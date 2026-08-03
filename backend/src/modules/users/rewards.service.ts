import { PoolClient } from "pg";
import { didLevelUp } from "./xp";

export interface CreditResult {
  xp: number;
  level: number;
  coinBalance: number;
  leveledUp: boolean;
  previousLevel: number;
}

// Shared "add XP/coins, detect a plain level-up, ledger the coins" helper —
// extracted from what POST /quests/complete and POST /pins/:id/checkin each
// did inline. Deliberately does NOT include quest-completion's level-skip
// streak logic (LEVEL_SKIP_TIERS) — that mechanic is specific to quests and
// stays in quests.routes.ts. Takes the transaction's own client so the
// caller controls atomicity (e.g. achievements are awarded in the same
// transaction as the event that triggered them).
export async function creditXpAndCoins(
  client: PoolClient,
  userId: string,
  xpAmount: number,
  coinAmount: number,
  ledgerType: string,
  referenceId: string | null
): Promise<CreditResult> {
  const before = await client.query<{ xp: number }>("SELECT xp FROM users WHERE id = $1", [userId]);
  const preXp = before.rows[0].xp;

  const updated = await client.query<{ xp: number; level: number; coin_balance: number }>(
    `UPDATE users
     SET xp = xp + $2,
         level = FLOOR((xp + $2) / 100) + 1,
         coin_balance = coin_balance + $3,
         updated_at = now()
     WHERE id = $1
     RETURNING xp, level, coin_balance`,
    [userId, xpAmount, coinAmount]
  );

  if (coinAmount > 0) {
    await client.query(
      `INSERT INTO coin_transactions (user_id, amount, type, reference_id) VALUES ($1, $2, $3, $4)`,
      [userId, coinAmount, ledgerType, referenceId]
    );
  }

  const { leveledUp, previousLevel } = didLevelUp(preXp, updated.rows[0].xp);

  return {
    xp: updated.rows[0].xp,
    level: updated.rows[0].level,
    coinBalance: updated.rows[0].coin_balance,
    leveledUp,
    previousLevel,
  };
}
