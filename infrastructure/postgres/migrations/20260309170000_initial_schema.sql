-- migrate:up

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    email VARCHAR(255) UNIQUE NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    full_name VARCHAR(255),
    plan VARCHAR(50) DEFAULT 'free',
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Topics table
CREATE TABLE IF NOT EXISTS topics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    user_id UUID REFERENCES users (id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    keywords TEXT [],
    platforms TEXT [],
    threshold INTEGER DEFAULT 20,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Trends table
CREATE TABLE IF NOT EXISTS trends (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    topic_id UUID REFERENCES topics (id) ON DELETE CASCADE,
    title VARCHAR(500),
    description TEXT,
    velocity_score FLOAT,
    sentiment VARCHAR(50),
    detected_at TIMESTAMP DEFAULT NOW(),
    ai_summary TEXT,
    sources JSONB
);

-- Trends archive (for cold storage)
CREATE TABLE IF NOT EXISTS trends_archive (LIKE trends INCLUDING ALL);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid (),
    trend_id UUID REFERENCES trends (id) ON DELETE CASCADE,
    user_id UUID REFERENCES users (id) ON DELETE CASCADE,
    channel VARCHAR(50),
    status VARCHAR(50) DEFAULT 'pending',
    sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_trends_detected_at ON trends (detected_at DESC);

CREATE INDEX IF NOT EXISTS idx_trends_velocity ON trends (velocity_score DESC);

CREATE INDEX IF NOT EXISTS idx_topics_user_id ON topics (user_id);

CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts (status);

CREATE INDEX IF NOT EXISTS idx_alerts_user_created ON alerts (user_id, created_at DESC);

-- Seed an admin user
INSERT INTO
    users (
        email,
        hashed_password,
        full_name,
        plan
    )
VALUES (
        'admin@viralis.ai',
        '$2b$12$LQv3c1VqBWUYRjW9f0f0uO1.2.3.4.5.6.7.8.9.0.1.2.3.4.5',
        'Admin User',
        'pro'
    )
ON CONFLICT (email) DO NOTHING;

-- migrate:down

DROP TABLE IF EXISTS alerts;

DROP TABLE IF EXISTS trends_archive;

DROP TABLE IF EXISTS trends;

DROP TABLE IF EXISTS topics;

DROP TABLE IF EXISTS users;
