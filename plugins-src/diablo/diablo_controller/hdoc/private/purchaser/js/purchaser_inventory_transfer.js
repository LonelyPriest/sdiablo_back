'use strict'


function purchaserInventoryTransferCtrlProvide (
    $scope, $q, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, diabloNormalFilter, 
    purchaserService, user, filterShop, filterFirm, filterEmployee,
    filterSizeGroup, filterColor, base){
    $scope.response_title = "库存移仓"; 
    // console.log(user); 
    // console.log(filterShop); 
    $scope.shops = user.sortShops;
    // console.log($scope.shops);
    // console.log(user.sortRepoes);
    
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
    $scope.focus             = {barcode: false, style_number:false, transfer: false};

    $scope.go_back = function(){
	diablo_goto_page("#inventory/inventory_transfer_detail");
    };

    $scope.pattern = {discount:diabloPattern.discount};

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight();
    console.log($scope.stock_right);

    $scope.calc_row = stockUtils.calc_row; 
    $scope.init_base_setting = function(shopId) {
	$scope.base_settings.check_orgprice_of_transfer = stockUtils.stock_mode(shopId, base).check_t_price;
	$scope.base_settings.check_firm_of_transfer = stockUtils.stock_mode(shopId, base).check_t_firm;
	$scope.base_settings.type_sale = stockUtils.type_sale(shopId, base);
	// $scope.base_settings.use_barcode = stockUtils.use_barcode(shopId, base);

	var tMode = stockUtils.scan_mode(shopId, base);
	$scope.base_settings.scan_mode = stockUtils.to_integer(tMode.charAt(3));
	$scope.base_settings.fast_transfer = stockUtils.to_integer(tMode.charAt(7));
	
	$scope.base_settings.show_tagprice = stockUtils.to_integer(tMode.charAt(5));
	$scope.base_settings.xsale = stockUtils.to_integer(tMode.charAt(6));
	$scope.base_settings.auto_barcode = stockUtils.auto_barcode(diablo_default_shop, base);

	// can operater repo, means master
	$scope.master = diablo_no; 
	if ($scope.base_settings.xsale)
	    $scope.master = user.sortRepoes.length === 0 ? diablo_no : diablo_yes;
	
	// console.log($scope.base_settings, $scope.master);
    };

    var now = $.now(); 
    // init
    $scope.has_saved       = false; 
    $scope.inventories     = [];
    
    $scope.select = {
	total: 0,
	date: now,
	shop: $scope.shops.length !==0 ? $scope.shops[0] : undefined
    };
    
    // $scope.last_select = {barcode: false; style_number:false};
    $scope.transfer = {barcode:undefined, style_number:undefined};

    $scope.get_transfer_shop = function(){
	$scope.to_shops = []; 
	for (var i=0, l=filterShop.length; i<l; i++){
	    if ($scope.select.shop.id !== filterShop[i].id){
		var ashop = filterShop[i];
		if ($scope.base_settings.xsale && $scope.master === diablo_no) {
		    if ( ashop.type === 1) {
			$scope.to_shops.push(ashop); 
		    }
		} else {
		    $scope.to_shops.push(ashop); 
		}
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
	$scope.init_base_setting($scope.select.shop.id); 
	$scope.get_transfer_shop();
	$scope.focus_good_or_barcode();
	// if ($scope.base_settings.q_prompt === diablo_frontend){
	//     $scope.get_all_prompt_inventory();
	// }
    };

    $scope.refresh = function(){
	$scope.inventories = [];
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

    $scope.focus_good_or_barcode = function() {
	if ($scope.base_settings.scan_mode)
	    $scope.auto_focus('barcode');
	else
	    $scope.auto_focus('style_number');
    };

    $scope.focus_by_element = function() {
	$scope.transfer.style_number = undefined;
	$scope.transfer.barcode = undefined;
	if ($scope.base_settings.scan_mode) {
	    document.getElementById("barcode").focus();
	} else {
	    document.getElementById("snumber").focus();
	} 
    };

    $scope.get_valid_employee = function(){
	var loginEmployee =  stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = loginEmployee.login;
	$scope.employees = loginEmployee.filter; 
    };

    $scope.get_valid_employee();
    $scope.init_base_setting($scope.select.shop.id); 
    $scope.get_transfer_shop();
    $scope.focus_good_or_barcode();    
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    // $scope.today = function(){
    // 	return now;
    // };
    
    $scope.qtime_start = function(shopId){
	return stockUtils.start_time(shopId, base, now, dateFilter); 
    };
    
    $scope.match_prompt_inventory = function(viewValue){
	if (diablo_yes === $scope.base_settings.type_sale) {
	    return diabloFilter.match_w_sale(
		viewValue,
		$scope.select.shop.id,
		diablo_type_sale,
		diablo_is_ascii_string(viewValue));
	} else {
	    if (angular.isUndefined(diablo_set_string(viewValue)) && viewValue.length < diablo_filter_length) return;
	    return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id); 
	} 
    }; 

    $scope.copy_select = function(add, src) {
	add.id           = src.id;
	add.bcode        = src.bcode;
	add.full_bcode   = src.full_bcode;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.firm_id      = src.firm_id;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.year         = src.year;
	add.sex          = src.sex;
	add.season       = src.season;
	add.vir_price    = src.vir_price;
	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price;
	add.ediscount    = src.ediscount;
	add.discount     = src.discount;
	add.path         = src.path; 
	// add.alarm_day    = src.alarm_day;
	add.full_name    = add.style_number + "/" + add.brand + "/" + add.type; 
	// console.log(add); 
	return add;
    };

    var dialog = diabloUtilsService;
    $scope.on_select_inventory = function(item, model, label){
	console.log(item); 
	if (diablo_invalid_firm === item.firm_id && $scope.base_settings.check_firm_of_transfer){
	    // diabloUtilsService.response_with_callback(
	    // 	false, "库存移仓", "转移失败：" + purchaserService.error[2089],
	    // 	$scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}}); 
	    // return;
	    dialog.set_error($scope.response_title, 2089);
	} else if ( item.org_price <=0 && $scope.base_settings.check_orgprice_of_transfer) {
	    // diabloUtilsService.response_with_callback(
	    // 	false, "库存转仓", "转移失败：" + purchaserService.error[2088],
	    // 	$scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
	    // return;
	    dialog.set_error($scope.response_title, 2088);
	} else {
	    var add = {$new:true};
	    $scope.copy_select(add, item);
	    $scope.add_inventory(add);
	}
	
	// has been added
	// var existStock = undefined;
	// for(var i=1, l=$scope.inventories.length; i<l; i++){
	//     if (item.style_number === $scope.inventories[i].style_number
	// 	&& item.brand_id  === $scope.inventories[i].brand_id){
	// 	existStock = $scope.inventories[i];
	// 	// diabloUtilsService.response_with_callback(
	// 	//     false, "库存移仓", "转移失败：" + purchaserService.error[2099],
	// 	//     $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
	// 	// return;
	//     }
	// }

	// if (angular.isDefined(existStock)) {
	//     $scope.update_inventory(
	// 	existStock,
	// 	function() {$scope.inventories[0] = {$edit:false, $new:true}})
	// } else {
	//     // add at first allways 
	//     var add = {$new:true};
	//     $scope.copy_select(add, item);
	//     // $scope.auto_focus("transfer");
	//     $scope.add_inventory(add);
	// } 
    };

    $scope.barcode_scanner = function(barcode) {
	diabloHelp.scanner(
	    barcode,
	    $scope.base_settings.auto_barcode,
	    $scope.select.shop.id,
	    diabloFilter.get_stock_by_barcode,
	    diabloUtilsService,
	    "库存移仓",
	    $scope.on_select_inventory)
    };

    $scope.row_change_xdiscount = function(inv) {
	inv.xprice = diablo_price(
	    stockUtils.to_float(inv.tag_price),
	    stockUtils.to_float(inv.xdiscount));
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	return $scope.has_saved || $scope.inventories.length === 0; 
    };

    $scope.index_of_transfer = function(sale, exists) {
	var index = diablo_invalid_index;;
	for (var i=0, l=exists.length; i<l; i++) {
	    if (sale.style_number === exists[i].style_number && sale.brand_id === exists[i].brand) {
		index = i;
		break;
	    }
	} 
	return index;
    };

    $scope.index_of_transfer_detail = function(existDetails, detail) {
	var index = diablo_invalid_index;
	for (var j=0, k=existDetails.length; j<k; j++) {
	    if (detail.cid === existDetails[j].cid && detail.size === existDetails[j].size) {
		index = j;
		break;
	    } 
	}

	return index;
    }

    var get_transfer_detail = function(amounts){
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
	$scope.has_saved = true;
	console.log($scope.inventories);

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string; 
	var added = [];
	
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    var index = $scope.index_of_transfer(add, added)
	    if (diablo_invalid_index !== index) {
		var existTransfer = added[index];
		existTransfer.total += stockUtils.to_integer(add.reject); 
		var details1 = get_transfer_detail(add.amounts);
		var existDetails = existTransfer.amounts;
		console.log(details1); 
		console.log(existDetails);
		angular.forEach(details1, function(d) {
		    var indexDetail = $scope.index_of_transfer_detail(existDetails, d);
		    if (diablo_invalid_index !== indexDetail) {
			existDetails[indexDetail].count += d.count;
		    } else {
			existDetails.push(d);
		    } 
		})
	    } else {
		added.push({
		    order_id    : add.order_id,
		    bcode       : add.bcode,
		    style_number: add.style_number,
		    brand       : add.brand_id,
		    type        : add.type_id,
		    sex         : add.sex,
		    season      : add.season,
		    firm        : add.firm_id,

		    vir_price   : add.vir_price,
		    org_price   : add.org_price,
		    tag_price   : add.tag_price,
		    ediscount   : add.ediscount,
		    discount    : add.discount,

		    xdiscount   : $scope.base_settings.xsale && $scope.master ? add.xdiscount : undefined,
		    xprice      : $scope.base_settings.xsale && $scope.master ? add.xprice : undefined,
		    
		    s_group     : add.s_group,
		    free        : add.free,
		    year        : add.year,
		    
		    amounts     : get_transfer_detail(add.amounts),
		    total       : stockUtils.to_integer(add.reject),
		    path        : add.path,
		    // alarm_day   : add.alarm_day
		})
	    } 
	}; 
	
	var base = {
	    shop:      $scope.select.shop.id,
	    shop_type: $scope.select.shop.type,
	    
	    tshop:     $scope.select.to_shop.id,
	    tshop_type:$scope.select.to_shop.type,
	    
	    datetime:  dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:  $scope.select.employee.id,
	    comment:   sets($scope.select.comment), 
	    total:     stockUtils.to_integer($scope.select.total),
	    cost:      stockUtils.to_decimal($scope.select.cost),

	    xmaster:   $scope.master,
	    xsale:     $scope.base_settings.xsale,
	    xcost:     $scope.base_settings.xsale ? $scope.select.xcost : undefined
	};

	console.log(added);
	console.log(base);
	
	// $scope.has_saved = true
	purchaserService.transfer_purchaser_inventory({
	    inventory: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	dialog.response_with_callback(
	    	    true,
		    "库存转移", "库存转移成功！！单号：" + state.rsn,
		    undefined,
		    $scope.refresh);
	    } else{
	    	dialog.response_with_callback(
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
	$scope.select.xcost = 0;
	for (var i=0, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    // console.log(one);
	    // $scope.select.cost += stockUtils.to_float(one.org_price);
	    $scope.select.total += stockUtils.to_integer(one.reject);
	    $scope.select.cost += stockUtils.to_float(one.org_price) * stockUtils.to_integer(one.reject);
	    $scope.select.xcost += stockUtils.to_float(one.xprice) * stockUtils.to_integer(one.reject); 
	}

	$scope.select.cost  = stockUtils.to_decimal($scope.select.cost);
	$scope.select.xcost = stockUtils.to_decimal($scope.select.xcost);
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

    // $scope.valid_free_size_reject = function(inv){
    // 	if (angular.isDefined(inv.amounts) && angular.isDefined(inv.amounts[0].reject_count)){
    // 	    if (parseInt(inv.amounts[0].reject_count) > inv.total){
    // 		return false;
    // 	    }
    // 	}
    // 	return true;
    // };
    
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

    var add_callback = function(params){
	// console.log(params.amounts); 
	var reject_total = 0, note = "";
	angular.forEach(params.amounts, function(a){
	    if (stockUtils.to_integer(a.reject_count) > 0){
		reject_total += stockUtils.to_integer(a.reject_count);
		note += diablo_find_color(a.cid, filterColor).cname + a.size;
		if (a.reject_total > 1)
		    note += diablo_dash_seperator + reject_total.toString();
		note += diablo_semi_seperator;
	    }
	}); 

	return {amounts:     params.amounts,
		org_price:   params.org_price,
		xdiscount:   params.xdiscount, 
		reject:      reject_total,
		note:        note};
    };

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
    
    $scope.add_free_inventory = function(inv){
	// console.log(inv); 
	if (free_stock_not_enought(inv)) {
	    dialog.set_error($scope.response_title, 2070);
	} else {
	    inv.$edit = true;
	    inv.$new = false;
	    inv.amounts[0].reject_count = inv.reject;
	    // // oreder
	    $scope.inventories.unshift(inv);
	    inv.order_id = $scope.inventories.length;

	    $scope.row_change_xdiscount(inv); 
	    $scope.re_calculate();
	    // $scope.auto_focus("style_number");
	    // $scope.focus_good_or_barcode();
	}
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

	    var after_add = function(enought_check){
		if (enought_check && cs_stock_not_enought(inv)) {
		    dialog.set_error($scope.response_title, 2070);
		}else {
		    inv.$edit = true;
		    inv.$new = false;
		    // order
		    $scope.inventories.unshift(inv); 
		    inv.order_id = $scope.inventories.length;
		    
		    $scope.row_change_xdiscount(inv); 
		    $scope.re_calculate();
		    $scope.focus_by_element();
		} 
	    };
	    
	    var callback = function(params){
		var result = add_callback(params);
		// console.log(result);
		inv.amounts   = result.amounts;
		inv.reject    = result.reject;
		inv.org_price = result.org_price;
		inv.xdiscount = stockUtils.to_integer(result.xdiscount);
		inv.note      = result.note;
		after_add(true);
	    };

	    var start_transfer = function() {
		var payload = {sizes:           inv.sizes,
			       colors:          inv.colors,
			       org_price:       inv.org_price,
			       amounts:         inv.amounts,
			       get_amount:      get_amount,
			       valid:           valid_all,
			       cancel_callback: $scope.focus_by_element};
		
		diabloUtilsService.edit_with_modal(
		    "inventory-new.html", 'lg', callback, $scope, payload); 
	    }
	    
	    if (inv.free === 0){
		inv.free_color_size = true;
		inv.amounts = [{cid:0, size:0}];
		inv.reject  = 1;
		$scope.auto_save_free(inv);
		if ($scope.base_settings.fast_transfer) {
		    $scope.focus_by_element();
		} else {
		    $scope.auto_focus("transfer"); 
		    $scope.update_inventory(inv);
		}
	    } else {
		inv.free_color_size = false;
		
		if ($scope.base_settings.scan_mode && angular.isDefined(inv.full_bcode)) {
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

		    if ($scope.base_settings.fast_transfer) {
			if (cs_stock_not_enought(inv)) {
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
			start_transfer();
		    } 
		    
		} else {
		    // inv.amounts[0].focus = true;
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			var a = inv.amounts[i];
			a.focus = false;
			if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
			    a.focus = true;
			}
		    }
		    
		    start_transfer();
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
	// $scope.focus_good_or_barcode();
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
    $scope.update_inventory = function(inv, updateCallback){
	console.log(inv);
	// inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_org_price  = inv.org_price;
	    $scope.auto_focus("transfer");
	} else {
	    for (var i=0, l=inv.amounts.length; i<l; i++) {
		var a = inv.amounts[i];
		a.focus = false;
		if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
		    a.focus = true;
		}
	    }
	    
	    var callback = function(params){
		var result = add_callback(params);
		inv.amounts   = result.amounts;
		inv.org_price = result.org_price;
		inv.xdiscount = result.xdiscount;
		inv.reject    = result.reject;
		inv.note      = result.note;
		
		$scope.row_change_xdiscount(inv);
		$scope.re_calculate();
		$scope.focus_by_element();
		
		if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
		    updateCallback();
	    };

	    var payload = {sizes:        inv.sizes,
			   colors:       inv.colors,
			   org_price:    inv.org_price,
			   amounts:      inv.amounts,
			   get_amount:   get_amount,
			   // valid_reject: valid_reject,
			   valid:        valid_all,
			   cancel_callback: function() {
			       $scope.focus_by_element();
			   }}; 
	    dialog.edit_with_modal(
		"inventory-new.html", undefined, callback, $scope, payload);
	} 
    };

    $scope.save_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	if (free_stock_not_enought(inv)) {
	    dialog.set_error($scope.response_title, 2070);
	} else {
	    inv.free_update = false;
	    inv.amounts[0].reject_count = inv.reject;

	    $scope.row_change_xdiscount(inv);
	    $scope.re_calculate();
	    console.log(inv);
	    // $scope.focus_good_or_barcode();
	    $scope.focus_by_element();
	} 
	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
    }

    $scope.cancel_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.org_price  = inv.o_org_price;
	inv.amounts[0].reject_count = inv.reject;
    } 

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
    
    //var timeout_auto_ = undefined;
    $scope.auto_save_free = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
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
	
	// if (angular.isUndefined(inv.style_number)
	//     || 0 === reject
	//     || reject > inv.total
	//     || reject === inv.reject){
	//     return;
	// }
	
	// $scope.timeout_auto_save = $timeout(function(){
	//     if (inv.$new && inv.free_color_size){
	// 	$scope.add_free_inventory(inv);
	//     };

	//     if (!inv.$new && inv.free_update){
	// 	$scope.save_free_update(inv);
	//     }
	// }, 1000);
    };

    $scope.transfer_by_shop = function() {
	console.log($scope.select.shop);
	var callback = function() {
	    purchaserService.get_stock_by_shop($scope.select.shop.id).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    $scope.refresh();
		    for (var i=0, l=result.data.length; i<l; i++) {
			var stock = result.data[i];
			if (stock.free === 0) {
			    var add = {$new:false, edit:true}; 
			    $scope.copy_select(add, stock); 
			    add.free_color_size = true;
			    add.total = stock.amount;
			    add.reject = stock.amount;
			    add.amounts = [{reject_count:stock.amount, cid:0, size:0}];
			    $scope.inventories.unshift(add);
			    add.order_id = $scope.inventories.length;
			    $scope.re_calculate();
			    // console.log(add);
			} else {
			    for (var j=0, k=stock.notes.length; j<k; j++) {
				var n = stock.notes[j]; 
				var add = {$new:false, edit:true}; 
				$scope.copy_select(add, stock); 
				add.free_color_size = false;
				add.total = stock.amount;
				add.reject = n.total;
				add.amounts = [{reject_count:n.total, cid:n.color, size:n.size}];
				var r = add_callback({amounts:add.amounts});
				add.note = r.note;
				$scope.inventories.unshift(add);
				add.order_id = $scope.inventories.length;
				$scope.re_calculate();
				// console.log(add);
			    }
			} 
		    }
		    // console.log($scope.inventories);
		    $scope.focus_by_element();
		    
		} else {
		    dialog.set_error("整店移仓", result.ecode);
		}
		
	    });
	}

	dialog.request(
	    "整店移仓",
	    "整店移仓容量导库存误差，确定要整店移仓吗？",
	    callback, undefined, undefined); 
    }
    
};


function purchaserInventoryTransferFromDetailCtrlProvide (
    $scope, dateFilter, localStorageService, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, 
    user, filterShop, filterEmployee, base){
    // console.log($routeParams);

    $scope.from_shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    $scope.total_items = 0;
    $scope.goto_page = diablo_goto_page;

    $scope.go_transfer = function(){
	$scope.goto_page('#/inventory/inventory_transfer');
    };

    $scope.go_transfer_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/transfer_from');
    };

    $scope.stock_right = {
	print:  stockUtils.authen_stock(user.type, user.right, 'print_stock_transfer'),
	cancel: stockUtils.authen_stock(user.type, user.right, 'cancel_stock_transfer'),
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, "show_orgprice")
    };

    $scope.base_settings = {
	xsale: stockUtils.to_integer(stockUtils.scan_mode(diablo_default_shop, base).charAt(6))
    };

    $scope.master = diablo_no;
    if ($scope.base_settings.xsale)
	$scope.master = user.sortRepoes.length === 0 ? diablo_no : diablo_yes;

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("fshop",    $scope.from_shops);
    diabloFilter.add_field("tshop",    filterShop);
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
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters = storage.filter;
	// console.log($scope.filter);
	if (angular.isDefined(storage.start_time)) {
	    $scope.time.start_time = storage.start_time; 
	}
    };

    // console.log($scope.filters);
    
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
	    if (angular.isUndefined(search.fshop)
		|| (angular.isArray(search.fshop) && search.fshop.length === 0)) {
		search.fshop = $scope.from_shops.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    if (angular.isUndefined(search.tshop)
		|| (angular.isArray(search.tshop) && search.tshop.length === 0)) {
		search.tshop = undefined; 
	    }

	    localStorageService.set(
		diablo_key_inventory_transfer,
		{filter:$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page:page, t:now});
	    
	    purchaserService.filter_transfer_w_inventory(
		$scope.match,
		search, page,
		$scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.t_amount;
		    $scope.total_cost  = result.t_cost;
		    // $scope.total_xcost = result.t_xcost;
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

    $scope.print_transfer = function(r) {
	var callback = function() {
	    diablo_goto_page("#/print_inventory_transfer/" + r.rsn);
	}
	
	dialog.request(
	    "采购单打印", "调出单打印需要打印机支持A4纸张，确认要打印吗？",
	    callback, undefined, undefined);
    };
};


function purchaserInventoryTransferToDetailCtrlProvide (
    $scope, dateFilter, localStorageService, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, 
    user, filterShop, filterEmployee, base){

    $scope.to_shops  = user.sortShops;
    $scope.shopIds = user.shopIds;
    // console.log($scope.to_shops);
    $scope.goto_page = diablo_goto_page;
    $scope.total_items = 0;

    $scope.go_transfer = function(){
	$scope.goto_page('#/inventory/inventory_transfer');
    };

    $scope.go_transfer_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/transfer_to');
    };

    var tMode = stockUtils.scan_mode(diablo_default_shop, base);
    $scope.base_settings = {
	xsale: stockUtils.to_integer(tMode.charAt(6)),
	check_stock: stockUtils.to_integer(tMode.charAt(8))
    };

    $scope.master = diablo_no; 
    if ($scope.base_settings.xsale)
	$scope.master = user.sortRepoes.length === 0 ? diablo_no : diablo_yes;

    $scope.stock_right = {
	// print:  stockUtils.authen_stock(user.type, user.right, 'print_stock_transfer'),
	// cancel: stockUtils.authen_stock(user.type, user.right, 'cancel_stock_transfer'),
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, "show_orgprice")
    };
    
    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    // diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("tshop",     $scope.to_shops);
    diabloFilter.add_field("fshop",     filterShop);

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
    var storage = localStorageService.get(diablo_key_inventory_transfer_to);
    // console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.filters = storage.filter;
	// console.log($scope.filter);
	if (angular.isDefined(storage.start_time)) {
	    $scope.time.start_time = storage.start_time; 
	}
    };
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
	    if (angular.isUndefined(search.tshop)
		|| (angular.isArray(search.tshop) && search.tshop.length === 0)){
	    	search.tshop = $scope.to_shops.length === 0 ? undefined : $scope.shopIds;
	    }

	    if (angular.isUndefined(search.fshop)
		|| (angular.isArray(search.fshop) && search.fshop.length === 0)) {
		search.fshop = undefined; 
	    }

	    localStorageService.set(
		diablo_key_inventory_transfer_to,
		{filter:$scope.filters,
		 start_time:diablo_get_time($scope.time.start_time),
		 page:page, t:now});
	    
	    purchaserService.filter_transfer_w_inventory(
		$scope.match,
		search, page,
		$scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.t_amount;
		    $scope.total_cost = result.t_cost;
		    // $scope.total_xcost = result.t_xcost;
		}
		angular.forEach(result.data, function(d){
		    d.fshop = diablo_get_object(d.fshop_id, filterShop);
		    d.tshop = diablo_get_object(d.tshop_id, $scope.to_shops);
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
	diablo_goto_page("#/inventory/inventory_rsn_detail/transfer_to/" + r.rsn);
    };

    // check
    var dialog = diabloUtilsService;
    $scope.check_transfer = function(r){
	var callback = function(){
	    var check_date = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
	    purchaserService.check_w_inventory_transfer(
		{rsn        :r.rsn,
		 fshop      :r.fshop_id,
		 fshop_type :r.fshop.type, 
		 tshop      :r.tshop_id,
		 datetime   :check_date,
		 xsale      :$scope.base_settings.xsale,
		 check_stock:$scope.base_settings.check_stock}
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
		    if (state.ecode === 2021) {
			dialog.response(
	    		    false,
			    "移仓调入确认",
	    		    "确认失败："
				+ purchaserService.error[2021]
				+ state.stock);
		    } else {
			dialog.response(
	    		    false,
			    "移仓调入确认",
	    		    "确认失败："
				+ purchaserService.error[state.ecode]);
		    } 
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
