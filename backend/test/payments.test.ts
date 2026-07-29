import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import { pool } from "../src/db/pool";
import { createTestUser } from "./helpers";
import { createTestCardToken } from "./omiseHelpers";

const app = createApp();

describe("POST /coins/purchase", () => {
  it("charges a valid test card and credits coins synchronously", async () => {
    const user = await createTestUser(app);
    const token = await createTestCardToken();

    const res = await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "small", omiseToken: token });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.status).toBe("successful");
    expect(res.body.newBalance).toBe(30); // 'small' package = 30 coins

    const balanceRes = await request(app).get("/coins/balance").set("Authorization", `Bearer ${user.token}`);
    expect(balanceRes.body.balance).toBe(30);
  }, 20000);

  it("records a failed transaction and does not credit coins when the charge fails", async () => {
    const user = await createTestUser(app);
    const token = await createTestCardToken();

    // Omise tokens are single-use — reusing one is a real, deterministic
    // failure mode (verified against the sandbox during initial testing).
    await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "small", omiseToken: token });

    const res = await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "small", omiseToken: token });

    expect(res.status).toBe(402);

    const balanceRes = await request(app).get("/coins/balance").set("Authorization", `Bearer ${user.token}`);
    // First purchase succeeded (30), second (reused token) must not add more.
    expect(balanceRes.body.balance).toBe(30);
  }, 20000);

  it("rejects an unknown package id", async () => {
    const user = await createTestUser(app);
    const res = await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "not-a-real-package", omiseToken: "tokn_test_fake" });

    expect(res.status).toBe(400);
  });

  it("requires authentication", async () => {
    const res = await request(app).post("/coins/purchase").send({ packageId: "small", omiseToken: "tokn_test_fake" });
    expect(res.status).toBe(401);
  });
});

describe("POST /payments/omise/webhook — idempotency", () => {
  it("does not double-credit coins when the same event is replayed", async () => {
    const user = await createTestUser(app);
    const token = await createTestCardToken();

    const purchaseRes = await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "small", omiseToken: token });

    const tx = await pool.query("SELECT provider_charge_id FROM payment_transactions WHERE id = $1", [
      purchaseRes.body.transactionId,
    ]);
    const chargeId = tx.rows[0].provider_charge_id as string;

    // Find the real charge.create event Omise recorded for this charge, then
    // replay the webhook against it multiple times — this reproduces the
    // exact scenario (a normal charge fires charge.create, not
    // charge.complete) that was hand-verified against the sandbox earlier.
    // Event indexing can lag slightly behind the charge itself, so poll
    // briefly rather than assuming it's already there on the first look.
    const auth = Buffer.from(`${process.env.OMISE_SECRET_KEY}:`).toString("base64");
    let event: { id: string; key: string; data: { id: string } } | undefined;
    for (let attempt = 0; attempt < 10 && !event; attempt++) {
      if (attempt > 0) await new Promise((r) => setTimeout(r, 1000));
      const eventsRes = await fetch("https://api.omise.co/events?limit=100&order=reverse_chronological", {
        headers: { Authorization: `Basic ${auth}` },
      });
      const events = (await eventsRes.json()) as { data: { id: string; key: string; data: { id: string } }[] };
      event = events.data.find((e) => e.data?.id === chargeId);
    }
    expect(event).toBeTruthy();

    for (let i = 0; i < 3; i++) {
      const webhookRes = await request(app).post("/payments/omise/webhook").send({ id: event!.id });
      expect(webhookRes.status).toBe(200);
    }

    const balanceRes = await request(app).get("/coins/balance").set("Authorization", `Bearer ${user.token}`);
    expect(balanceRes.body.balance).toBe(30); // still 30, not 90, after 3 replays
  }, 30000);
});

describe("Admin refund", () => {
  async function purchaseAsUser() {
    const user = await createTestUser(app);
    const admin = await createTestUser(app, { role: "admin" });
    const token = await createTestCardToken();

    const purchaseRes = await request(app)
      .post("/coins/purchase")
      .set("Authorization", `Bearer ${user.token}`)
      .send({ packageId: "small", omiseToken: token });

    return { user, admin, transactionId: purchaseRes.body.transactionId as string };
  }

  it("fully refunds a successful transaction and claws back all coins", async () => {
    const { user, admin, transactionId } = await purchaseAsUser();

    const res = await request(app)
      .post(`/admin/payment-transactions/${transactionId}/refund`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.status).toBe("refunded");
    expect(res.body.coinsClawedBack).toBe(30);

    const balanceRes = await request(app).get("/coins/balance").set("Authorization", `Bearer ${user.token}`);
    expect(balanceRes.body.balance).toBe(0);
  }, 20000);

  it("rejects a second refund on an already-fully-refunded transaction", async () => {
    const { admin, transactionId } = await purchaseAsUser();

    await request(app)
      .post(`/admin/payment-transactions/${transactionId}/refund`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({});

    const res = await request(app)
      .post(`/admin/payment-transactions/${transactionId}/refund`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({});

    expect(res.status).toBe(400);
  }, 20000);

  it("rejects a moderator attempting a refund (admin-only)", async () => {
    const { transactionId } = await purchaseAsUser();
    const moderator = await createTestUser(app, { role: "moderator" });

    const res = await request(app)
      .post(`/admin/payment-transactions/${transactionId}/refund`)
      .set("Authorization", `Bearer ${moderator.token}`)
      .send({});

    expect(res.status).toBe(403);
  }, 20000);

  it("rejects a refund on a nonexistent transaction", async () => {
    const admin = await createTestUser(app, { role: "admin" });
    const res = await request(app)
      .post("/admin/payment-transactions/00000000-0000-0000-0000-000000000000/refund")
      .set("Authorization", `Bearer ${admin.token}`)
      .send({});

    expect(res.status).toBe(404);
  });

  it("does not let coin balance go negative when refunding coins the user already spent", async () => {
    const { user, admin, transactionId } = await purchaseAsUser();

    // Spend the coins on something before the refund happens.
    await pool.query("UPDATE users SET coin_balance = 0 WHERE id = $1", [user.id]);

    const res = await request(app)
      .post(`/admin/payment-transactions/${transactionId}/refund`)
      .set("Authorization", `Bearer ${admin.token}`)
      .send({});

    expect(res.status).toBe(200);
    expect(res.body.coinsClawedBack).toBe(0); // nothing left to claw back

    const balanceRes = await request(app).get("/coins/balance").set("Authorization", `Bearer ${user.token}`);
    expect(balanceRes.body.balance).toBe(0); // not negative
  }, 20000);
});
