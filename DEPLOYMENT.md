# AseanGo — Production Deployment Runbook

Status snapshot: see the checklist at the bottom for what's done vs. pending.

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

## 2. Backend (Railway)

Files already in place: `backend/Dockerfile`, `backend/.dockerignore`,
`backend/railway.json`, `backend/.env.production.example`.

Health checks: `GET /health` (liveness, no dependencies) and `GET /ready`
(pings the database, returns 503 if unreachable) — `railway.json` is
configured to use `/health` for Railway's own probe.

### Steps (you'll need to run these yourself — they require your Railway login)

```bash
npm i -g @railway/cli
railway login
cd backend
railway init          # or `railway link` if the project already exists
railway up            # first manual deploy
```

Then in the Railway dashboard, set every variable from
`backend/.env.production.example` under the service's **Variables** tab
(never commit real values — that file only documents the shape). At minimum:
- `DATABASE_URL` — the pooler string from step 1
- `JWT_SECRET` — generate with `openssl rand -base64 48`; the app **refuses
  to boot** if this is left as the dev default in production (checked in
  `src/config/env.ts`)
- `NODE_ENV=production`
- `OMISE_PUBLIC_KEY` / `OMISE_SECRET_KEY` — sandbox keys for now; see §6
- `CLOUDINARY_*` — same keys already used in local dev

**Don't wrap values in quotes** in Railway's Variables UI — paste the raw
string. This was hit and confirmed during setup: a quoted `DATABASE_URL`
connects fine via `dotenv` locally (it strips quotes) but breaks when read
literally by Docker/other platforms, producing a confusing `ENOTFOUND`
against a garbled hostname instead of an obvious auth error.

Railway assigns a `*.up.railway.app` domain automatically; SSL is automatic
and covers that domain with no setup needed. See §5 for a custom domain.

### CI/CD

`.github/workflows/deploy.yml` runs after `ci.yml` passes on `main`, and
calls `railway up` using a `RAILWAY_TOKEN` repo secret. Generate one via
Railway dashboard → account settings → Tokens, then add it at
GitHub repo → Settings → Secrets and variables → Actions.

---

## 3. Admin Dashboard (Vercel)

Files already in place: `admin/vercel.json` (SPA rewrite so client-side
routes like `/pins` don't 404 on refresh).

### Steps (needs your Vercel login)

```bash
npm i -g vercel
cd admin
vercel login
vercel link        # creates the project, prints org/project IDs
vercel env add VITE_API_BASE_URL production   # paste the Railway backend URL
vercel --prod
```

After `vercel link`, grab the IDs it printed (or from `.vercel/project.json`)
and add as GitHub repo secrets for the CI deploy job:
`VERCEL_TOKEN` (Vercel dashboard → Settings → Tokens), `VERCEL_ORG_ID`,
`VERCEL_PROJECT_ID`.

Vercel's `*.vercel.app` domain gets automatic SSL. See §5 for custom domain.

---

## 4. Mobile

### Android — done, needs a rebuild once the backend URL is final

A release keystore was generated at `mobile/android/keystore/aseango-release.jks`
(gitignored — **back this file up somewhere safe**; losing it means you can
never publish an update to the same Play Store listing again). Passwords are
in `mobile/android/keystore/keystore.properties` (also gitignored).

The signing config in `android/app/build.gradle.kts` automatically uses this
keystore when present, falling back to debug signing if it's missing (e.g.
on a contributor's machine or a CI runner without the file).

A release APK was already built against the **local dev** backend URL as a
signing/build smoke test. Once the backend is deployed, rebuild pointed at
the real URL:
```bash
cd mobile
flutter build apk --release --dart-define=API_BASE_URL=https://<your-railway-domain>
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

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
- [ ] **Blocked on you:** first git commit + push to a GitHub repo (needed before Railway/Vercel/Actions can deploy from it)
- [ ] **Blocked on you:** `railway login` + first deploy
- [ ] **Blocked on you:** `vercel login` + first deploy
- [ ] **Blocked on you:** custom domain + DNS records
- [ ] **Blocked on you:** Omise live-mode business verification
- [ ] **Needs a Mac:** iOS IPA build (Xcode + Apple Developer account)
- [ ] Rebuild Android release APK once the real backend URL is live
