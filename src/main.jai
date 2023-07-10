main :: () {
    #if OS == .WINDOWS {
        // Windows is very bad at thread-switching by default unless you do this. Sad.
        timeBeginPeriod(1);
    }
    
    err := sqlite3_open("db.sqlite", *db);
    if err != SQLITE_OK {
        print("Error opening DB %", err);
        return;
    }
    defer sqlite3_close(db);

    ok := initialise_db();
    if !ok return;
    
    ok = get_all_categories_from_db();
    if !ok return;
    categories_list.edit = -1;
    categories_list.delete = -1;
    
    for categories_list.categories table_set(*show_categories_table, it.id, false);
    
    current_year = to_calendar(current_time_consensus()).year;
    graph_details.year = current_year;
    graph_details.category_id = -1;
    graph_details.type = .weekly;
    
    daily_spendings, ok = get_daily_spendings(0);
    if !ok return;
    get_max_spending(*daily_spendings);
    
    monthly_spendings, ok = get_monthly_spendings_for_last_3_years();
    if !ok return;
    get_max_spending(*monthly_spendings);
    
    ok = get_all_transactions_from_db();
    if !ok return;
    update_settings_transactions();
    settings_transactions.edit = -1;
    settings_transactions.delete = -1;
    
    weekly_dashboard_transactions.type = .weekly;
    update_transactions_on_dashboard(*weekly_dashboard_transactions);
    
    monthly_dashboard_transactions.chosen_period = -1;
    monthly_dashboard_transactions.type = .monthly;
    update_transactions_on_dashboard(*monthly_dashboard_transactions);    

    ok = get_all_rules_from_db();
    if !ok return;
    rules_list.edit = -1;
    rules_list.delete = -1;
    rules_list.category_filter = -1;
    rules_list.name_sort = .ascending;
    update_filtered_rules();
    
    // Window
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
        if !redraw_requested platform_wait_message();
        redraw_requested = false;
        enter_pressed = false;
        key_pressed = false;
        
        current_year = to_calendar(current_time_consensus()).year;
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
                    key_pressed = true;
                    
                    if event.key_pressed == 0 continue;

                    if event.key_code == .ESCAPE {
                        set_null_state();
                    }
                    
                    if event.key_code == .ENTER {
                        enter_pressed = true;
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
        sleep_milliseconds(1);
        reset_temporary_storage();
    }
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
    
    mouse.scroll_y_delta = cast(s32) (cast(float) Input.mouse_delta_z);

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

CIRCLE_RESOLUTION :: 100;
show_categories_table: Table(int, bool);
daily_spendings: Period_Spendings;
monthly_spendings: Period_Spendings;

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

program_state: Program_State = .dashboard;
Program_State :: enum {
    dashboard;
    something_else;
    settings;
}

show_all_categories_on_graph := 1;

List_Info :: struct {
    scroll_delta: float;
    scroll_to_bottom: bool;
    edit: int;
    add: bool;
    delete: int;
    update: bool;
} 

rules_list : struct {
    rules: [..]Rule;
    filtered_rules: [..]Rule;
    using info: List_Info;
    show_category_dropdown: bool;
    category_filter: int;
    name_sort: sort_direction;
};
Rule :: struct {
    id: int;
    name: string;
    category_id: int;
}
new_rule := Rule.{name="", category_id=0};

categories_list : struct {
    categories: [..]Category;
    scroll_delta_dashboard: float;
    using info: List_Info;
}
Category :: struct {
    id: int;
    name: string;
    color: string;
}
new_category := Category.{name="", color="e3a019"};

settings_transactions : struct {
    // transactions: [..]Transaction;
    subtotal: float64;
    using info: List_Info;
    remove_all: bool;
}
new_transaction := Transaction.{details="", note="", category_id=0, amount=0.0, date=""};

transactions_raw: [..]Transaction;
transactions_filtered: [..]Transaction;
transactions: [..]Transaction;
Transaction :: struct {
    id: int;
    date: string;
    amount: float64;
    details: string;
    note: string;
    category_id: int;
}

Transactions_List :: struct {
    transactions: [..]Transaction;
    type: graph_type;
    update: bool;
    scroll_delta: float;
    chosen_period: int;
    subtotal: float64;
}
weekly_dashboard_transactions: Transactions_List;
monthly_dashboard_transactions: Transactions_List;

Spending :: struct {
    category_id: int;
    total_spent: float64;
    color: string;
    category: string;
}
Period_Spendings :: struct {
    spendings: [..] Spending;
    period_indices: [..] s64;
    max_spending: float64;
}

screen: Rect;  // contains the current working area rect for convenience
dpi_scale := 1.0;
padding :: #run 4 * dpi_scale;

MAX_BUTTON_SIZE ::  #run 250 * dpi_scale;
LINE_HEIGHT :: #run 36 * dpi_scale;

enter_pressed := false;
key_pressed := false;

frame_time: Time;
redraw_requested := true;

db : sqlite3;  // initialised at the start

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

Color_Picker :: struct {
    hsv:  HSV;
    load: bool;
} 

HSV :: struct {
    hue:        float;
    saturation: float;
    value:      float;
}  
color_picker := Color_Picker.{
    hsv.hue        = 0,
    hsv.saturation = 0,
    hsv.value      = 0,
};


sort_direction :: enum int {
    ascending  :: 1;
    none       :: 0;
    descending :: -1;
};

transaction_filter : struct {
    transactions_search: string  = "";
    category_filter: int         = -1;
    amount_sort: sort_direction = .none;
    date_sort: sort_direction = .none;  
};

graph_type :: enum {
    weekly;
    monthly;
}

current_year: int;

graph_details : struct {
    year: int;
    category_id: int;
    active_transaction: int;
    type: graph_type;
};

Message :: struct {
    show: bool;
    text: string;
    time_start: Time;
}
message := Message.{show=false};
    
Time :: #type,isa float64;

MAX_FRAME_DT :: 1.0 / 60;

only_ctrl_pressed :: inline (mods: Mods) -> bool { return mods.packed == MODS_CTRL_ONLY; }
only_alt_pressed  :: inline (mods: Mods) -> bool { return mods.packed == MODS_ALT_ONLY; }

MODS_CTRL_ONLY :: #run Mods.{ ctrl_pressed = true }.packed;
MODS_ALT_ONLY  :: #run Mods.{ alt_pressed  = true }.packed;

shift_pressed :: inline () -> bool {
    return key_state(.SHIFT) & .DOWN != 0;
}

ctrl_pressed :: inline () -> bool {
    return key_state(.CTRL) & .DOWN != 0;
}

#import "Windows";
#import "Window_Creation";
#import "Basic";
#import "String";
#import "Math";
#import "File";
#import "Sort";
#import "Unicode";
#import "Hash_Table";
Simp  :: #import "Simp_Ext";
Input :: #import "Input";
Clipboard :: #import "Clipboard";

#load "../libs/sqlite.jai";
#load "csv.jai";
#load "sql.jai";
#load "layout.jai";
#load "draw.jai";
#load "unicode.jai";
#load "style.jai";
#load "utils.jai";
#load "pointer_image.jai";
#load "windows.jai";
#load "widgets/text_input.jai";

user32 :: #foreign_system_library "user32";
GetDpiForWindow :: (hWnd: HWND) -> u32 #foreign user32;

DOUBLE_CLICK_SPEED     :: 0.3;  // how many seconds between clicks to consider it a double click
DOUBLE_CLICK_TOLERANCE :: 2;    // how many pixels between the click locations are allowed
