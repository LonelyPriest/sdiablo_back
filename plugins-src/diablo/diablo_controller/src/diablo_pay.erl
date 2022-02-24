-module(diablo_pay).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([pay/3, pay/5]).
-export([pay_yc/4, pay_yc/5, pay_sx/9, pay_sx/7]).
-export([pack_sn/1, get_pay_type/2]).
-export([pay_test_sx/4]).

-define(MIN_SN_LEN, 7).
-define(YC_AGENT, "A103373").
-define(YC_AGENT_KEY, "7/ZbQ08OhITuruxv1qqCMiEOopM38bEoHJuFicbczTc=").
-define(YC_PATH, "https://apifacepay.cloudwalk.cn/api/transaction/front/pay/gateway").

-define(YC_AGENT_IP, "120.24.39.174").
-define(YC_PAY_SERVICE, "unified.trade.micropay").
-define(YC_PAY_QUERY_SERVICE, "unified.trade.query").

-define(SX_ORGANIZE, "8080").
-define(SX_PATH, "http://gateway.dbs12580.com").
-define(WXPAY, <<"WXPAY">>).
-define(ALIPAY, <<"ALIPAY">>).
-define(YLPAY, <<"YLPAY">>).
-define(BESTPAY, <<"BESTPAY">>).
-define(CCBPAY, <<"CCBPAY">>).

%% -define(YC_AGENT, "A100721").
%% -define(YC_AGENT_KEY, "S6Fl7nurJ5E6zyrb2tBLxg40+21RNmEClZ0fivTIX+k=").
%% -define(YC_PATH, "https://ipayfront.cloudwalk.cn/api/transaction/front/pay/gateway").

pay(wwt, Merchant, MchntCd, PayCode, Moneny) ->
    ?DEBUG("pay wwt: merchant ~p, MchntCd ~p, PayCode ~p, Moneny ~p",
	   [Merchant, MchntCd, PayCode, Moneny]),
    PayCodeLen = erlang:size(PayCode),
    case PayCodeLen < ?PAY_SCAN_CODE_MIN_LEN
    orelse PayCodeLen > ?PAY_SCAN_CODE_MAX_LEN of 
	true ->
	    {error, invalid_pay_scan_code_len, PayCode};
	false ->
	    Path = "http://api.zhihuishangjie.cn/api/v2/micropay",
	    Version = "1.0",
	    InsCd = "6f606eb525ffdc56",
	    %% MchntCd = "10001",
	    TermId = "",
	    MchntOrder = ?inventory_sn:sn(pay_order_sn, Merchant),
	    %% OrderAmt = "0.01",
	    %% AuthCode = "134650742072170576",
	    Random = ?utils:random(1000),

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
	    ?DEBUG("Body ~p", [Body]),
	    ?DEBUG("JsonBody ~p", [JsonBody]), 
	    case 
		httpc:request(
		  post,
		  {?to_s(Path) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
		   [], [], JsonBody}, [], []) of
		%% {ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
		{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
		    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
		    {struct, Result} = mochijson2:decode(Reply), 
		    ?DEBUG("pay result ~p", [Result]),
		    Code = ?v(<<"code">>, Result),
		    Info = ?v(<<"msg">>, Result),
		    ?DEBUG("code ~p, msg ~ts", [Code, Info]), 
		    case Code of
			0 ->
			    {struct, Data} = ?v(<<"data">>, Result),
			    OrderType = ?v(<<"order_type">>, Data),
			    Balance = ?v(<<"actual_amount">>, Data), 
			    {ok, ?PAY_SCAN_SUCCESS, MchntOrder, case OrderType of
								     <<"WECHAT">> -> 0;
								     <<"ALIPAY">> -> 1;
								     %% _ -> 99
								    %% default alipay
								    _ -> 1
								    end, Balance};
			-1 ->
			    {error, ?PAY_SCAN_UNKOWN, MchntOrder}; 
			_ ->
			    {error, Code, MchntOrder}
		    end;
		{error, Reason} ->
		    ?INFO("pay sacn send http failed, Reason ~p", [Reason]),
		    {error, pay_http_failed, Reason}
	    end
    end .

pay(wwt_query, MchntCd, MchntOrder) ->
    Path = "http://api.zhihuishangjie.cn/api/v2/commonQuery",
    Version = "1.0",
    InsCd = "6f606eb525ffdc56", 
    Random = ?utils:random(1000),
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
	{ok, {{"HTTP/1.1", 200, _}, Head, Reply}} ->
	    ?DEBUG("Head ~p, Reply ~ts", [Head, Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("query pay order_no ~p with result:~p", [MchntOrder, Result]),
	    Code = ?v(<<"code">>, Result),
	    Info = ?v(<<"msg">>, Result),
	    ?DEBUG("code ~p, msg ~ts", [Code, Info]),
	    
	    case Code of
		0 ->
		    {struct, Data} = ?v(<<"data">>, Result),
		    OrderType = ?v(<<"order_type">>, Data),
		    Balance = ?v(<<"actual_amount">>, Data),
		    State = case ?v(<<"trans_stat">>, Data) of
				<<"SUCCESS">> -> ?PAY_SCAN_SUCCESS;
				<<"PAYERROR">> -> ?PAY_SCAN_FAILED; 
				<<"USERPAYING">> -> ?PAY_SCAN_PAYING;
				<<"REFUND">> -> ?PAY_SCAN_REFUND;
				<<"REFUND_SUCCESS">> -> ?PAY_SCAN_REFUND_SUCCESS;
				<<"REFUND_FAIL">> -> ?PAY_SCAN_REFUND_FAILED 
			    end,
		    {ok, State, case OrderType of
				    <<"WECHAT">> -> 0;
				    <<"ALIPAYE">> -> 1;
				    %% _ -> 9999
				    _ ->1
				end, Balance};
		_ -> {error, Code, MchntOrder}
	    end; 
	{error, Reason} ->
	    ?INFO("sms send http failed, Reason ~p", [Reason]),
	    {error, check_pay_http_failed, Reason}
    end.


pay_yc(yc, Merchant, MchntCd, PayCode, Moneny) ->
    ?DEBUG("pay yc: merchant ~p, MchntCd ~p, PayCode ~p, Moneny ~p",
	   [Merchant, MchntCd, PayCode, Moneny]),
    PayCodeLen = erlang:size(PayCode),
    case PayCodeLen < ?PAY_SCAN_CODE_MIN_LEN
	orelse PayCodeLen > ?PAY_SCAN_CODE_MAX_LEN of 
	true ->
	    {error, invalid_pay_scan_code_len, PayCode};
	false ->
	    %% Path = "https://ipayfront.cloudwalk.cn/api/transaction/front/pay/gateway",
	    %% Service = "unified.trade.micropay",
	    %% MchId = "800310000015826",
	    OutTradeNo = pack_sn(?to_s(?inventory_sn:sn(pay_order_sn, Merchant))),
	    GoodDesc = "DaTangTongYong",
	    TotalFee = case is_float(Moneny) of
	    		   true ->
	    		       erlang:float_to_list((?to_i(Moneny) * 100), [{decimals, 0}]);
	    		   false ->
	    		       ?to_i(Moneny) * 100
	    	       end,
	    ?DEBUG("total fee ~p", [TotalFee]),
	    MchCreateIp = ?YC_AGENT_IP,
	    AuthCode = PayCode,
	    AgentNo = ?YC_AGENT,
	    Token = ?YC_AGENT_KEY,
	    Random = ?utils:random(1000), 
	    S = 
		%% lists:sort(
		  [
		   lists:concat(["agentNo=", ?to_s(AgentNo), "&"]),
		   lists:concat(["auth_code=", ?to_s(AuthCode), "&"]),
		   lists:concat(["body=", ?to_s(GoodDesc), "&"]),
		   lists:concat(["mch_create_ip=", ?to_s(MchCreateIp), "&"]),
		   lists:concat(["mch_id=", ?to_s(MchntCd), "&"]) ,
		   lists:concat(["nonce_str=", Random, "&"]),
		   lists:concat(["out_trade_no=", OutTradeNo, "&"]), 
		   lists:concat(["service=", ?YC_PAY_SERVICE, "&"]),
		   lists:concat(["total_fee=", ?to_s(TotalFee), "&"]),
		   lists:concat(["sign_token=", ?to_s(Token)])
		  ],
		%% ),
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

	    Body = [{<<"service">>, ?to_b(?YC_PAY_SERVICE)},
		    {<<"mch_id">>, ?to_b(MchntCd)},
		    %% {<<"mchnt_cd">>, ?to_b(MchntCd)},
		    {<<"out_trade_no">>, ?to_b(OutTradeNo)},
		    {<<"agentNo">>, ?to_b(AgentNo)},
		    {<<"body">>, ?to_b(GoodDesc)},
		    {<<"total_fee">>, ?to_b(TotalFee)},
		    {<<"mch_create_ip">>, ?to_b(MchCreateIp)},
		    {<<"auth_code">>, ?to_b(AuthCode)},
		    %% {<<"token">>, ?to_b(AuthCode)},
		    {<<"nonce_str">>, ?to_b(Random)},
		    {<<"sign">>, ?to_b(SignMD5)}],

	    JsonBody = ejson:encode({Body}),
	    ?DEBUG("Body ~p", [Body]),
	    ?DEBUG("JsonBody ~p", [JsonBody]),

	    case 
		httpc:request(
		  post,
		  {?to_s(?YC_PATH) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
		   [], "application/json;charset=utf-8", JsonBody}, [], []) of
		%% {ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
		{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
		    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
		    {struct, Result} = mochijson2:decode(Reply), 
		    ?DEBUG("pay result ~p", [Result]),
		    case ?v(<<"code">>, Result) of
			undefined ->
			    SysCode = ?v(<<"sys_code">>, Result),
			    SysMsg  = ?v(<<"sys_msg">>, Result),
			    ?DEBUG("merchant ~p, sys_code: ~p, sys_msg: ~ts",
				   [Merchant, SysCode, SysMsg]), 
			    BizCode = ?v(<<"biz_code">>, Result),
			    PayResult = ?v(<<"pay_result">>, Result),
			    %% ?DEBUG("biz_code ~p, pay_result ~p", [BizCode, PayResult]),
			    
			    <<PayCodePrefix:2/binary, _/binary>> = PayCode,
			    {PayType, _} = get_pay_type(by_prefix, PayCodePrefix), 
				case ?v(<<"need_query">>, Result) of
				    <<"Y">> ->
					%% ?DEBUG("PayType ~p", [PayType]),
					%% {ok, ?PAY_SCAN_NEED_QUERY, OutTradeNo, PayType}
					{ok, ?PAY_SCAN_UNKOWN, OutTradeNo, PayType};
				    _ ->
					case SysCode =:= <<"0">>
					    andalso BizCode =:= <<"0">>
					    andalso PayResult =:= <<"0">> of
					    true ->
						{ok, ?PAY_SCAN_SUCCESS, OutTradeNo, PayType};
					    false ->
						BizMsg = ?v(<<"biz_msg">>, Result),
						?INFO("pay scan failed:"
						      "merchant ~p, sys_code ~p, sys_msg ~ts, biz_code ~p,"
						      "BizMsg ~ts, s ~p",
						      [Merchant, SysCode, SysMsg, BizCode, BizMsg, S]),
						{error, ?PAY_SCAN_FAILED, BizCode}
					end
				end; 
			CheckCode ->
		    Msg = ?v(<<"message">>, Result),
			    ?DEBUG("code ~p, msg ~p", [CheckCode, Msg]),
			    ?INFO("pay sacn http transe failed,"
				  "merchant ~p, Code ~p, msg ~ts", [Merchant, CheckCode, Msg]),
			    {error, pay_http_trans_failed, CheckCode}
		    end; 
		{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
		    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
		    ?INFO("pay sacn http retun failed, merchant ~p, Reason ~p", [Merchant, HttpCode]),
		    {error, pay_http_failed, HttpCode};
		{error, Reason} ->
		    ?INFO("pay sacn send http failed, merchant ~p, Reason ~p", [Merchant, Reason]),
		    {error, pay_http_failed, Reason}
	    end
    end .

pay_yc(query_yc, Merchant, MchntCd, MchntOrder) ->
    %% Path = "https://ipayfront.cloudwalk.cn/api/transaction/front/pay/gateway",
    %% Service = "unified.trade.query",
    %% MchId = "800310000015826",
    AgentNo = ?YC_AGENT,
    Token = ?YC_AGENT_KEY,
    Random = ?utils:random(1000), 
    S = [lists:concat(["agentNo=", AgentNo, "&"]),
	 lists:concat(["mch_id=", ?to_s(MchntCd), "&"]) ,
	 lists:concat(["nonce_str=", Random, "&"]),
	 lists:concat(["out_trade_no=", ?to_s(MchntOrder), "&"]), 
	 lists:concat(["service=", ?YC_PAY_QUERY_SERVICE, "&"]),
	 lists:concat(["sign_token=", ?to_s(Token)])
	],
    ?DEBUG("S ~ts", [S]), 
    MD5 = crypto:hash(md5, unicode:characters_to_list(S, utf8)),
    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    
    Body = [{<<"service">>, ?to_b(?YC_PAY_QUERY_SERVICE)},
	    {<<"mch_id">>, ?to_b(MchntCd)},
	    {<<"out_trade_no">>, ?to_b(MchntOrder)},
	    {<<"agentNo">>, ?to_b(AgentNo)},
	    {<<"nonce_str">>, ?to_b(Random)},
	    {<<"sign">>, ?to_b(SignMD5)}], 
    JsonBody = ejson:encode({Body}),
    ?DEBUG("JsonBody ~p", [JsonBody]),

    case 
	httpc:request(
	  post,
	  {?to_s(?YC_PATH) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
	   [], "application/json;charset=utf-8", JsonBody}, [], []) of
	%% {ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
	    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
	    {struct, Result} = mochijson2:decode(Reply), 
	    ?DEBUG("pay result ~p", [Result]),
	    case ?v(<<"code">>, Result) of
		undefined ->
		    SysCode = ?v(<<"sys_code">>, Result),
		    SysMsg  = ?v(<<"sys_msg">>, Result),
		    ?DEBUG("sys_code: ~p, sys_msg: ~ts", [SysCode, SysMsg]), 
		    BizCode = ?v(<<"biz_code">>, Result),
		    PayResult = ?v(<<"pay_result">>, Result),
		    ?DEBUG("biz_code ~p, pay_result ~p", [BizCode, PayResult]),
		    case SysCode =:= <<"0">>
			andalso BizCode =:= <<"0">> of
			true ->
			    TransState = ?v(<<"trade_state">>,Result),
			    ?DEBUG("TransState ~p", [TransState]),
			    State = 
				case TransState of
				    <<"SUCCESS">> -> ?PAY_SCAN_SUCCESS;
				    <<"PAYERROR">> -> ?PAY_SCAN_FAILED;
				    <<"USERPAYING">> -> ?PAY_SCAN_PAYING;
				    <<"REFUND">> -> ?PAY_SCAN_REFUND;
				    <<"NOTPAY">> -> ?PAY_SCAN_NOTPAY; 
				    <<"CLOSED">> -> ?PAY_SCAN_CLOSED;
				    <<"REVOKED/REVERSE">> -> ?PAY_SCAN_REVOKED
				end,
			    {ok, State, case ?v(<<"trade_type">>, Result) of
					    <<"pay.weixin.micropay">> -> 0;
					    <<"pay.alipay.micropay">> -> 1;
					    <<"pay.unionpay.micropay">> -> 6;
					    _ -> 1
					end, 
			     case TransState of
				 <<"SUCCESS">> ->
				     ?to_i(?v(<<"total_fee">>, Result, 0)) / 100;
				 _ -> 0
			     end};
			false ->
			    ?INFO("pay yc trans failed: merchant~p,  sys_code ~p, biz_code ~p",
				  [Merchant, SysCode, BizCode]),
			    {error, pay_scan_failed, SysCode}
		    end; 
		CheckCode ->
		    Msg = ?v(<<"message">>, Result),
		    ?DEBUG("code ~p, msg ~p", [CheckCode, Msg]),
		    ?INFO("pay sacn send http failed, Code ~p, Msg ~ts", [CheckCode, Msg]),
		    {error, pay_http_trans_failed, CheckCode}
	    end; 
	{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
	    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
	    ?INFO("pay sacn http retun failed, Reason ~p", [HttpCode]),
	    {error, pay_http_failed, HttpCode};
	{error, Reason} ->
	    ?INFO("pay sacn send http failed, Reason ~p", [Reason]),
	    {error, pay_http_failed, Reason}
    end.

pay_sx(sx, Merchant, MchntCd, PayOrder, PayTime, PayTerm, PayKey, PayCode, Moneny) ->
    ?DEBUG("pay sx: merchant ~p, MchntCd ~p, PayCode ~p, Moneny ~p",
	   [Merchant, MchntCd, PayCode, Moneny]),
    PayCodeLen = erlang:size(PayCode),
    case PayCodeLen < ?PAY_SCAN_CODE_MIN_LEN
	orelse PayCodeLen > ?PAY_SCAN_CODE_MAX_LEN of 
	true ->
	    {error, invalid_pay_scan_code_len, PayCode};
	false -> 
	    <<PayCodePrefix:2/binary, _/binary>> = ?to_b(PayCode),
	    {_, PayMode} = get_pay_type (by_prefix, PayCodePrefix), 
	    S = lists:sort(
		  [{<<"opSys">>, ?to_b(0)},
		   {<<"orgNo">>, ?to_b(?SX_ORGANIZE)},
		   {<<"merchantNo">>, ?to_b(MchntCd)},
		   {<<"terminalNo">>, ?to_b(PayTerm)},
		   {<<"outTradeNo">>, ?to_b(PayOrder)},
		   {<<"tradeTime">>, ?to_b(PayTime)},
		   {<<"signType">>, ?to_b("MD5")},
		   {<<"version">>, ?to_b("V1.0.0")},

		   {<<"amount">>, ?to_b(1)},
		   {<<"totalAmount">>, ?to_b(1)},
		   {<<"authCode">>, ?to_b(PayCode)},
		   {<<"payMode">>, ?to_b(PayMode)},
		   {<<"subject">>, ?to_b(<<"DTGOOD">>)}
		  ]),
	    
	    ?DEBUG("S ~p", [S]),
	    Params = lists:foldr(
	      fun({_K, V}, Acc)->
		      <<V/binary, Acc/binary>>
	      end, <<>>, S),
	    ?DEBUG("Params ~p", [Params]),
	    
	    MD5 = crypto:hash(md5, unicode:characters_to_list(<<Params/binary, PayKey/binary>>, utf8)),
	    %% ?DEBUG("MD5 ~p", [MD5]),
	    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
	    ?DEBUG("SingMD5 ~p", [SignMD5]),
	    
	    Body = S ++ [{<<"signValue">>, ?to_b(SignMD5)}],
	    JsonBody = ejson:encode({Body}),
	    ?DEBUG("Body ~p", [Body]),
	    ?DEBUG("JsonBody ~p", [JsonBody]),

	    case 
		httpc:request(
		  post,
		  {?SX_PATH ++ "/mapi/pay/b2c",
		   [], "application/json;charset=utf-8", JsonBody}, [], []) of
		{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
		    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
		    {struct, Info} = mochijson2:decode(Reply), 
		    ?DEBUG("pay result ~p", [Info]),
		    ReturnCode = ?v(<<"returnCode">>, Info),
		    Msg = ?v(<<"message">>, Info),
		    case ReturnCode of 
			<<"000000">> ->
			    TradeState = ?v(<<"result">>, Info), 
			    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    case TradeState of
				<<"S">> ->
				    {ok, ?PAY_SCAN_SUCCESS, PayOrder, PayMode};
				<<"F">> ->
				    {error, ?PAY_SCAN_FAILED, PayOrder, PayMode};
				<<"A">> ->
				    {error, ?PAY_SCAN_PAYING, PayOrder, PayMode};
				<<"Z">> ->
				    {error, ?PAY_SCAN_UNKOWN, PayOrder, PayMode};
				<<"C">> ->
				    {error, ?PAY_SCAN_CLOSED, PayOrder, PayMode}
			    end;
			_ ->
			    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    ?INFO("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    {error, ?PAY_SCAN_FAILED, ReturnCode, Msg}
		    end; 
		{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
		    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
		    ?INFO("pay sacn http retun failed, merchant ~p, Reason ~p", [Merchant, HttpCode]),
		    {error, pay_http_failed, HttpCode};
		{error, Reason} ->
		    ?INFO("pay sacn send http failed, merchant ~p, Reason ~p", [Merchant, Reason]),
		    {error, pay_http_failed, Reason}
	    end
    end.

pay_sx(query_sx, Merchant, MchntCd, PayOrder, PayTime, PayTerm, PayKey) ->
    ?DEBUG("query_sx: merchant ~p, MchntCd ~p, PayOrder ~p, PayTime ~p, PayTerm, PayKey",
	   [Merchant, MchntCd, PayOrder, PayTime, PayTerm, PayKey]),

    TradeTime = ?utils:current_time(localtime),
    S = lists:sort(
	  [{<<"opSys">>, ?to_b(0)},
	   {<<"orgNo">>, ?to_b(?SX_ORGANIZE)},
	   {<<"merchantNo">>, ?to_b(MchntCd)},
	   {<<"terminalNo">>, ?to_b(PayTerm)},
	   {<<"outTradeNo">>, ?to_b(PayOrder)},
	   {<<"tradeTime">>, ?to_b(TradeTime)},
	   {<<"signType">>, ?to_b("MD5")},
	   {<<"version">>, ?to_b("V1.0.0")},
	   
	   {<<"queryNo">>, ?to_b(PayOrder)},
	   {<<"queryDate">>, ?to_b(PayTime)}
	  ]),

    ?DEBUG("S ~p", [S]),
    Params = lists:foldr(
	       fun({_K, V}, Acc)->
		       <<V/binary, Acc/binary>>
	       end, <<>>, S),
    ?DEBUG("Params ~p", [Params]),

    %% MD5 = crypto:hmac(md5, ?to_b(TradeKey), unicode:characters_to_list(Params, utf8)),
    MD5 = crypto:hash(md5, unicode:characters_to_list(<<Params/binary, PayKey/binary>>, utf8)),
    %% ?DEBUG("MD5 ~p", [MD5]),
    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    ?DEBUG("SingMD5 ~p", [SignMD5]),

    Body = S ++ [{<<"signValue">>, ?to_b(SignMD5)}],
    JsonBody = ejson:encode({Body}),
    ?DEBUG("Body ~p", [Body]),
    ?DEBUG("JsonBody ~p", [JsonBody]),

    case 
	httpc:request(
	  post,
	  {?SX_PATH ++ "/mapi/pay/orderQuery",
	   [], "application/json;charset=utf-8", JsonBody}, [], []) of
	{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
	    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
	    {struct, Info} = mochijson2:decode(Reply), 
	    ?DEBUG("pay result ~p", [Info]),
	    ReturnCode = ?v(<<"returnCode">>, Info),
	    Msg = ?v(<<"message">>, Info),
	    case ReturnCode of 
		<<"000000">> ->
		    TradeState = ?v(<<"result">>, Info), 
		    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    {PayMode, _} = get_pay_type(by_name, ?to_b(?v(<<"payMode">>, Info))),
		    {ok,
		     case TradeState of
			 <<"S">> ->
			     ?PAY_SCAN_SUCCESS;
			 <<"F">> ->
			     ?PAY_SCAN_FAILED;
			 <<"A">> ->
			     ?PAY_SCAN_PAYING;
			 <<"Z">> ->
			     ?PAY_SCAN_UNKOWN;
			 <<"C">> ->
			     ?PAY_SCAN_CLOSED
		     end,
		     PayMode,
		     ?to_i(?v(<<"totalAmount">>, Info, 0)) / 100
		    }; 
		_ ->
		    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    ?INFO("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    {error, ?PAY_SCAN_FAILED, ReturnCode, Msg}
	    end; 
	{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
	    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
	    ?INFO("pay sacn http retun failed, merchant ~p, Reason ~p", [Merchant, HttpCode]),
	    {error, pay_http_failed, HttpCode};
	{error, Reason} ->
	    ?INFO("pay sacn send http failed, merchant ~p, Reason ~p", [Merchant, Reason]),
	    {error, pay_http_failed, Reason}
    end.


pay_test_sx(sx, Merchant, PayCode, Moneny) ->
    ?DEBUG("pay sx: merchant ~p, PayCode ~p, Moneny ~p", [Merchant, PayCode, Moneny]),
    PayCodeLen = erlang:size(?to_b(PayCode)),
    case PayCodeLen < ?PAY_SCAN_CODE_MIN_LEN
	orelse PayCodeLen > ?PAY_SCAN_CODE_MAX_LEN of 
	true ->
	    {error, invalid_pay_scan_code_len, PayCode};
	false ->
	    %% Path = "https://ipayfront.cloudwalk.cn/api/transaction/front/pay/gateway",
	    %% Service = "unified.trade.micropay",
	    %% MchId = "800310000015826",
	    
	    OutTradeNo = pack_sn(?to_s(?inventory_sn:sn(pay_order_sn, Merchant))),

	    OrgNo = "8028",
	    MchntCd = "80280106",
	    TermId = "QR802804048",
	    TradeKey = <<"80C2D8BDDB692B06F6B109E1A3A18D72">>,
	    Path = "http://test-gateway.dbs12580.com",
	    Timestamp = ?utils:current_time(localtime),
	    
	    <<PayCodePrefix:2/binary, _/binary>> = ?to_b(PayCode), 
	    {_, PayMode} = get_pay_type (by_prefix, PayCodePrefix),

	    S = lists:sort(
		  [{<<"opSys">>, ?to_b(0)},
		   {<<"orgNo">>, ?to_b(OrgNo)},
		   {<<"merchantNo">>, ?to_b(MchntCd)},
		   {<<"terminalNo">>, ?to_b(TermId)},
		   {<<"outTradeNo">>, ?to_b(OutTradeNo)},
		   {<<"tradeTime">>, ?to_b(Timestamp)},
		   {<<"signType">>, ?to_b("MD5")},
		   {<<"version">>, ?to_b("V1.0.0")},

		   {<<"amount">>, ?to_b(Moneny)},
		   {<<"totalAmount">>, ?to_b(Moneny)},
		   {<<"authCode">>, ?to_b(PayCode)},
		   {<<"payMode">>, ?to_b(PayMode)},
		   {<<"subject">>, ?to_b(<<"DTGOOD">>)}
		  ]),

	    ?DEBUG("S ~p", [S]),
	    Params = lists:foldr(
		       fun({_K, V}, Acc)->
			       <<V/binary, Acc/binary>>
		       end, <<>>, S),
	    ?DEBUG("Params ~p", [Params]),

	    %% MD5 = crypto:hmac(md5, ?to_b(TradeKey), unicode:characters_to_list(Params, utf8)),
	    MD5 = crypto:hash(md5, unicode:characters_to_list(<<Params/binary, TradeKey/binary>>, utf8)),
	    ?DEBUG("MD5 ~p", [MD5]),
	    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
	    ?DEBUG("SingMD5 ~p", [SignMD5]),

	    Body = S ++ [{<<"signValue">>, ?to_b(SignMD5)}],
	    JsonBody = ejson:encode({Body}),
	    ?DEBUG("Body ~p", [Body]),
	    ?DEBUG("JsonBody ~p", [JsonBody]),

	    case 
		httpc:request(
		  post,
		  {Path ++ "/mapi/pay/b2c",
		   [], "application/json;charset=utf-8", JsonBody}, [], []) of
		{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
		    ?DEBUG("Head ~n~p, Reply ~ts", [_Head, Reply]),
		    {struct, Info} = mochijson2:decode(Reply), 
		    ?DEBUG("pay result ~p", [Info]),
		    ReturnCode = ?v(<<"returnCode">>, Info),
		    Msg = ?v(<<"message">>, Info),
		    case ReturnCode of 
			<<"000000">> ->
			    TradeState = ?v(<<"result">>, Info), 
			    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    case TradeState of
				<<"S">> ->
				    {ok, ?PAY_SCAN_SUCCESS, OutTradeNo, PayMode};
				<<"F">> ->
				    {error, ?PAY_SCAN_FAILED, OutTradeNo, PayMode};
				<<"A">> ->
				    {error, ?PAY_SCAN_PAYING, OutTradeNo, PayMode};
				<<"Z">> ->
				    {error, ?PAY_SCAN_UNKOWN, OutTradeNo, PayMode};
				<<"C">> ->
				    {error, ?PAY_SCAN_CLOSED, OutTradeNo, PayMode}
			    end;
			_ ->
			    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    ?INFO("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
			    {error, ?PAY_SCAN_FAILED, ReturnCode, Msg}
		    end; 
		{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
		    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
		    ?INFO("pay sacn http retun failed, merchant ~p, Reason ~p", [Merchant, HttpCode]),
		    {error, pay_http_failed, HttpCode};
		{error, Reason} ->
		    ?INFO("pay sacn send http failed, merchant ~p, Reason ~p", [Merchant, Reason]),
		    {error, pay_http_failed, Reason}
	    end
    end;

pay_test_sx(query_sx, Merchant, PayOrder, PayTime) ->
    ?DEBUG("query_sx: merchant ~p, PayOrder ~p, PayTime ~p", [Merchant, PayOrder, PayTime]),

    OrgNo = "8028",
    MchntCd = "80280106",
    TermId = "QR802804048",
    TradeKey = <<"80C2D8BDDB692B06F6B109E1A3A18D72">>,
    Path = "http://test-gateway.dbs12580.com",
    TradeTime = ?utils:current_time(localtime),
    
    S = lists:sort(
	  [{<<"opSys">>, ?to_b(0)},
	   {<<"orgNo">>, ?to_b(OrgNo)},
	   {<<"merchantNo">>, ?to_b(MchntCd)},
	   {<<"terminalNo">>, ?to_b(TermId)},
	   {<<"outTradeNo">>, ?to_b(PayOrder)},
	   {<<"tradeTime">>, ?to_b(TradeTime)},
	   {<<"signType">>, ?to_b("MD5")},
	   {<<"version">>, ?to_b("V1.0.0")},

	   {<<"queryNo">>, ?to_b(PayOrder)},
	   {<<"queryDate">>, ?to_b(PayTime)}
	  ]),

    ?DEBUG("S ~p", [S]),
    Params = lists:foldr(
	       fun({_K, V}, Acc)->
		       <<V/binary, Acc/binary>>
	       end, <<>>, S),
    ?DEBUG("Params ~p", [Params]),

    %% MD5 = crypto:hmac(md5, ?to_b(TradeKey), unicode:characters_to_list(Params, utf8)),
    MD5 = crypto:hash(md5, unicode:characters_to_list(<<Params/binary, TradeKey/binary>>, utf8)),
    ?DEBUG("MD5 ~p", [MD5]),
    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    ?DEBUG("SingMD5 ~p", [SignMD5]),

    Body = S ++ [{<<"signValue">>, ?to_b(SignMD5)}],
    JsonBody = ejson:encode({Body}),
    ?DEBUG("Body ~p", [Body]),
    ?DEBUG("JsonBody ~p", [JsonBody]),

    case 
	httpc:request(
	  post,
	  {Path ++ "/mapi/pay/orderQuery",
	   [], "application/json;charset=utf-8", JsonBody}, [], []) of
	{ok, {{"HTTP/1.1", 200, _}, _Head, Reply}} -> 
	    ?DEBUG("Head ~p, Reply ~ts", [_Head, Reply]),
	    {struct, Info} = mochijson2:decode(Reply), 
	    ?DEBUG("pay result ~p", [Info]),
	    ReturnCode = ?v(<<"returnCode">>, Info),
	    Msg = ?v(<<"message">>, Info),
	    case ReturnCode of 
		<<"000000">> ->
		    TradeState = ?v(<<"result">>, Info), 
		    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    {PayMode, _} = get_pay_type(by_name, ?to_b(?v(<<"payMode">>, Info))),
		    {ok,
		     case TradeState of
			    <<"S">> ->
				?PAY_SCAN_SUCCESS;
			    <<"F">> ->
				?PAY_SCAN_FAILED;
			    <<"A">> ->
				?PAY_SCAN_PAYING;
			    <<"Z">> ->
				?PAY_SCAN_UNKOWN;
			    <<"C">> ->
				?PAY_SCAN_CLOSED
			end,
		     PayMode,
		     ?to_i(?v(<<"totalAmount">>, Info, 0)) / 100
		     }; 
		_ ->
		    ?DEBUG("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    ?INFO("ReturnCode ~p, msg ~ts", [ReturnCode, Msg]),
		    {error, ?PAY_SCAN_FAILED, ReturnCode, Msg}
	    end; 
	{ok, {{"HTTP/1.1", HttpCode, _}, _Head, Reply}} ->
	    ?DEBUG("HttpCode ~p, Head ~p, Reply ~ts", [HttpCode, _Head, Reply]),
	    ?INFO("pay sacn http retun failed, merchant ~p, Reason ~p", [Merchant, HttpCode]),
	    {error, pay_http_failed, HttpCode};
	{error, Reason} ->
	    ?INFO("pay sacn send http failed, merchant ~p, Reason ~p", [Merchant, Reason]),
	    {error, pay_http_failed, Reason}
    end.
    

get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"10">>
					  orelse PayCodePrefix =:= <<"11">>
					  orelse PayCodePrefix =:= <<"12">>
					  orelse PayCodePrefix =:= <<"13">>
					  orelse PayCodePrefix =:= <<"14">>
					  orelse PayCodePrefix =:= <<"15">> ->
    {0, ?WXPAY};
get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"25">>
					  orelse PayCodePrefix =:= <<"26">>
					  orelse PayCodePrefix =:= <<"27">>
					  orelse PayCodePrefix =:= <<"28">>
					  orelse PayCodePrefix =:= <<"29">>
					  orelse PayCodePrefix =:= <<"30">> ->
    {1, ?ALIPAY};
get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"62">> ->
    {6, ?YLPAY};
get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"51">> ->
    {5, ?BESTPAY};
get_pay_type(by_prefix, _PayCodePrefix) ->
    {1, ?ALIPAY};

get_pay_type(by_name, ?WXPAY) ->
    {0, ?WXPAY};
get_pay_type(by_name, ?ALIPAY) ->
    {1, ?ALIPAY};
get_pay_type(by_name, ?YLPAY) ->
    {6, ?YLPAY};
get_pay_type(by_name, ?BESTPAY) ->
    {5, ?BESTPAY};
get_pay_type(by_name, _) ->
    {1, ?ALIPAY}. 
    
pack_sn(String) when length(String) =:= ?MIN_SN_LEN ->
    "M" ++ String;
pack_sn(String) when length(String) > ?MIN_SN_LEN ->
    String;
pack_sn(String) when length(String) < ?MIN_SN_LEN ->
    pack_sn(String, "0").


pack_sn(String, Pack) -> 
    SS = ?to_string(String),
    pack_sn(SS, ?to_string(Pack), length(SS)).
pack_sn(String, _Pack, ?MIN_SN_LEN) -> 
    "M" ++ String;
pack_sn(String, Pack, Length) ->
    pack_sn(Pack ++ String, Pack, Length + length(Pack)).
