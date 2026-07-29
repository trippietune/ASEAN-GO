# AseanGo — Production Deployment Runbook

Status snapshot: see the checklist at the bottom for what's done vs. pending.

## Live URLs

- **Backend (Railway):** https://aseango-backend-production.up.railway.app
- **Admin Dashboard (Vercel):** https://asean-go.vercel.app
- **Repo:** https://github.com/trippietune/ASEAN-GO
- **Database:** Supabase project `pcsupxayqqppzhfvandg` (via Transaction pooler, `ap-northeast-2`)

## Architecture

- **Backend** — Node/Express/TypeScript, Docker image, deploys to Railway
- **Database** — Supabase (managed Postgres + PostGIS)
- **Admin Dashboard** — React/Vite, deploys to Vercel
- **Mobile** — Flutter, Android APK (signed) + iOS IPA (needs a Mac)
- **CI/CD** — GitHub Actions (`.github/workflows/ci.yml`, `deploy.yml`)

---

## 1. Database (Supabase)

Already provisioned and migrated as of this runbook — all 9 migrations in
`backend/db/migrations/` have been applied, PostGIS and uuid-ossp extensions
are enabled.

**Important — IPv6 gotcha:** Supabase's direct connection host
(`db.<ref>.supabase.co`) is IPv6-only on all new projects. Most container
platforms (Railway included) don't route outbound IPv6 by default, so the
direct host **will time out** from a deployed backend even though it works
fine from your own machine. Use the **Connection Pooler** string instead:

1. Supabase Dashboard → your project → **Connect** button (top of page)
2. Choose the **Transaction pooler** tab (recommended for a stateless API;
   Session pooler also works if you hit prepared-statement issues)
3. Copy the string — it looks like:
   `postgresql://postgres.<project-ref>:<password>@aws-0-<region>.pooler.supabase.com:6543/postgres`
4. Put that in `DATABASE_URL` wherever the backend actually runs (Railway env
   vars) — not the direct host.

To re-run migrations against a fresh database:
```bash
cd backend
node -e "
require('dotenv').config();
const fs = require('fs');
const { Pool } = require('pg');
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });
(async () => {
  for (const file of fs.readdirSync('db/migrations').filter(f => f.endsWith('.sql')).sort()) {
    await pool.query(fs.readFileSync('db/migrations/' + file, 'utf8'));
    console.log('OK', file);
  }
  process.exit(0);
})();
"
```

---

## 2. Backend (Railway) — ✅ DEPLOYED

Live at **https://aseango-backend-production.up.railway.app**, project
`aseango-backend` in Thanapond Buadeang's Railway workspace. Verified
end-to-end: `/health`, `/ready` (real DB ping), and a real
register → JWT → row-in-Supabase round trip through the live URL.

Files in place: `backend/Dockerfile`, `backend/.dockerignore`,
`backend/railway.json`, `backend/.env.production.example`.

Health checks: `GET /health` (liveness, no dependencies) and `GET /ready`
(pings the database, returns 503 if unreachable) — `railway.json` is
configured to use `/health` for Railway's own probe.

Env vars are set on the Railway service: `NODE_ENV`, `JWT_SECRET` (freshly
generated for production — **not** the same one used locally),
`DATABASE_URL` via the Supabase pooler, `OMISE_PUBLIC_KEY`/`OMISE_SECRET_KEY`
(sandbox keys), and `CLOUDINARY_CLOUD_NAME`/`CLOUDINARY_API_KEY`/
`CLOUDINARY_API_SECRET` — media uploads verified end-to-end in production
(real upload → Cloudinary URL returned → publicly accessible → `media_assets`
row recorded correctly for later cleanup).

To redeploy after code changes:
```bash
cd backend
railway up --service aseango-backend
```
Or just push to `main` — the GitHub Actions deploy workflow (`deploy.yml`)
handles it automatically once `RAILWAY_TOKEN` is added as a repo secret
(Railway dashboard → account settings → Tokens).

**Don't wrap values in quotes** in Railway's Variables UI — paste the raw
string. This was hit and confirmed during setup: a quoted `DATABASE_URL`
connects fine via `dotenv` locally (it strips quotes) but breaks when read
literally by Docker/other platforms, producing a confusing `ENOTFOUND`
against a garbled hostname instead of an obvious auth error.

Railway assigns a `*.up.railway.app` domain automatically; SSL is automatic
and covers that domain with no setup needed. See §5 for a custom domain.

**Still needed:** real `CLOUDINARY_CLOUD_NAME`/`CLOUDINARY_API_KEY`/
`CLOUDINARY_API_SECRET` values set via `railway variables --set ... --service aseango-backend`.

### CI/CD

`.github/workflows/deploy.yml` runs after `ci.yml` passes on `main`, and
calls `railway up` using a `RAILWAY_TOKEN` repo secret. Generate one via
Railway dashboard → account settings → Tokens, then add it at
GitHub repo → Settings → Secrets and variables → Actions.

---

## 3. Admin Dashboard (Vercel) — ✅ DEPLOYED

Live at **https://asean-go.vercel.app**, project `asean-go` under the
`thanapond` Vercel account, connected via GitHub integration to
`trippietune/ASEAN-GO` (Root Directory setting: `admin`) — every push to
`main` auto-deploys.

`VITE_API_BASE_URL` is set to the Railway backend URL in the Vercel
project's Production environment variables; verified the built JS bundle
references the Railway URL (not `localhost`) and that CORS from the backend
allows this origin.

Files in place: `admin/vercel.json` (SPA rewrite so client-side routes like
`/pins` don't 404 on refresh).

**Gotcha hit during setup:** Vite bakes `VITE_*` env vars in at *build* time,
not runtime — setting the var in Vercel's dashboard after a build already
ran does nothing until the next build. If the deployed dashboard ever seems
to be calling the wrong API URL, check the env var is set, then trigger a
new deployment (push a commit, or use the dashboard's "Redeploy" button)
rather than assuming the existing build will pick it up.

**Also hit:** running `vercel` CLI commands from inside `admin/` while the
Vercel project also has a dashboard-configured "Root Directory: admin"
causes a double-path error (tries to resolve `admin/admin`). Prefer letting
the GitHub integration handle deploys; only use the CLI for one-off env var
management (`vercel env add/ls`), run from `admin/` with the project already
linked via `vercel link --project asean-go`.

To manage env vars via CLI:
```bash
cd admin
vercel link --project asean-go
vercel env add VITE_API_BASE_URL production
vercel env ls
```

For the GitHub Actions deploy job (`deploy.yml`) to also work as a fallback,
add `VERCEL_TOKEN` (Vercel dashboard → Settings → Tokens), `VERCEL_ORG_ID`,
`VERCEL_PROJECT_ID` (from `admin/.vercel/project.json` after linking) as
GitHub repo secrets — optional since the GitHub integration already
auto-deploys.

Vercel's `*.vercel.app` domain gets automatic SSL. See §5 for custom domain.

---

## 4. Mobile

### Android — ✅ built and signed against the live backend

A release keystore was generated at `mobile/android/keystore/aseango-release.jks`
(gitignored — **back this file up somewhere safe**; losing it means you can
never publish an update to the same Play Store listing again). Passwords are
in `mobile/android/keystore/keystore.properties` (also gitignored).

The signing config in `android/app/build.gradle.kts` automatically uses this
keystore when present, falling back to debug signing if it's missing (e.g.
on a contributor's machine or a CI runner without the file).

Current release APK (`build/app/outputs/flutter-apk/app-release.apk`) was
built with:
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://aseango-backend-production.up.railway.app
```
Signing verified via `apksigner verify --print-certs` (real AseanGo cert, not
debug). Rebuild with the same command any time the backend URL changes (e.g.
after §5's custom domain is set up).

For Play Store, an `.aab` (App Bundle) is generally required instead of a raw
APK: `flutter build appbundle --release --dart-define=API_BASE_URL=...`

### iOS — cannot be done from this machine

Building an IPA requires:
- **A Mac** running Xcode (Flutter's iOS toolchain doesn't run on Windows/Linux)
- An **Apple Developer Program** account ($99/year) for code signing and
  App Store distribution
- A signing certificate + provisioning profile created in Apple's developer portal

Once you have those, the build itself is:
```bash
flutter build ipa --release --dart-define=API_BASE_URL=https://<your-railway-domain>
```
This produces `build/ios/ipa/*.ipa`, ready for TestFlight/App Store Connect upload.

---

## 5. Domain + SSL

Both Railway and Vercel provision free automatic SSL (via Let's Encrypt) for
any domain you attach — no separate certificate purchase or renewal needed.

1. Buy/own a domain (registrar of your choice)
2. Railway: service Settings → Networking → Custom Domain → add e.g.
   `api.yourdomain.com` → Railway shows a CNAME target → add that CNAME at
   your DNS provider
3. Vercel: project Settings → Domains → add e.g. `admin.yourdomain.com` →
   same CNAME pattern
4. Wait for DNS propagation (minutes to a few hours) — both platforms
   auto-issue SSL once the CNAME resolves correctly
5. Update `VITE_API_BASE_URL` (Vercel) and any mobile build's
   `API_BASE_URL` to point at the new custom API domain

This step needs your registrar/DNS access — I can't do it for you.

---

## 6. Omise — going from sandbox to live payments

Current keys in use are **test mode** (`pkey_test_...` / `skey_test_...`).
Switching to real charges requires:

1. Log into the Omise Dashboard, complete **merchant/business verification**
   (company docs, bank account details) — this is a manual review process on
   Omise's side that only the account owner can initiate
2. Once approved, switch the dashboard to **Live mode** and copy the
   `pkey_live_...` / `skey_live_...` keys
3. Set those as `OMISE_PUBLIC_KEY` / `OMISE_SECRET_KEY` in Railway's
   production env vars (and in the mobile build's `OMISE_PUBLIC_KEY`
   `--dart-define`)
4. Re-register the webhook URL in Omise's dashboard pointing at your live
   backend: `https://<your-domain>/payments/omise/webhook`
5. Do a real small-value end-to-end test charge before announcing launch

This can't be done by an agent — it requires your business identity and
banking details.

---

## Checklist

- [x] Supabase database provisioned, PostGIS enabled, all migrations applied
- [x] Backend hardened for production (JWT_SECRET check, DB SSL, `/health` + `/ready`)
- [x] Backend Dockerfile written and test-built
- [x] Railway deploy config (`railway.json`)
- [x] GitHub Actions CI (typecheck/build all 3 projects) + deploy pipeline
- [x] Admin dashboard Vercel config (SPA rewrites), build verified
- [x] Android release keystore generated, signing wired into Gradle, release APK built
- [x] `DATABASE_URL` switched to the Supabase pooler string, verified end-to-end from inside a Docker container in production mode (register → JWT issued → row written/read back on Supabase)
- [x] Pushed to GitHub (`trippietune/ASEAN-GO`)
- [x] Backend deployed to Railway, live at `aseango-backend-production.up.railway.app`, verified end-to-end
- [x] Admin dashboard deployed to Vercel via GitHub integration, live at `asean-go.vercel.app`, correct backend URL verified in the built bundle + CORS verified
- [x] Release APK rebuilt against the live production backend URL
- [x] Real Cloudinary keys set on Railway, media upload pipeline verified end-to-end in production (upload → Cloudinary URL → accessible → `media_assets` row recorded)
- [ ] **Blocked on you:** custom domain + DNS records (see §5)
- [ ] **Blocked on you:** Omise live-mode business verification (see §6)
- [ ] **Needs a Mac:** iOS IPA build (Xcode + Apple Developer account)
- [ ] Optional: add `RAILWAY_TOKEN`/`VERCEL_TOKEN`+IDs as GitHub secrets so `deploy.yml` can auto-deploy on push (currently Vercel already auto-deploys via its own GitHub integration independent of this workflow; Railway does not yet)
