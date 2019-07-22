'use strict'

function switchShiftCtrlProvide(
    $scope, dateFilter, diabloFilter, wreportService, filterEmployee, user){
    // console.log(user);
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    $scope.employees = filterEmployee;
    
    $scope.filters = [];
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("employee", $scope.employees);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = reportUtils.first_day_of_month() 
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
	balance: 0,
	cash: 0,
	card: 0,

	stockIn: 0,
	stockOut: 0,	
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
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds;
	    };

	    wreportService.switch_shift_report(
		search, $scope.pagination.items_perpage, page
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (page === 1){
			$scope.s_stastic.total_items = result.total;
			
			$scope.s_stastic.sell = result.sell;
			$scope.s_stastic.balance = result.balance;
			$scope.s_stastic.cash = result.cash;
			$scope.s_stastic.card = result.card;
			$scope.s_stastic.wxin = result.wxin;
			$scope.s_stastic.aliPay = result.aliPay;

			// $scope.s_stastic.stockIn = result.stockIn;
			// $scope.s_stastic.stockOut = result.stockOut;
			
			$scope.d_reports = [];
		    }

		    $scope.d_reports = angular.copy(result.data); 
		    angular.forEach($scope.d_reports, function(d){
			d.shop = diablo_get_object(d.shop_id, $scope.shops);
			d.employee = diablo_get_object(d.employee_id, $scope.employees);
		    });
		    
		    // console.log(page);
		    diablo_order_page(page, $scope.pagination.items_perpage, $scope.d_reports);

		    // console.log($scope.d_reports);
		}
	    });
	});
    };

    $scope.do_search($scope.pagination.default_page);

    $scope.go_back = function(){
    	diablo_goto_page("#/wreport_daily");
    }
};

define(["wreportApp"], function(app){
    app.controller("switchShiftCtrl", switchShiftCtrlProvide); 
});
