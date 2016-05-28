wreportApp.controller("stockStasticCtrl", function(
    $scope, dateFilter, diabloFilter, wreportService, filterEmployee, user){
    // console.log(user);
    $scope.shops = user.sortShops;
    $scope.shopIds = user.shopIds;
    
    $scope.filters = [];
    diabloFilter.add_field("shop",     $scope.shops);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.time = diabloFilter.default_time($.now());

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
    
    $scope.do_search = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds === 0 ? undefined : $scope.shopIds; ;
	    };

	    wreportService.stock_stastic($scope.match, search).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    $scope.stastics = [];
		    
		    var stockSale        = result.sale;
		    var stockProfit      = result.profit;
		    var stockIn          = result.pin;
		    var stockOut         = result.pout;
		    var stockTransferIn  = result.tin;
		    var stockTransferOut = result.tout;
		    var stockFix         = result.fix;

		    var order_id = 1;
		    angular.forEach($scope.shops, function(shop){
			var s = {shop: shop, order_id:order_id};
			s.sale    = filter_by_shop(shop.id, stockSale);
			s.profit  = filter_by_shop(shop.id, stockProfit);
			s.sale.p  = calc_profit(s.profit.org_price, s.profit.rprice);
			s.pin     = filter_by_shop(shop.id, stockIn);
			s.pout    = filter_by_shop(shop.id, stockOut);
			s.tin     = filter_by_shop(shop.id, stockTransferIn);
			s.tout    = filter_by_shop(shop.id, stockTransferOut);
			s.fix     = filter_by_shop(shop.id, stockFix);
			$scope.stastics.push(s);
			order_id++;
		    });

		    console.log($scope.stastics);
		}
	    });
	});
    };

    $scope.do_search();
    
});
