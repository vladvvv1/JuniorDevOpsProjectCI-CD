\copy categories(id, name) FROM 'csv_data/categories.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
UPDATE categories SET slug = LOWER(name) WHERE slug IS NULL;
\copy photos(id, created_at, url, user_id) FROM 'csv_data/photos.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy photo_categories(photo_id, category_id) FROM 'csv_data/photo_categories.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');
\copy contact_messages(id, created_at, name, email, message) FROM 'csv_data/contact_messages.csv' WITH (FORMAT csv, HEADER true, DELIMITER ',');