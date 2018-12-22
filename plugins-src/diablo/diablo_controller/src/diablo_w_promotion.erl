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
    PRule    = ?v(<<"prule">>, Attrs, 0),
    Rule     = ?v(<<"rule">>, Attrs),
    Discount = case Rule of
		   0 -> ?v(<<"discount">>, Attrs, 100);
		   _ -> 100
	       end,
		   
    Consume  = case Rule of
		   1 -> ?v(<<"consume">>, Attrs, []);
		   2 -> ?v(<<"consume">>, Attrs, []);
		   _ -> 0
	       end,
    
    Reduce   = case Rule of
		   1 -> ?v(<<"reduce">>, Attrs, []);
		   2 -> ?v(<<"reduce">>, Attrs, []);
		   _ -> 0
	       end,

    SCount  = case Rule of
		  3 -> ?v(<<"scount">>, Attrs, []);
		  4 -> ?v(<<"scount">>, Attrs, []);
		  _ -> []
	      end,

    SDiscount  = case Rule of
		     3 -> ?v(<<"sdiscount">>, Attrs, []);
		     4 -> ?v(<<"sdiscount">>, Attrs, []);
		     _ -> []
	      end,
    
    SDate    = ?v(<<"sdate">>, Attrs),
    EDate    = ?v(<<"edate">>, Attrs),
    Remark   = ?v(<<"remark">>, Attrs, []), 

    Sql = case Rule of
	      0 -> "select id, name from w_promotion"
		       " where merchant=" ++ ?to_s(Merchant)
		       ++ " and rule=1"
		       ++ " and discount=" ++ ?to_s(Discount);
	      3 -> "select id, name from w_promotion"
		       " where merchant=" ++ ?to_s(Merchant)
		       ++ " and rule=3"
		       ++ " and scount=\'" ++ ?to_s(SCount) ++ "\'"
		       ++ " and sdiscount=\'" ++ ?to_s(SDiscount) ++ "\'";
	      4 ->
		  "select id, name from w_promotion"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=4"
		      ++ " and scount=\'" ++ ?to_s(SCount) ++ "\'"
		      ++ " and sdiscount=\'" ++ ?to_s(SDiscount) ++ "\'";
	      _ ->
		  "select id, name from w_promotion"
		      " where merchant=" ++ ?to_s(Merchant)
		      ++ " and rule=" ++ ?to_s(Rule)
		      ++ " and cmoney=\'" ++ ?to_s(Consume) ++ "\'"
		      ++ " and rmoney=\'" ++ ?to_s(Reduce) ++ "\'" 
	  end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_promotion(merchant, name"
		", rule, discount, cmoney, rmoney, scount, sdiscount, prule, sdate, edate, remark"
		", entry) values("
		++ ?to_s(Merchant) ++ ","
		%% ++ ?to_s(Shop) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ ?to_s(Rule) ++ ","
		++ ?to_s(Discount) ++ ","
		++ "\'" ++ ?to_s(Consume) ++ "\',"
		++ "\'" ++ ?to_s(Reduce) ++ "\',"
		
		++ "\'" ++ ?to_s(SCount) ++ "\',"
		++ "\'" ++ ?to_s(SDiscount) ++ "\',"

		++ ?to_s(PRule) ++ ","
		
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

handle_call({update_promotion, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_promotion with merhcant ~p, attrs ~p", [Merchant, Attrs]),
    Id       = ?v(<<"pid">>, Attrs),
    Name     = ?v(<<"name">>, Attrs),
    Discount = ?v(<<"discount">>, Attrs, 100),
    CMoney   = ?v(<<"cmoney">>, Attrs, []),
    RMoney   = ?v(<<"rmoney">>, Attrs, []),
    %% SDate    = ?v(<<"sdate">>, Attrs),
    %% EDate    = ?v(<<"edate">>, Attrs),
    Remark   = ?v(<<"remark">>, Attrs), 

    Sql = "select id, name from w_promotion"
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(discount, integer, Discount)
		++ ?utils:v(cmoney,  string, CMoney)
		++ ?utils:v(rmoney,  string, RMoney)
		++ ?utils:v(remark, string, Remark),
	    Sql1 = 
		"update w_promotion set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(Id)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, Id),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {error, ?err(promotion_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_promotion, Merchant}, _From, State) ->
    Sql = "select id"
	", name"
	", rule as rule_id"
	", discount"
	", cmoney"
	", rmoney"

	", scount"
	", sdiscount"

	", prule as prule_id"
	
	", sdate"
	", edate"
	", remark"
	", entry"
	
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
