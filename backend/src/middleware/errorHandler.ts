import { NextFunction, Request, Response } from "express";
import { ZodError } from "zod";
import { logger } from "../config/logger";

export class HttpError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export function errorHandler(err: unknown, req: Request, res: Response, _next: NextFunction) {
  if (err instanceof ZodError) {
    return res.status(400).json({ error: "Validation failed", details: err.flatten() });
  }
  if (err instanceof HttpError) {
    // Client errors (4xx) are routine — logging them at 'warn' keeps 'error'
    // reserved for genuinely unexpected failures worth paging on.
    if (err.status >= 500) {
      logger.error({ err, path: req.path }, err.message);
    } else {
      logger.warn({ path: req.path, status: err.status }, err.message);
    }
    return res.status(err.status).json({ error: err.message });
  }
  logger.error({ err, path: req.path }, "Unhandled error");
  return res.status(500).json({ error: "Internal server error" });
}
