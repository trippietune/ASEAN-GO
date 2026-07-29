import express from "express";
import cors from "cors";
import helmet from "helmet";
import pinoHttp from "pino-http";
import { logger } from "./config/logger";
import { pool } from "./db/pool";
import { authRouter } from "./modules/auth/auth.routes";
import { usersRouter } from "./modules/users/users.routes";
import { pinsRouter } from "./modules/pins/pins.routes";
import { questsRouter } from "./modules/quests/quests.routes";
import { coinsRouter } from "./modules/coins/coins.routes";
import { storeRouter } from "./modules/store/store.routes";
import { inventoryRouter } from "./modules/inventory/inventory.routes";
import { reviewsRouter } from "./modules/reviews/reviews.routes";
import { safetyRouter } from "./modules/safety/safety.routes";
import { riskReportsRouter } from "./modules/risk-reports/risk-reports.routes";
import { adminRouter } from "./modules/admin/admin.routes";
import { paymentsRouter } from "./modules/payments/payments.routes";
import { mediaRouter } from "./modules/media/media.routes";
import { errorHandler } from "./middleware/errorHandler";
import { authLimiter, paymentLimiter, generalLimiter } from "./middleware/rateLimit";

/// Builds the Express app without starting a listener or Socket.IO — kept
/// separate from index.ts so tests can drive it in-process via supertest
/// (supertest starts/stops its own ephemeral server per test) without also
/// spinning up a real TCP listener on a fixed port or the WebSocket server.
export function createApp() {
  const app = express();

  // Railway (and most PaaS) put the app behind a reverse proxy — without
  // this, express-rate-limit and req.ip would see the proxy's IP for every
  // request instead of the real client, making per-IP limits meaningless.
  app.set("trust proxy", 1);

  app.use(helmet());
  app.use(cors());
  app.use(express.json());
  app.use(
    pinoHttp({
      logger,
      // Health/readiness are polled constantly by the platform — logging
      // every one of those at 'info' would drown out everything else.
      autoLogging: { ignore: (req) => req.url === "/health" || req.url === "/ready" },
    })
  );
  app.use(generalLimiter);

  // Liveness: process is up and serving requests. Used by the platform's
  // basic health check — must stay fast and dependency-free.
  app.get("/health", (_req, res) => res.json({ status: "ok" }));

  // Readiness: process is up AND its critical dependency (the database) is
  // actually reachable. Used for post-deploy verification and can back a
  // load balancer's readiness probe if the platform supports a separate one.
  app.get("/ready", async (_req, res) => {
    try {
      await pool.query("SELECT 1");
      res.json({ status: "ok", database: "connected" });
    } catch (err) {
      logger.error({ err }, "Readiness check failed");
      res.status(503).json({ status: "error", database: "unreachable" });
    }
  });

  app.use("/auth", authLimiter, authRouter);
  app.use("/users", usersRouter);
  app.use("/pins", pinsRouter);
  app.use("/quests", questsRouter);
  app.use("/coins", paymentLimiter, coinsRouter);
  app.use("/store", storeRouter);
  app.use("/inventory", inventoryRouter);
  app.use(reviewsRouter);
  app.use("/safety", safetyRouter);
  app.use(riskReportsRouter);
  app.use(adminRouter);
  app.use(paymentsRouter);
  app.use(mediaRouter);

  app.use(errorHandler);

  return app;
}
