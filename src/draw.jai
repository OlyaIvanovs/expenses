draw_one_frame :: () {
    {
        using Colors.BACKGROUND;
        Simp.clear_render_target(r, g, b, a);
    }

    tabs_rect, main_area := cut_top(screen, 50 * dpi_scale);
    draw_rect(tabs_rect, Colors.BACKGROUND_DARK);
    
    if program_state == {
        case .dashboard;        draw_dashboard(main_area);
        // case .something_else;
        case .settings;         draw_settings(main_area);
    }

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

should_remove := -1;
new_category  := -1;;

draw_settings :: (r: Rect) {    
    draw_rect(r, Colors.BACKGROUND_LIGHT);
    categories_rect, rules_rect, upload_rect, pad : Rect;
    main_area := shrink_x(r, 50 * dpi_scale);
    // pad, main_area := cut_left(main_area, 30 * dpi_scale);
    pad, main_area = cut_bottom(main_area, 50 * dpi_scale);
    categories_rect, main_area = cut_left(main_area, 300 * dpi_scale);
    categories_rect, rules_rect = cut_top(categories_rect, 0.5 * categories_rect.h);
    upload_rect, main_area = cut_right(main_area, 250 * dpi_scale);
    top_pad := make_rect(main_area.x, main_area.y + main_area.h, main_area.w, window_height - main_area.h);
    
    draw_categories(categories_rect);
    draw_rules(rules_rect);
    draw_transactions(main_area);
    draw_upload_button_area(upload_rect);
    draw_rect(pad, Colors.BACKGROUND_LIGHT); // bottom pad
    draw_rect(top_pad, Colors.BACKGROUND_DARK); // top pad
    
    // Draw confirmation dialog
    if should_remove > -1{
        draw_dialog();
    }
}

draw_categories :: (r: Rect) {
    padding := 4 * dpi_scale;  // TODO: make global?
    categories_rect := r;
    title_rect : Rect;
    title_rect, categories_rect = cut_top(categories_rect, 50 * dpi_scale);
    draw_rect(title_rect, Colors.BACKGROUND_LIGHT);

    title_bottomline := title_rect;
    title_bottomline.h = 3 * dpi_scale;
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);

    width := cast(float) Simp.prepare_text(font_ui_bold, "Categories");
    pen := make_vector2((title_rect.w - width)/2, title_rect.y + (title_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, Colors.UI_DEFAULT);

    rect : Rect;
    for *category, cat_index: categories {
        draw_icon : bool;
        rect, categories_rect = cut_top(categories_rect, 36 * dpi_scale);
        draw_rect(rect, Colors.BACKGROUND_LIGHT);
        
        if cat_index != new_category {
            bottomline := rect;
            bottomline.h = 1 * dpi_scale;
            draw_rect(bottomline, Colors.SELECTION_ACTIVE);
            
             // Show icons on hover
            if mouse_pointer_is_within(rect) {
                draw_icon = true;
             }
            
            icons : Rect;
            icons, rect = cut_right(rect, 32 * dpi_scale);
            width := cast(float) Simp.prepare_text(font, category.name);
            pen := make_vector2(rect.x + 5 * dpi_scale, rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);

            if draw_icon {
                trash_icon, edit_icon := cut_right(icons, 10 * dpi_scale);
                
                // Edit category
                edit_icon_unicode := 0xf304;
                edit_icon_char := convert_utf32_to_utf8(xx edit_icon_unicode);
                width = cast(float) Simp.prepare_text(font_icons, to_string(*edit_icon_char));
                pen = make_vector2(edit_icon.x, edit_icon.y + (edit_icon.h - font.character_height) / 2 + 2 * dpi_scale);
                
                if mouse_pointer_is_within(edit_icon) {
                    Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DIM);
                    ui_id := get_ui_id_from_loc();
                    became_active := maybe_set_hot_or_active(ui_id, icons, .PRESSABLE);
                    if became_active then new_category = cat_index;
                } else {
                    Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
                }
                
                // Remove category
                trash_icon_unicode := 0xf1f8;
                trash_icon_char := convert_utf32_to_utf8(xx trash_icon_unicode);
                width = cast(float) Simp.prepare_text(font_icons, to_string(*trash_icon_char));
                pen = make_vector2(trash_icon.x, trash_icon.y + (trash_icon.h - font.character_height) / 2 + 2 * dpi_scale);
                
                if mouse_pointer_is_within(trash_icon) {
                    Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DIM);
                    ui_id := get_ui_id_from_loc();
                    became_active := maybe_set_hot_or_active(ui_id, icons, .PRESSABLE);
                    if became_active {
                        should_remove = cat_index;
                    } 
                } else {
                    Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
                }
             }
            
        } else {
            input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
            input_rect := cut_top(rect, input_height);
            input_rect.w = 300;
            draw_text_input(*text_input, input_rect);
            if category.name.count > 0 { // edit category
                array_resize(*text_input.text, category.name.count);
                memcpy(text_input.text.data, category.name.data, category.name.count);
                category.name.count = 0;
            } 
        } 
    }
    
    // Add a new category by clicking on the button
    // Show either input to type a new categorie's name or button "Add a new category"
    if new_category < 0 {
        rect, categories_rect = cut_top(categories_rect, 36 * dpi_scale);
        draw_button(rect, "Add a new category");
        
        // Click on button creates a new category)
        category_new : Category;
        category_new.id = categories[categories.count-1].id + 1;
        
        ui_id := get_ui_id_from_loc();
        became_active := maybe_set_hot_or_active(ui_id, rect, .PRESSABLE);
        if became_active {
            new_category = xx categories.count;
            array_add(*categories, category_new);
        }
    } else if enter_pressed {
        categories[new_category].name = copy_string(cast(string) text_input.text);
        
        ok := add_category_to_db(categories[new_category].id, categories[new_category].name);
        if !ok then return;
        
        new_category = -1;        
        text_input.text.count = 0;
    }
}

draw_dialog :: (loc := #caller_location) {
    cover := make_rect(10, 10, window_width, window_height);
    draw_rect(cover, Colors.BACKGROUND_TRANSPARENT);
    
    text := sprint("Are you sure you want to remove category '%'", categories[should_remove].name); 
    
    width := cast(float) Simp.prepare_text(font, text);
    dialog := make_rect(
        cast(float) (0.35 * window_width), 
        cast(float) (0.75 * window_height), 
        cast(float) (width + 40 * dpi_scale), 
        cast(float) (120 * dpi_scale));
    draw_rect(dialog, Colors.BACKGROUND_LIGHT);
    
    buttons : Rect;
    buttons, dialog = cut_bottom(dialog, 60 * dpi_scale);
    
    pen := make_vector2(dialog.x + 20 * dpi_scale, dialog.y + (dialog.h - font.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
    
   
    no, yes := cut_right(buttons, xx (buttons.w / 2));
    
    yes = shrink_y(shrink_x(yes, 0.2 * yes.w), 0.2 * yes.h);    
    no = shrink_y(shrink_x(no, 0.2 * no.w), 0.2 * no.h);   
    
    draw_button(yes, "Yes");
    draw_button(no, "Cancel");
    
    ui_id := get_ui_id_from_loc(loc); 
    yes_chosen := maybe_set_hot_or_active(ui_id, yes, .PRESSABLE);
    no_chosen := maybe_set_hot_or_active(ui_id, no, .PRESSABLE);
    
    if yes_chosen {
        ok := delete_category_from_db(categories[should_remove].id);
        if !ok then return;
        array_ordered_remove_by_index(*categories, should_remove);
        should_remove = -1;
        return;
    }
    
    if no_chosen {
        should_remove = -1;
    }
    
    return;
}

draw_rules :: (r: Rect) {
    padding := 4 * dpi_scale;  // TODO: make global?
    categories_rect := r;
    title_rect : Rect;
    title_rect, categories_rect = cut_top(categories_rect, 50 * dpi_scale);
    draw_rect(title_rect, Colors.BACKGROUND_LIGHT);

    title_bottomline := title_rect;
    title_bottomline.h = 3 * dpi_scale;
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);

    width := cast(float) Simp.prepare_text(font_ui_bold, "Rules");
    pen := make_vector2((title_rect.w - width)/2, title_rect.y + (title_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
}

transactions_scroll_delta :float = 0;
transactions_scroll_grip :float = 0;
transaction_height :float = 0;

draw_transactions :: (r: Rect) {
    padding := 4 * dpi_scale;  // TODO: make global?
    title_rect, transactions_rect_wrapper := cut_top(r, 50 * dpi_scale);
    
    title_bottomline := title_rect;
    title_bottomline.h = 3 * dpi_scale;
    
    transactions_rect_wrapper = shrink_x(transactions_rect_wrapper, 50 * dpi_scale);
   
    // Scroll bar
    scrollbar, scrollbar_line : Rect;
    scrollbar, transactions_rect_wrapper = cut_right(transactions_rect_wrapper, 10 * dpi_scale);
    scrollbar_line, scrollbar = cut_right(scrollbar, 2 * dpi_scale);
    scroll_h := cast(float) scrollbar.h * scrollbar.h / (transactions.count * 36 * dpi_scale); 
    if xx(transactions_rect_wrapper.x + transactions_rect_wrapper.h) > window_height { 
        scroll_y := cast(float) scrollbar.y + (scrollbar.h - scroll_h) - transactions_scroll_delta - transactions_scroll_grip;
        if scroll_y + scroll_h > scrollbar.y + scrollbar.h then scroll_y = scrollbar.y + scrollbar.h - scroll_h;
        if scroll_y < scrollbar.y { 
            scroll_y = scrollbar.y;
        }
        scroll := make_rect(cast(float) scrollbar.x, scroll_y, cast(float) scrollbar.w, scroll_h);
        
        ui_id := get_ui_id_from_loc();
        became_active := maybe_set_hot_or_active(ui_id, scroll, .PRESSABLE);
        // if became_active {
        //     transactions_scroll_grip = (window_height - mouse.pointer.y) - (scrollbar.y + scrollbar.h + transactions_scroll_delta);
        // }
        if ui.active == ui_id {
           transactions_scroll_delta = (scrollbar.y + scrollbar.h) - mouse.pointer.y;
           if transactions_scroll_delta < 0 then transactions_scroll_delta = 0;
           if transactions_scroll_delta + scroll_h > scrollbar.h {
                 transactions_scroll_delta = scrollbar.h - scroll_h;
           }
        }
        
        if is_hovering_over(ui_id) {
            draw_rect(scroll, Colors.BACKGROUND_HIGHLIGHT);
        } else {
            draw_rect(scroll, Colors.BACKGROUND_BRIGHT);
        }
        draw_rect(scrollbar_line, Colors.BACKGROUND_BRIGHT);
    }
    
     move := (transactions_scroll_delta) / scrollbar.h  * transactions.count * 36 * dpi_scale;
    
    // Transactions
    rect : Rect;
    transactions_rect := make_rect(transactions_rect_wrapper.x, transactions_rect_wrapper.y + move, transactions_rect_wrapper.w, transactions_rect_wrapper.h);
    for tr, tr_index: transactions {
        rect, transactions_rect = cut_top(transactions_rect, 36 * dpi_scale);
        draw_rect(rect, Colors.BACKGROUND_LIGHT);
        
        bottomline := rect;
        bottomline.h = 1 * dpi_scale;
        draw_rect(bottomline, Colors.SELECTION_ACTIVE);
        
        line_width := rect.w;
        
        // Date
        date_rect: Rect;
        date_rect, rect = cut_left(rect, 0.1 * line_width);
        draw_text_in_rect(date_rect, tr.date);
        
        // Details
        details_rect: Rect;
        details_rect, rect = cut_left(rect, 0.6 * line_width);
        draw_text_in_rect(details_rect, tr.details);

        // Amount
        amount_rect: Rect;
        amount_rect, rect = cut_left(rect, 0.1 * line_width);
        draw_text_in_rect(amount_rect, sprint("%", tr.amount));
        
        // Category
        category_name := "UNCATEGORIZED";
        if tr.category_id {
            for categories if it.id == tr.category_id { 
                category_name =  it.name;
                break; 
            }
        }
        draw_text_in_rect(rect, sprint("%", category_name));

    }
    
    draw_rect(title_rect, Colors.BACKGROUND_LIGHT);
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);
    width := cast(float) Simp.prepare_text(font_ui_bold, "Transactions");
    pen := make_vector2((title_rect.w - width)/2, title_rect.y + (title_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
}

draw_upload_button_area :: (r: Rect) {
    padding := 4 * dpi_scale;  
    title_rect, r := cut_top(r, 50 * dpi_scale);
    
    title_bottomline := title_rect;
    title_bottomline.h = 3 * dpi_scale;
    draw_rect(title_rect, Colors.BACKGROUND_LIGHT);
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);
    
    pad, button_area : Rect;
    pad, r = cut_top(r, 36 * dpi_scale);
    button_area, r = cut_top(r, 36 * dpi_scale);
    
    draw_button(button_area, "Upload transactions");
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

draw_text_in_rect :: (rect : Rect, text: string) {
    width := cast(float) Simp.prepare_text_with_max_width(font, text, xx (rect.w - 5 * dpi_scale));
    pen := Vector2.{
        rect.x + 5 * dpi_scale, 
        rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale};
    Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
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