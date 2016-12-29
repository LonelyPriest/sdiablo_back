-module(diablo_w_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

-define(d, ?utils:seperator(csv)).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    %% ?DEBUG("login with client ip:~n ~p", [Req:get(peer)]),
    {ok, HTMLOutput} = wsale_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wsaleApp"},
			  {ngcontroller, "wsaleCtrl"}
			  %% {baseapp, "baseApp"},
			  %% {basectrl, "baseCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

action(Session, Req, {"get_w_print_content", RSN}) ->
    ?DEBUG("get_w_print_content with session ~p, rsn ~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session),
    try
	{ok, Sale}     = ?w_sale:sale(get_new, Merchant, RSN),
	{ok, Employee} = ?w_user_profile:get(
			    employee, Merchant, ?v(<<"employ_id">>, Sale)),
	{ok, Retailer} = ?w_user_profile:get(
			    retailer, Merchant, ?v(<<"retailer_id">>, Sale)),

	{ok, Details} = ?w_sale:sale(
			   trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	
	{ok, MerchantInfo} = ?w_user_profile:get(merchant, Merchant),
	{ok, Banks} = ?w_user_profile:get(bank, Merchant),

	ShopId = ?v(<<"shop_id">>, Sale),
	{ok, PSetting} = ?w_user_profile:get(setting, Merchant, ShopId), 
	{ok, PFormat}  = ?w_user_profile:get(print_format, Merchant, ShopId), 
	{ok, ShopInfo} = ?w_user_profile:get(shop, Merchant, ShopId),

	?utils:respond(
	   200, object, Req,
	   {[{<<"ecode">>, 0},
	     {<<"sale">>, {[{<<"employee">>, ?v(<<"name">>, Employee)},
			    {<<"retailer">>, ?v(<<"name">>, Retailer)}
			    |Sale]}},
	     {<<"detail">>, Details},
	     {<<"psetting">>, PSetting},
	     {<<"merchant">>, {MerchantInfo}},
	     {<<"banks">>, Banks},
	     {<<"pformat">>, PFormat},
	     {<<"shop">>, ShopInfo}
	    ]})
    catch
	_:{badmatch, {error, Error}} ->
	    ?utils:respond(200, Req, Error)
    end;
	    
action(Session, Req, {"get_w_sale_new", RSN}) ->
    ?DEBUG("get_w_sale_new with session ~p, paylaod~n~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session),
    try
	{ok, Sale} = ?w_sale:sale(get_new, Merchant, RSN),
	%% ?DEBUG("sale ~p", [Sale]),
	{ok, Details} = ?w_sale:sale(
			   trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	?DEBUG("details ~p", [Details]),

	{ok, TicketScore} =
	    case ?v(<<"tbatch">>, Sale) of
		-1 -> {ok, 0};
		TicketBatch ->
		    {ok, Ticket} = ?w_retailer:get_ticket(by_batch, Merchant, {TicketBatch, 1}),
		    case ?v(<<"sid">>, Ticket) of
			-1 -> {ok, 0};
			TicketSId ->
			    {ok, Scores} = ?w_user_profile:get(score, Merchant),
			    case lists:filter(
				   fun({S})->
					   ?v(<<"type_id">>, S) =:= 1
					       andalso ?v(<<"id">>, S) =:= TicketSId end, Scores) of
				[] -> throw({wsale_invalid_ticket_score, TicketBatch}) ;
				[{Score2Money}] ->

				    AccScore = ?v(<<"score">>, Score2Money), 
				    Balance = ?v(<<"balance">>, Score2Money),
				    TicketBalance = ?v(<<"balance">>, Ticket),
				    case ?w_sale:direct(?v(<<"type">>, Sale)) of
					wreject -> {ok, -TicketBalance div Balance * AccScore};
					_ -> {ok, TicketBalance div Balance * AccScore}
				    end
			    end
		    end
	    end,
	
	%% sort by style_number and brand
	%% ShopId = ?v(<<"shop_id">>, Sale),

	%% {ok, [{Shop}]} = ?w_user_profile:get(shop, Merchant, ShopId),

	%% RealShop = 
	%%     case ?v(<<"repo">>, Shop) of
	%% 	-1 -> ShopId;
	%% 	RepoId -> RepoId
	%%     end, 
	
	%% Goods = lists:foldr(
	%% 	  fun({D}, Acc) ->
	%% 		  S =  {?v(<<"style_number">>, D),
	%% 			?v(<<"brand_id">>, D)},
	%% 		  case lists:member(S, Acc) of
	%% 		      true -> Acc;
	%% 		      false -> [S|Acc]
	%% 		  end
	%% 	  end, [], Details),

	%% {ok, Abstracts}
	%%     = case Goods of
	%% 	  [] -> {ok, []};
	%% 	  _ -> ?w_inventory:purchaser_inventory(
	%% 		  abstract, Merchant, RealShop, Goods)
	%%       end,

	?utils:respond(
	   200, object, Req,
	   {[{<<"ecode">>, 0},
	     {<<"sale">>, {Sale ++ [{<<"ticket_score">>, TicketScore}]}},
	     {<<"detail">>, Details}
	     %% {<<"inv">>, Abstracts}
	    ]}) 
    catch
	_:{badmatch, {error, Error}} ->
	    ?utils:respond(200, Req, Error)
    end; 
    
action(Session, _Req, Action) ->
    ?DEBUG("receive unkown action ~p with session ~p", [Action, Session]).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"list_w_sale_new"}, Payload) ->
    ?DEBUG("list_w_sale_new with session ~p, paylaod~n~p",
	   [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    batch_responed(
      fun() -> ?w_sale:sale(list_new, Merchant, Payload) end, Req); 

action(Session, Req, {"get_last_sale"}, Payload) ->
    ?DEBUG("get_last_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),

    case ?w_sale:sale(last, Merchant, Payload) of
	{ok, Last} ->
	    ?utils:respond(200, batch, Req, {Last});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_sale_new"}, Payload) ->
    ?DEBUG("filter_w_sale_new with session ~p, paylaod~n~p",
	   [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_sale:filter(total_news, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_sale:filter(
		  news,
		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_w_sale_image"}, Payload) ->
    ?DEBUG("filter_w_sale_image with session ~p, payload~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% inventory
    {struct, F} = ?v(<<"fields">>, Payload),
    NewPayload = [{<<"fields">>,
		   {struct, proplists:delete(<<"retailer">>, F)}},
		  {<<"page">>, ?v(<<"page">>, Payload)},
		  {<<"count">>, ?v(<<"count">>, Payload)}],
    Result = 
	?pagination:pagination(
	   no_response,
	   fun(Match, Conditions) ->
		   ?w_inventory:filter(
		      total_groups, Match, Merchant, Conditions)
	   end,
	   fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
		   ?w_inventory:filter(
		      groups,
		      Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
	   end, NewPayload),

    case Result of
	{ok, Total, []} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0}, {<<"total">>, Total}, {<<"data">>, []}]});
	{ok, Total, Data} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0},
		 {<<"total">>, Total},
		 {<<"data">>, Data},
		 {<<"history">>, []}]}); 
	    %% view history of the retailer
	    %% Retailer = ?v(<<"retailer">>, F),
	    %% Goods = lists:foldr(
	    %% 	      fun({Good}, Acc) ->
	    %% 		      [{?v(<<"style_number">>, Good),
	    %% 			?v(<<"brand_id">>, Good)}|Acc]
	    %% 	      end, [], Data),
	    
	    %% case ?w_sale:sale(history_retailer, Merchant, Retailer, Goods) of 
	    %% 	{ok, Histories} ->
	    %% 	    ?utils:respond(
	    %% 	       200, object, Req,
	    %% 	       {[{<<"ecode">>, 0},
	    %% 		 {<<"total">>, Total},
	    %% 		 {<<"data">>, Data},
	    %% 		 {<<"history">>, Histories}]}); 
	    %% 	{error, _Error} ->
	    %% 	    ?utils:respond(200, Req, ?err(wsale_history_failed, Retailer))
	    %% end;
	    
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_sale"}, Payload) ->
    ?DEBUG("new_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    {struct, Print} = ?v(<<"print">>, Payload),

    %% Shop = ?v(<<"shop">>, Base, -1),
    %% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, Shop),
    
    %% ImmediatelyPrint = ?v(<<"im_print">>, Print, ?NO),
    %% PMode            = ?v(<<"p_mode">>, Print, ?PRINT_FRONTE),
    %% Round            = ?v(<<"round">>, Base, 1),
    %% ShouldPay        = ?v(<<"should_pay">>, Base),
    
    TicketBatch      = ?v(<<"ticket_batch">>, Base),
    TicketBalance    = ?v(<<"ticket">>, Base),
    
    case TicketBatch =/= undefined andalso TicketBalance =/= undefined of
	true ->
	    {ok, Ticket} = ?w_retailer:get_ticket(by_batch, Merchant, TicketBatch), 
	    case Ticket of
		[] ->
		    ?utils:respond(200, Req, ?err(ticket_not_exist, TicketBatch));
		_ ->
		    TicketSId = ?v(<<"sid">>, Ticket),
		    case TicketSId of
			-1 ->
			    start(new_sale, Req, Merchant, Invs, Base, Print);
			_ ->
			    {ok, Scores} = ?w_user_profile:get(score, Merchant), 
			    case lists:filter(
				   fun({S})->
					   ?v(<<"type_id">>, S) =:= 1
					       andalso ?v(<<"id">>, S) =:= TicketSId end, Scores) of
				[] ->
				    ?utils:respond(
				       200, Req, ?err(wsale_invalid_ticket_score, TicketSId));
				[{Score2Money}] ->
				    case TicketBalance /= ?v(<<"balance">>, Ticket) of
					true ->
					    ?utils:respond(
					       200,
					       Req,
					       ?err(wsale_invalid_ticket_balance, TicketBalance));
					false ->
					    AccScore = ?v(<<"score">>, Score2Money), 
					    Balance = ?v(<<"balance">>, Score2Money),
					    TicketScore =TicketBalance div Balance * AccScore,
					    start(
					      new_sale,
					      Req,
					      Merchant,
					      Invs,
					      Base ++ [{<<"ticket_score">>, TicketScore}],
					      Print)
				    end
			    end
		    end
	    end;
	false ->
	    start(new_sale, Req, Merchant, Invs, Base, Print)
    end;
	
    %% check invs
    %% case check_inventory(oncheck, Round, 0, ShouldPay, Invs) of
    %%     {ok, _} -> 
    %% 	    case ?w_sale:sale(new, Merchant, lists:reverse(Invs), Base) of 
    %% 		{ok, RSN} ->
    %% 		    case ImmediatelyPrint =:= ?YES andalso PMode =:= ?PRINT_BACKEND of
    %% 			true ->
    %% 			    SuccessRespone =
    %% 				fun(PCode, PInfo) ->
    %% 					?utils:respond(
    %% 					   200, Req, ?succ(new_w_sale, RSN),
    %% 					   [{<<"rsn">>, ?to_b(RSN)},
    %% 					    {<<"pcode">>, PCode},
    %% 					    {<<"pinfo">>, PInfo}])
    %% 				end,

    %% 			    NewInvs =
    %% 				lists:foldr(
    %% 				  fun({struct, Inv}, Acc) ->
    %% 					  StyleNumber = ?v(<<"style_number">>, Inv),
    %% 					  BrandId     = ?v(<<"brand">>, Inv),
    %% 					  Total       = ?v(<<"sell_total">>, Inv),
    %% 					  TagPrice    = ?v(<<"tag_price">>, Inv),
    %% 					  RPrice      = ?v(<<"rprice">>, Inv),

    %% 					  P = [{<<"style_number">>, StyleNumber},
    %% 					       {<<"brand_id">>, BrandId},
    %% 					       {<<"tag_price">>, TagPrice},
    %% 					       {<<"rprice">>, RPrice},
    %% 					       {<<"total">>, Total}
    %% 					      ],

    %% 					  [P|Acc] 
    %% 				  end, [], Invs),
    %% 			    print(RSN, Merchant, NewInvs, Base, Print, SuccessRespone);
    %% 			false ->
    %% 			    ?utils:respond(
    %% 			       200, Req, ?succ(new_w_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}])
    %% 		    end,
    %% 		    ?w_user_profile:update(retailer, Merchant); 
    %% 		{error, Error} ->
    %% 		    ?utils:respond(200, Req, Error)
    %% 	    end;
    %% 	{error, EInv} ->
    %%         StyleNumber = ?v(<<"style_number">>, EInv),
    %% 	    ?utils:respond(
    %%            200,
    %%            Req,
    %%            ?err(wsale_invalid_inv, StyleNumber),
    %%            [{<<"style_number">>, StyleNumber},
    %%             {<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
    %% 	{error, Moneny, ShouldPay} ->
    %%         ?utils:respond(
    %%            200,
    %%            Req,
    %%            ?err(wsale_invalid_pay, Moneny))
    %% end;

action(Session, Req, {"update_w_sale"}, Payload) ->
    ?DEBUG("update_w_sale with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    RSN             = ?v(<<"rsn">>, Base),

     
    case ?w_sale:sale(get_new, Merchant, RSN) of
	{ok, OldBase} -> 
	    case ?w_sale:sale(update, Merchant, lists:reverse(Invs), {Base, OldBase}) of
		{ok, RSN} -> 
		    ?utils:respond(
		       200, Req, ?succ(update_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_sale"}, Payload) ->
    ?DEBUG("chekc_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?CHECK),

    case ?w_sale:sale(check, Merchant, RSN, Mode) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req, ?succ(check_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;
    
    
action(Session, Req, {"print_w_sale"}, Payload) ->
    ?DEBUG("print_w_sale with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN      = ?v(<<"rsn">>, Payload),
    try
	{ok, Sale} = ?w_sale:sale(get_new, Merchant, RSN),
	?DEBUG("sale ~p", [Sale]),
	{ok, SaleDetails} =
	    ?w_sale:sale(trans_detail, Merchant, {<<"rsn">>, ?to_b(RSN)}),
	?DEBUG("details ~p", [SaleDetails]), 

	{ok, TicketScore} = 
	    case ?v(<<"tbatch">>, Sale) of
		-1 -> {ok, 0};
		TicketBatch ->
		    {ok, Ticket} = ?w_retailer:get_ticket(by_batch, Merchant, {TicketBatch, 1}),
		    case ?v(<<"sid">>, Ticket) of
			-1 -> {ok, 0};
			TicketSId ->
			    {ok, Scores} = ?w_user_profile:get(score, Merchant),
			    case lists:filter(
				   fun({S})->
					   ?v(<<"type_id">>, S) =:= 1
					       andalso ?v(<<"id">>, S) =:= TicketSId end, Scores) of
				[] -> throw({wsale_invalid_ticket_score, TicketBatch}) ;
				[{Score2Money}] ->
				    
				    AccScore = ?v(<<"score">>, Score2Money), 
				    Balance = ?v(<<"balance">>, Score2Money),
				    TicketBalance = ?v(<<"balance">>, Ticket),
				    case ?w_sale:direct(?v(<<"type">>, Sale)) of
					wreject -> {ok, -TicketBalance div Balance * AccScore};
					_ ->{ ok, -TicketBalance div Balance * AccScore}
				    end
			    end
		    end
	    end,
	
	%% {ok, Details} = ?w_sale:rsn_detail(rsn, Merchant, {<<"rsn">>, RSN}),

	CombineInvs = combine_inv(SaleDetails, []),
	?DEBUG("combineinvs ~p", [CombineInvs]),

	%% {ok, Retailer} = ?w_user_profile:get(
	%% 		    retailer, Merchant, ?v(<<"retailer_id">>, Sale)),
	
	{ok, Employee} = ?w_user_profile:get(
			    employee, Merchant, ?v(<<"employ_id">>, Sale)),
	{ok, Brands}   = ?w_user_profile:get(brand, Merchant),

	GetBrand =
	    fun(BrandId)->
		    case ?w_user_profile:filter(Brands, <<"id">>, BrandId) of
			[] -> [];
			FindBrand -> ?v(<<"name">>, FindBrand)
		    end
	    end,
	    
	%% SortInvs = sort_inventory(Merchant, GetBrand, Details, []),
	%% ?DEBUG("sorts ~p", [SortInvs]),
	RSNAttrs = [{<<"shop">>,       ?v(<<"shop_id">>, Sale)},
		    {<<"datetime">>,   ?v(<<"entry_date">>, Sale)},
		    {<<"balance">>,    ?v(<<"balance">>, Sale)},
		    {<<"cash">>,       ?v(<<"cash">>, Sale)},
		    {<<"card">>,       ?v(<<"card">>, Sale)},
		    {<<"wxin">>,       ?v(<<"wxin">>, Sale)},
		    {<<"withdraw">>,   ?v(<<"withdraw">>, Sale)},
		    {<<"ticket">>,     ?v(<<"ticket">>, Sale)},
		    {<<"ticket_score">>, TicketScore},
		    {<<"verificate">>, ?v(<<"verificate">>, Sale)},
		    {<<"should_pay">>, ?v(<<"should_pay">>, Sale)}, 
		    {<<"total">>,      ?v(<<"total">>, Sale)},
		    {<<"last_score">>, ?v(<<"lscore">>, Sale)},
		    {<<"score">>,      ?v(<<"score">>, Sale)},
		    {<<"comment">>,    ?v(<<"comment">>, Sale)}, 
		    {<<"direct">>,     ?v(<<"type">>, Sale)},
		    {<<"im_print">>,   false}],

	
	%% ?DEBUG("retailer ~p", [Retailer]),
	%% ?DEBUG("employee ~p", [Employee]),
	PrintAttrs = [
		      %% {<<"retailer">>, ?v(<<"name">>, Retailer)},
		      {<<"retailer_id">>, ?v(<<"retailer_id">>, Sale)},
		      {<<"employ">>, ?v(<<"name">>, Employee)}], 

	SuccessRespone =
	    fun(PCode, PInfo) ->
		    ?utils:respond(200, Req, ?succ(print_w_sale, RSN),
		       [{<<"rsn">>, ?to_b(RSN)},
			{<<"pcode">>, PCode},
			{<<"pinfo">>, PInfo}])
	    end,

	print(RSN, Merchant, CombineInvs, RSNAttrs, PrintAttrs, SuccessRespone)
	
	%% ?utils:respond(
	%%    200, Req, ?succ(print_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)}) 
    catch
	_:{wsale_invalid_ticket_score, TBatch} ->
	    ?utils:respond(200, Req, ?err(wsale_invalid_ticket_score, TBatch));
	_:{badmatch, {error, Error}} ->
	    ?utils:respond(200, Req, Error)
    end;

%% =============================================================================
%% reject
%% =============================================================================
action(Session, Req, {"reject_w_sale"}, Payload) ->
    ?DEBUG("reject_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base}   = ?v(<<"base">>, Payload),
    %% {struct, Print}  = ?v(<<"print">>, Payload),
    %% ImmediatelyPrint = ?v(<<"im_print">>, Print, ?YES),
    case ?w_sale:sale(reject, Merchant, lists:reverse(Invs), Base) of 
    	{ok, RSN} ->
	    %% case ImmediatelyPrint of
	    %% 	?YES ->
	    %% 	    SuccessRespone =
	    %% 		fun(PCode, PInfo) ->
	    %% 			?utils:respond(
	    %% 			   200, Req, ?succ(reject_w_sale, RSN),
	    %% 			   [{<<"rsn">>, ?to_b(RSN)},
	    %% 			    {<<"pcode">>, PCode},
	    %% 			    {<<"pinfo">>, PInfo}])
	    %% 		end,
		    
	    %% 	    print(RSN, Merchant, Invs, Base, Print, SuccessRespone);
	    %% 	?NO ->
	    %% 	    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
	    %% 			   [{<<"rsn">>, ?to_b(RSN)}])
	    %% end;
	    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
			   [{<<"rsn">>, ?to_b(RSN)}]);
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_sale_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_sale_rsn_group with session ~p, paylaod~n~p",
	   [Session, Payload]), 
    Merchant           = ?session:get(merchant, Session),
    
    %% first, get rsn
    %% {struct, NewConditions} = ?v(<<"fields">>, Payload), 
    
    %% {ok, Q} = ?w_sale:sale(get_rsn, Merchant, NewConditions),
    %% FilterConditions =
    %% 	?w_inventory_request:filter_condition(
    %% 	  trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], NewConditions),
    
    %% case FilterConditions of
    %% 	    [] -> ?utils:respond(
    %% 		     200, object, Req, {[{<<"ecode">>, 0},
    %% 					 {<<"total">>, 0},
    %% 					 {<<"data">>, []}]});
    %% 	_ -> 
    %% 	    NewPayload = FilterConditions ++ proplists:delete(<<"fields">>, Payload), 
    
    %% 	    ?pagination:pagination(
    %% 	       fun(Match, Conditions) ->
    %% 		       ?w_sale:filter(total_rsn_group, ?to_a(Match), Merchant, Conditions)
    %% 	       end,
    %% 	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    %% 		       ?w_sale:filter(
    %% 			  rsn_group, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
    %% 	       end, Req, NewPayload)
    %% end;

    {struct, Mode}     = ?v(<<"mode">>, Payload),
    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode), 
    NewPayload = proplists:delete(<<"mode">>, Payload),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
    	       ?w_sale:filter(total_rsn_group,
    			      ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    	       ?w_sale:filter(
		  {rsn_group, mode(Order), Sort},
    		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, NewPayload);

action(Session, Req, {"w_sale_rsn_detail"}, Payload) ->
    ?DEBUG("w_sale_rsn_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_sale:rsn_detail(rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"w_sale_export"}, Payload) ->
    ?DEBUG("w_sale_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),
    
    {struct, Conditions} = ?v(<<"condition">>, Payload),


    NewConditions = 
	case ExportType of
	    trans_note ->
		{struct, CutConditions} = ?v(<<"condition">>, Payload),
		{ok, Q} = ?w_sale:sale(get_rsn, Merchant, CutConditions),
		{struct, C} =
		    ?v(<<"fields">>,
		       ?w_inventory_request:filter_condition(
			  trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q],
			  CutConditions)),
		C;
	    trans -> Conditions
	end,
	    
    
    case ?w_sale:export(ExportType, Merchant, NewConditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_no_date, Merchant));
	{ok, Transes} -> 
	    %% write to file 
	    {ok, ExportFile, Url} =
		?utils:create_export_file("otrans", Merchant, UserId), 
	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} -> 
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(ExportType, DoFun),
			do_write(ExportType, DoFun, 1, Transes),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p",
				   [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(
			       200, Req, ?err(wsale_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wsale_export_error, Error))
	    end; 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_wsale_rsn"}, Payload) ->
    ?DEBUG("get_wsale_rsn with session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(
      fun() -> ?w_sale:sale(
		  get_rsn, Merchant, [{<<"sell_type">>, 0}|Payload]) end, Req).

sidebar(Session) -> 
    case ?right_request:get_shops(Session, sale) of
	[] ->
	    ?menu:sidebar(level_2_menu, []);
	Shops ->
	    WSale = ?w_inventory_request:authen_shop_action(
		       {?new_w_sale,
			"new_wsale",
			"销售开单", "glyphicon glyphicon-usd"}, Shops), 

	    WReject = ?w_inventory_request:authen_shop_action(
			 {?reject_w_sale,
			  "reject_wsale",
			  "销售退货",
			  "glyphicon glyphicon-arrow-left"}, Shops), 

	    SaleR =
		[{"new_wsale_detail",
		  "交易记录", "glyphicon glyphicon-bookmark"}],
	    
	    SaleD =
		[{"wsale_rsn_detail",
		  "交易明细", "glyphicon glyphicon-map-marker"}],

	    L1 = ?menu:sidebar(
		    level_1_menu, WSale ++ WReject ++ SaleR ++ SaleD),
	    
	    L1
		
    end. 

%% =============================================================================
%% internal
%% =============================================================================
combine_inv([], Acc) ->
    Acc;
combine_inv([{Inv}|T], Acc) ->
    S = ?v(<<"style_number">>, Inv),
    B = ?v(<<"brand_id">>, Inv),
    Amount   = ?v(<<"amount">>, Inv),
    
    case in_sort(Inv, Acc) of
	true ->
	    NewAcc = 
		lists:foldr(
		  fun({A}, Acc1) ->
			  S1 = ?v(<<"style_number">>, A),
			  B1 = ?v(<<"brand_id">>, A),
			  TagPrice = ?v(<<"tag_price">>, A),
			  RPrice   = ?v(<<"rprice">>, A),
			  Amount1  = ?v(<<"amount">>, A),

			  case S =:= S1 andalso B =:= B1 of
			      true ->
				  [{[{<<"style_number">>, S1},
				     {<<"brand_id">>, B1},
				     {<<"tag_price">>, TagPrice},
				     {<<"rprice">>, RPrice},
				     {<<"total">>, Amount + Amount1}
				    ]}|Acc1];
			      false ->
				  [{A}|Acc1]
			  end
		  end, [], Acc),
	    combine_inv(T, NewAcc);
	false ->
	    combine_inv(T, [{Inv}|Acc])
    end.

in_sort(_In, []) ->
    false;
in_sort(In, [{TInv}|T]) ->
    S = ?v(<<"style_number">>, In),
    B = ?v(<<"brand_id">>, In),

    S1 = ?v(<<"style_number">>, TInv),
    B1 = ?v(<<"brand_id">>, TInv),

    case S =:= S1 andalso B =:= B1 of
	true -> true;
	false -> in_sort(In, T)
    end.
	    
    
print(RSN, Merchant, Invs, Attrs, PrintAttrs, ResponseFun) ->
    try ?wifi_print:print(RSN, Merchant, Invs, Attrs, PrintAttrs) of	
	{Success, []} ->
	    ResponseFun(0, Success); 
	{[], Failed} ->
	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
		     || {DeviceId, ECode} <- Failed],
	    ResponseFun(1, PInfo); 
	{_Success, Failed} when is_list(Failed)->
	    PInfo = [{[{<<"device">>, DeviceId}, {<<"ecode">>, ECode}]}
		     || {DeviceId, ECode} <- Failed],
	    ResponseFun(2, PInfo);
	{error, {ECode, _EInfo}} ->
	    ResponseFun(ECode, [])
    catch
	EType:What ->
	    %% ?INFO("failed to print ~p", [What]),
	    Report = ["print failed...",
		      {type, EType}, {what, What},
		      {trace, erlang:get_stacktrace()}],
	    ?ERROR("print failed: ~p", [Report]),
	    {ECode, _} = ?err(print_unkown_error, RSN),
	    ResponseFun(ECode, [])
    end.

batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

csv_head(trans, Do) ->
    Do("序号,单号,交易类型,门店,店员,客户,数量,现金,刷卡,汇款,核销,费用,帐户欠款,应付,实付,本次欠款,备注,开单日期");
csv_head(trans_note, Do) ->
    Do("序号,单号,交易类型,门店,店员,客户,款号,品牌,类型,厂商,单价,折扣,数量,小计,备注,日期").


do_write(trans, _Do, _Count, [])->
    ok;
do_write(trans, Do, Count, [H|T]) ->
    Rsn       = ?v(<<"rsn">>, H),
    Type      = ?v(<<"type">>, H),
    Shop      = ?v(<<"shop">>, H),
    Employee  = ?v(<<"employee">>, H),
    Retailer  = ?v(<<"retailer">>, H), 
    Total     = ?v(<<"total">>, H),
    Cash      = ?v(<<"cash">>, H),
    Card      = ?v(<<"card">>, H),
    Wire      = ?v(<<"wire">>, H),
    Verify    = ?v(<<"verificate">>, H),
    EPay      = ?v(<<"e_pay">>, H),
    LBalance  = ?to_f(?v(<<"balance">>, H)),
    ShouldPay = ?v(<<"should_pay">>, H),
    HasPay    = ?v(<<"has_pay">>, H), 
    Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),

    CBalance  = ?to_f(LBalance + ShouldPay + EPay - HasPay),
    %% ?DEBUG("CBalance ~p", [CBalance]),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(Type) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(Total) ++ ?d
	++ ?to_s(Cash) ++ ?d
	++ ?to_s(Card) ++ ?d 
	++ ?to_s(Wire) ++ ?d
	++ ?to_s(Verify) ++ ?d
	++ ?to_s(EPay) ++ ?d
	++ ?to_s(LBalance) ++ ?d
	++ ?to_s(ShouldPay) ++ ?d
	++ ?to_s(HasPay) ++ ?d
	++ ?to_s(CBalance) ++ ?d
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
	%% ++ ?to_s(Date),
    Do(L),
    do_write(trans, Do, Count + 1, T);

do_write(trans_note, _Do, _Count, [])->
    ok;
do_write(trans_note, Do, Count, [H|T]) ->
    Rsn         = ?v(<<"rsn">>, H),
    SType        = ?v(<<"sell_type">>, H),
    Shop        = ?v(<<"shop">>, H),
    Employee    = ?v(<<"employee">>, H),
    Retailer    = ?v(<<"retailer">>, H),
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Firm        = ?v(<<"firm">>, H),
    %% Color       = ?v(<<"color">>, H),
    %% Size        = ?v(<<"size">>, H),
    FDiscount   = ?v(<<"fdiscount">>, H),
    FPrice      = ?v(<<"fprice">>, H),
    Total       = ?v(<<"total">>, H),

    %% ?DEBUG("FDiscount ~p, FPrice ~p, Total ~p, rsn ~p", [FDiscount, FPrice, Total, Rsn]),
    Calc        = ?to_f(case FDiscount of
			    <<>> -> 100;
			    _ -> FDiscount
			end * FPrice * Total * 0.01), 
    Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),
    
    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(SType) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(StyleNumber) ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Firm) ++ ?d
	%% ++ ?to_s(Color) ++ ?d
	%% ++ ?to_s(Size) ++ ?d
	++ ?to_s(FPrice) ++ ?d 
	++ ?to_s(FDiscount) ++ ?d
	++ ?to_s(Total) ++ ?d
	++ ?to_s(Calc) ++ ?d 
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
    %% ++ ?to_s(Date),
    Do(L),
    do_write(trans_note, Do, Count + 1, T).
    
sale_type(0) -> "开单";
sale_type(1)-> "退货".

export_type(0) -> trans;
export_type(1) -> trans_note.

%% inventory(check_style_number, []) ->
%%     ok;
%% inventory(check_style_number, [{struct, Inv}|T]) ->
%%     case ?v(<<"style_number">>, Inv) of
%% 	undefined -> throw({invalid_balance});
%% 	_ -> inventory(check_style_number, T)
%%     end.

start(new_sale, Req, Merchant, Invs, Base, Print) ->
    ImmediatelyPrint = ?v(<<"im_print">>, Print, ?NO),
    PMode            = ?v(<<"p_mode">>, Print, ?PRINT_FRONTE),
    Round            = ?v(<<"round">>, Base, 1),
    ShouldPay        = ?v(<<"should_pay">>, Base),
    
    case check_inventory(oncheck, Round, 0, ShouldPay, Invs) of
        {ok, _} -> 
	    case ?w_sale:sale(new, Merchant, lists:reverse(Invs), Base) of 
		{ok, {RSN, Phone, _ShouldPay, Balance, Score}} ->
		    {SMSCode, _} =
			try
			    {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),
			    RetailerId   = ?v(<<"retailer">>, Base),
			    ShopId = ?v(<<"shop">>, Base), 
			    SysVips = sys_vip_of_shop(Merchant, ShopId), 
			    ?DEBUG("SysVips ~p", [SysVips]),
			    case not lists:member(RetailerId, SysVips)
				andalso ?to_i(?v(<<"consume_sms">>, Setting, 0)) == 1 of
				true ->
				    ShopName = case ?w_user_profile:get(
						       shop, Merchant, ShopId) of
						   {ok, []} -> ShopId;
						   {ok, [{Shop}]} -> ?v(<<"name">>, Shop)
					       end,
				    ?notify:sms_notify(
				       Merchant,
				       {ShopName, Phone, 1, ShouldPay, Balance, Score});
				false -> {0, none} 
			    end
			catch
			    _:{badmatch, _Error} ->
				?INFO("failed to send sms phone:~p, merchant ~p, Error ~p",
				      [Phone, Merchant, _Error]),
				?err(sms_send_failed, Merchant)
			end,
			
		    case ImmediatelyPrint =:= ?YES andalso PMode =:= ?PRINT_BACKEND of
			true ->
			    SuccessRespone =
				fun(PCode, PInfo) ->
					?utils:respond(
					   200, Req, ?succ(new_w_sale, RSN),
					   [{<<"rsn">>, ?to_b(RSN)},
					    {<<"sms_code">>, SMSCode},
					    {<<"pcode">>, PCode},
					    {<<"pinfo">>, PInfo}])
				end,

			    NewInvs =
				lists:foldr(
				  fun({struct, Inv}, Acc) ->
					  StyleNumber = ?v(<<"style_number">>, Inv),
					  BrandId     = ?v(<<"brand">>, Inv),
					  Total       = ?v(<<"sell_total">>, Inv),
					  TagPrice    = ?v(<<"tag_price">>, Inv),
					  RPrice      = ?v(<<"rprice">>, Inv),

					  P = [{<<"style_number">>, StyleNumber},
					       {<<"brand_id">>, BrandId},
					       {<<"tag_price">>, TagPrice},
					       {<<"rprice">>, RPrice},
					       {<<"total">>, Total}
					      ],

					  [P|Acc] 
				  end, [], Invs),
			    print(RSN, Merchant, NewInvs, Base, Print, SuccessRespone);
			false ->
			    ?utils:respond(
			       200, Req, ?succ(new_w_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}])
		    end,
		    ?w_user_profile:update(retailer, Merchant); 
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

    %% FDiscount = ?v(<<"rdiscount">>, Inv),
    FPrice = ?v(<<"rprice">>, Inv),
    Calc = FPrice * Count,
    %% end,

    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true -> check_inventory(oncheck, Round, Money + Calc, ShouldPay, T);
		false -> {error, Inv}
	    end
    end.
    
    
mode(0) -> use_id;
mode(1) -> use_shop;
mode(2) -> use_brand;
mode(3) -> use_firm.


sys_vip_of_shop(Merchant, Shop) ->
    {ok, Settings} = ?w_user_profile:get(setting, Merchant, Shop),
    SysVips =
	lists:foldr(
	  fun({S}, Acc) ->
		  case ?v(<<"ename">>, S) =:= <<"s_customer">> of
		      true ->
			  SysVip = ?to_i(?v(<<"value">>, S)),
			  %% ?DEBUG("sysvip ~p", [SysVip]),
			  case lists:member(SysVip, Acc) of
			      true -> Acc;
			      false -> [SysVip] ++ Acc
			  end;
		      false -> Acc
		  end
	  end, [], Settings),
    SysVips.
