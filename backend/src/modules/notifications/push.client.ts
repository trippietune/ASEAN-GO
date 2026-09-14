import { getMessaging as getFirebaseMessaging, Messaging } from "firebase-admin/messaging";
import { getFirebaseApp, FirebaseNotConfiguredError } from "../../config/firebaseAdmin";

export { FirebaseNotConfiguredError as FcmNotConfiguredError };

/// Sole low-level export — keeps this file a thin, swappable SDK boundary.
/// All send logic (settings gating, token fan-out, dead-token pruning)
/// lives one layer up in push.service.ts, mirroring how cloudinary.client.ts
/// separates "configure/expose SDK" from business logic in media.service.ts.
export function getMessaging(): Messaging {
  return getFirebaseMessaging(getFirebaseApp());
}
