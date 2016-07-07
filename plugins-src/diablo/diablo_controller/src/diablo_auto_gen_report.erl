%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2016, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  5 Jul 2016 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_auto_gen_report).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).
-export([lookup/1, report/2, cancel_report/1, task/3, add/3]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {merchant :: [],
		task_of_per_shop :: []}).

%%%===================================================================
%%% API
%%%===================================================================
lookup(state) ->
    gen_server:call(?SERVER, lookup_state).

report(stastic_per_shop, TriggerTime) ->
    gen_server:cast(?SERVER, {stastic_per_shop, TriggerTime}).

cancel_report(stastic_per_shop) ->
    gen_server:cast(?SERVER, cancel_stastic_per_shop).

add(report_task, Merchant, TriggerTime) ->
    gen_server:call(?SERVER, {add_report_task, Merchant, TriggerTime}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
    Sql = "select id, name from merchants order by id", 
    case ?sql_utils:execute(read, Sql) of
	{ok, Merchants} ->
	    L = lists:foldr(
		  fun({Merchant}, Acc) ->
			  [?v(<<"id">>, Merchant)|Acc]
		  end, [], Merchants),
	    ?INFO("start cron task to genarate report ....~n", []),
	    {ok, #state{merchant=L, task_of_per_shop=[]}};
	{error, _Error} ->
	    {ok, #state{}}
    end.

handle_call({add_report_task, Merchant, TriggerTime},
	    _From, #state{merchant=Merchants, task_of_per_shop=Tasks} = State) ->
    case lists:member(Merchant, Merchants) of
	true -> {reply, ok, State};
	false ->
	    CronTask = {{daily, TriggerTime},
			fun(_Ref, Datetime) ->
				task(stastic_per_shop, Datetime, Merchant)
			end},
	    NewTask = ?cron:cron(CronTask),
	    {reply, ok, #state{merchant=[Merchant|Merchants],
			       task_of_per_shop=[NewTask|Tasks]}}
    end;
    
handle_call(lookup_state, _From, #state{merchant=Merchants,
					task_of_per_shop=Tasks} = State) ->
    {reply, {Merchants, Tasks}, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({stastic_per_shop, TriggerTime}, #state{merchant=Merchants,
				     task_of_per_shop=Tasks} = State) ->
    ?DEBUG("stastic_per_shop ~p", [TriggerTime]),
    case Tasks of
	[] -> 
	    NewTasks = 
		lists:foldr(
		  fun(M, Acc) ->
			  CronTask = {{daily, TriggerTime},
				      fun(_Ref, Datetime) ->
					      task(stastic_per_shop, Datetime, M)
				      end}, 
			  [?cron:cron(CronTask)|Acc] 
		  end, [], Merchants),
	    ?DEBUG("new tasks ~p with merchants ~p", [NewTasks, Merchants]),
	    {noreply, #state{merchant=Merchants, task_of_per_shop=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast(cancel_stastic_per_shop, #state{merchant=Merchants,
					    task_of_per_shop=Tasks} = _State) ->
    ?DEBUG("cancel_stastic_per_shop", []),
    lists:foreach(
      fun(Task) ->
	      ?cron:cancel(Task)
      end, Tasks),
    {noreply, #state{merchant=Merchants, task_of_per_shop=[]}};

handle_cast(_Msg, State) ->
    %% ?DEBUG("handle_cast receive unkown message ~p", [_Msg]),
    {noreply, State}.

handle_info(_Info, State) ->
    %% ?DEBUG("handle_info receive unkown message ~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


task(stastic_per_shop, Datetime, Merchants) when is_list(Merchants)->
    {YestodayStart, YestodayEnd} = yestoday(Datetime),
    FormatDatetime = format_datetime(Datetime),

    SqlsOfAllMerchant=
	gen_report(stastic_per_shop,
		   {YestodayStart, YestodayEnd, FormatDatetime}, Merchants), 
    ?DEBUG("SqlsOfAllMerchant ~p", [SqlsOfAllMerchant]),
    
    lists:foreach(
      fun({_M, Sqls}) ->
	      lists:foreach(
		fun(Sql)->
			case ?sql_utils:execute(insert, Sql) of
			    {ok, _} -> ok;
			    {error, Error} ->
				?WARN("sql error to create daily report: ~p", [Error])
			end
		end, Sqls)
      end, SqlsOfAllMerchant);
task(stastic_per_shop, Datetime, Merchant) when is_number(Merchant)->
    task(stastic_per_shop, Datetime, [Merchant]).

gen_report(stastic_per_shop, Datetime, Merchants) ->
    gen_report(stastic_per_shop, Datetime, Merchants, []).
    
gen_report(stastic_per_shop, _Datetime, [], Acc) ->
    Acc;
gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , [M|Merchants], Acc) ->
    {ok, Shops} = ?w_user_profile:get(shop, M),
    ?DEBUG("merchant ~p with shops ~p",
	   [M, lists:foldr(fun({Shop}, Acc1)-> [?v(<<"id">>, Shop)|Acc1] end, [], Shops)]),
    {M, Sqls} = gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, []),
    gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , Merchants, [{M, Sqls}|Acc]).

gen_shop_report(_Datetime, M, [], Sqls) ->
    ?DEBUG("merchant ~p gen sql ~p", [M, Sqls]),
    {M, Sqls};
gen_shop_report({StartTime, EndTime, GenDatetime}, M, [S|Shops], Sqls) ->
    ShopId  = ?v(<<"id">>, S),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, M, ShopId), 
    IsShopDailyReport = ?v(<<"d_report">>, BaseSetting, 1),
    
    case IsShopDailyReport of
	1 -> 
	    Conditions = [{<<"shop">>, ShopId},
			  {<<"start_time">>, ?to_b(StartTime)},
			  {<<"end_time">>, ?to_b(EndTime)}],

	    {ok, SaleInfo} = ?w_report:stastic(stock_sale, M, Conditions),
	    {ok, SaleProfit} = ?w_report:stastic(stock_profit, M, Conditions),

	    {ok, StockIn}  = ?w_report:stastic(stock_in, M, Conditions),
	    {ok, StockOut} = ?w_report:stastic(stock_out, M, Conditions),

	    {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, M, Conditions),
	    {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, M, Conditions),

	    {ok, StockFix} = ?w_report:stastic(stock_fix, M, Conditions),

	    {ok, StockR} = ?w_report:stastic(
			      stock_real, M,
			      [{<<"shop">>, ShopId},
			       {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}
			      ]),

	    {SellTotal, SellBalance, SellCash, SellCard, SellVeri} = sell(info, SaleInfo),
	    {SellCost} = sell(cost, SaleProfit),

	    {CurrentStockTotal, CurrentStockCost} = stock(current, StockR), 
	    {StockInTotal, StockInCost} = stock(in, StockIn),
	    {StockOutTotal, StockOutCost} = stock(out, StockOut),

	    {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
	    {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
	    {StockFixTotal, StockFixCost} = stock(fix, StockFix),

	    case SellTotal == 0
		andalso StockInTotal == 0
		andalso StockOutTotal == 0
		andalso StockTransferInTotal == 0
		andalso StockTransferOutTotal == 0
		andalso StockFixTotal == 0 of
		true ->
		    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls);
		false ->
		    Sql = 
			"insert into w_daily_report(merchant, shop"
			", sell, sell_cost, balance, cash, card, veri"
			", stock, stock_cost"
			", stock_in, stock_out, stock_in_cost, stock_out_cost"
			", t_stock_in, t_stock_out, t_stock_in_cost, t_stock_out_cost"
			", stock_fix, stock_fix_cost"
			", day, entry_date) values("
			++ ?to_s(M) ++ ","
			++ ?to_s(ShopId) ++ ","

			++ ?to_s(SellTotal) ++ ","
			++ ?to_s(SellCost) ++ ","
			++ ?to_s(SellBalance) ++ ","
			++ ?to_s(SellCash) ++ ","
			++ ?to_s(SellCard) ++ ","
			++ ?to_s(SellVeri) ++ ","

			++ ?to_s(CurrentStockTotal) ++ ","
			++ ?to_s(CurrentStockCost) ++ ","

			++ ?to_s(StockInTotal) ++ ","
			++ ?to_s(StockOutTotal) ++ ","
			++ ?to_s(StockInCost) ++ ","
			++ ?to_s(StockOutCost) ++ ","

			++ ?to_s(StockTransferInTotal) ++ ","
			++ ?to_s(StockTransferOutTotal) ++ ","
			++ ?to_s(StockTransferInCost) ++ ","
			++ ?to_s(StockTransferOutCost) ++ ","

			++ ?to_s(StockFixTotal) ++ ","
			++ ?to_s(StockFixCost) ++ ","

			++ "\'" ++ StartTime ++ "\',"
			++ "\'" ++ GenDatetime ++ "\')", 
		    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, [Sql|Sqls])
	    end;
	0 ->
	    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls)
    end.
    

format_datetime({{Year, Month, Day}, {Hour, Minute, Second}}) ->
    lists:flatten(
      io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
		    [Year, Month, Day, Hour, Minute, Second])).


-spec yestoday/1 :: (calender:datetime()) -> calender:datetime(). 
yestoday(Datetime) ->
    SecondsOfYestoday = calendar:datetime_to_gregorian_seconds(Datetime) - ?ONE_DAY,
    {{Year, Month, Day}, _} = calendar:gregorian_seconds_to_datetime(SecondsOfYestoday),
    {Hour, Minute, Second} = calendar:seconds_to_time(86399),

    Start = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Day])),

    End = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Day, Hour, Minute, Second])),
    {Start, End}.



sell(info, [])->
    {0, 0, 0, 0, 0};
sell(info, [{SaleInfo}])->
    {?v(<<"total">>, SaleInfo, 0),
     ?v(<<"spay">>, SaleInfo, 0),
     ?v(<<"cash">>, SaleInfo, 0),
     ?v(<<"card">>, SaleInfo, 0),
     ?v(<<"veri">>, SaleInfo, 0)
    };

sell(cost, []) ->
    {0};
sell(cost, [{SaleProfit}]) ->
    {?v(<<"org_price">>, SaleProfit)}.

stock(current, []) ->
    {0, 0};
stock(current, [{StockCurrent}]) ->
    {?v(<<"total">>, StockCurrent, 0),
     ?v(<<"cost">>, StockCurrent, 0)};

stock(in, []) ->
    {0, 0};
stock(in, [{StockIn}]) ->
    {?v(<<"total">>, StockIn, 0),
     ?v(<<"cost">>, StockIn, 0)};
stock(out, []) ->
    {0, 0};
stock(out, [{StockOut}]) ->
    {?v(<<"total">>, StockOut, 0),
     ?v(<<"cost">>, StockOut, 0)};

stock(t_in, []) ->
    {0, 0};
stock(t_in, [{StockTIn}]) ->
    {?v(<<"total">>, StockTIn, 0),
     ?v(<<"cost">>, StockTIn, 0)};
stock(t_out, []) ->
    {0, 0};
stock(t_out, [{StockTOut}]) ->
    {?v(<<"total">>, StockTOut, 0),
     ?v(<<"cost">>, StockTOut, 0)};

stock(fix, []) ->
    {0, 0};
stock(fix, [{StockFix}]) ->
    {?v(<<"total">>, StockFix, 0),
     ?v(<<"cost">>, StockFix, 0)}.



