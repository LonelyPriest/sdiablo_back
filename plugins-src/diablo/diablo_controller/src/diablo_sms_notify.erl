-module(diablo_sms_notify).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([sms_notify/2, sign/1]).

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
						?w_user_profile:update(sms_rate, Merchant),
						{0, Merchant};
					    _Error ->
						?sql_utils:execute(write, Sql, Merchant),
						?w_user_profile:update(sms_rate, Merchant),
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
		    [{_,
		      {struct,
		       [{<<"result">>,
			 {struct,
			  [{<<"err_code">>, Code},
			   {<<"model">>, _Mode},
			   {<<"success">>, _Success}]}},
			{<<"request_id">>, _RequestId}]}}] = Result,

		    case ?to_i(Code) == 0 of
			true -> {ok, {sms_send, Phone}};
			false -> {error, {sms_send_failed, Code}}
		    end;
		{error, Reason} ->
		    {error, {http_failed, Reason}}
	    end
    end.


sign(md5) ->
    Path = "http://gw.api.taobao.com/router/rest", 
    Key = "23581677",
    Datetime = ?utils:current_time(format_localtime), 
    FreeSignName = "钱掌柜",
    SendMethod = "alibaba.aliqin.fc.sms.num.send", 
    AppSecret = "eab38d8733faf9d5c813a639afbcfbf2",
    Params = ?to_s(ejson:encode({[{<<"action">>, action(0)},
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
    Template = lists:concat(["sms_template_code", "SMS_36280065"]), 
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



action(0) -> <<"充值">>;
action(1) -> <<"消费">>;
action(2) -> <<"退款">>.
