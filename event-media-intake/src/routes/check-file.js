import { Router } from 'express';
import {
  findCompletedUploadByFingerprint,
  findUnfinishedUpload,
} from '../db/queries.js';

const router = Router();

/**
 * POST /api/check-file
 *
 * Body: { uploaderId, fingerprint, fileName, fileSize, mimeType }
 *
 * Returns:
 * - { status: 'new' }
 * - { status: 'resumable', uploadUrl }
 * - { status: 'duplicate', fileId, fileName }
 */
router.post('/', async (req, res) => {
  const { uploaderId, fingerprint, fileName, fileSize, mimeType } = req.body;

  if (!uploaderId || !fingerprint) {
    return res.status(400).json({
      error: 'uploaderId and fingerprint are required.',
    });
  }

  // First: is there an unfinished upload with a valid session URL?
  const unfinished = await findUnfinishedUpload(uploaderId, fingerprint);
  if (unfinished?.session_url) {
    return res.json({
      status: 'resumable',
      uploadUrl: unfinished.session_url,
    });
  }

  // Second: is there a completed duplicate?
  const completed = await findCompletedUploadByFingerprint(uploaderId, fingerprint);
  if (completed) {
    return res.json({
      status: 'duplicate',
      fileId: completed.drive_file_id,
      fileName: completed.file_name,
    });
  }

  return res.json({ status: 'new' });
});

export default router;
