text_input_handle_keypress :: (using text_input: *Text_Input, key_code: Input.Key_Code, mods: Mods) {
    if key_code == {
        case .ARROW_RIGHT;
            if cursor.sel != cursor.pos && !mods.shift_pressed {
                cursor.pos = max(cursor.pos, cursor.sel);
            } else if only_ctrl_pressed(mods) && cursor.pos != text.count {
                arr : []u8 = ---;
                arr.data = text.data + cursor.pos;
                arr.count = text.count - cursor.pos;
                ok, pos := array_find(arr, #char " ");
                if pos == 0 {
                    arr.data += 1;
                    arr.count -= 1;
                    ok, pos = array_find(arr, #char " ");
                    if pos == -1 {
                        pos = text.count - cursor.pos;
                    } else {
                        pos += 1;
                    }
                }
                cursor.pos += cast(s32) pos;
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
        case .HOME;
            cursor.pos = 0;
            cursor.sel = 0;
        case .END;
            cursor.pos = cast(s32) text.count;
            cursor.sel = cast(s32) text.count;
        case #char "A";
            if only_ctrl_pressed(mods) {
                cursor.sel = 0;
                cursor.pos = cast(s32) text.count;
            }
        case #char "C";
            if only_ctrl_pressed(mods) && cursor.pos != cursor.sel { // Copy to clipboard: CTRL + C
                copy_text := slice(to_string(text), min(cursor.pos, cursor.sel), abs(cursor.sel - cursor.pos));
                Clipboard.os_clipboard_set_text(copy_text);
            }
        case #char "V";
            if only_ctrl_pressed(mods) { // Paste from clipboard: CTLR + V
                paste_text := Clipboard.os_clipboard_get_text();
                if cursor.sel != cursor.pos {
                    array_remove_slice(*text, min(cursor.sel, cursor.pos), abs(cursor.pos - cursor.sel));
                }
                array_insert_slice(*text, cursor.pos, xx paste_text);
                cursor.pos += cast(s32) paste_text.count;
                cursor.sel = cursor.pos;
            }
        case #char "X";
            if only_ctrl_pressed(mods) {
                if cursor.sel != cursor.pos {
                    cursor.pos = min(cursor.pos, cursor.sel);
                    array_remove_slice(*text, cursor.pos, abs(cursor.pos - cursor.sel));
                    cursor.sel = cursor.pos;
                }
            }
        case .DELETE;
            if cursor.sel != cursor.pos {
                cursor.pos = min(cursor.pos, cursor.sel);
                array_remove_slice(*text, cursor.pos, abs(cursor.pos - cursor.sel));
                cursor.sel = cursor.pos;
            }
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