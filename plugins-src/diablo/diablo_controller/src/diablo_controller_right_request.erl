-module(diablo_controller_right_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
-export([get_shops/2, login_user/2]).

action(Session, Req) ->
    ?DEBUG("action with session ~p", [Session]),

    Render = fun(?SUPER) ->
		     sright_frame:render(
		       [{navbar, ?menu:navbars(?MODULE, Session)},
			{basebar, ?menu:w_basebar(Session)},
			{sidebar, sidebar(Session)} 
		       ]);
		(_) ->
		     right_frame:render(
		       [{navbar, ?menu:navbars(?MODULE, Session)},
			{basebar, ?menu:w_basebar(Session)},
			{sidebar, sidebar(Session)} 
		       ])
	     end,
    
    case ?session:get(type, Session) of
	?SUPER ->
	    %% {"rightMechantCtrl", "rightMerchantApp"},
	    {ok, HTMLOutput} = Render(?SUPER),
	    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput});
	?MERCHANT ->
	    %% {"rightUserCtrl", "rightUserApp"},
	    {ok, HTMLOutput} = Render(?MERCHANT),
	    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput});
	?USER ->
	    {ok, HTMLOutput} = Render(?USER),
	    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}) 
    end.

%%
%% GET
%%
action(Session, Req, {"get_login_user"}) ->
    ?DEBUG("get_login_user with session ~p", [Session]),
    User = ?session:get(name, Session),
    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
				       {<<"user">>, ?to_b(User)}]});

    
action(Session, Req, {"list_right_catlog"}) ->
    ?DEBUG("list_right_catlog with session ~p", [Session]),
    case ?session:get(type, Session) of
	?SUPER ->
	    {ok, Catlogs} = ?right_init:lookup(super),
	    ?utils:respond(200, batch, Req, Catlogs);
	?MERCHANT -> 
	    Catlogs = ?right_auth:catlog(session, Session),
	    %% ?DEBUG("catlogs ~p", [Catlogs]),
	    %% filter right
	    {ok, Rights} =
		?right_init:get_children([{<<"id">>, ?right_right}]), 
	    NewCatlogs = Catlogs -- Rights,
	    %% ?DEBUG("NewCatlogs ~p", [NewCatlogs]),
	    ?utils:respond(200, batch, Req, NewCatlogs)
    end;


action(Session, Req, {"get_login_user_info"}) ->
    ?DEBUG("get_login_user_info with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    LoginRetailer = ?session:get(login_retailer, Session),
    LoginEmployee = ?session:get(login_employee, Session),
    LoginShop     = ?session:get(login_shop, Session),
    SDays         = ?session:get(sdays, Session),
    Name          = ?session:get(name, Session),
    {ok, Catlogs} = ?w_user_profile:get(user_right, Merchant, Session),
    {ok, Shops}   = ?w_user_profile:get(user_shop, Merchant, Session),

    %% ?DEBUG("login_user_info: shops ~p", [Shops]),
    ?utils:respond(200, object, Req,
		   {[{<<"ecode">>, 0},
		     {<<"right">>, Catlogs},
		     {<<"shop">>, Shops},
		     {<<"login_retailer">>, LoginRetailer},
		     {<<"login_employee">>, LoginEmployee},
		     {<<"login_shop">>, LoginShop},
		     {<<"login_name">>, Name},
		     {<<"sdays">>, SDays},
		     {<<"type">>, ?session:get(type, Session)}]});
    
action(Session, Req, {"list_login_user_right"}) ->
    ?DEBUG("list_login_user_right with session ~p", [Session]),
    %% {ok, Catlogs} = login_user(right, Session),
    Merchant = ?session:get(merchant, Session),
    %% UserId = ?session:get(id, Session),
    {ok, Catlogs} = ?w_user_profile:get(user_right, Merchant, Session), 
    ?utils:respond(200, batch, Req, Catlogs); 


action(Session, Req, {"list_login_user_shop"}) ->
    ?DEBUG("list_login_user_shop with session ~p", [Session]),
    %% Shops = login_user(shop, Session),
    Merchant = ?session:get(merchant, Session),
    %% UserId = ?session:get(id, Session),
    {ok, Shops} = ?w_user_profile:get(user_shop, Merchant, Session),
    ?utils:respond(200, batch, Req, lists:usort(Shops));

action(Session, Req, {"list_role"}) ->
    ?DEBUG("list_role with session ~p", [Session]),
    Roles = 
	case ?session:get(type, Session) of
	    ?SUPER -> %% super can lookup all the roles
		?right:right(list_role, []);
	    ?MERCHANT ->
		?right:right(
		   list_role, {<<"created_by">>, ?session:get(id, Session)})
	end,
    case Roles of
	{ok, R} ->
	    ?utils:respond(200, batch, Req, R);
	{error, Error} ->
	    ?utils:respond(200, object, Req, Error)
    end;


action(Session, Req, {"get_right_by_role_id", RoleId}) ->
    ?DEBUG("get_right_by_role_id with session ~p, roleId ~p",
	   [Session, ?to_integer(RoleId)]),
    Catlogs = ?right_auth:catlog(role, ?to_integer(RoleId)),
    ?utils:respond(200, batch, Req, Catlogs);


action(Session, Req, {"get_shop_by_role", RoleId}) ->
    ?DEBUG("get_shop_by_role with session ~p, roleId ~p",
	   [Session, ?to_integer(RoleId)]),
    Shops = ?right:lookup_role_shop({<<"role_id">>, ?to_i(RoleId)}),

    FilterShops =
	lists:foldr(
	  fun(AShop, Acc) ->
		  case lists:member(AShop, Acc) of
		      true  -> Acc;
		      false -> [AShop|Acc]
		  end end, [], Shops),
    
    NewShops = 
	lists:foldr(
	  fun({Shop}, Acc) ->
		  {ok, Children} =
		      ?right_init:get_children(
			 children_only,
			 [{<<"id">>, ?v(<<"func_id">>, Shop)}]),

		  case Children of
		      [] -> 
			  [{Shop}|Acc];
		      Children -> 
			  Left = proplists:delete(<<"func_id">>, Shop),
			  [ {[{<<"func_id">>,  ?v(<<"id">>, Child)}|Left]}
			    || {Child} <-  Children] ++ Acc
		  end 
	  end, [], FilterShops),

    %% ?DEBUG("get shops ~p", [NewShops]),

    ?utils:respond(200, batch, Req, NewShops);
	    
action(Session, Req, {"list_account"}) ->
    ?DEBUG("list_account with session ~p", [Session]),
    case ?session:get(type,Session) of
	?SUPER ->
	    Accounts = ?right:lookup_account({<<"type">>,[?MERCHANT, ?USER]}),
	    ?utils:respond(200, batch, Req, Accounts);
	?MERCHANT ->
	    Merchant = ?session:get(merchant, Session),
	    Accounts = ?right:lookup_account(
			  [{<<"type">>, [?MERCHANT, ?USER]},
			   {<<"merchant">>, Merchant}]),
	    ?utils:respond(200, batch, Req, Accounts);
	_ ->
	    Req:respond({598,
			 [{"Content-Type", "application/json"}],
			 ejson:encode(
			   {[{<<"ecode">>, 9901},
			     {<<"action">>, <<"list_account">>}]})})
    end;

%% =============================================================================
%% @desc: get the certain account's roles
%% =============================================================================
action(Session, Req, {"list_account_right", AccountId}) ->
    ?DEBUG("list_account_right with session ~p, accountId ~p",
	   [Session, AccountId]),
    %% ?utils:respond(200, Req, ?err(not_enought_right, ?utils:get_user(Session)));
    Roles = ?right:lookup_account_right(
	       {<<"user_id">>, ?to_integer(AccountId)}),
    ?utils:respond(200, batch, Req, Roles);

action(Session, Req, {"list_inventory_children"}) ->
    ?DEBUG("list_inventory_children with session ~p", [Session]),

    {RightId, Cares}
	= {?right_w_inventory, [?new_w_inventory,
				?del_w_inventory,
				?update_w_inventory,
				?reject_w_inventory,
				?fix_w_inventory,
				?check_w_inventory,
				?list_new_w_inventory,

				%% transfer
				?transfer_w_inventory,
				?check_w_inventory_transfer,
				?cancel_w_inventory_transfer,

				%% order
				?new_stock_order,
				?del_stock_order,
				?update_stock_order,
				?filter_stock_order,
				?filter_stock_order_note
			       ]}, 
    
    {ok, Children} = ?right_init:get_children(children_only, [{<<"id">>, RightId}]),
	
    
    FilterChildren = 
	lists:filter(
	  fun({Node}) ->
		  lists:member(?to_i(?v(<<"id">>, Node)), Cares)
	  end, Children),
    ?utils:respond(200, batch, Req, FilterChildren);

action(Session, Req, {"list_sales_children"}) ->
    ?DEBUG("list_sales_children with session ~p", [Session]),
    
    {RightId, Cares} =
	{?right_w_sale, [?new_w_sale,
			 ?reject_w_sale,
			 ?print_w_sale,
			 ?update_w_sale,
			 ?check_w_sale,
			 ?list_w_sale]},
    
    {ok, Children} =
	?right_init:get_children(children_only, [{<<"id">>, RightId}]),
    
    FilterChildren = 
	lists:filter(
	  fun({Node}) ->
		  lists:member(?value(<<"id">>, Node), Cares)
	  end, Children),
    ?utils:respond(200, batch, Req, FilterChildren);

action(Session, Req, {"list_bsale_children"}) ->
    ?DEBUG("list_bsale_children with session ~p", [Session]),
    {RightId, Cares} =
	{?right_b_sale, [?new_batch_sale, 
			 ?reject_batch_sale,
			 ?update_batch_sale,
			 ?check_batch_sale,
			 ?list_batch_sale,
			 ?del_batch_sale,
			 ?book_batch_sale,
			 ?list_batch_sale_new_detail]},

    {ok, Children} =
	?right_init:get_children(children_only, [{<<"id">>, RightId}]),

    FilterChildren = 
	lists:filter(
	  fun({Node}) ->
		  lists:member(?value(<<"id">>, Node), Cares)
	  end, Children),
    ?utils:respond(200, batch, Req, FilterChildren).

%%
%% POST
%%
action(Session, Req, {"del_account"}, Payload) ->
    ?DEBUG("delete_account with session ~p~nPayload ~p", [Session, Payload]),
    LoginType    = ?session:get(type, Session),
    AccountType  = ?value(<<"type">>, Payload),
    Account      = ?value(<<"account">>, Payload),
    case LoginType > ?to_i(AccountType) of
	true ->
	    ?utils:respond(200, Req, ?err(not_enought_right, Account));
	false ->
	    case ?right:right(delete_account, Account, AccountType) of
		{ok, Account}->
		    ?utils:respond(200, Req, ?succ(delete_account, Account));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

%% =============================================================================
%% role
%% =============================================================================
action(Session, Req, {"new_role"}, Payload) ->
    ?DEBUG("new_role with session ~p~n, payload ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    LoginId   = ?session:get(id, Session),
    LoginName = ?session:get(name, Session),
    LoginType = ?session:get(type, Session),
    RoleType  = ?value(<<"type">>, Payload),
      
    %% super can create merchant role, and merchant can create user role only
    Result =
	case {?to_integer(LoginType), ?to_integer(RoleType)} of
	    {?SUPER, ?MERCHANT} ->
		case ?right:right(
			new_role, [{<<"created_by">>, LoginId},
				   {<<"merchant">>, Merchant}|Payload]) of
		    {ok, RoleName} ->
			?succ(add_role,RoleName);
		    {error, Error} ->
			Error
		end;
	    {?MERCHANT, ?USER} ->
		%% ?err(not_enought_right, LoginName);
		case ?right:right(
			new_user_role,
			[{<<"created_by">>, LoginId},
			 {<<"merchant">>, Merchant}|Payload]) of
		    {ok, RoleName} ->
			?succ(add_role,RoleName);
		    {error, Error} ->
			Error
		end;
	    _ ->
		?err(not_enought_right, LoginName)
	end,
    
    ?utils:respond(200, Req, Result);

action(Session, Req, {"update_role"}, Payload) ->
    ?DEBUG("new_role with session ~p~npayload ~p", [Session, Payload]),
    LoginType = ?session:get(type, Session),
    LoginName = ?session:get(name, Session),
    RoleId    = ?value(<<"role_id">>, Payload),
    RoleType  = ?value(<<"role_type">>, Payload),
    
    Result =
	case {?to_integer(LoginType), ?to_integer(RoleType)} of
	    {?SUPER, ?MERCHANT} ->
		case ?right:right(update_role, Payload) of
		    {ok, _} ->
			?succ(update_role, RoleId);
		    {error, Error} ->
			Error
		end;
	    {?MERCHANT, ?USER} ->
		%% ?err(not_enought_right, LoginName);
		case ?right:right(update_user_role, Payload) of
		    {ok, _} ->
			?succ(update_role,RoleId);
		    {error, Error} ->
			Error
		end;
	    _ ->
		?err(not_enought_right, LoginName)
	end,

    ?utils:respond(200, Req, Result);

%% =============================================================================
%% account
%% =============================================================================
action(Session, Req, {"new_account"}, Payload) ->
    ?DEBUG("action new_account with session ~p, payload ~p", [Session, Payload]),
    UserType = ?session:get(type, Session),
    Reply = 
	case UserType of
	    ?SUPER ->
		Merchant  = ?v(<<"merchant">>, Payload),
		case ?right:get(merchant_account, Merchant) of
		    {ok, []} ->
			?right:right(new_account, Payload); 
		    {ok, _} ->
			{error, ?err(merchant_account_exist,Merchant)}
		end;
	    ?MERCHANT ->
		Merchant = ?session:get(merchant, Session), 
		{ok, ExistAccounts} = ?right:get(account, Merchant),

		{MaxCreate, ExistCreate} = filter_account(ExistAccounts),

		case MaxCreate =< ExistCreate of
		    true ->
			?DEBUG("beyond the number of account, limit ~p"
			       ", exist ~p", [MaxCreate, ExistCreate]),
			{error, ?err(max_account, MaxCreate)};
		    false ->
			?right:right(
			   new_account, [{<<"merchant">>, Merchant}|Payload])
		end;
	    _ ->
		{error, ?err(not_enought_right, ?value(<<"name">>, Payload))}
	end,

    case Reply of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_account, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_account"}, Payload) ->
    ?DEBUG("update_account_role with session ~p~npayload ~p", [Session, Payload]),
    Account = ?value(<<"account">>, Payload),
    Role    = ?value(<<"role">>, Payload), 
    Type    = ?value(<<"type">>, Payload),

    UpdateFun =
        case Type of
            ?MERCHANT ->
                fun() ->
                        ?right:right(update_account_role, Account, Role)
                end;
            ?USER ->
                fun() ->
                        ?right:right(update_account, Payload)
		end
        end,

    case UpdateFun() of
        {ok, Account} ->
            ?utils:respond(
               200, Req, ?succ(update_account_role, Account));
        {error, Error} ->
            ?utils:respond(200, Req, Error)
    end;

action(Session, _Req, Args, Payload) ->
    ?DEBUG("unkown action with session ~p, args ~p, payload ~p",
	   [Session, Args, Payload]).

sidebar(Session) ->
    Super = [
	     {{"role_merchant", "商户角色", "glyphicon glyphicon-map-marker"},
	      [{"role_new", "新增角色", "glyphicon glyphicon-plus"},
	       {"role_detail", "角色详情", "glyphicon glyphicon-book"}]},
	     
	     {{"account_merchant", "商户帐户", "glyphicon glyphicon-user"},
	      [{"account_new", "新增帐户", "glyphicon glyphicon-plus"},
	       {"account_detail", "帐户详情", "glyphicon glyphicon-book"}]}
	    ],

    Role1 = 
	case ?right_auth:authen(?list_role, Session) of
	    {ok, ?list_role} ->
		[{"role_detail", "角色详情", "glyphicon glyphicon-book"}];
	    _ ->
		[]
	end,

    Role2 = 
	case ?right_auth:authen(?new_role, Session) of
	    {ok, ?new_role} ->
		[{"role_new", "新增角色", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,

    Account1 =
	case ?right_auth:authen(?list_account, Session) of
	    {ok, ?list_account} ->
		[{"account_detail", "帐户详情", "glyphicon glyphicon-book"}];
	    _ ->
		[]
	end,

    Account2 =
	case ?right_auth:authen(?new_account, Session) of
	    {ok, ?new_account} ->
		[{"account_new", "新增帐户", "glyphicon glyphicon-plus"}];
	    _ ->
		[]
	end,
    
    Merchant = 
	[
	 {{"role_user", "角色", "glyphicon glyphicon-off"}, Role2 ++ Role1},
	 {{"account_user", "帐户", "icon icon-user"}, Account2 ++ Account1}
	],

    Sidebars = 
	case ?session:get(type, Session) of
	    ?SUPER ->
		Super;
	    ?MERCHANT ->
		Merchant;
	    _ ->
		[]
	end,
    ?menu:sidebar(level_2_menu, Sidebars).


%% =============================================================================
%% internal
%% ============================================================================= 
get_shops(Session, Module) ->
    Shops = 
	case ?session:get(type, Session) of
	    ?SUPER ->
		?shop:lookup();
	    ?MERCHANT ->
		{ok, S0} = ?w_user_profile:get(shop, ?session:get(merchant, Session)),
		lists:foldr(
		  fun({AShop}, Acc) ->
			  [{[{<<"shop_id">>,  ?v(<<"id">>, AShop)},
			     {<<"name">>,     ?v(<<"name">>, AShop)},
			     {<<"repo_id">>,  ?v(<<"repo">>, AShop)},
			     {<<"charge_id">>,?v(<<"charge_id">>, AShop)},
			     {<<"score_id">>, ?v(<<"score_id">>, AShop)},
			     {<<"region_id">>, ?v(<<"region_id">>, AShop)},
			     {<<"addr">>,      ?v(<<"address">>, AShop)},
			     {<<"bcode_friend">>, ?v(<<"bcode_friend">>, AShop)},
			     {<<"bcode_pay">>,    ?v(<<"bcode_pay">>, AShop)},
			     {<<"type">>,         ?v(<<"type">>, AShop)},
			     {<<"func_id">>, 
			      case Module of
				  inventory -> ?right_w_inventory;
				  sale ->      ?right_w_sale;
				  bsale ->     ?right_b_sale
			      end}
			    ]} | Acc] 
		  end, [], S0);
	    ?USER ->
		?right_auth:get_user_shop(Session)
	end,
    
    SortShops = 
	lists:foldr(
	  fun({Shop}, Acc) ->
		  Id     = ?v(<<"shop_id">>, Shop),
		  Name   = ?v(<<"name">>, Shop),
		  FunId  = ?v(<<"func_id">>, Shop),
		  RepoId = ?v(<<"repo_id">>, Shop),
		  Charge = ?v(<<"charge_id">>, Shop),
		  Score  = ?v(<<"score_id">>, Shop), 
		  Region = ?v(<<"region_id">>, Shop),
		  Address = ?v(<<"addr">>, Shop),
		  BCodeFriend = ?v(<<"bcode_friend">>, Shop),
		  BCodePay    = ?v(<<"bcode_pay">>, Shop),
		  Type   = ?v(<<"type">>, Shop),
		  S = {Id, Name, FunId, RepoId, Charge, Score, Region, Type,
		       Address, BCodeFriend, BCodePay},
		  case lists:member(S, Acc) of
		      true  ->  Acc;
		      false -> [S|Acc]
		  end
	  end, [],  Shops),
    %% ?DEBUG("sort shops ~p", [SortShops]),
    SortShops.


filter_account(Accounts) ->
    filter_account(Accounts, 0, 0).
filter_account([], MaxCreate, ExistCreate) ->
    {MaxCreate, ExistCreate};
filter_account([{Account}|T], MaxCreate, ExistCreate) ->
    case ?v(<<"type">>, Account) of
	?MERCHANT ->
	    filter_account(
	      T, ?v(<<"max_create">>, Account) + MaxCreate, ExistCreate);
	?USER ->
	    filter_account(
	      T, MaxCreate, ExistCreate + 1)
    end.

login_user(right, Session) ->
    case ?session:get(type, Session) of
	?SUPER ->
	    ?right_init:lookup(super);
	    %% ?utils:respond(200, batch, Req, Catlogs);
	_ ->
	    Catlogs = ?right_auth:catlog(session, Session),
	    {ok, Catlogs}
	    %% ?utils:respond(200, batch, Req, Catlogs)
    end;

login_user(shop, Session) -> 
    case ?session:get(type, Session) of
	?SUPER ->
	    ?shop:lookup();
	?MERCHANT -> 
	    {ok, S} = ?shop:lookup(?session:get(merchant, Session)),
	    lists:foldr(
	      fun({AShop}, Acc) ->
		      [{[{<<"shop_id">>,   ?v(<<"id">>,   AShop)},
			 {<<"name">>,      ?v(<<"name">>, AShop)},
			 {<<"bcode_friend">>, ?v(<<"bcode_friend">>, AShop)},
			 {<<"bcode_pay">>,    ?v(<<"bcode_pay">>, AShop)},
			 {<<"addr">>,      ?v(<<"address">>, AShop)},
			 {<<"repo_id">>,   ?v(<<"repo">>, AShop)},
			 {<<"charge_id">>, ?v(<<"charge_id">>, AShop)},
			 {<<"score_id">>,  ?v(<<"score_id">>, AShop)},
			 {<<"region_id">>, ?v(<<"region_id">>, AShop)},
			 {<<"type">>,      ?v(<<"type">>, AShop)},
			 {<<"deleted">>,   ?v(<<"deleted">>, AShop)},
			 {<<"func_id">>,   ?right_w_inventory}]}
		       | Acc]
	      end, [], S);
	?USER ->
	    ?right_auth:get_user_shop(Session)
    end.
	


