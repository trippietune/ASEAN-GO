import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
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

  it("rejects a moderator creating a pin (admin-only), allows an admin", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const admin = await createTestUser(app, { role: "admin" });
    const body = { name: "Dashboard Pin", category: "attraction", country: "Thailand", lat: 13.7563, lng: 100.5018 };

    const moderatorRes = await request(app)
      .post("/admin/pins")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send(body);
    expect(moderatorRes.status).toBe(403);

    const adminRes = await request(app)
      .post("/admin/pins")
      .set("Authorization", `Bearer ${admin.token}`)
      .send(body);
    expect(adminRes.status).toBe(201);
    expect(adminRes.body.is_verified).toBe(true);
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

describe("POST/PUT /admin/quests — 5-type taxonomy and new fields", () => {
  it("creates quests of each of the 5 types", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    for (const questType of ["daily", "location", "category", "level", "story"]) {
      const res = await request(app)
        .post("/admin/quests")
        .set("Authorization", `Bearer ${moderator.token}`)
        .send({ title: `${questType} quest`, questType, xpReward: 10, coinReward: 0 });
      expect(res.status).toBe(201);
      expect(res.body.quest_type).toBe(questType);
    }
  });

  it("persists category, chapterId, and chapterOrder on create", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const chapterRes = await pool.query(
      `INSERT INTO quest_chapters (title, order_index) VALUES ('Chapter', $1) RETURNING id`,
      [Math.floor(Math.random() * 1_000_000)]
    );
    const chapterId = chapterRes.rows[0].id;

    const res = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ title: "Story quest", questType: "story", chapterId, chapterOrder: 1, xpReward: 10, coinReward: 0 });

    expect(res.status).toBe(201);
    expect(res.body.chapter_id).toBe(chapterId);
    expect(res.body.chapter_order).toBe(1);
  });

  it("setting pinId on update auto-creates a checkin unlock requirement", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const pinRes = await pool.query(
      `INSERT INTO verified_pins (name, category, country, location, is_verified)
       VALUES ('Test Pin', 'attraction', 'Thailand', ST_MakePoint(100.5, 13.7)::geography, TRUE)
       RETURNING id`
    );
    const pinId = pinRes.rows[0].id;
    const createRes = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ title: "Pin quest", questType: "daily", xpReward: 10, coinReward: 0 });
    const questId = createRes.body.id;

    await request(app)
      .put(`/admin/quests/${questId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ pinId });

    const requirements = await pool.query(
      `SELECT requirement_type, required_pin_id FROM quest_unlock_requirements WHERE quest_id = $1`,
      [questId]
    );
    expect(requirements.rowCount).toBe(1);
    expect(requirements.rows[0].requirement_type).toBe("checkin");
    expect(requirements.rows[0].required_pin_id).toBe(pinId);
  });
});

describe("Admin quest unlock-requirements CRUD", () => {
  it("moderator can list and create unlock requirements", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const createRes = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ title: "Gated quest", questType: "level", xpReward: 10, coinReward: 0 });
    const questId = createRes.body.id;

    const createReq = await request(app)
      .post(`/admin/quests/${questId}/unlock-requirements`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ requirementType: "level", minLevel: 5 });
    expect(createReq.status).toBe(201);
    expect(createReq.body.requirement_type).toBe("level");
    expect(createReq.body.min_level).toBe(5);

    const listRes = await request(app)
      .get(`/admin/quests/${questId}/unlock-requirements`)
      .set("Authorization", `Bearer ${moderator.token}`);
    expect(listRes.status).toBe(200);
    expect(listRes.body.length).toBe(1);
  });

  it("moderator cannot delete an unlock requirement (admin-only)", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const createRes = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ title: "Gated quest", questType: "level", xpReward: 10, coinReward: 0 });
    const questId = createRes.body.id;
    const reqRes = await request(app)
      .post(`/admin/quests/${questId}/unlock-requirements`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ requirementType: "level", minLevel: 5 });

    const deleteRes = await request(app)
      .delete(`/admin/quests/${questId}/unlock-requirements/${reqRes.body.id}`)
      .set("Authorization", `Bearer ${moderator.token}`);

    expect(deleteRes.status).toBe(403);
  });

  it("admin can delete an unlock requirement", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const createRes = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ title: "Gated quest", questType: "level", xpReward: 10, coinReward: 0 });
    const questId = createRes.body.id;
    const reqRes = await request(app)
      .post(`/admin/quests/${questId}/unlock-requirements`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ requirementType: "level", minLevel: 5 });

    const deleteRes = await request(app)
      .delete(`/admin/quests/${questId}/unlock-requirements/${reqRes.body.id}`)
      .set("Authorization", `Bearer ${admin.token}`);

    expect(deleteRes.status).toBe(204);
    const listRes = await request(app)
      .get(`/admin/quests/${questId}/unlock-requirements`)
      .set("Authorization", `Bearer ${admin.token}`);
    expect(listRes.body.length).toBe(0);
  });
});
