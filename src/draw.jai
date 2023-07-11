draw_one_frame :: () {
    {
        using Colors.BACKGROUND;
        Simp.clear_render_target(r, g, b, a);
    }
    
    pad: Rect;
    draw_rect(screen, Colors.BACKGROUND_LIGHT);
    
    tabs_rect, main_area := cut_top(screen, 50 * dpi_scale);
    main_area = shrink_x(main_area, 0.02 * window_width);
    pad, main_area = cut_bottom(main_area, 0.03 * window_height);
    draw_rect(tabs_rect, Colors.BACKGROUND_DARK);
    
    
    if enter_pressed {
        ui.last_active_input =  ui.active_input;
        ui.active_input = .none;
    }
    
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
            if program_state == .dashboard then color = Colors.BACKGROUND_LIGHT;

            draw_rect(tab_rect, color);

            text_color := Colors.UI_DEFAULT;
            if program_state == .settings then text_color = Colors.UI_DIM; 
            pen := make_vector2(tab_rect.x + margin, tab_rect.y + (tab_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, text_color);
        }

        // Settings & Data tab
        {
            ui_id := get_ui_id_from_loc();

            width := cast(float) Simp.prepare_text(font_ui_bold, "Settings & Data");
            tab_rect := cut_right(tabs_rect, width + margin * 2);

            became_active := maybe_set_hot_or_active(ui_id, tab_rect, .PRESSABLE);
            if became_active then program_state = .settings;
            
            color := Colors.BACKGROUND;
            if program_state == .settings then  color = Colors.BACKGROUND_LIGHT;

            draw_rect(tab_rect, color);

            text_color := Colors.UI_DEFAULT;
            if program_state == .dashboard then text_color = Colors.UI_DIM; 
            pen := make_vector2(tab_rect.x + margin, tab_rect.y + (tab_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
            Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, text_color);
        }
    }
    
    if message.show {
        if frame_time - message.time_start > 3 {
            message.show = false;
        } else { 
            draw_message_popup();
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


scrollbar_grab_point :float = 0;
dropdown_scroll_delta :float = 0;
should_show_category_dropdown := false;
should_show_graph_year_dropdown := false;
before_category_choose := true; 


set_null_state :: () {
    should_show_category_dropdown = false;
    should_show_graph_year_dropdown = false;
    
    settings_transactions.remove_all = false;
    settings_transactions.edit = -1;
    settings_transactions.add = false;
    settings_transactions.delete = -1;
    
    rules_list.edit = -1;
    rules_list.add = false;
    rules_list.delete = -1;
    
    categories_list.edit = -1;
    categories_list.add = false;
    categories_list.delete = -1;
    
    color_picker.hsv.hue = 0;
    color_picker.hsv.saturation = 0;
    color_picker.hsv.value = 0;
    color_picker.load = false;
    
    new_category = Category.{name="", color="e3a019"};
    new_rule = Rule.{name="", category_id=0};
    new_transaction = Transaction.{details="", note="", category_id=0, amount=0.0, date=""};
    
    before_category_choose = true; 
    text_input.text.count = 0;
    
    message.show = false;
}

draw_dashboard :: (main_area: Rect) {
    choose_graph_rect, transactions_rect, graph_rect, pie_chart_rect: Rect;
    categories_rect, main_area := cut_left(main_area, 300 * dpi_scale);
    choose_graph_rect, categories_rect = cut_bottom(categories_rect, 3 * LINE_HEIGHT);
    
    if graph_details.type == .weekly {
        graph_rect = draw_title(main_area, tprint("Weekly Expenses For Year %", graph_details.year));
        transactions_rect, graph_rect = cut_right(graph_rect, graph_rect.w * 0.2);
        transactions_rect, pie_chart_rect = cut_top(transactions_rect, 0.7 * transactions_rect.h);
        draw_weekly_graph_area(graph_rect, pie_chart_rect);
        draw_dashboard_transactions(transactions_rect, *weekly_dashboard_transactions);
    } else if graph_details.type == .monthly {
        graph_rect = draw_title(main_area, "Monthly Expenses for the last 3 years");
        transactions_rect, graph_rect = cut_right(graph_rect, graph_rect.w * 0.2);
        transactions_rect, pie_chart_rect = cut_top(transactions_rect, 0.7 * transactions_rect.h);
        draw_monthly_graph_area(graph_rect, pie_chart_rect);
        draw_dashboard_transactions(transactions_rect, *monthly_dashboard_transactions);
    }
    
    draw_dashboard_categories(categories_rect);
    draw_choose_graph(choose_graph_rect);
   
    if weekly_dashboard_transactions.update {
        daily_spendings = update_spendings_data(daily_spendings, .weekly);
        update_transactions_on_dashboard(*weekly_dashboard_transactions);
        redraw_requested = true;
    }
    
     if monthly_dashboard_transactions.update {
        update_transactions_on_dashboard(*monthly_dashboard_transactions);
        redraw_requested = true;
    }
}

draw_settings :: (r: Rect) {  
    categories_rect, rules_rect, upload_rect: Rect;
    main_area := r;
    categories_rect, main_area = cut_left(main_area, 380 * dpi_scale);
    categories_rect, rules_rect = cut_top(categories_rect, 0.5 * categories_rect.h);
    
    draw_rect(r, Colors.BACKGROUND_LIGHT);
    draw_categories(categories_rect);
    draw_rules(rules_rect);
    draw_settings_transactions(main_area);
    
    // Draw confirmation dialog
    if categories_list.delete > -1 {
        draw_remove_dialog("category");
    } else  if settings_transactions.delete > -1 {
        draw_remove_dialog("transaction");
    } else if settings_transactions.remove_all {
        draw_remove_dialog("all_transactions");
    } else if settings_transactions.edit > -1 || settings_transactions.add {
        draw_edit_transaction_dialog();
    } else if categories_list.edit > -1 || categories_list.add {
        draw_edit_category_dialog();
    }  else if rules_list.edit > -1 || rules_list.add {
        draw_edit_rule_dialog();
    } else if rules_list.delete > -1 {
        draw_remove_dialog("rule");
    }
    
    if settings_transactions.update {
        settings_transactions.update = false;
        update_settings_transactions();
        redraw_requested = true;
    }
    
    if rules_list.update {
        rules_list.update = false;
        update_filtered_rules();
        redraw_requested = true;
    }
}

draw_choose_graph :: (r: Rect) {
    option_icon_rect: Rect;
    r, rect := cut_top(r, LINE_HEIGHT);
    rect = shrink_x(rect, 15 * dpi_scale);
    first_option, second_option := cut_top(rect, LINE_HEIGHT);
    option_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(option_id, first_option, .PRESSABLE);
    if became_active then graph_details.type = .weekly;
    became_active = maybe_set_hot_or_active(option_id, second_option, .PRESSABLE);
    if became_active then graph_details.type = .monthly;
    
    option_icon_rect, first_option = cut_right(first_option, 20 * dpi_scale);
    if graph_details.type == {
        case .weekly; 
            draw_icon(0xf192, option_icon_rect, Colors.UI_DEFAULT);
        case .monthly;
            draw_icon(0xf111, option_icon_rect, Colors.UI_DEFAULT);
    }
    
    option_icon_rect, second_option = cut_right(second_option, 20 * dpi_scale);
    if graph_details.type == {
        case .monthly;
            draw_icon(0xf192, option_icon_rect, Colors.UI_DEFAULT);
        case .weekly;
            draw_icon(0xf111, option_icon_rect, Colors.UI_DEFAULT);
    }
    
    draw_text_in_rect(first_option, "Weekly expenses");
    draw_text_in_rect(second_option, "Monthly expenses");
}
 
draw_dashboard_categories :: (r: Rect) {
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, r, .NORMAL, false);
    
    count := categories_list.categories.count + 1; // + 'all categories'
    content_height := count * LINE_HEIGHT;    
    categories_rect := draw_title(r, "Categories");
    wrapper := adjust_height(categories_rect);
    
    if wrapper.h > content_height {
        wrapper.y += wrapper.h - content_height;
        wrapper.h = content_height;
    }
    categories_rect = shrink_x(categories_rect, 15 * dpi_scale);        
    push_scissor(wrapper);
    defer pop_scissor();
    
    // Scrollbar
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    to: bool;
    categories_list.scroll_delta_dashboard, to = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, categories_list.scroll_delta_dashboard, to);
    categories_rect.y += categories_list.scroll_delta_dashboard;
    
    draw_line :: (r: Rect, ui_id: Ui_Id, category: *Category) {
        rect := r;
        draw_line_separator(rect);
        became_active := maybe_set_hot_or_active(ui_id, rect, .PRESSABLE);
        
        color_rect, category_rect, icons_rect: Rect;
        icons_rect, rect = cut_right(rect, 20 * dpi_scale);
        color_rect, rect = cut_left(rect, 30 * dpi_scale);
        
        show_on_graph, found := table_find(*show_categories_table, category.id);
        if show_on_graph then draw_icon(0xf00c, icons_rect, Colors.SEARCH_RESULT_INACTIVE);
        
        text_color := Colors.UI_DEFAULT;
        if is_hovering_over(ui_id) then text_color = Colors.UI_DIM;
       
        // Choose category to show on the graph
        if became_active { 
            weekly_dashboard_transactions.update = true;
            monthly_dashboard_transactions.update = true;
            graph_details.active_transaction = 0;
            graph_details.category_id = -1;
            monthly_dashboard_transactions.chosen_period = -1;
            
            if show_on_graph && category.id != -1 {
                table_set(*show_categories_table, category.id, false);
                show_all_categories_on_graph -= 1;
            } else {
                if category.id == -1 {
                    show_all_categories_on_graph = 1;
                    for categories_list.categories table_set(*show_categories_table, it.id, false);
                } else {
                    show_all_categories_on_graph += 1;
                    table_set(*show_categories_table, category.id, true);
                }
            }
        }
       
        draw_text_in_rect(rect, category.name, text_color);
        
        // Color icon
        color_rect = shrink(color_rect, 10 * dpi_scale);
        c, ok := hex_to_color(category.color);
        if !ok then category.color = "110000";
        draw_rect(color_rect, c);
    }

    rect, c : Rect;
    category_line_id := get_ui_id_from_loc_with_index(ui_id, categories_list.categories.count);
    rect, categories_rect = cut_top(categories_rect, LINE_HEIGHT);
    category := Category.{name="All categories", id=-1, color="e3a019"};
    if show_all_categories_on_graph == 1 {
        table_set(*show_categories_table, category.id, true);
    } else {
        table_set(*show_categories_table, category.id, false);
    }
    draw_line(rect, category_line_id, *category);
    for *category, cat_index: categories_list.categories {
        category_line_id := get_ui_id_from_loc_with_index(ui_id, cat_index);
        rect, categories_rect = cut_top(categories_rect, LINE_HEIGHT);
        draw_line(rect, category_line_id, category);
    }
}

draw_monthly_graph_area :: (r: Rect, pie_chart_rect: Rect) {
    draw_bar_info: bool;
    amount, category_name: string;
   
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, r, .NORMAL, false);
         
    graph_rect := r;  
    draw_rect(graph_rect, Colors.BACKGROUND_HIGHLIGHT);
    graph_rect = shrink_x(graph_rect, 0.01 * graph_rect.w);
    
    instrument_bar, info_rect, category_rect, amount_rect, transactions_rect, rect: Rect;
    instrument_bar, graph_rect = cut_top(graph_rect, LINE_HEIGHT);
    instrument_bar = shrink_x(instrument_bar, instrument_bar.w * 0.02);
    
    month_desc_rect := make_rect(graph_rect.x, graph_rect.y - 30 * dpi_scale, graph_rect.w, 30 * dpi_scale);
    
    bar_rect := cut_left(graph_rect, (graph_rect.w / 12) - padding * 5);
    
    using monthly_spendings;
    for i : 0 .. 11 {
        month_id := get_ui_id_from_loc_with_index(ui_id, (i+1));
        month_rect := bar_rect;
        month_name_rect: Rect;
        month_name_rect, month_rect = cut_bottom(bar_rect, 30 * dpi_scale);
        month_rect.x += i * (bar_rect.w + padding * 5);
        month_name_rect.x = month_rect.x;
        draw_text_in_rect(month_name_rect, tprint("%", i+1), centered=true);
        
        for j : 0..2 {
            m_id := get_ui_id_from_loc_with_index(month_id, (j+1));
            rect := month_rect;
            rect.w = month_rect.w /3;
            rect.x += j * rect.w;
            rect = shrink_x(rect, 0.07 * rect.w);
            start := period_indices[12*j + i];
            end   := period_indices[12*j + i + 1];
            num_spendings := end - start;
            month_spendings := array_view(spendings, start, num_spendings);
            month_total: float64;
            for spending : month_spendings month_total += spending.total_spent;

            rect.h = xx (rect.h * (month_total / max_spending)); // MAX SPENDING
            if rect.h == 0 rect.h = 2 * dpi_scale;
                
            if mouse_pointer_is_within(rect) {
                draw_rect(month_name_rect, Colors.BACKGROUND_HIGH_TRANSPARENT);
                draw_text_in_rect(month_desc_rect, get_month_name(i, to_calendar(current_time_consensus()).year-j, month_total));
                // draw_pie_chart(pie_chart_rect, month_spendings, month_total);
            }
            
            if month_total == 0 {
                draw_rect(rect, Colors.BACKGROUND_LIGHT);
                continue;
            }
            
            // draw categories
            y: float32;
            for spending, k: month_spendings {
                show_on_graph, found := table_find(*show_categories_table, spending.category_id);
                if !show_on_graph { // check if show all categories
                    show_on_graph, found = table_find(*show_categories_table, -1);
                    if !show_on_graph continue;
                }
                r := rect;
                r.h = xx (rect.h * (spending.total_spent / month_total));
                r.y += y;
                y += r.h;
                color, ok := hex_to_color(spending.color);
                if !ok then color = Colors.RED;
                draw_rect(r, color);
                
                bar_id := get_ui_id_from_loc_with_index(m_id,(k+1) * period_indices.count);
                became_active := maybe_set_hot_or_active(bar_id, r, .PRESSABLE);
                
                if became_active {
                    graph_details.category_id = spending.category_id;
                    monthly_dashboard_transactions.update = true;
                    monthly_dashboard_transactions.chosen_period = j*12 + i + 1;
                }
                
                if is_hovering_over(bar_id) {
                    draw_rect(rect, Colors.BACKGROUND_HIGH_TRANSPARENT);
                    info_rect = make_rect(mouse.pointer.x, mouse.pointer.y, 150 * dpi_scale, 60 * dpi_scale);
                    info_rect = shrink(info_rect, 10 * dpi_scale);
                    category_rect, amount_rect = cut_top(info_rect, 20 * dpi_scale);
                    amount = tprint("%", formatFloat(spending.total_spent, trailing_width=2, zero_removal=.NO));
                    category_name = spending.category;
                    draw_bar_info =  true;
                }
            }
        }
        
        // if mouse_pointer_is_within(month_name_rect) && mouse.left.is_down {
        //     array_reset_keeping_memory(*dashboard_transactions);
        //     get_filtered_transactions_from_db(-1, to_calendar(current_time_consensus()).year-graph_details.year, i*7);
        //     if show_all_categories_on_graph != 1 {
        //         for tr, i: dashboard_transactions {
        //             show_on_graph, found := table_find(*show_categories_table, tr.category_id);
        //             if !show_on_graph then remove tr;
        //         }
        //     }
        // }
    }
    
    if draw_bar_info {
        draw_rect(info_rect, Colors.SELECTION_ACTIVE);
        draw_text_in_rect(category_rect, category_name);
        draw_text_in_rect(amount_rect, tprint("%", amount));
    }
}

draw_weekly_graph_area :: (r: Rect, pie_chart_rect: Rect) {
    draw_bar_info: bool;
    amount, category_name: string;

    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, r, .NORMAL, false);
    
    graph_rect := r;    
    draw_rect(graph_rect, Colors.BACKGROUND_HIGHLIGHT);
    graph_rect = shrink_x(graph_rect, 0.01 * graph_rect.w);
    
    instrument_bar, info_rect, category_rect, amount_rect, transactions_rect, rect: Rect;
    instrument_bar, graph_rect = cut_top(graph_rect, LINE_HEIGHT);
    instrument_bar = shrink_x(instrument_bar, instrument_bar.w * 0.02);
    year_dropdown_w := cut_left(instrument_bar, 80 * dpi_scale);
    year_dropdown_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(year_dropdown_id, year_dropdown_w, .PRESSABLE, true);
    year_dropdown, icon_rect := cut_left(year_dropdown_w, 60 * dpi_scale); 
    draw_icon(0xf107, icon_rect);
    if ui.active_input == year_dropdown_id {
        should_show_graph_year_dropdown = true;
    } else {
        should_show_graph_year_dropdown = false;
    }
    
    draw_text_in_rect(year_dropdown, tprint("%", graph_details.year));
    
    week_desc_rect := make_rect(graph_rect.x, graph_rect.y - 30 * dpi_scale, graph_rect.w, 30 * dpi_scale);
    
    bar_rect := cut_left(graph_rect, (graph_rect.w / 52) - padding);
    
    using daily_spendings;
    for i : 0 .. period_indices.count - 2 {
        start := period_indices[i];
        end   := period_indices[i + 1];
        num_spendings := end - start;
        week_spendings := array_view(spendings, start, num_spendings);
        weekly_total: float64;
        for spending : week_spendings weekly_total += spending.total_spent;

        // base rect
        week_rect := bar_rect;
        week_name_rect: Rect;
        if bar_rect.w > 25 * dpi_scale {
            week_name_rect, week_rect = cut_bottom(bar_rect, 30 * dpi_scale);
        } else {
            week_name_rect, week_rect = cut_bottom(bar_rect, 2 * dpi_scale);  
        }
        
        week_rect.x += i * (bar_rect.w + padding);
        week_name_rect.x = week_rect.x;
        week_rect.h = xx (week_rect.h * (weekly_total / max_spending));
        if bar_rect.w > 25 * dpi_scale {
            draw_text_in_rect(week_name_rect, tprint("%", i+1), centered=true);
        } else {
            draw_rect(week_name_rect, Colors.BACKGROUND_DARK);
        }
        
        if mouse_pointer_is_within(week_name_rect) ||  mouse_pointer_is_within(week_rect) {
            draw_rect(week_name_rect, Colors.BACKGROUND_HIGH_TRANSPARENT);
            draw_text_in_rect(week_desc_rect, get_week_name(i, graph_details.year, weekly_total));
            // draw_pie_chart(pie_chart_rect, week_spendings, weekly_total);
        }
        
        if mouse_pointer_is_within(week_name_rect) && mouse.left.is_down {
            array_reset_keeping_memory(*weekly_dashboard_transactions.transactions);
            get_filtered_transactions_from_db(-1, to_calendar(current_time_consensus()).year-graph_details.year, i*7);
            if show_all_categories_on_graph != 1 {
                for tr, i: weekly_dashboard_transactions.transactions {
                    show_on_graph, found := table_find(*show_categories_table, tr.category_id);
                    if !show_on_graph then remove tr;
                }
            }
        }
                
        // draw categories
        y: float32;
        for spending, j : week_spendings {
            show_on_graph, found := table_find(*show_categories_table, spending.category_id);
            if !show_on_graph { // check if show all categories
                show_on_graph, found = table_find(*show_categories_table, -1);
                if !show_on_graph continue;
            }
            rect := week_rect;
            rect.h = xx (week_rect.h * (spending.total_spent / weekly_total));
            rect.y += y;
            y += rect.h;
            color, ok := hex_to_color(spending.color);
            if !ok then color = Colors.RED;
            draw_rect(rect, color);
            
            bar_id := get_ui_id_from_loc_with_index(ui_id, (j+period_indices.count)*(i+1));
            became_active := maybe_set_hot_or_active(bar_id, rect, .PRESSABLE);
            
            if became_active {
                array_reset_keeping_memory(*weekly_dashboard_transactions.transactions);
                get_filtered_transactions_from_db(
                    spending.category_id, to_calendar(current_time_consensus()).year-graph_details.year, i*7);
                total: float64;
                for tr: weekly_dashboard_transactions.transactions total += tr.amount;
                weekly_dashboard_transactions.subtotal = total;
            }
            
            if is_hovering_over(bar_id) {
                draw_rect(rect, Colors.BACKGROUND_HIGH_TRANSPARENT);
                info_rect = make_rect(mouse.pointer.x, mouse.pointer.y, 150 * dpi_scale, 60 * dpi_scale);
                info_rect = shrink(info_rect, 10 * dpi_scale);
                category_rect, amount_rect = cut_top(info_rect, 20 * dpi_scale);
                amount = tprint("%", formatFloat(spending.total_spent, trailing_width=2, zero_removal=.NO));
                category_name = spending.category;
                draw_bar_info =  true;
            }
        }
    }
    
    if draw_bar_info {
        draw_rect(info_rect, Colors.SELECTION_ACTIVE);
        draw_text_in_rect(category_rect, category_name);
        draw_text_in_rect(amount_rect, tprint("%", amount));
    }
    
    // TMP !!!
    year_options := int.[2023, 2022, 2021];
    
    // Draw dropdown
    if should_show_graph_year_dropdown {
        wrapper := year_dropdown_w;
        wrapper.h = min(year_options.count-1, 5) * LINE_HEIGHT;
        wrapper.y = year_dropdown.y - wrapper.h;
        draw_rect(wrapper, Colors.SEARCH_RESULT_INACTIVE); 
        
        ui_id := get_ui_id_from_loc();
        maybe_set_hot_or_active(ui_id, wrapper, .NORMAL, false);
        
        content_height := (year_options.count-1) * LINE_HEIGHT;
        dropdown_rect := wrapper;
        if content_height <= wrapper.h  { // no scroll
            wrapper.y += wrapper.h - content_height;
            wrapper.h = content_height;
            dropdown_rect = wrapper;
        } else { // place for scroll
            dropdown_rect = cut_left(wrapper, wrapper.w - 10 * dpi_scale);
        }
        
        push_scissor(wrapper);
        defer pop_scissor();
        
        scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
        to: bool;
        dropdown_scroll_delta, to = draw_scrollbar(
            wrapper, content_height, scrollbar_id, ui_id, dropdown_scroll_delta);
        dropdown_rect.y += dropdown_scroll_delta;
                        
        for year, index: year_options {
            if year == graph_details.year continue; 
            rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
            line_id := get_ui_id_from_loc_with_index(ui_id, index);
            became_active := maybe_set_hot_or_active(line_id, rect, .NORMAL);   
            
            if is_hovering_over(line_id) && mouse_pointer_is_within(wrapper) {
                draw_rect(rect, Colors.BACKGROUND_LIGHT);
                set_pointer_image(.PRESSABLE);
            }
                   
            if became_active && mouse_pointer_is_within(wrapper) {  
                dropdown_scroll_delta = 0;
                weekly_dashboard_transactions.scroll_delta = 0;
                graph_details.year = year;
                weekly_dashboard_transactions.update = true;
            }
            
            draw_text_in_rect(rect, tprint("%", year));
        }
    }
}

draw_pie_chart :: (r: Rect, spendings: []Spending, total: float64) {
    rect := shrink(r, 10 * dpi_scale);
    
    start, end := 0, CIRCLE_RESOLUTION-1;
    for spending, j : spendings {
        color, ok := hex_to_color(spending.color);
        if !ok then color = Colors.RED;
        part := cast(int)(spending.total_spent/total*100);
        part_end := start+part;
        if j == spendings.count - 1 part_end = end;
        immediate_circle(Vector2.{x=rect.x + rect.w/2, y= rect.y + rect.h/2}, 
                        rect.w*0.3, color, start, part_end); 
        start += part;
        if start > end break; 
    }
}

draw_dashboard_transactions :: (r: Rect, transactions_list: *Transactions_List) {  
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, r, .NORMAL);
    
    draw_rect(r, Colors.BACKGROUND_LIGHT);
    
    // "Unfilter" icon
    filter_icon_rect: Rect;
    info_rect := make_rect(
        r.x + 0.75 * r.w,
        r.y + r.h + 10 * dpi_scale,
        0.25 * r.w,
        20 * dpi_scale,
    );
    filter_icon_rect, info_rect = cut_right(info_rect, 20 * dpi_scale);
    draw_text_in_rect(info_rect, 
                        tprint("%", formatFloat(transactions_list.subtotal, trailing_width=2, zero_removal=.NO)),
                        centered=true);
    
    draw_icon(0xe17b, filter_icon_rect, Colors.UI_DEFAULT);
    filter_icon_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(filter_icon_id, filter_icon_rect, .PRESSABLE, false);
    if became_active { 
        transactions_list.update = true; 
        transactions_list.chosen_period = -1;
        graph_details.category_id = -1;
    }  
        
    wrapper : = r;
    line_num := transactions_list.transactions.count;
    if graph_details.active_transaction != 0 then line_num += 2;  
    content_height := line_num * LINE_HEIGHT;
    wrapper = adjust_height(wrapper);
    if wrapper.h > content_height {
        wrapper.y += wrapper.h - content_height;
        wrapper.h = content_height;
    }
    
    transactions_rect := shrink_x(wrapper, 0.015 * wrapper.w);
    push_scissor(wrapper);
    defer pop_scissor();
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    to: bool;
    transactions_list.scroll_delta, to = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, transactions_list.scroll_delta, to);
    transactions_rect.y += transactions_list.scroll_delta;
    
    rect, date_rect, note_rect, amount_rect, color_rect : Rect;
    for tr, tr_index: transactions_list.transactions {
        if tr.id == graph_details.active_transaction {
            rect, transactions_rect = cut_top(transactions_rect, 3 * LINE_HEIGHT);
            rect, date_rect = cut_top(rect, LINE_HEIGHT); 
            date_rect, note_rect = cut_top(date_rect, LINE_HEIGHT); 
            // Date
            draw_text_in_rect(date_rect, tr.date, Colors.UI_DIM);
            // Note
            note := tr.note;
            if note == "" note = "No note for the transaction";
            draw_text_in_rect(note_rect, note, Colors.UI_DIM);
            draw_line_separator(note_rect);
        } else {
            rect, transactions_rect = cut_top(transactions_rect, LINE_HEIGHT);
            draw_line_separator(rect);
        }
        
        line_id := get_ui_id_from_loc_with_index(ui_id, tr_index);
        became_active := maybe_set_hot_or_active(line_id, rect, .PRESSABLE);
                   
        text_color := Colors.UI_DEFAULT;
        if is_hovering_over(line_id) then text_color = Colors.UI_DIM; 
        
        if became_active {
            if graph_details.active_transaction == tr.id {
                graph_details.active_transaction = 0;
            } else {
                graph_details.active_transaction = tr.id;
            }
        }
        
        // Amount
        amount_rect, rect = cut_right(rect, 0.2 * transactions_rect.w);
        draw_text_in_rect(amount_rect, tprint("%", formatFloat(tr.amount, trailing_width=2, zero_removal=.NO)), text_color);
        
        // Details
        color_rect, rect = cut_left(rect, 0.01 * transactions_rect.w);
        c: string;
        for *cat: categories_list.categories if cat.id == tr.category_id then {c = cat.color; break;}
        color, ok := hex_to_color(c);
        if !ok then color = Colors.RED;
        draw_rect(color_rect, color);
        draw_text_in_rect(rect, tr.details, text_color);
    }

}

draw_message_popup :: () {
    if !message.text return; 
    popup_height := 50 * dpi_scale;
    min_width := 400 * dpi_scale;
    width := cast(float) Simp.prepare_text(font, message.text);
    rect := make_rect(
        (window_width - max(width, min_width))/2, 
        window_height - popup_height, 
        max(width, min_width) + 20 * dpi_scale, 
        popup_height);
    draw_rect(rect, Colors.MESSAGE_BACKGROUND_ERROR);
    draw_text_in_rect(rect, message.text, centered = true);
    // pen := make_vector2(rect.x + 5 * dpi_scale, rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale);
    // Simp.draw_prepared_text(font, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
}
    
draw_scrollbar :: (wrapper: Rect, content_height: float, ui_id: Ui_Id, parent_ui_id: Ui_Id, scroll_delta: float, to_bottom: bool = false) -> float, bool {
    if content_height <= wrapper.h then return scroll_delta, to_bottom;
    if to_bottom then scroll_delta = content_height - wrapper.h;
    
    scroll_area      := cut_right(wrapper, 10 * dpi_scale);
    scrollbar_line   := cut_right(scroll_area, 2 * dpi_scale);    
    scrollbar        := scroll_area;
    scrollbar.h       = floor(scroll_area.h * scroll_area.h / content_height); 
    percent_scrolled := scroll_delta / content_height;
    scrollbar.y       = scroll_area.y + scroll_area.h - scroll_area.h * percent_scrolled - scrollbar.h;
             
    maybe_set_hot_or_active(ui_id, scroll_area, .PRESSABLE, false);
    
    color : = Colors.BACKGROUND_BRIGHT;
    if is_hovering_over(ui_id) then color = Colors.BACKGROUND_HIGHLIGHT;
    draw_rect(scrollbar, color);
    draw_rect(scrollbar_line, Colors.BACKGROUND_BRIGHT);
    
    // Maybe drag the slider
    if ui.active == ui_id {
        to_bottom = false;
        if mouse.left.just_pressed {
            if mouse_pointer_is_within(scrollbar) {
                scrollbar_grab_point = mouse.pointer.y - scrollbar.y;
            } else {
                scrollbar_grab_point = scrollbar.h /2;
            }
        }            
        new_scrollbar_top := mouse.pointer.y - scrollbar_grab_point + scrollbar.h;
        scroll_delta = content_height * (scroll_area.y + scroll_area.h - new_scrollbar_top) / scroll_area.h;      
    // Maybe mouse wheel    
    } else if is_hovering_over_child(parent_ui_id) && mouse_pointer_is_within(wrapper) { 
        to_bottom = false;
        scroll_delta -= mouse.scroll_y_delta;
    }
    
    return cast(float) clamp(scroll_delta, 0, xx (content_height - wrapper.h)), to_bottom;
}

adjust_height :: (rect: Rect) -> Rect {
    r := rect;
    d := cast(int) (r.h) - (cast(int) r.h % cast(int) LINE_HEIGHT);
    r.y += r.h - d;
    r.h = xx d;
    return r;
}

draw_categories :: (r: Rect) {
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, r, .NORMAL, false);
    
    content_height := categories_list.categories.count * LINE_HEIGHT;    
    categories_rect := draw_title(r, tprint("Categories (%)", categories_list.categories.count));
    add_category_button, wrapper := cut_bottom(categories_rect, LINE_HEIGHT + padding);
    wrapper = adjust_height(wrapper);
    
    if wrapper.h > content_height {
        wrapper.y += wrapper.h - content_height;
        add_category_button.y += wrapper.h - content_height;
        wrapper.h = content_height;
    }
    categories_rect = shrink_x(categories_rect, 15 * dpi_scale);
        
    push_scissor(wrapper);
    
    // Scrollbar
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    categories_list.scroll_delta, categories_list.scroll_to_bottom = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, categories_list.scroll_delta, categories_list.scroll_to_bottom);
    categories_rect.y += categories_list.scroll_delta;
        
    trash_icon_width := prepare_trash_icon();
    
    rect, c : Rect;
    for *category, cat_index: categories_list.categories {
        rect, categories_rect = cut_top(categories_rect, LINE_HEIGHT);
        
        draw_line_separator(rect);
        
        category_line_id := get_ui_id_from_loc_with_index(ui_id, cat_index);
        became_active: bool;
        if mouse_pointer_is_within(wrapper) {
            became_active = maybe_set_hot_or_active(category_line_id, rect, .PRESSABLE);
        }
        
        color_rect, category_rect, icons_rect: Rect;
        icons_rect, rect = cut_right(rect, 20 * dpi_scale);
        color_rect, rect = cut_left(rect, 30 * dpi_scale);
        text_color := Colors.UI_DEFAULT;
                
        // Show icons & change text color on hover
        if category.id != 0 && is_hovering_over(category_line_id) && mouse_pointer_is_within(wrapper)  {
            set_pointer_image(.PRESSABLE);
            text_color = Colors.UI_DIM;
            pen := make_vector2(
                icons_rect.x + (icons_rect.w - trash_icon_width) / 2, 
                icons_rect.y + (icons_rect.h - font.character_height) / 2 + 2 * dpi_scale);
    
            if mouse_pointer_is_within(icons_rect) {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DIM);
                if became_active then categories_list.delete = cat_index;
            } else {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
            }
         }
         
         if became_active && categories_list.delete < 0 {
            categories_list.edit = cat_index;
            new_category = categories_list.categories[categories_list.edit];
        }
        
        // Details
        draw_text_in_rect(rect, category.name, text_color);
        
        // Color icon
        color_rect = shrink(color_rect, 10 * dpi_scale);
        c, ok := hex_to_color(category.color);
        if !ok then category.color = "110000";
        draw_rect(color_rect, c);
    }
    
    pop_scissor();
    
    rect, add_category_button = cut_top(add_category_button, padding);
    add_category_button = set_max_size_button(add_category_button);
    button_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(button_id, add_category_button, .PRESSABLE);
    if became_active then categories_list.add = true;
    draw_button(add_category_button, "Add a new category");
}

draw_rules :: (r: Rect) { 
    ui_id := get_ui_id_from_loc();  
    maybe_set_hot_or_active(ui_id, r, .NORMAL);
    
    count := rules_list.filtered_rules.count;
    content_height := count * LINE_HEIGHT;
    
    rules_rect := draw_title(r, tprint("Rules (%)", count));
    
    filter_panel, category_filter, icon_rect, name_rect: Rect;
    filter_panel, rules_rect = cut_top(rules_rect, LINE_HEIGHT + padding);
    filter_panel = shrink_x(filter_panel, 15 * dpi_scale);
    draw_line_separator(filter_panel);
    
    // Category Filter
    category_filter, filter_panel = cut_right(
        filter_panel, 0.5 * (filter_panel.w - 30 * dpi_scale) + 30 * dpi_scale); // + 30dpi - trash icon width
    category_filter_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(category_filter_id, category_filter, .PRESSABLE, true);
    category_filter, icon_rect = cut_left(category_filter, 85 * dpi_scale); 
    draw_icon(0xf107, icon_rect, Colors.BACKGROUND_BRIGHT);
    if ui.active_input == category_filter_id {
        // Draw dropdown
        rules_list.show_category_dropdown = true;
    } else {
        rules_list.show_category_dropdown = false;
    }
    
    if rules_list.category_filter > -1 {
        draw_text_in_rect(category_filter, get_category_name(rules_list.category_filter), Colors.BACKGROUND_BRIGHT);
    } else {
        draw_text_in_rect(category_filter, "Category", Colors.BACKGROUND_BRIGHT);
    }
    
    name_rect, filter_panel = cut_left(filter_panel, 0.5 * (filter_panel.w - 30 * dpi_scale));
    name_filter_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(name_filter_id, name_rect, .PRESSABLE);
    name_rect, icon_rect = cut_left(name_rect, 50 * dpi_scale);
    draw_text_in_rect(name_rect, "Name", Colors.BACKGROUND_BRIGHT);
    draw_icon(0xf07d, icon_rect, Colors.BACKGROUND_BRIGHT);
    if became_active {
        if rules_list.name_sort == {
            case .none;       rules_list.name_sort = .ascending;
            case .ascending;  rules_list.name_sort = .descending;
            case .descending; rules_list.name_sort = .ascending;
        }
        rules_list.update = true;
    }
    
    add_rule_button, wrapper := cut_bottom(rules_rect, LINE_HEIGHT + padding);
    wrapper = adjust_height(wrapper);
    
    if wrapper.h > content_height {
        wrapper.y += wrapper.h - content_height;
        add_rule_button.y += wrapper.h - content_height;
        wrapper.h = content_height;
    }
    
    rules_rect = shrink_x(rules_rect, 15 * dpi_scale);
    push_scissor(wrapper);
    
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    rules_list.scroll_delta, rules_list.scroll_to_bottom = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, rules_list.scroll_delta, rules_list.scroll_to_bottom);
    rules_rect.y += rules_list.scroll_delta;
    
    trash_icon_width := prepare_trash_icon();
    
    rect: Rect;
    for rule, rule_index: rules_list.filtered_rules {
        rect, rules_rect = cut_top(rules_rect, LINE_HEIGHT);
        draw_line_separator(rect);
        
        rule_line_id := get_ui_id_from_loc_with_index(ui_id, rule_index);
        became_active: bool;
        if mouse_pointer_is_within(wrapper) {
            became_active = maybe_set_hot_or_active(rule_line_id, rect, .PRESSABLE);
        }
        
        details_rect, category_rect, icons_rect: Rect;
        icons_rect, rect = cut_right(rect, 30 * dpi_scale);
        text_color := Colors.UI_DEFAULT;
        
        // Show icons on hover
        if is_hovering_over(rule_line_id) && mouse_pointer_is_within(wrapper) {
            text_color = Colors.UI_DIM;
            pen := make_vector2(icons_rect.x + (icons_rect.w - trash_icon_width) / 2, 
                    icons_rect.y + (icons_rect.h - font.character_height) / 2 + 2 * dpi_scale);
    
            if mouse_pointer_is_within(icons_rect) {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DIM);
                if became_active then rules_list.delete = rule.id;
            } else {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
            }
         }
        
        if became_active && rules_list.delete < 0 {
            rules_list.edit = rule.id;
            new_rule = rule;
        }
                 
        // Details & Category
        details_rect, category_rect = cut_left(rect, 0.5 * rect.w);
        draw_text_in_rect(details_rect, rule.name, text_color);
        draw_text_in_rect(category_rect, get_category_name(rule.category_id), text_color);
    }
    
    pop_scissor();
    
    // Add a new rule
    rect, add_rule_button = cut_top(add_rule_button, padding);
    add_rule_button = set_max_size_button(add_rule_button);
    button_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(button_id, add_rule_button, .PRESSABLE);
    if became_active then rules_list.add = true;
    draw_button(add_rule_button, "Add a new rule");
    
    if rules_list.show_category_dropdown {
        rules_list.category_filter = draw_categories_dropdown(category_filter, rules_list.category_filter);
    }
    
}

draw_dialog_base :: (height: float, width: float) -> dialog: Rect {
    shrink := 30 * dpi_scale; 
    cover := make_rect(10, 10, window_width, window_height);
    draw_rect(cover, Colors.BACKGROUND_TRANSPARENT);
    ui_id_cover := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(ui_id_cover, cover, .NORMAL);
    
    if became_active then set_null_state();
    
    dialog := make_rect(
        cast(float) ((window_width - width) / 2), 
        cast(float) (0.45 * window_height), 
        cast(float) (width * dpi_scale + 2 * shrink), 
        cast(float) (height * dpi_scale));
    draw_rect(dialog, Colors.BACKGROUND_LIGHT);
    
    dialog = shrink_x(dialog, shrink);
    return dialog;
}

draw_edit_transaction_dialog :: (loc := #caller_location) {    
    pad, date_area, details_area, amount_area, category_area, note_area: Rect;
    dialog := draw_dialog_base(260, 600);
    
    ui_id := get_ui_id_from_loc();  
    maybe_set_hot_or_active(ui_id, dialog, .NORMAL);
    
    pad, dialog           = cut_top(dialog, 16 * dpi_scale);
    date_area, dialog     = cut_top(dialog, LINE_HEIGHT);
    details_area, dialog  = cut_top(dialog, LINE_HEIGHT);
    amount_area, dialog   = cut_top(dialog, LINE_HEIGHT);
    category_area, dialog = cut_top(dialog, LINE_HEIGHT);
    note_area, dialog     = cut_top(dialog, LINE_HEIGHT);

    // Transaction's date
    tr_date_id := get_ui_id_from_loc();
    if new_transaction.date == "" then new_transaction.date = copy_string(today_to_string());
    became_active := maybe_set_hot_or_active(tr_date_id, date_area, .PRESSABLE, true);
    if is_hovering_over(tr_date_id) || ui.active_input == tr_date_id then draw_rect(date_area, Colors.SEARCH_RESULT_INACTIVE );
    
    if ui.last_active_input == tr_date_id && ui.active_input != tr_date_id {
        new_date := new_transaction.date;
        ok := date_string_is_valid(new_date);
        if !ok {
            message.show = true;
            message.text = "Date Validation Error: Please enter the date in the format YYYY/MM/DD.";
            message.time_start = cast(Time) get_time();
        }
    }
    
    if ui.active_input == tr_date_id {
        if became_active {
            array_resize(*text_input.text, new_transaction.date.count);
            memcpy(text_input.text.data, new_transaction.date.data, new_transaction.date.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(date_area, input_height);
        draw_text_input(*text_input, input_rect, tr_date_id);
        new_transaction.date = copy_string(cast(string) text_input.text);
    } else {
        draw_text_in_rect(date_area, new_transaction.date);
    }
     
    // Transaction's details
    tr_details_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(tr_details_id, details_area, .PRESSABLE, true);
    if is_hovering_over(tr_details_id) || ui.active_input == tr_details_id then draw_rect(details_area, Colors.SEARCH_RESULT_INACTIVE );
    if ui.active_input == tr_details_id {
        if became_active {
            array_resize(*text_input.text, new_transaction.details.count);
            memcpy(text_input.text.data, new_transaction.details.data, new_transaction.details.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(details_area, input_height);
        draw_text_input(*text_input, input_rect, tr_details_id);
        new_transaction.details = copy_string(cast(string) text_input.text);
    } else {
        if new_transaction.details == "" {
            draw_text_in_rect(details_area, "No transaction's details", Colors.UI_DIM);} 
        else {
            draw_text_in_rect(details_area, new_transaction.details);
        } 
    } 
    
    // Transaction's note
    tr_note_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(tr_note_id, note_area, .PRESSABLE, true);
    if is_hovering_over(tr_note_id) || ui.active_input == tr_note_id { 
        draw_rect(note_area, Colors.SEARCH_RESULT_INACTIVE );
    }

    if ui.active_input == tr_note_id {
        if became_active {
            array_resize(*text_input.text, new_transaction.note.count);
            memcpy(text_input.text.data, new_transaction.note.data, new_transaction.note.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(note_area, input_height);
        draw_text_input(*text_input, input_rect, tr_note_id);
        new_transaction.note = copy_string(cast(string) text_input.text);
    } else {
        if new_transaction.note == "" {
            draw_text_in_rect(note_area, "No note for the transaction", Colors.UI_DIM);
        } else {
            draw_text_in_rect(note_area, new_transaction.note);
        }
    }
    
    // Transaction's amount
    amount := tprint("%", formatFloat(new_transaction.amount, trailing_width=2, zero_removal=.NO));
    tr_amount_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(tr_amount_id, amount_area, .PRESSABLE, true);
    if is_hovering_over(tr_amount_id) || ui.active_input == tr_amount_id {
        draw_rect(amount_area, Colors.SEARCH_RESULT_INACTIVE );
    }
    if ui.active_input == tr_amount_id {
        if became_active {
            array_resize(*text_input.text, amount.count);
            memcpy(text_input.text.data, amount.data, amount.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(amount_area, input_height);
        draw_text_input(*text_input, input_rect, tr_amount_id);
        amount_parsed, ok := parse_float64(*cast(string) text_input.text);
        if ok then new_transaction.amount = amount_parsed;
    } else {
        draw_text_in_rect(amount_area, amount);
    }
    
    // Transaction's category
    tr_category_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(tr_category_id, category_area, .PRESSABLE, true);
    if is_hovering_over(tr_category_id) || ui.active_input == tr_category_id { 
        draw_rect(category_area, Colors.SEARCH_RESULT_INACTIVE); 
    }

    if ui.active_input == tr_category_id {
        // Draw dropdown
        should_show_category_dropdown = true;
        before_category_choose = false;
    } else {
        should_show_category_dropdown = false;
        
        // Predict transaction's category
        if before_category_choose && settings_transactions.add  {
            if new_transaction.details != "" {
                for *r: rules_list.rules {
                    if contains_nocase(new_transaction.details, r.name) { 
                        new_transaction.category_id = r.category_id; 
                        break;
                    }
                }
            }
        }
        draw_text_in_rect(category_area, get_category_name(new_transaction.category_id));
    }
    
    // Buttons
    buttons : Rect;
    buttons, dialog = cut_bottom(dialog, 70 * dpi_scale);
    no, yes := cut_right(buttons, xx (buttons.w / 2));
    
    yes = shrink_y(shrink_x(yes, 0.2 * yes.w), 0.25 * yes.h);    
    no = shrink_y(shrink_x(no, 0.2 * no.w), 0.25 * no.h);   
    
    if settings_transactions.edit > -1 {
        draw_button(yes, "Update");
    } else if settings_transactions.add {
        draw_button(yes, "Add");
    }
    draw_button(no, "Cancel");
    
    ui_id = get_ui_id_from_loc(loc); 
    yes_chosen := maybe_set_hot_or_active(ui_id, yes, .PRESSABLE);
    no_chosen := maybe_set_hot_or_active(ui_id, no, .PRESSABLE);    
    
    // Draw dropdown
    if should_show_category_dropdown {
        wrapper := category_area;
        wrapper.h = min(categories_list.categories.count, 5) * LINE_HEIGHT;;
        wrapper.y = category_area.y + category_area.h - wrapper.h;
        draw_rect(wrapper, Colors.SEARCH_RESULT_INACTIVE);  
        
        ui_id := get_ui_id_from_loc();
        maybe_set_hot_or_active(ui_id, wrapper, .NORMAL, false);
            
        content_height := categories_list.categories.count * LINE_HEIGHT;
        dropdown_rect := wrapper;
        if content_height <= wrapper.h  { // no scroll
            wrapper.y += wrapper.h - content_height;
            wrapper.h = content_height;
            dropdown_rect = wrapper;
        } else { // place for scroll
            dropdown_rect = cut_left(wrapper, wrapper.w - 10 * dpi_scale);
        }
        
        push_scissor(wrapper);
        defer pop_scissor();
        
        scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
        to: bool;
        dropdown_scroll_delta, to = draw_scrollbar(
            wrapper, content_height, scrollbar_id, ui_id, dropdown_scroll_delta);
        dropdown_rect.y += dropdown_scroll_delta; 

        // Chosen category should go first                           
        rect : Rect;        
        rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
        first_category_id := get_ui_id_from_loc_with_index(ui_id, categories_list.categories.count);
        maybe_set_hot_or_active(first_category_id, rect, .PRESSABLE); 
        if is_hovering_over(first_category_id) {
            draw_rect(rect, Colors.BACKGROUND_LIGHT);
        }       
        draw_text_in_rect(rect, get_category_name(new_transaction.category_id));
        
        // Other categories go next 
        for *category, cat_index: categories_list.categories {
            if category.id == new_transaction.category_id then continue;
            rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
            category_line_id := get_ui_id_from_loc_with_index(ui_id, cat_index);
            
            became_active := maybe_set_hot_or_active(category_line_id, rect, .NORMAL);             
            
            if is_hovering_over(category_line_id) && mouse_pointer_is_within(wrapper) {
                draw_rect(rect, Colors.BACKGROUND_LIGHT);
                set_pointer_image(.PRESSABLE);
            }
            
            if became_active && mouse_pointer_is_within(wrapper) { 
                new_transaction.category_id = category.id;
                dropdown_scroll_delta = 0;
            }
            
           draw_text_in_rect(rect, category.name);
        }
    }
    
    if yes_chosen {   
        text_input.text.count = 0;
        
        ok := date_string_is_valid(new_transaction.date);
        if !ok {
            message.show = true;
            message.text = "Date Validation Error: Please enter the date in the format YYYY/MM/DD.";
            message.time_start = cast(Time) get_time();
            return;
        }
        
        if settings_transactions.add {
            id, ok := add_transaction_to_db(
                new_transaction.date, new_transaction.amount, new_transaction.details, new_transaction.note, new_transaction.category_id);
            if !ok then return;  
            new_transaction.id = id;
            array_add(*transactions, new_transaction);
            settings_transactions.scroll_to_bottom = true;
        } else if settings_transactions.edit > -1 { 
            ok := add_transaction_to_db(new_transaction.id, new_transaction.date, new_transaction.amount, new_transaction.details, new_transaction.note, new_transaction.category_id);
            if !ok then return;   
            for *t, index : transactions {
                if t.id == settings_transactions.edit {
                    transactions[index] = new_transaction;                            
                    break;
                }
            }     
        }
        weekly_dashboard_transactions.update = true;
        monthly_dashboard_transactions.update = true;
        settings_transactions.update = true;
        
        set_null_state();
    } else if no_chosen {
        set_null_state();
    }     
}

// Edit and add category
draw_edit_category_dialog :: (loc := #caller_location) {
    pad, name_area, color_area, color_hsv_area, color_hex_area, color_area_slider: Rect;
    dialog := draw_dialog_base(440, 600);
    pad, dialog = cut_top(dialog, 16 * dpi_scale);
    name_area, dialog = cut_top(dialog, LINE_HEIGHT);
    color_area, dialog = cut_top(dialog, 250 * dpi_scale);
    color_hex_area, dialog = cut_top(dialog, LINE_HEIGHT);
    color_hsv_area, dialog = cut_top(dialog, LINE_HEIGHT);
    
    // Categorie's name
    ui_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(ui_id, name_area, .PRESSABLE, true);
    if is_hovering_over(ui_id) || ui.active_input == ui_id then draw_rect(name_area, Colors.SEARCH_RESULT_INACTIVE );
    if ui.active_input == ui_id {
        if became_active {
            array_resize(*text_input.text, new_category.name.count);
            memcpy(text_input.text.data, new_category.name.data, new_category.name.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(name_area, input_height);
        draw_text_input(*text_input, input_rect, ui_id);
        new_category.name = copy_string(cast(string) text_input.text);
    } else {
        if new_category.name == "" then draw_text_in_rect(name_area, "Add category name", Colors.UI_DIM); else draw_text_in_rect(name_area, new_category.name);  
    } 
    
    // Hue slider
    color_area_slider, color_area = cut_bottom(color_area, 20 * dpi_scale);
    color_area_slider.w = 0.99 * color_area_slider.w;
    color_area_slider_1 := color_area_slider;
    color_area_slider_1.w = 0.165 * color_area.w;
    color_area_slider_2 := color_area_slider_1;
    color_area_slider_2.x += 0.165 * color_area.w;
    color_area_slider_3 := color_area_slider_2;
    color_area_slider_3.x += 0.165 * color_area.w;
    color_area_slider_4 := color_area_slider_3;
    color_area_slider_4.x += 0.165 * color_area.w;
    color_area_slider_5 := color_area_slider_4;
    color_area_slider_5.x += 0.165 * color_area.w;
    color_area_slider_6 := color_area_slider_5;
    color_area_slider_6.x += 0.165 * color_area.w;
    
    // Set chosen color
    if !color_picker.load {
        color_picker.hsv = hex_to_hsv(new_category.color); 
        color_picker.load = true;   
    } 
    
    color_hue_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(color_hue_id, color_area_slider, .PRESSABLE);   
    if ui.active == color_hue_id && mouse_pointer_is_within(color_area_slider) {
       color_picker.hsv.hue = ceil((mouse.pointer.x - color_area_slider.x)/color_area_slider.w * 360);
    }
    
    color_area = shrink_y(color_area, 10 * dpi_scale);
    color_area.w = 0.99 * color_area.w;
    color_area_active_color, color_area_sv := cut_left(color_area, 0.3 * color_area.w);
    
    color_sv_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(color_sv_id, color_area_sv, .PRESSABLE);
    
    if ui.active == color_sv_id && mouse_pointer_is_within(color_area_sv) {
        color_picker.hsv.saturation = (mouse.pointer.x - color_area_sv.x)/color_area_sv.w;
        color_picker.hsv.value = (mouse.pointer.y - color_area_sv.y)/color_area_sv.h;
    }
    
    // HEX
    c := hsv_to_color(color_picker.hsv);
    text := tprint("HEX:  #%", color_to_hex(c, true));
    draw_text_in_rect(color_hex_area, text);  
    
    // HSV
    text = tprint("HSV:  %°, %2%%, %3%%", 
        color_picker.hsv.hue, 
        formatFloat(color_picker.hsv.saturation * 100, trailing_width=2, zero_removal=.NO), 
        formatFloat(color_picker.hsv.value * 100, trailing_width=2, zero_removal=.NO));
    draw_text_in_rect(color_hsv_area, text);  
    
    // Draw hue slider
    draw_rect_raw(color_area_slider_1, Color.{r=1, g=0, b=0}, Color.{ r=1, g=0, b=0}, Color.{ r=1, g=1, b=0}, Color.{ r=1, g=1, b=0});
    draw_rect_raw(color_area_slider_2, Color.{ r=1, g=1, b=0}, Color.{ r= 1, g=1, b= 0}, Color.{r=0, g=1, b=0}, Color.{r=0, g=1, b=0});
    draw_rect_raw(color_area_slider_3, Color.{r=0, g=1, b=0}, Color.{r=0, g=1, b=0}, Color.{r=0, g=1, b=1}, Color.{r=0, g=1, b=1});
    draw_rect_raw(color_area_slider_4, Color.{r=0, g=1, b=1}, Color.{r=0, g=1, b=1}, Color.{r=0, g=0, b=1}, Color.{r=0, g=0, b=1});
    draw_rect_raw(color_area_slider_5, Color.{r=0, g=0, b=1}, Color.{r=0, g=0, b=1}, Color.{r=1, g=0, b=1}, Color.{r=1, g=0, b=1});
    draw_rect_raw(color_area_slider_6, Color.{r=1, g=0, b=1}, Color.{r=1, g=0, b=1}, Color.{r=1, g=0, b=0}, Color.{r=1, g=0, b=0});

    // Draw active color
    draw_rect(color_area_active_color, hsv_to_color(color_picker.hsv));
    
    // Draw SV
    draw_rect_raw(
        color_area_sv, 
        hsv_to_color(HSV.{color_picker.hsv.hue, 0, 0}), 
        hsv_to_color(HSV.{color_picker.hsv.hue, 0, 1}), 
        hsv_to_color(HSV.{color_picker.hsv.hue, 1, 0}), 
        hsv_to_color(HSV.{color_picker.hsv.hue, 1, 1}));       
     
    // Buttons
    buttons : Rect;
    buttons, dialog = cut_bottom(dialog, 70 * dpi_scale);
    no, yes := cut_right(buttons, xx (buttons.w / 2));
    
    yes = shrink_y(shrink_x(yes, 0.2 * yes.w), 0.25 * yes.h);    
    no = shrink_y(shrink_x(no, 0.2 * no.w), 0.25 * no.h);   
    
    if categories_list.edit > -1 {
        draw_button(yes, "Update");
    } else if categories_list.add {
        draw_button(yes, "Add");
    }
    draw_button(no, "Cancel");
    
    ui_id = get_ui_id_from_loc(loc); 
    yes_chosen := maybe_set_hot_or_active(ui_id, yes, .PRESSABLE);
    no_chosen := maybe_set_hot_or_active(ui_id, no, .PRESSABLE);
    
    if yes_chosen {    
        if new_category.name == "" {
            message.show = true;
            message.time_start = cast(Time) get_time();
            message.text = "Please provide a category name as it cannot be left empty";
            return;
        }
        text_input.text.count = 0;
        new_category.color = copy_string(hsv_to_hex(color_picker.hsv));
        
        if categories_list.add {
            id, ok := add_category_to_db(new_category.name, new_category.color);
            if !ok then return;
            new_category.id = id;
            array_add(*categories_list.categories, new_category);
            categories_list.scroll_to_bottom = true;
        } else if categories_list.edit > -1 {
            ok := add_category_to_db(new_category.id, new_category.name, new_category.color);
            if !ok then return;   
            categories_list.categories[categories_list.edit] = new_category;
            update_spendings_category(daily_spendings.spendings);
            update_spendings_category(monthly_spendings.spendings);
        }
        set_null_state();
    } else if no_chosen { 
        set_null_state();
    }
}


draw_remove_dialog :: (mode: string, loc := #caller_location) {    
    text : string;
    if mode == {
        case "category"; 
            text = tprint("Are you sure you want to remove category '%'?", categories_list.categories[categories_list.delete].name);
        case "rule"; 
            for rule: rules_list.rules {
                if rule.id == rules_list.delete {
                    text = tprint("Are you sure you want to remove rule '%'?", rule.name);
                    break;
                }
            }
        case "all_transactions"; 
            text = tprint("Are you sure you want to remove all transactions?");
        case "transaction";
            for tr: transactions {
                if tr.id == settings_transactions.delete {
                    text = tprint("Are you sure you want to remove transaction '%'?", tr.details);
                    break;
                }
            }
    }
    width := cast(float) Simp.prepare_text(font, text);
    dialog := draw_dialog_base(120, width + 40);

    // Buttons
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
    
    if yes_chosen if mode == {
        case "category"; 
            category_id := categories_list.categories[categories_list.delete].id;
            ok := delete_category_from_db(category_id);
            if !ok then return;
            array_ordered_remove_by_index(*categories_list.categories, categories_list.delete);
            for *rule: rules_list.rules {
                if rule.category_id == category_id {
                    rule.category_id = 0;
                    ok := add_rule_to_db(rule.name,  rule.category_id);
                    if !ok then return;
                }
            }
            rules_list.update = true;
            set_null_state();
        case "transaction";
            ok := delete_transaction_from_db(settings_transactions.delete);
            if !ok then return;
            for tr, index: transactions {
                if tr.id == settings_transactions.delete {
                    array_ordered_remove_by_index(*transactions, index);
                }
            }
            settings_transactions.update = true;
            set_null_state();
        case "rule"; 
            category := -1;
            ok := delete_rule_from_db(rules_list.delete);
            if !ok then return;
            for rule, index: rules_list.rules {
                if rule.id == rules_list.delete {
                    category = rule.category_id;
                    array_ordered_remove_by_index(*rules_list.rules, index);
                }
            }
            for *tr: transactions {
                if tr.category_id == category {
                    tr.category_id = 0;
                    add_transaction_to_db(tr.id, tr.date, tr.amount, tr.details, tr.note, tr.category_id);
                }
            }
            
            rules_list.update = true;
            set_null_state();  
        case "all_transactions";
            ok := delete_all_transaction_from_db();
            if !ok then return;
            transactions.count = 0;
            settings_transactions.update = true;
    } else  if no_chosen {
        set_null_state();
    }
}

// Edit and add rules
draw_edit_rule_dialog :: (loc := #caller_location) {
    pad, date_area, details_area, amount_area, category_area, note_area: Rect;
    dialog := draw_dialog_base(160, 600);
    pad, dialog = cut_top(dialog, 16 * dpi_scale);
    details_area, dialog = cut_top(dialog, LINE_HEIGHT);
    category_area, dialog = cut_top(dialog, LINE_HEIGHT);
    
    // Rule's details
    ui_details_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(ui_details_id, details_area, .PRESSABLE, true);
    if is_hovering_over(ui_details_id) || ui.active_input == ui_details_id then draw_rect(details_area, Colors.SEARCH_RESULT_INACTIVE );
    if ui.active_input == ui_details_id {
        if became_active {
            array_resize(*text_input.text, new_rule.name.count);
            memcpy(text_input.text.data, new_rule.name.data, new_rule.name.count);
        }
        input_height := cast(float) font_ui.default_line_spacing + 2 * padding;
        input_rect := cut_top(details_area, input_height);
        draw_text_input(*text_input, input_rect, ui_details_id);
        new_rule.name = copy_string(cast(string) text_input.text);
    } else {
        if new_rule.name == "" then draw_text_in_rect(details_area, "Add rule details", Colors.UI_DIM); else draw_text_in_rect(details_area, new_rule.name); 
        
    } 
     
    // Rule's category
    ui_category_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(ui_category_id, category_area, .PRESSABLE, true);
    if is_hovering_over(ui_category_id) || ui.active_input == ui_category_id then draw_rect(category_area, Colors.SEARCH_RESULT_INACTIVE); 

    // predict category based on category_filter
    if before_category_choose && rules_list.add && rules_list.category_filter > -1 {
        new_rule.category_id = rules_list.category_filter;
    }
        
    if ui.active_input == ui_category_id {
        // Draw dropdown
        should_show_category_dropdown = true;
        before_category_choose = false;
    } else {
        should_show_category_dropdown = false;
        draw_text_in_rect(category_area, get_category_name(new_rule.category_id));
    }
    
    // Buttons
    buttons : Rect;
    buttons, dialog = cut_bottom(dialog, 70 * dpi_scale);
    no, yes := cut_right(buttons, xx (buttons.w / 2));
    
    yes = shrink_y(shrink_x(yes, 0.2 * yes.w), 0.25 * yes.h);    
    no = shrink_y(shrink_x(no, 0.2 * no.w), 0.25 * no.h);   
    
    if rules_list.edit > -1 {
        draw_button(yes, "Update");
    } else if rules_list.add {
        draw_button(yes, "Add");
    }
    draw_button(no, "Cancel");
    
    button_id := get_ui_id_from_loc(loc); 
    yes_chosen := maybe_set_hot_or_active(button_id, yes, .PRESSABLE);
    no_chosen := maybe_set_hot_or_active(button_id, no, .PRESSABLE);
    
    if yes_chosen {    
        if new_rule.name == "" {
            message.show = true;
            message.time_start = cast(Time) get_time();
            message.text = "Please provide a rule name as it cannot be left empty";
            return;
        }
        edit_rule_category_id := -1;
        
        if rules_list.edit > -1 {
            for r: rules_list.rules {
                 if r.id == rules_list.edit {
                    edit_rule_category_id = r.category_id;
                    break;
                }
            }
        }
        
        for *tr: transactions {
            if contains_nocase(tr.details, new_rule.name) { 
                tr.category_id = new_rule.category_id; 
                add_transaction_to_db(tr.id, tr.date, tr.amount, tr.details, tr.note, tr.category_id);
                continue;
            }
            
            if rules_list.edit <= -1 continue; 
            if tr.category_id != edit_rule_category_id continue;

            for r: rules_list.rules {
                if r.id == rules_list.edit continue;  
                if contains_nocase(tr.details, r.name) {
                     tr.category_id = r.category_id;
                     add_transaction_to_db(tr.id, tr.date, tr.amount, tr.details, tr.note, tr.category_id);
                     continue tr;
                }
            }
            tr.category_id = 0; // no match, set category to "UNCATEGORISED" 
            add_transaction_to_db(tr.id, tr.date, tr.amount, tr.details, tr.note, tr.category_id);
        }
        
        text_input.text.count = 0;
        settings_transactions.update = true;
        rules_list.update = true;
        weekly_dashboard_transactions.update = true;
        monthly_dashboard_transactions.update = true;
        monthly_spendings = update_spendings_data(monthly_spendings, .monthly);
        
        if rules_list.add {
            ok := add_rule_to_db(new_rule.name,  new_rule.category_id);
            if !ok then return;
            array_add(*rules_list.rules, new_rule);
            rules_list.scroll_to_bottom = true;
        } else if rules_list.edit > -1 {
            ok := add_rule_to_db(new_rule.id, new_rule.name,  new_rule.category_id);
            if !ok then return;   
            for *rule : rules_list.rules {
                if rule.id == rules_list.edit {
                    <<rule = new_rule;                            
                    break;
                }
            }
        }
        set_null_state();
    } else if no_chosen {
        set_null_state();
    }
 
    // Draw dropdown
    if should_show_category_dropdown {
        wrapper := category_area; wrapper.h = min(categories_list.categories.count, 5) * LINE_HEIGHT;
        wrapper.y = category_area.y + category_area.h - wrapper.h;
        
        dropdown_id := get_ui_id_from_loc();
        maybe_set_hot_or_active(dropdown_id, wrapper, .NORMAL, false);
    
        draw_rect(wrapper, Colors.SEARCH_RESULT_INACTIVE);  
        
        content_height := categories_list.categories.count * LINE_HEIGHT;
        if wrapper.h > content_height {
            wrapper.y += wrapper.h - content_height;
            wrapper.h = content_height;
        }
        
        dropdown_rect := cut_left(wrapper, wrapper.w - 10*dpi_scale);
        
        push_scissor(wrapper);
        defer pop_scissor();
        
        scrollbar_id := get_ui_id_from_loc(parent_id = dropdown_id);
        to: bool;
        dropdown_scroll_delta, to = draw_scrollbar(wrapper, content_height, scrollbar_id, dropdown_id, dropdown_scroll_delta);
        dropdown_rect.y += dropdown_scroll_delta;
                           
        // Chosen category should go first                           
        rect : Rect;        
        rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
        first_category_id := get_ui_id_from_loc_with_index(dropdown_id, categories_list.categories.count);
        maybe_set_hot_or_active(first_category_id, rect, .PRESSABLE); 
        if is_hovering_over(first_category_id) {
            draw_rect(rect, Colors.BACKGROUND_LIGHT);
        }
        draw_text_in_rect(rect,  get_category_name(new_rule.category_id));                   
                
        // Other categories go next 
        for *category, cat_index: categories_list.categories {
            if category.id == new_rule.category_id  continue;
            rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
            category_line_id := get_ui_id_from_loc_with_index(dropdown_id, cat_index);
            
            became_active := maybe_set_hot_or_active(category_line_id, rect, .NORMAL);
                        
            if is_hovering_over(category_line_id) && mouse_pointer_is_within(wrapper) {
                draw_rect(rect, Colors.BACKGROUND_LIGHT);
                set_pointer_image(.PRESSABLE);
            }
               
            if became_active && mouse_pointer_is_within(wrapper) {  
                new_rule.category_id = category.id;
                dropdown_scroll_delta = 0;
            }
            
            draw_text_in_rect(rect, category.name);
        }
    }
}

draw_icon :: (icon_unicode: u16, icon_rect: Rect, color: Color = Colors.UI_DEFAULT) {
    icon_char := convert_utf32_to_utf8(xx icon_unicode);
    Simp.prepare_text(font_icons, to_string(*icon_char));
    pen := make_vector2(icon_rect.x, 
                        icon_rect.y + (icon_rect.h - font.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, color);
}

prepare_trash_icon :: () -> float {
    trash_icon_unicode := 0xf1f8;
    trash_icon_char := convert_utf32_to_utf8(xx trash_icon_unicode);
    return  cast(float) Simp.prepare_text(font_icons, to_string(*trash_icon_char));
}

draw_settings_transactions :: (r: Rect) {
    date_rect, details_rect, amount_rect, category_rect, icons_rect, icon_rect, rect, pad, category_filter, subtotal_rect: Rect; 
    count := transactions_filtered.count;
        
    content_height := count * LINE_HEIGHT;
    transactions_rect := draw_title(r, tprint("Transactions (%)", count));
    
    transactions_filter_panel: Rect;
    transactions_filter_panel, transactions_rect = cut_top(transactions_rect, LINE_HEIGHT + padding);
    pad, transactions_filter_panel = cut_top(transactions_filter_panel, padding);
    transactions_filter_panel = shrink_x(transactions_filter_panel, 0.02 * transactions_filter_panel.w);
    draw_line_separator(transactions_filter_panel);
    transactions_buttons, wrapper := cut_bottom(transactions_rect, LINE_HEIGHT*2 + padding);
    wrapper = adjust_height(wrapper);
    if wrapper.h > content_height {
        wrapper.y += wrapper.h - content_height;
        transactions_buttons.y += wrapper.h - content_height;
        wrapper.h = content_height;
    }
    
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, wrapper, .NORMAL);
    
    transactions_rect = shrink_x(wrapper, 0.02 * wrapper.w);
    line_width := transactions_filter_panel.w;
    push_scissor(wrapper);
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    settings_transactions.scroll_delta, settings_transactions.scroll_to_bottom = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, settings_transactions.scroll_delta, settings_transactions.scroll_to_bottom);
    transactions_rect.y += settings_transactions.scroll_delta;
        
    // Trash icon
    trash_icon_unicode := 0xf1f8;
    trash_icon_char := convert_utf32_to_utf8(xx trash_icon_unicode);
          
    for tr, tr_index: transactions_filtered {
        rect, transactions_rect = cut_top(transactions_rect, LINE_HEIGHT);
        
        draw_rect(rect, Colors.BACKGROUND_LIGHT); 
        draw_line_separator(rect);
        
        tr_line_id := get_ui_id_from_loc_with_index(ui_id, tr_index);
        became_active := maybe_set_hot_or_active(tr_line_id, rect, .NORMAL) && mouse_pointer_is_within(wrapper);
    
        icons_rect, rect = cut_right(rect, 20 * dpi_scale);
                
        text_color := Colors.UI_DEFAULT;
        // Show icons on hover
        if is_hovering_over(tr_line_id) && mouse_pointer_is_within(wrapper) {
            set_pointer_image(.PRESSABLE);
            text_color = Colors.UI_DIM;
            trash_icon_width := Simp.prepare_text(font_icons, to_string(*trash_icon_char));
            pen := make_vector2(
                icons_rect.x + (icons_rect.w - trash_icon_width) / 2, 
                icons_rect.y + (icons_rect.h - font.character_height) / 2 + 2 * dpi_scale);
    
            if mouse_pointer_is_within(icons_rect) {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DIM);
                if became_active then settings_transactions.delete = tr.id;
            } else {
                Simp.draw_prepared_text(font_icons, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
            }
         }
        
        // Edit transaction
        if became_active && settings_transactions.delete < 0 {
            settings_transactions.edit = tr.id;
            for t: transactions {
                if t.id == tr.id {
                    new_transaction = t;
                    break;
                }
            }
        }
        
        // Date
        date_rect, rect = cut_left(rect, 150 * dpi_scale);
        draw_text_in_rect(date_rect, tr.date, text_color);
        
        // Category
        category_rect, rect = cut_right(rect, 0.1 * line_width);
        draw_text_in_rect(category_rect, get_category_name(tr.category_id), text_color);
        
        // Amount
        amount_rect, rect = cut_right(rect, 0.1 * line_width);
        draw_text_in_rect(amount_rect, tprint("%", formatFloat(tr.amount, trailing_width=2, zero_removal=.NO)), text_color);
        
        // Details
        draw_text_in_rect(rect, tr.details, text_color);
    }
    
     pop_scissor();
     
     // Draw buttons at the bottom
     transactions_buttons = shrink_x(transactions_buttons, 0.02 * transactions_buttons.w);
     subtotal_rect, transactions_buttons = cut_top(transactions_buttons, LINE_HEIGHT);
     subtotal_rect, pad = cut_right(subtotal_rect, 0.2 * line_width + 20 * dpi_scale); // 20 * dpi_scale - icon_width
     draw_text_in_rect(subtotal_rect, 
                        tprint("%", formatFloat(settings_transactions.subtotal, trailing_width=2, zero_removal=.NO)), 
                        Colors.UI_DIM);
     
     transactions_buttons = shrink_x(transactions_buttons, 0.1 * transactions_buttons.w);
     rect, transactions_buttons = cut_top(transactions_buttons, padding);
     upload_button := transactions_buttons;
     upload_button.w = 250 * dpi_scale;
     
     add_button := upload_button;
     add_button.x += (transactions_buttons.w - add_button.w) / 2;
     
     remove_all_button := upload_button;   
     remove_all_button.x += transactions_buttons.w - remove_all_button.w;  
     
    draw_button(upload_button, "Upload transactions");
    upload_button_id := get_ui_id_from_loc();
    became_active := maybe_set_hot_or_active(upload_button_id, upload_button, .PRESSABLE);
    if became_active {
        file_name, ok := get_upload_file_name();
        if !ok return;
        ok = upload_transactions_from_file(file_name);
        if !ok return;
        ok = get_all_transactions_from_db();
        if !ok return;
        settings_transactions.update = true;
    }
    
    if transactions_filtered.count > 0 {
        draw_button(remove_all_button, "Remove all transactions");
        remove_all_tr_id := get_ui_id_from_loc();
        became_active = maybe_set_hot_or_active(remove_all_tr_id, remove_all_button, .PRESSABLE);
        if became_active then settings_transactions.remove_all = true;
    }
    
    draw_button(add_button, "Add a new transaction");
    add_tr_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(add_tr_id, add_button, .PRESSABLE);
    if became_active {
         settings_transactions.add = true;
         before_category_choose = true;
    }
    
     // Filter && Sort
    
    // Date Sort
    date_rect, transactions_filter_panel = cut_left(transactions_filter_panel, 150 * dpi_scale);
    date_filter_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(date_filter_id, date_rect, .PRESSABLE);
    date_rect, icon_rect = cut_left(date_rect, 50 * dpi_scale);
    draw_text_in_rect(date_rect, "Date", Colors.BACKGROUND_BRIGHT);
    draw_icon(0xf07d, icon_rect, Colors.BACKGROUND_BRIGHT);
    if became_active {
        transaction_filter.amount_sort = .none;
        if transaction_filter.date_sort == {
            case .none;       transaction_filter.date_sort = .ascending;
            case .ascending;  transaction_filter.date_sort = .descending;
            case .descending; transaction_filter.date_sort = .ascending;
        }
        settings_transactions.update = true;
    }
    
    // Category Filter
    category_filter, transactions_filter_panel = cut_right(
        transactions_filter_panel, 0.1 * line_width + 20 * dpi_scale); // + 20dpi - trash icon width
    category_filter_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(category_filter_id, category_filter, .PRESSABLE, true);
    category_filter, icon_rect = cut_left(category_filter, 85 * dpi_scale); 
    draw_icon(0xf107, icon_rect, Colors.BACKGROUND_BRIGHT);
    if ui.active_input == category_filter_id {
        // Draw dropdown
        should_show_category_dropdown = true;
    } else {
        should_show_category_dropdown = false;
    }
    
    if transaction_filter.category_filter > -1 {
        draw_text_in_rect(category_filter, get_category_name(transaction_filter.category_filter), Colors.BACKGROUND_BRIGHT);
    } else {
        draw_text_in_rect(category_filter, "Category", Colors.BACKGROUND_BRIGHT);
    }
    
    // Amount Sort
    amount_rect, transactions_filter_panel = cut_right(transactions_filter_panel, 0.1 * line_width);
    amount_filter_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(amount_filter_id, amount_rect, .PRESSABLE);
    amount_rect, icon_rect = cut_left(amount_rect, 65 * dpi_scale);;
    draw_text_in_rect(amount_rect, "Amount", Colors.BACKGROUND_BRIGHT);
    draw_icon(0xf07d, icon_rect, Colors.BACKGROUND_BRIGHT);
    if became_active {
        transaction_filter.date_sort = .none;
        if transaction_filter.amount_sort == {
            case .none;       transaction_filter.amount_sort = .ascending;
            case .ascending;  transaction_filter.amount_sort = .descending;
            case .descending; transaction_filter.amount_sort = .ascending;
        }
        settings_transactions.update = true;
    }
    
    // Details Filter
    transactions_filter := transactions_filter_panel;
    icon_rect = transactions_filter;
    icon_rect.w = 20 * dpi_scale;
    transactions_filter = shrink_x(transactions_filter, 20 * dpi_scale);
    draw_icon(0xf002, icon_rect, Colors.SELECTION_ACTIVE);
    
    tr_filter_id := get_ui_id_from_loc();
    became_active = maybe_set_hot_or_active(tr_filter_id, transactions_filter, .PRESSABLE, true);
    input_height := cast(float) font_ui.default_line_spacing + 3 * padding;
    input_rect := cut_top(transactions_filter, input_height);
    
    if ui.active_input == tr_filter_id {
        draw_text_input(*text_input, input_rect, tr_filter_id, Colors.UI_DIM);
        if key_pressed {
            transaction_filter.transactions_search = copy_string(cast(string) text_input.text);
            settings_transactions.update = true;
        } 
    } else {
        rect := snap_to_grid(input_rect);
        draw_rect(rect, Colors.BACKGROUND);
        draw_line_separator(rect);
        draw_text_in_rect(rect, transaction_filter.transactions_search, Colors.UI_DIM);
    }
    
    // Draw dropdown
    if should_show_category_dropdown {
        transaction_filter.category_filter = draw_categories_dropdown(category_filter, transaction_filter.category_filter);
    }
}

draw_categories_dropdown :: (r: Rect, category_filter: int) -> int{
    wrapper := r;
    wrapper.h = min(categories_list.categories.count, 5) * LINE_HEIGHT;
    wrapper.y = r.y - wrapper.h;
    min_width := cast(float) Simp.prepare_text(font, "All categories");
    wrapper.w = min_width + 20 * dpi_scale;
    draw_rect(wrapper, Colors.SEARCH_RESULT_INACTIVE); 
    
    ui_id := get_ui_id_from_loc();
    maybe_set_hot_or_active(ui_id, wrapper, .NORMAL, false);

    content_height := categories_list.categories.count * LINE_HEIGHT;
    dropdown_rect := wrapper;
    if content_height <= wrapper.h  { // no scroll
        wrapper.y += wrapper.h - content_height;
        wrapper.h = content_height;
        dropdown_rect = wrapper;
    } else { // place for scroll
        dropdown_rect = cut_left(wrapper, wrapper.w - 10 * dpi_scale);
    }
    
    push_scissor(wrapper);
    defer pop_scissor();
    
    scrollbar_id := get_ui_id_from_loc(parent_id = ui_id);
    to: bool;
    dropdown_scroll_delta, to = draw_scrollbar(
        wrapper, content_height, scrollbar_id, ui_id, dropdown_scroll_delta);
    dropdown_rect.y += dropdown_scroll_delta;
    
    draw_line :: (rect: Rect, category: *Category, ui_id: Ui_Id, wrapper: Rect, category_filter: int) -> int {
        became_active := maybe_set_hot_or_active(ui_id, rect, .NORMAL);   
        
        if is_hovering_over(ui_id) && mouse_pointer_is_within(wrapper) {
            draw_rect(rect, Colors.BACKGROUND_LIGHT);
            set_pointer_image(.PRESSABLE);
        }
               
        if became_active && mouse_pointer_is_within(wrapper) {  
            category_filter = category.id;
            dropdown_scroll_delta = 0;
            settings_transactions.update = true;
            rules_list.update = true;
        }
        
        draw_text_in_rect(rect, category.name);
        return category_filter;
    }
    
    rect: Rect;
    if category_filter != -1 {
        category_line_id := get_ui_id_from_loc_with_index(ui_id, categories_list.categories.count);
        rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
        category := Category.{name="All categories", id=-1};
        category_filter = draw_line(rect, *category, category_line_id, wrapper, category_filter);
    }                    
    for *category, cat_index: categories_list.categories {
        if category.id == category_filter continue;
        rect, dropdown_rect = cut_top(dropdown_rect, LINE_HEIGHT);
        category_line_id := get_ui_id_from_loc_with_index(ui_id, cat_index);
        category_filter = draw_line(rect, category, category_line_id, wrapper, category_filter);
    }
    
    return category_filter;
}

draw_text_input :: (using text_input: *Text_Input, r: Rect, ui_id: Ui_Id, color: Color = Colors.UI_DEFAULT) {
    input_rect := r;

    rect := snap_to_grid(input_rect);
    draw_rect(rect, Colors.BACKGROUND);
    draw_line_separator(rect);

    push_scissor(rect);
    defer pop_scissor();

    became_active := maybe_set_hot_or_active(ui_id, rect, .TEXT_SELECT);
    // TODO: when activated, make it so that the keyboard events are sent to the input

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
    Simp.draw_text(font_ui, xx text_start_x, xx y, to_string(text), color);
}

draw_line_separator :: (rect: Rect) {
    bottomline := rect;
    bottomline.h = 1;
    draw_rect(bottomline, Colors.SELECTION_ACTIVE);
}

draw_title_bottom_line :: (rect: Rect) {
    title_bottomline := rect;
    title_bottomline.h = 3 * dpi_scale;
    draw_rect(title_bottomline, Colors.SELECTION_ACTIVE);
}

draw_title :: (r: Rect, title: string) -> Rect {
    title_rect, rect := cut_top(r, 50 * dpi_scale);

    draw_title_bottom_line(title_rect);

    width := cast(float) Simp.prepare_text(font_ui_bold, title);
    pen := make_vector2(title_rect.x + (title_rect.w - width)/2, title_rect.y + (title_rect.h - font_ui_bold.character_height) / 2 + 2 * dpi_scale);
    Simp.draw_prepared_text(font_ui_bold, xx pen.x, xx pen.y, Colors.UI_DEFAULT);
    
    return rect;
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

draw_text_in_rect :: (rect : Rect, text: string, color : Color = Colors.UI_DEFAULT, centered : bool = false) {
    if !text return; 
    width := cast(float) Simp.prepare_text_with_max_width(font, text, xx (rect.w - 5 * dpi_scale));
    x := rect.x + 5 * dpi_scale;
    if centered then x = rect.x + (rect.w - width)/2;
    pen := Vector2.{
        x, 
        rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale};
    Simp.draw_prepared_text(font, xx pen.x, xx pen.y, color);
} 

draw_button :: (rect : Rect, text: string) {
    draw_rect(rect, Colors.BACKGROUND_BRIGHT);
    text_width := cast(float) Simp.prepare_text(font, text);
    text_pen := Vector2.{
        rect.x + (rect.w - text_width)/2, 
        rect.y + (rect.h - font.character_height) / 2 + 2 * dpi_scale};
    Simp.draw_prepared_text(font, xx text_pen.x, xx text_pen.y, Colors.UI_DEFAULT);
}

set_max_size_button :: (r: Rect) -> Rect {
    button := r;
    if button.w > MAX_BUTTON_SIZE {
        button = shrink_x(button, (button.w - MAX_BUTTON_SIZE)/2);
    }
    return button;
}


maybe_set_hot_or_active :: (ui_id: Ui_Id, rect: Rect, pointer_image: Pointer_Image) -> became_active: bool {
    if !mouse_pointer_is_within(rect) return false;

    ui.hot = ui_id;
    if ui.hot_last_frame == ui_id && ui.active == .none || ui.active == ui_id then set_pointer_image(pointer_image);
    if ui.hot_last_frame == ui_id && ui.active == .none && mouse.left.just_pressed {
        ui.last_active_input = ui.active_input;
        ui.active_input = .none; 
        ui.active = ui_id;
        return true;
    }
    
    return false;
}

maybe_set_hot_or_active :: (ui_id: Ui_Id, rect: Rect, pointer_image: Pointer_Image, is_input: bool) -> became_active: bool {
    if !mouse_pointer_is_within(rect) return false;

    ui.hot = ui_id;
    if ui.hot_last_frame == ui_id && ui.active == .none || ui.active == ui_id then set_pointer_image(pointer_image);
    if ui.hot_last_frame == ui_id && ui.active == .none && mouse.left.just_pressed {
        ui.active = ui_id;
        if is_input {
            ui.last_active_input = ui.active_input;
            ui.active_input = ui_id; 
        }
        return true;
    }
    
    return false;
}

is_hovering_over :: (ui_id: Ui_Id) -> bool {
    return (ui.hot_last_frame == ui_id && ui.active == .none) || ui.active == ui_id;
}

is_hovering_over_child :: (parent_id: Ui_Id) -> bool {
    child := is_child_with_index(ui.hot_last_frame, parent_id);
    return is_hovering_over(parent_id) || (child && ui.active == .none) || child;
}

get_ui_id_from_loc :: inline (loc := #caller_location, parent_id: Ui_Id = .none) -> Ui_Id {
    if parent_id != .none {
        return cast(Ui_Id) (loc.line_number + NUM_LINES_OF_CODE * cast(s64) parent_id);
    }
    return cast(Ui_Id) loc.line_number;
}

get_ui_id_from_loc_with_index :: inline (parent_id: Ui_Id, index: int) -> Ui_Id {
    return cast(Ui_Id) (NUM_LINES_OF_CODE * cast(s64) parent_id * (index + 100));
}

is_child :: (ui_id: Ui_Id, parent_id: Ui_Id) -> bool {
    // A ui id is considered a child if it was obtained by the get_ui_id_from_loc function above
    num := cast(s64) ui_id;
    parent_min := cast(s64) parent_id * NUM_LINES_OF_CODE;
    parent_max := parent_min + NUM_LINES_OF_CODE - 1;
    return parent_min <= num && num <= parent_max;
}

is_child_with_index :: (ui_id: Ui_Id, parent_id: Ui_Id) -> bool {
    return ui_id % parent_id == 0;
}

push_scissor :: (rect: Rect) {
    set_scissor(rect);
    array_add(*scissor_stack, rect);
}

pop_scissor :: () {
    Simp.immediate_flush();  // if we have any remaining vertices, flush them before removing the scissor
    
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
    active_input: Ui_Id = .none;
    last_active_input: Ui_Id = .none;
};


// !!!!!!!!!!!!!!!!!!!!!! TEMPORARY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

#scope_export

text_input: Text_Input;

// !!!!!!!!!!!!!!!!!!!!!! TEMPORARY !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



// Please keep at the bottom - needed for ui elements parent-child relationships
NUM_LINES_OF_CODE :: #run #location().line_number;