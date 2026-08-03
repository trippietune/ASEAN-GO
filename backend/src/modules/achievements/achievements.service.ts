import { PoolClient } from "pg";
import { creditXpAndCoins } from "../users/rewards.service";

export interface AwardedAchievement {
  id: string;
  title: string;
  description: string | null;
  icon_url: string | null;
  xp_reward: number;
  coin_reward: number;
}

interface AchievementRow {
  id: string;
  title: string;
  description: string | null;
  icon_url: string | null;
  criteria_type: string;
  criteria_category: string | null;
  criteria_chapter_id: string | null;
  count_threshold: number | null;
  xp_reward: number;
  coin_reward: number;
}

// Called right before COMMIT in the routes that can move an achievement's
// criteria forward (quest completion, checkin, review). Takes the same
// transaction client as the triggering mutation so award-or-nothing is
// atomic with the event that earned it. 'manual' achievements are never
// considered here — they only unlock through the admin grant endpoint.
export async function evaluateAchievements(client: PoolClient, userId: string): Promise<AwardedAchievement[]> {
  const candidates = await client.query<AchievementRow>(
    `SELECT a.id, a.title, a.description, a.icon_url, a.criteria_type, a.criteria_category,
            a.criteria_chapter_id, a.count_threshold, a.xp_reward, a.coin_reward
     FROM achievements a
     WHERE a.is_active = TRUE
       AND a.criteria_type != 'manual'
       AND NOT EXISTS (
         SELECT 1 FROM user_achievements ua WHERE ua.user_id = $1 AND ua.achievement_id = a.id
       )`,
    [userId]
  );
  if (candidates.rowCount === 0) return [];

  const awarded: AwardedAchievement[] = [];
  for (const achievement of candidates.rows) {
    if (await isCriteriaMet(client, userId, achievement)) {
      const inserted = await client.query(
        `INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2) ON CONFLICT DO NOTHING RETURNING id`,
        [userId, achievement.id]
      );
      if (!inserted.rowCount) continue; // lost a race with itself (shouldn't happen within one transaction, but idempotent either way)

      if (achievement.xp_reward > 0 || achievement.coin_reward > 0) {
        await creditXpAndCoins(client, userId, achievement.xp_reward, achievement.coin_reward, "achievement_reward", achievement.id);
      }
      awarded.push({
        id: achievement.id,
        title: achievement.title,
        description: achievement.description,
        icon_url: achievement.icon_url,
        xp_reward: achievement.xp_reward,
        coin_reward: achievement.coin_reward,
      });
    }
  }
  return awarded;
}

async function isCriteriaMet(client: PoolClient, userId: string, achievement: AchievementRow): Promise<boolean> {
  const threshold = achievement.count_threshold ?? 0;
  switch (achievement.criteria_type) {
    case "quests_completed": {
      const result = await client.query<{ count: string }>(
        `SELECT COUNT(*)::int AS count FROM user_quests WHERE user_id = $1 AND status = 'completed'`,
        [userId]
      );
      return Number(result.rows[0].count) >= threshold;
    }
    case "checkins": {
      const result = await client.query<{ count: string }>(
        `SELECT COUNT(*)::int AS count FROM pin_checkins WHERE user_id = $1`,
        [userId]
      );
      return Number(result.rows[0].count) >= threshold;
    }
    case "level_reached": {
      // >= not == : the quest-completion level-skip mechanic can jump a
      // user past a threshold in one hop (e.g. level 8 -> 13, skipping over
      // 10 entirely) — an exact-match check would silently miss this.
      const result = await client.query<{ level: number }>(`SELECT level FROM users WHERE id = $1`, [userId]);
      return (result.rows[0]?.level ?? 1) >= threshold;
    }
    case "category_visits": {
      if (!achievement.criteria_category) return false;
      const result = await client.query<{ count: string }>(
        `SELECT COUNT(DISTINCT vp.id)::int AS count
         FROM pin_checkins pc
         JOIN verified_pins vp ON vp.id = pc.pin_id
         WHERE pc.user_id = $1 AND vp.category = $2`,
        [userId, achievement.criteria_category]
      );
      return Number(result.rows[0].count) >= threshold;
    }
    case "chapter_completed": {
      if (!achievement.criteria_chapter_id) return false;
      const result = await client.query<{ total: string; completed: string }>(
        `SELECT COUNT(*)::int AS total,
                COUNT(*) FILTER (WHERE uq.status = 'completed')::int AS completed
         FROM quests q
         LEFT JOIN user_quests uq ON uq.quest_id = q.id AND uq.user_id = $2
         WHERE q.chapter_id = $1`,
        [achievement.criteria_chapter_id, userId]
      );
      const total = Number(result.rows[0].total);
      const completed = Number(result.rows[0].completed);
      return total > 0 && completed === total;
    }
    default:
      return false;
  }
}
