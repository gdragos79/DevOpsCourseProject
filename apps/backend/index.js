// apps/backend/index.js
const express = require('express');
const cors = require('cors');
const { Client } = require('pg');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = parseInt(process.env.PORT || '3000', 10);

function getDbConfig() {
  const { DB_HOST, DB_PORT = '5432', DB_USER, DB_PASSWORD, DB_NAME } = process.env;
  return {
    host: DB_HOST,
    port: parseInt(DB_PORT, 10),
    user: DB_USER,
    password: DB_PASSWORD,
    database: DB_NAME,
    ssl: false
  };
}

function hasDbEnv() {
  const { DB_HOST, DB_USER, DB_NAME } = process.env;
  return Boolean(DB_HOST && DB_USER && DB_NAME);
}

async function withClient(fn) {
  const client = new Client(getDbConfig());
  await client.connect();
  try {
    return await fn(client);
  } finally {
    await client.end();
  }
}

async function ensureUsersTable(client) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS users (
      id SERIAL PRIMARY KEY,
      name TEXT NOT NULL,
      age INTEGER NOT NULL,
      email TEXT NOT NULL
    );
  `);

  await client.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS users_name_age_email_unique_idx
    ON users (name, age, email);
  `);
}

app.get(['/api/health', '/health'], (req, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

app.get(['/api/db', '/db'], async (req, res) => {
  if (!hasDbEnv()) {
    return res.status(200).json({ db: 'skipped', reason: 'missing DB_* envs' });
  }

  try {
    const result = await withClient(async (client) => {
      await ensureUsersTable(client);
      const r = await client.query('SELECT 1 AS ok');
      return r.rows[0];
    });

    res.json({ db: 'ok', result });
  } catch (err) {
    res.status(500).json({ db: 'error', message: err.message });
  }
});

app.get('/api/all', async (req, res) => {
  if (!hasDbEnv()) {
    return res.status(500).json({ error: 'Database configuration is missing' });
  }

  try {
    const users = await withClient(async (client) => {
      await ensureUsersTable(client);
      const r = await client.query(
        'SELECT id, name, age, email FROM users ORDER BY id ASC'
      );
      return r.rows;
    });

    res.json(users);
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch users', message: err.message });
  }
});

app.post('/api/form', async (req, res) => {
  if (!hasDbEnv()) {
    return res.status(500).json({ error: 'Database configuration is missing' });
  }

  const { name, age, email } = req.body || {};

  if (!name || age === undefined || age === null || !email) {
    return res.status(400).json({ error: 'name, age and email are required' });
  }

  const parsedAge = parseInt(age, 10);
  if (Number.isNaN(parsedAge)) {
    return res.status(400).json({ error: 'age must be a valid integer' });
  }

  try {
    const inserted = await withClient(async (client) => {
      await ensureUsersTable(client);
      const r = await client.query(
        'INSERT INTO users (name, age, email) VALUES ($1, $2, $3) RETURNING id, name, age, email',
        [String(name).trim(), parsedAge, String(email).trim()]
      );
      return r.rows[0];
    });

    res.status(201).json(inserted);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'The user already exists' });
    }
    return res.status(500).json({ error: 'Failed to create user', message: err.message });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend listening on http://127.0.0.1:${PORT}`);
});
