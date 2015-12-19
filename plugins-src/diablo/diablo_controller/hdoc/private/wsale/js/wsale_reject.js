wsaleApp.controller("wsaleRejectCtrl", function(
    $scope, $q, $timeout, dateFilter, diabloUtilsService, diabloPromise,
    diabloPattern, diabloFilter, diabloNormalFilter, wgoodService,
    purchaserService, wsaleService, wretailerService,
    user, filterPromotion, filterScore, filterBrand,
    filterType, filterRetailer,
    filterEmployee, filterSizeGroup, filterColor, base){
    // console.log(base);
    // console.log(user); 
    $scope.shops         = user.sortBadRepoes.concat(user.sortShops);
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
    
    $scope.round             = diablo_round;
    $scope.timeout_auto_save = undefined;
    
    $scope.hidden = {travel:true};
    
    $scope.setting = {q_backend:true,
		      // show_discount:true,
		      check_sale:true,
		      // trace_price:true,
		      round:diablo_round_record,
		      reject_rsn: true};

    $scope.pattern = {reject: diabloPattern.positive_num,
		      price:  diabloPattern.positive_decimal_2,
		      passwd: diabloPattern.num_passwd};
    

    $scope.go_back = function(){
	diablo_goto_page("#/new_wsale_detail");
    };

    if ($scope.setting.reject_rsn){
	$scope.inventories = [];
	$scope.select = {
	    shop:     $scope.shops[0],
	    datetime: $.now()
	};

	// rsn 
	var time = diabloFilter.default_time();
	wsaleService.get_wsale_rsn(
	    {shop       :$scope.select.shop.id,
	     start_time :diablo_filter_time(time.start_time, 0, dateFilter),
	     end_time   :diablo_filter_time(time.end_time, 1, dateFilter)}
	).then(function(result){
	    // console.log(result);
	    $scope.rsns = result.map(function(result){
		return result.rsn;
	    });
	});
	
    } else {
	// init
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	
	$scope.select = {
	    shop:     $scope.shops[0],
	    total:    0, 
	    datetime: $.now(),
	    charge:   0,
	    left_balance: 0,
	    score:      0,
	    should_pay: 0
	};
    } 

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
	    }

	    // setting
	    $scope.setting.round = wsaleUtils.get_round(
		$scope.select.shop.id, $scope.base_settings);

	    $scope.show_promotions = wsale.show_promotions;
	    // console.log($scope.setting);

	    $scope.old_select = wsale.select;
	    $scope.select = angular.extend($scope.select, wsale.select);
	    $scope.select.surplus = $scope.select.retailer.balance;
	    $scope.select.left_balance = $scope.select.retailer.balance; 
	    console.log($scope.select);
	    
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

    
    $scope.disable_refresh = function(){
	return $scope.has_saved ? false:true;
    };
    
    $scope.refresh = function(){
	if ($scope.setting.reject_rsn){
	    $scope.inventories = [];
	    datetime: $.now();
	    $scope.hidden.travel   = true;
	    $scope.has_saved       = false;
	    $scope.has_withdrawed  = false;
	    
	    $scope.select.comment  = undefined;
	    $scope.select.rsn      = undefined;
	} else {
	    $scope.inventories = [];
	    $scope.inventories.push({$edit:false, $new:true});

	    $scope.select.should_pay   = 0;
	    $scope.select.score        = 0;
	    $scope.select.total        = 0;
	    $scope.select.comment      = undefined;
	    $scope.select.left_balance = $scope.select.retailer.balance;

	    $scope.has_withdrawed  = false;
	    $scope.has_saved       = false;
	    // $scope.get_retailer(); 
	}
	
	
    };


    // $scope.retailers = filterRetailer;
    if ($scope.retailers.length !== 0){
	$scope.select.retailer = $scope.retailers[0];
	$scope.select.surplus  = $scope.round($scope.select.retailer.balance);
	// $scope.select.left_balance = $scope.select.surplus;
    }; 
    
    $scope.change_retailer = function(){
	$scope.select.surplus = $scope.select.retailer.balance;
	$scope.re_calculate();
	// $scope.refresh();
    }

    // employees
    // $scope.employees = filterEmployee;
    if ($scope.employees.length !== 0){
	$scope.select.employee = $scope.employees[0];
    };
    
    // calender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true;
    }; 

    $scope.setting.round = wsaleUtils.get_round(
	$scope.select.shop.id, $scope.base_settings); 
    $scope.setting.q_backend = wsaleUtils.typeahead(
	$scope.select.shop.id, $scope.base_settings);
    
    if (!$scope.setting.q_backend){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.select.shop.id,
	     start_time:$scope.qtime_start($scope.select.shop.id)}
	).$promise.then(function(invs){
	    // console.log(invs);
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    return angular.extend(
			inv, {name:inv.style_number
			      + "，" + inv.brand + "，" + inv.type})
		})
	});
    }; 
    
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    }
    
    $scope.copy_select = function(add, src){
	// console.log(src);
	add.id           = src.id;
	add.style_number = src.style_number;
	add.brand        = src.brand;
	add.brand_id     = src.brand_id;
	add.type         = src.type;
	add.type_id      = src.type_id;
	add.firm_id      = src.firm_id;
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;

	add.org_price    = src.org_price;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;
	add.alarm_day    = src.alarm_day;
	
	add.path         = src.path;
	add.s_group      = src.s_group;
	add.free         = src.free;
	return add; 
    };
    
    $scope.on_select_good = function(item, model, label){
	// console.log(item);

	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false,
		    "销售退货",
		    "退货失败：" + purchaserService.error[2099],
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
     * withdraw
     */ 
    $scope.disable_withdraw = function(){

	if (angular.isUndefined($scope.select.should_pay)
	   || $scope.has_withdrawed){
	    return true;
	}
	
	return $scope.select.should_pay <= 0 ? true : false;
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
	if ($scope.has_saved){
	    return true;
	};
	
	if ($scope.inventories.length === 1
	    && $scope.inventories[0].$new){
	    return true;
	};

	return false;
    }; 

    $scope.print_backend = function(result, im_print){
	var print = function(result){
	    var messsage = "";
	    if (result.pcode == 0){
		messsage = "单号："
		    + result.rsn + "，打印成功，请等待服务器打印！！";
	    } else {
		if (result.pinfo.length === 0){
		    messsage += wsaleService.error[result.pcode]
		} else {
		    angular.forEach(result.pinfo, function(p){
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
	
	if (im_print === diablo_yes){
	    var show_message = "退货成功！！" + print(result);
	    show_dialog("销售退货", show_message); 
	} else{
	    var ok_print = function(){
		wsaleService.print_w_sale(rsn).then(function(result){
		    var show_message = "退货单打印" + print(result);
		    show_dialog("销售退货", show_message); 
		})
	    };
	    
	    dialog.request(
		"销售退货", "退货成功，是否打印退货单？",
		ok_print, undefined, $scope);
	}
	
    };

    $scope.print_front = function(result, im_print){
	if (im_print === diablo_yes){
	    javascript:window.print();
	} else {
	    var dialog = diabloUtilsService; 
	    var ok_print = function(){
		javascript:window.print();
	    };

	    dialog.request(
		"销售退货", "退货成功，是否打印销售单？",
		ok_print, undefined, $scope);
	}
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
	
	var added = [];
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    if (add.$new) continue;
	    
	    added.push({
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand.name,
		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free,
		type        : add.type_id,
		type_name   : add.type.name,
		sex         : add.sex,
		season      : add.season,
		firm        : add.firm_id,
		year        : add.year,
		
		// org_price   : add.org_price,
		// tag_price   : add.tag_price, 
		// discount    : add.discount,
		alarm_day   : add.alarm_day,

		promotion   : add.pid,
		score       : add.sid,
		
		amounts     : get_sales(add.amounts),
		sell_total  : parseInt(add.reject),
		fdiscount   : parseInt(add.fdiscount),
		fprice      : parseFloat(add.fprice),
		path        : add.path
	    })
	};

	var setv = diablo_set_float; 
	var seti = diablo_set_integer; 
	var e_pay = setv($scope.select.extra_pay);
	var im_print = wsaleUtils.im_print(
	    $scope.select.shop.id, $scope.base_settings);
	
	var base = {
	    retailer_id:   $scope.select.retailer.id,
	    shop:          $scope.select.shop.id,
	    datetime:      dateFilter($scope.select.datetime,
				      "yyyy-MM-dd HH:mm:ss"),
	    employee:      $scope.select.employee.id,
	    comment:       $scope.select.comment,
	    balance:       setv($scope.select.surplus),
	    should_pay:    setv($scope.select.should_pay),
	    withdraw:      setv($scope.select.withdraw),
	    // left_balance:  setv($scope.select.left_balance),
	    direct:        wsaleService.direct.wreject,
	    total:         seti($scope.select.total),
	    score:         $scope.select.score
	};

	

	var print = {
	    im_print:    im_print,
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
		$scope.print_front(result, im_print);
	    } else{
	    	dialog.response_with_callback(
	    	    false,
		    "销售退货",
		    "退货失败：" + wsaleService.error[result.ecode],
		    $scope, function(){
			$scope.has_saved = false});
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
    
    $scope.re_calculate = function(){
	$scope.select.total = 0;
	$scope.select.should_pay = 0;
	$scope.select.score      = 0;

	var pmoneys = []; 
	var pscores = []; 
	
	for (var i=0, l=$scope.inventories.length; i<l; i++){
	    var one = $scope.inventories[i];
	    if (one.$new) continue;
	    
	    $scope.select.total += parseInt(one.reject);

	    if ($scope.setting.round === diablo_round_row){
		one.calc = $scope.round(
		    one.reject * one.fdiscount * 0.01 * one.fprice);
	    } else {
		one.calc = $scope.f_mul(
		    one.reject * one.fprice,
		    $scope.f_mul(one.fdiscount, 0.01));
	    }

	    if (!one.promotion){
		wsaleUtils.sort_promotion(
		    {id: -1, rule_id: -1}, one.calc, pmoneys);
	    } else {
		wsaleUtils.sort_promotion(one.promotion, one.calc, pmoneys);
	    }

	    if (one.score){
		wsaleUtils.sort_score(
		    one.score, one.promotion, one.calc, pscores);
	    }
	    
	}

	console.log(pmoneys);
	console.log(pscores);

	$scope.select.should_pay = wsaleUtils.calc_with_promotion(pmoneys);
	$scope.select.score = wsaleUtils.calc_with_score(pscores); 

	if ($scope.has_withdrawed){
	    $scope.select.left_balance =
		$scope.select.surplus + $scope.select.should_pay;
	    $scope.select.should_pay =
		$scope.select.should_pay - $scope.select.withdraw;
	} 
    };

    // $scope.$watch("select.extra_pay", function(newValue, oldValue){
    // 	if (newValue === oldValue || angular.isUndefined(newValue)) return;
    // 	if ($scope.select.form.extraForm.$invalid) return; 
    // 	$scope.re_calculate(); 
    // });
    
    var valid_reject = function(amounts){
	var changed = 0;
	for(var i=0, l=amounts.length; i<l; i++){
	    var reject_count = amounts[i].sell_count; 
	    if (angular.isDefined(reject_count) && reject_count){
		changed++;
		continue;
	    } 
	};

	// console.log(changed);
	return changed === 0 ? false : true;

    };
    
    var add_callback = function(params){
	console.log(params.amounts);
	
	var reject_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		reject_total += parseInt(a.sell_count);
	    }
	})

	return {amounts:     params.amounts,
		// sell_style:  params.sell_style, 
		reject:      reject_total,
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
	console.log($scope.setting);
	if ($scope.setting.check_sale === diablo_no && inv.free === 0){
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

	    calls.push(promise(purchaserService.list_purchaser_inventory,
			       condition)());
	    
	    $q.all(calls).then(function(data){
		console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop

		if ($scope.setting.check_sale === diablo_yes
		    || inv.free !== 0){
		    var shop_now_inv = data[0];

		    var order_sizes = wgoodService.format_size_group(
			inv.s_group, filterSizeGroup);
		    var sort = purchaserService.sort_inventory(
			shop_now_inv, order_sizes, filterColor);

		    inv.total   = sort.total;
		    inv.sizes   = sort.size;
		    inv.colors  = sort.color;
		    inv.amounts = sort.sort; 
		    
		    console.log(inv.sizes);
		    console.log(inv.colors);
		    console.log(inv.amounts); 
		}

		
		inv.fdiscount   = inv.discount;
		inv.fprice      = inv.tag_price;
		
		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts         = [{cid:0, size:0}];
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
			// inv.sell_style = result.sell_style;
			inv.reject     = result.reject;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    
		    var payload = {
			// sell_styles:  $scope.sell_styles,
			// sell_style:   inv.sell_style,
			fdiscount:    inv.fdiscount,
			fprice:       inv.fprice,
			sizes:        inv.sizes,
			large_size:   large_size,
			colors:       inv.colors,
			amounts:      inv.amounts,
			path:         inv.path,
			get_amount:   get_amount,
			get_price:    function(name){return inv[name]},
			valid:        valid_reject}
		    
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
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		// $scope.inventories.splice(i, 1)
		// deleteIndex = i;
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
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
	    inv.free_update = true;
	    inv.o_fdiscount = inv.fdiscount;
	    inv.o_fprice    = inv.fprice;
	    return;
	} 
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    // inv.sell_style = result.sell_style;
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
	    valid:        valid_reject};

	if (angular.isDefined(inv.has_query) && inv.has_query){
	    diabloUtilsService.edit_with_modal(
		"wsale-reject.html", modal_size, callback, $scope, payload);
	} else {
	    purchaserService.list_purchaser_inventory({
		style_number:inv.style_number,
		brand:inv.brand.id,
		shop:$scope.select.shop.id 
	    }).then(function(exists){
		console.log(exists);
		
		var s = wsaleUtils.sort_amount(
		    exists, inv.amounts, $scope.colors);
		inv.amounts = s.amounts;
		inv.total   = s.total;
		inv.colors  = s.colors;
		inv.has_query = true;

		payload.colors = inv.colors;
		payload.amounts = inv.amounts; 
		dialog.edit_with_modal(
		    "wsale-reject.html",
		    'normal',
		    callback,
		    undefined,
		    payload)
	    });
	}
	
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.amounts[0].sell_count = inv.reject;
	$scope.re_calculate(); 
    };

    $scope.cancel_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.reject = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    };

    $scope.auto_save_free = function(inv){
	if (angular.isUndefined(inv.reject)
	    || !inv.reject
	    || parseInt(inv.reject) === 0){
	    return;
	} 
	
	$timeout.cancel($scope.timeout_auto_save);
	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    }
		
	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    }
	}, 1000); 
    };
}); 
