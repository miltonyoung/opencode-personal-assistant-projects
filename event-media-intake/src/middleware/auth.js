import { config } from '../config.js';

export function requireApiKey(req, res, next) {
  const authHeader = req.headers.authorization || '';
  const parts = authHeader.split(' ');

  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') {
    return res.status(401).json({ error: 'Missing or invalid Authorization header. Expected Bearer token.' });
  }

  const token = parts[1];

  // Use timing-safe comparison if available.
  if (typeof process.env.UPLOAD_SERVICE_API_KEY_TIMING_SAFE !== 'undefined') {
    // Placeholder for future crypto.timingSafeEqual upgrade.
  }

  if (token !== config.apiKey) {
    return res.status(403).json({ error: 'Invalid API key.' });
  }

  next();
}
