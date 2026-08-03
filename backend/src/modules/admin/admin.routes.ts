import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth } from "../../middleware/auth";
import { requireAdmin, requireModerator, AdminRequest } from "../../middleware/adminAuth";
import { HttpError } from "../../middleware/errorHandler";
import { deleteAssetsByUrls } from "../media/media.service";
import { QUEST_TYPES } from "../quests/quest-types";
import { cleanupDanglingChapterRequirements, relinkChapterRequirements } from "../quests/chapters.service";

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

const pinCategorySchema = z.enum(["food", "shop", "attraction", "transport", "lodging", "other"]);

const createPinAdminSchema = z.object({
  name: z.string().min(1).max(200),
  category: pinCategorySchema,
  description: z.string().max(2000).optional(),
  country: z.string().min(1).max(100),
  city: z.string().max(100).optional(),
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// Admin-only: creates a pin directly from the dashboard, immediately verified.
adminRouter.post("/admin/pins", requireAdmin, async (req: AdminRequest, res, next) => {
  try {
    const body = createPinAdminSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO verified_pins (name, category, description, country, city, location, submitted_by, approved_by, is_verified, photo_urls)
       VALUES ($1, $2, $3, $4, $5, ST_MakePoint($7, $6)::geography, $8, $8, TRUE, $9)
       RETURNING id, name, category, description, country, city,
                 ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng,
                 is_verified, is_scam_alert, safety_score, is_checkpoint, is_recommended, photo_urls, created_at`,
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

const updatePinAdminSchema = z.object({
  isVerified: z.boolean().optional(),
  isScamAlert: z.boolean().optional(),
  scamAlertMessage: z.string().max(1000).nullable().optional(),
  safetyScore: z.number().int().min(0).max(100).optional(),
  isCheckpoint: z.boolean().optional(),
  isRecommended: z.boolean().optional(),
});

// Admin-only: creating/editing/deleting pin records directly is restricted
// to admins to prevent duplicate/spam/false listings — moderators can still
// view pins and moderate the pin-suggestions queue (reject, or read the
// list), but the source-of-truth verified_pins table itself is admin-only.
adminRouter.put("/admin/pins/:id", requireAdmin, async (req: AdminRequest, res, next) => {
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
// Pin suggestions moderation queue
// ---------------------------------------------------------------------------

adminRouter.get("/admin/pin-suggestions", async (req, res, next) => {
  try {
    const { status } = z.object({ status: z.enum(["pending", "approved", "rejected"]).optional() }).parse(req.query);
    const result = await pool.query(
      `SELECT s.id, s.name, s.category, s.description, s.country, s.city,
              ST_Y(s.location::geometry) AS lat, ST_X(s.location::geometry) AS lng,
              s.photo_urls, s.submitted_by, u.display_name AS submitted_by_name,
              s.status, s.reviewed_by, s.reviewed_at, s.rejection_reason,
              s.resulting_pin_id, s.created_at
       FROM pin_suggestions s
       JOIN users u ON u.id = s.submitted_by
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

// Approving a suggestion creates a real, verified pin — same bar as direct
// pin creation (POST /pins, POST /admin/pins), so this is admin-only even
// though the rest of the moderation queue only needs moderator.
adminRouter.put("/admin/pin-suggestions/:id/approve", requireAdmin, async (req: AdminRequest, res, next) => {
  const client = await pool.connect();
  try {
    const suggestionId = z.string().uuid().parse(req.params.id);
    await client.query("BEGIN");

    // FOR UPDATE + the pending check below guards against a double-approve
    // race (two admins clicking approve on the same suggestion at once).
    const suggestion = await client.query("SELECT * FROM pin_suggestions WHERE id = $1 FOR UPDATE", [suggestionId]);
    if (!suggestion.rowCount) throw new HttpError(404, "Suggestion not found");
    const s = suggestion.rows[0];
    if (s.status !== "pending") throw new HttpError(409, "Suggestion already reviewed");

    const pin = await client.query(
      `INSERT INTO verified_pins (name, category, description, country, city, location, submitted_by, approved_by, is_verified, photo_urls)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, TRUE, $9)
       RETURNING id, name, category, description, country, city,
                 ST_Y(location::geometry) AS lat, ST_X(location::geometry) AS lng, is_verified, photo_urls`,
      [s.name, s.category, s.description, s.country, s.city, s.location, s.submitted_by, req.userId, s.photo_urls]
    );

    await client.query(
      `UPDATE pin_suggestions
       SET status = 'approved', reviewed_by = $2, reviewed_at = now(), resulting_pin_id = $3, updated_at = now()
       WHERE id = $1`,
      [suggestionId, req.userId, pin.rows[0].id]
    );

    await client.query("COMMIT");
    res.json({ suggestion: { id: suggestionId, status: "approved", resultingPinId: pin.rows[0].id }, pin: pin.rows[0] });
  } catch (err) {
    await client.query("ROLLBACK");
    next(err);
  } finally {
    client.release();
  }
});

const rejectSuggestionSchema = z.object({ reason: z.string().max(1000).optional() });

adminRouter.put("/admin/pin-suggestions/:id/reject", async (req: AdminRequest, res, next) => {
  try {
    const suggestionId = z.string().uuid().parse(req.params.id);
    const { reason } = rejectSuggestionSchema.parse(req.body);

    const result = await pool.query(
      `UPDATE pin_suggestions
       SET status = 'rejected', reviewed_by = $2, reviewed_at = now(), rejection_reason = $3, updated_at = now()
       WHERE id = $1 AND status = 'pending'
       RETURNING id, status, rejection_reason, photo_urls`,
      [suggestionId, req.userId, reason ?? null]
    );
    if (!result.rowCount) throw new HttpError(404, "Suggestion not found or already reviewed");

    const photoUrls: string[] = result.rows[0].photo_urls ?? [];
    if (photoUrls.length > 0) await deleteAssetsByUrls(photoUrls);

    res.json({ id: result.rows[0].id, status: result.rows[0].status, rejectionReason: result.rows[0].rejection_reason });
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
      `SELECT q.id, q.title, q.description, q.quest_type, q.category, q.chapter_id, q.chapter_order,
              q.xp_reward, q.coin_reward,
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
  questType: z.enum(QUEST_TYPES).default("daily"),
  category: z.string().max(50).optional(),
  chapterId: z.string().uuid().optional(),
  chapterOrder: z.number().int().min(1).max(1000).optional(),
  xpReward: z.number().int().min(0).max(100_000).default(0),
  coinReward: z.number().int().min(0).max(100_000).default(0),
  pinId: z.string().uuid().optional(),
  country: z.string().max(100).optional(),
  activeUntil: z.string().datetime().optional(),
});

// Setting a quest's pinId is a UX convenience for "this quest requires a
// check-in at this pin" — it auto-creates/updates/removes a plain
// source='admin' checkin unlock requirement row so POST /quests/complete's
// single unlock-evaluator gate covers it, instead of a second parallel
// pin_id-specific check. Editable/deletable afterward like any other row.
async function syncCheckinRequirement(questId: string, pinId: string | null) {
  await pool.query(`DELETE FROM quest_unlock_requirements WHERE quest_id = $1 AND requirement_type = 'checkin'`, [questId]);
  if (pinId) {
    await pool.query(
      `INSERT INTO quest_unlock_requirements (quest_id, requirement_type, required_pin_id, source)
       VALUES ($1, 'checkin', $2, 'admin')`,
      [questId, pinId]
    );
  }
}

adminRouter.post("/admin/quests", async (req, res, next) => {
  try {
    const body = createQuestSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO quests (title, description, quest_type, category, chapter_id, chapter_order, xp_reward, coin_reward, pin_id, country, active_until)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       RETURNING id, title, description, quest_type, category, chapter_id, chapter_order, xp_reward, coin_reward, pin_id, country, active_until, created_at`,
      [
        body.title,
        body.description ?? null,
        body.questType,
        body.category ?? null,
        body.chapterId ?? null,
        body.chapterOrder ?? null,
        body.xpReward,
        body.coinReward,
        body.pinId ?? null,
        body.country ?? null,
        body.activeUntil ?? null,
      ]
    );
    if (body.pinId) {
      await syncCheckinRequirement(result.rows[0].id, body.pinId);
    }
    if (body.chapterId) {
      await relinkChapterRequirements(body.chapterId);
    }
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updateQuestSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).nullable().optional(),
  questType: z.enum(QUEST_TYPES).optional(),
  category: z.string().max(50).nullable().optional(),
  chapterId: z.string().uuid().nullable().optional(),
  chapterOrder: z.number().int().min(1).max(1000).nullable().optional(),
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

    const before = await pool.query<{ chapter_id: string | null }>("SELECT chapter_id FROM quests WHERE id = $1", [questId]);
    const previousChapterId = before.rows[0]?.chapter_id ?? null;

    const result = await pool.query(
      `UPDATE quests
       SET title = COALESCE($2, title),
           description = CASE WHEN $3 THEN $4 ELSE description END,
           quest_type = COALESCE($5, quest_type),
           category = CASE WHEN $6 THEN $7 ELSE category END,
           chapter_id = CASE WHEN $8 THEN $9 ELSE chapter_id END,
           chapter_order = CASE WHEN $10 THEN $11 ELSE chapter_order END,
           xp_reward = COALESCE($12, xp_reward),
           coin_reward = COALESCE($13, coin_reward),
           pin_id = CASE WHEN $14 THEN $15 ELSE pin_id END,
           country = CASE WHEN $16 THEN $17 ELSE country END,
           active_until = CASE WHEN $18 THEN $19 ELSE active_until END
       WHERE id = $1
       RETURNING id, title, description, quest_type, category, chapter_id, chapter_order, xp_reward, coin_reward, pin_id, country, active_until`,
      [
        questId,
        body.title ?? null,
        "description" in body,
        body.description ?? null,
        body.questType ?? null,
        "category" in body,
        body.category ?? null,
        "chapterId" in body,
        body.chapterId ?? null,
        "chapterOrder" in body,
        body.chapterOrder ?? null,
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
    if ("pinId" in body) {
      await syncCheckinRequirement(questId, result.rows[0].pin_id);
    }
    const newChapterId = result.rows[0].chapter_id as string | null;
    if (("chapterId" in body || "chapterOrder" in body) && (previousChapterId || newChapterId)) {
      // Relink whichever chapter(s) actually changed — a quest moving
      // between chapters needs both the old chapter (to close the gap it
      // left behind) and the new one (to insert it into the sequence)
      // recomputed.
      if (previousChapterId && previousChapterId !== newChapterId) {
        await relinkChapterRequirements(previousChapterId);
      }
      if (newChapterId) {
        await relinkChapterRequirements(newChapterId);
      }
    }
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/quests/:id", requireAdmin, async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const before = await pool.query<{ chapter_id: string | null }>("SELECT chapter_id FROM quests WHERE id = $1", [questId]);
    const chapterId = before.rows[0]?.chapter_id ?? null;

    const result = await pool.query("DELETE FROM quests WHERE id = $1", [questId]);
    if (!result.rowCount) throw new HttpError(404, "Quest not found");

    if (chapterId) {
      await relinkChapterRequirements(chapterId);
    }
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Quest unlock requirements — admin-editable gating rules for a quest.
// Rows with source='chapter_auto' (Phase 3's chapter sequencing) aren't
// created here, but they're readable/deletable through these same routes
// like any other row — deleting one just re-locks that link until the
// chapter's relink logic recreates it.
// ---------------------------------------------------------------------------

adminRouter.get("/admin/quests/:id/unlock-requirements", async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `SELECT id, quest_id, requirement_type, min_level, required_quest_id, required_pin_id,
              category, country, city, count_threshold, source, created_at
       FROM quest_unlock_requirements
       WHERE quest_id = $1
       ORDER BY created_at ASC`,
      [questId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createUnlockRequirementSchema = z.object({
  requirementType: z.enum(["level", "quest", "checkin", "category", "location"]),
  minLevel: z.number().int().min(1).max(1000).optional(),
  requiredQuestId: z.string().uuid().optional(),
  requiredPinId: z.string().uuid().optional(),
  category: z.string().max(50).optional(),
  country: z.string().max(100).optional(),
  city: z.string().max(100).optional(),
  countThreshold: z.number().int().min(1).max(100_000).optional(),
});

adminRouter.post("/admin/quests/:id/unlock-requirements", async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const body = createUnlockRequirementSchema.parse(req.body);
    const questExists = await pool.query("SELECT id FROM quests WHERE id = $1", [questId]);
    if (!questExists.rowCount) throw new HttpError(404, "Quest not found");

    const result = await pool.query(
      `INSERT INTO quest_unlock_requirements
         (quest_id, requirement_type, min_level, required_quest_id, required_pin_id, category, country, city, count_threshold, source)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'admin')
       RETURNING id, quest_id, requirement_type, min_level, required_quest_id, required_pin_id,
                 category, country, city, count_threshold, source, created_at`,
      [
        questId,
        body.requirementType,
        body.minLevel ?? null,
        body.requiredQuestId ?? null,
        body.requiredPinId ?? null,
        body.category ?? null,
        body.country ?? null,
        body.city ?? null,
        body.countThreshold ?? null,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/quests/:id/unlock-requirements/:requirementId", requireAdmin, async (req, res, next) => {
  try {
    const questId = z.string().uuid().parse(req.params.id);
    const requirementId = z.string().uuid().parse(req.params.requirementId);
    const result = await pool.query(
      "DELETE FROM quest_unlock_requirements WHERE id = $1 AND quest_id = $2",
      [requirementId, questId]
    );
    if (!result.rowCount) throw new HttpError(404, "Unlock requirement not found");
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Story chapters
// ---------------------------------------------------------------------------

adminRouter.get("/admin/quest-chapters", async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT c.id, c.title, c.description, c.order_index, c.created_at, c.updated_at,
              COUNT(q.id)::int AS quest_count
       FROM quest_chapters c
       LEFT JOIN quests q ON q.chapter_id = c.id
       GROUP BY c.id
       ORDER BY c.order_index ASC`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createChapterSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  orderIndex: z.number().int().min(1).max(100_000),
});

adminRouter.post("/admin/quest-chapters", async (req, res, next) => {
  try {
    const body = createChapterSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO quest_chapters (title, description, order_index)
       VALUES ($1, $2, $3)
       RETURNING id, title, description, order_index, created_at, updated_at`,
      [body.title, body.description ?? null, body.orderIndex]
    );
    res.status(201).json({ ...result.rows[0], quest_count: 0 });
  } catch (err) {
    next(err);
  }
});

const updateChapterSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).nullable().optional(),
  orderIndex: z.number().int().min(1).max(100_000).optional(),
});

adminRouter.put("/admin/quest-chapters/:id", async (req, res, next) => {
  try {
    const chapterId = z.string().uuid().parse(req.params.id);
    const body = updateChapterSchema.parse(req.body);
    if (Object.keys(body).length === 0) throw new HttpError(400, "No fields to update");

    const result = await pool.query(
      `UPDATE quest_chapters
       SET title = COALESCE($2, title),
           description = CASE WHEN $3 THEN $4 ELSE description END,
           order_index = COALESCE($5, order_index),
           updated_at = now()
       WHERE id = $1
       RETURNING id, title, description, order_index, created_at, updated_at`,
      [chapterId, body.title ?? null, "description" in body, body.description ?? null, body.orderIndex ?? null]
    );
    if (!result.rowCount) throw new HttpError(404, "Chapter not found");

    // Reordering a chapter can change which chapter precedes/follows it, so
    // its own auto-chained gate (and its neighbors') needs recomputing.
    if ("orderIndex" in body) {
      await relinkChapterRequirements(chapterId);
    }
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// Deleting a chapter orphans its quests (ON DELETE SET NULL) rather than
// blocking deletion or cascading — they keep their completion history, they
// just lose chapter grouping/gating. Their chapter_auto requirement rows
// (which pointed into/out of this chapter) are cleaned up so a deleted
// chapter doesn't leave phantom gates behind.
adminRouter.delete("/admin/quest-chapters/:id", requireAdmin, async (req, res, next) => {
  try {
    const chapterId = z.string().uuid().parse(req.params.id);
    const questsInChapter = await pool.query<{ id: string }>("SELECT id FROM quests WHERE chapter_id = $1", [chapterId]);

    const result = await pool.query("DELETE FROM quest_chapters WHERE id = $1", [chapterId]);
    if (!result.rowCount) throw new HttpError(404, "Chapter not found");

    await cleanupDanglingChapterRequirements(questsInChapter.rows.map((q) => q.id));
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// ---------------------------------------------------------------------------
// Achievements
// ---------------------------------------------------------------------------

const ACHIEVEMENT_CRITERIA_TYPES = [
  "quests_completed",
  "checkins",
  "level_reached",
  "category_visits",
  "chapter_completed",
  "manual",
] as const;

adminRouter.get("/admin/achievements", async (_req, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, title, description, icon_url, criteria_type, criteria_category, criteria_chapter_id,
              count_threshold, xp_reward, coin_reward, is_active, created_at, updated_at
       FROM achievements
       ORDER BY created_at DESC`
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createAchievementSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
  iconUrl: z.string().url().optional(),
  criteriaType: z.enum(ACHIEVEMENT_CRITERIA_TYPES),
  criteriaCategory: z.string().max(50).optional(),
  criteriaChapterId: z.string().uuid().optional(),
  countThreshold: z.number().int().min(1).max(1_000_000).optional(),
  xpReward: z.number().int().min(0).max(100_000).default(0),
  coinReward: z.number().int().min(0).max(100_000).default(0),
  isActive: z.boolean().default(true),
});

adminRouter.post("/admin/achievements", async (req, res, next) => {
  try {
    const body = createAchievementSchema.parse(req.body);
    const result = await pool.query(
      `INSERT INTO achievements
         (title, description, icon_url, criteria_type, criteria_category, criteria_chapter_id, count_threshold, xp_reward, coin_reward, is_active)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
       RETURNING id, title, description, icon_url, criteria_type, criteria_category, criteria_chapter_id,
                 count_threshold, xp_reward, coin_reward, is_active, created_at, updated_at`,
      [
        body.title,
        body.description ?? null,
        body.iconUrl ?? null,
        body.criteriaType,
        body.criteriaCategory ?? null,
        body.criteriaChapterId ?? null,
        body.countThreshold ?? null,
        body.xpReward,
        body.coinReward,
        body.isActive,
      ]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updateAchievementSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  description: z.string().max(2000).nullable().optional(),
  iconUrl: z.string().url().nullable().optional(),
  criteriaType: z.enum(ACHIEVEMENT_CRITERIA_TYPES).optional(),
  criteriaCategory: z.string().max(50).nullable().optional(),
  criteriaChapterId: z.string().uuid().nullable().optional(),
  countThreshold: z.number().int().min(1).max(1_000_000).nullable().optional(),
  xpReward: z.number().int().min(0).max(100_000).optional(),
  coinReward: z.number().int().min(0).max(100_000).optional(),
  isActive: z.boolean().optional(),
});

adminRouter.put("/admin/achievements/:id", async (req, res, next) => {
  try {
    const achievementId = z.string().uuid().parse(req.params.id);
    const body = updateAchievementSchema.parse(req.body);
    if (Object.keys(body).length === 0) throw new HttpError(400, "No fields to update");

    const result = await pool.query(
      `UPDATE achievements
       SET title = COALESCE($2, title),
           description = CASE WHEN $3 THEN $4 ELSE description END,
           icon_url = CASE WHEN $5 THEN $6 ELSE icon_url END,
           criteria_type = COALESCE($7, criteria_type),
           criteria_category = CASE WHEN $8 THEN $9 ELSE criteria_category END,
           criteria_chapter_id = CASE WHEN $10 THEN $11 ELSE criteria_chapter_id END,
           count_threshold = CASE WHEN $12 THEN $13 ELSE count_threshold END,
           xp_reward = COALESCE($14, xp_reward),
           coin_reward = COALESCE($15, coin_reward),
           is_active = COALESCE($16, is_active),
           updated_at = now()
       WHERE id = $1
       RETURNING id, title, description, icon_url, criteria_type, criteria_category, criteria_chapter_id,
                 count_threshold, xp_reward, coin_reward, is_active, created_at, updated_at`,
      [
        achievementId,
        body.title ?? null,
        "description" in body,
        body.description ?? null,
        "iconUrl" in body,
        body.iconUrl ?? null,
        body.criteriaType ?? null,
        "criteriaCategory" in body,
        body.criteriaCategory ?? null,
        "criteriaChapterId" in body,
        body.criteriaChapterId ?? null,
        "countThreshold" in body,
        body.countThreshold ?? null,
        body.xpReward ?? null,
        body.coinReward ?? null,
        body.isActive ?? null,
      ]
    );
    if (!result.rowCount) throw new HttpError(404, "Achievement not found");
    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

adminRouter.delete("/admin/achievements/:id", requireAdmin, async (req, res, next) => {
  try {
    const achievementId = z.string().uuid().parse(req.params.id);
    const result = await pool.query("DELETE FROM achievements WHERE id = $1", [achievementId]);
    if (!result.rowCount) throw new HttpError(404, "Achievement not found");
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});

// Admin-only manual override — bypasses criteria evaluation entirely and
// grants any achievement (including 'manual'-type ones, which have no other
// path to being unlocked) directly to a user.
adminRouter.post("/admin/achievements/:id/grant", requireAdmin, async (req, res, next) => {
  try {
    const achievementId = z.string().uuid().parse(req.params.id);
    const { userId } = z.object({ userId: z.string().uuid() }).parse(req.body);

    const achievement = await pool.query("SELECT id FROM achievements WHERE id = $1", [achievementId]);
    if (!achievement.rowCount) throw new HttpError(404, "Achievement not found");
    const user = await pool.query("SELECT id FROM users WHERE id = $1", [userId]);
    if (!user.rowCount) throw new HttpError(404, "User not found");

    const result = await pool.query(
      `INSERT INTO user_achievements (user_id, achievement_id) VALUES ($1, $2)
       ON CONFLICT DO NOTHING
       RETURNING id, user_id, achievement_id, unlocked_at`,
      [userId, achievementId]
    );
    if (!result.rowCount) throw new HttpError(409, "User already has this achievement");
    res.status(201).json(result.rows[0]);
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
