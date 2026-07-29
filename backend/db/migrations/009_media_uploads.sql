-- Tracks every image uploaded through our backend to Cloudinary, independent
-- of whichever entity (user avatar, review, pin, risk report) ends up
-- referencing its URL. This is what makes "delete when no longer used"
-- possible: without a public_id record we'd have no way to clean up
-- Cloudinary after a photo is replaced or its owning record is deleted.
CREATE TABLE media_assets (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  uploaded_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose TEXT NOT NULL, -- 'avatar' | 'review_photo' | 'pin_photo' | 'risk_report_photo'
  provider TEXT NOT NULL DEFAULT 'cloudinary',
  public_id TEXT NOT NULL, -- Cloudinary public_id, needed to call destroy()
  url TEXT NOT NULL,
  width INTEGER,
  height INTEGER,
  bytes INTEGER,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX media_assets_public_id_idx ON media_assets (public_id);
CREATE INDEX media_assets_uploaded_by_idx ON media_assets (uploaded_by, created_at DESC);
CREATE INDEX media_assets_url_idx ON media_assets (url);

-- Pins and risk reports had no photo support at all before this — reviews
-- and user avatars already had a photo_urls/avatar_url column (previously
-- populated with client-pasted URLs; now populated via real uploads).
ALTER TABLE verified_pins ADD COLUMN photo_urls TEXT[] NOT NULL DEFAULT '{}';
ALTER TABLE risk_reports ADD COLUMN photo_urls TEXT[] NOT NULL DEFAULT '{}';
