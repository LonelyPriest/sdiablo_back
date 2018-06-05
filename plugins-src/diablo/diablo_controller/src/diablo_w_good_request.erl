-module(diablo_w_good_request).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(gen_request).

-export([action/2, action/3, action/4]).
%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req) ->
    ?DEBUG("unkown req ~p with session ~p", [Req, Session]). 

%%--------------------------------------------------------------------
%% @desc: GET action
%%--------------------------------------------------------------------
action(Session, Req, {"list_supplier"}) ->
    ?DEBUG("list supplier with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    %% batch_responed(fun()->?supplier:supplier(w_list, Merchant) end, Req);
    batch_responed(fun()->?w_user_profile:get(firm, Merchant) end, Req); 

action(Session, Req, {"list_brand"}) ->
    ?DEBUG("list brand with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    %% batch_responed(fun()->?w_user_profile:get(brand, Merchant) end, Req),
    case  ?w_user_profile:get(brand, Merchant) of
	{ok, Values} ->
	    ?utils:respond(200, batch_mochijson, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end;


action(Session, Req, {"list_type"}) ->
    ?DEBUG("list_type with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session), 
    batch_responed(fun()->?w_user_profile:get(type, Merchant) end, Req); 

action(Session, Req, {"list_w_size"}) ->
    ?DEBUG("list_purchaser_size with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(fun()->?w_user_profile:get(size_group, Merchant) end, Req); 
    

action(Session, Req, {"list_color_type"}) ->
    ?DEBUG("list_color_type with session ~p", [Session]), 
    Merchant = ?session:get(merchant, Session),
    batch_responed(fun()->?w_user_profile:get(color_type, Merchant)end, Req); 

action(Session, Req, {"list_w_color"}) ->
    ?DEBUG("list_purchaser_color with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(fun()->?w_user_profile:get(color, Merchant) end, Req);

action(Session, Req, {"list_w_promotion"}) ->
    ?DEBUG("list_w_promotion with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),
    batch_responed(fun()->?w_user_profile:get(promotion, Merchant) end, Req);
    
action(Session, Req, {"list_w_good"}) ->
    ?DEBUG("list_purchaser_good with session ~p", [Session]),
    Merchant = ?session:get(merchant, Session),    
    Groups = ?w_inventory:purchaser_good(lookup, Merchant),
    ?utils:respond(200, batch, Req, Groups);

action(Session, Req, {"get_w_good", Id}) ->
    ?DEBUG("get_w_good_by_id with session ~p, id ~p", [Session, Id]),
    Merchant    = ?session:get(merchant, Session),
    object_responed(
      fun() -> ?w_inventory:purchaser_good(lookup, Merchant, Id) end, Req).

%%--------------------------------------------------------------------
%% @desc: POST action
%%--------------------------------------------------------------------
action(Session, Req, {"delete_w_good", Id}, Payload) ->
    ?DEBUG("delete_w_good with session ~p, id ~p", [Session, Id]),

    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand = ?v(<<"brand">>, Payload),
    Merchant = ?session:get(merchant, Session),
    case ?w_inventory:purchaser_good(delete, Merchant, {Id, StyleNumber, Brand}) of
	{ok, GoodId} ->
	    ?utils:respond(200, Req, ?succ(delete_purchaser_good, GoodId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;
%%
%% size
%%
action(Session, Req, {"new_w_size"}, Payload) ->
    ?DEBUG("new purchaser size with session ~p,  paylaod ~p", [Session, Payload]),

    Merchant = ?session:get(merchant, Session),
    case ?attr:size_group(new, Merchant, Payload) of
	{ok, GId} ->
	    ?w_user_profile:update(size_group, Merchant),
	    ?utils:respond(200, Req, ?succ(add_size_group, GId), {<<"id">>, GId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

%%
%% color
%%
action(Session, Req, {"new_w_color"}, Payload) ->
    ?DEBUG("new_w_color with session ~p,  paylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),
    
    case 
	case ?v(<<"bcode">>, Payload) of
	    undefined ->
		ok;
	    _BCode ->
		case AutoBarcode of
		    ?YES ->
			{error, ?err(self_bcode_not_allowed, Merchant)};
		    ?NO ->
			ok
		end
	end
    of
	ok -> 
	    case ?attr:color(w_new, Merchant, Payload ++ [{<<"auto_barcode">>, AutoBarcode}]) of
		{ok, ColorId} ->
		    ?utils:respond(200, Req, ?succ(add_color, ColorId), {<<"id">>, ColorId}),
		    ?w_user_profile:update(color, Merchant);
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"get_colors"}, Payload) ->
    ?DEBUG("get color with session ~p,  paylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session),
    ColorIds = ?v(<<"color">>, Payload), 
    batch_responed(fun()->?attr:color(w_list, Merchant, ColorIds) end, Req); 

%%
%% good
%%
action(Session, Req, {"get_w_good"}, Payload) ->
    ?DEBUG("get_w_good with session ~p, payload~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand       = ?v(<<"brand">>, Payload),
    object_responed_with_code(
      fun() ->
	      ?w_inventory:purchaser_good(lookup, Merchant, StyleNumber, Brand)
      end, Req); 


action(Session, Req, {"get_used_w_good"}, Payload) ->
    ?DEBUG("get_used_w_good with session ~p, payload~n~p", [Session, Payload]),
    Merchant    = ?session:get(merchant, Session),
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand       = ?v(<<"brand">>, Payload),
    %% Shops       = ?v(<<"shops">>, Payload),
    case ?w_inventory:purchaser_good(used, Merchant, StyleNumber, Brand) of
	{ok, Details} ->
	    ?DEBUG("details ~p", [Details]),
	    ?utils:respond(200, object, Req, {[{<<"ecode">>, 0},
					       {<<"data">>, Details}]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end; 

action(Session, Req, {"match_w_good_style_number"}, Payload) ->
    ?DEBUG("match_w_good_style_number with session ~p, Payload ~p",
	   [Session, Payload]),
    Merchant     = ?session:get(merchant, Session),
    PromptNumber = ?v(<<"prompt_value">>, Payload),
    batch_responed(
      fun() ->
	      ?w_inventory:match(style_number, Merchant, PromptNumber )
      end, Req);

action(Session, Req, {"match_w_good"}, Payload) ->
    ?DEBUG("match_w_good with session ~p, Payload ~p",
	   [Session, Payload]),
    Merchant     = ?session:get(merchant, Session),
    PromptNumber = ?v(<<"prompt_value">>, Payload),
    Firm         = ?v(<<"firm">>, Payload), 
    batch_responed(
      fun() -> ?w_inventory:match(
		  style_number_with_firm, Merchant, PromptNumber, Firm)
      end, Req);


action(Session, Req, {"match_all_w_good"}, Payload) ->
    ?DEBUG("match_all_w_good with session ~p, payload ~p",
	   [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    StartTime = ?v(<<"start_time">>, Payload, []),
    Firm      = ?v(<<"firm">>, Payload, []),

    batch_responed(
      fun() -> ?w_inventory:match(
		  all_style_number_with_firm, Merchant, StartTime, Firm)
      end, Req);

action(Session, Req, {"new_w_good"}, Payload) ->
    %% ?DEBUG("new_w_good with session ~p, payload ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    {struct, Good} = ?v(<<"good">>, Payload),
    ?DEBUG("new purchaser good with session ~p, good~n~p", [Session, Good]),
    
    Type        = ?v(<<"type">>, Good),
    TypePY      = ?v(<<"type_py">>, Good),
    Brand       = ?v(<<"brand">>, Good),
    %% Firm        = ?v(<<"firm">>, Good),
    StyleNumber = ?v(<<"style_number">>, Good),
    ImageData   = ?v(<<"image">>, Payload, <<>>),

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),
    
    {file, Here} = code:is_loaded(?MODULE),
    ImageDir = filename:join(
		 [filename:dirname(filename:dirname(Here)),
		  "hdoc", "image", ?to_s(Merchant)]),
    
    try 
	{ok, BrandId} = ?attr:brand(new, Merchant, [{<<"name">>, Brand}]), 
	case ImageData of
	    <<>> -> ok;
	    _ ->
		ImageFile = filename:join(
			      [ImageDir,
			       ?to_s(StyleNumber) ++ "-"
			       ++ ?to_s(BrandId) ++ ".png"]),

		case filelib:ensure_dir(ImageFile) of
		    ok -> ok;
		    {error, _} -> ok = file:make_dir(ImageDir)
		end,

		%% ?DEBUG("ImageDir ~p", [ImageDir]), 
		ok = file:write_file(ImageFile, base64:decode(ImageData))
	end, 
	
	{ok, TypeId} =
	    case ?attr:type(new, Merchant, [{<<"name">>, Type},
					    {<<"py">>, TypePY},
					    {<<"auto_barcode">>, AutoBarcode}]) of
		{ok, _TypeId} -> {ok, _TypeId};
		{ok_exist, _TypeId} -> {ok, _TypeId};
		_Error -> _Error 
	    end,
	
	ImagePath = case ImageData of
			<<>> -> [];
			_ -> filename:join(["image", ?to_s(Merchant),
					    ?to_s(StyleNumber)
					    ++ "-" ++ ?to_s(BrandId) ++ ".png"])
		    end,
	case ?w_inventory:purchaser_good(
		new, Merchant,
		[{<<"brand_id">>, BrandId},
		 {<<"type_id">>, TypeId},
		 {<<"path">>, ImagePath},
		 {<<"auto_barcode">>, AutoBarcode}|Good]) of
	    {ok, DBId} -> 
		?utils:respond(
		   200,
		   Req,
		   ?succ(add_purchaser_good, DBId),
		   [{<<"brand">>, BrandId},
		    {<<"type">>, TypeId}] 
		   ++ case DBId of
			  StyleNumber -> [];
			  _ -> [{<<"db">>, DBId}]
		      end
		   ++ case ImagePath of
			  [] -> [];
			  _ -> [{<<"path">>, ?to_b(ImagePath)}] 
		      end); 
	    {error, Error} ->
		?utils:respond(200, Req, Error)
	end 
    catch
	_:{badmatch, {error, DBError}} ->
	    ?DEBUG("failed to new_w_inventory: ~p", [DBError]),
	    ?utils:respond(200, Req, DBError)
	%% EType:EWhat ->
	%%     ?DEBUG("failed to new_w_inventory: EType ~p, EWhat", [EType, EWhat])
	    %% ?utils:respond(200, Req, DBError)
    end;

action(Session, Req, {"update_w_good"}, Payload) -> 
    Merchant = ?session:get(merchant, Session), 
    {struct, Good} = ?v(<<"good">>, Payload),
    ?DEBUG("update purchaser good with session ~p, good~n~p",
	   [Session, Good]),
    
    OStyleNumber = ?v(<<"o_style_number">>, Good),
    OBrandId     = ?v(<<"o_brand">>, Good),
    OImagePath   = ?v(<<"o_path">>, Good),
    OFirm        = ?v(<<"o_firm">>, Good),

    StyleNumber  = ?v(<<"style_number">>, Good),
    Firm         = case ?v(<<"firm_id">>, Good) of
		       undefined -> OFirm;
		       _Firm     -> _Firm
		   end,

    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),

    UpdateOrNewBrand = 
    	fun(undefined) ->
    		case Firm =:= OFirm of
    		    true  -> undefined;
    		    false -> ?attr:brand(
				update,
				Merchant,
				[{<<"bid">>, OBrandId}, {<<"firm">>, Firm}]),
			     undefined
    		end;
    	   (NewBrand) ->
    		{ok, BId} =
    		    ?attr:brand(
    		       new,
    		       Merchant,
    		       [{<<"name">>, NewBrand}, {<<"firm">>, Firm}]),
    		BId
    	end, 
    
    try
	TypeId = case ?v(<<"type">>, Good) of
		     undefined -> undefined;
		     Type ->
			 
			 %% {ok, TId} = ?attr:type(new, Merchant, Type),
			 %% TId, 
			 {ok, TId} =
			     case ?attr:type(new, Merchant, [{<<"name">>, Type},
							     {<<"auto_barcode">>, AutoBarcode}]) of
				 {ok, _TypeId} -> {ok, _TypeId};
				 {ok_exist, _TypeId} -> {ok, _TypeId};
				 _Error -> _Error 
			     end,
			 TId
		 end,

	

	BrandId = UpdateOrNewBrand(?v(<<"brand">>, Good)), 
	OldPath = image(path, Merchant, OStyleNumber, OBrandId),
	
	NewPath= case {StyleNumber, BrandId} of
		     {undefined, undefined}      ->
			 OldPath;
		     {StyleNumber, undefined}    ->
			 image(path, Merchant, StyleNumber, OBrandId);
		     {undefined, BrandId}        ->
			 image(path, Merchant, OStyleNumber, BrandId);
		     {StyleNumber, BrandId}      ->
			 image(path, Merchant, StyleNumber, BrandId)
	    end,
	
	ImagePath =
	    case ?v(<<"image">>, Payload) of 
		undefined ->
		    case NewPath =:= OldPath of
			true  -> undefined; 
			false ->
			    case ?to_s(OImagePath) of
				[] -> undefined;
				_  ->
				    ok = mk_image_dir(NewPath, Merchant), 
				    {ok, _} = file:copy(OldPath, NewPath),
				    ok = file:delete(OldPath),
				    NewPath
			    end 
		    end;
		ImageData -> 
		    case NewPath =:= OldPath of
			true ->
			    ok = file:write_file(
				   OldPath, base64:decode(ImageData));
			false ->
			    ok = file:delete(OldPath),
			    ok = mk_image_dir(NewPath, Merchant), 

			    ?DEBUG("ImageDir ~p", [NewPath]), 
			    ok = file:write_file(
				   NewPath, base64:decode(ImageData))
		    end,
		    filename:join(["image", file:basename(NewPath)])
	    end,

	case ?w_inventory:purchaser_good(
		update, Merchant,
		[{<<"brand_id">>, BrandId},
		 {<<"type_id">>, TypeId},
		 {<<"path">>, ImagePath} |Good]) of
	    {ok, GoodId} -> 
		?utils:respond(
		   200, Req, ?succ(update_purchaser_good, GoodId));
	    {error, Error} ->
		?utils:respond(200, Req, Error)
	end
    catch
	_:{badmatch, {error, {_, _}=FError}} ->
	    ?WARN("failed to update good: Error ~p", [FError]),
	    ?utils:respond(200, Req, FError);
	_:{badmatch, {error, FError}} ->
	    ?WARN("failed to update good: Error ~p", [FError]),
	    ?utils:respond(200, Req, ?err(file_op_error, FError))
    end; 

action(Session, Req, {"filter_w_good"}, Payload) ->
    ?DEBUG("filter_w_good with session ~p~nPayload ~p", [Session, Payload]),
    Merchant  = ?session:get(merchant, Session),
    
    ?pagination:pagination(
      fun(Match, Conditions) ->
	      ?w_inventory:filter(total_goods, Match, Merchant, Conditions)
      end,
      fun(Match, CurrentPage, ItemsPerPage, Conditions) ->
	      ?w_inventory:filter(
		 goods, Match, Merchant, CurrentPage, ItemsPerPage, Conditions)
      end, Req, Payload);


%%
%% promotion 
%%
action(Session, Req, {"new_w_promotion"}, Payload) ->
    ?DEBUG("new_w_promotion with session ~p~nPayload ~p", [Session, Payload]),

    Merchant  = ?session:get(merchant, Session),

    case ?promotion:promotion(new, Merchant, Payload) of 
	{ok, PId} ->
	    ?utils:respond(
	       200, Req, ?succ(new_promotion, PId), {<<"id">>, PId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_promotion"}, Payload) ->
    ?DEBUG("update_w_promotion with session ~p~nPayload ~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    case ?promotion:promotion(update, Merchant, Payload) of 
	{ok, PId} ->
	    ?w_user_profile:update(promotion, Merchant),
	    ?utils:respond(
	       200, Req, ?succ(update_promotion, PId), {<<"id">>, PId});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_color"}, Payload) ->
    ?DEBUG("update_w_color with session ~p, Payload ~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),

    case 
	case ?v(<<"bcode">>, Payload) of
	    undefined ->
		ok;
	    _BCode ->
		{ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
		case ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)) of
		    ?YES ->
			{error, ?err(self_bcode_not_allowed, Merchant)};
		    ?NO ->
			ok
		end
	end
    of
	ok -> 
	    case ?attr:color(w_update, Merchant, Payload) of 
		{ok, ColorId} ->
		    ?w_user_profile:update(color, Merchant),
		    ?utils:respond(200, Req, ?succ(update_color, ColorId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"delete_w_color"}, Payload) ->
    ?DEBUG("delete_w_color with session ~p, Payload ~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session),
    ColorId = ?v(<<"cid">>, Payload, 0),
    case ?attr:color(w_delete, Merchant, ColorId) of 
	{ok, ColorId} ->
	    ?w_user_profile:update(color, Merchant),
	    ?utils:respond(200, Req, ?succ(update_color, ColorId));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"new_w_type"}, Payload) ->
    ?DEBUG("new_w_color with session ~p,  paylaod ~p", [Session, Payload]), 
    Merchant = ?session:get(merchant, Session), 
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)),

    case 
	case ?v(<<"bcode">>, Payload) of
	    undefined ->
		ok;
	    _BCode ->
		case AutoBarcode of
		    ?YES ->
			{error, ?err(self_bcode_not_allowed, Merchant)};
		    ?NO ->
			ok
		end
	end
    of
	ok -> 
	    case ?attr:type(new, Merchant, Payload ++ [{<<"auto_barcode">>, AutoBarcode}]) of
		{ok, TypeId} ->
		    ?utils:respond(200, Req, ?succ(add_color, TypeId), {<<"id">>, TypeId});
		    %% ?w_user_profile:update(type, Merchant);
		{ok_exist, TypeId} ->
		    ?utils:respond(200, Req, ?err(good_type_exist, TypeId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"update_w_type"}, Payload) ->
    ?DEBUG("update_w_type with session ~p, Payload ~p", [Session, Payload]), 
    Merchant  = ?session:get(merchant, Session), 
    case 
	case ?v(<<"bcode">>, Payload) of
	    undefined ->
		ok;
	    _BCode ->
		{ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
		case ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)) of
		    ?YES ->
			{error, ?err(self_bcode_not_allowed, Merchant)};
		    ?NO ->
			ok
		end
	end
    of
	ok -> 
	    case ?attr:type(update, Merchant, Payload) of 
		{ok, TypeId} ->
		    ?w_user_profile:update(type, Merchant),
		    ?utils:respond(200, Req, ?succ(update_color, TypeId));
		{error, Error} ->
		    ?utils:respond(200, Req, Error)
	    end;
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;

action(Session, Req, {"syn_type_pinyin"}, Payload) ->
    ?DEBUG("syn_type_pinyin: session ~p, paylaod ~p", [Session, Payload]),
    Merchant = ?session:get(merchant, Session),
    Types = ?v(<<"type">>, Payload, []),
    case ?attr:syn(type_py, Merchant, Types) of 
	{ok, Merchant} ->
	    ?w_user_profile:update(type, Merchant),
	    ?utils:respond(200, Req, ?succ(syn_retailer_pinyin, Merchant));
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end;


action(Session, Req, {"reset_w_good_barcode"}, Payload) ->
    Merchant = ?session:get(merchant, Session),
    {ok, BaseSetting} = ?wifi_print:detail(base_setting, Merchant, -1),
    AutoBarcode = ?to_i(?v(<<"bcode_auto">>, BaseSetting, ?YES)), 
    StyleNumber = ?v(<<"style_number">>, Payload),
    Brand = ?v(<<"brand">>, Payload),

    case ?w_inventory:purchaser_good(reset_barcode, AutoBarcode, Merchant, StyleNumber, Brand) of
	{ok, Barcode} ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"barcode">>, ?to_b(Barcode)}]}); 
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.
    
%% sidebar(Session) -> 
%%     G1 = 
%% 	case ?right_auth:authen(?new_w_good, Session) of
%% 	    {ok, ?new_w_good} ->
%% 		[{"wgood_new", "新增货品", "glyphicon glyphicon-plus"},
%% 		 {"wgood_detail", "货品详情", "glyphicon glyphicon-book"}];
%% 	    _ ->
%% 		[{"wgood_detail", "货品详情", "glyphicon glyphicon-book"}]
%% 	end, 

%%     L1 = ?menu:sidebar(level_1_menu, G1),


%%     %% setting
%%     Setting = [{{"setting", "基本设置", "glyphicon glyphicon-cog"},
%% 		[{"size", "尺寸", "glyphicon glyphicon-text-size"},
%% 		 {"color", "颜色", "glyphicon glyphicon-font"}]}],

%%     L2 = ?menu:sidebar(level_2_menu, Setting), 

%%     L1 ++ L2.

batch_responed(Fun, Req) ->
    case Fun() of
	{ok, Values} ->
	    ?utils:respond(200, batch_mochijson, Req, Values);
	{error, _Error} ->
	    ?utils:respond(200, batch, Req, [])
    end.

object_responed(Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req, {Value});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

object_responed_with_code(Fun, Req) ->
    case Fun() of
	{ok, Value} ->
	    ?utils:respond(200, object, Req,
			   {[{<<"ecode">>, 0},
			     {<<"data">>, {Value}}
			    ]});
	{error, Error} ->
	    ?utils:respond(200, Req, Error)
    end.

image(path, Merchant, StyleNumber, BrandId) ->
    filename:join([image(dir, Merchant),
		   image(name, StyleNumber, BrandId)]).

image(dir, Merchant) ->
    {file, Here} = code:is_loaded(?MODULE),
    filename:join([filename:dirname(filename:dirname(Here)),
		   "hdoc",
		   "image",
		   ?to_s(Merchant)]).

image(name, StyleNumber, BrandId) ->
    lists:concat([?to_s(StyleNumber), "-", ?to_s(BrandId), ".png"]).


mk_image_dir(Path, Merchant) ->
    case filelib:ensure_dir(Path) of
	ok -> ok;
	{error, _} ->
	    ok = file:make_dir(image(dir, Merchant)),
	    ok
    end.
