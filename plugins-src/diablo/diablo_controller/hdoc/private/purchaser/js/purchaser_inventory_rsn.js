'use strict'

function purchaserInventoryFixRsnDetailCtrlProvide(
    $scope, $routeParams, $location, dateFilter,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, 
    user, filterBrand, filterSizeGroup, filterColor, base){
    
    // var permitShops =  user.shopIds;
    // $scope.shops = user.sortAvailabeShops;
    $scope.shops   = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;
    
    
    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
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
    // diabloFilter.add_field("firm", filterFirm);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    // $scope.qtime_start = function(){
    // 	var shop = -1
    // 	if ($scope.shopIds.length === 1){
    // 	    shop = $scope.shopIds[0];
    // 	};
	
    // 	return diablo_base_setting(
    // 	    "qtime_start", shop, base, diablo_set_date, diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start);
    $scope.time   = diabloFilter.default_time(now, now);
    
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
			// d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.brand = diablo_get_object(d.brand_id, filterBrand);
			d.color = diablo_get_object(d.color_id, filterColor);
			d.metric = d.shop_total - d.db_total;
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
	    
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
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
    
};

function purchaserInventoryNewRsnDetailCtrlProvide (
    $scope, $routeParams, $location, dateFilter, diabloUtilsService, diabloFilter,
    purchaserService, localStorageService,
    user, filterBrand, filterFirm, filterType,
    filterEmployee, filterSizeGroup, filterColor, filterTemplate, base){

    // console.log(user.right);

    // var permitShops      = user.shopIds;
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.goto_page = diablo_goto_page;

    $scope.calc_row   = stockUtils.calc_row;
    $scope.calc_drate = stockUtils.calc_drate_of_org_price;
    $scope.css        = diablo_stock_css;

    $scope.setting = {
	// self_barcode   :stockUtils.barcode_self(diablo_default_shop, base), 
	use_barcode: stockUtils.use_barcode(diablo_default_shop, base),
	auto_barcode :stockUtils.auto_barcode(diablo_default_shop, base),
	printer_barcode: stockUtils.printer_barcode(user.loginShop, base),
	dual_barcode: stockUtils.dual_barcode_print(user.loginShop, base)
	// barcode_width: stockUtils.barcode_width(diablo_default_shop, base),
	// barcode_height: stockUtils.barcode_height(diablo_default_shop, base),
	// barcode_firm: stockUtils.barcode_with_firm(diablo_default_shop, base)
    };

    $scope.template = filterTemplate.length !== 0 ? filterTemplate[0] : undefined;
    $scope.printU = new stockPrintU($scope.template, $scope.setting.auto_barcode, $scope.setting.dual_barcode);
    $scope.printU.setPrinter($scope.setting.printer_barcode);
    /*
     * hidden
     */
    $scope.hidden      = {base:true};
    $scope.toggle_base = function(){$scope.hidden.base = !$scope.hidden.base};

    $scope.calc_colspan = function(){
	var column = 16;
	if ($scope.hidden.base) column -= 2;
	if (!$scope.stock_right.show_orgprice) column -=2;
	return column;
    };

    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight(); 
    // $scope.stock_right = {
    // 	show_orgprice: rightAuthen.authen(
    // 	    user.type, rightAuthen.rainbow_action()['show_orgprice'], user.right 
    // 	),

    // 	print_w_stock: stockUtils.authen_stock(user.type, user.right, 'print_w_stock_new')
    // };

    // console.log($scope.stock_right);

    var dialog       = diabloUtilsService;
    
    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    }; 
    
    // initial
    // $scope.filters = [];    
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type",  filterType);
    diabloFilter.add_field("firm",  filterFirm);
    diabloFilter.add_field("year",  diablo_full_year);
    diabloFilter.add_field("season",  diablo_season2objects);
    diabloFilter.add_field("shop", user.sortShops); 
    diabloFilter.add_field("purchaser_type", purchaserService.purchaser_type);
    diabloFilter.add_field("sex",   diablo_sex2object); 
    diabloFilter.add_field("rsn",   function(viewValue) {return undefined}); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt); 
    // console.log($scope.time);
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.total_items = 0;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    
    // default the first page
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    var recover_from_storage = function(storage) {
	$scope.filters      = angular.isArray(storage.filter) ? storage.filter : [];
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = angular.isDefined(storage.page) ? storage.page : $scope.default_page;
    }

    var reset_query_condition = function(){
	$scope.filters = [];
	// $scope.qtime_start = stockUtils.start_time(-1, base, now, dateFilter);
	$scope.qtime_start = now;
	$scope.qtime_end = now;
    };

    var now = $.now(); 
    var is_linked = $routeParams.rsn ? true : false;
    var storage_key = is_linked ? diablo_key_inventory_note_link : diablo_key_inventory_note;
    var stastic_key = is_linked ? "stock-note-link-stastic" : "stock-note-stastic";
    
    var storage = localStorageService.get(storage_key);
    // console.log(storage);
    if (storage !== null) {
	recover_from_storage(storage);
	if (!is_linked) {
	    localStorageService.remove(diablo_key_inventory_note_link);
	    localStorageService.remove("stock-note-link-stastic");
	};
    } else {
	reset_query_condition();
    } 
    
    // if (!is_linked) {
    // 	var note_storage = localStorageService.get(diablo_key_inventory_note);
    // 	console.log(note_storage); 
    // 	if (note_storage != null){
    // 	    recover_from_storage(note_storage);
    // 	    localStorageService.remove(diablo_key_inventory_note_link);
    // 	} else {
    // 	    reset_query_condition();
    // 	}
    // } else{
    // 	var link_storage  = localStorageService.get(diablo_key_inventory_note_link);
    // 	console.log(link_storage); 
    // 	if (link_storage != null){
    // 	    recover_from_storage(link_storage); 
    // 	} else {
    // 	    reset_query_condition()
    // 	}
    // }

    // var storage_key = undefined;
    // var stastic_key = undefined;
    // if (!is_linked) {
    // 	storage_key = diablo_key_inventory_note;
    // 	stastic_key = "stock-note-stastic";
    // };
    // else {
    // 	storage_key = diablo_key_inventory_note_link
    // 	stastic_key = "stock-note-link-stastic";
    // };

    $scope.time = diabloFilter.default_time($scope.qtime_start, $scope.qtime_end);
    // console.log($scope.time);

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

    $scope.cache_stastic = function(key){
	localStorageService.set(
	    key, {total_items:$scope.total_items,
		  total_amounts:$scope.total_amounts,
		  total_balance:$scope.total_balance,
		  total_over: $scope.total_over,
		  t:now})};

    $scope.do_search = function(page){
	stockUtils.cache_page_condition(
	    localStorageService,
	    storage_key,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now);
	
	if (page !== $scope.default_page) {
	    var stastic = localStorageService.get(stastic_key);
	    // console.log(stastic);
	    $scope.total_items       = stastic.total_items;
	    $scope.total_amounts     = stastic.total_amounts;
	    $scope.total_balance     = stastic.total_balance;
	    $scope.total_over        = stastic.total_over;
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    purchaserService.filter_w_inventory_new_rsn_group(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total;
			$scope.total_amounts = result.t_amount;
			$scope.total_over = result.t_over;
			$scope.total_balance = result.t_balance;
			$scope.cache_stastic(stastic_key);
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
			inv.dseason  = diablo_get_object(inv.season, diablo_season2objects);
			inv.expire_date = diablo_none;
			
			if (diablo_invalid_firm !== stockUtils.invalid_firm(inv.firm)) {
			    if (angular.isDefined(inv.firm.expire) &&  inv.firm.expire !== diablo_invalid_firm) {
				inv.expire_date = stockUtils.date_add(inv.entry_date, inv.firm.expire);
			    }
			}
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		})
	}) 
    };

    if ($scope.current_page !== $scope.default_page || is_linked)
	$scope.do_search($scope.current_page); 

    $scope.page_changed = function(page){
	$scope.current_page = page;
	$scope.do_search($scope.current_page);
    };

    var get_amount = purchaserService.get_inventory_from_sort; 
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
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    //console.log(order_sizes);
	    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
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
	if (is_linked) {
	    localStorageService.remove(diablo_key_inventory_note_link);
	    localStorageService.remove("stock-note-link-stastic")
	    $scope.goto_page("#/inventory_new_detail/" + $routeParams.ppage);
	} else {
	    $scope.goto_page("#/inventory_new_detail");
	}
	// if(angular.isDefined(ppage) && angular.isUndefined($routeParams.from)){
	//     localStorageService.remove(diablo_key_invnetory_trans_detail);
	//     $scope.goto_page("#/inventory_new_detail/" + ppage.toString()) 
	// } else{
	//     $scope.goto_page("#/inventory_new_detail") 
	// }
    };

    $scope.stock_history = function(inv){
	// set_storage(true);
	var extra = is_linked ? "/" + $routeParams.rsn : "";
	// console.log(extra);
	$scope.goto_page("#/inventory_new_history"
			 + "/" + inv.style_number
			 + "/" + inv.brand_id.toString()
			 + extra);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.csv_export(
		purchaserService.export_type.trans_note, search
	    ).then(function(result){
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

    $scope.print_note = function() {
	var callback = function() {
	    diabloFilter.do_filter($scope.filters, $scope.time, function(search){
		add_search_condition(search);
		diablo_goto_page("#/print_inventory_new_note/" + angular.toJson(search)); 
	    }); 
	}
	
	dialog.request(
	    "采购单打印", "采购单打印需要打印机支持A4纸张，确认要打印吗？",
	    callback, undefined, undefined);
    };


    if ($scope.setting.use_barcode && needCLodop()) loadCLodop();
    
    var dialog_barcode_title = "库存条码打印";
    var dialog_barcode_title_failed = "库存条码打印失败：";
    
    // $scope.p_barcode = function(inv) {
    // 	console.log(inv);

    // 	if ($scope.template.firm && diablo_invalid_firm === inv.firm_id ) {
    // 	    dialog.response(
    // 		false,
    // 		dialog_barcode_title,
    // 		dialog_barcode_title_failed + purchaserService.error[2086]);
    // 	    return;
    // 	} 

    // 	var print_barcode = function(barcode) {
    // 	    var firm = inv.firm_id === diablo_invalid_firm ? undefined: inv.firm.name;
    // 	    // $scope.printU.setCodeFirm(inv.firm.id);
    // 	    var barcodes = []; 
    // 	    if (0 === inv.free) {
    // 		for (var i=0; i<inv.amount; i++) {
    // 		    barcodes.push(barcode); 
    // 		}

    // 		$scope.printU.free_prepare(
    // 		    inv.shop.name,
    // 		    inv,
    // 		    inv.brand.name,
    // 		    barcodes,
    // 		    firm,
    // 		    inv.firm_id);
    // 	    }
    // 	    else {
    // 		var print = function(amounts) {
    // 		    barcodes = []; 
    // 		    angular.forEach(inv.amounts, function(a) {
    // 			var color = diablo_find_color(a.cid, filterColor);
    // 			// console.log(color);
    // 			for (var i=0; i<a.count; i++) {
    // 			    var o = stockUtils.gen_barcode_content2(barcode, color, a.size);
    // 			    if (angular.isDefined(o) && angular.isObject(o)) {
    // 				barcodes.push(o); 
    // 			    } 
    // 			}
    // 		    }); 
    // 		    console.log(barcodes);
    // 		    $scope.printU.prepare(
    // 			inv.shop.name,
    // 			inv,
    // 			inv.brand.name,
    // 			barcodes,
    // 			firm,
    // 			inv.firm_id); 
    // 		};

    // 		if (angular.isDefined(inv.amounts)
    // 		    && angular.isDefined(inv.colors)
    // 		    && angular.isDefined(inv.sizes)){
    // 		    print(inv.amounts);
    // 		}
    // 		else {
    // 		    purchaserService.w_inventory_new_rsn_detail(
    // 			{rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id}
    // 		    ).then(function(result){
    // 			console.log(result);
    // 			var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
    // 			var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
    // 			inv.sizes   = sort.size;
    // 			inv.colors  = sort.color;
    // 			inv.amounts = sort.sort; 
    // 			print(inv.amounts);
    // 		    }); 
    // 		}
    // 	    }
    // 	}
	
    // 	// gen
    // 	purchaserService.gen_barcode(
    // 	    inv.style_number, inv.brand_id, inv.shop_id
    // 	).then(function(result) {
    // 	    console.log(result);
    // 	    if (result.ecode === 0) {
    // 		print_barcode(result.barcode);
    // 	    } else {
    // 		dialog.response(
    // 		    false, "条码生成", "条码生成失败："
    // 			+ purchaserService.error[result.ecode]);
    // 	    }
    // 	}); 
    // };
    
};

function stockHistoryCtrlProvide(
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
	if ($routeParams.rsn)
	    diablo_goto_page("#/inventory_rsn_detail/" + $routeParams.rsn);
	else
	    diablo_goto_page("#/inventory_rsn_detail");
    };
    
};


function purchaserInventoryFlowCtrlProvide(
    $scope, $routeParams, dateFilter, purchaserService,
    user, filterBrand, filterFirm, base){

    var shops = user.sortShops;
    var shopIds = user.shopIds;
    var style_number = $routeParams.snumber;
    var brand_id = parseInt($routeParams.brand);

    $scope.news = [];
    $scope.sales = [];
    $scope.transfers = [];
    $scope.stock = {new_total: 0, sale_total: 0}; 
    // var firm_id  = undefined;
    // var q_start_time = stockUtils.start_time(-1, base, $.now(), dateFilter);

    $scope.stock_right = {
	orgprice: stockUtils.authen_rainbow(user.type, user.right, 'show_orgprice')
    };


    var sort_by_date = function(stocks) {
	return stocks.sort(function(s1, s2){
	    return diablo_set_date(s1.entry_date) - diablo_set_date(s2.entry_date);
	})
    };

    var order_with = function(stocks) {
	var order = 1;
	var total = 0;
	angular.forEach(stocks, function(s){
	    s.order_id = order; 
	    if (order === 1){
		s.style_number = style_number;
		s.brand = diablo_get_object(brand_id, filterBrand);
		s.firm  = diablo_get_object(s.firm_id, filterFirm);
	    }
	    total += s.total;
	    order++;
	});

	return total;
    }
    
    purchaserService.list_w_inventory_flow({
	style_number:style_number,
	brand:brand_id,
	shop: shopIds
	// start_time: q_start_time
    }).then(function(result){
	console.log(result);
	
	$scope.news = result.new.map(function(s){
	    return {
		// style_number:s.style_number,
		// brand_id: s.brand_id,
		firm_id:  s.firm_id,
		
		tag_price: s.tag_price,
		discount: s.discount,
		total: s.amount,
		org_price: s.org_price,
		ediscount: s.ediscount,
		type: s.type,
		shop: diablo_get_object(s.shop_id, shops),
		entry_date:  s.entry_date}
	});

	$scope.sales = result.sell.map(function(s){
	    return {
		// style_number:s.style_number,
		// brand_id: s.brand_id,
		firm_id:  s.firm_id,
		
		tag_price: s.tag_price,
		discount: s.fdiscount,
		rprice: s.rprice,
		rdiscount: s.rdiscount,
		
		total: s.total,
		org_price: s.org_price,
		ediscount: s.ediscount,
		type: s.sell_type,
		shop: diablo_get_object(s.shop_id, shops),
		entry_date: s.entry_date}
	});
	
	$scope.transfers = result.transfer.map(function(s){
	    return {
		// style_number:s.style_number,
		// brand_id: s.brand_id,
		firm_id:  s.firm_id, 
		total: s.amount, 
		tshop: diablo_get_object(s.tshop_id, shops),
		fshop: diablo_get_object(s.fshop_id, shops),
		state: s.state,
		entry_date: s.entry_date}
	});
	
	// $scope.stocks = news.concat(sells, transfers);

	sort_by_date($scope.news);
	sort_by_date($scope.sales);
	sort_by_date($scope.transfers);
	// $scope.news.sort(function(s1, s2){
	//     return diablo_set_date(s1.entry_date) - diablo_set_date(s2.entry_date); 
	// });

	$scope.stock.new_total = order_with($scope.news);
	$scope.stock.sale_total = order_with($scope.sales);
	
	order_with($scope.transfers);
	
	// var order = 1; 
	// angular.forEach($scope.news, function(h){
	//     h.order_id = order; 
	//     if (order === 1){
	// 	h.style_number = style_number;
	// 	h.brand = diablo_get_object(brand_id, filterBrand);
	// 	h.firm  = diablo_get_object(h.firm_id, filterFirm);
	//     }
	    
	//     order++;
	// });

	// console.log($scope.stocks); 
	
	// if (result.ecode === 0){
	//     $scope.stock_history = angular.copy(result.data); 
	//     var order = 1;
	//     angular.forEach($scope.stock_history, function(h){
	// 	h.order_id = order;
	// 	h.brand = diablo_get_object(h.brand_id, filterBrand);
	// 	h.firm  = diablo_get_object(h.firm_id, filterFirm);
	// 	h.shop  = diablo_get_object(h.shop_id, shops);
	// 	order++;
	//     });

	//     console.log($scope.stock_history);
	//}
    });

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_detail");
	// if ($routeParams.rsn)
	//     diablo_goto_page("#/inventory_rsn_detail/" + $routeParams.rsn);
	// else
	//     diablo_goto_page("#/inventory_rsn_detail");
    };
    
};


function purchaserInventoryTransferFromRsnDetailCtrlProvide(
    $scope, $routeParams, $location, dateFilter, localStorageService,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, 
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
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory/inventory_transfer_from_detail");
    };

    $scope.stock_right = {
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, "show_orgprice")
	// master: rightAuthen.authen_master(user.type)
    };

    $scope.total_items = 0;
    
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
    // $scope.qtime_start = function(){
    // 	var shop = -1
    // 	if ($scope.shopIds.length === 1){
    // 	        shop = $scope.shopIds[0];
    // 	    };
	
    // 	return diablo_base_setting(
    // 	        "qtime_start",
    // 	        shop,
    // 	        base,
    // 	        diablo_set_date,
    // 	        diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start);
    $scope.time   = diabloFilter.default_time(now - diablo_day_millisecond * 7, now);
    var storage = localStorageService.get(diablo_key_inventory_transfer_note);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters = storage.filter;
	if (angular.isDefined(storage.start_time)) {
	    $scope.time.start_time = storage.start_time; 
	}
    };
    
    // $scope.time   = diabloFilter.default_time();
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = 10;
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    var add_search_condition = function(search){
	if ((angular.isUndefined(search.fshop)
	     || !search.fshop || search.fshop.length === 0)){
	    search.fshop = $scope.shops.length === 0 ? undefined : $scope.shopIds;
	} 

	if (angular.isUndefined(search.rsn)){
	    search.rsn = $routeParams.rsn ? $routeParams.rsn : undefined;
	}

	return search;
    };
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // if ((angular.isUndefined(search.fshop)
	    // 	 || !search.fshop || search.fshop.length === 0)){
	    // 	search.fshop = $scope.shops.length === 0 ? undefined : $scope.shopIds;
	    // } 

	    // if (angular.isUndefined(search.rsn)){
	    // 	search.rsn = $routeParams.rsn ? $routeParams.rsn : undefined;
	    // }
	    search = add_search_condition(search);
	    console.log(search);

	    localStorageService.set(
		diablo_key_inventory_transfer_note,
		{filter:$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page:page, t:now});
	    
	    purchaserService.filter_transfer_rsn_w_inventory(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.t_amount;
		    $scope.total_cost = result.t_cost;
		}
		
		angular.forEach(result.data, function(d){
		    d.fshop = diablo_get_object(d.fshop_id, $scope.shops);
		    d.tshop = diablo_get_object(d.tshop_id, filterShop);
		    
		    d.firm = diablo_get_object(d.firm_id, filterFirm);
		    d.brand = diablo_get_object(d.brand_id, filterBrand);
		    d.type = diablo_get_object(d.type_id, filterType);

		    d.calc = stockUtils.to_decimal(d.org_price * d.amount);
		});
		
		$scope.inventories = result.data; 
		diablo_order_page(page, $scope.items_perpage, $scope.inventories);
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
		    
		    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
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
    };

    $scope.export_to = function() {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search = add_search_condition(search);
	    purchaserService.csv_export(
		purchaserService.export_type.shift_note, search 
	    ).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    diabloUtilsService.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    diabloUtilsService.response(
			false, "文件导出失败", "创建文件失败："
			    + purchaserService.error[result.ecode]);
		} 
	    }); 
	})
    };
    
};

function purchaserInventoryTransferToRsnDetailCtrlProvide(
    $scope, $routeParams, $location, dateFilter, localStorageService,
    diabloPattern, diabloUtilsService, diabloFilter,
    purchaserService, 
    user, filterShop, filterBrand, filterType, filterFirm,
    filterSizeGroup, filterColor, base){
    
    // var permitShops =  user.shopIds;
    // $scope.shops = user.sortAvailabeShops;
    // $scope.shops   = user.sortShops;
    $scope.shops  = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds, user.repoIds);
    
    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory/inventory_transfer_to_detail");
    };

    $scope.stock_right = {
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, "show_orgprice")
    };

    $scope.total_items = 0;
    
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
    // $scope.qtime_start = function(){
    // 	var shop = -1
    // 	if ($scope.shopIds.length === 1){
    // 	        shop = $scope.shopIds[0];
    // 	    };
	
    // 	return diablo_base_setting(
    // 	        "qtime_start",
    // 	        shop,
    // 	        base,
    // 	        diablo_set_date,
    // 	        diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start);
    $scope.time   = diabloFilter.default_time(now - diablo_day_millisecond * 7, now);
    var storage = localStorageService.get(diablo_key_inventory_transfer_to_note);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters = storage.filter;
	if (angular.isDefined(storage.start_time)) {
	    $scope.time.start_time = storage.start_time; 
	}
    };
    
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

	    localStorageService.set(
		diablo_key_inventory_transfer_to_note,
		{filter:$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page:page, t:now});
	        
	    purchaserService.filter_transfer_rsn_w_inventory(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.t_amount;
		    $scope.total_cost = result.t_cost;
		}
		
		angular.forEach(result.data, function(d){
		    d.fshop = diablo_get_object(
			d.fshop_id, filterShop);
		    d.tshop = diablo_get_object(
			d.tshop_id, $scope.shops);
		    
		    d.firm = diablo_get_object(d.firm_id, filterFirm);
		    d.brand = diablo_get_object(d.brand_id, filterBrand);
		    d.type = diablo_get_object(d.type_id, filterType);

		    d.calc = stockUtils.to_decimal(d.org_price * d.amount);
		});
		
		$scope.inventories = result.data; 
		diablo_order_page(page, $scope.items_perpage, $scope.inventories);
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
		    
		    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
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
};

define (["purchaserApp"], function(app){
    app.controller("purchaserInventoryFixRsnDetailCtrl", purchaserInventoryFixRsnDetailCtrlProvide);
    app.controller("purchaserInventoryNewRsnDetailCtrl", purchaserInventoryNewRsnDetailCtrlProvide);
    app.controller("stockHistoryCtrl", stockHistoryCtrlProvide);
    app.controller("purchaserInventoryFlowCtrl", purchaserInventoryFlowCtrlProvide);
    app.controller("purchaserInventoryTransferFromRsnDetailCtrl", purchaserInventoryTransferFromRsnDetailCtrlProvide);
    app.controller("purchaserInventoryTransferToRsnDetailCtrl", purchaserInventoryTransferToRsnDetailCtrlProvide);
});
