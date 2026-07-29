import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";

export const inventoryRouter = Router();

inventoryRouter.get("/", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT inv.id, inv.item_id, s.name AS item_name, s.type AS item_type,
              s.rarity AS item_rarity, s.image_url AS item_image_url, inv.acquired_at
       FROM inventory inv
       JOIN store_items s ON s.id = inv.item_id
       WHERE inv.user_id = $1
       ORDER BY inv.acquired_at DESC`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const purchaseSchema = z.object({
  itemId: z.string().uuid(),
});

// POST /inventory/purchase — the normal "buy this item" flow: checks the
// item exists and is active, checks the user hasn't already bought it,
// checks they have enough coins, then debits coins + grants inventory +
// records the transaction atomically.
inventoryRouter.post("/purchase", requireAuth, async (req: AuthedRequest, res, next) => {
  const client = await pool.connect();
  try {
    const { itemId } = purchaseSchema.parse(req.body);

    await client.query("BEGIN");

    const item = await client.query(
      "SELECT id, name, description, type, price, rarity, image_url, is_active FROM store_items WHERE id = $1",
      [itemId]
    );
    if (!item.rowCount) throw new HttpError(404, "Item not found");
    if (!item.rows[0].is_active) throw new HttpError(400, "This item is no longer available");

    const alreadyOwned = await client.query(
      "SELECT id FROM inventory WHERE user_id = $1 AND item_id = $2",
      [req.userId, itemId]
    );
    if (alreadyOwned.rowCount) {
      throw new HttpError(409, "You already own this item");
    }

    const price = item.rows[0].price as number;

    const user = await client.query("SELECT coin_balance FROM users WHERE id = $1 FOR UPDATE", [req.userId]);
    if (user.rows[0].coin_balance < price) {
      throw new HttpError(400, "Not enough coins");
    }

    const updatedUser = await client.query(
      "UPDATE users SET coin_balance = coin_balance - $2, updated_at = now() WHERE id = $1 RETURNING coin_balance",
      [req.userId, price]
    );

    await client.query(
      "INSERT INTO inventory (user_id, item_id) VALUES ($1, $2)",
      [req.userId, itemId]
    );

    await client.query(
      `INSERT INTO coin_transactions (user_id, amount, type, reference_id)
       VALUES ($1, $2, 'spend', $3)`,
      [req.userId, -price, itemId]
    );

    await client.query("COMMIT");

    res.status(201).json({
      success: true,
      item: item.rows[0],
      newBalance: updatedUser.rows[0].coin_balance,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});

const checkQuerySchema = z.object({
  itemId: z.string().uuid(),
});

inventoryRouter.get("/check", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { itemId } = checkQuerySchema.parse(req.query);
    const result = await pool.query(
      "SELECT id FROM inventory WHERE user_id = $1 AND item_id = $2",
      [req.userId, itemId]
    );
    res.json({ hasItem: (result.rowCount ?? 0) > 0 });
  } catch (err) {
    next(err);
  }
});
