purchaserApp.controller("purchaserInventoryNewCtrl", function(
    $scope, $timeout, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, wgoodService, purchaserService, shortCutGoodService,
    localStorageService, user, filterBrand, filterType,
    filterSizeGroup, filterFirm, filterEmployee, filterColor,
    filterColorType, base){
    // console.log(user);
    // console.log(filterColor);
    $scope.brands      = filterBrand;
    $scope.types       = filterType;
    $scope.size_groups = filterSizeGroup;
    $scope.firms       = filterFirm;
    $scope.colors      = filterColor;
    $scope.color_types = filterColorType;
    $scope.grouped_colors = [];
    
    $scope.tab_active  = [{active:true}, {active:false}, {active:false}]; 
    $scope.shops             = user.sortShops; 
    $scope.sexs              = diablo_sex;
    $scope.seasons           = diablo_season;
    $scope.extra_pay_types   = purchaserService.extra_pay_types;

    $scope.season2objs       = diablo_season2objects;
    $scope.sex2objs          = diablo_sex2object; 
    $scope.float_add         = diablo_float_add;
    $scope.float_sub         = diablo_float_sub;
    $scope.float_mul         = diablo_float_mul;
    $scope.round             = diablo_round;
    $scope.full_years        = diablo_full_year;
    $scope.calc_row          = stockUtils.calc_row;
    
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
    $scope.stock_right = {
	show_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	),

	show_balance: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_balance_onstock'],
	    user.right
	)
    }; 

    $scope.$watch("select.firm", function(newValue, oldValue){
	if (newValue === oldValue) return; 
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
	$scope.get_prompt_good(); 
    };

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.select.form.cardForm.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	$scope.select.form.vForm.$invalid     = false;
	$scope.select.form.wireForm.$invalid  = false;
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
	else if ($scope.tab_active[1].active)
	    $scope.on_focus_attr("style_number");
    };
    
    // init
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});

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
		       	employee:diablo_get_object(p[2], $scope.employees)}
	    });
	};

	var select = function(draft, resource){
	    $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
	    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops);
	    // $scope.select.frim = diablo_get_object(draft.firm.id, $scope.firms);
	    $scope.inventories = angular.copy(resource);
	    for (var i=0, l=$scope.inventories.length; i<l; i++){
		var inv = $scope.inventories[i];
		if (diablo_invalid_firm !== inv.firm_id){
		    $scope.select.firm = diablo_get_object(inv.firm_id, $scope.firms);
		}
	    }
	    
	    $scope.inventories.unshift({$edit:false, $new:true});
	    $scope.disable_refresh = false;
	    $scope.re_calculate();
	    $scope.auto_focus("style_number");
	};

	sDraft.select(diabloUtilsService, "inventory-draft.html", draft_filter, select); 
    };

    $scope.change_shop = function(){
	sDraft.change_key(undefined, $scope.select.shop.id, $scope.select.employee.id);
	$scope.base_settings.m_sgroup = stockUtils.multi_sizegroup($scope.select.shop.id, base);
	$scope.base_settings.t_trace = stockUtils.t_trace($scope.select.shop.id, base);
	$scope.base_settings.group_color = stockUtils.group_color($scope.select.shop.id, base);

	$scope.q_prompt = $scope.q_typeahead($scope.select.shop.id, base);
	$scope.get_prompt_good(); 
	$scope.get_employee();
    };
    
    $scope.prompt_limit = stockUtils.prompt_limit($scope.select.shop.id, base);

    $scope.base_settings = {
	m_sgroup: stockUtils.multi_sizegroup($scope.select.shop.id, base),
	t_trace: stockUtils.t_trace($scope.select.shop.id, base),
	group_color: stockUtils.group_color($scope.select.shop.id, base)
    };
    
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
	return diabloFilter.match_wgood_with_firm(
	    viewValue,
	    stockUtils.match_firm($scope.select.firm)); 
    };

    $scope.q_prompt = $scope.q_typeahead($scope.select.shop.id, base); 
    $scope.qtime_start = function(shopId){
	var now = $.now();
	return stockUtils.start_time(shopId, base, now, dateFilter); 
    };
    
    $scope.get_all_w_good = function(){
	// console.log(select_firm);
	diabloFilter.match_all_w_good(
	    $scope.qtime_start($scope.select.shop.id),
	    stockUtils.match_firm($scope.select.firm)
	).then(function(goods){
	    $scope.all_w_goods = goods.map(function(g){
		var p = stockUtils.prompt_name(g.style_number, g.brand, g.type);
		return angular.extend(g, {name:p.name, prompt:p.prompt}); 
	    });

	    // console.log($scope.all_w_goods);
	});
    };

    $scope.get_prompt_good = function(){
	if ($scope.q_prompt === diablo_frontend){
    	    $scope.get_all_w_good();
	}
    }; 
    $scope.get_prompt_good();

    var copy_select = function(add, src){
	add.$new_good    = src.$new_good;
	add.id           = src.id; 
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.sex          = src.sex;
	add.firm_id      = src.firm_id;
	add.year         = src.year; 
	add.season       = src.season;
	// add.pid          = src.pid;
	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price;
	add.ediscount    = src.ediscount;
	add.discount     = src.discount;
	add.path         = src.path;
	add.alarm_day    = src.alarm_day;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.sizes        = src.size.split(",");
	add.colors       = src.color.split(",");
	add.over         = 0;
	
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
	console.log($scope.inventories); 
	// has been added
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false,
		    "新增库存",
		    "新增库存失败：" + purchaserService.error[2099]
			+ "入库编号：" + $scope.inventories[i].order_id,
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
		    "新增库存",
		    "新增库存失败：" + purchaserService.error[2093],
		    $scope, function(){
			$scope.inventories[0] = {$edit:false, $new:true};
			if ($scope.tab_active[1].active){
			    $scope.reset_style_number();
			}
		    });
		return;
	    };
	}
	
	if (-1 !== item.firm_id){
	    $scope.select.firm = diablo_get_object(item.firm_id, $scope.firms);
	}

	// auto focus
	$scope.auto_focus("sale");
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = copy_select(add, item); 
	console.log(add);
	if (!add.free_color_size || $scope.tab_active[1].active){
	    $scope.add_inventory(add)
	} else {
	    if (diablo_yes === $scope.base_settings.t_trace
		&& (angular.isUndefined(add.$new_good) || !add.$new_good) ){
		purchaserService.get_purchaser_tagprice({
		    style_number: add.style_number,
		    brand:        add.brand_id,
		    shop:         $scope.select.shop.id
		}).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			if (!diablo_is_empty(result.data)){
			    add.org_price = result.data.org_price;
			    add.tag_price = result.data.tag_price;
			    add.discount  = result.data.discount;
			    add.ediscount = result.data.ediscount;
			} else {
			    add.tag_price = 0;
			    add.discount  = 0;
			} 
		    }
		})
	    }
	}
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
	    if (diablo_invalid_firm !== add.firm_id
		&& add.firm_id !== stockUtils.invalid_firm($scope.select.firm)){
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
		// promotion   : add.pid,
		org_price   : diablo_set_float(add.org_price),
		tag_price   : diablo_set_float(add.tag_price), 
		ediscount   : diablo_set_float(add.ediscount),
		discount    : diablo_set_float(add.discount),
		
		path        : add.path,
		alarm_day   : add.alarm_day,
		total       : add.total,
		score       : $scope.select.shop.score_id 
	    })
	};

	var setv = diablo_set_float; 
	var e_pay = setv($scope.select.extra_pay);
	
	var base = {
	    // brand:         $scope.select.brand.id,
	    firm:          angular.isDefined($scope.select.firm)
		&& $scope.select.firm ? $scope.select.firm.id : undefined,
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
	    
	    e_pay_type:     angular.isUndefined(e_pay)
		? undefined : $scope.select.extra_pay_type.id,
	    e_pay:          e_pay,
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
		    $scope, function(){
			sDraft.remove();
			$scope.refresh();
		    })
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false, "新增库存",
	    	    "新增库存失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false})
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
	    $scope.re_calculate();

	    // auto focus
	    if ($scope.tab_active[1].active) $scope.reset_style_number();
	    else $scope.auto_focus("style_number");
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
			       right:        $scope.stock_right,
			       get_amount:    get_amount,
			       valid_amount:  valid_amount,
			       get_price_info: stockUtils.calc_stock_orgprice_info,
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
			"inventory-new.html",
			modal_size, callback, undefined, payload)
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
		    } else {
			inv.tag_price = 0;
			inv.discount  = 0;
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
     * update inventory
     */
    $scope.update_inventory = function(inv){
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
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
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
		       right:      $scope.stock_right,
		       get_amount: get_amount,
		       valid_amount: valid_amount,
		       get_price_info: stockUtils.calc_stock_orgprice_info};
	diabloUtilsService.edit_with_modal(
	    "inventory-new.html", modal_size, callback, $scope, payload)
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
		      type:  diabloPattern.head_ch_en_num};

    $scope.focus_attrs = {style_number:true,
			  brand:false,
			  type:false,
			  // sex:false,
			  // year:false,
			  // season:false,
			  tag_price:false,
			  discount:false,
			  color:false,
			  size:false,
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
	$scope.on_focus_attr("style_number");
	console.log($scope.focus_attrs);

	if (angular.isUndefined($scope.all_w_goods)
	    || $scope.all_w_goods.length === 0){
	    $scope.get_all_w_good();
	}
    };

    $scope.on_select_good_new = function(item, model, label){
	console.log(item);
	$scope.good.$new_good = false;
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
	    $scope.is_same_good = true;
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

    $scope.group_color_with_8 = function(){
	var color = {};
	$scope.grouped_colors = [];
	for (var i=0, g=0, l=$scope.colors.length; i<l; i++){
	    var gc = $scope.colors[i];
	    if (i <= (g+1)*10 - 1){
		color[(i - g * 10).toString()] = {id:gc.id, name:gc.name, py:diablo_pinyin(gc.name)};
	    } 
	    if (i === (g+1) * 10){
		$scope.grouped_colors.push(color);
		g++;
		color = {};
		color[(i - g * 10).toString()] = {id:gc.id, name:gc.name, py:diablo_pinyin(gc.name)};
	    }
	} 
	$scope.grouped_colors.push(color); 
    };

    if (diablo_no === $scope.base_settings.group_color){
	$scope.group_color_with_8(); 
    }
    
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
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
		    
		    if (diablo_no === $scope.base_settings.group_color){
			$scope.group_color_with_8(); 
		    }
		}; 
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){append_color(state.id)});
		} else{
		    dialog.response(
			false, "新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html', undefined, callback,
	    $scope, {color: {types: $scope.color_types}})
    };

    $scope.select_color = function(){
	var callback = function(params){
	    console.log(params.colors);
	    
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
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html", 'lg',
	    callback, $scope, {colors:$scope.gcolors});
    };

    $scope.select_grouped_color = function(){
	var callback = function(params){
	    // console.log(params.colors);
	    // console.log(params.ucolors);
	    
	    $scope.selectColors = []; 
	    $scope.good.colors="";

	    for (var i=0, l1=params.colors.length; i<l1; i++){
		for (j in params.colors[i]){
		    var c = params.colors[i][j];
		    if(angular.isDefined(c.select) && c.select){
			$scope.good.colors += c.name + "；";
			$scope.selectColors.push(angular.copy(c));
		    }
		}
	    }
	    
	    console.log($scope.selectColors); 
	    $scope.grouped_colors = angular.copy(params.colors);
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
	     ucolors: function(){
		 var ucolors = [];
		 for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
		     for (j in $scope.grouped_colors[i]){
			 ucolors.push($scope.grouped_colors[i][j]); 
		     }
		 }

		 return ucolors;
	     }(),
	     on_select_ucolor: on_select_ucolor});
    };
    
    /*
     * size group
     */
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
	};

	var select_group = function(groups, g){
	    for(var i=0, l=groups.length; i<l; i++){
		if (groups[i].id !== g.id
		    && diablo_no === $scope.base_settings.m_sgroup){
		    groups[i].select = false;
		}
	    }
	}

	diabloUtilsService.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.size_groups,
			       select_group: select_group});
    };

    /*
     * good amount
     */
    $scope.new_good_amount = function(){
	var add = $scope.inventories[0]; 
    };

    /*
     * new good
     */
    var current_month = new Date().getMonth();
    $scope.form = {};
    $scope.good_saving = false; 
    $scope.good = {
	sex       : $scope.sex2objs[stockUtils.d_sex($scope.select.shop.id, base)],
	org_price : 0, 
	tag_price : 0, 
	ediscount : 0,
	discount  : 100,
	alarm_day : 7,
	year      : diablo_now_year(),
	season    : $scope.season2objs[stockUtils.valid_season(current_month)]
    };

    $scope.new_good = function(){
	if ($scope.form.gForm.$invalid || $scope.is_same_good || $scope.good_has_saved) return; 

	$scope.good_saving = true; 
	var good       = angular.copy($scope.good);
	good.firm      = angular.isDefined($scope.select.firm)
	    && $scope.select.firm ? $scope.select.firm.id : undefined;
	good.season    = good.season.id;
	good.sex       = good.sex.id;
	// good.promotion = good.promotion.id;
	
	good.brand    = typeof(good.brand) === "object" ? good.brand.name: good.brand; 
	good.type     = typeof(good.type) === "object" ? good.type.name: good.type;
	
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
	var image  = angular.isDefined($scope.image) && $scope.image
	    ? $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "") : undefined;
	
	// console.log(image);
	
	wgoodService.add_purchaser_good(good, image).then(function(state){
	    // console.log(state);
	    $scope.good_saving = false;
	    if (state.ecode == 0){
		// reset color
		$scope.selectColors = [];
		$scope.good.colors="";
		angular.forEach($scope.gcolors, function(colorInfo){
		    angular.forEach(colorInfo, function(color){
			// console.log(color);
			angular.forEach(color, function(c){
			    if (angular.isDefined(c.select)){
				c.select = false;
			    }
			}) 
		    })
		});
		console.log($scope.gcolors); 

		if (diablo_no === $scope.base_settings.group_color){
		    for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
			for (j in $scope.grouped_colors[i]){
			    if (angular.isDefined($scope.grouped_colors[i][j].select)){
				$scope.grouped_colors[i][j].select = false;
			    }
			}
		    }
		    console.log($scope.grouped_colors); 
		};

		// reset
		// $scope.good.style_number = undefined;
		// $scope.form.gForm.style_number.$pristine = true; 
		// $scope.good.type = undefined;
		// $scope.form.gForm.type.$pristine = true;
		
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
		}; 
		// console.log($scope.brands);

		// type
		if (!in_prompts($scope.types, good.type)){
		    $scope.types.push({
			id   :state.type,
			name :good.type,
			py   :diablo_pinyin(good.type)});
		};

		// cons.log($scope.types); 
		var sg = s_groups.length === 0 ? "0":s_groups.toString();
		var ss = s_sizes.length === 0 ? "0":s_sizes.toString();
		var sc = angular.isUndefined(good.colors)
		    ? "0" : good.colors.toString();
		var free = (sg === "0" && ss === "0" && sc === "0") ? 0:1;
		var p = stockUtils.prompt_name(
		    good.style_number, good.brand, good.type);
		
		var agood = {
		    $new_good: true,
		    id          : good.db,
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
		    tag_price: good.tag_price,
		    ediscount: good.ediscount,
		    discount:  good.discount,
		    alarm_day: good.alarm_day,

		    free:      free,
		    s_group:   sg,
		    size:      ss,
		    color:     sc
		};

		if ($scope.q_prompt === diablo_frontend){
		    if (angular.isDefined($scope.all_w_goods)){
			$scope.all_w_goods.splice(0, 0, agood); 
		    }
		};

		// $scope.focus.style_number = true;
		$scope.on_select_good(agood, undefined, undefined); 
	    } else{
		diabloUtilsService.response(
		    false, "新增货品",
		    "新增货品 ["
			+ good.style_number + "-" + good.brand + "-"
			+  good.type + "] 失败："
			+ wgoodService.error[state.ecode]);
	    }
	});
    };

    $scope.reset_style_number = function(){
	$scope.on_focus_attr("style_number");
	// $scope.good.style_number = undefined;
	$scope.is_same_good = false;
	// $scope.form.gForm.style_number.$pristine = true; 
	// console.log($scope.focus);
    };

    $scope.reset_brand = function(){
	$scope.on_focus_attr("brand");
	$scope.good.brand = undefined;
	$scope.is_same_good = false;
	$scope.form.gForm.brand.$pristine = true;
    };
    
    $scope.reset = function(){
	$scope.selectGroups = [];
	$scope.selectColors = [];
	$scope.is_same_good = false;
	$scope.good_saving = false;
	
	$scope.good = {
	    brand:     $scope.good.brand,
	    type:      $scope.good.type,
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.season2objs[stockUtils.valid_season(current_month)],
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price, 
	    ediscount: $scope.good.ediscount,
	    discount:  $scope.good.discount,
	    alarm_day: $scope.good.alarm_day
	};

	$scope.form.gForm.style_number.$pristine = true;
	$scope.form.gForm.brand.$pristine = true;
	$scope.form.gForm.type.$pristine = true;
	$scope.form.gForm.tag_price.$pristine = true; 
	$scope.form.gForm.discount.$pristine  = true;
	// $scope.form.gForm.alarm.$pristine     = true;
	$scope.image = undefined;

	//focus
	$scope.on_focus_attr("style_number");
    };
    
});

purchaserApp.controller("purchaserInventoryDetailCtrl", function(
    $scope, $routeParams, $q, dateFilter, diabloPattern, diabloFilter,
    diabloUtilsService, diabloPromise, purchaserService, wgoodService,
    localStorageService, filterPromotion,filterScore,  user, filterBrand,
    filterFirm, filterType, filterSizeGroup, filterColor, base){
    // $scope.touch_start = function(){
    // 	console.log("touch_start");
    // }
    // var data = {
    // 	labels : ["January","February","March","April","May","June","July"],
    // 	datasets : [
    // 	    {
    // 		fillColor : "rgba(220,220,220,0.5)",
    // 		strokeColor : "rgba(220,220,220,1)",
    // 		data : [65,59,90,81,56,55,40]
    // 	    },
    // 	    {
    // 		fillColor : "rgba(151,187,205,0.5)",
    // 		strokeColor : "rgba(151,187,205,1)",
    // 		data : [28,48,40,19,96,27,100]
    // 	    }
    // 	]
    // };

    // $scope.chart.data = data;
    // console.log($scope.promotions);
    $scope.promotions = filterPromotion.concat([{id:diablo_invalid_index, name:"重置促销方案"}]);
    $scope.scores     = filterScore;

    /*
     * tab-set
     */ 
    $scope.tab_active = {time: true, chart:false}; 
    $scope.chart_data = {};
    
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    
    $scope.sexs      = diablo_sex;
    $scope.seasons   = diablo_season;
    $scope.goto_page = diablo_goto_page;
    $scope.total_items = 0;

    /*
     * order
     */
    $scope.order_fields = stockUtils.order_fields();
    $scope.mode = $scope.order_fields.id;
    $scope.sort = 0;

    $scope.stock_right = {
	show_orgprice: stockUtils.authen_rainbow(user.type, user.right, 'show_orgprice'), 
	export_stock:  rightAuthen.authen_master(user.type),
	set_promotion: rightAuthen.authen_master(user.type),
	update_batch:  rightAuthen.authen_master(user.type),
	update_good:   rightAuthen.authen(
	    user.type, rightAuthen.good_action()["update_w_good"], user.right),
    };
    
    $scope.setting = {alarm: false};

    $scope.css =  function(isAlarm){
	return diablo_stock_alarm_css($scope.setting.alarm, isAlarm);
    };


    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };

    /*
     * filter
     */ 

    // initial
    var stocks =  [{name:">0", id:0}, {name:"=0", id:1}];
    $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("style_number", $scope.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    diabloFilter.add_field("type", filterType);
    diabloFilter.add_field("season", diablo_season2objects);
    diabloFilter.add_field("sex",  diablo_sex2object);
    diabloFilter.add_field("year", diablo_full_year);
    diabloFilter.add_field("discount", []);
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("firm", filterFirm);
    diabloFilter.add_field("stock", stocks);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    var storage = localStorageService.get(diablo_key_inventory_detail);
    // console.log(storage);
        
    // alarm, use default shop
    $scope.setting.alarm = diablo_base_setting(
	"stock_alarm", -1, base, parseInt, diablo_no); 

    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    
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
	if ($scope.sort === 0) $scope.sort = 1;
	else if ($scope.sort === 1) $scope.sort = 0;
	$scope.do_search($scope.tab_page.page_of_time);
    }
    
    // filter
    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds;
	    search.shop = $scope.shopIds
		=== 0 ? undefined : $scope.shopIds;
	}; 
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
			$scope.total_items = result.total;
			$scope.total_amount = result.t_amount;
			$scope.total_sell   = result.t_sell;
			$scope.total_lmoney = result.t_lmoney;
		    }
		    angular.forEach(result.data, function(d){
			if (now_date.getTime() - diablo_set_date(d.last_sell)
			    > diablo_day_millisecond * d.alarm_day){
			    d.isAlarm = true;
			} else{
			    d.isAlarm = false;
			}
		    })
		    
		    $scope.inventories = result.data;
		    angular.forEach(result.data, function(d){
			d.brand = diablo_get_object(d.brand_id, filterBrand);
			d.type  = diablo_get_object(d.type_id, filterType);
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			d.promotion = diablo_get_object(d.pid, filterPromotion);
			d.score = diablo_get_object(d.sid, filterScore);
			d.calc  = diablo_float_mul(d.org_price, d.amount);
			// d.shop  = diablo_get_object(d.shop_id, user.sortShops);
		    })
		    diablo_order_page(
			page, $scope.items_perpage, $scope.inventories);

		    console.log($scope.inventories);
		}
	    })
	});
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
	
	if (angular.isDefined(inv.sizes)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.amounts)){
	    var payload = {sizes:      inv.sizes,
			   colors:     inv.colors,
			   path:       inv.path,
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
		var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
		console.log(order_sizes);
		var sort    = purchaserService.sort_inventory(invs, order_sizes, filterColor);
		console.log(sort);
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort;

		var payload = {sizes:      inv.sizes,
			       colors:     inv.colors,
			       path:       inv.path,
			       get_amount: function(cid, size){
				   return get_amount(cid, size, inv.amounts);
			       }};
		dialog.edit_with_modal(
		    "inventory-detail.html", undefined, undefined,
		    $scope, payload, get_amount); 
	    }) 
	}
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    // console.log(search);
	    
	    purchaserService.csv_export(
		purchaserService.export_type.stock, search)
		.then(function(result){
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

	var check_only = function(select, promotions){
	    console.log(select);
	    
	    angular.forEach(promotions, function(p){
		if (p.id !== select.id){
		    p.select = false;
		};
	    });
	};

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

	var select_shops = angular.isNumber(condition.shop)
	    ? [].push(diablo_get_object(condition.shop, $scope.shops))
	    : condition.shop.map(
		function(s){return diablo_get_object(s, $scope.shops)});
	dialog.edit_with_modal(
	    "purchaser-on-sale.html",
	    undefined,
	    callback,
	    undefined,
	    {shops: select_shops,
	     promotions:   $scope.promotions,
	     scores:       $scope.scores.filter(
		 function(s){return s.type_id===0}),
	     check_only:   check_only,
	     check_select: check_select}); 
	
    };

    $scope.update_batch = function(){
	var condition = 
	    diabloFilter.do_filter(
		$scope.filters, $scope.time, function(search){
		    add_search_condition(search); 
		    return search; 
		});

	console.log(condition);

	var callback = function(params){
	    console.log(params);
	    var update = {
		// season: params.select.season,
		// year: params.select.year
		tag_price: diablo_set_integer(params.select.tag_price),
		discount: diablo_set_integer(params.select.discount)
	    };
	    
	    purchaserService.update_w_inventory_batch(
		condition, update 
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

	dialog.edit_with_modal(
	    "stock-update-batch.html",
	    undefined,
	    callback,
	    undefined,
	    {
		check_valid: function(select){
		    for (o in select){
			if ( 0 !== stockUtils.to_integer(select[o]))
			    return false;
		    };

		    return true;
		},
		// years: diablo_full_year,
		// sexs: diablo_sex2object,
		// seasons: diablo_season2objects,
		select: {
		    // sex: diablo_sex2object[0],
		    // season: diablo_season2objects[0],
		    // year: diablo_now_year()},
		}
	    }
	)
    };

    $scope.update_stock = function(inv){
	// console.log(inv); 
	wgoodService.get_purchaser_good(
	    {style_number:inv.style_number, brand:inv.brand.id}
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		diablo_goto_page(
		    "#/good/wgood_update/"
			+ result.data.id + "/"
			+ inv.shop_id + "/"
			+ diablo_from_stock.toString())
	    } else {
		dialog.response(
		    false,
		    "获取货品资料",
		    "获取货品资料失败：" + wgoodService.error[result.ecode]);
	    }
	}) 
    };
});


purchaserApp.controller("purchaserInventoryNewDetailCtrl", function(
    $scope, $routeParams, $location, dateFilter, diabloPattern,
    diabloUtilsService, localStorageService, diabloFilter, purchaserService,
    user, filterFirm, filterEmployee, base){
    // console.log(user);
    // console.log(filterFirm);
    // console.log(filterEmployee);

    $scope.shops   = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds = user.shopIds.concat(user.badrepoIds);

    $scope.f_add   = diablo_float_add;
    $scope.f_sub   = diablo_float_sub;
    $scope.round   = diablo_round;
    $scope.total_items  = 0;
    $scope.css = diablo_stock_css; 

    /*
     * authen
     */
    $scope.shop_right = {
	update_w_stock: rightAuthen.authen_shop_action(
	    user.type,
	    rightAuthen.stock_action()['update_w_stock'],
	    user.shop
	),

	check_w_stock: rightAuthen.authen_shop_action(
	    user.type,
	    rightAuthen.stock_action()['check_w_stock'],
	    user.shop
	),

	delete_w_stock: rightAuthen.authen_shop_action(
	    user.type,
	    rightAuthen.stock_action()['delete_w_stock'],
	    user.shop
	),

	show_balance: rightAuthen.authen_master(user.type)
    };
    
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

    $scope.add = function(){
	diablo_goto_page('#/inventory_new');
    }

    $scope.reject = function(){
	diablo_goto_page('#/inventory_reject');
    }

    $scope.inventory_detail = function(){
	diablo_goto_page('#/inventory_detail');
    }

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

    $scope.trans_detail = function(r){
	$scope.save_stastic();
	diablo_goto_page('#/inventory_rsn_detail/' + r.rsn + "/" + $scope.current_page.toString());
    };

    $scope.update_detail = function(r){
	$scope.save_stastic(); 
	if (r.type === 0){
	    diablo_goto_page(
		'#/update_new_detail/' + r.rsn + "/" + $scope.current_page.toString());
	} else{
	    diablo_goto_page(
		'#/update_new_detail_reject/' + r.rsn + "/" + $scope.current_page.toString());
	}
    };
    
    $scope.check_detail = function(r){
	console.log(r);
	// var callback = function(){
	purchaserService.check_w_inventory_new(r.rsn).then(function(state){
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
	// };

	// dialog.request(
	//     "入库单审核", "审核完成后，入库单将无法修改，确定要审核吗？",
	//     callback, undefined, $scope);
	
    };

    $scope.uncheck_detail = function(r){
	console.log(r);
	purchaserService.uncheck_w_inventory_new(
	    r.rsn, diablo_uncheck
	).then(function(state){
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

    
    /*
    * filter
    */

    // var has_pay =  [{name:">0", id:0, py:diablo_pinyin("大于0")},
    // 		    {name:"=0", id:1, py:diablo_pinyin("等于0")}];
    
    // initial
    // $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("firm",     filterFirm); 
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("check_state", purchaserService.check_state);
    diabloFilter.add_field("purchaser_type", purchaserService.purchaser_type);
    
    diabloFilter.add_field("rsn", []); 
    

    // diabloFilter.add_field("has_pay",  has_pay);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var storage = localStorageService.get(diablo_key_invnetory_trans);
    console.log(storage);

    if (angular.isDefined(storage) && storage !== null){
    	$scope.filters     = storage.filter;
    	$scope.qtime_start = storage.start_time;
    } else{
	$scope.filters = [];
	
	$scope.qtime_start = function(){
	    var shop = -1;
	    if ($scope.shopIds.length === 1){
		shop = $scope.shopIds[0];
	    };
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		diabloFilter.default_start_time(now));
	}();
    };
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    /*
     * pagination 
     */
    $scope.colspan = 18;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;

    var back_page = diablo_set_integer($routeParams.page);
    // console.log(back_page);
    if (angular.isDefined(back_page)){
	$scope.current_page = back_page;
    } else{
	$scope.current_page = $scope.default_page; 
    };
    
    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds.length === 0 ? undefined : user.shopIds;
	    search.shop = $scope.shopIds
		=== 0 ? undefined : $scope.shopIds; 
	}
    };
    
    $scope.do_search = function(page){
	// console.log(page);
	$scope.current_page = page; 
	
	localStorageService.set(
	    diablo_key_invnetory_trans,
	    {filter:$scope.filters,
	     start_time:diablo_get_time($scope.time.start_time),
	     page:page, t:now});

	if (angular.isDefined(back_page)){
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

	    // recover
	    $location.path("/inventory_new_detail", false);
	    $routeParams.page = undefined;
	    back_page = undefined;
	    localStorageService.remove("inventory-trans-stastic");
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);
	    
	    purchaserService.filter_w_inventory_new(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1 && angular.isUndefined(back_page)){
			$scope.total_items      = result.total
			$scope.total_amounts    = result.t_amount;
			$scope.total_spay       = result.t_spay;
			$scope.total_hpay       = result.t_hpay;
			$scope.total_cash       = result.t_cash;
			$scope.total_card       = result.t_card;
			$scope.total_wire       = result.t_wire;
			$scope.total_verificate = result.t_verificate;
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

    if (angular.isDefined(back_page)){
	$scope.do_search($scope.current_page); 
    }

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
    
});
