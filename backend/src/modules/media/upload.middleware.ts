import multer from "multer";
import { HttpError } from "../../middleware/errorHandler";

const MAX_FILE_BYTES = 8 * 1024 * 1024; // 8MB — generous for phone camera photos, small enough to not tie up memory
const ALLOWED_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/heic", "image/heif"]);

/// Memory storage: files land in req.file.buffer, never touch disk. We
/// stream that buffer straight to Cloudinary (see cloudinary.client.ts)
/// rather than writing a temp file we'd have to remember to clean up.
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_FILE_BYTES },
  fileFilter: (_req, file, cb) => {
    if (!ALLOWED_MIME_TYPES.has(file.mimetype)) {
      cb(new HttpError(400, `Unsupported image type: ${file.mimetype}`));
      return;
    }
    cb(null, true);
  },
});

export const uploadSingleImage = upload.single("image");
