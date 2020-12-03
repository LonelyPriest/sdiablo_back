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

action(Session, Req, {"list_ticket_plan"}) ->
    ?DEBUG("list_ticket_plan: session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       batch, fun() -> ?w_retailer:ticket(list_plan, Merchant)end, Req);

action(Session, Req, {"del_w_retailer", Id}) ->
    ?DEBUG("delete_w_retailer with session ~p, Id ~p", [Session, Id]), 
    Merchant = ?session:get(merchant, Session),
    UTable   = ?session:get(utable, Session),

    case ?w_retailer:retailer(delete, {Merchant, UTable}, Id) of
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

action(Session, Req, {"delete_ticket_plan", PlanId}) ->
    ?DEBUG("delete_ticket_plan with Session ~p plan ~p", [Session, PlanId]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:ticket(delete_plan, Merchant, PlanId) of
	{ok, PlanId} ->
	    ?w_user_profile:update(ticket_plan, Merchant),
	    ?utils:respond(200, Req, ?succ(new_ticket_plan, PlanId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


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

action(Session, Req, {"update_retailer_level"}, Payload) ->
    ?DEBUG("update_retailer_level with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(update_level, Merchant, Payload) of
	{ok, Level} ->
	    ?w_user_profile:update(retailer_level, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(add_w_retailer, Level), {<<"id">>, Level});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_retailer_batch"}, Payload) ->
    ?DEBUG("get_w_retailer with Session ~p~npaylaod ~p", [Session, Payload]), 
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

action(Session, Req, {"list_threshold_child_card"}, Payload) ->
    ?DEBUG("list_retailer_child_card: Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Retailer = ?v(<<"retailer">>, Payload),
    CSN      = ?v(<<"csn">>, Payload),
    
    case ?w_retailer:threshold_card(list_child, Merchant, Retailer, CSN) of
	{ok, Childs} ->
	    ?utils:respond(
	       200, object, Req, {[{<<"ecode">>, 0},
				   {<<"child">>, Childs}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_retailer_password", Id}, Payload) ->
    ?DEBUG("check_w_retailer_password: Session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Password = ?v(<<"password">>, Payload),
    CheckPwd = ?v(<<"check">>, Payload, ?YES),

    case ?w_retailer:retailer(check_password, Merchant, Id, Password, CheckPwd) of
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

action(Session, Req, {"check_w_retailer_charge", Id}, Payload) ->
    ?DEBUG("check_w_retailer_charge: session ~p, Payload ~p", [Session, Payload]),
    Merchant        = ?session:get(merchant, Session),
    ConsumeShop     = ?v(<<"shop">>, Payload),
    Pay             = ?v(<<"pay">>, Payload),
    RetailerBalance = ?v(<<"balance">>, Payload),
    RetailerDraw    = ?v(<<"draw">>, Payload),
    DrawRegion      = ?v(<<"region">>, Payload, -1),
    MaxDraw         = ?utils:min_value(RetailerBalance, Pay),
    ?DEBUG("MaxDraw ~p", [MaxDraw]),

    SameRegionShops = 
	case DrawRegion =:= ?NO of
	    true -> [];
	    false  ->
		case ?shop:lookup(Merchant) of
		    {ok, []} -> {<<"shop">>, ConsumeShop};
		    {ok, Shops} ->
			[ConsumeShopRegion] = [?v(<<"region_id">>, S)
					       || {S} <- Shops, ?v(<<"id">>, S) =:= ConsumeShop],
			?DEBUG("consumeShopRegion ~p", [ConsumeShopRegion]),
			{<<"shop">>,
			 lists:foldr(
			   fun({Shop}, Acc) ->
				   case ?v(<<"region_id">>, Shop) =:= ConsumeShopRegion of
				       true -> [?v(<<"id">>, Shop)|Acc];
				       false -> Acc
				   end
			   end, [], Shops)};
		    {error, _Error} ->
			{<<"shop">>, ConsumeShop}
		end
	end,
    ?DEBUG("SameRegionShops ~p", [SameRegionShops]),
	
    %% get last charge
    %% case ?w_retailer:retailer(last_recharge, Merchant, Id) of
    %% 	{ok, []} ->
    %% 	    ?utils:respond(200, Req, ?err(charge_none, Id));
    %% 	{ok, LastCharge} ->
    %% 	    %% ?DEBUG("LastCharge ~p", [LastCharge]),
    %% 	    ChargeId     = ?v(<<"charge_id">>, LastCharge),
    %% 	    ChargeShopId = ?v(<<"shop_id">>, LastCharge),
    %% 	    CBalance     = ?v(<<"cbalance">>, LastCharge),
    %% 	    SBalance     = ?v(<<"sbalance">>, LastCharge),

    %% 	    %% get charge promotion
    %% 	    case ?w_retailer:charge(get_charge, Merchant, ChargeId) of
    %% 		{ok, []} ->
    %% 		    ?utils:respond(200, Req, ?err(charge_none, ChargeId));
    %% 		{ok, ChargePromotion} ->
    %% 		    LimitShop       = ?v(<<"ishop">>, ChargePromotion),
    %% 		    LimitBalance    = ?v(<<"ibalance">>, ChargePromotion),
    %% 		    LimitCount      = ?v(<<"icount">>, ChargePromotion),
    %% 		    ThresholdBalance = ?v(<<"mbalance">>, ChargePromotion), 

    %% 		    SameShop = case ConsumeShopId =:= ChargeShopId of
    %% 				   true -> ?YES;
    %% 				   false -> ?NO
    %% 			       end,
    %% 		    ?utils:respond(200, Req, ?succ(charge_check_region, ChargeId),
    %% 				   [{<<"ishop">>, LimitShop},
    %% 				    {<<"balance">>, CBalance + SBalance},
    %% 				    {<<"ibalance">>, LimitBalance},
    %% 				    {<<"mbalance">>, ThresholdBalance}, 
    %% 				    {<<"icount">>, LimitCount},
    %% 				    {<<"same_shop">>, SameShop}]) 
    %% 	    end;
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error) 
    %% end;
    
    %% has bank card
    case 
	case ?w_retailer:bank_card(get, Merchant, Id, SameRegionShops) of
	    {ok, []} ->
		case ?w_retailer:retailer(last_recharge, Merchant, Id) of
		    {ok, []} ->
			{error, ?err(charge_none, Id)};
		    {ok, LastCharge} ->
			ChargeId  = ?v(<<"charge_id">>, LastCharge),
			ChargeShop = ?v(<<"shop_id">>, LastCharge),
			case ?w_retailer:charge(get_charge, Merchant, ChargeId) of
			    {ok, []} ->
				{error, ?err(charge_none, ChargeId)};
			    {ok, ChargePromotion} ->
				case RetailerDraw =/= ?INVALID_OR_EMPTY of
				    true  ->
					{ok, DrawStratege} = ?w_user_profile:get(charge, Merchant, RetailerDraw),
					LimitDraw = ?v(<<"charge">>, DrawStratege),
					{ok,
					  ?utils:min_value(LimitDraw, MaxDraw),
					  [{?DEFAULT_BANK_CARD, 
					    ?utils:min_value(LimitDraw, MaxDraw),
					    RetailerBalance,
					    1,
					    same_shop(ConsumeShop, ChargeShop),
					    0,
					    ChargeShop}]};
				    false ->
					LimitShop     = ?v(<<"ishop">>, ChargePromotion), 
					LimitBalance  = ?v(<<"ibalance">>, ChargePromotion, ?INVALID_OR_EMPTY),
					ThresholdBalance = ?v(<<"mbalance">>, ChargePromotion),
					case LimitBalance =/= ?INVALID_OR_EMPTY andalso LimitBalance =/= 0 of
					    true ->
						LimitDraw = Pay div ThresholdBalance * LimitBalance,
						{ok,
						 ?utils:min_value(LimitDraw, MaxDraw),
						 [{?DEFAULT_BANK_CARD, 
						   ?utils:min_value(LimitDraw, MaxDraw),
						   RetailerBalance,
						   1,
						   same_shop(ConsumeShop, ChargeShop),
						   LimitShop,
						   ChargeShop}]}; 
					    false ->
						LimitCount = ?v(<<"icount">>, ChargePromotion),
						case LimitCount =/= ?INVALID_OR_EMPTY
						    andalso LimitCount =/= 0 of
						    true ->
							CBalance     = ?v(<<"cbalance">>, LastCharge),
							SBalance     = ?v(<<"sbalance">>, LastCharge),
							OneTakeBalance = (CBalance + SBalance) div LimitCount,
							{ok,
							 ?utils:min_value(OneTakeBalance, RetailerBalance),
							 [{?DEFAULT_BANK_CARD, 
							   ?utils:min_value(OneTakeBalance, RetailerBalance),
							   RetailerBalance,
							   1,
							   same_shop(ConsumeShop, ChargeShop),
							   LimitShop,
							   ChargeShop}]};
						    false ->
							{ok,
							 MaxDraw,
							 [{?DEFAULT_BANK_CARD,
							   MaxDraw,
							   RetailerBalance,
							   0,
							   same_shop(ConsumeShop, ChargeShop),
							   LimitShop,
							   ChargeShop}]}
						end

					end
				end
			end
		end;
	    {ok, BankCards} ->
		SortBankCards = sort_bank_card(BankCards, []),
		{CalcDraw, Draws} =
		    draw_with_bank_card(SortBankCards, Merchant, ConsumeShop, Pay, MaxDraw, 0, []),
		?DEBUG ("calcDraw ~p, Draws ~p", [CalcDraw, Draws]),
		{ok, CalcDraw, Draws}
		%% case MaxDraw > CalcDraw of
		%%     true ->
		%% 	case ?w_retailer:retailer(last_recharge, Merchant, Id) of
		%% 	    {ok, []} ->
		%% 		{ok, [{?DEFAULT_BANK_CARD, MaxDraw - CalcDraw, 1, 0}|Draws]};
		%% 	    {ok, LastCharge} ->
		%% 		ChargeId  = ?v(<<"charge_id">>, LastCharge),
		%% 		ChargeShop = ?v(<<"shop_id">>, LastCharge),
		%% 		case ?w_retailer:charge(get_charge, Merchant, ChargeId) of
		%% 		    {ok, []} ->
		%% 			{ok,
		%% 			 [{?DEFAULT_BANK_CARD,
		%% 			   MaxDraw - CalcDraw,
		%% 			   same_shop(ConsumeShop, ChargeShop),
		%% 			   0}|Draws]};
		%% 		    {ok, ChargePromotion} ->
		%% 			LimitShop       = ?v(<<"ishop">>, ChargePromotion), 
		%% 			{ok,
		%% 			 [{?DEFAULT_BANK_CARD,
		%% 			   MaxDraw - CalcDraw,
		%% 			   same_shop(ConsumeShop, ChargeShop),
		%% 			   LimitShop}|Draws]}
		%% 		    end
		%% 	end; 
		%%     false ->
		%% 	{ok, Draws}
		%% end
	end
    of
	{ok, ShouldDraw, DrawInfos} ->
	    ?DEBUG("ShouldDraw ~p, DrawInfos ~p", [ShouldDraw, DrawInfos]),
	    MyDraw = 
		lists:foldr(
		  fun({Card, MDraw, CardBalance, CardType, SameShop, LimitShop, ChargeShop}, Acc) ->
			  [{[{<<"card">>, Card},
			     {<<"draw">>, MDraw},
			     {<<"balance">>, CardBalance},
			     {<<"type">>, CardType},
			     {<<"same_shop">>, SameShop},
			     {<<"limit_shop">>, LimitShop},
			     {<<"charge_shop">>, ChargeShop}]}|Acc]
		  end, [], DrawInfos), 
	    ?utils:respond(200, Req, ?succ(charge_check_region, Id),
			   [{<<"cdraw">>, ShouldDraw},
			    {<<"cards">>, MyDraw}]);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_retailer_transe_count", Id}, Payload) ->
    ?DEBUG("check_w_retailer_transe_count: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable   = ?session:get(utable, Session),

    RetailerPhone = ?v(<<"phone">>, Payload),
    Shop          = ?v(<<"shop">>, Payload),
    Count         = ?v(<<"count">>, Payload, 0),
    case ?w_retailer:retailer(check_trans_count, {Merchant, UTable}, Id, Shop, Count, 30) of
	{ok, 0, []} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, 
					       {<<"count">>, 0},
					       {<<"trans">>, []}]});
	{ok, TransCount, Trans} ->
	    case TransCount > Count of
		true ->
		    ?DEBUG("unexcept sale: trans ~p, count ~p", [Trans, TransCount]),
		    {ECode, EInfo} = ?err(max_trans, Id),
		    ?utils:respond(200,
				   object,
				   Req,
				   {[{<<"ecode">>, ECode},
				     {<<"einfo">>, ?to_b(EInfo)},
				     {<<"count">>, TransCount},
				     {<<"trans">>, Trans}]}),
		    %% send sms
		    %% {ok, Retailer} = ?w_retailer:retailer(get, Merchant, Id),
		    {ShopName, _ShopSign} = ?shop:shop(get_sign, Merchant, Shop),
		    %% ?DEBUG("shop name ~ts", [ShopName]),
		    {ok, Managers} = ?employ:employ(list_manager, Merchant), 
		    %% ?DEBUG("managers ~p", [Managers]), 

		    lists:foreach(
		      fun({M}) -> 
			      ?notify:sms(
				 max_trans,
				 Merchant,
				 ?v(<<"mobile">>, M),
				 {?v(<<"name">>, M), ShopName, RetailerPhone, TransCount})
		      end, Managers); 
		false -> 
		    ?utils:respond(200,
				   object,
				   Req,
				   {[{<<"ecode">>, 0}, 
				     {<<"count">>, TransCount},
				     {<<"trans">>, Trans}]}) 
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_threshold_card_sale", Id}, Payload) ->
    ?DEBUG("new_threshold_card_sale: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    CardRule = ?v(<<"rule">>, Payload, -1),
    Mobile   = ?v(<<"mobile">>, Payload),
    %% Shop     = ?v(<<"shop_name">>, Payload),
    ShopId     = ?v(<<"shop">>, Payload),
    case 
	case ?to_i(CardRule) of
	    ?INVALID_OR_EMPTY ->
		{error, ?err(invalid_threshold_card_rule, Id)};
	    ?THEORETIC_CHARGE ->
		?w_retailer:threshold_card(threshold_consume, Merchant, Id, Payload);
	    ?BALANCE_LIMIT_CHARGE ->
		?w_retailer:threshold_card(threshold_consume, Merchant, Id, Payload);
	    _ ->
		?w_retailer:threshold_card(expire_consume, Merchant, Id, Payload)
	end 
    of
	{ok, RSN, LeftSwiming, Expire} ->
	    try
		BaseSettings = ?w_report_request:get_setting(Merchant, ?DEFAULT_BASE_SETTING),
		Notifies = 
		    case ?w_report_request:get_config(<<"recharge_sms">>, BaseSettings) of
			[] -> ?to_s(?SMS_NOTIFY);
			_Value when size(_Value) =/= 2 -> ?to_s(?SMS_NOTIFY);
			_Value  -> ?to_s(_Value)
		    end,
		?DEBUG("notify ~p", [Notifies]),
		SMS = try
			  lists:nth(2, Notifies) - 48
		      catch _:_ ->
			      ?NO
		      end,

		?DEBUG("sms ~p", [SMS]), 
		case ?to_i(SMS) of
		    0 ->
			?utils:respond(
			   200,
			   Req,
			   ?succ(new_threshold_card_sale, RSN),
			   [{<<"rsn">>, ?to_b(RSN)}, {<<"sms_code">>, 0}]);
		    1 ->
			{SMSCode, _} = ?notify:sms(swiming, Merchant, Mobile, {ShopId, 1, LeftSwiming, Expire}),
			?utils:respond(200,
				       Req,
				       ?succ(new_recharge, RSN),
				       [{<<"rsn">>, ?to_b(RSN)}, {<<"sms_code">>, SMSCode}]) 
		end
	    catch
		_:{badmatch, _Error} ->
		    {Code1, _} =  ?err(sms_send_failed, Merchant),
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(new_recharge, RSN),
		       [{<<"rsn">>, ?to_b(RSN)}, {<<"sms_code">>, Code1}])
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end; 

action(Session, Req, {"delete_threshold_card_sale"}, Payload) ->
    ?DEBUG("delete_threshold_card_sale: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Card = ?v(<<"card">>, Payload),
    Attrs = lists:keydelete(<<"card">>, 1, Payload),
    ?utils:respond(
       normal,
       fun() ->?w_retailer:threshold_card(cancel_consume, Merchant, Card, Attrs) end,
       fun(ConsumeCard) ->?succ(new_threshold_card_sale, ConsumeCard) end,
       Req);

action(Session, Req, {"update_card_expire"}, Payload) ->
    ?DEBUG("update_card_expire: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    CardId = ?v(<<"card">>, Payload),
    Expire = ?v(<<"expire">>, Payload),

    case ?w_retailer:threshold_card(update_expire, Merchant, CardId, Expire) of
	{ok, CardId} ->
	    ?utils:respond(200, Req, ?succ(new_threshold_card_sale, CardId));
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
		    ?utils:respond(200, Req, ?succ(add_retailer_charge, Id));
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
    %% {ShopName, ShopSign} = case ?w_user_profile:get(shop, Merchant, ShopId) of
    %% 			       {ok, []} -> ShopId;
    %% 			       {ok, [{Shop}]} -> {?v(<<"name">>, Shop), ?v(<<"sign">>, Shop, [])}
    %% 	       end,

    ChargeId    = ?v(<<"charge">>, Payload),
    case ?w_user_profile:get(charge, Merchant, ChargeId) of
	{ok, []} ->
	    ?utils:respond(200, Req,?err(charge_no_promotion, ChargeId));
	{ok, Charge} -> 
	    case ?w_retailer:charge(recharge, Merchant, {Payload, Charge}) of
		{ok, {SN, Mobile, CBalance, Balance, Score}} -> 
		    try
			BaseSettings = ?w_report_request:get_setting(Merchant, ?DEFAULT_BASE_SETTING), 
			<<SMS:1/binary, _/binary>> = ?w_report_request:get_config(<<"recharge_sms">>, BaseSettings), 
			case ?to_i(SMS) of
			    0 ->
				?utils:respond(200, Req, ?succ(new_recharge, SN), [{<<"sms_code">>, 0}]);
			    1 ->
				{SMSCode, _} =
				    ?notify:sms_notify(Merchant, {ShopId, Mobile, 0, CBalance, Balance, Score}),
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
	    end
    end;

action(Session, Req, {"delete_recharge"}, Payload) ->
    ?DEBUG("delete_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    RechargeId = ?v(<<"recharge">>, Payload), 
    case ?w_retailer:charge(get_recharge, Merchant, RechargeId) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(invalid_recharge, RechargeId));
	{ok, Recharge} ->
	    ChargeId = ?v(<<"cid">>, Recharge),
	    case ?w_user_profile:get(charge, Merchant, ChargeId) of 
		{ok, []} ->
		    ?utils:respond(200, Req, ?err(charge_no_promotion, ChargeId));
		{ok, ChargePromotion} ->
		    case ?w_retailer:charge(
			    delete_recharge, Merchant, {RechargeId, Recharge, ChargePromotion}) of
			{ok, RechargeId} ->
			    %% ?w_user_profile:update(retailer, Merchant),
			    ?utils:respond(200, Req, ?succ(delete_recharge, RechargeId));
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end
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

action(Session, Req, {"delete_threshold_card"}, Payload) ->
    ?DEBUG("delete_threshold_card with session ~p, payload ~p", [Session, Payload]),
    CardId = ?v(<<"card">>, Payload),
    Merchant  = ?session:get(merchant, Session),
    case
	case ?w_retailer:threshold_card(get, Merchant, CardId) of
	    {ok, Card} ->
		case ?v(<<"rule">>, Card) =:= ?THEORETIC_CHARGE of 
		    true ->
			case ?v(<<"ctime">>, Card) > 0 of
			    true ->
				{error, ?err(threshold_card_non_zero, CardId)};
			    false ->
				?w_retailer:threshold_card(delete, Merchant, Card)
			end;
		    false ->
			?w_retailer:threshold_card(delete, Merchant, Card)
			%% EDate = ?v(<<"edate">>, Card),
			%% case ?utils:compare_date(date, ?utils:current_date(), EDate) of
			%%     true ->
			%% 	?w_retailer:threshold_card(delete, Merchant, Card);
			%%     false ->
			%% 	{error, ?err(threshold_card_non_expire, CardId)}
			%% end 
		end;
	    Error ->
		Error
	end
    of
	{ok, CardId} ->
	    ?utils:respond(200, Req, ?succ(update_recharge, CardId));
	{error, _Error} ->
	    ?utils:respond(200, Req, _Error)
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


action(Session, Req, {"print_w_retailer"}, Payload) ->
    ?DEBUG("print_w_retailer with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    {struct, Mode}   = ?v(<<"mode">>, Payload),
    {struct, Conditions} = ?v(<<"condition">>, Payload), 
    Order  = ?v(<<"mode">>, Mode),
    
    case ?w_retailer:retailer(list, Merchant, {Conditions, mode(Order)}) of
	[] -> ?utils:respond(200, Req, ?err(wretailer_export_none, Merchant));
	{ok, Retailers} ->
	    ?DEBUG("retailer ~p", [Retailers]),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, Retailers}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"filter_retailer_consume"}, Payload) ->
    ?DEBUG("filter_retailer_consume with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    UTable    = ?session:get(utable, Session),
    Mode      = ?v(<<"mode">>, Payload, 0),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter({total_consume, Mode}, ?to_a(Match), {Merchant, UTable}, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter({consume, Mode},
				  Match,
				  {Merchant, UTable},
				  Conditions,
				  CurrentPage, ItemsPerPage)
       end, Req, Payload);

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
    TicketSid = ?v(<<"sid">>, Payload),
    Comment = ?v(<<"comment">>, Payload, []),

    {ok, Scores}=?w_user_profile:get(score, Merchant),
    Score2Money =
	case lists:filter(fun({S})-> ?v(<<"type_id">>, S) =:= 1
					 andalso ?v(<<"id">>, S) =:= TicketSid end, Scores) of
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

action(Session, Req, {"syn_score_ticket"}, Payload) ->
    ?DEBUG("syn_score_ticket: session ~p, payload ~p",  [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {_StartTime, _EndTime, Conditions} = ?sql_utils:cut(non_prefix, Payload),
    case ?gen_report:syn_ticket(Merchant, Conditions) of
	{ok, Merchant} ->
	    ?utils:respond(200, Req, ?succ(syn_score_ticket, Merchant));
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
		?w_retailer:get_ticket(by_batch, Merchant, Batch, UseCustomTicket);
	    ?TICKET_BY_SALE ->
		UseCustomTicket = ?v(<<"custom">>, Payload, ?SCORE_TICKET),
		SaleRsn = ?v(<<"sale">>, Payload),
		?w_retailer:get_ticket(by_sale, Merchant, SaleRsn, UseCustomTicket)
	end
    of 
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, ?to_tl(Value)}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_retailer_all_ticket"}, Payload) ->
    ?DEBUG("get_w_retailer_all-ticket:session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    RetailerId  = ?v(<<"retailer">>, Payload),
    ConsumeShop = ?v(<<"ishop">>, Payload),
    try
	{ok, ScoreTicket}     = ?w_retailer:get_ticket(by_retailer, Merchant, RetailerId),
	{ok, PromotionTickets} = ?w_retailer:get_ticket(
				    by_promotion, Merchant, {RetailerId, ConsumeShop}),
	%% ?DEBUG("PromotionTickets ~p", [PromotionTickets]),
	

	?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					   {<<"sticket">>, {ScoreTicket}},
					   {<<"pticket">>, PromotionTickets}]})
    catch
	_:{badmatch, {error, Error}} ->
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
    {struct, Conditions} = ?v(<<"condition">>, Payload),
    Batch = ?v(<<"batch">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 0),
    Active = ?v(<<"active">>, Payload, 0),

    case Batch of
	?TICKET_DISCARD_ONE ->
	    TicketId = ?v(<<"tid">>, Conditions),
	    case ?w_retailer:ticket(discard_custom_one, Merchant, TicketId, Mode) of
		{ok, TicketId} ->
		    ?utils:respond(200, Req, ?succ(discard_ticket_one, TicketId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	?TICKET_DISCARD_ALL ->
	    case ?v(<<"ticket_state">>, Conditions) of
		?TICKET_STATE_CONSUMED ->
		    ?utils:respond(200, Req, ?err(invalid_ticket_state, ?TICKET_STATE_CONSUMED));
		_ ->
		    case ?w_retailer:ticket(discard_custom_all, Merchant, Conditions, {Mode, Active}) of
			{ok, Merchant} ->
			    ?utils:respond(200, Req, ?succ(discard_ticket_all, Merchant));
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end
	    end
    end;

action(Session, Req, {"filter_custom_ticket_detail"}, Payload) ->
    ?DEBUG("filter_custom_ticket_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    Mode = ?v(<<"mode">>, Payload),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  {total_custom_ticket_detail, Mode}, ?to_a(Match),  Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  {custom_ticket_detail, Mode}, ?to_a(Match), Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"new_ticket_plan"}, Payload) ->
    ?DEBUG("new_ticket_plan with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:ticket(new_plan, Merchant, Payload) of
	{ok, Plan} ->
	    ?w_user_profile:update(ticket_plan, Merchant),
	    ?utils:respond(200, Req, ?succ(new_ticket_plan, Plan), {<<"id">>, Plan});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_ticket_plan"}, Payload) ->
    ?DEBUG("update_ticket_plan with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:ticket(update_plan, Merchant, Payload) of
	{ok, Plan} ->
	    ?w_user_profile:update(ticket_plan, Merchant),
	    ?utils:respond(200, Req, ?succ(new_ticket_plan, Plan));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"gift_ticket"}, Payload) ->
    ?DEBUG("gift_ticket: Session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 
    UTable = ?session:get(utable, Session),
    
    Tickets  = ?v(<<"ticket">>, Payload), 
    RetailerId      = ?v(<<"retailer">>, Payload),
    RetailerPhone   = ?v(<<"retailer_phone">>, Payload),
    RetailerName    = ?v(<<"retailer_name">>, Payload),
    Employee        = ?v(<<"employee">>, Payload, []),
    WithRSN         = ?v(<<"rsn">>, Payload, []),

    ShopId   = ?v(<<"shop">>, Payload),
    %% ShopName = ?v(<<"shop_name">>, Payload),

    GiftFun =
	fun() ->
		case ?w_retailer:ticket(
			gift,
			{Merchant, UTable},
			{ShopId, RetailerId, Tickets, WithRSN, Employee}) of
		    {ok, RetailerId, Balance, Count, MinEffect} ->
			%% send sms
			try 
			    {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),
			    SMSSetting = ?v(<<"recharge_sms">>, Setting, ?SMS_NOTIFY),
			    ?DEBUG("SMSSetting ~p", [SMSSetting]),
			    SysVips  = ?w_sale_request:sys_vip_of_shop(Merchant, ShopId), 
			    case not lists:member(RetailerId, SysVips)
				andalso ?utils:nth(3, SMSSetting) == 1 of
				true ->
				    {SMSCode, _} = 
					?notify:sms(
					   ticket,
					   {Merchant, ShopId, RetailerName, RetailerPhone},
					   {Balance, Count, MinEffect}),
				    ?utils:respond(
				       200, Req, ?succ(new_ticket_plan, RetailerId),
				       [{<<"sms_code">>, SMSCode}]);
				false ->
				    %% {0, none} 
				    ?utils:respond(
				       200, Req, ?succ(new_ticket_plan, RetailerId),
				       [{<<"sms_code">>, 0}])
			    end
			catch
			    _:{badmatch, _Error} ->
				?INFO("failed to send sms phone:~p, merchant ~p, Error ~p",
				      [RetailerPhone, Merchant, _Error]),

				Report = ["web request failed", _Error,
					  {trace, erlang:get_stacktrace()}],
				%% ?DEBUG("Request failed: ~p ", [Report]),
				?ERROR("Request failed: ~p", [Report]),
				
				?utils:respond(200, Req, ?err(sms_send_failed, Merchant))
			end;
		    {error, Error} ->
			?utils:respond(200, Req, Error)
		end
	end,
    
    case WithRSN of
	[] ->
	    GiftFun();
	_ ->
	    case ?w_sale:sale(get_new, {Merchant, UTable}, WithRSN) of
		{ok, SaleNew} ->
		    case ?v(<<"g_ticket">>, SaleNew) of
			?YES ->
			    ?utils:respond(200, Req, ?err(ticket_gifted, WithRSN));
			?NO ->
			    GiftFun()
		    end;
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

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
    ?DEBUG("add_w_retailer_score with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    case ?w_retailer:score(new, Merchant, Payload) of
	{ok, Id} ->
	    ?w_user_profile:update(score, Merchant),
	    ?utils:respond(200, Req, ?succ(add_retailer_score, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% gift
%%
action(Session, Req, {"add_w_gift"}, Payload) ->
    ?DEBUG("add_w_gift: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:gift(new, Merchant, Payload) of
	{ok, Id} ->
	    ?utils:respond(200, Req, ?succ(add_retailer_gift, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"modify_w_gift", Id}, Payload) ->
    ?DEBUG("modify_w_gift: session ~p, Id ~p, payload ~p", [Session, Id, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:gift(update, Merchant, Id, Payload) of
	{ok, Id} ->
	    ?utils:respond(200, Req, ?succ(add_retailer_gift, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_gift"}, Payload) ->
    ?DEBUG("list_w_gift: session ~p, payload ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_gift, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(gift,
				  Match,
				  Merchant,
				  Conditions,
				  CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"exchange_w_gift"}, Payload) ->
    ?DEBUG("exchange_w_gift: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:gift(exchange, Merchant, Payload) of
	{ok, Gift} ->
	    ?utils:respond(200, Req, ?succ(add_retailer_gift, Gift));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_gift_exchange"}, Payload) ->
    ?DEBUG("list_w_gift_exchange: session ~p, payload ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_gift_exchange, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(gift_exchange,
				  Match,
				  Merchant,
				  Conditions,
				  CurrentPage, ItemsPerPage)
       end, Req, Payload);

%%
%% export
%%
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
	    {ok, ExportFile, Url} = ?utils:create_export_file("retailer", Merchant, UserId),
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
    S4 = [{"wretailer_account", "会员帐户", "glyphicon glyphicon-piggy-bank"}], 

    Gift = [{"gift", "礼品详情", "glyphicon glyphicon-gift"}],
    GiftExchange = [{"gift_exchange", "兑换记录", "glyphicon glyphicon-bookmark"}], 

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
	  ++ case ?right_auth:authen(?list_ticket_plan, Session) of
		 {ok, ?list_ticket_plan} ->
		     [{"plan_custom_ticket", "优惠券方案", "glyphicon glyphicon-italic"}];
		 _ -> []
	     end
	 }],
    
    ThresholdCard = [{{"threshold_card", "次/月/季/年卡", "glyphicon glyphicon-credit-card" },
		      [{"card_detail",   "卡类详情", "glyphicon glyphicon-credit-card"},
		       {"card_good",     "按次商品", "glyphicon glyphicon-book"}, 
		       {"card_sale",     "消费记录", "glyphicon glyphicon-bookmark"}
		      ] 
		     }],

    Level = [{"level", "会员等级", "glyphicon glyphicon-sort-by-alphabet"}],
    Consume = [{"consume", "消费统计", "glyphicon glyphicon-usd"}],

    
    L1 = ?menu:sidebar(level_1_menu, S2 ++ S1 ++ S4 ++ S3 ++ Gift ++ GiftExchange),
    L2 = ?menu:sidebar(level_2_menu, Ticket ++ Recharge ++
			   case ?to_i(?v(<<"threshold_card">>, BaseSetting, ?NO)) of
			       ?YES -> ThresholdCard;
			       ?NO -> []
			   end),
    L1 ++ L2 ++ ?menu:sidebar(level_1_menu, Level) ++ ?menu:sidebar(level_1_menu, Consume).

csv_head(retailer, Do, Code) ->
    Head = "序号,名称,生日,类型,等级,联系方式,余额,累计消费,累计积分,所在店铺,日期",
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
    Birth   = ?v(<<"birth">>, H),
    Type    = retailer_type(?v(<<"type_id">>, H)),
    Level   = retailer_level(?v(<<"level">>, H)),
    Mobile  = ?v(<<"mobile">>, H, []),
    Balance = ?v(<<"balance">>, H, 0),
    Consume = ?v(<<"consume">>, H),
    Score   = ?v(<<"score">>, H),
    Shop    = ?v(<<"shop">>, H),
    Entry   = ?v(<<"entry_date">>, H),
    Comment = ?v(<<"comment">>, H),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Name) ++ ?d
	++ ?to_s(Birth) ++ ?d 
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Level) ++ ?d
	++ ?to_s(Mobile) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(Consume) ++ ?d
	++ ?to_s(Score) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Entry) ++ ?d
	++ ?to_s(Comment) ++ ?d,

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
    
    do_write(recharge, Do, Seq + 1, T, Code, {AccCBalance + CBalance,
					      AccSBalance + SBalance,
					      AccBalance + CurrentBalance}).

retailer_type(0) -> "普通会员";
retailer_type(1) -> "充值会员";
retailer_type(_) -> "未知类型".

retailer_level(0) -> "普通";
retailer_level(1) -> "金卡";
retailer_level(2) -> "白金";
retailer_level(3) -> "黑金";
retailer_level(_) -> "无".
    
		    
mode(0) -> use_id; 
mode(1) -> use_balance;
mode(2) -> use_consume;
mode(3) -> use_level.

sort_bank_card([], Acc) ->
    Acc;
sort_bank_card([Card|T], Acc) ->
    case ?v(<<"balance">>, Card) > 0 of
	true ->
	    case ?v(<<"type">>, Card) of
		1 ->
		    sort_bank_card(T, [Card|Acc]);
		_ ->
		    sort_bank_card(T, Acc ++ [Card])
	    end;
	false ->
	    sort_bank_card(T, Acc)
    end.
	    
draw_with_bank_card(_Cards, _Merchant, _ConsumeShop, _Pay, MaxDraw, CalcDraw, Acc) when MaxDraw =<0 ->
    {CalcDraw, Acc};
draw_with_bank_card([], _Merchant, _ConsumeShop, _Pay, _MaxDraw, CalcDraw, Acc) ->
    {CalcDraw, Acc};
draw_with_bank_card([Card|T], Merchant, ConsumeShop, Pay, MaxDraw, CalcDraw,Acc) ->
    ChargeId = ?v(<<"charge_id">>, Card),
    BankCardId = ?v(<<"id">>, Card),
    ChargeShop = ?v(<<"shop_id">>, Card),
    CardBalance = ?v(<<"balance">>, Card),
    CardType  = ?v(<<"type">>, Card),
    case ?w_retailer:charge(get_charge, Merchant, ChargeId) of
	{ok, []} ->
	    draw_with_bank_card(T, Merchant, ConsumeShop, Pay, MaxDraw, CalcDraw, Acc);
	{ok, ChargePromotion} ->
	    LimitShop        = ?v(<<"ishop">>, ChargePromotion),
	    %% ?DEBUG("limitShop ~p, consumeShop ~p, chargeShop ~p",
	    %% 	   [LimitShop, ConsumeShop, ChargeShop]),
	    LimitBalance     = ?v(<<"ibalance">>, ChargePromotion, ?INVALID_OR_EMPTY),
	    ThresholdBalance = ?v(<<"mbalance">>, ChargePromotion),
	    case LimitShop =:= ?YES andalso same_shop(ConsumeShop, ChargeShop) =:= ?NO of
		true ->
		    draw_with_bank_card(T, Merchant, ConsumeShop, Pay, MaxDraw, CalcDraw, Acc);
		false ->
		    case LimitBalance =/= ?INVALID_OR_EMPTY andalso LimitBalance =/= 0 of
			true ->
			    LimitDraw = ?utils:min_value(
					   CardBalance, Pay div ThresholdBalance * LimitBalance),
			    CanDraw = ?utils:min_value(LimitDraw, MaxDraw),
			    draw_with_bank_card(
			      T,
			      Merchant,
			      ConsumeShop,
			      Pay,
			      MaxDraw - CanDraw,
			      CalcDraw + CanDraw,
			      [{BankCardId,
				CanDraw,
				CardBalance,
				CardType,
				same_shop(ConsumeShop, ChargeShop),
				LimitShop,
				ChargeShop}|Acc]);
			false ->
			    LimitCount = ?v(<<"icount">>, ChargePromotion),
			    case LimitCount =/= ?INVALID_OR_EMPTY andalso LimitCount =/= 0 of
				true ->
				    %% ?DEBUG("ChargePromotion ~p", [ChargePromotion]),
				    CBalance     = ?v(<<"charge">>, ChargePromotion),
				    SBalance     = ?v(<<"balance">>, ChargePromotion),
				    OneTakeBalance = ?utils:min_value(
							CardBalance,
							(CBalance + SBalance) div LimitCount),
				    CanDraw = ?utils:min_value(OneTakeBalance, MaxDraw),
				    draw_with_bank_card(
				      T,
				      Merchant,
				      ConsumeShop,
				      Pay,
				      MaxDraw - CanDraw,
				      CalcDraw + CanDraw,
				      [{BankCardId,
					CanDraw,
					CardBalance,
					CardType,
					same_shop(ConsumeShop, ChargeShop),
					LimitShop,
					ChargeShop}|Acc]); 
				false ->
				    CanDraw = ?utils:min_value(CardBalance, MaxDraw),
				    draw_with_bank_card(
				      T,
				      Merchant,
				      ConsumeShop,
				      Pay,
				      MaxDraw - CanDraw,
				      CalcDraw + CanDraw,
				      [{BankCardId,
					CanDraw,
					CardBalance,
					CardType,
					same_shop(ConsumeShop, ChargeShop),
					LimitShop,
					ChargeShop}|Acc])
			    end
		    end
	    end
    end.
			    
same_shop(S1, S2) when S1=:=S2 -> ?YES;
same_shop(_S1, _S2) -> ?NO.
    
