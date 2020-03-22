-module(diablo_sql_utils).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).


cut(non_prefix, Fields) ->
    cut(fields_no_prifix, Fields);
cut(fields_no_prifix, Fields) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),

    CutFields = proplists:delete(
		  <<"end_time">>,
		  proplists:delete(<<"start_time">>, Fields)), 
    {StartTime, EndTime, CutFields};

cut(prefix, Fields)->
    cut(fields_with_prifix, Fields);
cut(fields_with_prifix, Fields) ->
    StartTime = ?value(<<"start_time">>, Fields),
    EndTime   = ?value(<<"end_time">>, Fields),

    CutFields = proplists:delete(
		  <<"end_time">>,
		  proplists:delete(<<"start_time">>, Fields)),

    NewFields = ?utils:correct_condition(<<"a.">>, CutFields),
    {StartTime, EndTime, NewFields}.


fix_condition(time, Fix, Start, End) ->
    case condition(Fix, Start, End) of
	[] -> []; 
	TimeSql -> " and " ++ TimeSql
    end.

condition(time_no_prfix, undefined, undefined) ->
    [];
condition(time_no_prfix, Start, undefined) ->
    time_condition(Start, "entry_date", more);
condition(time_no_prfix, undefined, End) ->
    time_condition(End, "entry_date", less);
condition(time_no_prfix, Start, End) ->
    time_condition(Start, "entry_date", more)
	++ " and " ++ time_condition(End, "entry_date", less);

condition(time_with_prfix, undefined, undefined) ->
    [];
condition(time_with_prfix, Start, undefined) ->
    time_condition(Start, "a.entry_date", more);
condition(time_with_prfix, undefined, End) ->
    time_condition(End, "a.entry_date", less);
condition(time_with_prfix, Start, End) ->
    time_condition(Start, "a.entry_date", more)
	++ " and " ++ time_condition(End, "a.entry_date", less);

condition(page_desc, CurrentPage, ItemsPerPage) ->
    " order by id desc"
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
	++ ", " ++ ?to_s(ItemsPerPage).

condition(page_desc, {use_id, _Sort}, CurrentPage, ItemsPerPage) ->
    condition(page_desc, CurrentPage, ItemsPerPage);
condition(page_desc, {use_id, _Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "id desc"
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_sell, Sort}, CurrentPage, ItemsPerPage) ->
    " order by sell " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_sell, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "sell " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);


condition(page_desc, {use_discount, Sort}, CurrentPage, ItemsPerPage) ->
    " order by discount " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_discount, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "discount " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);


condition(page_desc, {use_year, Sort}, CurrentPage, ItemsPerPage) ->
    " order by year " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_year, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "year " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_season, Sort}, CurrentPage, ItemsPerPage) ->
    " order by season " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_season, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "season " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_amount, Sort}, CurrentPage, ItemsPerPage) ->
    " order by amount " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_amount, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "amount " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_style_number, Sort}, CurrentPage, ItemsPerPage) ->
    " order by style_number " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_style_number, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "style_number " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_brand, Sort}, CurrentPage, ItemsPerPage) ->
    " order by brand " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage);
condition(page_desc, {use_brand, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "brand " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_type, Sort}, CurrentPage, ItemsPerPage) ->
    condition(page_desc, {use_type, Sort, "a."}, CurrentPage, ItemsPerPage);    
condition(page_desc, {use_type, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "type " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_firm, Sort}, CurrentPage, ItemsPerPage) ->
    condition(page_desc, {use_firm, Sort, "a."}, CurrentPage, ItemsPerPage);
condition(page_desc, {use_firm, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "firm " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_datetime, Sort}, CurrentPage, ItemsPerPage) ->
    condition(page_desc, {use_datetime, Sort, "a."}, CurrentPage, ItemsPerPage);
condition(page_desc, {use_datetime, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "entry_date " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

condition(page_desc, {use_tag_price, Sort}, CurrentPage, ItemsPerPage) ->
    condition(page_desc, {use_tag_price, Sort, "a."}, CurrentPage, ItemsPerPage);
condition(page_desc, {use_tag_price, Sort, Prefix}, CurrentPage, ItemsPerPage) ->
    " order by " ++ ?to_s(Prefix) ++ "tag_price " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);

%% retailer use
condition(page_desc, {use_balance, Sort}, CurrentPage, ItemsPerPage) ->
    " order by a.balance " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_consume, Sort}, CurrentPage, ItemsPerPage) ->
    " order by a.consume " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage);
condition(page_desc, {use_level, Sort}, CurrentPage, ItemsPerPage) ->
    " order by a.level " ++ ?MODULE:sort(Sort)
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage).

like_condition(style_number, MatchMode, Conditions, LikeKey) ->
    like_condition(style_number, MatchMode, Conditions, LikeKey, LikeKey).
like_condition(style_number, MatchMode, Conditions, LikeKey, KeyInConditions) ->
    case MatchMode of
	?AND ->
	    ?sql_utils:condition(proplists, Conditions);
	?LIKE ->
	    %% case ?v(<<"b.style_number">>, Conditions, []) of
	    %% 	[] ->
	    %% 	    ?sql_utils:condition(proplists, Conditions);
	    %% 	Like ->
	    %% 	    " and " ++ ?to_s(LikeKey) ++ " like '" ++ ?to_s(Like) ++ "%'"
	    %% 		++ ?sql_utils:condition(
	    %% 		      proplists, lists:keydelete(LikeKey, 1, Conditions))
	    %% end
	    case ?v(KeyInConditions, Conditions, []) of
		[] ->
		    ?sql_utils:condition(proplists, Conditions);
		Like ->
		    " and " ++ ?to_s(LikeKey) ++ " like '" ++ ?to_s(Like) ++ "%'"
			++ ?sql_utils:condition(
			      proplists, lists:keydelete(KeyInConditions, 1, Conditions))
	    end
    end.

mode(Mode, Sort) ->
    " order by " ++ mode(Mode) ++ " " ++ sort(Sort).
mode(use_id) -> "id";
mode(use_sell) -> "sell";
mode(use_amount) -> "amount";
mode(use_date) ->   "entry_date";
mode(use_tag_price) -> "tag_price";
mode(use_balance) -> "balance";
mode(use_consume) -> "consume";
mode(use_level) -> "level".


sort(0) -> "desc";
sort(1) -> "asc".
    
condition(proplists, []) ->
    [];
condition(proplists, Conditions) -> 
    case ?utils:to_sqls(proplists, Conditions) of
	[] -> [];
	Sql -> " and " ++ Sql
    end;

condition(proplists_suffix, []) ->
    [];
condition(proplists_suffix, Conditions) ->
    case ?utils:to_sqls(proplists, Conditions) of
	[] -> [];
	SQL -> SQL ++ " and "
    end.
				 
time_condition(non_prefix, ge2less, Start, End) ->
    time_condition(Start, "entry_date", ge)
	++ " and " ++ time_condition(End, "entry_date", less);
time_condition(prefix, ge2less, Start, End) ->
    time_condition(Start, "a.entry_date", ge)
	++ " and " ++ time_condition(End, "a.entry_date", less).

time_condition(Time, TimeField, ge) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ ">=\"" ++ ?to_s(Time) ++ "\""
    end;
time_condition(Time, TimeField, le) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ "<=\"" ++ ?to_s(Time) ++ "\""
    end;

time_condition(Time, TimeField, more) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ ">\"" ++ ?to_s(Time) ++ "\""
    end;

time_condition(Time, TimeField, less) ->
    case Time of
	undefined -> [];
	Time ->
	    ?to_s(TimeField) ++ "<\"" ++ ?to_s(Time) ++ "\""
    end.

count_table(Table, Merchant, Conditions) ->
    count_table(Table, "count(*) as total", Merchant, Conditions).
count_table(Table, CountSql, Merchant, Conditions) -> 
    {StartTime, EndTime, NewConditions} = cut(fields_no_prifix, Conditions),
    
    Sql = "select " ++ CountSql ++ " from " ++ ?to_s(Table)
	++ " where " ++ condition(proplists_suffix, NewConditions) 
	++ " merchant="++ ?to_s(Merchant) 
	++ case condition(time_no_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end,
    Sql.

%%%================================================================================
%%%sql execute
%%%================================================================================
execute(write, Sql, OkReturn) ->
    case ?mysql:fetch(write, Sql) of
	{ok, _} ->
	    {ok, OkReturn};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(transaction, Sqls, OkReturn) ->
    case ?mysql:fetch(transaction, Sqls) of
	{ok, _} ->
	    {ok, OkReturn};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, Error} ->
	    {error, ?err(db_error, Error)} 
    end.
    
execute(read, Sql) ->
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    {ok, []};
	{ok, Results} ->
	    {ok, ?to_tl(Results)};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(s_read, Sql) -> 
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    {ok, []};
	{ok, {Results}} ->
	    %% ?DEBUG("s_read sql result ~p", [Results]),
	    {ok, Results};
	{error, timeout} ->
	    {error, ?err(db_timeout, timeout)};
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end;

execute(insert, Sql) ->
    case ?mysql:fetch(insert, Sql) of
	{ok, InsertId} ->
	    {ok, InsertId};
	{error, timeout} ->
	    {error, ?err(db_error, timeout)}; 
	{error, {_, Error}} ->
	    {error, ?err(db_error, Error)}
    end.
	    
