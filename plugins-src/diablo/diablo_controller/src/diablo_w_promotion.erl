%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Dec 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_promotion).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).
-export([promotion/3, promotion/2]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER(M), ?wpool:get(?MODULE, M)). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
promotion(new, Merchant, Attrs) ->
    gen_server:call(?SERVER(Merchant), {new_promotion, Merchant, Attrs});
promotion(delete, Merchant, PId) ->
    gen_server:call(?SERVER(Merchant), {delete_promotion, Merchant, PId});
promotion(update, Merchant, Attrs) ->
    gen_server:call(?SERVER(Merchant), {update_promotion, Merchant, Attrs}).

promotion(list, Merchant) ->
    gen_server:call(?SERVER(Merchant), {list_promotion, Merchant}).


start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_promotion, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_promotion with merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Entry    = ?utils:current_time(localtime),

    %% Shop     = ?v(<<"shop">>, Attrs, -1),
    Name     = ?v(<<"name">>, Attrs),
    Rule     = ?v(<<"rule">>, Attrs),
    Discount = ?v(<<"discount">>, Attrs, 100),
    Consume  = ?v(<<"consume">>, Attrs, 0),
    Reduce   = ?v(<<"reduce">>, Attrs, 0),
    SDate    = ?v(<<"sdate">>, Attrs),
    EDate    = ?v(<<"edate">>, Attrs),
    Remark   = ?v(<<"remark">>, Attrs, []),

    

    Sql = "select id, name from w_promotion"
	" where merchant=" ++ ?to_s(Merchant)
    %% ++ " and shop=" ++ ?to_s(Shop)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_promotion(merchant, name"
		", rule, discount, cmoney, rmoney, sdate, edate, remark"
		", entry) values("
		++ ?to_s(Merchant) ++ ","
		%% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Rule) ++ ","
		++ ?to_s(Discount) ++ ","
		++ ?to_s(Consume) ++ ","
		++ ?to_s(Reduce) ++ "," 
		++ "\'" ++ ?to_s(SDate) ++ "\',"
		++ "\'" ++ ?to_s(EDate) ++ "\',"
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ "\'" ++ Entry ++ "\')",

	    Reply = ?sql_utils:execute(insert, Sql1),

	    case Reply of
		{ok, _} -> ?w_user_profile:update(promotion, Merchant);
		_ -> error
	    end,

	    {reply, Reply, State};
	{ok, E} ->
	    {reply, {error, ?err(promotion_exist, ?v(<<"id">>, E))}, State}
    end;

handle_call({list_promotion, Merchant}, _From, State) ->
    Sql = "select id, name, rule as rule_id, discount, cmoney, rmoney"
	", sdate, edate, remark, entry"
	" from w_promotion"
	" where merchant=" ++ ?to_s(Merchant)
	++ " order by id desc",

    Reply = ?sql_utils:execute(read, Sql),
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
