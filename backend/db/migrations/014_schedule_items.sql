CREATE TABLE schedule_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  pin_id UUID NOT NULL REFERENCES verified_pins(id) ON DELETE CASCADE,
  scheduled_date DATE NOT NULL,
  scheduled_time TIME,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, pin_id, scheduled_date)
);

CREATE INDEX schedule_items_user_date_idx ON schedule_items (user_id, scheduled_date);
