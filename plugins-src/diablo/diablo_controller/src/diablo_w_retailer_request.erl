-module(diablo_w_retailer_request).

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
    {ok, HTMLOutput} = wretailer_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "wretailerApp"},
			  {ngcontroller, "wretailerCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_retailer"}) ->
    ?DEBUG("list w_retailer with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(retailer, Merchant) end, Req);


action(Session, Req, {"del_w_retailer", Id}) ->
    ?DEBUG("delete_w_retailer with session ~p, Id ~p", [Session, Id]),

    Merchant = ?session:get(merchant, Session),
    case ?w_retailer:retailer(delete, Merchant, Id) of
	{ok, RetailerId} ->
	    ?utils:respond(200, Req, ?succ(delete_w_retailer, RetailerId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_w_retailer_charge"}) ->
    ?DEBUG("list w_retailer_charge with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    %% ?utils:respond(
    %%    batch, fun() -> ?w_user_profile:get(retailer, Merchant) end, Req).
    ?utils:respond(
       batch, fun() -> ?w_retailer:charge(list, Merchant) end, Req);


action(Session, Req, {"list_w_retailer_score"}) ->
    ?DEBUG("list w_retailer_score with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session), 
    %% ?utils:respond(
    %%    batch, fun() -> ?w_user_profile:get(retailer, Merchant) end, Req).
    ?utils:respond(
       batch, fun() -> ?w_user_profile:get(score, Merchant) end, Req).



%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_retailer"}, Payload) ->
    ?DEBUG("new wretailer with session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 

    case ?w_retailer:retailer(new, Merchant, Payload) of
	{ok, RId} ->
	    ?utils:respond(
	       200, Req, ?succ(add_w_retailer, RId), {<<"id">>, RId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
	

action(Session, Req, {"update_w_retailer", Id}, Payload) ->
    ?DEBUG("update_w_retailer with Session ~p~npaylaod ~p",
	   [Session, Payload]),
    
    Merchant = ?session:get(merchant, Session),
    

    case ?w_retailer:retailer(update, Merchant, Id, Payload) of
	{ok, RId} ->
	    ?utils:respond(
	       200, Req, ?succ(update_w_retailer, RId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_retailer_score", Id}, Payload) ->
    ?DEBUG("update_retailer_score with Session ~p~npaylaod ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    Score = ?v(<<"score">>, Payload),
    case ?w_retailer:retailer(update_score, Merchant, Id, Score) of
	{ok, RId} ->
	    ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(update_w_retailer, RId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"check_w_retailer_password", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Password = ?v(<<"password">>, Payload),

    case ?w_retailer:retailer(check_password, Merchant, Id, Password) of
	{ok, Id} ->
	    ?utils:respond(
	       200, Req, ?succ(check_w_retailer_password, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"reset_w_retailer_password", Id}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Password = ?v(<<"password">>, Payload),

    case ?w_retailer:retailer(reset_password, Merchant, Id, Password) of
	{ok, Id} ->
	    ?utils:respond(
	       200, Req, ?succ(reset_w_retailer_password, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% 
%% charge
%%
action(Session, Req, {"add_w_retailer_charge"}, Payload) ->
    ?DEBUG("add_w_retailer_charge with session ~p, payload ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),

    case ?w_retailer:charge(new, Merchant, Payload) of
	{ok, Id} ->
	    ?utils:respond(
	       200, Req, ?succ(add_retailer_charge, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"del_w_retailer_charge"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ChargeId = ?v(<<"cid">>, Payload),
    case ?w_retailer:charge(delete, Merchant, ChargeId) of
	{ok, Id} -> 
	    ?utils:respond(
	       200, Req, ?succ(delete_retailer_charge, Id)),
	    ?w_user_profile:update(charge, Merchant);
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_recharge"}, Payload) ->
    ?DEBUG("new_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    ShopId = ?v(<<"shop">>, Payload),
    ShopName = case ?w_user_profile:get(shop, Merchant, ShopId) of
		   {ok, []} -> ShopId;
		   {ok, [{Shop}]} -> ?v(<<"name">>, Shop)
	       end,
    
    case ?w_retailer:charge(recharge, Merchant, Payload) of
	{ok, {SN, Mobile, CBalance, Balance, Score}} -> 
	    ?w_user_profile:update(retailer, Merchant),
	    try
		{ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1), 
		case ?to_i(?v(<<"recharge_sms">>, Setting, 0)) of
		    0 -> ?utils:respond(200, Req, ?succ(new_recharge, SN),
					[{<<"sms_code">>, 0}]);
		    1 ->
			{SMSCode, _} =
			    ?notify:sms_notify(
			       Merchant, {ShopName, Mobile, 0, CBalance, Balance, Score}),
			?utils:respond(200,
				       Req,
				       ?succ(new_recharge, SN),
				       [{<<"sms_code">>, SMSCode}]) 
		end
	    catch
		_:{badmatch, _Error} ->
		    {Code1, _} =  ?err(sms_send_failed, Merchant),
		    ?utils:respond(
		       200,
		       Req,
		       ?succ(new_recharge, SN), [{<<"sms_code">>, Code1}])
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_recharge"}, Payload) ->
    ?DEBUG("delete_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    ChargeId = ?v(<<"charge_id">>, Payload),
    
    case ?w_retailer:charge(delete_recharge, Merchant, ChargeId) of
	{ok, ChargeId} ->
	    ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(200, Req, ?succ(delete_recharge, ChargeId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_recharge"}, Payload) ->
    ?DEBUG("update_recharge with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    ChargeId = ?v(<<"charge_id">>, Payload),

    case ?w_retailer:charge(delete_recharge, Merchant, {ChargeId, Payload}) of
	{ok, ChargeId} ->
	    %% ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(200, Req, ?succ(update_recharge, ChargeId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"filter_retailer_detail"}, Payload) ->
    ?DEBUG("filter_retailer with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_retailer, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  retailer, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"filter_charge_detail"}, Payload) ->
    ?DEBUG("filter_charge_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_charge_detail, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  charge_detail, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);


action(Session, Req, {"filter_ticket_detail"}, Payload) ->
    ?DEBUG("filter_ticket_detail with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?w_retailer:filter(
		  total_ticket_detail, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?w_retailer:filter(
		  ticket_detail, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);


action(Session, Req, {"effect_w_retailer_ticket"}, Payload) ->
    ?DEBUG("effect_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    TicketId = ?v(<<"tid">>, Payload),

    case ?w_retailer:ticket(effect, Merchant, TicketId) of
	{ok, TicketId} ->
	    ?utils:respond(200, Req, ?succ(effect_ticket, TicketId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"consume_w_retailer_ticket"}, Payload) ->
    ?DEBUG("consume_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    TicketId = ?v(<<"tid">>, Payload),
    Comment = ?v(<<"comment">>, Payload, []),

    {ok, Scores}=?w_user_profile:get(score, Merchant),
    Score2Money =
	case lists:filter(fun({S})-> ?v(<<"type_id">>, S) =:= 1 end, Scores) of
	    [] -> [];
	    [{_Score2Money}] -> _Score2Money
	end, 
    ?DEBUG("score2money ~p, ", [Score2Money]),
    
    case ?w_retailer:ticket(consume, Merchant, {TicketId, Comment, Score2Money}) of
	{ok, TicketId} ->
	    ?w_user_profile:update(retailer, Merchant),
	    ?utils:respond(200, Req, ?succ(consume_ticket, TicketId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"get_w_retailer_ticket"}, Payload) ->
    ?DEBUG("get_w_retailer_ticket with session ~p, payload ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),

    case 
	case ?v(<<"mode">>, Payload, 0) of
	    0 ->
		RetailerId = ?v(<<"retailer">>, Payload),
		?w_retailer:get_ticket(by_retailer, Merchant, RetailerId);
	    1 ->
		Batch = ?v(<<"batch">>, Payload),
		?w_retailer:get_ticket(by_batch, Merchant, Batch)
	end
    of 
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, {Value}}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%% 
%% charge
%%
action(Session, Req, {"add_w_retailer_score"}, Payload) ->
    ?DEBUG("add_w_retailer_score with session ~p, payload ~p",
	   [Session, Payload]),

    Merchant = ?session:get(merchant, Session),

    case ?w_retailer:score(new, Merchant, Payload) of
	{ok, Id} ->
	    ?w_user_profile:update(score, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(add_retailer_score, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"export_w_retailer"}, Payload) ->
    ?DEBUG("export_w_retailer with session ~p, payload ~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    case ?w_retailer:retailer(list, Merchant) of
	[] -> ?utils:respond(200, Req, ?err(wretailer_export_none, Merchant));
	{ok, Retailers} ->
	    {ok, ExportFile, Url}
		= ?utils:create_export_file("retailer", Merchant, UserId),
	    SysVips = ?gen_report:sys_vip_of(merchant, Merchant),
	    ?DEBUG("sysvips ~p", [SysVips]),
	    NewRetailers = [{R} || {R} <- Retailers, not lists:member(?v(<<"id">>, R), SysVips)],
	    %% ?DEBUG("NewRetailers ~p", [NewRetailers]),

	    case file:open(ExportFile, [append, raw]) of
		{ok, Fd} ->
		    try
			DoFun = fun(C) -> ?utils:write(Fd, C) end,
			csv_head(retailer, DoFun),
			do_write(retailer, DoFun, 1, NewRetailers),
			ok = file:datasync(Fd),
			ok = file:close(Fd)
		    catch
			T:W -> 
			    file:close(Fd),
			    ?DEBUG("trace export:T ~p, W ~p~n~p",
				   [T, W, erlang:get_stacktrace()]),
			    ?utils:respond(200, Req, ?err(wretailer_export_error, W)) 
		    end,
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"url">>, ?to_b(Url)}]}); 
		{error, Error} ->
		    ?utils:respond(200, Req, ?err(wretailer_export_error, Error))
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"match_retailer_phone"}, Payload) ->
    ?DEBUG("match_retailer_phone with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Phone = ?v(<<"prompt">>, Payload),
    ?utils:respond(batch, fun() -> ?w_retailer:match(phone, Merchant, Phone) end, Req).

sidebar(Session) -> 
    S1 = [{"wretailer_detail", "会员详情", "glyphicon glyphicon-book"}],
    
    S2 = 
	case ?right_auth:authen(?new_w_retailer, Session) of
	    {ok, ?new_w_retailer} ->
		[{"wretailer_new", "新增会员", "glyphicon glyphicon-plus"}];
	    _ -> []
	end,

    S3 = [{"wretailer_charge_detail", "充值记录", "glyphicon glyphicon-bookmark"}],
    

    Recharge =
	[{{"promotion", "充值积分", "glyphicon glyphicon-superscript"},
	  
	  [{"recharge_detail", "充值方案", "icon-large icon-star-half"},
	   {"score_detail", "积分方案", "icon-large icon-lock"}]
	
	 }],

    Ticket = case ?right_auth:authen(?filter_ticket_detail, Session) of
		 {ok, ?filter_ticket_detail} ->
		     [{"wretailer_ticket_detail", "电子卷", "glyphicon glyphicon-certificate"}];
		 _ -> []
	     end,
    
    L1 = ?menu:sidebar(level_1_menu, S2 ++ S1 ++ S3 ++ Ticket),
    L2 = ?menu:sidebar(level_2_menu, Recharge),

    L1 ++ L2.

csv_head(retailer, Do) ->
    Do("序号,名称,类型,联系方式,累计消费,累计积分,所在店铺,日期").

do_write(retailer, _Do, _Count, []) ->
    ok;
do_write(retailer, Do, Count, [{H}|T]) ->
    %% ?DEBUG("retailer ~p", [H]),
    %% Id      = ?v(<<"id">>, H),
    Name    = ?v(<<"name">>, H),
    Type    = retailer_type(?v(<<"type_id">>, H)),
    Mobile  = ?v(<<"mobile">>, H, []),
    Consume = ?v(<<"consume">>, H),
    Score   = ?v(<<"score">>, H),
    Shop    = ?v(<<"shop">>, H),
    Entry   = ?v(<<"entry_date">>, H), 

    L = "\r\n"
	++ ?to_s(Count) ++ ?d
	++ ?to_s(Name) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?to_s(Mobile) ++ ?d
	++ ?to_s(Consume) ++ ?d
	++ ?to_s(Score) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Entry) ++ ?d,
    
    Do(L),
    do_write(retailer, Do, Count + 1, T).

retailer_type(0) -> "普通会员";
retailer_type(1) -> "充值会员";
retailer_type(_) -> "未知类型".
		    
       
