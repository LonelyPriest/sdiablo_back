function wsaleRejectCtrlProvide(
    $scope, $q, dateFilter, diabloUtilsService, diabloPromise,
    diabloPattern, diabloFilter, diabloNormalFilter, wsaleService,
    user, filterPromotion, filterScore, filterBrand,
    filterType, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log($scope);
    // console.log(user); 
    $scope.shops         = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds       = user.shopIds;
    
    $scope.promotions    = filterPromotion;
    $scope.scores        = filterScore;
    $scope.brands        = filterBrand;
    $scope.types         = filterType;
    // $scope.retailers     = filterRetailer;
    $scope.employees     = [];
    $scope.size_groups   = filterSizeGroup;
    $scope.colors        = filterColor;
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
    $scope.select = {datetime: $.now()};

    $scope.right = {
	master:rightAuthen.authen_master(user.type)
    };

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
		var base        = result.sale;
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
		    $scope.setting.cakeMode = wsaleUtils.cake_mode(shopId, settings);

		    $scope.employees = wsaleUtils.get_login_employee(
			shopId,
			base.employ_id,
			filterEmployee).filter;
		    
		    if (diablo_frontend === $scope.setting.p_mode) {
			if (needCLodop()) loadCLodop(); 
		    }
		    
		    $scope.old_inventories = wsale.details;
		    $scope.inventories = angular.copy(wsale.details);
		    
		    $scope.inventories.unshift({$edit:false, $new:true});

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
    $scope.disable_withdraw = function(){
	return $scope.has_withdrawed;
    };

    $scope.withdraw = function(){
	var callback = function(params){
	    console.log(params);
	    diabloFilter.check_retailer_password(
		params.retailer.id, params.retailer.password)
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
	      pattern   :$scope.pattern.passwd},
	    }
	);
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	var invalid = false;
	// save one time only
	if ($scope.has_saved || $scope.select.total === 0 || $scope.select.rcharge === 0)
	    return invalid = true;

	if ($scope.select.retailer.type_id===1
	    && $scope.select.withdraw!==0
	    && !$scope.has_withdrawed)
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
		wsalePrint.gen_head(
		    LODOP,
		    $scope.select.shop.name,
		    result.rsn,
		    $scope.select.employee.name,
		    $scope.select.retailer.name, 
		    dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"));

		var isRound = $scope.setting.round; 
		var cakeMode = $scope.setting.cake_mode;
		
		var hLine = wsalePrint.gen_body(
		    LODOP,
		    $scope.inventories.filter(function(r){return !r.$new && r.select}),
		    isRound,
		    cakeMode);
		
		var isVip = $scope.select.retailer.id !== $scope.setting.no_vip ? true : false;
		
		hLine = wsalePrint.gen_stastic(
		    LODOP, hLine, wsaleService.direct.wreject, $scope.select, isVip);
		
		wsalePrint.gen_foot(LODOP, hLine, $scope.setting.comments, pdate, cakeMode);
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
		if (angular.isDefined(amounts[i].sell_count)
		    && amounts[i].sell_count){
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
	var nscore = 0;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    if (!add.select) continue;
	    added.push({
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand.name,
		type        : add.type_id,
		firm        : add.firm_id,
		// sex         : add.sex,
		season      : add.season, 
		year        : add.year,
		entry       : add.entry,

		amounts     : get_sales(add.amounts),
		sell_total  : parseInt(add.reject), 
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

	var setv = diablo_set_float; 
	var seti = diablo_set_integer; 
	var e_pay = setv($scope.select.extra_pay); 

	var base = {
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
	    ticket:        setv($scope.select.ticket),
	    withdraw:      setv($scope.select.withdraw),
	    verificate:    $scope.select.verificate,
	    direct:        wsaleService.direct.wreject,
	    total:         seti($scope.select.rtotal),
	    score:         $scope.select.rscore, 
	    tbatch:        $scope.select.tbatch,
	    ticket_score:  $scope.select.ticket_score
	};
	
	var print = {
	    im_print:    false,
	    retailer_id: $scope.select.retailer.id,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    // retailer:    $scope.select.retailer.name
	};

	console.log(added);
	console.log(base);

	wsaleService.reject_w_sale({
	    inventory:added, base:base, print:print
	}).then(function(result){
	    console.log(result);
	    if (result.ecode == 0){
		$scope.select.retailer.balance = $scope.select.left_balance;
		$scope.select.surplus = $scope.select.left_balance;
		$scope.select.retailer.score -= $scope.select.score;
		$scope.select.retailer.score += $scope.select.ticket_score;

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
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.abs_total  = 0;
	$scope.select.should_pay = 0;
	$scope.select.score      = 0;
	$scope.select.rcharge    = 0;
	$scope.select.rtotal     = 0;
	$scope.select.rscore     = 0;

	var calc = wsaleCalc.calculate(
	    $scope.select.retailer,
	    $scope.select.retailer,
	    $scope.setting.no_vip,
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_reject,
	    $scope.select.verificate);
	
	console.log(calc);
	
	$scope.select.total     = calc.total; 
	$scope.select.abs_total = calc.abs_total;
	$scope.select.should_pay= calc.should_pay;
	$scope.select.score     = calc.score;

	var nscore = 0;
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    var inv = $scope.inventories[i];
	    // console.log(inv);
	    if (!inv.select){
		if (diablo_invalid_index !== inv.sid)
		    nscore += wsaleUtils.calc_score_of_money(inv.calc, inv.score);
	    } else {
		// console.log(inv);
		$scope.select.rcharge += inv.calc;
		$scope.select.rtotal += inv.reject;
	    }
	}

	// console.log(nscore);
	$scope.select.rscore = $scope.select.score - nscore;
	$scope.select.rcharge = diablo_round($scope.select.rcharge);

	if ($scope.has_withdrawed){
	    $scope.select.left_balance =
		$scope.select.surplus + $scope.select.withdraw; 
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

define (["wsaleApp"], function(app){
    app.controller("wsaleRejectCtrl", wsaleRejectCtrlProvide);
});
