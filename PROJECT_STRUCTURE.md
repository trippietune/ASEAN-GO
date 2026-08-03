# ASEAN GO — Project Structure & Database Reference

A gamified travel-safety and exploration app for the ASEAN region. Users discover and check in at verified places ("pins"), earn XP/coins/levels, complete quests, unlock achievements, write reviews, plan itineraries, and can trigger SOS alerts. Admins/moderators manage content and safety through a separate dashboard.

**Repo layout:** three independent projects in one repo —

| Project | Path | Stack |
|---|---|---|
| Backend API | `backend/` | Node.js, Express, TypeScript, PostgreSQL (PostGIS), Supabase-hosted |
| Admin Dashboard | `admin/` | React 19, TypeScript, Vite, Ant Design 6 |
| Mobile App | `mobile/` | Flutter, Riverpod, Dio |

**Live deployment** (see `DEPLOYMENT.md` for the full runbook):
- Backend: Railway — `https://aseango-backend-production.up.railway.app`
- Admin Dashboard: Vercel — `https://asean-go.vercel.app`
- Database: Supabase project `pcsupxayqqppzhfvandg` (Postgres + PostGIS, `ap-northeast-2`), accessed via the Transaction pooler (the direct host is IPv6-only and unreachable from Railway)

---

## Table of Contents

1. [Database Schema](#1-database-schema)
2. [Backend (Node/Express/TypeScript)](#2-backend-nodeexpresstypescript)
3. [Admin Dashboard (React/Vite)](#3-admin-dashboard-reactvite)
4. [Mobile App (Flutter)](#4-mobile-app-flutter)
5. [Cross-Cutting Conventions](#5-cross-cutting-conventions)

---

## 1. Database Schema

PostgreSQL with two extensions enabled: **PostGIS** (geography/location columns) and **uuid-ossp** (`uuid_generate_v4()` for every primary key). Schema is built from 21 sequential, hand-written SQL migration files in `backend/db/migrations/001_init.sql` … `021_achievements.sql` — there is no ORM; the backend talks to Postgres directly via the `pg` driver.

### 1.1 Entity relationship overview

```
users ──┬──< verified_pins (submitted_by, approved_by)
        ├──< quests (via pin_id, chapter_id)
        ├──< user_quests >── quests
        ├──< reviews >── verified_pins
        ├──< pin_checkins >── verified_pins
        ├──< inventory >── store_items
        ├──< coin_transactions
        ├──< sos_events
        ├──< risk_reports >── verified_pins
        ├──< payment_transactions
        ├──< media_assets
        ├──< password_reset_tokens
        ├──< user_favorite_pins >── verified_pins
        ├──< schedule_items >── verified_pins
        ├──< pin_suggestions (submitted_by, reviewed_by) >── verified_pins (resulting_pin_id)
        └──< user_achievements >── achievements

quest_chapters ──< quests (chapter_id)
               └──< achievements (criteria_chapter_id)

quests ──< quest_unlock_requirements >── quests (required_quest_id), verified_pins (required_pin_id)
```

### 1.2 Table dependency order

1. `users` — root, no FK dependencies
2. `verified_pins` — → `users`
3. `quests` — → `verified_pins`, later → `quest_chapters`
4. `user_quests` — → `users`, `quests`
5. `reviews` — → `verified_pins`, `users`
6. `pin_checkins` — → `users`, `verified_pins`
7. `store_items` — no FK
8. `inventory` — → `users`, `store_items`
9. `coin_transactions` — → `users`
10. `sos_events` — → `users`
11. `risk_reports` — → `verified_pins`, `users`
12. `payment_transactions` — → `users`
13. `media_assets` — → `users`
14. `password_reset_tokens` — → `users`
15. `user_favorite_pins` — → `users`, `verified_pins`
16. `schedule_items` — → `users`, `verified_pins`
17. `pin_suggestions` — → `users` (×2), `verified_pins`
18. `quest_chapters` — no FK (referenced by `quests`, `achievements`)
19. `quest_unlock_requirements` — → `quests` (×2), `verified_pins`
20. `achievements` — → `quest_chapters`
21. `user_achievements` — → `users`, `achievements`

### 1.3 Table reference

#### `users`
*Created `001_init.sql`. Altered by `003`, `006`, `007`, `012`, `017`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `email` | TEXT | NOT NULL | — | UNIQUE |
| `password_hash` | TEXT | NULL | — | null for OAuth-only accounts |
| `display_name` | TEXT | NOT NULL | — | |
| `auth_provider` | TEXT | NOT NULL | `'email'` | comment-only enum: email \| google \| facebook |
| `provider_id` | TEXT | NULL | — | |
| `avatar_url` | TEXT | NULL | — | |
| `home_country` | TEXT | NULL | — | |
| `xp` | INTEGER | NOT NULL | `0` | |
| `level` | INTEGER | NOT NULL | `1` | |
| `is_premium` | BOOLEAN | NOT NULL | `FALSE` | |
| `premium_until` | TIMESTAMPTZ | NULL | — | |
| `coin_balance` | INTEGER | NOT NULL | `0` | |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `notification_settings` | JSONB | NOT NULL | `{pushNotifications:true, emailNotifications:true, safetyAlerts:true, questReminders:true, promotions:false}` | added 003 |
| `privacy_settings` | JSONB | NOT NULL | `{showProfileToOthers:true, showCheckins:true, showReviews:true, allowDataCollection:true}` | added 003 |
| `emergency_contact_name` / `_phone` | TEXT | NULL | — | added 006 |
| `role` | TEXT | NOT NULL | `'user'` | added 007 — **real CHECK**: `IN ('user','admin','moderator')` |
| `username` | TEXT | NULL | — | added 012, nullable (no backfill needed) |
| `quests_completed_since_levelup` | INTEGER | NOT NULL | `0` | added 017 |

- **Unique:** `email`; `users_provider_idx` (unique on `auth_provider, provider_id` where `provider_id IS NOT NULL`); `users_username_unique_idx` (unique on `lower(username)` where not null — case-insensitive)
- **Index:** `users_role_idx` on `role` where `role != 'user'`
- **CHECK:** `role IN ('user','admin','moderator')`; `username` length 3–30; `username` format `^[a-zA-Z0-9_]+$`
- **Design note (012):** "Nullable so existing rows don't need backfilling; a user without a username can still log in with email."
- **Design note (017):** counter resets to 0 on any level-up (XP-crossing or skip) — "A lifetime counter would trigger once permanently after a user's 5th ever quest, which is a bug, not the intended mechanic."

#### `verified_pins`
*Created `001_init.sql`. Altered by `002`, `009`, `011`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `name` | TEXT | NOT NULL | — | |
| `category` | TEXT | NOT NULL | — | comment-only enum: food \| shop \| attraction \| transport \| lodging \| other |
| `description` | TEXT | NULL | — | |
| `country` | TEXT | NOT NULL | — | |
| `city` | TEXT | NULL | — | |
| `location` | GEOGRAPHY(POINT, 4326) | NOT NULL | — | PostGIS, GIST-indexed |
| `is_verified` | BOOLEAN | NOT NULL | `FALSE` | |
| `is_scam_alert` | BOOLEAN | NOT NULL | `FALSE` | |
| `scam_alert_message` | TEXT | NULL | — | |
| `submitted_by` | UUID | NULL | — | FK → `users(id)` ON DELETE SET NULL |
| `approved_by` | UUID | NULL | — | FK → `users(id)` ON DELETE SET NULL |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `safety_score` | SMALLINT | NOT NULL | `60` | added 002 — **real CHECK**: `BETWEEN 0 AND 100` |
| `photo_urls` | TEXT[] | NOT NULL | `'{}'` | added 009 |
| `is_checkpoint` | BOOLEAN | NOT NULL | `FALSE` | added 011 — curated meetup spot (blue map marker) |
| `is_recommended` | BOOLEAN | NOT NULL | `FALSE` | added 011 — admin "featured" flag (gold star marker) |

- **Index:** `verified_pins_location_idx` (GIST on `location`), `verified_pins_country_idx`, `verified_pins_checkpoint_idx` (partial, `is_checkpoint = TRUE`), `verified_pins_recommended_idx` (partial, `is_recommended = TRUE`)
- **CHECK:** `safety_score BETWEEN 0 AND 100`
- **Backfill (002):** `safety_score` set to 90 for verified/non-scam pins, 20 for scam-alert pins, on the migration that added the column

#### `quests`
*Created `001_init.sql`. Altered by `018`, `019`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `title` | TEXT | NOT NULL | — | |
| `description` | TEXT | NULL | — | |
| `quest_type` | TEXT | NOT NULL | `'daily'` | comment-only enum: daily \| location \| category \| level \| story (see [§2.6](#26-quest-system-design)) |
| `xp_reward` / `coin_reward` | INTEGER | NOT NULL | `0` | |
| `pin_id` | UUID | NULL | — | FK → `verified_pins(id)` ON DELETE SET NULL |
| `country` | TEXT | NULL | — | |
| `active_from` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `active_until` | TIMESTAMPTZ | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `category` | TEXT | NULL | — | added 018 — free text, for `category`-type quests |
| `chapter_id` | UUID | NULL | — | added 019, FK → `quest_chapters(id)` ON DELETE SET NULL |
| `chapter_order` | SMALLINT | NULL | — | added 019, position within its chapter |

- **No indexes** beyond PK
- **Schema evolution:** `quest_type` originally allowed `daily \| weekly \| recommended`, but only `daily` ever had a working route — migration 018 backfilled `weekly`/`recommended` rows to `daily` and expanded the taxonomy to 5 real types, centralized in `backend/src/modules/quests/quest-types.ts`
- **Design note (019):** deleting a chapter sets `chapter_id = NULL` rather than cascading — quests keep their completion history, just lose chapter grouping

#### `user_quests`
*Created `001_init.sql`. No later changes.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `quest_id` | UUID | NOT NULL | — | FK → `quests(id)` ON DELETE CASCADE |
| `status` | TEXT | NOT NULL | `'in_progress'` | comment-only enum: in_progress \| completed \| claimed |
| `completed_at` | TIMESTAMPTZ | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `(user_id, quest_id)`

#### `reviews`
*Created `001_init.sql`. Altered by `005`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `pin_id` | UUID | NOT NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `rating` | SMALLINT | NOT NULL | — | **real CHECK**: `BETWEEN 1 AND 5` |
| `comment` | TEXT | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `photo_urls` | TEXT[] | NOT NULL | `'{}'` | added 005 |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | added 005 |

- **Unique:** `reviews_pin_user_unique` on `(pin_id, user_id)` — one review per user per pin, editable via upsert
- **Index:** `reviews_pin_idx` on `pin_id`

#### `pin_checkins`
*Created `002_safety_score_and_checkins.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `pin_id` | UUID | NOT NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE |
| `xp_awarded` | INTEGER | NOT NULL | `0` | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `pin_checkins_user_idx`, `pin_checkins_pin_idx`
- One check-in per user per pin per calendar day is enforced at the application layer (`POST /pins/:id/checkin`), not by a DB constraint

#### `store_items`
*Created `004_store_and_inventory.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `name` | TEXT | NOT NULL | — | |
| `description` | TEXT | NULL | — | |
| `type` | TEXT | NOT NULL | — | comment-only enum: outfit \| avatar \| booster \| souvenir |
| `price` | INTEGER | NOT NULL | — | in coins — **real CHECK**: `>= 0` |
| `rarity` | TEXT | NOT NULL | `'common'` | comment-only enum: common \| rare \| epic \| legendary |
| `image_url` | TEXT | NOT NULL | — | |
| `is_active` | BOOLEAN | NOT NULL | `TRUE` | |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `store_items_type_idx`, `store_items_active_idx`

#### `inventory`
*Created `004_store_and_inventory.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `item_id` | UUID | NOT NULL | — | FK → `store_items(id)` ON DELETE CASCADE |
| `acquired_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `(user_id, item_id)` — ownership pattern reused later by `user_achievements`
- **Index:** `inventory_user_idx`

#### `coin_transactions`
*Created `004_store_and_inventory.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `amount` | INTEGER | NOT NULL | — | positive = credited, negative = spent |
| `type` | TEXT | NOT NULL | — | comment-only enum: purchase \| quest_reward \| checkin_reward \| spend \| bonus \| achievement_reward |
| `reference_id` | TEXT | NULL | — | questId, itemId, IAP package id, etc. |
| `metadata` | JSONB | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `coin_transactions_user_idx` on `(user_id, created_at DESC)`
- Append-only event log — contrast with `inventory`/`user_achievements`' "owned or not" unique-row pattern

#### `sos_events`
*Created `006_safety_system.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `location` | GEOGRAPHY(POINT, 4326) | NOT NULL | — | PostGIS, no spatial index |
| `status` | TEXT | NOT NULL | `'active'` | comment-only enum: active \| resolved |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `resolved_at` | TIMESTAMPTZ | NULL | — | |

- **Index:** `sos_events_user_idx` on `(user_id, created_at DESC)`
- **Design note:** "No real SMS/call dispatch happens yet — this is the real data path... that a provider integration would hook into later."

#### `risk_reports`
*Created `006_safety_system.sql`. Altered by `009`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `pin_id` | UUID | NOT NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE |
| `reported_by` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `severity` | TEXT | NOT NULL | `'caution'` | comment-only enum: caution \| warning \| danger |
| `description` | TEXT | NOT NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `photo_urls` | TEXT[] | NOT NULL | `'{}'` | added 009 |

- **Index:** `risk_reports_pin_idx` on `(pin_id, created_at DESC)`
- Additive alongside `verified_pins.is_scam_alert` — multiple users can each report the same pin; the admin-set flag remains the single authoritative badge. No unique constraint — repeat reports from the same user are allowed.

#### `payment_transactions`
*Created `008_payments.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `provider` | TEXT | NOT NULL | `'omise'` | |
| `provider_charge_id` | TEXT | NULL | — | UNIQUE |
| `package_id` | TEXT | NOT NULL | — | |
| `coins` | INTEGER | NOT NULL | — | |
| `amount_thb` | INTEGER | NOT NULL | — | in satang (smallest THB unit) |
| `currency` | TEXT | NOT NULL | `'thb'` | |
| `status` | TEXT | NOT NULL | `'pending'` | comment-only enum: pending \| successful \| failed \| refunded \| partially_refunded |
| `coins_credited` | BOOLEAN | NOT NULL | `FALSE` | |
| `failure_code` / `failure_message` | TEXT | NULL | — | |
| `refunded_amount_thb` | INTEGER | NOT NULL | `0` | |
| `metadata` | JSONB | NULL | — | |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `provider_charge_id`
- **Index:** `payment_transactions_user_idx` on `(user_id, created_at DESC)`, `payment_transactions_status_idx`

#### `media_assets`
*Created `009_media_uploads.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `uploaded_by` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `purpose` | TEXT | NOT NULL | — | comment-only enum: avatar \| review_photo \| pin_photo \| risk_report_photo |
| `provider` | TEXT | NOT NULL | `'cloudinary'` | |
| `public_id` | TEXT | NOT NULL | — | Cloudinary public_id, needed to call destroy() |
| `url` | TEXT | NOT NULL | — | |
| `width` / `height` / `bytes` | INTEGER | NULL | — | |
| `deleted_at` | TIMESTAMPTZ | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `media_assets_public_id_idx`
- **Index:** `media_assets_uploaded_by_idx` on `(uploaded_by, created_at DESC)`, `media_assets_url_idx`
- **Purpose:** tracks every uploaded image independent of whichever entity references its URL, so orphaned Cloudinary assets can be cleaned up on replace/delete

#### `password_reset_tokens`
*Created `010_password_reset.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `token_hash` | TEXT | NOT NULL | — | |
| `attempts` | INTEGER | NOT NULL | `0` | |
| `expires_at` | TIMESTAMPTZ | NOT NULL | — | |
| `used_at` | TIMESTAMPTZ | NULL | — | |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `password_reset_tokens_user_id_idx`

#### `user_favorite_pins`
*Created `013_favorite_pins.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `pin_id` | UUID | NOT NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `(user_id, pin_id)`
- **Index:** `user_favorite_pins_user_idx`, `user_favorite_pins_pin_idx`

#### `schedule_items`
*Created `014_schedule_items.sql`. Altered by `015` (rename + new column + CHECK).*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `pin_id` | UUID | NOT NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE |
| `scheduled_date` | DATE | NOT NULL | — | |
| `start_time` | TIME | NULL | — | renamed from `scheduled_time` in 015 |
| `note` | TEXT | NULL | — | |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |
| `end_time` | TIME | NULL | — | added 015 |

- **Unique:** `(user_id, pin_id, scheduled_date)`
- **Index:** `schedule_items_user_date_idx` on `(user_id, scheduled_date)`
- **CHECK:** `schedule_items_time_range_valid`: `start_time IS NULL OR end_time IS NULL OR end_time > start_time`
- **Schema evolution:** the only column RENAME in the entire migration history (`scheduled_time` → `start_time`), done to support itinerary time ranges like "10:00–12:00"

#### `pin_suggestions`
*Created `016_pin_suggestions.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `name` | TEXT | NOT NULL | — | |
| `category` | TEXT | NOT NULL | — | same domain as `verified_pins.category` |
| `description` | TEXT | NULL | — | |
| `country` | TEXT | NOT NULL | — | |
| `city` | TEXT | NULL | — | |
| `location` | GEOGRAPHY(POINT, 4326) | NOT NULL | — | PostGIS, no spatial index |
| `photo_urls` | TEXT[] | NOT NULL | `'{}'` | |
| `submitted_by` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `status` | TEXT | NOT NULL | `'pending'` | comment-only enum: pending \| approved \| rejected |
| `reviewed_by` | UUID | NULL | — | FK → `users(id)` ON DELETE SET NULL |
| `reviewed_at` | TIMESTAMPTZ | NULL | — | |
| `rejection_reason` | TEXT | NULL | — | |
| `resulting_pin_id` | UUID | NULL | — | FK → `verified_pins(id)` ON DELETE SET NULL |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `pin_suggestions_status_idx` on `(status, created_at DESC)`, `pin_suggestions_submitted_by_idx` on `(submitted_by, created_at DESC)`
- **Purpose:** replaces direct `POST /pins` for non-admin users now that pin creation is admin-only — a regular user's only path to adding a new place. Mirrors `risk_reports`' shape but adds a moderation workflow, since approval must produce a real `verified_pins` row.

#### `quest_chapters`
*Created `019_story_chapters.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `title` | TEXT | NOT NULL | — | |
| `description` | TEXT | NULL | — | |
| `order_index` | INTEGER | NOT NULL | — | required — "an unordered chapter is a modeling error" |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `quest_chapters_order_idx` on `order_index`
- Referenced by `quests.chapter_id` (ON DELETE SET NULL) and `achievements.criteria_chapter_id` (ON DELETE SET NULL)

#### `quest_unlock_requirements`
*Created `020_quest_unlock_requirements.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `quest_id` | UUID | NOT NULL | — | FK → `quests(id)` ON DELETE CASCADE |
| `requirement_type` | TEXT | NOT NULL | — | comment-only enum: level \| quest \| checkin \| category \| location |
| `min_level` | INTEGER | NULL | — | for `level` type |
| `required_quest_id` | UUID | NULL | — | FK → `quests(id)` ON DELETE CASCADE; for `quest` type |
| `required_pin_id` | UUID | NULL | — | FK → `verified_pins(id)` ON DELETE CASCADE; for `checkin` type |
| `category` | TEXT | NULL | — | for `category` type |
| `country` / `city` | TEXT | NULL | — | for `location` type |
| `count_threshold` | INTEGER | NULL | — | for `category`/`location` types |
| `source` | TEXT | NOT NULL | `'admin'` | comment-only enum: admin \| chapter_auto |
| `created_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Index:** `quest_unlock_requirements_quest_idx` on `quest_id`, `quest_unlock_requirements_required_quest_idx` on `required_quest_id` (partial, where not null)
- **Design note:** one relational table (not per-type tables, not JSONB) since a quest can have multiple AND-composed requirements and the evaluator needs to bulk-fetch a whole quest list's requirements in one query
- **Design note:** `source='chapter_auto'` rows are managed by the chapter-sequencing logic and are safe to relink/regenerate without touching `source='admin'` rows — see [§2.6](#26-quest-system-design)

#### `achievements`
*Created `021_achievements.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `title` | TEXT | NOT NULL | — | |
| `description` | TEXT | NULL | — | |
| `icon_url` | TEXT | NULL | — | |
| `criteria_type` | TEXT | NOT NULL | — | comment-only enum: quests_completed \| checkins \| level_reached \| category_visits \| chapter_completed \| manual |
| `criteria_category` | TEXT | NULL | — | for `category_visits` |
| `criteria_chapter_id` | UUID | NULL | — | FK → `quest_chapters(id)` ON DELETE SET NULL; for `chapter_completed` |
| `count_threshold` | INTEGER | NULL | — | |
| `xp_reward` / `coin_reward` | INTEGER | NOT NULL | `0` | |
| `is_active` | BOOLEAN | NOT NULL | `TRUE` | |
| `created_at` / `updated_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- `manual` criteria type is never auto-evaluated — only unlockable via the admin grant endpoint

#### `user_achievements`
*Created `021_achievements.sql`.*

| Column | Type | Null | Default | Notes |
|---|---|---|---|---|
| `id` | UUID | NOT NULL | `uuid_generate_v4()` | **PK** |
| `user_id` | UUID | NOT NULL | — | FK → `users(id)` ON DELETE CASCADE |
| `achievement_id` | UUID | NOT NULL | — | FK → `achievements(id)` ON DELETE CASCADE |
| `unlocked_at` | TIMESTAMPTZ | NOT NULL | `now()` | |

- **Unique:** `(user_id, achievement_id)`
- **Index:** `user_achievements_user_idx`
- Modeled on `inventory`'s unique-per-acquisition pattern (owned-or-not), not `coin_transactions`' event-log pattern

### 1.4 Cross-cutting schema conventions

**Comment-only enums are the norm; real CHECK constraints are the rare exception.** Across all 21 tables there are dozens of enum-like TEXT columns (`auth_provider`, `category`, `quest_type`, every `status` column, `severity`, `purpose`, `type`, `rarity`, `requirement_type`, `source`, `criteria_type`, …) documented only via an inline SQL comment listing valid values, with validation enforced entirely at the application layer (zod schemas in the backend). Only **six** real CHECK constraints exist in the whole schema:

| Constraint | Table | Rule |
|---|---|---|
| `role` enum | `users` | `IN ('user', 'admin', 'moderator')` — the one true enum-value CHECK |
| `rating` range | `reviews` | `BETWEEN 1 AND 5` |
| `safety_score` range | `verified_pins` | `BETWEEN 0 AND 100` |
| `price` range | `store_items` | `>= 0` |
| `username` length | `users` | `char_length BETWEEN 3 AND 30` |
| `username` format | `users` | regex `^[a-zA-Z0-9_]+$` |
| time range | `schedule_items` | `end_time > start_time` when both set |

Migrations 018, 020, and 021 each explicitly comment that they deliberately skip adding a CHECK for their new enum column, citing this established convention. **When extending the schema, follow the same pattern** — do not add a CHECK constraint to a new enum-like column unless it truly needs to be foolproof at the DB layer (as `role` is, being security-sensitive).

**JSONB is reserved for user-owned free-form settings**, not structured/queryable data. Only four JSONB columns exist: `users.notification_settings`, `users.privacy_settings` (both migration 003), and the loosely-typed `coin_transactions.metadata` / `payment_transactions.metadata` bags. Migration 020's design comment explicitly rejected JSONB for `quest_unlock_requirements` in favor of a real relational table, since that data is queried/joined against, not just stored per-user.

**PostGIS `GEOGRAPHY(POINT, 4326)`** is used on three tables: `verified_pins.location` (GIST-indexed for radius queries), `sos_events.location`, `pin_suggestions.location` (neither of the latter two has a spatial index, since they aren't queried by proximity).

**Design patterns reused across features** (explicitly cross-referenced in migration comments):
- **"Owned or not" (unique-per-row)**: `inventory` → later copied by `user_achievements`
- **"Append-only event log"**: `coin_transactions` (deliberately *not* the pattern used for achievements)
- **"Submission + moderation queue"**: `risk_reports` (no approval flow) → `pin_suggestions` (adds one, since approval must produce a real `verified_pins` row)

---

## 2. Backend (Node/Express/TypeScript)

`backend/src/` — package name `asean-go-backend`. No ORM; raw SQL via the `pg` driver (`backend/src/db/pool.ts`), one `Pool` instance shared app-wide.

### 2.1 Request pipeline (`backend/src/app.ts`)

In order:
1. `app.set("trust proxy", 1)` — trusts the first proxy hop (Railway) for correct `req.ip`
2. `helmet()` — security headers
3. `cors()` — allow-list based; requests with no `Origin` header (mobile/curl/server-to-server) always pass; browser origins checked against `env.corsAllowedOrigins`
4. `express.json()` — body parsing
5. `pinoHttp()` — request logging (skips `/health`, `/ready`)
6. `generalLimiter` — 300 req/15min baseline, applied globally
7. `GET /health`, `GET /ready` — liveness/readiness probes (defined directly on `app`, ahead of all routers)
8. Feature routers (below)
9. `errorHandler` — centralized error middleware, mounted last

### 2.2 Router mounts

| Base path | Extra middleware | Router file |
|---|---|---|
| `/auth` | `authLimiter` (10/15min) | `modules/auth/auth.routes.ts` |
| `/users` | — | `modules/users/users.routes.ts` |
| `/pins` | — | `modules/pins/pins.routes.ts` |
| `/quests` | — | `modules/quests/quests.routes.ts` |
| `/schedule` | — | `modules/schedule/schedule.routes.ts` |
| `/coins` | `paymentLimiter` (20/15min) | `modules/coins/coins.routes.ts` |
| `/store` | — | `modules/store/store.routes.ts` |
| `/inventory` | — | `modules/inventory/inventory.routes.ts` |
| *(root, self-scoped)* | — | `modules/reviews/reviews.routes.ts` — `/pins/:id/reviews`, `/reviews/user` |
| `/safety` | — | `modules/safety/safety.routes.ts` |
| *(root, self-scoped)* | — | `modules/risk-reports/risk-reports.routes.ts` — `/pins/:id/risk-reports` |
| *(root, self-scoped)* | — | `modules/pin-suggestions/pin-suggestions.routes.ts` — `/pin-suggestions...` |
| *(root, self-scoped)* | — | `modules/admin/admin.routes.ts` — all under `/admin/...`, applies its own `requireAuth, requireModerator` gate |
| *(root, self-scoped)* | — | `modules/payments/payments.routes.ts` — `/payments/omise/webhook`, `/admin/payment-transactions...` |
| *(root, self-scoped)* | — | `modules/media/media.routes.ts` — `/media/upload`, `/media/delete` |

### 2.3 Role tiers and auth middleware

Three roles: `user`, `moderator`, `admin` (stored in `users.role`, the one real CHECK-constrained enum in the schema).

- **`requireAuth`** (`middleware/auth.ts`) — verifies a Bearer JWT, sets `req.userId`. Proves identity only.
- **`optionalAuth`** (`middleware/optionalAuth.ts`) — same decode, never rejects; sets `req.userId` if a valid token is present, otherwise proceeds anonymously.
- **`requireAdmin` / `requireModerator`** (`middleware/adminAuth.ts`) — layered on top of `requireAuth`:

```ts
function requireRole(...allowedRoles: string[]) {
  return async (req, res, next) => {
    const result = await pool.query("SELECT role FROM users WHERE id = $1", [req.userId]);
    const role = result.rows[0]?.role;
    if (!role) throw new HttpError(401, "User not found");
    if (!allowedRoles.includes(role)) throw new HttpError(403, "...");
    req.userRole = role;
    next();
  };
}
export const requireAdmin = requireRole("admin");
export const requireModerator = requireRole("admin", "moderator");
```

**Key property:** role is looked up from the database on every request, never trusted from the JWT — a role change or ban takes effect immediately, no re-login required. `requireModerator` allows both `admin` and `moderator`; `requireAdmin` allows only `admin`.

### 2.4 Route inventory

Legend: 🔓 none · 🔑 requireAuth · 🔑👮 requireAuth+requireModerator · 🔑👑 requireAuth+requireAdmin · 🔑? optionalAuth

**`auth.routes.ts`** (`/auth`, rate-limited)

| Route | Auth | Description |
|---|---|---|
| POST `/auth/register` | 🔓 | Register with email/password/displayName/username |
| POST `/auth/login` | 🔓 | Log in with identifier (email/username) + password |
| POST `/auth/google` | 🔓 | Log in/register via Google ID token |
| POST `/auth/facebook` | 🔓 | Log in/register via Facebook access token |
| POST `/auth/forgot-password` | 🔓 | Request password-reset code by email (always same generic response) |
| POST `/auth/reset-password` | 🔓 | Reset password using emailed 6-digit code |

**`users.routes.ts`** (`/users`)

| Route | Auth | Description |
|---|---|---|
| GET `/users/me` | 🔑 | Current profile + `xpToNextLevel` |
| GET `/users/me/quests` | 🔑 | Caller's quest progress records |
| GET `/users/me/achievements` | 🔑 | All active achievements + this user's unlock status |
| PUT `/users/me` | 🔑 | Update display name / avatar URL |
| POST `/users/me/avatar` | 🔑 | Upload/replace avatar (multipart), deletes old one |
| PUT `/users/me/password` | 🔑 | Change password (requires current; rejects OAuth-only accounts) |
| GET/PUT `/users/me/notification-settings` | 🔑 | Notification preference flags |
| GET/PUT `/users/me/privacy-settings` | 🔑 | Privacy preference flags |

**`pins.routes.ts`** (`/pins`)

| Route | Auth | Description |
|---|---|---|
| GET `/pins/nearby` | 🔑? | Verified pins + active scam alerts within a radius, includes `is_favorited` if signed in |
| GET `/pins/nearby-risks` | 🔓 | Pins to warn about nearby (scam alert or ≥1 risk report) |
| POST `/pins` | 🔑👑 | Create a pin, immediately verified (creator = approver) |
| GET `/pins/favorites` | 🔑 | Caller's favorited pins |
| POST/DELETE `/pins/:id/favorite` | 🔑 | Favorite/unfavorite a pin (idempotent) |
| GET `/pins/:id` | 🔑? | Full pin detail |
| PUT `/pins/:id` | 🔑👑 | Update a pin's fields, cleans up removed photos |
| DELETE `/pins/:id` | 🔑👑 | Delete a pin and its photos |
| POST `/pins/:id/checkin` | 🔑 | Check in at a pin (once/day); awards XP, evaluates achievements |

**`pin-suggestions.routes.ts`**

| Route | Auth | Description |
|---|---|---|
| POST `/pin-suggestions` | 🔑 | Suggest a new place — a regular user's only path to adding one; sits pending |
| GET `/pin-suggestions/mine` | 🔑 | Caller's own suggestions |

**`reviews.routes.ts`**

| Route | Auth | Description |
|---|---|---|
| GET `/pins/:id/reviews` | 🔓 | All reviews for a pin, newest first |
| POST `/pins/:id/reviews` | 🔑 | Create/update (upsert) the caller's own review |
| DELETE `/pins/:id/reviews` | 🔑 | Delete the caller's own review |
| GET `/reviews/user` | 🔑 | Caller's own reviews across all pins |

**`quests.routes.ts`** (`/quests`)

| Route | Auth | Description |
|---|---|---|
| GET `/quests` | 🔑 | Active quests (optional `?type=`) with progress, `locked`, `unlockRequirements` |
| GET `/quests/daily` | 🔑 | Backward-compat alias for `?type=daily` |
| POST `/quests/complete` | 🔑 | Mark complete; awards XP/coins, level-skip check, evaluates achievements (idempotent) |

**`store.routes.ts`** (`/store`)

| Route | Auth | Description |
|---|---|---|
| GET `/store/items` | 🔓 | List active items, optional `?category=` |
| GET `/store/items/:id` | 🔓 | One item |
| POST/PUT/DELETE `/store/items/:id` | 🔑 | Manage catalog — **known gap:** no real role gate, any signed-in user can manage the store (flagged as a pre-launch TODO in source) |

**`inventory.routes.ts`** (`/inventory`)

| Route | Auth | Description |
|---|---|---|
| GET `/inventory` | 🔑 | Caller's owned items |
| POST `/inventory/purchase` | 🔑 | Buy with coins — atomic ownership/balance check + debit + grant |
| GET `/inventory/check` | 🔑 | Whether the caller already owns `?itemId=` |

**`coins.routes.ts`** (`/coins`, rate-limited)

| Route | Auth | Description |
|---|---|---|
| GET `/coins/balance` | 🔑 | Coin balance |
| POST `/coins/purchase` | 🔑 | Buy a coin package via Omise card token |
| POST `/coins/spend` | 🔑 | Generic coin debit against a store item's price |
| GET `/coins/transactions` | 🔑 | Last 100 ledger entries |

**`payments.routes.ts`**

| Route | Auth | Description |
|---|---|---|
| POST `/payments/omise/webhook` | 🔓* | Omise charge events; re-verified by re-fetching from Omise's API |
| GET `/admin/payment-transactions` | 🔑👑 | List, optional `?status=` |
| POST `/admin/payment-transactions/:id/refund` | 🔑👑 | Refund via Omise, claws back coins up to current balance |

**`safety.routes.ts`** (`/safety`)

| Route | Auth | Description |
|---|---|---|
| GET/PUT `/safety/emergency-contact` | 🔑 | Get/set emergency contact |
| POST `/safety/sos` | 🔑 | Create active SOS event; emits `sos:created` |
| POST `/safety/sos/:id/resolve` | 🔑 | Resolve own active SOS event; emits `sos:resolved` |
| GET `/safety/sos/active` | 🔑 | Caller's currently-active SOS event, if any |

**`risk-reports.routes.ts`**

| Route | Auth | Description |
|---|---|---|
| GET `/pins/:id/risk-reports` | 🔓 | All reports for a pin, newest first |
| POST `/pins/:id/risk-reports` | 🔑 | Submit a report (repeats from same user allowed) |

**`schedule.routes.ts`** (`/schedule`)

| Route | Auth | Description |
|---|---|---|
| GET `/schedule` | 🔑 | Caller's items, optional `?date=` |
| POST `/schedule` | 🔑 | Add a pin to schedule for a date/time |
| PUT/DELETE `/schedule/:id` | 🔑 + ownership | 403 if not the owner |

**`media.routes.ts`**

| Route | Auth | Description |
|---|---|---|
| POST `/media/upload` | 🔑 | Upload photo (`?purpose=review_photo\|pin_photo\|risk_report_photo`) to Cloudinary |
| POST `/media/delete` | 🔑 | Best-effort delete of a caller-owned asset by URL |

**`admin.routes.ts`** (all under `/admin`, router-level gate = `requireAuth + requireModerator`; routes marked 👑 add the stricter admin-only check)

*Stats:* GET `/admin/stats` 👮 — aggregate counts (users, pins, quests, reviews, active SOS, risk reports, scam alerts)

*Pins:* GET `/admin/pins` 👮 · POST `/admin/pins` 👑 · PUT `/admin/pins/:id` 👑 · DELETE `/admin/pins/:id` 👑

*Pin suggestions:* GET `/admin/pin-suggestions` 👮 · PUT `/admin/pin-suggestions/:id/approve` 👑 (creates a real verified pin, race-safe via row lock) · PUT `/admin/pin-suggestions/:id/reject` 👮

*Quests:* GET `/admin/quests` 👮 · POST `/admin/quests` 👮 (syncs implicit checkin requirement + chapter relink) · PUT `/admin/quests/:id` 👮 · DELETE `/admin/quests/:id` 👑 (relinks former chapter's sequencing)

*Quest unlock requirements:* GET `/admin/quests/:id/unlock-requirements` 👮 · POST `.../unlock-requirements` 👮 (tagged `source='admin'`) · DELETE `.../unlock-requirements/:requirementId` 👑

*Story chapters:* GET `/admin/quest-chapters` 👮 · POST `/admin/quest-chapters` 👮 · PUT `/admin/quest-chapters/:id` 👮 (relinks sequencing if order changed) · DELETE `/admin/quest-chapters/:id` 👑 (quests orphaned via `ON DELETE SET NULL`, cleans dangling auto-chain requirements)

*Achievements:* GET `/admin/achievements` 👮 · POST `/admin/achievements` 👮 · PUT `/admin/achievements/:id` 👮 · DELETE `/admin/achievements/:id` 👑 · POST `/admin/achievements/:id/grant` 👑 (manual grant, bypasses criteria)

*Users:* GET `/admin/users` 👮 · PUT `/admin/users/:id/role` 👑 (blocks self-demotion from admin)

*Reviews:* GET `/admin/reviews` 👮 · DELETE `/admin/reviews/:id` 👮

*Safety:* GET `/admin/risk-reports` 👮 · DELETE `/admin/risk-reports/:id` 👮 · GET `/admin/sos-events` 👮 (optional `?status=`) · POST `/admin/sos-events/:id/resolve` 👮

*Emergency contacts (read-only):* GET `/admin/emergency-contacts` 👮 — search users who have one set, for support/verification

### 2.5 Realtime (`backend/src/realtime/socket.ts`)

- `initSocketServer(httpServer)` — constructs a `socket.io` server, authenticates every connection via a handshake `auth.token` JWT (rejects if missing/invalid), joins the socket to room `user:<userId>`.
- `emitToUser(userId, event, payload)` — pushes to every open connection for that user; no-op if the user isn't connected or the socket server isn't running.
- **Events:** `sos:created` (on `POST /safety/sos`), `sos:resolved` (on resolve) — both originate only from `safety.routes.ts`. No location-tracking push channel exists; proximity checks are client-polled.

### 2.6 Quest system design

The quest system (migrations 018–021) is the most architecturally involved part of the backend. Five quest types share one `GET /quests` route (with `GET /quests/daily` kept as a thin backward-compatible alias):

- **daily** — auto-generated each day from random verified pins (`quests.service.ts::ensureDailyQuestsGenerated`, serialized via a Postgres advisory lock to avoid duplicate generation races)
- **location** — visit N pins in a country/city
- **category** — visit N pins in a category
- **level** — reach a minimum user level
- **story** — belongs to a `quest_chapters` chapter, unlocks sequentially

**Unlock evaluation** (`quests/unlock.service.ts`) is a pure, batch-oriented engine:
- `fetchUnlockContext()` — 3 queries total (not per-quest) to batch-load a user's level, completed quest IDs, and check-in/visit stats for a whole quest list
- `evaluateUnlockRequirements()` — pure function, AND-semantics across `level | quest | checkin | category | location` requirement rows
- `withImplicitPinRequirement()` — synthesizes a `checkin` requirement from a quest's own `pin_id` so a "visit this pin" quest is gated without needing an explicit `quest_unlock_requirements` row
- A quest's own objective (e.g. its own pin check-in) is tracked separately from genuine prerequisites — it contributes to whether the quest can be *completed*, but not to whether it displays as *locked* in the quest list (a pin-linked quest should render normally with a Complete button, not grayed out, until the user has actually tried it)

**Chapter sequencing** (`quests/chapters.service.ts`) is implemented as ordinary `quest`-type unlock requirements, not a separate mechanism: `relinkChapterRequirements()` deletes and reinserts only `source='chapter_auto'` rows to chain quest N+1 → requires quest N within a chapter, and chapter M's first quest → requires chapter M−1's last quest. This never touches `source='admin'` rows, so admin-added requirements survive a chapter reorder.

**Achievements** (`achievements/achievements.service.ts::evaluateAchievements`) run inside the same DB transaction as the triggering event (check-in or quest completion) — atomically checks all active, not-yet-earned, non-`manual` achievements against 5 criteria types (`quests_completed`, `checkins`, `level_reached`, `category_visits`, `chapter_completed`) and awards XP/coins via the shared `users/rewards.service.ts::creditXpAndCoins` helper.

### 2.7 Non-route module files

| File | Purpose |
|---|---|
| `quests/quests.service.ts` | Daily quest auto-generation with advisory-lock race protection |
| `quests/unlock.service.ts` | Quest-gating engine (batch fetch + pure evaluator) |
| `quests/chapters.service.ts` | Story chapter auto-chaining / relinking |
| `quests/quest-types.ts` | Single source of truth for the 5-value quest type enum |
| `achievements/achievements.service.ts` | Achievement criteria evaluation + atomic award |
| `users/rewards.service.ts` | Shared XP/coin-crediting + level-up detection helper |
| `users/xp.ts` | Pure leveling math (100 XP/level: `levelForXp`, `xpIntoCurrentLevel`, `xpToNextLevel`, `didLevelUp`) |
| `media/media.service.ts` | Cloudinary upload + ownership-checked/trusted asset deletion |
| `media/cloudinary.client.ts` | Lazy-configured Cloudinary SDK wrapper (1600×1600 cap, `f_auto/q_auto`) |
| `auth/mailer.client.ts` | Password-reset email via SMTP (logs instead of sending if unconfigured); never throws, to avoid leaking whether an email is registered |
| `payments/omise.client.ts` | Typed wrapper around the Omise payment SDK |
| `payments/coinPackages.ts` | The 4 purchasable coin packages (small/medium/large/xl) with THB pricing |

### 2.8 Environment configuration (`backend/src/config/env.ts`)

| Variable | Purpose |
|---|---|
| `NODE_ENV`, `PORT` | Runtime mode, listen port (default 4000) |
| `DATABASE_URL` | **Required** — Postgres connection string |
| `JWT_SECRET` | **Required in production** (dev/test falls back to a fixed value; boot fails if that fallback is used with `NODE_ENV=production`) |
| `JWT_EXPIRES_IN` | Token lifetime, default `7d` |
| `OMISE_PUBLIC_KEY`, `OMISE_SECRET_KEY` | Payment gateway credentials (optional) |
| `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` | Media upload credentials (optional) |
| `GOOGLE_CLIENT_ID` | Google OAuth (optional) |
| `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET` | Facebook OAuth (optional) |
| `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASSWORD`, `SMTP_FROM` | Outbound email (optional) |
| `CORS_ALLOWED_ORIGINS` | Comma-separated allow-list; defaults to the production admin dashboard URL if unset in production, or any `localhost:*` in dev/test |

---

## 3. Admin Dashboard (React/Vite)

`admin/src/` — React 19 + TypeScript + Vite, Ant Design 6 component library, `react-router-dom` v7, `axios` for HTTP. No dedicated state library — auth session lives in a React Context, page-level data fetching uses local `useState`/`useEffect`.

### 3.1 Pages (`admin/src/pages/`)

| Page | Purpose |
|---|---|
| `LoginPage.tsx` | Admin login (email/password), gated client-side to `admin`/`moderator` roles |
| `StatsPage.tsx` | Dashboard overview — user/pin/quest/review counts, active SOS/risk/scam alert stats |
| `PinsPage.tsx` | Pin CRUD — verify, flag scam alert, set safety score, create/delete (admin-only mutations) |
| `PinSuggestionsPage.tsx` | Review queue for user-submitted pin suggestions — approve/reject with reason |
| `QuestsPage.tsx` | Quest CRUD plus per-quest unlock-requirement management |
| `QuestChaptersPage.tsx` | Story chapter CRUD (title, description, order) |
| `AchievementsPage.tsx` | Achievement CRUD (criteria type, rewards, active flag) plus manual grant-to-user |
| `UsersPage.tsx` | User listing/search, role management |
| `ReviewsPage.tsx` | Review moderation (listing + delete) |
| `SafetyPage.tsx` | Risk report listing/deletion and SOS event listing/resolution |
| `EmergencyContactsPage.tsx` | Read-only listing/search of users' emergency contact info |
| `PaymentsPage.tsx` | Payment transaction listing, status filter, refund action |

### 3.2 Supporting structure

- **`admin/src/api/client.ts`** — shared `axios` instance; base URL from `VITE_API_BASE_URL`; request interceptor attaches `Authorization: Bearer`; response interceptor clears the token and calls a registered "unauthorized" handler on 401
- **`admin/src/api/admin.ts`** — one typed function per backend endpoint (login, stats, pins/quests/chapters/achievements/users/reviews/risk-reports/SOS/emergency-contacts/payments CRUD)
- **`admin/src/api/types.ts`** — TypeScript interfaces mirroring backend row shapes (`AdminUser`, `AdminPin`, `AdminQuest`, `AdminQuestChapter`, `AdminQuestUnlockRequirement`, `AdminAchievement`, etc.) and enums (`UserRole`, `PinCategory`, `QuestType`, `UnlockRequirementType`, `AchievementCriteriaType`, `PinSuggestionStatus`, `RiskSeverity`, `PaymentStatus`)
- **`admin/src/auth/AuthContext.tsx`** — holds the logged-in `AdminUser`; restores session from `localStorage` on mount; `login()` rejects non-admin/moderator roles client-side; registers itself as the API client's 401 handler
- **`admin/src/auth/RequireAuth.tsx`** — route guard: spinner while loading, redirect to `/login` (preserving origin path) if unauthenticated
- **`admin/src/layout/AdminLayout.tsx`** — collapsible-sidebar shell (Ant Design `Layout`); header shows role tag + user menu with logout

**Sidebar nav order:** Overview (`/`) → Pins → Pin Suggestions → Quests → Quest Chapters → Achievements → Users → Reviews → Safety Zones → Emergency Contacts → Payments

### 3.3 Key dependencies (`admin/package.json`)

| Package | Purpose |
|---|---|
| `antd` 6, `@ant-design/icons` | UI component library |
| `react-router-dom` 7 | Routing |
| `axios` | HTTP client |
| `dayjs` | Date handling |
| `vite`, `typescript`, `oxlint` | Build tooling, linting |

---

## 4. Mobile App (Flutter)

`mobile/lib/` — package `asean_go_mobile`. State management via **flutter_riverpod 2.6.1**; networking via **Dio**; realtime via **socket_io_client**.

### 4.1 Feature modules (`mobile/lib/features/`)

Each feature typically splits into `data/` (models + repositories calling the API) and `presentation/` (screens + Riverpod controllers).

**`auth/`** — `AppUser` model, login/register/social-login repository, `AuthController` (`StateNotifier<AuthState>`, sealed Initial/Loading/Authenticated/Unauthenticated states), login/signup/forgot-password/ToS screens, social login SDK wrappers (Google/Facebook), "remember me" email persistence.

**`home/`** — dashboard tab: XP/level summary, quick actions, quick nav to other tabs.

**`map/`** — `VerifiedPin`/`Review`/`PinSuggestion` models; repositories for nearby pins, favorites, check-in, reviews, pin suggestions; the main interactive `flutter_map` screen with markers/clustering, pin detail screen, favorites list, review composer/card/star-rating, submit-pin form.

**`profile/`** — `UserSettings` model + repository; profile screen (avatar, level/XP, stats), settings hub + sub-screens (theme, language, notifications, privacy, change password, about), inventory grid widget.

**`quests/`** — `Quest`/`QuestStatus`/`QuestUnlockRequirement` models; repository (fetch quests, complete quest); `QuestsController` (`AsyncNotifier<QuestsState>`) with type/chapter grouping; quest card widget (progress, reward, locked state) and quests-tab screen.

**`achievements/`** — `Achievement` model, repository, controller, and a grid/list screen showing unlocked + locked (grayed-out) badges.

**`safety/`** — `RiskPin`/`RiskReport` models; repository for risk pins/reports, SOS trigger/resolve, emergency contacts; emergency-contact form, proximity-alert banner + background-polling controller (started/stopped from `AppShell`), risk-report dialog/card, `SosController` (`AsyncNotifier<SosEvent?>`).

**`schedule/`** — `ScheduleItem` model + repository; itinerary tab with a date-picker strip, scheduled-entry cards, and a controller for the calendar/list state.

**`store/`** — `StoreItem`/`InventoryItem`/`ItemRarity` models; store + coins repositories; Omise card tokenization; card-entry form, coin-purchase dialog, item card/rarity badge, `StoreController` (`AsyncNotifier<StoreState>`) plus `storeCategoryProvider` and `coinBalanceProvider`.

### 4.2 Core infrastructure (`mobile/lib/core/`)

| Area | Files |
|---|---|
| **api** | `api_client.dart` — `Dio` wrapper: base-URL resolution (Android emulator vs. web/device), JWT attach interceptor, 401 handling, secure token storage. `providers.dart` — `apiClientProvider`. |
| **error** | `app_error_logger.dart` — in-memory sink for uncaught errors, wired via `runZonedGuarded`/`FlutterError.onError` |
| **localization** | `locale_controller.dart` — persists Thai/English/system language choice |
| **media** | `media_repository.dart` — uploads review/pin/risk-report photos |
| **realtime** | `socket_service.dart` — JWT-authenticated socket connection, auto-reconnect |
| **router** | `app_shell.dart` — bottom-tab shell (`IndexedStack` + `NavigationBar`) hosting Home/Map/Quests/Schedule/Profile; `app_tab_controller.dart` — `selectedTabProvider`; `splash_screen.dart` — shown while session restores |
| **theme** | `app_colors.dart` — palette (pastel-yellow background, pink primary, gold secondary, per-level-tier XP colors); `app_theme.dart` — `buildAppTheme()` builds light/dark `ThemeData` (Inter + Sarabun fonts); `app_typography.dart`; `theme_controller.dart` — persists Light/Dark/System choice |

**Navigation is manual, not `go_router`-based** — `go_router` is a declared dependency but unused. `MaterialApp` switches its `home` widget directly on `AuthState` (Splash → Login → `AppShell`); the 5 bottom tabs switch via a Riverpod `StateProvider<int>` inside an `IndexedStack`; secondary/detail screens use plain `Navigator.push(MaterialPageRoute(...))`.

### 4.3 Shared widgets (`mobile/lib/shared/widgets/`)

`animated_gradient_background.dart` (drifting pastel-yellow radial gradient, configurable colors/duration/opacity), `particles_background.dart` (floating decorative shapes, not yet wired into any screen), `wave_background.dart` (static sine-wave decoration, not yet wired in), `xp_bar.dart` (level-tier-colored progress bar), `xp_badge.dart`, `xp_gain_overlay.dart`, `level_badge.dart` (tier-gradient circular avatar), `level_up_animation.dart` (tier-gradient celebratory modal), `gradient_button.dart`, `empty_state_widget.dart`, `loading_shimmer.dart`, `app_logo.dart`, `organic_accent.dart`, `safety_indicator.dart`, `password_strength_indicator.dart`, `photo_picker_grid.dart`, `social_login_buttons.dart`, `settings_list_tile.dart`, `settings_section_header.dart`.

### 4.4 State management patterns (flutter_riverpod)

| Pattern | Example |
|---|---|
| Plain `Provider` (DI, no mutable state) | `apiClientProvider` |
| `StateProvider` (trivial mutable value) | `selectedTabProvider` |
| `StateNotifier` + `StateNotifierProvider` (sealed state, imperative mutation) | `AuthController`, `ThemeController`, `LocaleController` |
| `AsyncNotifier` + `AsyncNotifierProvider` (async-loaded state, built-in loading/error) | `QuestsController`, `StoreController`, `SosController`, `AchievementsController` |
| `FutureProvider.autoDispose` (one-shot async read) | `inventoryProvider`, `coinBalanceProvider` |

### 4.5 Localization

Thai and English, `flutter_localizations` + `intl`, generated via `flutter: generate: true`. Source files `mobile/lib/l10n/app_en.arb` (~332 keys) and `app_th.arb` (same key count; longer file due to `@key` description metadata blocks — English keys are bare, Thai keys carry a description). Generated delegate at `mobile/lib/l10n/generated/app_localizations.dart`.

### 4.6 Key dependencies (`mobile/pubspec.yaml`)

| Category | Packages |
|---|---|
| State management | `flutter_riverpod` |
| Navigation | `go_router` (declared, unused) |
| Networking | `dio`, `socket_io_client`, `connectivity_plus` |
| Maps/location | `flutter_map`, `latlong2`, `geolocator` |
| Auth | `google_sign_in`, `flutter_facebook_auth` |
| Storage | `flutter_secure_storage` (JWT), `shared_preferences` (theme/locale/misc) |
| UI/fonts | `google_fonts` (Inter + Sarabun), `cupertino_icons` |
| Media | `image_picker` |
| Localization | `flutter_localizations`, `intl` |

---

## 5. Cross-Cutting Conventions

These conventions recur across all three projects and should be followed when extending the codebase:

1. **No CHECK constraints for enum-like DB columns** — validate at the application layer (zod on the backend); see [§1.4](#14-cross-cutting-schema-conventions).
2. **One place per taxonomy** — e.g. `backend/src/modules/quests/quest-types.ts` is the single source for the 5 quest types, imported everywhere instead of duplicating a literal union across zod schemas (the exact bug that orphaned the old `weekly`/`recommended` quest types).
3. **Role checks always re-query the DB**, never trust the JWT for authorization — see [§2.3](#23-role-tiers-and-auth-middleware).
4. **`source` columns distinguish admin-authored from system-generated rows** (`quest_unlock_requirements.source`) so automation can safely regenerate its own rows without clobbering manual edits.
5. **Orphan, don't cascade, for grouping relationships** — deleting a `quest_chapters` row sets `quests.chapter_id = NULL` rather than deleting the quests; deleting a pin's category doesn't apply (no such relation) but the same philosophy applies wherever "grouping" is distinct from "ownership."
6. **Idempotent mutation endpoints** where a repeat action is plausible client-side — quest completion, check-ins, favoriting — return the current state rather than erroring on a duplicate call.
7. **Money is stored in the smallest currency unit** (`payment_transactions.amount_thb` is in satang, matching Omise's own convention) to avoid floating-point rounding.
8. **Mobile UI shows locked/unearned content grayed-out, never hidden** — applies to locked quests and locked achievements, giving users a reason to progress rather than surprising them with content appearing from nowhere.
