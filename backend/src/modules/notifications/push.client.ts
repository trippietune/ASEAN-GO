import { cert, initializeApp } from "firebase-admin/app";
import { getMessaging as getFirebaseMessaging, Messaging } from "firebase-admin/messaging";
import { env } from "../../config/env";

export class FcmNotConfiguredError extends Error {
  constructor() {
    super("FIREBASE_* env vars are not set — push notifications are unavailable");
  }
}

let configured = false;

function ensureConfigured(): void {
  if (configured) return;
  if (!env.fcmProjectId || !env.fcmClientEmail || !env.fcmPrivateKey) {
    throw new FcmNotConfiguredError();
  }
  initializeApp({
    credential: cert({
      projectId: env.fcmProjectId,
      clientEmail: env.fcmClientEmail,
      // Render's env var editor stores this as a single line with literal
      // \n escapes rather than real newlines — firebase-admin's PEM parser
      // requires the latter.
      privateKey: env.fcmPrivateKey.replace(/\\n/g, "\n"),
    }),
  });
  configured = true;
}

/// Sole low-level export — keeps this file a thin, swappable SDK boundary.
/// All send logic (settings gating, token fan-out, dead-token pruning)
/// lives one layer up in push.service.ts, mirroring how cloudinary.client.ts
/// separates "configure/expose SDK" from business logic in media.service.ts.
export function getMessaging(): Messaging {
  ensureConfigured();
  return getFirebaseMessaging();
}
