-- Story-type quests belong to chapters, which unlock sequentially. A
-- chapter's ordering is required (not nullable) because an unordered
-- chapter is a modeling error for this feature, not a valid state.
CREATE TABLE quest_chapters (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX quest_chapters_order_idx ON quest_chapters (order_index);

-- ON DELETE SET NULL: deleting a chapter orphans its quests (they keep
-- their completion history, they just lose chapter grouping/gating) rather
-- than blocking deletion or cascading the quests away.
ALTER TABLE quests ADD COLUMN chapter_id UUID REFERENCES quest_chapters(id) ON DELETE SET NULL;
-- Position within its chapter; only meaningful when chapter_id IS NOT NULL.
-- A quest belongs to at most one chapter, so this lives directly on
-- quests rather than needing a join table.
ALTER TABLE quests ADD COLUMN chapter_order SMALLINT;
