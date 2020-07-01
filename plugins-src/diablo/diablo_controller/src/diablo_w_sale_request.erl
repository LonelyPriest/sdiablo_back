-module(diablo_w_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([sale_note/3, sale_trans/3, note_class_with/3]).
-export([replace_condition_with_ctype/4,
	 replace_condition_with_ctype/5,
	 replace_condition_with_lbrand/5,
	 sys_vip_of_shop/2,
	 print_wsale_new/5,
	 start/6]).

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
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "wsaleApp"},
			  %% {ngcontroller, "wsaleCtrl"}
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
    UTable = ?session:get(utable, Session),
    
    try
	{ok, Sale} = ?w_sale:sale(get_new, {Merchant, UTable}, RSN),
	%% ?DEBUG("sale ~p", [Sale]),
	{ok, Details} = ?w_sale:sale(trans_detail, {Merchant, UTable}, {<<"rsn">>, ?to_b(RSN)}), 
	?DEBUG("details ~p", [Details]),

	{ok, TicketScore} =
	    case ?v(<<"tbatch">>, Sale) of
		?INVALID_OR_EMPTY -> {ok, 0};
		TicketBatch ->
		    TicketType = ?v(<<"tcustom">>, Sale), 
		    case TicketType of
			?INVALID_OR_EMPTY ->
			    {ok, 0};
			?CUSTOM_TICKET ->
			    {ok, 0};
			?SCORE_TICKET ->
			    {ok, Ticket} = ?w_retailer:get_ticket(
					      by_batch, Merchant, {TicketBatch, ?TICKET_ALL, TicketType}),
			    case ?v(<<"sid">>, Ticket) of
				-1 -> {ok, 0};
				TicketSid ->
				    {ok, Scores} = ?w_user_profile:get(score, Merchant),
				    case lists:filter(
					   fun({S})->
						   ?v(<<"type_id">>, S) =:= 1
						       andalso ?v(<<"id">>, S) =:= TicketSid end, Scores) of
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
    ?DEBUG("list_w_sale_new with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    batch_responed(
      fun() -> ?w_sale:sale(list_new, {Merchant, UTable}, Payload) end, Req); 

action(Session, Req, {"get_last_sale"}, Payload) ->
    ?DEBUG("get_last_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),

    case ?w_sale:sale(last, {Merchant, UTable}, Payload) of
	{ok, Last} ->
	    ?utils:respond(200, batch, Req, {Last});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_sale_new"}, Payload) ->
    ?DEBUG("filter_w_sale_new with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_sale:filter(total_news, ?to_a(Match), {Merchant, UTable}, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_sale:filter(
		  news,
		  Match,
		  {Merchant, UTable},
		  CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_w_sale_image"}, Payload) ->
    ?DEBUG("filter_w_sale_image with session ~p, payload~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
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
		      total_groups, Match, {Merchant, UTable}, Conditions)
	   end,
	   fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
		   ?w_inventory:filter(
		      groups,
		      Match, {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions)
	   end, NewPayload),

    case Result of
	{ok, Total, []} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0}, {<<"total">>, Total}, {<<"data">>, []}]});
	{ok, Total, Data, _Extra} ->
	    ?utils:respond(
	       200, object, Req,
	       {[{<<"ecode">>, 0},
		 {<<"total">>, Total},
		 {<<"data">>, Data},
		 {<<"history">>, []}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_sale"}, Payload) ->
    ?DEBUG("new_w_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session), 
    UserId = ?session:get(id, Session),
    
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    {struct, Print} = ?v(<<"print">>, Payload), 
    TicketBatchs    = ?v(<<"ticket_batchs">>, Base),
    TicketBalance   = ?v(<<"ticket">>, Base), 
    TicketCustom    = ?v(<<"ticket_custom">>, Base, -1),

    TicketInfo = 
	case TicketCustom of
	    ?SCORE_TICKET -> 
		{ok, Ticket} = ?w_retailer:get_ticket(by_batch, Merchant, TicketBatchs, ?SCORE_TICKET), 
		TicketSId = ?v(<<"sid">>, Ticket, ?INVALID_OR_EMPTY),
		{ok, Scores} = ?w_user_profile:get(score, Merchant),
		case lists:filter(
		       fun({S})->
			       ?v(<<"type_id">>, S) =:= 1 andalso ?v(<<"id">>, S) =:= TicketSId
		       end, Scores) of
		    [] ->
			{error, ?err(wsale_invalid_ticket_score, TicketSId)}; 
		    [{Score2Money}] ->
			case TicketBalance /= ?v(<<"balance">>, Ticket) of
			    true ->
				{error, ?err(wsale_invalid_ticket_balance, TicketBalance)}; 
			    false -> 
				AccScore = ?v(<<"score">>, Score2Money), 
				Balance = ?v(<<"balance">>, Score2Money),
				TicketScore =TicketBalance div Balance * AccScore,
				{ok_ticket, TicketScore} 
			end


		end;
	    ?CUSTOM_TICKET ->
		{ok, Tickets} = ?w_retailer:get_ticket(by_batch, Merchant, TicketBatchs, ?CUSTOM_TICKET),
		%% ?DEBUG("Tickets ~p", [Tickets]),
		RealTicketBalance = 
		    lists:foldr(
		      fun({T}, Acc) ->
			      ?v(<<"balance">>, T) + Acc
		      end, 0, Tickets),
		%% ?DEBUG("RealTicketBalance ~p", [RealTicketBalance]),
		case TicketBalance /= RealTicketBalance of
		    true ->
			{error, ?err(wsale_invalid_ticket_balance, TicketBalance)};
		    false ->
			{ok_ticket, 0}
		end;
	    ?INVALID_OR_EMPTY ->
		{ok_non_ticket, 0}
	end,
    
    case TicketInfo of
	{ok_non_ticket, 0} ->
	    start(new_sale,
		  Req,
		  {Merchant, UTable},
		  Invs,
		  lists:keydelete(<<"ticket_custom">>, 1, Base) ++ [{<<"user">>, UserId}],
		  Print);
	{ok_ticket, 0} ->
	    start(new_sale, Req, {Merchant, UTable}, Invs, Base ++ [{<<"user">>, UserId}], Print);
	{ok_ticket, _TicketScore} ->
	    start(
	      new_sale,
	      Req,
	      {Merchant, UTable},
	      Invs,
	      Base ++ [{<<"ticket_score">>, _TicketScore}, {<<"user">>, UserId}],
	      Print);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
    
    %% case TicketBatch =/= undefined andalso TicketBalance =/= undefined of
    %% 	true ->
    %% 	    {ok, Ticket} = ?w_retailer:get_ticket(by_batch, Merchant, TicketBatch, TicketCustom), 
    %% 	    case Ticket of
    %% 		[] -> 
    %% 		    ?utils:respond(200, Req, ?err(ticket_not_exist, TicketBatch));
    %% 		_ ->
    %% 		    TicketInfo =
    %% 			case TicketCustom of
    %% 			    ?SCORE_TICKET ->
    %% 				TicketSId = ?v(<<"sid">>, Ticket),
    %% 				case TicketSId of
    %% 				    ?INVALID_OR_EMPTY -> {ok, 0};
    %% 				    _ ->
    %% 					{ok, Scores} = ?w_user_profile:get(score, Merchant),
    %% 					case lists:filter(
    %% 					       fun({S})->
    %% 						       ?v(<<"type_id">>, S) =:= 1
    %% 							   andalso ?v(<<"id">>, S) =:= TicketSId
    %% 					       end, Scores) of
    %% 					    [] ->
    %% 						{error, ?err(wsale_invalid_ticket_score, TicketSId)}; 
    %% 					    [{Score2Money}] ->
    %% 						case TicketBalance /= ?v(<<"balance">>, Ticket) of
    %% 						    true ->
    %% 							{error, ?err(wsale_invalid_ticket_balance, TicketBalance)}; 
    %% 						    false -> 
    %% 							AccScore = ?v(<<"score">>, Score2Money), 
    %% 							Balance = ?v(<<"balance">>, Score2Money),
    %% 							TicketScore =TicketBalance div Balance * AccScore,
    %% 							{ok, TicketScore} 
    %% 						end
    %% 					end
    %% 				end;
    %% 			    ?CUSTOM_TICKET ->
    %% 				case TicketBalance /= ?v(<<"balance">>, Ticket) of
    %% 				    true ->
    %% 					{error, ?err(wsale_invalid_ticket_balance, TicketBalance)};
    %% 				    false ->
    %% 					{ok, 0}
    %% 				end
    %% 			end,
		    
    %% 		    case TicketInfo of
    %% 			{ok, 0} ->
    %% 			    start(new_sale, Req, Merchant, Invs, Base ++ [{<<"user">>, UserId}], Print);
    %% 			{ok, _TicketScore} ->
    %% 			    start(
    %% 			      new_sale,
    %% 			      Req,
    %% 			      Merchant,
    %% 			      Invs,
    %% 			      Base ++ [{<<"ticket_score">>, _TicketScore}, {<<"user">>, UserId}],
    %% 			      Print);
    %% 			{error, Error} ->
    %% 			    ?utils:respond(200, Req, Error)
    %% 		    end
    %% 	    end;
    %% 	false ->
    %% 	    start(new_sale,
    %% 		  Req,
    %% 		  Merchant,
    %% 		  Invs,
    %% 		  lists:keydelete(<<"ticket_custom">>, 1, Base) ++ [{<<"user">>, UserId}],
    %% 		  Print)
    %% end;
	
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
    UTable = ?session:get(utable, Session), 
    
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    RSN             = ?v(<<"rsn">>, Base),
    Vip             = ?v(<<"vip">>, Base, false),
    
    case ?w_sale:sale(get_new, {Merchant, UTable}, RSN) of
	{ok, OldBase} -> 
	    case ?w_sale:sale(update, {Merchant, UTable}, lists:reverse(Invs), {Base, OldBase}) of
		{ok, {RSN, BackBalance, _BackScore, {OldRetailerId, Withdraw}, {NewRetailerId, NewWithdraw}}} -> 
		    case OldRetailerId =:= NewRetailerId andalso Withdraw /= NewWithdraw of
			true ->
			    {ok, Retailer} = ?w_retailer:retailer(get, Merchant, OldRetailerId), 
			    ShopId = ?v(<<"shop_id">>, OldBase),
			    {SMSCode, _} =
				send_sms(Merchant, 2, ShopId, Retailer, BackBalance),
			    ?utils:respond(
			       200, Req, ?succ(update_w_sale, RSN),
			       [{<<"rsn">>, ?to_b(RSN)}, {<<"sms_code">>, SMSCode}]);
			false ->
			    case Vip of
				true -> ok;
				false -> ?w_user_profile:update(sysretailer, Merchant)
			    end, 
			    ?utils:respond(
			       200, Req, ?succ(update_w_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}])
		    end;
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
    %% end;

action(Session, Req, {"delete_w_sale"}, Payload) ->
    ?DEBUG("delete_w_sale: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    RSN = ?v(<<"rsn">>, Payload), 
    case ?w_sale:sale(get_new, {Merchant, UTable}, RSN) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_empty, RSN));
	{ok, New} ->
	    case ?w_sale:sale(trans_detail, {Merchant, UTable}, {<<"rsn">>, ?to_b(RSN)}) of
		{ok, []} -> 
		    case ?w_sale:sale(delete_new,
				      {Merchant, UTable},
				      {RSN, ?v(<<"retailer_id">>, New)}) of
			{ok, RSN} ->
			    ?utils:respond(
			       200, Req, ?succ(update_w_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}]);
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{ok, _} ->
		    ?utils:respond(200, Req, ?err(wsale_trans_detail_not_empty, RSN)); 
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_sale"}, Payload) ->
    ?DEBUG("chekc_w_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?CHECK), 
    case ?w_sale:sale(check, {Merchant, UTable}, RSN, Mode) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req, ?succ(check_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;
    
    
action(Session, Req, {"print_w_sale"}, Payload) ->
    ?DEBUG("print_w_sale with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    RSN      = ?v(<<"rsn">>, Payload),
    try
	{ok, Sale} = ?w_sale:sale(get_new, {Merchant, UTable}, RSN),
	?DEBUG("sale ~p", [Sale]),
	{ok, SaleDetails} = ?w_sale:sale(trans_detail, {Merchant, UTable}, {<<"rsn">>, ?to_b(RSN)}),
	?DEBUG("details ~p", [SaleDetails]), 

	{ok, TicketScore} = 
	    case ?v(<<"tbatch">>, Sale) of
		?INVALID_OR_EMPTY -> {ok, 0};
		TicketBatch ->
		    TicketType = ?v(<<"tcustom">>, Sale), 
		    case TicketType of
			?INVALID_OR_EMPTY ->
			    {ok, 0};
			?CUSTOM_TICKET ->
			    {ok, 0};
			?SCORE_TICKET -> 
			    {ok, Ticket} = ?w_retailer:get_ticket(
					      by_batch,
					      Merchant,
					      {TicketBatch, ?TICKET_ALL, TicketType}),
			    case ?v(<<"sid">>, Ticket) of
				?INVALID_OR_EMPTY -> {ok, 0};
				TicketSid ->
				    {ok, Scores} = ?w_user_profile:get(score, Merchant),
				    case lists:filter(
					   fun({S})->
						   ?v(<<"type_id">>, S) =:= 1
						       andalso ?v(<<"id">>, S) =:= TicketSid end, Scores) of
					[] -> throw({wsale_invalid_ticket_score, TicketBatch}) ;
					[{Score2Money}] -> 
					    AccScore = ?v(<<"score">>, Score2Money), 
					    Balance = ?v(<<"balance">>, Score2Money),
					    TicketBalance = ?v(<<"balance">>, Ticket),
					    case ?w_sale:direct(?v(<<"type">>, Sale)) of
						wreject -> {ok, -TicketBalance div Balance * AccScore};
						_ ->{ok, -TicketBalance div Balance * AccScore}
					    end
				    end
			    end
		    end
	    end,
	
	%% {ok, Details} = ?w_sale:rsn_detail(rsn, Merchant, {<<"rsn">>, RSN}),

	CombineInvs = combine_inv(SaleDetails, []),
	?DEBUG("combineinvs ~p", [CombineInvs]),

	%% {ok, Retailer} = ?w_user_profile:get(
	%% 		    retailer, Merchant, ?v(<<"retailer_id">>, Sale)),
	
	{ok, Employee} = ?w_user_profile:get(employee, Merchant, ?v(<<"employ_id">>, Sale)),
	%% {ok, Brands}   = ?w_user_profile:get(brand, Merchant),

	%% GetBrand =
	%%     fun(BrandId)->
	%% 	    case ?w_user_profile:filter(Brands, <<"id">>, BrandId) of
	%% 		[] -> [];
	%% 		FindBrand -> ?v(<<"name">>, FindBrand)
	%% 	    end
	%%     end,
	    
	%% SortInvs = sort_inventory(Merchant, GetBrand, Details, []),
	%% ?DEBUG("sorts ~p", [SortInvs]),
	RetailerId = ?v(<<"retailer_id">>, Sale),
	ShopId     = ?v(<<"shop_id">>, Sale),
	RSNAttrs = [{<<"shop">>,       ShopId},		    
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
		      {<<"retailer_id">>, RetailerId},
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
    UTable = ?session:get(utable, Session),
    
    UserId = ?session:get(id, Session),
    %% UserId = ?right:get(account, Merchant, User), 
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base}   = ?v(<<"base">>, Payload), 
    Datetime         = ?v(<<"datetime">>, Base),
    
    RejectTotal = calc_count(reject, Invs, 0),
    case RejectTotal =/= ?v(<<"total">>, Base) of
	true ->
	    ?utils:respond(200, Req, ?err(wsale_invalid_stock_total, RejectTotal));
	false -> 
	    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 1800 of
		true ->
		    CurDatetime = ?utils:current_time(format_localtime), 
		    ?utils:respond(200,
				   Req,
				   ?err(wsale_invalid_date, "reject_w_sale"),
				   [{<<"fdate">>, Datetime},
				    {<<"bdate">>, ?to_b(CurDatetime)}]);
		false ->
		    TicketCustom = ?v(<<"tcustom">>, Base, ?INVALID_OR_EMPTY),
		    Props = Base ++ [{<<"user">>, UserId}],
		    case TicketCustom of
			?INVALID_OR_EMPTY ->
			    start(reject_w_sale, Req, {Merchant, UTable}, Invs, Props);
			_ ->
			   case ?v(<<"tbatch">>, Base, []) of
			       [] -> 
				   SaleRsn = ?v(<<"sale_rsn">>, Base, []),
				   case ?w_retailer:get_ticket(by_sale, Merchant, SaleRsn, TicketCustom) of
				       {ok, []} -> 
					   start(reject_w_sale, Req, {Merchant, UTable}, Invs, Props);
				       {ok, [{OneTicket}]} ->
					   Batch = ?v(<<"batch">>, OneTicket),
					   NewProps = lists:keydelete(<<"tbatch">>, 1, Props), 
					   case TicketCustom of
					       ?SCORE_TICKET ->
						   TicketBalance = ?v(<<"ticket">>, Base, 0),
						   case calc_ticket_score(
							  OneTicket, TicketBalance, Merchant) of
						       {ok_ticket, TicketScore} -> 
							   start(reject_w_sale,
								 Req,
								 {Merchant, UTable},
								 Invs,
								 NewProps
								 ++ [{<<"tbatch">>, [Batch]}]
								 ++ [{<<"ticket_score">>, TicketScore}]);
						       {error, TicketError} ->
							   ?utils:respond(200, Req, TicketError)
						   end;
					       ?CUSTOM_TICKET ->
						   start(reject_w_sale,
							 Req,
							 {Merchant, UTable},
							 Invs,
							 NewProps
							 ++ [{<<"tbatch">>, [Batch]}])
					   end;
					   %% Batch = ?v(<<"batch">>, OneTicket), 
					   %% case ?v(<<"balance">>, OneTicket) /= ?v(<<"ticket">>, Base, 0) of
					   %%     true -> ?utils:respond(
					   %% 		  200,
					   %% 		  Req,
					   %% 		  ?err(invalid_ticket_balance, Batch));
					   %%     false ->
					   %% 	   NewProps = lists:keydelete(<<"tbatch">>, 1, Props),
					   %% 	   start(reject_w_sale,
					   %% 		 Req,
					   %% 		 {Merchant, UTable},
					   %% 		 Invs,
					   %% 		 NewProps ++ [{<<"tbatch">>, [Batch]}])
					   %% end;
				       {ok, MoreTickets} ->
					   Batchs = 
					       lists:foldr(
						 fun({Ticket}, Acc) ->
							 [?to_s(?v(<<"batch">>, Ticket))|Acc]
						 end, [], MoreTickets),
					   ?utils:respond(
					      200,
					      Req,
					      ?err(more_ticket_consume, Batchs))
				   end;
			       _ ->
				   start(reject_w_sale, Req, {Merchant, UTable}, Invs, Props)
			   end
				
		    end 
	    end
    end;

action(Session, Req, {"filter_w_sale_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_sale_rsn_group with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant           = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    {struct, Mode}     = ?v(<<"mode">>, Payload), 
    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode),
    ShowNote = ?v(<<"note">>, Mode),
    
    NewPayload = proplists:delete(<<"mode">>, Payload), 
    {struct, Fields}     = ?v(<<"fields">>, Payload),
    
    CType = ?v(<<"ctype">>, Fields),
    SType = ?v(<<"type">>, Fields),
    
    PayloadWithCtype = replace_condition_with_ctype(Merchant, CType, SType, Fields, NewPayload),
    ?DEBUG("PayloadWithCtype ~p", [PayloadWithCtype]),

    %% replace lbrand
    Like = ?value(<<"match">>, Payload, 'and'),
    Brand = ?v(<<"brand">>, Fields),
    %% LBrand = ?v(<<"lbrand">>, Fields),

    {struct, NewFields}  = ?v(<<"fields">>, PayloadWithCtype), 
    PayloadWithLBrand =
	replace_condition_with_lbrand(?to_a(Like), Merchant, Brand, NewFields, PayloadWithCtype),

    ?DEBUG("PayloadWithlbrand ~p", [PayloadWithLBrand]),
    
    case ShowNote of
	?NO -> 
	    ?pagination:pagination(
	       fun(Match, Conditions) ->
		       ?w_sale:filter(total_rsn_group, ?to_a(Match), {Merchant, UTable}, Conditions)
	       end,
	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
		       ?w_sale:filter(
			  {rsn_group, mode(Order), Sort},
			  Match,
			  {Merchant, UTable},
			  CurrentPage, ItemsPerPage, Conditions)
	       end, Req, PayloadWithLBrand);
	?YES -> 
	    case
		?pagination:pagination(
		   no_response,
		   fun(Match, Conditions) ->
			   ?w_sale:filter(total_rsn_group,
					  ?to_a(Match),
					  {Merchant, UTable}, Conditions)
		   end,
		   fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
			   ?w_sale:filter({rsn_group, mode(Order), Sort},
					  Match,
					  {Merchant, UTable},
					  CurrentPage, ItemsPerPage, Conditions)
		   end, PayloadWithLBrand)
	    of
		{ok, Total, []} ->
		    ?utils:respond(
		       200, object, Req,
		       {[{<<"ecode">>, 0}, {<<"total">>, Total}, {<<"data">>, []}]});
		{ok, Total, Data, Extra} ->
		    %% ?DEBUG("Total ~p, Data ~p, Extra ~p", [Total, Data, Extra]),
		    %% get rsn
		    %% {ok, AllColors} = ?w_user_profile:get(color, Merchant), 
		    Rsns = lists:foldr(
			     fun({D}, Acc) ->
				     Rsn = ?v(<<"rsn">>, D),
				     case lists:member(Rsn, Acc) of
					 true -> Acc;
					 false -> [Rsn|Acc]
				     end
			     end, [], Data),
		    %% note
		    {ok, SaleNotes} = ?w_sale:export(
					 trans_note_color_size,
					 {Merchant, UTable},
					 [{<<"rsn">>, Rsns}]),
		    NoteDict = sale_note(to_dict_with_rsn, SaleNotes, dict:new()),

		    DataWithNote =
			lists:foldr(
			  fun({D}, Acc) ->
				  %% ?DEBUG("D ~p", [D]),
				  Rsn = ?to_b(?v(<<"rsn">>, D)),
				  StyleNumber = ?to_b(?v(<<"style_number">>, D)),
				  UBrand = ?to_b(?v(<<"brand_id">>, D)),
				  Shop  = ?to_b(?v(<<"shop_id">>, D)),
				  Key = <<Rsn/binary,
					  <<"-">>/binary,
					  StyleNumber/binary,
					  <<"-">>/binary,
					  UBrand/binary,
					  <<"-">>/binary,
					  Shop/binary>>,

				  %% ?DEBUG("Key ~p", [Key]),
				  case dict:find(Key, NoteDict) of
				      error ->
					  [{D ++ [{<<"note">>, <<>>}]}] ++ Acc;
				      {ok, Find} ->
					  Note = ?to_b(?v(<<"note">>, Find)),
					  [{D ++ [{<<"note">>, Note}]}] ++ Acc
				  end
			  end, [], Data),

		    ?utils:respond(
		       200, object, Req, {[{<<"ecode">>, 0},
					   {<<"total">>, Total},
					   {<<"data">>, DataWithNote}] ++ Extra}); 
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

action(Session, Req, {"filter_employee_evaluation"}, Payload) ->
    ?DEBUG("filter_employee_evaluation with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_sale:filter(total_employee_evaluation,
			      ?to_a(Match),
			      {Merchant, UTable},
			      Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_sale:filter(employee_evaluation,
			      Match,
			      {Merchant, UTable},
			      CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"list_wsale_group_by_style_number"}, Payload) ->
    ?DEBUG("filter_w_sale_firm_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    {struct, NewPayload} = ?v(<<"condition">>, Payload),

    CType = ?v(<<"ctype">>, NewPayload),
    SType = ?v(<<"type">>, NewPayload), 
    PayloadWithCtype = replace_condition_with_ctype(Merchant, CType, SType, NewPayload),
    ?DEBUG("PayloadWithCtype ~p", [PayloadWithCtype]),
    
    {ok, Q} = ?w_sale:sale(get_rsn, {Merchant, UTable}, PayloadWithCtype),
    case Q of
	[] ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"total">>, 0},
			     {<<"note">>, []}]});
	_ ->
	    {struct, NewConditions} =
		?v(<<"fields">>,
		   ?w_inventory_request:filter_condition(
		      trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], PayloadWithCtype)),

	    {ok, Colors} = ?w_user_profile:get(color, Merchant), 
	    {ok, Sales} = ?w_sale:export(trans_note, {Merchant, UTable}, NewConditions),

	    NoteConditions = [{<<"rsn">>, ?v(<<"rsn">>, NewConditions, [])}],
	    {ok, SaleNotes} = ?w_sale:export(trans_note_color_size,
					     {Merchant, UTable}, NoteConditions),

	    SortTranses = sale_trans(to_dict, Sales, dict:new()),
	    DictNotes = sale_note(to_dict, SaleNotes, dict:new()),

	    {Amount, Notes} = print_wsale_new(sort_by_color, Colors, SortTranses, DictNotes, {0, []}),

	    Sort = lists:sort(
		     fun({N1}, {N2}) ->
			     Firm1 = ?v(<<"firm_id">>, N1),
			     Firm2 = ?v(<<"firm_id">>, N2),
			     Firm1 > Firm2
		     end, Notes),

	    %% ?DEBUG("sort ~p", [Sort]),
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"total">>, Amount},
			     {<<"note">>, Sort}]})
    end;
    

action(Session, Req, {"w_sale_rsn_detail"}, Payload) ->
    ?DEBUG("w_sale_rsn_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_sale:rsn_detail(rsn, {Merchant, UTable}, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"w_sale_export"}, Payload) ->
    ?DEBUG("w_sale_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),
    
    {struct, Conditions} = ?v(<<"condition">>, Payload),


    NewConditions = 
	case ExportType of
	    trans_note ->
		{struct, CutConditions} = ?v(<<"condition">>, Payload),
		{ok, Q} = ?w_sale:sale(get_rsn, {Merchant, UTable}, CutConditions),
		{struct, C} =
		    ?v(<<"fields">>,
		       ?w_inventory_request:filter_condition(
			  trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q],
			  CutConditions)),
		C;
	    trans -> Conditions
	end,
	    
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportColorSize = ?to_i(?v(<<"export_note">>, BaseSetting, 0)),
    ExportCode = ?to_i(?v(<<"export_code">>, BaseSetting, 0)),
    
    case ?w_sale:export(ExportType, {Merchant, UTable}, NewConditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_no_date, Merchant));
	{ok, Transes} -> 
	    %% write to file 
	    {ok, ExportFile, Url} =
		?utils:create_export_file("otrans", Merchant, UserId),

	    case ExportColorSize =:= 1 andalso ExportType =:= trans_note of
		true ->
		    %% only rsn
		    NoteConditions = [{<<"rsn">>, ?v(<<"rsn">>, NewConditions, [])}],
		    case ?w_sale:export(trans_note_color_size, {Merchant, UTable}, NoteConditions) of
			[] ->
			    ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
			{ok, SaleNotes} ->
			    {ok, Colors} = ?w_user_profile:get(color, Merchant),
			    case file:open(ExportFile, [append, raw]) of
				{ok, Fd} ->
				    try
					%% sort stock by color
					DoFun = fun(C) -> ?utils:write(Fd, C) end,
					%% sort transe
					%% lists:foldr(
					%%   fun({Trans}, Acc0) ->
					%% 	  Exist = ?v(<<"">>)
					%% 	  lists:keydelete(<<"total">>, 1, Acc0),
						  
					%%   end, Transes)
					SortTranses = sale_trans(to_dict, Transes, dict:new()),
					DictNotes = sale_note(to_dict, SaleNotes, dict:new()),
					csv_head(
					  trans_note_color,
					  DoFun,
					  ExportCode),
					do_write(
					  trans_note_color,
					  DoFun,
					  1,
					  SortTranses,
					  DictNotes,
					  Colors,
					  ExportCode,
					  {0, 0, 0}),
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
			    end
		    end;
		false -> 
		    case file:open(ExportFile, [write, raw]) of
			{ok, Fd} -> 
			    try
				DoFun = fun(C) -> ?utils:write(Fd, C) end,
				csv_head(ExportType, DoFun, ExportCode),
				do_write(ExportType, DoFun, 1, Transes, ExportCode, {0, 0, 0}),
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
		    end
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"print_w_sale_note"}, Payload) ->
    ?DEBUG("print_w_sale_note with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    {struct, Fields} = ?v(<<"fields">>, Payload),
    CType = ?v(<<"ctype">>, Fields),
    SType = ?v(<<"type">>, Fields),

    PayloadWithCtype = replace_condition_with_ctype(Merchant, CType, SType, Fields, Payload),
    ?DEBUG("PayloadWithCtype ~p", [PayloadWithCtype]),

    Like = ?value(<<"match">>, Payload, 'and'),
    Brand = ?v(<<"brand">>, Fields),

    {struct, NewFields}  = ?v(<<"fields">>, PayloadWithCtype), 
    PayloadWithLBrand =
	replace_condition_with_lbrand(?to_a(Like), Merchant, Brand, NewFields, PayloadWithCtype),
    ?DEBUG("PayloadWithlbrand ~p", [PayloadWithLBrand]),

    {struct, Conditions} = ?v(<<"fields">>, PayloadWithLBrand),
    {ok, Q} = ?w_sale:sale(get_rsn, {Merchant, UTable}, Conditions),
    {struct, NewConditions} =
	?v(<<"fields">>,
	   ?w_inventory_request:filter_condition(
	      trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], Conditions)),
    
    {ok, Transes} = ?w_sale:export(trans_note, {Merchant, UTable}, NewConditions),
    
    NoteConditions = [{<<"rsn">>, ?v(<<"rsn">>, NewConditions, [])}],
    {ok, SaleNotes} = ?w_sale:export(trans_note_color_size, {Merchant, UTable}, NoteConditions), 
    NoteDict = sale_note(to_dict_with_rsn, SaleNotes, dict:new()),

    TransesWithNote =
	lists:foldr(
	  fun({D}, Acc) ->
		  %% ?DEBUG("D ~p", [D]),
		  Rsn = ?to_b(?v(<<"rsn">>, D)),
		  StyleNumber = ?to_b(?v(<<"style_number">>, D)),
		  UBrand = ?to_b(?v(<<"brand_id">>, D)),
		  Shop  = ?to_b(?v(<<"shop_id">>, D)),
		  Key = <<Rsn/binary,
			  <<"-">>/binary,
			  StyleNumber/binary,
			  <<"-">>/binary,
			  UBrand/binary,
			  <<"-">>/binary,
			  Shop/binary>>,

		  %% ?DEBUG("Key ~p", [Key]),
		  case dict:find(Key, NoteDict) of
		      error ->
			  [{D ++ [{<<"note">>, <<>>}]}] ++ Acc;
		      {ok, Find} ->
			  Note = ?to_b(?v(<<"note">>, Find)),
			  [{D ++ [{<<"note">>, Note}]}] ++ Acc
		  end
	  end, [], Transes),

    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, TransesWithNote}]});
    
action(Session, Req, {"get_wsale_rsn"}, Payload) ->
    ?DEBUG("get_wsale_rsn with session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    batch_responed(
      fun() -> ?w_sale:sale(
		  get_rsn,
		  {Merchant, UTable},
		  [{<<"sell_type">>, 0}|Payload]) end, Req);

action(Session, Req, {"match_wsale_rsn"}, Payload) ->
    ?DEBUG("match_wsale_rsn with session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    %% {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    %% StartTime = ?v(<<"qtime_start">>, BaseSetting),
    %% EndTime = ?v(<<"qtime_end">>, BaseSetting)
    Shops = ?v(<<"shop">>, Payload),
    Prompt = ?v(<<"prompt">>, Payload),
    Mode = ?v(<<"mode">>, Payload, ?RSN_OF_ALL),
    
    {struct, Conditions} = ?v(<<"condition">>, Payload),
    batch_responed(
      fun() -> ?w_sale:sale(
		  match_rsn,
		  {Merchant, UTable},
		  case Mode of
		      ?RSN_OF_ALL ->
			  {Prompt, Conditions};
		      ?RSN_OF_NEW ->
			  {Prompt, [{<<"shop">>, Shops}, {<<"type">>, ?NEW_SALE}|Conditions]}
		  end)
      end, Req);

action(Session, Req, {"upload_w_sale", ShopId}, Payload) ->
    ?DEBUG("upload_w_sale with session ~p, ShopId ~p, payload~n~ts", [Session, ShopId, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    {ok, Colors} = ?w_user_profile:get(color, Merchant),
    {ok, Sizes} = ?w_user_profile:get(size_group, Merchant),

    {ok, [{Employee}|_]} = ?w_user_profile:get(employee, Merchant),
    %% {ok, [{Retailer}|_T]} = ?w_user_profile:get(retailer, Merchant),
    {ok, [{Retailer}|_]} = ?w_retailer:retailer(list, Merchant),
    %% ?DEBUG("Employee ~p", [Employee]),
    %% ?DEBUG("Retailers ~p", [Retailers]),

    case 
	diablo_import_taobao_csv:parse_data(
	  taobao_csv,
	  {Merchant, ShopId, ?v(<<"number">>, Employee), ?v(<<"id">>, Retailer)},
	  Payload,
	  Colors,
	  Sizes) of
	{ok, ShopId} ->
	    ?utils:respond(200, Req, ?succ(w_sale_uploaded, ShopId), {<<"shop">>, ?to_b(ShopId)}); 
	{error, Error, StyleNumber} ->
	    ?utils:respond(200, Req, Error, [{<<"style_number">>, ?to_b(StyleNumber)}]);
	{error, {invalid_stock_total, StyleNumber, TotalOfStyleNumber, Amount}} ->
	    ?utils:respond(200,
			   Req,
			   ?err(wsale_invalid_stock_total, StyleNumber),
			   [{<<"style_number">>, ?to_b(StyleNumber)},
			    {<<"total">>, TotalOfStyleNumber},
			    {<<"amount">>, Amount}]);
	{error, Error} -> 
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_sale_price"}, Payload) ->
    ?DEBUG("update_w_sale_price: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    
    RSN = ?v(<<"rsn">>, Payload),
    {struct, Updates} = ?v(<<"update">>, Payload),
    
    case ?w_sale:sale(update_price, {Merchant, UTable}, RSN, Updates) of
	{ok, RSN} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}]});
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_daily_cost"}, Payload) ->
    ?DEBUG("new_daily_cost: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       normal,
       fun() -> ?shop:cost(new, Merchant, Payload) end,
       fun(CostId) -> ?succ(add_shop, CostId) end,
       Req);

action(Session, Req, {"update_daily_cost"}, Payload) ->
    ?DEBUG("update_daily_cost: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       normal,
       fun() -> ?shop:cost(update, Merchant, Payload) end,
       fun(CostId) -> ?succ(add_shop, CostId) end,
       Req);

action(Session, Req, {"list_daily_cost"}, Payload) ->
    ?DEBUG("list_daily_cost: Session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?shop:cost(total, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?shop:cost(
		  filter,
		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"w_pay_scan"}, Payload) ->
    ?DEBUG("wsale_pay_sacn: Session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ShopId   = ?v(<<"shop">>, Payload),
    PayCode  = ?v(<<"code">>, Payload),
    Balance  = ?v(<<"balance">>, Payload),
    %% Balance = 0.01,
    case Balance > 0 andalso Balance < ?MAX_PAY_SCAN of
	true ->
	    %% merchant no
	    case ?shop:shop(get, Merchant, ShopId) of
		{ok, []} ->
		    ?utils:respond(200, Req, ?err(pay_scan_no_shop, ShopId));
		{ok, Shop} ->
		    case ?v(<<"pay_cd">>, Shop) of
			<<>> ->
			    ?utils:respond(200, Req, ?err(pay_scan_not_open, ShopId));
			undefined ->
			    ?utils:respond(200, Req, ?err(pay_scan_not_open, ShopId));
			MchntCd -> 
			    case diablo_pay:pay(wwt, Merchant, MchntCd, PayCode, Balance) of
				{ok, ?PAY_SCAN_SUCCESS, PayOrder, PayType, PayBalance} ->
				    Extra = [{<<"pay_order">>, ?to_b(PayOrder)},
					     {<<"balance">>, PayBalance},
					     {<<"pay_type">>, PayType}],
				    case ?w_sale:pay_scan(
					    start,
					    Merchant,
					    ShopId,
					    {PayType, ?PAY_SCAN_SUCCESS, ?NEW_SALE, PayOrder, PayBalance}) of
					{ok, _} ->
					    ?utils:respond(
					       200, Req, ?succ(pay_scan, Merchant), Extra);
					{error, _Error} ->
					    ?utils:respond(
					       200,
					       Req,
					       ?err(pay_scan_success_but_db_error, PayOrder),
					       Extra)
						
				    end;
				{error, ?PAY_SCAN_UNKOWN, PayOrderNo} ->
				    PayType = ?v(<<"type">>, Payload),
				    ?w_sale:pay_scan(
				       start,
				       Merchant,
				       ShopId,
				       {PayType, ?PAY_SCAN_UNKOWN, ?NEW_SALE, PayOrderNo, Balance}),
				    ?utils:respond(
				       200, Req, ?err(pay_scan_unkown, PayOrderNo),
				       [{<<"pay_order">>, ?to_b(PayOrderNo)}]); 
					
				{error, invalid_pay_scan_code_len, PayCode} ->
				    ?utils:respond(
				       200,
				       Req,
				       ?err(invalid_pay_scan_code_len, PayCode));
				{error, pay_http_failed, Reason} ->
				    ?utils:respond(
				       200,
				       Req,
				       ?err(pay_http_failed, Reason)); 
				{error, Code, _PayOrderNo} -> 
				    ?utils:respond(
				       200,
				       Req,
				       ?err(pay_scan_failed, Merchant),
				       [{<<"pay_code">>, ?to_b(Code)}]) 
			    end
		    end;
		{error, Error} ->
		    ?utils:respond(200, Req, Error) 
	    end;
	false ->
	    ?utils:respond(200, Req, ?err(pay_can_max_balance, Balance))
    end;

action(Session, Req, {"filter_w_pay_scan"}, Payload) ->
    ?DEBUG("filter_w_pay_sacn: Session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_sale:filter(total_pay_scan, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_sale:filter(
		  pay_scan,
		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"check_w_pay_scan"}, Payload) ->
    ?DEBUG("check_w_pay_sacn: Session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ShopId = ?v(<<"shop">>, Payload),
    PayOrder = ?v(<<"pay_order">>, Payload),
    case ?shop:shop(get, Merchant, ShopId) of
	{ok, Shop} ->
	    MchntCd = ?v(<<"pay_cd">>, Shop),
	    case diablo_pay:pay(wwt_query, MchntCd, PayOrder) of
		{ok, PayState, PayType, PayBalance} ->
		    case ?w_sale:pay_scan(
			    check,
			    Merchant,
			    ShopId,
			    {PayType, PayState, PayOrder, PayBalance}) of
			{ok, _} ->
			    ?utils:respond(
			       200,
			       Req,
			       ?succ(check_pay_scan, PayOrder),
			      [{<<"balance">>, PayBalance},
			       {<<"pay_type">>, PayType},
			       {<<"pay_state">>, PayState}
			      ]);
			{error, _CheckError} ->
			    ?utils:respond(
			       200, Req, ?err(check_pay_scan_but_db_error, PayOrder))
		    end; 
		{error, check_pay_http_failed, Reason} ->
		    ?utils:respond(200, Req, ?err(check_pay_http_failed, Reason));
		{error, Code, MchntOrder} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(check_pay_scan_failed, MchntOrder),
		       [{<<"pay_code">>, ?to_b(Code)}])
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

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
		  "交易记录", "glyphicon glyphicon-bookmark"},
		 {"wsale_rsn_detail",
		  "交易明细", "glyphicon glyphicon-map-marker"}]
		++ case ?right_auth:authen(?employee_evaluation, Session) of
		       {ok, ?employee_evaluation} -> 
			   [{"employee_evaluation",
			     "业绩统计", "glyphicon glyphicon-download"}];
		       _ -> []
		   end
		++ case ?right_auth:authen(?list_daily_cost, Session) of
		       {ok, ?list_daily_cost} ->
			   [{"list_daily_cost",
			     "日常费用", "glyphicon glyphicon-euro"}];
		       _ -> []
		   end,
	    
	    Merchant = ?session:get(merchant, Session),
	    BaseSettings = ?w_report_request:get_setting(Merchant, -1),
	    %% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),

	    %% ?DEBUG("import ~p", [?v(<<"wsale_import">>, Setting)]),
	    UploadMenu = 
		case ?to_i(?w_report_request:get_config(<<"wsale_import">>, BaseSettings)) of
		    1 -> ?w_inventory_request:authen_shop_action(
			    {?upload_w_sale,
			     "upload_wsale",
			     "销售导入",
			     "glyphicon glyphicon-upload"}, Shops);
		    0 -> []
		end,

	    %% use pay scan
	    PayScan = 
		case ?utils:nth(25, ?w_report_request:get_config(<<"p_balance">>, BaseSettings)) of
		    ?YES ->
			[{"list_pay_scan", "支付明细", "glyphicon glyphicon-qrcode"}];
		    ?NO ->
			[]
		end,
		    
		
	    L1 = ?menu:sidebar(
		    level_1_menu, WSale ++ WReject ++ SaleR ++ PayScan ++ UploadMenu),
	    
	    L1
		
    end. 

%% =============================================================================
%% internal
%% =============================================================================
combine_inv([], Acc) ->
    Acc;
combine_inv([{Inv}|T], Acc) ->
    S       = ?v(<<"style_number">>, Inv),
    B       = ?v(<<"brand_id">>, Inv),
    TypeId  = ?v(<<"type_id">>, Inv),
    ColorId = ?v(<<"color_id">>, Inv),
    Size    = ?v(<<"size">>, Inv),
    Total   = ?v(<<"amount">>, Inv),
    
    case in_sort(Inv, Acc) of
	true ->
	    NewAcc = 
		lists:foldr(
		  fun({A}, Acc1) ->
			  S1 = ?v(<<"style_number">>, A),
			  B1 = ?v(<<"brand_id">>, A),
			  TagPrice = ?v(<<"tag_price">>, A),
			  RPrice   = ?v(<<"rprice">>, A),
			  %% ColorId  = ?v(<<"color_id">>, A),
			  %% Size     = ?v(<<"size">>, A), 
			  case S =:= S1 andalso B =:= B1 of
			      true ->
				  [{[{<<"style_number">>, S1},
				     {<<"brand_id">>, B1},
				     {<<"type_id">>, ?v(<<"type_id">>, A)},
				     {<<"tag_price">>, TagPrice},
				     {<<"rprice">>, RPrice},
				     {<<"total">>, ?v(<<"total">>, A) + Total},
				     {<<"amounts">>,
				      ?v(<<"amounts">>, A)
				      ++ [{struct, [{<<"cid">>, ColorId},
						    {<<"size">>, Size},
						    {<<"sell_count">>, Total}]}]
				     }
				    ]}|Acc1];
			      false ->
				  [{A}|Acc1]
			  end
		  end, [], Acc),
	    combine_inv(T, NewAcc);
	false ->
	    NewInv = 
		[{<<"style_number">>, S},
		 {<<"brand_id">>, B},
		 {<<"type_id">>, TypeId},
		 {<<"tag_price">>, ?v(<<"tag_price">>, Inv)},
		 {<<"rprice">>, ?v(<<"rprice">>, Inv)},
		 {<<"total">>, Total},
		 {<<"amounts">>, [{struct, [{<<"cid">>, ColorId},
					    {<<"size">>, Size},
					    {<<"sell_count">>, Total}]}]}
		],
	    combine_inv(T, [{NewInv}|Acc])
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

csv_head(trans, Do, ExportCode) ->
    H = "序号,单号,交易,店铺,客户,上次结余,累计结余"
	",店员,数量,应收,实收,积分"
	",现金,刷卡,微信,提现,电子卷,核销,备注,日期",
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    Do(C);
csv_head(trans_note, Do, ExportCode) -> 
    H = "序号,单号,客户,促销,积分,交易,店铺,店员"
	",款号,品牌,类型,季节,厂商,年度,上架日期,进价,吊牌价,成交价,数量,小计,折扣率,日期",
    %% UTF8 = unicode:characters_to_list(H, utf8),
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% Do(UTF8).
    Do(C);

csv_head(trans_note_color, Do, ExportCode) -> 
    H = "序号,店铺,款号,品牌,类型,季节,厂商,年度,小计,数量,颜色,尺码,上架日期",
    %% UTF8 = unicode:characters_to_list(H, utf8),
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% Do(UTF8).
    Do(C).

do_write(trans, Do, _Seq, [], ExportCode, {Amount, SPay, RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?to_s(Amount) ++ ?d
	++ ?to_s(SPay) ++ ?d
	++ ?to_s(RPay) ++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d,
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(trans, Do, Seq, [{H}|T], ExportCode, {Amount, SPay, RPay}) ->
    Rsn        = ?v(<<"rsn">>, H),
    Type       = ?v(<<"type">>, H),
    Shop       = ?v(<<"shop">>, H),
    Retailer   = ?v(<<"retailer">>, H), 
    Balance    = ?v(<<"balance">>, H),
    
    Employee  = ?v(<<"employee">>, H),
    Total     = ?v(<<"total">>, H),
    HasPay    = ?v(<<"should_pay">>, H),
    Score     = ?v(<<"score">>, H),
    
    Cash      = ?v(<<"cash">>, H),
    Card      = ?v(<<"card">>, H),
    WXin      = ?v(<<"wxin">>, H),
    WithDraw  = ?v(<<"withdraw">>, H),
    Ticket    = ?v(<<"ticket">>, H), 
    Verify    = ?v(<<"verificate">>, H), 
    
    Comment   = ?v(<<"comment">>, H),
    Datetime  = ?v(<<"entry_date">>, H),

    AccBalance = Balance - WithDraw,
    ShouldPay  = HasPay + Verify,
    
    %% ?DEBUG("CBalance ~p", [CBalance]),

    L = "\r\n"
	++ ?to_s(Seq) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(Type) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(AccBalance) ++ ?d
	
	++ ?to_s(Employee) ++ ?d 
	++ ?to_s(Total) ++ ?d
	++ ?to_s(HasPay) ++ ?d
	++ ?to_s(ShouldPay) ++ ?d
	++ ?to_s(Score) ++ ?d
	
	++ ?to_s(Cash) ++ ?d
	++ ?to_s(Card) ++ ?d 
	++ ?to_s(WXin) ++ ?d
	++ ?to_s(WithDraw) ++ ?d
	++ ?to_s(Ticket) ++ ?d
	++ ?to_s(Verify) ++ ?d 
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(Datetime),
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line), 
    do_write(trans, Do, Seq + 1, T, ExportCode, {Amount + Total,
						 SPay + ShouldPay,
						 RPay + HasPay});

do_write(trans_note, Do, _Seq, [], ExportCode, {Amount, _SPay, _RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?to_s(Amount) ++ ?d
	++ ?d
	++ ?d
	++ ?d,
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(trans_note, Do, Seq, [{H}|T], ExportCode, {Amount, SPay, RPay}) ->
    Rsn         = ?v(<<"rsn">>, H),
    Retailer    = ?v(<<"retailer">>, H),
    Promotion   = case ?v(<<"promotion">>, H) of
		      <<>> -> "-";
		      _P -> _P
		  end,
    Score       = case ?v(<<"score">>, H) of
		      <<>> -> "-";
		      _S -> _S
		  end,
    SellType    = ?v(<<"sell_type">>, H), 
    Shop        = ?v(<<"shop">>, H),
    Employee    = ?v(<<"employee">>, H),
    
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Season      = ?v(<<"season">>, H),
    Firm        = ?v(<<"firm">>, H),
    Year        = ?v(<<"year">>, H),
    InDatetime  = ?v(<<"in_datetime">>, H),
    OrgPrice    = ?v(<<"org_price">>, H),
    TagPrice    = ?v(<<"tag_price">>, H),
    RPrice      = ?v(<<"rprice">>, H), 
    Total       = ?v(<<"total">>, H),

    Calc        =  RPrice * Total, 
    Datetime    = ?v(<<"entry_date">>, H),
    
    L = "\r\n"
	++ ?to_s(Seq) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(Promotion) ++ ?d
	++ ?to_s(Score) ++ ?d 
	++ sale_type(SellType) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	
	++ "\'" ++ ?to_s(StyleNumber) ++ "\'" ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?w_inventory_request:season(Season) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Year) ++ ?d
	++ ?to_s(InDatetime) ++ ?d
	++ ?to_s(OrgPrice) ++ ?d 
	++ ?to_s(TagPrice) ++ ?d 
	++ ?to_s(RPrice) ++ ?d
	++ ?to_s(Total) ++ ?d
	++ ?to_s(Calc) ++ ?d 
	++ ?to_s(?w_good_sql:stock(ediscount, RPrice, TagPrice)) ++ ?d 
	++ ?to_s(Datetime),
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line),
    do_write(trans_note, Do, Seq + 1, T, ExportCode, {Amount + Total, SPay, RPay}).

do_write(trans_note_color, Do, _Seq, [], _DictNotes, _Colors, ExportCode, {Amount, _SPay, _RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d 
	++ ?to_s(Amount) ++ ?d,
	
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(trans_note_color, Do, Seq, [DH|DT], DictNotes, Colors, ExportCode, {Amount, SPay, RPay}) ->
    {Key, [{H}]} = DH,
    Shop        = ?v(<<"shop">>, H), 
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H),
    Type        = ?v(<<"type">>, H),
    Season      = ?v(<<"season">>, H),
    Firm        = ?v(<<"firm">>, H),
    Year        = ?v(<<"year">>, H),
    InDatetime  = ?v(<<"in_datetime">>, H), 
    Total       = ?v(<<"total">>, H), 

    case dict:find(Key, DictNotes) of
	{ok, FindNotes} ->
	    ?DEBUG("find notes ~p", [FindNotes]),
	    ColoredNotes = note_class_with(color, FindNotes, dict:new()),

	    Details = 
		dict:fold(
		  fun(K, SSNotes, Acc) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({S}, {Total0, Descs}) ->
					Size = ?v(<<"size">>, S),
					TotalA = ?v(<<"total">>, S),
					{Total0 + TotalA,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(TotalA) ++ ";"} 
				end, {0, []}, SSNotes),

			  [{K, TotalOfColor, SizeDescs}|Acc]

		  end, [], ColoredNotes),
	    %% ?DEBUG("Details ~p", [Details]),

	    L = "\r\n"
		++ ?to_s(Seq) ++ ?d
	    %% ++ ?to_s(Rsn) ++ ?d
	    %% ++ ?to_s(Retailer) ++ ?d
	    %% ++ ?to_s(Promotion) ++ ?d
	    %% ++ ?to_s(Score) ++ ?d 
	    %% ++ sale_type(SellType) ++ ?d
		++ ?to_s(Shop) ++ ?d
	    %% ++ ?to_s(Employee) ++ ?d

		++ "\'" ++ ?to_s(StyleNumber) ++ "\'" ++ ?d
		++ ?to_s(Brand) ++ ?d
		++ ?to_s(Type) ++ ?d
		++ ?w_inventory_request:season(Season) ++ ?d
		++ ?to_s(Firm) ++ ?d
		++ ?to_s(Year) ++ ?d
		++ ?to_s(Total) ++ ?d
		++ ?d %% total of color
		++ ?d %% color
		++ ?d %% size
		++ ?to_s(InDatetime),


	    C = lists:foldr(
		  fun({ColorId, TotalOfColor, SizeDescs}, Acc) ->
			  L1 = "\r\n"
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d 
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d

			      ++ ?to_s(TotalOfColor) ++ ?d
			      ++ ?to_s(?w_inventory_request:get_color(ColorId, Colors)) ++ ?d
			      ++ ?to_s(SizeDescs) ++ ?d
			      ++ ?d,
			  Acc ++ L1
		  end, [], Details),

	    %% UTF8 = unicode:characters_to_list(L, utf8),
	    %% Do(UTF8),
	    Line = 
		case ExportCode of
		    0 -> ?utils:to_utf8(from_latin1, L ++ C);
		    1 -> ?utils:to_gbk(from_latin1, L ++ C)
		end,
	    Do(Line),
	    do_write(trans_note_color,
		     Do,
		     Seq + 1,
		     DT,
		     DictNotes,
		     Colors,
		     ExportCode,
		     {Amount + Total, SPay, RPay});

	error ->
	    do_write(trans_note_color,
		     Do,
		     Seq + 1,
		     DT,
		     DictNotes,
		     Colors,
		     ExportCode,
		     {Amount + Total, SPay, RPay})
    end.

print_wsale_new(sort_by_color, _Colors, [], _DictNotes, {Amount, Acc}) ->
    {Amount, Acc};
print_wsale_new(sort_by_color, Colors, [DH|DT], DictNotes, {Amount, Acc}) ->
    {Key, [{H}]} = DH,
    Shop        = ?v(<<"shop">>, H),
    ShopId      = ?v(<<"shop_id">>, H),
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H),
    BrandId     = ?v(<<"brand_id">>, H),
    SGroup      = ?v(<<"s_group">>, H),
    Type        = ?v(<<"type">>, H),
    Season      = ?v(<<"season">>, H),
    Firm        = ?v(<<"firm">>, H),
    FirmId      = ?v(<<"firm_id">>, H),
    Year        = ?v(<<"year">>, H),
    InDatetime  = ?v(<<"in_datetime">>, H), 
    Total       = ?v(<<"total">>, H),
    TagPrice    = ?v(<<"tag_price">>, H),

    case dict:find(Key, DictNotes) of
	{ok, FindNotes} ->
	    %% ?DEBUG("find notes ~p", [FindNotes]),
	    ColoredNotes = note_class_with(color, FindNotes, dict:new()),
	    Details = 
		dict:fold(
		  fun(K, SSNotes, Acc1) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({S}, {Total0, Descs}) ->
					Size = ?v(<<"size">>, S),
					TotalA = ?v(<<"total">>, S),
					{Total0 + TotalA,
					 Descs ++ case TotalA == 0 of
						      true -> [];
						      false -> ?to_s(Size) ++ ":" ++ ?to_s(TotalA) ++ ";"
						  end} 
				end, {0, []}, SSNotes),

			  [{K, TotalOfColor, SizeDescs}|Acc1]

		  end, [], ColoredNotes),
	    
	    %% ?DEBUG("Details ~p", [Details]),

	    N = {[{<<"style_number">>, StyleNumber},
		  {<<"brand">>, Brand},
		  {<<"brand_id">>, BrandId},
		  {<<"tag_price">>, TagPrice},
		  {<<"s_group">>, SGroup},
		  {<<"shop">>,  Shop},
		  {<<"shop_id">>,  ShopId},
		  {<<"firm">>,  Firm},
		  {<<"firm_id">>, FirmId},
		  {<<"year">>,  Year},
		  {<<"type">>,  Type},
		  {<<"season">>,Season},
		  {<<"total">>, Total},
		  {<<"entry_date">>, InDatetime},
		  {<<"note">>,
		   lists:foldr(
		     fun({ColorId, TotalOfColor, SizeDesc}, Acc1) ->
			     [{[{<<"color_id">>, ColorId},
				{<<"color">>, ?to_b(?w_inventory_request:get_color(ColorId, Colors))},
				{<<"total">>, TotalOfColor},
				{<<"size">>, ?to_b(SizeDesc)}]}|Acc1]
		     end, [], Details)}]},
	    
	    print_wsale_new(sort_by_color, Colors, DT, DictNotes, {Amount + Total, [N|Acc]}); 
	error ->
	    print_wsale_new(sort_by_color, Colors, DT, DictNotes, {Amount, Acc})
	    
    end.    
    
%% same style_number and brand, sort by color
note_class_with(color, [], Sorts) ->
    %% ?DEBUG("not_class_with_color: ~p", [dict:to_list(Sorts)]),
    Sorts;
note_class_with(color, [{H}|T], Sorts) ->
    %% ?DEBUG("H ~p", [H]),
    %% use color to key
    Color = ?v(<<"color">>, H),
    NewSorts = 
	case dict:find(Color, Sorts) of
	    error ->
		dict:store(Color, [{H}], Sorts);
	    {ok, _V} ->
		dict:update(
		  Color,
		  fun(V) ->
			  Size = ?v(<<"size">>, H),
			  {Found, NewV} = 
			      lists:foldr(
				fun({Note}, {Found, Acc}) ->
					case ?v(<<"size">>, Note) =:= Size of
					    true ->
						Exist = ?v(<<"total">>, Note),
						Added = ?v(<<"total">>, H),
						{true,
						 [{lists:keydelete(<<"total">>, 1, Note)
						   ++ [{<<"total">>, Exist + Added}]}|Acc]};
					    false ->
						{Found, [{Note}|Acc]}
					end 
				end, {fale, []}, V),
			  case Found of
			      true -> NewV;
			      fale -> [{H}] ++ V
			  end
		  end, 
		  Sorts)
	end,

    note_class_with(color, T, NewSorts).

sale_note(to_dict, [], Dict) ->
    %% ?DEBUG("sale_note_to_dict ~p", [dict:to_list(Dict)]),
    Dict;
sale_note(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand">>, H)),
    Shop  = ?to_b(?v(<<"shop">>, H)),
    %% Color = ?to_b(?v(<<"color">>, H)),
    Key = <<StyleNumber/binary, Brand/binary, Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		dict:store(Key, [{H}], Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  
			  %% lists:foldr(
			  %%   fun({Note}, Acc) ->
				    
			  %%   end, [], V)
			  [{H}] ++ V
			  %% case is_tuple(V) of
			  %%     true -> [{H}, V];
			  %%     false -> [{H}] ++ V
			  %% end
		  end,
		  Dict)
		%% dict:append(Key, {H}, Dict)
	end,

    sale_note(to_dict, T, DictNew);

sale_note(to_dict_with_rsn, [], Dict) ->
    %% ?DEBUG("sale_note_to_dict_with_rsn ~p", [dict:to_list(Dict)]),
    Dict;
sale_note(to_dict_with_rsn, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    Rsn = ?to_b(?v(<<"rsn">>, H)),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand">>, H)),
    Shop  = ?to_b(?v(<<"shop">>, H)),

    %% Color = ?v(<<"color">>, H),
    ColorName = ?v(<<"cname">>, H),    
    Size  = ?v(<<"size">>,H),
    Total = ?v(<<"total">>, H),

    Key = <<Rsn/binary,
	    <<"-">>/binary,
	    StyleNumber/binary,
	    <<"-">>/binary,
	    Brand/binary,
	    <<"-">>/binary,
	    Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		Note = [{<<"note">>, ?to_s(ColorName) ++ ?to_s(Size) ++ "/" ++ ?to_s(Total)}],
		N = proplists:delete(<<"size">>, proplists:delete(<<"color">>, H)),
		dict:store(Key, N ++ Note, Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  NewNote = ?v(<<"note">>, V) ++ ";"
			      ++ ?to_s(ColorName) ++ ?to_s(Size) ++ "/" ++ ?to_s(Total),
			  proplists:delete(<<"note">>, V) ++ [{<<"note">>, NewNote}]
		  end,
		  Dict)
	end,

    sale_note(to_dict_with_rsn, T, DictNew).

sale_trans(to_dict, [], Dict) ->
    %% ?DEBUG("sale_trans_to_Dict ~p", [dict:to_list(Dict)]),
    dict:to_list(Dict);
    %% [{_, L}] = dict:to_list(Dict),
    %% L;
sale_trans(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand_id">>, H)),
    Shop  = ?to_b(?v(<<"shop_id">>, H)),
    %% Color = ?to_b(?v(<<"color">>, H)),
    Key = <<StyleNumber/binary, Brand/binary, Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		dict:store(Key, [{H}], Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  %% ?DEBUG("V ~p", [V]),
			  NewV = 
			      lists:foldr(
				fun({Note}, Acc) ->
					%% ?DEBUG("note ~p", [Note]),
					Exist = ?v(<<"total">>, Note),
					Added = ?v(<<"total">>, H),
					[{lists:keydelete(<<"total">>, 1, Note)
					  ++ [{<<"total">>, Exist + Added}]}|Acc] 
				end, [], V),
			  NewV 
		  end,
		  Dict)
		%% dict:append(Key, {H}, Dict)
	end,

    sale_trans(to_dict, T, DictNew).    
    
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

calc_ticket_score(Ticket, TicketBalance, Merchant) ->
    case ?w_user_profile:get(score, Merchant) of
	{ok, Scores} ->
	    TicketSId = ?v(<<"sid">>, Ticket, ?INVALID_OR_EMPTY), 
	    case lists:filter(
		   fun({S})->
			   ?v(<<"type_id">>, S) =:= 1 andalso ?v(<<"id">>, S) =:= TicketSId
		   end, Scores) of
		[] ->
		    {error, ?err(wsale_invalid_ticket_score, TicketSId)}; 
		[{Score2Money}] ->
		    case TicketBalance /= ?v(<<"balance">>, Ticket) of
			true ->
			    {error, ?err(wsale_invalid_ticket_balance, TicketBalance)}; 
			false -> 
			    AccScore = ?v(<<"score">>, Score2Money), 
			    Balance = ?v(<<"balance">>, Score2Money),
			    TicketScore = TicketBalance div Balance * AccScore,
			    {ok_ticket, TicketScore} 
		    end 
	    end;
	_Error ->
	    {error, ?err(get_score_profile_filed, Merchant)}
    end.

start(new_sale, Req, {Merchant, UTable}, Invs, Base, Print) ->
    ImmediatelyPrint = ?v(<<"im_print">>, Print, ?NO),
    PMode            = ?v(<<"p_mode">>, Print, ?PRINT_BACKEND),
    Round            = ?v(<<"round">>, Base, 1),
    ShouldPay        = ?v(<<"should_pay">>, Base),
    %% RetailerId       = ?v(<<"retailer">>, Base),
    Vip              = ?v(<<"vip">>, Base, false),
    RetailerType     = ?v(<<"retailer_type">>, Base, 0),
    ShopId           = ?v(<<"shop">>, Base), 

    Datetime         = ?v(<<"datetime">>, Base),

    BaseSettings = ?w_report_request:get_setting(Merchant, ShopId),
    ?DEBUG("Shop ~p, BaseSettings ~p", [ShopId, BaseSettings]),
    SMS = ?utils:nth(1,?w_report_request:get_config(<<"consume_sms">>, BaseSettings)), 
    ?DEBUG("sms notify ~p", [SMS]), 
    CheckSale = ?utils:nth(1, ?w_report_request:get_config(<<"check_sale">>, BaseSettings)),
    ?DEBUG("check sale ~p", [CheckSale]),
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
	    case check_inventory(
		   {oncheck, Merchant, ShopId, UTable, CheckSale}, Round, 0, ShouldPay, Invs) of
		{ok, _} -> 
		    case ?w_sale:sale(new, {Merchant, UTable}, lists:reverse(Invs), Base) of 
			{ok, {RSN, Phone, _ShouldPay, Balance, Score}} ->
			    {SMSCode, _} =
				try
				    %% BaseSettings = ?w_report_request:get_setting(Merchant, ShopId), 
				    %% {ok, Retailer} = ?w_user_profile:get(
				    %% 			retailer, Merchant, RetailerId), 
				    %% SysVips  = sys_vip_of_shop(Merchant, ShopId),
				    %% ?DEBUG("SysVips ~p, Retailer ~p", [SysVips, Retailer]),
				    
				    case Vip andalso RetailerType =/= 3 andalso SMS =:= 1 of
					true ->
					    %% {ShopName, ShopSign} =
					    %% 	case ?w_user_profile:get(shop, Merchant, ShopId) of
					    %% 	    {ok, []} -> ShopId;
					    %% 	    {ok, [{Shop}]} ->
					    %% 		{?v(<<"name">>, Shop, []),
					    %% 		 ?v(<<"sign">>, Shop, [])}
					    %% 	end,
					    ?notify:sms_notify(
					       Merchant,
					       {ShopId, Phone, 1, ShouldPay, Balance, Score});
					false ->
					    %% ?w_user_profile:update(sysretailer, Merchant),
					    {0, none} 
				    end
				catch
				    _:{badmatch, _Error} ->
					?INFO("failed to send sms phone:~p, merchant ~p, Error ~p",
					      [Phone, Merchant, _Error]),
					?err(sms_send_failed, Merchant)
				end,

			    %% ?DEBUG("SMSCode ~p", [SMSCode]),

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
						  TypeId      = ?v(<<"type">>, Inv),
						  Total       = ?v(<<"sell_total">>, Inv),
						  TagPrice    = ?v(<<"tag_price">>, Inv),
						  RPrice      = ?v(<<"rprice">>, Inv), 
						  Amounts     = ?v(<<"amounts">>, Inv),

						  P = {[{<<"style_number">>, StyleNumber},
							{<<"brand_id">>, BrandId},
							{<<"type_id">>, TypeId},
							{<<"tag_price">>, TagPrice},
							{<<"rprice">>, RPrice},
							{<<"total">>, Total},
							{<<"amounts">>, Amounts}
						       ]},

						  [P|Acc] 
					  end, [], Invs),
				    print(RSN, Merchant, NewInvs, Base, Print, SuccessRespone);
				false ->
				    ?utils:respond(
				       200, Req, ?succ(new_w_sale, RSN),
				       [{<<"rsn">>, ?to_b(RSN)},
					{<<"sms_code">>, SMSCode}])
			    end;
			%% ?w_user_profile:update(retailer, Merchant); 
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
			{<<"check_pay">>, Moneny}]);
		{db_error, StyleNumber} ->
		    ?utils:respond(200, Req, ?err(db_error, StyleNumber));
		{not_enought_stock, StyleNumber} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(not_enought_stock, StyleNumber),
		       [{<<"style_number">>, StyleNumber}])
	    end
    end.

start(reject_w_sale, Req, {Merchant, UTable}, Invs, Props) ->
    case ?w_sale:sale(reject, {Merchant, UTable}, lists:reverse(Invs), Props) of 
	{{ok, RSN}, Shop, RetailerId, RetailerType, BackWithdraw} -> 
	    %% case BackWithdraw =/= 0 of
	    %% 	true ->
	    %% 	    %% query agign to obtain the correct infomation
	    %% 	    {ok, Retailer} = ?w_retailer:retailer(get, Merchant, RetailerId),
	    %% 	    {SMSCode, _} = send_sms(Merchant, 2, Shop, Retailer, BackWithdraw),
	    %% 	    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
	    %% 			   [{<<"rsn">>, ?to_b(RSN)},
	    %% 			    {<<"sms_code">>, SMSCode}]); 
	    %% 	false ->
	    %% 	    case RetailerType =:= ?SYSTEM_RETAILER of
	    %% 		true -> ?w_user_profile:update(sysretailer, Merchant);
	    %% 		false -> ok
	    %% 	    end,
	    %% 	    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
	    %% 			   [{<<"rsn">>, ?to_b(RSN)}])
	    %% end;
	    case BackWithdraw == 0
		orelse RetailerType =:= ?SYSTEM_RETAILER
		orelse RetailerType =:= ?NO_SMS_RETAILER of
		true ->
		    case RetailerType =:= ?SYSTEM_RETAILER of
			true -> ?w_user_profile:update(sysretailer, Merchant);
			false -> ok
		    end,
		    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
				   [{<<"rsn">>, ?to_b(RSN)}]);
		false ->
		    {ok, Retailer} = ?w_retailer:retailer(get, Merchant, RetailerId),
		    {SMSCode, _} = send_sms(Merchant, 2, Shop, Retailer, BackWithdraw),
		    ?utils:respond(200, Req, ?succ(reject_w_sale, RSN),
				   [{<<"rsn">>, ?to_b(RSN)},
				    {<<"sms_code">>, SMSCode}])
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.
    
check_inventory({oncheck, _Merchant, _Shop, _UTable, _CheckSale}, Round, Moneny, ShouldPay, []) ->
    ?DEBUG("Moneny ~p, ShouldPay, ~p", [Moneny, ShouldPay]),
    case Round of
	1 -> 
	    case round(Moneny) == ShouldPay of
		true -> {ok, none};
		false -> {error, round(Moneny), ShouldPay}
	    end;
	0 ->
	    case ?to_f(Moneny) == ShouldPay of
		true -> {ok, none};
		false -> {error, Moneny, ShouldPay}
	    end
    end;

check_inventory(
  {oncheck, Merchant, Shop, UTable, CheckSale}, Round, Money, ShouldPay, [{struct, Inv}|T]) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand = ?v(<<"brand">>, Inv), 
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
    %% ?DEBUG("StyleNumber ~p", [StyleNumber]),
    %% ?DEBUG("count ~p, DCount ~p", [Count, DCount]),
    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true ->
		    case CheckSale of
			?YES ->
			    Sql = "select style_number, brand, amount, shop, merchant"
				" from" ++ ?table:t(stock, Merchant, UTable)
				++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
				++ " and brand=" ++ ?to_s(Brand)
				++ " and shop=" ++ ?to_s(Shop)
				++ " and merchant=" ++ ?to_s(Merchant),
			    case ?sql_utils:execute(s_read, Sql) of
				{ok, Stock} ->
				    case ?v(<<"amount">>, Stock) < Count of
					true -> {not_enought_stock, StyleNumber};
					false ->
					    check_inventory(
					      {oncheck, Merchant, Shop, UTable, CheckSale},
					      Round,
					      Money + Calc,
					      ShouldPay,
					      T)
				    end;
				{error, _Error} ->
				    {db_error, StyleNumber}
			    end;
			?NO ->
			    check_inventory(
			      {oncheck, Merchant, Shop, UTable, CheckSale},
			      Round,
			      Money + Calc,
			      ShouldPay,
			      T)
		    end;
		false ->
		    {error, Inv}
	    end
    end.


calc_count(reject, [], Total) ->
    Total;
calc_count(reject, [{struct, Inv}|T], Total) ->
    InvTotal = ?v(<<"sell_total">>, Inv),
    calc_count(reject, T, Total + InvTotal).
    
    
mode(0) -> use_id;
mode(1) -> use_shop;
mode(2) -> use_brand;
mode(3) -> use_firm.

replace_condition_with_ctype(Merchant, CType, SType, Fields, Payload) ->
    P = proplists:delete(<<"fields">>, Payload), 
    case SType of
	undefined ->
	    case CType of
		undefined -> Payload; 
		_ ->
		    PN = proplists:delete(<<"type">>, proplists:delete(<<"ctype">>, Fields)),
		    case ?attr:type(get, Merchant, [{<<"ctype">>, CType}]) of
			{ok, []} ->
			    [{<<"fields">>, {struct, PN}} |P];
			{ok, Types}  ->
			    [{<<"fields">>,
			      {struct,
			       [{<<"type">>,
				 lists:foldr(
				   fun({Type}, Acc) ->
					   [?v(<<"id">>, Type)|Acc]
				   end, [], Types)}|PN]}} |P] 
		    end
	    end;
	_ ->
	    [{<<"fields">>, {struct, proplists:delete(<<"ctype">>, Fields)}}|P]
    end.

replace_condition_with_ctype(Merchant, CType, SType, Payload) ->
    case SType of
	undefined ->
	    case CType of
		undefined -> Payload; 
		_ ->
		    case ?attr:type(get, Merchant, [{<<"ctype">>, CType}]) of
			{ok, []} ->
			    Payload;
			{ok, Types}  -> 
			    AllType = 
				[{<<"type">>,
				  lists:foldr(
				    fun({T}, Acc) ->
					    [?v(<<"id">>, T)|Acc] end, [], Types)}],
			    proplists:delete(<<"ctype">>, Payload) ++ AllType
		    end
	    end;
	_ ->
	    proplists:delete(<<"ctype">>, Payload)
    end.
    
replace_condition_with_lbrand(?AND, _Merchant, _Brand, _Fields, Payload) ->
    Payload;
    %% P = proplists:delete(<<"fields">>, Payload),
    %% PN = proplists:delete(<<"lbrand">>, Fields),
    %% [{<<"fields">>, {struct, PN}} |P];
        
replace_condition_with_lbrand(?LIKE, Merchant, Brand, Fields, Payload) ->
    P = proplists:delete(<<"fields">>, Payload),
    case Brand of
	undefined ->
	    Payload; 
	_ -> 
	    PN = proplists:delete(<<"brand">>, Fields),
	    case ?attr:brand(like, Merchant, Brand) of
		{ok, []} ->
		    [{<<"fields">>, {struct, PN}} |P];
		{ok, Brands} ->
		    [{<<"fields">>,
		      {struct,
		       [{<<"brand">>,
			 lists:foldr(
			   fun({B}, Acc) ->
				   [?v(<<"id">>, B)|Acc]
			   end, [], Brands)}|PN]}} |P] 
	    end
	%% _ ->
	%%     [{<<"fields">>, {struct, proplists:delete(<<"lbrand">>, Fields)}}|P]
    end.

sys_vip_of_shop(Merchant, Shop) ->
    %% {ok, Settings} = ?w_user_profile:get(setting, Merchant, Shop),
    %% SysVips =
    %% 	lists:foldr(
    %% 	  fun({S}, Acc) ->
    %% 		  case ?v(<<"ename">>, S) =:= <<"s_customer">> of
    %% 		      true ->
    %% 			  SysVip = ?to_i(?v(<<"value">>, S)),
    %% 			  case lists:member(SysVip, Acc) of
    %% 			      true -> Acc;
    %% 			      false -> [SysVip] ++ Acc
    %% 			  end;
    %% 		      false -> Acc
    %% 		  end
    %% 	  end, [], Settings),
    %% SysVips.
    {ok, SysVips} = ?w_user_profile:get(sys_retailer, Merchant),
    SimpleSysVips = [?v(<<"id">>, S) || {S} <- SysVips, ?v(<<"shop_id">>, S) =:= Shop],
    ?DEBUG("SimpleSysVips ~p", [SimpleSysVips]),
    SimpleSysVips.

send_sms(Merchant, Action, ShopId, Retailer, ShouldPay) ->
    try 
	%% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),
	%% {ShopName, ShopSign} = case ?w_user_profile:get(shop, Merchant, ShopId) of
	%% 			   {ok, []} -> [];
	%% 			   {ok, [{Shop}]} ->
	%% 			       {?v(<<"name">>, Shop, []), ?v(<<"sign">>, Shop, [])}
	%% 		       end,
	%% {ok, Retailer} = ?w_retailer:get(retailer, Merchant, RetailerId),
	RetailerId = ?v(<<"id">>, Retailer),
	Phone = ?v(<<"mobile">>, Retailer, []),
	Balance = ?v(<<"balance">>, Retailer),
	Score = ?v(<<"score">>, Retailer),
	
	SysVips  = sys_vip_of_shop(Merchant, ShopId), 
	%% ?DEBUG("SysVips ~p, Retailer ~p", [SysVips, Retailer]),
	BaseSettings = ?w_report_request:get_setting(Merchant, ShopId),
	SMS = case ?w_report_request:get_config(<<"consume_sms">>, BaseSettings) of
		  [] -> 0;
		  V -> ?to_i(V)
	      end,

	?DEBUG("sms notify ~p", [SMS]),
	
	case not lists:member(RetailerId, SysVips)
	    andalso ?v(<<"type_id">>, Retailer) /= ?SYSTEM_RETAILER andalso SMS == ?YES of
	    true -> 
		?notify:sms_notify(
		   Merchant,
		   {ShopId, Phone, Action, abs(ShouldPay), Balance, Score});
	    false -> {0, none} 
	end
    catch
	_:{badmatch, _Error} ->
	    ?INFO("failed to send sms phone:~p, merchant ~p, Error ~p", [?v(<<"id">>, Retailer), Merchant, _Error]),
	    ?err(sms_send_failed, Merchant)
    end.
	    
