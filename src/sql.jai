initialise_db :: () -> bool {
    load_file_at_comptime :: (filename: string) -> string {
        contents, success := read_entire_file(filename);
        assert(success);
        return contents;
    }
    
    init_sql :: #run load_file_at_comptime("init_db.sql");
    errmsg : *u8;
    result := sqlite3_exec(db, init_sql, null, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    assert(result == SQLITE_OK);
    return true;
}


get_daily_spendings :: (year: int) -> Period_Spendings, bool {
    spending_query :: #string END
        SELECT category_id, SUM(amount)
        FROM Transactions
        WHERE
            amount >= 0 AND
            transaction_date >= strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year', 'weekday 1', '+%1 days')) AND
            transaction_date <  strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year' ,'weekday 1', '+%1 days', '+7 days'))
        GROUP BY category_id;
    END
    errmsg: *u8;
    using daily_spendings: Period_Spendings;

    for week_index : 0 .. 51 {
        array_add(*period_indices, spendings.count);
        week_query := to_c_string(tprint(spending_query, week_index * 7, tprint("%",year)));
        defer free(week_query);
        result := sqlite3_exec(db, week_query, collect_spendings_from_db, *daily_spendings, *errmsg);
        if result != SQLITE_OK {
            log_error("ERROR querying spendings for week %: %\n", week_index, from_c_string(errmsg));
            return daily_spendings, false;
        }
    }
    array_add(*period_indices, spendings.count);
    return daily_spendings, true;
}

get_monthly_spendings_for_last_3_years:: () -> Period_Spendings, bool {
    spending_query :: #string END
        SELECT category_id, SUM(amount)
        FROM Transactions
        WHERE
            amount >= 0 AND
            transaction_date >= strftime('%%Y/%%m/%%d', date('now', '%1 years', 'start of year', '+%2 months')) AND
            transaction_date <  strftime('%%Y/%%m/%%d', date('now', '%1 years', 'start of year', '+%3 months'))
        GROUP BY category_id;
    END
    errmsg: *u8;
    using period_spendings: Period_Spendings;
    
    for year: -2..0 {
        for month_index : 0 .. 10 {
            array_add(*period_indices, spendings.count);
            month_query := to_c_string(tprint(spending_query, year, month_index, month_index + 1));
            defer free(month_query);
            result := sqlite3_exec(db, month_query, collect_spendings_from_db, *period_spendings, *errmsg);
            if result != SQLITE_OK {
                log_error("ERROR querying spendings for month %: %\n", month_index, from_c_string(errmsg));
                return period_spendings, false;
            }
        }
        array_add(*period_indices, spendings.count);
    }  
    return period_spendings, true;
}

get_all_categories_from_db :: () -> bool {
    errmsg : *u8;
    query :: "SELECT * FROM Categories;";
    result := sqlite3_exec(db, query, load_category_from_db, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    return true;
}

get_all_rules_from_db :: () -> bool {
    errmsg : *u8;
    query :: "SELECT * FROM Rules;";
    result := sqlite3_exec(db, query,load_rule_from_db, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    return true;
}

get_all_transactions_from_db :: () -> bool {
    query_str :: "SELECT * FROM Transactions;";
    return get_transactions_from_db(to_c_string(query_str), *transactions);
}

get_filtered_transactions_from_db :: (category_id: int, year: int, days: int) -> bool {
    query_str := #string END
        SELECT *
        FROM Transactions
        WHERE
            amount > 0 AND
            category_id == '%1' AND
            transaction_date >= strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year', 'weekday 1', '+%3 days')) AND
            transaction_date <  strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year', 'weekday 1', '+%3 days', '+7 days'))
    END;
    if category_id == -1 {
        query_str =  #string END
        SELECT *
        FROM Transactions
        WHERE
            amount > 0 AND
            transaction_date >= strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year', 'weekday 1', '+%3 days')) AND
            transaction_date <  strftime('%%Y/%%m/%%d', date('now', '-%2 years', 'start of year', 'weekday 1', '+%3 days', '+7 days'))
        END;
    }
    query := to_c_string(tprint(query_str, tprint("%", category_id), year, days));
    return get_transactions_from_db(query, *weekly_dashboard_transactions.transactions);
}


get_transactions_from_db :: (query: *u8, userdata: *void) -> bool {
    errmsg : *u8;
    result := sqlite3_exec(db, query, load_transaction_from_db, userdata, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    return true;
}

delete_category_from_db :: (id: int) -> bool{
    query :: "DELETE FROM Categories WHERE id = %;";
    return execute_simple_db_query(tprint(query, id));
}

delete_transaction_from_db :: (id: int) -> bool{
    query :: "DELETE FROM Transactions WHERE id = %;";
    return execute_simple_db_query(tprint(query, id));
}

delete_rule_from_db :: (id: int) -> bool{
    query :: "DELETE FROM Rules WHERE id = %;";
    return execute_simple_db_query(tprint(query, id));
}

delete_all_transaction_from_db :: () -> bool{
    query :: "DELETE FROM Transactions;";
    return execute_simple_db_query(query);
}

add_category_to_db :: (id: int, name: string, color: string) -> bool {
    query :: "INSERT OR REPLACE INTO Categories(id, name, color) VALUES(%, '%', '%');";
    return execute_simple_db_query(tprint(query, id, name, color));
}

add_category_to_db :: (name: string, color: string) -> int, bool {
    query :: "INSERT OR REPLACE INTO Categories(name, color) VALUES('%', '%');";
    ok := execute_simple_db_query(tprint(query, name, color));
    if !ok return 0, false;
    id : int;
    id, ok = get_last_id();
    if !ok return 0, false;
    return id, ok;
}

get_last_id :: () -> (int, bool) {
    query := to_c_string("SELECT last_insert_rowid();");
    defer free(query);
    errmsg : *u8;
    last_id: int;
    result := sqlite3_exec(db, query, get_last_id_from_db, *last_id, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return 0, false;
    }
    return last_id, true;
}

get_last_id_from_db :: (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 1);
        last_id := cast(*int) userdata;
        id, ok := parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        <<last_id = id;
    }
    return SQLITE_OK;
}


add_rule_to_db :: (id: int, name: string, category_id: int) -> bool {
    query :: "INSERT OR REPLACE INTO Rules(id, name, category_id) VALUES(%, '%', %);";
    return execute_simple_db_query(tprint(query, id, name, category_id));
}

add_rule_to_db :: ( name: string, category_id: int) -> bool {
    query :: "INSERT OR REPLACE INTO Rules(name, category_id) VALUES('%', %);";
    return execute_simple_db_query(tprint(query, name, category_id));
}

add_transaction_to_db :: (id: int, date: string, amount: float64, details: string, note: string, category_id: int) -> bool {
    query :: "INSERT OR REPLACE INTO Transactions(id, transaction_date, amount, details, note, category_id) VALUES(%, '%', %, '%', '%', %);";
    return execute_simple_db_query(tprint(query, id, date, amount, details, note, category_id));
}

add_transaction_to_db :: (date: string, amount: float64, details: string, note: string, category_id: int) -> int, bool {
    query :: "INSERT OR REPLACE INTO Transactions(transaction_date, amount, details, note, category_id) VALUES('%', %, '%', '%', %);";
    ok := execute_simple_db_query(tprint(query, date, amount, details, note, category_id));
    if !ok return 0, false;
    id : int;
    id, ok = get_last_id();
    if !ok return 0, false;
    return id, ok;
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

load_transaction_from_db :: (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 6);
        ok: bool;
        
        transactions := cast(*[..]Transaction) userdata;

        transaction := array_add(transactions);
        transaction.id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        if col_data[1] != null then transaction.date = copy_temporary_string(from_c_string(col_data[1]));
        transaction.amount, ok = parse_float(*from_c_string(col_data[2]));
        if !ok then log_error("Couldn't parse amount from string");
        transaction.details = copy_temporary_string(from_c_string(col_data[3]));
        if col_data[4] != "" {
            transaction.note = copy_temporary_string(from_c_string(col_data[4]));
        }
        if col_data[5] != null transaction.category_id, ok = parse_int(*from_c_string(col_data[5]));
        if !ok then log_error("Couldn't parse category_id from string");
    }
    return SQLITE_OK;
}

load_category_from_db :: (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 3);
        ok: bool;
        category := array_add(*categories_list.categories);
        category.id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        category.name = copy_temporary_string(from_c_string(col_data[1]));
        category.color = copy_temporary_string(from_c_string(col_data[2]));
    }
    return SQLITE_OK;
}

load_rule_from_db :: (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 3);
        ok: bool;
        rule := array_add(*rules_list.rules);
        rule.id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        rule.name = copy_temporary_string(from_c_string(col_data[1]));
        rule.category_id, ok = parse_int(*from_c_string(col_data[2]));
        if !ok then log_error("Couldn't parse id from string");
    }
    return SQLITE_OK;
}

upload_transactions_from_file :: (file_name: string) -> bool {
    contents, success := read_entire_file(file_name);
    assert(success);

    csv_file := read_csv(file_name, ",", 6, num_cols = 7);
    ok: bool;
    for row : csv_file.rows {
        t := array_add(*transactions_raw);
        t.date = row.fields[1];
        t.amount, ok = parse_float64(*row.fields[6]);
        if !ok then log_error("Couldn't parse amount as float: %\n", row.fields[6]);
        t.details = row.fields[5]; 
        for rule: rules_list.rules {
            if contains_nocase(t.details, rule.name) then t.category_id = rule.category_id; 
        } 
    }

    query_builder: String_Builder;
    init_string_builder(*query_builder);
    print_to_builder(*query_builder, "BEGIN TRANSACTION;\n");
    for t : transactions_raw {
        if t.amount < 0 then continue; // do not include income
        insert :: #string QUERY
    INSERT INTO Transactions (transaction_date, amount, details, category_id) VALUES ("%", %, %, %);
    QUERY;
        print_to_builder(*query_builder, insert, t.date, t.amount, t.details, t.category_id);
    }
    print_to_builder(*query_builder, "COMMIT;\n");

    query := builder_to_string(*query_builder);
    defer free(query);
    
    errmsg : *u8;
    result := sqlite3_exec(db, to_c_string(query), null, null, *errmsg);
    if result != SQLITE_OK {
        log_error("ERROR: %\n",from_c_string(errmsg));
        return false;
    }
    
    return true;
}


#scope_file

collect_spendings_from_db :: (userdata: *void, num_cols: int, col_data: **u8, col_names: **u8) -> int #c_call {
    new_context: Context;
    push_context new_context {
        assert(num_cols == 2);
        ok: bool;

        s := cast(*Period_Spendings) userdata;
        spending := array_add(*s.spendings);
        
        spending.category_id, ok = parse_int(*from_c_string(col_data[0]));
        if !ok then log_error("Couldn't parse id from string");
        spending.total_spent, ok = parse_float64(*from_c_string(col_data[1]));
        if !ok then log_error("Couldn't parse amount from string");
        for category: categories_list.categories {
            if category.id == spending.category_id {
                spending.color = category.color;
                spending.category = category.name;
                break;
            }
        }
        if spending.color == "" then spending.color = "110000";
    }
    return SQLITE_OK;
}

