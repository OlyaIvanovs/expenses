Csv_File :: struct(num_cols: int) {
    raw_content: string;
    rows: [] Csv_Row(num_cols);
}

Csv_Row :: struct(num_cols: int) {
    fields: [num_cols]string;
}

read_csv :: (filename: string, sep: string, skip_top_lines: int, $num_cols: int) -> Csv_File(num_cols) {
    content, success := read_entire_file(filename);
    assert(success);

    rows: [..] Csv_Row(num_cols);

    lines := split(content, "\n");
    for line, line_num : lines {
        if line_num < skip_top_lines continue;
        trimmed := trim_right(line, " \r");
        elems := split(trimmed, ",");
        if elems.count != num_cols continue;

        row := array_add(*rows);
        for i : 0..num_cols-1 {
            row.fields[i] = elems[i];
        }
    }

    result: Csv_File(num_cols) = ---;
    result.raw_content = content;
    result.rows = rows;

    return result;
}