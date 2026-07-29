import "dotenv/config";

function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

const nodeEnv = process.env.NODE_ENV ?? "development";
const isProduction = nodeEnv === "production";

const DEV_JWT_SECRET_FALLBACK = "dev-secret-change-me";
const jwtSecret = required("JWT_SECRET", isProduction ? undefined : DEV_JWT_SECRET_FALLBACK);
// Belt-and-suspenders: even if someone sets JWT_SECRET=dev-secret-change-me
// explicitly in a production env by copy-paste mistake, refuse to boot —
// every token issued with this well-known secret would be forgeable.
if (isProduction && jwtSecret === DEV_JWT_SECRET_FALLBACK) {
  throw new Error("JWT_SECRET must not be the development default value in production");
}

export const env = {
  nodeEnv,
  isProduction,
  port: Number(process.env.PORT ?? 4000),
  databaseUrl: required("DATABASE_URL"),
  jwtSecret,
  jwtExpiresIn: process.env.JWT_EXPIRES_IN ?? "7d",
  omisePublicKey: process.env.OMISE_PUBLIC_KEY || undefined,
  omiseSecretKey: process.env.OMISE_SECRET_KEY || undefined,
  cloudinaryCloudName: process.env.CLOUDINARY_CLOUD_NAME || undefined,
  cloudinaryApiKey: process.env.CLOUDINARY_API_KEY || undefined,
  cloudinaryApiSecret: process.env.CLOUDINARY_API_SECRET || undefined,
};
