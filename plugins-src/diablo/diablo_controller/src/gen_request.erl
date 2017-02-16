%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright diablo(C) 2014, buxianhui
%%% @desc: Generator to HTTP request
%%% Created : 28 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(gen_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([http/2, http/3]).



%% -----------------------------------------------------------------------------
%% Behaviour
%% -----------------------------------------------------------------------------
-callback action(atom(), any()) -> ok.
-callback action(atom(), any(), tuple()) -> ok.
-callback action(atom(), any(), tuple(), list()) -> ok.
    
http(M, {'GET', Req}) ->
    ?DEBUG("http receiive GET message", []),
    action(M, Req);
http(M, {'GET', Req, [Url]}) ->
    ?DEBUG("http receiive GET message with url ~p", [Url]),
    action(M, Req, ?split_url(Url));
http(M, {'DELETE', Req, [Url]}) ->
    ?DEBUG("http receiive DELETE message with url ~p", [Url]),
    action(M, Req, ?split_url(Url));
http(UnkownModule, UnkownReq) ->
    ?DEBUG("http receiive unkown message, module ~p, Req ~p", [UnkownModule, UnkownReq]).

http(M, {'POST', Req, [Url]}, Payload) ->
    case Url =:= "upload_w_sale" of
	true -> ?DEBUG("http receive POST message with url ~p", [Url]);
	false -> ?DEBUG("http receive POST message with url ~p and payload ~ts", [Url, Payload])
    end,
    action(M, Req, ?split_url(Url), Payload).



action(M, Req) ->
    Session = get_session(Req),
    M:action(Session, Req).
action(M, Req, Args) ->
    Session = get_session(Req),
    Fun = fun() -> M:action(Session, Req, Args) end, 
    authen(Req, Args, Session, Fun).
    %% [Action|_] = erlang:tuple_to_list(Args),
    %% case ?right_auth:authen(action, Action, Session) of
    %% 	{error, Error} ->
    %% 	    ?utils:respond(200, object, Req, Error);
    %% 	{ok, FunId} ->
    %% 	    ?DEBUG("authen right action ~p, actionId ~p", [Action, FunId]),
    %% 	    M:action(Session, Req, Args)
    %% end.
    
action(M, Req, Args, Payload) ->
    Session = get_session(Req),
    ?DEBUG("Args ~p", [Args]),
    [Action|_] = erlang:tuple_to_list(Args),
    P = 
	case Action of
	    "upload_w_sale" -> Payload;
	    _ -> {struct, Decoded} = mochijson2:decode(Payload),
		 Decoded
	end,
    %% Session = get_session(Req),
    
    Fun = fun() -> M:action(Session, Req, Args, P) end, 
    authen(Req, Args, Session, Fun).


get_session(Req) -> 
    ESession = Req:get_cookie_value(?QZG_DY_SESSION),
    DSession = mochiweb_base64url:decode(ESession),
    ?session:refresh(DSession),
    {ok, Session} = ?session:lookup(DSession),
    Session.
    %% case 
    %% 	mochiweb_session:check_session_cookie(
    %% 	?to_b(MSession), 3600 * 12, fun(A) -> A end, ?QZG_DY_SESSION) of
    %% 	{true, [_, SessionId]} -> 
    %% 	    %% every request, refresh session
    %% 	    ?session:refresh(SessionId),
    %% 	    {ok, Session} = ?session:lookup(SessionId),
    %% 	    Session;
    %% 	{false, _} ->
    %% 	    ?INFO("request ~p failed to get session", [Req]),
    %% 	    #session{}
    %% end.

authen(Req, Args, Session, ValidFun) ->
    %% ?DEBUG("session ~p", [Session]),
    
    case ?session:get(type, Session) of
	?SUPER -> %% super pass directly
	    ValidFun();
	_ ->
	    [Action|_] = erlang:tuple_to_list(Args),
	    %% ?DEBUG("Action ~p", [Action]),
	    case ?right_auth:authen(action, Action, Session) of
		{error, _Error} ->
		    User = ?session:get(name, Session),
		    ?INFO("not enougth right to action ~p of user ~p", [Action, User]),
		    Req:respond({598,
				 [{"Content-Type", "application/json"}],
				 ejson:encode({[{<<"ecode">>, 9901},
						{<<"action">>, ?to_b(Action)}]})});
		{ok, _FunId} -> 
		    %% ?DEBUG("authen right action ~p with actionId ~p", [Action, FunId]),
		    ValidFun()
	    end
    end.
