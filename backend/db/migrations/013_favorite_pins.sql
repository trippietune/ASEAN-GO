CREATE TABLE user_favorite_pins (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pin_id UUID NOT NULL REFERENCES verified_pins(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, pin_id)
);

CREATE INDEX user_favorite_pins_user_idx ON user_favorite_pins (user_id);
CREATE INDEX user_favorite_pins_pin_idx ON user_favorite_pins (pin_id);
