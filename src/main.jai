main :: () {
    #if OS == .WINDOWS {
        // Windows is very bad at thread-switching by default unless you do this. Sad.
        timeBeginPeriod(1);
    }

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

    window = create_window(window_width, window_height, "Expenses");
    platform_maximize_window(window);
    window_width, window_height = Simp.get_render_dimensions(window);
    print("Window %#v", window);
    dpi_scale = platform_get_dpi_scale(window);
    init_fonts();

    screen  = make_rect(0, 0, window_width, window_height);
    Simp.set_render_target(window);

    quit : bool;
    while !quit {
        Input.update_window_events();

        for Input.get_window_resizes() {
            Simp.update_window(it.window);
            if (it.window == window) {
                should_reinit := (it.width != window_width) || (it.height != window_height);
                window_width = it.width;
                window_height = it.height;
                if should_reinit {
                    screen = make_rect(0, 0, window_width, window_height);
                    dpi_scale = platform_get_dpi_scale(window);
                    init_fonts();
                }
            }
        }

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

platform_maximize_window :: (window: Window_Type) {
    ShowWindow(window, SW_MAXIMIZE);
}

platform_get_dpi_scale :: (window: Window_Type) -> float {
    #assert OS == .WINDOWS;
    dpi := cast(float) GetDpiForWindow(window);
    return dpi / 96.0;
}

draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    categories_rect := cut_left(screen, 500 * dpi_scale);
    draw_rect(categories_rect, Colors.BACKGROUND_LIGHT);

    // Print categories
    for categories {
        Simp.draw_text(font, xx (categories_rect.x + 10 * dpi_scale), xx (categories_rect.y + categories_rect.h - line_height * it_index), it.name, Colors.UI_DEFAULT);
    }

    Simp.swap_buffers(window);
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

init_fonts :: () {
    font = Simp.get_font_at_size("fonts", "FiraCode-Retina.ttf", cast(int) (font_size * dpi_scale));
    assert(font != null, "Couldn't init main text font\n");
    char_size   = cast(float) font.em_width;
    line_height = cast(float) font.default_line_spacing * LINE_HEIGHT_SCALE;

    font_ui = Simp.get_font_at_size("fonts", "SEGOEUI.TTF", cast(int) (font_ui_size * dpi_scale));
    assert(font_ui != null, "Couldn't init main ui font\n");
    font_ui_line_height = cast(float) font_ui.default_line_spacing;

    font_ui_bold = Simp.get_font_at_size("fonts", "SEGUISB.TTF", cast(int) (font_ui_size * dpi_scale));
    assert(font_ui_bold != null, "Couldn't init bold ui font\n");

    font_ui_small = Simp.get_font_at_size("fonts", "SEGOEUI.TTF", cast(int) (font_ui_small_size * dpi_scale));
    // font_ui_small = Simp.get_font_at_size("fonts", "SEGUISB.TTF", cast(int) (font_ui_small_size * dpi_scale));
    assert(font_ui_small != null, "Couldn't init main ui font\n");
    font_ui_small_line_height = cast(float) font_ui.default_line_spacing;

    font_icons = Simp.get_font_at_size("fonts/font-awesome", "Font Awesome 6 Free-Solid-900.otf", cast(int) (font_icons_size * dpi_scale));
    assert(font_icons != null, "Couldn't init main icon font\n");

    // WORKAROUND:
    // Make a dummy call with most common chars for each font so that
    // we have all the font atlases loaded in the GPU memory once
    COMMON_CHARS :: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 ~!@#$%^&*()-|\"':;_+={}[]\\/`,.<>?АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧЩЪЫЬЭЮЯабвгдеёжзийклмнопрстуфхцчщъыьэюя";
    Simp.prepare_text(font,          COMMON_CHARS);
    Simp.prepare_text(font_ui,       COMMON_CHARS);
    Simp.prepare_text(font_ui_bold,  COMMON_CHARS);
    Simp.prepare_text(font_ui_small, COMMON_CHARS);
    // TODO: prepare icons as well
}

window_width : s32 = 1920;
window_height : s32 = 1080;
window : Window_Type;

char_size:   float;
line_height: float;

LINE_HEIGHT_SCALE :: 1.2;

WHEEL_SENSITIVITY :: 1.0;

font      :  *Simp.Dynamic_Font;
font_size := 14;

font_ui      :  *Simp.Dynamic_Font;
font_ui_bold :  *Simp.Dynamic_Font;
font_ui_size := 16;
font_ui_line_height: float;

font_ui_small      :  *Simp.Dynamic_Font;
font_ui_small_size := 15;
font_ui_small_line_height: float;

font_icons      : *Simp.Dynamic_Font;
font_icons_size := 16;

Mods :: Input.Event.Modifier_Flags;

categories: [..] Category;

Category :: struct {
    id: int;
    name: string;
}

Transaction :: struct {
    id: int;
    date: string;
    amount: float64;
    details: string;
    note: string;
    category_id: int;
}

screen: Rect;  // contains the current working area rect for convenience
dpi_scale := 1.0;

mouse: Mouse_State;

Mouse_State :: struct {
    pointer: Vector2;
    scroll_y_delta: s32;

    left:   Mouse_Button_State;
    right:  Mouse_Button_State;
    middle: Mouse_Button_State;
}

Mouse_Button_State :: struct {
    is_down:             bool;
    is_dragging:         bool;
    just_pressed:        bool;
    just_released:       bool;
    just_double_clicked: bool;

    last_down_pos:  Vector2;
    last_down_time: Time;
}

Time :: #type,isa float64;

#import "Windows";
#import "Window_Creation";
#import "Basic";
#import "String";
#import "Math";
#import "File";
Simp  :: #import "Simp_Ext";
Input :: #import "Input";

#load "../libs/sqlite.jai";
#load "csv.jai";
#load "layout.jai";
#load "draw.jai";
#load "style.jai";

user32 :: #foreign_system_library "user32";
GetDpiForWindow :: (hWnd: HWND) -> u32 #foreign user32;
