%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2018, buxianhui
%%% @doc
%%% @ import date from Guan Jia Po
%%% @end
%%% Created :  7 Jun 2018 by buxianhui <buxianhui@myowner.com>

-module(diablo_import_from_gjp).
-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).
-import(diablo_import_from_csv, [read_line/2, stock/3]).

import(Merchant, Shop, Path) -> 
    ?INFO("current path ~p", [file:get_cwd()]),
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    file:close(Device),
    insert_into_db(Merchant, Shop, Content, 0, []).

import(member, Merchant, Shop, Path) ->
    ?DEBUG("current path ~p", [file:get_cwd()]),
    {ok, Device} = file:open(Path, [read]),
    Content = read_line(Device, []),
    file:close(Device),
    {{Year, Month, Date}, {H, M, S}} = calendar:now_to_local_time(erlang:now()),
    Time = lists:flatten(io_lib:format("~2..0w:~2..0w:~2..0w", [H, M, S])),

    %% Datetime = 
    %% 	lists:flatten(
    %% 	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
    %% 			[Year, Month, Date, H, M, S])),
    insert_into_member(Merchant, Shop, Time, Content, [], []).

insert_into_db(Merchant, Shop, [], _Count, Content) ->
    case Content of
	[] -> ok;
	_ ->
	    new(Merchant, Shop, Content)
    end;

insert_into_db(Merchant, Shop, [H|T], Count, Content) ->
    %% {_OrderId, SN, Total, ShiftDate, OrgPrice, TagPrice} = H,
    case Count =:= 100 of
	true ->
	    new(Merchant, Shop, Content),
	    insert_into_db(Merchant, Shop, T, 0, [H]);
	false ->
	    insert_into_db(Merchant, Shop, T, Count + 1, Content ++ [H])
    end.


new(Merchant, Shop, Content) ->
    Datetime = ?utils:current_time(format_localtime),
    RSN = ?w_inventory:rsn(
	     new,
	     Merchant,
	     Shop,
	     ?inventory_sn:sn(w_inventory_new_sn, Merchant)),

    Sql = "select id, number from employees where merchant=" ++ ?to_s(Merchant)
    %% ++ " and shop=" ++ ?to_s(Shop)
	++ " order by id limit 1",

    {ok, Employee} = ?sql_utils:execute(s_read, Sql),
    %% ?DEBUG("employees ~p", [Employee]),
    EmployeeId = ?v(<<"number">>, Employee), 
    gen_sql(Content, RSN, EmployeeId, Merchant, Shop, Datetime, [], 0, 0).


gen_sql([], RSN, Employee, Merchant, Shop, Datetime, Sqls, AllTotal, AllCost) ->
    Sql = w_inventory_new(RSN, Employee, Merchant, Shop, Datetime, AllCost, AllTotal), 
    AllSqls = [{Sql}] ++ Sqls,
    %% ?DEBUG("======= Sqls of one firm  ==== ~n~p", [AllSqls]), 
    SS = lists:foldr(fun({S}, Acc) -> S ++ Acc end, [], AllSqls),
    %% ?DEBUG("SS ~p", [SS]),
    {ok, RSN} = ?sql_utils:execute(transaction, SS, RSN);

gen_sql([H|T], RSN, Employee, Merchant, Shop, Datetime, Sqls, AllTotal, AllCost) ->
    ?DEBUG("H ~p", [H]),
    {BCode, StockInfo, ShiftDate, Total, CostOfDecimal, TagPriceOfDecimal} = H,

    RealBCode = parse_bcode(BCode, <<>>), 
    ?DEBUG("RealBCode ~p", [RealBCode]),
    TagPrice = case TagPriceOfDecimal of
		   <<>> -> 0;
		   _ -> ?to_f(TagPriceOfDecimal)
	       end,

    Cost = case CostOfDecimal of
	       <<>> -> 0;
	       _ -> ?to_f(CostOfDecimal)
	   end,
    
    Discount = 100,
    {ParseSN, NewBrand} = parse_style_number(StockInfo, <<>>, <<>>),
    NewSN = 
	case ParseSN of
	    <<>> -> RealBCode;
	    _ -> ParseSN
	end,

    {ok, BrandId} = 
	case NewBrand of
	    <<>> -> ?attr:brand(new, Merchant, [{<<"name">>, <<"衣世界">>}]);
	_ ->
	    ?attr:brand(new, Merchant, [{<<"name">>, NewBrand}])
	end,
    %% {Type, Sex} = parse_type(StyleNumber), 
    %% {ok, TypeId} =
    %% 	case ?attr:type(new, Merchant, [{<<"name">>, Type}]) of
    %% 	    {ok_exist, _TypeId} ->
    %% 		{ok, _TypeId};
    %% 	    {ok, _TypeId} ->
    %% 		{ok, _TypeId}
    %% 	end,
    TypeId = 23379,
    %% TypeId = 23315,
    ?DEBUG("ShiftDate ~p", [ShiftDate]),
    {Year, P1} = parse_date(ShiftDate, <<>>),
    {Month, P2} = parse_date(P1, <<>>),
    {Date, <<>>} = parse_date(P2, <<>>), 
    %% ?DEBUG("Year ~p, Month ~p, Date ~p", [Year, Month, Date]),
    NewShiftDate = ?utils:correct_datetime(
		      datetime, <<Year/binary, <<"-">>/binary,
				  Month/binary, <<"-">>/binary,
				  Date/binary >>),
    ?DEBUG("NewShiftDate ~p", [NewShiftDate]),
    Season = season(?to_i(Month)),

    EDiscount = stock(ediscount, ?to_f(Cost), ?to_f(TagPrice)),
    %% InventoryExist = ?sql_utils:execute(s_read, Sql0),

    Sql0 = "select id, style_number, brand from w_inventory_71"
	" where style_number=\"" ++ ?to_s(NewSN) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId) 
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),
    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into" ++ ?table:t(stock, Merchant, 1) ++ "(rsn"
		 ", BCode, style_number, brand, type, sex, season, amount, year"
		 ", org_price, tag_price, ediscount, discount"
		 ", alarm_day, shop, merchant"
		 ", entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ string:strip(?to_s(RealBCode)) ++ "\","
		 ++ "\"" ++ ?to_s(NewSN) ++ "\","
		 ++ ?to_s(BrandId) ++ ","
		 ++ ?to_s(TypeId) ++ ","
		 ++ ?to_s(0) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(Cost) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(EDiscount) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ ?to_s(7) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(NewShiftDate) ++ "\")"]; 
	    {ok, R} ->
		["update" ++ ?table:t(stock, Merchant, 1) ++ " set"
		 " amount=amount+" ++ ?to_s(Total) 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))]; 
	    {error, Error} ->
		throw({db_error, Error})
	end,


    Sql20 = "select id, rsn, style_number, brand"
	%% " from w_inventory_new_detail"
	" from" ++ ?table:t(stock_new_detail, Merchant, 1)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(NewSN) ++ "\'"
	" and brand=" ++ ?to_s(BrandId),

    Sql2 = 
	case ?sql_utils:execute(s_read, Sql20) of
	    {ok, []} ->
		["insert into" ++ ?table:t(stock_new_detail, Merchant, 1) ++ "(rsn, style_number"
		 ", brand, type, sex, season, amount"
		 ", year"
		 ", org_price, tag_price, ediscount, discount"
		 ", merchant, shop, entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(NewSN) ++ "\","
		 ++ ?to_s(BrandId) ++ ","
		 ++ ?to_s(TypeId) ++ ","
		 ++ ?to_s(0) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Total) ++ "," 
		 ++ ?to_s(Year) ++ "," 

		 ++ ?to_s(Cost) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(EDiscount) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"];
	    {ok, R20} ->
		["update"
		 ++ ?table:t(stock_new_detail, Merchant, 1)
		 ++ " set amount=amount+" ++ ?to_s(Total) 
		 %% ++ ", entry_date=" ++ "\"" ++ ?to_s(ShiftDate) ++ "\"" 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R20))];
	    {error, Error20} ->
		throw({db_error, Error20})
	end,

    NewFun =
	fun(_Attr, Acc) -> 
		Sql00 = "select id, style_number, brand, color, size"
		    %% " from w_inventory_amount"
		    " from" ++ ?table:t(stock_note, Merchant, 1)
		    ++ " where style_number=\"" ++ ?to_s(NewSN) ++ "\""
		    ++ " and brand=" ++ ?to_s(BrandId)
		    ++ " and color=0"
		    ++ " and size=0"
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant),

		Sql01 =
		    "select id, style_number, brand, color, size"
		    %% " from w_inventory_new_detail_amount"
		    " from" ++ ?table:t(stock_new_note, Merchant, 1)
		    ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		    ++ " and style_number=\"" ++ ?to_s(NewSN) ++ "\""
		    ++ " and brand=" ++ ?to_s(BrandId)
		    ++ " and color=0"
		    ++ " and size=0",
		%% ++ " and shop=" ++ ?to_s(Shop)
		%% ++ " and merchant=" ++ ?to_s(Merchant),

		[case ?sql_utils:execute(s_read, Sql00) of
		     {ok, []} ->
			 "insert" ++ ?table:t(stock_note, Merchant, 1)
			     ++ "(rsn, style_number, brand, color, size"
			     ", shop, merchant, total, entry_date)"
			     " values("
			     ++ "\"" ++ ?to_s(-1) ++ "\","
			     ++ "\"" ++ ?to_s(NewSN) ++ "\","
			     ++ ?to_s(BrandId) ++ ","
			     ++ ?to_s(0) ++ ","
			     ++ "\'" ++ ?to_s(0)  ++ "\',"
			     ++ ?to_s(Shop)  ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Total) ++ "," 
			     ++ "\"" ++ ?to_s(NewShiftDate) ++ "\")"; 
		     {ok, R00} ->
			 "update" ++ ?table:t(stock_note, Merchant, 1) ++ " set"
			     " total=total+" ++ ?to_s(Total) 
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R00));
		     {error, E00} ->
			 throw({db_error, E00})
		 end,

		 case ?sql_utils:execute(s_read, Sql01) of
		     {ok, []} ->
			 %% "insert into w_inventory_new_detail_amount(rsn"
			 "insert into" ++ ?table:t(stock_new_note, Merchant, 1)
			     ++ "(rsn, style_number, brand, color, size"
			     ", total, merchant, shop, entry_date) values("
			     ++ "\"" ++ ?to_s(RSN) ++ "\","
			     ++ "\"" ++ ?to_s(NewSN) ++ "\","
			     ++ ?to_s(BrandId) ++ ","
			     ++ ?to_s(0) ++ ","
			     ++ "\'" ++ ?to_s(0)  ++ "\',"
			     ++ ?to_s(Total) ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Shop) ++ "," 
			     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		     {ok, R01} ->
			 "update" ++ ?table:t(stock_new_note, Merchant, 1) ++ " set"
			     " set total=total+" ++ ?to_s(Total)
			 %% ++ ", entry_date=" ++ ?to_s(Datetime)
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
		     {error, E00} ->
			 throw({db_error, E00})
		 end|Acc]
	end,

    Sql3 = lists:foldr(NewFun, [], [H]),

    Sql40 = "select style_number, brand from" ++ ?table:t(good, Merchant, 1)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and style_number=\'" ++ ?to_s(NewSN) ++ "\'"
	++ " and brand=" ++ ?to_s(BrandId),

    Sql4 = 
	case ?sql_utils:execute(s_read, Sql40) of
	    {ok, []} ->
		["insert" ++ ?table:t(good, Merchant, 1)
		 ++ "(BCode, style_number, sex, color, year, season, type, size, s_group, free"
		 ", brand, firm, org_price, tag_price, ediscount, discount"
		 ", alarm_day, merchant, change_date, entry_date"
		 ") values("
		 ++ "\"" ++ string:strip(?to_s(RealBCode)) ++ "\","
		 ++ "\"" ++ ?to_s(NewSN) ++ "\","
		 ++ ?to_s(0) ++ ","
		 ++ "\"" ++ ?to_s(0) ++ "\","
		 ++ ?to_s(Year) ++ ","
		 ++ ?to_s(Season) ++ "," 
		 ++ ?to_s(TypeId) ++ ","
		 ++ "\"" ++ ?to_s(0) ++ "\","
		 ++ "\"" ++ ?to_s(0) ++ "\","
		 ++ ?to_s(0) ++ ","
		 ++ ?to_s(BrandId) ++ ","
		 ++ ?to_s(-1) ++ ","
		 ++ ?to_s(Cost) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(EDiscount) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ ?to_s(7) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(NewShiftDate) ++ "\","
		 ++ "\"" ++ ?to_s(NewShiftDate) ++ "\")"];
	    {ok, _} ->
		[];
	    {error, E04} ->
		throw({db_error, E04})
	end,
    AllSql = {Sql1 ++ Sql2 ++ Sql3 ++ Sql4}, 
    %% ?DEBUG("Allsql ~p", [AllSql]),
    gen_sql(T, RSN, Employee, Merchant, Shop, Datetime,
	    Sqls ++ [AllSql],
	    AllTotal + ?to_i(Total),
	    AllCost + ?to_f(Cost) * ?to_i(Total)).

w_inventory_new(RSN, Employee, Merchant, Shop, Datetime, ShouldPay, Total)->
    ["insert into" ++ ?table:t(stock_new, Merchant, 1)
     ++ "(rsn, employ, shop, merchant, should_pay, total, type, entry_date) values("
     ++ "\"" ++ ?to_s(RSN) ++ "\","
     ++ "\"" ++ ?to_s(Employee) ++ "\","
     ++ ?to_s(Shop) ++ ","
     ++ ?to_s(Merchant) ++ ","
     ++ ?to_s(ShouldPay) ++ ","
     ++ ?to_s(Total) ++ ","
     ++ ?to_s(0) ++ ","
     ++ "\"" ++ ?to_s(Datetime) ++ "\")"].

parse_type(StyleNumber) ->
    <<H1:1/binary, H2:1/binary, H3:1/binary, _/binary>> = StyleNumber,
    parse_type(H1, H2, H3).

parse_type(<<"6">>, <<"6">>, _H3) ->
    t(12);
parse_type(<<"7">>, <<"7">>, _H3) ->
    t(12);
parse_type(<<"8">>, <<"8">>, _H3) ->
    t(12);
parse_type(<<"9">>, <<"9">>, _H3) ->
    t(12);
parse_type(<<"a">>, _H2, _H3) ->
    t(12);

parse_type(<<"1">>, <<"1">>, <<"1">>) ->
    t(0);
parse_type(<<"1">>, <<"3">>, _H3) ->
    t(0);
parse_type(<<"1">>, <<"6">>, _H3) ->
    t(0);
parse_type(<<"1">>, <<"9">>, _H3) ->
    t(0);
parse_type(<<"2">>, <<"0">>, _H3) ->
    t(0);

parse_type(<<"1">>, <<"1">>, _H3) ->
    t(1);
parse_type(<<"1">>, <<"4">>, _H3) ->
    t(1);

parse_type(<<"1">>, <<"2">>, _H3) ->
    t(2);
parse_type(<<"1">>, <<"5">>, _H3) ->
    t(2);
parse_type(<<"1">>, <<"8">>, _H3) ->
    t(2);

parse_type(<<"1">>, <<"7">>, _H3) ->
    t(3);

parse_type(<<"2">>, <<"1">>, _H3) ->
    t(4);
parse_type(<<"2">>, <<"4">>, _H3) ->
    t(4);

parse_type(<<"2">>, <<"5">>, _H3) ->
    t(4);
parse_type(<<"2">>, <<"7">>, _H3) ->
    t(4);

parse_type(<<"2">>, <<"2">>, _H3) ->
    t(5);
parse_type(<<"2">>, <<"6">>, _H3) ->
    t(5);
parse_type(<<"2">>, <<"8">>, _H3) ->
    t(6);

parse_type(<<"2">>, <<"3">>, _H3) ->
    t(7);

parse_type(<<"3">>, <<"1">>, _H3) ->
    t(8);
parse_type(<<"3">>, <<"2">>, _H3) ->
    t(9);

parse_type(<<"4">>, <<"1">>, _H3) ->
    t(10);
parse_type(<<"4">>, <<"2">>, _H3) ->
    t(10);
parse_type(<<"4">>, <<"3">>, _H3) ->
    t(10);
parse_type(<<"8">>, _H2, _H3) ->
    t(10);
parse_type(<<"9">>, _H2, _H3) ->
    t(10);

parse_type(<<"5">>, _H2, _H3) ->
    t(11);
parse_type(<<"6">>, _H2, _H3) ->
    t(11);
parse_type(<<"7">>, _H2, _H3) ->
    t(11).


t(0) ->
    {<<"男外套">>, 1};
t(1) ->
    {<<"男T恤">>, 1};
t(2) ->
    {<<"男裤">>, 1};
t(3) ->
    {<<"男衬衣">>, 1};
t(4) ->
    {<<"女T恤">>, 0};
t(5) ->
    {<<"女外套">>, 0};
t(6) ->
    {<<"女裤">>, 0};
t(7) ->
    {<<"裙子">>, 0};
t(8) ->
    {<<"童上装">>, 2};
t(9) ->
    {<<"童下装">>, 2};
t(10) ->
    {<<"针棉内衣">>, 0};
t(11) ->
    {<<"日用百货">>, 0};
t(12) ->
    {<<"陈货">>, 0}.

brand(xw) ->
    [{<<"name">>, <<"修文">>}].


season(M) when M=:=1 orelse M=:=2 orelse M=:=3 ->
    0;
season(M) when M=:=4 orelse M=:=5 orelse M=:=6 ->
    1;
season(M) when M=:=7 orelse M=:=8 orelse M=:=9 ->
    2;
season(M) when M=:=10 orelse M=:=11 orelse M=:=12 ->
    3.

parse_date(<<>>, P) ->
    %% {P, <<>>}
    {pack_date(P), <<>>};
parse_date(<<"-", T/binary>>, P) ->
    %% {P, T};
    {pack_date(P), T};
parse_date(<<H, T/binary>>, P) ->
    parse_date(T, <<P/binary, H>>).

parse_birth(<<>>, P) ->
    {pack_date(P), <<>>};
parse_birth(<<"-", T/binary>>, P) ->
    {pack_date(P), T};
parse_birth(<<H, T/binary>>, P) ->
    parse_birth(T, <<P/binary, H>>).

pack_date(String) -> 
    SS = ?to_string(String),
    case length(SS) =:= 1 of
	true -> pack_date(SS, length(SS));
	false -> ?to_b(String)
    end.
pack_date(String, 2) ->
    ?to_b(String);
pack_date(String, Length) ->
    pack_date("0" ++ String, Length + 1).
    

gen_shift_datetime() ->
    Seconds = ?utils:current_time(timestamp) + 60 + ?SECONDS_BEFOR_1970,
    calendar:gregorian_seconds_to_datetime(Seconds).
    


insert_into_member(Merchant, _Shop, _Time, [], _Sort, Acc) -> 
    ?DEBUG("Sqls ~p", [lists:reverse(Acc)]),
    {ok, Merchant} = ?sql_utils:execute(transaction, lists:reverse(Acc), Merchant);

insert_into_member(Merchant, Shop, Time, [H|T], Sort, Acc) ->
    ?DEBUG("H ~p", [H]),
    %% {RName, Phone, Birth} = H,
    {RName, Phone, Score, Date} = H,
    ?DEBUG("size RName ~p", [size(RName)]),

    %% NewBirth = case Birth of
    %% 		   <<>> -> <<"0000-00-00">>;
    %% 		   _ ->
    %% 		       {BirthMonth, _BirthDate} = parse_birth(Birth, <<>>),
    %% 		       BirthDate = pack_date(_BirthDate),
    %% 		       << <<"2018-">>/binary, BirthMonth/binary, <<"-">>/binary, BirthDate/binary>>
    %% 	       end,
    NewBirth = <<"0000-00-00">>,
    ?DEBUG("NewBirth ~p", [NewBirth]),

    Datetime = ?to_s(Date) ++ " " ++ ?to_s(Time),
    ?DEBUG("Datetime ~p", [Datetime]),

    IsExist = 
	case [ P || {_, P, _, _} <- Sort, P =:= Phone ] of
	    [] -> false;
	    _ -> true
	end,

    case size(Phone) =/= 11 orelse IsExist of
	true -> insert_into_member(Merchant, Shop, Time, T, Sort, Acc);
	false -> 
	    Sql0 = "select id, name, mobile from w_retailer"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and mobile=\'" ++ ?to_s(Phone) ++ "\'",

	    case ?sql_utils:execute(s_read, Sql0) of
		{ok, []} -> 
		    UName =
		    	case RName of
		    	    <<>> ->
		    		<<_:6/binary, Name:5/binary>> = Phone,
				Name;
		    	    _ ->
		    		case size(RName) =:= 3 of
		    		    true ->
		    			<<_:6/binary, Name:5/binary>> = Phone,
		    			<<RName/binary, Name/binary>>;
		    		    false ->
					unicode:characters_to_binary(RName)
		    		end
		    	end,

		    ?DEBUG("UName ~ts", [UName]),

		    Sql = ["insert into w_retailer("
			   "name, score, consume, mobile, shop, merchant, Birth, entry_date)"
			   " values ("
			   ++ "\'" ++ ?to_s(UName) ++ "\',"
			   ++ ?to_s(Score) ++ ","
			   ++ ?to_s(0) ++ "," 
			   ++ "\"" ++ ?to_s(Phone) ++ "\","
			   ++ ?to_s(Shop) ++ ","
			   ++ ?to_s(Merchant) ++ ","
			   ++ "\"" ++ ?to_s(NewBirth) ++ "\","
			   ++ "\"" ++  ?to_s(Datetime) ++ "\")"],
		    ?DEBUG("Sql ~p", [Sql]),
		    insert_into_member(Merchant, Shop, Time, T, [H|Sort], Sql ++ Acc);
		{ok, _R} -> 
		    insert_into_member(Merchant, Shop, Time, T, [H|Sort], Acc)
	    end
    end.


parse_style_number(<<>>, SN, Brand)->
    {SN, Brand};
parse_style_number(<<H, T/binary>>, SN, Brand) when H > 127 -> 
    parse_style_number(T, SN, <<Brand/binary, H>>);
parse_style_number(<<H, T/binary>>, SN, Brand)->
    parse_style_number(T, <<SN/binary, H>>, Brand).

parse_bcode(<<>>, BCode) ->
    ?DEBUG("bcode size ~p", [BCode]),
    case size(BCode) =< 3 of
	true -> << <<"0">>/binary, BCode/binary>>;
	false -> BCode
    end;
parse_bcode(<<H, T/binary>>, BCode) when H < 58 ->
    parse_bcode(T, <<BCode/binary, H>>);
parse_bcode(<<_H, T/binary>>, BCode) ->
    parse_bcode(T, BCode).
