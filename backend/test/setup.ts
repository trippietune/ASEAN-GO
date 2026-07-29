import { afterAll, beforeEach } from "vitest";
import { pool } from "../src/db/pool";

// Tables with FK dependencies on users/verified_pins — truncated together
// with CASCADE so ordering doesn't matter. Excludes schema/reference tables
// (spatial_ref_sys etc.) that migrations create but tests never touch.
const TABLES = [
  "coin_transactions",
  "payment_transactions",
  "media_assets",
  "sos_events",
  "risk_reports",
  "reviews",
  "pin_checkins",
  "user_quests",
  "inventory",
  "store_items",
  "quests",
  "verified_pins",
  "users",
];

export async function truncateAll(): Promise<void> {
  await pool.query(`TRUNCATE TABLE ${TABLES.join(", ")} RESTART IDENTITY CASCADE`);
}

beforeEach(async () => {
  await truncateAll();
});

afterAll(async () => {
  await pool.end();
});
