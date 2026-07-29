import { Router } from "express";
import { z } from "zod";
import { loginWithEmail, registerWithEmail, signToken } from "./auth.service";
import { HttpError } from "../../middleware/errorHandler";

export const authRouter = Router();

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  displayName: z.string().min(1).max(80),
});

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(1),
});

authRouter.post("/register", async (req, res, next) => {
  try {
    const { email, password, displayName } = registerSchema.parse(req.body);
    const user = await registerWithEmail(email, password, displayName);
    const token = signToken(user.id);
    res.status(201).json({ token, user });
  } catch (err) {
    next(err);
  }
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const { email, password } = loginSchema.parse(req.body);
    const user = await loginWithEmail(email, password);
    const token = signToken(user.id);
    res.json({ token, user });
  } catch (err) {
    next(err);
  }
});

// Placeholder endpoints until real OAuth credentials are configured (see .env.example).
authRouter.post("/google", (_req, res, next) => {
  next(new HttpError(501, "Google sign-in is not configured yet"));
});

authRouter.post("/facebook", (_req, res, next) => {
  next(new HttpError(501, "Facebook sign-in is not configured yet"));
});
