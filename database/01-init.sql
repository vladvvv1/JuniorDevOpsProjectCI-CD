DROP TABLE IF EXISTS photo_categories CASCADE;
DROP TABLE IF EXISTS photos CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS contact_messages CASCADE;
DROP TABLE IF EXISTS users CASCADE;

CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    id INT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    slug VARCHAR(100)
);

CREATE TABLE photos (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMPTZ,
    url VARCHAR(500) NOT NULL,
    user_id VARCHAR(255),
    title VARCHAR(255),
    description TEXT
);

CREATE TABLE photo_categories (
    photo_id VARCHAR(255) REFERENCES photos(id) ON DELETE CASCADE,
    category_id INT REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (photo_id, category_id)
);

CREATE TABLE contact_messages (
    id VARCHAR(255) PRIMARY KEY,
    created_at TIMESTAMPTZ,
    name VARCHAR(255),
    email VARCHAR(255),
    message TEXT
);

INSERT INTO users (email, password_hash)
VALUES ('admin@example.com', '$2b$10$YourHashedPasswordHere')
ON CONFLICT (email) DO NOTHING;