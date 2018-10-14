%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2018, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 14 Oct 2018 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_batch_saler).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([batch_saler/3]).

-define(SERVER, ?MODULE). 

-record(state, {prompt=0::integer()}).

%%%===================================================================
%%% API
%%%===================================================================
batch_saler(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_saler, Merchant, Attrs}).

start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [Name], []).

init([Name]) ->
    [Merchant|_] = lists:reverse(string:tokens(?to_s(Name), "-")),
    Prompt = ?w_retailer:default_profile(prompt, Merchant),
    {ok, #state{prompt=Prompt}}.

handle_call({new_saler, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_saler: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Shop     = ?v(<<"shop">>, Attrs, ?INVALID_OR_EMPTY),
    Name     = ?v(<<"name">>, Attrs),
    PinYin   = ?v(<<"py">>, Attrs),
    Type     = ?v(<<"type">>, Attrs), 
    Balance  = ?v(<<"balance">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),
    Remark   = ?v(<<"remark">>, Attrs, []),
    
    Sql = "select id, name, mobile, address from batchsaler"
	++ " where name = " ++ "\'" ++ ?to_s(Name) ++ "\'"
        ++ " and merchant = " ++ ?to_s(Merchant)
    %% ++ " and mobile = " ++ "\'" ++ ?to_s(Mobile) ++ "\'" 
        ++ " and deleted = " ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
        {ok, []} -> 
            Sql2 = "insert into batchsaler ("
		"shop, name, py, type, balance, mobile, address, remark, merchant, entry_date)"
                ++ " values ("
		++ ?to_s(Shop) ++ ","
                ++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(PinYin) ++ "\',"
		++ ?to_s(Type) ++ ","
                ++ ?to_s(Balance) ++ ","
                ++ "\'" ++ ?to_s(Mobile) ++ "\',"
                ++ "\'" ++ ?to_s(Address) ++ "\',"
		++ "\'" ++ ?to_s(Remark) ++ "\'," 
                ++ ?to_s(Merchant) ++ ","
                ++ "\'" ++ ?utils:current_time(format_localtime) ++ "\');",
            Reply = ?sql_utils:execute(insert, Sql2),
            {reply, Reply, State}; 
        {ok, _Any} ->
            {reply, {error, ?err(batch_saler_exist, Name)}, State};
        Error ->
            {reply, Error, State}
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





