import { pool } from '../db/pool.js';
import { config } from '../config.js';

export async function pruneExpiredRows() {
  const results = {};

  // Completed rows older than RETENTION_COMPLETED_DAYS.
  const completedResult = await pool.query(
    `DELETE FROM uploads
     WHERE status = 'completed'
       AND completed_at < NOW() - INTERVAL '${config.retention.completedDays} days'`
  );
  results.completed = completedResult.rowCount;

  // Uploading/failed rows older than RETENTION_UPLOADING_DAYS.
  const uploadingResult = await pool.query(
    `DELETE FROM uploads
     WHERE status IN ('uploading', 'failed')
       AND updated_at < NOW() - INTERVAL '${config.retention.uploadingDays} days'`
  );
  results.uploading = uploadingResult.rowCount;

  // Pending rows older than RETENTION_PENDING_DAYS.
  const pendingResult = await pool.query(
    `DELETE FROM uploads
     WHERE status = 'pending'
       AND created_at < NOW() - INTERVAL '${config.retention.pendingDays} days'`
  );
  results.pending = pendingResult.rowCount;

  return results;
}

// Run directly via: node src/lib/retention.js
if (import.meta.url === `file://${process.argv[1]}`) {
  pruneExpiredRows()
    .then((counts) => {
      console.log('Pruning complete:', counts);
      process.exit(0);
    })
    .catch((err) => {
      console.error('Pruning failed:', err);
      process.exit(1);
    });
}
