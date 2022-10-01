%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2022, buxianhui
%%% @doc
%%%
%%% @end
%%% Created :  1 Oct 2022 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(app_gen_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([http/2, http/3]).

%% -----------------------------------------------------------------------------
%% Behaviour
%% -----------------------------------------------------------------------------
-callback action(atom(), any(), list()) -> ok.
-callback action(atom(), any(), list(), tuple()) -> ok.
-callback action(atom(), any(), tuple(), list(), list()) -> ok.

http(M, {'GET', Req}) ->
    ?DEBUG("http receive GET message", []),
    action(M, Req);

http(M, {'GET', Req, [Url]}) ->
    ?DEBUG("http receive GET message with url ~p", [Url]),
    action(M, Req, ?split_url(Url));
http(M, {'DELETE', Req, [Url]}) ->
    ?DEBUG("http receive DELETE message with url ~p", [Url]),
    action(M, Req, ?split_url(Url));
http(UnkownModule, UnkownReq) ->
    ?DEBUG("http receive unkown message, module ~p, Req ~p", [UnkownModule, UnkownReq]).

http(M, {'POST', Req, [Url]}, Payload) -> 
    ?DEBUG("http receive POST message with url ~p and payload ~ts", [Url, Payload]),
    action(M, Req, ?split_url(Url), Payload).

action(M, Req) ->
    Session = get_session(Req),
    {struct, AppInfo} = mochijson2:decode(Req:get_header_value(?WEAPP)),
    
    M:action(Session, Req, AppInfo).

action(M, Req, Args) ->
    Session = get_session(Req),
    {struct, AppInfo} = mochijson2:decode(Req:get_header_value(?WEAPP)),
    Fun = fun() -> M:action(Session, Req, AppInfo, Args) end, 
    authen(Req, Args, Session, Fun).

action(M, Req, Args, Payload) ->
    Session = get_session(Req),
    ?DEBUG("Args ~p", [Args]),
    {struct, AppInfo} = mochijson2:decode(Req:get_header_value(?WEAPP)),
    {struct, P} = mochijson2:decode(Payload),
    %% Session = get_session(Req), 
    Fun = fun() -> M:action(Session, Req, AppInfo, Args, P) end, 
    authen(Req, Args, Session, Fun).

get_session(Req) -> 
    case Req:get_cookie_value(?QZG_DY_SESSION) of
	undefined -> [];
	Session ->
	    mochiweb_base64url:decode(Session)
    end.

authen(_Req, _Args, _Session, ValidFun) ->
    %% case ?session:get(type, Session) of
    %% 	?SUPER -> %% super pass directly
    %% 	    ValidFun();
    %% 	_ ->
    %% 	    [Action|_] = erlang:tuple_to_list(Args),
    %% 	    %% ?DEBUG("Action ~p", [Action]),
    %% 	    case ?right_auth:authen(action, Action, Session) of
    %% 		{error, _Error} ->
    %% 		    User = ?session:get(name, Session),
    %% 		    ?INFO("not enougth right to action ~p of user ~p", [Action, User]),
    %% 		    Req:respond({598,
    %% 				 [{"Content-Type", "application/json"}],
    %% 				 ejson:encode({[{<<"ecode">>, 9901},
    %% 						{<<"action">>, ?to_b(Action)}]})});
    %% 		{ok, _FunId} -> 
    %% 		    %% ?DEBUG("authen right action ~p with actionId ~p", [Action, FunId]),
    %% 		    ValidFun()
    %% 	    end
    %% end.
    ValidFun().

