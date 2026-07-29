import { createServer } from "http";
import express from "express";
import cors from "cors";
import helmet from "helmet";
import { env } from "./config/env";
import { pool } from "./db/pool";
import { initSocketServer } from "./realtime/socket";
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

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());

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
    console.error("Readiness check failed:", err);
    res.status(503).json({ status: "error", database: "unreachable" });
  }
});

app.use("/auth", authRouter);
app.use("/users", usersRouter);
app.use("/pins", pinsRouter);
app.use("/quests", questsRouter);
app.use("/coins", coinsRouter);
app.use("/store", storeRouter);
app.use("/inventory", inventoryRouter);
app.use(reviewsRouter);
app.use("/safety", safetyRouter);
app.use(riskReportsRouter);
app.use(adminRouter);
app.use(paymentsRouter);
app.use(mediaRouter);

app.use(errorHandler);

const httpServer = createServer(app);
initSocketServer(httpServer);

httpServer.listen(env.port, () => {
  console.log(`ASEAN GO backend listening on port ${env.port}`);
});
