%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2016, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Sep 2016 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_import_from_csv).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

delete(member_not_used, Merchant) ->
    Sql = "select id, merchant from w_retailer where merchant=" ++ ?to_s(Merchant)
	++ " and id>11883 and id<18912",
    [_Total, Sqls] = 
	case ?sql_utils:execute(read, Sql) of
	    {ok, []} -> ok;
	    {ok, Members} ->
		lists:foldr(
		  fun({Member}, [Inc, Acc])->
			  Id = ?v(<<"id">>, Member),
			  Sql1 = "select rsn from w_sale where retailer=" ++ ?to_s(Id)
			      ++ " and merchant=" ++ ?to_s(Merchant),

			  case ?sql_utils:execute(read, Sql1) of
			      {ok, []} ->
				  [ Inc + 1,
				    [{Inc, "delete from w_retailer where id=" ++ ?to_s(Id)
				     ++ " and merchant=" ++ ?to_s(Merchant)}|Acc]
				  ];
			      {ok, _} ->
				  [Inc, Acc]
			  end
		  end, [1, []], Members)
	end,
    %% ?DEBUG("Sqls ~p", [Sqls]),

    lists:foreach(fun({_, DSql})->
    			  ?sql_utils:execute(write, DSql, Merchant)
    		  end, Sqls),
    {ok, Merchant, _Total-1}.
	    

import(member, Merchant, Path) ->
    ?DEBUG("current path ~p", [file:get_cwd()]),
    {ok, Device} = file:open(Path, [read]),
    Content = read_line(Device, []),
    file:close(Device),

    
    {{Year, Month, Date}, {H, M, S}} = calendar:now_to_local_time(erlang:now()),
    Time = lists:flatten(io_lib:format("~2..0w:~2..0w:~2..0w", [H, M, S])),

    Datetime = 
	lists:flatten(
	  io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
			[Year, Month, Date, H, M, S])),
    insert_into_member(Merchant, Datetime, Time, Content, [], []).


insert_into_member(Merchant, _Datetime, _Time, [], _Sort, Acc) ->
    %% ?DEBUG("Sqls ~p", [lists:reverse(Acc)]),
    {ok, Merchant} = ?sql_utils:execute(transaction, lists:reverse(Acc), Merchant);

insert_into_member(Merchant, Datetime, Time, [H|T], Sort, Acc) ->
    {Phone, Shop, Score, Consume, Date} = H,

    NewScore = round(?to_f(Score)),

    NewConsume = case Consume of
		     <<>> -> 0;
		     _ -> Consume
		 end,

    IsExist = 
	case [ P || {P, _, _, _, _} <- Sort, P =:= Phone ] of
	    [] -> false;
	    _ -> true
	end,
    
    case size(Phone) =/= 11 orelse IsExist of
	true -> insert_into_member(Merchant, Datetime, Time, T, Sort, Acc);
	false -> 
	    Sql0 = "select id, name, mobile from w_retailer"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and mobile=\'" ++ ?to_s(Phone) ++ "\'",

	    case ?sql_utils:execute(s_read, Sql0) of
		{ok, []} ->
		    <<_:6/binary, Name:5/binary>> = Phone,
		    Entry = case Date of
				<<>> -> Datetime;
				_ -> ?to_s(Date) ++ " " ++ Time
			    end, 

		    Sql = ["insert into w_retailer("
			   "name, score, consume, mobile, shop, merchant, entry_date)"
			   " values ("
			   ++ "\"" ++ ?to_s(Name) ++ "\","
			   ++ ?to_s(NewScore) ++ ","
			   ++ ?to_s(NewConsume) ++ "," 
			   ++ "\"" ++ ?to_s(Phone) ++ "\","
			   ++ ?to_s(Shop) ++ ","
			   ++ ?to_s(Merchant) ++ ","
			   ++ "\"" ++ ?to_s(Entry) ++ "\")"],
		    insert_into_member(Merchant, Datetime, Time, T, [H|Sort], Sql ++ Acc);
		{ok, R} ->
		    Sql = ["update w_retailer set score=score+" ++ ?to_s(NewScore)
		     ++", consume=consume+" ++ ?to_s(NewConsume)
		     ++ " where id=" ++ ?to_s(?v(<<"id">>, R))
		     ++ " and merchant=" ++ ?to_s(Merchant)],
		    insert_into_member(Merchant, Datetime, Time, T, [H|Sort], Sql ++ Acc)
	    end
    end.

import(firm, Merchant, Shop, Path) ->
    ?DEBUG("current path ~p", [file:get_cwd()]),
    %% {ok, Content} = file:read_file(Path), 
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    file:close(Device),
    insert_into_db(Merchant, Shop, Content, <<>>, []).
    
read_line(Device, Content) ->
    case file:read_line(Device) of
	eof -> read_line(Device, Content, eof);
	{ok, Date}->
	    %% ?DEBUG("Date ~p", [Date]),
	    ParseLine = list_to_tuple(parse_line(?to_b(Date))),
	    %% ?DEBUG("parse line ~p", [ParseLine]), 
	    read_line(Device, Content ++ [ParseLine])
    end.

read_line(_Device, Content, eof) ->
    Content.


parse_line(Date) when is_binary(Date)->
    parse_line(Date, <<>>, []).

parse_line(<<>>, F, Contents) ->
    C = string:strip(?to_s(F), both, $\n), 
    Contents ++ [?to_b(C)];
parse_line(<<",", T/binary>>, F, Contents) ->
    parse_line(T, <<>>, Contents ++ [F]);
parse_line(<<H, T/binary>>, F, Contents) ->
    parse_line(T, <<F/binary, H>>, Contents).
    

insert_into_db(Merchant, Shop, [], _F, Content) ->
    %% ?DEBUG("content ~p", [Content]),
    case Content of
	[] -> ok;
	_ ->
	    NewContent = sort(firm, Content, []),
	    %% ?DEBUG("new content ~p", [NewContent]),
	    new(Merchant, Shop, NewContent)
    end;
    %% Datetime = ?utils:current_time(format_localtime),
    %% RSN = ?w_inventory:rsn(
    %% 	     new,
    %% 	     Merchant,
    %% 	     Shop,
    %% 	     ?inventory_sn:sn(w_inventory_new_sn, Merchant)),

    %% Sql = "select id, number from employees where merchant=" ++ ?to_s(Merchant)
    %% 	++ " and shop=" ++ ?to_s(Shop)
    %% 	++ " order by id limit 1",

    %% {ok, Employee} = ?sql_utils:execute(s_read, Sql),
    %% EmployeeId = ?v(<<"number">>, Employee), 
    %% insert_int_db(firm, Content, RSN, EmployeeId, Merchant, Shop, Datetime, [], 0, 0);

insert_into_db(Merchant, Shop, [H|T], F, Content) ->
    {Firm, _SN, _Brand, _Type, _YS, _TagPrice, _Discount, _Total, _Cost} = H,

    case F =:= Firm of
	true ->
	    insert_into_db(Merchant, Shop, T, F, Content ++ [H]);
	false ->
	    %% ?DEBUG("content ~p", [Content]),
	    case Content of
		[] -> ok;
		_ ->
		    NewContent = sort(firm, Content, []),
		    %% ?DEBUG("new content ~p", [NewContent]),
		    new(Merchant, Shop, NewContent)
		    %% Datetime = ?utils:current_time(format_localtime),
		    %% RSN = ?w_inventory:rsn(
		    %% 	     new,
		    %% 	     Merchant,
		    %% 	     Shop,
		    %% 	     ?inventory_sn:sn(w_inventory_new_sn, Merchant)),

		    %% Sql = "select id, number from employees where merchant=" ++ ?to_s(Merchant)
		    %% 	++ " and shop=" ++ ?to_s(Shop)
		    %% 	++ " order by id limit 1",

		    %% {ok, Employee} = ?sql_utils:execute(s_read, Sql),
		    %% ?DEBUG("employees ~p", [Employee]),
		    %% EmployeeId = ?v(<<"number">>, Employee),

		    %% insert_int_db(
		    %%   firm, Content, RSN, EmployeeId, Merchant, Shop, Datetime, [], 0, 0)
	    end,
	    insert_into_db(Merchant, Shop, T, Firm, [H])
    end.


insert_int_db(firm, [], RSN, Employee, Merchant, Shop, Datetime, Sqls, AllTotal, AllCost) ->
    Sql = w_inventory_new(RSN, Employee, Merchant, Shop, Datetime, AllCost, AllTotal), 
    AllSqls = [{Sql}] ++ Sqls,
    %% ?DEBUG("======= Sqls of one firm  ==== ~n~p", [AllSqls]), 
    SS = lists:foldr(fun({S}, Acc) -> S ++ Acc end, [], AllSqls),
    %% ?DEBUG("SS ~p", [SS]),

    {ok, RSN} = ?sql_utils:execute(transaction, SS, RSN);
    
insert_int_db(firm, [H|T], RSN, Employee, Merchant, Shop, Datetime, Sqls, AllTotal, AllCost) ->
    %% ?DEBUG("H ~p", [H]),
    {_Firm, SN, Brand, Type, YS,
     TagPriceOfDecimal, DiscountOfDecimal, Total, CostOfDecimal} = H,

    TagPrice = case TagPriceOfDecimal of
		   <<>> -> 0;
		   _ -> ?to_f(TagPriceOfDecimal)
	       end,

    Cost = case CostOfDecimal of
	       <<>> -> 0;
	       _ -> ?to_f(CostOfDecimal)
	   end,
    
    Discount = case DiscountOfDecimal of
		   <<>> ->100;
		   _ -> ?to_f(DiscountOfDecimal) * 10
	       end,
    
    {ok, BrandId} = ?attr:brand(new, Merchant, [{<<"name">>, Brand}]),
    {ok, TypeId} = case Type of
		       <<>> -> {ok, 48};
		       _ -> ?attr:type(new, Merchant, Type)
		   end,
    <<Year:4/binary, CSeason/binary>> = YS,

    Season = case CSeason of
		 <<"春">> -> 0;
		 <<"夏">> -> 1;
		 <<"秋">> -> 2;
		 <<"冬">> -> 3
	     end,

    EDiscount = stock(ediscount, ?to_f(Cost), ?to_f(TagPrice)),
    
    %% InventoryExist = ?sql_utils:execute(s_read, Sql0),

    Sql0 = "select id, style_number, brand from w_inventory"
	" where style_number=\"" ++ ?to_s(SN) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId)
    %% ++ " and color=" ++ ?to_s(Color)
    %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),
    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into w_inventory(rsn"
		 ", style_number, brand, type, sex, season, amount, year"
		 ", org_price, tag_price, ediscount, discount"
		 ", alarm_day, shop, merchant"
		 ", entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ ?to_s(SN) ++ "\","
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
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"]; 
	    {ok, R} ->
		["update w_inventory set"
		 " amount=amount+" ++ ?to_s(Total) 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))]; 
	    {error, Error} ->
		throw({db_error, Error})
	end,


    Sql20 = "select id, rsn, style_number, brand"
	" from w_inventory_new_detail"
	" where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	" and style_number=\'" ++ ?to_s(SN) ++ "\'"
	" and brand=" ++ ?to_s(BrandId),

    Sql2 = 
	case ?sql_utils:execute(s_read, Sql20) of
	    {ok, []} ->
		["insert into w_inventory_new_detail(rsn, style_number"
		 ", brand, type, sex, season, amount"
		 ", year"
		 ", org_price, tag_price, ediscount, discount"
		 ", merchant, shop, entry_date) values("
		 ++ "\"" ++ ?to_s(RSN) ++ "\","
		 ++ "\"" ++ ?to_s(SN) ++ "\","
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
		["update w_inventory_new_detail" 
		 " set amount=amount+" ++ ?to_s(Total) 
		 ++ ", entry_date=" ++ "\"" ++ ?to_s(Datetime) ++ "\"" 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R20))];
	    {error, Error20} ->
		throw({db_error, Error20})
	end,

    NewFun =
	fun(_Attr, Acc) -> 
		Sql00 = "select id, style_number, brand, color, size"
		    " from w_inventory_amount"
		    " where style_number=\"" ++ ?to_s(SN) ++ "\""
		    ++ " and brand=" ++ ?to_s(BrandId)
		    ++ " and color=0"
		    ++ " and size=0"
		    ++ " and shop=" ++ ?to_s(Shop)
		    ++ " and merchant=" ++ ?to_s(Merchant),

		Sql01 =
		    "select id, style_number, brand, color, size"
		    " from w_inventory_new_detail_amount"
		    " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		    ++ " and style_number=\"" ++ ?to_s(SN) ++ "\""
		    ++ " and brand=" ++ ?to_s(BrandId)
		    ++ " and color=0"
		    ++ " and size=0",
		%% ++ " and shop=" ++ ?to_s(Shop)
		%% ++ " and merchant=" ++ ?to_s(Merchant),

		[case ?sql_utils:execute(s_read, Sql00) of
		     {ok, []} ->
			 "insert into w_inventory_amount(rsn"
			     ", style_number, brand, color, size"
			     ", shop, merchant, total, entry_date)"
			     " values("
			     ++ "\"" ++ ?to_s(-1) ++ "\","
			     ++ "\"" ++ ?to_s(SN) ++ "\","
			     ++ ?to_s(BrandId) ++ ","
			     ++ ?to_s(0) ++ ","
			     ++ "\'" ++ ?to_s(0)  ++ "\',"
			     ++ ?to_s(Shop)  ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Total) ++ "," 
			     ++ "\"" ++ ?to_s(Datetime) ++ "\")"; 
		     {ok, R00} ->
			 "update w_inventory_amount set"
			     " total=total+" ++ ?to_s(Total) 
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R00));
		     {error, E00} ->
			 throw({db_error, E00})
		 end,

		 case ?sql_utils:execute(s_read, Sql01) of
		     {ok, []} ->
			 "insert into w_inventory_new_detail_amount(rsn"
			     ", style_number, brand, color, size"
			     ", total, merchant, shop, entry_date) values("
			     ++ "\"" ++ ?to_s(RSN) ++ "\","
			     ++ "\"" ++ ?to_s(SN) ++ "\","
			     ++ ?to_s(BrandId) ++ ","
			     ++ ?to_s(0) ++ ","
			     ++ "\'" ++ ?to_s(0)  ++ "\',"
			     ++ ?to_s(Total) ++ ","
			     ++ ?to_s(Merchant) ++ ","
			     ++ ?to_s(Shop) ++ "," 
			     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
		     {ok, R01} ->
			 "update w_inventory_new_detail_amount"
			     " set total=total+" ++ ?to_s(Total)
			     ++ ", entry_date=" ++ ?to_s(Datetime)
			     ++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
		     {error, E00} ->
			 throw({db_error, E00})
		 end|Acc]
	end,

    Sql3 = lists:foldr(NewFun, [], [H]),

    Sql40 = "select style_number, brand from w_inventory_good"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and style_number=\'" ++ ?to_s(SN) ++ "\'"
	++ " and brand=" ++ ?to_s(BrandId),

    Sql4 = 
	case ?sql_utils:execute(s_read, Sql40) of
	    {ok, []} ->
		["insert into w_inventory_good"
		 "(style_number, sex, color, year, season, type, size, s_group, free"
		 ", brand, firm, org_price, tag_price, ediscount, discount"
		 ", alarm_day, merchant, change_date, entry_date"
		 ") values("
		 ++ "\"" ++ ?to_s(SN) ++ "\","
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
		 ++ "\"" ++ ?to_s(Datetime) ++ "\","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"];
	    {ok, _} ->
		[];
	    {error, E04} ->
		throw({db_error, E04})
	end,
    AllSql = {Sql1 ++ Sql2 ++ Sql3 ++ Sql4}, 
    %% ?DEBUG("Allsql ~p", [AllSql]),
    insert_int_db(firm, T, RSN, Employee, Merchant, Shop, Datetime,
		  Sqls ++ [AllSql],
		  AllTotal + ?to_i(Total),
		  AllCost + ?to_f(Cost) * ?to_i(Total)).


w_inventory_new(RSN, Employee, Merchant, Shop, Datetime, ShouldPay, Total)->
    ["insert into w_inventory_new("
     "rsn, employ, shop, merchant, should_pay, total, type, entry_date) values("
     ++ "\"" ++ ?to_s(RSN) ++ "\","
     ++ "\"" ++ ?to_s(Employee) ++ "\","
     ++ ?to_s(Shop) ++ ","
     ++ ?to_s(Merchant) ++ ","
     ++ ?to_s(ShouldPay) ++ ","
     ++ ?to_s(Total) ++ ","
     ++ ?to_s(0) ++ ","
     ++ "\"" ++ ?to_s(Datetime) ++ "\")"].


new(Merchant, Shop, Content) ->
    Datetime = ?utils:current_time(format_localtime),
    RSN = ?w_inventory:rsn(
	     new,
	     Merchant,
	     Shop,
	     ?inventory_sn:sn(w_inventory_new_sn, Merchant)),

    Sql = "select id, number from employees where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " order by id limit 1",

    {ok, Employee} = ?sql_utils:execute(s_read, Sql),
    ?DEBUG("employees ~p", [Employee]),
    EmployeeId = ?v(<<"number">>, Employee),

    insert_int_db(firm, Content, RSN, EmployeeId, Merchant, Shop, Datetime, [], 0, 0).
    
stock(ediscount, _OrgPrice, TagPrice) when TagPrice == 0 -> 0;
stock(ediscount, OrgPrice, _TagPrice) when OrgPrice == 0 -> 0;
stock(ediscount, OrgPrice, TagPrice) ->
    %% case OrgPrice > TagPrice of
    %% 	true ->
    %% 	    -?to_f(float_to_binary((TagPrice - OrgPrice) / TagPrice, [{decimals, 3}])) * 100;
    %% 	false ->
	    ?to_f(float_to_binary(OrgPrice / TagPrice, [{decimals, 3}])) * 100.
    %% end.

sort(firm, [], Acc) ->
    Acc;
sort(firm, [H|T], Acc) ->
    {_Firm, SN, Brand, _Type, _YS, _TagPrice, _Discount, Total, _Cost} = H,

    NewAcc = 
	case [ A || {_, SN2, Brand2, _, _, _, _, _, _} = A <- Acc, SN2 =:= SN, Brand2 =:= Brand] of
	    [] -> [H|Acc];
	    [{_, _, _, _, _, _, _, Total2, _}] = S ->
		%% NewC = [{_Firm, SN, Brand, _Type, _YS,
		%% 	 _TagPrice, _Discount, ?to_i(Total) + ?to_i(Total2), _Cost}],
		%% ?DEBUG("new c ~p", [NewC]),
		(Acc -- S)
		    ++ [{_Firm, SN, Brand, _Type, _YS,
			 _TagPrice, _Discount, ?to_i(Total) + ?to_i(Total2), _Cost}]
	end,
    %% ?DEBUG("new acc ~p", [NewAcc]),
    sort(firm, T, NewAcc).
	    
