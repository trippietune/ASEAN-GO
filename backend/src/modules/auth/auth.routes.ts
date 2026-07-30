import { Router } from "express";
import { z } from "zod";
import {
  loginWithEmail,
  loginWithFacebook,
  loginWithGoogle,
  registerWithEmail,
  requestPasswordReset,
  resetPassword,
  signToken,
} from "./auth.service";

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

const googleAuthSchema = z.object({ idToken: z.string().min(1) });
const facebookAuthSchema = z.object({ accessToken: z.string().min(1) });

authRouter.post("/google", async (req, res, next) => {
  try {
    const { idToken } = googleAuthSchema.parse(req.body);
    const user = await loginWithGoogle(idToken);
    const token = signToken(user.id);
    res.json({ token, user });
  } catch (err) {
    next(err);
  }
});

authRouter.post("/facebook", async (req, res, next) => {
  try {
    const { accessToken } = facebookAuthSchema.parse(req.body);
    const user = await loginWithFacebook(accessToken);
    const token = signToken(user.id);
    res.json({ token, user });
  } catch (err) {
    next(err);
  }
});

const forgotPasswordSchema = z.object({ email: z.string().email() });
const resetPasswordSchema = z.object({
  email: z.string().email(),
  code: z.string().length(6),
  password: z.string().min(8),
});

authRouter.post("/forgot-password", async (req, res, next) => {
  try {
    const { email } = forgotPasswordSchema.parse(req.body);
    await requestPasswordReset(email);
    // Same response whether or not the email is registered — see
    // requestPasswordReset's doc comment for why.
    res.json({ message: "If that email is registered, a reset code has been sent." });
  } catch (err) {
    next(err);
  }
});

authRouter.post("/reset-password", async (req, res, next) => {
  try {
    const { email, code, password } = resetPasswordSchema.parse(req.body);
    await resetPassword(email, code, password);
    res.json({ message: "Password reset successfully." });
  } catch (err) {
    next(err);
  }
});
