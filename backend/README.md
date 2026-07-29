# ASEAN GO Backend

Node.js + Express + TypeScript API, backed by PostgreSQL/PostGIS.

## Setup

```bash
npm install
cp .env.example .env
docker compose up -d      # starts Postgres+PostGIS on host port 5433
for f in db/migrations/*.sql; do docker compose exec -T postgres psql -U asean_go -d asean_go < "$f"; done
docker compose exec -T postgres psql -U asean_go -d asean_go < db/seed.sql   # optional sample data
npm run dev                # http://localhost:4000
```

**Note:** Postgres is mapped to host port **5433**, not the default 5432 — this
machine already has a native Postgres instance bound to 5432, and the two would
otherwise silently collide (Node would connect to the wrong database).

## Modules

- `auth` — email register/login (JWT), OAuth endpoints are `501` placeholders until
  Google/Facebook credentials are added to `.env`.
- `users` — profile (`GET/PUT /users/me`), password change, XP/level, quest history,
  notification/privacy settings (JSONB columns on `users`).
- `pins` — Verified Pins: `GET /pins/nearby` (PostGIS `ST_DWithin`/`ST_Distance`),
  `GET/POST/PUT/DELETE /pins/:id` (edit/delete restricted to the original submitter),
  `POST /pins/:id/checkin` (awards XP, one per user per pin per day). Also the Scam
  Alert surface via `is_scam_alert` / `scam_alert_message`.
- `quests` — `GET /quests/daily` (with this user's per-quest status), `POST
  /quests/complete` (idempotent — completing twice is a no-op, awards XP/coins once).
- `coins` — `GET /coins/balance`, `POST /coins/purchase` (credits `users.coin_balance`
  from a fixed package list — **mock**, no real payment provider wired up, see the
  code comment on that route before using this beyond local dev), `POST
  /coins/spend` (generic debit against an item's price, no inventory grant — prefer
  `/inventory/purchase` for the normal buy flow), `GET /coins/transactions` (ledger).
- `store` — catalog CRUD for `store_items` (`outfit`/`avatar`/`booster`/`souvenir`,
  `common`/`rare`/`epic`/`legendary`). Write endpoints (`POST`/`PUT`/`DELETE`) are
  `requireAuth`-only — there is no admin-role system in this app yet, so any signed-in
  user can currently manage the catalog; replace with a real admin check before this
  is exposed beyond local/dev use.
- `inventory` — `GET /inventory` (owned items), `POST /inventory/purchase` (atomic:
  checks price/ownership/balance, then debits coins + grants the item + logs the
  transaction), `GET /inventory/check?itemId=`.

## Not yet implemented

Quests admin/approval, reviews endpoints, real payment provider integration
(Stripe/Omise/Google Play Billing — `/coins/purchase` is currently a mock that
credits coins without verifying any payment), push notifications (FCM), admin
dashboard/role system. See the project brief for the full MVP scope.
