import type { SendResponse } from "firebase-admin/messaging";
import { pool } from "../../db/pool";
import { logger } from "../../config/logger";
import { getMessaging } from "./push.client";

interface PushNotification {
  title: string;
  body: string;
  data?: Record<string, string>;
}

interface SendOptions {
  /// Which notification_settings flag gates this send. Defaults to the
  /// general "pushNotifications" toggle.
  settingsKey?: "pushNotifications" | "safetyAlerts" | "questReminders";
}

/// Sends a push to every device registered for `userId`, respecting their
/// notification settings. Never throws — a failed or unconfigured send must
/// never break the request that triggered it, so callers can fire-and-forget
/// with no try/catch.
export async function sendPushToUser(
  userId: string,
  notification: PushNotification,
  options?: SendOptions
): Promise<void> {
  try {
    const settingsKey = options?.settingsKey ?? "pushNotifications";
    const settingsResult = await pool.query(
      "SELECT notification_settings FROM users WHERE id = $1",
      [userId]
    );
    const settings = settingsResult.rows[0]?.notification_settings;
    if (!settings || settings[settingsKey] === false) return;

    const tokensResult = await pool.query<{ token: string }>(
      "SELECT token FROM user_fcm_tokens WHERE user_id = $1",
      [userId]
    );
    if (tokensResult.rowCount === 0) return;

    const tokens = tokensResult.rows.map((row) => row.token);
    const response = await getMessaging().sendEachForMulticast({
      tokens,
      notification: { title: notification.title, body: notification.body },
      data: notification.data ?? {},
    });

    const deadTokens: string[] = [];
    response.responses.forEach((result: SendResponse, index: number) => {
      const code = result.error?.code;
      if (
        code === "messaging/registration-token-not-registered" ||
        code === "messaging/invalid-registration-token"
      ) {
        deadTokens.push(tokens[index]);
      }
    });
    if (deadTokens.length > 0) {
      await pool.query("DELETE FROM user_fcm_tokens WHERE token = ANY($1::text[])", [deadTokens]);
    }
  } catch (err) {
    // Includes FcmNotConfiguredError (dev/unset-env-var case) — logged, not
    // rethrown, since push delivery is best-effort by design.
    logger.error({ err, userId }, "Failed to send push notification");
  }
}
