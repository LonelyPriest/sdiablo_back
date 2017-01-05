'use strict'

function wretailerRechargeNewCtrlProvide(
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
};


function wretailerRechargeDetailCtrlProvide(
    $scope, diabloPattern, diabloUtilsService, wretailerService, user
){

    var dialog = diabloUtilsService;
    
    wretailerService.list_charge_promotion().then(function(result){
	console.log(result);
	// $scope.promotions = result.filter(function(r){return r.deleted!==1});
	$scope.promotions = angular.copy(result);
	diablo_order($scope.promotions);
    });

    $scope.right = {
	new_score: rightAuthen.authen_master(user.type)
    };
    
    $scope.new_recharge = function(){
	diablo_goto_page("#/promotion/recharge_new");
    }

    $scope.update_charge = function(p){
	dialog.response(false, "修改充值方案", "暂不支持此操作！！");
    };

    $scope.delete_charge = function(p){
	var callback = function() {
	    wretailerService.delete_charge_promotion(p.id).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"删除充分值方案",
			"充值方案删除成功！！",
			undefined,
			function() {p.deleted=diablo_has_deleted});
		} else {
		    dialog.response(
			false,
			"删除充值方案",
			"充值方案删除失败！！" + wretailerService.error[result.ecode],
			undefined);
		}
	    });
	};
	
	dialog.request(
	    "删除充值方案",
	    "确认要删除该充值方案吗？",
	    callback,
	    undefined,
	    undefined
	);
    };
};


function wretailerScoreNewCtrlProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService, wretailerService){
    
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
    
};

function wretailerScoreDetailCtrlProvide(
    $scope, diabloPattern, diabloUtilsService, wretailerService, user){

    $scope.rules = wretailerService.score_rules;
    $scope.promotion = {balance2score: [], score2balance: []};
    $scope.select = {balance2score: false, score2balance: false};

    $scope.right = {
	new_score: rightAuthen.authen_master(user.type)
    };

    $scope.refresh = function(){
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
	})
    };
    
    

    var dialog = diabloUtilsService;
    $scope.new_score = function(){
	diablo_goto_page("#/promotion/score_new");
    }

    $scope.update_score = function(old_score){
	dialog.response(false, "修改积分方案", "暂不支持此操作！！");
    };

    $scope.delete_score = function(old_score){
	dialog.response(false, "删除积分方案", "暂不支持此操作！！");
    };
};

define (["wretailerApp"], function(app){
    app.controller("wretailerRechargeNewCtrl", wretailerRechargeNewCtrlProvide);
    app.controller("wretailerRechargeDetailCtrl", wretailerRechargeDetailCtrlProvide);
    app.controller("wretailerScoreNewCtrl", wretailerScoreNewCtrlProvide);
    app.controller("wretailerScoreDetailCtrl", wretailerScoreDetailCtrlProvide);
});
