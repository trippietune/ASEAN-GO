import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { COIN_PACKAGES } from "../payments/coinPackages";
import { omiseClient, OmiseApiError } from "../payments/omise.client";

export const coinsRouter = Router();

coinsRouter.get("/balance", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query("SELECT coin_balance FROM users WHERE id = $1", [req.userId]);
    if (!result.rowCount) throw new HttpError(404, "User not found");
    res.json({ balance: result.rows[0].coin_balance });
  } catch (err) {
    next(err);
  }
});

const purchaseSchema = z.object({
  packageId: z.enum(["small", "medium", "large", "xl"]),
  // Card token from Omise.js/Omise iOS/Android SDK running on the client —
  // full card data must never reach this server (see omise.client.ts).
  omiseToken: z.string().min(1),
});

// POST /coins/purchase — creates a pending payment_transactions row, then
// charges the card via Omise. Coins are only credited once the charge is
// confirmed paid: either synchronously here (typical for non-3DS test
// cards) or later via the webhook (3-D Secure / async methods), whichever
// fires first — creditCoinsForTransaction() is idempotent either way.
coinsRouter.post("/purchase", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { packageId, omiseToken } = purchaseSchema.parse(req.body);
    const pkg = COIN_PACKAGES[packageId];
    const amountSatang = pkg.priceThb * 100;

    const pending = await pool.query(
      `INSERT INTO payment_transactions (user_id, provider, package_id, coins, amount_thb, currency, status)
       VALUES ($1, 'omise', $2, $3, $4, 'thb', 'pending')
       RETURNING id`,
      [req.userId, packageId, pkg.coins, amountSatang]
    );
    const transactionId = pending.rows[0].id;

    let charge;
    try {
      charge = await omiseClient.createCharge({
        amount: amountSatang,
        currency: "thb",
        card: omiseToken,
        capture: true,
        description: `AseanGo coins: ${packageId}`,
        metadata: { transactionId, userId: req.userId, packageId },
      });
    } catch (err) {
      const message = err instanceof OmiseApiError ? err.message : "Payment provider request failed";
      await pool.query(
        `UPDATE payment_transactions SET status = 'failed', failure_message = $2, updated_at = now() WHERE id = $1`,
        [transactionId, message]
      );
      throw new HttpError(402, message);
    }

    await pool.query(
      `UPDATE payment_transactions
       SET provider_charge_id = $2, status = $3, failure_code = $4, failure_message = $5, updated_at = now()
       WHERE id = $1`,
      [
        transactionId,
        charge.id,
        charge.paid ? "successful" : charge.status === "failed" ? "failed" : "pending",
        charge.failure_code,
        charge.failure_message,
      ]
    );

    if (charge.status === "failed" && !charge.paid) {
      throw new HttpError(402, charge.failure_message ?? "Payment failed");
    }

    let newBalance: number | null = null;
    if (charge.paid) {
      const client = await pool.connect();
      try {
        await client.query("BEGIN");
        const locked = await client.query(
          "SELECT coins_credited FROM payment_transactions WHERE id = $1 FOR UPDATE",
          [transactionId]
        );
        if (!locked.rows[0].coins_credited) {
          const updated = await client.query(
            "UPDATE users SET coin_balance = coin_balance + $2, updated_at = now() WHERE id = $1 RETURNING coin_balance",
            [req.userId, pkg.coins]
          );
          await client.query(
            `INSERT INTO coin_transactions (user_id, amount, type, reference_id, metadata)
             VALUES ($1, $2, 'purchase', $3, $4::jsonb)`,
            [req.userId, pkg.coins, transactionId, JSON.stringify({ paymentTransactionId: transactionId })]
          );
          await client.query(
            "UPDATE payment_transactions SET coins_credited = TRUE, updated_at = now() WHERE id = $1",
            [transactionId]
          );
          newBalance = updated.rows[0].coin_balance;
        }
        await client.query("COMMIT");
      } catch (err) {
        await client.query("ROLLBACK");
        throw err;
      } finally {
        client.release();
      }
    }

    res.status(201).json({
      success: charge.paid,
      status: charge.paid ? "successful" : "pending",
      transactionId,
      newBalance,
    });
  } catch (err) {
    next(err);
  }
});

const spendSchema = z.object({
  itemId: z.string().uuid(),
});

// POST /coins/spend — generic coin debit against a store item, without
// granting inventory. Prefer POST /inventory/purchase for the normal
// "buy this item" flow (it spends coins AND grants the item atomically);
// this endpoint exists for the API shape requested but delegates to the
// same balance-check logic.
coinsRouter.post("/spend", requireAuth, async (req: AuthedRequest, res, next) => {
  const client = await pool.connect();
  try {
    const { itemId } = spendSchema.parse(req.body);

    await client.query("BEGIN");

    const item = await client.query(
      "SELECT id, name, description, type, price, rarity, image_url, is_active FROM store_items WHERE id = $1",
      [itemId]
    );
    if (!item.rowCount) throw new HttpError(404, "Item not found");
    if (!item.rows[0].is_active) throw new HttpError(400, "This item is no longer available");

    const price = item.rows[0].price as number;

    const user = await client.query("SELECT coin_balance FROM users WHERE id = $1 FOR UPDATE", [req.userId]);
    if (user.rows[0].coin_balance < price) {
      throw new HttpError(400, "Not enough coins");
    }

    const updated = await client.query(
      "UPDATE users SET coin_balance = coin_balance - $2, updated_at = now() WHERE id = $1 RETURNING coin_balance",
      [req.userId, price]
    );

    await client.query(
      `INSERT INTO coin_transactions (user_id, amount, type, reference_id)
       VALUES ($1, $2, 'spend', $3)`,
      [req.userId, -price, itemId]
    );

    await client.query("COMMIT");

    res.json({
      success: true,
      newBalance: updated.rows[0].coin_balance,
      item: item.rows[0],
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});

coinsRouter.get("/transactions", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, amount, type, reference_id, created_at
       FROM coin_transactions
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT 100`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});
