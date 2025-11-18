

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

   -- 3) Policy type enum
   DO $$
   BEGIN
     IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'policy_type') THEN
       CREATE TYPE policy_type AS ENUM ('HOUSE', 'MOTOR');
     END IF;
   END$$;

   -- 4) Policies table (superclass)
   CREATE TABLE IF NOT EXISTS policies (
     id            BIGSERIAL PRIMARY KEY,
     user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
     policy_type   policy_type NOT NULL,
     policy_number TEXT UNIQUE NOT NULL,
     premium_cents INTEGER NOT NULL CHECK (premium_cents >= 0) DEFAULT 0,
     start_date    DATE NOT NULL DEFAULT CURRENT_DATE,
     end_date      DATE,
     status        TEXT NOT NULL DEFAULT 'ACTIVE',
     created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
   );

   CREATE INDEX IF NOT EXISTS idx_policies_user_id ON policies(user_id);
   CREATE INDEX IF NOT EXISTS idx_policies_type ON policies(policy_type);

   -- 5) House policy details (subclass)
   CREATE TABLE IF NOT EXISTS house_policies (
     policy_id            BIGINT PRIMARY KEY REFERENCES policies(id) ON DELETE CASCADE,
     address_line         TEXT NOT NULL,
     property_value_cents INTEGER CHECK (property_value_cents >= 0),
     construction_year    INTEGER CHECK (construction_year BETWEEN 1800 AND EXTRACT(YEAR FROM NOW())::INT),
     insurance_value_cents INTEGER CHECK (insurance_value_cents >= 0)
   );

   -- Ensure only HOUSE policies can have an entry here
   CREATE OR REPLACE FUNCTION enforce_house_type()
   RETURNS TRIGGER AS $$
   BEGIN
     IF (SELECT policy_type FROM policies WHERE id = NEW.policy_id) <> 'HOUSE' THEN
       RAISE EXCEPTION 'house_policies must reference a HOUSE policy';
     END IF;
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   DROP TRIGGER IF EXISTS trg_house_type ON house_policies;
   CREATE TRIGGER trg_house_type
   BEFORE INSERT OR UPDATE ON house_policies
   FOR EACH ROW EXECUTE FUNCTION enforce_house_type();

   -- 6) Motor policy details (subclass)
   CREATE TABLE IF NOT EXISTS motor_policies (
     policy_id        BIGINT PRIMARY KEY REFERENCES policies(id) ON DELETE CASCADE,
     vehicle_make     TEXT NOT NULL,
     vehicle_model    TEXT NOT NULL,
     vehicle_year     INTEGER CHECK (vehicle_year BETWEEN 1900 AND EXTRACT(YEAR FROM NOW())::INT + 1),
     vin              TEXT UNIQUE,
     registration_no  TEXT,
     insurance_value_cents INTEGER CHECK (insurance_value_cents >= 0)
   );

   -- Ensure only MOTOR policies can have an entry here
   CREATE OR REPLACE FUNCTION enforce_motor_type()
   RETURNS TRIGGER AS $$
   BEGIN
     IF (SELECT policy_type FROM policies WHERE id = NEW.policy_id) <> 'MOTOR' THEN
       RAISE EXCEPTION 'motor_policies must reference a MOTOR policy';
     END IF;
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   DROP TRIGGER IF EXISTS trg_motor_type ON motor_policies;
   CREATE TRIGGER trg_motor_type
   BEFORE INSERT OR UPDATE ON motor_policies
   FOR EACH ROW EXECUTE FUNCTION enforce_motor_type();

   -- 7) Seed sample policies for existing users
   -- Sally Writer: both house and motor
   -- Nima Acharya: house only
   -- Charlie Smith: motor only

   -- Sally - house
   INSERT INTO policies (user_id, policy_type, policy_number, premium_cents, start_date, status)
   SELECT u.id, 'HOUSE'::policy_type, 'HOUSE-SALLY-001', 120000, CURRENT_DATE - INTERVAL '1 year', 'ACTIVE'
   FROM users u
   WHERE u.full_name = 'Sally Writer'
   ON CONFLICT (policy_number) DO NOTHING;

   INSERT INTO house_policies (policy_id, address_line, property_value_cents, construction_year, insurance_value_cents)
   SELECT p.id, '12 Rose Street, Springfield', 35000000, 1998, 30000000
   FROM policies p
   JOIN users u on p.user_id = u.id
   WHERE p.policy_number = 'HOUSE-SALLY-001' AND u.full_name = 'Sally Writer'
   ON CONFLICT DO NOTHING;

   -- Sally - motor
   INSERT INTO policies (user_id, policy_type, policy_number, premium_cents, start_date, status)
   SELECT u.id, 'MOTOR'::policy_type, 'MOTOR-SALLY-001', 85000, CURRENT_DATE - INTERVAL '6 months', 'ACTIVE'
   FROM users u
   WHERE u.full_name = 'Sally Writer'
   ON CONFLICT (policy_number) DO NOTHING;

   INSERT INTO motor_policies (policy_id, vehicle_make, vehicle_model, vehicle_year, vin, registration_no, insurance_value_cents)
   SELECT p.id, 'Toyota', 'Corolla', 2015, 'SALLYVIN12345', 'REG-SAL-001', 1500000
   FROM policies p
   JOIN users u on p.user_id = u.id
   WHERE p.policy_number = 'MOTOR-SALLY-001' AND u.full_name = 'Sally Writer'
   ON CONFLICT DO NOTHING;

   -- Nima - house
   INSERT INTO policies (user_id, policy_type, policy_number, premium_cents, start_date, status)
   SELECT u.id, 'HOUSE'::policy_type, 'HOUSE-NIMA-001', 95000, CURRENT_DATE - INTERVAL '2 years', 'ACTIVE'
   FROM users u
   WHERE u.full_name = 'Nima Acharya'
   ON CONFLICT (policy_number) DO NOTHING;

   INSERT INTO house_policies (policy_id, address_line, property_value_cents, construction_year, insurance_value_cents)
   SELECT p.id, '44 Elm Road, Lakeside', 22000000, 2010, 20000000
   FROM policies p
   JOIN users u on p.user_id = u.id
   WHERE p.policy_number = 'HOUSE-NIMA-001' AND u.full_name = 'Nima Acharya'
   ON CONFLICT DO NOTHING;

   -- Charlie - motor
   INSERT INTO policies (user_id, policy_type, policy_number, premium_cents, start_date, status)
   SELECT u.id, 'MOTOR'::policy_type, 'MOTOR-CHARLIE-001', 67000, CURRENT_DATE - INTERVAL '9 months', 'ACTIVE'
   FROM users u
   WHERE u.full_name = 'Charlie Smith'
   ON CONFLICT (policy_number) DO NOTHING;

   INSERT INTO motor_policies (policy_id, vehicle_make, vehicle_model, vehicle_year, vin, registration_no, insurance_value_cents)
   SELECT p.id, 'Honda', 'Civic', 2018, 'CHARLIEVIN98765', 'REG-CHAR-001', 1800000
   FROM policies p
   JOIN users u on p.user_id = u.id
   WHERE p.policy_number = 'MOTOR-CHARLIE-001' AND u.full_name = 'Charlie Smith'
   ON CONFLICT DO NOTHING;

