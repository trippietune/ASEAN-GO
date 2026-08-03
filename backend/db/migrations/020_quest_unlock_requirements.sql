-- One relational table (not per-type tables, not JSONB): a quest can have
-- multiple requirements (AND-composed), and the unlock evaluator needs to
-- bulk-fetch all requirements for a whole quest list in one query. This is
-- queryable, joined-against game logic, not user-owned free-form settings
-- (unlike notification_settings/privacy_settings, the only existing JSONB
-- precedent in this schema).
--
-- No CHECK constraint on requirement_type — matches this column's existing
-- comment-only-enum convention; enforcement is at the application layer
-- (backend/src/modules/quests/unlock.service.ts).
CREATE TABLE quest_unlock_requirements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  quest_id UUID NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
  requirement_type TEXT NOT NULL, -- 'level' | 'quest' | 'checkin' | 'category' | 'location'
  min_level INTEGER,
  required_quest_id UUID REFERENCES quests(id) ON DELETE CASCADE,
  required_pin_id UUID REFERENCES verified_pins(id) ON DELETE CASCADE,
  category TEXT,
  country TEXT,
  city TEXT,
  count_threshold INTEGER,
  -- 'admin' | 'chapter_auto' — distinguishes manually-added rows from the
  -- chapter auto-chaining logic (chapters.service.ts, Phase 3), so relinking
  -- a chapter's sequencing never clobbers admin-added requirements.
  source TEXT NOT NULL DEFAULT 'admin',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX quest_unlock_requirements_quest_idx ON quest_unlock_requirements (quest_id);
CREATE INDEX quest_unlock_requirements_required_quest_idx ON quest_unlock_requirements (required_quest_id) WHERE required_quest_id IS NOT NULL;
