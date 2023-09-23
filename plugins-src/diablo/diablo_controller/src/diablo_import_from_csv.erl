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

%% -import(diablo_import_from_gjp, [pack_date/1, parse_birth/2]).

-compile(export_all).

gen_charge(merchant, Merchant) ->
    {ok, Charge} = ?w_user_profile:get(charge, Merchant, 332),
    
    Sql = "select id, score, balance from w_retailer where merchant=" ++ ?to_s(Merchant)
	++ " and type=1"
	++ " and balance > 0",
    case ?sql_utils:execute(read, Sql) of
	{ok, []} -> [];
	{ok, Retailers} -> 
	    lists:foreach(
	      fun(R) ->
		      RetailerId = ?v(<<"id">>, R),
		      Balance = ?v(<<"balance">>, R),
		      Attrs = [{<<"shop">>, 325},
			       {<<"retailer">>, RetailerId},
			       {<<"employee">>, <<"00000001">>},
			       {<<"charge_balance">>, 0},
			       {<<"send_balance">>, Balance},
			       {<<"cash">>,0},
			       {<<"card">>,0},
			       {<<"wxin">>,0},
			       {<<"charge">>, 332}],
		      case ?w_retailer:retailer(last_recharge, Merchant, RetailerId) of
			  {ok, []} ->
			      ?w_retailer:charge(recharge, Merchant, {Attrs, Charge}),
			      Sql1 = "update w_retailer set balance=balance-" ++ ?to_s(Balance)
				  ++ " where merchant=" ++ ?to_s(Merchant)
				  ++ " and id=" ++ ?to_s(RetailerId),
			      ?sql_utils:execute(write, Sql1, ok);
			  {ok, _LastCharge} -> 
			      ok
		      end
	      end, Retailers)
    end.

delete(member_not_used, Merchant) ->
    Sql = "select id, merchant from w_retailer where merchant=" ++ ?to_s(Merchant),
    [_Total, Sqls] = 
	case ?sql_utils:execute(read, Sql) of
	    {ok, []} -> ok;
	    {ok, Members} ->
		lists:foldr(
		  fun({Member}, [Inc, Acc])->
			  Id = ?v(<<"id">>, Member),
			  Sql1 = "select rsn from" ++ ?table:t(sale_new, Merchant, 1)
			      ++ " where retailer=" ++ ?to_s(Id)
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
    {RName, Phone, Shop, Score, Consume, Balance, Birth, Date, ChangeDate} = H,
    ?DEBUG("H ~p", [H]),
    NewShop = case Shop of
		  <<>> -> 294;
		  _ -> Shop
	      end,
    NewScore = case Score of
		   <<>> -> 0;
		   _ -> round(?to_f(string:strip(?to_s(Score))))
	       end,

    NewConsume = case Consume of
		     <<>> -> 0;
		     _ -> round(?to_f(string:strip(?to_s(Consume))))
		 end,

    NewBalance = case Balance of
		     <<>> -> 0;
		     %% _ -> round(?to_f(string:strip(?to_s(Balance))))
		     _ -> 0
		 end,

    NewBirth = case Birth of
		  <<>> -> <<"0000-00-00">>;
		  %% _ -> <<"2017-", Birth/binary>>
		   _ ->
		       %% {BirthMonth, _BirthDate} = parse_birth(Birth, <<>>),
		       %% BirthDate = pack_date(_BirthDate),
		       %% ?DEBUG("BirthMonth ~p, BirthDate ~p", [BirthMonth, BirthDate]),
		       %% << <<"2018-">>/binary, BirthMonth/binary, <<"-">>/binary, BirthDate/binary>>
		       Birth
	      end,

    ?DEBUG("NewBirth ~p", [NewBirth]),

    IsExist = 
	case [ P || {_, P, _, _, _, _, _, _} <- Sort, P =:= Phone ] of
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

		    %% UName =
		    %% 	case RName of
		    %% 	    <<>> ->
		    %% 		<<_:6/binary, Name:5/binary>> = Phone,
		    %% 		Name;
		    %% 	    _ ->
		    %% 		case size(RName) =:= 3 of
		    %% 		    true ->
		    %% 			<<_:6/binary, Name:5/binary>> = Phone,
		    %% 			<<RName/binary, Name/binary>>;
		    %% 		    false ->
		    %% 			RName
		    %% 		end
				
		    %% 	end,

		    RegExp = "^[A-Za-z]",
		    UName = 
			case re:run(RName, RegExp) of
			    {match, _} ->
				<<_:6/binary, Name:5/binary>> = Phone,
				Name;
			    nomatch ->
				RName
			end,
			    
		    Entry = case Date of
				<<>> -> Datetime;
				_ -> case size(Date) == 10 of
					 true ->
					     ?to_s(Date) ++ " " ++ Time;
					 false ->
					     ?to_s(Date)
				     end
				%% _ ->?to_s(Date)
			    end,

		    NewChangeDate = case ChangeDate of
					<<>> -> Entry;
					_ -> ?to_s(ChangeDate)
				    end,

		    Sql = ["insert into w_retailer("
			   "name"
			   ", score"
			   ", consume"
			   ", balance"
			   ", mobile"
			   ", shop"
			   ", merchant"
			   ", type"
			   ", Birth"
			   ", change_date"
			   ", entry_date)"
			   
			   " values ("
			   ++ "\"" ++ ?to_s(UName) ++ "\","
			   ++ ?to_s(NewScore) ++ ","
			   ++ ?to_s(NewConsume) ++ ","
			   ++ ?to_s(NewBalance) ++ "," 
			   ++ "\"" ++ ?to_s(Phone) ++ "\","
			   ++ ?to_s(NewShop) ++ ","
			   ++ ?to_s(Merchant) ++ ","
			   ++ case ?to_f(Balance) > 0 of
			       true -> ?to_s(1);
			       false -> ?to_s(0)
			   end ++ ","
			   ++ "\"" ++ ?to_s(NewBirth) ++ "\","
			   ++ "\"" ++ ?to_s(NewChangeDate) ++ "\","
			   ++ "\"" ++ ?to_s(Entry) ++ "\")"],
		    insert_into_member(Merchant, Datetime, Time, T, [H|Sort], Sql ++ Acc);
		{ok, _R} ->
		    %% Sql = ["update w_retailer set score=score+" ++ ?to_s(NewScore)
		    %% 	   ++", consume=consume+" ++ ?to_s(NewConsume)
		    %% 	   ++ ", birth=\'" ++ ?to_s(Birth) ++ "\'"
		    %% 	       ++ " where id=" ++ ?to_s(?v(<<"id">>, _R))
		    %% 	   ++ " and merchant=" ++ ?to_s(Merchant)],

		    Entry = case Date of
				<<>> -> Datetime;
				%% _ -> ?to_s(Date) ++ " " ++ Time
				_ ->?to_s(Date)
			    end,
		    
		    Sql = ["update w_retailer set entry_date=\'" ++ ?to_s(Entry) ++ "\'"
			   ", score=score+" ++ ?to_s(NewScore)
			   ++", consume=consume+" ++ ?to_s(NewConsume)
			   ++ " where id=" ++ ?to_s(?v(<<"id">>, _R))
		    	   ++ " and merchant=" ++ ?to_s(Merchant)],

		    insert_into_member(Merchant, Datetime, Time, T, [H|Sort], Sql ++ Acc)
		    %% insert_into_member(Merchant, Datetime, Time, T, Sort, Acc)
		end
    end.

import_member_balance(recharge, Merchant, Shop, ChargeId, Path) ->
    ?INFO("current path ~p", [file:get_cwd()]), 
    {ok, Device} = file:open(Path, [read]),
    Content = read_line(Device, []),
    file:close(Device),
    
    insert_into_balance(recharge, Merchant, Shop, ChargeId, Content).

insert_into_balance(recharge, _Merchant, _Shop, _ChargeId, []) ->
    {ok, all};
insert_into_balance(recharge, Merchant, Shop, ChargeId, [H|T]) ->
    ?DEBUG("insert_int_balance: Charge ~p, H ~p", [H]),
    {_RName, Phone, _Shop, _Score, _Consume, Balance, _Birth, _Date, _ChangeDate} = H,
    Sql = "select id, mobile from w_retailer"
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and mobile=\'" ++ ?to_s(Phone) ++ "\'",
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> insert_into_balance(recharge, Merchant, Shop, ChargeId, T);
	{ok, RetailerInfo} ->
	    RoundBalnce = erlang:round(?to_f(Balance)),
	    case RoundBalnce > 0 of
		true ->
		    ChargeInfo = [{<<"retailer">>, ?v(<<"id">>, RetailerInfo)},
				  {<<"shop">>, Shop},
				  {<<"employee">>, <<"00000001">>},
				  {<<"card">>, erlang:round(?to_f(Balance))},
				  {<<"charge">>, ChargeId}],
		    %% ChargeRule = [{<<"rule_id">>, ?GIVING_CHARGE}],

		    case ?w_user_profile:get(charge, Merchant, ChargeId) of
			{ok, []} -> {error, charge_id_not_found};
			{ok, Charge} -> 
			    case ?w_retailer:charge(recharge, Merchant, {ChargeInfo, Charge}) of
				{ok, _ChargeResult} -> 
				    insert_into_balance(recharge, Merchant, Shop, ChargeId, T);
				Error ->
				    Error
			    end
		    end;
		false ->
		    insert_into_balance(recharge, Merchant, Shop, ChargeId, T)
	    end;
	Error ->
	    ?DEBUG("Error ~p", [Error])
    end.

import(firm, Merchant, Shop, Path) ->
    ?INFO("current path ~p", [file:get_cwd()]),
    %% {ok, Content} = file:read_file(Path), 
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    file:close(Device),
    insert_into_db(Merchant, Shop, Content, <<>>, []);

import(good, Merchant, Shop, Path) ->
    ?INFO("current path ~p", [file:get_cwd()]),
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    %% ?DEBUG("Content ~p", [Content]),
    file:close(Device),
    Datetime = ?utils:current_time(format_localtime),
    Sqls = insert_into_good(good, Merchant, Shop, Datetime, Content, []),
    ?DEBUG("all sqls ~p", [Sqls]).
%%
%% import from Guan Jia Po
%%
%% import(gjp, Merchant, Shop, Path) -> 
%%     ?INFO("current path ~p", [file:get_cwd()]),
%%     {ok, Device} = file:open(Path, [read]), 
%%     Content = read_line(Device, []),
%%     file:close(Device),
%%     insert_into_stock(from_gjp, Merchant, Shop, Content, <<>>, []).
    
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

insert_into_db(Merchant, Shop, [H|T], F, Content) ->
    {Firm, _SN, _BCode, _Brand, _Type, _YS, _TagPrice, _Discount, _Total, _Cost} = H,

    case F =:= Firm of
	true ->
	    insert_into_db(Merchant, Shop, T, F, Content ++ [H]);
	false ->
	    case Content of
		[] -> ok;
		_ ->
		    NewContent = sort(firm, Content, []),
		    new(Merchant, Shop, NewContent) 
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
    {_Firm, SN, BCode, Brand, Type, YS,
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
		       <<>> -> {ok, 1423};
		       _ -> case ?attr:type(new, Merchant, [{<<"name">>, Type}]) of
				{ok_exist, ExistTypeId} -> {ok, ExistTypeId};
				_NewType -> _NewType
			    end
		   end,
    {Year, CSeason} = 
	case YS of
	    <<>> -> {2019, 2};
	    <<"0">> -> {2019,2};
	    <<"1">> -> {2019,2};
	    _ ->
		try
		    <<_Year:4/binary, _CSeason/binary>> = YS,
		    {_Year, _CSeason}
		catch _:_ ->
			{2019, 2}
		end
    end,

    Season = case CSeason of
		 <<"年春">> -> 0;
		 <<"年夏">> -> 1;
		 <<"年秋">> -> 2;
		 <<"年冬">> -> 3;
		 _ -> 2
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
		["insert into w_inventory(rsn, bcode"
		 ", style_number, brand, type, sex, season, amount, year"
		 ", org_price, tag_price, ediscount, discount"
		 ", alarm_day, shop, merchant"
		 ", entry_date)"
		 " values("
		 ++ "\"" ++ ?to_s(-1) ++ "\","
		 ++ "\"" ++ ?to_s(BCode) ++ "\","
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
		 "(bcode, style_number, sex, color, year, season, type, size, s_group, free"
		 ", brand, firm, org_price, tag_price, ediscount, discount"
		 ", alarm_day, merchant, change_date, entry_date"
		 ") values("
		 ++ "\"" ++ ?to_s(BCode) ++ "\","
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
	    binary_to_float(float_to_binary(OrgPrice / TagPrice, [{decimals, 4}])) * 100.
    %% end.

sort(firm, [], Acc) ->
    Acc;
sort(firm, [H|T], Acc) ->
    {_Firm, SN, _BCode, Brand, _Type, _YS, _TagPrice, _Discount, Total, _Cost} = H,

    NewAcc = 
	case [ A || {_, SN2, _BCode2, Brand2, _, _, _, _, _, _} = A <- Acc, SN2 =:= SN, Brand2 =:= Brand] of
	    [] -> [H|Acc];
	    [{_, _, _, _, _, _, _, _, Total2, _}] = S ->
		%% NewC = [{_Firm, SN, Brand, _Type, _YS,
		%% 	 _TagPrice, _Discount, ?to_i(Total) + ?to_i(Total2), _Cost}],
		%% ?DEBUG("new c ~p", [NewC]),
		(Acc -- S)
		    ++ [{_Firm, SN, _BCode, Brand, _Type, _YS,
			 _TagPrice, _Discount, ?to_i(Total) + ?to_i(Total2), _Cost}]
	end,
    %% ?DEBUG("new acc ~p", [NewAcc]),
    sort(firm, T, NewAcc).

insert_into_good(good, _Merchant, _Shop, _Datetime, [], Sqls) ->
    Sqls;
insert_into_good(good, Merchant, Shop, Datetime, [H|T], Sqls) ->
    ?DEBUG("H~p", [H]),
    {Brand, SN, Color, Type, TagPrice, _Firm, _Num, _ShiftDate} = H,
    ?DEBUG("SN ~p", [SN]),
    %% get style_number, brand from sn
    {NewSN, NewBrand} = parse_style_number(SN, <<>>),
    ?DEBUG("NewSN ~p, NewBrand ~p", [NewSN,NewBrand]),

    {Year, Season, ShiftDate} =
    	case _ShiftDate of
    	    <<>> -> {2017, 2, Datetime};
    	    _ ->
		<<YY:4/binary, "-",  MM:2/binary, "-", _DD:2/binary>> = _ShiftDate,
		SS = 
		    case ?to_i(MM) of
			1 -> 0;
			2 -> 0;
			3 -> 0;
			4 -> 1;
			5 -> 1;
			6 -> 1;
			7 -> 2;
			8 -> 2;
			9 -> 2;
			10 -> 3;
			11 -> 3;
			12 -> 3
		    end,
		{YY, SS, <<_ShiftDate/binary, <<" 13:30:22">>/binary>>}
	end,
		

    case NewSN =:= <<>> of
	true ->
	    insert_into_good(good, Merchant, Shop, Datetime, T, Sqls);
	false ->
	    RealBrand = case NewBrand =:= <<>> of
			    true -> Brand;
			    false -> NewBrand
			end,
		
	    {ok, BrandId} = ?attr:brand(new, Merchant, [{<<"name">>, RealBrand}]),
	    %% {ok, TypeId} = ?attr:type(new, Merchant, Type),
	    {ok, TypeId} =
		case ?attr:type(new, Merchant, [{<<"name">>, Type},
						{<<"auto_barcode">>, 0}]) of
		    {ok, _TypeId} -> {ok, _TypeId};
		    {ok_exist, _TypeId} -> {ok, _TypeId};
		    _Error -> _Error 
		end,
	    
	    Sql00 = "select id, name from colors"
		" where name=" ++ "\"" ++ ?to_s(Color) ++ "\""
		" and merchant=" ++ ?to_s(Merchant),

	    {ok, ColorId} =
		case ?sql_utils:execute(s_read, Sql00) of
		    {ok, []} -> ?attr:color(
				   w_new,
				   Merchant,
				   [{<<"name">>, Color}, {<<"type">>, 1}]); 
		    {ok, R} ->
			{ok, ?v(<<"id">>, R)}
		end,

	    {SGroup, Sizes} = case type_like_trous(Type) of
			 true ->
			     %% 26, 27, 28...
			     {"150,151", "26,27,28,29,30,31,32,33,34,35,36"};
			 false ->
			     %% s, m, l...
			     {"75", "S,M,L,XL,2XL,3XL,4XL"}
		     end,
	    
	    Sql1 = "select id, style_number, brand, color, size from w_inventory_good"
		" where merchant=" ++ ?to_s(Merchant)
		++ " and style_number=\'" ++ ?to_s(NewSN) ++ "\'"
		++ " and brand=" ++ ?to_s(BrandId),

	    Sql10 = 
		case ?sql_utils:execute(s_read, Sql1) of
		    {ok, []} ->
			["insert into w_inventory_good"
			 "(style_number, sex, color, year, season, type, size, s_group, free"
			 ", brand, firm, org_price, tag_price, ediscount, discount"
			 ", alarm_day, merchant, change_date, entry_date"
			 ") values("
			 ++ "\"" ++ ?to_s(NewSN) ++ "\","
			 ++ ?to_s(0) ++ ","
			 ++ "\"" ++ ?to_s(ColorId) ++ "\","
			 ++ ?to_s(Year) ++ ","
			 ++ ?to_s(Season) ++ "," 
			 ++ ?to_s(TypeId) ++ ","
			 ++ "\"" ++ ?to_s(Sizes) ++ "\","
			 ++ "\"" ++ ?to_s(SGroup) ++ "\","
			 ++ ?to_s(1) ++ ","
			 ++ ?to_s(BrandId) ++ ","
			 ++ ?to_s(-1) ++ ","
			 ++ ?to_s(0) ++ ","
			 ++ ?to_s(TagPrice) ++ ","
			 ++ ?to_s(0) ++ ","
			 ++ ?to_s(100) ++ ","
			 ++ ?to_s(7) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(ShiftDate) ++ "\","
			 ++ "\"" ++ ?to_s(ShiftDate) ++ "\")"];
		    {ok, R1} ->
			?DEBUG("R1 ~p", [R1]),
			ExistColors = string:tokens(?to_s(?v(<<"color">>, R1)), ","),
			?DEBUG("ExistColors ~p, colorId ~p", [ExistColors, ColorId]),
			case lists:member(?to_s(ColorId), ExistColors) of
			    true -> [];
			    false ->
				["update w_inventory_good set color=\'"
				 ++ string:join(ExistColors, ",") ++ "," ++ ?to_s(ColorId) ++ "\'"
				 ++ "where id=" ++ ?to_s(?v(<<"id">>, R1))] 
			end
		end,
	    ?DEBUG("sql10 ~p", [Sql10]),
	    ?sql_utils:execute(transaction, Sql10, Merchant),
	    insert_into_good(good, Merchant, Shop, Datetime, T, Sql10 ++ Sqls)
    end.

%% --------------------------------------------------------------------------------
%% import with color and size
%% 1: import good first
%% 2: import stock next
%% --------------------------------------------------------------------------------
import_good_nj(Merchant, Shop, UTable, Path) ->
    ?INFO("current path ~p", [file:get_cwd()]),
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    %% ?DEBUG("Content ~p", [Content]),
    file:close(Device),
    Datetime = ?utils:current_time(format_localtime),
    Sqls = import_good_nj(Merchant, Shop, UTable, Datetime, Content, []),
    ?DEBUG("all sqls ~p", [Sqls]).

import_good_nj(_Merchant, _Shop, _UTable,  _Datetime, [], Sqls) ->
    Sqls;
import_good_nj(Merchant, Shop, UTable, Datetime, [H|T], Sqls) ->
    ?DEBUG("H~p", [H]),
    %% {StyleNumber, Type, ColorName, SizeName, _SmallSizeName, _Amount, Year, Season, TagPrice, _BigClass} = H,
    {StyleNumber, Type, ColorName, SizeName, _Amount, Year, Season, OrgPrice, TagPrice} = H,
    %% ?DEBUG("StyleNumber ~p", [StyleNumber]),
    %% get style_number, brand from sn
    %% {NewSN, NewBrand} = parse_style_number(SN, <<>>), 
    %% {Year, Season, FirstShiftDate} =
    %% 	case ShiftDate of
    %% 	    <<>> -> {2019, 12, Datetime};
    %% 	    _ ->
    %% 		<<YY:4/binary, "-",  MM:2/binary, "-", _DD:2/binary>> = ShiftDate,
    %% 		SS = 
    %% 		    case ?to_i(MM) of
    %% 			1 -> 0;
    %% 			2 -> 0;
    %% 			3 -> 0;
    %% 			4 -> 1;
    %% 			5 -> 1;
    %% 			6 -> 1;
    %% 			7 -> 2;
    %% 			8 -> 2;
    %% 			9 -> 2;
    %% 			10 -> 3;
    %% 			11 -> 3;
    %% 			12 -> 3
    %% 		    end,
    %% 		{YY, SS, <<ShiftDate/binary, <<" 13:30:22">>/binary>>}
    %% 	end,

    FirstShiftDate = Datetime,
    %% NewSizeName = case SizeName of
    %% 		      <<"220">> -> 34;
    %% 		      <<"225">> -> 35;
    %% 		      <<"230">> -> 36;
    %% 		      <<"235">> -> 37;
    %% 		      <<"240">> -> 38;
    %% 		      <<"245">> -> 39;
    %% 		      <<"250">> -> 40;
    %% 		      <<"255">> -> 41;
    %% 		      <<"260">> -> 42;
    %% 		      <<"265">> -> 43;
    %% 		      <<"270">> -> 44;
    %% 		      _ -> SizeName
    %% 		  end,
    NewSizeName = SizeName,
    ?DEBUG("NewSizeName ~p", [NewSizeName]),

    NYear = case Year of
		<<>> -> 2023;
		_ -> Year
	    end,

    NSeason = case Season of
		  <<"春">> -> 0;
		  <<"夏">> -> 1;
		  <<"秋">> -> 2;
		  <<"冬">> -> 3
	      end,

    NTagPrice = case TagPrice of
		    <<>> -> 0;
		    _ -> TagPrice
		end,

    case StyleNumber =:= <<>> of
	true ->
	    import_good_nj(Merchant, Shop, UTable, Datetime, T, Sqls);
	false ->
	    %% RealBrand = case NewBrand =:= <<>> of
	    %% 		    true -> <<"鬼洗">>;
	    %% 		    false -> NewBrand
	    %% 		end, 
	    RealBrand = <<"名思图">>, 
	    {ok, BrandId} = ?attr:brand(new, Merchant, [{<<"name">>, RealBrand}]),
	    %% {ok, TypeId} = ?attr:type(new, Merchant, Type),
	    {ok, TypeId} =
		case ?attr:type(new, Merchant, [{<<"name">>, Type},
						{<<"auto_barcode">>, 0}]) of
		    {ok, _TypeId} -> {ok, _TypeId};
		    {ok_exist, _TypeId} -> {ok, _TypeId};
		    _Error -> _Error 
		end,

	    Sql00 = "select id, name from colors"
		" where name=" ++ "\'" ++ ?to_s(ColorName) ++ "\'"
		" and merchant=" ++ ?to_s(Merchant),

	    {ok, ColorId} =
		case ColorName =:= <<>> of
		    true -> {ok, 0};
		    false ->
			case ?sql_utils:execute(s_read, Sql00) of
			    {ok, []} -> ?attr:color(
					   w_new,
					   Merchant,
					   [{<<"name">>, ColorName},
					    {<<"type">>, 1},
					    {<<"auto_barcode">>, ?NO}]); 
			    {ok, R} ->
				{ok, ?v(<<"id">>, R)}
			end
		end,

	    %% get valid size group
	    {[SelectGroup], SizesInGroup} = 
		case NewSizeName =:= <<"F">> orelse NewSizeName =:= <<>> of
		    true -> {["0"], ["0"]};
		    false ->
			{ok, AllSizeGroup} = ?w_user_profile:get(size_group, Merchant), 
			case get_size_group(
			       by_name, correct_size_name(NewSizeName), AllSizeGroup, [], []) of
			    {[], _} -> {-1, []};
			    Any -> Any
			end
		end,
	    ?DEBUG("SelectGroup ~p, SizesInGroup ~p", [SelectGroup, SizesInGroup]), 

	    Sql1 = "select id, style_number, brand, color, size, s_group"
		" from"
		%% " w_inventory_good"
		++ ?table:t(good, Merchant, UTable)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		++ " and brand=" ++ ?to_s(BrandId),

	    Sql10 = 
		case ?sql_utils:execute(s_read, Sql1) of
		    {ok, []} ->
			["insert into"
			 ++ ?table:t(good, Merchant, UTable)
			 ++ "(bcode, style_number, sex, color, year, season, type, size, s_group, free"
			 ", brand, firm, org_price, tag_price, ediscount, discount"
			 ", alarm_day, merchant, change_date, entry_date"
			 ") values("
			 ++ "\'" ++ ?to_s(-1) ++ "\',"
			 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
			 ++ ?to_s(0) ++ ","
			 ++ "\"" ++ ?to_s(ColorId) ++ "\","
			 ++ ?to_s(NYear) ++ ","
			 ++ ?to_s(NSeason) ++ "," 
			 ++ ?to_s(TypeId) ++ ","
			 ++ "\'" ++ ?to_s(string:join(SizesInGroup, ",")) ++ "\',"
			 ++ "\'" ++ ?to_s(SelectGroup) ++ "\',"
			 ++ case ?to_s(ColorId) =:= "0" andalso ?to_s(SelectGroup) =:= "0" of
			     true -> ?to_s(0);
			     false -> ?to_s(1)
			 end ++ ","
			 ++ ?to_s(BrandId) ++ ","
			 ++ ?to_s(-1) ++ ","
			 ++ ?to_s(OrgPrice) ++ ","
			 ++ ?to_s(NTagPrice) ++ ","
			 ++ ?to_s(0) ++ ","
			 ++ ?to_s(100) ++ ","
			 ++ ?to_s(7) ++ ","
			 ++ ?to_s(Merchant) ++ ","
			 ++ "\"" ++ ?to_s(FirstShiftDate) ++ "\","
			 ++ "\"" ++ ?to_s(FirstShiftDate) ++ "\")"];
		    {ok, R1} ->
			?DEBUG("R1 ~p", [R1]),
			ExistColors = string:tokens(?to_s(?v(<<"color">>, R1)), ","),
			?DEBUG("ExistColors ~p, colorId ~p", [ExistColors, ColorId]),
			AddColors = 
			    case lists:member(?to_s(ColorId), ExistColors) of
				true -> [];
				false ->
				    string:join(ExistColors, ",") ++ "," ++ ?to_s(ColorId) 
			    end,
			?DEBUG("AddColors ~p", [AddColors]),
			
			ExistSizeGroup = string:tokens(?to_s(?v(<<"s_group">>, R1)), ","),
			?DEBUG("ExistSizeGroup ~p, SelectGroup ~p", [ExistSizeGroup, SelectGroup]),
			{NewGroups, NewSizes} =
			    case lists:member(?to_s(SelectGroup), ExistSizeGroup) of
				true -> {[], []};
				false -> 
				    AddGroups = string:join(ExistSizeGroup, ",")
					++ "," ++ ?to_s(SelectGroup),
				    ExistSizes = string:tokens(?to_s(?v(<<"size">>, R1)), ","),
				    %% ?DEBUG("SizesInGroup ~p, ExistSizes ~p", [SizesInGroup, ExistSizes]),
				    
				    AddSizes = 
					 lists:foldr(
					   fun(S, Acc) ->
						   case lists:member(S, ExistSizes) of
						       true -> Acc;
						       false -> [S | Acc]
						   end 
					   end, [], SizesInGroup),

				    %% ?DEBUG("AddSize ~p", [AddSizes]),
				    
				    {AddGroups, string:join(ExistSizes, ",") ++
					 case AddSizes of
					     [] -> [];
					     _ -> "," ++ string:join(AddSizes, ",")
					 end}
				    
			    end,

			?DEBUG("NewGroups ~p, NewSizes ~p, AddColors ~p",
			       [NewGroups, NewSizes, AddColors]), 
			%% ["update w_inventory_good set merchant=" ++ ?to_s(Merchant)
			["update"
			 ++ ?table:t(good, Merchant, UTable)
			 ++ " set merchant=" ++ ?to_s(Merchant)
			 ++ case AddColors of
				[] -> [];
				_ ->
				    ", color=\'" ++ ?to_s(AddColors) ++ "\'"
			    end
			 ++ case NewGroups of
				[] -> [];
				_ -> ", size=\'" ++ ?to_s(NewSizes) ++ "\'"
					 ++ ", s_group=\'" ++ ?to_s(NewGroups) ++ "\'"
			    end
			++ " where id=" ++ ?to_s(?v(<<"id">>, R1))] 
		end,
	    ?DEBUG("sql10 ~p", [Sql10]),
	    ?sql_utils:execute(transaction, Sql10, Merchant),
	    import_good_nj(Merchant, Shop, UTable, Datetime, T, Sql10 ++ Sqls)
    end.

%% ================================================================================
%% import stock with color and size
%% ================================================================================
import_stock_nj(Merchant, Shop, UTable, Path) ->
    ?INFO("current path ~p", [file:get_cwd()]),
    %% {ok, Content} = file:read_file(Path), 
    {ok, Device} = file:open(Path, [read]), 
    Content = read_line(Device, []),
    file:close(Device),
    import_stock_nj(Merchant, Shop, UTable, Content, <<>>, [], 0).

import_stock_nj(Merchant, Shop, UTable, [], _F, Content, _Count) ->
    case Content of
	[] -> ok;
	_ -> new_nj(Merchant, Shop, UTable, Content)
    end;
import_stock_nj(Merchant, Shop, UTable, [H|T], F, Content, Count) ->
    %% {StyleNumber, _Type, ColorName, SizeName, _SmallSizeName, Stock, _Year, _Season, _TagPrice, _BigClass} = H,
    {StyleNumber, _Type, ColorName, SizeName,  Stock, _Year, _Season, _OrgPrice, _TagPrice} = H,
    case ?to_i(Stock) =< 0 of
	true ->
	    import_stock_nj(Merchant, Shop, UTable, T, F, Content, Count);
	false ->
	    
	    RealBrand = <<"名思图">>,
	    {ok, BrandId} = ?attr:brand(new, Merchant, [{<<"name">>, RealBrand}]),

	    %% NewSizeName = case SizeName of
	    %% 		      <<"220">> -> 34;
	    %% 		      <<"225">> -> 35;
	    %% 		      <<"230">> -> 36;
	    %% 		      <<"235">> -> 37;
	    %% 		      <<"240">> -> 38;
	    %% 		      <<"245">> -> 39;
	    %% 		      <<"250">> -> 40;
	    %% 		      <<"255">> -> 41;
	    %% 		      <<"260">> -> 42;
	    %% 		      <<"265">> -> 43;
	    %% 		      <<"270">> -> 44;
	    %% 		      _ -> SizeName
	    %% 		  end,
	    
	    NewSizeName = SizeName,
	    ?DEBUG("NewSizeName ~p", [NewSizeName]),

	    Sql00 = 
		"select id"
		", bcode"
		", style_number"
		", brand"
		", firm"
		", s_group"
		", type"
		", sex"
		", season"
		", year"
		", free"
		", org_price"
		", tag_price"
		", discount" 
		", ediscount"

		%% " from w_inventory_good"
		" from " ++ ?table:t(good, Merchant, UTable)
		++ " where merchant=" ++ ?to_s(Merchant)
		++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
		++ " and brand=" ++ ?to_s(BrandId),
	    case ?sql_utils:execute(s_read, Sql00) of
		{ok, []} -> import_stock_nj(Merchant, Shop, UTable, T, F, Content, Count);
		{ok, Good} ->
		    SqlColor = "select id, name from colors"
			" where merchant=" ++ ?to_s(Merchant)
			++ " and name=\'" ++ ?to_s(ColorName) ++ "\'",
		    {ok, Color} = ?sql_utils:execute(s_read, SqlColor), 
		    StockInfo = {[{<<"color">>, ?v(<<"id">>, Color)},
				  {<<"size">>, correct_size_name(NewSizeName)},
				  {<<"stock">>, Stock}] ++ Good},
		    ?DEBUG("Count ~p", [Count]),
		    case F =:= ?v(<<"firm">>, Good) andalso Count < 100 of
			true -> 
			    import_stock_nj(
			      Merchant,
			      Shop,
			      UTable,
			      T,
			      F,
			      Content ++ [StockInfo], Count + 1);
			false ->
			    case Content of
				[] -> ok;
				_ ->
				    %% NewContent = sort_nj(firm, Content, []),
				    new_nj(Merchant, Shop, UTable, Content) 
			    end,
			    import_stock_nj(Merchant, Shop, UTable, T, ?v(<<"firm">>, Good), [StockInfo], 1)
		    end
	    end
    end.

new_nj(Merchant, Shop, UTable, Content) ->
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
    stock_new_nj(Content, RSN, EmployeeId, Merchant, Shop, UTable, Datetime).

stock_new_nj([], RSN, _Employee, _Merchant, _Shop, _UTable, _Datetime) ->
    {ok, RSN};
stock_new_nj([{H}|T], RSN, Employee, Merchant, Shop, UTable, Datetime) ->
    ?DEBUG("H ~p", [H]),
    BCode = ?v(<<"bcode">>, H),
    StyleNumber = ?v(<<"style_number">>, H),
    BrandId   = ?v(<<"brand">>, H),
    TypeId    = ?v(<<"type">>, H),
    Sex       = ?v(<<"sex">>, H),
    Season    = ?v(<<"season">>, H),
    Stock     = ?v(<<"stock">>, H),
    Year      = ?v(<<"year">>, H),
    SizeGroup = ?v(<<"s_group">>, H),
    Free      = ?v(<<"free">>, H),
    
    OrgPrice = ?v(<<"org_price">>, H),
    TagPrice = ?v(<<"tag_price">>, H),
    Discount = ?v(<<"discount">>, H),
    EDiscount = ?v(<<"ediscount">>, H),

    Color   = ?v(<<"color">>, H),
    Size    = ?v(<<"size">>, H),


    Sql0 = "select id, style_number, brand"
	%% " from w_inventory"
	" from" ++ ?table:t(stock, Merchant, UTable)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId)
    %% ++ " and color=" ++ ?to_s(Color)
    %% ++ " and size=" ++ "\"" ++ ?to_s(Size) ++ "\""
	++ " and shop=" ++ ?to_s(Shop),
    Sql1 = 
	case ?sql_utils:execute(s_read, Sql0) of
	    {ok, []} ->
		["insert into"
		 %% " w_inventory"
		 ++ ?table:t(stock, Merchant, UTable)
		 ++ "(bcode"
		 ", style_number"
		 ", brand"
		 ", type"
		 ", sex"
		 ", season"
		 ", amount"
		 ", year"
		 ", s_group"
		 ", free"

		 ", org_price"
		 ", tag_price"
		 ", discount"
		 ", ediscount" 

		 ", alarm_day"
		 ", shop"
		 ", merchant"
		 ", entry_date)"
		 " values("
		 ++ "\'" ++ ?to_s(BCode) ++ "\',"
		 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
		 ++ ?to_s(BrandId) ++ ","
		 ++ ?to_s(TypeId) ++ ","
		 ++ ?to_s(Sex) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Stock) ++ ","
		 ++ ?to_s(Year) ++ ","
		 ++ "\'" ++ ?to_s(SizeGroup) ++ "\',"
		 ++ ?to_s(Free) ++ ","

		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(Discount) ++ ","
		 ++ ?to_s(EDiscount) ++ ","

		 ++ ?to_s(7) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"]; 
	    {ok, R} ->
		["update"
		 %% " w_inventory"
		 ++ ?table:t(stock, Merchant, UTable)
		 ++ " set amount=amount+" ++ ?to_s(Stock) 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R))]; 
	    {error, Error} ->
		throw({db_error, Error})
	end,


    Sql20 = "select id, rsn, style_number, brand"
	%% " from w_inventory_new_detail"
	" from "
	++ ?table:t(stock_new_detail, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(BrandId),

    Sql2 = 
	case ?sql_utils:execute(s_read, Sql20) of
	    {ok, []} ->
		["insert into"
		 %% " w_inventory_new_detail"
		 ++ ?table:t(stock_new_detail, Merchant, UTable)
		 ++ "(rsn, style_number"
		 ", brand, type, sex, season, amount"
		 ", year, s_group, free"
		 ", org_price, tag_price, ediscount, discount"
		 ", merchant, shop, entry_date) values("
		 ++ "\'" ++ ?to_s(RSN) ++ "\',"
		 ++ "\'" ++ ?to_s(StyleNumber) ++ "\',"
		 ++ ?to_s(BrandId) ++ ","
		 ++ ?to_s(TypeId) ++ ","
		 ++ ?to_s(0) ++ ","
		 ++ ?to_s(Season) ++ ","
		 ++ ?to_s(Stock) ++ "," 
		 ++ ?to_s(Year) ++ ","
		 ++ "\'" ++ ?to_s(SizeGroup) ++ "\',"
		 ++ ?to_s(Free) ++ ","

		 ++ ?to_s(OrgPrice) ++ ","
		 ++ ?to_s(TagPrice) ++ ","
		 ++ ?to_s(EDiscount) ++ ","
		 ++ ?to_s(Discount) ++ ","

		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(Shop) ++ ","
		 ++ "\"" ++ ?to_s(Datetime) ++ "\")"];
	    {ok, R20} ->
		["update"
		 %% " w_inventory_new_detail"
		 ++ ?table:t(stock_new_detail, Merchant, UTable)
		 ++ " set amount=amount+" ++ ?to_s(Stock) 
		 ++ ", entry_date=" ++ "\"" ++ ?to_s(Datetime) ++ "\"" 
		 ++ " where id=" ++ ?to_s(?v(<<"id">>, R20))];
	    {error, Error20} ->
		throw({db_error, Error20})
	end,

    
    Sql00 = "select id, style_number, brand, color, size"
	" from "
	%% "w_inventory_amount"
	++ ?table:t(stock_note, Merchant, UTable)
	++ " where style_number=\'" ++ ?to_s(StyleNumber) ++ "\'"
	++ " and brand=" ++ ?to_s(BrandId)
	++ " and color=" ++ ?to_s(Color)
	++ " and size=\'" ++ ?to_s(Size) ++ "\'"
	++ " and shop=" ++ ?to_s(Shop)
	++ " and merchant=" ++ ?to_s(Merchant),

    Sql01 =
	"select id, style_number, brand, color, size"
	%% " from w_inventory_new_detail_amount"
	" from"
	++ ?table:t(stock_new_note, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and style_number=\"" ++ ?to_s(StyleNumber) ++ "\""
	++ " and brand=" ++ ?to_s(BrandId)
	++ " and color=" ++ ?to_s(Color)
	++ " and size=\'" ++ ?to_s(Size) ++ "\'", 
    %% ++ " and shop=" ++ ?to_s(Shop)
    %% ++ " and merchant=" ++ ?to_s(Merchant),
    Sql3 = 
	[case ?sql_utils:execute(s_read, Sql00) of
	     {ok, []} ->
		 "insert into"
		     %% " w_inventory_amount"
		     ++ ?table:t(stock_note, Merchant, UTable)
		     ++ "(rsn"
		     ", style_number, brand, color, size"
		     ", shop, merchant, total, entry_date)"
		     " values("
		     ++ "\"" ++ ?to_s(-1) ++ "\","
		     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		     ++ ?to_s(BrandId) ++ ","
		     ++ ?to_s(Color) ++ ","
		     ++ "\'" ++ ?to_s(Size)  ++ "\',"
		     ++ ?to_s(Shop)  ++ ","
		     ++ ?to_s(Merchant) ++ ","
		     ++ ?to_s(Stock) ++ "," 
		     ++ "\"" ++ ?to_s(Datetime) ++ "\")"; 
	     {ok, R00} ->
		 "update"
		     %% " w_inventory_amount"
		     ++ ?table:t(stock_note, Merchant, UTable)
		     ++" set total=total+" ++ ?to_s(Stock) 
		     ++ " where id=" ++ ?to_s(?v(<<"id">>, R00));
	     {error, E00} ->
		 throw({db_error, E00})
	 end,

	 case ?sql_utils:execute(s_read, Sql01) of
	     {ok, []} ->
		 "insert into"
		     %% " w_inventory_new_detail_amount"
		     ++ ?table:t(stock_new_note, Merchant, UTable)
		     ++ "(rsn"
		     ", style_number, brand, color, size"
		     ", total, merchant, shop, entry_date) values("
		     ++ "\"" ++ ?to_s(RSN) ++ "\","
		     ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
		     ++ ?to_s(BrandId) ++ ","
		     ++ ?to_s(Color) ++ ","
		     ++ "\'" ++ ?to_s(Size)  ++ "\',"
		     ++ ?to_s(Stock) ++ ","
		     ++ ?to_s(Merchant) ++ ","
		     ++ ?to_s(Shop) ++ "," 
		     ++ "\"" ++ ?to_s(Datetime) ++ "\")";
	     {ok, R01} ->
		 "update"
		     %% " w_inventory_new_detail_amount"
		     ++ ?table:t(stock_new_note, Merchant, UTable)
		     ++ " set total=total+" ++ ?to_s(Stock)
		     ++ ", entry_date=\'" ++ ?to_s(Datetime) ++ "\'"
		     ++ " where id=" ++ ?to_s(?v(<<"id">>, R01));
	     {error, E00} ->
		 throw({db_error, E00})
	 end],

    Sql02 = "select rsn, merchant, shop from"
	%% " w_inventory_new"
	++ ?table:t(stock_new, Merchant, UTable)
	++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
	++ " and merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop),

    Sql4 = 
	case ?sql_utils:execute(s_read, Sql02) of
	    {ok, []} ->
		["insert into"
		 %% "w_inventory_new"
		 ++ ?table:t(stock_new, Merchant, UTable)
		 ++ "(rsn, employ, shop, merchant, should_pay, total, type, entry_date) values("
		 ++ "\'" ++ ?to_s(RSN) ++ "\',"
		 ++ "\'" ++ ?to_s(Employee) ++ "\',"
		 ++ ?to_s(Shop) ++ ","
		 ++ ?to_s(Merchant) ++ ","
		 ++ ?to_s(OrgPrice * ?to_i(Stock)) ++ ","
		 ++ ?to_s(Stock) ++ ","
		 ++ ?to_s(0) ++ ","
		 ++ "\'" ++ ?to_s(Datetime) ++ "\')"];
	    {ok, _StockNew} ->
		["update"
		 %% " w_inventory_new"
		 ++ ?table:t(stock_new, Merchant, UTable)
		 ++ " set total=total+" ++ ?to_s(Stock)
		 ++ ", should_pay=should_pay+" ++ ?to_s(OrgPrice * ?to_i(Stock))
		 ++ " where rsn=\'" ++ ?to_s(RSN) ++ "\'"
		 ++ " and merchant=" ++ ?to_s(Merchant)]
	end,

    AllSql = Sql1 ++ Sql2 ++ Sql3 ++ Sql4,
    {ok, RSN} = ?sql_utils:execute(transaction, AllSql, RSN),
    %% ?DEBUG("Allsql ~p", [AllSql]),
    stock_new_nj(T, RSN, Employee, Merchant, Shop, UTable, Datetime).
		    
parse_style_number(<<>>, SN)->
    {SN, <<>>};
parse_style_number(<<H, T/binary>>, SN) when H > 127 ->
    {SN, <<H, T/binary>>};
parse_style_number(<<H, T/binary>>, SN)->
    parse_style_number(T, <<SN/binary, H>>).


type_like_trous(FullType) ->
    T1 = << <<T1>> || <<T1>> <= FullType, <<T1>> =:= <<232>> >>,
    T2 = << <<T2>> || <<T2>> <= FullType, <<T2>> =:= <<163>> >>,
    T3 = << <<T3>> || <<T3>> <= FullType, <<T3>> =:= <<164>> >>,
    ?DEBUG("T1 ~p, T2 ~p, T3 ~p", [T1,T2,T3]),
    T1 =/= <<>> andalso T2 =/= <<>> andalso T3 =/= <<>>.

correct_size_name(Name) ->
    case ?to_b(Name) =:= <<"XXL">> of
	true -> <<"2XL">>;
	false -> ?to_b(Name)
    end.
	    
get_size_group(by_name, _SizeName, [], Acc1, Acc2) ->
    {Acc1, Acc2};
get_size_group(by_name, SizeName, [H|T], Acc1, Acc2) ->
    ?DEBUG("SizeName ~p, H ~p", [SizeName, H]),
    GroupId = ?v(<<"id">>, H),
    SI   = ?v(<<"si">>, H),
    SII  = ?v(<<"sii">>, H),
    SIII = ?v(<<"siii">>, H),
    SIV  = ?v(<<"siv">>, H),
    SV   = ?v(<<"sv">>, H),
    SVI  = ?v(<<"svi">>, H),
    SVII = ?v(<<"svii">>, H),

    case SI =:= SizeName
	orelse SII  =:= SizeName
	orelse SIII =:= SizeName
	orelse SIV  =:= SizeName
	orelse SV   =:= SizeName
	orelse SVI  =:= SizeName
	orelse SVII =:= SizeName
    of
	true -> 
	    get_size_group(
	      by_name,
	      SizeName,
	      [],
	      [?to_s(GroupId)|Acc1],
	      format_size_group([SI, SII, SIII, SIV, SV, SVI, SVII], []) ++ Acc2);
	false ->
	    get_size_group(by_name, SizeName, T, Acc1, Acc2)
    end.

format_size_group([], Acc) ->
    lists:reverse(Acc);
format_size_group([H|T], Acc) ->
    case H =:= [] orelse H =:= <<>> of
	true -> Acc;
	false -> format_size_group(T, [?to_s(H)|Acc])
    end.
		    

    
	 
	    
