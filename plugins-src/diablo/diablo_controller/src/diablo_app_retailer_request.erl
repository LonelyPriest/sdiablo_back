-module(diablo_app_retailer_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(app_gen_request).

-export([action/5]).

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, AppInfo, {"get_app_retailer"}, Payload) ->
    ?DEBUG("get_retailer with session ~p, appinfo ~p, paylaod~n~p", [Session, AppInfo, Payload]),
    Merchant = ?v(<<"merchant">>, AppInfo),
    Phone = ?v(<<"phone">>, Payload),
    ?utils:app_respond(fun() -> ?w_retailer:retailer(get_by_phone, Merchant, Phone) end, Req);

action(Session, Req, AppInfo, {"new_app_retailer"}, Payload) ->
    ?DEBUG("new_app_retailer with session ~p, appinfo ~p, paylaod~n~p", [Session, AppInfo, Payload]),
    Merchant = ?v(<<"merchant">>, AppInfo),
    case ?w_retailer:retailer(new, Merchant, Payload) of
	{ok, RId} ->
	    ?utils:respond(
	       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, AppInfo, {"get_app_shop"}, Payload) ->
    ?DEBUG("get_retailer with session ~p, appinfo ~p, paylaod~n~p", [Session, AppInfo, Payload]),
    Merchant = ?v(<<"merchant">>, AppInfo),
    ?utils:app_respond(fun() -> ?shop:lookup(Merchant) end, Req). 
    

