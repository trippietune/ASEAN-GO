import { config } from "dotenv";
import { defineConfig } from "vitest/config";

// Loaded here (before any test file, or src/config/env.ts, ever imports) so
// the whole app under test connects to the isolated test database rather
// than whatever DATABASE_URL happens to be in the developer's own .env.
config({ path: ".env.test", override: true });

export default defineConfig({
  test: {
    environment: "node",
    globals: false,
    testTimeout: 15000,
    hookTimeout: 20000,
    setupFiles: ["./test/setup.ts"],
    // Payments tests hit real Omise sandbox network calls and share module
    // state (the lazily-initialized Cloudinary/Omise SDK singletons) — run
    // test files serially to avoid cross-file DB truncation races.
    fileParallelism: false,
  },
});
