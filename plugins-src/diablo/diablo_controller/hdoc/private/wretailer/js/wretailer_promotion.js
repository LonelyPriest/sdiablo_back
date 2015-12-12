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
    $scope, diabloPattern, diabloUtilsService, wretailerService){

    var dialog = diabloUtilsService;
    
    wretailerService.list_charge_promotion().then(function(result){
	console.log(result);
	$scope.promotions = result;
	diablo_order($scope.promotions);
    });
    
    
    $scope.new_recharge = function(){
	diablo_goto_page("#/promotion/recharge_new");
    }

    $scope.update_charge = function(p){
	dialog.response(false, "修改充值方案", "暂不支持此操作！！");
    };

    $scope.delete_charge = function(p){
	dialog.response(false, "删除充值方案", "暂不支持此操作！！");
    };
});


wretailerApp.controller("wretailerScoreNewCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    wretailerService){
    
    $scope.pattern = {
	name      :diabloPattern.ch_en_num_beside_underline_bars,
	discount  :diabloPattern.discount,
	number    :diabloPattern.number,
	remark    :diabloPattern.comment
    };

    $scope.rules = wretailerService.score_rules;

    var now = $.now();
    $scope.promotion = {
	rule       :$scope.rules[0], 
	sdate      :now,
	edate      :now +  diablo_day_millisecond * 90
    };

    var dialog = diabloUtilsService;

    $scope.new_promotion = function(){
	console.log($scope.promotion);

	if (angular.isUndefined($scope.promotion.sdate)
	    || null === $scope.promotion.sdate){
	    $scope.promotion.sdate = now;
	}

	if (angular.isUndefined($scope.promotion.edate)
	    || null === $scope.promotion.edate){
	    $scope.promotion.edate = now +  diablo_day_millisecond * 90;
	}

	var p = {
	    // shop:     $scope.promotion.shop.id,
	    name:     $scope.promotion.name,
	    rule:     $scope.promotion.rule.id,
	    balance:  $scope.promotion.balance,
	    score:    $scope.promotion.score,
	    sdate:    dateFilter($scope.promotion.sdate, "yyyy-MM-dd"),
	    edate:    dateFilter($scope.promotion.edate, "yyyy-MM-dd"),
	    remark:   diablo_set_string($scope.promotion.remark)
	};

	wretailerService.new_score_promotion(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true, "新增积分方案", "新增积分方案成功！！", undefined,
		    function(){$scope.cancel()});
	    } else {
		dialog.response(
		    false,
		    "新增积分方案",
		    "新增积分方案失败："
			+ wretailerService.error[result.ecode],
		    undefined);
	    }
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/promotion/score_detail");
    }
    
});

wretailerApp.controller("wretailerScoreDetailCtrl", function(
    $scope, diabloPattern, diabloUtilsService, wretailerService){

    $scope.rules = wretailerService.score_rules;
    $scope.promotion = {balance2score: [], score2balance: []};
    $scope.select = {balance2score: false, score2balance: false};
    
    var dialog = diabloUtilsService;

    wretailerService.list_score_promotion().then(function(result){
    	console.log(result);

	$scope.promotion.balance2score = [];
	$scope.promotion.score2balance = [];
	angular.forEach(result, function(s){
	    if (s.type_id === $scope.rules[0].id){
		s.type = $scope.rules[0];
		$scope.promotion.balance2score.push(s);
	    } else if (s.type_id === $scope.rules[1].id){
		s.type = $scope.rules[1];
		$scope.promotion.score2balance.push(s);
	    }
	});
	
    	diablo_order($scope.promotion.balance2score);
	diablo_order($scope.promotion.score2balance);
    });
    
    
    $scope.new_score = function(){
	diablo_goto_page("#/promotion/score_new");
    }

    $scope.update_score = function(p){
	dialog.response(false, "修改积分方案", "暂不支持此操作！！");
    };

    $scope.delete_score = function(p){
	dialog.response(false, "删除积分方案", "暂不支持此操作！！");
    };
});
