text_input_handle_keypress :: (using text_input: *Text_Input, key_code: Input.Key_Code, mods: Mods) {
    if key_code == {
        
    }
}


text_input_type_char :: (using text_input: *Text_Input, char: u8) {
    // cursor.pos = clamp(cursor.pos, 0, text.count - 1);
    // cursor.sel = clamp(cursor.sel, 0, text.count - 1);
    
    // TODO: replace selection if exists
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