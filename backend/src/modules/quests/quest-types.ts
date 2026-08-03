// The one place the quest_type taxonomy is defined. Previously this list was
// duplicated across zod schemas in admin.routes.ts — that duplication is
// exactly how 'weekly'/'recommended' ended up as valid values with no route
// that ever surfaced them to a client. Anything that needs to validate or
// enumerate quest types should import from here.
export const QUEST_TYPES = ["daily", "location", "category", "level", "story"] as const;
export type QuestType = (typeof QUEST_TYPES)[number];
