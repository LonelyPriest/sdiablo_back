%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2022, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 21 Dec 2022 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_msg_code_check).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([new/4, get/3]).

-define(SERVER, ?MODULE).

%% second, one hour
-define(INTERVAL, 3600).
%% check code exist in 2 minitue
-define(TIMEOUT,  120).

-record(state, {tref}).

%%%===================================================================
%%% API
%%%===================================================================
new(retailer_code, Merchant, Mobile, MsgCode) ->
    gen_server:call(?SERVER, {new_retailer_code, Merchant, Mobile, MsgCode}).
get(retailer_code, Merchant, Mobile) ->
    gen_server:call(?SERVER, {get_retailer_code, Merchant, Mobile}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(?MSG_CHECK_CODE, [set, private, name_table]),
    ok = timer:start(),

    {ok, TRef} = timer:send_interval(
		   ?INTERVAL * 1000, ?SERVER, {'$gen_cast', cleanup}),
    
    {ok, #state{tref=TRef}}.


handle_call({new_retailer_code, Merchant, Mobile, MsgCode}, _From, State) ->
    ?DEBUG("new_retailer_check: Merchant ~p, Mobible ~p, MsgCode",
	   [Merchant, Mobile, MsgCode]),

    Key = retailer_check_key(Merchant, Mobile),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', Key}],
	   ['$_']
	  }],
    case ets:select(?MSG_CHECK_CODE, MS) of
	[] -> ok;
	[{OldKey, _}] ->
	    true = ets:delete(?SESSION, ?to_b(OldKey))
    end,

    true = ets:insert(
	     ?MSG_CHECK_CODE, {Key,
			       #msg_check_code{
				 merchant = ?to_i(Merchant),
				 mobile   = ?to_s(Mobile),
				 code     = ?to_s(MsgCode),
				 gen_time = ?utils:current_time(timestamp)
				}
			      }),
    {reply, {ok, Key}, State};

handle_call({get_retailer_code, Merchant, Mobile}, _From, State) ->
    ?DEBUG("lookup_retailer_code, Merchant ~p, Mobile ~p", [Merchant, Mobile]),
    Key = retailer_check_key(Merchant, Mobile),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', Key}],
	   ['$2']
	  }],
    case ets:select(?SESSION, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[CheckCode] ->
	    {reply, {ok, CheckCode}, State}
    end;
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast(cleanup, State) ->
    ?DEBUG("cleanup_msg_code after 1 hour", []),
    %% CleanSessions = 
    ets:foldl(
      fun({Key, MsgCode}, Acc)->
	      %% ?DEBUG("session id ~p, session ~p", [Id, Session]),
	      case ?utils:current_time(timestamp)
		  - MsgCode#msg_check_code.gen_time >= ?TIMEOUT of
		  true ->
		      %% not acitivte, delete
		      ?INFO("MsgCode ~p does not used, delete it", [MsgCode]),
		      true = ets:delete(?MSG_CHECK_CODE, Key),
		      [Key|Acc];
		  false -> Acc
	      end
      end, [], ?SESSION),

    %% ?DEBUG("clean sessions ~p", [CleanSessions]),
    {noreply, State};

handle_cast(_Msg, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Handling all non call/cast messages
%%
%% @spec handle_info(Info, State) -> {noreply, State} |
%%                                   {noreply, State, Timeout} |
%%                                   {stop, Reason, State}
%% @end
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    {noreply, State}.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any
%% necessary cleaning up. When it returns, the gen_server terminates
%% with Reason. The return value is ignored.
%%
%% @spec terminate(Reason, State) -> void()
%% @end
%%--------------------------------------------------------------------
terminate(_Reason, _State) ->
    ok.

%%--------------------------------------------------------------------
%% @private
%% @doc
%% Convert process state when code is changed
%%
%% @spec code_change(OldVsn, State, Extra) -> {ok, NewState}
%% @end
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
retailer_check_key(Merchant, Mobile) ->
    ?to_b(Merchant) ++ ?to_b("-") ++ ?to_b(Mobile).



