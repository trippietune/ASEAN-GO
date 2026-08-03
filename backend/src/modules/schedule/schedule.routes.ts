import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";

export const scheduleRouter = Router();

const SELECT_SCHEDULE_ITEM = `
  s.id, s.pin_id, s.scheduled_date, s.start_time, s.end_time, s.note,
  p.name AS pin_name, p.category AS pin_category, p.city AS pin_city, p.country AS pin_country,
  ST_Y(p.location::geometry) AS pin_lat, ST_X(p.location::geometry) AS pin_lng
`;

// GET /schedule?date=YYYY-MM-DD — this user's schedule items, optionally
// filtered to one date, ordered by date then time.
const listQuerySchema = z.object({
  date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
});

scheduleRouter.get("/", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { date } = listQuerySchema.parse(req.query);
    const result = await pool.query(
      `SELECT ${SELECT_SCHEDULE_ITEM}
       FROM schedule_items s
       JOIN verified_pins p ON p.id = s.pin_id
       WHERE s.user_id = $1 AND ($2::date IS NULL OR s.scheduled_date = $2)
       ORDER BY s.scheduled_date ASC, s.start_time ASC NULLS LAST`,
      [req.userId, date ?? null]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const timeSchema = z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/);

const createSchema = z
  .object({
    pinId: z.string().uuid(),
    scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/),
    startTime: timeSchema.optional(),
    endTime: timeSchema.optional(),
    note: z.string().max(500).optional(),
  })
  .refine((body) => !body.endTime || !body.startTime || body.endTime > body.startTime, {
    message: "endTime must be after startTime",
    path: ["endTime"],
  });

// POST /schedule — add a pin to this user's schedule for a given date.
scheduleRouter.post("/", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = createSchema.parse(req.body);

    const pin = await pool.query("SELECT id FROM verified_pins WHERE id = $1", [body.pinId]);
    if (!pin.rowCount) throw new HttpError(404, "Pin not found");

    let result;
    try {
      result = await pool.query(
        `INSERT INTO schedule_items (user_id, pin_id, scheduled_date, start_time, end_time, note)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id`,
        [req.userId, body.pinId, body.scheduledDate, body.startTime ?? null, body.endTime ?? null, body.note ?? null]
      );
    } catch (err) {
      if ((err as { code?: string }).code === "23505") {
        throw new HttpError(409, "This place is already scheduled for that date");
      }
      throw err;
    }

    const created = await pool.query(
      `SELECT ${SELECT_SCHEDULE_ITEM} FROM schedule_items s JOIN verified_pins p ON p.id = s.pin_id WHERE s.id = $1`,
      [result.rows[0].id]
    );
    res.status(201).json(created.rows[0]);
  } catch (err) {
    next(err);
  }
});

const updateSchema = z.object({
  scheduledDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  startTime: timeSchema.nullable().optional(),
  endTime: timeSchema.nullable().optional(),
  note: z.string().max(500).nullable().optional(),
});

// PUT /schedule/:id — owner-only partial update.
scheduleRouter.put("/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const itemId = z.string().uuid().parse(req.params.id);
    const body = updateSchema.parse(req.body);

    const existing = await pool.query("SELECT user_id FROM schedule_items WHERE id = $1", [itemId]);
    if (!existing.rowCount) throw new HttpError(404, "Schedule item not found");
    if (existing.rows[0].user_id !== req.userId) {
      throw new HttpError(403, "You can only edit your own schedule items");
    }

    let result;
    try {
      result = await pool.query(
        `UPDATE schedule_items
         SET scheduled_date = COALESCE($2, scheduled_date),
             start_time = CASE WHEN $3 THEN $4 ELSE start_time END,
             end_time = CASE WHEN $5 THEN $6 ELSE end_time END,
             note = CASE WHEN $7 THEN $8 ELSE note END,
             updated_at = now()
         WHERE id = $1
         RETURNING id`,
        [
          itemId,
          body.scheduledDate ?? null,
          "startTime" in body,
          body.startTime ?? null,
          "endTime" in body,
          body.endTime ?? null,
          "note" in body,
          body.note ?? null,
        ]
      );
    } catch (err) {
      if ((err as { code?: string }).code === "23505") {
        throw new HttpError(409, "This place is already scheduled for that date");
      }
      // Postgres check-constraint violation (end_time <= start_time after this partial update).
      if ((err as { code?: string }).code === "23514") {
        throw new HttpError(400, "endTime must be after startTime");
      }
      throw err;
    }

    const updated = await pool.query(
      `SELECT ${SELECT_SCHEDULE_ITEM} FROM schedule_items s JOIN verified_pins p ON p.id = s.pin_id WHERE s.id = $1`,
      [result.rows[0].id]
    );
    res.json(updated.rows[0]);
  } catch (err) {
    next(err);
  }
});

// DELETE /schedule/:id — owner-only.
scheduleRouter.delete("/:id", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const itemId = z.string().uuid().parse(req.params.id);

    const existing = await pool.query("SELECT user_id FROM schedule_items WHERE id = $1", [itemId]);
    if (!existing.rowCount) throw new HttpError(404, "Schedule item not found");
    if (existing.rows[0].user_id !== req.userId) {
      throw new HttpError(403, "You can only delete your own schedule items");
    }

    await pool.query("DELETE FROM schedule_items WHERE id = $1", [itemId]);
    res.status(204).send();
  } catch (err) {
    next(err);
  }
});
