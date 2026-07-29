import { createServer } from "http";
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
