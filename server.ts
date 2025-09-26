import express, { Response, Request } from 'express';
import cors from 'cors';
import { Pool } from 'pg';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT

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

// Test database connec

// Types
export type users = {
  id: number;
  fullname: string;
  policy: string;
}



// Get all events
app.get('/users', async (req: Request, res: Response) => {
  
  try {
    const result = await pool.query('SELECT * FROM users');
    console.log(res.json(result.rows));
  } catch (err) {
    console.error('Error fetching events:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});




app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});