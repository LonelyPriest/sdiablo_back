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
-export([sale/3, sale/4, pay_order/3, pay_order/4]).
-export([rsn_detail/3, get_modified/2]).
-export([filter/4, filter/6, export/3]).
-export([direct/1]).


%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).
-export([sort_condition/3, filter_condition/4]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
sale(new, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_sale, Merchant, Inventories, Props});
sale(update, Merchant, Inventories, {Props, OldProps}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_sale, Merchant, Inventories, Props, OldProps});
%% view the sale history of retailer
sale(history_retailer, Merchant, Retailer, Goods) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {history_retailer, Merchant, Retailer, Goods});
sale(reject, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reject_sale, Merchant, Inventories, Props});
sale(check, Merchant, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_new, Merchant, RSN, Mode});
sale(update_price, Merchant, RSN, Updates) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_price, Merchant, RSN, Updates}).

sale(list_new, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_new, Merchant, Condition});
sale(get_new, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new, Merchant, RSN}); 
sale(delete_new, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_new, Merchant, RSN});

sale(last, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {last_sale, Merchant, Condition});
sale(trace, Merchant, Condition) -> 
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trace_sale, Merchant, Condition});

sale(trans_detail, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trans_detail, Merchant, Condition});

sale(list_rsn_with_shop, Merchant, Shop) -> 
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_sale_rsn_with_shop, Merchant, Shop});
sale(get_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_sale_rsn, Merchant, Condition});
sale(match_rsn, Merchant, {ViewValue, Condition}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_sale_rsn, Merchant, {ViewValue, Condition}}).

rsn_detail(rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {rsn_detail, Merchant, Condition}).



filter(total_news, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_news, Merchant, Fields});

filter(total_rsn_group, MatchMode, Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_rsn_group, MatchMode, Merchant, Fields}, 6 * 1000);

filter(total_firm_detail, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_firm_detail, Merchant, Fields});

filter(total_employee_evaluation, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_employee_evaluation, Merchant, Fields}).

filter(news, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_news, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(rsn_group, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_rsn_group, {use_id, 0}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields}, 6 * 1000);

filter({rsn_group, Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_rsn_group, {Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields}, 6 * 1000);

filter(employee_evaluation, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_employee_evaluation, Merchant, CurrentPage, ItemsPerPage, Fields}).

export(trans, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_export, Merchant, Condition});
export(trans_note, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_export, Merchant, Condition});
export(trans_note_color_size, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_color_size_export, Merchant, Condition}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_sale, Merchant, Inventories, Props}, _From, State) ->
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
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),
    
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),
    Score      = ?v(<<"score">>, Props, 0),
    %% ScoreId    = ?v(<<"sid">>, Props, 0),
    %% DrawScore  = ?v(<<"draw_score">>, Props, 0),

    Ticket       = ?v(<<"ticket">>, Props, 0), 
    TicketScore  = ?v(<<"ticket_score">>, Props, 0),
    TicketBatch  = ?v(<<"ticket_batch">>, Props, -1),
    TicketCustom = ?v(<<"ticket_custom">>, Props, -1),
    
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
		    [NewTicket, NewWithdraw, NewWxin, NewCard, NewCash] =
			case ShouldPay >= 0 of
			    true ->
				pay_order(ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], []);
			    false ->
				pay_order(reject, ShouldPay,
					  [Ticket, Withdraw, Wxin, Card, Cash], [])
			end,
		    
		    ?DEBUG("NewCash ~p, NewCard ~p, NewWxin ~p, withdraw ~p, ticket ~p",
			   [NewCash,  NewCard, NewWxin, NewWithdraw, NewTicket]),
		    
		    SaleSn = lists:concat(
			       ["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-",
				?inventory_sn:sn(w_sale_new_sn, Merchant)]),
		    RealyShop = realy_shop(Merchant, Shop),
		    
		    Sql1 = 
			lists:foldr(
			  fun({struct, Inv}, Acc0)-> 
				  Amounts = ?v(<<"amounts">>, Inv), 
				  wsale(new, SaleSn, DateTime, Merchant, RealyShop, Inv, Amounts) ++ Acc0
			  end, [], Inventories), 

		    Sql2 = "insert into w_sale(rsn"
			", account, employ, retailer, shop, merchant, tbatch, tcustom"
			", balance, should_pay, cash, card, wxin, withdraw, ticket, verificate"
			", total, lscore, score, comment, type, entry_date) values("
			++ "\"" ++ ?to_s(SaleSn) ++ "\","
			++ ?to_s(UserId) ++ ","
			++ "\'" ++ ?to_s(Employe) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(Shop) ++ ","
			++ ?to_s(Merchant) ++ "," 
			++ ?to_s(TicketBatch) ++ ","
			++ ?to_s(TicketCustom) ++ "," 
			++ ?to_s(CurrentBalance) ++ ","
			++ ?to_s(ShouldPay) ++ "," 
			++ ?to_s(NewCash) ++ ","
			++ ?to_s(NewCard) ++ ","
			++ ?to_s(NewWxin) ++ ","
			++ ?to_s(NewWithdraw) ++ ","
			++ ?to_s(NewTicket) ++ ","
			++ ?to_s(Verificate) ++ ","
			++ ?to_s(Total) ++ ","
			++ ?to_s(CurrentScore) ++ ","
			++ ?to_s(Score) ++ "," 
			++ "\"" ++ ?to_s(Comment) ++ "\"," 
			++ ?to_s(type(new)) ++ ","
			++ "\"" ++ ?to_s(DateTime) ++ "\");",

		    Sql3 = ["update w_retailer set consume=consume+" ++ ?to_s(ShouldPay)
			    ++ case NewWithdraw =< 0 of
				   true  -> [];
				   false -> ", balance=balance-" ++ ?to_s(NewWithdraw)
			       end
			    ++ case Score == 0 andalso TicketScore =< 0 of
				   true  -> [];
				   false -> ", score=score+" ++ ?to_s(Score - TicketScore)
			       end 
			    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))],

		    Sql4 = case TicketBatch of
			       ?INVALID_OR_EMPTY ->
				   [];
			       _ ->
				   case TicketCustom of
				       ?SCORE_TICKET ->
					   ["update w_ticket set state=" ++ ?to_s(?TICKET_STATE_CONSUMED)
					    ++ " where merchant=" ++ ?to_s(Merchant)
					    ++ " and batch=" ++ ?to_s(TicketBatch)
					    ++ " and retailer=" ++ ?to_s(Retailer)];
				       ?CUSTOM_TICKET ->
					   ["update w_ticket_custom set "
					    "state=" ++ ?to_s(?TICKET_STATE_CONSUMED)
					    ++ ", retailer=" ++ ?to_s(Retailer)
					    ++ ", shop=" ++ ?to_s(Shop)
					    ++ " where merchant=" ++ ?to_s(Merchant)
					    ++ " and batch=" ++ ?to_s(TicketBatch)];
				       ?INVALID_OR_EMPTY ->
					   []
				   end
			   end,

		    AllSql = Sql1 ++ [Sql2] ++ Sql3 ++ Sql4,
		    case ?sql_utils:execute(transaction, AllSql, SaleSn) of
			{ok, SaleSn} -> 
			    {reply, {ok,
				     {SaleSn,
				      ?v(<<"mobile">>, Account),
				      ShouldPay,
				      CurrentBalance - NewWithdraw,
				      ?v(<<"score">>, Account) + Score - TicketScore} 
				    }, State};
			Error ->
			    {reply, Error, State}
		    end 
	    end;
	Error ->
	    {reply, Error, State}
    end;


handle_call({update_sale, Merchant, Inventories, Props, OldProps}, _From, State) ->
    ?DEBUG("update_sale with merchant ~p~n~p, props ~p, OldProps ~p",
	   [Merchant, Inventories, Props, OldProps]),

    Curtime    = ?utils:current_time(format_localtime), 
    
    RSN        = ?v(<<"rsn">>, Props),
    Retailer   = ?v(<<"retailer">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    Datetime   = ?v(<<"datetime">>, Props, Curtime), 
    Employee   = ?v(<<"employee">>, Props),

    %% Balance    = ?v(<<"balance">>, Props),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Ticket     = ?v(<<"ticket">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props),
    
    Total        = ?v(<<"total">>, Props),
    Score        = ?v(<<"score">>, Props, 0),

    RSNId        = ?v(<<"id">>, OldProps),
    OldEmployee  = ?v(<<"employ_id">>, OldProps),
    OldRetailer  = ?v(<<"retailer_id">>, OldProps),
    OldShouldPay = ?v(<<"should_pay">>, OldProps),
    OldDatetime  = ?v(<<"entry_date">>, OldProps),
    OldScore     = ?v(<<"score">>, OldProps),

    OldCash       = ?v(<<"cash">>, OldProps),
    OldCard       = ?v(<<"card">>, OldProps),
    OldWxin       = ?v(<<"wxin">>, OldProps),
    OldWithdraw   = ?v(<<"withdraw">>, OldProps),
    OldTicket     = ?v(<<"ticket">>, OldProps),
    
    %% OldComment   = ?v(<<"comment">>, OldProps),
    OldTotal     = ?v(<<"total">>, OldProps),
    SellType     = ?v(<<"type">>, OldProps),

    MShouldPay   = ShouldPay - OldShouldPay,
    MScore       = Score - OldScore,
    RealyShop    = realy_shop(Merchant, Shop),
    
    [NewTicket, NewWithdraw, NewWxin, NewCard, NewCash] = _NewPays =
	case SellType of
	    0 ->
		case ShouldPay >= 0 of
		    true ->
			pay_order(ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], []);
		    false ->
			pay_order(reject, ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], [])
		end;
	    1 -> pay_order(reject, ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], [])
	end,
    ?DEBUG("new pays ~p", [_NewPays]),

    NewDatetime = case Datetime =:= OldDatetime of
		      true -> Datetime;
		      false -> ?utils:correct_datetime(datetime, Datetime)
		  end,
    
    Sql1 = sql(update_wsale, RSN, Merchant, RealyShop, NewDatetime, OldDatetime, Inventories),

    Updates = ?utils:v(employ, string, get_modified(Employee, OldEmployee))
	++ ?utils:v(retailer, integer, get_modified(Retailer, OldRetailer)) 
    %% ++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(should_pay, float, get_modified(ShouldPay, OldShouldPay))
	++ ?utils:v(cash, float, get_modified(NewCash, OldCash))
	++ ?utils:v(card, float, get_modified(NewCard, OldCard))
	++ ?utils:v(wxin, float, get_modified(NewWxin, OldWxin))
	++ ?utils:v(withdraw, float, get_modified(NewWithdraw, OldWithdraw))
	++ ?utils:v(ticket, float, get_modified(NewTicket, OldTicket))
	++ ?utils:v(total, integer, get_modified(Total, OldTotal))
	++ ?utils:v(score, integer, get_modified(Score, OldScore))
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(entry_date, string, get_modified(NewDatetime, OldDatetime)), 

    case Retailer =:= OldRetailer of
	true ->
	    Sql2 = "update w_sale set " ++ ?utils:to_sqls(proplists, comma, Updates) 
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'", 
	    ?DEBUG("Sql2 ~ts", [Sql2]),

	    AllSql = Sql1 ++ [Sql2] ++
		case ?utils:v_0(consume, float, MShouldPay)
		    ++ ?utils:v_0(score, integer, MScore)
		    ++ ?utils:v_0(balance, float, Withdraw - NewWithdraw) of
		    [] -> [];
		    U0 ->
			?DEBUG("U0 ~p", [U0]),
			["update w_retailer set " ++ ?utils:to_sqls(plus, comma, U0)
			   ++ ", change_date=" ++ "\"" ++ ?to_s(Curtime) ++ "\""
			   ++ " where id=" ++ ?to_s(Retailer)
			   ++ " and merchant=" ++ ?to_s(Merchant)]
		end 
		++ case Withdraw - NewWithdraw /= 0 of
		       true -> 
			   ["update w_sale set balance=balance+" ++ ?to_s(Withdraw - NewWithdraw)
			    %% ++ " where shop=" ++ ?to_s(Shop)
			       ++ " where merchant=" ++ ?to_s(Merchant)
			       ++ " and retailer=" ++ ?to_s(Retailer)
			       ++ " and id>" ++ ?to_s(RSNId)];
		       false -> []
		   end,
	    
	    Reply = ?sql_utils:execute(
		       transaction, AllSql,
		       {RSN, MShouldPay, MScore,
			{OldRetailer, Withdraw}, {Retailer, NewWithdraw}}),
	    %% ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State}; 
	false ->
	    Sql0 = "select id, rsn, retailer, shop, merchant"
		", balance, should_pay, withdraw, lscore, score from w_sale"
	    %% " where shop=" ++ ?to_s(Shop)
		" where merchant=" ++ ?to_s(Merchant)
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
		"update w_sale set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, NewLastBalance)
		      ++ ?utils:v(lscore, float, NewLastScore) ++ Updates) 
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		++ " and merchant=" ++ ?to_s(Merchant), 
		%% ++ " and id=" ++ ?to_s(RSNId),

	    BackBalanceOfOldRetailer = Withdraw,
	    BalanceOfNewRetailer =  NewWithdraw,

	    AllSql = Sql1 ++ [Sql2] ++ 
		["update w_retailer set balance=balance+"
		 ++ ?to_s(BackBalanceOfOldRetailer) 
		 ++ ", score=score-" ++ ?to_s(OldScore)
		 ++ ", consume=consume-" ++ ?to_s(OldShouldPay)
		 ++ " where id=" ++ ?to_s(OldRetailer),

		 "update w_sale set balance=balance+"
		 ++ ?to_s(BackBalanceOfOldRetailer)
		 ++ ", score=score-" ++ ?to_s(OldScore)
		 %% ++ " where shop=" ++ ?to_s(Shop)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(OldRetailer)
		 ++ " and id>" ++ ?to_s(RSNId),

		 
		 "update w_retailer set balance=balance-"
		 ++ ?to_s(BalanceOfNewRetailer) 
		 ++ ", score=score+" ++ ?to_s(Score)
		 ++ ", consume=consume+" ++ ?to_s(ShouldPay)
		 ++ " where id=" ++ ?to_s(Retailer), 

		 "update w_sale set balance=balance-"
		 ++ ?to_s(BalanceOfNewRetailer)
		 ++ ", score=score+" ++ ?to_s(Score)
		 %% ++ " where shop=" ++ ?to_s(Shop)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(Retailer)
		 ++ " and id>" ++ ?to_s(RSNId)
		],

	    Reply = ?sql_utils:execute(
		       transaction, AllSql,
		       {RSN, MShouldPay, MScore,
			{OldRetailer, Withdraw}, {Retailer, NewWithdraw}}),
	    %% ?w_user_profile:update(retailer, Merchant),

	    {reply, Reply, State}

    end; 

handle_call({check_new, Merchant, RSN, Mode}, _From, State) ->
    ?DEBUG("check_new with merchant ~p, RSN ~p, mode ~p", [Merchant, RSN, Mode]),
    Sql = "update w_sale set state=" ++ ?to_s(Mode)
	++ ", check_date=\'" ++ ?utils:current_time(localtime) ++ "\'"
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({list_new, Merchant, Conditions}, _From, State) ->
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
	", a.verificate"
	", a.total"
	", a.comment"
	", a.rdate"
	", a.entry_date"
	
	", b.name as employee"
	", c.name as retailer"
	", d.name as shop"
	
	" from w_sale a"
	++ " left join employees b on a.employ=b.number"
	++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer c on a.retailer=c.id"
	++ " left join shops d on a.shop=d.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ";",
    {ok, Records} = ?mysql:fetch(read, Sql),
    {reply, ?to_tl(Records), State};

handle_call({get_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("get_new with merchant ~p, rsn ~p", [Merchant, RSN]),
    Sql = "select id"
	", rsn"
	", employ as employ_id"
	", retailer as retailer_id"
	", shop as shop_id"
	", tbatch"
	", tcustom"
	", balance"
	", should_pay"
	", cash"
	", card"
	", wxin"
	", withdraw"
	", ticket"
	", verificate"
	", total"
	", lscore"
	", score"
	", comment"
	", type"
	", entry_date" 
	" from w_sale" 
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({delete_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("delete_new with merchant ~p, rsn ~p", [Merchant, RSN]),
    Sql = "delete from w_sale where merchant=" ++ ?to_s(Merchant)
	++ " and rsn =\'" ++ ?to_s(RSN) ++ "\'",
    Reply =  ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({last_sale, Merchant, Conditions}, _From, State) ->
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
	" from w_sale a, w_sale_detail b"
	" where a.rsn=b.rsn" ++ ?sql_utils:condition(proplists, C1)
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

handle_call({trace_sale, Merchant, Conditions}, _From, State) ->
    ?DEBUG("trance_sale with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = sale_new(rsn_groups, 'and', Merchant, Conditions, fun() -> " order by id desc" end),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({get_sale_rsn, Merchant, Conditions}, _From, State) ->
    ?DEBUG("get_sale_rsn with merchant=~p, conditions ~p", [Merchant, Conditions]),
    
    {DetailConditions, SaleConditions} =
	filter_condition(wsale, [{<<"merchant">>, Merchant}|Conditions], [], []),
    ?DEBUG("sale conditions ~p, detail condition ~p", [SaleConditions, DetailConditions]), 

    {StartTime, EndTime, CutSaleConditions}
	= ?sql_utils:cut(fields_with_prifix, SaleConditions),
    
    Sql1 = 
	"select a.rsn from w_sale a"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    Sql = 
	case ?v(<<"rsn">>, SaleConditions, []) of
	    [] ->
		case DetailConditions of
		    [] -> Sql1;
		    _ ->
			"select a.rsn from w_sale a inner join (select rsn from w_sale_detail"
			    " where merchant=" ++ ?to_s(Merchant)
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

handle_call({match_sale_rsn, Merchant, {ViewValue, Conditions}}, _From, State) ->
    {StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),

    Limit = ?w_retailer:get(prompt, Merchant),
    Sql = "select id, rsn from w_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, undefined)
	++ " and rsn like \'%" ++ ?to_s(ViewValue) ++ "\'"
	++ " order by id desc"
	++ " limit " ++ ?to_s(Limit),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({history_retailer, Merchant, Retailer, Goods}, _From, State) ->
    ?DEBUG("history_retailer with merchant ~p, retailer ~p~n goods ~p",
	   [Merchant, Retailer, Goods]),
    [{S1, B1}|T] = Goods,

    Sql = "select style_number, brand"
	" from w_sale_detail where rsn in"
	"(select rsn from w_sale where retailer="++ ?to_s(Retailer) ++ ")" 
	++ " and (style_number, brand) in("
	++ lists:foldr(
	     fun({StyleNumber, Brand}, Acc)->
		     "(\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ")," ++ Acc
	     end, [], T)
	++ "(\'" ++ ?to_s(S1) ++ "\'," ++ ?to_s(B1) ++ "))",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 


handle_call({rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]),
    C = ?utils:to_sqls(proplists, Conditions),
    Sql = "select id, rsn, style_number, brand as brand_id, color as color_id"
	", size, total as amount"
	" from w_sale_detail_amount" 
	" where " ++ C, 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({trans_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("trans_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql =
	" select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand_id"
	", a.type_id"
	", a.sex"
	", a.s_group"
	", a.free"
	", a.season"
	", a.firm_id"
	", a.year"
	", a.in_datetime"
	", a.total"
	", a.pid"
	", a.sid"
	", a.org_price"
	", a.tag_price"
	", a.fdiscount"
	", a.rdiscount"
	", a.fprice"
	", a.rprice"
	", a.path"
	", a.comment"
	
	", b.color as color_id"
	", b.size"
	", b.total as amount"
	
	" from "
	
	"(select id"
	", rsn"
	", style_number"
	", brand as brand_id"
	", type as type_id"
	", sex"
	", s_group"
	", free"
	", season"
	", firm as firm_id"
	", year"
	", in_datetime"
	", total"
	", promotion as pid"
	", score as sid"
	", org_price"
	", tag_price"
	", fdiscount"
	", rdiscount"
	", fprice"
	", rprice"
	", path"
	", comment"
	" from w_sale_detail"
	" where " ++ ?utils:to_sqls(proplists, Conditions) ++ ") a"

	" inner join w_sale_detail_amount b on a.rsn=b.rsn"
	" and a.style_number=b.style_number"
	" and a.brand_id=b.brand",    

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% filter with pagination
%% =============================================================================
handle_call({total_news, Merchant, Fields}, _From, State) ->
    CountSql = count_table(w_sale, Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_news, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_with_and: "
	   "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = filter_table(
	    w_sale_with_page, Merchant, CurrentPage, ItemsPerPage, Fields), 
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% =============================================================================
%% reject
%% =============================================================================
handle_call({reject_sale, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("reject_sale with merchant ~p~n~p, props ~p", [Merchant, Inventories, Props]),
    UserId = ?v(<<"user">>, Props, -1),
    Retailer   = ?v(<<"retailer_id">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    %% Datetime   = ?v(<<"datetime">>, Props, ?utils:current_time(localtime)),
    Datetime   = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Employe    = ?v(<<"employee">>, Props),

    %% Balance    = ?v(<<"balance">>, Props), 
    Comment    = ?v(<<"comment">>, Props, ""),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    
    
    Withdraw   = ?v(<<"withdraw">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),
    Score      = ?v(<<"score">>, Props, 0),

    Ticket     = ?v(<<"ticket">>, Props, 0),
    TicketScore = ?v(<<"ticket_score">>, Props, 0),
    TicketBatch = ?v(<<"tbatch">>, Props, -1),
    TicketCustom = ?v(<<"tcustom">>, Props, -1),
    
    Sql0 = "select id, name, balance, score, type from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} -> 
	    Sn = lists:concat(["M-", ?to_i(Merchant),
			       "-S-", ?to_i(Shop), "-R-",
			       ?inventory_sn:sn(w_sale_reject_sn, Merchant)]),
	    {ShopType, RealyShop} = realy_shop(reject, Merchant, Shop),

	    Sql1 =
		case ShopType of
		    ?BAD_REPERTORY ->
			lists:foldr(
			  fun({struct, Inv}, Acc0)->
				  Amounts = ?v(<<"amounts">>, Inv),
				  wsale(reject_badrepo,
					Sn,
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
					Sn,
					Datetime,
					Merchant,
					RealyShop,
					Inv,
					Amounts) ++ Acc0
			  end, [], Inventories)
		end,

	    CurrentBalance = retailer(balance, Account),
	    CurrentScore = retailer(score, Account),

	    [NewTicket, NewWithdraw, NewWxin, NewCard, NewCash] = NewPays =
		case ShouldPay >= 0 of
		    true ->
			pay_order(ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], []);
		    false ->
			pay_order(reject, ShouldPay, [Ticket, Withdraw, Wxin, Card, Cash], [])
		end,
	    ?DEBUG("new pays ~p", [NewPays]),
	    
	    Sql2 = "insert into w_sale(rsn"
		", account, employ, retailer, shop, merchant, tbatch, tcustom, balance"
		", should_pay, cash, card, wxin, ticket, withdraw, verificate, total"
		", lscore, score, comment, type, entry_date) values("
		++ "\"" ++ ?to_s(Sn) ++ "\","
		++ ?to_s(UserId) ++ ","
		++ "\'" ++ ?to_s(Employe) ++ "\',"
		++ ?to_s(Retailer) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ ?to_s(TicketBatch) ++ ","
		++ ?to_s(TicketCustom) ++ ","
		++ ?to_s(CurrentBalance) ++ ","
		++ ?to_s(-ShouldPay) ++ ","
		++ ?to_s(-NewCash) ++ ","
		++ ?to_s(-NewCard) ++ ","
		++ ?to_s(-NewWxin) ++ ","
		++ ?to_s(-NewTicket) ++ ","
		%% ++ case Withdraw == ShouldPay of
		%%        true  -> ?to_s(0) ++ ",";
		%%        false -> ?to_s((Withdraw - ShouldPay)) ++ ","
		%%    end
		++ ?to_s(-NewWithdraw) ++ ","
		++ ?to_s(-Verificate) ++ ","
		++ ?to_s(-Total) ++ ","
		++ ?to_s(CurrentScore) ++ ","
		++ ?to_s(-Score) ++ ","
		++ "\"" ++ ?to_s(Comment) ++ "\"," 
		++ ?to_s(type(reject)) ++ ","
		++ "\"" ++ ?to_s(Datetime) ++ "\");",

	    Sql3 = ["update w_retailer set consume=consume-" ++ ?to_s(ShouldPay)
		++ case NewWithdraw > 0 of
		       true -> ", balance=balance+" ++ ?to_s(NewWithdraw);
		       false -> []
		   end
		++ case TicketScore - Score /= 0 of
		       true -> ", score=score+" ++ ?to_s(TicketScore - Score);
		       false -> []
		   end
		    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account))], 

	    Sql4 =
		case TicketBatch =:= -1 of
		    true -> [];
		    false ->
			case TicketCustom of
			    ?CUSTOM_TICKET ->
				["update w_ticket_custom set state=" ++ ?to_s(?TICKET_STATE_CHECKED)
				 ++ ", retailer=" ++ ?to_s(?INVALID_OR_EMPTY)
				 ++ ", shop=" ++ ?to_s(?INVALID_OR_EMPTY)
				 ++ " where merchant=" ++ ?to_s(Merchant)
				 ++ " and batch=" ++ ?to_s(TicketBatch)];
			    ?SCORE_TICKET ->
				["update w_ticket set state=" ++ ?to_s(?TICKET_STATE_CHECKING)
				 ++ " where merchant=" ++ ?to_s(Merchant)
				 ++ " and batch=" ++ ?to_s(TicketBatch)]
			end
		end,

	    AllSql = Sql1 ++ [Sql2] ++ Sql3 ++ Sql4,

	    case ?sql_utils:execute(transaction, AllSql, Sn) of
		{error, _} = Error ->
		    {reply, Error, State};
		OK ->
		    %% case NewWithdraw =/= 0 orelse TicketScore - Score =/= 0 of
		    %% 	true  -> ?w_user_profile:update(retailer, Merchant);
		    %% 	false -> ok
		    %% end,
		    {reply, {OK, Shop, Retailer, ?v(<<"type">>, Account), NewWithdraw}, State}
	    end; 
	Error ->
	    {reply, Error, State}
    end;

handle_call({total_rsn_group, MatchMode, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_rsn_group with merchant ~p, matchMode ~p, conditions ~p", [Merchant, MatchMode, Conditions]),
    MDiscount = ?v(<<"mdiscount">>, Conditions),
    LDiscount = ?v(<<"ldiscount">>, Conditions),
    LSell     = ?v(<<"lsell">>, Conditions),
    NewConditions = lists:keydelete(
		      <<"mdiscount">>, 1,
		      lists:keydelete(<<"ldiscount">>, 1,
				      lists:keydelete(<<"lsell">>, 1, Conditions))),
    {DConditions, SConditions} = filter_condition(wsale, NewConditions, [], []),
    
    
    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions), 
    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),

    %% ?DEBUG("CutDCondtions ~p", [CutDCondtions]),
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    Sql = "select count(*) as total"
    	", SUM(b.total) as t_amount"
	", SUM(b.tag_price * b.total) as t_tbalance"
    	", SUM(b.rprice * b.total) as t_balance"
	", SUM(b.org_price * b.total) as t_obalance"
	
    	" from w_sale_detail b, w_sale a"

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

handle_call({total_firm_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_rsn_group with merchant ~p, conditions ~p", [Merchant, Conditions]),

    Sql = "select count(*) as total"
    	", SUM(total) as t_amount" 
    	" from w_sale_detail"

    	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " group by style_number, brand, shop",
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_rsn_group, {Mode, Sort},
	     MatchMode, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_rsn_group_and: mode ~p, sort ~p, MatchMode ~p, currentPage ~p"
	   ", ItemsPerpage ~p, Merchant ~p~n",
	   [Mode, Sort, MatchMode, CurrentPage, ItemsPerPage, Merchant]), 
    Sql = sale_new(rsn_groups, MatchMode, Merchant, Conditions,
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

handle_call({new_trans_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_export with merchant ~p, condition ~p", [Merchant, Conditions]),
    Sql = filter_table(w_sale, Merchant, Conditions),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_trans_note_export, Merchant, Conditions}, _From, State)->
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
	
	" from w_sale_detail a"
	" inner join w_sale b on a.rsn=b.rsn" 

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


handle_call({new_trans_note_color_size_export, Merchant, Conditions}, _From, State)->
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
	
	" from w_sale_detail_amount a"
	" left join colors b on a.merchant=b.merchant and a.color = b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({update_price, Merchant, RSN, Updates}, _From, State) ->
    ?DEBUG("update_price: merchant ~p, RSN ~p, Updates ~p", [Merchant, RSN, Updates]),
    OrgPrice = ?v(<<"org_price">>, Updates),
    TagPrice = ?v(<<"tag_price">>, Updates),
    StyleNumber = ?v(<<"style_number">>, Updates),
    Brand = ?v(<<"brand">>, Updates),

    EDiscount = case TagPrice of
		    undefined -> 0;
		    _ -> ?w_good_sql:stock(ediscount, OrgPrice, TagPrice)
		end, 
    
    Sql = "update w_sale_detail set org_price=" ++ ?to_s(OrgPrice)
	++ ", ediscount=" ++ ?to_s(EDiscount)
	++ " where rsn=\'" ++ ?to_s(RSN)  ++ "\'"
	++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(Brand)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({total_employee_evaluation, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_employee_evaluation: merchant ~p, conditions ~p", [Merchant, Conditions]),
    SortConditions = sort_condition(wsale, Merchant, Conditions), 
    Sql = "select count(*) as total"
	", SUM(a.balance) as t_balance"
	", SUM(a.cash) as t_cash"
	", SUM(a.card) as t_card"
	", SUM(a.wxin) as t_wxin"
	", SUM(a.draw) as t_draw"
	", SUM(a.veri) as t_veri"
	", SUM(a.ticket) as t_ticket" 
	" from "
	" (select a.employee_id, a.shop_id, a.balance, a.cash, a.card, a.wxin, a.draw, a.ticket, a.veri"
	" from "
	"(select merchant"
	", employ as employee_id"
	", shop as shop_id"
	", SUM(should_pay) as balance"
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wxin) as wxin"
	", SUM(withdraw) as draw"
	", SUM(verificate) as veri"
	", SUM(ticket) as ticket"
	" from w_sale a"
    %% " where merchant=" ++ ?to_s(Merchant)
	++ " where " ++ SortConditions
	++ " group by employ, shop) a) a", 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_employee_evaluation, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_employee_evaluation:merchant ~p, conditions ~p, page ~p", [Merchant, Conditions, CurrentPage]),
    SortConditions = sort_condition(wsale, Merchant, Conditions),
    Sql = 
	" select a.employee_id, a.shop_id, a.balance, a.cash, a.card, a.wxin, a.draw, a.ticket, a.veri"
	" from "
	"(select merchant"
	", employ as employee_id"
	", shop as shop_id"
	", SUM(should_pay) as balance"
	", SUM(cash) as cash"
	", SUM(card) as card"
	", SUM(wxin) as wxin"
	", SUM(withdraw) as draw"
	", SUM(ticket) as ticket"
	", SUM(verificate) as veri"
	" from w_sale a"
    %% " where merchant=" ++ ?to_s(Merchant)
	++ " where " ++ SortConditions
	++ " group by employ, shop) a"	
	++ ?sql_utils:condition(page_desc, {use_balance, 0}, CurrentPage, ItemsPerPage),
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call(_Request, _From, State) ->
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

sql(update_wsale, RSN, _Merchant, _Shop, NewDatetime, OldDatetime, []) ->
    case NewDatetime =:= OldDatetime of
	true -> [];
	false ->
	    ["update w_sale_detail set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",
	     "update w_sale_detail_amount set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"]
    end;
    
sql(update_wsale, RSN, Merchant, Shop, NewDatetime, _OldDatetime, Inventories) -> 
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv), 
	      case Operation of
		  <<"d">> ->
		      Amounts = ?v(<<"amount">>, Inv),
		      wsale(delete, RSN, NewDatetime, Merchant,
			    Shop, Inv, Amounts) ++ Acc0; 
		  <<"a">> ->
		      Amounts = ?v(<<"amount">>, Inv), 
		      wsale(new, RSN, NewDatetime, Merchant,
			    Shop, Inv, Amounts) ++ Acc0; 
		  <<"u">> -> 
		      wsale(update, RSN, NewDatetime, Merchant,
			    Shop, Inv) ++ Acc0
	      end
      end, [], Inventories).
    

wsale(update, RSN, Datetime, Merchant, Shop, Inventory) -> 
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
	    0 -> ["update w_sale_detail set "
		  ++ "org_price=" ++ ?to_s(OrgPrice)
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
		["update w_inventory set amount=amount-" ++ ?to_s(Metric)
		 ++ ", sell=sell+" ++ ?to_s(Metric)
		 ++ " where "
		 "style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update w_sale_detail set total=total+" ++ ?to_s(Metric)
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
			Sql01 = "select id, style_number, brand, color, size"
			    " from w_sale_detail_amount"
			    " where " ++ C2(Color, Size),

			["update w_inventory_amount set total=total-"
			 ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 case ?sql_utils:execute(s_read, Sql01) of
			     {ok, []} ->
				 "insert into w_sale_detail_amount(rsn"
				     ", style_number, brand, "
				     "color, size, total, entry_date) values("
				     ++ "\"" ++ ?to_s(RSN) ++ "\","
				     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				     ++ ?to_s(Brand) ++ ","
				     ++ ?to_s(Color) ++ ","
				     ++ "\'" ++ ?to_s(Size)  ++ "\',"
				     ++ ?to_s(Count) ++ "," 
				     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
			     {ok, _} ->
				 "update w_sale_detail_amount"
				     " set total=total+" ++ ?to_s(Count)
				     ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
				     ++ " where " ++ C2(Color, Size);
			     {error, E00} ->
				 throw({db_error, E00})
			 end | Acc1];

		    <<"d">> -> 
			["update w_inventory_amount set total=total+"
			 ++ ?to_s(Count) ++ " where " ++ C1(Color, Size), 

			 "delete from w_sale_detail_amount"
			 " where " ++ C2(Color, Size)
			 | Acc1];
		    <<"u">> -> 
			["update w_inventory_amount"
			 " set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 " update w_sale_detail_amount"
			 " set total=total+" ++ ?to_s(Count)
			 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts). 
    
wsale(delete, RSN, _DateTime, Merchant, Shop, Inventory, Amounts)
  when is_list(Amounts)->
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

    ["update w_inventory set amount=amount+" ++ ?to_s(Metric)
     ++ ",sell=sell-" ++ ?to_s(Metric) 
     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)
     ++ " and shop=" ++ ?to_s(Shop)
     ++ " and merchant=" ++ ?to_s(Merchant),

     "delete from w_sale_detail"
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)]
	++ 
        lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  Count  = ?v(<<"sell_count">>, Attr),
		  ["update w_inventory_amount set total=total+" ++ ?to_s(Count)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand) 
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   "delete from w_sale_detail_amount"
		   " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   | Acc1]
	     end, [], Amounts);


wsale(reject_badrepo, RSN, DateTime, Merchant, {Shop, RealyShop}, Inventory, Amounts) -> 
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

wsale(Action, RSN, Datetime, Merchant, Shop, Inventory, Amounts) -> 
    ?DEBUG("wsale ~p with inv ~p, amounts ~p", [Action, Inventory, Amounts]),
    
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),
    
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory), 
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
    Promotion   = ?v(<<"promotion">>, Inventory, -1),
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

    Sql00 = "select rsn, style_number, brand, type from w_sale_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 
    
    ["update w_inventory set amount=amount-" ++ ?to_s(Total)
     ++ ", sell=sell+" ++ ?to_s(Total) 
     ++ ", last_sell=" ++ "\'" ++ ?to_s(Datetime) ++ "\'"
     ++ " where " ++ C1(),

     case ?sql_utils:execute(s_read, Sql00) of
	 {ok, []} ->
	     {ValidOrgPrice, ValidEDiscount}
		 = case Action of
		       new  -> valid_orgprice(stock, Merchant, Shop, Inventory);
		       reject -> {OrgPrice, ?w_good_sql:stock(ediscount, OrgPrice, TagPrice)}
		   end,
	     "insert into w_sale_detail("
		 "rsn, style_number, brand, merchant, shop, type, sex, s_group, free"
		 ", season, firm, year, in_datetime, total, promotion, score"
		 ", org_price, ediscount, tag_price, fdiscount, rdiscount, fprice, rprice"
		 ", path, comment, entry_date) values("
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
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Promotion) ++ ","
		 ++ ?to_s(Score) ++ ","
		 
		 ++ ?to_s(ValidOrgPrice) ++ ","
		 ++ ?to_s(ValidEDiscount) ++ ","
		 ++ ?to_s(TagPrice) ++ "," 
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(RDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ ?to_s(RPrice) ++ ","
		 
		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
	 {ok, _} ->
	     "update w_sale_detail set total=total+" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", rdiscount=" ++ ?to_s(RDiscount)
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", rprice=" ++ ?to_s(RPrice) 
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
		      " from w_sale_detail_amount"
		      " where " ++ C2(Color, Size),
		  
		  ["update w_inventory_amount set total=total-" ++ ?to_s(Count)
		   ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(Color)
		   ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),
		   
		   case ?sql_utils:execute(s_read, Sql01) of
		       {ok, []} ->
			   "insert into w_sale_detail_amount(rsn"
			       ", style_number, brand, color, size"
			       ", total, merchant, shop, entry_date) values("
			       ++ "\"" ++ ?to_s(RSN) ++ "\","
			       ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			       ++ ?to_s(Brand) ++ ","
			       ++ ?to_s(Color) ++ ","
			       ++ "\"" ++ ?to_s(Size) ++ "\","
			       ++ ?to_s(Count) ++ ","
			       ++ ?to_s(Merchant) ++ ","
			       ++ ?to_s(Shop) ++ ","
			       ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		       {ok, _} ->
			   "update w_sale_detail_amount"
			       " set total=total+" ++ ?to_s(Count)
			       ++ ", entry_date="
			       ++ "\'" ++ ?to_s(Datetime) ++ "\'"
			       ++ " where " ++ C2(Color, Size);
		       {error, E01} ->
			   throw({db_error, E01})
		   end|Acc1] 
	  end, [], Amounts).

count_table(w_sale, Merchant, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
    	", sum(a.should_pay + a.verificate) as t_spay"
	", sum(a.should_pay) as t_rpay"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
	", sum(a.wxin) as t_wxin"
	", sum(a.withdraw) as t_withdraw"
	", sum(a.ticket) as t_ticket"
	%% ", sum(a.balance) as t_balance"
	" from w_sale a where " ++ SortConditions, 
    CountSql.

filter_table(w_sale, Merchant, Conditions) ->
    SortConditions = sort_condition(wsale, Merchant, Conditions),

    Sql = "select a.id, a.rsn"
	", a.employ as employee_id"
	", a.retailer as retailer_id"
	", a.shop as shop_id"
    %% ", a.promotion as pid, a.charge as cid"
	
	", a.balance, a.should_pay, a.cash, a.card, a.wxin, a.withdraw, a.ticket, a.verificate"
	", a.total, a.score"
	
	", a.comment, a.type, a.entry_date"
	
	", b.name as shop"
	", c.name as employee"
	", d.name as retailer"
	
	" from w_sale a"
	" left join shops b on a.shop=b.id"
	" left join employees c on a.employ=c.number and c.merchant=" ++ ?to_s(Merchant)
	++ " left join w_retailer d on a.retailer=d.id"
	" where " ++ SortConditions ++ " order by a.id desc",
    Sql.

filter_table(w_sale_with_page, Merchant, CurrentPage, ItemsPerPage, Conditions) -> 
    SortConditions = sort_condition(wsale, Merchant, Conditions),
    
    Sql = "select a.id"
	", a.rsn"
	", a.account"
	", a.employ as employee_id"
    	", a.retailer as retailer_id"
	", a.shop as shop_id"
    %% ", a.promotion as pid"
	
	", a.balance"
	", a.should_pay"
	", a.cash"
	", a.card"
	", a.wxin"
	", a.withdraw"
	", a.ticket"
	", a.verificate"
	", a.total"
	", a.score"
	
	", a.comment"
	", a.type"
	", a.state"
	", a.entry_date"
	
	", b.name as retailer"
	", c.name as account"
	
    	" from w_sale a" 
	" left join w_retailer b on a.retailer=b.id"
	" left join users c on a.account=c.id"
	
    	" where " ++ SortConditions
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage), 
    Sql.
    
type(new) -> 0;
type(reject) -> 1.

direct(0) -> wsale;
direct(1) -> wreject;
direct(_) -> wsale.


sort_condition(wsale, Merchant, Conditions) ->
    Comment = ?v(<<"comment">>, Conditions),
    CutConditions = lists:keydelete(<<"comment">>, 1, Conditions),
    
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

valid_orgprice(stock, Merchant, Shop, Inventory) ->
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    OrgPrice    = ?v(<<"org_price">>, Inventory),
    EDiscount   = ?v(<<"ediscount">>, Inventory),
    Stock       = ?v(<<"stock">>, Inventory, 0),

    Sql = "select style_number, brand, org_price, ediscount, amount"
	" from w_inventory_new_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(Brand)
	++ " and rsn like \'M-" ++ ?to_s(Merchant) ++ "-S-" ++ ?to_s(Shop) ++ "%\'" 
	++ " order by id desc",

    case ?sql_utils:execute(read, Sql) of
	{ok, StockNews} ->
	    filter_stock(news, StockNews, Stock, OrgPrice, EDiscount);
	_ -> OrgPrice
    end.

filter_stock(news, [], _Stock, OrgPrice, EDiscount) ->
    {OrgPrice, EDiscount};
filter_stock(news, [{H}|T], Stock, OrgPrice, EDiscount) ->
    Amount = ?v(<<"amount">>, H),
    case Stock - Amount =< 0 of
	true -> {?v(<<"org_price">>, H), ?v(<<"ediscount">>, H)};
	false -> filter_stock(news, T, Stock - Amount, OrgPrice, EDiscount)
    end.

sale_new(rsn_groups, MatchMode, Merchant, Conditions, PageFun) ->
    MDiscount = ?v(<<"mdiscount">>, Conditions),
    LDiscount = ?v(<<"ldiscount">>, Conditions),
    LSell     = ?v(<<"lsell">>, Conditions), 
    NewConditions = lists:keydelete(
		      <<"mdiscount">>, 1,
		      lists:keydelete(<<"ldiscount">>, 1,
				      lists:keydelete(<<"lsell">>, 1, Conditions))),
    
    {DConditions, SConditions} = filter_condition(wsale, NewConditions, [], []),

    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions),

    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    "select b.id, b.rsn"
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

	", a.shop as shop_id"
	", a.retailer as retailer_id"
	", a.employ as employee_id"
	", a.type as sell_type"

	", c.name as retailer"

    	" from w_sale_detail b, w_sale a"
	" left join w_retailer c on c.id=a.retailer"

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
    	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end
    	++ PageFun().


pay_order(ShouldPay, [], Pays) when ShouldPay > 0 ->
    [H|T] = Pays,
    lists:reverse([H + ShouldPay|T]);
pay_order(ShouldPay, T, Pays) when ShouldPay =< 0 ->
    NewPays = lists:foldr(fun(_, Acc) -> [0|Acc] end, Pays, T),
    ?DEBUG("new pays ~p", [NewPays]),
    lists:reverse(NewPays);
pay_order(ShouldPay, [Pay|T], Pays) ->
    pay_order(ShouldPay - Pay, T, [case Pay /= 0 andalso ShouldPay - Pay < 0 of
					 true -> ShouldPay;
					 false -> Pay end
				     |Pays]).

pay_order(reject, ShouldPay, [], Pays) when ShouldPay < 0 ->
    [H|T] = Pays,
    lists:reverse([H + ShouldPay|T]);

pay_order(reject, ShouldPay, T, Pays) when ShouldPay >= 0 ->
    NewPays = 
	lists:foldr(
	  fun(_, Acc) -> [0|Acc] end, Pays, T),
    ?DEBUG("new pays ~p", [NewPays]),
    lists:reverse(NewPays);
pay_order(reject, ShouldPay, [Pay|T], Pays) ->
    pay_order(reject, ShouldPay - Pay, T, [case Pay /= 0 andalso ShouldPay - Pay >= 0 of
				       true -> ShouldPay;
				       false -> Pay end
				   |Pays]).


get_modified(NewValue, OldValue) when NewValue =/= OldValue -> NewValue;
get_modified(_NewValue, _OldValue) ->  undefined.


rsn_order(use_id)    -> " order by b.id ";
rsn_order(use_shop)  -> " order by a.shop ";
rsn_order(use_brand) -> " order by b.brand ";
rsn_order(use_firm)  -> " order by b.firm ".
