CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '000'
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

INSERT OR IGNORE INTO Categories(id, name, color) VALUES(1, "Food", "540d6e");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(2, "Rent", "ee4266");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(3, "Cafe", "ffd23f");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(4, "School", "3bceac");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(5, "Fuel", "0ead69");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(6, "Swimming", "1a8fe3");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(7, "Holiday accomodation", "f17105");


-- INSERT INTO Transactions(amount, details, category_id) VALUES(100.45, "RENT", 2);