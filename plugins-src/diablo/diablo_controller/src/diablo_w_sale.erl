%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 11 Feb 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_sale).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).
-export([sale/3, sale/4, pay_order/3, pay_order/4, pay_scan/4]).
-export([rsn_detail/3, get_modified/2]).
-export([order/3, order/4]).
-export([filter/4, filter/6, export/3]).
-export([direct/1]).

-export([sort_charge_card/2]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([sort_condition/3, filter_condition/4]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
sale(new, {Merchant, UTable}, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_sale, Merchant, UTable, Inventories, Props});
sale(update, {Merchant, UTable}, Inventories, {Props, OldProps}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_sale, Merchant, UTable, Inventories, Props, OldProps});
%% view the sale history of retailer
sale(history_retailer, {Merchant, UTable}, Retailer, Goods) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {history_retailer, Merchant, UTable, Retailer, Goods});
sale(reject, {Merchant, UTable}, Inventories, {Props, OldProps}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reject_sale, Merchant, UTable, Inventories, Props, OldProps});
sale(check, {Merchant, UTable}, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_new, Merchant, UTable, RSN, Mode});
sale(update_price, {Merchant, UTable}, RSN, Updates) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_price, Merchant, UTable, RSN, Updates}).

sale(list_new, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_new, Merchant, UTable, Condition});
sale(get_new, {Merchant, UTable}, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new, Merchant, UTable, RSN}); 
sale(delete_new, {Merchant, UTable}, {RSN, Retailer}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_new, Merchant, UTable, RSN, Retailer});

sale(last, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {last_sale, Merchant, UTable, Condition});
sale(trace, {Merchant, UTable}, Condition) -> 
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trace_sale, Merchant, UTable, Condition});

sale(trans_detail, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trans_detail, Merchant, UTable, Condition});

%% sale(list_rsn_with_shop, Merchant, Shop) -> 
%%     Name = ?wpool:get(?MODULE, Merchant),
%%     gen_server:call(Name, {list_sale_rsn_with_shop, Merchant, Shop});
sale(get_rsn, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_sale_rsn, Merchant, UTable, Condition});
sale(match_rsn, {Merchant, UTable}, {ViewValue, Condition}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_sale_rsn, Merchant, UTable, {ViewValue, Condition}}).

rsn_detail(rsn, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {rsn_detail, Merchant, UTable, Condition}).

order(new, {Merchant, UTable}, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_order, Merchant, UTable, Inventories, Props});
order(update, {Merchant, UTable}, Inventories, {Props, OldProps}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_order, Merchant, UTable, Inventories, Props, OldProps}).

order(delete_by_rsn, {Merchant, UTable}, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_order_by_rsn, Merchant, UTable, RSN});
order(list, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_order, Merchant, UTable, Condition});
order(list_note, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_order_note, Merchant, UTable, Condition}).

filter(total_news, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_news, Merchant, UTable, Conditions});

filter(total_rsn_group, MatchMode, {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_rsn_group, MatchMode, Merchant, UTable, Conditions}, 6 * 1000);

filter(total_firm_detail, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_firm_detail, Merchant, UTable, Conditions});

filter(total_employee_evaluation, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_employee_evaluation, Merchant, UTable, Conditions});

filter(total_pay_scan, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_pay_scan, Merchant, Conditions});

filter(total_orders, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_orders, Merchant, UTable, Conditions});
filter(total_order_detail, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_order_detail, Merchant, UTable, Conditions}).

filter(news, 'and', {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_news, Merchant, UTable, CurrentPage, ItemsPerPage, Conditions}, 10 * 1000 );

filter(rsn_group, MatchMode, {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_rsn_group,
	     {use_id, 0},
	     MatchMode,
	     {Merchant, UTable},
	     CurrentPage, ItemsPerPage, Conditions}, 10 * 1000);

filter({rsn_group, Mode, Sort}, MatchMode, {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_rsn_group,
	     {Mode, Sort},
	     MatchMode,
	     {Merchant, UTable},
	     CurrentPage, ItemsPerPage, Conditions}, 10 * 1000);

filter(employee_evaluation, 'and', {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_employee_evaluation, Merchant, UTable, CurrentPage, ItemsPerPage, Conditions});

filter(pay_scan, 'and', Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_pay_scan, Merchant, CurrentPage, ItemsPerPage, Conditions});

filter(orders, 'and', {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_orders, Merchant, UTable, CurrentPage, ItemsPerPage, Conditions});
filter(order_detail, 'and', {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_order_detail, Merchant, UTable, CurrentPage, ItemsPerPage, Conditions}).

pay_scan(start, Merchant, Shop, {PayType, PayState, Live, PayOrderNo, Balance, PayTime}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {start_pay_scan,
			   Merchant,
			   Shop,
			   {PayType, PayState, Live, PayOrderNo, Balance, PayTime}}); 
pay_scan(check, Merchant, Shop, {PayType, PayState, PayOrderNo, Balance}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {check_pay_scan, Merchant, Shop, {PayType, PayState, PayOrderNo, Balance}}).
    

export(trans, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_export, Merchant, UTable, Condition});
export(trans_note, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_export, Merchant, UTable, Condition});
export(trans_note_color_size, {Merchant, UTable}, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_color_size_export, Merchant, UTable, Condition}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_sale, Merchant, UTable, Inventories, Props}, _From, State) ->
    ?DEBUG("new_sale with merchant ~p~n~p, props ~p", [Merchant, Inventories, Props]),
    UserId = ?v(<<"user">>, Props, -1), 
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    %% DateTime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    DateTime   = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Employe    = ?v(<<"employee">>, Props),
    Comment    = ?v(<<"comment">>, Props, []),

    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    AliPay     = ?v(<<"aliPay">>, Props, 0),
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),

    BasePay    = ?v(<<"base_pay">>, Props, 0),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),
    Score      = ?v(<<"score">>, Props, 0),
    Oil        = ?v(<<"oil">>, Props, 0),

    BankCards  = ?v(<<"cards">>, Props, []),
    OrderRSN   = ?v(<<"order_rsn">>, Props, []),
    %% ScoreId    = ?v(<<"sid">>, Props, 0),
    %% DrawScore  = ?v(<<"draw_score">>, Props, 0),

    Ticket       = ?v(<<"ticket">>, Props, 0), 
    TicketScore  = ?v(<<"ticket_score">>, Props, 0),
    TicketBatchs = ?v(<<"ticket_batchs">>, Props, []),
    TicketCustom = ?v(<<"ticket_custom">>, Props, -1),

    PayOrder     = ?v(<<"pay_order">>, Props, -1),
    
    Vip          = ?v(<<"vip">>, Props, false),
    AllowedSave  = ?v(<<"allow_save">>, Props, 0),
    HasPay = Ticket + Withdraw + Wxin + AliPay + Card + Cash, 
    
    Sql0 = "select id, name, mobile, balance, score from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    CurrentBalance = retailer(balance, Account), 
	    CurrentScore = retailer(score, Account),

	    case Withdraw > 0 andalso CurrentBalance < Withdraw of
		true ->
		    {reply, {error, ?err(wsale_not_enought_balance, ?v(<<"id">>, Account))}, State};
		false -> 
		    SaleSn = lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-",
					   ?inventory_sn:sn(w_sale_new_sn, Merchant)]),
		    RealyShop = realy_shop(Merchant, Shop),
		    
		    Sql1 = 
			lists:foldr(
			  fun({struct, Inv}, Acc0)-> 
				  Amounts = ?v(<<"amounts">>, Inv), 
				  wsale(new,
					SaleSn,
					[],
					DateTime,
					{Merchant, UTable}, RealyShop, Inv, Amounts) ++ Acc0
			  end, [], Inventories),

		    [NewTicket, NewWithdraw, NewWxin, NewAliPay, NewCard, NewCash] = 
			case AllowedSave =:= ?NO of
			    true ->
				case ShouldPay >= 0 of
				    true ->
					pay_order(ShouldPay,
						  [Ticket, Withdraw, Wxin, AliPay, Card, Cash], []);
				    false ->
					pay_order(reject, ShouldPay,
						  [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
				end;
			    false ->
				pay_order(surplus, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
			end,
		    
		    ?DEBUG("NewCash ~p, NewCard ~p, NewWxin ~p, withdraw ~p, ticket ~p",
			   [NewCash,  NewCard, NewWxin, NewWithdraw, NewTicket]),
		    

		    Sql2 = "insert into" ++ ?table:t(sale_new, Merchant, UTable)
			++ "(rsn"
			", account"
			", employ"
			", retailer"
			", shop"
			", merchant"
			", tbatch"
			", tcustom"
			", balance"
			", base_pay"
			", should_pay"
		    %% ", charge"
			", cash"
			", card"
			", wxin"
			", aliPay"
			", withdraw"
			", ticket"
			", verificate"
			", total"
			", oil"
			", lscore"
			", score"
			", comment"
			", type"
			", pay_sn"
			", entry_date) values("
			++ "\"" ++ ?to_s(SaleSn) ++ "\","
			++ ?to_s(UserId) ++ ","
			++ "\'" ++ ?to_s(Employe) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(Shop) ++ ","
			++ ?to_s(Merchant) ++ "," 
		    %% ++ ?to_s(TicketBatch) ++ ","
			++ ?to_s("-1") ++ ","
			++ ?to_s(TicketCustom) ++ "," 
			++ ?to_s(CurrentBalance) ++ ","
			++ ?to_s(BasePay) ++ "," 
			++ ?to_s(ShouldPay) ++ ","
		    %% ++ ?to_s(CalcCharge) ++ ","
			++ ?to_s(NewCash) ++ ","
			++ ?to_s(NewCard) ++ ","
			++ ?to_s(NewWxin) ++ ","
			++ ?to_s(NewAliPay) ++ ","
			++ ?to_s(NewWithdraw) ++ ","
			++ ?to_s(NewTicket) ++ ","
			++ ?to_s(Verificate) ++ ","
			++ ?to_s(Total) ++ ","
			++ ?to_s(Oil) ++ ","
			++ ?to_s(CurrentScore) ++ ","
			++ ?to_s(Score) ++ "," 
			++ "\'" ++ ?to_s(Comment) ++ "\'," 
			++ ?to_s(type(new)) ++ ","
			++ "\'" ++ ?to_s(PayOrder) ++ "\'," 
			++ "\'" ++ ?to_s(DateTime) ++ "\');",

		    %% sale order
		    Sql6 = order_process(
			     stock,
			     {Merchant, UTable},
			     Shop,
			     OrderRSN,
			     DateTime,
			     Inventories,
			     0,
			     []),
		    ?DEBUG("Sql6 ~p", [Sql6]),

		    %% Sql3 = ["update w_retailer set consume=consume+"
		    %% 	    %% ++ ?to_s(ShouldPay - Verificate)
		    %% 	    ++ ?to_s(ShouldPay)
		    %% 	    ++ case NewWithdraw =< 0 of
		    %% 		   true  -> [];
		    %% 		   false -> ", balance=balance-" ++ ?to_s(NewWithdraw)
		    %% 	       end
		    %% 	    ++ case Score == 0 andalso TicketScore =< 0 of
		    %% 		   true  -> [];
		    %% 		   false -> ", score=score+" ++ ?to_s(Score - TicketScore)
		    %% 	       end
		    %% 	    ++ ", change_date=\'" ++ ?to_s(DateTime) ++ "\'"
		    %% 	    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))],
		    
		    Sql3 = case AllowedSave =:= ?NO of
		    	       true ->
		    		   ["update w_retailer set consume=consume+" ++ ?to_s(ShouldPay)
		    		    ++ case NewWithdraw =< 0 of
		    			   true  -> [];
		    			   false -> ", balance=balance-" ++ ?to_s(NewWithdraw)
		    		       end
		    		    ++ case Score == 0 andalso TicketScore =< 0 of
		    			   true  -> [];
		    			   false -> ", score=score+" ++ ?to_s(Score - TicketScore)
		    		       end
		    		    ++ ", change_date=\'" ++ ?to_s(DateTime) ++ "\'"
		    		    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))];
		    	       false ->
		    		   %% save with not enought money
		    		   case Vip of
		    		       true ->
		    			   ["update w_retailer set consume=consume+" ++ ?to_s(ShouldPay)
		    			    ++ ", balance=balance+" ++ ?to_s(HasPay - ShouldPay)
		    			    ++ case Score == 0 andalso TicketScore =< 0 of
		    				   true  -> [];
		    				   false -> ", score=score+" ++ ?to_s(Score - TicketScore)
		    			       end
		    			    ++ ", change_date=\'" ++ ?to_s(DateTime) ++ "\'"
		    			    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))];
		    		       false -> []
		    		   end
		    	   end,

		    Sql4 = case TicketBatchs of
			       [] -> [];
			       _ ->
				   C0 = ?sql_utils:condition(proplists, {<<"batch">>, TicketBatchs}),
				   case TicketCustom of
				       ?SCORE_TICKET ->
					   ["update w_ticket set "
					    "sale_rsn=\'" ++ ?to_s(SaleSn) ++ "\'"
					    ", state=" ++ ?to_s(?TICKET_STATE_CONSUMED)
					    ++ " where merchant=" ++ ?to_s(Merchant)
					    ++ " and retailer=" ++ ?to_s(Retailer)
					    ++ C0];
				       ?CUSTOM_TICKET -> 
					   ["update w_ticket_custom set "
					    "sale_rsn=\'" ++ ?to_s(SaleSn) ++ "\'"
					    ", state=" ++ ?to_s(?TICKET_STATE_CONSUMED) 
					    ++ ", ctime=\'" ++ ?to_s(DateTime) ++ "\'"
					    ++ ", retailer=" ++ ?to_s(Retailer)
					    ++ ", shop=" ++ ?to_s(Shop)
					    ++ " where merchant=" ++ ?to_s(Merchant)
					    ++ C0]; 
				       ?INVALID_OR_EMPTY ->
					   []
				   end
			   end,

		    Sql5 = case NewWithdraw > 0 andalso BankCards =/= [] of
			       true ->
				   LimitWithdraw = ?v(<<"limitWithdraw">>, Props),
				   UnlimitWithdraw = ?v(<<"unlimitWithdraw">>, Props),
				   NewBankCards = sort_charge_card(
						    card_pay(BankCards, LimitWithdraw, UnlimitWithdraw, []), []),
				   ?DEBUG("NewBankCards ~p", [NewBankCards]),
				   lists:foldr(
				     fun({BankCard}, Acc) ->
					     ?DEBUG("card ~p", [BankCard]),
					     CardNo = ?v(<<"card">>, BankCard, ?INVALID_OR_EMPTY),
					     CardDraw = ?v(<<"draw">>, BankCard, 0), 
					     ["insert into w_retailer_bank_flow(rsn"
					      ", retailer"
					      ", bank"
					      ", balance"
					      ", type"
					      ", merchant"
					      ", shop"
					      ", entry_date) values("
					      ++ "\'" ++ ?to_s(SaleSn) ++ "\',"
					      ++ ?to_s(Retailer) ++ ","
					      ++ ?to_s(CardNo) ++ ","
					      ++ ?to_s(CardDraw) ++ ","
					      ++ ?to_s(?CARD_CASH_OUT) ++ ","
					      ++ ?to_s(Merchant) ++ ","
					      ++ ?to_s(Shop) ++ ","
					      ++ "\'" ++ ?to_s(DateTime) ++ "\')"]
						 ++ case CardNo =:= ?INVALID_OR_EMPTY of
							true -> [];
							false ->
							    ["update w_retailer_bank set"
							     " balance=balance-" ++ ?to_s(CardDraw)
							     ++ " where merchant=" ++ ?to_s(Merchant)
							     ++ " and retailer=" ++ ?to_s(Retailer)
							     ++ " and id=" ++ ?to_s(CardNo)]
						    end ++ Acc
				     end, [], NewBankCards);
			       false -> []
			   end, 
		    
		    AllSql = Sql1 ++ [Sql2] ++ Sql3 ++ Sql4 ++ Sql5 ++ Sql6,
		    ?DEBUG("AllSql ~p", [AllSql]),
		    %% {reply, {ok,
		    %% 	     {SaleSn,
		    %% 	      ?v(<<"mobile">>, Account),
		    %% 	      ShouldPay,
		    %% 	      CurrentBalance - NewWithdraw,
		    %% 	      ?v(<<"score">>, Account) + Score - TicketScore} 
		    %% 	    }, State}
		    case ?sql_utils:execute(transaction, AllSql, SaleSn) of
		    	{ok, SaleSn} -> 
		    	    {reply, {ok,
		    		     {SaleSn,
		    		      ?v(<<"mobile">>, Account),
		    		      ShouldPay,
		    		      CurrentBalance - NewWithdraw,
				      Score,
		    		      ?v(<<"score">>, Account) + Score - TicketScore} 
		    		    }, State};
		    	Error ->
		    	    {reply, Error, State}
		    end
	    end;
	Error ->
	    {reply, Error, State}
    end;


handle_call({update_sale, Merchant, UTable, Inventories, Props, OldProps}, _From, State) ->
    ?DEBUG("update_sale with merchant ~p~n~p, props ~p, OldProps ~p",
	   [Merchant, Inventories, Props, OldProps]), 
    Curtime    = ?utils:current_time(format_localtime), 
    
    RSN        = ?v(<<"rsn">>, Props),
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    Datetime   = ?v(<<"datetime">>, Props, Curtime), 
    Employee   = ?v(<<"employee">>, Props),

    %% Balance    = ?v(<<"balance">>, Props),
    BasePay    = ?v(<<"base_pay">>, Props, 0),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    AliPay     = ?v(<<"aliPay">>, Props, 0),
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Ticket     = ?v(<<"ticket">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props),
    
    Total        = ?v(<<"total">>, Props),
    Oil          = ?v(<<"oil">>, Props, 0),
    Score        = ?v(<<"score">>, Props, 0), 
    AllowedSave  = ?v(<<"allow_save">>, Props, 0),
    Vip          = ?v(<<"vip">>, Props, false),
    
    RSNId        = ?v(<<"id">>, OldProps),
    TicketCustom = ?v(<<"tcustom">>, OldProps),
    OldEmployee  = ?v(<<"employ_id">>, OldProps),
    OldRetailer  = ?v(<<"retailer_id">>, OldProps),
    OldBasePay   = ?v(<<"base_pay">>, OldProps),
    OldShouldPay = ?v(<<"should_pay">>, OldProps),
    OldDatetime  = ?v(<<"entry_date">>, OldProps),
    OldScore     = ?v(<<"score">>, OldProps),

    OldCash       = ?v(<<"cash">>, OldProps),
    OldCard       = ?v(<<"card">>, OldProps),
    OldWxin       = ?v(<<"wxin">>, OldProps),
    OldAliPay     = ?v(<<"aliPay">>, OldProps),
    OldWithdraw   = ?v(<<"withdraw">>, OldProps),
    OldTicket     = ?v(<<"ticket">>, OldProps),
    OldVericate   = ?v(<<"verificate">>, OldProps),
    
    %% OldComment   = ?v(<<"comment">>, OldProps),
    OldTotal     = ?v(<<"total">>, OldProps),
    OldOil       = ?v(<<"oil">>, OldProps),
    SellType     = ?v(<<"type">>, OldProps),

    MShouldPay   = ShouldPay - OldShouldPay,
    MScore       = Score - OldScore,
    RealyShop    = realy_shop(Merchant, Shop),

    HasPay = Ticket + Withdraw + Wxin + AliPay + Card + Cash,
    CalcCharge = ShouldPay - HasPay,
    
    OldHasPay = OldTicket + OldWithdraw + OldWxin + OldAliPay + OldCard + OldCash,
    OldCalcCharge = OldShouldPay - OldHasPay,
    
    
    [NewTicket, NewWithdraw, NewWxin, NewAliPay, NewCard, NewCash] = _NewPays =
	case AllowedSave =:= ?NO of
	    true ->
		case SellType of
		    0 ->
			case ShouldPay >= 0 of
			    true ->
				pay_order(ShouldPay,
					  [Ticket, Withdraw, Wxin, AliPay, Card, Cash], []);
			    false ->
				pay_order(reject,
					  ShouldPay, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
			end;
		    1 -> pay_order(reject, ShouldPay, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
		end;
	    false ->
		pay_order(surplus, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
	end, 
    ?DEBUG("new pays ~p", [_NewPays]),

    NewDatetime = case Datetime =:= OldDatetime of
		      true -> Datetime;
		      false -> ?utils:correct_datetime(datetime, Datetime)
		  end,
    
    Sql1 = sql(update_wsale, RSN, Merchant, UTable, RealyShop, NewDatetime, OldDatetime, Inventories), 

    Updates = ?utils:v(employ, string, get_modified(Employee, OldEmployee))
	++ ?utils:v(retailer, integer, get_modified(Retailer, OldRetailer))
	++ ?utils:v(base_pay, float, get_modified(BasePay, OldBasePay))
	++ ?utils:v(should_pay, float, get_modified(ShouldPay, OldShouldPay))
	++ ?utils:v(cash, float, get_modified(NewCash, OldCash))
	++ ?utils:v(card, float, get_modified(NewCard, OldCard))
	++ ?utils:v(wxin, float, get_modified(NewWxin, OldWxin))
	++ ?utils:v(aliPay, float, get_modified(NewAliPay, OldAliPay))
	++ ?utils:v(withdraw, float, get_modified(NewWithdraw, OldWithdraw))
	++ ?utils:v(ticket, float, get_modified(NewTicket, OldTicket))
	++ ?utils:v(verificate, float, get_modified(Verificate, OldVericate))
	++ ?utils:v(total, integer, get_modified(Total, OldTotal))
	++ ?utils:v(oil, integer, get_modified(Oil, OldOil))
	++ ?utils:v(score, integer, get_modified(Score, OldScore))
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(entry_date, string, get_modified(NewDatetime, OldDatetime)), 

    case Retailer =:= OldRetailer of
	true ->
	    Sql2 =
		["update"
		 %% " w_sale"
		 ++ ?table:t(sale_new, Merchant, UTable)
		 ++ " set " ++ ?utils:to_sqls(proplists, comma, Updates) 
		 ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and merchant=" ++ ?to_s(Merchant)]
		
	    %% custome ticket syn consume time
		++ case NewDatetime =:= OldDatetime of
		       true -> [];
		       false ->
			   case TicketCustom =:= ?CUSTOM_TICKET of
			       true ->
				   ["update w_ticket_custom set ctime=\'"
				    ++ ?to_s(NewDatetime) ++ "\'"
				    ++ " where sale_rsn=\'" ++ ?to_s(RSN) ++ "\'"
				    ++ " and merchant=" ++ ?to_s(Merchant)];
			       false -> []
			   end
		   end,
	    ?DEBUG("Sql2 ~ts", [Sql2]),
	    
	    AllSql = Sql1 ++ Sql2 ++
		case ?utils:v_0(consume, float, MShouldPay)
		    ++ ?utils:v_0(score, integer, MScore)
		    ++ case AllowedSave =:= ?NO of 
			   true ->
			       case OldWithdraw - NewWithdraw /= 0 of
				   true -> ?utils:v_0(balance, float, OldWithdraw - NewWithdraw);
				   false -> []
			       end; 
			   false ->
			       case Vip and OldCalcCharge - CalcCharge /= 0 of
				   true ->
				       ?utils:v_0(balance, float, OldCalcCharge - CalcCharge);
				   false -> []
			       end
			       
		       end
		of
		    [] -> [];
		    U0 ->
			?DEBUG("U0 ~p", [U0]),
			["update w_retailer set " ++ ?utils:to_sqls(plus, comma, U0)
			 ++ ", change_date=" ++ "\"" ++ ?to_s(Curtime) ++ "\""
			 ++ " where id=" ++ ?to_s(Retailer)
			 ++ " and merchant=" ++ ?to_s(Merchant)]
		end
		++ case AllowedSave =:= ?YES andalso Vip andalso OldCalcCharge - CalcCharge /= 0 of
		    true ->
			["update"
			 ++ ?table:t(sale_new, Merchant, UTable)
			 ++ " set balance=balance+" ++ ?to_s(OldCalcCharge - CalcCharge)
			 ++ " where merchant=" ++ ?to_s(Merchant)
			 ++ " and retailer=" ++ ?to_s(Retailer)
			 ++ " and id>" ++ ?to_s(RSNId)];
		    false ->
			[]
		end
		++ case AllowedSave =:= ?NO andalso Vip andalso OldWithdraw - NewWithdraw /= 0 of
		       true ->
			   Sql01 = "update"
			       ++ ?table:t(sale_new, Merchant, UTable)
			       ++ " set balance=balance+" ++ ?to_s(OldWithdraw - NewWithdraw)
			       ++ " where merchant=" ++ ?to_s(Merchant)
			       ++ " and retailer=" ++ ?to_s(Retailer)
			       ++ " and id>" ++ ?to_s(RSNId),
			   
			   Sql00= "select a.id, a.rsn, a.retailer, a.bank, a.balance"
			       " from w_retailer_bank_flow a"
			       " where a.rsn=\'" ++ ?to_s(RSN) ++ "\'"
			       " and a.merchant=" ++ ?to_s(Merchant)
			       ++ " and a.shop=" ++ ?to_s(Shop)
			       ++ " and a.retailer=" ++ ?to_s(Retailer),

			   Sql02 = 
			       case ?sql_utils:execute(read, Sql00) of
				   {ok, []} -> [];
				   {ok, Flows} ->
				       NewFlows = card_flow_sort(Flows, []),
				       ?DEBUG("NewFlows ~p", [NewFlows]),
				       {_BackDraw, BackDrawSqls} = 
					   lists:foldl(
					     fun (_Flow, {LeftBackDraw, Acc}) when LeftBackDraw =< 0 ->
						     {LeftBackDraw, Acc};
						 ({FId, CardNo, Draw}, {LeftBackDraw, Acc}) ->
						     ?DEBUG("LeftBackDraw ~p, Draw ~p",
							    [LeftBackDraw, Draw]),
						     BackDraw =
							 case Draw - LeftBackDraw > 0 of
							     true -> LeftBackDraw;
							     false -> Draw
							 end,
						     ?DEBUG("BackDraw ~p", [BackDraw]),
						     {LeftBackDraw - BackDraw,
						      ["update w_retailer_bank_flow set "
						       ++ "balance=balance-" ++ ?to_s(BackDraw)
						       ++ " where id=" ++ ?to_s(FId)]
						      ++ case CardNo =:= ?INVALID_OR_EMPTY of
							     true -> [];
							     false ->
								 ["update w_retailer_bank set "
								  "balance=balance+" ++ ?to_s(BackDraw)
								  ++ " where merchant=" ++ ?to_s(Merchant)
								  ++ " and retailer=" ++ ?to_s(Retailer)
								  ++ " and id=" ++ ?to_s(CardNo)]
							 end ++ Acc} 
					     end, {OldWithdraw - NewWithdraw, []}, NewFlows),
				       BackDrawSqls;
				   _Error -> []
			       end,
			   [Sql01] ++ Sql02; 
		       false ->
			   []
		   end,
	    ?DEBUG("AllSql ~p", [AllSql]),
	    Reply = ?sql_utils:execute(
		       transaction, AllSql,
		       {RSN, MShouldPay, MScore, {OldRetailer, OldWithdraw}, {Retailer, NewWithdraw}}),
	    {reply, Reply, State}; 
	false ->
	    Sql0 = "select id, rsn, retailer, shop, merchant"
		", balance, should_pay, withdraw, lscore, score"
	    %% " from w_sale"
		" from" ++ ?table:t(sale_new, Merchant, UTable)
	    %% " where shop=" ++ ?to_s(Shop)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ " and retailer=" ++ ?to_s(Retailer)
		++ " and id<" ++ ?to_s(RSNId)
		++ " order by id desc limit 1",
	    
	    {ok, RetailerInfo} = ?w_retailer:retailer(get, Merchant, Retailer), 
	    {NewLastBalance, NewLastScore} = 
		case ?sql_utils:execute(s_read, Sql0) of
		    {ok, []} ->
			{?v(<<"balance">>, RetailerInfo), 0};
		    {ok, R}  ->
			{?v(<<"balance">>, R) - ?v(<<"withdraw">>, R),
			 ?v(<<"lscore">>, R) + ?v(<<"score">>, R)}
		end,
	    
	    Sql2 = 
		["update"
		 %% " w_sale"
		 ++ ?table:t(sale_new, Merchant, UTable)
		 ++ " set " ++ ?utils:to_sqls(
				  proplists, comma,
				  ?utils:v(balance, float, NewLastBalance)
				  ++ ?utils:v(lscore, float, NewLastScore) ++ Updates) 
		 ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and merchant=" ++ ?to_s(Merchant)]
		
		++ case NewDatetime =:= OldDatetime of
		   true -> [];
		   false ->
		       case TicketCustom =:= ?CUSTOM_TICKET of
			   true ->
			       ["update w_ticket_custom set ctime=\'"
				++ ?to_s(NewDatetime) ++ "\'"
				++ " where sale_rsn=\'" ++ ?to_s(RSN) ++ "\'"
				++ " and merchant=" ++ ?to_s(Merchant)];
			   false -> []
		       end
		   end,
	    
	    BackBalanceOfOldRetailer = case AllowedSave =:= ?NO of
					   true -> OldWithdraw;
					   false -> OldCalcCharge
				       end,
	    
	    BalanceOfNewRetailer =  case AllowedSave =:= ?NO of
					true -> NewWithdraw;
					false -> CalcCharge
				    end,

	    AllSql = Sql1 ++ [Sql2] ++ 
		["update w_retailer set balance=balance+" ++ ?to_s(BackBalanceOfOldRetailer) 
		 ++ ", score=score-" ++ ?to_s(OldScore)
		 ++ ", consume=consume-" ++ ?to_s(OldShouldPay)
		 ++ " where id=" ++ ?to_s(OldRetailer),

		 "update"
		 %% " w_sale"
		 ++ ?table:t(sale_new, Merchant, UTable)
		 ++ " set balance=balance+" ++ ?to_s(BackBalanceOfOldRetailer)
		 ++ ", lscore=lscore-" ++ ?to_s(OldScore)
		 %% ++ " where shop=" ++ ?to_s(Shop)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(OldRetailer)
		 ++ " and id>" ++ ?to_s(RSNId),

		 
		 "update w_retailer set balance=balance-" ++ ?to_s(BalanceOfNewRetailer) 
		 ++ ", score=score+" ++ ?to_s(Score)
		 ++ ", consume=consume+" ++ ?to_s(ShouldPay)
		 ++ " where id=" ++ ?to_s(Retailer), 

		 "update"
		 %% " w_sale"
		 ++ ?table:t(sale_new, Merchant, UTable)
		 ++ " set balance=balance-" ++ ?to_s(BalanceOfNewRetailer)
		 ++ ", lscore=lscore+" ++ ?to_s(Score)
		 %% ++ " where shop=" ++ ?to_s(Shop)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(Retailer)
		 ++ " and id>" ++ ?to_s(RSNId)
		],

	    Reply = ?sql_utils:execute(
		       transaction, AllSql,
		       {RSN, MShouldPay, MScore,
			{OldRetailer, OldWithdraw}, {Retailer, NewWithdraw}}),
	    %% ?w_user_profile:update(retailer, Merchant),

	    {reply, Reply, State}

    end; 

handle_call({check_new, Merchant, UTable, RSN, Mode}, _From, State) ->
    ?DEBUG("check_new with merchant ~p, RSN ~p, mode ~p", [Merchant, RSN, Mode]),
    Sql0 = "select rsn, state from" ++ ?table:t(sale_new, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'",
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Sale} ->
	    <<_SaleState:1/binary, T/binary>> = ?v(<<"state">>, Sale),
	    BinMode = ?to_b(Mode),
	    Sql1 = "update" ++ ?table:t(sale_new, Merchant, UTable)
		++ " set state=\'" ++ ?to_s(<<BinMode/binary, T/binary>>) ++ "\'"
		++ ", check_date=\'" ++ ?utils:current_time(format_localtime) ++ "\'"
		++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		++ " and merchant=" ++ ?to_s(Merchant), 
	    Reply = ?sql_utils:execute(write, Sql1, RSN),
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_new, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("list_new with merchant ~p, condtions ~p", [Conditions, Merchant]), 
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),
    Sql = "select a.id"
	", a.rsn"
	", a.retailer as retailer_id"
	", a.shop as shop_id"
	", a.balance"
	", a.should_pay"
	", a.has_pay"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.verificate"
	", a.total"
	", a.comment"
	", a.rdate"
	", a.entry_date"
	
	", b.name as employee"
	", c.name as retailer"
	", d.name as shop"
	
    %% " from w_sale a"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	++ " left join employees b on a.employ=b.number"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer c on a.retailer=c.id"
	++ " left join shops d on a.shop=d.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ";",
    {ok, Records} = ?mysql:fetch(read, Sql),
    {reply, ?to_tl(Records), State};

handle_call({get_new, Merchant, UTable, RSN}, _From, State) ->
    ?DEBUG("get_new with merchant ~p, rsn ~p", [Merchant, RSN]),
    Sql = "select a.id"
	", a.rsn"
	", a.employ as employ_id"
	", a.retailer as retailer_id"
	", a.shop as shop_id"
	", a.tbatch"
	", a.tcustom"
	", a.balance"
	", a.should_pay"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.withdraw"
	", a.ticket"
	", a.g_ticket"
	", a.verificate"
	", a.total"
	", a.oil"
	", a.lscore"
	", a.score"
	", a.comment"
	", a.type"
	", a.state"
	", a.entry_date"

	", b.name as retailer"
	", b.mobile"
	", b.address"
	
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	" left join w_retailer b on a.retailer=b.id and a.merchant=b.merchant"
	
	++ " where a.rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and a.merchant=" ++ ?to_s(Merchant), 
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({delete_new, Merchant, UTable, RSN, Retailer}, _From, State) ->
    ?DEBUG("delete_new with merchant ~p, rsn ~p", [Merchant, RSN]),
    Sqls = ["delete from"
	    %% " w_sale"
	    ++ ?table:t(sale_new, Merchant, UTable)
	    ++ " where merchant=" ++ ?to_s(Merchant)
	    ++ " and rsn =\'" ++ ?to_s(RSN) ++ "\'",
	    
	    "delete from w_retailer_bank_flow where merchant=" ++ ?to_s(Merchant)
	    ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"
	    ++ " and retailer=" ++ ?to_s(Retailer)
	   ],
    Reply =  ?sql_utils:execute(transaction, Sqls, RSN),
    {reply, Reply, State};

handle_call({last_sale, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("last_sale with merchant ~p, condtions ~p",
	   [Merchant, Conditions]),
    Retailer = ?v(<<"retailer">>, Conditions),
    Shop     = ?v(<<"shop">>, Conditions),
    C1 = [{<<"a.shop">>, Shop},
	  {<<"a.merchant">>, Merchant},
	  {<<"a.retailer">>, Retailer},
	  {<<"a.type">>, 0}],

    C2 = proplists:delete(<<"retailer">>,
			  proplists:delete(<<"shop">>, Conditions)),
    CorrectC2 = ?utils:correct_condition(<<"b.">>, C2),

    Sql = 
	"select a.rsn, b.id, b.rsn, b.style_number, b.sell_style"
	", b.fdiscount, b.fprice"
    %% " from w_sale a, w_sale_detail b"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a,"
	++ ?table:t(sale_detail, Merchant, UTable) ++ " b"
	++ " where a.rsn=b.rsn" ++ ?sql_utils:condition(proplists, C1)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectC2)
	++ " order by id desc limit 1",

    %% Sql = "select a.id, a.rsn, a.style_number, a.sell_style"
    %% 	", a.fdiscount, a.fprice"
    %% 	" from w_sale_detail a"
    %% 	" inner join "
    %% 	  "(select rsn from w_sale where " ++ ?utils:to_sqls(proplists, C1)
    %% 	++ ") b on a.rsn=b.rsn",
    %% 	%% " where a.rsn in"
    %% 	%% "(select rsn from w_sale where "
    %% 	%% ++ ?utils:to_sqls(proplists, C1) ++ ")"
    %% 	%% ++ ?sql_utils:condition(proplists, C2)
    %% 	++ " where " ++ ?utils:to_sqls(proplists, CorrectC2)
    %% 	++ " order by id desc limit 1",
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({trace_sale, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("trance_sale with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = sale_new(rsn_groups, 'and', {Merchant, UTable}, Conditions, fun() -> " order by id desc" end),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({get_sale_rsn, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("get_sale_rsn with merchant=~p, conditions ~p", [Merchant, Conditions]),
    
    {DetailConditions, SaleConditions} =
	filter_condition(wsale, [{<<"merchant">>, Merchant}|Conditions], [], []),
    ?DEBUG("sale conditions ~p, detail condition ~p", [SaleConditions, DetailConditions]), 

    {StartTime, EndTime, CutSaleConditions}
	= ?sql_utils:cut(fields_with_prifix, SaleConditions),
    
    Sql1 = 
	"select a.rsn from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    Sql = 
	case ?v(<<"rsn">>, SaleConditions, []) of
	    [] ->
		case DetailConditions of
		    [] -> Sql1;
		    _ ->
			"select a.rsn"
			    " from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
			    " inner join (select rsn from" ++ ?table:t(sale_detail, Merchant, UTable)
			    ++ " where merchant=" ++ ?to_s(Merchant)
			%% ++ "\'M-" ++ ?to_s(Merchant) ++"%\'"
			    ++ ?sql_utils:condition(proplists, DetailConditions) ++ ") b"
			    " on a.rsn=b.rsn"
			    " where "
			    ++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
			    ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) 
		end;
	    _ -> Sql1 
	end ++ " order by id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_sale_rsn, Merchant, UTable, {ViewValue, Conditions}}, _From, State) ->
    {StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),

    Limit = ?w_retailer:get(prompt, Merchant),
    Sql = "select id, rsn"
    %% " from w_sale"
	" from" ++ ?table:t(sale_new, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, undefined)
	++ " and rsn like \'%" ++ ?to_s(ViewValue) ++ "\'"
	++ " order by id desc"
	++ " limit " ++ ?to_s(Limit),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({history_retailer, Merchant, UTable, Retailer, Goods}, _From, State) ->
    ?DEBUG("history_retailer with merchant ~p, retailer ~p~n goods ~p",
	   [Merchant, Retailer, Goods]),
    [{S1, B1}|T] = Goods,

    Sql = "select"
	" style_number"
	", brand"
	" from"
    %% " w_sale_detail"
	++ ?table:t(sale_detail, Merchant, UTable)
	++ " where rsn in"
	"(select rsn"
    %%" from w_sale"
	" from" ++ ?table:t(sale_new, Merchant, UTable)
	++ " where retailer="++ ?to_s(Retailer) ++ ")" 
	++ " and (style_number, brand) in("
	++ lists:foldr(
	     fun({StyleNumber, Brand}, Acc)->
		     "(\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ")," ++ Acc
	     end, [], T)
	++ "(\'" ++ ?to_s(S1) ++ "\'," ++ ?to_s(B1) ++ "))",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 


handle_call({rsn_detail, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]),
    C = ?utils:to_sqls(proplists, Conditions),
    Sql = "select id"
	", rsn"
	", style_number"
	", brand as brand_id"
	", color as color_id"
	", size"
	", total as amount"
	", exist"
    %% " from w_sale_detail_amount"
	" from" ++ ?table:t(sale_note, Merchant, UTable)
	++ " where " ++ C, 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({trans_detail, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("trans_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql =
	%% " select a.id"
	%% ", a.rsn"
	%% ", a.style_number"
	%% ", a.brand_id"
	%% ", a.type_id"
	%% ", a.sex"
	%% ", a.s_group"
	%% ", a.free"
	%% ", a.season"
	%% ", a.firm_id"
	%% ", a.year"
	%% ", a.in_datetime"
	%% ", a.total"
	%% ", a.pid"
	%% ", a.sid"
	%% ", a.mid"
	%% ", a.org_price"
	%% ", a.tag_price"
	%% ", a.discount"
	%% ", a.fdiscount"
	%% ", a.rdiscount"
	%% ", a.fprice"
	%% ", a.rprice"
	%% ", a.oil" 
	%% ", a.path"
	%% ", a.comment"
	%% ", a.has_rejected"
	
	%% ", b.color as color_id"
	%% ", b.size"
	%% ", b.total as amount"
	
	%% " from "
	
	"select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand as brand_id"
	", a.type as type_id"
	", a.sex"
	", a.s_group"
	", a.free"
	", a.season"
	", a.firm as firm_id"
	", a.year"
	", a.in_datetime"
	", a.total"
	", a.promotion as pid"
	", a.score as sid"
	", a.commision as mid"
	", a.org_price"
	", a.tag_price"
	", a.discount"
	", a.fdiscount"
	", a.rdiscount"
	", a.fprice"
	", a.rprice"
	", a.oil"
	", a.path"
	", a.comment"
	", a.reject as has_rejected"

	", b.color as color_id"
	", b.size"
	", b.total as amount"

	", c.name as type"
	
	" from" ++ ?table:t(sale_detail, Merchant, UTable) ++ " a"
	
	" inner join" ++ ?table:t(sale_note, Merchant, UTable) ++ " b"
	" on a.rsn=b.rsn"
	" and a.merchant=b.merchant"
	" and a.style_number=b.style_number"
	" and a.brand=b.brand"

	" left join inv_types c on a.merchant=b.merchant and a.type=c.id"
	
	++ " where " ++ ?utils:to_sqls(proplists, ?utils:correct_condition(<<"a.">>, Conditions)), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% filter with pagination
%% =============================================================================
handle_call({total_news, Merchant, UTable, Fields}, _From, State) ->
    CountSql = count_table(w_sale, {Merchant, UTable}, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_news, Merchant, UTable, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_with_and:" "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n" "fields ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = filter_table(
	    w_sale_with_page, {Merchant, UTable}, CurrentPage, ItemsPerPage, Fields), 
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% =============================================================================
%% reject
%% =============================================================================
handle_call({reject_sale, Merchant, UTable, Inventories, Props, OldProps}, _From, State) ->
    ?DEBUG("reject_sale with merchant ~p~n~p, props ~p, OldProps ~p",
	   [Merchant, Inventories, Props, OldProps]), 
    UserId = ?v(<<"user">>, Props, -1),
    SaleRsn    = ?v(<<"sale_rsn">>, Props),
    Retailer   = ?v(<<"retailer_id">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    %% Datetime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    Datetime   = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Employe    = ?v(<<"employee">>, Props),

    %% Balance    = ?v(<<"balance">>, Props), 
    Comment    = ?v(<<"comment">>, Props, []),
    BasePay    = ?v(<<"base_pay">>, Props, 0),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    AliPay     = ?v(<<"aliPay">>, Props, 0),
    
    
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),
    Score      = ?v(<<"score">>, Props, 0),
    Oil        = ?v(<<"oil">>, Props, 0),

    Ticket       = ?v(<<"ticket">>, Props, 0),
    TicketScore  = ?v(<<"ticket_score">>, Props, 0),
    TicketBatchs = ?v(<<"tbatch">>, Props, []),
    GTicket      = ?v(<<"g_ticket">>, Props, ?NO),
    TicketCustom = ?v(<<"tcustom">>, Props, ?INVALID_OR_EMPTY),
    SaleState    = ?v(<<"state">>, Props),
    RejectAll    = case ?v(<<"reject_all">>, Props) of
		       ?YES -> 2;
		       ?NO  -> 1
		   end, 
    AllowedSave  = ?v(<<"allow_save">>, Props, 0),
    HasPay = Ticket + Withdraw + Wxin + AliPay + Card + Cash,
    
    Sql0 = "select id, name, balance, score, type from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} -> 
	    RejectRsn = lists:concat(
			  ["M-",
			   ?to_i(Merchant),
			   "-S-",
			   ?to_i(Shop),
			   "-R-",
			   ?inventory_sn:sn(w_sale_reject_sn, Merchant)]),
	    {ShopType, RealyShop} = realy_shop(reject, Merchant, Shop),

	    Sql1 =
		case ShopType of
		    ?BAD_REPERTORY ->
			lists:foldr(
			  fun({struct, Inv}, Acc0)->
				  Amounts = ?v(<<"amounts">>, Inv),
				  wsale(reject_badrepo,
					RejectRsn,
					Datetime,
					Merchant,
					{Shop, RealyShop},
					Inv,
					Amounts) ++ Acc0
			  end, [], Inventories);
		    _ ->
			lists:foldr(
			  fun({struct, Inv}, Acc0)->
				  Amounts = ?v(<<"amounts">>, Inv),
				  wsale(reject,
					RejectRsn,
					SaleRsn,
					Datetime,
					{Merchant, UTable},
					RealyShop,
					Inv,
					Amounts) ++ Acc0
			  end, [], Inventories)
		end,

	    CurrentBalance = retailer(balance, Account),
	    CurrentScore = retailer(score, Account),

	    
	    [NewTicket, NewWithdraw, NewWxin, NewAliPay, NewCard, NewCash] = NewPays =
		case AllowedSave =:= ?NO of
		    true ->
			case ShouldPay >= 0 of
			    true ->
				pay_order(ShouldPay,
					  [Ticket, Withdraw, Wxin, AliPay, Card, Cash], []);
			    false ->
				pay_order(reject,
					  ShouldPay, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
			end;
		    false ->
			pay_order(surplus, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], [])
		end,
	    ?DEBUG("new pays ~p", [NewPays]),
	    
	    Sql2 = ["insert into"
		    %% " w_sale"
		    ++ ?table:t(sale_new, Merchant, UTable)
		    ++ "(rsn"
		    ", account"
		    ", employ"
		    ", retailer"
		    ", shop"
		    ", merchant"
		    ", tbatch"
		    ", tcustom"
		    ", balance"
		    ", base_pay"
		    ", should_pay"
		    ", cash"
		    ", card"
		    ", wxin"
		    ", aliPay"
		    ", ticket"
		    ", withdraw"
		    ", verificate"
		    ", total"
		    ", oil"
		    ", lscore"
		    ", score"
		    ", comment"
		    ", type"
		    ", entry_date) values("
		    ++ "\"" ++ ?to_s(RejectRsn) ++ "\","
		    ++ ?to_s(UserId) ++ ","
		    ++ "\'" ++ ?to_s(Employe) ++ "\',"
		    ++ ?to_s(Retailer) ++ ","
		    ++ ?to_s(Shop) ++ ","
		    ++ ?to_s(Merchant) ++ ","
		    %% ++ ?to_s(TicketBatch) ++ ","
		    ++ ?to_s(-1) ++ ","
		    ++ ?to_s(TicketCustom) ++ ","
		    ++ ?to_s(CurrentBalance) ++ ","
		    ++ ?to_s(-BasePay) ++ ","
		    ++ ?to_s(-ShouldPay) ++ ","
		    ++ ?to_s(-NewCash) ++ ","
		    ++ ?to_s(-NewCard) ++ ","
		    ++ ?to_s(-NewWxin) ++ ","
		    ++ ?to_s(-NewAliPay) ++ ","
		    ++ ?to_s(-NewTicket) ++ ","
		    %% ++ case Withdraw == ShouldPay of
		    %%        true  -> ?to_s(0) ++ ",";
		    %%        false -> ?to_s((Withdraw - ShouldPay)) ++ ","
		    %%    end
		    ++ ?to_s(-NewWithdraw) ++ ","
		    ++ ?to_s(-Verificate) ++ ","
		    ++ ?to_s(-Total) ++ ","
		    ++ ?to_s(-Oil) ++ ","
		    ++ ?to_s(CurrentScore) ++ ","
		    ++ ?to_s(-Score) ++ ","
		    ++ "\'" ++ ?to_s(Comment) ++ "\'," 
		    ++ ?to_s(type(reject)) ++ ","
		    ++ "\'" ++ ?to_s(Datetime) ++ "\')",

		    "update"
		    %% " w_sale"
		    ++ ?table:t(sale_new, Merchant, UTable)
		    ++ " set state=\'" ++ ?utils:replace_list_at(SaleState, 2, RejectAll) ++ "\'"
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and rsn=\'" ++ ?to_s(SaleRsn) ++ "\'"
		   ],

	    ?DEBUG("TicketScore ~p", [TicketScore]),
	    Sql3 = ["update w_retailer set consume=consume-" ++ ?to_s(ShouldPay)
		    ++ case AllowedSave =:= ?NO of
			   true ->
			       case NewWithdraw > 0 of
				   true -> ", balance=balance+" ++ ?to_s(NewWithdraw);
				   false -> []
			       end;
			   false ->
			       ", balance=balance+" ++ ?to_s(ShouldPay - HasPay)
		       end 
		    ++ case TicketScore - Score /= 0 of
			   true -> ", score=score+" ++ ?to_s(TicketScore - Score);
			   false -> []
		       end
		    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))], 

	    Sql4 =
		case TicketBatchs of
		    [] -> [];
		    _ ->
			C0 = ?sql_utils:condition(proplists, {<<"batch">>, TicketBatchs}),
			case TicketCustom of 
			    ?SCORE_TICKET ->
				case ?sql_utils:execute(
					s_read,
					"select id, batch, retailer from w_ticket"
					" where merchant=" ++ ?to_s(Merchant)
					++ " and retailer=" ++ ?to_s(Retailer)
					++ " and state in(0,1)") of
				    {ok, []} ->
					["update w_ticket set sale_rsn=\'-1\'"
					 ", state=" ++ ?to_s(?TICKET_STATE_CHECKED) 
					 ++ " where merchant=" ++ ?to_s(Merchant)
					 ++ " and retailer=" ++ ?to_s(Retailer)
					 ++ C0]; 
				    {ok, _} ->
					["delete from w_ticket"
					 ++ " where merchant=" ++ ?to_s(Merchant)
					 ++ " and retailer=" ++ ?to_s(Retailer)
					 ++ C0]
				end; 
			    ?CUSTOM_TICKET ->
				["update w_ticket_custom set sale_rsn=\'-1\'"
				 ++ ", state=" ++ ?to_s(?TICKET_STATE_CHECKED)
				 ++ ", shop=" ++ ?to_s(?INVALID_OR_EMPTY)
				 ++ ", ctime=\'" ++ ?to_s(?TICKET_DATE_UNLIMIT) ++ "\'"
				 ++ " where merchant=" ++ ?to_s(Merchant)
				 ++ " and retailer=" ++ ?to_s(Retailer)
				 ++ C0];
			    ?INVALID_OR_EMPTY ->
				[]
			end
		end,

	    ?DEBUG("Sql4 ~p", [Sql4]),

	    Sql5 = 
		case NewWithdraw > 0 of
		    true ->
			Sql01= "select id, rsn, retailer, bank, balance from w_retailer_bank_flow"
			    " where rsn=\'" ++ ?to_s(SaleRsn) ++ "\'"
			    " and merchant=" ++ ?to_s(Merchant)
			    ++ " and shop=" ++ ?to_s(Shop)
			    ++ " and retailer=" ++ ?to_s(Retailer),
			case ?sql_utils:execute(read, Sql01) of
			    {ok, []} -> [];
			    {ok, Flows} ->
				NewFlows = card_flow(Flows, []),
				?DEBUG("NewFlows ~p", [NewFlows]),
				{_BackDraw, BackDrawSqls} = 
				    lists:foldl(
				      fun (_Flow, {LeftBackDraw, Acc}) when LeftBackDraw =< 0 ->
					      {LeftBackDraw, Acc};
					  ({_FId, CardNo, Draw}, {LeftBackDraw, Acc}) ->
					      ?DEBUG("LeftBackDraw ~p, Draw ~p", [LeftBackDraw, Draw]),
					      BackDraw =
						  case LeftBackDraw - Draw > 0 of
						      true -> Draw;
						      false -> LeftBackDraw
						  end,
					      ?DEBUG("BackDraw ~p", [BackDraw]),
					      {LeftBackDraw - Draw,
					       ["insert into w_retailer_bank_flow(rsn"
						", retailer"
						", bank"
						", balance"
						", type"
						", merchant"
						", shop"
						", entry_date) values("
						++ "\'" ++ ?to_s(RejectRsn) ++ "\',"
						++ ?to_s(Retailer) ++ ","
						++ ?to_s(CardNo) ++ ","
						++ ?to_s(-BackDraw) ++ ","
						++ ?to_s(?CARD_CASH_IN) ++ "," 
						++ ?to_s(Merchant) ++ ","
						++ ?to_s(Shop) ++ ","
						++ "\'" ++ ?to_s(Datetime) ++ "\')"]
					       ++ case CardNo =:= ?INVALID_OR_EMPTY of
						      true -> [];
						      false -> 
							  ["update w_retailer_bank set"
							   " balance=balance+" ++ ?to_s(BackDraw)
							   ++ " where merchant=" ++ ?to_s(Merchant)
							   ++ " and retailer=" ++ ?to_s(Retailer)
							   ++ " and id=" ++ ?to_s(CardNo)]
						  end ++ Acc} 
				      end, {NewWithdraw, []}, NewFlows),
				BackDrawSqls
			end;
		    false -> []
		end,
	    ?DEBUG("Sql5 ~p", [Sql5]),
	    
	    Sql6 =
		case GTicket of
		    ?NO -> [];
		    ?YES ->
			["update w_ticket_custom set state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD)
			 ++ " where sale_new=\'" ++ ?to_s(SaleRsn) ++ "\'"
			 ++ " and merchant=" ++ ?to_s(Merchant)
			 ++ " and retailer=" ++ ?to_s(Retailer)
			 ++ " and state=" ++ ?to_s(?TICKET_STATE_CHECKED)]
		end, 
	    AllSql = Sql1 ++ Sql2 ++ Sql3 ++ Sql4 ++ Sql5 ++ Sql6, 
	    case ?sql_utils:execute(transaction, AllSql, RejectRsn) of
		{error, _} = Error ->
		    {reply, Error, State};
		OK ->
		    %% case NewWithdraw =/= 0 orelse TicketScore - Score =/= 0 of
		    %% 	true  -> ?w_user_profile:update(retailer, Merchant);
		    %% 	false -> ok
		    %% end,
		    {reply, {OK,
			     Shop,
			     Retailer,
			     ?v(<<"type">>, Account), TicketScore - Score, NewWithdraw}, State}
	    end; 
	Error ->
	    {reply, Error, State}
    end;

handle_call({total_rsn_group, MatchMode, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_rsn_group with merchant ~p, matchMode ~p, conditions ~p", [Merchant, MatchMode, Conditions]),
    MDiscount = ?v(<<"mdiscount">>, Conditions),
    LDiscount = ?v(<<"ldiscount">>, Conditions),
    LSell     = ?v(<<"lsell">>, Conditions),
    MSell     = ?v(<<"msell">>, Conditions),
    
    NewConditions = lists:keydelete(
		      <<"mdiscount">>, 1,
		      lists:keydelete(
			<<"ldiscount">>, 1,
			lists:keydelete(
			  <<"lsell">>, 1,
			  lists:keydelete(
			    <<"msell">>, 1, Conditions)))),
    
    {DConditions, SConditions} = filter_condition(wsale, NewConditions, [], []),
    
    
    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions), 
    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),

    %% ?DEBUG("CutDCondtions ~p", [CutDCondtions]),
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    Sql = "select count(*) as total"
    	", SUM(b.total) as t_amount"
	", SUM(b.oil) as t_oil"
	", SUM(b.tag_price * b.total) as t_tbalance"
    	", SUM(b.rprice * b.total) as t_balance"
	", SUM(b.org_price * b.total) as t_obalance"
	
    %% " from w_sale_detail b, w_sale a"
	" from "
	++ ?table:t(sale_detail, Merchant, UTable) ++ " b,"
	++ ?table:t(sale_new, Merchant, UTable) ++ " a" 
    	" where "
    %% ++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:like_condition(style_number, MatchMode, CorrectCutDConditions, <<"b.style_number">>)
	++ case MDiscount of
	       undefined -> [];
	       _ ->
		   " and b.rprice/b.tag_price>" ++ ?to_s(?to_f(MDiscount/100))
	   end
	++ case LDiscount of
	       undefined -> [];
	       _ ->
		   " and b.rprice/b.tag_price<" ++ ?to_s(?to_f(LDiscount/100))
	   end
	++ case LSell of
	       undefined -> [];
	       _ ->
		   " and b.total<" ++ ?to_s(LSell)
	   end

	++ case MSell of
	       undefined -> [];
	       _ ->
		   " and b.total>" ++ ?to_s(MSell)
	   end
	
	%% ++ case MatchMode of
	%%        ?AND ->
	%% 	   ?sql_utils:condition(proplists, CorrectCutDConditions);
	%%        ?LIKE ->
	%% 	   case ?v(<<"b.style_number">>, CorrectCutDConditions, []) of
	%% 	       [] ->
	%% 		   ?sql_utils:condition(proplists, CorrectCutDConditions);
	%% 	       StyleNumber ->
	%% 		   " and b.style_number like '" ++ ?to_s(StyleNumber) ++ "%'"
	%% 		       ++ ?sql_utils:condition(
	%% 			     proplists, lists:keydelete(<<"b.style_number">>, 1, CorrectCutDConditions))
	%% 	   end
	%%    end
	++ " and b.rsn=a.rsn"
	
	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime), 
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total_firm_detail, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_rsn_group with merchant ~p, conditions ~p", [Merchant, Conditions]), 
    Sql = "select count(*) as total"
    	", SUM(total) as t_amount" 
    %% " from w_sale_detail"
	" from" ++ ?table:t(sale_detail, Merchant, UTable) 
    	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " group by style_number, brand, shop",
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_rsn_group,
	     {Mode, Sort},
	     MatchMode,
	     {Merchant, UTable},
	     CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_rsn_group_and: mode ~p, sort ~p, MatchMode ~p, currentPage ~p"
	   ", ItemsPerpage ~p, Merchant ~p~n",
	   [Mode, Sort, MatchMode, CurrentPage, ItemsPerPage, Merchant]), 
    Sql = sale_new(rsn_groups, MatchMode, {Merchant, UTable}, Conditions,
		   fun() ->
			   rsn_order(Mode) ++ ?sql_utils:sort(Sort)
			       ++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
			       ++ ", " ++ ?to_s(ItemsPerPage)
		   end),
    
    %% {DConditions, SConditions} = filter_condition(wsale, Conditions, [], []),

    %% {StartTime, EndTime, CutSConditions}
    %% 	= ?sql_utils:cut(fields_with_prifix, SConditions),

    %% {_, _, CutDCondtions}
    %% 	= ?sql_utils:cut(fields_no_prifix, DConditions),

    %% CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),
    
    %% Sql = "select b.id, b.rsn, b.style_number"
    %% 	", b.brand as brand_id, b.type as type_id, b.season, b.firm as firm_id"
    %% 	", b.year, b.s_group, b.free, b.total, b.promotion as pid, b.score as sid"
    %% 	", b.org_price, b.ediscount, b.tag_price, b.fdiscount, b.rdiscount"
    %% 	", b.fprice, b.rprice"
    %% 	", b.path, b.comment, b.entry_date"
	
    %% 	", a.shop as shop_id"
    %% 	", a.retailer as retailer_id"
    %% 	", a.employ as employee_id"
    %% 	", a.type as sell_type"
	
    %% 	" from w_sale_detail b, w_sale a"
	
    %% 	" where "
    %% 	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
    %% 	++ "b.rsn=a.rsn"
	
    %% 	++ ?sql_utils:condition(proplists, CutSConditions)
    %% 	++ " and a.merchant=" ++ ?to_s(Merchant)
    %% 	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
    %% 	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({new_trans_export, Merchant, UTable, Conditions}, _From, State)->
    ?DEBUG("new_trans_export with merchant ~p, condition ~p", [Merchant, Conditions]),
    Sql = filter_table(w_sale, {Merchant, UTable}, Conditions),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_trans_note_export, Merchant, UTable, Conditions}, _From, State)->
    %% ?DEBUG("new_trans_note_export: merchant ~p\nConditions~p", [Merchant, Conditions]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),

    Sql = "select a.id, a.rsn, a.style_number"
	", a.brand_id"
	", a.type_id"
	", a.firm_id"
	", a.season"
	", a.year"
	", a.in_datetime"
	", a.s_group"
	", a.total"
	", a.pid"
	", a.sid"
	", a.org_price, a.tag_price, a.rprice, a.entry_date"
	
	", a.shop_id"
	", a.retailer_id"
	", a.employee_id"
	", a.sell_type"

	", b.name as brand"
	", d.name as type"
	", e.name as firm"
	", f.name as shop"
	", g.name as retailer"
	", h.name as employee"
	", j.name as promotion"
	", k.name as score"

	" from (" 
	"select a.id, a.rsn, a.style_number"
	", a.brand as brand_id"
	", a.type as type_id"
	", a.firm as firm_id"
	", a.season"
	", a.year"
	", a.in_datetime"
	", a.s_group"
	", a.total"
	", a.promotion as pid"
	", a.score as sid"
	", a.org_price, a.tag_price, rprice, a.entry_date"

	", b.shop as shop_id"
	", b.retailer as retailer_id"
	", b.employ as employee_id"
	", b.type as sell_type"
	
    %% " from w_sale_detail a"
	" from" ++ ?table:t(sale_detail, Merchant, UTable) ++ " a"
	" inner join"
	++ ?table:t(sale_new, Merchant, UTable) ++ " b on a.rsn=b.rsn"

	" where " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ") a"

	" left join brands b on a.brand_id=b.id"
	" left join inv_types d  on a.type_id=d.id"
	" left join suppliers e on a.firm_id=e.id"

	" left join shops f on a.shop_id=f.id"
	" left join w_retailer g on a.retailer_id=g.id"
	" left join employees h on a.employee_id=h.number and h.merchant=" ++ ?to_s(Merchant)

	++ " left join w_promotion j on a.pid=j.id"
	++ " left join w_score k on a.sid=k.id"
	
	++ " order by a.id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({new_trans_note_color_size_export, Merchant, UTable, Conditions}, _From, State)->
    %% ?DEBUG("new_trans_note_colro_size_export: merchant ~p\nConditions~p", [Merchant, Conditions]),

    Sql = "select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand"
	", a.color"
	", a.size"
	", a.total"
	", a.shop" 
	", a.merchant"

	", b.name as cname"
	
    %% " from w_sale_detail_amount a"
	" from" ++ ?table:t(sale_note, Merchant, UTable) ++ " a"
	" left join colors b on a.merchant=b.merchant and a.color = b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({update_price, Merchant, UTable, RSN, Updates}, _From, State) ->
    ?DEBUG("update_price: merchant ~p, RSN ~p, Updates ~p", [Merchant, RSN, Updates]),
    OrgPrice = ?v(<<"org_price">>, Updates),
    TagPrice = ?v(<<"tag_price">>, Updates),
    StyleNumber = ?v(<<"style_number">>, Updates),
    Brand = ?v(<<"brand">>, Updates), 
    EDiscount = case TagPrice of
		    undefined -> 0;
		    _ -> ?w_good_sql:stock(ediscount, OrgPrice, TagPrice)
		end, 
    
    Sql = "update"
    %% " w_sale_detail"
	++ ?table:t(sale_detail, Merchant, UTable)
	++ " set org_price=" ++ ?to_s(OrgPrice)
	++ ", ediscount=" ++ ?to_s(EDiscount)
	++ " where rsn=\'" ++ ?to_s(RSN)  ++ "\'"
	++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(Brand)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({total_employee_evaluation, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_employee_evaluation: merchant ~p, conditions ~p", [Merchant, Conditions]),
    SortConditions = sort_condition(wsale, Merchant, Conditions), 
    Sql = "select count(*) as total"
	", SUM(a.balance) as t_balance"
	", SUM(a.cash) as t_cash"
	", SUM(a.card) as t_card"
	", SUM(a.wxin) as t_wxin"
	", SUM(a.aliPay) as t_aliPay"
	", SUM(a.draw) as t_draw"
	", SUM(a.veri) as t_veri"
	", SUM(a.ticket) as t_ticket" 
	" from "
	" (select a.employee_id"
	", a.shop_id"
	", a.balance"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.draw"
	", a.ticket"
	", a.veri"
	" from "
	"(select merchant"
	", employ as employee_id"
	", shop as shop_id"
	", SUM(should_pay) as balance"
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wxin) as wxin"
	", SUM(aliPay) as aliPay"
	", SUM(withdraw) as draw"
	", SUM(verificate) as veri"
	", SUM(ticket) as ticket"
    %% " from w_sale a"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
    %% " where merchant=" ++ ?to_s(Merchant)
	++ " where " ++ SortConditions
	++ " group by employ, shop) a) a", 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_employee_evaluation,
	     Merchant,
	     UTable,
	     CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_employee_evaluation:merchant ~p, conditions ~p, page ~p", [Merchant, Conditions, CurrentPage]),
    SortConditions = sort_condition(wsale, Merchant, Conditions),
    Sql = 
	" select a.employee_id"
	", a.shop_id"
	", a.balance"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.draw"
	", a.ticket"
	", a.veri"
	" from "
	"(select merchant"
	", employ as employee_id"
	", shop as shop_id"
	", SUM(should_pay) as balance"
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wxin) as wxin"
	", SUM(aliPay) as aliPay"
	", SUM(withdraw) as draw"
	", SUM(ticket) as ticket"
	", SUM(verificate) as veri"
    %% " from w_sale a"
    %% " where merchant=" ++ ?to_s(Merchant)
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	++ " where " ++ SortConditions
	++ " group by employ, shop) a"	
	++ ?sql_utils:condition(page_desc, {use_balance, 0}, CurrentPage, ItemsPerPage),
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({start_pay_scan,
	     Merchant,
	     Shop,
	     {PayType, PayState, Live, PayOrderNo, Balance, PayTime}}, _From, State) ->
    Sql = "insert into w_pay(sn" 
	", type"
	", live" 
	", balance"
	", state"
	
	", shop"
	", merchant"
	", entry_date) values("
	++ "\'" ++ ?to_s(PayOrderNo) ++ "\',"
	
	++ ?to_s(PayType) ++ ","
	++ ?to_s(Live) ++ ","
	++ ?to_s(Balance) ++ ","
	++ ?to_s(PayState) ++ ","
	
	++ ?to_s(Shop) ++ ","
	++ ?to_s(Merchant) ++ ","
	++ "\'" ++ ?to_s(PayTime) ++ "\')",
    Reply =  ?sql_utils:execute(insert, Sql),
    {reply, Reply, State};

handle_call({check_pay_scan, Merchant, Shop, {PayType, PayState, PayOrderNo, Balance}}, _From, State) ->
    Updates = ?utils:v(type, integer, PayType)
	++ ?utils:v(state, integer, PayState)
	++ ?utils:v(balance, float, Balance),
    Sql = "update w_pay set " ++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and sn=\'" ++ ?to_s(PayOrderNo) ++ "\'",

    Reply = ?sql_utils:execute(write, Sql, PayOrderNo),
    {reply, Reply, State};

handle_call({total_pay_scan, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_pay_scan: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, UseConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    SortConditions = filter_condition(pay_scan, UseConditions, []),
    ?DEBUG("SortConditions ~p", SortConditions),
    Sql = "select count(*) as total"
	", SUM(balance) as t_balance"
	" from w_pay"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, SortConditions)
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_pay_scan, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_pay_scan: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, UseConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    SortConditions = filter_condition(pay_scan, UseConditions, []),
    Sql = "select id"
	", sn"
	", type"
	", live"
	", balance"
	", state"
	", shop as shop_id"
	", entry_date"
	" from w_pay"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, SortConditions)
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_order, Merchant, UTable, Inventories, Props}, _From, State) ->
    ?DEBUG("new_order with merchant ~p~n~p, props ~p", [Merchant, Inventories, Props]),
    UserId = ?v(<<"user">>, Props, -1), 
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    Datetime   = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Employe    = ?v(<<"employee">>, Props),
    Comment    = ?v(<<"comment">>, Props, []),
    
    ABSPay    = ?v(<<"abs_pay">>, Props, 0),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),

    OrderSn = lists:concat(
	       [?inventory_sn:sn(sale_order, Merchant), "-M-", ?to_i(Merchant), "-S-", ?to_i(Shop)]),

    Sql1 = "insert into" ++ ?table:t(sale_order, Merchant, UTable)
	++ "(rsn"
	", account"
	", employ"
	", retailer"
	", shop"
	", merchant"

	", abs_pay"
	", should_pay" 
	", total"
	", finish"
	
	", comment"

	", state"
	", op_date" 
	", entry_date) values("
	++ "\"" ++ ?to_s(OrderSn) ++ "\","
	++ ?to_s(UserId) ++ ","
	++ "\'" ++ ?to_s(Employe) ++ "\',"
	++ ?to_s(Retailer) ++ ","
	++ ?to_s(Shop) ++ ","
	++ ?to_s(Merchant) ++ ","


	++ ?to_s(ABSPay) ++ "," 
	++ ?to_s(ShouldPay) ++ "," 
	++ ?to_s(Total) ++ ","
	++ ?to_s(?ORDER_START) ++ ","

	++ "\'" ++ ?to_s(Comment) ++ "\',"

	++ ?to_s(?ORDER_START) ++ ","
	++ "\'" ++ ?to_s(Datetime) ++ "\'," 
	++ "\'" ++ ?to_s(Datetime) ++ "\');",
    
    try
	Sql2 = 
	    lists:foldr(
	      fun({struct, Inv}, Acc0)-> 
		      Amounts = ?v(<<"amounts">>, Inv), 
		      order(new,
			    OrderSn,
			    Datetime,
			    {Merchant, UTable}, Shop, Retailer, Inv, Amounts) ++ Acc0
	      end, [], Inventories),
	Sqls = [Sql1] ++ Sql2,
	?DEBUG("Sqls ~p", [Sqls]),
	Reply = ?sql_utils:execute(transaction, Sqls, OrderSn),
	{reply, Reply, State} 
    catch
	_:{db_error, Error} ->
	    {reply, {error, Error}, State}
    end;

handle_call({update_order, Merchant, UTable, Inventories, Props, OldProps}, _From, State) ->
    ?DEBUG("update_order: merchant ~p~n, Inventories ~p~n, Props ~p OldProps ~p",
	   [Merchant, Inventories, Props, OldProps]),
    RSN        = ?v(<<"rsn">>, Props),
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props),
    Employee   = ?v(<<"employee">>, Props),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    ABSPay     = ?v(<<"abs_pay">>, Props, 0),
    Total      = ?v(<<"total">>, Props),
    Comment    = ?v(<<"comment">>, Props),
    Datetime   = ?v(<<"datetime">>, Props), 

    OldRetailer  = ?v(<<"retailer_id">>, OldProps),
    OldShop      = ?v(<<"shop_id">>, OldProps),
    OldEmployee  = ?v(<<"employee_id">>, OldProps),
    OldShouldPay = ?v(<<"should_pay">>, OldProps),
    OldABSPay    = ?v(<<"abs_pay">>, OldProps), 
    OldTotal     = ?v(<<"total">>, OldProps),
    OldFinish    = ?v(<<"finish">>, OldProps),
    OldOrderState = ?v(<<"state">>, OldProps),
    OldComment   = ?v(<<"comment">>, OldProps),
    OldDatetime  = ?v(<<"entry_date">>, OldProps), 

    Sq1 = 
	case Inventories of
	    [] ->
		case ?utils:v(retailer, integer, get_modified(Retailer, OldRetailer))
		    ++ ?utils:v(shop, integer, get_modified(Shop, OldShop)) 
		    ++ ?utils:v(entry_date, string, get_modified(Datetime, OldDatetime)) of
		    [] -> [];
		    UpdateAttr ->
			["update"
			 ++ ?table:t(sale_order_detail, Merchant, UTable)
			 ++ " set " ++ ?utils:to_sqls(proplists, comma, UpdateAttr)
			 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
			 ++ " and merchant=" ++ ?to_s(Merchant),

			 "update"
			 ++ ?table:t(sale_order_note, Merchant, UTable)
			 ++ " set " ++ ?utils:to_sqls(proplists, comma, UpdateAttr)
			 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
			 ++ " and merchant=" ++ ?to_s(Merchant)]
		end;
	    _ -> 
		sql_order(
		  update,
		  RSN,
		  Merchant,
		  UTable,
		  get_new(Shop, OldShop),
		  get_new(Retailer, OldRetailer),
		  get_new(Datetime, OldDatetime),
		  Inventories)
	end,

    OrderState = set_order_state(OldFinish, Total),
    Updates = ?utils:v(retailer, integer, get_modified(Retailer, OldRetailer))
	++ ?utils:v(shop, integer, get_modified(Shop, OldShop)) 
	++ ?utils:v(employ, string, get_modified(Employee, OldEmployee))
	++ ?utils:v(should_pay, float, get_modified(ShouldPay, OldShouldPay))
	++ ?utils:v(abs_pay, float, get_modified(ABSPay, OldABSPay))
	++ ?utils:v(total, integer, get_modified(Total, OldTotal))
	++ ?utils:v(state, integer, get_modified(OrderState, OldOrderState))
	++ ?utils:v(comment, string, get_modified(Comment, OldComment))
	++ ?utils:v(entry_date, string, get_modified(Datetime, OldDatetime)), 

    Sql2 = case Updates of
	       [] -> [];
	       _ -> ["update" ++ ?table:t(sale_order, Merchant, UTable)
		     ++ " set " ++ ?utils:to_sqls(proplists, comma, Updates) 
		     ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		     ++ " and merchant=" ++ ?to_s(Merchant)]
	   end,

    AllSqls = Sq1 ++ Sql2,
    ?DEBUG("AllSqls ~p", [AllSqls]),
    
    Reply = 
	case erlang:length(AllSqls) =:= 1 of
	    true -> ?sql_utils:execute(write, AllSqls, RSN);
	    false -> ?sql_utils:execute(transaction, AllSqls, RSN)
	end,
    {reply, Reply, State};


handle_call({delete_order_by_rsn, Merchant, UTable, RSN}, _From, State) ->
    ?DEBUG("delete_order_by_rsn: Merchant ~p, RSN ~p", [RSN]),
    Sqls = ["delete from"
	    ++ ?table:t(sale_order_note, Merchant, UTable)
	    ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'", 

	    "delete from"
	    ++ ?table:t(sale_order_detail, Merchant, UTable)
	    ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",

	    "delete from"
	    ++ ?table:t(sale_order, Merchant, UTable)
	    ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"],

    Reply = ?sql_utils:execute(transaction, Sqls, RSN),
    {reply, Reply, State};

handle_call({total_orders, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_orders: Merchant ~p, Conditions ~p", [Merchant, Conditions]),

    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    
    CountSql = "select count(*) as total" 
	" from" ++ ?table:t(sale_order, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime),
    
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};

handle_call({filter_orders, Merchant, UTable, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_orders:" "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n" "fields ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Fields]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, Fields),
    
    Sql = "select a.id"
	", a.rsn"
	", a.account as account_id"
	", a.employ as employee_id"
    	", a.retailer as retailer_id"
	", a.shop as shop_id"
	
	", a.abs_pay"
	", a.should_pay"
	", a.total"
	", a.finish"

	", a.comment"
	", a.state"
	", a.entry_date"

	", b.name as retailer"
	", b.mobile"
	", c.name as account"

	" from" ++ ?table:t(sale_order, Merchant, UTable) ++ " a"
	++ " left join w_retailer b on a.retailer=b.id"
	++ " left join users c on a.account=c.id"

    	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, {use_datetime, 0}, CurrentPage, ItemsPerPage),
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_order_detail, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_order_detail: Merchant ~p, Conditions ~p", [Merchant, Conditions]), 
    {DConditions, SConditions} = filter_condition(wsale, Conditions, [], []),
    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions),
    
    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    CountSql = "select count(*) as total"
	" from "
	++ ?table:t(sale_order_detail, Merchant, UTable) ++ " b,"
	++ ?table:t(sale_order, Merchant, UTable) ++ " a"
	++ " where b.rsn=a.rsn"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, CorrectCutDConditions)
	++ ?sql_utils:condition(proplists, CutSConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime), 

    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};

handle_call({filter_order_detail, Merchant, UTable, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_order_detail:currentPage ~p, ItemsPerpage ~p, Merchant ~p~n Conditions ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Conditions]),
    
    {DConditions, SConditions} = filter_condition(wsale, Conditions, [], []),
    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions),

    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),
    
    Sql =
	"select n.id"
	", n.rsn"
	", n.merchant"
	", n.shop_id"

	", n.style_number"
	", n.brand_id"

	", n.type_id"
	", n.sex"
	", n.s_group"
	", n.free"

	", n.season"
	", n.firm_id"
	", n.year"
	", n.in_datetime"

	", n.total"
	", n.finish"

	", n.tag_price"
	", n.discount"

	", n.fdiscount"
	", n.fprice"

	", n.path"
	", n.comment"

	", n.state"
	", n.entry_date"

	", n.account_id"
	", n.retailer_id"
	", n.employee_id"

	", n.retailer"
	", n.account"

	", m.name as type"

	" from ("
	
	"select b.id"
	", b.rsn"
	", b.merchant"
	", b.shop as shop_id"

	", b.style_number"
	", b.brand as brand_id"

	", b.type as type_id"
	", b.sex"
	", b.s_group"
	", b.free"

	", b.season"
	", b.firm as firm_id"
	", b.year"
	", b.in_datetime"

	", b.total"
	", b.finish"

	", b.tag_price"
	", b.discount"

	", b.fdiscount"
	", b.fprice"

	", b.path"
	", b.comment"

	", b.state"
	", b.entry_date"

	", a.account as account_id"
	", a.retailer as retailer_id"
	", a.employ as employee_id"

	", c.name as retailer"
	", d.name as account"


	" from" ++ ?table:t(sale_order_detail, Merchant, UTable) ++ " b,"
	++ ?table:t(sale_order, Merchant, UTable) ++ " a"
	" left join w_retailer c on c.id=a.retailer"
	" left join users d on d.id=a.account"
	
	" where b.rsn=a.rsn"
    	" and b.merchant=" ++ ?to_s(Merchant)

	++ ?sql_utils:condition(proplists, CorrectCutDConditions)
	++ ?sql_utils:condition(proplists, CutSConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, {use_datetime, 0}, CurrentPage, ItemsPerPage) ++ ") n"

	" left join inv_types m on n.type_id=m.id",
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_order, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("list_order:" "merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {_, _, NewConditions} = ?sql_utils:cut(fields_with_prifix, Conditions),
    Sql = "select a.id"
	", a.rsn"
	", a.employ as employee_id"
    	", a.retailer as retailer_id"
	", a.shop as shop_id"
	
	", a.should_pay"
	", a.abs_pay"
	", a.total"
	", a.finish"

	", a.comment"
	", a.state"
	", a.entry_date"

	", b.name as retailer"
	", b.level as retailer_level"
	", b.mobile"
	", b.type as retailer_type"
	
	" from" ++ ?table:t(sale_order, Merchant, UTable) ++ " a"
	++ " left join w_retailer b on a.retailer=b.id" 
    	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " order by a.entry_date desc",

    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_order_note, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("list_order:" "merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {_, _, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    Sql =
	"select a.rsn"
	", a.shop"
	", a.style_number"
	", a.brand_id"
	", a.total"
	", a.finish"
	", a.fdiscount"
	", a.fprice"

	", b.color as color_id"
	", b.size"
	", b.total as cs_total"
	", b.finish as cs_finish" 
	
	" from "
	
	"(select rsn"
	", shop"
	", style_number"
	", brand as brand_id"
	", fdiscount"
	", fprice"
	", total"
	", finish"
	", state"
	" from"
	++ ?table:t(sale_order_detail, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) ++ ") a"
	++ " inner join" ++ ?table:t(sale_order_note, Merchant, UTable) ++ " b"
	++ " on a.rsn=b.rsn"
	++ " and a.style_number=b.style_number"
	++ " and a.brand_id=b.brand"
	++ " and a.shop=b.shop", 
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
    
handle_call(Request, _From, State) ->
    ?DEBUG("unkown request ~p", [Request]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    ?DEBUG("handle_info: info ~p", [_Info]),
    {noreply, State}.


terminate(_Reason, _State) ->
    ?DEBUG("terminate: reason ~p", [_Reason]),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
sql(update_wsale, RSN, Merchant, UTable, _Shop, NewDatetime, OldDatetime, []) ->
    case NewDatetime =:= OldDatetime of
	true -> [];
	false ->
	    ["update"
	     %% " w_sale_detail"
	     ++ ?table:t(sale_detail, Merchant, UTable)
	     ++ " set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",
	     
	     "update"
	     %% " w_sale_detail_amount"
	     ++ ?table:t(sale_note, Merchant, UTable)
	     ++ " set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"]
    end;
    
sql(update_wsale, RSN, Merchant, UTable, Shop, NewDatetime, _OldDatetime, Inventories) ->    
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv), 
	      case Operation of
		  <<"d">> ->
		      Amounts = ?v(<<"amount">>, Inv),
		      wsale(delete,
			    RSN,
			    NewDatetime,
			    Merchant,
			    UTable,
			    Shop,
			    Inv,
			    Amounts) ++ Acc0; 
		  <<"a">> ->
		      Amounts = ?v(<<"amount">>, Inv), 
		      wsale(new,
			    RSN,
			    undefined,
			    NewDatetime,
			    {Merchant, UTable},
			    Shop,
			    Inv,
			    Amounts) ++ Acc0; 
		  <<"u">> -> 
		      wsale(update,
			    RSN,
			    NewDatetime,
			    Merchant,
			    UTable,
			    Shop,
			    Inv) ++ Acc0
	      end
      end, [], Inventories).
    

wsale(update, RSN, Datetime, Merchant, UTable, Shop, Inventory) -> 
    StyleNumber    = ?v(<<"style_number">>, Inventory),
    Brand          = ?v(<<"brand">>, Inventory),
    OrgPrice       = ?v(<<"org_price">>, Inventory),
    %% TagPrice       = ?v(<<"tag_price">>, Inventory),
    FPrice         = ?v(<<"fprice">>, Inventory),
    RPrice         = ?v(<<"rprice">>, Inventory),
    FDiscount      = ?v(<<"fdiscount">>, Inventory),
    RDiscount      = ?v(<<"rdiscount">>, Inventory),
    Comment        = ?v(<<"comment">>, Inventory, []),
    
    ChangeAmounts  = ?v(<<"changed_amount">>, Inventory, []),

    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       Count = ?v(<<"count">>, Attr),
			       case ?v(<<"operation">>, Attr) of
				   <<"d">> -> Acc - Count;
				   <<"a">> -> Acc + Count;
				   <<"u">> -> Acc + Count
			       end
		       end, 0, ChangeAmounts)
	     end(),

    ?DEBUG("metric ~p", [Metric]),
    
    C1 =
	fun(Color, Size) ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand},
				{<<"color">>, Color},
				{<<"size">>,  Size},
				{<<"shop">>,  Shop},
				{<<"merchant">>, Merchant}])
	end,

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,
    

    Sql0 = 
	case Metric of
	    0 -> ["update"
		  %% " w_sale_detail"
		  ++ ?table:t(sale_detail, Merchant, UTable)
		  ++ " set org_price=" ++ ?to_s(OrgPrice)
		  %% ++ ", tag_price=" ++ ?to_s(TagPrice)
		  ++ ", fdiscount=" ++ ?to_s(FDiscount)
		  ++ ", rdiscount=" ++ ?to_s(RDiscount) 
		  ++ ", fprice=" ++ ?to_s(FPrice)
		  ++ ", rprice=" ++ ?to_s(RPrice)
		  ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		  ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
		  ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		  ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		  ++ " and brand=" ++ ?to_s(Brand)];
	    Metric -> 
		["update"
		 %% " w_inventory"
		 ++ ?table:t(stock, Merchant, UTable)
		 ++ " set amount=amount-" ++ ?to_s(Metric)
		 ++ ", sell=sell+" ++ ?to_s(Metric)
		 ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update"
		 %% " w_sale_detail"
		 ++ ?table:t(sale_detail, Merchant, UTable)
		 ++ " set total=total+" ++ ?to_s(Metric)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 %% ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", rdiscount=" ++ ?to_s(RDiscount) 
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", rprice=" ++ ?to_s(RPrice)
		 ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
		 ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)]
	end,

    ChangeFun =
	fun({struct, Attr}, Acc1) ->
		?DEBUG("Attr ~p", [Attr]),
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr),

		case ?v(<<"operation">>, Attr) of 
		    <<"a">> ->
			Sql01 = "select id"
			    ", style_number"
			    ", brand"
			    ", color"
			    ", size"
			    " from" ++ ?table:t(sale_note, Merchant, UTable) 
			%% " w_sale_detail_amount"
			    ++ " where " ++ C2(Color, Size),

			["update"
			 %% " w_inventory_amount"
			 ++ ?table:t(stock_note, Merchant, UTable)
			 ++ " set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 case ?sql_utils:execute(s_read, Sql01) of
			     {ok, []} ->
				 "insert into"
				 %% " w_sale_detail_amount"
				     ++ ?table:t(sale_note, Merchant, UTable)
				     ++ "(rsn"
				     ", style_number"
				     ", brand"
				     ", color"
				     ", size"
				     ", total"
				     ", entry_date) values("
				     ++ "\"" ++ ?to_s(RSN) ++ "\","
				     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				     ++ ?to_s(Brand) ++ ","
				     ++ ?to_s(Color) ++ ","
				     ++ "\'" ++ ?to_s(Size)  ++ "\',"
				     ++ ?to_s(Count) ++ "," 
				     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
			     {ok, _} ->
				 "update"
				     %% " w_sale_detail_amount"
				     ++ ?table:t(sale_note, Merchant, UTable)
				     ++ " set total=total+" ++ ?to_s(Count)
				     ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
				     ++ " where " ++ C2(Color, Size);
			     {error, E00} ->
				 throw({db_error, E00})
			 end | Acc1];

		    <<"d">> -> 
			["update"
			 %% " w_inventory_amount"
			 ++ ?table:t(stock_note, Merchant, UTable)
			 ++ " set total=total+" ++ ?to_s(Count) ++ " where " ++ C1(Color, Size), 

			 "delete from"
			 %% " from w_sale_detail_amount"
			 ++ ?table:t(sale_note, Merchant, UTable)
			 %% ++ " set total=total+" ++ ?to_s(Count)
			 ++ " where " ++ C2(Color, Size)
			 | Acc1];
		    <<"u">> -> 
			["update"
			 %% " w_inventory_amount"
			 ++ ?table:t(stock_note, Merchant, UTable)
			 ++ " set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 " update"
			 %% " w_sale_detail_amount"
			 ++ ?table:t(sale_note, Merchant, UTable)
			 ++ " set total=total+" ++ ?to_s(Count)
			 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts). 
    
wsale(delete, RSN, _DateTime, Merchant, UTable, Shop, Inventory, Amounts) when is_list(Amounts)->
    %% Shop       = ?v(<<"shop">>, Props),
    %% change repo    
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory), 
    
    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       ?v(<<"sell_count">>, Attr) + Acc
		       end, 0, Amounts)
	     end(),

    ["update"
     %% " w_inventory"
     ++ ?table:t(stock, Merchant, UTable)
     ++ " set amount=amount+" ++ ?to_s(Metric)
     ++ ",sell=sell-" ++ ?to_s(Metric) 
     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)
     ++ " and shop=" ++ ?to_s(Shop)
     ++ " and merchant=" ++ ?to_s(Merchant),

     "delete from"
     %% " w_sale_detail"
     ++ ?table:t(sale_detail, Merchant, UTable)
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)]
	++ 
        lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  Count  = ?v(<<"sell_count">>, Attr),
		  ["update"
		   %% " w_inventory_amount"
		   ++ ?table:t(stock_note, Merchant, UTable)
		   ++ " set total=total+" ++ ?to_s(Count)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand) 
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   "delete from"
		   %% " w_sale_detail_amount"
		   ++ ?table:t(sale_note, Merchant, UTable)
		   ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   | Acc1]
	     end, [], Amounts);


wsale(reject_badrepo, RSN, DateTime, Merchant, _UTable, {Shop, RealyShop}, Inventory, Amounts) -> 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),
    Year        = ?v(<<"year">>, Inventory),
    AlarmDay    = ?v(<<"alarm_day">>, Inventory),
    
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory), 
    Discount    = ?v(<<"discount">>, Inventory),
    
    FDiscount   = ?v(<<"fdiscount">>, Inventory, 100), 
    FPrice      = ?v(<<"fprice">>, Inventory),
    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Total       = ?v(<<"sell_total">>, Inventory), 
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),

    C1 =
	fun() ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand}, 
				{<<"shop">>, Shop},
				{<<"merchant">>, Merchant}])
	end, 

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    
    Sql0 = "select id, style_number, brand, shop from w_inventory"
	" where " ++ C1(), 

    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into w_inventory(rsn"
		 ", style_number, brand, type, sex, season, amount"
		 ", firm, s_group, free, year"
		 ", org_price, tag_price, pkg_price, price3"
		 ", price4, price5, discount, path, alarm_day"
		 ", shop, merchant, last_sell, change_date, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Firm) ++ "," 
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","		 
		 ++ ?to_s(Discount) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ ?to_s(AlarmDay) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")"]; 
	    {ok, R} ->
		?DEBUG("R ~p", [R]),
		["update w_inventory set"
		 " amount=amount+" ++ ?to_s(Total)
		 ++ ", change_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
		 ++ ", entry_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))];
	    {error, Error} ->
		throw({db_error, Error})
	end, 


    Sql2 = ["update w_inventory set sell=sell-" ++ ?to_s(Total)
	    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	    ++ " and brand=" ++ ?to_s(Brand)
	    ++ " and shop=" ++ ?to_s(RealyShop)
	    ++ " and merchant=" ++ ?to_s(Merchant)],
    
    Sql00 = "select rsn, style_number, brand, type from w_sale_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 

    Sql3 = 
	case ?sql_utils:execute(s_read, Sql00) of
	    {ok, []} ->
		["insert into w_sale_detail("
		 "rsn, style_number, brand, merchant, type, s_group, free"
		 ", season, firm, year, total, fdiscount"
		 ", fprice, path, comment, entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ "," 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(-Total) ++ ","
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")"];
	    {ok, _} ->
		["update w_sale_detail set total=total-" ++ ?to_s(Total)
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)];
	    {error, E00} ->
		throw({db_error, E00})
	end,

    Sql1 ++ Sql2 ++ Sql3
	++ 
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count    = ?v(<<"reject_count">>, A), 

		  Sql01 =
		      "select id, style_number, brand, shop, merchant "
		      " from w_inventory_amount"
		      " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		      ++ " and brand=" ++ ?to_s(Brand)
		      ++ " and shop=" ++ ?to_s(Shop)
		      ++ " and merchant=" ++ ?to_s(Merchant)
		      ++ " and color=" ++ ?to_s(Color)
		      ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\"",
		      

		  Sql02 =
		      "select rsn, style_number, brand, color, size"
		      " from w_sale_detail_amount"
		      " where " ++ C2(Color, Size),

		  [ case ?sql_utils:execute(s_read, Sql01) of
			{ok, []} ->
			    "insert into w_inventory_amount(rsn"
				", style_number, brand, color, size"
				", shop, merchant, total, entry_date)"
				" values("
				++ "\"" ++ ?to_s(-1) ++ "\","
				++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				++ ?to_s(Brand) ++ ","
				++ ?to_s(Color) ++ ","
				++ "\'" ++ ?to_s(Size)  ++ "\',"
				++ ?to_s(Shop)  ++ ","
				++ ?to_s(Merchant) ++ ","
				++ ?to_s(Count) ++ "," 
				++ "\"" ++ ?to_s(DateTime) ++ "\")";
			{ok, R01} -> 
			    "update w_inventory_amount set"
				" total=total+" ++ ?to_s(Count) 
				++ ", entry_date="
				++ "\"" ++ ?to_s(DateTime) ++ "\""
				++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
			{error, E01} ->
			    throw({db_error, E01})
		    end, 

		    case ?sql_utils:execute(s_read, Sql02) of
			{ok, []} ->
			    "insert into w_sale_detail_amount("
				"rsn, style_number, brand, color, size"
				", total, entry_date) values("
				++ "\"" ++ ?to_s(RSN) ++ "\","
				++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				++ ?to_s(Brand) ++ ","
				++ ?to_s(Color) ++ ","
				++ "\"" ++ ?to_s(Size) ++ "\","
				++ ?to_s(-Count) ++ ","
				++ "\"" ++ ?to_s(DateTime) ++ "\")";
			{ok, _} ->
			    "update w_sale_detail_amount set total=total-"
				++ ?to_s(Count)
				++ ", entry_date="
				++ "\'" ++ ?to_s(DateTime) ++ "\'"
				++ " where " ++ C2(Color, Size);
			{error, E02} ->
			    throw({db_error, E02})
		    end|Acc1] 
	  end, [], Amounts);

wsale(Action, RSN, SaleRsn, Datetime, {Merchant, UTable}, Shop, Inventory, Amounts) -> 
    ?DEBUG("wsale ~p with inv ~p, amounts ~p", [Action, Inventory, Amounts]),
    
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),
    
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory),
    Discount    = ?v(<<"discount">>, Inventory),
    FDiscount   = ?v(<<"fdiscount">>, Inventory),
    RDiscount   = ?v(<<"rdiscount">>, Inventory),
    FPrice      = ?v(<<"fprice">>, Inventory),
    RPrice      = ?v(<<"rprice">>, Inventory),
    
    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory),
    Year        = ?v(<<"year">>, Inventory),
    InDatetime  = ?v(<<"entry">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Total       = case Action of
		      new    -> ?v(<<"sell_total">>, Inventory);
		      reject -> -?v(<<"sell_total">>, Inventory) 
		  end, 
    Oil         = ?v(<<"oil">>, Inventory),
    Exist       = ?v(<<"stock">>, Inventory),
    Negative    = ?v(<<"negative">>, Inventory),
    SPrice      = ?v(<<"sprice">>, Inventory, 0),
    Ticket      = ?v(<<"ticket">>, Inventory, 0),
	
    Promotion   = ?v(<<"promotion">>, Inventory, -1),
    Commision   = ?v(<<"commision">>, Inventory, -1),
    Score       = ?v(<<"score">>, Inventory, -1), 
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),

    C1 =
	fun() ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand}, 
				{<<"shop">>, Shop},
				{<<"merchant">>, Merchant}])
	end, 

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"merchant">>, Merchant},
			       {<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    Sql00 = "select rsn, style_number, brand, type"
	" from" ++ ?table:t(sale_detail, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 
    
    ["update" ++ ?table:t(stock, Merchant, UTable)
     ++ " set amount=amount-" ++ ?to_s(Total)
     ++ ", sell=sell+" ++ ?to_s(Total) 
     ++ ", last_sell=" ++ "\'" ++ ?to_s(Datetime) ++ "\'"
     ++ " where " ++ C1(), 
     case ?sql_utils:execute(s_read, Sql00) of
	 {ok, []} ->
	     {ValidOrgPrice, ValidEDiscount}
		 = case Action of
		       new  -> valid_orgprice(stock, Merchant, UTable, Shop, Inventory);
		       reject -> {OrgPrice, ?w_good_sql:stock(ediscount, OrgPrice, TagPrice)}
		   end,
	     "insert into" ++ ?table:t(sale_detail, Merchant, UTable)
		 ++ "(rsn"
		 ", style_number"
		 ", brand"
		 ", merchant"
		 ", shop"
		 ", type"
		 ", sex"
		 ", s_group"
		 ", free"
		 ", season"
		 ", firm"
		 ", year"
		 ", in_datetime"
		 ", exist"
		 ", total"
		 ", oil"
	     %% ", negative"
		 ", reject"
		 ", promotion"
		 ", commision"
		 ", score"
		 ", org_price"
		 ", ediscount"
		 ", tag_price"
		 ", discount"
		 ", fdiscount"
		 ", rdiscount"
		 ", fprice"
		 ", rprice"
		 ", path"
		 ", comment"
		 ", entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ "," 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ "\'" ++ ?to_s(InDatetime) ++ "\',"
		 ++ case Action of
				new -> ?to_s(Exist);
				reject -> ?to_s(0)
			    end ++ "," 
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Oil) ++ ","
		 ++ "\'" ++ case Action of
				new -> "0" ++ ?to_s(Negative) ++ ?to_s(SPrice) ++ ?to_s(Ticket);
				reject -> "00" ++ ?to_s(SPrice) ++ ?to_s(Ticket)
			    end ++ "\',"
		 ++ ?to_s(Promotion) ++ ","
		 ++ ?to_s(Commision) ++ ","
		 ++ ?to_s(Score) ++ ","
		 
		 ++ ?to_s(ValidOrgPrice) ++ ","
		 ++ ?to_s(ValidEDiscount) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(Discount) ++ "," 
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(RDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ ?to_s(RPrice) ++ ","
		 
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
	 {ok, _} ->
	     "update" ++ ?table:t(sale_detail, Merchant, UTable)
		 ++ " set total=total+" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", rdiscount=" ++ ?to_s(RDiscount)
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", rprice=" ++ ?to_s(RPrice)
		 ++ ", oil=" ++ ?to_s(Oil)
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand);
	 {error, E00} ->
	     throw({db_error, E00})
     end] ++ 
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count =
		      case Action of
			  new -> ?v(<<"sell_count">>, A);
			  reject -> -?v(<<"reject_count">>, A)
		      end,
		  
		  Sql01 = "select rsn, style_number, brand, color, size"
		      " from"
		      %% " w_sale_detail_amount"
		      ++ ?table:t(sale_note, Merchant, UTable)
		      ++ " where " ++ C2(Color, Size),
		  
		  ["update"
		   %% " w_inventory_amount"
		   ++ ?table:t(stock_note, Merchant, UTable)
		   ++ " set total=total-" ++ ?to_s(Count)
		   ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(Color)
		   ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),
		   
		   case ?sql_utils:execute(s_read, Sql01) of
		       {ok, []} ->
			   "insert into"
			       %% " w_sale_detail_amount"
			       ++ ?table:t(sale_note, Merchant, UTable)
			       ++ "(rsn"
			       ", style_number"
			       ", brand"
			       ", color"
			       ", size"
			       ", exist"
			       ", total"
			       ", merchant"
			       ", shop"
			       ", entry_date) values("
			       ++ "\"" ++ ?to_s(RSN) ++ "\","
			       ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			       ++ ?to_s(Brand) ++ ","
			       ++ ?to_s(Color) ++ ","
			       ++ "\"" ++ ?to_s(Size) ++ "\","
			       ++ case Action of
				   new -> ?to_s(?v(<<"exist">>, A));
				   reject -> ?to_s(0)
			       end ++ ","
			       ++ ?to_s(Count) ++ ","
			       ++ ?to_s(Merchant) ++ ","
			       ++ ?to_s(Shop) ++ ","
			       ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		       {ok, _} ->
			   "update"
			   %% " w_sale_detail_amount"
			       ++ ?table:t(sale_note, Merchant, UTable)
			       ++ " set total=total+" ++ ?to_s(Count)
			       ++ ", entry_date="
			       ++ "\'" ++ ?to_s(Datetime) ++ "\'"
			       ++ " where " ++ C2(Color, Size);
		       {error, E01} ->
			   throw({db_error, E01})
		   end|Acc1] 
	  end, [], Amounts)
	++ case Action of
	       new -> []; 
	       reject ->
		   ["update"
		    %% " w_sale_detail"
		    ++ ?table:t(sale_detail, Merchant, UTable)
		    ++ " set reject=insert(reject,1,1," ++ ?to_s(?YES) ++ ")"
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and rsn=\'" ++ ?to_s(SaleRsn) ++ "\'"
		    ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		    ++ " and brand=" ++ ?to_s(Brand)]
	   end.


order(new, RSN, Datetime, {Merchant, UTable}, Shop, Retailer, Inventory, Amounts) -> 
    ?DEBUG("order new with inv ~p, amounts ~p", [Inventory, Amounts]),
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),
    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory), 
    Year        = ?v(<<"year">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),
    InDatetime  = ?v(<<"entry">>, Inventory),
    
    
    Total       = ?v(<<"sell_total">>, Inventory), 
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory),
    Discount    = ?v(<<"discount">>, Inventory),
    FDiscount   = ?v(<<"fdiscount">>, Inventory),
    FPrice      = ?v(<<"fprice">>, Inventory), 
    
    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, ?to_b(RSN)},
			       {<<"merchant">>, Merchant},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,
    
    Sql00 = "select rsn, style_number, brand, type"
	" from" ++ ?table:t(sale_order_detail, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 

    [case ?sql_utils:execute(s_read, Sql00) of
	 {ok, []} -> 
	     "insert into" ++ ?table:t(sale_order_detail, Merchant, UTable)
		 ++ "(rsn"
		 ", merchant"
		 ", shop"
		 ", retailer"
		 
		 ", style_number"
		 ", brand"
		 
		 ", type"
		 ", sex"
		 ", s_group"
		 ", free"
		 
		 ", season"
		 ", firm"
		 ", year"
		 ", in_datetime"
		 
		 ", total"
		 ", finish"
		 
		 ", org_price"
		 ", tag_price" 
		 ", discount"		 
		 ", fdiscount"
		 ", fprice"
		 
		 ", path"
		 ", comment"

		 ", state"
		 ", op_date"
		 ", entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Retailer) ++ ","

		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ ","
		 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ "\'" ++ ?to_s(InDatetime) ++ "\',"

		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(0) ++ "," 

		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ "," 
		 ++ ?to_s(Discount) ++ "," 
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 
		 ++ "\'" ++ ?to_s(Path) ++ "\',"
		 ++ "\'" ++ ?to_s(Comment) ++ "\',"
		 
		 ++ ?to_s(?ORDER_START) ++ ","
		 ++ "\'" ++ ?to_s(Datetime) ++ "\',"
		 ++ "\'" ++ ?to_s(Datetime) ++ "\')";
	 {ok, _} ->
	     "update" ++ ?table:t(sale_order_detail, Merchant, UTable)
		 ++ " set total=" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", discount=" ++ ?to_s(Discount)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", op_date=\'" ++ ?to_s(Datetime) ++ "\'"
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand);
	 {error, E00} ->
	     throw({db_error, E00})
     end] ++ 
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count    = ?v(<<"sell_count">>, A), 
		  Sql01 = "select rsn"
		      ", style_number"
		      ", brand, color"
		      ", size"
		      " from"
		      ++ ?table:t(sale_order_note, Merchant, UTable)
		      ++ " where " ++ C2(Color, Size),

		  [case ?sql_utils:execute(s_read, Sql01) of
		       {ok, []} ->
			   "insert into" 
			       ++ ?table:t(sale_order_note, Merchant, UTable)
			       ++ "(rsn"
			       ", merchant"
			       ", shop"
			       
			       ", style_number"
			       ", brand"
			       ", color"
			       ", size"
			       ", total"
			       ", finish"

			       ", state"
			       ", op_date" 
			       ", entry_date) values("
			       ++ "\'" ++ ?to_s(RSN) ++ "\',"
			       ++ ?to_s(Merchant) ++ ","
			       ++ ?to_s(Shop) ++ ","
			       
			       ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
			       ++ ?to_s(Brand) ++ ","
			       ++ ?to_s(Color) ++ ","
			       ++ "\'" ++ ?to_s(Size) ++ "\'," 
			       ++ ?to_s(Count) ++ ","
			       ++ ?to_s(0) ++ ","

			       ++ ?to_s(?ORDER_START) ++ ","
			       ++ "\'" ++ ?to_s(Datetime) ++ "\',"
			       ++ "\'" ++ ?to_s(Datetime) ++ "\')";
		       {ok, _} ->
			   "update"
			       ++ ?table:t(sale_order_note, Merchant, UTable)
			       ++ " set total=" ++ ?to_s(Count)
			       ++ ", op_date=\'" ++ ?to_s(Datetime) ++ "\'"
			       ++ " where " ++ C2(Color, Size);
		       {error, E01} ->
			   throw({db_error, E01})
		   end|Acc1] 
	  end, [], Amounts). 

order_process(stock, {Merchant, UTable}, Shop, OrderRSN, Datetime, [], Total, Sqls) ->
    case Total =/= 0 of
	true ->
	    Sql0 = "select rsn, total, finish"
		" from" ++ ?table:t(sale_order, Merchant, UTable)
		++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
		++ " and merchant=" ++ ?to_s(Merchant)
		++ " and shop=" ++ ?to_s(Shop),
	    {ok, R} = ?sql_utils:execute(s_read, Sql0),

	    ["update" ++ ?table:t(sale_order, Merchant, UTable)
	     ++ " set finish=finish+"  ++ ?to_s(Total)
	     ++ case ?v(<<"finish">>, R) + Total >= ?v(<<"total">>, R) of
		    true -> ", state=2";
		    false -> ", state=1"
		end
	     ++ ", op_date=\'" ++ ?to_s(Datetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
	     ++ " and merchant=" ++ ?to_s(Merchant)
	     ++ " and shop=" ++ ?to_s(Shop)] ++ Sqls;
	false ->
	    []
    end;

order_process(stock, {Merchant, UTable}, Shop, OrderRSN, Datetime, Invs, Total, Sqls) ->
    ?DEBUG("order process sale with inv ~p", [Invs]),
    [{struct, S}|T] = Invs,
    StyleNumber = ?v(<<"style_number">>, S),
    Brand       = ?v(<<"brand">>, S),
    C = [{<<"shop">>, Shop},
	 {<<"style_number">>, StyleNumber},
	 {<<"brand">>, Brand}],
    
    case ?v(<<"order_rsn">>, S) =:= OrderRSN of
	true ->
	    {OrderCount, NoteSqls} = order_process(
				   stock_note,
				   {Merchant, UTable},
				   Shop,
				   OrderRSN,
				   Datetime,
				   S,
				   ?v(<<"amounts">>, S),
				   0,
				   []),
	    case OrderCount =/= 0 of 
		true ->
		    Sql0 = "select style_number, brand, total, finish"
			" from " ++ ?table:t(sale_order_detail, Merchant, UTable)
			++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
			++ " and merchant=" ++ ?to_s(Merchant)
			++ ?sql_utils:condition(proplists, C),
		    case ?sql_utils:execute(s_read, Sql0) of
			{ok, R} ->
			    Sql1 = "update" ++ ?table:t(sale_order_detail, Merchant, UTable)
				++ " set finish=finish+"  ++ ?to_s(OrderCount)
				++ case ?v(<<"finish">>, R) +  OrderCount >= ?v(<<"total">>, R) of
				       true -> ", state=2";
				       false -> ", state=1"
				   end
				++ ", op_date=\'" ++ ?to_s(Datetime) ++ "\'"
				++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
				++ " and merchant=" ++ ?to_s(Merchant)
				++ ?sql_utils:condition(proplists, C),
			    order_process(stock,
					  {Merchant, UTable},
					  Shop,
					  OrderRSN,
					  Datetime,
					  T,
					  Total + OrderCount,
					  [Sql1] ++ NoteSqls ++ Sqls)
		    end;
		false ->
		    order_process(stock, {Merchant, UTable}, Shop, OrderRSN, Datetime, T, Total, Sqls)
	    end;
	false ->
	    order_process(stock, {Merchant, UTable}, Shop, OrderRSN, Datetime, T, Total, Sqls)
    end.

order_process(stock_note, {_Merchant, _UTable}, _Shop, _OrderRSN, _DateTime, _Inv, [], Total, Sqls) ->
    {Total, Sqls};
    
order_process(stock_note, {Merchant, UTable}, Shop, OrderRSN, Datetime, Inv, [{struct, A}|Amounts], Total, Sqls) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Color = ?v(<<"cid">>, A),
    Size = ?v(<<"size">>, A),
    OrderCount = ?v(<<"sell_count">>, A),
    C = [{<<"shop">>, Shop},
	 {<<"style_number">>, StyleNumber},
	 {<<"brand">>, Brand},
	 {<<"color">>, Color},
	 {<<"size">>, Size}],
    
    case ?v(<<"order_rsn">>, A) =:= OrderRSN andalso OrderCount =/= 0 of
	true ->
	    Sql0 = "select style_number, brand, color, size, total, finish"
		" from " ++ ?table:t(sale_order_note, Merchant, UTable)
		++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
		++ " and merchant=" ++ ?to_s(Merchant)
		++ ?sql_utils:condition(proplists, C),
	    case ?sql_utils:execute(s_read, Sql0) of
		{ok, R} ->
		    Sql1 = "update" ++ ?table:t(sale_order_note, Merchant, UTable)
			++ " set finish=finish+"  ++ ?to_s(OrderCount)
			++ case ?v(<<"finish">>, R) + OrderCount >= ?v(<<"total">>, R) of
			       true -> ", state=2";
			       false -> ", state=1"
			   end
			++ ", op_date=\'" ++ ?to_s(Datetime) ++ "\'"
			++ " where rsn=\'" ++ ?to_s(OrderRSN) ++ "\'"
			++ " and merchant=" ++ ?to_s(Merchant)
			++ ?sql_utils:condition(proplists, C),
		    order_process(stock_note,
			  {Merchant, UTable},
			  Shop,
			  OrderRSN,
			  Datetime,
			  Inv,
			  Amounts,
			  Total + OrderCount,
			  [Sql1|Sqls]);
		_ ->
		    order_process(stock_note,
				  {Merchant, UTable},
				  Shop,
				  OrderRSN,
				  Datetime,
				  Inv,
				  Amounts,
				  Total,
				  Sqls)
	    end; 
	false ->
	    order_process(stock_note,
			  {Merchant, UTable},
			  Shop,
			  OrderRSN,
			  Datetime,
			  Inv,
			  Amounts,
			  Total,
			  Sqls)
    end.


sql_order(update, RSN, Merchant, UTable, Shop, Retailer, Datetime, Inventories) ->    
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv), 
	      case Operation of
		  <<"d">> -> 
		      order_update(delete,
				   RSN,
				   {Merchant, UTable},
				   Inv) ++ Acc0; 
		  <<"a">> ->
		      Amounts = ?v(<<"amount">>, Inv),
		      order(new,
			    RSN,
			    Datetime,
			    {Merchant, UTable},
			    Shop,
			    Retailer,
			    Inv,
			    Amounts) ++ Acc0; 
		  <<"u">> -> 
		      order_update(inner,
				   RSN,
				   Datetime,
				   {Merchant, UTable},
				   Shop,
				   Retailer,
				   Inv) ++ Acc0
	      end
      end, [], Inventories).

order_update(delete, RSN, {Merchant, UTable}, Inventory) -> 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Amounts = ?v(<<"amount">>, Inventory),

    ["delete from"
     ++ ?table:t(sale_order_detail, Merchant, UTable)
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)]
	++ 
        lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  ["delete from"
		   ++ ?table:t(sale_order_note, Merchant, UTable)
		   ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'" | Acc1]
	  end, [], Amounts).

order_update(inner, RSN, Datetime, {Merchant, UTable}, Shop, Retailer, Inventory) -> 
    StyleNumber    = ?v(<<"style_number">>, Inventory),
    Brand          = ?v(<<"brand">>, Inventory),
    OrgPrice       = ?v(<<"org_price">>, Inventory),
    TagPrice       = ?v(<<"tag_price">>, Inventory),
    FPrice         = ?v(<<"fprice">>, Inventory),
    FDiscount      = ?v(<<"fdiscount">>, Inventory),
    Comment        = ?v(<<"comment">>, Inventory, []),
    OrderState     = ?v(<<"order_state">>, Inventory),

    ChangeAmounts  = ?v(<<"changed_amount">>, Inventory, []), 
    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       Count = ?v(<<"sell_count">>, Attr),
			       case ?v(<<"operation">>, Attr) of
				   <<"d">> -> Acc - Count;
				   <<"a">> -> Acc + Count;
				   <<"u">> -> Acc + Count
			       end
		       end, 0, ChangeAmounts)
	     end(), 
    ?DEBUG("metric ~p", [Metric]),
    
    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,


    Sql0 = ["update"
	    ++ ?table:t(sale_order_detail, Merchant, UTable)
	    ++ " set total=total+" ++ ?to_s(Metric)
	    ++ ", state=" ++ ?to_s(OrderState)
	    ++ ", org_price=" ++ ?to_s(OrgPrice)
	    ++ ", tag_price=" ++ ?to_s(TagPrice)
	    ++ ", fdiscount=" ++ ?to_s(FDiscount)
	    ++ ", fprice=" ++ ?to_s(FPrice)
	    ++ ", shop=" ++ ?to_s(Shop)
	    ++ ", retailer=" ++ ?to_s(Retailer)
	    ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
	    ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
	    ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
	    ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	    ++ " and brand=" ++ ?to_s(Brand)],
	    

    ChangeFun =
	fun({struct, Attr}, Acc1) ->
		?DEBUG("Attr ~p", [Attr]),
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"sell_count">>, Attr),
		
		case ?v(<<"operation">>, Attr) of 
		    <<"a">> -> 
			["insert into"
			 ++ ?table:t(sale_order_note, Merchant, UTable)
			 ++ "(rsn"
			 ", merchant"
			 ", shop"
			 
			 ", style_number"
			 ", brand"
			 ", color"
			 ", size"
			 ", total"
			 
			 ", state"
			 ", op_date"
			 ", entry_date) values("
			 ++ "\'" ++ ?to_s(RSN) ++ "\',"
			 ++ ?to_s(Merchant) ++ ","
			 ++ ?to_s(Shop) ++ ","
			 
			 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ","
			 ++ ?to_s(Color) ++ ","
			 ++ "\'" ++ ?to_s(Size)  ++ "\',"
			 ++ ?to_s(Count) ++ ","
			 
			 ++ ?to_s(?ORDER_START) ++ ","
			 ++ "\'" ++ ?to_s(Datetime) ++ "\',"
			 ++ "\'" ++ ?to_s(Datetime) ++ "\')" | Acc1]; 
		    <<"d">> -> 
			["delete from"
			 ++ ?table:t(sale_order_note, Merchant, UTable)
			 ++ " where " ++ C2(Color, Size) | Acc1];
		    <<"u">> -> 
			["update"
			 ++ ?table:t(sale_order_note, Merchant, UTable)
			 ++ " set total=total+" ++ ?to_s(Count)
			 ++ ", state=" ++ ?to_s(?v(<<"order_state">>, Attr))
			 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts).

count_table(w_sale, {Merchant, UTable}, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
	", sum(a.oil) as t_oil"
    	", sum(a.base_pay) as t_bpay"
	", sum(a.should_pay) as t_spay"
	", sum(a.verificate) as t_veri"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
	", sum(a.wxin) as t_wxin"
	", sum(a.aliPay) as t_aliPay"
	", sum(a.withdraw) as t_withdraw"
	", sum(a.ticket) as t_ticket"
	%% ", sum(a.balance) as t_balance"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a where " ++ SortConditions, 
    CountSql.

filter_table(w_sale, {Merchant, UTable}, Conditions) ->
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    Sql = "select a.id"
	", a.rsn"
	", a.employ as employee_id"
	", a.retailer as retailer_id"
	", a.shop as shop_id"
    %% ", a.promotion as pid, a.charge as cid" 
	", a.balance"
	", a.base_pay"
	", a.should_pay"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.withdraw"
	", a.ticket"
	", a.verificate"
	", a.total"
	", a.oil"
	", a.score" 
	", a.comment"
	", a.type"
	", a.entry_date"
	
	", b.name as shop"
	", c.name as employee"
	", d.name as retailer"
	
    %% " from w_sale a"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	" left join shops b on a.shop=b.id"
	" left join employees c on a.employ=c.number and c.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer d on a.retailer=d.id"
	" where " ++ SortConditions ++ " order by a.id desc",
    Sql.

filter_table(w_sale_with_page, {Merchant, UTable}, CurrentPage, ItemsPerPage, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),
    
    Sql = "select a.id"
	", a.rsn"
	", a.account as account_id"
	", a.employ as employee_id"
    	", a.retailer as retailer_id"
	", a.shop as shop_id"
    %% ", a.promotion as pid"
	
	", a.balance"
	", a.base_pay"
	", a.should_pay"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.aliPay"
	", a.withdraw"
	", a.ticket"
	", a.verificate"
	", a.total"
	", a.oil"
	", a.score"
	
	", a.comment"
	", a.type"
	", a.state"
	", a.g_ticket"
	", a.entry_date"
	
	", b.name as retailer"
	", b.type as retailer_type"
	", b.mobile as rphone"
	", b.type as rtype"
	", c.name as account"
	
    %% " from w_sale a"
	" from" ++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	++ " left join w_retailer b on a.retailer=b.id"
	++ " left join users c on a.account=c.id"
	
    	" where " ++ SortConditions
	++ ?sql_utils:condition(page_desc, {use_datetime, 0}, CurrentPage, ItemsPerPage), 
    Sql.
    
type(new) -> 0;
type(reject) -> 1.

direct(0) -> wsale;
direct(1) -> wreject;
direct(_) -> wsale.


sort_condition(wsale, Merchant, Conditions) ->
    Comment = ?v(<<"comment">>, Conditions),
    MTicket = ?v(<<"mticket">>, Conditions), 
    CutConditions = lists:keydelete(
		      <<"comment">>, 1,
		      lists:keydelete(<<"mticket">>, 1, Conditions)),
    
    C = lists:foldr(
	  fun({K, V}, Acc) when K =:= <<"check_state">>->
		  [{<<"state">>, V}|Acc];
	     (KV, Acc)->
		  [KV|Acc]
	  end, [], CutConditions),
    
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, C),

    "a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case Comment of
	       undefined -> [];
	       0 -> " and a.comment!=\'\'";
	       1 -> []
	   end
	
	++ case MTicket of
	       undefined -> [];
	       _ -> "and a.ticket>=" ++ ?to_s(MTicket)
	   end
	
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end.    

realy_shop(Merchant, ShopId) ->
    case ?w_user_profile:get(shop, Merchant, ShopId) of
	{ok, []} -> ShopId;
	{ok, [{ShopInfo}]} -> 
	    case ?v(<<"repo">>, ShopInfo) of
		-1 ->
		    ShopId;
		RepoId ->
		    RepoId 
	    end
    end.

realy_shop(reject, Merchant, ShopId) ->
    case ?w_user_profile:get(shop, Merchant, ShopId) of
	{ok, []} -> ShopId;
	{ok, [{ShopInfo}]} -> 
	    case ?v(<<"repo">>, ShopInfo) of
		-1 ->
		    {?SHOP, ShopId};
		RepoId ->
		    {?v(<<"type">>, ShopInfo), RepoId}
	    end
    end.
    

filter_condition(wsale, [], Acc1, Acc2) ->
    {lists:reverse(Acc1), lists:reverse(Acc2)};
filter_condition(wsale, [{<<"style_number">>,_} = S|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [S|Acc1], Acc2);
filter_condition(wsale, [{<<"brand">>, _} = B|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [B|Acc1], Acc2);
filter_condition(wsale, [{<<"firm">>, _} = F|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [F|Acc1], Acc2);
filter_condition(wsale, [{<<"type">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [OT|Acc1], Acc2);
filter_condition(wsale, [{<<"sex">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [OT|Acc1], Acc2);
filter_condition(wsale, [{<<"year">>, _} = Y|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [Y|Acc1], Acc2);
filter_condition(wsale, [{<<"season">>, _} = Y|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [Y|Acc1], Acc2);
filter_condition(wsale, [{<<"rprice">>, _} = R|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [R|Acc1], Acc2);
filter_condition(wsale, [{<<"org_price">>, OP} = _OP|T], Acc1, Acc2) ->
    filter_condition(wsale, T, [{<<"org_price">>, ?to_f(OP)}|Acc1], Acc2);


filter_condition(wsale, [{<<"rsn">>, _} = R|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [R|Acc2]);
filter_condition(wsale, [{<<"start_time">>, _} = ST|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [ST|Acc2]);
filter_condition(wsale, [{<<"end_time">>, _} = SE|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [SE|Acc2]);
filter_condition(wsale, [{<<"shop">>, _} = S|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [S|Acc2]);
filter_condition(wsale, [{<<"sell_type">>, ST}|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [{<<"type">>, ST}|Acc2]);
filter_condition(wsale, [O|T], Acc1, Acc2) ->
    filter_condition(wsale, T, Acc1, [O|Acc2]).

filter_condition(pay_scan, [], Acc) ->
    Acc;
filter_condition(pay_scan, [{<<"pay_type">>, PT}|T], Acc) ->
    filter_condition(pay_scan, T, [{<<"type">>, PT}|Acc]);
filter_condition(pay_scan, [{<<"pay_state">>, ST}|T], Acc) ->
    filter_condition(pay_scan, T, [{<<"state">>, ST}|Acc]);
filter_condition(pay_scan, [H|T], Acc) ->
    filter_condition(pay_scan, T, [H|Acc]).

								  

retailer(balance, Retailer) ->
    case ?v(<<"balance">>, Retailer) of
	<<>>    -> 0;
	Balance -> Balance
    end;
retailer(score, Retailer) ->
    case ?v(<<"score">>, Retailer) of
	<<>>   -> 0;
	Score  -> Score
    end.

valid_orgprice(stock, Merchant, UTable, Shop, Inventory) ->
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    EDiscount   = ?v(<<"ediscount">>, Inventory),
    Stock       = ?v(<<"stock">>, Inventory, 0),
    %% YSell       = ?v(<<"ysell">>, Inventory, 0),

    Sql = "select style_number, brand, org_price, ediscount, amount"
    %% " from w_inventory_new_detail"
	" from" ++ ?table:t(stock_new_detail, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(Brand)
    %% ++ " and amount>0"
    %% ++ " and rsn like \'M-" ++ ?to_s(Merchant) ++ "-S-" ++ ?to_s(Shop) ++ "%\'"
	++ " order by entry_date desc;",

    case ?sql_utils:execute(read, Sql) of
	{ok, StockNews} ->
	    filter_stock(news, StockNews, Stock, OrgPrice, EDiscount);
	_ -> OrgPrice
    end.

filter_stock(news, [], _Stock, OrgPrice, EDiscount) ->
    {OrgPrice, EDiscount};
filter_stock(news, [{H}|T], Stock, OrgPrice, EDiscount) ->
    Amount = ?v(<<"amount">>, H),
    %% ?DEBUG("YSell ~p, Amount ~p", [YSell, Amount]), 
    case Amount > 0 of
	true ->
	    case Stock - Amount =< 0 of
		true ->
		    {?v(<<"org_price">>, H), ?v(<<"ediscount">>, H)}; 
		false ->
		    filter_stock(news, T, Stock - Amount, OrgPrice, EDiscount) 
	    end;
	false ->
	    filter_stock(news, T, Stock, OrgPrice, EDiscount)
    end.

sale_new(rsn_groups, MatchMode, {Merchant, UTable}, Conditions, PageFun) ->
    MDiscount = ?v(<<"mdiscount">>, Conditions),
    LDiscount = ?v(<<"ldiscount">>, Conditions),
    LSell     = ?v(<<"lsell">>, Conditions),
    MSell     = ?v(<<"msell">>, Conditions), 
    NewConditions = lists:keydelete(
		      <<"mdiscount">>, 1,
		      lists:keydelete(
			<<"ldiscount">>, 1,
			lists:keydelete(
			  <<"lsell">>, 1,
			  lists:keydelete(<<"msell">>, 1, Conditions)))),
    
    {DConditions, SConditions} = filter_condition(wsale, NewConditions, [], []),

    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions),

    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    "select n.id"
	", n.rsn"
	", n.style_number"
	", n.brand_id"
	", n.type_id"
	", n.sex"
	", n.season"
	", n.firm_id"
	", n.year"
	", n.s_group"
	", n.free"
	", n.total"
	", n.oil"
    %% ", n.negative"
	", n.reject"
	", n.pid"
	", n.sid"
	", n.org_price"
	", n.ediscount"
	", n.tag_price"
	", n.fdiscount"
	", n.rdiscount"
	", n.fprice"
	", n.rprice"
	", n.in_datetime"
	", n.path"
	", n.comment"
	", n.entry_date"

	", n.account_id"
	", n.shop_id"
	", n.retailer_id"
	", n.employee_id"
	", n.sell_type"

	", n.retailer"
	", n.phone"
	", n.account"

	", m.name as type"
	
	" from (" 
	"select b.id"
	", b.rsn"
	", b.style_number"
	", b.brand as brand_id"
	", b.type as type_id"
	", b.sex"
	", b.season"
	", b.firm as firm_id"
	", b.year"
	", b.s_group"
	", b.free"
	", b.total"
	", b.oil"
    %% ", b.negative"
	", b.reject"
	", b.promotion as pid"
	", b.score as sid"
	", b.org_price"
	", b.ediscount"
	", b.tag_price"
	", b.fdiscount"
	", b.rdiscount"
	", b.fprice"
	", b.rprice"
	", b.in_datetime"
	", b.path"
	", b.comment"
	", b.entry_date"

	", a.account as account_id"
	", a.shop as shop_id"
	", a.retailer as retailer_id"
	", a.employ as employee_id"
	", a.type as sell_type"

	", c.name as retailer"
	", c.mobile as phone"
	", d.name as account"

    %% " from w_sale_detail b, w_sale a"
	" from" ++ ?table:t(sale_detail, Merchant, UTable) ++ " b,"
	++ ?table:t(sale_new, Merchant, UTable) ++ " a"
	" left join w_retailer c on c.id=a.retailer"
	" left join users d on d.id=a.account"
	
    	" where "
    %% ++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:like_condition(style_number, MatchMode, CorrectCutDConditions, <<"b.style_number">>)
	++ case MDiscount of
	       undefined -> [];
	       _ ->
		   " and b.rprice/b.tag_price>" ++ ?to_s(?to_f(MDiscount/100))
	   end
	++ case LDiscount of
	       undefined -> [];
	       _ ->
		   " and b.rprice/b.tag_rprice<" ++ ?to_s(?to_f(LDiscount/100))
	   end
	++ case LSell of
	       undefined -> [];
	       _ ->
		   " and b.total<" ++ ?to_s(LSell)
	   end

	++ case MSell of
	       undefined -> [];
	       _ ->
		   " and b.total>" ++ ?to_s(MSell)
	   end 
	++ " and b.rsn=a.rsn"
	
	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end
    	++ PageFun() ++ ") n"

	" left join inv_types m on n.type_id=m.id".


pay_order(surplus, [], Pays) ->
    Pays;
pay_order(surplus, [Pay|T], Pays) ->
    pay_order(surplus, T, [Pay|Pays]);

pay_order(ShouldPay, [], Pays) when ShouldPay > 0 ->
    %% {ShouldPay, lists:reverse(Pays)}; 
    [H|T] = Pays,
    lists:reverse([H + ShouldPay|T]);
pay_order(ShouldPay, T, Pays) when ShouldPay =< 0 ->
    NewPays = lists:foldr(fun(_, Acc) -> [0|Acc] end, Pays, T),
    %% ?DEBUG("new pays ~p", [NewPays]),
    %% {ShouldPay, lists:reverse(NewPays)};
    lists:reverse(NewPays);
pay_order(ShouldPay, [Pay|T], Pays) ->
    pay_order(ShouldPay - Pay, T, [case Pay /= 0 andalso ShouldPay - Pay < 0 of
					 true -> ShouldPay;
					 false -> Pay end
				     |Pays]).

pay_order(reject, ShouldPay, [], Pays) when ShouldPay < 0 ->
    %% {ShouldPay, lists:reverse(Pays)}; 
    [H|T] = Pays,
    %% {ShouldPay, lists:reverse([H + ShouldPay|T])};
    lists:reverse([H + ShouldPay|T]);

pay_order(reject, ShouldPay, T, Pays) when ShouldPay >= 0 ->
    NewPays = lists:foldr(fun(_, Acc) -> [0|Acc] end, Pays, T),
    %% ?DEBUG("new pays ~p", [NewPays]),
    %% {ShouldPay, lists:reverse(NewPays)};
    lists:reverse(NewPays);
pay_order(reject, ShouldPay, [Pay|T], Pays) ->
    pay_order(reject, ShouldPay - Pay, T, [case Pay /= 0 andalso ShouldPay - Pay >= 0 of
				       true -> ShouldPay;
				       false -> Pay end
				   |Pays]).


get_modified(NewValue, OldValue) when NewValue /= OldValue -> NewValue;
get_modified(_NewValue, _OldValue) ->  undefined.

get_new(NewValue, OldValue) when NewValue /= OldValue -> NewValue;
get_new(_NewValue, OldValue) -> OldValue.

card_pay([], _LimitWithdraw, _UnlimitWithdraw, Cards) ->
    Cards;
card_pay([{struct, H}|T], LimitWithdraw, UnlimitWithdraw, Cards) ->
    C = ?v(<<"card">>, H),
    Draw = ?v(<<"draw">>, H),
    Type = ?v(<<"type">>, H),

    case Type of
	1 ->
	    case LimitWithdraw >= 0 of
		true ->
		    card_pay(T,
			     LimitWithdraw - Draw,
			     UnlimitWithdraw,
			     [{[{<<"card">>, C}, {<<"draw">>, Draw}, {<<"type">>, Type}]}|Cards]);
		false ->
		    card_pay(T, LimitWithdraw, UnlimitWithdraw, Cards)
	    end;
	0 ->
	    case UnlimitWithdraw >= 0 of
		true ->
		    card_pay(T,
			     LimitWithdraw,
			     UnlimitWithdraw - Draw,
			     [{[{<<"card">>, C}, {<<"draw">>, Draw}, {<<"type">>, Type}]}|Cards]);
		false ->
		    card_pay(T, LimitWithdraw, UnlimitWithdraw, Cards)
	    end
    end.

sort_charge_card([], Acc) ->
    Acc;
sort_charge_card([{H}|T], Acc) ->
    CardId = ?v(<<"card">>, H),
    %% ?DEBUG("Acc ~p", [Acc]),
    case [C || {C} <- Acc, ?v(<<"card">>, C) =:= CardId] of
	[] ->
	    sort_charge_card(T, [{H}|Acc]);
	[C] ->
	    M = [{[{<<"card">>, CardId},
		   {<<"draw">>, ?v(<<"draw">>, H) + ?v(<<"draw">>, C)},
		   {<<"type">>, ?v(<<"type">>, C)}]}],
	    sort_charge_card(T, (Acc -- [{C}]) ++ M)
    end.
      
card_flow([], Acc) ->
    %% ?DEBUG("Acc ~p", [Acc]),
    lists:sort(fun({_, _, B1}, {_, _, B2}) -> B1 =< B2 end, Acc );
card_flow([{H}|T], Acc) ->
    Id   = ?v(<<"id">>, H),
    Card = ?v(<<"bank">>, H),
    Draw = ?v(<<"balance">>, H),
    card_flow(T, [{Id, Card, Draw}|Acc]).

card_flow_sort([], Acc) ->
    lists:sort(fun({_, _, B1}, {_, _, B2}) -> B1 > B2 end, Acc );
card_flow_sort([{H}|T], Acc) ->
    Id   = ?v(<<"id">>, H),
    Card = ?v(<<"bank">>, H),
    Draw = ?v(<<"balance">>, H), 
    card_flow_sort(T, [{Id, Card, Draw}|Acc]).

set_order_state(Finish, _Order) when Finish =:= 0 -> ?ORDER_START;
set_order_state(Finish, Order) when Finish =:= Order -> ?ORDER_COMPLETED_FINISHED;
set_order_state(Finish, Order) when Finish < Order -> ?ORDER_PART_FINISHED.
    
rsn_order(use_id)    -> " order by b.id ";
rsn_order(use_shop)  -> " order by a.shop ";
rsn_order(use_brand) -> " order by b.brand ";
rsn_order(use_firm)  -> " order by b.firm ".
