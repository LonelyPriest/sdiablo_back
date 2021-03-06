-module(diablo_controller_shop_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).

action(Session, Req) ->
    {ok, HTMLOutput} = shop_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "shopApp"},
			  %% {ngcontroller, "shopCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).


%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_shop"}) ->
    ?DEBUG("list_shop with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:lookup(Merchant) end, Req);
%% {ok, M} = ?shop:lookup(?session:get(merchant, Session)),
%% ?utils:respond(200, batch, Req, M);

action(Session, Req, {"list_repo"}) ->
    ?DEBUG("list_repo with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:repo(list, Merchant) end, Req);

action(Session, Req, {"list_badrepo"}) ->
    ?DEBUG("list_badrepo with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:badrepo(list, Merchant) end, Req);

action(Session, Req, {"list_shop_promotion"}) ->
    ?DEBUG("list_shop_promotion with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?shop:promotion(list, Merchant) end, Req);

action(Session, Req, {"list_region"}) ->
    ?DEBUG("list_region with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_user_profile:get(region, Merchant) end, Req);

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%-------------------------------------------------------------------- 
action(Session, Req, {"delete_shop", Id}) ->
    ?DEBUG("delete_shop with session ~p, id ~p", [Session, Id]), 
    Merchant = ?session:get(merchant, Session),
    UTable = ?session:get(utable, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:shop(delete, {Merchant, UTable}, Id) end,
		   fun(ShopId)-> ?succ(delete_shop, ShopId) end,
		   Req).

    %% case ?shop:shop(delete, Merchant, ?to_i(Id)) of
    %% 	{ok, ShopId} ->
    %% 	    ?utils:respond(200, Req, ?succ(delete_shop, ShopId));
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, Req, Error)
    %% end. 

%% ================================================================================
%% POST
%% ================================================================================
action(Session, Req, {"new_shop"}, Payload) ->
    ?DEBUG("add a new shop with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:shop(new, Merchant, Payload) end,
		   fun(ShopId)-> ?succ(add_shop, ShopId) end,
		   Req); 

action(Session, Req, {"update_shop", Id}, Payload) ->
    ?DEBUG("update a shop with session ~p, id ~p, paylaod ~p",
	   [Session, Id, Payload]), 
    Merchant = ?session:get(merchant, Session),

    ImageFriendPath = 
	case ?v(<<"bcode_friend">>, Payload) of
	    undefined -> [];
	    FriendData ->
		FriendPath = filename:join([?w_good_request:image(dir, Merchant), Id, "friend.png"]),
		ok = ?w_good_request:mk_image_dir(FriendPath, Merchant),
		ok = file:write_file(FriendPath, base64:decode(FriendData)),
		filename:join(["image", ?to_s(Merchant), Id, filename:basename(FriendPath)])
	end,

    ImagePayPath = 
	case ?v(<<"bcode_pay">>, Payload) of
	    undefined -> [];
	    PayData ->
		PayPath = filename:join([?w_good_request:image(dir, Merchant), Id, "pay.png"]),
		ok = ?w_good_request:mk_image_dir(PayPath, Merchant),
		ok = file:write_file(PayPath, base64:decode(PayData)),
		filename:join(["image", ?to_s(Merchant), Id, filename:basename(PayPath)])
	end,

    Attrs = lists:keydelete(<<"bcode_friend">>, 1,  lists:keydelete(<<"bcode_pay">>, 1, Payload)),
	    
    case ?shop:shop(update, Merchant, Id, [{<<"bcode_friend">>, ImageFriendPath},
					   {<<"bcode_pay">>, ImagePayPath}] ++  Attrs) of
    	{ok, Id} ->
	    ?w_user_profile:update(shop, Merchant), 
	    ?w_user_profile:update(user_shop, Merchant, Session), 
    	    ?utils:respond(200, Req, ?succ(update_shop, Id));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_shop_charge", Id}, Payload) ->
    ?DEBUG("update_shop_charge with session ~p, id ~p, paylaod ~p",
	   [Session, Id, Payload]), 
    Merchant = ?session:get(merchant, Session),
    case ?shop:shop(update_charge, Merchant, Id, Payload) of
    	{ok, Id} ->
	    ?w_user_profile:update(shop, Merchant), 
	    ?w_user_profile:update(user_shop, Merchant, Session), 
    	    ?utils:respond(200, Req, ?succ(update_shop, Id));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end; 

%% repo
action(Session, Req, {"new_repo"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:repo(new, Merchant, Payload) end,
		   fun(RepoId)-> ?succ(add_repo, RepoId) end,
		   Req);

action(Session, Req, {"new_badrepo"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:badrepo(new, Merchant, Payload) end,
		   fun(RepoId)-> ?succ(add_repo, RepoId) end,
		   Req);

action(Session, Req, {"add_shop_promotion"}, Payload) ->
    ?DEBUG("add_promotion with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),

    ?utils:respond(normal,
		   fun()-> ?shop:promotion(new, Merchant, Payload) end,
		   fun(ShopId)-> ?succ(add_shop_promotion, ShopId) end,
		   Req);

action(Session, Req, {"new_region"}, Payload) ->
    ?DEBUG("new region with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?shop:region(new, Merchant, Payload) end,
		   fun(RegionId)-> ?succ(add_shop, RegionId) end,
		   Req);

action(Session, Req, {"update_region", RegionId}, Payload) ->
    ?DEBUG("update_region with session ~p, regionId ~p, paylaod ~p",
	   [Session, RegionId, Payload]), 
    Merchant = ?session:get(merchant, Session),
    case ?shop:region(update, Merchant, RegionId, Payload) of
    	{ok, Id} ->
	    ?w_user_profile:update(region, Merchant), 
    	    ?utils:respond(200, Req, ?succ(update_shop, Id));
    	{error, Error} ->
    	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_cost_class"}, Payload) ->
    ?DEBUG("new region with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Name = ?v(<<"name">>, Payload, []),
    PinYin = ?v(<<"py">>, Payload, []),
    ?utils:respond(normal,
		   fun()-> ?shop:cost_class(new, Merchant, {Name, PinYin}) end,
		   fun(RegionId)-> ?succ(add_shop, RegionId) end,
		   Req);

action(Session, Req, {"list_cost_class"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    ?pagination:pagination(
       fun(_Match, _Conditions) -> ?shop:cost_class(total, Merchant) end,
       fun(_Match, CurrentPage, ItemsPerPage, _Conditions) ->
	       ?shop:cost_class(filter, Merchant, CurrentPage, ItemsPerPage)
       end, Req, Payload);

action(Session, Req, {"match_cost_class"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    Prompt   = ?v(<<"prompt">>, Payload),
    Ascii    = ?v(<<"ascii">>, Payload, ?YES), 
    ?utils:respond(batch, fun() ->?shop:cost_class(like_match, Merchant, {Prompt, Ascii}) end, Req).

sidebar(Session) ->
    AuthenFun =
	fun(Actions) ->
		lists:foldr(
		  fun({Action, Detail}, Acc) ->
			  case ?right_auth:authen(Action, Session) of
			      {ok, Action} -> [Detail|Acc];
			      _ -> Acc
			  end 
		  end, [], Actions)
		
	end,

    ShopAuthen = AuthenFun(
		   [{?new_shop,
		     {"shop_new", "新增店铺", "glyphicon glyphicon-plus"}},
		    {?list_shop,
		     {"shop_detail", "店铺详情", "glyphicon glyphicon-book"}}
		   ]), 

    
    L1 = case AuthenFun(
		[{?list_region,
		  {"region_detail", "区域", "glyphicon glyphicon-th-list"}},
		 {?list_cost_class,
		  {"cost_class_detail", "费用类型", "glyphicon glyphicon-font"}}
		]) of
	     [] -> [];
	     Region  ->
		 ?menu:sidebar(level_1_menu, Region)
	 end,

    L2 = 
	case ShopAuthen of
	    []   -> [];
	    Shop ->
		[{{"shop", "店铺", "glyphicon glyphicon-map-marker"}, Shop}] 
	end,
    
    ?menu:sidebar(level_2_menu, L2) ++ L1.


