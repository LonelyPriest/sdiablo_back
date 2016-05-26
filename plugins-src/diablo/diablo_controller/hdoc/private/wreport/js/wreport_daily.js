wreportApp.controller("wreportDailyCtrl", function(
    $scope, dateFilter, diabloFilter, wreportService, wreportCommService,
    filterEmployee, user){
    wreportCommService.set_employee(filterEmployee);
    // wreportCommService.set_retailer(filterRetailer);
    wreportCommService.set_user(user);
    
    // $scope.employees = filterEmployee;
    // $scope.retailers = filterRetailer;
    // $scope.sortShops = user.sortShops;

    $scope.employees = wreportCommService.get_employee();
    // $scope.retailers = wreportCommService.get_retailer();
    $scope.sortShops = wreportCommService.get_sort_shop();

    // pagination
    $scope.max_page_size       = wreportService.max_page_size;
    // $scope.items_perpage     = wreportService.items_perpage;
    $scope.items_perpage       = diablo_items_per_page();

    // shop
    $scope.report_shop_colspan = 5; 
    $scope.current_day         = $.now();
    $scope.current_shop_page   = 1;
    
    // var day = {start_time:now - diablo_day_millisecond, end_time:now};
    // var day = {start_time:now, end_time:now};
    var now_day = dateFilter($scope.current_day, "yyyy-MM-dd");
    var one_shop_report = {t_amount:0, t_hpay:0, t_spay:0, t_cash:0, t_card:0, t_verificate:0};
    
    var last_shop_page = 0;
    var unused_shops = angular.copy(user.sortShops);

    $scope.refresh = function(){
        $scope.current_day = $.now();
        $scope.do_search_by_shop($scope.current_shop_page, true);
    };

    $scope.disable_after_daily = function(){
        return dateFilter($scope.current_day, "yyyy-MM-dd") === now_day;
    };

    $scope.after_daily = function(){
        $scope.current_day = $scope.current_day + diablo_day_millisecond;
        $scope.do_search_by_shop($scope.current_shop_page, true);
    }

    $scope.pre_daily = function(){
        $scope.current_day = $scope.current_day - diablo_day_millisecond;
        $scope.do_search_by_shop($scope.current_shop_page, true);
    }
    
    $scope.do_search_by_shop = function(page, force){
	// console.log(page);
	if (page === last_shop_page && !force){
            return;
        } 

	var day = {start_time:$scope.current_day, end_time:$scope.current_day};
	
	diabloFilter.do_filter([], day, function(search){
	    search.shop = wreportCommService.get_shop_id(); 
	    wreportService.daily_report(
		"by_shop", search, $scope.items_perpage, page
	    ).then(function(result){
		console.log(result);

		var report_data = angular.copy(result.data);
		
		unused_shops = 
		    unused_shops.filter(function(s){
			for (var i=0, l=report_data.length; i<l; i++){
			    if (s.id === report_data[i].shop_id){
				return false;
			    }
			} 
			return true;
		    })
		console.log(unused_shops);

		$scope.shop_reports = result.data.map(function(d){
		    return {t_amount: d.t_amount,
			    t_spay:   d.t_spay,
			    t_cash:   d.t_cash,
			    t_card:   d.t_card,
			    t_cbalance:   d.t_cbalance,
			    t_withdraw: d.t_withdraw,
			    shop: diablo_get_object(d.shop_id, $scope.sortShops)}
		});

		angular.forEach(unused_shops, function(s){
		    $scope.shop_reports.push(
			angular.extend({shop:s}, one_shop_report))
		});
		
		
		if (page === 1){
		    $scope.total_items =
			result.total === user.sortShops.length
			? result.total : user.sortShops.length;
		    $scope.total_amounts
			= result.t_amount ? result.t_amount : 0;
		    $scope.total_spay
			= result.t_spay ? result.t_spay : 0; 
		    $scope.total_cash
			=  result.t_cash ? result.t_cash : 0;
		    $scope.total_card
			=  result.t_card ? result.t_card : 0;
		    $scope.total_cbalance
			=  result.t_cbalance ? result.t_cbalance : 0;
		    $scope.total_withdraw
			=  result.t_withdraw ? result.t_withdraw : 0;
		}

		console.log($scope.shop_reports);
		diablo_order_page(
		    page, $scope.items_perpage, $scope.shop_reports); 
		last_shop_page = page;
	    })
	}) 
    };

    $scope.print = function(){
        wreportService.print_wreport(
            diablo_by_shop, {shop: wreportCommService.get_shop_id()[0],
                             datetime: dateFilter($scope.current_day, "yyyy-MM-dd HH:mm:ss"),
                             // hpay: $scope.total_hpay,
			     total: $scope.total_amount,
                             cash: $scope.total_cash,
                             card: $scope.total_card,
                             vpay: $scope.total_verificate}
        ).then(function(status){
            console.log(status);
            var messsage = "";
            if (status.pcode === 0){
                messsage = "打印成功！！请等待服务器打印．．．";
                diabloUtilsService.response(true, "日报表打印", messsage);
            } else {
                message = "打印失败！！"
                if (status.pinfo.length === 0){
                    messsage += common_error[status.pcode]
                } else {
                    angular.forEach(status.pinfo, function(p){
                        messsage += "[" + p.device + "] " + common_error[p.ecode]
                    })
                };
                diabloUtilsService.response(false, "日报表打印", messsage);
            }

        })
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
