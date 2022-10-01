-module(diablo_app_retailer_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(app_gen_request).

-export([action/5]).

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, AppInfo, {"match_retailer_phone"}, Payload) ->
    ?DEBUG("match_retailer_phone with session ~p, appinfo ~p, paylaod~n~p", [Session, AppInfo, Payload]),
    Merchant = ?v(<<"merchant">>, AppInfo),
    Phone = ?v(<<"prompt">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 0),
    ShopId  = ?v(<<"shop">>, Payload, -1),
    Shops = 
	case ?v(<<"region">>, Payload) of
	    undefined -> [];
	    ?NO -> [];
	    ?YES ->
		{ok, AllShop} = ?w_user_profile:get(shop, Merchant),
		%% ?DEBUG("AllShop ~p", [AllShop]),
		case lists:filter(fun({S}) -> ?v(<<"id">>, S) =:= ShopId end, AllShop) of
		    [] -> [];
		    [{Shop}] ->
			%% ?DEBUG("Shop ~p", [Shop]),
			SameRegionShops =
			    lists:filter(
			      fun({S}) ->
				      ?v(<<"region_id">>, Shop) =:= ?v(<<"region_id">>, S)
			      end, AllShop),
			lists:foldr(fun({S}, Acc) ->
					    [?v(<<"id">>, S)|Acc]
				    end, [], SameRegionShops)
		end
	end, 
    ?utils:respond(batch, fun() -> ?w_retailer:match(phone, Merchant, {Mode, Phone, Shops}) end, Req).


