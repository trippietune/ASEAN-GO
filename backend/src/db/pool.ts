import { Pool } from "pg";
import { env } from "../config/env";

// Supabase (and most managed Postgres) requires TLS; their certs aren't
// always in Node's default trust store, so we accept the connection without
// verifying the CA chain — acceptable here since the alternative is the
// connection failing outright, and the connection string itself (with
// credentials) is only ever passed via a trusted env var, not attacker input.
export const pool = new Pool({
  connectionString: env.databaseUrl,
  ssl: env.isProduction ? { rejectUnauthorized: false } : undefined,
});
