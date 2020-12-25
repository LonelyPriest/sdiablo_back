function wsaleOrderUpdateCtrlProvide(
    $scope, $q, $timeout, $interval, $routeParams, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wsaleService,
    user, filterPromotion, filterScore, filterSysRetailer, filterEmployee,
    filterSizeGroup, filterType, filterColor, filterLevel, base){
    // console.log($routeParams);
    $scope.rsn = $routeParams.rsn; 
    $scope.shops     = user.sortShops.filter(function(s) {return s.deleted===0});
    $scope.promotions = filterPromotion;
    $scope.scores     = filterScore;
    
    $scope.pattern    = {
	money:        diabloPattern.decimal_2,
	sell:         diabloPattern.integer_except_zero,
	discount:     diabloPattern.discount,
	barcode:      diabloPattern.number,
	name:         diabloPattern.chinese_name,
	comment:      diabloPattern.comment,
	tel_mobile:   diabloPattern.tel_mobile
    };

    var response_title = "销售订单编辑";
    var dialog = diabloUtilsService;
    
    var authen = new diabloAuthen(user.type, user.right, user.shop); 
    $scope.right = authen.authenSaleRight();

    $scope.color_negative_order = function(negative) {
    	return negative ? "bg-red" : "";
    };
    
    $scope.focus_attr = {style_number:false, barcode:false};
    $scope.auto_focus = function(attr){
	for (var o in $scope.focus_attr){
	    $scope.focus_attr[o] = false;
	}
	$scope.focus_attr[attr] = true; 
    };
    
    $scope.focus_good_or_barcode = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.scan_only) {
	    $scope.auto_focus('barcode');
	} else {
	    if ($scope.setting.barcode_mode && !$scope.setting.focus_style_number) {
		$scope.auto_focus('barcode'); 
	    } else {
		$scope.auto_focus('style_number');
	    }
	} 
    };

    $scope.focus_by_element = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.scan_only) {
	    document.getElementById("barcode").focus();
	} else {
	    if ($scope.setting.barcode_mode && !$scope.setting.focus_style_number) {
		document.getElementById("barcode").focus();
	    }
	    else {
		document.getElementById("snumber").focus();
	    }
	} 
    };

    $scope.match_style_number = function(viewValue){
	if (diablo_yes === $scope.setting.type_sale) {
	    return diabloFilter.match_w_sale(
		viewValue,
		$scope.select.shop.id,
		diablo_type_sale,
		diablo_is_ascii_string(viewValue));
	} else {
	    if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return; 
	    
	    return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
	} 
    };

    $scope.match_retailer_phone = function(viewValue){
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.select.shop.id,
	    $scope.setting.solo_retailer);
    };

    $scope.copy_select = function(add, src){
	console.log(src);
	// add.id           = src.id;
	add.bcode        = src.bcode;
	add.full_bcode   = src.full_bcode;
	add.style_number = src.style_number;
	
	add.brand_id     = src.brand_id;
	add.brand        = src.brand;
	
	add.type_id      = src.type_id;
	add.type         = src.type;
	
	add.firm_id      = src.firm_id; 
	
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;
	
	add.pid          = src.pid;
	add.promotion    = diablo_get_object(src.pid, $scope.promotions);
	add.sid          = src.sid;
	add.score        = diablo_get_object(src.sid, $scope.scores);
	add.mid          = src.mid;
	// add.commision    = diablo_get_object(src.mid, $scope.commisions);
	
	add.org_price    = src.org_price;
	add.ediscount    = src.ediscount;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;
	add.vir_price    = src.vir_price;
	add.draw         = src.draw;
	
	add.path         = src.path; 
	add.s_group      = src.s_group;
	add.free         = src.free;
	
	add.state        = src.state;
	add.bargin_price = wsaleUtils.to_integer(src.state.charAt(0)); 
	add.gift         = wsaleUtils.to_integer(src.state.charAt(1));	
	add.entry        = src.entry_date;

	add.o_finish     = 0;

	add.full_name    = add.style_number + "/" + add.brand + "/" + add.type; 
	return add; 
    };

    var fail_response = function(code, callback){
	diabloUtilsService.response_with_callback(
	    false,
	    "销售订单编辑",
	    "销售订单编辑失败：" + wsaleService.error[code],
	    undefined,
	    callback);
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item); 

	var ok_select = true;
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		ok_select =false;
		break;
	    };
	};

	if (!ok_select) {
	    diabloUtilsService.response_with_callback(
		false,
		"销售定单单编辑",
		"销售定单单编辑失败：" + wsaleService.error[2191],
		undefined, function(){})
	} else {
	    var add  = {$new:true}; 
	    $scope.copy_select(add, item);
	    console.log(add);
	    $scope.add_inventory(add);
	    $scope.auto_focus("sell"); 
	} 
    };

    $scope.barcode_scanner = function(full_bcode) {
	// console.log($scope.inventories);
    	console.log(full_bcode);
	if (angular.isUndefined(full_bcode) || !diablo_trim(full_bcode))
	    return;
	
	// get stock by barcode
	// stock info 
	var barcode = diabloHelp.correct_barcode(full_bcode, $scope.setting.barcode_auto); 
	console.log(barcode);

	// invalid barcode
	if (!barcode.cuted || !barcode.correct) {
	    dialog.set_error(response_title, 2196);
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(barcode.cuted, $scope.select.shop.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.set_error(response_title, 2195);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.set_error(response_title, result.ecode);
	    }
	});
	
    };

    $scope.disable_save = function(){
	// save one time only
	return $scope.has_saved || $scope.inventories.length === 0 ? true :false; 
    };

    $scope.re_calculate = function(){
	$scope.select.total        = 0; 
	// $scope.select.abs_total    = 0;
	$scope.select.abs_pay      = 0;
	$scope.select.should_pay   = 0;
	$scope.select.base_pay     = 0;
	
	var calc = wsaleCalc.calculate(
	    true,
	    $scope.setting.vip_mode,
	    wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels),
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_sale,
	    0,
	    $scope.setting.round,
	    0);
	
	// console.log(calc);
	// console.log($scope.show_promotions);
	$scope.select.total      = calc.total;
	// $scope.select.abs_total  = calc.abs_total;
	$scope.select.abs_pay    = calc.abs_pay;
	$scope.select.should_pay = calc.should_pay;
	$scope.select.base_pay   = calc.base_pay; 
    }; 
    
    // init
    $scope.disable_start_sale = function() {
	return $scope.inventories.length === 0;
    };

    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.retailer_types  = diablo_retailer_types.filter(function(t) {return t.id !== 2;});

    $scope.sale = {barcode:undefined, style_number:undefined};
    $scope.inventories = [];
    $scope.setting = {};
    $scope.face = window.face;
    $scope.show_promotions = [];
    $scope.disable_refresh = true; 
    
    var get_setting = function(shopId){
	$scope.setting.q_backend     = wsaleUtils.typeahead(shopId, base);
	$scope.setting.round         = wsaleUtils.round(shopId, base);
	$scope.setting.solo_retailer = wsaleUtils.solo_retailer(shopId, base);
	$scope.setting.semployee     = wsaleUtils.s_employee(shopId, base);
	$scope.setting.barcode_mode  = wsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = wsaleUtils.barcode_auto(shopId, base);
	
	$scope.setting.vip_mode      = wsaleUtils.vip_mode(shopId, base);
	$scope.setting.vip_discount_mode = wsaleUtils.to_integer($scope.setting.vip_mode.charAt(0));

	var scan_mode = wsaleUtils.scan_only(shopId, base);
	$scope.setting.scan_only     = wsaleUtils.to_integer(scan_mode.charAt(0));
	$scope.setting.focus_style_number = wsaleUtils.to_integer(scan_mode.charAt(4));

	var sale_mode = wsaleUtils.sale_mode(shopId, base);
	$scope.setting.hide_pwd       = wsaleUtils.to_integer(sale_mode.charAt(9));
	
	$scope.setting.type_sale     = wsaleUtils.type_sale(shopId, base); 
	$scope.setting.shop_mode  = wsaleUtils.shop_mode(shopId, base);
	$scope.retailer_levels    = $scope.face($scope.setting.shop_mode).retailer_levels; 
	console.log($scope.setting);
	
	$scope.levels = filterLevel.filter(function(l) {
	    return l.shop_id === shopId;
	})

	if ($scope.levels.length === 0) {
	    $scope.levels = filterLevel.filter(function(l) {
		return l.shop_id === user.loginShop;
	    })
	} 
    };

    var valid_all_sell = function(amounts){
	// var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;
	var valid = true;
	for(var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (wsaleUtils.to_integer(a.cs_finish) > wsaleUtils.to_integer(a.sell_count)) {
		valid = false;
		break;
	    }
	    
	    if (0 === wsaleUtils.to_integer(a.sell_count)){
		unchanged++;
	    } 
	};
	if (valid) 
	    return unchanged === l ? false : true;
	return valid; 
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    var add_callback = function(params){
	console.log(params.amounts); 
	var sell_total = 0, note = "";
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += wsaleUtils.to_integer(a.sell_count);
		note += diablo_find_color(a.cid, filterColor).cname + a.size + ";"
	    }
	}); 

	return {amounts:     params.amounts,
		sell:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,
		note:        note};
    };

    $scope.add_free_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer) || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, response_title,  response_title + "失败：" + wsaleService.error[2192]);
	    return; 
	};

	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.sell;
	$scope.inventories.unshift(inv);
	inv.order_id = $scope.inventories.length; 
	$scope.disable_refresh = false;
	$scope.re_calculate();	    
	$scope.focus_good_or_barcode(); 
    };

    $scope.add_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer) || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
	    	false, response_title, response_title + "失败：" + wsaleService.error[2192]);
	    return;
	};
	
	inv.fdiscount = inv.discount;
	inv.fprice    = diablo_price(inv.tag_price, inv.discount); 
	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	var promise = diabloPromise.promise; 
	var calls = [promise(diabloFilter.list_purchaser_inventory,
			     {style_number: inv.style_number,
			      brand:        inv.brand_id,
			      shop:         $scope.select.shop.id
			     })()];
	
	$q.all(calls).then(function(data){
	    if (data.length === 0 ){
		diabloUtilsService.response(
		    false, response_title, response_title + "失败：" + wsaleService.error[2194]);
		return; 
	    };
	    
	    var shop_now_inv = data[0]; 
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(shop_now_inv, order_sizes, filterColor);
	    
	    inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color;
	    inv.amounts = sort.sort; 

	    // console.log(inv.sizes);
	    // console.log(inv.colors);
	    // console.log(inv.amounts); 

	    if(inv.free === 0){
		$scope.auto_focus("sell");
		inv.free_color_size = true;
		inv.amounts = [{cid:0, size:0, count:inv.total}];
		inv.sell = 1; 
		$scope.auto_save_free(inv);
	    } else{
		var after_add = function(){
		    inv.$edit = true;
		    inv.$new = false;
		    $scope.disable_refresh = false;
		    $scope.inventories.unshift(inv); 
		    inv.order_id = $scope.inventories.length;
		    $scope.re_calculate();
		    $scope.focus_good_or_barcode();
		};

		var callback = function(params){
		    console.log(params);
		    var result  = add_callback(params);
		    // console.log(result);
		    if (inv.fprice !== result.fprice || inv.fdiscount !== result.fdiscount) {
			inv.$update = true;
		    }
		    inv.amounts    = result.amounts;
		    inv.sell       = result.sell;
		    inv.fdiscount  = result.fdiscount;
		    inv.fprice     = result.fprice;
		    inv.note       = result.note;
		    inv.negative   = result.negative;
		    after_add();
		};

		var focus_first = function() {
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			inv.amounts[i].focus = false;
			if (wsaleUtils.to_integer(inv.amounts[i].count) !==0) {
			    inv.amounts[i].focus = true;
			}
		    }
		}

		var modal_size = diablo_valid_dialog(inv.sizes);
		var large_size = modal_size === 'lg' ? true : false;
		var payload = {
		    fdiscount:      inv.fdiscount,
		    fprice:         inv.fprice,
		    sizes:          inv.sizes,
		    large_size:     large_size,
		    colors:         inv.colors,
		    amounts:        inv.amounts,
		    path:           inv.path,
		    get_amount:     get_amount,
		    valid:          valid_all_sell,
		    cancel_callback:  function(close) {
			$scope.focus_by_element();},
		    right:          $scope.right
		}; 
		
		inv.free_color_size = false; 
		if ($scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
		    var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
		    console.log(color_size);

		    var bcode_color = wsaleUtils.to_integer(color_size.substr(0, 3));
		    var bcode_size_index = wsaleUtils.to_integer(
			color_size.substr(3, color_size.length));
		    
		    var bcode_size = bcode_size_index === 0 ? diablo_free_size:size_to_barcode[bcode_size_index]; 
		    var scan_found = false;
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			var color;
			inv.amounts[i].focus = false; 
			// find color first
			for (var j=0, k=inv.colors.length; j<k; j++) {
			    if (inv.amounts[i].cid === inv.colors[j].cid) {
				color = inv.colors[j];
				break;
			    }
			} 
			// console.log(color);
			
			// find size
			if ( angular.isDefined(color) && angular.isObject(color)
			     && color.bcode === bcode_color
			     && inv.amounts[i].size === bcode_size ) {
			    inv.amounts[i].sell_count = 1; 
			    inv.amounts[i].focus = true;

			    inv.sell      = inv.amounts[i].sell_count;
			    inv.fdiscount = inv.discount;
			    inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);
			    inv.note      = color.cname + inv.amounts[i].size + ";"
			    scan_found    = true;
			    break;
			}
		    }
		    
		    if (scan_found){
			after_add();
		    } 
		    else {
			focus_first();
			diabloUtilsService.edit_with_modal(
			    "wsale-update-order-new.html",
			    modal_size,
			    callback,
			    undefined,
			    payload); 
		    }
		} else {
		    focus_first();
		    diabloUtilsService.edit_with_modal(
			"wsale-update-order-new.html",
			modal_size,
			callback,
			undefined,
			payload); 
		    
		}
	    }
	});
    };

    /*
     * delete inventory
     */
    $scope.delete_inventory_head = function() {
	$scope.inventories.splice(0, 1);
	$scope.focus_good_or_barcode();
    };
    
    $scope.delete_inventory = function(inv){
	console.log(inv); 
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	} 

	$scope.re_calculate();
	
	// promotion
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    if (inv.order_id === $scope.show_promotions[i].order_id){
		break;
	    }
	}

	$scope.show_promotions.splice(i, 1);
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    $scope.show_promotions[i].order_id = l - i; 
	}
	
	$scope.focus_by_element();
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-update-order-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv, updateCallback, scan){
	console.log(inv);
	// inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    if (angular.isDefined(scan) && scan) {
	    	if (wsaleUtils.to_integer(inv.sell) === 0)
	    	    inv.sell = 1;
	    	else
	    	    inv.sell += 1;

	    	$scope.auto_save_free(inv);
	    } else {
	    	$scope.auto_focus("sell");
	    }
	    
	    return;
	}

	if (angular.isDefined(scan)
	    && scan
	    && $scope.setting.barcode_mode
	    && angular.isDefined(inv.full_bcode)) {
	    // get color, size from barcode 
	    var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
	    console.log(color_size);

	    var bcode_color = wsaleUtils.to_integer(color_size.substr(0, 3));
	    var bcode_size_index = wsaleUtils.to_integer(color_size.substr(3, color_size.length));
	    
	    var bcode_size = bcode_size_index === 0 ? diablo_free_size : size_to_barcode[bcode_size_index];
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
		    if (wsaleUtils.to_integer(a.sell_count) === 0)
			a.sell_count = 1;
		    else
			a.sell_count += 1;
		    a.focus = true;
		}
	    });
	} else {
	    for (var i=0, l=inv.amounts.length; i<l; i++) {
		var a = inv.amounts[i];
		a.focus = false;
		if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
		    a.focus = true;
		}
	    }
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result); 
	    
	    if (inv.fprice !== result.fprice || inv.fdiscount !== result.fdiscount) inv.$update = true;
	    
	    inv.amounts    = result.amounts;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    inv.note       = result.note;
	    
	    // inv.note 
	    $scope.re_calculate();
	    $scope.focus_by_element();

	    if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
		updateCallback();
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
	var payload = {fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount, 
		       valid:        valid_all_sell,
		       cancel_callback:  function() {
			   $scope.focus_by_element();
		       },
		       right:        $scope.right};
	console.log(payload);
	diabloUtilsService.edit_with_modal(
	    "wsale-update-order-new.html", modal_size, callback, undefined, payload)
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.sell;
	
	if (inv.fprice !== inv.o_fprice || inv.fdiscount !== inv.o_fdiscount) inv.$update = true;

	$scope.re_calculate(); 
	$scope.focus_good_or_barcode(); 
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv); 
	inv.free_update = false;
	inv.sell      = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice; 
	$scope.re_calculate(); 
    };

    $scope.check_free_update = function(inv) {
	return wsaleUtils.to_integer(inv.amounts[0].cs_finish) <= inv.sell;
    };

    $scope.reset_inventory = function(inv){
	$scope.focus_good_or_barcode(); 
    };

    $scope.auto_save_free = function(inv){
	var sell = wsaleUtils.to_integer(inv.sell);
	if (sell !== 0 && angular.isDefined(inv.style_number)) {
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    } 

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    } 
	} 
    }; 

    $scope.get_employee = function(){
	var select = wsaleUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee);

	$scope.employees = select.filter;
	$scope.select.employee = select.login;
	if ($scope.setting.semployee) $scope.select.employee = undefined;
    };
    
    wsaleService.get_w_sale_order_group_by_rsn($scope.rsn).then(function(result) {
	console.log(result);
	if (result.ecode === 0) {
	    var order = result.order; 
	    $scope.select = {
		rsn:  order.rsn,
		state: order.state,
		shop: diablo_get_object(order.shop_id, $scope.shops),
		retailer: {id:order.retailer_id,
			   name:order.retailer + "/" + order.mobile,
			   mobile:order.mobile,
			   level:order.retailer_level,
			   type_id:order.retailer_type}, 
		datetime:     diablo_set_datetime(order.entry_date)
	    };

	    get_setting(order.shop_id); 
	    $scope.get_employee();
	    $scope.select.employee = diablo_get_object(order.employee_id, filterEmployee);
	    // console.log($scope.employees);

	    angular.forEach(result.data, function(s) {
		var add = $scope.copy_select({}, s);
		add.o_finish = s.o_finish;
		
		var order_sizes = diabloHelp.usort_size_group(add.s_group, filterSizeGroup);
		var sort = diabloHelp.sort_stock(s.stock, order_sizes, filterColor); 
		add.total = sort.total;
		add.sizes = sort.size;
		add.colors = sort.color;
		add.amounts = sort.sort;

		add.fdiscount = add.fdiscount;
		// add.fprice = diablo_price(add.tag_price, add.fdiscount);
		add.fprice = add.fprice;
		add.o_fdiscount = add.fdiscount;
		add.o_fprice    = add.fprice;

		add.note = diablo_empty_string;
		add.sell = 0;
		add.free_color_size = false;

		if (0 === add.free) {
		    add.free_color_size = true;
		    add.sell = s.o_total;
		    add.amounts[0].sell_count = s.o_total;
		    add.amounts[0].cs_finish = s.o_finish;
		    if (add.sell > s.total) {
			add.negative = diablo_yes;
		    }
		} else {
		    add.free_color_size = false;
		    angular.forEach(s.order, function(o) {
			for (var i=0, l=add.amounts.length; i<l; i++) {
			    var a = add.amounts[i];
			    if (o.color_id === a.cid && o.size === a.size) {
				add.sell += o.cs_total;
				add.note += a.cname + a.size + ";";
				
				a.sell_count = o.cs_total;
				a.cs_finish = o.cs_finish;
				if (o.cs_total > a.count) {
				    add.negative = diablo_yes;
				}
			    }
			}
		    }); 
		}

		// console.log(add);
		add.$edit = true;
		add.$new = false;
		$scope.inventories.unshift(add);
		add.order_id = $scope.inventories.length;		
	    });
	    
	    $scope.re_calculate();
	    
	    $scope.old_select = angular.copy($scope.select);
	    console.log($scope.old_select);
	    
	    $scope.old_inventories = angular.copy($scope.inventories);
	    angular.forEach($scope.old_inventories, function(m) {
		m.amounts = m.amounts.filter(function(a) {
		    return wsaleUtils.to_integer(a.sell_count) !== 0;
		})
	    }); 
	    console.log($scope.old_inventories);
	    
	    $scope.focus_good_or_barcode();
	}
    });

    var get_order_state = function(order, finished) {
    	if (finished === 0) return diablo_order_start;
    	else if (finished >= order) return diablo_order_finish;
    	else if (finished < order) return diablo_order_part;
    };
    
    var get_update_order_note = function(newAmounts, oldAmounts){
	var changedAmounts = [];
	var found = false;
	for (var i=0, l1=newAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=oldAmounts.length; j < l2; j++){
		if (newAmounts[i].cid === oldAmounts[j].cid && newAmounts[i].size === oldAmounts[j].size){
		    // update
		    found = true; 
		    var update_count = wsaleUtils.to_integer(newAmounts[i].sell_count)
			- wsaleUtils.to_integer(oldAmounts[j].sell_count);
		    if ( update_count !== 0 ){
			changedAmounts.push(
			    {operation: 'u',
			     cid:   newAmounts[i].cid,
			     size:  newAmounts[i].size,
			     sell_count: update_count,
			     order_state: get_order_state(newAmounts[i].sell_count,
							  oldAmounts[j].cs_finish)})
		    }
		    
		    break;
		} 
	    }

	    // new
	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'a',
		     cid:  newAmounts[i].cid,
		     size: newAmounts[i].size,
		     sell_count: wsaleUtils.to_integer(newAmounts[i].sell_count)})
	    }
	}

	// delete
	for (var i=0, l1=oldAmounts.length; i < l1; i++){
	    found = false;
	    for (var j=0, l2=newAmounts.length; j < l2; j++){
		if (oldAmounts[i].cid === newAmounts[j].cid && oldAmounts[i].size === newAmounts[j].size){
		    found = true;
		    break;
		} 
	    }

	    if ( !found ) {
		changedAmounts.push(
		    {operation: 'd',
		     cid:   oldAmounts[i].cid,
		     size:  oldAmounts[i].size,
		     sell_count: wsaleUtils.to_integer(oldAmounts[i].sell_count)})
	    }
	}

	console.log(changedAmounts);
	return changedAmounts;
    };
    
    var get_update_order = function(){
	var changedInvs = [];
	var found = false;
	for (var i=0, l1=$scope.inventories.length; i < l1; i++){
	    var newInv = $scope.inventories[i];
	    found = false;
	    for (var j=0, l2=$scope.old_inventories.length; j < l2; j++){
		var oldInv = $scope.old_inventories[j];
		// update
		if (newInv.style_number === oldInv.style_number
		    && newInv.brand_id === oldInv.brand_id){
		    var sort_amounts = newInv.amounts.filter(function(a){
			return wsaleUtils.to_integer(a.sell_count) !== 0 
		    });
		    
		    var change_amouts = get_update_order_note(sort_amounts, oldInv.amounts);
		    
		    if (change_amouts.length !== 0){
			newInv.operation = 'u'; 
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			// console.log(newInv);
			// console.log(oldInv);
			if (parseFloat(newInv.fprice) !== oldInv.fprice
			    || parseFloat(newInv.fdiscount) !== oldInv.fdiscount
			    || diablo_set_string(newInv.comment) !== oldInv.comment){
			    newInv.operation = 'u';
			    changedInvs.push(newInv);
			}
		    }
		    newInv.order_state = get_order_state(newInv.sell, oldInv.o_finish);
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
	    for (var j=0, l2=$scope.inventories.length; j < l2; j++){
		var newInv = $scope.inventories[j];
		// console.log(oldInv);
		// console.log(newInv);
		if (oldInv.style_number === newInv.style_number && oldInv.brand_id === newInv.brand_id){
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

    $scope.save_update_order = function(){
	console.log($scope.inventories); 
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false,
		response_title,
		response_title + "失败：" + wsaleService.error[2192]);
	    return;
	};

	if ($scope.select.retailer.type_id === diablo_system_retailer) {
	    dialog.set_error(response_title, 2689);
	    return;
	}

	if ( 0 !== $scope.old_select.state
	     && $scope.old_select.retailer.id !== $scope.select.retailer.id) {
	    dialog.set_error(response_title, 2198);
	    return;
	}
	
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if ($scope.inventories[i].free_update) {
		diabloUtilsService.set_error(response_title, 2690);
		return; 
	    } 
	}

	var updates = get_update_order();
	console.log(updates);
	
	var added = [];
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		id          : add.id,
		style_number: add.style_number,
		brand       : add.brand_id,
		type        : add.type_id,
		sex         : add.sex,
		firm        : add.firm_id,
		season      : add.season,
		year        : add.year,
		s_group     : add.s_group,
		free        : add.free,
		path        : diablo_set_string(add.path), 
		comment     : diablo_set_string(add.comment), 
		entry       : add.entry,

		sell_total  : add.sell,
		order_state : add.order_state,
		org_price   : add.org_price,
		ediscount   : add.ediscount,
		tag_price   : add.tag_price,
		discount    : add.discount,
		fprice      : add.fprice,
		fdiscount   : add.fdiscount,

		operation   : add.operation,
		changed_amount : add.changed_amounts, 
		amount: function(){
		    if (add.operation === 'd' || add.operation === "a"){
			return add.amounts.filter(function(a){
			    return wsaleUtils.to_integer(a.sell_count) !== 0
			}).map(function(a) {
			    return {
				cid: a.cid,
				size: a.size,
				sell_count: a.sell_count,
				order_state: a.order_state}
			}) 
		    }}(),
	    })
	};
	
	var base = {
	    rsn:            $scope.select.rsn,
	    retailer:       $scope.select.retailer.id,
	    // retailer_type:  $scope.select.retailer.type_id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        diablo_set_string($scope.select.comment), 

	    abs_pay:        wsaleUtils.to_float($scope.select.abs_pay),
	    should_pay:     wsaleUtils.to_float($scope.select.should_pay), 
	    total:          wsaleUtils.to_integer($scope.select.total), 
	    round:          $scope.setting.round,
	}; 

	console.log(added);
	console.log(base); 
	// console.log($scope.select);
	var new_datetime = dateFilter($scope.select.datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.datetime, "yyyy-MM-dd");
	if (added.length === 0 
	    && $scope.select.employee.id === $scope.old_select.employee.id
	    && $scope.select.shop.id === $scope.old_select.shop.id
	    && $scope.select.retailer.id === $scope.old_select.retailer.id
	    && $scope.select.comment === $scope.old_select.comment
	    &&  new_datetime === old_datetime){
	    diabloUtilsService.response(
	    	false,
		"销售定单编辑",
		"销售定单编辑失败：" + wsaleService.error[2699]);
	} else {
	    wsaleService.update_w_sale_order(
		{inventory:added.length===0 ? undefined:added, base:base}
	    ).then(function(result){
		console.log(result); 
		if (0 === result.ecode){
		    dialog.response_with_callback(
			true,
			response_title,
			response_title + "成功：单号" + result.rsn,
			undefined,
			$scope.back);
		} else {
		    dialog.response(
	    		false,
			response_title,
			response_title + "失败：" + wsaleService.error[result.ecode]); 
		}
	    })
	} 
    };

    $scope.back = function() {diablo_goto_page("#/order/order_detail");}	
};


define (["wsaleApp"], function(app){
    app.controller("wsaleOrderUpdateCtrl", wsaleOrderUpdateCtrlProvide); 
});
