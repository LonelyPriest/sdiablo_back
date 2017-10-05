%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright diablo(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 13 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_login_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").
-export([action/2]).
-export([test_login/3]).


-define(LOGIN_USER_ACTIVE,
	"该用户已登录系统，是否继续登录？").
-define(LOGIN_EXECCED_USER,
	"超过在线最大用户数限制，是否强制登录？注意：系统将踢出未在线时间最长用户！！").
-define(LOGIN_NO_USER_FIRE, "没有用户可以踢出！！注意：管理员用户无法踢出，请确认管理员是否在线！！").
-define(INVALID_USER, "非法用户！！").
-define(WRONG_USER_PASSWD, "用户名或密码错误").


test_login(UserName, Passwd, Force) ->
    case ?login:login(UserName, Passwd) of	
	{ok, UserDetail}    ->
	    StartInfo = 
		case ?session:get_session(by_user, UserName) of
		    {ok, []} ->
			start_force(Force, new_user, UserDetail); 
		    {ok, {SessionId, Session}} ->
			start_force(Force, old_user, 
				    SessionId, Session, UserDetail)
		end,
	    case StartInfo of
		{ok, {Cookie, Path}} ->
		    ?DEBUG("ok, login with cookie ~p, path ~p", [Cookie, Path]);
		{error, Error} ->
		    ?DEBUG("error, login error ~p", [Error])
	    end; 
	{error, Error} ->
	    ?DEBUG("login error ~p", [Error]),
	    ?DEBUG("error,  login error ~p", [Error])
    end.

action(Req, login) ->
    %%action(Req, login, false); 
    Post = Req:parse_post(),
    Tablet   = ?to_i(?v("tablet", Post, 0)),
    ?DEBUG("tablet ~p", [Tablet]),
    case Tablet of
        ?TABLET -> 
            tablet_login(Req, ?TABLET);
        _ ->
            action(Req, login, false)
    end;

action(Req, login_force) ->
    %% action(Req, login, true). 
    Post = Req:parse_post(),
    Tablet   = ?to_i(?v("tablet", Post, 0)),
    ?DEBUG("tablet ~p", [Tablet]),
    case Tablet of
	?TABLET ->
            tablet_login(Req, ?TABLET);
        _ ->
            action(Req, login, true)
    end.

action(Req, login, Force) -> 
    Post = Req:parse_post(),
    ?DEBUG("post data ~p", [Post]),
    UserName = ?v("username", Post, []),
    Passwd   = ?v("password", Post, []),
    %% Force     = ?to_a(?v("force", Post, false)),

    LoginResponseFun =
	fun(Error) ->
		{ok, HTML} = login:render([{show_error, "true"},
					   {login_error, Error}]),
		Req:respond({200, [{"Content-Type", "text/html"}], HTML})
	end,

    LoginForceFun =
	fun(Error) ->
		{ok, HTML} = login_force:render([{login_error, Error},
						 {username, UserName},
						 {password, Passwd}]),
		Req:respond({200, [{"Content-Type", "text/html"}], HTML})
	end,

    case UserName of
	[] -> LoginResponseFun(?WRONG_USER_PASSWD);
	    %% ?utils:respond(200, Req, ?err(login_no_user, none));
	UserName ->
	    case Passwd of
		[] ->
		    LoginResponseFun(?WRONG_USER_PASSWD);
		%% ?utils:respond(200, Req, ?err(login_no_password, none));
		Passwd ->
		    case ?login:login(UserName, Passwd) of	
			{ok, UserDetail}    ->
			    StartInfo = 
				case ?session:get_session(by_user, UserName) of
				    {ok, []} ->
					start_force(Force, new_user, UserDetail); 
				    {ok, {SessionId, Session}} -> 
					start_force(Force, old_user, 
						    SessionId, Session, UserDetail);
				    {error, more_session} ->
					{error, {1109, more_session}}
				end,
			    case StartInfo of
				{ok, {Cookie, _CookieData, Path}} ->
				    response_with_cookie(Req, Cookie, Path, UserName);
				{error, {1105, _}} ->
				    LoginForceFun(?LOGIN_USER_ACTIVE); 
				{error, {1106, _}} ->
				    LoginForceFun(?LOGIN_EXECCED_USER); 
				{error, {1107, _}} ->
				    LoginForceFun(?LOGIN_NO_USER_FIRE); 
				{error, {1108, _}} ->
				    LoginResponseFun(?INVALID_USER);
				{error, {1109, _}} ->
				    LoginResponseFun(?INVALID_USER)
				    %% ?utils:respond(200, Req, Error)
			    end; 
			{error, _Error} ->
			    LoginResponseFun(?WRONG_USER_PASSWD) 
			    %% ?DEBUG("login error ~p", [Error]),
			    %% ?utils:respond(200, Req, Error)
		    end 
	    end
    end.
    
    
response_with_cookie(Req, Cookie, Path, _UserName) -> 
    Req:respond({302, [{"Location", Path},
		       {"Content-Type", "text/html; charset=UTF-8"},
		       Cookie],
		 "Redirecting " ++ Path}).

start_force(false, new_user, UserDetail) ->
    case ?v(<<"type">>, UserDetail) of
	?SUPER ->
	    {ok, start(with_new_session, UserDetail)};
	_ ->
	    UserName = ?v(<<"name">>, UserDetail),
	    case ?login:get(max_user, UserName) of
		{ok, {Merchant, MaxUser}} -> 
		    {ok, NowUsers} = ?session:get_user(number, Merchant),
		    case NowUsers + 1 > MaxUser of
			true ->
			    ?DEBUG("excedd max user of merchant ~p,now ~p,"
				   "max ~p", [Merchant, NowUsers, MaxUser]),
			    {error, ?err(login_exceed_user, Merchant)}; 
			false ->
			    {ok, start(with_new_session, UserDetail)}
		    end;
		{error, login_invalid_user} ->
		    {error, ?err(login_invalid_user, UserName)}
	    end
    end;

start_force(true, new_user, UserDetail) ->
    %% fire user that unused longest
    UserName = ?v(<<"name">>, UserDetail),
    {ok, {Merchant, _MaxUser}} = ?login:get(max_user, UserName),
    case ?session:delete(longest_unused, Merchant) of
	{error, no_users} ->
	    {error, ?err(login_no_user_fire, Merchant)};
	ok -> {ok, start(with_new_session, UserDetail)}
    end.

start_force(false, old_user, SessionId, Session, UserDetail) ->
    Now = ?utils:current_time(timestamp),
    case Now - ?session:get(time, Session) > 3600 * 2 of
	true -> %% more than half an hour, login direct 
	    ?session:delete(SessionId),
	    {ok, start(with_new_session, UserDetail)};
	false ->
	    {error, ?err(login_user_active, ?v(<<"id">>, UserDetail))}
    end;

start_force(true, old_user, SessionId, _Session, UserDetail) ->
    ?session:delete(SessionId),
    {ok, start(with_new_session, UserDetail)}.


start(with_new_session, UserDetail) ->
    ?DEBUG("new session ~p", [?v(<<"name">>, UserDetail)]),
    %% first, get login user role
    UserId = ?v(<<"id">>, UserDetail),
    Merchant = ?v(<<"merchant">>, UserDetail),

    %% create a new session
    {ok, SessionId} = ?session:new(UserDetail),
    ?DEBUG("SessionId ~p", [SessionId]),

    %% CookieData = mochiweb_session:generate_session_data(
    %% 		   3600 * 12, SessionId, fun(A) -> A end, ?QZG_DY_SESSION),
    
    CookieData = mochiweb_base64url:encode(<<SessionId/binary>>),
    Cookie = mochiweb_cookies:cookie(?QZG_DY_SESSION, CookieData, [{path, "/"}]),
    ?DEBUG("Cookie ~p", [Cookie]),
    
    %% use the first navigation
    [{Path, _Name, _Module, _Hidden}|_] =
	case ?v(<<"type">>, UserDetail) of
	    ?SUPER -> %% super login directly
		?right_auth:navbar(super);
	    _ ->
		?right_auth:navbar(user, UserId)
	end,

    %% create the right of this login user
    case ?v(<<"type">>, UserDetail) of
	?SUPER ->
	    ok;
	_Type ->
	    ok = ?right_auth:cache(right, UserId),
	    {ok, Merchant} = ?w_user_profile:new(Merchant),
	    {ok, Merchant, SessionId} = ?w_user_profile:new(Merchant, SessionId),
	    ok
    end,

    {Cookie, CookieData, Path}. 


tablet_login(Req, ?TABLET) -> 
    Post = Req:parse_post(),
    UserName = ?v("user_name", Post, []),
    Passwd   = ?v("user_password", Post, []),
    Force    = case ?to_i(?v("force", Post, 0)) of
		   0 -> false;
		   1 -> true
               end, 
    case ?login:login(UserName, Passwd) of
        {ok, UserDetail} ->
            StartInfo =
                case ?session:get_session(by_user, UserName) of
                    {ok, []} ->
                        start_force(Force,
                                    new_user,
                                    UserDetail ++ [{<<"tablet">>, 1}]);
                    {ok, {SessionId, Session}} ->
                        start_force(Force,
                                    old_user,
                                    SessionId,
                                    Session,
                                    UserDetail ++ [{<<"tablet">>, 1}]);
                    {error, more_session} ->
                        {error, {1109, more_session}}
                end,

            ?DEBUG("StartInfo ~p", [StartInfo]),
            case StartInfo of
                {ok, {_Cookie, CookieData, _Path}} ->
                    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
                                                       {<<"token">>, ?to_b(CookieData)},
                                                       {<<"einfo">>, <<>>}]});
                {error, {ECode, _}} ->
                    ?utils:respond(200, object, Req, {[{<<"ecode">>, ECode},
                                                       {<<"token">>, <<>>},
                                                       {<<"einfo">>, <<>>}]})
            end;
        {error, {1199, _}} ->
            ?utils:respond(200, object, Req, {[{<<"ecode">>, 1199},
                                               {<<"token">>, <<>>},
                                               {<<"einfo">>, <<>>}]});
        {error, {ECode, _}} = _Error->
            ?DEBUG("login error ~p", [_Error]),
            ?utils:respond(200, object, Req, {[{<<"ecode">>, ECode},
                                               {<<"token">>, <<>>},
                                               {<<"einfo">>, <<>>}]})
    end.
