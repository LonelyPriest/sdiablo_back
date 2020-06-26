'use strict'

function purchaserInventoryNewCtrlProvide (
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
    $scope.extra_pay_types   = purchaserService.extra_pay_types;
    
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
	diablo_goto_page("#/inventory_new_detail");
    };

    $scope.focus_of_inv = {style_number: true, sale:false};
    $scope.auto_focus = function(attr){
	// console.log(attr);
	if (!$scope.focus_of_inv[attr]){
	    $scope.focus_of_inv[attr] = true;
	}
	for (var o in $scope.focus_of_inv){
	    if (o !== attr) $scope.focus_of_inv[o] = false;
	}

	// console.log($scope.focus_of_inv);
    };
    
    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight(); 

    $scope.$watch("select.firm", function(newValue, oldValue){
	if (newValue === oldValue) return;
	if (diablo_no === $scope.base_settings) return;
	
	$scope.change_firm();
    });
    
    $scope.change_firm = function(){
	$scope.select.surplus = 0;
	$scope.select.left_balance   = 0;
	if (diablo_invalid_firm !== stockUtils.invalid_firm($scope.select.firm)){
	    $scope.select.surplus = $scope.select.firm.balance;
	    $scope.select.left_balance = $scope.select.surplus;
	} else {
	    $scope.select.surplus = undefined;
	    $scope.select.left_balance = undefined;
	} 
	// $scope.get_prompt_good(); 
    };

    $scope.focus_barcode_or_style_number = function() {
	if ($scope.base_settings.hide_barcode)
	    $scope.on_focus_attr("style_number");
	else
	    $scope.on_focus_attr("barcode");
    };

    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	// $scope.select.form.cardForm.$invalid  = false;
	// $scope.select.form.cashForm.$invalid  = false;
	// $scope.select.form.vForm.$invalid     = false;
	// $scope.select.form.wireForm.$invalid  = false;
	$scope.select.form.extraForm.$invalid = false;

	$scope.select.cash       = undefined;
	$scope.select.card       = undefined;
	$scope.select.verificate = undefined;
	$scope.select.wire       = undefined;
	$scope.select.extra_pay  = undefined;
	
	$scope.select.has_pay    = 0;
	$scope.select.should_pay = 0;

	$scope.select.total   = 0;
	$scope.select.comment = undefined;

	$scope.select.surplus = 0;
	$scope.select.left_balance = 0;
	$scope.select.firm = undefined;
	// $scope.select.left_balance = 0;
	
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

    // console.log($scope.shops);
    $scope.select = {
	shop: $scope.shops.length !== 0 ? $scope.shops[0]:undefined,
	total: 0,
	has_pay: 0,
	should_pay: 0,
	surplus: 0,
	left_balance: 0,
	extra_pay_type: $scope.extra_pay_types[0],
	date: $scope.today()};


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

	var e_pay = stockUtils.to_float($scope.select.extra_pay); 
	var verificate = stockUtils.to_float($scope.select.verificate); 

	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    // console.log(one);
	    $scope.select.total  += stockUtils.to_integer(one.total);
	    
	    $scope.select.should_pay += $scope.calc_row(
		one.org_price, 100, one.total - one.over);
	};
	
	$scope.select.should_pay = stockUtils.to_decimal($scope.select.should_pay);
	
	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;
	
	$scope.select.left_balance = stockUtils.to_decimal($scope.select.left_balance);
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
	    diablo_dkey_stock_in)
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

	sDraft.select(diabloUtilsService, "inventory-draft.html", draft_filter, select); 
    };

    // list first draft
    if (sDraft.keys().length !== 0) {
	// var keySec = sDraft.keys()[0].split("-");
	// console.log(keySec);
	// $scope.select.shop = diablo_get_object(stockUtils.to_integer(keySec[1]), $scope.shops);
	// $scope.select.employee = diablo_get_object(stockUtils.to_integer(keySec[2]), filterEmployee);
	// $scope.get_employee();

	// var one = sDraft.get(sDraft.keys()[0]);
	// $scope.inventories = angular.copy(one.v);

	// for (var i=0, l=$scope.inventories.length; i<l; i++){
	//     var stock = $scope.inventories[i];
	//     if (diablo_invalid_firm !== stock.firm_id){
	// 	$scope.select.firm = diablo_get_object(stock.firm_id, $scope.firms);
	// 	break;
	//     }
	// }

	// $scope.inventories.unshift({$edit:false, $new:true});
	// $scope.disable_refresh = false;
	// $scope.re_calculate();
	// $scope.auto_focus("style_number");
	$scope.list_draft();
    }

    $scope.get_setting = function(shopId){
	$scope.base_settings.m_sgroup = stockUtils.multi_sizegroup(shopId, base);
	$scope.base_settings.t_trace = stockUtils.t_trace(shopId, base);
	$scope.base_settings.group_color = stockUtils.group_color(shopId, base);
	// $scope.base_settings.image_allowed = stockUtils.image_allowed(shopId, base);
	$scope.base_settings.price_on_region = stockUtils.price_on_region(shopId, base);

	angular.extend($scope.base_settings, stockUtils.stock_in_hide_mode(shopId, base));
	
	console.log($scope.base_settings);
	$scope.base_settings.stock_alarm     = stockUtils.stock_alarm(shopId, base);
	$scope.base_settings.stock_alarm_a   = stockUtils.stock_alarm_a(shopId, base);
	$scope.base_settings.stock_contailer = stockUtils.stock_contailer(shopId, base); 
	$scope.base_settings.stock_with_firm = stockUtils.stock_mode(shopId, base).check_i_firm;
	$scope.base_settings.auto_barcode    = stockUtils.auto_barcode(shopId, base); 

	angular.extend($scope.base_settings, stockUtils.bill_mode(shopId, base));
    }

    $scope.change_shop = function(){
	console.log(sDraft.key);
	// sDraft.remove(); 
	$scope.get_setting($scope.select.shop.id);
	$scope.get_employee();
	sDraft.change_key(undefined, $scope.select.shop.id, $scope.select.employee.id);
	// sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	
	// $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id, base);
	// $scope.get_prompt_good(); 
	$scope.get_employee();
    };

    $scope.pvp_calc_tagprice = function() {
	if (0 !== stockUtils.to_integer($scope.good.vir_price)
	    && $scope.good.vir_price > stockUtils.to_integer($scope.good.tag_price)) {
	    $scope.good.tag_price = diablo_round(diablo_price($scope.good.vir_price, $scope.base_settings.pvp))
	}
    };

    $scope.get_setting($scope.select.shop.id);

    // console.log($scope.base_settings);
    
    $scope.prompt_limit = stockUtils.prompt_limit($scope.select.shop.id, base);

    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    }; 
    
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
		$scope.base_settings.stock_with_firm ? $scope.select.firm : diablo_invalid_firm) ); 
    };

    $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id, base); 
    $scope.qtime_start = function(shopId){
	return stockUtils.start_time(shopId, base, $.now(), dateFilter); 
    };

    $scope.get_good_by_barcode = function(bcode) {
	// console.log(bcode);
	// if (angular.isUndefined(bcode) || !bcode) {
	//     dialog.set_error("新增货品",   2072);
	// } else {
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
	add.draw         = src.draw;
	add.ediscount    = src.ediscount;
	add.discount     = src.discount;
	
	add.state        = src.state; 
	add.path         = src.path;
	add.alarm_day    = src.alarm_day;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.sizes        = src.size.split(",");
	add.colors       = src.color.split(",");
	add.over         = 0; 
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
		    "新增库存",
		    "新增库存失败：" + purchaserService.error[2093],
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
		    && (angular.isUndefined($scope.stock_at_first.$new_good) || !$scope.stock_at_first.$new_good) ){
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
	if ($scope.has_saved){
	    return true;
	};
	
	if (angular.isDefined($scope.select.cash) && $scope.select.cash
	    || angular.isDefined($scope.select.card) && $scope.select.card
	    || angular.isDefined($scope.select.wire) && $scope.select.wire
	    || angular.isDefined($scope.select.verificate) && $scope.select.verificate
	    || angular.isDefined($scope.select.extra_pay) && $scope.select.extra_pay
	    || $scope.inventories.length !== 1){
	    return false;
	} 
	return true;
    };

    var reset_payment = function(newValue){
	$scope.select.has_pay = 0.00;
	var e_pay = 0.00;
	var verificate = 0.00;
	
	if(angular.isDefined($scope.select.extra_pay)
	   && $scope.select.extra_pay){
	    e_pay = parseFloat($scope.select.extra_pay);
	}
	
	if(angular.isDefined($scope.select.cash) && $scope.select.cash){
	    $scope.select.has_pay += parseFloat($scope.select.cash);
	}

	if(angular.isDefined($scope.select.card) && $scope.select.card){
	    $scope.select.has_pay += parseFloat($scope.select.card);
	}

	if(angular.isDefined($scope.select.wire) && $scope.select.wire){
	    $scope.select.has_pay += parseFloat($scope.select.wire);
	}

	if(angular.isDefined($scope.select.verificate)
	   && $scope.select.verificate){
	    verificate = parseFloat($scope.select.verificate); 
	}

	$scope.select.left_balance =
	    $scope.select.surplus + $scope.select.should_pay + e_pay
	    - $scope.select.has_pay - verificate;
	
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

    $scope.$watch("select.extra_pay", function(newValue, oldValue){
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	if ($scope.select.form.extraForm.$invalid) return; 
    	$scope.re_calculate(); 
    }); 

    
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
		"新增库存",
		"新增库存失败：" + purchaserService.error[2096]);
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
		    "新增库存",
		    "新增库存失败：["
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
		    "新增库存",
		    "新增库存失败：[" 
			+ add.order_id + "]：" + purchaserService.error[2092]
		    	+ "款号：" + add.style_number + "！！", 
		    undefined);
		return;
	    };
	    
	    added.push({
		// good        : add.id,
		order_id    : add.order_id,
		bcode       : add.bcode == diablo_empty_db_barcode ? undefined : add.bcode,
		style_number: add.style_number,
		brand       : add.brand_id,
		firm        : add.firm_id,
		type        : add.type_id,
		sex         : add.sex,
		year        : add.year,
		season      : add.season,
		amount      : add.amount,
		over        : add.over,
		s_group     : add.s_group,
		free        : add.free,
		
		vir_price   : diablo_set_float(add.vir_price),
		org_price   : diablo_set_float(add.org_price),
		tag_price   : diablo_set_float(add.tag_price),
		draw        : diablo_set_float(add.draw),
		ediscount   : diablo_set_float(add.ediscount),
		discount    : diablo_set_float(add.discount),
		state       : add.state,
		unit        : add.unit,

		contailer   : add.contailer,
		alarm_a     : add.alarm_a,

		level       : add.level,
		executive   : add.executive,
		category    : add.category,
		fabric      : add.fabric,
		feather     : add.feather,
		
		path        : add.path,
		alarm_day   : add.alarm_day,
		total       : add.total,
		score       : add.state === 3 && $scope.base_settings.no_score_with_promotion ? diablo_invalid : $scope.select.shop.score_id 
	    })
	};

	var setv = diablo_set_float; 
	var e_pay = setv($scope.select.extra_pay);
	
	var base = {
	    // brand:         $scope.select.brand.id,
	    // firm: function() {
	    // 	if ($scope.base_settings.stock_with_firm === diablo_yes) {
	    // 	    return stockUtils.invalid_firm($scope.select.firm);
	    // 	} else {
	    // 	    return diablo_invalid_firm;
	    // 	} 
	    // }(),
	    firm:          stockUtils.invalid_firm($scope.select.firm), 
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.date, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    total:         $scope.select.total,
	    balance:       parseFloat($scope.select.surplus), 
	    cash:          setv($scope.select.cash),
	    card:          setv($scope.select.card),
	    wire:          setv($scope.select.wire),
	    verificate:    setv($scope.select.verificate),
	    should_pay:    setv($scope.select.should_pay),
	    has_pay:       setv($scope.select.has_pay),
	    
	    e_pay_type: angular.isUndefined(e_pay) ? undefined : $scope.select.extra_pay_type.id,
	    e_pay:  e_pay,
	};

	console.log(added);
	console.log(base);

	// $scope.has_saved = true;
	// $scope.local_remove();
	// return;
	purchaserService.add_purchaser_inventory({
	    inventory: added.length === 0 ? undefined: added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		$scope.disable_refresh = false; 
		diabloUtilsService.response_with_callback(
		    true, "新增库存", "新增库存成功！！单号：" + state.rsn,
		    undefined,
		    function(){sDraft.remove(); $scope.refresh()})
	    } else {
		diabloUtilsService.response_with_callback(
	    	    false,
		    "新增库存",
	    	    "新增库存失败："
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
	    total += parseFloat(a.count);
	})
	
	return {amount:    new_amount,
		total:     total,
		org_price: params.org_price,
		ediscount: params.ediscount,
		tag_price: params.tag_price,
		discount:  params.discount,
		over:      stockUtils.to_integer(params.over)};
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
			       over:         inv.over,
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
			"inventory-new.html", modal_size, callback, undefined, payload)
		} else{
		    inv.colors_info = inv.colors.map(function(cid){
			return diablo_find_color(parseInt(cid), $scope.colors)});
		    
		    payload.colors = inv.colors_info;
		    diabloUtilsService.edit_with_modal(
			"inventory-new.html", modal_size, callback, undefined, payload);
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
	// $scope.current_inventories = $scope.get_page($scope.current_page);
	
	// $scope.local_save();
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
		       over:       inv.over,
		       right:      $scope.stock_right,
		       colors:     inv.colors_info,
		       path:       inv.path,
		       get_amount: get_amount};
	diabloUtilsService.edit_with_modal(
	    "inventory-detail.html", undefined, undefined, $scope, payload)
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
	    inv.over      = result.over;

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
		    "inventory-new.html", modal_size, callback, undefined, payload);
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
	// console.log(inv);
	// $scope.good.colors=""; 
	// $scope.selectColors = [];
	
	// angular.forEach(inv.colors, function(colorId) {
	//     for (var i=0, l1=$scope.gcolors.length; i<l1; i++) {
	// 	angular.forEach($scope.gcolors[i].colors, function(c) {
	// 	    if (stockUtils.to_integer(colorId) === c.id) {
	// 		c.select = true;
	// 		c.disabled = true;
	// 	    } 
	// 	}) 
	//     }
	// });
	
	// if (diablo_no === $scope.base_settings.group_color){
	//     angular.forEach(inv.colors, function(colorId) {
	// 	for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
	// 	    for (var j in $scope.grouped_colors[i]){
	// 		var c = $scope.grouped_colors[i][j];
	// 		if (stockUtils.to_integer(colorId) === c.id) {
	// 		    c.select = true;
	// 		    c.disabled = true; 
	// 		}
	// 	    }
	// 	} 
	//     });
	// };

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
		    // if (inv.$new)
		    // 	$scope.add_inventory(inv)
		    // else
		    // 	$scope.update_inventory_with_new(inv);
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
	inv.o_over      = inv.over;
	
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
	    inv.over      = result.over;

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
			       over:       inv.over,
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
		    "inventory-new.html", modal_size, callback, undefined, payload);
	    };
	}); 
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.$update          = false;
	inv.update_directory = false; 
	inv.total            = inv.amount[0].count; 
	// $scope.local_save();
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
	inv.over             = inv.o_over;
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

	if (angular.isDefined(inv.form.ediscount)
	    && inv.form.ediscount.$invalid)
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
	// sex:false,
	// year:false,
	// season:false,
	vir_price:false,
	tag_price:false,
	draw: false,
	
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
	// $scope.good.color     = item.color;

	if ($scope.tab_active[1].active){
	    $scope.on_select_good(item, model, label); 
	    // $scope.is_same_good = true;
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
	    
	    // for (var j=0, l1=oldGroupedColors.length; j<l1; j++){
	    // 	for (var k in oldGroupedColors[j]){
	    // 	    console.log(k);
	    // 	    var c = oldGroupedColors[j][k];
	    // 	    if (addedColor.id === c.id) {
	    // 		if (c.select)
	    // 	    	    addedColor.select = c.select;
	    // 		if (c.disabled)
	    // 	    	    addedColor.disabled = c.disabled;
	    // 	    } 
	    // 	}
	    // }
	    
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
		    // dialog.response_with_callback(
		    // 	true, "新增颜色", "新增颜色成功！！", $scope, function(){append_color(state.id)});
		} else{
		    // var error = require("diablo-error");
		    // dialog.response(false, "新增颜色", "新增颜色失败：" + error[state.ecode]);
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
	    // console.log(item);
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

	// force
	// angular.forEach($scope.size_groups, function(g) {
	//     if (angular.isDefined(g.select) && g.select)
	// 	g.focus = true;
	//     else
	// 	g.focus = (g.order_id === 1);
	// });
	
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
    // $scope.$watch("good.image", function(newValue, oldValue){
    // 	console.log(newValue, oldValue);
    // 	if ($scope.good.image) $scope.good.d_image = false; 
    // });
    
    $scope.delete_image = function(){
    	// $scope.good.d_image = true; 
	// if (angular.isDefined($scope.good.image)) $scope.good.image.file = undefined;
	$scope.good.image = undefined;
    };

    /*
     * good amount
     */
    // $scope.new_good_amount = function(){
    // 	var add = $scope.inventories[0];
    // };

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
	draw      : 0,
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
	good.draw      = $scope.good.draw;
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
			draw:      good.draw,
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
	    // type:      $scope.good.type,
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.season2objs[stockUtils.valid_season(current_month)],
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price,
	    draw: undefined,
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
	    // image.file: undefined,
	    // d_image: true
	};

	// if (angular.isDefined($scope.good.image)) $scope.good.image.file = undefined;

	$scope.form.gForm.style_number.$pristine = true;
	$scope.form.gForm.brand.$pristine = true;
	$scope.form.gForm.type.$pristine = true;
	$scope.form.gForm.tag_price.$pristine = true;
	$scope.form.gForm.draw.$pristine = true;
	$scope.form.gForm.discount.$pristine  = true;
	// $scope.form.gForm.alarm.$pristine     = true;
	// $scope.image = undefined;

	//focus
	// $scope.on_focus_attr("style_number");
	$scope.focus_barcode_or_style_number();
    };
};


function purchaserInventoryDetailCtrlProvide(
    $scope, $routeParams, $q, dateFilter, diabloPattern, diabloFilter,
    diabloUtilsService, diabloPromise, purchaserService,
    localStorageService, filterPromotion, filterScore,  filterBrand,
    filterFirm, filterType, filterCType, filterSizeGroup, filterColor,
    filterSizeSpec, filterStdExecutive, filterCategory, filterFabric, filterTemplate,
    filterRegion, base, user) {
    $scope.promotions = filterPromotion.concat([{id:diablo_invalid_index, name:"重置促销方案"}]);
    $scope.scores = filterScore.filter(function(s) {return s.type_id===0})
	.concat([{id:diablo_invalid_index, name:"重置积分方案", type_id:0}]);
    // console.log(filterTemplate);
    
    $scope.unfold = true; 
    /*
     * tab-set
     */ 
    $scope.tab_active = {time: true, chart:false};
    $scope.chart_data = {};
    
    $scope.shops     = user.sortShops;
    $scope.shopIds   = user.shopIds;
    
    $scope.sexs      = diablo_sex;
    $scope.seasons   = diablo_season;
    $scope.goto_page = diablo_goto_page;
    $scope.waynodes  = diablo_waynodes;
    $scope.total_items = 0;

    /*
     * order
     */
    $scope.order_fields = stockUtils.order_fields();
    $scope.mode = $scope.order_fields.id;
    $scope.sort = 0;

    $scope.stock_right = {
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, "show_orgprice"), 
	// export_stock:  rightAuthen.authen_master(user.type),
	// set_promotion: rightAuthen.authen_master(user.type),
	set_promotion: rightAuthen.authen(
	    user.type, rightAuthen.stock_action()["set_w_stock_promotion"], user.right),
	update_batch:  rightAuthen.authen(
	    user.type, rightAuthen.stock_action()["update_w_stock_batch"], user.right),
	reset_barcode: rightAuthen.authen(
	    user.type, rightAuthen.stock_action()["reset_barcode"], user.right), 
	update_good:   rightAuthen.authen(
	    user.type, rightAuthen.good_action()["update_w_good"], user.right),
	gift_stock:  rightAuthen.authen(
	    user.type, rightAuthen.good_action()["gift_w_stock"], user.right)
    };
    
    $scope.setting = {alarm: false};

    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };

    $scope.css =  function(minalarm_amount){
	return minalarm_amount < 0 ? "bg-magenta" : "";
    };
    
    /*
     * filter
     */ 

    // initial
    var stocks =  [{name:">0", id:0}, {name:"=0", id:1}, {name:"!=0", id:2}];
    $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",  filterBrand);
    diabloFilter.add_field("ctype",  filterCType);
    diabloFilter.add_field("type",   filterType);
    diabloFilter.add_field("season", diablo_season2objects);
    diabloFilter.add_field("sex",    diablo_sex2object);
    diabloFilter.add_field("score",  $scope.scores);
    diabloFilter.add_field("year",   diablo_full_year);
    if ($scope.stock_right.show_orgprice) {
	diabloFilter.add_field("org_price", []);
    };
    diabloFilter.add_field("tag_price", []); 
    diabloFilter.add_field("discount", []);
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("region", filterRegion);
    diabloFilter.add_field("firm", filterFirm);
    diabloFilter.add_field("stock", stocks);
    diabloFilter.add_field("sprice", stockUtils.yes_no());
    diabloFilter.add_field("msell", []);
    diabloFilter.add_field("esell", []);
    diabloFilter.add_field("lsell", []);
    

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    var storage = localStorageService.get(diablo_key_inventory_detail);
    // console.log(storage);
        
    // alarm, use default shop
    // $scope.setting.alarm           = stockUtils.stock_alarm_b(diablo_default_shop, base);
    $scope.setting.stock_alarm     = stockUtils.stock_alarm(diablo_default_shop, base);
    $scope.setting.stock_contailer = stockUtils.stock_contailer(diablo_default_shop, base);
    $scope.setting.use_barcode     = stockUtils.use_barcode(diablo_default_shop, base);
    $scope.setting.auto_barcode    = stockUtils.auto_barcode(diablo_default_shop, base); 
    $scope.setting.saler_stock     = stockUtils.saler_stock(diablo_default_shop, base);
    $scope.setting.gift_sale       = stockUtils.gift_sale(diablo_default_shop, base);
    $scope.setting.print_access    = stockUtils.print_num(user.loginShop, base);
    angular.extend($scope.setting, stockUtils.stock_in_hide_mode(user.loginShop, base));
    // if (needCLodop()) loadCLodop(print_mode.protocal); 
    
    // var hide_mode  = stockUtils.stock_in_hide_mode(diablo_default_shop, base); 
    // $scope.setting.hide_expire  = function() {
    // 	var h = hide_mode.charAt(3);
    // 	if ( !h ) return diablo_yes;
    // 	else return stockUtils.to_integer(h);
    // }(),
    
    // $scope.setting.printer_barcode = stockUtils.printer_barcode(user.loginShop, base); 
    $scope.setting.printer_barcode = stockUtils.printer_barcode(user.loginShop, base);
    $scope.setting.dual_barcode = stockUtils.dual_barcode_print(user.loginShop, base);
    console.log($scope.setting);

    $scope.printU = new stockPrintU($scope.setting.auto_barcode, $scope.setting.dual_barcode);
    $scope.printU.setPrinter($scope.setting.printer_barcode);
    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    
    // default the first page
    $scope.default_page = 1;

    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters       = storage.filter;
	// $scope.current_page  = storage.page; 
    	$scope.qtime_start   = storage.start_time;
    } else{
	$scope.filters = [];
	// $scope.current_page  = $scope.default_page;
	$scope.qtime_start = function(){
	    var shop = -1
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };

    console.log($scope.filters);

    $scope.time = diabloFilter.default_time($scope.qtime_start);
    
    $scope.tab_page = {
	page_of_time: $scope.default_page,
	page_of_chart: $scope.default_page
    };
    
    // $scope.current_page = $scope.default_page;
    
    $scope.page_changed = function(page){
	// console.log(page);
	$scope.tab_page.page_of_time = page;
	$scope.do_search($scope.tab_page.page_of_time);
    }

    $scope.chart_mode = function(page){
	// console.log("chart mode");
	$scope.tab_page.page_of_chart = page;
	$scope.do_search($scope.tab_page.page_of_chart);
    }; 

    $scope.use_order = function(mode){
	$scope.mode = mode;
	$scope.sort = $scope.sort === 0 ? 1 : 0;
	// if ($scope.sort === 0) $scope.sort = 1;
	// else if ($scope.sort === 1) $scope.sort = 0;
	$scope.do_search($scope.tab_page.page_of_time);
    }
    
    // filter
    var add_search_condition = function(search){
	search = stockUtils.correct_condition_with_shop(
	    search, $scope.shopIds, $scope.shops, $scope.setting.saler_stock);
	
	// if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
	//     // search.shop = user.shopIds;
	//     if (diablo_yes !== $scope.setting.saler_stock) {
	// 	search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds;
	//     } else {
	// 	// more than shop means super user
	// 	search.shop = $scope.shopIds.length === 1 ? undefined : $scope.shopIds;
	// 	// search.shop = undefined;
	//     } 
	// };

	return search;
    };

    var now_date = diablo_now_date(); 
    $scope.do_search = function(page){
	if ($scope.tab_active.chart){
	    $scope.mode = $scope.order_fields.sell;
	    $scope.sort =0;
	    $scope.tab_page.page_of_chart = page;
	} else {
	    $scope.tab_page.page_of_time = page; 
	}
	
	localStorageService.set(
	    diablo_key_inventory_detail,
	    {filter:$scope.filters,
	     start_time:diablo_get_time($scope.time.start_time),
	     page:page, t:now});
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.filter_purchaser_inventory_group(
		{mode:$scope.mode, sort:$scope.sort},
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);

		if ($scope.tab_active.chart && $scope.mode === 1){
		    var labels  = [];
		    var totals  = [];
		    var sells   = []; 
		    angular.forEach(result.data, function(d){
			labels.push(d.style_number);
			totals.push(d.amount + d.sell);
			sells.push(d.sell);
		    }); 
		    $scope.chart_data.bar={
			label:labels, left:totals, right:sells};
		    
		} else {
		    if (page === 1){
			$scope.total_items  = result.total;
			$scope.total_amount = result.t_amount;
			$scope.total_sell   = result.t_sell;
			$scope.total_lmoney = result.t_lmoney;
			$scope.total_pmoney = result.t_pmoney;
		    }
		    // angular.forEach(result.data, function(d){
		    // 	// if (now_date.getTime() - diablo_set_date(d.last_sell)
		    // 	//     > diablo_day_millisecond * d.alarm_day){
		    // 	//     d.isAlarm = true;
		    // 	// } else{
		    // 	//     d.isAlarm = false;
		    // 	// }
		    // 	d.isAlarm = false;
		    // 	if (d.alarm_day !== diablo_nolimit_day && 0 !== d.amount) {
		    // 	    var limit = diablo_day_millisecond * d.alarm_day;
		    // 	    if (diablo_set_date(d.entry_date)
		    // 		+ limit < diablo_set_date(now) ) {
		    // 		d.isAlarm = true;
		    // 	    }
		    // 	}
			
		    // });
		    
		    $scope.inventories = result.data;
		    angular.forEach(result.data, function(d){
			d.brand = diablo_get_object(d.brand_id, filterBrand);
			d.type  = diablo_get_object(d.type_id, filterType);
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			d.promotion = diablo_get_object(d.pid, filterPromotion);
			d.bargin_price = stockUtils.to_integer(d.state.charAt(0));
			d.gift  = stockUtils.to_integer(d.state.charAt(1));
			    
			d.score = diablo_get_object(d.sid, filterScore);
			d.calc  = diablo_float_mul(d.org_price, d.amount);

			d.executive = diablo_get_object(d.executive_id, filterStdExecutive);
			d.category = diablo_get_object(d.category_id, filterCategory);
			d.specs = [];
			if (angular.isObject(d.type) && d.type.cid !== diablo_invalid_index) {
			    angular.forEach(filterSizeSpec, function(s) {
				if (s.cid === d.type.cid) {
				    d.specs.push(s);
				}
			    }) 
			}

			if (d.fabric_json) {
			    d.fabrics = angular.fromJson(d.fabric_json);
			    d.fabric_desc = diablo_empty_string;
			    angular.forEach(d.fabrics, function(f) {
				var fabric = diablo_get_object(f.f, filterFabric);
				if (angular.isDefined(fabric) && angular.isObject(fabric)) {
				    f.name = fabric.name;
				    f.way  = diablo_get_object(
					stockUtils.to_integer(f.w), $scope.waynodes);
				    d.fabric_desc += fabric.name + ":" + f.p.toString();
				} 
			    });
			}

			if (d.feather_json) {
			    d.feathers = angular.fromJson(d.feather_json);
			}
			
			// d.isAlarm = false;
			// if (d.alarm_day !== diablo_nolimit_day && 0 !== d.amount) {
			//     var limit = diablo_day_millisecond * d.alarm_day;
			//     if (diablo_set_date(d.entry_date) + limit < now ) {
			// 	d.isAlarm = true;
			//     }
			// }
			
			d.expire_date = diablo_none;
			var expire = diablo_nolimit_day;
			if (d.alarm_day !== diablo_nolimit_day) {
			    expire = stockUtils.to_integer(d.alarm_day);
			} else {
			    if (diablo_invalid_firm !== stockUtils.invalid_firm(d.firm)) {
				if (angular.isDefined(d.firm.expire)
				    && d.firm.expire !== diablo_nolimit_day) {
				    expire = stockUtils.to_integer(d.firm.expire);
				}
			    }
			}

			if (expire !== diablo_nolimit_day) {
			    d.expire_date = stockUtils.date_add(d.entry_date, expire);
			} 
			// d.shop  = diablo_get_object(d.shop_id, user.sortShops);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);

		    console.log($scope.inventories);
		}
	    })
	});
    };

    $scope.refresh = function(){
	// $scope.mode = undefined;
	$scope.mode = $scope.order_fields.id;
	$scope.do_search($scope.default_page);
    };
    
    // $scope.do_search($scope.tab_page.page_of_time);
        
    /*
     * detail
     */

    $scope.free_color_size = function(inv){
	// wait for get goods from server
	if (angular.isUndefined($scope.goods)){
	    return false;
	}
	
	for(var i=0, l=$scope.goods.length; i<l; i++){
	    var good = $scope.goods[i];
	    if (inv.style_number === good.style_number
		&& inv.brand_id === good.brand_id){
		if (good.color === "0" && good.size === "0"){
		    return true;
		}
	    }
	}
	
	return false;
    };

    var dialog = diabloUtilsService;
    $scope.lookup_detail = function(inv){
	console.log(inv);

	var get_amount = function(cid, size){
	    return purchaserService.get_inventory_from_sort(cid, size, inv.amounts)};
	
	if (angular.isDefined(inv.sizes) && angular.isDefined(inv.colors) && angular.isDefined(inv.amounts)){
	    var payload = {sizes:      inv.sizes,
			   colors:     inv.colors,
			   path:       inv.path ? inv.path + "?" + Match.random() : undefined,
			   stock_alarm: $scope.setting.stock_alarm,
			   get_amount: get_amount 
			  };
	    
	    dialog.edit_with_modal(
		"inventory-detail.html", undefined, undefined, $scope, payload);
	} else{
	    purchaserService.list_purchaser_inventory(
		{style_number: inv.style_number,
		 brand:        inv.brand_id,
		 rsn:          $routeParams.rsn ? $routeParams.rsn:undefined,
		 shop:         inv.shop_id,
		 qtype:        1}
	    ).then(function(invs){
		console.log(invs);
		var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		console.log(order_sizes);
		var sort    = diabloHelp.sort_stock(invs, order_sizes, filterColor);
		console.log(sort);
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort;
		inv.path = inv.path ? inv.path + "?" + Math.random() : undefined;

		var payload = {sizes:      inv.sizes,
			       colors:     inv.colors,
			       path:       inv.path,
			       stock_alarm: $scope.setting.stock_alarm,
			       get_amount: function(cid, size){
				   return get_amount(cid, size, inv.amounts)}
			      };
		dialog.edit_with_modal(
		    "inventory-detail.html",
		    undefined,
		    undefined,
		    $scope,
		    payload); 
	    }) 
	}
    };

    // var LODOP;
    if ($scope.setting.use_barcode && needCLodop()) 
	loadCLodop($scope.setting.print_access.protocal);
    
    var dialog_barcode_title = "库存条码打印";
    var dialog_barcode_title_failed = "库存条码打印失败：";
    
    $scope.p_barcode = function(inv) {
	console.log(inv);
	var print_barcode = function(barcode, template) {
	    console.log(barcode);
	    $scope.printU.set_template(template); 
	    if (template.firm && diablo_invalid_firm === inv.firm_id) {
		dialog.response(
		    false,
		    dialog_barcode_title,
		    dialog_barcode_title_failed + purchaserService.error[2086]);
		return;
	    }
	    
	    var firm = inv.firm_id === diablo_invalid_firm ? undefined : inv.firm.name;
	    if (diablo_free_color_size === inv.free) {
		$scope.printU.free_prepare(
		    inv.shop,
		    inv,
		    inv.brand.name,
		    [barcode],
		    firm,
		    inv.firm_id); 
	    }
	    else {
		var callback = function(params) {
		    console.log(params.amounts); 
		    var barcode_amounts = [];
		    for (var i=0, l=params.amounts.length; i<l; i++) {
			var a = params.amounts[i];
			if (angular.isDefined(a.select) && a.select) {
			    barcode_amounts.push(a);
			}
		    }

		    if (0 === barcode_amounts.length) {
			dialog.response(
			    false,
			    dialog_barcode_title,
			    dialog_barcode_title_failed+ purchaserService.error[2087]);
		    } else {
			var barcodes = []; 
			angular.forEach(barcode_amounts, function(a) {
			    var o = stockUtils.gen_barcode_content(
				barcode,
				a.cid,
				a.size,
				filterColor);

			    if (angular.isDefined(o) && angular.isObject(o)) {
				barcodes.push(o);
			    } 
			});

			console.log(barcodes);
			$scope.printU.prepare(
			    inv.shop,
			    inv,
			    inv.brand.name,
			    barcodes,
			    firm,
			    inv.firm_id); 
		    }
		}

		var get_amount = function(cid, size, amounts){
		    return purchaserService.get_inventory_from_sort(cid, size, amounts)};
		
		if (angular.isDefined(inv.sizes)
		    && angular.isDefined(inv.colors)
		    && angular.isDefined(inv.amounts)){
		    var payload = {sizes:      inv.sizes,
				   colors:     inv.colors,
				   path:       inv.path,
				   amounts:    inv.amounts,
				   get_amount: get_amount};
		    
		    dialog.edit_with_modal(
			"inventory-gen-barcode.html", undefined, callback, undefined, payload);
		} else{
		    purchaserService.list_purchaser_inventory(
			{style_number: inv.style_number,
			 brand:        inv.brand_id,
			 rsn:          $routeParams.rsn ? $routeParams.rsn:undefined,
			 shop:         inv.shop_id,
			 qtype:        1}
		    ).then(function(invs){
			console.log(invs);
			var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
			// console.log(order_sizes);
			var sort    = diabloHelp.sort_stock(invs, order_sizes, filterColor);
			// console.log(sort);
			inv.sizes   = sort.size;
			inv.colors  = sort.color;
			inv.amounts = sort.sort;

			var payload = {sizes:      inv.sizes,
				       colors:     inv.colors,
				       path:       inv.path,
				       amounts:    inv.amounts,
				       get_amount: get_amount};
			dialog.edit_with_modal(
			    "inventory-gen-barcode.html",
			    undefined,
			    callback,
			    undefined,
			    payload); 
		    }) 
		}
	    }
	};

	var start_barcode = function(template) {
	    purchaserService.gen_barcode(
		inv.style_number, inv.brand_id, inv.shop_id
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    inv.bcode = result.barcode; 
		    print_barcode(result.barcode, template);
		} else {
		    dialog.response(
			false, "条码生成", "条码生成失败："
			    + purchaserService.error[result.ecode]);
		}
	    });
	};

	$scope.templates = stockUtils.get_print_templates(inv.shop_id, filterTemplate);
	console.log($scope.templates);
	
	if ($scope.templates.length === 1) {
	    start_barcode($scope.templates[0]);
	} else {
	    var callback2 = function(params) {
		console.log(params);
		start_barcode(params.templates.filter(function(t) {return t.select})[0]);
	    };

	    dialog.edit_with_modal(
		"select-template.html",
		undefined,
		callback2,
		undefined,
		{templates: $scope.templates,
		 check_only: stockUtils.check_select_only}); 
	} 
    };

    $scope.p_barcode_all = function(inv) {
	console.log(inv); 
	var print_barcode = function(barcode, template) {
	    console.log(barcode);
	    $scope.printU.set_template(template);
	    
	    if (template.firm && diablo_invalid_firm === inv.firm_id ) {
		dialog.response(
		    false,
		    dialog_barcode_title,
		    dialog_barcode_title_failed + purchaserService.error[2086]);
		return;
	    }
	    
	    var firm = inv.firm_id === diablo_invalid_firm ? undefined : inv.firm.name;
	    var barcodes = []; 
	    if (diablo_free_color_size === inv.free) {
		for (var i=0; i<inv.amount; i++) {
		    barcodes.push(barcode); 
		}
		$scope.printU.free_prepare(
		    inv.shop,
		    inv,
		    inv.brand.name,
		    barcodes,
		    firm,
		    inv.firm_id);
	    } else {
		purchaserService.list_purchaser_inventory(
		    {style_number: inv.style_number,
		     brand:        inv.brand_id,
		     rsn:          undefined,
		     shop:         inv.shop_id,
		     qtype:        1}
		).then(function(invs){
		    console.log(invs);
		    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		    // console.log(order_sizes);
		    var sort    = diabloHelp.sort_stock(invs, order_sizes, filterColor);
		    // console.log(sort);
		    // inv.sizes   = sort.size;
		    // inv.colors  = sort.color;
		    inv.amounts = sort.sort;

		    barcodes = [];
		    angular.forEach(inv.amounts, function(a) {
			for (var i=0; i<a.count; i++) {
			    var o = stockUtils.gen_barcode_content(
				barcode,
				a.cid,
				a.size,
				filterColor);

			    if (angular.isDefined(o) && angular.isObject(o)) {
				barcodes.push(o);
			    }
			} 
		    });

		    console.log(barcodes);
		    $scope.printU.prepare(
			inv.shop,
			inv,
			inv.brand.name,
			barcodes,
			firm,
			inv.firm_id); 
		});
	    } 
	};

	var start_barcode = function(template) {
	    purchaserService.gen_barcode(
		inv.style_number, inv.brand_id, inv.shop_id
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    inv.bcode = result.barcode;
		    print_barcode(result.barcode, template);
		} else {
		    dialog.response(
			false,
			"条码生成", "条码生成失败："
			    + purchaserService.error[result.ecode]);
		}
	    });
	};

	$scope.templates = stockUtils.get_print_templates(inv.shop_id, filterTemplate);
	console.log($scope.templates);
	
	if ($scope.templates.length === 1) {
	    start_barcode($scope.templates[0]);
	} else {
	    var callback2 = function(params) {
		console.log(params);
		var t = params.templates.filter(function(t) {return t.select})[0];
		start_barcode(t);
	    };

	    dialog.edit_with_modal(
		"select-template.html",
		undefined,
		callback2,
		undefined,
		{templates: $scope.templates,
		 check_only: stockUtils.check_select_only}); 
	}
	
    };

    var dialog_reset_barcode_title = "条码重置";
    var dialog_reset_barcode_title_failed = "条码重置失败：";
    $scope.reset_barcode = function(inv) {
	console.log(inv);
	if (inv.bcode === diablo_empty_barcode) {
	    dialog.response(
		false,
		dialog_reset_barcode_title,
		dialog_reset_barcode_title_failed + purchaserService.error[2081]);
	} else if ($scope.setting.self_barcode) {
	    dialog.response(
		false,
		dialog_reset_barcode_title,
		dialog_reset_barcode_title_failed + purchaserService.error[2079]); 
	}
	else {
	    var callback = function() {
		purchaserService.reset_barcode(
		    inv.style_number, inv.brand_id, inv.shop_id
		).then(function(result) {
		    console.log(result);
		    if (result.ecode === 0) {
			dialog.response_with_callback(
			    true,
			    dialog_reset_barcode_title,
			    "条码重置成功，重置后条码值为："
				+ result.barcode
				+ "请重新打印条码！！",
			    undefined,
			    function() {
				inv.bcode = result.barcode;
			    });
			// print_barcode(result.barcode);
		    } else {
			dialog.response(
			    false,
			    dialog_reset_barcode_title,
			    dialog_reset_barcode_title_failed + purchaserService.error[result.ecode]); 
		    }
		});
	    };

	    dialog.request(
		dialog_reset_barcode_title,
		"所有店铺下的该货品的条码将会重置，确定要重置吗？",
		callback, undefined, undefined);
	} 
    };

    $scope.export_to = function(){
	diabloFilter.do_filter(
	    $scope.filters, $scope.time, function(search){
		add_search_condition(search); 
		// console.log(search); 
		purchaserService.csv_export(
		    purchaserService.export_type.stock,
		    search,
		    {mode:$scope.mode, sort:$scope.sort} 
		).then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true,
			    "文件导出成功",
			    "创建文件成功，请点击确认下载！！",
			    undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			dialog.response(
			    false, "文件导出失败", "创建文件失败："
				+ purchaserService.error[result.ecode]);
		    } 
		}); 
	    });
    };

    $scope.promotion = function(){
	var condition = 
	    diabloFilter.do_filter(
		$scope.filters, $scope.time, function(search){
		    add_search_condition(search); 
		    return search; 
		}); 

	console.log(condition);

	// var check_only = function(select, promotions){
	//     console.log(select); 
	//     angular.forEach(promotions, function(p){
	// 	if (p.id !== select.id){
	// 	    p.select = false;
	// 	};
	//     });
	// };

	var check_select = function(promotions, scores){
	    for (var i=0, l=promotions.length; i<l; i++){
		if (promotions[i].select){
		    return true;
		}
	    }

	    for (var j=0, k=scores.length; j<k; j++){
		if (scores[j].select) {
		    return true;
		}
	    }
	    
	    return false;
	};
	
	var callback = function(params){
	    console.log(params);

	    var s_promotion = params.promotions.filter(function(p){
		return p.select;
	    });

	    var s_score = params.scores.filter(function(s){
		return s.select;
	    });
	    
	    purchaserService.set_w_inventory_promotion(
		condition,
		s_promotion.length !==0 ? s_promotion[0].id : undefined,
		s_score.length !==0 ? s_score[0].id : undefined 
	    ).then(function(result){
		if (result.ecode === 0){
		    var s = "";
		    if (s_promotion.length !== 0){
			s += "促销 [" + s_promotion[0].name + "] ";
		    }
		    if (s_score.length !== 0){
			s += "积分 [" + s_score[0].name + "] ";
		    } 
		    s += "方案设置成功！！";
		    
		    dialog.response_with_callback(
			true, "促销积分设置", s, undefined,
			function(){
			    $scope.do_search($scope.tab_page.page_of_time)
			});
		} else {
		    dialog.response(
			false,
			"促销积分设置",
			"促销积分设置失败："
			    + purchaserService.error[result.ecode]);
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "purchaser-on-sale.html",
	    undefined,
	    callback,
	    undefined,
	    {shops: function() {
		if (angular.isDefined(condition.shop)) {
		    if (angular.isNumber(condition.shop)) {
			return [].push(diablo_get_object(condition.shop, $scope.shops));
		    } else {
			condition.shop.map(function(s){return diablo_get_object(s, $scope.shops)});
		    }
		} else {
		    return $scope.shops;
		}
	    }(),
	     promotions:   $scope.promotions,
	     scores:       $scope.scores.filter(
		 function(s){return s.type_id===0}),
	     check_only:   stockUtils.check_select_only,
	     check_select: check_select}); 
	
    };

    $scope.update_batch = function(){
	var condition = diabloFilter.do_filter(
	    $scope.filters, $scope.time, function(search){
		// add_search_condition(search); 
		return search; 
	    }); 
	console.log(stockUtils.get_own_property_length(condition));

	if (stockUtils.get_own_property_length(condition) < 3) {
	    dialog.set_error("批量修改库存价格", 2071);
	} else {
	    condition = add_search_condition(condition); 
	    var callback = function(params){
		console.log(params);
		var update = {
		    // season: params.select.season,
		    // year: params.select.year 
		    tag_price: diablo_set_float(params.select.tag_price),
		    discount:  diablo_set_float(params.select.discount),
		    imbalance: diablo_set_float(params.select.imbalance),
		    score: params.select.score.id,
		    sprice: params.select.sprice.id
		};
		console.log(update);
		
		purchaserService.update_w_inventory_batch(
		    $scope.match, condition, update
		).then(function(result){
		    console.log(result);
		    var s = "";
		    if ( 0 !== stockUtils.to_integer(update.tag_price))
			s += "吊牌价[" + update.tag_price.toString() + "]";
		    if (0 !== stockUtils.to_integer(update.discount)){
			if (s)
			    s += "  "
			s += "折扣[" + update.discount.toString() + "]"; 
		    };

		    s += " 积分["  + params.select.score.name + "]";
		    s += " 特价["  + params.select.sprice.name + "]";
		    console.log(s);
		    
		    if (result.ecode === 0){
			s += "批量修改价格成功！！";
			dialog.response_with_callback(
			    true, "批量修改库存价格", s, undefined,
			    function(){
				$scope.do_search($scope.tab_page.page_of_time)
			    });
		    } else {
			dialog.response(
			    false,
			    "批量修改库存价格",
			    "批量修改库存价格失败："
				+ purchaserService.error[result.ecode]);
		    }
		})
	    };

	    var yes_no = stockUtils.yes_no();
	    // console.log(yes_no);
	    dialog.edit_with_modal(
		"stock-update-batch.html",
		undefined,
		callback,
		undefined,
		{
		    check_invalid: function(select){
			if (0 === stockUtils.to_integer(select.tag_price)
			    && 0 === stockUtils.to_integer(select.discount)
			    && 0 === select.sprice.id
			    && 1 === select.score.id){
			    return true;
			} 
			return false;
		    },
		    
		    yes_no: yes_no,
		    select: {score: yes_no[0], sprice: yes_no[0]}
		}
	    ); 
	}
    };

    $scope.update_stock = function(inv){
	// console.log(inv); 
	diabloFilter.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand.id}
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		if (diablo_is_empty(result.data)) {
		    var error = require("diablo-error");
		    dialog.response(
			false,
			"获取获品资料", "获取货品资料失败：" + error[2018]);
		} else {
		    diablo_goto_page(
			"#/good/wgood_update/"
			    + result.data.id + "/"
			    + inv.shop_id + "/"
			    + diablo_from_stock.toString())
		} 
	    } else {
		var error = require("diablo-error");
		dialog.response(
		    false,
		    "获取货品资料", "获取货品资料失败：" + error[result.ecode]);
	    }
	}) 
    };

    $scope.update_price = function(inv) {
	var callback = function(params){
	    console.log(params);
	    var update = {
		org_price  :diablo_get_modified(params.org_price, inv.org_price),
		tag_price  :diablo_get_modified(params.tag_price, inv.tag_price),
		discount   :diablo_get_modified(params.discount, inv.discount),
		contailer  :diablo_get_modified(params.contailer, inv.contailer),
		score      :params.is_score.id === 1 ? undefined : params.is_score.id,
		vir_price  :diablo_get_modified(params.vir_price, inv.vir_price),
		draw       :diablo_get_modified(params.draw, inv.draw)
	    };

	    console.log(update);

	    if (angular.isUndefined(update.tag_price)
		&& angular.isUndefined(update.discount)
		&& angular.isUndefined(update.contailer)
		&& (angular.isUndefined(update.score) || stockUtils.to_integer(update.score) === 1)) {
		dialog.response_with_callback(
		    false,
		    "库存价格编辑",
		    "编辑库存价格失败：" + purchaserService.error[2078]);
		return;
	    }

	    var condition = {style_number:inv.style_number, brand:inv.brand.id, shop:inv.shop_id};

	    purchaserService.update_w_inventory_batch(
		undefined, condition, update
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    var get_modified = function(newValue, oldValue) {
			if (angular.isUndefined(newValue)) {
			    return oldValue
			} else {
			    if (angular.isNumber(newValue) && angular.isNumber(oldValue)) {
				return newValue !== oldValue ? newValue : oldValue;
			    }  
			} 
		    };
		    
		    var tag_price = get_modified(update.tag_price, inv.tag_price);
		    var org_price = get_modified(update.org_price, inv.org_price);
		    var discount  = get_modified(update.discount, inv.discount);
		    var contailer = get_modified(update.contailer, inv.contailer);
		    var vir_price = get_modified(update.vir_price, inv.vir_price);
		    var draw      = get_modified(update.draw, inv.draw);
		    var s = "修改价格成功！！"
		    
			+ "[吊牌价" + tag_price.toString() + "；" 
			+ "折扣" + discount.toString() + "；";
		    if ($scope.setting.stock_contailer)
			s += "货柜号" + contailer.toString() + "]";
		    else
			s += "]";
		    
		    dialog.response_with_callback(
			true, "库存价格编辑", s, undefined,
			function(){
			    inv.tag_price = tag_price;
			    inv.org_price = org_price;
			    inv.discount  = discount;
			    inv.ediscount = stockUtils.ediscount(org_price, tag_price);
			    inv.vir_price = vir_price;
			    inv.draw      = draw;
			    inv.contailer = contailer;
			    inv.sid       = update.score === 0 ? -1 : inv.sid;
			    console.log(inv);}); 
		} else {
		    dialog.response(
			false,
			"库存价格编辑",
			"编辑库存价格失败："
			    + purchaserService.error[result.ecode]);
		}
	    });
	};

	var yes_no = stockUtils.yes_no(); 
	dialog.edit_with_modal(
	    "stock-update-price.html",
	    undefined,
	    callback,
	    undefined,
	    {
		style_number :inv.style_number,
		brand        :inv.brand.name,
		org_price    :inv.org_price,
		vir_price    :inv.vir_price,
		tag_price    :inv.tag_price,
		discount     :inv.discount,
		draw         :inv.draw,
		contailer    :inv.contailer,
		yes_no       :yes_no,
		is_score     :yes_no[0],
		is_sprice    :yes_no[0],
		stock_contailer: $scope.setting.stock_contailer,
		update_orgprice: $scope.stock_right.show_orgprice,
		hide_vprice  :$scope.setting.hide_vprice,
		hide_draw    :$scope.setting.hide_draw
	    }
	);
    };

    $scope.gift_stock = function(inv) {
	console.log(inv);
	var condition = {style_number:inv.style_number, brand:inv.brand.id, shop:inv.shop_id};
	purchaserService.gift_stock(condition, {gift:inv.gift}).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "赠送标识设置",
		    "赠送标识设置成功！！",
		    undefined,
		    function() {inv.gift = result.gift;});
	    } else {
		dialog.response(
		    false,
		    "赠送标识设置",
		    "赠送标识设置失败："
			+ purchaserService.error[result.ecode]);
	    }
	});
    };

    $scope.copy_stock = function(inv) {
	diabloFilter.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand.id}
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		if (!diablo_is_empty(result.data)) {
		    dialog.set_error("复制库存属性", 2082); 
		} else {
		    purchaserService.copy_stock_attr(
			inv.style_number, inv.brand.id, inv.shop_id
		    ).then(function(result) {
			if (result.ecode === 0){
			    dialog.response(
				true, "复制库存属性", "复制库存属性成功！！");
			} else {
			    dialog.set_error("复制库存属性", result.ecode); 
			}
		    })
		} 
	    } else {
		var error = require("diablo-error");
		dialog.response(
		    false,
		    "获取货品资料", "获取货品资料失败：" + error[result.ecode]);
	    }
	}) 
    };

    $scope.offering_stock = function(inv) {
	console.log(inv);
	var condition = {style_number:inv.style_number, brand:inv.brand.id, shop:inv.shop_id};
	purchaserService.offering_stock(condition, {state:inv.state}).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "特价标识设置",
		    "特价标识设置成功！！",
		    undefined,
		    function() {inv.state = result.state;})
	    } else {
		dialog.set_error(false, "特价标识设置", result.ecode); 
	    }
	});
    };

    $scope.update_alarm_a = function(inv){
	console.log(inv);

	var callback = function(params){
	    console.log(params.amounts); 
	    var update_amounts = [];
	    var min = params.amounts[0].alarm_a;
	    for (var i=0, l=params.amounts.length; i<l; i++){
		if (min > params.amounts[i].alarm_a)
		    min = params.amounts[i].alarm_a;
		
		for (var j=0, k=inv.amounts.length; j<k; j++){
		    if (params.amounts[i].cid === inv.amounts[j].cid
			&& params.amounts[i].size === inv.amounts[j].size
			&& params.amounts[i].alarm_a !== inv.amounts[j].alarm_a)
			update_amounts.push(params.amounts[i]);
		}
	    }

	    console.log(update_amounts);

	    var condition = {style_number:inv.style_number, brand:inv.brand.id, shop:inv.shop_id};
	    purchaserService.update_w_inventory_alarm(
		condition, {alarm_a:min, amount:update_amounts}).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "库存预警编辑", "修改库存预警数量成功！！", undefined,
			function(){
			    inv.amounts = params.amounts;
			    inv.alarm_a = min;
			}); 
		} else {
		    dialog.response(
			false,
			"库存预警编辑",
			"修改库存预警数量失败："
			    + purchaserService.error[result.ecode]);
		}
	    });
	    
	};
	
	var get_amount = function(cid, size, amounts){
	    return purchaserService.get_inventory_from_sort(cid, size, amounts)};

	var check_valid = function(amounts) {
	    for (var i=0, l=amounts.length; i<l; i++){
		if (angular.isUndefined(diablo_set_integer(amounts[i].alarm_a)))
		    return false;
	    }
	    return true;
	};
	
	if (angular.isDefined(inv.sizes) && angular.isDefined(inv.colors) && angular.isDefined(inv.amounts)){
	    var payload = {sizes:      inv.sizes,
			   colors:     inv.colors,
			   path:       inv.path,
			   amounts:    inv.amounts,
			   check_valid: check_valid,
			   get_amount: get_amount 
			  };
	    
	    dialog.edit_with_modal(
		"inventory-update-stock-alarm.html",
		diablo_valid_dialog(inv.sizes),
		callback,
		undefined,
		payload);
	} else{
	    purchaserService.list_purchaser_inventory(
		{style_number: inv.style_number,
		 brand:        inv.brand_id,
		 rsn:          $routeParams.rsn ? $routeParams.rsn:undefined,
		 shop:         inv.shop_id,
		 qtype:        1}
	    ).then(function(invs){
		console.log(invs);
		var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		console.log(order_sizes);
		var sort    = diabloHelp.sort_stock(invs, order_sizes, filterColor);
		console.log(sort);
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort;

		var payload = {sizes:       inv.sizes,
			       colors:      inv.colors,
			       path:        inv.path,
			       amounts:     inv.amounts,
			       check_valid: check_valid,
			       get_amount:  get_amount};
		dialog.edit_with_modal(
		    "inventory-update-stock-alarm.html",
		    diablo_valid_dialog(inv.sizes),
		    callback,
		    $scope,
		    payload); 
	    }) 
	}
    };

    $scope.stock_flow = function(inv){
	console.log(inv);
	$scope.goto_page("#/inventory_detail/inventory_flow"
			 + "/" + inv.style_number.replace("#", "%23")
			 + "/" + inv.brand_id.toString());
    };
};

function purchaserInventoryHistoryCtrlProvide(
    $scope, dateFilter, diabloPattern, diabloFilter, diabloUtilsService, purchaserService,
    filterShop, user){
    $scope.filters = [];
    diabloFilter.reset_field();

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.hstocks = [];
    
    var now = stockUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);

    var get_stock = function(stocks) {
	return stocks.length === 0 ? {} : stocks[0];
    };
    
    $scope.do_search = function() {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search) {
	    console.log(search);
	    purchaserService.analysis_history_stock(search).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    $scope.hstocks = [];
		    diablo_order(result.data);
		    for (var i=0, l=result.data.length; i<l; i++) {
			$scope.hstocks.push(
			    {order_id  :result.data[i].order_id,
			     shop_id   :result.data[i].shop_id,
			     shop_name :result.data[i].shop_name});
			var metric = {stock_in:
				      {total:0, cost:0, over:0, ocost:0},
				      stock_out:
				      {total:0, cost:0},
				      transfer_in:
				      {total:0, cost:0},
				      transfer_out:
				      {total:0, cost:0},
				      sale:
				      {total:0, balance:0, cost:0}
				     };
			for (var j=0, k=result.data[i].stock.length; j<k; j++) {
			    var s = result.data[i].stock[j];
			    var stock_in     = get_stock(s.stock_in);
			    var stock_out    = get_stock(s.stock_out);
			    var transfer_in  = get_stock(s.transfer_in);
			    var transfer_out = get_stock(s.transfer_out);
			    var sale         = get_stock(s.sale);
			    $scope.hstocks.push(
				{firm_id      :s.firm_id,
				 firm         :s.firm,
				 stock_in     :stock_in,
				 stock_out    :stock_out,
				 transfer_in  :transfer_in,
				 transfer_out :transfer_out,
				 sale         :sale});
			    
			    metric.stock_in.total  += stockUtils.to_integer(stock_in.total);
			    metric.stock_in.cost   += stockUtils.to_float(stock_in.cost);
			    metric.stock_in.over   += stockUtils.to_integer(stock_in.over);
			    metric.stock_in.ocost  += stockUtils.to_float(stock_in.ocost);

			    metric.stock_out.total += stockUtils.to_integer(stock_out.total);
			    metric.stock_out.cost  += stockUtils.to_float(stock_out.cost);

			    metric.transfer_in.total +=  stockUtils.to_integer(transfer_in.total);
			    metric.transfer_in.cost  +=  stockUtils.to_float(transfer_in.cost);

			    metric.transfer_out.total +=  stockUtils.to_integer(transfer_out.total);
			    metric.transfer_out.cost  +=  stockUtils.to_float(transfer_out.cost);

			    metric.sale.total += stockUtils.to_integer(sale.total);
			    metric.sale.balance += stockUtils.to_float(sale.balance);
			    metric.sale.cost += stockUtils.to_float(sale.cost);
			    
			}

			metric.stock_in.cost     = stockUtils.to_decimal(metric.stock_in.cost);
			metric.stock_in.ocost    = stockUtils.to_decimal(metric.stock_in.ocost); 
			metric.stock_out.cost    = stockUtils.to_decimal(metric.stock_out.cost); 
			metric.transfer_in.cost  = stockUtils.to_decimal(metric.transfer_in.cost);
			metric.transfer_in.cost  = stockUtils.to_decimal(metric.transfer_in.cost);
			metric.transfer_out.cost = stockUtils.to_decimal(metric.transfer_out.cost);
			metric.sale.balance      = stockUtils.to_decimal(metric.sale.balance);
			metric.sale.cost      = stockUtils.to_decimal(metric.sale.cost);
			
			$scope.hstocks.push(metric); 
		    }
		    console.log($scope.hstocks);
		}
	    })
	});
    }

    
    $scope.refresh = function() {
	$scope.do_search(); 
    };

    $scope.go_back = function() {
	diablo_goto_page("#/inventory_detail");
    } 
};

function purchaserInventoryNewDetailCtrlProvide (
    $scope, $routeParams, $location, dateFilter, diabloPattern,
    diabloUtilsService, localStorageService, diabloFilter, purchaserService,
    user, filterFirm, filterEmployee, filterBrand, filterRegion, base){
    // console.log(user);
    // console.log(filterFirm);
    // console.log(filterEmployee);
    // console.log(filterRegion);

    $scope.shops   = user.sortShops;
    $scope.shopIds = user.shopIds;
    $scope.regions = filterRegion;

    $scope.f_add   = diablo_float_add;
    $scope.f_sub   = diablo_float_sub;
    $scope.round   = diablo_round;
    $scope.total_items  = 0;
    $scope.css = diablo_stock_css;
    $scope.css_gift_stock = function(state) {return state === 2 ? "success" : "";};
    

    $scope.base_setting = {
	check_firm:  stockUtils.stock_mode(-1, base).check_c_firm,
	check_price: stockUtils.stock_mode(-1, base).check_c_price
    };

    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.shop_right = authen.authenStockRight();
    
    $scope.hidden = {base:true, balance:true, comment:true};
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };
    
    $scope.toggle_balance = function(){
	$scope.hidden.balance = !$scope.hidden.balance;
    };
    
    $scope.toggle_comment = function(){
	$scope.hidden.comment = !$scope.hidden.comment;
    };


    var now    = $.now();
    var dialog = diabloUtilsService;
    var return_back_page = angular.isDefined($routeParams.page) ? true : false;
    if (return_back_page) $location.path("/inventory_new_detail", false);

    $scope.add = function(){
	diablo_goto_page('#/inventory_new');
    }

    $scope.reject = function(){
	diablo_goto_page('#/inventory_reject');
    }

    $scope.inventory_detail = function(){
	diablo_goto_page('#/inventory_detail');
    }

    $scope.inventory_rsn_detail = function(){
	diablo_goto_page('#/inventory_rsn_detail');
    }
    
    $scope.trans_detail = function(r){
	// $scope.save_stastic();
	diablo_goto_page('#/inventory_rsn_detail/' + r.rsn + "/" + $scope.current_page.toString());
    };

    $scope.update_detail = function(r){
	// $scope.save_stastic(); 
	if (r.type === 0){
	    diablo_goto_page(
		'#/update_new_detail/' + r.rsn + "/" + $scope.current_page.toString());
	} else{
	    diablo_goto_page(
		'#/update_new_detail_reject/' + r.rsn + "/" + $scope.current_page.toString());
	}
    };
    
    $scope.check_detail = function(r){
	// console.log(r);
	if (diablo_yes === $scope.base_setting.check_firm && r.firm_id === diablo_invalid_firm) {
	    diabloUtilsService.response(
	    	false, "入库单审核", "入库单审核失败：" + purchaserService.error[2013]);
	} else {
	    purchaserService.check_w_inventory_new(
		r.rsn,
		$scope.base_setting.check_firm,
		$scope.base_setting.check_price).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "入库单审核", "入库单审核成功！！单号：" + state.rsn,
			$scope, function(){r.state = diablo_stock_has_checked})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "入库单审核",
	    		"入库单审核失败：" + purchaserService.error[state.ecode]);
		}
	    }) 
	} 
    };

    $scope.uncheck_detail = function(r){
	console.log(r);
	purchaserService.uncheck_w_inventory_new(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "入库单反审", "入库单反审成功！！单号：" + state.rsn,
		    $scope, function(){r.state = 0})
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "入库单反审",
	    	    "入库反审失败：" + purchaserService.error[state.ecode]);
	    }
	})
    };

    $scope.delete_detail = function(r){
	var callback = function(){
	    purchaserService.delete_w_inventory_new(
		r.rsn, diablo_delete
	    ).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "入库单删除", "入库单删除成功！！单号：" + state.rsn,
			$scope, function(){$scope.do_search($scope.current_page)})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "入库单删除",
	    		"入库删除失败：" + purchaserService.error[state.ecode]);
		}
	    })
	}
	
	dialog.request(
	    "入库单删除", "入库单删除后，无法恢复，确认要删除吗？",
	    callback, undefined, undefined);
    };

    $scope.abandon_detail = function(r){
	var callback = function(){
	    purchaserService.delete_w_inventory_new(
		r.rsn, diablo_abandon
	    ).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "入库单废弃", "入库单废弃成功！！单号：" + state.rsn,
			$scope, function(){r.state=diablo_stock_has_abandoned})
	    	    return;
		} else{
	    	    diabloUtilsService.response(
	    		false, "入库单废弃",
	    		"入库废弃失败：" + purchaserService.error[state.ecode]);
		}
	    })
	}
	
	dialog.request(
	    "入库单废弃", "入库单废弃后，无法恢复，确认要废弃吗？",
	    callback, undefined, undefined);
    };

    $scope.print_detail = function(r) {
	var callback = function() {
	    diablo_goto_page("#/print_inventory_new/" + r.rsn);
	}
	
	dialog.request(
	    "采购单打印", "采购单打印需要打印机支持A4纸张，确认要打印吗？",
	    callback, undefined, undefined);
    };

    
    /*
    * filter
    */ 
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, user.shopIds)
    };

    $scope.save_stastic = function(){
	localStorageService.set(
	    "inventory-trans-stastic",
	    {total_items:      $scope.total_items,
	     total_amounts:    $scope.total_amounts,
	     total_spay:       $scope.total_spay,
	     total_hpay:       $scope.total_hpay,
	     total_cash:       $scope.total_cash,
	     total_card:       $scope.total_card,
	     total_wire:       $scope.total_wire,
	     total_verificate: $scope.total_verificate,
	     t:                now});
    };
    
    // var has_pay =  [{name:">0", id:0, py:diablo_pinyin("大于0")},
    // 		    {name:"=0", id:1, py:diablo_pinyin("等于0")}];
    
    // initial
    // $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("firm",     filterFirm); 
    diabloFilter.add_field("shop",     $scope.shops);
    // diabloFilter.add_field("season",   diablo_season2objects);
    diabloFilter.add_field("region",   $scope.regions);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("check_state", purchaserService.check_state);
    diabloFilter.add_field("purchaser_type", purchaserService.purchaser_type);
    if ($scope.shop_right.check_w_stock) {
	diabloFilter.add_field("org_price", []);
    }
    diabloFilter.add_field("over", stockUtils.over_flow()); 
    diabloFilter.add_field("rsn", function(viewValue) {return undefined});
    // diabloFilter.add_field("has_pay",  has_pay);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt);

    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;


    var storage = localStorageService.get(diablo_key_inventory_trans);
    // console.log(storage);

    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters      = storage.filter;
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else{
	$scope.filters     = [];
	$scope.qtime_start = now;
	$scope.qtime_end   = now;
	// $scope.qtime_start = function(){
	//     var shop = -1;
	//     if ($scope.shopIds.length === 1){
	// 	shop = $scope.shopIds[0];
	//     };
	//     return diablo_base_setting(
	// 	"qtime_start", shop, base, diablo_set_date,
	// 	diabloFilter.default_start_time(now));
	// }();
    };
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start, $scope.qtime_end);

    // var back_page = diablo_set_integer($routeParams.page);
    // if (angular.isDefined(back_page)){
    // 	$scope.current_page = back_page;
    // } else{
    // 	$scope.current_page = $scope.default_page; 
    // };
    
    var add_search_condition = function(search){
	if (stockUtils.to_integer(search.region) === 0){
	    if (angular.isUndefined(search.shop) || search.shop.length === 0){
		search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds; 
	    }
	} else {
	    if (angular.isArray(search.shop) && search.shop.length !== 0){
		delete search.region;
	    } else {
		search.shop = $scope.shops.filter(function(s){
		    return s.region === search.region;
		}).map(function(s) { return s.id});
	    }
	}
	// only in and out
	if (angular.isUndefined(search.purchaser_type))
	    search.purchaser_type = [0, 1];
    };
    
    $scope.do_search = function(page){
	// console.log(page);
	$scope.current_page = page; 

	stockUtils.cache_page_condition(
	    localStorageService,
	    diablo_key_inventory_trans,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now);

	if (page !== $scope.default_page){
	    var stastic = localStorageService.get("inventory-trans-stastic");
	    console.log(stastic);
	    $scope.total_items      = stastic.total_items;
	    $scope.total_amounts    = stastic.total_amounts;
	    $scope.total_spay       = stastic.total_spay;
	    $scope.total_hpay       = stastic.total_hpay;
	    $scope.total_cash       = stastic.total_cash;
	    $scope.total_card       = stastic.total_card;
	    $scope.total_wire       = stastic.total_wire;
	    $scope.total_verificate = stastic.total_verificate;
	} 
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.filter_w_inventory_new(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items      = result.total
			$scope.total_amounts    = result.t_amount;
			$scope.total_spay       = result.t_spay;
			$scope.total_hpay       = result.t_hpay;
			$scope.total_cash       = result.t_cash;
			$scope.total_card       = result.t_card;
			$scope.total_wire       = result.t_wire;
			$scope.total_verificate = result.t_verificate;

			$scope.records = [];
			$scope.save_stastic();
		    }
		    
		    angular.forEach(result.data, function(d){
			d.firm = diablo_get_object(d.firm_id, filterFirm);
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.acc_balance =
			    stockUtils.to_decimal(
				d.balance + d.should_pay + d.e_pay - d.has_pay - d.verificate);
		    });
		    
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		}) 
	})
    };

    if ($scope.current_page !== $scope.default_page){
	$scope.do_search($scope.current_page); 
    } else if (return_back_page){
	$scope.do_search($scope.current_page); 
    }

    $scope.refresh = function() {
	$scope.do_search($scope.default_page);
	// localStorageService.remove("inventory-trans-stastic"); 
    };
    
    $scope.page_changed = function(){
	// console.log($scope.current_page);
	$scope.do_search($scope.current_page);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    // console.log(search);
	    
	    purchaserService.csv_export(purchaserService.export_type.trans, search)
		.then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			dialog.response(
			    false, "文件导出失败", "创建文件失败："
				+ purchaserService.error[result.ecode]);
		    } 
		}); 
	}) 
    };
    
};

define (["purchaserApp"], function(app){
    app.controller("purchaserInventoryNewCtrl", purchaserInventoryNewCtrlProvide);
    app.controller("purchaserInventoryDetailCtrl", purchaserInventoryDetailCtrlProvide);
    app.controller("purchaserInventoryHistoryCtrl", purchaserInventoryHistoryCtrlProvide);
    app.controller("purchaserInventoryNewDetailCtrl", purchaserInventoryNewDetailCtrlProvide);
});
