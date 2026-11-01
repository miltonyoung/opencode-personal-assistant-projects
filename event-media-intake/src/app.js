import express from 'express';
import helmet from 'helmet';
import { requireApiKey } from './middleware/auth.js';
import { errorHandler } from './middleware/error-handler.js';
import healthRouter from './routes/health.js';
import checkFileRouter from './routes/check-file.js';
import initUploadRouter from './routes/init-upload.js';
import completeUploadRouter from './routes/complete-upload.js';

const app = express();

app.use(helmet());
app.use(express.json());

// Public health check (used by Docker Compose and monitoring).
app.use('/api/health', healthRouter);

// All other API endpoints require the coordinator API key.
app.use('/api', requireApiKey);
app.use('/api/check-file', checkFileRouter);
app.use('/api/init-upload', initUploadRouter);
app.use('/api/complete-upload', completeUploadRouter);

app.use(errorHandler);

export default app;
