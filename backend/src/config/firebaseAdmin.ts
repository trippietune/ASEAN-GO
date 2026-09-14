import { App, cert, initializeApp } from "firebase-admin/app";
import { env } from "./env";

export class FirebaseNotConfiguredError extends Error {
  constructor() {
    super("FIREBASE_* env vars are not set — Firebase Admin features are unavailable");
  }
}

let app: App | undefined;

/// Single shared Firebase Admin app instance — initializeApp() may only be
/// called once per process, so every consumer (FCM push, Firebase Auth
/// verification) must go through this lazy singleton rather than each
/// calling initializeApp() independently.
export function getFirebaseApp(): App {
  if (app) return app;
  if (!env.fcmProjectId || !env.fcmClientEmail || !env.fcmPrivateKey) {
    throw new FirebaseNotConfiguredError();
  }
  app = initializeApp({
    credential: cert({
      projectId: env.fcmProjectId,
      clientEmail: env.fcmClientEmail,
      // Render's env var editor stores this as a single line with literal
      // \n escapes rather than real newlines — firebase-admin's PEM parser
      // requires the latter.
      privateKey: env.fcmPrivateKey.replace(/\\n/g, "\n"),
    }),
  });
  return app;
}
