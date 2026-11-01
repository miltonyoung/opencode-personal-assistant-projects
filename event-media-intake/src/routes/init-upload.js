import { Router } from 'express';
import { config } from '../config.js';
import {
  createUpload,
  findCompletedUploadByFingerprint,
  findUploadByFingerprintAndCopy,
  getNextCopyIndex,
  setUploadSessionUrl,
} from '../db/queries.js';
import { createResumableSession } from '../services/drive.js';
import { sanitizeFileName, generateCopyFileName } from '../services/files.js';
import { initUploadRateLimit } from '../middleware/rate-limit.js';

const router = Router();

/**
 * POST /api/init-upload
 *
 * Body: { uploaderId, uploaderName, fileName, fileSize, mimeType, fingerprint, folderId, mode }
 *
 * mode is one of: 'standard' | 'replace' | 'keep_both'
 */
router.post('/', initUploadRateLimit, async (req, res) => {
  const {
    uploaderId,
    uploaderName,
    fileName,
    fileSize,
    mimeType,
    fingerprint,
    folderId,
    mode = 'standard',
  } = req.body;

  // Validate required fields.
  if (!uploaderId || !fileName || !fingerprint || !folderId) {
    return res.status(400).json({
      error: 'uploaderId, fileName, fingerprint, and folderId are required.',
    });
  }

  if (typeof fileSize !== 'number' || fileSize <= 0) {
    return res.status(400).json({ error: 'fileSize must be a positive number.' });
  }

  if (fileSize > config.limits.maxFileSize) {
    return res.status(413).json({
      error: `File size exceeds the maximum allowed size of ${config.limits.maxFileSize} bytes.`,
    });
  }

  const validModes = ['standard', 'replace', 'keep_both'];
  if (!validModes.includes(mode)) {
    return res.status(400).json({
      error: `mode must be one of: ${validModes.join(', ')}.`,
    });
  }

  const sanitizedName = sanitizeFileName(fileName);

  let copyIndex = 0;
  let finalFileName = sanitizedName;
  let replacesUploadId = null;

  if (mode === 'keep_both') {
    copyIndex = await getNextCopyIndex(uploaderId, fingerprint);
    finalFileName = generateCopyFileName(sanitizedName, copyIndex);

    // Defensive: if the generated copy index somehow collides, increment until free.
    while (await findUploadByFingerprintAndCopy(uploaderId, fingerprint, copyIndex)) {
      copyIndex += 1;
      finalFileName = generateCopyFileName(sanitizedName, copyIndex);
    }
  } else if (mode === 'replace') {
    const existing = await findCompletedUploadByFingerprint(uploaderId, fingerprint);
    if (existing) {
      replacesUploadId = existing.id;
    }
  }

  // Create the database row first so we have a record before Google Drive call.
  const upload = await createUpload({
    uploaderId,
    displayName: uploaderName,
    fileName: finalFileName,
    fileSize,
    mimeType,
    fingerprint,
    copyIndex,
    folderId,
    status: 'pending',
    mode,
    replacesUploadId,
  });

  // Create the resumable session with Google Drive.
  const sessionUrl = await createResumableSession({
    fileName: finalFileName,
    mimeType,
    folderId,
  });

  // Store the session URL and transition to 'uploading'.
  await setUploadSessionUrl(upload.id, sessionUrl);

  return res.json({ uploadUrl: sessionUrl });
});

export default router;
