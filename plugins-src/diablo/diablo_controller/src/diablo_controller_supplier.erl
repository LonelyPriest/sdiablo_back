%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_supplier).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([supplier/2, supplier/3, filter/4, filter/6, bill/3]).

-define(SERVER, ?MODULE). 
-define(tbl_supplier, "suppliers").


-record(state, {}).

%%%===================================================================
%%% API
%%%=================================================================== 
supplier(w_new, Attrs) ->
    gen_server:call(?MODULE, {w_new_supplier, Attrs});
supplier(w_list, Merchant) ->
    gen_server:call(?MODULE, {w_list, Merchant}). 
supplier(w_delete, Merchant, Id) ->
    gen_server:call(?MODULE, {w_delete_supplier, Merchant, Id});
supplier(w_update, Merchant, Attrs) ->
    gen_server:call(?MODULE, {w_update_supplier, Merchant, Attrs});
supplier(bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {bill_supplier, Merchant, Attrs});
supplier(update_bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {update_bill_supplier, Merchant, Attrs});
supplier(check_bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {check_bill_supplier, Merchant, Attrs});
supplier(abandon_bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {abandon_bill_supplier, Merchant, Attrs}).

filter(total_bill, 'and', Merchant, Conditions) ->
    gen_server:call(?MODULE, {total_bill, Merchant, Conditions}).
filter(bill, 'and', Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?MODULE, {bill_detail,
			      Merchant, CurrentPage, ItemsPerPage, Conditions}).

bill(lookup, Merchant, Conditions) ->
    gen_server:call(?MODULE, {bill_lookup, Merchant, Conditions}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({w_new_supplier, Attrs}, _From, State)->
    ?DEBUG("w_new supplier with Attrs ~p", [Attrs]),
    Name     = ?v(<<"name">>, Attrs),
    %% Pinyin   = ?v(<<"pinyin">>, Attrs),
    Balance  = ?v(<<"balance">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs),
    Merchant = ?v(<<"merchant">>, Attrs),
    
    %% name can not be same
    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into " ++ ?tbl_supplier
		++ "(name, balance, mobile, address, merchant, change_date, entry_date)"
		++ " values ("
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Balance) ++ ","
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",

	    %% ?DEBUG("sql to supplier ~tp", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(insert, Sql1),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(supplier_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({w_update_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("w_update_supplier with merhcant ~p, attrs ~p", [Merchant, Attrs]),
    FirmId   = ?v(<<"firm_id">>, Attrs),
    Name     = ?v(<<"name">>, Attrs), 
    Balance  = ?v(<<"balance">>, Attrs), 
    Mobile   = ?v(<<"mobile">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),

    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    %% ++ " and mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\";",
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(balance, float, Balance)
		++ ?utils:v(mobile,  string, Mobile)
		++ ?utils:v(address, string, Address),
	    Sql1 = 
		"update " ++ ?tbl_supplier ++ " set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(FirmId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, FirmId),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {error, ?err(supplier_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({w_delete_supplier, Merchant, Id}, _From, State) ->
    ?DEBUG("w_delete_supplier with merchant ~p, Id ~p", [Merchant, Id]),
    Sql = "delete from " ++ ?tbl_supplier
	++ " where id=" ++ ?to_s(Id)
	++ " and merchant=" ++ ?to_s(Merchant), 
    Reply = ?sql_utils:execute(write, Sql, Id),
    ?w_user_profile:update(firm, Merchant),
    {reply, Reply, State}; 

handle_call({update_supplier, Condition, Fields}, _From, State) ->
    ?DEBUG("Update supplier with condtion: condition ~p, fields ~p", [Condition, Fields]),
    C = ?utils:to_sqls(proplists, Condition),
    ?DEBUG("C ~p", [C]),

    Values = ?utils:to_sqls(proplists, Fields),
    ?DEBUG("U ~p", [Values]),
    
    Sql = "update " ++ ?tbl_supplier ++ " set " ++ Values ++ " where " ++ C ++ ";",    
    ?DEBUG("sql ~p", [Sql]),
    {ok, _} = ?mysql:fetch(write, Sql),
    {reply, ok, State};

handle_call({w_list, Merchant}, _From, State) ->
    ?DEBUG("w_list with merchant ~p", [Merchant]),
    Sql = "select id, name, mobile, address, balance, entry_date from suppliers"
	++ " where "
	++ " merchant=" ++ ?to_s(Merchant)
	++ " and deleted = " ++ ?to_s(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% brand
handle_call({new_brand, Attrs}, _From, State)->
    ?DEBUG("new brand with Attrs ~p", [Attrs]),
    Name     = ?value(<<"name">>, Attrs),
    Supplier = ?value(<<"supplier">>, Attrs),
    Merchant = ?value(<<"merchant">>, Attrs),

    %% name can not be same
    Sql = "select id, name, supplier, merchant"
	++ " from brands"
	++ " where "
	++ " name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and supplier = " ++ ?to_string(Supplier)
	++ " and merchant = " ++ ?to_string(Merchant)
	++ " and deleted = "  ++ ?to_string(?NO) ++ ";",
	
    case ?mysql:fetch(read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into brands"
		++ "(name, supplier, merchant)"
		++ " values ("
		++ "\"" ++ ?to_string(Name) ++ "\","
		++ ?to_string(Supplier) ++ ","
		++ ?to_string(Merchant) ++ ");",

	    ?DEBUG("sql to brands ~ts", [?to_binary(Sql1)]),
	    {ok, _} = ?mysql:fetch(write, Sql1),
	    {reply, {ok, Name}, State};
	{ok, _Any} ->
	    ?DEBUG("brands of merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(brand_exist, Name)}, State}
    end;


handle_call({connect_brand, Attrs}, _From, State)->
    ?DEBUG("connect brand with Attrs ~p", [Attrs]),
    Brand    = ?value(<<"brand">>, Attrs),
    Supplier = ?value(<<"supplier">>, Attrs),
    Merchant = ?value(<<"merchant">>, Attrs),
    
    Sql1 = "update brands set"
	++ " supplier=" ++ ?to_string(Supplier)
	++ " where id=" ++ ?to_string(Brand)
	++ " and merchant=" ++ ?to_string(Merchant)
	++ ";",
	
    ?DEBUG("sql to connect_brands ~ts", [?to_binary(Sql1)]),
    {ok, _} = ?mysql:fetch(write, Sql1),
    {reply, {ok, Brand}, State};


handle_call({lookup_unconnect_brand, Condition}, _From, State) ->
    ?DEBUG("lookup brand with condition ~p", [Condition]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Condition),
    C = ?utils:to_sqls(proplists, CorrectCondition),
    Sql = "select a.id, a.name"
	++ " from brands a"
	++ " where " ++ C
	++ " and supplier = -1"
	++ " and a.deleted = " ++ ?to_string(?NO) ++ ";",
    {ok, Suppliers} = ?mysql:fetch(read, Sql),
    {reply, ?to_tuplelist(Suppliers), State};

handle_call({bill_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("bill_supplier with merchant ~p, attrs ~p", [Merchant, Attrs]), 
    ShopId   = ?v(<<"shop">>, Attrs),
    FirmId   = ?v(<<"firm">>, Attrs),
    Mode     = ?v(<<"mode">>, Attrs),
    Bill     = ?v(<<"bill">>, Attrs),
    Veri     = ?v(<<"veri">>, Attrs, 0),
    BankCard = case Mode of
		     ?CASH -> -1;
		     _     -> ?v(<<"card">>, Attrs)
		 end,
    Employee = ?v(<<"employee">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),

    CurrentDatetime = ?utils:current_time(format_localtime),
    Datetime = ?v(<<"datetime">>, Attrs, CurrentDatetime),

    Sql0 = "select id, merchant, balance from suppliers"
	" where id=" ++ ?to_s(FirmId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Firm} ->
	    RSN = lists:concat(
		    ["M-", ?to_i(Merchant),
		     "-S-", ?to_i(ShopId), "-C-",
		     ?inventory_sn:sn(w_firm_bill, Merchant)]), 
	    CurrentBalance = ?v(<<"balance">>, Firm, 0),

	    Sql1 = "insert into w_bill_detail("
		"rsn, shop, firm, mode, balance, bill, veri, card, employee"
		", comment, merchant, entry_date) values("
		++ "\'" ++ ?to_s(RSN) ++ "\',"
		++ ?to_s(ShopId) ++ ","
		++ ?to_s(FirmId) ++ ","
		++ ?to_s(Mode) ++ ","
		++ ?to_s(CurrentBalance) ++ ","
		++ ?to_s(Bill) ++ ","
		++ ?to_s(Veri) ++ ","
		++ ?to_s(BankCard) ++ ","
		++ "\'" ++ ?to_s(Employee) ++ "\',"
		++ "\'" ++ ?to_s(Comment) ++ "\',"
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Datetime) ++ "\')",

	    {Cash, Card, Wire} = bill_mode(Mode, Bill),
	    
	    Sql2 = "insert into w_inventory_new(rsn"
		", employ, firm, shop, merchant, balance"
		", has_pay, cash, card, wire, verificate"
		", comment, type, entry_date) values("
		++ "\"" ++ ?to_s(RSN) ++ "\","
		++ "\"" ++ ?to_s(Employee) ++ "\","
		++ ?to_s(FirmId) ++ ","
		++ ?to_s(ShopId) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ ?to_s(CurrentBalance) ++ ","
		++ ?to_s(Bill) ++ ","
		++ ?to_s(Cash) ++ ","
		++ ?to_s(Card) ++ ","
		++ ?to_s(Wire) ++ ","
		++ ?to_s(Veri) ++ ","
		++ "\"" ++ ?to_s(Comment) ++ "\"," 
		++ ?to_s(?FIRM_BILL) ++ ","
		++ "\"" ++ ?to_s(Datetime) ++ "\");",

	    Sql3 = "update suppliers set "
		"balance=balance-" ++ ?to_s(Bill + Veri)
		++ ", change_date=" ++ "\"" ++ ?to_s(Datetime) ++ "\""
		++ " where id=" ++ ?to_s(FirmId),

	    Reply = ?sql_utils:execute(transaction, [Sql1, Sql2, Sql3], FirmId),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	Error ->
    	    {reply, Error, State}
    end;

handle_call({update_bill_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("update_bill_supplier with merchant ~p, attrs ~p", [Merchant, Attrs]),
    BillId   = ?v(<<"bill_id">>, Attrs),
    StockId  = ?v(<<"stock_id">>, Attrs),
    FirmId   = ?v(<<"firm">>, Attrs),
    RSN      = ?v(<<"rsn">>, Attrs),
    Shop     = ?v(<<"shop">>, Attrs),
    Mode     = ?v(<<"mode">>, Attrs),
    Bill     = ?v(<<"bill">>, Attrs),
    Veri     = ?v(<<"veri">>, Attrs),
    OVeri    = ?v(<<"o_veri">>, Attrs),
    OBill    = ?v(<<"o_bill">>, Attrs),
    BankCard = case Mode of
		   ?CASH -> -1;
		   _     -> ?v(<<"card">>, Attrs)
	       end,
    Employee = ?v(<<"employee">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),
    Datetime = ?v(<<"datetime">>, Attrs),

    {Cash, Card, Wire} = bill_mode(Mode, Bill),
    Updates
	= ?utils:v(shop, integer, Shop)
	%% ++ ?utils:v(mode, integer, Mode)
	%% ++ ?utils:v(bill, integer, Bill)
	%% ++ ?utils:v(card, integer, BankCard)
	++ ?utils:v(employee, string, Employee)
	%% ++ ?utils:v(cash, float, Cash)
	%% ++ ?utils:v(card, float, Card)
	%% ++ ?utils:v(wire, float, Wire)
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(entry_date, string, Datetime), 

    
    Sql1 = ["update w_bill_detail set "
	     ++ ?utils:to_sqls(
		   proplists,
		   comma,
		   Updates ++ ?utils:v(mode, integer, Mode)
		   ++ case Bill == OBill of
			  true  -> [];
			  false -> ?utils:v(bill, integer, Bill)
		      end
		   ++ case Veri == OVeri of
		       true  -> [];
		       false -> ?utils:v(veri, integer, Veri)
		   end
		   ++ ?utils:v(card, integer, BankCard))
	     ++ " where merchant=" ++ ?to_s(Merchant)
	     ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"],

    UpdatesOfStock =
	Updates
	++ case Bill == OBill of
	       true  -> [];
	       false ->
		   ?utils:v(cash, float, Cash)
		       ++ ?utils:v(card, float, Card)
		       ++ ?utils:v(wire, float, Wire)
		       ++ ?utils:v(has_pay, float, Bill)
	   end
	++ case Veri == OVeri of
	       true  -> [];
	       false -> ?utils:v(verificate, integer, Veri)
	   end,
    
    Sql11 = case UpdatesOfStock of
		[] -> [];
		_  ->
		    ["update w_inventory_new set "
		     ++ ?utils:to_sqls(proplists, comma, UpdatesOfStock)
		     ++ " where merchant=" ++ ?to_s(Merchant)
		     ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"]
	    end,

    Sql2 =
	case Bill + Veri - OBill - OVeri of
	    0 -> [] ;
	    Metric -> 
		["update suppliers set balance=balance-" ++ ?to_s(Metric)
		 ++ " where id=" ++ ?to_s(FirmId),
		 
		 "update w_bill_detail set "
		 "balance=balance-" ++ ?to_s(Metric)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and id>" ++ ?to_s(BillId),

		"update w_inventory_new set "
		"balance=balance-" ++ ?to_s(Metric)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and id>" ++ ?to_s(StockId)]
	end,

    Reply = ?sql_utils:execute(transaction, Sql1 ++ Sql11 ++ Sql2, RSN),
    ?w_user_profile:update(firm, Merchant),
    {reply, Reply, State};

handle_call({check_bill_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("check_bill_supplier with merchant ~p, attrs ~p", [Merchant, Attrs]),
    RSN  = ?v(<<"rsn">>, Attrs),
    Mode = ?v(<<"mode">>, Attrs),

    Sql = "update w_bill_detail set "
	"state=" ++ ?to_s(Mode)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'",

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({abandon_bill_supplier, Merchant, Attrs}, _From, State) ->
    ?DEBUG("abandon_bill_supplier with merchant ~p, attrs ~p", [Merchant, Attrs]),
    RSN       = ?v(<<"rsn">>, Attrs),
    BillId    = ?v(<<"bill_id">>, Attrs),
    StockId   = ?v(<<"stock_id">>, Attrs),
    BillState = ?v(<<"state">>, Attrs),
    Bill      = ?v(<<"bill">>, Attrs),
    Veri    = ?v(<<"veri">>, Attrs),
    FirmId    = ?v(<<"firm">>, Attrs),
    case BillState =:= ?DISCARD of
	true  -> {reply, ?err(supplier_bill_discard, RSN)};
	false ->
	    Sqls = ["update w_bill_detail set "
		    "state=" ++ ?to_s(?DISCARD)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'",

		    "update w_inventory_new set "
		    "state=" ++ ?to_s(?DISCARD)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'",

		    "update suppliers set balance=balance+" ++ ?to_s(Bill+Veri)
		    ++ " where id=" ++ ?to_s(FirmId),

		    "update w_bill_detail set "
		    "balance=balance+" ++ ?to_s(Bill+Veri)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id>" ++ ?to_s(BillId),

		    "update w_inventory_new set "
		    "balance=balance+" ++ ?to_s(Bill+Veri)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id>" ++ ?to_s(StockId)],

	    Reply = ?sql_utils:execute(transaction, Sqls, RSN),
	    {reply, Reply, State}
    end;

handle_call({bill_lookup, Merchant, Conditions}, _From, State) ->
    ?DEBUG("bill_lookup with merchant ~p, conditions ~p", [Merchant, Conditions]),
    RSN = ?v(<<"rsn">>, Conditions),
    NewConditions = ?utils:correct_condition(
		       <<"a.">>, proplists:delete(<<"rsn">>, Conditions)),
    Sql = "select a.id, a.rsn"
	", a.shop as shop_id, a.firm as firm_id"
	", a.mode, a.balance, a.bill, a.veri"
	", a.card as card_id, a.employee as employee_id"
	", a.comment, a.state, a.merchant, a.entry_date"

	", b.id as sid"
	" from w_bill_detail a, w_inventory_new b"
	" where a.merchant=b.merchant and a.rsn=b.rsn"
	" and a.merchant="++ ?to_s(Merchant)
	++ " and a.rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ ?sql_utils:condition(proplists, NewConditions),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({total_bill, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_bill with merchant ~p, conditions ~p", [Merchant, Conditions]),
    CountSql = "count(*) as total"
	", sum(bill) as t_bill" 
	", sum(veri) as t_veri" ,
    Sql = ?sql_utils:count_table(
	     w_bill_detail, CountSql, Merchant, Conditions), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({bill_detail,
	     Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("bill_detail:  merchant ~p, currentPage ~p, ItemsPerpage ~p~nfields ~p",
	   [Merchant, CurrentPage, ItemsPerPage, Conditions]),

    {StartTime, EndTime, NewConditions} =
	?sql_utils:cut(fields_no_prifix, Conditions),
    Sql = "select rsn, shop as shop_id, firm as firm_id, mode, balance, bill"
	", veri, card as card_id, employee as employee_id"
	", comment, state, merchant, entry_date"
	" from w_bill_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime)
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    
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
bill_mode(?CASH, Balance) ->
    {Balance, 0, 0};
bill_mode(?CARD, Balance) ->
    {0, Balance, 0};
bill_mode(?WIRE, Balance) ->
    {0, 0, Balance}.
    
fields() -> "name, mobile, address, merchant".
