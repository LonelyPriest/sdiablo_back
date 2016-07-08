-module(diablo_controller_inventory_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([shop_action/2, get_shops/1, shops/2]).

shop_action(Action, Shops) ->
    ?DEBUG("shpos ~p", [Shops]),
    lists:foldr(
      fun({Id, Name, FunId, RepoId, Charge, Score, Region, Type}, Acc) ->
	      {ok, Children} =
		  ?right_init:get_children([{<<"id">>, FunId}]),

	      %% ?DEBUG("Children ~p", [Children]),

	      case [Child || {Child} <- Children,
			     ?value(<<"id">>, Child) =:= Action] of
		  [] -> Acc;
		  _  -> [{Id, Name, RepoId, Charge, Score, Region, Type}|Acc]
	      end
      end, [], Shops).
    
get_shops(Session) ->
    Shops = 
	case ?session:get(type, Session) of
	    ?SUPER ->
		?shop:lookup();
	    ?MERCHANT ->
		{ok, S0} = ?shop:lookup(?session:get(merchant, Session)),
		lists:foldr(fun({AShop}, Acc) ->
				    [{[{<<"shop_id">>,
					?value(<<"id">>, AShop)},
				       {<<"name">>,
					?value(<<"name">>, AShop)},
				       {<<"func_id">>, ?right_w_inventory}]}
				     |Acc]
			    end, [], S0);
	    ?USER ->
		?right_auth:get_user_shop(Session)
	end,
    %% ?DEBUG("shops ~p", [Shops]),

    SortShops = 
	lists:foldr(
	  fun({Shop}, Acc) ->
		  Id =   ?value(<<"shop_id">>, Shop),
		  Name = ?value(<<"name">>, Shop),
		  FunId = ?value(<<"func_id">>, Shop),
		  S = {Id, Name, FunId},
		  case lists:member(S, Acc) of
		      true  ->  Acc;
		      false -> [S|Acc]
		  end
		  %% [{?to_string(Id), ?to_string(Name)}|Acc]
	  end, [],  Shops),
    ?DEBUG("sort shops ~p", [SortShops]),
    SortShops.


%% =============================================================================
%% @desc: get all of ids of shop by user session
%% =============================================================================
shops(user, Session) ->
    Shops = ?right_auth:get_user_shop(Session),
    ShopIds =
	lists:foldr(
	  fun({Shop}, Acc) ->
		  ShopId = ?value(<<"shop_id">>, Shop),
		  case lists:member(ShopId, Acc) of
		      true -> Acc;
		      false -> [ShopId|Acc]
		  end
	  end, [], Shops),
    ShopIds.
