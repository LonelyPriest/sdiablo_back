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

-export([supplier/2, supplier/3, filter/4, filter/6, bill/3, supplier/5]).
-export([update/3, datetime2seconds/1, profit/4, sprofit/4, get_modified/2]).

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
supplier(update_bill, Merchant, {Attrs, OldAttrs}) ->
    gen_server:call(?MODULE, {update_bill_supplier, Merchant, {Attrs, OldAttrs}});
supplier(check_bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {check_bill_supplier, Merchant, Attrs});
supplier(abandon_bill, Merchant, Attrs) ->
    gen_server:call(?MODULE, {abandon_bill_supplier, Merchant, Attrs});

supplier(page_total, Merchant, Conditions) ->
    gen_server:call(?MODULE, {page_total, Merchant, Conditions});
supplier({page_list, Mode, Sort}, Merchant, Conditions) ->
    supplier({page_list, Mode, Sort}, Merchant, Conditions, -1, -1).
supplier({page_list, Mode, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    gen_server:call(?MODULE, {page_list, {Mode, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage}).

filter(total_bill, 'and', Merchant, Conditions) ->
    gen_server:call(?MODULE, {total_bill, Merchant, Conditions}).
filter(bill, 'and', Merchant, CurrentPage, ItemsPerPage, Conditions) ->
    gen_server:call(?MODULE, {bill_detail,
			      Merchant, CurrentPage, ItemsPerPage, Conditions}).

bill(lookup, Merchant, Conditions) ->
    gen_server:call(?MODULE, {bill_lookup, Merchant, Conditions});
bill(check_time, Merchant, {Firm, Datetime}) ->
    gen_server:call(?MODULE, {bill_check_time, Merchant, Firm ,Datetime}).

profit(profit, Mode, Merchant, Conditions) ->
    gen_server:call(?MODULE, {profit, Mode, Merchant, Conditions}).

%% stastic
sprofit(sprofit, Mode, Merchant, Conditions) ->
    gen_server:call(?MODULE, {sprofit, Mode, Merchant, Conditions}).

update(code, Merchant, FirmId) ->
    gen_server:cast(?MODULE, {update_code, Merchant, FirmId}).

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
    Address  = ?v(<<"address">>, Attrs, []),
    Expire   = ?v(<<"expire">>, Attrs, -1),
    Merchant = ?v(<<"merchant">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs, []),
    
    %% name can not be same
    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),
    
    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    BCode = ?inventory_sn:sn(firm, Merchant),
	    Sql1 = "insert into " ++ ?tbl_supplier
		++ "(bcode, name, balance, mobile, address, expire, comment, merchant, change_date, entry_date)"
		++ " values ("
		++ ?to_s(BCode) ++ ","
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Balance) ++ ","
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Expire) ++ "," 
		++ "\"" ++ ?to_s(Comment) ++ "\","
		++ ?to_s(Merchant) ++ ","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\","
		++ "\"" ++ ?utils:current_time(localtime) ++ "\");",

	    %% ?DEBUG("sql to supplier ~tp", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(insert, Sql1),
	    %% ?w_user_profile:update(firm, Merchant),
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
    %% OldBalance  = ?v(<<"old_balance">>, Attrs), 
    Mobile   = ?v(<<"mobile">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),
    Expire   = ?v(<<"expire">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(balance, float, Balance)
	++ ?utils:v(mobile,  string, Mobile)
	++ ?utils:v(address, string, Address)
	++ ?utils:v(expire, integer, Expire)
	++ ?utils:v(comment, string, Comment), 

    Sql1 = ["update " ++ ?tbl_supplier ++ " set "
	    ++ ?utils:to_sqls(proplists, comma, Updates)
	    ++ " where id=" ++ ?to_s(FirmId)
	    ++ " and merchant=" ++ ?to_s(Merchant)],
    Sql2 = 
	case Balance =/= 0 of
	    true ->
		Datetime = ?utils:current_time(format_localtime), 
		Sql0 = "select id, balance from " ++ ?tbl_supplier
		    ++ " where "
		    ++ " id=" ++ ?to_s(FirmId)
		    ++ " and merchant=" ++ ?to_s(Merchant),
		CurBalance = 
		    case ?sql_utils:execute(s_read, Sql0) of
			{ok, []} -> 0;
			{ok, Firm} ->
			    ?v(<<"balance">>, Firm, 0) 
		    end,
		
		["insert into firm_balance_history("
		 "firm, balance, metric, action, merchant, entry_date) values("
		 ++ ?to_s(FirmId) ++ ","
		 ++ ?to_s(CurBalance) ++ ","
		 ++ ?to_s(Balance - CurBalance) ++ "," 
		 ++ ?to_s(?UPDATE_FIRM) ++ "," 
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"];
	    false -> []
	end,

    DoUpdate =
	fun() ->
		case Sql2 of
		    [] -> ?sql_utils:execute(write, Sql1, FirmId);
		    _ -> ?sql_utils:execute(transaction, Sql1 ++ Sql2, FirmId)
		end
	end,

    Sql = "select id, " ++ fields()
	++ " from " ++ ?tbl_supplier
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = 
	case Name of
	    undefined ->
		DoUpdate();
	    _ ->
		case ?sql_utils:execute(s_read, Sql) of
		    {ok, []} ->
			DoUpdate();
		    {ok, _} ->
			{error, ?err(supplier_exist, Name)};
		    Error ->
			Error
		end
	end,

    {reply, Reply, State}; 

handle_call({w_delete_supplier, Merchant, Id}, _From, State) ->
    ?DEBUG("w_delete_supplier with merchant ~p, Id ~p", [Merchant, Id]),
    Sql0 = "select id, firm from w_inventory_new"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(Id)
	++ " order by id desc limit 1",
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql = "delete from " ++ ?tbl_supplier
		++ " where id=" ++ ?to_s(Id)
		++ " and merchant=" ++ ?to_s(Merchant), 
	    Reply = ?sql_utils:execute(write, Sql, Id),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State};
	{ok, _R} ->
	    {reply, {error, ?err(firm_retalted_stock, Id)}, State} 
    end;

handle_call({w_list, Merchant}, _From, State) ->
    ?DEBUG("w_list with merchant ~p", [Merchant]),
    Sql = "select id, bcode, name, mobile, address, expire, comment"
	", balance, entry_date from suppliers"
	++ " where "
	++ " merchant=" ++ ?to_s(Merchant)
	++ " and deleted = " ++ ?to_s(?NO)
	++ " order by id",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({page_total, Merchant, Conditions}, _From, State) ->
    ?DEBUG("page_total: merchant ~p, Conditions ~p", [Merchant, Conditions]),
    NewConditions = lists:foldr(fun({<<"firm">>, Firm}, Acc) ->
					[{<<"id">>, Firm}|Acc];
				   (Others, Acc) ->
					[Others|Acc]
				end, [], Conditions),
    Sql = "select count(*) as total"
	" from suppliers where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({page_list, {Mode, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("page_list: merchant ~p, Conditions ~p, CurrentPage ~p, ItemsPerPage ~p",
	   [Merchant, Conditions, CurrentPage, ItemsPerPage]),
    NewConditions = lists:foldr(fun({<<"firm">>, Firm}, Acc) ->
    					[{<<"id">>, Firm}|Acc];
    				   (Others, Acc) ->
    					[Others|Acc]
    				end, [], Conditions),
    Sql = "select a.id"
	", a.name"
	", a.balance"
	", b.sell"
	", b.amount"
	", b.cost"
	
	" from suppliers a"
	" left join"
	" (select firm as firm_id"
	", SUM(sell) as sell"
	", SUM(amount) as amount"
	", SUM(org_price * amount) as cost"
	" from w_inventory where merchant=" ++ ?to_s(Merchant)
	++ " group by firm ) b on a.id=b.firm_id"
	++ " where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, ?utils:correct_condition(<<"a.">>, NewConditions))
	++ case CurrentPage =:= -1 orelse ItemsPerPage =:= -1 of
	       true  -> ?sql_utils:mode(Mode, Sort);
	       false -> ?sql_utils:condition(page_desc, {Mode, Sort}, CurrentPage, ItemsPerPage)
	   end,
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
    %% Datetime = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Attrs)),
    Datetime = ?v(<<"datetime">>, Attrs), 
    %% DateEnd = date_end(Datetime),
    
    Sql0 = "select id, merchant, balance from suppliers"
	" where id=" ++ ?to_s(FirmId)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, Firm} ->
	    Sql00 = "select id, rsn, firm, shop, merchant"
		", balance, should_pay, has_pay, e_pay, verificate, entry_date"
	    	" from w_inventory_new"
	    	" where merchant=" ++ ?to_s(Merchant)
	    	++ " and firm=" ++ ?to_s(FirmId)
		++ " and state in(0, 1)"
	    	++ " and entry_date<\'" ++ ?to_s(Datetime) ++ "\'"
	    	++ " order by entry_date desc limit 1",

	    case ?sql_utils:execute(s_read, Sql00) of
		{ok, LastStockIn} ->
		    LastBalance =
			case LastStockIn of
			    [] ->
				Sql01 = "select id, rsn, firm, shop, merchant"
				    ", balance, should_pay, has_pay, e_pay, verificate, entry_date"
				    " from w_inventory_new"
				    " where merchant=" ++ ?to_s(Merchant)
				    ++ " and firm=" ++ ?to_s(FirmId)
				    ++ " and state in(0, 1)"
				    ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"
				    ++ " order by entry_date limit 1",
				{ok, LastStockInW} = ?sql_utils:execute(s_read, Sql01),
				case LastStockInW of
				    [] -> ?v(<<"balance">>, Firm, 0);
				    _ -> ?v(<<"balance">>, LastStockInW)
				end;
			    _ -> ?v(<<"balance">>, LastStockIn)
				     + ?v(<<"should_pay">>, LastStockIn)
				     + ?v(<<"e_pay">>, LastStockIn)
				     - ?v(<<"has_pay">>, LastStockIn)
				     - ?v(<<"verificate">>, LastStockIn)
			end,
		    CurrentBalance = ?v(<<"balance">>, Firm, 0), 

		    RSN = lists:concat(
			    ["M-", ?to_i(Merchant), "-S-", ?to_i(ShopId), "-C-",
			     ?inventory_sn:sn(w_firm_bill, Merchant)]),
		    
		    Sql1 = "insert into w_bill_detail("
			"rsn, shop, firm, mode, balance, bill, veri, card, employee"
			", comment, merchant, entry_date, op_date) values("
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
			++ "\'" ++ ?to_s(Datetime) ++ "\',"
			++ "\'" ++ ?to_s(CurrentDatetime) ++ "\')",

		    {Cash, Card, Wire} = bill_mode(Mode, Bill),

		    Sql2 = "insert into w_inventory_new(rsn"
			", employ, firm, shop, merchant, balance"
			", has_pay, cash, card, wire, verificate"
			", comment, type, entry_date, op_date) values("
			++ "\'" ++ ?to_s(RSN) ++ "\',"
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(FirmId) ++ ","
			++ ?to_s(ShopId) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(LastBalance) ++ ","
			++ ?to_s(Bill) ++ ","
			++ ?to_s(Cash) ++ ","
			++ ?to_s(Card) ++ ","
			++ ?to_s(Wire) ++ ","
			++ ?to_s(Veri) ++ ","
			++ "\"" ++ ?to_s(Comment) ++ "\"," 
			++ ?to_s(?FIRM_BILL) ++ ","
			++ "\"" ++ ?to_s(Datetime) ++ "\","
			++ "\'" ++ ?to_s(CurrentDatetime) ++ "\')",

		    Sql3 = "update suppliers set balance=balance-" ++ ?to_s(Bill + Veri)
			++ ", change_date=" ++ "\"" ++ ?to_s(CurrentDatetime) ++ "\""
			++ " where merchant=" ++ ?to_s(Merchant)
			++ " and id=" ++ ?to_s(FirmId),

		    Sql4 = "update w_inventory_new set balance=balance-" ++ ?to_s(Bill + Veri)
			++ " where merchant=" ++ ?to_s(Merchant)
			++ " and firm=" ++ ?to_s(FirmId)
			++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'",

		    Sql5 = "insert into firm_balance_history("
			"rsn, firm, balance, metric, action, shop, merchant, entry_date) values("
			++ "\'" ++ ?to_s(RSN) ++ "\',"
			++ ?to_s(FirmId) ++ ","
			++ ?to_s(CurrentBalance) ++ ","
			++ ?to_s(-Bill) ++ ","
			++ ?to_s(?FIRM_BILL) ++ ","
			++ ?to_s(ShopId) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ "\'" ++ ?to_s(CurrentDatetime) ++ "\')",

		    Reply = ?sql_utils:execute(transaction, [Sql1, Sql2, Sql3, Sql4, Sql5], FirmId),
		    {reply, Reply, State};
		{error, Error} ->
		    {reply, Error, State}
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_bill_supplier, Merchant, {Attrs, OldAttrs}}, _From, State) ->
    ?DEBUG("update_bill_supplier with merchant ~p, attrs ~p, oldattrs ~p",
	   [Merchant, Attrs, OldAttrs]),

    BillId   = ?v(<<"id">>, OldAttrs),
    %% StockId  = ?v(<<"sid">>, OldAttrs),
    
    RSN      = ?v(<<"rsn">>, Attrs), 
    FirmId   = ?v(<<"firm">>, Attrs), 
    Shop     = ?v(<<"shop">>, Attrs),
    OldShop  = ?v(<<"shop_id">>, OldAttrs), 
    Mode     = ?v(<<"mode">>, Attrs),
    %% OldMode  = ?v(<<"mode">>, OldAttrs),
    Bill     = ?v(<<"bill">>, Attrs),
    OldBill  = ?v(<<"bill">>, OldAttrs),
    Veri     = ?v(<<"veri">>, Attrs),
    OldVeri  = ?v(<<"veri">>, OldAttrs),
    
    BankCard = ?v(<<"card">>, Attrs),
    OldBankCard = ?v(<<"card_id">>, OldAttrs),
    
    Employee = ?v(<<"employee">>, Attrs),
    OldEmployee = ?v(<<"employee_id">>, OldAttrs),
    
    Comment  = ?v(<<"comment">>, Attrs),
    OldComment = ?v(<<"comment">>, OldAttrs),
    
    Datetime = ?v(<<"datetime">>, Attrs),
    OldDatetime = ?v(<<"entry_date">>, OldAttrs),
    %% DateEnd = date_end(Datetime),

    {Cash, Card, Wire} = bill_mode(Mode, Bill),
    Updates
	= ?utils:v(shop, integer, get_modified(Shop, OldShop)) 
	++ ?utils:v(employee, string, get_modified(Employee, OldEmployee))
	++ ?utils:v(comment, string, get_modified(Comment, OldComment))
	++ ?utils:v(entry_date, string, get_modified(Datetime, OldDatetime)), 

    
    Sql10 = ["update w_bill_detail set "
	     ++ ?utils:to_sqls(
		   proplists,
		   comma,
		   Updates
		   ++ ?utils:v(mode, integer, Mode) 
		   ++ ?utils:v(bill, float, get_modified(Bill, OldBill))
		   ++ ?utils:v(veri, float, get_modified(Veri, OldVeri)) 
		   ++ ?utils:v(card, integer, get_modified(BankCard, OldBankCard)))
	     ++ " where merchant=" ++ ?to_s(Merchant)
	     ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"],

    UpdatesOfStock = Updates ++ ?utils:v(cash, float, Cash)
	++ ?utils:v(card, float, Card)
	++ ?utils:v(wire, float, Wire)
	++ ?utils:v(has_pay, float, get_modified(Bill, OldBill))
	++ ?utils:v(verificate, float, get_modified(Veri, OldVeri)),
    
    Sqls = 
	case get_modified(Datetime, OldDatetime) of
	    undefined ->
		{ok, ["update w_inventory_new set "
		 ++ ?utils:to_sqls(proplists, comma, UpdatesOfStock)
		 ++ " where merchant=" ++ ?to_s(Merchant)
		 ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"]
		 ++ case Bill + Veri - OldBill - OldVeri of
			0 -> [];
			Metric -> 
			     ["update suppliers set balance=balance-" ++ ?to_s(Metric)
			      ++ " where merchant=" ++ ?to_s(Merchant)
			      ++ " and id=" ++ ?to_s(FirmId),

			      "update w_bill_detail set "
			      "balance=balance-" ++ ?to_s(Metric)
			      ++ " where merchant=" ++ ?to_s(Merchant)
			      ++ " and firm=" ++ ?to_s(FirmId)
			      ++ " and id>" ++ ?to_s(BillId),

			      "update w_inventory_new set "
			      "balance=balance-" ++ ?to_s(Metric)
			      ++ " where merchant=" ++ ?to_s(Merchant)
			      ++ " and firm=" ++ ?to_s(FirmId)
			      ++ " and entry_date>\'" ++ ?to_s(OldDatetime) ++ "\'"]
		     end
		};
	    Datetime -> 
		Sql00 = "select id, rsn, firm, shop, merchant"
		    ", balance, should_pay, has_pay, e_pay, verificate, entry_date"
		    " from w_inventory_new"
		    " where merchant=" ++ ?to_s(Merchant)
		    ++ " and firm=" ++ ?to_s(FirmId)
		    ++ " and state in(0, 1)"
		    ++ " and entry_date<\'" ++ ?to_s(Datetime) ++ "\'"
		    ++ " order by entry_date desc limit 1",
		case ?sql_utils:execute(s_read, Sql00) of
		    {ok, LastStockIn} ->
			LastBalance =
			    case LastStockIn of
				[] ->
				    Sql01 = "select id, rsn, firm, shop, merchant"
					", balance, should_pay, has_pay, e_pay, verificate"
					", entry_date"
					" from w_inventory_new"
					" where merchant=" ++ ?to_s(Merchant)
					++ " and firm=" ++ ?to_s(FirmId)
					++ " and state in(0, 1)"
					++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"
					++ " order by entry_date limit 1",
				    {ok, LastStockInW} = ?sql_utils:execute(s_read, Sql01),
				    case LastStockInW of
					[] ->
					    case ?w_user_profile:get(firm, Merchant, FirmId) of
						{ok, []} -> 0;
						{ok, FirmProfile} ->
						    ?v(<<"balance">>, FirmProfile, 0)
					    end;
					_ -> ?v(<<"balance">>, LastStockInW, 0)
				    end;
				_  -> ?v(<<"balance">>, LastStockIn)
					  + ?v(<<"should_pay">>, LastStockIn)
					  + ?v(<<"e_pay">>, LastStockIn)
					  - ?v(<<"has_pay">>, LastStockIn)
					  - ?v(<<"verificate">>, LastStockIn)
			    end,

			AllUpdate = UpdatesOfStock ++ ?utils:v(balance, float, LastBalance),
			?DEBUG("AllUpdate ~p", [AllUpdate]),

			Metric = Bill + Veri - OldBill - OldVeri,
			    
			{ok, 
			 ["update w_inventory_new set "
			  "balance=balance+" ++ ?to_s(OldBill + OldVeri)
			  ++ " where merchant=" ++ ?to_s(Merchant)
			  ++ " and firm=" ++ ?to_s(FirmId)
			  ++ " and entry_date>\'" ++ ?to_s(OldDatetime) ++ "\'",

			  "update w_inventory_new set "
			  "balance=balance-" ++ ?to_s(Bill + Veri)
			  ++ " where merchant=" ++ ?to_s(Merchant)
			  ++ " and firm=" ++ ?to_s(FirmId)
			  ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"]

			 ++ case ?to_b(Datetime) > ?to_b(OldDatetime) of
				true ->
				    ["update w_inventory_new set "
				     ++ ?utils:to_sqls(
					   proplists,
					   comma,
					   UpdatesOfStock
					   ++ ?utils:v(
						 balance, float, LastBalance + OldBill + OldVeri))
				     ++ " where merchant=" ++ ?to_s(Merchant)
				     ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"];
				false ->
				    ["update w_inventory_new set "
				     ++ ?utils:to_sqls(proplists, comma, AllUpdate)
				     ++ " where merchant=" ++ ?to_s(Merchant)
				     ++ " and rsn=\'" ++ ?to_s(RSN) ++ "\'"]
			    end
			 
			 ++ case Metric == 0 of
				true -> [];
				false ->
				    [
				     "update suppliers set balance=balance-" ++ ?to_s(Metric)
				     ++ " where merchant=" ++ ?to_s(Merchant)
				     ++ " and id=" ++ ?to_s(FirmId),
				     
				     "update w_bill_detail set "
				     "balance=balance-" ++ ?to_s(Metric)
				     ++ " where merchant=" ++ ?to_s(Merchant)
				     ++ " and firm=" ++ ?to_s(FirmId)
				     ++ " and id>" ++ ?to_s(BillId)]
			    end
			};
		    Error -> Error
		end 
	end,

    case Sqls of
	{ok, AllSql} -> 
	    Reply = ?sql_utils:execute(transaction, Sql10 ++ AllSql, RSN),
	    {reply, Reply, State};
	Error1 -> 
	    {reply, Error1, State}
    end;

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
    %% StockId   = ?v(<<"stock_id">>, Attrs),
    BillState = ?v(<<"state">>, Attrs),
    Bill      = ?v(<<"bill">>, Attrs),
    Veri      = ?v(<<"veri">>, Attrs),
    FirmId    = ?v(<<"firm">>, Attrs),
    Datetime  = ?v(<<"datetime">>, Attrs),
    
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
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and id=" ++ ?to_s(FirmId),

		    "update w_bill_detail set "
		    "balance=balance+" ++ ?to_s(Bill+Veri)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and firm=" ++ ?to_s(FirmId)
		    ++ " and id>" ++ ?to_s(BillId),

		    "update w_inventory_new set "
		    "balance=balance+" ++ ?to_s(Bill+Veri)
		    ++ " where merchant=" ++ ?to_s(Merchant)
		    ++ " and firm=" ++ ?to_s(FirmId)
		    ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"],
		    %% ++ " and id>" ++ ?to_s(StockId)],

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
	     w_bill_detail, CountSql, Merchant, Conditions ++ [{<<"state">>, [0, 1]}]), 
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({bill_detail,
	     Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("bill_detail:  merchant ~p, currentPage ~p, ItemsPerpage ~p~nfields ~p",
	   [Merchant, CurrentPage, ItemsPerPage, Conditions]),

    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    Sql = "select rsn, shop as shop_id, firm as firm_id, mode, balance, bill"
	", veri, card as card_id, employee as employee_id"
	", comment, state, merchant, entry_date, op_date"
	" from w_bill_detail"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime) 
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({bill_check_time, Merchant, Firm, Datetime}, _From, State) ->
    Sql = "select id, rsn, firm, entry_date"
	" from w_bill_detail where merchant=" ++ ?to_s(Merchant)
	++ " and firm=" ++ ?to_s(Firm)
	++ " and entry_date=\'" ++ ?to_s(Datetime) ++ "\'",
    case ?sql_utils:execute(read, Sql) of
	{ok, []} -> {reply, {ok, check}, State};
	{ok, _} -> {reply, {error, ?err(bill_at_same_time, Firm)}, State};
	Error -> {reply, Error, State}
    end;

handle_call({profit, sale_of_firm, Merchant, Conditions}, _From, State) ->
    ?DEBUG("sale_of_firm: Merchant ~p, conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions),
    %% Sql = 
    %% 	"select a.id"
    %% 	", a.name as firm"
	
    %% 	", b.total as stotal"
    %% 	", b.cost as scost"

    %% 	", c.amount as itotal"
    %% 	", c.over as iover"
    %% 	", c.cost as icost"
    %% 	", c.ocost as ovcost"

    %% 	", d.amount as ototal"
    %% 	", d.cost as ocost"
	
    %% 	++ " from (select id, name from suppliers where merchant=" ++ ?to_s(Merchant)
    %% 	++ " order by id limit 0, 10) a"
	
    %% 	++ " left join "

    %% 	"(select x.firm_id"
    %% 	", SUM(x.total) as total"
    %% 	", SUM(x.total * x.org_price) as cost"
    %% 	" from "
    %% 	"(select a.rsn"
    %% 	", b.total"
    %% 	", b.org_price"
    %% 	", b.firm as firm_id"

    %% 	" from w_sale a, w_sale_detail b" 
    %% 	" where a.merchant=" ++ ?to_s(Merchant) 
    %% 	++ ?sql_utils:condition(proplists, NewConditions) 
    %% 	++ " and a.rsn=b.rsn"
    %% 	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) ++ ") x"
    %% 	++ " group by firm_id) b on a.id=b.firm_id"

    %% 	++ " left join "
	
    %% 	"(select a.rsn"
    %% 	", a.firm as firm_id" 
    %% 	", SUM(a.org_price * a.amount) as cost"
    %% 	", SUM(a.org_price * a.over) as ocost"
    %% 	", SUM(a.amount) as amount"
    %% 	", SUM(a.over) as over"

    %% 	" from w_inventory_new_detail a, w_inventory_new b" 
    %% 	" where a.merchant=" ++ ?to_s(Merchant)
    %% 	++ ?sql_utils:condition(proplists, NewConditions) 
    %% 	++ " and a.rsn=b.rsn"
    %% 	++ " and b.type=0"
    %% 	++ " and b.state in(0, 1)"
    %% 	++ " and " ++ ?sql_utils:time_condition(StartTime, "b.entry_date", ge)
    %% 	++ " and " ++ ?sql_utils:time_condition(EndTime, "b.entry_date", le)
    %% 	++ " group by a.firm) c on a.id=c.firm_id"

    %% 	++ " left join "

    %% 	"(select a.rsn"
    %% 	", a.firm as firm_id" 
    %% 	", SUM(a.org_price * a.amount) as cost"
    %% 	", SUM(a.amount) as amount"

    %% 	" from w_inventory_new_detail a, w_inventory_new b" 
    %% 	" where a.merchant=" ++ ?to_s(Merchant)
    %% 	++ ?sql_utils:condition(proplists, NewConditions) 
    %% 	++ " and a.rsn=b.rsn"
    %% 	++ " and b.type=1"
    %% 	++ " and b.state in(0, 1)"
    %% 	++ " and " ++ ?sql_utils:time_condition(StartTime, "b.entry_date", ge)
    %% 	++ " and " ++ ?sql_utils:time_condition(EndTime, "b.entry_date", le)
    %% 	++ " group by a.firm) d on a.id=d.firm_id", 
    
    Sql =
    	"select x.merchant, x.firm_id"
	", SUM(x.total) as total"
	", SUM(x.total * x.org_price) as cost"
	
    	" from " 
    	"(select a.rsn"
    	", b.total"
    	", b.org_price"
	", b.merchant"
    	", b.firm as firm_id"
	
    	" from w_sale a, w_sale_detail b" 
    	" where a.merchant=" ++ ?to_s(Merchant) 
    	++ ?sql_utils:condition(proplists, NewConditions) 
    	++ " and a.rsn=b.rsn"
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) ++ ") x"
    	++ " group by x.merchant, x.firm_id",
    
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({profit, stock_in_of_firm, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    %% CorrectConditions = ?utils:correct_condition(<<"a.">>, NewConditions),
    Sql =
	"select a.rsn, a.merchant"
	", a.firm as firm_id" 
	", SUM(a.org_price * a.amount) as cost"
	", SUM(a.org_price * a.over) as ocost"
	", SUM(a.amount) as amount"
	", SUM(a.over) as over"
	
	" from w_inventory_new_detail a, w_inventory_new b" 
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) 
	++ " and a.rsn=b.rsn"
	++ " and b.type=0"
	++ " and b.state in(0, 1)"
	++ " and " ++ ?sql_utils:time_condition(StartTime, "b.entry_date", ge)
	++ " and " ++ ?sql_utils:time_condition(EndTime, "b.entry_date", le)
	++ " group by a.merchant, a.firm",
    
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({profit, stock_out_of_firm, Merchant, Conditions}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    %% CorrectConditions = ?utils:correct_condition(<<"a.">>, NewConditions),

    Sql =
	"select a.rsn, a.merchant"
	", a.firm as firm_id" 
	", SUM(a.org_price * a.amount) as cost"
	", SUM(a.amount) as amount"

	" from w_inventory_new_detail a, w_inventory_new b" 
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) 
	++ " and a.rsn=b.rsn"
	++ " and b.type=1"
	++ " and b.state in(0, 1)"
	++ " and " ++ ?sql_utils:time_condition(StartTime, "b.entry_date", ge)
	++ " and " ++ ?sql_utils:time_condition(EndTime, "b.entry_date", le)
	++ " group by a.merchant, a.firm", 
    
    R = ?sql_utils:execute(read, Sql), 
    {reply, R, State};

handle_call({profit, stock_all, Merchant, Conditions}, _From, State) ->
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    %% CorrectConditions = ?utils:correct_condition(<<"a.">>, NewConditions),
    Sql = "select a.merchant"
	", a.firm as firm_id"
	", SUM(a.amount) as amount"
	", SUM(a.org_price * a.amount) as cost"
	%% "select a.rsn"
	%% ", a.firm as firm_id" 
	%% ", SUM(a.org_price * a.amount) as cost"
	%% ", SUM(a.org_price * a.over) as ocost"
	%% ", SUM(a.amount) as amount"
	%% ", SUM(a.over) as over"

	" from w_inventory a" 
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) 
	%% ++ " and a.rsn=b.rsn"
	%% ++ " and b.type in (0, 1)"
	%% ++ " and b.state in(0, 1)" 
	++ " group by a.merchant, a.firm", 

    R = ?sql_utils:execute(read, Sql), 
    {reply, R, State};

handle_call({profit, balance, Merchant, Conditions}, _From, State) ->
    {_StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = "select a.id"
	", a.merchant"
	", a.firm as firm_id"
	", a.balance"
	", a.should_pay"
	", a.has_pay"
    %% ", a.cash"
    %% ", a.card"
    %% ", a.wire"
	", a.verificate"
	", a.e_pay"
	", a.entry_date"
	
	" from w_inventory_new a"
	" inner join"
	" (select max(a.entry_date) as entry, a.merchant, a.firm from w_inventory_new a"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, undefined, EndTime)
	++ " group by a.merchant, a.firm) b on "
	" a.merchant=b.merchant and a.firm=b.firm and a.entry_date=b.entry"
	
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, undefined, EndTime),
    
    R = ?sql_utils:execute(read, Sql),
    {reply, R, State};

handle_call({sprofit, balance, Merchant, Conditions}, _From, State) ->
    {_StartTime, EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    Sql = "select a.merchant"
	", SUM(a.should_pay - a.has_pay - a.verificate + a.e_pay) as tbalance"
    %% ", a.should_pay"
	%% ", a.has_pay" 
	%% ", a.verificate"
	%% ", a.e_pay"
    %% ", a.entry_date"
	" from w_inventory_new a" 

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:fix_condition(time, time_with_prfix, undefined, EndTime),

    R = ?sql_utils:execute(s_read, Sql),
    {reply, R, State}; 

handle_call(_Request, _From, State) ->
    ?DEBUG("unkown request ~p", [_Request]),
    Reply = ok,
    {reply, Reply, State}.


handle_cast({update_code, Merchant, FirmId}, State) ->
    Sql = "update suppliers set code=1000 + id"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and id=" ++ ?to_s(FirmId), 
    ?sql_utils:execute(write, Sql, FirmId),
    {noreply, State};

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

get_modified(undefined, _OldValue) -> undefined; 
get_modified(NewValue, OldValue) when NewValue /= OldValue ->
    %% ?DEBUG("newValue ~p, oldValue ~p", [NewValue, OldValue]),
    NewValue;
get_modified(_NewValue, _OldValue) ->  undefined.

%% date_end(Datetime) when is_binary(Datetime) ->
%%     <<YYMMDD:10/binary, _/binary>> = ?to_b(Datetime), 
%%     {Hour, Minute, Second} = calendar:seconds_to_time(86399),
%%     Time = ?to_b(
%% 	      lists:flatten(
%% 		io_lib:format("~2..0w:~2..0w:~2..0w", [Hour, Minute, Second]))),
%%     DateEnd = <<YYMMDD/binary, <<" ">>/binary, Time/binary>>,
%%     DateEnd;
%% date_end(Datetime) ->
%%     date_end(?to_b(Datetime)).

datetime2seconds(Datetime) when is_binary(Datetime)->
    <<YY:4/binary, "-",  MM:2/binary, "-", DD:2/binary, " ",
      HH:2/binary, ":", MMM:2/binary, ":", SS:2/binary>> = Datetime,

    calendar:datetime_to_gregorian_seconds({{?to_i(YY), ?to_i(MM), ?to_i(DD)},
					    {?to_i(HH), ?to_i(MMM), ?to_i(SS)}});
datetime2seconds(Datetime) ->
    datetime2seconds(?to_b(Datetime)).


    
				  
