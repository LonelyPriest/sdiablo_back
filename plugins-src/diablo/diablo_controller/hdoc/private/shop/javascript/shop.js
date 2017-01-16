'use strict'

function newShopCtrlProvide(
    $scope, shopService, diabloPattern, diabloUtilsService, filterEmployee, user){
    $scope.pattern = {address:diabloPattern.ch_name_address};
    
    $scope.employees = filterEmployee;
    // console.log($scope.employees);

    var dialog = diabloUtilsService;
    // employService.list().$promise.then(function(employees){
    // 	console.log(employees);
    // 	$scope.employees =  employees.map(function(e){
    // 	    return {name:e.name, id:e.number, py:diablo_pinyin(e.name)}
    // 	}) 
    // });

    // repo
    $scope.authen_list_repo =
	rightAuthen.authen_menu(
	    rightAuthen.shop_action["list_repo"],
	    user.right); 
    

    // console.log($scope.authen_list_repo);
    

    $scope.repertories = [];
    if ($scope.authen_list_repo){
	shopService.list_repo().then(function(repo){
    	    console.log(repo);
    	    $scope.repertories = repo.map(function(r){
    		return {name:r.name, id:r.id, py:diablo_pinyin(r.name)}
    	    })
	});
	// $scope.repertories = diabloNormalFilter.get_repo();
	console.log($scope.repertories);
    };
    
    // canlender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true; 
    }

    
    $scope.today = function(){
	return $.now();
    };

    // $scope.shop = {};
    $scope.new_shop = function(){
	console.log($scope.shop);
	shopService.add($scope.shop).$promise.then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true,
		    "新增店铺",
		    "恭喜你，店铺 " + $scope.shop.name + " 成功创建！！",
		    undefined,
		    function(){diablo_goto_page("#/shop/shop_detail")});
	    } else{
		dialog.response(
		    false, "新增店铺", shopService.error[state.ecode]); 
	    }
	})
    };
    
    $scope.cancel_new_shop = function(){
	diablo_goto_page("#/shop/shop_detail");
    }; 
};


function shopDetailCtrlProvide(
    $scope, $q, diabloUtilsService, shopService,
    filterPromotion, filterScore, filterCharge, filterEmployee, filterRegion, user){
    // console.log(filterPromotion);
    // console.log(filterEmployee); 
    // console.log(filterScore);
    // console.log(filterRegion);
    // console.log(user);
    
    $scope.promotions      = filterPromotion;
    // $scope.shop_promotions = filterShopPromotion.map(
    // 	function(p){return p.pid});
    $scope.charges = filterCharge.filter(function(c){return c.type===diablo_charge});
    $scope.charges = $scope.charges.concat([{id:-1, name:"重置充值方案"}]);
    $scope.draws   = filterCharge.filter(function(c){return c.type===diablo_withdraw});
    $scope.draws   = $scope.draws.concat([{id:-1, name:"重置提现方案"}]);
    
    $scope.scores          = filterScore.filter(function(s){return s.type_id===0});    
    $scope.employees       = filterEmployee;
    $scope.regions         = filterRegion.concat([{id:-1, name:"===请选择区域==="}]);
    // $scope.repertories = filterRepo;
    $scope.goto_page   = diablo_goto_page;

    // authen    
    $scope.authen_list_repo =
	rightAuthen.authen_menu(
	    rightAuthen.shop_action["list_repo"],
	    user.right); 
    
    $scope.repertories = [];
    var deferred = $q.defer(); 
    if ($scope.authen_list_repo){
	
	shopService.list_repo().then(function(repo){
    	    console.log(repo);
    	    $scope.repertories = repo.map(function(r){
    		return {name:r.name, id:r.id, py:diablo_pinyin(r.name)}
    	    });

	    $scope.get_repo = function(id){
		// console.log(id);
    		return diablo_get_object(id, $scope.repertories)
	    };

	    deferred.resolve();
	}); 
	// $scope.repertories = diabloNormalFilter.get_repo()
    } else{
	deferred.resolve();
    }
    
    
    $scope.get_employee = function(id){
    	return diablo_get_object(id, $scope.employees)
    }; 
    
    $scope.refresh = function(){
	$scope.shops = [];
	shopService.list().$promise.then(function(shops){
	    // console.log(shops);
	    // $scope.shops = angular.copy(shops);
	    // angular.forEach($scope.shops, function(s){
	    // 	$scope.repo = $scope.get_repo(s.repo);
	    // })
	    $scope.shops = [];
	    angular.forEach(shops, function(s){
		// console.log($scope.authen_list_repo);
		if (s.type === diablo_shop){
		    $scope.shops.push({
			id: s.id,
			name: s.name,
			
			charge_id: s.charge_id,
			charge: diablo_get_object(s.charge_id, $scope.charges),
			draw_id: s.draw_id,
			draw: diablo_get_object(s.draw_id, $scope.draws),

			score_id: s.score_id,
			score: diablo_get_object(s.score_id, $scope.scores),

			region_id: s.region_id,
			region: diablo_get_object(s.region_id, $scope.regions),
			
			address:      s.address,
			open_date:    s.open_date,
			entry_date:   s.entry_date,
			
			repo_id:s.repo,
			repo:$scope.authen_list_repo
			    ? $scope.get_repo(s.repo) : undefined,
			
			shopowner_id:s.shopowner_id,
			shopowner:diablo_get_object(
			    s.shopowner_id, $scope.employees)})
		}
	    }) 
	    diablo_order($scope.shops);
	    // console.log($scope.shops);
	});
    };

    
    // $scope.refresh();
    // wait for loading repo
    deferred.promise.then(function(data){$scope.refresh()});
    
    var dialog = diabloUtilsService;
    // edit 
    $scope.edit_shop = function(old_shop){
	// console.log(shop);
	var callback = function(params){
	    console.log(params);

	    // console.log(params.shop.name, old_shop.name);
	    // console.log(params.shop.address, old_shop.address);
	    // console.log(params.shop.region, old_shop.region);
	    // console.log(params.shop.shopowner, old_shop.shopowner);
	    var update = {
		id: params.shop.id,
		name: diablo_get_modified(params.shop.name, old_shop.name),
		address: diablo_get_modified(params.shop.address, old_shop.address),
		region: diablo_get_modified(params.shop.region, old_shop.region),
		shopowner: diablo_get_modified(params.shop.shopowner, old_shop.shopowner)
	    };
	    
	    // for (var o in params.shop){
	    // 	if (!angular.equals(params.shop[o], old_shop[o])){
	    // 	    update[o] = params.shop[o];
	    // 	}
	    // }
	    
	    // update.id = params.shop.id; 
	    console.log(update);
	    
    	    shopService.update(update).then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"店铺编辑",
			"恭喜你，店铺 ["
			    + old_shop.name + "] 信息修改成功！！",
			$scope, function(){$scope.refresh()});
    		} else{
		    dialog.response(
			false, "店铺编辑",
			"店铺编辑失败：" + shopService.error[state.ecode]);
    		}
	    })
	};

	var check_shop = function(new_shop){
	    for (var i=0, l=$scope.shops.length; i<l; i++){
		if (new_shop.name === $scope.shops[i].name
		    && new_shop.name !== old_shop.name){
		    return false;
		}
	    }

	    return true;
	};

	var has_update = function(new_shop){
	    return angular.equals(new_shop, old_shop) ? false : true; 
	};

	dialog.edit_with_modal(
	    "edit-shop.html", undefined, callback, $scope,
	    {shop:angular.extend(
		old_shop,
		{employee:$scope.get_employee(old_shop.shopowner_id)}),
	     employees:        $scope.employees,
	     repertories:      $scope.repertories,
	     regions:          $scope.regions,
	     authen_list_repo: $scope.authen_list_repo,
	     check_shop:       check_shop,
	     has_update:       has_update});
    };

    // delete shop
    $scope.delete_shop = function(shop){
	var callback = function(){
	    shopService.destroy(shop).then(function(state){
    		console.log(state);
    		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"删除店铺",
			"恭喜你， 店铺 [" + shop.name + "] 删除成功！！",
			$scope,
			function(){$scope.refresh()}); 
    		} else{
		    dialog.response(
			false,
			"删除店铺",
			"删除店铺失败："
			    + shopService.error[state.ecode], $scope);
    		}
    	    })
	};
	
	diabloUtilsService.request(
	    "删除店铺", "确定要删除该店铺吗？", callback, undefined, $scope);
    };

    $scope.on_sale = function(shop){
	var check_select = function(promotions){
	    var l = promotions.length;
	    for (var i=0; i<l; i++){
		if (promotions[i].select !== $scope.promotions[i].select){
		    return true;
		}
	    } 
	    
	    return false;
	};
	
	var callback = function(params){
	    console.log(params);

	    // only one rule of every promotion
	    for (var i=0, l=params.promotions.length; i<l; i++){
		for (var j=1; j<l; j++){
		    if (params.promotions[i].select
			&& params.promotions[j].select){
			if (params.promotions[i].rule_id
			    === params.promotions[j].rule_id){
			    dialog.response(
				false,
				"促销方案",
				"促销方案编辑失败！！"
				    + shopService.error[1398])
			    return false;
			}
		    }
		}
	    };
	    
	    var ps = params.promotions.filter(function(p){
		return p.select}).map(function(sp){return sp.id});
	    console.log(ps);

	    var oldps = $scope.shop_promotions;
	    console.log(oldps);

	    // added
	    var adds = [];
	    for (var i=0, l=ps.length; i<l; i++){
		var find = false;
		for (var j=0, k=oldps.length; j<k; j++){
		    if (ps[i] === oldps[j]){
			find = true;
			break;
		    }
		}
		if (!find) adds.push(ps[i]);
	    }

	    // deleted
	    var deletes = [];
	    for (var i=0, l=oldps.length; i<l; i++){
		var find = false;
		for (var j=0, k=ps.length; j<k; j++){
		    if (oldps[i] === ps[j]){
			find = true;
			break
		    }
		} 

		if (!find) deletes.push(oldps[i]);
	    }
	    

	    console.log(adds);
	    console.log(deletes); 
	    
	    shopService.add_promotion(
		0, shop.id,
		{add  :adds.length !== 0 ? adds : undefined,
		 del  : deletes.length !== 0 ? deletes : undefined}
	    ).then(function(result){
		console.log(result);
		
		if (result.ecode === 0){
		    $scope.shop_promotions = ps; 
		    $scope.promotions      = params.promotions; 

		    console.log($scope.shop_promotions);
		    console.log($scope.promotions); 
		    
		    dialog.response(true, "促销方案", "编辑促销方案成功！！");
		} else {
		    dialog.response(
			false,
			"促销方案",
			"编辑促销方案失败："
			    + shopService.error[result.ecode]);
		}
	    });
	};

	console.log($scope.shop_promotions);
	for (var i=0, l=$scope.promotions.length; i<l; i++){
	    $scope.promotions[i].select = false;
	    for (var j=0, k=$scope.shop_promotions.length; j<k; j++){
		if ($scope.promotions[i].id === $scope.shop_promotions[j]){
		    $scope.promotions[i].select = true; 
		    break;
		}
	    }

	};

	
	
	dialog.edit_with_modal(
	    "on-sale.html",
	    undefined,
	    callback,
	    undefined,
	    {shop: shop,
	     promotions: $scope.promotions,
	     check_select: check_select});
    };

    $scope.charge = function (shop){
	var check_only = function(select, charges){
	    // console.log(select);
	    angular.forEach(charges, function(c){
		if (c.id !== select.id){
		    c.select = false;
		};
	    });
	};

	var check_same = function(charges) {
	    for (var i=0, l=charges.length; i<l; i++){
		if (charges[i].select && charges[i].id === shop.charge_id){
		    return true;
		}
	    }
	    return false; 
	};
	
	var callback = function(params){
	    //console.log(params); 
	    var select = params.charges.filter(function(c){
		return c.select;
	    })[0];

	    console.log(select);

	    shopService.update_charge(shop.id, select.id, diablo_charge).then(function(
		result){
		console.log(result);
		
		if (result.ecode === 0){
		    shop.charge_id = select.id;
		    shop.charge = diablo_get_object(shop.charge_id, $scope.charges);
		    dialog.response(true, "充值方案", "编辑充值方案成功！！");
		} else {
		    dialog.response(
			false,
			"充值方案",
			"编辑充值方案失败："
			    + shopService.error[result.ecode]);
		}
	    });
	};  
	
	angular.forEach($scope.charges, function(c){
	    c.select = false;
	    if (c.id === shop.charge_id){
		c.select = true;
	    }
	});

	console.log($scope.charges);
	
	dialog.edit_with_modal(
	    "charge.html",
	    undefined,
	    callback,
	    undefined,
	    {shop: shop,
	     charges: $scope.charges,
	     check_only: check_only,
	     check_same: check_same});
    };

    $scope.withdraw = function (shop){
	var check_only = function(select, draws){
	    // console.log(select);
	    angular.forEach(draws, function(d){
		if (d.id !== select.id){
		    d.select = false;
		};
	    });
	};

	var check_same = function(draws) {
	    for (var i=0, l=draws.length; i<l; i++){
		if (draws[i].select && draws[i].id === shop.draw_id){
		    return true;
		}
	    }
	    return false; 
	};
	
	var callback = function(params){
	    //console.log(params); 
	    var select = params.draws.filter(function(d){
		return d.select;
	    })[0];

	    console.log(select);

	    shopService.update_charge(shop.id, select.id, diablo_withdraw).then(function(
		result){
		console.log(result);
		
		if (result.ecode === 0){
		    shop.draw_id = select.id;
		    shop.draw = diablo_get_object(shop.draw_id, $scope.draws);
		    dialog.response(true, "提现方案", "编辑提现方案成功！！");
		} else {
		    dialog.response(
			false,
			"提现方案",
			"编辑提现方案失败："
			    + shopService.error[result.ecode]);
		}
	    });
	};  
	
	angular.forEach($scope.draws, function(d){
	    d.select = false;
	    if (d.id === shop.draw_id)
		d.select = true;
	});

	console.log($scope.draws);
	
	dialog.edit_with_modal(
	    "shop-withdraw.html",
	    undefined,
	    callback,
	    undefined,
	    {shop: shop,
	     draws: $scope.draws,
	     check_only: check_only,
	     check_same: check_same});
    };

    $scope.score = function (shop){
	// console.log(shop);
	var check_only = function(select, scores){
	    // console.log(select);
	    angular.forEach(scores, function(s){
		if (s.id !== select.id){
		    s.select = false;
		};
	    });
	};

	var check_same = function(scores) {
	    for (var i=0, l=scores.length; i<l; i++){
		if (scores[i].select && scores[i].id === shop.score_id){
		    return true;
		}
	    }
	    return false; 
	};
	
	var callback = function(params){
	    //console.log(params);

	    var select = params.scores.filter(function(s){
		return s.select;
	    })[0];

	    console.log(select);

	    shopService.update_score(
		shop.id,
		angular.isDefined(select) ? select.id : -1)
		.then(function(result){
		    console.log(result);
		
		if (result.ecode === 0){
		    shop.score_id = angular.isDefined(select) ? select.id : -1;
		    shop.score = diablo_get_object(shop.score_id, $scope.scores);
		    dialog.response(true, "积分方案", "编辑积分方案成功！！");
		} else {
		    dialog.response(
			false,
			"积分方案",
			"编辑积分方案失败："
			    + shopService.error[result.ecode]);
		}
	    });
	};  
	
	angular.forEach($scope.scores, function(s){
	    s.select = false;
	    if (s.id === shop.score_id){
		s.select = true;
	    }
	});

	console.log($scope.scores);
	
	dialog.edit_with_modal(
	    "score.html",
	    undefined,
	    callback,
	    undefined,
	    {shop: shop,
	     scores: $scope.scores,
	     check_only: check_only,
	     check_same: check_same});
    };
};

function regionDetailCtrlProvide($scope, shopService, diabloUtilsService){
    var dialog = diabloUtilsService;

    $scope.refresh = function(){
	shopService.list_region().then(function(data){
	    console.log(data); 
	    $scope.regions = angular.copy(data);
	    diablo_order($scope.regions);
	});	
    };

    $scope.refresh();

    $scope.new_region = function(){
	var callback = function(params){
	    console.log(params);

	    shopService.add_region(params.name, params.comment).then(function(state){
		if (state.ecode === 0){
		    dialog.response_with_callback
		    (true,
		     "新增区域",
		     "新增区域 [" + params.name + "] 成功",
		     undefined,
		     function() {$scope.refresh()});
		} else {
		    dialog.response(
			false,
			"新增区域",
			"新增区域失败：" + shopService.error[state.ecode]);
		}
	    });
	};

	dialog.edit_with_modal("new-region.html", undefined, callback, undefined, {});
    };

    $scope.update_region = function(region){
	dialog.response(false, "修改区域", "修改区域失败：暂不支持此操作！！")
    };
	
};

define(["shopApp"], function(app){
    app.controller("newShopCtrl", newShopCtrlProvide);
    app.controller("shopDetailCtrl", shopDetailCtrlProvide);
    app.controller("regionDetailCtrl", regionDetailCtrlProvide);
});
