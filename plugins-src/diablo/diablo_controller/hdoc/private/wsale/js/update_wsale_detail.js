'use strict'

function wsaleUpdateDetailCtrlProvide(
    $scope, $routeParams, $q, dateFilter, diabloUtilsService,
    diabloPromise, diabloFilter, diabloPattern,
    wsaleService,
    user, filterPromotion, filterScore, filterEmployee,
    filterSizeGroup, filterBrand, filterColor, filterType, base){
    console.log(user);

    $scope.pattern     = {money: diabloPattern.decimal_2};
    
    $scope.shops         = user.sortShops;
    $scope.promotions    = filterPromotion;
    $scope.scores        = filterScore;
    
    // $scope.retailers     = filterRetailer; 
    // $scope.employees     = filterEmployee;
    $scope.size_groups   = filterSizeGroup;
    $scope.brands        = filterBrand;
    $scope.colors        = filterColor;
    $scope.types         = filterType;
    $scope.base_settings = base;
    // $scope.vpays         = wsaleService.vpays;
    
    $scope.sexs        = diablo_sex;
    $scope.seasons     = diablo_season2objects;
    // $scope.sell_styles = diablo_sell_style;
    // $scope.e_pay_types = wsaleService.extra_pay_types;
    $scope.round       = diablo_round;
    $scope.has_saved   = false;
    $scope.setting     = {check_sale:true, q_backend:true};

    $scope.old_select  = {};
    
    $scope.select      = {}; 
    $scope.inventories = [];
    $scope.show_promotions = [];
    
    $scope.f_add      = diablo_float_add;
    $scope.f_sub      = diablo_float_sub;
    $scope.f_mul      = diablo_float_mul;
    $scope.get_object = diablo_get_object; 

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail/" + $routeParams.ppage);
	// diablo_goto_page("#/new_wsale_detail");
    };

    // $scope.calc_withdraw = function(){
    // 	if ($scope.select.retailer.type === diablo_charge_retailer && $scope.select.withdraw > 0){
    // 	    $scope.select.save_to_back = $scope.select.withdraw
    // 		+ $scope.select.cash + $scope.select.card - $scope.select.should_pay; 
    // 	    $scope.select.left_balance = $scope.select.surplus - $scope.select.withdraw
    // 		+ $scope.select.save_to_back; 
    // 	} else {
    // 	    $scope.select.charge = $scope.select.should_pay - $scope.select.has_pay;
    // 	} 
    // };
    
    $scope.re_calculate = function(){
	$scope.select.total          = 0;
	$scope.select.abs_total      = 0;
	$scope.select.should_pay     = 0;
	$scope.select.score          = 0;
	$scope.select.charge         = 0;
	// $scope.select.save_to_back   = 0;
	
	var calc = wsaleCalc.calculate(
	    $scope.select.o_retailer,
	    $scope.select.retailer,
	    $scope.setting.no_vip,
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_reject,
	    $scope.select.verificate,
	    $scope.setting.round);

	// console.log(calc);
	// console.log($scope.show_promotions); 
	$scope.select.total     = calc.total; 
	$scope.select.should_pay= calc.should_pay;
	$scope.select.score     = calc.score;
	
	// if (0 !== wsaleUtils.to_float($scope.select.has_pay))
	//     $scope.select.charge = $scope.select.should_pay
	//     - wsaleUtils.to_float($scope.select.has_pay)
	//     - wsaleUtils.to_float($scope.select.ticket);

	$scope.select.charge = $scope.select.should_pay
	    - wsaleUtils.to_float($scope.select.has_pay)
	    - wsaleUtils.to_float($scope.select.ticket);

	// console.log($scope.select);
	
	// $scope.calc_withdraw();
    };
    
    // $scope.change_retailer = function(){
    // 	$scope.select.surplus = $scope.select.retailer.balance;
    // 	$scope.re_calculate();
    // 	$scope.select.o_retailer = $scope.select.retailer;
    // }
    
    // rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    wsaleService.get_w_sale_new(rsn).then(function(result){
	// console.log(result);
	if (result.ecode === 0){
	    // result[0] is the record detail
	    var base        = result.sale;

	    diabloFilter.get_wretailer_batch([base.retailer_id]).then(function(retailers){
		console.log(retailers);

		var sells       = result.detail;
		var wsale = wsaleUtils.cover_wsale(
		    base,
		    sells,
		    $scope.shops,
		    $scope.brands,
		    retailers,
		    filterEmployee,
		    $scope.types,
		    $scope.colors,
		    $scope.size_groups,
		    $scope.promotions,
		    $scope.scores);

		// console.log(wsale);
		
		$scope.old_select = wsale.select;
		$scope.select = angular.extend($scope.select, wsale.select);
		$scope.select.o_retailer = $scope.select.retailer;
		$scope.select.left_balance = $scope.select.surplus - $scope.select.withdraw;

		$scope.show_promotions = wsale.show_promotions;

		// setting
		var shopId = $scope.select.shop.id;
		$scope.setting.check_sale = wsaleUtils.check_sale(shopId, $scope.base_settings);
		$scope.setting.no_vip = wsaleUtils.no_vip(shopId, $scope.base_settings);
		$scope.setting.round = wsaleUtils.round(shopId, $scope.base_settings); 
		$scope.setting.cake_mode = wsaleUtils.cake_mode(shopId, $scope.base_settings);
		
		if (diablo_no === $scope.setting.cake_mode) 
		    $scope.vpays = wsaleService.vpays;
		else 
		    $scope.vpays = wsaleService.cake_vpays;
		
		$scope.employees = wsaleUtils.get_login_employee(
		    $scope.select.shop.id,
		    base.employ_id,
		    filterEmployee).filter;
		// console.log($scope.employees);


		// inventory
		$scope.old_inventories = wsale.details;
		$scope.inventories = angular.copy(wsale.details);
		$scope.inventories.unshift({$edit:false, $new:true});

		console.log($scope.old_inventories);
		console.log($scope.inventories);

		$scope.re_calculate();
	    }); 
	}
	
    });

    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    };

    // retailer;
    $scope.match_retailer_phone = function(viewValue){
	return wsaleUtils.match_retailer_phone(viewValue, diabloFilter)
    };

    $scope.copy_select = function(add, src){
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand_id     = src.brand_id;
	add.brand        = $scope.get_object(src.brand_id, $scope.brands); 
	add.type_id      = src.type_id;
	add.type         = $scope.get_object(src.type_id, $scope.types);
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	add.pid          = src.pid;
	add.promotion    = diablo_get_object(src.pid, $scope.promotions);
	add.sid          = src.sid;
	add.score        = diablo_get_object(src.sid, $scope.scores);

	add.org_price    = add.org_price;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;
	add.path         = src.path;
	
	add.s_group      = src.s_group;
	add.free         = src.free; 
	return add;
	
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand.id){
		diabloUtilsService.response_with_callback(
		    false,
		    "销售单编辑",
		    "销售单编辑失败：" + wsaleService.error[2191],
		$scope, function(){
		    $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	};
	
	// add at first allways 
	var add = $scope.inventories[0];
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
	if ($scope.has_saved || $scope.inventories.length === 1) return true;

	if ($scope.select.should_pay >=0 && $scope.select.charge > 0)
	    return true;

	if ($scope.select.should_pay < 0 && $scope.select.charge < 0)
	    return true;
	
	// if ($scope.has_saved || $scope.select.charge > 0) return true;
	
	// any payment of cash, card or wire or any inventory
	// if (angular.isDefined(diablo_set_float($scope.select.cash))
	//     || angular.isDefined(diablo_set_float($scope.select.card))
	//     || angular.isDefined(diablo_set_float($scope.select.withdraw)) 
	//     || angular.isDefined(diablo_set_string($scope.select.comment))
	//     || $scope.inventories.length !== 1
	//    ) return false;
	
	return false;
    };

    $scope.disable_modify_discount = function(inv){
	return inv.pid !== -1 ? true : false;
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
		    
		    var update_count = parseInt(newAmounts[i].sell_count)
			- parseInt(oldAmounts[j].sell_count);
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
	for (var i=1, l1=$scope.inventories.length; i < l1; i++){
	    var newInv = $scope.inventories[i];
	    found = false;
	    for (var j=0, l2=$scope.old_inventories.length; j < l2; j++){
		var oldInv = $scope.old_inventories[j];
		// update
		if (newInv.style_number === oldInv.style_number
		    && newInv.brand.id === oldInv.brand.id){
		    var sort_amounts = newInv.amounts.filter(function(a){
			if (angular.isDefined(a.sell_count)
			    && a.sell_count
			    && parseInt(a.sell_count) !== 0){
			    return true;
			}
		    });
		    
		    var change_amouts = get_update_amount(
			sort_amounts, oldInv.amounts);
		    
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
    
    $scope.save_wsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	console.log($scope.select);
	
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)
	    || angular.isUndefined($scope.select.employee)
	    || diablo_is_empty($scope.select.employee)){
	    diabloUtilsService.response(
		false,
		"销售单编辑",
		"销售单编辑失败：" + wsaleService.error[2192]);
	    return;
	}; 

	var updates = get_update_inventory();
	console.log(updates);
	var added = [];
	
	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		id             : add.id,
		style_number   : add.style_number,
		brand          : add.brand.id,
		brand_name     : add.brand,
		type           : add.type.id,
		// type_name   : add.type,
		firm           : add.firm_id,
		// sex            : add.sex,
		season         : add.season,
		year           : add.year,
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
		promotion      : add.pid,
		score          : add.sid,

		org_price      : add.org_price,
		tag_price      : add.tag_price,
		fdiscount      : add.fdiscount,
		rdiscount      : add.rdiscount,
		fprice         : add.fprice,
		rprice         : add.rprice,
		path           : add.path,
		comment        : add.comment,

		// sizes          : add.sizes,
		s_group        : add.s_group,
		colors         : add.colors,
		free           : add.free,
		// alarm_day      : add.alarm_day
	    })
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var base = {
	    id:            $scope.select.rsn_id,
	    rsn:           $scope.select.rsn,
	    retailer:      $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.rsn_datetime,
				      "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    
	    balance:       $scope.select.surplus, 
	    cash:          setv($scope.select.cash),
	    card:          setv($scope.select.card),
	    wxin:          setv($scope.select.wxin),
	    ticket:        setv($scope.select.ticket),
	    withdraw:      setv($scope.select.withdraw),
	    verificate:    setv($scope.select.verificate),
	    should_pay:    setv($scope.select.should_pay),
	    comment:       sets($scope.select.comment),

	    old_retailer:    $scope.old_select.retailer.id, 
	    old_balance:     $scope.old_select.surplus,
	    // old_withdraw:    $scope.old_select.withdraw,
	    old_should_pay:  $scope.old_select.should_pay,
	    old_datetime:    dateFilter($scope.old_select.rsn_datetime,
				       "yyyy-MM-dd HH:mm:ss"),
	    old_score:       $scope.old_select.score,
	    
	    total:          seti($scope.select.total),
	    score:          $scope.select.score
	};
	
	console.log(added);
	console.log(base);
	
	console.log($scope.old_select);
	var new_datetime = dateFilter($scope.select.rsn_datetime,
				      "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.rsn_datetime,
				      "yyyy-MM-dd");
	if (added.length === 0
	    && ($scope.select.cash === $scope.old_select.cash
		&& $scope.select.card === $scope.old_select.card
		&& $scope.select.wxin === $scope.old_select.wxin
		&& $scope.select.withdraw === $scope.old_select.withdraw 
		&& $scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.retailer.id === $scope.old_select.retailer.id
		&& $scope.select.comment === $scope.old_select.comment
		&&  new_datetime === old_datetime)){
	    diabloUtilsService.response_with_callback(
	    	false,
		"销售单编辑",
		"销售单编辑失败：" + wsaleService.error[2699],
		undefined,
		function() {$scope.has_saved = false});
	    return; 
	};

	// return;

	// $scope.has_saved = true;
	wsaleService.update_w_sale_new({
	    inventory:added.length === 0 ? undefined : added, base:base
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		var msg = "销售单编辑成功！！单号：" + result.rsn;
		if (angular.isDefined(result.sms_code)
		    && result.sms_code !== 0){
		    var ERROR = require("diablo-error");
		    msg += "，短消息发送失败：" + ERROR[result.sms_code];
		}
	    	diabloUtilsService.response_with_callback(
	    	    true, "销售单编辑", msg, $scope,
	    	    function(){
			diabloFilter.reset_retailer();
			$scope.go_back();
		    })
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false,
		    "销售单编辑",
		    "销售单编辑失败：" + wsaleService.error[result.ecode],
		    $scope,
		    function(){$scope.has_saved = false});
	    }
	})
    };

    // watch balance
    var reset_payment = function(newValue){
	$scope.select.has_pay = 0;	
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.cash); 
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.card);
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.wxin);

	if ($scope.select.retailer.type_id === diablo_charge_retailer)
	    $scope.select.has_pay += wsaleUtils.to_float($scope.select.withdraw);

	$scope.select.charge = $scope.select.should_pay
	    - wsaleUtils.to_float($scope.select.has_pay)
	    - wsaleUtils.to_float($scope.select.ticket);
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
	    if(amounts[i].cid === inv.color_id
	       && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
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
		reject:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单编辑", "开单编辑失败：" + wsaleService.error[2192]);
	    return;
	};
	
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.reject;
	// oreder
	inv.order_id = $scope.inventories.length; 
	// add new line
	$scope.inventories.unshift({$edit:false, $new:true}); 
	$scope.re_calculate(); 
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv);
	if ($scope.setting.check_sale == diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv.tag_price;
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    var promise   = diabloPromise.promise;
	    var condition = {style_number: inv.style_number,
			     brand: inv.brand.id,
			     shop: $scope.select.shop.id}; 
	    var calls     = []; 
	    calls.push(promise(
		diabloFilter.list_purchaser_inventory,
		condition)()); 
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

		inv.fdiscount   = inv.fdiscount   = function(){
		    if (angular.isObject(inv.promotion) && inv.promotion.rule_id === 0){
			return inv.promotion.discount;
		    } else {
			return inv.discount;
		    }
		}();
		
		inv.fprice      = inv.tag_price;

		if(inv.free === 0){
		    inv.free_color_size = true;
		} else{
		    inv.free_color_size = false;

		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			// oreder
			inv.order_id = $scope.inventories.length; 
			// add new line
			$scope.inventories.unshift({$edit:false, $new:true}); 
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
			"wsale-new.html",
			inv.sizes.length > 7 ? "lg":undefined,
			callback, $scope, payload); 
		}; 
	    });
	}
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
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

	$scope.re_calculate(); 
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    if (inv.order_id === $scope.show_promotions[i].order_id){
		break;
	    }
	}

	$scope.show_promotions.splice(i, 1);
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    $scope.show_promotions[i].order_id = l - i; 
	}
	
    };

    $scope.stock_info = function(inv){
	diabloFilter.list_w_inventory_info(
	    {style_number: inv.style_number, brand: inv.brand.id, shop: $scope.select.shop.id}
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var stocks = angular.copy(result.data);
		angular.forEach(stocks, function(s){
		    s.type = diablo_get_object(s.type_id, $scope.types);
		    s.seasonObj = diablo_get_object(s.season, $scope.seasons);
		});
		
		diabloUtilsService.edit_with_modal(
		    "stock-info.html", undefined, undefined, undefined, {stock: stocks}
		);
	    } 
	})
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
	    "wsale-detail.html", undefined, undefined, undefined, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	console.log(inv);
	// inv.$update = true; 
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
	    "wsale-new.html", inv.sizes.length > 7 ? "lg":undefined,
	    callback, $scope, payload)
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


define (["wsaleApp"], function(app){
    app.controller("wsaleUpdateDetailCtrl", wsaleUpdateDetailCtrlProvide);
});
