wreportApp.controller("stockStasticCtrl", function(
    $scope, dateFilter, diabloFilter, wreportService, filterEmployee, user, base){
    // console.log(user);
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    
    $scope.filters = [];
    diabloFilter.add_field("shop",     $scope.shops);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();


    var now = $.now();
    $scope.qtime_start = function(){
	return diablo_base_setting(
	    "qtime_start", -1, base, diablo_set_date,
	    diabloFilter.default_start_time(now));
    }();
    
    $scope.time = diabloFilter.default_time($scope.qtime_start);

    var calc_profit = function(m1, m2){
	if ( angular.isUndefined(m1) || angular.isUndefined(m2)) return undefined;
	if ( 0 === m1 || 0 === m2 ) return 0;
	return parseFloat(diablo_float_div((m2 - m1), m2) * 100).toFixed(1);
    }

    var filter_by_shop = function(shopId, stastics) {
	if (!angular.isArray(stastics)) return {};
	
	var s = stastics.filter(function(s){
	    if (s.hasOwnProperty("shop_id")){
		return s.shop_id === shopId; 
	    } else if (s.hasOwnProperty("fshop_id")){
		return s.fshop_id === shopId; 
	    }
	    else if (s.hasOwnProperty("tshop_id")){
		return s.tshop_id === shopId; 
	    } else {
		return false;
	    } 
	});

	if (s.length === 1) return s[0];
	else return {};
    };

    var to_i =  function(v){
	if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
	    return 0;
	} else{
	    return parseInt(v)
	}
    };

    var to_f =  function(v){
	if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
	    return 0;
	} else{
	    return parseFloat(v)
	}
    };
    
    $scope.do_search = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds; ;
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

		    $scope.stastics = [];
		    $scope.total = {spay:0, oprice:0, cash:0, card:0, veri:0,
				    pin:0, pout:0,
				    tin:0, tout:0,
				    sale:0, fix:0, stock:0, rstock:0,
				    
				    pin_cost: 0, pout_cost:0,
				    tin_cost: 0, tout_cost:0,
				    sale_cost:0, fix_cost:0,
				    stock_cost:0, rstock_cost:0};

		    $scope.stastic_cost = [];
		    // $scope.total_cost = {};
		    
		    var order_id = 1; 
		    angular.forEach($scope.shops, function(shop){
			var s = {shop: shop, order_id:order_id};
			
			s.sale    = filter_by_shop(shop.id, stockSale);
			s.profit  = filter_by_shop(shop.id, stockProfit);
			// s.sale.s  = diablo_float_sub(s.profit.rprice, s.profit.org_price);
			s.sale.s  = diablo_float_sub(s.sale.spay, s.profit.org_price);
			// s.sale.p  = calc_profit(s.profit.org_price, s.profit.rprice);
			s.sale.p  = calc_profit(s.profit.org_price, s.sale.spay);
			s.pin     = filter_by_shop(shop.id, stockIn);
			s.pout    = filter_by_shop(shop.id, stockOut);
			s.tin     = filter_by_shop(shop.id, stockTransferIn);
			s.tout    = filter_by_shop(shop.id, stockTransferOut);
			s.fix     = filter_by_shop(shop.id, stockFix);
			s.rstock  = filter_by_shop(shop.id, stockReal);
			
			s.stock   = to_i(s.pin.total) + to_i(s.pout.total)
			    + to_i(s.tin.total) - to_i(s.tout.total)
			    + to_i(s.fix.total)
			    - to_i(s.sale.total);
			
			s.stock_cost = to_f(s.pin.cost) + to_f(s.pout.cost)
			    + to_f(s.tin.cost) - to_f(s.tout.cost)
			    + to_f(s.fix.cost) - to_f(s.profit.org_price);

			$scope.total.spay += s.sale.spay;
			$scope.total.oprice += s.profit.oprice;
			$scope.total.cash += s.sale.cash;
			$scope.total.card += s.sale.card;
			$scope.total.veri += s.sale.veri;
			$scope.total.pin  += to_i(s.pin.total);
			$scope.total.pout += to_i(s.pout.total);
			$scope.total.tin  += to_i(s.tin.total);
			$scope.total.tout += to_i(s.tout.total);
			$scope.total.sale += to_i(s.sale.total);
			$scope.total.fix += to_i(s.fix.total);
			$scope.total.stock += s.stock;
			$scope.total.rstock += to_i(s.rstock.total);

			$scope.total.pin_cost += to_f(s.pin.cost);
			$scope.total.pout_cost += to_f(s.pout.cost);
			$scope.total.tin_cost += to_f(s.tin.cost);
			$scope.total.tout_cost += to_f(s.tout.cost);
			$scope.total.sale_cost += to_f(s.profit.org_price);
			$scope.total.fix_cost += to_f(s.fix.cost);
			$scope.total.stock_cost += to_f(s.stock_cost);
			$scope.total.rstock_cost += to_f(s.rstock.cost);
			
			$scope.stastics.push(s); 
			// $scope.stastic_cost.push(s);
			
			order_id++;
		    });

		    console.log($scope.stastics);
		}
	    });
	});
    };

    $scope.do_search();
    
});
