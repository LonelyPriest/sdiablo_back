wretailerApp.controller("wretailerNewCtrl", function(
    $scope, wretailerService, diabloPattern, diabloUtilsService, user){
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      decimal_2:    diabloPattern.decimal_2,
		      score:        diabloPattern.number,
		      password:     diabloPattern.num_passwd};

    $scope.right = {master: rightAuthen.authen_master(user.type)};
    
    $scope.shops = user.sortShops;
    $scope.retailer_types = wretailerService.retailer_types;
    $scope.retailer = {
	birth:$.now(),
	type:$scope.retailer_types[0],
	shop:$scope.shops[0]};

    $scope.new_wretailer = function(retailer){
	// console.log(retailer); 
	wretailerService.new_wretailer(retailer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "新增会员",
		    "恭喜你，会员 " + retailer.name + " 成功创建！！",
	    	    $scope,
		    function(){diablo_goto_page("#/wretailer_detail")});
	    } else{
		diabloUtilsService.response(
	    	    false, "新增会员",
	    	    "新增会员失败：" + wretailerService.error[state.ecode]);
	    };
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/wretailer_detail");
    };
});


wretailerApp.controller("wretailerDetailCtrl", function(
    $scope, $location, dateFilter, diabloPattern, diabloUtilsService,
    diabloPagination, localStorageService, wretailerService,
    filterEmployee, filterCharge, user, base){
    $scope.employees      = filterEmployee;
    $scope.charges        = filterCharge;
    $scope.shops          = user.sortShops;
    $scope.shopIds = user.shopIds;
    $scope.retailer_types = wretailerService.retailer_types;
    
    // console.log($scope.employees);
    // console.log($scope.shops);
    // console.log(base);
    $scope.no_vips = base.filter(function(s){
	return 's_customer' === s.name
    }).map(function(c){return parseInt(c.value)});

    var LODOP;
    var print_mode = diablo_backend;
    for (var i=0, l=$scope.shopIds.length; i<l; i++){
	if (diablo_frontend === retailerUtils.print_mode($scope.shopIds[i], base)){
	    if (needCLodop()) {
		loadCLodop();
		break;
	    };
	}
    };

    // console.log($scope.no_vips);
    
    $scope.round      = diablo_round;
    $scope.pagination = {}; 
    $scope.months     = ["===请选择会员生日月份==="].concat(retailerUtils.months());
    $scope.birth_month = $scope.months[0];
    
    var dialog = diabloUtilsService;
    var f_add  = diablo_float_add;
    var now    = $.now();

    $scope.right = {
	reset_password: rightAuthen.authen(
	    user.type, rightAuthen.retailer_action()['reset_password'], user.right),
	delete_retailer: rightAuthen.authen(
	    user.type, rightAuthen.retailer_action()['delete_retailer'], user.right),
	update_retailer_score: rightAuthen.authen(
	    user.type, rightAuthen.retailer_action()['update_score'], user.right),
	master: rightAuthen.authen_master(user.type)};

    console.log($scope.right);

    $scope.save_to_local = function(search, t_retailer){
	var s = localStorageService.get(diablo_key_retailer);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_retailer, {
		    search:angular.isDefined(search) ? search:s.search,
		    t_retailer:angular.isDefined(t_retailer)
			? t_retailer:s.t_retailer,
		    page:$scope.pagination.current_page,
		    t:now}
	    )
	} else {
	    localStorageService.set(
		diablo_key_retailer, {
		    search:     search,
		    t_retailer: t_retailer,
		    page:       $scope.pagination.current_page,
		    t:          now})
	}
    };

    $scope.reset_local_storage = function(){
	var s = localStorageService.get(diablo_key_retailer);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_retailer, {
		    search:     undefined,
		    t_retailer: undefined,
		    page:       $scope.pagination.current_page,
		    t:          now}
	    ) 
	};
    };

    var repagination = function(filters){
	diablo_order(filters);
	$scope.total_balance = 0;
	$scope.total_consume = 0;
	
	angular.forEach(filters, function(f){
	    $scope.total_balance += f.balance;
	    $scope.total_consume += f.consume;
	});

	$scope.total_balance = retailerUtils.to_decimal($scope.total_balance);
	$scope.total_consume = retailerUtils.to_decimal($scope.total_consume);

	// re pagination
	diabloPagination.set_data(filters);
	$scope.total_items      = diabloPagination.get_length();
	$scope.filter_retailers = diabloPagination.get_page(
	    $scope.pagination.default_page);

	return filters;
    };
    

    /*
     * pagination
     */
    // $scope.pagination.colspan = 9;
    $scope.pagination.max_page_size = diablo_max_page_size();
    $scope.pagination.items_perpage = diablo_items_per_page();
    $scope.pagination.default_page  = 1;

    var storage = localStorageService.get(diablo_key_retailer);
    // console.log(storage);
    
    if (angular.isDefined(storage) && storage !== null){
	$scope.pagination.current_page = storage.page;
	$scope.search                  = storage.search;
	$scope.total_items             = storage.t_retailer;
    } else {
	$scope.pagination.current_page = $scope.pagination.default_page;
	$scope.search                  = undefined;
	$scope.total_items             = undefined;
    } 
    
    $scope.page_changed = function(page){
	// console.log(page);
	// console.log($scope.pagination.current_page);
	// $scope.current_page = page;
	$scope.pagination.current_page = page;
	$scope.save_to_local();
	$scope.filter_retailers
	    = diabloPagination.get_page($scope.pagination.current_page);
    }
    
    $scope.do_search = function(search){
	console.log(search);
    	return $scope.retailers.filter(function(r){
	    // console.log(r);
	    return search === r.name
		|| search === r.mobile 
		|| search === r.address
	})
    };

    $scope.on_select_retailer = function(item, model, label){
	console.log(model);
	
	var filters = $scope.do_search(model.name); 
	repagination(filters);
	// save
	$scope.save_to_local(model.name, $scope.total_items);
    }

    var in_prompt = function(p, prompts){
	for (var i=0, l=prompts.length; i<l; i++){
	    if (p === prompts[i].name){
		return true;
	    }
	}

	return false;
    }

    $scope.refresh = function(){
	$scope.reset_local_storage();
	$scope.birth_month = $scope.months[0];
	$scope.do_refresh($scope.pagination.default_page, undefined);
    };
    
    $scope.do_refresh = function(page, search){
	// console.log(page);
	$scope.pagination.current_page = page;
	$scope.search = search;
	
	wretailerService.list_retailer().then(function(data){
	    // console.log(data);
	    $scope.retailers = data;
	    $scope.total_balance = 0;
	    $scope.total_consume = 0;
	    angular.forEach($scope.retailers, function(r){
		r.type = diablo_get_object(r.type_id, $scope.retailer_types);
		r.birthday = r.birth.substr(5,8); 
		r.birth = diablo_set_date_obj(r.birth);
		r.shop  = diablo_get_object(r.shop_id, $scope.shops);
		r.no_vip = in_array($scope.no_vips, r.id) ? true : false;
		r.balance = diablo_rdight(r.balance, 2);
		$scope.total_balance += r.balance;
		$scope.total_consume += r.consume; 
	    })

	    $scope.total_balance = diablo_rdight($scope.total_balance, 2);
	    $scope.total_consume = diablo_rdight($scope.total_consume, 2);
	    
	    diablo_order($scope.retailers);
	    // console.log($scope.retailers);
	    console.log($scope.total_balance, $scope.total_consume);

	    var filters;
	    if (angular.isDefined(search)){
		filters = $scope.do_search(search);
	    } else {
		filters = $scope.retailers;
	    }
	    
	    diabloPagination.set_data(filters);
	    diabloPagination.set_items_perpage($scope.pagination.items_perpage);
	    $scope.total_items      = diabloPagination.get_length();
	    $scope.filter_retailers = diabloPagination.get_page(
		$scope.pagination.current_page);
	    
	    // save
	    $scope.save_to_local($scope.search, $scope.total_items);
	    
	    $scope.prompts = [];
	    for(var i=0, l=$scope.retailers.length; i<l; i++){
		var r = $scope.retailers[i];

		if (!in_prompt(r.name, $scope.prompts)){
		    $scope.prompts.push(
			{name: r.name, py:diablo_pinyin(r.name)}); 
		}
		if (!in_prompt(r.address, $scope.prompts)){
		    $scope.prompts.push(
			{name: r.address, py:diablo_pinyin(r.address)}); 
		}
		if (!in_prompt(r.mobile, $scope.prompts)){
		    $scope.prompts.push(
			{name: r.mobile, py:diablo_pinyin(r.mobile)}); 
		} 
	    }
	})
    }; 
    
    $scope.do_refresh($scope.pagination.current_page, $scope.search);

    $scope.new_retailer = function(){
	$location.path("/wretailer_new"); 
    };

    $scope.charge_detail = function(){
	diablo_goto_page("#/wretailer_charge_detail");
    }

    $scope.trans_info = function(r){
	dialog.response(false, "会员对帐", "暂不支持此操作！！请在销售记录中查询！！");
	return;
    };

    $scope.change_birth_month = function(){
	console.log($scope.birth_month);
	if ($scope.birth_month !== $scope.months[0]) {
	    var filters = $scope.retailers.filter(function(r){
		return parseInt((dateFilter(r.birth, "yyyy-MM-dd").split("-")[1])) === $scope.birth_month;
	    })
	    // console.log(filter); 
	    repagination(filters); 
	}
    };
    
    var pattern = {name_address: diabloPattern.ch_name_address,
		   tel_mobile:   diabloPattern.tel_mobile,
		   decimal_2:    diabloPattern.decimal_2,
		   number:       diabloPattern.number,
		   comment:      diabloPattern.comment,
		   password:     diabloPattern.num_passwd};
    
    // var get_login_employee = function(shop, loginEmployee, employees){
    // 	var filterEmployees = employees.filter(function(e){
    // 	    return e.shop === shop;
    // 	});
    
    // 	var select = undefined;
    // 	if (diablo_invalid_employee !== loginEmployee)
    // 	    select = diablo_get_object(loginEmployee, filterEmployees); 
    
    // 	if (angular.isUndefined(select)) select = filterEmployees[0];

    // 	// console.log(select);
    // 	return {login:select, filter:filterEmployees};
    // },    
    $scope.charge = function(retailer){
	console.log($scope.charges); 
	var get_charge = function(charge_id) {
	    for (var i=0, l=$scope.charges.length; i<l; i++){
		if (charge_id === $scope.charges[i].id){
		    return $scope.charges[i];
		}
	    } 
	    return undefined;
	};
	
	var callback = function(params){
	    console.log(params);

	    var promotion       = params.retailer.select_charge;
	    var charge_balance  = diablo_set_integer(params.charge);
	    var send_balance    = function(){
		if (promotion.charge !== 0 && charge_balance >= promotion.charge){
		    return Math.floor(charge_balance / promotion.charge) * promotion.balance;
		} else {
		    return 0;
		}
	    }();

	    wretailerService.new_recharge({
		retailer: retailer.id, 
		shop: params.retailer.select_shop.id,
		employee: params.retailer.select_employee.id, 
		// old_balance:  retailer.balance,
		charge_balance: charge_balance,
		send_balance: send_balance,
		charge: promotion.id,
		comment: params.comment})
		.then(function(result){
		    console.log(result); 
		    if (result.ecode == 0){
			retailer.balance += charge_balance + send_balance;
			dialog.response_with_callback(
			    true,
			    "会员充值",
			    "会员 [" + retailer.name + "] 充分值成功，"
				+ "帐户余额 [" + retailer.balance.toString() + " ]！！",
			    undefined, function(){
				if (diablo_frontend === retailerUtils.print_mode(
				    params.retailer.select_shop.id, base)){
				    if (angular.isUndefined(LODOP)){
					LODOP = getLodop(); 
				    }
				    if (angular.isDefined(LODOP)){
					var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
					var hLine = retailerPrint.gen_head(
					    LODOP,
					    params.retailer.name,
					    params.retailer.select_shop.name,
					    params.retailer.select_employee.name,
					    pdate);
					
					retailerPrint.gen_body(
					    hLine, LODOP,
					    {cbalance:charge_balance,
					     sbalance:send_balance,
					     comment:params.comment
					    });
					
					return retailerPrint.start_print(LODOP);
				    } else {
					console.log("get lodop failed...");
				    }
				} 
			    });
    		    } else{
			dialog.response(
			    false,
			    "会员充值",
			    "会员充值失败："
				+ wretailerService.error[result.ecode]);
    		    }
		})
	};
	
	dialog.edit_with_modal(
	    "wretailer-charge.html",
	    undefined,
	    callback,
	    undefined,
	    {retailer:  {
		name: retailer.name,
		balance:retailer.balance,
		shops: $scope.shops,
		select_shop: $scope.shops[0],
		employees: $scope.employees,
		select_employee: $scope.employees[0],
		charges: $scope.charges,
		select_charge:get_charge($scope.shops[0].charge_id)
	    },
	     // shops:      $scope.shops,
	     // select_shop: $scope.shops[0]; 
	     // employees:  $scope.employees,
	     // select_employees:  $scope.employees[0];
	     pattern:  pattern,
	     get_charge: get_charge
	    }
	)
    };
    
    $scope.update_retailer = function(old_retailer){
	console.log(old_retailer);
	var callback = function(params){
	    console.log(params); 
	    var update_retailer = {
		name: diablo_get_modified(params.retailer.name, old_retailer.name),
		mobile: diablo_get_modified(params.retailer.mobile, old_retailer.mobile),
		address: diablo_get_modified(params.retailer.address, old_retailer.address),
		shop: diablo_get_modified(params.retailer.shop, old_retailer.shop),
		type: diablo_get_modified(params.retailer.type, old_retailer.type),
		password:diablo_get_modified(params.retailer.password, old_retailer.password),
		birth:diablo_get_modified(params.retailer.birth.getTime(),
					  old_retailer.birth.getTime()),
		balance: diablo_get_modified(params.retailer.balance, old_retailer.balance),
	    };
	    
	    console.log(update_retailer); 
	    update_retailer.id = params.retailer.id;
	    update_retailer.obalance = old_retailer.balance;
	    // console.log(update_retailer);

	    wretailerService.update_retailer(update_retailer).then(function(result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "会员编辑",
			"恭喜你，会员 ["
			    + old_retailer.name + "] 信息修改成功！！",
			$scope, function(){
			    $scope.do_refresh($scope.pagination.current_page, $scope.search);
			});
    		} else{
		    dialog.response(
			false, "会员编辑",
			"会员编辑失败："
			    + wretailerService.error[result.ecode]);
    		}
    	    }) 
	};

	var check_same = function(new_retailer){
	    return angular.equals(new_retailer, old_retailer);
	};

	var check_exist = function(new_retailer){
	    for(var i=0, l=$scope.retailers.length; i<l; i++){
		if (new_retailer.name === $scope.retailers[i].name
		    && new_retailer.name !== old_retailer.name){
		    return true;
		}
	    }

	    return false;
	};

	// var get_valid_date = function(dateString){
	//     if (dateString === $scope.invalid_date)
	// 	return $.now();
	//     return diablo_set_date(dateString);
	// };
	
	dialog.edit_with_modal(
	    "update-wretailer.html", undefined, callback, $scope,
	    {retailer:    old_retailer,
	     types:       $scope.retailer_types,
	     shops:       $scope.shops,
	     pattern:     pattern,
	     check_same:  check_same,
	     check_exist: check_exist,
	     right: $scope.right})
    };

    $scope.delete_retailer = function(r){
	var callback = function(){
	    wretailerService.delete_retailer(r.id).then(function(result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true,
			"删除会员",
			"恭喜你，会员 [" + r.name + "] 删除成功！！",
			$scope,
			function(){$scope.refresh()});
    		} else{
		    dialog.response(
			false,
			"删除会员",
			"删除会员失败："
			    + wretailerService.error[result.ecode]);
    		}
    	    })
	};

	diabloUtilsService.request(
	    "删除会员", "确定要删除该会员吗？",
	    callback, undefined, undefined);
    };

    $scope.reset_password = function(retailer) {
	var callback = function(params){
	    console.log(params);
	    
	    if (params.newp !== params.checkp){
		dialog.response(
		    false, "密码重置", "密码重置失败：两次输入密码不匹配，请重新输入！！", undefined);
	    } else {
		wretailerService.reset_password(retailer.id, params.checkp).then(function(result){
		    console.log(result);
		    if (result.ecode == 0){
			dialog.response(
			    true, "密码重置", "密码重置成功！！", undefined);
		    } else{
			dialog.response(
			    false, "密码重置失败", "密码重置失败："
				+ wretailerService.error[result.ecode], undefined);
		    }
		});
	    }
	};
	
	dialog.edit_with_modal(
	    "reset-password.html", undefined, callback, undefined,
	    {retailer:retailer, password_pattern:pattern.password});
    };

    $scope.update_score = function(retailer){
	console.log(retailer);
	var callback = function(params){
	    console.log(params); 
	    var score = diablo_get_modified(params.retailer.nscore, retailer.score); 
	    // console.log(update_retailer);

	    wretailerService.update_retailer_score(retailer.id, score).then(function(
		result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "会员积分修改",
			"会员积分 [" +  score.toString() + "] 修改成功！！",
			$scope, function(){
			    $scope.do_refresh($scope.pagination.current_page, $scope.search);
			});
    		} else{
		    dialog.response(
			false, "会员积分修改",
			"会员积分修改失败："
			    + wretailerService.error[result.ecode]);
    		}
    	    }) 
	};

	dialog.edit_with_modal(
	    "update-score.html", undefined, callback, undefined,
	    {retailer:angular.extend(retailer, {nscore:retailer.score})});
    };
});

wretailerApp.controller("wretailerChargeDetailCtrl", function(
    $scope, diabloFilter, diabloUtilsService, localStorageService, wretailerService,
    filterEmployee, filterRetailer, filterCharge, user, base){

    var dialog = diabloUtilsService;
    
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("retailer", filterRetailer);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.right = {master: rightAuthen.authen_master(user.type)};
    
    var now = $.now();
    // var start_time = diablo_base_setting(
    // 	"qtime_start", -1, base, diablo_set_date, diabloFilter.default_start_time(now));
    
    // $scope.time = diabloFilter.default_time($scope.qtime_start, now);
    $scope.time = diabloFilter.default_time(now, now);
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_charge_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
			$scope.total_cbalance = result.cbalance;
			$scope.total_sbalance = result.sbalance;
		    }

		    angular.forEach(result.data, function(d){
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.charge = diablo_get_object(d.cid, filterCharge);
			d.accbalance = d.lbalance + d.cbalance + d.sbalance;
		    });

		    diablo_order(result.data, (page - 1) * $scope.items_perpage + 1);
		    $scope.charges = result.data;
		    $scope.current_page = page; 
		} 
	    })
	})
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function(page){
	$scope.do_search(page)
    };

    $scope.refresh();

    $scope.delete_recharge = function(charge){
	console.log(charge);
	var callback = function(){
	    wretailerService.delete_recharge(charge.id).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "删除充值记录", "充值记录删除成功！！" ,
			undefined,
			function(){$scope.do_search($scope.current_page)})
		} else {
		    dialog.response(
			false, "删除充值记录", "删除充值记录失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};
	
	dialog.request(
	    "删除充值记录",
	    "充值记录删除时，会员余额会相应减少，确定要删除该充值记录吗？",
	    callback);
    };

    $scope.update_recharge = function(recharge) {
	console.log(recharge)

	var callback = function(params){
	    console.log(params);

	    var update = {
		id: recharge.id,
		employee: diablo_get_modified(params.recharge.employee, recharge.employee)
	    };

	    console.log(update);

	    wretailerService.update_recharge(update).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "充值记录修改", "充值记录修改成功！！" ,
			undefined,
			function(){$scope.do_search($scope.current_page)})
		} else {
		    dialog.response(
			false, "删除充值记录", "充值记录删除失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};

	var employees = filterEmployee.filter(function(e){
	    return e.shop === recharge.shop_id;
	});
	
	var payload = {
	    recharge: recharge,
	    employees: employees
	};
	
	dialog.edit_with_modal("update-recharge.html", undefined, callback, undefined, payload);
    };
});

wretailerApp.controller("wretailerTicketDetailCtrl", function(
    $scope, diabloFilter, diabloPattern, diabloUtilsService,
    wretailerService, filterRetailer, user){

    var dialog = diabloUtilsService;

    $scope.pattern = {comment: diabloPattern.comment};
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0; 

    $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("retailer", filterRetailer);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // $scope.right = {master: rightAuthen.authen_master(user.type)};
    
    var now = retailerUtils.first_day_of_month();
    // var start_time = diablo_base_setting(
    // 	"qtime_start", -1, base, diablo_set_date, diabloFilter.default_start_time(now));
    
    // $scope.time = diabloFilter.default_time($scope.qtime_start, now);
    $scope.time = diabloFilter.default_time(now.first, now.current);
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_ticket_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.tickets = angular.copy(result.data);
		
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
			$scope.total_balance = result.balance;
		    } 

		    diablo_order($scope.tickets, (page - 1) * $scope.items_perpage + 1);
		    $scope.current_page = page; 
		} 
	    })
	})
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function(page){
	$scope.do_search(page)
    };

    $scope.refresh();

    $scope.consume = function(ticket){
	console.log(ticket);
	var callback = function(params){
	    console.log(params);
	    
	    wretailerService.consume_ticket(ticket.id, params.comment).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "电子卷消费", "电子卷消费成功！！" ,
			undefined,
			function(){ticket.state=2})
		} else {
		    dialog.response(
			false, "电子卷消费", "电子卷消费失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};

	
	dialog.edit_with_modal("effect-ticket.html", 'lg', callback, undefined,
			       {comment_pattern: $scope.pattern.comment}); 
    };

    $scope.effect = function(ticket) {
	console.log(ticket)

	var callback = function(params){
	    console.log(params);
	    
	    wretailerService.effect_ticket(ticket.id).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "电子卷确认", "电子卷确认成功，该电子卷可正常使用！！" ,
			undefined,
			function(){ticket.state=1})
		} else {
		    dialog.response(
			false, "电子", "电子卷确认失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};

	dialog.request("电子卷确认", "确定要使该电子卷生效吗？", callback, undefined, undefined);
    };
});



wretailerApp.controller("wretailerCtrl", function(
    $scope, localStorageService){
    diablo_remove_local_storage(localStorageService);
});

wretailerApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
