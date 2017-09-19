'use strict'

function purchaserInventoryNewUpdateCtrlProvide (
    $scope, $q, $routeParams, diabloPromise, dateFilter, diabloPattern,
    diabloUtilsService, diabloFilter, diabloPagination, purchaserService,
    user, filterBrand, filterFirm, filterType, filterEmployee,
    filterSizeGroup, filterColor, filterTemplate, base){
    $scope.shops       = user.sortShops;
    $scope.brands      = filterBrand;
    $scope.firms       = filterFirm;
    $scope.types       = filterType;
    // $scope.employees   = filterEmployee;
    $scope.size_groups = filterSizeGroup;
    $scope.ubase       = base;
    $scope.sexs        = diablo_sex;
    $scope.seasons     = diablo_season;
    $scope.e_pay_types = purchaserService.extra_pay_types;
    
    $scope.has_saved   = false;

    $scope.old_select      = {};
    $scope.select          = {};
    $scope.inventories     = [];
    $scope.h_inventories   = [];
    $scope.h_items_perpage = 5;
    $scope.h_current_page  = 1;
    // $scope.select_history  = [];

    $scope.get_object = diablo_get_object;
    $scope.round      = diablo_round;
    $scope.calc_drate = stockUtils.calc_drate_of_org_price; 
    $scope.calc_row   = stockUtils.calc_row;
    $scope.setting    = {history_stock: false};
    $scope.pattern    = {discount:diabloPattern.discount};

    $scope.setting.use_barcode     = stockUtils.use_barcode(diablo_default_shop, $scope.ubase);
    $scope.setting.auto_barcode    = stockUtils.auto_barcode(diablo_default_shop, base);
    $scope.setting.printer_barcode = stockUtils.printer_barcode(user.loginShop, base);

    $scope.template = filterTemplate.length !== 0 ? filterTemplate[0] : undefined;
    $scope.printU = new stockPrintU($scope.template, $scope.setting.auto_barcode);
    $scope.printU.setPrinter($scope.setting.printer_barcode);

    var dialog = diabloUtilsService;

    $scope.go_back = function(){
	console.log($routeParams.ppage);
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
    $scope.stock_right = {
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, 'show_orgprice'),
	show_balance:  stockUtils.authen_rainbow(user.type, user.right, 'show_balance_onstock'),
	master:        rightAuthen.authen_master(user.type)
    };

    // console.log($scope.stock_right);
    
    /*
     * auto focus
     */
    $scope.focus_attrs = {org_price:true, ediscount:false, tag_price:false, discount:false};
    $scope.on_focus_attr = function(attr, inv){
	// force syn
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

	    // console.log($scope.old_select.datetime.getTime());
	    // var end_time = $scope.old_select.datetime.getTime() + diablo_day_millisecond;
	    if (filter_history.length === 0){
		purchaserService.list_w_inventory_new_detail({
		    style_number:inv.style_number,
		    brand:inv.brand_id,
		    start_time: $scope.setting.q_start_time
		}).then(function(result){
		    // console.log(result);
		    if (result.ecode === 0){
			var history = angular.copy(result.data);
			angular.forEach(history, function(h){
			    h.brand = diablo_get_object(h.brand_id, $scope.brands);
			    h.firm  = diablo_get_object(h.firm_id, $scope.firms);
			    h.shop  = diablo_get_object(h.shop_id, $scope.shops);
			});

			$scope.select_history = {style_number:inv.style_number,
						 brand_id:    inv.brand_id,
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

	// console.log($scope.focus_row);
	return $scope.focus_row;
    };

    $scope.focus_css = function(order, render){
	return render && $scope.focus_row === order ? "vert-align bg-cyan" : "vert-align";
    };
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0;
	$scope.select.acc_tag_price = 0;

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    $scope.select.total += stockUtils.to_integer(one.total);
	    $scope.select.should_pay += stockUtils.calc_row(
	    	one.org_price, 100, one.total - stockUtils.to_integer(one.over));
	    $scope.select.acc_tag_price += one.tag_price * one.total; 
	};
	
	$scope.select.should_pay = stockUtils.to_decimal($scope.select.should_pay);
	$scope.select.acc_tag_price = stockUtils.to_decimal($scope.select.acc_tag_price);
	
	var e_pay = stockUtils.to_float($scope.select.e_pay); 
	var verificate = stockUtils.to_float($scope.select.verificate); 
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay
	    + e_pay - $scope.select.has_pay - $scope.select.verificate;

	$scope.select.left_balance = stockUtils.to_decimal($scope.select.left_balance);
    };
    
    $scope.change_firm = function(){
	$scope.select.surplus = parseFloat($scope.select.firm.balance);
	$scope.re_calculate();
    };

    $scope.get_prompt_firm = function(prompt){
	return stockUtils.get_prompt_firm(prompt, $scope.firms)};

    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    $scope.row_change_price = function(inv){
	stockUtils.calc_stock_orgprice_info(inv.tag_price, inv, 1);
	if (angular.isDefined(diablo_set_float(inv.org_price))){
	    $scope.re_calculate(); 
	}
    };

    $scope.row_change_ediscount = function(inv){
	stockUtils.calc_stock_orgprice_info(inv.tag_price, inv, 0);
	if (angular.isDefined(diablo_set_float(inv.ediscount))){
	    $scope.re_calculate();
	}
    };

    $scope.row_change_over = function(inv){
	// inv.over = stockUtils.to_integer(inv.over)
	$scope.re_calculate();
    };
    
    var in_sort = function(sorts, tag){
	for (var i=0, l=sorts.length; i<l;i ++){
	    if(tag.style_number === sorts[i].style_number && tag.brand_id === sorts[i].brand.id){
		if (!in_array(sorts[i].sizes, tag.size)){
		    sorts[i].sizes.push(tag.size)
		}

		var color = diablo_find_color(tag.color_id, filterColor);
		if (!diablo_in_colors(color, sorts[i].colors)){
		    sorts[i].colors.push(color)
		}; 
		
		sorts[i].amounts.push({cid:tag.color_id, size:tag.size, count:tag.amount}); 
		sorts[i].total += tag.amount;
		return true;
	    } 
	}

	return false;
    };
    
    // get rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    $q.all([
	promise(purchaserService.get_w_invnetory_new, rsn)(),
	promise(purchaserService.get_w_invnetory_new_amount, {rsn:rsn})()
    ]).then(function(result){
	// console.log(result);
	// result[0] is the record detail
	// result[1] are the inventory detail that the record is included
	// console.log(result[1]);
	var base = result[0];
	var invs = result[1].data;

	// console.log(base);
	if (base.state === diablo_stock_has_abandoned) {
	    diabloUtilsService.response_with_callback(
		false,
		"采购单修改",
		"采购单修改失败：" + purchaserService.error[2090],
		undefined,
		function(){$scope.go_back()})
	}

	$scope.old_select.rsn     = rsn;
	$scope.old_select.rsn_id  = base.id;
	
	// $scope.old_select.brand =
	//     $scope.get_object(base.brand_id, $scope.brands);
	$scope.old_select.firm  =
	    $scope.get_object(base.firm_id, $scope.firms);
	
	$scope.old_select.datetime = diablo_set_datetime(base.entry_date); 
	
	// $scope.old_select.surplus    = $scope.old_select.firm.balance;
	var select = stockUtils.get_login_employee(
	    base.shop_id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = select.login;
	$scope.employees = select.filter;
	
	$scope.old_select.shop =
	    $scope.get_object(base.shop_id, $scope.shops);
	$scope.old_select.employee =
	    $scope.get_object(base.employee_id, $scope.employees);
	
	$scope.old_select.surplus    = base.balance;
	$scope.old_select.comment    = base.comment;
	$scope.old_select.total      = base.total;
	$scope.old_select.cash       = base.cash;
	$scope.old_select.card       = base.card;
	$scope.old_select.wire       = base.wire;
	$scope.old_select.verificate = base.verificate;
	$scope.old_select.should_pay = base.should_pay;
	$scope.old_select.has_pay    = base.has_pay;
	$scope.old_select.state      = base.state;


	if (base.e_pay_type === -1){
	    $scope.old_select.e_pay_type = $scope.e_pay_types[0];
	    $scope.old_select.e_pay      = undefined;
	} else{
	    $scope.old_select.e_pay_type
		= diablo_get_object(base.e_pay_type, $scope.e_pay_types);
	    $scope.old_select.e_pay      = base.e_pay; 
	}
	
	$scope.select = angular.extend($scope.select, $scope.old_select);
	// console.log($scope.select);
	// base setting
	$scope.setting.history_stock =
	    stockUtils.history_stock(base.shop_id, $scope.ubase);
	$scope.setting.q_start_time =
	    stockUtils.start_time(base.shop_id, $scope.ubase, $.now(), dateFilter);
	
	var length = invs.length;
	var sorts  = [];
	for(var i = 0; i < length; i++){
	    if(!in_sort(sorts, invs[i])) {
		var add = {$edit:true, $new:false, sizes:[], colors:[], amounts:[]};
		
		add.style_number    = invs[i].style_number;
		add.brand_id        = invs[i].brand_id;
		add.brand = $scope.get_object(invs[i].brand_id, $scope.brands);
		add.type = $scope.get_object(invs[i].type_id, $scope.types);
		add.sex             = invs[i].sex,
		add.free            = invs[i].free,
		add.season          = invs[i].season;
		add.firm_id         = invs[i].firm_id;
		add.year            = invs[i].year;
		
		add.s_group         = invs[i].s_group;
		add.free_color_size = invs[i].free === 0 ? true : false;
		add.org_price       = invs[i].org_price;
		add.tag_price       = invs[i].tag_price;
		// add.ediscount       = invs[i].ediscount;
		add.ediscount       = diablo_discount(add.org_price, add.tag_price);
		add.discount        = invs[i].discount;
		add.total           = invs[i].amount;
		add.over            = invs[i].over;
		
		add.sizes.push(invs[i].size);
		add.colors.push(diablo_find_color(invs[i].color_id, filterColor));
		add.amounts.push({cid:invs[i].color_id, size:invs[i].size, count:invs[i].amount})
		sorts.push(add); 
	    } 
	};

	// console.log(sorts);
	$scope.old_inventories = sorts;
	
	var order_length = sorts.length;
	$scope.select.acc_tag_price = 0; 
	angular.forEach(sorts, function(s){
	    var tag = angular.copy(s);
	    tag.order_id = order_length;
	    if (tag.sizes.length !== 1 || tag.sizes[0] !=="0" ){
		tag.sizes = diabloHelp.usort_size_group(tag.s_group, filterSizeGroup); 
	    }
	    $scope.inventories.push(tag);
	    $scope.select.acc_tag_price += tag.tag_price * tag.total;
	    
	    order_length--;
	});

	$scope.select.acc_tag_price = stockUtils.to_decimal($scope.select.acc_tag_price);

	$scope.focus_row = sorts.length; 
	$scope.inventories.unshift({$edit:false, $new:true});
    });
    
    var reset_payment = function(newValue){
	// console.log("reset_payment", $scope.select);
	$scope.select.has_pay = 0.00;

	$scope.select.has_pay += stockUtils.to_float($scope.select.cash); 
	$scope.select.has_pay += stockUtils.to_float($scope.select.card);
	$scope.select.has_pay += stockUtils.to_float($scope.select.wire); 

	var verificate = stockUtils.to_float($scope.select.verificate);
	var e_pay = stockUtils.to_float($scope.select.e_pay); 
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay
	    + e_pay - $scope.select.has_pay - verificate;

	$scope.select.left_balance = stockUtils.to_decimal($scope.select.left_balance);
    };

    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cashForm.$invalid) return; 
	reset_payment(newValue); 
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cardForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.wire", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wireForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wireForm.$invalid) return; 
	reset_payment(newValue); 
    });

    $scope.$watch("select.e_pay", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.extraForm.$invalid) return;
	reset_payment(newValue);
    });
    
    $scope.match_prompt_good = function(viewValue){
	return diabloFilter.match_wgood_with_firm(
	    viewValue, stockUtils.match_firm($scope.select.firm)); 
    }; 
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);

	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false,
		    "采购单修改", "采购单修改失败："
			+ purchaserService.error[2099],
		    $scope, function(){
			$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }

	    if (item.firm_id === -1 || $scope.inventories[i].firm_id === -1) {
		continue;
	    }
	    
	    if (item.firm_id !== $scope.inventories[i].firm_id){
		diabloUtilsService.response_with_callback(
		    false,
		    "采购单修改",
		    "采购单修改失败：" + purchaserService.error[2093],
		    $scope, function(){
			$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}

	if (-1 !== item.firm_id){
	    $scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
	}

	// add at first allways 
	var add = $scope.inventories[0];
	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = $scope.get_object(item.brand_id, $scope.brands);
	add.type         = $scope.get_object(item.type_id, $scope.types);
	add.sex          = item.sex;
	add.year         = item.year;
	add.season       = item.season;
	add.firm_id      = item.firm_id;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.ediscount    = item.ediscount;
	add.discount     = item.discount;
	add.s_group      = item.s_group;
	add.free         = item.free;
	add.sizes        = item.size.split(",");
	add.colors       = item.color.split(",");
	add.over         = 0;
	
	if ( add.free === 0 ){
	    add.free_color_size = true;
	    add.amounts = [{cid:0, size:0}];
	} else{
	    add.free_color_size = false;
	    add.amounts = []; 
	}

	console.log(add);

	if (!add.free_color_size){
	    $scope.add_inventory(add)
	};
    };

    var get_update_amount = function(newAmounts, oldAmounts){
	var changedAmounts = [];
	var found = false;
	for (var i=0, l1=newAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=oldAmounts.length; j < l2; j++){
		if (newAmounts[i].cid === oldAmounts[j].cid
		    && newAmounts[i].size === oldAmounts[j].size){
		    // update
		    found = true;
		    
		    var update_count = parseInt(newAmounts[i].count)
			- parseInt(oldAmounts[j].count); 
		    if ( update_count !== 0 ){
			changedAmounts.push(
			    {operation: 'u',
			     cid:       newAmounts[i].cid,
			     size:      newAmounts[i].size,
			     count:     update_count})
		    }
		    
		    break;
		} 
	    }

	    // new
	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'a',
		     cid:       newAmounts[i].cid,
		     size:      newAmounts[i].size,
		     count:     parseInt(newAmounts[i].count)})
	    }
	}

	// delete
	for (var i=0, l1=oldAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=newAmounts.length; j < l2; j++){
		if (oldAmounts[i].cid === newAmounts[j].cid
		    && oldAmounts[i].size == newAmounts[j].size){
		    found = true;
		    break;
		} 
	    }

	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'd',
		     cid:       oldAmounts[i].cid,
		     size:      oldAmounts[i].size,
		     count:     parseInt(oldAmounts[i].count)})
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
		if (newInv.style_number === oldInv.style_number
		    && newInv.brand.id === oldInv.brand.id){
		    var change_amouts = get_update_amount(
			newInv.amounts, oldInv.amounts);
		    if (change_amouts.length !== 0){
			newInv.operation = 'u';
			// newInv.old_total = oldInv.total;
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			// console.log(newInv);
			// console.log(oldInv);
			if (stockUtils.to_float(newInv.org_price)
			    !== stockUtils.to_float(oldInv.org_price)
			    
			    || stockUtils.to_float(newInv.ediscount)
			    !== stockUtils.to_float(oldInv.ediscount)
			    
			    || stockUtils.to_integer(newInv.over)
			    !== stockUtils.to_integer(oldInv.over)

			    || stockUtils.to_float(newInv.tag_price)
			    !== stockUtils.to_float(oldInv.tag_price)
			    
			    || stockUtils.to_float(newInv.discount)
			    !== stockUtils.to_float(oldInv.discount)

			    || newInv.firm_id !== stockUtils.invalid_firm($scope.select.firm)
			   ){
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

    // save
    $scope.save_inventory = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories);

	if (angular.isUndefined($scope.select.shop)
	    || diablo_is_empty($scope.select.shop)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response_with_callback(
		false,
		"采购单修改",
		"采购单修改失败：" + purchaserService.error[2096],
		undefined, function(){$scope.has_saved = false });
	    return;
	};

	if ($scope.select.state === diablo_stock_has_abandoned) {
	    diabloUtilsService.response_with_callback(
		false,
		"采购单修改",
		"采购单修改失败：" + purchaserService.error[2090],
		undefined,
		function(){$scope.go_back()})
	    return;
	}

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
		// good           : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		// firm           : add.firm_id,
		firm           : stockUtils.invalid_firm($scope.select.firm),
		type           : add.type.id,
		sex            : add.sex,
		year           : add.year, 
		season         : add.season,
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			return add.amounts
		    }}(),
		s_group        : add.s_group,
		free           : add.free,
		org_price      : stockUtils.to_float(add.org_price),
		tag_price      : stockUtils.to_float(add.tag_price), 
		ediscount      : stockUtils.to_float(add.ediscount),
		discount       : stockUtils.to_float(add.discount),
		total          : stockUtils.to_integer(add.total),
		over           : stockUtils.to_integer(add.over)
	    })
	};
	
	if (added.length === 0
	    && (stockUtils.is_same($scope.select.cash, $scope.old_select.cash)
		&& stockUtils.is_same($scope.select.card, $scope.old_select.card)
		&& stockUtils.is_same($scope.select.wire, $scope.old_select.wire)
		&& stockUtils.is_same($scope.select.verificate, $scope.old_select.verificate)
		&& stockUtils.is_same($scope.select.e_pay, $scope.old_select.e_pay) 
		&& stockUtils.is_same(stockUtils.invalid_firm($scope.old_select.firm),
				      stockUtils.invalid_firm($scope.select.firm))
		&& stockUtils.is_same($scope.select.employee, $scope.old_select.employee)
		&& stockUtils.is_same($scope.select.shop.id, $scope.old_select.shop.id)
		&& stockUtils.is_same($scope.select.comment, $scope.old_select.comment)
		&& stockUtils.is_same($scope.select.datetime, $scope.old_select.datetime))){
	    diabloUtilsService.response_with_callback(
	    	false,
		"采购单编辑",
		"采购单编辑失败：" + purchaserService.error[2094],
		undefined, function(){$scope.has_saved = false});
	    return;
	}

	var setv = diablo_set_float;
	var base = {
	    id:             $scope.select.rsn_id,
	    mode:           diablo_stock_new,
	    rsn:            $scope.select.rsn,
	    firm:           stockUtils.invalid_firm($scope.select.firm),
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        diablo_set_string($scope.select.comment),
	    total:          diablo_set_integer($scope.select.total),
	    balance:        parseFloat($scope.select.surplus), 
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wire:           setv($scope.select.wire),
	    verificate:     setv($scope.select.verificate),
	    e_pay:          setv($scope.select.e_pay),
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        setv($scope.select.has_pay),
	    e_pay_type:     function(){
		if (stockUtils.to_float($scope.select.e_pay) === 0) return undefined;
		return $scope.select.e_pay_type.id; 
	    }(),
	    
	    old_firm:       stockUtils.invalid_firm($scope.old_select.firm), 
	    old_balance:    setv($scope.old_select.surplus),
	    old_verify_pay: setv($scope.old_select.verificate),
	    old_should_pay: setv($scope.old_select.should_pay),
	    old_has_pay:    setv($scope.old_select.has_pay),
	    old_epay:       setv($scope.old_select.e_pay),
	    old_datetime:   dateFilter($scope.old_select.datetime, "yyyy-MM-dd HH:mm:ss"),
	};

	console.log(added);
	console.log(base);

	purchaserService.update_w_inventory_new({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
		    true,
		    "采购单修改",
		    "采购单修改成功！！单号：" + state.rsn,
		    $scope, function(){
			diabloFilter.reset_firm();
			$scope.go_back();
		    })
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "采购单修改",
	    	    "采购单修改失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    };

    /*
     * add
     */
    var get_amount = function(cid, sname, amounts){
	var m = {cid:cid, size:sname};
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	
	amounts.push(m); return m;
    };

    var valid_amount = function(amounts){
	var unchanged = 0;
	for (var i=0, l=amounts.length; i<l; i++){
	    if(angular.isUndefined(amounts[i])
	       || angular.isUndefined(amounts[i].count)
	       || !amounts[i].count){
		unchanged++;
	    } 
	}

	// console.log(unchanged, l);
	// console.log(amounts);
	return unchanged === l ? false : true;
    };
    
    var add_callback = function(params){
	console.log(params);
	// delete empty
	var new_amount = [];
	for(var i=0, l=params.amount.length; i<l; i++){
	    var amount = params.amount[i]
	    if (angular.isDefined(amount)
		&& angular.isDefined(amount.count)
		&& amount.count){
		// console.log(amount);
		new_amount.push(amount);
	    } 
	}
	
	console.log(new_amount);
	// inv.amount = new_amount;
	var total = 0;
	angular.forEach(new_amount, function(a){
	    total += parseFloat(a.count);
	})

	return {amount:    new_amount,
		total:     total,
		org_price: params.org_price,
		ediscount: params.ediscount};
	// inv.total = total; 
	// reset(); 
    };
    
    $scope.add_inventory = function(inv){
	console.log(inv);
	// var add = $scope.inventories[0]; 

	var after_add = function(){
	    inv.$edit = true;
	    inv.$new = false;
	    // oreder 
	    inv.order_id = $scope.inventories.length; 
	    // add new line
	    $scope.inventories.unshift({$edit:false, $new:true});

	    // pagination
	    // $scope.total_items = $scope.inventories.length; 
	    // $scope.current_page_index = $scope.get_page($scope.current_page);
	    $scope.re_calculate(); 
	};
	
	var callback = function(params){
	    var result    = add_callback(params);
	    
	    inv.amounts   = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    inv.ediscount = result.ediscount;
	    after_add();
	} 
	
	if(inv.free_color_size){
	    inv.total = inv.amounts[0].count;
	    after_add();
	} else{
	    var payload = {sizes:        inv.sizes,
			   amount:       inv.amounts,
			   org_price:    inv.org_price,
			   ediscount:    inv.ediscount,
			   get_amount:   get_amount,
			   valid_amount: valid_amount};
	    
	    if (inv.colors.length === 1 && inv.colors[0] === "0"){
		inv.colors = [{cid:0}];
		payload.colors = inv.colors;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", undefined, callback, $scope, payload)
	    } else{
		inv.colors = inv.colors.map(function(cid){
		    if (angular.isObject(cid)) return cid;
		    return diablo_find_color(parseInt(cid), filterColor); 
		});
		
		payload.colors = inv.colors;
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", diablo_valid_dialog(inv.sizes),
		    callback, $scope, payload);
		// })
	    } 
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

	// pagination
	// $scope.total_items = $scope.inventories.length; 
	// $scope.current_page_index = $scope.get_page($scope.current_page);

	$scope.re_calculate(); 
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:      inv.sizes,
		       amount:     inv.amounts,
		       org_price:  inv.org_price,
		       ediscount:  inv.ediscount,
		       colors:     inv.colors,
		       get_amount: get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	inv.$update = true;
	inv.o_org_price = inv.org_price;
	inv.o_ediscount = inv.ediscount;
	if (inv.free_color_size){
	    inv.update_directory = true;
	    return; 
	}
	
	var callback = function(params){
	    var result    = add_callback(params);
	    inv.amounts   = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    inv.ediscount = result.ediscount;

	    // console.log(inv);
	    $scope.re_calculate(); 
	};

	diabloFilter.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result) {
	    if(result.ecode === 0 && !diablo_is_empty(result.data)) {
		inv.sizes  = result.data.size.split(","); 
		inv.colors = result.data.color.split(",").map(function(cid){
		    return diablo_find_color(stockUtils.to_integer(cid), filterColor);
		});

		var payload = {sizes:        inv.sizes,
			       amount:       inv.amounts,
			       org_price:    inv.org_price,
			       ediscount:    inv.ediscount,
			       colors:       inv.colors,
			       get_amount:   get_amount,
			       valid_amount: valid_amount};
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", undefined, callback, $scope, payload)
	    }
	}); 
    };

    $scope.save_free_update = function(inv){
	inv.$update = false;
	inv.update_directory = false;
	
	if (inv.free_color_size){
	    inv.total = inv.amounts[0].count;
	} //else{
	$scope.re_calculate()
	// }; 
    }

    $scope.cancel_free_update = function(inv){
	console.log(inv);
	inv.$update          = false; 
	inv.update_directory = false;
	inv.org_price        = inv.o_org_price;
	inv.ediscount        = inv.o_ediscount;
	inv.amounts[0].count  = inv.total; 
    };

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true}; 
    };

    $scope.disable_gen_barcode_all = false;
    $scope.p_barcode_all = function() {
	if ($scope.setting.barcode_firm
	    && diablo_invalid_firm === stockUtils.invalid_firm($scope.select.firm)) {
	    diabloUtilsService.response(
		false,
		dialog_barcode_title,
		dialog_barcode_title_failed + purchaserService.error[2086]);
	    return;
	}
	
	$scope.disable_gen_barcode_all = true;
	for (var i=1, l=$scope.inventories.length; i<l; i++) {
	    var one = $scope.inventories[i];
	    $scope.p_barcode(one);
	    // break;
	}
	$scope.disable_gen_barcode_all = false;
    };

    if ($scope.setting.use_barcode && needCLodop()) loadCLodop();
    
    var dialog_barcode_title = "库存条码打印";
    var dialog_barcode_title_failed = "库存条码打印失败：";
    $scope.p_barcode = function(inv) {
	console.log(inv);
	if ($scope.template.firm && diablo_invalid_firm === inv.firm_id ) {
	    dialog.response(
		false,
		dialog_barcode_title,
		dialog_barcode_title_failed + purchaserService.error[2086]);
	    return;
	} 
	
	var print_barcode = function(barcode) {
	    var firm = stockUtils.invalid_firm($scope.select.firm)
		=== diablo_invalid_firm ? undefined : $scope.select.firm.name; 
	    // $scope.printU.setCodeFirm($scope.select.firm.id);
	    
	    if (inv.free_color_size) {
		for (var i=0; i<inv.total; i++) {
		    $scope.printU.free_prepare(
			inv, 
			inv.brand.name,
			barcode,
			firm,
			$scope.select.firm.id); 
		}
	    } 
	    else {
		var barcodes = []; 
		angular.forEach(inv.amounts, function(a) {
		    
		    var color = diablo_find_color(a.cid, filterColor);
		    for (var i=0; i<a.count; i++) {
			var o = stockUtils.gen_barcode_content2(barcode, color, a.size);
			if (angular.isDefined(o) && angular.isObject(o)) {
			    barcodes.push(o); 
			}
		    } 
		});
		
		console.log(barcodes);
		angular.forEach(barcodes, function(b) {
		    $scope.printU.prepare(
			inv,
			inv.brand.name,
			b.barcode,
			firm,
			$scope.select.firm.id,
			b.cname,
			b.size); 
		})
	    }
	};

	// gen 
	purchaserService.gen_barcode(
	    inv.style_number, inv.brand_id, $scope.select.shop.id
	).then(function(result) {
	    if (result.ecode === 0) {
		print_barcode(result.barcode);
	    } else {
		dialog.response(
		    false,
		    dialog_barcode_title,
		    dialog_barcode_title_failed + purchaserService.error[result.ecode]);
	    }
	});
    };
    
};

define (["purchaserApp"], function(app){
    app.controller("purchaserInventoryNewUpdateCtrl", purchaserInventoryNewUpdateCtrlProvide); 
});
