#import "Window_Creation";
#import "Basic";
#import "Math";
#import "File";
Simp :: #import "Simp";
Input :: #import "Input";

#load "libs/sqlite.jai";

window_width : s32 = 1920;
window_height : s32 = 1080;
the_window : Window_Type;

Rect :: struct {
    x, y: float;
    w, h: float;
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

print_db_documents ::(userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        columns: []*u8 = ---;
        columns.count = num_cols;
        columns.data = col_data;

        for columns {
            s := from_c_string(it);
            print("% ", s);
        }
        print("\n");
    } 
    return SQLITE_OK;
}

color_1 : Vector4 = .{0.13, 0.15, 0.18, 1};
color_red : Vector4 = .{1, 0, 0, 1};

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
        print("ERROR: %\n",from_c_string(errmsg));
    }
    assert(result == SQLITE_OK);
    
    // categories := string.["food", "cloth", "school"];
    // sql_str: string;
    // for categories {
    //     sql_str = sprint("INSERT INTO Categories (id, name) VALUES (%, \"%\");", it_index, it);
    //     result = sqlite3_exec(db, to_c_string(sql_str), null, null, *errmsg);
    //     assert(result == SQLITE_OK);
    // }

    sql_select :: #string DONE
SELECT * FROM Categories;
DONE
    result = sqlite3_exec(db, sql_select, print_db_documents, null, *errmsg);


        
    // the_window = create_window(window_width, window_height, "Expenses", background_color_rgb = float.[.55, .01, .9]);
    // window_width, window_height = Simp.get_render_dimensions(the_window);

    // Simp.set_render_target(the_window);

    // quit : bool;

    // while !quit {
    //     Input.update_window_events();

    //     for Input.events_this_frame {
    //         if it.type == .QUIT {
    //             quit = true;
    //         }
    //     }

    //     draw_one_frame();
    //     sleep_milliseconds(10);
    //     reset_temporary_storage();
    // }
}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    screen : Rect;
    screen = make_rect(0, 0, xx window_width, xx window_height);
    draw_rect(screen, color_red);

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

