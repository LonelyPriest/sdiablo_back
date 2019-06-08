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
-export([bsale/3, bsale/4, bsale_prop/3, bsale_prop/4]).
-export([filter/4, filter/6, match/3, export/3]).

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
bsale(update_sale, Merchant, Inventories, {Props, OldProps}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_sale, Merchant, Inventories, Props, OldProps}); 
bsale(check, Merchant, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {check_sale, Merchant, RSN, Mode});
bsale(delete_sale, Merchant, SaleProps, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {delete_sale_new, Merchant, SaleProps, Conditions}).

bsale(get_sale, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new, Merchant, Conditions});
bsale(get_sale_new_detail, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_detail, Merchant, Conditions});
bsale(get_sale_new_note, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_note, Merchant, Conditions});
bsale(get_sale_new_transe, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_transe, Merchant, Conditions});
bsale(get_sale_rsn, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {get_sale_new_rsn, Merchant, Conditions}).

bsale_prop(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_sale_prop, Merchant, Attrs}).
bsale_prop(update, Merchant, PropId, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {update_sale_prop, Merchant, PropId, Attrs}).

filter(total_sale_new, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_sale_new, Merchant, Fields});

filter(total_sale_new_detail, MatchMode, Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_sale_new_detail, MatchMode, Merchant, Fields}, 6 * 1000);

filter(total_sale_prop, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_sale_prop, Merchant, Fields}).


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
	     {Mode, Sort}, MatchMode, Merchant, CurrentPage, ItemsPerPage, Fields}, 6 * 1000);

filter(sale_prop, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_sale_prop, Merchant, CurrentPage, ItemsPerPage, Conditions}).

match(rsn, Merchant, {ViewValue, Condition}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_rsn, Merchant, {ViewValue, Condition}});
match(sale_prop, Merchant, {Mode, Prop}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_sale_prop, Merchant, {Mode, Prop}}).

export(sale_new, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {export_sale_new, Merchant, Condition});
export(sale_new_detail, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {export_sale_new_detail, Merchant, Condition});
export(sale_new_note, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {export_sale_new_note, Merchant, Condition}).

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
    SaleProp   = ?v(<<"prop">>, Props, -1),
    
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
		", total, prop, comment, type, entry_date) values("
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
		++ ?to_s(SaleProp) ++ "," 
		++ "\"" ++ ?to_s(Comment) ++ "\"," 
		++ ?to_s(type(new)) ++ ","
		++ "\"" ++ ?to_s(DateTime) ++ "\");",

	    Sql3 = "update batchsaler set balance=balance+" ++ ?to_s(ShouldPay + Verificate - HasPay) 
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

handle_call({update_sale, Merchant, Inventories, Props, OldProps}, _From, State) ->
    ?DEBUG("update_sale with merchant ~p~n~p, props ~p, OldProps ~p", [Merchant, Inventories, Props, OldProps]), 
    Curtime    = ?utils:current_time(format_localtime), 

    RSN        = ?v(<<"rsn">>, Props),
    BSaler     = ?v(<<"bsaler">>, Props),
    Shop       = ?v(<<"shop">>, Props), 
    Datetime   = ?v(<<"datetime">>, Props, Curtime), 
    Employee   = ?v(<<"employee">>, Props),
    SaleProp   = ?v(<<"prop">>, Props),

    %% Balance    = ?v(<<"balance">>, Props),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0), 
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wxin       = ?v(<<"wxin">>, Props, 0),
    HasPay     = ?v(<<"has_pay">>, Props, 0),
    %% Verificate = ?v(<<"verificate">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props),

    Total        = ?v(<<"total">>, Props),
    
    %% RSNId        = ?v(<<"id">>, OldProps),
    OldEmployee  = ?v(<<"employee_id">>, OldProps),
    OldBSaler    = ?v(<<"bsaler_id">>, OldProps),
    OldSaleProp  = ?v(<<"prop_id">>, OldProps), 
    OldDatetime  = ?v(<<"entry_date">>, OldProps),
    
    OldCash       = ?v(<<"cash">>, OldProps),
    OldCard       = ?v(<<"card">>, OldProps),
    OldWxin       = ?v(<<"wxin">>, OldProps),
    OldShouldPay  = ?v(<<"should_pay">>, OldProps), 
    OldHasPay     = ?v(<<"has_pay">>, OldProps),
    %% OldVerificate = ?v(<<"verificate">>, OldProps, 0),
    OldComment    = ?v(<<"comment">>, OldProps),
    OldTotal       = ?v(<<"total">>, OldProps),
    %% SellType     = ?v(<<"type">>, OldProps),

    NewDatetime = case Datetime =:= OldDatetime of
		      true -> Datetime;
		      false -> ?utils:correct_datetime(datetime, Datetime)
		  end,

    Sql1 = sql(update_bsale, RSN, Merchant, Shop, NewDatetime, OldDatetime, Inventories),

    IsSame = fun(_, New, Old) when New == Old -> undefined;
		(number, New, _Old) -> New; 
		(datetime, New, _Old) -> New;
		(_, New, _Old) -> New
	     end,
    
    Updates = ?utils:v(employ, string, IsSame(string, Employee, OldEmployee))
	++ ?utils:v(bsaler, integer, IsSame(number, BSaler, OldBSaler))
	++ ?utils:v(prop, integer, IsSame(number, SaleProp, OldSaleProp))
	++ ?utils:v(should_pay, float, IsSame(number, ShouldPay, OldShouldPay)) 
	++ ?utils:v(cash, float, IsSame(number, Cash, OldCash))
	++ ?utils:v(card, float, IsSame(number, Card, OldCard))
	++ ?utils:v(wxin, float, IsSame(number, Wxin, OldWxin))
	++ ?utils:v(has_pay, float, IsSame(number, HasPay, OldHasPay))
	++ ?utils:v(total, integer, IsSame(number, Total, OldTotal))
	++ ?utils:v(comment, string, IsSame(string, Comment, OldComment))
	++ ?utils:v(entry_date, string, IsSame(datetime, NewDatetime, OldDatetime)),

    %% ?DEBUG("Updates ~p", [Updates]),

    %% OldPay = OldShouldPay + OldVerificate - OldHasPay,
    %% NewPay = ShouldPay + Verificate - HasPay,

    Sqls = Sql1 ++ 
	case BSaler =:= OldBSaler of
	    true ->
		update_sale(same_bsaler, Merchant, Updates, {Props, OldProps});
	    false ->
		update_sale(same_bsaler, Merchant, Updates, {Props, OldProps})
	end,
    Reply = ?sql_utils:execute(transaction, Sqls, RSN),
    {reply, Reply, State};

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

handle_call({delete_sale_new, Merchant, SaleProps, Conditions}, _From, State) ->
    ?DEBUG("delete_sale_new with merchant ~p, SaleProps, condition ~p", [Merchant, SaleProps, Conditions]),
    RSN = ?v(<<"rsn">>, Conditions),

    BSaler       = ?v(<<"bsaler_id">>, SaleProps),
    Datetime     = ?v(<<"entry_date">>, SaleProps),
    Verificate   = ?v(<<"verificate">>, SaleProps),
    HasPay       = ?v(<<"has_pay">>, SaleProps), 

    MBalance = HasPay - Verificate,

    Sqls = ["update batch_sale set balance=balance+" ++ ?to_s(MBalance)
	    ++ " where merchant=" ++ ?to_s(Merchant)
	    ++ " and bsaler=" ++ ?to_s(BSaler)
	    ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'",

	    "update batchsaler set balance=balance+" ++ ?to_s(MBalance)
	    ++ " where id=" ++ ?to_s(BSaler)
	    ++ " and merchant=" ++ ?to_s(Merchant),

	    "delete from batch_sale where merchant=" ++ ?to_s(Merchant)
	    ++ " and " ++ ?utils:to_sqls(proplists, Conditions)],

    Reply =  ?sql_utils:execute(transaction, Sqls, RSN),
    {reply, Reply, State};

handle_call({get_sale_new, Merchant, Conditions} , _From, State) ->
    Sql = filter_bsale(fun()-> [] end, Merchant, Conditions),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_detail, Merchant, Conditions} , _From, State) ->
    Sql = sale_new(sale_new_detail, 'and', Merchant, Conditions, fun() -> [] end), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_note, Merchant, Conditions} , _From, State) ->
    Sql = sale_new(sale_new_note, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_transe, Merchant, Conditions} , _From, State) ->
    ?DEBUG("sale_new_transe with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = "select a.rsn"
	", a.style_number"
	", a.brand_id"
	", a.type_id"
	", a.sex"
	", a.s_group"
	", a.free"
	", a.season"
	", a.firm_id"
	", a.year"
	", a.in_datetime"
	", a.total"
	", a.unit"
	
	", a.org_price"
	", a.tag_price"
	", a.vir_price"
	", a.ediscount"
	", a.fdiscount"
	", a.rdiscount"
	", a.fprice"
	", a.rprice"
	
	", a.path"
	", a.comment"

	", b.color as color_id"
	", b.size"
	", b.total as amount"

	" from "

	"(select id"
	", rsn"
	", style_number"
	", brand as brand_id"
	", type as type_id"
	", sex"
	", s_group"
	", free"
	", season"
	", firm as firm_id"
	", year"
	", in_datetime"
	", total"
	", unit"
	
	", org_price"
	", ediscount"
	", tag_price"
	", vir_price"
	", fdiscount"
	", rdiscount"
	", fprice"
	", rprice"
	
	", path"
	", comment"
	" from batch_sale_detail"
	" where " ++ ?utils:to_sqls(proplists, Conditions) ++ ") a"

	" inner join batch_sale_detail_amount b on a.rsn=b.rsn"
	" and a.style_number=b.style_number"
	" and a.brand_id=b.brand",    

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_sale_new_rsn, Merchant, Conditions} , _From, State) ->
    ?DEBUG("get_sale_rsn with merchant=~p, conditions ~p", [Merchant, Conditions]),

    {DetailConditions, SaleConditions} =
	filter_condition(batchsale, [{<<"merchant">>, Merchant}|Conditions], [], []),
    ?DEBUG("sale conditions ~p, detail condition ~p", [SaleConditions, DetailConditions]), 

    {StartTime, EndTime, CutSaleConditions} = ?sql_utils:cut(fields_with_prifix, SaleConditions),

    Sql1 = 
	"select a.rsn from batch_sale a"
	" where "
	++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
	++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    Sql = 
	case ?v(<<"rsn">>, SaleConditions, []) of
	    [] ->
		case DetailConditions of
		    [] -> Sql1;
		    _ ->
			"select a.rsn from batch_sale a "
			    "inner join (select rsn from batch_sale_detail"
			    " where rsn like "
			    ++ "\'M-" ++ ?to_s(Merchant) ++"%\'"
			    ++ ?sql_utils:condition(proplists, DetailConditions) ++ ") b"
			    " on a.rsn=b.rsn"
			    " where "
			    ++ ?sql_utils:condition(proplists_suffix, CutSaleConditions)
			    ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime) 
		end;
	    _ -> Sql1 
	end ++ " order by id desc",
    
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

handle_call({export_sale_new, Merchant, Conditions}, _From, State)->
    ?DEBUG("export_sale_new_detail: merchant ~p, condition ~p", [Merchant, Conditions]),
    Sql = filter_table(batchsale, Merchant, Conditions),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({export_sale_new_detail, Merchant, Conditions}, _From, State)->
    %% ?DEBUG("new_trans_note_export: merchant ~p\nConditions~p", [Merchant, Conditions]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions), 
    Sql = "select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand_id"
	", a.type_id"
	", a.firm_id"
	", a.bsaler_id"
	", a.season" 
	", a.year"
	", a.unit"
	", a.prop_id"
	", a.s_group"
	", a.total"
	
	", a.org_price"
	", a.tag_price"
	", a.vir_price"
	", a.rprice"
	
	", a.in_datetime" 
	", a.entry_date"
	", a.comment"
	
	", a.shop_id"
	", a.bsaler_id"
	", a.employee_id"
	", a.sell_type"

	", b.name as brand"
	", d.name as type"
	", e.name as firm"
	", f.name as shop"
	", g.name as bsaler"
	", g.region as region_id"
	", h.name as employee"
	", m.name as prop"

	" from (" 
	"select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand as brand_id"
	", a.type as type_id" 
	", a.firm as firm_id"
	", a.season" 
	", a.year"
	", a.unit"
	", a.s_group"
	", a.total" 
	
	", a.org_price"
	", a.tag_price"
	", a.vir_price"
	", a.rprice"
	
	", a.in_datetime"
	", a.entry_date"
	", a.comment"

	", b.shop as shop_id"
	", b.prop as prop_id"
	", b.bsaler as bsaler_id"
	", b.employ as employee_id"
	", b.type as sell_type"

	" from batch_sale_detail a"
	" inner join batch_sale b on a.rsn=b.rsn" 

	" where " ++ ?utils:to_sqls(proplists, CorrectCondition) ++ ") a"

	" left join brands b on a.brand_id=b.id"
	" left join inv_types d  on a.type_id=d.id"
	" left join suppliers e on a.firm_id=e.id"

	" left join shops f on a.shop_id=f.id"
	" left join batchsaler g on a.bsaler_id=g.id"
	" left join employees h on a.employee_id=h.number and h.merchant=" ++ ?to_s(Merchant)
	++ " left join batch_sale_prop m on a.prop_id=m.id"
	++ " order by a.id desc",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({export_sale_new_note, Merchant, Conditions}, _From, State)->
    Sql = "select a.id"
	", a.rsn"
	", a.style_number"
	", a.brand"
	", a.color"
	", a.size"
	", a.total"
	", a.shop" 
	", a.merchant"

	", b.name as cname"

	" from batch_sale_detail_amount a"
	" left join colors b on a.merchant=b.merchant and a.color = b.id"
	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_sale_prop, Merchant, Attrs}, _From, State)->
    ?DEBUG("new_sale_prop with props ~p", [Attrs]),
    Name      = ?v(<<"name">>, Attrs),
    Comment   = ?v(<<"comment">>, Attrs, []),
    PY        = ?v(<<"py">>, Attrs, []),
    Datetime  = ?utils:current_time(localdate),

    %% name can not be same
    Sql = "select id, name from batch_sale_prop  where merchant=" ++ ?to_s(Merchant)
	++ " and name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into batch_sale_prop"
		++ "(merchant, name, py, comment, entry)"
		++ " values ("
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(PY) ++ "\'," 
		++ "\'" ++ ?to_s(Comment) ++ "\'," 
		++ "\"" ++ ?to_s(Datetime) ++ "\")", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(batch_sale_prop_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_sale_prop, Merchant, PropId, Attrs}, _From, State) ->
    ?DEBUG("update_sale_prop with merchant ~p, PropId ~p, Attrs ~p", [Merchant, PropId, Attrs]), 
    Name    = ?v(<<"name">>, Attrs),
    PY      = ?v(<<"py">>, Attrs),
    Comment = ?v(<<"comment">>, Attrs),

    Updates = ?utils:v(name, string, Name)
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(py, string, PY),

    Sql = "update batch_sale_prop set "
	++ ?utils:to_sqls(proplists, comma, Updates)
	++ " where id=" ++ ?to_s(PropId)
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = 
	case Name of
	    undefined ->
		?sql_utils:execute(write, Sql, PropId);
	    _ ->
		Sql1 = "select id, name from batch_sale_prop  where merchant=" ++ ?to_s(Merchant)
		    ++ " and name=" ++ "\'" ++ ?to_string(Name) ++ "\'"
		    ++ " and deleted=" ++ ?to_s(?NO), 
		case ?sql_utils:execute(s_read, Sql1) of
		    {ok, []} ->
			?sql_utils:execute(write, Sql, PropId);
		    _ ->
			{error, ?err(batch_sale_prop_exist, Name)}
		end
	end, 
    {reply, Reply, State};

handle_call({match_sale_prop, Merchant, {Mode, Prop}}, _From, State) ->
    ?DEBUG("match_sale_prop: merchant ~p, mode ~p, prop ~p", [Merchant, Mode, Prop]),
    First = string:substr(?to_s(Prop), 1, 1),
    Last  = string:substr(?to_s(Prop), string:len(?to_s(Prop))),
    Match = string:strip(?to_s(Prop), both, $/),

    Name = case Mode of
	       1 -> "py";
	       2 -> "name"
	   end,

    Sql = "select id, name, py, merchant from batch_sale_prop" 
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and "
	++ case {First, Match, Last} of
	       {"/", Match, "/"} ->
		   Name ++ " =\'" ++ Match ++ "\'"; 
	       {"/", Match, _} ->
		   Name ++ " like \'" ++ Match ++ "%\'";
	       {_, Match, "/"} ->
		   Name ++ " like \'%" ++ Match ++ "\'";
	       {_, Match, _}->
		   Name ++ " like \'%" ++ Match ++ "%\'"
	   end
	++ " limit 20",

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({total_sale_prop, Merchant, _Fields}, _From, State) ->
    CountSql = "select count(*) as total from batch_sale_prop"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=0",
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};

handle_call({filter_sale_prop, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_sale_prop: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n fields ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = "select id, name, comment, entry from batch_sale_prop where merchant=" ++ ?to_s(Merchant)
	++ " and deleted=0"
	++ ?sql_utils:condition(page_desc, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
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
sql(update_bsale, RSN, _Merchant, _Shop, NewDatetime, OldDatetime, []) ->
    case NewDatetime =:= OldDatetime of
	true -> [];
	false ->
	    ["update batch_sale_detail set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",
	     "update batch_sale_detail_amount set entry_date=\'"
	     ++ ?to_s(NewDatetime) ++ "\'"
	     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"]
    end;

sql(update_bsale, RSN, Merchant, Shop, NewDatetime, _OldDatetime, Inventories) -> 
    lists:foldr(
      fun({struct, Inv}, Acc0)-> 
	      Operation   = ?v(<<"operation">>, Inv), 
	      case Operation of
		  <<"d">> ->
		      Amounts = ?v(<<"amount">>, Inv),
		      bsale(delete, RSN, NewDatetime, Merchant, Shop, Inv, Amounts) ++ Acc0; 
		  <<"a">> ->
		      Amounts = ?v(<<"amount">>, Inv), 
		      bsale(new, RSN, NewDatetime, Merchant, Shop, Inv, Amounts) ++ Acc0; 
		  <<"u">> -> 
		      bsale(update, RSN, NewDatetime, Merchant, Shop, Inv) ++ Acc0
	      end
      end, [], Inventories).

bsale(update, RSN, Datetime, Merchant, Shop, Inventory) -> 
    StyleNumber    = ?v(<<"style_number">>, Inventory),
    Brand          = ?v(<<"brand">>, Inventory),
    OrgPrice       = ?v(<<"org_price">>, Inventory),
    FPrice         = ?v(<<"fprice">>, Inventory),
    RPrice         = ?v(<<"rprice">>, Inventory),
    FDiscount      = ?v(<<"fdiscount">>, Inventory),
    RDiscount      = ?v(<<"rdiscount">>, Inventory),
    Comment        = ?v(<<"comment">>, Inventory, []),

    ChangeAmounts  = ?v(<<"changed_amount">>, Inventory, []),

    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       Count = ?v(<<"count">>, Attr),
			       case ?v(<<"operation">>, Attr) of
				   <<"d">> -> Acc - Count;
				   <<"a">> -> Acc + Count;
				   <<"u">> -> Acc + Count
			       end
		       end, 0, ChangeAmounts)
	     end(),

    ?DEBUG("metric ~p", [Metric]),

    C1 =
	fun(Color, Size) ->
		?utils:to_sqls(proplists,
			       [{<<"style_number">>, StyleNumber},
				{<<"brand">>, Brand},
				{<<"color">>, Color},
				{<<"size">>,  Size},
				{<<"shop">>,  Shop},
				{<<"merchant">>, Merchant}])
	end,

    C2 =
	fun(Color, Size) ->
		?utils:to_sqls(
		   proplists, [{<<"rsn">>, ?to_b(RSN)},
			       {<<"style_number">>, StyleNumber},
			       {<<"brand">>, Brand},
			       {<<"color">>, Color},
			       {<<"size">>, Size}])
	end,


    Sql0 = 
	case Metric of
	    0 -> ["update batch_sale_detail set "
		  ++ "org_price=" ++ ?to_s(OrgPrice)
		  ++ ", fdiscount=" ++ ?to_s(FDiscount)
		  ++ ", rdiscount=" ++ ?to_s(RDiscount) 
		  ++ ", fprice=" ++ ?to_s(FPrice)
		  ++ ", rprice=" ++ ?to_s(RPrice)
		  ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		  ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
		  ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		  ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		  ++ " and brand=" ++ ?to_s(Brand)];
	    Metric -> 
		["update w_inventory set amount=amount-" ++ ?to_s(Metric)
		 ++ ", sell=sell+" ++ ?to_s(Metric)
		 ++ " where "
		 "style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)
		 ++ " and shop=" ++ ?to_s(Shop)
		 ++ " and merchant=" ++ ?to_s(Merchant),

		 "update batch_sale_detail set total=total+" ++ ?to_s(Metric)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", rdiscount=" ++ ?to_s(RDiscount) 
		 ++ ", fprice=" ++ ?to_s(FPrice)
		 ++ ", rprice=" ++ ?to_s(RPrice)
		 ++ ", comment=\'" ++ ?to_s(Comment) ++ "\'"
		 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
		 ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		 ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		 ++ " and brand=" ++ ?to_s(Brand)]
	end,

    ChangeFun =
	fun({struct, Attr}, Acc1) ->
		?DEBUG("Attr ~p", [Attr]),
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr),

		case ?v(<<"operation">>, Attr) of 
		    <<"a">> ->
			Sql01 = "select id, style_number, brand, color, size"
			    " from batch_sale_detail_amount where " ++ C2(Color, Size),

			["update w_inventory_amount set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 case ?sql_utils:execute(s_read, Sql01) of
			     {ok, []} ->
				 "insert into batch_sale_detail_amount(rsn"
				     ", style_number, brand, "
				     "color, size, total, entry_date) values("
				     ++ "\"" ++ ?to_s(RSN) ++ "\","
				     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
				     ++ ?to_s(Brand) ++ ","
				     ++ ?to_s(Color) ++ ","
				     ++ "\'" ++ ?to_s(Size)  ++ "\',"
				     ++ ?to_s(Count) ++ "," 
				     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
			     {ok, _} ->
				 "update batch_sale_detail_amount"
				     " set total=total+" ++ ?to_s(Count)
				     ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
				     ++ " where " ++ C2(Color, Size);
			     {error, E00} ->
				 throw({db_error, E00})
			 end | Acc1];

		    <<"d">> -> 
			["update w_inventory_amount set total=total+"
			 ++ ?to_s(Count) ++ " where " ++ C1(Color, Size), 

			 "delete from batch_sale_detail_amount"
			 " where " ++ C2(Color, Size)
			 | Acc1];
		    <<"u">> -> 
			["update w_inventory_amount"
			 " set total=total-" ++ ?to_s(Count)
			 ++ " where " ++ C1(Color, Size),

			 " update batch_sale_detail_amount"
			 " set total=total+" ++ ?to_s(Count)
			 ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
			 ++ " where " ++ C2(Color, Size)|Acc1]
		end
	end,
    Sql0 ++ lists:foldr(ChangeFun, [], ChangeAmounts). 

bsale(delete, RSN, _DateTime, Merchant, Shop, Inventory, Amounts)
  when is_list(Amounts)-> 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory), 

    Metric = fun()->
		     lists:foldl(
		       fun({struct, Attr}, Acc) ->
			       ?v(<<"sell_count">>, Attr) + Acc
		       end, 0, Amounts)
	     end(),

    ["update w_inventory set amount=amount+" ++ ?to_s(Metric)
     ++ ",sell=sell-" ++ ?to_s(Metric) 
     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)
     ++ " and shop=" ++ ?to_s(Shop)
     ++ " and merchant=" ++ ?to_s(Merchant),

     "delete from batch_sale_detail"
     ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
     ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
     ++ " and brand=" ++ ?to_s(Brand)]
	++ 
        lists:foldr(
	  fun({struct, Attr}, Acc1)->
		  CId    = ?v(<<"cid">>, Attr),
		  Size   = ?v(<<"size">>, Attr),
		  Count  = ?v(<<"sell_count">>, Attr),
		  ["update w_inventory_amount set total=total+" ++ ?to_s(Count)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand) 
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant),

		   "delete from batch_sale_detail_amount"
		   " where rsn=\"" ++ ?to_s(RSN) ++ "\""
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and color=" ++ ?to_s(CId)
		   ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
		   | Acc1]
	  end, [], Amounts);

bsale(Action, RSN, Datetime, Merchant, Shop, Inventory, Amounts) -> 
    ?DEBUG("batch_sale ~p with inv ~p, amounts ~p", [Action, Inventory, Amounts]), 
    StyleNumber = ?v(<<"style_number">>, Inventory),
    Brand       = ?v(<<"brand">>, Inventory),
    Type        = ?v(<<"type">>, Inventory),
    Sex         = ?v(<<"sex">>, Inventory),

    OrgPrice    = ?v(<<"org_price">>, Inventory),
    TagPrice    = ?v(<<"tag_price">>, Inventory),
    VirPrice    = ?v(<<"vir_price">>, Inventory),
    FDiscount   = ?v(<<"fdiscount">>, Inventory),
    FPrice      = ?v(<<"fprice">>, Inventory), 
    RDiscount   = ?v(<<"rdiscount">>, Inventory),
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
    Unit        = ?v(<<"unit">>, Inventory, 0),
    %% SaleProp    = ?v(<<"prop">>, Inventory, -1),

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
		 "rsn"
		 ", style_number"
		 ", brand"
		 ", merchant"
		 ", shop"
		 ", type"
		 ", sex"
		 ", s_group"
		 ", free"
		 ", season"
		 ", firm"
		 ", year"
		 ", in_datetime"
		 ", total"
		 ", unit"
	     %% ", prop"
		 ", org_price"
		 ", ediscount"
		 ", tag_price"
		 ", vir_price"
		 ", fdiscount"
		 ", fprice"
		 ", rdiscount"
		 ", rprice"
		 ", path"
		 ", comment"
		 ", entry_date) values("
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
		 ++ ?to_s(Unit) ++ ","
	     %%  ++ ?to_s(SaleProp) ++ ","

		 ++ ?to_s(ValidOrgPrice) ++ ","
		 ++ ?to_s(ValidEDiscount) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(VirPrice) ++ "," 
		 ++ ?to_s(FDiscount) ++ ","
		 ++ ?to_s(FPrice) ++ ","
		 ++ ?to_s(RDiscount) ++ "," 
		 ++ ?to_s(RPrice) ++ ","

		 ++ "\"" ++ ?to_s(Path) ++ "\","
		 ++ "\"" ++ ?to_s(Comment) ++ "\","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
	 {ok, _} ->
	     "update batch_sale_detail set total=total+" ++ ?to_s(Total)
		 ++ ", org_price=" ++ ?to_s(OrgPrice)
		 ++ ", tag_price=" ++ ?to_s(TagPrice)
		 ++ ", fdiscount=" ++ ?to_s(FDiscount)
		 ++ ", fprice=" ++ ?to_s(FPrice) 
	     %% ++ ", rdiscount=" ++ ?to_s(RDiscount)
	     %% ++ ", rprice=" ++ ?to_s(RPrice) 
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
	", a.prop as prop_id"
	", a.state"
	", a.entry_date"

	", b.name as bsaler"
	", b.type as bsaler_type"
	", b.region as region_id"
	", c.name as account"
	", d.name as prop"

    	" from batch_sale a" 
	" left join batchsaler b on a.bsaler=b.id"
	" left join users c on a.account=c.id"
	" left join batch_sale_prop d on a.prop=d.id"

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
	", a.unit"
	", a.prop_id"
	
	", a.org_price"
	", a.ediscount"
	", a.tag_price"
	", a.vir_price"
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
	", f.name as prop"

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
	", b.unit"
    %% ", b.prop as prop_id"
	
	", b.org_price"
	", b.ediscount"
	", b.tag_price"
	", b.vir_price"
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
	", a.prop as prop_id"

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
	" left join inv_types e on a.type_id=e.id"
	" left join batch_sale_prop f on a.prop_id=f.id"
	.
	
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


update_sale(same_bsaler, Merchant, Updates, {Props, OldProps})->
    RSN        = ?v(<<"rsn">>, Props),
    %% Shop        = ?v(<<"shop_id">>, OldProps),

    ShouldPay   = ?v(<<"should_pay">>, Props),
    HasPay      = ?v(<<"has_pay">>, Props, 0),
    Verificate  = ?v(<<"verificate">>, Props, 0),
    
    OldShouldPay  = ?v(<<"should_pay">>, OldProps),
    OldHasPay     = ?v(<<"has_pay">>, OldProps),
    OldVerificate = ?v(<<"verificate">>, OldProps),
    
    Datetime     = ?v(<<"datetime">>, Props),
    OldDatetime  = ?v(<<"entry_date">>, OldProps),

    BSaler       = ?v(<<"bsaler">>, Props),
    %% OldFirm    = ?v(<<"firm_id">>, OldProps),

    Mbalance = (ShouldPay + Verificate - HasPay) - (OldShouldPay + OldVerificate - OldHasPay),

    Sql0 = "select id, name, balance  from batchsaler where id=" ++ ?to_s(BSaler)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO),

    {ok, QBSaler} = ?sql_utils:execute(s_read, Sql0),
    BSalerCurBalance = ?v(<<"balance">>, QBSaler),

    case ?to_b(Datetime) == ?to_b(OldDatetime) of
	true ->
	    case Updates of
		[] -> [];
		_ -> ["update batch_sale set " ++ ?utils:to_sqls(proplists, comma, Updates)
		      ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"]
	    end ++ 
		case Mbalance == 0 of
		    true -> [] ;
		    false -> 
			["update batch_sale set balance=balance+"
			 ++ ?to_s(Mbalance)
			 ++ " where merchant=" ++ ?to_s(Merchant)
			 ++ " and bsaler=" ++ ?to_s(BSaler)
			 ++ " and entry_date>\'" ++ ?to_s(OldDatetime) ++ "\'",
			 
			 "update batchsaler set balance=balance+" ++ ?to_s(Mbalance) 
			 ++ " where id=" ++ ?to_s(BSaler)
			 ++ " and merchant=" ++ ?to_s(Merchant)]
		end;
	false ->
	    Sql = "select id, rsn, bsaler, shop, merchant, balance, should_pay, has_pay"
		", verificate, entry_date"
		" from batch_sale"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and bsaler=" ++ ?to_s(BSaler)
		++ " and state in(0, 1)"
		++ " and entry_date<\'" ++ ?to_s(Datetime) ++ "\'"
		++ " order by entry_date desc limit 1", 
	    {ok, LastSaleIn} = ?sql_utils:execute(s_read, Sql), 
	    LastBalance
		= case LastSaleIn of
		      [] ->
			  Sql01 = "select id, rsn, bsaler, shop, merchant"
			      ", balance, should_pay, has_pay, verificate, entry_date"
			      " from batch_sale"
			      " where merchant=" ++ ?to_s(Merchant)
			      ++ " and bsaler=" ++ ?to_s(BSaler)
			      ++ " and state in(0, 1)"
			      ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"
			      ++ " order by entry_date limit 1",
			  {ok, LastSaleInW} = ?sql_utils:execute(s_read, Sql01),
			  case LastSaleInW of
			      [] -> BSalerCurBalance;
			      _ -> ?v(<<"balance">>, LastSaleInW, 0)
			  end;
		      _  -> ?v(<<"balance">>, LastSaleIn)
				+ ?v(<<"should_pay">>, LastSaleIn)
				+ ?v(<<"verificate">>, LastSaleIn) 
				- ?v(<<"has_pay">>, LastSaleIn)
		  end,

	    ?DEBUG("LastBalance ~p", [LastBalance]),
	    OldBackBalance = OldShouldPay + OldVerificate - OldHasPay,
	    NewPayBalance = ShouldPay + Verificate - HasPay,

	    UpdateSale = 
		case ?to_b(Datetime) > ?to_b(OldDatetime) of
		    true ->
			Updates ++ ?utils:v(balance, float, LastBalance - OldBackBalance);
		    false ->
			Updates ++ ?utils:v(balance, float, LastBalance)
		end,

	    ["update batch_sale set balance=balance-" ++ ?to_s(OldBackBalance)
	     ++ " where merchant=" ++ ?to_s(Merchant)
	     ++ " and bsaler=" ++ ?to_s(BSaler)
	     ++ " and entry_date>\'" ++ ?to_s(OldDatetime) ++ "\'",

	     "update batch_sale set balance=balance+" ++ ?to_s(NewPayBalance)
	     ++ " where merchant=" ++ ?to_s(Merchant)
	     ++ " and bsaler=" ++ ?to_s(BSaler)
	     ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'",

	     "update batch_sale set " ++ ?utils:to_sqls(proplists, comma, UpdateSale)
	     ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"]

		++ case Mbalance == 0 of
		       true -> [];
		       false -> 
			   ["update batchsaler set balance=balance+" ++ ?to_s(Mbalance) 
			    ++ " where id=" ++ ?to_s(BSaler)
			    ++ " and merchant=" ++ ?to_s(Merchant)]
		   end
    end;

update_sale(diff_bsaler, Merchant, Updates, {Props, OldProps}) ->
    RSN        = ?v(<<"rsn">>, Props),
    %% Shop      = ?v(<<"shop_id">>, OldProps),

    ShouldPay  = ?v(<<"should_pay">>, Props),
    HasPay     = ?v(<<"has_pay">>, Props, 0),
    Verificate  = ?v(<<"verificate">>, Props, 0),
    
    OldShouldPay = ?v(<<"should_pay">>, OldProps),
    OldHasPay    = ?v(<<"has_pay">>, OldProps),
    OldVerificate = ?v(<<"verificate">>, OldProps),
    
    Datetime   = ?v(<<"datetime">>, Props),
    OldDatetime  = ?v(<<"entry_date">>, OldProps),

    BSaler       = ?v(<<"bsaler">>, Props),
    OldBSaler    = ?v(<<"bsaler_id">>, OldProps),

    BackBalanceOfOld = OldShouldPay + OldVerificate - OldHasPay,
    PayBalanceOfNew = ShouldPay + HasPay - Verificate,

    Sql0 = "select id, name, balance  from batchsaler where id=" ++ ?to_s(BSaler)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO), 
    {ok, Q0BSaler} = ?sql_utils:execute(s_read, Sql0),
    NewBSalerCurBalance = ?v(<<"balance">>, Q0BSaler),

    %% Sql01 = "select id, name, balance  from batchsaler where id=" ++ ?to_s(BSaler)
    %% 	++ " and merchant=" ++ ?to_s(Merchant)
    %% 	++ " and deleted=" ++ ?to_s(?NO), 
    %% {ok, Q1BSaler} = ?sql_utils:execute(s_read, Sql01),
    %% OldBSalerCurBalance = ?v(<<"balance">>, Q1BSaler),
    
    
    Sql = "select id, rsn, bsaler, shop, merchant"
	", balance, should_pay, has_pay, verificate, entry_date"
	" from batch_sale"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and bsaler=" ++ ?to_s(BSaler)
	++ " and state in(0, 1)"
	++ " and entry_date<\'" ++ ?to_s(Datetime) ++ "\'"
	++ " order by entry_date desc limit 1",

    {ok, LastStockIn} = ?sql_utils:execute(s_read, Sql),

    LastBalance =
	case LastStockIn of
	    [] ->
		Sql01 = "select id, rsn, bsaler, shop, merchant"
		    ", balance, should_pay, has_pay, verificate"
		    ", entry_date"
		    " from batch_sale"
		    " where merchant=" ++ ?to_s(Merchant)
		    ++ " and bsaler=" ++ ?to_s(BSaler)
		    ++ " and state in(0, 1)"
		    ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'"
		    ++ " order by entry_date limit 1",
		{ok, LastStockInW} = ?sql_utils:execute(s_read, Sql01),
		case LastStockInW of
		    [] -> NewBSalerCurBalance;
		    _  ->?v(<<"balance">>, LastStockInW, 0)
		end; 
	    _  -> ?v(<<"balance">>, LastStockIn)
		      + ?v(<<"should_pay">>, LastStockIn)
		      + ?v(<<"verificate">>, LastStockIn)
		      - ?v(<<"has_pay">>, LastStockIn)
		     
	end,

    UpdateStock = Updates ++ ?utils:v(balance, float, LastBalance), 
    ["update batch_sale set " "balance=balance-" ++ ?to_s(BackBalanceOfOld)
     ++ " where merchant=" ++ ?to_s(Merchant)
     ++ " and firm=" ++ ?to_s(OldBSaler)
     ++ " and entry_date>\'" ++ ?to_s(OldDatetime) ++ "\'",

     "update batchsaler set balance=balance-" ++ ?to_s(BackBalanceOfOld)
     ++ " where id=" ++ ?to_s(OldBSaler)
     ++ " and merchant=" ++ ?to_s(Merchant)]
	
	++
	
	["update batch_sale set balance=balance+" ++ ?to_s(PayBalanceOfNew)
	 ++ " where merchant=" ++ ?to_s(Merchant)
	 ++ " and bsaler=" ++ ?to_s(BSaler)
	 ++ " and entry_date>\'" ++ ?to_s(Datetime) ++ "\'",

	 "update batch_sale set "
	 ++ ?utils:to_sqls(proplists, comma, UpdateStock)
	 ++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'",

	 "update batchsaler set balance=balance+" ++ ?to_s(PayBalanceOfNew)
	 ++ " where id=" ++ ?to_s(BSaler)
	 ++ " and merchant=" ++ ?to_s(Merchant)].


filter_table(batchsale, Merchant, Conditions) ->
    SortConditions = sort_condition(batchsale, Merchant, Conditions),

    Sql = "select a.id, a.rsn"
	", a.employ as employee_id"
	", a.bsaler as bsaler_id"
	", a.shop as shop_id"
	", a.prop as prop_id"

	", a.balance, a.should_pay, a.has_pay, a.cash, a.card, a.wxin, a.verificate, a.total" 
	", a.comment, a.type, a.entry_date"

	", b.name as shop"
	", c.name as employee"
	", d.name as retailer"
	", e.name as prop"

	" from batch_sale a"
	++ " left join shops b on a.shop=b.id"
	++ " left join employees c on a.employ=c.number and c.merchant=" ++ ?to_s(Merchant)
	++ " left join batchsaler d on a.bsaler=d.id"
	++ " left join batch_sale_prop e on a.prop=e.id"
	" where " ++ SortConditions ++ " order by a.id desc",
    Sql.

type(new) -> 0;
type(reject) -> 1.

rsn_order(use_id)    -> " order by b.id ";
rsn_order(use_shop)  -> " order by a.shop ";
rsn_order(use_brand) -> " order by b.brand ";
rsn_order(use_firm)  -> " order by b.firm ".
