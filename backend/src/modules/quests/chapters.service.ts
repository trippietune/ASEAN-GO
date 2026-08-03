import { pool } from "../../db/pool";

// Chapter-to-chapter and within-chapter gating is just another instance of
// the generic 'quest'-type unlock requirement (see unlock.service.ts) — no
// bespoke "is this chapter complete" mechanism. This function recomputes a
// single chapter's auto-chained requirements:
//   - chapter N's first quest (chapter_order = 1) requires the immediately
//     preceding chapter's last quest (by order_index), if one exists.
//   - quest K (K > 1) within the chapter requires quest K-1 in the same
//     chapter (decision: strict sequential within a chapter).
// Only source='chapter_auto' rows are touched (delete-then-reinsert) — the
// source column exists precisely so this never clobbers admin-added rows.
export async function relinkChapterRequirements(chapterId: string): Promise<void> {
  const chapterResult = await pool.query<{ id: string; order_index: number }>(
    `SELECT id, order_index FROM quest_chapters WHERE id = $1`,
    [chapterId]
  );
  const chapter = chapterResult.rows[0];
  if (!chapter) return;

  const questsResult = await pool.query<{ id: string; chapter_order: number }>(
    `SELECT id, chapter_order FROM quests WHERE chapter_id = $1 ORDER BY chapter_order ASC`,
    [chapterId]
  );
  const quests = questsResult.rows;
  const questIds = quests.map((q) => q.id);

  // Clear this chapter's own auto-chained rows before recomputing. Also
  // clear any auto-chained row on the *next* chapter's first quest that
  // points at one of this chapter's quests — reordering/removing this
  // chapter's last quest can otherwise leave the next chapter gated on a
  // quest that's no longer the last one.
  if (questIds.length > 0) {
    await pool.query(
      `DELETE FROM quest_unlock_requirements WHERE quest_id = ANY($1) AND source = 'chapter_auto'`,
      [questIds]
    );
  }
  await pool.query(
    `DELETE FROM quest_unlock_requirements
     WHERE source = 'chapter_auto' AND requirement_type = 'quest'
       AND required_quest_id = ANY($1)
       AND quest_id NOT IN (SELECT unnest($1::uuid[]))`,
    [questIds.length > 0 ? questIds : ["00000000-0000-0000-0000-000000000000"]]
  );

  if (quests.length === 0) return;

  // Within-chapter sequential chaining: quest K requires quest K-1.
  for (let i = 1; i < quests.length; i++) {
    await pool.query(
      `INSERT INTO quest_unlock_requirements (quest_id, requirement_type, required_quest_id, source)
       VALUES ($1, 'quest', $2, 'chapter_auto')`,
      [quests[i].id, quests[i - 1].id]
    );
  }

  // Cross-chapter chaining: this chapter's first quest requires the
  // previous chapter's (by order_index) last quest, if any.
  const previousChapter = await pool.query<{ id: string }>(
    `SELECT id FROM quest_chapters WHERE order_index < $1 ORDER BY order_index DESC LIMIT 1`,
    [chapter.order_index]
  );
  if (previousChapter.rowCount) {
    const previousLastQuest = await pool.query<{ id: string }>(
      `SELECT id FROM quests WHERE chapter_id = $1 ORDER BY chapter_order DESC LIMIT 1`,
      [previousChapter.rows[0].id]
    );
    if (previousLastQuest.rowCount) {
      await pool.query(
        `INSERT INTO quest_unlock_requirements (quest_id, requirement_type, required_quest_id, source)
         VALUES ($1, 'quest', $2, 'chapter_auto')`,
        [quests[0].id, previousLastQuest.rows[0].id]
      );
    }
  }

  // Re-chain the *next* chapter (if any) since this chapter's last quest may
  // have changed (a new quest appended, one removed, or reordered).
  const nextChapter = await pool.query<{ id: string }>(
    `SELECT id FROM quest_chapters WHERE order_index > $1 ORDER BY order_index ASC LIMIT 1`,
    [chapter.order_index]
  );
  if (nextChapter.rowCount) {
    await relinkNextChapterOnly(nextChapter.rows[0].id, quests[quests.length - 1].id);
  }
}

// Re-points the next chapter's first quest at this chapter's (new) last
// quest, without recursing into relinkChapterRequirements (which would
// re-walk further chapters unnecessarily — only the immediate link changes).
async function relinkNextChapterOnly(nextChapterId: string, newPreviousLastQuestId: string): Promise<void> {
  const firstQuest = await pool.query<{ id: string }>(
    `SELECT id FROM quests WHERE chapter_id = $1 ORDER BY chapter_order ASC LIMIT 1`,
    [nextChapterId]
  );
  if (!firstQuest.rowCount) return;

  await pool.query(
    `DELETE FROM quest_unlock_requirements
     WHERE quest_id = $1 AND source = 'chapter_auto' AND requirement_type = 'quest'`,
    [firstQuest.rows[0].id]
  );
  await pool.query(
    `INSERT INTO quest_unlock_requirements (quest_id, requirement_type, required_quest_id, source)
     VALUES ($1, 'quest', $2, 'chapter_auto')`,
    [firstQuest.rows[0].id, newPreviousLastQuestId]
  );
}

// Called when a chapter is deleted — quests.chapter_id is already set to
// NULL by the FK's ON DELETE SET NULL, but their chapter_auto requirement
// rows would otherwise dangle (pointing at a quest whose chapter grouping
// no longer exists). Also re-chains the chapter that followed the deleted
// one, since its cross-chapter gate now points at the wrong predecessor.
export async function cleanupDanglingChapterRequirements(orphanedQuestIds: string[]): Promise<void> {
  if (orphanedQuestIds.length === 0) return;
  await pool.query(
    `DELETE FROM quest_unlock_requirements
     WHERE source = 'chapter_auto'
       AND (quest_id = ANY($1) OR required_quest_id = ANY($1))`,
    [orphanedQuestIds]
  );
}
