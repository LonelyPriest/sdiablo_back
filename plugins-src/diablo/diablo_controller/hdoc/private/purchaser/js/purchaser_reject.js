'use strict'

function purchaserInventoryRejectCtrlProvide(
    $scope, $q, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloPromise, diabloFilter, purchaserService,
    user, filterFirm, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log($scope.disable_refresh);
    // console.log(user);

    // $scope.shops     = user.sortShops;
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
	$scope.setting.scan_mode = stockUtils.to_integer(stockUtils.scan_mode(shop_id, base).charAt(2));
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
    
    // init
    var now = $.now(); 
    $scope.has_saved    = false; 
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    
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
	$scope.get_setting();
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
	$scope.inventories.push({$edit:false, $new:true});

	$scope.select.firm = undefined;
	$scope.select.should_pay = 0;
	$scope.select.total      = 0;
	$scope.select.comment    = undefined;
	$scope.select.left_balance = 0;
	$scope.select.extra_pay    = undefined;

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
	
	for (var i=1, l=$scope.inventories.length; i<l; i++){
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
	var existStock = undefined;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
	    	&& item.brand_id  === $scope.inventories[i].brand_id){
	    	// diabloUtilsService.response_with_callback(
	    	//     false, "退货", "退货失败：" + purchaserService.error[2099],
	    	//     $scope, function(){$scope.inventories[0] = {$edit:false, $new:true}});
	    	// return;
		existStock = $scope.inventories[i];
	    }

	    if (item.firm_id === diablo_invalid_firm && $scope.setting.check_firm === diablo_no) {
		continue;
	    }
	    
	    if (item.firm_id !== $scope.inventories[i].firm_id){
		diabloUtilsService.response_with_callback(
		    false, "采购退货", "退货失败：" + purchaserService.error[2093],
		    $scope, function(){$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    };
	}

	if (diablo_invalid_firm === stockUtils.invalid_firm($scope.select.firm)
	    && $scope.setting.check_firm === diablo_yes){
	    $scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
	    $scope.change_firm();
	};

	if (angular.isDefined(existStock)) {
	    $scope.update_inventory(
		existStock, function() {$scope.inventories[0] = {$edit:false, $new:true}})
	} else {
	    // add at first allways 
	    var add = $scope.inventories[0];
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
	
	if ($scope.inventories.length === 1
	    && (angular.isUndefined($scope.select.extra_pay)
		|| !$scope.select.extra_pay)){
	    return true;
	};

	return false;
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
	
	var get_reject = function(amounts){
	    var reject_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].reject_count)
		    && amounts[i].reject_count){
		    amounts[i].reject_count
			= parseInt(amounts[i].reject_count);
		    reject_amounts.push(amounts[i]); 
		} 
	    } 
	    return reject_amounts;
	};

	// check
	$scope.re_calculate();
	
	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;

	var added = []; 
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    
	    if (angular.isUndefined(add.style_number)){
		diabloUtilsService.response(
		    false,
		    "库存退回",
		    "库存退回失败：[" 
			+ add.order_id + "]：" + purchaserService.error[2092]
		    	+ "款号：" + add.style_number + "！！", 
		    undefined);
		return;
	    };
	    
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
		amounts     : get_reject(add.amounts), 
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
		$scope.disable_refresh     = false;
		if (stockUtils.invalid_firm($scope.select.firm) !== diablo_invalid_firm
		    && $scope.setting.check_firm === diablo_yes) {
		    $scope.select.firm.balance = $scope.select.left_balance;
		    $scope.select.surplus = $scope.select.firm.balance;
		} 
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
    	    && !$scope.setting.reject_negative
	    && parseInt(inv.amounts[0].reject_count) > inv.total){
    	    return false;
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
		if ( !$scope.setting.reject_negative
		     && stockUtils.to_integer(amount.reject_count)>amount.count){
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
	// auto_focus
	// $scope.auto_focus("style_number");
	$scope.focus_good_or_barcode();
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

	    var add_callback = function(params){
		console.log(params.amounts);
		
		var reject_total = 0;
		angular.forEach(params.amounts, function(a){
		    if (angular.isDefined(a.reject_count) && a.reject_count){
			reject_total += parseInt(a.reject_count);
		    }
		})

		return {amounts:   params.amounts,
			reject:    reject_total,
			org_price: params.org_price,
		        ediscount: params.ediscount};
	    };

	    var after_add = function(){
		inv.$edit = true;
		inv.$new  = false;
		// order
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});

		$scope.disable_refresh   = false;
		$scope.re_calculate();

		// auto focus
		// $scope.auto_focus("style_number");
		$scope.focus_good_or_barcode();
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.org_price;
		inv.ediscount = result.ediscount;
		after_add();
	    };

	    if (inv.free === 0){
		inv.free_color_size = true;
		$scope.auto_focus("reject");
	    } else{
		inv.free_color_size = false;
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
		    'normal', callback, $scope, payload); 
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
	$timeout.cancel($scope.timeout_auto_save); 
	inv.free_update = false;
	inv.reject      = inv.amounts[0].reject_count;
	$scope.re_calculate();

	// reset
	$scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode();
    }

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.amounts[0].reject_count = inv.reject;
	inv.org_price   = inv.o_org_price;
	inv.ediscount   = inv.o_ediscount;
    } 
    
    $scope.reset_inventory = function(inv){
	// inv.$reset = true;
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    }


    var timeout_auto_save = undefined;
    $scope.auto_save_free = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	// $scope.invalid_stock = false;
	if (0 === stockUtils.to_integer(inv.amounts[0].reject_count))
	    return;

	if (!diablo_set_string(inv.style_number)) {
	    diabloUtilsService.response(
	    	false,
	    	"采购退货",
	    	"采购退货失败：款号为空，请重新操作！！");
	    return;
	}
	    
	    
	if ( (0 === stockUtils.to_float(inv.org_price) && $scope.setting.check_orgprice)
	     || 0 == stockUtils.to_float(inv.tag_price) ){
	    diabloUtilsService.response(
	    	false,
	    	"采购退货",
	    	"采购退货失败：该款号无进货价或吊牌价！！");
	    return;
	}

	if (!$scope.setting.reject_negative
	    && parseInt(inv.amounts[0].reject_count) > inv.total){
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

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryRejectCtrl", purchaserInventoryRejectCtrlProvide);
});
