-- Achievements are a separate special-accomplishment system from quests:
-- most auto-unlock via criteria evaluated after quest completion, checkins,
-- or reviews; a 'manual' criteria_type exists for admin-only achievements
-- that are never auto-evaluated, only granted via the admin override.
--
-- No CHECK constraint on criteria_type — matches this schema's existing
-- comment-only-enum convention; enforcement is at the application layer
-- (backend/src/modules/achievements/achievements.service.ts).
CREATE TABLE achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  criteria_type TEXT NOT NULL, -- 'quests_completed' | 'checkins' | 'level_reached' | 'category_visits' | 'chapter_completed' | 'manual'
  criteria_category TEXT,
  criteria_chapter_id UUID REFERENCES quest_chapters(id) ON DELETE SET NULL,
  count_threshold INTEGER,
  xp_reward INTEGER NOT NULL DEFAULT 0,
  coin_reward INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Modeled on inventory's unique-per-acquisition pattern (owned-or-not state),
-- not coin_transactions' append-only event log — an achievement is a boolean
-- unlock, not a repeatable event.
CREATE TABLE user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
  unlocked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, achievement_id)
);

CREATE INDEX user_achievements_user_idx ON user_achievements (user_id);
