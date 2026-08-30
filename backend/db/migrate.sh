#!/usr/bin/env bash
# Applies any db/migrations/*.sql file not yet recorded in schema_migrations,
# in filename order, each inside its own transaction.
#
# This project's migrations are hand-written raw SQL (not node-pg-migrate's
# timestamp-prefixed format), most without IF NOT EXISTS guards — re-running
# an already-applied one would error against a live database. Tracking which
# ones ran, rather than looping over every file unconditionally, is what
# makes this safe to run on every deploy.
#
# Usage: DATABASE_URL=postgresql://... ./db/migrate.sh
set -euo pipefail
cd "$(dirname "$0")/.."

if [ -z "${DATABASE_URL:-}" ]; then
  echo "DATABASE_URL is not set" >&2
  exit 1
fi

psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c "
  CREATE TABLE IF NOT EXISTS schema_migrations (
    filename TEXT PRIMARY KEY,
    applied_at TIMESTAMPTZ NOT NULL DEFAULT now()
  );
"

applied_any=0
for file in db/migrations/*.sql; do
  name=$(basename "$file")
  already_applied=$(psql "$DATABASE_URL" -tA -c \
    "SELECT 1 FROM schema_migrations WHERE filename = '$name'")
  if [ "$already_applied" = "1" ]; then
    continue
  fi

  echo "Applying $name..."
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$file"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -c \
    "INSERT INTO schema_migrations (filename) VALUES ('$name')"
  applied_any=1
done

if [ "$applied_any" = "0" ]; then
  echo "No pending migrations."
fi
