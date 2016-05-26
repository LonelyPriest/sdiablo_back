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
	
	?utils:respond(200, object, Req,
		       {[{<<"ecode">>, 0},
			 {<<"sale">>, StockSale},
			 {<<"profit">>, StockProfit},
			 {<<"pin">>, StockIn},
			 {<<"pout">>, StockOut},
			 {<<"tin">>, StockTransferIn},
			 {<<"tout">>, StockTransferOut},
			 {<<"fix">>, StockFix}
			]})
    catch
	_:{badmatch, {error, Error}} -> ?utils:respond(200, Req, Error)
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

    



