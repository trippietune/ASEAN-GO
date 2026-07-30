import { describe, expect, it, vi } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";
import * as mailer from "../src/modules/auth/mailer.client";

const app = createApp();

describe("POST /auth/forgot-password", () => {
  it("returns a generic success message for a registered email and sends a reset code", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "resetme@example.com",
      password: "originalpassword",
      displayName: "Reset Me",
    });

    const res = await request(app).post("/auth/forgot-password").send({ email: "resetme@example.com" });

    expect(res.status).toBe(200);
    expect(sendSpy).toHaveBeenCalledTimes(1);
    expect(sendSpy.mock.calls[0][0]).toBe("resetme@example.com");
    expect(sendSpy.mock.calls[0][1]).toMatch(/^\d{6}$/);

    sendSpy.mockRestore();
  });

  it("returns the same generic success message for an unregistered email, without sending anything", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    const res = await request(app).post("/auth/forgot-password").send({ email: "doesnotexist@example.com" });

    expect(res.status).toBe(200);
    expect(sendSpy).not.toHaveBeenCalled();

    sendSpy.mockRestore();
  });

  it("rejects an invalid email format", async () => {
    const res = await request(app).post("/auth/forgot-password").send({ email: "not-an-email" });
    expect(res.status).toBe(400);
  });

  it("does not send a reset code for an OAuth-only account (no password to reset via email)", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    // Insert an OAuth-only user directly since we can't drive a real Google
    // sign-in here — same shape /auth/google's findOrCreateSocialUser produces.
    const { pool } = await import("../src/db/pool");
    await pool.query(
      `INSERT INTO users (email, display_name, auth_provider, provider_id) VALUES ($1, $2, 'google', 'g-123')`,
      ["oauthonly@example.com", "OAuth Only"]
    );

    const res = await request(app).post("/auth/forgot-password").send({ email: "oauthonly@example.com" });

    expect(res.status).toBe(200);
    expect(sendSpy).not.toHaveBeenCalled();

    sendSpy.mockRestore();
  });
});

describe("POST /auth/reset-password", () => {
  it("resets the password with a valid code and allows logging in with the new password", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "fullflow@example.com",
      password: "originalpassword",
      displayName: "Full Flow",
    });
    await request(app).post("/auth/forgot-password").send({ email: "fullflow@example.com" });
    const code = sendSpy.mock.calls[0][1];

    const resetRes = await request(app)
      .post("/auth/reset-password")
      .send({ email: "fullflow@example.com", code, password: "brandnewpassword" });
    expect(resetRes.status).toBe(200);

    const oldPasswordLogin = await request(app)
      .post("/auth/login")
      .send({ email: "fullflow@example.com", password: "originalpassword" });
    expect(oldPasswordLogin.status).toBe(401);

    const newPasswordLogin = await request(app)
      .post("/auth/login")
      .send({ email: "fullflow@example.com", password: "brandnewpassword" });
    expect(newPasswordLogin.status).toBe(200);

    sendSpy.mockRestore();
  });

  it("rejects a code that has already been used", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "reused@example.com",
      password: "originalpassword",
      displayName: "Reused Code",
    });
    await request(app).post("/auth/forgot-password").send({ email: "reused@example.com" });
    const code = sendSpy.mock.calls[0][1];

    const first = await request(app)
      .post("/auth/reset-password")
      .send({ email: "reused@example.com", code, password: "newpassword1" });
    expect(first.status).toBe(200);

    const second = await request(app)
      .post("/auth/reset-password")
      .send({ email: "reused@example.com", code, password: "newpassword2" });
    expect(second.status).toBe(400);

    sendSpy.mockRestore();
  });

  it("rejects an unknown email or wrong code", async () => {
    const res = await request(app)
      .post("/auth/reset-password")
      .send({ email: "doesnotexist@example.com", code: "000000", password: "newpassword1" });
    expect(res.status).toBe(400);
  });

  it("rejects a malformed (non-6-digit) code with a validation error", async () => {
    const res = await request(app)
      .post("/auth/reset-password")
      .send({ email: "whatever@example.com", code: "abc", password: "newpassword1" });
    expect(res.status).toBe(400);
  });

  it("rejects a password shorter than 8 characters", async () => {
    const res = await request(app)
      .post("/auth/reset-password")
      .send({ email: "whatever@example.com", code: "123456", password: "short" });
    expect(res.status).toBe(400);
  });

  it("rejects a wrong code against a real pending reset and locks out after too many attempts", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "bruteforce@example.com",
      password: "originalpassword",
      displayName: "Brute Force",
    });
    await request(app).post("/auth/forgot-password").send({ email: "bruteforce@example.com" });
    const correctCode = sendSpy.mock.calls[0][1];
    const wrongCode = correctCode === "000000" ? "111111" : "000000";

    // 5 wrong attempts exhaust MAX_RESET_ATTEMPTS.
    for (let i = 0; i < 5; i++) {
      const res = await request(app)
        .post("/auth/reset-password")
        .send({ email: "bruteforce@example.com", code: wrongCode, password: "newpassword1" });
      expect(res.status).toBe(400);
    }

    // Even the correct code is now rejected — the code is burned after too many guesses.
    const finalAttempt = await request(app)
      .post("/auth/reset-password")
      .send({ email: "bruteforce@example.com", code: correctCode, password: "newpassword1" });
    expect(finalAttempt.status).toBe(400);

    sendSpy.mockRestore();
  });

  it("rejects an expired code", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "expired@example.com",
      password: "originalpassword",
      displayName: "Expired Code",
    });
    await request(app).post("/auth/forgot-password").send({ email: "expired@example.com" });
    const code = sendSpy.mock.calls[0][1];

    const { pool } = await import("../src/db/pool");
    await pool.query("UPDATE password_reset_tokens SET expires_at = now() - interval '1 hour'");

    const res = await request(app)
      .post("/auth/reset-password")
      .send({ email: "expired@example.com", code, password: "newpassword1" });
    expect(res.status).toBe(400);

    sendSpy.mockRestore();
  });

  it("only accepts the most recently requested code when multiple resets were requested", async () => {
    const sendSpy = vi.spyOn(mailer, "sendPasswordResetEmail").mockResolvedValue();

    await request(app).post("/auth/register").send({
      email: "multirequest@example.com",
      password: "originalpassword",
      displayName: "Multi Request",
    });
    await request(app).post("/auth/forgot-password").send({ email: "multirequest@example.com" });
    const firstCode = sendSpy.mock.calls[0][1];
    await request(app).post("/auth/forgot-password").send({ email: "multirequest@example.com" });
    const secondCode = sendSpy.mock.calls[1][1];

    const usingFirstCode = await request(app)
      .post("/auth/reset-password")
      .send({ email: "multirequest@example.com", code: firstCode, password: "newpassword1" });
    expect(usingFirstCode.status).toBe(400);

    const usingSecondCode = await request(app)
      .post("/auth/reset-password")
      .send({ email: "multirequest@example.com", code: secondCode, password: "newpassword1" });
    expect(usingSecondCode.status).toBe(200);

    sendSpy.mockRestore();
  });
});
