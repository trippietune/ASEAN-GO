import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import { pool } from "../../db/pool";
import { env } from "../../config/env";
import { HttpError } from "../../middleware/errorHandler";

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
