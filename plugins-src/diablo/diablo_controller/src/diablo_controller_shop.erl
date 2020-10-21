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

-export([shop/1, shop/2, shop/3, shop/4, lookup/1, lookup/2]).
-export([region/2, region/3, region/4]).
-export([cost_class/2, cost_class/3, cost_class/4, cost/3, cost/4, cost/6]).

-export([repo/2, repo/3, badrepo/2, badrepo/3, promotion/2, promotion/3]).

-define(SERVER, ?MODULE). 
-define(tbl_shop, "shops").


-record(state, {info :: dict()}).

%%%===================================================================
%%% API
%%%===================================================================
shop(list_info) ->
    gen_server:call(?MODULE, list_info).
shop(list_info, ShopId) ->
    gen_server:call(?MODULE, {list_info, ShopId}).

shop(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_shop, Merchant, Attrs});
shop(get, Merchant, ShopId) ->
    gen_server:call(?MODULE, {get_shop, Merchant, ShopId});
shop(get_sign, Merchant, ShopId) ->
    gen_server:call(?MODULE, {get_shop_sign, Merchant, ShopId});
shop(delete, {Merchant, UTable}, ShopId) ->
    gen_server:call(?MODULE, {delete_shop, Merchant, UTable, ShopId}).

shop(update, Merchant, ShopId, Attrs) ->
    gen_server:call(?MODULE, {update_shop, Merchant, ShopId, Attrs});
shop(update_charge, Merchant, ShopId, Attrs) ->
    gen_server:call(?MODULE, {update_shop_charge, Merchant, ShopId, Attrs}).

region(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_region, Merchant, Attrs}).
region(list, Merchant) ->
    gen_server:call(?MODULE, {list_region, Merchant, []}).

region(update, Merchant, RegionId, Attrs) ->
    gen_server:call(?MODULE, {update_region, Merchant, RegionId, Attrs}).

cost_class(new, Merchant, {Name, PinYin}) ->
    gen_server:call(?MODULE, {new_cost_class, Merchant, Name, PinYin});
cost_class(like_match, Merchant, {Prompt, Ascii}) ->
    gen_server:call(?MODULE, {like_match_cost_class, Merchant, Prompt, Ascii}). 
cost_class(total, Merchant) ->
    gen_server:call(?MODULE, {total_cost_class, Merchant}).
cost_class(filter, Merchant, CurrentPage, ItemsPerPage) ->
    gen_server:call(?MODULE, {filter_cost_class, Merchant, CurrentPage, ItemsPerPage}).

cost(new, Merchant, Cost) ->
    gen_server:call(?MODULE, {new_daily_cost, Merchant, Cost});
cost(update, Merchant, Cost) ->
    gen_server:call(?MODULE, {update_daily_cost, Merchant, Cost}).

cost(total, 'and', Merchant, Conditions) ->
    gen_server:call(?MODULE, {total_daily_cost, Merchant, Conditions}).
cost(filter, 'and', Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?MODULE, {filter_daily_cost, Merchant, CurrentPage, ItemsPerPage, Conditions}).

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
    %% Sql = "select id, name, sms_sign from shops order by id",
    %% case ?sql_utils:execute(read, Sql) of
    %% 	{ok, []} ->
    %% 	    {ok, #state{}};
    %% 	{ok, Shops} ->
    %% 	    Info = 
    %% 		lists:foldr(
    %% 		  fun(S, Dict)->
    %% 			  Key = ?v(<<"id">>, S),
    %% 			  Name = ?v(<<"name">>, S),
    %% 			  Sign = ?v(<<"sms_sign">>, S), 
    %% 			  dict:store(Key, [{<<"name">>, Name}, {<<"sign">>, Sign}], Dict)
    %% 		  end, dict:new(), Shops),
    %% 	    {ok, #state{info=Info}};
    %% 	_ ->
    %% 	    {ok, #state{}}
    %% end.
    {ok, #state{info=dict:new()}}.

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

handle_call({delete_shop, Merchant, _UTable, ShopId}, _From, State) ->
    ?DEBUG("delete_shop with merchant ~p, ShopId ~p", [Merchant, ShopId]),
    %% case ?sql_utils:execute(
    %% 	    s_read,
    %% 	    "select id, rsn"
    %% 	    %% " from w_inventory_new"
    %% 	    " from" ++ ?table:t(stock_new, Merchant, UTable)
    %% 	    ++ " where merchant=" ++ ?to_s(Merchant)
    %% 	    ++" and shop=" ++ ?to_s(ShopId)
    %% 	    ++ " limit 1") of
    %% 	{ok, []} ->
    %% 	    Sql = "update from shops set deleted=1 where id=" ++ ?to_s(ShopId) ++ " and merchant=" ++ ?to_s(Merchant), 
    %% 	    Reply = ?sql_utils:execute(write, Sql, ShopId),
    %% 	    {reply, Reply, State};
    %% 	{ok, _Stocks} ->
    %% 	    {reply, {error, ?err(shop_with_stocks, ShopId)}, State}
    %% end;
    Sql = "update shops set deleted=1 where id=" ++ ?to_s(ShopId) ++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, ShopId),
    {reply, Reply, State};

handle_call({get_shop, Merchant, ShopId}, _From, State) ->
    Sql = "select id, name, sms_sign, pay_cd from shops"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(ShopId),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_shop_sign, Merchant, ShopId}, _From, State) ->
    Sql = "select id, name, sms_sign from shops"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(ShopId),
    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, Shop} ->
		{?v(<<"name">>, Shop), ?v(<<"sms_sign">>, Shop)};
	    _ ->
		{ShopId, []}
	end,
    {reply, Reply, State};

handle_call({update_shop, Merchant, ShopId, Attrs}, _From, State) ->
    ?DEBUG("Update_shop with merchant ~p, ShopId ~p, Attrs ~p",
	   [Merchant, ShopId, Attrs]), 
    Name    = ?v(<<"name">>, Attrs),
    Address = ?v(<<"address">>, Attrs),
    Repo    = ?v(<<"repo">>, Attrs),
    %% Type    = ?v(<<"type">>, Attrs),
    Master  = ?v(<<"shopowner">>, Attrs),
    %% Charge  = ?v(<<"charge">>, Attrs),
    Score   = ?v(<<"score">>, Attrs),
    Region  = ?v(<<"region">>, Attrs),
    BCodeFriend = ?v(<<"bcode_friend">>, Attrs),
    BCodePay = ?v(<<"bcode_pay">>, Attrs),
    

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
		++ ?utils:v(bcode_friend, string, BCodeFriend)
		++ ?utils:v(bcode_pay, string, BCodePay)
	    %% ++ ?utils:v(charge, integer, Charge)
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

handle_call({update_shop_charge, Merchant, ShopId, Attrs}, _From, State) ->
    ?DEBUG("update_shop_charge with merchant ~p, ShopId ~p, Attrs ~p",
	   [Merchant, ShopId, Attrs]), 
    Charge  = ?v(<<"charge">>, Attrs),
    Updates = 
	case ?v(<<"type">>, Attrs) of
	    ?RECHARGE -> ?utils:v(charge, integer, Charge);
	    ?WITHDRAW -> ?utils:v(draw, integer, Charge)
	end, 
	    
    Sql1 = "update shops set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(ShopId)
	++ " and merchant=" ++ ?to_s(Merchant),
    
    Reply = ?sql_utils:execute(write, Sql1, ShopId),
    {reply, Reply, State};
	


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

    Sql1 = "select a.id"
	", a.repo"
	", a.name"
	", a.address"
	", a.type"
	", a.open_date"
	", a.master as shopowner_id"
	", a.charge as charge_id"
	", a.draw as draw_id"
	", a.score as score_id"
	", a.region as region_id"
	", a.bcode_friend"
	", a.bcode_pay"
	", a.pay_cd"
	", a.sms_sign"
	", a.entry_date"
	", a.deleted"
	++ " from shops a" 
	++ " where "
	++ case Conditions of
	       [] -> [];
	       _  ->
		   CorrectConditions =
		       ?utils:correct_condition(<<"a.">>, Conditions), 
		   ?utils:to_sqls(proplists, CorrectConditions) ++ " and "
	   end
	++ "a.merchant=" ++ ?to_s(Merchant)
    %%++ " and a.deleted = " ++ ?to_s(?NO)
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
    Department    = ?v(<<"department">>, Attrs, []),
    Comment   = ?v(<<"comment">>, Attrs, []),
    Datetime  = ?utils:current_time(format_localtime),

    %% name can not be same
    Sql = "select id, name from region  where merchant=" ++ ?to_s(Merchant)
	++ " and name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into region"
		++ "(merchant, name, department, comment, entry_date)"
		++ " values ("
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\'," 
	        ++ "\'" ++ ?to_s(Department) ++ "\',"
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

handle_call({update_region, Merchant, RegionId, Attrs}, _From, State) ->
    ?DEBUG("Update_region with merchant ~p, RegionId ~p, Attrs ~p", [Merchant, RegionId, Attrs]), 
    Name    = ?v(<<"name">>, Attrs),
    Department = ?v(<<"department">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(department, integer, Department)
	++ ?utils:v(comment, string, Comment),
    
    Sql = "update region set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(RegionId)
	++ " and merchant=" ++ ?to_s(Merchant),
    
    Reply = ?sql_utils:execute(write, Sql, RegionId),
    {reply, Reply, State};


handle_call({list_region, Merchant, Conditions}, _From, State) ->
    Sql = "select id, name, department as department_id, comment, entry_date from region"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({new_cost_class, Merchant, Name, PinYin}, _From, State)->
    ?DEBUG("new cost_class: Name ~p, PinYin ~p", [Name, PinYin]), 
    %% name can not be same
    Sql = "select id, name from cost_class where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_string(Name) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into cost_class(merchant, name, py) values ("
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(PinYin) ++ "\')",
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(cost_class_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({like_match_cost_class, Merchant, Prompt, Ascii}, _From, State) ->
    Sql = "select id, name, py from cost_class"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and "
	++ case Ascii of
	       ?YES -> ?utils:check_match_mode(<<"py">>, Prompt);
	       ?NO ->?utils:check_match_mode(<<"name">>, Prompt)
	   end,
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_cost_class, Merchant}, _From, State) ->
    Sql = ?sql_utils:count_table(cost_class, Merchant, []),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_cost_class, Merchant, CurrentPage, ItemsPerPage}, _From, State) ->
    Sql = "select id, name, py, merchant from cost_class"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_daily_cost, Merchant, Cost}, _From, State)->
    ?DEBUG("new_daily_cost: Merchant ~p, Cost ~p", [Merchant, Cost]),
    CostClass = ?v(<<"cost_class">>, Cost),
    EntryDate = ?v(<<"date">>, Cost),
    Cash = ?v(<<"cash">>, Cost, 0),
    Card = ?v(<<"card">>, Cost, 0),
    Wxin = ?v(<<"wxin">>, Cost, 0),
    Comment = ?v(<<"comment">>, Cost, []),
    Shop = ?v(<<"shop">>, Cost), 
    Balance = ?to_i(Cash) + ?to_i(Card) + ?to_i(Wxin),
    Reply = 
	case Balance > 0 of
	    true ->
		Sql =
		    "insert into daily_cost("
		    "shop"
		    ", cost_class"
		    ", balance"
		    ", cash"
		    ", card"
		    ", wxin"
		    ", comment"
		    ", merchant"
		    ", entry_date"
		    ", op_date) values("
		    ++ ?to_s(Shop) ++ ","
		    ++ ?to_s(CostClass) ++ ","
		    ++ ?to_s(Balance) ++ "," 
		    ++ ?to_s(Cash) ++ ","
		    ++ ?to_s(Card) ++ ","
		    ++ ?to_s(Wxin) ++ ","
		    ++ "\'" ++ ?to_s(Comment) ++ "\',"
		    ++ ?to_s(Merchant) ++ ","
		    ++ "\'" ++ ?to_s(EntryDate) ++ "\',"
		    ++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')",
		?sql_utils:execute(insert, Sql);
	    false ->
		{error, ?err(cost_zero_balance, CostClass)}
    end,
    {reply, Reply, State};

handle_call({update_daily_cost, Merchant, Cost}, _From, State) ->
    ?DEBUG("update_daily_cost: Merchant ~p, Cost ~p", [Merchant, Cost]),
    CostId = ?v(<<"cid">>, Cost),
    EntryDate = ?v(<<"date">>, Cost),
    Cash = ?v(<<"cash">>, Cost),
    Card = ?v(<<"card">>, Cost),
    Wxin = ?v(<<"wxin">>, Cost),
    Comment = ?v(<<"comment">>, Cost),
    Shop = ?v(<<"shop">>, Cost),
    
    Updates = ?utils:v(cash, integer, Cash)
	++ ?utils:v(card, integer, Card)
	++ ?utils:v(wxin, integer, Wxin)
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(entry_date, string, EntryDate),

    Sql = "update daily_cost set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(CostId)
	++ " and merchant=" ++ ?to_s(Merchant),
    
    Reply = ?sql_utils:execute(write, Sql, CostId),
    {reply, Reply, State};

handle_call({total_daily_cost, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    CountSql = "select count(*) as total"
    	", sum(a.balance) as t_balance"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
	", sum(a.wxin) as t_wxin"
	" from daily_cost a"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case ?sql_utils:time_condition(non_prefix, ge2less, StartTime, EndTime) of
	       [] -> [];
	       Sql -> " and " ++ Sql
	   end,
	Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};

handle_call({filter_daily_cost, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = "select a.id"
	", a.shop as shop_id"
	", a.cost_class as cost_class_id"
	", a.balance"
	", a.cash"
	", a.wxin"
	", a.card"
	", a.comment"
	", a.entry_date"
	", a.op_date"

	", b.name as shop"
	", c.name as cost_class"
	
	" from daily_cost a"
	" left join shops b on a.shop=b.id"
	" left join cost_class c on a.cost_class=c.id"
	
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case ?sql_utils:time_condition(prefix, ge2less, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end
	++ ?sql_utils:condition(page_desc, {use_datetime, 0}, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call(list_info, _From, #state{info=Dict} = State) ->
    List = dict:to_list(Dict),
    {reply, List, State};

handle_call({list_info, ShopId}, _From, #state{info=Dict} = State) ->
    Info = 
	case dict:find(ShopId, Dict) of
	    {ok, V} -> V;
	    error -> []
	end,
    {reply, Info, State};

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
