-- Marks a pin as a curated meetup/checkpoint spot on the map (blue marker).
-- Check-in itself already existed (POST /pins/:id/checkin, pin_checkins
-- table) — this flag only controls whether the map highlights the pin as
-- one worth visiting, not a new reward mechanic.
ALTER TABLE verified_pins ADD COLUMN is_checkpoint BOOLEAN NOT NULL DEFAULT FALSE;

-- Admin-curated "featured" flag (gold star marker on the map).
ALTER TABLE verified_pins ADD COLUMN is_recommended BOOLEAN NOT NULL DEFAULT FALSE;

CREATE INDEX verified_pins_checkpoint_idx ON verified_pins (is_checkpoint) WHERE is_checkpoint = TRUE;
CREATE INDEX verified_pins_recommended_idx ON verified_pins (is_recommended) WHERE is_recommended = TRUE;
