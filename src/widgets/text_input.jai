text_input_handle_keypress :: (using text_input: *Text_Input, key_code: Input.Key_Code, mods: Mods) {
    if key_code == {
        case .ARROW_RIGHT;
            if cursor.sel != cursor.pos && !mods.shift_pressed {
                cursor.pos = max(cursor.pos, cursor.sel);
            } else {
                cursor.pos += 1;
            }
            if !mods.shift_pressed {
                cursor.sel = cursor.pos;  // remove selection
            }
        case .ARROW_LEFT;
            if cursor.sel != cursor.pos && !mods.shift_pressed {
                cursor.pos = min(cursor.sel, cursor.pos);
            } else {
                cursor.pos -= 1;
            }
            if !mods.shift_pressed {
                cursor.sel = cursor.pos;  // remove selection
            }
        case .BACKSPACE;
            if cursor.pos != cursor.sel {
                // Delete selected text
                array_remove_slice(*text, min(cursor.sel, cursor.pos), abs(cursor.pos - cursor.sel));
                cursor.pos = min(cursor.pos, cursor.sel);
                cursor.sel = cursor.pos;
            } else if cursor.pos > 0 {
                cursor.pos -= 1;
                array_ordered_remove_by_index(*text, cursor.pos);
                cursor.sel = cursor.pos;
            }
        case .DELETE;
            // TODO
    }
    cursor.pos = clamp(cursor.pos, 0, xx (text.count));
    cursor.sel = clamp(cursor.sel, 0, xx (text.count));
    // if !mods.shift_pressed {
    //     cursor.sel = cursor.pos;  // remove selection
    // }
}


text_input_type_char :: (using text_input: *Text_Input, char: u8) {
    if cursor.pos != cursor.sel {
        array_remove_slice(*text, min(cursor.sel, cursor.pos), abs(cursor.pos - cursor.sel));
        cursor.pos = min(cursor.pos, cursor.sel);
        cursor.sel = cursor.pos;
    }

    print("cursor pos % cursor sel %", cursor.pos, cursor.sel);

    array_insert_at(*text, char, cursor.pos);
    cursor.pos += 1;
    cursor.sel = cursor.pos;  // remove selection
}

Text_Input :: struct {
    text: [..] u8;
    cursor: struct { pos: s32; sel: s32; };
    scroll_x: s32;
    // scroll_anim: Tween_Animation(s32);
}