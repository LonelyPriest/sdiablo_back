
var shopApp = angular.module(
    "shopApp", ['ngRoute', 'ngResource', 'diabloPattern',
		'diabloUtils', 'userApp', 'diabloNormalFilterApp',
		'diabloAuthenApp', 'ui.bootstrap'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
    // $httpProvider.responseInterceptors.push(authenProvider.interceptor);
    $httpProvider.interceptors.push(authenProvider.interceptor); 
});

shopApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}};

    var promotion = {"filterPromotion": function(diabloNormalFilter){
	return diabloNormalFilter.get_promotion()}};

    var shop_promotion = {"filterShopPromotion": function(diabloNormalFilter){
	return diabloNormalFilter.get_shop_promotion()}};
    
    // var repo = {"filterRepo": function(diabloNormalFilter){
    // 	return diabloNormalFilter.get_repo()}};
    
    $routeProvider.
	when('/shop/shop_detail', {
	    templateUrl: '/private/shop/html/shop_detail.html',
            controller: 'shopDetailCtrl',
	    resolve: angular.extend(
		{}, promotion, shop_promotion, employee, user)
	}).
	when('/shop/shop_new', {
	    templateUrl: '/private/shop/html/shop_new.html',
            controller: 'newShopCtrl',
	    resolve: angular.extend({}, employee, user)
	}).
	when('/repo/repo_detail', {
	    templateUrl: '/private/shop/html/repo_detail.html',
            controller: 'repoDetailCtrl'
	}).
	when('/repo/repo_new', {
	    templateUrl: '/private/shop/html/repo_new.html',
            controller: 'repoNewCtrl'
	}).
	when('/repo/badrepo_detail', {
	    templateUrl: '/private/shop/html/badrepo_detail.html',
            controller: 'badRepoDetailCtrl',
	    resolve: angular.extend({}, user)
	}).
	when('/repo/badrepo_new', {
	    templateUrl: '/private/shop/html/badrepo_new.html',
            controller: 'badRepoNewCtrl',
	    resolve: angular.extend({}, user)
	}).
	otherwise({
	    templateUrl: '/private/shop/html/shop_detail.html',
            controller: 'shopDetailCtrl' ,
	    resolve: angular.extend(
		{}, promotion, shop_promotion, employee, user)
        })
}]);


shopApp.service("shopService", function($resource, dateFilter){
    // error
    this.error = {1301: "店铺创建失败，已存在同样的店铺名称！！",
		  1302: "仓库创建失败，已存在同样的仓库名称！！",
		  1398: "同类型的促销方案只允许选择一个！！",
		  1399: "修改前后信息一致，请重新编辑修改项！！",
		  9001: "数据库操作失败，请联系服务人员！！"};

    // this.shop_type = [{id:0, name: "店铺"},
    // 		      {id:1, name: "仓库"}];
    
    // =========================================================================    
    var shop = $resource("/shop/:operation/:id",
    			 {operation: '@operation', id: '@id'});
    // var members = $resource("/member/:operation/:number");

    this.list = function(){
	return shop.query({operation: "list_shop"})};

    this.query = function(shop_id){
	return shop.get(
	    {operation: "get_shop", id: shop_id}
	)};

    this.add = function(ashop){
	return shop.save(
	    {operation: "new_shop"},
	    {name:      ashop.name,
	     address:   ashop.address,
	     
	     repo:      angular.isDefined(ashop.repo)
	     && ashop.repo ? ashop.repo.id : undefined,
	     
	     shopowner: angular.isDefined(ashop.shopowner)
	     && ashop.shopowner ? ashop.shopowner.id:undefined,
	     
	     open_date: dateFilter(ashop.openDate, "yyyy-MM-dd")
	    }
	)};

    this.destroy = function(ashop){
	return shop.delete(
	    {operation: "delete_shop", id: ashop.id}
	).$promise;
    };

    this.update = function(ashop){
	return shop.save(
	    {operation: "update_shop"},
	    {id:        ashop.id,
	     name:      ashop.name,
	     address:   ashop.address,
	     shopowner: angular.isDefined(ashop.employee)
	     && ashop.employee ? ashop.employee.id : undefined,
	     repo: angular.isDefined(ashop.repo)
	     && ashop.repo ? ashop.repo.id : undefined}
	).$promise;
    };

    this.new_repo = function(repo){
	return shop.save(
	    {operation: "new_repo"},
	    {name: repo.name, address: repo.address}).$promise;
    };

    this.list_repo = function(){
	return shop.query({operation: "list_repo"}).$promise;
    };

    this.new_badrepo = function(repo){
	return shop.save(
	    {operation: "new_badrepo"},
	    {name: repo.name, address: repo.address,
	     repo: repo.repo.id}).$promise;
    };

    this.list_badrepo = function(){
	return shop.query({operation: "list_badrepo"}).$promise;
    };

    this.add_promotion = function(type, shopId, promotion){
	return shop.save(
	    {operation: "add_shop_promotion"},
	    {type: type, shop: shopId, promotion: promotion}).$promise;
    };
});

shopApp.controller("newShopCtrl", function(
    $scope, shopService, diabloPattern, diabloUtilsService,
    filterEmployee, user){
    $scope.name_address_pattern = diabloPattern.ch_name_address;
    $scope.shop_types = shopService.shop_type;

    $scope.employees = filterEmployee;

    var dialog = diabloUtilsService;
    // employService.list().$promise.then(function(employees){
    // 	console.log(employees);
    // 	$scope.employees =  employees.map(function(e){
    // 	    return {name:e.name, id:e.number, py:diablo_pinyin(e.name)}
    // 	}) 
    // });

    // repo
    $scope.authen_list_repo = false;
    if (rightAuthen.authen(
	rightAuthen.shop_action()["list_repo"], user.right)){
	$scope.authen_list_repo = true; 
    };

    console.log($scope.authen_list_repo);
    

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
});


shopApp.controller("shopDetailCtrl", function(
    $scope, $q, diabloUtilsService, shopService,
    filterPromotion, filterShopPromotion, filterEmployee, user){
    // console.log(filterPromotion);
    // console.log(filterShopPromotion);
    // console.log(filterEmployee);
    // console.log(user);
    
    $scope.promotions      = filterPromotion;
    $scope.shop_promotions = filterShopPromotion.map(
	function(p){return p.pid});
    
    // employees
    $scope.employees   = filterEmployee;
    // $scope.repertories = filterRepo;
    $scope.goto_page   = diablo_goto_page;

    // console.log();
    $scope.authen_list_repo = false; 
    if (rightAuthen.authen("list_repo", user.right)){
	$scope.authen_list_repo = true; 
    };
    

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
	// $scope.shops = [];
	shopService.list().$promise.then(function(shops){
	    console.log(shops);
	    // $scope.shops = angular.copy(shops);
	    // angular.forEach($scope.shops, function(s){
	    // 	$scope.repo = $scope.get_repo(s.repo);
	    // })
	    $scope.shops = [];
	    angular.forEach(shops, function(s){
		// console.log($scope.authen_list_repo);
		if (s.type === diablo_shop){
		    $scope.shops.push({
			id     :      s.id,
			name   :      s.name,
			address:      s.address,
			open_date:    s.open_date,
			repo_id:      s.repo,
			repo:         $scope.authen_list_repo
			    ? $scope.get_repo(s.repo) : undefined,
			shopowner:    s.shopowner,
			shopowner_id: s.shopowner_id})
		}
	    })
	    // shops.filter(function(s){
	    // 	    if (s.type === diablo_shop){
	    // 		return {id     :      s.id,
	    // 			name   :      s.name,
	    // 			address:      s.address,
	    // 			open_date:    s.open_date,
	    // 			repo_id:      s.repo,
	    // 			repo:         $scope.get_repo(s.repo),
	    // 			shopowner:    s.shopowner,
	    // 			shopowner_id: s.shopowner_id}
	    // 	    }
	    // 	});
	    diablo_order($scope.shops);
	    console.log($scope.shops);
	});
    };

    
    // $scope.refresh();
    // wait for loading repo
    deferred.promise.then(function(data){
	$scope.refresh(); 
    })
    
    var dialog = diabloUtilsService;
    // edit 
    $scope.edit_shop = function(old_shop){
	// console.log(shop);
	var callback = function(params){
	    console.log(params);

	    var update = {};
	    for (var o in params.shop){
		if (!angular.equals(params.shop[o], old_shop[o])){
		    update[o] = params.shop[o];
		}
	    }
	    
	    update.id = params.shop.id; 
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
	    // none changed
	    if (angular.equals(new_shop, old_shop)){
		return false;
	    }

	    return true;
	};

	dialog.edit_with_modal(
	    "edit-shop.html", undefined, callback, $scope,
	    {shop:angular.extend(
		old_shop,
		{employee:$scope.get_employee(old_shop.shopowner_id)}),
		// {repo:$scope.get_repo(old_shop.repo)}),
	     employees:        $scope.employees,
	     repertories:      $scope.repertories,
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
	     check_select: check_select})
    };
});



shopApp.controller("shopCtrl", function($scope){});

shopApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});



