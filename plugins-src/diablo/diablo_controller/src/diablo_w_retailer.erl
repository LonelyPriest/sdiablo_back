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
-export([score/2, score/3]).
-export([filter/4, filter/6]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

retailer(list, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_retailer, Merchant}).

retailer(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_retailer, Merchant, Attrs});
retailer(delete, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_retailer, Merchant, RetailerId});
retailer(get, Merchant, RetailerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_retailer, Merchant, RetailerId}).
    
retailer(update, Merchant, RetailerId, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_retailer, Merchant, RetailerId, Attrs});
retailer(update_score, Merchant, RetailerId, Score) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_score, Merchant, RetailerId, Score});
retailer(check_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_password, Merchant, RetailerId, Password});
retailer(reset_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reset_password, Merchant, RetailerId, Password}).


%% charge
charge(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_charge, Merchant, Attrs});

charge(recharge, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {recharge, Merchant, Attrs});
charge(delete_recharge, Merchant, ChargeId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_recharge, Merchant, ChargeId});

charge(update_recharge, Merchant, {ChargeId, Attrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_recharge, Merchant, {ChargeId, Attrs}}).

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

filter(total_charge_detail, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_charge_detail, Merchant, Conditions}).

filter(charge_detail, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name,
		    {filter_charge_detail, Merchant, Conditions, CurrentPage, ItemsPerPage}).
    

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_retailer, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_retailer with attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Birth    = ?v(<<"birth">>, Attrs),
    Type     = ?v(<<"type">>, Attrs),
    Passwd   = ?v(<<"password">>, Attrs, []), 
    Score    = ?v(<<"score">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),
    Shop     = ?v(<<"shop">>, Attrs, -1),

    %% name can not be same
    Sql = "select id, name, mobile, address"
	++ " from w_retailer" 
	++ " where merchant=" ++ ?to_s(Merchant) 
	++ " and name = " ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\"" 
	++ " and deleted = " ++ ?to_s(?NO),

    case ?sql_utils:execute(read, Sql) of
	{ok, []} -> 
	    Sql2 = "insert into w_retailer("
		"name, birth, type, password, score"
		" ,mobile, address, shop, merchant, entry_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ "\"" ++ ?to_s(Birth) ++ "\","
		++ ?to_s(Type) ++ ","
		++ "\"" ++ ?to_s(Passwd) ++ "\"," 
		++ ?to_s(Score) ++ "," 
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(format_localtime) ++ "\");", 
	    Reply = ?sql_utils:execute(insert, Sql2),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(retailer_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_retailer, Merchant, RetailerId, Attrs}, _From, State) ->
    ?DEBUG("update_retailer with merchant ~p, retailerId ~p~nattrs ~p",
	   [Merchant, RetailerId, Attrs]),

    Name     = ?v(<<"name">>, Attrs),
    Mobile   = ?v(<<"mobile">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Address  = ?v(<<"address">>, Attrs), 
    Birth    = ?v(<<"birth">>, Attrs),
    Type     = ?v(<<"type">>, Attrs),
    Password = ?v(<<"password">>, Attrs),
    OBalance  = ?v(<<"obalance">>, Attrs),
    NBalance  = ?v(<<"nbalance">>, Attrs),

    NameExist =
	case Name of
	    undefined -> {ok, []} ;
	    Name ->
		Sql = "select id, name from w_retailer"
		    " where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
		    ++ " and merchant=" ++ ?to_s(Merchant)
		    ++ " and deleted=" ++ ?to_s(?NO),
		case ?mysql:fetch(read, Sql) of
		    {ok, R} -> {ok, R};
		    {error, {_, Err}} ->
			{error, ?err(db_error, Err)}
		end
	end,

    case NameExist of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(shop, integer, Shop)
		++ ?utils:v(address, string, Address)
		++ ?utils:v(birth, string, Birth)
		++ ?utils:v(type, integer, Type) 
		++ ?utils:v(password, string, Password)
		++ ?utils:v(balance, float, NBalance),

	    Sql1 = "update w_retailer set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = 
		case NBalance of
		    undefined -> 
			?sql_utils:execute(write, Sql1, RetailerId);
		    _ ->
			Datetime = ?utils:current_time(format_localtime),
			Sqls = [Sql1, "insert into retailer_balance_history("
				"retailer, obalance, nbalance"
				", action, merchant, entry_date) values("
				++ ?to_s(RetailerId) ++ ","
				++ ?to_s(OBalance) ++ ","
				++ ?to_s(NBalance) ++ "," 
				++ ?to_s(?UPDATE_RETAILER) ++ "," 
				++ ?to_s(Merchant) ++ ","
				++ "\"" ++ ?to_s(Datetime) ++ "\")"], 
			?sql_utils:execute(transaction, Sqls, RetailerId)
		end, 
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State}; 
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;


handle_call({update_score, Merchant, RetailerId, Score}, _From, State) ->
    Sql = "update w_retailer set score=" ++ ?to_s(Score) ++ ""
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId),

    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    {reply, Reply, State};


handle_call({check_password, Merchant, RetailerId, Password}, _From, State) ->
    Sql = "select id, password from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(RetailerId)
	++ " and password=\'" ++ ?to_s(Password) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    {reply,
	     {error, ?err(retailer_invalid_password, RetailerId)}, State};
	{ok, _}->
	    {reply, {ok, RetailerId}, State};
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
    Sql = "select id, name, mobile, address"
	", balance, merchant, entry_date"
	" from w_retailer where id=" ++ ?to_s(RetailerId)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    {reply, Reply, State};

handle_call({delete_retailer, Merchant, RetailerId}, _From, State) ->
    ?DEBUG("delete_retailer with merchant ~p, retailerId ~p",
	   [Merchant, RetailerId]),
    Sql = "delete from w_retailer where id=" ++ ?to_s(RetailerId)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, RetailerId),
    ?w_user_profile:update(retailer, Merchant),
    {reply, Reply, State};
    

handle_call({list_retailer, Merchant}, _From, State) ->
    ?DEBUG("lookup retail with merchant ~p", [Merchant]),
    Sql = "select id, name, birth, type as type_id"
	", balance, consume, score, mobile, address"
	", shop as shop_id, merchant, entry_date"
	" from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% charge
%%
handle_call({new_charge, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_charge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Charge  = ?v(<<"charge">>, Attrs, 0),
    Balance = ?v(<<"balance">>, Attrs, 0),
    SDate   = ?v(<<"sdate">>, Attrs),
    EDate   = ?v(<<"edate">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs, []),

    Entry    = ?utils:current_time(localtime),
    
    Sql = "select id, name from w_charge"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_charge(merchant, name"
		", charge, balance, sdate, edate, remark"
		", entry) values("
		++ ?to_s(Merchant) ++ ","
	    %% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Charge) ++ ","
		++ ?to_s(Balance) ++ "," 
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


handle_call({recharge, Merchant, Attrs}, _From, State) ->
    ?DEBUG("recharge with merchant ~p, paylaod ~p", [Merchant, Attrs]),

    Retailer = ?v(<<"retailer">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Employee = ?v(<<"employee">>, Attrs),
    CBalance    = ?v(<<"charge_balance">>, Attrs),
    SBalance    = ?v(<<"send_balance">>, Attrs),

    Charge      = ?v(<<"charge">>, Attrs), 
    Comment     = ?v(<<"comment">>, Attrs, []), 
    Entry       = ?utils:current_time(format_localtime),

    Sql0 = "select id, name, balance from w_retailer"
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
	    
	    Sql2 =
		["insert into w_charge_detail(rsn"
		 ", merchant, shop, employ, cid, retailer"
		 ", lbalance, cbalance, sbalance, comment, entry_date) values("
		 ++ "\"" ++ ?to_s(SN) ++ "\","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ "\"" ++ ?to_s(Employee) ++ "\","
		 ++ ?to_s(Charge) ++ "," 
		 ++ ?to_s(Retailer) ++ "," 
		 ++ ?to_s(CurrentBalance) ++ ","
		 ++ ?to_s(CBalance) ++ "," 
		 ++ ?to_s(SBalance) ++ "," 
		 ++ "\"" ++ ?to_s(Comment) ++ "\"," 
		 ++ "\"" ++ ?to_s(Entry) ++ "\")",
		 
		 "update w_retailer set balance=balance+"
		 ++ ?to_s(CBalance + SBalance)
		 ++ " where id=" ++ ?to_s(Retailer)],
	    
	    Reply = ?sql_utils:execute(transaction, Sql2, SN),
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

    Updates = ?utils:v(employ, string, Employee),
    
    Sql0 = "update w_charge_detail set"
	++ ?utils:to_sqls(proplists, comma, Updates) 
	++ " where a.id=" ++ ?to_s(ChargeId)
	++ " and a.merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql0, ChargeId), 
    {reply, Reply, State};

	    

handle_call({list_charge, Merchant}, _From, State) ->
    Sql = "select id, name, charge, balance, sdate, edate"
	", remark, entry"
	" from w_charge"
	" where merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(read, Sql),
    
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

    Sql = "select id, name from w_score"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

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
	     {error, ?err(retailer_score_exist, ?v(<<"id">>, E))}, State}
    end;

handle_call({list_score, Merchant}, _From, State) ->
    Sql = "select id, name, balance, score, type as type_id"
	", sdate, edate, remark, entry"
	" from w_score"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),

    {reply, Reply, State};


handle_call({total_charge_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_charge_detail: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    Sql = "select count(*) as total"
	", sum(cbalance) as cbalance"
	", sum(sbalance) as sbalance"
	" from w_charge_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),

    Reply = ?sql_utils:execute(s_read, Sql),
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
	", a.lbalance, a.cbalance, a.sbalance"
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
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


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


