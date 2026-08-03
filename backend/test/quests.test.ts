import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

async function insertVerifiedPin(
  overrides: { name?: string; isVerified?: boolean; isScamAlert?: boolean; category?: string; country?: string; city?: string } = {}
): Promise<string> {
  const result = await pool.query(
    `INSERT INTO verified_pins (name, category, country, city, location, is_verified, is_scam_alert)
     VALUES ($1, $2, $3, $4, ST_MakePoint(100.5018, 13.7563)::geography, $5, $6)
     RETURNING id`,
    [
      overrides.name ?? "Test Pin",
      overrides.category ?? "attraction",
      overrides.country ?? "Thailand",
      overrides.city ?? null,
      overrides.isVerified ?? true,
      overrides.isScamAlert ?? false,
    ]
  );
  return result.rows[0].id as string;
}

async function insertUnlockRequirement(
  questId: string,
  overrides: {
    requirementType: string;
    minLevel?: number;
    requiredQuestId?: string;
    requiredPinId?: string;
    category?: string;
    country?: string;
    city?: string;
    countThreshold?: number;
  }
) {
  await pool.query(
    `INSERT INTO quest_unlock_requirements
       (quest_id, requirement_type, min_level, required_quest_id, required_pin_id, category, country, city, count_threshold)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
    [
      questId,
      overrides.requirementType,
      overrides.minLevel ?? null,
      overrides.requiredQuestId ?? null,
      overrides.requiredPinId ?? null,
      overrides.category ?? null,
      overrides.country ?? null,
      overrides.city ?? null,
      overrides.countThreshold ?? null,
    ]
  );
}

async function checkIn(userId: string, pinId: string) {
  await pool.query(`INSERT INTO pin_checkins (user_id, pin_id, xp_awarded) VALUES ($1, $2, 15)`, [userId, pinId]);
}

async function insertQuest(overrides: { title?: string; xpReward?: number; coinReward?: number } = {}): Promise<string> {
  const result = await pool.query(
    `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, active_from)
     VALUES ($1, 'daily', $2, $3, date_trunc('day', now()))
     RETURNING id`,
    [overrides.title ?? `Quest ${Math.random().toString(36).slice(2, 8)}`, overrides.xpReward ?? 0, overrides.coinReward ?? 0]
  );
  return result.rows[0].id as string;
}

async function setUserXpState(userId: string, xp: number, questsCompletedSinceLevelup = 0) {
  await pool.query(
    `UPDATE users SET xp = $2, level = FLOOR($2 / 100) + 1, quests_completed_since_levelup = $3 WHERE id = $1`,
    [userId, xp, questsCompletedSinceLevelup]
  );
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

describe("GET /quests — unified route", () => {
  it("returns quests of every type, not just daily", async () => {
    await pool.query(
      `INSERT INTO quests (title, quest_type, category, xp_reward, coin_reward, active_from)
       VALUES ('Location Quest', 'location', NULL, 10, 0, date_trunc('day', now())),
              ('Category Quest', 'category', 'food', 10, 0, date_trunc('day', now())),
              ('Level Quest', 'level', NULL, 10, 0, date_trunc('day', now())),
              ('Story Quest', 'story', NULL, 10, 0, date_trunc('day', now()))`
    );
    const user = await createTestUser(app);

    const res = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(200);
    const types = res.body.map((q: { quest_type: string }) => q.quest_type).sort();
    expect(types).toEqual(["category", "level", "location", "story"]);
  });

  it("filters by ?type=", async () => {
    await insertQuest({ title: "Daily Quest" });
    await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, active_from)
       VALUES ('Level Quest', 'level', 10, 0, date_trunc('day', now()))`
    );
    const user = await createTestUser(app);

    const res = await request(app).get("/quests?type=level").set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(200);
    expect(res.body.every((q: { quest_type: string }) => q.quest_type === "level")).toBe(true);
  });

  it("surfaces category, chapterId, chapterOrder, locked, and unlockRequirements fields", async () => {
    const orderIndex = Math.floor(Math.random() * 1_000_000);
    const chapter = await pool.query(
      `INSERT INTO quest_chapters (title, order_index) VALUES ('Chapter 1', $1) RETURNING id`,
      [orderIndex]
    );
    await pool.query(
      `INSERT INTO quests (title, quest_type, category, chapter_id, chapter_order, xp_reward, coin_reward, active_from)
       VALUES ('Story Quest', 'story', NULL, $1, 1, 10, 0, date_trunc('day', now()))`,
      [chapter.rows[0].id]
    );
    const user = await createTestUser(app);

    const res = await request(app).get("/quests?type=story").set("Authorization", `Bearer ${user.token}`);

    expect(res.status).toBe(200);
    expect(res.body[0]).toMatchObject({
      chapter_order: 1,
      locked: false,
      unlockRequirements: [],
    });
    expect(res.body[0].chapter_id).toBe(chapter.rows[0].id);
  });

  it("GET /quests/daily and GET /quests?type=daily return the same quests", async () => {
    await insertVerifiedPin({ name: "Grand Palace" });
    const user = await createTestUser(app);

    const alias = await request(app).get("/quests/daily").set("Authorization", `Bearer ${user.token}`);
    const unified = await request(app).get("/quests?type=daily").set("Authorization", `Bearer ${user.token}`);

    expect(alias.status).toBe(200);
    expect(unified.status).toBe(200);
    expect(alias.body.map((q: { id: string }) => q.id).sort()).toEqual(
      unified.body.map((q: { id: string }) => q.id).sort()
    );
  });

  it("a pin-linked quest with no check-in yet is NOT locked — its own checkin objective isn't a prerequisite", async () => {
    const pinId = await insertVerifiedPin();
    const questResult = await pool.query(
      `INSERT INTO quests (title, quest_type, xp_reward, coin_reward, pin_id, active_from)
       VALUES ('Visit Test Pin', 'daily', 25, 10, $1, date_trunc('day', now()))
       RETURNING id`,
      [pinId]
    );
    const questId = questResult.rows[0].id;
    const user = await createTestUser(app);

    const res = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    const found = res.body.find((q: { id: string }) => q.id === questId);

    expect(found.locked).toBe(false);
    expect(found.unlockRequirements).toEqual([
      { type: "checkin", description: "Check in at the required pin", satisfied: false, isOwnObjective: true },
    ]);
  });
});

describe("GET /quests — unlock requirements", () => {
  it("level requirement: locked below the required level, unlocked at or above it", async () => {
    const questId = await insertQuest({ title: "Level Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "level", minLevel: 5 });
    const user = await createTestUser(app);
    await setUserXpState(user.id, 0);

    const before = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    const found = before.body.find((q: { id: string }) => q.id === questId);
    expect(found.locked).toBe(true);
    expect(found.unlockRequirements[0]).toMatchObject({ type: "level", satisfied: false });

    await setUserXpState(user.id, 400); // level 5
    const after = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    const foundAfter = after.body.find((q: { id: string }) => q.id === questId);
    expect(foundAfter.locked).toBe(false);
  });

  it("quest requirement: locked until the required quest is completed", async () => {
    const requiredQuestId = await insertQuest({ title: "Prereq Quest" });
    const questId = await insertQuest({ title: "Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "quest", requiredQuestId });
    const user = await createTestUser(app);

    const before = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(before.body.find((q: { id: string }) => q.id === questId).locked).toBe(true);

    await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId: requiredQuestId });

    const after = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(after.body.find((q: { id: string }) => q.id === questId).locked).toBe(false);
  });

  it("checkin requirement: locked until a check-in at the required pin", async () => {
    const pinId = await insertVerifiedPin();
    const questId = await insertQuest({ title: "Checkin Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "checkin", requiredPinId: pinId });
    const user = await createTestUser(app);

    const before = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(before.body.find((q: { id: string }) => q.id === questId).locked).toBe(true);

    await checkIn(user.id, pinId);

    const after = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(after.body.find((q: { id: string }) => q.id === questId).locked).toBe(false);
  });

  it("category requirement: locked until N distinct pins in that category are visited", async () => {
    const pinA = await insertVerifiedPin({ category: "food" });
    const pinB = await insertVerifiedPin({ category: "food" });
    const questId = await insertQuest({ title: "Category Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "category", category: "food", countThreshold: 2 });
    const user = await createTestUser(app);

    await checkIn(user.id, pinA);
    const oneVisit = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(oneVisit.body.find((q: { id: string }) => q.id === questId).locked).toBe(true);

    await checkIn(user.id, pinB);
    const twoVisits = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(twoVisits.body.find((q: { id: string }) => q.id === questId).locked).toBe(false);
  });

  it("location requirement: locked until N distinct pins in that country are visited", async () => {
    const pinA = await insertVerifiedPin({ country: "Vietnam" });
    const pinB = await insertVerifiedPin({ country: "Vietnam" });
    const questId = await insertQuest({ title: "Location Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "location", country: "Vietnam", countThreshold: 2 });
    const user = await createTestUser(app);

    await checkIn(user.id, pinA);
    const oneVisit = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(oneVisit.body.find((q: { id: string }) => q.id === questId).locked).toBe(true);

    await checkIn(user.id, pinB);
    const twoVisits = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(twoVisits.body.find((q: { id: string }) => q.id === questId).locked).toBe(false);
  });

  it("compound AND: a quest with two requirements stays locked until both are satisfied", async () => {
    const pinId = await insertVerifiedPin();
    const questId = await insertQuest({ title: "Compound Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "level", minLevel: 5 });
    await insertUnlockRequirement(questId, { requirementType: "checkin", requiredPinId: pinId });
    const user = await createTestUser(app);
    await setUserXpState(user.id, 400); // level 5, satisfies only the level requirement

    const levelOnly = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(levelOnly.body.find((q: { id: string }) => q.id === questId).locked).toBe(true);

    await checkIn(user.id, pinId);
    const both = await request(app).get("/quests").set("Authorization", `Bearer ${user.token}`);
    expect(both.body.find((q: { id: string }) => q.id === questId).locked).toBe(false);
  });
});

describe("POST /quests/complete — locked quest rejection", () => {
  it("rejects completing a still-locked quest with 400", async () => {
    const questId = await insertQuest({ title: "Level Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "level", minLevel: 5 });
    const user = await createTestUser(app);
    await setUserXpState(user.id, 0);

    const res = await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });

    expect(res.status).toBe(400);
  });

  it("allows completing a quest once its unlock requirements are met", async () => {
    const questId = await insertQuest({ title: "Level Gated Quest" });
    await insertUnlockRequirement(questId, { requirementType: "level", minLevel: 2 });
    const user = await createTestUser(app);
    await setUserXpState(user.id, 150); // level 2

    const res = await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });

    expect(res.status).toBe(200);
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

describe("POST /quests/complete — level-up and level-skip", () => {
  it("detects a normal level-up when XP crosses a 100-boundary", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 90);
    const questId = await insertQuest({ xpReward: 20 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.status).toBe(200);
    expect(res.body.leveledUp).toBe(true);
    expect(res.body.previousLevel).toBe(1);
    expect(res.body.level).toBe(2);
    expect(res.body.skippedLevels).toBe(0);
  });

  it("does not report a level-up when XP doesn't cross a boundary", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 10);
    const questId = await insertQuest({ xpReward: 20 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.leveledUp).toBe(false);
    expect(res.body.skippedLevels).toBe(0);
  });

  it("skips 1 level at the 5-quest tier when the 80% XP gate is met", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 85, 4); // 85% into the level, 4 quests already in streak
    const questId = await insertQuest({ xpReward: 0 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.leveledUp).toBe(true);
    expect(res.body.skippedLevels).toBe(1);
    expect(res.body.level).toBe(2); // level 1 + 1 skipped

    const row = await pool.query("SELECT quests_completed_since_levelup FROM users WHERE id = $1", [user.id]);
    expect(row.rows[0].quests_completed_since_levelup).toBe(0);
  });

  it("does not skip at the 5-quest tier when XP is below the 80% gate", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 50, 4); // only 50% into the level
    const questId = await insertQuest({ xpReward: 0 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.leveledUp).toBe(false);
    expect(res.body.skippedLevels).toBe(0);

    const row = await pool.query("SELECT quests_completed_since_levelup FROM users WHERE id = $1", [user.id]);
    expect(row.rows[0].quests_completed_since_levelup).toBe(5); // armed for next time
  });

  it("skips 2 levels at the 7-quest tier when the 70% XP gate is met", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 75, 6);
    const questId = await insertQuest({ xpReward: 0 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.skippedLevels).toBe(2);
    expect(res.body.level).toBe(3); // level 1 + 2 skipped
  });

  it("skips 5 levels at the 10-quest tier when the 60% XP gate is met", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 65, 9);
    const questId = await insertQuest({ xpReward: 0 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.skippedLevels).toBe(5);
    expect(res.body.level).toBe(6); // level 1 + 5 skipped
  });

  it("picks the highest matching tier when the streak jumps straight to 10", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 65, 9); // this completion makes it the 10th
    const questId = await insertQuest({ xpReward: 0 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.skippedLevels).toBe(5);
  });

  it("resets the streak on a plain level-up, not just on a skip", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 90, 3);
    const questId = await insertQuest({ xpReward: 20 });

    const res = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(res.body.leveledUp).toBe(true);
    const row = await pool.query("SELECT quests_completed_since_levelup FROM users WHERE id = $1", [user.id]);
    expect(row.rows[0].quests_completed_since_levelup).toBe(0);
  });

  it("does not increment the streak or report a level-up when replaying an already-completed quest", async () => {
    const user = await createTestUser(app);
    await setUserXpState(user.id, 50, 2);
    const questId = await insertQuest({ xpReward: 0 });

    await request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });
    const replay = await request(app)
      .post("/quests/complete")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ questId });

    expect(replay.body.alreadyCompleted).toBe(true);
    expect(replay.body.leveledUp).toBe(false);
    expect(replay.body.skippedLevels).toBe(0);

    const row = await pool.query("SELECT quests_completed_since_levelup FROM users WHERE id = $1", [user.id]);
    expect(row.rows[0].quests_completed_since_levelup).toBe(3); // only incremented once, by the first call
  });
});
