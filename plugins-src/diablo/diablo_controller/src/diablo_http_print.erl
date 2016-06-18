%%%-------------------------------------------------------------------
%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2015, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  3 Mar 2015 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_http_print).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([print/4, print/5, call/2]).

-export([server/1, head/7, detail/2, detail/3,
	 start_print/8, start_print/6,
	 multi_print/1, get_printer_state/4,
	 multi_send/5]).

-export([title/3, get_printer/2]).

-import(?f_print,
	[width/2, pading/1, clean_zero/1, br/1, line/2]).

-define(SERVER, ?MODULE).
-define(PRINT_FIELDS,
	[brand, style_number, type, color, size_name,
	 size, price, discount, dprice, hand, count, calc]).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================

%% print(Merchant, Shop, Content) ->
%%     gen_server:call(?SERVER, {print, Merchant, Shop, Content}).

print(test, Merchant, Shop, _PId) ->
    %% gen_server:call(?SERVER, {print_test, Merchant, Shop, PId}).

    RSN = "88888888",
    Attrs = [{<<"shop">>, Shop}],
    Self = self(),
    spawn(?MODULE, call,
	  [Self, {print, test, RSN, Merchant, [], Attrs, []}]),

    receive
	{Self, Any} -> Any
    after 3000 ->
	    {error, ?err(print_timeout, RSN)}
    end.

print(RSN, Merchant, Inventories, Attrs, Print) -> 
    Self = self(),
    spawn(?MODULE, call,
	  [Self, {print, normal, RSN, Merchant, Inventories, Attrs, Print}]),

    receive
	{Self, Any} -> Any
    after 3000 ->
	    {error, ?err(print_timeout, RSN)}
    end.
    

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
    inets:start(),
    {ok, #state{}}. 

handle_call({print_test, Merchant, Shop, PId}, _Form, State) ->
    Reply = diablo_http_print_test:print(Merchant, Shop, PId),
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


get_printer(Merchant, ShopId) ->
    {Printers, ShopInfo} =
	case ?w_user_profile:get(shop, Merchant, ShopId) of
	    {ok, []} -> {[], []};
	    {ok, [{Shop}]} ->
		case ?v(<<"repo">>, Shop) of
		    -1 ->
			case ?w_user_profile:get(print, Merchant, ShopId) of
			    {ok, []} -> {[], []};
			    {ok, [{P1}]} ->
				{[[{<<"pshop">>, ShopId}|P1]], Shop}
			end;
		    RepoId ->
			{[case ?w_user_profile:get(print, Merchant, ShopId) of
			      {ok, []} -> [];
			      {ok, [{P1}]} ->
				  [{<<"pshop">>, ShopId}|P1]
			  end,
			  case ?w_user_profile:get(print, Merchant, RepoId) of
			      {ok, []} -> [];
			      {ok, [{P2}]} -> [{<<"pshop">>, RepoId}|P2]
			  end], Shop}
		end
	end,
    VPrinters = [P || P <- Printers, length(P) =/= 0 ],
    {VPrinters, ShopInfo}.

content(test, {Brand, Model, Column}, Shop, Setting) ->
    title(Brand, Model, Shop)
	++ body_foot(Brand, Model, Column, Setting);

content(normal, {Brand, Model, Column},
	{Merchant, Shop, RSN, Retailer, Setting}, {Invs, Attrs, Print}) ->

    Datetime     = ?v(<<"datetime">>, Attrs),
    RetailerName = ?v(<<"name">>, Retailer, []),
    Employee     = ?v(<<"employ">>, Print), 
    RetailerId = ?v(<<"retailer_id">>, Print),
    Vip = RetailerId =/= ?to_i(?v(<<"s_customer">>, Setting)),
    
    Head = title(Brand, Model, Shop)
    %% ++ address(Brand, Model, ShopAddr)
	++ head(Brand, Model, Column, RSN,
		RetailerName, Employee, Datetime),

    {Body, TotalBalance, STotal, RTotal} =
	print_content(
	  -1, Brand, Model, Column,
	  Merchant, Setting, Invs), 

    Stastic = body_stastic(
		Brand, Model, Column, TotalBalance,
		Attrs, Vip, STotal, RTotal),

    Foot = body_foot(
	     Brand, Model, Column, Setting),

    Head ++ Body ++ Stastic ++ Foot.

call(Parent, {print, Action, RSN, Merchant, Invs, Attrs, Print}) ->
    ?DEBUG("print with action ~p, RSN ~p, merchant ~p~ninventory ~p~nAttrs ~p"
	   ", Print  ~p", [Action, RSN, Merchant, Invs, Attrs, Print]),

    ShopId = ?v(<<"shop">>, Attrs), 

    {VPrinters, ShopInfo} = get_printer(Merchant, ShopId), 
    %% ?DEBUG("printers ~p", [Printers]),
    %% VPrinters = [P || P <- Printers, length(P) =/= 0 ],
    ?DEBUG("printers ~p", [VPrinters]),
    case VPrinters of
	[] ->
	    Parent ! {Parent, {error, ?err(shop_not_printer, ShopId)}};
	_  ->
	    %% content info
	    %% Retailer     = ?v(<<"retailer">>, Print),
	    RetailerId = ?v(<<"retailer_id">>, Print),
	    {ok, Retailer}
		= ?w_user_profile:get(retailer, Merchant, RetailerId),
	    %% RetailerName = ?v(<<"name">>, Retailer, []),
	    
	    %% ?DEBUG("retailer  ~p", [Retailer]),
	    %% Employee     = ?v(<<"employ">>, Print), 
	    %% Datetime     = ?v(<<"datetime">>, Attrs),
	    %% Total        = ?v(<<"total">>, Attrs, 0),
	    Direct       = ?v(<<"direct">>, Attrs, 0),
	    %%  [Date, _]    = string:tokens(?to_s(DateTime), " "),

	    %% shop info
	    ShopName = case ?w_sale:direct(Direct) of
			   wreject ->
			       ?to_s(?v(<<"name">>, ShopInfo))
				   ++ "（退）";
			   _       ->
			       ?v(<<"name">>, ShopInfo)
		       end, 
	    %% ShopAddr = ?v(<<"address">>, ShopInfo), 
	    try
		lists:foldr(
		  fun(P, Acc) ->
			  ?DEBUG("p ~p", [P]),
			  SN     = ?v(<<"sn">>, P),
			  Key    = ?v(<<"code">>, P),
			  Path   = ?v(<<"server_path">>, P),

			  Brand  = ?v(<<"brand">>, P),
			  Model  = ?v(<<"model">>, P),

			  Column = ?v(<<"pcolumn">>, P),
			  %% Height = ?v(<<"pheight">>, P),
			  PShop  = ?v(<<"pshop">>, P),
			  
			  %% ?DEBUG("P ~p", [P]),
			  Server = server(?v(<<"server_id">>, P)),

			  {ok, Setting}
			      = detail(base_setting, Merchant, PShop),

			  Content =
			      case Action of
				  normal ->
				      content(
					normal, 
					{Brand, Model, Column},
					{Merchant, ShopName, RSN, Retailer, Setting},
					{Invs, Attrs, Print});
				  test ->
				      content(test,
					      {Brand, Model, Column},
					      ShopName,
					      Setting)
			      end,
			  %% ?DEBUG("setting ~p", [Setting]),
			  %% Vip = RetailerId =/= ?to_i(?v(<<"s_customer">>, Setting)),
			  %% Num = ?to_i(?v(<<"pum">>, Setting, 1)),

			  %% Head = title(Brand, Model, ShopName)
			  %%     %% ++ address(Brand, Model, ShopAddr)
			  %%     ++ head(Brand, Model, Column, RSN,
			  %%     	      RetailerName, Employee, Datetime),

			  %% {Body, TotalBalance, STotal, RTotal} = print_content(
			  %% 	   PShop, Brand, Model, Column,
			  %% 	   Merchant, Setting, Invs), 

			  %% Stastic = body_stastic(
			  %% 	      Brand, Model, Column, TotalBalance,
			  %% 	      Attrs, Vip, STotal, RTotal),
			  
			  %% Foot = body_foot(
			  %% 	   Brand, Model, Column, Setting),
			  
			  %% Content = Head ++ Body ++ Stastic ++ Foot,
			  Num = ?to_i(?v(<<"pum">>, Setting, 1)),
			  [{SN, fun() when Server =:= fcloud ->
					start_print(
					  fcloud, SN, Key, Path, Num, Content) 
				end}|Acc]
		  end, [], VPrinters) of
		PrintInfo ->
		    ?DEBUG("print Info ~p", [PrintInfo]),
		    Reply = multi_print(PrintInfo),
		    ?DEBUG("Reply ~p", [Reply]),
		    Parent ! {Parent, Reply}
	    catch
		size_not_include ->
		   Parent ! {Parent,
			     {error, ?err(print_size_not_include, ShopId)}}
	    end
    end.

print_content(ShopId, PBrand, Model, 58, Merchant, Setting, Invs) ->
    ?DEBUG("print_content with shop ~p, pbrand ~p, model ~p"
	   ", merchant ~p~nsetting ~p~ninvs ~p",
	   [ShopId, PBrand, Model, Merchant, Setting, Invs]),

    {ok, Brands} = ?w_user_profile:get(brand, Merchant),
    lists:foldr(
      fun(Inv, {Acc, Balance, STotal, RTotal})->
	      StyleNumber = ?v(<<"style_number">>, Inv),
	      BrandId     = ?v(<<"brand_id">>, Inv),
	      SellTotal   = ?v(<<"total">>, Inv),
	      TagPrice    = ?v(<<"tag_price">>, Inv),
	      RPrice      = ?v(<<"rprice">>, Inv),
	      %% rDiscount   = ?v(<<"rdiscount">>, Inv), 
	      Discount   =
		  case TagPrice == 0 of
		      true -> 0;
		      false ->
			  binary_to_float(
			    float_to_binary(RPrice / TagPrice, [{decimals, 3}])) * 100
		  end,
	      
	      {NewSTotal, NewRTotal } =
		  case SellTotal > 0 of
		      true  -> {STotal + SellTotal, RTotal};
		      false -> {STotal, RTotal + SellTotal}
		  end,
	      
	      {"款号：" ++ ?to_s(StyleNumber) ++ br(PBrand)
	       ++ "品名：" ++ ?to_s(get_brand(Brands, BrandId)) ++ br(PBrand)
	       ++ "单价：" ++ ?to_s(TagPrice) ++ br(PBrand)
	       ++ "成交价：" ++ ?to_s(RPrice) ++ br(PBrand)
	       ++ "数量：" ++ ?to_s(SellTotal) ++ br(PBrand)
	       ++ "小计：" ++ ?to_s(RPrice * SellTotal) ++ br(PBrand)
	       ++ "折扣率：" ++ ?to_s(Discount) ++ br(PBrand)
	       ++ line(minus, 32) ++ br(PBrand)
	       ++ Acc, Balance +RPrice * SellTotal, NewSTotal, NewRTotal}
      end, {[], 0, 0, 0}, Invs);

print_content(ShopId, PBrand, Model, 80, Merchant, Setting, Invs) ->
    ?DEBUG("print_content with shop ~p, pbrand ~p, model ~p"
	   ", merchant ~p~nsetting ~p~ninvs ~p",
	   [ShopId, PBrand, Model, Merchant, Setting, Invs]),

    {ok, Brands} = ?w_user_profile:get(brand, Merchant),

    H = "款号" ++ pading(10)
	++ "单价" ++ pading(2)
	++ "成交价" ++ pading(2)
	++ "数量" ++ pading(2)
	++ "小计" ++ pading(4)
	++ "折扣率"
	++ br(PBrand),

    {Body, TB, ST, RT} =
	lists:foldr(
	  fun(Inv, {Acc, Balance, STotal, RTotal})->
		  StyleNumber = ?v(<<"style_number">>, Inv),
		  BrandId     = ?v(<<"brand_id">>, Inv),
		  SellTotal   = ?v(<<"total">>, Inv),
		  TagPrice    = ?v(<<"tag_price">>, Inv),
		  RPrice      = ?v(<<"rprice">>, Inv),

		  CleanTagPrice = clean_zero(TagPrice),
		  Calc        = RPrice * SellTotal, 
		  Discount    =
		      binary_to_float(
			float_to_binary(RPrice / TagPrice, [{decimals, 3}])) * 100,

		  {NewSTotal, NewRTotal } =
		      case SellTotal > 0 of
			  true  -> {STotal + SellTotal, RTotal};
			  false -> {STotal, RTotal + SellTotal}
		      end,

		  {?to_s(StyleNumber) ++ pading(14 - width(latin1, StyleNumber))
		   %% ++ "品名：" ++ ?to_s(get_brand(Brands, BrandId)) ++ br(PBrand)
		   ++ ?to_s(CleanTagPrice) ++ pading(6 - width(latin1, CleanTagPrice))
		   ++ ?to_s(RPrice) ++ pading(8 - width(latin1, RPrice))
		   ++ ?to_s(SellTotal) ++ pading(6 - width(latin1, SellTotal))
		   ++ ?to_s(Calc) ++ pading(8 - width(latin1, Calc))
		   ++ ?to_s(Discount) ++ br(PBrand)
		   ++ ?to_s(get_brand(Brands, BrandId)) ++ br(PBrand)
		   ++ line(minus, 48) ++ br(PBrand) 
		   ++ Acc, Balance + Calc, NewSTotal, NewRTotal}
	  end, {[], 0, 0, 0}, Invs),
    {H ++ Body, TB, ST, RT}.
    
%% =============================================================================
%% internal function
%% =============================================================================

title(<<"feie">>, _Model, Title) ->
    "<CB>" ++ ?to_s(Title) ++ "</CB><BR>".
    %% ?DEBUG("title ~ts", [?to_b(T)]),

%% address
%% address(<<"feie">>, _Model, Address) ->
%%     "<C>" ++ ?to_s(Address) ++ "</C><BR>".

head(<<"feie">> = Brand, _Model, 58, RSN, Retailer, Employee, Date) ->
    ?DEBUG("feie head brand ~p, RSN ~p~nretailer ~p, employee ~p, date ~p",
	   [Brand, RSN, Retailer, Employee, Date]),
    "单号：" ++ ?to_s(RSN) ++ br(Brand)
	++ "客户：" ++ ?to_s(Retailer)
	++ pading(32 - 12 - width(chinese, Retailer) - width(chinese, Employee))
	++ "店员：" ++ ?to_s(Employee) ++ br(Brand)
	++ "日期：" ++ ?to_s(Date) ++ br(Brand)
	++ line(equal, 32) ++ br(Brand);

head(<<"feie">> = Brand, _Model, 80, RSN, Retailer, Employee, Date) ->
    "单号：" ++ ?to_s(RSN)
	++ pading(48 - 6 - width(latin1, RSN) - 25)
	++ "日期：" ++ ?to_s(Date) ++ br(Brand)
	
	++ "客户：" ++ ?to_s(Retailer)
	++ pading(48 - 25 - 6 - width(chinese, Retailer))
	++ "店员：" ++ ?to_s(Employee) ++ br(Brand)
	
	++ line(equal, 48) ++ br(Brand).

body_stastic(Brand, _Model, Column, _TotalBalance, Attrs, Vip, STotal, RTotal) ->
    ?DEBUG("body_stastic with Attrs ~p, Column ~p, Vip ~p", [Column, Attrs, Vip]),
    Cash         = ?v(<<"cash">>, Attrs, 0),
    Card         = ?v(<<"card">>, Attrs, 0),
    Withdraw     = ?v(<<"withdraw">>, Attrs, 0),
    ShouldPay    = clean_zero(?v(<<"should_pay">>, Attrs, 0)),
    Total        = abs(STotal) + abs(RTotal),
    Comment      = ?v(<<"comment">>, Attrs, []),
    Direct       = ?v(<<"direct">>, Attrs, 0),

    LastScore    = ?v(<<"last_score">>, Attrs, 0),
    Score        = ?v(<<"score">>, Attrs, 0),

    AccScore     = Score + LastScore,

    RPay         = ShouldPay - Withdraw,
    NewCash      = case Cash >= RPay of
		       true  -> RPay;
		       false -> Cash
		   end,

    NewCard      = case Card >= RPay - NewCash of
		       true  -> RPay - NewCash;
		       false -> Card
		   end,

    case RTotal =/= 0 of
	true -> "销售：" ++ ?to_s(STotal)
		    ++ pading(length(?to_s(ShouldPay)) - length(?to_s(STotal)) + 2)
		    ++ "退货：" ++ ?to_s(RTotal) ++ br(Brand);
	false -> []
    end ++
	"总计：" ++ ?to_s(Total)
	++ pading(length(?to_s(ShouldPay)) - length(?to_s(Total)) + 2)
	++ "备注：" ++ ?to_s(Comment) ++ br(Brand)
	++ case Direct of
	       0 -> "实付：";
	       1 -> "退款："
	   end
	
	++ ?to_s(abs(ShouldPay))
	++ pay(style, abs(NewCash), abs(NewCard), abs(Withdraw))
	++ br(Brand)

	++ case Vip of 
	       true ->
		   case Column of
		       80 -> "上次积分：" ++ ?to_s(LastScore) ++ pading(1)
			   ++ "本次积分：" ++ ?to_s(Score) ++ pading(1)
			   ++ "累计积分：" ++ ?to_s(AccScore) ++ br(Brand);
		       58 ->
			   "上次积分：" ++ ?to_s(LastScore) ++ br(Brand)
			       ++ "本次积分：" ++ ?to_s(Score) ++ br(Brand)
			       ++ "累计积分：" ++ ?to_s(AccScore) ++ br(Brand)
		   end;
	       false -> []
	   end
	
	++ case Column of
	       80 -> line(minus, 48);
	       58 -> line(minus, 32)
	   end
	++ br(Brand).
    
body_foot(Brand, _Model, Column, Setting) ->
    %% ?DEBUG("body_foot with setting ~p", [Setting]), 
    [CH|CT] = [?v(<<"comment1">>, Setting, []),
	       ?v(<<"comment2">>, Setting, []),
	       ?v(<<"comment3">>, Setting, []),
	       ?v(<<"comment4">>, Setting, [])
	      ],
    %% comment
    FirstComment = "顾客须知：" ++ br(Brand) 
	++ "1：" ++ ?to_s(CH) ++ br(Brand),

    Len = erlang:length(CT),
    
    {OtherComment, _Order} =
	lists:foldr(
	  fun([], {Acc, Sequence}) ->
		  {Acc, Sequence - 1};
	     (M, {Acc, Sequence}) ->
		  {?to_s(Sequence) ++ "："
		   ++ ?to_s(M) ++ br(Brand) ++ Acc, Sequence - 1}
	  end, {[], Len + 1}, CT), 
    %% ?DEBUG("OtherComment ~p, order ~p", [OtherComment, _Order]),
    
    PrintDatetime =
	case Column of
	    58 -> pading(32 - 26);
	    80 -> pading(48 - 26);
	    _  -> []
	end ++ "打印日期：" ++ ?utils:current_time(format_localtime), 
    FirstComment ++ OtherComment ++ PrintDatetime.

start_print(fcloud, SN, Key, Path, Num, Body) ->
    ?DEBUG("fcloud with sn ~p, key ~p, path ~p, num ~p, body~n~ts",
	   [SN, Key, Path, Num, ?to_b(Body)]),
    
    UTF8Body = unicode:characters_to_list(?to_s(Body), utf8),
    
    FormatBody = lists:concat(["sn=", ?to_s(SN),
			       "&key=", ?to_s(Key),
			       "&printContent=", ?to_s(UTF8Body),
			       "&times=", ?to_s(Num)]),

    %% ?DEBUG("format body ~ts", [?to_b(FormatBody)]),

    Response = httpc:request(
		 post,
		 {?to_s(Path), [], "application/x-www-form-urlencoded", FormatBody},
		 [], []),

    case Response of
	{ok, {{"HTTP/1.1", ReturnCode, ReturnState}, _Head, Result}} -> 
	    ?DEBUG("print http request return code ~p, state ~p~n"
		   "result ~ts", [ReturnCode, ReturnState, ?to_b(Result)]),
	    case mochijson2:decode(Result) of
		{struct, [{<<"responseCode">>, 0},
			  {<<"msg">>, _PMsg},
			  {<<"orderindex">>, OrderIndex}]} ->
		    {ok, {0, OrderIndex}};
		%% error
		{struct, [{<<"responseCode">>, PCode},
			  {<<"msg">>, _PMsg}]} ->
		    case PCode of
			1 -> {error, ?err(invalid_sn, SN)};
			2 -> {error, ?err(fail_to_process, SN)};
			3 -> {error, ?err(long_content, SN)};
			4 -> {error, ?err(invalid_params, SN)}

		    end
	    end;
	{error, Reason} ->
	    ?INFO("print http request failed: ~p", [Reason]),
	    {error, ?err(print_http_failed, Reason)}
    end.

start_print(rcloud, Brand, Model, Height, SN, Key, Path, {IsPage, Body})  ->
    ?DEBUG("print with brand ~p, Model ~p, Height ~p, sn ~p, key ~p, path ~p"
	   "IsPage ~p", [Brand, Model, Height, SN, Key, Path, IsPage]),
    lists:foreach(
      fun(B) ->
	      ?DEBUG("====== page content ====== ~n~ts", [?to_b(B)])
      end, Body),
    
    CureentTimeTicks = (?SECONDS_BEFOR_1970 + ?utils:current_time(timestamp)) * 10000,

    
    Head = ?f_print:decorate_data(head, ?to_a(Brand), ?to_a(Model), Height * 10), 
    Tail = ?f_print:decorate_data(tail, ?to_a(Brand), ?to_a(Model)),
    Len  = erlang:length(Body),
    
    try 
	%% query state 
	{ok, SN} = get_printer_state(Path, SN, Key, CureentTimeTicks), 
	
	%% ok, print
	{GBKBodys, _} = 
	    lists:foldr(
	      fun(B, {Acc, Lens}) ->
		      Utf8Data = unicode:characters_to_list(?to_s(B), utf8),
		      GBKData  = diablo_iconv:convert("utf-8", "gbk", Utf8Data),
		      Base64 =
			  case Lens + 1 =:= Len of
			      true -> 
				  case IsPage of
				      true ->
					  base64:encode_to_string(Head ++ GBKData ++ Tail);
				      false -> 
					  base64:encode_to_string(GBKData)
				  end;
			      false ->
				  base64:encode_to_string(GBKData)
			  end,
		      {[Base64|Acc], Lens + 1}
	      end,  {[], 0}, Body),

	%% ?DEBUG("gbk body ~p", [GBKBodys]),
	
	%% {ok, SN} = get_printer_state(Path, SN, Key, CureentTimeTicks),
	SignHead = lists:concat(
		     ["action=send&device_id=", ?to_s(SN),
		      "&secretkey=", ?to_s(Key),
		      "&timestamp=" ++ ?to_s(CureentTimeTicks) ++ "&"]),
	
	multi_send(SignHead, Path, SN, GBKBodys, {}) 
    catch
    	throw:{printer_unconnect, DeviceId} ->
    	    ?DEBUG("printer ~p unconnect", [DeviceId]),
	    {error, ?err(printer_unconnect, DeviceId)};
	throw:{printer_no_paper, DeviceId} ->
	    ?DEBUG("printer ~p has not paper", [DeviceId]),
	    {error, ?err(printer_no_paper, DeviceId)};
	throw:{printer_unkown_state, DeviceId} ->
	    ?DEBUG("printer ~p unkown", [DeviceId]),
	    {error, ?err(printer_unkown_state, DeviceId)};
	throw:{printer_conn_not_found, DeviceId} ->
	    {error, ?err(printer_conn_not_found, DeviceId)} 
    end.


multi_send(_SignHead, _Path, Device, [], {}) ->
    {ok, {0, Device}};
multi_send(_SignHead, _Path, _Device, [], Error) ->
    Error;
multi_send(SignHead, Path, Device, [H|T], _Result) ->
    ?DEBUG("start to print ..."),
    %% multi_send(SignHead, Path, Device, T, {}).
    Sign = bin2hex(sha1, crypto:hash(sha, SignHead ++ H)),
    case httpc:request(
    	   post, {?to_s(Path) ++ "?" ++ SignHead ++ "sign=" ++ ?to_s(Sign),
    		  [], "application/x-www-form-urlencoded", H}, [], []) of 
    	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
    	    ?DEBUG("Reply ~ts", [Reply]),
	    case Reply of
		"!device not found." ->
		    Error = {error, ?err(printer_conn_not_found, Device)},
		    multi_send(SignHead, Path, Device, [], Error);
		_ ->
		    {struct, Status} = mochijson2:decode(Reply), 
		    case ?v(<<"state">>, Status) of
			<<"ok">> ->
			    multi_send(SignHead, Path, Device, T, {});
			<<"100">> ->
			    Error = {error, ?err(print_content_error, Device)}, 
			    multi_send(SignHead, Path, Device, [], Error)
		    end
    	    end;
    	{error, Reason} ->
    	    ?INFO("print http request failed: ~p", [Reason]),
    	    Error = {error, ?err(print_http_failed, Reason)},
    	    multi_send(SignHead, Path, Device, [], Error)
    end.

get_printer_state(Path, DeviceId, Key, TimeTicks) -> 
    State = lists:concat(
	      ["action=state&device_id=", ?to_s(DeviceId),
	       "&secretkey=", ?to_s(Key), "&timestamp=" ++ ?to_s(TimeTicks)]),
    Sign = bin2hex(sha1, crypto:hash(sha, State)),

    case httpc:request(
	   post, {?to_s(Path), [], "application/x-www-form-urlencoded",
		  State ++ "&sign=" ++ Sign}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("reply ~p", [Reply]),
	    try 
		case mochijson2:decode(Reply) of
		    1 -> {ok, DeviceId};
		    %% 1 -> throw({printer_unconnect, DeviceId});
		    2 -> throw({printer_unconnect, DeviceId});
		    3 -> throw({printer_no_paper, DeviceId});
		    4 -> throw({printer_unkown_state, DeviceId})
		end
	    catch
		_:{case_clause, <<"!device not found.">>} ->
		    throw({printer_conn_not_found, DeviceId});
		<<"!", _/binary>> ->
		    throw({printer_unkown_state, DeviceId})
	    end;
	{error, Error} ->
	    ?INFO("print http request failed: ~p", [Error]),
	    throw({print_http_failed, Error})
    end.


multi_print(PrintInfo) ->
    multi_print(PrintInfo, [], []).

multi_print([], Succes, Failed) ->
    ?DEBUG("Succes ~p, Failed ~p", [Succes, Failed]),
    {Succes, Failed};
multi_print([{DeviceId, PrintFun}|T], Succes, Failed) ->
    ?DEBUG("deviceid ~p", [DeviceId]),
    case PrintFun() of
	{ok, _} ->
	    multi_print(T, [DeviceId|Succes], Failed);
	{error, {ECode, _}} ->
	    multi_print(T, Succes, [{DeviceId, ECode}|Failed])
    end. 
    
bin2hex(sha1, B) ->
    L = binary_to_list(B),
    LH0 = lists:map(fun(X)->integer_to_list(X,16) end, L),
    LH = lists:map(fun([X,Y])-> [X,Y];
		      %% add zero
		      ([X])   ->[$0,X]
		   end, LH0),
    lists:flatten(LH).

get_brand(Brands, BrandId) ->
    case ?w_user_profile:filter(Brands, <<"id">>, BrandId) of
	[] -> [];
	FindBrand -> ?v(<<"name">>, FindBrand)
    end.

server(1) ->
    fcloud.

detail(merchant, Merchant) ->
    case ?w_user_profile:get(merchant, Merchant) of
	{ok, []} ->
	    ?merchant:merchant(get, Merchant);
	{ok, Info} ->
	    {ok, Info}
    end.

detail(print_format, Merchant, Shop) ->
    {ok, Formats} = ?w_user_profile:get(print_format, Merchant, Shop), 
    lists:foldr(
      fun(F, Acc) ->
	      case
		  lists:filter(
		    fun({Format}) -> 
			    ?v(<<"name">>, Format) =:= ?to_b(F)
				andalso ?v(<<"print">>, Format) =:= 1
				andalso ?v(<<"width">>, Format) =/= 0
		    end, Formats) of
		  [] -> Acc;
		  [{S}] ->
		      [{?v(<<"name">>, S),
			field_name(?v(<<"name">>, S)), ?v(<<"width">>, S)}|Acc]
	      end
      end, [], ?PRINT_FIELDS);

detail(base_setting, Merchant, Shop) ->
    ?DEBUG("base_setting with merhcant ~p, Shop ~p", [Merchant, Shop]),
    {ok, Settings} = ?w_user_profile:get(setting, Merchant, Shop), 
    {ok, lists:foldr(
	   fun({R}, Acc) ->
		   %% only use print setting
		   case ?v(<<"type">>, R) of
		       1 -> Acc;
		       0 -> EName = ?v(<<"ename">>, R),
			    Value = ?v(<<"value">>, R),
			    [{EName, Value}|Acc]
		   end
	   end, [], Settings)}.


field_name(<<"brand">>) -> "品牌";
field_name(<<"style_number">>) -> "款号";
field_name(<<"type">>)         -> "类型";
field_name(<<"color">>)        -> "颜色";
field_name(<<"size">>)         -> "尺码".

pay(style, Cash, Card, Withdraw) ->
    ?DEBUG("cash ~p, card ~p, withdraw ~p", [Cash, Card, Withdraw]),
    Pays = [pay(cash, Cash), pay(card, Card), pay(withdraw, Withdraw)], 
    lists:foldr(fun([], Acc) -> Acc;
		   (S, Acc) -> pading(2) ++ S ++ Acc
		end, [], Pays).
    
pay(card, Card) when Card == 0 -> []; 
pay(card, Card) -> "刷卡：" ++ ?to_s(clean_zero(Card));
pay(cash, Cash)  when Cash == 0-> [];
pay(cash, Cash) -> "现金：" ++ ?to_s(clean_zero(Cash));
pay(withdraw, Withdraw) when Withdraw == 0 -> [];
pay(withdraw, Withdraw) -> "提现：" ++ ?to_s(clean_zero(Withdraw));
pay(veri, Veri) when Veri == 0-> [];
pay(veri, Veri) -> "核销：" ++ ?to_s(clean_zero(Veri)).

    
