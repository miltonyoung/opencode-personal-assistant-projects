import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { pool } from './pool.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const migrationsDir = path.join(__dirname, '..', '..', 'migrations');

async function runMigrations() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // Ensure migration bookkeeping table exists.
    await client.query(`
      CREATE TABLE IF NOT EXISTS migrations (
        id SERIAL PRIMARY KEY,
        filename VARCHAR(255) NOT NULL UNIQUE,
        applied_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
      );
    `);

    const files = await fs.readdir(migrationsDir);
    const sqlFiles = files
      .filter((f) => f.endsWith('.sql'))
      .sort();

    for (const filename of sqlFiles) {
      const existing = await client.query(
        'SELECT filename FROM migrations WHERE filename = $1',
        [filename]
      );

      if (existing.rowCount > 0) {
        console.log(`Skipping ${filename} (already applied)`);
        continue;
      }

      const filePath = path.join(migrationsDir, filename);
      const sql = await fs.readFile(filePath, 'utf-8');

      console.log(`Applying ${filename}...`);
      await client.query(sql);
      await client.query(
        'INSERT INTO migrations (filename) VALUES ($1)',
        [filename]
      );
    }

    await client.query('COMMIT');
    console.log('Migrations complete.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

runMigrations();
