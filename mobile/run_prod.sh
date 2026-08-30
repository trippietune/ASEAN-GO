#!/usr/bin/env bash
# Runs the app against the production backend with Google Sign-In's web
# client ID passed in — google_sign_in v7 reads this via --dart-define
# instead of a google-services.json file (no Firebase project needed).
#
# NOTE: backend runs on Render's free plan (moved off Railway — trial
# expired, no free tier there anymore). Render's free plan sleeps the
# service after 15min idle; the first request after that can take 30-50s to
# wake it back up, so don't be alarmed by a slow first login attempt.
# api.aseango.com's DNS still needs pointing at Render (was misconfigured
# toward GoDaddy/Afternic domain parking since before the Railway era) —
# switch back to https://api.aseango.com once that's fixed.
#
# Usage: ./run_prod.sh [extra flutter run args, e.g. -d chrome]

set -euo pipefail
cd "$(dirname "$0")"

flutter run \
  --dart-define=API_BASE_URL=https://asean-go.onrender.com \
  --dart-define=GOOGLE_WEB_CLIENT_ID=83522479812-bmc4huf5ck6vglkjq4avv6jnkb3e2cfj.apps.googleusercontent.com \
  "$@"
