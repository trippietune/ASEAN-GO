import { pool } from "../../db/pool";

const DAILY_QUEST_COUNT = 3;
const DAILY_QUEST_XP_REWARD = 25;
const DAILY_QUEST_COIN_REWARD = 10;

// Arbitrary fixed key for the Postgres advisory lock guarding daily quest
// generation — any 64-bit int works, it just needs to be stable and unique
// among this app's advisory lock usages (there are none others today).
const DAILY_QUEST_LOCK_KEY = 728_331_001;

/// Ensures today's set of daily quests exists before GET /quests/daily reads
/// them. Global, not per-user (every user sees the same daily set) — the
/// simplest version of "today's quests," matching how `quests`/`user_quests`
/// are already modeled (quests are global rows; only completion is
/// per-user). Runs lazily on read rather than via a cron job, since no job
/// scheduler is set up for this backend and a lazy check is one indexed
/// query on the common case (today's quests already exist).
///
/// Two requests can race in to an empty "today" at once (no cron means the
/// first request of the day always risks this) — a transaction-scoped
/// advisory lock serializes generation so the second racer re-checks under
/// the lock and finds today's quests already exist instead of doubling up.
export async function ensureDailyQuestsGenerated(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    await client.query("SELECT pg_advisory_xact_lock($1)", [DAILY_QUEST_LOCK_KEY]);

    const today = await client.query(
      `SELECT COUNT(*)::int AS count FROM quests
       WHERE quest_type = 'daily' AND active_from >= date_trunc('day', now())`
    );
    if (today.rows[0].count > 0) {
      await client.query("COMMIT");
      return;
    }

    // Verified, non-scam pins only — a daily quest shouldn't send someone to
    // an unverified submission or a place flagged as a scam risk.
    const pins = await client.query(
      `SELECT id, name FROM verified_pins
       WHERE is_verified = TRUE AND is_scam_alert = FALSE
       ORDER BY random()
       LIMIT $1`,
      [DAILY_QUEST_COUNT]
    );

    for (const pin of pins.rows) {
      await client.query(
        `INSERT INTO quests (title, description, quest_type, xp_reward, coin_reward, pin_id, active_from, active_until)
         VALUES ($1, $2, 'daily', $3, $4, $5, date_trunc('day', now()), date_trunc('day', now()) + interval '1 day')`,
        [
          `Visit ${pin.name}`,
          `Check in at ${pin.name} to complete today's quest`,
          DAILY_QUEST_XP_REWARD,
          DAILY_QUEST_COIN_REWARD,
          pin.id,
        ]
      );
    }

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}
