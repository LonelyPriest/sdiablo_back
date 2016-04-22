purchaserApp.controller("stockPromotionNew", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    purchaserService, wgoodService){

    // $scope.shops = user.sortShops;

    $scope.pattern = {
	name      :diabloPattern.ch_en_num_beside_underline_bars,
	discount  :diabloPattern.discount,
	number    :diabloPattern.number,
	remark    :diabloPattern.comment
    };
    
    $scope.rules = purchaserService.promotion_rules;

    var now = $.now();
    $scope.promotion = {
	// shop:      $scope.shops[0],
	rule       :$scope.rules[0],
	discount   :100,
	sdate      :now,
	edate      :now +  diablo_day_millisecond * 90
    };

    var dialog = diabloUtilsService;
    
    $scope.new_promotion = function(){
	console.log($scope.promotion);

	if (angular.isUndefined($scope.promotion.sdate)
	    || $scope.promotion.sdate === null){
	    $scope.promotion.sdate = now;
	}

	if (angular.isUndefined($scope.promotion.edate)
	    || $scope.promotion.edate === null){
	    $scope.promotion.edate = now +  diablo_day_millisecond * 90;
	}
	
	var p = {
	    // shop:     $scope.promotion.shop.id,
	    name:     $scope.promotion.name,
	    rule:     $scope.promotion.rule.id,
	    discount: $scope.promotion.discount,
	    consume:  $scope.promotion.consume,
	    reduce:   $scope.promotion.reduce,
	    sdate:    dateFilter($scope.promotion.sdate, "yyyy-MM-dd"),
	    edate:    dateFilter($scope.promotion.edate, "yyyy-MM-dd"),
	    remark:   diablo_set_string($scope.promotion.remark)
	}; 
	
	wgoodService.new_w_promotion(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true, "新增促销方案", "促销方案新增成功！！", undefined,
		    function(){$scope.cancel()});
	    } else {
		dialog.response(
		    false,
		    "新增促销方案",
		    "促销方案新增失败：" + wgoodService.error[result.ecode],
		    undefined);
	    }
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/promotion/promotion_detail");
    }
    
});


purchaserApp.controller("stockPromotionDetail", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    purchaserService, wgoodService){
    $scope.rules = purchaserService.promotion_rules; 
    $scope.refresh = function(){
	wgoodService.list_w_promotion().then(function(promotions){
	    console.log(promotions);

	    var order = 0;
	    angular.forEach(promotions, function(p){
		p.rule = diablo_get_object(p.rule_id, $scope.rules);
		p.order_id = ++order;
	    });
	    
	    $scope.promotions = promotions;
	    
	})
    };

    $scope.refresh();

    $scope.new_promotion = function(){
	diablo_goto_page("#/promotion/promotion_new");
    };

    var dialog = diabloUtilsService;
    $scope.update_promotion = function(p){
	dialog.response(false, "修改促销方案", "暂不支持此操作！！");
    };

    $scope.delete_promotion = function(p){
	dialog.response(false, "删除促销方案", "暂不支持此操作！！");
    };
    
});
