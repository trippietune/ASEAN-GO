import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";

export const pinSuggestionsRouter = Router();

const pinCategorySchema = z.enum(["food", "shop", "attraction", "transport", "lodging", "other"]);

const SELECT_SUGGESTION = `
  id, name, category, description, country, city,
  ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
  photo_urls, submitted_by, status, reviewed_by, reviewed_at, rejection_reason,
  resulting_pin_id, created_at, updated_at
`;

const createSuggestionSchema = z.object({
  name: z.string().min(1).max(200),
  category: pinCategorySchema,
  description: z.string().max(2000).optional(),
  country: z.string().min(1).max(100),
  city: z.string().max(100).optional(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// POST /pin-suggestions — any signed-in user may suggest a new place; it sits
// pending until an admin reviews it (see PUT /admin/pin-suggestions/:id/approve).
pinSuggestionsRouter.post("/pin-suggestions", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = createSuggestionSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO pin_suggestions (name, category, description, country, city, location, photo_urls, submitted_by)
       VALUES ($1, $2, $3, $4, $5, ST_MakePoint($7, $6)::geography, $8, $9)
       RETURNING ${SELECT_SUGGESTION}`,
      [
        body.name,
        body.category,
        body.description ?? null,
        body.country,
        body.city ?? null,
        body.lat,
        body.lng,
        body.photoUrls ?? [],
        req.userId,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// GET /pin-suggestions/mine — the caller's own suggestions, most recent first.
pinSuggestionsRouter.get("/pin-suggestions/mine", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT ${SELECT_SUGGESTION} FROM pin_suggestions WHERE submitted_by = $1 ORDER BY created_at DESC`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});
