"use strict";
var wretailerApp = angular.module(
    'wretailerApp',
    ['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
     'wgoodApp', 'diabloAuthenApp', 'diabloFilterApp',
     'diabloNormalFilterApp', 'diabloPattern', 'diabloUtils', 'userApp'])
    .config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wretailerApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    })
    .run(['$route', '$rootScope', '$location',
	  function ($route, $rootScope, $location) {
	      var original = $location.path;
	      $location.path = function (path, reload) {
		  if (reload === false) {
		      var lastRoute = $route.current;
		      var un = $rootScope.$on(
			  '$locationChangeSuccess',
			  function () {
			      $route.current = lastRoute;
			      un();
			  });
		  }
		  return original.apply($location, [path]);
	      };
	  }])
    .config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

wretailerApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};

    var brand = {"filterBrand": function(diabloFilter){
	return diabloFilter.get_brand()}};

    var firm = {"filterFirm": function(diabloFilter){
	return diabloFilter.get_firm()}};

    var type = {"filterType": function(diabloFilter){
	return diabloFilter.get_type()}};
    
    var s_group = {"filterSizeGroup": function(diabloFilter){
	return diabloFilter.get_size_group()}};
    
    var retailer = {"filterRetailer": function(diabloNormalFilter){
	return diabloNormalFilter.get_wretailer()}};
    
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}}; 

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};

    var charge = {"filterCharge": function(diabloNormalFilter){
	return diabloNormalFilter.get_charge()}};
    
    $routeProvider. 
	when('/wretailer_new', {
	    templateUrl: '/private/wretailer/html/wretailer_new.html',
	    controller: 'wretailerNewCtrl',
	    resolve: angular.extend({}, user) 
	}).
	when('/wretailer_detail', {
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, employee, charge, user)
	}).
	when('/wretailer_trans/:retailer?/:page?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans.html',
	    controller: 'wretailerTransCtrl',
	    resolve: angular.extend({}, retailer, employee, user, base)
	}).
	// when('/wretailer_top', {
	//     templateUrl: '/private/wretailer/html/wretailer_top.html',
	//     controller: 'wretailerTopCtrl',
	//     resolve: angular.extend({}, retailer, province, city)
	// }).
	when('/wretailer_trans_rsn/:retailer?/:rsn?/:ppage?', {
	    templateUrl: '/private/wretailer/html/wretailer_trans_rsn_detail.html',
	    controller: 'wretailerTransRsnDetailCtrl',
	    resolve: angular.extend(
		{}, brand, firm, retailer, employee, s_group, type, user, base)
	}).
	// recharge and score
	when('/promotion/recharge_new', {
	    templateUrl: '/private/wretailer/html/recharge_new.html',
	    controller: 'wretailerRechargeNewCtrl'
	}). 
	when('/promotion/recharge_detail', {
	    templateUrl: '/private/wretailer/html/recharge_detail.html',
	    controller: 'wretailerRechargeDetailCtrl'
	}).
	when('/promotion/score_new', {
	    templateUrl: '/private/wretailer/html/score_new.html',
	    controller: 'wretailerScoreNewCtrl'
	}).
	when('/promotion/score_detail', {
	    templateUrl: '/private/wretailer/html/score_detail.html',
	    controller: 'wretailerScoreDetailCtrl'
	}).
	// default
	otherwise({
	    templateUrl: '/private/wretailer/html/wretailer_detail.html',
	    controller: 'wretailerDetailCtrl',
	    resolve: angular.extend({}, employee, charge, user)
        })
}]);

wretailerApp.service("wretailerService", function($resource, dateFilter){
    // error information
    // this._retailers = undefined;

    // this.set_retailer = function(retailers){
    // 	this._retailers = retailers;
    // };

    // this.get_retailer = function(){
    // 	return this._retailers;
    // };
    
    this.error = {
     	2101: "会员信息重复！！",
	2102: "会员密码不正确，请重新输入！！",
	2103: "充值方案名称已存在，请重新输入方案名称!!",
	2104: "积分方案名称已存在，请重新输入方案名称!!",
	9001: "数据库操作失败，请联系服务人员！！"};

    this.score_rules = [
	{name: "钱兑换积分", id:0, remark: "钱到积分"},
	{name: "积分兑换钱", id:1, remakr: "积分到钱"}
	// {name: "金额赠送", id:2, remakr: "交易金额达到目标值赠送一定金额"}
    ]; 

    this.sort_inventory = function(invs, orderSizes){
	// console.log(invs);
	// console.log(orderSizes);
	var in_sort = function(sorts, inv){
	    for(var i=0, l=sorts.length; i<l; i++){
		if(sorts[i].cid === inv.color_id
		   && sorts[i].size === inv.size){
		    sorts[i].count += parseInt(inv.amount);
		    return true;
		}
	    }
	    return false;
	};

	var total = 0;
	var used_sizes  = [];
	var colors = [];
	var sorts = [];
	angular.forEach(invs, function(inv){
	    if (angular.isDefined(inv.amount)){
		total += inv.amount; 
	    };
	    
	    if (!in_array(used_sizes, inv.size)){
		used_sizes.push(inv.size);
	    };
	    
	    var color = {cid:inv.color_id, cname: inv.color};
	    if (!in_array(colors, color)){
		colors.push(color)
	    };

	    if (!in_sort(sorts, inv)){
		sorts.push({
		    cid:inv.color_id, size:inv.size, count:inv.amount})
	    }; 
	});

	// format size
	var order_used_sizes = [];
	if (angular.isArray(orderSizes) && orderSizes.length !== 0){
	    order_used_sizes = orderSizes.filter(function(s){
		return in_array(used_sizes, s); 
	    });
	} else{
	    order_used_sizes = used_sizes;
	};
	

	// console.log(order_used_sizes);
	// console.log(colors);
	// console.log(sorts);
	
	return {total: total,
		size:  order_used_sizes,
		color: colors, sort:sorts};
    };

    
    
    var http = $resource("/wretailer/:operation/:id",
    			 {operation: '@operation', id: '@id'});

    this.new_wretailer = function(r){
	return http.save(
	    {operation:"new_w_retailer"},
	    {name:     r.name,
	     password: diablo_set_string(r.password),
	     balance:  diablo_set_float(r.balance),
	     conusme:  diablo_set_float(r.consume),
	     score:    diablo_set_integer(r.score),
	     mobile:   r.mobile,
	     address:  r.address 
	    }).$promise;
    };

    this.delete_retailer = function(wretailerId){
	return http.delete({
	    operation: "del_w_retailer",
	    id:wretailerId}).$promise;
    };

    this.update_retailer = function(r){
	return http.save(
	    {operation: "update_w_retailer"},
	    {id:       r.id,
	     type:     r.type.id,
	     name:     r.name,
	     balance:  r.balance,
	     mobile:   r.mobile,
	     address:  r.address 
	    }).$promise;
    };

    this.check_retailer_password = function(retailerId, password){
	return http.save(
	    {operation: "check_w_retailer_password"},
	    {id:         retailerId,
	     password:   password}).$promise;
    };

    this.list_retailer = function(){
	return http.query({operation: "list_w_retailer"}).$promise
    };

    var http_wsale = $resource(
	"/wsale/:operation/:id", {operation: '@operation', id: '@id'});
    this.filter_w_sale_new = function(
	match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_new"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.filter_w_sale_rsn_group = function(
	match, fields, currentPage, itemsPerpage){
	return http_wsale.save(
	    {operation: "filter_w_sale_rsn_group"},
	    {match:  angular.isDefined(match) ? match.op : undefined,
	     fields: fields,
	     page:   currentPage,
	     count:  itemsPerpage}).$promise;
    };

    this.w_sale_rsn_detail = function(inv){
	return http_wsale.save(
	    {operation: "w_sale_rsn_detail"},
	    {rsn:inv.rsn,
	     style_number:inv.style_number, brand:inv.brand}).$promise;
    };

    this.check_w_sale_new = function(rsn){
	return http_wsale.save({operation: "check_w_sale"},
			       {rsn: rsn}).$promise;
    };

    /*
     * charge
     */
    this.new_charge_promotion = function(promotion){
	return http.save(
	    {operation: "add_w_retailer_charge"}, promotion).$promise;
    };

    this.list_charge_promotion = function(){
	return http.query({operation:"list_w_retailer_charge"}).$promise;
    };

    this.new_recharge = function(charge){
	return http.save({operation:"new_recharge"}, charge).$promise;
    };

    /*
     * score
     */
    this.new_score_promotion = function(promotion){
	return http.save(
	    {operation: "add_w_retailer_score"}, promotion).$promise;
    };

    this.list_score_promotion = function(){
	return http.query({operation:"list_w_retailer_score"}).$promise;
    };
    
});
