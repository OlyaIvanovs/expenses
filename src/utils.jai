to_string :: (bytes: [] u8) -> string {
    s: string = ---;
    s.data  = bytes.data;
    s.count = bytes.count;
    return s;
}

array_remove_slice :: (array: *[] u8, start: s64, count: s64) {
    assert(start >= 0 && start + count <= array.count);
    memcpy(array.data + start, array.data + start + count, count);
    array.count -= count;
}

