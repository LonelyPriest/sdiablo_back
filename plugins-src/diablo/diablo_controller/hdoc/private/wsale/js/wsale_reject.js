function wsaleRejectCtrlProvide(
    $scope, $q, dateFilter, diabloUtilsService, diabloPromise,
    diabloPattern, diabloFilter, diabloNormalFilter, wsaleService,
    user, filterPromotion, filterScore, filterSysRetailer, filterBrand,
    filterType, filterEmployee, filterSizeGroup, filterColor, filterLevel, base){
    // console.log($scope);
    // console.log(user); 
    $scope.shops         = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds       = user.shopIds;
    
    $scope.promotions    = filterPromotion;
    $scope.scores        = filterScore;
    $scope.sysRetailers  = filterSysRetailer; 
    $scope.brands        = filterBrand;
    $scope.types         = filterType;
    // $scope.retailers     = filterRetailer;
    $scope.employees     = [];
    $scope.size_groups   = filterSizeGroup;
    $scope.colors        = filterColor;
    $scope.levels        = filterLevel;
    $scope.base_settings = base; 
    
    // $scope.repoes  = user.sortRepoes; 
    $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season;
    $scope.f_add   = diablo_float_add;
    $scope.f_sub   = diablo_float_sub;
    $scope.f_mul   = diablo_float_mul;    
    
    $scope.hidden  = {travel:true};
    $scope.pattern = {passwd: diabloPattern.num_passwd};
    
    $scope.go_back = function(){diablo_goto_page("#/new_wsale_detail")};

    $scope.inventories = [];
    $scope.show_promotions = [];
    $scope.setting = {};
    $scope.select = {
	datetime: $.now(),
	withdraw: 0,
	total: 0,
	ticket: 0
    };

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();
    
    // $scope.right = {
    // 	master:rightAuthen.authen_master(user.type)
    // };

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.shop_right = authen.authenSaleRight();

    $scope.has_select_rsn = false;
    
    // match rsn
    
    // var time = diabloFilter.default_time(); 
    // wsaleService.get_wsale_rsn(
    // 	{shop       :$scope.shopIds,
    // 	 start_time :diablo_filter_time(time.start_time, 0, dateFilter),
    // 	 end_time   :diablo_filter_time(time.end_time, 1, dateFilter)}
    // ).then(function(result){
    // 	$scope.rsns = result.map(function(result){
    // 	    return result.rsn;
    // 	});
    // });



    var dialog = diabloUtilsService; 
    var now    = $.now();

    var shopId = $scope.shopIds.length > 0 ? $scope.shopIds[0] : diablo_default_setting;
    var qtime_start = wsaleUtils.start_time(shopId, base, now, dateFilter);
    // console.log(qtime_start);
    var qtime = diabloFilter.default_time(qtime_start, now);
    $scope.match_rsn = function(viewValue){
	return diabloFilter.match_wsale_rsn_of_new(diablo_rsn_new, viewValue, $scope.shopIds, qtime);
    };
    
    $scope.select_rsn = function(item, model, label){
	// console.log($scope.has_select_rsn);
	// if ($scope.has_select_rsn) return;
	wsaleService.get_w_sale_new(item).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var base = result.sale;
		diabloFilter.get_wretailer_batch([base.retailer_id]).then(function(retailers){
		    console.log(retailers);
		    $scope.has_select_rsn = true; 
		    var sells = result.detail; 
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
		    
		    console.log(wsale); 
		    $scope.show_promotions = wsale.show_promotions; 
		    // $scope.old_select = wsale.select;
		    $scope.select = angular.extend($scope.select, wsale.select);
		    $scope.select.has_pay = $scope.select.cash
			+ $scope.select.card + $scope.select.wxin
			+ $scope.select.withdraw + $scope.select.ticket;
		    $scope.select.left_balance = $scope.select.surplus; 
		    console.log($scope.select);

		    // setting
		    var shopId = $scope.select.shop.id;
		    var settings = $scope.base_settings;
		    $scope.setting.no_vip = wsaleUtils.no_vip(shopId, settings);
		    $scope.setting.comments = wsaleUtils.comment(shopId, settings);
		    $scope.setting.p_mode = wsaleUtils.print_mode(shopId, settings);
		    $scope.setting.round = wsaleUtils.round(shopId, settings);
		    // $scope.setting.cakeMode = wsaleUtils.cake_mode(shopId, settings);
		    $scope.setting.draw_score = wsaleUtils.draw_score(shopId, settings);
		    $scope.setting.vip_mode = wsaleUtils.vip_mode(shopId, settings);
		    
		    var sale_mode = wsaleUtils.sale_mode(shopId, settings);
		    // $scope.setting.print_perform = wsaleUtils.to_integer(sale_mode.charAt(3));
		    
		    $scope.setting.hide_pwd      = wsaleUtils.to_integer(sale_mode.charAt(9)); 
		    $scope.setting.print_access = wsaleUtils.print_num(shopId, settings);

		    $scope.setting.score_discount = wsaleUtils.to_integer(sale_mode.charAt(16)) * 10
			+ wsaleUtils.to_integer(sale_mode.charAt(17));

		    $scope.print_setting = {
			print_discount: wsaleUtils.yes_default(sale_mode.charAt(15)),
			print_perform:  wsaleUtils.to_integer(sale_mode.charAt(3)),
			cake_mode:      wsaleUtils.cake_mode(shopId, settings),
			comments:       wsaleUtils.comment(shopId, settings),
			head_seperater: wsaleUtils.to_integer(sale_mode.charAt(23)),
			print_score:    wsaleUtils.yes_default(sale_mode.charAt(26))
		    };
		    
		    // console.log($scope.setting);

		    $scope.employees = wsaleUtils.get_login_employee(
			shopId,
			base.employ_id,
			filterEmployee).filter;
		    
		    if (diablo_frontend === $scope.setting.p_mode) {
			if (needCLodop()) loadCLodop($scope.setting.print_access.protocal); 
		    }
		    
		    $scope.old_inventories = wsale.details;
		    $scope.inventories = angular.copy(wsale.details);
		    
		    // $scope.inventories.unshift({$edit:false, $new:true});

		    console.log($scope.old_inventories);
		    console.log($scope.inventories);

		    //
		    $scope.has_withdrawed = false;
		    $scope.re_calculate();
		    
		    $scope.hidden.travel = false;
		}); 
	    };
	});
    }

    
    $scope.disable_refresh = function(){
	return $scope.has_saved ? false:true;
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.show_promotions = [];
	datetime: $.now();
	$scope.hidden.travel   = true;
	$scope.has_saved       = false;
	$scope.has_select_rsn  = false;
	$scope.has_withdrawed  = false;
	$scope.select = {datetime: $.now()}; 
    }; 
    
    // employees
    if ($scope.employees.length !== 0){
    	$scope.select.employee = $scope.employees[0];
    };
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    }; 

    /*
     * withdraw
     */ 
    $scope.disable_draw_back = function(){
	return angular.isUndefined($scope.select.retailer)
	    || $scope.select.retailer.type_id !== diablo_charge_retailer
	    || $scope.select.withdraw === 0
	    || $scope.select.total === 0;
    };

    $scope.withdraw = function(){
	var callback = function(params){
	    console.log(params);
	    diabloFilter.check_retailer_password(
		params.retailer.id, params.retailer.password, params.hide_pwd ? diablo_no : diablo_yes)
		.then(function(result){
		    console.log(result); 
		    if (result.ecode === 0){
			// $scope.select.surplus  = params.retailer.balance 
			// $scope.select.withdraw = params.retailer.withdraw;
			$scope.has_withdrawed  = true;
			$scope.re_calculate();
		    } else {
			var ERROR = require("diablo-error");
			diabloUtilsService.response(
			    false,
			    "会员退款",
			    ERROR[result.ecode],
			    undefined)
		    }
		}); 
	};

	diabloUtilsService.edit_with_modal(
	    "new-withdraw.html",
	    undefined,
	    callback,
	    undefined,
	    {retailer:
	     {id        :$scope.select.retailer.id,
	      name      :$scope.select.retailer.name,
	      withdraw  :$scope.select.withdraw,
	      pattern   :$scope.pattern.passwd,
	     },
	     hide_pwd   :$scope.setting.hide_pwd
	    }
	);
    };

    $scope.disable_ticket_back = function() {
	return angular.isUndefined($scope.select.retailer)
	    || $scope.select.retailer.type_id === diablo_system_retailer
	    || $scope.select.tcustom === diablo_score_ticket
	    || $scope.select.ticket === 0
	    || $scope.select.total === 0;
    };
    
    $scope.ticket_back = function() {
	diabloFilter.get_ticket_by_sale(
	    $scope.select.rsn, diablo_custom_ticket
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var callback = function(params) {
		    console.log(params);
		    $scope.select.ticket = 0;
		    $scope.select.tbatch = [];
		    for (var j=0, k=params.ptickets.length; j<k; j++) {
			if (angular.isDefined(params.ptickets[j].select) && params.ptickets[j].select){
			    select_ticket = params.ptickets[j];
			    $scope.select.tbatch.push(select_ticket.batch); 
			    $scope.select.ticket += select_ticket.balance;
			    // break;
			}
		    }   
		};
		
		var promotionTickets = result.data.map(function(t) {
		    return {batch:t.batch, balance:t.balance, select:true}
		});
		
    		diabloUtilsService.edit_with_modal(
    		    "ticket-back.html",
    		    undefined,
    		    callback,
    		    undefined,
    		    {ptickets: promotionTickets, 
		     check_valid: function(ptickets) {
			 var autoTicket = false;
			 for (var j=0, k=ptickets.length; j<k; j++) {
			     if (angular.isDefined(ptickets[j].select) && ptickets[j].select) {
				 autoTicket = true;
				 break;
			     }
			 }
			 return autoTicket;
		     }
		    });
    	    } else {
		dialog.set_error("会员电子卷获取", result.ecode); 
    	    }
	})
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	var invalid = false;
	// save one time only
	if ($scope.has_saved || $scope.select.total === 0)
	    return invalid = true;

	if ($scope.select.retailer.type_id===1 && $scope.select.withdraw!==0 && !$scope.has_withdrawed)
	    invalid = true; 
	
	return invalid; 
    }; 

    $scope.print_backend = function(result, im_print){
	var print = function(status){
	    var messsage = "";
	    if (status.pcode == 0){
		messsage = "单号："
		    + result.rsn + "，打印成功，请等待服务器打印！！";
	    } else {
		if (status.pinfo.length === 0){
		    messsage += wsaleService.error[status.pcode]
		} else {
		    angular.forEach(status.pinfo, function(p){
			messsage += "[" + p.device + "] "
			    + wsaleService.error[p.ecode]
		    })
		};
		messsage = "单号："
		    + result.rsn + "，打印失败：" + messsage;
	    }

	    return messsage;
	};

	var dialog = diabloUtilsService; 
	var show_dialog = function(title, message){
	    dialog.response(true, title, message, undefined)
	};
	
	var ok_print = function(){
	    wsaleService.print_w_sale(result.rsn).then(function(result){
		var show_message = "退货单打印" + print(result);
		show_dialog("销售退货", show_message); 
	    })
	};

	var sms_message = "";
	if (angular.isDefined(result.sms_code) && result.sms_code !== 0){
	    var ERROR = require("diablo-error");
	    sms_message += "，短消息发送失败：" + ERROR[result.sms_code] + "，";
	}
	
	dialog.request(
	    "销售退货", "退货成功，" + sms_message + "是否打印退货单？",
	    ok_print, undefined, $scope);
    };

    var LODOP;
    $scope.print_front = function(result, im_print){
	var dialog = diabloUtilsService; 
	var ok_print = function(){
	    var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss"); 
	    if (angular.isUndefined(LODOP)) LODOP = getLodop();

	    // console.log($scope.select);
	    
	    if (angular.isDefined(LODOP)){
		var top = wsalePrint.gen_head(
		    LODOP,
		    $scope.select.shop.name,
		    result.rsn,
		    $scope.select.employee.name,
		    $scope.select.retailer.name, 
		    dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
		    wsaleService.direct.wreject,
		    $scope.print_setting);

		var isRound = $scope.setting.round; 
		// var cakeMode = $scope.setting.cakeMode;
		// console.log($scope.setting);
		
		top = wsalePrint.gen_body(
		    LODOP,
		    top,
		    $scope.select,
		    $scope.inventories.filter(function(r){return !r.$new && r.select}),
		    isRound,
		    $scope.print_setting); 
		
		top = wsalePrint.gen_stastic(
		    LODOP,
		    top,
		    wsaleService.direct.wreject,
		    $scope.select,
		    wsaleUtils.isVip(
			$scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
		    $scope.print_setting);
		
		wsalePrint.gen_foot(
		    LODOP,
		    top,
		    pdate,
		    $scope.select.shop.addr,
		    $scope.print_setting);
		wsalePrint.start_print(LODOP);
	    };
	};

	var sms_message = "";
	if (angular.isDefined(result.sms_code) && result.sms_code !== 0){
	    var ERROR = require("diablo-error");
	    sms_message += "，短消息发送失败：" + ERROR[result.sms_code] + "，";
	}
	
	dialog.request(
	    "销售退货",
	    "退货成功，" + sms_message + "是否打印销售单？", ok_print, undefined, undefined);
    };
    
    $scope.save_inventory = function(){
	$scope.has_saved = true;
	console.log($scope.inventories);
	
	var get_sales = function(amounts){
	    var sale_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		if (angular.isDefined(amounts[i].sell_count) && amounts[i].sell_count){
		    sale_amounts.push({
			cid:  amounts[i].cid,
			size: amounts[i].size, 
			reject_count: parseInt(amounts[i].sell_count),
			direct: wsaleService.direct.wreject}); 
		}
	    }

	    return sale_amounts;
	};
	
	var added  = [];
	var rtotal = 0;
	// var nscore = 0;
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // if (!add.select || add.total < 0) continue;
	    if (!add.select) continue;
	    rtotal += add.reject;
	    added.push({
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand.name,
		type        : add.type_id,
		firm        : add.firm_id,
		sex         : add.sex,
		season      : add.season, 
		year        : add.year,
		entry       : add.entry,

		amounts     : get_sales(add.amounts),
		sell_total  : wsaleUtils.to_integer(add.reject), 
		promotion   : add.pid,
		score       : add.sid, 
		
		org_price   : add.org_price, 
		tag_price   : add.tag_price,
		fdiscount   : add.fdiscount,
		rdiscount   : add.rdiscount,
		fprice      : add.fprice,
		rprice      : add.rprice,
		path        : add.path,

		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free
	    })
	};
	
	console.log(added);
	if (added.length === 0) {
	    dialog.response_with_callback(
		false,
		"销售退货",
		"退货失败：" + wsaleService.error[2697],
		undefined,
		function() {$scope.has_saved = false});
	    return;
	};

	if (rtotal !== $scope.select.rtotal) {
	    dialog.response_with_callback(
		false,
		"销售退货",
		"退货失败：" + wsaleService.error[2712],
		undefined,
		function() {$scope.has_saved = false});
	    return;
	}

	var setv = diablo_set_float; 
	var seti = diablo_set_integer; 
	var e_pay = setv($scope.select.extra_pay); 

	var base = {
	    sale_rsn:      $scope.select.rsn,
	    retailer_id:   $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    balance:       setv($scope.select.surplus),
	    should_pay:    setv($scope.select.rcharge),
	    cash:          setv($scope.select.cash),
	    card:          setv($scope.select.card),
	    wxin:          setv($scope.select.wxin),
	    aliPay:        setv($scope.select.aliPay),
	    ticket:        setv($scope.select.ticket),
	    withdraw:      setv($scope.select.withdraw),
	    verificate:    $scope.select.verificate,
	    g_ticket:      $scope.select.g_ticket,
	    direct:        wsaleService.direct.wreject,
	    total:         seti($scope.select.rtotal),
	    score:         $scope.select.rscore, 
	    tbatch:        $scope.select.tbatch.length === 0 ? undefined : $scope.select.tbatch,
	    tcustom:       $scope.select.tcustom,
	    ticket_score:  $scope.select.ticket_score
	};
	
	var print = {
	    im_print:    false,
	    retailer_id: $scope.select.retailer.id,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    // retailer:    $scope.select.retailer.name
	};

	console.log(base);

	wsaleService.reject_w_sale({
	    inventory:added, base:base, print:print
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		// $scope.select.retailer.balance = $scope.select.left_balance;
		// $scope.select.surplus = $scope.select.left_balance;
		// $scope.select.retailer.score -= $scope.select.score;
		// $scope.select.retailer.score += $scope.select.ticket_score;

		if (diablo_backend === $scope.setting.p_mode){
		    $scope.print_backend(result, false);
		} else {
		    $scope.print_front(result, false); 
		} 
	    } else{
	    	dialog.response_with_callback(
	    	    false,
		    "销售退货",
		    "退货失败："
			+ wsaleService.error[result.ecode]
			+ wsaleUtils.extra_error(result),
		    undefined,
		    function(){$scope.has_saved = false});
	    }
	})
    }; 

    /*
     * add
     */ 
    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    };

    $scope.reset_score = function() {
	if (diablo_no === $scope.setting.draw_score
	    && ( wsaleUtils.to_float($scope.select.withdraw) !== 0
		 || wsaleUtils.to_float($scope.select.ticket) !== 0)
	   ) {
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
	}
    };
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.abs_total  = 0;
	$scope.select.should_pay = 0;
	$scope.select.score      = 0;
	$scope.select.rcharge    = 0;
	$scope.select.rtotal     = 0;
	$scope.select.rscore     = 0;

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
	
	// console.log(calc);
	
	$scope.select.total     = calc.total; 
	$scope.select.abs_total = calc.abs_total;
	$scope.select.should_pay= calc.should_pay;
	$scope.select.score     = calc.score;
	$scope.select.pscores   = calc.pscores; 
	$scope.reset_score();

	var nscore = 0;
	for (var i=0, l=$scope.inventories.length; i<l; i++){
	    var inv = $scope.inventories[i];
	    // console.log(inv);
	    if (!inv.select){
		if (diablo_invalid_index !== inv.sid) {
		    if (diablo_no === $scope.setting.draw_score) {
			for (var j=0, k=$scope.select.pscores; j<k; j++) {
			    if (inv.sid === $scope.select.pscores[i].score.id) {
				$scope.select.pscores[i].money - inv.calc;
			    }
			}
		    } else {
			nscore += wsaleUtils.calc_score_of_money(inv.calc, inv.score); 
		    }
		} 
	    } else {
		// console.log(inv);
		$scope.select.rcharge += inv.calc;
		$scope.select.rtotal += inv.reject;
	    } 
	} 
	$scope.select.rcharge = diablo_round($scope.select.rcharge);
	
	if (diablo_no === $scope.setting.draw_score) {
	    var pay_orders = function() {
	    	if ($scope.select.rcharge >= 0) {
	    	    return wsaleCalc.pay_order_of_reject(
	    		$scope.select.rcharge, [$scope.select.cash,
	    					$scope.select.card,
	    					$scope.select.wxin,
	    					$scope.select.withdraw,
	    					$scope.select.ticket]);
	    	} else {
	    	    return wsaleCalc.pay_order_of_reject(
	    		$scope.select.rcharge, [$scope.select.cash,
	    					$scope.select.card,
	    					$scope.select.wxin,
	    					$scope.select.withdraw,
	    					$scope.select.ticket]); 
	    	} 
	    }();
	    
	    var pay_with_score = pay_orders[0] + pay_orders[1] + pay_orders[2];
	    nscore = wsaleUtils.calc_score_of_pay(pay_with_score, $scope.select.pscores);
	}
	
	// console.log(nscore);
	if (diablo_no === $scope.setting.draw_score) {
	    // if (nscore > $scope.select.score)
	    // 	$scope.select.rscore = $scope.select.score;
	    // else
	    $scope.select.rscore = nscore;
	} else {
	    $scope.select.rscore = $scope.select.score - nscore; 
	}
	// $scope.select.rcharge = diablo_round($scope.select.rcharge);

	if ($scope.has_withdrawed){
	    $scope.select.left_balance = $scope.select.surplus + $scope.select.withdraw; 
	}
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
};

function wsaleEmployeeEvaluationCtrlProvide(
    $scope, diabloFilter, diabloPattern, diabloUtilsService, wsaleService, filterEmployee, user){
    // console.log(filterEmployee);
    var dialog = diabloUtilsService;

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1; 
    $scope.current_page = $scope.default_page;
    $scope.total_items = 0;

    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;

    $scope.filters = []; 
    diabloFilter.reset_field();

    diabloFilter.add_field("employee", filterEmployee);
    diabloFilter.add_field("shop", $scope.shops);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = wsaleUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);

    $scope.do_search = function(page){
	console.log($scope.filters);
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    wsaleService.filter_employee_evaluation(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === $scope.default_page){
			$scope.total_items = result.total;
			$scope.total_balance = result.t_balance;
			$scope.total_cash = result.t_cash;
			$scope.total_card = result.t_card;
			$scope.total_wxin = result.t_wxin;
			$scope.total_draw = result.t_draw;
			$scope.total_ticket = result.t_ticket;
			$scope.total_veri = result.t_veri;
		    }

		    angular.forEach(result.data, function(d) {
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    })

		    diablo_order(result.data, (page - 1) * $scope.items_perpage + 1);
		    $scope.evaluations = result.data;
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

define (["wsaleApp"], function(app){
    app.controller("wsaleRejectCtrl", wsaleRejectCtrlProvide);
    app.controller("wsaleEmployeeEvaluationCtrl", wsaleEmployeeEvaluationCtrlProvide);
});
