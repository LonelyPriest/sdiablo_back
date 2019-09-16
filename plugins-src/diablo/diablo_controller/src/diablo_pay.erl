-module(diablo_pay).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").
-export([pay/3, pay/5]).
pay(wwt, Merchant, MchntCd, PayCode, Moneny) ->
    Path = "http://test.zhihuishangjie.cn/api/v2/micropay",
    Version = "1.0",
    InsCd = "6f606eb525ffdc56",
    %% MchntCd = "10001",
    TermId = "139887",
    MchntOrder = ?inventory_sn:sn(pay_order_sn, Merchant),
    %% OrderAmt = "0.01",
    %% AuthCode = "134650742072170576",
    random:seed(),
    Random = random:uniform(1000),

    S = 
	lists:sort(
	  [
	   lists:concat(["version", Version]),
	   lists:concat(["ins_cd", InsCd]) ,
	   lists:concat(["mchnt_cd", ?to_s(MchntCd)]),
	   lists:concat(["term_id", TermId]),
	   lists:concat(["mchnt_order_no", ?to_s(MchntOrder)]),
	   lists:concat(["order_amt", ?to_s(Moneny)]),
	   lists:concat(["auth_code", ?to_s(PayCode)]),
	   lists:concat(["random_str", Random])
	  ]),
    ?DEBUG("S ~ts", [S]),

    MD5 = crypto:hash(md5, unicode:characters_to_list(S, utf8)),
    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    ?DEBUG("SingMD5 ~p", [SignMD5]),

    %% Body = lists:concat(["version=", Version,
    %% 			 "&ins_cd=", InsCd,
    %% 			 "&mchnt_cd", MchntCd,
    %% 			 "&term_id=", TermId, 
    %% 			 "&mchnt_order_no=", MchntOrder,
    %% 			 "&order_amt=", OrderAmt,
    %% 			 "&auth_code=", AuthCode,
    %% 			 "&random_str=", Random]),
    %% UTF8Body = unicode:characters_to_list(Body, utf8),

    Body = [{<<"version">>, ?to_b(Version)},
	    {<<"ins_cd">>, ?to_b(InsCd)},
	    {<<"mchnt_cd">>, ?to_b(MchntCd)},
	    {<<"term_id">>, ?to_b(TermId)},
	    {<<"mchnt_order_no">>, ?to_b(MchntOrder)},
	    {<<"order_amt">>, ?to_b(Moneny)},
	    {<<"auth_code">>, ?to_b(PayCode)},
	    {<<"random_str">>, ?to_b(Random)},
	    {<<"sign">>, ?to_b(SignMD5)}],

    JsonBody = ejson:encode({Body}),
    ?DEBUG("JsonBody ~p", [JsonBody]),

    case 
	httpc:request(
	  post,
	  {?to_s(Path) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
	   [], [], JsonBody}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("pay result ~p", [Result]),
	    Code = ?v(<<"code">>, Result), 
	    Info = ?v(<<"msg">>, Result), 
	    %% Data = ?v(<<"data">>, Result),
	    %% [{<<"code">>, Code},
	    %%  {<<"msg">>, Msg},
	    %%  {<<"data">>, _Data}] = Result,
	    ?DEBUG("code ~p, msg ~ts", [Code, Info]),
	    case Code of
		?SUCCESS -> {ok, ?SUCCESS, MchntOrder};
		_ -> {error, Code, MchntOrder}
	    end;
	{error, Reason} ->
	    ?INFO("sms send http failed, Reason ~p", [Reason]),
	    {error, pay_http_failed, Reason}
    end.

pay(wwt_query, MchntCd, MchntOrder) ->
    Path = "http://test.zhihuishangjie.cn/api/v2/commonQuery",
    Version = "1.0",
    InsCd = "6f606eb525ffdc56",
    random:seed(),
    Random = random:uniform(1000),
    S = 
	lists:sort(
	  [
	   lists:concat(["version", Version]),
	   lists:concat(["ins_cd", ?to_s(InsCd)]) ,
	   lists:concat(["mchnt_cd", ?to_s(MchntCd)]),
	   lists:concat(["mchnt_order_no", ?to_s(MchntOrder)]),
	   lists:concat(["random_str", ?to_s(Random)])
	  ]),
    ?DEBUG("S ~ts", [S]),

    MD5 = crypto:hash(md5, unicode:characters_to_list(S, utf8)),
    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    ?DEBUG("SingMD5 ~p", [SignMD5]),

    Body = [{<<"version">>, ?to_b(Version)},
	    {<<"ins_cd">>, ?to_b(InsCd)},
	    {<<"mchnt_cd">>, ?to_b(MchntCd)}, 
	    {<<"mchnt_order_no">>, ?to_b(MchntOrder)},
	    {<<"random_str">>, ?to_b(Random)},
	    {<<"sign">>, ?to_b(SignMD5)}],

    JsonBody = ejson:encode({Body}),
    ?DEBUG("JsonBody ~p", [JsonBody]),

    case 
	httpc:request(
	  post,
	  {?to_s(Path) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
	   [], [], JsonBody}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("query pay order_no ~p with result:~p", [MchntOrder, Result]),
	    Code = ?v(<<"code">>, Result),
	    Info = ?v(<<"msg">>, Result),
	    OrderType = ?v(<<"order_type">>, Result),
	    Balance = ?v(<<"total_amount">>, Result),
	    ?DEBUG("code ~p, msg ~ts", [Code, Info]),
	    case Code of
		?SUCCESS ->
		    {ok, ?SUCCESS, MchntOrder, case OrderType of
						   <<"WECHAT">> -> 0;
						   <<"ALIPAYE">> -> 1;
						   _ -> 9999
					       end, Balance};
		_ -> {error, Code, MchntOrder}
	    end; 
	{error, Reason} ->
	    ?INFO("sms send http failed, Reason ~p", [Reason]),
	    {error, q_pay_http_failed, Reason}
    end.
