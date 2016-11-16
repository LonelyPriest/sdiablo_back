%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright QianZhangGui(C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 16 Jan 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_purchaser).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/1]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, 
	 terminate/2, code_change/3]).

-export([purchaser_good/2, purchaser_good/3,
	 purchaser_good/4, purchaser_good/5]).

-export([purchaser_inventory/3, purchaser_inventory/4, purchaser_inventory/5]).

-export([filter/4, filter/6, rsn_detail/3, export/3, rsn/4]).
-export([match/3, match/4, match/5, match/6]).

-define(SERVER, ?MODULE). 

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
purchaser_good(lookup, Merchant) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant}).

purchaser_good(new, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_good, Merchant, Attrs}); 
purchaser_good(update, Merchant, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_good, Merchant, Attrs});

purchaser_good(lookup, Merchant, GoodId) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant, GoodId});
purchaser_good(delete, Merchant, {GoodId, StyleNumber, Brand}) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_good, Merchant, {GoodId, StyleNumber, Brand}});
purchaser_good(price, Merchant, [{_StyleNumber, _Brand}|_] = Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_good_price, Merchant, Conditions}).

purchaser_good(lookup, Merchant, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_good, Merchant, StyleNumber, Brand});
    
purchaser_good(used, Merchant, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {lookup_used_good, Merchant, StyleNumber, Brand}).
purchaser_good(used, Merchant, Shops, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {lookup_used_good, Merchant, Shops, StyleNumber, Brand}).

purchaser_inventory(new, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_inventory, Merchant, Inventories, Props});
purchaser_inventory(update, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_inventory, Merchant, Inventories, Props});
purchaser_inventory(reject, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {reject_inventory, Merchant, Inventories, Props});
purchaser_inventory(transfer, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {transfer_inventory, Merchant, Inventories, Props});

purchaser_inventory(fix, Merchant, Inventories, Props) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {fix_inventory, Merchant, Inventories, Props});

purchaser_inventory(set_promotion, Merchant, Promotions, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {set_promotion, Merchant, Promotions, Conditions});

purchaser_inventory(update_batch, Merchant, Attrs, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {update_batch, Merchant, Attrs, Conditions});
purchaser_inventory(adjust_price, Merchant, Inventories, Attrs) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {adjust_price, Merchant, Inventories, Attrs});
    
purchaser_inventory(abstract, Merchant, Shop, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {abstract_inventory, Merchant, Shop, Conditions});

purchaser_inventory(check, Merchant, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {check_inventory, Merchant, RSN, Mode});

purchaser_inventory(delete_new, Merchant, RSN, Mode) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {delete_new, Merchant, RSN, Mode});
purchaser_inventory(comment, Merchant, RSN, Comment) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {comment_new, Merchant, RSN, Comment}).



%%
%% 
%%
purchaser_inventory(check_transfer, Merchant, CheckProps) ->    
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {check_inventory_transfer, Merchant, CheckProps});

purchaser_inventory(cancel_transfer, Merchant, RSN) -> 
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {cancel_inventory_transfer, Merchant, RSN});

purchaser_inventory(list, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_inventory, Merchant, Conditions});
purchaser_inventory(list_inventory_info, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_inventory_info, Merchant, Conditions});
purchaser_inventory(list_new_detail, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {list_new_detail, Merchant, Conditions});

%% trace
purchaser_inventory(trace_new, Merchant, Conditions) ->
    purchaser_inventory(list_new_detail, Merchant, Conditions);
purchaser_inventory(trace_transfer, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {trace_transfer, Merchant, Conditions});

%% purchaser_inventory(last_reject, Merchant, Conditions) ->
%%     gen_server:call(?SERVER, {last_reject, Merchant, Conditions});
purchaser_inventory(get_new, Merchant, RSN) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new, Merchant, RSN});
purchaser_inventory(get_inventory_new_rsn, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_inventory_new_rsn, Merchant, Conditions}); 
purchaser_inventory(get_new_amount, Merchant, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_new_amount, Merchant, Conditions}).
    
purchaser_inventory(amount, Merchant, Shop, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_amount, Merchant, Shop, StyleNumber, Brand});
purchaser_inventory(tag_price, Merchant, Shop, StyleNumber, Brand) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {get_tagprice, Merchant, Shop, StyleNumber, Brand}). 

%%
%% match
%%
%% match good
match(style_number, Merchant, PromptNumber) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_style_number, Merchant, PromptNumber}).
match(style_number_with_firm, Merchant, PromptNumber, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_style_number_with_firm,
			   Merchant, PromptNumber, Firm});
match(all_style_number_with_firm, Merchant, StartTime, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_all_style_number_with_firm,
			   Merchant, StartTime, Firm}).


%% match inventory 
match(inventory, all_inventory, Merchant, Shop, Conditions) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {match_all_inventory, Merchant, Shop, Conditions});

match(inventory, QType, Merchant, StyleNumber, Shop) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_inventory, QType, Merchant, StyleNumber, Shop}).

match(inventory, QType, Merchant, StyleNumber, Shop, Firm) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_inventory, QType, Merchant, StyleNumber, Shop, Firm});

match(all_reject_inventory, QType, Merchant, Shop, Firm, StartTime) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {match_all_reject_inventory,
		QType, Merchant, Shop, Firm, StartTime}).

%% =============================================================================
%% filter with pagination
%% =============================================================================
%% new
filter(total_news, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_news, Merchant, Fields});

filter(total_new_rsn_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_new_rsn_groups, Merchant, Fields});

%% reject
%% filter(total_rejects, 'and', Merchant, Fields) ->
%%     gen_server:call(?SERVER, {total_rejects, Merchant, Fields});

%% filter(total_reject_rsn_groups, 'and', Merchant, Fields) -> 
%%     gen_server:call(?SERVER, {total_new_rsn_groups, reject, Merchant, Fields});

%% fix
filter(total_fix, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_fix, Merchant, Fields});

filter(total_fix_rsn_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_fix_rsn_groups, Merchant, Fields});

%% transfer
filter(total_transfer, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_transfer, Merchant, Fields});

filter(total_transfer_rsn_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {total_transfer_rsn_groups, Merchant, Fields});

%% inventory
filter(total_groups, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_groups, Merchant, Fields});

%% good
filter(total_goods, 'and', Merchant, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {total_goods, Merchant, Fields}).

%%
%% filter detail
%%
%% new stock
filter(news, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_news, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(new_rsn_groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_new_rsn_groups,
			   Merchant, CurrentPage, ItemsPerPage, Fields});

%% fix
filter(fix, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_fix, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(fix_rsn_groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_fix_rsn_groups,
			   Merchant, CurrentPage, ItemsPerPage, Fields});
%% transfer
filter(transfer, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(
      Name, {filter_transfer, Merchant, CurrentPage, ItemsPerPage, Fields});

filter(transfer_rsn_groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {filter_transfer_rsn_groups,
                           Merchant, CurrentPage, ItemsPerPage, Fields});

%% inventory
filter(groups, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant),
    %% default use id
    gen_server:call(
      Name, {filter_groups, {use_id, 0}, Merchant, CurrentPage, ItemsPerPage, Fields});

filter({groups, Mode, Sort}, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(
      Name, {filter_groups, {Mode, Sort}, Merchant, CurrentPage, ItemsPerPage, Fields});

%% good
filter(goods, 'and', Merchant, CurrentPage, ItemsPerPage, Fields) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {filter_goods, Merchant, CurrentPage, ItemsPerPage, Fields}).

%% rsn
rsn_detail(new_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_rsn_detail, Merchant, Condition});

rsn_detail(reject_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_rsn_detail, Merchant, Condition});

rsn_detail(fix_rsn, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {fix_rsn_detail, Merchant, Condition});

rsn_detail(transfer_rsn, Merchant, Condition) ->    
    Name = ?wpool:get(?MODULE, Merchant),
    gen_server:call(Name, {transfer_rsn_detail, Merchant, Condition}).

%%
%% export
%%
export(trans, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_export, Merchant, Condition});
export(trans_note, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {new_trans_note_export, Merchant, Condition});
export(stock, Merchant, Condition) ->
    Name = ?wpool:get(?MODULE, Merchant), 
    gen_server:call(Name, {stock_export, Merchant, Condition}).


start_link(Name) ->
    gen_server:start_link({local, Name}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    {ok, #state{}}.

handle_call({new_good, Merchant, Attrs}, _Form, State) ->
    ?DEBUG("new_good with merchant ~p~nattrs~p", [Merchant, Attrs]),
    %% Merchant    = ?v(<<"merchant">>, Attrs), 
    StyleNumber = ?v(<<"style_number">>, Attrs),
    BrandId     = ?v(<<"brand_id">>, Attrs),
    Shop        = ?v(<<"shop">>, Attrs),
    UseZero     = ?v(<<"zero_inventory">>, Attrs, ?NO),
    
    Sql = "select style_number, brand from w_inventory_good"
	" where style_number=" ++ "\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId)
	++ " and merchant=" ++ ?to_s(Merchant) ++ ";",

    Reply = 
	case ?sql_utils:execute(s_read, Sql) of
	    {ok, []} ->
		GetShop = fun() -> ?w_good_sql:realy_shop(Merchant, Shop) end,
		Sql1 = ?w_good_sql:good_new(Merchant, UseZero, GetShop, Attrs),
		case erlang:length(Sql1) =:= 1 of
		    true ->
			[SqlH] = Sql1, ?sql_utils:execute(insert, SqlH);
		    false -> ?sql_utils:execute(transaction, Sql1, StyleNumber)
		end;
	    {ok, _} ->
		{error, ?err(purchaser_good_exist, StyleNumber)};
	    Error ->
		Error
	end,
    {reply, Reply, State};

handle_call({update_good, Merchant, Attrs}, _Form, State) ->
    ?DEBUG("update_good with merchant ~p~nattrs~n~p", [Merchant, Attrs]),
    GoodId         = ?v(<<"good_id">>, Attrs),
    Shop           = ?v(<<"shop">>, Attrs),

    OrgStyleNumber = ?v(<<"o_style_number">>, Attrs),
    OrgBrand       = ?v(<<"o_brand">>, Attrs),

    StyleNumber    = ?v(<<"style_number">>, Attrs),
    Brand          = ?v(<<"brand_id">>, Attrs),
    
    TypeId         = ?v(<<"type_id">>, Attrs), 
    Firm           = ?v(<<"firm_id">>, Attrs), 
    Sex            = ?v(<<"sex">>, Attrs),
    Season         = ?v(<<"season">>, Attrs),
    Year           = ?v(<<"year">>, Attrs),
    
    OrgPrice       = ?v(<<"org_price">>, Attrs),
    TagPrice       = ?v(<<"tag_price">>, Attrs),

    EDiscount      = ?v(<<"ediscount">>, Attrs),
    Discount       = ?v(<<"discount">>, Attrs),
    
    Colors         = ?v(<<"color">>, Attrs),
    SizeGroup      = ?v(<<"s_group">>, Attrs),
    Sizes          = ?v(<<"size">>, Attrs),
    Path           = ?v(<<"path">>, Attrs),
    
    %% Date     = ?utils:current_time(localdate),
    DateTime = ?utils:current_time(localtime),

    UpdateBase =
	%% ?utils:v(type, string, StyleNumber)
	%% ++ ?utils:v(type, integer, Brand)
	?utils:v(type, integer, TypeId)
	++ ?utils:v(firm, integer, Firm)
	++ ?utils:v(sex, integer, Sex)
	++ ?utils:v(year, integer, Year)
	++ ?utils:v(season, integer, Season) 
	++ ?utils:v(path, string, Path),
	%% ++ ?utils:v(change_date, string, DateTime),

    UpdatePrice = ?utils:v(org_price, float, OrgPrice)
	++ ?utils:v(tag_price, float, TagPrice)
	++ ?utils:v(ediscount, integer, EDiscount) 
	++ ?utils:v(discount, integer, Discount),

    UpdateFree = case ?utils:v(color, string, Colors) of
		     [] -> [];
		     _ when Colors =/= <<"0">> -> ?utils:v(free, integer, 1);
		     _ -> [] 
		 end,

    UpdateGood = UpdateBase ++ UpdatePrice
	++ ?utils:v(color, string, Colors)
	++ UpdateFree
	++ ?utils:v(s_group, string, SizeGroup)
	++ ?utils:v(size, string, Sizes)
	++ ?utils:v(change_date, string, DateTime),
    
    RBrand = fun(undefined) -> OrgBrand; (_) -> Brand end,
    RStyleNumber = fun(undefined) -> ?to_s(OrgStyleNumber);
		      (_) -> ?to_s(StyleNumber) end,
		
    C = fun(true, S, B) ->
		"style_number=\'" ++ ?to_s(S) ++ "\'"
		    ++ " and brand=" ++ ?to_s(B)
		    ++ case Shop of
			   undefined -> [];
			   _ -> " and shop="  ++ ?to_s(Shop)
		       end
		    ++ " and merchant=" ++ ?to_s(Merchant) ;
	   (false, S, B) ->
		"style_number=\'" ++ ?to_s(S) ++ "\'"
		    ++ " and brand=" ++ ?to_s(B)
		    ++ " and merchant=" ++ ?to_s(Merchant) 
	end,
    

    RC = fun(S, B) ->
		 "style_number=\'" ++ ?to_s(S) ++ "\'"
		     ++ " and brand=" ++ ?to_s(B)
		     ++ " and rsn like \'"
		     "M-" ++ ?to_s(Merchant) ++ "-S-" ++ ?to_s(Shop) ++ "%\'"
	 end,

    Sql1 = "update w_inventory_good set "
	++ ?utils:to_sqls(proplists, comma, UpdateGood)
	++ " where id=" ++ ?to_s(GoodId) 
	++ " and merchant=" ++ ?to_s(Merchant),
    
    case StyleNumber =:= undefined andalso Brand =:= undefined of
	true -> 
	    case UpdateBase ++ UpdatePrice ++ UpdateFree of
		[] -> 
		    {reply, ?sql_utils:execute(write, Sql1, GoodId), State};
		_  ->
		    UpdateInv = UpdateBase
			++ UpdatePrice ++ UpdateFree
			++ ?utils:v(change_date, string, DateTime),
		    
		    Sql2 = "update w_inventory set "
			++ ?utils:to_sqls(proplists, comma, UpdateInv)
			++ " where " ++ C(true, OrgStyleNumber, OrgBrand),

		    Sql3 =
			%% case UpdateBase ++ UpdatePrice of
			case UpdateBase of
			    [] -> []; 
			    U3  ->
				["update w_inventory_new_detail set "
				 ++ ?utils:to_sqls(proplists, comma, U3)
				 ++ " where "
				 ++ C(true, OrgStyleNumber, OrgBrand)]
				    ++ 
				    case lists:keydelete(<<"sex">>, 1, U3) of
					[] -> [];
					U1 ->
					    ["update w_sale_detail set "
					     ++ ?utils:to_sqls(proplists, comma, U1)
					     ++ " where "
					     ++ C(true, OrgStyleNumber, OrgBrand)]
				    end
			end,
		    
		    {reply,
		     ?sql_utils:execute(
			transaction, [Sql1, Sql2] ++ Sql3, GoodId), State}
	    end;
	false -> 
	    FindFun =
		fun(Color, Size) ->
			"select id, style_number, brand, color, size"
			    " from w_inventory_amount"
			    " where style_number=\'"
			    ++ (RStyleNumber(StyleNumber)) ++ "\'"
			    ++ " and brand=" ++ ?to_s(RBrand(Brand))
			    ++ " and color=" ++ ?to_s(Color)
			    ++ " and size=\'" ++ ?to_s(Size) ++ "\'"
			    ++ case Shop of
				   undefined -> [];
				   _ -> " and shop=" ++ ?to_s(Shop)
			       end
			    ++ " and merchant=" ++ ?to_s(Merchant) 
		end,

	    InsertFun =
		fun(Color, Size, Total) ->
			"insert into w_inventory_amount("
			    "style_number, brand, color, size, shop, merchant"
			    ", total, entry_date"
			    ") values("
			    "\'" ++ (RStyleNumber(StyleNumber)) ++ "\'"
			    ", " ++ ?to_s(RBrand(Brand)) ++ 
			    ", " ++ ?to_s(Color) ++ 
			    ", \'" ++ ?to_s(Size) ++ "\'" ++
			    case Shop of
				undefined -> [];
				_ -> " and shop=" ++ ?to_s(Shop)
			    end ++
			    ", " ++ ?to_s(Merchant) ++
			    ", " ++ ?to_s(Total) ++
			    ", \'" ++ ?to_s(DateTime) ++ "\')"
		end,

	    UpdateFun =
		fun(UId, Total) ->
			"update w_inventory_amount"
			    " set total=total+" ++ ?to_s(Total)
			    ++ " where id=" ++ ?to_s(UId)
		end,
	    
	    FoldrFun =
		fun({R}, Acc) ->
			Color = ?v(<<"color">>, R),
			Size  = ?v(<<"size">>, R),
			Total = ?v(<<"total">>, R),
			case ?sql_utils:execute(
				s_read, FindFun(Color, Size)) of
			    {ok, []} ->
				[InsertFun(Color, Size, Total)|Acc];
			    {ok, F} ->
				UId = ?v(<<"id">>, F),
				[UpdateFun(UId, Total)|Acc]
			end
		end,
	    
	    try
		Update2 =
		    ?utils:v(style_number, string, StyleNumber)
		    ++ ?utils:v(brand, integer, Brand),
		%% ++ ?utils:v(firm, integer, Firm),
		
		%% update w_inventory_good 
		Sql00 = 
		    case ?sql_utils:execute(
			    s_read, "select id, style_number, brand"
			    " from w_inventory_good where "
			    ++ C(false, RStyleNumber(StyleNumber), RBrand(Brand))) of
			{ok, []} ->
			    %% new, update only
			    ["update w_inventory_good set "
			     ++ ?utils:to_sqls(proplists, comma, Update2 ++ UpdateGood)
			     ++ " where id=" ++ ?to_s(GoodId) 
			     ++ " and merchant=" ++ ?to_s(Merchant)];
			{ok, G} ->
			    %% exist, delete the old
			    ["delete from w_inventory_good where id=" ++ ?to_s(GoodId),
			      
			     "update w_inventory_good set "
			     ++ ?utils:to_sqls(proplists, comma, UpdateGood)
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, G))]
		    end,
		?DEBUG("Sql00 ~p", [Sql00]),

		%% update record of new stock 
		Sql10 = 
		    ["update w_inventory_new_detail set "
		     ++ ?utils:to_sqls(
			   proplists,
			   comma,
			   Update2
			   ++ ?utils:v(path, string, Path)
			   ++ ?utils:v(firm, integer, Firm))
		     ++ " where " ++ RC(OrgStyleNumber, OrgBrand),

		     "update w_inventory_new_detail_amount set "
		     ++ ?utils:to_sqls(proplists, comma, Update2)
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand)],
		    
		?DEBUG("Sql10 ~p", [Sql10]),
		
		%% update w_inventory
		UpdateInv = UpdateBase ++?utils:v(change_date, string, DateTime), 

		Sql12 = 
		    case ?sql_utils:execute(
			    s_read,
			    "select id, style_number, brand from w_inventory"
			    " where "
			    ++ C(true, RStyleNumber(StyleNumber), RBrand(Brand))) of
			{ok, []} ->
			    %% new, update only
			    ["update w_inventory set "
			     ++ ?utils:to_sqls(
				   proplists, comma,
				   Update2 ++ UpdateInv ++ UpdatePrice ++ UpdateFree)
			     ++ " where "
			     ++ C(true, OrgStyleNumber, OrgBrand),

			     "update w_inventory_amount set "
			     ++ ?utils:to_sqls(proplists, comma, Update2)
			     ++ " where "
			     ++ C(true, OrgStyleNumber, OrgBrand)];
			{ok, S} ->
			    %% exist, add amount
			    Sqla = 
				["update w_inventory a inner join("
				 "select style_number, brand, amount, sell"
				 " from w_inventory"
				 " where "
				 ++ C(true, OrgStyleNumber, OrgBrand) ++ ") b"
				 %% " on a.style_number=b.style_number"
				 %% " and a.brand=b.brand"
				 %% " and a.shop=b.shop"
				 %% " and a.merchant=b.merchant"
				 " set a.amount=a.amount+b.amount"
				 ", a.sell=a.sell+b.sell"
				 ++ ", " ++ ?utils:to_sqls(proplists, comma, UpdateInv)
				 ++ " where a.id=" ++ ?to_s(?v(<<"id">>, S))],
			    
			    Sqlb = 
				case ?sql_utils:execute(
					read, "select id"
					", style_number, brand, color, size, total"
					" from w_inventory_amount"
					" where " ++ C(true, OrgStyleNumber, OrgBrand))
				of
				    {ok, Rs} -> lists:foldr(FoldrFun, [], Rs)
				end,
			    %% "update w_inventory_amount a inner join("
			    %% "select "
			    %% ++ "\'" ++ RStyleNumber(StyleNumber) ++ "\'"
			    %% " as style_number"
			    %% ++ ", " ++ ?to_s(RBrand(Brand))
			    %% ++ " as brand"
			    %% ++ ", color, size, shop, merchant, total"
			    %% " from w_inventory_amount where "
			    %% ++ C(true, OrgStyleNumber, OrgBrand) ++ ") b"
			    %% " on a.style_number=b.style_number"
			    %% " and a.brand=b.brand"
			    %% " and a.color=b.color"
			    %% " and a.size=b.size"
			    %% " and a.shop=b.shop"
			    %% " and a.merchant=b.merchant"
			    %% " set a.total=a.total+b.total"
			    %% " where a.merchant=" ++ ?to_s(Merchant),
			    Sqla ++ Sqlb ++ 
				[" delete from w_inventory"
				 " where " ++ C(true, OrgStyleNumber, OrgBrand),
				 " delete from w_inventory_amount"
				 " where " ++ C(true, OrgStyleNumber, OrgBrand)]
		    end,
		
		?DEBUG("Sql12 ~p", [Sql12]),

		Sql14 =
		    [ "update w_sale_detail set "
		      ++ ?utils:to_sqls(
			    proplists,
			    comma,
			    Update2
			    ++ ?utils:v(path, string, Path)
			    ++ ?utils:v(firm, integer, Firm))
		      ++ " where "
		      ++ RC(OrgStyleNumber, OrgBrand),

		      "update w_sale_detail_amount set "
		      ++ ?utils:to_sqls(proplists, comma, Update2)
		      ++ " where "
		      ++ RC(OrgStyleNumber, OrgBrand)],
		
		?DEBUG("Sql14 ~p", [Sql14]),

		%% transfer
		Sql15 =
		    ["update w_inventory_transfer_detail set "
		     ++ ?utils:to_sqls(
			   proplists,
			   comma,
			   Update2
			   ++ ?utils:v(path, string, Path)
			   ++ ?utils:v(firm, integer, Firm))
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand),

		     "update w_inventory_transfer_detail_amount set "
		     ++ ?utils:to_sqls(proplists, comma, Update2)
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand)],

		?DEBUG("Sql15 ~p", [Sql15]),

		%% fix
		Sql16 =
		    ["update w_inventory_fix_detail set "
		     ++ ?utils:to_sqls(
			   proplists,
			   comma,
			   Update2
			   ++ ?utils:v(path, string, Path)
			   ++ ?utils:v(firm, integer, Firm))
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand),

		     "update w_inventory_fix_detail_amount set "
		     ++ ?utils:to_sqls(proplists, comma, Update2)
		     ++ " where "
		     ++ RC(OrgStyleNumber, OrgBrand)],

		?DEBUG("Sql16 ~p", [Sql16]),

		AllSql = Sql00 ++ Sql10 ++ Sql12 ++ Sql14 ++ Sql15 ++ Sql16,
		{reply, ?sql_utils:execute(transaction, AllSql, GoodId), State}
	    catch
		_:{badmatch, Error} -> {reply, Error, State}
	    end
    end;
		
handle_call({delete_good, Merchant, {GoodId, StyleNumber, Brand}}, _Form, State) ->
    ?DEBUG("delete_good with merchant ~p, goodId ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, GoodId, StyleNumber, Brand]),
    Sqls = ?w_good_sql:good(delete, Merchant, {GoodId, StyleNumber, Brand}), 
    Reply = ?sql_utils:execute(transaction, Sqls, GoodId),
    {reply, Reply, State};

handle_call({lookup_good, Merchant}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p", [Merchant]),
    Sql = ?w_good_sql:good(detail, Merchant),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


handle_call({lookup_good, Merchant, GoodId}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p, goodId ~p", [Merchant, GoodId]),
    Sql = ?w_good_sql:good(detail, Merchant, [{<<"id">>, ?to_i(GoodId)}]),
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};
    
handle_call({lookup_good, Merchant, StyleNumber, Brand}, _Form, State) ->
    ?DEBUG("lookup_good with merchant ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, StyleNumber, Brand]),
    Sql = ?w_good_sql:good(detail_no_join, Merchant, StyleNumber, Brand),
    Reply =  ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({lookup_used_good, Merchant, StyleNumber, Brand}, _Form, State) ->
    ?DEBUG("lookup_used_good with merchant ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, StyleNumber, Brand]),
    Sql = ?w_good_sql:good(used_detail, Merchant, StyleNumber, Brand),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_good_price, Merchant, Conditions}, _Form, State) ->
    ?DEBUG("get_good_attr with merchant ~p, conditions ~p", [Merchant, Conditions]),
    Sql = ?w_good_sql:good(price, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% good match
%%
handle_call({match_style_number, Merchant, PromptNumber}, _Form, State) ->
    ?DEBUG("match_style_number with merchant ~p, promptNumber ~p",
	   [Merchant, PromptNumber]),
    Sql = ?w_good_sql:good_match(style_number, Merchant, PromptNumber),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_style_number_with_firm, Merchant, PromptNumber, Firm},
	    _Form, State) ->
    ?DEBUG("match_style_number_with_firm with merchant ~p, promptNumber ~p"
	   ", firm ~p", [Merchant, PromptNumber, Firm]),
    Sql = ?w_good_sql:good_match(
	     style_number_with_firm, Merchant, PromptNumber, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_all_style_number_with_firm, Merchant, StartTime, Firm},
	    _Form, State) ->
    ?DEBUG("match_all_style_number_with_firm with merchant ~p, start time ~p"
	   ",firm ~p", [Merchant, StartTime, Firm]),
    Sql = ?w_good_sql:good_match(
	     all_style_number_with_firm, Merchant, StartTime, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% inventory match
handle_call({match_inventory, QType, Merchant, StyleNumber, Shop},
	    _Form, State) ->
    ?DEBUG("match_inventory with qtype ~p, merchant ~p, styleNumber ~p"
	   ", shop ~p", [QType, Merchant, StyleNumber, Shop]),
    RealyShop = case QType of
		    1 -> Shop;
		    _ -> ?w_good_sql:realy_shop(Merchant, Shop)
		end,
    
    Sql = ?w_good_sql:inventory_match(Merchant, StyleNumber, RealyShop),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_inventory,
	     QType, Merchant, StyleNumber, Shop, Firm}, _Form, State) ->
    ?DEBUG("match_inventory with qtype ~p, merchant ~p, styleNumber ~p"
	   ",shop ~p, firm ~p", [QType, Merchant, StyleNumber, Shop, Firm]),
    RealyShop = case QType of
		    1 -> ?w_good_sql:realy_shop(true, Merchant, Shop);
		    _ -> ?w_good_sql:realy_shop(Merchant, Shop)
		end,
    %% RealyShop = realy_shop(Merchant, Shop),
    Sql = ?w_good_sql:inventory_match(Merchant, StyleNumber, RealyShop, Firm),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({match_all_reject_inventory,
	     QType, Merchant, Shop, Firm, StartTime}, _Form, State) ->
    ?DEBUG("match_all_reject_inventory with qtype ~p, merchant ~p"
	   ", shop ~p, firm ~p, StartTime ~p",
	   [QType, Merchant, Shop, Firm, StartTime]),
    RealyShop = case QType of
		    1 -> ?w_good_sql:realy_shop(true, Merchant, Shop);
		    _ -> ?w_good_sql:realy_shop(Merchant, Shop)
		end,
    Sql = ?w_good_sql:inventory_match(
	     all_reject, Merchant, RealyShop, Firm, StartTime),
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({match_all_inventory, Merchant, Shop, Conditions}, _From, State) ->
    ?DEBUG("match_all_inventory  with merchant ~p, shop ~p, conditions ~p",
	   [Merchant, Shop, Conditions]),
    RealyShop = ?w_good_sql:realy_shop(Merchant, Shop),
    Sql = ?w_good_sql:inventory_match(all_inventory, Merchant, RealyShop, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% new
handle_call({new_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("new_inventory: merchant ~p~n, Inventories ~p, props ~p",
	   [Merchant, Inventories, Props]), 
    DateTime = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    
    Shop       = ?v(<<"shop">>, Props),
    Firm       = ?v(<<"firm">>, Props, -1),
    Employee   = ?v(<<"employee">>, Props),
    
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    Comment    = ?v(<<"comment">>, Props, ""),
    ShouldPay  = ?v(<<"should_pay">>, Props, 0),
    HasPay     = ?v(<<"has_pay">>, Props, 0),

    EPayType   = ?v(<<"e_pay_type">>, Props, -1),
    EPay       = ?v(<<"e_pay">>, Props, 0),
    
    Total      = ?v(<<"total">>, Props, 0),

    FF = fun (V) when V =:= <<>> -> 0;
	     (Any)  -> ?to_f(Any)
	 end,
		 
    Sql0 = "select a.id, a.merchant, a.balance"
	", b.balance as lbalance, b.should_pay, b.has_pay, b.verificate, b.e_pay"
	" from suppliers a"
	" left join "
	"(select id, merchant, firm, balance, should_pay"
	", has_pay, verificate, e_pay from w_inventory_new"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and firm=" ++ ?to_s(Firm)
	++ " and state in (0,1)"
	++ " order by id desc limit 1) b on a.merchant=b.merchant and a.id=b.firm"
	" where a.id=" ++ ?to_s(Firm)
	++ " and a.merchant=" ++ ?to_s(Merchant)
	++ " and a.deleted=" ++ ?to_s(?NO) ++ ";",

    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    %% ?INFO("account ~p", [Account]),
	    LastBalance = FF(?v(<<"lbalance">>, Account, 0))
		+ FF(?v(<<"should_pay">>, Account, 0))
		+ FF(?v(<<"e_pay">>, Account, 0))
		- FF(?v(<<"has_pay">>, Account, 0))
		- FF(?v(<<"verificate">>, Account, 0)), 
	    CurrentBalance = ?v(<<"balance">>, Account, 0),
	    ?DEBUG("current balance ~p, last balance ~p",
		   [?to_f(CurrentBalance), ?to_f(LastBalance)]),
	    case ?to_f(LastBalance) =:= ?to_f(CurrentBalance)
		orelse (CurrentBalance /= 0 andalso ?v(<<"lbalance">>, Account) =:= <<>>) of
		true ->
		    RSn = rsn(new,
			      Merchant,
			      Shop,
			      ?inventory_sn:sn(w_inventory_new_sn, Merchant)),

		    Sql1 = sql(wnew, RSn, Merchant, Shop, Firm, DateTime, Inventories), 

		    Sql2 = "insert into w_inventory_new(rsn"
			", employ, firm, shop, merchant, balance"
			", should_pay, has_pay, cash, card, wire"
			", verificate, total, comment"
			", e_pay_type, e_pay, type, entry_date) values("
			++ "\"" ++ ?to_s(RSn) ++ "\","
			++ "\"" ++ ?to_s(Employee) ++ "\","
			++ ?to_s(Firm) ++ ","
			++ ?to_s(Shop) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(CurrentBalance) ++ "," 
			++ ?to_s(ShouldPay) ++ ","
			++ ?to_s(HasPay) ++ ","
			++ ?to_s(Cash) ++ ","
			++ ?to_s(Card) ++ ","
			++ ?to_s(Wire) ++ ","
			++ ?to_s(VerifyPay) ++ ","
			++ ?to_s(Total) ++ ","
			++ "\"" ++ ?to_s(Comment) ++ "\","
			++ ?to_s(EPayType) ++ ","
			++ ?to_s(EPay) ++ ","
			++ ?to_s(?NEW_INVENTORY) ++ ","
			++ "\"" ++ ?to_s(DateTime) ++ "\")",

		    Metric = ShouldPay + EPay - (Cash + Card + Wire + VerifyPay),
		    case Metric == 0 orelse Firm =:= -1 of
			true ->
			    AllSql = [Sql2|Sql1],
			    Reply = ?sql_utils:execute(transaction, AllSql, RSn),
			    {reply, Reply, State};
			false -> 
			    Sql3 = ["update suppliers set balance=balance+" ++ ?to_s(Metric)
				    ++ ", change_date=" ++ "\"" ++ ?to_s(DateTime) ++ "\""
				    ++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

				    "insert into firm_balance_history("
				    "rsn, firm, balance, metric, action"
				    ", shop, merchant, entry_date) values("
				    ++ "\'" ++ ?to_s(RSn) ++ "\',"
				    ++ ?to_s(Firm) ++ ","
				    ++ ?to_s(CurrentBalance) ++ ","
				    ++ ?to_s(Metric) ++ ","
				    ++ ?to_s(?NEW_INVENTORY) ++ ","
				    ++ ?to_s(Shop) ++ ","
				    ++ ?to_s(Merchant) ++ ","
				    ++ "\"" ++ ?to_s(DateTime) ++ "\")" 
				   ],

			    AllSql = [Sql2|Sql1] ++ Sql3, 
			    Reply = ?sql_utils:execute(transaction, AllSql, RSn),
			    ?w_user_profile:update(firm, Merchant),
			    {reply, Reply, State}
		    end;
		false ->
		    {reply, {invalid_balance, {Firm, CurrentBalance, LastBalance}}, State}
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({update_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("update_inventory: merchant ~p~n, inventories ~p, props ~p",
	   [Merchant, Inventories, Props]), 
    CurTime    = ?utils:current_time(format_localtime),
    
    Id         = ?v(<<"id">>, Props),
    Mode       = ?v(<<"mode">>, Props),
    RSN        = ?v(<<"rsn">>, Props),
    Shop       = ?v(<<"shop">>, Props),
    Datetime   = ?v(<<"datetime">>, Props),
    Firm       = ?v(<<"firm">>, Props),
    Employee   = ?v(<<"employee">>, Props),

    Balance    = ?v(<<"balance">>, Props),
    Cash       = ?v(<<"cash">>, Props, 0),
    Card       = ?v(<<"card">>, Props, 0),
    Wire       = ?v(<<"wire">>, Props, 0),
    VerifyPay  = ?v(<<"verificate">>, Props, 0),
    EPay       = ?v(<<"e_pay">>, Props, 0),
    EPayType   = ?v(<<"e_pay_type">>, Props),

    Comment    = ?v(<<"comment">>, Props, []), 
    ShouldPay  = ?v(<<"should_pay">>, Props),
    HasPay     = ?v(<<"has_pay">>, Props, 0),
    
    OldFirm      = ?v(<<"old_firm">>, Props),
    OldBalance   = ?v(<<"old_balance">>, Props), 
    OldVerifyPay = ?v(<<"old_verify_pay">>, Props, 0),
    OldShouldPay = ?v(<<"old_should_pay">>, Props),
    OldHasPay    = ?v(<<"old_has_pay">>, Props, 0), 
    OldDatatime  = ?v(<<"old_datetime">>, Props),
    OldEPay      = ?v(<<"old_epay">>, Props, 0),

    Total      = ?v(<<"total">>, Props),
    
    RealyShop = ?w_good_sql:realy_shop(Merchant, Shop),
    
    Sql1 = case Inventories of
	       [] ->
		   ?w_good_sql:inventory(
		      update, Mode, RSN, Merchant, RealyShop,
		      Firm, OldFirm, Datetime, OldDatatime);
	       _ ->
		   ?w_good_sql:inventory(
		      update, Mode, RSN, Merchant, RealyShop, Firm,
		      Datetime, OldDatatime, CurTime, Inventories)
	   end,

    IsSame = fun(_, New, Old) when New == Old -> undefined;
		(number, New, _Old) -> New; 
		(datetime, New, _Old) ->
		     ?utils:correct_datetime(datetime, New)
	     end,
    
    Updates = ?utils:v(employ, string, Employee)
	++ ?utils:v(firm, integer, IsSame(number, Firm, OldFirm)) 
	++ ?utils:v(shop, integer, Shop)
	++ ?utils:v(should_pay, float, IsSame(number, ShouldPay, OldShouldPay))
	++ ?utils:v(has_pay, float, IsSame(number, HasPay, OldHasPay))
	++ ?utils:v(cash, float, Cash)
	++ ?utils:v(card, float, Card)
	++ ?utils:v(wire, float, Wire)
	++ ?utils:v(verificate, float, VerifyPay)
	++ ?utils:v(e_pay, float, IsSame(number, EPay, OldEPay))
	++ ?utils:v(e_pay_type, integer, EPayType)
	++ ?utils:v(total, integer, Total)
	++ ?utils:v(comment, string, Comment)
	++ ?utils:v(entry_date, string, IsSame(datetime, Datetime, OldDatatime)), 
		     
    case Firm =:= OldFirm of
	true ->
	    Sql2 = "update w_inventory_new set "
		++ ?utils:to_sqls(
		      proplists, comma,
		      ?utils:v(balance, float, IsSame(number, Balance, OldBalance)) ++ Updates)
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'",

	    case (ShouldPay + EPay - HasPay - VerifyPay)
		- (OldShouldPay + OldEPay - OldHasPay - OldVerifyPay) of
		0 ->
		    AllSql = Sql1 ++ [Sql2],
		    Reply = ?sql_utils:execute(transaction, AllSql, RSN), 
		    {reply, Reply, State};
		Metric ->
		    {ok, FirmProfile} = ?w_user_profile:get(firm, Merchant, Firm),
		    CurBalance = ?v(<<"balance">>, FirmProfile, 0),
		    
		    AllSql = Sql1 ++ [Sql2]
			++
			case Firm =/= ?INVALID_OR_EMPTY of
			    true ->
				["update suppliers set balance=balance+"
				 ++ ?to_s(Metric) 
				 ++ ", change_date=" ++ "\"" ++ CurTime ++ "\""
				 " where id=" ++ ?to_s(Firm)
				 ++ " and merchant=" ++ ?to_s(Merchant),

				 "update w_inventory_new set balance=balance+"
				 ++ ?to_s(Metric)
				 ++ " where"
				 %% " and shop=" ++ ?to_s(Shop)
				 ++ " merchant=" ++ ?to_s(Merchant)
				 ++ " and firm=" ++ ?to_s(Firm)
				 ++ " and id>" ++ ?to_s(Id),

				 "insert into firm_balance_history("
				 "rsn, firm, balance, metric, action"
				 ", shop, merchant, entry_date) values("
				 ++ "\'" ++ ?to_s(RSN) ++ "\',"
				 ++ ?to_s(Firm) ++ ","
				 ++ ?to_s(CurBalance) ++ ","
				 ++ ?to_s(Metric) ++ ","
				 ++ ?to_s(?UPDATE_INVENTORY) ++ "," 
				 ++ ?to_s(Shop) ++ ","
				 ++ ?to_s(Merchant) ++ ","
				 ++ "\"" ++ ?to_s(Datetime) ++ "\")"
				];
			    false -> []
			end,
		    
		    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
		    ?w_user_profile:update(firm, Merchant),
		    {reply, Reply, State}
	    end;
	false ->
	    NewBalance = 
		case Firm =/= ?INVALID_OR_EMPTY of
		    true ->
			Sql0 = "select id, rsn, firm, shop, merchant, balance"
			    ", verificate, should_pay, has_pay, e_pay"
			    " from w_inventory_new"
			    " where"
			    ++ " merchant=" ++ ?to_s(Merchant)
			%% " and shop=" ++ ?to_s(Shop) 
			    ++ " and firm=" ++ ?to_s(Firm)
			    ++ " and id<" ++ ?to_s(Id)
			    ++ " order by id desc limit 1", 
			case ?sql_utils:execute(s_read, Sql0) of
			    {ok, []}  ->
				Sql00 = "select id, rsn, firm, shop, merchant, balance"
				    ", verificate, should_pay, has_pay, e_pay"
				    " from w_inventory_new"
				    " where"
				    ++ " merchant=" ++ ?to_s(Merchant)
				%% " and shop=" ++ ?to_s(Shop) 
				    ++ " and firm=" ++ ?to_s(Firm)
				    ++ " and id>" ++ ?to_s(Id)
				    ++ " order by id limit 1",
				case ?sql_utils:execute(s_read, Sql00) of
				    {ok, []} -> Balance;
				    {ok, R0} -> ?v(<<"balance">>, R0)
				end; 
			    {ok, R}   ->
				?v(<<"balance">>, R)
				    + ?v(<<"should_pay">>, R, 0)
				    + ?v(<<"e_pay">>, R, 0)
				    - ?v(<<"has_pay">>, R, 0)
				    - ?v(<<"verificate">>, R, 0)
			end;
		    false -> 0
		end,
	    
	    
	    Sql2 = "update w_inventory_new set "
		++ ?utils:to_sqls(
		      proplists, comma, ?utils:v(balance, float, NewBalance) ++ Updates)
		++ " where rsn=" ++ "\'" ++ ?to_s(RSN) ++ "\'"
		++ " and id=" ++ ?to_s(Id),

	    NewCurBalance =
		case ?w_user_profile:get(firm, Merchant, Firm) of
		    {ok, []} -> 0;
		    {ok, NewFirmProfile} -> ?v(<<"balance">>, NewFirmProfile, 0)
		end,
	    OldCurBalance =
		case ?w_user_profile:get(firm, Merchant, OldFirm) of
		    {ok, []} -> 0;
		    {ok, OldFirmProfile} ->
			?v(<<"balance">>, OldFirmProfile, 0)
		end,
	    
	    BackBalanceOfOldFirm = OldShouldPay + EPay - OldVerifyPay - OldHasPay,
	    BalanceOfNewFirm = ShouldPay + EPay - HasPay - VerifyPay,
		
	    AllSql = Sql1 ++ [Sql2] ++
		case Firm =/= ?INVALID_OR_EMPTY of
		    true ->
			["update suppliers set balance=balance+"
			 ++ ?to_s(BalanceOfNewFirm)
			 ++ " where id="++ ?to_s(Firm)
			 ++ " and merchant=" ++ ?to_s(Merchant),
		 
			 "insert into firm_balance_history("
			 "rsn, firm, balance, metric, action, shop, merchant, entry_date) values("
			 ++ "\'" ++ ?to_s(RSN) ++ "\',"
			 ++ ?to_s(Firm) ++ ","
			 ++ ?to_s(NewCurBalance) ++ ","
			 ++ ?to_s(BalanceOfNewFirm) ++ ","
			 ++ ?to_s(?UPDATE_INVENTORY) ++ "," 
			 ++ ?to_s(Shop) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(Datetime) ++ "\")",
		 
			 "update w_inventory_new set balance=balance+"
			 ++ ?to_s(BalanceOfNewFirm)
			 ++ " where"
			 ++ " merchant=" ++ ?to_s(Merchant)
			 %% " and shop=" ++ ?to_s(Shop) 
			 ++ " and firm=" ++ ?to_s(Firm)
			 ++ " and id>" ++ ?to_s(Id)];
		    false -> []
		end
		++ 
		case OldFirm =/= ?INVALID_OR_EMPTY of
		    true -> 
			["update suppliers set balance=balance-"
			 ++ ?to_s(BackBalanceOfOldFirm)
			 ++ " where id=" ++ ?to_s(OldFirm)
			 ++ " and merchant=" ++ ?to_s(Merchant),

			 "insert into firm_balance_history("
			 "rsn, firm, balance, metric, action, shop, merchant, entry_date) values("
			 ++ "\'" ++ ?to_s(RSN) ++ "\',"
			 ++ ?to_s(OldFirm) ++ ","
			 ++ ?to_s(OldCurBalance) ++ ","
			 ++ ?to_s(-BackBalanceOfOldFirm) ++ ","
			 ++ ?to_s(?UPDATE_INVENTORY) ++ "," 
			 ++ ?to_s(Shop) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(Datetime) ++ "\")",

			 "update w_inventory_new set balance=balance-"
			 ++ ?to_s(BackBalanceOfOldFirm)
			 ++ " where"
			 ++ " merchant=" ++ ?to_s(Merchant)
			 %% ++ " and shop=" ++ ?to_s(Shop) 
			 ++ " and firm=" ++ ?to_s(OldFirm)
			 ++ " and id>" ++ ?to_s(Id) 
			];
		    false -> []
		end,
	    
	    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
	    ?w_user_profile:update(firm, Merchant),
	    {reply, Reply, State}
    end; 

handle_call({check_inventory, Merchant, RSN, Mode}, _From, State) ->
    ?DEBUG("check_inventory with merchant ~p, RSN ~p, Mode ~p",
	   [Merchant, RSN, Mode]),
    Sql0 = "select id, rsn, state from w_inventory_new"
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant),

    case ?sql_utils:execute(s_read, Sql0) of
	{ok, []} ->
	    {reply, {error, ?err(failed_to_get_stock_new, RSN)}};
	{ok, New} ->
	    StockState = ?v(<<"state">>, New),
	    case StockState == ?DISCARD
		orelse StockState == ?FIRM_BILL of
		true -> {reply, {error, ?err(error_state_of_check, RSN)}, State};
		false -> 
		    Sql1 = "select style_number, brand, org_price from w_inventory_new_detail"
			" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
			++ " and merchant=" ++ ?to_s(Merchant)
			++ " and org_price=0",
		    case ?sql_utils:execute(read, Sql1) of
			{ok, []} -> 
			    Sql = "update w_inventory_new set state=" ++ ?to_s(Mode)
				++ ", check_date=\'" ++ ?utils:current_time(localtime) ++ "\'"
				++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
				++ " and merchant=" ++ ?to_s(Merchant),

			    Reply = ?sql_utils:execute(write, Sql, RSN),
			    {reply, Reply, State};
			{ok, R} ->
			    {reply, {error, {zero_org_price, R}}, State}
		    end
	    end;
	{error, Error} ->
	    {reply, Error, State}
    end;

handle_call({delete_new, Merchant, RSN, Mode}, _From, State) ->
    ?DEBUG("delete_inventory_new with merchant ~p, RSN ~p, Mode ~p",
	   [Merchant, RSN, Mode]),
    Sql1 = ?w_good_sql:inventory(
	      new_detail,
	      new,
	      Merchant,
	      [{<<"rsn">>, ?to_b(RSN)}],
	      fun()-> "" end),

    case ?sql_utils:execute(s_read, Sql1) of
	{ok, []} ->
	    {reply, {error, ?err(failed_to_get_stock_new, RSN)}};
	{ok, New} ->
	    NId = ?v(<<"id">>, New),
	    StockState = ?v(<<"state">>, New),
	    Firm = ?v(<<"firm_id">>, New),
	    Shop = ?v(<<"shop_id">>, New),
	    Total = ?v(<<"total">>, New),
	    SPay = ?v(<<"should_pay">>, New),
	    HPay = ?v(<<"has_pay">>, New),
	    VPay = ?v(<<"verificate">>, New),
	    EPay = ?v(<<"e_pay">>, New), 

	    DeleteNewSqls = ["delete from w_inventory_new_detail_amount"
			     " where rsn=\'" ++ ?to_s(RSN) ++ "\'",

			     "delete from w_inventory_new_detail"
			     " where rsn=\'" ++ ?to_s(RSN) ++ "\'",

			     "delete from w_inventory_new"
			     " where rsn=\'" ++ ?to_s(RSN) ++ "\'"],
	    
	    case {Mode, StockState} of
		{?ABANDON, ?DISCARD} ->
		    {reply, {error, ?err(stock_been_discard, RSN)}};
		{?DELETE, ?DISCARD} ->
		    Reply = ?sql_utils:execute(transaction, DeleteNewSqls, RSN),
		    {reply, Reply, State};
		{_, ?CHECKING} ->
		    Sql11 =
			[
			 "update w_inventory a inner join "
			 "(select style_number, brand, amount"
			 " from w_inventory_new_detail"
			 " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
			 ") b"
			 " on a.style_number=b.style_number and a.brand=b.brand"
			 " set a.amount=a.amount-b.amount"
			 " where a.merchant=" ++ ?to_s(Merchant)
			 ++ " and shop=" ++ ?to_s(Shop),

			 "update w_inventory_amount a inner join "
			 "(select style_number, brand, color, size, total"
			 " from w_inventory_new_detail_amount"
			 " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
			 ") b"
			 " on a.style_number=b.style_number and a.brand=b.brand"
			 " and a.color=b.color and a.size=b.size"
			 " set a.total=a.total-b.total"
			 " where a.merchant=" ++ ?to_s(Merchant)
			 ++ " and shop=" ++ ?to_s(Shop)
			],

		    BackBalance = SPay + EPay - HPay - VPay,
		    Sql21 = 
			case BackBalance == 0 orelse Firm == ?INVALID_OR_EMPTY of
			    true -> [];
			    false-> 
				CurBalance =
				    case ?w_user_profile:get(firm, Merchant, Firm) of
					{ok, []} -> 0;
					{ok, FirmProfile} ->
					    ?v(<<"balance">>, FirmProfile, 0)
				    end,
				Datetime = ?utils:current_time(format_localtime),
				["update suppliers set "
				 "balance=balance-" ++ ?to_s(BackBalance)
				 ++ " where merchant=" ++ ?to_s(Merchant)
				 ++ " and id=" ++ ?to_s(Firm),

				 "update w_inventory_new set "
				 "balance=balance-" ++ ?to_s(BackBalance)
				 ++ " where merchant=" ++ ?to_s(Merchant)
				 %% ++ " and shop=" ++ ?to_s(Shop) 
				 ++ " and firm=" ++ ?to_s(Firm)
				 ++ " and id>" ++ ?to_s(NId),

				 "insert into firm_balance_history("
				 "rsn, firm, balance, metric, action"
				 ", shop, merchant, entry_date) values("
				 ++ "\'" ++ ?to_s(RSN) ++ "\',"
				 ++ ?to_s(Firm) ++ ","
				 ++ ?to_s(CurBalance) ++ ","
				 ++ ?to_s(-BackBalance) ++ ","
				 ++ ?to_s(?DELETE_INVENTORY) ++ "," 
				 ++ ?to_s(Shop) ++ ","
				 ++ ?to_s(Merchant) ++ ","
				 ++ "\"" ++ ?to_s(Datetime) ++ "\")"]
			end,

		    Reply = 
			case Mode of
			    ?DELETE ->
				Sqls = Sql11 ++ Sql21 ++ DeleteNewSqls,
				?sql_utils:execute(transaction, Sqls, RSN);
			    ?ABANDON ->
				Sqls = case Total of
					0 -> [];
					_ -> Sql11 ++ Sql21
				    end ++
				    ["update w_inventory_new set state=" ++ ?to_s(?DISCARD)
				     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"],
				
				?sql_utils:execute(transaction, Sqls, RSN)
			end,
		    
		    case BackBalance == 0 of
			true -> ok;
			false -> ?w_user_profile:update(firm, Merchant)
		    end,
		    {reply, Reply, State}
	    end;
	{error, Error} ->
	    {reply, {error, Error}, State}
    end;

handle_call({comment_new, Merchant, RSN, Comment}, _From, State) ->
    Sql = "update w_inventory_new set comment=\'" ++ ?to_s(Comment) ++ "\'"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(write, Sql, RSN),
    {reply, Reply, State};

%% reject
handle_call({reject_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("reject_inventory with merchant ~p~n~p, props ~p",
	   [Merchant, Inventories, Props]),

    Now         = ?utils:current_time(format_localtime),
    Shop        = ?v(<<"shop">>, Props),
    Firm        = ?v(<<"firm">>, Props),
    %% DateTime    = ?v(<<"datetime">>, Props, Now),
    DateTime = ?utils:correct_datetime(datetime, ?v(<<"datetime">>, Props)),
    Cash        = ?v(<<"cash">>, Props, 0),
    Card        = ?v(<<"card">>, Props, 0),
    Wire        = ?v(<<"wire">>, Props, 0),
    VerifyPay   = ?v(<<"verificate">>, Props, 0),
    Employe     = ?v(<<"employee">>, Props), 
    Balance     = ?v(<<"balance">>, Props),
    ShouldPay   = ?v(<<"should_pay">>, Props, 0),
    HasPay      = ?v(<<"has_pay">>, Props, 0), 
    EPayType    = ?v(<<"e_pay_type">>, Props, -1),
    EPay        = ?v(<<"e_pay">>, Props, 0), 
    
    RejectTotal = ?v(<<"total">>, Props),
    Comment     = ?v(<<"comment">>, Props, ""), 
    
    Sql0 = "select id, merchant, balance from suppliers"
	" where id=" ++ ?to_s(Firm)
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and deleted=" ++ ?to_s(?NO) ++ ";",
    case ?sql_utils:execute(s_read, Sql0) of 
	{ok, Account} ->
	    RSN = rsn(reject, Merchant, Shop, ?inventory_sn:sn(w_inventory_reject_sn, Merchant)),

	    Sql1 = case RejectTotal of
		       0 -> [];
		       _ -> sql(wreject, RSN, Merchant, Shop, Firm, DateTime, Inventories)
		   end, 
	    
	    RealBalance = ?v(<<"balance">>, Account),
	    Sql2 = ["insert into w_inventory_new(rsn"
		    ", employ, firm, shop, merchant, balance"
		    ", should_pay, has_pay, cash, card, wire"
		    ", verificate, total, comment, e_pay_type, e_pay"
		    ", type, entry_date) values(" 
		    ++ "\"" ++ ?to_s(RSN) ++ "\","
		    ++ "\"" ++ ?to_s(Employe) ++ "\","
		    ++ ?to_s(Firm) ++ ","
		    ++ ?to_s(Shop) ++ ","
		    ++ ?to_s(Merchant) ++ ","
		    ++ case ?to_f(RealBalance) == ?to_f(Balance) of
			   true -> ?to_s(Balance) ++ ",";
			   false -> ?to_s(RealBalance) ++ ","
		       end
		    ++ ?to_s(ShouldPay) ++ ","
		    ++ ?to_s(HasPay) ++ ","
		    ++ ?to_s(Cash) ++ ","
		    ++ ?to_s(Card) ++ ","
		    ++ ?to_s(Wire) ++ ","
		    ++ ?to_s(VerifyPay) ++ ","
		    ++ ?to_s(-RejectTotal) ++ ","
		    ++ "\"" ++ ?to_s(Comment) ++ "\","
		    ++ ?to_s(EPayType) ++ ","
		    ++ ?to_s(-EPay) ++ ","
		    ++ ?to_s(?REJECT_INVENTORY) ++ ","
		    ++ "\"" ++ ?to_s(DateTime) ++ "\")"],
	    
	    Sql3 = 
		["update suppliers set balance=balance+"
		 ++ ?to_s(ShouldPay-EPay)
		 ++ ", change_date=" ++ "\"" ++ Now ++ "\""
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, Account)),

		 "insert into firm_balance_history("
		 "rsn, firm, balance, metric, action"
		 ", shop, merchant, entry_date) values("
		 ++ "\'" ++ ?to_s(RSN) ++ "\',"
		 ++ ?to_s(Firm) ++ ","
		 ++ ?to_s(RealBalance) ++ ","
		 ++ ?to_s(ShouldPay-EPay) ++ ","
		 ++ ?to_s(?REJECT_INVENTORY) ++ "," 
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(DateTime) ++ "\")"
		],
	    
	    AllSql = Sql1 ++ Sql2 ++ Sql3,
	    %% ?DEBUG("AllSql ~p", [AllSql]),
	    case ?sql_utils:execute(transaction, AllSql, RSN) of
		{ok, _} = OK ->
		    case ShouldPay - EPay == 0 of
			true -> ok;
			false -> ?w_user_profile:update(firm, Merchant)
		    end,
		    {reply, OK, State};
		{error, _} = Error-> 
		    {reply, Error, State} 
	    end;
	Error ->
	    {reply, Error, State}
    end;

%% fix
handle_call({fix_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("fix_inventory with merchant ~p~ninventory ~p~nprops ~p",
	   [Merchant, Inventories, Props]), 
    Now             = ?utils:current_time(localtime), 
    Shop            = ?v(<<"shop">>, Props),
    DateTime        = ?v(<<"datetime">>, Props, Now),
    Employe         = ?v(<<"employee">>, Props), 
    TotalExist      = ?v(<<"total_exist">>, Props),
    TotalFixed      = ?v(<<"total_fixed">>, Props),
    TotalMetric     = ?v(<<"total_metric">>, Props),
    TotalCost       = ?v(<<"total_cost">>, Props),
    
    RSN = rsn(fix, Merchant, Shop, ?inventory_sn:sn(w_inventory_fix_sn, Merchant)),

    RealyShop = ?w_good_sql:realy_shop(Merchant, Shop),
    Sql1 = sql(wfix, RSN, DateTime, Merchant, RealyShop, Inventories),
    
    Sql2 = "insert into w_inventory_fix(rsn"
	", shop, employ, exist, fixed, metric, cost, merchant, entry_date)"
	" values("
	++ "\"" ++ ?to_s(RSN) ++ "\","
	++ ?to_s(Shop) ++ ","
	++ "\"" ++ ?to_s(Employe) ++ "\","
	++ ?to_s(TotalExist) ++ ","
	++ ?to_s(TotalFixed) ++ ","
	++ ?to_s(TotalMetric) ++ ","
	++ ?to_s(TotalCost) ++ ","
	++ ?to_s(Merchant) ++ "," 
	++ "\"" ++ ?to_s(DateTime) ++ "\");", 

    AllSql = Sql1 ++ [Sql2],
    Reply = ?sql_utils:execute(transaction, AllSql, RSN),
    {reply, Reply, State}; 


handle_call({transfer_inventory, Merchant, Inventories, Props}, _From, State) ->
    ?DEBUG("transfer_inventory with merchant ~p~n~p, props ~p",
           [Merchant, Inventories, Props]),
    Now         = ?utils:current_time(localtime),
    Shop        = ?v(<<"shop">>, Props),
    ToShop      = ?v(<<"tshop">>, Props),
    DateTime    = ?v(<<"datetime">>, Props, Now),
    Employe     = ?v(<<"employee">>, Props),
    Total       = ?v(<<"total">>, Props),
    Cost        = ?v(<<"cost">>, Props),
    Comment     = ?v(<<"comment">>, Props, []),
    TRSN        = rsn(transfer_from, Merchant, Shop,
		      ?inventory_sn:sn(w_inventory_transfer_sn_from, Merchant)),
    %% ToRSN = rsn(transfer_to, Merchant, ToShop,
    %%        ?inventory_sn:sn(w_inventory_transfer_sn_to, Merchant)),

    Sql1 = ["insert into w_inventory_transfer(rsn"
            ", fshop, tshop, employ, total, cost"
            ", comment, merchant, state, entry_date) values("
            ++ "\"" ++ ?to_s(TRSN) ++ "\","
            ++ ?to_s(Shop) ++ ","
            ++ ?to_s(ToShop) ++ ","
            ++ "\"" ++ ?to_s(Employe) ++ "\","
            ++ ?to_s(Total) ++ ","
	    ++ ?to_s(Cost) ++ ","
            ++ "\"" ++ ?to_s(Comment) ++ "\","
            ++ ?to_s(Merchant) ++ ","
            ++ ?to_s(0) ++ ","

	    ++ "\"" ++ ?to_s(DateTime) ++ "\")"],
    Sql2 = sql(transfer_from, TRSN, Merchant, Shop, ToShop, DateTime, Inventories),
    ?DEBUG("Sql2 ~p", [Sql2]),
    %% Sql3 = sql(transfer_to,
    %%         ToRSN, Merchant, ToShop, Firm, DateTime, Inventories),
    %% ?DEBUG("Sql3 ~p", [Sql3]),

    AllSql = Sql1 ++ Sql2,    %% ?DEBUG("AllSql ~p", [AllSql]),
    Reply = ?sql_utils:execute(transaction, AllSql, TRSN),
    {reply, Reply, State};

handle_call({check_inventory_transfer, Merchant, CheckProps}, _From, State) -> 
    ?DEBUG("check_inventory_transfer: checkprops ~p", [CheckProps]),
    %% Now = ?utils:current_time(format_localtime),
    RSN = ?v(<<"rsn">>, CheckProps),
    Sql = "select rsn, fshop, tshop, state from w_inventory_transfer"
        " where rsn=\"" ++ ?to_s(RSN) ++ "\"",
    Reply =
        case ?sql_utils:execute(s_read, Sql) of
            {ok, []} -> 
                {error, ?err(stock_sn_not_exist, RSN)};
	    {ok, R} ->
                case ?v(<<"state">>, R) of
                    ?IN_STOCK ->
                        {error, ?err(stock_been_checked, RSN)};
                    ?IN_BACK ->
                        {error, ?err(stock_been_canceled, RSN)};
                    ?IN_ROAD ->
			FShop = ?v(<<"fshop">>, R),
			TShop = ?v(<<"tshop">>, R), 
                        Sqls = ?w_transfer_sql:check_transfer(
				  Merchant, FShop, TShop, CheckProps),
                        ?sql_utils:execute(transaction, Sqls, RSN)
                end
        end,
    {reply, Reply, State};

handle_call({cancel_inventory_transfer, Merchant, RSN}, _From, State) ->
    ?DEBUG("cancel_inventory_transfer: rsn ~p", [RSN]),
    Sql = "select rsn, fshop, tshop, state from w_inventory_transfer"
        " where rsn=\"" ++ ?to_s(RSN) ++ "\"",
    Reply =
        case ?sql_utils:execute(s_read, Sql) of
            {ok, []} -> 
                {error, ?err(stock_sn_not_exist, RSN)};
	    {ok, R} ->
                case ?v(<<"state">>, R) of
                    ?IN_STOCK ->
                        {error, ?err(stock_been_checked, RSN)};
                    ?IN_BACK ->
                        {error, ?err(stock_been_canceled, RSN)};
                    ?IN_ROAD -> 
                        Sqls = ?w_transfer_sql:cancel_transfer(Merchant, RSN),
                        ?sql_utils:execute(transaction, Sqls, RSN)
                end
        end,
    {reply, Reply, State}; 

handle_call({list_inventory, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_inventory  with merchant ~p, conditions ~p", [Merchant, Conditions]), 
    QType = ?v(<<"qtype">>, Conditions, 0), 
    NewConditions = 
	lists:foldr(
	  fun({<<"shop">>, Shop}, Acc) ->
		  [{<<"shop">>, case QType of
				    1 -> ?w_good_sql:realy_shop(true, Merchant, Shop);
				    _ -> ?w_good_sql:realy_shop(Merchant, Shop)
				end}|Acc];
	     ({<<"qtype">>, _}, Acc) ->
		  Acc;
	     (C, Acc) ->
		  [C|Acc]
	  end, [], Conditions), 
		   
    Sql = ?w_good_sql:inventory(list, Merchant, NewConditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_inventory_info, Merchant, Conditions}, _From, State) ->
    Sql = ?w_good_sql:inventory(list_info, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({list_new_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("list_new_detail  with merchant ~p, conditions ~p",
	   [Merchant, Conditions]),
    Sql = ?w_good_sql:inventory(
	     new_rsn_groups, new, Merchant, Conditions, fun() -> [] end),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({trace_transfer, Merchant, Conditions}, _From, State) ->
    ?DEBUG("trace_transfer  with merchant ~p, conditions ~p",
	   [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(
	     transfer_rsn_groups, transfer, Merchant, Conditions, fun() -> [] end),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% handle_call({last_reject, Merchant, Conditions}, _From, State) ->
%%     ?DEBUG("last_reject with merchant ~p, Conditions ~p", [Merchant, Conditions]),
%%     Shop = ?v(<<"shop">>, Conditions),
%%     Firm = ?v(<<"firm">>, Conditions),
%%     NewConditions = proplists:delete(<<"firm">>,
%% 			  proplists:delete(<<"shop">>, Conditions)),
    
%%     Sql = ?w_good_sql:inventory(last_reject, Merchant, Shop, Firm, NewConditions),
%%     Reply = ?sql_utils:execute(s_read, Sql),
%%     {reply, Reply, State}; 
    
handle_call({abstract_inventory, Merchant, Shop, Conditions}, _From, State) ->
    ?DEBUG("abstract_inventory with merchant ~p, Shop ~p, conditions ~p",
	   [Merchant, Shop, Conditions]),
    Sql = ?w_good_sql:inventory(abstract, Merchant, Shop, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({set_promotion, Merchant, Promotions, Conditions}, _From, State) ->
    ?DEBUG("set_promotion with merchant ~p, promotions ~p, conditions ~p",
	   [Merchant, Promotions, Conditions]), 
    Sql = ?w_good_sql:inventory(
	     set_promotion, Merchant, Promotions, Conditions),
    
    Reply = ?sql_utils:execute(write, Sql, ok),
    {reply, Reply, State};

handle_call({update_batch, Merchant, Attrs, Conditions}, _From, State) ->
    ?DEBUG("update_batch with merchant ~p, attrs ~p, conditions ~p",
	   [Merchant, Attrs, Conditions]), 
    Sqls = ?w_good_sql:inventory(
	     update_batch, Merchant, Attrs, Conditions),

    Reply = ?sql_utils:execute(transaction, Sqls, Merchant),
    {reply, Reply, State};

handle_call({adjust_price, Merchant, Inventories, Attrs}, _From, State) ->
    ?DEBUG("adjust_price with merchant ~p, inventories ~p, attrs ~p",
	   [Merchant, Inventories, Attrs]),

    Shop = ?v(<<"shop">>, Attrs),
    PMode = ?v(<<"pmode">>, Attrs),
    SMode = ?v(<<"smode">>, Attrs),
    Sqls = 
	lists:foldr(
	  fun({struct, Inv}, Acc) ->
		  StyleNumber = ?v(<<"style_number">>, Inv),
		  Brand = ?v(<<"brand">>, Inv),
		  OrgPrice = ?v(<<"org_price">>, Inv),
		  TagPrice = ?v(<<"tag_price">>, Inv),
		  Discount = ?v(<<"discount">>, Inv), 
		  EDiscount   =
		      case TagPrice == 0 of
			  true -> 0;
			  false ->
			      ?to_f(float_to_binary(
				      OrgPrice / TagPrice, [{decimals, 3}])) * 100
		      end,
		  
		  ["update w_inventory set discount=" ++ ?to_s(Discount)
		   ++ case PMode of
			  1 -> ", tag_price=" ++ ?to_s(TagPrice)
				   ++ ", ediscount=" ++ ?to_s(EDiscount);
			  0 -> []
		      end
		   ++ case SMode of
			  1 -> ", score=-1";
			  0 -> []
		      end
		   ++ " where merchant=" ++ ?to_s(Merchant)
		   ++ " and " ++ ?utils:to_sqls(proplists, {<<"shop">>, Shop})
		   ++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)|Acc]
	  end, [], Inventories),
    Reply = ?sql_utils:execute(transaction, Sqls, Merchant),
    {reply, Reply, State};
    
handle_call({get_new, Merchant, RSN}, _From, State) ->
    ?DEBUG("get_new_inventory wht merchant ~p, RSN ~p", [Merchant, RSN]),
    Sql = ?w_good_sql:inventory(
	     new_detail,
	     new,
	     Merchant,
	     [{<<"rsn">>, ?to_b(RSN)}],
	     fun()-> "" end),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_amount, Merchant, Shop, StyleNumber, Brand}, _From, State) ->
    ?DEBUG("get_amount, with Merchant ~p, Shop ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, Shop, StyleNumber, Brand]),

    RealyShop = ?w_good_sql:realy_shop(true, Merchant, Shop),
    Sql = "select amount as total from w_inventory"
	" where style_number=" ++ "\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand)
	++ " and shop=" ++ ?to_s(RealyShop) 
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};

handle_call({get_tagprice, Merchant, Shop, StyleNumber, Brand}, _From, State) ->
    ?DEBUG("get_tagprice, with Merchant ~p, Shop ~p, StyleNumber ~p, Brand ~p",
	   [Merchant, Shop, StyleNumber, Brand]),

    RealyShop = ?w_good_sql:realy_shop(true, Merchant, Shop),
    Sql = "select style_number, brand, amount, org_price, tag_price, discount, ediscount"
	" from w_inventory"
	" where style_number=" ++ "\'" ++ ?to_s(StyleNumber) ++ "\'"
	" and brand=" ++ ?to_s(Brand)
	++ " and shop=" ++ ?to_s(RealyShop) 
	++ " and merchant=" ++ ?to_s(Merchant),

    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% filter with pagination
%% =============================================================================
%% new
handle_call({total_news, Merchant, Fields}, _From, State) ->
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Fields, [], []),
    CountSql = count_table(w_inventory_new, Merchant, C),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_news, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_with_and: currentPage ~p, ItemsPerpage ~p"
	   ", Merchant ~p~nfields ~p",
	   [CurrentPage, ItemsPerPage, Merchant, Fields]),
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Fields, [], []),
    Sql = ?w_good_sql:inventory(
	     new_detail_with_pagination,
	     Merchant, C, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% reject
%% handle_call({total_rejects, Merchant, Fields}, _From, State) ->
%%     CountSql = count_table(w_inventory_new, reject, Merchant, Fields),
%%     Reply = ?sql_utils:execute(s_read, CountSql),
%%     {reply, Reply, State}; 

%% handle_call({filter_rejects, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
%%     ?DEBUG("filter_rejects_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
%% 	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
%%     %% {StartTime, EndTime, Conditions} = cut(fields_with_prifix, Fields),
%%     Sql = ?w_good_sql:inventory(
%% 	     reject_detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
%%     Reply = ?sql_utils:execute(read, Sql),
%%     {reply, Reply, State}; 

%% fix
handle_call({total_fix, Merchant, Fields}, _From, State) ->
    Sql = "rsn, exist, fixed, metric",
    CountTable = ?sql_utils:count_table(w_inventory_fix, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
    	", sum(exist) as t_exist"
    	", sum(fixed) as t_fixed"
    	", sum(metric) as t_metric"
    	" from ("
	++ CountTable ++ ") a",
    %% Sql = ?sql_utils:count_table("w_inventory_fix", Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_fix, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_fix_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     fix_detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 


%% transfer
handle_call({total_transfer, Merchant, Fields}, _From, State) ->
    Sql = "rsn, total",
    CountTable = ?sql_utils:count_table(w_inventory_transfer, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
        ", sum(total) as t_total"
        " from ("
        ++ CountTable ++ ") a",
    %% Sql = ?sql_utils:count_table("w_inventory_fix", Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, CountSql),    {reply, Reply, State};

handle_call({filter_transfer, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_transfer_with_and: " "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
           "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = ?w_good_sql:inventory(
	     transfer_detail_with_pagination,
	     Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% good
handle_call({total_goods, Merchant, Fields}, _From, State) ->
    Sql = ?sql_utils:count_table("w_inventory_good", Merchant, Fields),
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_goods, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_goods_with_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),

    Sql = ?w_good_sql:good(
	     detail_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

%% inventory
handle_call({total_groups, Merchant, Fields}, _From, State) ->
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Fields),
    RealyConditions = ?w_good_sql:realy_conditions(Merchant, NewConditions), 
    ExtraCondtion = ?w_good_sql:sort_condition(stock, NewConditions),

    Sql = "select count(*) as total"
	", sum(amount) as t_amount"
	", sum(sell) as t_sell"
	", sum(amount * org_price) as t_lmoney"
	" from w_inventory"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, RealyConditions)
	++ ExtraCondtion
	++ " and " ++ ?sql_utils:condition(time_no_prfix, StartTime, EndTime),
    
    Reply = ?sql_utils:execute(s_read, Sql),
    {reply, Reply, State}; 

handle_call({filter_groups, {Mode, Sort}, Merchant,
	     CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_groups_with_and: mode ~p, sort ~p, currentPage ~p, ItemsPerpage ~p"
	   ", Merchant ~p~nfields ~p",
	   [Mode, Sort, CurrentPage, ItemsPerPage, Merchant, Fields]),
    %% C = realy_conditions(Merchant, Fields),
    Sql = ?w_good_sql:inventory({group_detail_with_pagination, Mode, Sort},
				Merchant, Fields, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%% =============================================================================
%% new
%% =============================================================================
handle_call({get_inventory_new_rsn, Merchant, Conditions}, _From, State) ->
    Sql = ?w_good_sql:inventory(inventory_new_rsn, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({total_new_rsn_groups, Merchant, Conditions}, _From, State) -> 
    {DConditions, NConditions}
	= ?w_good_sql:filter_condition(inventory_new, Conditions, [], []),

    {StartTime, EndTime, CutNConditions}
    	= ?sql_utils:cut(fields_with_prifix, NConditions),

    {_, _, CutDCondtions}
    	= ?sql_utils:cut(fields_no_prifix, DConditions),

    CorrectCutDConditions = ?utils:correct_condition(<<"b.">>, CutDCondtions),
    
    CountSql = "select count(*) as total"
    	", SUM(b.amount) as t_amount"
	", SUM(b.over) as t_over"
	", SUM(b.org_price * (b.amount - b.over)) as t_balance" 
    	" from w_inventory_new_detail b, w_inventory_new a" 
    	" where "
	++ ?sql_utils:condition(proplists_suffix, CorrectCutDConditions)
	++ "b.rsn=a.rsn"

    	++ ?sql_utils:condition(proplists, CutNConditions)
    	++ " and a.merchant=" ++ ?to_s(Merchant)
    	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime),
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};
    
handle_call({filter_new_rsn_groups, Merchant,
	     CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_new_rsn_group_and: "
	   "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     new_rsn_group_with_pagination, Merchant,
	     Fields, CurrentPage, ItemsPerPage), 
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("new_rsn_detail with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(new_rsn_detail, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({get_new_amount, Merchant, Conditions}, _From, State) ->
    ?DEBUG("get_new_amount with merchant ~p, Conditions ~p",
	   [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(get_new_amount, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% fix
%% =============================================================================
handle_call({total_fix_rsn_groups, Merchant, Fields}, _From, State) ->
    Sql = "rsn",
    CountTable = ?sql_utils:count_table(w_inventory_fix, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
	", SUM(exist) as t_exist"
	", SUM(fixed) as t_fixed"
	", SUM(metric) as t_metric"
	" from w_inventory_fix_detail"
	" where rsn in(" ++ CountTable ++ ")",
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State}; 

handle_call({filter_fix_rsn_groups,
	     Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_fix_rsn_group_and: currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
	   "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]), 
    Sql = ?w_good_sql:inventory(
	     fix_rsn_group_with_pagination, Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State}; 

handle_call({fix_rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("rsn_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]), 
    Sql = ?w_good_sql:inventory(fix_rsn_detail, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};


%% =============================================================================
%% transfer
%% =============================================================================
handle_call({total_transfer_rsn_groups, Merchant, Fields}, _From, State) ->
    Sql = "rsn",
    CountTable = ?sql_utils:count_table(w_inventory_transfer, Sql, Merchant, Fields),
    CountSql = "select count(*) as total"
        ", SUM(amount) as t_amount"
        " from w_inventory_transfer_detail"
        " where rsn in(" ++ CountTable ++ ")",
    Reply = ?sql_utils:execute(s_read, CountSql),
    {reply, Reply, State};

handle_call({filter_transfer_rsn_groups, Merchant, CurrentPage, ItemsPerPage, Fields}, _From, State) ->
    ?DEBUG("filter_fix_rsn_group_and: " "currentPage ~p, ItemsPerpage ~p, Merchant ~p~n"
           "fields ~p", [CurrentPage, ItemsPerPage, Merchant, Fields]),
    Sql = ?w_good_sql:inventory(
             transfer_rsn_group_with_pagination,
	     Merchant, Fields, CurrentPage, ItemsPerPage),
    Reply = ?sql_utils:execute(read, Sql),    {reply, Reply, State};

handle_call({transfer_rsn_detail, Merchant, Conditions}, _From, State) ->
    ?DEBUG("transfer_rsn_detail with merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = ?w_good_sql:inventory(transfer_rsn_detail, Merchant, Conditions),
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

%%
%% export
%%
handle_call({new_trans_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_export with merchant ~p, condition ~p", [Merchant, Conditions]),
    {_, C} = ?w_good_sql:filter_condition(inventory_new, Conditions, [], []),
    SortConditions = ?w_good_sql:sort_condition(w_inventory_new, Merchant, C),
    Sql = "select a.id, a.rsn, a.employ as employee_id"
	", a.firm as firm_id, a.shop as shop_id"
	", a.balance, a.should_pay, a.has_pay, a.cash, a.card, a.wire"
	", a.verificate, a.total, a.comment, a.e_pay_type, a.e_pay"
	", a.type, a.state, a.entry_date"

	", b.name as firm"
	", c.name as shop"
	", d.name as employee"

	" from w_inventory_new a"
	" left join suppliers b on a.firm=b.id"
	" left join shops c on a.shop=c.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") d on a.employ=d.number"
	" where " ++ SortConditions ++ "order by a.id desc",
    
    Reply =  ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({new_trans_note_export, Merchant, Conditions}, _From, State)->
    ?DEBUG("new_trans_note_export: merchant ~p\nConditions~p", [Merchant, Conditions]),
    CorrectCondition = ?utils:correct_condition(<<"a.">>, Conditions),

    Sql = 
	"select a.id, a.rsn, a.style_number, a.brand_id, a.type_id, a.season"
	", a.amount as total, a.firm_id, a.year, a.discount, a.entry_date"
	", a.shop_id, a.employee_id, a.in_type"
	
	", b.name as brand"
	", d.name as type"
	", e.name as firm"
	", f.name as shop"
	", h.name as employee"

	" from ("
	"select a.id, a.rsn, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.season, a.amount, a.firm as firm_id"
	", a.year, a.discount, a.entry_date"

	", b.shop as shop_id"
	", b.employ as employee_id"
	", b.type as in_type"

    %% ", c.color as color_id"
    %% ", c.size"
    %% ", c.total"

	" from w_inventory_new_detail a"
	" left join w_inventory_new b on a.rsn=b.rsn" 
    %% " right join w_inventory_new_detail_amount c on a.rsn=c.rsn"
    %% " and a.style_number=c.style_number and a.brand=c.brand"
	" where "
	++ ?utils:to_sqls(proplists, CorrectCondition) ++ " order by a.id desc) a"

	" left join brands b on a.brand_id=b.id"
    %% " left join colors c on a.color_id=c.id"
	" left join inv_types d  on a.type_id=d.id"
	" left join suppliers e on a.firm_id=e.id"

	" left join shops f on a.shop_id=f.id"
	" left join (select id, number, name from employees where merchant="
	++ ?to_s(Merchant) ++ ") h on a.employee_id=h.number", 
    
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({stock_export, Merchant, Conditions}, _From, State) ->
    %% {StartTime, EndTime, NewConditions} =
    %% 	?sql_utils:cut(fields_with_prifix, ?w_good_sql:realy_conditions(Merchant, Conditions)),

    ?DEBUG("stock export:merchant ~p, Conditions ~p", [Merchant, Conditions]),
    {StartTime, EndTime, NewConditions} = ?sql_utils:cut(non_prefix, Conditions), 
    RealyConditions = ?w_good_sql:realy_conditions(Merchant, NewConditions), 
    ExtraCondtion = ?w_good_sql:sort_condition(stock, NewConditions, <<"a.">>),
    
    Sql =
	"select a.id, a.style_number, a.brand as brand_id"
	", a.type as type_id, a.sex, a.season, a.amount"
	", a.firm as firm_id, a.year"

	", a.org_price, a.ediscount, a.tag_price , a.discount"
	", a.shop as shop_id, a.entry_date"

	", b.name as shop"
	", c.name as brand"
	", d.name as type"
	", e.name as firm"

	" from w_inventory a"
	" left join shops b on a.shop=b.id"
	" left join brands c on a.brand=c.id"
	" left join inv_types d on a.type=d.id"
	" left join suppliers e on a.firm=e.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(
	      proplists, ?utils:correct_condition(<<"a.">>, RealyConditions, []))
	++ ExtraCondtion
	++ " and " ++ ?sql_utils:condition(time_with_prfix, StartTime, EndTime)
	++ " order by a.id desc",

        %% ++ ?sql_utils:condition(proplists_suffix, NewConditions)
	%% ++ "a.merchant=" ++ ?to_s(Merchant)
	
	%% ++ case ?sql_utils:condition(time_with_prfix, StartTime, EndTime) of
	%%        [] -> [];
	%%        TimeSql ->  " and " ++ TimeSql
	%%    end
	%% ++ " and a.deleted=" ++ ?to_s(?NO)
	%% ++ " order by a.id desc",
    Reply = ?sql_utils:execute(read, Sql),
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

%%%===================================================================
%%% Internal functions
%%%===================================================================

%% @desc: generate a sn of record
rsn(new, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-", Rsn]);
rsn(reject, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-R-", Rsn]);
rsn(transfer_from, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-F-", Rsn]);
rsn(fix, Merchant, Shop, Rsn) ->
    lists:concat(["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-x-", Rsn]).

%% @desc: geratte a sql
sql(wnew, RSN, Merchant, Shop, Firm, DateTime, Inventories) ->
    RealyShop = ?w_good_sql:realy_shop(Merchant, Shop),
    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      Amounts      = lists:reverse(?v(<<"amount">>, Inv)),
	      ?w_good_sql:amount_new(
		 ?NEW_INVENTORY, RSN, Merchant, RealyShop, Firm, DateTime, Inv, Amounts)
		  ++ Acc0 
      end, [], Inventories);


sql(wreject, RSN, Merchant, Shop, Firm, DateTime, Inventories) ->
    RealyShop = ?w_good_sql:realy_shop(true, Merchant, Shop),
    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      Amounts = lists:reverse(?v(<<"amounts">>, Inv)),
	      ?w_good_sql:amount_reject(
		 RSN, Merchant, RealyShop, Firm, DateTime, Inv, Amounts)
		  ++ Acc0 
      end, [], Inventories);

sql(transfer_from, RSN, Merchant, Shop, TShop, Datetime, Inventories) ->
    RealyShop = ?w_good_sql:realy_shop(true, Merchant, Shop),
    lists:foldr(
      fun({struct, Inv}, Acc0)->
              %% Amounts = lists:reverse(?v(<<"amounts">>, Inv)),
              ?w_transfer_sql:amount_transfer(
                 transfer_from, RSN, Merchant, RealyShop, TShop,
                 Datetime, Inv) ++ Acc0
      end, [], Inventories).

sql(wfix, RSN, DateTime, Merchant, Shop, Inventories) ->
    %% Shop       = ?v(<<"shop">>, Props),
    %% Employe    = ?v(<<"employee">>, Props),

    lists:foldr(
      fun({struct, Inv}, Acc0)->
	      StyleNumber = ?v(<<"style_number">>, Inv),
	      Brand       = ?v(<<"brand">>, Inv),
	      Type        = ?v(<<"type">>, Inv),
	      Firm        = ?v(<<"firm">>, Inv),
	      Year        = ?v(<<"year">>, Inv),
	      Season      = ?v(<<"season">>, Inv),
	      SizeGroup   = ?v(<<"s_group">>, Inv),
	      Free        = ?v(<<"free">>, Inv),
	      Path        = ?v(<<"path">>, Inv),
	      Exist       = ?v(<<"exist">>, Inv),
	      Fixed       = ?v(<<"fixed">>, Inv),
	      Metric      = ?v(<<"metric">>, Inv),
	      OrgPrice    = ?v(<<"org_price">>, Inv),

	      Sql0 = 
		  ["insert into w_inventory_fix_detail("
		   "rsn, style_number, brand, type, s_group, free"
		   ", year, season, firm, path"
		   ", exist, fixed, metric, org_price"
		   ", merchant, shop, entry_date)"
		   " values("
		   ++ "\"" ++ ?to_s(RSN) ++ "\","
		   ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		   ++ ?to_s(Brand) ++ ","
		   ++ ?to_s(Type) ++ ","
		   ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
		   ++ ?to_s(Free) ++ ","
		   ++ ?to_s(Year) ++ ","
		   ++ ?to_s(Season) ++ ","
		   ++ ?to_s(Firm) ++ ","
		   ++ "\'" ++ ?to_s(Path) ++ "\'," 
		   ++ ?to_s(Exist) ++ ","
		   ++ ?to_s(Fixed) ++ ","
		   ++ ?to_s(Metric) ++ ","
		   ++ ?to_s(OrgPrice) ++ ","
		   ++ ?to_s(Merchant) ++ ","
		   ++ ?to_s(Shop) ++ ","
		   ++ "\'" ++ ?to_s(DateTime) ++ "\')",
		   
		  "update w_inventory set amount=amount+" ++ ?to_s(Metric)
		   ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		   ++ " and brand=" ++ ?to_s(Brand)
		   ++ " and shop=" ++ ?to_s(Shop)
		   ++ " and merchant=" ++ ?to_s(Merchant)],

	      Amounts  = lists:reverse(?v(<<"amounts">>, Inv)),
	      
	      Sql0 ++ 
		  lists:foldr(
		    fun({struct, A}, Acc1)->
			    Color  = ?v(<<"cid">>, A),
			    Size   = ?v(<<"size">>, A),
			    AExist  = ?v(<<"count">>, A),
			    AFixed  = ?v(<<"fixed_count">>, A), 
			    AMetric = AFixed - AExist,

			    case AMetric of
				0 -> [];
				_ ->
				    ["update w_inventory_amount set total=total+" ++ ?to_s(AMetric)
				     ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
				     ++ " and brand=" ++ ?to_s(Brand)
				     ++ " and color=" ++ ?to_s(Color)
				     ++ " and size=" ++ "\'" ++ ?to_s(Size) ++ "\'"
				     ++ " and shop=" ++ ?to_s(Shop)
				     ++ " and merchant=" ++ ?to_s(Merchant)]
			    end ++ 
				["insert into w_inventory_fix_detail_amount(rsn"
				 ", merchant, shop, style_number, brand, color, size"
				 ", exist, fixed, metric, entry_date)"
				 " values("
				 ++ "\'" ++ ?to_s(RSN) ++ "\',"
				 ++ ?to_s(Merchant) ++ ","
				 ++ ?to_s(Shop) ++ ","
				 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
				 ++ ?to_s(Brand) ++ ","
				 ++ ?to_s(Color) ++ ","
				 ++ "\'" ++ ?to_s(Size) ++ "\'," 
				 ++ ?to_s(AExist) ++ ","
				 ++ ?to_s(AFixed) ++ ","
				 ++ ?to_s(AMetric) ++ ","
				 ++ "\'" ++ ?to_s(DateTime) ++ "\')"|Acc1] 
		    end, [], Amounts) ++ Acc0

      end, [], Inventories).

count_table(w_inventory_new, Merchant, Conditions) -> 
    %% SubSql = "select a.rsn, a.total, a.should_pay, a.has_pay"
    %% 	", a.cash, a.card, a.wire, a.verificate"
    %% 	" from w_inventory_new a"
    %% 	" where "
    %% 	++ ?w_good_sql:sort_condition(w_inventory_new, Merchant, Conditions),

    CountSql = "select count(*) as total"
    	", sum(a.total) as t_amount"
    	", sum(a.should_pay) as t_spay"
    	", sum(a.has_pay) as t_hpay"
    	", sum(a.cash) as t_cash"
    	", sum(a.card) as t_card"
    	", sum(a.wire) as t_wire"
    	", sum(a.verificate) as t_verificate"
	" from w_inventory_new a where "
	++ ?w_good_sql:sort_condition(
	      w_inventory_new,
	      Merchant,
	      Conditions ++ [{<<"state">>, [0,1]}]),
    CountSql.

%% get_setting([], _Key, Value) ->
%%     Value;
%% get_setting([S|T], Key, Value) ->
%%     case Key =:= ?v(<<"ename">>, S) of
%% 	true -> get_setting([], Key, ?v(<<"value">>, S));
%% 	false -> get_setting(T, Key, Value)
%%     end.
	    
%% rsn(shop, RSN) ->
%%     S = lists:nth(4, string:tokens(?to_s(RSN), "-")),
%%     S.
