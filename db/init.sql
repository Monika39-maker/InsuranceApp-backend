

-- 2) Users table
CREATE TABLE IF NOT EXISTS users (
  id            BIGSERIAL PRIMARY KEY,
  full_name     TEXT NOT NULL,
  password      TEXT NOT NULL,
  role          TEXT NOT NULL
);

-- Avoid duplicate seed rows based on (full_name, role)
CREATE UNIQUE INDEX IF NOT EXISTS uniq_users_full_name_role ON users(full_name, role);

-- Seed sample users (safe to re-run: avoid duplicates by unique full_name+role combination if desired)
-- Note: For production, store hashed passwords. These are plain-text for demo only.
INSERT INTO users (full_name, password, role)
VALUES
  ('Nicky Tania', 'nick123', 'underwriter'),
  ('Joe Smith', 'joe123', 'admin'),
  ('Lily Singh', 'lily123', 'underwriter'),
  ('Sally Writer', 'sal123', 'insured'),
  ('Nima Acharya', 'nim123', 'insured'),
  ('Charlie Smith', 'charl123', 'insured')
ON CONFLICT DO NOTHING;

-- 3) Policies table (superclass)
-- CREATE TABLE IF NOT EXISTS policies (
--   id            BIGSERIAL PRIMARY KEY,
--   user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
--   policy_type   policy_type NOT NULL,
--   policy_number TEXT UNIQUE NOT NULL,
--   premium_cents INTEGER NOT NULL CHECK (premium_cents >= 0),
--   start_date    DATE NOT NULL,
--   end_date      DATE,
--   status        TEXT NOT NULL DEFAULT 'ACTIVE',  -- e.g., ACTIVE, LAPSED, CANCELLED
--   created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
-- );

-- CREATE INDEX IF NOT EXISTS idx_policies_user_id ON policies(user_id);
-- CREATE INDEX IF NOT EXISTS idx_policies_type ON policies(policy_type);

-- 4) House policy details (subclass)
-- CREATE TABLE IF NOT EXISTS house_policies (
--   policy_id            BIGINT PRIMARY KEY REFERENCES policies(id) ON DELETE CASCADE,
--   address_line       TEXT NOT NULL,
  
--   property_value_cents INTEGER CHECK (property_value_cents >= 0),
--   construction_year    INTEGER CHECK (construction_year BETWEEN 1800 AND EXTRACT(YEAR FROM NOW())::INT),
--   insurance_value_cents INTEGER CHECK (insurance_value_cents >= 0),
  
-- );

-- Ensure only HOUSE policies can have an entry here
-- CREATE OR REPLACE FUNCTION enforce_house_type()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   IF (SELECT policy_type FROM policies WHERE id = NEW.policy_id) <> 'HOUSE' THEN
--     RAISE EXCEPTION 'house_policies must reference a HOUSE policy';
--   END IF;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS trg_house_type ON house_policies;
-- CREATE TRIGGER trg_house_type
-- BEFORE INSERT OR UPDATE ON house_policies
-- FOR EACH ROW EXECUTE FUNCTION enforce_house_type();

-- 5) Motor policy details (subclass)
-- CREATE TABLE IF NOT EXISTS motor_policies (
--   policy_id        BIGINT PRIMARY KEY REFERENCES policies(id) ON DELETE CASCADE,
--   vehicle_make     TEXT NOT NULL,
--   vehicle_model    TEXT NOT NULL,
--   vehicle_year     INTEGER CHECK (vehicle_year BETWEEN 1900 AND EXTRACT(YEAR FROM NOW())::INT + 1),
--   vin              TEXT UNIQUE,
--   registration_no  TEXT,
--   insurance_value_cents INTEGER CHECK (insurance_value_cents >= 0),
-- );

-- Ensure only MOTOR policies can have an entry here
-- CREATE OR REPLACE FUNCTION enforce_motor_type()
-- RETURNS TRIGGER AS $$
-- BEGIN
--   IF (SELECT policy_type FROM policies WHERE id = NEW.policy_id) <> 'MOTOR' THEN
--     RAISE EXCEPTION 'motor_policies must reference a MOTOR policy';
--   END IF;
--   RETURN NEW;
-- END;
-- $$ LANGUAGE plpgsql;

-- DROP TRIGGER IF EXISTS trg_motor_type ON motor_policies;
-- CREATE TRIGGER trg_motor_type
-- BEFORE INSERT OR UPDATE ON motor_policies
-- FOR EACH ROW EXECUTE FUNCTION enforce_motor_type();
