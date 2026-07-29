import { Router } from "express";
import { z } from "zod";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { uploadSingleImage } from "./upload.middleware";
import { uploadAndRecord, deleteOwnAssetByUrl, MediaPurpose } from "./media.service";
import { CloudinaryNotConfiguredError } from "./cloudinary.client";

export const mediaRouter = Router();

const uploadQuerySchema = z.object({
  purpose: z.enum(["review_photo", "pin_photo", "risk_report_photo"]),
});

// POST /media/upload?purpose=review_photo|pin_photo|risk_report_photo
// Generic upload endpoint for the three "attach photos to a thing I'm about
// to create" flows — the client uploads each photo first, gets back a URL,
// and includes that URL in the review/pin/risk-report create request.
// (Avatar upload is separate — see PUT /users/me/avatar — since it always
// replaces a single existing image rather than accumulating a list.)
mediaRouter.post("/media/upload", requireAuth, uploadSingleImage, async (req: AuthedRequest, res, next) => {
  try {
    const { purpose } = uploadQuerySchema.parse(req.query);
    if (!req.file) throw new HttpError(400, "No image file provided (expected multipart field 'image')");

    const asset = await uploadAndRecord(req.file.buffer, purpose as MediaPurpose, req.userId!);
    res.status(201).json({ id: asset.id, url: asset.url });
  } catch (err) {
    next(err instanceof CloudinaryNotConfiguredError ? new HttpError(503, err.message) : err);
  }
});

const deleteSchema = z.object({
  url: z.string().url(),
});

// POST /media/delete — lets a client discard a photo it just uploaded but
// decided not to use (e.g. removed it from the picker before submitting the
// review/pin/report). Best-effort: deleting a URL that isn't a tracked
// media_assets row (or isn't this user's) is a silent no-op, not an error —
// the client can't tell the difference from its side and doesn't need to.
mediaRouter.post("/media/delete", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { url } = deleteSchema.parse(req.body);
    await deleteOwnAssetByUrl(url, req.userId!);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
});
