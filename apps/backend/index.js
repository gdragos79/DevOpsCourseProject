const express = require('express');
const cors = require('cors');
const { Client } = require('pg');

const app = express();
app.use(express.json());
app.use(cors());

const PORT = parseInt(process.env.PORT || '3000', 10);

function getDbConfig() {
  const {
    DB_HOST,
    DB_PORT = '5432',
    DB_USER,
    DB_PASSWORD,
    DB_NAME,
  } = process.env;

  return {
    DB_HOST,
    DB_PORT,
    DB_USER,
    DB_PASSWORD,
    DB_NAME,
  };
}

function hasDbEnv(cfg) {
  return Boolean(cfg.DB_HOST && cfg.DB_USER && cfg.DB_NAME);
}

function createClient(cfg) {
  return new Client({
    host: cfg.DB_HOST,
    port: parseInt(cfg.DB_PORT, 10),
    user: cfg.DB_USER,
    password: cfg.DB_PASSWORD,
    database: cfg.DB_NAME,
    ssl: false,
  });
}

async function withDb(work) {
  const cfg = getDbConfig();

  if (!hasDbEnv(cfg)) {
    const err = new Error('missing DB_* envs');
    err.statusCode = 503;
    throw err;
  }

  const client = createClient(cfg);
  await client.connect();

  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        age INTEGER NULL,
        email VARCHAR(255) NOT NULL UNIQUE,
        created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      )
    `);

    return await work(client);
  } finally {
    await client.end();
  }
}

app.get(['/api/health', '/health'], (req, res) => {
  res.json({ ok: true, ts: new Date().toISOString() });
});

app.get(['/api/db', '/db'], async (req, res) => {
  const cfg = getDbConfig();

  if (!hasDbEnv(cfg)) {
    return res.status(200).json({ db: 'skipped', reason: 'missing DB_* envs' });
  }

  try {
    const client = createClient(cfg);
    await client.connect();
    const r = await client.query('SELECT 1 AS ok');
    await client.end();
    res.json({ db: 'ok', result: r.rows[0] });
  } catch (err) {
    res.status(500).json({ db: 'error', message: err.message });
  }
});

app.get(['/api/all', '/all'], async (req, res) => {
  try {
    const rows = await withDb(async (client) => {
      const result = await client.query(
        'SELECT id, name, age, email FROM users ORDER BY id ASC'
      );
      return result.rows;
    });

    res.json(rows);
  } catch (err) {
    res.status(err.statusCode || 500).json({
      error: 'failed_to_fetch_users',
      message: err.message,
    });
  }
});

app.post(['/api/form', '/form'], async (req, res) => {
  const { name, age, email } = req.body || {};

  if (!name || !email) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'name and email are required',
    });
  }

  const parsedAge = age === null || age === undefined || age === '' ? null : Number(age);
  if (parsedAge !== null && Number.isNaN(parsedAge)) {
    return res.status(400).json({
      error: 'validation_error',
      message: 'age must be a number or empty',
    });
  }

  try {
    const created = await withDb(async (client) => {
      const result = await client.query(
        `
          INSERT INTO users (name, age, email)
          VALUES ($1, $2, $3)
          RETURNING id, name, age, email
        `,
        [name, parsedAge, email]
      );
      return result.rows[0];
    });

    res.status(201).json(created);
  } catch (err) {
    const message = (err && err.message) || 'unknown error';

    if (err && err.code === '23505') {
      return res.status(409).json({
        error: 'duplicate_email',
        message: 'a user with this email already exists',
      });
    }

    res.status(err.statusCode || 500).json({
      error: 'failed_to_create_user',
      message,
    });
  }
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Backend listening on http://127.0.0.1:${PORT}`);
});
