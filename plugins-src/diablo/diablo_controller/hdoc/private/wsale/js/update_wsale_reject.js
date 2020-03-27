function wsaleUpdateRejectCtrlProvide(
    $scope, $q, $routeParams, dateFilter, diabloUtilsService, diabloPromise,
    diabloFilter, diabloPattern, wsaleService,
    user, filterPromotion, filterScore, filterSysRetailer, filterEmployee,
    filterSizeGroup, filterBrand, filterColor, filterType, filterLevel, base){
    // console.log(base);
    // console.log(user);
    // console.log(filterScore);
    $scope.shops         = user.sortBadRepoes.concat(user.sortShops);
    $scope.promotions    = filterPromotion;
    $scope.scores        = filterScore;
    $scope.sysRetailers  = filterSysRetailer; 
    
    // $scope.retailers       = filterRetailer; 
    $scope.employees       = filterEmployee;
    $scope.size_groups     = filterSizeGroup;
    $scope.brands          = filterBrand;
    $scope.colors          = filterColor;
    $scope.types           = filterType;
    $scope.levels          = filterLevel;
    $scope.base_settings   = base;
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.get_object      = diablo_get_object;
    $scope.round           = diablo_round;
    
    $scope.setting         = {q_backend:true, check_sale:true};

    $scope.pattern         = {discount:diabloPattern.discount,
			      positive_num:diabloPattern.positive_num,
			      price:diabloPattern.positive_decimal_2};
    
    var dialog             = diabloUtilsService;

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail/" + $routeParams.ppage);
    };
    
    $scope.select      = {}; 
    $scope.change_retailer = function(){
	$scope.select.surplus = parseFloat($scope.select.retailer.balance);
	$scope.re_calculate();
    };
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    };

    /*
     * get reject by rsn
     */ 
    // rsn detail
    var rsn     = $routeParams.rsn
    var promise = diabloPromise.promise;
    wsaleService.get_w_sale_new(rsn).then(function(result){
	console.log(result);
	if (result.ecode === 0){
	    // result[0] is the record detail
	    // result[1] are the inventory detail that the record is included
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
		    $scope.employees,
		    $scope.types,
		    $scope.colors,
		    $scope.size_groups,
		    $scope.promotions,
		    $scope.scores);

		console.log(wsale);

		$scope.show_promotions = wsale.show_promotions;
		
		$scope.old_select = wsale.select;
		$scope.select = angular.extend($scope.select, wsale.select);

		// setting
		var shopId = $scope.select.shop.id;
		$scope.setting.check_sale = wsaleUtils.check_sale(shopId, $scope.base_settings);
		$scope.setting.no_vip     = wsaleUtils.no_vip(shopId, $scope.base_settings); 
		$scope.setting.draw_score = wsaleUtils.draw_score(shopId, $scope.base_settings);
		$scope.setting.vip_mode   = wsaleUtils.vip_mode(shopId, $scope.base_settings);
		$scope.setting.type_sale  = wsaleUtils.type_sale(shopId, $scope.base_settings);
		$scope.setting.round      = wsaleUtils.round(shopId, $scope.base_settings);
		
		var sale_mode = wsaleUtils.sale_mode(shopId, $scope.base_settings);
		$scope.setting.score_discount = wsaleUtils.to_integer(sale_mode.charAt(16)) * 10
		    + wsaleUtils.to_integer(sale_mode.charAt(17));
		
		$scope.employees = wsaleUtils.get_login_employee(
		    shopId,
		    base.employ_id,
		    filterEmployee).filter;

		$scope.select.has_pay = $scope.select.cash
	    	    + $scope.select.card + $scope.select.wxin
		    + $scope.select.withdraw + $scope.select.ticket;
		$scope.select.left_balance = $scope.select.surplus;
		
		// inventory
		$scope.old_inventories = wsale.details;
		$scope.inventories = angular.copy(wsale.details);
		// $scope.inventories.unshift({$edit:false, $new:true});
		console.log($scope.old_inventories);
		console.log($scope.inventories); 
		$scope.re_calculate(); 
	    }); 
	};	    
	
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
    }
    
    $scope.copy_select = function(add, src){
	// console.log(src);
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
	
	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount; 
	add.path         = src.path;
	add.s_group      = src.s_group;
	add.free         = src.free;
	return add; 
    };
    
    $scope.on_select_good = function(item, model, label){
	// one good can be add only once at the same time
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		dialog.response_with_callback(
		    false,
		    "退货单编辑",
		    "退货编辑失败：" + wsaleService.error[2191],
		    $scope, function(){
			$scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	}
	
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
	// console.log($scope.select.should_pay, $scope.select.has_pay);
	if ($scope.has_saved
	    || $scope.select.has_pay > 0
	    || $scope.select.should_pay !== $scope.select.has_pay){
	    return true;
	}; 

	return false;
    };

    $scope.disable_modify_discount = function(inv){
	return inv.pid !== -1 ? true : false;
    };

    var get_update_amount = function(newAmounts, oldAmounts){
	console.log(newAmounts, oldAmounts);
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
			     count:     -update_count})
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
		     count:     -parseInt(newAmounts[i].sell_count)})
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
		     count:     -parseInt(oldAmounts[i].sell_count)})
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
	    if (newInv.$new) {
		continue;
	    }
	    
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
		    var change_amouts = get_update_amount(sort_amounts, oldInv.amounts);
		    if (change_amouts.length !== 0){
			newInv.operation = 'u'; 
			newInv.changed_amounts = change_amouts;
			changedInvs.push(newInv);
		    } else {
			if (parseFloat(newInv.fprice) !== oldInv.fprice
			    || parseFloat(newInv.fdiscount) !== oldInv.fdiscount){
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
		if (newInv.$new){
		    continue;
		}
		
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
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories); 
	
	var updates = get_update_inventory();
	console.log(updates);
	var added = [];

	for(var i=0, l=updates.length; i<l; i++){
	    var add = updates[i];
	    added.push({
		style_number   : add.style_number,
		brand          : add.brand.id,
		type           : add.type.id,
		firm           : add.firm_id,
		// sex            : add.sex,
		season         : add.season,
		year           : add.year, 
		changed_amount : add.changed_amounts,
		operation      : add.operation,
		amount         : function(){
		    if (add.operation === 'd' || add.operation === "a"){
			console.log(add.amounts);
			var filter =  add.amounts.filter(function(m){
			    return angular.isDefined(m.sell_count)
				&& !isNaN(parseInt(m.sell_count))
				&& parseInt(m.sell_count) !== 0;
			});
			return filter.map(function(m){
			    return {cid:m.cid,
				    size:m.size,
				    sell_count: -parseInt(m.sell_count)};
			}); 
		    }}(),

		promotion      : add.pid,
		score          : add.sid,
		
		org_price      : add.org_price,
		tag_price      : add.tag_price,
		fdiscount      : add.fdiscount,
		rdiscount      : add.rdiscount,
		fprice         : add.fprice,
		rprice         : add.rprice,
		path           : add.path, 

		sell_total     : -diablo_set_integer(add.reject),
		s_group        : add.s_group,
		free           : add.free
	    })
	};
	
	var setv  = diablo_set_float; 
	var seti  = diablo_set_integer;
	var sets  = diablo_set_string; 

	var base = {
	    id:             $scope.select.rsn_id,
	    rsn :           $scope.select.rsn,
	    retailer:       $scope.select.retailer.id,
	    vip:            wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.rsn_datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    
	    balance:        parseFloat($scope.select.surplus),
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wxin:           setv($scope.select.wxin),
	    ticket:         setv($scope.select.ticket),
	    
	    withdraw:       $scope.select.withdraw, 
	    should_pay:     setv($scope.select.should_pay),
	    comment:        sets($scope.select.comment),
	    
	    // old_shop:       $scope.old_select.shop.id,
	    old_retailer:   $scope.old_select.retailer.id, 
	    old_balance:    $scope.old_select.surplus,
	    
	    old_should_pay: $scope.old_select.should_pay,
	    old_withdraw:   $scope.old_select.withdraw,
	    old_datetime:   dateFilter($scope.old_select.rsn_datetime, "yyyy-MM-dd HH:mm:ss"),
	    old_score:      $scope.old_select.score,
	    
	    total:          seti($scope.select.total),
	    score:          $scope.select.score
	};
	
	console.log(added);
	console.log(base);
	
	// console.log($scope.old_select);
	if ($scope.select.shop.id !== $scope.old_select.shop.id){
	    dialog.response_with_callback(
		false,
		"退货单编辑",
		"退货单编辑失败：",
		"暂不支持店铺修改！！",
		undefined, function(){$scope.has_saved = false})
	};
	
	var new_datetime = dateFilter($scope.select.rsn_datetime,
				      "yyyy-MM-dd");
	var old_datetime = dateFilter($scope.old_select.rsn_datetime,
				      "yyyy-MM-dd");
	if (added.length === 0
	    && ($scope.select.employee.id === $scope.old_select.employee.id
		&& $scope.select.shop.id === $scope.old_select.shop.id
		&& $scope.select.retailer.id === $scope.old_select.retailer.id
		&& $scope.select.comment === $scope.old_select.comment
		&&  new_datetime === old_datetime)){
	    diabloUtilsService.response_with_callback(
	    	false,
		"退货单编辑",
		"退货单编辑失败：" + wsaleService.error[2699],
		undefined, function() {$scope.has_saved = false});
	    return;
	}

	// $scope.has_saved = false;
	// return;

	wsaleService.update_w_sale_new({
	    inventory:added.length === 0 ? undefined : added, base:base
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		msg = "退货单编辑成功！！单号：" + result.rsn; 
	    	diabloUtilsService.response_with_callback(
	    	    true,
		    "退货单编辑",
		    msg,
		    undefined,
	    	    function(){$scope.go_back()})
	    } else{
	    	diabloUtilsService.response_with_callback(
	    	    false,
		    "退货单编辑",
		    "退货单编辑失败：" + wsaleService.error[result.ecode],
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	}) 
    }; 

    /*
     * add
     */ 
    var get_amount = function(cid, sname, amounts){
	// console.log(amounts);
	// var m = {cid:cid, size:sname};
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    };

    $scope.reset_score = function() {
	if (diablo_score_only_cash === $scope.setting.draw_score
	    && ( wsaleUtils.to_float($scope.select.withdraw) !== 0
		 || wsaleUtils.to_float($scope.select.ticket) !== 0 )) {
	    var pay_orders = wsaleCalc.pay_order_of_reject(
		$scope.select.should_pay, [
		    $scope.select.ticket,
		    $scope.select.withdraw,
		    $scope.select.wxin,
		    $scope.select.aliPay,
		    $scope.select.card,
		    $scope.select.cash]);
	    var pay_with_score = pay_orders[2] + pay_orders[3] + pay_orders[4] + pay_orders[5];
	    $scope.select.score = wsaleUtils.calc_score_of_pay(pay_with_score, $scope.select.pscores);
	} else if (diablo_score_only_cash === $scope.setting.draw_score
		   && ( wsaleUtils.to_float($scope.select.withdraw) !== 0
			|| wsaleUtils.to_float($scope.select.ticket) !== 0 )) {
	    $scope.select.score = 0;
	}
    };
    
    $scope.re_calculate = function(){
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;
	$scope.select.score        = 0;
	
	var calc = wsaleCalc.calculate(
	    wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
	    $scope.setting.vip_mode,
	    wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels),
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_reject, 
	    $scope.select.verificate,
	    $scope.setting.round,
	    $scope.setting.score_discount);

	$scope.select.total     = calc.total; 
	$scope.select.abs_total = calc.abs_total;
	$scope.select.should_pay= calc.should_pay;
	$scope.select.score     = calc.score;
	$scope.select.pscores   = calc.pscores; 
	$scope.reset_score();
	

	// back to retailer
	if ($scope.select.retailer.type===1){
	    $scope.select.left_balance = $scope.select.surplus - $scope.select.withdraw; 
	}
	
	console.log($scope.select);
    }; 

    var valid_all = function(amounts){
	var total = 0;
	for(var i=0, l=amounts.length; i<l; i++){
	    var sell_count = amounts[i].sell_count; 
	    if (angular.isDefined(sell_count) && sell_count){
		total += parseInt(sell_count);
	    } 
	}

	return total === 0 ? false:true;
    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell += parseInt(a.sell_count);
	    }
	})

	return {amounts:     params.amounts,
		reject:      sell,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,};
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
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
	if ($scope.setting.check_sale === diablo_no
	    && $scope.setting.trace_price === diablo_no
	    && inv.free === 0){
	    inv.free_color_size = true;
	    inv.fdiscount       = inv.discount;
	    inv.fprice          = inv.tag_price;
	    inv.amounts         = [{cid:0, size:0}];
	} else {
	    var promise   = diabloPromise.promise;
	    var condition = {style_number: inv.style_number,
			     brand: inv.brand_id,
			     shop:  $scope.select.shop.id};

	    var calls     = []; 
	    calls.push(promise(diabloFilter.list_purchaser_inventory, condition)());
	    
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop 
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
		
		inv.fdiscount   = inv.discount;
		inv.fprice      = inv.tag_price;

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts = [{cid:0, size:0}];
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
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    
		    var payload = {
			fdiscount:    inv.fdiscount,
			fprice:       inv.fprice,
			sizes:        inv.sizes,
			large_size:   large_size,
			colors:       inv.colors,
			amounts:      inv.amounts,
			path:         inv.path,
			get_amount:   get_amount,
			valid_all:    valid_all
		    }
		    
		    diabloUtilsService.edit_with_modal(
			"wsale-reject.html",
			modal_size, callback, $scope, payload);
		}
	    })   
	} 
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
	
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	console.log(inv);
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-reject-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	// console.log(inv);
	inv.$update = true; 
	if (inv.free_color_size){
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    inv.free_update = true;
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

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	var payload = {
	    fdiscount:    inv.fdiscount,
	    fprice:       inv.fprice,
	    sizes:        inv.sizes,
	    large_size:   large_size,
	    colors:       inv.colors, 
	    amounts:      inv.amounts,
	    path:         inv.path,
	    get_amount:   get_amount,
	    // valid_one:    valid_one,
	    valid_all:    valid_all
	};

	diabloUtilsService.edit_with_modal(
	    "wsale-reject.html", modal_size, callback, undefined, payload); 
    };

    $scope.save_free_update = function(inv){
	inv.free_update = false;
	// console.log(inv);
	inv.amounts[0].sell_count = inv.reject;
	$scope.re_calculate(); 
    }

    $scope.cancel_free_update = function(inv){
	inv.free_update = false;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	
	inv.reject = inv.amounts[0].sell_count;
	$scope.re_calculate(); 
    }

    $scope.reset_inventory = function(inv){
	$scope.inventories[0] = {$edit:false, $new:true};;
    }
};

define (["wsaleApp"], function(app){
    app.controller("wsaleUpdateRejectCtrl", wsaleUpdateRejectCtrlProvide);
});
