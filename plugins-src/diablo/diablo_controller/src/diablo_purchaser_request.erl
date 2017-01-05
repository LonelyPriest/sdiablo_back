-module(diablo_purchaser_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([authen/2, authen_shop_action/2, filter_condition/3]).

-define(d, ?utils:seperator(csv)).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    %% ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = purchaser_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "purchaserApp"},
			  %% {ngcontroller, "purchaserCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"get_w_inventory_new", RSN}) ->
    ?DEBUG("get_w_inventory_new whith Session ~p, RSN ~p", [Session, RSN]),
    Merchant = ?session:get(merchant, Session), 
    object_responed(
      fun() ->
	      ?w_inventory:purchaser_inventory(get_new, Merchant, RSN)
      end, Req);
    
action(Session, _Req, Unkown) ->
    ?DEBUG("receive unkown message ~p with session~n~p", [Unkown, Session]).


%% =============================================================================
%% new
%% =============================================================================
action(Session, Req, {"new_w_inventory"}, Payload) ->
    ?DEBUG("new purchaser inventory with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload), 
    Datetime = ?v(<<"datetime">>, Base), 
    CurrentDate = ?utils:current_time(format_localtime), 
    %% Date = ?utils:to_date(datetime, Datetime),
    
    case ?utils:to_date(datetime, Datetime) /= ?utils:to_date(datetime, CurrentDate) of
	true ->
	    ?utils:respond(200,
			   Req,
			   ?err(invalid_date, "new_w_inventory"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, CurrentDate}]);
	false -> 
	    case ?w_inventory:purchaser_inventory(
		    new, Merchant, lists:reverse(Invs), Base) of
		{ok, RSn} -> 
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(add_purchaser_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
		{invalid_balance, {Firm, CurrentBalance, LastBalance}} ->
		    ?utils:respond(200,
				   Req,
				   ?err(invalid_balance, Firm),
				   [{<<"cbalance">>, CurrentBalance},
				    {<<"lbalance">>, LastBalance}]);
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

action(Session, Req, {"update_w_inventory"}, Payload) ->
    ?DEBUG("update purchaser inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),

    %% Datetime = ?v(<<"datetime">>, Base), 
    %% CurrentDate = ?utils:current_time(format_localtime),

    %% case ?utils:to_date(datetime, Datetime) /= ?utils:to_date(datetime, CurrentDate) of
    %% 	true ->
    %% 	    ?utils:respond(200,
    %% 			   Req,
    %% 			   ?err(invalid_date, "update_w_inventory"),
    %% 			   [{<<"fdatetime">>, Datetime},
    %% 			    {<<"bdatetime">>, CurrentDate}]);
    %% 	false -> 
    RSN = ?v(<<"rsn">>, Base), 
    {ok, OldBase} = ?w_inventory:purchaser_inventory(get_new, Merchant, RSN),

    case ?w_inventory:purchaser_inventory(
	    update, Merchant, lists:reverse(Invs), {Base, OldBase}) of
	{ok, RSn} -> 
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(update_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
    %% end;

action(Session, Req, {"comment_w_inventory_new"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload),
    Comment = ?v(<<"comment">>, Payload, []),
    case ?w_inventory:purchaser_inventory(comment, Merchant, RSN, Comment) of
    	{ok, RSn} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(update_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"check_w_inventory"}, Payload) ->
    ?DEBUG("check purchaser inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?CHECK),
    
    case ?w_inventory:purchaser_inventory(check, Merchant, RSN, Mode) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req,
	       ?succ(check_w_inventory, RSN), {<<"rsn">>, ?to_b(RSN)});
	{error, {zero_org_price, _R}} ->
	    ?utils:respond(
               200,
               Req,
               ?err(zero_price_of_check, RSN));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"del_w_inventory"}, Payload) ->
    ?DEBUG("delete inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?DELETE), 

    case ?w_inventory:purchaser_inventory(delete_new, Merchant, RSN, Mode) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req,
	       ?succ(delete_w_inventory, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_inventory_new"}, Payload) -> 
    ?DEBUG("filter_w_inventory_new with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 
    {struct, Fields} = ?v(<<"fields">>, Payload),
    SortMode = ?v(<<"mode">>, Payload, ?SORT_BY_ID),
    %% SortMode = ?v(<<"mode">>, Payload, ?SORT_BY_DATE), 
    NewPayload = proplists:delete(<<"mode">>, Payload),

    %% case
    %% 	case ?utils:v(style_number, string, ?v(<<"style_number">>, Fields))
    %% 	    ++ ?utils:v(brand, integer, ?v(<<"brand">>, Fields)) of
    %% 	    [] -> {ok, []}; 
    %% 	    _ ->
    %% 		?w_inventory:purchaser_inventory(get_inventory_new_rsn, Merchant, Fields)
    %% 	end
    %% of
    %% 	{ok, RSNs} ->
    %% 	    NewConditions =
    %% 		[{<<"fields">>, 
    %% 		    {struct, lists:keydelete(<<"style_number">>, 1,
    %% 				lists:keydelete(<<"brand">>, 1, Fields))
    %% 		     ++ case RSNs of
    %% 			    [] -> []; 
    %% 			    _ -> [{<<"rsn">>, lists:foldr(
    %% 					fun({RSN}, Acc) ->
    %% 						[?v(<<"rsn">>, RSN)|Acc]
    %% 					end, [], RSNs)}]
    %% 			end
    %% 		    }
    %% 		 }] ++ lists:keydelete(<<"fields">>, 1, Payload),

    %% 	    ?DEBUG("new conditions ~p", [NewConditions]),

    %% 	    ?pagination:pagination(
    %% 	       fun(Match, Conditions) ->
    %% 		       ?w_inventory:filter(
    %% 			  total_news, ?to_a(Match), Merchant, Conditions)
    %% 	       end,
    %% 	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
    %% 		       ?w_inventory:filter(
    %% 			  news, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
    %% 	       end, Req, NewConditions);
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end;

    NewFields =
	case ?utils:v(style_number, string, ?v(<<"style_number">>, Fields))
	    ++ ?utils:v(brand, integer, ?v(<<"brand">>, Fields)) of
	    [] -> {ok,
		   [{<<"fields">>, {struct, Fields}}]
		   ++ lists:keydelete(<<"fields">>, 1, NewPayload)}; 
	    _ ->
		case ?w_inventory:purchaser_inventory(get_inventory_new_rsn, Merchant, Fields) of
		    {ok, []} -> {ok, []};
		    {ok, RSNs} ->
			{ok,
			 [{<<"fields">>, 
			   {struct, lists:keydelete(<<"style_number">>, 1,
						    lists:keydelete(<<"brand">>, 1, Fields))
			    ++ [{<<"rsn">>, lists:foldr(
					      fun({RSN}, Acc) ->
						      [?v(<<"rsn">>, RSN)|Acc]
					      end, [], RSNs)}]
			   }
			  }] ++ lists:keydelete(<<"fields">>, 1, NewPayload)};
		    Error -> Error
		end
	end,

    ?DEBUG("NewFields ~p", [NewFields]),

    case NewFields of
	{ok, []} ->
	    ?utils:respond(
	       200, object, Req, {[{<<"ecode">>, 0}, {<<"total">>, 0}, {<<"data">>, []}]});
	{ok, NewConditions} ->
	    	    ?pagination:pagination(
	    	       fun(Match, Conditions) ->
	    		       ?w_inventory:filter(
	    			  total_news, ?to_a(Match), Merchant, Conditions)
	    	       end,
	    	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	    		       ?w_inventory:filter(
	    			  {news, SortMode},
				  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
	    	       end, Req, NewConditions);
	{error, ErrorS} ->
	    ?utils:respond(200, Req, ErrorS)
    end;


action(Session, Req, {"list_w_inventory_new_detail"}, Payload) ->
    ?DEBUG("list_w_inventory_new_detail with session ~p, paylaod ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    case ?w_inventory:purchaser_inventory(list_new_detail, Merchant, Payload) of
	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_inventory_flow"}, Payload) ->
    ?DEBUG("list_w_inventory_flow with session ~p, paylaod ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    
    try
	{ok, NewDetails} = ?w_inventory:purchaser_inventory(trace_new, Merchant, Payload),
	?DEBUG("NewDetails ~p", [NewDetails]),
	{ok, SellDetails} = ?w_sale:sale(trace, Merchant, Payload),
	?DEBUG("SellDetails ~p", [SellDetails]),
	{ok, TransferDetail} = ?w_inventory:purchaser_inventory(trace_transfer, Merchant, Payload),
	?DEBUG("TransferDetail ~p", [TransferDetail]),

	?utils:respond(200, object, Req,
		       {[{<<"ecode">>, 0},
			 {<<"new">>, NewDetails},
			 {<<"sell">>, SellDetails},
			 {<<"transfer">>, TransferDetail}
			]})
    catch
	_:{badmatch, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

    %% case ?w_inventory:purchaser_inventory(flow, Merchant, Payload) of
    %% 	{ok, Details} ->
    %% 	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
    %% 					       {<<"data">>, Details}]}); 
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end;

action(Session, Req, {"list_w_inventory_info"}, Payload) ->
    ?DEBUG("list_w_inventory_info with session ~p, paylaod ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    case ?w_inventory:purchaser_inventory(list_inventory_info, Merchant, Payload) of
	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_w_inventory_new_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_inventory_new_rsn_group with session ~p, paylaod~n~p", [Session, Payload]),

    Merchant  = ?session:get(merchant, Session), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_new_rsn_groups, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  new_rsn_groups, Match, Merchant,
		  CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"w_inventory_new_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_rsn_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(new_rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_inventory_new_amount"}, Payload) ->
    ?DEBUG("get_new_amount_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:purchaser_inventory(
	    get_new_amount, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_w_inventory_tagprice"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Shop = ?v(<<"shop">>, Payload),
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand = ?v(<<"brand">>, Payload),
    
    case ?w_inventory:purchaser_inventory(
	    tag_price, Merchant, Shop, StyleNumber, Brand) of 
    	{ok, Detail} ->
	    %% ?DEBUG("detail ~p", [Detail]),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, {Detail}}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

    
%% =============================================================================
%% reject
%% =============================================================================
action(Session, Req, {"reject_w_inventory"}, Payload) ->
    ?DEBUG("reject purchasr inventory with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base} = ?v(<<"base">>, Payload),

    Datetime = ?v(<<"datetime">>, Base), 
    CurrentDatetime = ?utils:current_time(format_localtime),

    case ?utils:to_date(datetime, Datetime) /= ?utils:to_date(datetime, CurrentDatetime) of
	true ->
	    ?utils:respond(200,
			   Req,
			   ?err(invalid_date, "update_w_inventory"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, CurrentDatetime}]);
	false -> 
	    case ?w_inventory:purchaser_inventory(reject, Merchant, lists:reverse(Invs), Base) of 
		{ok, RSn} ->
		    ?utils:respond(
		       200, Req,
		       ?succ(reject_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
		{invalid_balance, {Firm, CurrentBalance, LastBalance}} ->
		    ?utils:respond(200,
				   Req,
				   ?err(invalid_balance, Firm),
				   [{<<"cbalance">>, CurrentBalance},
				    {<<"lbalance">>, LastBalance}]);
		{error, Error} ->
		    ?utils:respond(200, Req, Error) 
	    end
    end;

%% =============================================================================
%% inventory
%% ============================================================================= 
action(Session, Req, {"filter_w_inventory_group"}, Payload) -> 
    ?DEBUG("filter_w_inventory_group with session ~p, paylaod~n~p",
	   [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    {struct, Mode}     = ?v(<<"mode">>, Payload),
    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode),

    %% {struct, P}  = ?v(<<"fields">>, Payload),

    %% Order = ?v(<<"order">>, P),
    NewPayload = proplists:delete(<<"mode">>, Payload),
    %% 	++ [{<<"fields">>, {struct, proplists:delete(<<"order">>, P)}}],
    %% ?DEBUG("new payload ~p", [NewPayload]),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(total_groups, Match, Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  {groups, mode(Order), Sort},
		  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, NewPayload); 

action(Session, Req, {"list_w_inventory"}, Payload) ->
    ?DEBUG("list purchaser inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(
      fun() -> ?w_inventory:purchaser_inventory(list, Merchant, Payload) end, Req);

%% =============================================================================
%% fix
%% =============================================================================
action(Session, Req, {"fix_w_inventory"}, Payload) ->
    ?DEBUG("fix_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),
    case ?w_inventory:purchaser_inventory(
	    fix, Merchant, lists:reverse(Invs), Base) of 
    	{ok, RSn} ->
	    ?utils:respond(200,
			   Req,
			   ?succ(fix_w_inventory, RSn),
			   {<<"rsn">>, ?to_b(RSn)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_fix_w_inventory"}, Payload) -> 
    ?DEBUG("filter_fix_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_fix, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  fix, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_w_inventory_fix_rsn_group"}, Payload) ->
    ?DEBUG("filter_w_inventory_fix_rsn_group with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant  = ?session:get(merchant, Session),
    
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_fix_rsn_groups, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_inventory:filter(
		  fix_rsn_groups, Match, Merchant,
		  CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);
    

action(Session, Req, {"w_inventory_fix_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_rsn_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(fix_rsn, Merchant, Payload) of 
    	{ok, Details} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]}); 
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

%% =============================================================================
%% transfer
%% =============================================================================
action(Session, Req, {"transfer_w_inventory"}, Payload) ->
    ?DEBUG("transfer purchasr inventory with session~n~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload),
    {struct, Base} = ?v(<<"base">>, Payload),
    case ?w_inventory:purchaser_inventory(transfer, Merchant, lists:reverse(Invs), Base) of
        {ok, RSn} ->
            ?utils:respond(200, Req, ?succ(transfer_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
        {error, Error} ->
            ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"filter_transfer_w_inventory"}, Payload) ->
    ?DEBUG("filter_transfer_w_inventory with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
               ?w_inventory:filter(total_transfer, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
               ?w_inventory:filter(
                  transfer, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"filter_transfer_rsn_w_inventory"}, Payload) ->
    ?DEBUG("filter_transfer_rsn_w_inventory with session ~p~n, paylaod~n~p",
           [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_inventory:filter(
		  total_transfer_rsn_groups, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
               ?w_inventory:filter(
                  transfer_rsn_groups,
                  Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);


action(Session, Req, {"w_inventory_transfer_rsn_detail"}, Payload) ->
    ?DEBUG("w_inventory_transfer_rsn_detail with session ~p~n, paylaod~n~p",
           [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% RSn = ?v(<<"rsn">>, Payload),
    case ?w_inventory:rsn_detail(transfer_rsn, Merchant, Payload) of
        {ok, Details} ->
            ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
                                               {<<"data">>, Details}]});
        {error, Error} ->
            ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"check_w_inventory_transfer"}, Payload) ->
    ?DEBUG("check_w_inventory_transfer with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% RSN = ?v(<<"rsn">>, Payload),
    %% TShop = ?v(<<"tshop">>, Payload), 
    case ?w_inventory:purchaser_inventory(check_transfer, Merchant, Payload) of
        {ok, RSN} ->
            ?utils:respond(
               200,
               Req,
               ?succ(check_w_inventory_transfer, RSN),
               {<<"rsn">>, ?to_b(RSN)});
        {error, Error} ->
            ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"cancel_w_inventory_transfer"}, Payload) ->
    ?DEBUG("cancel_w_inventory_transfer with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    %% RSN = ?v(<<"rsn">>, Payload),
    %% TShop = ?v(<<"tshop">>, Payload), 
    case ?w_inventory:purchaser_inventory(cancel_transfer, Merchant, RSN) of
        {ok, RSN} ->
            ?utils:respond(
               200,
               Req,
               ?succ(cancel_w_inventory_transfer, RSN),
               {<<"rsn">>, ?to_b(RSN)});
        {error, Error} ->
            ?utils:respond(200, Req, Error)
    end;


%% =============================================================================
%% match
%% =============================================================================
action(Session, Req, {"match_all_w_inventory"}, Payload) ->
    ?DEBUG("match_all_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    NewPayload = proplists:delete(<<"shop">>, Payload),
    batch_responed(
      fun() -> ?w_inventory:match(
		  inventory, all_inventory, Merchant, Shop, NewPayload)
      end, Req);

action(Session, Req, {"match_all_reject_w_inventory"}, Payload) ->
    ?DEBUG("match_all_reject_w_inventory with session ~p, paylaod~n~p",
	   [Session, Payload]),
    Merchant   = ?session:get(merchant, Session),
    Shop       = ?v(<<"shop">>, Payload),
    Firm       = ?v(<<"firm">>, Payload, []),
    QType      = ?v(<<"type">>, Payload, 0),
    StartTime  = ?v(<<"start_time">>, Payload),

    batch_responed(
      fun() -> ?w_inventory:match(
		  all_reject_inventory, QType, Merchant, Shop, Firm, StartTime) end, Req);


action(Session, Req, {"match_w_inventory"}, Payload) ->
    ?DEBUG("match_w_inventory with session ~p~npayload ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"prompt">>, Payload),
    Shop        = ?v(<<"shop">>, Payload),
    Firm        = ?v(<<"firm">>, Payload),
    QType       = ?v(<<"type">>, Payload, 0),

    Match = fun() when Firm =:= undefined->
		    ?w_inventory:match(
		       inventory, QType, Merchant, StyleNumber, Shop);
	       () ->
		    ?w_inventory:match(
		       inventory, QType, Merchant, StyleNumber, Shop, Firm)
	    end,
    
    batch_responed(Match, Req);

action(Session, Req, {"w_inventory_export"}, Payload) ->
    ?DEBUG("w_inventory_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),

    {struct, Conditions} = ?v(<<"condition">>, Payload),
    
    {struct, Mode}     = ?v(<<"mode">>, Payload, []),

    UseMode = 
	case ?v(<<"mode">>, Payload) of
	    undefined -> [];
	    {struct, Mode} ->
		Order = ?v(<<"mode">>, Mode),
		Sort  = ?v(<<"sort">>, Mode),
		[{<<"mode">>, mode(Order)}, {<<"sort">>, Sort}]
	end,

    NewConditions = 
	case ExportType of
	    trans_note ->
		{struct, CutConditions} = ?v(<<"condition">>, Payload),
		{ok, Q} = ?w_inventory:purchaser_inventory(
			     get_inventory_new_rsn, Merchant, CutConditions),
		{struct, C} =
		    ?v(<<"fields">>,
		       filter_condition(
			 trans_note,
			 [?v(<<"rsn">>, Rsn) || {Rsn} <- Q],
			 CutConditions)),
		C;
	    trans -> Conditions;
	    stock -> Conditions
	end,


    case ?w_inventory:export(ExportType, Merchant, NewConditions, UseMode) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
	{ok, Transes} -> 
	    %% write to file 
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("itrans", Merchant, UserId), 
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

action(Session, Req, {"set_w_inventory_promotion"}, Payload) ->
    ?DEBUG("set_w_inventory_promotion with session ~p~n, paylaod ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Conditions} = ?value(<<"condition">>, Payload),
    Promotion = ?v(<<"promotion">>, Payload),
    Score     = ?v(<<"score">>, Payload),
    
    case ?w_inventory:purchaser_inventory(
	    set_promotion, Merchant, [{<<"promotion">>, Promotion},
				      {<<"score">>, Score}], Conditions) of
	{ok, _} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(set_w_inventory_promotion, Merchant));
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_inventory_batch"}, Payload) ->
    ?DEBUG("update_w_inventory_batch with session ~p~n, paylaod ~p",
	   [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Conditions} = ?value(<<"condition">>, Payload),
    {struct, Attrs} = ?value(<<"attrs">>, Payload, []),
    
    case ?w_inventory:purchaser_inventory(
	    update_batch, Merchant, Attrs , Conditions) of
	{ok, Merchant} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(update_w_inventory_batch, Merchant));
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"adjust_w_inventory_price"}, Payload) ->
    ?DEBUG("adjust_w_inventory_price with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Invs = ?v(<<"inventory">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),

    case ?w_inventory:purchaser_inventory(adjust_price, Merchant, Invs, Base) of
    	{ok, Merchant} -> 
    	    ?utils:respond(
	       200,
	       Req,
	       ?succ(adjust_w_inventory_price, Merchant));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end.



sidebar(Session) ->
    UserType = ?session:get(type, Session),
    
    case ?right_request:get_shops(Session, inventory) of
	[] ->
	    ?menu:sidebar(level_1_menu,[]);
	Shops ->
	    Record = authen_shop_action(
		       {?new_w_inventory,
			"inventory_new",
			"采购入库",
			"glyphicon glyphicon-shopping-cart"}, Shops),

	    Reject = authen_shop_action(
		       {?reject_w_inventory,
			"inventory_reject",
			"采购退货", "glyphicon glyphicon-arrow-left"}, Shops),

	    TransR = [{"inventory_new_detail", "采购记录", "glyphicon glyphicon-download"}],
	    TransD = [{"inventory_rsn_detail", "采购明细", "glyphicon glyphicon-map-marker"}], 
	    InvDetail = [{"inventory_detail", "库存详情", "glyphicon glyphicon-book"}], 
		
	    InvPrice =
		case ?right_auth:authen(?adjust_w_inventory_price, Session) of
		    {ok, ?adjust_w_inventory_price} ->
			[{"inventory_price", "库存调价", "glyphicon glyphicon-sort"}]; 
		    _ -> []
		end, 
	    %% InvPrice = [{"inventory_price", "库存调价", "glyphicon glyphicon-sort"}],

	    Transfer =
                [
                 {{"inventory", "调入调出", "glyphicon glyphicon-transfer"},
                  authen_shop_action(
                    {?transfer_w_inventory, 
                     "inventory_transfer",
                     "调出",
                     "glyphicon glyphicon-transfer"},
                    Shops)
                  ++ [{"inventory_transfer_from_detail",
                       "调出记录",
                       "glyphicon glyphicon-circle-arrow-left"},
                      {"inventory_transfer_to_detail",
                       "调入记录",
                       "glyphicon glyphicon-circle-arrow-right"},

                      {"inventory_rsn_detail/transfer_from",
                       "调出明细",
                       "glyphicon glyphicon-superscript"},
                      {"inventory_rsn_detail/transfer_to",
                       "调入明细",
                       "glyphicon glyphicon-subscript"}
                      ]
                 }],

	    InvMgr =
		[{{"inventory", "库存盘点", "glyphicon glyphicon-check"},
		  case UserType of
		      ?MERCHANT ->
			  [{"inventory_fix", "盘点", "glyphicon glyphicon-check"}];
		      _ -> []
		  end
			      
		  %% authen_shop_action(
		  %%   {?fix_w_inventory,
		  %%    "inventory_fix",
		  %%    "盘点", "glyphicon glyphicon-check"}, Shops) 
		  ++ [{"inventory_fix_detail",
		       "盘点记录", "glyphicon glyphicon-tasks"},
		      {"inventory_rsn_detail/fix",
		       "盘点明细", "glyphicon glyphicon-leaf"}] 
		 }],

	    GoodMgr = [{{"good", "货品资料",
			 "glyphicon glyphicon-headphones"},
			case ?right_auth:authen(?new_w_good, Session) of
			    {ok, ?new_w_good} ->
				[{"wgood_new",
				  "新增货品", "glyphicon glyphicon-plus"}];
			    _ -> []
			end
			++ [{"wgood_detail",
			     "货品详情", "glyphicon glyphicon-book"},
			    {"size",
			     "尺码", "glyphicon glyphicon-text-size"},
			    {"color", "颜色",
			     "glyphicon glyphicon-font"}]
		       }],


	    PromotionMgr =
		[{{"promotion", "促销定价",
		   "glyphicon glyphicon-superscript"},
		  case ?right_auth:authen(?new_w_promotion, Session) of
		      {ok, ?new_w_promotion} ->
			  [{"promotion_new",
			    "新增方案", "glyphicon glyphicon-plus"}];
		      _ -> []
		  end 
		  ++ case ?right_auth:authen(?list_w_promotion, Session) of
			 {ok, ?list_w_promotion} ->
			     [{"promotion_detail",
			       "方案详情", "glyphicon glyphicon-book"}];
			 _ -> []
		     end 
		 }],

	    Level1 = ?menu:sidebar(
			level_1_menu,
			Record ++ Reject ++ TransR ++ TransD ++ InvDetail ++ InvPrice),
	    Level2 = ?menu:sidebar(
			level_2_menu, InvMgr ++ Transfer ++ GoodMgr ++ PromotionMgr),

	    Level1 ++ Level2
    end.

authen_shop_action({Action, Path, Name}, Shops) ->
    case ?inventory_request:shop_action(Action, Shops) of
	[] -> [];
	_  -> [{Path, Name}]
    end;

authen_shop_action({Action, Path, Name, Icon}, Shops) ->
    case ?inventory_request:shop_action(Action, Shops) of
	[] -> [];
	_  -> [{Path, Name, Icon}]
    end.

authen(Actions, Session) ->
    authen(Actions, Session, []).
authen([], _Session, Acc) ->
    lists:reverse(Acc);
authen([Action|T], Session, Acc) ->
    {Id, Path, Desc} = Action,
    case ?right_auth:authen(Id, Session) of
	{ok, Id} ->
	    authen(T, Session, [{Path, Desc}|Acc]);
	_ ->
	    authen(T, Session, Acc)
    end.

batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

object_responed(Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {Value});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

filter_condition(trans_note, [], _Conditions) ->
    [];
filter_condition(trans_note, Rsns, Conditions) ->
    [{<<"fields">>, {
	  struct, [{<<"rsn">>, Rsns}]
	  ++ lists:foldr(
	       fun({<<"style_number">>, _}=S, Acc) ->
		       [S|Acc];
		  ({<<"brand">>, _}=B, Acc) ->
		       [B|Acc];
		  ({<<"firm">>, _}=F, Acc) ->
		       [F|Acc];
		  ({<<"type">>, _}=T, Acc) ->
		       [T|Acc];
		  ({<<"year">>, _}=Y, Acc) ->
		       [Y|Acc];
		  (_, Acc) ->
		       Acc
	       end, [], Conditions)}}].


csv_head(trans, Do) ->
    H = "序号,单号,厂商,门店,入单员,采购,数量,现金,刷卡,汇款,核销,费用,帐户欠款,应付,实付,本次欠款,备注,日期",
    UTF8 = unicode:characters_to_list(H, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK);
csv_head(trans_note, Do) ->
    H = "序号,单号,厂商,门店,店员,交易类型,款号,品牌,类型,折扣,数量,日期",
    UTF8 = unicode:characters_to_list(H, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK);
csv_head(stock, Do) ->
    H = "序号,款号,品牌,类别,性别,厂商,季节,年度,吊牌价,折扣,进价,进折扣,数量,店铺,上架日期",
    UTF8 = unicode:characters_to_list(H, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK). 

do_write(trans, _Do, _Count, [])->
    ok;
do_write(trans, Do, Count, [H|T]) ->
    Rsn       = ?v(<<"rsn">>, H),
    Firm      = ?v(<<"firm">>, H),
    Shop      = ?v(<<"shop">>, H),
    Employee  = ?v(<<"employee">>, H),
    Type      = ?v(<<"type">>, H), 
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
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ purchaser_type(Type) ++ ?d 
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
    %% Do(L),
    UTF8 = unicode:characters_to_list(L, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK),
    do_write(trans, Do, Count + 1, T);

do_write(trans_note, _Do, _Count, [])->
    ok;
do_write(trans_note, Do, Count, [H|T]) ->
    Rsn         = ?v(<<"rsn">>, H),
    Firm        = ?v(<<"firm">>, H), 
    Shop        = ?v(<<"shop">>, H),
    Employee    = ?v(<<"employee">>, H),
    InType        = ?v(<<"in_type">>, H),

    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Total       = ?v(<<"total">>, H), 

    %% Color       = ?v(<<"color">>, H),
    %% Size        = ?v(<<"size">>, H),
    Discount   = ?v(<<"discount">>, H),
    %% FPrice      = ?v(<<"fprice">>, H),

    %% Comment   = ?v(<<"comment">>, H),
    Date      = ?v(<<"entry_date">>, H),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ purchaser_type(InType) ++ ?d
	
	++ ?to_s(StyleNumber) ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	
    %% ++ ?to_s(Color) ++ ?d
    %% ++ ?to_s(Size) ++ ?d
    %% ++ ?to_s(FPrice) ++ ?d 
    %% ++ ?to_s(FDiscount) ++ ?d
	++ ?to_s(Discount) ++ ?d 
	++ ?to_s(Total) ++ ?d
    %% ++ ?to_s(Calc) ++ ?d 
    %% ++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
    %% ++ ?to_s(Date),
    
    UTF8 = unicode:characters_to_list(L, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK),
    
    do_write(trans_note, Do, Count + 1, T);

do_write(stock, _Do, _Count, [])->
    ok;
do_write(stock, Do, Count, [H|T]) ->
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    %% Color       = ?v(<<"color">>, H),
    %% Size        = ?v(<<"size">>, H),
    Sex         = ?v(<<"sex">>, H),
    
    Firm        = ?v(<<"firm">>, H), 
    Shop        = ?v(<<"shop">>, H),
    Season      = ?v(<<"season">>, H),
    Year        = ?v(<<"year">>, H),

    OrgPrice    = ?v(<<"org_price">>, H),
    EDiscount   = ?v(<<"ediscount">>, H),
    TagPrice    = ?v(<<"tag_price">>, H), 
    Discount    = ?v(<<"discount">>, H), 
    Total       = ?v(<<"amount">>, H), 

    Date      = ?v(<<"entry_date">>, H),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ "\'" ++ string:strip(?to_s(StyleNumber)) ++ "\'" ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d 
	++ sex(Sex) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ season(Season) ++ ?d
	++ ?to_s(Year) ++ ?d
	++ ?to_s(TagPrice) ++ ?d
	++ ?to_s(Discount) ++ ?d
	++ ?to_s(OrgPrice) ++ ?d
	++ ?to_s(EDiscount) ++ ?d 
	++ ?to_s(Total) ++ ?d
	
	++ ?to_s(Shop) ++ ?d 
	++ ?to_s(Date),

    UTF8 = unicode:characters_to_list(L, utf8),
    GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(GBK),    
    do_write(stock, Do, Count + 1, T).

export_type(0) -> trans;
export_type(1) -> trans_note;
export_type(2) -> stock.

purchaser_type(0) -> "入库";
purchaser_type(1)-> "退货".

sex(0) ->"女"; 
sex(1) ->"男".

season(0) -> "春";
season(1) -> "夏";
season(2) -> "秋";
season(3) -> "冬".

mode(0) -> use_id;
mode(1) -> use_sell;
mode(2) -> use_discount;
mode(3) -> use_year;
mode(4) -> use_season;
mode(5) -> use_amount;
mode(6) -> use_style_number;
mode(7) -> use_brand;
mode(8) -> use_type.

    
