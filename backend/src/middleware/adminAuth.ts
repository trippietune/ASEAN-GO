import { NextFunction, Response } from "express";
import { pool } from "../db/pool";
import { AuthedRequest } from "./auth";
import { HttpError } from "./errorHandler";

export interface AdminRequest extends AuthedRequest {
  userRole?: string;
}

/// Looks up the caller's current role from the DB on every request (not the
/// JWT) so a role change or ban takes effect immediately, without waiting for
/// the user's token to expire or forcing a re-login.
function requireRole(...allowedRoles: string[]) {
  return async (req: AdminRequest, res: Response, next: NextFunction) => {
    try {
      const result = await pool.query("SELECT role FROM users WHERE id = $1", [req.userId]);
      const role = result.rows[0]?.role as string | undefined;
      if (!role) throw new HttpError(401, "User not found");
      if (!allowedRoles.includes(role)) {
        throw new HttpError(403, "You do not have permission to perform this action");
      }
      req.userRole = role;
      next();
    } catch (err) {
      next(err);
    }
  };
}

export const requireAdmin = requireRole("admin");
export const requireModerator = requireRole("admin", "moderator");
