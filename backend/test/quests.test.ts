import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

async function insertVerifiedPin(overrides: { name?: string; isVerified?: boolean; isScamAlert?: boolean } = {}): Promise<string> {
  const result = await pool.query(
    `INSERT INTO verified_pins (name, category, country, location, is_verified, is_scam_alert)
     VALUES ($1, 'attraction', 'Thailand', ST_MakePoint(100.5018, 13.7563)::geography, $2, $3)
     RETURNING id`,
    [overrides.name ?? "Test Pin", overrides.isVerified ?? true, overrides.isScamAlert ?? false]
  );
  return result.rows[0].id as string;
}

async function checkIn(userId: string, pinId: string) {
  await pool.query(`INSERT INTO pin_checkins (user_id, pin_id, xp_awarded) VALUES ($1, $2, 15)`, [userId, pinId]);
}

describe("GET /quests/daily — auto-generation", () => {
  it("generates today's daily quests from verified pins when none exist yet", async () => {
    await insertVerifiedPin({ name: "Grand Palace" });
    await insertVerifiedPin({ name: "Wat Arun" });
    const user = await createTestUser(app);

    const res = await request(app).get("/quests/daily").set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(200);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body.every((q: { quest_type: string }) => q.quest_type === "daily")).toBe(true);
  });

  it("does not generate duplicate quests on a second call the same day", async () => {
    await insertVerifiedPin({ name: "Grand Palace" });
    const user = await createTestUser(app);

    const first = await request(app).get("/quests/daily").set("Authorization", `Bearer ${user.token}`);
    const second = await request(app).get("/quests/daily").set("Authorization", `Bearer ${user.token}`);

    expect(first.body.length).toBe(second.body.length);
    expect(first.body.map((q: { id: string }) => q.id).sort()).toEqual(second.body.map((q: { id: string }) => q.id).sort());
  });

  it("only generates quests from verified, non-scam-alert pins", async () => {
    await insertVerifiedPin({ name: "Unverified Pin", isVerified: false });
    await insertVerifiedPin({ name: "Scam Pin", isScamAlert: true });
    const user = await createTestUser(app);

    const res = await request(app).get("/quests/daily").set("Authorization", `Bearer ${user.token}`);

    expect(res.body.length).toBe(0);
  });

  it("shows the same daily quests to every user (global, not per-user)", async () => {
    await insertVerifiedPin({ name: "Grand Palace" });
    const userA = await createTestUser(app);
    const userB = await createTestUser(app);

    const resA = await request(app).get("/quests/daily").set("Authorization", `Bearer ${userA.token}`);
    const resB = await request(app).get("/quests/daily").set("Authorization", `Bearer ${userB.token}`);

    expect(resA.body.map((q: { id: string }) => q.id).sort()).toEqual(resB.body.map((q: { id: string }) => q.id).sort());
  });
});

describe("POST /quests/complete — pin check-in requirement", () => {
  it("rejects completing a pin-linked quest without a check-in at that pin", async () => {
    const pinId = await insertVerifiedPin();
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, pin_id, active_from)
       VALUES ('Visit Test Pin', 'daily', 25, 10, $1, date_trunc('day', now()))
       RETURNING id`,
      [pinId]
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId, pinId });

    expect(res.status).toBe(400);
  });

  it("allows completing a pin-linked quest after checking in at that pin today", async () => {
    const pinId = await insertVerifiedPin();
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, pin_id, active_from)
       VALUES ('Visit Test Pin', 'daily', 25, 10, $1, date_trunc('day', now()))
       RETURNING id`,
      [pinId]
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);
    await checkIn(user.id, pinId);

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId, pinId });

    expect(res.status).toBe(200);
    expect(res.body.alreadyCompleted).toBe(false);
    expect(res.body.xpAwarded).toBe(25);
    expect(res.body.coinAwarded).toBe(10);
  });

  it("does not count a check-in from before the quest's active window", async () => {
    const pinId = await insertVerifiedPin();
    const user = await createTestUser(app);
    // Check in "yesterday" relative to a quest that only became active today.
    await pool.query(
      `INSERT INTO pin_checkins (user_id, pin_id, xp_awarded, created_at)
       VALUES ($1, $2, 15, now() - interval '2 days')`,
      [user.id, pinId]
    );
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, pin_id, active_from)
       VALUES ('Visit Test Pin', 'daily', 25, 10, $1, date_trunc('day', now()))
       RETURNING id`,
      [pinId]
    );
    const questId = questResult.rows[0].id;

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId, pinId });

    expect(res.status).toBe(400);
  });

  it("does not require a check-in for a quest with no linked pin", async () => {
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, active_from)
       VALUES ('Generic Quest', 'daily', 20, 5, date_trunc('day', now()))
       RETURNING id`
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.status).toBe(200);
  });

  it("is idempotent — completing an already-completed quest returns alreadyCompleted without re-awarding", async () => {
    const pinId = await insertVerifiedPin();
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, pin_id, active_from)
       VALUES ('Visit Test Pin', 'daily', 25, 10, $1, date_trunc('day', now()))
       RETURNING id`,
      [pinId]
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);
    await checkIn(user.id, pinId);

    const first = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId, pinId });
    const second = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId, pinId });

    expect(first.body.xp).toBe(second.body.xp);
    expect(second.body.alreadyCompleted).toBe(true);
    expect(second.body.xpAwarded).toBe(0);
  });
});

describe("POST /quests/complete — coin ledger", () => {
  it("writes a coin_transactions entry for the quest reward", async () => {
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, active_from)
       VALUES ('Generic Quest', 'daily', 20, 15, date_trunc('day', now()))
       RETURNING id`
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);

    await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });

    const ledger = await pool.query(
      `SELECT amount, type, reference_id FROM coin_transactions WHERE user_id = $1 AND type = 'quest_reward'`,
      [user.id]
    );
    expect(ledger.rowCount).toBe(1);
    expect(ledger.rows[0].amount).toBe(15);
    expect(ledger.rows[0].reference_id).toBe(questId);
  });

  it("does not write a ledger entry when the quest has no coin reward", async () => {
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, active_from)
       VALUES ('No Coin Quest', 'daily', 20, 0, date_trunc('day', now()))
       RETURNING id`
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);

    await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });

    const ledger = await pool.query(`SELECT id FROM coin_transactions WHERE user_id = $1`, [user.id]);
    expect(ledger.rowCount).toBe(0);
  });
});
