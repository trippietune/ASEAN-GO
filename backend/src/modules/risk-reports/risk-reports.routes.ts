import { Router } from "express";
import { z } from "zod";
import { pool } from "../../db/pool";
import { requireAuth, AuthedRequest } from "../../middleware/auth";
import { HttpError } from "../../middleware/errorHandler";

export const riskReportsRouter = Router();

// GET /pins/:id/risk-reports — all community reports for a pin, newest first.
riskReportsRouter.get("/pins/:id/risk-reports", async (req, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const result = await pool.query(
      `SELECT r.id, r.pin_id, r.reported_by, u.display_name AS reporter_display_name,
              r.severity, r.description, r.photo_urls, r.created_at
       FROM risk_reports r
       JOIN users u ON u.id = r.reported_by
       WHERE r.pin_id = $1
       ORDER BY r.created_at DESC`,
      [pinId]
    );
    res.json(result.rows);
  } catch (err) {
    next(err);
  }
});

const createReportSchema = z.object({
  severity: z.enum(["caution", "warning", "danger"]),
  description: z.string().min(1).max(1000),
  photoUrls: z.array(z.string().url()).max(6).optional(),
});

// POST /pins/:id/risk-reports — any signed-in user may report a pin as risky;
// unlike reviews this is not one-per-user (a returning traveler may want to
// confirm a still-ongoing risk), so no upsert/uniqueness constraint.
riskReportsRouter.post("/pins/:id/risk-reports", requireAuth, async (req: AuthedRequest, res, next) => {
  try {
    const pinId = z.string().uuid().parse(req.params.id);
    const body = createReportSchema.parse(req.body);

    const pin = await pool.query("SELECT id FROM verified_pins WHERE id = $1", [pinId]);
    if (!pin.rowCount) throw new HttpError(404, "Pin not found");

    const result = await pool.query(
      `INSERT INTO risk_reports (pin_id, reported_by, severity, description, photo_urls)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, pin_id, reported_by, severity, description, photo_urls, created_at`,
      [pinId, req.userId, body.severity, body.description, body.photoUrls ?? []]
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    next(err);
  }
});
