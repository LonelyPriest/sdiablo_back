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
    ?utils:respond(200, Req, ?succ(delete_supplier, FirmId)).


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
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("firm", Merchant, UserId),

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
    {struct, Conditions} = ?v(<<"condition">>, Payload),
    CurrentPage = ?v(<<"page">>, Payload, 1),
    ItemsPerpage = ?v(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE), 

    FF = fun (V) when V =:= <<>> -> 0;
	     (Any)  -> ?to_f(Any)
	 end,
    
    try
	{Total, Others} = 
	    case CurrentPage =:= 1 of
		true ->
		    {ok, R} = ?supplier:supplier(page_total, Merchant, []),
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
				       {<<"stockall">>, []},
				       {<<"balance">>, []}
				      ]});
	    false ->
		{ok, Firms} = ?supplier:supplier(page_list, Merchant, [], CurrentPage, ItemsPerpage),
		FirmIds = lists:foldr(fun({Firm}, Acc) ->
					      [?v(<<"id">>, Firm)|Acc]
				      end, [], Firms), 
		NConditions = [{<<"firm">>, FirmIds}|Conditions],
	
		{ok, Sales} = ?supplier:profit(profit, sale_of_firm, Merchant, NConditions),
		{ok, StockIn} = ?supplier:profit(profit, stock_in_of_firm, Merchant, NConditions),
		{ok, StockOut} = ?supplier:profit(profit, stock_out_of_firm, Merchant, NConditions),
		{ok, StockAll} = ?supplier:profit(profit, stock_all, Merchant, NConditions),
		{ok, StockBalance} = ?supplier:profit(profit, balance, Merchant, NConditions),

		SS = 
		    lists:foldr(
		      fun({S}, Acc) ->
			      [{[{<<"firm_id">>, ?v(<<"firm_id">>, S)},
				 {<<"has_pay">>, ?v(<<"has_pay">>, S)},
				 {<<"veri">>,    ?v(<<"verificate">>, S)},
				 {<<"epay">>,    ?v(<<"e_pay">>, S)},
				 {<<"balance">>,
				  ?to_f(FF(?v(<<"balance">>, S, 0))
					+ FF(?v(<<"should_pay">>, S, 0))
					+ FF(?v(<<"e_pay">>, S, 0))
					- FF(?v(<<"has_pay">>, S, 0))
					- FF(?v(<<"verificate">>, S, 0)))
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
				 {<<"stockall">>, StockAll},
				 {<<"balance">>, SS},
				 {<<"other">>, Others}
				]})
	end
    catch
	_:{badmatch, {error, Error}} -> ?utils:respond(200, Req, Error) 
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
		[{"firm_profit", "厂商进销存", "glyphicon glyphicon-font"}];
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
	    ?utils:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

csv_head(firm, Do) ->
    H = "序号,名称,欠款,联系方式,联系地址,备注,编号,日期",
    Do(?utils:to_utf8(from_latin1, H)).

do_write(firm, _Do, _Count, []) ->
    ok;
do_write(firm, Do, Count, [{H}|T]) ->
    ?DEBUG("firm ~p", [H]),
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
