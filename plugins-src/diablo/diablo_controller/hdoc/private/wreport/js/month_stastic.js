'use strict'

function monthStasticCtrlProvide(
    $scope, dateFilter, diabloFilter, diabloUtilsService, wreportService,
    filterEmployee, filterRegion, user, base){
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;

    // $scope.right = {
    // 	orgprice: rightAuthen.authen(user.type,
    // 				     rightAuthen.rainbow_action()['show_orgprice'],
    // 				     user.right)
    // };

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenReportRight();

    $scope.d_reports = [];
    $scope.s_stastic = {
	stockc:0,
	stockCost:0,
	
	sell: 0,
	balance: 0,
	sellCost: 0,
	cash: 0,
	card: 0,
	wxin: 0,
	aliPay: 0,
	draw: 0,
	ticket: 0,
	veri: 0,

	charge:0,

	stockIn: 0,
	stockInCost: 0,
	stockOut: 0,
	stockOutCost: 0,

	tstockIn: 0,
	tstockInCost: 0,
	tstockOut: 0,
	tstockOutCost: 0,

	stockFix: 0,
	stockFixCost: 0 
    };

    $scope.filters = [];
    diabloFilter.reset_field(); 
    diabloFilter.add_field("shop", $scope.shops);
    diabloFilter.add_field("region", filterRegion);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = reportUtils.first_day_of_month();
    var show_report_days = user.sdays;
    $scope.time = reportUtils.correct_query_time(
	authen.master,
	show_report_days,
	now.first,
	now.current,
	diabloFilter); 

    var reset_stastic = function(){
	$scope.s_stastic.stockc = 0;
	$scope.s_stastic.stockCost = 0;
	
	$scope.s_stastic.sell = 0;
	$scope.s_stastic.balance = 0;
	$scope.s_stastic.sellCost = 0;
	$scope.s_stastic.cash = 0;
	$scope.s_stastic.card = 0;
	$scope.s_stastic.wxin = 0;
	$scope.s_stastic.aliPay = 0;
	$scope.s_stastic.draw = 0;
	$scope.s_stastic.ticket = 0;
	$scope.s_stastic.veri = 0;

	$scope.s_stastic.charge = 0;

	$scope.s_stastic.stockIn = 0;
	$scope.s_stastic.stockInCost = 0;
	$scope.s_stastic.stockOut = 0;
	$scope.s_stastic.stockOutCost = 0;

	$scope.s_stastic.tstockIn = 0;
	$scope.s_stastic.tstockInCost = 0;
	$scope.s_stastic.tstockOut = 0;
	$scope.s_stastic.tstockOutCost = 0;

	$scope.s_stastic.stockFix = 0;
	$scope.s_stastic.stockFixCost = 0;
    };
    
    var to_i =  reportUtils.to_integer; 
    var to_f =  reportUtils.to_float;
    var decimal = reportUtils.to_decimal;
    
    $scope.do_search = function() {
	if (!authen.master && show_report_days !== diablo_nolimit_day) {
	    var diff = now.current - diablo_get_time($scope.time.start_time);
	    if (diff - diablo_day_millisecond * show_report_days > diablo_day_millisecond)
	    	$scope.time.start_time = now.current - show_report_days * diablo_day_millisecond;

	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now.current;
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    reportUtils.correct_condition_with_shop(search, $scope.shopIds, $scope.shops);
	    console.log(search);
	    
	    wreportService.h_month_wreport(search).then(function(result){
		console.log(result);
		if (result.ecode === 0) {
		    var order_id = 1;
		    $scope.d_reports = [];
		    reset_stastic();

		    var select_shops = function(){
			var shops = [];
			if (!angular.isArray(search.shop))
			    shops.push(search.shop);
			else
			    shops = search.shop;
			
			return shops.map(function(s){
			    return diablo_get_object(s, $scope.shops);
			})
		    }();
		    
		    angular.forEach(select_shops, function(shop){
			var p = {shop: shop, order_id:order_id};

			var d = reportUtils.filter_by_shop(shop.id, result.data);
			var s = reportUtils.filter_by_shop(shop.id, result.stock);

			p.stockc     = s.stockc;
			p.stockCost = s.stock_cost;
			
			p.sell     = d.sell;
			p.sellCost = d.sell_cost;
			p.balance  = d.balance;
			p.cash     = d.cash;
			p.card     = d.card;
			p.wxin     = d.wxin;
			p.aliPay   = d.aliPay;
			p.veri     = d.veri;
			p.draw     = d.draw;
			p.ticket   = d.ticket;

			p.charge   = d.charge;

			p.stockIn       = d.stock_in;
			p.stockOut      = d.stock_out;
			p.stockInCost   = d.stock_in_cost;
			p.stockOutCost  = d.stock_out_cost;

			p.tstockIn       = d.tstock_in;
			p.tstockOut      = d.tstock_out;
			p.tstockInCost   = d.tstock_in_cost;
			p.tstockOutCost  = d.tstock_out_cost;

			p.stockFix       = d.stock_fix;
			p.stockFixCost   = d.stock_fix_cost; 

			$scope.d_reports.push(p);

			order_id++;

			$scope.s_stastic.stockc += to_i(p.stockc);
			$scope.s_stastic.stockCost += to_f(p.stockCost);
			
			$scope.s_stastic.sell += to_i(p.sell);
			$scope.s_stastic.sellCost += to_f(p.sellCost);
			$scope.s_stastic.balance += to_f(p.balance);
			$scope.s_stastic.cash += to_f(p.cash);
			$scope.s_stastic.card += to_f(p.card);
			$scope.s_stastic.wxin += to_f(p.wxin);
			$scope.s_stastic.aliPay += to_f(p.aliPay);
			$scope.s_stastic.draw += to_f(p.draw);
			$scope.s_stastic.ticket += to_f(p.ticket);
			$scope.s_stastic.veri += to_f(p.veri);

			$scope.s_stastic.charge += to_f(p.charge);

			$scope.s_stastic.stockIn += to_i(p.stockIn);
			$scope.s_stastic.stockInCost += to_f(p.stockInCost);
			$scope.s_stastic.stockOut += to_i(p.stockOut);
			$scope.s_stastic.stockOutCost += to_f(p.stockOutCost);

			$scope.s_stastic.tstockIn += to_i(p.tstockIn);
			$scope.s_stastic.tstockInCost += to_f(p.tstockInCost);
			$scope.s_stastic.tstockOut += to_i(p.tstockOut);
			$scope.s_stastic.tstockOutCost += to_f(p.tstockOutCost);

			$scope.s_stastic.stockFix += to_i(p.stockFix);
			$scope.s_stastic.stockFixCost += to_f(p.stockFixCost); 
		    });

		    $scope.s_stastic.stockCost = decimal($scope.s_stastic.stockCost);
		    
		    $scope.s_stastic.sellCost = decimal($scope.s_stastic.sellCost);
		    $scope.s_stastic.stockInCost = decimal($scope.s_stastic.stockInCost);
		    $scope.s_stastic.stockOutCost = decimal($scope.s_stastic.stockOutCost);
		    
		    $scope.s_stastic.tstockInCost = decimal($scope.s_stastic.tstockInCost);
		    $scope.s_stastic.tstockOutCost = decimal($scope.s_stastic.tstockOutCost);

		    $scope.s_stastic.stockFixCost = decimal($scope.s_stastic.stockFixCost);

		    console.log($scope.s_stastic);
		    
		    
		    // console.log($scope.d_reports); 
		}
		
	    })
	});
    };

    var dialog = diabloUtilsService;
    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // add_shop_condition(search);
	    reportUtils.correct_condition_with_shop(search, $scope.shopIds, $scope.shops);
	    // console.log(search); 
	    wreportService.export_month_report(search).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"文件导出成功",
			"创建文件成功，请点击确认下载！！",
			undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败："
			    + wreportService.error[result.ecode]);
		} 
	    }); 
	});
    };

    $scope.go_back = function() {
	diablo_goto_page("#/wreport_daily");
    };
};

define(["wreportApp"], function(app){
    app.controller("monthStasticCtrl", monthStasticCtrlProvide); 
});
