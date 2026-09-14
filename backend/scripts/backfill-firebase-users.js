// One-off script: creates a Firebase Authentication user for every existing
// `users` row that doesn't have one yet, and stores the resulting Firebase
// UID back into users.firebase_uid.
//
// Run locally (NOT in CI/deploy) with DATABASE_URL pointed at production and
// the same FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY
// used by the backend — this repo's own backend/.env already has them.
//
// Idempotent: safe to re-run — rows with firebase_uid already set are
// skipped, and an email that Firebase already knows about is looked up
// instead of re-created.
//
// Usage: node scripts/backfill-firebase-users.js

require("dotenv").config();
const { Pool } = require("pg");
const { initializeApp, cert } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const TESTER_EMAIL = "tester@example.com";
const TESTER_PASSWORD = "Test1234";

const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, "\n"),
  }),
});
const auth = getAuth(app);

async function createOrFetchFirebaseUser(email, displayName) {
  try {
    return await auth.createUser({ email, displayName, emailVerified: true });
  } catch (err) {
    if (err.code === "auth/email-already-exists") {
      return await auth.getUserByEmail(email);
    }
    throw err;
  }
}

async function main() {
  const { rows } = await pool.query(
    "SELECT id, email, display_name FROM users WHERE firebase_uid IS NULL ORDER BY created_at ASC"
  );

  let created = 0;
  let linked = 0;
  const needsPasswordReset = [];

  for (const row of rows) {
    const firebaseUser = await createOrFetchFirebaseUser(row.email, row.display_name);
    await pool.query("UPDATE users SET firebase_uid = $2, updated_at = now() WHERE id = $1", [row.id, firebaseUser.uid]);
    created += 1;
    linked += 1;

    if (row.email === TESTER_EMAIL) {
      // Demo account: set the SAME password it already uses today, so
      // sign-in keeps working end-to-end with zero email-delivery
      // dependency during the live demo.
      await auth.updateUser(firebaseUser.uid, { password: TESTER_PASSWORD });
      console.log(`Set demo password for ${TESTER_EMAIL}`);
    } else {
      needsPasswordReset.push(row.email);
    }
  }

  console.log(`\nDone. ${created} Firebase users created/fetched, ${linked} rows linked.`);
  if (needsPasswordReset.length > 0) {
    console.log(`\n${needsPasswordReset.length} accounts left passwordless in Firebase (will need "forgot password" next time they sign in via Firebase):`);
    needsPasswordReset.forEach((email) => console.log(`  - ${email}`));
  }

  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
