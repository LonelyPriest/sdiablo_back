-module(diablo_controller_utils).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

min_value(V1, V2) when V1 > V2 ->  V2;
min_value(V1, _V2) -> V1.

%%--------------------------------------------------------------------
%% @desc : get current time
%% @return: format yyyymmddhhmmsss
%%--------------------------------------------------------------------
current_time(localtime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),
    
    lists:flatten(
      io_lib:format("~4..0w~2..0w~2..0w~2..0w~2..0w~2..0w",
		    [Year, Month, Date, Hour, Minute, Second]));

current_time(format_localtime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),

    lists:flatten(
      io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
		    [Year, Month, Date, Hour, Minute, Second]));

current_time(localdate) ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date]));

current_time(year) ->
    {{Year, _, _}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    lists:flatten(io_lib:format("~4..0w", [Year]));

current_time(timestamp) ->
    {M, S, _} = erlang:now(),
    
    M * 1000000 + S;

current_time(localtime2second) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} =
	calendar:now_to_local_time(erlang:now()),
    calendar:datetime_to_gregorian_seconds({{Year, Month, Date}, {Hour, Minute, Second}});

current_time(db) ->
    "CURRENT_TIMESTAMP()";

current_time(db_unix_timestamp) ->
    "UNIX_TIMESTAMP()".

correct_datetime(datetime, Datetime) ->
    {{Year, Month, Date}, {Hour, Minute, Second}} = calendar:now_to_local_time(erlang:now()),
    case Datetime of
	undefined ->
	    Time = lists:flatten(
		     io_lib:format("~4..0w-~2..0w-~2..0w ~2..0w:~2..0w:~2..0w",
				   [Year, Month, Date, Hour, Minute, Second])),
	    %% ?DEBUG("time ~p", [Time]),
	    Time;
	Datetime -> 
	    Time = ?to_b(
		      lists:flatten(
			io_lib:format("~2..0w:~2..0w:~2..0w", [Hour, Minute, Second]))), 
	    <<YYMMDD:10/binary, _/binary>> = Datetime, 
	    <<YYMMDD/binary, <<" ">>/binary, Time/binary>>
    end.

current_date() ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    {Year, Month, Date}.
current_date(format) ->
    {{Year, Month, Date}, {_, _, _}} = calendar:now_to_local_time(erlang:now()),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date])).


-spec to_date/2::(atom(), binary()|string()) -> calendar:date().
to_date(datetime, Datetime) when is_list(Datetime)->
    <<YYMMDD:10/binary, _/binary>> = ?to_b(Datetime), 
    to_date(date, YYMMDD);

to_date(datetime, Datetime) ->
    <<YYMMDD:10/binary, _/binary>> = Datetime,
    to_date(date, YYMMDD);


to_date(date, Date) when is_binary(Date) -> 
    [Y, M, D] = string:tokens(?to_s(Date), "-"),
    {?to_i(Y), ?to_i(M), ?to_i(D)};
to_date(date, Date) when is_list(Date)->
    SDate = ?to_s(Date),
    [Y, M, D] = string:tokens(SDate, "-"),
    {?to_i(Y), ?to_i(M), ?to_i(D)};
to_date(date, Date) when is_tuple(Date)->
    Date.


small_date(date, {Y, M, D}, {Y1, M1, D1}) ->
    case calendar:date_to_gregorian_days({Y, M, D}) < calendar:date_to_gregorian_days({Y1, M1, D1}) of
	true -> {Y, M, D};
	false -> {Y1, M1, D1}
    end.

big_date(date, {Y,M,D}, ?INVALID_DATE) ->
    {Y, M, D}; 
big_date(date, {Y, M, D}, {Y1, M1, D1}) ->
    case calendar:date_to_gregorian_days({Y, M, D}) > calendar:date_to_gregorian_days({Y1, M1, D1}) of
	true -> {Y, M, D};
	false -> {Y1, M1, D1}
    end;
big_date(date, {Y, M, D}, StringDate) ->
    big_date(date, {Y, M, D}, to_date(date, StringDate));
big_date(date, StringDate0, StringDate1) ->
    big_date(date, to_date(date, StringDate0), to_date(date, StringDate1)). 

compare_date(date, {Y, M, D}, {Y1, M1, D1}) ->
    calendar:date_to_gregorian_days({Y, M, D}) > calendar:date_to_gregorian_days({Y1, M1, D1});
compare_date(date, {Y, M, D}, StringDate) ->
    compare_date(date, {Y, M, D}, to_date(date, StringDate));
compare_date(date, StringDate0, StringDate1) ->
    compare_date(date, to_date(date, StringDate0), to_date(date, StringDate1)).


ecompare_date(date, {_Y, _M, _D}, {0, 0, 0}) ->
    true;
ecompare_date(date, {Y, M, D}, {Y1, M1, D1}) ->
    calendar:date_to_gregorian_days({Y, M, D}) >= calendar:date_to_gregorian_days({Y1, M1, D1});
ecompare_date(date, {Y, M, D}, StringDate) ->
    ecompare_date(date, {Y, M, D}, to_date(date, StringDate));
ecompare_date(date, StringDate0, StringDate1) ->
    ecompare_date(date, to_date(date, StringDate0), to_date(date, StringDate1)).
			
datetime2seconds(Datetime) when is_binary(Datetime)->
    <<YY:4/binary, "-",  MM:2/binary, "-", DD:2/binary, " ",
      HH:2/binary, ":", MMM:2/binary, ":", SS:2/binary>> = Datetime,

    calendar:datetime_to_gregorian_seconds({{?to_i(YY), ?to_i(MM), ?to_i(DD)},
					    {?to_i(HH), ?to_i(MMM), ?to_i(SS)}});
datetime2seconds(Datetime) ->
    datetime2seconds(?to_b(Datetime)).

date_before(Before) ->
    date_before(current_date(), Before).
date_before({Year, Month, Date}, Before) ->
    Days = calendar:date_to_gregorian_days({Year, Month, Date}),
    calendar:gregorian_days_to_date(Days - Before).

date_after({Year, Month, Date}, After) ->
    Days = calendar:date_to_gregorian_days({Year, Month, Date}),
    calendar:gregorian_days_to_date(Days + After).

current_date_after(After) ->
    CurrentDate = current_date(),
    {Year, Month, Date} = date_after(CurrentDate, After),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date])).
current_date_before(Before) ->
    {Year, Month, Date} = date_before(Before),
    lists:flatten(io_lib:format("~4..0w-~2..0w-~2..0w", [Year, Month, Date])).

fmonth(last, Year, Month) ->
    {LastYear, LastMonth} = 
	case Month - 1 == 0 of
	    true -> {Year - 1, 12};
	    false -> {Year, Month - 1}
	end,

    {LastYear, LastMonth}.

respond(batch, Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    %% ?DEBUG("value ~p", [Values]),
	    ?MODULE:respond(200, batch, Req, Values);
	{error, _Error} ->
	    ?MODULE:respond(200, batch, Req, [])
    end; 
respond(object, Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {Value});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

respond(200, Req, {ECode, Error}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(Error)}]})});

respond(200, _Req, Unkown) ->
    ?DEBUG("unexpect response: ~p", [Unkown]);

respond(StatusCode, Req, {ECode, Error}) ->
    Req:respond({StatusCode,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(Error)}]})}).

error_respond(list, Req, {ECode, EInfo}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode([{[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}]}])}).

respond(200, batch, Req, Content) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode(?to_tl(Content))});

respond(200, batch_mochijson, Req, Content) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 mochijson2:encode(Content)});

respond(200, object, Req, Content) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode(Content)});

respond(200, Req, {ECode, EInfo}, Extra) when is_tuple(Extra)->
    respond(200, Req, {ECode, EInfo}, [Extra]); 

respond(200, Req, {ECode, EInfo}, Extra) when is_list(Extra)->
    Req:respond({200,
		 [{"Content-Type", "application/json"}],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}] ++ Extra}
			     )});

respond(200, Headers, Req, {ECode, EInfo}) ->
    Req:respond({200,
		 [{"Content-Type", "application/json"},
		  Headers],
		 ejson:encode({[{<<"ecode">>, ?to_i(ECode)},
				{<<"einfo">>, ?to_b(EInfo)}]})});

respond(normal, Fun, Success, Req) ->
    case Fun() of
	{ok, Ok} ->
	    ?MODULE:respond(200, Req, Success(Ok));
	{error, Error} ->
	    ?MODULE:respond(200, Req, Error)
    end.


%% -----------------------------------------------------------------------------
%% @desc:   string present as a binary, to distinguish the number and string,
%%          such as 123 and "123"
%% @params: V -> list should be format [1, 2, 3],
%%               string should be format <<"123">>
%%               integer should be format 123
%% -----------------------------------------------------------------------------
to_sqls(proplists, {K, V}) when is_list(V)->
    S = lists:foldr(
	  fun(E, Acc)->
		  [case is_integer(E) of
		       true -> ?to_s(E);
		       false ->
			   case is_binary(E) of
			       true -> "\'" ++ ?to_s(E) ++ "\'";
			       false -> ?to_s(E)
			   end
		   end|Acc] end, [], V),
    case S of
	[] -> [];
	_  -> ?to_s(K) ++ " in(" ++ string:join(S, ",") ++ ")"
    end;
	
%% string
to_sqls(proplists, {K, V}) when is_binary(V) ->
    ?to_string(K) ++ "=" ++ "\'" ++ ?to_s(V) ++ "\'";

%% integer
to_sqls(proplists, {K, V}) when is_integer(V) ->
    ?to_string(K) ++ "=" ++ ?to_s(V);

%% float
to_sqls(proplists, {K, V}) when is_float(V)->
    ?to_string(K) ++ "=" ++ ?to_s(V);


%% integer
to_sqls(plus, {K, V}) when is_integer(V) ->
    ?to_string(K) ++ "=" ++ ?to_string(K) ++ "+" ++ ?to_s(V);

%% float
to_sqls(plus, {K, V}) when is_float(V)->
    ?to_string(K) ++ "=" ++ ?to_s(K) ++ "+" ++ ?to_s(V);
	
%% -----------------------------------------------------------------------------
%% concat tuple list to a sql with 'and', such as
%% [{<<"a">>, 1}, {<<"b">, 2}] => a = 1 and b = 2
%% -----------------------------------------------------------------------------
to_sqls(proplists, Proplists) when is_list(Proplists)->
    L = lists:filter(fun({_, V}) ->
			     V =/= [] andalso V =/= undefined
		     end, Proplists),
    to_sqls(proplists, L, "").

to_sqls(proplists, [], SQL) ->
    SQL;
to_sqls(proplists, [Proplist], SQL) ->
    SQL ++ to_sqls(proplists, Proplist);
to_sqls(proplists, [Proplist|T], SQL) ->
    to_sqls(proplists, T, SQL ++ to_sqls(proplists, Proplist) ++ " and ");


%% -----------------------------------------------------------------------------
%% concat tuple list to a sql with ',', such as
%% [{<<"a">>, 1}, {<<"b">, 2}] => a = 1 , b = 2
%% -----------------------------------------------------------------------------
to_sqls(proplists, comma, Proplists) when is_list(Proplists)->
    to_sqls(proplists, comma, Proplists, "");
to_sqls(plus, comma, Proplists) when is_list(Proplists)->
    to_sqls(plus, comma, Proplists, "").

to_sqls(proplists, comma, [Proplist], SQL) ->
    SQL ++ to_sqls(proplists, Proplist);
to_sqls(proplists, comma, [H|T], SQL) ->
    to_sqls(proplists, comma, T, SQL ++ to_sqls(proplists, H) ++ ",");

to_sqls(plus, comma, [Proplist], SQL) ->
    SQL ++ to_sqls(plus, Proplist);
to_sqls(plus, comma, [H|T], SQL) ->
    to_sqls(plus, comma, T, SQL ++ to_sqls(plus, H) ++ ",").


%% -----------------------------------------------------------------------------
%% @desc: correct conditions with special prefix
%% @param: prefx -> such as "a."
%% @Conditions: the key-value tuple or list, sucha {<<"id">>, 1}
%% @return:    {<<"a.id">>, 1}
%% -----------------------------------------------------------------------------
correct_condition(Prefix, Conditions) when is_tuple(Conditions) ->
    correct_condition(Prefix, [Conditions], []);
correct_condition(Prefix, Conditions) ->
    correct_condition(Prefix, Conditions, []).
correct_condition(_Prefix, [], Conditions) ->
    lists:reverse(Conditions);
correct_condition(Prefix, [{K, V}|T], Conditions) ->
    correct_condition(Prefix, T,
		      [{<<Prefix/binary, K/binary>>, V}|Conditions]).

%% -----------------------------------------------------------------------------
%% @desc: set db value by key
%% @params: key -> table property name of db,
%%          keyType -> type, such as float, string, integer
%% @params: value -> value of key
%% 
%% -----------------------------------------------------------------------------
v(_Key, _KeyType, []) ->
    [];
v(_Key, _KeyType, undefined) ->
    [];
%% v(_Key, _KeyType, <<>>) ->
%%     [];
v(Key, KeyType, Value) ->
    [{?to_b(Key), case KeyType of
		      float   -> ?to_f(Value);
		      string  -> ?to_b(Value);
		      integer -> ?to_i(Value)
		  end
     }].

v_0(Key, KeyType, Value) when Value == 0 ->
    v(Key, KeyType, []);
v_0(Key, KeyType, Value) ->
    v(Key, KeyType, Value).

value_from_proplists(Key, {Proplists}) ->
    proplists:get_value(Key, Proplists); 
value_from_proplists(Key, Proplists) ->
    proplists:get_value(Key, Proplists).

%% =============================================================================
%% @desc: add the sequence number of lists
%% @param: lists  -> [ {[{<<"a1", 1>>}, {<<"a2">>, 2}]}, ...]
%% @return: lists -> [ {[{<<"order_id">>, 1}, {<<"a1", 1>>}, {<<"a2">>, 2}]}, ...]
%% =============================================================================
%% order(Lists) ->
%%     order(Lists, 1, []).
%% order([], _, OrderedLists) ->
%%     lists:reverse(OrderedLists);
%% order([{H}|T], Inc, OrderedLists) ->
%%     order(T, Inc + 1, [{[{<<"order_id">>, Inc}|H]}|OrderedLists]).
seperator(csv) ->",".

create_export_file(Prefix, Merchant, UserId)->
    {file, Here} = code:is_loaded(?MODULE),
    ExportDir = filename:join(
		  [filename:dirname(filename:dirname(Here)),
		   "hdoc", "export", ?to_s(Merchant)]),
    ?DEBUG("export dir ~p", [ExportDir]),
    UUID = knife_uuid:v5(string, ?to_s(UserId)),

    File = Prefix ++ "-" ++ UUID ++ ".csv",
    ExportFile = filename:join([ExportDir, File]),
    Url = filename:join(["export", ?to_s(Merchant), File]),

    case filelib:ensure_dir(ExportFile) of
	ok -> ok; 
	{error, _} -> ok = file:make_dir(ExportDir)
    end, 
    {ok, ExportFile, Url}.

write(Fd, Content) ->
    case file:write(Fd, Content) of
	ok -> ok;
	{error, Error} ->
	    throw({error, Error})
    end.

-define(MAX_EMPLOYEE_ID, 8).
pack_string(String, Pack) -> 
    SS = ?to_string(String),
    pack_string(SS, ?to_string(Pack), length(SS)).
pack_string(String, _Pack, ?MAX_EMPLOYEE_ID) -> 
    String;
pack_string(String, Pack, Length) ->
    pack_string(Pack ++ String, Pack, Length + length(Pack)).

-define(MAX_FLOW_ID, 6).
pack_flow(Flow, Pack) -> 
    SS = ?to_string(Flow),
    pack_flow(SS, ?to_string(Pack), length(SS)).
pack_flow(Flow, _Pack, Length) when Length >= ?MAX_FLOW_ID -> 
    Flow;
pack_flow(Flow, Pack, Length) ->
    pack_flow(Pack ++ Flow, Pack, Length + length(Pack)).


-spec epoch_seconds/0 :: () -> diablo_cron:seconds().
epoch_seconds() -> 
    {Megasecs, Secs, Microsecs} = os:timestamp(),
    erlang:trunc((Megasecs * 1000000) + Secs + (Microsecs / 1000000)).


to_utf8(from_latin1, S) ->
    unicode:characters_to_list(S, utf8).
to_gbk(from_latin1, S) ->
    U8 = to_utf8(from_latin1, S),
    diablo_iconv:convert("utf-8", "gbk", U8).


nth(N, Setting) when is_binary(Setting)->
    nth(N, ?to_s(Setting));
nth(N, Setting) ->
    try
	?to_i(lists:nth(N, Setting)) - 48
    catch _:_ ->
	    ?NO
    end.

replace_list_at(S, Position, Value) when is_list(Value) ->
    ?to_s(replace_binary_list(?to_b(S), Position, ?to_b(Value), 1, <<>>));
replace_list_at(S, Position, Value) ->
    ?to_s(replace_binary_list(S, Position, ?to_b(Value), 1, <<>>)).
    
replace_binary_list(<<>>, Position, Value, _Len, Acc) ->
    case Position =< size(Acc) of
	true -> Acc;
	false ->
	    case Position - size(Acc) of
		1 -> <<Acc/binary, Value/binary>>;
		Any -> 
		    R = binary:copy(<<"0">>, Any - 1),
		    <<Acc/binary, R/binary, Value/binary>>
	    end
    end;
    
replace_binary_list(<<H:1/binary, T/binary>>, Position, Value, Len, Acc) ->
    case Position =:= Len of
	true ->
	    replace_binary_list(T, Position, Value, Len + 1, <<Acc/binary, Value/binary>>); 
	false ->
	    replace_binary_list(T, Position, Value, Len + 1,  <<Acc/binary, H/binary>>)
    end.

dbvalue(Value) when Value == 0 ->
    ?INVALID_OR_EMPTY;
dbvalue(Value) ->
    Value.
	
check_match_mode(Field, Prompt) ->
    check_match_mode(?to_s(Field), ?to_s(Prompt), []).
check_match_mode(Field, Prompt, Prefix) ->
    First = string:substr(Prompt, 1, 1),
    Last = string:substr(Prompt, string:len(Field)),
    Match = string:strip(Prompt, both, $/),

    case {First, Match, Last} of
	{"/", Match, "/"} ->
	    ?to_s(Prefix) ++ Field ++ "=\'" ++ Match ++ "\'"; 
	{"/", Match, _} ->
	    ?to_s(Prefix) ++ Field ++ " like \'" ++ Match ++ "%\'";
	{_, Match, "/"} ->
	    ?to_s(Prefix) ++ Field ++ " like \'%" ++ Match ++ "\'";
	{_, Match, _}->
	    ?to_s(Prefix) ++ Field ++ " like \'%" ++ Match ++ "%\'"
    end.

check_empty(barcode, Barcode) ->
    Barcode =:= undefined
	orelse Barcode =:= []
	orelse Barcode =:= <<>>
	orelse Barcode =:= ?EMPTY_DB_BARCODE
	orelse Barcode =:= <<"0">>;

check_empty(good_extra, GoodExtraId) ->
    GoodExtraId =:= <<>>
	orelse GoodExtraId =:= [].

get_modified(NewValue, OldValue) when NewValue =/= OldValue -> NewValue;
get_modified(_NewValue, _OldValue) ->  undefined.

random(Max) ->
    <<A:32, B:32, C:32>> = crypto:rand_bytes(12),
    random:seed({A,B,C}),
    random:uniform(Max).
