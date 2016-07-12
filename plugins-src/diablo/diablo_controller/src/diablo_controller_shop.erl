%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_shop).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([shop/3, shop/4, lookup/1, lookup/2]).
-export([region/2, region/3]).

-export([repo/2, repo/3, badrepo/2, badrepo/3, promotion/2, promotion/3]).

-define(SERVER, ?MODULE). 
-define(tbl_shop, "shops").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
shop(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_shop, Merchant, Attrs});
shop(delete, Merchant, ShopId) ->
    gen_server:call(?MODULE, {delete_shop, Merchant, ShopId}).

shop(update, Merchant, ShopId, Attrs) ->
    gen_server:call(?MODULE, {update_shop, Merchant, ShopId, Attrs}).

region(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_region, Merchant, Attrs}).
region(list, Merchant) ->
    gen_server:call(?MODULE, {list_region, Merchant, []}).

lookup(Merchant) ->
    lookup(Merchant, []).
lookup(Merchant, Condition) ->
    gen_server:call(?MODULE, {list_shop, Merchant, Condition}).

%% lookup(shop_info, Merchant, Condition) ->
%%     gen_server:call(?MODULE, {shop_info, Merchant, Condition}).

%% repertory
repo(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_repo, Merchant, Attrs});
repo(get, Merchant, RepoId) -> 
    gen_server:call(?MODULE, {get_repo, Merchant, RepoId}).
repo(list, Merchant) ->
    gen_server:call(?MODULE, {list_repo, Merchant}).


%% bad repertory
badrepo(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_badrepo, Merchant, Attrs});
badrepo(get, Merchant, RepoId) -> 
    gen_server:call(?MODULE, {get_badrepo, Merchant, RepoId}).
badrepo(list, Merchant) ->
    gen_server:call(?MODULE, {list_badrepo, Merchant}).

%% promotion
promotion(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_promotion, Merchant, Attrs});
promotion(list, Merchant, Conditions) ->
    gen_server:call(?MODULE, {list_promotion, Merchant, Conditions}).
promotion(list, Merchant) ->
    gen_server:call(?MODULE, {list_promotion, Merchant}).


start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_shop, Merchant, Props}, _From, State)->
    ?DEBUG("new shop with props ~p", [Props]),
    Name      = ?v(<<"name">>, Props),
    Shopowner = ?v(<<"shopowner">>, Props, []),
    Address   = ?v(<<"address">>, Props),
    OpenDate  = ?v(<<"open_date">>, Props),
    Repo      = ?v(<<"repo">>, Props, -1),
    Datetime  = ?utils:current_time(format_localtime),
    
    %% name can not be same
    Sql = "select id, name"
	++ " from " ++ ?tbl_shop
	++ " where name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into shops"
		++ "(repo, type, name, address, open_date, master"
		", merchant, entry_date)"
		++ " values ("
		++ ?to_s(Repo) ++ ","
		++ ?to_s(?SHOP) ++ ","
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		%% ++ ?to_s(Type) ++ ","
		++ "\"" ++ ?to_s(OpenDate) ++ "\","
		++ "\"" ++ ?to_s(Shopowner) ++ "\"," 
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?to_s(Datetime) ++ "\")",
		
	    ?DEBUG("sql to shop ~ts", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(insert, Sql1),
	    ?w_user_profile:update(shop, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(shop_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_shop, Merchant, ShopId}, _From, State) ->
    ?DEBUG("delete_shop with merchant ~p, ShopId ~p", [Merchant, ShopId]),
    Sql = "delete from shops where id=" ++ ?to_s(ShopId)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, ShopId),
    {reply, Reply, State};

handle_call({update_shop, Merchant, ShopId, Attrs}, _From, State) ->
    ?DEBUG("Update_shop with merchant ~p, ShopId ~p, Attrs ~p",
	   [Merchant, ShopId, Attrs]), 
    Name    = ?v(<<"name">>, Attrs),
    Address = ?v(<<"address">>, Attrs),
    Repo    = ?v(<<"repo">>, Attrs),
    %% Type    = ?v(<<"type">>, Attrs),
    Master  = ?v(<<"shopowner">>, Attrs),
    Charge  = ?v(<<"charge">>, Attrs),
    Score   = ?v(<<"score">>, Attrs),
    Region  = ?v(<<"region">>, Attrs),

    ShopExist = 
	case Name of
	    undefined -> {ok, []};
	    Name ->
		Sql = "select id, name from shops"
		    " where name=" ++ "\"" ++ ?to_s(Name) ++ "\""
		    ++ " and merchant=" ++ ?to_s(Merchant)
		    ++ " and deleted=" ++ ?to_s(?NO), 
		?sql_utils:execute(s_read, Sql)
	end,

    case ShopExist of
	{ok, []} ->
	    Updates = ?utils:v(repo, integer, Repo) 
		++ ?utils:v(name, string, Name)
		++ ?utils:v(address, string, Address)
		++ ?utils:v(region, integer, Region)
		++ ?utils:v(master, string, Master)
		++ ?utils:v(charge, integer, Charge)
		++ ?utils:v(score, integer, Score),
	    Sql1 = "update shops set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(ShopId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    case Master of
		undefined ->
		    Reply = ?sql_utils:execute(write, Sql1, ShopId),
		    %% ?w_user_profile:update(shop, Merchant), 
		    {reply, Reply, State};
		Master ->
		    Trans = [Sql1,
			     %% set shopowner of the employee
			     "update employees set position=" ++ ?to_s(?SHOP_MASTER)
			     ++ " where number=" ++ ?to_s(Master)
			     ++ " and merchant=" ++ ?to_s(Merchant)],
		    Reply = ?sql_utils:execute(transaction, Trans, ShopId),
		    {reply, Reply, State}
	    end;
	Error ->
	    {reply, Error, State}
    end;

%% handle_call({shop_info, Merchant, Condition}, _From, State) ->
%%     ?DEBUG("lookup_shop_info with condition ~p", [Condition]),
%%     Sql1 = "select id, name, address, open_date, shopowner"
%% 	++ " from shops"
%% 	++ " where "
%% 	++ case Condition of
%% 	       [] -> [];
%% 	       _  -> ?utils:to_sqls(proplists, Condition) ++ " and "
%% 	   end
%% 	++ " merchant=" ++ ?to_s(Merchant)
%% 	++ " and type=" ++ ?to_s(?SHOP) 
%% 	++ " and deleted = " ++ ?to_string(?NO),
    
%%     Reply = ?sql_utils:execute(read, Sql1),
%%     {reply, Reply, State};

handle_call({list_shop, Merchant, Conditions}, _From, State) ->
    ?DEBUG("lookup shops with merchant ~p, condition ~p",
	   [Merchant, Conditions]),

    Sql1 = "select a.id, a.repo, a.name, a.address, a.type"
	", a.open_date, a.master as shopowner_id, a.charge as charge_id"
	", a.score as score_id, a.region as region_id, a.entry_date"
	%% ", b.name as shopowner"
	++ " from shops a"
	%% ++ " left join employees b on a.shopowner=b.number"
	%% ++ " and b.merchant=" ++ ?to_s(Merchant)
	++ " where "
	++ case Conditions of
	       [] -> [];
	       _  ->
		   CorrectConditions =
		       ?utils:correct_condition(<<"a.">>, Conditions), 
		   ?utils:to_sqls(proplists, CorrectConditions) ++ " and "
	   end
	++ "a.merchant=" ++ ?to_s(Merchant)
	%% ++ " and a.type=" ++ ?to_s(?SHOP)
	++ " and a.deleted = " ++ ?to_s(?NO)
	++ " order by id",

    Reply = ?sql_utils:execute(read, Sql1), 
    {reply, Reply, State};


%% repertory
handle_call({new_repo, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new repo with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name    = ?v(<<"name">>, Attrs),
    Address = ?v(<<"address">>, Attrs),
    
    Sql0 = "select id, name from shops"
	" where name=\'" ++ ?to_s(Name) ++ "\'"
	" and merchant=" ++ ?to_s(Merchant),

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into shops("
		"type, name, address, merchant, open_date)"
		" values("
		++ ?to_s(?REPERTORY) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(Address) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localtime) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, Repo} ->
	    {reply, {error, ?err(repo_exist, ?v(<<"id">>, Repo))}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_repo, Merchant}, _From, State) ->
    ?DEBUG("list_repo with merchant ~p", [Merchant]),
    Sql = "select id, name, address, open_date"
	" from shops where merchant=" ++ ?to_s(Merchant) 
	++ " and type=" ++ ?to_s(?REPERTORY),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_repo, Merchant, RepoId}, _From, State) ->
    ?DEBUG("get_repo with merchant ~p, repoId ~p", [Merchant, RepoId]),
    Sql = "select id, name, address, open_date"
	" from shops where id=" ++ ?to_s(RepoId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and type=" ++ ?to_s(?REPERTORY),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

%% bad repertory
handle_call({new_badrepo, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new badrepo with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name    = ?v(<<"name">>, Attrs), 
    Address = ?v(<<"address">>, Attrs),
    Repo    = ?v(<<"repo">>, Attrs),

    Sql0 = "select id, name from shops"
	" where name=\'" ++ ?to_s(Name) ++ "\'"
	" and merchant=" ++ ?to_s(Merchant),

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into shops("
		"repo, type, name, address, merchant, open_date)"
		" values("
		++ ?to_s(Repo) ++ ","
		++ ?to_s(?BAD_REPERTORY) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(Address) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localtime) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, Repo} ->
	    {reply, {error, ?err(repo_exist, ?v(<<"id">>, Repo))}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_badrepo, Merchant}, _From, State) ->
    ?DEBUG("list_badrepo with merchant ~p", [Merchant]),
    Sql = "select id, name, address, repo as repo_id, open_date"
	" from shops where merchant=" ++ ?to_s(Merchant) 
	++ " and type=" ++ ?to_s(?BAD_REPERTORY),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_badrepo, Merchant, RepoId}, _From, State) ->
    ?DEBUG("get_badrepo with merchant ~p, repoId ~p", [Merchant, RepoId]),
    Sql = "select id, name, address, repo ad repo_id, open_date"
	" from shops where id=" ++ ?to_s(RepoId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and type=" ++ ?to_s(?BAD_REPERTORY),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({new_promotion, Merchant, Attrs}, _From, State) ->
    Shop          = ?v(<<"shop">>, Attrs),
    
    {struct, Promotions} = ?v(<<"promotion">>, Attrs), 
    DelPromotions = ?v(<<"del">>, Promotions, []),
    AddPromotions = ?v(<<"add">>, Promotions, []),

    ?DEBUG("delpromotions ~p, addpromotions ~p",
	   [DelPromotions, AddPromotions]),

    Datetime      = ?utils:current_time(localtime),

    AddSql =
	lists:foldr(
	  fun(Add, Acc) ->
		  ["insert into shop_promotion("
		   "merchant, shop, pid, entry) values("
		   ++ ?to_s(Merchant)
		   ++ "," ++ ?to_s(Shop)
		   ++ "," ++ ?to_s(Add)
		   ++ ",\'" ++ Datetime ++ "\')"|Acc]
	  end, [], AddPromotions),

    ?DEBUG("add sql ~p", [AddSql]),

    DelSql = 
	case DelPromotions of
	    [] -> [];
	    _  ->
		["delete from shop_promotion"
		 " where merchant=" ++ ?to_s(Merchant)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ ?sql_utils:condition(
		       proplists, {<<"pid">>, DelPromotions})]
	end,

    ?DEBUG("del sql ~p", [DelSql]),

    Reply = ?sql_utils:execute(transaction, DelSql ++ AddSql, Shop),

    {reply, Reply, State};

handle_call({list_promotion, Merchant}, _From, State) ->
    Sql = "select id, shop as shop_id, pid, entry from shop_promotion"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_promotion, Merchant, Conditions}, _From, State) ->
    Sql = "select id, shop as shop_id, pid, entry from shop_promotion"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_region, Merchant, Attrs}, _From, State)->
    ?DEBUG("new region with props ~p", [Attrs]),
    Name      = ?v(<<"name">>, Attrs),
    Comment   = ?v(<<"comment">>, Attrs, []),
    Datetime  = ?utils:current_time(format_localtime),

    %% name can not be same
    Sql = "select id, name"
	++ " from region"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into region"
		++ "(merchant, name, comment, entry_date)"
		++ " values ("
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(Comment) ++ "\'," 
		++ "\"" ++ ?to_s(Datetime) ++ "\")", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    ?w_user_profile:update(region, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(region_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_region, Merchant, Conditions}, _From, State) ->
    Sql = "select id, name, comment, entry_date from region"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};
	

handle_call(_Request, _From, State) ->
    ?WARN("receive unkown request ~p", [_Request]),
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
