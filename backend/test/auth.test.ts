import { describe, expect, it } from "vitest";
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
