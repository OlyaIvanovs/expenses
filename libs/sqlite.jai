
sqlite3 :: #type,distinct *void;
Exec_Callback :: #type (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call;


sqlite3_open :: (filename: *u8, ppDb: *sqlite3) -> int #foreign sqlite;

sqlite3_close :: (db: sqlite3) -> int #foreign sqlite;

sqlite3_exec :: (db: sqlite3, sql: *u8, callback: Exec_Callback, userdata: *void, errmsg: **u8) -> int #foreign sqlite;

SQLITE_OK :: 0;


#scope_file

sqlite :: #foreign_library "../sqlite3";
