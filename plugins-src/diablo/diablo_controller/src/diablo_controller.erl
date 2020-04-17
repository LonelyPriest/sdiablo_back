%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright Seasungame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1, handle_gc/0]).

%%%===================================================================
%%% Application callbacks
%%%===================================================================
start(normal, _StartArgs) ->
    case diablo_controller_sup:start_link() of
	{ok, Pid} ->
	    true = register(diablo_controller, self()),
	    %% ok = diablo_controller_mq_handler:connect(),
	    ok = diablo_controller_http_server:start(),

	    %% report
	    ok = diablo_auto_gen_report:report(stastic_per_shop, {2, 0, am}),
	    %% ticket
	    ok = diablo_auto_gen_report:ticket(preferential, {4, 0, am}),
	    %% retailer level
	    ok = diablo_auto_gen_report:retailer_level(check, {5, 0, am}),
	    %% birth sms
	    ok = diablo_auto_gen_report:birth(congratulation, {9, 0, am}),
	    

	    GCTask = {
	      %% {daily, [{0,  6,  am},
	      %% 	       {0, 7, am},
	      %% 	       {0, 8, am},
	      %% 	       {0,  9,  am},
	      %% 	       {0,  10,  am} 
	      %% 	      ]},
	      {daily, [{8,  00,  am},
	      	       {10, 00, am},
	      	       {11, 59, am},
		       {12, 59, am},
		       {1,  00,  pm},
	      	       {2,  00,  pm},
		       {3,  00,  pm},
	      	       {4,  00,  pm},
		       {5,  00,  pm},
	      	       {6,  00,  pm},
	      	       {8,  00,  pm},
	      	       {10,  00,  pm},
	      	       {11,  59,  pm}
	      	      ]},
	      {?MODULE, handle_gc, []}
	     },

	    ?cron:cron(GCTask), 
	    %% init right data
	    %% ok = diablo_controller_right_init:init(),
	     {ok, Pid};
	Error ->
	    Error
    end.


stop(_State) ->
    ok.

handle_gc() ->
    ?INFO("--- handle_gc ---", []),
    [erlang:garbage_collect(P) || P <- erlang:processes(),
				  {status, waiting} == erlang:process_info(P, status)],
    erlang:garbage_collect(),
    ok.
    


%%%===================================================================
%%% Internal functions
%%%===================================================================
