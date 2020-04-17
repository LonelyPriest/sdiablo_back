%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_merchant).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([merchant/2, merchant/3, lookup/0, lookup/1, sms/1, sms/2, sms/3]).

-define(SERVER, ?MODULE). 
-define(tbl_merchant, "merchants").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
merchant(new, Props) ->
    gen_server:call(?MODULE, {new_merchant, Props});
merchant(delete, Condition) ->
    gen_server:call(?MODULE, {delete_merchant, Condition});

merchant(get, Merchant) ->
    gen_server:call(?MODULE, {get_merchant, Merchant}).

merchant(update, Condition, Fields) ->
    gen_server:call(?MODULE, {update_merchant, Condition, Fields}).

lookup() ->
    gen_server:call(?MODULE, lookup).
lookup(Condition) ->
    gen_server:call(?MODULE, {lookup, Condition}).

sms(list) ->
    gen_server:call(?MODULE, list_sms);
sms(list_center) ->
    gen_server:call(?MODULE, list_sms_center).

sms(list, Merchant) ->
    gen_server:call(?MODULE, {list_sms, Merchant});
sms(list_center, Merchant) ->
    gen_server:call(?MODULE, {list_sms_center, Merchant});
sms(list_template, Merchant) ->
    gen_server:call(?MODULE, {list_sms_template, Merchant}).


sms(new_rate, Merchant, Rate) ->
    gen_server:call(?MODULE, {new_sms_rate, Merchant, Rate});
sms(charge, Merchant, Balance) ->
    gen_server:call(?MODULE, {charge_sms, Merchant, Balance});
sms(new_sign, Merchant, Sign) ->
    gen_server:call(?MODULE, {new_sms_sign, Merchant, Sign}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_merchant, Props}, _From, State)->
    ?DEBUG("new merchant with props ~p", [Props]),
    Name    = ?v(<<"name">>, Props),
    Type    = ?v(<<"type">>, Props),
    Owner   = ?v(<<"owner">>, Props),
    Mobile  = ?v(<<"mobile">>, Props),
    Address = ?v(<<"address">>, Props),
    UTable  = ?v(<<"utable">>, Props, 0),

    %% name can not be same
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	%% ++ " and type=" ++ ?to_s(Type)
	%% ++ " and mobile="   ++ "\"" ++ ?to_s(Mobile) ++ "\""
	%% ++ " and owner="    ++ "\"" ++ ?to_s(Owner) ++ "\""
	++ " and deleted="  ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into " ++ ?tbl_merchant
		++ "(name"
		", type"
		", owner"
		", mobile"
		", sms_team"
		", address"
		", unique_table"
		", entry_date) values ("
		++ "\'"  ++ ?to_s(Name) ++ "\'"
		++ ","   ++ ?to_s(Type)
		++ ",\'" ++ ?to_s(Owner) ++ "\'"
		++ ",\'" ++ ?to_s(Mobile) ++ "\'"
		++ "," ++ ?to_s(?DEFAULT_MERCHANT)
		++ ",\'" ++ ?to_s(Address) ++ "\'"
		++ ","   ++ ?to_s(UTable)
		++ ",\'" ++ ?utils:current_time(localdate) ++ "\')", 
		
	    %% ?DEBUG("sql to merchant ~p", [Sql1]),
	    case ?sql_utils:execute(insert, Sql1) of
		{ok, InsertId} -> 
		    %% user profile
		    case ?w_user_profile:set_default(InsertId) of
			{ok, _} -> 
			    ok = ?inventory_sn:init(merchant, InsertId),
			    {reply, {ok, Name}, State}; 
			Error ->
			    %% rollback
			    Rollback = "delete from "
				++ ?tbl_merchant ++ " where id=" ++ ?to_s(InsertId),
			    case ?sql_utils:execute(write, Rollback, Name) of
				{ok, Name} ->
				    {reply, Error, State};
				_RollbackError ->
				    {reply, ?err(merchant_rollback_failed, Name), State}
			    end
			end;
		Error ->
		    {reply, Error, State}
	    end;
	{ok, _Any} ->
	    ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(merchant_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_merchant, Condition}, _From, State) ->
    ?DEBUG("delete merchant with condtion ~p", [Condition]),
    C = ?utils:to_sqls(proplists, Condition),
    Sql = "update " ++ ?tbl_merchant
	++ " set deleted = " ++ ?to_s(?YES)
	++ " where " ++ C ++ ";",
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call({update_merchant, Condition, Fields}, _From, State) ->
    ?DEBUG("Update merchant with condtion: condition ~p, fields ~p", [Condition, Fields]),
    C = ?utils:to_sqls(proplists, Condition),
    ?DEBUG("C ~p", [C]),

    Values = ?utils:to_sqls(proplists, Fields),
    ?DEBUG("U ~p", [Values]),
    
    Sql = "update " ++ ?tbl_merchant ++ " set " ++ Values ++ " where " ++ C ++ ";",    
    ?DEBUG("sql ~p", [Sql]),
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call(lookup, _From, State) ->
    %% ?DEBUG("lookup merchant all", []),
    Sql = "select " ++ fields() ++ " from " ++ ?tbl_merchant ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({lookup, Condition}, _From, State) ->
    ?DEBUG("lookup merchant with condition ~p", [Condition]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where " ++ ?utils:to_sqls(proplists, Condition) ++ ";",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({get_merchant, Merchant}, _From, State) ->
    ?DEBUG("get_merchant merchant with Merchant ~p", [Merchant]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_merchant
	++ " where id=" ++  ?to_s(Merchant) ++";",
    {ok, Detail} = ?sql_utils:execute(s_read, Sql),
    {reply, {ok, Detail}, State};

handle_call(list_sms, _From, State) ->
    Sql = "select a.id, a.name, a.mobile, a.balance"
	", a.sms_send, a.entry_date" 
	", b.rate"
	
	" from merchants a"
	" left join sms_rate b on a.id=b.merchant"
	" order by a.id", 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_sms, Merchant}, _From, State) ->
    Sql = "select a.id, a.name, a.mobile, a.balance"
	", a.sms_send, a.entry_date" 
	", b.rate"
	
	" from merchants a, sms_rate b"
	" where a.id=b.merchant"
	" and a.id=" ++ ?to_s(Merchant),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call(list_sms_center, _From, State) ->
    Sql = "select a.id, a.merchant as mid, a.url, a.app_key, a.app_secret"
	", a.sms_sign_name"
	", a.sms_sign_method"
	", a.sms_send_method"
	", a.sms_template"
	", a.sms_type"
	", a.sms_version"
	", b.name as merchant"
	" from sms_center a"
	" left join merchants b on a.merchant=b.id"
	" order by a.id", 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_sms_center, Merchant}, _From, State) ->
    Sql = "select a.id, a.merchant as mid, a.url, a.app_key, a.app_secret"
	", a.sms_sign_name"
	", a.sms_sign_method"
	", a.sms_send_method"
	", a.sms_template"
	", a.sms_type"
	", a.sms_version"
	", b.name as merchant"
	" from sms_center a"
	" left join merchants b on a.merchant=b.id", 
    case ?sql_utils:execute(s_read, Sql ++ " where a.merchant=" ++ ?to_s(Merchant)) of
	{ok, []} ->
	    Reply = ?sql_utils:execute(s_read, Sql ++ " where a.merchant=-1"),
	    {reply, Reply, State};
	{ok, Center} ->
	    {reply, {ok, Center}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_sms_template, Merchant}, _From, State) ->
    Sql = "select a.id"
	", a.merchant"
	", a.type"
	", a.content"
	" from zz_sms_template a"
	" where a.merchant in (-1, " ++ ?to_s(Merchant) ++ ")",
    case ?sql_utils:execute(read, Sql) of
	{ok, Templates} ->
	    {reply, {ok, Templates}, State};
	_Error ->
	    {reply, {ok, []}, State}
    end;

handle_call({new_sms_rate, Merchant, Rate}, _From, State) ->
    Sql0 = "select id, sms_rate from merchants"
	" where id=" ++ ?to_s(Merchant)
	++ " and sms_rate=" ++ ?to_s(Rate), 
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} -> 
	    %% Sql = "insert into sms_rate(merchant, rate) values("
	    %% 	++ ?to_s(Merchant) ++ ","
	    %% 	++ ?to_s(Rate) ++ ")",
	    Sql = "update merchants set sms_rate=" ++ ?to_s(Rate)
		++ " where id=" ++ ?to_s(Merchant),
	    Reply = ?sql_utils:execute(write, Sql, Merchant),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {error, ?err(sms_rate_exist, Merchant)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({new_sms_sign, Merchant, SignName}, _From, State) ->
    Sql0 = "select id, sms_sign from merchants"
	" where id=" ++ ?to_s(Merchant)
	++ " and sms_sign=\'" ++ ?to_s(SignName) ++ "\'",
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    %% Timestamp = ?utils:current_time(timestamp),
	    %% Account = ?ZZ_SMS_ACCOUNT ++ ?ZZ_SMS_PASSWORD ++ Timestamp,
	    %% MD5Sign = crypto:hash(md5, Account),
	    %% ?DEBUG("MD5Sing ~p", [MD5Sign]),
	    %% AppId = "49",
	    %% Params = {[{<<"username">>, ?to_b(?ZZ_SMS_ACCOUNT)},
	    %% 	       {<<"timestamp">>, ?to_b(Timestamp)},
	    %% 	       {<<"signature">>, ?to_b(MD5Sign)},
	    %% 	       {<<"appid">>, ?to_b(AppId)},
	    %% 	       {<<"signature_name">>, ?to_b(SignName)}
	    %% 	      ]},
	    %% Body = ?to_s(ejson:encode(Params)), 

	    %% case httpc:request(
	    %% 	   post, {?ZZ_SMS_SIGN ++ "/signatureAdd",
	    %% 		  [], [], Body}, [], []) of
	    %% 	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    %% 	    ?DEBUG("Reply ~ts", [Reply]),
	    %% 	    {struct, Result} = mochijson2:decode(Reply), 
	    %% 	    ?DEBUG("sms result ~p", [Result]),
	    %% 	    case ?v(<<"status">>, Result) of
	    %% 		<<"success">> ->
	    %% 		    Sql = "update merchants set sms_sign=\'" ++ ?to_s(SignName) ++ "\'"
	    %% 			++ " where id=" ++ ?to_s(Merchant),
	    %% 		    Reply = ?sql_utils:execute(write, Sql, Merchant),
	    %% 		    {reply, Reply, State};
	    %% 		_ ->
	    %% 		    ?INFO("add sms sign failed: ~ts", [?v(<<"msg">>, Result)]),
	    %% 		    {error, {failed_to_add_sms_sign, ?v(<<"code">>, Result)}}
	    %% 	    end;
	    %% 	{error, Reason} ->
	    %% 	    {error, {http_failed, Reason}}
	    %% end;
	    Sql = "update merchants set sms_sign=\'" ++ ?to_s(SignName) ++ "\'"
		++ " where id=" ++ ?to_s(Merchant),
	    Reply = ?sql_utils:execute(write, Sql, Merchant),
	    {reply, Reply, State}; 
	{ok, _SMS} ->
	    {reply, {error, ?err(sms_sign_exist, Merchant)}, State}; 
	Error ->
	    {reply, Error, State}
    end;

handle_call({charge_sms, Merchant, Balance}, _From, State) ->
    Sql = "update merchants set balance=balance+" ++ ?to_s(Balance)
	++ " where id=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, Merchant),
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
fields() ->
    "id"
	", name"
	", owner"
	", balance"
	", mobile"
	", sms_send"
	", sms_rate"
	", sms_sign"
	", sms_team"
	", unique_table" 
	", address"
	", type"
	", entry_date".
