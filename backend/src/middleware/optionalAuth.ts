import { NextFunction, Response } from "express";
import jwt from "jsonwebtoken";
import { env } from "../config/env";
import { AuthedRequest } from "./auth";

/// Decodes the JWT if one is present, but never rejects the request — routes
/// using this need to know *who's asking* to compute a per-user flag (e.g.
/// is_favorited), while still being fully viewable by anonymous callers.
export function optionalAuth(req: AuthedRequest, _res: Response, next: NextFunction) {
  const header = req.headers.authorization;
  if (!header?.startsWith("Bearer ")) return next();

  try {
    const payload = jwt.verify(header.slice("Bearer ".length), env.jwtSecret) as { sub: string };
    req.userId = payload.sub;
  } catch {
    // Invalid/expired token on an optional-auth route: degrade to anonymous.
  }
  next();
}
