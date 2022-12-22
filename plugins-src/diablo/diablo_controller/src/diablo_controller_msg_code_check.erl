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

-export([verificate_code/1, verificate_code/3, verificate_code/4]).

-define(SERVER, ?MODULE).

%% second, one hour
-define(INTERVAL, 3600).
%% check code exist in 2 minitue
-define(TIMEOUT,  120).

-record(state, {tref}).

%%%===================================================================
%%% API
%%%===================================================================
verificate_code(new, Merchant, Mobile, MsgCode) ->
    gen_server:call(?SERVER, {new_code, Merchant, Mobile, MsgCode});
verificate_code(check, Merchant, Mobile, MsgCode) ->
    gen_server:call(?SERVER, {check_code, Merchant, Mobile, MsgCode}).

verificate_code(get_all) ->
    gen_server:call(?SERVER, get_all_code).

verificate_code(get, Merchant, Mobile) ->
    gen_server:call(?SERVER, {get_code, Merchant, Mobile});
verificate_code(delete, Merchant, Mobile) ->
    gen_server:call(?SERVER, {delete_code, Merchant, Mobile}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    ets:new(?MSG_CHECK_CODE, [set, private, named_table]),
    ok = timer:start(), 
    {ok, TRef} = timer:send_interval(
		   ?INTERVAL * 1000, ?SERVER, {'$gen_cast', cleanup}),
    
    {ok, #state{tref=TRef}}.


handle_call({new_code, Merchant, Mobile, MsgCode}, _From, State) ->
    ?DEBUG("new_retailer_check: Merchant ~p, Mobible ~p, MsgCode ~p",
	   [Merchant, Mobile, MsgCode]),

    Key = gen_key(Merchant, Mobile),
    %% MS = [{{'$1', '$2'},
    %% 	   [{'==', '$1', Key}],
    %% 	   ['$_']
    %% 	  }],
    %% case ets:select(?MSG_CHECK_CODE, MS) of
    %% 	[] -> ok;
    %% 	[{OldKey, _}] ->
    %% 	    true = ets:delete(?MSG_CHECK_CODE, ?to_b(OldKey))
    %% end, 
    true=ets:insert(
	     ?MSG_CHECK_CODE, {Key,
			       #msg_check_code{
				 merchant = ?to_i(Merchant),
				 mobile   = ?to_b(Mobile),
				 code     = ?to_b(MsgCode),
				 gen_time = ?utils:current_time(timestamp)
				}
			      }),
    {reply, {ok, Key}, State};

handle_call({check_code, Merchant, Mobile, OrgCode}, _From, State) ->
    ?DEBUG("check_retailer_code, Merchant ~p, Mobile ~p, OrgCode ~p",
	   [Merchant, Mobile, OrgCode]),
    Key = gen_key(Merchant, Mobile),

    %% example 
    %% [{{'$1',#code{merchant = '_',mobile = '$2',code = '$3', gen_time = '$4'}},
    %%   [{'andalso',{'=:=','$1',<<"4-18692269329">>},
    %% 	          {'=:=','$3',<<"2222">>}}],
    %%   [{{'$3','$4'}}]
    %%  }]

    MS = [{{'$1',#msg_check_code{code='$3', gen_time='$4', _='_'}},
	   [{'andalso',{'=:=','$1', Key},
	               {'=:=','$3', ?to_b(OrgCode)}}],
	   [{{'$3','$4'}}]
	  }],
    
    case ets:select(?MSG_CHECK_CODE, MS) of
    	[] ->
    	    {reply, {error, ?err(verficate_code_not_found, Mobile)}, State}; 
    	[{Code, GenTime}] ->
    	    case ?utils:current_time(timestamp) - GenTime >= ?TIMEOUT of
    	    	true ->
		    {reply, {error, ?err(verficate_code_timeout, Code)}, State};
    	    	false ->
    	    	    {reply, {ok, Code}, State}
    	    end
    end;

handle_call(get_all_code, _From, State) ->
    {reply, {ok, ets:tab2list(?MSG_CHECK_CODE)}, State};

handle_call({get_code, Merchant, Mobile}, _From, State) ->
    ?DEBUG("lookup_retailer_code, Merchant ~p, Mobile ~p", [Merchant, Mobile]),
    Key = gen_key(Merchant, Mobile),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', Key}],
	   ['$2']
	  }],
    case ets:select(?MSG_CHECK_CODE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[MsgCode] -> 
	    {reply, {ok, MsgCode#msg_check_code.code}, State}
    end;

handle_call({delete_code, Merchant, Mobile}, _From, State) ->
    ?DEBUG("delete_code: merchant ~p, Mobile ~p", [Merchant, Mobile]),
    Key = gen_key(Merchant, Mobile),
    ets:delete(?MSG_CHECK_CODE, Key), 
    {reply, ok, State};
    
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
      end, [], ?MSG_CHECK_CODE),

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
gen_key(Merchant, Mobile) ->
    B0 = ?to_b(Merchant),
    B1 = ?to_b(Mobile),
    <<B0/binary, <<"-">>/binary, B1/binary>>.



