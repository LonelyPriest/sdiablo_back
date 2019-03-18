%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @desc: wreport request
%%% Created : 22 Jul 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_report_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([sell/2, stock/2, get_setting/2, get_config/2]).

-define(d, ?utils:seperator(csv)).

action(Session, Req) ->
    ?DEBUG("req ~p", [Req]),
    {ok, HTMLOutput} = wreport_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "wreportApp"},
			  %% {ngcontroller, "wreportCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_shop"}) ->
    ?DEBUG("list_shop with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:lookup(Merchant) end, Req);
%% {ok, M} = ?shop:lookup(?session:get(merchant, Session)),
%% ?utils:respond(200, batch, Req, M);

action(Session, Req, {"list_repo"}) ->
    ?DEBUG("list_repo with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:repo(list, Merchant) end, Req); 

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%-------------------------------------------------------------------- 
action(Session, Req, {"delete_shop", Id}) ->
    ?DEBUG("delete_shop with session ~p, id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:shop(delete, Merchant, Id) end,
		   fun(ShopId)-> ?succ(delete_shop, ShopId) end,
		   Req).

%% case ?shop:shop(delete, Merchant, ?to_i(Id)) of
%% 	{ok, ShopId} ->
%% 	    ?utils:respond(200, Req, ?succ(delete_shop, ShopId));
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%% end. 

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"daily_wreport", Type}, Payload) ->
    ?DEBUG("daily_wrport with session ~p, type ~p, paylaod~n~p", [Session, Type, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    case ?to_a(Type) of
	by_shop ->
	    try
		{struct, Conditions} = ?v(<<"condition">>, Payload), 
		ShopIds = ?v(<<"shop">>, Conditions),
		CurrentDate = ?v(<<"start_time">>, Conditions),
		{ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),

		{ok, StockSale} = ?w_report:stastic(stock_sale, Merchant, Conditions),
		{ok, StockProfit} = ?w_report:stastic(stock_profit, Merchant, Conditions),
		
		{ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, Conditions),
		{ok, StockOut} = ?w_report:stastic(stock_out, Merchant, Conditions),
		
		{ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, Conditions),
		{ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, Conditions),

		{ok, StockR} =
		    case ?to_s(CurrentDate) =:= ?utils:current_time(localdate) of
			true ->
			    ?w_report:stastic(
			       stock_real,
			       Merchant,
			       lists:keydelete(<<"start_time">>, 1,
					       lists:keydelete(<<"end_time">>, 1, Conditions))
			       ++ [{<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}]);
			false ->
			    case ?w_report:stastic(
				    current_stock_of_shop, Merchant, ShopIds, CurrentDate) of
				{ok, []} ->
				    ?w_report:stastic(
				       stock_real,
				       Merchant,
				       lists:keydelete(
					 <<"start_time">>, 1,
					 lists:keydelete(<<"end_time">>, 1, Conditions))
				       ++ [{<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}]);
				{ok, HistoryStock} ->
				    {ok, HistoryStock}
			    end
		    end,
		
		{ok, LastStockInfo} = ?w_report:stastic(
					 last_stock_of_shop, Merchant, ShopIds, CurrentDate),
		{ok, Recharges} = ?w_report:stastic(recharge, Merchant, Conditions),

		?utils:respond(200, object, Req,
			       {[{<<"ecode">>, 0},
				 {<<"sale">>, StockSale},
				 {<<"profit">>, StockProfit},
				 {<<"rstock">>, StockR},
				 {<<"lstock">>, LastStockInfo},
				 {<<"recharge">>, Recharges},
				 {<<"pin">>, StockIn},
				 {<<"pout">>, StockOut},
				 {<<"tin">>, StockTransferIn},
				 {<<"tout">>, StockTransferOut}
				]})
	    catch
		_:{badmatch, {error, Error}} -> ?utils:respond(200, Req, Error)
	    end;
	_ -> 
	    ?pagination:pagination(
	       fun(_Match, Conditions) ->
		       ?w_report:report(total, ?to_a(Type), Merchant, Conditions)
	       end,

	       fun(_Match, CurrentPage, ItemsPerPage, Conditions) ->
		       ?w_report:report(
			  ?to_a(Type), Merchant, CurrentPage, ItemsPerPage, Conditions)
	       end, Req, Payload)
    end;

action(Session, Req, {"h_daily_wreport"}, Payload) ->
    ?DEBUG("h_daily_wrport with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    
    ?pagination:pagination(
       fun(_Match, Conditions) ->
	       ?w_report:daily_report(total, Merchant, Conditions)
       end,

       fun(_Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_report:daily_report(
		  detail, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"syn_daily_report"}, Payload) ->
    ?DEBUG ("syn_daily_report with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 
    case ?gen_report:syn_report(stastic_per_shop, Merchant, Payload) of
	{ok, Merchant} ->
	    ?utils:respond(200, Req, ?succ(syn_daily_report, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"h_month_wreport"}, Payload) ->
    ?DEBUG("h_month_wrport with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    {struct, Conditions} = ?v(<<"condition">>, Payload),

    case ?w_report:month_report(by_shop, Merchant, lists:keydelete(<<"region">>, 1, Conditions)) of
	{ok, Details} ->
	    ShopIds = ?v(<<"shop">>, Conditions), 
	    {_, EndTime, _} = ?sql_utils:cut(fields_no_prifix, Conditions),
	    Yestoday = yestoday(EndTime),
	    %% <<Y:4/binary, "-", M:2/binary, "-", D:2/binary, _/binary>> = EndTime,
	    %% Seconds = calendar:datetime_to_gregorian_seconds(
	    %% 		{{?to_i(Y), ?to_i(M), ?to_i(D)}, {0, 0, 0}}) - ?ONE_DAY,
	    %% {{Year, Month, Day}, _} = calendar:gregorian_seconds_to_datetime(Seconds),
	    %% FDay = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])),
	    
	    case ?w_report:stock(of_day, Merchant, ShopIds, Yestoday) of
		{ok, Stock} ->
		    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
						       {<<"data">>, Details},
						       {<<"stock">>, Stock}]});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"export_month_report"}, Payload) ->
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ShopIds     = ?to_l(?v(<<"shop">>, Payload)),
		      
    {_, EndTime, _} = ?sql_utils:cut(fields_no_prifix, Payload),
    Yestoday = yestoday(EndTime),

    {ok, AllShops} = ?w_user_profile:get(shop, Merchant),

    ValidShops = case [Shop || Shop <- AllShops,
			       lists:member(?v(<<"id">>, Shop), ShopIds)] of
		     [] -> AllShops;
		     VShops -> VShops
		 end, 
    %% ?DEBUG("valid shops ~p", [ValidShops]),
    
    try
	{ok, Details} = ?w_report:month_report(by_shop, Merchant, Payload),
	%% ?DEBUG("details ~p", [Details]),
	{ok, Stocks} = ?w_report:stock(of_day, Merchant, ShopIds, Yestoday),
	%% ?DEBUG("Stocks ~p", [Stocks]),

	MonthReports = 
	    lists:foldr(
	      fun({Shop}, Acc) ->
		      D = case lists:filter(
				 fun({Detail}) ->
					 ?v(<<"shop_id">>, Detail) =:= ?v(<<"id">>, Shop)
				 end, Details) of
			      []    -> [];
			      [{V}] -> V
			  end, 
		      %% ?DEBUG("D ~p", [D]),

		      S = case lists:filter(
				fun({Stock}) ->
					?v(<<"shop_id">>, Stock) =:= ?v(<<"id">>, Shop)
				end, Stocks) of
			     [] -> [];
			     [{V2}] -> V2
			 end, 
		      %% ?DEBUG("S ~p", [S]),
		      
		      [
		       {[{<<"shop">>, ?v(<<"name">>, Shop)},
			 {<<"stockc">>, ?v(<<"stockc">>, S, 0)},
			 {<<"stockCost">>, ?v(<<"stock_cost">>, S, 0)},

			 {<<"sell">>, ?v(<<"sell">>, D, 0)},
			 {<<"sellCost">>, ?v(<<"sell_cost">>, D, 0)},
			 {<<"balance">>, ?v(<<"balance">>, D, 0)},
			 {<<"cash">>, ?v(<<"cash">>, D, 0)},
			 {<<"card">>, ?v(<<"card">>, D, 0)},
			 {<<"wxin">>, ?v(<<"wxin">>, D, 0)},
			 {<<"veri">>, ?v(<<"veri">>, D, 0)},
			 {<<"draw">>, ?v(<<"draw">>, D, 0)},
			 {<<"ticket">>, ?v(<<"ticket">>, D, 0)},

			 {<<"charge">>, ?v(<<"charge">>, D, 0)},

			 {<<"stockIn">>, ?v(<<"stock_in">>, D, 0)},
			 {<<"stockOut">>, ?v(<<"stock_out">>, D, 0)},
			 {<<"stockInCost">>, ?v(<<"stock_in_cost">>, D, 0)},
			 {<<"stockOutCost">>, ?v(<<"stock_out_cost">>, D, 0)},

			 {<<"tstockIn">>, ?v(<<"tstock_in">>, D, 0)},
			 {<<"tstockOut">>, ?v(<<"tstock_out">>, D, 0)},
			 {<<"tstockInCost">>, ?v(<<"tstock_in_cost">>, D, 0)},
			 {<<"tstockOutCost">>, ?v(<<"tstock_out_cost">>, D, 0)},

			 {<<"stockFix">>, ?v(<<"stock_fix">>, D, 0)},
			 {<<"stockFixCost">>, ?v(<<"stock_fix_cost">>, D, 0)}]}
		       |Acc] 
	      end, [], ValidShops),

	%% ?DEBUG("reports ~p", [MonthReports]),
	
	{ok, ExportFile, Url} = ?utils:create_export_file("mreport", Merchant, UserId),
	Calcs = erlang:list_to_tuple(lists:duplicate(22, 0)),
	case file:open(ExportFile, [append, raw]) of
	    {ok, Fd} -> 
		try
		    DoFun = fun(C) -> ?utils:write(Fd, C) end,
		    csv_head(month_report, DoFun), 
		    do_write(month_report, DoFun, 1, MonthReports, Calcs),
		    ok = file:datasync(Fd),
		    ok = file:close(Fd)
		catch
		    T:W -> 
			file:close(Fd),
			?DEBUG("trace export:T ~p, W ~p~n~p", [T, W, erlang:get_stacktrace()]),
			?utils:respond(200, Req, ?err(wsale_export_error, W)) 
		end,
		?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"url">>, ?to_b(Url)}]}); 
	    {error, Error} ->
		?utils:respond(200, Req, ?err(wsale_export_error, Error))
	end
    catch
	_:{badmatch, ErrorExport} ->
	    ?utils:respond(200, Req, ErrorExport)
    end;

action(Session, Req, {"switch_shift_report"}, Payload) ->
    ?DEBUG("switch_shift_report with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 

    ?pagination:pagination(
       fun(_Match, Conditions) ->
	       ?w_report:switch_shift_report(total, Merchant, Conditions)
       end,

       fun(_Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_report:switch_shift_report(
		  detail, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"stock_stastic"}, Payload) ->
    ?DEBUG("stock_stastic with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    %% ?DEBUG("baseSetting ~p", [BaseSetting]),
    NewPayload = [{<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}]
	++ lists:keydelete(<<"start_time">>, 1, Payload),
    try 
	{ok, StockSale} = ?w_report:stastic(stock_sale, Merchant, NewPayload),
	%% ?DEBUG("stock sale ~p", [StockSale]),
	{ok, StockProfit} = ?w_report:stastic(stock_profit, Merchant, NewPayload),
	{ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, NewPayload),
	{ok, StockOut} = ?w_report:stastic(stock_out, Merchant, NewPayload),
	{ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, NewPayload),
	{ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, NewPayload),
	{ok, StockFix} = ?w_report:stastic(stock_fix, Merchant, NewPayload),
	{ok, StockR} = ?w_report:stastic(stock_real, Merchant, NewPayload),
	
	?utils:respond(200, object, Req,
		       {[{<<"ecode">>, 0},
			 {<<"sale">>, StockSale},
			 {<<"profit">>, StockProfit},
			 {<<"pin">>, StockIn},
			 {<<"pout">>, StockOut},
			 {<<"tin">>, StockTransferIn},
			 {<<"tout">>, StockTransferOut},
			 {<<"fix">>, StockFix},
			 {<<"rstock">>, StockR}
			]})
    catch
	_:{badmatch, {error, Error}} -> ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"print_wreport", Type}, Payload) -> 
    ?DEBUG("print_wreport with session ~p, type ~p, payload~n~p",[Session, Type, Payload]),
    Merchant = ?session:get(merchant, Session), 
    {struct, Content}  = ?v(<<"content">>, Payload), 
    ShopId     = ?v(<<"shop">>, Content),
    StartDate  = ?v(<<"date">>, Content),
    EmployeeId = ?v(<<"employee">>, Content),
    PCash      = ?v(<<"pcash">>, Content, 0),
    PCashIn    = ?v(<<"pcash_in">>, Content, 0),
    Comment    = ?v(<<"comment">>, Content, []), 
    Curtime    = ?utils:current_time(format_localtime), 
    EndDate  = ?to_s(StartDate) ++ " " ++ time_of_end_day(),

    {ok, EmployeeInfo} = ?w_user_profile:get(employee, Merchant, EmployeeId), 
    
    BaseSettings = get_setting(Merchant, ShopId), 
    {VPrinters, ShopInfo} = ?wifi_print:get_printer(Merchant, ShopId),
    
    ShopName = ?to_s(?v(<<"name">>, ShopInfo)),
    EmployeeName = case ?v(<<"name">>, EmployeeInfo) of
		       undefined -> [];
		       EName -> EName
		   end,

    Conditions = [{<<"shop">>, ShopId},
		  {<<"start_time">>, ?to_b(StartDate)},
		  {<<"end_time">>, ?to_b(EndDate)}],
			     
    ConditionsWithEmployee =
	case EmployeeId of
	    undefined -> Conditions;
	    _ ->
		Conditions ++ [{<<"employ">>, EmployeeId}]
	end,

    DistinctUser =
	try
	    %% ascii -> number
	    ?to_i(lists:nth(5, ?to_s(get_config(<<"p_balance">>, BaseSettings)))) - 48
	catch _:_ ->
		?NO
	end,

    ?DEBUG("distinct user ~p", [DistinctUser]),
		 
    UserId =  case ?v(<<"account">>, Content) of
		  undefined -> -1;
		  Name ->
		      case DistinctUser =:= ?YES of
			  true ->
			      case ?right:get(account, Merchant, Name) of
				  {ok, []} -> -1;
				  {ok, _Account} ->
				      ?v(<<"id">>, _Account)
			      end;
			  false ->
			      -1
		      end
	      end,

    ConditionsWithAccount =
	case UserId of
	    -1 -> ConditionsWithEmployee;
	    _ -> 
		ConditionsWithEmployee ++ [{<<"account">>, UserId}] 
	end, 

    DropConditions = lists:keydelete(<<"account">>, 1 ,lists:keydelete(<<"employ">>, 1, Conditions)),
    
    {ok, SaleInfo} = ?w_report:stastic(stock_sale, Merchant, ConditionsWithAccount), 
    {ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, DropConditions),
    {ok, StockOut} = ?w_report:stastic(stock_out, Merchant, DropConditions),
    {ok, Recharges} = case ?w_report:stastic(recharge, Merchant, DropConditions) of
			  {ok, []} -> {ok, []};
			  {ok, [{_Recharges}]} -> {ok, _Recharges}
		      end,
			  
    ?DEBUG("recharges ~p", [Recharges]),
    %% {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, Conditions),
    %% {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, Conditions),
    %% {ok, StockFix} = ?w_report:stastic(stock_fix, Merchant, Conditions), 
    {ok, StockR} = ?w_report:stastic(
		      stock_real, Merchant,
		      [{<<"shop">>, ShopId},
		       {<<"start_time">>, get_config(<<"qtime_start">>, BaseSettings)}
		      ]),

    {ok, LastStockInfo} = ?w_report:stastic(last_stock_of_shop, Merchant, ShopId, StartDate),
    
    {SellTotal, SellBalance, SellCash, SellCard, SellWxin, SellDraw, SellTicket}
	= sell(info, SaleInfo),
    
    CurrentStockTotal = stock(total, StockR), 
    LastStockTotal = stock(last_total, LastStockInfo),
    StockInTotal = stock(total, StockIn),
    StockOutTotal = stock(total, StockOut),
    
    %% ?DEBUG("stockr ~p", [StockR]),
    
    Sql = "select id, merchant, shop, employ, entry_date"
	" from w_change_shift"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(ShopId)
	++ case DistinctUser =:= ?YES of
	    true -> " and account=" ++ ?to_s(UserId); 
	    false -> " and account=-1"
	end
	%% ++ case UserId of
	%%        -1 -> [];
	%%        _ ->
	%% 	   case DistinctUser =:= ?YES of
	%% 	       true -> " and account=" ++ ?to_s(UserId); 
	%% 	       false -> []
	%% 	   end
	%%    end
	
	++ case EmployeeId of
	       undefined -> " and employ=\'" ++ ?to_s(-1) ++ "\'";
	       _ -> " and employ=\'" ++ ?to_s(EmployeeId) ++ "\'"
	   end
	++ " and entry_date>=\'" ++ ?to_s(StartDate) ++ "\'"
	++ " and entry_date<=\'" ++ ?to_s(EndDate) ++ "\'",

    ShiftSql = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> 
		{insert,
		 "insert into w_change_shift(merchant, account, employ, shop"
		 ", total, balance, cash, card, wxin, withdraw, ticket"
		 ", charge, ccash, ccard, cwxin"
		 ", stock, y_stock, stock_in, stock_out"
		 ", pcash, pcash_in"
		 ", comment, entry_date) values("
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(UserId) ++ ","
		 ++ case EmployeeId of
			undefined -> "\'-1\',";
			_ -> "\'" ++ ?to_s(EmployeeId) ++ "\',"
		 end
		 ++ ?to_s(ShopId) ++ ","

		 ++ ?to_s(SellTotal) ++ ","
		 ++ ?to_s(SellBalance) ++ ","
		 ++ ?to_s(SellCash) ++ ","
		 ++ ?to_s(SellCard) ++ ","
		 ++ ?to_s(SellWxin) ++ ","
		 ++ ?to_s(SellDraw) ++ ","
		 ++ ?to_s(SellTicket) ++ ","

		 ++ ?to_s(?v(<<"cbalance">>, Recharges, 0)) ++ ","
		 ++ ?to_s(?v(<<"tcash">>, Recharges, 0)) ++ ","
		 ++ ?to_s(?v(<<"tcard">>, Recharges, 0)) ++ ","
		 ++ ?to_s(?v(<<"twxin">>, Recharges, 0)) ++ ","
		 
		 ++ ?to_s(CurrentStockTotal) ++ ","
		 ++ ?to_s(LastStockTotal) ++ "," 
		 ++ ?to_s(StockInTotal) ++ ","
		 ++ ?to_s(StockOutTotal) ++ ","

		 ++ ?to_s(PCash) ++ ","
		 ++ ?to_s(PCashIn) ++ ","
		 
		 ++ "\'" ++ ?to_s(Comment) ++ "\',"
		 ++ "\'" ++ ?to_s(StartDate) ++ "\')"};
	    {ok, Shift} ->
		{update,
		 "update w_change_shift set "
		 ++ "total=" ++ ?to_s(SellTotal)
		 ++ ", balance="++ ?to_s(SellBalance)
		 ++ ", cash="++ ?to_s(SellCash)
		 ++ ", card="++ ?to_s(SellCard)
		 ++ ", wxin="++ ?to_s(SellWxin)
		 ++ ", withdraw="++ ?to_s(SellDraw)
		 ++ ", ticket="++ ?to_s(SellTicket)

		 ++ ", charge=" ++ ?to_s(?v(<<"cbalance">>, Recharges, 0)) 
		 ++ ", ccash=" ++ ?to_s(?v(<<"tcash">>, Recharges, 0)) 
		 ++ ", ccard=" ++ ?to_s(?v(<<"tcard">>, Recharges, 0)) 
		 ++ ", cwxin=" ++ ?to_s(?v(<<"twxin">>, Recharges, 0))
		 
		 ++ ", stock=" ++ ?to_s(CurrentStockTotal)
		 ++ ", stock_in=" ++ ?to_s(StockInTotal)
		 ++ ", stock_out=" ++ ?to_s(StockOutTotal)

		 ++ ", pcash=" ++ ?to_s(PCash)
		 ++ ", pcash_in=" ++ ?to_s(PCashIn)

		 ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		 ++ ", entry_date=\'" ++ ?to_s(StartDate) ++ "\'"
		 " where id=" ++ ?to_s(?v(<<"id">>, Shift))}
	end,

    TitleFun =
	fun(Brand, Model) ->
		?wifi_print:title(Brand, Model, ShopName)
		    ++ ?f_print:br(Brand)
		    ++ ?wifi_print:title(Brand, Model, "（交班报表）")
	end,
    
    BodyFun =
	fun(Brand, _Model, Column) ->
		FillLen = case Column of
			      58 -> 
				  (32 - 8) div 2;
			      80 ->
				  (49 - 8) div 2
			  end,
		"日期：" ++ ?to_s(StartDate) ++ ?f_print:br(Brand)
		    ++ "员工：" ++ ?to_s(EmployeeName)
		    ++ ?f_print:br(Brand)
		    ++ ?f_print:br(Brand)
		    
		    ++ "<C>" ++ ?f_print:line(equal, FillLen)
		    ++ "营业状况" ++ ?f_print:line(equal, FillLen)
		    ++ "</C>" ++ ?f_print:br(Brand)
		    
		    ++ "数量  ：" ++ ?to_s(SellTotal) ++ ?f_print:br(Brand) 
		    ++ "营业额：" ++ ?to_s(SellBalance) ++ ?f_print:br(Brand) 
		    ++ "现金  ：" ++ ?to_s(SellCash) ++ ?f_print:br(Brand)
		    ++ "刷卡  ：" ++ ?to_s(SellCard) ++ ?f_print:br(Brand)
		    ++ "微信  ：" ++ ?to_s(SellWxin) ++ ?f_print:br(Brand)
		    ++ "提现  ：" ++ ?to_s(SellDraw) ++ ?f_print:br(Brand)
		    ++ "电子券：" ++ ?to_s(SellTicket) ++ ?f_print:br(Brand)
		    ++ ?f_print:br(Brand)

		    ++ "<C>" ++ ?f_print:line(equal, FillLen)
		    ++ "充值状况" ++ ?f_print:line(equal, FillLen)
		    ++ "</C>" ++ ?f_print:br(Brand)
		    ++ "充值  ：" ++ ?to_s(?v(<<"cbalance">>, Recharges, 0)) ++ ?f_print:br(Brand) 
		    ++ "现金  ：" ++ ?to_s(?v(<<"tcash">>, Recharges, 0))  ++ ?f_print:br(Brand)
		    ++ "刷卡  ：" ++ ?to_s(?v(<<"tcard">>, Recharges, 0))  ++ ?f_print:br(Brand)
		    ++ "微信  ：" ++ ?to_s(?v(<<"twxin">>, Recharges, 0))  ++ ?f_print:br(Brand) 
		    
		    ++ "<C>" ++ ?f_print:line(equal, FillLen)
		    ++ "库存状况"
		    ++ ?f_print:line(equal, FillLen) ++ "</C>" ++ ?f_print:br(Brand)
		    
		    ++ "昨日库存：" ++ ?to_s(LastStockTotal) ++ ?f_print:br(Brand)
		    ++ "当前库存：" ++ ?to_s(CurrentStockTotal) ++ ?f_print:br(Brand)

		    ++ "入库数量：" ++ ?to_s(StockInTotal) ++ ?f_print:br(Brand)
		    ++ "退货数量：" ++ ?to_s(StockOutTotal) ++ ?f_print:br(Brand)
		    ++ ?f_print:br(Brand)

		    ++ "<C>" ++ ?f_print:line(equal, FillLen)
		    ++ "备用金"
		    ++ ?f_print:line(equal, FillLen) ++ "</C>" ++ ?f_print:br(Brand)

		    ++ "备用金：" ++ ?to_s(PCash) ++ ?f_print:br(Brand)
		    ++ "余额  ：" ++ ?to_s(PCashIn) ++ ?f_print:br(Brand)

		    ++ ?f_print:br(Brand)
		    ++ "备注  ：" ++ ?to_s(Comment)
		    ++ "打印日期：" ++ ?to_s(Curtime)
		    
		    ++ lists:foldl(
			 fun(_Inc, Acc) -> ?f_print:br(Brand) ++ Acc end, [], lists:seq(1, 2))
	end,

    %% ResponseFun =
    %%     fun(PCode, PInfo) -> 
    %%             ?utils:respond(200, Req, ?succ(print_wreport, ShopId),
    %%                            [{<<"pcode">>, PCode},
    %%                             {<<"pinfo">>, PInfo}])
    %%     end,
    case
	case ShiftSql of
	    {insert, InsertSql} ->
		?sql_utils:execute(insert, InsertSql);
	    {update, UpdateSql} ->
		?sql_utils:execute(write, UpdateSql, ok)
	end
    of
	{ok, _} ->
	    case get_config(<<"ptype">>, BaseSettings) of
		<<"0">> ->
		    %% ?utils:respond(200, Req, ?succ(print_wreport, ShopId));
		    ReportInfo = {[{<<"sell_total">>, SellTotal},
				  {<<"sell_balance">>, SellBalance},
				  {<<"sell_cash">>, SellCash},
				  {<<"sell_card">>, SellCard},
				  {<<"sell_wxin">>, SellWxin},
				  {<<"sell_draw">>, SellDraw},
				  {<<"sell_ticket">>, SellTicket},

				  {<<"charge_balance">>, ?v(<<"cbalance">>, Recharges, 0)},
				  {<<"charge_cash">>, ?v(<<"tcash">>, Recharges, 0)},
				  {<<"charge_card">>, ?v(<<"tcard">>, Recharges, 0)},
				  {<<"charge_wxin">>, ?v(<<"twxin">>, Recharges, 0)},

				  {<<"lstock">>, LastStockTotal},
				  {<<"cstock">>, CurrentStockTotal},

				  {<<"stock_in">>, StockInTotal},
				  {<<"stock_out">>, StockOutTotal}]},
		    
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"data">>, ReportInfo}]});
		<<"1">> ->
		    PrintInfo = s_print(VPrinters, ShopId, TitleFun, BodyFun, []),
		    m_print(Req, ShopId, PrintInfo)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

sidebar(Session) ->
    AuthenFun =
	fun(Actions) ->
		lists:foldr(
		  fun({Action, Detail}, Acc) ->
			  case ?right_auth:authen(Action, Session) of
			      {ok, Action} -> [Detail|Acc];
			      _ -> Acc
			  end 
		  end, [], Actions)

	end,

    ReportAuthen = AuthenFun(
		   [{?daily_wreport,
		     {"wreport_daily", "实时报表", "glyphicon glyphicon-time"}},
		    {?h_daily_wreport,
		     {"stastic", "日报表", "glyphicon glyphicon-calendar"}},

		    {?h_month_wreport,
		     {"m_stastic", "月报表", "glyphicon glyphicon-calendar"}},
		    
		    {?switch_shift_report,
		     {"switch_shift", "交班报表", "glyphicon glyphicon-transfer"}}
		    
		    %% {?weekly_wreport,
		    %%  {"wreport_weekly", "周报表", "wi wi-moon-waxing-cresent-1"}}, 
		    %% {?monthly_wreport,
		    %%  {"wreport_montyly", "月报表", "wi wi-moon-waxing-cresent-3"}},
		    %% {?quarter_wreport,
		    %%  {"wreport_quarter", "季度报表", "wi wi-moon-waxing-cresent-6"}},
		    %% {?half_wreport,
		    %%  {"wreport_half", "年中报表", "wi wi-moon-first-quarter"}},
		    %% {?year_wreport,
		    %%  {"wreport_year", "年报表", "wi wi-moon-full"}}
		   ]),

    

    case ReportAuthen of
	[]   -> [];
	R -> 
	    ?menu:sidebar(level_1_menu, R) 
    end.


s_print([], Shop, _TitleFun, _BodyFun, []) ->
    ?err(shop_not_printer, Shop);
s_print([], _Shop, _TitleFun, _BodyFun, Acc) ->
    Acc;
s_print([P|Printers], Shop, TitleFun, BodyFun, Acc) ->
    SN     = ?v(<<"sn">>, P),
    Key    = ?v(<<"code">>, P),
    Path   = ?v(<<"server_path">>, P),

    Brand  = ?v(<<"brand">>, P),
    Model  = ?v(<<"model">>, P),
    Column = ?v(<<"pcolumn">>, P),
    
    Server = ?wifi_print:server(?v(<<"server_id">>, P)),

    PrintContent = TitleFun(Brand, Model) ++ BodyFun(Brand, Model, Column),

    s_print(Printers,
	    Shop,
	    TitleFun,
	    BodyFun,
	    [{SN,
	      fun() when Server =:= fcloud ->
		      ?wifi_print:start_print(fcloud, SN, Key, Path, 1, PrintContent)
	      end}|Acc]).

m_print(Req, ShopId, PrintInfo) ->
    ResponseFun =
        fun(PCode, PInfo) -> 
                ?utils:respond(200, Req, ?succ(print_wreport, ShopId),
                               [{<<"pcode">>, PCode},
                                {<<"pinfo">>, PInfo}])
        end,
    m_print(PrintInfo, ResponseFun).

m_print({2401, _}, ResponseFun) ->
    ResponseFun(2401, []);
m_print(PrintInfo, ResponseFun) ->
    case ?wifi_print:multi_print(PrintInfo) of
	{Success, []} -> 
	    ResponseFun(0, Success);
	{[], Failed} ->
	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
		     || {DeviceId, ECode} <- Failed],
	    ResponseFun(1, PInfo);
	{_Success, Failed} when is_list(Failed)->
	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
		     || {DeviceId, ECode} <- Failed],
	    ResponseFun(2, PInfo);
	{error, {ECode, _EInfo}} ->
	    ResponseFun(ECode, [])
    end.


time_of_end_day() ->
    {H, M, S} = calendar:seconds_to_time(86399), 
    Correntfun = fun(V) when V < 10->
			 "0" ++ ?to_s(V);
		    (V) -> ?to_s(V)
		 end,
	     
   Correntfun(H) ++ ":" ++ Correntfun(M) ++ ":" ++ Correntfun(S).


sell(info, [])->
    {0, 0, 0, 0, 0, 0, 0};
sell(info, [{SaleInfo}])->
    {?v(<<"total">>, SaleInfo, 0),
     ?v(<<"spay">>, SaleInfo, 0),
     ?v(<<"cash">>, SaleInfo, 0),
     ?v(<<"card">>, SaleInfo, 0),
     ?v(<<"wxin">>, SaleInfo, 0),
     ?v(<<"draw">>, SaleInfo, 0),
     ?v(<<"ticket">>, SaleInfo, 0)}.

stock(total, []) ->
    0;
stock(total, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0);

stock(last_total, []) ->
    0;
stock(last_total, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0).

yestoday(Datetime) when is_binary(Datetime)->
    <<Y:4/binary, "-", M:2/binary, "-", D:2/binary, _/binary>> = Datetime,
    Seconds = calendar:datetime_to_gregorian_seconds(
		{{?to_i(Y), ?to_i(M), ?to_i(D)}, {0, 0, 0}}) - ?ONE_DAY,
    {{Year, Month, Day}, _} = calendar:gregorian_seconds_to_datetime(Seconds),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])).
    
csv_head(month_report, Do) ->
    Head = "序号,店铺,库存,库存成本"
       ",销售数量,销售金额,销售成本,现金,刷卡,微信,提现,电子卷,核销"
       ",充值,入库数量,入库成本,出库数量,出库成本"
       ",调入数量,调入成本,调出数量,调出成本"
	",盘点数量,盘点成本",
    %% UTF8 = unicode:characters_to_list(Head, utf8),
    %% GBK = diablo_iconv:convert("utf-8", "gbk", UTF8),
    %% Do(?utils:to_utf8(from_latin1, Head)).
    Do(?utils:to_gbk(from_latin1, Head)).

do_write(month_report, Do, _Count, [], Calcs) ->
    {CStockc, CStockCost,
     CSell, CSellCost, CBalance, CCash, CCard, CWxin, CDraw, CTicket, CVeri,
     Charge, CStockIn, CStockOut, CStockInCost, CStockOutCost,
     CTStockIn, CTStockOut, CTStockInCost, CTStockOutCost,
     CStockFix, CStockFixCost} = Calcs,

    Do("\r\n"
       ++ ?d
       ++ ?d
       ++ ?to_s(CStockc) ++ ?d
       ++ ?to_s(CStockCost) ++ ?d

       ++ ?to_s(CSell) ++ ?d
       ++ ?to_s(CBalance) ++ ?d
       ++ ?to_s(CSellCost) ++ ?d
       ++ ?to_s(CCash) ++ ?d
       ++ ?to_s(CCard) ++ ?d
       ++ ?to_s(CWxin) ++ ?d
       ++ ?to_s(CDraw) ++ ?d
       ++ ?to_s(CTicket) ++ ?d
       ++ ?to_s(CVeri) ++ ?d

       ++ ?to_s(Charge) ++ ?d

       ++ ?to_s(CStockIn) ++ ?d
       ++ ?to_s(CStockInCost) ++ ?d
       ++ ?to_s(CStockOut) ++ ?d
       ++ ?to_s(CStockOutCost) ++ ?d

       ++ ?to_s(CTStockIn) ++ ?d
       ++ ?to_s(CTStockInCost) ++ ?d
       ++ ?to_s(CTStockOut) ++ ?d
       ++ ?to_s(CTStockOutCost) ++ ?d

       ++ ?to_s(CStockFix) ++ ?d
       ++ ?to_s(CStockFixCost) ++ ?d);

do_write(month_report, Do, Count, [{H}|T], Calcs) ->
    Shop = ?v(<<"shop">>, H),
    Stockc = ?v(<<"stockc">>, H),
    StockCost = ?v(<<"stockCost">>, H),
    
    Sell = ?v(<<"sell">>, H),
    SellCost = ?v(<<"sellCost">>, H),
    Balance = ?v(<<"balance">>, H),
    Cash = ?v(<<"cash">>, H),
    Card = ?v(<<"card">>, H),
    Wxin = ?v(<<"wxin">>, H),
    Draw = ?v(<<"draw">>, H),
    Ticket = ?v(<<"ticket">>, H),
    Veri = ?v(<<"veri">>, H), 

    Charge = ?v(<<"charge">>, H),
    StockIn = ?v(<<"stockIn">>, H),
    StockOut = ?v(<<"stockOut">>, H),
    StockInCost = ?v(<<"stockInCost">>, H),
    StockOutCost = ?v(<<"stockOutCost">>, H),

    TStockIn = ?v(<<"tstockIn">>, H),
    TStockOut = ?v(<<"tstockOut">>, H),
    TStockInCost = ?v(<<"tstockInCost">>, H),
    TStockOutCost = ?v(<<"tstockOutCost">>, H),

    StockFix = ?v(<<"stockFix">>, H),
    StockFixCost = ?v(<<"stockFixCost">>, H), 
    
    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Stockc) ++ ?d
	++ ?to_s(StockCost) ++ ?d

	++ ?to_s(Sell) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(SellCost) ++ ?d
	++ ?to_s(Cash) ++ ?d
	++ ?to_s(Card) ++ ?d
	++ ?to_s(Wxin) ++ ?d
	++ ?to_s(Draw) ++ ?d
	++ ?to_s(Ticket) ++ ?d
	++ ?to_s(Veri) ++ ?d

	++ ?to_s(Charge) ++ ?d
	++ ?to_s(StockIn) ++ ?d
	++ ?to_s(StockInCost) ++ ?d
	++ ?to_s(StockOut) ++ ?d
	++ ?to_s(StockOutCost) ++ ?d

	++ ?to_s(TStockIn) ++ ?d
	++ ?to_s(TStockInCost) ++ ?d
	++ ?to_s(TStockOut) ++ ?d
	++ ?to_s(TStockOutCost) ++ ?d

	++ ?to_s(StockFix) ++ ?d
	++ ?to_s(StockFixCost) ++ ?d, 
    %% Do(?utils:to_utf8(from_latin1, L)),
    Do(?utils:to_gbk(from_latin1, L)),
    
    {CStockc, CStockCost,
     CSell, CSellCost, CBalance, CCash, CCard, CWxin, CDraw, CTicket, CVeri,
     CCharge, CStockIn, CStockOut, CStockInCost, CStockOutCost,
     CTStockIn, CTStockOut, CTStockInCost, CTStockOutCost,
     CStockFix, CStockFixCost} = Calcs,
    
    do_write(month_report, Do, Count + 1, T, {CStockc + Stockc,
					      CStockCost + StockCost,

					      CSell + Sell,
					      CSellCost + SellCost,
					      CBalance + Balance,
					      CCash + Cash,
					      CCard + Card,
					      CWxin + Wxin,
					      CDraw + Draw,
					      CTicket + Ticket,
					      CVeri + Veri,

					      CCharge + Charge,
					      CStockIn + StockIn,
					      CStockOut + StockOut,
					      CStockInCost + StockInCost,
					      CStockOutCost + StockOutCost,

					      CTStockIn + TStockIn,
					      CTStockOut + TStockOut,
					      CTStockInCost + TStockInCost,
					      CTStockOutCost + TStockOutCost,

					      CStockFix + StockFix,
					      CStockFixCost + StockFixCost}).
	
	



get_setting(Merchant, Shop) ->
    {ok, S}  = ?w_user_profile:get(setting, Merchant),
    Select = 
	case [{SS} || {SS} <- S, ?v(<<"shop">>, SS) =:= Shop] of
	    [] -> [{SS} || {SS} <- S, ?v(<<"shop">>, SS) =:= -1];
	    V -> V ++ [{SS} || {SS} <- S, ?v(<<"shop">>, SS) =:= -1]
	end,
    Select.

get_config(_ConfigName, []) ->
    [];
get_config(ConfigName, [{H}|T]) ->
    case ?v(<<"ename">>, H) =:= ConfigName of
	true -> ?v(<<"value">>, H);
	false -> get_config(ConfigName, T)
    end.
	    
	    
