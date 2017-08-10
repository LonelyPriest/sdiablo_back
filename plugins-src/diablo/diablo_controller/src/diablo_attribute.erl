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
-export([type/2, type/3]).

-define(SERVER, ?MODULE).

-define(SIZE_TO_BARCODE,
	["XS",  "S",   "M",   "L",   "XL",  "2XL",  "3XL", "4XL", "5XL", "6XL", "7XL",
	 "0",   "8",   "9",   "10",  "11",  "12",  "13",   "14",  "15",  "16",  "17",
	 "18",  "19",  "20",  "21",  "22",  "23",  "24",   "25",  "26",  "27",  "28",
	 "29",  "30",  "31",   "32",  "33",  "34",  "35",  "36",  "37",  "38",  "40",
	 "42",  "44",  "46",   "48",  "50",  "52",
	 "80",  "90",  "100", "105", "110", "115",  "120", "125", "130", "135", "140",
	 "145", "150", "155", "160", "165", "170",  "175", "180", "185", "190", "195",
	 "200"]).

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
    gen_server:call(?MODULE, {update_brand, Merchant, Attrs}).
brand(list, Merchant) ->
    gen_server:call(?MODULE, {list_brand, Merchant}).

type(new, Merchant, Type)->
    gen_server:call(?MODULE, {new_type, Merchant, Type}).
type(list, Merchant) ->
    gen_server:call(?MODULE, {list_type, Merchant}).


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
    SelfBarcode = ?v(<<"self_barcode">>, Attr, 0),
    
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
    
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    NewBCode = case SelfBarcode of
			   ?NO -> ?inventory_sn:sn(color, Merchant);
			   ?YES -> BCode
		       end,
	    case NewBCode =/= 0 of
		true ->
		    Sql01 = "select id, bcode, name from colors"
			" where bcode=" ++ ?to_s(BCode) ++
			" and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql01) of
			{ok, []} ->
			    R = AddColor(NewBCode),
			    {reply, R, State};
			{ok, _Color} ->
			    {reply, {error, ?err(color_bcode_exist, BCode)}, State};
			Error ->
			    {reply, Error, State}
		    end;
		false ->
		    R = AddColor(NewBCode),
		    {reply, R, State}
	    end;
	{ok, Color} ->
	    {reply, {error, ?err(color_exist, ?v(<<"id">>, Color))}, State};
	Error ->
	    {reply, Error, State}
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
    Sql  = "update colors set deleted=" ++ ?to_s(?YES)
	++ " where=id" ++ ?to_s(ColorId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, ColorId),
    {reply, Reply, State};

handle_call({list_w_color, Merchant}, _Form, State) ->
    ?DEBUG("list colors with merchant ~p", [Merchant]),
    Sql = "select a.id, a.bcode, a.name, a.type as tid, a.remark, b.name as type"
	++ " from colors a, color_type b"
	++ " where "
	++ " a.merchant=" ++ ?to_s(Merchant)
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
    Name     = ?value(<<"name">>, Attrs),
    
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

		case invalid_size(SI)
		    orelse invalid_size(SII)
		    orelse invalid_size(SIII)
		    orelse invalid_size(SIV)
		    orelse invalid_size(SV)
		    orelse invalid_size(SVI)
		    orelse invalid_size(SVII) of
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


handle_call({new_type, Merchant, Type}, _From, State) ->
    ?DEBUG("new_type with merchant ~p, type ~p", [Merchant, Type]),
    
    Sql = "select id, name from inv_types"
	++ " where name=" ++ "\"" ++ ?to_s(Type) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant) ++ ";",

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		BCode = ?inventory_sn:sn(type, Merchant),
		Sql1 = 
		    "insert into inv_types"
		    ++"(bcode, name, merchant) values("
		    ++ ?to_s(BCode) ++ ","
		    ++ "\"" ++?to_s(Type) ++ "\","
		    ++ ?to_s(Merchant) ++ ");",
		R = ?sql_utils:execute(insert, Sql1),
		?w_user_profile:update(type, Merchant),
		R;
	    {ok, R} -> 
		{ok, ?v(<<"id">>, R)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({list_type, Merchant}, _From, State) ->
    ?DEBUG("list_type with merchant ~p", [Merchant]),
    Sql = "select id, bcode, name from inv_types"
	++ " where "
	++ " merchant = " ++ ?to_string(Merchant)
	++ " and deleted = " ++ ?to_string(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
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

invalid_size("") -> false; 
invalid_size(Size) ->
    ?DEBUG("Size ~p", [Size]),
    not lists:member(?to_s(Size), ?SIZE_TO_BARCODE).
