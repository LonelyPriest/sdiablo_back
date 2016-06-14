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
    ?DEBUG("daily_wrport with session ~p, type ~p, paylaod~n~p",
	   [Session, Type, Payload]), 
    Merchant = ?session:get(merchant, Session),
    %% {struct, C} = ?v(<<"condition">>, Payload),
    
    ?pagination:pagination(
       fun(_Match, Conditions) ->
	       ?w_report:report(total, ?to_a(Type), Merchant, Conditions)
       end,
       
       fun(_Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_report:report(
		  ?to_a(Type), Merchant, CurrentPage, ItemsPerPage, Conditions)
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
    ShopId   = ?v(<<"shop">>, Content, []),
    EmployeeId = ?v(<<"employee">>, Content),
    Datetime = ?v(<<"datetime">>, Content),
    Total    = ?v(<<"total">>, Content),
    SPay     = ?v(<<"spay">>, Content), 
    Cash     = ?v(<<"cash">>, Content),
    Card     = ?v(<<"card">>, Content), 

    {ok, EmployeeInfo} = ?w_user_profile:get(employee, Merchant, EmployeeId),
    {VPrinters, ShopInfo} = ?wifi_print:get_printer(Merchant, ShopId),
    %% ?DEBUG("VPrinters ~p", [VPrinters]),
    
    ResponseFun =
        fun(PCode, PInfo) -> 
                ?utils:respond(200, Req, ?succ(print_wreport, ShopId),
                               [{<<"pcode">>, PCode},
                                {<<"pinfo">>, PInfo}])
        end,


    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, ShopId),

    QTimeStart = ?v(<<"qtime_start">>, BaseSetting),

    {ok, StockInfo} =
	?w_inventory:filter(
	   total_groups,
	   'and',
	   Merchant,
	   [{<<"shop">>, ShopId},
	    {<<"start_time">>, QTimeStart}]),

    LeftStock = ?v(<<"t_amount">>, StockInfo),
    %% ?DEBUG("stock info ~p", [StockInfo]),

    case VPrinters of
        [] ->
	    {ECode, _} = ?err(shop_not_printer, ShopId), 
	    ResponseFun(ECode, []);
	_  ->
	    ShopName = ?to_s(?v(<<"name">>, ShopInfo)),
	    Employee = ?v(<<"name">>, EmployeeInfo),
	    PrintInfo = 
		lists:foldr(
		  fun(P, Acc) ->
			  ?DEBUG("p ~p", [P]),
			  SN     = ?v(<<"sn">>, P),
			  Key    = ?v(<<"code">>, P),
			  Path   = ?v(<<"server_path">>, P),

			  Brand  = ?v(<<"brand">>, P),
			  Model  = ?v(<<"model">>, P),

			  %% Column = ?v(<<"pcolumn">>, P),
			  %% PShop  = ?v(<<"pshop">>, P),

			  %% ?DEBUG("P ~p", [P]),
			  Server = ?wifi_print:server(?v(<<"server_id">>, P)), 

			  Title = ?wifi_print:title(Brand, Model, ShopName)
			      ++ ?f_print:br(Brand)
			      ++ ?wifi_print:title(Brand, Model, "（交班报表）"),

			  Body = "日期：" ++ ?to_s(Datetime) ++ ?f_print:br(Brand)
			      ++ "营业员：" ++ ?to_s(Employee) ++ ?f_print:br(Brand)
			      ++ "营业额：" ++ ?to_s(SPay) ++ ?f_print:br(Brand) 
			      ++ "数量：" ++ ?to_s(Total) ++ ?f_print:br(Brand)
                              ++ "现金：" ++ ?to_s(Cash) ++ ?f_print:br(Brand)
                              ++ "刷卡：" ++ ?to_s(Card) ++ ?f_print:br(Brand) 
			      ++ "库存：" ++ ?to_s(LeftStock) ++ ?f_print:br(Brand),
			  
			  PrintContent = Title ++ Body,

			  [{SN, fun() when Server =:= fcloud ->
					?wifi_print:start_print(
					   fcloud, SN, Key, Path, 1, PrintContent) 
				end}|Acc]
		  end, [], VPrinters),


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
            end
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
		     {"wreport_daily", "日报表", "wi wi-moon-waxing-cresent-6"}},
		    {?stock_stastic,
		     {"stastic", "进销存", "wi wi-moon-full"}}
		    
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

    



