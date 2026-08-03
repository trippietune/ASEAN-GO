-- Expands the quest_type taxonomy from daily/weekly/recommended (only
-- 'daily' ever had a working GET route — weekly/recommended quests were
-- permanently unreachable by any client) to daily/location/category/level/
-- story. The taxonomy itself now lives in one place in code
-- (backend/src/modules/quests/quest-types.ts) instead of being duplicated
-- across zod schemas, so adding a 6th type later can't silently orphan
-- quests the way weekly/recommended did.
--
-- No CHECK constraint added here — matches this column's existing
-- comment-only-enum convention; enforcement is at the application layer.
UPDATE quests SET quest_type = 'daily' WHERE quest_type IN ('weekly', 'recommended');

-- For Category-type quests ("visit N pins in this category"). Free text,
-- matching verified_pins.category's existing convention (also comment-only,
-- no CHECK/FK).
ALTER TABLE quests ADD COLUMN category TEXT;
