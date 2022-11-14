draw_one_frame :: () {
    Simp.clear_render_target(.05, .08, .15, 1);

    upload_button_wrapper : Rect;
    categories_rect, main_area := cut_left(screen, 300 * dpi_scale);
    upload_button_wrapper, categories_rect = cut_top(categories_rect, 50 * dpi_scale);
    upload_button := shrink_y(shrink_x(upload_button_wrapper, 100 * dpi_scale), 12 * dpi_scale);

    draw_rect(categories_rect, Colors.BACKGROUND_LIGHT);

    maybe_set_hot_or_active(.upload_button, upload_button, .PRESSABLE);

    button_color := ifx ui.hot_last_frame == .upload_button then Colors.BACKGROUND_HIGHLIGHT else Colors.BACKGROUND_LIGHT;
    if ui.active == .upload_button {
        button_color = Colors.RED;
    }
    draw_rect(upload_button, button_color);

    // Print categories
    for categories {
        ui_id := cast(Ui_Id) (100 + it_index);
        color := ifx ui.hot_last_frame == ui_id then Colors.RED else Colors.UI_DEFAULT;
        Simp.draw_text(font, xx (categories_rect.x + 10 * dpi_scale), xx (categories_rect.y + categories_rect.h - (line_height * (it_index + 1))), it.name, color);
    }

    // Draw graph
    main_area = shrink(main_area, 50);
    draw_rect(main_area, Colors.BACKGROUND_HIGHLIGHT);

    width_bar := 40 * dpi_scale;
    for daily_spendings_graph {
        r := make_rect(main_area.x + it_index * 2 * width_bar , main_area.y + 10 * dpi_scale, width_bar, xx it.total_spent * dpi_scale);
        ui_id := cast(Ui_Id) (100 + it_index);
        maybe_set_hot_or_active(ui_id, r, .PRESSABLE);
        color := ifx ui.hot_last_frame == ui_id then Colors.BACKGROUND_BRIGHT else Colors.RED;
        draw_rect(r, color);
        if ui.hot_last_frame == ui_id {
            s := tprint("%",it.total_spent);
            Simp.draw_text(font, xx r.x, xx (r.y + r.h + 10 * dpi_scale), s, Colors.RED);
        }
    }

    // for day : 1..31 {
    //     errmsg : *u8;
    //     result := sqlite3_exec(db, init_sql, null, null, *errmsg);
    //     if result != SQLITE_OK {
    //         log_error("ERROR: %\n",from_c_string(errmsg));
    //     }
    // }

    // [
    //     { date: 2022/01/02, food: 300, ljkldkf: 4534}
    //     { date: 2022/01/02, food: 300, ljkldkf: 4534}
    //     { date: 2022/01/02, food: 300, ljkldkf: 4534}
    //     { date: 2022/01/02, food: 300, ljkldkf: 4534}
    // ]

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
    print("UI %\n", ui);
    if ui.hot_last_frame == ui_id || ui.active == ui_id then set_pointer_image(pointer_image);
    if ui.hot_last_frame == ui_id && ui.active == .none && mouse.left.just_pressed {
        ui.active = ui_id;
        return true;
    }

    return false;
}

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
