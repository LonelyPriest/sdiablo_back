purchaserApp.controller("purchaserInventoryPriceCtrl", function(
    $scope, $q, $timeout, dateFilter, localStorageService, diabloPattern,
    diabloUtilsService, diabloFilter, diabloNormalFilter,
    purchaserService, wgoodService, user, filterFirm, filterEmployee, base){
    // console.log(user); 
    $scope.shops   = user.sortShops;    
    $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season; 
    $scope.employees = filterEmployee;
    $scope.firms     = filterFirm;

    $scope.pattern = {
	price: diabloPattern.positive_decimal_2,
	discount: diabloPattern.discount,
	comment: diabloPattern.comment
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.has_saved = false; 
    }; 

    // focus
    $scope.focus      = {style_number:true, tag_price:false, discount:false};
    $scope.auto_focus = function(attr){
	if (!$scope.focus[attr]){
	    $scope.focus[attr] = true;
	}
	for (var o in $scope.focus){
	    if (o !== attr) $scope.focus[o] = false;
	} 
    };

    /*
     * init
     */ 
    // $scope.refresh();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.current_inventories = [];
    $scope.select = {
	shop:$scope.shops[0],
	employee: $scope.employees[0]
    };
    
    $scope.has_saved = false;
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

    $scope.change_shop = function(){
	if ($scope.q_prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory();
	}
    };

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
		    false, "库存调价", "调价失败：" + purchaserService.error[2099],
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
	add.firm         = diablo_get_object(item.firm_id, $scope.firms);
	add.firm_id      = item.firm_id;

	// add.s_group      = item.s_group;
	// add.free         = item.free;
	add.sex          = item.sex;
	add.year         = item.year;
	add.season       = item.season;

	add.total        = item.total;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.ediscount    = item.ediscount;
	add.discount     = item.discount;
	add.path         = item.path;

	add.n_discount   = item.discount;
	add.n_tag_price  = diablo_price(item.tag_price, item.discount); 

	$scope.auto_focus("tag_price");
	return;
    };

    var sDraft = new stockDraft(localStorageService,
			       $scope.select.shop.id,
			       $scope.select.employee.id,
			       diablo_dkey_stock_price);
    
    $scope.disable_draft = function(){
	if (sDraft.keys().length === 0) return true; 
	if ($scope.inventories.length !== 1) return true; 
	return false;
    };

    $scope.list_draft = function(){
	var draft_filter = function(keys){
	    return keys.map(function(k){
		var p = k.split("-");
		return {sn:k,
			employee:diablo_get_object(p[2], $scope.employees),
			shop:diablo_get_object(parseInt(p[1]), $scope.shops)}
	    });
	};

	var select = function(draft, resource){
	    $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
	    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops);
	    $scope.inventories = angular.copy(resource);
	    $scope.inventories.unshift({$edit:false, $new:true}); 
	    re_calculate(); 
	}

	sDraft.select(diabloUtilsService, "wfix-draft.html", draft_filter, select); 
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved) return true; 
	if ($scope.inventories.length === 1) return true; 
	return false;
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true
	// console.log($scope.inventories);
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i]; 
	    added.push({
		style_number    : add.style_number,
		brand           : add.brand_id,
		discount        : add.n_discount
		// firm            : add.firm_id,
		// type            : add.type_id,
		// year            : add.year,
		// season          : add.season,
		// s_group         : add.s_group,
		// free            : add.free,
		// exist           : add.total,
		// fixed           : add.fixed,
		// metric          : add.metric,
		// amounts         : fixed_amounts,
		// fprice          : add.org_price,
		// fdiscount       : add.discount,
		// path            : add.path
	    })
	}; 

	var base = {
	    shop:             $scope.select.shop.id,
	    date:             dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:         $scope.select.employee.id 
	};

	console.log(added);
	console.log(base);
	// return;

	// $scope.has_saved = true
	purchaserService.adjust_price({
	    inventory: added.length === 0 ? undefined : added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	diabloUtilsService.response_with_callback(
	    	    true, "库存调价", "调点成功！！", undefined, function(){sDraft.remove()})
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "库存调价",
	    	    "调价失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    }; 
    
    var re_calculate = function(){
	$scope.select.total = $scope.inventories.length - 1; 
    }; 
    
    $scope.timeout_auto_save = undefined; 
    $scope.add_inventory = function(inv, direct){
	$timeout.cancel($scope.timeout_auto_save);
	if (0 === direct){
	    if ( 0 === stockUtils.to_float(inv.n_tag_price)
		 || inv.n_tag_price === inv.tag_price) return; 
	    inv.n_discount = diablo_discount(inv.n_tag_price, inv.tag_price);
	} else if (1 === direct){
	    if (0 === stockUtils.to_float(inv.n_discount)
		|| inv.n_discount === inv.discount) return;
	    inv.n_tag_price = diablo_price(inv.tag_price, inv.n_discount);
	}
	
	if (angular.isUndefined(inv.order_id)){
	    $scope.timeout_auto_save = $timeout(function(){
		console.log(inv.n_tag_price, inv.n_discount);
		inv.$new = false; 
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});
		re_calculate();
		
		sDraft.save($scope.inventories.filter(function(r){
		    return !r.$new}));
		
		$scope.auto_focus("style_number");
		$timeout.cancel($scope.timeout_auto_save);
	    }, 1000); 
	} 
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
	
	sDraft.remove();
	re_calculate();
	
    }; 
});
