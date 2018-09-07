-module(diablo_pagination).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-export([pagination/4]).

pagination(no_response, TotalFun, PageFun, Payload) ->
    Match                = ?value(<<"match">>, Payload, 'and'),
    {struct, Conditions} = correct_payload(Payload),
    %% {struct, Conditions} =
    %% 	case ?value(<<"fields">>, Payload) of
    %% 	    undefined ->
    %% 		case ?value(<<"condition">>, Payload) of
    %% 		    undefined -> {struct, []};
    %% 		    {struct, Any} -> {struct, lists:keydelete(<<"region">>, 1, Any)}
    %% 		end; 
    %% 	    {struct, Any} ->
    %% 		{struct, lists:keydelete(<<"region">>, 1, Any)}
    %% 	end,

    ?DEBUG("conditions ~p", [Conditions]),

    CurrentPage  = ?value(<<"page">>, Payload, 1), 
    ItemsPerPage  = ?value(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE),

    case page(Conditions, CurrentPage, fun(C) -> TotalFun(?to_a(Match), C) end) of
	{error, Error} -> {error, Error};
	{Total, Others} -> 
	    case Total =:= 0 andalso CurrentPage =:= 1 of
		true ->
		    {ok, Total, []}; 
		false ->
		    case PageFun(?to_a(Match), CurrentPage, ItemsPerPage, Conditions) of
			{ok, Details} ->
			    {ok, Total, Details, Others}; 
			{error, Error} ->
			    {error, Error}
		    end
	    end
    end;

pagination(TotalFun, PageFun, Req, Payload) ->
    Match = ?value(<<"match">>, Payload, 'and'),
    {struct, Conditions} = correct_payload(Payload),
	%% case ?value(<<"fields">>, Payload) of
	%%     undefined ->
	%% 	case ?value(<<"condition">>, Payload) of
	%% 	    undefined -> {struct, []};
	%% 	    {struct, Any} ->
	%% 		F = lists:keydelete(<<"region">>, 1, Any),
	%% 		case ?v(<<"account">>, F) of
	%% 		    undefined -> {struct, lists:keydelete(<<"region">>, 1, Any)};
	%% 		    UserId ->
	%% 			case ?right:get(account, merchant, UserId) of
	%% 			    {ok, []} ->
	%% 				{struct, lists:keydelete(<<"region">>, 1, Any)};
	%% 			    {ok, Account} ->
	%% 				lists:keyreplace(
	%% 				  <<"account">>, 1, Any, {<<"account">>, ?v(<<"id">>, Account)})
	%% 			end
	%% 		end
	%% 	end; 
	%%     {struct, Any} ->
	%% 	F = lists:keydelete(<<"region">>, 1, Any),
	%% 	case ?v(<<"account">>, F) of
	%% 	    undefined -> {struct, lists:keydelete(<<"region">>, 1, Any)};
	%% 	    UserId ->
	%% 		case ?right:get(account, merchant, UserId) of
	%% 		    {ok, []} ->
	%% 			{struct, lists:keydelete(<<"region">>, 1, Any)};
	%% 		    {ok, Account} ->
	%% 			lists:keyreplace(
	%% 			  <<"account">>, 1, Any, {<<"account">>, ?v(<<"id">>, Account)})
	%% 		end
	%% 	end
	%% 	%% {struct, lists:keydelete(<<"region">>, 1, Any)}
	%% end,

    ?DEBUG("conditions ~p", [Conditions]),
    CurrentPage  = ?value(<<"page">>, Payload, 1), 
    ItemsPerPage = ?value(<<"count">>, Payload, ?DEFAULT_ITEMS_PERPAGE),
    
    case page(Conditions, CurrentPage, fun(C) -> TotalFun(?to_a(Match), C) end) of 
	{error, Error} ->
	    ?utils:respond(200, Req, Error);
	{Total, Others} -> 
	    case Total =:= 0 andalso CurrentPage =:= 1 of
		true ->
		    ?utils:respond(
		       200, object, Req, {[{<<"ecode">>, 0},
					   {<<"total">>, Total},
					   {<<"data">>, []}]}); 
		false ->
		    case PageFun(?to_a(Match), CurrentPage, ItemsPerPage, Conditions) of
			{ok, Details} ->
			    ?utils:respond(
			       200, object, Req, {[{<<"ecode">>, 0},
						   {<<"total">>, Total},
						   {<<"data">>, Details}] ++ Others}); 
			{error, Error} ->
			    ?utils:respond(200, Req, Error) 
		    end
	    end
    end.


page([], 1, TotalFun) ->
    %% {0, []};
    case TotalFun([]) of
	{ok, []} ->
	    {0, []};
	{ok, R} ->
	    {?v(<<"total">>, R), proplists:delete(<<"total">>, R)};
	Error ->
	    Error
    end;
page(Conditions, 1, TotalFun) ->
    case TotalFun(Conditions) of
	{ok, []} ->
	    {0, []};
	{ok, R} ->
	    {?v(<<"total">>, R), proplists:delete(<<"total">>, R)};
	Error ->
	    Error
    end;
page(_, _, _TotalFun) ->
    {0, []}.


correct_payload(Payload)->
    case ?value(<<"fields">>, Payload) of
	undefined ->
	    case ?value(<<"condition">>, Payload) of
		undefined -> {struct, []};
		{struct, Any} ->
		    F = lists:keydelete(<<"region">>, 1, Any),
		    case ?v(<<"account">>, F) of
			undefined -> {struct, lists:keydelete(<<"region">>, 1, Any)};
			UserName ->
			    case ?right:get(account, merchant, UserName) of
				{ok, []} ->
				    {struct, lists:keydelete(<<"region">>, 1, Any)};
				{ok, Account} ->
				    {struct,
				     lists:keyreplace(
				       <<"account">>, 1, Any, {<<"account">>, ?v(<<"id">>, Account)})}
			    end
		    end
	    end; 
	{struct, Any} ->
	    F = lists:keydelete(<<"region">>, 1, Any),
	    case ?v(<<"account">>, F) of
		undefined -> {struct, lists:keydelete(<<"region">>, 1, Any)};
		UserName ->
		    case ?right:get(account, merchant, UserName) of
			{ok, []} ->
			    {struct, lists:keydelete(<<"region">>, 1, Any)};
			{ok, Account} ->
			    {struct,
			     lists:keyreplace(
			       <<"account">>, 1, Any, {<<"account">>, ?v(<<"id">>, Account)})}
		    end
	    end
    end.
    
