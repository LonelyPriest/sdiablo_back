%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 10 Feb 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_retailer).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([retailer/2, retailer/3, retailer/4]).
-export([charge/2, charge/3]).
-export([score/2, score/3, ticket/2, ticket/3, get_ticket/3, get_ticket/4, make_ticket/3]).
-export([filter/4, filter/6]).
-export([match/3, syn/2, syn/3, get/2, card/3]).

-define(SERVER, ?MODULE). 

-record(state, {prompt = 0 :: integer()}).

%%%===================================================================
%%% API
%%%===================================================================
retailer(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant, []}).

retailer(list, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant, Conditions});

retailer(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_retailer, Merchant, Attrs});
retailer(delete, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_retailer, Merchant, RetailerId});
retailer(get, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer, Merchant, RetailerId});
retailer(get_batch, Merchant, RetailerIds) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer_batch, Merchant, RetailerIds}); 
retailer(last_recharge, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {last_recharge, Merchant, RetailerId}).
    
retailer(update, Merchant, RetailerId, {Attrs, OldAttrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_retailer, Merchant, RetailerId, {Attrs, OldAttrs}});
retailer(update_score, Merchant, RetailerId, Score) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_score, Merchant, RetailerId, Score});
retailer(check_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_password, Merchant, RetailerId, Password});
retailer(reset_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reset_password, Merchant, RetailerId, Password}).


%% charge strategy
charge(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_charge, Merchant, Attrs});
charge(delete, Merchant, ChargeId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_charge, Merchant, ChargeId});
charge(set_withdraw, Merchant, {DrawId, Conditions}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {set_withdraw, Merchant, {DrawId, Conditions}});

%% recharge of retailer
charge(recharge, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {recharge, Merchant, Attrs});
charge(delete_recharge, Merchant, ChargeId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_recharge, Merchant, ChargeId});

charge(update_recharge, Merchant, {ChargeId, Attrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_recharge, Merchant, {ChargeId, Attrs}});

charge(list_recharge, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_recharge, Merchant, Conditions}).

charge(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_charge, Merchant}).

%% score
score(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_score, Merchant, Attrs}).

score(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_score, Merchant}).

%% ticket
ticket(effect, Merchant, TicketId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {effect_ticket, Merchant, TicketId});
ticket(consume, Merchant, {TicketId, Comment, Score2Money}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {consume_ticket, Merchant, {TicketId, Comment, Score2Money}});
ticket(discard_custom_one, Merchant, TicketId) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {discard_custom_one, Merchant, TicketId}).
ticket(discard_custom_all, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {discard_custom_all, Merchant}).


get_ticket(by_retailer, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_retailer, Merchant, RetailerId});

get_ticket(by_batch, Merchant, {Batch, Mode, Custom}) -> 
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_batch, Merchant, {Batch, Mode, Custom}}).

get_ticket(by_batch, Merchant, Batch, Custom) ->
    get_ticket(by_batch, Merchant, {Batch, ?TICKET_CHECKED, Custom}).


make_ticket(batch, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {make_ticket_batch, Merchant, Attrs}).
    %% Name = ?wpool:get(?MODULE, Merchant), 
    %% gen_server:call(Name, {ticket_by_batch, Merchant, Batch}).

filter(total_retailer, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_retailer, Merchant, Conditions}); 
filter(total_charge_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_charge_detail, Merchant, Conditions});
filter(total_ticket_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_ticket_detail, Merchant, Conditions});
filter(total_custom_ticket_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_custom_ticket_detail, Merchant, Conditions}).


filter({retailer, Order, Sort}, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {{filter_retailer, Order, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(charge_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_charge_detail, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(ticket_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(custom_ticket_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_custom_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}).

%% match
match(phone, Merchant, {Mode, Phone}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {match_phone, Merchant, {Mode, Phone}}).

syn(pinyin, Merchant, Retailers) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {syn_pinyin, Merchant, Retailers}, 30 * 1000).

syn(prompt, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:cast(Name, {syn_prompt, Merchant}).

get(prompt, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_prompt, Merchant}).

card(exist, Merchant, Card) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {is_card_exist, Merchant, Card}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [Name], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([Name]) ->
    [Merchant|_] = lists:reverse(string:tokens(?to_s(Name), "-")),
    Prompt = default_profile(prompt, Merchant),
    {ok, #state{prompt=Prompt}}.

handle_call({new_retailer, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_retailer with attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Card     = ?v(<<"card">>, Attrs, []),
    Pinyin   = ?v(<<"py">>, Attrs, []),
    IDCard   = ?v(<<"id_card">>, Attrs, []),
    Birth    = ?v(<<"birth">>, Attrs),
    Type     = ?v(<<"type">>, Attrs),
    Passwd   = ?v(<<"password">>, Attrs, []), 
    Score    = ?v(<<"score">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),
    Shop     = ?v(<<"shop">>, Attrs, -1),
    
    %% mobile can not be same
    Sql = case Type =:= ?SYSTEM_RETAILER of
	      true -> 
		  "select id, name, mobile, address"
		      ++ " from w_retailer" 
		      ++ " where merchant=" ++ ?to_s(Merchant)
		      ++ " and name = " ++ "\'" ++ ?to_s(Name) ++ "\'" 
		      ++ " and mobile = " ++ "\'" ++ ?to_s(Mobile) ++ "\'"
		      ++ " and deleted = " ++ ?to_s(?NO);
	      false ->
		  "select id, name, mobile, address"
		      ++ " from w_retailer" 
		      ++ " where merchant=" ++ ?to_s(Merchant)
		      ++ " and mobile = " ++ "\'" ++ ?to_s(Mobile) ++ "\'"
		      ++ " and type !=" ++ ?to_s(?SYSTEM_RETAILER) 
		      ++ " and deleted = " ++ ?to_s(?NO)
	  end,

    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    DrawId = default_withdraw(Merchant, Shop, Type),
	    Sql2 = "insert into w_retailer("
		"name, card, py, id_card, birth, type, password, score"
		" ,mobile, address, shop, draw, merchant, entry_date)"
		++ " values (" 
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(Card) ++ "\',"
		++ "\'" ++ ?to_s(Pinyin) ++ "\',"
		++ "\'" ++ ?to_s(IDCard) ++ "\',"
		++ "\'" ++ ?to_s(Birth) ++ "\',"
		++ ?to_s(Type) ++ ","
		++ "\'" ++ ?to_s(Passwd) ++ "\'," 
		++ ?to_s(Score) ++ "," 
		++ "\'" ++ ?to_s(Mobile) ++ "\',"
		++ "\'" ++ ?to_s(Address) ++ "\',"
		++ ?to_s(Shop) ++ ","
		++ ?to_s(DrawId) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')", 
	    Reply = ?sql_utils:execute(insert, Sql2),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(retailer_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_retailer, Merchant, RetailerId, {Attrs, OldAttrs}}, _From, State) ->
    ?DEBUG("update_retailer with merchant ~p, retailerId ~p~nattrs ~p, oldattrs ~p",
	   [Merchant, RetailerId, Attrs, OldAttrs]),

    Name     = ?v(<<"name">>, Attrs),
    Card     = ?v(<<"card">>, Attrs),
    Pinyin   = ?v(<<"py">>, Attrs),
    IDCard   = ?v(<<"id_card">>, Attrs),
    Mobile   = ?v(<<"mobile">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs),
    Birth    = ?v(<<"birth">>, Attrs), 
    Password = ?v(<<"password">>, Attrs), 

    OldShop     = ?v(<<"shop_id">>, OldAttrs),
    OldType     = ?v(<<"type_id">>, OldAttrs),
    OldDrawId   = ?v(<<"draw_id">>, OldAttrs),
    OldBalance  = ?to_f(?v(<<"balance">>, OldAttrs)),

    Balance  = case ?v(<<"balance">>, Attrs) of
		   undefined -> OldBalance;
		   _Balance -> ?to_f(_Balance)
	       end,
    
    Type     = case ?v(<<"type">>, Attrs) of
		   undefined -> OldType;
		   _Type -> _Type
	       end,

   IsMobileModified = 
	case Mobile =:= undefined of
	    true -> {ok, []};
	    false -> 
		Sql = case Type =:= ?SYSTEM_RETAILER of
			  true ->
			      "select id, name, mobile, address"
				  ++ " from w_retailer" 
				  ++ " where merchant=" ++ ?to_s(Merchant)
				  ++ " and name=" ++ "\'" ++ ?to_s(Name) ++ "\'" 
				  ++ " and mobile=" ++ "\'" ++ ?to_s(Mobile) ++ "\'" 
				  ++ " and deleted=" ++ ?to_s(?NO);
			  false ->
			      "select id, name, mobile, address"
				  ++ " from w_retailer" 
				  ++ " where merchant=" ++ ?to_s(Merchant)
				  ++ " and mobile=" ++ "\'" ++ ?to_s(Mobile) ++ "\'"
				  ++ " and type!=" ++ ?to_s(?SYSTEM_RETAILER) 
				  ++ " and deleted=" ++ ?to_s(?NO)
		      end,
		?sql_utils:execute(read, Sql)
	end,

    case IsMobileModified of 
	{ok, []} -> 
	    DrawId = 
		case Type =:= ?CHARGE_RETAILER andalso Type =/= OldType of
		    true -> default_withdraw(Merchant, Shop, Type);
		    false -> OldDrawId
		end,

	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(card, string, Card)
		++ ?utils:v(py, string, Pinyin)
		++ ?utils:v(id_card, string, IDCard)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(shop, integer, ?supplier:get_modified(Shop, OldShop))
		++ ?utils:v(address, string, Address)
		++ ?utils:v(comment, string, Comment)
		++ ?utils:v(birth, string, Birth)
		++ ?utils:v(type, integer, ?supplier:get_modified(Type, OldType)) 
		++ ?utils:v(password, string, Password)
		++ ?utils:v(balance, float, ?supplier:get_modified(Balance, OldBalance))
		++ ?utils:v(draw, integer, ?supplier:get_modified(DrawId, OldDrawId)),

	    Sql1 = "update w_retailer set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant),
	    
	    Reply = 
		case Balance =:= undefined
		    orelse Type =/= ?CHARGE_RETAILER
		    orelse Balance == OldBalance of
		    true -> 
			?sql_utils:execute(write, Sql1, RetailerId);
		    false ->
			Datetime = ?utils:current_time(format_localtime),
			Sqls = [Sql1, "insert into retailer_balance_history("
				"retailer, obalance, nbalance"
				", action, merchant, entry_date) values("
				++ ?to_s(RetailerId) ++ ","
				++ ?to_s(OldBalance) ++ ","
				++ ?to_s(Balance) ++ "," 
				++ ?to_s(?UPDATE_RETAILER) ++ "," 
				++ ?to_s(Merchant) ++ ","
				++ "\"" ++ ?to_s(Datetime) ++ "\")"], 
			?sql_utils:execute(transaction, Sqls, RetailerId)
		end, 
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State}; 
	{ok, _} ->
	    {reply, {error, ?err(retailer_exist, Mobile)}, State};
	Error ->
	    {reply, Error, State}
    end;


handle_call({update_score, Merchant, RetailerId, Score}, _From, State) ->
    Sql = "update w_retailer set score=" ++ ?to_s(Score) ++ ""
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId),

    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    {reply, Reply, State};


handle_call({check_password, Merchant, RetailerId, Password}, _From, State) ->
    Sql = "select id, password, draw from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId)
	++ " and password=\'" ++ ?to_s(Password) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    {reply,
	     {error, ?err(retailer_invalid_password, RetailerId)}, State};
	{ok, R}-> 
	    {reply, {ok, {RetailerId, ?v(<<"draw">>, R)}}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({reset_password, Merchant, RetailerId, Password}, _From, State) ->
    Sql = "update w_retailer set password=\'" ++ ?to_s(Password) ++ "\'"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId),

    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    {reply, Reply, State};


handle_call({get_retailer, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("get_retailer with merchant ~p, retailerId ~p",
	   [Merchant, RetailerId]),
    Sql = "select a.id"
	", a.name"
	", a.card"
	", a.id_card"
	", a.py"
	", a.birth"
	", a.type as type_id"
	", a.balance"
	", a.consume"
	", a.score"
	", a.mobile"
	", a.address"
	", a.shop as shop_id"
	", a.draw as draw_id"
	", a.merchant"
	", a.entry_date" 
	" from w_retailer a where a.id=" ++ ?to_s(RetailerId)
	++ " and a.merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_retailer_batch, Merchant, RetailerIds}, _From, State) ->
    ?DEBUG("get_retailer_batch with merchant ~p, retailerIds ~p",
	   [Merchant, RetailerIds]),
    Sql = "select id, merchant, name, py"
	", shop as shop_id"
	", draw as draw_id"
	", type as type_id"
	", balance, score, mobile"
	" from w_retailer"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, [{<<"id">>, lists:usort(RetailerIds)}]),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({delete_retailer, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("delete_retailer with merchant ~p, retailerId ~p",
	   [Merchant, RetailerId]),
    Sql0 = "select id, retailer from w_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " order by id desc limit 1",
    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, []} ->
	    Sql = "delete from w_retailer where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant), 
	    Reply = ?sql_utils:execute(write, Sql, RetailerId),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
	{ok, _R} ->
	    {reply, {error, ?err(wretailer_retalted_sale, RetailerId)}, State} 
    end;

handle_call({list_retailer, Merchant, Conditions}, _From, State) ->
    ?DEBUG("lookup retail with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions), 
    Month = ?v(<<"month">>, Conditions, []),
    Date  = ?v(<<"date">>, Conditions, []),    
    SortConditions = lists:keydelete(<<"a.month">>, 1, lists:keydelete(<<"a.date">>, 1, NewConditions)),
    
    Sql = "select a.id"
	", a.name"
	", a.card"
	", a.id_card"
	", a.py"
	", a.birth"
	", a.type as type_id"
	", a.balance"
	", a.consume"
	", a.score"
	", a.mobile"
	", a.address"
	", a.shop as shop_id"
	", a.draw as draw_id"
	", a.merchant"
	", a.entry_date"
	", a.comment"

	", b.name as shop"
	
	" from w_retailer a"
	" left join shops b on a.shop=b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ case {Month, Date} of
	       {[], []} -> [];
	       {Month, []} -> 
		   " and month(a.birth)=" ++ ?to_s(Month);
	       {[], Date} ->
		   " and dayofmonth(a.birth)=" ++ ?to_s(Date);
	       {Month, Date} ->
		   " and month(a.birth)=" ++ ?to_s(Month) ++ " and dayofmonth(a.birth)=" ++ ?to_s(Date)
	   end 
	++ ?sql_utils:condition(proplists, ?utils:correct_condition(<<"a.">>, SortConditions))
	++ " order by a.id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% charge
%%
handle_call({new_charge, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_charge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Rule    = ?v(<<"rule">>, Attrs, 0),
    XTime   = ?v(<<"xtime">>, Attrs, 1),

    %% N+1
    Charge  = case Rule of
		  0 -> ?v(<<"charge">>, Attrs, 0);
		  1 -> 0
	      end,
    Balance = case Rule of
		  0 -> ?v(<<"balance">>, Attrs, 0);
		  1 -> 0
	      end,
    Type    = ?v(<<"type">>, Attrs),
    SDate   = ?v(<<"sdate">>, Attrs),
    EDate   = ?v(<<"edate">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs, []),

    Entry    = ?utils:current_time(localtime),
    
    Sql = case Rule of
	      0 -> 
		  "select id, charge, balance from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and charge=" ++ ?to_s(Charge)
		      ++ " and balance=" ++ ?to_s(Balance)
		      ++ " and type=" ++ ?to_s(Type);
	      1 ->
		  %% N+1
		  "select id, charge, balance from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and xtime=" ++ ?to_s(XTime)
		      ++ " and type=" ++ ?to_s(Type)
	  end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_charge(merchant, name"
		", rule, xtime, charge, balance, type"
		", sdate, edate, remark, entry) values("
		++ ?to_s(Merchant) ++ ","
	    %% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Rule) ++ ","
		++ ?to_s(XTime) ++ ","
		++ ?to_s(Charge) ++ ","
		++ ?to_s(Balance) ++ ","
		++ ?to_s(Type) ++ "," 
		++ "\'" ++ ?to_s(SDate) ++ "\',"
		++ "\'" ++ ?to_s(EDate) ++ "\',"
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ "\'" ++ Entry ++ "\')",

	    Reply = ?sql_utils:execute(insert, Sql1),

	    %% case Reply of
	    %% 	{ok, _} -> ?w_user_profile:update(promotion, Merchant);
	    %% 	_ -> error
	    %% end,

	    {reply, Reply, State};
	{ok, E} ->
	    {reply,
	     {error, ?err(retailer_charge_exist, ?v(<<"id">>, E))}, State}
    end;

handle_call({delete_charge, Merchant, ChargeId}, _From, State) ->
    ?DEBUG("delete_charge with merchant ~p, chargeId ~p", [Merchant, ChargeId]), 
    case erlang:is_number(ChargeId) of
	true ->
	    Sql0 = "select id, charge from shops"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and charge=" ++ ?to_s(ChargeId),
	    case ?sql_utils:execute(read, Sql0) of 
		{ok, []} ->
		    Sql = "update w_charge set deleted=1"
			" where id=" ++ ?to_s(ChargeId)
			++ " and merchant=" ++ ?to_s(Merchant),
		    Reply = ?sql_utils:execute(write, Sql, ChargeId),
		    {reply, Reply, State};
		{ok, _Shops} ->
		    {reply, {error, ?err(charge_has_been_used, ChargeId)}, State}
	    end; 
	false ->
	    {reply, {error, ?err(invalid_charge_id, ChargeId)}, State}
    end;

handle_call({set_withdraw, Merchant, {DrawId, Conditions}}, _From, State) ->
    ?DEBUG("set_withdraw with merchant ~p, drawId ~p, condition ~p",
	   [Merchant, DrawId, Conditions]),
    case erlang:is_number(DrawId) of
	true ->
	    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
	    Month = ?v(<<"month">>, Conditions, []),
	    SortConditions = lists:keydelete(<<"month">>, 1, NewConditions),
	    
	    Sql = "update w_retailer set draw=" ++ ?to_s(DrawId)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ case Month of
		       [] -> [];
		       _ -> " and month(a.birth)=" ++ ?to_s(Month)
		   end
		++ ?sql_utils:condition(proplists, SortConditions)
		++ " and type=" ++ ?to_s(?CHARGE_RETAILER) 
		++ " and deleted=" ++ ?to_s(?NO),

	    Reply =  ?sql_utils:execute(write, Sql, Merchant),
	    {reply, Reply, State};
	false ->
	    {reply, {error, ?err(invalid_charge_id, DrawId)}, State}
    end;

handle_call({list_charge, Merchant}, _From, State) ->
    Sql = "select id, name, rule as rule_id, xtime, charge, balance, type, sdate, edate"
	", remark, entry, deleted"
	" from w_charge"
	" where merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(read, Sql),

    {reply, Reply, State};

handle_call({recharge, Merchant, Attrs}, _From, State) ->
    ?DEBUG("recharge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Retailer = ?v(<<"retailer">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    %% CBalance    = ?v(<<"charge_balance">>, Attrs),
    
    Cash     = ?v(<<"cash">>, Attrs, 0),
    Card     = ?v(<<"card">>, Attrs, 0),
    Wxin     = ?v(<<"wxin">>, Attrs, 0),
    CBalance = ?to_i(Cash) + ?to_i(Card) + ?to_i(Wxin), 
    SBalance    = ?v(<<"send_balance">>, Attrs),

    Charge      = ?v(<<"charge">>, Attrs), 
    Comment     = ?v(<<"comment">>, Attrs, []), 
    Entry       = ?utils:current_time(format_localtime),

    Sql0 = "select id, name, mobile, balance, score from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Account} -> 
	    SN = lists:concat(
		   ["M-", ?to_i(Merchant),
		    "-S-", ?to_i(Shop), "-",
		    ?inventory_sn:sn(w_recharge, Merchant)]),

	    CurrentBalance = case ?v(<<"balance">>, Account) of
				 <<>> -> 0;
				 R    -> R
			     end,
	    Score = case ?v(<<"score">>, Account) of
			<<>> -> 0;
			_Score -> _Score
		    end,

	    Mobile = ?v(<<"mobile">>, Account),
	    
	    Sql2 =
		["insert into w_charge_detail(rsn"
		 ", merchant, shop, employ, cid, retailer"
		 ", lbalance, cbalance, sbalance, cash, card, wxin, comment, entry_date) values("
		 ++ "\"" ++ ?to_s(SN) ++ "\","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ "\"" ++ ?to_s(Employee) ++ "\","
		 ++ ?to_s(Charge) ++ "," 
		 ++ ?to_s(Retailer) ++ "," 
		 ++ ?to_s(CurrentBalance) ++ ","
		 ++ ?to_s(CBalance) ++ "," 
		 ++ ?to_s(SBalance) ++ ","
		 ++ ?to_s(Cash) ++ ","
		 ++ ?to_s(Card) ++ ","
		 ++ ?to_s(Wxin) ++ ","
		 ++ "\"" ++ ?to_s(Comment) ++ "\"," 
		 ++ "\"" ++ ?to_s(Entry) ++ "\")",
		 
		 "update w_retailer set balance=balance+"
		 ++ ?to_s(CBalance + SBalance)
		 ++ " where id=" ++ ?to_s(Retailer)],
	    
	    Reply =
		case ?sql_utils:execute(transaction, Sql2, SN) of
		    {ok, SN} ->
			{ok, {SN, Mobile, CBalance, CurrentBalance + CBalance + SBalance, Score}};
		    Error -> Error
		end,
	    %% ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_recharge, Merchant, ChargeId}, _From, State) ->
    Sql0 =
	"select a.id, a.rsn, a.retailer, a.cbalance, a.sbalance"
	", b.balance"
	" from w_charge_detail a, w_retailer b"
	%% " left join w_retailer b on a.retailer=b.id"
	
	" where a.retailer=b.id and a.id=" ++ ?to_s(ChargeId)
	++ " and a.merchant=" ++ ?to_s(Merchant),

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql = "delete from w_charge_detail where id=" ++ ?to_s(ChargeId)
		++ " and merchant=" ++ ?to_s(Merchant),
	    Reply = ?sql_utils:execute(write, Sql, ChargeId),
	    {reply, Reply, State};
	{ok, Charge} ->
	    ?DEBUG("charge ~p", [Charge]),
	    
	    RSN = ?v(<<"rsn">>, Charge),
	    CBalance = ?v(<<"cbalance">>, Charge),
	    SBalance = ?v(<<"sbalance">>, Charge),
	    Retailer = ?v(<<"retailer">>, Charge),
	    OBalance = ?v(<<"balance">>, Charge),
	    Datetime = ?utils:current_time(format_localtime), 
	    Sqls = 
		["delete from w_charge_detail where id=" ++ ?to_s(ChargeId)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update w_charge_detail set lbalance=lbalance-" ++ ?to_s(CBalance + SBalance) 
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and retailer=" ++ ?to_s(Retailer)
		 ++ " and id>" ++ ?to_s(ChargeId),

		 "update w_retailer set balance=balance-" ++ ?to_s(CBalance + SBalance)
		 ++ " where id=" ++ ?to_s(Retailer),

		 "insert into retailer_balance_history("
		 "rsn, retailer, obalance, nbalance"
		 ", action, merchant, entry_date) values("
		 ++ "\'" ++ ?to_s(RSN) ++ "\',"
		 ++ ?to_s(Retailer) ++ ","
		 ++ ?to_s(OBalance) ++ ","
		 ++ ?to_s(OBalance - CBalance - SBalance) ++ "," 
		 ++ ?to_s(?DELETE_RECHARGE) ++ "," 
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"],
	    
	    Reply = ?sql_utils:execute(transaction, Sqls, ChargeId),
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_recharge, Merchant, {ChargeId, Attrs}}, _From, State) ->
    Employee = ?v(<<"employee">>, Attrs),
    Shop = ?v(<<"shop">>, Attrs),
    Comment = ?v(<<"comment">>, Attrs),

    Updates = ?utils:v(employ, string, Employee)
	++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(comment, string, Comment),
    
    Sql0 = "update w_charge_detail set "
	++ ?utils:to_sqls(proplists, comma, Updates) 
	++ " where id=" ++ ?to_s(ChargeId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql0, ChargeId), 
    {reply, Reply, State};

handle_call({list_recharge, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),

    Sql = 
	"select a.id, a.rsn"
	", a.shop as shop_id"
	", a.employ as employee_id"
	", a.cid"
	", a.retailer as retailer_id"
	", a.lbalance, a.cbalance, a.sbalance, a.cash, a.card, a.wxin"
	", a.comment, a.entry_date"
	
	", b.name as retailer, b.mobile"
	", c.name as shop"
	", d.name as cname"
	", e.name as employee"
	
	" from w_charge_detail a"
	" left join w_retailer b on a.retailer=b.id"
	" left join shops c on a.shop=c.id"
	" left join w_charge d on a.cid=d.id"
	" left join employees e on a.employ=e.number and e.merchant=" ++ ?to_s(Merchant)

	++ " where a.merchant=" ++ ?to_s(Merchant) 
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ " order by id desc",
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({last_recharge, Merchant, RetailerId}, _From, State) ->
    Sql = "select a.id, a.rsn"
	", a.shop as shop_id" 
	", a.retailer as retailer_id" 
	" from w_charge_detail a"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " order by id desc limit 1",

    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


%%
%% score
%%
handle_call({new_score, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_charge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Balance = ?v(<<"balance">>, Attrs, 0),
    Score   = ?v(<<"score">>, Attrs, 0),
    Rule    = ?v(<<"rule">>, Attrs),
    SDate   = ?v(<<"sdate">>, Attrs),
    EDate   = ?v(<<"edate">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs, []),

    Entry    = ?utils:current_time(localtime),

    Sql = case Rule of
	      0 ->
		  "select id, balance, score, type from w_score"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and balance=" ++ ?to_s(Balance)
		      ++ " and score=" ++ ?to_s(Score)
		      ++ " and type=" ++ ?to_s(Rule);
	      1 ->
		  "select id, balance, score, type from w_score"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and type=" ++ ?to_s(Rule)
	  end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_score(name, merchant"
		", balance, score, type, sdate, edate, remark"
		", entry) values("
	    %% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Merchant) ++ "," 
		++ ?to_s(Balance) ++ ","
		++ ?to_s(Score) ++ ","
		++ ?to_s(Rule) ++ "," 
		++ "\'" ++ ?to_s(SDate) ++ "\',"
		++ "\'" ++ ?to_s(EDate) ++ "\',"
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ "\'" ++ Entry ++ "\')",

	    Reply = ?sql_utils:execute(insert, Sql1),

	    %% case Reply of
	    %% 	{ok, _} -> ?w_user_profile:update(promotion, Merchant);
	    %% 	_ -> error
	    %% end,

	    {reply, Reply, State};
	{ok, E} ->
	    {reply,
	     case Rule of
		 0 -> {error, ?err(retailer_score_exist, ?v(<<"id">>, E))};
		 1 -> {error, ?err(retailer_score2money_exist, ?v(<<"id">>, E))}
	     end , State}
    end;

handle_call({list_score, Merchant}, _From, State) ->
    Sql = "select id, name, balance, score, type as type_id"
	", sdate, edate, remark, entry"
	" from w_score"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id", 
    Reply = ?sql_utils:execute(read, Sql),

    {reply, Reply, State};

handle_call({effect_ticket, Merchant, TicketId}, _From, State) ->
    Sql = "select id, balance, retailer, state from w_ticket"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(TicketId),

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> ?err(ticket_not_exist, TicketId);
	    {ok, R} ->
		case ?v(<<"state">>, R) =/= 0 of
		    true -> ?err(ticket_has_been_effect, TicketId);
		    false ->
			Sql1 = "update w_ticket set state=1"
			    " where merchant=" ++ ?to_s(Merchant)
			    ++ " and id=" ++ ?to_s(TicketId),
			?sql_utils:execute(write, Sql1, TicketId)
		end
	end,

    {reply, Reply, State};


handle_call({consume_ticket, Merchant, {TicketId, Comment, Score2Money}}, _From, State) ->
    Sql = "select id, balance, retailer, state from w_ticket"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(TicketId),

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> ?err(ticket_not_exist, TicketId);
	    {ok, R} ->
		case ?v(<<"state">>, R) =/= 1 of
		    true ->
			?err(ticket_has_been_consume, TicketId);
		    false ->
			TicketBalance = ?v(<<"balance">>, R, 0),
			RetailerId = ?v(<<"retailer">>, R),
			%% {ok, Scores}=?w_user_profile:get(score, Merchant),
			%% Score2Money =
			%%     case lists:filter(fun({S})-> ?v(<<"type_id">>, S) =:= 1 end, Scores) of
			%% 	[] -> [];
			%% 	[{_Score2Money}] -> _Score2Money
			%%     end, 
			%% ?DEBUG("score2money ~p, ", [Score2Money]),

			AccScore = ?v(<<"score">>, Score2Money), 
			Balance = ?v(<<"balance">>, Score2Money), 
			RetailerScore = TicketBalance div Balance * AccScore,
			
			Sqls = ["update w_ticket set state=2"
				", remark=\'" ++ ?to_s(Comment) ++ "\'"
				" where merchant=" ++ ?to_s(Merchant)
				++ " and id=" ++ ?to_s(TicketId),

				"update w_retailer set score=score-" ++ ?to_s(RetailerScore)
				++ " where merchant=" ++ ?to_s(Merchant)
				++ " and id=" ++ ?to_s(RetailerId)
			       ],
			
			?sql_utils:execute(transaction, Sqls, TicketId)
		end
	end,

    {reply, Reply, State};


handle_call({discard_custom_one, Merchant, TicketId}, _From, State) ->
    Sql = "select id, balance, retailer, state from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(TicketId), 
    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> ?err(ticket_not_exist, TicketId);
	    {ok, _R} ->
		Sql1 = "update w_ticket_custom set state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id=" ++ ?to_s(TicketId)
		    ++ " and state=" ++ ?to_s(?TICKET_STATE_CHECKED),
		?sql_utils:execute(write, Sql1, TicketId)
	end,

    {reply, Reply, State};

handle_call({discard_custom_all, Merchant}, _From, State) -> 
    Sql = "update w_ticket_custom set state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and state=" ++ ?to_s(?TICKET_STATE_CHECKED),
    Reply = ?sql_utils:execute(write, Sql, Merchant), 
    {reply, Reply, State};


handle_call({ticket_by_retailer, Merchant, RetailerId}, _From, State) ->
    Sql = "select id, batch, balance, retailer, sid, state from w_ticket"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " and state=" ++ ?to_s(?CHECKED), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({ticket_by_batch, Merchant, {Batch, Mode, Custom}}, _From, State) ->
    Sql = case Custom of
	      ?CUSTOM_TICKET ->
		  "select id, batch, balance, state from w_ticket_custom";
	      ?SCORE_TICKET ->
		  "select id, batch, balance, retailer, sid, state from w_ticket"
	  end
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and batch=" ++ ?to_s(Batch)
	++ case Mode of
	       ?TICKET_CHECKED -> " and state=" ++ ?to_s(?CHECKED);
	       ?TICKET_ALL -> []
	   end,
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total_retailer, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_retailer: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),

    Month = ?v(<<"month">>, Conditions, []),
    Date  = ?v(<<"date">>, Conditions, []),
    SortConditions = lists:keydelete(<<"month">>, 1, lists:keydelete(<<"date">>, 1, NewConditions)),

    Sql = "select count(*) as total"
	", sum(balance) as balance"
	", sum(consume) as consume"
	", sum(score) as score" 
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ case {Month, Date} of
	       {[], []} -> [];
	       {Month, []} -> 
		   " and month(birth)=" ++ ?to_s(Month);
	       {[], Date} ->
		   " and dayofmonth(birth)=" ++ ?to_s(Date);
	       {Month, Date} ->
		   " and month(birth)=" ++ ?to_s(Month) ++ " and dayofmonth(birth)=" ++ ?to_s(Date)
	   end
	++ ?sql_utils:condition(proplists, SortConditions),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total_charge_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_charge_detail: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	", sum(cbalance) as cbalance"
	", sum(cash) as tcash"
	", sum(card) as tcard"
	", sum(wxin) as twxin"
	", sum(sbalance) as sbalance"
	" from w_charge_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({{filter_retailer, Order, Sort},
	     Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_retailer: order ~p, sort ~p, merchant ~p, conditions ~p, page ~p",
	   [Order, Sort, Merchant, Conditions, CurrentPage]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Month = ?v(<<"month">>, Conditions, []),
    Date  = ?v(<<"date">>, Conditions, []),    
    SortConditions = lists:keydelete(<<"a.month">>, 1, lists:keydelete(<<"a.date">>, 1, NewConditions)),
    
    Sql = "select a.id"
	", a.merchant" 
	", a.name"
	", a.card"
	", a.id_card"
	", a.birth"
	", a.type as type_id"
	", a.balance"
	", a.consume"
	", a.score"
	", a.mobile"
	", a.address"
	", a.shop as shop_id"
	", a.draw as draw_id"
	", a.entry_date"
	", a.comment"

	", b.name as shop_name" 
	" from w_retailer a"
	" left join shops b on a.shop=b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ case {Month, Date} of
	       {[], []} -> [];
	       {Month, []} -> 
		   " and month(a.birth)=" ++ ?to_s(Month);
	       {[], Date} ->
		   " and dayofmonth(a.birth)=" ++ ?to_s(Date);
	       {Month, Date} ->
		   " and month(a.birth)=" ++ ?to_s(Month) ++ " and dayofmonth(a.birth)=" ++ ?to_s(Date)
	   end 
	++ ?sql_utils:condition(proplists, SortConditions)
    %% ++ " and a.deleted=" ++ ?to_s(?NO) 
	++ ?sql_utils:condition(page_desc, {Order, Sort}, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({filter_charge_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_charge_detail: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions), 
    Sql = 
	"select a.id, a.rsn"
	", a.shop as shop_id"
	", a.employ as employee_id"
	", a.cid"
	", a.retailer as retailer_id"
	", a.lbalance, a.cbalance, a.sbalance, a.cash, a.card, a.wxin"
	", a.comment, a.entry_date"
	", b.name as retailer"
	", b.mobile as mobile"
	", c.name as shop"
	" from w_charge_detail a"
	" left join w_retailer b on a.retailer=b.id"
	" left join shops c on a.shop=c.id"

	" where a.merchant=" ++ ?to_s(Merchant) 
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({total_ticket_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_ticket_detail: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	", sum(balance) as balance"
	" from w_ticket"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_ticket_detail: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = 
	"select a.id, a.batch, a.sid, a.balance"
	", a.retailer as retailer_id" 
	", a.state, a.remark, a.entry_date"
	
	", b.name as retailer"
	", b.shop as shop_id"
	", b.mobile"
	", c.name as score"
	
	" from w_ticket a"
	" left join w_retailer b on a.retailer=b.id"
	" left join w_score c on a.sid=c.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_phone, Merchant, {Mode, Phone}}, _From, #state{prompt=Prompt} = State) ->
    ?DEBUG("match_phone: merchant ~p, Mode ~p, Phone ~p, state ~p",
	   [Merchant, Mode, Phone, State]),

    NewPrompt = 
	case Prompt =:= 0 of
	    true -> default_profile(prompt, Merchant);
	    false -> Prompt
	end,
	    
    First = string:substr(?to_s(Phone), 1, 1),
    Last  = string:substr(?to_s(Phone), string:len(?to_s(Phone))),
    Match = string:strip(?to_s(Phone), both, $/),

    Name = case Mode of
	       0 -> "mobile";
	       1 -> "py";
	       2 -> "name";
	       3 -> "card"
	   end,

    Sql = "select id, merchant, name, card, py"
	", shop as shop_id"
	", draw as draw_id"
	", type as type_id"
	", balance, score, mobile"
	" from w_retailer"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and "
	++ case {First, Match, Last} of
	       {"/", Match, "/"} ->
		   Name ++ " =\'" ++ Match ++ "\'"; 
	       {"/", Match, _} ->
		   Name ++ " like \'" ++ Match ++ "%\'";
	       {_, Match, "/"} ->
		   Name ++ " like \'%" ++ Match ++ "\'";
	       {_, Match, _}->
		   Name ++ " like \'%" ++ Match ++ "%\'"
	   end
	++ " limit " ++ ?to_s(NewPrompt),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, case NewPrompt =:= Prompt of
		       true -> State;
		       false ->
			   ?w_user_profile:update(setting, Merchant),
			   State#state{prompt=NewPrompt}
		   end};

handle_call({syn_pinyin, Merchant, Retailers}, _From, State) ->
    ?DEBUG("syn_pinyin with merchant ~p", [Merchant]),
    Sqls = 
	lists:foldr(
	  fun({struct, R}, Acc)->
		  Id     = ?v(<<"id">>, R),
		  Pinyin = ?v(<<"py">>, R, []),
		  ["update w_retailer set py=\'" ++ ?to_s(Pinyin) ++ "\'"
		   " where merchant=" ++ ?to_s(Merchant)
		   ++ " and id=" ++ ?to_s(Id)|Acc]
	  end, [], Retailers),

    ?DEBUG("Sqls ~p", [Sqls]),
    Reply = ?sql_utils:execute(transaction, Sqls, Merchant),
    {reply, Reply, State};


handle_call({get_prompt, _Merchant}, _From, #state{prompt=Prompt} = State) -> 
    {reply, Prompt, State};

handle_call({is_card_exist, Merchant, Card}, _From, State) ->
    Sql = "select id, card, mobile, merchant"
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and card=" ++ ?to_s(Card),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({make_ticket_batch, Merchant, Attrs}, _From, State) ->
    ?DEBUG("make_ticket_batch: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    StartBatch = ?v(<<"sbatch">>, Attrs),
    Count = ?v(<<"count">>, Attrs),
    Balance = ?v(<<"balance">>, Attrs),

    Sql = "select id, batch from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and batch>=" ++ ?to_s(StartBatch)
	++ " limit 1",
    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		%% make
		Datetime = ?utils:current_time(format_localtime),
		Sqls = make_ticket(Merchant, Datetime, Balance, StartBatch, Count, []),
		?DEBUG("sqls ~p", [Sqls]),
		?sql_utils:execute(transaction, Sqls, StartBatch); 
	    {ok, _} ->
		{error, ?err(make_ticket_batch_used, StartBatch)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({total_custom_ticket_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_custom_ticket_detail: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	", sum(balance) as balance"
	" from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_custom_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_ticket_detail: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = 
	"select a.id"
	", a.batch"
	", a.balance"
	", a.retailer as retailer_id" 
	", a.state"
	", a.shop as shop_id"
	", a.remark"
	", a.entry_date"

	", b.name as retailer"
	", b.shop as in_shop_id"
	", b.mobile"
    %% ", c.name as shop" 

	" from w_ticket_custom a"
	" left join w_retailer b on a.retailer=b.id"
    %% " left join shops c on a.shop=c.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast({syn_prompt, Merchant}, State) ->
    Prompt = default_profile(prompt, Merchant),
    {noreply, State#state{prompt=Prompt}};

handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================    
default_profile(prompt, Merchant) -> 
    %% Settings = ?w_user_profile:get(setting, Merchant, -1), 
    {ok, Settings} = ?w_base:setting(list, Merchant, {<<"shop">>, -1}),
    %% ?DEBUG("settings ~p", [Settings]),
    case lists:filter(
	   fun({S}) ->
		   ?v(<<"ename">>, S) =:= <<"prompt">>
	   end, Settings) of
	[] -> 20;
	[{Select}] ->
	    Prompt = ?to_i(?v(<<"value">>, Select, 0)),
	    ?DEBUG("Prompt ~p", [Prompt]),
	    Prompt
    end.


default_withdraw(_Merchant, Shop, _RetailerType) when Shop =:= ?INVALID_OR_EMPTY->
    ?INVALID_OR_EMPTY;
default_withdraw(_Merchant, _Shop, RetailerType) when RetailerType =/= ?CHARGE_RETAILER ->
    ?INVALID_OR_EMPTY; 
default_withdraw(Merchant, Shop, _RetailerType) ->
    case ?w_user_profile:get(shop, Merchant, Shop) of
	{ok, []} -> ?INVALID_OR_EMPTY;
	{ok, [{Draw}]} -> ?v(<<"draw_id">>, Draw)
    end.


make_ticket(_Merchant, _Datetime, _Balance, _StartBatch, 0, Acc) ->
    lists:reverse(Acc);
make_ticket(Merchant, Datetime, Balance, StartBatch, Count, Acc) ->
    Sql = "insert into w_ticket_custom("
	"batch"
	", balance"
	", retailer"
	", state"
	", shop"
	", remark"
	", merchant"
	", entry_date) values("
	++ ?to_s(StartBatch) ++ ","
	++ ?to_s(Balance) ++ ","
	++ ?to_s(-1) ++ ","
	++ ?to_s(?CHECKED) ++ ","
	++ ?to_s(-1) ++ ","
	++ "\'\'" ++ ","
	++ ?to_s(Merchant) ++ ","
	++ "\'" ++ ?to_s(Datetime) ++ "\')",

    make_ticket(Merchant, Datetime, Balance, StartBatch + 1, Count - 1, [Sql|Acc]).
    
    
