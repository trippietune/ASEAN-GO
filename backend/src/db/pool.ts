import { Pool, types } from "pg";
import { env } from "../config/env";

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
