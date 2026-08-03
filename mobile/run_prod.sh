#!/usr/bin/env bash
# Runs the app against the production backend with Google Sign-In's web
# client ID passed in — google_sign_in v7 reads this via --dart-define
# instead of a google-services.json file (no Firebase project needed).
#
# NOTE: api.aseango.com's DNS is currently misconfigured (still pointing at
# GoDaddy/Afternic domain parking, not Railway) — TLS handshake fails until
# that's fixed. Using the Railway-issued subdomain directly in the meantime;
# switch API_BASE_URL back to https://api.aseango.com once DNS is corrected.
#
# Usage: ./run_prod.sh [extra flutter run args, e.g. -d chrome]

set -euo pipefail
cd "$(dirname "$0")"

flutter run \
  --dart-define=API_BASE_URL=https://aseango-backend-production.up.railway.app \
  --dart-define=GOOGLE_WEB_CLIENT_ID=83522479812-bmc4huf5ck6vglkjq4avv6jnkb3e2cfj.apps.googleusercontent.com \
  "$@"
