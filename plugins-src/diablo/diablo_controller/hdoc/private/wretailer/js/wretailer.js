'use strict'

function wretailerNewCtrlProvide(
    $scope, wretailerService, diabloFilter, diabloPattern, diabloUtilsService, user, base){
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      decimal_2:    diabloPattern.decimal_2,
		      score:        diabloPattern.number,
		      password:     diabloPattern.num_passwd,
		      name:         diabloPattern.chinese_name,
		      id_card:      diabloPattern.id_card,
		      card:         diabloPattern.card};
    $scope.shops = user.sortShops;

    $scope.right = {master: rightAuthen.authen_master(user.type)};    
    if ($scope.right.master) {
	$scope.retailer_types = wretailerService.retailer_types;
    } else {
	$scope.retailer_types = wretailerService.retailer_types.filter(function(t) {
	    return t.id !== 2;
	});
    };

    var sale_mode = retailerUtils.sale_mode($scope.shops[0].id, base);
    $scope.setting = {hide_pwd:retailerUtils.to_integer(sale_mode.charAt(9))}; 
    
    $scope.levels = diablo_retailer_levels;
    $scope.retailer = {
	birth:$.now(),
	type :$scope.retailer_types[0],
	shop :$scope.shops[0],
	level:$scope.levels[0]
    };

    $scope.match_retailer_phone = function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    };
    
    $scope.new_wretailer = function(retailer){
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
};


function wretailerDetailCtrlProvide(
    $scope, $location, $q, dateFilter, diabloFilter, diabloPattern,
    diabloUtilsService, localStorageService, wretailerService,
    filterEmployee, filterCharge, filterRegion, user, base){
    $scope.employees      = filterEmployee;
    // $scope.charges        = filterCharge;
    $scope.charges        = filterCharge.filter(function(c){
	return c.type===diablo_charge && c.deleted!==diablo_has_deleted;
    });
    
    $scope.draws          = filterCharge.filter(function(c){
	return c.type===diablo_withdraw && c.deleted!==diablo_has_deleted;
    })
    $scope.draws          = $scope.draws.concat([{id:-1, name:"重置提现方案"}]);;
    $scope.regions        = filterRegion;
    
    $scope.shops           = user.sortShops.concat([{id:-1, name:"无"}]);
    $scope.shopIds         = user.shopIds;
    $scope.retailer_types  = wretailerService.retailer_types;
    $scope.months          = retailerUtils.months();
    $scope.date_of_month   = retailerUtils.date_of_month();
    $scope.retailer_levels = diablo_retailer_levels;

    var sale_mode = retailerUtils.sale_mode($scope.shops[0].id, base);
    $scope.setting = {hide_pwd:retailerUtils.to_integer(sale_mode.charAt(9))}; 
    
    $scope.select         = {phone:undefined};

    var dialog = diabloUtilsService;
    var now    = $.now();

    $scope.no_vips = base.filter(function(s){
	return 's_customer' === s.name
    }).map(function(c){return parseInt(c.value)});

    var LODOP;
    for (var i=0, l=$scope.shopIds.length; i<l; i++){
	var print_access = retailerUtils.print_num($scope.shopIds[i], base);
    	if (diablo_frontend === retailerUtils.print_mode($scope.shopIds[i], base)){
    	    if (needCLodop()) {
    		loadCLodop(print_access.protocal);
    		break;
    	    };
    	}
    }; 

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenRetailerRight();
    // $scope.right = {
    // 	reset_password        :retailerUtils.authen(user.type, user.right, 'reset_password'),
    // 	delete_retailer       :retailerUtils.authen(user.type, user.right, 'delete_retailer'),
    // 	update_retailer_score :retailerUtils.authen(user.type, user.right, 'update_score'),
    // 	export_retailer       :retailerUtils.authen(user.type, user.right, 'export_retailer'),
    // 	query_balance         :retailerUtils.authen(user.type, user.right, 'query_balance'),
    // 	update_phone          :retailerUtils.authen(user.type, user.right, 'update_phone'),
    // 	set_withdraw          :retailerUtils.authen(user.type, user.right, 'set_withdraw'),
    // 	update_level          :retailerUtils.authen(user.type, user.right, 'update_level'),
    // 	master                :rightAuthen.authen_master(user.type) 
    // };
    // console.log($scope.right);

    /*
     * filter
     */
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("month", $scope.months);
    diabloFilter.add_field("date", $scope.date_of_month);
    diabloFilter.add_field("region", $scope.regions);
    diabloFilter.add_field("shop", user.sortShops);
    diabloFilter.add_field("level", $scope.retailer_levels);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    $scope.order_fields = retailerUtils.order_fields();
    $scope.sort = {mode: $scope.order_fields.id, sort:diablo_desc};

    /*
     * pagination
     */
    $scope.max_page_size = diablo_max_page_size();
    $scope.items_perpage = diablo_items_per_page();
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.total_items   = undefined;

    
    var storage = localStorageService.get(diablo_key_retailer);
    // console.log(storage); 
    if (angular.isDefined(storage) && storage !== null){
	$scope.current_page = storage.page;
	$scope.filters      = storage.filter;
	$scope.select.phone = storage.phone;
    }

    $scope.time = diabloFilter.default_time(now, now);
    
    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };

    $scope.save_stastic = function(){
	localStorageService.remove("retailer-detail-stastic");
	localStorageService.set(
	    "retailer-detail-stastic",
	    {total_items:       $scope.total_items, 
	     total_balance:     $scope.total_balance,
	     total_consume:     $scope.total_consume,
	     t:                 now});
    };

    var add_search_condition = function(search) {
	if (angular.isDefined($scope.select.phone) && angular.isObject($scope.select.phone)){
	    search.mobile = $scope.select.phone.mobile;
	    search.py = $scope.select.phone.py;
	}

	return search;
    };
    
    $scope.do_search = function(page){
	// console.log($scope.filters);
    	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    console.log($scope.select.phone); 
	    search = add_search_condition(search); 
	    localStorageService.remove(diablo_key_retailer);
	    localStorageService.set(diablo_key_retailer, {filter:$scope.filters,
							  phone: $scope.select.phone,
							  page: page,
							  t: now});

	    if (page !== $scope.default_page) {
		var stastic = localStorageService.get("retailer-detail-stastic");
		// console.log(stastic);
		$scope.total_items       = stastic.total_items; 
		$scope.total_balance     = stastic.total_balance;
		$scope.total_consume     = stastic.total_consume; 
	    };
	    
    	    wretailerService.filter_retailer(
		$scope.sort, $scope.match, search, page, $scope.items_perpage
    	    ).then(function(result){
    		console.log(result);
    		if (result.ecode === 0){
    		    if (page === $scope.default_page){
			$scope.total_items   = result.total;
			$scope.total_balance = result.balance;
			$scope.total_consume = result.consume;
			$scope.retailers = [];
			$scope.save_stastic();
    		    }

		    $scope.retailers = angular.copy(result.data);
		    angular.forEach($scope.retailers, function(r){
			r.type = diablo_get_object(r.type_id, $scope.retailer_types);
			r.olevel = $scope.retailer_levels[r.level];
			r.birthday = r.birth.substr(5,8); 
			r.birth     = diablo_set_date_obj(r.birth);
			r.shop      = diablo_get_object(r.shop_id, $scope.shops);
			r.edit_shop = in_array($scope.shopIds, r.shop_id)
			    || r.shop_id === diablo_invalid_index;
			r.no_vip    = in_array($scope.no_vips, r.id)
			    || r.type === diablo_system_retailer ? true : false;
			r.draw     = diablo_get_object(r.draw_id, $scope.draws);
		    });
		    
    		    diablo_order($scope.retailers, (page - 1) * $scope.items_perpage + 1);
    		    $scope.current_page = page;
    		} 
    	    })
    	})
    };

    $scope.print_retailer = function() {
	var callback = function() {
	    diabloFilter.do_filter($scope.filters, $scope.time, function(search){
		add_search_condition(search);
		diablo_goto_page("#/print_w_retailer/"
				 + angular.toJson(search) + "/" + angular.toJson($scope.sort)) ; 
	    });
	}
	
	dialog.request(
	    "会员打印", "会员打印需要打印机支持A4纸张，确认要打印吗？",
	    callback, undefined, undefined);
    };

    $scope.withdraw = function (){
	// var check_same = function(draws) {
	//     for (var i=0, l=draws.length; i<l; i++){
	// 	if (draws[i].select && draws[i].id === shop.draw_id){
	// 	    return true;
	// 	}
	//     }
	//     return false; 
	// };
	angular.forEach($scope.draws, function(d){
	    d.select = false; 
	});
	
	var callback = function(params){
	    console.log(params); 
	    var select = params.draws.filter(function(d){
		return d.select;
	    })[0];

	    console.log(select);

	    diabloFilter.do_filter($scope.filters, $scope.time, function(search){
		if (angular.isDefined($scope.select.phone) && angular.isObject($scope.select.phone)){
		    search.mobile = $scope.select.phone.mobile;
		    search.py = $scope.select.phone.py;
		}

		wretailerService.set_withdraw(select.id, search).then(function(result){
		    console.log(result); 
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true,
			    "会员提现方案",
			    "会员提现方案设置成功！！",
			    undefined, function(){$scope.do_search($scope.current_page)});
			// shop.draw_id = select.id;
			// shop.draw = diablo_get_object(shop.draw_id, $scope.draws);
			// dialog.response(true, "提现方案", "编辑提现方案成功！！");
		    } else {
			dialog.response(
			    false,
			    "会员提现方案",
			    "会员提现方案设置失败：" + wretailerService.error[result.ecode]);
		    }
		}); 
	    }); 
	};  

	var check_only = function(select, draws){
	    angular.forEach(draws, function(d){
		if (d.id !== select.id)
		    d.select = false;
	    });
	};

	var check_one = function(draws){
	    for (var i=0,l=draws.length; i<l; i++){
		if (draws[i].select) return true;
	    }
	    return false;
	};
	
	dialog.edit_with_modal(
	    "retailer-withdraw.html",
	    undefined,
	    callback,
	    undefined,
	    {draws: $scope.draws, check_only: check_only, check_one:check_one}
	);
    };

    $scope.refresh = function(){
	localStorageService.remove("retailer-detail-stastic");
	$scope.select.phone = undefined;
	$scope.do_search($scope.default_page);
    };

    $scope.match_retailer_phone = function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    };

    $scope.use_order = function(mode){
	$scope.sort.mode = mode;
	if ($scope.right.page_retailer) {
	    $scope.do_search($scope.current_page); 
	}
    }

    if ($scope.right.page_retailer) {
	$scope.do_search($scope.current_page); 
    } 

    $scope.new_retailer = function(){
	$location.path("/wretailer_new"); 
    };

    $scope.charge_detail = function(){
	diablo_goto_page("#/wretailer_charge_detail");
    }

    $scope.trans_info = function(r){
	diablo_goto_page("#/wretailer_trans/" +r.id.toString());
    };

    var pattern = {name_address: diabloPattern.ch_name_address,
		   name:         diabloPattern.chinese_name,
		   tel_mobile:   diabloPattern.tel_mobile,
		   decimal_2:    diabloPattern.decimal_2,
		   number:       diabloPattern.number,
		   comment:      diabloPattern.comment,
		   password:     diabloPattern.num_passwd,
		   id_card:      diabloPattern.id_card,
		   card:         diabloPattern.card}; 

    var is_unlimit_card = function(rule_id) {
	return rule_id === diablo_month_unlimit_charge
	    || rule_id === diablo_quarter_unlimit_charge
	    || rule_id === diablo_half_of_year_unlimit_charge
	    || rule_id === diablo_year_unlimit_charge;
    };

    var is_theoretic_card = function(rule_id) {
	return rule_id === diablo_theoretic_charge;
    };

    var get_charge = function(charge_id) {
	// console.log(charges);
	for (var i=0, l=$scope.charges.length; i<l; i++){
	    if (charge_id === $scope.charges[i].id){
		return $scope.charges[i];
	    }
	} 
	return undefined;
    };
    
    var get_employee = function(shop_id) {
	var validEmployees = $scope.employees.filter(function(e) {
	    return e.shop === shop_id && e.state === 0;
	});

	return validEmployees.length === 0 ? $scope.employees : validEmployees;
    }; 

    $scope.charge = function(retailer){
	console.log($scope.charges); 
	var callback = function(params){
	    console.log(params);

	    var charge_balance  = retailerUtils.to_integer(params.charge)
		+ retailerUtils.to_integer(params.card)
		+ retailerUtils.to_integer(params.wxin);

	    var promotion       = params.retailer.select_charge; 
	    var send_balance = function(){
		if (diablo_giving_charge === promotion.rule_id) {
		    if (promotion.charge !== 0 && charge_balance >= promotion.charge){
			return Math.floor(charge_balance / promotion.charge) * promotion.balance;
		    } else {
			return 0;
		    }
		} else if (diablo_theoretic_charge === promotion.rule_id) {
		    return retailerUtils.to_integer(promotion.cstime);
		}
		return 0;
		// else if (diablo_times_charge === promotion.rule_id) {
		//     return Math.floor(charge_balance / promotion.xtime);
		// } else {
		//     return undefined;
		// }
	    }();

	    var ctime, stime, goods;
	    if (promotion.rule_id === diablo_theoretic_charge) {
		ctime = retailerUtils.to_integer(promotion.ctime) + retailerUtils.to_integer(promotion.cstime);
		goods = params.goods.filter(function(g) {
		    return angular.isDefined(g.select) && g.select;
		})
	    }
		

	    if (is_unlimit_card(promotion.rule_id)) stime = dateFilter(params.stime, "yyyy-MM-dd");
	    
	    wretailerService.new_recharge({
		shop:           params.retailer.select_shop.id, 
		retailer:       retailer.id, 
		employee:       params.retailer.select_employee.id, 
		charge_balance: charge_balance,
		cash:           retailerUtils.to_integer(params.charge),
		card:           retailerUtils.to_integer(params.card),
		wxin:           retailerUtils.to_integer(params.wxin),
		send_balance:   send_balance,
		charge:         promotion.id,
		ctime:          ctime,
		stime:          stime,
		good:           angular.isArray(goods) ? goods.map(
		    function(g) {return {id:g.id, count:g.count}}) : undefined,
		comment:        params.comment
	    }).then(function(result){
		console.log(result); 
		if (result.ecode == 0){
		    if (!is_theoretic_card(promotion.rule_id) && !is_unlimit_card(promotion.rule_id)) {
			retailer.balance += charge_balance + retailerUtils.to_float(send_balance) 
		    }

		    var charge_shop = params.retailer.select_shop;
		    var print_access = retailerUtils.print_num(charge_shop.id, base);
		    var LODOP;
		    var print_callback = function() {
			if (diablo_frontend === retailerUtils.print_mode(charge_shop.id, base)){
			    LODOP = getLodop();
			    if (angular.isDefined(LODOP)){
				retailerChargePrint.init(LODOP);
				
				var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss"); 
				var top = retailerChargePrint.gen_head(
				    LODOP,
				    charge_shop.name,
				    params.retailer.select_employee.name, 
				    params.retailer.name,
				    pdate);
				
				top = retailerChargePrint.gen_body(
				    LODOP,
				    top,
				    {name:promotion.name,
				     cbalance:charge_balance,
				     sbalance:send_balance,
				     comment:params.comment ? params.comment : diablo_empty_string});

				retailerChargePrint.gen_foot(LODOP, top); 
				retailerChargePrint.start_print(LODOP);
			    } 
			}
		    };
		    
		    dialog.response_with_callback(
			true,
			"会员充值",
			"会员 [" + retailer.name + "] 充值成功，"
			    + "帐户余额 [" + retailer.balance.toString() + " ]！！"
			    + function(){
				if (result.sms_code !== 0)
				    return "发送短消息失败："
				    + wretailerService.error[result.sms_code];
				else return ""; 
			    }(),
			undefined, function(){
			    dialog.request(
				"会员充值",
				"是否打印充值单据？",
				print_callback, undefined, undefined); 
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

	var select_shop = $scope.shops[0];
	var employees = get_employee(select_shop.id);

	var start_charge = function(card_goods) {
	    dialog.edit_with_modal(
		"wretailer-charge.html",
		undefined,
		callback,
		$scope,
		{retailer:  {
		    name: retailer.name,
		    balance:retailer.balance,
		    shops: $scope.shops,
		    select_shop: select_shop,
		    employees: employees,
		    select_employee: employees[0],
		    // charges: $scope.charges,
		    // select_charge:get_charge($scope.shops[0].charge_id)
		},
		 
		 goods: card_goods,
		 card: 0,
		 wxin: 0,
		 stime: $.now(),
		 pattern:  pattern,
		 get_charge: get_charge,
		 unlimit_card: is_unlimit_card,
		 calc_card_count: function(goods, ctime, cstime) {
		     var all_times = ctime + retailerUtils.to_integer(cstime);
		     var good_count = 0;
		     angular.forEach(goods, function(g) {
		     	 if (angular.isDefined(g.select) && g.select) {
		     	     good_count += 1;
		     	 }
		     });

		     var per_count = Math.floor(all_times / good_count);
		     var last_select = diablo_invalid_index;
		     for (var i=0, l=goods.length; i<l; i++) {
			 if (angular.isDefined(goods[i].select) && goods[i].select) {
		     	     goods[i].count = per_count;
			     last_select = i;
		     	 } else {
			     goods[i].count = undefined;
			 }
		     }

		     if (last_select !== diablo_invalid_index) {
			 goods[last_select].count += all_times % good_count;
		     }
		 }, 
		 check_good: function(goods) {
		     var valid = false;
		     for (var i=0, l=goods.length; i<l; i++) {
			 if (angular.isDefined(goods[i].select) && goods[i].select) {
		     	     valid = true;
			     break;
		     	 }
		     }
		     return valid;
		 }
		}
	    )
	};
	
	
	var deferred = $q.defer(); 
	diabloFilter.list_threshold_card_good(deferred, $scope.shopIds);
	deferred.promise.then(function(goods) {
	    console.log(goods);
	    start_charge(goods.map(function(g) { return {id:g.id, name:g.name}}));
	}); 
    };

    var get_modified = diablo_get_modified; 
    $scope.update_retailer = function(oRetailer){
	console.log(oRetailer);
	oRetailer.intro = {
	    id:oRetailer.intro_id,
	    name:oRetailer.intro_id === diablo_invalid_index ? "无" : oRetailer.intro_name};
	
	var callback = function(params){
	    console.log(params);
	    var uRetailer = params.retailer;
	    var update_retailer = {
		name:  get_modified(uRetailer.name, oRetailer.name),
		card:  get_modified(uRetailer.card, oRetailer.card),
		py:    get_modified(diablo_pinyin(uRetailer.name), diablo_pinyin(oRetailer.name)),
		id_card: get_modified(uRetailer.id_card, oRetailer.id_card),
		mobile:  get_modified(uRetailer.mobile,  oRetailer.mobile),
		address: get_modified(uRetailer.address, oRetailer.address),
		comment: get_modified(uRetailer.comment, oRetailer.comment),
		shop:    uRetailer.edit_shop ? uRetailer.shop.id : undefined,
		type:    get_modified(uRetailer.type, oRetailer.type),
		intro: function() {
		    if (uRetailer.intro && angular.isObject(uRetailer.intro))
			return get_modified(uRetailer.intro.id, oRetailer.intro);
		    return get_modified(diablo_invalid_index, oRetailer.intro);
		}(),
		level: function() {
		    if (oRetailer.type_id !== 2)
			return get_modified(uRetailer.olevel.level, oRetailer.level)}(),
		
		password:get_modified(uRetailer.password, oRetailer.password),
		
		birth:get_modified(uRetailer.birth.getTime(), oRetailer.birth.getTime()),
		balance: get_modified(uRetailer.balance, oRetailer.balance)
	    };
	    
	    console.log(update_retailer); 
	    update_retailer.id = params.retailer.id;
	    // update_retailer.obalance = oRetailer.balance;
	    // console.log(update_retailer);

	    if (update_retailer.intro !== diablo_invalid_index
		&& update_retailer.intro === update_retailer.id) {
		dialog.response(
		    false, "会员编辑", "会员编辑失败：" + wretailerService.error[2199]);
	    } else {
		wretailerService.update_retailer(update_retailer).then(function(result){
    		    console.log(result);
    		    if (result.ecode == 0){
			dialog.response_with_callback(
			    true, "会员编辑", "会员 [" + oRetailer.name + "] 信息修改成功！！",
			    $scope, function(){
				$scope.do_search($scope.current_page);
			    });
    		    } else{
			dialog.response(
			    false, "会员编辑", "会员编辑失败：" + wretailerService.error[result.ecode]);
    		    }
    		}) 
	    } 
	};

	var check_same = function(new_retailer){
	    return angular.equals(new_retailer, oRetailer);
	};

	var check_exist = function(new_retailer){
	    for(var i=0, l=$scope.retailers.length; i<l; i++){
		if (new_retailer.name === $scope.retailers[i].name
		    && new_retailer.name !== oRetailer.name){
		    return true;
		}
	    }

	    return false;
	};
	
	dialog.edit_with_modal(
	    "update-wretailer.html", undefined, callback, $scope,
	    {retailer:    oRetailer,
	     types:       function(){
		 if ($scope.right.master)
		     return $scope.retailer_types;
		 else
		     return $scope.retailer_types.filter(function(t){
			 return t.id !== diablo_system_retailer;
		     });
	     }(),
	     levels:      $scope.retailer_levels,
	     shops:       $scope.shops,
	     pattern:     pattern,
	     check_same:  check_same,
	     check_exist: check_exist})
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
			    $scope.refresh();
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

    $scope.export_retailer = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search) {
	    wretailerService.export_w_retailer(search).then(function(state){
		if (state.ecode === 0){
		    dialog.response_with_callback(
			true,
			"文件导出成功",
			"创建文件成功，请点击确认下载！！",
			undefined,
			function(){window.location.href = state.url;})
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败："
			    + wretailerService.error[state.ecode]);
		}
	    })
	}); 
    };

    $scope.syn_pinyin = function(){
	wretailerService.list_retailer().then(function(retailers){
	    var s = [];
	    angular.forEach(retailers, function(r){
		s.push({id:r.id, py:diablo_pinyin(r.name)});
	    });

	    wretailerService.syn_retailer_pinyin(s).then(function(result){
		if (result.ecode === 0){
		    dialog.response(true, "同步会员姓名拼音", "同步成功！！");
		} else {
		    dialog.response(true,
				    "同步会员姓名拼音",
				    "同步失败！！" + wretailerService.error[result.ecode]);
		}
	    });
	});
    };
};

function wretailerChargeDetailCtrlProvide(
    $scope, diabloFilter, diabloUtilsService, localStorageService, wretailerService,
    filterEmployee, filterCharge, user, base){

    var dialog = diabloUtilsService;
    
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;
    $scope.shops = user.sortShops;
    
    $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    });
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("employee", filterEmployee);

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // $scope.right = {
    // 	master: rightAuthen.authen_master(user.type),
    // 	update_phone: retailerUtils.authen(user.type, user.right, 'update_phone')};

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenRetailerRight();
    
    var now = retailerUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);
    
    $scope.do_search = function(page){
	console.log($scope.filters);
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
			$scope.total_cash = result.tcash;
			$scope.total_card = result.tcard;
			$scope.total_wxin = result.twxin;
		    }

		    angular.forEach(result.data, function(d){
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.charge = diablo_get_object(d.cid, filterCharge);
			if (d.charge.rule_id === diablo_giving_charge
			    || d.charge.rule_id === diablo_times_charge)
			    d.accbalance = retailerUtils.to_decimal(d.lbalance + d.cbalance + d.sbalance);
			else
			    d.accbalance = 0;
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
		employee: diablo_get_modified(params.recharge.employee, recharge.employee),
		shop: diablo_get_modified(params.recharge.select_shop.id, recharge.shop_id),
		comment: diablo_get_modified(params.comment, recharge.comment)
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
			false, "修改充值记录", "充值记录修改失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};

	var employees = filterEmployee.filter(function(e){
	    return e.shop === recharge.shop_id;
	});

	recharge.select_shop = diablo_get_object(recharge.shop_id, $scope.shops);
	
	var payload = {
	    shops:     $scope.shops,
	    recharge:  recharge,
	    employees: employees
	};
	
	dialog.edit_with_modal("update-recharge.html", undefined, callback, undefined, payload);
    };

    $scope.export_charge_detail = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.export_recharge_detail(search).then(function(state){
		if (state.ecode === 0){
		    dialog.response_with_callback(
			true,
			"文件导出成功",
			"创建文件成功，请点击确认下载！！",
			undefined,
			function(){window.location.href = state.url;})
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败："
			    + wretailerService.error[state.ecode]);
		}
	    })
	}); 
    };
};

function wretailerTicketDetailCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, filterShop, filterScore, user){

    var dialog = diabloUtilsService; 
    // $scope.shops = user.sortShops;
    $scope.scores = filterScore.filter(function(s) {return s.type_id === 1});
    $scope.pattern = {comment: diabloPattern.comment};
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.right = {
	syn_ticket        :retailerUtils.authen(user.type, user.right, 'syn_score_ticket')
    };
    // $scope.retailers = filterRetailer.filter(function(r){return r.score > 10000});

    $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    });
    
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

		    angular.forEach($scope.tickets, function(t){
			t.shop = diablo_get_object(t.shop_id, filterShop);
		    });

		    diablo_order($scope.tickets, (page - 1) * $scope.items_perpage + 1);
		    $scope.current_page = page; 
		} 
	    })
	})
    };

    var check_only = function(select, scores){
	angular.forEach(scores, function(s){
	    if (s.id !== select.id)
		s.select = false;
	});
    };

    var check_one = function(scores){
	for (var i=0,l=scores.length; i<l; i++){
	    if (scores[i].select) return true;
	}
	return false;
    };
    
    $scope.syn_ticket = function() {
	var callback = function(params) {
	    console.log(params); 
	    var select_score = -1;
	    for (var i=0,l=params.scores.length; i<l; i++){
		if (params.scores[i].select) {
		    select_score = params.scores[i].id;
		    break;
		}
	    } 
	    
	    diabloFilter.do_filter($scope.filters, $scope.time, function(search) {
		wretailerService.syn_ticket(angular.extend(search, {sid:select_score})).then(function(result) {
		    console.log(result);
		    if (result.ecode === 0) {
			dialog.response_with_callback(
			    true,
			    "同步电子卷",
			    "同步电子卷成功！！",
			    undefined,
			    function(){$scope.do_search($scope.current_page)}) 
		    } else {
			dialog.response(
			    false, "同步电子卷", "同步电子卷失败：" + wretailerService.error[result.ecode]);
		    }
		});
	    });
	};

	dialog.edit_with_modal(
	    "syn-ticket.html",
	    undefined,
	    callback,
	    undefined,
	    {scores: $scope.scores,
	     check_only: check_only,
	     check_one: check_one}); 
	
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
	    wretailerService.consume_ticket(ticket.id, ticket.sid, params.comment).then(function(result){
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

	
	dialog.edit_with_modal("effect-ticket.html", undefined, callback, undefined,
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
};

function wretailerCustomTicketDetailCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService,
    wretailerService, filterTicketPlan, filterShop){
    var dialog = diabloUtilsService; 
    // $scope.shops = user.sortShops;
    $scope.pattern = {positive_num: diabloPattern.positive_num};
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    });
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = retailerUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_custom_ticket_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.tickets = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
			$scope.total_balance = result.balance;
		    }

		    angular.forEach($scope.tickets, function(t){
			t.shop = diablo_get_object(t.shop_id, filterShop);
		    	t.in_shop = diablo_get_object(t.in_shop_id, filterShop);
			t.provide_shop =  diablo_get_object(t.p_shop_id, filterShop);
			t.plan = diablo_get_object(t.plan_id, filterTicketPlan);
		    });
		    console.log($scope.tickets); 
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

    $scope.add_batch = function(){
	var makeTicketTitle = "批量制券"; 
	var callback = function(params){
	    console.log(params);
	    var sbatch  = retailerUtils.to_integer(params.sbatch);
	    var count   = retailerUtils.to_integer(params.count);
	    var balance = retailerUtils.to_integer(params.balance);
	    var plan    = params.plan;

	    if (sbatch.toString().length > diablo_max_ticket_batch) {
		dialog.set_error();
		dialog.response(makeTicketTitle, 2118);
	    } else if (count > 1000) {
		dialog.response(makeTicketTitle, 2115);
	    } else if (balance > 5000) {
		dialog.response(makeTicketTitle, 2116);
	    } 
	    else {
		wretailerService.make_ticket_batch(
		    {sbatch:sbatch, count:count, balance:balance, plan:plan.id}
		).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true,
			    makeTicketTitle,
			    "批量制券成功！！" ,
			    undefined,
			    function(){});
		    } else {
			dialog.set_error(makeTicketTitle, wretailerService.error[result.ecode]);
		    }
		})
	    } 
	};

	if (filterTicketPlan.length === 0) {
	    dialog.set_error(makeTicketTitle, 2191);
	} else {
	    dialog.edit_with_modal(
		"add-ticket-batch.html",
		undefined,
		callback,
		undefined,
		{num_pattern: $scope.pattern.positive_num,
		 plan: filterTicketPlan[0],
		 planes: filterTicketPlan,
		 balance: filterTicketPlan[0].balance}); 
	} 
    };

    $scope.discard = function(ticketId, mode) {
	console.log(ticketId);
	var callback = function(params) {
	    wretailerService.discard_custom_ticket(ticketId, mode).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "优惠券废弃", "优惠券废弃成功！！" ,
			undefined,
			function(){
			    $scope.do_search($scope.current_page);
			})
		} else {
		    dialog.response(
			false, "优惠券废弃", "优惠券废弃失败："
			    + wretailerService.error[result.ecode]);
		}
	    })
	};

	dialog.request("优惠券废弃", "优惠券废弃后不可恢复，确定要废弃吗？", callback, undefined, undefined);
    };  
};

function wretailerThresholdCardDetailCtrlProvide(
    $scope, $q, dateFilter, diabloFilter, diabloPattern,
    diabloUtilsService, wretailerService, filterEmployee, user, base){
    var dialog = diabloUtilsService;
    
    var now = $.now();
    $scope.shopIds = user.shopIds;
    $scope.shops   = user.sortShops;
    $scope.employees = filterEmployee.filter(function(e) {
	return e.state === 0 && in_array($scope.shopIds, e.shop);
    });

    var LODOP;
    var print_mode = diablo_backend;
    for (var i=0, l=$scope.shopIds.length; i<l; i++){
	print_mode = retailerUtils.print_mode($scope.shopIds[i], base);
	var print_access = retailerUtils.print_num($scope.shopIds[i], base);
    	if (diablo_frontend === print_mode){
    	    if (needCLodop()) {
    		loadCLodop(print_access.protocal);
    		break;
    	    };
    	}
    }; 
    
    var deferred = $q.defer(); 
    diabloFilter.list_threshold_card_good(deferred, $scope.shopIds);
    deferred.promise.then(function(goods) {
	console.log(goods);
	$scope.card_goods = goods;
	$scope.refresh();
    });
    
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.select         = {phone:undefined};

    $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    });
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt(); 
    
    $scope.time = diabloFilter.default_time(now, now);
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    console.log($scope.select.phone);
	    if (angular.isDefined($scope.select.phone) && angular.isObject($scope.select.phone)){
		search.retailer = $scope.select.phone.id;
	    }

	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    wretailerService.filter_threshold_card_detail(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.tcards = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
		    }

		    angular.forEach($scope.tcards, function(c) {
			c.shop = diablo_get_object(c.shop_id, $scope.shops);
			c.rule = diablo_get_object(c.rule_id, wretailerService.threshold_cards);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.tcards);
		    $scope.current_page = page; 
		} 
	    })
	})
    };


    $scope.match_retailer_phone = function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function(page){
	$scope.do_search(page)
    };

    var get_card_title = function(rule_id) {
	if (rule_id === diablo_theoretic_charge)
	    return "次卡消费"
	else if (rule_id === diablo_month_unlimit_charge)
	    return "月卡消费"
	else if (rule_id === diablo_quarter_unlimit_charge)
	    return "季卡消费"
	else if (rule_id === diablo_year_unlimit_charge)
	    return "年卡消费"
	else if (rule_id === diablo_half_of_year_unlimit_charge)
	    return "半年卡消费"
    };
    
    $scope.consume = function(card){
	console.log(card);
	var title = get_card_title(card.rule_id); 
	var callback = function(params){
	    console.log(params);
	    diabloFilter.check_retailer_password(
		card.retailer_id, params.card.password
	    ).then(function(result){
		// console.log(result);
		if (result.ecode === 0){
		    var cgoods = [];
		    var cgoods_to_print = [];
		    var total_count = 0;
		    
		    if (card.rule_id !== diablo_theoretic_charge || !params.has_child_card) {
			total_count = params.count; 
			cgoods_to_print.push({g:params.good.id,
					      n:params.good.name,
					      c:params.count,
					      p:params.good.tag_price}); 
			cgoods.push({g:params.good.id, c:params.count, p:params.good.tag_price});
		    } else {
			angular.forEach(params.goods, function(g) {
			    if (g.select) {
				total_count += g.count;
				cgoods_to_print.push({g:g.id,
						      n:g.name,
						      c:g.count,
						      p:g.tag_price});
				cgoods.push({g:g.id, c:g.count, p:g.tag_price});
			    }
			});
		    }
		    
		    wretailerService.new_threshold_card_sale({
			id        :card.id,
			csn       :card.csn,
			charge    :card.cid,
			rule      :card.rule_id,
			retailer  :card.retailer_id,
			mobile    :card.mobile,
			employee  :params.employee.id,
			cgoods    :cgoods,
			// tag_price :params.good.tag_price,
			count     :total_count,
			shop      :params.shop.id,
			shop_name :params.shop.name,
			comment   :params.comment
			// count     :params.count
		    }).then(function(state) {
			console.log(state);
			if (state.ecode === 0) {
			    var p_num = retailerUtils.print_num(params.shop.id, base).swiming;
			    var saleMode = retailerUtils.sale_mode(params.shop.id, base); 
			    dialog.response_with_callback(
				true,
				title, title + "消费成功！！"
				+ function() {
				    if (state.sms_code !== 0)
					return "发送短消息失败：" + wretailerService.error[result.sms_code];
				    else return ""; 
				}(),
				undefined,
				function() {
				    if (card.rule_id === diablo_theoretic_charge)
					card.ctime -= total_count;
				    
				    var start_print = function(LODOP, ptime) {
					retailerPrint.init(LODOP);
					var top = retailerPrint.gen_head(
					    LODOP,
					    params.shop.name,
					    state.rsn,
					    params.employee.name,
					    card.retailer + "-" + card.mobile,
					    ptime);
					
					if (retailerUtils.to_integer(saleMode.charAt(7)) ) {
					    top = retailerPrint.gen_body(
						LODOP,
						top,
						cgoods_to_print 
					    );
					}
					
					top = retailerPrint.gen_stastic(
					    LODOP,
					    top,
					    {cname: card.cname,
					     rule: card.rule,
					     left_time: card.ctime,
					     expire_date: card.edate},
					    params.comment);
					
					retailerPrint.gen_foot(LODOP, top, ptime); 
					retailerPrint.start_print(LODOP);
				    }

				    if (diablo_frontend === print_mode) {
					// print
					var ptime = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
					if (angular.isUndefined(LODOP)) LODOP = getLodop();

					if (angular.isDefined(LODOP)) {
					    for (var i=0; i<p_num; i++){
						start_print(LODOP, ptime); 
					    }
					}; 
				    } 
				});
			} else {
			    dialog.set_error(title, state.ecode); 
			}
		    });
		} else {
		    dialog.set_error(title, result.ecode); 
		}
	    }); 
	}; 

	var start_consume = function(goods, has_child) {
	    dialog.edit_with_modal(
		"new-card-consume.html",
		undefined,
		callback,
		undefined,
		{title: title,
		 employees: $scope.employees,
		 goods: goods,
		 shops: $scope.shops,
		 
		 card: {
		     rule    :card.rule_id,
		     retailer:card.retailer, 
		     mobile  :card.mobile,
		     ctime   :card.ctime,
		     edate   :card.edate},
		 
		 has_child_card: has_child,
		 count: has_child ? undefined : 1,
		 employee: $scope.employees[0],
		 good: has_child ? undefined: goods[0],
		 shop: $scope.shops[0],
		 comment_pattern: diabloPattern.comment,
		 check_consume: function(goods) {
		     var valid = false;
		     if (card.rule_id === diablo_theoretic_charge) {
			 if (has_child) {
			     for (var i=0, l=goods.length; i<l; i++) {
				 if (goods[i].select
				     && retailerUtils.to_integer(goods[i].count)<=goods[i].left) {
				     valid = true;
				     break;
				 }
			     }
			 } else {
			     valid = true;
			 }
			 
		     } else {
			 valid = true;
		     }
		     
		     return valid;
		 }}
	    );
	}; 
	
	if (card.rule_id === diablo_theoretic_charge) {
	    // get child card
	    wretailerService.list_threshold_child_card(
		card.retailer_id, card.csn
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    var child_goods = [];
		    for (var i=0, l= result.child.length; i<l; i++) {
			for(var j=0, k=$scope.card_goods.length; j<k; j++) {
			    if (result.child[i].good === $scope.card_goods[j].id) {
				child_goods.push(
				    {id:$scope.card_goods[j].id,
				     name:$scope.card_goods[j].name,
				     tag_price:$scope.card_goods[i].tag_price, 
				     left:result.child[i].ctime,
				     count:1});
			    }
			}
		    } 
		    start_consume(
			child_goods.length === 0 ? $scope.card_goods : child_goods,
			child_goods.length === 0 ? false : true);
		} else {
		    // error
		}
	    })
	} else {
	    start_consume($scope.card_goods, false)
	} 
    };

    $scope.delete_card = function(card) {
	console.log(card);
	var title = "删除次/月/季/年/半年卡"; 
	var callback = function() {
	    wretailerService.delete_threshold_card(card.id).then(function(result) {
		if (result.ecode === 0) {
		    dialog.success_response_with_callback(
			title,
			title + "成功！！",
			function() {$scope.do_search($scope.current_page);})
		} else {
		    dialog.set_error(title, result.ecode);
		}
	    })
	}
	
	dialog.request(title, "确定要删除该卡吗?", callback, undefined, undefined);
    };
};

function wretailerThresholdCardSaleCtrlProvide(
    $scope, $q, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, filterEmployee, filterShop){
    var dialog = diabloUtilsService; 
    var deferred = $q.defer(); 
    diabloFilter.list_threshold_card_good(deferred, $scope.shopIds);
    deferred.promise.then(function(goods) {
	console.log(goods);
	$scope.card_goods = goods;
	$scope.refresh();
    });
    
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.select         = {phone:undefined};

    $scope.filters = []; 
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    });
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt(); 

    var now = retailerUtils.first_day_of_month(); 
    $scope.time = diabloFilter.default_time(now.first, now.current);
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_threshold_card_sale(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.sales = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
			$scope.amount_items = result.amount;
		    }

		    angular.forEach($scope.sales, function(s) {
			s.employee = diablo_get_object(s.employee_id, filterEmployee);
			s.cgood    = diablo_get_object(s.cgood_id, $scope.card_goods);
			s.shop     = diablo_get_object(s.shop_id, filterShop);
			s.card     = wretailerService.threshold_cards[s.rule_id - 2];
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.sales);
		    $scope.current_page = page; 
		} 
	    })
	})
    };


    $scope.match_retailer_phone = function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter)
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function(page){
	$scope.do_search(page)
    };

    $scope.cancel_card_sale = function(sale) {
	console.log(sale);
	var callback = function() {
	    wretailerService.delete_threshold_card_sale(
		{rsn:      sale.rsn,
		 rule:     sale.rule_id,
		 shop:     sale.shop_id,
		 card:     sale.card_id,
		 count:    sale.amount,
		 retailer: sale.retailer_id
		}).then(function(result) {
		    console.log(result);
		    if (result.ecode === 0) {
			dialog.response_with_callback(
			    true,
			    "删除按次消费商品",
			    "删除按次消费商品成功！！",
			    undefined,
			    $scope.page_changed($scope.current_page));
		    } else {
			dialog.set_error("删除按次消费商品", result.ecode); 
		    }
		});
	}

	// diabloUtilsService.request(
	//     "删除按次消费商品", "确定要删除该消费记录吗？",
	//     callback, undefined, undefined);
	diabloUtilsService.response(false, "删除按次消费商品", "暂不支持该操作");
    };
};


function wretailerThresholdCardGoodCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, user){
    var dialog = diabloUtilsService;
    var now = $.now();

    $scope.shops = user.sortShops;
    $scope.right = {
	add_good        :retailerUtils.authen(user.type, user.right, 'add_card_good'),
	delete_good     :retailerUtils.authen(user.type, user.right, 'delete_card_good') 
    };

    // $scope.pattern = {name: ch_name_address};
    
    // $scope.shops = user.sortShops;
    // $scope.threshold_cards = wretailerService.threshold_cards;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.filters = []; 
    diabloFilter.reset_field();
    
    $scope.time = diabloFilter.default_time(now, now);
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_threshold_card_good(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.card_goods = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
		    } 
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.card_goods);
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

    $scope.new_card_good = function() {
	var callback = function(params) {
	    console.log(params);
	    wretailerService.add_threshold_card_good(
		{shop:params.shop.id, name:params.name, price:params.tag_price}
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "新增按次消费商品", "新增按次消费商品成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("新增按次消费商品", result.ecode); 
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-card-good.html",
	    undefined,
	    callback,
	    undefined,
	    {shops: $scope.shops,
	     shop:  $scope.shops[0],
	     tag_price: 0,
	     name_pattern: diabloPattern.ch_name_address}); 
    };

    $scope.delete_card_good = function() {
	dialog.response(false, "删除按次消费商品", "系统暂不支持此操作！！", undefined);
    };
};

function wretailerLevelCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, user){
    $scope.levels = diablo_retailer_levels;
    $scope.shops  = [{id: -1, name:"== 默认所有店铺配置相同 =="}].concat(user.sortShops);
    var dialog = diabloUtilsService; 
    var lpattern = {name     :diabloPattern.chinese_name,
		    score    :diabloPattern.number,
		    discount :diabloPattern.discount};

    $scope.refresh = function() {
	wretailerService.list_retailer_level().then(function(levels) {
	    diablo_order(levels); 
	    $scope.retailer_levels = angular.copy(levels);
	    
	    angular.forEach($scope.retailer_levels, function(l) {
	    	l.shop = diablo_get_object(l.shop_id, $scope.shops);
	    });
	});
    };

    $scope.new_level = function() {
	var callback = function(params) {
	    console.log(params);
	    wretailerService.new_retailer_level(
		params.shop.id, params.level.level, params.name, params.score, params.discount
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "新增会员等级", "新增会员等级成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("新增会员等级", result.ecode); 
		}
	    });
	};

	dialog.edit_with_modal(
	    "new-retailer-level.html",
	    undefined,
	    callback,
	    undefined,
	    {shops   :$scope.shops,
	     shop    :$scope.shops[0],
	     levels  :$scope.levels,
	     level   :$scope.levels[0],
	     pattern :lpattern
	    })
    };

    $scope.update_level = function(l) {
	console.log(l);
	var callback = function(params) {
	    console.log(params);
	    wretailerService.update_retailer_level(
		l.id, l.shop.id, params.score, params.discount
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "编辑会员等级", "编辑会员等级成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("编辑会员等级", result.ecode); 
		}
	    });
	};

	dialog.edit_with_modal(
	    "update-retailer-level.html",
	    undefined,
	    callback,
	    undefined,
	    {
		shops   :$scope.shops,
		shop    :diablo_get_object(l.shop_id, $scope.shops),
		level   :$scope.levels[l.level],
		name    :l.name,
		score   :l.score,
		discount :l.discount,
		pattern :lpattern}
	)
    };
};

function wretailerConsumeCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, filterShop, user){
    $scope.levels = diablo_retailer_levels;
    var dialog = diabloUtilsService;

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.shops = user.sortShops;

    $scope.filters = []; 
    diabloFilter.reset_field();

    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("mconsume", []);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = retailerUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);

    $scope.do_search = function(page){
	console.log($scope.filters);
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_retailer_consume(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total; 
		    }

		    angular.forEach(result.data, function(d) {
			d.shop = diablo_get_object(d.shop_id, filterShop);
		    })

		    diablo_order(result.data, (page - 1) * $scope.items_perpage + 1);
		    $scope.consumes = result.data;
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
};

function wretailerPlanCustomTicketCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService, user){
    var dialog = diabloUtilsService; 
    var lpattern = {name     :diabloPattern.chinese_name,
		    number   :diabloPattern.number,
		    remark   :diabloPattern.comment};

    $scope.refresh = function() {
	wretailerService.list_ticket_plan().then(function(planes) {
	    console.log(planes);
	    diablo_order(planes);
	    $scope.planes = planes;
	});
    };

    $scope.refresh();

    $scope.new_plan = function() {
	var callback = function(params) {
	    console.log(params);
	    wretailerService.new_ticket_plan(
		{name: diablo_trim(params.name),
		 balance: retailerUtils.to_integer(params.balance),
		 effect: retailerUtils.to_integer(params.effect),
		 expire: retailerUtils.to_integer(params.expire),
		 scount: retailerUtils.to_integer(params.scount),
		 remark: params.remark ? diablo_trim(params.remark) : undefined}
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "新增制券方案", "新增制券方案成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("新增制券方案失败", result.ecode); 
		}
	    });
	};

	dialog.edit_with_modal("new-ticket-plane.html", undefined, callback, undefined, {});
    };

    $scope.update_plan = function(p) {
	console.log(p);
	var callback = function(params) {
	    console.log(params);
	    wretailerService.update_ticket_plan(
		{plan     :p.id,
		 name     :diablo_get_modified(params.name, p.name),
		 balance  :diablo_get_modified(params.balance, p.balance),
		 effect   :diablo_get_modified(params.effect, p.effect),
		 expire   :diablo_get_modified(params.expire, p.expire),
		 scount   :diablo_get_modified(params.scount, p.scount),
		 remark   :diablo_get_modified(params.remark, p.remark)}
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "制券方案编辑", "制券方案编辑成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("制券方案编辑", result.ecode); 
		}
	    });
	};

	dialog.edit_with_modal("new-ticket-plane.html", undefined, callback, undefined, p);
    };
};


define (["wretailerApp"], function(app){
    app.controller("wretailerNewCtrl", wretailerNewCtrlProvide);
    app.controller("wretailerDetailCtrl", wretailerDetailCtrlProvide);
    app.controller("wretailerChargeDetailCtrl", wretailerChargeDetailCtrlProvide);
    app.controller("wretailerTicketDetailCtrl", wretailerTicketDetailCtrlProvide);
    app.controller("wretailerCustomTicketDetailCtrl", wretailerCustomTicketDetailCtrlProvide);
    app.controller("wretailerThresholdCardDetailCtrl", wretailerThresholdCardDetailCtrlProvide);
    app.controller("wretailerThresholdCardGoodCtrl", wretailerThresholdCardGoodCtrlProvide);
    app.controller("wretailerThresholdCardSaleCtrl", wretailerThresholdCardSaleCtrlProvide);
    app.controller("wretailerLevelCtrl", wretailerLevelCtrlProvide);
    app.controller("wretailerConsumeCtrl", wretailerConsumeCtrlProvide);
    app.controller("wretailerPlanCustomTicketCtrl", wretailerPlanCustomTicketCtrlProvide);
});

