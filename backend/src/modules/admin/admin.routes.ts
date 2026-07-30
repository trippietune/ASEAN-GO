import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth } from "../../middleware/auth";
import { requireAdmin, requireModerator, AdminRequest } from "../../middleware/adminAuth";
import { HttpError } from "../../middleware/errorHandler";
import { deleteAssetsByUrls } from "../media/media.service";

export const adminRouter = Router();

// Every route here requires a signed-in user whose current DB role is at
// least 'moderator'; a few destructive actions further require 'admin'.
// Scoped to /admin so this router — mounted at app root — doesn't act as a
// blanket auth gate for other root-mounted routers (e.g. the payments
// webhook, which Omise's servers call unauthenticated).
adminRouter.use("/admin", requireAuth, requireModerator);

// ---------------------------------------------------------------------------
// Stats overview
// ---------------------------------------------------------------------------

adminRouter.get("/admin/stats", async (_req, res, next) => {
  try {
    const [users, pins, quests, reviews, activeSos, riskReports, scamAlerts] = await Promise.all([
      pool.query("SELECT COUNT(*)::int AS total, COUNT(*) FILTER (WHERE created_at >= now() - interval '7 days')::int AS new_this_week FROM users"),
      pool.query("SELECT COUNT(*)::int AS total, COUNT(*) FILTER (WHERE is_verified)::int AS verified FROM verified_pins"),
      pool.query("SELECT COUNT(*)::int AS total FROM quests"),
      pool.query("SELECT COUNT(*)::int AS total, COALESCE(AVG(rating)::float, 0) AS average_rating FROM reviews"),
      pool.query("SELECT COUNT(*)::int AS total FROM sos_events WHERE status = 'active'"),
      pool.query("SELECT COUNT(*)::int AS total FROM risk_reports"),
      pool.query("SELECT COUNT(*)::int AS total FROM verified_pins WHERE is_scam_alert = TRUE"),
    ]);

    res.json({
      users: users.rows[0],
      pins: pins.rows[0],
      quests: quests.rows[0],
      reviews: reviews.rows[0],
      activeSosEvents: activeSos.rows[0].total,
      riskReports: riskReports.rows[0].total,
      scamAlerts: scamAlerts.rows[0].total,
    });
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Pins management
// ---------------------------------------------------------------------------

adminRouter.get("/admin/pins", async (req, res, next) => {
  try {
    const { search } = z.object({ search: z.string().max(200).optional() }).parse(req.query);
    const result = await pool.query(
      `SELECT p.id, p.name, p.category, p.country, p.city,
              ST_Y(p.location::geometry) AS lat, ST_X(p.location::geometry) AS lng,
              p.is_verified, p.is_scam_alert, p.scam_alert_message, p.safety_score,
              p.is_checkpoint, p.is_recommended,
              p.submitted_by, u.display_name AS submitted_by_name,
              p.created_at,
              COALESCE(r.review_count, 0) AS review_count,
              COALESCE(rr.report_count, 0) AS report_count
       FROM verified_pins p
       LEFT JOIN users u ON u.id = p.submitted_by
       LEFT JOIN (SELECT pin_id, COUNT(*)::int AS review_count FROM reviews GROUP BY pin_id) r ON r.pin_id = p.id
       LEFT JOIN (SELECT pin_id, COUNT(*)::int AS report_count FROM risk_reports GROUP BY pin_id) rr ON rr.pin_id = p.id
       WHERE ($1::text IS NULL OR p.name ILIKE '%' || $1 || '%' OR p.city ILIKE '%' || $1 || '%')
       ORDER BY p.created_at DESC
       LIMIT 500`,
      [search ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const updatePinAdminSchema = z.object({
  isVerified: z.boolean().optional(),
  isScamAlert: z.boolean().optional(),
  scamAlertMessage: z.string().max(1000).nullable().optional(),
  safetyScore: z.number().int().min(0).max(100).optional(),
  isCheckpoint: z.boolean().optional(),
  isRecommended: z.boolean().optional(),
});

adminRouter.put("/admin/pins/:id", async (req: AdminRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const body = updatePinAdminSchema.parse(req.body);
    if (Object.keys(body).length === 0) throw new HttpError(400, "No fields to update");

    const result = await pool.query(
      `UPDATE verified_pins
       SET is_verified = COALESCE($2, is_verified),
           is_scam_alert = COALESCE($3, is_scam_alert),
           scam_alert_message = CASE WHEN $4::boolean THEN $5 ELSE scam_alert_message END,
           safety_score = COALESCE($6, safety_score),
           approved_by = CASE WHEN $2 = TRUE THEN $7 ELSE approved_by END,
           is_checkpoint = COALESCE($8, is_checkpoint),
           is_recommended = COALESCE($9, is_recommended),
           updated_at = now()
       WHERE id = $1
       RETURNING id, name, is_verified, is_scam_alert, scam_alert_message, safety_score, is_checkpoint, is_recommended`,
      [
        pinId,
        body.isVerified ?? null,
        body.isScamAlert ?? null,
        "scamAlertMessage" in body,
        body.scamAlertMessage ?? null,
        body.safetyScore ?? null,
        req.userId,
        body.isCheckpoint ?? null,
        body.isRecommended ?? null,
      ]
    );
    if (!result.rowCount) throw new HttpError(404, "Pin not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/pins/:id", requireAdmin, async (req, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const result = await pool.query("DELETE FROM verified_pins WHERE id = $1 RETURNING photo_urls", [pinId]);
    if (!result.rowCount) throw new HttpError(404, "Pin not found");

    const photoUrls: string[] = result.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) await deleteAssetsByUrls(photoUrls);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Quests management
// ---------------------------------------------------------------------------

adminRouter.get("/admin/quests", async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT q.id, q.title, q.description, q.quest_type, q.xp_reward, q.coin_reward,
              q.pin_id, p.name AS pin_name, q.country, q.active_from, q.active_until, q.created_at,
              COALESCE(uq.completed_count, 0) AS completed_count
       FROM quests q
       LEFT JOIN verified_pins p ON p.id = q.pin_id
       LEFT JOIN (
         SELECT quest_id, COUNT(*)::int AS completed_count FROM user_quests
         WHERE status = 'completed' GROUP BY quest_id
       ) uq ON uq.quest_id = q.id
       ORDER BY q.created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createQuestSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  questType: z.enum(["daily", "weekly", "recommended"]).default("daily"),
  xpReward: z.number().int().min(0).max(100_000).default(0),
  coinReward: z.number().int().min(0).max(100_000).default(0),
  pinId: z.string().uuid().optional(),
  country: z.string().max(100).optional(),
  activeUntil: z.string().datetime().optional(),
});

adminRouter.post("/admin/quests", async (req, res, next) => {
  try {
    const body = createQuestSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO quests (title, description, quest_type, xp_reward, coin_reward, pin_id, country, active_until)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING id, title, description, quest_type, xp_reward, coin_reward, pin_id, country, active_until, created_at`,
      [
        body.title,
        body.description ?? null,
        body.questType,
        body.xpReward,
        body.coinReward,
        body.pinId ?? null,
        body.country ?? null,
        body.activeUntil ?? null,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updateQuestSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).nullable().optional(),
  questType: z.enum(["daily", "weekly", "recommended"]).optional(),
  xpReward: z.number().int().min(0).max(100_000).optional(),
  coinReward: z.number().int().min(0).max(100_000).optional(),
  pinId: z.string().uuid().nullable().optional(),
  country: z.string().max(100).nullable().optional(),
  activeUntil: z.string().datetime().nullable().optional(),
});

adminRouter.put("/admin/quests/:id", async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const body = updateQuestSchema.parse(req.body);
    if (Object.keys(body).length === 0) throw new HttpError(400, "No fields to update");

    const result = await pool.query(
      `UPDATE quests
       SET title = COALESCE($2, title),
           description = CASE WHEN $3 THEN $4 ELSE description END,
           quest_type = COALESCE($5, quest_type),
           xp_reward = COALESCE($6, xp_reward),
           coin_reward = COALESCE($7, coin_reward),
           pin_id = CASE WHEN $8 THEN $9 ELSE pin_id END,
           country = CASE WHEN $10 THEN $11 ELSE country END,
           active_until = CASE WHEN $12 THEN $13 ELSE active_until END
       WHERE id = $1
       RETURNING id, title, description, quest_type, xp_reward, coin_reward, pin_id, country, active_until`,
      [
        questId,
        body.title ?? null,
        "description" in body,
        body.description ?? null,
        body.questType ?? null,
        body.xpReward ?? null,
        body.coinReward ?? null,
        "pinId" in body,
        body.pinId ?? null,
        "country" in body,
        body.country ?? null,
        "activeUntil" in body,
        body.activeUntil ?? null,
      ]
    );
    if (!result.rowCount) throw new HttpError(404, "Quest not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/quests/:id", requireAdmin, async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const result = await pool.query("DELETE FROM quests WHERE id = $1", [questId]);
    if (!result.rowCount) throw new HttpError(404, "Quest not found");
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Users management
// ---------------------------------------------------------------------------

adminRouter.get("/admin/users", async (req, res, next) => {
  try {
    const { search } = z.object({ search: z.string().max(200).optional() }).parse(req.query);
    const result = await pool.query(
      `SELECT id, email, display_name, role, auth_provider, xp, level,
              is_premium, coin_balance, created_at
       FROM users
       WHERE ($1::text IS NULL OR email ILIKE '%' || $1 || '%' OR display_name ILIKE '%' || $1 || '%')
       ORDER BY created_at DESC
       LIMIT 500`,
      [search ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const updateRoleSchema = z.object({
  role: z.enum(["user", "admin", "moderator"]),
});

// Only admins may change roles — a moderator granting itself admin would be
// a privilege-escalation hole.
adminRouter.put("/admin/users/:id/role", requireAdmin, async (req: AdminRequest, res, next) => {
  try {
    const userId = z.string().uuid().parse(req.params.id);
    const { role } = updateRoleSchema.parse(req.body);

    if (userId === req.userId && role !== "admin") {
      throw new HttpError(400, "You cannot remove your own admin role");
    }

    const result = await pool.query(
      "UPDATE users SET role = $2, updated_at = now() WHERE id = $1 RETURNING id, email, display_name, role",
      [userId, role]
    );
    if (!result.rowCount) throw new HttpError(404, "User not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Reviews moderation
// ---------------------------------------------------------------------------

adminRouter.get("/admin/reviews", async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT r.id, r.pin_id, p.name AS pin_name, r.user_id, u.display_name AS user_display_name,
              r.rating, r.comment, r.photo_urls, r.created_at
       FROM reviews r
       JOIN users u ON u.id = r.user_id
       JOIN verified_pins p ON p.id = r.pin_id
       ORDER BY r.created_at DESC
       LIMIT 500`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/reviews/:id", async (req, res, next) => {
  try {
    const reviewId = z.string().uuid().parse(req.params.id);
    const result = await pool.query("DELETE FROM reviews WHERE id = $1 RETURNING photo_urls", [reviewId]);
    if (!result.rowCount) throw new HttpError(404, "Review not found");

    const photoUrls: string[] = result.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) await deleteAssetsByUrls(photoUrls);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Safety: risk reports, SOS events
// ---------------------------------------------------------------------------

adminRouter.get("/admin/risk-reports", async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT rr.id, rr.pin_id, p.name AS pin_name, rr.reported_by,
              u.display_name AS reporter_display_name, rr.severity, rr.description, rr.created_at
       FROM risk_reports rr
       JOIN users u ON u.id = rr.reported_by
       JOIN verified_pins p ON p.id = rr.pin_id
       ORDER BY rr.created_at DESC
       LIMIT 500`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/risk-reports/:id", async (req, res, next) => {
  try {
    const reportId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      "DELETE FROM risk_reports WHERE id = $1 RETURNING photo_urls",
      [reportId]
    );
    if (!result.rowCount) throw new HttpError(404, "Risk report not found");

    const photoUrls: string[] = result.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) await deleteAssetsByUrls(photoUrls);

    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

adminRouter.get("/admin/sos-events", async (req, res, next) => {
  try {
    const { status } = z.object({ status: z.enum(["active", "resolved"]).optional() }).parse(req.query);
    const result = await pool.query(
      `SELECT s.id, s.user_id, u.display_name AS user_display_name, u.emergency_contact_name,
              u.emergency_contact_phone,
              ST_Y(s.location::geometry) AS lat, ST_X(s.location::geometry) AS lng,
              s.status, s.created_at, s.resolved_at
       FROM sos_events s
       JOIN users u ON u.id = s.user_id
       WHERE ($1::text IS NULL OR s.status = $1)
       ORDER BY s.created_at DESC
       LIMIT 500`,
      [status ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

// Lets an admin close out an SOS event on the user's behalf (e.g. after
// confirming by phone the traveler is safe but they can't reach the app).
adminRouter.post("/admin/sos-events/:id/resolve", async (req, res, next) => {
  try {
    const eventId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `UPDATE sos_events SET status = 'resolved', resolved_at = now()
       WHERE id = $1 AND status = 'active'
       RETURNING id, status, resolved_at`,
      [eventId]
    );
    if (!result.rowCount) throw new HttpError(404, "SOS event not found or already resolved");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Emergency contacts (read-only view for support/verification purposes)
// ---------------------------------------------------------------------------

adminRouter.get("/admin/emergency-contacts", async (req, res, next) => {
  try {
    const { search } = z.object({ search: z.string().max(200).optional() }).parse(req.query);
    const result = await pool.query(
      `SELECT id, email, display_name, emergency_contact_name, emergency_contact_phone
       FROM users
       WHERE emergency_contact_phone IS NOT NULL
         AND ($1::text IS NULL OR email ILIKE '%' || $1 || '%' OR display_name ILIKE '%' || $1 || '%')
       ORDER BY display_name ASC
       LIMIT 500`,
      [search ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});
