-module(diablo_purchaser_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([authen/2, authen_shop_action/2, filter_condition/3, season/1]).
-export([get_color/2, mode/1]).

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
    Datetime       = ?v(<<"datetime">>, Base),
    Total          = ?v(<<"total">>, Base), 
    %% Date = ?utils:to_date(datetime, Datetime),

    %% ?DEBUG("current seconds ~p, date seconds ~p",
    %% 	   [?utils:current_time(localtime2second), ?utils:datetime2seconds(Datetime)]),
    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 3600 * 2 of
	true ->
	    CurDatetime    = ?utils:current_time(format_localtime), 
	    ?utils:respond(200,
			   Req,
			   ?err(stock_invalid_date, "new_w_inventory"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, ?to_b(CurDatetime)}]);
	false ->
	    case stock(check, ?NEW_INVENTORY, Total, 0, Invs) of
		ok ->
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
		    end;
		{error, EInv} ->
		    StyleNumber = ?v(<<"style_number">>, EInv),
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_inv, StyleNumber),
		       [{<<"style_number">>, StyleNumber},
			{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
		{error, Total, CalcTotal} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_total, CalcTotal),
		       [{<<"total">>, Total},
			{<<"ctotal">>, CalcTotal}])
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
    
    Firm = ?v(<<"firm">>, Base), 
    Datetime   = ?v(<<"datetime">>, Base),
    OldDatetime = ?v(<<"entry_date">>, OldBase),

    case Firm == ?INVALID_OR_EMPTY andalso ?to_b(Datetime) =/= ?to_b(OldDatetime) of
	true ->
	    ?utils:respond(200, Req, ?err(purchaser_diff_time_with_empty_firm, Datetime));
	false -> 
	    case ?w_inventory:purchaser_inventory(
		    update, Merchant, lists:reverse(Invs), {Base, OldBase}) of
		{ok, RSn} -> 
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(update_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

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

action(Session, Req, {"modify_w_inventory_new_balance"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload),
    Balance = ?v(<<"balance">>, Payload),

    case is_number(Balance) of
	true -> 
	    case ?w_inventory:purchaser_inventory(modify_balance, Merchant, RSN, Balance) of
		{ok, RSn} -> 
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(update_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	false ->
	    Error = ?err(params_error, "balance"),
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
	{error, {empty_firm, _R}} ->
	    ?utils:respond(
               200,
               Req,
               ?err(empty_firm_of_check, RSN));
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
	    ++ ?utils:v(brand, integer, ?v(<<"brand">>, Fields))
	    ++ ?utils:v(org_price, integer, ?v(<<"org_price">>, Fields))
	    ++ ?utils:v(over, integer, ?v(<<"over">>, Fields)) of
	    [] -> {ok,
		   [{<<"fields">>, {struct, Fields}}]
		   ++ lists:keydelete(<<"fields">>, 1, NewPayload)}; 
	    _ ->
		case ?w_inventory:purchaser_inventory(get_inventory_new_rsn, Merchant, Fields) of
		    {ok, []} -> {ok, []};
		    {ok, RSNs} ->
			{ok,
			 [{<<"fields">>, 
			   {struct, lists:keydelete(
				      <<"style_number">>, 1,
				      lists:keydelete(<<"brand">>, 1,
						      lists:keydelete(<<"org_price">>, 1, Fields)))
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
	_:{badmatch, {error, Error}} ->
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
    Total          = ?v(<<"total">>, Base), 

    Datetime = ?v(<<"datetime">>, Base), 

    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 3600 * 2 of
	true ->
	    CurDatetime = ?utils:current_time(format_localtime), 
	    ?utils:respond(200,
			   Req,
			   ?err(stock_invalid_date, "update_w_inventory"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, ?to_b(CurDatetime)}]);
	false ->
	    case stock(check, ?REJECT_INVENTORY, Total, 0, Invs) of
		ok ->
		    case ?w_inventory:purchaser_inventory(
			    reject, Merchant, lists:reverse(Invs), Base) of 
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
		    end;
		{error, EInv} ->
		    StyleNumber = ?v(<<"style_number">>, EInv),
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_inv, StyleNumber),
		       [{<<"style_number">>, StyleNumber},
			{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
		{error, Total, CalcTotal} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_total, CalcTotal),
		       [{<<"total">>, Total},
			{<<"ctotal">>, CalcTotal}])
	    end
    end;

%% =============================================================================
%% inventory
%% ============================================================================= 
action(Session, Req, {"filter_w_inventory_group"}, Payload) -> 
    ?DEBUG("filter_w_inventory_group with session ~p, paylaod~n~p", [Session, Payload]), 
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
    Merchant       = ?session:get(merchant, Session),
    ShopStocks     = ?v(<<"stock">>, Payload, []),
    {struct, Base} = ?v(<<"base">>, Payload),
    Shop = ?v(<<"shop">>, Base),
    Firm = ?v(<<"firm">>, Base, -1),

    %% {ShopTotal, ShopStockDict} = stock(shop_to_dict, ShopStocks, 0, dict:new()),

    %% get stock of shop
    case ?w_inventory:stock(detail_get_by_shop, Merchant, Shop, Firm) of
	{ok, DBStocks} ->
	    {DBTotal, DBStockDict} = stock(to_dict, DBStocks, 0, dict:new()),
	    {StocksNotInDB, StocksNotEqualDB}
		= compare_stock(shop_to_db, ShopStocks, DBStockDict, [], []),
	    ?DEBUG("stocksNotInDB ~p", [StocksNotInDB]),
	    ?DEBUG("stocksNotEqualDB ~p", [StocksNotEqualDB]),
	    
	    {ShopTotal, ShopStockDict} = stock(shop_to_dict, ShopStocks, 0, dict:new()),
	    {StocksNotInShop, _StocksNotEqualShop}
		= compare_stock(db_to_shop, DBStocks, ShopStockDict, [], []),
	    ?DEBUG("stocksNotInShop ~p", [StocksNotInShop]),
	    %% ?DEBUG("stocksNotEqualShop ~p", [StocksNotEqualShop]),

	    case ?w_inventory:purchaser_inventory(
		    fix,
		    Merchant,
		    {StocksNotInDB, StocksNotInShop, StocksNotEqualDB},
		    [{<<"db_total">>, DBTotal}, {<<"shop_total">>, ShopTotal}] ++ Base) of
		{ok, RSN} -> 
		    ?utils:respond(
		       200,
		       object,
		       Req,
		       {[{<<"ecode">>, 0},
			 {<<"rsn">>, ?to_b(RSN)}
			 %% {<<"s_not_db">>, StocksNotInDB},
			 %% {<<"s_not_equal_db">>, StocksNotEqualDB},
			 %% {<<"s_not_shop">>, StocksNotInShop},
			 %% {<<"s_not_equal_shop">>, StocksNotEqualShop}
			]});
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error}->
	    ?utils:respond(200, Req, Error)
    end;

    
    %% case ?w_inventory:purchaser_inventory(fix, Merchant, Stocks, Base) of 
    %% 	{ok, RSn} ->
    %% 	    ?utils:respond(200,
    %% 			   Req,
    %% 			   ?succ(fix_w_inventory, RSn),
    %% 			   {<<"rsn">>, ?to_b(RSn)});
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end;

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
    Total          = ?v(<<"total">>, Base), 
    Datetime       = ?v(<<"datetime">>, Base),

    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 3600 * 2 of
	true ->
	    CurDatetime = ?utils:current_time(format_localtime), 
	    ?utils:respond(200,
			   Req,
			   ?err(stock_invalid_date, "update_w_inventory"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, ?to_b(CurDatetime)}]);
	false -> 
	    case stock(check, ?TRANSFER_INVENTORY, Total, 0, Invs) of
		ok ->
		    case ?w_inventory:purchaser_inventory(
			    transfer, Merchant, lists:reverse(Invs), Base) of
			{ok, RSn} ->
			    ?utils:respond(
			       200,
			       Req,
			       ?succ(transfer_w_inventory, RSn), {<<"rsn">>, ?to_b(RSn)});
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{error, EInv} ->
		    StyleNumber = ?v(<<"style_number">>, EInv),
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_inv, StyleNumber),
		       [{<<"style_number">>, StyleNumber},
			{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
		{error, Total, CalcTotal} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(stock_invalid_total, CalcTotal),
		       [{<<"total">>, Total},
			{<<"ctotal">>, CalcTotal}])
	    end
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
    ?DEBUG("match_w_inventory with session ~p~npayload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Prompt = ?v(<<"prompt">>, Payload),
    Shop        = ?v(<<"shop">>, Payload),
    Firm        = ?v(<<"firm">>, Payload),
    QMode       = ?v(<<"mode">>, Payload, ?GOOD_SALE),
    Ascii       = ?v(<<"ascii">>, Payload, ?YES),

    Match = 
	case QMode of
	    ?GOOD_SALE ->
		fun() when Firm =:= undefined->
			?w_inventory:match(
			   inventory, Merchant, Prompt, Shop);
		   () ->
			?w_inventory:match(
			   inventory, Merchant, Prompt, Shop, Firm)
		end;
	    ?BRAND_TYPE_SALE ->
		case ?attr:type(list, Merchant, Prompt, Ascii) of
		    {ok, []} ->
			fun() -> {ok, []} end;
		    {ok, Types} ->
			fun() ->
				?w_inventory:match(
				   inventory_with_type, Merchant, Shop,
				   {<<"type">>,
				    lists:foldr(
				      fun({Type}, Acc) ->
					      [?v(<<"id">>, Type)|Acc]
				      end, [], Types)})
			end
		end
	end,
    
    batch_responed(Match, Req);

action(Session, Req, {"match_stock_by_shop"}, Payload) ->
    ?DEBUG("match_stock_by_shop: session ~p, payload ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    ShopIds   = ?v(<<"shop">>, Payload),
    StartTime = ?v(<<"stime">>, Payload),
    Prompt    = ?v(<<"prompt">>, Payload),

    batch_responed(
      fun()-> ?w_inventory:match_stock(by_shop, Merchant, ShopIds, StartTime, Prompt) end, Req);


action(Session, Req, {"w_inventory_export"}, Payload) ->
    ?DEBUG("w_inventory_export with session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"e_type">>, Payload, 0)),

    {struct, Conditions} = ?v(<<"condition">>, Payload),
    
    %% {struct, Mode}     = ?v(<<"mode">>, Payload),

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
		{ok, Q} = ?w_inventory:purchaser_inventory(get_inventory_new_rsn, Merchant, CutConditions),
		{struct, C} =
		    ?v(<<"fields">>,
		       filter_condition(
			 trans_note,
			 [?v(<<"rsn">>, Rsn) || {Rsn} <- Q],
			 CutConditions)),
		C;
	    trans -> Conditions;
	    stock -> Conditions;
	    shift_note -> Conditions
	end,

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportColorSize = ?to_i(?v(<<"export_note">>, BaseSetting, 0)),
    ExportCode = ?to_i(?v(<<"export_code">>, BaseSetting, 0)), 

    ShowOrgPrice = 
	case ?right_auth:authen(?stock_show_orgprice, Session) of
	    {ok, ?stock_show_orgprice} -> true;
	    _ -> false
	end,

    case ?w_inventory:export(ExportType, Merchant, NewConditions, UseMode) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
	{ok, Transes} ->
	    %% write to file 
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("itrans", Merchant, UserId), 
	    %% case ExportColorSize =:= 1 andalso ExportType =:=stock of
	    case ExportColorSize =:= ?YES
		andalso (ExportType =:= stock orelse ExportType =:= shift_note) of 
		true ->
		    case ExportType of
			stock ->
			    case export(
				   stock_note,
				   Merchant,
				   NewConditions, 
				   {UseMode, Transes, ExportFile, Url, ExportCode, ShowOrgPrice}) of
				{ok, OkReturn} ->
				    ?utils:respond(200, object, Req, OkReturn);
				{error, Error} ->
				    ?utils:respond(200, Req, Error)
			    end; 
			shift_note ->
			    case export(
				   shift_note,
				   Merchant,
				   Conditions,
				   {UseMode, Transes, ExportFile, Url, ExportCode, ShowOrgPrice}) of
				{ok, OkReturn} ->
				    ?utils:respond(200, object, Req, OkReturn);
				{error, Error} ->
				    ?utils:respond(200, Req, Error)
			    end;
			_ ->
			    ok
		    end;
		false -> 
		    case file:open(ExportFile, [append, raw]) of
			{ok, Fd} -> 
			    try
				DoFun = fun(C) -> ?utils:write(Fd, C) end, 
				csv_head(ExportType, DoFun, ExportCode, ShowOrgPrice),
				do_write(ExportType, DoFun, 1, Transes, ExportCode, ShowOrgPrice),
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

action(Session, Req, {"set_w_inventory_promotion"}, Payload) ->
    ?DEBUG("set_w_inventory_promotion with session ~p~n, paylaod ~p", [Session, Payload]),
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

action(Session, Req, {"gift_w_stock"}, Payload) ->
    ?DEBUG("gift_w_stock with session ~p~n, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Conditions} = ?value(<<"condition">>, Payload),
    {struct, Attrs} = ?value(<<"attrs">>, Payload, []),
    case ?w_inventory:purchaser_inventory(set_gift, Merchant, Attrs, Conditions) of
	{ok, State} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(update_w_inventory_batch, Merchant),
	       {<<"state">>, State});
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

action(Session, Req, {"update_w_inventory_alarm"}, Payload) ->
    ?DEBUG("update_w_inventory_alarm with session ~p~n, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Conditions} = ?value(<<"condition">>, Payload), 
    {struct, Attrs} = ?value(<<"attrs">>, Payload, []),

    case ?w_inventory:purchaser_inventory(
	    update_stock_alarm, Merchant, Attrs, Conditions) of
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
    end;

action(Session, Req, {"get_stock_by_barcode"}, Payload) ->
    ?DEBUG("get_stock_by_barcode: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Barcode = ?v(<<"barcode">>, Payload),
    Shop = ?v(<<"shop">>, Payload),
    Firm = ?v(<<"firm">>, Payload, -1),
    
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)), 
    %% BarcodeSize = erlang:size(Barcode),

    %% 128C code's lenght should be odd
    <<ZZ:2/binary, _/binary>> = Barcode,
    <<_Z:1/binary, SCode/binary>> = Barcode, 
    NewBarcode = 
	case AutoBarcode of
	    ?YES -> 
		case ZZ of
		    <<"00">> ->
			SCode;
		    <<"0", _T/binary>> ->
			SCode;
		    _ ->
			Barcode
		end;
	    ?NO ->
		case ZZ of
		    <<"00">> ->
			SCode;
		    <<"0", _T/binary>> ->
			SCode;
		    _ ->
			Barcode
		end
    end,
    
    ?DEBUG("newBarcode ~p", [Barcode]),
	    
    case ?w_inventory:purchaser_inventory(get_by_barcode, Merchant, Shop, Firm, NewBarcode) of 
	{ok, Stock} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"stock">>, {Stock} }]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"syn_w_inventory_barcode"}, Payload) ->
    ?DEBUG("syn_w_inventory_barcode with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% StyleNumber = ?v(<<"style_number">>, Payload),
    %% Brand = ?v(<<"brand">>, Payload),
    %% Shop = ?v(<<"shop">>, Payload),
    Barcode = ?v(<<"barcode">>, Payload),
    Conditions = lists:keydelete(<<"barcode">>, 1, Payload),
    case ?w_inventory:purchaser_inventory(syn_barcode, Merchant, Barcode, Conditions) of
	{ok, Barcode} ->
	    ?utils:respond(
	       200,
	       Req,
	       ?succ(syn_w_inventory_barcode, Barcode));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"gen_stock_barcode"}, Payload) ->
    ?DEBUG("gen_stock_barcode: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand = ?v(<<"brand">>, Payload),
    Shop = ?v(<<"shop">>, Payload),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),
    
    case ?w_inventory:purchaser_inventory(
	    gen_barcode, AutoBarcode, Merchant, Shop, StyleNumber, Brand) of
	{ok, Barcode} ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"barcode">>, ?to_b(Barcode)}]}); 
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"reset_stock_barcode"}, Payload) ->
    ?DEBUG("reset_stock_barcode: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand = ?v(<<"brand">>, Payload),
    Shop = ?v(<<"shop">>, Payload),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),
    
    case ?w_inventory:purchaser_inventory(
	    reset_barcode, AutoBarcode, Merchant, Shop, StyleNumber, Brand) of
	{ok, Barcode} ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"barcode">>, ?to_b(Barcode)}]}); 
	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"print_w_inventory_new"}, Payload) ->
    ?DEBUG("print_stock_new: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload),

    %% new
    {ok, Detail} = ?w_inventory:purchaser_inventory(get_new, Merchant, RSN),
    %% ?DEBUG("detail ~p", [Detail]),
    %% detail
    {ok, Transes} = ?w_inventory:purchaser_inventory(list_new_detail, Merchant, [{<<"rsn">>, RSN}]),
    %% ?DEBUG("transes ~p", [Transes]),
    %% amount
    {ok, Notes} = ?w_inventory:rsn_detail(new_rsn, Merchant, [{<<"rsn">>, RSN}]),
    %% ?DEBUG("Notes ~p", [Notes]),
    Key = {<<"style_number">>, <<"brand_id">>, <<"shop_id">>},
    DictNote = stock_note(
		 to_dict,
		 Key,
		 Notes,
		 dict:new()),

    %% ?DEBUG("dict note ~p", [dict:to_list(DictNote)]), 
    Sort = print_inventory_new(sort_by_color, Key, Transes, DictNote, []),
    %% ?DEBUG("sort ~p", [Sort]), 
    ?utils:respond(200, object, Req,
		   {[{<<"ecode">>, 0},
		     {<<"detail">>, {Detail}},
		     {<<"note">>, Sort}]});


action(Session, Req, {"print_w_inventory_fix_note"}, Payload) ->
    ?DEBUG("print_stock_fix_note: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload), 
    %% fix
    {ok, Detail} = ?w_inventory:purchaser_inventory(get_fix, Merchant, RSN),
    
    {ok, Notes} = ?w_inventory:purchaser_inventory(list_fix_detail, Merchant, [{<<"rsn">>, RSN}]), 
    ?utils:respond(200, object, Req,
		   {[{<<"ecode">>, 0},
		     {<<"detail">>, {Detail}},
		     {<<"note">>, Notes}]});

action(Session, Req, {"print_w_inventory_transfer"}, Payload) ->
    ?DEBUG("print_stock_tranasfer: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload),

    %% new
    {ok, Detail} = ?w_inventory:purchaser_inventory(get_transfer, Merchant, RSN),
    ?DEBUG("detail ~p", [Detail]),
    %% detail
    {ok, Transes} = ?w_inventory:purchaser_inventory(trace_transfer, Merchant, [{<<"rsn">>, RSN}]),
    %% ?DEBUG("transes ~p", [Transes]),
    %% amount
    {ok, Notes} = ?w_inventory:rsn_detail(transfer_rsn, Merchant, [{<<"rsn">>, RSN}]),
    %% ?DEBUG("Notes ~p", [Notes]),

    Key = {<<"style_number">>, <<"brand_id">>, <<"fshop_id">>},
    DictNote = stock_note(
		 to_dict,
		 Key,
		 Notes,
		 dict:new()),

    %% ?DEBUG("dict note ~p", [dict:to_list(DictNote)]), 
    Sort = print_inventory_new(sort_by_color, Key, Transes, DictNote, []),
    %% ?DEBUG("sort ~p", [Sort]), 
    ?utils:respond(200, object, Req,
		   {[{<<"ecode">>, 0},
		     {<<"detail">>, {Detail}},
		     {<<"note">>, Sort}]});

action(Session, Req, {"print_w_inventory_new_note"}, Payload) ->
    ?DEBUG("print_w_inventory_note: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, CutConditions} = ?v(<<"condition">>, Payload),
    
    {ok, Q} = ?w_inventory:purchaser_inventory(
		 get_inventory_new_rsn, Merchant, CutConditions),
    
    {struct, C} = ?v(<<"fields">>,
		     filter_condition(
		       trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], CutConditions)),
    
    {ok, Transes} = ?w_inventory:export(trans_note, Merchant, C, []),
    Dict = note_to_dict_by_firm(Transes, dict:new()),
    %% ?DEBUG("dict note ~p", [dict:to_list(Dict)]),

    %% sort by shop
    Keys = dict:fetch_keys(Dict),
    %% ?DEBUG("keys ~p", [Keys]), 
    SortAll = 
    	lists:foldr(
    	  fun(Key, Acc) ->
    		  case dict:find(Key, Dict) of
    		      error ->
    			  Acc;
    		      {ok, Notes} ->
			  [{N}|_T] = Notes,
			  ?DEBUG("N ~p", [N]),
    			  [{[{<<"fid">>, Key},
			     {<<"firm">>, case ?v(<<"vfirm">>, N, <<>>) of
					      <<>> ->
						  ?v(<<"firm">>, N, <<>>);
					      _Firm ->
						  _Firm
					  end},
			     {<<"addr">>, case ?v(<<"vfirm_addr">>, N, <<>>) of
					      <<>> ->
						  ?v(<<"firm_addr">>, N, <<>>);
					       _Addr ->
						   _Addr
					  end},
			     {<<"note">>, Notes}]}|Acc]
    		  end
		  
    	  end, [], Keys), 
    %% ?DEBUG("SortAll ~p", [SortAll]), 
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
				       {<<"data">>, SortAll}]}).


print_inventory_new(sort_by_color, _Key, [], _DictNote, Acc) ->
    Acc; 
print_inventory_new(sort_by_color, {K1, K2, K3} = K, [H|T], DictNote, Acc) ->
    StyleNumber = ?v(K1, H),
    BrandId     = ?to_b(?v(K2, H)),
    ShopId      = ?to_b(?v(K3, H)),
    
    TypeId      = ?v(<<"type_id">>, H), 
    Season      = ?v(<<"season">>, H),
    %% Year        = ?v(<<"year">>, H), 
    %% OrgPrice    = ?v(<<"org_price">>, H),
    %% EDiscount   = ?v(<<"ediscount">>, H),
    %% TagPrice    = ?v(<<"tag_price">>, H), 
    %% Discount    = ?v(<<"discount">>, H), 
    Total       = ?v(<<"amount">>, H), 
    Date        = ?v(<<"entry_date">>, H),

    Key = <<StyleNumber/binary, BrandId/binary, ShopId/binary>>,

    case dict:find(Key, DictNote) of
	{ok, Notes} ->
	    OneDict = one_stock_note(sort_by_color, <<"color_id">>, Notes, dict:new()),

	    NoteDetails = 
		dict:fold(
		  fun(C, OneNotes, Acc1) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({One}, {Amount, Descs}) ->
					Size = ?v(<<"size">>, One),
					OneAmount = ?v(<<"amount">>, One),
					{Amount + OneAmount,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(OneAmount) ++ ";"} 
				end, {0, []}, OneNotes),

			  [{C, TotalOfColor, SizeDescs}|Acc1]

		  end, [], OneDict),

	    N = {[{<<"style_number">>, StyleNumber},
		  {<<"brand_id">>, ?to_i(BrandId)},
		  {<<"type_id">>, TypeId},
		  {<<"season">>, Season},
		  {<<"total">>, Total},
		  {<<"entry_date">>, Date},
		  {<<"note">>,
		   lists:foldr(
		     fun({ColorId, TotalOfColor, SizeDesc}, Acc1) ->
			     [{[{<<"color_id">>, ColorId},
			      {<<"total">>, TotalOfColor},
				{<<"size">>, ?to_b(SizeDesc)}]}|Acc1]
		     end, [], NoteDetails)}]},
	    print_inventory_new(sort_by_color, K, T, DictNote, [N|Acc]);
	error ->
	    print_inventory_new(sort_by_color, K, T, DictNote, Acc)
    end.


export(stock_note, Merchant, Conditions, {UseMode, Transes, File, Url, ExportCode, ShowOrgPrice}) ->
    case ?w_inventory:export(stock_note, Merchant, Conditions, UseMode) of
	[] ->
	    {error, ?err(wsale_export_none, Merchant)};
	{ok, StockNotes} ->
	    {ok, Colors} = ?w_user_profile:get(color, Merchant),
	    case file:open(File, [append, raw]) of
		{ok, Fd} ->
		    try
			%% sort stock by color
			DoFun = fun(C) -> ?utils:write(Fd, C) end, 
			SortStockS = stock_note(
				       to_dict,
				       {<<"style_number">>, <<"brand">>, <<"shop">>},
				       StockNotes,
				       dict:new()),
			csv_head(
			  stock_sort_by_color,
			  DoFun,
			  ExportCode,
			  ShowOrgPrice),
			do_write(
			  stock_sort_by_color,
			  DoFun,
			  1,
			  Transes,
			  SortStockS,
			  Colors,
			  ExportCode,
			  ShowOrgPrice),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p", [T, W, erlang:get_stacktrace()]),
			    {error, ?err(wsale_export_error, W)}
		    end,
		    {ok, {[{<<"ecode">>, 0}, {<<"url">>, ?to_b(Url)}]}}; 
		{error, Error} ->
		    {error, ?err(wsale_export_error, Error)}
	    end
    end;

export(shift_note, Merchant, _Conditions, {UseMode, Transes, File, Url, ExportCode, ShowOrgPrice}) ->
    %% get rsn
    RSNs = lists:foldr(fun({Transe}, Acc) ->
			Rsn = ?v(<<"rsn">>, Transe),
			case lists:member(Rsn, Acc) of
			    true  -> Acc;
			    false -> [Rsn|Acc]
			end
		end, [], Transes),
    
    case ?w_inventory:export(shift_note_color_size, Merchant, [{<<"rsn">>, RSNs}], UseMode) of
	[] ->
	    {error, ?err(wsale_export_none, Merchant)};
	{ok, ShiftNotes} -> 
	    {ok, Colors} = ?w_user_profile:get(color, Merchant),
	    {ok, Shops}  = ?w_user_profile:get(shop, Merchant),
	    {ok, Brands} = ?w_user_profile:get(brand, Merchant),
	    {ok, Types}  = ?w_user_profile:get(type, Merchant),
	    {ok, Firms}  = ?w_user_profile:get(firm, Merchant),
	    
	    case file:open(File, [append, raw]) of
		{ok, Fd} ->
		    try
			%% sort stock by color
			DoFun = fun(C) -> ?utils:write(Fd, C) end, 
			SortTranses = shift_trans(
					to_dict,
					Transes,
					dict:new()),
			
			DictNotes = shift_note(to_dict, ShiftNotes, dict:new()), 
			csv_head(
			  shift_note_color,
			  DoFun,
			  ExportCode,
			  ShowOrgPrice),
			do_write(
			  shift_note_color,
			  DoFun,
			  1,
			  SortTranses,
			  DictNotes,
			  {Colors, Shops, Brands, Types, Firms},
			  ExportCode,
			  ShowOrgPrice),
			ok = file:datasync(Fd),
			ok = file:close(Fd),
			{ok, {[{<<"ecode">>, 0}, {<<"url">>, ?to_b(Url)}]}}
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p", [T, W, erlang:get_stacktrace()]),
			    {error, ?err(wsale_export_error, W)}
		    end;
		    %% {ok, {[{<<"ecode">>, 0}, {<<"url">>, ?to_b(Url)}]}}; 
		{error, Error} ->
		    {error, ?err(wsale_export_error, Error)}
	    end
    end.

sidebar(Session) ->
    %% UserType = ?session:get(type, Session),
    
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
	    InvDetail = [{"inventory_detail",  "库存详情", "glyphicon glyphicon-book"}], 
		
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
		  %% case UserType of
		  %%     ?MERCHANT ->
		  %% 	  [{"inventory_fix", "店铺盘点", "glyphicon glyphicon-check"}];
		  %%     _ -> []
		  %% end
			      
		  authen_shop_action(
		    {?fix_w_inventory,
		     "inventory_fix",
		     "扫描盘点", "glyphicon glyphicon-check"}, Shops)
		  ++ authen_shop_action(
		       {?fix_w_inventory,
			"inventory_import_fix",
			"导入盘点", "glyphicon glyphicon-import"}, Shops)
		  ++ [{"inventory_fix_detail",
		       "盘点记录", "glyphicon glyphicon-tasks"},
		      {"inventory_rsn_detail/fix",
		       "盘点明细", "glyphicon glyphicon-leaf"}
		     ] 
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
			     "glyphicon glyphicon-font"},
			    {"type", "品类",
			     "glyphicon glyphicon-object-align-top"}
			   ]
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
	    ?utils:respond(200, batch_mochijson, Req, Values);
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


csv_head(trans, Do, Code, _ShowOrgPrice) ->
    H = "序号,单号,厂商,门店,入单员,采购,数量,现金,刷卡,汇款,核销,费用,帐户欠款,应付,实付,本次欠款,备注,日期",
    %% UTF8 = unicode:characters_to_list(H, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8),
    C = case Code of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end, 
    Do(C);
csv_head(trans_note, Do, Code, ShowOrgPrice) ->
    H = case ShowOrgPrice of
	    true ->
		"序号,单号,厂商,门店,店员,交易类型,款号,品牌,类型,吊牌价,折扣,进价,数量,日期";
	    false ->
		"序号,单号,厂商,门店,店员,交易类型,款号,品牌,类型,吊牌价,折扣,数量,日期"
	end,
    C = case Code of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(C);

csv_head(stock, Do, Code, ShowOrgPrice) ->
    H = case ShowOrgPrice of
	    true ->
		"序号,款号,品牌,类别,性别,厂商,季节,年度,吊牌价,折扣,进价,进折扣,数量,店铺,上架日期";
	    false ->
		"序号,款号,品牌,类别,性别,厂商,季节,年度,吊牌价,折扣,数量,店铺,上架日期"
	end,

    C = 
	case Code of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(C);

csv_head(stock_sort_by_color, Do, Code, ShowOrgPrice) ->
    H = case ShowOrgPrice of
	    true ->
		"序号,款号,品牌,类别,性别,厂商,季节,年度,吊牌价,折扣,进价,进折扣,小计,数量,颜色,尺码,店铺,上架日期";
	    false ->
		"序号,款号,品牌,类别,性别,厂商,季节,年度,吊牌价,折扣,小计,数量,颜色,尺码,店铺,上架日期"
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    C = 
	case Code of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(C);

csv_head(shift_note_color, Do, ExportCode, ShowOrgPrice) -> 
    H = case ShowOrgPrice of
	    true ->
		"序号,调出店铺,调入店铺,厂商,款号,品牌,类型,季节,进价,小计,数量,颜色,尺码";
	    false ->
		"序号,调出店铺,调入店铺,厂商,款号,品牌,类型,季节,小计,数量,颜色,尺码"
	end,
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    Do(C).

do_write(trans, _Do, _Count, [], _Code, _ShowOrgPrice)->
    ok;
do_write(trans, Do, Count, [H|T], Code, ShowOrgPrice) ->
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
    Line = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
    Do(Line),
    do_write(trans, Do, Count + 1, T, Code, ShowOrgPrice);

do_write(trans_note, _Do, _Count, [], _Code, _ShowOrgPrice)->
    ok;
do_write(trans_note, Do, Count, [H|T], Code, ShowOrgPrice) ->
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
    TagPrice   = ?v(<<"tag_price">>, H),
    Discount   = ?v(<<"discount">>, H),
    OrgPrice   = ?v(<<"org_price">>, H),
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
	++ ?to_s(TagPrice) ++ ?d 
	++ ?to_s(Discount) ++ ?d

	++ case ShowOrgPrice of
	       true ->
		   ?to_s(OrgPrice) ++ ?d;
	       false ->
		   []
	   end
	
	++ ?to_s(Total) ++ ?d
    %% ++ ?to_s(Calc) ++ ?d 
    %% ++ ?to_s(Comment) ++ ?d
	++ ?to_s(Date),
    %% ++ ?to_s(Date),
    
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 

    Line = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line),
    
    do_write(trans_note, Do, Count + 1, T, Code, ShowOrgPrice);

do_write(stock, _Do, _Count, [], _Code, _ShowOrgPrice)->
    ok;
do_write(stock, Do, Count, [H|T], Code, ShowOrgPrice) ->
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
	++ case ShowOrgPrice of
	       true ->
		   ?to_s(OrgPrice) ++ ?d
		       ++ ?to_s(EDiscount) ++ ?d;
	       false ->
		   []
	   end
	++ ?to_s(Total) ++ ?d 
	++ ?to_s(Shop) ++ ?d 
	++ ?to_s(Date),

    
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8),
    Line = 
	case Code of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line), 
    do_write(stock, Do, Count + 1, T, Code, ShowOrgPrice).

do_write(stock_sort_by_color, _Do, _Count, [], _SortStocks, _Colors, _Code, _ShowOrgPrice)->
    ok;
do_write(stock_sort_by_color, Do, Count, [H|T], SortStocks, Colors, Code, ShowOrgPrice) ->
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H),
    BrandId     = ?to_b(?v(<<"brand_id">>, H)),
    Type        = ?v(<<"type">>, H),
    %% Color       = ?v(<<"color">>, H),
    %% Size        = ?v(<<"size">>, H),
    Sex         = ?v(<<"sex">>, H),

    Firm        = ?v(<<"firm">>, H), 
    Shop        = ?v(<<"shop">>, H),
    ShopId      = ?to_b(?v(<<"shop_id">>, H)),
    Season      = ?v(<<"season">>, H),
    Year        = ?v(<<"year">>, H),

    OrgPrice    = ?v(<<"org_price">>, H),
    EDiscount   = ?v(<<"ediscount">>, H),
    TagPrice    = ?v(<<"tag_price">>, H), 
    Discount    = ?v(<<"discount">>, H), 
    Total       = ?v(<<"amount">>, H), 

    Date      = ?v(<<"entry_date">>, H),

    Key = <<StyleNumber/binary, BrandId/binary, ShopId/binary>>,
    %% ?DEBUG("key ~p", [Key]),
    case dict:find(Key, SortStocks) of
	{ok, Notes} ->
	    %% ?DEBUG("Notes ~p", [Notes]),
	    %% sort notes
	    NoteDict = one_stock_note(sort_by_color, <<"color">>, Notes, dict:new()),

	    %% Keys = dict:fetch_keys(NoteDict),
	    Details = 
		dict:fold(
		  fun(K, SStocks, Acc) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({S}, {Total0, Descs}) ->
					Size = ?v(<<"size">>, S),
					TotalA = ?v(<<"total">>, S),
					{Total0 + TotalA,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(TotalA) ++ ";"} 
				end, {0, []}, SStocks),

			  [{K, TotalOfColor, SizeDescs}|Acc]

		  end, [], NoteDict),
	    %% ?DEBUG("Details ~p", [Details]),

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
		++ case ShowOrgPrice of
		    true ->
			?to_s(OrgPrice) ++ ?d
			       ++ ?to_s(EDiscount) ++ ?d;
		    false ->
			   []
		end
		++ ?to_s(Total) ++ ?d
		++ ?d %% total of the color
		++ ?d %% color
		++ ?d %% size
		++ ?to_s(Shop) ++ ?d 
		++ ?to_s(Date),
	    
	    C = 
		lists:foldr(
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
			      ++ ?d
			      ++ case ShowOrgPrice of
				     true -> ?d ++ ?d;
				     false -> []
				 end 
			      ++ ?d
			      ++ ?to_s(TotalOfColor) ++ ?d
			      ++ ?to_s(get_color(ColorId, Colors)) ++ ?d
			      ++ ?to_s(SizeDescs) ++ ?d
			      ++ ?d,
			  Acc ++ L1
		  end, [], Details),

	    %% ?DEBUG("C ~ts", [?to_b(L ++ C)]), 
	    Line = 
		case Code of
		    0 -> ?utils:to_utf8(from_latin1, L ++ C);
		    1 -> ?utils:to_gbk(from_latin1, L ++ C)
		end,
	    %% UTF8 = unicode:characters_to_list(L ++ C, utf8),
	    %% GBK  = diablo_iconv:convert("utf-8", "gbk", UTF8), 
	    Do(Line),    
	    do_write(stock_sort_by_color, Do,  Count + 1, T, SortStocks, Colors, Code, ShowOrgPrice);
	error ->
	    do_write(stock_sort_by_color, Do, Count + 1, T, SortStocks, Colors, Code, ShowOrgPrice)
    end;

do_write(shift_note_color, _Do, _Count, [], _DictNotes, _Attrs, _Code, _ShowOrgPrice) ->
    ok;
do_write(shift_note_color, Do, Count, [DH|DT], DictNotes,
	 {Colors, Shops, Brands, Types, Firms}, Code, ShowOrgPrice) ->    
    {Key, [{H}]} = DH,
    FShop       = get_name(by_id, ?v(<<"fshop_id">>, H), Shops),
    TShop       = get_name(by_id, ?v(<<"tshop_id">>, H), Shops),
    
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = get_name(by_id, ?v(<<"brand_id">>, H), Brands),
    Type        = get_name(by_id, ?v(<<"type_id">>, H), Types),
    Season      = ?v(<<"season">>, H),
    Firm        = get_name(by_id, ?v(<<"firm_id">>, H), Firms),
    OrgPrice    = ?v(<<"org_price">>, H),
    Total       = ?v(<<"amount">>, H), 

    
    case dict:find(Key, DictNotes) of
	{ok, FindNotes} ->
	    ?DEBUG("find notes ~p", [FindNotes]),
	    ColoredNotes = shift_note_class_with(color, FindNotes, dict:new()),
	    %% ?DEBUG("coloredNotes ~p", [ColoredNotes]),
	    Details = 
		dict:fold(
		  fun(K, SSNotes, Acc) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({S}, {Total0, Descs}) ->
					Size = ?v(<<"size">>, S),
					TotalA = ?v(<<"amount">>, S),
					{Total0 + TotalA,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(TotalA) ++ ";"} 
				end, {0, []}, SSNotes),

			  [{K, TotalOfColor, SizeDescs}|Acc]

		  end, [], ColoredNotes),
	    ?DEBUG("Details ~p", [Details]),

	    L = "\r\n"
		++ ?to_s(Count) ++ ?d 
		++ ?to_s(FShop) ++ ?d
		++ ?to_s(TShop) ++ ?d
		++ ?to_s(Firm)  ++ ?d
		++ "\'" ++ ?to_s(StyleNumber) ++ "\'" ++ ?d
		++ ?to_s(Brand) ++ ?d
		++ ?to_s(Type) ++ ?d
		++ ?w_inventory_request:season(Season) ++ ?d
		++ case ShowOrgPrice of
		    true -> ?to_s(OrgPrice) ++ ?d;
		    false -> []
		   end
		++ ?to_s(Total) ++ ?d,


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
			      ++ case ShowOrgPrice of
				     true -> ?d;
				     false -> []
				 end
			      ++ ?d
			      ++ ?to_s(TotalOfColor) ++ ?d
			      ++ ?to_s(?w_inventory_request:get_color(ColorId, Colors)) ++ ?d
			      ++ ?to_s(SizeDescs),
			  Acc ++ L1
		  end, [], Details),

	    %% UTF8 = unicode:characters_to_list(L, utf8),
	    %% Do(UTF8),
	    Line = 
		case Code of
		    0 -> ?utils:to_utf8(from_latin1, L ++ C);
		    1 -> ?utils:to_gbk(from_latin1, L ++ C)
		end,
	    Do(Line),
	    do_write(shift_note_color,
		     Do,
		     Count + 1,
		     DT,
		     DictNotes,
		     {Colors, Shops, Brands, Types, Firms},
		     Code,
		     ShowOrgPrice);

	error ->
	    do_write(shift_note_color,
		     Do,
		     Count + 1,
		     DT,
		     DictNotes,
		     {Colors, Shops, Brands, Types, Firms},
		     Code,
		     ShowOrgPrice)
    end.
    
export_type(0) -> trans;
export_type(1) -> trans_note;
export_type(2) -> stock;
export_type(3) -> shift;
export_type(4) -> shift_note.

purchaser_type(0) -> "入库";
purchaser_type(1)-> "退货";
purchaser_type(9)-> "结帐".

sex(0) ->"女"; 
sex(1) ->"男";
sex(2) ->"童";
sex(3) ->"鞋";
sex(4) ->"配".

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
mode(8) -> use_type;
mode(9) -> use_firm;
mode(10) -> use_date.


stock(check, _Action, Total, CalcTotal, []) ->
    ?DEBUG("total ~p, CalcTotal ~p", [Total, CalcTotal]),
    case Total =:= CalcTotal of
	true -> ok;
	false -> {error, Total, CalcTotal}
    end;
stock(check, Action, Total, CalcTotal, [{struct, Inv}|T]) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Amounts     = case Action of
		      ?NEW_INVENTORY -> ?v(<<"amount">>, Inv);
		      ?REJECT_INVENTORY ->  ?v(<<"amounts">>, Inv);
		      ?TRANSFER_INVENTORY -> ?v(<<"amounts">>, Inv)
		  end,
    Count       = ?v(<<"total">>, Inv),
    DCount      = lists:foldr(
		    fun({struct, A}, Acc)->
			    %% ?INFO("style number ~p, A ~p", [StyleNumber, A]),
			    case Action of
				?NEW_INVENTORY -> ?v(<<"count">>, A) + Acc;
				?REJECT_INVENTORY -> ?v(<<"reject_count">>, A) + Acc;
				?TRANSFER_INVENTORY -> ?v(<<"count">>, A) + Acc
			    end
		    end, 0, Amounts), 

    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true -> stock(check, Action, Total, CalcTotal + Count, T);
		false -> {error, Inv}
	    end
    end.


key(stock, Stock) ->
    StyleNumber = ?v(<<"style_number">>, Stock),
    Brand = ?to_b(?v(<<"brand">>, Stock)),
    Color = ?to_b(?v(<<"color">>, Stock)),
    Size  = ?to_b(?v(<<"size">>, Stock)),
    Key = <<StyleNumber/binary, Brand/binary, Color/binary, Size/binary>>,
    Key.

stock(to_dict, [], DBTotal, DictStocks) ->
    {DBTotal, DictStocks};
stock(to_dict, [{Stock}|T], DBTotal, DictStocks) -> 
    Key = key(stock, Stock),
    Total = ?v(<<"total">>, Stock),
    stock(to_dict, T, Total + DBTotal, dict:store(Key, Stock, DictStocks));

stock(shop_to_dict, [], ShopTotal, DictStocks) ->
    ?DEBUG("sthopTotal ~p DictStocks ~p", [ShopTotal, dict:to_list(DictStocks)]),
    {ShopTotal, DictStocks};
stock(shop_to_dict, [{struct, Stock}|T], ShopTotal, DictStocks) -> 
    Key = key(stock, Stock),
    Total = ?v(<<"fix">>, Stock),
    stock(shop_to_dict, T, Total + ShopTotal, dict:store(Key, Stock, DictStocks)).

compare_stock(shop_to_db, [], _DBStockDict, StocksNotInDB, StocksNotEqualDB) ->
    {StocksNotInDB, StocksNotEqualDB}; 
compare_stock(shop_to_db, [{struct, Stock}|T], DBStockDict, StocksNotInDB, StocksNotEqualDB) ->
    ?DEBUG("stock ~p", [Stock]),
    Key = key(stock, Stock),
    ?DEBUG("key ~p", [Key]),
    case dict:find(Key, DBStockDict) of
	{ok, DBStock} ->
	    StockFixed = ?v(<<"fix">>, Stock),
	    StockInDB = ?v(<<"total">>, DBStock),
	    case StockFixed =/= StockInDB of
		true ->
		    compare_stock(
		      shop_to_db,
		      T,
		      DBStockDict,
		      StocksNotInDB,
		      [{Stock ++ [{<<"db">>, StockInDB}]}|StocksNotEqualDB]);
		false ->
		    compare_stock(shop_to_db, T, DBStockDict, StocksNotInDB, StocksNotEqualDB)
	    end;
	error ->
	    ?DEBUG("shop_to_db:key ~p not found", [Key]),
	    compare_stock(shop_to_db, T, DBStockDict, [{Stock}|StocksNotInDB], StocksNotEqualDB)
    end;


compare_stock(db_to_shop, [], _ShopStockDict, StocksNotInShop, StocksNotEqualShop) ->
    {StocksNotInShop, StocksNotEqualShop}; 
compare_stock(db_to_shop, [{Stock}|T], ShopStockDict, StocksNotInShop, StocksNotEqualShop) ->
    Key = key(stock, Stock),
    case dict:find(Key, ShopStockDict) of
	{ok, _ShopStock} ->
	    compare_stock(db_to_shop, T, ShopStockDict, StocksNotInShop, StocksNotEqualShop);
	    %% StockFixed = ?v(<<"fix">>, Stock),
	    %% StockInDB = ?v(<<"total">>, DBStock),
	    %% case StockFixed =/= StockInDB of
	    %% 	true ->
	    %% 	    compare_stock(
	    %% 	      shop_to_db,
	    %% 	      T,
	    %% 	      DBStockDict,
	    %% 	      StocksNotInDB,
	    %% 	      [{Stock ++ [{<<"db">>, StockInDB}]}|StocksNotEqualDB]);
	    %% 	false ->
	    %% 	    compare_stock(shop_to_db, T, DBStockDict, StocksNotInDB, StocksNotEqualDB)
	    %% end;
	error ->
	    %% ?DEBUG("db_to_shop:key ~p not found", [Key]),
	    compare_stock(
	      db_to_shop,
	      T,
	      ShopStockDict,
	      [{Stock}|StocksNotInShop], StocksNotEqualShop)
    end.


stock_note(to_dict, _key, [], Dict) ->
    %% ?DEBUG("Dict ~p", [dict:to_list(Dict)]),
    Dict;
stock_note(to_dict, {K1, K2, K3} = K, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(K1, H)),
    Brand = ?to_b(?v(K2, H)),
    Shop  = ?to_b(?v(K3, H)),
    
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
			  [{H}] ++ V 
		  end,
		  Dict)
	end,
    
    stock_note(to_dict, K, T, DictNew).

%% same style_number and brand, sort by color
one_stock_note(sort_by_color, _Key, [], Sorts) ->
    %% ?DEBUG("one_stock_note: ~p", [dict:to_list(Sorts)]),
    Sorts;
one_stock_note(sort_by_color, Key, [{H}|T], Sorts) ->
    %% ?DEBUG("H ~p", [H]),
    %% use color to key
    %% Color = ?v(<<"color">>, H),
    Color = ?v(Key, H),
    NewSorts = 
	case dict:find(Color, Sorts) of
	    error ->
		dict:store(Color, [{H}], Sorts);
	    {ok, _V} ->
		dict:update(
		  Color,
		  fun(V) -> [{H}] ++ V end, 
		  Sorts)
	end,

    one_stock_note(sort_by_color, Key, T, NewSorts).


shift_trans(to_dict, [], Dict) ->
    %% ?DEBUG("sale_trans_to_Dict ~p", [dict:to_list(Dict)]),
    dict:to_list(Dict); 
shift_trans(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand_id">>, H)),
    Shop  = ?to_b(?v(<<"fshop_id">>, H)),
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
					?DEBUG("note ~p", [Note]),
					Exist = ?v(<<"amount">>, Note),
					Added = ?v(<<"amount">>, H),
					[{lists:keydelete(<<"amount">>, 1, Note)
					  ++ [{<<"amount">>, Exist + Added}]}|Acc] 
				end, [], V),
			  NewV 
		  end,
		  Dict)
		%% dict:append(Key, {H}, Dict)
	end, 
    shift_trans(to_dict, T, DictNew).


shift_note(to_dict, [], Dict) ->
    %% ?DEBUG("sale_note_to_dict ~p", [dict:to_list(Dict)]),
    Dict;
shift_note(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand_id">>, H)),
    Shop  = ?to_b(?v(<<"fshop_id">>, H)),
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

    shift_note(to_dict, T, DictNew).


shift_note_class_with(color, [], Sorts) ->
    %% ?DEBUG("not_class_with_color: ~p", [dict:to_list(Sorts)]),
    Sorts;
shift_note_class_with(color, [{H}|T], Sorts) ->
    %% ?DEBUG("H ~p", [H]),
    %% use color to key
    Color = ?v(<<"color_id">>, H),
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
						Exist = ?v(<<"amount">>, Note),
						Added = ?v(<<"amount">>, H),
						{true,
						 [{lists:keydelete(<<"amount">>, 1, Note)
						   ++ [{<<"amount">>, Exist + Added}]}|Acc]};
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

    shift_note_class_with(color, T, NewSorts).

note_to_dict_by_firm([], Dict) ->
    Dict;
note_to_dict_by_firm([{H}|T], Dict) ->
    Key  = case ?v(<<"vfirm_id">>, H) of
	     ?INVALID_OR_EMPTY ->
		   K = ?to_b(?v(<<"firm_id">>, H)),
		   << <<"f-">>/binary, K/binary>>;
	     _VFirmId ->
		   K = ?to_b(_VFirmId),
		   << <<"v-">>/binary, K/binary>>
	 end,

    case Key of
	?INVALID_OR_EMPTY ->
	    note_to_dict_by_firm(T, Dict);
	_ -> 
	    DictNew =
		case dict:find(Key, Dict) of
		    error ->
			dict:store(Key, [{H}], Dict);
		    {ok, _V} ->
			dict:update(
			  Key,
			  fun(V) ->
				  [{H}] ++ V
			  end,
			  Dict)
		end,
	    note_to_dict_by_firm(T, DictNew)
    end.

%% note_to_dict_by_shop([], Dict) ->
%%     Dict;
%% note_to_dict_by_shop([{H}|T], Dict) ->
%%     ?DEBUG("H ~p", [H]),
%%     Key = ?v(<<"shop_id">>, H),
%%     DictNew =
%% 	case dict:find(Key, Dict) of
%% 	    error ->
%% 		dict:store(Key, [{H}], Dict);
%% 	    {ok, _V} ->
%% 		dict:update(
%% 		  Key,
%% 		  fun(V) ->
%% 			  [{H}] ++ V
%% 		  end,
%% 		  Dict)
%% 	end,
%%     note_to_dict_by_shop(T, DictNew).

get_color(0, _Colors) ->
    <<"均色">>;
get_color(ColorId, []) ->
    ColorId;
get_color(ColorId, [{H}|T]) ->
    CId = ?v(<<"id">>, H),
    case ColorId =:= CId of
	true ->
	    ?v(<<"name">>, H);
	false ->
	    get_color(ColorId, T)
    end.

get_name(by_id, _GivenID, []) ->
    <<>>;
get_name(by_id, GivenID, [{H}|T]) ->
    ID = ?v(<<"id">>, H),
    case ID =:= GivenID of
	true ->
	    ?v(<<"name">>, H);
	false ->
	    get_name(by_id, GivenID, T)
    end.
