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
-export([lookup/1,
	 report/2, cancel_report/1, task/3, add/3,
	 ticket/2, cancel_ticket/1,
	 birth/2, birth/1,
	 retailer_level/2, retailer_level/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([syn_report/3, sys_vip_of/2, syn_ticket/2]).
-export([syn_stastic_per_shop/5]).

-export([gen_report/3]).

-define(SERVER, ?MODULE).

-record(state, {merchant            :: [],
		task_of_per_shop    :: [],
		ticket_of_merchant  :: [],
		birth_of_merchant   :: [],
		task_of_level_check :: []}).

%%%===================================================================
%%% API
%%%===================================================================
lookup(state) ->
    gen_server:call(?SERVER, lookup_state);
lookup(task_of_per_shop) ->
    gen_server:call(?SERVER, lookup_task_of_pershop).

report(stastic_per_shop, TriggerTime) ->
    gen_server:cast(?SERVER, {stastic_per_shop, TriggerTime}). 
cancel_report(stastic_per_shop) ->
    gen_server:cast(?SERVER, cancel_stastic_per_shop). 
syn_report(stastic_per_shop, {Merchant, UTable}, Conditions) ->
    %% 30 minute
    %% ?DEBUG("syn_report: Merchant ~p, UTable ~p, Conditions ~p", [Merchant, UTable, Conditions]),
    gen_server:call(?SERVER, {syn_stastic_per_shop, Merchant, UTable, Conditions}, 60000 * 30).

add(report_task, Merchant, TriggerTime) ->
    gen_server:call(?SERVER, {add_report_task, Merchant, TriggerTime}).

%% triggerTime: {12, 13, am} or {9, 15, pm}
ticket(preferential, TriggerTime) ->
    gen_server:cast(?SERVER, {gen_ticket, TriggerTime}).
cancel_ticket(preferential) ->
    gen_server:cast(?SERVER, cancel_ticket). 
syn_ticket(Merchant, Conditions) ->
    gen_server:call(?SERVER, {syn_ticket, Merchant, Conditions}).
    
%%
birth(congratulation, TriggerTime) ->
    gen_server:cast(?SERVER, {birth, TriggerTime}).
birth(cancel) ->
    gen_server:cast(?SERVER, cancel_birth).

%% retailer level
retailer_level(check, TriggerTime) ->
    gen_server:cast(?SERVER, {check_level, TriggerTime}).
retailer_level(cancel_check) ->
    gen_server:cast(?SERVER, {cancel_check_level}).

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
	    {ok, #state{merchant=L,
			task_of_per_shop    = [],
			ticket_of_merchant  = [],
			birth_of_merchant   = [],
			task_of_level_check = []}};
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
	    {reply, ok, State#state{merchant=[Merchant|Merchants],
				    task_of_per_shop=[NewTask|Tasks]}}
    end;
    
handle_call(lookup_state, _From, #state{merchant=Merchants,
					task_of_per_shop=Tasks,
					ticket_of_merchant=Tickets} = State) ->
    {reply, {Merchants, Tasks, Tickets}, State};

handle_call(lookup_task_of_pershop,
	    _From,
	    #state{merchant=_Merchants,
		   task_of_per_shop=Tasks,
		   ticket_of_merchant=_Tickets} = State) ->
    
    {reply, Tasks, State};

handle_call({syn_stastic_per_shop, Merchant, UTable, Conditions}, _From, State) ->
    ?DEBUG("syn_stastic_per_shop: merchant ~p, conditions ~p", [Merchant, Conditions]),
    StartTime = ?v(<<"start_time">>, Conditions),
    EndTime = ?v(<<"end_time">>, Conditions),
    Shops = ?v(<<"shop">>, Conditions),

    StartDays = calendar:date_to_gregorian_days(?utils:to_date(datetime, StartTime)),
    EndDays = calendar:date_to_gregorian_days(?utils:to_date(datetime, EndTime)),

    ToListFun = fun(V) when is_list(V) -> V;
		   (V) -> [V]
		end,
    try 
	lists:foreach(
	  fun(Shop) ->
		  ok = syn_stastic_per_shop(Merchant, UTable, Shop, StartDays, EndDays)
	  end, ToListFun(Shops)),
	{reply, {ok, Merchant}, State}
    catch
	_:{badmatch, Error} -> {reply, Error, State}
    end;

handle_call({syn_ticket, Merchant, Conditions}, _From, State) ->
    ?DEBUG("syn_ticket: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {Merchant, Sqls} = task(gen_ticket, calendar:now_to_local_time(erlang:now()), {Merchant, Conditions}),
    Reply = case length(Sqls) =:= 0 of
		true -> {ok, Merchant};
		false ->
		    ?sql_utils:execute(transaction, Sqls, Merchant)
	    end,
    {reply, Reply, State};
    
handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.

handle_cast({stastic_per_shop, TriggerTime}, #state{merchant=Merchants, task_of_per_shop=Tasks} = State) ->
    ?DEBUG("stastic_per_shop ~p, tasks ~p", [TriggerTime, Tasks]),
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
			  %% end, [], Merchants),
	    end, [], [138]),
	    %% ?DEBUG("new tasks ~p with merchants ~p", [NewTasks, Merchants]),
	    %% {noreply, #state{merchant=Merchants, task_of_per_shop=NewTasks}};
	    {noreply, State#state{task_of_per_shop=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast(cancel_stastic_per_shop, #state{task_of_per_shop=Tasks} = State) ->
    ?DEBUG("cancel_stastic_per_shop", []),
    lists:foreach(
      fun(Task) ->
	      ?cron:cancel(Task)
      end, Tasks),
    {noreply, State#state{task_of_per_shop=[]}};

handle_cast(cancel_ticket, #state{ticket_of_merchant=Tickets} = State) ->
    ?DEBUG("cancel_ticket", []),
    lists:foreach(
      fun(Ticket) ->
	      ?cron:cancel(Ticket)
      end, Tickets),
    {noreply, State#state{ticket_of_merchant=[]}}; 

handle_cast({gen_ticket, TriggerTime}, #state{merchant=Merchants, ticket_of_merchant=Tickets} = State) ->
    %% ?DEBUG("gen_ticket time ~p, tickets ~p", [TriggerTime, Tickets]),
    %% ?INFO("auto generate ticket at time ~p, tasks ~p", [TriggerTime, Tickets]),
    case Tickets of
	[] -> 
	    NewTasks = 
		lists:foldr(
		  fun(M, Acc) ->
			  CronTask = {{daily, TriggerTime},
				      fun(_Ref, Datetime) ->
					      task(gen_ticket, Datetime, [M])
				      end}, 
			  [?cron:cron(CronTask)|Acc] 
		  end, [], Merchants),
	    %% end, [], [1]),
	    %% ?DEBUG("new ticket ~p with merchants ~p", [NewTasks, Merchants]),
	    {noreply, State#state{ticket_of_merchant=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast({birth, TriggerTime}, #state{merchant=Merchants, birth_of_merchant=BirthAll} = State) ->
    %% ?DEBUG("birth time ~p, birth ~p", [TriggerTime, BirthAll]),
    %% ?INFO("Auto birth at time time ~p, birth ~p", [TriggerTime, BirthAll]),
    case BirthAll of
	[] ->
	    NewTasks =
		lists:foldr(
		  fun(M, Acc) ->
			  CronTask = {{daily, TriggerTime},
				      fun(_Ref, Datetime) ->
					      task(auto_sms_at_birth, Datetime, [M])
				      end},
			  %% ?DEBUG("CronTask ~p", [CronTask]),
			  [?cron:cron(CronTask)|Acc] 
		  end, [], Merchants),
			  %% end, [], [36]),
	    %% ?DEBUG("new auto sms ~p", [NewTasks]),
	    {noreply, State#state{birth_of_merchant=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast(cancel_birth, #state{birth_of_merchant=BirthAll} = State) ->
    ?DEBUG("cancel_birth", []),
    lists:foreach(
      fun(Birth) ->
	      ?cron:cancel(Birth)
      end, BirthAll),
    {noreply, State#state{birth_of_merchant=[]}};


handle_cast({check_level, TriggerTime}, #state{merchant=Merchants, task_of_level_check=Tasks} = State) ->
    ?INFO("level check at time~p, tasks ~p", [TriggerTime, Tasks]),
    case Tasks of
	[] ->
	    NewTasks =
		lists:foldr(
		  fun(M, Acc) ->
			  CronTask = {{daily, TriggerTime},
				      fun(_Ref, Datetime) ->
					      task(check_level, Datetime, [M])
				      end}, 
			  [?cron:cron(CronTask)|Acc] 
		  end, [], Merchants),
			  %% end, [], [4]),
	    ?DEBUG("new level check ~p with merchants ~p", [NewTasks, Merchants]),
	    {noreply, State#state{task_of_level_check=NewTasks}};
	_ -> {noreply, State}
    end;

handle_cast({cancel_check_level}, #state{task_of_level_check=Tasks} = State) ->
    ?DEBUG("cancel check level", []),
    lists:foreach(
      fun(Task) ->
	      ?cron:cancel(Task)
      end, Tasks),
    {noreply, State#state{task_of_level_check=[]}}; 

handle_cast(_Msg, State) ->
    ?DEBUG("handle_cast receive unkown message ~p, State ~p", [_Msg, State]),
    {noreply, State}.

handle_info(_Info, State) ->
    %% ?DEBUG("handle_info receive unkown message ~p", [_Info]),
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

syn_stastic_per_shop(_Merchant, _UTable, _Shop, StartDay, EndDay) when StartDay >= EndDay -> 
    ok;
syn_stastic_per_shop(Merchant, UTable, Shop, StartDay, EndDay) ->
    %% ?DEBUG("syn_stastic_per_shop: StartDay ~p, EndDay ~p", [StartDay, EndDay]),
    %% {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, Shop),
    %% BaseSettings = ?w_report_request:get_setting(Merchant, Shop),
    
    Date = calendar:gregorian_days_to_date(StartDay),
    {BeginOfDay, EndOfDay} = day(begin_to_end, Date),
    
    ?DEBUG("syn_stastic_per_shop: beginOfDay ~p, EndOfDay ~p", [BeginOfDay, EndOfDay]),

    Conditions = [{<<"shop">>, Shop},
		  {<<"start_time">>, ?to_b(BeginOfDay)},
		  {<<"end_time">>, ?to_b(EndOfDay)}],

    {ok, StockCalcTotal, StockCalcCost} =
	get_stock(calc,
		  Merchant,
		  UTable,
		  [{<<"shop">>, Shop},
		   %% {<<"start_time">>, ?w_report_request:get_config(<<"qtime_start">>, BaseSettings)},
		   {<<"end_time">>, ?to_b(EndOfDay)}
		  ]),

    %% {ok, LastStockInfo} = ?w_report:stastic(last_stock_of_shop, Merchant, Shop, BeginOfDay),
    %% LastStockTotal = stock(last_stock, LastStockInfo),

    {ok, SaleInfo} = ?w_report:stastic(stock_sale, Merchant, UTable, Conditions),
    {ok, ChargeInfo} = ?w_report:stastic(recharge, Merchant, Conditions),
    %% ?DEBUG("chargeInfo ~p", [ChargeInfo]),
    {ok, SaleProfit} = ?w_report:stastic(stock_profit, Merchant, UTable, Conditions),

    {ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, UTable, Conditions),
    {ok, StockOut} = ?w_report:stastic(stock_out, Merchant, UTable, Conditions),

    {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, UTable, Conditions),
    {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, UTable, Conditions),

    {ok, StockFix} = ?w_report:stastic(stock_fix, Merchant, UTable, Conditions),

    {SellTotal,
     SellBalance,
     SellCash,
     SellCard,
     SellWxin,
     SellAliPay,
     SellVeri,
     SellDraw,
     SellTicket} = sell(info, SaleInfo),
    {CBalance, SBalance, _CCash, _CCard, _CWxin} = charge(info, ChargeInfo),
    {SellCost} = sell(cost, SaleProfit),

    %% {CurrentStockTotal, CurrentStockCost} = stock(current, StockR), 
    {StockInTotal, StockInCost} = stock(in, StockIn),
    {StockOutTotal, StockOutCost} = stock(out, StockOut),

    {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
    {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
    {StockFixTotal, StockFixCost} = stock(fix, StockFix),

    %% ?DEBUG("StockInCost ~p, StockOutCost ~p, StockTransferInCost, StockTransferOutCost"),
    
    Sql="select id, merchant, shop, day from w_daily_report where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and day=\'" ++ ?to_s(BeginOfDay) ++ "\'",
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    case SellTotal == 0
		andalso SellBalance == 0
		andalso CBalance == 0
		andalso StockInTotal == 0
		andalso StockOutTotal == 0
		andalso StockTransferInTotal == 0
		andalso StockTransferOutTotal == 0
		andalso StockFixTotal == 0 of
		true ->
		    syn_stastic_per_shop(Merchant, UTable, Shop, StartDay + 1, EndDay);
		false ->
		    Sql1 = 
			"insert into w_daily_report(merchant, shop"
			", sell"
			", sell_cost"
			", balance"
			", cash"
			", card"
			", wxin"
			", aliPay"
			", draw"
			", ticket"
			", veri" 
			
			", charge"
			", sbalance"
			", stock"
			", stockc"
			", stock_cost"
			
			", stock_in"
			", stock_out"
			", stock_in_cost"
			", stock_out_cost"
			
			", t_stock_in"
			", t_stock_out"
			", t_stock_in_cost"
			", t_stock_out_cost"
			
			", stock_fix"
			", stock_fix_cost"
			", day"
			", entry_date) values("
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","

			++ ?to_s(SellTotal) ++ ","
			++ ?to_s(SellCost) ++ ","
			++ ?to_s(SellBalance) ++ ","
			++ ?to_s(SellCash) ++ ","
			++ ?to_s(SellCard) ++ ","
			++ ?to_s(SellWxin) ++ ","
			++ ?to_s(SellAliPay) ++ ","
			++ ?to_s(SellDraw) ++ ","
			++ ?to_s(SellTicket) ++ ","
			++ ?to_s(SellVeri) ++ "," 

			++ ?to_s(CBalance) ++ ","
			++ ?to_s(SBalance) ++ ","
			++ ?to_s(0) ++ ","
			++ ?to_s(StockCalcTotal) ++ ","
			++ ?to_s(StockCalcCost) ++ ","

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

			++ "\'" ++ ?to_s(BeginOfDay) ++ "\',"
			++ "\'" ++ ?utils:current_time(format_localtime) ++ "\')",
		    {ok, _} = ?sql_utils:execute(insert, Sql1), 
		    syn_stastic_per_shop(Merchant, UTable, Shop, StartDay + 1, EndDay)
	    end;
	{ok, R} ->
	    Updates = ?utils:v(sell, integer, SellTotal)
		++ ?utils:v(sell_cost, integer, SellCost)
		++ ?utils:v(balance, float, SellBalance)
		++ ?utils:v(cash, float, SellCash)
		++ ?utils:v(card, float, SellCard)
		++ ?utils:v(wxin, float, SellWxin)
		++ ?utils:v(aliPay, float, SellAliPay)
		++ ?utils:v(draw, float, SellDraw)
		++ ?utils:v(ticket, float, SellTicket)
		++ ?utils:v(veri, float, SellVeri)

	    %% ++ ?utils:v(stock, integer, LastStockTotal)
		++ ?utils:v(charge, float, CBalance)
		++ ?utils:v(sbalance, float, SBalance)
		++ ?utils:v(stockc, integer, StockCalcTotal)
		++ ?utils:v(stock_cost, float, StockCalcCost)

		++ ?utils:v(stock_in, integer, StockInTotal)
		++ ?utils:v(stock_out, integer, StockOutTotal)
		++ ?utils:v(stock_in_cost, float, StockInCost)
		++ ?utils:v(stock_out_cost, float, StockOutCost)

		++ ?utils:v(t_stock_in, integer, StockTransferInTotal)
		++ ?utils:v(t_stock_out, integer, StockTransferOutTotal)
		++ ?utils:v(t_stock_in_cost, float, StockTransferInCost)
		++ ?utils:v(t_stock_out_cost, float, StockTransferOutCost)

		++ ?utils:v(stock_fix, integer, StockFixTotal)
		++ ?utils:v(stock_fix_cost, float, StockFixCost),

	    Sql1 = "update w_daily_report set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(?v(<<"id">>, R))
		++ " and merchant=" ++ ?to_s(Merchant),
	    {ok, _} = ?sql_utils:execute(write, Sql1, ?v(<<"id">>, R)),
	    syn_stastic_per_shop(Merchant, UTable, Shop, StartDay + 1, EndDay)
    end.

task(gen_ticket, Datetime, Merchants) when is_list(Merchants) ->
    Sqls = lists:foldr(fun(M, Acc) ->
			       [task(gen_ticket, Datetime, {M, []})|Acc]
		       end, [], Merchants),
    %% ?DEBUG("gen_tickiet: auto gen Sqls ~p", [Sqls]), 
    lists:foreach(
      fun({_M, SqlsOfMerchant}) -> 
	      %% lists:foreach(
	      %% 	fun(Sql)->
	      %% 		case ?sql_utils:execute(insert, Sql) of
	      %% 		    {ok, _} -> ok;
	      %% 		    {error, Error} ->
	      %% 			?WARN("sql error to create daily report: ~p", [Error])
	      %% 		end
	      %% 	end, SqlsOfMerchant)
	      case length(SqlsOfMerchant) =:= 0 of
		  true -> ok;
		  false ->
		      case ?sql_utils:execute(transaction, SqlsOfMerchant, _M) of
			  {ok, _} -> ok;
			  {error, Error} ->
			      ?WARN("sql error to create gen ticket: ~p", [Error])
			      %% {error, Error}
		      end
	      end
      end, Sqls);

task(gen_ticket, Datetime, {Merchant, Conditions}) when is_number(Merchant) ->
    FormatDatetime = format_datetime(Datetime),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    {ok, Scores} = ?w_user_profile:get(score, Merchant),
    ?DEBUG("scores ~p", [Scores]), 
    ScoreId = ?v(<<"sid">>, Conditions, ?INVALID_OR_EMPTY),
    %% ?DEBUG("scoreId ~p", [ScoreId]),
    %% max first
    Score2Money =
	case ScoreId of
	    ?INVALID_OR_EMPTY ->
		lists:foldr(
		  fun({S}, Acc) ->
			  case ?v(<<"type_id">>, S) =:= 1 andalso ?v(<<"deleted">>, S) =:= 0 of
			      true ->
				  %% case Acc of
				  %%     [] -> S;
				  %%     S0 ->
				  %% 	  case ?v(<<"balance">>, S0) < ?v(<<"balance">>, S) of
				  %% 	      true -> S;
				  %% 	      false -> Acc
				  %% 	  end
				  %% end;
				  [{S}|Acc];
			      false ->
				  Acc
			  end
		  end, [], Scores);
	    _ ->
		lists:foldr(
		  fun({S}, Acc) ->
			  case ?v(<<"type_id">>, S) =:= 1 andalso ?v(<<"id">>, S) =:= ScoreId of
			      true -> [{S}];
			      false -> Acc
			  end
		  end, [], Scores)
	end,    
    %% ?DEBUG("score2money ~p, ", [Score2Money]),
    
    TicketSetting = ?to_s(?v(<<"gen_ticket">>, BaseSetting)),
    %% ?DEBUG("TicketSetting ~p", [TicketSetting]),

    AutoGenTicket = ?utils:nth(1, TicketSetting),
    IsCheck = ?utils:nth(2, TicketSetting),
    PartCalc = ?utils:nth(3, TicketSetting), 
    ?DEBUG("AutoGenTicket ~p, IsCheck ~p, PartCalc ~p", [AutoGenTicket, IsCheck, PartCalc]),

    SortScores = lists:sort(
		   fun({S0}, {S1}) -> ?v(<<"score">>, S0) < ?v(<<"score">>, S1) end,
		   Score2Money),
    %% ?DEBUG("SortScores ~p", [SortScores]),

    SysVips = sys_vip_of(merchant, Merchant), 
    TicketSqls =
	case AutoGenTicket =:= ?YES andalso length(SortScores) =/= 0 of
	    true -> 
		%% SortScores = 
		%%     lists:sort(
		%%       fun({S0}, {S1}) ->
		%% 	      ?v(<<"score">>, S0) < ?v(<<"score">>, S1) end,
		%%       lists:filter(
		%% 	fun({S}) ->
		%% 		?v(<<"type_id">>, S) =:= 1
		%% 		    andalso ?v(<<"id">>, S) /= ScoreId
		%% 		    andalso ?v(<<"score">>, S) > ?v(<<"score">>, Score2Money) end, Scores)),
		
		%% AccScore1 = 
		%%     lists:foldr(
		%%       fun({S}, Acc) ->
		%% 	      ?DEBUG("S ~p", [S]),
		%% 	      AccScore0 = ?v(<<"score">>, Acc),
		%% 	      AccScore1 = ?v(<<"score">>, S),
		%% 	      ?DEBUG("score0 ~p, score1 ~p, score ~p,", [AccScore0, AccScore1, AccScore]),
		%% 	      case AccScore1 > AccScore of
		%% 		  true ->
		%% 		      case AccScore1 < AccScore0 of
		%% 			  true -> AccScore1;
		%% 			  false -> Acc
		%% 		      end;
		%% 		  false ->
		%% 		      Acc
		%% 	      end
		%%       end, Score2Money, lists:filter(fun({S}) -> ?v(<<"type_id">>, S) =:= 1 end, Scores)),

		%% ?DEBUG("SortScores ~p", [SortScores]),

		NewConditions = lists:keydelete(
				  <<"retailer">>, 1,
				  lists:keydelete(<<"sid">>, 1, Conditions))
		    ++ case ?v(<<"retailer">>, Conditions, []) of
			   [] -> [];
			   _RetailerId -> [{<<"id">>, _RetailerId}]
		       end, 

		[MinScore2Money|_] = SortScores,
		MinAccScore = ?v(<<"score">>, MinScore2Money), 
		Sql = "select id, score from w_retailer where merchant=" ++ ?to_s(Merchant) 
		    ++ " and score>=" ++ ?to_s(MinAccScore)
		    %% ++ case SortScores of
		    %% 	   [] -> [];
		    %% 	   [H|_] ->
		    %% 	       " and score<" ++ ?to_s(?v(<<"score">>, H))
		    %%    end
		    ++ ?sql_utils:condition(proplists, NewConditions)
		    ++ " and type in (0, 1)"
		    ++ " and deleted=0",
		case ?sql_utils:execute(read, Sql) of
		    {ok, []} -> [];
		    {ok, Retailers} ->
			%% gen ticket
			Max2MinSortScores = lists:reverse(SortScores),
			lists:foldr(
			  fun({R}, Acc)->
				  case lists:member(?v(<<"id">>, R), SysVips) of
				      true -> Acc;
				      false ->
					  travel_retailer_score(
					    R,
					    Merchant,
					    Max2MinSortScores,
					    IsCheck,
					    PartCalc,
					    FormatDatetime,
					    []) ++ Acc
					  %% only one ticket unless the ticked was consumed
					  %% case ?sql_utils:execute(
					  %% 	  s_read , "select id, batch, balance, retailer from w_ticket"
					  %% 	  " where merchant=" ++ ?to_s(Merchant)
					  %% 	  ++ " and retailer=" ++ ?to_s(RetailerId)
					  %% 	  ++ " and state in (0, 1)" ) of
					  %%     {ok, []} ->
					  %% 	  Batch = ?inventory_sn:sn(w_ticket, Merchant), 
					  %% 	  ["insert into w_ticket(batch, sid, balance"
					  %% 	   ", retailer, state, merchant, entry_date) values("
					  %% 	   ++ ?to_s(Batch) ++ ","
					  %% 	   ++ ?to_s(?v(<<"id">>, Score2Money)) ++ ","
					  %% 	   ++ ?to_s(TicketBalance) ++ ","
					  %% 	   ++ ?to_s(RetailerId) ++ ","
					  %% 	   ++ ?to_s(IsCheck) ++ ","
					  %% 	   ++ ?to_s(Merchant) ++ ","
					  %% 	   ++ "\'" ++ FormatDatetime ++ "\')"|Acc];
					  %%     {ok, E} ->
					  %% 	  %% ["update w_ticket set "
					  %% 	  %%  " sid=" ++ ?to_s(?v(<<"id">>, Score2Money))
					  %% 	  %%  ++ ", balance=" ++ ?to_s(TicketBalance)
					  %% 	  %%  ++ ", entry_date=\'" ++ FormatDatetime ++ "\'"
					  %% 	  %%  ++ " where id=" ++ ?to_s(?v(<<"id">>, E))|Acc]
					  %% 	  case TicketBalance =/= ?v(<<"balance">>, E) of
					  %% 	      true ->
					  %% 	  	  %% ["update w_ticket set balance=" ++ ?to_s(TicketBalance)
					  %% 	  	  %% ++ " where id=" ++ ?to_s(?v(<<"id">>, E))|Acc];
					  %% 	  	  ["update w_ticket set "
					  %% 	  	   " sid=" ++ ?to_s(?v(<<"id">>, Score2Money))
					  %% 	  	   ++ ", balance=" ++ ?to_s(TicketBalance)
					  %% 	  	   ++ ", entry_date=\'" ++ FormatDatetime ++ "\'"
					  %% 	  	   ++ " where id=" ++ ?to_s(?v(<<"id">>, E))|Acc];
					  %% 	      false -> Acc
					  %% 	  end
					  %% end
				  end
			  end, [], Retailers)
		end;
	    false -> [] 
	end,
    %% lists:foreach(
    %%   fun(GenSql) ->
    %% 	      case ?sql_utils:execute(insert, GenSql) of
    %% 		  {ok, _} -> ok;
    %% 		  {error, Error} ->
    %% 		      ?WARN("sql error to gen ticket: ~p", [Error])
    %% 	      end
    %%   end, TicketSqls);
    %% ?DEBUG("ticketSqls ~p", [TicketSqls]),
    {Merchant, lists:reverse(TicketSqls)};

task(auto_sms_at_birth, Datetime, Merchants) when is_list(Merchants) ->
    ?DEBUG("auto_sms_at_birth: datetime ~p, Merchants ~p", [Datetime, Merchants]),
    MerchantPhones = lists:foldr(
		  fun(M, Acc) ->
			  [task(auto_sms_at_birth, Datetime, M)|Acc]
		  end, [], Merchants),
    %% ?DEBUG("auto_sms_at_birth: Phones ~p", [MerchantPhones]), 
    lists:foreach(
      fun({Merchant, Info}) ->
	      lists:foreach(
		fun({Phone, Shop, Sign})->
			%% send sms 
			?notify:sms(birth, Merchant, Phone, {Shop, Sign})
		end, Info)
      end, MerchantPhones);

task(auto_sms_at_birth, Datetime, Merchant) when is_number(Merchant)->
    {{Year, Month, Day}, _Time} = Datetime,
    {_LunarYear, LunarMonth, LunarDay} = ?lunar_calendar:solar2lunar(Year, Month, Day),
    %% ?DEBUG("LunarYear ~p, LunarMonth ~p, LunarDay ~p", [_LunarYear, LunarMonth, LunarDay]),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, ?DEFAULT_BASE_SETTING),
    SMSSetting = ?v(<<"recharge_sms">>, BaseSetting, ?SMS_NOTIFY), 
    BirthSMS = ?utils:nth(4, SMSSetting),
    %% ?DEBUG("SMSSetting ~p, BirthSMS ~p", [SMSSetting, BirthSMS]),
    %% BirthBefore = ?to_i(?v(<<"birth_before">>, BaseSetting, 0)),
    case BirthSMS of
	0 -> {Merchant, []}; 
	1 ->
	    %% get all retailers
	    {ok, Retailers} = ?w_retailer:retailer(list, Merchant),
	    %% birthday of retailer
	    SMSRetailers = 
		lists:foldr(
		  fun({Retailer}, Acc) ->
			  case ?v(<<"type_id">>, Retailer) =:= ?SYSTEM_RETAILER of
			      true -> Acc;
			      false ->
				  Birth = ?v(<<"birth">>, Retailer, []),
				  <<_Y:4/binary, "-", MonthOfBirth:2/binary, "-", DayOfBirth/binary>> = Birth, 
				  %% Seconds = calendar:datetime_to_gregorian_seconds(Datetime) - ?ONE_DAY * BirthBefore,
				  %% {{_Year, Month, Day}, _} = calendar:gregorian_seconds_to_datetime(Seconds),
				  case ?v(<<"lunar_id">>, Retailer) of
				      0 -> %% solar calendar
					  case Month =:= ?to_i(MonthOfBirth)
					      andalso Day =:= ?to_i(DayOfBirth) of
					      true ->
						  [{?v(<<"mobile">>, Retailer),
						    ?v(<<"shop">>, Retailer),
						    ?v(<<"sign">>, Retailer)}|Acc];
					      false ->
						  Acc
					  end;
				      1 -> %% lunar calendar
					  case LunarMonth =:= ?to_i(MonthOfBirth)
					      andalso LunarDay =:= ?to_i(DayOfBirth) of
					      true ->
						  [{?v(<<"mobile">>, Retailer),
						    ?v(<<"shop">>, Retailer),
						    ?v(<<"sign">>, Retailer)
						   }|Acc];
					      false ->
						  Acc
					  end
				  end
			  end
		  end, [], Retailers),
	    {Merchant, SMSRetailers}
    end;

task(check_level, Datetime, Merchants) when is_list(Merchants) ->
    %% ?DEBUG("start check_level ~p", [Datetime]),
     UpLevels = lists:foldr(
		fun(M, Acc) ->
			[task(check_level,  Datetime, M)|Acc]
		end, [], Merchants),
    ?DEBUG("check level ~p:", [UpLevels]),
    lists:foreach(
      fun({Merchant, UpSqls}) ->
	      lists:foreach(
		fun({_, _, Sqls})-> 
			%%?DEBUG("Sqls: ~p", [Sqls]),
			case length(Sqls) =:= 0 of
			    true -> ok;
			    false ->
				case ?sql_utils:execute(transaction, Sqls, Merchant) of
				    {ok, Merchant} -> ok;
				    {error, Error} ->
					?WARN("sql error to check retailer level: ~p", [Error])
				end
			end
		end, UpSqls)
      end, UpLevels);
    
task(check_level, _Datetime, Merchant) when is_number(Merchant) ->
    %% get shop
    %% ?DEBUG("start check level: datetime ~p", [_Datetime]),
    {ok, Shops} = ?w_user_profile:get(shop, Merchant),
    {ok, Levels} = ?w_user_profile:get(retailer_level, Merchant), 
    Sqls = start_check_level(Merchant, Levels, Shops, []),
    {Merchant, Sqls};
	
task(stastic_per_shop, Datetime, Merchants) when is_list(Merchants)->
    ?DEBUG("stastic_per_shop Datetime ~p, Merchants ~p", [Datetime, Merchants]),
    {YestodayStart, YestodayEnd} = yestoday(Datetime),
    FormatDatetime = format_datetime(Datetime),

    SqlsOfAllMerchant=
	gen_report(stastic_per_shop,
		   {YestodayStart, YestodayEnd, FormatDatetime}, Merchants), 
    %% ?DEBUG("SqlsOfAllMerchant ~p", [SqlsOfAllMerchant]), 
    lists:foreach(
      fun({_M, Sqls}) ->
	      case length(Sqls) =:= 0 of
		  true -> ok;
		  false ->
		      case ?sql_utils:execute(transaction, Sqls, _M) of
			  {ok, _} -> ok;
			  {error, Error} ->
			      ?WARN("sql error to create daily report: ~p", [Error])
		      end
	      end
			  
	      %% lists:foreach(
	      %% 	fun(Sql)->
	      %% 		case ?sql_utils:execute(insert, Sql) of
	      %% 		    {ok, _} -> ok;
	      %% 		    {error, Error} ->
	      %% 			?WARN("sql error to create daily report: ~p", [Error])
	      %% 		end
	      %% 	end, Sqls)
      end, SqlsOfAllMerchant);
task(stastic_per_shop, Datetime, Merchant) when is_number(Merchant)->
    task(stastic_per_shop, Datetime, [Merchant]).

gen_report(stastic_per_shop, Datetime, Merchants) ->
    gen_report(stastic_per_shop, Datetime, Merchants, []).
    
gen_report(stastic_per_shop, _Datetime, [], Acc) ->
    Acc;
gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , [M|Merchants], Acc) ->
    {ok, Shops} = ?w_user_profile:get(shop, M),
    %% ?DEBUG("merchant ~p with shops ~p",
    %% 	   [M, lists:foldr(fun({Shop}, Acc1)-> [?v(<<"id">>, Shop)|Acc1] end, [], Shops)]), 
    %% Shops = [{[{<<"id">>, 280}]}],
    {M, Sqls} = gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, []),
    gen_report(stastic_per_shop, {StartTime, EndTime, GenDatetime} , Merchants, [{M, Sqls}|Acc]).

gen_shop_report(_Datetime, M, [], Sqls) ->
    %% ?DEBUG("merchant ~p gen sql ~p", [M, Sqls]),
    {M, Sqls};
gen_shop_report({StartTime, EndTime, GenDatetime}, M, [{S}|Shops], Sqls) ->
    %% ?DEBUG("gen_shop_report with merchant ~p, shop ~p, startTime ~p, endTime ~p, genTime ~p",
    %% 	   [M, S, StartTime, EndTime, GenDatetime]),
    ShopId  = ?v(<<"id">>, S),
    %% ?DEBUG("ShopId ~p", [ShopId]),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, M, -1),
    IsShopDailyReport = ?v(<<"d_report">>, BaseSetting, 0),

    {ok, MerchantInfo} = ?w_user_profile:get(merchant, M),
    UTable = ?v(<<"unique_table">>, MerchantInfo, 0),
    %% ?DEBUG("IsShopDailyReport ~p", [IsShopDailyReport]),
    
    case ?to_i(IsShopDailyReport) of
	1 -> 
	    Conditions = [{<<"shop">>, ShopId},
			  {<<"start_time">>, ?to_b(StartTime)},
			  {<<"end_time">>, ?to_b(EndTime)}],

	    {ok, SaleInfo} = ?w_report:stastic(stock_sale, M, UTable, Conditions),
	    {ok, ChargeInfo} = ?w_report:stastic(recharge, M, Conditions),
	    {ok, SaleProfit} = ?w_report:stastic(stock_profit, M, UTable, Conditions),

	    {ok, StockIn}  = ?w_report:stastic(stock_in, M, UTable, Conditions),
	    {ok, StockOut} = ?w_report:stastic(stock_out, M, UTable, Conditions),

	    {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, M, UTable, Conditions),
	    {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, M, UTable, Conditions),

	    {ok, StockFix} = case ?w_report:stastic(stock_fix, M, UTable, Conditions) of
				 {ok, _StockFix} -> {ok, _StockFix};
				 {error, _} -> {ok, []}
			     end,

	    {ok, StockCalcTotal, StockCalcCost} =
		get_stock(calc,
			  M,
			  UTable,
			  [{<<"shop">>, ShopId},
			   %% {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)},
			   {<<"end_time">>, ?to_b(EndTime)}
			  ]),
	    
	    {ok, StockR} = ?w_report:stastic(
			      stock_real,
			      M,
			      UTable,
			      [{<<"shop">>, ShopId}
			       %% {<<"start_time">>, ?v(<<"qtime_start">>, BaseSetting)}
			      ]),

	    {SellTotal,
	     SellBalance,
	     SellCash,
	     SellCard,
	     SellWxin,
	     SellAliPay,
	     SellVeri,
	     SellDraw,
	     SellTicket} = sell(info, SaleInfo),
	    
	    {CBalance, SBalance, _CCash, _CCard, _CWxin} = charge(info, ChargeInfo),
	    {SellCost} = sell(cost, SaleProfit),

	    {CurrentStockTotal, _CurrentStockCost} = stock(current, StockR), 
	    {StockInTotal, StockInCost} = stock(in, StockIn),
	    {StockOutTotal, StockOutCost} = stock(out, StockOut),

	    {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
	    {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
	    {StockFixTotal, StockFixCost} = stock(fix, StockFix),

	    case SellTotal == 0
		andalso SellBalance == 0
	    	andalso CBalance == 0
	    	andalso StockInTotal == 0
	    	andalso StockOutTotal == 0
	    	andalso StockTransferInTotal == 0
	    	andalso StockTransferOutTotal == 0
	    	andalso StockFixTotal == 0 of
	    	true ->
	    	    %% ?DEBUG("no input, no daily report", []),
	    	    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls);
	    	false ->
		    Sql0 = "select"
			" id"
			", merchant"
			", shop"
			", day"
			" from w_daily_report where merchant=" ++ ?to_s(M)
			++ " and shop=" ++ ?to_s(ShopId)
			++ " and day=\'" ++ ?to_s(StartTime) ++ "\'", 
		    case ?sql_utils:execute(s_read, Sql0) of
			{ok, []} -> 
			    Sql = 
				"insert into w_daily_report(merchant, shop"
				", sell"
				", sell_cost"
				", balance"
				", cash"
				", card"
				", wxin"
				", aliPay"
				", draw"
				", ticket"
				", veri"
				
				", charge"
				", sbalance"
				", stock"
				", stockc"
				", stock_cost"
				
				", stock_in"
				", stock_out"
				", stock_in_cost"
				", stock_out_cost"
				
				", t_stock_in"
				", t_stock_out"
				", t_stock_in_cost"
				", t_stock_out_cost"
				
				", stock_fix"
				", stock_fix_cost"
				", day"
				", entry_date) values("
				++ ?to_s(M) ++ ","
				++ ?to_s(ShopId) ++ ","

				++ ?to_s(SellTotal) ++ ","
				++ ?to_s(SellCost) ++ ","
				++ ?to_s(SellBalance) ++ ","
				++ ?to_s(SellCash) ++ ","
				++ ?to_s(SellCard) ++ ","
				++ ?to_s(SellWxin) ++ ","
				++ ?to_s(SellAliPay) ++ ","
				++ ?to_s(SellDraw) ++ ","
				++ ?to_s(SellTicket) ++ ","
				++ ?to_s(SellVeri) ++ ","

				++ ?to_s(CBalance) ++ ","
				++ ?to_s(SBalance) ++ ","
				++ ?to_s(CurrentStockTotal) ++ ","
				++ ?to_s(StockCalcTotal) ++ ","
				++ ?to_s(StockCalcCost) ++ ","
			    %% ++ ?to_s(CurrentStockCost) ++ ","

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
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, [Sql|Sqls]);
			{ok, R} ->
			    ?DEBUG("R ~p", [R]),
			    Updates = ?utils:v(sell, integer, SellTotal)
				++ ?utils:v(sell_cost, integer, SellCost)
				++ ?utils:v(balance, float, SellBalance)
				++ ?utils:v(cash, float, SellCash)
				++ ?utils:v(card, float, SellCard)
				++ ?utils:v(wxin, float, SellWxin)
				++ ?utils:v(aliPay, float, SellAliPay)
				++ ?utils:v(draw, float, SellDraw)
				++ ?utils:v(ticket, float, SellTicket)
				++ ?utils:v(veri, float, SellVeri)

				++ ?utils:v(charge, float, CBalance)
				++ ?utils:v(sbalance, float, SBalance)
				++ ?utils:v(stock, integer, CurrentStockTotal) 
				++ ?utils:v(stockc, integer, StockCalcTotal)
				++ ?utils:v(stock_cost, float, StockCalcCost)

				++ ?utils:v(stock_in, integer, StockInTotal)
				++ ?utils:v(stock_out, integer, StockOutTotal)
				++ ?utils:v(stock_in_cost, float, StockInCost)
				++ ?utils:v(stock_out_cost, float, StockOutCost)

				++ ?utils:v(t_stock_in, integer, StockTransferInTotal)
				++ ?utils:v(t_stock_out, integer, StockTransferOutTotal)
				++ ?utils:v(t_stock_in_cost, float, StockTransferInCost)
				++ ?utils:v(t_stock_out_cost, float, StockTransferOutCost)

				++ ?utils:v(stock_fix, integer, StockFixTotal)
				++ ?utils:v(stock_fix_cost, float, StockFixCost)
				++ ?utils:v(entry_date, string, GenDatetime),

			    Sql = "update w_daily_report set "
				++ ?utils:to_sqls(proplists, comma, Updates)
				++ " where id=" ++ ?to_s(?v(<<"id">>, R)),
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, [Sql|Sqls]);
			{error, _Error} ->
			    ?INFO("failed to gen daily report merchant ~p, shop ~p, date ~p",
				  [M, ShopId, GenDatetime]),
			    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls)
		    end
	    end;
	0 ->
	    %% ?DEBUG("daily report does not opend ~p", [S]),
	    gen_shop_report({StartTime, EndTime, GenDatetime}, M, Shops, Sqls)
    end.

start_check_level(_Merchant, _Levels, [], CheckSqls) ->
    CheckSqls; 
start_check_level(Merchant, Levels, [{Shop}|Shops], CheckSqls) ->
    %% ?DEBUG("shop ~p", [Shop]),
    ShopId = ?v(<<"id">>, Shop),
    BaseSettings = ?w_report_request:get_setting(Merchant, ShopId),
    <<_M:1/binary, Auto:1/binary, _/binary>> =
	case ?w_report_request:get_config(<<"r_discount">>, BaseSettings) of
	    [] -> ?VIP_DEFAULT_MODE;
	    <<"0">> -> ?VIP_DEFAULT_MODE;
	    _Value -> _Value
	end,
    
    Sqls =
	case ?to_i(Auto) =:= ?YES of
	    true ->
		[L0|LT] = Levels,
		Sql = "select id, level, score, consume, shop from w_retailer"
		    " where merchant=" ++ ?to_s(Merchant)
		    ++ " and shop=" ++ ?to_s(ShopId) 
		    ++ " and type in(0, 1)" 
		    ++ case erlang:length(Levels) =/= 0 of
			   true ->
			       " and (consume>" ++ ?to_s(?v(<<"score">>, L0)) 
				   ++ lists:foldr(
					fun({Level}, Acc) ->
						" or consume>"
						    ++ ?to_s(?v(<<"score">>, Level)) ++ Acc
					end, [], LT)
				   ++ ")";
			   false -> []
		       end,
		case ?sql_utils:execute(read, Sql) of
		    {ok, []} -> [];
		    {ok, Retailers} ->
			lists:foldr(
			  fun({R}, Acc) -> 
				  ILevel = ?v(<<"level">>, R),
				  UpLevel = lists:foldr(
					      fun({Level}, StartLevel) ->
						      L = ?v(<<"level">>, Level),
						      Consume = ?v(<<"consume">>, R),
						      ScoreLevel = ?v(<<"score">>, Level),
						      case  Consume >  ScoreLevel of
							  true ->
							      case StartLevel < L of
								  true ->
								      L;
								  false ->
								      StartLevel
							      end;
							  false ->
							      StartLevel
						      end
					      end, ILevel, Levels),
				  case UpLevel > ILevel of
				      true ->
					  ["update w_retailer set level=" ++ ?to_s(UpLevel)
					   ++ " where merchant=" ++ ?to_s(Merchant)
					   ++ " and shop=" ++ ?to_s(ShopId)
					   ++ " and id=" ++ ?to_s(?v(<<"id">>, R))| Acc];
				      false ->
					  Acc
				  end
			  end, [], Retailers)
		end;
	    false ->
		[]
	end,
    start_check_level(Merchant, Levels, Shops, [{Merchant, ShopId, Sqls}|CheckSqls]).

get_stock(calc, Merchant, UTable, Conditions) ->
    {ok, SaleInfo} = ?w_report:stastic(stock_sale, Merchant, UTable, Conditions),
    {ok, SaleProfit} = ?w_report:stastic(stock_profit, Merchant, UTable, Conditions),
    {ok, StockIn}  = ?w_report:stastic(stock_in, Merchant, UTable, Conditions),
    {ok, StockOut} = ?w_report:stastic(stock_out, Merchant, UTable, Conditions),
    {ok, StockTransferIn} = ?w_report:stastic(stock_transfer_in, Merchant, UTable, Conditions),
    {ok, StockTransferOut} = ?w_report:stastic(stock_transfer_out, Merchant, UTable, Conditions),
    {ok, StockFix} = case ?w_report:stastic(stock_fix, Merchant, UTable, Conditions) of
			 {ok, _StockFix} -> {ok, _StockFix};
			 {error, _} -> {ok, []}
		     end,

    {SellTotal,
     _SellBalance,
     _SellCash,
     _SellCard,
     _SellWxin,
     _SellAliPay,
     _SellVeri,
     _SellDraw,
     _SellTicket} = sell(info, SaleInfo),
    {SellCost} = sell(cost, SaleProfit),

    {StockInTotal, StockInCost} = stock(in, StockIn),
    {StockOutTotal, StockOutCost} = stock(out, StockOut),

    {StockTransferInTotal, StockTransferInCost}  = stock(t_in, StockTransferIn),
    {StockTransferOutTotal, StockTransferOutCost} = stock(t_out, StockTransferOut), 
    {StockFixTotal, StockFixCost} = stock(fix, StockFix),

    StockCalcTotal = StockInTotal + StockOutTotal - SellTotal
	+ StockTransferInTotal - StockTransferOutTotal
	+ StockFixTotal,

    %% ?DEBUG("StockInCost ~p, StockOutCost ~p, SellCost ~p, StockTransferInCost ~p, StockTransferOutCost ~p",
    %% 	  [StockInCost, StockOutCost, SellCost, StockTransferInCost, StockTransferOutCost]),
    
    StockCalcCost = StockInCost + StockOutCost - SellCost
	+ StockTransferInCost - StockTransferOutCost
	+ StockFixCost,

    {ok, StockCalcTotal, StockCalcCost}.

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


-spec day/2::(atom(), calendar:date()) -> tuple(). 
day(begin_to_end, {Year, Month, Day}) ->
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
    {0, 0, 0, 0, 0, 0, 0, 0, 0};
sell(info, [{SaleInfo}])->
    {?v(<<"total">>, SaleInfo, 0),
     ?v(<<"spay">>, SaleInfo, 0),
     ?v(<<"cash">>, SaleInfo, 0),
     ?v(<<"card">>, SaleInfo, 0),
     ?v(<<"wxin">>, SaleInfo, 0),
     ?v(<<"aliPay">>, SaleInfo, 0),
     ?v(<<"veri">>, SaleInfo, 0),
     ?v(<<"draw">>, SaleInfo, 0),
     ?v(<<"ticket">>, SaleInfo, 0)
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

stock(last_stock, []) ->
    0;
stock(last_stock, [{StockInfo}]) ->
    ?v(<<"total">>, StockInfo, 0);

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

charge(info, []) ->
    {0, 0, 0, 0, 0};
charge(info, [{ChargeInfo}]) ->
    {?v(<<"cbalance">>, ChargeInfo, 0),
     ?v(<<"sbalance">>, ChargeInfo, 0),
     ?v(<<"tcash">>, ChargeInfo, 0),
     ?v(<<"tcard">>, ChargeInfo, 0),
     ?v(<<"twxin">>, ChargeInfo, 0)}.

travel_retailer_score(_Retailer, _Merchant, [], _IsCheck, _PartCalc, _Datetime, Sql) ->
    Sql;
travel_retailer_score(Retailer, Merchant, [{Score2Money}|T], IsCheck, PartCalc, Datetime, Sql) -> 
    %% ?DEBUG("Retailer ~p, Score2Money ~p, PartCalc ~p", [Retailer, Score2Money, PartCalc]),
    RetailerScore = ?v(<<"score">>, Retailer, 0),
    AccScore = ?v(<<"score">>, Score2Money),
    case RetailerScore >= AccScore of
	true ->
	    SendBalance = ?v(<<"balance">>, Score2Money),
	    TicketBalance =
		case PartCalc of
		    ?YES ->
			SendBalance;
		    ?NO ->
			RetailerScore div AccScore * SendBalance
		end,
	    %% TicketBalance = SendBalance, 
	    travel_retailer_score(
	      Retailer,
	      Merchant,
	      [],
	      IsCheck,
	      PartCalc,
	      Datetime,
	      gen_sql(ticket,
		      Merchant,
		      ?v(<<"id">>, Retailer),
		      ?v(<<"id">>, Score2Money),
		      TicketBalance,
		      IsCheck,
		      Datetime));
	false ->
	    travel_retailer_score(Retailer, Merchant, T, IsCheck, PartCalc, Datetime, Sql)
    end.
		     
gen_sql(ticket, Merchant, RetailerId, Score2Money, TicketBalance, IsCheck, Datetime) ->
    %% ?DEBUG("TicketBalance ~p", [TicketBalance]),
    case ?sql_utils:execute(
	    s_read , "select id, batch, balance, retailer from w_ticket"
	    " where merchant=" ++ ?to_s(Merchant)
	    ++ " and retailer=" ++ ?to_s(RetailerId)
	    ++ " and state in (0,1)" ) of
	{ok, []} ->
	    Batch = ?inventory_sn:sn(w_ticket, Merchant), 
	    ["insert into w_ticket(batch, sid, balance"
		", retailer, state, merchant, entry_date) values("
	     ++ ?to_s(Batch) ++ ","
	     ++ ?to_s(Score2Money) ++ ","
	     ++ ?to_s(TicketBalance) ++ ","
	     ++ ?to_s(RetailerId) ++ ","
	     ++ ?to_s(IsCheck) ++ ","
	     ++ ?to_s(Merchant) ++ ","
	     ++ "\'" ++ Datetime ++ "\')"];
	{ok, E} ->
	    %% ["update w_ticket set "
	    %%  " sid=" ++ ?to_s(?v(<<"id">>, Score2Money))
	    %%  ++ ", balance=" ++ ?to_s(TicketBalance)
	    %%  ++ ", entry_date=\'" ++ FormatDatetime ++ "\'"
	    %%  ++ " where id=" ++ ?to_s(?v(<<"id">>, E))|Acc]
	    case TicketBalance =/= ?v(<<"balance">>, E) of
		true ->
		    %% ["update w_ticket set balance=" ++ ?to_s(TicketBalance)
		    %% ++ " where id=" ++ ?to_s(?v(<<"id">>, E))|Acc];
		    ["update w_ticket set "
		     " sid=" ++ ?to_s(Score2Money)
		     ++ ", balance=" ++ ?to_s(TicketBalance)
		     ++ ", entry_date=\'" ++ Datetime ++ "\'"
		     ++ " where id=" ++ ?to_s(?v(<<"id">>, E))];
		false -> []
	    end
    end.

sys_vip_of(merchant, Merchant) ->
    %% {ok, Settings} = ?w_user_profile:get(setting, Merchant),
    %% SysVips =
    %% 	lists:foldr(
    %% 	  fun({S}, Acc) ->
    %% 		  case ?v(<<"ename">>, S) =:= <<"s_customer">> of
    %% 		      true ->
    %% 			  SysVip = ?to_i(?v(<<"value">>, S)),
    %% 			  %% ?DEBUG("sysvip ~p", [SysVip]),
    %% 			  case SysVip /= 0 andalso not lists:member(SysVip, Acc) of
    %% 			      true -> [SysVip] ++ Acc;
    %% 			      false -> Acc 
    %% 			  end;
    %% 		      false -> Acc
    %% 		  end
    %% 	  end, [], Settings),
    {ok, SysVips} = ?w_user_profile:get(sys_retailer, Merchant), 
    SimpleSysVips = [?v(<<"id">>, S) || {S} <- SysVips],
    ?DEBUG("SimpleSysVips ~p", [SimpleSysVips]),
    SimpleSysVips.



