import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

async function insertPin(overrides: {
  name?: string;
  category?: string;
  lat?: number;
  lng?: number;
  isCheckpoint?: boolean;
  isRecommended?: boolean;
}): Promise<string> {
  const result = await pool.query(
    `INSERT INTO verified_pins (name, category, country, location, is_verified, is_checkpoint, is_recommended)
     VALUES ($1, $2, 'Thailand', ST_MakePoint($3, $4)::geography, TRUE, $5, $6)
     RETURNING id`,
    [
      overrides.name ?? "Test Pin",
      overrides.category ?? "attraction",
      overrides.lng ?? 100.5018,
      overrides.lat ?? 13.7563,
      overrides.isCheckpoint ?? false,
      overrides.isRecommended ?? false,
    ]
  );
  return result.rows[0].id as string;
}

describe("GET /pins/nearby — checkpoint/recommended/quest flags", () => {
  it("includes is_checkpoint and is_recommended on each pin", async () => {
    await insertPin({ name: "Checkpoint Pin", isCheckpoint: true });
    await insertPin({ name: "Recommended Pin", isRecommended: true });
    await insertPin({ name: "Plain Pin" });

    const res = await request(app).get("/pins/nearby").query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 });
    expect(res.status).toBe(200);

    const byName = Object.fromEntries(res.body.map((p: { name: string }) => [p.name, p]));
    expect(byName["Checkpoint Pin"].is_checkpoint).toBe(true);
    expect(byName["Checkpoint Pin"].is_recommended).toBe(false);
    expect(byName["Recommended Pin"].is_recommended).toBe(true);
    expect(byName["Plain Pin"].is_checkpoint).toBe(false);
    expect(byName["Plain Pin"].is_recommended).toBe(false);
  });

  it("marks a pin as has_active_quest only while a linked quest is currently active", async () => {
    const pinId = await insertPin({ name: "Quest Pin" });

    const noQuestYet = await request(app).get("/pins/nearby").query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 });
    expect(noQuestYet.body.find((p: { name: string }) => p.name === "Quest Pin").has_active_quest).toBe(false);

    await pool.query(
      `INSERT INTO quests (title, quest_type, pin_id, active_from, active_until)
       VALUES ('Visit Quest Pin', 'daily', $1, now() - interval '1 hour', now() + interval '1 day')`,
      [pinId]
    );

    const withActiveQuest = await request(app).get("/pins/nearby").query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 });
    expect(withActiveQuest.body.find((p: { name: string }) => p.name === "Quest Pin").has_active_quest).toBe(true);

    await pool.query(
      `INSERT INTO quests (title, quest_type, pin_id, active_from, active_until)
       VALUES ('Expired Quest', 'daily', $1, now() - interval '2 days', now() - interval '1 day')`,
      [pinId]
    );
    await pool.query("DELETE FROM quests WHERE title = 'Visit Quest Pin'");

    const onlyExpiredQuest = await request(app).get("/pins/nearby").query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 });
    expect(onlyExpiredQuest.body.find((p: { name: string }) => p.name === "Quest Pin").has_active_quest).toBe(false);
  });
});

describe("GET /pins/:id — checkpoint/recommended/quest flags", () => {
  it("includes the same flags on the single-pin detail response", async () => {
    const pinId = await insertPin({ name: "Detail Pin", isCheckpoint: true, isRecommended: true });

    const res = await request(app).get(`/pins/${pinId}`);
    expect(res.status).toBe(200);
    expect(res.body.is_checkpoint).toBe(true);
    expect(res.body.is_recommended).toBe(true);
    expect(res.body.has_active_quest).toBe(false);
  });
});

describe("PUT /admin/pins/:id — checkpoint/recommended toggles", () => {
  it("lets an admin mark a pin as a checkpoint", async () => {
    const pinId = await insertPin({ name: "To Be Checkpoint" });
    const admin = await createTestUser(app, { role: "admin" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ isCheckpoint: true });

    expect(res.status).toBe(200);
    expect(res.body.is_checkpoint).toBe(true);
  });

  it("lets an admin mark a pin as recommended", async () => {
    const pinId = await insertPin({ name: "To Be Recommended" });
    const admin = await createTestUser(app, { role: "admin" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ isRecommended: true });

    expect(res.status).toBe(200);
    expect(res.body.is_recommended).toBe(true);
  });

  it("leaves is_checkpoint/is_recommended unchanged when omitted from the update body", async () => {
    const pinId = await insertPin({ name: "Untouched Flags", isCheckpoint: true });
    const admin = await createTestUser(app, { role: "admin" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ safetyScore: 90 });

    expect(res.status).toBe(200);
    expect(res.body.is_checkpoint).toBe(true);
  });

  it("rejects a moderator's attempt to edit a pin (admin-only)", async () => {
    const pinId = await insertPin({ name: "Moderator Blocked" });
    const moderator = await createTestUser(app, { role: "moderator" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ isCheckpoint: true });

    expect(res.status).toBe(403);
  });
});

describe("POST/PUT/DELETE /pins — admin-only", () => {
  it("returns 401 creating a pin with no auth", async () => {
    const res = await request(app).post("/pins").send({
      name: "Unauthed Pin",
      category: "attraction",
      country: "Thailand",
      lat: 13.7563,
      lng: 100.5018,
    });
    expect(res.status).toBe(401);
  });

  it("returns 403 creating a pin as a plain user", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/pins")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ name: "User Pin", category: "attraction", country: "Thailand", lat: 13.7563, lng: 100.5018 });
    expect(res.status).toBe(403);
  });

  it("returns 403 creating a pin as a moderator", async () => {
    const moderator = await createTestUser(app, { role: "moderator" });
    const res = await request(app)
      .post("/pins")
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ name: "Moderator Pin", category: "attraction", country: "Thailand", lat: 13.7563, lng: 100.5018 });
    expect(res.status).toBe(403);
  });

  it("lets an admin create a pin, immediately verified", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const res = await request(app)
      .post("/pins")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ name: "Admin Pin", category: "attraction", country: "Thailand", lat: 13.7563, lng: 100.5018 });
    expect(res.status).toBe(201);
    expect(res.body.is_verified).toBe(true);
  });

  it("returns 403 editing a pin as a plain user, even one they submitted", async () => {
    const pinId = await insertPin({ name: "Editable Pin" });
    const user = await createTestUser(app);
    const res = await request(app)
      .put(`/pins/${pinId}`)
      .set("Authorization", `Bearer ${user.token}`)
      .send({ name: "Renamed" });
    expect(res.status).toBe(403);
  });

  it("returns 403 editing a pin as a moderator", async () => {
    const pinId = await insertPin({ name: "Editable Pin 2" });
    const moderator = await createTestUser(app, { role: "moderator" });
    const res = await request(app)
      .put(`/pins/${pinId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ name: "Renamed" });
    expect(res.status).toBe(403);
  });

  it("lets an admin edit any pin, not just ones they created", async () => {
    const pinId = await insertPin({ name: "Editable Pin 3" });
    const admin = await createTestUser(app, { role: "admin" });
    const res = await request(app)
      .put(`/pins/${pinId}`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ name: "Renamed By Admin" });
    expect(res.status).toBe(200);
    expect(res.body.name).toBe("Renamed By Admin");
  });

  it("returns 403 deleting a pin as a plain user or moderator, 204 for admin", async () => {
    const pinForUser = await insertPin({ name: "Delete Me User" });
    const pinForModerator = await insertPin({ name: "Delete Me Moderator" });
    const pinForAdmin = await insertPin({ name: "Delete Me Admin" });
    const user = await createTestUser(app);
    const moderator = await createTestUser(app, { role: "moderator" });
    const admin = await createTestUser(app, { role: "admin" });

    const userRes = await request(app).delete(`/pins/${pinForUser}`).set("Authorization", `Bearer ${user.token}`);
    const moderatorRes = await request(app)
      .delete(`/pins/${pinForModerator}`)
      .set("Authorization", `Bearer ${moderator.token}`);
    const adminRes = await request(app).delete(`/pins/${pinForAdmin}`).set("Authorization", `Bearer ${admin.token}`);

    expect(userRes.status).toBe(403);
    expect(moderatorRes.status).toBe(403);
    expect(adminRes.status).toBe(204);
  });
});

describe("GET /pins/nearby — anonymous access still works", () => {
  it("returns 200 with no Authorization header (optionalAuth must not require auth)", async () => {
    await insertPin({ name: "Anon Pin" });
    const res = await request(app).get("/pins/nearby").query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 });
    expect(res.status).toBe(200);
    expect(res.body.find((p: { name: string }) => p.name === "Anon Pin").is_favorited).toBe(false);
  });
});

describe("Favorite pins", () => {
  it("favorites a pin, reflects it on /nearby and /:id, then unfavorites it", async () => {
    const pinId = await insertPin({ name: "Favoritable Pin" });
    const user = await createTestUser(app);

    const favorite = await request(app)
      .post(`/pins/${pinId}/favorite`)
      .set("Authorization", `Bearer ${user.token}`);
    expect(favorite.status).toBe(200);
    expect(favorite.body.isFavorited).toBe(true);

    const detail = await request(app)
      .get(`/pins/${pinId}`)
      .set("Authorization", `Bearer ${user.token}`);
    expect(detail.body.is_favorited).toBe(true);

    const nearby = await request(app)
      .get("/pins/nearby")
      .query({ lat: 13.7563, lng: 100.5018, radiusMeters: 5000 })
      .set("Authorization", `Bearer ${user.token}`);
    expect(nearby.body.find((p: { name: string }) => p.name === "Favoritable Pin").is_favorited).toBe(true);

    const unfavorite = await request(app)
      .delete(`/pins/${pinId}/favorite`)
      .set("Authorization", `Bearer ${user.token}`);
    expect(unfavorite.status).toBe(200);
    expect(unfavorite.body.isFavorited).toBe(false);

    const detailAfter = await request(app)
      .get(`/pins/${pinId}`)
      .set("Authorization", `Bearer ${user.token}`);
    expect(detailAfter.body.is_favorited).toBe(false);
  });

  it("is idempotent — favoriting twice or unfavoriting twice doesn't error", async () => {
    const pinId = await insertPin({ name: "Idempotent Pin" });
    const user = await createTestUser(app);

    const first = await request(app).post(`/pins/${pinId}/favorite`).set("Authorization", `Bearer ${user.token}`);
    const second = await request(app).post(`/pins/${pinId}/favorite`).set("Authorization", `Bearer ${user.token}`);
    expect(first.status).toBe(200);
    expect(second.status).toBe(200);

    const firstDelete = await request(app).delete(`/pins/${pinId}/favorite`).set("Authorization", `Bearer ${user.token}`);
    const secondDelete = await request(app).delete(`/pins/${pinId}/favorite`).set("Authorization", `Bearer ${user.token}`);
    expect(firstDelete.status).toBe(200);
    expect(secondDelete.status).toBe(200);
  });

  it("returns 404 favoriting a nonexistent pin", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/pins/00000000-0000-0000-0000-000000000000/favorite")
      .set("Authorization", `Bearer ${user.token}`);
    expect(res.status).toBe(404);
  });

  it("rejects favoriting/unfavoriting without auth", async () => {
    const pinId = await insertPin({ name: "Auth Required Pin" });
    const favorite = await request(app).post(`/pins/${pinId}/favorite`);
    const unfavorite = await request(app).delete(`/pins/${pinId}/favorite`);
    expect(favorite.status).toBe(401);
    expect(unfavorite.status).toBe(401);
  });

  it("is_favorited is scoped per-user — one user's favorite isn't visible to another", async () => {
    const pinId = await insertPin({ name: "Scoped Pin" });
    const owner = await createTestUser(app);
    const other = await createTestUser(app);

    await request(app).post(`/pins/${pinId}/favorite`).set("Authorization", `Bearer ${owner.token}`);

    const ownerView = await request(app).get(`/pins/${pinId}`).set("Authorization", `Bearer ${owner.token}`);
    const otherView = await request(app).get(`/pins/${pinId}`).set("Authorization", `Bearer ${other.token}`);
    const anonView = await request(app).get(`/pins/${pinId}`);

    expect(ownerView.body.is_favorited).toBe(true);
    expect(otherView.body.is_favorited).toBe(false);
    expect(anonView.body.is_favorited).toBe(false);
  });

  it("GET /pins/favorites returns only the calling user's favorited pins, most recent first", async () => {
    const pinA = await insertPin({ name: "Fav List Pin A" });
    const pinB = await insertPin({ name: "Fav List Pin B" });
    const user = await createTestUser(app);
    const other = await createTestUser(app);

    await request(app).post(`/pins/${pinA}/favorite`).set("Authorization", `Bearer ${user.token}`);
    await request(app).post(`/pins/${pinB}/favorite`).set("Authorization", `Bearer ${user.token}`);
    await request(app).post(`/pins/${pinA}/favorite`).set("Authorization", `Bearer ${other.token}`);

    const res = await request(app).get("/pins/favorites").set("Authorization", `Bearer ${user.token}`);
    expect(res.status).toBe(200);
    const names = res.body.map((p: { name: string }) => p.name);
    expect(names).toEqual(["Fav List Pin B", "Fav List Pin A"]);
  });

  it("rejects GET /pins/favorites without auth", async () => {
    const res = await request(app).get("/pins/favorites");
    expect(res.status).toBe(401);
  });
});

describe("POST /pins/:id/checkin — level-up detection", () => {
  it("reports leveledUp when the check-in's XP crosses a level boundary", async () => {
    const pinId = await insertPin({ name: "Checkin Level Pin" });
    const user = await createTestUser(app);
    await pool.query("UPDATE users SET xp = 90, level = 1 WHERE id = $1", [user.id]);

    const res = await request(app)
      .post(`/pins/${pinId}/checkin`)
      .set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(201);
    expect(res.body.leveledUp).toBe(true);
    expect(res.body.previousLevel).toBe(1);
    expect(res.body.level).toBe(2);
  });

  it("reports leveledUp: false when the check-in doesn't cross a level boundary", async () => {
    const pinId = await insertPin({ name: "Checkin No Level Pin" });
    const user = await createTestUser(app);
    await pool.query("UPDATE users SET xp = 10, level = 1 WHERE id = $1", [user.id]);

    const res = await request(app)
      .post(`/pins/${pinId}/checkin`)
      .set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(201);
    expect(res.body.leveledUp).toBe(false);
    expect(res.body.previousLevel).toBe(1);
  });
});
