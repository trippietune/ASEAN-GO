import { describe, expect, it } from "vitest";
import request from "supertest";
import { createApp } from "../src/app";

describe("CORS — dev/test mode (no CORS_ALLOWED_ORIGINS set)", () => {
  const app = createApp();

  it("allows requests with no Origin header (mobile app, curl, server-to-server)", async () => {
    const res = await request(app).get("/health");
    expect(res.status).toBe(200);
    expect(res.headers["access-control-allow-origin"]).toBeUndefined();
  });

  it("allows any localhost origin regardless of port (Flutter web picks a random port per run)", async () => {
    const first = await request(app).get("/health").set("Origin", "http://localhost:5173");
    expect(first.status).toBe(200);
    expect(first.headers["access-control-allow-origin"]).toBe("http://localhost:5173");

    const second = await request(app).get("/health").set("Origin", "http://localhost:51323");
    expect(second.status).toBe(200);
    expect(second.headers["access-control-allow-origin"]).toBe("http://localhost:51323");
  });

  it("rejects a non-localhost origin", async () => {
    const res = await request(app).get("/health").set("Origin", "https://evil-site.example.com");
    expect(res.status).toBe(403);
  });
});

describe("CORS — explicit allowlist (CORS_ALLOWED_ORIGINS set, e.g. production)", () => {
  it("allows only the configured origins and rejects everything else, including localhost", async () => {
    process.env.CORS_ALLOWED_ORIGINS = "https://asean-go.vercel.app";
    // env.ts reads process.env once at import time — reset the module cache
    // so this test's createApp() picks up the env var set just above.
    let app: ReturnType<typeof createApp>;
    await import("../src/config/env").then(async ({ env }) => {
      (env as { corsAllowedOrigins: string[] | null }).corsAllowedOrigins = ["https://asean-go.vercel.app"];
    });
    app = createApp();

    const allowed = await request(app).get("/health").set("Origin", "https://asean-go.vercel.app");
    expect(allowed.status).toBe(200);
    expect(allowed.headers["access-control-allow-origin"]).toBe("https://asean-go.vercel.app");

    const rejected = await request(app).get("/health").set("Origin", "http://localhost:5173");
    expect(rejected.status).toBe(403);

    delete process.env.CORS_ALLOWED_ORIGINS;
    await import("../src/config/env").then(({ env }) => {
      (env as { corsAllowedOrigins: string[] | null }).corsAllowedOrigins = null;
    });
  });
});
