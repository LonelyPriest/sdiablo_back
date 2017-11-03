-module(diablo_firm_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

-define(d, ?utils:seperator(csv)).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = firm_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "firmApp"},
			  {ngcontroller, "firmCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_firm"}) ->
    ?DEBUG("list firm with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    %% batch_responed(fun() -> ?supplier:supplier(w_list, Merchant) end, Req);
    batch_responed(fun() -> ?w_user_profile:get(firm, Merchant) end, Req);

action(Session, Req, {"list_brand"}) ->
    ?DEBUG("list brand with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    %% batch_responed(fun()->?attr:brand(list, Merchant) end, Req);
    batch_responed(fun()->?w_user_profile:get(brand, Merchant) end, Req); 

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_frim", FirmId}) ->
    ?DEBUG("delete firm with session ~p, id ~p", [Session, FirmId]),
    ok = ?supplier:supplier(delete, {"id", ?to_integer(FirmId)}),
    ?utils:respond(200, Req, ?succ(delete_supplier, FirmId));

action(Session, Req, {"delete_brand", Id}) ->
    ?DEBUG("delete_brand with session ~p, id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    case ?attr:brand(delete, Merchant, Id) of
	{ok, GoodId} ->
	    ?utils:respond(200, Req, ?succ(delete_purchaser_good, GoodId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_firm"}, Payload) ->
    ?DEBUG("new frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?supplier:supplier(w_new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, FirmId} ->
	    %% ?supplier:update(code, Merchant, FirmId),
	    ?w_user_profile:update(firm, Merchant),
	    ?utils:respond(200, Req, ?succ(add_supplier, FirmId), {<<"id">>, FirmId}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_firm"}, Payload) ->
    ?DEBUG("update frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    FirmId  = ?v(<<"firm_id">>, Payload),
    case ?supplier:supplier(w_delete, Merchant, FirmId) of
	{ok, FirmId} ->
	    ?utils:respond(200, Req, ?succ(delete_supplier, FirmId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_firm"}, Payload) ->
    ?DEBUG("update frim with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?supplier:supplier(w_update, Merchant, Payload) of
	{ok, FirmId} ->
	    ?w_user_profile:update(firm, Merchant), 
	    ?utils:respond(200, Req, ?succ(update_supplier, FirmId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% brand
%%
action(Session, Req, {"new_brand"}, Payload) ->
    ?DEBUG("new brand with session ~p,  payload ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?attr:brand(new, Merchant, Payload) of
	{ok, BrandId} ->
	    ?utils:respond(
	       200, Req, ?succ(add_brand, BrandId), {<<"id">>, BrandId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_brand"}, Payload) ->
    ?DEBUG("update brand with session ~p,  payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    case ?attr:brand(update, Merchant, Payload) of
	{ok, BrandId} ->
	    ?utils:respond(
	       200, Req, ?succ(update_brand, BrandId), {<<"id">>, BrandId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"bill_w_firm"}, Payload) ->
    ?DEBUG("bill_w_firm with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    FirmId = ?v(<<"firm">>, Payload),
    Datetime = ?v(<<"datetime">>, Payload),
    %% check time
    case ?supplier:bill(check_time, Merchant, {FirmId, Datetime}) of
	{ok, check} -> 
	    case ?supplier:supplier(bill, Merchant, Payload) of
		{ok, FirmId} ->
		    ?w_user_profile:update(firm, Merchant), 
		    ?utils:respond(200, Req, ?succ(bill_firm, FirmId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} -> 
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_bill_w_firm"}, Payload) ->
    ?DEBUG("update_bill_w_firm with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    BillRSN  = ?v(<<"rsn">>, Payload),

    try
	{ok, OldBill} = ?supplier:bill(lookup, Merchant, [{<<"rsn">>, BillRSN}]), 
	case ?supplier:supplier(update_bill, Merchant, {Payload, OldBill}) of
	    {ok, RSN} ->
		?w_user_profile:update(firm, Merchant), 
		?utils:respond(200, Req, ?succ(update_bill_check, RSN));
	    {error, Error} ->
		?utils:respond(200, Req, Error)
	end
    catch
	_:{badmatch, Error1} -> ?utils:respond(200, Req, Error1)
    end;

action(Session, Req, {"check_w_firm_bill"}, Payload) ->
    ?DEBUG("check_w_firm_bill with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),

    case ?supplier:supplier(check_bill, Merchant, Payload) of
	{ok, RSN} ->
	    ?utils:respond(200, Req, ?succ(bill_check, RSN));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"abandon_w_firm_bill"}, Payload) ->
    ?DEBUG("check_w_firm_bill with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload),
    
    case ?supplier:bill(lookup, Merchant, [{<<"rsn">>, RSN}]) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(supplier_bill_not_exist, RSN));
	{ok, TheBill} ->
	    BillId  = ?v(<<"id">>, TheBill),
	    StockId = ?v(<<"sid">>, TheBill),
	    State   = ?v(<<"state">>, TheBill),
	    Bill    = ?v(<<"bill">>, TheBill),
	    Veri    = ?v(<<"veri">>, TheBill),
	    Firm    = ?v(<<"firm_id">>, TheBill),
	    Datetime = ?v(<<"entry_date">>, TheBill),
	    
	    Attrs = [{<<"rsn">>, RSN},
		     {<<"bill_id">>, BillId},
		     {<<"stock_id">>, StockId},
		     {<<"state">>, State},
		     {<<"bill">>, ?to_f(Bill)},
		     {<<"veri">>, Veri},
		     {<<"firm">>, Firm},
		     {<<"datetime">>, Datetime}],
	    case ?supplier:supplier(abandon_bill, Merchant, Attrs) of
		{ok, RSN} ->
		    ?w_user_profile:update(firm, Merchant), 
		    ?utils:respond(200, Req, ?succ(bill_abandon, RSN));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_firm_bill"}, Payload) ->
    ?DEBUG("get_firm_bill with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(
       object, fun() -> ?supplier:bill(lookup, Merchant, Payload) end, Req); 

action(Session, Req, {"filter_firm_bill_detail"}, Payload) -> 
    ?DEBUG("filter_firm_bill_detail with session ~p, paylaod~n~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?supplier:filter(
		  total_bill, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?supplier:filter(
		  bill, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
       end, Req, Payload);

action(Session, Req, {"export_w_firm"}, Payload) ->
    ?DEBUG("export_w_firm with session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    case ?supplier:supplier(w_list, Merchant) of
	[] -> ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
	{ok, Firms} ->
	    {ok, ExportFile, Url} = ?utils:create_export_file("firm", Merchant, UserId),

	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} ->
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(firm, DoFun),
			do_write(firm, DoFun, 1, Firms),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p",
				   [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(
			       200, Req, ?err(wsale_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wsale_export_error, Error))
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"analysis_profit_w_firm"}, Payload) ->
    ?DEBUG("analysis_profit_w_firm:session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    {struct, Conditions} = ?v(<<"condition">>, Payload, []),
    CurrentPage = ?v(<<"page">>, Payload, 1),
    ItemsPerpage = ?v(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE),

    {struct, Mode}     = ?v(<<"mode">>, Payload),
    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode),

    {_, _, ConditionsWithOutTime} = ?sql_utils:cut(non_prefix, Conditions),

    %% FF = fun (V) when V =:= <<>> -> 0;
    %% 	     (Any)  -> ?to_f(Any)
    %% 	 end,
    
    try
	{Total, Others} = 
	    case CurrentPage =:= 1 of
		true ->
		    {ok, R} = ?supplier:supplier(page_total, Merchant, ConditionsWithOutTime),
		    {ok, TBalance} = ?supplier:sprofit(sprofit, balance, Merchant, Conditions),
		    ?DEBUG("tbalance ~p", [TBalance]),
		    {?v(<<"total">>, R),
		     {proplists:delete(<<"total">>, R)
		      ++ [{<<"tbalance">>, ?v(<<"tbalance">>, TBalance)}]
		     }
		    };
		false -> {0, []}
	    end,

	case Total =:= 0 andalso CurrentPage =:= 1 of
	    true ->
		?utils:respond(
		   200, object, Req, {[{<<"ecode">>, 0},
				       {<<"total">>, Total},
				       {<<"firm">>, []},
				       {<<"sale">>, []},
				       {<<"stockin">>, []},
				       {<<"stockout">>, []},
				       %% {<<"stockall">>, []},
				       {<<"balance">>, []}
				      ]});
	    false ->
		{ok, Firms} = ?supplier:supplier(
				 {page_list, ?w_inventory_request:mode(Order), Sort},
				 Merchant,
				 ConditionsWithOutTime,
				 CurrentPage,
				 ItemsPerpage),
		FirmIds = lists:foldr(fun({Firm}, Acc) ->
					      [?v(<<"id">>, Firm)|Acc]
				      end, [], Firms), 
		NConditions = [{<<"firm">>, FirmIds}|Conditions],
	
		{ok, Sales} = ?supplier:profit(profit, sale_of_firm, Merchant, NConditions),
		{ok, StockIn} = ?supplier:profit(profit, stock_in_of_firm, Merchant, NConditions),
		{ok, StockOut} = ?supplier:profit(profit, stock_out_of_firm, Merchant, NConditions),
		%% {ok, StockAll} = ?supplier:profit(profit, stock_all, Merchant, NConditions),
		{ok, StockBalance} = ?supplier:profit(profit, balance, Merchant, NConditions),

		SS = 
		    lists:foldr(
		      fun({S}, Acc) ->
			      [{[{<<"firm_id">>, ?v(<<"firm_id">>, S)},
				 {<<"has_pay">>, ?v(<<"has_pay">>, S)},
				 {<<"veri">>,    ?v(<<"verificate">>, S)},
				 {<<"epay">>,    ?v(<<"e_pay">>, S)},
				 {<<"balance">>,
				  ?to_f(to_f(?v(<<"balance">>, S, 0))
					+ to_f(?v(<<"should_pay">>, S, 0))
					+ to_f(?v(<<"e_pay">>, S, 0))
					- to_f(?v(<<"has_pay">>, S, 0))
					- to_f(?v(<<"verificate">>, S, 0)))
				 }]}|Acc] 
		      end, [], StockBalance),

		%% ?DEBUG("SS ~p", [SS]),

		?utils:respond(200, object, Req,
			       {[{<<"ecode">>, 0},
				 {<<"total">>, Total},
				 {<<"firm">>, Firms},
				 {<<"sale">>, Sales},
				 {<<"stockin">>, StockIn},
				 {<<"stockout">>, StockOut},
				 %% {<<"stockall">>, StockAll},
				 {<<"balance">>, SS},
				 {<<"other">>, Others}
				]})
	end
    catch
	_:{badmatch, {error, Error}} -> ?utils:respond(200, Req, Error) 
    end;

action(Session, Req, {"export_firm_profit"}, Payload) ->
    ?DEBUG("export_firm_profit: session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    
    {struct, Conditions} = ?v(<<"condition">>, Payload), 
    {struct, Mode}     = ?v(<<"mode">>, Payload),

    {_, _, ConditionsWithOutTime} = ?sql_utils:cut(non_prefix, Conditions),
    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportFormat = ?to_i(?v(<<"export_code">>, BaseSetting, 0)), 
    ShowOrgPrice = 
	case ?right_auth:authen(?stock_show_orgprice, Session) of
	    {ok, ?stock_show_orgprice} -> true;
	    _ -> false
	end,
    
    SelectFun =
	fun(Firm, Objs) when is_list(Objs) ->
		case 
		    lists:filter(
		      fun({O}) -> 
			      ?v(<<"firm_id">>, O) =:= Firm
		      end, Objs)
		of
		    [] -> [];
		    [{V}] -> V
		end;
	   (_Firm, _) -> []
	end,
    
    {ok, Firms} = ?supplier:supplier(
		     {page_list, ?w_inventory_request:mode(Order), Sort},
		     Merchant,
		     ConditionsWithOutTime),
    FirmIds = lists:foldr(fun({Firm}, Acc) ->
				  [?v(<<"id">>, Firm)|Acc]
			  end, [], Firms), 
    NConditions = [{<<"firm">>, FirmIds}|Conditions],

    {ok, Sales} = ?supplier:profit(profit, sale_of_firm, Merchant, NConditions),
    %% ?DEBUG("sales ~p", [Sales]),
    {ok, StocksIn} = ?supplier:profit(profit, stock_in_of_firm, Merchant, NConditions),
    %% ?DEBUG("stocksIn ~p", [StocksIn]),
    {ok, StocksOut} = ?supplier:profit(profit, stock_out_of_firm, Merchant, NConditions),
    %% ?DEBUG("stocksOut ~p", [StocksOut]),
    {ok, StocksBalance} = ?supplier:profit(profit, balance, Merchant, NConditions),
    %% ?DEBUG("stocksBalance ~p", [StocksBalance]),
    

    {ok, File, Url} = ?utils:create_export_file("pfirm", Merchant, UserId),
    
    case file:open(File, [append, raw]) of
	{ok, Fd} ->
	    try
		DoFun = fun(C) -> ?utils:write(Fd, C) end,
		csv_head(pfirm, DoFun, {ExportFormat, ShowOrgPrice}),
		do_write(pfirm,
			 DoFun,
			 SelectFun,
			 1,
			 Firms,
			 {Sales, StocksIn, StocksOut, StocksBalance},
			 {ExportFormat, ShowOrgPrice}),
		
		ok = file:datasync(Fd),
		ok = file:close(Fd)
	    catch
		T:W -> 
		    file:close(Fd),
		    ?DEBUG("trace export:T ~p, W ~p~n~p",
			   [T, W, erlang:get_stacktrace()]),
		    ?utils:respond(
		       200, Req, ?err(wsale_export_error, W)) 
	    end,
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"url">>, ?to_b(Url)}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, ?err(wsale_export_error, Error))
    end. 


sidebar(Session) -> 
    NewFirm =
	case ?right_auth:authen(?new_w_firm, Session) of
	    {ok, ?new_w_firm} ->
		[{"new_firm", "新增厂商", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,

    ListFirm =
	case ?right_auth:authen(?list_w_firm, Session) of
	    {ok, ?list_w_firm} ->
		[{"firm_detail", "厂商详情", "glyphicon glyphicon-book"}];
	    _ ->
		[]
	end,

    NewBrand =
	case ?right_auth:authen(?new_w_brand, Session) of
	    {ok, ?new_w_brand} ->
		[{"new_brand", "新增品牌", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,

    ListBrand =
	case ?right_auth:authen(?list_w_brand, Session) of
	    {ok, ?list_w_brand} ->
		[{"brand_detail", "品牌详情", "glyphicon glyphicon-bold"}];
	    _ ->
		[]
	end,

    FirmProfit = 
	case ?right_auth:authen(?analysis_profit_w_firm, Session) of
	    {ok, ?analysis_profit_w_firm} ->
		[{"firm_profit", "进销存分析", "glyphicon glyphicon-font"}];
	    _ ->
		[]
	end,
    
    
    Bill =
        case ?right_auth:authen(?bill_w_firm, Session) of 
            {ok, ?bill_w_firm} ->
                [{{"firm", "厂商结账", "glyphicon glyphicon-check"},
                  [{"bill", "结帐", "glyphicon glyphicon-check"},
                   {"bill_detail", "结帐详情", "glyphicon glyphicon-leaf"}
                  ]
                 }];
            _ ->
                []
        end,
    ?menu:sidebar(level_1_menu, ListFirm ++ ListBrand ++ NewFirm ++ NewBrand)
	++ ?menu:sidebar(level_2_menu, Bill)
	++ ?menu:sidebar(level_1_menu, FirmProfit).

batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch_mochijson, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

csv_head(firm, Do) ->
    H = "序号,名称,欠款,联系方式,联系地址,备注,编号,日期",
    Do(?utils:to_utf8(from_latin1, H)).

do_write(firm, _Do, _Count, []) ->
    ok;
do_write(firm, Do, Count, [{H}|T]) ->
    %% ?DEBUG("firm ~p", [H]),
    Id       = ?v(<<"id">>, H),
    Name     = ?v(<<"name">>, H),
    Balance  = ?v(<<"balance">>, H),
    Mobile   = ?v(<<"mobile">>, H, []),
    Address  = ?v(<<"address">>, H, []),
    Comment  = ?v(<<"comment">>, H, []),
    Datetime = ?v(<<"entry_date">>, H),

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Name) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(Mobile) ++ ?d
	++ ?to_s(Address) ++ ?d
	++ ?to_s(Comment) ++ ?d
	++ ?to_s(?FIRM_PREFIX + Id) ++ ?d
	++ ?to_s(Datetime) ++ ?d, 
    Do(?utils:to_utf8(from_latin1, L)),
    do_write(firm, Do, Count + 1, T).



csv_head(pfirm, Do, {Format, ShowOrgPrice}) ->
    H = case ShowOrgPrice of
	    true ->
		"序号,厂商,已付,核销,费用,欠款,入库数量,入库成本,退货数量,退货成本,销售数量,销售成本,当前库存,库存成本";
	    false ->
		"序号,厂商,入库数量,退货数量,销售数量,当前库存"
	end,

    L = case Format of
	    0 -> ?utils:to_utf8(from_latin1, H);
	    1 -> ?utils:to_gbk(from_latin1, H)
	end,
    Do(L).

do_write(pfirm, _Do, _Select, _Count, [], _Info, _Format) ->
    ok;
do_write(pfirm, Do, Select, Count, [{H}|T],
	 {Sales, StocksIn, StocksOut, StocksBalance},
	 {Format, ShowOrgPrice}) ->
    FirmId = ?v(<<"id">>, H),
    Firm   = ?v(<<"name">>, H),
    %% ?DEBUG("Firm: ~p", [FirmId]),

    Sale     = Select(FirmId, Sales),
    %% ?DEBUG("Sale: ~p", [Sale]),
    
    SIn      = Select(FirmId, StocksIn),
    %% ?DEBUG("StockIn: ~p", [SIn]),
    
    SOut     = Select(FirmId, StocksOut),
    %% ?DEBUG("StockOut: ~p", [SOut]),
    
    SBalance = Select(FirmId, StocksBalance),
    %% ?DEBUG("SBalance: ~p", [SBalance]), 

    Balance = ?v(<<"balance">>, SBalance, 0),
    ShouldPay = ?v(<<"should_pay">>, SBalance, 0),
    EPay    = ?v(<<"e_pay">>, SBalance, 0), 
    HasPay  = ?v(<<"has_pay">>, SBalance, 0),
    Veri    = ?v(<<"verificate">>, SBalance, 0), 
    AccBalance = ?to_f(Balance + ShouldPay + EPay - HasPay - Veri),

    StockIn     = ?v(<<"amount">>, SIn, 0),
    StockInCost = ?v(<<"cost">>, SIn, 0),

    StockOut     = ?v(<<"amount">>, SOut, 0),
    StockOutCost = ?v(<<"cost">>, SOut, 0),

    Sell     = ?v(<<"total">>, Sale, 0),
    SellCost = ?v(<<"cost">>, Sale, 0),

    StockExist = ?v(<<"amount">>, H, 0),
    StockExistCost = ?v(<<"cost">>, H, 0),

    %% ?DEBUG("AccBalance ~p, StockIn ~p, StockInCost ~p, StockOut ~p, StockOutCost ~p"
    %% 	   ", Sell ~p, SellCost ~p, StockExist ~p, StockExistCost ~p",
    %% 	  [AccBalance, StockIn, StockInCost, StockOut, StockOutCost, Sell, SellCost,
    %% 	   StockExist, StockExistCost]),
    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ case ShowOrgPrice of
	       true ->
		   ?to_s(HasPay) ++ ?d
		       ++ ?to_s(Veri) ++ ?d
		       ++ ?to_s(EPay) ++ ?d
		       ++ ?to_s(AccBalance) ++ ?d;
	       false -> []
	   end
	
	++ ?to_s(StockIn) ++ ?d
	++ case ShowOrgPrice of
	       true -> ?to_s(StockInCost) ++ ?d;
	       false -> []
	   end 
	++ ?to_s(StockOut) ++ ?d

	++ case ShowOrgPrice of
	       true -> ?to_s(StockOutCost) ++ ?d;
	       false -> []
	   end 
	
	++ ?to_s(Sell) ++ ?d
	++ case ShowOrgPrice of
	       true -> ?to_s(SellCost) ++ ?d;
	       false -> []
	   end 

	++ ?to_s(StockExist) ++ ?d
	++ case ShowOrgPrice of
	       true -> ?to_s(StockExistCost) ++ ?d;
	       false -> []
	   end,

    Line = case Format of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,

    Do(Line), 
    do_write(pfirm, Do, Select, Count + 1, T,
	     {Sales -- Sale,
	      StocksIn -- SIn,
	      StocksOut -- SOut,
	      StocksBalance -- SBalance},
	     {Format, ShowOrgPrice}).

to_f(<<>>) -> 0;
to_f(V) -> ?to_f(V).
