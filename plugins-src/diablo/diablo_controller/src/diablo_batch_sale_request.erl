-module(diablo_batch_sale_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = bsale_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)} 
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_employe"}) ->
    ?DEBUG("list employ with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),       
    case ?w_user_profile:get(employee, Merchant) of
	{ok, Employees} ->
	    ?utils:respond(200, batch, Req, Employees);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
%% action(Session, Req, {"delete_employe", EmployId}) ->
%%     ?DEBUG("delete employ with session ~p, id ~p", [Session, EmployId]),
%%     Merchant = ?session:get(merchant, Session),
%%     case ?employ:employ(delete, Merchant, EmployId) of
%% 	{ok, EmployId} ->
%% 	    ?w_user_profile:update(employee, Merchant),
%% 	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
%% 	{error, Error} ->
%% 	    ?utils:respond(200, Req, Error)
%%     end.

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
%%--------------------------------------------------------------------------------
%% batch sale
%%--------------------------------------------------------------------------------
action(Session, Req, {"new_batch_sale"}, Payload) ->
    ?DEBUG("new_batch_sale with session ~p, paylaod~n~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    UserId = ?session:get(id, Session), 
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload), 
    start(new_bsale, Req, Merchant, Invs, Base ++ [{<<"user">>, UserId}]);

action(Session, Req, {"check_batch_sale"}, Payload) ->
    ?DEBUG("chekc_batch_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?CHECK),

    case ?b_sale:bsale(check, Merchant, RSN, Mode) of
    	{ok, RSN} -> 
    	    ?utils:respond(
	       200, Req, ?succ(check_w_sale, RSN), {<<"rsn">>, ?to_b(RSN)});
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_batch_sale"}, Payload) ->
    ?DEBUG("get_batch_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case  ?v(<<"rsn">>, Payload) of
	undefined ->
	    ?utils:respond(200, Req, ?err(params_error, "get_batch_sale"));
	RSN ->
	    %% BaseSettings = ?w_report_request:get_setting(Merchant, ?DEFAULT_BASE_SETTING),
	    %% <<PColorSize:1/binary, PColor:1/binary, PSize:1/binary, _/binary>> = 
	    %% 	case ?w_report_request:get_config(<<"p_color_size">>, BaseSettings) of
	    %% 	    [] -> ?to_s(?PRINT_DEFAULT_MODE);
	    %% 	    <<"0">> -> ?to_s(?PRINT_DEFAULT_MODE);
	    %% 	    _Value -> ?to_s(_Value)
	    %% 	end,

	    
	    Merchant = ?session:get(merchant, Session), 
	    %% new
	    {ok, Sale} = ?b_sale:bsale(get_sale, Merchant, RSN),
	    %% ?DEBUG("Sale ~p", [Sale]),
	    
	    %% detail
	    {ok, Detail} = ?b_sale:bsale(get_sale_new_detail, Merchant, RSN),
	    %% ?DEBUG("Detail ~p", [Detail]),
	    
	    %% amount
	    {ok, Notes} = ?b_sale:bsale(get_sale_new_note, Merchant, RSN),
	    %% ?DEBUG("Notes ~p", [Notes]),
	    
	    Key = {<<"style_number">>, <<"brand_id">>, <<"shop_id">>},
	    DictNewNote = sale_new_note(to_dict, Key, Notes, dict:new()), 
	    %% ?DEBUG("dict note ~p", [dict:to_list(DictNewNote)]),
	    
	    Sort = sort_sale_new_detail(sort_by_color, Key, Detail, DictNewNote, []),
	    %% ?DEBUG("sort ~p", [Sort]),
	    
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"detail">>, {Sale}},
			     {<<"note">>, Sort}]
			   })
    end;

action(Session, Req, {"list_batch_sale"}, Payload) ->
    ?DEBUG("filter_batch_sale with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?b_sale:filter(total_sale_new, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?b_sale:filter(sale_new, ?to_a(Match), Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"list_batch_sale_new_detail"}, Payload) ->
    ?DEBUG("filter_batch_sale_note with session ~p, payload~n~p", [Session, Payload]),
    Merchant           = ?session:get(merchant, Session), 
    {struct, Mode}     = ?v(<<"mode">>, Payload),

    Order = ?v(<<"mode">>, Mode),
    Sort  = ?v(<<"sort">>, Mode),
    ShowNote = ?v(<<"note">>, Mode),

    NewPayload = proplists:delete(<<"mode">>, Payload), 
    {struct, Fields}     = ?v(<<"fields">>, Payload),

    CType = ?v(<<"ctype">>, Fields),
    SType = ?v(<<"type">>, Fields),

    PayloadWithCtype = ?w_sale_request:replace_condition_with_ctype(Merchant, CType, SType, Fields, NewPayload),
    ?DEBUG("PayloadWithCtype ~p", [PayloadWithCtype]),

    %% replace lbrand
    Like = ?value(<<"match">>, Payload, 'and'),
    Brand = ?v(<<"brand">>, Fields),
    %% LBrand = ?v(<<"lbrand">>, Fields),

    {struct, NewFields}  = ?v(<<"fields">>, PayloadWithCtype), 
    PayloadWithLBrand =
	?w_sale_request:replace_condition_with_lbrand(?to_a(Like), Merchant, Brand, NewFields, PayloadWithCtype),
    
    ?DEBUG("PayloadWithlbrand ~p", [PayloadWithLBrand]),
    
    case ShowNote of
	?NO -> 
	    ?pagination:pagination(
	       fun(Match, Conditions) ->
		       ?b_sale:filter(total_sale_new_detail, ?to_a(Match), Merchant, Conditions)
	       end,
	       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
		       ?b_sale:filter({sale_new_detail, mode(Order), Sort},
				      Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
	       end, Req, PayloadWithLBrand);
	?YES -> 
	    case
		?pagination:pagination(
		   no_response,
		   fun(Match, Conditions) ->
			   ?b_sale:filter(total_sale_new_detail, ?to_a(Match), Merchant, Conditions)
		   end,
		   fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
			   ?b_sale:filter(
			      {total_sale_new_detail, mode(Order), Sort},
			      Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
		   end, PayloadWithLBrand)
	    of
		{ok, Total, []} ->
		    ?utils:respond(
		       200, object, Req, {[{<<"ecode">>, 0}, {<<"total">>, Total}, {<<"data">>, []}]});
		{ok, Total, Data, Extra} ->
		    %% ?DEBUG("Total ~p, Data ~p, Extra ~p", [Total, Data, Extra]),
		    %% get rsn
		    %% {ok, AllColors} = ?w_user_profile:get(color, Merchant), 
		    Rsns = lists:foldr(
			     fun({D}, Acc) ->
				     Rsn = ?v(<<"rsn">>, D),
				     case lists:member(Rsn, Acc) of
					 true -> Acc;
					 false -> [Rsn|Acc]
				     end
			     end, [], Data),
		    %% note
		    {ok, SaleNotes} = ?b_sale:export(with_color_size, Merchant, [{<<"rsn">>, Rsns}]),
		    NoteDict = ?w_sale_request:sale_note(to_dict_with_rsn, SaleNotes, dict:new()),

		    DataWithNote =
			lists:foldr(
			  fun({D}, Acc) ->
				  %% ?DEBUG("D ~p", [D]),
				  Rsn = ?to_b(?v(<<"rsn">>, D)),
				  StyleNumber = ?to_b(?v(<<"style_number">>, D)),
				  UBrand = ?to_b(?v(<<"brand_id">>, D)),
				  Shop  = ?to_b(?v(<<"shop_id">>, D)),
				  Key = <<Rsn/binary,
					  <<"-">>/binary,
					  StyleNumber/binary,
					  <<"-">>/binary,
					  UBrand/binary,
					  <<"-">>/binary,
					  Shop/binary>>,

				  %% ?DEBUG("Key ~p", [Key]),
				  case dict:find(Key, NoteDict) of
				      error ->
					  [{D ++ [{<<"note">>, <<>>}]}] ++ Acc;
				      {ok, Find} ->
					  Note = ?to_b(?v(<<"note">>, Find)),
					  [{D ++ [{<<"note">>, Note}]}] ++ Acc
				  end
			  end, [], Data),

		    ?utils:respond(
		       200, object, Req, {[{<<"ecode">>, 0},
					   {<<"total">>, Total},
					   {<<"data">>, DataWithNote}] ++ Extra}); 
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

%%--------------------------------------------------------------------------------
%% batch saler
%%--------------------------------------------------------------------------------
action(Session, Req, {"new_batch_saler"}, Payload) ->
    ?DEBUG("new_batch_saler with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?b_saler:batch_saler(new, Merchant, Payload) of
	{ok, Id} ->
	    ?utils:respond(200, Req, ?succ(new_batch_saler, Id));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_batch_saler", BSalerId}, Payload) -> 
    ?DEBUG("update_batch_saler with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    case ?b_saler:batch_saler(get, Merchant, BSalerId) of
	{ok, OldBSaler} ->
	    case ?b_saler:batch_saler(update, Merchant, BSalerId, {Payload, OldBSaler}) of
		{ok, RId} ->
		    ?utils:respond(
		       200, Req, ?succ(update_w_retailer, RId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"list_batch_saler"}, Payload) ->
    ?DEBUG("filter_batch_saler with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    {struct, Mode}   = ?v(<<"mode">>, Payload),
    %% {struct, Fields} = ?v(<<"fields">>, Payload), 
    Order = ?v(<<"mode">>, Mode, ?SORT_BY_ID),
    Sort  = ?v(<<"sort">>, Mode),

    NewPayload = proplists:delete(<<"mode">>, Payload),
    ?DEBUG("new payload ~p", [NewPayload]), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?b_saler:filter(total_saler, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?b_saler:filter(
		  {saler, mode(Order), Sort}, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, NewPayload);

action(Session, Req, {"get_bsaler_batch"}, Payload) ->
    ?DEBUG("get_bsaler_batch with Session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    BSalerIds = ?v(<<"bsaler">>, Payload, []), 
    ?utils:respond(batch, fun() -> ?b_saler:batch_saler(get_batch, Merchant, BSalerIds) end, Req);

action(Session, Req, {"match_bsaler_phone"}, Payload) ->
    ?DEBUG("match_bsaler_phone with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Phone = ?v(<<"prompt">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 0),
    ?utils:respond(batch, fun() -> ?b_saler:match(phone, Merchant, {Mode, Phone}) end, Req);

action(Session, Req, {"match_bsale_rsn"}, Payload) ->
    ?DEBUG("match_bsale_rsn with session ~p, Payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session), 
    Shops = ?v(<<"shop">>, Payload),
    Prompt = ?v(<<"prompt">>, Payload),
    Mode = ?v(<<"mode">>, Payload, ?RSN_OF_ALL),

    {struct, Conditions} = ?v(<<"condition">>, Payload),
    ?utils:respond(
       batch,
       fun() ->
	       ?b_sale:match(
		  rsn, Merchant,
		  case Mode of
		      ?RSN_OF_ALL ->
			  {Prompt, Conditions};
		      ?RSN_OF_NEW ->
			  {Prompt, [{<<"shop">>, Shops}, {<<"type">>, ?NEW_SALE}|Conditions]}
		  end)
       end, Req).

sidebar(Session) -> 
    case ?right_request:get_shops(Session, bsale) of
	[] ->
	    ?menu:sidebar(level_2_menu, []);
	Shops ->
	    BookBatchSale = ?w_inventory_request:authen_shop_action(
			   {?book_batch_sale,
			    "book_bsale",
			    "批发订货", "glyphicon glyphicon-usd"}, Shops),
	    
	    BatchSale = ?w_inventory_request:authen_shop_action(
		       {?new_batch_sale,
			"new_bsale",
			"销售开单", "glyphicon glyphicon-usd"}, Shops), 

	    BatchReject = ?w_inventory_request:authen_shop_action(
			 {?reject_batch_sale,
			  "reject_bsale",
			  "销售退货",
			  "glyphicon glyphicon-arrow-left"}, Shops), 

	    ListBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?list_batch_sale,
		    "list_bsale_new",
		    "交易记录",
		    "glyphicon glyphicon-bookmark"}, Shops), 

	    NoteBatchSale =
		?w_inventory_request:authen_shop_action(
		   {?list_batch_sale_new_detail,
		    "list_bsale_new_detail",
		    "交易明细",
		    "glyphicon glyphicon-map-marker"}, Shops),
		
	    %% Merchant = ?session:get(merchant, Session), 
	    %% {ok, Setting} = ?wifi_print:detail(base_setting, Merchant, -1),

	    Saler = 
		[{"new_bsaler", "新增客户", "glyphicon glyphicon-plus"},
		 {"bsaler_detail", "客户详情", "glyphicon glyphicon-bookmark"}], 


	    L1 = ?menu:sidebar(
		    level_1_menu,
		    BookBatchSale
		    ++ BatchSale
		    ++ BatchReject
		    ++ ListBatchSale
		    ++ NoteBatchSale
		    ++ Saler),

	    %% L2 = ?menu:sidebar(level_2_menu, Saler),

	    L1 

    end.


start(new_bsale, Req, Merchant, Invs, Base) ->
    Round            = ?v(<<"round">>, Base, 1),
    ShouldPay        = ?v(<<"should_pay">>, Base),
    Datetime         = ?v(<<"datetime">>, Base),
    %% half an hour
    case abs(?utils:current_time(localtime2second) - ?utils:datetime2seconds(Datetime)) > 1800 of
	true ->
	    CurDatetime = ?utils:current_time(format_localtime), 
	    ?utils:respond(200,
			   Req,
			   ?err(wsale_invalid_date, "new_batch_sale"),
			   [{<<"fdate">>, Datetime},
			    {<<"bdate">>, ?to_b(CurDatetime)}]);
	false-> 
	    case check_inventory(oncheck, Round, 0, ShouldPay, Invs) of
		{ok, _} -> 
		    case ?b_sale:bsale(new, Merchant, lists:reverse(Invs), Base) of 
			{ok, RSN} -> 
			    ?utils:respond(
			       200, Req, ?succ(new_w_sale, RSN),
			       [{<<"rsn">>, ?to_b(RSN)}]); 
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{error, EInv} ->
		    StyleNumber = ?v(<<"style_number">>, EInv),
		    ?utils:respond(
		       200,
		       Req,
		       ?err(wsale_invalid_inv, StyleNumber),
		       [{<<"style_number">>, StyleNumber},
			{<<"order_id">>, ?v(<<"order_id">>, EInv)}]);
		{error, Moneny, ShouldPay} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(wsale_invalid_pay, Moneny),
		       [{<<"should_pay">>, ShouldPay},
			{<<"check_pay">>, Moneny}])
	    end
    end.

check_inventory(oncheck, Round, Moneny, ShouldPay, []) ->
    ?DEBUG("Moneny ~p, ShouldPay, ~p", [Moneny, ShouldPay]),
    case Round of
	1 -> 
	    case round(Moneny) == ShouldPay of
		true -> {ok, none};
		false -> {error, round(Moneny), ShouldPay}
	    end;
	0 ->
	    case Moneny == ShouldPay of
		true -> {ok, none};
		false -> {error, Moneny, ShouldPay}
	    end
    end;

check_inventory(oncheck, Round, Money, ShouldPay, [{struct, Inv}|T]) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Amounts = ?v(<<"amounts">>, Inv),
    Count = ?v(<<"sell_total">>, Inv),
    DCount = lists:foldr(
	       fun({struct, A}, Acc)->
		       ?v(<<"sell_count">>, A) + Acc
	       end, 0, Amounts),

    FPrice = ?v(<<"rprice">>, Inv),
    Calc = FPrice * Count, 
    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true -> check_inventory(oncheck, Round, Money + Calc, ShouldPay, T);
		false -> {error, Inv}
	    end
    end.


%% calc_count(reject, [], Total) ->
%%     Total;
%% calc_count(reject, [{struct, Inv}|T], Total) ->
%%     InvTotal = ?v(<<"sell_total">>, Inv),
%%     calc_count(reject, T, Total + InvTotal).

sale_new_note(to_dict, _key, [], Dict) ->
    %% ?DEBUG("Dict ~p", [dict:to_list(Dict)]),
    Dict;
sale_new_note(to_dict, {K1, K2, K3} = K, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(K1, H)),
    Brand = ?to_b(?v(K2, H)),
    Shop  = ?to_b(?v(K3, H)),

    %% Color = ?to_b(?v(<<"color">>, H)),
    Key = <<StyleNumber/binary, <<"-">>/binary, Brand/binary, <<"-">>/binary, Shop/binary>>, 
    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		dict:store(Key, [{H}], Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  [{H}] ++ V 
		  end,
		  Dict)
	end,

    sale_new_note(to_dict, K, T, DictNew).


sort_sale_new_detail(sort_by_color, _Key, [], _DictNote, Acc) ->
    Acc; 
sort_sale_new_detail(sort_by_color, {K1, K2, K3} = K, [{H}|T], DictNote, Acc) ->
    ?DEBUG("H ~p", [H]),
    ShopId      = ?to_b(?v(K3, H)),

    StyleNumber = ?v(K1, H),
    BrandId     = ?to_b(?v(K2, H)),
    Brand     = ?v(<<"brand">>, H), 
    Type      = ?v(<<"type">>, H),
    
    %% Season      = ?v(<<"season">>, H), 
    TagPrice    = ?v(<<"tag_price">>, H),
    RPrice      = ?v(<<"rprice">>, H),
    RDiscount   = ?v(<<"rdiscount">>, H), 
    Total       = ?v(<<"total">>, H),
    
    Key = <<StyleNumber/binary, <<"-">>/binary, BrandId/binary, <<"-">>/binary, ShopId/binary>>, 
    case dict:find(Key, DictNote) of
	{ok, Notes} ->
	    OneDict = ?w_inventory_request:one_stock_note(sort_by_color, <<"color_id">>, Notes, dict:new()),

	    NoteDetails = 
		dict:fold(
		  fun(C, OneNotes, Acc1) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({One}, {Amount, Descs}) ->
					Size = ?v(<<"size">>, One),
					OneAmount = ?v(<<"amount">>, One),
					{Amount + OneAmount,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(OneAmount) ++ ";"} 
				end, {0, []}, OneNotes),

			  [{C, TotalOfColor, SizeDescs}|Acc1]

		  end, [], OneDict),

	    N = {[{<<"style_number">>, StyleNumber},
		  {<<"brand_id">>, ?to_i(BrandId)},
		  {<<"brand">>, Brand},
		  {<<"type">>, Type},
		  {<<"total">>, Total},
		  {<<"tagPrice">>, TagPrice},
		  {<<"rprice">>, RPrice},
		  {<<"rdiscount">>, RDiscount},
		  {<<"note">>,
		   lists:foldr(
		     fun({ColorId, TotalOfColor, SizeDesc}, Acc1) ->
			     [{[{<<"color_id">>, ColorId},
				{<<"total">>, TotalOfColor},
				{<<"size">>, ?to_b(SizeDesc)}]}|Acc1]
		     end, [], NoteDetails)}]},
	    sort_sale_new_detail(sort_by_color, K, T, DictNote, [N|Acc]);
	error ->
	    sort_sale_new_detail(sort_by_color, K, T, DictNote, Acc)
    end.

mode(0) -> use_id.
