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

-export([retailer/2, retailer/3, retailer/4, retailer/5, retailer/6, default_profile/2]).
-export([charge/2, charge/3, threshold_card/3, threshold_card/4, threshold_card_good/3]).
-export([score/2, score/3, ticket/2, ticket/3, ticket/4, get_ticket/3, get_ticket/4, make_ticket/3]).
-export([bank_card/3, bank_card/4]).
-export([filter/4, filter/6]).
-export([gift/3, gift/4]).
-export([match/3, syn/2, syn/3, get/2, card/3, sms/2]).

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

retailer(delete, {Merchant, UTable}, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_retailer, Merchant, UTable, RetailerId});
retailer(get, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer, Merchant, RetailerId});
retailer(get_batch, Merchant, RetailerIds) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer_batch, Merchant, RetailerIds}).

retailer(update, Merchant, RetailerId, {Attrs, OldAttrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_retailer, Merchant, RetailerId, {Attrs, OldAttrs}});
retailer(update_score, Merchant, RetailerId, Score) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_score, Merchant, RetailerId, Score});
retailer(reset_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reset_password, Merchant, RetailerId, Password});
retailer(last_recharge, Merchant, RetailerId, Shops) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {last_recharge, Merchant, RetailerId, Shops}).

retailer(check_password, Merchant, RetailerId, Password, CheckPwd) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_password, Merchant, RetailerId, Password, CheckPwd}).

retailer(check_trans_count, {Merchant, UTable}, RetailerId, Shop, Count, Days) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {check_trans_count, {Merchant, UTable}, RetailerId, Shop, Count, Days}).

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
    gen_server:call(Name, {get_recharge, Merchant, RechargeId});

charge(get_charge, Merchant, ChargeId)  ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_charge, Merchant, ChargeId}).

charge(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_charge, Merchant}).

%% bank card
bank_card(get, Merchant, RetailerId) ->
    %% Name = ?wpool:get(?MODULE, Merchant),
    %% gen_server:call(Name, {get_bank_card, Merchant, RetailerId}).
    bank_card(get, Merchant, RetailerId, []).
bank_card(get, Merchant, RetailerId, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_bank_card, Merchant, RetailerId, Conditions}).

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

ticket(new_plan, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_ticket_plan, Merchant, Attrs});
ticket(update_plan, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {update_ticket_plan, Merchant, Attrs});
ticket(delete_plan, Merchant, Plan) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {delete_ticket_plan, Merchant, Plan});
ticket(gift, {Merchant, UTable}, GiftInfo) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {gift_ticket, Merchant, UTable, GiftInfo}).

ticket(discard_custom_one, Merchant, TicketId, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {discard_custom_one, Merchant, TicketId, Mode}); 
ticket(discard_custom_all, Merchant, Conditions, {Mode, Active}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {discard_custom_all, Merchant, Conditions, Mode, Active}).

ticket(list_plan, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_ticket_plan, Merchant}).

get_ticket(by_retailer, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_retailer, Merchant, RetailerId});
get_ticket(by_promotion, Merchant, {RetailerId, ConsumeShop}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_promotion, Merchant, RetailerId, ConsumeShop});

get_ticket(by_batch, Merchant, {Batch, Mode, Custom}) when is_integer(Batch)-> 
    get_ticket(by_batch, Merchant, {[Batch], Mode, Custom});
get_ticket(by_batch, Merchant, {Batch, Mode, Custom})-> 
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_batch, Merchant, {Batch, Mode, Custom}}).

get_ticket(by_batch, Merchant, Batch, Custom) ->
    get_ticket(by_batch, Merchant, {Batch, ?TICKET_CHECKED, Custom});
get_ticket(by_sale, Merchant, Sale, Custom) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {ticket_by_sale, Merchant, Sale, Custom}).

make_ticket(batch, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {make_ticket_batch, Merchant, Attrs}).
    %% Name = ?wpool:get(?MODULE, Merchant), 
    %% gen_server:call(Name, {ticket_by_batch, Merchant, Batch}).

%% threshold_card
threshold_card_good(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {add_threshold_card_good, Merchant, Attrs});
threshold_card_good(update, Merchant, {GoodId, Attrs}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {update_threshold_card_good, Merchant, GoodId, Attrs});
threshold_card_good(list, Merchant, Shops) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {list_threshold_card_good, Merchant, Shops}).

threshold_card(get, Merchant, Card) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_threshold_card, Merchant, Card});
threshold_card(delete, Merchant, CardAttr) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_threshold_card, Merchant, CardAttr}).

threshold_card(threshold_consume, Merchant, Card, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {threshold_card_consume, Merchant, Card, Attrs});
threshold_card(expire_consume, Merchant, Card, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {expire_card_consume, Merchant, Card, Attrs});
threshold_card(cancel_consume, Merchant, Card, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {cancel_card_consume, Merchant, Card, Attrs});
threshold_card(list_child, Merchant, Retailer, CardSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_threshold_child_card, Merchant, Retailer, CardSN});
threshold_card(update_expire, Merchant, Card, Expire) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_threshold_card_expire, Merchant, Card, Expire}).

gift(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {add_gift, Merchant, Attrs});

gift(exchange, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {exchange_gift, Merchant, Attrs}).

gift(update, Merchant, GiftId, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {update_gift, Merchant, GiftId, Attrs}).

filter(total_retailer, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_retailer, Merchant, Conditions});
filter({total_consume, Mode}, 'and', {Merchant, UTable}, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_consume, Mode, Merchant, UTable, Conditions}); 
filter(total_charge_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_charge_detail, Merchant, Conditions});
filter(total_ticket_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_ticket_detail, Merchant, Conditions});
filter({total_custom_ticket_detail, Mode}, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_custom_ticket_detail, Mode, Merchant, Conditions}); 
filter(total_threshold_card, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card, Merchant, Conditions});
filter(total_threshold_card_sale, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card_sale, Merchant, Conditions});
filter(total_threshold_card_sale_note, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card_sale_note, Merchant, Conditions});
filter(total_threshold_card_good, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_threshold_card_good, Merchant, Conditions});
filter(total_gift, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_gift, Merchant, Conditions});
filter(total_gift_exchange, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_gift_exchange, Merchant, Conditions}).



filter({retailer, Order, Sort}, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {{filter_retailer, Order, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter({consume, Mode}, 'and', {Merchant, UTable}, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {filter_consume, Mode, Merchant, UTable, Conditions, CurrentPage, ItemsPerPage});

filter(charge_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_charge_detail, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(ticket_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter({custom_ticket_detail, Mode}, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_custom_ticket_detail, Mode, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(threshold_card, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(threshold_card_sale, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card_sale, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(threshold_card_sale_note, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card_sale_note, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(threshold_card_good, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_threshold_card_good, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(gift, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_gift, Merchant, Conditions, CurrentPage, ItemsPerPage});
filter(gift_exchange, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_gift_exchange, Merchant, Conditions, CurrentPage, ItemsPerPage}).




%% match
match(phone, Merchant, {Mode, Phone, Shops}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {match_phone, Merchant, {Mode, Phone, Shops}}).

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
    Lunar    = ?v(<<"lunar">>, Attrs, 0),
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
	    Sql2 = "insert into w_retailer(name"
		", intro"
		", level"
		", card"
		", py"
		", id_card"
		", birth"
		", lunar"
		", type"
		", password"
		", score"
		", mobile"
		", address"
		", shop"
		", draw"
		", merchant"
		", entry_date)"
		++ " values (" 
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Intro) ++ ","
		++ ?to_s(Level) ++ ","
		++ "\'" ++ ?to_s(Card) ++ "\',"
		++ "\'" ++ ?to_s(Pinyin) ++ "\',"
		++ "\'" ++ ?to_s(IDCard) ++ "\',"
		++ "\'" ++ ?to_s(Birth) ++ "\',"
		++ ?to_s(Lunar) ++ ","
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
    %% Rule     = ?v(<<"rule">>, Attrs, 0),

    Sql = "select id, name, level from w_retailer_level"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop) 
	++ " and level=" ++ ?to_s(Level),
    
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    Sql2 = "insert into w_retailer_level("
		"shop"
		", name"
		", level"
	    %% ", rule"
		", score"
		", discount"
		", Merchant)"
		++ " values ("
		++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Level) ++ ","
	    %% ++ ?to_s(Rule) ++ ","
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
    Lunar    = ?v(<<"lunar">>, Attrs),
    Password = ?v(<<"password">>, Attrs), 

    OldShop     = ?v(<<"shop_id">>, OldAttrs),
    OldType     = ?v(<<"type_id">>, OldAttrs),
    OldLevel    = ?v(<<"level">>, OldAttrs),
    OldDrawId   = ?v(<<"draw_id">>, OldAttrs),
    OldBalance  = ?to_f(?v(<<"balance">>, OldAttrs)),
    OldLunar    = ?v(<<"lunar_id">>, OldAttrs),

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
		++ ?utils:v(lunar, integer, ?supplier:get_modified(Lunar, OldLunar))
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

handle_call({check_trans_count, {Merchant, UTable}, RetailerId, Shop, Count, Days}, _From, State) -> 
    Sql = "select id"
	", rsn"
	", retailer"
	", entry_date"
	" from" ++ ?table:t(sale_new, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " and type=0"
	++ " order by id desc limit " ++ ?to_s(Count + 1),
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    {reply, {ok, 0, []}, State};
	{ok, Trans} ->
	    DateBeforDays = ?utils:date_before(Days),
	    ValidTrans = 
		lists:foldr(
		  fun({T}, Acc) ->
			  Date = format_date(?utils:to_date(datetime, ?v(<<"entry_date">>, T))),
			  case ?utils:big_date(date, Date, DateBeforDays) of
			      true -> [{T}|Acc];
			      false -> Acc
			  end
		  end, Trans, []), 
	    {reply, {ok, length(ValidTrans), ValidTrans}, State};
	Error ->
	    {reply, Error, State}
    end;

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
	", a.lunar as lunar_id"
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
	", lunar as lunar_id"
	", shop as shop_id"
	", draw as draw_id"
	", type as type_id"
	", balance"
	", score"
	", mobile"
	" from w_retailer"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, [{<<"id">>, lists:usort(RetailerIds)}]),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({delete_retailer, Merchant, UTable, RetailerId}, _From, State) ->
    ?DEBUG("delete_retailer with merchant ~p, retailerId ~p", [Merchant, RetailerId]),
    Sql0 = "select id, retailer"
    %% " from w_sale"
	" from" ++ ?table:t(sale_new, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
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
    %% ", rule"
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
    MConsume = ?v(<<"mconsume">>, Conditions, []),
    MScore = ?v(<<"mscore">>, Conditions, []),
    LScore = ?v(<<"lscore">>, Conditions, []),
    
    %% SortConditions = lists:keydelete(<<"a.month">>, 1, lists:keydelete(<<"a.date">>, 1, NewConditions)),
    SortConditions = lists:keydelete(
		       <<"a.mconsume">>, 1,
		       lists:keydelete(
			 <<"a.lscore">>, 1,
			 lists:keydelete(
			   <<"a.mscore">>, 1,
			   lists:keydelete(
			     <<"a.month">>, 1,
			     lists:keydelete(<<"a.date">>, 1, NewConditions))))),
    
    Sql = "select a.id"
	", a.name"
	", a.intro as intro_id"
	", a.level"
	", a.card"
	", a.id_card"
	", a.py"
	", a.birth"
	", a.lunar as lunar_id"
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
	", b.sms_sign as sign"
	
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

	++ case MConsume of
	       [] -> [];
	       _ ->
		   " and a.consume>=" ++ ?to_s(MConsume)
	   end
	++ case MScore of
	       [] -> [];
	       _ ->
		   " and a.score>=" ++ ?to_s(MScore)
	   end
	++ case LScore of
	       [] -> [];
	       _ ->
		   " and a.score<=" ++ ?to_s(LScore)
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

    Name      = ?v(<<"name">>, Attrs),
    Rule      = ?v(<<"rule">>, Attrs, -1),
    XTime     = ?v(<<"xtime">>, Attrs, 0),
    XDiscount = ?v(<<"xdiscount">>, Attrs, 100),
    CTime     = ?v(<<"ctime">>, Attrs, 0),
    
    %% N
    {Charge, Balance}  =
	case Rule =:= 0 of
	    true -> {?v(<<"charge">>, Attrs, 0), ?v(<<"balance">>, Attrs, 0)};
	    _ -> {0, 0}
	end,

    IShop    = ?v(<<"ishop">>, Attrs, ?NO),
    IBalance = ?v(<<"ibalance">>, Attrs, ?INVALID_OR_EMPTY),
    MBalance = ?v(<<"mbalance">>, Attrs, ?INVALID_OR_EMPTY),
    ICount   = ?v(<<"icount">>, Attrs, ?INVALID_OR_EMPTY), 
    
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
		      ++ " and type=" ++ ?to_s(Type)
		      ++ " and mbalance=" ++ ?to_s(MBalance)
		      ++ " and ibalance=" ++ ?to_s(IBalance)
		      ++ " and ishop=" ++ ?to_s(IShop)
		      ++ " and icount=" ++ ?to_s(ICount);
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
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'";
	      ?BALANCE_LIMIT_CHARGE ->
		  "select id, name from w_charge" 
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and name=\'" ++ ?to_s(Name) ++ "\'"
	  end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_charge(merchant"
		", name"
		", rule"
		", xtime"
		", xdiscount"
		", ctime"
		", charge"
		", balance"
		", type"
		", ishop"
		", ibalance"
		", mbalance"
		", icount"
		", sdate"
		", edate"
		", remark"
		", entry) values("
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
		++ ?to_s(IShop) ++ ","
		++ ?to_s(IBalance) ++ ","
		++ ?to_s(MBalance) ++ ","
		++ ?to_s(ICount) ++ "," 
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
	", ishop"
	", icount"
	", ibalance"
	", mbalance"
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

handle_call({get_charge, Merchant, ChargeId}, _From, State) ->
    ?DEBUG("get_charge: Merchant ~p, ChargeId ~p", [Merchant, ChargeId]),
    Sql = "select id"
	", name"
	", rule as rule_id"
	", xtime"
	", xdiscount"
	", ctime"
	", charge"
	", balance"
	", type"
	", ishop"
	", icount"
	", ibalance"
	", mbalance"
	", sdate"
	", edate"
	", deleted"
	" from w_charge"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(ChargeId),
    %%++ " and deleted=" ++ ?to_s(?NO),
    Reply = ?sql_utils:execute(s_read, Sql),

    {reply, Reply, State};

handle_call({get_bank_card, Merchant, RetailerId, Conditions}, _From, State) ->
    ?DEBUG("get_bank_card: merchant ~p, retailer ~p", [Merchant, RetailerId]),
    Sql = "select id"
	", retailer as retailer_id"
	", balance"
	", cid as charge_id"
	", shop as shop_id"
	", type"
	" from w_retailer_bank"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ ?sql_utils:condition(proplists, Conditions),
    %% ++ " and balance > 0",
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
    CTime    = ?v(<<"ctime">>, Attrs, 0), 
    SBalance = ?v(<<"send_balance">>, Attrs, 0),
    Goods    = ?v(<<"good">>, Attrs, []),

    ChargeId    = ?v(<<"charge">>, Attrs),
    Stock       = ?v(<<"stock">>, Attrs, []),
    Comment     = ?v(<<"comment">>, Attrs, []),
    
    Entry       = ?utils:current_time(format_localtime),

    Rule = ?v(<<"rule_id">>, ChargeRule, -1),
    
    %% ?DEBUG("Charge ~p", [Charge]),
    Sql0 = "select id, name, mobile, balance, score from w_retailer"
	" where id=" ++ ?to_s(Retailer)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Account} -> 
	    SN = lists:concat(
		   ["M-",
		    ?to_i(Merchant),
		    "-S-", ?to_i(Shop), "-", ?inventory_sn:sn(w_recharge, Merchant)]),

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
		fun(CardNo, EndDate) ->
			"insert into w_charge_detail(rsn"
			    ", csn"
			    ", merchant"
			    ", shop"
			    ", employ"
			    ", cid"
			    ", retailer"
			    ", ledate"
			    ", lbalance"
			    ", cbalance"
			    ", ctime" 
			    ", sbalance"
			    ", cash"
			    ", card"
			    ", wxin"
			    ", stock"
			    ", comment"
			    ", entry_date) values("
			    ++ "\'" ++ ?to_s(SN) ++ "\',"
			    ++ "\'" ++ ?to_s(CardNo) ++ "\',"
			    ++ ?to_s(Merchant) ++ ","
			    ++ ?to_s(Shop) ++ ","
			    ++ "\'" ++ ?to_s(Employee) ++ "\',"
			    ++ ?to_s(ChargeId) ++ "," 
			    ++ ?to_s(Retailer) ++ ","
			    ++ "\'" ++ format_date(EndDate) ++ "\',"
			    ++ ?to_s(CurrentBalance) ++ ","
			    ++ ?to_s(CBalance) ++ ","
			    ++ ?to_s(CTime) ++ "," 
			    ++ ?to_s(SBalance) ++ ","
			    ++ ?to_s(Cash) ++ ","
			    ++ ?to_s(Card) ++ ","
			    ++ ?to_s(Wxin) ++ ","
			    ++ case Rule =:= ?THEORETIC_CHARGE
				   orelse Rule =:= ?MONTH_UNLIMIT_CHARGE
				   orelse Rule =:= ?QUARTER_UNLIMIT_CHARGE
				   orelse Rule =:= ?YEAR_UNLIMIT_CHARGE
				   orelse Rule =:= ?HALF_YEAR_UNLIMIT_CHARGE of
				   true ->
				       NewGoods = 
					   lists:foldr(
					     fun({struct, Good}, Acc) ->
						     [{[{<<"g">>, ?v(<<"id">>, Good)},
							{<<"c">>, ?v(<<"count">>, Good)}]}|Acc]
					     end, [], Goods),
				       %% ?DEBUG("NewGoods ~p", [NewGoods]),
				       case NewGoods of
					   [] -> "\'\'";
					   _ ->
					       "\'" ++ ?to_s(ejson:encode(NewGoods)) ++ "\'"
				       end;
				   false ->
				       "\'" ++ ?to_s(Stock) ++ "\'"
			       end
			    %% ++ case Rule of
			    %% 	?THEORETIC_CHARGE ->
			    %% 	       NewGoods = 
			    %% 		   lists:foldr(
			    %% 		     fun({struct, Good}, Acc) ->
			    %% 			     [{[{<<"g">>, ?v(<<"id">>, Good)},
			    %% 				{<<"c">>, ?v(<<"count">>, Good)}]}|Acc]
			    %% 		     end, [], Goods),
			    %% 	       %% ?DEBUG("NewGoods ~p", [NewGoods]),
			    %% 	       case NewGoods of
			    %% 		   [] -> "\'\'";
			    %% 		   _ ->
			    %% 		       "\'" ++ ?to_s(ejson:encode(NewGoods)) ++ "\'"
			    %% 	       end;
			    %% 	_ ->
			    %% 	    "\'" ++ ?to_s(Stock) ++ "\'"
			    %% end
			    ++ ","
			    ++ "\'" ++ ?to_s(Comment) ++ "\'," 
			    ++ "\'" ++ ?to_s(Entry) ++ "\')"
		end, 

	    case Rule =:= ?GIVING_CHARGE orelse Rule =:= ?TIMES_CHARGE of
		true ->
		    Sql2 = "update w_retailer set balance=balance+"
			++ ?to_s(CBalance + SBalance) ++ " where id=" ++ ?to_s(Retailer), 
		    LimitBalance = ?v(<<"ibalance">>, ChargeRule, ?INVALID_OR_EMPTY),
		    LimitCount = ?v(<<"icount">>, ChargeRule, ?INVALID_OR_EMPTY),
		    
		    Sql20 = "select id"
			", retailer"
			", balance"
			", cid"
			", shop"
			" from w_retailer_bank where merchant=" ++ ?to_s(Merchant)
			++ " and retailer=" ++ ?to_s(Retailer)
			++ " and shop=" ++ ?to_s(Shop)
			++ " and cid=" ++ ?to_s(ChargeId),
		    Sql3 = 
			case ?sql_utils:execute(s_read, Sql20) of
			    {ok, []} ->
				"insert into w_retailer_bank("
				    "retailer"
				    ", balance"
				    ", cid"
				    ", type"
				    ", merchant"
				    ", shop"
				    ", entry_date) values("
				    ++ ?to_s(Retailer) ++ ","
				    ++ ?to_s(CBalance + SBalance) ++ ","
				    ++ ?to_s(ChargeId) ++ ","
				    ++ case LimitBalance =:= ?INVALID_OR_EMPTY
				       andalso LimitCount =:= ?INVALID_OR_EMPTY of
					   true -> "0";
					   false -> "1"
				       end ++ ","
				    ++ ?to_s(Merchant) ++ ","
				    ++ ?to_s(Shop) ++ ","
				    ++ "\'" ++ ?to_s(Entry) ++ "\')";
			    {ok, BankCard} ->
				"update w_retailer_bank set balance=balance+"
				    ++ ?to_s(CBalance + SBalance)
				    ++ " where merchant=" ++ ?to_s(Merchant)
				    ++ " and retailer=" ++ ?to_s(Retailer)
				    ++ " and shop=" ++ ?to_s(Shop)
				    ++ " and cid=" ++ ?to_s(ChargeId)
				    ++ " and id=" ++ ?to_s(?v(<<"id">>, BankCard))
		    end,
				
		    AllSqls =  [RechargeDetailSql(?INVALID_OR_EMPTY, ?INVALID_DATE), Sql2, Sql3], 
		    Reply =
			case ?sql_utils:execute(transaction, AllSqls, SN) of
			    {ok, SN} ->
				{ok, {SN, Mobile, CBalance, CurrentBalance + CBalance + SBalance, Score}};
			    Error -> Error
			end,
		    %% ?w_user_profile:update(retailer, Merchant),
		    {reply, Reply, State};
		false  ->
		    StartDate   = ?v(<<"stime">>, Attrs, ?INVALID_DATE),
		    Period      = ?v(<<"period">>, Attrs, 0), 

		    ChildTheoreticCardSql =
			fun(CardSN, CardGood, ConsumeCount) ->
				"insert into w_child_card(csn"
				    ", retailer"
				    ", good, ctime, merchant, shop, entry_date)"
				    " values("
				    ++ "\'" ++ ?to_s(CardSN) ++ "\',"
				    ++ ?to_s(Retailer) ++ ","
				    ++ ?to_s(CardGood) ++ ","
				    ++ ?to_s(ConsumeCount) ++ ","
				    ++ ?to_s(Merchant) ++ ","
				    ++ ?to_s(Shop) ++ ","
				    ++ "\'" ++ ?to_s(Entry) ++ "\')"
			end,
		    
		    Sql01 = "select id"
			", csn"
			", retailer"
			", ctime"
			", sdate"
			", edate"
			", cid"
			", rule"
			", deleted"
			" from w_card"
			" where merchant=" ++ ?to_s(Merchant)
			++ " and retailer=" ++ ?to_s(Retailer)
			++ " and cid=" ++ ?to_s(ChargeId),

		    {_CardInfo, Sql22} = 
			case ?sql_utils:execute(s_read, Sql01) of 
			    {ok, []} ->
				{Year, Month, Date} =
				    case Rule of
					?THEORETIC_CHARGE -> ?INVALID_DATE;
					_ ->
					    ?utils:big_date(date, current_date(), StartDate)
				    end,
				?DEBUG("Year ~p, Month ~p, Date ~p", [Year, Month, Date]),
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
					    date_next(?HALF_YEAR_UNLIMIT_CHARGE, {Year, Month, Date});
					?BALANCE_LIMIT_CHARGE ->
					    case Period of
						12 -> {Year + 1, Month, Date};
						_ ->
						    UYear = (Period div 12)
							+ ((Period rem 12 + Month) div 12),
						    UMonth = case (Period + Month) rem 12 of
								 0 -> 12;
								 _UMonth ->_UMonth
							     end,
						    {Year + UYear,
						     UMonth,
						     day_of_next_month(UYear, UMonth, Date)}
					    end
				    end,

				CardSN =
				    lists:concat(
				      [?to_i(Merchant),
				       "-",
				       ?to_i(Shop),
				       "-",
				       ?inventory_sn:sn(wretailer_card_sn, Merchant)]),

				%% ChildTheoreticCardSql =
				%%     fun(CardSN, CardGood, ConsumeCount) ->
				%% 	    "insert into w_child_card(csn"
				%% 		", retailer"
				%% 		", good, ctime, merchant, shop, entry_date)"
				%% 		" values("
				%% 		++ "\'" ++ ?to_s(CardSN) ++ "\',"
				%% 		++ ?to_s(Retailer) ++ ","
				%% 		++ ?to_s(CardGood) ++ ","
				%% 		++ ?to_s(ConsumeCount) ++ ","
				%% 		++ ?to_s(Merchant) ++ ","
				%% 		++ ?to_s(Shop) ++ ","
				%% 		++ "\'" ++ ?to_s(Entry) ++ "\')"
				%%     end,
				
				{new_card,
				 [case Rule of
				     ?THEORETIC_CHARGE -> RechargeDetailSql(CardSN, ?INVALID_DATE);
				     _ ->
					 %% must not to use at current day
					 RechargeDetailSql(
					   CardSN, ?utils:date_before({Year, Month, Date}, 1))
				  end,
				 "insert into w_card(csn"
				  ", retailer"
				  ", ctime"
				  ", sdate"
				  ", edate"
				  ", cid"
				  ", rule"
				  ", merchant"
				  ", shop"
				  %% ", good"
				  ", entry_date) values("
				  ++ "\'" ++ ?to_s(CardSN) ++ "\',"
				  ++ ?to_s(Retailer) ++ "," 
				  ++ case Rule of
					 ?BALANCE_LIMIT_CHARGE ->
					     ?to_s(CBalance + SBalance);
					 _ ->
					     ?to_s(CTime + SBalance)
				     end ++ ","
				  ++ "\'" ++ format_date(Year, Month, Date) ++ "\',"
				  ++ "\'" ++ format_date(EndDate) ++ "\',"
				  ++ ?to_s(ChargeId) ++ ","
				  ++ ?to_s(Rule) ++ ","
				  ++ ?to_s(Merchant) ++ ","
				  ++ ?to_s(Shop) ++ "," 
				  ++ "\'" ++ ?to_s(Entry) ++ "\')"]

				 ++ case Rule =:= ?THEORETIC_CHARGE
				    orelse Rule =:= ?MONTH_UNLIMIT_CHARGE
				    orelse Rule =:= ?QUARTER_UNLIMIT_CHARGE
				    orelse Rule =:= ?YEAR_UNLIMIT_CHARGE
				    orelse Rule =:= ?HALF_YEAR_UNLIMIT_CHARGE of
					true ->
					    lists:foldr(
					      fun({struct, Good}, Acc) ->
						      [ChildTheoreticCardSql(
							 CardSN,
							 ?v(<<"id">>, Good),
							 ?v(<<"count">>, Good,
							    ?UNLIMIT_TIME_COUNT_CARD)) | Acc]
					      end, [], Goods);
					false ->
					    []
				    end
				      %% ?THEORETIC_CHARGE ->
				      %% 	lists:foldr(
				      %% 	  fun({struct, Good}, Acc) ->
				      %% 		      [ChildTheoreticCardSql(
				      %% 			 CardSN,
				      %% 			 ?v(<<"id">>, Good),
				      %% 			 ?v(<<"count">>, Good)) | Acc]
				      %% 	      end, [], Goods);
				      %% 	%% ?BALANCE_LIMIT_CHARGE ->
				      %% 	%%     ["update w_retailer set balance=balance+"
				      %% 	%%      ++ ?to_s(CBalance + SBalance)
				      %% 	%%      ++ " where id=" ++ ?to_s(Retailer)];
				      %% 	_ ->
				      %% 	    []
				}; 
			    {ok, OCard} ->
				%% ?DEBUG("old card ..., startDate ~p", [StartDate]),
				LastEndDate = ?v(<<"edate">>, OCard),
				BeginDate = ?utils:big_date(date, current_date(), ?v(<<"sdate">>, OCard)), 
				?DEBUG("BeginDate ~p", [BeginDate]),
				HasDeleted = ?v(<<"deleted">>, OCard, ?NO),
				%% {Year, Month, Date} = ?utils:to_date(date, EndDate),
				{Year, Month, Date} =
				    case Rule of
					?THEORETIC_CHARGE -> ?INVALID_DATE;
					_ -> 
					    %% %% case HasDeleted of
					    %% %% 	?YES -> ?utils:to_date(date, StartDate);
					    %% %% 	?NO -> ?utils:big_date(date, StartDate, EndDate)
					    %% %% end
					    %% current_date()
					    BeginDate
				    end,
				?DEBUG("Year ~p, Month ~p, Date ~p", [Year, Month, Date]), 
				CardSN = ?v(<<"csn">>, OCard),
				
				{exist_card,
				 [case Rule of
				     ?THEORETIC_CHARGE ->
					 RechargeDetailSql(CardSN, ?INVALID_DATE);
				     _ ->
					 RechargeDetailSql(CardSN, ?utils:to_date(date, LastEndDate))
				 end, 
				 case Rule of
				     ?THEORETIC_CHARGE -> 
					 case HasDeleted of
					     ?NO ->
						 "update w_card set ctime=ctime+"
						     ++ ?to_s(CTime + SBalance);
					     ?YES ->
						 "update w_card set ctime=" ++ ?to_s(CTime)
						     ++ ", deleted=" ++ ?to_s(?NO)
					 end;
				     ?MONTH_UNLIMIT_CHARGE ->
					 NextMonth = date_next(?MONTH_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextMonth) ++ "\'"
					     ++ ", deleted=" ++ ?to_s(?NO);
				     ?QUARTER_UNLIMIT_CHARGE ->
					 NextQuarter =
					     date_next(?QUARTER_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextQuarter) ++ "\'"
					     ++ case HasDeleted of
						    ?YES -> ", deleted=" ++ ?to_s(?NO);
						    ?NO -> []
						end;
				     ?HALF_YEAR_UNLIMIT_CHARGE ->
					 NextHalfYear =
					     date_next(?HALF_YEAR_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextHalfYear) ++ "\'"
					     ++ case HasDeleted of
						       ?YES -> ", deleted=" ++ ?to_s(?NO);
						       ?NO -> []
						   end;
				     ?YEAR_UNLIMIT_CHARGE ->
					 NextYear = date_next(?YEAR_UNLIMIT_CHARGE, {Year, Month, Date}),
					 "update w_card set edate=\'" ++ format_date(NextYear)
					     ++ case HasDeleted of
						       ?YES -> ", deleted=" ++ ?to_s(?NO);
						       ?NO -> []
						   end;
				     ?BALANCE_LIMIT_CHARGE ->
					 NextPeriod = 
					     case Period of
						 12 -> {Year + 1, Month, Date};
						 _ ->
						     UYear = (Period + Month) div 12,
						     UMonth = case (Period + Month) rem 12 of
								  0 -> 12;
								  _UMonth ->_UMonth
							      end,
						     {Year + UYear,
						      UMonth,
						      day_of_next_month(Year + UYear, UMonth, Date)}
					     end,
					 ?DEBUG("NextPeriod ~p", [NextPeriod]),
					 "update w_card set "
					     ++ case HasDeleted of
						    ?NO -> "ctime=ctime+";
						    ?YES -> "ctime="
						end ++ ?to_s(CBalance + SBalance)
					     ++", edate=\'" ++ format_date(NextPeriod) ++ "\'" 
				 end ++ 
				     case Rule of
					 ?THEORETIC_CHARGE -> [];
					 _ ->
					     %% case ?utils:compare_date(date, StartDate, EndDate) of 
					     %% 	 true ->
					     %% 	     ", sdate=\'" ++ ?to_s(StartDate) ++ "\'";
					     %% 	 false -> []
					     %% end
					     ", sdate=\'" ++ ?to_s(StartDate) ++ "\'"
				     end
				 ++ " where id=" ++ ?to_s(?v(<<"id">>, OCard))]
				 
				 ++ case Rule =:= ?THEORETIC_CHARGE
					orelse Rule =:= ?MONTH_UNLIMIT_CHARGE
					orelse Rule =:= ?QUARTER_UNLIMIT_CHARGE
					orelse Rule =:= ?YEAR_UNLIMIT_CHARGE
					orelse Rule =:= ?HALF_YEAR_UNLIMIT_CHARGE of
					true ->
					    lists:foldr(
					      fun({struct, Good}, Acc) ->
						      GoodId = ?v(<<"id">>, Good), 
						      GoodCount = ?v(<<"count">>,
								     Good, ?UNLIMIT_TIME_COUNT_CARD),
						      case ?sql_utils:execute(
							   s_read,
							      "select csn, good, retailer, merchant"
							      " from w_child_card"
							      " where csn=\'" ++ ?to_s(CardSN) ++ "\'"
							      ++ " and retailer=" ++ ?to_s(Retailer)
							      ++ " and good=" ++ ?to_s(GoodId))
						      of
							  {ok, []} ->
							      [ChildTheoreticCardSql(
								 CardSN,
								 GoodId,
								 GoodCount) | Acc];
							  {ok, _E} ->
							      case Rule =:= ?THEORETIC_CHARGE of
								  true ->
								      ["update w_child_card set "
								       "ctime=ctime+" ++ ?to_s(GoodCount)
								       ++ " where csn=\'"
								       ++ ?to_s(CardSN) ++ "\'"
								       ++ " and merchant=" ++ ?to_s(Merchant)
								       ++ " and retailer=" ++ ?to_s(Retailer)
								       ++ " and good=" ++ ?to_s(GoodId)|Acc];
								  false ->
								      []
							      end
						      end
					      end, [], Goods);
					%% ?BALANCE_LIMIT_CHARGE ->
					%%     ["update w_retailer set balance=balance+"
					%%      ++ ?to_s(CBalance + SBalance)
					%%      ++ " where id=" ++ ?to_s(Retailer)];
					false ->
					    []
				    end
				}
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
	    ShopId     = ?v(<<"shop">>, RechargeInfo), 
	    Rule       = ?v(<<"rule_id">>, ChargePromotion),

	    RSN      = ?v(<<"rsn">>, RechargeInfo), 
	    CBalance = ?v(<<"cbalance">>, RechargeInfo),
	    SBalance = ?v(<<"sbalance">>, RechargeInfo),
	    AllBalance = CBalance + SBalance,
	    OBalance = ?v(<<"balance">>, RechargeInfo),
	    Datetime = ?utils:current_time(format_localtime), 
	    case Rule =:= ?GIVING_CHARGE orelse Rule =:= ?TIMES_CHARGE of
		true -> 
		    %% Retailer = ?v(<<"retailer">>, RechargeInfo), 
		    Sqls = 
			[Sql1, 
			 "update w_charge_detail set lbalance=lbalance-" ++ ?to_s(AllBalance) 
			 ++ " where merchant=" ++ ?to_s(Merchant)
			 ++ " and retailer=" ++ ?to_s(RetailerId)
			 ++ " and id>" ++ ?to_s(RechargeId),

			 "update w_retailer set balance=balance-" ++ ?to_s(AllBalance)
			 ++ " where id=" ++ ?to_s(RetailerId)
			 ++ " and merchant=" ++ ?to_s(Merchant),

			 "update w_retailer_bank set balance=balance-" ++ ?to_s(AllBalance)
			 ++ " where merchant=" ++ ?to_s(Merchant)
			 ++ " and shop=" ++ ?to_s(ShopId)
			 ++ " and retailer=" ++ ?to_s(RetailerId)
			 ++ " and cid=" ++ ?to_s(?v(<<"id">>, ChargePromotion)),

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
		    %% ?DEBUG("ChargeId ~p", [ChargeId]),
		    case Rule of
			?THEORETIC_CHARGE ->
			    %% CTime = ?v(<<"ctime">>, ChargePromotion),
			    CTime = ?v(<<"ctime">>, RechargeInfo),
			    STime = ?v(<<"sbalance">>, RechargeInfo),
			    %% ?DEBUG("CTime ~p, STime ~p", [CTime, STime]),
			    CardGoods = 
				case ?v(<<"stock">>, RechargeInfo) of
				    [] -> [];
				    _Goods -> ejson:decode(?to_s(_Goods))
				end,
			    ?DEBUG("CardGoods ~p", [CardGoods]), 
			    CardNo   = ?v(<<"csn">>, RechargeInfo), 
			    Sqls = ["update w_card set ctime=ctime-"
				    ++ case ?to_i(STime) > 0 of
					   true -> ?to_s(?to_i(CTime) + ?to_i(STime));
					   false -> ?to_s(CTime)
				       end
				    ++ " where merchant=" ++ ?to_s(Merchant)
				    ++ " and retailer=" ++ ?to_s(RetailerId)
				    ++ " and cid=" ++ ?to_s(ChargeId),
				    Sql1] 
				++ lists:foldr(
				     fun({Good}, Acc) ->
					     ["update w_child_card set "
					      "ctime=ctime-" ++ ?to_s(?v(<<"c">>, Good, 0))
					      ++ " where merchant=" ++ ?to_s(Merchant)
					      ++ " and csn=\'" ++ ?to_s(CardNo) ++ "\'"
					      ++ " and retailer=" ++ ?to_s(RetailerId)
					      ++ " and good=" ++ ?to_s(?v(<<"g">>, Good, -1)) | Acc]
				     end, [], CardGoods)
				,
			    %% ?DEBUG("Sqls ~p", [Sqls]),
			    Reply = ?sql_utils:execute(transaction, Sqls, RechargeId),
			    {reply, Reply, State};
			?BALANCE_LIMIT_CHARGE ->
			    EndDate = ?v(<<"ledate">>, RechargeInfo),
			    Sqls = ["update w_card set ctime=ctime-" ++ ?to_s(AllBalance)
				    ++ ", edate=\'" ++ ?to_s(EndDate) ++ "\'"
				    ++ " where merchant=" ++ ?to_s(Merchant)
				    ++ " and retailer=" ++ ?to_s(RetailerId)
				    ++ " and cid=" ++ ?to_s(ChargeId),
				    Sql1],
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
    EntryDate = ?v(<<"datetime">>, Attrs),

    Updates = ?utils:v(employ, string, Employee)
	++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(entry_date, string, EntryDate)
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
	", a.lbalance, a.cbalance, a.ctime, a.sbalance, a.cash, a.card, a.wxin"
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
    Sql = "select a.id"
	", a.rsn"
	", a.csn"
	", a.shop"
	", a.retailer"
	", a.cid"
	", a.ledate"
	", a.cbalance"
	", a.ctime"
	", a.sbalance"
	", a.stock"
	", b.balance"
	" from w_charge_detail a, w_retailer b"
	" where a.retailer=b.id and a.id=" ++ ?to_s(RechargeId)
	++ " and a.merchant=" ++ ?to_s(Merchant), 
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({last_recharge, Merchant, RetailerId, Shops}, _From, State) ->
    Sql = "select id"
	", rsn"
	", cid as charge_id"
	", shop as shop_id"
	", cbalance"
	", ctime"
	", sbalance"
	", retailer as retailer_id" 
	" from w_charge_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ ?sql_utils:condition(proplists, Shops)
	++ " order by id desc limit 1",
    ?DEBUG("Sql ~p", [Sql]),

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
    Sql = "select id"
	", name"
	", balance"
	", score"
	", type as type_id"
	", sdate"
	", edate"
	", remark"
	", deleted"
	", entry"
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
    Rule    = ?v(<<"rule">>, Attrs),
    Balance = ?v(<<"balance">>, Attrs),
    Effect  = case Rule of
		  0 -> ?utils:dbvalue(?v(<<"effect">>, Attrs, 0));
		  1 -> ?INVALID_OR_EMPTY
	      end,
    Expire  = case Rule of
		  0 -> ?utils:dbvalue(?v(<<"expire">>, Attrs, 0));
		  1 -> ?INVALID_OR_EMPTY
	      end,
    
    STime   = case Rule of
		  1 -> ?v(<<"stime">>, Attrs, 0);
		  0 -> format_date(?INVALID_DATE)
	      end,
    
    ETime   = case Rule of
		  1 -> ?v(<<"etime">>, Attrs, 0);
		  0 -> format_date(?INVALID_DATE)
	      end,
    
    MaxSend = ?v(<<"scount">>, Attrs, 1),
    MBalance= ?v(<<"mbalance">>, Attrs, -1),
    UBalance= ?v(<<"ubalance">>, Attrs, -1),
    IShop   = ?v(<<"ishop">>, Attrs, -1),
    Remark  = ?v(<<"remark">>, Attrs, []),
    Entry   = ?utils:current_time(format_localtime), 
    %% balacen should be unique
    Sql = "select id, name, balance from w_ticket_plan"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_ticket_plan("
		"name"
		", rule"
		", balance"
		", effect"
		", expire"
		", stime"
		", etime"
		", scount"
		", mbalance"
		", ubalance"
		", ishop"
		", remark"
		", merchant"
		", entry_date) values("
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Rule) ++ ","
		++ ?to_s(Balance) ++ ","
		++ case Effect of
		       0 -> ?to_s(?INVALID_OR_EMPTY);
		       _ -> ?to_s(Effect)
		   end ++ ","
		++ ?to_s(Expire) ++ ","
		++ "\'" ++ ?to_s(STime) ++ "\',"
		++ "\'" ++ ?to_s(ETime) ++ "\',"
		++ ?to_s(MaxSend) ++ ","
		++ ?to_s(MBalance) ++ ","
		++ ?to_s(UBalance) ++ ","
		++ ?to_s(IShop) ++ ","
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
    MBalance = ?v(<<"mbalance">>, Attrs),
    UBalance = ?v(<<"ubalance">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(balance, integer, Balance)
	++ ?utils:v(effect, integer, Effect)
	++ ?utils:v(expire, integer, Expire)
	++ ?utils:v(scount, integer, MaxSend)
	++ ?utils:v(mbalance, integer, MBalance)
	++ ?utils:v(ubalance, integer, UBalance)
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

handle_call({list_ticket_plan, Merchant}, _From, State) ->
    Sql = "select id"
	", merchant"
	", name"
	", rule as rule_id"
	", balance"
	", mbalance"
	", ubalance"
	", effect"
	", expire"
	", stime"
	", etime"
	", scount"
	", mbalance"
	", ishop"
	", entry_date"
	" from w_ticket_plan where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc",
    {reply, ?sql_utils:execute(read, Sql), State};

handle_call({delete_ticket_plan, Merchant, Plan}, _From, State) ->
    Sql = "update w_ticket_plan set deleted=" ++ ?to_s(?YES)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Plan),
    Reply = ?sql_utils:execute(write, Sql, Plan),
    {reply, Reply, State};
    

handle_call({gift_ticket,
	     Merchant,
	     UTable,
	     {Shop, Retailer, Tickets, WithRSN, Employee} = GiftInfo}, _From, State) ->
    ?DEBUG("gift_ticket: merchant ~p, GiftInfo ~p", [Merchant, GiftInfo]),
    Date = ?utils:current_time(localdate),
    Reply = 
	case search_custome_ticket(Merchant, Tickets, [], [], 0, 0, ?TICKET_EFFECT_NEVER) of
	    {_Success, Failed, _Balance, _Count, _MinEffect} when length(Failed) =/= 0 ->
		{error, ?err(no_valid_ticket, Merchant)};
	    {Success, _Failed, _Balance, _Count, _MinEffect} when length(Success) =:= 0 ->
		{error, ?err(no_valid_ticket, Merchant)};
	    {Success, [], Balance, Count, MinEffect} -> 
		Sql0 = 
		    lists:foldr(
		      fun({Plan, Batch, Effect, Expire}, Acc) ->
			      ValidEffect = case Effect == ?INVALID_OR_EMPTY of
						true -> 0;
						false -> Effect
					    end, 
			      ["update w_ticket_custom set retailer=" ++ ?to_s(Retailer)
			       ++ case WithRSN of
				      [] -> [];
				      _ -> ", sale_new=\'" ++ ?to_s(WithRSN) ++ "\'"
				  end
			       ++ case Employee of
				      [] -> ", employee=\'" ++ ?to_s(?INVALID_OR_EMPTY) ++ "\'";
				      _ -> ", employee=\'" ++ ?to_s(Employee) ++ "\'"
				  end 
			       ++ ", in_shop=" ++ ?to_s(Shop)
			       ++ ", mtime=\'" ++ ?to_s(Date) ++ "\'"
			       ++ ", stime=\'" ++ ?utils:current_date_after(ValidEffect) ++ "\'"
			       ++ case Expire == ?INVALID_OR_EMPTY of
				      true -> [];
				      false ->
					  ", etime=\'" ++ ?utils:current_date_after(ValidEffect + Expire) ++ "\'"
				  end
			       ++ ", state=" ++ ?to_s(?TICKET_STATE_CHECKED)
			       ++ " where merchant=" ++ ?to_s(Merchant)
			       ++ " and plan=" ++ ?to_s(Plan)
			       ++ " and batch=" ++ ?to_s(Batch)|Acc]
		      end, [], Success),
		Sql1 = 
		    case WithRSN of
			[] -> [];
			_ ->
			    ["update" ++ ?table:t(sale_new, Merchant, UTable)
			     ++ " set g_ticket=1 where rsn=\'" ++ ?to_s(WithRSN) ++ "\'"
			    ++ " and merchant=" ++ ?to_s(Merchant)
			    ++ " and retailer=" ++ ?to_s(Retailer)]
		    end,
		
		case ?sql_utils:execute(transaction, Sql0 ++ Sql1, Retailer) of
		    {ok, Retailer} ->
			{ok, Retailer, Balance, Count, MinEffect};
		    Error->
			Error
		end
	end, 
    {reply, Reply, State};

handle_call({discard_custom_one, Merchant, TicketId, Mode}, _From, State) ->
    Sql = "select id, balance, retailer, state from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(TicketId), 
    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} -> ?err(ticket_not_exist, TicketId);
	    {ok, _R} ->
		Sql1 = 
		    case Mode of
			0 ->
			    "update w_ticket_custom set state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD)
				++ " where merchant=" ++ ?to_s(Merchant)
				++ " and id=" ++ ?to_s(TicketId)
				++"  and state in(1,3)"; %% checked, unused
			1 ->
			    "update w_ticket_custom set state=" ++ ?to_s(?TICKET_STATE_CHECKED)
				++ " where merchant=" ++ ?to_s(Merchant)
				++ " and id=" ++ ?to_s(TicketId)
				++ " and state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD) %% 
		    end,
		?sql_utils:execute(write, Sql1, TicketId) 
	end,

    {reply, Reply, State};

handle_call({discard_custom_all, Merchant, Conditions, Mode, Active}, _From, State) ->
    ?DEBUG("discard_custom_all: merchant ~p, Conditions ~p, Mode ~p, Active ~p",
	   [Merchant, Conditions, Mode, Active]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, ticket_condition(custome, Conditions, [])), 
    Sql = "update w_ticket_custom set state=" ++ ?to_s(?CUSTOM_TICKET_STATE_DISCARD) 
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case Active of
	       0 -> case ?sql_utils:time_condition(StartTime, <<"mtime">>, ge) of
			[] -> [];
			T1 -> " and " ++ T1
		    end ++ case ?sql_utils:time_condition(EndTime, <<"mtime">>, less) of
			       [] -> [];
			       T2 -> " and " ++ T2
			   end;
	       1 -> ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime) ;
	       2 ->
		   case ?sql_utils:time_condition(StartTime, <<"ctime">>, ge) of
		       [] -> [];
		       T1 -> " and " ++ T1
		   end ++ case ?sql_utils:time_condition(EndTime, <<"ctime">>, less) of
			      [] -> [];
			      T2 -> " and " ++ T2
			  end
	   end,
    
    Reply = ?sql_utils:execute(write, Sql, Merchant), 
    {reply, Reply, State};


handle_call({ticket_by_retailer, Merchant, RetailerId}, _From, State) ->
    Sql = "select id, batch, balance, retailer, sid, state from w_ticket"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and retailer=" ++ ?to_s(RetailerId)
	++ " and state=" ++ ?to_s(?CHECKED), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({ticket_by_promotion, Merchant, RetailerId, ConsumeShop}, _From, State) ->
    Sql = "select a.id"
	", a.plan"
	", a.batch"
	", a.balance"
	", a.retailer"
	", a.in_shop"
	", a.stime"
	", a.etime"
	", a.state"

	", b.ubalance"
	", b.name"
	", b.ishop" 
	" from w_ticket_custom a" 
	" left join w_ticket_plan b on a.merchant=b.merchant and a.plan=b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ " and a.retailer=" ++ ?to_s(RetailerId)
	++ " and a.state=" ++ ?to_s(?CHECKED),
    Reply = 
	case ?sql_utils:execute(read, Sql) of
	    {ok, []} -> {ok, []};
	    {ok, Tickets} ->
		NewTickets = 
		    lists:filter(
		      fun({T}) ->
			      IShop = ?v(<<"ishop">>, T),
			      Plan = ?v(<<"plan">>, T),
			      Plan =/= ?INVALID_OR_EMPTY
				  andalso
				  case IShop of
				      ?YES ->
					  %% ?DEBUG("same_shop ~p ~p", [?v(<<"in_shop">>, T), ConsumeShop]),
					  ?v(<<"in_shop">>, T) =:= ConsumeShop;
				      ?NO ->
					  true
			      end
		      end, Tickets),
		
		%% ?DEBUG("NewTickets ~p", [NewTickets]),
		%% CurrentDate = {2019, 7, 26},
		CurrentDate = ?utils:current_date(), 
		{ok,
		 lists:foldr(
		   fun({T}, Acc) ->
			   STime = ?v(<<"stime">>, T),
			   ETime = ?v(<<"etime">>, T),
			   case ?utils:ecompare_date(date, CurrentDate, STime) of
			       true ->
				   case ETime =:= ?TICKET_DATE_UNLIMIT of
				       true -> [{T}|Acc];
				       false ->
					   case ?utils:compare_date(date, CurrentDate, ETime) of 
					       true -> Acc;
					       false -> [{T}|Acc]
					   end
				   end;
			       false ->
				   Acc
			   end
		  end, [], NewTickets)};
	    Error -> Error
	end, 
    {reply, Reply, State};

handle_call({ticket_by_batch, Merchant, {Batchs, Mode, Custom}}, _From, State) ->
    ?DEBUG("ticket_by_batch: merchant ~p, batchs ~p, mode ~p, custom ~p",
	   [Merchant, Batchs, Mode, Custom]),
    Sql = case Custom of
	      ?CUSTOM_TICKET ->
		  "select id, batch, balance, state from w_ticket_custom";
	      ?SCORE_TICKET ->
		  "select id, batch, balance, retailer, sid, state from w_ticket"
	  end
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, {<<"batch">>, Batchs})
	%% ++ " and batch=" ++ ?to_s(Batch)
	++ case Mode of
	       ?TICKET_CHECKED -> " and state=" ++ ?to_s(?TICKET_STATE_CHECKED);
	       ?TICKET_ALL -> []
	   end,
    
    Reply = case Custom of
		?SCORE_TICKET ->
		    ?sql_utils:execute(s_read, Sql);
		?CUSTOM_TICKET ->
		    ?sql_utils:execute(read, Sql)
	    end,
    {reply, Reply, State};

handle_call({ticket_by_sale, Merchant, Sale, Custom}, _From, State) -> 
    Sql = case Custom of
	      ?CUSTOM_TICKET ->
		  "select id, batch, balance, state from w_ticket_custom";
	      ?SCORE_TICKET ->
		  "select id, batch, balance, retailer, sid, state from w_ticket"
	  end
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and sale_rsn=\'" ++ ?to_s(Sale) ++ "\'"
	++ " and state=" ++ ?to_s(?TICKET_STATE_CONSUMED),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
	
handle_call({total_retailer, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_retailer: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),

    Month = ?v(<<"month">>, Conditions, []),
    Date  = ?v(<<"date">>, Conditions, []),
    MConsume = ?v(<<"mconsume">>, Conditions, []),
    MScore = ?v(<<"mscore">>, Conditions, []),
    LScore = ?v(<<"lscore">>, Conditions, []),
    SortConditions = lists:keydelete(
		       <<"mconsume">>, 1,
		       lists:keydelete(
			 <<"lscore">>, 1,
			 lists:keydelete(
			   <<"mscore">>, 1,
			   lists:keydelete(
			     <<"month">>, 1,
			     lists:keydelete(<<"date">>, 1, NewConditions))))),
    
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
	++ case MConsume of
	       [] -> [];
	       _ ->
		   " and consume>=" ++ ?to_s(MConsume)
	   end
	++ case MScore of
	       [] -> [];
	       _ ->
		   " and score>=" ++ ?to_s(MScore)
	   end
	++ case LScore of
	       [] -> [];
	       _ ->
		   " and score<=" ++ ?to_s(LScore)
	   end
	++ ?sql_utils:condition(proplists, SortConditions),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


handle_call({total_consume, Mode, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("total_consume: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    FilterConditions = filter_condition(consume, NewConditions),
    SortCondtions = sort_condition(consume, NewConditions),

    Sql = 
	case Mode of
	    0 ->
		"select count(*) as total" 
		    " from "
		    " (select a.retailer, a.shop, a.consume"
		    " from "
		    "(select merchant"
		    ", retailer"
		    ", shop, SUM(should_pay - verificate) as consume"
		    " from" ++ ?table:t(sale_new, Merchant, UTable)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ ?sql_utils:condition(proplists, FilterConditions)
		    ++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
		    ++ " group by retailer, shop) a"
		    ++ case SortCondtions of
			   [] -> [];
			   _ -> " where " ++ SortCondtions
		       end ++ ") b";
	    1 ->
		"select count(*) as total"
		    " from "
		    "(select count(*)"
		    ", retailer"
		    " from " ++ ?table:t(sale_new, Merchant, UTable)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and type=0"
		    ++ ?sql_utils:condition(proplists, FilterConditions)
		    ++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
		    ++ " group by retailer) a"
	end,
    
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
    MConsume = ?v(<<"mconsume">>, Conditions, []),
    MScore = ?v(<<"mscore">>, Conditions, []),
    LScore = ?v(<<"lscore">>, Conditions, []),
    SortConditions = lists:keydelete(
		       <<"a.mconsume">>, 1,
		       lists:keydelete(
			 <<"a.lscore">>, 1,
		       lists:keydelete(
			 <<"a.mscore">>, 1,
			 lists:keydelete(
			   <<"a.month">>, 1,
			   lists:keydelete(
			     <<"a.date">>, 1, NewConditions))))), 
    
    Sql = "select a.id"
	", a.merchant" 
	", a.name"
	", a.intro as intro_id"
	", a.level"
	", a.card"
	", a.id_card"
	", a.birth"
	", a.lunar as lunar_id"
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
	++ case MConsume of
	       [] -> [];
	       _ ->
		   " and a.consume>=" ++ ?to_s(MConsume)
	   end 
	++ case MScore of
	       [] -> [];
	       _ ->
		   " and a.score>=" ++ ?to_s(MScore)
	   end
	++ case LScore of
	       [] -> [];
	       _ ->
		   " and a.score<=" ++ ?to_s(LScore)
	   end 
    %% ++ " and a.deleted=" ++ ?to_s(?NO)
	++ ?sql_utils:condition(page_desc, {Order, Sort}, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({filter_consume, Mode, Merchant, UTable, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_consume:merchant ~p, conditions ~p, page ~p", [Merchant, Conditions, CurrentPage]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    FilterConditions = filter_condition(consume, NewConditions),
    SortCondtions = sort_condition(consume, NewConditions, <<"a.">>),
    
    Sql = case Mode of
	      0 ->
		  "select a.retailer_id"
		      ", a.total"
		      ", a.score"
		      ", a.consume"
		      ", a.draw"
		      ", a.ticket"

		      ", b.name as retailer"
		      ", b.shop as shop_id"
		      ", b.mobile as phone"
		      ", b.type as type_id"
		      ", b.balance"

		      " from ("
		      "select retailer as retailer_id"
		      ", shop as shop_id"
		      ", SUM(total) as total"
		      ", SUM(score) as score"
		      ", SUM(should_pay - verificate) as consume"
		      ", SUM(withDraw) as draw"
		      ", SUM(ticket) as ticket" 
		  %% " from w_sale"
		      " from" ++ ?table:t(sale_new, Merchant, UTable)
		      ++ " where merchant=" ++ ?to_s(Merchant)
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
		      ++ ?sql_utils:condition(page_desc, {use_consume, 0}, CurrentPage, ItemsPerPage); 
	      1 ->
		  "select a.amount"
		      ", a.retailer as retailer_id"
		      ", b.mobile as phone"
		      ", b.name as retailer"
		      ", b.shop as shop_id"
		      ", b.type as type_id"
		      " from "
		      "(select count(*) as amount"
		      ", retailer"
		      " from " ++ ?table:t(sale_new, Merchant, UTable)
		      ++ " where merchant=" ++ ?to_s(Merchant)
		      ++ " and type=0"
		      ++ ?sql_utils:condition(proplists, FilterConditions)
		      ++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime)
		      ++ " group by retailer) a"
		      ++ " left join w_retailer b on a.retailer=b.id"
		      ++ ?sql_utils:condition(page_desc, {use_amount, 0}, CurrentPage, ItemsPerPage)
	  end,
    
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
	", a.cbalance, a.ctime, a.sbalance, a.cash, a.card, a.wxin"
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
    %% ++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
	++ ?sql_utils:condition(page_desc, {use_datetime, 0}, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({total_ticket_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_ticket_detail: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Shop = ?v(<<"shop">>, NewConditions),
    Sql = case Shop of
	      undefined ->
		  "select count(*) as total"
		      ", sum(balance) as balance"
		      " from w_ticket"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ ?sql_utils:condition(proplists, lists:keydelete(<<"shop">>, 1, NewConditions))
		      ++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime);
	      Shop ->
		  "select count(*) as total"
		      ", sum(x.balance) as balance"
		      " from ("
		      "select a.id, a.retailer, a.balance, b.shop from w_ticket a"
		      " inner join ("
		      " select id, name, mobile, shop, merchant from w_retailer"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and shop=" ++ ?to_s(Shop) ++ ") b"
		      " on a.merchant=b.merchant and a.retailer=b.id"
		      " where a.merchant=" ++ ?to_s(Merchant)
		      ++ ?sql_utils:condition(proplists, lists:keydelete(<<"shop">>, 1, NewConditions))
		      ++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime) ++ ") x" 
	  end, 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_ticket_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_ticket_detail: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    CorrectCondition = ticket_condition(score, Conditions, []),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, CorrectCondition),
    %% Shop = ?v(<<"a.shop">>, Conditions),
    Sql = "select a.id"
	", a.batch"
	", a.sid"
	", a.balance"
	", a.retailer_id"
	", a.state"
	", a.remark"
	", a.entry_date"
	", a.retailer"
	", a.shop_id"
	", a.mobile"
	", a.score"
	" from ("
	"select x.id"
	", x.merchant"
	", x.batch"
	", x.sid"
	", x.balance"
	", x.retailer as retailer_id" 
	", x.state"
	", x.remark"
	", x.entry_date"
	
	", b.name as retailer"
	", b.shop as shop_id"
	", b.mobile"
	", c.name as score"
	
	" from w_ticket x"
	" left join w_retailer b on x.retailer=b.id"
	" left join w_score c on x.sid=c.id"
	" where x.merchant=" ++ ?to_s(Merchant) ++ ") a"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_phone, Merchant, {Mode, Phone, Shops}}, _From, #state{prompt=Prompt} = State) ->
    ?DEBUG("match_phone: merchant ~p, Mode ~p, Phone ~p, shops ~p, state ~p",
	   [Merchant, Mode, Phone, Shops, State]),

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
	", lunar as lunar_id"
	", level"
	", card"
	", py"
	", shop as shop_id"
	", draw as draw_id"
	", type as type_id"
	", balance"
	", score"
	", mobile"
	", comment"
	" from w_retailer"
	
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, [{<<"shop">>, Shops}])
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

handle_call({total_custom_ticket_detail, Mode, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_custom_ticket_detail: mode ~p, merchant ~p, conditions ~p",
	   [Mode, Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, ticket_condition(custome, Conditions, [])),
    
    Sql = "select count(*) as total"
	", sum(balance) as balance"
	" from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case Mode of
	       0 -> case ?sql_utils:time_condition(StartTime, <<"mtime">>, ge) of
			[] -> [];
			T1 -> " and " ++ T1
		    end ++ case ?sql_utils:time_condition(EndTime, <<"mtime">>, less) of
			       [] -> [];
			       T2 -> " and " ++ T2
			   end;
	       1 -> ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime) ;
	       2 ->
		   case ?sql_utils:time_condition(StartTime, <<"ctime">>, ge) of
		       [] -> [];
		       T1 -> " and " ++ T1
		   end ++ case ?sql_utils:time_condition(EndTime, <<"ctime">>, less) of
			      [] -> [];
			      T2 -> " and " ++ T2
			  end 
	   end,

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_custom_ticket_detail, Mode, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_custom_ticket_detail: mode ~p, merchant ~p, conditions ~p, page ~p",
	   [Mode, Merchant, Conditions, CurrentPage]), 
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, ticket_condition(custome, Conditions, [])),
    ?DEBUG("NewConditions ~p", [NewConditions]),
    Sql = 
	"select a.id"
	", a.batch"
	", a.plan as plan_id"
	", a.balance"
	", a.employee as employee_id"
	", a.retailer as retailer_id" 
	", a.state"
	", a.mtime"
	", a.ctime"
	", a.stime"
	", a.etime"
	", a.in_shop as p_shop_id"
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
	++ ?sql_utils:condition(proplists, ?utils:correct_condition(<<"a.">>, NewConditions))
	++ case Mode of
	       0 -> case ?sql_utils:time_condition(StartTime, <<"a.mtime">>, ge) of 
			[] -> [];
			T1 -> " and " ++ T1
		    end ++ case ?sql_utils:time_condition(EndTime, <<"a.mtime">>, less) of
			       [] -> [];
			       T2 -> " and " ++ T2
			   end;
	       1 ->
		   ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime);
	       2 ->
		   case ?sql_utils:time_condition(StartTime, <<"a.ctime">>, ge) of
		       [] -> [];
		       T1 -> " and " ++ T1
		   end ++ case ?sql_utils:time_condition(EndTime, <<"a.ctime">>, less) of
			      [] -> [];
			      T2 -> " and " ++ T2
			  end
	   end
	++ ?sql_utils:condition(page_desc, {use_ticket, Mode, 0}, CurrentPage, ItemsPerPage),
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
	", a.csn"
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
	++ ?sql_utils:condition(proplists, NewConditions ++ [{<<"a.deleted">>, 0}])
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% threshold card good
handle_call({list_threshold_card_good, Merchant, Shops}, _From, State) ->
    Sql = "select id"
	", name"
	", tag_price"
	", oil"
	", shop as shop_id from w_card_good"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Shops),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_threshold_card_sale, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_threshold_card_sale: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    CorrectCondition = correct_condition(card_sale, NewConditions, []),
    Sql = "select count(*) as total"
	", sum(amount) as amount"
	", sum(oil) as oil"
	" from w_card_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, CorrectCondition)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


handle_call({filter_threshold_card_sale, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_threshold_card_sale: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    CorrectCondition = correct_condition(card_sale, Conditions, []),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, CorrectCondition),
    
    Sql = 
	"select a.id"
	", a.rsn"
	", a.employee as employee_id"
	", a.retailer as retailer_id" 
	", a.card as card_id"
	", a.amount"
	", a.oil"
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

handle_call({total_threshold_card_sale_note, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_threshold_card_sale_note: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    CorrectCondition = correct_condition(card_sale, NewConditions, []),
    Sql = "select count(*) as total"
	", sum(amount) as amount"
	", sum(oil * amount) as oil"
	" from w_card_sale_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, CorrectCondition)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_threshold_card_sale_note, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_threshold_card_sale_note: merchant ~p, conditions ~p, page ~p",
	   [Merchant, Conditions, CurrentPage]),
    CorrectCondition = correct_condition(card_sale, Conditions, []), 
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, CorrectCondition),
    Sql =
	"select a.id"
	", a.rsn"
	", a.employee_id"
	", a.retailer_id" 
	", a.card_id"
	", a.cid"
	", a.good_id"
	", a.amount"
	", a.oil"
	", a.shop_id"
	", a.entry_date"

	", b.name as retailer"
	", b.mobile" 
	", c.rule as rule_id" 
	", d.name as cname"
	
	" from("
	"select a.id"
	", a.rsn"
	", a.employee as employee_id"
	", a.retailer as retailer_id" 
	", a.card as card_id"
	", a.good as good_id"
	", a.cid"
	", a.amount"
	", a.oil"
	", a.shop as shop_id"
	", a.entry_date"

	%% ", c.name as retailer"
	%% ", c.mobile" 
	%% ", d.rule as rule_id" 
	%% ", e.name as cname"

	" from w_card_sale_detail a, w_card_sale b"
	" where a.rsn=b.rsn and a.merchant=b.merchant and a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ") a"
	
	" left join w_retailer b on b.id=a.retailer_id"
	" left join w_card c on c.id=a.card_id"
	" left join w_charge d on d.id=a.cid"

	%% " where a.rsn=b.rsn and a.merchant=b.merchant and a.merchant=" ++ ?to_s(Merchant)
	%% ++ ?sql_utils:condition(proplists, NewConditions)
	%% ++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
    
handle_call({add_threshold_card_good, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_threshold_card_good: merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name = ?v(<<"name">>, Attrs),
    Shop = ?v(<<"shop">>, Attrs),
    TagPrice = ?v(<<"price">>, Attrs),
    Oil = ?v(<<"oil">>, Attrs, 0),
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
		    Sql = "insert into w_card_good("
			"name"
			", tag_price"
			", oil"
			", merchant"
			", shop"
			", entry_date) values("
			++ "\'" ++ ?to_s(Name) ++ "\',"
			++ ?to_s(TagPrice) ++ ","
			++ ?to_s(Oil) ++ ","
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

handle_call({update_threshold_card_good, Merchant, GoodId, Attrs}, _From, State) ->
    ?DEBUG("update_threshold_card_good: merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name = ?v(<<"name">>, Attrs),
    Shop = ?v(<<"shop">>, Attrs),
    TagPrice = ?v(<<"price">>, Attrs),
    Oil = ?v(<<"oil">>, Attrs),
    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(tag_price, float, TagPrice)
	++ ?utils:v(oil, float, Oil),
    Reply = 
	case Updates of
	    [] -> {ok, GoodId};
	    _ ->
		Sql1 = "update w_card_good set " ++ ?utils:to_sqls(proplists, comma, Updates)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id=" ++ ?to_s(GoodId),

		?sql_utils:execute(write, Sql1, GoodId)
	end,
    {reply, Reply, State};

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
	", a.oil"
	", a.shop as shop_id" 
	", a.entry_date" 
	", b.name as shop"

	" from w_card_good a"
	" left join shops b on a.shop=b.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_threshold_card, Merchant, Card}, _Frobm, State) ->
    ?DEBUG("get_threshold_card: Merchant ~p, Card ~p", [Merchant, Card]),
    Sql = "select id, csn, retailer, rule, ctime, edate from w_card"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Card),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({delete_threshold_card, Merchant, CardAttr}, _Frobm, State) ->
    ?DEBUG("delete_threshold_card: Merchant ~p, CardAttr ~p", [Merchant, CardAttr]),
    CardId = ?v(<<"id">>, CardAttr),
    CardNo = ?v(<<"csn">>, CardAttr),
    Retailer = ?v(<<"retailer">>, CardAttr),
    Sql1 = "update w_card set deleted=1 where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(CardId)
	++ " and retailer=" ++ ?to_s(Retailer), 
    Reply = 
	case CardNo =:= <<"-1">> of
	    true -> ?sql_utils:execute(write, Sql1, CardId);
	    false ->
		Sql2 = "update w_child_card set deleted=1 where merchant=" ++ ?to_s(Merchant)
		    ++ " and csn=\'" ++ ?to_s(CardNo) ++ "\'"
		    ++ " and retailer=" ++ ?to_s(Retailer), 
		?sql_utils:execute(transaction, [Sql1, Sql2], CardId)
	end,
    {reply, Reply, State};

handle_call({threshold_card_consume, Merchant, CardId, Attrs}, _From, State) ->
    ?DEBUG("threshold_card_consume: merchant ~p, card ~p, attrs ~p", [Merchant, CardId, Attrs]),
    CardSN   = ?v(<<"csn">>, Attrs),
    CGoods   = ?v(<<"cgoods">>, Attrs),
    Oil      = ?v(<<"oil">>, Attrs, 0),
    ChargeId = ?v(<<"charge">>, Attrs),
    Retailer = ?v(<<"retailer">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    %% Price    = ?v(<<"tag_price">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),
    
    Sql = "select id, merchant, retailer, rule, ctime, edate from w_card"
	" where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and cid=" ++ ?to_s(ChargeId),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    {reply, {error, ?err(threshold_card_not_exist, CardId)}, State};
	{ok, Card} ->
	    case ?v(<<"rule">>, Card) of
		?THEORETIC_CHARGE ->
		    LeftCount = ?v(<<"ctime">>, Card, 0),
		    Count    = ?v(<<"count">>, Attrs), 
		    case LeftCount =< 0 orelse LeftCount < Count of
			true ->
			    {reply, {error, ?err(threshold_card_not_enought_count, CardId)}, State};
			false -> 
			    SN = lists:concat(
				   ["M-", ?to_i(Merchant),
				    "-S-", ?to_i(Shop),
				    "-", ?inventory_sn:sn(threshold_card_sale, Merchant)]),

			    Datetime = ?utils:current_time(format_localtime),

			    Sql1 = ["update w_card set ctime=ctime-" ++ ?to_s(Count)
				    ++ " where id=" ++ ?to_s(CardId)
				    ++ " and merchant=" ++ ?to_s(Merchant)
				    ++ " and rule=" ++ ?to_s(?THEORETIC_CHARGE),

				    "insert into w_card_sale(rsn"
				    ", employee"
				    ", retailer"
				    ", card"
				    ", cid"
				    ", amount"
				    ", oil"
				    ", merchant"
				    ", shop"
				    ", comment"
				    ", entry_date) values("
				    ++ "\'" ++ ?to_s(SN) ++ "\',"
				    ++ "\'" ++ ?to_s(Employee) ++ "\',"
				    ++ ?to_s(Retailer) ++ ","
				    ++ ?to_s(CardId) ++ ","
				    ++ ?to_s(ChargeId) ++ "," 
				    ++ ?to_s(Count) ++ ","
				    ++ ?to_s(Oil) ++ "," 
				    ++ ?to_s(Merchant) ++ ","
				    ++ ?to_s(Shop) ++ ","
				    ++ "\'" ++ ?to_s(Comment) ++ "\',"
				    ++ "\'" ++ Datetime ++ "\')"],

			    Sql2 =
				lists:foldr(
				  fun({struct, Good}, Acc) ->
					  ["insert into w_card_sale_detail(rsn"
					   ", employee"
					   ", retailer"
					   ", card"
					   ", cid"

					   ", good"
					   ", amount" 
					   ", tag_price"
					   ", oil"

					   ", merchant"
					   ", shop"
					   ", entry_date) values("
					   ++ "\'" ++ ?to_s(SN) ++ "\',"
					   ++ "\'" ++ ?to_s(Employee) ++ "\',"
					   ++ ?to_s(Retailer) ++ ","
					   ++ ?to_s(CardId) ++ ","
					   ++ ?to_s(ChargeId) ++ ","

					   ++ ?to_s(?v(<<"g">>, Good)) ++ ","
					   ++ ?to_s(?v(<<"c">>, Good)) ++ ","
					   ++ ?to_s(?v(<<"p">>, Good)) ++ ","
					   ++ ?to_s(?v(<<"o">>, Good)) ++ ","

					   ++ ?to_s(Merchant) ++ ","
					   ++ ?to_s(Shop) ++ ","
					   ++ "\'" ++ Datetime ++ "\')",

					   "update w_child_card set "
					   "ctime=ctime-" ++ ?to_s(?v(<<"c">>, Good))
					   ++ " where merchant=" ++ ?to_s(Merchant)
					   ++ " and retailer=" ++ ?to_s(Retailer)
					   ++ " and csn=\'" ++ ?to_s(CardSN) ++ "\'" 
					   ++ " and good=" ++ ?to_s(?v(<<"g">>, Good)) |Acc]
				  end, [], CGoods),
			    case ?sql_utils:execute(transaction, Sql1 ++ Sql2, SN) of
				{ok, SN} ->
				    {reply, {ok, SN, LeftCount - Count, ?INVALID_OR_EMPTY}, State};
				_Error ->
				    _Error
			    end
		    end;
		?BALANCE_LIMIT_CHARGE  ->
		    LeftBalance = ?v(<<"ctime">>, Card, 0),
		    FBalance    = ?v(<<"fbalance">>, Attrs, 0),
		    case LeftBalance =< 0 orelse LeftBalance < FBalance of
			true ->
			    {reply, {error, ?err(balance_card_not_enought_money, CardId)}, State};
			false ->
			    ExpireDate = ?v(<<"edate">>, Card),
			    case ?utils:compare_date(date, current_date(), ExpireDate) of
				true ->
				    {reply, {error, ?err(balance_card_expire, CardId)}, State};
				false -> 
				    SN = lists:concat(
					   ["M-", ?to_i(Merchant),
					    "-S-", ?to_i(Shop),
					    "-", ?inventory_sn:sn(threshold_card_sale, Merchant)]),
				    Datetime = ?utils:current_time(format_localtime),
				    
				    Sql1 = ["update w_card set ctime=ctime-" ++ ?to_s(FBalance)
					    ++ " where id=" ++ ?to_s(CardId)
					    ++ " and merchant=" ++ ?to_s(Merchant)
					    ++ " and rule=" ++ ?to_s(?BALANCE_LIMIT_CHARGE),

					    %% "update w_retailer set balance=balance-" ++ ?to_s(FBalance)
					    %% ++ " where id=" ++ ?to_s(Retailer)
					    %% ++ " and merchant=" ++ ?to_s(Merchant),

					    "insert into w_card_sale(rsn"
					    ", employee"
					    ", retailer"
					    ", card"
					    ", cid"
					    ", amount"
					    ", oil"
					    ", merchant"
					    ", shop"
					    ", comment"
					    ", entry_date) values("
					    ++ "\'" ++ ?to_s(SN) ++ "\',"
					    ++ "\'" ++ ?to_s(Employee) ++ "\',"
					    ++ ?to_s(Retailer) ++ ","
					    ++ ?to_s(CardId) ++ ","
					    ++ ?to_s(ChargeId) ++ "," 
					    ++ ?to_s(FBalance) ++ ","
					    ++ ?to_s(Oil) ++ ","
					    ++ ?to_s(Merchant) ++ ","
					    ++ ?to_s(Shop) ++ ","
					    ++ "\'" ++ ?to_s(Comment) ++ "\',"
					    ++ "\'" ++ Datetime ++ "\')"],

				    Sql2 =
					lists:foldr(
					  fun({struct, Good}, Acc) ->
						  ["insert into w_card_sale_detail(rsn"
						   ", employee"
						   ", retailer"
						   ", card"
						   ", cid"

						   ", good"
						   ", amount" 
						   ", tag_price"
						   ", oil"

						   ", merchant"
						   ", shop"
						   ", entry_date) values("
						   ++ "\'" ++ ?to_s(SN) ++ "\',"
						   ++ "\'" ++ ?to_s(Employee) ++ "\',"
						   ++ ?to_s(Retailer) ++ ","
						   ++ ?to_s(CardId) ++ ","
						   ++ ?to_s(ChargeId) ++ ","

						   ++ ?to_s(?v(<<"g">>, Good)) ++ ","
						   ++ ?to_s(?v(<<"c">>, Good)) ++ ","
						   ++ ?to_s(?v(<<"p">>, Good)) ++ ","
						   ++ ?to_s(?v(<<"o">>, Good)) ++ ","

						   ++ ?to_s(Merchant) ++ ","
						   ++ ?to_s(Shop) ++ ","
						   ++ "\'" ++ Datetime ++ "\')"] ++ Acc
					  end, [], CGoods),

				    case ?sql_utils:execute(transaction, Sql1 ++ Sql2, SN) of
					{ok, SN} ->
					    {reply,
					     {ok, SN, LeftBalance - FBalance, ?INVALID_OR_EMPTY},
					     State};
					_Error ->
					    _Error
				    end
			    end
		    end 
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({expire_card_consume, Merchant, CardId, Attrs}, _From, State) ->
    ?DEBUG("threshold_card_consume: merchant ~p, card ~p, attrs ~p", [Merchant, CardId, Attrs]),
    CGoods   = ?v(<<"cgoods">>, Attrs),
    Count    = ?v(<<"count">>, Attrs),
    Oil      = ?v(<<"oil">>, Attrs, 0),
    ChargeId = ?v(<<"charge">>, Attrs),
    Retailer = ?v(<<"retailer">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    %% Price    = ?v(<<"tag_price">>, Attrs),
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

		    Datetime = ?utils:current_time(format_localtime),
		    
		    Sql1 = "insert into w_card_sale(rsn"
			", employee"
			", retailer"
			", card"
			", cid"
			", amount"
			", oil"
			", merchant"
			", shop"
			", comment"
			", entry_date) values("
			++ "\'" ++ ?to_s(SN) ++ "\',"
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(CardId) ++ ","
			++ ?to_s(ChargeId) ++ ","
			++ ?to_s(Count) ++ ","
			++ ?to_s(Oil) ++ ","
		    %%++ ?to_s(CGood) ++ ","
		    %% ++ ?to_s(Price) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ "\'" ++ ?to_s(Comment) ++ "\',"
			++ "\'" ++ Datetime ++ "\')",

		    Sql2 =
			lists:foldr(
			  fun({struct, Good}, Acc) ->
				  ["insert into w_card_sale_detail(rsn"
				   ", employee"
				   ", retailer"
				   ", card"
				   ", cid"

				   ", good"
				   ", amount" 
				   ", tag_price"
				   ", oil"

				   ", merchant"
				   ", shop"
				   ", entry_date) values("
				   ++ "\'" ++ ?to_s(SN) ++ "\',"
				   ++ "\'" ++ ?to_s(Employee) ++ "\',"
				   ++ ?to_s(Retailer) ++ ","
				   ++ ?to_s(CardId) ++ ","
				   ++ ?to_s(ChargeId) ++ ","

				   ++ ?to_s(?v(<<"g">>, Good)) ++ ","
				   ++ ?to_s(?v(<<"c">>, Good)) ++ ","
				   ++ ?to_s(?v(<<"p">>, Good)) ++ ","
				   ++ ?to_s(?v(<<"o">>, Good)) ++ ","

				   ++ ?to_s(Merchant) ++ ","
				   ++ ?to_s(Shop) ++ ","
				   ++ "\'" ++ Datetime ++ "\')"|Acc]
			  end, [], CGoods),
		    
		    case ?sql_utils:execute(transaction, [Sql1] ++ Sql2, SN) of
			{ok, SN} ->
			    {reply, {ok, SN, ?INVALID_OR_EMPTY, ExpireDate}, State};
			_Error ->
			    _Error
		    end 
	    end; 
	Error ->
	    {reply, Error, State}
    end;

handle_call({cancel_card_consume, Merchant, Card, Attrs}, _From, State) ->
    ?DEBUG("cancel_card_consume: merchant ~p, card ~p, attrs ~p", [Merchant, Card, Attrs]),
    RSN = ?v(<<"rsn">>, Attrs),
    Sql = "delete from w_card_sale where merchant=" ++ ?to_s(Merchant)
	++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'",
    Reply = 
	case ?v(<<"rule">>, Attrs) of
	    ?THEORETIC_CHARGE ->
		Count = ?v(<<"count">>, Attrs),
		Sqls = ["update w_card set ctime=ctime+" ++ ?to_s(Count)
			++ " where merchant="++ ?to_s(Merchant)
			++ " and id=" ++ ?to_s(Card), Sql],
		?sql_utils:execute(transaction, Sqls, Card);
	    _ ->
		?sql_utils:execute(write, Sql, Card)
	end,
    %% ?DEBUG("reply ~p", [Reply]),
    {reply, Reply, State};

handle_call({list_threshold_child_card, Merchant, Retailer, CardSN}, _From, State) ->
    ?DEBUG("list_threshold_child_card: merchant ~p, retailer ~p, card ~p",
	   [Merchant, Retailer, CardSN]),
    Reply =
	case CardSN of
	    ?INVALID_OR_EMPTY ->
		{ok, []};
	    _ ->
		Sql = 
		    "select id, csn, retailer, good, ctime, merchant from w_child_card"
		    " where merchant=" ++ ?to_s(Merchant)
		    ++ " and retailer=" ++ ?to_s(Retailer) 
		    ++ " and csn=\'" ++ ?to_s(CardSN) ++ "\'",
		?sql_utils:execute(read, Sql)
	end,
    {reply, Reply, State};

handle_call({update_threshold_card_expire, Merchant, Card, Expire}, _From, State) ->
    ?DEBUG("update_threshold_card_expire: merchant ~p, card ~p, expire ~p", [Merchant, Card, Expire]),

    Sql = "update w_card set edate=\'" ++ ?to_s(Expire) ++ "\'"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Card),
    
    Reply = ?sql_utils:execute(write, Sql, Card),
    {reply, Reply, State};
    

handle_call({add_gift, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_gift: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Code = ?v(<<"code">>, Attrs),
    Name = ?v(<<"name">>, Attrs),
    OrgPrice = ?v(<<"org_price">>, Attrs, 0),
    TagPrice = ?v(<<"tag_price">>, Attrs, 0),
    Count = ?v(<<"count">>, Attrs),
    Pinyin = ?v(<<"py">>, Attrs, []),
    Rule = ?v(<<"rule">>, Attrs),
    Score = ?v(<<"score">>, Attrs),
    Sql0 = "select id, code, name from w_gift"
	" where code=" ++ ?to_s(Code)
	++ " and merchant=" ++ ?to_s(Merchant),
    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql1 = "insert into w_gift(code"
		    ", name"
		    ", py"
		    ", rule"
		    ", score"
		    ", org_price"
		    ", tag_price"
		    ", total"
		    ", merchant"
		    ", entry_date) values("
		    ++ "\'" ++ ?to_s(Code) ++ "\',"
		    ++ "\'" ++ ?to_s(Name) ++ "\',"
		    ++ "\'" ++ ?to_s(Pinyin) ++ "\',"
		    ++ ?to_s(Rule) ++ ","
		    ++ ?to_s(Score) ++ ","
		    ++ ?to_s(OrgPrice) ++ ","
		    ++ ?to_s(TagPrice) ++ ","
		    ++ ?to_s(Count) ++ ","
		    ++ ?to_s(Merchant) ++ ","
		    ++ "\'" ++ ?to_s(?utils:current_time(localdate)) ++ "\')",
		?sql_utils:execute(insert, Sql1); 
	    {ok, _Gift} ->
		{error, ?err(retailer_gift_exist, Code)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({update_gift, Merchant, GiftId, Attrs}, _From, State) ->
    ?DEBUG("update_gift: merchant ~p, GiftId ~p, Attrs ~p", [Merchant, GiftId, Attrs]),
    Updates = ?utils:v(name, string, ?v(<<"name">>, Attrs))
	++ ?utils:v(org_price, float, ?v(<<"org_price">>, Attrs))
	++ ?utils:v(tag_price, float, ?v(<<"tag_price">>, Attrs))
	++ ?utils:v(total, integer, ?v(<<"count">>, Attrs))
	++ ?utils:v(rule, integer, ?v(<<"rule">>, Attrs)) 
	++ ?utils:v(py, string, ?v(<<"py">>, Attrs)),

    Sql = "update w_gift set " ++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(GiftId),
    Reply = ?sql_utils:execute(write, Sql, GiftId),
    {reply, Reply, State}; 

handle_call({exchange_gift, Merchant, Attrs}, _From, State) ->
    ?DEBUG("exchange_gift: merchant ~p, attrs ~p", [Merchant, Attrs]),
    Gift = ?v(<<"gift">>, Attrs),
    Rule = ?v(<<"rule">>, Attrs),
    Retailer = ?v(<<"retailer">>, Attrs),
    Shop = ?v(<<"shop">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    Score = ?v(<<"score">>, Attrs, 0),
    Comment = ?v(<<"comment">>, Attrs, []),
    
    GetRetailerScore =
	fun() ->
		Sql0 = "select id, score, mobile from w_retailer"
		    " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id=" ++ ?to_s(Retailer),
		case ?sql_utils:execute(s_read, Sql0) of
		    {ok, RetailerInfo} ->
			ScoreLive = ?v(<<"score">>, RetailerInfo),
			case ScoreLive >= Score of
			    true -> {ok, ScoreLive};
			    false -> {error, ?err(gift_score_not_enought, ScoreLive)}
			end;
		    Error ->
			Error
		end
	end,

    GenSqls =
	fun() ->
		RSN = lists:concat(
			["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-",
			 ?inventory_sn:sn(gift_draw, Merchant)]), 
		Sqls = ["insert into w_gift_sale(rsn"
			", employee"
			", retailer"
			", gift"
			", score"
			", merchant"
			", shop"
			", comment"
			", entry_date) values("
			++ "\'" ++ ?to_s(RSN) ++ "\',"
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(Gift) ++ ","
			++ ?to_s(Score) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ "\'" ++ ?to_s(Comment) ++ "\',"
			++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')"]

		    ++ case Rule =:= ?GIFT_MONTH_AND_SCORE
			   orelse Rule =:= ?GIFT_SCORE_ONLY
			   orelse Rule =:= ?GIFT_YEAR_AND_SCORE of
			   true ->
			       ["update w_retailer set score=score-" ++ ?to_s(Score)
				++ " where merchant=" ++ ?to_s(Merchant)
				++ " and id=" ++ ?to_s(Retailer)];
			   false ->
			       []
		       end

		    ++ ["update w_gift set total=total-1"
			++ " where merchant=" ++ ?to_s(Merchant)
			++ " and id=" ++ ?to_s(Gift)],
		{Sqls, RSN}
	end,


    StartDrawBy =
	fun(Mode) ->
		{Year, Month, Day} = current_date(),
		{StartDate, EndDate} =
		    case Mode of
			month ->
			    month(begin_to_now, Year, Month, Day);
			year ->
			    year(begin_to_now, Year, Month, Day)
		end,
		Sql = "select a.rsn"
		    ", a.gift"
		    ", a.shop"
		    ", b.rule"
		    " from w_gift_sale a, w_gift b"
		    " where a.gift=b.id"
		    ++ " and a.merchant=" ++ ?to_s(Merchant)
		    ++ " and a.retailer=" ++ ?to_s(Retailer)
		    ++ " and a.gift=" ++ ?to_s(Gift)
		    ++ " and b.rule=" ++ ?to_s(Rule)
		    ++ " and " ++ ?sql_utils:condition(time_with_prfix, StartDate, EndDate), 
		case ?sql_utils:execute(s_read, Sql) of
		    {ok, []} ->
			{Sqls, RSN} = GenSqls(),
			?sql_utils:execute(transaction, Sqls, RSN);
		    {ok, _} ->
			case Mode of
			    month ->
				{error, ?err(gift_drawed_last_month, Gift)};
			    year ->
				{error, ?err(gift_drawed_last_year, Gift)}
			end
		end
	end, 

    Reply = 
	case Rule of
	    ?GIFT_MONTH_AND_SCORE -> %% get by month and score
		case GetRetailerScore() of
		    {ok, _ScoreLive} -> StartDrawBy(month);
		    Error -> Error 
		end; 
	    ?GIFT_SCORE_ONLY  ->
		case GetRetailerScore() of
		    {ok, _ScoreLive} ->
			{Sqls, RSN} = GenSqls(),
			?sql_utils:execute(transaction, Sqls, RSN);
		    Error -> Error 
		end;
	    ?GIFT_MONTH_WITH_FREE ->
		StartDrawBy(month);
	    ?GIFT_YEAR_AND_SCORE ->
		case GetRetailerScore() of
		    {ok, _ScoreLive} -> StartDrawBy(year);
		    Error -> Error 
		end;
	    ?GIFT_YEAR_WITH_FREE ->
		StartDrawBy(year);
	    _ ->
		{error, ?err(gift_rule_undefined, Rule)}
	end,
    {reply, Reply, State};    

handle_call({total_gift, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_gift: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select COUNT(*) as total from w_gift"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_gift, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_gift: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select a.id"
	", a.code"
	", a.name"
	", a.rule as rule_id"
	", a.org_price"
	", a.tag_price"
	", a.total"
	", a.score"
	", a.entry_date"
	" from w_gift a"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:condition(page_desc, {use_id, none, <<"a.">>}, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({total_gift_exchange, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_gift_exchange: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select COUNT(*) as total from w_gift_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, EndTime),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_gift_exchange, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_gift_exchange: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = "select a.id"
	", a.rsn"
	", a.employee as employee_id"
	", a.retailer as retailer_id"
	", a.gift as gift_id"
	", a.score"
	", a.shop as shop_id"
	", a.comment"
	", a.entry_date"

	", b.name as gift"
	", b.score as fscore"
	", b.rule"
	", c.name as retailer"
	", c.mobile"
	
	" from w_gift_sale a"
	" left join w_gift b on a.gift=b.id"
	" left join w_retailer c on a.retailer=c.id"
	
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, {use_id, none, <<"a.">>}, CurrentPage, ItemsPerPage),
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
	++ ?to_s(?CUSTOM_TICKET_STATE_UNUSED) ++ ","
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
	    {Year + 1, (Month + 3) rem 12, day_of_next_month(Year + 1, (Month + 3) rem 12, Date)};
	false ->
	    {Year, Month + 3, day_of_next_month(Year, Month + 3, Date)}
    end;
date_next(?YEAR_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    {Year + 1, Month, Date};

date_next(?HALF_YEAR_UNLIMIT_CHARGE, {Year, Month, Date}) ->
    case Month + 6 > 12 of
	true ->
	    {Year + 1, (Month + 6) rem 12, day_of_next_month(Year + 1, (Month + 6) rem 12, Date)};
	false ->
	    {Year, Month + 6, day_of_next_month(Year, Month + 6, Date)}
    end.


month(begin_to_now, Year, Month, Day) ->
    Start = format_date(Year, Month, 1),
    %% LastDay = calendar:last_day_of_the_month(Year, Month),
    {Hour, Minute, Second} = calendar:seconds_to_time(86399),
    End = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Day, Hour, Minute, Second])),
    {Start, End}.

year(begin_to_now, Year, Month, Day) ->
    Start = format_date(Year, 1, 1),
    %% LastDay = calendar:last_day_of_the_month(Year, Month),
    {Hour, Minute, Second} = calendar:seconds_to_time(86399),
    End = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Day, Hour, Minute, Second])),
    {Start, End}.
    
day_of_next_month(CurrentYear, NextMonth, CurrentDay) ->
    ?DEBUG("CurrentYear ~p, NextMonth ~p, CurrentDay ~p", [CurrentYear, NextMonth, CurrentDay]),
    Days = calendar:last_day_of_the_month(CurrentYear, NextMonth),
    case CurrentDay > Days of
	true -> Days; 
	false -> CurrentDay
    end.

current_date() ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    ?DEBUG("Year ~p, Month ~p, Date ~p", [Year, Month, Date]),
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


search_custome_ticket(_Merchant, [], Success, Failed, AllBalance, AllCount, MinEffect)->
    ?DEBUG("Success ~p, Failed ~p, AllBalance ~p, AllCount ~p, MinEffect ~p",
	   [Success, Failed, AllBalance, AllBalance, MinEffect]),
    {Success, Failed, AllBalance, AllCount, MinEffect};
search_custome_ticket(Merchant, [{struct, Ticket}|T], Success, Failed, AllBalance, AllCount, MinEffect)->
    Plan     = ?v(<<"id">>, Ticket),
    Rule     = ?v(<<"rule">>, Ticket),
    Balance  = ?v(<<"balance">>, Ticket),
    Count    = ?v(<<"count">>, Ticket),
    Effect   = case Rule of
		   0 -> ?v(<<"effect">>, Ticket);
		   1 -> ?utils:diff_date(date, ?v(<<"stime">>, Ticket), current_date())
	       end,
    Expire   = case Rule of
		   0 -> ?v(<<"expire">>, Ticket);
		   1 -> ?utils:diff_date(date, ?v(<<"etime">>, Ticket), ?v(<<"stime">>, Ticket))
	       end,
    
    Batchs   = find_custome_ticket_batch(by_plan, Plan, Success, []),
    Sql = "select id"
	", batch"
	", plan"
	", balance" 
	" from w_ticket_custom"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and plan="  ++ ?to_s(Plan)
	++ " and balance=" ++ ?to_s(Balance)
	++ " and state=" ++ ?to_s(?CUSTOM_TICKET_STATE_UNUSED)
	++" and deleted=0"
	++ case Batchs of
	       [] -> [];
	       _ ->
		   " and batch not in(" ++ string:join(Batchs, ",") ++ ")"
	   end
	++ " order by id"
	++ " limit " ++ ?to_s(Count),

    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    search_custome_ticket(Merchant, [], Success, [Plan|Failed], AllBalance, AllCount, MinEffect);
	{ok, UnusedTickets} ->
	    Searchs = lists:foldr(
			fun({Unused}, Acc) ->
				[{Plan, ?to_s(?v(<<"batch">>, Unused)), Effect, Expire}|Acc]
			end, [], UnusedTickets),
	    search_custome_ticket(
	      Merchant,
	      T,
	      Searchs ++ Success,
	      Failed,
	      AllBalance + Balance,
	      AllCount + Count,
	      case MinEffect > Effect of
		  true -> Effect;
		  false -> MinEffect
	      end)
    end.

find_custome_ticket_batch(by_plan, _Plan, [], Sort) ->
    Sort;
find_custome_ticket_batch(by_plan, Plan, [{P, Batch, _Effext, _Expire}|T], Sort) when Plan =:= P->
    find_custome_ticket_batch(by_plan, Plan, T, [?to_s(Batch)|Sort]);
find_custome_ticket_batch(by_plan, _Plan, _PlanTickets, Sort) ->
    Sort.
	    

sms(promotion, Merchant) ->
    Sql = "select id, mobile from w_retailer where merchant=" ++ ?to_s(Merchant)
	++ " and type!=2 and deleted=0",
    case ?sql_utils:execute(read, Sql) of
	{ok, []} -> ok;
	{ok, Retailers} ->
	    lists:foreach(
	      fun({R}) ->
		      Phone = ?v(<<"mobile">>, R),
		      %% ?DEBUG("Phone ~p", [Phone]),
		      ?notify:sms(promotion, Merchant, Phone)
	      end, Retailers);
	Error -> Error
    end.
		
ticket_condition(custome, [], Acc) ->
    Acc;
ticket_condition(custome, [{<<"ticket_state">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"state">>, Value}|Acc]);
ticket_condition(custome, [{<<"ticket_pshop">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"in_shop">>, Value}|Acc]);
ticket_condition(custome, [{<<"ticket_cshop">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"shop">>, Value}|Acc]);
ticket_condition(custome, [{<<"ticket_plan">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"plan">>, Value}|Acc]);
ticket_condition(custome, [{<<"ticket_batch">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"batch">>, Value}|Acc]);
ticket_condition(custome, [{<<"ticket_employee">>, Value}|T], Acc) ->
    ticket_condition(custome, T, [{<<"employee">>, Value}|Acc]);
ticket_condition(custome, [H|T], Acc) ->
    ticket_condition(custome, T, [H|Acc]);

ticket_condition(score, [], Acc) ->
    Acc;
ticket_condition(score, [{<<"shop">>, Shop}|T], Acc) ->
    ticket_condition(score, T, [{<<"shop_id">>, Shop}|Acc]);
ticket_condition(score, [{<<"retailer">>, Shop}|T], Acc) ->
    ticket_condition(score, T, [{<<"retailer_id">>, Shop}|Acc]);
ticket_condition(score, [H|T], Acc) ->
    ticket_condition(score, T, [H|Acc]).

correct_condition(card_sale, [], Acc) ->
    Acc;
correct_condition(card_sale, [{<<"employ">>, Value}|T], Acc) ->
    correct_condition(card_sale, T, [{<<"employee">>, Value}|Acc]);
correct_condition(card_sale, [H|T], Acc) ->
    correct_condition(card_sale, T, [H|Acc]).


    
