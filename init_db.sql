CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    amount REAL DEFAULT 0,
    details TEXT NOT NULL,
    note TEXT,
    category_id INTEGER,
    FOREIGN KEY (category_id) 
        REFERENCES Categories (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION
);

INSERT OR IGNORE INTO Categories(name) VALUES("Food");
INSERT OR IGNORE INTO Categories(name) VALUES("Rent");
INSERT OR IGNORE INTO Categories(name) VALUES("Cafe");
INSERT OR IGNORE INTO Categories(name) VALUES("School");


-- INSERT INTO Transactions(amount, details, category_id) VALUES(100.45, "RENT", 2);