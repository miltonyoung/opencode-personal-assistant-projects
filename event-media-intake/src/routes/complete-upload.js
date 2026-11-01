import { Router } from 'express';
import {
  findUploadByFingerprintAndCopy,
  getUploadById,
  markUploadCompleted,
  markUploadReplaced,
} from '../db/queries.js';
import { getDriveFile, deleteDriveFile } from '../services/drive.js';

const router = Router();

/**
 * POST /api/complete-upload
 *
 * Body: { uploaderId, fingerprint, copyIndex, driveFileId }
 *
 * Verifies the file in Google Drive, marks the row completed,
 * and finalizes replacements.
 */
router.post('/', async (req, res) => {
  const { uploaderId, fingerprint, copyIndex = 0, driveFileId } = req.body;

  if (!uploaderId || !fingerprint || !driveFileId) {
    return res.status(400).json({
      error: 'uploaderId, fingerprint, and driveFileId are required.',
    });
  }

  // Find the matching upload row by unique key.
  const upload = await findUploadByFingerprintAndCopy(uploaderId, fingerprint, copyIndex);

  if (!upload) {
    return res.status(404).json({ error: 'Upload record not found.' });
  }

  // Verify the file exists in Google Drive.
  const driveFile = await getDriveFile(driveFileId);
  if (!driveFile) {
    return res.status(404).json({
      error: 'File not found in Google Drive. Upload may not have completed.',
    });
  }

  // Optional: verify size matches.
  if (driveFile.size && parseInt(driveFile.size, 10) !== upload.file_size) {
    return res.status(400).json({
      error: 'File size in Google Drive does not match expected size.',
      expected: upload.file_size,
      actual: parseInt(driveFile.size, 10),
    });
  }

  // Mark current upload complete.
  await markUploadCompleted(upload.id, driveFileId);

  // If this was a replacement, delete the old Drive file and mark old row replaced.
  if (upload.mode === 'replace' && upload.replaces_upload_id) {
    const oldUpload = await getUploadById(upload.replaces_upload_id);
    if (oldUpload && oldUpload.drive_file_id) {
      await deleteDriveFile(oldUpload.drive_file_id);
      await markUploadReplaced(oldUpload.id);
    }
  }

  return res.json({
    status: 'completed',
    fileId: driveFileId,
    fileName: driveFile.name,
  });
});

export default router;
