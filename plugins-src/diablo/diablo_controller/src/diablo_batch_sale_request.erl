-module(diablo_batch_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = bsale_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)} 
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_employe"}) ->
    ?DEBUG("list employ with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),       
    case ?w_user_profile:get(employee, Merchant) of
	{ok, Employees} ->
	    ?utils:respond(200, batch, Req, Employees);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
%% action(Session, Req, {"delete_employe", EmployId}) ->
%%     ?DEBUG("delete employ with session ~p, id ~p", [Session, EmployId]),
%%     Merchant = ?session:get(merchant, Session),
%%     case ?employ:employ(delete, Merchant, EmployId) of
%% 	{ok, EmployId} ->
%% 	    ?w_user_profile:update(employee, Merchant),
%% 	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%%     end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_batch_sale"}, Payload) ->
    ?DEBUG("new_batch_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UserId = ?session:get(id, Session), 
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload), 
    start(new_bsale, Req, Merchant, Invs, Base ++ [{<<"user">>, UserId}]); 

action(Session, Req, {"new_batch_saler"}, Payload) ->
    ?DEBUG("new_batch_saler with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?b_saler:batch_saler(new, Merchant, Payload) of
	{ok, Id} ->
	    ?utils:respond(200, Req, ?succ(new_batch_saler, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_batch_saler"}, Payload) ->
    ?DEBUG("filter_retailer with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    {struct, Mode}   = ?v(<<"mode">>, Payload),
    %% {struct, Fields} = ?v(<<"fields">>, Payload), 
    Order = ?v(<<"mode">>, Mode, ?SORT_BY_ID),
    Sort  = ?v(<<"sort">>, Mode),

    NewPayload = proplists:delete(<<"mode">>, Payload),
    ?DEBUG("new payload ~p", [NewPayload]), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?b_saler:filter(total_saler, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?b_saler:filter(
		  {saler, mode(Order), Sort}, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, NewPayload);


action(Session, Req, {"get_bsaler_batch"}, Payload) ->
    ?DEBUG("get_bsaler_batch with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    BSalerIds = ?v(<<"bsaler">>, Payload, []), 
    ?utils:respond(batch, fun() -> ?b_saler:batch_saler(get_batch, Merchant, BSalerIds) end, Req);

action(Session, Req, {"match_bsaler_phone"}, Payload) ->
    ?DEBUG("match_bsaler_phone with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Phone = ?v(<<"prompt">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 0),
    ?utils:respond(batch, fun() -> ?b_saler:match(phone, Merchant, {Mode, Phone}) end, Req).

sidebar(Session) -> 
    case ?right_request:get_shops(Session, bsale) of
	[] ->
	    ?menu:sidebar(level_2_menu, []);
	Shops ->
	    BookBatchSale = ?w_inventory_request:authen_shop_action(
			   {?book_batch_sale,
			    "book_bsale",
			    "批发订货", "glyphicon glyphicon-usd"}, Shops),
	    
	    BatchSale = ?w_inventory_request:authen_shop_action(
		       {?new_batch_sale,
			"new_bsale",
			"销售开单", "glyphicon glyphicon-usd"}, Shops), 

	    BatchReject = ?w_inventory_request:authen_shop_action(
			 {?reject_batch_sale,
			  "reject_bsale",
			  "销售退货",
			  "glyphicon glyphicon-arrow-left"}, Shops), 

	    ListBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?list_batch_sale,
		    "detail_bsale",
		    "交易记录",
		    "glyphicon glyphicon-bookmark"}, Shops), 

	    NoteBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?note_batch_sale,
		    "note_bsale",
		    "交易明细",
		    "glyphicon glyphicon-map-marker"}, Shops),
		
	    %% Merchant = ?session:get(merchant, Session), 
	    %% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),

	    Saler = 
		[{"new_bsaler", "新增客户", "glyphicon glyphicon-plus"},
		 {"bsaler_detail", "客户详情", "glyphicon glyphicon-bookmark"}], 


	    L1 = ?menu:sidebar(
		    level_1_menu,
		    BookBatchSale
		    ++ BatchSale
		    ++ BatchReject
		    ++ ListBatchSale
		    ++ NoteBatchSale
		    ++ Saler),

	    %% L2 = ?menu:sidebar(level_2_menu, Saler),

	    L1 

    end.


start(new_bsale, Req, Merchant, Invs, Base) ->
    Round            = ?v(<<"round">>, Base, 1),
    ShouldPay        = ?v(<<"should_pay">>, Base),
    Datetime         = ?v(<<"datetime">>, Base),
    %% half an hour
    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 1800 of
	true ->
	    CurDatetime = ?utils:current_time(format_localtime), 
	    ?utils:respond(200,
			   Req,
			   ?err(wsale_invalid_date, "new_w_sale"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, ?to_b(CurDatetime)}]);
	false-> 
	    case check_inventory(oncheck, Round, 0, ShouldPay, Invs) of
		{ok, _} -> 
		    case ?b_sale:bsale(new, Merchant, lists:reverse(Invs), Base) of 
			{ok, RSN} -> 
			    ?utils:respond(
			       200, Req, ?succ(new_w_sale, RSN),
			       [{<<"rsn">>, ?to_b(RSN)}]); 
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{error, EInv} ->
		    StyleNumber = ?v(<<"style_number">>, EInv),
		    ?utils:respond(
		       200,
		       Req,
		       ?err(wsale_invalid_inv, StyleNumber),
		       [{<<"style_number">>, StyleNumber},
			{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
		{error, Moneny, ShouldPay} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(wsale_invalid_pay, Moneny),
		       [{<<"should_pay">>, ShouldPay},
			{<<"check_pay">>, Moneny}])
	    end
    end.

check_inventory(oncheck, Round, Moneny, ShouldPay, []) ->
    ?DEBUG("Moneny ~p, ShouldPay, ~p", [Moneny, ShouldPay]),
    case Round of
	1 -> 
	    case round(Moneny) == ShouldPay of
		true -> {ok, none};
		false -> {error, round(Moneny), ShouldPay}
	    end;
	0 ->
	    case Moneny == ShouldPay of
		true -> {ok, none};
		false -> {error, Moneny, ShouldPay}
	    end
    end;

check_inventory(oncheck, Round, Money, ShouldPay, [{struct, Inv}|T]) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Amounts = ?v(<<"amounts">>, Inv),
    Count = ?v(<<"sell_total">>, Inv),
    DCount = lists:foldr(
	       fun({struct, A}, Acc)->
		       ?v(<<"sell_count">>, A) + Acc
	       end, 0, Amounts),

    FPrice = ?v(<<"rprice">>, Inv),
    Calc = FPrice * Count, 
    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true -> check_inventory(oncheck, Round, Money + Calc, ShouldPay, T);
		false -> {error, Inv}
	    end
    end.


%% calc_count(reject, [], Total) ->
%%     Total;
%% calc_count(reject, [{struct, Inv}|T], Total) ->
%%     InvTotal = ?v(<<"sell_total">>, Inv),
%%     calc_count(reject, T, Total + InvTotal).

mode(0) -> use_id.
