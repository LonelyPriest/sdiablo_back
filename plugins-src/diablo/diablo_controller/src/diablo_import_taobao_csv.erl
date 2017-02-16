%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2017, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 15 Feb 2017 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_import_taobao_csv).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

parse_data(taobao_csv, {Merchant, Shop, Employee, Retailer}, CSVData, Colors, Sizes) ->
    %% [{TaoBaoSN, StyleNumber, Price, Total, Color, Size}, {...}]
    Stocks = parse_data(by_line, CSVData, <<>>, []), 
    %% ?DEBUG("Stocks ~p", [Stocks]), 
    %% sort with style_number and brand
    Sort = sort(stock, Stocks, Colors, Sizes, []),
    ?DEBUG("sort stock ~p", [Sort]), 
    case check_amount(stock, Sort, 0, 0) of
	{ok, {_Total, _ShouldPay}} ->
	    Datetime = ?utils:current_time(format_localtime),
	    try
		Sqls = insert_db(stock, {Merchant, Shop, Employee, Retailer, Datetime}, Sort, []),
		?DEBUG("all sqls ~n~p", [Sqls]),
		Sqls
	    catch _:Error ->
		    ?DEBUG("error ~p, ~p", [Error, erlang:get_stacktrace()]),
		    Error
	    end;
	Error ->
	    ?DEBUG("error ~p", [Error]),
	    Error
    end.

%% get one line from data
parse_data(by_line, <<>>, _Line, Contents) ->
    Contents;
parse_data(by_line, <<"\n", T/binary>>, Line, Contents) ->
    case Line =:= [] of
	true -> parse_data(by_line, T, <<>>, Contents);
	false ->
	    case string:strip(?to_s(Line), both, $\r) of
		[] -> parse_data(by_line, T, <<>>, Contents);
		[H1,H2,H3|StripLine] ->
		    case [H1,H2,H3] =:= "\"=\"" of
			true ->
			    %% ?DEBUG("strip line ~ts", [?to_b(StripLine)]),
			    LineData = parse_line(StripLine),
			    %% ?DEBUG("lineData ~p", [LineData]),
			    [TaoBaoSn, _Title, Price, Total, _Code, Attr, _Info, _Comment, _State, StyleNumber|_T]
				= LineData, 
			    %% ?DEBUG("Price ~p, Total ~p, Attr ~ts, StyleNumber ~p", [Price, Total, Attr, StyleNumber]),
			    case StyleNumber of
				<<>> -> parse_data(by_line, T, <<>>, Contents);
				_ ->
				    {Color, Size} = parse_size_and_color(from_attr, Attr),
				    parse_data(by_line, T, <<>>,
					       [{TaoBaoSn, StyleNumber, Price, Total, Color, Size}|Contents])
			    end;
			false ->
			    parse_data(by_line, T, <<>>, Contents)
		    end
	    end
    end;

parse_data(by_line, <<H, T/binary>>, Line, Contents) ->
    parse_data(by_line, T, <<Line/binary, H>>, Contents).

parse_line(Line) when is_binary(Line) ->
    parse_line(Line, <<>>, []);
parse_line(Line) ->
    parse_line(?to_b(Line), <<>>, []).

parse_line(<<>>, F, Contents) ->
    C = string:strip(?to_s(F), both, $\n), 
    Contents ++ [?to_b(C)];
parse_line(<<",", T/binary>>, F, Contents) ->
    parse_line(T, <<>>, Contents ++ [F]);
parse_line(<<H, T/binary>>, F, Contents) ->
    parse_line(T, <<F/binary, H>>, Contents).

parse_size_and_color(from_attr, Attr) ->
    [ColorInfo, SizeInfo] = parse_size_and_color(Attr, <<>>, []),
    %% ?DEBUG("color info ~ts, size info ~ts", [ColorInfo, SizeInfo]),
    Color = parse_color(ColorInfo, <<>>, []),
    Size = parse_color(SizeInfo, <<>>, []),
    PSize = parse_size(Size, <<>>), 
    %% ?DEBUG("color ~ts, size ~ts", [Color, PSize]),
    {Color, PSize}.


parse_size_and_color(<<>>, F, Contents) ->
    Contents ++ [F];
parse_size_and_color(<<";", T/binary>>, F, Contents) ->
    parse_size_and_color(T, <<>>, Contents ++ [F]);
parse_size_and_color(<<H, T/binary>>, F, Contents) ->
    parse_size_and_color(T, <<F/binary, H>>, Contents).

parse_color(<<>>, F, _Contents) ->
    F;
parse_color(<<"：", T/binary>>, F, Contents) ->
    parse_color(T, <<>>, Contents ++ [F]);
parse_color(<<":", T/binary>>, F, Contents) ->
    parse_color(T, <<>>, Contents ++ [F]);
parse_color(<<H, T/binary>>, F, Contents) ->
    case H =:= <<>> of
    	true ->
    	    parse_color(T, <<F/binary>>, Contents);
    	false ->
    	    parse_color(T, <<F/binary, H>>, Contents)
    end.

parse_size(<<>>, F) ->
    ?to_b(string:strip(?to_s(F)));
parse_size(<<"/", _T/binary>>, F) ->
    parse_size(<<>>, F);
parse_size(<<"（", _T/binary>>, F) ->
    parse_size(<<>>, F);
parse_size(<<"(", _T/binary>>, F) ->
    parse_size(<<>>, F);
parse_size(<<"[", _T/binary>>, F) ->
    parse_size(<<>>, F);
parse_size(<<" ", _T/binary>>, F) ->
    parse_size(<<>>, F); 
parse_size(<<H, T/binary>>, F) ->
    case H =:= <<>> of
    	true ->
    	    parse_size(T, <<F/binary>>);
    	false ->
    	    parse_size(T, <<F/binary, H>>)
    end.

sort(stock, [], _Colors, _sizes, Acc) ->
    Acc;
sort(stock, [H|T], Colors, _Sizes, Acc) ->
    %% ?DEBUG("H ~p, Acc ~p", [H, Acc]),
    {_TaoBaoSn, StyleNumber, Price, Total, Color, Size} = H,
    ColorId = get_color_id(by_name, Color, Colors),

    %% NewAcc = [{StyleNumber, Price, ?to_i(Total), [{ColorId, Size, Total}]}|Acc],
    NewAcc = 
    	case [A || {StyleNumber2, _, _, _} = A <- Acc, StyleNumber2 =:= StyleNumber] of
    	    [] ->
    		[{StyleNumber, Price, ?to_i(Total), [{ColorId, Size, ?to_i(Total)}]}|Acc];
    	    [{_, _, Total2, C}] = _S ->
    		%% ?DEBUG("S ~p", [S]), 
    		Combined = combine_stock(by_color_size, C, {ColorId, Size, ?to_i(Total)}, false, []),
		%% ?DEBUG("combined ~p", [Combined]),
	    [A || {StyleNumber2, _, _, _} = A <- Acc, StyleNumber2 =/= StyleNumber]
    		    ++ [{StyleNumber, Price, ?to_i(Total2) + ?to_i(Total), Combined}]
    	end,
    %% ?DEBUG("new acc ~p", [NewAcc]),
    sort(stock, T, Colors, _Sizes, NewAcc).

combine_stock(by_color_size, [], New, Found, Acc) ->
    case Found of
	true-> Acc;
	false -> [New|Acc]
    end;
combine_stock(by_color_size, [{ColorId, Size, Total}=H|T], {ColorIdNew, SizeNew, TotalNew}, Found, Acc) ->
    %% ?DEBUG("H ~p, New ~p", [H, New]),
    case ColorIdNew =:= ColorId andalso SizeNew =:= Size of
	true ->
	    combine_stock(by_color_size, T, {ColorIdNew, SizeNew, TotalNew}, true,
			  [{ColorId, Size, ?to_i(TotalNew) + ?to_i(Total)}|Acc]);
	false -> 
	    combine_stock(by_color_size, T, {ColorIdNew, SizeNew, TotalNew}, Found, [H|Acc])
    end.

get_color_id(by_name, _ColorName, []) ->
    0;
get_color_id(by_name, ColorName, [{H}|T]) ->
    Name = ?v(<<"name">>, H),
    case Name =:= ColorName of
	true -> ?v(<<"id">>, H);
	false -> get_color_id(by_name, ColorName, T)
    end.	    

check_amount(stock, [], Total, ShouldPay) ->
    {ok, {Total, ShouldPay}};
check_amount(stock, [H|T], Total, ShouldPay) ->
    {StyleNumber, Price, TotalOfStyleNumber, Attrs} = H,

    Amount = lists:foldr(fun({_ColorId, _Size, ATotal}, Acc) ->
				 ?to_i(ATotal) + Acc
			 end, 0, Attrs),

    case ?to_i(TotalOfStyleNumber) =:= Amount of
	true -> check_amount(stock,
			     T,
			     TotalOfStyleNumber + Total,
			     ?to_f(TotalOfStyleNumber * ?to_f(Price)) + ShouldPay);
	false ->
	    {error, {invalid_stock_total, StyleNumber, TotalOfStyleNumber, Amount}} 
    end.

insert_db(stock, {_Merchant, _Shop, _Employee, _Retailer, _Datetime}, [], Acc) ->
    Acc;
insert_db(stock, {Merchant, Shop, Employee, Retailer, Datetime}, [H|T], Acc) ->
    {StyleNumber, Price, TotalOfStyleNumber, Attrs} = H,
    Sql = "select id, style_number"
	", brand"
	", firm"
	", type"
	", s_group"
	", free"
	", season"
	", year"
	", amount"
	", org_price"
	", tag_price"
	", discount"
	", path"
	", entry_date"
	" from w_inventory where merchant=" ++ ?to_s(Merchant)
	++ " and shop=" ++ ?to_s(Shop)
	++ " and style_number=\'"  ++ ?to_s(StyleNumber) ++ "\'",

    case ?sql_utils:execute(read, Sql) of
	{ok, []} ->
	    throw({error, ?err(wsale_stock_not_found, StyleNumber), StyleNumber});
	{ok, [{R}]} ->
	    ?DEBUG("R ~p", [R]),
	    Amount   = ?v(<<"amount">>, R),
	    case Amount - TotalOfStyleNumber >= 0 of
		true ->
		    SaleSn = lists:concat(
			       ["M-", ?to_i(Merchant), "-S-", ?to_i(Shop), "-",
				?inventory_sn:sn(w_sale_new_sn, Merchant)]),
		    
		    Brand    = ?v(<<"brand">>, R),
		    Firm     = ?v(<<"firm">>, R),
		    Type     = ?v(<<"type">>, R),
		    SGroup   = ?v(<<"s_group">>, R),
		    Free     = ?v(<<"free">>, R),
		    Season   = ?v(<<"season">>, R),
		    Year     = ?v(<<"year">>, R),

		    OrgPrice = ?v(<<"org_price">>, R),
		    TagPrice = ?v(<<"tag_price">>, R),
		    Discount = ?v(<<"discount">>, R),
		    Path     = ?v(<<"path">>, R),
		    
		    InDatetime = ?v(<<"entry_date">>, R),
		    ShouldPay  = ?to_f(?to_i(TotalOfStyleNumber) * ?to_f(Price)),
		    EDiscount = ?w_good_sql:stock(ediscount, OrgPrice, TagPrice),
		    RDiscount = ?w_good_sql:stock(ediscount, Price, TagPrice),

		BaseSql = "insert into w_sale(rsn, employ, retailer, shop, merchant"
			", should_pay, card, total, type, entry_date) values("
			++ "\"" ++ ?to_s(SaleSn) ++ "\","
			++ "\'" ++ ?to_s(Employee) ++ "\',"
			++ ?to_s(Retailer) ++ ","
			++ ?to_s(Shop) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(ShouldPay) ++ ","
			++ ?to_s(ShouldPay) ++ ","
			++ ?to_s(TotalOfStyleNumber) ++ ","
			++ ?to_s(0) ++ ","
			++ "\'" ++ ?to_s(Datetime) ++ "\')",

		    SaleSql = "insert into w_sale_detail("
			"rsn, style_number, brand, merchant, shop, type, s_group, free"
			", season, firm, year, in_datetime, total"
			", org_price, ediscount, tag_price, fdiscount, rdiscount, fprice, rprice"
			", path, entry_date) values("
			++ "\"" ++ ?to_s(SaleSn) ++ "\","
			++ "\"" ++ ?to_s(StyleNumber) ++ "\","
			++ ?to_s(Brand) ++ ","
			++ ?to_s(Merchant) ++ ","
			++ ?to_s(Shop) ++ ","
			++ ?to_s(Type) ++ ","
			++ "\"" ++ ?to_s(SGroup) ++ "\","
			++ ?to_s(Free) ++ "," 
			++ ?to_s(Season) ++ ","
			++ ?to_s(Firm) ++ ","
			++ ?to_s(Year) ++ ","
			++ "\'" ++ ?to_s(InDatetime) ++ "\'," 
			++ ?to_s(TotalOfStyleNumber) ++ ","

			++ ?to_s(OrgPrice) ++ ","
			++ ?to_s(EDiscount) ++ ","
			++ ?to_s(TagPrice) ++ "," 
			++ ?to_s(Discount) ++ ","
			++ ?to_s(RDiscount) ++ ","
			++ ?to_s(Price) ++ ","
			++ ?to_s(Price) ++ "," 
			++ "\"" ++ ?to_s(Path) ++ "\","
			++ "\"" ++ ?to_s(Datetime) ++ "\")",

		    StockSql0 = "update w_inventory set amount=amount-" ++ ?to_s(TotalOfStyleNumber)
			++ ", sell=sell-" ++ ?to_s(TotalOfStyleNumber)
			++ " where id=" ++ ?to_s(?v(<<"id">>, R))
			++ " and merchant=" ++ ?to_s(Merchant)
			++ " and shop=" ++ ?to_s(Shop)
			++ " and style_number=\'"  ++ ?to_s(StyleNumber) ++ "\'",

		    StockSql1 = 
			lists:foldr(
			  fun({ColorId, Size, TAmount}, Acc1) ->
				  UpperSize = string:to_upper(?to_s(Size)),
				  Sql0 = "select id, style_number, brand, total"
				      " from w_inventory_amount where merchant=" ++ ?to_s(Merchant)
				      ++ " and shop=" ++ ?to_s(Shop)
				      ++ " and style_number=\'"  ++ ?to_s(StyleNumber) ++ "\'"
				      ++ " and color=" ++ ?to_s(ColorId)
				      ++ " and size=\"" ++ UpperSize ++ "\"",
				  case ?sql_utils:execute(read, Sql0) of
				      {ok, []} ->
					  throw({error, ?err(wsale_stock_not_found, StyleNumber), StyleNumber});
				      {ok, [{R1}]} ->
					  ?DEBUG("R ~p", [R1]),
					  Total = ?v(<<"total">>, R1),
					  RID   = ?v(<<"id">>, R1),
					  case Total - TAmount >= 0 of
					      true ->
						  ["update w_inventory_amount set total=total-" ++ ?to_s(TAmount)
						   ++ " and id=" ++ ?to_s(RID)
						   ++ " merchant=" ++ ?to_s(Merchant)
						   ++ " and shop=" ++ ?to_s(Shop)
						   ++ " and style_number=\'"  ++ ?to_s(StyleNumber) ++ "\'"
						   ++ " and color=" ++ ?to_s(ColorId)
						   ++ " and size=\"" ++ UpperSize ++ "\"",
						   
						   "insert into w_sale_detail_amount(rsn"
						   ", style_number, brand, color, size"
						   ", total, merchant, shop, entry_date) values("
						   ++ "\"" ++ ?to_s(SaleSn) ++ "\","
						   ++ "\"" ++ ?to_s(StyleNumber) ++ "\","
						   ++ ?to_s(Brand) ++ ","
						   ++ ?to_s(ColorId) ++ ","
						   ++ "\"" ++ UpperSize ++ "\","
						   ++ ?to_s(TAmount) ++ ","
						   ++ ?to_s(Merchant) ++ ","
						   ++ ?to_s(Shop) ++ ","
						   ++ "\"" ++ ?to_s(Datetime) ++ "\")"
						  ] ++ Acc1;
					      false ->
						  throw({error,
							 ?err(wsale_stock_not_enought, StyleNumber),
							 StyleNumber})
					  end;
				      {ok, _RS1} ->
					  ?DEBUG("RS ~p", [_RS1]),
					  throw({error, ?err(w_sale_stock_not_unique, StyleNumber), StyleNumber})
				  end
			  end, [], Attrs),
		    insert_db(stock, {Merchant, Shop, Employee, Retailer, Datetime}, T, 
			      [BaseSql, SaleSql, StockSql0] ++ StockSql1 ++ Acc);
		false ->
		    throw({error, ?err(wsale_stock_not_enought, StyleNumber), StyleNumber})
	    end; 
	{ok, _RS} ->
	    ?DEBUG("RS ~p", [_RS]),
	    throw({error, ?err(wsale_stock_not_unique, StyleNumber), StyleNumber})
    end.

    
