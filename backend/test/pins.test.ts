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
  it("lets a moderator mark a pin as a checkpoint", async () => {
    const pinId = await insertPin({ name: "To Be Checkpoint" });
    const moderator = await createTestUser(app, { role: "moderator" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ isCheckpoint: true });

    expect(res.status).toBe(200);
    expect(res.body.is_checkpoint).toBe(true);
  });

  it("lets a moderator mark a pin as recommended", async () => {
    const pinId = await insertPin({ name: "To Be Recommended" });
    const moderator = await createTestUser(app, { role: "moderator" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ isRecommended: true });

    expect(res.status).toBe(200);
    expect(res.body.is_recommended).toBe(true);
  });

  it("leaves is_checkpoint/is_recommended unchanged when omitted from the update body", async () => {
    const pinId = await insertPin({ name: "Untouched Flags", isCheckpoint: true });
    const moderator = await createTestUser(app, { role: "moderator" });

    const res = await request(app)
      .put(`/admin/pins/${pinId}`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ safetyScore: 90 });

    expect(res.status).toBe(200);
    expect(res.body.is_checkpoint).toBe(true);
  });
});
