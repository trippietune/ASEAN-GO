-- User-submitted pin suggestions: replaces direct POST /pins for non-admin
-- users now that pin creation is admin-only. Mirrors risk_reports' shape
-- (submitted content pointing at a place) but adds a moderation workflow —
-- risk_reports has no status/approval path, this table does, because
-- approving a suggestion must produce a real verified_pins row.
CREATE TABLE pin_suggestions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  category TEXT NOT NULL, -- 'food' | 'shop' | 'attraction' | 'transport' | 'lodging' | 'other' (same domain as verified_pins.category)
  description TEXT,
  country TEXT NOT NULL,
  city TEXT,
  location GEOGRAPHY(POINT, 4326) NOT NULL,
  photo_urls TEXT[] NOT NULL DEFAULT '{}',
  submitted_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'pending', -- 'pending' | 'approved' | 'rejected'
  reviewed_by UUID REFERENCES users(id) ON DELETE SET NULL,
  reviewed_at TIMESTAMPTZ,
  rejection_reason TEXT,
  resulting_pin_id UUID REFERENCES verified_pins(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX pin_suggestions_status_idx ON pin_suggestions (status, created_at DESC);
CREATE INDEX pin_suggestions_submitted_by_idx ON pin_suggestions (submitted_by, created_at DESC);
