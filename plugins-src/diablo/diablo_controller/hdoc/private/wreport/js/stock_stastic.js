'use strict'

function stockStasticCtrlProvide(
    $scope, dateFilter, diabloFilter, diabloUtilsService, wreportService,
    filterEmployee, filterRegion, user, base){
    // console.log(user);
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    $scope.disableSyn = false;

    var show_report_days = user.sdays;
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenReportRight();
    
    // $scope.right = {
    // 	orgprice: rightAuthen.authen(user.type,
    // 				     rightAuthen.rainbow_action()['show_orgprice'],
    // 				     user.right)
    // }; 
    
    $scope.filters = [];
    diabloFilter.add_field("shop",     $scope.shops);
    diabloFilter.add_field("region", filterRegion);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = reportUtils.first_day_of_month()
    // var now = $.now();
    // $scope.qtime_start = function(){
    // 	return diablo_base_setting(
    // 	    "qtime_start", -1, base, diablo_set_date,
    // 	    diabloFilter.default_start_time(now));
    // }(); 
    // $scope.time = diabloFilter.default_time(now.first, now.current);
    $scope.time = reportUtils.correct_query_time(
	authen.master,
	show_report_days,
	now.first,
	now.current,
	diabloFilter);
    console.log($scope.time);

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
	wxin: 0,
	aliPay: 0,
	draw: 0,
	ticket: 0,
	veri: 0,

	// stock: 0,
	// stockCost: 0,
	charge: 0,
	stockIn: 0,
	stockInCost: 0,
	stockOut: 0,
	stockOutCost:0,

	tstockIn: 0,
	tstockOut: 0,
	tstockInCost:0,
	tstockOutCost:0,

	stockFix: 0,
	stockFixCost: 0,

	margins: 0
    };

    $scope.refresh = function(){
	$scope.do_search($scope.pagination.default_page);
    };
    
    $scope.page_changed = function(){
	$scope.do_search($scope.pagination.current_page);
    };
    
    $scope.do_search = function(page){
	console.log(page);
	$scope.pagination.current_page = page;
	if (!authen.master && show_report_days !== diablo_nolimit_day) {
	    var diff = now.current - diablo_get_time($scope.time.start_time);
	    if (diff - diablo_day_millisecond * show_report_days > diablo_day_millisecond)
	    	$scope.time.start_time = now.current - show_report_days * diablo_day_millisecond;

	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now.current;
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // add_shop_condition(search);
	    reportUtils.correct_condition_with_shop(search, $scope.shopIds, $scope.shops);
	    
	    wreportService.h_daily_report(
		search, $scope.pagination.items_perpage, page
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === 1){
			$scope.s_stastic.total_items = result.total;
			
			$scope.s_stastic.sell = result.sell;
			$scope.s_stastic.sellCost = result.sellCost;
			$scope.s_stastic.balance = result.balance;
			$scope.s_stastic.cash = result.cash;
			$scope.s_stastic.card = result.card;
			$scope.s_stastic.wxin = result.wxin;
			$scope.s_stastic.aliPay = result.aliPay;
			$scope.s_stastic.draw = result.draw;
			$scope.s_stastic.ticket = result.ticket;
			$scope.s_stastic.veri = result.veri;

			$scope.s_stastic.charge = result.charge;
			$scope.s_stastic.pure_balance = result.balance - result.ticket - result.draw;

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

			$scope.s_stastic.margins = reportUtils.calc_profit(
			    $scope.s_stastic.sellCost, $scope.s_stastic.pure_balance);

			$scope.d_reports = [];
		    }

		    $scope.d_reports = angular.copy(result.data); 
		    angular.forEach($scope.d_reports, function(d){
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
		    });
		    console.log(page);
		    diablo_order_page(page, $scope.pagination.items_perpage, $scope.d_reports); 
		    console.log($scope.d_reports);
		}
	    });
	});
    };

    $scope.do_search($scope.pagination.default_page);

    var dialog = diabloUtilsService;
    $scope.syn_report = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    reportUtils.correct_condition_with_shop(search, $scope.shopIds, $scope.shops);
	    // console.log(search);
	    $scope.disableSyn = true;
	    wreportService.syn_daily_report(search).then(function(result){
		console.log(result);
		$scope.disableSyn = false;
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
    
};

define(["wreportApp"], function(app){
    app.controller("stockStasticCtrl", stockStasticCtrlProvide); 
});
