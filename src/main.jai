#import "Window_Creation";
#import "Basic";
#import "String";
#import "Math";
#import "File";
Simp  :: #import "Simp_Ext";
Input :: #import "Input";

#load "../libs/sqlite.jai";
#load "csv.jai";

window_width : s32 = 1920;
window_height : s32 = 1080;
the_window : Window_Type;

categories: [..] Category;

Category :: struct {
    id: int;
    name: string;
}

Rect :: struct {
    x, y: float;
    w, h: float;
}

Transaction :: struct {
    id: int;
    date: string;
    amount: float64;
    details: string;
    note: string;
    category_id: int;
}

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

// print_db_documents ::(userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
//     new_context: Context;
//     push_context new_context {
//         columns: []*u8 = ---;
//         columns.count = num_cols;
//         columns.data = col_data;

//         for columns {
//             s := from_c_string(it);
//             print("% ", s);
//         }
//         print("\n");
//     } 
//     return SQLITE_OK;
// }

add_category_from_db ::(userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 2);
        ok: bool;

        category := array_add(*categories);
        category.id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        category.name = copy_temporary_string(from_c_string(col_data[1]));
    } 
    return SQLITE_OK;
}


main :: () {
    db : sqlite3;
    err := sqlite3_open("db.sqlite", *db);
    defer sqlite3_close(db);

    if err != SQLITE_OK {
        print("Error opening DB %", err);
        return;
    }

    // Initialise DB
    load_file_at_comptime :: (filename: string) -> string {
        contents, success := read_entire_file(filename);
        assert(success);
        return contents;
    }
    init_sql :: #run load_file_at_comptime("init_db.sql");

    errmsg : *u8;
    result := sqlite3_exec(db, init_sql, null, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
    }
    assert(result == SQLITE_OK);

    sql_select :: "SELECT * FROM Categories;";
    result = sqlite3_exec(db, sql_select, add_category_from_db, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
    }                                                                     
    for categories print("%\n", it);

    // Open file and parse
    contents, success := read_entire_file("ex.csv");
    assert(success);

    transactions : [..]Transaction;
    csv_file := read_csv("ex.csv", ",", 6, num_cols = 7);
    ok: bool;
    for row : csv_file.rows {
        t := array_add(*transactions);    
        t.date = row.fields[1];
        t.amount, ok = parse_float64(*row.fields[6]);
        if !ok then log_error("Couldn't parse amount as float: %\n", row.fields[6]);
        t.details = row.fields[5];
        if contains_nocase(t.details, "pak n save fuel") || contains_nocase(t.details, "bp"){
            t.category_id = 5;
        } else if contains_nocase(t.details, "pak n save") || contains_nocase(t.details, "countdown") {
            t.category_id = 1;
        } else if contains_nocase(t.details, "pizza") || contains_nocase(t.details, "burger") {
            t.category_id = 3;
        } else if contains_nocase(t.details, "swim") {
            t.category_id = 6;
        } else if contains_nocase(t.details, "hotel") {
            t.category_id = 7;
        }
    }

    parse_float64 :: (line: *string) -> value:float64, success:bool {
        token, ok := parse_token(line);
        value: float64;
        if ok value, ok = string_to_float64(token);
        return value, ok;
    }

    // for t : transactions print("%\n", t);

    query_builder: String_Builder;
    init_string_builder(*query_builder);
    print_to_builder(*query_builder, "BEGIN TRANSACTION;\n");
    for t : transactions {
        insert :: #string QUERY
    INSERT INTO Transactions (transaction_date, amount, details, category_id) VALUES ("%", %, %, %);
    QUERY;
        print_to_builder(*query_builder, insert, t.date, t.amount, t.details, t.category_id);
    }
    print_to_builder(*query_builder, "COMMIT;\n");

    query := builder_to_string(*query_builder);
    defer free(query);
    // print("Query: \n%\n", query);

    // result = sqlite3_exec(db, to_c_string(query), null, null, *errmsg);
    // if result != SQLITE_OK {
    //     log_error("Couldn't insert transactions: %\n", from_c_string(errmsg));
    // }    

    the_window = create_window(window_width, window_height, "Expenses");
    window_width, window_height = Simp.get_render_dimensions(the_window);

    Simp.set_render_target(the_window);

    quit : bool;

    while !quit {
        Input.update_window_events();

        for Input.events_this_frame {
            if it.type == .QUIT {
                quit = true;
            }
            if it.type == .KEYBOARD {
                if it.key_pressed == 0 continue;

                if it.key_code == .ESCAPE {
                    quit = true;
                }
            }
        }

        draw_one_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    screen : Rect;
    screen = make_rect(0, 0, xx window_width, xx window_height);
    // draw_rect(screen, color_red);

    Simp.swap_buffers(the_window);
}

make_rect :: (x: float, y: float, width: float, height: float) -> Rect{
    rect : Rect;

    rect.w = width;
    rect.h = height;
    rect.x = x;
    rect.y = y;

    return rect;
}

draw_rect :: (r: Rect, color: Vector4) {
    using r;
    Simp.set_shader_for_color();
    Simp.immediate_quad(x, y, x + w, y + h, color);
}

