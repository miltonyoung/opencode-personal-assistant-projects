import 'dotenv/config';

function toInt(value, defaultValue) {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? defaultValue : parsed;
}

function toBytes(value, defaultValue) {
  const parsed = parseInt(value, 10);
  return Number.isNaN(parsed) ? defaultValue : parsed;
}

export const config = {
  env: process.env.NODE_ENV || 'development',
  port: toInt(process.env.PORT, 3000),

  apiKey: process.env.UPLOAD_SERVICE_API_KEY,

  google: {
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    refreshToken: process.env.GOOGLE_REFRESH_TOKEN,
    scope: process.env.GOOGLE_DRIVE_SCOPE || 'https://www.googleapis.com/auth/drive.file',
  },

  database: {
    url: process.env.DATABASE_URL,
  },

  limits: {
    maxFileSize: toBytes(process.env.MAX_FILE_SIZE_BYTES, 5 * 1024 * 1024 * 1024), // 5 GB
    initUploadPerMinute: toInt(process.env.INIT_UPLOAD_PER_MINUTE, 100),
    chunkSize: toBytes(process.env.CHUNK_SIZE_BYTES, 10 * 1024 * 1024), // 10 MB
  },

  retention: {
    completedDays: toInt(process.env.RETENTION_COMPLETED_DAYS, 180),
    uploadingDays: toInt(process.env.RETENTION_UPLOADING_DAYS, 30),
    pendingDays: toInt(process.env.RETENTION_PENDING_DAYS, 7),
  },
};

if (!config.apiKey) {
  throw new Error('UPLOAD_SERVICE_API_KEY is required');
}

if (!config.google.refreshToken) {
  console.warn('GOOGLE_REFRESH_TOKEN is not set. Google Drive operations will fail until configured.');
}

if (!config.database.url) {
  throw new Error('DATABASE_URL is required');
}
