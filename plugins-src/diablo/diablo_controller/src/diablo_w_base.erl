%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  8 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_w_base).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([bank_card/2, bank_card/3, setting/2, setting/3, sys_config/0, sys_config/1]).
-export([good/2, good/3, print/2, print/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
bank_card(new, Merchant, Attrs) ->
    gen_server:call(?SERVER, {new_bank_card, Merchant, Attrs});
bank_card(delete, Merchant, CardId) ->
    gen_server:call(?SERVER, {delete_bank_card, Merchant, CardId});
bank_card(update, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_bank_card, Merchant, Attrs}).

bank_card(list, Merchant) ->
    gen_server:call(?SERVER, {list_bank_card, Merchant}).

setting(list, Merchant) ->
    gen_server:call(?SERVER, {list_base_setting, Merchant}).

setting(add_to_shop, Merchant, Shop) ->
    gen_server:call(?SERVER, {add_shop_setting, Merchant, Shop});

setting(list, Merchant, Conditions) ->
    gen_server:call(?SERVER, {list_base_setting, Merchant, Conditions});
setting(add, Merchant, Attr) ->
    gen_server:call(?SERVER, {add_base_setting, Merchant, Attr});
setting(update, Merchant, Update) ->
    gen_server:call(?SERVER, {update_base_setting, Merchant, Update});
setting(delete_from_shop, Merchant , Shop) ->
    gen_server:call(?SERVER, {delete_from_setting, Merchant, Shop}).


good(list_executive, Merchant) ->
    gen_server:call(?SERVER, {list_good_executive, Merchant});
good(list_safety_category, Merchant) ->
    gen_server:call(?SERVER, {list_safety_category, Merchant});
good(list_fabric, Merchant) ->
    gen_server:call(?SERVER, {list_fabric, Merchant});
good(list_ctype, Merchant) ->
    gen_server:call(?SERVER, {list_ctype, Merchant});
good(list_size_spec, Merchant) ->
    gen_server:call(?SERVER, {list_size_spec, Merchant}).

good(add_executive, Merchant, Name) ->
    gen_server:call(?SERVER, {add_good_executive, Merchant, Name});
good(update_executive, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_good_executive, Merchant, Attrs});

good(add_safety_category, Merchant, Name) ->
    gen_server:call(?SERVER, {add_safety_category, Merchant, Name});
good(update_safety_category, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_safety_category, Merchant, Attrs});

good(add_fabric, Merchant, Name) ->
    gen_server:call(?SERVER, {add_fabric, Merchant, Name});
good(update_fabric, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_fabric, Merchant, Attrs});

good(add_ctype, Merchant, Name) ->
    gen_server:call(?SERVER, {add_ctype, Merchant, Name});
good(update_ctype, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_ctype, Merchant, Attrs});

good(add_size_spec, Merchant, Attrs) ->
    gen_server:call(?SERVER, {add_size_spec, Merchant, Attrs});
good(update_size_spec, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_size_spec, Merchant, Attrs}).



%% barcode print
print(list_template, Merchant) ->
    gen_server:call(?SERVER, {list_barcode_print_template, Merchant}).
print(update_template, Merchant, Attrs) ->
    gen_server:call(?SERVER, {update_barcode_print_template, Merchant, Attrs}).
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================


init([]) ->
    {ok, #state{}}.

handle_call({new_bank_card, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_bank_card with merchant ~p, attr~p", [Merchant, Attrs]),
    CardName   = ?v(<<"name">>, Attrs),
    CardNo     = ?v(<<"no">>, Attrs),
    CardBank   = ?v(<<"bank">>, Attrs),
    CardType   = ?v(<<"type">>, Attrs, 0),
    CardRemark = ?v(<<"remark">>, Attrs, ""),

    Sql = "select id, no from w_bank_card where no=\'" ++ ?to_s(CardNo) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_bank_card(name, no, bank, type, remark, merchant"
		", entry_date) values("
		++ "\'" ++ ?to_s(CardName) ++ "\',"
		++ "\'" ++ ?to_s(CardNo) ++ "\',"
		++ "\'" ++ ?to_s(CardBank) ++ "\',"
		++ ?to_s(CardType) ++ ","
		++ "\'" ++ ?to_s(CardRemark) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localtime) ++ "\');",

	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _Any} ->
	    ?DEBUG("bank card ~p has been exist of merchant ~p", [CardNo, Merchant]),
	    {reply, {error, ?err(base_card_exist, CardNo)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_bank_card, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_bank_card with merchant ~p, attrs ~p", [Merchant, Attrs]),
    CardId     = ?v(<<"id">>, Attrs),
    CardNo     = ?v(<<"no">>, Attrs),
    CardBank   = ?v(<<"bank">>, Attrs),
    CardType   = ?v(<<"type">>, Attrs),

    Updates = ?utils:v(no, string, CardNo)
	++ ?utils:v(bank, string, CardBank)
	++ ?utils:v(type, integer, CardType),

    Sql = "update w_bank_card set" ++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, CardNo),
    {reply, Reply, State}; 

handle_call({delete_bank_card, Merchant, CardId}, _From, State) ->
    ?DEBUG("delete_bank_card with merchant ~p, CardId ~p", [Merchant, CardId]),

    Sql = "update w_bank_card set deleted=" ++ ?to_s(?YES)
	++ " where id=" ++ ?to_s(CardId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, CardId),
    {reply, Reply, State}; 
	
handle_call({list_bank_card, Merchant}, _From, State) ->
    ?DEBUG("list_bank_card with merchant ~p", [Merchant]),
    Sql = "select id, name, no, bank, type, remark, entry_date from w_bank_card"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({list_base_setting, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_base_setting with merchant ~p, condtions ~p", [Merchant, Conditions]), 
    Sql = "select id, ename, cname, value, type"
	", remark, shop, entry_date from w_base_setting"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({list_base_setting, Merchant}, _From, State) ->
    ?DEBUG("list_base_setting with merchant ~p", [Merchant]),

    Sql = "select id, ename, cname, value, type"
	", remark, shop, entry_date from w_base_setting"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({add_base_setting, Merchant, Attr}, _From, State) ->
    ?DEBUG("add_base_setting with merchant ~p, attr ~p", [Merchant, Attr]),
    EName  = ?v(<<"ename">>, Attr),
    CName  = ?v(<<"cname">>, Attr),
    Value  = ?v(<<"value">>, Attr),
    Type   = ?v(<<"type">>, Attr),
    Remark = ?v(<<"remark">>, Attr, []),
    Shop   = ?v(<<"shop">>, Attr, -1),

    Sql0 = "select id, ename, value from w_base_setting"
	" where shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and ename=\'" ++ ?to_s(EName) ++ "\'"
	++ " and deleted=" ++ ?to_s(?NO),
	%% ++ " and value=\'" ++ ?to_s(Value) ++ "\'",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into w_base_setting("
		"ename, cname, value, type, remark"
		", shop, merchant, entry_date) values("
		++ "\'" ++ ?to_s(EName) ++ "\',"
		++ "\'" ++ ?to_s(CName) ++ "\',"
		++ "\'" ++ ?to_s(Value) ++ "\',"
		++ ?to_s(Type) ++ ","
		++ "\'" ++ ?to_s(Remark) ++ "\',"
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localdate) ++ "\')", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State}; 
	{ok, _} ->
	    {reply, {error, ?err(base_setting_exist, EName)}, State};
	Error ->
	    {reply, Error, State}
    end;
	

handle_call({update_base_setting, Merchant, Update}, _From, State) ->
    ?DEBUG("update_base_setting with merchant ~p, update ~p",
	   [Merchant, Update]),

    Id    = ?v(<<"id">>, Update),
    EName = ?v(<<"ename">>, Update),
    Value = ?v(<<"value">>, Update),
    Shop  = ?v(<<"shop">>, Update),

    Sql = "update w_base_setting set value=\'" ++ ?to_s(Value) ++ "\'"
	++ " where id=" ++ ?to_s(Id)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, EName),
    %% refresh profile
    ?w_user_profile:update(setting, Merchant),
    ?w_retailer:syn(prompt, Merchant),
    {reply, Reply, State};

handle_call({add_shop_setting, Merchant, Shop}, _From, State) ->
    ?DEBUG("add_shop_setting with merchant ~p, shop ~p", [Merchant, Shop]),
    Now = ?utils:current_time(localdate),

    %% one month default
    %% {M, S, T} = erlang:now(),
    %% {{YY, MM, DD}, _} = calendar:now_to_datetime({M, S - 86400 * 30, T}),
    %% DefaultDate = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [YY, MM, DD])), 
    
    Values = sys_config(shop), 
    Sql0 = lists:foldr(
	     fun({EName, CName, Value, Type}, Acc) ->
		     Sql00 = "select id, ename, value from w_base_setting"
			 " where ename=\'" ++ EName ++ "\'"
			 ++ " and shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant),
		     case ?sql_utils:execute(s_read, Sql00) of
			 {ok, []} ->
			     ["insert into w_base_setting("
			      "ename, cname, value, type"
			      ", shop, merchant, entry_date) values("
			      "\'" ++ EName ++ "\',"
			      "\'" ++ CName ++ "\',"
			      ++ "\'" ++ ?to_s(Value) ++ "\',"
			      ++ Type  ++ ","
			      ++ ?to_s(Shop) ++ ","
			      ++ ?to_s(Merchant) ++ "," 
			      "\'" ++ Now ++ "\');"|Acc];
			 {ok, _} ->
			     Acc
		     end
	     end, [], Values),

    Reply = ?sql_utils:execute(transaction, Sql0, Shop),
    ?w_user_profile:update(setting, Merchant),
    {reply, Reply, State};

handle_call({delete_from_setting, Merchant, Shop}, _From, State) ->
    ?DEBUG("delete_from_setting with merchant ~p, shop ~p", [Merchant, Shop]),

    %% Id    = ?v(<<"id">>, Update),
    %% EName = ?v(<<"ename">>, Update),
    %% Value = ?v(<<"value">>, Update),
    %% Shop  = ?v(<<"shop">>, Update),

    Sql = "delete from w_base_setting where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop),

    Reply = ?sql_utils:execute(write, Sql, Shop),
    %% refresh profile
    %% ?w_user_profile:update(setting, Merchant),
    %% ?w_retailer:syn(prompt, Merchant),
    {reply, Reply, State};

handle_call({add_good_executive, Merchant, Name}, _From, State) ->
    ?DEBUG("add_good_executive: Merchant  ~p, Name ~p", [Merchant, Name]),

    Sql0 = "select id, name from std_executive"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "insert into std_executive(name, merchant) values("
		    ++ "\'" ++ ?to_s(Name) ++ "\',"
		    ++ ?to_s(Merchant) ++ ")",
		?sql_utils:execute(insert, Sql01);
	    {ok, _R} ->
		{error, ?err(good_safety_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({list_good_executive, Merchant}, _From, State) ->
    ?DEBUG("list_good_executive: Merchant  ~p", [Merchant]),

    Sql0 = "select id, name from std_executive"
	" where merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_good_executive, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_good_executive: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"eid">>, Attrs),
    Name = ?v(<<"name">>, Attrs),

    Sql0 = "select id, name from std_executive"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "update std_executive set"
		    ++ " name=\'" ++ ?to_s(Name) ++ "\'"
		    ++ " where id=" ++ ?to_s(Id), 
		?sql_utils:execute(write, Sql01, Id);
	    {ok, _R} ->
		{error, ?err(good_safety_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};


handle_call({add_safety_category, Merchant, Name}, _From, State) ->
    ?DEBUG("add_safety_category: Merchant  ~p, Name ~p", [Merchant, Name]),

    Sql0 = "select id, name from safety_category"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "insert into safety_category(name, merchant) values("
		    ++ "\'" ++ ?to_s(Name) ++ "\',"
		    ++ ?to_s(Merchant) ++ ")",
		?sql_utils:execute(insert, Sql01);
	    {ok, _R} ->
		{error, ?err(good_safety_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({list_safety_category, Merchant}, _From, State) ->
    ?DEBUG("list_good_safety: Merchant  ~p", [Merchant]), 
    Sql0 = "select id, name from safety_category"
	" where merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_safety_category, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_safety_category: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"cid">>, Attrs),
    Name = ?v(<<"name">>, Attrs),

    Sql0 = "select id, name from safety_category"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "update safety_category set name=\'" ++ ?to_s(Name) ++ "\'"
		    ++ " where id=" ++ ?to_s(Id), 
		?sql_utils:execute(write, Sql01, Id);
	    {ok, _R} ->
		{error, ?err(good_safety_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};


handle_call({add_fabric, Merchant, Name}, _From, State) ->
    ?DEBUG("add_fabric: Merchant  ~p, Name ~p", [Merchant, Name]),

    Sql0 = "select id, name from fabric"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "insert into fabric(name, merchant) values("
		    ++ "\'" ++ ?to_s(Name) ++ "\',"
		    ++ ?to_s(Merchant) ++ ")",
		?sql_utils:execute(insert, Sql01);
	    {ok, _R} ->
		{error, ?err(good_fabric_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({list_fabric, Merchant}, _From, State) ->
    ?DEBUG("list_fabric: Merchant  ~p", [Merchant]), 
    Sql0 = "select id, name from fabric where merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_fabric, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_fabric: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"fid">>, Attrs),
    Name = ?v(<<"name">>, Attrs),

    Sql0 = "select id, name from fabric where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "update fabric set name=\'" ++ ?to_s(Name) ++ "\'"
		    ++ " where id=" ++ ?to_s(Id), 
		?sql_utils:execute(write, Sql01, Id);
	    {ok, _R} ->
		{error, ?err(good_fabric_exist,?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({add_ctype, Merchant, Name}, _From, State) ->
    ?DEBUG("add_ctype: Merchant  ~p, Name ~p", [Merchant, Name]), 
    %% Name = ?v(<<"name">>, Attrs),
    %% Spec = ?v(<<"spec">>, Attrs, []),
    
    Sql0 = "select id, name from type_class"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Sql01 = "insert into type_class(name, merchant) values("
		    ++ "\'" ++ ?to_s(Name) ++ "\',"
		%% ++ "\'" ++ ?to_s(Spec) ++ "\',"
		    ++ ?to_s(Merchant) ++ ")",
		?sql_utils:execute(insert, Sql01);
	    {ok, _R} ->
		{error, ?err(good_ctype_exist, ?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({list_ctype, Merchant}, _From, State) ->
    ?DEBUG("list_ctype: Merchant  ~p", [Merchant]), 
    Sql0 = "select id, name from type_class where merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_ctype, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_fabric: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"cid">>, Attrs),
    Name = ?v(<<"name">>, Attrs),
    %% Spec = ?v(<<"spec">>, Attrs),

    Sql0 = "select id, name from type_class where merchant=" ++ ?to_s(Merchant)
	++ " and name=\'" ++ ?to_s(Name) ++ "\'",

    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
	        Updates = ?utils:v(name, string, Name), 
		Sql01 = "update type_class set "
		    ++ ?utils:to_sqls(proplists, comma, Updates)
		    ++ " where id=" ++ ?to_s(Id),
		?sql_utils:execute(write, Sql01, Id);
	    {ok, _R} ->
		{error, ?err(good_ctype_exist, ?to_s(?v(<<"id">>, _R)))};
	    Error ->
		Error
	end, 
    {reply, Reply, State};


handle_call({add_size_spec, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_ctype: Merchant  ~p, Attrs ~p", [Merchant, Attrs]), 
    Name  = ?v(<<"name">>, Attrs),
    Spec  = ?v(<<"spec">>, Attrs, []),
    CType = ?v(<<"cid">>, Attrs, -1),

    case ?attr:invalid_size(Name) of
	true ->
	    {reply, {error, ?err(good_size_spec_invalid_size, Name)}, State};
        false -> 
	    Sql0 = "select id, name from size_spec"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and name=\'" ++ ?to_s(Name) ++ "\'"
		++ " and ctype=" ++ ?to_s(CType),

	    Reply = 
		case ?sql_utils:execute(s_read, Sql0) of
		    {ok, []} ->
			Sql01 = "insert into size_spec(name, spec, ctype, merchant) values("
			    ++ "\'" ++ ?to_s(Name) ++ "\',"
			    ++ "\'" ++ ?to_s(Spec) ++ "\',"
			    ++ ?to_s(CType) ++ ","
			    ++ ?to_s(Merchant) ++ ")",
			?sql_utils:execute(insert, Sql01);
		    {ok, _R} ->
			{error, ?err(good_size_spec_exist, ?to_s(?v(<<"id">>, _R)))};
		    Error ->
			Error
		end, 
	    {reply, Reply, State}
    end;

handle_call({list_size_spec, Merchant}, _From, State) ->
    ?DEBUG("list_size_spec: Merchant  ~p", [Merchant]), 
    Sql0 = "select id, name, spec, ctype as cid from size_spec where merchant=" ++ ?to_s(Merchant)
	++ " order by id",
    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_size_spec, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_size_spec: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id    = ?v(<<"sid">>, Attrs),
    Name  = ?v(<<"name">>, Attrs),
    Spec  = ?v(<<"spec">>, Attrs),
    CType = ?v(<<"cid">>, Attrs),

    UpdateFun =
	fun() ->
		Updates = ?utils:v(name, string, Name)
		    ++ ?utils:v(spec, string, Spec)
		    ++ ?utils:v(ctype, integer, CType),
		Sql01 = "update size_spec set "
		    ++ ?utils:to_sqls(proplists, comma, Updates)
		    ++ " where id=" ++ ?to_s(Id),
		?sql_utils:execute(write, Sql01, Id)
	end,

    Reply =
	case Name of
	    undefined ->
		UpdateFun();
	    _ ->
		case ?attr:invalid_size(Name) of
		    true ->
			{error, ?err(good_size_spec_invalid_size, Name)};
		    false ->
			Sql0 = "select id, name from size_spec"
			    " where merchant=" ++ ?to_s(Merchant)
			    ++ " and name=\'" ++ ?to_s(Name) ++ "\'"
			    ++ " and ctype=" ++ ?to_s(CType),
			case ?sql_utils:execute(s_read, Sql0) of
			    {ok, []} ->
				UpdateFun();
			    {ok, _R} ->
				{error, ?err(good_size_spec_exist, ?to_s(?v(<<"id">>, _R)))};
			    Error ->
				Error
			end
		end
	end,
    {reply, Reply, State};

handle_call({list_barcode_print_template, Merchant}, _From, State) ->
    ?DEBUG("list_barcode_print_template: Merchant  ~p", [Merchant]), 
    Sql0 = "select id"
	", name"
	", label"
	", tshop as tshop_id"
	
	", width"
	", height"
	
	", shop"
	", style_number"
	", brand"
	", type"
	", stock"
	", firm"
	", code_firm"

	", p_virprice"
	", p_tagprice"
	
	", expire"
	", shift_date"
	
	", color"
	", size"
	", size_spec"

	", level"
	", executive"
	", category"
	", fabric"
	", feather"
	
	", font"
	", font_name"
	", font_executive"
	", font_category"
	", font_price"
	", font_size"
	", font_fabric"
	", font_feather"
	", font_label"
	", font_type"
	", font_sn"
    %% ", font_vprice"
	
	", bold"
	
	", solo_brand"
	", solo_color"
	", solo_size"
	", solo_date"
	
	", hpx_each"
	", hpx_executive"
	", hpx_category"
	", hpx_fabric"
	", hpx_feather"
	", hpx_price"
	", hpx_size"
	", hpx_barcode"
	", hpx_label"
	", hpx_type"
	", hpx_sn"

	", hpx_top"
	", hpx_left"
	", second_space"

	", solo_snumber"
	", len_snumber"
	", count_type"

	", size_date"
	", size_color"
	", firm_date"

	", tag_price"
	", vir_price"
	", my_price"
	", self_brand"
	
	", offset_size"
	", offset_color"
	", offset_tagprice"
	", offset_virprice"
	", offset_myprice" 
	", offset_label"
	", offset_type"
	", offset_fabric"
	", offset_fabric3"
	", offset_feather"
	", offset_barcode"
	", offset_sn"
	
	", barcode"
	", w_barcode"

	", printer"
	", dual_print"
	
	" from print_template"
	" where merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_barcode_print_template, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_barcode_print_template: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"id">>, Attrs),
    U =?utils:v(name, string, ?v(<<"name">>, Attrs))
	++ ?utils:v(label, string, ?v(<<"label">>, Attrs))
	++ ?utils:v(width, float, ?v(<<"width">>, Attrs)) 
	++  ?utils:v(height, float, ?v(<<"height">>, Attrs))
    %% ++  ?utils:v(height, integer, ?v(<<"dual_column">>, Attrs))

	++  ?utils:v(shop, integer, ?v(<<"shop">>, Attrs))
	++  ?utils:v(style_number, integer, ?v(<<"style_number">>, Attrs))
	++  ?utils:v(brand, integer, ?v(<<"brand">>, Attrs))
	++  ?utils:v(type, integer, ?v(<<"type">>, Attrs))
	++  ?utils:v(stock, integer, ?v(<<"stock">>, Attrs))
	++  ?utils:v(firm, integer, ?v(<<"firm">>, Attrs))
	++  ?utils:v(code_firm, integer, ?v(<<"code_firm">>, Attrs))

	++  ?utils:v(p_virprice, integer, ?v(<<"p_virprice">>, Attrs))
	++  ?utils:v(p_tagprice, integer, ?v(<<"p_tagprice">>, Attrs))
	
	++  ?utils:v(expire, integer, ?v(<<"expire">>, Attrs))
	++  ?utils:v(shift_date, integer, ?v(<<"shift_date">>, Attrs))
	
	++  ?utils:v(color, integer, ?v(<<"color">>, Attrs))
	++  ?utils:v(size, integer, ?v(<<"size">>, Attrs))
	++  ?utils:v(size_spec, integer, ?v(<<"size_spec">>, Attrs))
	
	++  ?utils:v(level, integer, ?v(<<"level">>, Attrs))
	++  ?utils:v(executive, integer, ?v(<<"executive">>, Attrs))
	++  ?utils:v(category, integer, ?v(<<"category">>, Attrs))
	++  ?utils:v(fabric, integer, ?v(<<"fabric">>, Attrs))
	++  ?utils:v(feather, integer, ?v(<<"feather">>, Attrs))

	++  ?utils:v(font, integer, ?v(<<"font">>, Attrs))
	++  ?utils:v(font_name, string, ?v(<<"font_name">>, Attrs))
	++  ?utils:v(font_executive, integer, ?v(<<"font_executive">>, Attrs))
	++  ?utils:v(font_category, integer, ?v(<<"font_category">>, Attrs))
	++  ?utils:v(font_price, integer, ?v(<<"font_price">>, Attrs))
	++  ?utils:v(font_size, integer, ?v(<<"font_size">>, Attrs))
	++  ?utils:v(font_fabric, integer, ?v(<<"font_fabric">>, Attrs))
	++  ?utils:v(font_feather, integer, ?v(<<"font_feather">>, Attrs))
	++  ?utils:v(font_label, integer, ?v(<<"font_label">>, Attrs))
	++  ?utils:v(font_type, integer, ?v(<<"font_type">>, Attrs))
	++  ?utils:v(font_sn, integer, ?v(<<"font_sn">>, Attrs))
    %% ++  ?utils:v(font_vprice, integer, ?v(<<"font_vprice">>, Attrs))
	
	++  ?utils:v(bold, integer, ?v(<<"bold">>, Attrs))
	
	++  ?utils:v(solo_brand, integer, ?v(<<"solo_brand">>, Attrs))
	++  ?utils:v(solo_color, integer, ?v(<<"solo_color">>, Attrs))
	++  ?utils:v(solo_size, integer, ?v(<<"solo_size">>, Attrs))
	++  ?utils:v(solo_date, integer, ?v(<<"solo_date">>, Attrs))

	++  ?utils:v(hpx_each, integer, ?v(<<"hpx_each">>, Attrs))
	++  ?utils:v(hpx_executive, integer, ?v(<<"hpx_executive">>, Attrs))
	++  ?utils:v(hpx_category, integer, ?v(<<"hpx_category">>, Attrs))
	++  ?utils:v(hpx_fabric, integer, ?v(<<"hpx_fabric">>, Attrs))
	++  ?utils:v(hpx_feather, integer, ?v(<<"hpx_feather">>, Attrs))
	++  ?utils:v(hpx_price, integer, ?v(<<"hpx_price">>, Attrs))
	++  ?utils:v(hpx_size, integer, ?v(<<"hpx_size">>, Attrs))
	++  ?utils:v(hpx_barcode, integer, ?v(<<"hpx_barcode">>, Attrs))
	++  ?utils:v(hpx_label, integer, ?v(<<"hpx_label">>, Attrs))
	++  ?utils:v(hpx_type, integer, ?v(<<"hpx_type">>, Attrs))
	++  ?utils:v(hpx_sn, integer, ?v(<<"hpx_sn">>, Attrs))

	++  ?utils:v(hpx_top, integer, ?v(<<"hpx_top">>, Attrs))
	++  ?utils:v(hpx_left, integer, ?v(<<"hpx_left">>, Attrs))
	++  ?utils:v(second_space, integer, ?v(<<"second_space">>, Attrs))

	++  ?utils:v(solo_snumber, integer, ?v(<<"solo_snumber">>, Attrs))
	++  ?utils:v(len_snumber, integer, ?v(<<"len_snumber">>, Attrs))
	++  ?utils:v(count_type, integer, ?v(<<"count_type">>, Attrs))

	++  ?utils:v(size_date, integer, ?v(<<"size_date">>, Attrs))
	++  ?utils:v(size_color, integer, ?v(<<"size_color">>, Attrs))
	++  ?utils:v(firm_date, integer, ?v(<<"firm_date">>, Attrs))

	++  ?utils:v(tag_price, string, ?v(<<"tag_price">>, Attrs))
	++  ?utils:v(vir_price, string, ?v(<<"vir_price">>, Attrs))
	++  ?utils:v(my_price, string, ?v(<<"my_price">>, Attrs))
	++  ?utils:v(self_brand, string, ?v(<<"self_brand">>, Attrs))
	
	++  ?utils:v(offset_size, integer, ?v(<<"offset_size">>, Attrs))
	++  ?utils:v(offset_color, integer, ?v(<<"offset_color">>, Attrs))
	++  ?utils:v(offset_tagprice, integer, ?v(<<"offset_tagprice">>, Attrs))
	++  ?utils:v(offset_virprice, integer, ?v(<<"offset_virprice">>, Attrs))
	++  ?utils:v(offset_myprice, integer, ?v(<<"offset_myprice">>, Attrs)) 
	++  ?utils:v(offset_label, integer, ?v(<<"offset_label">>, Attrs))
	++  ?utils:v(offset_type, integer, ?v(<<"offset_type">>, Attrs))
	++  ?utils:v(offset_fabric, integer, ?v(<<"offset_fabric">>, Attrs))
	++  ?utils:v(offset_fabric3, integer, ?v(<<"offset_fabric3">>, Attrs))
	++  ?utils:v(offset_feather, integer, ?v(<<"offset_feather">>, Attrs))
	++  ?utils:v(offset_barcode, integer, ?v(<<"offset_barcode">>, Attrs))
	++  ?utils:v(offset_sn, integer, ?v(<<"offset_sn">>, Attrs))

	++  ?utils:v(barcode, integer, ?v(<<"barcode">>, Attrs))
	++  ?utils:v(w_barcode, integer, ?v(<<"w_barcode">>, Attrs))

	++  ?utils:v(printer, integer, ?v(<<"printer">>, Attrs))
	++  ?utils:v(dual_print, integer, ?v(<<"dual_print">>, Attrs)),
    
    Sql = "update print_template set " ++ ?utils:to_sqls(proplists, comma, U)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Id), 

    Reply = ?sql_utils:execute(write, Sql, Id),
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
sys_config(shop) ->
    [{"pum",             "打印份数",            "11",  "0"},
     {"ptype",           "打印方式",            "1",  "0"}, %% 0: front; 1:backend
     {"pim_print",       "立即打印",            "0",  "0"},

     {"reject_negative", "零库存退货",           "0",  "0"},
     {"check_sale",      "检测库存销售",         "1",  "0"}, 

     {"h_stock_edit",    "采购编辑展示历史记录", "0",   "0"},
     {"m_sgroup",        "允许多尺码组",         "0",   "0"},
     {"t_trace",         "入库价格跟踪",         "0",   "0"},
     {"d_sex",           "默认入库性别",         "0",   "0"},
     {"m_sale",          "允许负数退货",         "1",   "0"},
     {"round",           "四舍五入",             "1",   "0"},
     {"h_stock",         "入库字段隐藏",
      "0001"++"1011"++"1111"++"0111"++"0000"++"11111", "0"},
     
     {"consume_sms",     "消费短信提醒",         "0",   "0"}, 

     {"p_balance",
      "销售模式",
      "0000"++"0000"++"0000"++"0001"++"0000"++"0000"++"0010"++"0", "0"},
     
     {"s_member",        "会员区域隔离",             "0",   "0"},
     {"s_employee",      "营业员必选",           "0",   "0"},
     
     %% {"prn_barcode",       "条码打印机编号",     "-1",   "0"},
     {"prn_bill",          "单据打印机编号",     "-1",   "0"},
     {"prn_h_page",        "单据纸张高",         "14.0", "0"},
     {"prn_w_page",        "单据纸张宽",         "21.3", "0"},
     
     {"draw_score",        "提现积分",           "1",    "0"}, 
     %% {"dual_barcode",      "双排条码",           "0",    "0"},

     {"r_discount",        "会员折扣模式",       "0000", "0"},
     {"scan_only",         "扫码模式",           "0000000111", "0"},
     {"maling_rang",       "抹零范围",           "3",    "0"}
    ].
    
sys_config() ->
    %% one month default
    {M, S, T} = erlang:now(), 
    {{YY, MM, DD}, _} = calendar:now_to_datetime({M, S - 86400 * 30, T}),
    DefaultDate = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [YY, MM, DD])),
    
    %%         ename,             cname,                 value,type
    %% [0]: common print num
    %% [1]: swiming print num
    %% [2]: print protocal 0:http 1:https default 0
    %% [3]: remain
    %% [4]: print with A4
    Values = [{"pum",             "打印份数",            "11010",  "0"},
	      %% 0: front;
	      %% 1: backend
	      {"ptype",           "打印方式",            "1",     "0"}, 
	      {"pim_print",       "立即打印",            "0",     "0"},

	      {"qtime_start",     "联想开始时间",        DefaultDate,  "0"}, 
	      {"qtypeahead",      "联想方式",            "1",    "0"}, %% 0: front; 1:backend 
	      {"prompt",          "联想数目",            "20",   "0"},

	      %% {"stock_alarm",     "库存告警",             "0",  "0"},
	      {"reject_negative", "零库存退货",           "0",  "0"},
	      {"check_sale",      "检测库存销售",         "1",  "0"},
	      
	      {"se_pagination",   "顺序翻页",             "0",  "0"}, 
	      {"h_stock_edit",    "采购编辑展示历史记录", "0",   "0"},
	      {"m_sgroup",        "允许多尺码组",         "0",   "0"},
	      {"t_trace",         "入库价格跟踪",         "0",   "0"},
	      {"d_sex",           "默认入库性别",         "0",   "0"},
	      {"d_report",        "日报表能力",           "0",   "0"},
	      {"m_sale",          "允许负数退货",         "1",   "0"},
	      {"group_color",     "颜色分组",             "1",   "0"},
	      {"image_mode",      "图片模式",             "0",   "0"},
	      %% 0: round none
	      %% 1: round multi good on sale
	      %% 2: round single good on sale
	      {"round",           "四舍五入",             "1",   "0"},
	      
	      %% [0]: hide color
	      %% [1]: hide size
	      %% [2]: hide sex
	      %% [3]: hide expire
	      %% [4]: hide image
	      %% [5]: type should be select
	      %% [6]: hide std_executive
	      %% [7]: hide std_category
	      %% [8]: hide level
	      %% [9]: hide fabric
	      %% [10]: hide vir_price
	      %% [11]: hide promotion price
	      %% [12]: hide discount 
	      %% [13]: hide unit
	      %% [14]: hide barcode
	      %% [15]: hide feather
	      %% [16]: none score with promotion 0:yes, 1:no
	      %% [17-18]: 80-> vir_price * 0.8 = tag_price, 00 -> none
	      %% [19]: print label with dialog 0: no dialog, 1: dialog
	      %% [20]: hide fixed draw or reduction, refer to sale_mode[28]
	      %% [21]: hide commision
	      %% [22]: hide product_batch
	      %% [23]: hide gen_date
	      %% [24]: hide valid_date
	      {"h_stock",         "入库字段隐藏",
	       "0001"++"1011"++"1111"++"0111"++"0000"++"11111", "0"},
	      
	      {"s_member",        "会员区域隔离",         "0",   "0"},
	      {"s_employee",      "营业员必选",           "0",   "0"},

	      %% [0]: print balance of charge vip
	      %% [1]: show color size when on sale
	      %% [2]: print sale note when switch shift
	      %% [3]: print perform when on sale
	      %% [4]: distinct account when on sale
	      %% [5]: hide charge on sale
	      %% [6]: print title when on stock out
	      %% [7]: print sale body on swiming comsume
	      %% [8]: scanner device 0:idata 1:c40
	      %% [9]: hide password for retailer
	      %% [10]: hide bill info on stock in
	      %% [11]: hide bsaler when on batchsale
	      %% [12]: virtual price name 0: virtual price 1: batch price
	      %% [13]: default price when on sale 0:tag_price, 1:vir_price
	      %% [14]: show whole price on sale
	      %% [15]: print discount on sale
	      %% [16-17]: threshold discount of score 00:none
	      %% [18]: gift good on sale directly 0: none, 1:send good directly
	      %% [19]: gift_ticket 0: gift ticket on sale direct, 1:gift ticket with sale recode
	      %% [20]: charge special 0: none, 1:special stock can charge
	      %% [21]: allowed multi ticket 0:limit, 1:allowed
	      %% [22]: gift ticket strategy 0:only one max ticket, 1:greed strategy
	      %% [23]: head title seperater by '-' when print.
	      %% 0:one line and align left,
	      %% 1:both seperaer by '-' and align center
	      %% 2:both seperaer by '-' and align left
	      %% 3:one line and align center
	      %% [24]: use pay scan
	      %% [25]: disable withdarw on sale
	      %% [26]: print score information of retailer
	      %% [27]: interval print
	      %% [28]: stock with fixed mode, 1:fixed draw, 2:fixed reduction. refer to hide_mode[20]
	      %% [29]: check retailer trans count, 0 means nocheck
	      %% [30]: remain
	      %% [31]: remain
	      %% [32]: which pay_scan to use 0:wwt, 1:yc, 2:sx, default 0
	      %% [33]: can save sale when then money is not enought 0: not allowed, 1:allowed
	      %% [34]: use member discount when take ticket. 1: use
	      %% [35]: active score when on sale
	      %% [36]: hide member info such as 188****9999
	      %% [37-38]: every charactor per line when print note default 14;
	      %% [39]: withdraw 0:auto calc; 1:list account to select
	      %% [40]: verificate code when draw or ticket.
	      %% 0:none,
	      %% 1:use verificate code in ticket or withdraw
	      %% 2: use verificate code allways
	      %% [41]: update score. 0: update directly, 1: add mode
	      {"p_balance",
	       "销售模式",
	       "0000"++"0000"++"0000"++"0001" ++ "0000"++"0000"++"0010"++"0030"
	       ++ "0010" ++ "0000" ++ "0", "0"},

	      %% [0]: auto generate ticket at 04:00
	      %% [1]: use ticket with no check 0-> check 1-> no check
	      %% [2]: part calculate total score to genrate ticket 0:total 1:part
	      {"gen_ticket",      "自动生成电子卷",       "000",   "0"},
	      
	      %% [0]: recharge notify
	      %% [1]: threshold_card consume notify
	      %% [2]: gift ticket notify
	      %% [3]: birth notify at 9:00 am
	      %% [4]: update score notify
	      {"recharge_sms",    "充值短信提醒",         "00000",   "0"},	      
	      {"consume_sms",     "消费短信提醒",         "0",   "0"},
	      
	      {"price_on_region", "按区域填写价格",       "0",   "0"},
	      {"wsale_import",    "导入淘宝销售单",       "0",   "0"},
	      {"stock_warning",   "库存预警",             "0",   "0"},
	      {"stock_warning_a", "库存预警数量",         "0",   "0"},
	      {"stock_contailer", "货品货柜号",           "0",   "0"},
	      
	      %% [0] check firm when stock in
	      %% [1] check original price when stock transfer
	      
	      %% [2] check original price when stock out
	      %% [3] check frim when stock out

	      %% [4] check original price wheen stock check
	      %% [5] check firm when stock check

	      %% [6] check firm when stock transfer
	      {"stock_firm",      "入库区分厂商",         "1111111",   "0"},

	      
	      {"bcode_use",       "条码开单模式",         "0",   "0"},
	      %% 0: year + flow; 1: year + season + type + flow; 2:use style_number
	      {"bcode_auto",      "采用系统规则生成条码", "1",   "0"}, 
	      %% {"trans_orgprice",  "移仓检测进价",         "1",   "0"},

	      
	      %% [0]: print color and size
	      %% [1]: print color only
	      %% [2]: print size only
	      %% 000: no color and no size

	      %% batch mode
	      %% [3]:  hide unit when print
	      %% [4]:  hide bcode friend when print
	      %% [5]:  hide bcode pay when print
	      %% [6]:  hide address when print
	      %% [7]:  hide discount when print
	      %% [8]:  hide tag price when print
	      %% [9]:  hide vir price when print
	      %% [10]: hide batch retailer balance info when print
	      %% [11]: hide batch retailer code when print
	      %% [12]: hide comment
	      %% [13]: hide product_batch, gen_date, valid_date
	      {"p_color_size",    "打印颜色尺码",         "00011111110111", "0"},
	      
	      {"saler_stock",      "营业员查看区域库存",  "0",   "0"},
	      %% {"r_stock_oprice",    "厂商退货检测进价",   "1",   "0"},
	      %% {"c_stock_oprice",    "入库审核检测进价",   "1",   "0"},
	      %% {"c_stock_firm",      "入库审核检测厂商",   "1",   "0"},
	      {"export_code",       "导出编码格式",       "0",   "0"}, %% 0: utf8 1: gbk
	      {"export_note",       "导出颜色尺码",       "0",   "0"}, %% 0: utf8 1: gbk

	      %% {"prn_barcode",       "条码打印机编号",     "-1",   "0"},
	      {"prn_bill",          "单据打印机编号",     "-1",   "0"},
	      {"prn_h_page",        "单据纸张高",         "14.0", "0"},
	      {"prn_w_page",        "单据纸张宽",         "21.3", "0"},
	      {"draw_score",        "提现积分",           "1",    "0"},
	      %% {"dual_barcode",      "双排条码",           "0",    "0"},
	      {"draw_region",       "区域提现",           "0",    "0"},
	      {"threshold_card",    "次卡消费模式",       "0",    "0"},
	      %% vip mode
	      %% case 1: 1000 or 2100 when the shop take score promotion,
	      %%         no score measn no discount any

	      %% case 2: 1010 or 2010 when the shop no score promotion,
	      %%         should be take vip discount any

	      %% case 3: 1011 or 2011 when the shop take score and stock promotion,
	      %%         used in child mode usually

	      %% case 4: 1001 or 2001
	      
	      %% [0]: 0-> no vip discount
	      %%      1-> vip discount only,
	      %%      2-> vip discount  on discount
	      %% [1]: auto check level at 5:00 am
	      
	      %% [2]: use vir_price or not
	      %%      0: tag_price default
	      %%      1: vir_price
	      %% [3]: 
	      %%      1-> score with discount of every stock
	      {"r_discount",        "会员折扣模式",       "0000",    "0"},
	      
	      %% {"r_level",        "会员等级模式",       "0",    "0"},
	      
	      %% [0]: 0->gift none, 1->use gift mode
	      %% [1]: 0->commision none, 1-> commision mode
	      {"gift_sale",         "开单赠送模式",       "0",    "0"},
	      
	      %%[0]:scan sale only
	      %%[1]:add scan mode when stock_in
	      %%[2]:add scan mode when stock_out
	      %% [1] both scan and input
	      %% [2] scan only
	      %%[3]:add scan mode when stock_transfer
	      %%[4]:foucs styleNumber when barcode use
	      %%[5]:show tag_price in stock transfer
	      %%[6]:xsale mode only used to batch sale transfer
	      %%[7]:stock transfer mode
	      %%    0-> common transfer 
	      %%    1-> fast transfer no dialog pop
	      %%[8]:check stock when stock transfer 0:uncheck, 1:check
	      %%[9]:stock reject mode
	      %%    0 -> common reject
	      %%    1 -> fast reject
	      %%[10]:member mode, 0 default
	      %%    0 -> input manual
	      %%    1 -> scan by weapp
	      {"scan_only",         "扫码模式",           "00000001110", "0"},
	      %% {"auto_level",        "会员自动升级",       "0",    "0"},
	      {"maling_rang",       "抹零范围",           "3",    "0"},
	      %% 1: different mode has different dashboard
	      %% 0: clothes common
	      %% 1: water common
	      {"shop_mode",         "店铺模式",           "1",    "0"},
	      {"type_sale",         "品类开单模式",       "0",    "0"},

	      %%--------------------------------------------------------------------------------
	      %% batch mode
	      %%--------------------------------------------------------------------------------
	      %%[0]:print with no check
	      %%[1]:hide tag price when battch sale
	      %%[2]:hide vir price when batch sale
	      %%[3]:hide discount when batch sale
	      %%[4]:hide whole discount when batch sale
	      %%[5]:hide properties when batch sale
	      %%[6]:hide comment when batch sale
	      %%[7]:hide whole comment when batch sale
	      {"batch_mode",        "批发配置",           "01111111",    "0"}
	     ],
    
    Values.
