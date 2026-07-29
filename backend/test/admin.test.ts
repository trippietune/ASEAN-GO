import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { createTestUser } from "./helpers";

const app = createApp();

describe("Admin guard — role tiers", () => {
  it("rejects a plain user with 403", async () => {
    const user = await createTestUser(app, { role: "user" });
    const res = await request(app).get("/admin/stats").set("Authorization", `Bearer ${user.token}`);
    expect(res.status).toBe(403);
  });

  it("allows a moderator to read admin resources", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const res = await request(app).get("/admin/stats").set("Authorization", `Bearer ${moderator.token}`);
    expect(res.status).toBe(200);
  });

  it("allows an admin to read admin resources", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const res = await request(app).get("/admin/stats").set("Authorization", `Bearer ${admin.token}`);
    expect(res.status).toBe(200);
  });

  it("rejects an unauthenticated request with 401 (not 403 — no role to even check)", async () => {
    const res = await request(app).get("/admin/stats");
    expect(res.status).toBe(401);
  });

  it("rejects a moderator attempting an admin-only destructive action (delete pin)", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const res = await request(app)
      .delete("/admin/pins/00000000-0000-0000-0000-000000000000")
      .set("Authorization", `Bearer ${moderator.token}`);
    // requireAdmin runs before the route body, so this must be 403, never a
    // 404 that would leak whether that pin ID exists to a moderator.
    expect(res.status).toBe(403);
  });

  it("reflects a role change immediately without requiring the user to re-login", async () => {
    const user = await createTestUser(app, { role: "user" });
    const admin = await createTestUser(app, { role: "admin" });

    const before = await request(app).get("/admin/stats").set("Authorization", `Bearer ${user.token}`);
    expect(before.status).toBe(403);

    await request(app)
      .put(`/admin/users/${user.id}/role`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ role: "moderator" });

    // Same JWT as before — the guard re-checks the DB on every request
    // rather than trusting a role baked into the token, so this must now
    // succeed without a new token.
    const after = await request(app).get("/admin/stats").set("Authorization", `Bearer ${user.token}`);
    expect(after.status).toBe(200);
  });
});

describe("Admin guard — role escalation prevention", () => {
  it("rejects a moderator trying to change anyone's role", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const target = await createTestUser(app, { role: "user" });

    const res = await request(app)
      .put(`/admin/users/${target.id}/role`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ role: "admin" });

    expect(res.status).toBe(403);
  });

  it("blocks an admin from demoting their own account", async () => {
    const admin = await createTestUser(app, { role: "admin" });

    const res = await request(app)
      .put(`/admin/users/${admin.id}/role`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ role: "user" });

    expect(res.status).toBe(400);
  });

  it("lets an admin promote another user to admin", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const target = await createTestUser(app, { role: "user" });

    const res = await request(app)
      .put(`/admin/users/${target.id}/role`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ role: "admin" });

    expect(res.status).toBe(200);
    expect(res.body.role).toBe("admin");
  });

  it("rejects an invalid role value", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const target = await createTestUser(app, { role: "user" });

    const res = await request(app)
      .put(`/admin/users/${target.id}/role`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ role: "superadmin" });

    expect(res.status).toBe(400);
  });
});
