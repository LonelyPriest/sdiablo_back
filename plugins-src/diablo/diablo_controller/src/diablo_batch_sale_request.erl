-module(diablo_batch_sale_request).

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
    end;

action(Session, Req, {"list_sys_bsaler"}) ->
    ?DEBUG("list sys batch saler with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    {ok, Shops}   = ?w_user_profile:get(user_shop, Merchant, Session),
    ShopIds = lists:foldr(fun({Shop}, Acc) ->
				  ShopId = ?v(<<"shop_id">>, Shop),
				  case lists:member(ShopId, Acc) of
				      true -> Acc;
				      false ->[ShopId|Acc]
				  end
			  end, [], Shops),
    ?DEBUG("ShopIds ~p", [ShopIds]),
    ?utils:respond(batch, fun() -> ?w_user_profile:get(sys_bsaler, Merchant, ShopIds) end, Req).

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

action(Session, Req, {"check_print_batch_sale"}, Payload) ->
    ?DEBUG("chekc_print_batch_sale with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload, []),
    Mode = ?v(<<"mode">>, Payload, ?PRINTED),

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
	    case ?v(<<"mode">>, Payload) of
		0 -> %% print mode
		    Merchant = ?session:get(merchant, Session), 
		    Conditions = [{<<"rsn">>, RSN}],
		    %% new
		    {ok, Sale} = ?b_sale:bsale(get_sale, Merchant, Conditions),
		    %% ?DEBUG("Sale ~p", [Sale]),

		    %% detail
		    {ok, Detail} = ?b_sale:bsale(get_sale_new_detail, Merchant, Conditions),
		    %% ?DEBUG("Detail ~p", [Detail]),

		    %% amount
		    {ok, Notes} = ?b_sale:bsale(get_sale_new_note, Merchant, Conditions),
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
				   });
		1 -> %% update mode
		    Merchant = ?session:get(merchant, Session),
		    Conditions = [{<<"rsn">>, RSN}],
		    
		    %% new
		    {ok, Sale} = ?b_sale:bsale(get_sale, Merchant, Conditions),
		    %% ?DEBUG("Sale ~p", [Sale]), 
		    %% detail
		    {ok, Detail} = ?b_sale:bsale(get_sale_new_transe, Merchant, Conditions), 
		    ?utils:respond(200, object, Req,
				   {[{<<"ecode">>, 0},
				     {<<"sale">>, {Sale}},
				     {<<"detail">>, Detail}]
				   })
	    end
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

action(Session, Req, {"list_batch_sale_stastic_note"}, Payload) ->
    ?DEBUG("list_batch_sale_stastic_note: session ~p, payload~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    {struct, NewPayload} = ?v(<<"condition">>, Payload),
    CType = ?v(<<"ctype">>, NewPayload),
    SType = ?v(<<"type">>, NewPayload),
    PayloadWithCtype = ?w_sale_request:replace_condition_with_ctype(Merchant, CType, SType, NewPayload),
    ?DEBUG("PayloadWithCtype ~p", [PayloadWithCtype]),
    {ok, Q} = ?b_sale:bsale(get_sale_rsn, Merchant, PayloadWithCtype),
    case Q of
	[] ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"total">>, 0},
			     {<<"note">>, []}]});
	_ ->
	    {struct, NewConditions} =
		?v(<<"fields">>,
		   ?w_inventory_request:filter_condition(
		      trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], PayloadWithCtype)),

	    ?DEBUG("NewConditions ~p", [NewConditions]),
	    {ok, Colors} = ?w_user_profile:get(color, Merchant), 
	    {ok, Sales} = ?b_sale:export(sale_new_detail, Merchant, NewConditions),
	    ?DEBUG("sales ~p", [Sales]),
	    NoteConditions = [{<<"rsn">>, ?v(<<"rsn">>, NewConditions, [])}],
	    {ok, SaleNotes} = ?b_sale:export(sale_new_note, Merchant, NoteConditions),

	    SortTranses = ?w_sale_request:sale_trans(to_dict, Sales, dict:new()),
	    DictNotes = ?w_sale_request:sale_note(to_dict, SaleNotes, dict:new()),

	    ?DEBUG("SortTranses ~p", [SortTranses]),
	    ?DEBUG("DictNotes ~p", [DictNotes]),
	    {Amount, Notes} = ?w_sale_request:print_wsale_new(sort_by_color, Colors, SortTranses, DictNotes, {0, []}),

	    Sort = lists:sort(
		     fun({N1}, {N2}) ->
			     Firm1 = ?v(<<"firm_id">>, N1),
			     Firm2 = ?v(<<"firm_id">>, N2),
			     Firm1 > Firm2
		     end, Notes),

	    %% ?DEBUG("sort ~p", [Sort]),
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"total">>, Amount},
			     {<<"note">>, Sort}]})
    end;

action(Session, Req, {"update_batch_sale"}, Payload) ->
    ?DEBUG("update_w_sale with session ~p~npaylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    Invs            = ?v(<<"inventory">>, Payload, []),
    {struct, Base}  = ?v(<<"base">>, Payload),
    RSN             = ?v(<<"rsn">>, Base),
    
    case ?b_sale:bsale(get_sale, Merchant, [{<<"rsn">>, RSN}]) of
	{ok, OldBase} -> 
	    case ?b_sale:bsale(update_sale, Merchant, lists:reverse(Invs), {Base, OldBase}) of
		{ok, RSN} -> 
		    ?utils:respond(200, Req, ?succ(update_w_sale, RSN), [{<<"rsn">>, ?to_b(RSN)}]); 
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_batch_sale"}, Payload) ->
    ?DEBUG("delete_batch_sale: session ~p, payload ~p", [Payload]),
    Merchant = ?session:get(merchant, Session),
    RSN = ?v(<<"rsn">>, Payload), 
    Conditions = [{<<"rsn">>, RSN}],
    case ?b_sale:bsale(get_sale, Merchant, Conditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_empty, RSN));
	{ok, SaleProps} ->
	    case ?b_sale:bsale(get_sale_new_transe, Merchant, Conditions) of
		{ok, []} -> 
		    case ?b_sale:bsale(delete_sale, Merchant, SaleProps, Conditions) of
			{ok, RSN} ->
			    ?utils:respond(
			       200, Req, ?succ(update_w_sale, RSN), Conditions);
			{error, Error} ->
			    ?utils:respond(200, Req, Error)
		    end;
		{ok, _} ->
		    ?utils:respond(200, Req, ?err(wsale_trans_detail_not_empty, RSN)); 
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"export_batch_sale"}, Payload) ->
    ?DEBUG("export_batch_sale:session ~p, paylaod ~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    UserId      = ?session:get(id, Session),
    ExportType  = export_type(?v(<<"type">>, Payload, 0)), 
    {struct, Conditions} = ?v(<<"condition">>, Payload),
    
    NewConditions = 
	case ExportType of
	    sale_new_detail ->
		{struct, CutConditions} = ?v(<<"condition">>, Payload),
		{ok, Q} = ?b_sale:bsale(get_sale_rsn, Merchant, CutConditions),
		{struct, C} = ?v(<<"fields">>,
				 ?w_inventory_request:filter_condition(
				    trans_note, [?v(<<"rsn">>, Rsn) || {Rsn} <- Q], CutConditions)),
		C;
	    sale_new -> Conditions
	end,

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    ExportColorSize = ?to_i(?v(<<"export_note">>, BaseSetting, 0)),
    ExportCode = ?to_i(?v(<<"export_code">>, BaseSetting, 0)),

    case ?b_sale:export(ExportType, Merchant, NewConditions) of
	{ok, []} ->
	    ?utils:respond(200, Req, ?err(wsale_export_no_date, Merchant));
	{ok, Transes} -> 
	    %% write to file 
	    {ok, ExportFile, Url} = ?utils:create_export_file("btrans", Merchant, UserId), 
	    case ExportColorSize =:= 1 andalso ExportType =:= sale_new_note of
		true ->
		    %% only rsn
		    NoteConditions = [{<<"rsn">>, ?v(<<"rsn">>, NewConditions, [])}],
		    case ?b_sale:export(sale_new_transe, Merchant, NoteConditions) of
			[] ->
			    ?utils:respond(200, Req, ?err(wsale_export_none, Merchant));
			{ok, SaleNotes} ->
			    {ok, Colors} = ?w_user_profile:get(color, Merchant),
			    case file:open(ExportFile, [append, raw]) of
				{ok, Fd} ->
				    try
					%% sort stock by color
					DoFun = fun(C) -> ?utils:write(Fd, C) end, 
					SortBSaleDetail = bsale_detail(to_dict, Transes, dict:new()),
					SortBSaleNote = bsale_note(to_dict, SaleNotes, dict:new()),
					csv_head(
					  trans_note_color,
					  DoFun,
					  ExportCode),
					do_write(
					  trans_note_color,
					  DoFun,
					  1,
					  SortBSaleDetail,
					  SortBSaleNote,
					  Colors,
					  ExportCode,
					  {0, 0, 0}),
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
			    end
		    end;
		false -> 
		    case file:open(ExportFile, [write, raw]) of
			{ok, Fd} -> 
			    try
				{ok, Employees} = ?w_user_profile:get(employee, Merchant),
				{ok, Regions} = ?w_user_profile:get(region, Merchant),
				{ok, Departments} = ?w_user_profile:get(department, Merchant),
				
				DoFun = fun(C) -> ?utils:write(Fd, C) end,
				?DEBUG("exportType ~p", [ExportType]),
				csv_head(ExportType, DoFun, ExportCode),
				do_write(ExportType,
					 DoFun,
					 1,
					 Transes,
					 {ExportCode, Employees, Regions, Departments},
					 {0, 0, 0}),
				ok = file:datasync(Fd),
				ok = file:close(Fd)
			    catch
				T:W -> 
				    file:close(Fd),
				    ?DEBUG("trace export:T ~p, W ~p~n~p",
					   [T, W, erlang:get_stacktrace()]),
				    ?utils:respond(200, Req, ?err(wsale_export_error, W)) 
			    end,
			    ?utils:respond(200, object, Req,
					   {[{<<"ecode">>, 0},
					     {<<"url">>, ?to_b(Url)}]}); 
			{error, Error} ->
			    ?utils:respond(200, Req, ?err(wsale_export_error, Error))
		    end
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
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

action(Session, Req, {"new_batch_sale_prop"}, Payload) ->
    ?DEBUG("new_batch_sale_prop with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?b_sale:bsale_prop(new, Merchant, Payload) end,
		   fun(RegionId)-> ?succ(add_shop, RegionId) end,
		   Req);

action(Session, Req, {"update_batch_sale_prop", PropId}, Payload) ->
    ?DEBUG("update_batch_sale_prop with session ~p, PropId ~p, paylaod ~p",
	   [Session, PropId, Payload]), 
    Merchant = ?session:get(merchant, Session),
    case ?b_sale:bsale_prop(update, Merchant, PropId, Payload) of
    	{ok, Id} ->
    	    ?utils:respond(200, Req, ?succ(update_shop, Id));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"list_batch_sale_prop"}, Payload) ->
    ?DEBUG("list_batch_sale_prop with session ~p, payload~n~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session), 
    ?pagination:pagination(
       fun(Match, Conditions) ->
	       ?b_sale:filter(total_sale_prop, ?to_a(Match), Merchant, Conditions)
       end,
       fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	       ?b_sale:filter(
		  sale_prop, Match, Merchant, Conditions, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"match_batch_sale_prop"}, Payload) ->
    ?DEBUG("match_batch_sale_prop with session ~p, paylaod~n~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Phone = ?v(<<"prompt">>, Payload),
    Mode  = ?v(<<"mode">>, Payload, 2),
    ?utils:respond(batch, fun() -> ?b_sale:match(sale_prop, Merchant, {Mode, Phone}) end, Req);

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
    LoginShop = ?session:get(login_shop, Session),
    Merchant = ?session:get(merchant, Session), 
    BaseSettings = ?w_report_request:get_setting(Merchant, LoginShop),
    BatchMode = ?w_report_request:get_config(<<"batch_mode">>, BaseSettings),
    
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

	    %% ?DEBUG("BatchMode ~p", [?to_s(BatchMode)]),
	    HideSaleProp =
		try
		    ?to_i(lists:nth(6, ?to_s(BatchMode))) - 48
		catch _:_ ->
			?YES
		end,
	    %% ?DEBUG("HideSaleProp ~p", [HideSaleProp]),

	    SaleProp =
		case HideSaleProp of
		    ?YES -> 
			[]; 
		    ?NO ->
			[{"bsale_prop", "销售场景", "glyphicon glyphicon-map-marker"}]
		end,

	    L1 = ?menu:sidebar(
		    level_1_menu,
		    BookBatchSale
		    ++ BatchSale
		    ++ BatchReject
		    ++ ListBatchSale
		    ++ NoteBatchSale
		    ++ Saler
		    ++ SaleProp),

	    %% L2 = ?menu:sidebar(level_2_menu, Saler),

	    L1 

    end.


start(new_bsale, Req, Merchant, Invs, Base) ->
    Round            = ?v(<<"round">>, Base, 1),
    ShouldPay        = ?v(<<"should_pay">>, Base),
    Shop             = ?v(<<"shop">>, Base),
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
	    case check_inventory({oncheck, Shop, Merchant}, Round, 0, ShouldPay, Invs) of 
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
			{<<"check_pay">>, Moneny}]);
		{db_error, StyleNumber} ->
		    ?utils:respond(200, Req, ?err(db_error, StyleNumber));
		{not_enought_stock, StyleNumber} ->
		    ?utils:respond(
		       200,
		       Req,
		       ?err(not_enought_stock, StyleNumber),
		       [{<<"style_number">>, StyleNumber}])
	    end
    end.

check_inventory({oncheck, _Shop, _Merchant}, Round, Moneny, ShouldPay, []) ->
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

check_inventory({oncheck, Shop, Merchant}, Round, Money, ShouldPay, [{struct, Inv}|T]) ->
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand = ?v(<<"brand">>, Inv),
    Amounts = ?v(<<"amounts">>, Inv),
    Count = ?v(<<"sell_total">>, Inv),
    DCount = lists:foldr(
	       fun({struct, A}, Acc)->
		       ?v(<<"sell_count">>, A) + Acc
	       end, 0, Amounts),

    FPrice = ?v(<<"rprice">>, Inv),
    Calc = ?to_f(FPrice * Count), 
    case StyleNumber of
	undefined -> {error, Inv};
	_ ->
	    case Count =:= DCount of
		true ->
		    %% is enought stock
		    Sql = "select style_number, brand, amount, shop, merchant"
			" from w_inventory"
			" where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
			++ " and brand=" ++ ?to_s(Brand)
			++ " and shop=" ++ ?to_s(Shop)
			++ " and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql) of
			{ok, Stock} ->
			    case ?v(<<"amount">>, Stock) < Count of
				true -> {not_enought_stock, StyleNumber};
				false ->
				    check_inventory(
				      {oncheck, Shop, Merchant}, Round, Money + Calc, ShouldPay, T)
			    end;
			{error, _Error} ->
			    {db_error, StyleNumber}
		    end;
		false ->
		    {error, Inv}
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
    %% ?DEBUG("H ~p", [H]),
    ShopId      = ?to_b(?v(K3, H)),

    StyleNumber = ?v(K1, H),
    BrandId     = ?to_b(?v(K2, H)),
    Brand     = ?v(<<"brand">>, H), 
    Type      = ?v(<<"type">>, H),
    
    %% Season      = ?v(<<"season">>, H),
    TagPrice    = ?v(<<"tag_price">>, H),
    FPrice      = ?v(<<"fprice">>, H),
    VirPrice    = ?v(<<"vir_price">>,H),
    RPrice      = ?v(<<"rprice">>, H),
    FDiscount   = ?v(<<"fdiscount">>, H),
    RDiscount   = ?v(<<"rdiscount">>, H), 
    Total       = ?v(<<"total">>, H),
    Unit        = ?v(<<"unit">>, H),

    Comment     = ?v(<<"comment">>, H),
    
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
		  {<<"unit">>, Unit},
		  {<<"tagPrice">>, TagPrice},
		  {<<"fprice">>, FPrice},
		  {<<"vir_price">>, VirPrice},
		  {<<"rprice">>, RPrice},
		  {<<"fdiscount">>, FDiscount}, 
		  {<<"rdiscount">>, RDiscount},
		  {<<"comment">>, Comment},
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

bsale_note(to_dict, [], Dict) ->
    %% ?DEBUG("sale_note_to_dict ~p", [dict:to_list(Dict)]),
    Dict;
bsale_note(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand">>, H)),
    Shop  = ?to_b(?v(<<"shop">>, H)),
    %% Color = ?to_b(?v(<<"color">>, H)),
    Key = <<StyleNumber/binary, Brand/binary, Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		dict:store(Key, [{H}], Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->

			  %% lists:foldr(
			  %%   fun({Note}, Acc) ->

			  %%   end, [], V)
			  [{H}] ++ V
			  %% case is_tuple(V) of
			  %%     true -> [{H}, V];
			  %%     false -> [{H}] ++ V
			  %% end
		  end,
		  Dict)
		%% dict:append(Key, {H}, Dict)
	end,

    bsale_note(to_dict, T, DictNew);

bsale_note(to_dict_with_rsn, [], Dict) ->
    ?DEBUG("sale_note_to_dict_with_rsn ~p", [dict:to_list(Dict)]),
    Dict;
bsale_note(to_dict_with_rsn, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    Rsn = ?to_b(?v(<<"rsn">>, H)),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand">>, H)),
    Shop  = ?to_b(?v(<<"shop">>, H)),

    %% Color = ?v(<<"color">>, H),
    ColorName = ?v(<<"cname">>, H),

    Size  = ?v(<<"size">>,H),

    Key = <<Rsn/binary,
	    <<"-">>/binary,
	    StyleNumber/binary,
	    <<"-">>/binary,
	    Brand/binary,
	    <<"-">>/binary,
	    Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		Note = [{<<"note">>, ?to_s(ColorName) ++ ?to_s(Size)}],
		N = proplists:delete(<<"size">>, proplists:delete(<<"color">>, H)),
		dict:store(Key, N ++ Note, Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  NewNote = ?v(<<"note">>, V) ++ ";"
			      ++ ?to_s(ColorName) ++ ?to_s(Size),
			  proplists:delete(<<"note">>, V) ++ [{<<"note">>, NewNote}]
		  end,
		  Dict)
	end,

    bsale_note(to_dict_with_rsn, T, DictNew).

bsale_detail(to_dict, [], Dict) ->
    %% ?DEBUG("sale_trans_to_Dict ~p", [dict:to_list(Dict)]),
    dict:to_list(Dict); 
bsale_detail(to_dict, [{H}|T], Dict) ->
    %% ?DEBUG("H ~p", [H]),
    StyleNumber = ?to_b(?v(<<"style_number">>, H)),
    Brand = ?to_b(?v(<<"brand_id">>, H)),
    Shop  = ?to_b(?v(<<"shop_id">>, H)),
    %% Color = ?to_b(?v(<<"color">>, H)),
    Key = <<StyleNumber/binary, Brand/binary, Shop/binary>>,

    DictNew = 
	case dict:find(Key, Dict) of
	    error ->
		dict:store(Key, [{H}], Dict);
	    {ok, _V} ->
		dict:update(
		  Key,
		  fun(V) ->
			  %% ?DEBUG("V ~p", [V]),
			  NewV = 
			      lists:foldr(
				fun({Note}, Acc) ->
					%% ?DEBUG("note ~p", [Note]),
					Exist = ?v(<<"total">>, Note),
					Added = ?v(<<"total">>, H),
					[{lists:keydelete(<<"total">>, 1, Note)
					  ++ [{<<"total">>, Exist + Added}]}|Acc] 
				end, [], V),
			  NewV 
		  end,
		  Dict)
		%% dict:append(Key, {H}, Dict)
	end,

    bsale_detail(to_dict, T, DictNew).    


note_class_by(color, [], Sorts) ->
    %% ?DEBUG("not_class_with_color: ~p", [dict:to_list(Sorts)]),
    Sorts;
note_class_by(color, [{H}|T], Sorts) ->
    %% ?DEBUG("H ~p", [H]),
    %% use color to key
    Color = ?v(<<"color">>, H),
    NewSorts = 
	case dict:find(Color, Sorts) of
	    error ->
		dict:store(Color, [{H}], Sorts);
	    {ok, _V} ->
		dict:update(
		  Color,
		  fun(V) ->
			  Size = ?v(<<"size">>, H),
			  {Found, NewV} = 
			      lists:foldr(
				fun({Note}, {Found, Acc}) ->
					case ?v(<<"size">>, Note) =:= Size of
					    true ->
						Exist = ?v(<<"total">>, Note),
						Added = ?v(<<"total">>, H),
						{true,
						 [{lists:keydelete(<<"total">>, 1, Note)
						   ++ [{<<"total">>, Exist + Added}]}|Acc]};
					    false ->
						{Found, [{Note}|Acc]}
					end 
				end, {fale, []}, V),
			  case Found of
			      true -> NewV;
			      fale -> [{H}] ++ V
			  end
		  end, 
		  Sorts)
	end,

    note_class_by(color, T, NewSorts).

csv_head(sale_new, Do, ExportCode) ->
    H = "序号,单号,交易,店铺,客户,场景,上次结余,累计结余,店员,数量,应收,实收,积分,现金,刷卡,微信,提现,电子卷,核销,备注,日期",
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% UTF8 = unicode:characters_to_list(H, utf8),
    Do(C);
csv_head(sale_new_detail, Do, ExportCode) -> 
    H = "序号,单号,导购,区域,负责人,交易,店铺,客户,场景,货号,品牌,类型,季节,厂商,年度,上架日期,参考价,单价,数量,小计,备注,日期",
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    Do(C);

csv_head(sale_new_note, Do, ExportCode) -> 
    H = "序号,店铺,款号,品牌,类型,季节,厂商,年度,小计,数量,颜色,尺码,上架日期",
    %% UTF8 = unicode:characters_to_list(H, utf8),
    C = 
	case ExportCode of
	    0 ->
		?utils:to_utf8(from_latin1, H);
	    1 ->
		?utils:to_gbk(from_latin1, H)
	end,
    %% Do(UTF8).
    Do(C).

do_write(sale_new, Do, _Seq, [], ExportCode, {Amount, SPay, RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?to_s(Amount) ++ ?d
	++ ?to_s(SPay) ++ ?d
	++ ?to_s(RPay) ++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d,
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(sale_new, Do, Seq, [{H}|T], ExportCode, {Amount, SPay, RPay}) ->
    Rsn        = ?v(<<"rsn">>, H),
    Type       = ?v(<<"type">>, H),
    Shop       = ?v(<<"shop">>, H),
    SaleProp   = ?v(<<"prop">>, H),
    Retailer   = ?v(<<"retailer">>, H), 
    Balance    = ?v(<<"balance">>, H),

    Employee  = ?v(<<"employee">>, H),
    Total     = ?v(<<"total">>, H),
    HasPay    = ?v(<<"should_pay">>, H),
    Score     = ?v(<<"score">>, H),

    Cash      = ?v(<<"cash">>, H),
    Card      = ?v(<<"card">>, H),
    WXin      = ?v(<<"wxin">>, H),
    WithDraw  = ?v(<<"withdraw">>, H),
    Ticket    = ?v(<<"ticket">>, H), 
    Verify    = ?v(<<"verificate">>, H), 

    Comment   = ?v(<<"comment">>, H),
    Datetime  = ?v(<<"entry_date">>, H),

    AccBalance = Balance - WithDraw,
    ShouldPay  = HasPay + Verify,

    %% ?DEBUG("CBalance ~p", [CBalance]),

    L = "\r\n"
	++ ?to_s(Seq) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ sale_type(Type) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(Retailer) ++ ?d
	++ ?to_s(SaleProp) ++ ?d
	++ ?to_s(Balance) ++ ?d
	++ ?to_s(AccBalance) ++ ?d

	++ ?to_s(Employee) ++ ?d 
	++ ?to_s(Total) ++ ?d
	++ ?to_s(HasPay) ++ ?d
	++ ?to_s(ShouldPay) ++ ?d
	++ ?to_s(Score) ++ ?d

	++ ?to_s(Cash) ++ ?d
	++ ?to_s(Card) ++ ?d 
	++ ?to_s(WXin) ++ ?d
	++ ?to_s(WithDraw) ++ ?d
	++ ?to_s(Ticket) ++ ?d
	++ ?to_s(Verify) ++ ?d 
	++ "\'" ++ ?to_s(Comment) ++ "\'" ++ ?d
	++ ?to_s(Datetime),
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line), 
    do_write(sale_new, Do, Seq + 1, T, ExportCode, {Amount + Total,
						 SPay + ShouldPay,
						 RPay + HasPay});

do_write(sale_new_detail, Do, _Seq, [],
	 {ExportCode, _Employees, _Regions, _Departments}, {Amount, _SPay, _RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?to_s(Amount) ++ ?d
	++ ?d
	++ ?d
	++ ?d,
	
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(sale_new_detail, Do, Seq, [{H}|T],
	 {ExportCode, Employees, Regions, Departments}, {Amount, SPay, RPay}) ->
    Rsn         = ?v(<<"rsn">>, H),
    BSaler      = ?v(<<"bsaler">>, H),
    RegionId    = ?v(<<"region_id">>, H),
    SellType    = ?v(<<"sell_type">>, H), 
    Shop        = ?v(<<"shop">>, H),
    SaleProp    = ?v(<<"prop">>, H),
    Employee    = ?v(<<"employee">>, H),

    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H), 
    Type        = ?v(<<"type">>, H),
    Season      = ?v(<<"season">>, H),
    Firm        = ?v(<<"firm">>, H),
    Year        = ?v(<<"year">>, H),
    InDatetime  = ?v(<<"in_datetime">>, H),
    %% OrgPrice    = ?v(<<"org_price">>, H),
    TagPrice    = ?v(<<"tag_price">>, H),
    RPrice      = ?v(<<"rprice">>, H), 
    Total       = ?v(<<"total">>, H),
    Comment     = ?v(<<"comment">>, H),

    Calc        =  RPrice * Total, 
    Datetime    = ?v(<<"entry_date">>, H),

    {RegionName, DepartmentId} = 
	case [R || {R} <- Regions, ?v(<<"id">>, R) =:= RegionId] of
	    [] -> {[], ?INVALID_OR_EMPTY};
	    [R] ->
		{?v(<<"name">>, R), ?v(<<"department_id">>, R)}
	end,
    
    DepartmentMaster =
	case [D || {D} <- Departments, ?v(<<"id">>, D) =:= DepartmentId] of
	    [] -> [];
	    [D] ->
		MasterId = ?v(<<"master_id">>, D),
		case [M || M <- Employees, ?v(<<"number">>, M) =:= MasterId] of
		    [] -> [];
		    [Master]-> ?v(<<"name">>, Master)
		end
	end,

    L = "\r\n"
	++ ?to_s(Seq) ++ ?d
	++ ?to_s(Rsn) ++ ?d
	++ ?to_s(Employee) ++ ?d
	++ ?to_s(RegionName) ++ ?d
	++ ?to_s(DepartmentMaster) ++ ?d
	++ sale_type(SellType) ++ ?d
	++ ?to_s(Shop) ++ ?d
	++ ?to_s(BSaler) ++ ?d
	++ ?to_s(SaleProp) ++ ?d 

	++ "\'" ++ ?to_s(StyleNumber) ++ "\'" ++ ?d
	++ ?to_s(Brand) ++ ?d
	++ ?to_s(Type) ++ ?d
	++ ?w_inventory_request:season(Season) ++ ?d
	++ ?to_s(Firm) ++ ?d
	++ ?to_s(Year) ++ ?d
	++ ?to_s(InDatetime) ++ ?d
	++ ?to_s(TagPrice) ++ ?d
	++ ?to_s(RPrice) ++ ?d 
    %% ++ ?to_s(OrgPrice) ++ ?d 
	++ ?to_s(Total) ++ ?d
	++ ?to_s(Calc) ++ ?d 

	++ "\'" ++ ?to_s(Comment) ++ "\'" ++ ?d 
    %% ++ ?to_s(?w_good_sql:stock(ediscount, RPrice, TagPrice)) ++ ?d 
	++ ?to_s(Datetime),
    %% UTF8 = unicode:characters_to_list(L, utf8),
    %% Do(UTF8),
    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line),
    do_write(sale_new_detail, Do, Seq + 1, T,
	     {ExportCode, Employees, Regions, Departments}, {Amount + Total, SPay, RPay}).

do_write(sale_new_note, Do, _Seq, [], _DictNotes, _Colors, ExportCode, {Amount, _SPay, _RPay})->
    L = "\r\n"
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d
	++ ?d 
	++ ?to_s(Amount) ++ ?d,

    Line = 
	case ExportCode of
	    0 -> ?utils:to_utf8(from_latin1, L);
	    1 -> ?utils:to_gbk(from_latin1, L)
	end,
    Do(Line);

do_write(sale_new_note, Do, Seq, [DH|DT], DictNotes, Colors, ExportCode, {Amount, SPay, RPay}) ->
    {Key, [{H}]} = DH,
    Shop        = ?v(<<"shop">>, H), 
    StyleNumber = ?v(<<"style_number">>, H),
    Brand       = ?v(<<"brand">>, H),
    Type        = ?v(<<"type">>, H),
    Season      = ?v(<<"season">>, H),
    Firm        = ?v(<<"firm">>, H),
    Year        = ?v(<<"year">>, H),
    InDatetime  = ?v(<<"in_datetime">>, H), 
    Total       = ?v(<<"total">>, H), 

    case dict:find(Key, DictNotes) of
	{ok, FindNotes} ->
	    ?DEBUG("find notes ~p", [FindNotes]),
	    ColoredNotes = note_class_by(color, FindNotes, dict:new()),

	    Details = 
		dict:fold(
		  fun(K, SSNotes, Acc) ->
			  {TotalOfColor, SizeDescs} = 
			      lists:foldr(
				fun({S}, {Total0, Descs}) ->
					Size = ?v(<<"size">>, S),
					TotalA = ?v(<<"total">>, S),
					{Total0 + TotalA,
					 Descs ++ ?to_s(Size) ++ ":" ++ ?to_s(TotalA) ++ ";"} 
				end, {0, []}, SSNotes),

			  [{K, TotalOfColor, SizeDescs}|Acc]

		  end, [], ColoredNotes),
	    %% ?DEBUG("Details ~p", [Details]),

	    L = "\r\n"
		++ ?to_s(Seq) ++ ?d
	    %% ++ ?to_s(Rsn) ++ ?d
	    %% ++ ?to_s(Retailer) ++ ?d
	    %% ++ ?to_s(Promotion) ++ ?d
	    %% ++ ?to_s(Score) ++ ?d 
	    %% ++ sale_type(SellType) ++ ?d
		++ ?to_s(Shop) ++ ?d
	    %% ++ ?to_s(Employee) ++ ?d

		++ "\'" ++ ?to_s(StyleNumber) ++ "\'" ++ ?d
		++ ?to_s(Brand) ++ ?d
		++ ?to_s(Type) ++ ?d
		++ ?w_inventory_request:season(Season) ++ ?d
		++ ?to_s(Firm) ++ ?d
		++ ?to_s(Year) ++ ?d
		++ ?to_s(Total) ++ ?d
		++ ?d %% total of color
		++ ?d %% color
		++ ?d %% size
		++ ?to_s(InDatetime),


	    C = lists:foldr(
		  fun({ColorId, TotalOfColor, SizeDescs}, Acc) ->
			  L1 = "\r\n"
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d 
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d
			      ++ ?d

			      ++ ?to_s(TotalOfColor) ++ ?d
			      ++ ?to_s(?w_inventory_request:get_color(ColorId, Colors)) ++ ?d
			      ++ ?to_s(SizeDescs) ++ ?d
			      ++ ?d,
			  Acc ++ L1
		  end, [], Details),

	    %% UTF8 = unicode:characters_to_list(L, utf8),
	    %% Do(UTF8),
	    Line = 
		case ExportCode of
		    0 -> ?utils:to_utf8(from_latin1, L ++ C);
		    1 -> ?utils:to_gbk(from_latin1, L ++ C)
		end,
	    Do(Line),
	    do_write(sale_new_note,
		     Do,
		     Seq + 1,
		     DT,
		     DictNotes,
		     Colors,
		     ExportCode,
		     {Amount + Total, SPay, RPay});

	error ->
	    do_write(sale_new_note,
		     Do,
		     Seq + 1,
		     DT,
		     DictNotes,
		     Colors,
		     ExportCode,
		     {Amount + Total, SPay, RPay})
    end.

mode(0) -> use_id.

sale_type(0) -> "开单";
sale_type(1)-> "退货".

export_type(0) -> sale_new;
export_type(1) -> sale_new_detail.

