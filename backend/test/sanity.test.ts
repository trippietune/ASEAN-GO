import { describe, expect, it } from "vitest";
import { pool } from "../src/db/pool";

describe("test harness", () => {
  it("connects to the test database", async () => {
    const result = await pool.query("SELECT current_database() AS db");
    expect(result.rows[0].db).toBe("asean_go_test");
  });
});
