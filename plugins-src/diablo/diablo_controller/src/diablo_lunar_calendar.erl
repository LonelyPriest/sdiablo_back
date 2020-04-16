-module(diablo_lunar_calendar).
-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-compile(export_all).

-define (LUNAR_INFO,
	 [16#04bd8,16#04ae0,16#0a570,16#054d5,16#0d260,16#0d950,16#16554,16#056a0,16#09ad0,16#055d2,%% 1900-1909
	  16#04ae0,16#0a5b6,16#0a4d0,16#0d250,16#1d255,16#0b540,16#0d6a0,16#0ada2,16#095b0,16#14977,%% 1910-1919
	  16#04970,16#0a4b0,16#0b4b5,16#06a50,16#06d40,16#1ab54,16#02b60,16#09570,16#052f2,16#04970,%% 1920-1929
	  16#06566,16#0d4a0,16#0ea50,16#16a95,16#05ad0,16#02b60,16#186e3,16#092e0,16#1c8d7,16#0c950,%% 1930-1939
	  16#0d4a0,16#1d8a6,16#0b550,16#056a0,16#1a5b4,16#025d0,16#092d0,16#0d2b2,16#0a950,16#0b557,%% 1940-1949
	  16#06ca0,16#0b550,16#15355,16#04da0,16#0a5b0,16#14573,16#052b0,16#0a9a8,16#0e950,16#06aa0,%% 1950-1959
	  16#0aea6,16#0ab50,16#04b60,16#0aae4,16#0a570,16#05260,16#0f263,16#0d950,16#05b57,16#056a0,%% 1960-1969
	  16#096d0,16#04dd5,16#04ad0,16#0a4d0,16#0d4d4,16#0d250,16#0d558,16#0b540,16#0b6a0,16#195a6,%% 1970-1979
	  16#095b0,16#049b0,16#0a974,16#0a4b0,16#0b27a,16#06a50,16#06d40,16#0af46,16#0ab60,16#09570,%% 1980-1989
	  16#04af5,16#04970,16#064b0,16#074a3,16#0ea50,16#06b58,16#05ac0,16#0ab60,16#096d5,16#092e0,%% 1990-1999
	  16#0c960,16#0d954,16#0d4a0,16#0da50,16#07552,16#056a0,16#0abb7,16#025d0,16#092d0,16#0cab5,%% 2000-2009
	  16#0a950,16#0b4a0,16#0baa4,16#0ad50,16#055d9,16#04ba0,16#0a5b0,16#15176,16#052b0,16#0a930,%% 2010-2019
	  16#07954,16#06aa0,16#0ad50,16#05b52,16#04b60,16#0a6e6,16#0a4e0,16#0d260,16#0ea65,16#0d530,%% 2020-2029
	  16#05aa0,16#076a3,16#096d0,16#04afb,16#04ad0,16#0a4d0,16#1d0b6,16#0d250,16#0d520,16#0dd45,%% 2030-2039
	  16#0b5a0,16#056d0,16#055b2,16#049b0,16#0a577,16#0a4b0,16#0aa50,16#1b255,16#06d20,16#0ada0,%% 2040-2049
	  16#14b63,16#09370,16#049f8,16#04970,16#064b0,16#168a6,16#0ea50,16#06b20,16#1a6c4,16#0aae0,%% 2050-2059
	  16#092e0,16#0d2e3,16#0c960,16#0d557,16#0d4a0,16#0da50,16#05d55,16#056a0,16#0a6d0,16#055d4,%% 2060-2069
	  16#052d0,16#0a9b8,16#0a950,16#0b4a0,16#0b6a6,16#0ad50,16#055a0,16#0aba4,16#0a5b0,16#052b0,%% 2070-2079
	  16#0b273,16#06930,16#07337,16#06aa0,16#0ad50,16#14b55,16#04b60,16#0a570,16#054e4,16#0d160,%% 2080-2089
	  16#0e968,16#0d520,16#0daa0,16#16aa6,16#056d0,16#04ae0,16#0a9d4,16#0a2d0,16#0d150,16#0f252,%% 2090-2099
	  16#0d520 %% 2100
	 ]).

-define(SOLAR_MONTH, [31,28,31,30,31,30,31,31,30,31,30,31]).

lunar_days(Year) ->
    lunar_days(Year, 16#8000, 348).
lunar_days(Year, L, Acc) when L > 16#8 ->
    D = 
	case lists:nth(Year - 1900 + 1, ?LUNAR_INFO) band L of
	    0 -> 0;
	    _ -> 1
	end,
    lunar_days(Year, L bsr 1, Acc + D);
lunar_days(Year, _L, Acc) ->
    Acc + leap(days, Year).

leap(days, Year) ->
    case leap(month, Year) =:= 0 of
	true -> 0;
	false -> case lists:nth(Year - 1900 + 1, ?LUNAR_INFO) band 16#10000 =:= 0 of
		 true -> 29;
		 false -> 30
	     end
    end;

leap(month, Year) ->
    lists:nth(Year - 1900 + 1, ?LUNAR_INFO) band 16#f.

leap(month_days, Year, Month) ->
    case lists:nth(Year - 1900 + 1, ?LUNAR_INFO) band (16#10000 bsr Month) =:= 0 of
	true -> 29;
	false -> 30
    end.

solar(days, Year, 2)-> 
    case (Year rem 4 =:= 0 andalso Year rem 100 =/= 0)
	orelse (Year rem 400 =:= 0) of
	true -> 29; 
	false -> 28
    end;
solar(days, _Year, Month) ->
    lists:nth(Month, ?SOLAR_MONTH).


solar2lunar(Year, Month, Day) ->
    Offset0 = calendar:date_to_gregorian_days(Year, Month, Day) - calendar:date_to_gregorian_days(1900, 1, 31),
    ?DEBUG("Offset0 ~p", [Offset0]),
    {Metric, LunarYear} = lunar_year_by_offset(1900, Offset0),
    LeapMonth = leap(month, LunarYear),
    {LunarYear, lunar_month_by_offset(LunarYear, 1, LeapMonth, false, Metric, 0)}.

lunar_year_by_offset(Year, SolarDays) when SolarDays < 0 ->
    {SolarDays + lunar_days(Year - 1), Year - 1};
    
lunar_year_by_offset(Year, SolarDays) ->
    lunar_year_by_offset(Year + 1, SolarDays - lunar_days(Year)).

lunar_month_by_offset(_LunarYear, MonthIndex, _LeapMonth, _IsLeap, Offset, MonthDays) when Offset < 0 ->
    {MonthIndex -1, Offset + MonthDays + 1};
lunar_month_by_offset(_LunarYear, MonthIndex, _LeapMonth, _IsLeap, Offset, _MonthDays) when Offset =:= 0 ->
    {MonthIndex - 1, Offset + 1};

lunar_month_by_offset(LunarYear, MonthIndex, LeapMonth, IsLeap, Offset, _MonthDays) ->
    {Days, Index0, Leap0} = 
	case LeapMonth > 0 andalso MonthIndex =:= LeapMonth + 1 andalso (not IsLeap) of
	    true ->
		{leap(days, LunarYear), MonthIndex - 1, true}; 
	    false ->
		{leap(month_days, LunarYear, MonthIndex), MonthIndex, IsLeap}
		    
	end,
    lunar_month_by_offset(LunarYear,
			  Index0 + 1,
			  LeapMonth,
			  case Leap0 andalso Index0 =:= LeapMonth + 1 of
			      true -> false;
			      _    -> Leap0
			  end,				   
			  Offset - Days,
			  Days).
