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
    CardRemark = ?v(<<"remark">>, Attrs, ""),

    Sql = "select id, no from w_bank_card where no=\'" ++ ?to_s(CardNo) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into w_bank_card(name, no, bank, remark, merchant"
		", entry_date) values("
		++ "\'" ++ ?to_s(CardName) ++ "\',"
		++ "\'" ++ ?to_s(CardNo) ++ "\',"
		++ "\'" ++ ?to_s(CardBank) ++ "\',"
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

    Sql = "update w_bank_card set"
	" no=\'"   ++ ?to_s(CardNo) ++ "\',"
	" bank=\'" ++ ?to_s(CardBank) ++ "\'"
	" where id=" ++ ?to_s(CardId)
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
    Sql = "select id, name, no, bank, remark, entry_date from w_bank_card"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({list_base_setting, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_base_setting with merchant ~p, condtions ~p",
	   [Merchant, Conditions]),

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
	", width"
	", height"
    %% ", dual_column"
	
	", style_number"
	", brand"
	", type"
	", firm"
	", code_firm"
	", expire"
	
	", color"
	", size"

	", level"
	", executive"
	", category"
	", fabric"

	", font"
	", font_name"
	", font_executive"
	", font_category"
	", font_price"
	", font_fabric"
	
	", bold"
	
	", solo_brand"
	", solo_color"
	", solo_size"
	
	", hpx_each"
	", hpx_executive"
	", hpx_category"
	", hpx_fabric"
	", hpx_price"
	", hpx_barcode"

	", hpx_top"
	", hpx_left"
	", second_space"
	
	" from print_template"
	" where merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(read, Sql0),
    {reply, Reply, State};

handle_call({update_barcode_print_template, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_barcode_print_template: Merchant ~p, attrs ~p", [Merchant, Attrs]),
    Id = ?v(<<"id">>, Attrs),
    U = ?utils:v(width, integer, ?v(<<"width">>, Attrs))
	++  ?utils:v(height, integer, ?v(<<"height">>, Attrs))
    %% ++  ?utils:v(height, integer, ?v(<<"dual_column">>, Attrs))
	
	++  ?utils:v(style_number, integer, ?v(<<"style_number">>, Attrs))
	++  ?utils:v(brand, integer, ?v(<<"brand">>, Attrs))
	++  ?utils:v(type, integer, ?v(<<"type">>, Attrs))
	++  ?utils:v(firm, integer, ?v(<<"firm">>, Attrs))
	++  ?utils:v(code_firm, integer, ?v(<<"code_firm">>, Attrs))
	++  ?utils:v(expire, integer, ?v(<<"expire">>, Attrs))
	
	++  ?utils:v(color, integer, ?v(<<"color">>, Attrs))
	++  ?utils:v(size, integer, ?v(<<"size">>, Attrs))
	
	++  ?utils:v(level, integer, ?v(<<"level">>, Attrs))
	++  ?utils:v(executive, integer, ?v(<<"executive">>, Attrs))
	++  ?utils:v(category, integer, ?v(<<"category">>, Attrs))
	++  ?utils:v(fabric, integer, ?v(<<"fabric">>, Attrs))

	++  ?utils:v(font, integer, ?v(<<"font">>, Attrs))
	++  ?utils:v(font_name, string, ?v(<<"font_name">>, Attrs))
	++  ?utils:v(font_executive, integer, ?v(<<"font_executive">>, Attrs))
	++  ?utils:v(font_category, integer, ?v(<<"font_category">>, Attrs))
	++  ?utils:v(font_price, integer, ?v(<<"font_price">>, Attrs))
	++  ?utils:v(font_fabric, integer, ?v(<<"font_fabric">>, Attrs))
	
	++  ?utils:v(bold, integer, ?v(<<"bold">>, Attrs))
	++  ?utils:v(solo_brand, integer, ?v(<<"solo_brand">>, Attrs))
	++  ?utils:v(solo_color, integer, ?v(<<"solo_color">>, Attrs))
	++  ?utils:v(solo_size, integer, ?v(<<"solo_size">>, Attrs))

	++  ?utils:v(hpx_each, integer, ?v(<<"hpx_each">>, Attrs))
	++  ?utils:v(hpx_executive, integer, ?v(<<"hpx_executive">>, Attrs))
	++  ?utils:v(hpx_category, integer, ?v(<<"hpx_category">>, Attrs))
	++  ?utils:v(hpx_fabric, integer, ?v(<<"hpx_fabric">>, Attrs))
	++  ?utils:v(hpx_price, integer, ?v(<<"hpx_price">>, Attrs))
	++  ?utils:v(hpx_barcode, integer, ?v(<<"hpx_barcode">>, Attrs))

	++  ?utils:v(hpx_top, integer, ?v(<<"hpx_top">>, Attrs))
	++  ?utils:v(hpx_left, integer, ?v(<<"hpx_left">>, Attrs))
	++  ?utils:v(second_space, integer, ?v(<<"second_space">>, Attrs)),

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
    [{"pum",             "打印份数",            "1",  "0"},
     {"ptype",           "打印方式",            "1",  "0"}, %% 0: front; 1:backend
     {"pim_print",       "立即打印",            "0",  "0"},

     {"reject_negative", "零库存退货",           "0",  "0"},
     {"check_sale",      "检测库存销售",         "1",  "0"}, 

     {"h_stock_edit",    "采购编辑展示历史记录", "0",   "0"},
     {"m_sgroup",        "允许多尺码组",         "0",   "0"},
     {"t_trace",         "入库价格跟踪",         "0",   "0"},
     {"d_sex",           "默认入库性别",         "0",   "0"},
     {"d_report",        "日报表能力",           "0",   "0"},
     {"m_sale",          "允许负数退货",         "1",   "0"},
     {"round",           "四舍五入",             "1",   "0"},
     {"h_color",         "隐藏颜色",             "0",   "0"},
     {"h_size",          "隐藏尺码",             "0",   "0"},
     {"h_sex",           "隐藏性别",             "0",   "0"},
     {"s_member",        "会员独立",             "0",   "0"},
     {"s_employee",      "营业员必选",           "0",   "0"},
     
     {"prn_barcode",       "条码打印机编号",     "-1",   "0"},
     {"prn_bill",          "单据打印机编号",     "-1",   "0"},
     {"prn_h_page",        "单据纸张高",         "14.0", "0"},
     {"prn_w_page",        "单据纸张宽",         "21.3", "0"},
     
     {"draw_score",        "提现积分",           "1",    "0"}, 
     {"dual_barcode",      "双排条码",           "0",    "0"}
    ].
    
sys_config() ->
    %% one month default
    {M, S, T} = erlang:now(), 
    {{YY, MM, DD}, _} = calendar:now_to_datetime({M, S - 86400 * 30, T}),
    DefaultDate = lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [YY, MM, DD])),
    
    %%         ename,             cname,                 value,type
    Values = [{"pum",             "打印份数",            "1",  "0"},
	      {"ptype",           "打印方式",            "1",  "0"}, %% 0: front; 1:backend
	      {"pim_print",       "立即打印",            "0",  "0"},

	      {"qtime_start",     "联想开始时间",        DefaultDate,  "0"}, 
	      {"qtypeahead",      "联想方式",            "1",   "0"}, %% 0: front; 1:backend 
	      {"prompt",          "联想数目",            "8",   "0"},


	      {"stock_alarm",     "库存告警",             "0",  "0"},
	      {"reject_negative", "零库存退货",           "0",  "0"},
	      {"check_sale",      "检测库存销售",         "1",  "0"},
	      
	      {"se_pagination",   "顺序翻页",             "0",  "0"}, 
	      {"s_customer",      "非VIP客户",            "0",   "0"},

	      {"h_stock_edit",    "采购编辑展示历史记录", "0",   "0"},
	      {"m_sgroup",        "允许多尺码组",         "0",   "0"},
	      {"t_trace",         "入库价格跟踪",         "0",   "0"},
	      {"d_sex",           "默认入库性别",         "0",   "0"},
	      {"d_report",        "日报表能力",           "0",   "0"},
	      {"m_sale",          "允许负数退货",         "1",   "0"},
	      {"group_color",     "颜色分组",             "1",   "0"},
	      {"image_mode",      "图片模式",             "0",   "0"},
	      {"round",           "四舍五入",             "1",   "0"},
	      %% {"scanner",         "扫描模式",             "0",   "0"},
	      {"h_color",         "隐藏颜色",             "0",   "0"},
	      {"h_size",          "隐藏尺码",             "0",   "0"},
	      {"h_sex",           "隐藏性别",             "0",   "0"},
	      {"s_member",        "会员独立",             "0",   "0"},
	      {"s_employee",      "营业员必选",           "0",   "0"},
	      %% {"cake_mode",    "蛋糕店模式",           "0",   "0"},
	      {"p_balance",       "打印会员余额",         "0",   "0"},
	      {"gen_ticket",      "自动生成电子卷",       "0",   "0"},
	      {"recharge_sms",    "充值短信提醒",         "0",   "0"},
	      {"consume_sms",     "消费短信提醒",         "0",   "0"},
	      {"price_on_region", "按区域填写价格",       "0",   "0"},
	      {"wsale_import",    "导入淘宝销售单",       "0",   "0"},
	      {"stock_warning",   "库存预警",             "0",   "0"},
	      {"stock_warning_a", "库存预警数量",         "0",   "0"},
	      {"stock_contailer", "货品货柜号",           "0",   "0"},
	      {"stock_firm",      "入库区分厂商",         "1",   "0"},
	      {"bcode_use",       "启用条码",             "0",   "0"},
	      {"bcode_auto",      "自动条码",             "1",   "0"},
	      %% {"bcode_width",     "条码宽度",             "7",   "0"},
	      %% {"bcode_height",    "条码高度",             "2",   "0"},
	      {"trans_orgprice",  "移仓检测进价",         "1",   "0"},
	      {"p_color_size",    "打印颜色尺码",         "0",   "0"},
	      
	      %% {"birth_sms",       "生日短信",             "0",   "0"},
	      %% default send sms current day
	      %% {"birth_before",    "生日短信发送间隔",     "0",   "0"}, 
	      
	      %%  {"score_withdraw",  "提现是否积分",         "1",   "0"}
	      {"saler_stock",      "营业员查看区域库存",  "0",   "0"},
	      {"r_stock_oprice",    "厂商退货检测进价",   "1",   "0"},
	      {"c_stock_oprice",    "入库审核检测进价",   "1",   "0"},
	      {"c_stock_firm",      "入库审核检测厂商",   "1",   "0"},
	      %% {"bcode_firm",     "条码打印厂商",       "0",   "0"},
	      {"export_code",       "导出编码格式",       "0",   "0"}, %% 0: utf8 1: gbk
	      {"export_note",       "导出颜色尺码",       "0",   "0"}, %% 0: utf8 1: gbk

	      {"prn_barcode",       "条码打印机编号",     "-1",   "0"},
	      {"prn_bill",          "单据打印机编号",     "-1",   "0"},
	      {"prn_h_page",        "单据纸张高",         "14.0", "0"},
	      {"prn_w_page",        "单据纸张宽",         "21.3", "0"},
	      {"draw_score",        "提现积分",           "1",    "0"},
	      {"dual_barcode",      "双排条码",           "0",    "0"}
	      %% {"bcode_self",     "吊牌打印模式",       "0",   "0"}
	     ],
    Values.
