'use strict'

function purchaserInventoryRejectCtrlProvide(
    $scope, $q, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloPromise, diabloFilter, purchaserService,
    user, filterFirm, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log($scope.disable_refresh);
    // console.log(user);

    // $scope.shops     = user.sortShops;
    $scope.response_title    = "采购退货"; 
    $scope.shops             = user.sortBadRepoes.concat(user.sortShops);
    // $scope.shops     = user.sortAvailabeShops;
    $scope.f_add             = diablo_float_add;
    $scope.f_sub             = diablo_float_sub;
    $scope.f_mul             = diablo_float_mul;
    $scope.calc_row          = stockUtils.calc_row;
    // $scope.calc_drate        = stockUtils.calc_drate_of_org_price;

    $scope.pattern           = {
	price:    diabloPattern.positive_decimal_2,
	discount: diabloPattern.discount,
	amount:   diabloPattern.positive_num
    };
    
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    $scope.firms             = filterFirm;
    // $scope.employees         = filterEmployee;
    $scope.extra_pay_types   = purchaserService.extra_pay_types;
    $scope.timeout_auto_save = undefined;
    // $scope.invalid_stock     = false;
    // $scope.round             = diablo_round;

    $scope.setting = {};
    $scope.get_setting = function(shop_id) {
	$scope.setting.reject_negative = stockUtils.reject_negative(shop_id, base); 
	$scope.setting.check_orgprice = stockUtils.stock_mode(diablo_default_shop, base).check_o_price;
	$scope.setting.check_firm = stockUtils.stock_mode(diablo_default_shop, base).check_o_firm;

	var scan_mode = stockUtils.scan_mode(shop_id, base);
	$scope.setting.scan_mode = stockUtils.to_integer(scan_mode.charAt(2));
	$scope.setting.fast_reject = stockUtils.to_integer(scan_mode.charAt(9));
	
	$scope.setting.auto_barcode = stockUtils.auto_barcode(diablo_default_shop, base); 
	// $scope.setting.type_sale = stockUtils.type_sale(shop_id, base);
	console.log($scope.setting);
	
    } 

    $scope.disable_refresh = true;

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_new_detail");
    };

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight();
    console.log($scope.stock_right);

    $scope.stock_reject = {barcode:undefined, style_number:undefined}; 
    $scope.focus = {barcode: false, style_number:false, reject: false};
    
    $scope.auto_focus = function(attr){
	console.log($scope.focus, attr);
	if (!$scope.focus[attr]){
	    $scope.focus[attr] = true;
	}
	for (var o in $scope.focus){
	    if (o !== attr) $scope.focus[o] = false;
	}
	console.log($scope.focus, attr);
    };

    $scope.focus_good_or_barcode = function() {
	if ($scope.setting.scan_mode)
	    $scope.auto_focus('barcode');
	else
	    $scope.auto_focus('style_number');
    };

    $scope.focus_by_element = function() {
	$scope.stock_reject.style_number = undefined;
	$scope.stock_reject.barcode = undefined;
	if ($scope.setting.scan_mode) {
	    document.getElementById("barcode").focus();
	} else {
	    document.getElementById("snumber").focus();
	} 
    };
    
    // init
    var now = $.now();
    var dialog = diabloUtilsService;
    
    $scope.has_saved    = false; 
    $scope.inventories = [];
    // $scope.inventories.push({$edit:false, $new:true}); 
    $scope.select = {
	shop: $scope.shops.length !== 0 ? $scope.shops[0]:undefined,
	firm: undefined,
	datetime:   now,
	total:      0,
	should_pay: 0,
	surplus:    0,
	left_balance: 0,
	extra_pay_type: $scope.extra_pay_types[0]
    };

    // setting
    $scope.get_setting($scope.select.shop.id);
    $scope.focus_good_or_barcode();
    
    $scope.get_employee = function(){
	var select = stockUtils.get_login_employee(
	    $scope.select.shop.id,
	    user.loginEmployee,
	    filterEmployee);
	
	$scope.select.employee = select.login;
	$scope.employees = select.filter; 
    }; 
    $scope.get_employee();

    $scope.get_prompt_firm = function(prompt){
	return stockUtils.get_prompt_firm(prompt, $scope.firms)}; 

    $scope.change_shop = function(){
	$scope.get_setting($scope.select.shop.id);
	$scope.get_employee();
    };

     $scope.change_firm = function(){
	 console.log($scope.select.firm);
	 $scope.select.surplus = 0;
	 $scope.select.left_balance = 0;
	 if (diablo_invalid_firm !== stockUtils.invalid_firm($scope.select.firm)){
	     $scope.select.surplus = stockUtils.to_float($scope.select.firm.balance);
	     $scope.select.left_balance = $scope.select.surplus; 
	 }
	 
	 $scope.re_calculate(); 
    };

    $scope.refresh = function(){
	$scope.inventories = [];
	// $scope.inventories.push({$edit:false, $new:true}); 
	$scope.select.firm = undefined;
	$scope.select.should_pay = 0;
	$scope.select.total      = 0;
	$scope.select.comment    = undefined;
	$scope.select.left_balance = 0;
	$scope.select.extra_pay    = undefined;
	$scope.select.surplus      = 0;

	$scope.disable_refresh   = true;
	$scope.has_saved         = false;

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

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0;
	
	for (var i=0, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    
	    $scope.select.total  += parseInt(one.reject); 
	    $scope.select.should_pay -= stockUtils.calc_row(one.org_price, 100, one.reject); 
	} 
	$scope.select.should_pay = stockUtils.to_decimal($scope.select.should_pay);

	var e_pay = stockUtils.to_float($scope.select.extra_pay); 
	$scope.select.left_balance = $scope.select.surplus + $scope.select.should_pay - e_pay;
	$scope.select.left_balance = stockUtils.to_decimal($scope.select.left_balance);
    };

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
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

    // $scope.qtime_start = function(shopId){
    // 	return stockUtils.start_time(shopId, base, now, dateFilter); 
    // }; 

    $scope.match_prompt_inventory = function(viewValue){
	return diabloFilter.match_w_reject_inventory(
	    viewValue, $scope.select.shop.id, stockUtils.invalid_firm($scope.select.firm)); 
    }; 

    $scope.on_select_inventory = function(item, model, label){
	console.log(item); 
	// has been added
	// var existStock = undefined;
	var invalid = false;
	if ($scope.setting.check_orgprice && 0 >= stockUtils.to_float(item.org_price)) {
	    dialog.set_error_with_callback($scope.response_title, 2088, $scope.focus_by_element);
	    invalid = true;
	}

	if (0 >= stockUtils.to_float(item.tag_price)) {
	    dialog.set_error_with_callback($scope.response_title, 2040, $scope.focus_by_element);
	    invalid = true;
	}
	
	if (item.firm_id !== diablo_invalid_firm) {
	    if (stockUtils.invalid_firm($scope.select.firm) === diablo_invalid_firm) {
		$scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
		$scope.change_firm();
	    }
	} else {
	    if ($scope.setting.check_firm === diablo_yes) {
		dialog.set_error_with_callback($scope.response_title, 2058, $scope.focus_by_element);
		invalid = true;
	    }
	} 

	if (!invalid) {
	    for(var i=0, l=$scope.inventories.length; i<l; i++){
		// if (item.style_number === $scope.inventories[i].style_number
		// 	&& item.brand_id  === $scope.inventories[i].brand_id){
		// 	existStock = $scope.inventories[i];
		// } 
		if (item.firm_id === diablo_invalid_firm && $scope.setting.check_firm === diablo_no) 
		    continue;
		
		if (item.firm_id !== $scope.inventories[i].firm_id){
		    // diabloUtilsService.response_with_callback(
		    //     false,
		    //     "采购退货",
		    //     "退货失败：" + purchaserService.error[2093],
		    //     undefined,
		    //     $scope.focus_by_element);
		    dialog.set_error_with_callback(
			$scope.response_title, 2093, $scope.focus_by_element);
		    invalid = true;
		    break;
		};
	    }
	}

	if (!invalid) {
	    if (diablo_invalid_firm === stockUtils.invalid_firm($scope.select.firm)
		&& $scope.setting.check_firm === diablo_yes){
		$scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
		$scope.change_firm();
	    };

	    var add = {$new:true};
	    add.id           = item.id;
	    add.bcode        = item.bcode;
	    add.full_bcode   = item.full_bcode; 
	    add.style_number = item.style_number;
	    add.brand        = item.brand;
	    add.brand_id     = item.brand_id;
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
	}
    };

    $scope.barcode_scanner = function(barcode) {
	diabloHelp.scanner(
	    barcode,
	    $scope.setting.auto_barcode,
	    $scope.select.shop.id,
	    diabloFilter.get_stock_by_barcode,
	    diabloUtilsService,
	    "采购退货",
	    $scope.on_select_inventory)
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved){
	    return true;
	}; 
	
	if ($scope.inventories.length === 0
	    && (angular.isUndefined($scope.select.extra_pay) || !$scope.select.extra_pay)){
	    return true;
	};

	return false;
    };

    $scope.index_of_reject = function(sale, exists) {
	var index = diablo_invalid_index;;
	for (var i=0, l=exists.length; i<l; i++) {
	    if (sale.style_number === exists[i].style_number && sale.brand_id === exists[i].brand) {
		index = i;
		break;
	    }
	} 
	return index;
    };

    $scope.index_of_reject_detail = function(existDetails, detail) {
	var index = diablo_invalid_index;
	for (var j=0, k=existDetails.length; j<k; j++) {
	    if (detail.cid === existDetails[j].cid && detail.size === existDetails[j].size) {
		index = j;
		break;
	    } 
	}

	return index;
    }; 

    var get_reject_detail = function(amounts){
	var reject_amounts = [];
	for(var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (stockUtils.to_integer(a.reject_count) !== 0){
		a.reject_count = stockUtils.to_integer((a.reject_count));
		reject_amounts.push({
		    cid   :a.cid,
		    size  :a.size,
		    count :stockUtils.to_integer((a.reject_count))
		}); 
	    }
	}

	return reject_amounts;
    };
    
    $scope.save_inventory = function(){
	if (diablo_yes === $scope.setting.check_firm
	    && diablo_invalid_firm === stockUtils.invalid_firm($scope.select.firm)){
	    diabloUtilsService.response(
		false,
		"库存退回",
		"库存退回失败：" + purchaserService.error[2091]);
	    return;
	}
	
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	// var get_reject = function(amounts){
	//     var reject_amounts = [];
	//     for(var i=0, l=amounts.length; i<l; i++){
	// 	if (angular.isDefined(amounts[i].reject_count) && amounts[i].reject_count){
	// 	    amounts[i].reject_count
	// 		= parseInt(amounts[i].reject_count);
	// 	    reject_amounts.push(amounts[i]); 
	// 	} 
	//     } 
	//     return reject_amounts;
	// };

	// check
	$scope.re_calculate();
	
	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string; 
	var added = [];
	
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    var index = $scope.index_of_reject(add, added)

	    if (diablo_invalid_index !== index) {
		var existReject = added[index];
		existReject.total += stockUtils.to_integer(add.reject); 
		var details1 = get_reject_detail(add.amounts);
		var existDetails = existReject.amounts;
		console.log(details1); 
		console.log(existDetails);
		angular.forEach(details1, function(d) {
		    var indexDetail = $scope.index_of_reject_detail(existDetails, d);
		    if (diablo_invalid_index !== indexDetail) {
			existDetails[indexDetail].count += d.count;
		    } else {
			existDetails.push(d);
		    } 
		})
	    } else {
		added.push({
		    // style_number: add.style_number,
		    order_id    : add.order_id,
		    style_number: add.style_number,
		    brand       : add.brand_id,
		    firm        : add.firm_id,
		    type        : add.type_id,
		    sex         : add.sex,
		    year        : add.year,
		    season      : add.season,
		    amounts     : get_reject_detail(add.amounts),
		    s_group     : add.s_group,
		    free        : add.free,

		    org_price   : add.org_price,
		    tag_price   : add.tag_price, 
		    ediscount   : add.ediscount,
		    discount    : add.discount,
		    
		    path        : add.path, 
		    total       : seti(add.reject),
		    alarm_day   : add.alarm_day,
		})
	    }
	    
	    // if (angular.isUndefined(add.style_number)){
	    // 	diabloUtilsService.response(
	    // 	    false,
	    // 	    "库存退回",
	    // 	    "库存退回失败：[" 
	    // 		+ add.order_id + "]：" + purchaserService.error[2092]
	    // 	    	+ "款号：" + add.style_number + "！！", 
	    // 	    undefined);
	    // 	return;
	    // };
	    
	    
	};
	
	var e_pay = setv($scope.select.extra_pay); 
	var base = {
	    firm:          stockUtils.invalid_firm($scope.select.firm),
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter(
		$scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       sets($scope.select.comment),
	    balance:       setv($scope.select.surplus),
	    should_pay:    setv($scope.select.should_pay),
	    total:         seti($scope.select.total),

	    e_pay_type:    angular.isUndefined(e_pay)
		? undefined : $scope.select.extra_pay_type.id,
	    e_pay:         e_pay
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true
	purchaserService.reject_purchaser_inventory({
	    inventory: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		// diabloFilter.reset_firm(); 
		// $scope.disable_refresh     = false;
		// if (stockUtils.invalid_firm($scope.select.firm) !== diablo_invalid_firm
		//     && $scope.setting.check_firm === diablo_yes) {
		//     $scope.select.firm.balance = $scope.select.left_balance;
		//     $scope.select.surplus = $scope.select.firm.balance;
		// }
		// $scope.refresh();
	    	diabloUtilsService.response_with_callback(
		    true,
		    "采购退货",
		    "退货成功！！退货单号：" + state.rsn,
		    undefined,
		    $scope.refresh)
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false,
		    "采购退货",
	    	    "退货失败："
			+ purchaserService.error[state.ecode]
			+ stockUtils.extra_error(state), 
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	})
    };

    /*
     * add
     */

    var free_stock_not_enought = function(stock) {
	var existTransferStock = 0;
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var s = $scope.inventories[i];
	    if (!s.free_update
		&& stock.style_number === s.style_number && stock.brand_id === s.brand_id){
		existTransferStock += s.reject;
	    }
	} 
	return existTransferStock + stock.reject > stock.total;
    };
    
    var cs_stock_not_enought = function(stock) {
	var not_enought = false;
	var existStocks = [];
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var s = $scope.inventories[i];
	    if (stock.style_number === s.style_number && stock.brand_id === s.brand_id){
		existStocks.push(s); 
	    }
	}


	var willAmounts = stock.amounts.filter(function(a) {
	    return stockUtils.to_integer(a.reject_count) > 0;
	}).map(function(m) {
	    return {cid:m.cid, size:m.size, reject_count:m.reject_count, count:m.count}
	});
	
	angular.forEach(existStocks, function(e) {
	    var existAmounts = e.amounts;
	    for (var j=0, k=willAmounts.length; j<k; j++) {
		for (var m=0, n=existAmounts.length; m<n; m++) {
		    if (existAmounts[m].reject_count > 0) {
			if (existAmounts[m].cid === willAmounts[j].cid
			    && existAmounts[m].size === willAmounts[j].size) {
			    willAmounts[j].reject_count += existAmounts[m].reject_count;
			    if (willAmounts[j].reject_count > willAmounts[j].count) {
				not_enought = true;
				break;
			    }
			}
			
		    }
		    
		}
	    }
	});

	console.log(willAmounts);	
	return not_enought;
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    $scope.valid_free_size_reject = function(inv){
	inv.invalid_reject = false;
    	if (angular.isDefined(inv.amounts)
    	    && angular.isDefined(inv.amounts[0].reject_count) 
    	    && !$scope.setting.reject_negative
	    && parseInt(inv.amounts[0].reject_count) > inv.total){
	    inv.invalid_reject = true;
    	    // return false;
    	}
    	return !inv.invalid_reject;
    };
    
    var valid_all = function(amounts){
	var unchanged = 0;
	// var invalid = true;
	for(var i=0, l=amounts.length; i<l; i++){
	    var amount = amounts[i];
	    if (angular.isUndefined(amount.reject_count) || !amount.reject_count){
		unchanged++;
	    } else {
		if ( !$scope.setting.reject_negative
		     && stockUtils.to_integer(amount.reject_count)>amount.count){
		    return false;
		}
	    }
	}
	
	return unchanged == l ? false : true;
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	if (!$scope.setting.reject_negative && free_stock_not_enought(inv)) {
	    dialog.set_error_with_callback($scope.response_title, 2070, $scope.focus_by_element);
	} else {
	    inv.$edit = true;
	    inv.$new = false;
	    inv.amounts[0].reject_count = inv.reject;
	    $scope.inventories.unshift(inv);
	    inv.order_id = $scope.inventories.length;
	    $scope.re_calculate();
	    $scope.focus_by_element();
	}
	
	// inv.reject = inv.amounts[0].reject_count;
	// oreder
	// inv.order_id = $scope.inventories.length; 
	// add new line
	// $scope.inventories.unshift({$edit:false, $new:true});
	
	// $scope.re_calculate(); 
	// auto_focus
	// $scope.auto_focus("style_number");
	// $scope.focus_good_or_barcode();
    };

    var add_callback = function(params){
	console.log(params.amounts); 
	var reject_total = 0, note = "";
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.reject_count) && a.reject_count){
		reject_total += parseInt(a.reject_count);
		note += diablo_find_color(a.cid, filterColor).cname + a.size;
		if (a.reject_total > 1)
		    note += diablo_dash_seperator + reject_total.toString();
		note += diablo_semi_seperator;
	    }
	})

	return {amounts:   params.amounts,
		reject:    reject_total,
		org_price: params.org_price,
		ediscount: params.ediscount,
		note: note};
    };
    
    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number,
	     brand:       inv.brand_id,
	     shop:        $scope.select.shop.id,
	     qtype:       diablo_badrepo}
	).then(function(invs){
	    console.log(invs);
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(invs, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort; 
	    
	    var after_add = function(enought_check){
		if (enought_check && cs_stock_not_enought(inv)) {
		    dialog.set_error_with_callback(
			$scope.response_title, 2070, $scope.focus_by_element);
		} else {
		    inv.$edit = true;
		    inv.$new  = false;
		    $scope.inventories.unshift(inv);
		    inv.order_id = $scope.inventories.length;

		    $scope.disable_refresh   = false;
		    $scope.re_calculate();

		    $scope.focus_by_element();
		} 
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.org_price;
		inv.ediscount = result.ediscount;
		inv.note      = result.note;
		after_add(true);
	    };

	    var start_reject = function() {
		var payload = {sizes:          inv.sizes,
			       colors:         inv.colors,
			       tag_price:      inv.tag_price,
			       org_price:      inv.org_price,
			       ediscount:      inv.ediscount,
			       amounts:        inv.amounts,
			       get_amount:     get_amount,
			       valid:          valid_all,
			       check_orgprice: $scope.setting.check_orgprice,
			       get_price_info: stockUtils.calc_stock_orgprice_info};
		
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html",
		    'normal',
		    callback,
		    $scope,
		    payload);
	    };

	    if (inv.free === 0){
		inv.free_color_size = true;
		inv.amounts = [{cid:0, size:0}];
		inv.reject  = 1;
		$scope.auto_save_free(inv);
		if ($scope.setting.fast_reject) {
		    $scope.focus_by_element();
		} else {
		    $scope.auto_focus("reject");
		    $scope.update_inventory(inv);
		}
	    } else{
		inv.free_color_size = false;

		if ($scope.setting.scan_mode && angular.isDefined(inv.full_bcode)) {
		    var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
		    console.log(color_size);

		    var bcode_color = stockUtils.to_integer(color_size.substr(0, 3));
		    var bcode_size_index = stockUtils.to_integer(color_size.substr(3, color_size.length));
		    
		    var bcode_size = bcode_size_index === 0 ? diablo_free_size:size_to_barcode[bcode_size_index];
		    // console.log(bcode_color);
		    // console.log(bcode_size);
		    
		    angular.forEach(inv.amounts, function(a) {
			// console.log(a.cid, inv.colors);
			a.focus = false;
			var color;
			for (var i=0, l=inv.colors.length; i<l; i++) {
			    if (a.cid === inv.colors[i].cid) {
				color = inv.colors[i];
				break;
			    }
			}
			
			// console.log(color); 
			if (angular.isDefined(color) && color.bcode === bcode_color && a.size === bcode_size) {
			    a.reject_count = 1; 
			    a.focus = true;
			}
		    });

		    if ($scope.setting.fast_reject) {
			if (!$scope.setting.reject_negative && cs_stock_not_enought(inv)) {
			    dialog.set_error($scope.response_title, 2070);
			} else {
			    var result = add_callback({amounts:inv.amounts});
			    console.log(result);
			    inv.amounts   = result.amounts;
			    inv.reject    = result.reject;
			    // fast mode can not change org_price and xdiscount of stock 
			    // inv.org_price = result.org_price;
			    // inv.xdiscount = stockUtils.to_integer(result.xdiscount);
			    inv.note      = result.note;
			    after_add(false); 
			} 
		    } else {
			start_reject();
		    } 
		} else {
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			var a = inv.amounts[i];
			a.focus = false;
			if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
			    a.focus = true;
			}
		    }
		    
		    start_reject();
		}
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
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		// $scope.inventories.splice(i, 1)
		// deleteIndex = i;
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	$scope.re_calculate();
	$scope.focus_by_element();
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       org_price:    inv.org_price,
		       ediscount:    inv.ediscount,
		       amounts:      inv.amounts,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv, updateCallback){
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_org_price = inv.org_price;
	    inv.o_ediscount = inv.ediscount;
	    $scope.auto_focus("reject");
	    return;
	}
	
	var callback = function(params){
	    inv.amounts = params.amounts;
	    inv.reject  = 0;
	    angular.forEach(params.amounts, function(a){
		if (angular.isDefined(a.reject_count) && a.reject_count){
		    inv.reject += parseInt(a.reject_count);
		}
	    });

	    inv.org_price = params.org_price;
	    inv.ediscount = params.ediscount;
	    
	    $scope.re_calculate();

	    if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
		updateCallback();
	};

	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       tag_price:    inv.tag_price,
		       org_price:    inv.org_price,
		       ediscount:    inv.ediscount,
		       amounts:      inv.amounts,
		       get_amount:   get_amount,
		       // valid_reject: valid_reject,
		       valid:        valid_all,
		       get_price_info: stockUtils.calc_stock_orgprice_info}; 
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html",
	    inv.sizes.length >= 6 ? "lg" : undefined,
	    callback,
	    undefined,
	    payload)
    };

    $scope.save_free_update = function(inv){
	if (!$scope.setting.reject_negative && free_stock_not_enought(inv)) {
	    dialog.set_error_with_callback($scope.response_title, 2070, $scope.focus_by_element);
	} else {
	    inv.free_update = false;
	    inv.amounts[0].reject_count = inv.reject;
	    $scope.re_calculate();
	    $scope.focus_by_element();
	}
	
	// $timeout.cancel($scope.timeout_auto_save); 
	// inv.free_update = false;
	// // inv.reject  = inv.amounts[0].reject_count;
	// $scope.re_calculate();

	// // reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	// $scope.focus_good_or_barcode();
    }

    $scope.cancel_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	// inv.amounts[0].reject_count = inv.reject;
	inv.reject = inv.amounts[0].reject_count;
	inv.org_price   = inv.o_org_price;
	inv.ediscount   = inv.o_ediscount;
    } 
    
    // $scope.reset_inventory = function(inv){
    // 	// inv.$reset = true;
    // 	// $timeout.cancel($scope.timeout_auto_save);
    // 	$scope.inventories[0] = {$edit:false, $new:true};;
    // }


    $scope.check_free_stock = function(inv) {
	var reject = stockUtils.to_integer(inv.reject);
	inv.invalid_reject = false;
	
	if (!inv.$new && inv.free_update){
	    if (reject > inv.total){
		if (angular.isDefined(inv.form.reject)) {
		    inv.form.reject.$invalid = true;
		    inv.form.reject.$pristine = false; 
		}
		inv.invalid_reject = true; 
	    } 
	}

	return !inv.invalid_reject;
    }
    
    $scope.auto_save_free = function(inv){
	// console.log(inv);
	var reject = stockUtils.to_integer(inv.reject); 
	if (angular.isDefined(inv.style_number) && reject > 0) {
	    if ($scope.check_free_stock(inv)) {
		if (inv.$new && inv.free_color_size) {
		    $scope.add_free_inventory(inv);
		}
		
		if (!inv.$new && inv.free_update) {
		    $scope.save_free_update(inv)
		}
	    } 
	} 
    };
    
};

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryRejectCtrl", purchaserInventoryRejectCtrlProvide);
});
