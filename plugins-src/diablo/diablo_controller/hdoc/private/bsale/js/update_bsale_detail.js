'use strict'

function updateBSaleDetailCtrlProvide(
    $scope, $routeParams, $q, dateFilter, 
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, bsaleService,
    filterEmployee, filterSizeGroup, filterBrand, filterType, filterColor,
    filterRegion, filterDepartment, user, base){
    console.log(user);
    $scope.employees     = filterEmployee;
    $scope.pattern       = {money: diabloPattern.decimal_2}; 
    $scope.shops         = user.sortShops; 
    
    $scope.size_groups   = filterSizeGroup;
    $scope.brands        = filterBrand;
    $scope.colors        = filterColor;
    $scope.types         = filterType;
    $scope.base_settings = base;
    
    $scope.sexs        = diablo_sex;
    $scope.seasons     = diablo_season2objects; 
    $scope.round       = diablo_round;
    $scope.has_saved   = false;
    $scope.setting     = {check_sale:true};

    $scope.sale        = {style_number:undefined};
    $scope.old_select  = {}; 
    $scope.select      = {}; 
    $scope.inventories = [];
    
    $scope.get_object = diablo_get_object; 

    $scope.go_back = function(){
	diablo_goto_page("#/new_bsale_detail");
    };
    
    $scope.re_calculate = function(){
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;

	var calc = bsaleCalc.calculate(
	    $scope.inventories,
	    diablo_reject,
	    $scope.select.verificate,
	    $scope.setting.round,
	    $scope.get_valid_price);
	console.log(calc);
	$scope.select.total      = calc.total;
	$scope.select.abs_total  = calc.abs_total;
	$scope.select.should_pay = calc.should_pay; 
    }; 
    
    // rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    var get_setting = function(shopId){
	angular.extend($scope.setting, bsaleUtils.sale_mode(shopId, base));
	angular.extend($scope.setting, bsaleUtils.batch_mode(shopId, base));
	
	$scope.setting.semployee     = bsaleUtils.select_employee(shopId, base);
	$scope.setting.check_sale    = bsaleUtils.check_sale(shopId, base);
	$scope.setting.negative_sale = bsaleUtils.negative_sale(shopId, base);
	$scope.setting.round         = bsaleUtils.round(shopId, base);
	$scope.setting.barcode_mode  = bsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = bsaleUtils.barcode_auto(shopId, base); 
	$scope.setting.scan_only     = bsaleUtils.to_integer(bsaleUtils.scan_only(shopId, base).charAt(0));
	$scope.setting.type_sale     = bsaleUtils.type_sale(shopId, base);
	// $scope.setting.print_protocal = bsaleUtils.print_protocal(shopId, base);	
	console.log($scope.setting); 
    };
    
    bsaleService.get_batch_sale(rsn, diablo_batch_sale_update_mode).then(function(result){
	// console.log(result);
	if (result.ecode === 0){
	    // result[0] is the record detail
	    var base        = result.sale; 
	    bsaleService.get_bsaler_batch([base.bsaler_id]).then(function(bsalers){
		console.log(bsalers);
		var sells = result.detail;
		var bsale = bsaleUtils.cover_bsale(
		    base,
		    sells,
		    $scope.shops,
		    $scope.brands,
		    bsalers,
		    filterEmployee,
		    $scope.types,
		    $scope.colors,
		    $scope.size_groups,
		    filterRegion);

		console.log(bsale);

		if (angular.isObject(bsale.select.region))
		    bsale.select.department = diablo_get_object(
			bsale.select.region.department_id, filterDepartment);

		if (angular.isObject(bsale.select.department)) {
		    bsale.select.department.master =
			diablo_get_object(bsale.select.department.master_id, filterEmployee); 
		}
		
		$scope.old_select = bsale.select;
		$scope.select = angular.extend($scope.select, bsale.select);
		$scope.select.o_bsaler = $scope.select.bsaler;
		$scope.select.left_balance = $scope.select.surplus;
		
		// setting 
		$scope.setting = {};
		get_setting($scope.select.shop.id, $scope.base_settings);

		$scope.get_valid_price = function(stock) {
		    if (0 === $scope.setting.sale_price)
			return stock.tag_price;
		    else 
			return stock.vir_price;
		};
		
		// var shopId = $scope.select.shop.id;
		// $scope.setting.check_sale = bsaleUtils.check_sale(shopId, $scope.base_settings);
		// $scope.setting.round = bsaleUtils.round(shopId, $scope.base_settings); 
		// $scope.setting.type_sale = bsaleUtils.type_sale(shopId, $scope.base_settings);
		
		// inventory
		$scope.old_inventories = bsale.details;
		// console.log($scope.old_inventories);
		$scope.inventories = angular.copy(bsale.details);
		
		console.log($scope.old_inventories);
		console.log($scope.inventories); 
		$scope.re_calculate();
	    }); 
	}
	
    });

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

    // bsaler;
    $scope.match_bsaler_phone = bsaleService.match_bsaler_phone;
    $scope.match_bsale_prop = bsaleService.match_bsale_prop;

    $scope.set_bsaler = function(){
    	if ($scope.select.bsaler.id !== diablo_invalid_index
	    && $scope.select.bsaler.type_id !== diablo_system_retailer){
    	    $scope.select.surplus = bsaleUtils.to_decimal($scope.select.bsaler.balance);
    	    $scope.select.left_balance = $scope.select.surplus;
    	} 
    };
    
    $scope.on_select_bsaler = function(item, model, label){
	// console.log(item);
	console.log($scope.select.bsaler);
	$scope.set_bsaler();

	$scope.select.region = diablo_get_object($scope.select.bsaler.region_id, filterRegion);
	// console.log($scope.select.region); 
	if (angular.isObject($scope.select.region))
	    $scope.select.department = diablo_get_object($scope.select.region.department_id, filterDepartment);

	console.log($scope.select.department);
	if (angular.isObject($scope.select.department)) {
	    $scope.select.department.master =
		diablo_get_object($scope.select.department.master_id, filterEmployee); 
	}
	
	$scope.re_calculate(); 
    };

    $scope.copy_select = function(add, src){
	// add.id           = src.id;
	add.style_number = src.style_number;
	
	add.brand_id     = src.brand_id;
	add.brand        = $scope.get_object(src.brand_id, $scope.brands);
	
	add.type_id      = src.type_id;
	add.type         = $scope.get_object(src.type_id, $scope.types);
	add.firm_id      = src.firm_id;
	
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;
	
	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price;
	add.vir_price    = src.vir_price;
	add.ediscount    = src.ediscount;
	add.discount     = src.discount;
	
	add.unit         = src.unit;
	add.path         = src.path;
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.entry        = src.entry_date;

	add.full_name    = add.style_number + "/" + add.brand.name + "/" + add.type.name;
	
	console.log(add);
	return add;
	
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);
	// one good can be add only once at the same time
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false,
		    "销售单编辑",
		    "销售单编辑失败：" + bsaleService.error[2191],
		    $scope, function(){})}
	};
	
	// add at first allways 
	var add = {$new:true}; 
	add = $scope.copy_select(add, item);
	console.log(add); 
	$scope.add_inventory(add); 
	return;
    }; 
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	return bsaleUtils.get_valid_id($scope.select.bsaler) === diablo_invalid_index
	    || $scope.has_saved;
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
		    
		    var update_count = parseInt(newAmounts[i].sell_count) - parseInt(oldAmounts[j].sell_count);
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
		     count:     parseInt(newAmounts[i].sell_count)})
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
		     count:     parseInt(oldAmounts[i].sell_count)})
	    }
	}

	console.log(changedAmounts);
	return changedAmounts;
    };
    
    var get_update_inventory = function(){
	var changedInvs = [];
	var found = false;
	for (var i=0, l1=$scope.inventories.length; i < l1; i++){
	    var newInv = $scope.inventories[i];
	    found = false;
	    for (var j=0, l2=$scope.old_inventories.length; j < l2; j++){
		var oldInv = $scope.old_inventories[j];
		// update
		if (newInv.style_number === oldInv.style_number && newInv.brand.id === oldInv.brand.id){
		    var sort_amounts = newInv.amounts.filter(function(a){
			if (angular.isDefined(a.sell_count) && a.sell_count && parseInt(a.sell_count) !== 0){
			    return true;
			}
		    });
		    
		    var change_amouts = get_update_amount(sort_amounts, oldInv.amounts);
		    
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
		if (oldInv.style_number === newInv.style_number && oldInv.brand.id === newInv.brand.id){
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
    
    $scope.save_bsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	console.log($scope.select);

	if (bsaleUtils.get_valid_id($scope.select.bsaler) === diablo_invalid_index
	    || bsaleUtils.get_valid_id($scope.select.employee) === diablo_invalid_index){
	    dialog.response(
		false,
		"销售开单",
		"开单失败：" + bsaleService.error[2192]);
	    $scope.has_saved = false; 
	    return;
	};
	
	var updates = get_update_inventory();
	console.log(updates);
	var added = [];
	
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		// id             : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		brand_name     : add.brand.name,
		type           : add.type.id,
		// type_name   : add.type,
		firm           : add.firm_id,
		sex            : add.sex,
		season         : add.season,
		year           : add.year,
		entry          : add.entry,
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			return add.amounts.filter(function(a){
			    if (angular.isDefined(a.sell_count)
				&& a.sell_count
				&& parseInt(a.sell_count) !== 0){
				return true;
			    }
			})
		    }}(),
		
		sell_total     : parseInt(add.reject),
		unit           : add.unit,

		org_price      : add.org_price,
		ediscount      : add.ediscount, 
		tag_price      : add.tag_price, 
		fprice         : add.fprice,
		rprice         : add.rprice,
		fdiscount      : add.fdiscount,
		rdiscount      : add.rdiscount,
		path           : add.path,
		comment        : add.comment,

		// sizes          : add.sizes,
		s_group        : add.s_group,
		colors         : add.colors,
		free           : add.free,
		// alarm_day      : add.alarm_day
	    })
	};

	var seti = diablo_set_integer;
	var sets = diablo_set_string;

	console.log($scope.old_select); 
	var base = {
	    id:            $scope.select.rsn_id,
	    rsn:           $scope.select.rsn,
	    bsaler:        $scope.select.bsaler.id,
	    shop:          $scope.select.shop.id,
	    prop:          bsaleUtils.get_valid_id($scope.select.sale_prop), 
	    datetime:      dateFilter($scope.select.rsn_datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    
	    balance:       $scope.select.surplus, 
	    cash:          bsaleUtils.to_float($scope.select.cash),
	    card:          bsaleUtils.to_float($scope.select.card),
	    wxin:          bsaleUtils.to_float($scope.select.wxin), 
	    verificate:    bsaleUtils.to_float($scope.select.verificate),
	    should_pay:    bsaleUtils.to_float($scope.select.should_pay),
	    has_pay:       bsaleUtils.to_float($scope.select.has_pay),
	    comment:       sets($scope.select.comment),

	    old_bsaler:    $scope.old_select.bsaler.id, 
	    old_balance:     $scope.old_select.surplus,
	    old_has_pay:     $scope.old_select.has_pay,
	    old_should_pay:  $scope.old_select.should_pay,
	    old_datetime:    dateFilter($scope.old_select.rsn_datetime, "yyyy-MM-dd HH:mm:ss"),	    
	    total:          bsaleUtils.to_integer($scope.select.total),
	};
	
	console.log(added);
	console.log(base);
	
	var new_datetime = dateFilter($scope.select.rsn_datetime, "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.rsn_datetime, "yyyy-MM-dd");
	if (added.length === 0
	    && ($scope.select.cash === $scope.old_select.cash
		&& $scope.select.card === $scope.old_select.card
		&& $scope.select.wxin === $scope.old_select.wxin
		&& $scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.bsaler.id === $scope.old_select.bsaler.id
		&& bsaleUtils.get_valid_id($scope.select.sale_prop) === bsaleUtils.get_valid_id($scope.old_select.sale_prop)
		&& $scope.select.comment === $scope.old_select.comment
		&&  new_datetime === old_datetime)){
	    diabloUtilsService.response_with_callback(
	    	false,
		"销售单编辑",
		"销售单编辑失败：" + bsaleService.error[2699],
		undefined,
		function() {$scope.has_saved = false});
	    return; 
	};

	// return; 
	// $scope.has_saved = true;
	bsaleService.update_batch_sale({inventory:added.length === 0 ? undefined : added, base:base}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
	    	diabloUtilsService.response_with_callback(
	    	    true, "销售单编辑", "销售单编辑成功！！单号：" + result.rsn, undefined,
	    	    function(){$scope.go_back()});
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false,
		    "销售单编辑",
		    "销售单编辑失败：" + bsaleService.error[result.ecode],
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	})
    };

    // watch balance
    var reset_payment = function(newValue){
	$scope.select.has_pay = 0;
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.cash); 
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.card);
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.wxin);
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.verificate);
	$scope.select.has_pay = bsaleUtils.to_decimal($scope.select.has_pay); 
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

    $scope.$watch("select.wxin", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wForm.$invalid) return;
	reset_payment(newValue); 
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
    	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    	reset_payment(newValue);
    });

    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
	// console.log(cid, sname, amounts);
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 

    var valid_sell = function(amount){
	var count = amount.sell_count; 
	if (angular.isUndefined(count) || !count) return true;

	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	return renumber.test(count) ? true : false;
	
    };
    
    var valid_all_sell = function(amounts){
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;

	for(var i=0, l=amounts.length; i<l; i++){
	    var count = amounts[i].sell_count; 
	    if (angular.isUndefined(count) || !count){
		unchanged++;
		continue;
	    }
	    
	    if (!renumber.test(count)) return false;
	};

	return unchanged === l ? false : true;

    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += parseInt(a.sell_count);
	    }
	})

	return {amounts:     params.amounts,
		reject:      sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };
    
    $scope.add_free_inventory = function(inv){
	console.log(inv);
	if (!angular.isObject($scope.select.bsaler) || !angular.isObject($scope.select.employee)){
	    dialog.response(
		false,
		"销售开单",
		"开单失败：" + bsaleService.error[2192]);
	    return;
	}; 
	
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.reject;
	// oreder
	$scope.inventories.unshift(inv); 
	inv.order_id = $scope.inventories.length;

	// reset
	$scope.sale.style_number = undefined;
	
	// add new line
	$scope.re_calculate(); 
    }; 
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	inv.fdiscount  = inv.discount;
	inv.fprice     = diablo_price($scope.get_valid_price(inv), inv.discount);
	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	if ($scope.setting.check_sale == diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount  = inv.discount;
	    // inv.fprice     = diablo_price($scope.get_valid_price(inv), inv.discount); 
	    // inv.fprice  = inv.tag_price;
	    inv.amounts    = [{cid:0, size:0}];
	} else {
	    var promise   = diabloPromise.promise;
	    var condition = {style_number: inv.style_number,
			     brand: inv.brand.id,
			     shop: $scope.select.shop.id}; 
	    var calls     = []; 
	    calls.push(promise(
		diabloFilter.list_purchaser_inventory, condition)()); 
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop 
		var shop_now_inv = data[0];

		var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		var sort = diabloHelp.sort_stock(shop_now_inv, order_sizes, filterColor);
		
		inv.total   = sort.total;
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort; 
		
		console.log(inv.sizes)
		console.log(inv.colors);
		console.log(inv.amounts); 

		// inv.fdiscount = inv.discount;
		// inv.fprice   = inv.tag_price;

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.reject = 1;
		    $scope.add_free_inventory(inv);
		} else{
		    inv.free_color_size = false; 
		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			$scope.inventories.unshift(inv); 
			inv.order_id = $scope.inventories.length;
			// reset
			$scope.sale.style_number = undefined; 
			$scope.re_calculate(); 
		    };
		    
		    var callback = function(params){
			var result  = add_callback(params);
			console.log(result);
			inv.amounts    = result.amounts;
			inv.reject     = result.reject;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var payload = {
			fdiscount:      inv.fdiscount,
			fprice:         inv.fprice,
			sizes:          inv.sizes,
			colors:         inv.colors,
			amounts:        inv.amounts,
			path:           inv.path,
			get_amount:     get_amount,
			valid_sell:     valid_sell,
			valid:          valid_all_sell};

		    diabloUtilsService.edit_with_modal(
			"bsale-new.html", inv.sizes.length > 7 ? "lg":undefined, callback, $scope, payload); 
		}; 
	    });
	}
    };
    
    /*
     * delete inventory
     */
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
	
    };

    // $scope.stock_info = function(inv){
    // 	diabloFilter.list_w_inventory_info(
    // 	    {style_number: inv.style_number, brand: inv.brand.id, shop: $scope.select.shop.id}
    // 	).then(function(result){
    // 	    console.log(result);
    // 	    if (result.ecode === 0){
    // 		var stocks = angular.copy(result.data);
    // 		angular.forEach(stocks, function(s){
    // 		    s.type = diablo_get_object(s.type_id, $scope.types);
    // 		    s.seasonObj = diablo_get_object(s.season, $scope.seasons);
    // 		});
		
    // 		diabloUtilsService.edit_with_modal(
    // 		    "stock-info.html", undefined, undefined, undefined, {stock: stocks}
    // 		);
    // 	    } 
    // 	})
    // };

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
	diabloUtilsService.edit_with_modal("bsale-detail.html", undefined, undefined, undefined, payload);
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	console.log(inv);
	inv.$update = true;
	
	if (inv.free_color_size){
	    inv.free_update = true;
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    inv.reject     = result.reject;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    $scope.re_calculate(); 
	};

	var payload = {fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount,
		       valid_sell:   valid_sell,
		       valid:        valid_all_sell}; 
	diabloUtilsService.edit_with_modal(
	    "bsale-new.html", inv.sizes.length > 7 ? "lg":undefined, callback, $scope, payload);
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.reject;
	$scope.re_calculate(); 
    }

    $scope.cancel_free_update = function(inv){
	inv.free_update = false;
	inv.reject = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	$scope.re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }

    $scope.gift = function(inv){
	inv.fprice = 0;
	$scope.re_calculate();
    }
};


define (["bsaleApp"], function(app){
    app.controller("updateBSaleDetailCtrl", updateBSaleDetailCtrlProvide);
});
