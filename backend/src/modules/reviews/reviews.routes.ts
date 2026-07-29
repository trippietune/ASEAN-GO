import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { deleteAssetsByUrls } from "../media/media.service";

export const reviewsRouter = Router();

// GET /pins/:id/reviews — all reviews for a pin, newest first, with the
// reviewer's display name (no separate user lookup needed on the client).
reviewsRouter.get("/pins/:id/reviews", async (req, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `SELECT r.id, r.pin_id, r.user_id, u.display_name AS user_display_name, u.avatar_url AS user_avatar_url,
              r.rating, r.comment, r.photo_urls, r.created_at, r.updated_at
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       WHERE r.pin_id = $1
       ORDER BY r.created_at DESC`,
      [pinId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const upsertReviewSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(2000).optional(),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// POST /pins/:id/reviews — create or update the current user's review for
// this pin (one review per user per pin; posting again edits the existing one).
reviewsRouter.post("/pins/:id/reviews", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const body = upsertReviewSchema.parse(req.body);

    const pin = await pool.query("SELECT id FROM verified_pins WHERE id = $1", [pinId]);
    if (!pin.rowCount) throw new HttpError(404, "Pin not found");

    const existing = await pool.query(
      "SELECT photo_urls FROM reviews WHERE pin_id = $1 AND user_id = $2",
      [pinId, req.userId]
    );
    const previousPhotoUrls: string[] = existing.rows[0]?.photo_urls ?? [];
    const nextPhotoUrls = body.photoUrls ?? [];

    const result = await pool.query(
      `INSERT INTO reviews (pin_id, user_id, rating, comment, photo_urls)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (pin_id, user_id)
       DO UPDATE SET rating = $3, comment = $4, photo_urls = $5, updated_at = now()
       RETURNING id, pin_id, user_id, rating, comment, photo_urls, created_at, updated_at`,
      [pinId, req.userId, body.rating, body.comment ?? null, nextPhotoUrls]
    );

    // Editing a review can drop photos from the array (the client re-sends
    // the full desired list) — free anything that's no longer referenced.
    const removedUrls = previousPhotoUrls.filter((url) => !nextPhotoUrls.includes(url));
    if (removedUrls.length > 0) {
      await deleteAssetsByUrls(removedUrls);
    }

    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// DELETE /pins/:id/reviews — remove the current user's own review for this pin.
reviewsRouter.delete("/pins/:id/reviews", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      "DELETE FROM reviews WHERE pin_id = $1 AND user_id = $2 RETURNING photo_urls",
      [pinId, req.userId]
    );
    if (!result.rowCount) throw new HttpError(404, "You haven't reviewed this pin");

    const photoUrls: string[] = result.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) {
      await deleteAssetsByUrls(photoUrls);
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// GET /reviews/user — the current user's own reviews, across all pins.
reviewsRouter.get("/reviews/user", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT r.id, r.pin_id, p.name AS pin_name, r.rating, r.comment, r.photo_urls,
              r.created_at, r.updated_at
       FROM reviews r
       JOIN verified_pins p ON p.id = r.pin_id
       WHERE r.user_id = $1
       ORDER BY r.created_at DESC`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});
