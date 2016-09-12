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
-export([sell/2, stock/2]).

action(Session, Req) ->
    ?DEBUG("req ~p", [Req]),
    {ok, HTMLOutput} = wreport_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wreportApp"},
			  {ngcontroller, "wreportCtrl"}]),
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
		{ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),

		{ok, StockSale} = ?w_report:stastic(stock_sale, Merchant, Conditions),
		{ok, StockProfit} = ?w_report:stastic(stock_profit, Merchant, Conditions),
		
		{ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, Conditions),
		{ok, StockOut} = ?w_report:stastic(stock_out, Merchant, Conditions),
		
		{ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, Conditions),
		{ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, Conditions),
		
		{ok, StockR} = ?w_report:stastic(
				  stock_real,
				  Merchant,
				  lists:keydelete(<<"start_time">>, 1,
						  lists:keydelete(<<"end_time">>, 1, Conditions))
				  ++ [{<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}]),
		
		{ok, LastStockInfo} = ?w_report:stastic(last_stock_of_shop, Merchant, ShopIds),
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
    try 
	{ok, StockSale} = ?w_report:stastic(stock_sale, Merchant, Payload),
	{ok, StockProfit} = ?w_report:stastic(stock_profit, Merchant, Payload),
	{ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, Payload),
	{ok, StockOut} = ?w_report:stastic(stock_out, Merchant, Payload),
	{ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, Payload),
	{ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, Payload),
	{ok, StockFix} = ?w_report:stastic(stock_fix, Merchant, Payload),
	{ok, StockR} = ?w_report:stastic(stock_real, Merchant, Payload),
	
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
    EmployeeId = ?v(<<"employee">>, Content),
    PCash      = ?v(<<"pcash">>, Content, 0),
    PCashIn    = ?v(<<"pcash_in">>, Content, 0),
    Comment    = ?v(<<"comment">>, Content, []),
    
    Currenttime = ?utils:current_time(format_localtime), 
    TimeEnd = time_of_end_day(),
    TodayStart = ?utils:current_time(localdate),
    TodayEnd = TodayStart ++ " " ++ TimeEnd,
    
    {ok, EmployeeInfo} = ?w_user_profile:get(employee, Merchant, EmployeeId),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, ShopId), 

    {VPrinters, ShopInfo} = ?wifi_print:get_printer(Merchant, ShopId),
    ShopName = ?to_s(?v(<<"name">>, ShopInfo)),
    EmployeeName = case ?v(<<"name">>, EmployeeInfo) of
		       undefined -> [];
		       EName -> EName
		   end,
    
    Conditions = case EmployeeId of
		     undefined ->
			 [{<<"shop">>, ShopId},
			  {<<"start_time">>, ?to_b(TodayStart)},
			  {<<"end_time">>, ?to_b(TodayEnd)}];
		     _ ->
			 [{<<"shop">>, ShopId},
			  {<<"employ">>, EmployeeId},
			  {<<"start_time">>, ?to_b(TodayStart)},
			  {<<"end_time">>, ?to_b(TodayEnd)}]
		 end,

    DropConditions = lists:keydelete(<<"employ">>, 1, Conditions),
    
    {ok, SaleInfo} = ?w_report:stastic(stock_sale, Merchant, Conditions), 
    {ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, DropConditions),
    {ok, StockOut} = ?w_report:stastic(stock_out, Merchant, DropConditions),
    %% {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, Conditions),
    %% {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, Conditions),
    %% {ok, StockFix} = ?w_report:stastic(stock_fix, Merchant, Conditions), 
    {ok, StockR} = ?w_report:stastic(
		      stock_real, Merchant,
		      [{<<"shop">>, ShopId},
		       {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}
		      ]),

    {ok, LastStockInfo} = ?w_report:stastic(last_stock_of_shop, Merchant, ShopId), 

    {SellTotal, SellBalance, SellCash, SellCard} = sell(info, SaleInfo),
    CurrentStockTotal = stock(total, StockR), 
    LastStockTotal = stock(last_total, LastStockInfo),
    StockInTotal = stock(total, StockIn),
    StockOutTotal = stock(total, StockOut),
    %% ?DEBUG("stockr ~p", [StockR]),
    
    Sql = "select id, merchant, shop, employ entry_date"
	" from w_change_shift"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(ShopId)
	++ case EmployeeId of
	       undefined -> [];
	       _ -> " and employ=\'" ++ ?to_s(EmployeeId) ++ "\'"
	   end
	++ " and entry_date>\'" ++ TodayStart ++ "\'"
	++ " and entry_date<=\'" ++ TodayEnd ++ "\'",

    ShiftSql = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> 
		{insert,
		 "insert into w_change_shift(merchant, employ, shop"
		 ", total, balance, cash, card"
		 ", stock, y_stock, stock_in, stock_out"
		 ", pcash, pcash_in"
		 ", comment, entry_date) values("
		 ++ ?to_s(Merchant) ++ ","
		 ++ case EmployeeId of
			undefined -> "\'-1\',";
			_ -> "\'" ++ ?to_s(EmployeeId) ++ "\',"
		 end
		 ++ ?to_s(ShopId) ++ ","

		 ++ ?to_s(SellTotal) ++ ","
		 ++ ?to_s(SellBalance) ++ ","
		 ++ ?to_s(SellCash) ++ ","
		 ++ ?to_s(SellCard) ++ ","

		 ++ ?to_s(CurrentStockTotal) ++ ","
		 ++ ?to_s(LastStockTotal) ++ "," 
		 ++ ?to_s(StockInTotal) ++ ","
		 ++ ?to_s(StockOutTotal) ++ ","

		 ++ ?to_s(PCash) ++ ","
		 ++ ?to_s(PCashIn) ++ ","
		 
		 ++ "\'" ++ ?to_s(Comment) ++ "\',"
		 ++ "\'" ++ ?to_s(Currenttime) ++ "\')"};
	    {ok, Shift} ->
		{update,
		 "update w_change_shift set "
		 ++ "total=" ++ ?to_s(SellTotal)
		 ++ ", balance="++ ?to_s(SellBalance)
		 ++ ", cash="++ ?to_s(SellCash)
		 ++ ", card="++ ?to_s(SellCard)

		 ++ ", stock=" ++ ?to_s(CurrentStockTotal)
		 ++ ", stock_in=" ++ ?to_s(StockInTotal)
		 ++ ", stock_out=" ++ ?to_s(StockOutTotal)

		 ++ ", pcash=" ++ ?to_s(PCash)
		 ++ ", pcash_in=" ++ ?to_s(PCashIn)

		 ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		 ++ ", entry_date=\'" ++ ?to_s(Currenttime) ++ "\'"
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
		"日期：" ++ ?to_s(Currenttime) ++ ?f_print:br(Brand)
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
		    ++ ?f_print:br(Brand)

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
	    case ?v(<<"ptype">>, BaseSetting) of
		<<"0">> ->
		    ?utils:respond(200, Req, ?succ(print_wreport, ShopId));
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
		    {?stock_stastic,
		     {"stastic", "日报表", "glyphicon glyphicon-calendar"}},
		    
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
    {0, 0, 0, 0};
sell(info, [{SaleInfo}])->
    {?v(<<"total">>, SaleInfo, 0),
     ?v(<<"spay">>, SaleInfo, 0),
     ?v(<<"cash">>, SaleInfo, 0),
     ?v(<<"card">>, SaleInfo, 0)}.

stock(total, []) ->
    0;
stock(total, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0);

stock(last_total, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0).

    
