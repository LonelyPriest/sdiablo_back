%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2016, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 28 Jan 2016 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_purchaser_transfer).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

amount_transfer(transfer_from, RSN, Merchant, UTable, Shop, TShop, Datetime, Inv, Props) ->
    ?DEBUG("transfer inventory with rsn ~p~nInv ~p", [RSN, Inv]),
    XSale       = ?v(<<"xsale">>, Props, ?NO),
    XMaster     = ?v(<<"xmaster">>, Props, ?NO), 
    %% ShopType    = ?v(<<"shop_type">>, Props, ?SHOP),
    %% TShopType   = ?v(<<"tshop_type">>, Props, ?SHOP),
    
    Amounts     = ?v(<<"amounts">>, Inv),
    Barcode     = ?v(<<"bcode">>, Inv, 0),
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Type        = ?v(<<"type">>, Inv),
    Sex         = ?v(<<"sex">>, Inv), 
    Season      = ?v(<<"season">>, Inv),
    Firm        = ?v(<<"firm">>, Inv),

    VirPrice    = ?v(<<"vir_price">>, Inv),
    OrgPrice    = ?v(<<"org_price">>, Inv),
    TagPrice    = ?v(<<"tag_price">>, Inv),
    EDiscount   = ?v(<<"ediscount">>, Inv),
    Discount    = ?v(<<"discount">>, Inv),

    XDiscount   = ?v(<<"xdiscount">>, Inv, 0),
    XPrice      = ?v(<<"xprice">>, Inv, 0),
    
    %% Amount      = lists:reverse(?v(<<"amount">>, Inv)),
    SizeGroup   = ?v(<<"s_group">>, Inv),
    Free        = ?v(<<"free">>, Inv),
    Year        = case ?v(<<"year">>, Inv) of
		      undefined -> ?utils:current_time(year);
		      CurYear -> CurYear
		  end,
    
    Total       = ?v(<<"total">>, Inv), 
    Path        = ?v(<<"path">>, Inv, []),
    %% AlarmDay    = ?v(<<"alarm_day">>, Inv, ?DEFAULT_ALARM_DAY),

    
    %% Sql1 = case Transfer of
    %% 	       transfer_from ->
    %% 		   ["update w_inventory set"
    %% 		    " amount=amount-" ++ ?to_s(Total)
    %% 		    ++ ", change_date=" ++ "\"" ++ ?to_s(Datetime) ++ "\""
    %% 		    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
    %% 		    ++ " and brand=" ++ ?to_s(Brand)
    %% 		    ++ " and shop=" ++ ?to_s(Shop)
    %% 		    ++ " and merchant=" ++ ?to_s(Merchant)];
    %% 	       transfer_to ->
    %% 		   Sql11 = "select id, style_number, brand, shop"
    %% 		       " from w_inventory"
    %% 		       ++ " where "
    %% 		       ++ "style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
    %% 		       ++ " and brand=" ++ ?to_s(Brand)
    %% 		       ++ " and shop=" ++ ?to_s(Shop)
    %% 		       ++ " and merchant=" ++ ?to_s(Merchant),

    %% 		   case ?sql_utils:execute(s_read, Sql11) of
    %% 		       {ok, []} ->
    %% 			   ["insert into w_inventory(rsn"
    %% 			    ", style_number, brand, type, sex, season, amount"
    %% 			    ", firm, s_group, free, year"
    %% 			    ", org_price, tag_price, pkg_price, price3"
    %% 			    ", price4, price5, discount, path, alarm_day"
    %% 			    ", shop, merchant"
    %% 			    ", last_sell, change_date, entry_date)"
    %% 			    " values("
    %% 			    ++ "\"" ++ ?to_s(-1) ++ "\","
    %% 			    ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
    %% 			    ++ ?to_s(Brand) ++ ","
    %% 			    ++ ?to_s(Type) ++ ","
    %% 			    ++ ?to_s(Sex) ++ ","
    %% 			    ++ ?to_s(Season) ++ ","
    %% 			    ++ ?to_s(Total) ++ ","
    %% 			    ++ ?to_s(Firm) ++ "," 
    %% 			    %% ++ ?to_s(Color) ++ ","
    %% 			    %% ++ "\"" ++ ?to_s(Size) ++ "\","
    %% 			    ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
    %% 			    ++ ?to_s(Free) ++ ","
    %% 			    ++ ?to_s(Year) ++ ","
    %% 			    ++ ?to_s(OrgPrice) ++ ","
    %% 			    ++ ?to_s(TagPrice) ++ ","
    %% 			    ++ ?to_s(PkgPrice) ++ ","
    %% 			    ++ ?to_s(P3) ++ ","
    %% 			    ++ ?to_s(P4) ++ ","
    %% 			    ++ ?to_s(P5) ++ ","
    %% 			    ++ ?to_s(Discount) ++ ","
    %% 			    ++ "\"" ++ ?to_s(Path) ++ "\","
    %% 			    ++ ?to_s(AlarmDay) ++ ","
    %% 			    ++ ?to_s(Shop) ++ ","
    %% 			    ++ ?to_s(Merchant) ++ ","
    %% 			    ++ "\"" ++ ?to_s(Datetime) ++ "\","
    %% 			    ++ "\"" ++ ?to_s(Datetime) ++ "\","
    %% 			    ++ "\"" ++ ?to_s(Datetime) ++ "\")"]; 
    %% 		       {ok, R} ->
    %% 			   ["update w_inventory set"
    %% 			    " amount=amount+" ++ ?to_s(Total)
    %% 			    ++ ", org_price=" ++ ?to_s(OrgPrice)
    %% 			    %% ++ ", tag_price=" ++ ?to_s(TagPrice)
    %% 			    %% ++ ", pkg_price=" ++ ?to_s(PkgPrice)
    %% 			    %% ++ ", price3=" ++ ?to_s(P3)
    %% 			    %% ++ ", price4=" ++ ?to_s(P4)
    %% 			    %% ++ ", price5=" ++ ?to_s(P5)
    %% 			    %% ++ ", discount=" ++ ?to_s(Discount)
    %% 			    ++ ", change_date="
    %% 			    ++ "\"" ++ ?to_s(Datetime) ++ "\""
    %% 			    ++ ", entry_date="
    %% 			    ++ "\"" ++ ?to_s(Datetime) ++ "\""
    %% 			    ++ " where id=" ++ ?to_s(?v(<<"id">>, R))];
    %% 		       {error, Error} ->
    %% 			   throw({db_error, Error})
    %% 		   end
    %% 	   end, 

    Sql00 = "select id, rsn, style_number, brand"
	%% " from w_inventory_transfer_detail"
	" from" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
	++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
	" and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(Brand),

    
    Sql2 = [ case ?sql_utils:execute(s_read, Sql00) of
		 {ok, []} ->
		     %% "insert into w_inventory_transfer_detail"
		     "insert into" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
			 ++ "(rsn"
			 ", bcode"
			 ", style_number"
			 ", brand"
			 ", type"
			 ", sex"
			 ", season"
			 ", amount"
			 ", firm"
			 ", s_group"
			 ", free"
			 ", year"
			 ", vir_price, org_price, tag_price, discount, ediscount"
			 %% ", xdiscount, xprice"
			 ", path"
			 ", merchant"
			 ", fshop"
			 ", tshop"
			 ", entry_date) values("
			 ++ "\'" ++ ?to_s(RSN) ++ "\',"
			 ++ "\'" ++ ?to_s(Barcode) ++ "\',"
			 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(Brand) ++ ","
			 ++ ?to_s(Type) ++ ","
			 ++ ?to_s(Sex) ++ ","
			 ++ ?to_s(Season) ++ ","
			 ++ ?to_s(Total) ++ ","
	    
			 ++ ?to_s(Firm) ++ ","

			 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
			 ++ ?to_s(Free) ++ ","
			 ++ ?to_s(Year) ++ ","
			 ++ ?to_s(VirPrice) ++ ","
			 ++ case XSale =:= ?YES andalso XMaster =:= ?YES
				%% andalso ShopType =:= ?REPERTORY
				%% andalso TShopType =:= ?SHOP
			    of
				true -> ?to_s(XPrice);
				false -> ?to_s(OrgPrice)
			    end ++ ","
			 
			 ++ ?to_s(TagPrice) ++ ","
			 ++ ?to_s(Discount) ++ ","
		     %% ++ ?to_s(EDiscount) ++ ","

			 ++ case XSale =:= ?YES
				andalso XMaster =:= ?YES
				%% andalso ShopType =:= ?SHOP
				%% andalso TShopType =:= ?REPERTORY
			    of
				true ->
				    ?to_s(XDiscount);
				false ->
				    ?to_s(EDiscount)
			    end ++ ","
			 
			 ++ "\"" ++ ?to_s(Path) ++ "\","
			 ++ ?to_s(Merchant) ++ ","
			 ++ ?to_s(Shop) ++ ","
			 ++ ?to_s(TShop) ++ "," 
			 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		 {ok, R0} ->
		     %% "update w_inventory_transfer_detail"
		     "update" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
			 ++ " set total=" ++ ?to_s(Total)
			 ++ ", org_price=" ++ ?to_s(OrgPrice)
			 ++ " where id=" ++ ?to_s(?v(<<"id">>, R0));
		 {error, E00} ->
		     throw({db_error, E00})
	     end 
	     %% "update w_ventory set amount=amount-" ++ ?to_s(Total)
	     %% ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	     %% ++ " and brand=" ++ ?to_s(Brand)
	     %% ++ " and shop=" ++ ?to_s(Shop)
	     %% ++ " and merchant=" ++ ?to_s(Merchant)
	   ],

    NewFun =
	fun({struct, Attr}, Acc) ->
		Color = ?v(<<"cid">>, Attr),
		Size  = ?v(<<"size">>, Attr),
		Count = ?v(<<"count">>, Attr), 

		Condition = "rsn=\"" ++ ?to_s(RSN) ++ "\""
		    ++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and color=" ++ ?to_s(Color)
		    ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\"", 
		
		
		Sql01 = "select id, rsn, style_number, brand, color, size"
		%% " from w_inventory_transfer_detail_amount"
		    " from" ++ ?table:t(stock_transfer_note, Merchant, UTable)
		    ++ " where " ++ Condition,
		
		[case ?sql_utils:execute(s_read, Sql01) of
		     {ok, []} ->
			 "insert into"
			 %%" w_inventory_transfer_detail_amount"
			     ++ ?table:t(stock_transfer_note, Merchant, UTable)
			     ++ "(rsn"
			     ", style_number, brand, color, size"
			     ", total, merchant, fshop, tshop, entry_date) values("
			     ++ "\"" ++ ?to_s(RSN) ++ "\","
			     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			     ++ ?to_s(Brand) ++ ","
			     ++ ?to_s(Color) ++ ","
			     ++ "\'" ++ ?to_s(Size)  ++ "\'," 
			     ++ ?to_s(Count) ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Shop) ++ ","
			     ++ ?to_s(TShop) ++ "," 
			     ++ "\"" ++ ?to_s(Datetime) ++ "\")"; 
		     {ok, R1} ->
			 "update"
			 %% " w_inventory_transfer_detail_amount"
			     ++ ?table:t(stock_transfer_note, Merchant, UTable)
			     ++ " set total=" ++ ?to_s(Count) 
			     ++ ", entry_date="
			     ++ "\"" ++ ?to_s(Datetime) ++ "\""
			     ++ " where id="
			     ++ ?to_s(?v(<<"id">>, R1));
		     {error, E01} ->
			 throw({db_error, E01})
		 end
		 %% "update w_inventory_amount "
		 %% "set total=total-" ++ ?to_s(Count)
		 %% ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		 %% ++ " and brand=" ++ ?to_s(Brand)
		 %% ++ " and color=" ++ ?to_s(Color)
		 %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
		 %% ++ " and shop=" ++ ?to_s(Shop)
		 %% ++ " and merchant=" ++ ?to_s(Merchant)
		] ++ Acc
	end,

    Sql3 = lists:foldr(NewFun, [], Amounts),
    %% ?DEBUG("all sqls ~p", [Sql1 ++ Sql2 ++ Sql3]),
    Sql2 ++ Sql3.

check_transfer(Merchant, UTable, FShop, TShop, CheckProps) ->
    ?DEBUG("check_inventory_transfer: FShop ~p, TShop ~p, checkprops ~p",
	   [FShop, TShop, CheckProps]), 
    %% Now = ?utils:current_time(format_localtime),

    RSN = ?v(<<"rsn">>, CheckProps),
    %% XSale = ?v(<<"xsale">>, CheckProps, ?NO),
    %% FShopType = ?v(<<"fshop_type">>, CheckProps, 0),
    
    %% TShop = ?v(<<"tshop">>, CheckProps),
    Now = ?v(<<"datetime">>, CheckProps, ?utils:current_time(format_localtime)), 
    
    Sql1 = "update"
	%% " w_inventory_transfer"
	++ ?table:t(stock_transfer, Merchant, UTable)
	++ " set state=" ++ ?to_s(?IN_STOCK)
	++ ", check_date=\"" ++ ?to_s(Now) ++ "\""
	++ " where rsn=\"" ++ ?to_s(RSN) ++ "\"",

    Sql2 = "select bcode"
	", style_number"
	", brand"
	", type"
	", sex"
	", season"
    	", firm"
	", s_group"
	", free"
	", year"
	", vir_price"
    	", org_price"
	", tag_price"
	", discount"
	", ediscount" 
    %% ", xdiscount"
    %% ", xprice" 
	", amount"
	", path"
	", entry_date"
	%% " from w_inventory_transfer_detail"
	" from" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'",

    DefaultScore = case ?w_user_profile:get(shop, Merchant, TShop) of
		       [] -> -1;
		       {ok, [{Setting}]} ->
			   %% ?DEBUG("setting ~p", [Setting]),
			   ?v(<<"score_id">>, Setting)
		   end,
    CheckFun = 
	fun({Transfer}, Acc)->
		Barcode     = ?v(<<"bcode">>, Transfer),
		StyleNumber = ?v(<<"style_number">>, Transfer),
		Brand       = ?v(<<"brand">>, Transfer),
		Type        = ?v(<<"type">>, Transfer),
		Sex         = ?v(<<"sex">>, Transfer), 
		Season      = ?v(<<"season">>, Transfer),
		Firm        = ?v(<<"firm">>, Transfer),

		SizeGroup   = ?v(<<"s_group">>, Transfer),
		Free        = ?v(<<"free">>, Transfer),
		Year        = case ?v(<<"year">>, Transfer) of
				  undefined ->
				      ?utils:current_time(year);
				  CurYear -> CurYear
			      end,

		VirPrice    = ?v(<<"vir_price">>, Transfer),
		OrgPrice    = ?v(<<"org_price">>, Transfer),
		TagPrice    = ?v(<<"tag_price">>, Transfer),
		Discount    = ?v(<<"discount">>, Transfer),
		EDiscount   = ?v(<<"ediscount">>, Transfer),

		%% XDiscount   = ?v(<<"xdiscount">>, Transfer),
		%% XPrice      = ?v(<<"xprice">>, Transfer),
		
		Amount      = ?v(<<"amount">>, Transfer), 
		Path        = ?v(<<"path">>, Transfer, []),
		AlarmDay    = ?v(<<"alarm_day">>, Transfer, ?INVALID_OR_EMPTY),
		EntryDate   = ?v(<<"entry_date">>, Transfer),

		Sql22 = "select style_number, brand, entry_date"
		    %% " from w_inventory_good"
		    " from" ++ ?table:t(good, Merchant, UTable)
		    ++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		    " and brand=" ++ ?to_s(Brand)
		    ++ " and merchant=" ++ ?to_s(Merchant),
		{ok, Good} = ?sql_utils:execute(s_read, Sql22),

		Sql21 = "select id, bcode, style_number, brand, shop, merchant"
		%%" from w_inventory"
		    " from" ++ ?table:t(stock, Merchant, UTable)
		    ++ " where style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    ++ " and brand=" ++ ?to_s(Brand)
		    ++ " and shop=" ++ ?to_s(TShop)
		    ++ " and merchant=" ++ ?to_s(Merchant), 

		case ?sql_utils:execute(s_read, Sql21) of
		    {ok, []} -> 
			["insert into"
			 %% " w_inventory"
			 ++ ?table:t(stock, Merchant, UTable)
			 ++ "(rsn"
			 ", bcode, style_number, brand, firm, type, sex, season, year"
			 ", amount, s_group, free, promotion, score"
			 ", vir_price, org_price, ediscount, tag_price, discount"
			 ", path, alarm_day, shop, merchant"
			 ", last_sell, change_date, entry_date)"
			 " values("
			 ++ "\"" ++ ?to_s(-1) ++ "\","
			 ++ "\"" ++ ?to_s(Barcode) ++ "\","
			 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			 ++ ?to_s(Brand) ++ ","
			 ++ ?to_s(Firm) ++ "," 
			 ++ ?to_s(Type) ++ ","
			 ++ ?to_s(Sex) ++ ","
			 ++ ?to_s(Season) ++ ","
			 ++ ?to_s(Year) ++ "," 
			 ++ ?to_s(Amount) ++ "," 
			 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
			 ++ ?to_s(Free) ++ ","
			 ++ ?to_s(-1) ++ ","
			 ++ ?to_s(DefaultScore) ++ ","
			 
			 ++ ?to_s(VirPrice) ++ "," 
			 ++ ?to_s(OrgPrice) ++ "," 
			 ++ ?to_s(EDiscount) ++ "," 
			 ++ ?to_s(TagPrice) ++ ","
			 ++ ?to_s(Discount) ++ "," 
			 
			 ++ "\"" ++ ?to_s(Path) ++ "\","
			 ++ ?to_s(AlarmDay) ++ ","
			 ++ ?to_s(TShop) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(Now) ++ "\","
			 ++ "\"" ++ ?to_s(Now) ++ "\"," 
			 ++ "\"" ++
			     case Good of
				 [] -> ?to_s(EntryDate);
				 _ -> ?to_s(?v(<<"entry_date">>, Good))
			     end
			 ++ "\")" 
			]; 
		    {ok, R} ->
			OldBCode = ?v(<<"bcode">>, R),
			["update" ++ ?table:t(stock, Merchant, UTable)
			 ++ " set "
			 ++ case OldBCode == ?EMPTY_DB_BARCODE
			    orelse OldBCode == <<"0">>
			    orelse OldBCode == <<>> of
				true -> "bcode=\'" ++ ?to_s(Barcode) ++ "\', "; 
				false -> []
			    end
			 ++ "amount=amount+" ++ ?to_s(Amount)
			 ++ ", s_group=\'" ++ ?to_s(SizeGroup) ++ "\'"
			 %% ++ ", org_price=" ++ ?to_s(OrgPrice) 
			 %% ++ ", ediscount=" ++ ?to_s(eDiscount)
			 ++ ", change_date="
			 ++ "\"" ++ ?to_s(Now) ++ "\"" 
			 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))

			 %% "update w_inventory_amount a inner join("
			 %% "select style_number, brand, color"
			 %% ", size, total"
			 %% " from w_inventory_transfer_detail_amount"
			 %% " where rsn=\"" ++ ?to_s(RSN) ++ "\""
			 %% " and style_number=\"" ++
			 %%     ?to_s(StyleNumber) ++ "\""
			 %% " and brand=" ++ ?to_s(Brand) ++ ") b"
			 %% " on a.style_number=b.style_number"
			 %% " and a.brand=b.brand"
			 %% " and a.size=b.size"
			 %% " and a.color=b.color"
			 %% " and a.shop=" ++ ?to_s(TShop)
			 %% ++ " and a.merchant=" ++ ?to_s(Merchant)
			 %% ++ " set a.total=a.total+b.total"

			 %% " where a.style_number=\"" ++
			 %%     ?to_s(StyleNumber) ++ "\""
			 %% ++ " and a.brand=" ++ ?to_s(Brand)
			 %% ++ " and a.shop=" ++ ?to_s(TShop)
			 %% ++ " and a.merchant=" ++ ?to_s(Merchant)
			]; 
		    {error, Error} ->
			throw({db_error, Error})
		end ++
		    case ?sql_utils:execute(
			    read,
			    "select id"
			    ", style_number"
			    ", brand"
			    ", color"
			    ", size"
			    ", total"
			    ", entry_date"
			    %% " from w_inventory_transfer_detail_amount"
			    " from" ++ ?table:t(stock_transfer_note, Merchant, UTable)
			    ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\""
			    " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
			    " and brand=" ++ ?to_s(Brand)) of
			{ok, []} -> [];
			{ok, RDs}->
			    %% Color = ?v(<<"color">>, RD),
			    %% Size  = ?v(<<"size">>, RD),
			    lists:foldr(
			      fun({RD}, Acc1)->
				      Color = ?v(<<"color">>, RD),
				      Size  = ?v(<<"size">>, RD),
				      Total = ?v(<<"total">>, RD),
				      
				      Sql33 =
					  "select id, style_number, brand, shop"
					  ", color, size, merchant"
				      %% " from w_inventory_amount"
					  " from" ++ ?table:t(stock_note, Merchant, UTable)
					  ++ " where "
					  " style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
					  " and brand=" ++ ?to_s(Brand)
					  ++ " and shop=" ++ ?to_s(TShop)
					  ++ " and color=" ++ ?to_s(Color)
					  ++ " and size=\"" ++ ?to_s(Size) ++ "\""
					  ++ " and merchant=" ++ ?to_s(Merchant),
				      case ?sql_utils:execute(s_read, Sql33) of
					  {ok, []} ->
					      %% Sql22 = "select style_number, brand, entry_date"
					      %% 	  " from w_inventory_good"
					      %% 	  " where style_number=\'"++?to_s(StyleNumber) ++ "\'"
					      %% 	  " and brand=" ++ ?to_s(Brand)
					      %% 	  ++ " and merchant=" ++ ?to_s(Merchant),
					      %% {ok, Good} = ?sql_utils:execute(s_read, Sql22),
					      
					      ["insert into"
					       %% " w_inventory_amount"
					       ++ ?table:t(stock_note, Merchant, UTable)
					       ++ "(rsn"
					       ", style_number"
					       ", brand"
					       ", color"
					       ", size"
					       ", shop"
					       ", merchant"
					       ", total"
					       ", entry_date) values("
					       ++ "-1,"
					       ++ "\"" ++ ?to_s(StyleNumber) ++ "\"," 
					       ++ ?to_s(Brand) ++ ","
					       ++ ?to_s(Color) ++ ","
					       ++ "\'" ++ ?to_s(Size) ++ "\',"
					       ++ ?to_s(TShop) ++ ","
					       ++ ?to_s(Merchant) ++ ","
					       ++ ?to_s(Total) ++ ","
					       ++ "\"" 
					       ++ case Good of
						      [] ->?to_s(?v(<<"entry_date">>, RD));
						      _ -> ?to_s(?v(<<"entry_date">>, Good))
						  end ++ "\")"];
					  {ok, RR} ->
					      ["update"
					       ++ ?table:t(stock_note, Merchant, UTable)
					       %% " w_inventory_amount"
					       ++ " set total=total+" ++ ?to_s(Total)
					       ++ ", entry_date=\"" ++ ?to_s(Now) ++ "\""
					       ++ " where id="
					       ++ ?to_s(?v(<<"id">>, RR))];
					  {error, Error} ->
					      throw({db_error, Error})
				      end ++ Acc1
			      end, [], RDs);
			{error, Error} ->
			    throw({db_error, Error})
		    end ++ Acc
	end,

    Sql3 = case ?sql_utils:execute(read, Sql2) of
	       {ok, []} -> []; 
	       {ok, Transfers} ->
		   lists:foldr(CheckFun, [], Transfers)
		       ++ [%% "update w_inventory_amount a inner join("
			   "update" ++ ?table:t(stock_note, Merchant, UTable) ++ " a"
			   " inner join("
			   "select style_number, brand, color"
			   ", size, total"
			   %% " from w_inventory_transfer_detail_amount"
			   " from" ++ ?table:t(stock_transfer_note, Merchant, UTable)
			   ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\") b"
			   " on a.style_number=b.style_number"
			   " and a.brand=b.brand"
			   " and a.size=b.size"
			   " and a.color=b.color"
			   %% " and a.shop=b.fshop" 
			   " set a.total=a.total-b.total" 
			   " where "
			   "a.merchant=" ++ ?to_s(Merchant) ++ " and a.shop=" ++ ?to_s(FShop),

			   %% "update w_inventory a inner join("
			   "update" ++ ?table:t(stock, Merchant, UTable) ++ " a"
			   " inner join("
			   "select style_number, brand, amount"
			   %% " from w_inventory_transfer_detail"
			   " from" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
			   ++ " where rsn=\"" ++ ?to_s(RSN) ++ "\") b"
			   " on a.style_number=b.style_number"
			   " and a.brand=b.brand" 
			   %% " and a.shop=b.fshop" 
			   " set a.amount=a.amount-b.amount" 
			   " where "
			   ++ "a.merchant=" ++ ?to_s(Merchant) 
			   ++ " and a.shop=" ++ ?to_s(FShop)
			  ]
	   end,
	    
    %% ?DEBUG("Sql3 ~p", [Sql3]),
    %% Sql2 = "insert into w_inventory("
    %% 	"style_number, brand, type, sex, season, amount"
    %% 	", firm, s_group, free, year"
    %% 	", org_price, tag_price, pkg_price, price3"
    %% 	", price4, price5, discount, path, alarm_day"
    %% 	", shop, merchant, change_date, entry_date)"
	
    %% 	" select "
    %% 	"style_number, brand, type, sex, season, amount"
    %% 	", firm, s_group, free, year"
    %% 	", org_price, tag_price, pkg_price, price3"
    %% 	", price4, price5, discount, path, alarm_day"
    %% 	", " ++ ?to_s(TShop)
    %% 	++ ", " ++ ?to_s(Merchant)
    %% 	++ ", \"" ++ Now ++ "\""
    %% 	++ ", \"" ++ Now ++ "\""

    %% 	" from (select * from w_inventory_transfer_detail a"
    %% 	" where "
    %% 	" rsn=\"" ++ ?to_s(RSN) ++ "\""
    %% 	" and not exists("
    %% 	"select style_number, brand, shop, merchant from w_inventory"
    %% 	" where style_number=a.style_number"
    %% 	" and brand=a.brand"
    %% 	" and shop=" ++ ?to_s(TShop)
    %% 	++ " and merchant=" ++ ?to_s(Merchant)
    %% 	++ ")) as a",
	
	
    [Sql1] ++ Sql3.

cancel_transfer(Merchant, UTable, RSN) ->
    ["delete from" ++ ?table:t(stock_transfer_note, Merchant, UTable)
     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
     " and merchant=" ++ ?to_s(Merchant),
     
     "delete from" ++ ?table:t(stock_transfer_detail, Merchant, UTable)
     ++ " where rsn=\'"++ ?to_s(RSN) ++ "\'"
     ++ " and merchant=" ++ ?to_s(Merchant),

     "delete from" ++ ?table:t(stock_transfer, Merchant, UTable)
     ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
     " and merchant=" ++ ?to_s(Merchant)
    ].
    
check_stock(Merchant, UTable, RSN) ->
    "select a.style_number, a.brand, a.fshop, a.amount, a.stock"
	" from("
	"select a.style_number"
	", a.brand"
	", a.fshop"
	", a.merchant"
	", a.amount"
	", b.amount as stock"
    %% " from w_inventory_transfer_detail a"
	" from" ++ ?table:t(stock_transfer_detail, Merchant, UTable) ++ " a"
	" left join "
    %% " w_inventory b"
	++ ?table:t(stock, Merchant, UTable) ++ " b on a.style_number=b.style_number"
	" and a.brand=b.brand"
	" and a.fshop=b.shop"
	" and a.merchant=b.merchant"
	" where a.rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and a.merchant=" ++ ?to_s(Merchant) ++ ") a"
	" where a.amount > a.stock".
	
	    
