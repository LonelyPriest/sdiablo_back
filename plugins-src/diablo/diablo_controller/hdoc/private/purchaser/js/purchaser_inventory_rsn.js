purchaserApp.controller("purchaserInventoryFixRsnDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, wgoodService,
    user, filterBrand, filterFirm, filterSizeGroup, filterColor, base){
    
    // var permitShops =  user.shopIds;
    // $scope.shops = user.sortAvailabeShops;
    $scope.shops   = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;
    
    
    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    }; 
    
    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    // diabloFilter.add_field("shop", user.sortShops);
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("firm", filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(){
	var shop = -1
	if ($scope.shopIds.length === 1){
	    shop = $scope.shopIds[0];
	};
	
	return diablo_base_setting(
	    "qtime_start", shop, base, diablo_set_date, diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time();

    // console.log($routeParams);
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
	    	// search.shop = user.shopIds;
		search.shop = user.shopIds.length
		    === 0 ? undefined : user.shopIds;
	    };

	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    }
	    console.log(search);
	    
	    purchaserService.filter_w_inventory_fix_rsn_group(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    
		    angular.forEach(result.data, function(d){
			d.shop = diablo_get_object(d.shop_id, user.sortShops);
			d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.brand = diablo_get_object(d.brand_id, filterBrand);
		    });
		    
		    $scope.inventories = result.data; 
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		}) 
	}) 
    }
    
    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }


    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].exit  += parseInt(inv.exist);
		amounts[i].fixed += parseInt(inv.fixed);
		return true;
	    }
	}
	return false;
    };
    
    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === size){
		return amounts[i];
	    }
	}
	return undefined;
    }; 
    
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
		 // total:      inv.metric,
		 path:       inv.path,
		 get_amount: get_amount});
	    return;
	}
	
	purchaserService.w_invnetory_fix_rsn_detail(
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result){
	    console.log(result);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(result.data, order_sizes, filterColor);
	    console.log(sort);
	    
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    var amounts = [];
	    angular.forEach(result.data, function(i){
		if (!in_amount(amounts, i)){
		    amounts.push({cid:i.color_id, size:i.size, exist:i.exist, fixed:i.fixed})
		}; 
	    });
	    
	    inv.amounts = amounts;
	    diabloUtilsService.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 path:       inv.path,
		 get_amount: get_amount});
	}); 
    }
    
});

purchaserApp.controller("purchaserInventoryNewRsnDetailCtrl", function(
    $scope, $routeParams, $location, diabloUtilsService, diabloFilter,
    wgoodService, purchaserService, localStorageService,
    user, filterBrand, filterFirm, filterType,
    filterEmployee, filterSizeGroup, filterColor, base){

    // console.log(user.right);

    // var permitShops      = user.shopIds;
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;

    $scope.calc_row   = stockUtils.calc_row;
    $scope.calc_drate = stockUtils.calc_drate_of_org_price;

    /*
     * hidden
     */
    $scope.hidden      = {base:true};
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base
    };

    $scope.calc_colspan = function(){
	var column = 15;
	if ($scope.hidden.base){
	    column -= 2;
	}
	if (!$scope.stock_right.show_orgprice){
	    column -=2;
	}
	return column;
    };

    /*
     * authen
     */
    $scope.stock_right = {
	show_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	)
    };

    // console.log($scope.stock_right);

    var dialog       = diabloUtilsService;
    
    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    }; 
    
    // initial
    // $scope.filters = [];    
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type",  filterType);
    diabloFilter.add_field("sex",   diablo_sex2object); 
    diabloFilter.add_field("firm",  filterFirm);
    diabloFilter.add_field("year",  diablo_full_year);
    diabloFilter.add_field("season",  diablo_season2objects); 
    diabloFilter.add_field("rsn",   []); 
    diabloFilter.add_field("shop", user.sortShops);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt); 
    // console.log($scope.time);
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    
    // default the first page
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    var now = $.now(); 
    var storage = localStorageService.get(diablo_key_invnetory_trans_detail);
    console.log(storage);

    var use_storage  = $routeParams.rsn && angular.isUndefined($routeParams.from) ? false : true;
    if (use_storage && angular.isDefined(storage) && storage !== null){
    	$scope.filters      = storage.filter;
    	$scope.qtime_start  = storage.start_time;
	// $scope.back_from_history = storage.backFromHistory;
	// if (storage.backFromHistory) $scope.current_page = storage.page;
    } else{
	$scope.filters = []; 
	$scope.qtime_start = function(){
	    var shop = -1
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}(); 
    };

    if (angular.isDefined($routeParams.from)){
	$location.path("/inventory_rsn_detail", false);
	$routeParams.rsn = undefined;
	$routeParams.ppage = undefined;
    };

    $scope.time = diabloFilter.default_time($scope.qtime_start);

    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    search.shop = user.shopIds.length
		=== 0 ? undefined : $scope.shopIds; 
	};

	if (angular.isUndefined(search.rsn) && angular.isUndefined($routeParams.from)){
	    search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	};

	// return search;
    };

    var set_storage = function(backFromHistory){
	if (use_storage) {
	    localStorageService.set(
		diablo_key_invnetory_trans_detail,
		{filter    :$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page      :$scope.current_page,
		 t         :now,
		 backFromHistory:backFromHistory
		});
	}
    };

    $scope.do_search = function(page){
	// save condition of query
	set_storage(false); 
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);

	    purchaserService.filter_w_inventory_new_rsn_group(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total;
			$scope.total_amounts = result.t_amount;
			// $location.path("/inventory_rsn_detail", false);
		    }
		    
		    $scope.inventories = angular.copy(result.data);
		    angular.forEach($scope.inventories, function(inv){
			inv.shop     = diablo_get_object(inv.shop_id, $scope.shops);
			inv.employee = diablo_get_object(inv.employee_id, filterEmployee);
			inv.firm     = diablo_get_object(inv.firm_id, filterFirm);
			inv.brand    = diablo_get_object(inv.brand_id, filterBrand);
			inv.itype    = diablo_get_object(inv.type_id, filterType);
			inv.sex      = diablo_get_object(inv.sex_id, diablo_sex2object);
			inv.dseason =  diablo_get_object(inv.season, diablo_season2objects);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		})
	}) 
    }

    $scope.total_items = 0;
    if (angular.isDefined($routeParams.rsn) && $routeParams.rsn
	|| angular.isDefined($routeParams.from)){
	$scope.do_search($scope.default_page); 
    }

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };

    // if ($scope.back_from_history) {
    // 	$scope.do_search($scope.current_page);
    // 	set_storage(false);
    // };


    var get_amount = purchaserService.get_inventory_from_sort;

    var dialog = diabloUtilsService;
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

	purchaserService.w_inventory_new_rsn_detail(
	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result){
	    console.log(result);
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    //console.log(order_sizes);
	    var sort = purchaserService.sort_inventory(result.data, order_sizes, filterColor);
	    console.log(sort);
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    dialog.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 get_amount: get_amount});
	}); 
    };


    // $scope.edit_rsn_detail = function(inv){
    // 	console.log(inv);

    // 	purchaserService.w_inventory_new_rsn_detail(
    // 	    {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
    // 	).then(function(result){
    // 	    console.log(result);
    // 	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
    // 	    var sort = purchaserService.sort_inventory(result.data, order_sizes);
    // 	    console.log(sort);
    // 	    inv.sizes   = sort.size;
    // 	    inv.colors  = sort.color;
    // 	    inv.amounts = sort.sort;

    // 	    dialog.edit_with_modal(
    // 		"edit-rsn-detail.html", undefined, undefined, $scope,
    // 		{colors:     inv.colors,
    // 		 sizes:      inv.sizes,
    // 		 amounts:    inv.amounts,
    // 		 total:      inv.total,
    // 		 path:       inv.path,
    // 		 get_amount: get_amount});
    // 	}); 
    // };

    $scope.update_rsn_detail = function(inv){
	if (inv.type===0){
	    diablo_goto_page("#/update_new_detail/" + inv.rsn
			     + "/" + $scope.current_page.toString()
			     + "/" + diablo_from_update_stock.toString()); 
	} else if (inv.type === 1){
	    diablo_goto_page("#/update_new_detail_reject/" + inv.rsn
			     + "/" + $scope.current_page.toString()
			     + "/" + diablo_from_update_stock.toString()); 
	}
    };

    $scope.go_back = function(){
	var ppage = diablo_set_integer($routeParams.ppage);
	if(angular.isDefined(ppage) && angular.isUndefined($routeParams.from)){
	    localStorageService.remove(diablo_key_invnetory_trans_detail);
	    $scope.goto_page("#/inventory_new_detail/" + ppage.toString()) 
	} else{
	    $scope.goto_page("#/inventory_new_detail") 
	}
    };

    $scope.stock_history = function(inv){
	// set_storage(true);
	$scope.goto_page("#/inventory_new_history"
			 + "/" + inv.style_number
			 + "/" + inv.brand_id.toString());
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.csv_export(purchaserService.export_type.trans_note, search)
		.then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			dialog.response(
			    false, "文件导出失败", "创建文件失败："
				+ purchaserService.error[result.ecode]);
		    } 
		}); 
	}) 
    };
});

purchaserApp.controller("stockHistoryCtrl", function(
    $scope, $routeParams, dateFilter, purchaserService,
    user, filterBrand, filterFirm, base){
    $scope.stock_history = [];

    var shops = user.sortShops;
    var shopIds = user.shopIds;
    var style_number = $routeParams.snumber;
    var brand_id = parseInt($routeParams.brand);
    var q_start_time = stockUtils.start_time(-1, base, $.now(), dateFilter); 

    purchaserService.list_w_inventory_new_detail({
	style_number:style_number,
	brand:brand_id,
	shop: shopIds,
	start_time: q_start_time
    }).then(function(result){
	// console.log(result);
	if (result.ecode === 0){
	    $scope.stock_history = angular.copy(result.data); 
	    var order = 1;
	    angular.forEach($scope.stock_history, function(h){
		h.order_id = order;
		h.brand = diablo_get_object(h.brand_id, filterBrand);
		h.firm  = diablo_get_object(h.firm_id, filterFirm);
		h.shop  = diablo_get_object(h.shop_id, shops);
		order++;
	    });

	    console.log($scope.stock_history);
	}
    });

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_rsn_detail");
    };
    
});


purchaserApp.controller("purchaserInventoryTransferFromRsnDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, wgoodService,
    user, filterShop, filterBrand, filterType, filterFirm,
    filterSizeGroup, filterColor, base){
    
    // var permitShops =  user.shopIds;
    // $scope.shops = user.sortAvailabeShops;
    // $scope.shops   = user.sortShops;
    // $scope.shopIds = user.shopIds;
    $scope.shops  = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds, user.repoIds);
    
    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory/inventory_transfer_from_detail");
    };
    
    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type", filterType);
    diabloFilter.add_field("fshop", $scope.shops);
    // diabloFilter.add_field("tshop", $scope.shops);
    diabloFilter.add_field("firm", filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(){
	var shop = -1
	if ($scope.shopIds.length === 1){
	        shop = $scope.shopIds[0];
	    };
	
	return diablo_base_setting(
	        "qtime_start",
	        shop,
	        base,
	        diablo_set_date,
	        diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	        if ((angular.isUndefined(search.fshop)
		      || !search.fshop || search.fshop.length === 0)){
		    search.fshop = $scope.shops.length
		        === 0 ? undefined : $scope.shopIds;
		        } 

	        if (angular.isUndefined(search.rsn)){
		    search.rsn = $routeParams.rsn ? $routeParams.rsn : undefined; 
		        }
	        console.log(search);
	        
	        purchaserService.filter_transfer_rsn_w_inventory(
		    $scope.match, search, page, $scope.items_perpage
		        ).then(function(result){
			    console.log(result);
			    if (page === 1){
				    $scope.total_items = result.total
				}
			    
			    angular.forEach(result.data, function(d){
				    d.fshop = diablo_get_object(d.fshop_id, $scope.shops);
				    d.tshop = diablo_get_object(d.tshop_id, filterShop);
				    
				    d.firm = diablo_get_object(d.firm_id, filterFirm);
				    d.brand = diablo_get_object(d.brand_id, filterBrand);
				    d.type = diablo_get_object(d.type_id, filterType);
				});
			    
			    $scope.inventories = result.data; 
			    diablo_order_page(
				    page, $scope.items_perpage, $scope.inventories);
			        })
	    }) 
    };
    
    // default the first page
    // $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }


    // var in_amount = function(amounts, inv){
    // for(var i=0, l=amounts.length; i<l; i++){
    //     if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
    // amounts[i].exit  += parseInt(inv.exist);
    // amounts[i].fixed += parseInt(inv.fixed);
    // return true;
    //     }
    // }
    // return false;
    // };
    
    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	        if (amounts[i].cid === cid && amounts[i].size === size){
		    return amounts[i];
		        }
	    }
	return undefined;
    }; 
    
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
		      path:       inv.path,
		      get_amount: get_amount});
	        return;
	    }
	
	purchaserService.w_invnetory_transfer_rsn_detail(
	        {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	    ).then(function(result){
		    console.log(result);
		    
		    var order_sizes = wgoodService.format_size_group(
			inv.s_group, filterSizeGroup);
		    var sort = purchaserService.sort_inventory(
			result.data, order_sizes, filterColor);
		    console.log(sort);
		    
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		    
		    // inv.amounts = amounts;
		    diabloUtilsService.edit_with_modal(
			"rsn-detail.html", undefined, undefined, $scope,
			{colors:     inv.colors,
			  sizes:      inv.sizes,
			  amounts:    inv.amounts,
			  path:       inv.path,
			  get_amount: get_amount});
		}); 
    }
    
});

purchaserApp.controller("purchaserInventoryTransferToRsnDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, wgoodService,
    user, filterShop, filterBrand, filterType, filterFirm,
    filterSizeGroup, filterColor, base){
    
    // var permitShops =  user.shopIds;
    // $scope.shops = user.sortAvailabeShops;
    // $scope.shops   = user.sortShops;
    $scope.shops  = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds, user.repoIds);
    
    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory/inventory_transfer_to_detail");
    };
    
    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type", filterType);
    // diabloFilter.add_field("fshop", $scope.shops);
    diabloFilter.add_field("tshop", $scope.shops);
    diabloFilter.add_field("firm", filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(){
	var shop = -1
	if ($scope.shopIds.length === 1){
	        shop = $scope.shopIds[0];
	    };
	
	return diablo_base_setting(
	        "qtime_start",
	        shop,
	        base,
	        diablo_set_date,
	        diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	        if ((angular.isUndefined(search.tshop)
		      || !search.tshop || search.tshop.length === 0)){
		    search.tshop = $scope.shops.length
		        === 0 ? undefined : $scope.shopIds; ;
		        } 

	        if (angular.isUndefined(search.rsn)){
		    search.rsn = $routeParams.rsn ? $routeParams.rsn : undefined; 
		        }
	        console.log(search);
	        
	        purchaserService.filter_transfer_rsn_w_inventory(
		    $scope.match, search, page, $scope.items_perpage
		        ).then(function(result){
			    console.log(result);
			    if (page === 1){
				    $scope.total_items = result.total
				}
			    
			    angular.forEach(result.data, function(d){
				    d.fshop = diablo_get_object(
					d.fshop_id, filterShop);
				    d.tshop = diablo_get_object(
					d.tshop_id, $scope.shops);
				    
				    d.firm = diablo_get_object(d.firm_id, filterFirm);
				    d.brand = diablo_get_object(d.brand_id, filterBrand);
				    d.type = diablo_get_object(d.type_id, filterType);
				});
			    
			    $scope.inventories = result.data; 
			    diablo_order_page(
				    page, $scope.items_perpage, $scope.inventories);
			        })
	    }) 
    };
    
    // default the first page
    // $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    }


    // var in_amount = function(amounts, inv){
    // for(var i=0, l=amounts.length; i<l; i++){
    //     if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
    // amounts[i].exit  += parseInt(inv.exist);
    // amounts[i].fixed += parseInt(inv.fixed);
    // return true;
    //     }
    // }
    // return false;
    // };
    
    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	        if (amounts[i].cid === cid && amounts[i].size === size){
		    return amounts[i];
		        }
	    }
	return undefined;
    }; 
    
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
		      path:       inv.path,
		      get_amount: get_amount});
	        return;
	    }
	
	purchaserService.w_invnetory_transfer_rsn_detail(
	        {rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
	    ).then(function(result){
		    console.log(result);
		    
		    var order_sizes = wgoodService.format_size_group(
			inv.s_group, filterSizeGroup);
		    var sort = purchaserService.sort_inventory(
			result.data, order_sizes, filterColor);
		    console.log(sort);
		    
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		    
		    // inv.amounts = amounts;
		    diabloUtilsService.edit_with_modal(
			"rsn-detail.html", undefined, undefined, $scope,
			{colors:     inv.colors,
			  sizes:      inv.sizes,
			  amounts:    inv.amounts,
			  path:       inv.path,
			  get_amount: get_amount});
		}); 
    }
    
});
