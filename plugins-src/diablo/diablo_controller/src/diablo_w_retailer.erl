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
-export([charge/3]).

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
retailer(check_password, Merchant, RetailerId, Password) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_password, Merchant, RetailerId, Password}).


%% charge
charge(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_charge, Merchant, Attrs}).

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
    Passwd   = ?v(<<"password">>, Attrs, []),
    Balance  = ?v(<<"balance">>, Attrs, 0), 
    Consume  = ?v(<<"consume">>, Attrs, 0),
    Score    = ?v(<<"score">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),

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
		"name, password, balance, consume, score"
		" ,mobile, address, merchant, entry_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ "\"" ++ ?to_s(Passwd) ++ "\","
		++ ?to_s(Balance) ++ ","
		++ ?to_s(Consume) ++ "," 
		++ ?to_s(Score) ++ "," 
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\"," 
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");", 
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
    Address  = ?v(<<"address">>, Attrs), 
    Balance  = ?v(<<"balance">>, Attrs),

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
		++ ?utils:v(balance, float, Balance)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(address, string, Address), 

	    Sql1 = "update w_retailer set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(RetailerId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, RetailerId),
	    ?w_user_profile:update(retailer, Merchant),
	    {reply, Reply, State}; 
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

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
    Sql = "select id, name, balance, consume, score, mobile, address"
	", merchant, entry_date"
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


