import crypto from "node:crypto";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { OAuth2Client } from "google-auth-library";
import { pool } from "../../db/pool";
import { env } from "../../config/env";
import { HttpError } from "../../middleware/errorHandler";
import { sendPasswordResetEmail } from "./mailer.client";

export interface UserRecord {
  id: string;
  email: string;
  password_hash: string | null;
  display_name: string;
  auth_provider: string;
  avatar_url: string | null;
  xp: number;
  level: number;
  is_premium: boolean;
  coin_balance: number;
  role: string;
}

const PUBLIC_COLUMNS = `id, email, display_name, auth_provider, avatar_url, xp, level, is_premium, coin_balance, role`;

export function signToken(userId: string): string {
  return jwt.sign({ sub: userId }, env.jwtSecret, { expiresIn: env.jwtExpiresIn } as jwt.SignOptions);
}

export async function registerWithEmail(email: string, password: string, displayName: string) {
  const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email]);
  if (existing.rowCount) {
    throw new HttpError(409, "An account with this email already exists");
  }

  const passwordHash = await bcrypt.hash(password, 12);
  const result = await pool.query(
    `INSERT INTO users (email, password_hash, display_name, auth_provider)
     VALUES ($1, $2, $3, 'email')
     RETURNING ${PUBLIC_COLUMNS}`,
    [email, passwordHash, displayName]
  );
  return result.rows[0];
}

export async function loginWithEmail(email: string, password: string) {
  const result = await pool.query<UserRecord>(
    `SELECT ${PUBLIC_COLUMNS}, password_hash FROM users WHERE email = $1`,
    [email]
  );
  const user = result.rows[0];
  if (!user || !user.password_hash) {
    throw new HttpError(401, "Invalid email or password");
  }

  const valid = await bcrypt.compare(password, user.password_hash);
  if (!valid) {
    throw new HttpError(401, "Invalid email or password");
  }

  const { password_hash, ...publicUser } = user;
  return publicUser;
}

const googleClient = env.googleClientId ? new OAuth2Client(env.googleClientId) : null;

/// Verifies a Google Sign-In ID token against Google's public keys (offline
/// signature check, no network round trip to Google needed after the
/// library's cached certs are fetched) and returns the verified payload.
async function verifyGoogleIdToken(idToken: string) {
  if (!googleClient || !env.googleClientId) {
    throw new HttpError(501, "Google sign-in is not configured yet");
  }
  let ticket;
  try {
    ticket = await googleClient.verifyIdToken({ idToken, audience: env.googleClientId });
  } catch {
    throw new HttpError(401, "Invalid Google sign-in token");
  }
  const payload = ticket.getPayload();
  if (!payload?.sub || !payload.email) {
    throw new HttpError(401, "Invalid Google sign-in token");
  }
  return { providerId: payload.sub, email: payload.email, displayName: payload.name ?? payload.email, avatarUrl: payload.picture };
}

/// Verifies a Facebook access token by asking Facebook's Graph API to
/// confirm it's valid for our app (via the app's own access token as
/// `input_token`'s authority), then fetches the profile fields we need.
async function verifyFacebookAccessToken(accessToken: string) {
  if (!env.facebookAppId || !env.facebookAppSecret) {
    throw new HttpError(501, "Facebook sign-in is not configured yet");
  }

  const appAccessToken = `${env.facebookAppId}|${env.facebookAppSecret}`;
  const debugRes = await fetch(
    `https://graph.facebook.com/debug_token?input_token=${encodeURIComponent(accessToken)}&access_token=${encodeURIComponent(appAccessToken)}`
  );
  const debugData = (await debugRes.json()) as { data?: { is_valid?: boolean; app_id?: string } };
  if (!debugRes.ok || !debugData.data?.is_valid || debugData.data.app_id !== env.facebookAppId) {
    throw new HttpError(401, "Invalid Facebook sign-in token");
  }

  const profileRes = await fetch(
    `https://graph.facebook.com/me?fields=id,name,email,picture&access_token=${encodeURIComponent(accessToken)}`
  );
  const profile = (await profileRes.json()) as { id?: string; name?: string; email?: string; picture?: { data?: { url?: string } } };
  if (!profileRes.ok || !profile.id) {
    throw new HttpError(401, "Invalid Facebook sign-in token");
  }
  if (!profile.email) {
    // Facebook lets users decline sharing email; we require it since email
    // is our unique account key. Ask them to use a different sign-in method.
    throw new HttpError(400, "Your Facebook account has no email to sign in with. Please use email/password or Google instead.");
  }
  return { providerId: profile.id, email: profile.email, displayName: profile.name ?? profile.email, avatarUrl: profile.picture?.data?.url };
}

/// Shared find-or-create for any social provider: an existing account
/// matched by (provider, providerId) logs straight in; a first-time signup
/// with an email that already belongs to a *different* provider is refused
/// rather than silently merged, since we can't verify the person requesting
/// the merge actually owns that other account.
async function findOrCreateSocialUser(
  provider: "google" | "facebook",
  identity: { providerId: string; email: string; displayName: string; avatarUrl?: string }
) {
  const existing = await pool.query<UserRecord>(
    `SELECT ${PUBLIC_COLUMNS} FROM users WHERE auth_provider = $1 AND provider_id = $2`,
    [provider, identity.providerId]
  );
  if (existing.rowCount) {
    return existing.rows[0];
  }

  const emailTaken = await pool.query("SELECT auth_provider FROM users WHERE email = $1", [identity.email]);
  if (emailTaken.rowCount) {
    throw new HttpError(
      409,
      `An account with this email already exists using ${emailTaken.rows[0].auth_provider} sign-in. Please use that method instead.`
    );
  }

  const result = await pool.query<UserRecord>(
    `INSERT INTO users (email, display_name, auth_provider, provider_id, avatar_url)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING ${PUBLIC_COLUMNS}`,
    [identity.email, identity.displayName, provider, identity.providerId, identity.avatarUrl ?? null]
  );
  return result.rows[0];
}

export async function loginWithGoogle(idToken: string) {
  const identity = await verifyGoogleIdToken(idToken);
  return findOrCreateSocialUser("google", identity);
}

export async function loginWithFacebook(accessToken: string) {
  const identity = await verifyFacebookAccessToken(accessToken);
  return findOrCreateSocialUser("facebook", identity);
}

const RESET_CODE_TTL_MS = 15 * 60 * 1000; // 15 minutes
const MAX_RESET_ATTEMPTS = 5; // per issued code, across all resetPassword() calls

function hashResetCode(code: string): string {
  // A reset code is a bearer credential, same threat model as a session
  // token — hash it at rest so a DB read doesn't hand out working codes.
  return crypto.createHash("sha256").update(code).digest("hex");
}

/// Generates a 6-digit numeric code — short enough to type by hand out of an
/// email, unlike a long opaque token. Low entropy (1e6 possibilities) is
/// compensated by a short TTL and [MAX_RESET_ATTEMPTS] guess cap enforced in
/// resetPassword(), on top of the router's authLimiter.
function generateResetCode(): string {
  return crypto.randomInt(0, 1_000_000).toString().padStart(6, "0");
}

/// Always succeeds from the caller's point of view regardless of whether the
/// email exists, has a password (vs. OAuth-only), or delivery fails — none
/// of that should be observable by whoever is submitting the form, to avoid
/// leaking which emails have accounts.
export async function requestPasswordReset(email: string): Promise<void> {
  const result = await pool.query<{ id: string; password_hash: string | null }>(
    "SELECT id, password_hash FROM users WHERE email = $1",
    [email]
  );
  const user = result.rows[0];
  if (!user || !user.password_hash) return;

  const code = generateResetCode();
  const codeHash = hashResetCode(code);
  const expiresAt = new Date(Date.now() + RESET_CODE_TTL_MS);

  // Invalidate any earlier unused codes for this user first, so only the
  // most recently requested code is ever valid.
  await pool.query("DELETE FROM password_reset_tokens WHERE user_id = $1 AND used_at IS NULL", [user.id]);
  await pool.query(
    `INSERT INTO password_reset_tokens (user_id, token_hash, expires_at) VALUES ($1, $2, $3)`,
    [user.id, codeHash, expiresAt]
  );

  await sendPasswordResetEmail(email, code);
}

export async function resetPassword(email: string, code: string, newPassword: string): Promise<void> {
  const codeHash = hashResetCode(code);
  const result = await pool.query<{
    id: string;
    user_id: string;
    token_hash: string;
    expires_at: Date;
    used_at: Date | null;
    attempts: number;
  }>(
    `SELECT prt.id, prt.user_id, prt.token_hash, prt.expires_at, prt.used_at, prt.attempts
     FROM password_reset_tokens prt
     JOIN users u ON u.id = prt.user_id
     WHERE u.email = $1
     ORDER BY prt.created_at DESC
     LIMIT 1`,
    [email]
  );
  const record = result.rows[0];

  // Generic message in every failure branch — never reveal whether the
  // email exists, whether a code was ever issued, or which specific check
  // failed, so a brute-forcer learns nothing from the error text.
  const invalidError = new HttpError(400, "That code is invalid or has expired. Please request a new one.");

  if (!record || record.used_at || record.expires_at.getTime() < Date.now()) {
    throw invalidError;
  }
  if (record.attempts >= MAX_RESET_ATTEMPTS) {
    throw invalidError;
  }
  if (record.token_hash !== codeHash) {
    await pool.query("UPDATE password_reset_tokens SET attempts = attempts + 1 WHERE id = $1", [record.id]);
    throw invalidError;
  }

  const passwordHash = await bcrypt.hash(newPassword, 12);
  await pool.query("UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1", [record.user_id, passwordHash]);
  await pool.query("UPDATE password_reset_tokens SET used_at = now() WHERE id = $1", [record.id]);
}
