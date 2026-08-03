-- Adds a username as an alternate login identifier alongside email. Nullable
-- so existing rows don't need backfilling; a user without a username can
-- still log in with email. Uniqueness is enforced case-insensitively via a
-- functional unique index (matching how login looks it up), since two
-- usernames differing only in case would otherwise be ambiguous at login.
ALTER TABLE users ADD COLUMN username TEXT;

ALTER TABLE users ADD CONSTRAINT users_username_length
  CHECK (username IS NULL OR (char_length(username) BETWEEN 3 AND 30));

ALTER TABLE users ADD CONSTRAINT users_username_format
  CHECK (username IS NULL OR username ~ '^[a-zA-Z0-9_]+$');

CREATE UNIQUE INDEX users_username_unique_idx ON users (lower(username)) WHERE username IS NOT NULL;
