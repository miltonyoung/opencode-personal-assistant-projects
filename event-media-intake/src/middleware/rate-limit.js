import rateLimit from 'express-rate-limit';
import { config } from '../config.js';

export const initUploadRateLimit = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: config.limits.initUploadPerMinute,
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => req.headers.authorization || req.ip,
  handler: (req, res) => {
    res.status(429).json({
      error: 'Too many upload initialization requests. Please slow down.',
      retryAfter: res.getHeader('Retry-After'),
    });
  },
});
