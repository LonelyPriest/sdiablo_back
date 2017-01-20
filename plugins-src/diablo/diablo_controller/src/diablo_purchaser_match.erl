%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright DaTang(C) 2017, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jan 2017 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_purchaser_match).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

match_stock(by_shop, Merchant, ShopIds, StartTime, Promot) when is_number(ShopIds)->
    match_stock(by_shop, Merchant, [ShopIds], StartTime, Promot);
    
match_stock(by_shop, Merchant, ShopIds, StartTime, Promot) ->
    ?DEBUG("match_stock_by_shop: merchant ~p, shopIds ~p, startTime ~p, prompt ~p",
	   [Merchant, ShopIds, StartTime, Promot]),
    P = ?w_retailer:get(prompt, Merchant), 
    "select a.id, a.style_number, a.brand as brand_id, a.type as type_id"
	", a.season, a.firm as firm_id, a.s_group, a.free, a.year"
	++ case length(ShopIds) =:= 1 of
	       true -> ", a.amount as total";
	       false -> ", SUM(a.amount) as total"
	   end
	++ 
    %% ", a.promotion as pid"
    %% ", a.score as sid"
	", a.org_price, a.tag_price, a.ediscount, a.discount"
    %% ", a.path, a.entry_date"

	", b.name as brand" 
	", c.name as type"
	" from w_inventory a"

	" left join brands b on a.brand=b.id" 
	" left join inv_types c on a.type=c.id"

	" where a.merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, {<<"a.shop">>, ShopIds})
	++ " and a.entry_date>\'" ++ ?to_s(StartTime) ++ "\'"
	++ " and a." ++ ?w_good_sql:get_match_mode(style_number, Promot)
	++ " group by a.style_number, a.brand"
	" order by id desc limit " ++ ?to_s(P).
    

