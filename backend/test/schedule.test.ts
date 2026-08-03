import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

async function insertPin(name = "Schedule Test Pin"): Promise<string> {
  const result = await pool.query(
    `INSERT INTO verified_pins (name, category, country, location, is_verified)
     VALUES ($1, 'attraction', 'Thailand', ST_MakePoint(100.5018, 13.7563)::geography, TRUE)
     RETURNING id`,
    [name]
  );
  return result.rows[0].id as string;
}

describe("POST /schedule", () => {
  it("adds a pin to the user's schedule for a date", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01", startTime: "09:30", endTime: "11:00", note: "Morning visit" });

    expect(res.status).toBe(201);
    expect(res.body.pin_id).toBe(pinId);
    expect(res.body.pin_name).toBe("Schedule Test Pin");
    expect(res.body.scheduled_date).toBe("2026-08-01");
    expect(res.body.start_time).toBe("09:30:00");
    expect(res.body.end_time).toBe("11:00:00");
    expect(res.body.note).toBe("Morning visit");
  });

  it("returns 400 when endTime is not after startTime", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01", startTime: "11:00", endTime: "09:30" });

    expect(res.status).toBe(400);
  });

  it("returns 404 for a nonexistent pin", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId: "00000000-0000-0000-0000-000000000000", scheduledDate: "2026-08-01" });
    expect(res.status).toBe(404);
  });

  it("returns 400 for a malformed date", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "not-a-date" });
    expect(res.status).toBe(400);
  });

  it("returns 409 for a duplicate (user, pin, date)", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    expect(res.status).toBe(409);
  });

  it("allows the same pin scheduled on a different date", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const res = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-02" });

    expect(res.status).toBe(201);
  });

  it("rejects without auth", async () => {
    const pinId = await insertPin();
    const res = await request(app).post("/schedule").send({ pinId, scheduledDate: "2026-08-01" });
    expect(res.status).toBe(401);
  });
});

describe("GET /schedule", () => {
  it("lists only the calling user's items, optionally filtered by date, ordered by date then time", async () => {
    const pinA = await insertPin("Pin A");
    const pinB = await insertPin("Pin B");
    const user = await createTestUser(app);
    const other = await createTestUser(app);

    await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId: pinA, scheduledDate: "2026-08-02", startTime: "15:00" });
    await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId: pinB, scheduledDate: "2026-08-01", startTime: "09:00" });
    await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${other.token}`)
      .send({ pinId: pinA, scheduledDate: "2026-08-01" });

    const all = await request(app).get("/schedule").set("Authorization", `Bearer ${user.token}`);
    expect(all.status).toBe(200);
    expect(all.body.map((i: { pin_name: string }) => i.pin_name)).toEqual(["Pin B", "Pin A"]);

    const filtered = await request(app)
      .get("/schedule")
      .query({ date: "2026-08-01" })
      .set("Authorization", `Bearer ${user.token}`);
    expect(filtered.body).toHaveLength(1);
    expect(filtered.body[0].pin_name).toBe("Pin B");
  });

  it("rejects without auth", async () => {
    const res = await request(app).get("/schedule");
    expect(res.status).toBe(401);
  });
});

describe("PUT /schedule/:id", () => {
  it("lets the owner partially update an item", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    const created = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const res = await request(app)
      .put(`/schedule/${created.body.id}`)
      .set("Authorization", `Bearer ${user.token}`)
      .send({ note: "Updated note" });

    expect(res.status).toBe(200);
    expect(res.body.note).toBe("Updated note");
    expect(res.body.scheduled_date).toBe("2026-08-01");
  });

  it("returns 400 when an update would leave endTime not after startTime", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    const created = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01", startTime: "10:00", endTime: "11:00" });

    const res = await request(app)
      .put(`/schedule/${created.body.id}`)
      .set("Authorization", `Bearer ${user.token}`)
      .send({ startTime: "12:00" });

    expect(res.status).toBe(400);
  });

  it("returns 403 when a non-owner tries to update", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);
    const other = await createTestUser(app);

    const created = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const res = await request(app)
      .put(`/schedule/${created.body.id}`)
      .set("Authorization", `Bearer ${other.token}`)
      .send({ note: "Hijacked" });

    expect(res.status).toBe(403);
  });

  it("returns 404 for a nonexistent item", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .put("/schedule/00000000-0000-0000-0000-000000000000")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ note: "x" });
    expect(res.status).toBe(404);
  });
});

describe("DELETE /schedule/:id", () => {
  it("lets the owner delete an item, removed from subsequent list", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);

    const created = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const del = await request(app)
      .delete(`/schedule/${created.body.id}`)
      .set("Authorization", `Bearer ${user.token}`);
    expect(del.status).toBe(204);

    const list = await request(app).get("/schedule").set("Authorization", `Bearer ${user.token}`);
    expect(list.body).toHaveLength(0);
  });

  it("returns 403 when a non-owner tries to delete", async () => {
    const pinId = await insertPin();
    const user = await createTestUser(app);
    const other = await createTestUser(app);

    const created = await request(app)
      .post("/schedule")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ pinId, scheduledDate: "2026-08-01" });

    const res = await request(app)
      .delete(`/schedule/${created.body.id}`)
      .set("Authorization", `Bearer ${other.token}`);
    expect(res.status).toBe(403);
  });

  it("rejects without auth", async () => {
    const res = await request(app).delete("/schedule/00000000-0000-0000-0000-000000000000");
    expect(res.status).toBe(401);
  });
});
