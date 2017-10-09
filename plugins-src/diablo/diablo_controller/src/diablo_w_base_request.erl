-module(diablo_w_base_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).


%%--------------------------------------------------------------------
%% @desc: GET action
%%-------------------------------------------------------------------- 
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = sys_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(?MODULE, Session)},
			  {sidebar, sidebar(Session)},
			  {ngapp, "baseApp"},
			  {ngcontroller, "baseCtrl"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


action(Session, Req, {"list_w_bank_card"}) ->
    ?DEBUG("list_w_bank_card with session ~p", [Session]),

    Merchant = ?session:get(merchant, Session),
    {ok, Cards}    = ?w_base:bank_card(list, Merchant),
    ?utils:respond(200, batch, Req, Cards);

action(Session, Req, {"list_base_setting"}) ->
    ?DEBUG("list_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    case ?session:get(type, Session) of
	?MERCHANT ->
	    {ok, S}  = ?w_user_profile:get(setting, Merchant),
	    ?utils:respond(200, batch, Req, S); 
	?USER ->
	    {ok, Shops} = ?w_user_profile:get(user_shop, Merchant, Session),
	    %% ?DEBUG("Shops ~p", [Shops]),
	    ShopIds = lists:foldr(
			    fun({Shop}, Acc) ->
				    ShopId = ?v(<<"shop_id">>, Shop),
				    case lists:member(ShopId, Acc) of
					true -> Acc;
					false -> [ShopId|Acc]
				    end
			    end, [], Shops),

	    {ok, S}  = ?w_user_profile:get(setting, Merchant),

	    Select =
		case [{SS} || {SS} <- S, lists:member(?v(<<"shop">>, SS), ShopIds)] of
		    [] -> [{SS} || {SS} <- S, ?v(<<"shop">>, SS) =:= -1];
		    V -> V ++ [{SS} || {SS} <- S, ?v(<<"shop">>, SS) =:= -1]
		end,
	    %% ?DEBUG("select ~p", [Select]),
	    %% lists:filter()
	    ?utils:respond(200, batch, Req, Select)

    end;


action(Session, Req, {"list_std_executive"}) ->
    ?DEBUG("list_executive with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:good(list_executive, Merchant) end, Req);

action(Session, Req, {"list_safety_category"}) ->
    ?DEBUG("list_safety_category with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:good(list_safety_category, Merchant) end, Req);

action(Session, Req, {"list_fabric"}) ->
    ?DEBUG("list_fabric with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:good(list_fabric, Merchant) end, Req);

action(Session, Req, {"list_ctype"}) ->
    ?DEBUG("list_ctype with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:good(list_ctype, Merchant) end, Req);

action(Session, Req, {"list_size_spec"}) ->
    ?DEBUG("list_ctype with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:good(list_size_spec, Merchant) end, Req);

action(Session, Req, {"list_print_template"}) ->
    ?DEBUG("list_print_template with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_base:print(list_template, Merchant) end, Req).


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_w_bank_card"}, Payload) ->
    ?DEBUG("new_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?w_base:bank_card(new, Merchant, Payload) of
	{ok, CardNo} ->
	    %% refresh profile
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_new_card, CardNo));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"del_w_bank_card"}, Payload) ->
    ?DEBUG("del_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    CardId   = ?v(<<"id">>, Payload),
    case ?w_base:bank_card(delete, Merchant, CardId) of
	{ok, CardId} ->
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_delete_card, CardId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_bank_card"}, Payload) ->
    ?DEBUG("update_w_bank_card with session ~p~npaylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?w_base:bank_card(update, Merchant, Payload) of
	{ok, CardNo} ->
	    ?w_user_profile:update(bank, Merchant),
	    ?utils:respond(200, Req, ?succ(base_update_card, CardNo));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% base setting 
%%
action(Session, Req, {"list_base_setting"}, Payload) ->
    ?DEBUG("list_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    {ok, S}    = ?w_base:setting(list, Merchant, Payload),
    ?utils:respond(200, batch, Req, S);

action(Session, Req, {"add_base_setting"}, Payload) ->
    ?DEBUG("add_base_setting with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    case ?w_base:setting(add, Merchant, Payload) of
	{ok, EName}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_add_setting, EName));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
    
action(Session, Req, {"update_base_setting"}, Payload) ->
    ?DEBUG("update_base_setting with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    case ?w_base:setting(update, Merchant, Payload) of
	{ok, EName}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_update_setting, EName));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"add_shop_setting"}, Payload) ->
    ?DEBUG("add_shop_setting with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    case ?w_base:setting(add_to_shop, Merchant, Shop) of
	{ok, Shop}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_add_shop_setting, Shop));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_shop_setting"}, Payload) ->
    ?DEBUG("delete_shop_setting with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    Shop     = ?v(<<"shop">>, Payload),
    case ?w_base:setting(delete_from_shop, Merchant, Shop) of
	{ok, Shop}  ->
	    ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(base_delete_shop_setting, Shop));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_std_executive"}, Payload) ->
    ?DEBUG("add_std_executive with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Name = ?v(<<"name">>, Payload),
    case ?w_base:good(add_executive, Merchant, Name) of
	{ok, AddId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"id">>, AddId}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_std_executive"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_base:good(update_executive, Merchant, Payload) of
	{ok, EId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_std_executive, EId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_safety_category"}, Payload) ->
    ?DEBUG("add_safety_category with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Name = ?v(<<"name">>, Payload),
    case ?w_base:good(add_safety_category, Merchant, Name) of
	{ok, AddId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"id">>, AddId}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_safety_category"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_base:good(update_safety_category, Merchant, Payload) of
	{ok, CId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_std_executive, CId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_fabric"}, Payload) ->
    ?DEBUG("add_fabric with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Name = ?v(<<"name">>, Payload),
    case ?w_base:good(add_fabric, Merchant, Name) of
	{ok, AddId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"id">>, AddId}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_fabric"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_base:good(update_fabric, Merchant, Payload) of
	{ok, FId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_std_executive, FId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"create_print_template"}, Payload) ->
    ?DEBUG("create_print_template: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_user_profile:set_template(barcode_print, Merchant) of
	{ok, _}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(create_print_template, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_print_template"}, Payload) ->
    ?DEBUG("update_print_template: session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?w_base:print(update_template, Merchant, Payload) of
	{ok, TId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_std_executive, TId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"add_ctype"}, Payload) ->
    ?DEBUG("add_ctype with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Name = ?v(<<"name">>, Payload),
    case ?w_base:good(add_ctype, Merchant, Name) of
	{ok, AddId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"id">>, AddId}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_ctype"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_base:good(update_ctype, Merchant, Payload) of
	{ok, CId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_ctype, CId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"add_size_spec"}, Payload) ->
    ?DEBUG("add_size_spec with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    %% Name = ?v(<<"name">>, Payload),
    case ?w_base:good(add_size_spec, Merchant, Payload) of
	{ok, AddId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"id">>, AddId}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_size_spec"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    case ?w_base:good(update_size_spec, Merchant, Payload) of
	{ok, SId}  ->
	    %% ?w_user_profile:update(setting, Merchant),
	    ?utils:respond(200, Req, ?succ(good_update_ctype, SId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% passwd
%%
action(Session, Req, {"update_user_passwd"}, Payload) ->
    ?DEBUG("update_user_passwd with session ~p", [Session]),
    Account = ?session:get(name, Session),
    case ?right:right(update_account_passwd, Account, Payload) of
	{ok, Account} ->
	    ?utils:respond(200, Req, ?succ(base_update_passwd, Account));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"download_stock_fix"}, Payload) ->
    ?DEBUG("download_stock_fix with session ~p, payload ~p", [Session, Payload]),
    _Merchant = ?session:get(merchant, Session),
    Apk = <<"qzg_stock-release2017-10-08_01-18-32.apk">>,
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"url">>, ?to_b(Apk)}]});

%%
%% login out
%% 
action(Session, Req, {"destroy_login_user"}, Payload) ->
    ?DEBUG("destroy_login_user with session ~p, payload ~p",
	   [Session, Payload]),
    User = ?session:get(name, Session),
    %% ?DEBUG("Session ~p", [Session]),
    Ok = ?session:delete(Session#session.id),
    ?DEBUG("ok ~p", [Ok]),
    case Ok of
	ok -> ?utils:respond(200, Req, ?succ(destroy_login_user, User));
	_ ->
	    ?session:delete(Session#session.id),
	    ?utils:respond(200, Req, ?succ(destroy_login_user, User))
    end.

sidebar(Session) -> 
    Card = 
    	case ?right_auth:authen(?new_w_bank_card, Session) of
    	    {ok, ?new_w_bank_card} ->
    		[{"new_bank_card", "新增银行卡", "glyphicon glyphicon-plus"},
    		 {"bank_card_detail", "银行卡详情", "glyphicon glyphicon-briefcase"}
		 %% {"bank_card_detail", "银行卡详情", "glyphicon glyphicon-briefcase"}
		];
    	    _ ->
		[]
    	end, 

    Print =
	case ?right_auth:authen(?new_w_printer_conn, Session) of
	    {ok, ?new_w_printer_conn} ->
		[
		 {"connect_new",    "打印机绑定", "glyphicon glyphicon-plus"},
		 {"connect_detail", "绑定详情",   "glyphicon glyphicon-briefcase"}
		 %% {"connect_detail", "绑定详情", "glyphicon glyphicon-leaf"}
		]; 
	    _ -> []
	end ++ [{"detect",         "打印机探测", "glyphicon glyphicon-search"}],

    
    SBase =
	case Card of
	    [] -> [];
	    _ ->
		[{{"bank", "银行卡设置", "glyphicon glyphicon-credit-card"}, Card}]
	end ++

	case Print of
	    [] -> [];
	    _ ->  [{{"printer", "打印机设置", "glyphicon glyphicon-print"}, Print}]
	end ++

	case ?session:get(type, Session) of
	    ?USER -> [];
	    ?MERCHANT ->
		Merchant = ?session:get(merchant, Session),
		{ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
		AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),
		
		[{{"setting",        "基本设置", "glyphicon glyphicon-cog"},
		  [{"print_option",  "系统设置", "glyphicon glyphicon-wrench"},
		   {"ctype",         "货品大类", "glyphicon glyphicon-text-width"}]
		  ++ case AutoBarcode of
			 ?YES -> [];
			 ?NO ->
			     [{"std_executive",   "执行标准", "glyphicon glyphicon-registration-mark"},
			      {"safety_category", "安全类别", "glyphicon glyphicon-text-background"},
			      {"fabric",          "货品面料", "glyphicon glyphicon-glass"},
			      {"size_spec",       "尺码规格", "glyphicon glyphicon-text-size"}]
		     end
		  ++ [{"print_template", "打印模板", "glyphicon glyphicon-file"}
		      %% {"soft_stock_fix", "盘点软件", "glyphicon glyphicon-save"}
		     ]}
		]
	end,
    
    Passwd = [{"passwd", "重置密码", "glyphicon glyphicon-user"}], 
    ?menu:sidebar(level_2_menu, SBase) ++ ?menu:sidebar(level_1_menu, Passwd).
