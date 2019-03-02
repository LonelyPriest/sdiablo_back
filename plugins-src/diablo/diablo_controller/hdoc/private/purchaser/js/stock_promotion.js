'use strict'

function stockPromotionNewProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    purchaserService, wgoodService){
    // $scope.shops = user.sortShops; 
    $scope.pattern = {
	name        :diabloPattern.ch_en_num_beside_underline_bars,
	discount    :diabloPattern.discount,
	number      :diabloPattern.number,
	remark      :diabloPattern.comment,
	semi_number :diabloPattern.semicolon_number
    };
    
    $scope.rules  = purchaserService.promotion_rules;
    $scope.prules = purchaserService.promotion_prules;
    $scope.yes_no = stockUtils.yes_no();

    var now = $.now();
    $scope.promotion = {
	// shop:      $scope.shops[0],
	rule       :$scope.rules[0],
	prule      :$scope.prules[0],
	member     :$scope.yes_no[0],
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

	var rule_id = $scope.promotion.rule.id;
	var prule_id = $scope.promotion.prule.id;
	var p = {
	    // shop:     $scope.promotion.shop.id,
	    name:     $scope.promotion.name,
	    rule:     rule_id,
	    prule:    prule_id,
	    discount: rule_id === 0 ? $scope.promotion.discount : undefined,
	    consume:  rule_id === 1 || rule_id === 2 ? $scope.promotion.consume : undefined,
	    reduce:   rule_id === 1 || rule_id === 2 ? $scope.promotion.reduce : undefined,

	    scount:   rule_id === 3 || rule_id === 4 || rule_id === 5 ? $scope.promotion.scount : undefined,
	    sdiscount:rule_id === 3 || rule_id === 4 || rule_id === 5 ? $scope.promotion.sdiscount : undefined, 

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
    
};


function stockPromotionDetailProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    purchaserService, wgoodService, user){
    $scope.pattern = {
	name: diabloPattern.ch_name_address,
	balance: diabloPattern.decimal_2,
	semi_number :diabloPattern.semicolon_number,
	comment: diabloPattern.comment};
    
    $scope.rules = purchaserService.promotion_rules;
    $scope.prules = purchaserService.promotion_prules;
    $scope.refresh = function(){
	wgoodService.list_w_promotion().then(function(promotions){
	    console.log(promotions);

	    var order = 0;
	    angular.forEach(promotions, function(p){
		p.rule = diablo_get_object(p.rule_id, $scope.rules);
		p.prule = diablo_get_object(p.prule_id, $scope.prules); 
		p.order_id = ++order;
	    });
	    
	    $scope.promotions = promotions;
	    
	})
    };

    $scope.good_right = {
	new_promotion: rightAuthen.authen(
	    user.type,
	    rightAuthen.good_action()['new_promotion'],
	    user.right
	)
    };

    $scope.refresh();

    $scope.new_promotion = function(){
	diablo_goto_page("#/promotion/promotion_new");
    };

    var dialog = diabloUtilsService;
    $scope.update_promotion = function(old_promotion){
	var callback = function(params){
	    // console.log(params.promotion); 
	    var update = {pid: old_promotion.id};
	    for (var o in params.promotion){
		if (!angular.equals(params.promotion[o], old_promotion[o])){
		    update[o] = params.promotion[o];
		}
	    }
	    console.log(update);
	    wgoodService.update_w_promotion(update).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "促销方案编辑",
			"促销方案 [" + params.promotion.name + "] 编辑成功！！",
			undefined, function(){$scope.refresh()})
		} else{
		    dialog.response(
			false, "促销方案编辑", "促销方案编辑失败："
			    + wgoodService.error[result.ecode], $scope);
		}
	    });
	}

	var valid_promotion = function(new_promotion){
	    for (var i=0, l=$scope.promotions.length; i<l; i++){
		if (new_promotion.name === $scope.promotions[i].name
		    && new_promotion.name !== old_promotion.name){
		    return false;
		}
	    }
	    
	    return true;
	}

	dialog.edit_with_modal(
	    'update-promotion.html', undefined, callback, undefined,
	    {promotion:old_promotion,
	     valid_promotion:valid_promotion,
	     pattern:$scope.pattern,
	     has_update: function(new_promotion){
		 if (diablo_is_same(new_promotion.member, old_promotion.member)
		     && diablo_is_same(new_promotion.remark, old_promotion.remark)) {
		     if (0 === new_promotion.rule_id
			 && diablo_is_same(new_promotion.discount, old_promotion.discount))
			 return false;
		     else if ((1 === new_promotion.rule_id || 2 === new_promotion.rule_id)
			      && diablo_is_same(new_promotion.cmoney, old_promotion.cmoney)
			      && diablo_is_same(new_promotion.rmoney, old_promotion.rmoney))
			 return false;
		     else if ((3 === new_promotion.rule_id
			       || 4 === new_promotion.rule_id
			       || 5 === new_promotion.rule_id)
			      && diablo_is_same(new_promotion.scount, old_promotion.scount)
			      && diablo_is_same(new_promotion.sdiscount, old_promotion.sdiscount))
			 return false;
		 }
		 return true;
	     }
	    })
    };

    $scope.delete_promotion = function(p){
	dialog.response(false, "删除促销方案", "暂不支持此操作！！");
    };
    
};

define(["purchaserApp"], function(app){
    app.controller("stockPromotionNew", stockPromotionNewProvide);
    app.controller("stockPromotionDetail", stockPromotionDetailProvide);
});
