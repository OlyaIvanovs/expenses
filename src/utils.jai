// to_string :: (bytes: [] u8) -> string {
//     s: string = ---;
//     s.data  = bytes.data;
//     s.count = bytes.count;
//     return s;
// }

from_c_string ::(s: *u8) -> string {
    count: s64 = 0;
    q := s;
    while <<q {
        count += 1;
        q += 1;
    }

    str: string = ---;
    str.data = s;
    str.count = count;

    return str;
}

parse_float64 :: (line: *string) -> value:float64, success:bool {
    token, ok := parse_token(line);
    value: float64;
    if ok value, ok = string_to_float64(token);
    return value, ok;
}

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

// Windows
get_upload_file_name :: () -> string /* temp */, success: bool {
    buffer: [512] u16;

    ofn: OPENFILENAMEW;
    ofn.lStructSize = size_of(OPENFILENAMEW);
    ofn.hwndOwner   = window;
    ofn.lpstrFile   = buffer.data;
    ofn.nMaxFile    = buffer.count;
    ofn.lpstrTitle  = utf8_to_wide("Choose file to upload");
    ofn.Flags       = OFN_NOCHANGEDIR;

    open_success := GetOpenFileNameW(*ofn);

    if open_success {
        file_path, success := wide_to_utf8(buffer.data);
        path_overwrite_separators(file_path, #char "/");

        if success {
            return file_path, success;
        }
    }
    return "", false;
}

get_category_name :: (category_id: int) -> string{
    if category_id == -1 then return "All categories";
    for categories_list.categories if it.id == category_id { 
        return  it.name;
    }
    return "UNCATEGORISED";
}

update_filtered_transactions :: ()  {
    array_reset_keeping_memory(*transactions_filtered);
    for tr: transactions {
        // -1: All categories 
        if (transaction_filter.category_filter == -1 || tr.category_id == transaction_filter.category_filter) && 
            contains_nocase(tr.details, transaction_filter.transactions_search) then array_add(*transactions_filtered, tr);
    }
    
    if transaction_filter.transactions_search != "" then transactions_scroll_delta = 0;
    
    if transaction_filter.amount_sort != .none {
        quick_sort(transactions_filtered, tr => transaction_filter.amount_sort * tr.amount);
        transactions_scroll_delta = 0;
    } else if transaction_filter.date_sort != .none { 
        quick_sort(transactions_filtered,  compare_tr_dates);
        transactions_scroll_delta = 0;
    }
    
        
    compare_tr_dates :: (tr1: Transaction, tr2: Transaction) -> s64 {
        a := tr1.date; 
        b := tr2.date; 
        for 0..a.count-1 {
            if it >= b.count return 1;
            
            delta := cast(s64) a[it] - cast(s64) b[it];
            if delta return xx transaction_filter.date_sort * delta;
        }
    
        if b.count > a.count return -1 * xx transaction_filter.date_sort;
        return 0;
    }
}

update_transactions_on_dashboard :: (transactions_list: *Transactions_List) {
    array_reset_keeping_memory(*transactions_list.transactions);
    subtotal: float64;
    start_date, end_date: string;
    if transactions_list.type == {
        case .weekly;
            start_date = tprint("%/01/01", graph_details.year); 
            end_date = tprint("%/01/01", graph_details.year+1); 
        case .monthly;
            if transactions_list.chosen_period != -1 {
                year := cast(int) transactions_list.chosen_period / 12 + current_year - 2;
                month := cast(int) transactions_list.chosen_period % 12;
                start_date = tprint("%/%/01", year, formatInt(month, minimum_digits=2)); 
                if month == 12 then {year += 1; month = 0;};
                end_date = tprint("%/%/01", year, formatInt(month+1, minimum_digits=2)); 
            } else {
                start_date = tprint("%/01/01", current_year-2); 
                end_date = tprint("%/01/01", current_year); 
            }
    }
            
    for tr: transactions {
        if tr.amount <= 0 continue;
        show_on_graph, found := table_find(*show_categories_table, tr.category_id);
        if !show_on_graph && show_all_categories_on_graph != 1 continue;
        if compare_strings(tr.date, end_date) > 0 || compare_strings(start_date, tr.date) > 0 then continue;
        if (graph_details.category_id == -1 || tr.category_id == graph_details.category_id) { 
            subtotal += tr.amount; 
            array_add(*transactions_list.transactions, tr);
        }
    }
    transactions_list.update = false;
    transactions_list.subtotal = subtotal;
}

get_max_spending :: (spendings: *Period_Spendings) {
    max_total: float64;
    for i : 0 .. spendings.period_indices.count - 2 {
        start := spendings.period_indices[i];
        end   := spendings.period_indices[i + 1];
        num_spendings := end - start;
        spendings_array := array_view(spendings.spendings, start, num_spendings);
        total:float64 = 0;
        for spending : spendings_array {
            total += spending.total_spent;
        }
        if total > max_total then max_total = total;
    }
    spendings.max_spending = max_total;
}

update_filtered_rules :: ()  {
    using rules_list;
    array_reset_keeping_memory(*filtered_rules);
    for rule: rules {
        // -1: All categories 
        if (category_filter == -1 || rule.category_id == category_filter) {
            array_add(*filtered_rules, rule);
        }
    }
    
    // if transaction_filter.amount_sort != .none {
    //     quick_sort(transactions_filtered, tr => transaction_filter.amount_sort * tr.amount);
    //     transactions_scroll_delta = 0;
    // } else if transaction_filter.date_sort != .none { 
    //     quick_sort(transactions_filtered,  compare_tr_dates);
    //     transactions_scroll_delta = 0;
    // }
}

update_spendings_data :: (period_spendings: Period_Spendings, type: graph_type) -> Period_Spendings {
    s := period_spendings;
    using s;
    array_reset_keeping_memory(*spendings);
    array_reset_keeping_memory(*period_indices);
    ok: bool;
    if type == {
        case .weekly;
            s, ok = get_daily_spendings(to_calendar(current_time_consensus()).year - graph_details.year);
        case .monthly;
            s, ok = get_monthly_spendings_for_last_3_years();
    }
    if !ok return s;
    get_max_spending(*s);
    return s;
}


update_spendings_category :: (spendings: [..]Spending) {
    for *spending : spendings {
        for category: categories_list.categories {
            if category.id == spending.category_id {
                spending.color = category.color;
                spending.category = category.name;
                break;
            }
        }  
    } 
}

// date format yyyy/mm/dd
date_string_is_valid :: (date: string) -> bool {
    if date.count != 10 return false; 
    d := date;
    ok, year_str, month_and_day := split_from_left(d, #char "/");
    if !ok return false;
    ok2, month_str, day_str := split_from_left(month_and_day, #char "/");
    if !ok2 return false;

    year, day, month : int;
    year, ok = string_to_int(year_str);
    if year < 1000 || year > 2500 return false;
    month, ok = string_to_int(month_str);
    if month < 1 || month > 12 return false;
    day, ok = string_to_int(day_str);
    if day < 1 && day > 31 return false;
    if (month == 4 || month == 6 || month == 9 || month == 11) && day > 30 {
        return false;
    } else if month == 2 {
        if (year % 4 == 0 && (year % 100 == 0 || year % 400 == 0) && day > 29) || (day > 28) {
            return false;
        }
    } 
    return true;
}

today_to_string :: () -> string {
    cal := to_calendar(current_time_consensus());
    return tprint("%/%/%", 
        cal.year, 
        formatInt(cal.month_starting_at_0+1, minimum_digits=2), 
        formatInt(cal.day_of_month_starting_at_0+1, minimum_digits=2));
}

// Find a way to show week date
get_week_name :: (week_num: int, year: int, amount: float64) -> string {
    return tprint("%th week of year % - %", week_num+1, year, formatFloat(amount, trailing_width=2, zero_removal=.NO));
}

get_month_name :: (month_num: int, year: int, amount: float64) -> string {
    month_names :: string.["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];
    return tprint("% of year % - %", month_names[month_num], year, formatFloat(amount, trailing_width=2, zero_removal=.NO));
}

immediate_circle :: (center: Vector2, radius: float, color: Vector4, start: int, end: int) {
    STEP_ANGLE :: 2*PI/CIRCLE_RESOLUTION;
    for start..end {
        p0 := center;
        p1 := center + Vector2.{ x = cos(STEP_ANGLE*it), y = sin(STEP_ANGLE*it)} * radius;
        p2 := center + Vector2.{ x = cos(STEP_ANGLE*(it+1)), y = sin(STEP_ANGLE*(it+1))} * radius;
        Simp.immediate_triangle(make_vector3(p0,0), make_vector3(p1, 0), make_vector3(p2, 0), color, color, color);
    }
}


#import "Windows_Utf8";
#import "Windows";
