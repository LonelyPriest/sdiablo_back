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

-export([server/1, head/8, detail/2, detail/3,
	 start_print/8, start_print/6,
	 multi_print/1, get_printer_state/4,
	 multi_send/5]).

-export([title/3, get_printer/2, bin2hex/2]).

-export([test_barcode/1, bar_code/2, bar_code/5]).

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

content(test, {Brand, Model, Column}, {Shop, ShopAddress, Setting}, []) ->
    title(Brand, Model, Shop)
	++ body_foot(Brand, Model, Column, ShopAddress, Setting);

content(normal, {Brand, Model, Column},
	{Merchant, Shop, ShopAddress, RSN, Retailer, Setting}, {Invs, Attrs, Print}) ->

    Datetime     = ?v(<<"datetime">>, Attrs),
    Vip          = case ?v(<<"vip">>, Attrs) of
		       undefined ->
			   SysVips  = ?gen_report:sys_vip_of(merchant, Merchant),
			   RetailerId = ?v(<<"id">>, Retailer),
			   not lists:member(RetailerId, SysVips)
			       andalso ?v(<<"type_id">>, Retailer) /= ?SYSTEM_RETAILER;
		       _Vip -> _Vip
		   end,
    
    %% RetailerName = ?v(<<"name">>, Retailer, []),
    Employee     = ?v(<<"employ">>, Print), 
    %% LastScore    = ?v(<<"score">>, Retailer, 0),
    
    Head = title(Brand, Model, Shop)
	++ head(Brand, Model, Column, RSN, Retailer, Vip, Employee, Datetime),

    {Body, TotalBalance, STotal, RTotal} =
	print_content(-1, Brand, Model, Column, Merchant, Setting, Invs), 

    Stastic = body_stastic(
		Brand, Model, Column, TotalBalance, Attrs, Vip, STotal, RTotal),

    Foot = body_foot(Brand, Model, Column, ShopAddress, Setting),

    Head ++ Body ++ Stastic ++ Foot.

call(Parent, {print, Action, RSN, Merchant, Invs, Attrs, Print}) ->
    ?DEBUG("print with action ~p, RSN ~p, merchant ~p~ninventory ~p~nAttrs ~p"
	   ", Print  ~p", [Action, RSN, Merchant, Invs, Attrs, Print]),

    ShopId = ?v(<<"shop">>, Attrs), 

    {VPrinters, ShopInfo} = get_printer(Merchant, ShopId), 
    case VPrinters of
	[] ->
	    Parent ! {Parent, {error, ?err(shop_not_printer, ShopId)}};
	_  ->
	    %% content info
	    RetailerId     = ?v(<<"retailer_id">>, Print),
	    {ok, Retailer} = case Action of
				 test -> {ok, []};
				 _ ->
				     ?w_retailer:retailer(get, Merchant, RetailerId)
			     end,
	    Direct         = ?v(<<"direct">>, Attrs, 0), 
	    %% shop info
	    ShopName = case ?w_sale:direct(Direct) of
			   wreject ->
			       ?to_s(?v(<<"name">>, ShopInfo))
				   ++ "（退）";
			   _       ->
			       ?v(<<"name">>, ShopInfo)
		       end, 
	    ShopAddress = ?v(<<"address">>, ShopInfo), 
	    try
		lists:foldr(
		  fun(P, Acc) ->
			  %% ?DEBUG("p ~p", [P]),
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

			  {ok, Setting} = detail(base_setting, Merchant, PShop),

			  Content =
			      case Action of
				  normal ->
				      content(
					normal, 
					{Brand, Model, Column},
					{Merchant, ShopName, ShopAddress, RSN, Retailer, Setting},
					{Invs, Attrs, Print});
				  test ->
				      content(test,
					      {Brand, Model, Column},
					      {ShopName, ShopAddress, Setting}, [])
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
			  <<Num:1/binary, _/binary>> = ?v(<<"pum">>, Setting),
			  ?DEBUG("Num ~p", [Num]),
			  [{SN, fun() when Server =:= fcloud ->
					start_print(fcloud, SN, Key, Path, ?to_i(Num), Content) 
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

print_content(_ShopId, PBrand, _Model, 58, Merchant, Setting, Invs) ->
    %% ?DEBUG("print_content with shop ~p, pbrand ~p, model ~p"
    %% 	   ", merchant ~p~nsetting ~p~ninvs ~p",
    %% 	   [ShopId, PBrand, Model, Merchant, Setting, Invs]),

    {ok, Brands} = ?w_user_profile:get(brand, Merchant),
    {ok, Colors} = ?w_user_profile:get(color, Merchant),
    %%  {ok, Types} = ?w_user_profile:get(type, Merchant),
    <<PColorSize:1/binary, _/binary>> = ?v(<<"p_color_size">>, Setting),
    
    

    H = "款号" ++ pading(8)
	++ "单价" ++ pading(2)
	%% ++ "成交价" ++ pading(2)
	++ "数量" ++ pading(2)
	%% ++ "小计" ++ pading(4)
	++ "折扣率"
	++ br(PBrand),

    {Body, TB, ST, RT} =
	lists:foldr(
	  fun({Inv}, {Acc, Balance, STotal, RTotal})->
		  %% ?DEBUG("Inv ~p", [Inv]),
		  StyleNumber = ?v(<<"style_number">>, Inv),
		  %% ?DEBUG("StyleNumber ~p", [StyleNumber]),
		  BrandId     = ?v(<<"brand_id">>, Inv),
		  %% TypeId      = ?v(<<"type_id">>, Inv),
		  TypeName      = ?v(<<"type">>, Inv),
		  SellTotal   = ?v(<<"total">>, Inv),
		  TagPrice    = ?v(<<"tag_price">>, Inv),
		  RPrice      = ?v(<<"rprice">>, Inv),
		  Amounts     = ?v(<<"amounts">>, Inv, []),

		  %% ?DEBUG("Amounts ~p", [Amounts]),
		  %% rDiscount   = ?v(<<"rdiscount">>, Inv),
		  %% Amounts = [],
		  CleanTagPrice = clean_zero(TagPrice),

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

		  BrandName = ?to_s(get_brand(Brands, BrandId)),
		  %% TypeName = ?to_s(get_type(Types, TypeId)),

		  {?to_s(StyleNumber) ++ pading(12 - width(latin1, StyleNumber))
		   %% ++ "品名：" ++ ?to_s(get_brand(Brands, BrandId)) ++ br(PBrand)
		   ++ ?to_s(CleanTagPrice) ++ pading(6 - width(latin1, CleanTagPrice))
		   ++ ?to_s(SellTotal) ++ pading(6 - width(latin1, SellTotal)) 
		   ++ ?to_s(Discount) ++ br(PBrand)

		   %% ++ ?to_s(RPrice) ++ pading(8 - width(latin1, RPrice)) ++ br(PBrand)
		   ++ BrandName ++ "/" ++ ?to_s(TypeName)
		   ++ pading(24 - width(chinese, BrandName) - width(chinese, TypeName))
		   %% ++ case ?to_i(?v(<<"p_color_size">>, Setting, 0)) of
		   %% 	  0 -> pading(24 - width(chinese, BrandName));
		   %% 	  1 ->
		   %% 	      fun() ->
		   %% 		      ColorSize = 
		   %% 			  lists:foldr(
		   %% 			    fun({struct, A}, Acc1) ->
		   %% 				    ColorId  = ?v(<<"cid">>, A),
		   %% 				    Size     = ?v(<<"size">>, A),
		   %% 				    case ColorId of
		   %% 					?FREE_COLOR -> [];
		   %% 					_ ->
		   %% 					    "/" ++ ?to_s(get_color(Colors, ColorId))
		   %% 				    end ++ 
		   %% 					case Size of
		   %% 					    ?FREE_SIZE -> [];
		   %% 					    _ -> "/" ++ ?to_s(Size)
		   %% 					end ++ Acc1
		   %% 			    end, [], Amounts),
		   %% 		      ?DEBUG("ColorSize ~p", [ColorSize]),
		   %% 		      ColorSize ++ pading(24
		   %% 					  - width(chinese, BrandName)
		   %% 					  - width(chinese, ColorSize))
		   %% 	      end ()
		   %%    end
		   ++ ?to_s(RPrice)
		   ++ br(PBrand)
		   ++ case ?to_i(PColorSize) of
			  0 ->
			      pading(24 - 4) ++ "合：" ++ ?to_s(RPrice * SellTotal) ++ br(PBrand);
			  1 ->
			      fun() -> 
				      ColorSize = 
					  lists:foldr(
					    fun({struct, A}, Acc1) ->
						    ColorId  = ?v(<<"cid">>, A),
						    Size     = ?v(<<"size">>, A),
						    Sell     = ?v(<<"sell_count">>, A),
						    Note = 
							case ColorId of
							    ?FREE_COLOR -> [];
							    _ ->
								"/" ++ ?to_s(get_color(Colors, ColorId))
							end ++ 
							case Size of
							    ?FREE_SIZE -> [];
							    _ -> "/" ++ ?to_s(Size)
							end,
						    [Note ++ pading(18 - width(chinese, Note))
						     ++ ?to_s(Sell)] ++ Acc1
					    end, [], Amounts),
				      %% ?DEBUG("ColorSize ~ts", [?to_b(ColorSize)]),
				      [H1|T1] = ColorSize,
				      ?DEBUG("H1 ~p, T1 ~p", [H1, T1]),
				      lists:foldr(
					fun(Note, Acc2) ->
						Note ++ br(PBrand) ++ Acc2
					end, [], T1)
					  ++ H1 ++ pading(24 - width(chinese, H1) - 4)
					  ++ "合：" ++ ?to_s(RPrice * SellTotal) ++ br(PBrand)
			      end ()
		      end
		   %% ++ pading(24 - 6) ++ "（合）" ++ ?to_s(RPrice * SellTotal) ++ br(PBrand)
		   %% ++ "单价：" ++ ?to_s(TagPrice) ++ br(PBrand)
		   %% ++ "成交价：" ++ ?to_s(RPrice) ++ br(PBrand)
		   %% ++ "数量：" ++ ?to_s(SellTotal) ++ br(PBrand)
		   %% ++ "小计：" ++ ?to_s(RPrice * SellTotal) ++ "折扣率：" ++ ?to_s(Discount) ++ br(PBrand)
		   ++ line(minus, 32) ++ br(PBrand)
		   ++ Acc, Balance +RPrice * SellTotal, NewSTotal, NewRTotal}
	  end, {[], 0, 0, 0}, Invs),
    {H ++ Body, TB, ST, RT};

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
		      binary_to_float(float_to_binary(RPrice / TagPrice, [{decimals, 3}])) * 100,

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

head(<<"feie">> = Brand, _Model, 58, RSN, Retailer, Vip, Employee, Date) ->
    ?DEBUG("feie head brand ~p, RSN ~p~nretailer ~p, employee ~p, date ~p",
	   [Brand, RSN, Retailer, Employee, Date]),
    Name = ?v(<<"name">>, Retailer),
    Phone = ?v(<<"mobile">>, Retailer),
    
    "单号：" ++ ?to_s(RSN) ++ br(Brand)
	
	++ "客户：" ++ ?to_s(Name)
	++ case Vip of
	       true ->
		   pading(32 - 6 - width(chinese, Name) - 6 - width(latin1, Phone))
		       ++ "电话：" ++ ?to_s(Phone) ++ br(Brand);
	       false ->
		   []
	   end
	
	++ "店员：" ++ ?to_s(Employee) ++ br(Brand)
	++ "日期：" ++ ?to_s(Date) ++ br(Brand)
	++ line(equal, 32) ++ br(Brand);

head(<<"feie">> = Brand, _Model, 80, RSN, Retailer, Vip, Employee, Date) ->
    Name = ?v(<<"name">>, Retailer),
    Phone = ?v(<<"mobile">>, Retailer),
    
    "单号：" ++ ?to_s(RSN)
	++ pading(48 - 6 - width(latin1, RSN) - 25)
	++ "日期：" ++ ?to_s(Date) ++ br(Brand)

	++ case Vip of
	       true ->
		   "客户：" ++ ?to_s(Name) ++ pading(2) ++ "电话：" ++ ?to_s(Phone) ++ pading(2)
		       ++ pading(48 - 8 - width(chinese, Name) - 8 - width(latin1, Phone) - 7 - width(chinese, Employee));
	       false ->
		   "客户：" ++ ?to_s(Name)
		       ++ pading(48 - 6 - width(chinese, Name) - 20 - width(chinese, Employee))
	   end
	++ "店员：" ++ ?to_s(Employee) ++ br(Brand)
	
	++ line(equal, 48) ++ br(Brand).

body_stastic(Brand, _Model, Column, _TotalBalance, Attrs, Vip, STotal, RTotal) ->
    %% ?DEBUG("body_stastic with Attrs ~p, Column ~p, Vip ~p", [Attrs, Column, Vip]),
    Cash         = ?v(<<"cash">>, Attrs, 0),
    Card         = ?v(<<"card">>, Attrs, 0),
    Wxin         = ?v(<<"wxin">>, Attrs, 0),
    AliPay       = ?v(<<"aliPay">>, Attrs, 0),
    Withdraw     = ?v(<<"withdraw">>, Attrs, 0),
    Ticket       = ?v(<<"ticket">>, Attrs, 0), 
    ShouldPay    = clean_zero(?v(<<"should_pay">>, Attrs, 0)),
    Total        = abs(STotal) + abs(RTotal),
    Comment      = ?v(<<"comment">>, Attrs, []),
    Direct       = ?v(<<"direct">>, Attrs, 0),

    %% LastScore    = ?v(<<"last_score">>, Attrs, 0),
    Score        = ?v(<<"score">>, Attrs, 0),
    TicketScore  = ?v(<<"ticket_score">>, Attrs, 0),

    RealLastScore = ?v(<<"last_score">>, Attrs), 
    AccScore      = Score + RealLastScore - TicketScore,
    
    [NewTicket, NewWithdraw, NewWxin, _NewAliPay, NewCard, NewCash] = NewPays =
	?w_sale:pay_order(ShouldPay, [Ticket, Withdraw, Wxin, AliPay, Card, Cash], []), 
    ?DEBUG("newPays ~p", [NewPays]), 

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
	++ pay(style,
	       abs(NewCash),
	       abs(NewCard),
	       abs(NewWithdraw),
	       abs(NewTicket),
	       abs(NewWxin))
	++ br(Brand)

	++ case Vip of 
	       true ->
		   case Column of
		       80 -> "上次积分：" ++ ?to_s(RealLastScore) ++ pading(1)
			   ++ "本次积分：" ++ ?to_s(Score) ++ pading(1)
			   ++ "累计积分：" ++ ?to_s(AccScore) ++ br(Brand);
		       58 ->
			   "上次积分：" ++ ?to_s(RealLastScore) ++ br(Brand)
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
    
body_foot(Brand, _Model, Column, ShopAddress, Setting) ->
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
		  {?to_s(Sequence) ++ "：" ++ ?to_s(M) ++ br(Brand) ++ Acc, Sequence - 1}
	  end, {[], Len + 1}, CT), 
    %% ?DEBUG("OtherComment ~p, order ~p", [OtherComment, _Order]),

    Address = "地址：" ++ ?to_s(ShopAddress) ++ br(Brand),
    PrintDatetime =
	case Column of
	    58 -> pading(32 - 30);
	    80 -> pading(48 - 30);
	    _  -> []
	end ++ "打印日期：" ++ ?utils:current_time(format_localtime), 
    FirstComment ++ OtherComment ++ Address ++ PrintDatetime.

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

get_color(Colors, ColorId) ->
    case ?w_user_profile:filter(Colors, <<"id">>, ColorId) of
	[] -> [];
	FindColor -> ?v(<<"name">>, FindColor)
    end.

%% get_type(Types, TypeId) ->
%%     case ?w_user_profile:filter(Types, <<"id">>, TypeId) of
%% 	[] -> [];
%% 	FindType -> ?v(<<"name">>, FindType)
%%     end.
    
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
    %% ?DEBUG("base_setting with merhcant ~p, Shop ~p", [Merchant, Shop]),
    %% {ok, Settings} = ?w_user_profile:get(setting, Merchant, Shop),
    Settings = ?w_report_request:get_setting(Merchant, Shop),
    FormatSettings = 
	{ok, lists:foldr(
	       fun({R}, Acc) ->
		       %% only use print setting
		       case ?v(<<"type">>, R) of
			   1 -> Acc;
			   0 -> 
			       EName = ?v(<<"ename">>, R),
			       Value = ?v(<<"value">>, R),
			       T = {EName, Value},
			       case ?to_i(?v(<<"shop">>, R)) =:= Shop of
				   true ->
				       case lists:keysearch(EName, 1, Acc) of
					   {_V, _T} ->
					       lists:keyreplace(EName, 1, Acc, T);
					   false ->
					       [T|Acc]
				       end;
				   false ->
				       case lists:keysearch(EName, 1, Acc) of
					   {_V, _T} ->
					       Acc;
					   false ->
					       [T|Acc]
				       end
			       end
		       end
	       end, [], Settings)},
    %% ?DEBUG("formatSettings ~p", FormatSettings),
    FormatSettings.

field_name(<<"brand">>) -> "品牌";
field_name(<<"style_number">>) -> "款号";
field_name(<<"type">>)         -> "类型";
field_name(<<"color">>)        -> "颜色";
field_name(<<"size">>)         -> "尺码".

pay(style, Cash, Card, Withdraw, Ticket, Wxin) ->
    %% ?DEBUG("cash ~p, card ~p, withdraw ~p, ticket ~p, Wxin ~p", [Cash, Card, Withdraw, Ticket, Wxin]),
    Pays = [pay(cash, Cash),
	    pay(card, Card),
	    pay(withdraw, Withdraw),
	    pay(ticket, Ticket),
	    pay(wxin, Wxin)], 
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
pay(veri, Veri) -> "核销：" ++ ?to_s(clean_zero(Veri));
pay(ticket, Ticket) when Ticket == 0 -> [];
pay(ticket, Ticket) -> "券：" ++ ?to_s(clean_zero(Ticket));
pay(wxin, Wxin) when Wxin == 0 -> [];
pay(wxin, Wxin) -> "微信：" ++ ?to_s(clean_zero(Wxin)).

    
bar_code(one, DigitString) ->

    %% Len = length(DigitString) div 2,

    {Status, Len}=bar_code(length, DigitString, true, 0, 0),

    %% Encode = bar_code(encode, DigitString, <<>>, true, Status),
    Encode = bar_code(encode, DigitString, <<>>, true, Status),

    ?DEBUG("Status ~p, len ~p, encode ~p", [Status, Len, Encode]),

    B1 = <<16#1b, 16#64, 16#02, 16#1d, 16#48, 16#32,
	   16#1d, 16#68, 16#50, %% height
	   16#1d, 16#77, 16#02, %% width
	   16#1d, 16#6b, 16#49, Len>>,

    ?DEBUG("B1 ~p", [B1]),

    <<B1/binary, Encode/binary>>.


bar_code(length, <<>>, _Bb1, Status, Size) ->
    {Status, Size};
bar_code(length, <<Sub:2/binary, T/binary>>, Bb1, Status, Size) ->
    case Sub =:= <<"00">> of
	true ->
	    case Bb1 of
		true -> 
		    bar_code(length, T, false, 0, Size + 4);
		false ->
		    case Status =:= 0 of
			true ->
			    bar_code(length, T, Bb1, 0, Size + 2);
			false ->
			    bar_code(length, T, Bb1, 0, Size + 4)
		    end
	    end;
	false ->
	    case Bb1 of
		true ->
		    bar_code(length, T, false, 1, Size + 3);
		false ->
		    case Status =:= 1 of
			true ->
			    bar_code(length, T, Bb1, 1, Size + 1);
			false ->
			    bar_code(length, T, Bb1, 1, Size + 3)
		    end
	    end
    end;

bar_code(encode, <<>>, Encode, _InitZero, _Status) ->
    Encode;
bar_code(encode, <<Sub:2/binary, T/binary>>, Encode, InitZero, Status) ->
    ?DEBUG("Sub ~p, InitZero ~p, Status ~p", [Sub, InitZero, Status]),
    case Sub =:= <<"00">> of
	true ->
	    case InitZero of
		true ->
		    Code = <<16#7b, 16#42, 16#30, 16#30>>,
		    bar_code(encode, T, <<Encode/binary, Code/binary>>, false, Status);
		false ->
		    case Status =:= 0 of
			true ->
			    Code = <<16#30, 16#30>>,
			    bar_code(encode, T, <<Encode/binary, Code/binary>>, InitZero, 0);
			false ->
			    Code = <<16#7b, 16#42, 16#30, 16#30>>,
			    bar_code(encode, T, <<Encode/binary, Code/binary>>, InitZero, 0)
		    end
	    end;
	false ->
	    case InitZero of
		true ->
		    Number = ?to_i(Sub),
		    Code = <<16#7b, 16#43, Number>>, 
		    bar_code(encode, T, <<Encode/binary, Code/binary>>, false, Status);
		false ->
		    case Status =:= 1 of
			true ->
			    Number = ?to_i(Sub),
			    Code = <<Number>>,
			    bar_code(encode, T, <<Encode/binary,  Code/binary>>, InitZero, 1);
			false ->
			    Number = ?to_i(Sub),
			    Code = <<16#7b, 16#43, Number>>,
			    bar_code(encode, T, <<Encode/binary, Code/binary>>, InitZero, 1)
		    end
	    end
    end.

test_barcode(DigitS) ->
    Body = "<C>" ++ ?to_s(bar_code(one, DigitS)) ++ "</C>",
    ?DEBUG("Body ~p", [Body]),
    %% ok.
    start_print(fcloud,
    		<<"716500297">>,
    		<<"Sd6ThU4d">>,
    		<<"http://121.42.48.187:80/WPServer/printOrderAction">>,
    		1,
    		Body).
    
