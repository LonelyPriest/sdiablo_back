-module(diablo_pay).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").
-export([pay/1]).
pay(wwt) ->
    Path = "http://test.zhihuishangjie.cn/api/v2/micropay",
    Version = "1.0",
    InsCd = "d7772b0674a318d5",
    MchntCd = "10001",
    TermId = "139887",
    MchntOrder = "807",
    OrderAmt = "0.01",
    AuthCode = "134650742072170576", 
    Random = "70",

    S = 
	lists:sort(
	  [
	   lists:concat(["version", Version]),
	   lists:concat(["ins_cd", InsCd]) ,
	   lists:concat(["mchnt_cd", MchntCd]),
	   lists:concat(["term_id", TermId]),
	   lists:concat(["mchnt_order_no", MchntOrder]),
	   lists:concat(["order_amt", OrderAmt]),
	   lists:concat(["auth_code", AuthCode]),
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
	    {<<"order_amt">>, ?to_b(OrderAmt)},
	    {<<"auth_code">>, ?to_b(AuthCode)},
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
	    [{<<"code">>, _Code},
	     {<<"msg">>, Msg},
	     {<<"data">>, _Data}] = Result,
	    ?DEBUG("msg ~ts", [Msg]);
	{error, Reason} ->
	    ?INFO("sms send http failed, Reason ~p", [Reason]),
	    {error, {http_failed, Reason}}
    end;

pay(wwt_query) ->
    Path = "http://test.zhihuishangjie.cn/api/v2/commonQuery",
    Version = "1.0",
    InsCd = "d7772b0674a318d5",
    MchntCd = "10001",
    MchntOrder = "807",
    Random = "70",
    S = 
	lists:sort(
	  [
	   lists:concat(["version", Version]),
	   lists:concat(["ins_cd", InsCd]) ,
	   lists:concat(["mchnt_cd", MchntCd]),
	   lists:concat(["mchnt_order_no", MchntOrder]),
	   lists:concat(["random_str", Random])
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
	    ?DEBUG("pay result ~p", [Result]),
	    [{<<"code">>, _Code},
	     {<<"msg">>, Msg},
	     {<<"data">>, _Data}] = Result,
	    ?DEBUG("msg ~ts", [Msg]);
	{error, Reason} ->
	    ?INFO("sms send http failed, Reason ~p", [Reason]),
	    {error, {http_failed, Reason}}
    end.
