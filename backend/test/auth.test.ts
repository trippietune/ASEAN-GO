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
    });

    expect(res.status).toBe(201);
    expect(res.body.user.email).toBe("newuser@example.com");
    expect(res.body.user.display_name).toBe("New User");
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
    });

    const res = await request(app).post("/auth/register").send({
      email: "dupe@example.com",
      password: "differentpassword",
      displayName: "Second",
    });

    expect(res.status).toBe(409);
  });

  it("rejects a password shorter than 8 characters", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "shortpw@example.com",
      password: "short",
      displayName: "Short PW",
    });

    expect(res.status).toBe(400);
  });

  it("rejects an invalid email format", async () => {
    const res = await request(app).post("/auth/register").send({
      email: "not-an-email",
      password: "password123",
      displayName: "Bad Email",
    });

    expect(res.status).toBe(400);
  });
});

describe("POST /auth/login", () => {
  it("logs in with correct credentials", async () => {
    await request(app).post("/auth/register").send({
      email: "logintest@example.com",
      password: "correctpassword",
      displayName: "Login Test",
    });

    const res = await request(app).post("/auth/login").send({
      email: "logintest@example.com",
      password: "correctpassword",
    });

    expect(res.status).toBe(200);
    expect(res.body.token).toBeTruthy();
  });

  it("rejects a wrong password without leaking whether the email exists", async () => {
    await request(app).post("/auth/register").send({
      email: "wrongpw@example.com",
      password: "correctpassword",
      displayName: "Wrong PW",
    });

    const wrongPassword = await request(app).post("/auth/login").send({
      email: "wrongpw@example.com",
      password: "incorrectpassword",
    });
    const nonexistentEmail = await request(app).post("/auth/login").send({
      email: "doesnotexist@example.com",
      password: "whatever123",
    });

    expect(wrongPassword.status).toBe(401);
    expect(nonexistentEmail.status).toBe(401);
    // Same message for both cases — an attacker probing for valid emails
    // shouldn't be able to distinguish "wrong password" from "no such user".
    expect(wrongPassword.body.error).toBe(nonexistentEmail.body.error);
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

  it("refuses to sign in when the email is already registered under a different provider", async () => {
    await request(app).post("/auth/register").send({
      email: "shared@example.com",
      password: "password123",
      displayName: "Email User",
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

    const res = await request(app).post("/auth/facebook").send({ accessToken: "valid-token" });
    expect(res.status).toBe(409);

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
