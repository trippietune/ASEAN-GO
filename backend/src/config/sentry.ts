import * as Sentry from "@sentry/node";
import { env } from "./env";

/// No-op until SENTRY_DSN is set — every call site here is safe to leave in
/// place regardless of whether a Sentry project has been created yet.
export function initSentry(): void {
  if (!env.sentryDsn) return;
  Sentry.init({
    dsn: env.sentryDsn,
    environment: env.nodeEnv,
    // Full error capture, no sampling — this API's traffic volume doesn't
    // warrant trimming, and losing an error to sampling defeats the point of
    // having alerting at all.
    tracesSampleRate: 0,
  });
}

export { Sentry };
