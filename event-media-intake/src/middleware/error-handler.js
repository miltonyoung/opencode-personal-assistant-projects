import { config } from '../config.js';

export function errorHandler(err, req, res, next) {
  console.error('Unhandled error:', err);

  const statusCode = err.statusCode || 500;
  const message = config.env === 'production' && statusCode >= 500
    ? 'Internal server error'
    : err.message || 'Internal server error';

  res.status(statusCode).json({
    error: message,
    ...(config.env !== 'production' && err.stack ? { stack: err.stack } : {}),
  });
}
