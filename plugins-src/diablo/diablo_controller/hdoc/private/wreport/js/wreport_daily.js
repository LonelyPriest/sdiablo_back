'use strict'


function wreportDailyCtrlProvide(
    $scope, dateFilter, diabloFilter, diabloUtilsService, wreportService,
    wreportCommService, filterEmployee, user, base){
    wreportCommService.set_employee(filterEmployee);
    wreportCommService.set_user(user);
    wreportCommService.set_base_setting(base);

    // $scope.employees = wreportCommService.get_employee().filter(function(e){
    // 	return in_array(user.shopIds, e.shop)
    // });
    $scope.employees = filterEmployee;
    
    // console.log($scope.employees); 
    $scope.sortShops = wreportCommService.get_sort_shop();
    $scope.shopIds = user.shopIds;
    $scope.current_day = $.now();

    var LODOP;
    var print_mode = diablo_backend;
    for (var i=0, l=$scope.shopIds; i<l; i++){
	if (diablo_frontend === reportUtils.print_mode($scope.shopIds[i], base)){
	    if (needCLodop()) {
		loadCLodop();
		break;
	    };
	}
    };

    var to_f = reportUtils.to_float;
    var to_i = reportUtils.to_integer;

    var now_day = dateFilter($scope.current_day, "yyyy-MM-dd");
    // var one_shop_report = {t_amount:0, t_hpay:0, t_spay:0, t_cash:0, t_card:0, t_verificate:0};

    $scope.right = {
	master: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	)
    };
    
    $scope.refresh = function(){
        $scope.current_day = $.now();
        $scope.do_search_by_shop(true);
    };

    $scope.disable_after_daily = function(){
        return dateFilter("yyyy-MM-dd") === now_day;
    };

    $scope.after_daily = function(){
        $scope.current_day = $scope.current_day + diablo_day_millisecond;
        $scope.do_search_by_shop(true);
    }

    $scope.pre_daily = function(){
        $scope.current_day = $scope.current_day - diablo_day_millisecond;
        $scope.do_search_by_shop(true);
    } 

    $scope.do_search_by_shop = function(force){
	// console.log(page);
	if (!force) return;
	
	var day = {start_time:$scope.current_day, end_time:$scope.current_day}; 
	diabloFilter.do_filter([], day, function(search){
	    search.shop = wreportCommService.get_shop_id(); 
	    wreportService.daily_report("by_shop", search).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    var sale = result.sale;
		    var profit = result.profit;
		    var currentStock = result.rstock;
		    var lastStock = result.lstock;
		    var recharge = result.recharge;
		    var stockIn = result.pin;
		    var stockOut = result.pout;
		    var stockTransferIn = result.tin;
		    var stockTransferOut = result.tout;
		    
		    var order_id = 1;

		    $scope.report_data = [];
		    $scope.total = {
			sale:0,
			sale_cost:0,
			gross:0,
			margins:0,
			
			spay:0,
			cash:0,
			card:0,
			wxin:0,
			draw:0,
			ticket:0,
			veri:0,

			cbalance: 0,
			ccash: 0,
			ccard: 0,
			cwxin: 0,

			stock_in: 0,
			stock_out: 0,
			transfer_in: 0,
			transfer_out: 0
		    };
		    
		    angular.forEach($scope.sortShops, function(shop){
			var s = {shop: shop, order_id: order_id};

			s.sale = reportUtils.filter_by_shop(shop.id, sale);
			
			s.profit = reportUtils.filter_by_shop(shop.id, profit); 
			s.sale.cost = s.profit.org_price;
			
			s.sale.gross = reportUtils.f_sub(
			    to_f(s.sale.spay), to_f(s.profit.org_price));
			
			s.sale.margins = reportUtils.calc_profit(
			    to_f(s.profit.org_price), to_f(s.sale.spay));

			s.sale.currentStock = reportUtils.filter_by_shop(shop.id, currentStock);
			s.sale.lastStock = reportUtils.filter_by_shop(shop.id, lastStock);

			s.recharge = reportUtils.filter_by_shop(shop.id, recharge);
			s.sale.cbalance = s.recharge.cbalance;
			s.sale.ccash = s.recharge.tcash;
			s.sale.ccard = s.recharge.tcard;
			s.sale.cwxin = s.recharge.twxin;

			s.stock_in = reportUtils.filter_by_shop(shop.id, stockIn);
			s.stock_out = reportUtils.filter_by_shop(shop.id, stockOut);
			s.sale.stock_in = s.stock_in.total;
			s.sale.stock_out = s.stock_out.total;

			s.transfer_in = reportUtils.filter_by_shop(shop.id, stockTransferIn);
			s.transfer_out = reportUtils.filter_by_shop(shop.id, stockTransferOut);
			s.sale.transfer_in = s.transfer_in.total;
			s.sale.transfer_out = s.transfer_out.total;
		
			
			$scope.total.sale += to_i(s.sale.total);
			$scope.total.sale_cost += reportUtils.to_float(s.sale.cost);
			$scope.total.gross += to_f(s.sale.gross); 
			$scope.total.spay += reportUtils.to_float(s.sale.spay);
			
			$scope.total.cash += reportUtils.to_float(s.sale.cash);
			$scope.total.card += reportUtils.to_float(s.sale.card);
			$scope.total.wxin += reportUtils.to_float(s.sale.wxin);
			$scope.total.draw += reportUtils.to_float(s.sale.draw);
			$scope.total.ticket += reportUtils.to_float(s.sale.ticket);
			$scope.total.veri += reportUtils.to_float(s.sale.veri);

			$scope.total.cbalance += reportUtils.to_float(s.sale.cbalance); 
			$scope.total.ccash += reportUtils.to_integer(s.sale.ccash);
			$scope.total.ccard += reportUtils.to_integer(s.sale.ccard);
			$scope.total.cwxin += reportUtils.to_integer(s.sale.cwxin);

			$scope.total.stock_in += reportUtils.to_integer(s.sale.stock_in);
			$scope.total.stock_out += reportUtils.to_integer(s.sale.stock_out);
			$scope.total.transfer_in += reportUtils.to_integer(s.sale.transfer_in);
			$scope.total.transfer_out += reportUtils.to_integer(s.sale.transfer_out);
			
			$scope.report_data.push(s); 
			order_id++; 
		    });

		    $scope.total.sale_cost = reportUtils.to_decimal($scope.total.sale_cost);
		    $scope.total.gross = reportUtils.to_decimal($scope.total.gross);
		    $scope.total.margins = reportUtils.calc_profit($scope.total.sale_cost, $scope.total.spay); 
		    // console.log($scope.report_data);
		    // console.log($scope.total);
		}
		
	    })
	}) 
    };

    $scope.refresh();
    $scope.go_stastic = function(){diablo_goto_page("#/stastic")};

    var dialog = diabloUtilsService;

    var get_login_employee = function(shop, loginEmployee, employees){
	var employees = [{id: "-1", name: "==不选择员工表示默认打印整天报表=="}].concat(
	    employees.filter(function(e){
		return e.shop === shop;
	    })
	);
	
	var select = undefined;
	if (diablo_invalid_employee !== loginEmployee)
	    select = diablo_get_object(loginEmployee, employees); 
	
	if (angular.isUndefined(select)) select = employees[0];
	
	return {login_employee:select, employees:employees};
    };

    $scope.shift_print = function(d) {
	if (diablo_frontend === reportUtils.print_mode(d.shop.id, base))
	    $scope.print_shop_fronted(d);
	else
	    $scope.print_shop_backend(d);
    };
    
    $scope.print_shop_backend = function(d){
	var callback = function(params){
            wreportService.print_wreport(
		diablo_by_shop,
		{shop:     d.shop.id,
		 employee: params.employee.id === "-1" ? undefined : params.employee.id,
		 pcash:    diablo_set_float(params.pcash),
		 pcash_in: diablo_set_float(params.pcash_in),
		 comment:  diablo_set_string(params.comment)}
            ).then(function(status){
		console.log(status);
		if (status.ecode === 0){
		    var message = "";
		    if (status.pcode === 0){
			message = "打印成功！！请等待服务器打印．．．";
			dialog.response(true, "交班报表打印", message);
		    } else {
			message = "打印失败！！"
			if (status.pinfo.length === 0){
			    message += wreportService.error[status.pcode]
			} else {
			    angular.forEach(status.pinfo, function(p){
				message += "[" + p.device + "] " + wreportService.error[p.ecode]
			    })
			};
			dialog.response(false, "交班报表打印", message);
		    }
		} else {
		    dialog.response(
			false, "交班失败", "交班失败：" + wreportService.error[status.ecode]);
		}
            })
	} 
	
	// var loginEmployee = user.loginEmployee === diablo_invalid_employee ?
	//     $scope.employees[0] : diablo_get_object(user.loginEmployee, $scope.employees);
	var login = get_login_employee(d.shop.id, user.loginEmployee, $scope.employees);
	
	dialog.edit_with_modal(
	    "select-employee.html",
	    'normal',
	    callback,
	    undefined,
	    {employees:login.employees,
	     employee: login.login_employee});
    };

    $scope.print_shop_fronted = function(d){
	var login = get_login_employee(d.shop.id, user.loginEmployee, $scope.employees);

	// console.log(login);
	var callback = function(params){
	    wreportService.print_wreport(
		diablo_by_shop,
		{shop:     d.shop.id,
		 employee: params.employee.id === "-1" ? undefined : params.employee.id,
		 pcash:    diablo_set_float(params.pcash),
		 pcash_in: diablo_set_float(params.pcash_in),
		 comment:  diablo_set_string(params.comment)}
            ).then(function(status){
		if (status.ecode === 0){
		    var report = $scope.report_data.filter(function(r){
			return r.shop.id === d.shop.id;
		    })[0];

		    var pdate = dateFilter($scope.current_day, "yyyy-MM-dd HH:mm:ss");
		    
		    if (angular.isUndefined(LODOP)) LODOP = getLodop();

		    if (angular.isDefined(LODOP)){
			var hLine = reportPrint.gen_head(
			    LODOP, d.shop.name, login.login_employee, pdate);
			console.log(report.sale);
			hLine = reportPrint.gen_body(hLine, LODOP, report.sale, params); 
			reportPrint.start_print(LODOP)
		    } 
		} else {
		    dialog.response(
			false, "交班失败", "交班失败：" + wreportService.error[status.ecode]);
		}
	    }); 
	};

	dialog.edit_with_modal(
	    "select-employee.html",
	    'normal',
	    callback,
	    undefined,
	    {employees:login.employees,
	     employee: login.login_employee});
    }
};

function dailyByGoodProvide(
    $scope, diabloFilter, wreportService, wreportCommService){

    $scope.employees = wreportCommService.get_employee();
    $scope.retailers = wreportCommService.get_retailer();
    $scope.sortShops = wreportCommService.get_sort_shop();

    $scope.round     = diablo_round;

    /*
     * pagination
     */
    $scope.s_pagination = {
	items_perpage:  diablo_items_per_page(),
	total_page:    0,
	max_page_size: 5,
	default_page:  1,
	current_page:  1,
	last_page:     0,
	last_day:      ""    
    };

    $scope.s_stastic = {
	total_items: 0,
	total_sell:  0,
	total_stock: 0 
    };

    // $scope.retailer_colspan=5;
    // $scope.current_page = $scope.default_page;

    var last_page = 0;
    // var now = $.now();
    // var day = {start_time:now - 30*diablo_day_millisecond, end_time:now};
    // var day = {start_time:now, end_time:now};
    
    $scope.pre = function(){
	$scope.s_pagination.current_page -= 1;
	$scope.do_search($scope.s_pagination.current_page);
    };
    
    $scope.next = function(){
	$scope.s_pagination.current_page += 1;
	$scope.do_search($scope.s_pagination.current_page);
    };
    
    $scope.do_search = function(page, current_day){
	// console.log(page, current_day); 
	if (page === $scope.s_pagination.last_page
	    && current_day === $scope.s_pagination.last_day){
	    return;
	};

	var day = {start_time:$scope.current_day, end_time:$scope.current_day};

	diabloFilter.do_filter([], day, function(search){
	    search.shop = wreportCommService.get_shop_id(); 
	    wreportService.daily_report(
		"by_good", search, $scope.s_pagination.items_perpage, page
	    ).then(function(result){
		console.log(result); 
		// var report_data = angular.copy(result.data); 
		if (page === 1){
		    $scope.s_pagination.total_page =
			Math.ceil(
			    result.total / $scope.s_pagination.items_perpage);

		    $scope.s_stastic.total_items = result.total;
		    $scope.s_stastic.total_sell  = result.t_sell;
		    $scope.s_stastic.total_stock = result.t_stock;
		    $scope.s_data = [];
		}

		// $scope.s_data = angular.copy(result.data);

		angular.forEach(result.data, function(s){
		    s.shop = diablo_get_object(s.shop_id, $scope.sortShops); 
		});

		// diablo_order_page(
		//     page, $scope.s_pagination.items_perpage, $scope.s_data);
		
		// console.log($scope.s_data);
		diablo_order(
		    result.data,
		    (page - 1) * $scope.s_pagination.items_perpage + 1);

		$scope.s_data = $scope.s_data.concat(result.data);
		
		$scope.s_pagination.last_page = page;
		$scope.s_pagination.last_day = current_day;
		
	    })
	})
	
    };
};

function realStasticControllerProvide(
    $scope, diabloFilter, wreportCommService, wreportService){
    // console.log($scope); 
    // console.log($scope.sortShops);
    $scope.base_setting = wreportCommService.get_base_setting();
    $scope.shops = wreportCommService.get_sort_shop();
    $scope.shopIds = wreportCommService.get_shop_id();

    var query_start_time = reportUtils.start_time(
	$scope.base_setting, $scope.current_day, diabloFilter) 
    $scope.time = diabloFilter.default_time(query_start_time);

    // console.log($scope.time);

    $scope.filters = [];
    // diabloFilter.add_field("shop", $scope.sortShops);
    // $scope.filter = diabloFilter.get_filter();
    // $scope.prompt = diabloFilter.get_prompt();

    var calc_profit = reportUtils.calc_profit; 
    var filter_by_shop = reportUtils.filter_by_shop;
    var f_sub = reportUtils.f_sub;
    var to_i =  reportUtils.to_integer; 
    var to_f =  reportUtils.to_float;
    var to_decimal = reportUtils.to_decimal;

    $scope.do_search = function(){
	diabloFilter.do_filter([], $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds;
	    };

	    wreportService.stock_stastic($scope.match, search).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    var stockSale        = result.sale;
		    var stockProfit      = result.profit;
		    var stockIn          = result.pin;
		    var stockOut         = result.pout;
		    var stockTransferIn  = result.tin;
		    var stockTransferOut = result.tout;
		    var stockFix         = result.fix;
		    var stockReal        = result.rstock;
		    
		    $scope.total = {
			sale:0,
			sale_cost:0,
			gross:0,
			margins:0,
			spay:0,
			cost:0,
			cash:0,
			card:0,
			wxin:0,
			draw:0,
			ticket:0,
			veri:0,

			rstock:0,
			rstock_cost:0,

			cstock:0,
			cstock_cost:0,
			
			stock_in:0,
			stock_out:0,
			stock_in_cost:0,
			stock_out_cost:0,
			
			t_stock_in:0,
			t_stock_out:0,
			t_stock_in_cost:0,
			t_stock_out_cost:0,

			stock_fix:0,
			stock_fix_cost:0
		    };
		    
		    var order_id = 1;
		    $scope.d_sale_stastics = [];
		    $scope.d_stock_stastics = [];
		    
		    angular.forEach($scope.shops, function(shop){
			// sale stastic
			var s = {shop: shop, order_id:order_id};
			
			s.stockSale = filter_by_shop(shop.id, stockSale);
			s.stockProfit = filter_by_shop(shop.id, stockProfit); 
			s.stockSale.gross = f_sub(s.stockSale.spay, s.stockProfit.org_price); 
			s.stockSale.margins = calc_profit(s.stockProfit.org_price, s.stockSale.spay);

			$scope.d_sale_stastics.push(s);

			// stock statstic
			var ss = {shop: shop, order_id:order_id};

			ss.stockIn = filter_by_shop(shop.id, stockIn);
			ss.stockOut = filter_by_shop(shop.id, stockOut);
			
			ss.t_stockIn = filter_by_shop(shop.id, stockTransferIn);
			ss.t_stockOut = filter_by_shop(shop.id, stockTransferOut);
			
			ss.stockFix = filter_by_shop(shop.id, stockFix); 
			ss.rstock  = filter_by_shop(shop.id, stockReal);

			ss.saleTotal = s.stockSale.total;
			ss.saleCost = s.stockProfit.org_price;
			
			ss.cstock = to_i(ss.stockIn.total) + to_i(ss.stockOut.total)
			    + to_i(ss.t_stockIn.total) - to_i(ss.t_stockOut.total)
			    + to_i(ss.stockFix.total)
			    - to_i(s.stockSale.total);
			
			ss.cstock_cost =
			    to_f(ss.stockIn.cost) + to_f(ss.stockOut.cost)
			    + to_f(ss.t_stockIn.cost) - to_f(ss.t_stockOut.cost)
			    + to_f(ss.stockFix.cost) - to_f(ss.saleCost);
			ss.cstock_cost = reportUtils.to_decimal(ss.cstock_cost);

			$scope.d_stock_stastics.push(ss);

			// all
			$scope.total.sale += to_i(ss.saleTotal);
			$scope.total.sale_cost += to_f(ss.saleCost);
			$scope.total.gross += to_f(s.stockSale.gross);
			
			$scope.total.spay += to_f(s.stockSale.spay);
			$scope.total.cost += to_f(s.stockSale.cost);
			$scope.total.cash += to_f(s.stockSale.cash);
			$scope.total.card += to_f(s.stockSale.card);
			$scope.total.wxin += to_f(s.stockSale.wxin);
			$scope.total.draw += to_f(s.stockSale.draw);
			$scope.total.ticket += to_f(s.stockSale.ticket);
			$scope.total.veri += to_f(s.stockSale.veri);
			
			$scope.total.cstock += to_i(ss.cstock);
			$scope.total.cstock_cost += to_f(ss.cstock_cost);

			$scope.total.rstock += to_i(ss.rstock.total);
			$scope.total.rstock_cost += to_f(ss.rstock.cost);

			$scope.total.stock_in += to_i(ss.stockIn.total);
			$scope.total.stock_in_cost += to_f(ss.stockIn.cost);

			$scope.total.stock_out += to_i(ss.stockOut.total);
			$scope.total.stock_out_cost += to_f(ss.stockOut.cost);

			$scope.total.t_stock_in += to_i(ss.t_stockIn.total);
			$scope.total.t_stock_in_cost += to_f(ss.t_stockIn.cost);

			$scope.total.t_stock_out += to_i(ss.t_stockOut.total);
			$scope.total.t_stock_out_cost += to_f(ss.t_stockOut.cost);
			
			$scope.total.stock_fix += to_i(ss.stockFix.total);
			$scope.total.stock_fix_cost += to_f(ss.stockFix.cost); 
			order_id++;
		    });

		    $scope.total.margins = calc_profit($scope.total.sale_cost, $scope.total.spay);
		    $scope.total.sale_cost = reportUtils.to_decimal($scope.total.sale_cost);
		    $scope.total.gross = reportUtils.to_decimal($scope.total.gross);
		    
		    $scope.total.spay = to_decimal($scope.total.spay);
		    $scope.total.cost = to_decimal($scope.total.cost);
		    $scope.total.cash = to_decimal($scope.total.cash);
		    $scope.total.card = to_decimal($scope.total.card);
		    $scope.total.wxin = to_decimal($scope.total.wxin);
		    $scope.total.draw = to_decimal($scope.total.draw);
		    $scope.total.card = to_decimal($scope.total.ticket);
		    $scope.total.veri = to_decimal($scope.total.veri);

		    $scope.total.cstock_cost = to_decimal($scope.total.cstock_cost);
		    $scope.total.rstock_cost = to_decimal($scope.total.rstock_cost);
		    $scope.total.stock_in_cost = to_decimal($scope.total.stock_in_cost);
		    $scope.total.stock_out_cost = to_decimal($scope.total.stock_out_cost);

		    $scope.total.t_stock_in_cost = to_decimal($scope.total.t_stock_in_cost);
		    $scope.total.t_stock_out_cost = to_decimal($scope.total.t_stock_out_cost);

		    $scope.total.stock_fix_cost = to_decimal($scope.total.stock_fix_cost);
		    
		    
		    // console.log($scope.stastics);
		    // console.log($scope.d_sale_stastics);
		    // console.log($scope.d_stock_stastics);
		}
	    });
	});
    };

    // $scope.do_search();

    $scope.go_daily = function(){
	diablo_goto_page("#/stastic");
    };

    $scope.go_shift = function(){
	diablo_goto_page("#/switch_shift");
    };
};

define(["wreportApp"], function(app){
    app.controller("wreportDailyCtrl", wreportDailyCtrlProvide);
    app.controller("dailyByGood", dailyByGoodProvide);
    app.controller("realStasticController", realStasticControllerProvide);
});
