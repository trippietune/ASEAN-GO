import { Router } from "express";
import bcrypt from "bcryptjs";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { uploadSingleImage } from "../media/upload.middleware";
import { uploadAndRecord, deleteOwnAssetByUrl } from "../media/media.service";
import { CloudinaryNotConfiguredError } from "../media/cloudinary.client";
import { xpToNextLevel } from "./xp";

export const usersRouter = Router();

usersRouter.get("/me", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, email, display_name, auth_provider, avatar_url, home_country,
              xp, level, is_premium, coin_balance, created_at
       FROM users WHERE id = $1`,
      [req.userId]
    );
    const user = result.rows[0];
    if (!user) throw new HttpError(404, "User not found");

    res.json({ ...user, xpToNextLevel: xpToNextLevel(user.xp) });
  } catch (err) {
    next(err);
  }
});

usersRouter.get("/me/quests", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT uq.id, uq.status, uq.completed_at, q.id AS quest_id, q.title, q.description,
              q.quest_type, q.xp_reward, q.coin_reward, q.country
       FROM user_quests uq
       JOIN quests q ON q.id = uq.quest_id
       WHERE uq.user_id = $1
       ORDER BY uq.created_at DESC`,
      [req.userId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

// GET /users/me/achievements — every active, non-manual-only-visible
// achievement (manual ones still show up, they just can't be self-earned),
// with this user's unlock status. Show-not-hide, matching how locked quests
// are surfaced (decision carried over from the quest unlock system).
usersRouter.get("/me/achievements", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT a.id, a.title, a.description, a.icon_url, a.criteria_type, a.criteria_category,
              a.count_threshold, a.xp_reward, a.coin_reward,
              ua.unlocked_at
       FROM achievements a
       LEFT JOIN user_achievements ua ON ua.achievement_id = a.id AND ua.user_id = $1
       WHERE a.is_active = TRUE
       ORDER BY (ua.unlocked_at IS NULL), ua.unlocked_at DESC, a.created_at ASC`,
      [req.userId]
    );
    res.json(
      result.rows.map((row) => ({
        ...row,
        unlocked: row.unlocked_at !== null,
      }))
    );
  } catch (err) {
    next(err);
  }
});

const updateProfileSchema = z.object({
  displayName: z.string().min(1).max(80).optional(),
  avatarUrl: z.string().url().max(2000).optional(),
});

usersRouter.put("/me", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = updateProfileSchema.parse(req.body);
    if (Object.keys(body).length === 0) {
      throw new HttpError(400, "No fields to update");
    }

    const result = await pool.query(
      `UPDATE users
       SET display_name = COALESCE($2, display_name),
           avatar_url = COALESCE($3, avatar_url),
           updated_at = now()
       WHERE id = $1
       RETURNING id, email, display_name, auth_provider, avatar_url, home_country,
                 xp, level, is_premium, coin_balance, created_at`,
      [req.userId, body.displayName ?? null, body.avatarUrl ?? null]
    );
    const user = result.rows[0];
    res.json({ ...user, xpToNextLevel: xpToNextLevel(user.xp) });
  } catch (err) {
    next(err);
  }
});

// POST /users/me/avatar — always replaces the caller's own avatar: uploads
// the new image first, then deletes the previous one (if it was one of ours
// to begin with — an OAuth-provided avatar_url has no media_assets row and
// is silently skipped, matching deleteOwnAssetByUrl's no-op behavior).
usersRouter.post("/me/avatar", requireAuth, uploadSingleImage, async (req: AuthedRequest, res, next) => {
  try {
    if (!req.file) throw new HttpError(400, "No image file provided (expected multipart field 'image')");

    const previous = await pool.query("SELECT avatar_url FROM users WHERE id = $1", [req.userId]);
    const previousAvatarUrl = previous.rows[0]?.avatar_url as string | null | undefined;

    const asset = await uploadAndRecord(req.file.buffer, "avatar", req.userId!);

    const result = await pool.query(
      `UPDATE users SET avatar_url = $2, updated_at = now()
       WHERE id = $1
       RETURNING id, email, display_name, auth_provider, avatar_url, home_country,
                 xp, level, is_premium, coin_balance, created_at`,
      [req.userId, asset.url]
    );

    if (previousAvatarUrl) {
      await deleteOwnAssetByUrl(previousAvatarUrl, req.userId!);
    }

    const user = result.rows[0];
    res.json({ ...user, xpToNextLevel: xpToNextLevel(user.xp) });
  } catch (err) {
    next(err instanceof CloudinaryNotConfiguredError ? new HttpError(503, err.message) : err);
  }
});

const changePasswordSchema = z.object({
  currentPassword: z.string().min(1),
  newPassword: z.string().min(8),
});

usersRouter.put("/me/password", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { currentPassword, newPassword } = changePasswordSchema.parse(req.body);

    const result = await pool.query(
      "SELECT password_hash FROM users WHERE id = $1",
      [req.userId]
    );
    const passwordHash = result.rows[0]?.password_hash as string | null | undefined;
    if (!passwordHash) {
      throw new HttpError(400, "This account does not use a password (signed in via OAuth)");
    }

    const valid = await bcrypt.compare(currentPassword, passwordHash);
    if (!valid) {
      throw new HttpError(401, "Current password is incorrect");
    }

    const newHash = await bcrypt.hash(newPassword, 12);
    await pool.query(
      "UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1",
      [req.userId, newHash]
    );

    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});

usersRouter.get("/me/notification-settings", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      "SELECT notification_settings FROM users WHERE id = $1",
      [req.userId]
    );
    if (!result.rowCount) throw new HttpError(404, "User not found");
    res.json(result.rows[0].notification_settings);
  } catch (err) {
    next(err);
  }
});

const notificationSettingsSchema = z.object({
  pushNotifications: z.boolean(),
  emailNotifications: z.boolean(),
  safetyAlerts: z.boolean(),
  questReminders: z.boolean(),
  promotions: z.boolean(),
});

usersRouter.put("/me/notification-settings", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const settings = notificationSettingsSchema.parse(req.body);
    const result = await pool.query(
      `UPDATE users SET notification_settings = $2::jsonb, updated_at = now()
       WHERE id = $1 RETURNING notification_settings`,
      [req.userId, JSON.stringify(settings)]
    );
    res.json(result.rows[0].notification_settings);
  } catch (err) {
    next(err);
  }
});

usersRouter.get("/me/privacy-settings", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      "SELECT privacy_settings FROM users WHERE id = $1",
      [req.userId]
    );
    if (!result.rowCount) throw new HttpError(404, "User not found");
    res.json(result.rows[0].privacy_settings);
  } catch (err) {
    next(err);
  }
});

const privacySettingsSchema = z.object({
  showProfileToOthers: z.boolean(),
  showCheckins: z.boolean(),
  showReviews: z.boolean(),
  allowDataCollection: z.boolean(),
});

usersRouter.put("/me/privacy-settings", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const settings = privacySettingsSchema.parse(req.body);
    const result = await pool.query(
      `UPDATE users SET privacy_settings = $2::jsonb, updated_at = now()
       WHERE id = $1 RETURNING privacy_settings`,
      [req.userId, JSON.stringify(settings)]
    );
    res.json(result.rows[0].privacy_settings);
  } catch (err) {
    next(err);
  }
});
