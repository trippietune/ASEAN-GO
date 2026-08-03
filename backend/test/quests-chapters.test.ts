import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

// order_index has a unique constraint — tests run against a shared DB with
// no per-test cleanup, so a fixed small integer collides across runs/tests
// and across test cases in this file. relativeOrder preserves the caller's
// intended ordering (1 before 2) while a per-test random base keeps
// different test cases from colliding with each other.
function newOrderIndexBase() {
  return Math.floor(Math.random() * 9_000) * 10;
}
async function createChapter(admin: { token: string }, orderIndexBase: number, relativeOrder: number, title = "Chapter") {
  const res = await request(app)
    .post("/admin/quest-chapters")
    .set("Authorization", `Bearer ${admin.token}`)
    .send({ title, orderIndex: orderIndexBase + relativeOrder });
  return res.body.id as string;
}

async function createStoryQuest(admin: { token: string }, chapterId: string, chapterOrder: number, title: string) {
  const res = await request(app)
    .post("/admin/quests")
    .set("Authorization", `Bearer ${admin.token}`)
    .send({ title, questType: "story", chapterId, chapterOrder, xpReward: 10, coinReward: 0 });
  return res.body.id as string;
}

async function completeQuest(user: { token: string }, questId: string) {
  return request(app).post("/quests/complete").set("Authorization", `Bearer ${user.token}`).send({ questId });
}

async function isLocked(user: { token: string }, questId: string): Promise<boolean> {
  const res = await request(app).get("/quests?type=story").set("Authorization", `Bearer ${user.token}`);
  return res.body.find((q: { id: string }) => q.id === questId).locked;
}

describe("Story chapter progression", () => {
  it("a chapter with no predecessor has no cross-chapter gate", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const chapter1 = await createChapter(admin, newOrderIndexBase(), 1);
    const questId = await createStoryQuest(admin, chapter1, 1, "Chapter 1 Quest 1");

    expect(await isLocked(user, questId)).toBe(false);
  });

  it("within-chapter: quest 2 is locked until quest 1 is completed", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const chapter1 = await createChapter(admin, newOrderIndexBase(), 1);
    const quest1 = await createStoryQuest(admin, chapter1, 1, "Quest 1");
    const quest2 = await createStoryQuest(admin, chapter1, 2, "Quest 2");

    expect(await isLocked(user, quest2)).toBe(true);

    await completeQuest(user, quest1);

    expect(await isLocked(user, quest2)).toBe(false);
  });

  it("chapter 2 is locked until chapter 1's last quest is completed", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const base = newOrderIndexBase();
    const chapter1 = await createChapter(admin, base, 1);
    const chapter2 = await createChapter(admin, base, 2);
    const c1q1 = await createStoryQuest(admin, chapter1, 1, "C1 Quest 1");
    const c1q2 = await createStoryQuest(admin, chapter1, 2, "C1 Quest 2");
    const c2q1 = await createStoryQuest(admin, chapter2, 1, "C2 Quest 1");

    expect(await isLocked(user, c2q1)).toBe(true);

    await completeQuest(user, c1q1);
    expect(await isLocked(user, c2q1)).toBe(true); // chapter 1 not done yet

    await completeQuest(user, c1q2);
    expect(await isLocked(user, c2q1)).toBe(false); // chapter 1's last quest done
  });

  it("completing a chapter's last quest unlocks the next chapter's first quest, not just any of its quests", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const user = await createTestUser(app);
    const base = newOrderIndexBase();
    const chapter1 = await createChapter(admin, base, 1);
    const chapter2 = await createChapter(admin, base, 2);
    const c1q1 = await createStoryQuest(admin, chapter1, 1, "C1 Quest 1");
    const c2q1 = await createStoryQuest(admin, chapter2, 1, "C2 Quest 1");
    const c2q2 = await createStoryQuest(admin, chapter2, 2, "C2 Quest 2");

    await completeQuest(user, c1q1);

    expect(await isLocked(user, c2q1)).toBe(false);
    expect(await isLocked(user, c2q2)).toBe(true); // still gated on c2q1 within-chapter
  });

  it("deleting a chapter orphans its quests (not cascades) and cleans up dangling chapter_auto requirements", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const base = newOrderIndexBase();
    const chapter1 = await createChapter(admin, base, 1);
    const chapter2 = await createChapter(admin, base, 2);
    const c1q1 = await createStoryQuest(admin, chapter1, 1, "C1 Quest 1");
    const c2q1 = await createStoryQuest(admin, chapter2, 1, "C2 Quest 1");

    const deleteRes = await request(app)
      .delete(`/admin/quest-chapters/${chapter1}`)
      .set("Authorization", `Bearer ${admin.token}`);
    expect(deleteRes.status).toBe(204);

    const quest = await pool.query("SELECT chapter_id FROM quests WHERE id = $1", [c1q1]);
    expect(quest.rows[0].chapter_id).toBeNull();

    const questStillExists = await pool.query("SELECT id FROM quests WHERE id = $1", [c1q1]);
    expect(questStillExists.rowCount).toBe(1);

    const danglingRequirement = await pool.query(
      `SELECT id FROM quest_unlock_requirements WHERE quest_id = $1 AND source = 'chapter_auto'`,
      [c2q1]
    );
    expect(danglingRequirement.rowCount).toBe(0);
  });
});
