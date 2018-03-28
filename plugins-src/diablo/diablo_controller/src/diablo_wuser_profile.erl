%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  9 Apr 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_wuser_profile).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0, start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([new/1, new/2, get/1, get/2, get/3,
	 update/2, update/3, set_default/1, set_default/2, set_template/2]).
-export([filter/3]).

%% -define(SERVER, ?MODULE).
%% -define(SERVER(M), ?wpool:get(?MODULE, M)).
-define(SERVER(M), ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

new(Merchant) ->
    gen_server:call(?SERVER(Merchant), {new_profile, Merchant}).
new(Merchant, SessionId) ->
    gen_server:call(?SERVER(Merchant), {new_profile, Merchant, SessionId}).

get(Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_profile, Merchant}).

%% about print
get(merchant, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_merchant_profile, Merchant});
get(bank, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_bank_profile, Merchant});
get(setting, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_setting_profile, Merchant});
get(size_group, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_size_group_profile, Merchant});
get(shop, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_shop_profile, Merchant});
get(repo, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_repo_profile, Merchant});
get(region, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_region_profile, Merchant});
get(print, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_print_profile, Merchant});
get(print_format, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_print_format_profile, Merchant});
get(type, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_type_profile, Merchant});
%% get(retailer, Merchant) ->
%%     gen_server:call(?SERVER(Merchant), {get_retailer_profile, Merchant}); 
get(firm, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_firm_profile, Merchant});
get(employee, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_employee_profile, Merchant});
get(brand, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_brand_profile, Merchant});
get(color_type, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_color_type_profile, Merchant});
get(color, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_color_profile, Merchant});
get(promotion, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_promotion, Merchant});
get(charge, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_charge, Merchant});
get(score, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_score, Merchant});
get(sms_rate, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_sms_rate, Merchant});
get(sms_center, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_sms_center, Merchant});
get(retailer_level, Merchant) ->
    gen_server:call(?SERVER(Merchant), {get_retailer_level, Merchant}).


get(shop, Merchant, Shop) ->
    gen_server:call(?SERVER(Merchant), {get_shop_profile, Merchant, Shop});
get(repo, Merchant, Repo) ->
    gen_server:call(?SERVER(Merchant), {get_repo_profile, Merchant, Repo});
get(print, Merchant, Shop) ->
    gen_server:call(?SERVER(Merchant), {get_print_profile, Merchant, Shop});
get(print_format, Merchant, Shop) ->
    gen_server:call(?SERVER(Merchant), {get_print_format_profile, Merchant, Shop});
get(setting, Merchant, Shop) ->
    gen_server:call(?SERVER(Merchant), {get_setting_profile, Merchant, Shop}); 
get(size_group, Merchant, GId) ->
    gen_server:call(?SERVER(Merchant), {get_size_group_profile, Merchant, GId});
get(type, Merchant, TypeId) ->
    gen_server:call(?SERVER(Merchant), {get_type_profile, Merchant, TypeId});
%% get(retailer, Merchant, Retailer) -> 
%%     gen_server:call(?SERVER(Merchant), {get_retailer_profile, Merchant, Retailer});
get(sys_retailer, Merchant, Shops) ->
    gen_server:call(?SERVER(Merchant), {get_sysretailer_profile, Merchant, Shops});
get(firm, Merchant, Firm) ->
    gen_server:call(?SERVER(Merchant), {get_firm_profile, Merchant, Firm});
get(employee, Merchant, Employee) ->
    gen_server:call(?SERVER(Merchant), {get_employee_profile, Merchant, Employee});
get(brand, Merchant, BrandId) ->
    gen_server:call(?SERVER(Merchant), {get_brand_profile, Merchant, BrandId});
get(color, Merchant, ColorId) ->
    gen_server:call(?SERVER(Merchant), {get_color_profile, Merchant, ColorId});
get(charge, Merchant, ChargeId) ->
    gen_server:call(?SERVER(Merchant), {get_charge, Merchant, ChargeId});

%% about right of login user
get(user_right, Merchant, Session) ->
    gen_server:call(?SERVER(Merchant), {get_user_right, Merchant, Session});
get(user_shop, Merchant, Session) ->
    gen_server:call(?SERVER(Merchant), {get_user_shop, Merchant, Session});
get(user_nav, Merchant, Session) ->
    gen_server:call(?SERVER(Merchant), {get_user_nav, Merchant, Session});
get(user, Merchant, UserId) ->
    gen_server:call(?SERVER(Merchant), {get_user_profile, Merchant, UserId}).

set_default(Merchant) ->
    set_default(Merchant, -1).
set_default(Merchant, Shop) ->
    gen_server:call(?SERVER(Merchant), {set_default, Merchant, Shop}).
set_template(barcode_print, Merchant) ->
    gen_server:call(?SERVER(Merchant), {set_barcode_print_template, Merchant}).

update(merchant, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_merchant, Merchant}); 
update(good, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_good, Merchant}); 
update(setting, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_setting, Merchant});
update(bank, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_bank, Merchant});
update(shop, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_shop, Merchant});
update(employee, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_employee, Merchant});
update(print, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_print, Merchant});
update(type, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_type, Merchant});
update(brand, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_brand, Merchant});
update(print_format, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_print_format, Merchant});
update(firm, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_firm_format, Merchant});
update(sysretailer, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_sysretailer, Merchant});
update(color, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_color, Merchant});
update(size_group, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_sizegroup, Merchant});
update(promotion, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_promotion, Merchant});
update(charge, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_charge, Merchant});
update(score, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_score, Merchant});
update(sms_rate, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_sms_rate, Merchant});
update(region, Merchant) ->
    gen_server:cast(?SERVER(Merchant), {update_region, Merchant}).



update(user_shop, Merchant, Session) ->
    gen_server:cast(?SERVER(Merchant), {update_user_shop, Merchant, Session}).


start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    ets:new(?WUSER_PROFILE, [set, private, named_table]),
    ets:new(?WUSER_SESSION_PROFILE, [set, private, named_table]), 
    {ok, #state{}}.


handle_call({new_profile, Merchant}, _From, State) ->
    ?DEBUG("new profile of merchant ~p", [Merchant]),

    try
	{ok, MerchantInfo} = ?merchant:merchant(get, Merchant),
	{ok, Shops}        = ?shop:lookup(Merchant),
	{ok, Repoes}       = ?shop:repo(list, Merchant),
	{ok, Regions}      = ?shop:region(list, Merchant),
	
	%% {ok, Cards}        = ?w_base:bank_card(list, Merchant), 
	%% base stting
	{ok, Setting}      = ?w_base:setting(list, Merchant),
	{ok, SizeGroups}   = ?attr:size_group(list, Merchant),
	{ok, Types}        = ?attr:type(list, Merchant),
	{ok, Prints}       = ?w_print:printer(list_conn, Merchant),
	{ok, PFormats}     = ?w_print:format(list, Merchant),
	
	{ok, Employees}    = ?employ:employ(list, Merchant),
	{ok, Brands}       = ?attr:brand(list, Merchant),
	{ok, Firms}        = ?supplier:supplier(w_list, Merchant),
	{ok, ColorTypes}   = ?attr:color_type(list, Merchant),
	{ok, Colors}       = ?attr:color(w_list, Merchant),

	{ok, Promotions}   = ?promotion:promotion(list, Merchant),
	{ok, Charges}      = ?w_retailer:charge(list, Merchant),
	{ok, Scores}       = ?w_retailer:score(list, Merchant),

	{ok, SMSRate}      = ?merchant:sms(list, Merchant),
	{ok, SMSCenter}    = ?merchant:sms(list_center, Merchant),
	{ok, Levels}       = ?w_retailer:retailer(list_level, Merchant),

	{ok, SysRetailers} = ?w_retailer:retailer(list_sys, Merchant),
	
	%% good
	%% Goods = ?w_inventory:purchaser_good(lookup, Merchant), 
	true = ets:insert(?WUSER_PROFILE,
			  {?to_i(Merchant), #wuser_profile{
				  merchant    = ?to_i(Merchant), 
				  info        = MerchantInfo,
				  shop        = Shops,
				  repo        = Repoes,
				  region      = Regions, 
				  print       = Prints,
				  pformat     = PFormats,
				  %% bank        = ?to_tl(Cards),
				  setting     = ?to_tl(Setting),
				  size_groups = SizeGroups,
				  itype       = Types,
				  firm        = Firms,
				  employee    = Employees,
				  sysretailer = SysRetailers,
				  brand       = Brands,
				  color_type  = ColorTypes,
				  color       = Colors,
				  promotion   = Promotions,
				  charge      = Charges,
				  score       = Scores,

				  sms_rate    = SMSRate,
				  sms_center  = SMSCenter,
				  level       = Levels
				  %% good     = ?to_tl(Goods)
				 }
			  })
    catch _:_ ->
	    ?INFO("=== failed to new profile of merchant ~p~n~p ===",
		  [Merchant, erlang:get_stacktrace()]),
	    {reply, {ok, Merchant}, State}
    end,
    
    {reply, {ok, Merchant}, State};

handle_call({new_profile, Merchant, SessionId}, _From, State) ->
    ?DEBUG("=== new session profile of merchant ~p, session ~p === ",
	   [Merchant, SessionId]),
    try
	{ok, Session} = ?session:lookup(SessionId),
	{ok, Catlogs} = ?right_request:login_user(right, Session),
	Shops = ?right_request:login_user(shop, Session),
	
	Navs = user_nav(Session), 
	UserId = ?session:get(id, Session),
	UserType = ?session:get(type, Session),
	true = ets:insert(?WUSER_SESSION_PROFILE,
			 {{Merchant, UserId},
			 #wuser_session_profile{
			    merchant = Merchant,
			    user     = UserId,
			    type     = UserType,
			    right    = Catlogs,
			    shop     = Shops,
			    nav      = Navs
			   }})
    catch _:_ ->
	    {ok, Merchant, SessionId}
    end,

    {reply, {ok, Merchant, SessionId}, State};

handle_call({get_user_profile, Merchant, UserId}, _From, State) ->
    ?DEBUG("get_user_profile merchant ~p, user ~p", [Merchant, UserId]),
    MS = ms(Merchant, UserId, user), 
    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Profile] ->
	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
	    {reply, {ok, Profile}, State}
    end;

handle_call({get_user_right, Merchant, Session}, _From, State) ->
    ?DEBUG("get_user_right merchant ~p, session ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    Select = select(user, MS, fun()-> ?right_request:login_user(right, Session) end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.right}, State};
	false -> {reply, {ok, Select}, State}
    end;
    %% case ets:select(?WUSER_PROFILE, MS) of
    %% 	[] ->
    %% 	    {reply, {ok, []}, State};
    %% 	[Profile] ->
    %% 	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
    %% 	    {reply, {ok, Profile#wuser_session_profile.right}, State}
    %% end;

handle_call({get_user_shop, Merchant, Session}, _From, State) ->
    ?DEBUG("get_login_user_shop merchant ~p, select ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    Select = select(user, MS, fun()-> {ok, ?right_request:login_user(shop, Session)} end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.shop}, State};
	false -> {reply, {ok, Select}, State}
    end; 

handle_call({get_user_nav, Merchant, Session}, _From, State) ->
    ?DEBUG("get_login_user_nav merchant ~p, select ~p", [Merchant, Session]),
    UserId = ?session:get(id, Session),
    MS = ms(Merchant, UserId, user),
    %% TryFun = fun() ->
    %% 		     case ?session:get(type, Session) of
    %% 			 ?SUPER ->
    %% 			     ?right_auth:navbar(super);
    %% 			 _ ->
    %% 			     ?right_auth:navbar(session, Session)
    %% 		     end
    %% 	     end,
    Select = select(user, MS, fun()-> {ok, user_nav(Session)} end),
    case is_record(Select, wuser_session_profile) of
	true -> {reply, {ok, Select#wuser_session_profile.nav}, State};
	false -> {reply, {ok, Select}, State}
    end;

handle_call({get_profile, Merchant}, _From, State) ->
    ?DEBUG("get_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {reply, {ok, []}, State};
	[Profile] ->
	    ?DEBUG("user profile of merchant ~p~n~p", [Merchant, Profile]),
	    {reply, {ok, Profile}, State}
    end;

handle_call({get_merchant_profile, Merchant}, _From, State) ->
    ?DEBUG("get_merchant_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', info='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    Select = select(MS, fun() -> ?merchant:merchant(get, Merchant) end),
    {reply, {ok, Select}, State};

%% handle_call({get_bank_profile, Merchant}, _From, State) ->
%%     ?DEBUG("get_bank_profile of merchant ~p", [Merchant]),
%%     MS = [{{'$1', #wuser_profile{merchant='$1', bank='$2', _='_'}}, 
%% 	   [{'==', '$1', ?to_i(Merchant)}],
%% 	   ['$2']
%% 	  }],

%%     case ets:select(?WUSER_PROFILE, MS) of
%% 	[] ->
%% 	    {reply, {ok, []}, State};
%% 	[Bank] ->
%% 	    ?DEBUG("bank ~p of merchant ~p", [Bank, Merchant]),
%% 	    {reply, {ok, Bank}, State}
%%     end;

%%
%% Setting
%%
handle_call({get_setting_profile, Merchant}, _From, State) ->
    ?DEBUG("get_setting_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, setting),

    Select = select(MS, fun() -> ?w_base:setting(list, Merchant) end), 
    {reply, {ok, Select}, State};
    %% case ets:select(?WUSER_PROFILE, MS) of
    %% 	[] ->
    %% 	    {ok, Setting} = ?w_base:setting(list, Merchant),
    %% 	    {reply, {ok, Setting}, State};
    %% 	[Setting] ->
    %% 	    ?DEBUG("base setting ~p of merchant ~p", [Setting, Merchant]),
    %% 	    {reply, {ok, Setting}, State}
    %% end;

handle_call({get_setting_profile, Merchant, Shop}, _From, State) ->
    MS = ms(Merchant, setting),
    Select = select(MS, fun() -> ?w_base:setting(list, Merchant, {<<"shop">>, [Shop, -1]}) end),
    F = case filter(Select, <<"shop">>, Shop) of
	    [] -> filter(Select, <<"shop">>, -1);
	    Filter -> Filter
	end,
    {reply, {ok, F}, State};


handle_call({get_size_group_profile, Merchant}, _From, State) ->
    ?DEBUG("get_size_group_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, size_group), fun() -> ?attr:size_group(list, Merchant) end), 
    {reply, {ok, Select}, State};

handle_call({get_size_group_profile, Merchant, GId}, _From, State) ->
    ?DEBUG("get_size_group_profile of merchant ~p, GId ~p", [Merchant, GId]), 
    Select = select(ms(Merchant, size_group), fun() -> ?attr:size_group(list, Merchant) end), 
    SelectGroup = filter(Select, <<"id">>, ?to_i(GId)),
    {reply, {ok, SelectGroup}, State}; 

handle_call({get_shop_profile, Merchant}, _From, State) ->
    ?DEBUG("get_shop_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', shop='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Shops} = ?shop:lookup(Merchant),
	    {reply, {ok, Shops}, State};
	[Shops] ->
	    %% ?DEBUG("shop ~p of merchant ~p", [Shops, Merchant]),
	    {reply, {ok, Shops}, State}
    end;


handle_call({get_shop_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_shop_profile of merchant ~p, shop ~p", [Merchant, Shop]),
    MS = [{{'$1', #wuser_profile{merchant='$1', shop='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],
    GetShop = fun(Shops) ->
		      lists:foldr(
			fun({S}, Acc) ->
				case ?v(<<"id">>, S) =:= ?to_i(Shop) of
				    true ->
					[{S}|Acc];
				    false -> Acc
				end
			end, [], Shops)
	      end,

    %% R = ets:select(?WUSER_PROFILE, MS),
    %% ?DEBUG("R ~p", [R]),
    NewShops = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Shops} = ?shop:lookup(Merchant, {<<"id">>, Shop}),
		GetShop(Shops);
	    [Shops] ->
		%% ?DEBUG("shop ~p of merchant ~p", [Shops, Merchant]),
		GetShop(Shops) 
	end,
   
	
    {reply, {ok, NewShops}, State};

handle_call({get_repo_profile, Merchant}, _From, State) ->
    ?DEBUG("get_repo_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', repo='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Repoes} = ?shop:repo(list, Merchant),
	    {reply, {ok, Repoes}, State};
	[Repoes] ->
	    ?DEBUG("repo ~p of merchant ~p", [Repoes, Merchant]),
	    {reply, {ok, Repoes}, State}
    end;


handle_call({get_repo_profile, Merchant, Repo}, _From, State) ->
    ?DEBUG("get_repo_profile of merchant ~p, Repo ~p", [Merchant, Repo]),
    MS = [{{'$1', #wuser_profile{merchant='$1', repo='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    GetFun =
	fun(Repoes) ->
		lists:foldr(
		  fun({R}, Acc) ->
			  case ?v(<<"id">>, R) =:= ?to_i(Repo) of
			      true ->
				  [{R}|Acc];
			      false -> Acc
			  end
		  end, [], Repoes)
	     end,

    NewRepoes = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Repoes} = ?shop:repo(list, Merchant, Repo),
		GetFun(Repoes); 
	    [Repoes] ->
		?DEBUG("repo ~p of merchant ~p", [Repoes, Merchant]),
		GetFun(Repoes)
	end, 
    {reply, {ok, NewRepoes}, State};


handle_call({get_region_profile, Merchant}, _From, State) ->
    ?DEBUG("get_region_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, region), 
    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Regions} = ?shop:region(list, Merchant),
	    {reply, {ok, Regions}, State};
	[Regions] ->
	    ?DEBUG("regions ~p of merchant ~p", [Regions, Merchant]),
	    {reply, {ok, Regions}, State}
    end;

handle_call({get_print_profile, Merchant}, _From, State) ->
    ?DEBUG("get_print_profile of merchant ~p", [Merchant]),
    MS = [{{'$1', #wuser_profile{merchant='$1', print='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    case ets:select(?WUSER_PROFILE, MS) of
	[] ->
	    {ok, Prints} = ?w_print:printer(list_conn, Merchant),
	    {reply, {ok, Prints}, State};
	[Prints] ->
	    ?DEBUG("print ~p of merchant ~p", [Prints, Merchant]),
	    {reply, {ok, Prints}, State}
    end;

handle_call({get_print_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_print_profile of merchant ~p, shop ~p", [Merchant, Shop]),
    MS = [{{'$1', #wuser_profile{merchant='$1', print='$2', _='_'}},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    GetPrint = fun(Prints) ->
		       lists:foldr(
			 fun({P}, Acc) ->
				 case ?v(<<"shop_id">>, P) =:= ?to_i(Shop)
				     andalso ?v(<<"status">>, P) =:= ?START of
				     true ->
					 [{P}|Acc];
				     false -> Acc
				 end
			 end, [], Prints)
	       end,
    
    NewPrints = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, Prints} = ?w_print:printer(list_conn, Merchant),
		GetPrint(Prints);
	    [Prints] ->
		%% ?DEBUG("print ~p of merchant ~p", [Prints, Merchant]),
		GetPrint(Prints) 
	end, 
    {reply, {ok, NewPrints}, State};

%%
%% formater options of print
%%
handle_call({get_print_format_profile, Merchant}, _From, State) ->
    ?DEBUG("get_print_format_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, pformat), fun() -> ?w_print:format(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_print_format_profile, Merchant, Shop}, _From, State) ->
    ?DEBUG("get_print_format_profile of merchant ~p", [Merchant]),
    Select = select(ms(Merchant, pformat), fun() -> ?w_print:format(list, Merchant) end),
    Format = 
	case filter(Select, <<"shop">>, Shop) of
	    [] -> filter(Select, <<"shop">>, -1);
	    F  -> F
	end,
    {reply, {ok, Format}, State};

%%
%% type of inventory
%%
handle_call({get_type_profile, Merchant}, _From, State) ->
    ?DEBUG("get_type_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, itype),
    Select = select(MS, fun() -> ?attr:type(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_type_profile, Merchant, TypeId}, _From, State) ->
    ?DEBUG("get_type_profile of merchant ~p, TypeId ~p", [Merchant, TypeId]),
    MS = ms(Merchant, itype),
    Select = select(MS, fun() -> ?attr:type(list, Merchant) end),

    SelectType = lists:filter(fun({Type}) ->
				      ?v(<<"id">>, Type) =:= TypeId
			      end, Select), 
    
    {reply, {ok, SelectType}, State};



%%
%% retailer
%%
%% handle_call({get_retailer_profile, Merchant}, _From, State) ->
%%     ?DEBUG("get_retailer_profile of merchant ~p", [Merchant]),
%%     MS = ms(Merchant, retailer),
%%     Select = select(MS, fun() -> ?w_retailer:retailer(list, Merchant) end),
%%     {reply, {ok, Select}, State};

handle_call({get_sysretailer_profile, Merchant, Shops}, _From, State) ->
    ?DEBUG("get_sysretailer_profile: merchant ~p, shops ~p", [Merchant, Shops]),
    %% Settings = select(ms(Merchant, setting), fun() -> ?w_base:setting(list, Merchant) end),
    %% FilterSettings = 
    %% 	case lists:filter(
    %% 	       fun({S})->
    %% 		       lists:member(?v(<<"shop">>, S), Shops) orelse ?v(<<"shop">>, S) =:= -1
    %% 	       end, ?to_tl(Settings)) of
    %% 	    [] -> [];
    %% 	    Filter -> Filter
    %% 	end, 
    
    %% SysVips = lists:foldr(
    %% 		fun({S}, Acc) ->
    %% 			case ?v(<<"ename">>, S) =:= <<"s_customer">> of
    %% 			    true ->
    %% 				SysVip = ?to_i(?v(<<"value">>, S)),
    %% 				%% ?DEBUG("sysvip ~p", [SysVip]),
    %% 				case lists:member(SysVip, Acc) of
    %% 				    true -> Acc;
    %% 				    false -> [SysVip] ++ Acc
    %% 				end;
    %% 			    false -> Acc
    %% 			end
    %% 		end, [], FilterSettings), 
    %% ?DEBUG("SysVips ~p", [SysVips]),
    
    SysRetailers = select(ms(Merchant, sysretailer), fun() -> ?w_retailer:retailer(list_sys, Merchant) end),
    %% ?DEBUG("sysRetailers ~p", [SysRetailers]),
    
    FilterRetailers = 
	case lists:filter(
	       fun({R})-> 
		       lists:member(?v(<<"shop_id">>, R), Shops) end,
	       ?to_tl(SysRetailers))
	of
	    [] -> [];
	    RFilter -> RFilter
	end, 
    %% ?DEBUG("FilterRetailers ~p", [FilterRetailers]),

    SimpleRetailers = 
	lists:foldr(
	  fun({R}, Acc)->
		  R1 = lists:keydelete(
			 <<"address">>, 1,
			 lists:keydelete(
			   <<"birth">>, 1,
			   lists:keydelete(
			     <<"consume">>, 1,
			     lists:keydelete(
			       <<"entry_date">>, 1,
			       lists:keydelete(
				 <<"shop">>, 1,
				 lists:keydelete(<<"merchant">>, 1, R)))))),
		  [{R1}|Acc]
	  end, [], FilterRetailers),

    %% ?DEBUG("SimpleRetailers ~p", [SimpleRetailers]),
    
    {reply, {ok, SimpleRetailers}, State};

%% handle_call({get_retailer_profile, Merchant, RetailerId}, _From, State) ->
%%     ?DEBUG("get_retailer_profile of merchant ~p, Retailer ~p",
%% 	   [Merchant, RetailerId]),
%%     MS = ms(Merchant, retailer),
%%     Select = select(MS, fun() -> ?w_retailer:retailer(list, Merchant) end),
%%     SelectRetailer = filter(Select, <<"id">>, RetailerId),
%%     {reply, {ok, SelectRetailer}, State};

%%
%% firm
%%
handle_call({get_firm_profile, Merchant}, _From, State) ->
    ?DEBUG("get_firm_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, firm),
    Select = select(MS, fun() -> ?supplier:supplier(w_list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_firm_profile, Merchant, FirmId}, _From, State) ->
    MS = ms(Merchant, firm),
    Select = select(MS, fun() -> ?supplier:supplier(w_list, Merchant) end),
    SelectFirm = filter(Select, <<"id">>, FirmId),
    {reply, {ok, SelectFirm}, State};
%%
%% employee
%%
handle_call({get_employee_profile, Merchant}, _From, State) ->
    ?DEBUG("get_employee_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, employee),
    Select = select(MS, fun() -> ?employ:employ(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_employee_profile, Merchant, EmpId}, _From, State) ->
    ?DEBUG("get_employee_profile of merchant ~p, empid ~p",
	   [Merchant, EmpId]),
    MS = ms(Merchant, employee),
    Select = select(MS, fun() -> ?employ:employ(list, Merchant) end), 
    SelectEmployee = filter(Select, <<"number">>, EmpId), 
    {reply, {ok, SelectEmployee}, State};


%%
%% employee
%%
handle_call({get_brand_profile, Merchant}, _From, State) ->
    ?DEBUG("get_brand_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, brand),
    Select = select(MS, fun() -> ?attr:brand(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_brand_profile, Merchant, BrandId}, _From, State) ->
    ?DEBUG("get_brand_profile of merchant ~p, Brand ~p", [Merchant, BrandId]),
    MS = ms(Merchant, brand),
    Select = select(MS, fun() -> ?attr:brand(list, Merchant) end), 
    SelectEmployee = filter(Select, <<"id">>, BrandId), 
    {reply, {ok, SelectEmployee}, State};

%%
%% color
%%
handle_call({get_color_type_profile, Merchant}, _From, State) ->
    ?DEBUG("get_color_type_profile of merchant ~p", [Merchant]),
    MS = ms(Merchant, color_type),
    Select = select(MS, fun() -> ?attr:color_type(list, Merchant) end),
    {reply, {ok, Select}, State};
handle_call({get_color_profile, Merchant}, _From, State) ->
    MS = ms(Merchant, color),
    Select = select(MS, fun() -> ?attr:color(w_list, Merchant) end),
    {reply, {ok, Select}, State};
handle_call({get_color_profile, Merchant, ColorId}, _From, State) ->
    MS = ms(Merchant, color),
    Select = select(MS, fun() -> ?attr:color(w_list, Merchant) end),
    SelectColor = lists:filter(fun({Color}) ->
				       ?v(<<"id">>, Color) =:= ColorId
			      end, Select), 
    {reply, {ok, SelectColor}, State};

%% promotion
handle_call({get_promotion, Merchant}, _From, State) ->
    MS = ms(Merchant, promotion),
    Select = select(MS, fun() -> ?promotion:promotion(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_promotion, Merchant, PId}, _From, State) ->
    MS = ms(Merchant, promotion),
    Select = select(MS, fun() -> ?promotion:promotion(list, Merchant) end),
    SelectPromotion = lists:filter(fun({Promotion}) ->
				       ?v(<<"id">>, Promotion) =:= PId
			       end, Select), 
    {reply, {ok, SelectPromotion}, State};

handle_call({get_charge, Merchant}, _From, State) ->
    MS = ms(Merchant, charge),
    Select = select(MS, fun() -> ?w_retailer:charge(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_charge, Merchant, ChargeId}, _From, State) ->
    MS = ms(Merchant, charge),
    Select = select(MS, fun() -> ?w_retailer:charge(list, Merchant) end),
    Charge = filter(Select, <<"id">>, ChargeId), 
    {reply, {ok, Charge}, State};

handle_call({get_score, Merchant}, _From, State) ->
    MS = ms(Merchant, score),
    Select = select(MS, fun() -> ?w_retailer:score(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_sms_rate, Merchant}, _From, State) ->
    MS = ms(Merchant, sms_rate),
    Select = select(MS, fun() -> ?merchant:sms(list, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_sms_center, Merchant}, _From, State) ->
    MS = ms(Merchant, sms_center),
    Select = select(MS, fun() -> ?merchant:sms(list_center, Merchant) end),
    {reply, {ok, Select}, State};

handle_call({get_retailer_level, Merchant}, _From, State) ->
    MS = ms(Merchant, retailer_level),
    Select = select(MS, fun() -> ?w_retailer:retailer(list_level, Merchant) end),
    {reply, {ok, Select}, State};


handle_call({set_default, Merchant, Shop}, _From, State) ->
    ?DEBUG("set default value of merchant ~p, shop ~p", [Merchant, Shop]),
    %% base setting
    Now = ?utils:current_time(format_localtime), 
    Values = case Shop of
		 -1 -> ?w_base:sys_config();
		 _ -> ?w_base:sys_config(shop)
	     end,
    Sql0 = lists:foldr(
	    fun({EName, CName, Value, Type}, Acc) ->
		    Sql00 = "select id, ename, value from w_base_setting"
			" where ename=\'" ++ EName ++ "\'"
			" and shop=" ++ ?to_s(Shop)
			++ " and merchant=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(s_read, Sql00) of
			{ok, []} ->
			    ["insert into w_base_setting("
			     "ename, cname, value, type"
			     ", remark, shop, merchant, entry_date) values("
			     "\'" ++ EName ++ "\',"
			     "\'" ++ CName ++ "\',"
			     ++ "\'" ++ ?to_s(Value) ++ "\',"
			     ++ Type  ++ ","
			     ++ "\'\',"
			     ++ ?to_s(Shop)  ++ ","
			     ++ ?to_s(Merchant) ++ "," 
			     "\'" ++ Now ++ "\');"|Acc];
			{ok, _} ->
			    Acc
		    end
	    end, [], Values),

    %% print format
    %% {name, isPrint}
    Formats = ?w_print:print_format(), 
    Sql1 = lists:foldr(
	     fun({Name, Print}, Acc) ->
		     Sql01 = "select id, name, print from w_print_format"
			 " where name=\'" ++ Name ++ "\'"
			 " and shop=" ++ ?to_s(Shop)
			 ++ " and merchant=" ++ ?to_s(Merchant),
		     case ?sql_utils:execute(s_read, Sql01) of
			 {ok, []} ->
			     ["insert into w_print_format("
			      "name, print, shop, merchant, entry_date) values("
			      "\'" ++ Name ++ "\',"
			      ++ Print ++ ","
			      ++ ?to_s(Shop) ++ ","
			      ++ ?to_s(Merchant) ++ "," 
			      "\'" ++ Now ++ "\')"|Acc];
			 {ok, _} ->
			     Acc
		     end
	     end, [], Formats),

    Reply = ?sql_utils:execute(transaction, Sql0 ++ Sql1, ok),
    {reply, Reply, State};

handle_call({set_barcode_print_template, Merchant}, _From, State) ->
    Sql0 = "select id, width, height from print_template"
	" where merchant=" ++ ?to_s(Merchant),
    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    Sql1 = "insert into print_template ("
		"width"
		", height"
	    %% ", dual_column"

		", shop"
		", style_number"
		", brand"
		", type"
		", firm"
		", code_firm"
		", expire" 
		
		", color"
		", size"
		
		", level"
		", executive"
		", category"
		", fabric"

		", font"
		", font_name"
		", font_executive"
		", font_category"
		", font_price"
		", font_fabric"
		
		", bold"
		
		", solo_brand"
		", solo_color"
		", solo_size" 
		
		", hpx_each"
		", hpx_executive"
		", hpx_category"
		", hpx_fabric"
		", hpx_price"
		", hpx_barcode"

		", hpx_top"
		", hpx_left"
		", second_space"

		", merchant) values("
		++ ?to_s(4) ++ ","
		++ ?to_s(3) ++ ","
	    %% ++ ?to_s(0) ++ ","

		++ ?to_s(0) ++ ","
		++ ?to_s(?YES) ++ ","
		++ ?to_s(?YES) ++ ","
		++ ?to_s(?YES) ++ ","
		++ ?to_s(?YES) ++ ","
		++ ?to_s(?NO) ++ ","
		++ ?to_s(?NO) ++ ","
		
		++ ?to_s(?YES) ++ ","
		++ ?to_s(?YES) ++ ","

		++ ?to_s(?NO) ++ ","
		++ ?to_s(?NO) ++ "," 
		++ ?to_s(?NO) ++ ","
		++ ?to_s(?NO) ++ ","
		
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		
		++ ?to_s(?NO) ++ ","

		++ ?to_s(?NO) ++ ","
		++ ?to_s(?NO) ++ ","
		++ ?to_s(?NO) ++ ","
		
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","
		++ ?to_s(0) ++ ","

		++ ?to_s(5) ++ ","
		++ ?to_s(10) ++ ","
		++ ?to_s(0) ++ ","
		
		++ ?to_s(Merchant)  ++ ")",

	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, _} ->
	    {reply, {ok, exist}, State}
    end;

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.



handle_cast({Update, Merchant}, State) ->
    ?DEBUG("update profile of merchant ~p, update ~p", [Merchant, Update]),
    %% get user profile
    MS = [{{'$1', '$2'},
	   [{'==', '$1', ?to_i(Merchant)}],
	   ['$2']
	  }],

    NewProfile = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		[];
	    [Profile] -> 
		case Update of
		    update_good ->
			%% Goods = ?w_inventory:purchaser_good(lookup, Merchant), 
			%% Profile#wuser_profile{good=?to_tl(Goods)};
			Profile; 
		    update_setting ->
			{ok, S} = ?w_base:setting(list, Merchant),
			Profile#wuser_profile{setting=?to_tl(S)}; 
		    %% update_bank ->
		    %% 	{ok, Cards} = ?w_base:bank_card(list, Merchant),
		    %% 	Profile#wuser_profile{bank=?to_tl(Cards)};
		    update_shop ->
			{ok, Shops} = ?shop:lookup(Merchant),
			Profile#wuser_profile{shop=Shops};
		    update_employee ->
			{ok, Employees}    = ?employ:employ(list, Merchant),
			Profile#wuser_profile{employee=Employees};
		    update_print ->
			{ok, Prints} = ?w_print:printer(list_conn, Merchant),
			Profile#wuser_profile{print=Prints};
		    update_type ->
			{ok, Types}        = ?attr:type(list, Merchant),
			Profile#wuser_profile{itype=Types};
		    update_brand ->
			{ok, Brands}        = ?attr:brand(list, Merchant),
			Profile#wuser_profile{brand=Brands};
		    update_print_format ->
			{ok, Formats} = ?w_print:format(list, Merchant),
			%% ?DEBUG("formats ~p", [Formats]),
			Profile#wuser_profile{pformat=?to_tl(Formats)};
		    update_firm_format ->
			{ok, Firms} = ?supplier:supplier(w_list, Merchant),
			Profile#wuser_profile{firm=Firms};
		     update_sysretailer ->
                        {ok, SysRetailers}=?w_retailer:retailer(list_sys, Merchant),
                        Profile#wuser_profile{sysretailer=SysRetailers}; 
		    update_color ->
			{ok, Colors}= ?attr:color(w_list, Merchant),
			Profile#wuser_profile{color=Colors};
		    update_sizegroup ->
			{ok, SizeGroups}   = ?attr:size_group(list, Merchant),
			Profile#wuser_profile{size_groups=SizeGroups};
		    update_promotion ->
			{ok, Promotions}
			    = ?promotion:promotion(list, Merchant),
			Profile#wuser_profile{promotion=Promotions};
		    update_charge ->
			{ok, Charges} = ?w_retailer:charge(list, Merchant), 
			Profile#wuser_profile{charge=Charges};
		    update_score ->
			{ok, Scores} = ?w_retailer:score(list, Merchant),
			Profile#wuser_profile{score=Scores};
		    update_sms_rate ->
			{ok, SMSRate}      = ?merchant:sms(list, Merchant),
			Profile#wuser_profile{sms_rate=SMSRate};
		    update_region ->
			{ok, Regions} = ?shop:region(list, Merchant),
			Profile#wuser_profile{region=Regions};
		    update_merchant ->
			{ok, Info} = ?merchant:merchant(get, Merchant),
			Profile#wuser_profile{info=Info}
		end 
	end,

    case NewProfile of
	[] -> {noreply, State};
	NewProfile ->
	    case ets:update_element(
		   ?WUSER_PROFILE, ?to_i(Merchant), {2, NewProfile}) of
		true ->
		    ?DEBUG("success to update profile of merchant ~p",
			   [Merchant]),
		    {noreply, State};
		false ->
		    ?DEBUG("failed to update profile of merchant ~p",
			   [Merchant]),
		    {noreply, State}
	    end
    end;


handle_cast({Update, Merchant, Session}, State) ->
    ?DEBUG("update user profile of merchant ~p, session ~p, update ~p",
	   [Merchant, Session, Update]),
    %% get user profile
    UserId = ?session:get(id, Session),
    
    MS = ms(Merchant, UserId, user),

    NewProfile = 
	case ets:select(?WUSER_SESSION_PROFILE, MS) of
	    [] ->
		[];
	    [Profile] -> 
		case Update of 
		    update_user_shop ->
			Shops = ?right_request:login_user(shop, Session), 
			Profile#wuser_session_profile{shop=Shops}
		end 
	end,

    case NewProfile of
	[] -> {noreply, State};
	NewProfile ->
	    case ets:update_element(
		   ?WUSER_SESSION_PROFILE,
		   {Merchant, UserId}, {2, NewProfile}) of
		true ->
		    ?DEBUG("success to update user session profile of "
			   "merchant ~p", [Merchant]),
		    {noreply, State};
		false ->
		    ?DEBUG("failed to update user session profile of "
			   "merchant ~p", [Merchant]),
		    {noreply, State}
	    end
    end;


handle_cast(_Msg, State) ->
    {noreply, State}.


handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.


code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
select(MS, RetryFun) ->
    Select = 
	case ets:select(?WUSER_PROFILE, MS) of
	    [] ->
		{ok, R} = RetryFun(),
		R;
	    [[]] ->
		{ok, R} = RetryFun(),
		R;
	    [R] ->
		R
	end,
    %% ?DEBUG("select ~p", [ets:select(?WUSER_PROFILE, MS)]),
    Select.


ms(Merchant, setting) ->
    [{{'$1', #wuser_profile{merchant='$1', setting='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];

ms(Merchant, pformat) ->
    [{{'$1', #wuser_profile{merchant='$1', pformat='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, itype) ->
    [{{'$1', #wuser_profile{merchant='$1', itype='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, sysretailer) ->
    [{{'$1', #wuser_profile{merchant='$1', sysretailer='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, firm) ->
    [{{'$1', #wuser_profile{merchant='$1', firm='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, employee) ->
    [{{'$1', #wuser_profile{merchant='$1', employee='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, brand) ->
    [{{'$1', #wuser_profile{merchant='$1', brand='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, size_group) ->
    [{{'$1', #wuser_profile{merchant='$1', size_groups='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, color_type) ->
    [{{'$1', #wuser_profile{merchant='$1', color_type='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, color) ->
    [{{'$1', #wuser_profile{merchant='$1', color='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, promotion) ->
    [{{'$1', #wuser_profile{merchant='$1', promotion='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, charge) ->
    [{{'$1', #wuser_profile{merchant='$1', charge='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, score) ->
    [{{'$1', #wuser_profile{merchant='$1', score='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, sms_rate) ->
    [{{'$1', #wuser_profile{merchant='$1', sms_rate='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];
ms(Merchant, sms_center) ->
    [{{'$1', #wuser_profile{merchant='$1', sms_center='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }]; 
ms(Merchant, retailer_level) ->
    [{{'$1', #wuser_profile{merchant='$1', level='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }];

ms(Merchant, region) ->
    [{{'$1', #wuser_profile{merchant='$1', region='$2', _='_'}},
      [{'==', '$1', ?to_i(Merchant)}],
      ['$2']
     }].

ms(Merchant, UserId, user) ->
    [{{{'$1', '$2'}, '$3'},
      [{'==', '$1', Merchant}, {'==', '$2', UserId}],
      ['$3']
     }].

select(user, MS, RetryFun) ->
    Select = 
	case ets:select(?WUSER_SESSION_PROFILE, MS) of
	    [] ->
		{ok, R} = RetryFun(),
		R;
	    [[]] ->
		{ok, R} = RetryFun(),
		R;
	    [R] ->
		R
	end,
    %% ?DEBUG("select ~p", [ets:select(?WUSER_PROFILE, MS)]),
    Select.

filter(L, Key, MatchValue) ->
    %% ?DEBUG("filter with L ~p, Key ~p, MatchValue ~p", [L, Key, MatchValue]),
    case lists:filter(fun({Pair})->
			 ?v(Key, Pair) =:= MatchValue
		      end, ?to_tl(L)) of
	[] -> [];
	[{Match}] -> Match;
	Match -> Match
    end.
	     

user_nav(Session) ->
    case ?session:get(type, Session) of
	?SUPER ->
	    ?right_auth:navbar(super);
	_ ->
	    ?right_auth:navbar(session, Session)
    end.
