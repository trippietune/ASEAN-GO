import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth } from "../../middleware/auth";
import { requireAdmin, AdminRequest } from "../../middleware/adminAuth";
import { HttpError } from "../../middleware/errorHandler";
import { omiseClient, OmiseCharge } from "./omise.client";

export const paymentsRouter = Router();

async function creditCoinsForTransaction(transactionId: string, userId: string, coins: number): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    // Row lock + status re-check inside the transaction: guards against the
    // synchronous purchase response and an in-flight webhook both trying to
    // credit the same charge (Omise sends the webhook regardless of whether
    // the charge already came back 'paid' synchronously).
    const locked = await client.query(
      "SELECT coins_credited FROM payment_transactions WHERE id = $1 FOR UPDATE",
      [transactionId]
    );
    if (!locked.rowCount || locked.rows[0].coins_credited) {
      await client.query("ROLLBACK");
      return;
    }

    await client.query(
      "UPDATE users SET coin_balance = coin_balance + $2, updated_at = now() WHERE id = $1",
      [userId, coins]
    );
    await client.query(
      `INSERT INTO coin_transactions (user_id, amount, type, reference_id, metadata)
       VALUES ($1, $2, 'purchase', $3, $4::jsonb)`,
      [userId, coins, transactionId, JSON.stringify({ paymentTransactionId: transactionId })]
    );
    await client.query(
      "UPDATE payment_transactions SET coins_credited = TRUE, updated_at = now() WHERE id = $1",
      [transactionId]
    );

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

// Statuses a webhook must never regress out of — a refund can be initiated
// (by an admin, via the admin API) before Omise's own charge-completion
// webhook for the original purchase arrives, since the two are unrelated
// event streams with no ordering guarantee between them.
const TERMINAL_REFUND_STATUSES = new Set(["refunded", "partially_refunded"]);

async function applyChargeResult(charge: OmiseCharge): Promise<void> {
  const client = await pool.connect();
  let shouldCreditCoins = false;
  let creditArgs: { transactionId: string; userId: string; coins: number } | null = null;

  try {
    await client.query("BEGIN");

    const existing = await client.query(
      "SELECT id, user_id, coins, status FROM payment_transactions WHERE provider_charge_id = $1 FOR UPDATE",
      [charge.id]
    );
    if (!existing.rowCount) {
      await client.query("ROLLBACK");
      return; // Not one of ours (or already deleted) — ignore.
    }
    const row = existing.rows[0];

    if (TERMINAL_REFUND_STATUSES.has(row.status)) {
      await client.query("ROLLBACK");
      return; // Refund already recorded — a late charge webhook must not undo it.
    }

    const nextStatus = charge.paid ? "successful" : charge.status === "failed" ? "failed" : "pending";

    await client.query(
      `UPDATE payment_transactions
       SET status = $2, failure_code = $3, failure_message = $4, updated_at = now()
       WHERE id = $1`,
      [row.id, nextStatus, charge.failure_code, charge.failure_message]
    );

    if (charge.paid) {
      shouldCreditCoins = true;
      creditArgs = { transactionId: row.id, userId: row.user_id, coins: row.coins };
    }

    await client.query("COMMIT");
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }

  // Runs on its own connection/transaction after the status update commits —
  // creditCoinsForTransaction() re-checks coins_credited under its own lock,
  // so this is still safe against a concurrent purchase-response credit.
  if (shouldCreditCoins && creditArgs) {
    await creditCoinsForTransaction(creditArgs.transactionId, creditArgs.userId, creditArgs.coins);
  }
}

// POST /payments/omise/webhook — Omise has no HMAC signing secret, so the
// only trustworthy verification path is to ignore the request body's claims
// and re-fetch the event from Omise's API using our secret key before acting
// on it (per Omise's own guidance).
//
// Verified against a real sandbox charge: a normal (non-3DS) card charge
// fires 'charge.create' with the final paid/status already set — it never
// fires 'charge.complete' at all. 'charge.complete' only shows up for async
// flows (e.g. 3-D Secure) where the charge starts pending and transitions
// later. So we react to any charge.* event and trust the payload's own
// paid/status fields rather than gating on one specific event name.
paymentsRouter.post("/payments/omise/webhook", async (req, res, next) => {
  try {
    const eventId = z.object({ id: z.string().min(1) }).parse(req.body).id;
    const event = await omiseClient.retrieveEvent(eventId);

    if (event.key.startsWith("charge.")) {
      await applyChargeResult(event.data as OmiseCharge);
    }

    res.status(200).json({ received: true });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Admin: transaction history + refunds
// ---------------------------------------------------------------------------

paymentsRouter.get("/admin/payment-transactions", requireAuth, requireAdmin, async (req, res, next) => {
  try {
    const { status } = z
      .object({ status: z.enum(["pending", "successful", "failed", "refunded", "partially_refunded"]).optional() })
      .parse(req.query);
    const result = await pool.query(
      `SELECT t.id, t.user_id, u.display_name AS user_display_name, u.email AS user_email,
              t.provider, t.provider_charge_id, t.package_id, t.coins, t.amount_thb, t.currency,
              t.status, t.coins_credited, t.failure_code, t.failure_message, t.refunded_amount_thb,
              t.created_at, t.updated_at
       FROM payment_transactions t
       JOIN users u ON u.id = t.user_id
       WHERE ($1::text IS NULL OR t.status = $1)
       ORDER BY t.created_at DESC
       LIMIT 500`,
      [status ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const refundSchema = z.object({
  amountThb: z.number().int().positive().optional(), // omit for a full refund of the remaining amount
});

// POST /admin/payment-transactions/:id/refund — admin-only. Calls Omise's
// refund API, then claws back coins from the user's balance up to whatever
// is still there (a user who already spent the coins keeps the balance at 0
// rather than going negative — the money-side refund still proceeds either
// way, since that's a matter between us and the payment provider).
paymentsRouter.post(
  "/admin/payment-transactions/:id/refund",
  requireAuth,
  requireAdmin,
  async (req: AdminRequest, res, next) => {
    const client = await pool.connect();
    try {
      const transactionId = z.string().uuid().parse(req.params.id);
      const { amountThb } = refundSchema.parse(req.body ?? {});

      // Locked read up front: without this, a charge webhook landing between
      // this check and the UPDATE below could race with the refund (e.g. the
      // late 'charge.create' event we saw in sandbox testing arriving after
      // the admin already refunded). The lock is released by the same
      // transaction's COMMIT/ROLLBACK further down.
      await client.query("BEGIN");
      const txResult = await client.query(
        "SELECT * FROM payment_transactions WHERE id = $1 FOR UPDATE",
        [transactionId]
      );
      if (!txResult.rowCount) throw new HttpError(404, "Transaction not found");
      const tx = txResult.rows[0];

      if (tx.status !== "successful" && tx.status !== "partially_refunded") {
        throw new HttpError(400, `Cannot refund a transaction with status '${tx.status}'`);
      }
      if (!tx.provider_charge_id) {
        throw new HttpError(400, "Transaction has no associated charge to refund");
      }

      const remainingThb = tx.amount_thb / 100 - tx.refunded_amount_thb / 100;
      const refundAmountThb = amountThb ?? remainingThb;
      if (refundAmountThb <= 0 || refundAmountThb > remainingThb) {
        throw new HttpError(400, `Refund amount must be between 1 and ${remainingThb} THB`);
      }

      const refund = await omiseClient.createRefund(tx.provider_charge_id, refundAmountThb * 100);

      const newRefundedThb = tx.refunded_amount_thb / 100 + refundAmountThb;
      const isFullRefund = newRefundedThb >= tx.amount_thb / 100;
      const newStatus = isFullRefund ? "refunded" : "partially_refunded";

      await client.query(
        `UPDATE payment_transactions
         SET status = $2, refunded_amount_thb = $3, updated_at = now()
         WHERE id = $1`,
        [transactionId, newStatus, newRefundedThb * 100]
      );

      // Claw back coins only up to whatever the user still has — refunding
      // money already spent shouldn't push a balance negative.
      let coinsClawedBack = 0;
      if (tx.coins_credited) {
        const proportionalCoins = Math.round((refundAmountThb / (tx.amount_thb / 100)) * tx.coins);
        const userResult = await client.query(
          "SELECT coin_balance FROM users WHERE id = $1 FOR UPDATE",
          [tx.user_id]
        );
        const currentBalance = userResult.rows[0]?.coin_balance ?? 0;
        coinsClawedBack = Math.min(proportionalCoins, currentBalance);

        if (coinsClawedBack > 0) {
          await client.query(
            "UPDATE users SET coin_balance = coin_balance - $2, updated_at = now() WHERE id = $1",
            [tx.user_id, coinsClawedBack]
          );
          await client.query(
            `INSERT INTO coin_transactions (user_id, amount, type, reference_id, metadata)
             VALUES ($1, $2, 'refund', $3, $4::jsonb)`,
            [
              tx.user_id,
              -coinsClawedBack,
              transactionId,
              JSON.stringify({ refundId: refund.id, refundAmountThb, requestedBy: req.userId }),
            ]
          );
        }
      }

      await client.query("COMMIT");

      res.json({
        success: true,
        refundId: refund.id,
        status: newStatus,
        refundedAmountThb: newRefundedThb,
        coinsClawedBack,
        fullCoinsClawedBack: coinsClawedBack === Math.round((refundAmountThb / (tx.amount_thb / 100)) * tx.coins),
      });
    } catch (err) {
      await client.query("ROLLBACK");
      next(err);
    } finally {
      client.release();
    }
  }
);
