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
    draw_rect(main_area, Colors.BACKGROUND_LIGHT);
    categories_rect, main_area := cut_left(main_area, 300 * dpi_scale);

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
    for categories {
        rect, categories_rect = cut_top(categories_rect, 36 * dpi_scale);
        draw_rect(rect, Colors.BACKGROUND_LIGHT);
        width := cast(float) Simp.prepare_text(font, it.name);
        pen := make_vector2(rect.x + 5 * dpi_scale, rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale);
        Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
        bottomline := rect;
        bottomline.h = 1 * dpi_scale;
        draw_rect(bottomline, Colors.SELECTION_ACTIVE);
    }

    padding := 4 * dpi_scale;  // TODO: make global?

    input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
    input_rect := cut_top(main_area, input_height);
    input_rect.x += 30;  // @tmp
    input_rect.y -= 30;
    input_rect.w = 300;
    draw_text_input(*text_input, input_rect);
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

    // Maybe scroll
    if scroll_x != scroll_anim.target {
        redraw_requested = true;
        scroll_x = get_animation_value(scroll_anim);
    }

    padding := 4 * dpi_scale;  // GLOBAL??

    // Check if the cursor reaches the end on the right
    to_scroll := cast(s32) (Simp.prepare_text(font_ui, slice(to_string(text), 0, cursor.pos)) - (rect.w - 2 * padding));
    if to_scroll > 0 {
        start_animation(*scroll_anim, scroll_x, to_scroll, snappy = true);
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