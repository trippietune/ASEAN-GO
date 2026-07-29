import { pool } from "../../db/pool";
import { destroyImage, uploadImage, UploadResult } from "./cloudinary.client";

export type MediaPurpose = "avatar" | "review_photo" | "pin_photo" | "risk_report_photo";

export interface MediaAsset {
  id: string;
  url: string;
  publicId: string;
}

/// Uploads to Cloudinary and records the asset in one step, so every image
/// that ever lands in Cloudinary through this backend has a corresponding
/// media_assets row — the only way we can find and delete it later.
export async function uploadAndRecord(
  buffer: Buffer,
  purpose: MediaPurpose,
  userId: string
): Promise<MediaAsset> {
  const result: UploadResult = await uploadImage(buffer, purpose);

  const inserted = await pool.query(
    `INSERT INTO media_assets (uploaded_by, purpose, provider, public_id, url, width, height, bytes)
     VALUES ($1, $2, 'cloudinary', $3, $4, $5, $6, $7)
     RETURNING id, url, public_id`,
    [userId, purpose, result.publicId, result.url, result.width, result.height, result.bytes]
  );

  return {
    id: inserted.rows[0].id,
    url: inserted.rows[0].url,
    publicId: inserted.rows[0].public_id,
  };
}

/// Looks up a media_assets row by URL and deletes it from Cloudinary, then
/// marks it deleted_at locally (row is kept for audit rather than dropped —
/// there's no undo on the Cloudinary side once destroy() runs).
/// Safe to call with a URL that isn't one of ours (e.g. legacy client-pasted
/// review photo URLs from before this system existed) — it's a no-op then.
///
/// Internal/trusted use only (e.g. replacing a user's own avatar, cleaning
/// up after we delete a review/pin/report we already loaded and checked
/// ownership on) — does not itself verify who uploaded the asset. For a
/// user-facing "delete this" action, use deleteOwnAssetByUrl instead.
async function deleteAssetByUrl(url: string): Promise<void> {
  const result = await pool.query(
    "SELECT id, public_id FROM media_assets WHERE url = $1 AND deleted_at IS NULL",
    [url]
  );
  if (!result.rowCount) return;

  const { id, public_id: publicId } = result.rows[0];
  await destroyImage(publicId);
  await pool.query("UPDATE media_assets SET deleted_at = now() WHERE id = $1", [id]);
}

/// User-facing delete: only removes the asset if this user is the one who
/// uploaded it, so one user can't delete another's photo by guessing/
/// observing its URL. Silent no-op if it's not theirs or not ours to begin
/// with — the client can't distinguish "not found" from "not yours" and
/// doesn't need to.
export async function deleteOwnAssetByUrl(url: string, userId: string): Promise<void> {
  const result = await pool.query(
    "SELECT id, public_id FROM media_assets WHERE url = $1 AND uploaded_by = $2 AND deleted_at IS NULL",
    [url, userId]
  );
  if (!result.rowCount) return;

  const { id, public_id: publicId } = result.rows[0];
  await destroyImage(publicId);
  await pool.query("UPDATE media_assets SET deleted_at = now() WHERE id = $1", [id]);
}

/// Cleanup after we delete/replace an entity we've already authorized the
/// caller against (e.g. "you may only edit pins you submitted" already
/// checked by the route). Deletes every URL that has a live media_assets
/// row; URLs from before this upload system existed are silently skipped.
export async function deleteAssetsByUrls(urls: string[]): Promise<void> {
  await Promise.all(urls.map((url) => deleteAssetByUrl(url)));
}
