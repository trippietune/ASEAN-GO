import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";

export const questsRouter = Router();

// GET /quests/daily — active daily quests, with this user's progress if any.
questsRouter.get("/daily", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT q.id, q.title, q.description, q.quest_type, q.xp_reward, q.coin_reward,
              q.pin_id, q.country,
              COALESCE(uq.status, 'not_started') AS status
       FROM quests q
       LEFT JOIN user_quests uq ON uq.quest_id = q.id AND uq.user_id = $1
       WHERE q.quest_type = 'daily'
         AND q.active_from <= now()
         AND (q.active_until IS NULL OR q.active_until >= now())
       ORDER BY q.created_at ASC`,
      [req.userId]
    );
    res.json(result.rows);
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
      `SELECT id, xp_reward, coin_reward, pin_id FROM quests WHERE id = $1`,
      [questId]
    );
    const quest = questResult.rows[0];
    if (!quest) throw new HttpError(404, "Quest not found");

    if (quest.pin_id && pinId && quest.pin_id !== pinId) {
      throw new HttpError(400, "This quest is tied to a different pin");
    }

    const existing = await client.query(
      `SELECT status FROM user_quests WHERE user_id = $1 AND quest_id = $2`,
      [req.userId, questId]
    );

    if (existing.rowCount && existing.rows[0].status === "completed") {
      await client.query("COMMIT");
      const user = await pool.query("SELECT xp, level FROM users WHERE id = $1", [req.userId]);
      return res.json({ alreadyCompleted: true, xpAwarded: 0, ...user.rows[0] });
    }

    await client.query(
      `INSERT INTO user_quests (user_id, quest_id, status, completed_at)
       VALUES ($1, $2, 'completed', now())
       ON CONFLICT (user_id, quest_id)
       DO UPDATE SET status = 'completed', completed_at = now()`,
      [req.userId, questId]
    );

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

    await client.query("COMMIT");

    res.json({
      alreadyCompleted: false,
      xpAwarded: quest.xp_reward,
      coinAwarded: quest.coin_reward,
      ...updatedUser.rows[0],
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});
