'use strict'

function firmTransCtrlProvide(
    $scope, $routeParams, $location, localStorageService,
    diabloFilter, diabloPattern, firmService, diabloUtilsService,
    filterBrand, filterFirm, filterEmployee, filterRegion, user, base){

    // console.log(filterFirm);
    // console.log($routeParams);
    var firm_id = parseInt($routeParams.firm);
    $scope.firm = diablo_get_object(firm_id, filterFirm);
    // console.log($scope.firm); 
    $scope.shops        = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds      = user.shopIds.concat(user.badrepoIds); 
    $scope.goto_page    = diablo_goto_page; 
    $scope.f_add        = diablo_float_add;
    $scope.f_sub        = diablo_float_sub;
    // $scope.round        = diablo_round;
    $scope.default_page = 1;

    /*
     * hidden
     */
    $scope.hidden = {base:true, balance:true, comment:true};

    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };
    
    $scope.toggle_balance = function(){
	$scope.hidden.balance = !$scope.hidden.balance;
    };
    
    $scope.toggle_comment = function(){
	$scope.hidden.comment = !$scope.hidden.comment;
    };

    $scope.right = {master: rightAuthen.authen_master(user.type)};
    
    
    $scope.css = diablo_stock_css;
    
    $scope.go_back = function(){
	localStorageService.remove(diablo_key_firm_trans);
	$scope.goto_page("#/firm_detail")
    }; 
    
    /*
     * local sate
     */
    var now             = $.now(); 
    $scope.save_to_local = function(filter, time){
	var s = localStorageService.get(diablo_key_firm_trans);

	var format_time = undefined;
	if (angular.isDefined(time)){
	    format_time = {start_time:diablo_get_time(time.start_time),
			   end_time:  diablo_get_time(time.end_time)}
	};
	
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_firm_trans, {
		    filter:angular.isDefined(filter) ? filter:s.filter,
		    start_time:angular.isDefined(time)
			? diablo_get_time(time) :s.time,
		    // stastic:angular.isDefined(stastic) ? stastic:s.stastic,
		    page:$scope.current_page,
		    t:now}
	    )
	} else {
	    localStorageService.set(
		diablo_key_firm_trans, {
		    filter:   filter,
		    start_time: angular.isDefined(time)
			? diablo_get_time(time) : undefined,
		    // stastic:  stastic,
		    page:     $scope.current_page,
		    t:        now})
	}
    };

    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };

    /* 
     * filter operation
     */ 
    // initial
    // $scope.filters = [];
    diabloFilter.reset_field();

    // diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("region",   filterRegion);
    diabloFilter.add_field("employee", filterEmployee);
    // diabloFilter.add_field("check_state", purchaserService.check_state);
    // diabloFilter.add_field("purchaser_type", purchaserService.purchaser_type);
    diabloFilter.add_field("org_price", []);
    // if ($scope.shop_right.check_w_stock) {
    // 	diabloFilter.add_field("org_price", []);
    // }

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var storage = localStorageService.get(diablo_key_firm_trans);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters      = storage.filter;
	$scope.qtime_start  = storage.start_time; 
    } else {
	$scope.filters = [];
	$scope.qtime_start = function(){
	    // -1 use the default setting
	    var shop = -1
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    }

    $scope.time = diabloFilter.default_time($scope.qtime_start); 

    
    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    
    var back_page = diablo_set_integer($routeParams.page);
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };
    
    $scope.refresh = function(){
	$scope.do_search($scope.default_page);
    };

    var add_search_condition = function(search) {
	if (stockUtils.to_integer(search.region) === 0){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	} else {
	    if (angular.isArray(search.shop) && search.shop.length !== 0){
		delete search.region;
	    } else {
		search.shop = $scope.shops.filter(function(s){
		    return s.region === search.region;
		}).map(function(s) { return s.id});
	    }
	}

	search.firm = firm_id; 
	return search;
    };
    
    $scope.do_search = function(page){
	// console.log(page);
	$scope.current_page = page;
	
	// save
	$scope.save_to_local($scope.filters, $scope.time.start_time);

	if (angular.isDefined(back_page)){
	    var stastic = localStorageService.get("firm-trans-stastic");
	    console.log(stastic);
	    $scope.total_items      = stastic.total_items
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;

	    // recover
	    $location.path("/firm_trans/" + firm_id.toString(), false);
	    $routeParams.page = undefined;
	    back_page = undefined;
	    localStorageService.remove("firm-trans-stastic");
	}; 
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // if (stockUtils.to_integer(search.region) === 0){
	    // 	if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
	    // 	    search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    // 	}
	    // } else {
	    // 	if (angular.isArray(search.shop) && search.shop.length !== 0){
	    // 	    delete search.region;
	    // 	} else {
	    // 	    search.shop = $scope.shops.filter(function(s){
	    // 		return s.region === search.region;
	    // 	    }).map(function(s) { return s.id});
	    // 	}
	    // }
	    
	    // search.firm = firm_id;
	    search = add_search_condition(search); 
	    firmService.filter_w_inventory_new(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		    // console.log(result);
		    if (page === 1 && angular.isUndefined(back_page)){
			$scope.total_items      = result.total
			$scope.total_amounts    = result.t_amount;
			$scope.total_spay       = result.t_spay;
			$scope.total_hpay       = result.t_hpay;
			$scope.total_cash       = result.t_cash;
			$scope.total_card       = result.t_card;
			$scope.total_wire       = result.t_wire;
			$scope.total_verificate = result.t_verificate; 
		    }
		    angular.forEach(result.data, function(d){
			d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.debt = diablo_rdight(
			    d.balance + d.should_pay + d.e_pay - d.has_pay - d.verificate, 2);
		    });
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records); 
		})
	})
    }; 
    
    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }
    
    // default the first page
    $scope.do_search($scope.current_page);

    $scope.trans_rsn_detail = function(r){
    	console.log(r); 
	// save stastic
	localStorageService.set(
	  "firm-trans-stastic"  ,
	    	{total_items       :$scope.total_items,
	    	 total_amounts     :$scope.total_amounts,
	    	 total_spay        :$scope.total_spay,
	    	 total_hpay        :$scope.total_hpay,
	    	 total_cash        :$scope.total_cash,
	    	 total_card        :$scope.total_card,
	    	 total_wire        :$scope.total_wire,
	    	 total_verificate  :$scope.total_verificate,
		 t:                 now});
	
    	diablo_goto_page("#/firm_trans_rsn/" + firm_id.toString()
			 + "/" + r.rsn
			 + "/" + $scope.current_page.toString());
    };

    var dialog = diabloUtilsService;
    $scope.check_trans = function(r){
	console.log(r);
	firmService.check_w_inventory_new(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "厂商对帐单审核", "厂商对帐单审核成功！！单号：" + state.rsn,
		    $scope, function(){r.state = 1})
	    	return;
	    } else{
	    	dialog.response(
	    	    false, "厂商对帐单审核",
	    	    "厂商对帐单审核失败：" + firmService.error[state.ecode]);
	    }
	})
    };

    $scope.uncheck_trans = function(r){
	console.log(r);
	firmService.uncheck_w_inventory_new(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "厂商对帐单反审", "厂商对帐单反审核成功！！单号：" + state.rsn,
		    $scope, function(){r.state = 0})
	    	return;
	    } else{
	    	dialog.response(
	    	    false, "厂商对帐单反审",
	    	    "厂商对帐单反审核失败：" + firmService.error[state.ecode]);
	    }
	})
    };

    $scope.comment_rsn_detail = function(r){
	var callback = function(params){
	    console.log(params);
	    firmService.comment_w_inventory_new(r.rsn, params.comment).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    // dialog.response_with_callback(
		    // 	true, "厂商对帐单审核", "厂商对帐单审核成功！！单号：" + state.rsn,
		    // 	$scope, function(){r.state = 1})
		    r.comment = params.comment;
		} else{
	    	    dialog.response(
	    		false, "厂商对帐备注",
	    		"修改厂商对帐备注失败：" + firmService.error[state.ecode]);
		}
	    });
	}; 
	
	dialog.edit_with_modal(
	    'comment-stock.html', 'lg', callback, undefined,
	    {comment:r.comment, comment_pattern:diabloPattern.comment});
    };

    $scope.modify_balance = function(r){
	console.log(r);
	var callback = function(params){
	    console.log(params);
	    firmService.modify_w_inventory_new_balance(r.rsn, params.balance).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    // r.balance = params.balance;
		    $scope.do_search($scope.current_page);
		} else{
	    	    dialog.response(
	    		false, "厂商帐户欠款修改",
	    		"修改厂商帐户欠款失败：" + firmService.error[state.ecode]);
		}
	    });
	};

	dialog.edit_with_modal(
	    'modify-balance.html', undefined, callback, undefined,
	    {balance:r.balance, pattern:diabloPattern.decimal_2});
    };

    $scope.export_firm_trans = function() {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search = add_search_condition(search);
	    // [transe, transe_note, stock, shift, shift_note]
	    firmService.export_firm_trans(0, search, {mode: 10}).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"文件导出成功",
			"创建文件成功，请点击确认下载！！",
			undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败：" + firmService.error[result.ecode]);
		} 
	    }); 
	});	
    };
}

function firmTransRsnDetailCtrlProvide(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    firmService,
    filterBrand, filterFirm, filterEmployee, filterSizeGroup,
    filterColor, user, base){
    // console.log($routeParams); 
    // console.log(filterEmployee);
    $scope.shopIds   = user.shopIds; 
    /*
     * hidden
     */
    $scope.hidden      = {base:true, over:true};
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base
    };

    $scope.toggle_over = function(){
	$scope.hidden.over = !$scope.hidden.over;
    }
    
    var firm_id = parseInt($routeParams.firm);
    $scope.firm = diablo_get_object(firm_id, filterFirm);

    var now = $.now();
    
    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, user.shopIds);
    };

    $scope.match_prompt_type = function(viewValue){
	return diabloFilter.match_prompt_type(viewValue, diablo_is_ascii_string(viewValue)); 
    };

    $scope.goto_page = diablo_goto_page;

    // console.log($routeParams);
    $scope.go_back = function(){
	console.log($routeParams);
	
	$scope.goto_page("#/firm_trans/" + firm_id.toString()
			 + "/" + $routeParams.ppage.toString());
    };

    $scope.calc_row   = stockUtils.calc_row;
    $scope.calc_drate = stockUtils.calc_drate_of_org_price;

    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",        filterBrand);
    diabloFilter.add_field("type",         $scope.match_prompt_type);
    diabloFilter.add_field("shop",         user.sortShops);
    // diabloFilter.add_field("employee",     filterEmployee);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.qtime_start = function(){
	// -1 use the default setting
	var shop = -1
	if ($scope.shopIds.length === 1){
	    shop = $scope.shopIds[0];
	};
	return diablo_base_setting(
	    "qtime_start", shop, base, diablo_set_date,
	    diabloFilter.default_start_time(now));
    }();
    
    $scope.time = diabloFilter.default_time($scope.qtime_start);
    console.log($scope.time);
    
    /*
     * pagination 
     */
    $scope.colspan = 14;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search.firm = firm_id;
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
	    	search.shop = user.shopIds.length
		    === 0 ? undefined : $scope.shopIds;; 
	    };
	    
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    }
	    
	    firmService.filter_w_inventory_new_rsn_group(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total;
			$scope.total_amounts = result.t_amount;
			$scope.total_balance = result.t_balance;
			$scope.total_over = result.t_over;

			$scope.total_amounts -= $scope.total_over;
		    }
		    
		    $scope.inventories = angular.copy(result.data);
		    angular.forEach($scope.inventories, function(inv){
			inv.shop     = diablo_get_object(inv.shop_id, user.sortShops);
			inv.employee = diablo_get_object(inv.employee_id, filterEmployee);
			inv.firm     = diablo_get_object(inv.firm_id, filterFirm);
			inv.brand    = diablo_get_object(inv.brand_id, filterBrand);
			// inv.itype    = diablo_get_object(inv.type_id, filterType);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		    $scope.current_page = page;
		})
	}) 
    }

    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }

    var get_amount = diablo_get_amount;
    
    $scope.rsn_detail = function(inv){
	console.log(inv);
	if (angular.isDefined(inv.amounts)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.sizes)){
	    
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 get_amount: get_amount});
	    return;
	}

	firmService.w_inventory_new_rsn_detail(
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result){
	    console.log(result);
	    
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    //console.log(order_sizes);
	    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
	    console.log(sort);
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 get_amount: get_amount});
	}); 
    }; 
};


define(["firmApp"], function(app){
    app.controller("firmTransCtrl", firmTransCtrlProvide);
    app.controller("firmTransRsnDetailCtrl", firmTransRsnDetailCtrlProvide);
});
