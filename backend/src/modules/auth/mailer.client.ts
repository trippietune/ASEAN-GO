import nodemailer, { Transporter } from "nodemailer";
import { env } from "../../config/env";
import { logger } from "../../config/logger";

let transporter: Transporter | null = null;

function getTransporter(): Transporter | null {
  if (!env.smtpHost || !env.smtpUser || !env.smtpPassword) return null;
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: env.smtpHost,
      port: env.smtpPort,
      secure: env.smtpPort === 465,
      auth: { user: env.smtpUser, pass: env.smtpPassword },
    });
  }
  return transporter;
}

/// Sends the password-reset code by email, or — if SMTP isn't configured —
/// logs it instead so local development isn't blocked on picking a
/// provider. Never throws: a reset request must not reveal via a 500
/// whether sending failed for a given address, and the caller already
/// returns a generic "check your email" response regardless of outcome.
export async function sendPasswordResetEmail(to: string, code: string): Promise<void> {
  const client = getTransporter();
  if (!client) {
    logger.warn({ to, code }, "SMTP not configured — logging password reset code instead of emailing it");
    return;
  }

  try {
    await client.sendMail({
      from: env.smtpFrom ?? env.smtpUser,
      to,
      subject: "Your AseanGo password reset code",
      text: `We received a request to reset your AseanGo password.\n\nYour reset code is: ${code}\n\nEnter this code in the app to choose a new password. This code expires in 15 minutes. If you didn't request this, you can ignore this email.`,
      html: `<p>We received a request to reset your AseanGo password.</p><p style="font-size:28px;font-weight:bold;letter-spacing:4px;">${code}</p><p>Enter this code in the app to choose a new password. This code expires in 15 minutes. If you didn't request this, you can ignore this email.</p>`,
    });
  } catch (err) {
    logger.error({ err, to }, "Failed to send password reset email");
  }
}
