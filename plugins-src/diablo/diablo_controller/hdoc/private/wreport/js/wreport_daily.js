wreportApp.controller("wreportDailyCtrl", function(
    $scope, dateFilter, diabloFilter, diabloUtilsService, wreportService,
    wreportCommService, filterEmployee, user){
    wreportCommService.set_employee(filterEmployee);
    // wreportCommService.set_retailer(filterRetailer);
    wreportCommService.set_user(user);
    
    // $scope.employees = filterEmployee;
    // $scope.retailers = filterRetailer;
    // $scope.sortShops = user.sortShops;

    $scope.employees = wreportCommService.get_employee();
    $scope.sortShops = wreportCommService.get_sort_shop();
    $scope.current_day         = $.now();

    var to_f = reportUtils.to_float;
    var to_i = reportUtils.to_integer;

    var now_day = dateFilter($scope.current_day, "yyyy-MM-dd");
    var one_shop_report = {t_amount:0, t_hpay:0, t_spay:0, t_cash:0, t_card:0, t_verificate:0};

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
		// console.log(result);
		if (result.ecode === 0){
		    var sale = result.sale;
		    var profit = result.profit; 
		    var order_id = 1;

		    $scope.report_data = [];
		    $scope.total = {
			amount:0, spay: 0, org_price:0, money:0, cash:0, card:0, veri:0};
		    angular.forEach($scope.sortShops, function(shop){
			var s = {shop: shop, order_id: order_id};

			s.sale = reportUtils.filter_by_shop(shop.id, sale);
			s.profit = reportUtils.filter_by_shop(shop.id, profit);

			s.sale.s = diablo_float_sub(
			    to_f(s.sale.spay), to_f(s.profit.org_price));
			s.sale.p = reportUtils.calc_profit(
			    to_f(s.profit.org_price), to_f(s.sale.spay));

			$scope.total.amount += to_i(s.sale.total);
			$scope.total.spay += reportUtils.to_float(s.sale.spay);
			$scope.total.cash += reportUtils.to_float(s.sale.cash);
			$scope.total.card += reportUtils.to_float(s.sale.card);
			$scope.total.veri += reportUtils.to_float(s.sale.veri);
			$scope.total.org_price += reportUtils.to_float(s.profit.org_price);
			$scope.total.money += to_f(s.sale.s);
			
			$scope.report_data.push(s); 
			order_id++;
			
		    });

		    $scope.total.profit = reportUtils.calc_profit(
			$scope.total.org_price, $scope.total.spay); 
		    // console.log($scope.report_data);
		    // console.log($scope.total);
		}
		
	    })
	}) 
    };

    $scope.refresh();

    var dialog = diabloUtilsService;
    $scope.print_shop = function(d){

	var callback = function(params){
            wreportService.print_wreport(
		diablo_by_shop,
		{shop:     d.shop.id,
		 employee: params.employee.id,
		 datetime: dateFilter($scope.current_day, "yyyy-MM-dd HH:mm:ss"),
		 total:    d.t_amount,
		 spay:     d.t_spay,
		 cash:     d.t_cash,
		 card:     d.t_card}
            ).then(function(status){
		console.log(status);
		var messsage = "";
		if (status.pcode === 0){
                    messsage = "打印成功！！请等待服务器打印．．．";
                    dialog.response(true, "交班报表打印", messsage);
		} else {
                    message = "打印失败！！"
                    if (status.pinfo.length === 0){
			messsage += wreportService.error[status.pcode]
                    } else {
			angular.forEach(status.pinfo, function(p){
                            messsage += "[" + p.device + "] " + wreportService.error[p.ecode]
			})
                    };
                    dialog.response(false, "交班报表打印", messsage);
		}

            })
	}

	dialog.edit_with_modal(
	    "select-employee.html",
	    'normal',
	    callback,
	    undefined,
	    {employees:$scope.employees,
	     employee: $scope.employees[0]});
    };
});

wreportApp.controller("dailyByRetailer", function(
    $scope, diabloFilter, wreportService, wreportCommService){

    $scope.employees = wreportCommService.get_employee();
    $scope.retailers = wreportCommService.get_retailer();
    $scope.sortShops = wreportCommService.get_sort_shop();

    $scope.round     = diablo_round;

    /*
     * pagination
     */
    $scope.r_pagination = {
	items_perpage:  diablo_items_per_page(),
	total_page:    0,
	max_page_size: 5,
	default_page:  1,
	current_page:  1,
	colspan:       5,
	last_page:     0,
    };

    $scope.r_stastic = {
	total_items: 0,
	
	total_card:       0,
	total_cash:       0,
	total_wire:       0,
	total_verificate: 0,
	total_hpay:       0
    };

    // $scope.retailer_colspan=5;
    // $scope.current_page = $scope.default_page;

    var last_page = 0;
    var now = $.now();
    // var day = {start_time:now - 30 * diablo_day_millisecond, end_time:now};

    var day = {start_time:now, end_time:now};
    $scope.pre = function(){
	$scope.r_pagination.current_page -= 1;
	$scope.do_search($scope.r_pagination.current_page);
    };
    
    $scope.next = function(){
	$scope.r_pagination.current_page += 1;
	$scope.do_search($scope.r_pagination.current_page);
    };
    
    $scope.do_search = function(page){
	// console.log(page); 
	if (page === $scope.r_pagination.last_page){
	    return;
	};

	diabloFilter.do_filter([], day, function(search){
	    search.shop = wreportCommService.get_shop_id(); 
	    wreportService.daily_report(
		"by_retailer", search, $scope.r_pagination.items_perpage, page
	    ).then(function(result){
		console.log(result); 
		// var report_data = angular.copy(result.data);

		if (page === 1){
		    $scope.r_pagination.total_page =
			Math.ceil(
			    result.total / $scope.r_pagination.items_perpage);

		    $scope.r_stastic.total_items = result.total;
		    $scope.r_stastic.total_cash  = result.t_cash;
		    $scope.r_stastic.total_card  = result.t_card;
		    $scope.r_stastic.total_verificate = result.t_verificate;
		    $scope.r_stastic.total_spay = result.t_spay;
		    
		    $scope.r_data = [];
		}

		// $scope.r_data = angular.copy(result.data);

		angular.forEach(result.data, function(r){
		    r.shop = diablo_get_object(r.shop_id, $scope.sortShops);
		    r.retailer = diablo_get_object(
			r.retailer_id, $scope.retailers);
		});

		diablo_order(
		    result.data,
		    (page - 1) * $scope.r_pagination.items_perpage + 1);

		$scope.r_data = $scope.r_data.concat(result.data);
		
		// diablo_order_page(
		//     page, $scope.r_pagination.items_perpage, $scope.r_data);
		
		// console.log($scope.r_data);
		$scope.r_pagination.last_page = page;
		
	    })
	}) 
    }; 
});


wreportApp.controller("dailyByGood", function(
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
	// console.log(page); 
	if (page === $scope.s_pagination.last_page){
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
		
	    })
	})
	
    };
});
