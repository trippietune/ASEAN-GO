import { Pool, PoolClient } from "pg";

export interface UnlockRequirementRow {
  id: string;
  quest_id: string;
  requirement_type: string;
  min_level: number | null;
  required_quest_id: string | null;
  required_pin_id: string | null;
  category: string | null;
  country: string | null;
  city: string | null;
  count_threshold: number | null;
  isOwnObjective?: boolean;
}

export interface UnlockRequirementResult {
  type: string;
  description: string;
  satisfied: boolean;
  // True for the implicit checkin requirement synthesized from a quest's own
  // pin_id (see withImplicitPinRequirement) — that's the quest's objective,
  // not a prerequisite gating access to it, so it must never contribute to
  // `locked` in GET /quests (a "Visit this pin" quest should render as a
  // normal, tappable card, not a grayed-out locked one). It still gates
  // actual completion server-side via POST /quests/complete, which checks
  // every requirement regardless of this flag.
  isOwnObjective: boolean;
}

interface VisitStats {
  categoryCounts: Map<string, number>;
  locationCounts: Map<string, number>;
  // Most recent check-in timestamp per pin — a `checkin` requirement is
  // satisfied by a check-in at or after the *requiring* quest's own
  // active_from, so the dispatcher needs the timestamp, not just presence.
  checkinTimesByPin: Map<string, Date>;
}

// Batch-fetches everything the dispatcher needs to evaluate unlock
// requirements for a whole list of quests in three queries total, not
// per-quest — GET /quests can list 20+ quests in one response.
export async function fetchUnlockContext(
  db: Pool | PoolClient,
  userId: string,
  questIds: string[]
): Promise<{
  requirementsByQuest: Map<string, UnlockRequirementRow[]>;
  userLevel: number;
  completedQuestIds: Set<string>;
  visitStats: VisitStats;
}> {
  const requirementsByQuest = new Map<string, UnlockRequirementRow[]>();
  if (questIds.length > 0) {
    const requirements = await db.query<UnlockRequirementRow>(
      `SELECT id, quest_id, requirement_type, min_level, required_quest_id, required_pin_id,
              category, country, city, count_threshold
       FROM quest_unlock_requirements
       WHERE quest_id = ANY($1)`,
      [questIds]
    );
    for (const row of requirements.rows) {
      const list = requirementsByQuest.get(row.quest_id) ?? [];
      list.push(row);
      requirementsByQuest.set(row.quest_id, list);
    }
  }

  const userResult = await db.query<{ level: number }>(`SELECT level FROM users WHERE id = $1`, [userId]);
  const userLevel = userResult.rows[0]?.level ?? 1;

  const completed = await db.query<{ quest_id: string }>(
    `SELECT quest_id FROM user_quests WHERE user_id = $1 AND status = 'completed'`,
    [userId]
  );
  const completedQuestIds = new Set(completed.rows.map((r) => r.quest_id));

  // Per-pin most-recent check-in, plus one row per distinct (pin) for the
  // category/location counts below — category/location thresholds count
  // distinct pins visited, not total check-ins.
  const visits = await db.query<{
    category: string;
    country: string;
    city: string | null;
    pin_id: string;
    last_checkin_at: Date;
  }>(
    `SELECT vp.category, vp.country, vp.city, vp.id AS pin_id, MAX(pc.created_at) AS last_checkin_at
     FROM pin_checkins pc
     JOIN verified_pins vp ON vp.id = pc.pin_id
     WHERE pc.user_id = $1
     GROUP BY vp.id, vp.category, vp.country, vp.city`,
    [userId]
  );

  const categoryCounts = new Map<string, number>();
  const locationCounts = new Map<string, number>();
  const checkinTimesByPin = new Map<string, Date>();
  for (const row of visits.rows) {
    checkinTimesByPin.set(row.pin_id, row.last_checkin_at);
    categoryCounts.set(row.category, (categoryCounts.get(row.category) ?? 0) + 1);
    const countryKey = `country:${row.country}`;
    locationCounts.set(countryKey, (locationCounts.get(countryKey) ?? 0) + 1);
    if (row.city) {
      const cityKey = `city:${row.country}:${row.city}`;
      locationCounts.set(cityKey, (locationCounts.get(cityKey) ?? 0) + 1);
    }
  }

  return { requirementsByQuest, userLevel, completedQuestIds, visitStats: { categoryCounts, locationCounts, checkinTimesByPin } };
}

function describeRequirement(row: UnlockRequirementRow): string {
  switch (row.requirement_type) {
    case "level":
      return `Reach level ${row.min_level}`;
    case "quest":
      return `Complete the required quest first`;
    case "checkin":
      return `Check in at the required pin`;
    case "category":
      return `Visit ${row.count_threshold} ${row.category} pins`;
    case "location":
      return row.city ? `Visit ${row.count_threshold} pins in ${row.city}` : `Visit ${row.count_threshold} pins in ${row.country}`;
    default:
      return "Unmet requirement";
  }
}

// Pure — no DB access. AND semantics: a quest with multiple requirement rows
// needs every one satisfied. A quest with zero rows is unconditionally
// unlocked, matching today's behavior for every existing quest.
//
// `questActiveFrom` scopes the `checkin` case: a check-in only counts if it
// happened at or after the *requiring* quest's own active_from, preserving
// the original pin-linked-quest behavior (a stale check-in from before the
// quest went live doesn't retroactively satisfy it).
export function evaluateUnlockRequirements(
  requirements: UnlockRequirementRow[],
  context: {
    userLevel: number;
    completedQuestIds: Set<string>;
    visitStats: VisitStats;
    questActiveFrom?: Date;
  }
): { locked: boolean; allSatisfied: boolean; unlockRequirements: UnlockRequirementResult[] } {
  const results = requirements.map((row): UnlockRequirementResult => {
    let satisfied: boolean;
    switch (row.requirement_type) {
      case "level":
        satisfied = context.userLevel >= (row.min_level ?? 0);
        break;
      case "quest":
        satisfied = row.required_quest_id ? context.completedQuestIds.has(row.required_quest_id) : true;
        break;
      case "checkin": {
        if (!row.required_pin_id) {
          satisfied = true;
          break;
        }
        const checkinAt = context.visitStats.checkinTimesByPin.get(row.required_pin_id);
        satisfied = !!checkinAt && (!context.questActiveFrom || checkinAt >= context.questActiveFrom);
        break;
      }
      case "category": {
        const count = row.category ? context.visitStats.categoryCounts.get(row.category) ?? 0 : 0;
        satisfied = count >= (row.count_threshold ?? 0);
        break;
      }
      case "location": {
        const key = row.city ? `city:${row.country}:${row.city}` : `country:${row.country}`;
        const count = context.visitStats.locationCounts.get(key) ?? 0;
        satisfied = count >= (row.count_threshold ?? 0);
        break;
      }
      default:
        satisfied = true;
    }
    return {
      type: row.requirement_type,
      description: describeRequirement(row),
      satisfied,
      isOwnObjective: row.isOwnObjective ?? false,
    };
  });

  // `locked` (display/gating for GET /quests): only prerequisites — not the
  // quest's own objective — can lock a quest. See the isOwnObjective doc
  // comment on UnlockRequirementResult.
  // `allSatisfied` (completion gate for POST /quests/complete): every
  // requirement must hold, including the quest's own objective — you can't
  // complete a "check in here" quest without actually checking in.
  const locked = results.some((r) => !r.satisfied && !r.isOwnObjective);
  const allSatisfied = results.every((r) => r.satisfied);
  return { locked, allSatisfied, unlockRequirements: results };
}

// A quest's own pin_id is the source of truth for "this quest needs a
// check-in at this pin" — the admin route also mirrors it into an explicit
// quest_unlock_requirements row (so it shows up alongside other requirements
// in the admin UI), but gating here doesn't depend on that mirror having run
// (e.g. quests inserted directly, migrations, tests). If an explicit
// 'checkin' row already exists for this pin, it isn't duplicated.
export function withImplicitPinRequirement(
  requirements: UnlockRequirementRow[],
  questId: string,
  pinId: string | null
): UnlockRequirementRow[] {
  if (!pinId) return requirements;
  const alreadyPresent = requirements.some((r) => r.requirement_type === "checkin" && r.required_pin_id === pinId);
  if (alreadyPresent) return requirements;
  return [
    ...requirements,
    {
      id: "implicit",
      quest_id: questId,
      requirement_type: "checkin",
      min_level: null,
      required_quest_id: null,
      required_pin_id: pinId,
      category: null,
      country: null,
      city: null,
      count_threshold: null,
      isOwnObjective: true,
    },
  ];
}

// Convenience wrapper for a single quest (used by POST /quests/complete's
// server-side gate) — fetches context scoped to just that one quest.
export async function isQuestUnlocked(
  db: Pool | PoolClient,
  userId: string,
  questId: string,
  questActiveFrom: Date,
  pinId: string | null
): Promise<boolean> {
  const { requirementsByQuest, userLevel, completedQuestIds, visitStats } = await fetchUnlockContext(db, userId, [questId]);
  const requirements = withImplicitPinRequirement(requirementsByQuest.get(questId) ?? [], questId, pinId);
  // allSatisfied, not `locked` — completion needs every requirement met,
  // including the quest's own objective (e.g. its own checkin), which
  // `locked` deliberately excludes (see UnlockRequirementResult.isOwnObjective).
  const { allSatisfied } = evaluateUnlockRequirements(requirements, {
    userLevel,
    completedQuestIds,
    visitStats,
    questActiveFrom,
  });
  return allSatisfied;
}
