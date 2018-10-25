%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2018, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 14 Oct 2018 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_batch_saler).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-export([batch_saler/3, batch_saler/4, match/3]).
-export([filter/4, filter/6]).

-define(SERVER, ?MODULE). 

-record(state, {prompt=0::integer()}).

%%%===================================================================
%%% API
%%%===================================================================
batch_saler(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {new_saler, Merchant, Attrs});

batch_saler(get, Merchant, BSalerId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_batch, Merchant, [BSalerId]});

batch_saler(get_batch, Merchant, BSalers) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_batch, Merchant, BSalers}).

batch_saler(update, Merchant, BSalerId, {Attrs, OldAttrs}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_saler, Merchant, BSalerId, {Attrs, OldAttrs}}).

filter(total_saler, 'and', Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_saler, Merchant, Conditions}).

filter({saler, Order, Sort}, 'and', Merchant, Conditions, CurrentPage, ItemsPerPage) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {{filter_saler, Order, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage}).

match(phone, Merchant, {Mode, Phone}) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {match_phone, Merchant, {Mode, Phone}}).


start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [Name], []).

init([Name]) ->
    [Merchant|_] = lists:reverse(string:tokens(?to_s(Name), "-")),
    Prompt = ?w_retailer:default_profile(prompt, Merchant),
    {ok, #state{prompt=Prompt}}.

handle_call({new_saler, Merchant, Attrs}, _From, State) ->
    ?DEBUG("new_saler: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Shop     = ?v(<<"shop">>, Attrs, ?INVALID_OR_EMPTY),
    Region   = ?v(<<"region">>, Attrs, ?INVALID_OR_EMPTY),
    Name     = ?v(<<"name">>, Attrs),
    PinYin   = ?v(<<"py">>, Attrs),
    Type     = ?v(<<"type">>, Attrs), 
    Balance  = ?v(<<"balance">>, Attrs, 0),
    Mobile   = ?v(<<"mobile">>, Attrs, []),
    Address  = ?v(<<"address">>, Attrs, []),
    Remark   = ?v(<<"remark">>, Attrs, []),
    
    Sql = "select id, name, mobile from batchsaler"
	%% ++ " where name = " ++ "\'" ++ ?to_s(Name) ++ "\'"
        ++ " where merchant = " ++ ?to_s(Merchant)
	++ " and mobile = " ++ "\'" ++ ?to_s(Mobile) ++ "\'" 
        ++ " and deleted = " ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
        {ok, []} -> 
            Sql2 = "insert into batchsaler ("
		"shop, region, name, py, type, balance, mobile, address, remark, merchant, entry_date)"
                ++ " values ("
		++ ?to_s(Shop) ++ ","
		++ ?to_s(Region) ++ ","
                ++ "\'" ++ ?to_s(Name) ++ "\',"
		++ "\'" ++ ?to_s(PinYin) ++ "\',"
		++ ?to_s(Type) ++ ","
                ++ ?to_s(Balance) ++ ","
                ++ "\'" ++ ?to_s(Mobile) ++ "\',"
                ++ "\'" ++ ?to_s(Address) ++ "\',"
		++ "\'" ++ ?to_s(Remark) ++ "\'," 
                ++ ?to_s(Merchant) ++ ","
                ++ "\'" ++ ?utils:current_time(format_localtime) ++ "\');",
            Reply = ?sql_utils:execute(insert, Sql2),
            {reply, Reply, State}; 
        {ok, _Any} ->
            {reply, {error, ?err(batch_saler_exist, Name)}, State};
        Error ->
            {reply, Error, State}
    end;

handle_call({update_saler, Merchant, BSalerId, {Attrs, OldAttrs}}, _From, State) ->
    ?DEBUG("update_retailer with merchant ~p, BSalerId ~p~nattrs ~p, oldattrs ~p",
	   [Merchant, BSalerId, Attrs, OldAttrs]),

    Shop     = ?v(<<"shop">>, Attrs), 
    Name     = ?v(<<"name">>, Attrs),
    Pinyin   = ?v(<<"py">>, Attrs),
    Mobile   = ?v(<<"mobile">>, Attrs),
    %% Balance  = ?v(<<"balance">>, Attrs),
    Region   = ?v(<<"region">>, Attrs),
    Address  = ?v(<<"address">>, Attrs),
    Comment  = ?v(<<"comment">>, Attrs),
    

    OldShop     = ?v(<<"shop_id">>, OldAttrs), 
    OldType     = ?v(<<"type_id">>, OldAttrs),
    OldBalance  = ?v(<<"balance">>, OldAttrs),
    OldRegion   = ?v(<<"region_id">>, OldAttrs),

    Balance  = case ?v(<<"balance">>, Attrs) of
		   undefined -> OldBalance;
		   _Balance -> ?to_f(_Balance)
	       end,

    Type     = case ?v(<<"type">>, Attrs) of
		   undefined -> OldType;
		   _Type -> _Type
	       end,
    
    IsMobileModified = 
	case Mobile =:= undefined of
	    true -> {ok, []};
	    false -> 
		Sql = case Type =:= ?SYSTEM_RETAILER of
			  true ->
			      "select id, name, mobile, address"
				  ++ " from batchsaler" 
				  ++ " where merchant=" ++ ?to_s(Merchant)
				  ++ " and name=" ++ "\'" ++ ?to_s(Name) ++ "\'" 
				  ++ " and mobile=" ++ "\'" ++ ?to_s(Mobile) ++ "\'" 
				  ++ " and deleted=" ++ ?to_s(?NO);
			  false ->
			      "select id, name, mobile, address"
				  ++ " from batchsaler" 
				  ++ " where merchant=" ++ ?to_s(Merchant)
				  ++ " and mobile=" ++ "\'" ++ ?to_s(Mobile) ++ "\'"
				  ++ " and type!=" ++ ?to_s(?SYSTEM_RETAILER) 
				  ++ " and deleted=" ++ ?to_s(?NO)
		      end,
		?sql_utils:execute(read, Sql)
	end,

    case IsMobileModified of 
	{ok, []} -> 

	    Updates = ?utils:v(name, string, Name) 
		++ ?utils:v(py, string, Pinyin)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(region, integer, ?supplier:get_modified(Region, OldRegion))
		++ ?utils:v(shop, integer, ?supplier:get_modified(Shop, OldShop))
		++ ?utils:v(address, string, Address)
		++ ?utils:v(remark, string, Comment)
		++ ?utils:v(type, integer, ?supplier:get_modified(Type, OldType)) 
		++ ?utils:v(balance, float, ?supplier:get_modified(Balance, OldBalance)),

	    Sql1 = "update batchsaler set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(BSalerId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, BSalerId), 
	    {reply, Reply, State}; 
	{ok, _} ->
	    {reply, {error, ?err(batch_saler_exist, Mobile)}, State};
	Error ->
	    {reply, Error, State}
    end;
    

handle_call({total_saler, Merchant, Conditions}, _From, State) ->
    ?DEBUG("total_saler: merchant ~p, conditions ~p", [Merchant, Conditions]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions), 
    Sql = "select count(*) as total"
	", sum(balance) as balance"
	" from batchsaler"
	" where merchant=" ++ ?to_s(Merchant) 
	++ ?sql_utils:condition(proplists, NewConditions),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({{filter_saler, Order, Sort}, Merchant, Conditions, CurrentPage, ItemsPerPage}, _From, State) ->
    ?DEBUG("filter_retailer: order ~p, sort ~p, merchant ~p, conditions ~p, page ~p",
	   [Order, Sort, Merchant, Conditions, CurrentPage]),
    {_StartTime, _EndTime, NewConditions} = ?sql_utils:cut(prefix, Conditions),
    
    Sql = "select a.id"
	", a.shop as shop_id"
	", a.region as region_id" 
	", a.name" 
	", a.type as type_id"
	", a.balance"
	", a.mobile"
	", a.address"
	", a.merchant"
	", a.remark" 
	", a.entry_date"

	", b.name as shop_name"
	", c.name as region_name"
	" from batchsaler a"
	" left join shops b on a.shop=b.id"
	" left join region c on a.region=c.id"
	" where a.merchant=" ++ ?to_s(Merchant) 
	++ ?sql_utils:condition(proplists, NewConditions)
	++ ?sql_utils:condition(page_desc, {Order, Sort}, CurrentPage, ItemsPerPage),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_phone, Merchant, {Mode, Phone}}, _From, #state{prompt=Prompt} = State) ->
    ?DEBUG("match_phone: merchant ~p, Mode ~p, Phone ~p, state ~p", [Merchant, Mode, Phone, State]),

    NewPrompt = 
	case Prompt =:= 0 of
	    true -> ?w_retailer:default_profile(prompt, Merchant);
	    false -> Prompt
	end,

    First = string:substr(?to_s(Phone), 1, 1),
    Last  = string:substr(?to_s(Phone), string:len(?to_s(Phone))),
    Match = string:strip(?to_s(Phone), both, $/),

    Name = case Mode of
	       0 -> "mobile";
	       1 -> "py";
	       2 -> "name"
	   end,

    Sql = "select id"
	", name"
	", balance"
	", py"
	", mobile" 
	", shop as shop_id"
	", region as region_id"
	", type as type_id"
	", merchant" 
	" from batchsaler"

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
	++ " limit " ++ ?to_s(NewPrompt),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, case NewPrompt =:= Prompt of
		       true -> State;
		       false ->
			   ?w_user_profile:update(setting, Merchant),
			   State#state{prompt=NewPrompt}
		   end};


handle_call({get_batch, Merchant, BSalers}, _From, State) ->
    ?DEBUG("get_bsaler_batch with merchant ~p, BSalers ~p", [Merchant, BSalers]),
    Sql = "select id"
	", name"
	", py"
	", balance"
	", mobile"
	", shop as shop_id"
	", region as region_id"
	", type as type_id"
	", merchant" 
	" from batchsaler"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, [{<<"id">>, lists:usort(BSalers)}]),

    Reply = case length(BSalers) =:= 1 of
		true -> ?sql_utils:execute(s_read, Sql);
		false -> ?sql_utils:execute(read, Sql)
	    end,
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





