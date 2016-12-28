var merchantApp = angular.module(
    "merchantApp", ['ngRoute', 'ngResource', 'ui.bootstrap', 'diabloAuthenApp',
		    'diabloPattern', 'diabloUtils'])
// .config(diablo_authen);
.config(function($httpProvider, authenProvider){
    // $httpProvider.responseInterceptors.push(authenProvider.interceptor);
    $httpProvider.interceptors.push(authenProvider.interceptor); 
});

merchantApp.config(['$routeProvider', function($routeProvider){
    $routeProvider. 
	when('/merchant_detail', {
	    templateUrl: '/private/merchant/html/merchant_detail.html',
            controller: 'merchantDetailCtrl'
	}).
	when('/merchant_new', {
	    templateUrl: '/private/merchant/html/merchant_new.html',
            controller: 'merchantNewCtrl'
	}).
	when('/merchant_sms_rate', {
	    templateUrl: '/private/merchant/html/merchant_sms.html',
            controller: 'merchantSMSCtrl'
	}).
	when('/merchant_sms_center', {
	    templateUrl: '/private/merchant/html/merchant_sms_center.html',
            controller: 'merchantSMSCenterCtrl'
	}).
	otherwise({
	    templateUrl: '/private/merchant/html/merchant_detail.html',
            controller: 'merchantDetailCtrl'
            // templateUrl: '/private/member/html/member_index.html',
            // controller: 'memberCtrl'
        })
}]);


merchantApp.service("merchantService", function($resource, dateFilter){
    this.types = [{name:"saler", chinese: "零售", id: 0},
		  {name: "wholesaler", chinese: "批发", id: 1}];
		    
    // error information
    this.error = {
	1201: "商家创建失败，已存在同样的商家名称！！",
	1202: "删除商家失败，请先删除该商家对应的所有帐户！！",
	1203: "商家费率信息已建立！！",
	1299: "商家修改前后信息一致，无需修改！！",
	9001: "数据库操作失败，请联系服务人员！！"};

    
    this.get_type = function(id){
	for(var i=0, l=this.types.length; i<l; i++){
	    if(this.types[i].id === id){
		return this.types[i];
	    }
	}
    };
    
    // =========================================================================    
    var merchant = $resource("/merchant/:operation/:id",
    			 {operation: '@operation', id: '@id'});
    // var members = $resource("/member/:operation/:number");

    this.list = function(){
	return merchant.query({operation: "list_merchant"})};

    // this.list_w_merchant = function(){
    // 	return merchant.query({operation: "list_w_merchant"}).$promise;
    // };

    this.query = function(merchantId){
	return merchant.get(
	    {operation: "get_merchant", id: merchantId}
	)};

    this.add = function(one){
	console.log(one);
	return merchant.save(
	    {operation: "new_merchant"},
	    {name:      one.name,
	     type:      one.type.id,
	     owner:     one.owner,
	     address:   one.address,
	     mobile:    one.mobile
	    }
	)};

    this.destroy = function(one){
	return merchant.delete(
	    {operation: "delete_merchant", id: one.id}
	)};

    this.edit = function(one){
	return merchant.save(
	    {operation: "update_merchant", id: one.id},
	    {mobile:    one.mobile}
	)};

    this.list_sms = function(){
	return merchant.query({operation: "list_merchant_sms"}).$promise;
    };

    this.new_rate = function(merchantId, rate){
	return merchant.save(
	    {operation: "new_sms_rate"},
	    {merchant: merchantId, rate: rate}).$promise;
    };

    this.charge_sms = function(merchantId, balance) {
	return merchant.save(
	    {operation: "charge_sms"},
	    {merchant: merchantId, balance: balance}).$promise;
    };

    this.list_sms_center = function(){
	return merchant.query({operation: "list_merchant_sms_center"}).$promise;
    };
});


merchantApp.controller("merchantDetailCtrl", function(
    $scope, $routeParams, diabloUtilsService, merchantService){
    var dialog = diabloUtilsService;
    
    $scope.refresh = function(){
	merchantService.list().$promise.then(function(merchants){
	    console.log(merchants);
	    angular.forEach(merchants, function(m){
		m.type_name = merchantService.get_type(m.type).chinese;
	    })
	    
	    $scope.merchants = merchants;
	    diablo_order($scope.merchants);
	})
    };

    $scope.refresh();
    
    $scope.goto_page = diablo_goto_page;

    // update
    $scope.update_merchant = function(merchant){
	// console.log(merchant); 
	var callback = function(params){
	    console.log(params);

	    if (angular.equals(merchant, params.merchant)){
		diabloUtilsService.response(
		    false, "商家编辑", "商家编辑失败：" + merchantService.error[1299]); 
	    } else{
		merchantService.edit(params.merchant).$promise.then(function(state){
		    console.log(state);
    		    if (state.ecode == 0){
    			diabloUtilsService.response_with_callback(
			    true, "商家编辑", "商家" + merchant.name + "编辑成功！！",
			    $scope, function(){$scope.refresh()})
    		    } else{
    			diabloUtilsService.response(
			    false, "商家编辑",
			    "商家编辑失败：" + merchantService.error[state.ecode]); 
    		    }
		})
	    }
	};
	
	diabloUtilsService.edit_with_modal(
	    "update-merchant.html", undefined, callback, $scope, {merchant: merchant});
    };

    $scope.charge = function(merchant){
	var callback = function(params){
	    console.log(params);
	    merchantService.charge_sms(merchant.id, params.balance).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
	    		true,
			"商家充值",
			"商家 " + merchant.name + " 充值成功！！",
	    		undefined,
			function(){merchant.balance += params.balance});  
		} else {
		    dialog.response(
	    		false,
			"商家充值",
	    		"商家充值失败：" + merchantService.error[result.ecode]);
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "charge-sms.html",
	    undefined,
	    callback,
	    undefined, 
	    {name:merchant.name})
    };

    $scope.delete_merchant = function(merchant){
	diabloUtilsService.response(false, "删除商家", "暂不支持此操作！！", $scope);
    }
});

merchantApp.controller("merchantNewCtrl", function(
    $scope, $location, merchantService, diabloPattern, diabloUtilsService){
    //$scope.merchant = {};
    var dialog = diabloUtilsService;
    
    $scope.merchantTypes = merchantService.types; 
    $scope.pattern_mobile=diabloPattern.mobile;

    $scope.merchant = {type: $scope.merchantTypes[0]};
    
    // new merchant
    $scope.new_merchant = function(){
	console.log($scope.merchant);
	merchantService.add($scope.merchant).$promise.then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	dialog.response_with_callback(
	    	    true, "新增商家",
		    "恭喜你，商家 " + $scope.merchant.name + " 成功创建！！",
	    	    $scope, function(){$location.path("/merchant_detail")}
		);
	    } else{
	    	dialog.response(
	    	    false, "新增商家",
	    	    "新增商家失败：" + merchantService.error[state.ecode]);
	    }
	})
    };
    
    $scope.cancel = function(){
	$location.path("/merchant_detail")
    }; 
});

merchantApp.controller("merchantSMSCtrl", function(
    $scope, $routeParams, diabloUtilsService, merchantService){
    var dialog = diabloUtilsService;
    $scope.goto_page = diablo_goto_page;
    
    $scope.refresh = function(){
    	merchantService.list_sms().then(function(sms){
	    console.log(sms);
	    $scope.sms = sms;
    	})
    };

    $scope.new_sms_rate = function(merchant){
	var callback = function(params){
	    console.log(params);
	    merchantService.new_rate(merchant.id, params.rate).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
	    		true,
			"新增短信费率",
			"商家 " + merchant.name + " 短信费率创建成功！！",
	    		undefined,
			function(){merchant.rate = params.rate});  
		} else {
		    dialog.response(
	    		false,
			"新增短信费率",
	    		"新增短信费率失败：" + merchantService.error[result.ecode]);
		}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-rate.html",
	    undefined,
	    callback,
	    undefined, 
	    {name:merchant.name, rate: merchant.rate})
    };

    $scope.refresh();
});


merchantApp.controller("merchantSMSCenterCtrl", function(
    $scope, $routeParams, diabloUtilsService, merchantService){
    var dialog = diabloUtilsService;
    $scope.goto_page = diablo_goto_page;
    
    $scope.refresh = function(){
    	merchantService.list_sms_center().then(function(centers){
	    console.log(centers);
	    $scope.centers = centers;
    	})
    };

    $scope.refresh();
});

merchantApp.controller("merchantCtrl", function($scope){});

merchantApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	console.log('home');
	diablo_login_out($resource)
    };
});



