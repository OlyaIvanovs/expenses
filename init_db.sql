CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Transactions (
    id INTEGER PRIMARY KEY,
    amount REAL DEFAULT 0,
    details TEXT NOT NULL,
    note TEXT,
    category_id INTEGER,
    FOREIGN KEY (category_id) 
        REFERENCES Categories (id)
            ON DELETE CASCADE
            ON UPDATE NO ACTION
);