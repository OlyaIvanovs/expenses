CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    color TEXT DEFAULT '000'
);

CREATE TABLE IF NOT EXISTS Rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    category_id INTEGER,
    FOREIGN KEY (category_id) 
        REFERENCES Categories (id)
            ON DELETE SET NULL
            ON UPDATE NO ACTION
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

INSERT OR IGNORE INTO Categories(id, name, color) VALUES(0, "UNCATEGORISED", "540d11");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(1, "Food", "540d6e");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(2, "Rent", "ee4266");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(3, "Cafe", "ffd23f");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(4, "School", "3bceac");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(5, "Fuel", "0ead69");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(6, "Swimming", "1a8fe3");
INSERT OR IGNORE INTO Categories(id, name, color) VALUES(7, "Holiday accomodation", "f17105");

INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(1, "fuel", 5);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(2, "bp", 5);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(3, "pak n save", 1);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(4, "countdown", 1);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(5, "pizza", 3);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(6, "Donalds", 3);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(7, "KFC", 3);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(8, "Burger", 3);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(9, "Dominos", 3);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(10, "Swim", 6);
INSERT OR IGNORE INTO Rules(id, name, category_id) VALUES(11, "hotel", 7);
