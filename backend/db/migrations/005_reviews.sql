-- One review per user per pin (editable via upsert), plus photo URLs.
-- Photos are stored as URLs only — no upload endpoint exists in this backend
-- yet, matching how avatar_url/store item images already work.
ALTER TABLE reviews
  ADD COLUMN photo_urls TEXT[] NOT NULL DEFAULT '{}',
  ADD COLUMN updated_at TIMESTAMPTZ NOT NULL DEFAULT now();

ALTER TABLE reviews
  ADD CONSTRAINT reviews_pin_user_unique UNIQUE (pin_id, user_id);
