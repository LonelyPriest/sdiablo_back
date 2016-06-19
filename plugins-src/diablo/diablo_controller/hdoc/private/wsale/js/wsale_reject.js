wsaleApp.controller("wsaleRejectCtrl", function(
    $scope, $q, dateFilter, diabloUtilsService, diabloPromise,
    diabloPattern, diabloFilter, diabloNormalFilter, wgoodService,
    purchaserService, wsaleService, wretailerService,
    user, filterPromotion, filterScore, filterBrand,
    filterType, filterRetailer,
    filterEmployee, filterSizeGroup, filterColor, base){
    // console.log(base);
    // console.log(user); 
    $scope.shops         = user.sortBadRepoes.concat(user.sortShops);
    $scope.shopIds       = user.shopIds;
    
    $scope.promotions    = filterPromotion;
    $scope.scores        = filterScore;
    $scope.brands        = filterBrand;
    $scope.types         = filterType;
    $scope.retailers     = filterRetailer;
    $scope.employees     = filterEmployee;
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
    
    // rsn 
    var time = diabloFilter.default_time();
    wsaleService.get_wsale_rsn(
	{shop       :$scope.shopIds,
	 start_time :diablo_filter_time(time.start_time, 0, dateFilter),
	 end_time   :diablo_filter_time(time.end_time, 1, dateFilter)}
    ).then(function(result){
	$scope.rsns = result.map(function(result){
	    return result.rsn;
	});
    });
	

    var dialog = diabloUtilsService; 
    var now    = $.now(); 
    
    $scope.select_rsn = function(item, model, label){
	wsaleService.get_w_sale_new(item).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var base        = result.sale;
		var sells       = result.detail; 
		var wsale = wsaleUtils.cover_wsale(
		    base,
		    sells,
		    $scope.shops,
		    $scope.brands,
		    $scope.retailers,
		    $scope.employees,
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
		    + $scope.select.card + $scope.select.withdraw; 
		$scope.select.left_balance = $scope.select.surplus; 
		console.log($scope.select);

		// setting
		$scope.setting.no_vip = wsaleUtils.no_vip(
		    $scope.select.shop.id, $scope.base_settings);
	    
		$scope.old_inventories = wsale.details;
		$scope.inventories = angular.copy(wsale.details);
	    
		$scope.inventories.unshift({$edit:false, $new:true});

		console.log($scope.old_inventories);
		console.log($scope.inventories);

	    //
		$scope.has_withdrawed = false;
		$scope.re_calculate();
		
		$scope.hidden.travel = false;
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
    
    $scope.p_mode = function(shopId){
	return wsaleUtils.print_mode(shopId, base);
    };
    
    /*
     * withdraw
     */ 
    $scope.disable_withdraw = function(){
	return $scope.select.has_pay <= 0 || $scope.has_withdrawed;
    };

    $scope.withdraw = function(){
	var callback = function(params){
	    console.log(params);
	    wretailerService.check_retailer_password(
		params.retailer.id, params.retailer.password)
		.then(function(result){
		    console.log(result); 
		    if (result.ecode === 0){
			// $scope.select.surplus  = params.retailer.balance 
			$scope.select.withdraw = params.retailer.withdraw;
			$scope.has_withdrawed  = true;
			$scope.re_calculate();
		    } else {
			diabloUtilsService.response(
			    false,
			    "会员退款",
			    wretailerService.error[result.ecode],
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
	      withdraw  :$scope.select.should_pay,
	      pattern   :$scope.pattern.passwd},
	    }
	);
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved || $scope.inventories.length === 0 || $scope.select.rcharge === 0)
	    return true;

	if ($scope.select.retailer.type===1 && !$scope.has_withdrawed)
	    return true;

	return false; 
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
	    
	dialog.request(
	    "销售退货", "退货成功，是否打印退货单？",
	    ok_print, undefined, $scope);
    };

    $scope.print_front = function(result, im_print){
	var dialog = diabloUtilsService; 
	var ok_print = function(){
	    javascript:window.print();
	};

	dialog.request(
	    "销售退货", "退货成功，是否打印销售单？",
	    ok_print, undefined, $scope);
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
	    withdraw:      setv($scope.select.withdraw),
	    verificate:    $scope.select.verificate,
	    direct:        wsaleService.direct.wreject,
	    total:         seti($scope.select.rtotal),
	    score:         $scope.select.rscore
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

		if (diablo_backend === $scope.p_mode($scope.select.shop.id)){
		    $scope.print_backend(result, false);
		} else {
		    $scope.print_front(result, false); 
		} 
	    } else{
	    	dialog.response_with_callback(
	    	    false,
		    "销售退货",
		    "退货失败：" + wsaleService.error[result.ecode],
		    $scope, function(){$scope.has_saved = false});
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
	    if (!inv.select){
		if (diablo_invalid_index !== inv.sid)
		    nscore += wsaleUtils.calc_score_of_money(inv.calc, inv.score);
	    } else {
		$scope.select.rcharge += inv.calc;
		$scope.select.rtotal += inv.reject;
	    }
	}

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
}); 
