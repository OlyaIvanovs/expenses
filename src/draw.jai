draw_one_frame :: () {
    {
        using Colors.BACKGROUND;
        Simp.clear_render_target(r, g, b, a);
    }

    tabs_rect, main_area := cut_top(screen, 50 * dpi_scale);
    draw_rect(tabs_rect, Colors.BACKGROUND_DARK);

    // Draw tabs
    {
        margin := 10 * dpi_scale;
        tabs_rect = shrink_x(tabs_rect, margin);
        tabs_rect.h -= margin;

        // Dashboard tab
        {
            ui_id := get_ui_id_from_loc();

            width := cast(float) Simp.prepare_text(font_ui_bold, "Dashboard");
            tab_rect := cut_left(tabs_rect, width + margin * 2);

            became_active := maybe_set_hot_or_active(ui_id, tab_rect, .PRESSABLE);
            if became_active then program_state = .dashboard;
            color := Colors.BACKGROUND;
            if program_state == .dashboard {
                color = Colors.BACKGROUND_LIGHT;
            }

            draw_rect(tab_rect, color);

            text_color := Colors.UI_DEFAULT;
            if program_state == .settings {
                text_color = Colors.UI_DIM;
            }
            pen := make_vector2(tab_rect.x + margin, tab_rect.y + (tab_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, text_color);
        }

        // Settings tab
        {
            ui_id := get_ui_id_from_loc();

            width := cast(float) Simp.prepare_text(font_ui_bold, "Settings");
            tab_rect := cut_right(tabs_rect, width + margin * 2);

            color := Colors.BACKGROUND;
            became_active := maybe_set_hot_or_active(ui_id, tab_rect, .PRESSABLE);
            if became_active then program_state = .settings;

            if program_state == .settings {
                color = Colors.BACKGROUND_LIGHT;
            }

            draw_rect(tab_rect, color);

            text_color := Colors.UI_DEFAULT;
            if program_state == .dashboard {
                text_color = Colors.UI_DIM;
            }

            pen := make_vector2(tab_rect.x + margin, tab_rect.y + (tab_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, text_color);
        }
    }

    if program_state == {
        case .dashboard;        draw_dashboard(main_area);
        // case .something_else;
        case .settings;         draw_settings(main_area);
    }

    // Reset UI state after drawing
    if !mouse.left.is_down || mouse.left.just_released {
        ui.active = .none;
    } else if ui.active == .none {
        ui.active = .unavailable;  // so that we don't activate anything by dragging on it
    }
    ui.hot_last_frame = ui.hot;
    ui.hot = .none;

    Simp.swap_buffers(window);
}

draw_dashboard :: (main_area: Rect) {
    categories_rect, main_area := cut_left(main_area, 300 * dpi_scale);
    draw_rect(categories_rect, Colors.BACKGROUND_LIGHT);

    // Print categories
    for categories {
        Simp.draw_text(font, xx (categories_rect.x + 10 * dpi_scale), xx (categories_rect.y + categories_rect.h - (line_height * (it_index + 1))), it.name, Colors.UI_DEFAULT);
    }

    // Draw spendings
    {
        using daily_spendings;

        main_area = shrink(main_area, 50);
        draw_rect(main_area, Colors.BACKGROUND_HIGHLIGHT);

        padding := 4 * dpi_scale;
        bar_rect := cut_left(main_area, (main_area.w / 52) - padding);

        for i : 0 .. week_indices.count - 2 {
            start := week_indices[i];
            end   := week_indices[i + 1];
            num_spendings := end - start;
            week_spendings := array_view(spendings, start, num_spendings);
            weekly_total: float64;
            for spending : week_spendings {
                weekly_total += spending.total_spent;
            }

            // base rect
            week_rect := bar_rect;
            week_rect.x += i * (bar_rect.w + padding);
            week_rect.h = xx (bar_rect.h * (weekly_total / 2000.0));
            draw_rect(week_rect, Colors.RED);

            // draw categories
            y: float32;
            c := Color.[Colors.GREEN, Colors.YELLOW, Colors.BLUE, Colors.CYAN];
            for spending, i : week_spendings {
                if i == 0 continue;
                rect := week_rect;
                rect.h = xx (week_rect.h * (spending.total_spent / weekly_total));
                rect.y += y;
                y += rect.h;
                index := i % 4;
                draw_rect(rect, c[index]);
            }
        }
    }
}

draw_settings :: (main_area: Rect) {
    padding := 4 * dpi_scale;  // TODO: make global?
    new_category := -1;

    draw_rect(main_area, Colors.BACKGROUND_LIGHT);
    categories_rect : Rect;
    pad, main_area := cut_left(main_area, 30 * dpi_scale);
    categories_rect, main_area = cut_left(main_area, 300 * dpi_scale);

    title_rect : Rect;
    title_rect, categories_rect = cut_top(categories_rect, 50 * dpi_scale);
    draw_rect(title_rect, Colors.BACKGROUND_LIGHT);

    title_bottomline := title_rect;
    title_bottomline.h = 3 * dpi_scale;
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);

    width := cast(float) Simp.prepare_text(font_ui_bold, "Categories");
    pen := make_vector2((title_rect.w - width)/2, title_rect.y + (title_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, Colors.UI_DEFAULT);

    // @review
    // Print categories
    rect : Rect;
    parent_id := get_ui_id_from_loc();
    for categories {
        draw_icon : bool;
        rect, categories_rect = cut_top(categories_rect, 36 * dpi_scale);
        draw_rect(rect, Colors.BACKGROUND_LIGHT);
        if !it.new {
            bottomline := rect;
            bottomline.h = 1 * dpi_scale;
            draw_rect(bottomline, Colors.SELECTION_ACTIVE);
            
             // Add 'remove' button on hover
            if mouse_pointer_is_within(rect) {
                draw_icon = true;
             }
            
            icon : Rect;
            icon, rect = cut_right(rect, 12 * dpi_scale);
            width := cast(float) Simp.prepare_text(font, it.name);
            pen := make_vector2(rect.x + 5 * dpi_scale, rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);

            // Add 'remove' button on hover
            if draw_icon {
                trash_icon_unicode := 0xf1f8;
                icon_char := convert_utf32_to_utf8(xx trash_icon_unicode);
                width = cast(float) Simp.prepare_text(font_icons, to_string(*icon_char));
                pen = make_vector2(icon.x, icon.y + (icon.h - font.character_height) / 2 + 2 * dpi_scale);
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
             }
             
             if mouse_pointer_is_within(icon) {
                ui_id := get_ui_id_from_loc();
                became_active := maybe_set_hot_or_active(ui_id, icon, .PRESSABLE);
                if became_active then array_ordered_remove_by_index(*categories, it_index);
                
                // Remove category from DB
                sql_str :: "DELETE FROM Categories WHERE id = %;";
                query := to_c_string(tprint(sql_str, it.id));
                defer free(query);
                errmsg : *u8;
                result := sqlite3_exec(db, query, null, null, *errmsg);
                if result != SQLITE_OK {
                    log_error("ERROR: %\n",from_c_string(errmsg));
                }
            }
            
        } else {
            input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
            input_rect := cut_top(rect, input_height);
            input_rect.w = 300;
            draw_text_input(*text_input, input_rect);
            new_category = it_index;
        }
    }
    
    // Add a new category by clicking on the button
    // Show either input to type a new ctagorie's name or button "Add a new category"
    if new_category < 0 {
        rect, categories_rect = cut_top(categories_rect, 36 * dpi_scale);
        draw_button(rect, "Add a new category");
        
        // Click on button creates a new category to edit(input)
        ui_id := get_ui_id_from_loc();
        became_active := maybe_set_hot_or_active(ui_id, rect, .PRESSABLE);
        new_category : Category;
        new_category.new = true;
        new_category.id = categories[categories.count-1].id + 1;
        if became_active then array_add(*categories, new_category);
    } else if enter_pressed {
        categories[new_category].name = copy_string(cast(string) text_input.text);
        categories[new_category].new = false;
        
        // Add a new category to db
        sql_select :: "INSERT OR IGNORE INTO Categories(id, name) VALUES(%, '%');";
        query := to_c_string(tprint(sql_select, categories[new_category].id, categories[new_category].name));
        defer free(query);
        errmsg : *u8;
        result := sqlite3_exec(db, query, null, null, *errmsg);
        if result != SQLITE_OK {
            log_error("ERROR: %\n",from_c_string(errmsg));
        }
        
        new_category = -1;        
        text_input.text.count = 0;
    }
    
     
}

draw_text_input :: (using text_input: *Text_Input, input_rect: Rect, loc := #caller_location) {
    ui_id := get_ui_id_from_loc(loc);

    rect := snap_to_grid(input_rect);
    draw_rect(rect, Colors.BACKGROUND_DARK);
    rect = shrink(rect, 1);
    draw_rect(rect, Colors.BACKGROUND);

    push_scissor(rect);
    defer pop_scissor();

    became_active := maybe_set_hot_or_active(ui_id, rect, .TEXT_SELECT);
    // TODO: when activated, make it so that the keyboard events are sent to the input

    padding := 4 * dpi_scale;  // GLOBAL??

    // 1. Given current scroll_x, calculate cursor_x and check if it's within allowed boundaries
    // 2. If outside the boundaries, calculate new target for the cursor so that it reaches the closest allowed position
    // 3. Only when the calculated target doesn't match the current target do we start a new animation

    cursor_x    := Simp.prepare_text(font_ui, slice(to_string(text), 0, cursor.pos));
    text_length := Simp.prepare_text(font_ui, to_string(text));
    rect_w := cast(s64) (rect.w - 2 * padding);
    
    new_scroll_target := scroll_anim.target;
    
    if cursor_x >= scroll_x && cursor_x <= scroll_x + rect_w {
        // Cursor position is within allowed boundaries
        if scroll_x > 0 && xx (text_length - scroll_x) < rect_w {
            // Don't allow any whitespace on the right with a nonzero scroll
            new_scroll_target = xx max(0, text_length - rect_w);
        }
    } else {
        // Cursor is outside allowed boundaries
        new_scroll_target = cast(s32) cursor_x;
        if cursor_x > xx rect_w then new_scroll_target = cast(s32) (cursor_x - rect_w);   
    }
    
    if new_scroll_target != scroll_anim.target {
        start_animation(*scroll_anim, scroll_x, new_scroll_target, snappy = true);
    }

    // Maybe scroll
    if scroll_x != scroll_anim.target {
        redraw_requested = true;
        scroll_x = get_animation_value(scroll_anim);
    }

    // Maybe set cursor on mouse click
    if mouse_pointer_is_within(rect) && mouse.left.is_down {
        // @Hack: we're adding 2 * dpi_scale to the mouse pointer value, because the active point of the
        // text select cursor seems to be more to the left than we expect it to be.
        // This may not be true on all systems! Maybe we should do some other solution, like
        // reconsider how the get_cursor_pos_for_width calculates width and change it to get
        // the expected behavior of changing the cursor position.
        rel_x := cast(s64) (mouse.pointer.x + 2 * dpi_scale - (rect.x + padding)) + scroll_x;
        cursor_rect := make_rect(xx (mouse.pointer.x + 2 * dpi_scale), xx mouse.pointer.y, 50, 100);
        draw_rect(cursor_rect, Colors.RED);
        
        // TODO: review !!!!!!!!!!!!!!!!!!!!!!
        cursor.pos = Simp.get_cursor_pos_for_width(font_ui, to_string(text), rel_x);
        if !shift_pressed() then cursor.sel = cursor.pos;
    }

    text_start_x := rect.x + padding - scroll_x;

    if cursor.pos != cursor.sel {
        sel_start := min(cursor.pos, cursor.sel);
        sel_rect := make_rect(
            text_start_x + Simp.prepare_text(font_ui, slice(to_string(text), 0, sel_start)),
            rect.y + (rect.h - font_ui.default_line_spacing) / 2.0,
            cast(float)Simp.prepare_text(font_ui, slice(to_string(text), sel_start, abs(cursor.sel - cursor.pos))),
            cast(float)font_ui.default_line_spacing,
        );
        draw_rect(sel_rect, Colors.SELECTION_ACTIVE);
    }

    cursor_rect := make_rect(
        text_start_x + Simp.prepare_text(font_ui, slice(to_string(text), 0, cursor.pos)),
        rect.y + (rect.h - font_ui.default_line_spacing) / 2.0,
        2 * dpi_scale,
        cast(float)font_ui.default_line_spacing,
    );
    draw_rect(cursor_rect, Colors.CURSOR);

    y := rect.y + (rect.h - font_ui.character_height) / 2.0 + 2 * dpi_scale;
    Simp.draw_text(font_ui, xx text_start_x, xx y, to_string(text), Colors.UI_DEFAULT);

}

draw_rect :: (rect: Rect, color: Color) {
    Simp.set_shader_for_color(enable_blend = true);
    draw_rect_raw(rect, color);
}

draw_rect_raw :: inline (using rect: Rect, color: Color) {
    Simp.immediate_quad(x, y, x + w, y + h, color);
}

draw_rect_raw :: inline (using rect: Rect, c00: Color, c01: Color, c10: Color, c11: Color) {
    Simp.immediate_quad(x, y, x + w, y + h, c00, c01, c10, c11);
}

draw_button :: (rect : Rect, text: string) {
    draw_rect(rect, Colors.BACKGROUND_BRIGHT);
    text_width := cast(float) Simp.prepare_text(font, text);
    text_pen := Vector2.{
        rect.x + (rect.w - text_width)/2 * dpi_scale, 
        rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale};
    Simp.draw_prepared_text(font, xx text_pen.x, xx text_pen.y, Colors.UI_DEFAULT);
}

maybe_set_hot_or_active :: (ui_id: Ui_Id, rect: Rect, pointer_image: Pointer_Image) -> became_active: bool {
    if !mouse_pointer_is_within(rect) return false;

    ui.hot = ui_id;
    if ui.hot_last_frame == ui_id || ui.active == ui_id then set_pointer_image(pointer_image);
    if ui.hot_last_frame == ui_id && ui.active == .none && mouse.left.just_pressed {
        ui.active = ui_id;
        return true;
    }
    
    return false;
}

is_hovering_over :: (ui_id: Ui_Id) -> bool {
    return ui.hot_last_frame == ui_id && ui.active == .none || ui.active == ui_id;
}

get_ui_id_from_loc :: inline (loc := #caller_location, parent_id: Ui_Id = .none) -> Ui_Id {
    if parent_id != .none {
        return cast(Ui_Id) (loc.line_number + NUM_LINES_OF_CODE * cast(s64) parent_id);
    }
    return cast(Ui_Id) loc.line_number;
}

is_child :: (ui_id: Ui_Id, parent_id: Ui_Id) -> bool {
    // A ui id is considered a child if it was obtained by the get_ui_id_from_loc function above
    num := cast(s64) ui_id;
    parent_min := cast(s64) parent_id * NUM_LINES_OF_CODE;
    parent_max := parent_min + NUM_LINES_OF_CODE - 1;
    return parent_min <= num && num <= parent_max;
}

push_scissor :: (rect: Rect) {
    set_scissor(rect);
    array_add(*scissor_stack, rect);
}

pop_scissor :: () {
    assert(scissor_stack.count > 0);
    pop(*scissor_stack);
    if scissor_stack {
        last := peek(scissor_stack);
        set_scissor(last);
    } else {
        Simp.clear_scissor();
    }
}

set_scissor :: (rect: Rect) {
    x0 := cast(s32) rect.x;
    y0 := cast(s32) rect.y;
    x1 := cast(s32) (rect.x + rect.w);
    y1 := cast(s32) (rect.y + rect.h);
    Simp.set_scissor(x0, y0, max(x0, x1), max(y0, y1));
}

#scope_file

scissor_stack: [..] Rect;

Ui_Id :: enum s64 {
    unavailable :: -2;
    none        :: -1;

    // tmp
    categories_panel :: -3;
    upload_button :: -4;
}

ui: struct {
    active: Ui_Id = .none;
    hot:    Ui_Id = .none;
    hot_last_frame: Ui_Id = .none;
};


// !!!!!!!!!!!!!!!!!!!!!! TEMPORARY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#scope_export

text_input: Text_Input;

// !!!!!!!!!!!!!!!!!!!!!! TEMPORARY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



// Please keep at the bottom - needed for ui elements parent-child relationships
NUM_LINES_OF_CODE :: #run #location().line_number;