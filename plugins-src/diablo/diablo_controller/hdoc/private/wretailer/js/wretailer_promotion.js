wretailerApp.controller("wretailerRechargeNewCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService, wretailerService){
    $scope.pattern = {
	name      :diabloPattern.ch_en_num_beside_underline_bars,
	number    :diabloPattern.number,
	remark    :diabloPattern.comment
    };

    var dialog = diabloUtilsService; 
    var now    = $.now();
    
    $scope.promotion = {
	discount   :100,
	sdate      :now,
	edate      :now +  diablo_day_millisecond * 90
    };

    $scope.new_promotion = function(){
	console.log($scope.promotion);

	wretailerService.new_charge_promotion(
	    {name:    $scope.promotion.name,
	     charge:  $scope.promotion.charge,
	     balance: diablo_set_integer($scope.promotion.balance),
	     sdate:   dateFilter($scope.promotion.sdate, "yyyy-MM-dd"),
	     edate:   dateFilter($scope.promotion.edate, "yyyy-MM-dd"), 
	     remark:  diablo_set_string($scope.promotion.remark)}
	).then(function(result){
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true, "新增充值方案", "充值方案新增成功！！", undefined,
		    function(){$scope.cancel()});
	    } else {
		dialog.response(
		    false,
		    "新增充值方案",
		    "充值方案新增失败："
			+ wretailerService.error[result.ecode],
		    undefined);
	    }
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/promotion/recharge_detail");
    }
});


wretailerApp.controller("wretailerRechargeDetailCtrl", function(
    $scope, diabloPattern, diabloUtilsService){

    
    
    $scope.new_recharge = function(){
	diablo_goto_page("#/promotion/recharge_new");
    }
});
