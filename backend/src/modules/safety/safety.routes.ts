import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";
import { emitToUser } from "../../realtime/socket";

export const safetyRouter = Router();

// GET /safety/emergency-contact
safetyRouter.get("/emergency-contact", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      "SELECT emergency_contact_name, emergency_contact_phone FROM users WHERE id = $1",
      [req.userId]
    );
    if (!result.rowCount) throw new HttpError(404, "User not found");
    res.json({
      name: result.rows[0].emergency_contact_name,
      phone: result.rows[0].emergency_contact_phone,
    });
  } catch (err) {
    next(err);
  }
});

const emergencyContactSchema = z.object({
  name: z.string().min(1).max(120),
  phone: z.string().min(5).max(30),
});

// PUT /safety/emergency-contact
safetyRouter.put("/emergency-contact", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const body = emergencyContactSchema.parse(req.body);
    const result = await pool.query(
      `UPDATE users SET emergency_contact_name = $2, emergency_contact_phone = $3, updated_at = now()
       WHERE id = $1
       RETURNING emergency_contact_name, emergency_contact_phone`,
      [req.userId, body.name, body.phone]
    );
    res.json({
      name: result.rows[0].emergency_contact_name,
      phone: result.rows[0].emergency_contact_phone,
    });
  } catch (err) {
    next(err);
  }
});

const createSosSchema = z.object({
  lat: z.number().min(-90).max(90),
  lng: z.number().min(-180).max(180),
});

// POST /sos — creates an active SOS event with the user's live location and
// emits a real-time event over the user's own socket room (so, e.g., a
// second device signed into the same account sees it immediately). No real
// SMS/call dispatch happens here yet — see the note in the migration.
safetyRouter.post("/sos", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const { lat, lng } = createSosSchema.parse(req.body);

    const contact = await pool.query(
      "SELECT emergency_contact_name, emergency_contact_phone, display_name FROM users WHERE id = $1",
      [req.userId]
    );
    if (!contact.rowCount) throw new HttpError(404, "User not found");

    const result = await pool.query(
      `INSERT INTO sos_events (user_id, location)
       VALUES ($1, ST_MakePoint($3, $2)::geography)
       RETURNING id, status, created_at`,
      [req.userId, lat, lng]
    );

    const event = result.rows[0];
    const payload = {
      id: event.id,
      userId: req.userId,
      userDisplayName: contact.rows[0].display_name,
      lat,
      lng,
      createdAt: event.created_at,
    };

    emitToUser(req.userId!, "sos:created", payload);

    res.status(201).json({
      id: event.id,
      status: event.status,
      createdAt: event.created_at,
      hasEmergencyContact: Boolean(contact.rows[0].emergency_contact_phone),
    });
  } catch (err) {
    next(err);
  }
});

// POST /sos/:id/resolve — mark an SOS event as resolved (e.g. user is safe now).
safetyRouter.post("/sos/:id/resolve", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const eventId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `UPDATE sos_events SET status = 'resolved', resolved_at = now()
       WHERE id = $1 AND user_id = $2 AND status = 'active'
       RETURNING id, status, resolved_at`,
      [eventId, req.userId]
    );
    if (!result.rowCount) throw new HttpError(404, "SOS event not found or already resolved");

    emitToUser(req.userId!, "sos:resolved", { id: eventId });

    res.json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});

// GET /sos/active — the user's currently-active SOS event, if any (so the UI
// can restore "SOS is active" state after an app restart).
safetyRouter.get("/sos/active", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const result = await pool.query(
      `SELECT id, status, created_at FROM sos_events
       WHERE user_id = $1 AND status = 'active'
       ORDER BY created_at DESC LIMIT 1`,
      [req.userId]
    );
    res.json(result.rows[0] ?? null);
  } catch (err) {
    next(err);
  }
});
