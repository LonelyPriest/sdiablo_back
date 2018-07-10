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
    end;

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_employe", EmployId}) ->
    ?DEBUG("delete employ with session ~p, id ~p", [Session, EmployId]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(delete, Merchant, EmployId) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"recover_employe", EmployId}) ->
    ?DEBUG("recover employ with session ~p, id ~p", [Session, EmployId]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(recover, Merchant, EmployId) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_employe"}, Payload) ->
    ?DEBUG("new employ with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_employ, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_employe", Id}, Payload) ->
    ?DEBUG("update a employ with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(update, Merchant, Id, Payload) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(update_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

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
			"批发开单", "glyphicon glyphicon-usd"}, Shops), 

	    BatchReject = ?w_inventory_request:authen_shop_action(
			 {?reject_batch_sale,
			  "reject_bsale",
			  "批发退货",
			  "glyphicon glyphicon-arrow-left"}, Shops), 

	    ListBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?list_batch_sale,
		    "list_bsale",
		    "批发记录",
		    "glyphicon glyphicon-bookmark"}, Shops),

	    

	    NoteBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?note_batch_sale,
		    "note_bsale",
		    "批发明细",
		    "glyphicon glyphicon-map-marker"}, Shops),
		
	    %% Merchant = ?session:get(merchant, Session), 
	    %% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),

	    Saler = 
		[{"new_saler", "新增客户", "glyphicon glyphicon-plus"},
		 {"saler_detail", "客户详情", "glyphicon glyphicon-bookmark"}], 


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



