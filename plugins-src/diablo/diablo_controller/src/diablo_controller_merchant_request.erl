-module(diablo_controller_merchant_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = merchant_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar()},
			  {ngapp, "merchantApp"},
			  {ngcontroller, "merchantCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
     
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_merchant"}) ->
    ?DEBUG("list_merchant with session ~p", [Session]),
    case ?merchant:lookup() of
	{ok, Merchants} ->
	    ?utils:respond(200, batch, Req, Merchants);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_merchant_sms"}) ->
    ?DEBUG("list_merchant_sms with session ~p", [Session]),
    case ?merchant:sms(list) of
	{ok, SMS} ->
	    ?utils:respond(200, batch, Req, SMS);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_merchant_sms_center"}) ->
    ?DEBUG("list_merchant_sms_center with session ~p", [Session]),
    case ?merchant:sms(list_center) of
	{ok, Centers} ->
	    ?utils:respond(200, batch, Req, Centers);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_merchant_shop"}) ->
    ?DEBUG("list_merchant_shop with session ~p", [Session]),
    case ?merchant:shop(list) of
	{ok, Shops} ->
	    ?utils:respond(200, batch, Req, Shops);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% action(Session, Req, {"list_w_merchant"}) ->
%%     ?DEBUG("list_w_merchant with session ~p", [Session]),
%%     case ?merchant:lookup({<<"type">>, ?WHOLESALER}) of
%% 	{ok, Merchants} ->
%% 	    ?utils:respond(200, batch, Req, Merchants);
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%%     end;

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_merchant", MerchantId}) ->
    ?DEBUG("delete_merchant with session ~p, merchantId ~p",
	   [Session, MerchantId]),
    %% user of the merchant should be deleted first
    case  ?right:lookup_account({<<"merchant">>, ?to_integer(MerchantId)}) of
	[] ->
	    ok = ?merchant:merchant(delete, {"id", ?to_integer(MerchantId)}),
	    ?utils:respond(200, Req, ?succ(delete_merchant, MerchantId));
	_ ->
	    ?utils:respond(200, Req, ?err(account_of_merchant_not_empty, MerchantId))
    end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_merchant"}, Payload) ->
    ?DEBUG("new_merchant with session ~p, paylaod ~p", [Session, Payload]),
    case ?merchant:merchant(new, Payload) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_merchant, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_merchant", Id}, Payload) ->
    ?DEBUG("update_merchant with session ~p, paylaod ~p", [Session, Payload]),
    ok =  ?merchant:merchant(update, {<<"id">>, ?to_integer(Id)}, Payload),
    ?utils:respond(200, Req, ?succ(update_merchant, Id));

action(Session, Req, {"new_sms_rate"}, Payload) ->
    ?DEBUG("new_sms_rate with session ~p, paylaod ~p", [Session, Payload]), 
    Merchant = ?v(<<"merchant">>, Payload),
    Rate = ?v(<<"rate">>, Payload),
    case ?merchant:sms(new_rate, Merchant, Rate) of
	{ok, _} ->
	    ?utils:respond(200, Req, ?succ(add_merchant, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_sms_sign"}, Payload) ->
    ?DEBUG("new_sms_sign with session ~p, paylaod ~p", [Session, Payload]), 
    Merchant = ?v(<<"merchant">>, Payload),
    Shop = ?v(<<"shop">>, Payload, ?INVALID_OR_EMPTY),
    Mode = ?v(<<"mode">>, Payload, 0), 
    Sign = ?v(<<"sign">>, Payload),
    
    case ?merchant:sms(new_sign, Merchant, Shop, Mode, Sign) of
	{ok, _} ->
	    ?utils:respond(200, Req, ?succ(add_merchant, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"charge_sms"}, Payload) ->
    ?DEBUG("charge_sms with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?v(<<"merchant">>, Payload),
    Name     = ?v(<<"name">>, Payload, []),
    Mobile   = ?v(<<"mobile">>, Payload, []),
    
    Balance = ?v(<<"balance">>, Payload),
    case ?merchant:sms(charge, Merchant, Balance) of
	{ok, _} -> 
	    ?notify:sms(charge, {Merchant, Name, Mobile}, Balance),
	    ?w_user_profile:update(merchant, Merchant),
	    ?utils:respond(200, Req, ?succ(charge_sms, Merchant)); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.



sidebar() ->
    ?menu:sidebar(
       level_1_menu, 
       [{"merchant_new", "新增商家", "glyphicon glyphicon-plus"},
	{"merchant_detail", "商家详情", "glyphicon glyphicon-briefcase"},
	{"shop_detail", "店铺详情", "glyphicon glyphicon-map-marker"},
	%% {"merchant_sms_rate", "短信费率", "glyphicon glyphicon-yen"},
	{"merchant_sms_center", "短信中心", "glyphicon glyphicon-send"}
       ]).


