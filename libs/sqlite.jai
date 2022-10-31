#if OS == .WINDOWS {
    // sqlite :: #foreign_library "win/libcurl";
} else #if OS == .LINUX {
    sqlite :: #foreign_library "sqlite3";
}

sqlite3 :: #type,distinct *void;


sqlite3_open :: (filename: *u8, ppDb: *sqlite3) -> int #foreign sqlite;

sqlite3_close :: (db: sqlite3) -> int #foreign sqlite;

SQLITE_OK :: 0;