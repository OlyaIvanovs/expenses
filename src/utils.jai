to_string :: (bytes: [] u8) -> string {
    s: string = ---;
    s.data  = bytes.data;
    s.count = bytes.count;
    return s;
}