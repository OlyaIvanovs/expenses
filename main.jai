#import "Window_Creation";
#import "Basic";
#import "Math";
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

print_db_documents ::(userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        print("num_cols: %", num_cols);
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

    sql_string :: #string DONE
CREATE TABLE IF NOT EXISTS Categories (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE
);
DONE
    errmsg : *u8;
    result := sqlite3_exec(db, sql_string, null, null, *errmsg);
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


        
    the_window = create_window(window_width, window_height, "Expenses", background_color_rgb = float.[.55, .01, .9]);
    window_width, window_height = Simp.get_render_dimensions(the_window);

    Simp.set_render_target(the_window);

    quit : bool;

    while !quit {
        Input.update_window_events();

        for Input.events_this_frame {
            if it.type == .QUIT {
                quit = true;
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

