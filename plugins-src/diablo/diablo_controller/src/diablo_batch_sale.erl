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
-export([bsale/4]).

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
    gen_server:call(Name, {new_sale, Merchant, Inventories, Props}).

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

type(new) -> 0;
type(reject) -> 1.
