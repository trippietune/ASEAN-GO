-- Firebase Cloud Messaging device tokens, one row per device+app install.
--
-- UNIQUE on token alone (not (user_id, token)): a token belongs to a
-- device+app install, not an account. On a shared/reset device, a second
-- user logging in should re-point the existing row via upsert rather than
-- create a second row that would keep pushing to the first user's device.
--
-- No CHECK constraint on platform — matches this schema's existing
-- comment-only-enum convention; enforcement is at the application layer.
CREATE TABLE user_fcm_tokens (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL, -- 'android' | 'ios'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (token)
);

CREATE INDEX user_fcm_tokens_user_idx ON user_fcm_tokens (user_id);
