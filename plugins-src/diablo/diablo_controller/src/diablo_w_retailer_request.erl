-module(diablo_w_retailer_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = wretailer_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wretailerApp"},
			  {ngcontroller, "wretailerCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_retailer"}) ->
    ?DEBUG("list w_retailer with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    
    %% ?utils:respond(
    %%    batch, fun() -> ?w_retailer:retailer(list, Merchant) end, Req);
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(retailer, Merchant) end, Req);

action(Session, Req, {"list_w_province"}) ->
    ?DEBUG("list w_province with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       batch, fun() -> ?w_retailer:province(list, Merchant) end, Req);

action(Session, Req, {"list_w_city"}) ->
    ?DEBUG("list w_city with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_retailer:city(list, Merchant) end, Req);

action(Session, Req, {"del_w_retailer", Id}) ->
    ?DEBUG("delete_w_retailer with session ~p, Id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(delete, Merchant, Id) of
	{ok, RetailerId} ->
	    ?utils:respond(200, Req, ?succ(delete_w_retailer, RetailerId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_retailer"}, Payload) ->
    ?DEBUG("new wretailer with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 

    case ?w_retailer:retailer(new, Merchant, Payload) of
	{ok, RId} ->
	    ?utils:respond(
	       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
	

action(Session, Req, {"update_w_retailer", Id}, Payload) ->
    ?DEBUG("update_w_retailer with Session ~p~npaylaod ~p", [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    Province = ?v(<<"province">>, Payload),

    UpdateFun =
	fun(Update, CId) ->
		case ?w_retailer:retailer(update, Merchant, Id, Update) of
		    {ok, RId} ->
			?utils:respond(200,
				       Req,
				       ?succ(update_w_retailer, RId),
				       {<<"cid">>, CId});
		    {error, Error} ->
			?utils:respond(200, Req, Error)
		end 
	end,
    
    case ?v(<<"city">>, Payload, []) of
    	[]   ->
    	    UpdateFun(Payload, -1);
    	City ->
    	    case ?w_retailer:city(new, Merchant, City, Province) of
		{ok, CityId} -> 
		    NewPayload = [{<<"city">>, CityId}
				  |proplists:delete(<<"city">>, Payload)],
		    UpdateFun(NewPayload, CityId);
		Error ->
		    ?utils:respond(200, Req, Error)
	    end
    end.
		

sidebar(Session) -> 
    S1 = [{"wretailer_detail", "会员详情", "glyphicon glyphicon-book"}],
    
    S2 = 
	case ?right_auth:authen(?new_w_retailer, Session) of
	    {ok, ?new_w_retailer} ->
		[{"wretailer_new", "新增会员", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,
    
    ?menu:sidebar(level_1_menu, S2 ++ S1).
       
