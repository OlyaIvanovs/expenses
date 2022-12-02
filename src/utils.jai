// to_string :: (bytes: [] u8) -> string {
//     s: string = ---;
//     s.data  = bytes.data;
//     s.count = bytes.count;
//     return s;
// }

array_remove_slice :: (array: *[] u8, start: s64, count: s64) {
    assert(start >= 0 && start + count <= array.count);
    memcpy(array.data + start, array.data + start + count, count);
    array.count -= count;
}

array_insert_slice :: (array: *[..] u8, start: s64, slice: [] u8) {
    assert(start  >= 0);
    old_count := array.count;
    array_resize(array, array.count + slice.count);

    end : [] u8 = ---;
    end.data = array.data + start;
    end.count = old_count - start;
    end = array_copy_into_temp(end);

    memcpy(array.data + start, slice.data, slice.count);
    memcpy(array.data + start + slice.count, end.data, end.count);
}

array_copy_into_temp :: (array: [] $T) -> [] T {
    dest := NewArray(array.count, T, initialized=false, allocator=temp);
    memcpy(dest.data, array.data, array.count * size_of(T));
    return dest;
}