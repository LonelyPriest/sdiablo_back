-module(diablo_pay).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([pay/3, pay/5]).
-export([pay_yc/4, pay_yc/5]).

-define(YC_AGENT, "A103373").
-define(YC_AGENT_KEY, "7/ZbQ08OhITuruxv1qqCMiEOopM38bEoHJuFicbczTc=").
-define(YC_AGENT_IP, "120.24.39.174").
-define(YC_PATH, "https://apifacepay.cloudwalk.cn/api/transaction/front/pay/gateway").
-define(YC_PAY_SERVICE, "unified.trade.micropay").
-define(YC_PAY_QUERY_SERVICE, "unified.trade.query").

pay(wwt, Merchant, MchntCd, PayCode, Moneny) ->
    ?DEBUG("pay wwt: merchant ~p, MchntCd ~p, PayCode ~p, Moneny ~p",
	   [Merchant, MchntCd, PayCode, Moneny]),
    case erlang:size(PayCode) =/= ?PAY_SCAN_CODE_LEN of 
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
    case erlang:size(PayCode) =/= ?PAY_SCAN_CODE_LEN of 
	true ->
	    {error, invalid_pay_scan_code_len, PayCode};
	false ->
	    %% Path = "https://ipayfront.cloudwalk.cn/api/transaction/front/pay/gateway",
	    %% Service = "unified.trade.micropay",
	    %% MchId = "800310000015826",
	    OutTradeNo = "1000" ++ ?to_s(?inventory_sn:sn(pay_order_sn, Merchant)),
	    GoodDesc = "test",
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
			    ?DEBUG("biz_code ~p, pay_result ~p", [BizCode, PayResult]),
			    
			    <<PayCodePrefix:2/binary, _/binary>> = PayCode,
			    PayType = get_pay_type(by_prefix, PayCodePrefix), 
				case ?v(<<"need_query">>, Result) of
				    <<"Y">> ->
					?DEBUG("PayType ~p", [PayType]),
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
						      "merchant ~p, sys_code ~p, biz_code ~p,"
						      "BizMsg ~ts",
						      [Merchant, SysCode, BizCode, BizMsg]),
						{error, ?PAY_SCAN_FAILED, BizCode}
					end
				end; 
			CheckCode ->
		    Msg = ?v(<<"message">>, Result),
			    ?DEBUG("code ~p, msg ~p", [CheckCode, Msg]),
			    ?INFO("pay sacn http transe failed,"
				  "merchant ~p, Code ~p, Msg ~ts", [Merchant, CheckCode, Msg]),
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
	 lists:concat(["out_trade_no=", MchntOrder, "&"]), 
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
				 <<"SUCCESS">> -> ?v(<<"total_fee">>, Result);
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
    

get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"10">>
					  orelse PayCodePrefix =:= <<"11">>
					  orelse PayCodePrefix =:= <<"12">>
					  orelse PayCodePrefix =:= <<"13">>
					  orelse PayCodePrefix =:= <<"14">>
					  orelse PayCodePrefix =:= <<"15">> ->
    0;
get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"25">>
					  orelse PayCodePrefix =:= <<"26">>
					  orelse PayCodePrefix =:= <<"27">>
					  orelse PayCodePrefix =:= <<"28">>
					  orelse PayCodePrefix =:= <<"29">>
					  orelse PayCodePrefix =:= <<"30">> ->
    1;
get_pay_type(by_prefix, PayCodePrefix) when PayCodePrefix =:= <<"62">> ->
    6;
get_pay_type(by_prefix, _PayCodePrefix) ->
    1.    
