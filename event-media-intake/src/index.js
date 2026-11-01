import app from './app.js';
import { config } from './config.js';
import { pool } from './db/pool.js';

const server = app.listen(config.port, () => {
  console.log(`Event media upload service listening on port ${config.port} in ${config.env} mode`);
});

// Graceful shutdown.
async function shutdown(signal) {
  console.log(`Received ${signal}. Shutting down gracefully...`);

  server.close(async () => {
    try {
      await pool.end();
      console.log('Database pool closed.');
      process.exit(0);
    } catch (err) {
      console.error('Error during shutdown:', err);
      process.exit(1);
    }
  });
}

process.on('SIGTERM', () => shutdown('SIGTERM'));
process.on('SIGINT', () => shutdown('SIGINT'));
