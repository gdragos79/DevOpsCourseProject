-- infra/db/init/01-init-users.sql
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  age INTEGER NOT NULL,
  email TEXT NOT NULL
);

CREATE UNIQUE INDEX IF NOT EXISTS users_name_age_email_unique_idx
ON users (name, age, email);
