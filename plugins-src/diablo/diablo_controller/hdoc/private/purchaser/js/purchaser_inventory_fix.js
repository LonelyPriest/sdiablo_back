purchaserApp.controller("purchaserInventoryFixCtrl", function(
    $scope, $q, $timeout, dateFilter, localStorageService, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter, purchaserService,
    wgoodService, user, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log(user); 
    $scope.shops   = user.sortShops;    
    $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season;
    $scope.calc_row = stockUtils.calc_row;

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.has_saved = false; 
    }; 

    // focus
    $scope.focus      = {style_number:true, fix: false};
    $scope.auto_focus = function(attr){
	if (!$scope.focus[attr]){
	    $scope.focus[attr] = true;
	}
	for (var o in $scope.focus){
	    if (o !== attr) $scope.focus[o] = false;
	} 
    };

    $scope.right = {
	master: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	)
    };

    /*
     * init
     */ 
    // $scope.refresh();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.current_inventories = [];
    $scope.select = {shop:$scope.shops[0]}
    $scope.has_saved = false;

    $scope.get_employee = function(){
	var select = stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = select.login;
	$scope.employees = select.filter;
    };

    $scope.get_employee();
    
    var now = $.now(); 
    $scope.base_settings = {
	plimit : stockUtils.prompt_limit($scope.select.shop.id, base),
	prompt : stockUtils.typeahead($scope.select.shop.id, base),
	start_time : stockUtils.start_time($scope.select.shop.id, base, now, dateFilter)
    };
    
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.today = function(){
	return now;
    }

    $scope.match_style_number = function(viewValue){
	// console.log(viewValue);
	return diabloFilter.match_w_fix(viewValue, $scope.select.shop.id);
    }

    $scope.get_all_prompt_inventory = function(){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.select.shop.id,
	     start_time:$scope.base_settings.start_time}
	).$promise.then(function(invs){
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    var p = stockUtils.prompt_name(inv.style_number, inv.brand, inv.type); 
		    return angular.extend(inv, {name:p.name, prompt:p.prompt}); 
		})
	}); 
    };

    if (diablo_frontend === $scope.base_settings.prompt){
	$scope.get_all_prompt_inventory();
    };
    
    $scope.on_select_good = function(item, model, label){
	// console.log(item); 
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "库存盘点", "盘点失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	};

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
	add.sex          = item.sex;
	add.year         = item.year;
	add.season       = item.season;
	add.org_price    = item.org_price; 
	add.discount     = item.discount;
	add.path         = item.path;

	console.log(add);

	$scope.auto_focus("fix");
	$scope.add_inventory(add); 
	return;
    };

    $scope.re_calculate = function(){
	$scope.select.total_exist = 0; 
    	$scope.select.total_fixed = 0;
	$scope.select.total_metric = 0;
	$scope.select.total_cost   = 0;
	
    	for (var i=1, l=$scope.inventories.length; i<l; i++){
    	    var one = $scope.inventories[i];
	    one.calc = stockUtils.calc_row(one.org_price, 100, one.metric);
	    $scope.select.total_exist += stockUtils.to_integer(one.total); 
	    $scope.select.total_fixed += stockUtils.to_integer(one.fixed);
	    $scope.select.total_cost  += one.calc;
    	}
	
	$scope.select.total_metric = $scope.select.total_fixed - $scope.select.total_exist; 
    };

    /*
     * draft
     */
    var gen_draft = function() {
	return new stockDraft(
	    localStorageService,
	    undefined,
	    $scope.select.shop.id,
	    $scope.select.employee.id,
	    diablo_dkey_stock_fix)
    };

    $scope.sDraft = gen_draft();

    $scope.disable_draft = function(){
	if ($scope.sDraft.keys().length === 0) return true; 
	if ($scope.inventories.length !== 1) return true; 
	return false;
    };

    $scope.list_draft = function(){
	var draft_filter = function(keys){
	    return keys.map(function(k){
		var p = k.split("-");
		return {sn:k,
			shop:diablo_get_object(parseInt(p[1]), $scope.shops),
		       	employee:diablo_get_object(p[2], $scope.employees)}
	    });
	};

	var select = function(draft, resource){
	    $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
	    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops);
	    // $scope.select.frim = diablo_get_object(draft.firm.id, $scope.firms);
	    $scope.inventories = angular.copy(resource); 
	    $scope.inventories.unshift({$edit:false, $new:true});
	    $scope.disable_refresh = false;
	    $scope.re_calculate();
	    $scope.auto_focus("style_number");
	};

	$scope.sDraft.select(diabloUtilsService, "wfix-draft.html", draft_filter, select); 
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	return $scope.has_saved || $scope.inventories.length === 1 ? true : false;
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true
	// console.log($scope.inventories); 
	var added = [];
	var get_fixed = function(amounts){
	    var fixed_amounts = []; 
	    angular.forEach(amounts, function(a){
		if (angular.isDefined(a.fixed_count) && a.fixed_count){
		    if (stockUtils.to_integer(a.fixed_count) !== a.count){
			a.fixed_count = stockUtils.to_integer(a.fixed_count);
			fixed_amounts.push(a)
		    }
		}
	    })

	    return fixed_amounts;
	}
	
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // get changed only
	    var fixed_amounts = get_fixed(add.amounts);
	    if ( fixed_amounts !== 0){
		added.push({
		    style_number    : add.style_number,
		    brand           : add.brand_id,
		    firm            : add.firm_id,
		    type            : add.type_id,
		    year            : add.year,
		    season          : add.season,
		    s_group         : add.s_group,
		    free            : add.free,
		    exist           : add.total,
		    fixed           : add.fixed,
		    metric          : add.metric,
		    org_price       : add.org_price,
		    amounts         : fixed_amounts,
		    // fprice          : add.org_price,
		    // fdiscount       : add.discount,
		    path            : add.path 
		})
	    } 
	}; 

	var base = {
	    shop:             $scope.select.shop.id,
	    date:             dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:         $scope.select.employee.id,
	    total_exist:      $scope.select.total_exist,
	    total_fixed:      $scope.select.total_fixed,
	    total_metric:     $scope.select.total_metric,
	    total_cost:       $scope.select.total_cost
	};

	console.log(added);
	console.log(base);
	// return;

	// $scope.has_saved = true
	purchaserService.fix_purchaser_inventory({
	    inventory: added.length === 0 ? undefined : added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		$scope.sDraft.remove();
	    	diabloUtilsService.response_with_callback(
	    	    true, "库存盘点", "盘点成功！！盘点单号：" + state.rsn,
		    $scope, undefined)
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "库存盘点",
	    	    "盘点失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    /*
     * add
     */ 
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
    };
    
    var valid_fixed = function(amount){
	var re = /^[+|\-]?\d+$/;
	// var re = /^\d+$/;
	if (angular.isDefined(amount) && amount.fixed_count && !re.test(amount.fixed_count)){
	    return false;
	};
	
	return true
    };
    
    var valid_all = function(amounts){
	// var re = /^\d+$/;
	var re = /^[+|\-]?\d+$/;
	var unchanged = 0;
	for(var i=0, l=amounts.length; i<l; i++) {
	    var amount = amounts[i];
	    
	    if (angular.isUndefined(amount.fixed_count)
		|| !amount.fixed_count){
		unchanged++;
		continue;
	    }
	    
	    if (angular.isDefined(amount.fixed_count) && amount.fixed_count
		&& !re.test(amount.fixed_count)){
		// console.log(re.test(amount.fixed_count));
		return false; 
	    } 
	}

	// return unchanged === l ? false : true;
	// console.log(unchanged);
	return unchanged !== 0 ? false : true;
    };
    
    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new = false;

	inv.fixed = inv.amounts[0].fixed_count;
	inv.metric = parseInt(inv.fixed) - inv.total;
	
	// oreder
	inv.order_id = $scope.inventories.length;
	$scope.sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true}); 

	$scope.auto_focus("style_number");
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number, brand:inv.brand_id, shop:$scope.select.shop.id}
	).then(function(invs){
	    console.log(invs);
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort;

	    var after_add = function(){
		console.log(inv);
		inv.$edit = true;
		inv.$new = false;
		// oreder
		inv.order_id = $scope.inventories.length;
		
		// save to local storage
		$scope.sDraft.save($scope.inventories.filter(function(r){return !r.$new})); 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true}); 

		$scope.auto_focus("style_number");
		$scope.re_calculate(); 
	    };
	    
	    var callback = function(params){
		inv.amounts = params.amounts;
		inv.fixed   = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.fixed_count) && a.fixed_count){
			inv.fixed += parseInt(a.fixed_count);
		    }
		})
		inv.metric  = parseInt(inv.fixed) - inv.total;
		after_add();
	    }; 
	    
	    if (inv.free === 0){
		inv.free_color_size = true;
		// inv.amounts = [{cid:0, size:0, count:inv.total}];
	    } else{
		inv.free_color_size = false;
		var modal_size = diablo_valid_dialog(inv.sizes);
		var large_size = modal_size === 'lg' ? true : false
		var payload = {sizes:        inv.sizes,
			       large_size:   large_size,
			       colors:       inv.colors,
			       amounts:      inv.amounts,
			       get_amount:   get_amount,
			       valid_fixed:  valid_fixed,
			       valid_all:    valid_all
			      };

		diabloUtilsService.edit_with_modal(
		    "inventory-fix.html", modal_size, callback, $scope, payload); 
	    }; 
	}); 
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

	$scope.sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false
	var payload = {sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors,
		       fixed:        inv.fixed,
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-fix-detail.html", modal_size, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    return;
	}
	
	var callback = function(params){
	    inv.amounts = params.amounts;
	    inv.fixed   = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.fixed_count) && a.fixed_count){
		    inv.fixed += parseInt(a.fixed_count);
		}
	    })
	    inv.metric  = parseInt(inv.fixed) - inv.total; 
	    // save to local
	    $scope.sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false
	
	var payload = {sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors,
		       fixed:        inv.fixed,
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       valid_fixed:  valid_fixed,
		       valid_all:    valid_all}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-fix.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.fixed = inv.amounts[0].fixed_count;
	inv.metric = parseInt(inv.fixed) - inv.total;
	$scope.local_save();
	$scope.re_calculate(); 
    }

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	// inv.org_price  = inv.o_org_price;
	// inv.amounts[0].reject_count = inv.reject;
    }

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    }

    $scope.timeout_auto_save = undefined;
    $scope.auto_save_free = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	if (0 === stockUtils.to_integer(inv.amounts[0].fixed_count) ){
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
});



purchaserApp.controller("purchaserInventoryFixDetailCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, wgoodService,
    user, filterEmployee, base){
    console.log(user);

    $scope.goto_page = diablo_goto_page;

    $scope.go_fix = function(){
	$scope.goto_page('#/inventory/inventory_fix');
    };

    $scope.go_fix_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/fix');
    };

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.sortShops);
    // diabloFilter.add_field("shop",     user.sortAvailabeShops);
    // diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, diablo_set_date, diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start); 
    // $scope.time   = diabloFilter.default_time();

    console.log($scope.filter);
    
    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = 10;
    $scope.default_page = 1;
    // $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = user.availableShopIds.length
		    === 0 ? undefined : user.shopIds; ;
	    }

	    purchaserService.filter_fix_w_inventory(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.shop = diablo_get_object(d.shop_id, user.sortShops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    })
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		})

	    $scope.current_page = page;
	    
	})
    };
    
    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	diablo_goto_page("#/inventory/inventory_rsn_detail/fix/" + r.rsn);
    }
    
})
