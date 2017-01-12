'use strict'


function purchaserInventoryTransferCtrlProvide (
    $scope, $q, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, diabloNormalFilter, 
    purchaserService, user, filterShop, filterFirm, filterEmployee,
    filterSizeGroup, filterColor, base){
    // console.log(user); 
    // console.log(filterShop);
    $scope.shops = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    console.log($scope.shops);
    $scope.to_shops          = [];
    
    // $scope.f_add             = diablo_float_add;
    // $scope.f_sub             = diablo_float_sub;
    
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    $scope.firms             = filterFirm;
    // $scope.employees         = filterEmployee;
    $scope.extra_pay_types   = purchaserService.extra_pay_types;
    $scope.timeout_auto_save = undefined;
    $scope.base_settings     = {};
    $scope.focus             = {style_number:true, transfer: false};

    $scope.go_back = function(){
	diablo_goto_page("#inventory/inventory_transfer_detail");
    };

    $scope.stock_right = {
	show_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	)
    };

    $scope.calc_row = stockUtils.calc_row;

    var now = $.now();

    // init
    $scope.has_saved       = false; 
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true}); 
    
    $scope.select = {
	total: 0,
	shop: $scope.shops.length !==0 ? $scope.shops[0]: undefined,
	// extra_pay_type: $scope.extra_pay_types[0]
    };

    $scope.get_transfer_shop = function(){
	$scope.to_shops = [];
	for (var i=0, l=filterShop.length; i<l; i++){
	    if ($scope.select.shop.id !== filterShop[i].id){
		$scope.to_shops.push(filterShop[i]);
	    }
	};

	if ($scope.to_shops.length !==0){
	    $scope.select.to_shop = $scope.to_shops[0];
	};
    };

    $scope.disable_refresh = function(){
	return !$scope.has_saved; 
    }; 

    $scope.change_shop = function(){
	$scope.get_valid_employee();
	$scope.get_transfer_shop(); 
	if ($scope.base_settings.q_prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory();
	}
    };

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	
	$scope.select.total      = 0;
	$scope.select.comment    = undefined;

	$scope.has_saved = false;

    };

    $scope.auto_focus = function(attr){
	if (!$scope.focus[attr]){
	    $scope.focus[attr] = true;
	}
	for (var o in $scope.focus){
	    if (o !== attr) $scope.focus[o] = false;
	} 
    };

    $scope.get_valid_employee = function(){
	var loginEmployee =  stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = loginEmployee.login;
	$scope.employees = loginEmployee.filter; 
    };

    $scope.get_valid_employee();
    $scope.get_transfer_shop(); 
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return now;
    };

    $scope.base_settings.q_prompt = stockUtils.typeahead($scope.select.shop.id, base);
    $scope.base_settings.plimit = stockUtils.prompt_limit($scope.select.shop.id, base);
    
    $scope.qtime_start = function(shopId){
	return stockUtils.start_time(shopId, base, now, dateFilter); 
    };

    // console.log($scope.setting);

    $scope.get_all_prompt_inventory = function(){
	console.log($scope.select.shop);
	diabloNormalFilter.match_all_w_inventory(
	    {start_time:$scope.qtime_start($scope.select.shop.id),
	     shop:$scope.select.shop.id} 
	).$promise.then(function(invs){
	    // console.log(invs);
	    $scope.all_prompt_inventory = invs.map(function(v){
		var p = stockUtils.prompt_name(v.style_number, v.brand, v.type);
		return angular.extend(v, {name:p.name, prompt:p.prompt}); 
	    });

	    // console.log($scope.all_prompt_inventory);
	});
    };
    
    if ($scope.base_settings.q_prompt === diablo_frontend){
	// console.log($scope.select);
	$scope.get_all_prompt_inventory()
    };

    $scope.match_prompt_inventory = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id); 
    }; 

    $scope.on_select_inventory = function(item, model, label){
	console.log(item);

	if (diablo_invalid_firm === item.firm_id){
	    diabloUtilsService.response_with_callback(
		false, "库存转移", "转移失败：" + purchaserService.error[2089],
		$scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
	    return;
	}
	
	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "库存转移", "转移失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}
	
	// add at first allways 
	var add = $scope.inventories[0];

	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.firm_id      = item.firm_id;
	add.s_group      = item.s_group;
	add.free         = item.free;
	add.year         = item.year;
	add.sex          = item.sex;
	add.season       = item.season;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.ediscount    = item.ediscount;
	add.discount     = item.discount;
	add.path         = item.path;
	add.alarm_day    = item.alarm_day;

	console.log(add);

	$scope.auto_focus("transfer");
	$scope.add_inventory(add);
	
	return;
    }; 
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved){
	    return true;
	}; 
	
	if ($scope.inventories.length === 1){
	    return true;
	};

	return false;
    };
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	var get_transfer_amount = function(amounts){
	    var reject_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].reject_count)
		    && amounts[i].reject_count){
		    amounts[i].reject_count
			= parseInt(amounts[i].reject_count);
		    reject_amounts.push({
			cid:amounts[i].cid,
			size:amounts[i].size,
			count:parseInt(amounts[i].reject_count)
		    }); 
		} 
	    }

	    return reject_amounts;
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var added = []; 
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    added.push({
		order_id    : add.order_id,
		style_number: add.style_number,
		brand       : add.brand_id,
		type        : add.type_id,
		sex         : add.sex,
		season      : add.season,
		firm        : add.firm_id,
		
		org_price   : add.org_price,
		tag_price   : add.tag_price,
		ediscount   : add.ediscount,
		discount    : add.discount,
		
		s_group     : add.s_group,
		free        : add.free,
		year        : add.year,
		
		amounts     : get_transfer_amount(add.amounts),
		total       : seti(add.reject),
		// discount    : add.discount,
		path        : add.path,
		alarm_day   : add.alarm_day
	    })
	}; 
	
	var base = {
	    shop:          $scope.select.shop.id,
	    tshop:         $scope.select.to_shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       sets($scope.select.comment), 
	    total:         stockUtils.to_integer($scope.select.total),
	    cost:          stockUtils.to_float($scope.select.cost)
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true
	purchaserService.transfer_purchaser_inventory({
	    inventory: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	diabloUtilsService.response(
	    	    true, "库存转移", "库存转移成功！！单号：" + state.rsn)
	    	return;
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false,
		    "库存转移",
	    	    "库存转移失败："
			+ purchaserService.error[state.ecode]
			+ stockUtils.extra_error(state),
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	})
    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.cost = 0;
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    // console.log(one);
	    $scope.select.cost += stockUtils.to_float(one.org_price);
	    $scope.select.total += stockUtils.to_integer(one.reject); 
	} 
    };
    
    /*
     * add
     */ 
    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    $scope.valid_free_size_reject = function(inv){
    	if (angular.isDefined(inv.amounts)
    	    && angular.isDefined(inv.amounts[0].reject_count) 
    	    // && !$scope.setting.reject_negative
	    // && parseInt(inv.amounts[0].reject_count) > inv.total
	   ){
	    if (parseInt(inv.amounts[0].reject_count) > inv.total){
		return false;
	    }
    	}
    	return true;
    };
    
    var valid_all = function(amounts){
	var unchanged = 0;
	// var invalid = true;
	for(var i=0, l=amounts.length; i<l; i++){
	    var amount = amounts[i];
	    if (angular.isUndefined(amount.reject_count)
		|| !amount.reject_count){
		unchanged++;
	    }
	    else {
		// if ( !$scope.setting.reject_negative
		//      && diablo_set_integer(amount.reject_count)>amount.count)
		if (diablo_set_integer(amount.reject_count) > amount.count) {
		    // unchanged++
		    return false;
		}
	    }
	}
	
	return unchanged == l ? false : true;
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new = false;
	inv.reject = inv.amounts[0].reject_count;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true}); 
	$scope.re_calculate();
	$scope.auto_focus("style_number");
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number,
	     brand:inv.brand_id,
	     shop:$scope.select.shop.id,
	     qtype: diablo_badrepo}
	).then(function(invs){
	    console.log(invs);
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    var add_callback = function(params){
		console.log(params.amounts);
		
		var reject_total = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.reject_count) && a.reject_count){
			reject_total += parseInt(a.reject_count);
		    }
		})

		return {amounts: params.amounts,
			reject:  reject_total,
			org_price: params.org_price};
	    };

	    var after_add = function(){
		inv.$edit = true;
		inv.$new = false;
		// order
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});

		$scope.re_calculate();
		$scope.auto_focus("style_number");
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.org_price;
		after_add();
	    };

	    if (inv.free === 0){
		inv.free_color_size = true;
	    } else{
		inv.free_color_size = false;
		var payload = {sizes:        inv.sizes,
			       colors:       inv.colors,
			       org_price:    inv.org_price,
			       amounts:      inv.amounts,
			       get_amount:   get_amount,
			       // valid_reject: valid_reject,
			       valid:        valid_all};
		
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", 'normal', callback, $scope, payload); 
	    }
	}) 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	// console.log($scope.inventories)

	// var deleteIndex = -1;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		// $scope.inventories.splice(i, 1)
		// deleteIndex = i;
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	$scope.re_calculate();
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       org_price:    inv.org_price,
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_org_price  = inv.org_price;
	    return;
	}
	
	var callback = function(params){
	    inv.amounts   = params.amounts;
	    inv.org_price = params.org_price;
	    inv.reject    = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.reject_count) && a.reject_count){
		    inv.reject += parseInt(a.reject_count);
		}
	    });

	    calculate();
	};

	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       org_price:    inv.org_price,
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       // valid_reject: valid_reject,
		       valid:        valid_all}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html", undefined, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save); 
	inv.free_update = false;
	inv.reject      = inv.amounts[0].reject_count;
	$scope.re_calculate();
    }

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.org_price  = inv.o_org_price;
	inv.amounts[0].reject_count = inv.reject;
    } 
    
    $scope.reset_inventory = function(inv){
	// inv.$reset = true;
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    }


    //var timeout_auto_ = undefined;
    $scope.auto_save_free = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	var reject = stockUtils.to_integer(inv.amounts[0].reject_count);
	if (angular.isUndefined(inv.style_number) || 0 === reject || reject > inv.total){
	    return;
	}
	
	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    };

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv);
	    }
	}, 1000); 
    };
    
};


function purchaserInventoryTransferFromDetailCtrlProvide (
    $scope, dateFilter, localStorageService, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, 
    user, filterShop, filterEmployee, base){
    // console.log($routeParams);

    $scope.from_shops = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds, user.repoIds);
    
    $scope.goto_page = diablo_goto_page;

    $scope.go_transfer = function(){
	$scope.goto_page('#/inventory/inventory_transfer');
    };

    $scope.go_transfer_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/transfer_from');
    };

    $scope.stock_right = {
	// show_orgprice: rightAuthen.authen(
	//     user.type,
	//     rightAuthen.rainbow_action()['show_orgprice'],
	//     user.right
	// )
	master: rightAuthen.authen_master(user.type)
    }; 

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("fshop",    $scope.from_shops);
    // diabloFilter.add_field("tshop",     user.sortShops);
    // diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("rsn", []); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    // $scope.qtime_start = function(shopId){
    // 	return diablo_base_setting(
    // 	    "qtime_start",
    // 	    shopId, base,
    // 	    diablo_set_date,
    // 	    diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time(now - diablo_day_millisecond * 7, now);

    var storage = localStorageService.get(diablo_key_inventory_transfer);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters = storage.filter;
    };

    console.log($scope.filters);
    
    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page = 1;
    // $scope.current_page = $scope.default_page;

    var toshopIds = filterShop.map(function(s){
	return s.id;
    });
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    console.log(search);
	    if ((angular.isUndefined(search.fshop)
		 || !search.fshop || search.fshop.length === 0)){
		search.fshop = $scope.from_shops.length
		    === 0 ? undefined : $scope.shopIds;
	    };

	    localStorageService.set(
		diablo_key_inventory_transfer,
		{filter:$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page:page, t:now});
	    
	    purchaserService.filter_transfer_w_inventory(
		$scope.match,
		search, page,
		$scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.fshop = diablo_get_object(d.fshop_id, $scope.from_shops);
			d.tshop = diablo_get_object(d.tshop_id, filterShop);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    })
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		})

	    $scope.current_page = page;
	    
	})
    };
    
    // default the first page
    // $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	// console.log(r);
	diablo_goto_page(
	    "#/inventory/inventory_rsn_detail/transfer_from/" + r.rsn);
    };

    // check
    var dialog = diabloUtilsService; 
    $scope.cancel_transfer = function(r){
	var callback = function(){
	    purchaserService.cancel_w_inventory_transfer(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"移仓操作删除",
			"移仓单删除成功，移仓单["
			    + r.fshop.name + "-" + r.rsn + "] 删除成功！！",
			$scope, function(){$scope.do_search($scope.current_page)})
		} else{
	    	    dialog.response(
	    		false,
			"移仓删除失败",
	    		"移仓单删除失败："
			    + purchaserService.error[state.ecode]);
		}
	    })
	};

	dialog.request(
	    "移仓删除确认",
	    "移仓删除后无法恢复，确认要删除该称仓！！",
	    callback, undefined, $scope);
    };
};


function purchaserInventoryTransferToDetailCtrlProvide (
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, 
    user, filterShop, filterEmployee, base){

    $scope.to_shops  = user.sortBadRepoes.concat(user.sortShops, user.sortRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds, user.repoIds);
    // console.log($scope.to_shops);
    $scope.goto_page = diablo_goto_page;

    $scope.go_transfer = function(){
	$scope.goto_page('#/inventory/inventory_transfer');
    };

    $scope.go_transfer_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/transfer_to');
    };

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    // diabloFilter.add_field("rsn", []);
    // diabloFilter.add_field("fshop",     user.sortShops);
    diabloFilter.add_field("tshop",     $scope.to_shops);
    // diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    // $scope.qtime_start = function(shopId){
    // 	return diablo_base_setting(
    // 	    "qtime_start",
    // 	    shopId, base,
    // 	    diablo_set_date,
    // 	    diabloFilter.default_start_time(now));
    // }();
    // console.log($scope.qtime_start);
    
    // $scope.time   = diabloFilter.default_time($scope.qtime_start);
    $scope.time   = diabloFilter.default_time(now - diablo_day_millisecond * 7, now);
    // $scope.time   = diabloFilter.default_time();

    // console.log($scope.filter);
    
    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page = 1;
    // $scope.current_page = $scope.default_page;

    // var toshopIds = filterShop.map(function(s){
    // 	return s.id;
    // });
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // if ((angular.isUndefined(search.fshopo)
	    // 	 || !search.fshop || search.fshop.length === 0)){
	    // 	search.fshop = user.sortShops.length
	    // 	    === 0 ? undefined : user.shopIds;
	    // };
	    
	    if ((angular.isUndefined(search.tshop)
	    	 || !search.tshop || search.tshop.length === 0)){
	    	search.tshop = $scope.to_shops.length
	    	    === 0 ? undefined : $scope.shopIds;
	    }

	    purchaserService.filter_transfer_w_inventory(
		$scope.match,
		search, page,
		$scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.fshop = diablo_get_object(
			    d.fshop_id, filterShop);
			d.tshop = diablo_get_object(
			    d.tshop_id, $scope.to_shops);
			d.employee = diablo_get_object(
			    d.employee_id, filterEmployee);
		    })
		    $scope.records = result.data;
		    diablo_order_page(
			page, $scope.items_perpage, $scope.records);
		})

	    $scope.current_page = page;
	    
	})
    };
    
    // default the first page
    // $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	// console.log(r);
	diablo_goto_page(
	    "#/inventory/inventory_rsn_detail/transfer_to/" + r.rsn);
    };

    // check
    var dialog = diabloUtilsService;
    $scope.check_transfer = function(r){
	var callback = function(){
	    var check_date = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
	    purchaserService.check_w_inventory_transfer(
		{rsn:r.rsn, tshop:r.tshop_id, datetime:check_date}
	    ).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"移仓调入确认",
			"确认成功，请检查店铺 ["
			    + r.tshop.name + "] 库存！！",
			$scope, function(){
			    r.state=1; r.check_date=check_date;})
	    	    return;
		} else{
	    	    dialog.response(
	    		false,
			"移仓调入确认",
	    		"确认失败："
			    + purchaserService.error[state.ecode]);
		}
	    })
	};

	dialog.request(
	    "移仓调入确认",
	    "移仓只能确认一次，确认后货品自动增加，请在货品到达到后确认！！",
	    callback, undefined, undefined);
    };

    $scope.cancel_transfer = function(r){
	dialog.response(false, "移仓取消", "系统暂不支持此操作！！", undefined);
    };
};

define (["purchaserApp"], function(app){
    app.controller("purchaserInventoryTransferCtrl", purchaserInventoryTransferCtrlProvide);
    app.controller("purchaserInventoryTransferFromDetailCtrl", purchaserInventoryTransferFromDetailCtrlProvide);
    app.controller("purchaserInventoryTransferToDetailCtrl", purchaserInventoryTransferToDetailCtrlProvide);
});
