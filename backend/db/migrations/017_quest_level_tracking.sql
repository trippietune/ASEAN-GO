-- Tracks quests completed since the user's last level-up (via XP crossing a
-- level boundary) or level-skip event. Resets to 0 whenever users.level
-- increases for any reason. Used to gate the level-skip mechanic: crossing
-- 5/7/10 completed-since-reset quests makes the user eligible to skip extra
-- levels on their next quest completion, provided they're also far enough
-- into their current level's XP bar (see quests.routes.ts). A lifetime
-- counter would trigger once permanently after a user's 5th ever quest,
-- which is a bug, not the intended mechanic — hence the reset semantics.
ALTER TABLE users
  ADD COLUMN quests_completed_since_levelup INTEGER NOT NULL DEFAULT 0;
