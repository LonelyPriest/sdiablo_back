%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright DaYuTongYong(C) 2015, buxianhui
%%% @Desc   : all sql of report
%%% Created : 23 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report_sql).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

sale(new_by_shop, Merchant, Conditions) ->
    {StartTime, EndTime, NewConditions} = 
	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select shop as shop_id"
	
	", sum(total) as t_amount"
	", sum(should_pay) as t_spay" 
	", sum(cash) as t_cash"
	", sum(card) as t_card"
	", sum(wxin) as t_wxin"
	%% ", sum(cbalance) as t_cbalance" 
	", sum(withdraw) as t_withdraw"
	
	" from w_sale"
	++ " where " ++ ?utils:to_sqls(proplists, NewConditions)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " group by shop";

sale(new_by_retailer, Merchant, Conditions) ->
    ?DEBUG("new_by_retailer with merchant ~p, conditions ~p",
	   [Merchant, Conditions]), 
    SortConditions = ?w_sale:sort_condition(wsale, Merchant, Conditions),
    
    %% {StartTime, EndTime, NewConditions} = 
    %% 	?sql_utils:cut(fields_no_prifix, Conditions), 
    "select a.shop as shop_id"
	
	", a.employ as employee_id"
	", a.retailer as retailer_id"

	", sum(a.should_pay) as t_spay" 
	", sum(a.cash) as t_cash"
	", sum(a.card) as t_card"
    %% ", sum(cbalance) as t_cbalance" 
	", sum(withdraw) as t_withdraw"
	
	" from w_sale a"
	++ " where " ++ SortConditions
	++ " and a.deleted=" ++ ?to_s(?NO)
	++ " group by a.retailer";

sale(new_by_good, Merchant, Conditions) ->
    ?DEBUG("new_by_good with merchant ~p, conditions ~p",
	   [Merchant, Conditions]),

    {DConditions, SConditions}
	= ?w_sale:filter_condition(wsale, Conditions, [], []),

    {_, _, CutDCondtions}
	= ?sql_utils:cut(fields_no_prifix, DConditions),
    {StartTime, EndTime, CutSConditions}
    	= ?sql_utils:cut(fields_no_prifix, SConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"a.">>, CutDCondtions),
    CorrectCutSConditions = ?utils:correct_condition(<<"b.">>, CutSConditions),

    "select a.id, a.rsn, a.style_number, a.brand as brand_id, d.name as brand"
	", sum(a.total) as t_sell"

	", b.shop as shop_id"
	", b.type as sell_type"
    %% ", c.amount as t_stock"
	
	%% " from w_sale_detail a, w_sale b, w_inventory c, brands d"
	" from w_sale_detail a, w_sale b, brands d"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "a.rsn=b.rsn"

	++ ?sql_utils:condition(proplists, CorrectCutSConditions)
    	++ " and b.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) 
    %% ++ " and a.style_number=c.style_number"
    %% ++ " and a.brand=c.brand"
    %% ++ " and b.merchant=c.merchant"
    %% ++ " and b.shop=c.shop"
	++ " and a.brand=d.id"
	++ " group by a.style_number, a.brand, b.merchant, b.shop".

daily(detail, Merchant, Conditions) ->
    ?DEBUG("daily_detail with merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    
    "select id, merchant, shop as shop_id"
	", sell, sell_cost as sellCost, balance, cash, card, wxin, draw, ticket, veri"
	", charge, stock, stockc, stock_cost as stockCost"
	
	", stock_in as stockIn, stock_in_cost as stockInCost"
	", stock_out as stockOut, stock_out_cost as stockOutCost"
	
	", t_stock_in as tstockIn, t_stock_in_cost as tstockInCost"
	", t_stock_out as tstockOut, t_stock_out_cost as tstockOutCost"
	
	", stock_fix as stockFix, stock_fix_cost as stockFixCost"

	", day, entry_date"

	" from w_daily_report"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ day_condition(StartTime, EndTime).
	%% ++ case ?sql_utils:condition(time_no_prfix, StartTime, EndTime) of
	%%        [] -> [];
	%%        TimeSql ->
	%% 	   " and " ++ TimeSql
	%%    end.

shift(detail, Merchant, Conditions) ->
    ?DEBUG("shift_detail with merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, Conditions),

    "select a.id"
	", a.merchant"
	", a.employ as employee_id"
	", a.shop as shop_id"
	", a.account as account_id"
	", a.total as sell"
	", a.balance"
	", a.cash"
	", a.card"
	", a.wxin"
	
	", a.y_stock"
	", a.stock"

	", a.stock_in as stockIn"
	", a.stock_out as stockOut"

	", a.pcash"
	", a.pcash_in as pcashIn"

	", a.comment"
	", a.entry_date"

	", b.name as account"

	" from w_change_shift a"
	" left join users b on a.account=b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) 
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql ->
		   " and " ++ TimeSql
	   end.

sale(new_by_shop_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_shop, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);

sale(new_by_retailer_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_retailer, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage);

sale(new_by_good_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    sale(new_by_good, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).

daily(daily_with_pagination,
     Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    daily(detail, Merchant, Conditions)
	++ " order by day desc"
	++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
    	++ ", " ++ ?to_s(ItemsPerPage).
	%% ++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).


shift(shift_with_pagination,
      Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    shift(detail, Merchant, Conditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage).

day_condition(StartDatetime, EndDatetime) ->
    <<StartDay:10/binary, _/binary>> = ?to_b(StartDatetime),
    <<EndDay:10/binary, _/binary>> = ?to_b(EndDatetime),
    ?sql_utils:time_condition(StartDay, day, ge)
	++ " and " ++ ?sql_utils:time_condition(EndDay, day, less).
