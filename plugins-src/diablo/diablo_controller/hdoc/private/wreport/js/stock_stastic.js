wreportApp.controller("stockStasticCtrl", function(
    $scope, dateFilter, diabloFilter, diabloUtilsService, wreportService, filterEmployee, user, base){
    // console.log(user);
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    
    $scope.filters = [];
    diabloFilter.add_field("shop",     $scope.shops);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = reportUtils.first_day_of_month()
    // var now = $.now();
    // $scope.qtime_start = function(){
    // 	return diablo_base_setting(
    // 	    "qtime_start", -1, base, diablo_set_date,
    // 	    diabloFilter.default_start_time(now));
    // }(); 
    $scope.time = diabloFilter.default_time(now.first, now.current);

    $scope.pagination = {
	items_perpage:  diablo_items_per_page(),
	total_page:    0,
	max_page_size: 10,
	default_page:  1,
	current_page:  1
    };

    $scope.d_reports = [];
    $scope.s_stastic = {
	total_items: 0,

	sell: 0,
	sell_cost: 0,
	balance: 0,
	cash: 0,
	card: 0,
	veri: 0,

	// stock: 0,
	// stockCost: 0,

	stockIn: 0,
	stockInCost: 0,
	stockOut: 0,
	stockOutCost:0,

	tstockIn: 0,
	tstockOut: 0,
	tstockInCost:0,
	tstockOutCost:0,

	stockFix: 0,
	stockFixCost: 0 
    };

    $scope.refresh = function(){
	$scope.do_search($scope.pagination.default_page);
    };
    
    $scope.page_changed = function(){
	$scope.do_search($scope.pagination.current_page);
    };

    var add_shop_condition = function(search){
	if (angular.isUndefined(search.shop)
	    || !search.shop || search.shop.length === 0){
	    // search.shop = user.shopIds;
	    search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds;
	};

	return search;
    };
    
    $scope.do_search = function(page){
	console.log(page);
	$scope.pagination.current_page = page;
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_shop_condition(search);
	    
	    wreportService.h_daily_report(
		search, $scope.pagination.items_perpage, page
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === 1){
			$scope.s_stastic.total_items = result.total;
			
			$scope.s_stastic.sell = result.sell;
			$scope.s_stastic.sell_cost = result.sell_cost;
			$scope.s_stastic.balance = result.balance;
			$scope.s_stastic.cash = result.cash;
			$scope.s_stastic.card = result.card;
			$scope.s_stastic.veri = result.veri;

			// $scope.s_stastic.stock = result.stock;
			// $scope.s_stastic.stockCost = result.stockCost;
			
			$scope.s_stastic.stockIn = result.stockIn;
			$scope.s_stastic.stockInCost = result.stockInCost;
			$scope.s_stastic.stockOut = result.stockOut;
			$scope.s_stastic.stockOutCost = result.stockOutCost;

			$scope.s_stastic.tstockIn = result.tstockIn;
			$scope.s_stastic.tstockInCost = result.tstockInCost;
			$scope.s_stastic.tstockOut = result.tstockOut;
			$scope.s_stastic.tstockOutCost = result.tstockOutCost;

			$scope.s_stastic.stockFix = result.stockFix;
			$scope.s_stastic.stockFixCost = result.stockFixCost;

			$scope.d_reports = [];
		    }

		    $scope.d_reports = angular.copy(result.data); 
		    angular.forEach($scope.d_reports, function(d){
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    });
		    console.log(page);
		    diablo_order_page(
			page, $scope.pagination.items_perpage, $scope.d_reports);

		    console.log($scope.d_reports);
		}
	    });
	});
    };

    $scope.do_search($scope.pagination.default_page);

    var dialog = diabloUtilsService;
    $scope.syn_report = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_shop_condition(search);
	    // console.log(search);
	    
	    wreportService.syn_daily_report(search).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "同步日报表", "同步日报表成功！！", undefined,
			function(){$scope.do_search($scope.pagination.current_page)}) 
		} else {
		    dialog.response(
			false, "同步日报表", "同步日报表失败："
			    + wreportService.error[result.ecode]);
		} 
	    }); 
	})
    };

    $scope.go_back = function(){
    	diablo_goto_page("#/wreport_daily");
    }
    
});
