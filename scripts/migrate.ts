import { Pool } from 'pg';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load env vars from Backend/.env
dotenv.config();

async function run() {
  const sqlPath = path.resolve(__dirname, '..', 'db', 'init.sql');
  const sql = fs.readFileSync(sqlPath, 'utf-8');

  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    console.error('DATABASE_URL is not set. Please set it in Backend/.env');
    process.exit(1);
  }

  const pool = new Pool({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  const client = await pool.connect();
  try {
    console.log('Running migrations from', sqlPath);
    await client.query('BEGIN');
    await client.query(sql);
    await client.query('COMMIT');
    console.log('Migrations completed successfully.');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Migration failed:', err);
    process.exitCode = 1;
  } finally {
    client.release();
    await pool.end();
  }
}

run().catch((err) => {
  console.error('Unexpected error:', err);
  process.exit(1);
});
