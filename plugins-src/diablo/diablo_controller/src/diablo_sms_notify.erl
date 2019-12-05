-module(diablo_sms_notify).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([sms_notify/2, sign/1, sms/1, sms/3, sms/4]).

sms_notify(Merchant, {Shop, Phone, Action, Money, RetailerBalance, Score}) ->
    ?DEBUG("sms_notify: merchants ~p, shop ~p, phone ~p, action ~p, money ~p"
	   ", rbalance ~p score ~p",
	   [Merchant, Shop, Phone, Action, Money, RetailerBalance, Score]),
    try
	case ?w_user_profile:get(merchant, Merchant) of
	    {ok, []} -> ?err(sms_rate_not_found, Merchant);
	    {ok, MerchantInfo} ->
		?DEBUG("MerchantInfo ~p", [MerchantInfo]),
		MerchantBalance = ?v(<<"balance">>, MerchantInfo),

		case ?w_user_profile:get(sms_rate, Merchant) of
		    {ok, []} -> ?err(sms_rate_not_found, Merchant);
		    {ok, SMSRate} ->
			Rate = ?v(<<"rate">>, SMSRate),
			?DEBUG("sms rate ~p, MerchantBalance ~p", [Rate, MerchantBalance]),
			case Rate > MerchantBalance of
			    true  -> ?err(sms_not_enought_blance, Merchant);
			    false ->
				case sms_once(aliqin,
					      Merchant,
					      {Shop, Phone, Action, Money, RetailerBalance, Score}) of
				    {ok, {sms_send, Phone}} ->
					Sql = "update merchants set balance=balance-" ++ ?to_s(Rate)
					    ++ ", sms_send=sms_send+1"
					    ++ " where id=" ++ ?to_s(Merchant),
					case ?sql_utils:execute(write, Sql, Merchant) of
					    {ok, Merchant} ->
						?w_user_profile:update(merchant, Merchant),
						{0, Merchant};
					    _Error ->
						?sql_utils:execute(write, Sql, Merchant),
						?w_user_profile:update(merchant, Merchant),
						{0, Merchant}
					end;
				    {error, {sms_center_not_found, Merchant}} ->
					?err(sms_center_not_found, Merchant);
				    {error, _} ->
					?err(sms_send_failed, Merchant)
				end
			end
		end
	end
    catch
	_:_ ->
	    ?err(sms_send_failed, Merchant)
    end.
	    
sms_once(aliqin, Merchant, {Shop, Phone, Action, Money, Balance, Score}) ->
    NewBalance = ?f_print:clean_zero(Balance),
    case ?w_user_profile:get(sms_center, Merchant) of
	{ok, []} -> {error, {sms_center_not_found, Merchant}};
	{ok, Center} ->
	    URL       = ?to_s(?v(<<"url">>, Center)),
	    AppKey    = ?to_s(?v(<<"app_key">>, Center)),
	    AppSecret = ?to_s(?v(<<"app_secret">>, Center)),

	    SMSSignName   = ?to_s(?v(<<"sms_sign_name">>, Center)),
	    SMSSignMethod = ?to_s(?v(<<"sms_sign_method">>, Center)),
	    SMSSendMethod = ?to_s(?v(<<"sms_send_method">>, Center)),
	    SMSTemplate   = ?to_s(?v(<<"sms_template">>, Center)),
	    SMSType       = ?to_s(?v(<<"sms_type">>, Center)),
	    SMSVersion    = ?to_s(?v(<<"sms_version">>, Center)),

	    Timestamp = ?utils:current_time(format_localtime),

	    SMSParams = ?to_s(ejson:encode({[{<<"shop">>, Shop},
					     {<<"action">>, action(Action)},
					     {<<"maction">>, action(Action)},
					     {<<"money">>, ?to_b(Money)},
					     {<<"balance">>, ?to_b(NewBalance)},
					     {<<"score">>, ?to_b(Score)}]})),

	    SortedParams = lists:sort(
			     [lists:concat(["app_key", AppKey]),
			      lists:concat(["format", "json"]),
			      lists:concat(["method", SMSSendMethod]),
			      lists:concat(["partner_id", ""]),
			      lists:concat(["rec_num", ?to_s(Phone)]),
			      lists:concat(["sign_method", SMSSignMethod]),
			      lists:concat(["sms_free_sign_name", SMSSignName]),
			      lists:concat(["sms_param", SMSParams]),
			      lists:concat(["sms_template_code", SMSTemplate]),
			      lists:concat(["sms_type", SMSType]),
			      lists:concat(["timestamp", Timestamp]),
			      lists:concat(["v", SMSVersion])]),

	    %% ?DEBUG("sorted params ~ts", [?to_b(lists:concat(SortedParams))]),

	    SS = AppSecret ++ lists:concat(SortedParams) ++ AppSecret,
	    %% ?DEBUG("ss ~ts", [?to_b(SS)]), 
	    MD5Sign = ?wifi_print:bin2hex(
			 sha1, crypto:hash(md5, unicode:characters_to_list(SS, utf8))),
	    ?DEBUG("MD5Sign ~p", [MD5Sign]),

	    Body = lists:concat(["app_key=", AppKey,
				 "&format=", "json" 
				 "&method=", SMSSendMethod,
				 "&partner_id", "",
				 "&rec_num=", ?to_s(Phone), 
				 "&sign_method=", SMSSignMethod,
				 "&sms_free_sign_name=", SMSSignName,
				 "&sms_param=", SMSParams,
				 "&sms_template_code=", SMSTemplate,
				 "&sms_type=", SMSType,
				 "&timestamp=", Timestamp,
				 "&v=", SMSVersion]), 

	    UTF8Body = unicode:characters_to_list(Body, utf8),

	    case httpc:request(
		   post, {?to_s(URL) ++ "?" ++ "sign=" ++ ?to_s(MD5Sign),
			  [], "application/x-www-form-urlencoded;charset=utf-8", UTF8Body}, [], []) of
		{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
		    ?DEBUG("Reply ~ts", [Reply]),
		    {struct, Result} = mochijson2:decode(Reply),
		    ?DEBUG("sms result ~p", [Result]),
		    [{_,
		      {struct,
		       [{<<"result">>,
			 {struct,
			  [{<<"err_code">>, Code}|_T
			   %% {<<"model">>, _Mode},
			   %% {<<"success">>, _Success}
			  ]}},
			{<<"request_id">>, _RequestId}]}}] = Result,
		    ?DEBUG("code ~p", [Code]),

		    case ?to_i(Code) == 0 of
			true -> {ok, {sms_send, Phone}};
			false ->
			    ?INFO("sms send failed phone ~p, code ~p", [Phone, Code]),
			    {error, {sms_send_failed, Code}}
		    end;
		{error, Reason} ->
		    ?INFO("sms send http failed phone ~p, Reason ~p", [Phone, Reason]),
		    {error, {http_failed, Reason}}
	    end
    end.

sms(promotion, Merchant, Phone) ->
    SMSTemplate = "SMS_167400277",
    start_sms(Merchant, Phone, SMSTemplate, []);

sms(ticket, {Merchant, Shop, Retailer, Phone}, {Balance, Count, MinEffect}) ->
    {SMSTemplate, SMSParams} = 
	case Merchant of
	    15 -> {"SMS_170835177",
		   ?to_s(ejson:encode(
			   {[{<<"m">>, ?to_b(Balance)},
			     {<<"d">>, ?to_b(Count)},
			     {<<"day">>, ?to_b(MinEffect)}
			    ]}))};
	    _ ->
		{"SMS_168285336",
		 ?to_s(ejson:encode(
			{[{<<"shop">>, Shop},
			  {<<"user">>, Retailer},
			  {<<"money">>, ?to_b(Balance)},
			  {<<"count">>, ?to_b(Count)}
			 ]}))}
	end,
    start_sms(Merchant, Phone, SMSTemplate, SMSParams);
    
sms(charge, {Merchant, Name, Phone}, Balance) ->
    {ok, SMSRate} = ?w_user_profile:get(sms_rate, Merchant),
    %% ?DEBUG("smsrate ~p", [SMSRate]), 
    Rate = ?v(<<"rate">>, SMSRate),
    LeftBalance = ?v(<<"balance">>, SMSRate, 0), 
    Count = trunc(LeftBalance + Balance) div Rate, 
    SMSTemplate   = "SMS_153716629",
    SMSParams = ?to_s(ejson:encode(
			{[{<<"name">>, <<Name/binary, <<"-">>/binary, Phone/binary>>},
			  {<<"money">>, ?to_b(Balance div 100)},
			  {<<"count">>, ?to_b(Count)} 
			 ]})),
    case send_sms(Phone, SMSTemplate, SMSParams) of
    	{ok, {sms_send, Phone}} = OK->
    	    {ok, OK};
    	{error, {sms_center_not_found, Merchant}} ->
    	    ?err(sms_center_not_found, Merchant);
    	{error, _} ->
    	    ?err(sms_send_failed, Phone)
    end.

sms(swiming, Merchant, Phone, {Shop, Action, LeftSwiming, Expire}) ->
    SMSTemplate   = "SMS_146809919",
    SMSParams = ?to_s(ejson:encode({[{<<"shop">>, Shop},
				     {<<"action">>, action(Action)},
				     {<<"lcount">>, limit_swiming(LeftSwiming)},
				     {<<"expire">>, limit_swiming(Expire)}
				    ]})),
    start_sms(Merchant, Phone, SMSTemplate, SMSParams).

start_sms(Merchant, Phone, SMSTemplate, SMSParams) ->
    case check_sms_rate(Merchant) of
	{ok, SMSRate} ->
	    %% sen sms
	    case send_sms(Phone, SMSTemplate, SMSParams) of
		{ok, {sms_send, Phone}} ->
		    Sql = "update merchants set balance=balance-" ++ ?to_s(SMSRate)
			++ ", sms_send=sms_send+1  where id=" ++ ?to_s(Merchant),
		    case ?sql_utils:execute(write, Sql, Merchant) of
			{ok, Merchant} ->
			    ?w_user_profile:update(merchant, Merchant),
			    {0, Merchant};
			_Error ->
			    ?sql_utils:execute(write, Sql, Merchant),
			    ?w_user_profile:update(merchant, Merchant),
			    {0, Merchant}
		    end;
		{error, {sms_center_not_found, Merchant}} ->
		    ?err(sms_center_not_found, Merchant);
		{error, _} ->
		    ?err(sms_send_failed, Merchant)
	    end;
	Error ->
	    Error
    end.

check_sms_rate(Merchant) ->
    try
	case ?w_user_profile:get(merchant, Merchant) of
	    {ok, []} -> ?err(sms_rate_not_found, Merchant);
	    {ok, MerchantInfo} ->
		?DEBUG("MerchantInfo ~p", [MerchantInfo]),
		MerchantBalance = ?v(<<"balance">>, MerchantInfo), 
		case ?w_user_profile:get(sms_rate, Merchant) of
		    {ok, []} -> ?err(sms_rate_not_found, Merchant);
		    {ok, SMSRate} ->
			Rate = ?v(<<"rate">>, SMSRate),
			?DEBUG("sms rate ~p, MerchantBalance ~p", [Rate, MerchantBalance]),
			case Rate > MerchantBalance of
			    true  -> ?err(sms_not_enought_blance, Merchant);
			    false -> {ok, Rate}
			end
		end
	end
    catch
	_:_ ->
	    ?err(sms_send_failed, Merchant)
    end.

sign(md5) ->
    Path = "http://gw.api.taobao.com/router/rest", 
    Key = "23581677",
    Datetime = ?utils:current_time(format_localtime), 
    FreeSignName = "钱掌柜",
    SendMethod = "alibaba.aliqin.fc.sms.num.send", 
    AppSecret = "eab38d8733faf9d5c813a639afbcfbf2",
    Params = ?to_s(ejson:encode({[{<<"shop">>, <<"myshop">>},
				  {<<"action">>, action(0)},
				  {<<"maction">>, action(0)},
				  {<<"money">>, <<"400">>},
				  {<<"balance">>, <<"1000">>},
				  {<<"score">>, <<"500">>}]})),

    AppKey = lists:concat(["app_key", Key]),
    %% Extend = lists:concat(["extend", "123456"]),
    Format = lists:concat(["format", "json"]),
    Method = lists:concat(["method", SendMethod]), 
    PartnerId = lists:concat(["partner_id", ""]),
    Phones = lists:concat(["rec_num", "18692269329"]),
    SignMethod   = lists:concat(["sign_method", "md5"]),
    SMSFreeSignName = lists:concat(["sms_free_sign_name", FreeSignName]),

    SMSParams = lists:concat(["sms_param", Params]),
    Template = lists:concat(["sms_template_code", "SMS_146809919"]), 
    SMSType  = lists:concat(["sms_type", "normal"]), 
    Timestamp = lists:concat(["timestamp", Datetime]),
    Version  =  lists:concat(["v", "2.0"]), 

    S = lists:sort([AppKey,
		    %% Extend,
		    Format,
		    Method,
		    PartnerId,
		    Phones, 
		    SignMethod,
		    SMSFreeSignName,
		    SMSParams,
		    Template,
		    SMSType,
		    Timestamp,
		    Version 
		   ]),

    ?DEBUG("S ~ts", [?to_b(lists:concat(S))]),

    SS = AppSecret ++ lists:concat(S) ++ AppSecret,

    %% SS = lists:concat(S),
    ?DEBUG("ss ~ts", [?to_b(SS)]),

    MD5 = crypto:hash(md5, unicode:characters_to_list(SS, utf8)),
    %% ?DEBUG("md5 ~p", [MD5]),

    SignMD5 = ?wifi_print:bin2hex(sha1, MD5),
    ?DEBUG("SignMD5 ~p", [SignMD5]),

    Body = lists:concat(["app_key=", Key,
			 %% "&extend=", "123456",
			 "&format=", "json" 
			 "&method=", SendMethod,
			 "&partner_id", "",
			 "&rec_num=", "18692269329", 
			 "&sign_method=", "md5",
			 "&sms_free_sign_name=", FreeSignName,
			 "&sms_param=", Params,
			 "&sms_template_code=", "SMS_36280065",
			 "&sms_type=", "normal",
			 "&timestamp=", Datetime,
			 "&v=", "2.0" 
			]), 

    UTF8Body = unicode:characters_to_list(Body, utf8),
    %% ?DEBUG("body ~ts", [?to_b(UTF8Body)]),
    httpc:request(
      post, {?to_s(Path) ++ "?" ++ "sign=" ++ ?to_s(SignMD5),
	     [], "application/x-www-form-urlencoded;charset=utf-8", UTF8Body}, [], []).

send_sms(Phone, SMSTemplate, SMSParams) ->
    ?DEBUG("send_sms: phone ~p, template ~p, params ~p", [Phone, SMSTemplate, SMSParams]),
    URL       = "http://gw.api.taobao.com/router/rest",
    AppKey    = "23581677",
    AppSecret = "eab38d8733faf9d5c813a639afbcfbf2",

    SMSSignName   = "钱掌柜",
    SMSSignMethod = "md5",
    SMSSendMethod = "alibaba.aliqin.fc.sms.num.send",
    
    SMSTemplate   = ?to_s(SMSTemplate),
    SMSType       = "normal",
    SMSVersion    = "2.0",

    Timestamp = ?utils:current_time(format_localtime),

    %% SMSParams = ?to_s(ejson:encode({[{<<"shop">>, Shop},
    %% 				     {<<"action">>, action(Action)},
    %% 				     {<<"lcount">>, ?to_b(LeftSwiming)},
    %% 				     {<<"expire">>, ?to_b(Expire)}
    %% 				    ]})),

    SortedParams = lists:sort(
		     [lists:concat(["app_key", AppKey]),
		      lists:concat(["format", "json"]),
		      lists:concat(["method", SMSSendMethod]),
		      lists:concat(["partner_id", ""]),
		      lists:concat(["rec_num", ?to_s(Phone)]),
		      lists:concat(["sign_method", SMSSignMethod]),
		      lists:concat(["sms_free_sign_name", SMSSignName]),
		      lists:concat(["sms_param", SMSParams]),
		      lists:concat(["sms_template_code", SMSTemplate]),
		      lists:concat(["sms_type", SMSType]),
		      lists:concat(["timestamp", Timestamp]),
		      lists:concat(["v", SMSVersion])]),
    
    SS = AppSecret ++ lists:concat(SortedParams) ++ AppSecret,
    MD5Sign = ?wifi_print:bin2hex(sha1, crypto:hash(md5, unicode:characters_to_list(SS, utf8))),
    ?DEBUG("MD5Sign ~p", [MD5Sign]),

    Body = lists:concat(["app_key=", AppKey,
			 "&format=", "json" 
			 "&method=", SMSSendMethod,
			 "&partner_id", "",
			 "&rec_num=", ?to_s(Phone), 
			 "&sign_method=", SMSSignMethod,
			 "&sms_free_sign_name=", SMSSignName,
			 "&sms_param=", SMSParams,
			 "&sms_template_code=", SMSTemplate,
			 "&sms_type=", SMSType,
			 "&timestamp=", Timestamp,
			 "&v=", SMSVersion]), 

    UTF8Body = unicode:characters_to_list(Body, utf8),

    case httpc:request(
	   post, {?to_s(URL) ++ "?" ++ "sign=" ++ ?to_s(MD5Sign),
		  [], "application/x-www-form-urlencoded;charset=utf-8", UTF8Body}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("sms result ~p", [Result]),
	    [{_,
	      {struct,
	       [{<<"result">>,
		 {struct,
		  [{<<"err_code">>, Code}|_T 
		  ]}},
		{<<"request_id">>, _RequestId}]}}] = Result,
	    ?DEBUG("code ~p", [Code]),

	    case ?to_i(Code) == 0 of
		true -> {ok, {sms_send, Phone}};
		false ->
		    ?INFO("sms send failed phone ~p, code ~p", [Phone, Code]),
		    {error, {sms_send_failed, Code}}
	    end;
	{error, Reason} ->
	    ?INFO("sms send http failed phone ~p, Reason", [Phone, Reason]),
	    {error, {http_failed, Reason}}
    end.

sms(zz) ->
    Timestamp = ?utils:current_time(timestamp),
    ?DEBUG("timestamp ~p", [Timestamp]),
    Account = "18692269329123456" ++ ?to_s(Timestamp),
    ?DEBUG("Account ~p", [Account]),
    MD5Sign = md5(Account), 
    ?DEBUG("MD5Sign ~p", [MD5Sign]),
    AppId = "49",
    Name = <<"钱掌柜">>,
    %% Params = {[{<<"username">>, <<"18692269329">>},
    %% 	       {<<"password">>, <<"123456">>},
    %% 	       {<<"timestamp">>, ?to_b(Timestamp)},
    %% 	       {<<"signature">>, ?to_b(MD5Sign)},
    %% 	       {<<"appid">>, ?to_b(AppId)},
    %% 	       {<<"signature_name">>, ?to_b(Name)},
    %% 	       {<<"remind_type">>, <<"0">>},
    %% 	       {<<"remind_phone">>, <<>>},
    %% 	       {<<"signature_scene_type">>, <<"1">>},
    %% 	       {<<"is_online">>, <<"0">>},
    %% 	       {<<"web_site">>, <<>>},
    %% 	       {<<"sub_id">>, <<>>} 
    %% 	      ]},

    Body = lists:concat(["username=", "18692269329",
			 "&password=", "123456",
			 "&timestamp=", Timestamp,
			 "&signature=", MD5Sign,
			 "&appid=", AppId,
			 "&signature_name=", ?to_s(Name)]),
    UTF8Body = unicode:characters_to_list(Body, utf8),
    ?DEBUG("body ~p", [UTF8Body]), 
    ?DEBUG("URL ~p", [?ZZ_SMS_SIGN ++ "/signatureAdd"]),
    case httpc:request(
	   post, {?ZZ_SMS_SIGN ++ "/signatureAdd",
		  [], "application/x-www-form-urlencoded;charset=utf-8", UTF8Body}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Head ~p", [_Head]),
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("sms result ~p", [Result]),
	    Status = ?v(<<"status">>, Result),
	    Code  = ?v(<<"code">>, Result),
	    Msg   = ?v(<<"msg">>, Result),
	    ?DEBUG("status ~p, code ~p, msg ~ts", [Status, Code, Msg]);
	{error, Reason} ->
	    {error, {http_failed, Reason}}
    end.

action(0) -> <<"充值">>;
action(1) -> <<"消费">>;
action(2) -> <<"退款">>.


limit_swiming(?INVALID_OR_EMPTY) -> <<"未限制">>;
limit_swiming(V) ->  ?to_b(V).

md5(S) -> 
    Md5_bin =  erlang:md5(S),
    Md5_list = binary_to_list(Md5_bin),
    lists:flatten(list_to_hex(Md5_list)).

list_to_hex(L) ->
    lists:map(fun(X) -> int_to_hex(X) end, L).

int_to_hex(N) when N < 256 -> 
    [hex(N div 16), hex(N rem 16)].

hex(N) when N < 10 ->
    $0+N;
hex(N) when N >= 10, N < 16 ->
    $a + (N-10).

     
