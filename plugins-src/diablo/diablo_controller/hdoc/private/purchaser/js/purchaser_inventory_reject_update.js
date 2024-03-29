'use strict'

function purchaserInventoryRejectUpdateCtrlProvide(
    $scope, $q, $routeParams, dateFilter, diabloPattern, diabloUtilsService,
    diabloPromise, diabloFilter, diabloPagination, purchaserService,
    user, filterBrand, filterFirm, filterEmployee,
    filterSizeGroup, filterColor, base){
    // console.log(user);

    console.log($routeParams);
    // $scope.shops     = user.sortShops;
    $scope.shops           = user.sortBadRepoes.concat(user.sortShops);
    $scope.brands          = filterBrand;
    // $scope.types           = filterType;
    $scope.firms           = filterFirm;
    // $scope.employees       = filterEmployee;
    $scope.ubase           = base;
    
    // $scope.shops     = user.sortAvailabeShops;
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.get_object      = diablo_get_object;
    $scope.round           = diablo_round;
    $scope.calc_row        = stockUtils.calc_row;
    $scope.calc_drate      = stockUtils.calc_drate_of_org_price;
    
    var dialog             = diabloUtilsService;
    var setv               = diablo_set_float;
    
    $scope.pattern           = {
	price:    diabloPattern.positive_decimal_2,
	discount: diabloPattern.discount,
	amount:   diabloPattern.positive_num
    }; 
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season; 
    $scope.e_pay_types     = purchaserService.extra_pay_types;

    $scope.setting = {reject_negative: false, history_stock: false}; 
    
    $scope.go_back = function(){
	if (diablo_from_update_stock === stockUtils.to_integer($routeParams.from)){
	    diablo_goto_page("#/inventory_rsn_detail/" + $routeParams.rsn
			     // + "/" + $routeParams.ppage
			     + "/1"  // always bo back first page
			     + "/" + diablo_from_update_stock.toString());
	} else {
	    diablo_goto_page("#/inventory_new_detail/" + $routeParams.ppage); 
	}
    };

    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight(); 

    // init
    $scope.has_saved       = false;
    $scope.old_select      = {};
    $scope.select          = {};
    $scope.inventories     = [];
    $scope.h_inventories   = [];
    $scope.h_items_perpage = 5;
    $scope.h_current_page  = 1;

    $scope.focus_attrs = {org_price:true, ediscount:false};
    $scope.on_focus_attr = function(attr, inv){
	// console.log(attr);
	if (angular.isDefined(diablo_set_integer(inv.order_id))
	    && inv.order_id !== $scope.focus_row){
	    $scope.focus_row = inv.order_id; 
	}
	
	if (!$scope.focus_attrs[attr]){
	    $scope.focus_attrs[attr] = true;
	    for (var o in $scope.focus_attrs){
		if (o !== attr) $scope.focus_attrs[o] = false;
	    }
	}

	if ($scope.stock_right.show_orgprice && $scope.setting.history_stock){
	    // flow
	    var filter_history = $scope.h_inventories.filter(function(h){
		return h.style_number === inv.style_number
		    && h.brand_id === inv.brand.id
	    });

	    // console.log(inv);
	    var end_time = $scope.old_select.datetime.getTime() + diablo_day_millisecond;
	    if (filter_history.length === 0){
		purchaserService.list_w_inventory_new_detail({
		    style_number:inv.style_number,
		    brand:inv.brand.id,
		    start_time: $scope.setting.q_start_time
		}).then(function(result){
		    // console.log(result);
		    if (result.ecode === 0){
			var history = angular.copy(result.data).sort(function(h1, h2) {
			    return diablo_set_date(h1.entry_date) - diablo_set_date(h2.entry_date);
			});
			
			angular.forEach(history, function(h){
			    h.firm  = diablo_get_object(h.firm_id, $scope.firms);
			    h.brand = inv.brand;
			    h.shop = diablo_get_object(h.shop_id, $scope.shops);
			});

			$scope.select_history = {style_number:inv.style_number,
						 brand_id:    inv.brand.id,
						 history: history};
			
			$scope.h_inventories.splice(0, 0, $scope.select_history);
			$scope.h_pagination($scope.select_history.history);
			// console.log($scope.h_inventories); 
		    }
		}) 
	    } else {
		$scope.select_history = filter_history[0];
		$scope.h_pagination($scope.select_history.history);
	    }
	}
    };

    $scope.h_pagination = function(history){
	diabloPagination.set_data(history.reverse());
	diabloPagination.set_items_perpage($scope.h_items_perpage);
	$scope.h_total_items = diabloPagination.get_length(); 
	$scope.h_current_page = 1;
	$scope.p_history = diabloPagination.get_page($scope.h_current_page);
	// console.log($scope.p_history);
    };

    $scope.h_page_changed = function(page) {
	$scope.h_current_page = page;
	$scope.p_history = diabloPagination.get_page($scope.h_current_page);
    }

    $scope.focus_row_auto = function(direction){
	if (diablo_up === direction){
	    if ($scope.focus_row < $scope.inventories.length - 1){
		$scope.focus_row += 1; 
	    }
	}

	if (diablo_down === direction){
	    if ($scope.focus_row > 1){
		$scope.focus_row -= 1; 
	    }
	} 
	return $scope.focus_row;
    };

    $scope.focus_css = function(order, render){
	return render && $scope.focus_row === order ? "vert-align bg-cyan" : "vert-align";
    }; 

    $scope.row_change_price = function(inv){
	// inv.org_price = stockUtils.to_float(inv.org_price);
	inv.ediscount = diablo_discount(
	    stockUtils.to_float(inv.org_price),
	    stockUtils.to_float(inv.tag_price));
	
	if (angular.isDefined(diablo_set_float(inv.org_price))){
	    $scope.re_calculate(); 
	}
    };

    $scope.row_change_ediscount = function(inv){
	inv.org_price = diablo_price(
	    stockUtils.to_float(inv.tag_price),
	    stockUtils.to_float(inv.ediscount));
	
	if (angular.isDefined(diablo_set_float(inv.ediscount))){
	    $scope.re_calculate();
	}
    };
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0;

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total      += parseInt(one.reject);

	    $scope.select.should_pay += stockUtils.calc_row(
		stockUtils.to_float(one.org_price), 100, one.reject); 
	};

	$scope.select.should_pay = stockUtils.to_decimal($scope.select.should_pay);
	
	var e_pay = stockUtils.to_float($scope.select.e_pay); 
	$scope.select.left_balance = $scope.select.surplus - $scope.select.should_pay - e_pay;
	$scope.select.left_balance = stockUtils.to_decimal($scope.select.left_balance);
    };

    $scope.get_prompt_firm = function(prompt){
	return stockUtils.get_prompt_firm(prompt, $scope.firms)};
    
    $scope.change_firm = function(){
	console.log($scope.select.firm);
	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.re_calculate();
    }
    
    $scope.$watch("select.e_pay", function(newValue, oldValue){
    	// console.log(newValue);
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    }); 
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    // rsn detail
    var in_sort = function(sorts, tag){
	for (var i=0, l=sorts.length; i<l;i ++){
	    if(tag.style_number === sorts[i].style_number
	       && tag.brand_id  === sorts[i].brand.id){
		if (!in_array(sorts[i].sizes, tag.size)){
		    sorts[i].sizes.push(tag.size)
		}
		
		sorts[i].amounts.push({
		    cid:tag.color_id,
		    size:tag.size,
		    reject:Math.abs(tag.amount)}); 
		sorts[i].reject += Math.abs(tag.amount);
		return true;
	    }
	}

	return false;
    };


    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    $q.all([
	promise(purchaserService.get_w_invnetory_new, rsn)(),
	promise(purchaserService.get_w_invnetory_new_amount, {rsn:rsn})()
    ]).then(function(result){
	console.log(result);
	// result[0] is the record detail
	// result[1] are the inventory detail that the record is included
	var baseInfo = result[0];
	var invs = result[1].data; 
	
	$scope.old_select.rsn        = rsn;
	$scope.old_select.rsn_id     = baseInfo.id;
	$scope.old_select.firm       = $scope.get_object(baseInfo.firm_id, $scope.firms); 
	$scope.old_select.datetime   = diablo_set_datetime(baseInfo.entry_date);
	
	// console.log($scope.e_pay_types);
	if (baseInfo.e_pay_type === -1){
	    $scope.old_select.e_pay_type = $scope.e_pay_types[0];
	    $scope.old_select.e_pay      = undefined;
	} else{
	    $scope.old_select.e_pay_type = $scope.get_object(baseInfo.e_pay_type, $scope.e_pay_types);
	    $scope.old_select.e_pay      = baseInfo.e_pay; 
	}
	
	// $scope.old_select.surplus    = $scope.old_select.firm.balance;
	var loginInfo = stockUtils.get_login_employee(baseInfo.shop_id, user.loginEmployee, filterEmployee);
	
	// console.log(loginInfo);
	// $scope.select.employee = loginInfo.login;
	$scope.employees = loginInfo.filter; 
	$scope.old_select.shop = $scope.get_object(baseInfo.shop_id, $scope.shops); 
	$scope.old_select.employee = $scope.get_object(baseInfo.employee_id, $scope.employees);
	
	$scope.old_select.surplus      = baseInfo.balance;
	$scope.old_select.comment      = baseInfo.comment;
	$scope.old_select.total        = Math.abs(baseInfo.total); 
	$scope.old_select.should_pay   = Math.abs(baseInfo.should_pay);
	$scope.old_select.left_balance = stockUtils.to_decimal(baseInfo.balance + baseInfo.should_pay);
	// $scope.old_select.rsn          = base.rsn;

	console.log($scope.old_select);
	$scope.select = angular.extend($scope.select, $scope.old_select);

	// base setting
	$scope.setting.stock_with_firm = stockUtils.stock_mode(baseInfo.shop_id, $scope.ubase).check_i_firm; 
	$scope.setting.reject_negative = stockUtils.reject_negative(baseInfo.shop_id, $scope.ubase);
	$scope.setting.history_stock = stockUtils.history_stock(baseInfo.shop_id, $scope.ubase);
	$scope.setting.q_start_time =
	    dateFilter(stockUtils.start_time(base.shop_id, $scope.ubase, $.now(), dateFilter), "yyyy-MM-dd");
	
	$scope.prompt_limit = stockUtils.prompt_limit(baseInfo.shop_id, $scope.ubase); 
	$scope.q_prompt = stockUtils.typeahead(baseInfo.shop_id, $scope.ubase); 
	console.log($scope.q_prompt);
	
	if ($scope.q_prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory(baseInfo.shop_id, base.firm_id);
	}
	
	var length = invs.length;
	var sorts  = [];
	for(var i = 0; i < length; i++){
	    if(!in_sort(sorts, invs[i])) {
		var add = {$edit:true,
			   $new:false,
			   sizes:[],
			   colors:[],
			   amounts:[]};
		
		add.style_number    = invs[i].style_number;
		add.brand           = $scope.get_object(invs[i].brand_id, $scope.brands);
		// add.type            = $scope.get_object(invs[i].type_id, $scope.types);
		add.type_id         = invs[i].type_id;
		add.type            = invs[i].type;
		add.name = add.style_number + "/" + add.brand.name + "/" + add.type;
		add.firm_id         = invs[i].firm_id;
		add.sex             = invs[i].sex;
		add.free            = invs[i].free;
		add.season          = invs[i].season;
		add.year            = invs[i].year;
		add.path            = invs[i].path;
		add.s_group         = invs[i].s_group;
		add.free_color_size = invs[i].free === 0 ? true : false;
		add.org_price       = invs[i].org_price;
		add.ediscount       = invs[i].ediscount;
		add.tag_price       = invs[i].tag_price;
		add.discount        = invs[i].discount; 
		add.reject          = Math.abs(invs[i].amount);
		
		add.sizes.push(invs[i].size);
		add.colors.push(diablo_find_color(invs[i].color_id, filterColor));
		
		add.amounts.push(
		    {cid:invs[i].color_id, size:invs[i].size, reject:Math.abs(invs[i].amount)})
		sorts.push(add); 
	    } 
	}

	// console.log(sorts);
	$scope.old_inventories = sorts;
	
	var order_length = sorts.length;
	angular.forEach(sorts, function(s){
	    var tag = angular.copy(s);
	    tag.order_id = order_length;
	    if (tag.sizes.length !== 1 || tag.sizes[0] !=="0" ){
		tag.sizes = diabloHelp.usort_size_group(tag.s_group, filterSizeGroup); 
	    }
	    $scope.inventories.push(tag);
	    order_length--;
	})

	$scope.inventories.unshift({$edit:false, $new:true});
	$scope.focus_row = sorts.length; 

	// console.log($scope.old_inventories);
	// console.log($scope.inventories);
    });

    // match
    $scope.match_prompt_inventory = function(viewValue){
	return diabloFilter.match_w_reject_inventory(
	    viewValue, $scope.select.shop.id, stockUtils.invalid_firm($scope.select.firm)); 
    };

    $scope.qtime_start = function(shopId){
	var now = $.now();
	return stockUtils.start_time(shopId, base, now, dateFilter); 
    };
    
    $scope.get_all_prompt_inventory = function(shop, firm){
	diabloFilter.match_all_w_reject_inventory(
	    $scope.qtime_start(shop),
	    shop,
	    firm
	).then(function(invs){
	    // console.log(invs);
	    $scope.all_prompt_inventory = invs.map(function(inv){
		var p = stockUtils.prompt_name(
		    inv.style_number, inv.brand, inv.type);
		return angular.extend(inv, {name:p.name, prompt:p.prompt}); 
	    });
	});
    };
    
    $scope.on_select_inventory = function(item, model, label){
	console.log($scope.q_prompt);
	console.log(item); 
	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false,
		    "退货单修改",
		    "退货单修改失败：" + purchaserService.error[2099],
		    undefined,
		    function(){
			$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }

	    if (item.firm_id !== $scope.inventories[i].firm_id){
		diabloUtilsService.response_with_callback(
		    false,
		    "退货单修改",
		    "退货单修改失败：" + purchaserService.error[2093],
		    $scope, function(){
			$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    };
	}
	
	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.name         = item.name;
	add.style_number = item.style_number; 
	add.brand        = $scope.get_object(item.brand_id, $scope.brands); 
	// add.type         = $scope.get_object(item.type_id, $scope.types);
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.firm_id      = item.firm_id;
	add.s_group      = item.s_group;
	add.free         = item.free; 
	add.sex          = item.sex;
	add.season       = item.season;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.ediscount    = item.ediscount;
	add.discount     = item.discount;
	add.year         = item.year;
	add.path         = item.path;

	console.log(add);

	$scope.add_inventory(add);
	
	return;
    }; 
    
    var get_update_amount = function(newAmounts, oldAmounts){
	var filterNewAmounts = newAmounts.filter(function(m){
	    return stockUtils.to_integer(m.reject) !== 0; 
	}); 
	console.log(filterNewAmounts);
	
	var changedAmounts = [];
	var found = false;
	for (var i=0, l1=filterNewAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=oldAmounts.length; j < l2; j++){
		if (filterNewAmounts[i].cid === oldAmounts[j].cid
		    && filterNewAmounts[i].size === oldAmounts[j].size){
		    // update
		    found = true; 
		    var update_count = parseInt(filterNewAmounts[i].reject) - parseInt(oldAmounts[j].reject);
		    
		    if ( update_count !== 0 ){
			changedAmounts.push(
			    {operation: 'u',
			     cid:       filterNewAmounts[i].cid,
			     size:      filterNewAmounts[i].size,
			     count:     -update_count})
		    } 
		    break;
		} 
	    }

	    // new
	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'a',
		     cid:       filterNewAmounts[i].cid,
		     size:      filterNewAmounts[i].size,
		     count:     -parseInt(filterNewAmounts[i].reject)});
	    }
	}

	// delete
	for (var i=0, l1=oldAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=filterNewAmounts.length; j < l2; j++){
		if (oldAmounts[i].cid === filterNewAmounts[j].cid
		    && oldAmounts[i].size == filterNewAmounts[j].size){
		    found = true;
		    break;
		} 
	    }

	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'd',
		     cid:       oldAmounts[i].cid,
		     size:      oldAmounts[i].size,
		     count:     -parseInt(oldAmounts[i].reject)});
	    }
	}

	console.log(changedAmounts);
	return changedAmounts;
    };
    
    var get_update_inventory = function(){
	var changedInvs = [];
	var found = false;
	for (var i=1, l1=$scope.inventories.length; i < l1; i++){
	    var newInv = $scope.inventories[i];
	    found = false;
	    for (var j=0, l2=$scope.old_inventories.length; j < l2; j++){
		var oldInv = $scope.old_inventories[j];
		// update
		if (newInv.style_number === oldInv.style_number && newInv.brand.id === oldInv.brand.id){
		    var change_amouts = get_update_amount(newInv.amounts, oldInv.amounts);
		    
		    if (change_amouts.length !== 0){
			newInv.operation = 'u';
			// newInv.old_total = oldInv.total;
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			// console.log(newInv);
			// console.log(oldInv);
			// if (parseFloat(newInv.org_price) !== oldInv.org_price
			//     || parseFloat(newInv.ediscount) !== oldInv.ediscount){
			//     newInv.operation = 'u';
			//     changedInvs.push(newInv);
			// }
			
			if (stockUtils.to_float(newInv.org_price) !== stockUtils.to_float(oldInv.org_price) 
			    || stockUtils.to_float(newInv.ediscount) !== stockUtils.to_float(oldInv.ediscount)) {
			    newInv.operation = 'u';
			    changedInvs.push(newInv);
			}
			
		    }
		    found = true;
		    break;
		} 
	    }
	    
	    if ( !found ){
		// add
		newInv.operation = 'a';
		changedInvs.push(newInv);
	    } 
	}

	// deleted
	for (var i=0, l1=$scope.old_inventories.length; i < l1; i++){
	    var oldInv = $scope.old_inventories[i];
	    found = false;
	    for (var j=1, l2=$scope.inventories.length; j < l2; j++){
		var newInv = $scope.inventories[j];
		// console.log(oldInv);
		// console.log(newInv);
		if (oldInv.style_number === newInv.style_number
		    && oldInv.brand.id === newInv.brand.id){
		    found = true;
		    break;
		} 
	    }
	    
	    if ( !found ){
		oldInv.operation = 'd';
		changedInvs.push(oldInv);
	    }
	} 

	console.log(changedInvs);
	return changedInvs;
    };


    $scope.save_inventory = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories);

	if ( ($scope.setting.stock_with_firm
	      && (angular.isUndefined($scope.select.firm)
		  || diablo_is_empty($scope.select.firm)))
	    || angular.isUndefined($scope.select.shop)
	    || diablo_is_empty($scope.select.shop)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response_with_callback(
		false, "采购退货编辑", "采购退货编辑失败："
		    + purchaserService.error[2096], undefined, function(){
			$scope.has_saved = false; 
		    });
	    return;
	};

	// check
	$scope.re_calculate();
	
	var updates = get_update_inventory();
	console.log(updates);
	
	var added = [];
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];

	    if (angular.isUndefined(add.style_number)){
		diabloUtilsService.response(
		    false,
		    "新增库存",
		    "新增库存失败：[" 
			+ add.order_id + "]：" + purchaserService.error[2092]
		    	+ "款号：" + add.style_number + "！！", 
		    undefined);
		return;
	    };
	    
	    added.push({
		style_number   : add.style_number,
		brand          : add.brand.id,
		firm           : stockUtils.invalid_firm($scope.select.firm),
		type           : add.type_id,
		sex            : add.sex,
		season         : add.season,
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			// console.log(add.amounts);
			var filter =  add.amounts.filter(function(m){
			    return stockUtils.to_integer(m.reject) !== 0; 
			});

			return filter.map(function(m){
			    return {cid:m.cid, size:m.size, count:-m.reject};
			});
		    }}(),
		s_group        : add.s_group,
		free           : add.free,
		org_price      : stockUtils.to_float(add.org_price),
		tag_price      : parseFloat(add.tag_price), 
		ediscount      : stockUtils.to_float(add.ediscount),
		// discount       : add.discount,
		year           : add.year,
		path           : add.path,
		total          : -add.reject
		// old_total      : add.old_total
	    })
	};

	// var setv = diablo_set_float; 
	var new_datetime = dateFilter($scope.select.datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.datetime, "yyyy-MM-dd");
	
	if (added.length === 0
	    && ($scope.select.cash === $scope.old_select.cash 
		&& $scope.select.employee.id === stockUtils.get_object_id($scope.old_select.employee)
		&& $scope.select.comment === $scope.old_select.comment
		&& stockUtils.invalid_firm($scope.select.firm) === stockUtils.invalid_firm($scope.old_select.firm)
		&& stockUtils.to_float($scope.select.e_pay) === stockUtils.to_float($scope.old_select.e_pay)
		&& new_datetime === old_datetime)){
	    dialog.response_with_callback(
	    	false,
		"采购退货编辑",
		"采购退货编辑失败：" + purchaserService.error[2094],
	    $scope, function(){$scope.has_saved = false});
	    return;
	}
	
	var base = {
	    id:             $scope.select.rsn_id,
	    mode:           diablo_stock_reject,
	    rsn :           $scope.select.rsn,
	    firm:           stockUtils.invalid_firm($scope.select.firm),
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        diablo_set_string($scope.select.comment),
	    total:          -diablo_set_integer($scope.select.total),
	    
	    balance:        parseFloat($scope.select.surplus), 
	    should_pay:     stockUtils.get_opposite(setv($scope.select.should_pay)),
	    e_pay: stockUtils.get_opposite(setv($scope.select.e_pay)), 

	    e_pay_type:     function(){
		if (stockUtils.to_float($scope.select.e_pay) === 0) return undefined;
		return $scope.select.e_pay_type.id; 
	    }(),

	    old_firm:       stockUtils.invalid_firm($scope.old_select.firm),
	    old_balance:    setv($scope.old_select.surplus),
	    old_should_pay: stockUtils.get_opposite(setv($scope.old_select.should_pay)),
	    old_epay:       stockUtils.get_opposite(setv($scope.old_select.e_pay)),
	    old_datetime:   dateFilter($scope.old_select.datetime, "yyyy-MM-dd HH:mm:ss")
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = false; 
	purchaserService.update_w_inventory_new({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true,
		    "采购退货编辑",
		    "采购退货编辑成功！！单号：" + state.rsn,
		    undefined,
		    function(){
			diabloFilter.reset_firm();
			$scope.go_back();
		    })
	    	return;
	    } else{
	    	dialog.response_with_callback(
	    	    false,
		    "退货单修改",
	    	    "退货单修改失败：" + purchaserService.error[state.ecode],
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	})
    }; 

    /*
     * add
     */

    var get_amount = function(cid, sname, amounts){
	// console.log(cid, sname, amounts);
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    $scope.valid_free = function(inv){

	// console.log(inv);
	if (angular.isDefined(inv.amounts)
    	    && angular.isDefined(inv.amounts[0].reject)
	    && !$scope.setting.reject_negative
    	    && parseInt(inv.amounts[0].reject) > inv.total){
	    return false;
    	}
	
	return true;
    };
    
    var valid_all = function(amounts){
	var unchanged = 0;
	// var invalid = true;
	for(var i=0, l=amounts.length; i<l; i++){
	    var amount = amounts[i];
	    if (angular.isUndefined(amount.count) || !amount.count){
		unchanged++;
	    }
	    else {
		if (!$scope.setting.reject_negative &&
		    diablo_set_integer(amount.reject) > amount.count){
		    // unchanged++
		    return false;
		}
	    }
	}
	
	return unchanged == l ? false : true;
    };

    var select_amount = function(invs, selected){
	// console.log(invs);
	var select_amounts = [];
	var colors = [];
	var total = 0;
	for (var i=0, l=invs.length; i<l; i++){
	    var inv = invs[i];
	    var color = diablo_find_color(inv.color_id, filterColor);
	    var amount = {cid:   color.cid,
			  size:  inv.size,
			  cname: color.cname,
			  count: inv.amount};

	    total += inv.amount;
	    select_amounts.push(amount);

	    if (!diablo_in_colors(color, colors)){
		colors.push(color); 
	    }
	    
	    // get select
	    for (var j=0, k=selected.length; j<k; j++){
		var s = selected[j];
		if (inv.color_id === s.cid && inv.size === s.size){
		    // amount.old_reject = s.reject;
		    total += parseInt(s.reject);
		    amount.count += parseInt(s.reject);
		    amount.reject = parseInt(s.reject); 
		    break;
		}
	    }
	}

	return {total: total, select_amounts:select_amounts, colors:colors};
    }

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$edit = true;
	inv.$new = false;
	inv.reject = inv.amounts[0].reject;
	
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true});
	
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number,
	     brand:inv.brand.id,
	     shop:$scope.select.shop.id,
	     qtype: diablo_badrepo}
	).then(function(invs){
	    console.log(invs);
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    // inv.amounts = sort.sort;
	    inv.select_amounts = sort.sort;

	    console.log(inv);

	    var add_callback = function(params){
		console.log(params.amounts);
		
		var reject = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.reject) && a.reject){
			reject += parseInt(a.reject);
		    }
		})

		return {amounts:   params.amounts,
			reject:    reject,
			fprice:    params.fprice,
			fdiscount: params.fdiscount};
	    };

	    var after_add = function(){
		inv.$edit = true;
		inv.$new = false;
		
		// order
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});
		
		$scope.re_calculate(); 
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.fprice;
		inv.ediscount = result.fdiscount;
		after_add();
	    };

	    if (inv.free === 0){
		// console.log(inv);
		// inv.total = inv.select_amounts[0].count;
		inv.amounts = [{cid:0, size:'0', count:sort.total}];
		inv.free_color_size = true;
	    } else{
		inv.free_color_size = false;
		var payload = {sizes:        inv.sizes,
			       colors:       inv.colors,
			       fprice:       inv.org_price,
			       fdiscount:    inv.ediscount,
			       amounts:      inv.select_amounts,
			       get_amount:   get_amount, 
			       valid:        valid_all,
			       pattern:      $scope.pattern};
		
		dialog.edit_with_modal(
		    "inventory-new.html", 'normal',
		    callback, undefined, payload); 
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
	// console.log(inv);
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       fprice:       inv.org_price,
		       fdiscount:    inv.ediscount,
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	// console.log(inv);
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    // inv.o_org_price = inv.org_price;
	    // inv.o_ediscount = inv.ediscount;
	    return;
	}

	var callback = function(params){
	    inv.amounts = params.amounts;
	    inv.reject  = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.reject) && a.reject){
		    inv.reject += parseInt(a.reject);
		}
	    });

	    inv.org_price = params.fprice;
	    inv.ediscount = params.fdiscount;
	    
	    $scope.re_calculate(); 
	};
	
	var payload = {sizes:        inv.sizes,
		       // colors:       inv.colors,
		       fprice:       inv.org_price,
		       fdiscount:    inv.ediscount,
		       get_amount:   get_amount,
		       valid:        valid_all};
	
	if (angular.isDefined(inv.select_amounts)){
	    payload.amounts = inv.amounts;
	    payload.colors  = inv.colors;
	    dialog.edit_with_modal(
		"inventory-new.html", 'normal', callback, $scope, payload);
	} else {
	    purchaserService.list_purchaser_inventory({
		style_number:inv.style_number,
		brand:inv.brand.id,
		shop:$scope.select.shop.id,
	    	qtype:diablo_badrepo
	    }).then(function(exists){
		console.log(exists);
		
		var s = select_amount(exists, inv.amounts);
		inv.select_amounts = s.select_amounts;
		inv.amounts = s.select_amounts;
		inv.total   = s.total;
		inv.colors  = s.colors;

		// console.log(inv);
		if (inv.free_color_size){
		    // return;
		} else {
		    payload = {sizes:        inv.sizes,
			       colors:       inv.colors,
			       fprice:       inv.org_price,
			       fdiscount:    inv.ediscount,
			       amounts:      inv.select_amounts,
			       get_amount:   get_amount,
			       valid:        valid_all}; 
		    dialog.edit_with_modal(
			"inventory-new.html", 'normal',
			callback, $scope, payload)
		} 
	    });
	} 
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false;
	inv.reject  = inv.amounts[0].reject;
	$scope.re_calculate(); 
    };

    $scope.cancel_free_update = function(inv){
	inv.free_update = false;
	inv.amounts[0].reject_count = inv.reject;
	// inv.org_price   = inv.o_org_price;
	// inv.ediscount   = inv.o_ediscount;
    };

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
};

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryRejectUpdateCtrl", purchaserInventoryRejectUpdateCtrlProvide);
});


