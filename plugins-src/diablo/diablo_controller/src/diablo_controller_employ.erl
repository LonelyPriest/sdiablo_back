%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 17 Sep 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_employ).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-export([employ/2, employ/3, employ/4, department/2, department/3]).

-define(SERVER, ?MODULE). 
-define(tbl_employ, "employees").


-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
employ(new, Props) ->
    gen_server:call(?MODULE, {new_employee, Props});
employ(list, Merchant) ->
    employ(list, Merchant, []);
employ(list_manager, Merchant) ->
    gen_server:call(?MODULE, {list_manager, Merchant}).

employ(delete, Merchant, EmployeeId) ->
    gen_server:call(?MODULE, {delete_employee, Merchant, EmployeeId});
employ(recover, Merchant, EmployeeId) ->
    gen_server:call(?MODULE, {recover_employee, Merchant, EmployeeId});
employ(list, Merchant, Conditions) ->
    gen_server:call(?MODULE, {list_employee, Merchant, Conditions}).
    

department(list, Merchant) ->
    gen_server:call(?MODULE, {list_department, Merchant, []}).
department(new, Merchant, Attrs) -> 
    gen_server:call(?MODULE, {new_department, Merchant, Attrs});
department(add_employee, Merchant, Attrs) -> 
    gen_server:call(?MODULE, {add_employee_of_department, Merchant, Attrs});
department(del_employee, Merchant, Attrs) ->
    gen_server:call(?MODULE, {del_employee_of_department, Merchant, Attrs});
department(list_employee, Merchant, Department) -> 
    gen_server:call(?MODULE, {list_employee_of_department, Merchant, Department}).

employ(update, Merchant, EmployeeId, Attrs) ->
    gen_server:call(?MODULE, {update_employee, Merchant, EmployeeId, Attrs}).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================
init([]) ->
    {ok, #state{}}.

handle_call({new_employee, Props}, _From, State)->
    ?DEBUG("new employ with props ~p", [Props]),
    Name     = ?v(<<"name">>, Props),
    %% NamePy   = ?v(<<"name_py">>, Props),
    Sex      = ?v(<<"sex">>, Props),
    Mobile   = ?v(<<"mobile">>, Props),
    Address  = ?v(<<"address">>, Props),
    Entry    = ?v(<<"entry">>, Props),
    Shop     = ?v(<<"shop">>, Props),
    Merchant = ?v(<<"merchant">>, Props),

    %% name can not be same
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_employ
	++ " where "
	++ " name=" ++ "\"" ++ ?to_s(Name) ++ "\""
	%% %% ++ " or "
	%% ++ " mobile = " ++ "\"" ++ ?to_s(Mobile) ++ "\""
	++ " and merchant=" ++ ?to_s(Merchant),
    
    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Number = ?utils:pack_string(new_number(Merchant), 0),
	    Sql1 = "insert into " ++ ?tbl_employ
		++ "(number, name, sex, mobile, address, shop, entry, merchant)"
		++ " values ("
		++ "\"" ++ ?to_s(Number) ++ "\","
		++ "\"" ++ ?to_s(Name) ++ "\","
		++ ?to_s(Sex) ++ ","
		++ "\"" ++ ?to_s(Mobile) ++ "\","
		++ "\"" ++ ?to_s(Address) ++ "\","
		++ ?to_s(Shop) ++ ","
		++ "\"" ++ ?to_s(Entry) ++ "\","
		++ ?to_s(Merchant) ++ ");",
		
	    ?DEBUG("sql to employ ~ts", [?to_b(Sql1)]),
	    Reply = ?sql_utils:execute(write, Sql1, Name),
	    ?w_user_profile:update(employee, Merchant),
	    {reply, Reply, State};
	    %% case ?mysql:fetch(write, Sql1) of
	    %% 	{ok, _} ->
	    %% 	    {reply, {ok, Name}, State};
	    %% 	{error, {ECode, _}} ->
	    %% 	    {reply, {error, ?err(db_error, ECode)}, State}
	    %% end;
	{ok, _Any} ->
	    %% ?DEBUG("merchant ~p has been exist", [Name]),
	    {reply, {error, ?err(employ_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({delete_employee, Merchant, EmployeeId}, _From, State) ->
    ?DEBUG("delete_employee with merchant ~p, employeeId ~p", [Merchant, EmployeeId]), 
    Sql = "update employees set deleted=1 where id=" ++ ?to_s(EmployeeId)
	++ " and merchant=" ++ ?to_s(Merchant),
    
    case ?mysql:fetch(write, Sql) of
	{ok, _} ->
	    {reply, {ok, EmployeeId}, State};
	{error, {_, Err}} ->
	    {reply, {error, ?err(db_error, Err), State}}
    end;

handle_call({recover_employee, Merchant, EmployeeId}, _From, State) ->
    ?DEBUG("recover_employee with merchant ~p, employeeId ~p", [Merchant, EmployeeId]), 
    Sql = "update employees set deleted=0 where id=" ++ ?to_s(EmployeeId)
	++ " and merchant=" ++ ?to_s(Merchant),

    case ?mysql:fetch(write, Sql) of
	{ok, _} ->
	    {reply, {ok, EmployeeId}, State};
	{error, {_, Err}} ->
	    {reply, {error, ?err(db_error, Err), State}}
    end; 

handle_call({update_employee, Merchant, EmployeeId, Attrs}, _From, State) ->
    ?DEBUG("Update employee with merchant ~p, employeeId ~p~n, attrs ~p",
	   [Merchant, EmployeeId, Attrs]),

    Name    = ?v(<<"name">>, Attrs),
    Sex     = ?v(<<"sex">>, Attrs),
    Mobile  = ?v(<<"mobile">>, Attrs),
    Address = ?v(<<"address">>, Attrs),
    Shop    = ?v(<<"shop">>, Attrs),
    Entry   = ?v(<<"entry">>, Attrs),
    Position = ?v(<<"position">>, Attrs),
    
    NameExist =
	case Name of
	    undefined -> {ok, []} ;
	    Name ->
		Sql = "select id, name from employees"
		    " where name=" ++ "\'" ++ ?to_s(Name) ++ "\'"
		    ++ " and merchant=" ++ ?to_s(Merchant)
		    ++ " and deleted=" ++ ?to_s(?NO),
		case ?sql_utils:execute(s_read, Sql) of
		    {ok, R} -> {ok, R};
		    Error1 -> Error1
		end
	end,

    case NameExist of
	{ok, []} ->
	    Updates = ?utils:v(name, string, Name)
		++ ?utils:v(sex, integer, Sex)
		++ ?utils:v(mobile, string, Mobile)
		++ ?utils:v(address, string, Address)
		++ ?utils:v(shop, integer, Shop)
		++ ?utils:v(entry, string, Entry)
		++ ?utils:v(position, integer, Position),

	    
	    Sql1 = "update employees set "
		++ ?utils:to_sqls(proplists, comma, Updates)
		++ " where id=" ++ ?to_s(EmployeeId)
		++ " and merchant=" ++ ?to_s(Merchant),

	    Reply = ?sql_utils:execute(write, Sql1, EmployeeId), 
	    {reply, Reply, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_employee, Merchant, Conditions}, _From, State) ->
    %% ?DEBUG("list_employee with Merchant ~p, Conditions ~p", [Merchant, Conditions]),
    Sql = "select " ++ fields()
	++ " from " ++ ?tbl_employ
	++ " where " ++
	case Conditions of
	    [] -> [];
	    Conditions ->
		?utils:to_sqls(proplists, Conditions) ++ " and "
	end
    %% ++ "position in(1,2)"
	++ " merchant=" ++ ?to_s(Merchant) 
    %% ++ " and deleted=" ++ ?to_s(?NO)
	++ " order by shop",
    
    case ?mysql:fetch(read, Sql) of
	{ok, Employees} ->
	    {reply, {ok, Employees}, State};
	{error, {_, Error}} ->
	    {reply, ?err(db_error, Error), State}
    end;

handle_call({list_manager, Merchant}, _From, State) ->
    Sql = "select id, name, mobile, shop, merchant"
	" from employees"
	" where position=0 and merchant="  ++ ?to_s(Merchant),
    Reply = 
	case ?sql_utils:execute(read, Sql) of
	    {ok, []} -> {ok, []};
	    {ok, Employees} -> {ok, Employees};
	    {error, _Error} -> {ok, []}
	end,
    
    {reply, Reply, State};

handle_call({new_department, Merchant, Attrs}, _From, State)->
    ?DEBUG("new department with props ~p", [Attrs]),
    Name      = ?v(<<"name">>, Attrs),
    Master    = ?v(<<"master">>, Attrs, []),
    Comment   = ?v(<<"comment">>, Attrs, []),
    Datetime  = ?utils:current_time(format_localtime),

    %% name can not be same
    Sql = "select id, name from department where merchant=" ++ ?to_s(Merchant)
	++ " and name = " ++ "\"" ++ ?to_string(Name) ++ "\""
	++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} -> 
	    Sql1 = "insert into department"
		++ "(merchant, name, master, comment, entry_date)"
		++ " values ("
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?to_s(Name) ++ "\'," 
		++ "\'" ++ ?to_s(Master) ++ "\',"
		++ "\'" ++ ?to_s(Comment) ++ "\'," 
		++ "\"" ++ ?to_s(Datetime) ++ "\")",
	    
	    Reply = ?sql_utils:execute(insert, Sql1),
	    %% ?w_user_profile:update(region, Merchant),
	    {reply, Reply, State};
	{ok, _Any} ->
	    {reply, {error, ?err(department_exist, Name)}, State};
	Error ->
	    {reply, Error, State}
    end;

handle_call({list_department, Merchant, Conditions}, _From, State) ->
    Sql = "select id, name, master as master_id, comment, entry_date from department"
	" where merchant=" ++ ?to_s(Merchant)
	++ ?sql_utils:condition(proplists, Conditions)
	++ " and deleted=" ++ ?to_s(?NO)
	++ " order by id desc",
    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call({add_employee_of_department, Merchant, Attrs}, _From, State) ->
    ?DEBUG("add_employee_of_department: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Department = ?v(<<"department">>, Attrs),
    Employee   = ?v(<<"employee">>, Attrs),
    
    Sql = "select id, department, employ, deleted from employee_locate"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and department=" ++ ?to_s(Department)
	++ " and employ=\'" ++ ?to_s(Employee) ++ "\'",
    %% ++ " and deleted=" ++ ?to_s(?NO),

    case ?sql_utils:execute(s_read, Sql) of
	{ok, []} ->
	    Sql1 = "insert into employee_locate("
		"department, employ, position, merchant, entry)"
		" values ("
		++ ?to_s(Department) ++ ","
		++ "\'" ++ ?to_s(Employee) ++ "\',"
		++ ?to_s(0) ++ ","
		++ ?to_s(Merchant) ++ ","
		++ "\'" ++ ?utils:current_time(localdate) ++ "\')", 
	    Reply = ?sql_utils:execute(insert, Sql1),
	    {reply, Reply, State};
	{ok, Emp} ->
	    case ?v(<<"deleted">>, Emp) of
		?NO ->
		    {reply, {error, ?err(department_employee_added, Employee)}, State};
		?YES ->
		    Sql1 = "update employee_locate set deleted=" ++ ?to_s(?NO)
			++ " where merchant=" ++ ?to_s(Merchant)
			++ " and department=" ++ ?to_s(Department)
			++ " and employ=\'" ++ ?to_s(Employee) ++ "\'",
		    Reply = ?sql_utils:execute(write, Sql1, Employee),
		    {reply, Reply, State}
	    end;
	Error ->
	    {reply, Error, State}
    end;

handle_call({del_employee_of_department, Merchant, Attrs}, _From, State) ->
    ?DEBUG("del_employee_of_department: merchant ~p, Attrs ~p", [Merchant, Attrs]),
    Department = ?v(<<"department">>, Attrs),
    Employee   = ?v(<<"employee">>, Attrs),
    Sql = "update employee_locate set deleted=" ++ ?to_s(?YES)
	++ " where merchant=" ++ ?to_s(Merchant)
	++ " and department=" ++ ?to_s(Department)
	++ " and employ=\'" ++ ?to_s(Employee) ++ "\'",
    Reply = ?sql_utils:execute(write, Sql, Employee),
    {reply, Reply, State};

handle_call({list_employee_of_department, Merchant, Department}, _From, State) ->
    ?DEBUG("list_employee_of_department: merchant ~p, Department ~p", [Merchant, Department]), 
    Sql = "select id, department, employ as employee_id, entry from employee_locate"
	" where merchant=" ++ ?to_s(Merchant)
	++ " and department=" ++ ?to_s(Department)
	++ " and deleted=" ++ ?to_s(?NO),

    Reply = ?sql_utils:execute(read, Sql),
    {reply, Reply, State};

handle_call(_Request, _From, State) ->
    Reply = ok,
    {reply, Reply, State}.


handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.


terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
fields() ->
    "id"
	", number"
	", name"
	", sex"
	", entry"
	", position as pos_id"
	", mobile"
	", address"
	", shop as shop_id"
	", deleted as state".

new_number(Merchant) ->
    ?inventory_sn:sn(member, Merchant). 
    
