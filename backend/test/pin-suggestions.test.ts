import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";

const app = createApp();

function suggestionBody(overrides: Partial<Record<string, unknown>> = {}) {
  return {
    name: "Suggested Pin",
    category: "attraction",
    country: "Thailand",
    lat: 13.7563,
    lng: 100.5018,
    ...overrides,
  };
}

describe("POST /pin-suggestions", () => {
  it("returns 401 with no auth", async () => {
    const res = await request(app).post("/pin-suggestions").send(suggestionBody());
    expect(res.status).toBe(401);
  });

  it("lets any authenticated user submit a suggestion, pending by default", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${user.token}`)
      .send(suggestionBody({ name: "New Cafe" }));

    expect(res.status).toBe(201);
    expect(res.body.name).toBe("New Cafe");
    expect(res.body.status).toBe("pending");
    expect(res.body.submitted_by).toBe(user.id);
  });

  it("returns 400 on invalid body (missing name)", async () => {
    const user = await createTestUser(app);
    const body = suggestionBody();
    delete (body as { name?: string }).name;
    const res = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${user.token}`)
      .send(body);
    expect(res.status).toBe(400);
  });

  it("returns 400 for out-of-range coordinates", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${user.token}`)
      .send(suggestionBody({ lat: 999 }));
    expect(res.status).toBe(400);
  });
});

describe("GET /pin-suggestions/mine", () => {
  it("returns 401 with no auth", async () => {
    const res = await request(app).get("/pin-suggestions/mine");
    expect(res.status).toBe(401);
  });

  it("returns only the caller's own suggestions, newest first", async () => {
    const user = await createTestUser(app);
    const other = await createTestUser(app);

    await request(app).post("/pin-suggestions").set("Authorization", `Bearer ${user.token}`).send(suggestionBody({ name: "Mine A" }));
    await request(app).post("/pin-suggestions").set("Authorization", `Bearer ${user.token}`).send(suggestionBody({ name: "Mine B" }));
    await request(app).post("/pin-suggestions").set("Authorization", `Bearer ${other.token}`).send(suggestionBody({ name: "Not Mine" }));

    const res = await request(app).get("/pin-suggestions/mine").set("Authorization", `Bearer ${user.token}`);
    expect(res.status).toBe(200);
    expect(res.body.map((s: { name: string }) => s.name)).toEqual(["Mine B", "Mine A"]);
  });
});

describe("GET /admin/pin-suggestions", () => {
  it("returns 403 for a plain user", async () => {
    const user = await createTestUser(app);
    const res = await request(app).get("/admin/pin-suggestions").set("Authorization", `Bearer ${user.token}`);
    expect(res.status).toBe(403);
  });

  it("returns 200 for moderator and admin, optionally filtered by status", async () => {
    const submitter = await createTestUser(app);
    const moderator = await createTestUser(app, { role: "moderator" });
    const admin = await createTestUser(app, { role: "admin" });

    await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Queue Item" }));

    const moderatorRes = await request(app).get("/admin/pin-suggestions").set("Authorization", `Bearer ${moderator.token}`);
    const adminRes = await request(app).get("/admin/pin-suggestions").set("Authorization", `Bearer ${admin.token}`);
    expect(moderatorRes.status).toBe(200);
    expect(adminRes.status).toBe(200);

    const filtered = await request(app)
      .get("/admin/pin-suggestions")
      .query({ status: "pending" })
      .set("Authorization", `Bearer ${admin.token}`);
    expect(filtered.status).toBe(200);
    expect(filtered.body.every((s: { status: string }) => s.status === "pending")).toBe(true);
  });
});

describe("PUT /admin/pin-suggestions/:id/approve", () => {
  it("returns 403 for a plain user and for a moderator", async () => {
    const submitter = await createTestUser(app);
    const moderator = await createTestUser(app, { role: "moderator" });
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Approve Perm Test" }));

    const userRes = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/approve`)
      .set("Authorization", `Bearer ${submitter.token}`);
    const moderatorRes = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/approve`)
      .set("Authorization", `Bearer ${moderator.token}`);

    expect(userRes.status).toBe(403);
    expect(moderatorRes.status).toBe(403);
  });

  it("lets an admin approve a suggestion, creating a verified pin attributed to the original submitter", async () => {
    const submitter = await createTestUser(app);
    const admin = await createTestUser(app, { role: "admin" });
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Approve Me", category: "food", city: "Bangkok" }));

    const res = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/approve`)
      .set("Authorization", `Bearer ${admin.token}`);

    expect(res.status).toBe(200);
    expect(res.body.pin.name).toBe("Approve Me");
    expect(res.body.pin.is_verified).toBe(true);
    expect(res.body.suggestion.status).toBe("approved");

    const pinRow = await pool.query("SELECT submitted_by, approved_by, is_verified FROM verified_pins WHERE id = $1", [
      res.body.pin.id,
    ]);
    expect(pinRow.rows[0].submitted_by).toBe(submitter.id);
    expect(pinRow.rows[0].approved_by).toBe(admin.id);
    expect(pinRow.rows[0].is_verified).toBe(true);

    const suggestionRow = await pool.query("SELECT status, resulting_pin_id, reviewed_by FROM pin_suggestions WHERE id = $1", [
      created.body.id,
    ]);
    expect(suggestionRow.rows[0].status).toBe("approved");
    expect(suggestionRow.rows[0].resulting_pin_id).toBe(res.body.pin.id);
    expect(suggestionRow.rows[0].reviewed_by).toBe(admin.id);
  });

  it("returns 409 approving an already-reviewed suggestion, and does not create a second pin", async () => {
    const submitter = await createTestUser(app);
    const admin = await createTestUser(app, { role: "admin" });
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Double Approve" }));

    const first = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/approve`)
      .set("Authorization", `Bearer ${admin.token}`);
    const second = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/approve`)
      .set("Authorization", `Bearer ${admin.token}`);

    expect(first.status).toBe(200);
    expect(second.status).toBe(409);

    const pinCount = await pool.query("SELECT COUNT(*)::int AS count FROM verified_pins WHERE name = 'Double Approve'");
    expect(pinCount.rows[0].count).toBe(1);
  });

  it("returns 404 approving a nonexistent suggestion", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const res = await request(app)
      .put("/admin/pin-suggestions/00000000-0000-0000-0000-000000000000/approve")
      .set("Authorization", `Bearer ${admin.token}`);
    expect(res.status).toBe(404);
  });
});

describe("PUT /admin/pin-suggestions/:id/reject", () => {
  it("returns 403 for a plain user", async () => {
    const submitter = await createTestUser(app);
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Reject Perm Test" }));

    const res = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/reject`)
      .set("Authorization", `Bearer ${submitter.token}`);
    expect(res.status).toBe(403);
  });

  it("lets a moderator reject a suggestion with a reason, creating no pin", async () => {
    const submitter = await createTestUser(app);
    const moderator = await createTestUser(app, { role: "moderator" });
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Reject Me" }));

    const res = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/reject`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({ reason: "Duplicate of an existing pin" });

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("rejected");
    expect(res.body.rejectionReason).toBe("Duplicate of an existing pin");

    const pinCount = await pool.query("SELECT COUNT(*)::int AS count FROM verified_pins WHERE name = 'Reject Me'");
    expect(pinCount.rows[0].count).toBe(0);
  });

  it("returns 404/409 rejecting an already-reviewed suggestion", async () => {
    const submitter = await createTestUser(app);
    const moderator = await createTestUser(app, { role: "moderator" });
    const created = await request(app)
      .post("/pin-suggestions")
      .set("Authorization", `Bearer ${submitter.token}`)
      .send(suggestionBody({ name: "Double Reject" }));

    const first = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/reject`)
      .set("Authorization", `Bearer ${moderator.token}`);
    const second = await request(app)
      .put(`/admin/pin-suggestions/${created.body.id}/reject`)
      .set("Authorization", `Bearer ${moderator.token}`);

    expect(first.status).toBe(200);
    expect(second.status).toBe(404);
  });
});
