import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { deleteAssetsByUrls } from "../media/media.service";

const CHECKIN_XP_REWARD = 15;

export const pinsRouter = Router();

const pinCategorySchema = z.enum(["food", "shop", "attraction", "transport", "lodging", "other"]);

const nearbyQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusMeters: z.coerce.number().min(1).max(50_000).default(2000),
  category: pinCategorySchema.optional(),
});

// GET /pins/nearby?lat=..&lng=..&radiusMeters=..
// Returns Verified Pins and active Scam Alerts within range, closest first.
pinsRouter.get("/nearby", async (req, res, next) => {
  try {
    const { lat, lng, radiusMeters, category } = nearbyQuerySchema.parse(req.query);

    const result = await pool.query(
      `SELECT p.id, p.name, p.category, p.description, p.country, p.city,
              ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
              p.is_verified, p.is_scam_alert, p.scam_alert_message, p.safety_score,
              p.is_checkpoint, p.is_recommended,
              ST_Distance(p.location, ST_MakePoint($2, $1)::geography) AS distance_meters,
              COALESCE(r.average_rating, 0) AS average_rating,
              COALESCE(r.review_count, 0) AS review_count,
              COALESCE(rr.report_count, 0) AS report_count,
              COALESCE(aq.has_active_quest, FALSE) AS has_active_quest
       FROM verified_pins p
       LEFT JOIN (
         SELECT pin_id, AVG(rating)::float AS average_rating, COUNT(*)::int AS review_count
         FROM reviews GROUP BY pin_id
       ) r ON r.pin_id = p.id
       LEFT JOIN (
         SELECT pin_id, COUNT(*)::int AS report_count FROM risk_reports GROUP BY pin_id
       ) rr ON rr.pin_id = p.id
       LEFT JOIN (
         SELECT DISTINCT pin_id, TRUE AS has_active_quest FROM quests
         WHERE pin_id IS NOT NULL AND active_from <= now() AND (active_until IS NULL OR active_until > now())
       ) aq ON aq.pin_id = p.id
       WHERE ST_DWithin(p.location, ST_MakePoint($2, $1)::geography, $3)
         AND ($4::text IS NULL OR p.category = $4)
       ORDER BY distance_meters ASC
       LIMIT 200`,
      [lat, lng, radiusMeters, category ?? null]
    );

    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const nearbyRisksQuerySchema = z.object({
  lat: z.coerce.number().min(-90).max(90),
  lng: z.coerce.number().min(-180).max(180),
  radiusMeters: z.coerce.number().min(1).max(50_000).default(1500),
});

// GET /pins/nearby-risks — pins the client should warn the user about right
// now: admin scam alerts and/or pins with at least one community risk report,
// within range of the given point. Used by the mobile app's foreground
// proximity check (polls its own GPS, calls this, shows a local alert) —
// there is no background/server-push geofencing in this version.
pinsRouter.get("/nearby-risks", async (req, res, next) => {
  try {
    const { lat, lng, radiusMeters } = nearbyRisksQuerySchema.parse(req.query);

    const result = await pool.query(
      `SELECT p.id, p.name, p.category, p.country, p.city,
              ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
              p.is_scam_alert, p.scam_alert_message, p.safety_score,
              ST_Distance(p.location, ST_MakePoint($2, $1)::geography) AS distance_meters,
              COALESCE(rr.report_count, 0) AS report_count
       FROM verified_pins p
       LEFT JOIN (
         SELECT pin_id, COUNT(*)::int AS report_count FROM risk_reports GROUP BY pin_id
       ) rr ON rr.pin_id = p.id
       WHERE ST_DWithin(p.location, ST_MakePoint($2, $1)::geography, $3)
         AND (p.is_scam_alert = TRUE OR rr.report_count > 0)
       ORDER BY distance_meters ASC
       LIMIT 50`,
      [lat, lng, radiusMeters]
    );

    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createPinSchema = z.object({
  name: z.string().min(1).max(200),
  category: pinCategorySchema,
  description: z.string().max(2000).optional(),
  country: z.string().min(1).max(100),
  city: z.string().max(100).optional(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// Authenticated users can submit a pin candidate; it starts unverified pending admin review.
pinsRouter.post("/", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = createPinSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO verified_pins (name, category, description, country, city, location, submitted_by, photo_urls)
       VALUES ($1, $2, $3, $4, $5, ST_MakePoint($7, $6)::geography, $8, $9)
       RETURNING id, name, category, description, country, city,
                 ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
                 is_verified, is_scam_alert, scam_alert_message, safety_score, photo_urls,
                 0 AS average_rating, 0 AS review_count`,
      [
        body.name,
        body.category,
        body.description ?? null,
        body.country,
        body.city ?? null,
        body.lat,
        body.lng,
        req.userId,
        body.photoUrls ?? [],
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// GET /pins/:id — full detail for a single pin.
pinsRouter.get("/:id", async (req, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `SELECT p.id, p.name, p.category, p.description, p.country, p.city,
              ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
              p.is_verified, p.is_scam_alert, p.scam_alert_message, p.safety_score,
              p.is_checkpoint, p.is_recommended,
              p.submitted_by, p.created_at, p.updated_at, p.photo_urls,
              COALESCE(r.average_rating, 0) AS average_rating,
              COALESCE(r.review_count, 0) AS review_count,
              COALESCE(rr.report_count, 0) AS report_count,
              COALESCE(aq.has_active_quest, FALSE) AS has_active_quest
       FROM verified_pins p
       LEFT JOIN (
         SELECT pin_id, AVG(rating)::float AS average_rating, COUNT(*)::int AS review_count
         FROM reviews GROUP BY pin_id
       ) r ON r.pin_id = p.id
       LEFT JOIN (
         SELECT pin_id, COUNT(*)::int AS report_count FROM risk_reports GROUP BY pin_id
       ) rr ON rr.pin_id = p.id
       LEFT JOIN (
         SELECT DISTINCT pin_id, TRUE AS has_active_quest FROM quests
         WHERE pin_id IS NOT NULL AND active_from <= now() AND (active_until IS NULL OR active_until > now())
       ) aq ON aq.pin_id = p.id
       WHERE p.id = $1`,
      [pinId]
    );
    if (!result.rowCount) throw new HttpError(404, "Pin not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updatePinSchema = z.object({
  name: z.string().min(1).max(200).optional(),
  category: pinCategorySchema.optional(),
  description: z.string().max(2000).optional(),
  country: z.string().min(1).max(100).optional(),
  city: z.string().max(100).optional(),
  lat: z.number().min(-90).max(90).optional(),
  lng: z.number().min(-180).max(180).optional(),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// PUT /pins/:id — only the original submitter may edit their pin.
pinsRouter.put("/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const body = updatePinSchema.parse(req.body);
    if (Object.keys(body).length === 0) {
      throw new HttpError(400, "No fields to update");
    }

    const existing = await pool.query("SELECT submitted_by, photo_urls FROM verified_pins WHERE id = $1", [pinId]);
    if (!existing.rowCount) throw new HttpError(404, "Pin not found");
    if (existing.rows[0].submitted_by !== req.userId) {
      throw new HttpError(403, "You can only edit pins you submitted");
    }

    const hasLocation = body.lat !== undefined && body.lng !== undefined;
    const result = await pool.query(
      `UPDATE verified_pins
       SET name = COALESCE($2, name),
           category = COALESCE($3, category),
           description = COALESCE($4, description),
           country = COALESCE($5, country),
           city = COALESCE($6, city),
           location = CASE WHEN $7 THEN ST_MakePoint($9, $8)::geography ELSE location END,
           photo_urls = COALESCE($10, photo_urls),
           updated_at = now()
       WHERE id = $1
       RETURNING id, name, category, description, country, city,
                 ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
                 is_verified, is_scam_alert, safety_score, photo_urls`,
      [
        pinId,
        body.name ?? null,
        body.category ?? null,
        body.description ?? null,
        body.country ?? null,
        body.city ?? null,
        hasLocation,
        body.lat ?? 0,
        body.lng ?? 0,
        body.photoUrls ?? null,
      ]
    );

    // Editing a pin can drop photos from the array — free anything no
    // longer referenced, same as review photo edits.
    if (body.photoUrls) {
      const previousPhotoUrls: string[] = existing.rows[0].photo_urls ?? [];
      const removedUrls = previousPhotoUrls.filter((url) => !body.photoUrls!.includes(url));
      if (removedUrls.length > 0) {
        await deleteAssetsByUrls(removedUrls);
      }
    }

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// DELETE /pins/:id — only the original submitter may delete their pin.
pinsRouter.delete("/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);

    const existing = await pool.query("SELECT submitted_by, photo_urls FROM verified_pins WHERE id = $1", [pinId]);
    if (!existing.rowCount) throw new HttpError(404, "Pin not found");
    if (existing.rows[0].submitted_by !== req.userId) {
      throw new HttpError(403, "You can only delete pins you submitted");
    }

    await pool.query("DELETE FROM verified_pins WHERE id = $1", [pinId]);

    const photoUrls: string[] = existing.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) {
      await deleteAssetsByUrls(photoUrls);
    }

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// POST /pins/:id/checkin — one reward per user per pin per calendar day.
pinsRouter.post("/:id/checkin", requireAuth, async (req: AuthedRequest, res, next) => {
  const client = await pool.connect();
  try {
    const pinId = z.string().uuid().parse(req.params.id);

    await client.query("BEGIN");

    const pin = await client.query("SELECT id FROM verified_pins WHERE id = $1", [pinId]);
    if (!pin.rowCount) throw new HttpError(404, "Pin not found");

    const alreadyToday = await client.query(
      `SELECT id FROM pin_checkins
       WHERE user_id = $1 AND pin_id = $2 AND created_at >= date_trunc('day', now())`,
      [req.userId, pinId]
    );
    if (alreadyToday.rowCount) {
      throw new HttpError(409, "Already checked in here today");
    }

    await client.query(
      `INSERT INTO pin_checkins (user_id, pin_id, xp_awarded) VALUES ($1, $2, $3)`,
      [req.userId, pinId, CHECKIN_XP_REWARD]
    );

    const updated = await client.query(
      `UPDATE users SET xp = xp + $2, level = FLOOR((xp + $2) / 100) + 1, updated_at = now()
       WHERE id = $1
       RETURNING xp, level`,
      [req.userId, CHECKIN_XP_REWARD]
    );

    await client.query("COMMIT");

    res.status(201).json({
      xpAwarded: CHECKIN_XP_REWARD,
      xp: updated.rows[0].xp,
      level: updated.rows[0].level,
    });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});
