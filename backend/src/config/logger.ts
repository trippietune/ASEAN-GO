import pino from "pino";
import { env } from "./env";

/// JSON logs in production (Railway's log viewer parses these natively —
/// structured fields like req.id become filterable/searchable there), a
/// human-readable colorized format in local dev.
export const logger = pino({
  level: process.env.LOG_LEVEL ?? (env.nodeEnv === "test" ? "silent" : "info"),
  transport: env.isProduction
    ? undefined
    : { target: "pino-pretty", options: { colorize: true, translateTime: "HH:MM:ss", ignore: "pid,hostname" } },
});
