import rateLimit from "express-rate-limit";

const isTest = process.env.NODE_ENV === "test";

/// Test env gets a very high ceiling instead of skipping the middleware
/// entirely — this keeps the real limiter logic (headers, store, ordering)
/// exercised by every test run, while a dedicated rate-limit test can still
/// verify enforcement by driving past a small explicit `limit`.
function multiplier(): number {
  return isTest ? 1000 : 1;
}

/// Strict limiter for credential-guessing surfaces (login, register, password
/// change) — these are the endpoints brute-force/credential-stuffing attacks
/// actually target, so they get a much tighter budget than everything else.
export const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 10 * multiplier(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many attempts. Please try again later." },
});

/// Payment-initiating endpoints (charge/refund) — generous enough for normal
/// retry-after-typo behavior, tight enough to blunt automated card-testing
/// (attackers cycling stolen card numbers through a purchase endpoint).
/// The Omise webhook is intentionally NOT behind this limiter: it's called
/// by Omise's servers, not a browser, and has its own trust model (event
/// re-fetch from Omise's API — see payments.routes.ts).
export const paymentLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20 * multiplier(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many payment requests. Please try again later." },
});

/// Baseline for everything else — generous enough that no normal user or the
/// mobile app's own polling (e.g. the 45s proximity check) ever comes close,
/// but still bounds worst-case load from a single bad actor or buggy client.
export const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 300 * multiplier(),
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: "Too many requests. Please try again later." },
});
