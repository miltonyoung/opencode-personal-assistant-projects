import { pool } from './pool.js';

export async function findUploadByFingerprint(uploaderId, fingerprint) {
  const result = await pool.query(
    `SELECT * FROM uploads
     WHERE uploader_id = $1 AND fingerprint = $2 AND copy_index = 0
     ORDER BY created_at DESC
     LIMIT 1`,
    [uploaderId, fingerprint]
  );
  return result.rows[0] || null;
}

export async function findUploadByFingerprintAndCopy(uploaderId, fingerprint, copyIndex) {
  const result = await pool.query(
    `SELECT * FROM uploads
     WHERE uploader_id = $1 AND fingerprint = $2 AND copy_index = $3
     ORDER BY created_at DESC
     LIMIT 1`,
    [uploaderId, fingerprint, copyIndex]
  );
  return result.rows[0] || null;
}

export async function findUnfinishedUpload(uploaderId, fingerprint) {
  const result = await pool.query(
    `SELECT * FROM uploads
     WHERE uploader_id = $1 AND fingerprint = $2
       AND status IN ('pending', 'uploading', 'failed')
       AND session_url IS NOT NULL
     ORDER BY created_at DESC
     LIMIT 1`,
    [uploaderId, fingerprint]
  );
  return result.rows[0] || null;
}

export async function findCompletedUploadByFingerprint(uploaderId, fingerprint) {
  const result = await pool.query(
    `SELECT * FROM uploads
     WHERE uploader_id = $1 AND fingerprint = $2
       AND status = 'completed'
     ORDER BY created_at DESC
     LIMIT 1`,
    [uploaderId, fingerprint]
  );
  return result.rows[0] || null;
}

export async function getNextCopyIndex(uploaderId, fingerprint) {
  const result = await pool.query(
    `SELECT COALESCE(MAX(copy_index), 0) + 1 AS next_index
     FROM uploads
     WHERE uploader_id = $1 AND fingerprint = $2`,
    [uploaderId, fingerprint]
  );
  return result.rows[0].next_index;
}

export async function createUpload({
  uploaderId,
  displayName,
  fileName,
  fileSize,
  mimeType,
  fingerprint,
  copyIndex = 0,
  folderId,
  status = 'pending',
  mode = 'standard',
  replacesUploadId = null,
  sessionUrl = null,
  driveFileId = null,
}) {
  const result = await pool.query(
    `INSERT INTO uploads (
      uploader_id, display_name, file_name, file_size, mime_type,
      fingerprint, copy_index, folder_id, status, mode,
      replaces_upload_id, session_url, drive_file_id
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
    RETURNING *`,
    [
      uploaderId, displayName, fileName, fileSize, mimeType,
      fingerprint, copyIndex, folderId, status, mode,
      replacesUploadId, sessionUrl, driveFileId,
    ]
  );
  return result.rows[0];
}

export async function setUploadSessionUrl(id, sessionUrl) {
  const result = await pool.query(
    `UPDATE uploads
     SET session_url = $2, status = 'uploading', updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [id, sessionUrl]
  );
  return result.rows[0] || null;
}

export async function markUploadCompleted(id, driveFileId) {
  const result = await pool.query(
    `UPDATE uploads
     SET status = 'completed', drive_file_id = $2, completed_at = NOW(), updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [id, driveFileId]
  );
  return result.rows[0] || null;
}

export async function markUploadReplaced(id) {
  const result = await pool.query(
    `UPDATE uploads
     SET status = 'replaced', updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [id]
  );
  return result.rows[0] || null;
}

export async function markUploadFailed(id) {
  const result = await pool.query(
    `UPDATE uploads
     SET status = 'failed', updated_at = NOW()
     WHERE id = $1
     RETURNING *`,
    [id]
  );
  return result.rows[0] || null;
}

export async function getUploadById(id) {
  const result = await pool.query('SELECT * FROM uploads WHERE id = $1', [id]);
  return result.rows[0] || null;
}
