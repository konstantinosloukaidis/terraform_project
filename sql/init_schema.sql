CREATE TABLE IF NOT EXISTS operator (
    id SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    age INT,
    height FLOAT,
    full_name TEXT,
    coalition TEXT
);

-- Optional seed data
INSERT INTO operator (name, age, height, full_name, coalition)
VALUES ('Sledge', 42, 1.94, 'Scrooge McDuck', 'Rainbow');

INSERT INTO operator (name, age, height, full_name, coalition)
VALUES ('Kali', 34, 1.77, 'Jaimini Kalimohan Shah', 'Nighthaven');