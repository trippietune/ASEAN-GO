import { createServer } from "http";
import { initSentry } from "./config/sentry";

// Must run before anything else is imported so Sentry's instrumentation can
// hook into modules (http, pg, etc.) as they're required.
initSentry();

import { createApp } from "./app";
import { env } from "./config/env";
import { logger } from "./config/logger";
import { initSocketServer } from "./realtime/socket";

const app = createApp();
const httpServer = createServer(app);
initSocketServer(httpServer);

httpServer.listen(env.port, () => {
  logger.info(`ASEAN GO backend listening on port ${env.port}`);
});
