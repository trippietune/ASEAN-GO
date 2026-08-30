import { Pool, types } from "pg";
import { env } from "../config/env";
import { logger } from "../config/logger";
import { Sentry } from "../config/sentry";

// DATE (OID 1082) defaults to a JS Date at local midnight, which then
// serializes through res.json()'s toISOString() shifted to a different
// calendar day in any timezone ahead of UTC. Keep it as the raw
// "YYYY-MM-DD" string instead — there's no timezone to lose if it's never
// parsed into a Date to begin with.
types.setTypeParser(1082, (value) => value);

// Supabase (and most managed Postgres) requires TLS; their certs aren't
// always in Node's default trust store, so we accept the connection without
// verifying the CA chain — acceptable here since the alternative is the
// connection failing outright, and the connection string itself (with
// credentials) is only ever passed via a trusted env var, not attacker input.
export const pool = new Pool({
  connectionString: env.databaseUrl,
  ssl: env.isProduction ? { rejectUnauthorized: false } : undefined,
});

// An idle client in the pool (not one currently serving a request) can still
// emit a connection-level error — e.g. Supabase pausing the project or
// dropping the socket. node-postgres surfaces that as an 'error' event on
// the Pool itself, and Node's default behavior for an unhandled 'error'
// event is to crash the process. Without this listener, a single dropped
// idle connection takes down the entire API rather than just failing the
// in-flight queries that actually depended on it.
pool.on("error", (err) => {
  logger.error({ err }, "Unexpected error on idle database client");
  Sentry.captureException(err, { tags: { source: "pg-pool" } });
});
