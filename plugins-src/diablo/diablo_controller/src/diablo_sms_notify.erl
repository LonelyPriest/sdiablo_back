-module(diablo_sms_notify).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([sms_notify/2,
	 sign/1,
	 zz_sms/1, zz_sms/3, sms/3, sms/4,
	 init_sms/0, init_sms/1, sms_once/4, check_sms_rate/1]).
-export([check_merchant_balance/2]).
-export([gen_verificate_code/1]).

-define(zz_sms_account, <<"N3001234">>).
-define(zz_sms_password, <<"dLZJfzK5Mc7a9d">>).

init_sms() ->
    Sqls= [
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 0, \'会员提醒：欢迎光临{$var}，本次{$var}成功，消费金额{$var}，当前余额{$var}，累计积分{$var}，感谢您的惠顾！！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 1, \'会员提醒：欢迎光临{$var}，本次{$var}成功，消费金额{$var}，当前余额{$var}，累计积分{$var}，感谢您的惠顾！！\')">>,
	   <<"insert into zz_sms_template(merchant, type, content) values(2, 1, \'{$var}提醒您：本次消费{$var}元，本次积分{$var}，累计积分{$var}，特价不积分。5千积分兑换50元现金券，请及时兑换！\')" >>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 2, \'会员提醒：欢迎光临{$var}，本次{$var}成功，消费金额{$var}，当前余额{$var}，累计积分{$var}，感谢您的惠顾！！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 3, \'尊敬的VIP：欢迎光临{$var}，现赠与总价值{$var}元的优惠券{$var}张，{$var}天激活后可使用，请保管好该信息并及时消费。\')">>,
	   <<"insert into zz_sms_template(merchant, type, content) values(15, 3, \'尊敬的VIP，现赠予总价值{$var}元的优惠券{$var}张，{$var}天后激活可在钻石女人、艾莱依、E主题、波司登、千仞岗使用！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 4, \'尊敬的{$var}会员，花开一季，岁月一轮，祝您生日快乐，本店特意为您准备了礼品，感谢您的一路陪伴。{$var}祝！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 5, \'会员提醒：欢迎光临{$var}，本次{$var}成功，剩余次数{$var}，有效期截止日{$var}，感谢您的惠顾！！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 6, \'尊敬的客户{$var}，短信充值成功，您已充值{$var}元，目前剩余短消息{$var}条，感谢您的使用！！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 7, \'尊敬的钱掌柜客户{$var}，您名下店铺{$var}会员{$var}消费异常，近一月内消费达{$var}次，请及时核对本次交易！！\')">>,
	   
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 8, \'验证码{$var}，尊敬的{$var}会员，您正在使用会员充值消费功能，请勿转发或泄露（2分钟这内有效）。\')">>,
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 9, \'会员提醒：欢迎光临{$var}，您于{$var}当天{$var}积分成功，目前累计积分为{$var}，感谢您的惠顾！！\')">>
	  ],
    ?sql_utils:execute(transaction, Sqls, ok).

init_sms(added) ->
    Sqls= [
	   <<"insert into zz_sms_template(merchant, type, content) values(-1, 9, \'会员提醒：欢迎光临{$var}，您于{$var}当天{$var}积分成功，目前累计积分为{$var}，感谢您的惠顾！！\')">>
	  ],
    ?sql_utils:execute(transaction, Sqls, ok).    
    

sms_notify(Merchant, {ShopId, Phone, Action, Money, RetailerBalance, Score0, Score}) ->
    ?DEBUG("sms_notify: merchants ~p, shop ~p, phone ~p, action ~p, money ~p"
	   ", rbalance ~p score0 ~p, score ~p",
	   [Merchant, ShopId, Phone, Action, Money, RetailerBalance, Score0, Score]),
    try
	case ?w_user_profile:get(merchant, Merchant) of
	    {ok, []} -> ?err(sms_rate_not_found, Merchant);
	    {ok, MerchantInfo} ->
		?DEBUG("MerchantInfo ~p", [MerchantInfo]),
		MerchantBalance = ?v(<<"balance">>, MerchantInfo),	
		Rate = ?v(<<"sms_rate">>, MerchantInfo),
		?DEBUG("sms rate ~p, MerchantBalance ~p", [Rate, MerchantBalance]),
		case Rate > MerchantBalance of
		    true  -> ?err(sms_not_enought_blance, Merchant);
		    false ->
			{ShopName, ShopSign} = ?shop:shop(get_sign, Merchant, ShopId),
			
			Result = 
			    case ?v(<<"sms_team">>, MerchantInfo) of
				0 ->
				    sms_once(aliqin, 
					     Merchant,
					     {ShopName, Phone, Action, Money, RetailerBalance, Score});
				1 ->

				    Sign = case ShopSign == [] orelse ShopSign == <<>> of
					       true -> ?v(<<"sms_sign">>, MerchantInfo);
					       _ -> ShopSign
					   end, 
				    sms_once(zz,
					     Merchant,
					     Sign,
					     {ShopName, Phone, Action, Money, RetailerBalance, Score0, Score})
			    end,

			case Result of 
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

sms_once(zz, Merchant, Sign, {Shop, Phone, Action, Money, Balance, Score0, Score}) ->
    ?DEBUG("merchant ~p, Sign ~ts, shop ~p, phone ~p, action ~p, money  ~p, balance ~p, score0 ~p, score ~p",
	  [Merchant, Sign, Shop, Phone, Action, Money, Balance, Score0, Score]),
    NewBalance = ?f_print:clean_zero(Balance),
    case ?w_user_profile:get(sms_template, Merchant) of
	{ok, []} -> {error, {sms_template_not_found, Merchant}};
	{ok, Templates} ->
	    %% ?DEBUG("templates ~p", [Templates]),
	    %% filter
	    [Template] = get_sms_template(zz, Action, Merchant, Templates), 
	    Content = ?v(<<"content">>, Template),
	    Text = case Sign == <<>> orelse Sign == [] of
			  true ->
			   <<"【大唐通用】", Content/binary>>;
			   %% <<"【钱掌柜】", Content/binary>>;
			  false ->
			   << <<"【">>/binary, Sign/binary, <<"】">>/binary, Content/binary>>
		      end,
	    ?DEBUG("text ~ts", [Text]),

	    DefaultParams = "," ++ ?to_s(Shop) 
		++ "," ++ ?to_s(action(Action))
		++ "," ++ ?to_s(Money)
		++ "," ++ ?to_s(NewBalance)
		++ "," ++ ?to_s(Score),
	    
	    Params = string:strip(?to_s(Phone))
		++ case Merchant of
		       2 ->
			   case Action of
			       1 ->
				   "," ++ ?to_s(Shop)
				       ++ "," ++ ?to_s(Money)
				       ++ "," ++ ?to_s(Score0)
				       ++ "," ++ ?to_s(Score);
			       _ ->
				   DefaultParams
			   end;
		       _ ->
			   DefaultParams
		   end,
	    ?DEBUG("params ~ts", [?to_b(Params)]),
	    
	    SMSParams = ?to_s(ejson:encode({[{<<"account">>, ?zz_sms_account},
					     {<<"password">>,?zz_sms_password},
					     {<<"msg">>, Text},
					     {<<"params">>, ?to_b(Params)}]})),
	    UTF8Body = unicode:characters_to_list(SMSParams, utf8),
	    case httpc:request(
		   post, {"https://smssh1.253.com/msg/variable/json",
			  [], "application/json;charset=utf-8", UTF8Body}, [], []) of
		{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
		    ?DEBUG("Head ~p", [_Head]),
		    ?DEBUG("Reply ~ts", [Reply]),
		    {struct, Result} = mochijson2:decode(Reply),
		    ?DEBUG("sms result ~p", [Result]),
		    Code  = ?v(<<"code">>, Result),
		    ErrorMsg   = ?v(<<"errorMsg">>, Result),
		    ?DEBUG("code ~p, msg ~ts", [Code, ErrorMsg]),
		    case ?to_i(Code) == 0 of
			true -> {ok, {sms_send, Phone}};
			false ->
			    ?INFO("sms send failed phone ~p, code ~p", [Phone, Code]),
			    {error, {sms_send_failed, Code}}
		    end;
		{error, Reason} ->
		    {error, {http_failed, Reason}}
	    end
    end.
    
sms(promotion, Merchant, Phone) ->
    SMSTemplate = "SMS_167400277",
    start_sms(Merchant, Phone, SMSTemplate, []);

sms(ticket, {Merchant, ShopId, Retailer, Phone}, {Balance, Count, MinEffect}) ->
    ?DEBUG("sms ticket: merchant ~p, retailer ~p, phone ~p, balance ~p, count ~p, effect ~p",
	   [Merchant, Retailer, Phone, Balance, Count, MinEffect]),
    %% case check_merchant_balance(zz, Merchant) of
    %% 	{ok, {Rate, Team, Sign}} ->
    %% 	    case Team of
    %% 		0 ->
    %% 		    {SMSTemplate, SMSParams} = 
    %% 			case Merchant of
    %% 			    15 -> {"SMS_170835177",
    %% 				   ?to_s(ejson:encode(
    %% 					   {[{<<"m">>, ?to_b(Balance)},
    %% 					     {<<"d">>, ?to_b(Count)},
    %% 					     {<<"day">>, ?to_b(MinEffect)}
    %% 					    ]}))};
    %% 			    _ ->
    %% 				{"SMS_168285336",
    %% 				 ?to_s(ejson:encode(
    %% 					 {[{<<"shop">>, Shop},
    %% 					   {<<"user">>, Retailer},
    %% 					   {<<"money">>, ?to_b(Balance)},
    %% 					   {<<"count">>, ?to_b(Count)}
    %% 					  ]}))}
    %% 			end,
    %% 		    start_sms(Merchant, Phone, SMSTemplate, SMSParams);
    %% 		1 -> 
    %% 		    case get_sms_template(zz, ?NORMAL_TICKET, Merchant) of
    %% 			{ok, Template} ->
    %% 			    Params = string:strip(?to_s(Phone))
    %% 				++ "," ++ ?to_s(Shop) 
    %% 				++ "," ++ ?to_s(Balance)
    %% 				++ "," ++ ?to_s(Count)
    %% 				++ "," ++ ?to_s(MinEffect),
    %% 			    ?DEBUG("params ~ts", [?to_b(Params)]),

    %% 			    case send_sms(zz, Sign, Phone, Params, Template) of
    %% 				{ok, {sms_send, Phone}} ->
    %% 				    reset_merchant_balance(zz, Merchant, Rate),
    %% 				    {?SUCCESS, Merchant};
    %% 				{error, SendError} -> SendError
    %% 			    end;
    %% 			{error, GetTemplateError} ->
    %% 			    GetTemplateError
    %% 		    end
    %% 	    end;
    %% 	{error, CheckBalanceError} -> CheckBalanceError
    %% end,
    {ShopName, ShopSign} = ?shop:shop(get_sign, Merchant, ShopId),
    Callback =
	fun() ->
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
				     {[{<<"shop">>, ShopName},
				       {<<"user">>, Retailer},
				       {<<"money">>, ?to_b(Balance)},
				       {<<"count">>, ?to_b(Count)}
				      ]}))}
		    end,
		start_sms(Merchant, Phone, SMSTemplate, SMSParams)
	end,
    
    ZZParams =
	case Merchant of
	    15 -> string:strip(?to_s(Phone))
		      ++ "," ++ ?to_s(Balance)
		      ++ "," ++ ?to_s(Count)
		      ++ "," ++ ?to_s(MinEffect);
	    _ ->
		string:strip(?to_s(Phone))
		    ++ "," ++ ?to_s(ShopName) 
		    ++ "," ++ ?to_s(Balance)
		    ++ "," ++ ?to_s(Count)
		    ++ "," ++ ?to_s(MinEffect)
	end,
    ?DEBUG("params ~ts", [?to_b(ZZParams)]),
    rocket_sms_send(zz, Merchant, ShopSign, ?NORMAL_TICKET, Phone, ZZParams, Callback);
		
sms(charge, {Merchant, Name, Phone}, Balance) ->
    {ok, MerchantInfo} = ?w_user_profile:get(merchant, Merchant),
    %% ?DEBUG("smsrate ~p", [SMSRate]), 
    Rate = ?v(<<"sms_rate">>, MerchantInfo),
    LeftBalance = ?v(<<"balance">>, MerchantInfo, 0), 
    Count = trunc(LeftBalance + Balance) div Rate, 
    %% SMSTemplate   = "SMS_153716629",
    %% SMSParams = ?to_s(ejson:encode(
    %% 			{[{<<"name">>, <<Name/binary, <<"-">>/binary, Phone/binary>>},
    %% 			  {<<"money">>, ?to_b(Balance div 100)},
    %% 			  {<<"count">>, ?to_b(Count)} 
    %% 			 ]})),
    %% case send_sms(Phone, SMSTemplate, SMSParams) of
    %% 	{ok, {sms_send, Phone}} = OK->
    %% 	    {ok, OK};
    %% 	{error, {sms_center_not_found, Merchant}} ->
    %% 	    ?err(sms_center_not_found, Merchant);
    %% 	{error, _} ->
    %% 	    ?err(sms_send_failed, Phone)
    %% end.
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(<<Name/binary, <<"-">>/binary, Phone/binary>>)
	++ "," ++ ?to_s(Balance div 100)
	++ "," ++ ?to_s(Count),
    ?DEBUG("params ~ts", [Params]),
    case get_sms_template(zz, ?SMS_CHARGE, Merchant) of
	{ok, Template} -> 
	    send_sms(zz, Phone, <<>>, Params, Template);
	Error ->
	    Error
    end.
    

sms(swiming, Merchant, Phone, {ShopId, Action, LeftSwiming, Expire}) ->
    %% SMSTemplate   = "SMS_146809919",
    %% SMSParams = ?to_s(ejson:encode({[{<<"shop">>, Shop},
    %% 				     {<<"action">>, action(Action)},
    %% 				     {<<"lcount">>, limit_swiming(LeftSwiming)},
    %% 				     {<<"expire">>, limit_swiming(Expire)}
    %% 				    ]})),
    %% start_sms(Merchant, Phone, SMSTemplate, SMSParams);
    {ShopName, ShopSign} = ?shop:shop(get_sign, Merchant, ShopId),
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(ShopName)
	++ "," ++ ?to_s(action(Action))
	++ "," ++ ?to_s(limit_swiming(LeftSwiming))
	++ "," ++ ?to_s(limit_swiming(Expire)),
    ?DEBUG("params ~ts", [?to_b(Params)]),
    rocket_sms_send(zz, Merchant, ShopSign, ?THEORETIC_CARD_SALE, Phone, Params, fun() -> ok end);

sms(birth, Merchant, Phone, {Shop, Sign}) ->
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(Shop)
	++ "," ++ ?to_s(Shop),
    ?DEBUG("params ~ts", [?to_b(Params)]),
    rocket_sms_send(zz, Merchant, Sign, ?BIRTH_NOTIFY, Phone, Params, fun() -> ok end);

sms(max_trans, Merchant, Phone, {Manager, Shop, Retailer, TransCount}) ->
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(Manager)
	++ "," ++ ?to_s(Shop)
	++ "," ++ ?to_s(Retailer)
	++ "," ++ ?to_s(TransCount),
    ?DEBUG("params ~ts", [?to_b(Params)]),
    rocket_sms_send(zz, Merchant, <<"钱掌柜">>, ?MAX_TRANS, Phone, Params, fun() -> ok end);

sms(verificate_code, Merchant, Phone, {ShopId, Code})->
    {ShopName, ShopSign} = ?shop:shop(get_sign, Merchant, ShopId),
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(Code)
	++ "," ++ ?to_s(ShopName),
    ?DEBUG("params ~ts", [?to_b(Params)]),
    rocket_sms_send(zz, Merchant, ShopSign, ?VERIFICATION_CODE, Phone, Params, fun() -> ok end);
sms(score_modify, Merchant, Phone, {Action, ShopId, Score}) ->
    {ShopName, ShopSign} = ?shop:shop(get_sign, Merchant, ShopId),
    Params = string:strip(?to_s(Phone))
	++ "," ++ ?to_s(ShopName)
	++ "," ++ ?utils:current_date(format)
	++ "," ++ ?to_s(action(score, Action))
	++ "," ++ ?to_s(Score),
    
    ?DEBUG("params ~ts", [?to_b(Params)]),
    rocket_sms_send(zz, Merchant, ShopSign, ?SCORE_MODIFY, Phone, Params, fun() -> ok end).

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
		Rate = ?v(<<"sms_rate">>, MerchantInfo),
		case Rate > MerchantBalance of
		    true  -> ?err(sms_not_enought_blance, Merchant);
		    false -> {ok, Rate}
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

zz_sms(add_sign) ->
    Timestamp = ?utils:current_time(timestamp),
    Account = "18692269329123456" ++ ?to_s(Timestamp),
    MD5Sign = md5(Account), 
    AppId = "49",
    Sign = <<"钱掌柜">>,
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
			 "&signature_name=", ?to_s(Sign)]),
    UTF8Body = unicode:characters_to_list(Body, utf8),
    ?DEBUG("body ~p", [UTF8Body]), 
    ?DEBUG("URL ~p", [?ZZ_SMS_SIGN ++ "/signatureAdd"]),
    case httpc:request(
	   post, {?ZZ_SMS_SIGN ++ "/signature/signatureAdd",
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
    end;

zz_sms(add_template) ->
    Timestamp = ?utils:current_time(timestamp),
    Account = "18692269329123456" ++ ?to_s(Timestamp),
    MD5Sign = md5(Account),
    AppId = "49",
    Sign = <<"钱掌柜">>,
    Content = <<"会员提醒：欢迎光临{s}，本次{a}成功，消费金额{m}，当前余额{b}，累计积分{c}，感谢您的惠顾！！">>,
    

    Body = lists:concat(["username=", "18692269329",
			 "&password=", "123456",
			 "&timestamp=", Timestamp,
			 "&signature=", MD5Sign,
			 "&appid=", AppId,
			 "&signature_name=", ?to_s(Sign),
			 "&content=", ?to_s(Content)]),
    UTF8Body = unicode:characters_to_list(Body, utf8),
    case httpc:request(
	   post, {?ZZ_SMS_SIGN ++ "/template/add",
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
    end;

zz_sms(send) ->
    Account = "N3001234",
    Password = "dLZJfzK5Mc7a9d",
    Msg = "【钱掌柜】会员提醒：欢迎光临{$var}，本次消费成功，消费金额{$var}，当前余额{$var}，累计积分{$var}，感谢您的惠顾！！",
    Params = "18692269329,一帆风顺,399,0,799",
    SMSParams = ?to_s(ejson:encode({[{<<"account">>, ?to_b(Account)},
				     {<<"password">>, ?to_b(Password)},
				     {<<"msg">>, ?to_b(Msg)},
				     {<<"params">>, ?to_b(Params)}]})),
    UTF8Body = unicode:characters_to_list(SMSParams, utf8),
    case httpc:request(
	   post, {"https://smssh1.253.com/msg/variable/json",
		  [], "application/json;charset=utf-8", UTF8Body}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Head ~p", [_Head]),
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("sms result ~p", [Result]),
	    Code  = ?v(<<"code">>, Result),
	    ErrorMsg   = ?v(<<"errorMsg">>, Result),
	    ?DEBUG("code ~p, msg ~ts", [Code, ErrorMsg]);
	{error, Reason} ->
	    {error, {http_failed, Reason}}
    end.

zz_sms(retailer_sms_send, Merchant, Shops) ->
    Account = "N3001234",
    Password = "dLZJfzK5Mc7a9d",
    Msg = "【独品服饰】尊敬的{$var}会员：易俗河独品女装搬迁至凤凰路肯德基旁，9月10日至12日盛大开业，特为您准备了精美礼品一份！期待您的到来！",

    Sql = "select id, name, mobile from w_retailer"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and " ++ ?utils:to_sqls(proplists, {<<"shop">>, Shops})
	++ " and type!=2",
    case ?sql_utils:execute(read, Sql) of
	{ok, []} -> ok;
	{ok, _Retailers} ->
	    lists:foreach(
	      fun({R}) ->
		      Phone = ?v(<<"mobile">>, R),
		      Name = ?v(<<"name">>, R),
		      Params = ?to_s(Phone) ++ "," ++ ?to_s(Name),
		      SMSParams = ?to_s(ejson:encode({[{<<"account">>, ?to_b(Account)},
						       {<<"password">>, ?to_b(Password)},
						       {<<"msg">>, ?to_b(Msg)},
						       {<<"params">>, ?to_b(Params)}]})),
		      ?DEBUG("Phone ~p, Name ~p, Params ~p", [Phone, Name, Params]),
		      UTF8Body = unicode:characters_to_list(SMSParams, utf8),
		      case httpc:request(
			     post, {"https://smssh1.253.com/msg/variable/json",
				    [], "application/json;charset=utf-8", UTF8Body}, [], []) of
			  {ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
			      ?DEBUG("Head ~p", [_Head]),
			      ?DEBUG("Reply ~ts", [Reply]),
			      {struct, Result} = mochijson2:decode(Reply),
			      ?DEBUG("sms result ~p", [Result]),
			      Code  = ?v(<<"code">>, Result),
			      ErrorMsg   = ?v(<<"errorMsg">>, Result),
			      ?DEBUG("code ~p, msg ~ts", [Code, ErrorMsg]);
			  {error, Reason} ->
			      {error, {http_failed, Reason}}
		      end
	      end, [{[{<<"name">>, <<"卜仙慧">>}, {<<"mobile">>, <<"18692269329">>}]}]);
	Error -> Error
    end.

get_sms_template(zz, Action, Merchant) ->
    case ?w_user_profile:get(sms_template, Merchant) of
	{ok, []} -> {error, ?err(sms_template_not_found, Merchant)};
	{ok, Templates} ->
	    case get_sms_template(zz, Action, Merchant, Templates) of
		[] ->
		    {error, ?err(sms_template_not_found, Merchant)};
		[Template] ->
		    ?DEBUG("template ~p", [Template]),
		    {ok, Template}
	    end
    end.

get_sms_template(zz, Action, Merchant, Templates) ->
    ?DEBUG("Action ~p, Merchant ~p", [Action, Merchant]),
    case [ T || {T} <- Templates,
	       case Action of
		   ?NORMAL_CHARGE -> ?v(<<"type">>, T) =:= 0; %% charge
		   ?NORMAL_SALE -> ?v(<<"type">>, T) =:= 1;  %% sale
		   ?NORMAL_REJECT_SALE -> ?v(<<"type">>, T) =:= 2;  %% reject sale
		   ?NORMAL_TICKET -> ?v(<<"type">>, T) =:= 3;   %% ticket
		   ?BIRTH_NOTIFY -> ?v(<<"type">>, T) =:= 4; %% birth
		   ?THEORETIC_CARD_SALE -> ?v(<<"type">>, T) =:= 5; %% card sale
		   ?SMS_CHARGE -> ?v(<<"type">>, T) =:= 6; %% sms charge
		   ?MAX_TRANS -> ?v(<<"type">>, T) =:= 7;
		   ?VERIFICATION_CODE -> ?v(<<"type">>, T) =:= 8; %% msg verificate code for retailer
		   ?SCORE_MODIFY -> ?v(<<"type">>, T) =:= 9 %% sms score modify
	       end] of
	FTemplates ->
	    ?DEBUG("FTemplates ~p", [FTemplates]),
	    case [T || T <- FTemplates, ?v(<<"merchant">>, T) =:= Merchant] of
		[] ->
		    [T || T <- FTemplates, ?v(<<"merchant">>, T) =:= -1];
		UTemplates->
		    ?DEBUG("UTemplates ~p", [UTemplates]),
		    UTemplates
	    end
    end.
	
check_merchant_balance(zz, Merchant) ->
    case ?w_user_profile:get(merchant, Merchant) of
	{ok, []} -> {error, ?err(sms_rate_not_found, Merchant)};
	{ok, MerchantInfo} ->
	    ?DEBUG("MerchantInfo ~p", [MerchantInfo]),
	    MerchantBalance = ?v(<<"balance">>, MerchantInfo),	
	    Rate = ?v(<<"sms_rate">>, MerchantInfo),
	    %% ?DEBUG("sms rate ~p, MerchantBalance ~p", [Rate, MerchantBalance]),
	    case Rate == 0 orelse Rate > MerchantBalance of
	    %% case Rate > MerchantBalance of
		true  -> {error, ?err(sms_not_enought_blance, Merchant)};
		false ->
		    {ok, {Rate,
			  ?v(<<"sms_team">>, MerchantInfo),
			  ?v(<<"sms_sign">>, MerchantInfo)}}
	    end;
	_Error ->
	    {error, ?err(sms_rate_not_found, Merchant)}
    end.

send_sms(zz, Phone, Sign, MsgParams, SMSTemplate) ->
    Content = ?v(<<"content">>, SMSTemplate),
    ?DEBUG("templdate content ~ts", [?to_b(Content)]),
    Msg = case Sign == <<>> orelse Sign == [] of
	      true -> <<"【钱掌柜】", Content/binary>>;
	      false -> << <<"【">>/binary, Sign/binary, <<"】">>/binary, Content/binary>>
	  end,
    SMSParams = ?to_s(ejson:encode({[{<<"account">>, ?zz_sms_account},
				     {<<"password">>,?zz_sms_password},
				     {<<"msg">>, Msg},
				     {<<"params">>, ?to_b(MsgParams)}]})), 
    UTF8Body = unicode:characters_to_list(SMSParams, utf8),
    case httpc:request(
	   post, {"https://smssh1.253.com/msg/variable/json",
		  [], "application/json;charset=utf-8", UTF8Body}, [], []) of
	{ok, {{"HTTP/1.1", 200, "OK"}, _Head, Reply}} ->
	    ?DEBUG("Head ~p", [_Head]),
	    ?DEBUG("Reply ~ts", [Reply]),
	    {struct, Result} = mochijson2:decode(Reply),
	    ?DEBUG("sms result ~p", [Result]),
	    Code  = ?v(<<"code">>, Result),
	    ErrorMsg   = ?v(<<"errorMsg">>, Result),
	    ?DEBUG("code ~p, msg ~ts", [Code, ErrorMsg]),
	    case ?to_i(Code) == 0 of
		true -> {ok, Phone};
		false ->
		    ?INFO("sms send failed phone ~p, code ~p", [Phone, Code]),
		    {error, ?err(sms_send_failed, Code)}
	    end;
	{error, Reason} ->
	    {error, ?err(sms_http_failed, Reason)}
    end.

reset_merchant_balance(zz, Merchant, SMSRatee) ->
    Sql = "update merchants set balance=balance-" ++ ?to_s(SMSRatee)
	++ ", sms_send=sms_send+1"
	++ " where id=" ++ ?to_s(Merchant),
    case ?sql_utils:execute(write, Sql, Merchant) of
	{ok, Merchant} ->
	    ?w_user_profile:update(merchant, Merchant),
	    {?SUCCESS, Merchant};
	_Error ->
	    ?sql_utils:execute(write, Sql, Merchant),
	    ?w_user_profile:update(merchant, Merchant),
	    {?SUCCESS, Merchant}
    end.

rocket_sms_send(zz, Merchant, ShopSign, Action, Phone, MsgParams, TeamCallback) ->
    case check_merchant_balance(zz, Merchant) of
	{ok, {Rate, Team, Sign}} ->
	    case Team of
		0 -> TeamCallback();
		1 ->
		    case get_sms_template(zz, Action, Merchant) of
			{ok, Template} ->
			    RealySign = case ShopSign == [] orelse ShopSign == <<>> of
					    true -> Sign;
					    _ -> ShopSign
					end,
			    case send_sms(zz, Phone, RealySign, MsgParams, Template) of
				{ok, Phone} ->
				    reset_merchant_balance(zz, Merchant, Rate);
				{error, SendError} -> SendError
			    end;
			{error, GetTemplateError} ->
			    GetTemplateError
		    end
	    end;
	{error, CheckBalanceError} -> CheckBalanceError
    end.


action(0) -> <<"充值">>;
action(1) -> <<"消费">>;
action(2) -> <<"退款">>.

action(score, 0)-> <<"获得">>;
action(score, 1)-> <<"消费">>.
    
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

gen_verificate_code(with_4)->
    crypto:rand_uniform(1000, 9999);
gen_verificate_code(with_5) ->
    crypto:rand_uniform(10000, 99999);
gen_verificate_code(with_6) ->
    crypto:rand_uniform(100000, 999999).

