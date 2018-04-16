-module(diablo_w_retailer_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

-define(d, ?utils:seperator(csv)).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = wretailer_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "wretailerApp"},
			  %% {ngcontroller, "wretailerCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_retailer"}) ->
    ?DEBUG("list w_retailer with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    
    ?utils:respond(
       batch, fun() -> ?w_retailer:retailer(list, Merchant)end, Req);

action(Session, Req, {"list_sys_wretailer"}) ->
    ?DEBUG("list sys_retailer with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    {ok, Shops}   = ?w_user_profile:get(user_shop, Merchant, Session),
    ShopIds = lists:foldr(fun({Shop}, Acc) ->
				  ShopId = ?v(<<"shop_id">>, Shop),
				  case lists:member(ShopId, Acc) of
				      true -> Acc;
				      false ->[ShopId|Acc]
				  end
			  end, [], Shops),
    ?DEBUG("ShopIds ~p", [ShopIds]),
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(sys_retailer, Merchant, ShopIds) end, Req);


action(Session, Req, {"del_w_retailer", Id}) ->
    ?DEBUG("delete_w_retailer with session ~p, Id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(delete, Merchant, Id) of
	{ok, RetailerId} ->
	    ?utils:respond(200, Req, ?succ(delete_w_retailer, RetailerId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_retailer", Id}) ->
    ?DEBUG("get_w_retailer with session ~p, Id ~p", [Session, Id]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       object, fun() -> ?w_retailer:retailer(get, Merchant, Id) end, Req);


action(Session, Req, {"list_w_retailer_charge"}) ->
    ?DEBUG("list w_retailer_charge with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    ?utils:respond(
       batch, fun() -> ?w_retailer:charge(list, Merchant) end, Req);


action(Session, Req, {"list_w_retailer_score"}) ->
    ?DEBUG("list w_retailer_score with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(score, Merchant) end, Req);

action(Session, Req, {"list_retailer_level"}) ->
    ?DEBUG("list_retailer_level with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(retailer_level, Merchant) end, Req).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_retailer"}, Payload) ->
    ?DEBUG("new wretailer with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),

    case 
	case ?v(<<"card">>, Payload, []) of
	    [] -> ok;
	    Card ->
		case ?w_retailer:card(exist, Merchant, Card) of
		    {ok, []} -> ok;
		    {ok, _} -> {error, ?err(wretailer_card_exist, Card)}
		end
	end
    of
	ok -> 
	    case ?w_retailer:retailer(new, Merchant, Payload) of
		{ok, RId} ->
		    ?utils:respond(
		       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, ErrorCard} ->
	    ?utils:respond(200, Req, ErrorCard)
    end;
	
action(Session, Req, {"update_w_retailer", Id}, Payload) ->
    ?DEBUG("update_w_retailer with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    case 
	case ?v(<<"card">>, Payload, []) of
	    [] -> ok;
	    Card ->
		case ?w_retailer:card(exist, Merchant, Card) of
		    {ok, []} -> ok;
		    {ok, _} -> {error, ?err(wretailer_card_exist, Card)}
		end
	end
    of
	ok-> 
	    case ?w_retailer:retailer(get, Merchant, Id) of
		{ok, OldRetailer} ->
		    case ?w_retailer:retailer(update, Merchant, Id, {Payload, OldRetailer}) of
			{ok, RId} ->
			    ?utils:respond(
			       200, Req, ?succ(update_w_retailer, RId));
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, ErrorCard} ->
	    ?utils:respond(200, Req, ErrorCard)
    end;

action(Session, Req, {"add_retailer_level"}, Payload) ->
    ?DEBUG("add_retailer_level with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(add_level, Merchant, Payload) of
	{ok, RId} ->
	    ?w_user_profile:update(retailer_level, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_retailer_batch"}, Payload) ->
    ?DEBUG("update_w_retailer with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    RetailerIds = ?v(<<"retailer">>, Payload, []), 
    ?utils:respond(
       batch, fun() -> ?w_retailer:retailer(get_batch, Merchant, RetailerIds) end, Req);


action(Session, Req, {"update_retailer_score", Id}, Payload) ->
    ?DEBUG("update_retailer_score with Session ~p~npaylaod ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    Score = ?v(<<"score">>, Payload),
    case ?w_retailer:retailer(update_score, Merchant, Id, Score) of
	{ok, RId} ->
	    %% ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(update_w_retailer, RId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_retailer_password", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Password = ?v(<<"password">>, Payload),

    case ?w_retailer:retailer(check_password, Merchant, Id, Password) of
	{ok, {Id, DrawId}} ->
	    %% limt to withdraw
	    Withdraw = 
		case DrawId of
		    ?INVALID_OR_EMPTY -> 0;
		    _ ->
			{ok, Charge} = ?w_user_profile:get(charge, Merchant, DrawId),
			?v(<<"charge">>, Charge)
		end,
	    ?utils:respond(200,
			   Req,
			   ?succ(check_w_retailer_password, Id),
			   [{<<"limit">>, Withdraw}]);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"check_w_retailer_region", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ConsumeShopId = ?v(<<"shop">>, Payload),

    %% get last charge
    case ?w_retailer:retailer(last_recharge, Merchant, Id) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(charge_none, Id));
	{ok, LastCharge} ->
	    ChargeShopId = ?v(<<"shop_id">>, LastCharge),
	    case ?w_user_profile:get(shop, Merchant, ChargeShopId) of
		{ok, [] }   ->
		    ?utils:respond(200, Req, ?err(charge_none_shop, ChargeShopId));
		{ok, [{ChargeShop}]} ->
		    ?DEBUG("chargeShop ~p", [ChargeShop]), 
		    ChargeShopRegion = ?v(<<"region_id">>, ChargeShop),
		    case ?w_user_profile:get(shop, Merchant, ConsumeShopId) of
			{ok, [] }   ->
			    ?utils:respond(200, Req, ?err(charge_none_shop, ConsumeShopId));
			{ok, [{ConsumeShop}]} ->
			    ?DEBUG("consumeShop ~p", [ConsumeShop]), 
			    ConsumeShopRegion = ?v(<<"region_id">>, ConsumeShop),
			    case ChargeShopRegion =:= ConsumeShopRegion of
				true -> 
				    ?utils:respond(
				       200, Req, ?succ(charge_check_region, ConsumeShopRegion));
				false ->
				    ?utils:respond(200, Req, ?err(charge_diff_region, ConsumeShopRegion))
				end
		    end
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error) 
    end;


action(Session, Req, {"new_threshold_card_sale", Id}, Payload) ->
    ?DEBUG("new_threshold_card_sale: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% Retailer = ?v(<<"retailer">>, Payload),
    CardRule = ?v(<<"rule">>, Payload, -1), 
    %% Count = ?v(<<"count">>, Payload), 
    case 
	case ?to_i(CardRule) of
	    ?INVALID_OR_EMPTY ->
		{error, ?err(invalid_threshold_card_rule, Id)};
	    ?THEORETIC_CHARGE ->
		?w_retailer:threshold_card(threshold_consume, Merchant, Id, Payload);
	    _ ->
		?w_retailer:threshold_card(expire_consume, Merchant, Id, Payload)
	end 
    of
	{ok, RSN} ->
	    ?utils:respond(200, Req, ?succ(new_threshold_card_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}]);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end; 

action(Session, Req, {"reset_w_retailer_password", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Password = ?v(<<"password">>, Payload),

    case ?w_retailer:retailer(reset_password, Merchant, Id, Password) of
	{ok, Id} ->
	    ?utils:respond(
	       200, Req, ?succ(reset_w_retailer_password, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% 
%% charge
%%
action(Session, Req, {"add_w_retailer_charge"}, Payload) ->
    ?DEBUG("add_w_retailer_charge with session ~p, payload ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?v(<<"type">>, Payload) =:= undefined of
	true -> ?utils:respond(200, Req, ?err(params_error, "type"));
	false ->
	    case ?w_retailer:charge(new, Merchant, Payload) of
		{ok, Id} ->
		    ?w_user_profile:update(charge, Merchant),
		    ?utils:respond(
		       200, Req, ?succ(add_retailer_charge, Id));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

action(Session, Req, {"del_w_retailer_charge"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ChargeId = ?v(<<"cid">>, Payload),
    case ?w_retailer:charge(delete, Merchant, ChargeId) of
	{ok, Id} -> 
	    ?utils:respond(
	       200, Req, ?succ(delete_retailer_charge, Id)),
	    ?w_user_profile:update(charge, Merchant);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"set_w_retailer_withdraw"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    DrawId = ?v(<<"draw_id">>, Payload),
    {struct, Conditions} = ?v(<<"condition">>, Payload),
    
    NewConditions = 
	case ?v(<<"region">>, Conditions) of
	    undefined -> Conditions;
	    Region -> 
		{ok, Shops} = ?w_user_profile:get(shop, Merchant),
		SelectShops = 
		    lists:foldr(
		      fun({Shop}, Acc)->
			      case ?v(<<"region_id">>, Shop) =:= Region of
				  true -> [?v(<<"id">>, Shop)|Acc];
				  false -> Acc
			      end
		      end, [], Shops), 
		[{<<"shop">>, SelectShops}|proplists:delete(<<"region">>, Conditions)]
	end,
    ?DEBUG("new Conditions ~p", [NewConditions]), 
    
    case ?w_retailer:charge(set_withdraw, Merchant, {DrawId, NewConditions}) of
	{ok, Merchant} -> 
	    ?utils:respond(200, Req, ?succ(set_retailer_withdraw, Merchant));
	    %% ?w_user_profile:update(retailer, Merchant);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_recharge"}, Payload) ->
    ?DEBUG("new_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    ShopId = ?v(<<"shop">>, Payload),
    ShopName = case ?w_user_profile:get(shop, Merchant, ShopId) of
		   {ok, []} -> ShopId;
		   {ok, [{Shop}]} -> ?v(<<"name">>, Shop)
	       end,

    case ?w_retailer:charge(recharge, Merchant, Payload) of
	{ok, {SN, Mobile, CBalance, Balance, Score}} -> 
	    %% ?w_user_profile:update(retailer, Merchant),
	    try
		{ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1), 
		case ?to_i(?v(<<"recharge_sms">>, Setting, 0)) of
		    0 ->
			?utils:respond(200, Req, ?succ(new_recharge, SN), [{<<"sms_code">>, 0}]);
		    1 ->
			{SMSCode, _} =
			    ?notify:sms_notify(
			       Merchant, {ShopName, Mobile, 0, CBalance, Balance, Score}),
			?utils:respond(200,
				       Req,
				       ?succ(new_recharge, SN),
				       [{<<"sms_code">>, SMSCode}]) 
		end
	    catch
		_:{badmatch, _Error} ->
		    {Code1, _} =  ?err(sms_send_failed, Merchant),
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(new_recharge, SN), [{<<"sms_code">>, Code1}])
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_recharge"}, Payload) ->
    ?DEBUG("delete_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    RechargeId = ?v(<<"recharge">>, Payload), 
    case ?w_retailer:charge(get_recharge, Merchant, RechargeId) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(invalid_recharge, RechargeId));
	{ok, Recharge} -> 
	    case ?w_retailer:charge(delete_recharge, Merchant, {RechargeId, Recharge}) of
		{ok, RechargeId} ->
		    %% ?w_user_profile:update(retailer, Merchant),
		    ?utils:respond(200, Req, ?succ(delete_recharge, RechargeId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_recharge"}, Payload) ->
    ?DEBUG("update_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    ChargeId = ?v(<<"charge_id">>, Payload),

    case ?w_retailer:charge(update_recharge, Merchant, {ChargeId, Payload}) of
	{ok, ChargeId} ->
	    %% ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(200, Req, ?succ(update_recharge, ChargeId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_retailer_detail"}, Payload) ->
    ?DEBUG("filter_retailer with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    {struct, Mode}   = ?v(<<"mode">>, Payload),
    {struct, Fields} = ?v(<<"fields">>, Payload),
    
    Order = ?v(<<"mode">>, Mode, ?SORT_BY_ID),
    Sort  = ?v(<<"sort">>, Mode),

    NewPayload = 
	case ?v(<<"region">>, Fields) of
	    undefined -> proplists:delete(<<"mode">>, Payload);
	    Region -> 
		{ok, Shops} = ?w_user_profile:get(shop, Merchant),
		SelectShops = 
		    lists:foldr(
		      fun({Shop}, Acc)->
			      case ?v(<<"region_id">>, Shop) =:= Region of
				  true -> [?v(<<"id">>, Shop)|Acc];
				  false -> Acc
			      end
		      end, [], Shops), 
		proplists:delete(
		  <<"fields">>, proplists:delete(<<"mode">>, Payload))
		    ++ [{<<"fields">>, {struct, [{<<"shop">>, SelectShops}|Fields]}}]
	end,
    ?DEBUG("new payload ~p", [NewPayload]),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_retailer, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  {retailer, mode(Order), Sort},
		  Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, NewPayload);

action(Session, Req, {"filter_charge_detail"}, Payload) ->
    ?DEBUG("filter_charge_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_charge_detail, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  charge_detail, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);


action(Session, Req, {"filter_ticket_detail"}, Payload) ->
    ?DEBUG("filter_ticket_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_ticket_detail, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  ticket_detail, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);


action(Session, Req, {"effect_w_retailer_ticket"}, Payload) ->
    ?DEBUG("effect_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    TicketId = ?v(<<"tid">>, Payload),

    case ?w_retailer:ticket(effect, Merchant, TicketId) of
	{ok, TicketId} ->
	    ?utils:respond(200, Req, ?succ(effect_ticket, TicketId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"consume_w_retailer_ticket"}, Payload) ->
    ?DEBUG("consume_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    TicketId = ?v(<<"tid">>, Payload),
    Comment = ?v(<<"comment">>, Payload, []),

    {ok, Scores}=?w_user_profile:get(score, Merchant),
    Score2Money =
	case lists:filter(fun({S})-> ?v(<<"type_id">>, S) =:= 1 end, Scores) of
	    [] -> [];
	    [{_Score2Money}] -> _Score2Money
	end, 
    ?DEBUG("score2money ~p, ", [Score2Money]),
    
    case ?w_retailer:ticket(consume, Merchant, {TicketId, Comment, Score2Money}) of
	{ok, TicketId} ->
	    %% ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(200, Req, ?succ(consume_ticket, TicketId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"get_w_retailer_ticket"}, Payload) ->
    ?DEBUG("get_w_retailer_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    
    case 
	case ?v(<<"mode">>, Payload, ?TICKET_BY_RETAILER) of
	    ?TICKET_BY_RETAILER ->
		RetailerId = ?v(<<"retailer">>, Payload),
		?w_retailer:get_ticket(by_retailer, Merchant, RetailerId);
	    ?TICKET_BY_BATCH ->
		Batch = ?v(<<"batch">>, Payload),
		UseCustomTicket = ?v(<<"custom">>, Payload, ?SCORE_TICKET), 
		?w_retailer:get_ticket(by_batch, Merchant, Batch, UseCustomTicket)
	end
    of 
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, {Value}}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"make_ticket_batch"}, Payload) ->
    ?DEBUG("make_ticket_batch with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    Count = ?v(<<"count">>, Payload),
    Balance = ?v(<<"balance">>, Payload),
    StartBatch = ?v(<<"sbatch">>, Payload),

    case erlang:length(?to_s(StartBatch)) > 9 of
	true ->
	    ?utils:respond(200, Req, ?err(ticket_batch_length_error, StartBatch));
	false ->
	    case Count > 1000 of
		true ->
		    ?utils:respond(200, Req, ?err(make_ticket_invalid_count, Count));
		false ->
		    case Balance > 5000 of
			true ->
			    ?utils:respond(200, Req, ?err(make_ticket_invalid_balance, Balance));
			false ->
			    case ?w_retailer:make_ticket(batch, Merchant, Payload) of
				{ok, StartBatch} ->
				    ?utils:respond(200, Req, ?succ(consume_ticket, StartBatch));
				{error, Error} ->
				    ?utils:respond(200, Req, Error)
			    end
		    end
	    end
    end;

action(Session, Req, {"discard_custom_ticket"}, Payload) ->
    ?DEBUG("discard_custom_ticket: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    TicketId = ?v(<<"tid">>, Payload),
    DiscardMode = ?v(<<"mode">>, Payload),

    case DiscardMode of
	?TICKET_DISCARD_ONE ->
	    case ?w_retailer:ticket(discard_custom_one, Merchant, TicketId) of
		{ok, TicketId} ->
		    ?utils:respond(200, Req, ?succ(discard_ticket_one, TicketId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	?TICKET_DISCARD_ALL ->
	    case ?w_retailer:ticket(discard_custom_all, Merchant) of
		{ok, Merchant} ->
		    ?utils:respond(200, Req, ?succ(discard_ticket_all, Merchant));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

action(Session, Req, {"filter_custom_ticket_detail"}, Payload) ->
    ?DEBUG("filter_custom_ticket_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_custom_ticket_detail, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  custom_ticket_detail, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);


%%
%% threshold card
%%
action(Session, Req, {"list_threshold_card_good"}, Payload) ->
    ?DEBUG("list_threshold_card_good with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    Shops = ?v(<<"shop">>, Payload, []), 
    ?utils:respond(
       batch, fun() -> ?w_retailer:threshold_card_good(
			  list,
			  Merchant,
			  case Shops of
			      [] -> [];
			      _ -> [{<<"shop">>, Shops}]
			  end) end, Req);

action(Session, Req, {"add_threshold_card_good"}, Payload) ->
    ?DEBUG("add_threshold_card_good with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    case ?w_retailer:threshold_card_good(new, Merchant, Payload) of
	{ok, GoodId} ->
	    %% ?w_user_profile:update(charge, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(add_threshold_card_good, GoodId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;    

action(Session, Req, {"filter_threshold_card_detail"}, Payload) ->
    ?DEBUG("filter_threshold_card_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(total_threshold_card, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(threshold_card, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"filter_threshold_card_sale"}, Payload) ->
    ?DEBUG("filter_threshold_card_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(total_threshold_card_sale, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(threshold_card_sale, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"filter_threshold_card_good"}, Payload) ->
    ?DEBUG("filter_threshold_card_good with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(total_threshold_card_good, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(threshold_card_good, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

%% 
%% charge
%%
action(Session, Req, {"add_w_retailer_score"}, Payload) ->
    ?DEBUG("add_w_retailer_score with session ~p, payload ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),

    case ?w_retailer:score(new, Merchant, Payload) of
	{ok, Id} ->
	    ?w_user_profile:update(score, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(add_retailer_score, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"export_w_retailer"}, Payload) ->
    ?DEBUG("export_w_retailer with session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportCode  = ?to_i(?v(<<"export_code">>, BaseSetting, 0)),
    
    {_StartTime, _EndTime, Conditions} = ?sql_utils:cut(non_prefix, Payload),
    case ?w_retailer:retailer(list, Merchant, Conditions) of
	[] -> ?utils:respond(200, Req, ?err(wretailer_export_none, Merchant));
	{ok, Retailers} ->
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("retailer", Merchant, UserId),
	    SysVips = ?gen_report:sys_vip_of(merchant, Merchant),
	    ?DEBUG("sysvips ~p", [SysVips]),
	    NewRetailers = [{R} || {R} <- Retailers, not lists:member(?v(<<"id">>, R), SysVips)],
	    %% ?DEBUG("NewRetailers ~p", [NewRetailers]),

	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} ->
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(retailer, DoFun, ExportCode),
			do_write(retailer, DoFun, 1, NewRetailers, ExportCode),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p",
				   [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(200, Req, ?err(wretailer_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wretailer_export_error, Error))
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"export_recharge_detail"}, Payload) ->
    ?DEBUG("export_recharge_detail with session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    {struct, Condition}   = ?v(<<"condition">>, Payload, []),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportCode  = ?to_i(?v(<<"export_code">>, BaseSetting, 0)), 
    case ?w_retailer:charge(list_recharge, Merchant, Condition) of
	[] -> ?utils:respond(200, Req, ?err(wretailer_export_none, Merchant));
	{ok, Details} ->
	    {ok, ExportFile, Url} = ?utils:create_export_file("recharge", Merchant, UserId),
	    
	    case file:open(ExportFile, [write, raw]) of
		{ok, Fd} ->
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(recharge, DoFun, ExportCode),
			do_write(recharge, DoFun, 1, Details, ExportCode, {0, 0, 0}),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p",
				   [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(200, Req, ?err(wretailer_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wretailer_export_error, Error))
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"syn_retailer_pinyin"}, Payload) ->
    ?DEBUG("syn_retailer_pinyin with session ~p", [Session]),

    Merchant = ?session:get(merchant, Session), 
    Retailers = ?v(<<"retailer">>, Payload, []),
    case ?w_retailer:syn(pinyin, Merchant, Retailers) of
	{ok, Merchant} ->
	    %% ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(syn_retailer_pinyin, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"match_retailer_phone"}, Payload) ->
    ?DEBUG("match_retailer_phone with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Phone = ?v(<<"prompt">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 0),
    ?utils:respond(batch, fun() -> ?w_retailer:match(phone, Merchant, {Mode, Phone}) end, Req).

sidebar(Session) ->
    Merchant = ?session:get(merchant, Session),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, ?DEFAULT_BASE_SETTING),
    
    S1 = [{"wretailer_detail", "会员详情", "glyphicon glyphicon-map-marker"}], 
    S2 = 
	case ?right_auth:authen(?new_w_retailer, Session) of
	    {ok, ?new_w_retailer} ->
		[{"wretailer_new", "新增会员", "glyphicon glyphicon-plus"}];
	    _ -> []
	end,

    S3 = [{"wretailer_charge_detail", "充值记录", "glyphicon glyphicon-bookmark"}],

    Recharge =
	[{{"promotion", "充值积分", "glyphicon glyphicon-superscript"},
	  
	  [{"recharge_detail", "充值方案", "icon-large icon-star-half"},
	   {"score_detail", "积分方案", "icon-large icon-lock"}]
	
	 }],

    Ticket = 
	[{{"ticket", "电子券", "glyphicon glyphicon-certificate"},

	  case ?right_auth:authen(?filter_ticket_detail, Session) of
	      {ok, ?filter_ticket_detail} ->
		  [{"score_ticket_detail", "积分电子券", "glyphicon glyphicon-font"}];
	      _ -> []
	  end
	  ++ case ?right_auth:authen(?filter_custom_ticket_detail, Session) of
		  {ok, ?filter_custom_ticket_detail} ->
		     [{"custom_ticket_detail", "优惠电子券", "glyphicon glyphicon-bold"}];
		  _ -> []
	      end
	 }],
    
    ThresholdCard = [{{"threshold_card", "次/月/季/年卡", "glyphicon glyphicon-credit-card" },
		      [{"card_detail", "卡类详情", "glyphicon glyphicon-credit-card"},
		       {"card_good",   "按次商品", "glyphicon glyphicon-book"}, 
		       {"card_sale",   "消费记录", "glyphicon glyphicon-bookmark"}
		      ] 
		     }],

    Level = [{"wretailer_level", "会员等级", "glyphicon glyphicon-sort-by-alphabet"}],

    
    L1 = ?menu:sidebar(level_1_menu, S2 ++ S1 ++ S3),
    L2 = ?menu:sidebar(level_2_menu, Ticket ++ Recharge ++
			   case ?to_i(?v(<<"threshold_card">>, BaseSetting, ?NO)) of
			       ?YES -> ThresholdCard;
			       ?NO -> []
			   end),
    L1 ++ L2 ++ ?menu:sidebar(level_1_menu, Level).

csv_head(retailer, Do, Code) ->
    Head = "序号,名称,类型,联系方式,余额,累计消费,累计积分,所在店铺,日期",
    C = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, Head);
	    1 -> ?utils:to_gbk(from_latin1, Head)
	end,
    
    %% UTF8 = unicode:characters_to_list(Head, utf8),
    Do(C);
csv_head(recharge, Do, Code) ->
    Head = "序号,单号,店铺,经手人,会员,手机号码,充值方案,帐户余额,充值金额,赠送金额,累积余额"
	",备注,充值日期",
    
    %% UTF8 = unicode:characters_to_list(Head, utf8),
    C = 
	case Code of
	    0 ->
		?utils:to_utf8(from_latin1, Head);
	    1 ->
		?utils:to_gbk(from_latin1, Head)
	end,
    Do(C).

do_write(retailer, _Do, _Count, [], _Code) ->
    ok;
do_write(retailer, Do, Count, [{H}|T], Code) ->
    %% ?DEBUG("retailer ~p", [H]),
    %% Id      = ?v(<<"id">>, H),
    Name    = ?v(<<"name">>, H),
    Type    = retailer_type(?v(<<"type_id">>, H)),
    Mobile  = ?v(<<"mobile">>, H, []),
    Balance = ?v(<<"balance">>, H, 0),
    Consume = ?v(<<"consume">>, H),
    Score   = ?v(<<"score">>, H),
    Shop    = ?v(<<"shop">>, H),
    Entry   = ?v(<<"entry_date">>, H), 

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Name) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Mobile) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(Consume) ++ ?d
	++ ?to_s(Score) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Entry) ++ ?d,

    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),

    Line = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line), 
    
    do_write(retailer, Do, Count + 1, T, Code).

do_write(recharge, Do, _Seq, [], _Code, {AccCBalance, AccSBalance, _AccBalance}) ->
    Do("\r\n"
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d
       ++ ?to_s(AccCBalance) ++ ?d
       ++ ?to_s(AccSBalance) ++ ?d
       ++ ?d
       ++ ?d
       ++ ?d);

do_write(recharge, Do, Seq, [{H}|T], Code, {AccCBalance, AccSBalance, AccBalance}) ->
    RSN          = ?v(<<"rsn">>, H),
    Shop         = ?v(<<"shop">>, H),
    Employee     = ?v(<<"employee">>, H),
    Retailer     = ?v(<<"retailer">>, H),
    Mobile       = ?v(<<"mobile">>, H),
    ChargeName   = ?v(<<"cname">>, H),
    LBalance     = ?v(<<"lbalance">>, H),
    CBalance     = ?v(<<"cbalance">>, H), 
    SBalance     = ?v(<<"sbalance">>, H),
    Comment      = ?v(<<"comment">>, H),
    Datetime     = ?v(<<"entry_date">>, H),

    CurrentBalance = LBalance + CBalance + SBalance,

    L = "\r\n"
	++ ?to_s(Seq) ++ ?d
	++ ?to_s(RSN) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(Mobile) ++ ?d
	++ ?to_s(ChargeName) ++ ?d
	++ ?to_s(LBalance) ++ ?d
	++ ?to_s(CBalance) ++ ?d
	++ ?to_s(SBalance) ++ ?d
	++ ?to_s(CurrentBalance) ++ ?d
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Datetime) ++ ?d,

    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),

    Line = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line),
    
    do_write(recharge, Do, Seq + 1, T, {AccCBalance + CBalance,
					AccSBalance + SBalance,
					AccBalance + CurrentBalance}).

retailer_type(0) -> "普通会员";
retailer_type(1) -> "充值会员";
retailer_type(_) -> "未知类型".
		    
mode(0) -> use_id; 
mode(1) -> use_balance;
mode(2) -> use_consume.

