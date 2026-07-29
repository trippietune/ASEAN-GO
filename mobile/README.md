# ASEAN GO Mobile

Flutter app (Riverpod state management, `flutter_map`/OpenStreetMap tiles — no API
key required yet).

## Setup

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:4000   # Android emulator
# iOS simulator / desktop: override to http://localhost:4000 instead.
```

The backend must be running first (see `../backend/README.md`).

## Structure

- `lib/core` — API client (Dio + secure-storage token), theme, app shell/bottom nav.
- `lib/features/auth` — login/register, session restore.
- `lib/features/map` — Verified Pins map (scam alerts render as red markers).
- `lib/features/quests` — user's assigned quests.
- `lib/features/profile` — XP/level/coin display.

## Not yet implemented

Gamification screens beyond quests (inventory, outfits, boosters, leaderboard),
Store/IAP, reviews UI, QR check-in, push notifications, offline map caching,
multi-language support. See the project brief for the full MVP scope.
