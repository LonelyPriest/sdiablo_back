'use strict'

function wretailerNewCtrlProvide(
    $scope, wretailerService, diabloPattern, diabloUtilsService, user){
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      decimal_2:    diabloPattern.decimal_2,
		      score:        diabloPattern.number,
		      password:     diabloPattern.num_passwd,
		      name:         diabloPattern.chinese_name,
		      id_card:      diabloPattern.id_card};

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
};


function wretailerDetailCtrlProvide(
    $scope, $location, dateFilter, diabloFilter, diabloPattern,
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
    
    $scope.shops          = user.sortShops.concat([{id:-1, name:"无"}]);
    $scope.shopIds        = user.shopIds;
    $scope.retailer_types = wretailerService.retailer_types;
    $scope.months         = retailerUtils.months();
    $scope.select         = {phone:undefined};

    var dialog = diabloUtilsService;
    var now    = $.now();

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
    
    $scope.right = {
	reset_password        :retailerUtils.authen(user.type, user.right, 'reset_password'),
	delete_retailer       :retailerUtils.authen(user.type, user.right, 'delete_retailer'),
	update_retailer_score :retailerUtils.authen(user.type, user.right, 'update_score'),
	export_retailer       :retailerUtils.authen(user.type, user.right, 'export_retailer'),
	query_balance         :retailerUtils.authen(user.type, user.right, 'query_balance'),
	update_phone          :retailerUtils.authen(user.type, user.right, 'update_phone'),
	set_withdraw          :retailerUtils.authen(user.type, user.right, 'set_withdraw'),
	master                :rightAuthen.authen_master(user.type) 
    };
    // console.log($scope.right);

    /*
     * filter
     */
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("month", $scope.months);
    diabloFilter.add_field("region", $scope.regions);
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

    $scope.do_search = function(page){
    	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    console.log($scope.select.phone);
	    if (angular.isDefined($scope.select.phone) && angular.isObject($scope.select.phone)){
		search.mobile = $scope.select.phone.mobile;
		search.py = $scope.select.phone.py;
	    } 

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
	// $scope.sort.sort = $scope.sort.sort === 0 ? 1 : 0; 
	$scope.do_search($scope.current_page);
    }

    $scope.do_search($scope.current_page);

    
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
		   tel_mobile:   diabloPattern.tel_mobile,
		   decimal_2:    diabloPattern.decimal_2,
		   number:       diabloPattern.number,
		   comment:      diabloPattern.comment,
		   password:     diabloPattern.num_passwd,
		   id_card:      diabloPattern.id_card}; 
    
    $scope.charge = function(retailer){
	console.log($scope.charges); 

	var callback = function(params){
	    console.log(params);

	    var promotion       = params.retailer.select_charge;
	    var charge_balance  = retailerUtils.to_integer(params.charge)
		+ retailerUtils.to_integer(params.cash)
		+ retailerUtils.to_integer(params.wxin);
	    
	    var send_balance = function(){
		if (0 === promotion.rule_id) {
		    if (promotion.charge !== 0 && charge_balance >= promotion.charge){
			return Math.floor(charge_balance / promotion.charge) * promotion.balance;
		    } else {
			return 0;
		    }
		}
		else if (1 === promotion.rule_id) {
		    return Math.floor(charge_balance / promotion.xtime);
		}
	    }();

	    wretailerService.new_recharge({
		retailer:       retailer.id, 
		shop:           params.retailer.select_shop.id,
		employee:       params.retailer.select_employee.id, 
		charge_balance: charge_balance,
		cash:           retailerUtils.to_integer(params.charge),
		card:           retailerUtils.to_integer(params.card),
		wxin:           retailerUtils.to_integer(params.wxin),
		send_balance:   send_balance,
		charge:         promotion.id,
		comment:        params.comment
	    }).then(function(result){
		console.log(result); 
		if (result.ecode == 0){
		    retailer.balance += charge_balance + send_balance;
		    dialog.response_with_callback(
			true,
			"会员充值",
			"会员 [" + retailer.name + "] 充分值成功，"
			    + "帐户余额 [" + retailer.balance.toString() + " ]！！"
			    + function(){
				if (result.sms_code !== 0)
				    return "发送短消息失败："
				    + wretailerService.error[result.sms_code];
				else return ""; 
			    }(),
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

	var get_charge = function(charge_id) {
	    // console.log(charges);
	    for (var i=0, l=$scope.charges.length; i<l; i++){
		if (charge_id === $scope.charges[i].id){
		    return $scope.charges[i];
		}
	    } 
	    return undefined;
	};
	
	dialog.edit_with_modal(
	    "wretailer-charge.html",
	    undefined,
	    callback,
	    $scope,
	    {retailer:  {
		name: retailer.name,
		balance:retailer.balance,
		shops: $scope.shops,
		select_shop: $scope.shops[0],
		employees: $scope.employees,
		select_employee: $scope.employees[0],
		// charges: $scope.charges,
		// select_charge:get_charge($scope.shops[0].charge_id)
	    },
	     card: 0,
	     wxin: 0,
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
		py: diablo_get_modified(diablo_pinyin(params.retailer.name),
					diablo_pinyin(old_retailer.name)),
		id_card: diablo_get_modified(params.retailer.id_card, old_retailer.id_card),
		mobile: diablo_get_modified(params.retailer.mobile, old_retailer.mobile),
		address: diablo_get_modified(params.retailer.address, old_retailer.address),
		shop: params.retailer.edit_shop ? params.retailer.shop.id : undefined,
		type: diablo_get_modified(params.retailer.type, old_retailer.type),
		password:diablo_get_modified(params.retailer.password, old_retailer.password),
		birth:diablo_get_modified(params.retailer.birth.getTime(),
					  old_retailer.birth.getTime()),
		balance: diablo_get_modified(params.retailer.balance, old_retailer.balance)
	    };
	    
	    console.log(update_retailer); 
	    update_retailer.id = params.retailer.id;
	    // update_retailer.obalance = old_retailer.balance;
	    // console.log(update_retailer);
	    
	    wretailerService.update_retailer(update_retailer).then(function(result){
    		console.log(result);
    		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "会员编辑",
			"恭喜你，会员 ["
			    + old_retailer.name + "] 信息修改成功！！",
			$scope, function(){
			    $scope.do_search($scope.current_page);
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
	
	dialog.edit_with_modal(
	    "update-wretailer.html", undefined, callback, $scope,
	    {retailer:    old_retailer,
	     types:       function(){
		 if ($scope.right.master)
		     return $scope.retailer_types;
		 else
		     return $scope.retailer_types.filter(function(t){
			 return t.id !== diablo_system_retailer;
		     });
	     }(),
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
	wretailerService.export_w_retailer().then(function(state){
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

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.right = {master: rightAuthen.authen_master(user.type)};
    
    var now = $.now(); 
    $scope.time = diabloFilter.default_time(now, now);
    
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
    $scope, diabloFilter, diabloPattern, diabloUtilsService,
    wretailerService, user){

    var dialog = diabloUtilsService;

    $scope.shops = user.sortShops;
    $scope.pattern = {comment: diabloPattern.comment};
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;
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
			t.shop = diablo_get_object(t.shop_id, $scope.shops);
		    });

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
};

define (["wretailerApp"], function(app){
    app.controller("wretailerNewCtrl", wretailerNewCtrlProvide);
    app.controller("wretailerDetailCtrl", wretailerDetailCtrlProvide);
    app.controller("wretailerChargeDetailCtrl", wretailerChargeDetailCtrlProvide);
    app.controller("wretailerTicketDetailCtrl", wretailerTicketDetailCtrlProvide);
});

