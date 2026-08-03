import { afterEach, describe, expect, it, vi } from "vitest";
import request from "supertest";
import jwt from "jsonwebtoken";
import { createApp } from "../src/app";
import { env } from "../src/config/env";

const app = createApp();

describe("POST /auth/register", () => {
  it("creates a user and returns a valid JWT", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "newuser@example.com",
      password: "password123",
      displayName: "New User",
      username: "newuser",
    });

    expect(res.status).toBe(201);
    expect(res.body.user.email).toBe("newuser@example.com");
    expect(res.body.user.display_name).toBe("New User");
    expect(res.body.user.username).toBe("newuser");
    expect(res.body.user.role).toBe("user");
    // Password hash must never be echoed back to the client.
    expect(res.body.user.password_hash).toBeUndefined();

    const payload = jwt.verify(res.body.token, env.jwtSecret) as { sub: string };
    expect(payload.sub).toBe(res.body.user.id);
  });

  it("rejects a duplicate email", async () => {
    await request(app).post("/auth/register").send({
      email: "dupe@example.com",
      password: "password123",
      displayName: "First",
      username: "dupefirst",
    });

    const res = await request(app).post("/auth/register").send({
      email: "dupe@example.com",
      password: "differentpassword",
      displayName: "Second",
      username: "dupesecond",
    });

    expect(res.status).toBe(409);
  });

  it("rejects a duplicate username, case-insensitively", async () => {
    await request(app).post("/auth/register").send({
      email: "userone@example.com",
      password: "password123",
      displayName: "User One",
      username: "TestUser",
    });

    const res = await request(app).post("/auth/register").send({
      email: "usertwo@example.com",
      password: "password123",
      displayName: "User Two",
      username: "testuser",
    });

    expect(res.status).toBe(409);
  });

  it("rejects a username with invalid characters", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "badusername@example.com",
      password: "password123",
      displayName: "Bad Username",
      username: "bad user!",
    });

    expect(res.status).toBe(400);
  });

  it("rejects a username shorter than 3 characters", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "shortusername@example.com",
      password: "password123",
      displayName: "Short Username",
      username: "ab",
    });

    expect(res.status).toBe(400);
  });

  it("rejects a password shorter than 8 characters", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "shortpw@example.com",
      password: "short",
      displayName: "Short PW",
      username: "shortpw",
    });

    expect(res.status).toBe(400);
  });

  it("rejects an invalid email format", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "not-an-email",
      password: "password123",
      displayName: "Bad Email",
      username: "bademail",
    });

    expect(res.status).toBe(400);
  });
});

describe("POST /auth/login", () => {
  it("logs in with correct credentials via email", async () => {
    await request(app).post("/auth/register").send({
      email: "logintest@example.com",
      password: "correctpassword",
      displayName: "Login Test",
      username: "logintest",
    });

    const res = await request(app).post("/auth/login").send({
      identifier: "logintest@example.com",
      password: "correctpassword",
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeTruthy();
  });

  it("logs in with a username instead of email", async () => {
    await request(app).post("/auth/register").send({
      email: "byusername@example.com",
      password: "correctpassword",
      displayName: "By Username",
      username: "byusername",
    });

    const res = await request(app).post("/auth/login").send({
      identifier: "byusername",
      password: "correctpassword",
    });

    expect(res.status).toBe(200);
    expect(res.body.user.email).toBe("byusername@example.com");
  });

  it("logs in with a username in different case than registered", async () => {
    await request(app).post("/auth/register").send({
      email: "casetest@example.com",
      password: "correctpassword",
      displayName: "Case Test",
      username: "CaseTest",
    });

    const res = await request(app).post("/auth/login").send({
      identifier: "casetest",
      password: "correctpassword",
    });

    expect(res.status).toBe(200);
  });

  it("rejects a wrong password without leaking whether the account exists", async () => {
    await request(app).post("/auth/register").send({
      email: "wrongpw@example.com",
      password: "correctpassword",
      displayName: "Wrong PW",
      username: "wrongpw",
    });

    const wrongPassword = await request(app).post("/auth/login").send({
      identifier: "wrongpw@example.com",
      password: "incorrectpassword",
    });
    const nonexistentIdentifier = await request(app).post("/auth/login").send({
      identifier: "doesnotexist@example.com",
      password: "whatever123",
    });

    expect(wrongPassword.status).toBe(401);
    expect(nonexistentIdentifier.status).toBe(401);
    // Same message for both cases — an attacker probing for valid accounts
    // shouldn't be able to distinguish "wrong password" from "no such account".
    expect(wrongPassword.body.error).toBe(nonexistentIdentifier.body.error);
  });

  it("rejects a wrong password when logging in by username, without leaking whether the username exists", async () => {
    await request(app).post("/auth/register").send({
      email: "wrongpwuser@example.com",
      password: "correctpassword",
      displayName: "Wrong PW User",
      username: "wrongpwuser",
    });

    const wrongPassword = await request(app).post("/auth/login").send({
      identifier: "wrongpwuser",
      password: "incorrectpassword",
    });
    const nonexistentUsername = await request(app).post("/auth/login").send({
      identifier: "nosuchusername",
      password: "whatever123",
    });

    expect(wrongPassword.status).toBe(401);
    expect(nonexistentUsername.status).toBe(401);
    expect(wrongPassword.body.error).toBe(nonexistentUsername.body.error);
  });
});

describe("POST /auth/google", () => {
  it("rejects with 501 when Google sign-in isn't configured (no GOOGLE_CLIENT_ID in test env)", async () => {
    const res = await request(app).post("/auth/google").send({ idToken: "whatever" });
    expect(res.status).toBe(501);
  });

  it("rejects a request missing idToken with a validation error", async () => {
    const res = await request(app).post("/auth/google").send({});
    expect(res.status).toBe(400);
  });
});

describe("POST /auth/facebook", () => {
  afterEach(() => {
    vi.unstubAllGlobals();
  });

  it("rejects with 501 when Facebook sign-in isn't configured (no FACEBOOK_APP_ID in test env)", async () => {
    const res = await request(app).post("/auth/facebook").send({ accessToken: "whatever" });
    expect(res.status).toBe(501);
  });

  it("rejects a request missing accessToken with a validation error", async () => {
    const res = await request(app).post("/auth/facebook").send({});
    expect(res.status).toBe(400);
  });

  it("creates a new user on first Facebook sign-in and reuses it on a second sign-in with the configured app", async () => {
    vi.stubEnv("FACEBOOK_APP_ID", "test-app-id");
    vi.stubEnv("FACEBOOK_APP_SECRET", "test-app-secret");
    // env.ts reads process.env once at import time, so directly patch the
    // already-imported singleton rather than relying on re-evaluation.
    (env as { facebookAppId?: string }).facebookAppId = "test-app-id";
    (env as { facebookAppSecret?: string }).facebookAppSecret = "test-app-secret";

    const fetchMock = vi.fn(async (url: string) => {
      if (url.includes("/debug_token")) {
        return new Response(JSON.stringify({ data: { is_valid: true, app_id: "test-app-id" } }), { status: 200 });
      }
      return new Response(
        JSON.stringify({ id: "fb-user-123", name: "FB Person", email: "fbperson@example.com" }),
        { status: 200 }
      );
    });
    vi.stubGlobal("fetch", fetchMock);

    const first = await request(app).post("/auth/facebook").send({ accessToken: "valid-token" });
    expect(first.status).toBe(200);
    expect(first.body.user.email).toBe("fbperson@example.com");
    expect(first.body.user.auth_provider).toBe("facebook");
    expect(first.body.token).toBeTruthy();

    const second = await request(app).post("/auth/facebook").send({ accessToken: "valid-token" });
    expect(second.status).toBe(200);
    expect(second.body.user.id).toBe(first.body.user.id);

    (env as { facebookAppId?: string }).facebookAppId = undefined;
    (env as { facebookAppSecret?: string }).facebookAppSecret = undefined;
  });

  it("logs into the existing account when the email is already registered under a different provider", async () => {
    const registerRes = await request(app).post("/auth/register").send({
      email: "shared@example.com",
      password: "password123",
      displayName: "Email User",
      username: "sharedemailuser",
    });

    (env as { facebookAppId?: string }).facebookAppId = "test-app-id";
    (env as { facebookAppSecret?: string }).facebookAppSecret = "test-app-secret";

    vi.stubGlobal(
      "fetch",
      vi.fn(async (url: string) => {
        if (url.includes("/debug_token")) {
          return new Response(JSON.stringify({ data: { is_valid: true, app_id: "test-app-id" } }), { status: 200 });
        }
        return new Response(
          JSON.stringify({ id: "fb-user-999", name: "Someone Else", email: "shared@example.com" }),
          { status: 200 }
        );
      })
    );

    // The Facebook profile's verified email matches an existing
    // email/password account — that's proof enough of ownership, so this
    // logs into the same account rather than being refused or creating a
    // duplicate.
    const res = await request(app).post("/auth/facebook").send({ accessToken: "valid-token" });
    expect(res.status).toBe(200);
    expect(res.body.user.id).toBe(registerRes.body.user.id);
    expect(res.body.user.auth_provider).toBe("email");

    (env as { facebookAppId?: string }).facebookAppId = undefined;
    (env as { facebookAppSecret?: string }).facebookAppSecret = undefined;
  });
});

describe("Authenticated routes reject bad tokens", () => {
  it("rejects a request with no Authorization header", async () => {
    const res = await request(app).get("/users/me");
    expect(res.status).toBe(401);
  });

  it("rejects a malformed JWT", async () => {
    const res = await request(app).get("/users/me").set("Authorization", "Bearer not-a-real-jwt");
    expect(res.status).toBe(401);
  });

  it("rejects a JWT signed with the wrong secret", async () => {
    const forgedToken = jwt.sign({ sub: "some-user-id" }, "wrong-secret-entirely");
    const res = await request(app).get("/users/me").set("Authorization", `Bearer ${forgedToken}`);
    expect(res.status).toBe(401);
  });
});
