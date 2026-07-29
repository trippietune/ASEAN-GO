import { Express } from "express";
import request from "supertest";
import { pool } from "../src/db/pool";
import { signToken } from "../src/modules/auth/auth.service";

export interface TestUser {
  id: string;
  token: string;
  email: string;
  role: string;
}

/// Registers a real user through the API (so password hashing etc. all runs
/// for real), then optionally promotes it directly in the DB — there's
/// deliberately no API path to self-promote, so tests reaching for
/// admin/moderator fixtures have to go around the API for that one step,
/// same as a real operator would via direct DB access or a seed script.
export async function createTestUser(
  app: Express,
  options: { role?: "user" | "admin" | "moderator"; email?: string } = {}
): Promise<TestUser> {
  const email = options.email ?? `test-${Math.random().toString(36).slice(2)}@example.com`;
  const res = await request(app).post("/auth/register").send({
    email,
    password: "password123",
    displayName: "Test User",
  });
  const userId = res.body.user.id as string;

  if (options.role && options.role !== "user") {
    await pool.query("UPDATE users SET role = $2 WHERE id = $1", [userId, options.role]);
  }

  return { id: userId, token: signToken(userId), email, role: options.role ?? "user" };
}
