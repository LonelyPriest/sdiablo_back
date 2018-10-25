%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2018, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 24 Oct 2018 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_batch_sale).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).
-export([bsale/3, bsale/4]).
-export([filter/4, filter/6, match/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
bsale(new, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_sale, Merchant, Inventories, Props});
bsale(check, Merchant, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {check_sale, Merchant, RSN, Mode}).

bsale(get_sale, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new, Merchant, RSN});
bsale(get_sale_new_detail, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_detail, Merchant, RSN});
bsale(get_sale_new_note, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_note, Merchant, RSN}).

filter(total_sale_new, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_sale_new, Merchant, Fields});

filter(total_sale_new_detail, MatchMode, Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_sale_new_detail, MatchMode, Merchant, Fields}, 6 * 1000).

filter(sale_new, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_sale_new, Merchant, Conditions, CurrentPage, ItemsPerPage});

filter(sale_new_detail, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_sale_new_detail,
	     {use_id, 0}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields}, 6 * 1000);

filter({sale_new_detail, Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_sale_new_detail,
	     {Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields}, 6 * 1000).

match(rsn, Merchant, {ViewValue, Condition}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_rsn, Merchant, {ViewValue, Condition}}).

%%--------------------------------------------------------------------
%% @doc
%% Starts the server
%%
%% @spec start_link() -> {ok, Pid} | ignore | {error, Error}
%% @end
%%--------------------------------------------------------------------
start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

init([]) ->
    {ok, #state{}}.

handle_call({new_sale, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("new_sale with merchant ~p~n~p, props ~p", [Merchant, Inventories, Props]),
    UserId = ?v(<<"user">>, Props, -1), 
    BSaler   = ?v(<<"bsaler">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    DateTime   = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Employe    = ?v(<<"employee">>, Props),
    Comment    = ?v(<<"comment">>, Props, []),

    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    Verificate = ?v(<<"verificate">>, Props, 0),

    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    HasPay     = ?v(<<"has_pay">>, Props, 0),
    Total      = ?v(<<"total">>, Props, 0),
    
    Sql0 = "select id, name, balance  from batchsaler where id=" ++ ?to_s(BSaler)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    CurrentBalance = case ?v(<<"balance">>, Account) of
				 <<>> -> 0;
				 Balance -> Balance
			     end, 
	    
	    SaleSn = lists:concat(["M-", ?to_i(Merchant), "-BS-", ?to_i(Shop), "-",
				   ?inventory_sn:sn(batch_sale_new_sn, Merchant)]), 
	    Sql1 = lists:foldr(
		     fun({struct, Inv}, Acc0)-> 
			     Amounts = ?v(<<"amounts">>, Inv), 
			     bsale(new, SaleSn, DateTime, Merchant, Shop, Inv, Amounts) ++ Acc0
		     end, [], Inventories), 

	    Sql2 = "insert into batch_sale(rsn"
		", account, employ, bsaler, shop, merchant"
		", balance, should_pay, has_pay, cash, card, wxin, verificate"
		", total, comment, type, entry_date) values("
		++ "\"" ++ ?to_s(SaleSn) ++ "\","
		++ ?to_s(UserId) ++ ","
		++ "\'" ++ ?to_s(Employe) ++ "\',"
		++ ?to_s(BSaler) ++ ","
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Merchant) ++ "," 
		++ ?to_s(CurrentBalance) ++ ","
		++ ?to_s(ShouldPay) ++ ","
		++ ?to_s(HasPay) ++ "," 
		++ ?to_s(Cash) ++ ","
		++ ?to_s(Card) ++ ","
		++ ?to_s(Wxin) ++ "," 
		++ ?to_s(Verificate) ++ ","
		++ ?to_s(Total) ++ "," 
		++ "\"" ++ ?to_s(Comment) ++ "\"," 
		++ ?to_s(type(new)) ++ ","
		++ "\"" ++ ?to_s(DateTime) ++ "\");",

	    Sql3 = "update batchsaler set balance=balance+" ++ ?to_s(ShouldPay - HasPay) 
		++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),
	    
	    AllSql = Sql1 ++ [Sql2] ++ [Sql3],
	    case ?sql_utils:execute(transaction, AllSql, SaleSn) of
		{ok, SaleSn} -> 
		    {reply, {ok, SaleSn} , State};
		Error ->
		    {reply, Error, State}
	    end ;
	Error ->
	    {reply, Error, State}
    end;

handle_call({check_sale, Merchant, RSN, Mode}, _From, State) ->
    ?DEBUG("check_sale with merchant ~p, RSN ~p, mode ~p", [Merchant, RSN, Mode]),
    Sql = "update batch_sale set state=" ++ ?to_s(Mode)
	++ ", check_date=\'" ++ ?utils:current_time(localtime) ++ "\'"
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

handle_call({total_sale_new, Merchant, Fields}, _From, State) ->
    CountSql = count_table(batchsale, Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_sale_new, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_sale_new: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n fields ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = filter_bsale(batchsale_with_page, Merchant, CurrentPage, ItemsPerPage, Fields), 
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_sale_new_detail, MatchMode, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_sale_note with merchant ~p, matchMode ~p, conditions ~p",
	   [Merchant, MatchMode, Conditions]),
    {DConditions, SConditions} = filter_condition(batchsale, Conditions, [], []),

    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions), 
    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    Sql = "select count(*) as total"
    	", SUM(b.total) as t_amount"
	", SUM(b.tag_price * b.total) as t_tbalance"
    	", SUM(b.rprice * b.total) as t_balance"
	", SUM(b.org_price * b.total) as t_obalance"
	
    	" from batch_sale_detail b, batch_sale a"
	
    	" where "
	++ "b.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:like_condition(style_number, MatchMode, CorrectCutDConditions, <<"b.style_number">>) 
	++ " and b.rsn=a.rsn"

	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime), 

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({filter_sale_new_detail,
	     {Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Conditions}, _From, State) ->
    ?DEBUG("filter_rsn_group_and: mode ~p, sort ~p, MatchMode ~p, currentPage ~p, ItemsPerpage ~p, Merchant ~p~n",
	   [Mode, Sort, MatchMode, CurrentPage, ItemsPerPage, Merchant]),
    Sql = sale_new(sale_new_detail, MatchMode, Merchant, Conditions,
		   fun() ->
			   rsn_order(Mode) ++ ?sql_utils:sort(Sort)
			       ++ " limit " ++ ?to_s((CurrentPage-1)*ItemsPerPage)
			       ++ ", " ++ ?to_s(ItemsPerPage)
		   end),
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new, Merchant, RSN} , _From, State) ->
    Sql = filter_bsale(fun()-> [] end, Merchant, [{<<"rsn">>, RSN}]),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_detail, Merchant, RSN} , _From, State) ->
    Sql = sale_new(sale_new_detail, 'and', Merchant, [{<<"rsn">>, RSN}], fun() -> [] end), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_note, Merchant, RSN} , _From, State) ->
    Sql = sale_new(sale_new_note, Merchant, [{<<"rsn">>, RSN}]),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_rsn, Merchant, {ViewValue, Conditions}}, _From, State) ->
    {StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions), 
    Limit = ?w_retailer:get(prompt, Merchant),
    Sql = "select id, rsn from batch_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) 
	++ ?sql_utils:fix_condition(time, time_no_prfix, StartTime, undefined)
	++ " and rsn like \'%" ++ ?to_s(ViewValue) ++ "\'"
	++ " order by id desc"
	++ " limit " ++ ?to_s(Limit), 
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
bsale(Action, RSN, Datetime, Merchant, Shop, Inventory, Amounts) -> 
    ?DEBUG("batch_sale ~p with inv ~p, amounts ~p", [Action, Inventory, Amounts]), 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),

    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory),
    FDiscount   = ?v(<<"fdiscount">>, Inventory),
    RDiscount   = ?v(<<"rdiscount">>, Inventory),
    FPrice      = ?v(<<"fprice">>, Inventory),
    RPrice      = ?v(<<"rprice">>, Inventory),

    Firm        = ?v(<<"firm">>, Inventory),
    Season      = ?v(<<"season">>, Inventory),
    Year        = ?v(<<"year">>, Inventory),
    InDatetime  = ?v(<<"entry">>, Inventory),
    SizeGroup   = ?v(<<"s_group">>, Inventory),
    Total       = case Action of
		      new    -> ?v(<<"sell_total">>, Inventory);
		      reject -> -?v(<<"sell_total">>, Inventory) 
		  end, 
    Free        = ?v(<<"free">>, Inventory),
    Path        = ?v(<<"path">>, Inventory, []),
    Comment     = ?v(<<"comment">>, Inventory, []),

    C1 =
	fun() ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand}, 
				{<<"shop">>, Shop},
				{<<"merchant">>, Merchant}])
	end, 

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"merchant">>, Merchant},
			       {<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,

    Sql00 = "select rsn, style_number, brand, type from batch_sale_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand), 

    ["update w_inventory set amount=amount-" ++ ?to_s(Total)
     ++ ", sell=sell+" ++ ?to_s(Total) 
     ++ ", last_sell=" ++ "\'" ++ ?to_s(Datetime) ++ "\'"
     ++ " where " ++ C1(),

     case ?sql_utils:execute(s_read, Sql00) of
	 {ok, []} ->
	     {ValidOrgPrice, ValidEDiscount} = {OrgPrice, ?w_good_sql:stock(ediscount, OrgPrice, TagPrice)},
	 
	     "insert into batch_sale_detail("
		 "rsn, style_number, brand, merchant, shop, type, sex, s_group, free"
		 ", season, firm, year, in_datetime, total"
		 ", org_price, ediscount, tag_price, fdiscount, rdiscount, fprice, rprice"
		 ", path, comment, entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		 ++ ?to_s(Brand) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Type) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		 ++ ?to_s(Free) ++ "," 
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ "\'" ++ ?to_s(InDatetime) ++ "\'," 
		 ++ ?to_s(Total) ++ ","
	 
		 ++ ?to_s(ValidOrgPrice) ++ ","
		 ++ ?to_s(ValidEDiscount) ++ ","
		 ++ ?to_s(TagPrice) ++ "," 
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(RDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ ?to_s(RPrice) ++ ","

		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
	 {ok, _} ->
	     "update batch_sale_detail set total=total+" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", rdiscount=" ++ ?to_s(RDiscount)
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", rprice=" ++ ?to_s(RPrice) 
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand);
	 {error, E00} ->
	     throw({db_error, E00})
     end] ++ 
	lists:foldr(
	  fun({struct, A}, Acc1)->
		  Color    = ?v(<<"cid">>, A),
		  Size     = ?v(<<"size">>, A), 
		  Count =
		      case Action of
			  new -> ?v(<<"sell_count">>, A);
			  reject -> -?v(<<"reject_count">>, A)
		      end,

		  Sql01 = "select rsn, style_number, brand, color, size"
		      " from batch_sale_detail_amount"
		      " where " ++ C2(Color, Size),

		  ["update w_inventory_amount set total=total-" ++ ?to_s(Count)
		   ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(Color)
		   ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   case ?sql_utils:execute(s_read, Sql01) of
		       {ok, []} ->
			   "insert into batch_sale_detail_amount(rsn"
			       ", style_number, brand, color, size"
			       ", total, merchant, shop, entry_date) values("
			       ++ "\"" ++ ?to_s(RSN) ++ "\","
			       ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			       ++ ?to_s(Brand) ++ ","
			       ++ ?to_s(Color) ++ ","
			       ++ "\"" ++ ?to_s(Size) ++ "\","
			       ++ ?to_s(Count) ++ ","
			       ++ ?to_s(Merchant) ++ ","
			       ++ ?to_s(Shop) ++ ","
			       ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		       {ok, _} ->
			   "update batch_sale_detail_amount"
			       " set total=total+" ++ ?to_s(Count)
			       ++ ", entry_date="
			       ++ "\'" ++ ?to_s(Datetime) ++ "\'"
			       ++ " where " ++ C2(Color, Size);
		       {error, E01} ->
			   throw({db_error, E01})
		   end|Acc1] 
	  end, [], Amounts).


count_table(batchsale, Merchant, Conditions) -> 
    SortConditions = sort_condition(batchsale, Merchant, Conditions), 
    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
    	", sum(a.should_pay) as t_spay"
	", sum(a.has_pay) as t_hpay"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
	", sum(a.wxin) as t_wxin"
	", sum(a.verificate) as t_veri" 
	" from batch_sale a where " ++ SortConditions, 
    CountSql.

sort_condition(batchsale, Merchant, Conditions) ->
    Comment = ?v(<<"comment">>, Conditions),
    CutConditions = lists:keydelete(<<"comment">>, 1, Conditions), 
    C = lists:foldr(
	  fun({K, V}, Acc) when K =:= <<"check_state">>->
		  [{<<"state">>, V}|Acc];
	     (KV, Acc)->
		  [KV|Acc]
	  end, [], CutConditions),

    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(fields_with_prifix, C),

    "a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions)
	++ case Comment of
	       undefined -> [];
	       0 -> " and a.comment!=\'\'";
	       1 -> []
	   end
	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end.

filter_bsale(PageFun, Merchant, Conditions) ->
    ?DEBUG("filter_batch_sale: Merchant ~p, Conditions ~p", [Merchant, Conditions]),
    SortConditions = sort_condition(batchsale, Merchant, Conditions), 
    Sql = "select a.id"
	", a.rsn"
	", a.account"
	", a.employ as employee_id"
    	", a.bsaler as bsaler_id"
	", a.shop as shop_id"

	", a.balance"
	", a.should_pay"
	", a.has_pay"
	", a.cash"
	", a.card"
	", a.wxin" 
	", a.verificate"
	", a.total"

	", a.comment"
	", a.type"
	", a.state"
	", a.entry_date"

	", b.name as bsaler"
	", b.region as region_id"
	", c.name as account"

    	" from batch_sale a" 
	" left join batchsaler b on a.bsaler=b.id"
	" left join users c on a.account=c.id"

    	" where " ++ SortConditions
	++ PageFun(), 
    Sql.

filter_bsale(batchsale_with_page, Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    ?DEBUG("batchsale_with_page:Merchant ~p, Conditions ~p, CurrentPage ~p, ItemsPerPage ~p",
	   [Merchant, Conditions, CurrentPage, ItemsPerPage]),
    %% SortConditions = sort_condition(batchsale, Merchant, Conditions),
    PageFun = fun() -> ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage) end,
    filter_bsale(PageFun, Merchant, Conditions). 
	

filter_condition(batchsale, [], Acc1, Acc2) ->
    {lists:reverse(Acc1), lists:reverse(Acc2)};
filter_condition(batchsale, [{<<"style_number">>,_} = S|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [S|Acc1], Acc2);
filter_condition(batchsale, [{<<"brand">>, _} = B|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [B|Acc1], Acc2);
filter_condition(batchsale, [{<<"firm">>, _} = F|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [F|Acc1], Acc2);
filter_condition(batchsale, [{<<"type">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [OT|Acc1], Acc2);
filter_condition(batchsale, [{<<"sex">>, _} = OT|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [OT|Acc1], Acc2);
filter_condition(batchsale, [{<<"year">>, _} = Y|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [Y|Acc1], Acc2);
filter_condition(batchsale, [{<<"season">>, _} = Y|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [Y|Acc1], Acc2);
filter_condition(batchsale, [{<<"org_price">>, OP} = _OP|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, [{<<"org_price">>, ?to_f(OP)}|Acc1], Acc2);


filter_condition(batchsale, [{<<"rsn">>, _} = R|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [R|Acc2]);
filter_condition(batchsale, [{<<"start_time">>, _} = ST|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [ST|Acc2]);
filter_condition(batchsale, [{<<"end_time">>, _} = SE|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [SE|Acc2]);
filter_condition(batchsale, [{<<"shop">>, _} = S|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [S|Acc2]);
filter_condition(batchsale, [{<<"sell_type">>, ST}|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [{<<"type">>, ST}|Acc2]);
filter_condition(batchsale, [O|T], Acc1, Acc2) ->
    filter_condition(batchsale, T, Acc1, [O|Acc2]).


sale_new(sale_new_detail, MatchMode, Merchant, Conditions, PageFun) ->
    {DConditions, SConditions} = filter_condition(batchsale, Conditions, [], []),
    {StartTime, EndTime, CutSConditions} = ?sql_utils:cut(fields_with_prifix, SConditions),

    {_, _, CutDCondtions} = ?sql_utils:cut(fields_no_prifix, DConditions), 
    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),

    "select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand_id"
	", a.type_id"
	", a.sex"
	", a.season"
	", a.firm_id"
	", a.year"
	", a.s_group"
	", a.free"
	", a.total" 
	", a.org_price"
	", a.ediscount"
	", a.tag_price"
	", a.fdiscount"
	", a.rdiscount"
	", a.fprice"
	", a.rprice"
	", a.in_datetime"
	", a.path"
	", a.comment"
	", a.entry_date"

	", a.shop_id"
	", a.bsaler_id"
	", a.employee_id"
	", a.sell_type"

	", c.name as bsaler"
    %% ", c.region as region_id"
	", d.name as brand"
	", e.name as type"

	" from ("
	"select b.id"
	", b.rsn"
	", b.style_number"
	", b.brand as brand_id"
	", b.type as type_id"
	", b.sex"
	", b.season"
	", b.firm as firm_id"
	", b.year"
	", b.s_group"
	", b.free"
	", b.total" 
	", b.org_price"
	", b.ediscount"
	", b.tag_price"
	", b.fdiscount"
	", b.rdiscount"
	", b.fprice"
	", b.rprice"
	", b.in_datetime"
	", b.path"
	", b.comment"
	", b.entry_date"

	", a.shop as shop_id"
	", a.bsaler as bsaler_id"
	", a.employ as employee_id"
	", a.type as sell_type"

    %% ", c.name as bsaler"
    %% ", d.name as brand"
    %% ", e.name as type"

    	" from batch_sale_detail b, batch_sale a"
    %% " left join batchsaler c on a.bsaler=c.id"
    %% " left join brands d on b.brand=d.id"
    %% " left join inv_types e on b.type=e.id"

    	" where "
	++ "b.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:like_condition(style_number, MatchMode, CorrectCutDConditions, <<"b.style_number">>) 
	++ " and b.rsn=a.rsn"

	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ ?sql_utils:condition(proplists, CutSConditions)
    	++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	       [] -> [];
	       TimeSql -> " and " ++ TimeSql
	   end
    	++ PageFun() ++ ") a"

	" left join batchsaler c on a.bsaler_id=c.id"
	" left join brands d on a.brand_id=d.id"
	" left join inv_types e on a.type_id=e.id".
	
sale_new(sale_new_note, Merchant, Conditions) ->
    %% ?DEBUG("Merchant ~p, Conditions ~p", [Merchant, Conditions]), 
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(fields_no_prifix, Conditions),
    "select a.rsn"
	", a.style_number"
	", a.brand as brand_id"
	", a.shop as shop_id"
	", a.color as color_id"
	", a.size"
	", a.total as amount"
	", b.name as color"

	" from (" 
	"select rsn, style_number, brand, shop, color, size, total"
	" from batch_sale_detail_amount"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, NewConditions) ++  ") a"

	" left join colors b on a.color=b.id".

type(new) -> 0;
type(reject) -> 1.

rsn_order(use_id)    -> " order by b.id ";
rsn_order(use_shop)  -> " order by a.shop ";
rsn_order(use_brand) -> " order by b.brand ";
rsn_order(use_firm)  -> " order by b.firm ".
