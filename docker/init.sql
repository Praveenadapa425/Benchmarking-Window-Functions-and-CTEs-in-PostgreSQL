-- Create tables
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    email VARCHAR(255) UNIQUE,
    cohort_month DATE NOT NULL,
    referred_by INT REFERENCES users(user_id)
);

CREATE TABLE orders (
    order_id UUID PRIMARY KEY,
    user_id INT REFERENCES users(user_id),
    product_id INT NOT NULL,
    amount NUMERIC CHECK (amount > 0),
    status VARCHAR(50) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Seed users
INSERT INTO users (user_id, email, cohort_month, referred_by)
SELECT
    i,
    'user_' || i || '@example.com',
    date_trunc('month', CURRENT_DATE - (floor(random() * 24) * INTERVAL '1 month'))::date,
    NULL
FROM generate_series(1, 200000) i;

-- Update referred_by to simulate referral graph (DAG)
UPDATE users
SET referred_by = floor(random() * (user_id - 1) + 1)::int
WHERE user_id > 1 AND random() < 0.3;

-- Seed orders (power-law distribution of orders per user)
INSERT INTO orders (order_id, user_id, product_id, amount, status, created_at, updated_at)
SELECT
    gen_random_uuid(),
    floor(1 + 199999 * power(random(), 5.0))::int,
    floor(1 + random() * 100)::int,
    round((random() * 495 + 5.00)::numeric, 2),
    (ARRAY['completed', 'pending', 'cancelled'])[floor(random() * 3 + 1)],
    CURRENT_DATE - (random() * 730 * INTERVAL '1 day') - (random() * 24 * INTERVAL '1 hour'),
    NOW()
FROM generate_series(1, 1000000) i;
