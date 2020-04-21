'use strict'

function purchaserOrderNewCtrlProvide (
    $scope, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, shortCutGoodService,
    localStorageService, user, filterBrand, filterType,
    filterSizeGroup, filterFirm, filterEmployee, filterColor, filterColorType,
    filterStdExecutive, filterCategory, filterFabric, base){
    
    // console.log(ERROR); 
    // console.log(user); 
    $scope.brands      = filterBrand;
    $scope.types       = filterType;
    $scope.size_groups = angular.copy(filterSizeGroup);
    diablo_order($scope.size_groups);
    $scope.firms       = filterFirm;
    $scope.colors      = filterColor;
    $scope.color_types = filterColorType;
    $scope.grouped_colors = []; 
    $scope.base_settings = {};

    
    $scope.tab_active  = [{active:false}, {active:true}, {active:false}]; 
    $scope.shops             = user.sortShops; 
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    
    $scope.levels            = diablo_level;
    $scope.std_executives    = filterStdExecutive;
    $scope.categories        = filterCategory;
    $scope.fabrics           = filterFabric;
    $scope.waynodes          = diablo_waynodes; 

    $scope.season2objs       = diablo_season2objects;
    $scope.sex2objs          = diablo_sex2object; 
    $scope.float_add         = diablo_float_add;
    $scope.float_sub         = diablo_float_sub;
    $scope.float_mul         = diablo_float_mul;
    $scope.round             = diablo_round;
    $scope.full_years        = diablo_full_year;
    $scope.std_units         = diablo_std_units;
    $scope.calc_row          = stockUtils.calc_row;
    $scope.yes_no            = stockUtils.yes_no();
    
    $scope.disable_refresh   = true;
    $scope.timeout_auto_save = undefined; 

    $scope.get_prompt_firm = function(prompt){
	return stockUtils.get_prompt_firm(prompt, $scope.firms)};
    
    $scope.today = function(){
	return $.now();
    };
    
    $scope.q_typeahead = function(shopId, base){
	return stockUtils.typeahead(shopId, base); 
    };

    $scope.go_back = function(){
	diablo_goto_page("#/inventory_order_detail");
    };

    $scope.focus_of_inv = {style_number: true, sale:false};
    $scope.auto_focus = function(attr){
	if (!$scope.focus_of_inv[attr]){
	    $scope.focus_of_inv[attr] = true;
	}
	for (var o in $scope.focus_of_inv){
	    if (o !== attr) $scope.focus_of_inv[o] = false;
	}
    };
    
    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight(); 

    $scope.focus_barcode_or_style_number = function() {
	if ($scope.base_settings.hide_barcode)
	    $scope.on_focus_attr("style_number");
	else
	    $scope.on_focus_attr("barcode");
    };

    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.select.total   = 0;
	$scope.select.comment = undefined;
	
	$scope.select.surplus = 0; 
	$scope.disable_refresh = true;
	$scope.has_saved = false;

	if ($scope.tab_active[0].active)
	    $scope.auto_focus("style_number");
	else if ($scope.tab_active[1].active) {
	    $scope.focus_barcode_or_style_number();
	} 
    };

    // init
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.stock_at_first = undefined; 

    $scope.select = {
	shop: $scope.shops.length !== 0 ? $scope.shops[0]:undefined,
	total: 0, 
	date: $scope.today()
    };


    $scope.get_employee = function(){
	var select = stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = select.login;
	$scope.employees = select.filter; 
    }; 
    $scope.get_employee();

    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0.00; 

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    // console.log(one);
	    $scope.select.total  += stockUtils.to_integer(one.total); 
	    $scope.select.should_pay += $scope.calc_row(one.org_price, 100, one.total);
	};
	
	$scope.select.should_pay = stockUtils.to_decimal($scope.select.should_pay); 
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
	    diablo_dkey_stock_order)
    }; 
    var sDraft = gen_draft();
    
    // console.log(sDraft);
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
			// firm: diablo_get_object(p[1], $scope.firms),
			shop:diablo_get_object(parseInt(p[1]), $scope.shops),
		       	// employee:diablo_get_object(p[2], $scope.employees)
			employee:diablo_get_object(p[2], filterEmployee)
		       }
	    });
	};

	var select = function(draft, resource){
	    // $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
	    // console.log(draft);
	    $scope.select.employee = diablo_get_object(draft.employee.id, filterEmployee);
	    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops);
	    $scope.get_employee();
	    // $scope.select.frim = diablo_get_object(draft.firm.id, $scope.firms);
	    $scope.inventories = angular.copy(resource);
	    for (var i=0, l=$scope.inventories.length; i<l; i++){
		var inv = $scope.inventories[i];
		if (diablo_invalid_firm !== inv.firm_id){
		    $scope.select.firm = diablo_get_object(inv.firm_id, $scope.firms);
		    break;
		}
	    }
	    
	    $scope.inventories.unshift({$edit:false, $new:true});
	    $scope.disable_refresh = false;
	    $scope.re_calculate();

	    if ($scope.tab_active[0].active)
		$scope.auto_focus("style_number");
	    else if ($scope.tab_active[1].active)
		$scope.reset_style_number();
	};

	sDraft.select(diabloUtilsService, "stock-order-draft.html", draft_filter, select); 
    };

    // list first draft
    if (sDraft.keys().length !== 0) {
	$scope.list_draft();
    }

    $scope.get_setting = function(shopId){
	$scope.base_settings.m_sgroup = stockUtils.multi_sizegroup(shopId, base);
	$scope.base_settings.t_trace = stockUtils.t_trace(shopId, base);
	$scope.base_settings.group_color = stockUtils.group_color(shopId, base);
	// $scope.base_settings.image_allowed = stockUtils.image_allowed(shopId, base);
	angular.extend($scope.base_settings, stockUtils.stock_in_hide_mode(shopId, base));
	
	console.log($scope.base_settings);
	$scope.base_settings.stock_alarm     = stockUtils.stock_alarm(shopId, base);
	$scope.base_settings.stock_with_firm = stockUtils.stock_mode(shopId, base).check_i_firm;
	$scope.base_settings.auto_barcode    = stockUtils.auto_barcode(shopId, base);
    }

    $scope.change_shop = function(){
	console.log(sDraft.key);
	$scope.get_setting($scope.select.shop.id);
	$scope.get_employee();
	sDraft.change_key(undefined, $scope.select.shop.id, $scope.select.employee.id); 
	$scope.get_employee();
    };

    $scope.get_setting($scope.select.shop.id); 
    $scope.prompt_limit = stockUtils.prompt_limit($scope.select.shop.id, base);

    // calender
    // $scope.open_calendar = function(event){
    // 	event.preventDefault();
    // 	event.stopPropagation();
    // 	$scope.isOpened = true;
    // }; 
    
    /*
     * match
     */
    $scope.match_prompt_good = function(viewValue){
	// console.log(viewValue);
	if (angular.isUndefined(diablo_set_string(viewValue))
	    || viewValue.length < diablo_filter_length) return;
	
	return diabloFilter.match_wgood_with_firm(
	    viewValue,
	    stockUtils.match_firm(
		$scope.base_settings.stock_with_firm ? $scope.select.firm : diablo_invalid_firm)); 
    };

    $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id, base); 
    $scope.qtime_start = function(shopId){
	return stockUtils.start_time(shopId, base, $.now(), dateFilter); 
    };

    $scope.get_good_by_barcode = function(bcode) {
	diabloHelp.scanner(
	    bcode,
	    $scope.base_settings.auto_barcode,
	    $scope.select.shop.id,
	    diabloFilter.get_good_by_barcode,
	    diabloUtilsService,
	    "新增货品",
	    $scope.on_select_good_new,
	    function() {});
	    
	    // diabloFilter.get_good_by_barcode(bcode).then(function(result) {
	    // 	console.log(result);
	    // 	if (result.ecode === 0) {
	    // 	    if (!diablo_is_empty(result.data))
	    // 		$scope.on_select_good_new(result.data);
	    // 	} else {
	    // 	    dialog.set_error("新增货品", result.ecode);
	    // 	}
	    // });
	// }
	
    };
    
    var copy_select = function(add, src){
	add.$new_good    = src.$new_good;
	add.id           = src.id;
	add.bcode        = src.bcode === diablo_empty_db_barcode ? undefined : src.bcode;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.name         = src.style_number + "/" + src.brand + "/" + src.type;
	add.sex          = src.sex;
	add.firm_id      = src.firm_id;
	add.year         = src.year; 
	add.season       = src.season;
	
	// add.pid          = src.pid;
	add.org_price    = src.org_price;
	add.vir_price    = src.vir_price;
	add.tag_price    = src.tag_price;
	add.ediscount    = src.ediscount;
	add.discount     = src.discount;
	
	add.state        = src.state; 
	add.path         = src.path;
	add.alarm_day    = src.alarm_day;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.sizes        = src.size.split(",");
	add.colors       = src.color.split(",");
	// exist stock in shop
	add.stock        = 0;

	add.contailer   = src.contailer;
	add.alarm_a     = src.alarm_a;

	add.unit        = src.unit;
	
	add.level       = src.level;
	add.executive   = src.executive_id;
	add.category    = src.category_id;
	add.fabric      = src.fabric_json;
	add.feather     = src.feather_json;
	
	if ( add.free === 0 ){
	    add.free_color_size = true;
	    add.amount = [{cid:0, size:0}];
	} else{
	    add.free_color_size = false;
	    add.amount = []; 
	}

	return add;
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);
	// console.log($scope.inventories); 
	// has been added
	var existStock = undefined;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		existStock = $scope.inventories[i]; 
	    }
	    
	    // do not check firm 
	    if ($scope.base_settings.stock_with_firm === diablo_no) {
		continue;
	    }

	    if (item.firm_id === -1 || $scope.inventories[i].firm_id === -1) {
		continue;
	    }
	    
	    if (item.firm_id !== $scope.inventories[i].firm_id){
		diabloUtilsService.response_with_callback(
		    false,
		    "新增定单",
		    "新增定单失败：" + purchaserService.error[2093],
		    $scope,
		    function(){
			$scope.inventories[0] = {$edit:false, $new:true};
			if ($scope.tab_active[1].active){
			    $scope.reset_style_number();
			}
		    });
		return;
	    };
	}
	
	if ($scope.base_settings.stock_with_firm === diablo_yes) {
	    if (diablo_invalid_firm !== item.firm_id
		&& diablo_invalid_firm === stockUtils.invalid_firm($scope.select.firm)){
		$scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
	    }
	}
	
	// auto focus
	// $scope.auto_focus("sale");
	
	// add at first allways 
	$scope.stock_at_first = $scope.inventories[0];
	copy_select($scope.stock_at_first, item); 
	console.log($scope.stock_at_first);
	if (angular.isDefined(existStock)) {
	    $scope.update_inventory_with_new(existStock);
	} else {
	    if (!$scope.stock_at_first.free_color_size || $scope.tab_active[1].active){
		$scope.add_inventory($scope.stock_at_first)
	    } else {
		if ($scope.tab_active[0].active) {
		    $scope.auto_focus("sale");
		};
		
		if (diablo_yes === $scope.base_settings.t_trace
		    && (angular.isUndefined($scope.stock_at_first.$new_good)
			|| !$scope.stock_at_first.$new_good) ){
		    purchaserService.get_purchaser_tagprice({
			style_number: $scope.stock_at_first.style_number,
			brand:        $scope.stock_at_first.brand_id,
			shop:         $scope.select.shop.id
		    }).then(function(result){
			console.log(result);
			if (result.ecode === 0){
			    if (!diablo_is_empty(result.data)){
				$scope.stock_at_first.org_price = result.data.org_price;
				$scope.stock_at_first.tag_price = result.data.tag_price;
				$scope.stock_at_first.discount  = result.data.discount;
				$scope.stock_at_first.ediscount = result.data.ediscount;
				$scope.stock_at_first.stock     = result.data.amount;
			    }
			    else {
				if (diablo_yes === $scope.base_settings.price_on_region){
				    $scope.stock_at_first.tag_price = 0;
				    $scope.stock_at_first.discount  = 0;
				} 
			    } 
			}
		    })
		};
	    }
	};
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	return $scope.has_saved || $scope.inventories.length === 1; 
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);

	if (angular.isUndefined($scope.select.shop)
	    || diablo_is_empty($scope.select.shop)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    $scope.has_saved = false;
	    diabloUtilsService.response(
		false,
		"新增采购定单",
		"新增采购定单失败：" + purchaserService.error[2096]);
	    return;
	};

	// check all
	$scope.re_calculate();
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    var select_firm = stockUtils.invalid_firm($scope.select.firm);
	    if (diablo_yes === $scope.base_settings.stock_with_firm
		&& add.firm_id !== diablo_invalid_firm
		&& select_firm !== diablo_invalid_firm
		&& add.firm_id !== select_firm){
		$scope.has_saved = false;
		diabloUtilsService.response(
		    false,
		    "新增采购定单",
		    "新增采购定单失败：["
			+ $scope.select.firm.name + "，"
			+ diablo_get_object(add.firm_id, $scope.firms).name
			+ "]" + purchaserService.error[2093]
		    	+ "款号：" + add.style_number + "！！", 
		    undefined);
		return;
	    };

	    if (angular.isUndefined(add.style_number)){
		diabloUtilsService.response(
		    false,
		    "新增采购定单",
		    "新增采购定单失败：[" 
			+ add.order_id + "]：" + purchaserService.error[2092]
		    	+ "款号：" + add.style_number + "！！", 
		    undefined);
		return;
	    };
	    
	    added.push({
		// good        : add.id,
		order_id    : add.order_id,
		style_number: add.style_number,
		brand       : add.brand_id,
		
		type        : add.type_id,
		sex         : add.sex,
		season      : add.season,
		firm        : add.firm_id,
		s_group     : add.s_group,
		free        : add.free,
		year        : add.year,
		path        : add.path,
		
		org_price   : diablo_set_float(add.org_price),
		tag_price   : diablo_set_float(add.tag_price), 
		ediscount   : diablo_set_float(add.ediscount),
		discount    : diablo_set_float(add.discount), 
		
		amount      : add.amount, 
		total       : add.total,
	    })
	}; 
	
	var base = {
	    firm:          stockUtils.invalid_firm($scope.select.firm), 
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    total:         $scope.select.total,
	    
	    should_pay:    setv($scope.select.should_pay) 
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true;
	// $scope.local_remove();
	// return;
	purchaserService.add_purchaser_order({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		$scope.disable_refresh = false; 
		diabloUtilsService.response_with_callback(
		    true, "新增采购定单", "新增采购定单成功！！单号：" + state.rsn,
		    $scope, function(){
			sDraft.remove();
			$scope.refresh();
		    })
	    } else {
		diabloUtilsService.response_with_callback(
	    	    false,
		    "新增采购定单",
	    	    "新增采购定单失败："
			+ purchaserService.error[state.ecode]
			+ stockUtils.extra_error(state), 
		    undefined,
		    function(){$scope.has_saved = false})
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

    var valid_amount = function(amounts, ediscount){
	var re = diabloPattern.discount;
	if (!re.test(ediscount)) return false;
	
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
    
    var add_callback = function(params){
	// console.log(params);
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
	
	// console.log(new_amount);
	// inv.amount = new_amount;
	var total = 0;
	angular.forEach(new_amount, function(a){
	    total += stockUtils.to_integer(a.count);
	})
	
	return {amount:    new_amount,
		total:     total,
		org_price: params.org_price,
		ediscount: params.ediscount,
		tag_price: params.tag_price,
		discount:  params.discount}; 
    };
    
    $scope.add_inventory = function(inv){
	console.log(inv);
	// var add = $scope.inventories[0]; 
	var after_add = function(){
	    inv.$edit = true;
	    inv.$new = false;
	    // oreder 
	    inv.order_id = $scope.inventories.length;
	    // backup
	    // $scope.local_save();
	    sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	    // add new line
	    // console.log("add new line");
	    $scope.inventories.unshift({$edit:false, $new:true}); 
	    $scope.disable_refresh = false;
	    // reset barcode
	    $scope.good.bcode = undefined;
	    // $scope.good.sprice = $scope.yes_no[0];
	    // $scope.stock_at_first = undefined;
	    $scope.re_calculate();

	    // auto focus
	    if ($scope.tab_active[1].active) {
		$scope.delete_image();
		$scope.reset_style_number()
	    } else {
		$scope.auto_focus("style_number")
	    };
	};
	
	var callback = function(params){
	    var result    = add_callback(params); 
	    inv.amount    = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    // inv.ediscount = result.ediscount;
	    inv.tag_price = result.tag_price; 
	    inv.discount  = result.discount;
	    inv.ediscount = diablo_discount(inv.org_price, inv.tag_price);
	    inv.over      = result.over;
	    after_add();
	} 

	var add_stock = function(){
	    if(inv.free_color_size && $scope.tab_active[0].active){
		inv.total = inv.amount[0].count;
		after_add();
	    } else{
		var modal_size = diablo_valid_dialog(inv.sizes);
		var large_size = modal_size === 'lg' ? true : false
		var payload = {sizes:        inv.sizes,
			       large_size:   large_size,
			       amount:       inv.amount,
			       org_price:    inv.org_price,
			       ediscount:    inv.ediscount,
			       tag_price:    inv.tag_price,
			       discount:     inv.discount,
			       path:         inv.path,
			       stock:        inv.stock,
			       free:         inv.free_color_size, 
			       right:        $scope.stock_right,
			       get_amount:    get_amount,
			       valid_amount:  valid_amount,
			       get_price_info: stockUtils.calc_stock_orgprice_info,
			       add_exist_stock_color: function(close) {
				   if (angular.isFunction(close))
				       close();
				   $scope.add_exist_stock_color(inv, function(stock) {
				       $scope.add_inventory(stock);
				   });
			       },
			       cancel_callback: function() {
				   // reset barcode
				   $scope.good.bcode = undefined;
				   $scope.inventories[0] = {$edit:false, $new:true};
			       }, 
			       edit: function(){
				   diablo_goto_page(
				       "#/good/wgood_update"
					   + "/" + inv.id.toString()
					   + "/" + $scope.select.shop.id.toString()
					   + "/" + diablo_from_stock_new.toString())}
			      };
		
		if (inv.colors.length === 1 && inv.colors[0] === "0"){
		    inv.colors_info = [{cid:0}];
		    payload.colors = inv.colors_info;
		    diabloUtilsService.edit_with_modal(
			"order-new.html", modal_size, callback, undefined, payload)
		} else{
		    inv.colors_info = inv.colors.map(function(cid){
			return diablo_find_color(parseInt(cid), $scope.colors)});
		    
		    payload.colors = inv.colors_info;
		    diabloUtilsService.edit_with_modal(
			"order-new.html", modal_size, callback, undefined, payload);
		} 
	    }
	}; 
	
	if (diablo_yes === $scope.base_settings.t_trace
	    && (!inv.free_color_size || $scope.tab_active[1].active)
	    && (angular.isUndefined(inv.$new_good) || !inv.$new_good) ){
	    purchaserService.get_purchaser_tagprice({
		style_number: inv.style_number,
		brand:        inv.brand_id,
		shop:         $scope.select.shop.id
	    }).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (!diablo_is_empty(result.data)){
			inv.org_price = result.data.org_price;
			inv.tag_price = result.data.tag_price;
			inv.discount  = result.data.discount;
			inv.ediscount = result.data.ediscount;
			inv.stock = result.data.amount;
		    }
		    else {
			if (diablo_yes === $scope.base_settings.price_on_region){
			    inv.tag_price = 0;
			    inv.discount  = 0;
			} 
		    }
		}
		add_stock();
	    })
	} else {
	    add_stock();
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
		break;
	    }
	}

	$scope.inventories.splice(i, 1); 
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}
	
	sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	// recalculate 
	$scope.re_calculate(); 
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:      inv.sizes,
		       amount:     inv.amount,
		       org_price:  inv.org_price,
		       ediscount:  inv.ediscount,
		       tag_price:  inv.tag_price,
		       discount:   inv.discount,
		       right:      $scope.stock_right,
		       colors:     inv.colors_info,
		       path:       inv.path,
		       get_amount: get_amount};
	diabloUtilsService.edit_with_modal(
	    "order-detail.html", undefined, undefined, $scope, payload)
    };


    /*
     * update inventory while stock in
     */
    $scope.update_inventory_with_new = function(inv){
	var callback = function(params){
	    var result    = add_callback(params);
	    inv.amount    = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    // inv.ediscount = result.ediscount;
	    inv.tag_price = result.tag_price;
	    inv.discount  = result.discount;
	    inv.ediscount = stockUtils.ediscount(inv.org_price, inv.tag_price);
	    
	    // save to local
	    // $scope.local_save();
	    sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate();

	    $scope.inventories[0] = {$edit:false, $new:true};

	    $scope.selectColors = [];
	    $scope.good.color = "";

	    // auto focus
	    if ($scope.tab_active[1].active) {
		$scope.delete_image();
		$scope.reset_style_number()
	    } else {
		$scope.auto_focus("style_number")
	    };
	    // if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
	    // 	updateCallback();
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;

	// refresh colors 
	diabloFilter.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result) {
	    if(result.ecode === 0 && !diablo_is_empty(result.data)) {
		if (inv.free_color_size) {
		    inv.colors_info = [{cid:0}];
		} else {		    
		    inv.colors = result.data.color.split(","); 
		    inv.sizes  = result.data.size.split(",");
		    inv.s_group = result.data.s_group;
		    inv.colors_info = inv.colors.map(function(cid){
			return diablo_find_color(parseInt(cid), $scope.colors)});
		}
		
		var payload = {sizes:      inv.sizes,
			       large_size: large_size,
			       amount:     inv.amount,
			       org_price:  inv.org_price,
			       ediscount:  inv.ediscount,
			       tag_price:  inv.tag_price,
			       discount:   inv.discount,
			       over:       inv.over,
			       colors:     inv.colors_info,
			       path:       inv.path,
			       stock:      inv.stock,
			       free:       inv.free_color_size, 
			       right:      $scope.stock_right,
			       get_amount: get_amount,
			       valid_amount: valid_amount,
			       get_price_info: stockUtils.calc_stock_orgprice_info,
			       add_exist_stock_color: function(close) {
				   if (angular.isFunction(close))
				       close();
				   $scope.add_exist_stock_color(
				       inv, function(stock) {$scope.update_inventory_with_new(stock);});
			       }, 
			       cancel_callback: function() {
				   $scope.good.bcode = undefined;
				   $scope.inventories[0] = {$edit:false, $new:true};
			       },
			       edit: function(){
			       	   diablo_goto_page(
			       	       "#/good/wgood_update"
			       		   + "/" + inv.id.toString()
			       		   + "/" + $scope.select.shop.id.toString()
			       		   + "/" + diablo_from_stock_new.toString())}
			       };
		diabloUtilsService.edit_with_modal(
		    "order-new.html", modal_size, callback, undefined, payload);
	    };
	}); 
    };

    $scope.on_select_sprice = function($item, $model, $label) {
	if ($model.id === 1) $scope.good.discount = 100;
    };
    
    $scope.reset_select_color = function() {
	$scope.good.colors=""; 
	$scope.selectColors = [];

	
	angular.forEach($scope.gcolors, function(cs){
	    angular.forEach(cs.colors, function(c){
		if (angular.isDefined(c.select))
		    c.select = false;

		if (angular.isDefined(c.disabled))
		    c.disabled = false;
	    })
	});
	
	if (diablo_no === $scope.base_settings.group_color){
	    for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
		for (var j in $scope.grouped_colors[i]){
		    if (angular.isDefined($scope.grouped_colors[i][j].select))
			$scope.grouped_colors[i][j].select = false;
		    
		    if (angular.isDefined($scope.grouped_colors[i][j].disabled))
			$scope.grouped_colors[i][j].disabled = false;
		}
	    }
	};
    };
    
    $scope.add_exist_stock_color = function(inv, afterAddColorCallback) {
	var callback = function() {
	    var update_good = {};
	    update_good.good_id = inv.id;
	    update_good.o_style_number = inv.style_number;
	    update_good.o_brand        = inv.brand_id;
	    update_good.shop           = $scope.select.shop.id;
	    update_good.color = $scope.selectColors.map(function(c) {
		return c.id
	    }).toString();

	    diabloFilter.update_purchaser_good(update_good, undefined).then(function(result) {
		if (result.ecode === 0) {
		    $scope.reset_select_color();
		    inv.colors = update_good.color.split(",");
		    if (angular.isFunction(afterAddColorCallback))
			afterAddColorCallback(inv) 
		} else{
		    diabloUtilsService.set_error("修改货品", result.ecode);
		}
	    }) 
	};

	if ($scope.base_settings.group_color) {
	    $scope.select_color(callback, inv.colors);
	} else {
	    $scope.select_grouped_color(callback, inv.colors); 
	}
    };

    // $scope.add_exist_stock_size = function(inv) {
	
    // };
    
    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	// console.log(inv);
	inv.$update = true;
	inv.o_org_price = inv.org_price;
	inv.o_ediscount = inv.ediscount;
	inv.o_tag_price = inv.tag_price;
	inv.o_discount  = inv.discount;
	
	if (inv.free_color_size){
	    inv.update_directory = true;
	    return; 
	}
	
	var callback = function(params){
	    var result    = add_callback(params);
	    inv.amount    = result.amount;
	    inv.total     = result.total;
	    inv.org_price = result.org_price;
	    // inv.ediscount = result.ediscount;
	    inv.tag_price = result.tag_price;
	    inv.discount  = result.discount;
	    inv.ediscount = stockUtils.ediscount(inv.org_price, inv.tag_price);
	    
	    // save to local
	    // $scope.local_save();
	    sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate();

	    // if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
	    // 	updateCallback();
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;

	// refresh colors 
	diabloFilter.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand_id}
	).then(function(result) {
	    if(result.ecode === 0 && !diablo_is_empty(result.data)) {
		inv.colors = result.data.color.split(",");
		inv.sizes  = result.data.size.split(",");
		inv.s_group = result.data.s_group;
		inv.colors_info = inv.colors.map(function(cid){
		    return diablo_find_color(parseInt(cid), $scope.colors)});

		var payload = {sizes:      inv.sizes,
			       large_size: large_size,
			       amount:     inv.amount,
			       org_price:  inv.org_price,
			       ediscount:  inv.ediscount,
			       tag_price:  inv.tag_price,
			       discount:   inv.discount,
			       colors:     inv.colors_info,
			       path:       inv.path,
			       stock:      inv.stock,
			       right:      $scope.stock_right,
			       free:       inv.free_color_size,
			       get_amount: get_amount,
			       valid_amount: valid_amount,
			       get_price_info: stockUtils.calc_stock_orgprice_info,
			       add_exist_stock_color: function(close) {
				   if (angular.isFunction(close))
				       close();
				   $scope.add_exist_stock_color(inv, function(stock) {
				       $scope.update_inventory(stock)
				   });
			       },
			       cancel_callback: function() {
				   $scope.good.bcode = undefined;
				   $scope.inventories[0] = {$edit:false, $new:true};
			       },
			       edit: function(){
				   diablo_goto_page(
				       "#/good/wgood_update"
					   + "/" + inv.id.toString()
					   + "/" + $scope.select.shop.id.toString()
					   + "/" + diablo_from_stock_new.toString())}
			      };
		diabloUtilsService.edit_with_modal(
		    "order-new.html", modal_size, callback, undefined, payload);
	    };
	}); 
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.$update          = false;
	inv.update_directory = false; 
	inv.total            = inv.amount[0].count; 
	sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate()

    };

    $scope.cancel_free_update = function(inv){
	console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.update_directory = false;
	inv.$update          = false;
	inv.org_price        = inv.o_org_price;
	inv.ediscount        = inv.o_ediscount;
	inv.tag_price        = inv.o_tag_price;
	inv.discount         = inv.o_discount;
	inv.amount[0].count  = inv.total; 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};
	$scope.auto_focus("style_number");
    }

    $scope.auto_save_free = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);

	if (angular.isUndefined(inv.amount[0].count)
	    || !inv.amount[0].count
	    || parseInt(inv.amount[0].count) === 0
	    || angular.isUndefined(inv.style_number)
	    || angular.isUndefined(inv.ediscount)
	    || angular.isUndefined(inv.org_price)
	    || angular.isUndefined(inv.tag_price)
	    || angular.isUndefined(inv.discount) ){
	    return;
	}

	if (angular.isDefined(inv.form.ediscount) && inv.form.ediscount.$invalid)
	    return   
	
	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_inventory(inv);
	    }

	    if (!inv.$new && inv.update_directory){
		$scope.save_free_update(inv) 
	    }
	}, 1000); 
    };

    /*
     * good new
     */ 
    $scope.pattern = {style_number: diabloPattern.style_number,
		      brand: diabloPattern.ch_en_num,
		      type:  diabloPattern.good_type,
		      expire: diabloPattern.expire_date,
		      percent: diabloPattern.percent,
		      barcode: diabloPattern.number};

    $scope.focus_attrs = {
	barcode: false,
	style_number:false,
	brand:false,
	type:false, 
	vir_price:false,
	tag_price:false,
	discount:false,
	color:false,
	size:false,
	expire: false,
	ok:false};
    $scope.on_focus_attr = function(attr){
	stockUtils.on_focus_attr(attr, $scope.focus_attrs);
    };

    $scope.go_next_good_field = function(direct, attr){
	// console.log(direct, attr)
	if (angular.isDefined(attr)) $scope.on_focus_attr(attr);
    }

    $scope.select_tab_of_new_good = function(){
	$scope.focus_of_inv.style_number=false;
	// $scope.on_focus_attr("style_number");
	$scope.focus_barcode_or_style_number();
	console.log($scope.focus_attrs); 
    };

    $scope.on_select_good_new = function(item, model, label){
	console.log(item);
	$scope.good.$new_good = false;
	$scope.good.bcode = item.bcode === diablo_empty_db_barcode ? undefined : item.bcode;
	$scope.good.style_number = item.style_number;
	$scope.good.type  = item.type;
	$scope.good.brand = item.brand;
	$scope.good.sex   = $scope.sex2objs[item.sex];
	$scope.good.year  = item.year;
	$scope.good.season    = $scope.season2objs[item.season];
	$scope.good.tag_price = item.tag_price;
	$scope.good.discount  = item.discount;

	if ($scope.tab_active[1].active){
	    $scope.on_select_good(item, model, label); 
	} 
    };

    $scope.is_same_good = false;
    
    /*
     * color
     */
    // $scope.gcolors = [{type:"红色", tid:1
    // 		  colors:[{name:"深红", id:1},
    // 			  {name:"粉红", id:2}]},
    // 		 {type:"蓝色", tid:2
    // 		  colors:[{name:"深蓝", id:3},
    // 			  {name:"浅蓝", id:4}]}, 
    
    // 		];

    $scope.gcolors = [];
    var dialog = diabloUtilsService;

    var in_sys_color = function(syscolors, color){
	for(var i=0, l=syscolors.length; i<l; i++){
	    if(syscolors[i].tid === color.tid){
		syscolors[i].colors.push(
		    {name: color.name, id:color.id});
		return true;
	    }
	} 
	return false;
    };
    
    angular.forEach($scope.colors, function(color){
    	if (!in_sys_color($scope.gcolors, color)){
    	    $scope.gcolors.push(
    		{type:color.type, tid:color.tid,
    		 colors:[{name:color.name, id:color.id}]})
    	}
    });

    // console.log($scope.colors);

    var max_color = diablo_max_color_per_line;
    var color_range = [0].concat(diablo_range(max_color - 1));
    $scope.group_color_with_8 = function(){
	var color = {};
	// var oldGroupedColors = angular.copy($scope.grouped_colors);
	
	$scope.grouped_colors = [];
	for (var i=0, g=0, l=$scope.colors.length; i<l; i++){
	    var gc = $scope.colors[i];
	    var addedColor = {id:gc.id, name:gc.name, py:diablo_pinyin(gc.name)} 
	    
	    if (i <= (g+1)*max_color - 1){
		color[(i - g * max_color).toString()] = addedColor;
	    } 
	    if (i === (g+1) * max_color){
		$scope.grouped_colors.push(color);
		g++;
		color = {};
		color[(i - g * max_color).toString()] = addedColor;
	    }
	} 
	$scope.grouped_colors.push(color); 
    };

    if (diablo_no === $scope.base_settings.group_color){
	$scope.group_color_with_8(); 
    }
    
    $scope.new_color = function(afterAddCallback){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    diabloFilter.add_purchaser_color(color).then(function(state){
		console.log(state);
		
		var append_color = function(newColorId){
		    var newColor = {
			id:      newColorId,
			name:    params.color.name,
			tid:     params.color.type.id,
			type:    params.color.type.name
			// remark:  params.color.remark
		    };

		    $scope.colors.push(newColor);
		    // console.log($scope.colors); 
		    if (!in_sys_color($scope.gcolors, newColor)){
			$scope.gcolors.push(
			    {type: newColor.type,
			     tid:  newColor.tid,
			     colors:[{name:newColor.name, id:newColor.id}]}); 
		    }

		    // reset filter color
		    diabloFilter.reset_color();
		    
		    if (diablo_no === $scope.base_settings.group_color){
			$scope.group_color_with_8(); 
		    }

		    if (angular.isFunction(afterAddCallback))
			afterAddCallback();
		}; 
		
		if (state.ecode == 0){
		    append_color(state.id); 
		} else{
		    dialog.set_error("新增颜色", state.ecode);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html',
	    undefined,
	    callback,
	    undefined,
	    {color: {types: $scope.color_types}});
    };

    $scope.select_color = function(afterSelectCallback, disabledColors){
	angular.forEach(disabledColors, function(colorId) {
	    for (var i=0, l1=$scope.gcolors.length; i<l1; i++) {
		angular.forEach($scope.gcolors[i].colors, function(c) {
		    if (stockUtils.to_integer(colorId) === c.id) {
			c.select = true;
			c.disabled = true;
		    } 
		}) 
	    }
	});
	
	var callback = function(params){
	    // console.log(params.colors); 
	    $scope.selectColors = []; 
	    $scope.good.colors="";
	    angular.forEach(params.colors, function(colorInfo){
		angular.forEach(colorInfo.colors, function(color){
		    if(angular.isDefined(color.select) && color.select){
			$scope.good.colors += color.name + "；";
			$scope.selectColors.push(angular.copy(color));
		    }
		})
	    }); 
	    console.log($scope.selectColors); 
	    // save select info
	    $scope.gcolors = angular.copy(params.colors);

	    if (angular.isFunction(afterSelectCallback))
		afterSelectCallback();
	}; 
	
	diabloUtilsService.edit_with_modal("select-color.html", 'lg', callback, $scope, {colors:$scope.gcolors});
    };

    $scope.select_grouped_color = function(afterSelectCallback, disabledColors){
	if (angular.isArray(disabledColors)) {
	    angular.forEach(disabledColors, function(colorId) {
		for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
		    for (var j in $scope.grouped_colors[i]){
			var c = $scope.grouped_colors[i][j];
			if (stockUtils.to_integer(colorId) === c.id) {
			    c.select = true;
			    c.disabled = true; 
			}
		    }
		} 
	    });
	}
	
	var callback = function(params){
	    $scope.good.colors=""; 
	    $scope.selectColors = [];

	    for (var i=0, l1=params.colors.length; i<l1; i++){
		for (var j in params.colors[i]){
		    var c = params.colors[i][j];
		    if(angular.isDefined(c.select) && c.select){
			$scope.good.colors += c.name + "；";
			$scope.selectColors.push(angular.copy(c));
		    }
		}
	    }
	    
	    console.log($scope.selectColors); 
	    $scope.grouped_colors = angular.copy(params.colors);

	    if (angular.isFunction(afterSelectCallback))
		afterSelectCallback();

	    document.getElementById("n-select-color").focus();
	    
	}; 

	var on_select_ucolor = function(item, model, label){
	    item.select = true; 
	};
	
	diabloUtilsService.edit_with_modal(
	    "select-grouped-color.html",
	    'lg',
	    callback,
	    undefined,
	    {colors:$scope.grouped_colors,
	     color_range:color_range,
	     ucolors: function(){
		 var ucolors = [];
		 for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
		     for (var j in $scope.grouped_colors[i]){
			 ucolors.push($scope.grouped_colors[i][j]); 
		     }
		 }

		 return ucolors;
	     }(),
	     add_color: function(close) {
		 if (angular.isFunction(close))
		     close();
		 
		 $scope.new_color(function() {
		     $scope.select_grouped_color(afterSelectCallback, disabledColors)
		 });
	     },
	     on_select_ucolor: on_select_ucolor});
    };
    
    /*
     * size group
     */
    $scope.free_size = function() {
	$scope.good.sizes = diablo_empty_string;
	$scope.selectGroups = [];
    };

    $scope.select_group = function(groups, g){
	for(var i=0, l=groups.length; i<l; i++){
	    if (groups[i].id !== g.id && diablo_no === $scope.base_settings.m_sgroup){
		groups[i].select = false;
	    }
	}
    };
    
    $scope.on_select_group_short = function(size, groups) {
	if (size) {
	    for(var i=0, l=groups.length; i<l; i++) {
		if (groups[i].id === size.id) {
		    if (angular.isDefined(groups[i].select))
			groups[i].select = !groups[i].select;
		    else
			groups[i].select = true;

		    if (groups[i].select) $scope.select_group(groups, groups[i]);
		}
	    }
	} 
    };

    $scope.select_size = function(){
	var callback = function(params){
	    console.log(params.groups);	    
	    $scope.selectGroups = [];
	    $scope.good.sizes = "";
	    angular.forEach(params.groups, function(g){
		if (angular.isDefined(g.select) && g.select){
		    $scope.good.sizes += g.name + "；";
		    $scope.selectGroups.push(angular.copy(g));
		}
	    }); 
	    console.log($scope.selectGroups); 
	    $scope.size_groups = params.groups;
	    // focus
	    document.getElementById("n-select-size").focus();
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-size.html", 'lg',
	    callback,
	    $scope,
	    {groups: $scope.size_groups});
    };

    /*
     * select fabric
     */
    $scope.select_fabric = function() {
	var callback = function(params) {
	    console.log(params.composites);
	    var cs = params.composites; 
	    // check
	    for (var i=0, l=cs.length; i<l; i++) {
		var c = cs[i];
		if ( (angular.isUndefined(c.fabric) && 0 !== stockUtils.to_float(c.percent))
		     || (angular.isDefined(c.fabric) && 0 === stockUtils.to_float(c.percent)) ) {
		    dialog.response(
			false, "新增货品", "新增货品失败：" + purchaserService.error[2060]);
		    return;
		}
	    };

	    $scope.good.fabrics = cs.filter(function(c) {
		return angular.isDefined(c) && 0 !== stockUtils.to_float(c.percent);
	    });

	    $scope.good.fabric_desc = diablo_empty_string;
	    angular.forEach($scope.good.fabrics, function(f) {
		$scope.good.fabric_desc += f.fabric + ":" + f.percent.toString();
	    });

	    // console.log($scope.good.fabric_desc);
	};
	
	dialog.edit_with_modal(
	    "select-fabric.html",
	    undefined,
	    callback,
	    undefined,
	    {composites:function(){
		if(angular.isDefined($scope.good.fabrics)
		   && angular.isArray($scope.good.fabrics)
		   && $scope.good.fabrics.length > 0) {
		    angular.forEach($scope.good.fabrics, function(f) {
			f.way = diablo_get_object(f.way.id, $scope.waynodes);
		    });
		} 
		return $scope.good.fabrics;
	    }(),
	     
	     add_composite: function(composites, waynodes) {
		 composites.push({fabric:undefined, way:waynodes[0], percent:undefined});
	     },
	     
	     delete_composite: function(composites) {
		 composites.splice(-1, 1);
	     },
	     fabrics:   $scope.fabrics,
	     waynodes:  $scope.waynodes,
	     p_percent: $scope.pattern.percent});
    };

    $scope.select_feather = function() {
	var callback = function(params) {
	    console.log(params.composites);
	    var fs = params.composites; 
	    // check
	    for (var i=0, l=fs.length; i<l; i++) {
		var f = fs[i];
		if ( stockUtils.to_float(f.wsize) === 0 || stockUtils.to_float(f.weight) === 0 ) {
		    dialog.set_error("新增货品", 2059); 
		    return;
		}
	    };

	    $scope.good.feathers = fs.filter(function(f) {
		return angular.isDefined(f)
		    && 0 !== stockUtils.to_float(f.wsize)
		    && 0 !== stockUtils.to_float(f.weight)
		
	    });

	    $scope.good.feather_desc = diablo_empty_string;
	    angular.forEach($scope.good.feathers, function(f) {
		$scope.good.feather_desc += f.wsize.toString() + ":" + f.weight.toString();
	    });

	    // console.log($scope.good.fabric_desc);
	};
	
	dialog.edit_with_modal(
	    "select-feather.html",
	    undefined,
	    callback,
	    undefined,
	    {composites:$scope.good.feathers,
	     add_composite: function(composites) {
		 composites.push({wsize:undefined, weight:undefined});
	     },
	     delete_composite: function(composites) {
		 composites.splice(-1, 1);
	     },
	    });
    };

    /*
     * image
     */ 
    $scope.delete_image = function(){
	$scope.good.image = undefined;
    };

    /*
     * good amount
     */ 
    /*
     * new good
     */
    var current_month = new Date().getMonth();
    $scope.form = {};
    $scope.good_saving = false; 
    $scope.good = {
	// bcode     : undefined,
	sex       : $scope.sex2objs[stockUtils.d_sex($scope.select.shop.id, base)],
	vir_price : 0,
	org_price : 0, 
	tag_price : 0, 
	ediscount : 0,
	discount  : 100,
	sprice    : $scope.yes_no[0],
	alarm_day : -1,
	year      : diablo_now_year(),
	season    : $scope.season2objs[stockUtils.valid_season(current_month)],
	image     : undefined,
	contailer : -1,
	alarm_a   : $scope.base_settings.stock_alarm_a,
	
	level     : $scope.base_settings.hide_level ? undefined : $scope.levels[1],
	executive : $scope.base_settings.hide_executive ? undefined : $scope.std_executives[0],
	category  : $scope.base_settings.hide_category ? undefined : $scope.categories[0],
	fabrics   : $scope.base_settings.hide_fabric ? undefined : [],
	feathers  : $scope.base_settings.hide_feather ? undefined : [],

	unit      : $scope.base_settings.hide_unit ? undefined : $scope.std_units[0]
	// d_image   : true
    };
    // console.log($scope.good);
    

    $scope.new_good = function(){
	// console.log($scope.good);
	if ($scope.form.gForm.$invalid || $scope.is_same_good || $scope.good_has_saved) return; 

	$scope.good_saving = true; 
	// var good       = angular.copy($scope.good);
	var good       = {};
	good.bcode      = diablo_set_string($scope.good.bcode);
	good.style_number = diablo_trim($scope.good.style_number);
	good.brand = typeof($scope.good.brand)==="object" ? $scope.good.brand.name:$scope.good.brand; 
	good.type =  typeof($scope.good.type)==="object" ? $scope.good.type.name: $scope.good.type;
	good.type = diablo_trim(good.type);
	good.type_py = diablo_pinyin(good.type);
	good.sex  = $scope.good.sex.id;
	good.year = $scope.good.year; 
	good.firm = stockUtils.invalid_firm($scope.select.firm);
	good.season    = $scope.good.season.id; 
	good.alarm_day = $scope.good.alarm_day;

	good.org_price = $scope.good.org_price;
	good.vir_price = $scope.good.vir_price;
	good.tag_price = $scope.good.tag_price;
	good.discount  = $scope.good.discount; 
	good.ediscount = $scope.good.ediscount;
	good.sprice    = stockUtils.get_object_id($scope.good.sprice);
	
	good.contailer = $scope.good.contailer;
	good.alarm_a   = $scope.good.alarm_a;

	good.unit  = angular.isDefined($scope.good.unit) ? $scope.std_units.indexOf($scope.good.unit) : undefined;
	
	good.level     = angular.isDefined($scope.good.level) ? $scope.levels.indexOf($scope.good.level) : undefined;
	good.executive = angular.isObject($scope.good.executive)  ? $scope.good.executive.id : undefined;
	good.category  = angular.isObject($scope.good.category) ? $scope.good.category.id : undefined;

	good.fabric    = function() {
	    if (!$scope.base_settings.hide_fabric
		&& angular.isArray($scope.good.fabrics) && $scope.good.fabrics.length !== 0) {
		var cs = $scope.good.fabrics.map(function(f){
		    return {
			f:stockUtils.get_object_by_name(f.fabric, $scope.fabrics).id,
			w:f.way.id,
			p:f.percent};
		});
		// console.log(cs); 
		return angular.toJson(cs);
	    } else {
		return undefined;
	    }
	}();

	good.feather    = function() {
	    if (!$scope.base_settings.hide_feather
		&& angular.isArray($scope.good.feathers) && $scope.good.feathers.length !== 0) {
		var fs = $scope.good.feathers.map(function(f){
		    return {m:f.wsize, w:f.weight};
		});
		// console.log(cs); 
		return angular.toJson(fs);
	    } else {
		return undefined;
	    }
	}();
	
	// good.promotion = good.promotion.id; 
	
	good.colors   = function(){
	    if (angular.isDefined($scope.selectColors) && $scope.selectColors.length > 0){
		var colors = [];
		angular.forEach($scope.selectColors, function(color){
		    colors.push(color.id)
		});
		return colors;
	    } else{
		return undefined;
	    }
	}();

	var s_groups = [];
	var s_sizes  = [];
	good.sizes = function(){
	    if (angular.isDefined($scope.selectGroups) && $scope.selectGroups.length > 0){
		var groups = [];
		angular.forEach($scope.selectGroups, function(group){
		    s_groups.push(group.id);
		    groups.push({id:group.id, group:function(){
			var validSize = [];
			for(var i=0, l=diablo_sizegroup.length; i<l; i++){
	    		    var k = diablo_sizegroup[i];
			    var s = group[k];
	    		    if(s){
				validSize.push(s);
				if (!in_array(s_sizes, s)){
				    s_sizes.push(s)
				}
			    }
	    		}
			return validSize;
		    }()})
		});
		return groups;
	    } else{
		return undefined;
	    }
	}();
	
	console.log(good);
	var image  = function() {
	    if (angular.isDefined($scope.good.image) && $scope.good.image){
		return $scope.good.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "")
	    }
	    return undefined; 
	}();

	var add_purchaser_good = function() {
	    diabloFilter.add_purchaser_good(good, image).then(function(state){
		console.log(state);
		$scope.good_saving = false;
		if (state.ecode == 0){
		    $scope.reset_select_color();
		    /*
		     * add prompt
		     */
		    var in_prompts = function(prompts, item){
			for(var i=0, l=prompts.length; i<l; i++){
			    if (prompts[i].name === item){
				return true;
			    }
			};
			return false;
		    };
		    
		    // brand
		    if (!in_prompts($scope.brands, good.brand)){
			$scope.brands.push({
			    // id   :$scope.brands.length + 1,
			    id   :state.brand,
			    name :good.brand,
			    py   :diablo_pinyin(good.brand)});
			diabloFilter.reset_brand();
		    }; 
		    // console.log($scope.brands);

		    // type
		    if (!in_prompts($scope.types, good.type)){
			$scope.types.push({
			    id   :state.type,
			    name :good.type,
			    py   :good.type_py});
			diabloFilter.reset_type();
		    };

		    // cons.log($scope.types); 
		    var sg = s_groups.length === 0 ? "0":s_groups.toString();
		    var ss = s_sizes.length === 0 ? "0":s_sizes.toString();
		    var sc = angular.isUndefined(good.colors) ? "0" : good.colors.toString();
		    var free = (sg === "0" && ss === "0" && sc === "0") ? 0:1;
		    var p = stockUtils.prompt_name(good.style_number, good.brand, good.type);
		    
		    var agood = {
			$new_good   : true,
			id          : state.db,
			bcode       : good.bcode,
			style_number: good.style_number,
			brand:     good.brand,
			brand_id:  state.brand,
			type:      good.type,
			type_id:   state.type,
			name:      p.name,
			prompt:    p.prompt,
			sex:       good.sex,
			firm_id:   stockUtils.invalid_firm(good.firm),
			year:      good.year,
			season:    good.season,
			org_price: good.org_price,
			vir_price: good.vir_price,
			tag_price: good.tag_price,
			ediscount: good.ediscount,
			state:     stockUtils.to_integer(good.sprice) === 1 ? 3 : diablo_invalid_index,
			discount:  good.discount,
			alarm_day: good.alarm_day,
			path:      state.path,

			free:      free,
			s_group:   sg,
			size:      ss,
			color:     sc,

			contailer: good.contailer,
			alarm_a:   good.alarm_a,

			unit     : good.unit,
			
			level:        good.level,
			executive_id: good.executive,
			category_id:  good.category,
			fabric_json:  good.fabric,
			feather_json: good.feather
		    };
		    
		    // $scope.focus.style_number = true;
		    $scope.on_select_good(agood, undefined, undefined); 
		} else{
		    var ERROR = require("diablo-error"); 
		    diabloUtilsService.response_with_callback(
			false,
			"新增货品",
			"新增货品 ["
			    +  good.style_number + "-" + good.brand + "-"
			    +  good.type + "] 失败："
			    +  ERROR[state.ecode],
			undefined,
			function() {
			    $scope.good_saving = false;
			});
		}
	    });
	}
	
	// console.log(image);
	if (angular.isDefined(good.bcode) && good.bcode
	    && good.bcode !== diablo_empty_barcode
	    && good.bcode !== diablo_empty_db_barcode) {
	    if (good.bcode.length !== diablo_std_barcode_length) {
		diabloUtilsService.response_with_callback(
	    	    false,
		    "新增货品",
	    	    "新增货品失败：" + purchaserService.error[2073],
		    undefined,
		    function(){$scope.good_saving =false; $scope.focus_barcode_or_style_number()});
	    } else {
		add_purchaser_good();
	    }
	} else {
	    add_purchaser_good();
	} 
    };

    $scope.reset_barcode = function() {
	$scope.focus_barcode_or_style_number();
    }
    
    $scope.reset_style_number = function(){
	// $scope.on_focus_attr("style_number");
	$scope.focus_barcode_or_style_number();
	$scope.is_same_good = false;
    };
    
    $scope.reset_brand = function(){
	$scope.on_focus_attr("brand");
	$scope.good.brand = undefined;
	$scope.is_same_good = false;
	$scope.form.gForm.brand.$pristine = true;
    };

    $scope.delete_w_good = function() {
	console.log($scope.stock_at_first);
	if (angular.isUndefined($scope.stock_at_first) || !angular.isObject($scope.stock_at_first)) {
	    dialog.set_error("删除货品资料", 2080);
	} else {
	    var style_number = $scope.stock_at_first.style_number, brand = $scope.stock_at_first.brand_id;
	    if (angular.isUndefined(style_number) || angular.isUndefined(brand)) {
		dialog.set_error("删除货品资料", 2080);
	    } else {
		var stock_in_use = false;
		for(var i=1, l=$scope.inventories.length; i<l; i++){
		    if (style_number === $scope.inventories[i].style_number
			&& brand  === $scope.inventories[i].brand_id){
			stock_in_use = true;
			break;
		    }
		}
		if (stock_in_use) {
		    dialog.set_error("删除货品资料", 2081);
		} else {
		    diabloFilter.delete_purchaser_good(style_number, brand).then(function(result){
			console.log(result);
			if (result.ecode === 0){
			    dialog.response(
				true,
				"删除货品",
				"货品资料 ["
				    + $scope.stock_at_first.style_number
				    + "-" + $scope.stock_at_first.brand
				    + "-" + $scope.stock_at_first.type + " ]删除成功！！",
				undefined)
			} else {
			    dialog.set_error("删除货品资料", result.ecode);
			}
		    })
		} 
	    } 
	} 
    };
    
    $scope.reset = function(){
	$scope.selectGroups = [];
	$scope.selectColors = [];
	$scope.is_same_good = false;
	$scope.good_saving  = false; 
	$scope.good = {
	    brand:     $scope.good.brand,
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.season2objs[stockUtils.valid_season(current_month)],
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price, 
	    ediscount: $scope.good.ediscount, 
	    discount:  $scope.good.discount,
	    alarm_day: -1,
	    
	    image: undefined, 
	    contailer : -1,
	    
	    level     : $scope.base_settings.hide_level ? undefined : $scope.levels[1],
	    executive : $scope.base_settings.hide_executive ? undefined : $scope.std_executives[0],
	    category  : $scope.base_settings.hide_category ? undefined : $scope.categories[0],
	    fabrics   : $scope.base_settings.hide_fabric ? undefined : [],
	    feathers  : $scope.base_settings.hide_feather ? undefined : [],

	    unit      : $scope.base_settings.hide_unit ? undefined : $scope.std_units[0] 
	};

	$scope.form.gForm.style_number.$pristine = true;
	$scope.form.gForm.brand.$pristine = true;
	$scope.form.gForm.type.$pristine = true;
	$scope.form.gForm.tag_price.$pristine = true; 
	$scope.form.gForm.discount.$pristine  = true; 
	$scope.focus_barcode_or_style_number();
    };
};

define (["purchaserApp"], function(app){
    app.controller("purchaserOrderNewCtrl", purchaserOrderNewCtrlProvide); 
});
