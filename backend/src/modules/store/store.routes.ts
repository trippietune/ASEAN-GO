import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";

export const storeRouter = Router();

const ITEM_TYPES = ["outfit", "avatar", "booster", "souvenir"] as const;
const RARITIES = ["common", "rare", "epic", "legendary"] as const;

const listQuerySchema = z.object({
  category: z.enum(ITEM_TYPES).optional(),
});

// GET /store/items?category=outfit|avatar|booster|souvenir
storeRouter.get("/items", async (req, res, next) => {
  try {
    const { category } = listQuerySchema.parse(req.query);
    const result = await pool.query(
      `SELECT id, name, description, type, price, rarity, image_url, is_active
       FROM store_items
       WHERE is_active = TRUE
         AND ($1::text IS NULL OR type = $1)
       ORDER BY type, price ASC`,
      [category ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

storeRouter.get("/items/:id", async (req, res, next) => {
  try {
    const itemId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `SELECT id, name, description, type, price, rarity, image_url, is_active
       FROM store_items WHERE id = $1`,
      [itemId]
    );
    if (!result.rowCount) throw new HttpError(404, "Item not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const createItemSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  type: z.enum(ITEM_TYPES),
  price: z.number().int().min(0),
  rarity: z.enum(RARITIES).default("common"),
  imageUrl: z.string().url(),
});

// NOTE: no admin-role system exists in this app yet — these write endpoints
// are gated by requireAuth only (any signed-in user can manage the catalog).
// Replace with a real admin check before this is exposed beyond local/dev use.
storeRouter.post("/items", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = createItemSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO store_items (name, description, type, price, rarity, image_url)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, name, description, type, price, rarity, image_url, is_active`,
      [body.name, body.description ?? null, body.type, body.price, body.rarity, body.imageUrl]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updateItemSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).optional(),
  type: z.enum(ITEM_TYPES).optional(),
  price: z.number().int().min(0).optional(),
  rarity: z.enum(RARITIES).optional(),
  imageUrl: z.string().url().optional(),
  isActive: z.boolean().optional(),
});

storeRouter.put("/items/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const itemId = z.string().uuid().parse(req.params.id);
    const body = updateItemSchema.parse(req.body);
    if (Object.keys(body).length === 0) {
      throw new HttpError(400, "No fields to update");
    }

    const result = await pool.query(
      `UPDATE store_items
       SET name = COALESCE($2, name),
           description = COALESCE($3, description),
           type = COALESCE($4, type),
           price = COALESCE($5, price),
           rarity = COALESCE($6, rarity),
           image_url = COALESCE($7, image_url),
           is_active = COALESCE($8, is_active),
           updated_at = now()
       WHERE id = $1
       RETURNING id, name, description, type, price, rarity, image_url, is_active`,
      [
        itemId,
        body.name ?? null,
        body.description ?? null,
        body.type ?? null,
        body.price ?? null,
        body.rarity ?? null,
        body.imageUrl ?? null,
        body.isActive ?? null,
      ]
    );
    if (!result.rowCount) throw new HttpError(404, "Item not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

storeRouter.delete("/items/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const itemId = z.string().uuid().parse(req.params.id);
    const result = await pool.query("DELETE FROM store_items WHERE id = $1", [itemId]);
    if (!result.rowCount) throw new HttpError(404, "Item not found");
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

