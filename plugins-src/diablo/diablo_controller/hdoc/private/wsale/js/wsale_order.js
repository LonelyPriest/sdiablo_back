function wsaleOrderNewCtrlProvide(
    $scope, $q, $timeout, $interval, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wsaleService,
    user, filterPromotion, filterScore, filterSysRetailer, filterEmployee,
    filterSizeGroup, filterType, filterColor, filterLevel, base){
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
    
    $scope.round  = diablo_round;
    $scope.calendar = require('diablo-calendar');
    
    $scope.today = function(){return $.now();}; 
    $scope.back  = function(){diablo_goto_page("#/wsale_order_detail.html");};
    
    $scope.setting = {check_sale:true};
    $scope.face = window.face;

    var response_title = "销售订单";
    var dialog = diabloUtilsService; 

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();
    
    // console.log($scope.right);
    $scope.focus_attr = {style_number:false, barcode:false};
    $scope.auto_focus = function(attr){
	for (var o in $scope.focus_attr){
	    $scope.focus_attr[o] = false;
	}
	$scope.focus_attr[attr] = true; 
    };

    $scope.disable_start_sale = function() {
	return $scope.inventories.length === 0;
    };
    
    $scope.q_typeahead = function(){
	// default prompt comes from backend
	return wsaleUtils.typeahead($scope.select.shop.id, base); 
    }; 
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.retailer_types  = diablo_retailer_types.filter(function(t) {
	return t.id !== 2;
    });
    
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.f_discount      = diablo_discount;
    $scope.wsale_mode      = wsaleService.wsale_mode;
    $scope.face            = window.face;
    $scope.show_promotions = [];
    $scope.disable_refresh = true; 
    $scope.solar2lunar = function(date) {
	// console.log(date);
	return $scope.calendar.solar2lunar(date.year, date.month, date.day);
    };
    
    $scope.select = {
	rsn:  undefined, 
	total:        0, 
	has_pay:      0,
	should_pay:   0,
	base_pay:     0,
	datetime:     $scope.today(),
	lunar:        $scope.solar2lunar(diablo_get_now_full_date()),
    };
    console.log($scope.select);

    // init
    $scope.sale = {barcode:undefined, style_number:undefined};
    $scope.inventories = []; 
    
    var dialog = diabloUtilsService; 
    var get_setting = function(shopId){
	$scope.setting.q_backend     = $scope.q_typeahead(shopId);
	$scope.setting.round         = wsaleUtils.round(shopId, base);
	$scope.setting.solo_retailer = wsaleUtils.solo_retailer(shopId, base);
	$scope.setting.semployee     = wsaleUtils.s_employee(shopId, base);
	//$scope.setting.cake_mode     = wsaleUtils.cake_mode(shopId, base);
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

	// get valid levels
	// console.log(shopId);
	$scope.levels = filterLevel.filter(function(l) {
	    return l.shop_id === shopId;
	})

	if ($scope.levels.length === 0) {
	    $scope.levels = filterLevel.filter(function(l) {
		return l.shop_id === diablo_default_shop;
	    })
	}

	// console.log($scope.levels);
    };
    
    // shops
    $scope.shops = user.sortShops.filter(function(s) {return s.deleted===0}); 
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0];
	get_setting($scope.select.shop.id);
	// console.log($scope.face($scope.setting.shop_mode));
    }

    $scope.focus_good_or_barcode = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.scan_only) {
	    $scope.auto_focus('barcode');
	} else {
	    if ($scope.setting.barcode_mode && !$scope.setting.focus_style_number) {
		// document.getElementById("barcode").focus();
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
    
    $scope.focus_good_or_barcode();
    console.log($scope.focus_attr);

    $scope.change_shop = function(){
	get_setting($scope.select.shop.id);	
	$scope.get_employee();
	$scope.reset_retailer();

	$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	$scope.wsaleStorage.change_shop($scope.select.shop.id);
	$scope.refresh(); 
    };
    
    $scope.get_employee = function(){
	var select = wsaleUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee);

	$scope.employees = select.filter;
	$scope.select.employee = select.login;
	if ($scope.setting.semployee) $scope.select.employee = undefined;
    };
    
    $scope.get_employee();
    
    // retailer;
    $scope.match_retailer_phone = function(viewValue){
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.select.shop.id,
	    $scope.setting.solo_retailer);
    };
    
    $scope.set_retailer = function(){
    	$scope.select.o_retailer = $scope.select.retailer; 
    };
    
    $scope.on_select_retailer = function(item, model, label){
	// console.log(item);
	console.log($scope.select.retailer);
	$scope.set_retailer(); 
	$scope.re_calculate(); 
    };
    
    $scope.reset_retailer = function(){
	$scope.sysRetailers = filterSysRetailer.filter(function(r){
    	    return r.shop_id === $scope.select.shop.id;
    	});
	
    	if ($scope.sysRetailers.length !== 0){
    	    $scope.select.retailer = $scope.sysRetailers[0];
    	    if (user.loginRetailer !== diablo_invalid){
    		for (var i=0, l=$scope.sysRetailers.length; i<l; i++){
                    if (user.loginRetailer === $scope.sysRetailers[i].id){
    			$scope.select.retailer = $scope.sysRetailers[i]
    			break;
                    }
    		}
            } 
    	    // $scope.set_retailer(); 
    	} else {
	    $scope.select.retailer = filterSysRetailer[0];
	}
	// console.log($scope.select.retailer);
	$scope.set_retailer();
	$scope.select.sysVip = diablo_yes;
	// $scope.select.retailer.name = diablo_empty_string;
    };

    $scope.reset_retailer();
    
    $scope.new_retailer = function() {
	var callback = function(params) {
	    console.log(params);
	    var r = params.retailer;
	    var addedRetailer =
		{name:     r.name,
		 intro:    r.intro && angular.isObject(r.intro) ? r.intro.id : undefined,
		 py:       diablo_pinyin(r.name),
		 password: diablo_set_string(r.password),
		 mobile:   r.mobile,
		 type:     r.type.id,
		 level:    r.level.level,
		 shop:     $scope.select.shop.id,
		 birth:    dateFilter(r.birth, "yyyy-MM-dd"),
		 lunar:    r.lunar.id};

	    console.log(addedRetailer);
	    diabloFilter.new_wretailer(addedRetailer).then(function(result){
	        console.log(result);
	        if (result.ecode === 0){
		    var nRetailer = {
			id:      result.id,
			name:    addedRetailer.name + "/" + addedRetailer.mobile,
			wname:   addedRetailer.name,
			birth:   addedRetailer.birth.substr(5,8),
			wbirth:  addedRetailer.birth,
			lunar_id:addedRetailer.lunar,
			level:   addedRetailer.level,
			mobile:  addedRetailer.mobile,
			type_id: addedRetailer.type,
			score:   0,
			shop_id: addedRetailer.shop,
			py:      addedRetailer.py,
			balance: 0
		    }; 
		    $scope.select.retailer = nRetailer;
		    // $scope.set_retailer();
		    $scope.on_select_retailer();
	        } else {
	    	    dialog.set_error("新增会员", result.ecode);
	    	}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-retailer.html",
	    undefined,
	    callback,
	    $scope,
	    {
		retailer: {
		    $new:true,
		    birth:$.now(),
		    lunar:diablo_lunar[0],
		    type :$scope.retailer_types[0],
		    level:$scope.retailer_levels[0]
		},
		levels: $scope.retailer_levels,
		lunars: diablo_lunar,
		retailer_types:$scope.retailer_types,
		pattern: {name:diabloPattern.chinese_name,
			  tel_mobile: diabloPattern.tel_mobile,
			  password:   diabloPattern.num_passwd}
	    }
	    
	); 
    };

    $scope.update_retailer = function() {
	var oRetailer = angular.copy($scope.select.retailer);
	var get_modified = diablo_get_modified;
	var pinyin = diablo_pinyin;
	var set_date = diablo_set_date_obj;
	
	var callback = function(params) {
	    console.log(params);
	    var u = params.retailer;
	    var uRetailer = {
		id:       oRetailer.id,
		shop:     $scope.select.shop.id,
		name:     get_modified(u.name, oRetailer.wname),
		py:       get_modified(pinyin(u.name), pinyin(oRetailer.wname)),
		password: get_modified(u.password, oRetailer.password),
		type:     get_modified(u.type.id, oRetailer.type_id),
		birth:    get_modified(u.birth.getTime(), set_date(oRetailer.wbirth).getTime()),
		lunar:    get_modified(u.lunar.id, oRetailer.lunar_id)
	    };
	    
	    console.log(uRetailer);
	    diabloFilter.update_wretailer(uRetailer).then(function(result){
	        console.log(result);
	        if (result.ecode === 0){
		    if (angular.isDefined(uRetailer.name)) {
			oRetailer.wname = uRetailer.name;
			oRetailer.name  = uRetailer.name + "/" + uRetailer.mobile;
			oRetailer.py    = diablo_pinyin(uRetailer.name);
		    }

		    if (angular.isDefined(uRetailer.type)) {
			oRetailer.type_id = uRetailer.type; 
		    }

		    if (angular.isDefined(uRetailer.lunar)) {
			oRetailer.lunar_id = uRetailer.lunar;
			oRetailer.lunar = diablo_get_object(oRetailer.lunar_id, diablo_lunar);
		    }

		    if (angular.isDefined(uRetailer.birth)) {
			oRetailer.wbirth = dateFilter(uRetailer.birth, "yyyy-MM-dd");
			oRetailer.birth = oRetailer.wbirth.substr(5,8);
		    }
		    $scope.select.retailer = oRetailer;
		    $scope.set_retailer();
		    // console.log($scope.select.retailer);
	        } else {
	    	    dialog.set_error("会员编辑", result.ecode);
	    	}
	    });
	};

	dialog.edit_with_modal(
	    "new-retailer.html",
	    undefined,
	    callback,
	    $scope,
	    {
		retailer: {
		    name:    oRetailer.wname,
		    mobile:  oRetailer.mobile,
		    birth:   set_date(oRetailer.wbirth),
		    lunar:   diablo_get_object(oRetailer.lunar_id, diablo_lunar),
		    type_id: oRetailer.type_id,
		    type:    diablo_get_object(oRetailer.type_id, $scope.retailer_types),
		},
		retailer_types:$scope.retailer_types,
		lunars: diablo_lunar,
		pattern: {name:diabloPattern.chinese_name,
			  password: diabloPattern.num_passwd}
	    }
	    
	); 
    };
    
    $scope.refresh = function(){
	$scope.inventories = []; 
	$scope.select.rsn             = undefined; 
	$scope.select.sysVip       = diablo_yes,
	$scope.select.total        = 0; 
	$scope.select.should_pay   = 0;
	$scope.select.base_pay     = 0; 
	
	$scope.select.comment      = undefined; 
	$scope.select.datetime     = $scope.today();
	$scope.select.lunar        = $scope.solar2lunar(diablo_get_now_full_date());
	
	if ($scope.setting.semployee)
	    $scope.select.employee = undefined;
	
	$scope.disable_refresh     = true;
	$scope.has_saved           = false;
	
	$scope.disable_focus();
	$scope.focus_good_or_barcode();
	$scope.reset_retailer();
    };
    

    var now = $scope.today(); 
    $scope.qtime_start = function(shopId){
	return wsaleUtils.start_time(shopId, base, now, dateFilter);
    };
    
    $scope.setting.q_backend = $scope.q_typeahead($scope.select.shop.id); 
    
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

    $scope.copy_select = function(add, src){
	console.log(src);
	add.id           = src.id;
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

	add.full_name    = add.style_number + "/" + add.brand + "/" + add.type; 
	return add; 
    };

    var fail_response = function(code, callback){
	diabloUtilsService.response_with_callback(
	    false,
	    "销售开单",
	    "开单失败：" + wsaleService.error[code],
	    undefined,
	    callback);
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item); 
	if (item.tag_price < 0){
	    fail_response(2193, function(){}); 
	} else {
	    // auto focus
	    $scope.auto_focus("sell"); 
	    var add  = {$new:true}; 
	    $scope.copy_select(add, item);
	    console.log(add);
	    $scope.add_inventory(add); 
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
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	return $scope.has_saved || $scope.inventories.length === 0 ? true :false; 
    };
    
    var get_sale_detail = function(amounts){
	var sale_amounts = [];
	for(var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		var new_a = {
		    cid:        a.cid,
		    size:       a.size, 
		    sell_count: wsaleUtils.to_integer(amounts[i].sell_count),
		    exist:      a.count
		}; 
		sale_amounts.push(new_a); 
	    }
	}; 
	return sale_amounts;
    };

    var index_of_sale = function(sale, exists) {
	var index = diablo_invalid_index;;
	for (var i=0, l=exists.length; i<l; i++) {
	    if (sale.style_number === exists[i].style_number && sale.brand_id === exists[i].brand) {
		index = i;
		break;
	    }
	} 
	return index;
    };

    var index_of_sale_detail = function(existDetails, detail) {
	var index = diablo_invalid_index;
	for (var j=0, k=existDetails.length; j<k; j++) {
	    if (detail.cid === existDetails[j].cid && detail.size === existDetails[j].size) {
		// existDetails[j].sell_count += d.sell_count;
		index = j;
		break;
	    } 
	}

	return index;
    }
    
    $scope.save_order = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	// console.log($scope.select);
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false,
		response_title,
		response_title + "失败：" + wsaleService.error[2192]);
	    $scope.has_saved = false; 
	    return;
	};

	if ($scope.select.retailer.type_id === diablo_system_retailer) {
	    dialog.set_error(response_title, 2689);
	    $scope.has_saved = false; 
	    return;
	}
	
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if ($scope.inventories[i].free_update) {
		diabloUtilsService.set_error(response_title, 2198);
		$scope.has_saved = false;
		return; 
	    } 
	}
	
	var added = [];
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    console.log(add);
	    var sell_total = wsaleUtils.to_integer(add.sell); 
	    var index = index_of_sale(add, added)
	    // console.log(index);
	    if (diablo_invalid_index !== index) {
		var existSale = added[index];
		existSale.sell_total += sell_total;
		existSale.all_tagprice += wsaleUtils.to_decimal(add.tag_price * sell_total);
		existSale.all_fprice += wsaleUtils.to_decimal(add.fprice * sell_total);
		existSale.all_rprice += wsaleUtils.to_decimal(add.rprice * sell_total);
		
		// reset fdiscount
		if (existSale.fdiscount !== add.fdiscount) {
		    existSale.fdiscount = diablo_discount(
			existSale.all_fprice, existSale.all_tagprice) ; 
		    existSale.fprice = diablo_price(existSale.tag_price, existSale.fdiscount);
		} 
		
		var details1 = get_sale_detail(add.amounts);
		var existDetails = existSale.amounts;
		// console.log(existDetails);
		// console.log(details1);
		angular.forEach(details1, function(d) {
		    var indexDetail = index_of_sale_detail(existDetails, d);
		    if (diablo_invalid_index !== indexDetail) {
			existDetails[indexDetail].sell_count += d.sell_count;
		    } else {
			existDetails.push(d);
		    } 
		})
	    } else {
		// var batch = add.batch;
		// console.log(batch);
		var details0 = get_sale_detail(add.amounts);
		added.push({
		    id          : add.id,
		    style_number: add.style_number,
		    brand       : add.brand_id,
		    brand_name  : add.brand,
		    type        : add.type_id,
		    type_name   : add.type,
		    sex         : add.sex,
		    firm        : add.firm_id,
		    // sex         : add.sex,
		    season      : add.season,
		    year        : add.year,
		    s_group     : add.s_group,
		    free        : add.free,
		    path        : diablo_set_string(add.path), 
		    comment     : diablo_set_string(add.comment), 
		    entry       : add.entry,
		    
		    sell_total  : sell_total, 
		    org_price   : add.org_price,
		    ediscount   : add.ediscount,
		    tag_price   : add.tag_price,
		    discount    : add.discount,
		    fprice      : add.fprice,
		    fdiscount   : add.fdiscount,
		    
		    all_fprice  : wsaleUtils.to_decimal(add.fprice * sell_total),
		    all_tagprice: wsaleUtils.to_decimal(add.tag_price * sell_total),
		    		    
		    // sizes       : add.sizes, 
		    // colors      : add.colors, 
		    amounts     : details0
		})
	    } 
	};
	
	console.log($scope.select); 
	console.log(added);
	
	// console.log($scope.select); 
	// console.log(im_print);
	var base = {
	    retailer:       $scope.select.retailer.id,
	    retailer_type:  $scope.select.retailer.type_id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        diablo_set_string($scope.select.comment), 

	    base_pay:       wsaleUtils.to_float($scope.select.base_pay),
	    should_pay:     wsaleUtils.to_float($scope.select.should_pay), 
	    total:          wsaleUtils.to_integer($scope.select.total), 
	    round:          $scope.setting.round,
	}; 

	console.log(base);

	wsaleService.new_w_sale_order(
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
		dialog.response_with_callback(
	    	    false,
		    response_title,
		    response_title + "失败："
			+ wsaleService.error[result.ecode]
			+ wsaleUtils.extra_error(result), 
		    undefined,
		    function(){$scope.has_saved = false});
		
	    }
	})
    };
	
    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 
    
    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total        = 0; 
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;
	$scope.select.base_pay     = 0;
	
	// console.log($scope.inventoyies);
	var calc = wsaleCalc.calculate(
	    // $scope.select.o_retailer,
	    // $scope.select.retailer,
	    wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
	    $scope.setting.vip_mode,
	    wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels),
	    // wsaleUtils.get_retailer_level($scope.select.retailer.level, $scope.levels),
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_sale,
	    0,
	    $scope.setting.round,
	    0);
	
	// console.log(calc);
	// console.log($scope.show_promotions);
	$scope.select.total      = calc.total;
	$scope.select.abs_total  = calc.abs_total;
	$scope.select.should_pay = calc.should_pay;
	$scope.select.base_pay   = calc.base_pay; 
    }; 

    
    var valid_all_sell = function(amounts){
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;
	for(var i=0, l=amounts.length; i<l; i++){
	    var sell = amounts[i].sell_count;
	    if (0 === wsaleUtils.to_integer(sell)){
		unchanged++;
		continue;
	    } 
	    if (!renumber.test(sell)) return false; 
	};

	return unchanged === l ? false : true; 
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
	// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
	$scope.re_calculate();	    
	$scope.focus_good_or_barcode(); 
    };
    
    $scope.calc_discount = function(inv){
	if (inv.pid !== -1 && inv.promotion.rule_id === 0){
	    return inv.discount < inv.promotion.discount ? inv.discount : inv.promotion.discount;
	} 
	else {
	    return inv.discount;
	}
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer) || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
	    	false, response_title, response_title + "失败：" + wsaleService.error[2192]);
	    return;
	    // $scope.reset_retailer();
	};
	
	inv.fdiscount = inv.discount;
	inv.fprice    = diablo_price(inv.tag_price, inv.discount);

	// inv.fdiscount = $scope.calc_discount(inv); 
	// inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);

	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	// if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	//     inv.free_color_size = true;
	//     inv.amounts         = [{cid:0, size:0}];
	//     inv.sell = 1; 
	//     $scope.auto_save_free(inv);
	// }
	// else {
	var promise = diabloPromise.promise; 
	var calls = [promise(diabloFilter.list_purchaser_inventory,
			     {style_number: inv.style_number,
			      brand:        inv.brand_id,
			      shop:         $scope.select.shop.id
			     })()];
	
	$q.all(calls).then(function(data){
	    // console.log(data);
	    // data[0] is the inventory belong to the shop
	    // data[1] is the last sale of the shop
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
		    // valid_sell:     valid_sell,
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
			    "wsale-order-new.html",
			    modal_size,
			    callback,
			    undefined,
			    payload); 
		    }
		} else {
		    focus_first();
		    diabloUtilsService.edit_with_modal(
			"wsale-order-new.html",
			modal_size,
			callback,
			undefined,
			payload); 
		    
		}
	    }
	});
	// } 
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
	    "wsale-detail.html", undefined, undefined, $scope, payload)
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

	if (angular.isDefined(scan) && scan && $scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
	    // get color, size from barcode
	    // console.log(inv.bcode);
	    // console.log(inv.full_bcode);
	    // console.log(inv.full_bcode.length - inv.bcode.length);
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
	    // save
	    // $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate();
	    $scope.focus_by_element();

	    if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
		updateCallback();
	    // inv.$update = false;
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
		       // valid_sell:   valid_sell,
		       valid:        valid_all_sell,
		       cancel_callback:  function() {
			   $scope.focus_by_element();
		       },
		       right:        $scope.right};
	console.log(payload);
	diabloUtilsService.edit_with_modal(
	    "wsale-order-new.html", modal_size, callback, undefined, payload)
    };

    $scope.save_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;

	// if (inv.amounts[0].sell_count !== inv.sell)
	//     inv.$update_count = true; 
	inv.amounts[0].sell_count = inv.sell;
	
	// save
	// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	if (inv.fprice !== inv.o_fprice || inv.fdiscount !== inv.o_fdiscount) inv.$update = true;

	$scope.re_calculate();
	
	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode();
	
	// inv.$update = false; 
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv);
	// $timeout.cancel($scope.timeout_auto_save);
	// inv.$update = false;
	inv.free_update = false;
	inv.sell      = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode(); 
    };

    $scope.auto_save_free = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	
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
};


function wsaleOrderDetailCtrlProvide(
    $scope, $routeParams, $location, dateFilter, diabloUtilsService,
    localStorageService, diabloFilter, wsaleService,
    user, filterEmployee, base){
    $scope.shops     = user.sortShops.filter(function(s) {return s.deleted===0});
    $scope.shopIds   = user.shopIds;
    $scope.orders   = [];
    $scope.goto_page = diablo_goto_page;

    $scope.setting   = {};

    $scope.total_items   = 0;
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();

    var now = diablo_now_datetime();
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.shop_right = authen.authenSaleRight();

    var storage = localStorageService.get(diablo_key_wsale_order_detail);
    if (angular.isDefined(storage) && storage !== null){
	// console.log(storage);
    	$scope.filters      = storage.filter; 
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else{
	$scope.filters = [];
	$scope.qtime_start = now;
	$scope.qtime_end = now;
    };
    $scope.time = diabloFilter.default_time($scope.qtime_start, $scope.qtime_end);

    $scope.match_retailer = function(viewValue) {
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.shopIds.length === 1 ? $scope.shopIds[0] : [],
	    diablo_no);
    };

    diabloFilter.reset_field();
    diabloFilter.add_field("shop",        $scope.shops);
    diabloFilter.add_field("account",     []); 
    diabloFilter.add_field("employee",    filterEmployee); 
    diabloFilter.add_field("retailer",    $scope.match_retailer); 
    diabloFilter.add_field("rsn",         $scope.match_rsn);
    diabloFilter.add_field("comment",     wsaleService.check_comment);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.do_search = function(page){
	// console.log(page); 
	$scope.current_page = page;
	
	// save condition of query
	wsaleUtils.cache_page_condition(
	    localStorageService,
	    diablo_key_wsale_order_detail,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now); 
	
	if (page !== $scope.default_page) {
	    var stastic = localStorageService.get("wsale-order-stastic");
	    // console.log(stastic);
	    $scope.total_items       = stastic.total_items;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    } 
	    
	    wsaleService.filter_w_sale_order(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1) {
		    $scope.total_items       = result.total; 
		    $scope.orders = [];
		    $scope.save_stastic();
		}
		
		// console.log($scope); 
		angular.forEach(result.data, function(d){
		    d.crsn     = diablo_array_first(d.rsn.split(diablo_date_seprator));
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee); 
		}); 

		$scope.orders = result.data; 
		diablo_order_page(page, $scope.items_perpage, $scope.orders);
	    })
	})
    };

    $scope.save_stastic = function(){
	localStorageService.remove("wsale-order-stastic");
	localStorageService.set(
	    "wsale-order-stastic",
	    {total_items:       $scope.total_items, 
	     t:                 now});
    };

    if ($scope.current_page !== $scope.default_page){
	$scope.do_search($scope.current_page); 
    }
    
    $scope.refresh = function() {
	$scope.do_search($scope.default_page);
    };
    
    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };
    
};

function wsaleOrderNoteCtrlProvide(
    $scope, $routeParams, $location, dateFilter, diabloUtilsService,
    localStorageService, diabloFilter, wsaleService,
    user, filterEmployee, filterBrand, filterType, filterCType, filterFirm, base){
    $scope.shops     = user.sortShops.filter(function(s) {return s.deleted===0});
    $scope.shopIds   = user.shopIds;
    $scope.orders   = [];
    $scope.goto_page = diablo_goto_page;

    $scope.setting   = {};

    $scope.total_items   = 0;
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();

    var now = diablo_now_datetime();
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.shop_right = authen.authenSaleRight();

    var storage = localStorageService.get(diablo_key_wsale_order_note);
    if (angular.isDefined(storage) && storage !== null){
	// console.log(storage);
    	$scope.filters      = storage.filter; 
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else{
	$scope.filters = [];
	$scope.qtime_start = now;
	$scope.qtime_end = now;
    };
    $scope.time = diabloFilter.default_time($scope.qtime_start, $scope.qtime_end);

    $scope.match_retailer = function(viewValue) {
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.shopIds.length === 1 ? $scope.shopIds[0] : [],
	    diablo_no);
    };

    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number); 
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("type",     filterType); 
    diabloFilter.add_field("ctype",    filterCType);
    diabloFilter.add_field("sex",      diablo_sex2object);
    diabloFilter.add_field("season",   diablo_season2objects);
    diabloFilter.add_field("year",     diablo_full_year); 
    diabloFilter.add_field("firm",     filterFirm); 
    diabloFilter.add_field("shop",     $scope.shops); 
    diabloFilter.add_field("retailer", function(viewValue){
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.shopIds.length === 1 ? $scope.shopIds[0] : [],
	    $scope.setting.solo_retailer)
    });
    
    diabloFilter.add_field("employee",  filterEmployee);
    diabloFilter.add_field("account",   []);
    diabloFilter.add_field("rsn",       $scope.match_rsn);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.do_search = function(page){
	// console.log(page); 
	$scope.current_page = page;
	
	// save condition of query
	wsaleUtils.cache_page_condition(
	    localStorageService,
	    diablo_key_wsale_order_note,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now); 
	
	if (page !== $scope.default_page) {
	    var stastic = localStorageService.get("wsale-order-note-stastic");
	    $scope.total_items       = stastic.total_items;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    } 
	    
	    wsaleService.filter_w_sale_order_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1) {
		    $scope.total_items       = result.total; 
		    $scope.orders = [];
		    $scope.save_stastic();
		}
		
		// console.log($scope); 
		angular.forEach(result.data, function(d){
		    d.crsn     = diablo_array_first(d.rsn.split(diablo_date_seprator));
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.brand    = diablo_get_object(d.brand_id, filterBrand);
		    d.type     = diablo_get_object(d.type_id, filterType);
		}); 

		$scope.orders = result.data; 
		diablo_order_page(page, $scope.items_perpage, $scope.orders);
	    })
	})
    };

    $scope.save_stastic = function(){
	localStorageService.remove("wsale-order-note-stastic");
	localStorageService.set(
	    "wsale-order-note-stastic",
	    {total_items:       $scope.total_items, 
	     t:                 now});
    };

    if ($scope.current_page !== $scope.default_page){
	$scope.do_search($scope.current_page); 
    }
    
    $scope.refresh = function() {
	$scope.do_search($scope.default_page);
    };
    
    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };
    
};

define (["wsaleApp"], function(app){
    app.controller("wsaleOrderNewCtrl", wsaleOrderNewCtrlProvide);
    app.controller("wsaleOrderDetailCtrl", wsaleOrderDetailCtrlProvide);
    app.controller("wsaleOrderNoteCtrl", wsaleOrderNoteCtrlProvide); 
});
