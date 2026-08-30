# Disaster Recovery

How ASEAN GO's data is backed up and how to restore it, if the production
Supabase database is ever lost, corrupted, or a bad migration/admin action
needs to be undone.

## Why this exists

Supabase's **free tier has no automated backups or point-in-time recovery
(PITR)** — that's a paid-tier-only feature. Without something in place, a
lost database has no recovery path at all. `.github/workflows/backup-db.yml`
is that something: it exists specifically to cover this gap, not because
it's the ideal backup strategy.

## What's backed up

A full `pg_dump` of the production database (schema + data, all tables),
taken **once a day** by `.github/workflows/backup-db.yml`, uploaded as a
GitHub Actions artifact on this repo.

- **Where**: GitHub → this repo → **Actions** tab → **Backup database**
  workflow → pick a run → **Artifacts** section at the bottom. Each artifact
  is named `aseango-backup-<UTC timestamp>`.
- **Retention**: 30 days. Older backups are deleted automatically by GitHub;
  there is no long-term archive beyond that window.
- **Access**: artifacts are only downloadable by someone with access to this
  GitHub repo. A dump contains full production data — password hashes,
  payment transaction records, user emails — treat a downloaded dump file
  exactly like a database credential: don't leave it lying around, don't
  attach it anywhere outside this process.

## Honest RPO / RTO for this setup

- **RPO (Recovery Point Objective) — up to ~24 hours of data loss.** The
  backup runs once a day; anything written between the last successful run
  and the incident is gone. This is materially worse than a paid tier's
  PITR (which can restore to almost any point in time), and is the direct
  cost of running on the free tier.
- **RTO (Recovery Time Objective) — expect 30–60 minutes, manual.** There is
  no one-click restore. Someone has to notice the incident, download the
  right artifact, provision or clear a target database, and run
  `pg_restore` by hand (steps below). None of this is automated.

If either number is unacceptable, the actual fix is upgrading the Supabase
project to a paid tier for real PITR — see "When to stop relying on this"
below.

## How to restore

You'll need `pg_restore` (comes with any local Postgres/`postgresql-client`
install) and the target database's connection string.

1. **Get the backup.** Go to the failed workflow run or the most recent
   successful one under Actions → Backup database, download the artifact
   `.zip`, and unzip it to get the `.dump` file.

2. **Decide the target.**
   - **Restoring into the same (now-empty or corrupted) database**: get the
     current `DATABASE_URL` from Railway (`railway variables --service
     aseango-backend` from `backend/`, or the Railway dashboard).
   - **Restoring into a fresh Supabase project** (e.g. the old one was
     deleted): create a new project in the Supabase dashboard, copy its
     pooler connection string (Settings → Database → Connection pooling),
     and use that as the target. You'll then need to update `DATABASE_URL`
     in Railway to point at the new project once the restore is done.

3. **Restore.**
   ```bash
   pg_restore --no-owner --no-privileges --clean --if-exists \
     -d "<target DATABASE_URL>" \
     aseango-backup-<timestamp>.dump
   ```
   `--clean --if-exists` drops existing objects before recreating them, so
   this is safe to run against a database that already has (broken/partial)
   data in it, not just an empty one.

   Restoring into any **non-Supabase** Postgres (e.g. testing this locally
   against a plain `postgres`/`postgis` Docker image) will print a handful
   of errors about `supabase_vault`/`transaction_timeout` — those are
   Supabase-internal objects the dump includes automatically and are safe to
   ignore (`pg_restore` reports "errors ignored on restore: N" and continues
   — verified end-to-end: application tables and all rows restore
   correctly regardless). Restoring into an actual Supabase project won't
   hit this at all, since those objects already exist there.

4. **Verify.** Run `psql "<target DATABASE_URL>" -c "SELECT count(*) FROM
   users;"` (and spot-check a couple of other tables) to confirm the data
   actually landed before pointing production traffic at it.

5. **If you restored into a new Supabase project**, update `DATABASE_URL` in
   Railway (`railway variables --set DATABASE_URL=... --service
   aseango-backend`) and redeploy.

## What this does NOT cover

- **Media uploads (Cloudinary)** — images/photos aren't in the Postgres
  database and aren't touched by this backup. Cloudinary has its own
  retention on its own plan; check there separately if that ever matters.
- **Anything written in the last backup cycle** — see RPO above.
- **Application code** — that's already recoverable via git history; this
  document is about data only.

## When to stop relying on this

This GitHub Actions backup is a stopgap appropriate for a free-tier,
low-traffic project. It stops being appropriate once:

- Real users/payments depend on the app staying up and current — a 24-hour
  RPO on payment data is a real business risk, not just a technical one.
- The database grows large enough that a daily full `pg_dump` becomes slow
  or expensive to run/store (not a concern yet — current production DB is
  ~19 MB).

At that point, upgrading the Supabase project to a paid tier (Pro, $25/mo at
time of writing) for built-in PITR is the correct fix, not a more elaborate
version of this workflow.
