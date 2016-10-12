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

amount_transfer(transfer_from, RSN, Merchant, Shop, TShop, Datetime, Inv) ->
    ?DEBUG("transfer inventory with rsn ~p~nInv ~p", [RSN, Inv]), 
    Amounts     = ?v(<<"amounts">>, Inv),
    StyleNumber = ?v(<<"style_number">>, Inv),
    Brand       = ?v(<<"brand">>, Inv),
    Type        = ?v(<<"type">>, Inv),
    Sex         = ?v(<<"sex">>, Inv), 
    Season      = ?v(<<"season">>, Inv),
    Firm        = ?v(<<"firm">>, Inv),

    OrgPrice    = ?v(<<"org_price">>, Inv),
    TagPrice    = ?v(<<"tag_price">>, Inv),
    EDiscount   = ?v(<<"ediscount">>, Inv),
    Discount    = ?v(<<"discount">>, Inv),
    
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
	" from w_inventory_transfer_detail"
	" where rsn=\"" ++ ?to_s(RSN) ++ "\""
	" and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(Brand),

    
    Sql2 = [ case ?sql_utils:execute(s_read, Sql00) of
		 {ok, []} ->
		     "insert into w_inventory_transfer_detail("
			 "rsn, style_number"
			 ", brand, type, sex, season, amount"
			 ", firm, s_group, free, year"
			 ", org_price, tag_price, discount"
			 ", ediscount, path, merchant, fshop, tshop, entry_date) values("
			 ++ "\"" ++ ?to_s(RSN) ++ "\","
			 ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			 ++ ?to_s(Brand) ++ ","
			 ++ ?to_s(Type) ++ ","
			 ++ ?to_s(Sex) ++ ","
			 ++ ?to_s(Season) ++ ","
			 ++ ?to_s(Total) ++ ","
	    
			 ++ ?to_s(Firm) ++ ","

			 ++ "\"" ++ ?to_s(SizeGroup) ++ "\","
			 ++ ?to_s(Free) ++ ","
			 ++ ?to_s(Year) ++ ","
			 %% ++ ?to_s(AlarmDay) ++ "," 
			 ++ ?to_s(OrgPrice) ++ ","
			 ++ ?to_s(TagPrice) ++ ","
			 ++ ?to_s(Discount) ++ ","
			 ++ ?to_s(EDiscount) ++ "," 
			 ++ "\"" ++ ?to_s(Path) ++ "\","
			 ++ ?to_s(Merchant) ++ ","
			 ++ ?to_s(Shop) ++ ","
			 ++ ?to_s(TShop) ++ "," 
			 ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		 {ok, R0} ->
		     "update w_inventory_transfer_detail"
			 " set total=" ++ ?to_s(Total)
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
		    " from w_inventory_transfer_detail_amount"
		    " where " ++ Condition,
		
		[case ?sql_utils:execute(s_read, Sql01) of
		     {ok, []} ->
			 "insert into w_inventory_transfer_detail_amount(rsn"
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
			 "update w_inventory_transfer_detail_amount set"
			     " total=" ++ ?to_s(Count) 
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

check_transfer(Merchant, FShop, TShop, CheckProps) ->
    ?DEBUG("check_inventory_transfer: FShop, TShop, checkprops ~p",
	   [FShop, TShop, CheckProps]), 
    %% Now = ?utils:current_time(format_localtime),

    RSN = ?v(<<"rsn">>, CheckProps),
    %% TShop = ?v(<<"tshop">>, CheckProps),
    Now = ?v(<<"datetime">>, CheckProps, ?utils:current_time(format_localtime)), 
    
    Sql1 = "update w_inventory_transfer set"
	" state=" ++ ?to_s(?IN_STOCK)
	++ ", check_date=\"" ++ ?to_s(Now) ++ "\""
	++ " where rsn=\"" ++ ?to_s(RSN) ++ "\"",

    Sql2 = "select style_number, brand, type, sex, season"
    	", firm, s_group, free, year"
    	", org_price, tag_price, discount, ediscount, amount, path"
	" from w_inventory_transfer_detail"
	" where rsn=\"" ++ ?to_s(RSN) ++ "\"",

    DefaultScore = case ?w_user_profile:get(shop, Merchant, TShop) of
		       [] -> -1;
		       {ok, [{Setting}]} ->
			   %% ?DEBUG("setting ~p", [Setting]),
			   ?v(<<"score_id">>, Setting)
		   end,
    CheckFun = 
	fun({Transfer}, Acc)->
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
		
		OrgPrice    = ?v(<<"org_price">>, Transfer),
		TagPrice    = ?v(<<"tag_price">>, Transfer),
		Discount    = ?v(<<"discount">>, Transfer),
		EDiscount   = ?v(<<"ediscount">>, Transfer), 
		Amount      = ?v(<<"amount">>, Transfer), 
		Path        = ?v(<<"path">>, Transfer, []),
		AlarmDay    = ?v(<<"alarm_day">>, Transfer, ?DEFAULT_ALARM_DAY),

		Sql21 = "select id, style_number, brand, shop, merchant"
		    " from w_inventory"
		    " where "
		    "style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
		    " and brand=" ++ ?to_s(Brand)
		    ++ " and shop=" ++ ?to_s(TShop)
		    ++ " and merchant=" ++ ?to_s(Merchant), 

		case ?sql_utils:execute(s_read, Sql21) of
		    {ok, []} ->
			["insert into w_inventory(rsn"
			 ", style_number, brand, firm, type, sex, season, year"
			 ", amount, s_group, free, promotion, score"
			 ", org_price, tag_price, ediscount, discount"
			 ", path, alarm_day, shop, merchant"
			 ", last_sell, change_date, entry_date)"
			 " values("
			 ++ "\"" ++ ?to_s(-1) ++ "\","
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
			 
			 ++ ?to_s(OrgPrice) ++ ","
			 ++ ?to_s(TagPrice) ++ ","
			 ++ ?to_s(EDiscount) ++ "," 
			 ++ ?to_s(Discount) ++ ","
			 
			 ++ "\"" ++ ?to_s(Path) ++ "\","
			 ++ ?to_s(AlarmDay) ++ ","
			 ++ ?to_s(TShop) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(Now) ++ "\","
			 ++ "\"" ++ ?to_s(Now) ++ "\","
			 ++ "\"" ++ ?to_s(Now) ++ "\")"

			 %% "insert into w_inventory_amount(rsn"
			 %% ", style_number, brand, color, size"
			 %% ", shop, merchant, total, entry_date) select" 
			 %% " -1"
			 %% ", style_number"
			 %% ", brand"
			 %% ", color"
			 %% ", size "
			 %% ", " ++ ?to_s(TShop)
			 %% ++ ", " ++ ?to_s(Merchant)
			 %% ++ ", total"
			 %% ", \"" ++ ?to_s(Now) ++ "\""
			 %% " from w_inventory_transfer_detail_amount"
			 %% " where rsn=\"" ++ ?to_s(RSN) ++ "\""
			 %% " and style_number=\"" ++
			 %%     ?to_s(StyleNumber) ++ "\""
			 %% " and brand=" ++ ?to_s(Brand)
			]; 
		    {ok, R} ->
			["update w_inventory set"
			 " amount=amount+" ++ ?to_s(Amount)
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
			    "select id, style_number"
			    ", brand, color, size, total"
			    " from w_inventory_transfer_detail_amount"
			    " where rsn=\"" ++ ?to_s(RSN) ++ "\""
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
					  " from w_inventory_amount"
					  " where "
					  " style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
					  " and brand=" ++ ?to_s(Brand)
					  ++ " and shop=" ++ ?to_s(TShop)
					  ++ " and color=" ++ ?to_s(Color)
					  ++ " and size=\"" ++ ?to_s(Size) ++ "\""
					  ++ " and merchant=" ++ ?to_s(Merchant),
				      case ?sql_utils:execute(s_read, Sql33) of
					  {ok, []} ->
					      ["insert into w_inventory_amount("
					       "rsn, style_number, brand"
					       ", color, size, shop, merchant"
					       ", total, entry_date) values("
					       ++ "-1,"
					       ++ "\"" ++ ?to_s(StyleNumber) ++ "\"," 
					       ++ ?to_s(Brand) ++ ","
					       ++ ?to_s(Color) ++ ","
					       ++ "\'" ++ ?to_s(Size) ++ "\',"
					       ++ ?to_s(TShop) ++ ","
					       ++ ?to_s(Merchant) ++ ","
					       ++ ?to_s(Total) ++ ","
					       ++ "\"" ++ ?to_s(Now) ++ "\")"];
					  {ok, RR} ->
					      ["update w_inventory_amount"
					       " set total=total+" ++ ?to_s(Total)
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
		       ++ ["update w_inventory_amount a inner join("
			   "select style_number, brand, color"
			   ", size, total"
			   " from w_inventory_transfer_detail_amount"
			   " where rsn=\"" ++ ?to_s(RSN) ++ "\") b"
			   " on a.style_number=b.style_number"
			   " and a.brand=b.brand"
			   " and a.size=b.size"
			   " and a.color=b.color"
			   %% " and a.shop=b.fshop" 
			   " set a.total=a.total-b.total" 
			   " where "
			   ++ "a.merchant=" ++ ?to_s(Merchant) 
			   ++ " and a.shop=" ++ ?to_s(FShop),

			   "update w_inventory a inner join("
			   "select style_number, brand, amount"
			   " from w_inventory_transfer_detail"
			   " where rsn=\"" ++ ?to_s(RSN) ++ "\") b"
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

cancel_transfer(Merchant, RSN) ->
    ["delete from w_inventory_transfer_detail_amount where rsn=\'" ++ ?to_s(RSN) ++ "\'"
     " and merchant=" ++ ?to_s(Merchant),
     
     "delete from w_inventory_transfer_detail where rsn=\'"++ ?to_s(RSN) ++ "\'"
     " and merchant=" ++ ?to_s(Merchant),

     "delete from w_inventory_transfer where rsn=\'" ++ ?to_s(RSN) ++ "\'"
     " and merchant=" ++ ?to_s(Merchant)
    ].
    
