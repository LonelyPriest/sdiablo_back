%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 23 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_attribute).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([color_type/2, color/2, color/3, bcode/3]).
-export([size_group/2, size_group/3]).
-export([brand/2, brand/3]).
-export([type/2, type/3, type/4, invalid_size/1, invalid_size/2]).
-export([filter/4, filter/6]).
-export([syn/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
color_type(list, Merchant) ->
    gen_server:call(?MODULE, {list_w_color_type, Merchant}).

color(w_list, Merchant) ->
    gen_server:call(?MODULE, {list_w_color, Merchant}). 
color(w_new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_w_color, Merchant, Attrs});
color(w_update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_w_color, Merchant, Attrs});
color(w_delete, Merchant, ColorId) ->
    gen_server:call(?MODULE, {delete_w_color, Merchant, ColorId});
color(w_list, Merchant, ColorIds) ->
    gen_server:call(?MODULE, {list_w_color, Merchant, ColorIds}). 

size_group(list, Merchant) ->
    gen_server:call(?MODULE, {list_size_group, Merchant}).
size_group(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_size_group, Merchant, Attrs});
size_group(delete, Merchant, GId) ->
    gen_server:call(?MODULE, {delete_size_group, Merchant, GId});
size_group(update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_size_group, Merchant, Attrs}).

brand(new, Merchant, Attrs) ->
    gen_server:call(?MODULE, {new_brand, Merchant, Attrs});
brand(update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_brand, Merchant, Attrs});
brand(like, Merchant, Like) ->
    gen_server:call(?MODULE, {like_brand, Merchant, Like});
brand(delete, {Merchant, UTable}, BrandId) ->
    gen_server:call(?MODULE, {delete_brand, Merchant, UTable, BrandId }).
brand(list, Merchant) ->
    gen_server:call(?MODULE, {list_brand, Merchant}).

type(new, Merchant, Attrs)->
    gen_server:call(?MODULE, {new_type, Merchant, Attrs}); 
type(get, Merchant, Condition) ->
    gen_server:call(?MODULE, {get_type, Merchant, Condition});
type(update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_type, Merchant, Attrs}).
type(like_match, Merchant, LikePrompt, Ascii) ->
    gen_server:call(?MODULE, {type_like_match, Merchant, LikePrompt, Ascii}); 
type(list, Merchant, LikePrompt, Ascii) ->
    gen_server:call(?MODULE, {list_type, Merchant, LikePrompt, Ascii});
type(delete, Merchant, TypeId, Mode) ->
    gen_server:call(?MODULE, {delete_type, Merchant, TypeId, Mode}).
type(list, Merchant) ->
    type(list, Merchant, [], ?YES).

%% filter
filter(total_types, 'and', Merchant, Fields) ->
    gen_server:call(?MODULE, {total_types, Merchant, Fields}).
filter(types, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    gen_server:call(?MODULE, {filter_types, Merchant, CurrentPage, ItemsPerPage, Fields}).

syn(type_py, Merchant, Types) ->
    gen_server:call(?MODULE, {syn_type_py, Merchant, Types}).


bcode(update, firm, Merchant) ->
    gen_server:call(?MODULE, {bcode_update, firm, Merchant});
bcode(update, brand, Merchant) ->
    gen_server:call(?MODULE, {bcode_update, brand, Merchant});
bcode(update, type, Merchant) ->
    gen_server:call(?MODULE, {bcode_update, type, Merchant});
bcode(update, color, Merchant) ->
    gen_server:call(?MODULE, {bcode_update, color, Merchant}).



start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================


init([]) ->
    {ok, #state{}}.

handle_call({list_w_color_type, Merchant}, _Form, State) ->
    ?DEBUG("list_w_color_type", []),
    Sql = "select id, name from color_type"
	++ " where " ++ ?utils:to_sqls(proplists, {<<"merchant">>, [0, Merchant]})
	%% ++ " where deleted=" ++ ?to_string(?NO)
	++ " order by id",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_w_color, Merchant, Attr}, _From, State) ->
    ?DEBUG("new color with merchant ~p, attr ~p ", [Merchant, Attr]),
    Name     = ?v(<<"name">>, Attr),
    Type     = ?v(<<"type">>, Attr),
    BCode    = ?v(<<"bcode">>, Attr, 0),
    Remark   = ?v(<<"remark">>, Attr, []),
    AutoBarcode = ?v(<<"auto_barcode">>, Attr, ?YES),
    
    Sql0 = "select id, name from colors"
	" where name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	" and merchant=" ++ ?to_s(Merchant),

    AddColor =
	fun(NewBCode) ->
		Sql1 = "insert into colors(bcode, name, type, remark, merchant)"
		    " values("
		    ++ ?to_s(NewBCode) ++ ","
		    ++ "\"" ++ ?to_s(Name) ++ "\","
		    ++ ?to_s(Type) ++ ","
		    ++ "\"" ++ ?to_s(Remark) ++ "\","
		    ++ ?to_s(Merchant) ++ ");",
		?sql_utils:execute(insert, Sql1)
	end,

    Sql1 = "select count(*) as total from colors where merchant="  ++ ?to_s(Merchant),
    case ?sql_utils:execute(s_read, Sql1) of 
	{ok, R} ->
	    Total = ?v(<<"total">>, R),
	    case Total > 999 of
		true ->
		    {reply, {error, ?err(color_max_999, Total)}, State};
		false -> 
		    case ?sql_utils:execute(s_read, Sql0) of
			{ok, []} ->
			    NewBCode = case AutoBarcode of
					   ?YES -> ?inventory_sn:sn(color, Merchant);
					   ?NO -> BCode
				       end,
			    case NewBCode =/= 0 of
				true ->
				    Sql01 = "select id, bcode, name from colors"
					" where bcode=" ++ ?to_s(NewBCode) ++
					" and merchant=" ++ ?to_s(Merchant),
				    case ?sql_utils:execute(s_read, Sql01) of
					{ok, []} ->
					    {reply, AddColor(NewBCode), State};
					{ok, _Color} ->
					    {reply, {error, ?err(color_bcode_exist, BCode)}, State};
					Error0 ->
					    {reply, Error0, State}
				    end;
				false ->
				    {reply, AddColor(NewBCode), State}
			    end;
			{ok, Color} ->
			    {reply, {error, ?err(color_exist, ?v(<<"id">>, Color))}, State};
			Error1 ->
			    {reply, Error1, State}
		    end
	    end;
	Error2 ->
	    {reply, Error2, State}
    end; 

handle_call({update_w_color, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_w_color with Merchant ~p, attrs ~p", [Merchant, Attrs]),
    ColorId  = ?v(<<"cid">>, Attrs),
    BCode    = ?v(<<"bcode">>, Attrs),
    Name     = ?v(<<"name">>, Attrs),
    Type     = ?v(<<"type">>, Attrs),
    Remark   = ?v(<<"remark">>, Attrs),

    case 
	case BCode of
	    undefined -> ok;
	    0 -> ok;
	    _ ->
		Sql01 = "select id, bcode, name from colors"
		    " where bcode=" ++ ?to_s(BCode) ++
		    " and merchant=" ++ ?to_s(Merchant),
		case ?sql_utils:execute(s_read, Sql01) of
		    {ok, []} ->
			ok; 
		    {ok, _Color} ->
			{error, ?err(color_bcode_exist, BCode)};
		    Error ->
			Error
		end
	end
    of
	ok -> 
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(bcode, integer, BCode)
		++ ?utils:v(type, integer, Type)
		++ ?utils:v(Remark, string, Remark), 
	    ?DEBUG("updates ~p", [Updates]),

	    Sql  = "update colors set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ " and id=" ++ ?to_s(ColorId), 
	    Reply = ?sql_utils:execute(write, Sql, ColorId),
	    {reply, Reply, State};
	Error1 ->
	    {reply, Error1, State}
    end;

handle_call({delete_w_color, Merchant, ColorId}, _From, State) ->
    ?DEBUG("delete_w_color with merchant ~p, colorId ~p", [Merchant, ColorId]), 
    %% Sql  = "update colors set deleted=" ++ ?to_s(?YES)
    %% 	++ " where id=" ++ ?to_s(ColorId)
    %% 	++ " and merchant=" ++ ?to_s(Merchant),

    Sql = "delete from colors" 
	++ " where id=" ++ ?to_s(ColorId)
	++ " and merchant=" ++ ?to_s(Merchant),
    Reply = ?sql_utils:execute(write, Sql, ColorId),
    {reply, Reply, State};

handle_call({list_w_color, Merchant}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p", [Merchant]),
    Sql = "select a.id, a.bcode, a.name, a.type as tid, a.remark, b.name as type"
	++ " from colors a, color_type b"
	++ " where "
	++ " a.merchant=" ++ ?to_s(Merchant)
	++ " and a.deleted!=1"
	++ " and a.type=b.id order by a.id",

    Reply = ?sql_utils:execute(read, Sql),
    %% ?DEBUG("reply ~p", [Reply]),
    {reply, Reply, State};

handle_call({list_w_color, Merchant, ColorIds}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p, colorIds ~p", [Merchant, ColorIds]), 
    Sql = "select id, bcode, name from colors"
	" where " ++ ?utils:to_sqls(proplists, [{<<"id">>, ColorIds}])
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id", 
    Reply = ?sql_utils:execute(read, Sql),
    ?DEBUG("reply ~p", [Reply]),
    {reply, Reply, State};


handle_call({new_size_group, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_size_group with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    Mode     = ?v(<<"mode">>, Attrs, ?CLOTHES_MODE),
    ?DEBUG("Mode ~p", [Mode]),
    
    Sql0 = "select id, name from size_group"
	" where name=\"" ++ ?to_s(Name) ++ "\""
	" and merchant=" ++ ?to_s(Merchant),
    
    Reply = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		Name = ?v(<<"name">>, Attrs),
		SI   = ?v(<<"si">>, Attrs, ""),
		SII  = ?v(<<"sii">>, Attrs, ""),
		SIII = ?v(<<"siii">>, Attrs, ""),
		SIV  = ?v(<<"siv">>, Attrs, ""),
		SV   = ?v(<<"sv">>, Attrs, ""),
		SVI  = ?v(<<"svi">>, Attrs, ""),
		SVII = ?v(<<"svii">>, Attrs, ""),

		case invalid_size(SI, Mode)
		    orelse invalid_size(SII, Mode)
		    orelse invalid_size(SIII, Mode)
		    orelse invalid_size(SIV, Mode)
		    orelse invalid_size(SV, Mode)
		    orelse invalid_size(SVI, Mode)
		    orelse invalid_size(SVII, Mode) of
		    true ->
			{error, ?err(size_group_invalid_name, Name)};
		    false -> 
			Sql1 = "insert into size_group("
			    "name, si, sii, siii, siv, sv, svi, svii, merchant)"
			    " values("
			    "\'" ++ ?to_s(Name) ++ "\',"
			    "\'" ++ ?to_s(SI) ++ "\',"
			    "\'" ++ ?to_s(SII) ++ "\',"
			    "\'" ++ ?to_s(SIII) ++ "\',"
			    "\'" ++ ?to_s(SIV) ++ "\',"
			    "\'" ++ ?to_s(SV) ++ "\',"
			    "\'" ++ ?to_s(SVI) ++ "\',"
			    "\'" ++ ?to_s(SVII) ++ "\',"
			    ++ ?to_s(Merchant) ++ ")",
			?sql_utils:execute(insert, Sql1)
		%% Result = ?sql_utils:execute(insert, Sql1),
		%% ?w_user_profile:update(size_group, Merchant),
		%% Result
		end;
	    {ok, Group} ->
		{error, ?err(size_group_exist, ?v(<<"id">>, Group))};
	    Error ->
		Error
	end,

    {reply, Reply, State};

handle_call({delete_size_group, Merchant, GId}, _From, State) ->
    ?DEBUG("delete_size_group with merchant ~p, GId ~p", [Merchant, GId]), 
    Sql  = "update size_group set deleted=" ++ ?to_s(?YES)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(GId) ++ ";", 
    Reply = ?sql_utils:execute(write, Sql, GId),
    {reply, Reply, State};

handle_call({update_size_group, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_size_group with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Gid      = ?v(<<"gid">>, Attrs),
    SI       = ?v(<<"si">>, Attrs),
    SII      = ?v(<<"sii">>, Attrs),
    SIII     = ?v(<<"siii">>, Attrs),
    SIV      = ?v(<<"siv">>, Attrs),
    SV       = ?v(<<"sv">>, Attrs),
    SVI      = ?v(<<"svi">>, Attrs),
    SVII     = ?v(<<"sviI">>, Attrs),

    Updates = ?utils:v(si, string, SI)
	++ ?utils:v(sii, string, SII)
	++ ?utils:v(siii, string, SIII)
	++ ?utils:v(siv, string, SIV)
	++ ?utils:v(sv, string, SV)
	++ ?utils:v(svi, string, SVI)
	++ ?utils:v(svii, string, SVII),
    
    %% ?DEBUG("updates ~p", [Updates]),

    Sql  = "update size_group set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(Gid)
	++ "and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, Gid),
    {reply, Reply, State};

handle_call({list_size_group, Merchant}, _From, State) ->
    ?DEBUG("lookup size group with merchant ~p", [Merchant]),
    Sql = "select id, name, si, sii, siii, siv, sv, svi, svii"
	++ " from size_group"
	++ " where merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO)
	++ " order by id",

    Reply = ?sql_utils:execute(read, Sql), 
    {reply, Reply, State};


%% =============================================================================
%% brand
%% =============================================================================
handle_call({new_brand, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_brand with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name   = ?v(<<"name">>, Attrs),
    Firm   = ?v(<<"firm">>, Attrs, -1),
    Remark = ?v(<<"remark">>, Attrs, []),
    
    
    Sql = "select id, name, supplier from brands"
	++ " where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
	%% ++ " and supplier=" ++ ?to_s(Firm)
	++ " and merchant =" ++ ?to_s(Merchant) ++ ";",

    Reply =
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		BCode = ?inventory_sn:sn(brand, Merchant),
		Sql1 = 
		    "insert into brands"
		    ++"(bcode, name, supplier, merchant, remark, entry) values("
		    ++ ?to_s(BCode) ++ ","
		    ++ "\'" ++?to_s(Name) ++ "\',"
		    ++ ?to_s(Firm) ++ ","
		    ++ ?to_s(Merchant) ++ ","
		    ++ "\'" ++?to_s(Remark) ++ "\',"
		    ++ "\'" ++ ?utils:current_time(localtime) ++ "\')",
		
		R = ?sql_utils:execute(insert, Sql1),
		?w_user_profile:update(brand, Merchant),
		R;
	    {ok, R} -> 
		%% {error, ?err(brand_exist, ?v(<<"id">>, R))};
		{ok, ?v(<<"id">>, R)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({update_brand, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_brand with merchant ~p, attrs ~p", [Merchant, Attrs]),
    BrandId = ?v(<<"bid">>, Attrs),
    Name    = ?v(<<"name">>, Attrs),
    Firm    = ?v(<<"firm">>, Attrs),
    Remark  = ?v(<<"remark">>, Attrs, []),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(supplier, integer, Firm)
	++ ?utils:v(remark, string, Remark),

    Sql = "update brands set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(BrandId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, BrandId),
    ?w_user_profile:update(brand, Merchant),
    {reply, Reply, State};


handle_call({delete_brand, Merchant, UTable, BrandId}, _From, State) ->
    Sql0 = "select style_number, brand"
    %% " from w_inventory_good"
	" from" ++ ?table:t(good, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and brand=" ++ ?to_s(BrandId),

    case ?sql_utils:execute(read, Sql0) of
	{ok, []} -> 
	    Sql = "delete from brands"
		++ " where id=" ++ ?to_s(BrandId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql, BrandId),
	    ?w_user_profile:update(brand, Merchant),
	    {reply, Reply, State};
	{ok, _R} ->
	    {reply, {error, ?err(brand_used, BrandId)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_brand, Merchant}, _From, State) ->
    ?DEBUG("list_brand with merchant ~p", [Merchant]),
    Sql = "select a.id, a.bcode, a.name, a.supplier as supplier_id"
	", a.remark, a.entry"
	", b.name as supplier"
	++ " from brands a"
	++ " left join suppliers b on a.supplier=b.id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and a.deleted = " ++ ?to_string(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({like_brand, Merchant, Like}, _From, State) ->
    ?DEBUG("like_brand with merchant ~p, Like ~p", [Merchant, Like]),
    Sql = "select id, name from brands a" ++ " where a.merchant=" ++ ?to_s(Merchant)
	++ " and name like '%" ++ ?to_s(Like) ++ "%'"
	++ " and deleted = " ++ ?to_string(?NO),
	Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({new_type, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_type with merchant ~p, attrs ~p", [Merchant, Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    PY       = ?v(<<"py">>, Attrs, []),
    BCode    = ?v(<<"bcode">>, Attrs, 0),
    CType    = ?v(<<"ctype">>, Attrs, -1),
    AutoBarcode = ?v(<<"auto_barcode">>, Attrs, ?YES),
    
    Sql = "select id, name from inv_types"
	++ " where name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant) ++ ";",

    AddType =
	fun(NewBarcode) ->
		Sql1 = 
		    "insert into inv_types"
		    ++"(bcode, name, py, ctype, merchant) values("
		    ++ ?to_s(NewBarcode) ++ ","
		    ++ "\"" ++?to_s(Name) ++ "\","
		    ++ "\"" ++?to_s(PY) ++ "\","
		    ++ ?to_s(CType) ++ ","
		    ++ ?to_s(Merchant) ++ ");",
		case ?sql_utils:execute(insert, Sql1) of
		    {ok, _} = R ->
			%% ?w_user_profile:update(type, Merchant),
			R;
		    R -> R
		end 
	end,

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    NewBCode = case AutoBarcode of
			   ?YES -> ?inventory_sn:sn(type, Merchant);
			   ?NO -> BCode
		       end,
	    case NewBCode =/= 0 of
		true ->
		    Sql01 = "select id, bcode, name from inv_types"
			" where bcode=" ++ ?to_s(NewBCode) ++
			" and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql01) of
			{ok, []} ->
			    R = AddType(NewBCode), 
			    {reply, R, State};
			{ok, _Type} ->
			    {reply, {error, ?err(type_bcode_exist, BCode)}, State};
			Error ->
			    {reply, Error, State}
		    end;
		false ->
		    R = AddType(NewBCode),
		    {reply, R, State}
	    end; 
	{ok, _Type} -> 
	    {reply, {ok_exist, ?v(<<"id">>, _Type)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_type, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_type with Merchant ~p, attrs ~p", [Merchant, Attrs]),
    TypeId   = ?v(<<"tid">>, Attrs),
    BCode    = ?v(<<"bcode">>, Attrs),
    Name     = ?v(<<"name">>, Attrs),
    CId     = ?v(<<"cid">>, Attrs), 

    case 
	case BCode of
	    undefined -> ok;
	    0 -> ok;
	    ?INVALID_OR_EMPTY -> ok;
	    _ ->
		Sql01 = "select id, bcode, name from inv_types"
		    " where bcode=" ++ ?to_s(BCode) ++
		    " and merchant=" ++ ?to_s(Merchant),
		case ?sql_utils:execute(s_read, Sql01) of
		    {ok, []} ->
			ok; 
		    {ok, _Type} ->
			{error, ?err(type_bcode_exist, BCode)};
		    Error ->
			Error
		end
	end
    of
	ok -> 
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(bcode, integer, BCode)
		++ ?utils:v(ctype, integer, CId),
	    ?DEBUG("updates ~p", [Updates]),
	    Sql  = "update inv_types set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ " and id=" ++ ?to_s(TypeId),
	    
	    case Name of
		undefined ->
		    {reply, ?sql_utils:execute(write, Sql, TypeId), State};
		_ ->
		    Sql02 = "select id, name from inv_types"
			" where name=\'" ++ ?to_s(Name) ++ "\'"
			" and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql02) of
			{ok, []} ->
			    {reply, ?sql_utils:execute(write, Sql, TypeId), State};
			{ok, _} ->
			    {reply, {error, ?err(good_type_exist, Name)}, State};
			_Error ->
			    {reply, _Error, State}
		    end
	    end; 
	Error1 ->
	    {reply, Error1, State}
    end;

handle_call({delete_type, Merchant, TypeId, Mode}, _From, State) ->
    ?DEBUG("delete_type: merchant ~p, TypeId ~p", [Merchant, TypeId]),
    Sql = "update inv_types set deleted="
	++ case Mode of
	       ?DELETE -> ?to_s(?YES);
	       ?RECOVER -> ?to_s(?NO)
	   end
	++ " where "
	++ " merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, [{<<"id">>, TypeId}]),
    Reply = ?sql_utils:execute(write, Sql, TypeId),
    {reply, Reply, State};


handle_call({get_type, Merchant, Condition}, _From, State) ->
    ?DEBUG("get_type: merchant ~p, Condition ~p", [Merchant, Condition]),
    Sql = "select id, bcode, name, py, ctype as cid from inv_types"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ ?sql_utils:condition(proplists, Condition)
	++ " and deleted = " ++ ?to_string(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_type, Merchant, LikePrompt, Ascii}, _From, State) ->
    ?DEBUG("list_type with merchant ~p, LikePrompt ~p, ascii ~p",
	   [Merchant, LikePrompt, Ascii]),
    Sql = "select id"
	", bcode"
	", name"
	", py"
	", deleted"
	", ctype as cid from inv_types"
	++ " where "
	++ " merchant=" ++ ?to_s(Merchant)
	++ case LikePrompt of
	       [] -> [];
	       _ ->
		   case Ascii of
		       ?YES -> " and py like \'%" ++ ?to_s(LikePrompt) ++ "%\'";
		       ?NO -> " and name like \'%" ++ ?to_s(LikePrompt) ++ "%\'"
		   end
	   end
    %% ++ " and deleted = " ++ ?to_s(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({type_like_match, Merchant, LikePrompt, Ascii}, _From, State) ->
    ?DEBUG("match_type with merchant ~p, LikePrompt ~p, ascii ~p", [Merchant, LikePrompt, Ascii]),
    Sql = "select id"
	", name"
	", py"
	", ctype as cid from inv_types"
	" where"
	" merchant=" ++ ?to_s(Merchant)
	++ case LikePrompt of
	       [] -> [];
	       _ ->
		   case Ascii of
		       ?YES -> " and py like \'%" ++ ?to_s(LikePrompt) ++ "%\'";
		       ?NO -> " and name like \'%" ++ ?to_s(LikePrompt) ++ "%\'"
		   end
	   end
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc limit 20",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({syn_type_py, Merchant, Types}, _From, State) ->
    ?DEBUG("syn_type_py: merchant ~p", [Merchant]),
    Sqls = 
	lists:foldr(
	  fun({struct, R}, Acc)->
		  Id     = ?v(<<"id">>, R),
		  Pinyin = ?v(<<"py">>, R, []),
		  ["update inv_types set py=\'" ++ ?to_s(Pinyin) ++ "\'"
		   " where merchant=" ++ ?to_s(Merchant)
		   ++ " and id=" ++ ?to_s(Id)|Acc]
	  end, [], Types),

    ?DEBUG("Sqls ~p", [Sqls]),
    Reply = ?sql_utils:execute(transaction, Sqls, Merchant),
    {reply, Reply, State};

handle_call({bcode_update, Table, Merchant}, _From, State) ->
    Sql = "select id, bcode from "
	++ case Table of
	       firm -> "suppliers";
	       brand -> "brands";
	       type -> "inv_types";
	       color -> "colors"
	   end
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " order by id",

    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    {reply, ok, State};
	{ok, Records} ->
	    Sqls = 
		lists:foldl(
		  fun({R}, Acc) ->
			  case ?v(<<"bcode">>, R) /= 0 of
			      true -> Acc;
			      false ->
				  BCode = ?inventory_sn:sn(?to_a(Table), Merchant),
				  ["update " ++ case Table of
						    firm -> "suppliers";
						    brand-> "brands";
						    type -> "inv_types";
						    color -> "colors"
						end
				   ++ " set bcode=" ++ ?to_s(BCode)
				   ++ " where id=" ++ ?to_s(?v(<<"id">>, R))]
				      ++ Acc
			  end
		  end, [], Records),
	    Reply = ?sql_utils:execute(transaction, Sqls, Table),
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

%% filter
handle_call({total_types, Merchant, Fields}, _From, State) ->
    Sql = ?sql_utils:count_table(inv_types, Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_types, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_good_type: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = "select id"
	", name"
	", bcode"
	", ctype as ctype_id"
	", py"
	", deleted"
	" from inv_types"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Fields)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    {reply, ok, State}.


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
invalid_size(Size) ->
    invalid_size(Size, ?CLOTHES_MODE).

invalid_size("", _Mode) -> false;
invalid_size(Size, ?CLOTHES_MODE) ->
    not lists:member(?to_s(Size), ?SIZE_TO_BARCODE);
invalid_size(Size, _Mode) ->
    not lists:member(?to_s(Size), ?SIZE_TO_BARCODE).

