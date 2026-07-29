import { v2 as cloudinary, UploadApiResponse } from "cloudinary";
import { env } from "../../config/env";
import { logger } from "../../config/logger";

export class CloudinaryNotConfiguredError extends Error {
  constructor() {
    super("CLOUDINARY_* env vars are not set — media uploads are unavailable");
  }
}

let configured = false;

function ensureConfigured(): void {
  if (configured) return;
  if (!env.cloudinaryCloudName || !env.cloudinaryApiKey || !env.cloudinaryApiSecret) {
    throw new CloudinaryNotConfiguredError();
  }
  cloudinary.config({
    cloud_name: env.cloudinaryCloudName,
    api_key: env.cloudinaryApiKey,
    api_secret: env.cloudinaryApiSecret,
    secure: true,
  });
  configured = true;
}

export interface UploadResult {
  publicId: string;
  url: string;
  width: number;
  height: number;
  bytes: number;
}

/// Uploads a resize-capped, auto-optimized image. `eager` runs the
/// transformation at upload time (rather than on first delivery request) so
/// the very first client to load the URL doesn't pay a transcode delay.
/// `f_auto/q_auto` picks the best format (WebP/AVIF where supported) and
/// quality automatically — this is Cloudinary's standard "optimize" lever,
/// no separate image-processing library needed.
export function uploadImage(buffer: Buffer, folder: string): Promise<UploadResult> {
  ensureConfigured();

  return new Promise((resolve, reject) => {
    const stream = cloudinary.uploader.upload_stream(
      {
        folder: `aseango/${folder}`,
        resource_type: "image",
        eager: [{ width: 1600, height: 1600, crop: "limit", fetch_format: "auto", quality: "auto" }],
        eager_async: false,
      },
      (err, result?: UploadApiResponse) => {
        if (err || !result) {
          reject(err ?? new Error("Cloudinary upload returned no result"));
          return;
        }
        const optimized = result.eager?.[0];
        resolve({
          publicId: result.public_id,
          url: optimized?.secure_url ?? result.secure_url,
          width: optimized?.width ?? result.width,
          height: optimized?.height ?? result.height,
          bytes: result.bytes,
        });
      }
    );
    stream.end(buffer);
  });
}

/// Best-effort delete — callers should not fail the overall request just
/// because a stale Cloudinary asset couldn't be cleaned up (e.g. it was
/// already removed, or Cloudinary is temporarily unreachable).
export async function destroyImage(publicId: string): Promise<void> {
  try {
    ensureConfigured();
    await cloudinary.uploader.destroy(publicId);
  } catch (err) {
    logger.error({ err, publicId }, "Failed to delete Cloudinary asset");
  }
}
