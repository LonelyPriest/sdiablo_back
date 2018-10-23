-module(diablo_controller_employ_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("GET Req ~n~p", [Req]),
    {ok, HTMLOutput} = employ_frame:render(
			 [
			  {navbar, ?menu:navbars(?MODULE, Session)},
			  {basebar, ?menu:w_basebar(Session)},
			  {sidebar, sidebar(Session)}
			  %% {ngapp, "employApp"},
			  %% {ngcontroller, "employCtrl"}
			 ]),
    Req:respond({200, [{"Content-Type", "text/html"}], HTMLOutput}).
     
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_employe"}) ->
    ?DEBUG("list employ with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),       
    case ?w_user_profile:get(employee, Merchant) of
	{ok, Employees} ->
	    ?utils:respond(200, batch, Req, Employees);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end;

action(Session, Req, {"list_department"}) ->
    ?DEBUG("list_department with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(batch, fun() -> ?w_user_profile:get(department, Merchant) end, Req);

%%--------------------------------------------------------------------
%% @desc: DELTE action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_employe", EmployId}) ->
    ?DEBUG("delete employ with session ~p, id ~p", [Session, EmployId]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(delete, Merchant, EmployId) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"recover_employe", EmployId}) ->
    ?DEBUG("recover employ with session ~p, id ~p", [Session, EmployId]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(recover, Merchant, EmployId) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(delete_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.


%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"new_employe"}, Payload) ->
    ?DEBUG("new employ with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(new, [{<<"merchant">>, Merchant}|Payload]) of
	{ok, Name} ->
	    ?utils:respond(200, Req, ?succ(add_employ, Name));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_employe", Id}, Payload) ->
    ?DEBUG("update a employ with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    case ?employ:employ(update, Merchant, Id, Payload) of
	{ok, EmployId} ->
	    ?w_user_profile:update(employee, Merchant),
	    ?utils:respond(200, Req, ?succ(update_employ, EmployId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"new_department"}, Payload) ->
    ?DEBUG("new department with session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    ?utils:respond(normal,
		   fun()-> ?employ:department(new, Merchant, Payload) end,
		   fun(DId)-> ?w_user_profile:update(department, Merchant),
			      ?succ(add_employ, DId)
		   end,
		   Req);

action(Session, Req, {"add_employee_of_department"}, Payload) ->
    ?DEBUG("add_employee_of_department with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    
    case ?v(<<"department">>, Payload) =:= undefined
	orelse ?v(<<"employee">>, Payload) =:= undefined of
	true ->
	    ?utils:respond(200, Req, ?err(params_error, "add_employee_of_department"));
	false -> 
	    case ?employ:department(add_employee, Merchant, Payload) of
		{ok, AddId} ->
		    ?utils:respond(200, Req, ?succ(add_employ, AddId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end
    end;

action(Session, Req, {"list_employee_of_department"}, Payload) ->
    ?DEBUG("list_employee_of_department with Session ~p~npaylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Department = ?v(<<"department">>, Payload),
    %% ?utils:respond(batch, fun() -> ?employ:department(list_employee_of, Merchant, Department) end, Req),
    case ?employ:department(list_employee, Merchant, Department) of
	{ok, Employees} ->
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0}, {<<"data">>, Employees}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

sidebar(Session) ->
    S1 = 
	case ?right_auth:authen(?list_employe, Session) of
	    {ok, ?list_employe} ->
		[{"employ_detail", "员工详情", "glyphicon glyphicon-book"}];
	    _ -> []
	end,

    S2 = 
	case ?right_auth:authen(?new_employe, Session) of
	    {ok, ?new_employe} ->
		[{"employ_new", "新增员工", "glyphicon glyphicon-plus"}];
	    _ -> []
	end,

    %% S3 = 
    %% 	case ?right_auth:authen(?new_department, Session) of
    %% 	    {ok, ?new_department} ->
    %% 		[{"new_department", "新增部门", "glyphicon glyphicon-plus"}];
    %% 	    _ -> []
    %% 	end,

    S4 = 
	case ?right_auth:authen(?list_department, Session) of
	    {ok, ?list_department} ->
		[{"department_detail", "部门详情", "glyphicon glyphicon-book"}];
	    _ -> []
	end,

    case S2 ++ S1 ++ S4 of
	[] -> [];
	Sidebar -> ?menu:sidebar(level_1_menu, Sidebar)
    end.


