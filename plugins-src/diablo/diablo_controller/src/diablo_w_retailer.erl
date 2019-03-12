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

-export([retailer/2, retailer/3, retailer/4, retailer/5, default_profile/2]).
-export([charge/2, charge/3, threshold_card/4, threshold_card_good/3]).
-export([score/2, score/3, ticket/2, ticket/3, get_ticket/3, get_ticket/4, make_ticket/3]).
-export([filter/4, filter/6]).
-export([match/3, syn/2, syn/3, get/2, card/3]).

-define(SERVER, ?MODULE). 

-record(state, {prompt = 0 :: integer()}).

%%%===================================================================
%%% API
%%%===================================================================
retailer(list, Merchant) ->
    retailer(list, Merchant, []); 
retailer(list_sys, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_retailer, Merchant, [{<<"type">>, ?SYSTEM_RETAILER}], []});
retailer(list_level, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer_level, Merchant}).

retailer(list, Merchant, {Conditions, Order}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant, Conditions, Order});
retailer(list, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant, Conditions, []});

retailer(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_retailer, Merchant, Attrs});
retailer(add_level, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {add_retailer_level, Merchant, Attrs});
retailer(update_level, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_retailer_level, Merchant, Attrs});

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
retailer(reset_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reset_password, Merchant, RetailerId, Password}).

retailer(check_password, Merchant, RetailerId, Password, CheckPwd) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_password, Merchant, RetailerId, Password, CheckPwd}).


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
charge(recharge, Merchant, {Attrs, ChargeRule}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {recharge, Merchant, Attrs, ChargeRule});
charge(delete_recharge, Merchant, {RechargeId, RechargeInfo, ChargePromotion}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_recharge, Merchant, RechargeId, RechargeInfo, ChargePromotion});

charge(update_recharge, Merchant, {ChargeId, Attrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_recharge, Merchant, {ChargeId, Attrs}});

charge(list_recharge, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_recharge, Merchant, Conditions});
charge(get_recharge, Merchant, RechargeId) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_recharge, Merchant, RechargeId}).

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
    gen_server:call(Name, {discard_custom_one, Merchant, TicketId});

ticket(new_plan, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_ticket_plan, Merchant, Attrs});
ticket(update_plan, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {update_ticket_plan, Merchant, Attrs});
ticket(gift, Merchant, Tickets) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {gift_ticket, Merchant, Tickets}).

ticket(list_plan, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_ticket_plan, Merchant});

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

%% threshold_card
threshold_card_good(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {add_threshold_card_good, Merchant, Attrs}); 
threshold_card_good(list, Merchant, Shops) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_threshold_card_good, Merchant, Shops}).

threshold_card(threshold_consume, Merchant, Card, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {threshold_card_consume, Merchant, Card, Attrs});
threshold_card(expire_consume, Merchant, Card, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {expire_card_consume, Merchant, Card, Attrs}).

filter(total_retailer, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_retailer, Merchant, Conditions});
filter(total_consume, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_consume, Merchant, Conditions}); 
filter(total_charge_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_charge_detail, Merchant, Conditions});
filter(total_ticket_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_ticket_detail, Merchant, Conditions});
filter(total_custom_ticket_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_custom_ticket_detail, Merchant, Conditions}); 
filter(total_threshold_card, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card, Merchant, Conditions});
filter(total_threshold_card_sale, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card_sale, Merchant, Conditions});
filter(total_threshold_card_good, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card_good, Merchant, Conditions}).


filter({retailer, Order, Sort}, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {{filter_retailer, Order, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(consume, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {filter_consume, Merchant, Conditions, CurrentPage, ItemsPerPage});


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
      Name, {filter_custom_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(threshold_card, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(threshold_card_sale, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card_sale, Merchant, Conditions, CurrentPage, ItemsPerPage}); 
filter(threshold_card_good, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card_good, Merchant, Conditions, CurrentPage, ItemsPerPage}).


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
    Intro    = ?v(<<"intro">>, Attrs, -1),
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
    Level    = case Type =:= ?SYSTEM_RETAILER of
		   true -> -1;
		   false -> ?v(<<"level">>, Attrs, 0)
	       end,
    
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
		"name, intro, level, card, py, id_card, birth, type, password, score"
		" ,mobile, address, shop, draw, merchant, entry_date)"
		++ " values (" 
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Intro) ++ ","
		++ ?to_s(Level) ++ ","
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
	    OkReply =
		case ?sql_utils:execute(insert, Sql2) of
		    {ok, _} = Reply ->
			case Type =:= ?SYSTEM_RETAILER of
			    true ->
				?w_user_profile:update(sysretailer, Merchant),
				Reply;
			    false ->
			        Reply
			end;
		    Reply ->
			Reply
		end,
	    {reply, OkReply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(retailer_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({add_retailer_level, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_retailer_level with attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Level    = ?v(<<"level">>, Attrs),
    Score    = ?v(<<"score">>, Attrs, 0),
    Discount = ?v(<<"discount">>, Attrs, 100),

    Sql = "select id, name, level from w_retailer_level"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop) 
	++ " and level=" ++ ?to_s(Level),
    
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    Sql2 = "insert into w_retailer_level("
		"shop, name, level, score, discount, Merchant)"
		++ " values ("
		++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(Level) ++ "\'," 
		++ ?to_s(Score) ++ ","
		++ ?to_s(Discount) ++ "," 
		++ ?to_s(Merchant) ++ ")",
	    Reply = ?sql_utils:execute(insert, Sql2),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(retailer_level_exist, Level)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_retailer_level, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_retailer_level with attrs ~p", [Attrs]),
    Shop     = ?v(<<"shop">>, Attrs),
    Level    = ?v(<<"level">>, Attrs, -1),
    Score    = ?v(<<"score">>, Attrs),
    Discount = ?v(<<"discount">>, Attrs),

    Sql = "select id, name, level from w_retailer_level"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Level),
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    {reply, {error, ?err(retailer_level_not_exist, Level)}, State};
	{ok, _Any} ->
	    Updates = ?utils:v(shop, integer, Shop)
		++ ?utils:v(score, integer, Score)
		++ ?utils:v(discount, integer, Discount),
	    Sql1 = "update w_retailer_level set " ++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where merchant="  ++ ?to_s(Merchant)
		++ " and id=" ++ ?to_s(Level),
	    Reply = ?sql_utils:execute(write, Sql1, Level),
	    {reply, Reply, State}; 
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_retailer, Merchant, RetailerId, {Attrs, OldAttrs}}, _From, State) ->
    ?DEBUG("update_retailer with merchant ~p, retailerId ~p~nattrs ~p, oldattrs ~p",
	   [Merchant, RetailerId, Attrs, OldAttrs]),

    Name     = ?v(<<"name">>, Attrs),
    Intro    = ?v(<<"intro">>, Attrs),
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
    OldLevel    = ?v(<<"level">>, OldAttrs),
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
    
    Level    = ?v(<<"level">>, Attrs, OldLevel),

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
		++ ?utils:v(intro, integer, Intro)
		++ ?utils:v(card, string, Card)
		++ ?utils:v(py, string, Pinyin)
		++ ?utils:v(id_card, string, IDCard)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(shop, integer, ?supplier:get_modified(Shop, OldShop))
		++ ?utils:v(address, string, Address)
		++ ?utils:v(comment, string, Comment)
		++ ?utils:v(birth, string, Birth)
		++ ?utils:v(type, integer, ?supplier:get_modified(Type, OldType))
		++ ?utils:v(level, integer, ?supplier:get_modified(Level, OldLevel))
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
	    
	    case ?supplier:get_modified(Type, OldType) of
		?SYSTEM_RETAILER -> 
		    ?w_user_profile:update(sysretailer, Merchant);
		_ ->
		    none
	    end,
	    
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


handle_call({check_password, Merchant, RetailerId, Password, CheckPwd}, _From, State) ->
    Sql = "select id, password, draw from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId)
	++ case CheckPwd of
	       ?YES -> " and password=\'" ++ ?to_s(Password) ++ "\'";
	       ?NO -> []
	   end
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
	", a.intro as intro_id"
	", a.level"
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
    ?DEBUG("get_retailer_batch with merchant ~p, retailerIds ~p", [Merchant, RetailerIds]),
    Sql = "select id"
	", merchant"
	", name"
	", intro as intro_id"
	", level"
	", py"
	", birth"
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
    ?DEBUG("delete_retailer with merchant ~p, retailerId ~p", [Merchant, RetailerId]),
    Sql0 = "select id, retailer from w_sale where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " order by id desc limit 1",
    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, []} ->
	    Sql1 = "select id, retailer from w_charge_detail where merchant=" ++ ?to_s(Merchant)
		++ " and retailer=" ++ ?to_s(RetailerId)
		++ " order by id desc limit 1",
	    case ?sql_utils:execute(s_read, Sql1) of
		{ok, []} -> 
		    Sql = "delete from w_retailer where id=" ++ ?to_s(RetailerId)
			++ " and merchant=" ++ ?to_s(Merchant), 
		    Reply = ?sql_utils:execute(write, Sql, RetailerId),
		    {reply, Reply, State}; 
		{ok, _R0} ->
		    {reply, {error, ?err(wretailer_retalted_sale, RetailerId)}, State};
		Error0 ->
		    {reply, Error0, State}
	    end;
	{ok, _R} ->
	    {reply, {error, ?err(wretailer_retalted_sale, RetailerId)}, State} ;
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_retailer_level, Merchant}, _From, State) ->
    ?DEBUG("list_retailer_level with merchant ~p", [Merchant]),
    Sql = "select id"
	", name"
	", level"
	", score"
	", discount"
	", shop as shop_id"
	" from w_retailer_level"
	" where merchant=" ++ ?to_s(Merchant),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_retailer, Merchant, Conditions, Mode}, _From, State) ->
    ?DEBUG("lookup retail with merchant ~p, Conditions ~p, Sort ~p", [Merchant, Conditions, Mode]),
    
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions), 
    Month = ?v(<<"month">>, Conditions, []),
    Date  = ?v(<<"date">>, Conditions, []),    
    SortConditions = lists:keydelete(<<"a.month">>, 1, lists:keydelete(<<"a.date">>, 1, NewConditions)),
    
    Sql = "select a.id"
	", a.name"
	", a.intro as intro_id"
	", a.level"
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
	++ ?sql_utils:condition(proplists, SortConditions)
	++ case Mode of
	       [] -> [];
	       _ ->
		   ?sql_utils:mode(Mode, 0)
	   end,

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% charge
%%
handle_call({new_charge, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_charge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Rule    = ?v(<<"rule">>, Attrs, -1),
    XTime   = ?v(<<"xtime">>, Attrs, 0),
    XDiscount = ?v(<<"xdiscount">>, Attrs, 100),
    CTime   = ?v(<<"ctime">>, Attrs, 0),

    %% N
    {Charge, Balance}  =
	case Rule =:= 0 of
	    true -> {?v(<<"charge">>, Attrs, 0), ?v(<<"balance">>, Attrs, 0)};
	    _ -> {0, 0}
	end,
    
    Type    = ?v(<<"type">>, Attrs),
    SDate   = ?v(<<"sdate">>, Attrs),
    EDate   = ?v(<<"edate">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs, []),

    Entry    = ?utils:current_time(localtime),
    
    Sql = case Rule of
	      ?GIVING_CHARGE -> 
		  "select id, charge, balance from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and charge=" ++ ?to_s(Charge)
		      ++ " and balance=" ++ ?to_s(Balance)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and type=" ++ ?to_s(Type);
	      ?TIMES_CHARGE ->
		  %% N
		  "select id, xtime from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and xtime=" ++ ?to_s(XTime)
		      ++ " and xdiscount=" ++ ?to_s(XDiscount)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and type=" ++ ?to_s(Type);
	      ?THEORETIC_CHARGE ->
		  %% time consume
		  "select id, ctime from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and ctime=" ++ ?to_s(CTime)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'";
	      ?MONTH_UNLIMIT_CHARGE ->
		  "select id, name from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'";
	      ?QUARTER_UNLIMIT_CHARGE ->
		  "select id, name from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'";
	      ?YEAR_UNLIMIT_CHARGE ->
		  "select id, name from w_charge"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'";
	      ?HALF_YEAR_UNLIMIT_CHARGE ->
		  "select id, name from w_charge" 
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'"
	  end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_charge(merchant, name"
		", rule, xtime, xdiscount, ctime, charge, balance, type"
		", sdate, edate, remark, entry) values("
		++ ?to_s(Merchant) ++ ","
	    %% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Rule) ++ ","
		++ ?to_s(XTime) ++ ","
		++ ?to_s(XDiscount) ++ ","
		++ ?to_s(CTime) ++ ","
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
    Sql = "select id"
	", name"
	", rule as rule_id"
	", xtime"
	", xdiscount"
	", ctime"
	", charge"
	", balance"
	", type"
	", sdate"
	", edate"
	", remark"
	", entry"
	", deleted"
	" from w_charge"
	" where merchant=" ++ ?to_s(Merchant)
	++ " order by id desc",
    

    Reply = ?sql_utils:execute(read, Sql),

    {reply, Reply, State};

handle_call({recharge, Merchant, Attrs, ChargeRule}, _From, State) ->
    ?DEBUG("recharge with merchant ~p, paylaod ~p, ChargeRule ~p", [Merchant, Attrs, ChargeRule]),

    Retailer = ?v(<<"retailer">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    %% CBalance    = ?v(<<"charge_balance">>, Attrs),
    
    Cash     = ?v(<<"cash">>, Attrs, 0),
    Card     = ?v(<<"card">>, Attrs, 0),
    Wxin     = ?v(<<"wxin">>, Attrs, 0),
    CBalance = ?to_i(Cash) + ?to_i(Card) + ?to_i(Wxin), 
    SBalance    = ?v(<<"send_balance">>, Attrs, 0),

    ChargeId    = ?v(<<"charge">>, Attrs),
    Stock       = ?v(<<"stock">>, Attrs, []),
    Comment     = ?v(<<"comment">>, Attrs, []), 
    Entry       = ?utils:current_time(format_localtime),

    
    %% ?DEBUG("Charge ~p", [Charge]),
    Sql0 = "select id, name, mobile, balance, score from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Account} -> 
	    SN = lists:concat(
		   ["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-", ?inventory_sn:sn(w_recharge, Merchant)]),

	    CurrentBalance = case ?v(<<"balance">>, Account) of
				 <<>> -> 0;
				 R    -> R
			     end,
	    Score = case ?v(<<"score">>, Account) of
			<<>> -> 0;
			_Score -> _Score
		    end, 
	    Mobile = ?v(<<"mobile">>, Account),

	    RechargeDetailSql =
		fun(EndDate) ->
			"insert into w_charge_detail(rsn"
			    ", merchant, shop, employ, cid, retailer"
			    ", ledate, lbalance, cbalance, sbalance"
			    ", cash, card, wxin, stock, comment, entry_date) values("
			    ++ "\'" ++ ?to_s(SN) ++ "\',"
			    ++ ?to_s(Merchant) ++ ","
			    ++ ?to_s(Shop) ++ ","
			    ++ "\'" ++ ?to_s(Employee) ++ "\',"
			    ++ ?to_s(ChargeId) ++ "," 
			    ++ ?to_s(Retailer) ++ ","
			    ++ "\'" ++ format_date(EndDate) ++ "\',"
			    ++ ?to_s(CurrentBalance) ++ ","
			    ++ ?to_s(CBalance) ++ "," 
			    ++ ?to_s(SBalance) ++ ","
			    ++ ?to_s(Cash) ++ ","
			    ++ ?to_s(Card) ++ ","
			    ++ ?to_s(Wxin) ++ ","
			    ++ "\'" ++ ?to_s(Stock) ++ "\',"
			    ++ "\'" ++ ?to_s(Comment) ++ "\'," 
			    ++ "\'" ++ ?to_s(Entry) ++ "\')"
		end,

	    Rule = ?v(<<"rule_id">>, ChargeRule, -1),
	    case Rule =:= ?GIVING_CHARGE orelse Rule =:= ?TIMES_CHARGE of
		true -> 
		    Sql2 = [RechargeDetailSql(?INVALID_DATE),
			    "update w_retailer set balance=balance+"
			    ++ ?to_s(CBalance + SBalance) ++ " where id=" ++ ?to_s(Retailer)], 
		    Reply =
			case ?sql_utils:execute(transaction, Sql2, SN) of
			    {ok, SN} ->
				{ok, {SN, Mobile, CBalance, CurrentBalance + CBalance + SBalance, Score}};
			    Error -> Error
			end,
		    %% ?w_user_profile:update(retailer, Merchant),
		    {reply, Reply, State};
		false  ->
		    CTime       = ?v(<<"ctime">>, Attrs, -1),
		    StartDate   = ?v(<<"stime">>, Attrs, ?INVALID_DATE),

		    Sql01 = "select id, retailer, ctime, edate, cid, rule from w_card"
			" where merchant=" ++ ?to_s(Merchant)
			++ " and retailer=" ++ ?to_s(Retailer)
			++ " and cid=" ++ ?to_s(ChargeId),

		    Sql22 = 
			case ?sql_utils:execute(s_read, Sql01) of 
			    {ok, []} ->
				{Year, Month, Date} =
				    case Rule of
					?THEORETIC_CHARGE -> ?INVALID_DATE;
					_ ->
					    ?utils:big_date(date, current_date(), StartDate)
				    end,

				EndDate = 
				    case Rule of
					?THEORETIC_CHARGE ->
					    ?INVALID_DATE;
					?MONTH_UNLIMIT_CHARGE ->
					    date_next(?MONTH_UNLIMIT_CHARGE, {Year, Month, Date});
					?QUARTER_UNLIMIT_CHARGE ->
					    date_next(?QUARTER_UNLIMIT_CHARGE, {Year, Month, Date});
					?YEAR_UNLIMIT_CHARGE ->
					    date_next(?YEAR_UNLIMIT_CHARGE, {Year, Month, Date});
					?HALF_YEAR_UNLIMIT_CHARGE ->
					    date_next(?HALF_YEAR_UNLIMIT_CHARGE, {Year, Month, Date})
				    end, 

				[case Rule of
				     ?THEORETIC_CHARGE -> RechargeDetailSql(?INVALID_DATE);
				     _ ->
					 %% must not to use at current day
					 RechargeDetailSql(?utils:date_before({Year, Month, Date}, 1))
				 end,
				 "insert into w_card(retailer"
				 ", ctime, sdate, edate, cid, rule, merchant, shop, entry_date) values("
				 ++ ?to_s(Retailer) ++ ","
				 ++ ?to_s(CTime) ++ ","
				 ++ "\'" ++ format_date(Year, Month, Date) ++ "\',"
				 ++ "\'" ++ format_date(EndDate) ++ "\',"
				 ++ ?to_s(ChargeId) ++ ","
				 ++ ?to_s(Rule) ++ ","
				 ++ ?to_s(Merchant) ++ ","
				 ++ ?to_s(Shop) ++ ","
				 ++ "\'" ++ ?to_s(Entry) ++ "\')"];
			    {ok, OCard} ->
				EndDate = ?v(<<"edate">>, OCard, ?INVALID_DATE), 
				%% {Year, Month, Date} = ?utils:to_date(date, EndDate),
				{Year, Month, Date} =
				    case Rule of
					?THEORETIC_CHARGE -> ?INVALID_DATE;
					_ ->
					    ?utils:big_date(date, StartDate, EndDate)
				    end,

				[case Rule of
				     ?THEORETIC_CHARGE -> RechargeDetailSql(?INVALID_DATE);
				     _ -> RechargeDetailSql(?utils:to_date(date, EndDate))
				 end, 
				 case Rule of
				     ?THEORETIC_CHARGE ->
					 "update w_card set ctime=ctime+" ++ ?to_s(CTime);
				     ?MONTH_UNLIMIT_CHARGE ->
					 NextMonth = date_next(?MONTH_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextMonth) ++ "\'"; 
				     ?QUARTER_UNLIMIT_CHARGE ->
					 NextQuarter =
					     date_next(?QUARTER_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextQuarter);
				     ?YEAR_UNLIMIT_CHARGE ->
					 NextYear = date_next(?YEAR_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextYear)
				 end ++ 
				     case Rule of
					 ?THEORETIC_CHARGE -> [];
					 _ ->
					     case ?utils:compare_date(date, StartDate, EndDate) of 
						 true ->
						     ", sdate=\'" ++ ?to_s(StartDate) ++ "\'";
						 false -> []
					     end
				     end
				 ++ " where id=" ++ ?to_s(?v(<<"id">>, OCard))]
			end,

		    Reply =
			case ?sql_utils:execute(transaction, Sql22, SN) of
			    {ok, SN} ->
				{ok, {SN, Mobile, CBalance, CurrentBalance, Score}};
			    Error -> Error
			end,
		    %% ?w_user_profile:update(retailer, Merchant),
		    {reply, Reply, State}
	    end; 
	Error ->
	    {reply, Error, State}
    end; 

handle_call({delete_recharge, Merchant, RechargeId, RechargeInfo, ChargePromotion}, _From, State) ->
    ?DEBUG("delete_recharge: merchant ~p, RechargeId ~p, RechargeInfo ~p, ChargePromotion ~p",
	   [Merchant, RechargeId, RechargeInfo, ChargePromotion]), 
    Sql1 = "delete from w_charge_detail where id=" ++ ?to_s(RechargeId)
	++ " and merchant=" ++ ?to_s(Merchant),

    case RechargeInfo of
	[] -> 
	    Reply = ?sql_utils:execute(write, Sql1, RechargeId),
	    {reply, Reply, State};
	_ ->
	    RetailerId = ?v(<<"retailer">>, RechargeInfo), 
	    Rule = ?v(<<"rule_id">>, ChargePromotion),
	    case Rule =:= ?GIVING_CHARGE orelse Rule =:= ?TIMES_CHARGE of
		true -> 
		    RSN      = ?v(<<"rsn">>, RechargeInfo),
		    CBalance = ?v(<<"cbalance">>, RechargeInfo),
		    SBalance = ?v(<<"sbalance">>, RechargeInfo),
		    %% Retailer = ?v(<<"retailer">>, RechargeInfo),
		    OBalance = ?v(<<"balance">>, RechargeInfo),
		    Datetime = ?utils:current_time(format_localtime), 
		    Sqls = 
			[Sql1, 
			 "update w_charge_detail set lbalance=lbalance-" ++ ?to_s(CBalance + SBalance) 
			 ++ " where merchant=" ++ ?to_s(Merchant)
			 ++ " and retailer=" ++ ?to_s(RetailerId)
			 ++ " and id>" ++ ?to_s(RechargeId),

			 "update w_retailer set balance=balance-" ++ ?to_s(CBalance + SBalance)
			 ++ " where id=" ++ ?to_s(RetailerId)
			 ++ " and merchant=" ++ ?to_s(Merchant),

			 "insert into retailer_balance_history("
			 "rsn, retailer, obalance, nbalance"
			 ", action, merchant, entry_date) values("
			 ++ "\'" ++ ?to_s(RSN) ++ "\',"
			 ++ ?to_s(RetailerId) ++ ","
			 ++ ?to_s(OBalance) ++ ","
			 ++ ?to_s(OBalance - CBalance - SBalance) ++ "," 
			 ++ ?to_s(?DELETE_RECHARGE) ++ "," 
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(Datetime) ++ "\")"], 
		    Reply = ?sql_utils:execute(transaction, Sqls, RechargeId),
		    {reply, Reply, State} ;
		false ->
		    ChargeId = ?v(<<"cid">>, RechargeInfo), 
		    case Rule of
			?THEORETIC_CHARGE ->
			    CTime = ?v(<<"ctime">>, ChargePromotion), 
			    Sqls = ["update w_card set ctime=ctime-" ++ ?to_s(CTime)
				    ++ " where merchant=" ++ ?to_s(Merchant)
				    ++ " and retailer=" ++ ?to_s(RetailerId)
				    ++ " and cid=" ++ ?to_s(ChargeId), Sql1],
			    Reply = ?sql_utils:execute(transaction, Sqls, RechargeId),
			    {reply, Reply, State};
			_ ->
			    EndDate = ?v(<<"ledate">>, RechargeInfo),
			    Sqls = ["update w_card set edate=\'" ++ ?to_s(EndDate) ++ "\'"
				    ++ " where merchant=" ++ ?to_s(Merchant)
				    ++ " and retailer=" ++ ?to_s(RetailerId)
				    ++ " and cid=" ++ ?to_s(ChargeId), Sql1],
			    Reply = ?sql_utils:execute(transaction, Sqls, RechargeId),
			    {reply, Reply, State} 
		    end
	    end
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

handle_call({get_recharge, Merchant, RechargeId}, _From, State) ->
    Sql = "select a.id, a.rsn, a.retailer, a.cid, a.ledate, a.cbalance, a.sbalance"
	", b.balance"
	" from w_charge_detail a, w_retailer b"
	" where a.retailer=b.id and a.id=" ++ ?to_s(RechargeId)
	++ " and a.merchant=" ++ ?to_s(Merchant), 
    Reply =  ?sql_utils:execute(s_read, Sql),
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

    %% Sql = case Rule of
    %% 	      0 ->
    %% 		  "select id, balance, score, type from w_score"
    %% 		      " where merchant=" ++ ?to_s(Merchant)
    %% 		      ++ " and balance=" ++ ?to_s(Balance)
    %% 		      ++ " and score=" ++ ?to_s(Score)
    %% 		      ++ " and type=" ++ ?to_s(Rule);
    %% 	      1 ->
    %% 		  "select id, balance, score, type from w_score"
    %% 		      " where merchant=" ++ ?to_s(Merchant)
    %% 		      ++ " and type=" ++ ?to_s(Rule)
    %% 	  end,

    Sql = "select id, balance, score, type from w_score"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and balance=" ++ ?to_s(Balance)
	++ " and score=" ++ ?to_s(Score)
	++ " and type=" ++ ?to_s(Rule),

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

handle_call({new_ticket_plan, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_ticket_plan: merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name    = ?v(<<"name">>, Attrs),
    Balance = ?v(<<"balance">>, Attrs),
    Effect  = ?v(<<"effect">>, Attrs, 0),
    Expire  = ?v(<<"expire">>, Attrs, 0),
    MaxSend = ?v(<<"scount">>, Attrs, 1),
    Remark  = ?v(<<"remark">>, Attrs, []),
    Entry   = ?utils:current_time(format_localtime), 
    %% balacen should be unique
    Sql = "select id, name, balance from w_ticket_plan"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and balance=" ++ ?to_s(Balance),
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_ticket_plan("
		"name"
		", balance"
		", effect"
		", expire"
		", scount"
		", remark"
		", merchant"
		", entry_date) values("
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Balance) ++ ","
		++ ?to_s(Effect) ++ ","
		++ ?to_s(Expire) ++ ","
		++ ?to_s(MaxSend) ++ ","
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Entry) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, ?err(ticket_plan_exist, Name), State}
    end;

handle_call({update_ticket_plan, Merchant, Attrs}, _From, State) ->
    Id      = ?v(<<"plan">>, Attrs),
    Name    = ?v(<<"name">>, Attrs),
    Balance = ?v(<<"balance">>, Attrs),
    Effect  = ?v(<<"effect">>, Attrs ),
    Expire  = ?v(<<"expire">>, Attrs),
    MaxSend = ?v(<<"scount">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(balance, integer, Balance)
	++ ?utils:v(effect, integer, Effect)
	++ ?utils:v(expire, integer, Expire)
	++ ?utils:v(scount, integer, MaxSend)
	++ ?utils:v(remark, string, Remark),

    UpdateFun =
	fun() ->
		Sql1 = "update w_ticket_plan set " ++ ?utils:to_sqls(proplists, comma, Updates)
		    ++ " where merchant="  ++ ?to_s(Merchant)
		    ++ " and id=" ++ ?to_s(Id),
		Reply = ?sql_utils:execute(write, Sql1, Id),
		{reply, Reply, State}
	end,
		   
    case Balance of
	undefined ->
	    UpdateFun();
	_ ->
	    Sql = "select id, name, balance from w_ticket_plan"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and balance=" ++ ?to_s(Balance),
	    case ?sql_utils:execute(s_read, Sql) of
		{ok, []} ->
		    UpdateFun();
		{ok, _} ->
		    {reply, ?err(ticket_plan_exist, Id), State}
	    end
    end;

handle_call({gift_ticket, Merchant, Tickets}, _From, State) ->
    ?DEBUG("gift_ticket: merchant ~p, tickets ~p", [Merchant, Tickets]),
    {reply, ok, State};

handle_call({list_ticket_plan, Merchant}, _From, State) ->
    Sql = "select id, merchant, name, balance, effect, expire, scount, entry_date"
	" from w_ticket_plan where merchant=" ++ ?to_s(Merchant),
    {reply, ?sql_utils:execute(read, Sql), State};

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


handle_call({total_consume, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_consume: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    FilterConditions = filter_condition(consume, NewConditions),
    SortCondtions = sort_condition(consume, NewConditions),

    Sql = "select count(*) as total" 
	" from "
	" (select a.retailer, a.shop, a.consume"
	" from "
	"(select merchant"
	", retailer"
	", shop, SUM(should_pay - verificate) as consume from w_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, FilterConditions)
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
	++ " group by retailer, shop) a"
	++ case SortCondtions of
	    [] -> [];
	    _ -> " where " ++ SortCondtions
	end ++ ") b",
    
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
	", a.intro as intro_id"
	", a.level"
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
	", c.name as intro_name"
	
	" from w_retailer a"
	" left join shops b on a.shop=b.id"
	" left join (select id, name, merchant from w_retailer where merchant="
	++ ?to_s(Merchant) ++ ") c on a.intro=c.id"
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


handle_call({filter_consume, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_consume:merchant ~p, conditions ~p, page ~p", [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    FilterConditions = filter_condition(consume, NewConditions),
    SortCondtions = sort_condition(consume, NewConditions, <<"a.">>),
    
    Sql = "select a.retailer_id"
	", a.total"
	", a.score"
	", a.consume"
	", a.draw"
	", a.ticket"

	", b.name as retailer"
	", b.shop as shop_id"
	", b.mobile as phone"
	", b.balance"
	
	" from ("
	"select retailer as retailer_id"
	", shop as shop_id"
	", SUM(total) as total"
	", SUM(score) as score"
	", SUM(should_pay - verificate) as consume"
	", SUM(withDraw) as draw"
	", SUM(ticket) as ticket" 
	" from w_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, FilterConditions)
    %% ++ SortCondtions
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
	++ " group by retailer, shop) a"

	++ " left join w_retailer b on a.retailer_id=b.id"
    %%++ " left join shops c on a.shop_id=c.id"
	++ case SortCondtions of
	       [] -> [];
	       _ -> " where " ++ SortCondtions
	   end
	++ ?sql_utils:condition(page_desc, {use_consume, 0}, CurrentPage, ItemsPerPage),

    
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
	", a.ledate, a.lbalance"
	", a.cbalance, a.sbalance, a.cash, a.card, a.wxin"
	", a.stock" 
	", a.comment"
	", a.entry_date"
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

    Sql = "select id"
	", merchant"
	", name"
	", birth"
	", level"
	", card"
	", py"
	", shop as shop_id"
	", draw as draw_id"
	", type as type_id"
	", balance"
	", score"
	", mobile"
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
    Count      = ?v(<<"count">>, Attrs),
    Balance    = ?v(<<"balance">>, Attrs),
    Plan       = ?v(<<"plan">>, Attrs, ?INVALID_OR_EMPTY),

    Sql = "select id, batch from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and batch>=" ++ ?to_s(StartBatch)
	++ " limit 1",
    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		%% make
		Datetime = ?utils:current_time(format_localtime),
		Sqls = make_ticket(Merchant, Datetime, Balance, StartBatch, Plan, Count, []),
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
	", a.plan as plan_id"
	", a.balance"
	", a.retailer as retailer_id" 
	", a.state"
	", a.stime"
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

handle_call({total_threshold_card, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_threshold_card: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_, _, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	" from w_card"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions),
	
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


handle_call({filter_threshold_card, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_threshold_card: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {_, _, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = 
	"select a.id" 
	", a.retailer as retailer_id" 
	", a.ctime"
	", a.sdate"
	", a.edate"
	", a.cid"
	", a.rule as rule_id"
	", a.shop as shop_id"
	", a.entry_date"

	", b.name as retailer"
	", b.mobile"

	", c.name as cname"
	
    %% ", c.name as shop" 

	" from w_card a"
	" left join w_retailer b on a.retailer=b.id"
	" left join w_charge c on a.cid=c.id"
    %% " left join shops c on a.shop=c.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% threshold card good
handle_call({list_threshold_card_good, Merchant, Shops}, _From, State) ->
    Sql = "select id, name, tag_price, shop as shop_id from w_card_good"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Shops),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_threshold_card_sale, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_threshold_card_sale: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	", sum(amount) as amount"
	" from w_card_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


handle_call({filter_threshold_card_sale, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_threshold_card_sale: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = 
	"select a.id"
	", a.rsn"
	", a.employee as employee_id"
	", a.retailer as retailer_id" 
	", a.card as card_id"
	", a.amount"
	", a.cgood as cgood_id"
	", a.tag_price"
	", a.shop as shop_id"
	", a.comment" 
	", a.entry_date"

	", b.name as retailer"
	", b.mobile"

	", c.rule as rule_id"
	
	", d.name as cname"

	" from w_card_sale a"
	" left join w_retailer b on a.retailer=b.id"
	" left join w_card c on a.card=c.id"
	" left join w_charge d on a.cid=d.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
    
handle_call({add_threshold_card_good, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_threshold_card_good: merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name = ?v(<<"name">>, Attrs),
    Shop = ?v(<<"shop">>, Attrs),
    TagPrice = ?v(<<"price">>, Attrs),
    CurrentTime = ?utils:current_time(format_localtime),

    case Name =:= undefined orelse Shop =:= undefined orelse TagPrice =:= undefined of
	true ->
	    {reply, {error, ?err(params_error, "add_threshold_card_good")}, State};
	false ->
	    Sql0 = "select id, name from w_card_good where merchant=" ++ ?to_s(Merchant)
		++ " and name=\'" ++ ?to_s(Name) ++ "\'"
		++ " and shop=" ++ ?to_s(Shop),

	    case ?sql_utils:execute(s_read, Sql0) of
		{ok, []} ->
		    Sql = "insert into w_card_good(name, tag_price, merchant, shop, entry_date) values("
			++ "\'" ++ ?to_s(Name) ++ "\',"
			++ ?to_s(TagPrice) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ "\'" ++ ?to_s(CurrentTime) ++ "\')",
		    Reply = ?sql_utils:execute(insert, Sql),
		    {reply, Reply, State};
		{ok, _Good} ->
		    {reply, {error, ?err(threshold_card_good_exist, Name)}, State};
		Error ->
		    {reply, Error, State}
	    end
    end;

handle_call({total_threshold_card_good, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_threshold_card_good: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_, _, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	" from w_card_good"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_threshold_card_good, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_threshold_card_good: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    {_, _, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = 
	"select a.id" 
	", a.name" 
	", a.tag_price"
	", a.shop" 
	", a.entry_date" 
	", b.name as shop"

	" from w_card_good a"
	" left join shops b on a.shop=b.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({threshold_card_consume, Merchant, CardId, Attrs}, _From, State) ->
    ?DEBUG("threshold_card_consume: merchant ~p, card ~p, attrs ~p", [Merchant, CardId, Attrs]),
    CGood = ?v(<<"cgood">>, Attrs), 
    Count = ?v(<<"count">>, Attrs),
    ChargeId = ?v(<<"charge">>, Attrs),
    Retailer = ?v(<<"retailer">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    Price    = ?v(<<"tag_price">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),
    
    Sql = "select id, merchant, retailer, rule, ctime from w_card"
	" where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and cid=" ++ ?to_s(ChargeId),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    {reply, {error, ?err(threshold_card_not_exist, CardId)}, State};
	{ok, Card} ->
	    LeftCount = ?v(<<"ctime">>, Card, 0),
	    case LeftCount < Count of
		true ->
		    {reply, {error, ?err(threshold_card_not_enought_count, CardId)}, State};
		false ->
		    SN = lists:concat(
			   ["M-", ?to_i(Merchant),
			    "-S-", ?to_i(Shop), "-", ?inventory_sn:sn(threshold_card_sale, Merchant)]),
		    
		    Sql1 = "update w_card set ctime=ctime-" ++ ?to_s(Count)
			++ " where id=" ++ ?to_s(CardId)
			++ " and merchant=" ++ ?to_s(Merchant)
			++ " and rule=" ++ ?to_s(?THEORETIC_CHARGE),
		    Sql2 = "insert into w_card_sale(rsn"
			", employee, retailer, card, cid, amount, cgood, tag_price, merchant"
			", shop, comment, entry_date) values("
			++ "\'" ++ ?to_s(SN) ++ "\',"
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(CardId) ++ ","
			++ ?to_s(ChargeId) ++ "," 
			++ ?to_s(Count) ++ ","
			++ ?to_s(CGood) ++ ","
			++ ?to_s(Price) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ "\'" ++ ?to_s(Comment) ++ "\',"
			++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')", 
		    case ?sql_utils:execute(transaction, [Sql1, Sql2], SN) of
			{ok, SN} ->
			    {reply, {ok, SN, LeftCount - Count, ?INVALID_OR_EMPTY}, State};
			_Error ->
			    _Error
		    end
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({expire_card_consume, Merchant, CardId, Attrs}, _From, State) ->
    ?DEBUG("threshold_card_consume: merchant ~p, card ~p, attrs ~p", [Merchant, CardId, Attrs]),
    CGood = ?v(<<"cgood">>, Attrs),
    Count = ?v(<<"count">>, Attrs),
    ChargeId = ?v(<<"charge">>, Attrs),
    Retailer = ?v(<<"retailer">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    Price    = ?v(<<"tag_price">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),
    
    Sql = "select id, merchant, retailer, rule, sdate, edate from w_card"
	" where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and cid=" ++ ?to_s(ChargeId), 
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    {reply, {error, ?err(threshold_card_not_exist, CardId)}, State};
	{ok, Card} ->
	    ExpireDate = ?v(<<"edate">>, Card),
	    case ?utils:compare_date(date, current_date(), ExpireDate) of
		true ->
		    {reply, {error, ?err(threshold_card_expired, CardId)}, State};
		false ->
		    SN = lists:concat(
			   ["M-", ?to_i(Merchant),
			    "-S-", ?to_i(Shop), "-", ?inventory_sn:sn(threshold_card_sale, Merchant)]),
		    
		    Sql1 = "insert into w_card_sale(rsn"
			", employee, retailer, card, amount, cgood, tag_price, merchant"
			", shop, comment, entry_date) values("
			++ "\'" ++ ?to_s(SN) ++ "\',"
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(CardId) ++ ","
			++ ?to_s(Count) ++ ","
			++ ?to_s(CGood) ++ ","
			++ ?to_s(Price) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ "\'" ++ ?to_s(Comment) ++ "\',"
			++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')", 
		    case ?sql_utils:execute(write, Sql1, SN) of
			{ok, SN} ->
			    {reply, {ok, SN, ?INVALID_OR_EMPTY, ExpireDate}, State};
			_Error ->
			    _Error
		    end 
	    end; 
	Error ->
	    {reply, Error, State}
    end;
    
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


make_ticket(_Merchant, _Datetime, _Balance, _StartBatch, _Plan, 0, Acc) ->
    lists:reverse(Acc);
make_ticket(Merchant, Datetime, Balance, StartBatch, Plan, Count, Acc) ->
    Sql = "insert into w_ticket_custom("
	"batch"
	", plan"
	", balance"
	", retailer"
	", state"
	", shop"
	", remark"
	", merchant"
	", entry_date) values("
	++ ?to_s(StartBatch) ++ ","
	++ ?to_s(Plan) ++ ","
	++ ?to_s(Balance) ++ ","
	++ ?to_s(-1) ++ ","
	++ ?to_s(?CHECKED) ++ ","
	++ ?to_s(-1) ++ ","
	++ "\'\'" ++ ","
	++ ?to_s(Merchant) ++ ","
	++ "\'" ++ ?to_s(Datetime) ++ "\')",

    make_ticket(Merchant, Datetime, Balance, StartBatch + 1, Plan, Count - 1, [Sql|Acc]).
    
date_next(?MONTH_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    case Month + 1 > 12 of
	true ->
	    {Year + 1, 1, Date};
	false -> 
	    {Year, Month + 1, day_of_next_month(Year, Month + 1, Date)}
    end;
date_next(?QUARTER_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    case Month + 3 > 12 of
	true ->
	    {Year + 1, (Month + 3) rem 12, day_of_next_month(Year, (Month + 3) rem 12, Date)};
	false ->
	    {Year, Month + 3, day_of_next_month(Year, Month + 3, Date)}
    end;
date_next(?YEAR_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    {Year + 1, Month, Date};

date_next(?HALF_YEAR_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    case Month + 6 > 12 of
	true ->
	    {Year + 1, (Month + 6) rem 12, day_of_next_month(Year, (Month + 6) rem 12, Date)};
	false ->
	    {Year, Month + 6, day_of_next_month(Year, Month + 6, Date)}
    end.

day_of_next_month(CurrentYear, NextMonth, CurrentDay) -> 
    Days = calendar:last_day_of_the_month(CurrentYear, NextMonth),
    case CurrentDay > Days of
	true -> Days; 
	false -> CurrentDay
    end. 

current_date() ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    {Year, Month, Date}.

format_date(Year, Month, Date) ->
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date])).
format_date({Year, Month, Date}) ->
    format_date(Year, Month, Date).
    

filter_condition(consume, Conditions) -> 
    lists:foldr(
      fun({<<"mconsume">>, _}, Acc) -> 
    	      Acc; 
	 ({<<"lconsume">>, _}, Acc) ->
    	      Acc; 
    	 (C, Acc) ->
    	      [C|Acc]
      end, [], Conditions).

sort_condition(consume, Conditions) ->
    sort_condition(consume, Conditions, []).

sort_condition(consume, Conditions, Prefix) ->
    case ?v(<<"mconsume">>, Conditions, []) of
	[] -> [];
	More -> ?to_s(Prefix) ++ "consume>" ++ ?to_s(More)
    end ++ 
	case ?v(<<"lconsume">>, Conditions, []) of
	    [] -> [];
	    LessSell -> ?to_s(Prefix) ++ "consume<" ++ ?to_s(LessSell)
	end.


