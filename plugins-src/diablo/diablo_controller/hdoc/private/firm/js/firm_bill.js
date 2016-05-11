firmApp.controller("firmBillCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    firmService, filterCard, filterEmployee, user){
    // console.log(filterCard);
    // $scope.retailer = {};
    $scope.pattern = {
	// decimal_2:    diabloPattern.decimal_2,
	number:       diabloPattern.integer_except_zero
    };

    $scope.focus = {firm:true},

    // $scope.full_years = diablo_full_year; 
    // $scope.check_year = diablo_now_year();
    $scope.cards = [{no:"== 请选择银行卡号 ==", id:-1}] .concat(filterCard);
    $scope.employees  = filterEmployee;
    $scope.shops      = user.sortShops; 
    $scope.bill_modes = firmService.bill_modes;
    console.log($scope.cards);
    
    $scope.employee   = filterEmployee[0];
    $scope.shop       = $scope.shops[0];
    $scope.bill_mode  = $scope.bill_modes[0];
    $scope.bill_card  = $scope.cards[0];
    $scope.bill_date  = $.now();
    $scope.has_billed = false;

    // canlender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true; 
    }

    var dialog = diabloUtilsService;
    
    firmService.list_firm().then(function(firms){
	// console.log(firms);
	$scope.firms = firms.map(function(f){
	    return {id      :f.id,
		    name    :f.name, 
		    balance :f.balance,
		    mobile  :f.mobile,
		    address :f.address,
		    prompt  :f.name + diablo_pinyin(f.name)}
	});
	// console.log($scope.firms);
    });

    $scope.check_bill = function(){
	// console.log($scope.firm, $scope.bill, $scope.bill_mode, $scope.bill_card);
	$scope.has_billed = true;
	firmService.bill_w_firm({
	    shop:       $scope.shop.id, 
	    firm:       $scope.firm.id,
	    mode:       $scope.bill_mode.id,
	    bill:       $scope.bill,
	    veri:       diablo_set_integer($scope.verificate),
	    card:       $scope.bill_card.id,
	    employee:   $scope.employee.id,
	    comment:    $scope.comment,
	    datetime:   dateFilter($scope.bill_date, "yyyy-MM-dd hh:mm:ss")
	}).then(function(status){
	    console.log(status);
	    $scope.has_billed = false; 
	    if (status.ecode === 0){
		var left_balance = $scope.firm.balance - $scope.bill;
		dialog.response_with_callback(
		    true,
		    "厂商结帐",
		    "厂商结账成功！！剩余欠款：" +  left_balance.toString(),
		    undefined,
		    function() {
			$scope.firm.balance = left_balance;
			$scope.firm = undefined;
			$scope.rForm.name.$pristine = true;
			$scope.bill = undefined;
			$scope.rForm.bill.$pristine = true;
			$scope.verificate = undefined;
			$scope.rForm.veri.$pristine = true;

			$scope.focus.firm = true;
		    });
	    } else {
		dialog.response(
		    false,
		    "厂商结账",
		    "厂商结账失败！！" + firmService.error[status.ecode]);
	    }
	})
    };

    $scope.cancel_bill = function(){
	diablo_goto_page("#/firm/bill_detail");
    };
});

firmApp.controller("firmBillDetailCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService, diabloFilter,
    firmService, filterFirm, filterCard, filterEmployee, user, base){

    $scope.shops     = user.sortShops;
    $scope.shopIds   = user.shopIds;
    $scope.css       = diablo_bill_css;
    $scope.state_css = function(state){
	return diablo_stock_css(state, diablo_invalid);
    };
    $scope.bill_check = function(){
	diablo_goto_page("#/firm/bill")};

    /*
     * filter
     */ 

    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("card", filterCard);
    diabloFilter.add_field("firm", filterFirm);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = $.now;
    var shop = $scope.shopIds.length === 1 ? $scope.shopIds[0] : -1;
    $scope.qtime_start = stockUtils.start_time_of_second(shop, base, now, diabloFilter);
    $scope.time = diabloFilter.default_time($scope.qtime_start);
    console.log($scope.time);

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.total_items      = 0;

    $scope.page_changed = function(page){
	// console.log(page);
	$scope.current_page = page;
	$scope.do_search(page);
    };

    var add_search_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds;
	    search.shop = $scope.shopIds
		=== 0 ? undefined : $scope.shopIds; ;
	};
    };

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search);

	    firmService.filter_bill_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_bill  = result.t_bill;
		    $scope.total_veri  = result.t_veri;
		}

		angular.forEach(result.data, function(d){
		    d.firm = diablo_get_object(d.firm_id, filterFirm);
		    d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    d.bank_card = diablo_get_object(d.card_id, filterCard);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.cash = d.mode === diablo_bill_cash ? d.bill : 0;
		    d.card = d.mode === diablo_bill_card ? d.bill : 0;
		    d.wire = d.mode === diablo_bill_wire ? d.bill : 0; 
		})

		$scope.bills = result.data;
		diablo_order_page(page, $scope.items_perpage, $scope.bills);
	    });
	});
    };

    $scope.do_search($scope.current_page);

    $scope.update = function(bill){
    	diablo_goto_page("#/firm/bill_update/" + bill.rsn);
    }

    var dialog = diabloUtilsService;
    $scope.check_detail = function(bill){
	firmService.check_bill_w_firm(bill.rsn).then(function(state){
	    if (state.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "结帐单审核",
		    "结帐单审核成功！！单号：" + bill.rsn,
		    undefined,
		    function() {bill.state = diablo_check});
	    } else {
		diablo.response(
		    false,
		    "结帐单审核",
		    "结帐单审核失败：" + firmService.error[state.ecode]
		)
	    }
	})};

    $scope.uncheck_detail = function(bill){
	firmService.uncheck_bill_w_firm(bill.rsn).then(function(state){
	    if (state.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "结帐单反审",
		    "结帐单反审成功！！单号：" + bill.rsn,
		    undefined,
		    function() {bill.state = diablo_uncheck});
	    } else {
		diablo.response(
		    false,
		    "结帐单反审",
		    "结帐单反审失败：" + firmService.error[state.ecode]
		)
	    }
	})
    };

    $scope.abandon_detail = function(bill){
	var callback = function(){
	    firmService.abandon_bill_w_firm(bill.rsn).then(function(state){
		if (state.ecode === 0){
		    dialog.response_with_callback(
			true,
			"结帐单废弃",
			"结帐单废弃成功！！单号：" + bill.rsn,
			undefined,
			function() {bill.state = diablo_stock_has_abandoned});
		} else {
		    dialog.response(
			false,
			"结帐单废弃",
			"结帐单废弃失败：" + firmService.error[state.ecode]
		    )
		}
	    })
	};

	dialog.request(
	    "入库单废弃", "入库单废弃后，无法恢复，确认要废弃吗？",
	    callback, undefined, undefined);
    }
    
});


firmApp.controller("firmBillUpdateCtrl", function(
    $scope, $routeParams, dateFilter, diabloPattern, diabloUtilsService,
    firmService, filterFirm, filterCard, filterEmployee, user){
    $scope.pattern = {
	// decimal_2:    diabloPattern.decimal_2
	number: diabloPattern.integer_except_zero
    };

    // $scope.full_years = diablo_full_year; 
    // $scope.check_year = diablo_now_year();
    $scope.cards = [{no:"== 请选择银行卡号 ==", id:-1}] .concat(filterCard);
    $scope.employees  = filterEmployee;
    $scope.shops      = user.sortShops;
    $scope.firms      = angular.copy(filterFirm);
    $scope.bill_modes = firmService.bill_modes;
    // console.log($scope.cards);
    
    // $scope.employee   = filterEmployee[0];
    // $scope.shop       = $scope.shops[0];
    // $scope.bill_mode  = $scope.bill_modes[0];
    // $scope.bill_card  = $scope.cards[0];
    $scope.has_updated = false;

    // canlender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true; 
    };

    $scope.change_bill_mode = function(){
	if (diablo_bill_cash === $scope.bill_mode.id){
	    $scope.bill_card = $scope.cards[0];
	}
    };

    firmService.get_bill_by_rsn($routeParams.rsn).then(function(result){
	console.log(result);
	$scope.bill_id   = result.id;
	$scope.stock_id  = result.sid;
	$scope.shop      = diablo_get_object(result.shop_id, $scope.shops);
	$scope.firm      = diablo_get_object(result.firm_id, $scope.firms);
	$scope.bill_mode = diablo_get_object(result.mode, $scope.bill_modes);
	$scope.bill      = result.bill;
	$scope.veri      = result.veri;      
	$scope.employee  = diablo_get_object(result.employee_id, $scope.employees); 
	$scope.bill_date = diablo_set_datetime(result.entry_date);
	$scope.bill_card = diablo_get_object(result.card_id, $scope.cards);
	$scope.comment   = result.comment; 
	$scope.firm.balance += result.bill;

	$scope.o_shop      = angular.copy($scope.shop);
	$scope.o_bill_mode = angular.copy($scope.bill_mode);
	$scope.o_bill      = $scope.bill;
	$scope.o_veri      = $scope.veri;
	$scope.o_employee  = angular.copy($scope.employee);
	$scope.o_bill_date = angular.copy($scope.bill_date);
	$scope.o_bill_card = angular.copy($scope.bill_card);
	$scope.o_comment   = angular.copy($scope.comment); 
    });

    var dialog = diabloUtilsService;
    
    $scope.update_bill = function(){
	// console.log($scope.bill_mode.id === $scope.o_bill_mode.id,
	// 	    $scope.bill === $scope.o_bill,
	// 	    $scope.employee.id === $scope.o_employee.id,
	// 	    $scope.bill_date.getTime() === $scope.o_bill_date.getTime(),
	// 	    $scope.bill_card.id === $scope.o_bill_card.id,
	// 	    $scope.comment === $scope.o_comment);
	if ($scope.shop.id === $scope.o_shop.id
	    &&$scope.bill_mode.id === $scope.o_bill_mode.id
	    && $scope.bill === $scope.o_bill
	    && stockUtils.to_integer($scope.veri) === $scope.o_veri
	    && $scope.employee.id === $scope.o_employee.id
	    && $scope.bill_date.getTime() === $scope.o_bill_date.getTime()
	    && $scope.bill_card.id === $scope.o_bill_card.id
	    && $scope.comment === $scope.o_comment){
	    dialog.response(
		false,
		"厂商结帐单编辑",
		"厂商结帐单编辑失败：" + firmService.error[1699]);
	    return;
	}

	var get_modified = function(newValue, oldValue){
	    if (angular.isNumber(newValue) || angular.isString(newValue)){
		return newValue !== oldValue ? newValue : undefined;
	    }
	    if (angular.isDate(newValue)){
		return newValue.getTime() !== oldValue.getTime()
		    ? dateFilter($scope.bill_date, "yyyy-MM-dd hh:mm:ss") : undefined; 
	    }
	    if (angular.isObject(newValue)){
		return newValue.id !== oldValue.id ? newValue.id : undefined; 
	    }
	};

	// console.log();
	
	$scope.has_billed = true; 
	firmService.update_bill_w_firm({
	    rsn:      $routeParams.rsn, 
	    
	    bill:     $scope.bill,
	    veri:     stockUtils.to_integer($scope.veri),
	    shop:     get_modified($scope.shop, $scope.o_shop),
	    mode:     get_modified($scope.bill_mode, $scope.o_bill_mode),
	    card:     get_modified($scope.bill_card, $scope.o_bill_card),
	    employee: get_modified($scope.employee, $scope.o_employee),
	    comment:  get_modified($scope.comment, $scope.o_comment),
	    datetime: get_modified($scope.bill_date, $scope.o_bill_date),

	    bill_id:  $scope.bill_id,
	    stock_id: $scope.stock_id,
	    firm:     $scope.firm.id,
	    mode:     $scope.bill_mode.id,
	    
	    o_bill:   $scope.o_bill,
	    o_veri:   $scope.o_veri
	}).then(function(status){
	    console.log(status);
	    if (status.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "厂商结帐编辑",
		    "厂商结账编辑成功！！",
		    undefined,
		    $scope.cancel);
	    } else {
		$scope.has_billed = false; 
		dialog.response(
		    false,
		    "厂商结账编辑",
		    "厂商结账编辑失败！！" + firmService.error[status.ecode]);
	    }
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/firm/bill_detail");
    };
});
