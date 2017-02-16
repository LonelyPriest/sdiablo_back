%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_http_server).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([start/0,  dispatch/2]).

start() ->
    {file, Here} = code:is_loaded(?MODULE),
    BaseDir = filename:dirname(filename:dirname(Here)),
    Path = filename:join([BaseDir, "hdoc/"]),

    %% default 80
    Port =
	case application:get_env(diablo_controller, diablo_port) of
	    {ok, Any} -> Any;
	    _ -> 80
	end,

    Loop = fun(Req) -> ?MODULE:dispatch(Req, Path) end,
    
    HttpOpts = [{loop, Loop},
		{port, Port},
		{name, ?MODULE}],
    
    {ok, _Http} = mochiweb_http:start(HttpOpts),
    ?INFO("success to start http server on port, ~p", [Port]),
    ok.

valid_session(Req) ->
    case Req:get_cookie_value(?QZG_DY_SESSION) of
	undefined -> %% redirect to login page
	    {error, no_session};
	ESession ->
	    %% ?DEBUG("MSession ~p", [MSession]),
	    DSession = mochiweb_base64url:decode(ESession),
	    case ?session:lookup(DSession) of
		{ok, []} -> %% session time out or lost
		    ?INFO("invalid session ~p", [DSession]),
		    {error, {invalid_session, DSession}};
		{ok, _} -> %% valid session 
		    {ok, valid_session}
	    end
	
	    %% case 
	    %% 	mochiweb_session:check_session_cookie(
	    %% 	  ?to_b(MSession),
	    %% 	  3600 * 12,
	    %% 	  fun(A) -> A end,
	    %% 	  ?QZG_DY_SESSION) of
	    %% 	{true, [_, SessionId]} -> 
	    %% 	    case ?session:lookup(SessionId) of
	    %% 		{ok, []} -> %% session time out or lost
	    %% 		    ?INFO("invalid session ~p", [SessionId]),
	    %% 		    {error, {invalid_session, MSession}};
	    %% 		{ok, _} -> %% valid session 
	    %% 		    {ok, valid_session}
	    %% 	    end;
	    %% 	{false, []} ->
	    %% 	    {error, no_session};
	    %% 	{false, [_, SessionId]} ->
	    %% 	    ?INFO("failed to check session ~p", [SessionId]),
	    %% 	    {error, {invalid_session, MSession}}
	    %% end
    end.	    

dispatch(Req, DocRoot) ->
    %% check session
    "/" ++ Path = Req:get(path),
	%% try
	%%     "/" ++ PPath = Req:get(path),
	%%     PPath
	%% catch
	%%     _:_ -> unkown_path
	%% end,
				  
			      
		     
    %% ?DEBUG("Req ~p", [Req]),
    %% ?DEBUG("Path = ~p", [Path]),
    try
	case Req:get(method) of
	    Method when Method =:= 'GET'; Method =:= 'HEAD' ->
		case Path of
		    [] -> root(Req);
		    _ ->
			case url_dispatch(Req, ?http_route:url_match(get)) of
			    none ->
				%% ?DEBUG("Path ~p", [Path]),
				case filelib:is_file(
				       filename:join([DocRoot, Path])) of
				    true ->
					Req:serve_file(Path, DocRoot);
				    false->
					Req:not_found()
				end;
			    Response ->
				Response
			end
		end;
	    Method when Method =:= 'POST' ->
		Payload = Req:recv_body(),
		%% ?DEBUG("post data ~ts", [Payload]),
		case url_dispatch(Req, ?http_route:url_match(post, Payload)) of
		    none ->
			case filelib:is_file(
			       filename:join([DocRoot, Path])) of
			    true ->
				Req:serve_file(Path, DocRoot);
			    false->
				Req:not_found()
			end;
		    Response ->
			Response
		end;
	    Method when Method =:= 'DELETE' ->
		case url_dispatch(Req, ?http_route:url_match(delete)) of
		    none ->
			case filelib:is_file(
			       filename:join([DocRoot, Path])) of
			    true ->
				Req:serve_file(
				  Path, DocRoot,
				  [{'Cache-Control',"max-age=14400"}]);
			    false->
				Req:not_found()
			end;
		    Response ->
			Response
		end;
	    Method when Method =:= 'OPTIONS'; Method =:= 'TRACE' -> 
		case filelib:is_file(
		       filename:join([DocRoot, Path])) of
		    true ->
			Req:serve_file(Path, DocRoot);
		    false->
			Req:not_found()
		end 
	end
    catch
        Type:What ->
	    ?DEBUG("request fialed: ~p:~p", [Type, What]),
            Report = ["web request failed",
                      {path, Path},
                      {type, Type}, {what, What},
                      {trace, erlang:get_stacktrace()}],
	    %% ?DEBUG("Request failed: ~p ", [Report]),
            ?ERROR("Request failed: ~p", [Report]),
            %% NOTE: mustache templates need \ because they are not awesome.
            Req:respond({500, [{"Content-Type", "text/plain"}],
                         "request failed, sorry\n"})
    end.

root(Req) ->
    %% ?INFO("start login...", []),
    {ok, HTMLOutput} = login:render([{show_error,   "false"}]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

%% root(no_session, Req) ->
%%     {ok, HTMLOutput} = login:render([{show_error, "true"},
%% 				     {login_error, "用户会话已删除，请重新登录！！"}]),
%%     Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}). 

%% root(invalid_session, Req, SessionId) ->
%%     Cookie = mochiweb_cookies:cookie(
%%     	       ?QZG_DY_SESSION,
%%     	       SessionId,
%%     	       [{max_age, 0}, {path, "/"}]),
%%     {ok, HTMLOutput} = login:render([{show_error, "true"},
%% 				     {login_error, "用户会话非法，请重新登录！！"}, Cookie]),
%%     Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).

url_dispatch(_, []) ->
    none;
url_dispatch(Req, [{Regexp,  Function}|T]) ->
    "/" ++ Path = Req:get(path),
    Method = Req:get(method),
    Match = re:run(Path, Regexp, [global, {capture, all_but_first, list}]),

    %% ?DEBUG("Path ~p, Method ~p, Math ~p", [Path, Method, Match]),

    case Match of
	{match, [MatchList]} ->
	    %% ?DEBUG("Path ~p, Method ~p, Math ~p", [Path, Method, Match]),
	    case valid_session(Req) of
		{ok, _} ->
		    case length(MatchList) of
			0 ->
			    %% No any URL param
			    Function({Method, Req});
			Length when Length > 0 ->
			    Function({Method, Req, MatchList})
		    end;
		%% {error, _} when Path =:= "login"->
		%%     %% Function({Method, Req, [["login"]]});
		%%     ?login_request:action(Req, login);
		{error, _Error} ->
		    %% ?INFO("failed to check session of url ~p,"
		    %% 	  "reseaon ~p, redirect to login...", [Path, _Error]),
		    
		    %% {ECode, Error} = ?err(operation_invalid_session, Error),
		    %% Req:respond({599,
		    %% 		 [{"Content-Type", "application/json"}],
		    %% 		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
		    %% 				{<<"einfo">>, ?to_b(Error)}]})})
		    
		    case _Error of
			no_session ->
			    ?DEBUG("no session !!"),
			    Req:respond(
			      {302, [{"Location", "/"},
			    	     {"Content-Type", "text/html; charset=UTF-8"}], 
			       "Redirecting /"});
			    %% root(no_session, Req);
			{invalid_session, SessionId} ->
			    Cookie = mochiweb_cookies:cookie(
			    	       ?QZG_DY_SESSION,
			    	       SessionId,
			    	       [{max_age, 0}, {path, "/"}]),
			    Req:respond(
			      {302, [{"Location", "/"},
			    	     {"Content-Type", "text/html; charset=UTF-8"}, Cookie], 
			       "Redirecting /"})
			    %% Req:respond(
			    %%   {301, [{"Location", "/"},
			    %% 	     {"Content-Type", "text/html; charset=UTF-8"}], 
			    %%    "Redirecting /"})
			    %% root(invalid_session, Req, SessionId)
		    end 
	    end;
	nomatch when Path =:= "login" ->
	    ?DEBUG("no match, login !!"),
	    ?login_request:action(Req, login);
	nomatch when Path =:= "login_force" ->
	    ?DEBUG("login force!!"),
	    ?login_request:action(Req, login_force);
	%% nomatch when Path =:= "login_redirect" ->
	%%     %% Payload = Req:recv_body(),
	%%     %% {struct, P} = mochijson2:decode(Payload),
	%%     %% RedirectPath = ?v(<<"redirect">>, P),
	%%     ?utils:respond(200, Req, {0, success}); 
	_ ->
	    url_dispatch(Req, T)		
    end.

