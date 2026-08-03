import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { ensureDailyQuestsGenerated } from "./quests.service";
import { didLevelUp, xpIntoCurrentLevel } from "../users/xp";
import { QUEST_TYPES } from "./quest-types";
import { evaluateUnlockRequirements, fetchUnlockContext, isQuestUnlocked, withImplicitPinRequirement } from "./unlock.service";
import { evaluateAchievements } from "../achievements/achievements.service";

// Level-skip thresholds, checked highest-first so a user who's accumulated
// 10 completions gets the 5-level skip, not the 1-level one. Gate percentage
// is how far into the *current* level (before this completion's own reward)
// the user already was — a flat 100 XP/level curve, so this is just
// xpIntoCurrentLevel(preXp) / 100.
const LEVEL_SKIP_TIERS = [
  { questsNeeded: 10, gatePercentage: 0.6, skipLevels: 5 },
  { questsNeeded: 7, gatePercentage: 0.7, skipLevels: 2 },
  { questsNeeded: 5, gatePercentage: 0.8, skipLevels: 1 },
] as const;

export const questsRouter = Router();

const listQuestsQuerySchema = z.object({
  type: z.enum(QUEST_TYPES).optional(),
});

// Shared by GET /quests and the GET /quests/daily backward-compat alias.
async function listQuests(userId: string, type: string | undefined) {
  await ensureDailyQuestsGenerated();
  const result = await pool.query(
    `SELECT q.id, q.title, q.description, q.quest_type, q.category,
            q.chapter_id, q.chapter_order, q.xp_reward, q.coin_reward,
            q.pin_id, q.country, q.active_from,
            COALESCE(uq.status, 'not_started') AS status
     FROM quests q
     LEFT JOIN user_quests uq ON uq.quest_id = q.id AND uq.user_id = $1
     WHERE ($2::text IS NULL OR q.quest_type = $2)
       AND q.active_from <= now()
       AND (q.active_until IS NULL OR q.active_until >= now())
     ORDER BY q.created_at ASC`,
    [userId, type ?? null]
  );

  const questIds = result.rows.map((row) => row.id as string);
  const { requirementsByQuest, userLevel, completedQuestIds, visitStats } = await fetchUnlockContext(pool, userId, questIds);

  return result.rows.map(({ active_from, ...row }) => {
    const requirements = withImplicitPinRequirement(requirementsByQuest.get(row.id) ?? [], row.id, row.pin_id);
    const { locked, unlockRequirements } = evaluateUnlockRequirements(requirements, {
      userLevel,
      completedQuestIds,
      visitStats,
      questActiveFrom: active_from,
    });
    return { ...row, locked, unlockRequirements };
  });
}

// GET /quests — active quests of any type, with this user's progress if any.
// Optional ?type= filter.
questsRouter.get("/", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { type } = listQuestsQuerySchema.parse(req.query);
    res.json(await listQuests(req.userId!, type));
  } catch (err) {
    next(err);
  }
});

// GET /quests/daily — backward-compatible alias for GET /quests?type=daily.
questsRouter.get("/daily", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    res.json(await listQuests(req.userId!, "daily"));
  } catch (err) {
    next(err);
  }
});

const completeQuestSchema = z.object({
  questId: z.string().uuid(),
  pinId: z.string().uuid().optional(),
});

// POST /quests/complete — marks a quest completed for this user and awards XP/coins.
// Idempotent: completing an already-completed quest is a no-op that just returns current state.
questsRouter.post("/complete", requireAuth, async (req: AuthedRequest, res, next) => {
  const client = await pool.connect();
  try {
    const { questId, pinId } = completeQuestSchema.parse(req.body);

    await client.query("BEGIN");

    const questResult = await client.query(
      `SELECT id, xp_reward, coin_reward, pin_id, active_from FROM quests WHERE id = $1`,
      [questId]
    );
    const quest = questResult.rows[0];
    if (!quest) throw new HttpError(404, "Quest not found");

    if (quest.pin_id && pinId && quest.pin_id !== pinId) {
      throw new HttpError(400, "This quest is tied to a different pin");
    }

    // Covers both the auto-created checkin requirement for pin-linked quests
    // (an actual check-in at that pin during the quest's active window —
    // otherwise completing it is just two IDs in a request body with no
    // proof the user went anywhere) and any admin-added unlock requirements
    // (level/quest/category/location) — one gate, not two parallel checks.
    const unlocked = await isQuestUnlocked(client, req.userId!, questId, quest.active_from, quest.pin_id);
    if (!unlocked) {
      throw new HttpError(400, "This quest's unlock requirements aren't met yet");
    }

    const existing = await client.query(
      `SELECT status FROM user_quests WHERE user_id = $1 AND quest_id = $2`,
      [req.userId, questId]
    );

    if (existing.rowCount && existing.rows[0].status === "completed") {
      await client.query("COMMIT");
      const user = await pool.query("SELECT xp, level, coin_balance FROM users WHERE id = $1", [req.userId]);
      return res.json({
        alreadyCompleted: true,
        xpAwarded: 0,
        coinAwarded: 0,
        ...user.rows[0],
        leveledUp: false,
        previousLevel: user.rows[0].level,
        skippedLevels: 0,
      });
    }

    await client.query(
      `INSERT INTO user_quests (user_id, quest_id, status, completed_at)
       VALUES ($1, $2, 'completed', now())
       ON CONFLICT (user_id, quest_id)
       DO UPDATE SET status = 'completed', completed_at = now()`,
      [req.userId, questId]
    );

    const before = await client.query(
      "SELECT xp, quests_completed_since_levelup FROM users WHERE id = $1",
      [req.userId]
    );
    const preXp = before.rows[0].xp as number;
    const preQuestStreak = before.rows[0].quests_completed_since_levelup as number;
    const xpPercentage = xpIntoCurrentLevel(preXp) / 100;

    const updatedUser = await client.query(
      `UPDATE users
       SET xp = xp + $2,
           level = FLOOR((xp + $2) / 100) + 1,
           coin_balance = coin_balance + $3,
           updated_at = now()
       WHERE id = $1
       RETURNING xp, level, coin_balance`,
      [req.userId, quest.xp_reward, quest.coin_reward]
    );

    if (quest.coin_reward > 0) {
      await client.query(
        `INSERT INTO coin_transactions (user_id, amount, type, reference_id)
         VALUES ($1, $2, 'quest_reward', $3)`,
        [req.userId, quest.coin_reward, questId]
      );
    }

    const { leveledUp, previousLevel } = didLevelUp(preXp, updatedUser.rows[0].xp);
    let finalLevel = updatedUser.rows[0].level;
    let skippedLevels = 0;

    if (leveledUp) {
      // A plain XP crossing already leveled the user up this turn — reset the
      // streak and don't also apply a skip on top of it (would let one quest
      // jump an unbounded number of levels in a confusing way).
      await client.query("UPDATE users SET quests_completed_since_levelup = 0 WHERE id = $1", [req.userId]);
    } else {
      const newStreak = preQuestStreak + 1;
      const tier = LEVEL_SKIP_TIERS.find((t) => newStreak >= t.questsNeeded && xpPercentage >= t.gatePercentage);

      if (tier) {
        const skipped = await client.query(
          `UPDATE users
           SET level = level + $2, quests_completed_since_levelup = 0
           WHERE id = $1
           RETURNING level`,
          [req.userId, tier.skipLevels]
        );
        finalLevel = skipped.rows[0].level;
        skippedLevels = tier.skipLevels;
      } else {
        await client.query(
          "UPDATE users SET quests_completed_since_levelup = $2 WHERE id = $1",
          [req.userId, newStreak]
        );
      }
    }

    const awardedAchievements = await evaluateAchievements(client, req.userId!);

    await client.query("COMMIT");

    res.json({
      alreadyCompleted: false,
      xpAwarded: quest.xp_reward,
      coinAwarded: quest.coin_reward,
      xp: updatedUser.rows[0].xp,
      level: finalLevel,
      coin_balance: updatedUser.rows[0].coin_balance,
      leveledUp: leveledUp || skippedLevels > 0,
      previousLevel,
      skippedLevels,
      awardedAchievements,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});
