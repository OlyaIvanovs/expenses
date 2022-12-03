main :: () {
    #if OS == .WINDOWS {
        // Windows is very bad at thread-switching by default unless you do this. Sad.
        timeBeginPeriod(1);
    }

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
    // for categories print("%\n", it);

    ok1: bool;
    daily_spendings, ok1 = get_daily_spendings();
    if !ok1 return;

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
        } else if contains_nocase(t.details, "pizza") || contains_nocase(t.details, "Donalds") || contains_nocase(t.details, "KFC") || contains_nocase(t.details, "burger") || contains_nocase(t.details, "DOMINOS") {
            t.category_id = 3;
        } else if contains_nocase(t.details, "swim") {
            t.category_id = 6;
        } else if contains_nocase(t.details, "hotel") {
            t.category_id = 7;
        }
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
    // result = sqlite3_exec(db, to_c_string(query), null, null, *errmsg);
    // if result != SQLITE_OK {
    //     log_error("ERROR: %\n",from_c_string(errmsg));
    // }

    window_x, window_y := platform_get_biggest_monitor_pos();
    window = create_window(window_width, window_height, "Expenses", window_x, window_y, background_color_rgb = as_3_floats(Colors.BACKGROUND));
    platform_maximize_window(window);
    window_width, window_height = Simp.get_render_dimensions(window);
    dpi_scale = platform_get_dpi_scale(window);
    init_fonts();

    screen  = make_rect(0, 0, window_width, window_height);
    Simp.set_render_target(window);

    quit : bool;
    while !quit {
        frame_time = cast(Time) get_time();
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

        update_mouse_state();

        for event : Input.events_this_frame {
            if event.type == {
                case .QUIT;  quit = true;

                case .KEYBOARD;
                    if event.key_pressed == 0 continue;

                    if event.key_code == .ESCAPE {
                        quit = true;
                    }

                    // TMP
                    text_input_handle_keypress(*text_input, event.key_code, event.modifier_flags);

                case .TEXT_INPUT;
                    char := cast,trunc(u8) event.utf32;
                    if char > 31 && char < 127 {
                        // TMP
                        text_input_type_char(*text_input, char);
                    }
            }
        }

        draw_one_frame();
        pointer_end_frame();
        sleep_milliseconds(10);
        reset_temporary_storage();
    }
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

parse_float64 :: (line: *string) -> value:float64, success:bool {
    token, ok := parse_token(line);
    value: float64;
    if ok value, ok = string_to_float64(token);
    return value, ok;
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

key_state :: inline (key: Input.Key_Code) -> Input.Key_Current_State {
    return Input.input_button_states[key];
}

update_mouse_state :: () {
    x, y := get_mouse_pointer_position(window, false);
    mouse.pointer.x = xx x;
    mouse.pointer.y = xx (window_height - y);

    update_button(*mouse.left,   .MOUSE_BUTTON_LEFT);
    update_button(*mouse.right,  .MOUSE_BUTTON_RIGHT);
    update_button(*mouse.middle, .MOUSE_BUTTON_MIDDLE);

    update_button :: (button: *Mouse_Button_State, key: Input.Key_Code) {
        button.is_down       = key_state(key) & .DOWN  != 0;  // NOTE: this doesn't include just_pressed!
        button.just_pressed  = key_state(key) & .START != 0;
        button.just_released = key_state(key) & .END   != 0;

        if button.just_pressed {
            time_from_last_click := frame_time - button.last_down_time;
            distance_from_last_click := mouse.pointer - button.last_down_pos;
            max_distance := max(abs(distance_from_last_click.x), abs(distance_from_last_click.y));
            button.just_double_clicked = time_from_last_click < DOUBLE_CLICK_SPEED && max_distance < DOUBLE_CLICK_TOLERANCE;
            button.last_down_pos  = mouse.pointer;
            button.last_down_time = frame_time;
        } else {
            button.just_double_clicked = false;
        }

        button.is_dragging   = button.is_down && mouse.pointer != button.last_down_pos;
    }
}

panic :: (format_string: string, args: .. Any, exit_code : s32 = 1) {
    log_error(format_string, ..args);
    exit(exit_code);
} @PrintLike

daily_spendings: Daily_Spendings;

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

program_state: Program_State = .settings;

Program_State :: enum {
    dashboard;
    something_else;
    settings;
}

Category :: struct {
    id: int;
    name: string;
}

Spending :: struct {
    category_id: int;
    total_spent: float64;
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

frame_time: Time;

mouse: Mouse_State;

db : sqlite3;  // initialised at the start

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

MAX_FRAME_DT :: 1.0 / 60;

only_ctrl_pressed :: inline (mods: Mods) -> bool { return mods.packed == MODS_CTRL_ONLY; }
only_alt_pressed  :: inline (mods: Mods) -> bool { return mods.packed == MODS_ALT_ONLY; }

MODS_CTRL_ONLY :: #run Mods.{ ctrl_pressed = true }.packed;
MODS_ALT_ONLY  :: #run Mods.{ alt_pressed  = true }.packed;

#import "Windows";
#import "Window_Creation";
#import "Basic";
#import "String";
#import "Math";
#import "File";
Simp  :: #import "Simp_Ext";
Input :: #import "Input";
Clipboard :: #import "Clipboard";

#load "../libs/sqlite.jai";
#load "csv.jai";
#load "sql.jai";
#load "layout.jai";
#load "draw.jai";
#load "style.jai";
#load "utils.jai";
#load "pointer_image.jai";
#load "windows.jai";
#load "widgets/text_input.jai";

user32 :: #foreign_system_library "user32";
GetDpiForWindow :: (hWnd: HWND) -> u32 #foreign user32;

DOUBLE_CLICK_SPEED     :: 0.3;  // how many seconds between clicks to consider it a double click
DOUBLE_CLICK_TOLERANCE :: 2;    // how many pixels between the click locations are allowed
