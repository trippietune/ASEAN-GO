ALTER TABLE verified_pins
  ADD COLUMN safety_score SMALLINT NOT NULL DEFAULT 60 CHECK (safety_score BETWEEN 0 AND 100);

-- Backfill a sane score from the existing flags so old rows aren't all default-60.
UPDATE verified_pins SET safety_score = 90 WHERE is_verified AND NOT is_scam_alert;
UPDATE verified_pins SET safety_score = 20 WHERE is_scam_alert;

CREATE TABLE pin_checkins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pin_id UUID NOT NULL REFERENCES verified_pins(id) ON DELETE CASCADE,
  xp_awarded INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX pin_checkins_user_idx ON pin_checkins (user_id);
CREATE INDEX pin_checkins_pin_idx ON pin_checkins (pin_id);
