-- Emergency contact: one per user, set from Profile/Settings.
ALTER TABLE users
  ADD COLUMN emergency_contact_name TEXT,
  ADD COLUMN emergency_contact_phone TEXT;

-- SOS events: created when the user presses the emergency button. No real
-- SMS/call dispatch happens yet — this is the real data path (live location,
-- active/resolved state) that a provider integration would hook into later.
CREATE TABLE sos_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  status TEXT NOT NULL DEFAULT 'active', -- 'active' | 'resolved'
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  resolved_at TIMESTAMPTZ
);

CREATE INDEX sos_events_user_idx ON sos_events (user_id, created_at DESC);

-- User-submitted risk reports: additive alongside the existing admin-set
-- is_scam_alert/scam_alert_message on verified_pins. Multiple users can each
-- report the same pin; the admin flag remains the single authoritative badge.
CREATE TABLE risk_reports (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pin_id UUID NOT NULL REFERENCES verified_pins(id) ON DELETE CASCADE,
  reported_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  severity TEXT NOT NULL DEFAULT 'caution', -- 'caution' | 'warning' | 'danger'
  description TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX risk_reports_pin_idx ON risk_reports (pin_id, created_at DESC);
