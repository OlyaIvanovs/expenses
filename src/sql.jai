get_daily_spendings :: () -> Daily_Spendings, bool {
    spending_query :: #string END
        SELECT category_id, SUM(amount)
        FROM Transactions
        WHERE
            amount >= 0 AND
            transaction_date >= strftime('%%Y/%%m/%%d', date('now','start of year', 'weekday 1', '+%1 days')) AND
            transaction_date <  strftime('%%Y/%%m/%%d', date('now','start of year', 'weekday 1', '+%1 days', '+7 days'))
        GROUP BY category_id;
    END
    errmsg: *u8;
    using daily_spendings: Daily_Spendings;

    for week_index : 0 .. 51 {
        array_add(*week_indices, spendings.count);
        week_query := to_c_string(tprint(spending_query, week_index * 7));
        defer free(week_query);
        result := sqlite3_exec(db, week_query, collect_spendings_from_db, *daily_spendings, *errmsg);
        if result != SQLITE_OK {
            log_error("ERROR querying spendings for week %: %\n", week_index, from_c_string(errmsg));
            return daily_spendings, false;
        }
    }
    array_add(*week_indices, spendings.count);
    return daily_spendings, true;
}


delete_category_from_db :: (id: int) -> bool{
    sql_str :: "DELETE FROM Categories WHERE id = %;";
    return execute_simple_db_query(tprint(sql_str, id));
}

delete_transaction_from_db :: (id: int) -> bool{
    print("delete id %", id);
    sql_str :: "DELETE FROM Transactions WHERE id = %;";
    return execute_simple_db_query(tprint(sql_str, id));
}

add_category_to_db :: (id: int, name: string) -> bool {
    sql_str :: "INSERT OR REPLACE INTO Categories(id, name) VALUES(%, '%');";
    return execute_simple_db_query(tprint(sql_str, id, name));
}

execute_simple_db_query :: (select: string) -> bool{
    query := to_c_string(select);
    defer free(query);
    errmsg : *u8;
    result := sqlite3_exec(db, query, null, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    return true;
}


#scope_file

collect_spendings_from_db ::(userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 2);
        ok: bool;

        daily_spendings := cast(*Daily_Spendings) userdata;

        spending := array_add(*daily_spendings.spendings);
        spending.category_id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        spending.total_spent, ok = parse_float64(*from_c_string(col_data[1]));
        if !ok then log_error("Couldn't parse amount from string");
    }
    return SQLITE_OK;
}


#scope_export

Daily_Spendings :: struct {
    spendings: [..] Spending;
    week_indices: [..] s64;
}
