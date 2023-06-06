// to_string :: (bytes: [] u8) -> string {
//     s: string = ---;
//     s.data  = bytes.data;
//     s.count = bytes.count;
//     return s;
// }

from_c_string ::(s: *u8) -> string {
    count: s64 = 0;
    q := s;
    while <<q {
        count += 1;
        q += 1;
    }

    str: string = ---;
    str.data = s;
    str.count = count;

    return str;
}

parse_float64 :: (line: *string) -> value:float64, success:bool {
    token, ok := parse_token(line);
    value: float64;
    if ok value, ok = string_to_float64(token);
    return value, ok;
}

array_remove_slice :: (array: *[] u8, start: s64, count: s64) {
    assert(start >= 0 && start + count <= array.count);
    memcpy(array.data + start, array.data + start + count, count);
    array.count -= count;
}

array_insert_slice :: (array: *[..] u8, start: s64, slice: [] u8) {
    assert(start  >= 0);
    old_count := array.count;
    array_resize(array, array.count + slice.count);

    end : [] u8 = ---;
    end.data = array.data + start;
    end.count = old_count - start;
    end = array_copy_into_temp(end);

    memcpy(array.data + start, slice.data, slice.count);
    memcpy(array.data + start + slice.count, end.data, end.count);
}

array_copy_into_temp :: (array: [] $T) -> [] T {
    dest := NewArray(array.count, T, initialized=false, allocator=temp);
    memcpy(dest.data, array.data, array.count * size_of(T));
    return dest;
}

// Windows
get_upload_file_name :: () -> string /* temp */, success: bool {
    buffer: [512] u16;

    ofn: OPENFILENAMEW;
    ofn.lStructSize = size_of(OPENFILENAMEW);
    ofn.hwndOwner   = window;
    ofn.lpstrFile   = buffer.data;
    ofn.nMaxFile    = buffer.count;
    ofn.lpstrTitle  = utf8_to_wide("Choose file to upload");
    ofn.Flags       = OFN_NOCHANGEDIR;

    open_success := GetOpenFileNameW(*ofn);

    if open_success {
        file_path, success := wide_to_utf8(buffer.data);
        path_overwrite_separators(file_path, #char "/");

        if success {
            return file_path, success;
        }
    }
    return "", false;
}


// Upload transactions
upload_transactions_from_file :: (file_name: string) -> bool {
    contents, success := read_entire_file(file_name);
    assert(success);

    csv_file := read_csv(file_name, ",", 6, num_cols = 7);
    ok: bool;
    for row : csv_file.rows {
        t := array_add(*transactions_raw);
        t.date = row.fields[1];
        t.amount, ok = parse_float64(*row.fields[6]);
        if !ok then log_error("Couldn't parse amount as float: %\n", row.fields[6]);
        t.details = row.fields[5];
        if contains_nocase(t.details, "pak n save fuel") || contains_nocase(t.details, "bp"){
            t.category_id = 5;
        } else if contains_nocase(t.details, "pak n save") || contains_nocase(t.details, "countdown") {
            t.category_id = 1;
        } else if contains_nocase(t.details, "pizza") || contains_nocase(t.details, "Donalds") || contains_nocase(t.details, "KFC") || contains_nocase(t.details, "burger") || contains_nocase(t.details, "DOMINOS") {
            t.category_id = 3;
        } else if contains_nocase(t.details, "swim") {
            t.category_id = 6;
        } else if contains_nocase(t.details, "hotel") {
            t.category_id = 7;
        }
    }

    query_builder: String_Builder;
    init_string_builder(*query_builder);
    print_to_builder(*query_builder, "BEGIN TRANSACTION;\n");
    for t : transactions_raw {
        if t.amount < 0 then continue; // do not include income
        insert :: #string QUERY
    INSERT INTO Transactions (transaction_date, amount, details, category_id) VALUES ("%", %, %, %);
    QUERY;
        print_to_builder(*query_builder, insert, t.date, t.amount, t.details, t.category_id);
    }
    print_to_builder(*query_builder, "COMMIT;\n");

    query := builder_to_string(*query_builder);
    defer free(query);
    
    errmsg : *u8;
    result := sqlite3_exec(db, to_c_string(query), null, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    
    return true;
}


#import "Windows_Utf8";
#import "Windows";
