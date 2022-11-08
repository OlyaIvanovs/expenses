CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS Transactions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    transaction_date TEXT,
    amount REAL DEFAULT 0,
    details TEXT NOT NULL,
    note TEXT,
    category_id INTEGER,
    FOREIGN KEY (category_id) 
        REFERENCES Categories (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION
);

INSERT OR IGNORE INTO Categories(id, name) VALUES(1, "Food");
INSERT OR IGNORE INTO Categories(id, name) VALUES(2, "Rent");
INSERT OR IGNORE INTO Categories(id, name) VALUES(3, "Cafe");
INSERT OR IGNORE INTO Categories(id, name) VALUES(4, "School");
INSERT OR IGNORE INTO Categories(id, name) VALUES(5, "Fuel");
INSERT OR IGNORE INTO Categories(id, name) VALUES(6, "Swimming");
INSERT OR IGNORE INTO Categories(id, name) VALUES(7, "Holiday accomodation");


-- INSERT INTO Transactions(amount, details, category_id) VALUES(100.45, "RENT", 2);