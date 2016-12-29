wretailerApp.controller('wretailerTransCtrl', function(
    $scope, $routeParams, $location, diabloFilter, wretailerService,
    localStorageService, diabloUtilsService, filterEmployee, user, base){
    
    var retailer_id = parseInt($routeParams.retailer); 
    // $scope.retailer = diablo_get_object(retailer_id, filterRetailer);
    
    $scope.shops     = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;
    // $scope.float_add = diablo_float_add;
    // $scope.float_sub = diablo_float_sub;
    // $scope.round     = diablo_round; 
    
    $scope.go_back = function(){
	retailerUtils.remove_cache_page(localStorageService, diablo_key_retailer_trans);
	retailerUtils.remove_cache_page(localStorageService, "retailer-trans-stastic");
	$scope.goto_page("#/wretailer_detail")
    };
    
    /* 
     * filter operation
     */ 
    // initial
    diabloFilter.reset_field(); 
    diabloFilter.add_field("shop",     $scope.shops); 
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    /*
     * pagination 
     */
    $scope.colspan = 19;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size(); 
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    var now          = $.now(); 
    var storage = localStorageService.get(diablo_key_retailer_trans);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters      = storage.filter;
	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else {
	$scope.filters = [];
	$scope.qtime_start = function(){
	    // -1 use the default setting
	    var shop = $scope.shopIds[0]; 
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
	$scope.qtime_end = now;
    }
    
    $scope.time  = diabloFilter.default_time($scope.qtime_start, $scope.qtime_end); 
    
    $scope.refresh = function(){
	retailerUtils.remove_cache_page(diablo_key_retailer_trans);
	retailerUtils.remove_cache_page("retailer-trans-stastic");
	$scope.do_search($scope.default_page);
    };

    $scope.do_search = function(page){
	console.log(page);
	$scope.current_page = page;

	// save
	// $scope.save_to_local($scope.filters, $scope.time.start_time);
	retailerUtils.cache_page_condition(
	    localStorageService,
	    diablo_key_retailer_trans,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now);

	if (page !== $scope.default_page){
	    var stastic = localStorageService.get("retailer-trans-stastic");
	    console.log(stastic); 
	    $scope.total_items       = stastic.total_items;
	    $scope.total_amounts     = stastic.total_amounts;
	    $scope.total_spay        = stastic.total_spay;
	    $scope.total_rpay        = stastic.total_rpay;
	    $scope.total_cash        = stastic.total_cash;
	    $scope.total_card        = stastic.total_card;
	    $scope.total_withdraw    = stastic.total_withdraw;
	    $scope.total_ticket      = stastic.total_ticket;
	    $scope.total_balance     = stastic.total_balance;
	}
	
	// recover
	// if (angular.isDefined(back_page)){
	//     var stastic = localStorageService.get("retailer-trans-stastic");
	//     console.log(stastic); 
	//     $scope.total_items       = stastic.total_items;
	//     $scope.total_amounts     = stastic.total_amounts;
	//     $scope.total_spay        = stastic.total_spay;
	//     $scope.total_rpay        = stastic.total_rpay;
	//     $scope.total_cash        = stastic.total_cash;
	//     $scope.total_card        = stastic.total_card;
	//     $scope.total_withdraw    = stastic.total_withdraw;
	//     $scope.total_ticket      = stastic.total_ticket;
	//     $scope.total_balance     = stastic.total_balance;
	    
	//     $location.path("/retailer_trans/" + retailer_id.toString(), false);
	//     $routeParams.page = undefined;
	//     back_page         = undefined;
	//     localStorageService.remove("retailer-trans-stastic");
	// };
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // if (angular.isUndefined(search.shop)
	    // 	|| !search.shop || search.shop.length === 0){
	    // 	search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    // }
	    
	    search.retailer = retailer_id;
	    
	    wretailerService.filter_w_sale_new(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items       = result.total;
		    $scope.total_amounts     = result.t_amount;
		    $scope.total_spay        = result.t_spay;
		    $scope.total_rpay        = result.t_rpay;
		    $scope.total_cash        = result.t_cash;
		    $scope.total_card        = result.t_card;
		    $scope.total_withdraw    = result.t_withdraw;
		    $scope.total_ticket      = result.t_ticket;
		    $scope.total_balance     = result.t_balance;

		    $scope.records = [];
		    $scope.save_stastic();
		}
		angular.forEach(result.data, function(d){
		    d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.has_pay  = d.should_pay;
		    d.left_balance = retailerUtils.to_decimal(d.balance - d.withdraw); 
		})
		
		$scope.records = angular.copy(result.data); 
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
    	// console.log(r); 
    	diablo_goto_page("#/wretailer_trans_rsn/" + retailer_id.toString()
			 + "/" + r.rsn
			 + "/" + $scope.current_page.toString());
    };

    $scope.save_stastic = function(){
	localStorageService.remove("retailer-trans-stastic");
	localStorageService.set(
	    "retailer-trans-stastic",
	    {total_items:       $scope.total_items,
	     total_amounts:     $scope.total_amounts,
	     total_spay:        $scope.total_spay,
	     total_rpay:        $scope.total_rpay,
	     total_cash:        $scope.total_cash,
	     total_card:        $scope.total_card,
	     total_withdraw:    $scope.total_withdraw,
	     total_ticket:      $scope.total_ticket,
	     total_balance:     $scope.total_balance,
	     t:                 now});
    };
})


wretailerApp.controller("wretailerTransRsnDetailCtrl", function(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    wgoodService, wretailerService,
    filterBrand, filterFirm, filterEmployee, filterSizeGroup,
    filterType, filterPromotion, filterScore, filterColor, user, base){
    // console.log($routeParams); 
    // console.log(filterEmployee);
    // console.log(filterColor);
    var retailer_id  = parseInt($routeParams.retailer); 
    // $scope.retailer  = diablo_get_object(retailer_id, filterRetailer);
    $scope.shopIds   = user.shopIds;
    $scope.goto_page = diablo_goto_page;
    var now          = $.now(); 

    $scope.back = function(){
	$scope.goto_page("#/wretailer_trans/" + $routeParams.retailer);
    };

    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    
    // diabloFilter.add_field("style_number", $scope.match_style_number);
    // diabloFilter.add_field("brand",        filterBrand);
    // diabloFilter.add_field("type",         filterType);
    // diabloFilter.add_field("firm",         filterFirm);
    diabloFilter.add_field("shop",         user.sortShops);
    // diabloFilter.add_field("employee",     filterEmployee);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.qtime_start = function(){
	var shop = $scope.shopIds[0];
	return diablo_base_setting(
	    "qtime_start", shop, base, diablo_set_date,
	    diabloFilter.default_start_time(now));
    }();

    $scope.time = diabloFilter.default_time($scope.qtime_start);
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page = 1; 

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // if (angular.isUndefined(search.shop)
	    // 	|| !search.shop || search.shop.length === 0){
	    // 	search.shop = user.shopIds; 
	    // }; 
	    search.retailer = retailer_id;
	    
	    wretailerService.filter_w_sale_rsn_group(
		{mode:0, sort:0},
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.total === 0 ? 0 : result.t_amount;
		    $scope.total_balance = result.total === 0 ? 0 : result.t_balance;
		    $scope.total_obalance = result.total === 0 ? 0 : result.t_obalance;
		    $scope.inventories = []; 
		}
		
		angular.forEach(result.data, function(d){
		    d.brand    = diablo_get_object(d.brand_id, filterBrand);
		    d.firm     = diablo_get_object(d.firm_id, filterFirm);
		    d.shop     = diablo_get_object(d.shop_id, user.sortShops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.type     = diablo_get_object(d.type_id, filterType);

		    d.oseason   = diablo_get_object(d.season, diablo_season2objects);
		    d.promotion = diablo_get_object(d.pid, filterPromotion);
		    d.score     = diablo_get_object(d.sid, filterScore);
		    d.drate     = diablo_discount(d.rprice, d.tag_price);
		    d.calc      = retailerUtils.to_decimal(d.rprice * d.total); 
		});
		
		$scope.inventories = angular.copy(result.data);
		diablo_order_page(page, $scope.items_perpage, $scope.inventories);

		$scope.current_page = page;
	    })
	})
    }; 

    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    } 

    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === size){
		return amounts[i].count;
	    }
	}
	return undefined;
    };

    var sort_amounts_by_color = function(colors, amounts){
	console.log(amounts);
	return colors.map(function(c){
	    var row = {total:0, cid:c.cid, cname:c.cname};
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (a.cid === c.cid){
		    row.total += a.count;
		}
	    };
	    return row;
	})
    }
    
    $scope.rsn_detail = function(inv){
	console.log(inv);
	if (angular.isDefined(inv.amounts)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.order_sizes)){

	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:        inv.colors,
		 sizes:         inv.order_sizes,
		 amounts:       inv.amounts,
		 total:         inv.total, 
		 path:          inv.path,
		 colspan:       inv.sizes.length + 1,
		 get_amount:    get_amount,
		 row_total:     function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		});
	    return;
	}
	
	wretailerService.w_sale_rsn_detail({
	    rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id
	}).then(function(result){
	    console.log(result);

	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = wretailerService.sort_inventory(result.data, order_sizes, filterColor);
	    inv.total       = sort.total; 
	    inv.colors      = sort.color;
	    inv.sizes       = sort.size;
	    inv.amounts     = sort.sort; 
	    // console.log(inv.amounts);
	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    console.log(color_sorts);
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 colspan:    inv.sizes.length + 1,
		 get_amount: get_amount,
		 row_total:  function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		});
	});
    }; 
});
