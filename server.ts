import express from 'express';
import type { Response, Request } from 'express';
import cors from 'cors';
import { Pool } from 'pg';
import dotenv from 'dotenv';


// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

// Enable CORS
app.use(cors());

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));


// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: {
    rejectUnauthorized: false
  }
});

// Test database connection
const testDatabaseConnection = async () => {
  try {
    const client = await pool.connect();
    console.log('Successfully connected to the database');
    const result = await client.query('SELECT NOW()');
    console.log('Database time:', result.rows[0].now);
    client.release();
    return true;
  } catch (err) {
    console.error('Database connection error:', err);
    return false;
  }
};

// Types
export type users = {
  id: number;
  fullname: string;
  policy: string;
}



// Get all events
app.get('/users', async (req: Request, res: Response) => {
  try {
    // Only return non-sensitive fields
    const result = await pool.query('SELECT id, full_name, role FROM users');
    console.log('Retrieved users:', result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ 
      error: 'Failed to fetch users',
      details: err instanceof Error ? err.message : 'Unknown error'
    });
  }
});

// Create a new user
app.post('/users', async (req: Request, res: Response) => {
  const { full_name, role } = req.body;

  if (!full_name || !role) {
    return res.status(400).json({ error: 'full_name and role are required' });
  }

  try {
    // Password column exists in DB schema and is NOT NULL; store empty string when not provided
    const password = '';
    const insert = await pool.query(
      'INSERT INTO users (full_name, role) VALUES ($1, $2) RETURNING id, full_name, role',
      [full_name, role]
    );

    const created = insert.rows[0];
    res.status(201).json(created);
  } catch (err) {
    console.error('Error creating user:', err);
    res.status(500).json({ error: 'Failed to create user', details: err instanceof Error ? err.message : 'Unknown error' });
  }
});

app.get('/housepolicies', async (req: Request, res: Response) => {
  try {
    // Only return non-sensitive fields
    const result = await pool.query('SELECT * FROM house_policies');
    console.log('Retrieved users:', result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching users:', err);
    res.status(500).json({ 
      error: 'Failed to fetch users',
      details: err instanceof Error ? err.message : 'Unknown error'
    });
  }
});

// Get policies (basic list joining policies table)
app.get('/policies', async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT id, user_id, policy_type, policy_number, premium_cents, start_date, end_date, status
       FROM policies`
    );
    console.log('Retrieved policies:', result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching policies:', err);
    res.status(500).json({
      error: 'Failed to fetch policies',
      details: err instanceof Error ? err.message : 'Unknown error'
    });
  }
});




// Get users with policy flags (has_house, has_motor)
app.get('/users-with-policies', async (req: Request, res: Response) => {
  try {
    const result = await pool.query(
      `SELECT u.id, u.full_name, u.role,
         BOOL_OR((p.policy_type)::text = 'HOUSE') AS has_house,
         BOOL_OR((p.policy_type)::text = 'MOTOR') AS has_motor
       FROM users u
       LEFT JOIN policies p ON p.user_id = u.id
       GROUP BY u.id, u.full_name, u.role`
    );
    console.log('Retrieved users-with-policies:', result.rows.length);
    res.json(result.rows);
  } catch (err) {
    console.error('Error fetching users-with-policies:', err);
    res.status(500).json({
      error: 'Failed to fetch users with policies',
      details: err instanceof Error ? err.message : 'Unknown error'
    });
  }
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});