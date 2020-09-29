'use strict'

function wretailerRechargeNewCtrlProvide(
    $scope, $routeParams, dateFilter, diabloPattern, diabloNormalFilter,
    diabloUtilsService, wretailerService){
    $scope.pattern = {
	name         :diabloPattern.ch_en_num_beside_underline_bars,
	number       :diabloPattern.number,
	limit_draw   :diabloPattern.integer_except_zero,
	remark       :diabloPattern.comment
    };

    $scope.action = retailerUtils.to_integer($routeParams.action); 
    $scope.label = $scope.action === 1 ? "提现" : "充值";
    $scope.rules = wretailerService.charge_rules;
    $scope.times = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15];
    $scope.yes_no = retailerUtils.yes_no();

    var dialog = diabloUtilsService; 
    var now    = $.now();

    $scope.promotion = {	
	rule       :$scope.rules[0],
	time       :$scope.times[2],

	ishop      :$scope.yes_no[0], 
	ibalance   :diablo_invalid,
	mbalance   :diablo_invalid,
	icount     :diablo_invalid,
	
	sdate      :now,
	edate      :now + diablo_day_millisecond * 90
    };
    console.log($scope.promotion);

    
    $scope.new_promotion = function(){
	console.log($scope.promotion);

	var isChargeCard = $scope.promotion.rule.id ===0 || $scope.promotion.rule.id ===1;
	
	wretailerService.new_charge_promotion(
	    {name:    $scope.promotion.name,
	     rule:    $scope.promotion.rule.id,
	     xtime:   $scope.promotion.rule.id !==1 ? undefined : $scope.promotion.time,
	     xdiscount: $scope.promotion.rule.id !==1 ? undefined : $scope.promotion.xdiscount,
	     ctime:   $scope.promotion.rule.id !==2 ? undefined : $scope.promotion.ctime,
	     charge:  $scope.promotion.charge,
	     balance: retailerUtils.to_integer($scope.promotion.balance),

	     ishop:    isChargeCard ? retailerUtils.to_integer($scope.promotion.ishop.id) : undefined,
	     ibalance: isChargeCard ? retailerUtils.to_integer($scope.promotion.ibalance) : undefined,
	     mbalance: isChargeCard ? retailerUtils.to_integer($scope.promotion.mbalance) : undefined,
	     icount:   isChargeCard ? retailerUtils.to_integer($scope.promotion.icount)   : undefined,
	     
	     
	     type:    $scope.action, 
	     sdate:   dateFilter($scope.promotion.sdate, "yyyy-MM-dd"),
	     edate:   dateFilter($scope.promotion.edate, "yyyy-MM-dd"), 
	     remark:  diablo_set_string($scope.promotion.remark)}
	).then(function(result){
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "新增" + $scope.label + "方案",
		    $scope.label + "方案新增成功！！",
		    undefined,
		    function(){
			diabloNormalFilter.reset_charge();
			$scope.cancel();
		    });
	    } else {
		dialog.response(
		    false,
		    "新增" + $scope.label + "方案",
		    $scope.label + "方案新增失败：" + wretailerService.error[result.ecode],
		    undefined);
	    }
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/promotion/recharge_detail");
    }
};


function wretailerRechargeDetailCtrlProvide(
    $scope, diabloPattern, diabloNormalFilter, diabloUtilsService, wretailerService, user
){

    var dialog = diabloUtilsService;
    $scope.actions = {recharge:true, draw:false}
    
    wretailerService.list_charge_promotion().then(function(result){
	console.log(result);
	// $scope.promotions = result.filter(function(r){return r.deleted!==1});
	
	$scope.promotions = result.filter(function(r){return r.type===0});
	$scope.draws = result.filter(function(r){return r.type===1});

	angular.forEach($scope.promotions, function(p){
	    p.rule = diablo_get_object(p.rule_id, wretailerService.charge_rules); 
	});
	
	diablo_order($scope.promotions);
	diablo_order($scope.draws);
    });

    $scope.right = {
	new_score: rightAuthen.authen_master(user.type)
    };
    
    $scope.new_recharge = function(){
	if ($scope.actions.recharge)
	    diablo_goto_page("#/promotion/recharge_new/0");
	else if ($scope.actions.draw)
	    diablo_goto_page("#/promotion/recharge_new/1");
    }

    $scope.update_charge = function(p){
	var title = $scope.actions.recharge ? "充值" : "提现";
	dialog.response(false, "修改" + title + "方案", "暂不支持此操作！！");
    };

    $scope.delete_charge = function(p){
	var title = $scope.actions.recharge ? "充值" : "提现";
	
	var callback = function() {
	    wretailerService.delete_charge_promotion(p.id).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"删除" + title + "方案",
			title + "方案删除成功！！",
			undefined,
			function() {
			    diabloNormalFilter.reset_charge();
			    p.deleted=diablo_has_deleted;
			});
		} else {
		    dialog.response(
			false,
			"删除" + title + "方案",
			title + "方案删除失败！！" + wretailerService.error[result.ecode],
			undefined);
		}
	    });
	};
	
	dialog.request(
	    "删除" + title + "方案",
	    "确认要删除该" + title + "方案吗？",
	    callback,
	    undefined,
	    undefined
	);
    };
};


function wretailerScoreNewCtrlProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService, wretailerService){
    
    $scope.pattern = {
	name      :diabloPattern.ch_en_num_beside_underline_bars,
	discount  :diabloPattern.discount,
	number    :diabloPattern.number,
	remark    :diabloPattern.comment
    };

    $scope.rules = wretailerService.score_rules;

    var now = $.now();
    $scope.promotion = {
	rule       :$scope.rules[0], 
	sdate      :now,
	edate      :now +  diablo_day_millisecond * 90
    };

    var dialog = diabloUtilsService;

    $scope.new_promotion = function(){
	console.log($scope.promotion);

	if (angular.isUndefined($scope.promotion.sdate)
	    || null === $scope.promotion.sdate){
	    $scope.promotion.sdate = now;
	}

	if (angular.isUndefined($scope.promotion.edate)
	    || null === $scope.promotion.edate){
	    $scope.promotion.edate = now +  diablo_day_millisecond * 90;
	}

	var p = {
	    // shop:     $scope.promotion.shop.id,
	    name:     $scope.promotion.name,
	    rule:     $scope.promotion.rule.id,
	    balance:  $scope.promotion.balance,
	    score:    $scope.promotion.score,
	    sdate:    dateFilter($scope.promotion.sdate, "yyyy-MM-dd"),
	    edate:    dateFilter($scope.promotion.edate, "yyyy-MM-dd"),
	    remark:   diablo_set_string($scope.promotion.remark)
	};

	wretailerService.new_score_promotion(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true, "新增积分方案", "新增积分方案成功！！", undefined,
		    function(){$scope.cancel()});
	    } else {
		dialog.response(
		    false,
		    "新增积分方案",
		    "新增积分方案失败："
			+ wretailerService.error[result.ecode],
		    undefined);
	    }
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/promotion/score_detail");
    }
    
};

function wretailerScoreDetailCtrlProvide(
    $scope, diabloPattern, diabloUtilsService, wretailerService, user){

    $scope.rules = wretailerService.score_rules;
    $scope.promotion = {balance2score: [], score2balance: []};
    $scope.select = {balance2score: false, score2balance: false};

    $scope.right = {
	new_score: rightAuthen.authen_master(user.type)
    };

    $scope.refresh = function(){
	wretailerService.list_score_promotion().then(function(result){
    	    console.log(result);

	    $scope.promotion.balance2score = [];
	    $scope.promotion.score2balance = [];
	    angular.forEach(result, function(s){
		if (s.type_id === $scope.rules[0].id){
		    s.type = $scope.rules[0];
		    $scope.promotion.balance2score.push(s);
		} else if (s.type_id === $scope.rules[1].id){
		    s.type = $scope.rules[1];
		    $scope.promotion.score2balance.push(s);
		}
	    });
	    
    	    diablo_order($scope.promotion.balance2score);
	    diablo_order($scope.promotion.score2balance);
	})
    };
    
    

    var dialog = diabloUtilsService;
    $scope.new_score = function(){
	diablo_goto_page("#/promotion/score_new");
    }

    $scope.update_score = function(old_score){
	dialog.response(false, "修改积分方案", "暂不支持此操作！！");
    };

    $scope.delete_score = function(old_score){
	dialog.response(false, "删除积分方案", "暂不支持此操作！！");
    };
};


function wretailerDetailPrintCtrlProvide(
    $scope, $routeParams, diabloUtilsService, wretailerService, user, base){
    console.log($routeParams); 
    
    var LODOP;
    var print_access = retailerUtils.print_num(user.loginShop, base);
    if (needCLodop()) loadCLodop(print_access.protocal); 
    var dialog = diabloUtilsService;

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);

    var search = angular.fromJson($routeParams.search);
    var sort   = angular.fromJson($routeParams.sort)
    wretailerService.print_w_retailer(sort, search).then(function(result) {
    	console.log(result);
	if (result.ecode === 0) {
	    $scope.retailers = result.data;
	    var order_id = 1;
	    angular.forEach($scope.retailers, function(r){
		r.order_id  = order_id;
		r.type      = diablo_get_object(r.type_id, wretailerService.retailer_types);
		r.olevel    = diablo_retailer_levels[r.level];
		r.birthday  = r.birth.substr(5,8);
		order_id++
	    });
	    
	} else {
	    dialog.response(
		false,
		"会员详情打印",
		"会员详情打印失败：会员详情失败，请核对后再打印！！")
	}
    });

    // var css = "<style>table { border-splice:0; border-collapse:collapse }</style>"
    // var strBodyStyle="<style>table,td { border: 1 solid #000000;border-collapse:collapse }</style>"; 
    var strBodyStyle="<style>"
	+ ".table-response {min-height: .01%; overflow-x:auto;}"
	+ "table {border-spacing:0; border-collapse:collapse; width:100%}"
	+ "td,th {padding:0; border:1 solid #000000; text-align:center;}"
	+ ".table-bordered {border:1 solid #000000;}" 
	+ "</style>";
    $scope.print = function() {
	if (angular.isUndefined(LODOP)) {
	    LODOP = getLodop();
	}

	if (LODOP.CVERSION) {
	    LODOP.PRINT_INIT("task_print_retailer");
	    LODOP.SET_PRINTER_INDEX(retailerUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	    LODOP.ADD_PRINT_HTM(
		"5%", "5%",  "90%", "BottomMargin:15mm",
		strBodyStyle + "<body>" + document.getElementById("retailer_detail").innerHTML + "</body>");
	    LODOP.PREVIEW(); 
	}
    };

    $scope.go_back = function() {
	diablo_goto_page("#/wretailer_detaill");
    };
    
};

function wretailerGiftCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService,
    filterEmployee, filterShop, user){
    var dialog = diabloUtilsService;
    var now = $.now();
    
    $scope.shops = user.sortShops;
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenRetailerRight();
    console.log($scope.right);

    $scope.pattern = {
	code:  diabloPattern.style_number,
	name:  diabloPattern.ch_en_num,
	score: diabloPattern.number,
	price: diabloPattern.decimal_2,
	count: diabloPattern.positive_num,
	comment:diabloPattern.comment
    };

    $scope.rules = wretailerService.gift_rules;

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
	    wretailerService.filter_gift($scope.match, search, page, $scope.items_perpage).then(function(result){
		console.log(result);
		$scope.gifts = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
		    } 
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.gifts);
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

    $scope.new_gift = function() {
	var callback = function(params) {
	    console.log(params);
	    wretailerService.add_gift(
		{code:diablo_trim(params.code),
		 name:diablo_trim(params.name),
		 org_price:params.org_price,
		 tag_price:params.tag_price,
		 count:params.count,
		 rule:params.rule.id,
		 score:retailerUtils.to_integer(params.score)}
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "新增礼品", "新增会员礼品成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("新增礼品", result.ecode); 
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-gift.html",
	    undefined,
	    callback,
	    undefined,
	    {mode: 0,
	     rule: $scope.rules[0],
	     rules:$scope.rules,
	     pattern:$scope.pattern,
	     score: 0,
	     show_orgprice: $scope.right.show_orgprice}); 
    };

    $scope.update_gift = function(g) {
	console.log(g);
	var callback = function(params) {
	    console.log(params);
	    wretailerService.update_gift(
		{id: g.id,
		 name: diablo_get_modified(diablo_trim(params.name), g.name),
		 org_price: diablo_get_modified(params.org_price, g.org_price),
		 tag_price: diablo_get_modified(params.tag_price, g.tag_price),
		 count: diablo_get_modified(params.count, g.total),
		 rule: diablo_get_modified(params.rule.id, g.rule_id),
		 score: diablo_get_modified(retailerUtils.to_integer(params.score), g.score)}
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true, "礼品编辑", "会员礼品编辑成功！！", undefined, $scope.refresh);
		} else {
		    dialog.set_error("礼品编辑", result.ecode); 
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-gift.html",
	    undefined,
	    callback,
	    undefined,
	    {mode: 1,
	     code: g.code,
	     name: g.name,
	     org_price: g.org_price,
	     tag_price: g.tag_price,
	     count: g.total,
	     rule: diablo_get_object(g.rule_id, $scope.rules),
	     rules:$scope.rules,
	     pattern:$scope.pattern,
	     score: g.score,
	     show_orgprice: $scope.right.show_orgprice}); 
    }; 

    $scope.get_employee = function(shop_id) {
	var validEmployees = filterEmployee.filter(function(e) {
	    return e.shop === shop_id && e.state === 0;
	});

	return validEmployees.length === 0 ? filterEmployee : validEmployees;
    };

    $scope.match_retailer_phone = function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter);
    };

    $scope.exchange_gift = function(g) {
	var callback = function(params) {
	    console.log(params);
	    var title = "礼品领取"; 
	    if ((g.rule_id === diablo_gift_month_and_score
	    	 || g.rule_id === diablo_gift_score_only
		 || g.rule_id === diablo_gift_year_and_score)
	    	&& params.score > params.retailer.score) {
	    	    dialog.set_error(title, 2140); 
	    } else {
		wretailerService.exchange_gift(
		    {gift: g.id,
		     rule: g.rule_id,
		     retailer:params.retailer.id,
		     shop: params.select_shop.id,
		     employee: params.employee.id,
		     score: params.score,
		     comment: params.comment}
		).then(function(result) {
		    if (result.ecode === 0) {
			dialog.success_response_with_callback(
			    title, title + "成功！！", $scope.refresh);
		    } else {
			dialog.set_error(title, result.ecode);
		    }
		});
	    }
	};

	var default_shop = $scope.shops[0];
	dialog.edit_with_modal(
	    "exchange-gift.html",
	    undefined,
	    callback,
	    undefined,
	    {code:  g.code,
	     name:  g.name,
	     rule_name: $scope.rules[g.rule_id].name,
	     rule_id: g.rule_id,
	     score: g.score,
	     shops: $scope.shops,
	     select_shop: default_shop,
	     employees: $scope.get_employee(default_shop.id),
	     get_employee: $scope.get_employee,
	     match_retailer_phone: $scope.match_retailer_phone,
	     pattern:$scope.pattern}); 
    }

    $scope.delete_gift = function() {
	dialog.response(false, "删除礼品", "系统暂不支持此操作！！", undefined);
    };
};


function wretailerGiftExchangeCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wretailerService,
    filterEmployee, filterShop, user){
    var dialog = diabloUtilsService;
    var now = $.now();
    
    $scope.shops = user.sortShops;
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenRetailerRight(); 

    $scope.rules = wretailerService.gift_rules;
    $scope.exchange_modes = wretailerService.gift_exchange_modes;
    
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.filters = []; 
    diabloFilter.reset_field(); 
    diabloFilter.add_field("retailer", function(viewValue){
	return retailerUtils.match_retailer_phone(viewValue, diabloFilter);
    });

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = retailerUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wretailerService.filter_gift_exchange(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		$scope.es = angular.copy(result.data); 
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
		    }

		    angular.forEach($scope.es, function(e) {
			e.employee = diablo_get_object(e.employee_id, filterEmployee);
			e.shop = diablo_get_object(e.shop_id, filterShop);
		    });
		    
		    diablo_order_page(page, $scope.items_perpage, $scope.es);
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
}



define (["wretailerApp"], function(app){
    app.controller("wretailerRechargeNewCtrl", wretailerRechargeNewCtrlProvide);
    app.controller("wretailerRechargeDetailCtrl", wretailerRechargeDetailCtrlProvide);
    app.controller("wretailerScoreNewCtrl", wretailerScoreNewCtrlProvide);
    app.controller("wretailerScoreDetailCtrl", wretailerScoreDetailCtrlProvide);
    app.controller("wretailerDetailPrintCtrl", wretailerDetailPrintCtrlProvide);
    app.controller("wretailerGiftCtrl", wretailerGiftCtrlProvide);
    app.controller("wretailerGiftExchangeCtrl", wretailerGiftExchangeCtrlProvide);
});
