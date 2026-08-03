import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

async function createAchievement(
  admin: { token: string },
  overrides: {
    title?: string;
    criteriaType: string;
    criteriaCategory?: string;
    criteriaChapterId?: string;
    countThreshold?: number;
    xpReward?: number;
    coinReward?: number;
    isActive?: boolean;
  }
) {
  const res = await request(app)
    .post("/admin/achievements")
    .set("Authorization", `Bearer ${admin.token}`)
    .send({
      title: overrides.title ?? `Achievement ${Math.random().toString(36).slice(2, 8)}`,
      criteriaType: overrides.criteriaType,
      criteriaCategory: overrides.criteriaCategory,
      criteriaChapterId: overrides.criteriaChapterId,
      countThreshold: overrides.countThreshold,
      xpReward: overrides.xpReward ?? 0,
      coinReward: overrides.coinReward ?? 0,
      isActive: overrides.isActive ?? true,
    });
  return res.body.id as string;
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

async function completeQuest(user: { token: string }, questId: string) {
  return request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });
}

async function insertVerifiedPin(overrides: { category?: string } = {}): Promise<string> {
  const result = await pool.query(
    `INSERT INTO verified_pins (name, category, country, location, is_verified, is_scam_alert)
     VALUES ('Test Pin', $1, 'Thailand', ST_MakePoint(100.5018, 13.7563)::geography, TRUE, FALSE)
     RETURNING id`,
    [overrides.category ?? "attraction"]
  );
  return result.rows[0].id as string;
}

async function checkIn(user: { token: string }, pinId: string) {
  return request(app).post(`/pins/${pinId}/checkin`).set("Authorization", `Bearer ${user.token}`);
}

async function setUserXpState(userId: string, xp: number) {
  await pool.query(`UPDATE users SET xp = $2, level = FLOOR($2 / 100) + 1 WHERE id = $1`, [userId, xp]);
}

async function getUserAchievements(user: { token: string }) {
  const res = await request(app).get("/users/me/achievements").set("Authorization", `Bearer ${user.token}`);
  return res.body as Array<{ id: string; unlocked: boolean }>;
}

describe("Achievements — auto-award per criteria type", () => {
  it("quests_completed: awards once the threshold number of quests are completed", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "quests_completed", countThreshold: 2 });
    const q1 = await insertQuest();
    const q2 = await insertQuest();

    await completeQuest(user, q1);
    let achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(false);

    const res = await completeQuest(user, q2);
    expect(res.body.awardedAchievements.map((a: { id: string }) => a.id)).toContain(achievementId);

    achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(true);
  });

  it("checkins: awards once the threshold number of check-ins are made", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "checkins", countThreshold: 2 });
    const pin1 = await insertVerifiedPin();
    const pin2 = await insertVerifiedPin();

    await checkIn(user, pin1);
    let achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(false);

    const res = await checkIn(user, pin2);
    expect(res.body.awardedAchievements.map((a: { id: string }) => a.id)).toContain(achievementId);
  });

  it("category_visits: awards once N distinct pins in that category are visited", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "category_visits", criteriaCategory: "food", countThreshold: 2 });
    const pin1 = await insertVerifiedPin({ category: "food" });
    const pin2 = await insertVerifiedPin({ category: "food" });

    await checkIn(user, pin1);
    let achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(false);

    await checkIn(user, pin2);
    achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(true);
  });

  it("chapter_completed: awards once every quest in the chapter is completed", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const orderIndex = Math.floor(Math.random() * 9_000) * 10;
    const chapterRes = await request(app)
      .post("/admin/quest-chapters")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ title: "Chapter", orderIndex });
    const chapterId = chapterRes.body.id;
    const q1Res = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ title: "Q1", questType: "story", chapterId, chapterOrder: 1, xpReward: 0, coinReward: 0 });
    const q2Res = await request(app)
      .post("/admin/quests")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ title: "Q2", questType: "story", chapterId, chapterOrder: 2, xpReward: 0, coinReward: 0 });
    const achievementId = await createAchievement(admin, { criteriaType: "chapter_completed", criteriaChapterId: chapterId });

    await completeQuest(user, q1Res.body.id);
    let achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(false);

    await completeQuest(user, q2Res.body.id);
    achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(true);
  });

  it("level_reached: awards even when a level-skip jumps past the threshold without landing on it exactly", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "level_reached", countThreshold: 10 });

    // Set up the 10-quest / 60% XP-gate tier so completing one more quest
    // skips 5 levels in a single jump (level 8 -> 13), stepping over level
    // 10 without ever landing on it exactly. xp=765 is level 8 (FLOOR(765/100)+1)
    // at 65% into the level, satisfying the tier's 60% gate.
    await setUserXpState(user.id, 765);
    await pool.query("UPDATE users SET quests_completed_since_levelup = 9 WHERE id = $1", [user.id]);
    const questId = await insertQuest({ xpReward: 0 });

    const res = await completeQuest(user, questId);
    expect(res.body.level).toBeGreaterThanOrEqual(10);
    expect(res.body.awardedAchievements.map((a: { id: string }) => a.id)).toContain(achievementId);
  });

  it("is_active=false is never auto-awarded", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "quests_completed", countThreshold: 1, isActive: false });
    const questId = await insertQuest();

    await completeQuest(user, questId);

    const achievements = await getUserAchievements(user);
    // Inactive achievements aren't even shown (GET /users/me/achievements filters is_active).
    expect(achievements.find((a) => a.id === achievementId)).toBeUndefined();
  });

  it("is idempotent — does not duplicate the unlock row or double-award on repeated trigger", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "quests_completed", countThreshold: 1, xpReward: 50 });
    const q1 = await insertQuest();
    const q2 = await insertQuest();

    const first = await completeQuest(user, q1);
    expect(first.body.awardedAchievements.map((a: { id: string }) => a.id)).toContain(achievementId);

    const second = await completeQuest(user, q2);
    expect(second.body.awardedAchievements.map((a: { id: string }) => a.id)).not.toContain(achievementId);

    const rows = await pool.query(
      "SELECT id FROM user_achievements WHERE user_id = $1 AND achievement_id = $2",
      [user.id, achievementId]
    );
    expect(rows.rowCount).toBe(1);
  });
});

describe("Achievements — manual grant", () => {
  it("admin can manually grant a 'manual'-type achievement outside the trigger routes", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "manual" });

    const res = await request(app)
      .post(`/admin/achievements/${achievementId}/grant`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ userId: user.id });

    expect(res.status).toBe(201);
    const achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(true);
  });

  it("granting an already-granted achievement is a 409, not a duplicate", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "manual" });

    await request(app)
      .post(`/admin/achievements/${achievementId}/grant`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ userId: user.id });
    const second = await request(app)
      .post(`/admin/achievements/${achievementId}/grant`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({ userId: user.id });

    expect(second.status).toBe(409);
  });

  it("a 'manual' achievement is never auto-awarded even if its (nonexistent) criteria would otherwise match", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "manual" });
    const questId = await insertQuest();

    await completeQuest(user, questId);

    const achievements = await getUserAchievements(user);
    expect(achievements.find((a) => a.id === achievementId)!.unlocked).toBe(false);
  });

  it("moderator cannot grant achievements (admin-only)", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const moderator = await createTestUser(app, { role: "moderator" });
    const user = await createTestUser(app);
    const achievementId = await createAchievement(admin, { criteriaType: "manual" });

    const res = await request(app)
      .post(`/admin/achievements/${achievementId}/grant`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ userId: user.id });

    expect(res.status).toBe(403);
  });
});
