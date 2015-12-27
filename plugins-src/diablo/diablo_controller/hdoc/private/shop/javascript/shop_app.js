"use strict";

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

    var charge = {"filterCharge": function(diabloNormalFilter){
	return diabloNormalFilter.get_charge()}};
    
    // var repo = {"filterRepo": function(diabloNormalFilter){
    // 	return diabloNormalFilter.get_repo()}};
    
    $routeProvider.
	when('/shop/shop_detail', {
	    templateUrl: '/private/shop/html/shop_detail.html',
            controller: 'shopDetailCtrl',
	    resolve: angular.extend(
		{}, promotion, shop_promotion, charge, employee, user)
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
		{}, promotion, shop_promotion, charge, employee, user)
        })
}]);


// shopApp.service("shopService", function($resource, dateFilter){
    
// });
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

    this.update_charge = function(shopId, charge) {
	return shop.save(
	    {operation: "update_shop"},
	    {id:shopId, charge:charge}).$promise;
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
	    {name: repo.name,
	     address: repo.address,
	     repo: repo.repo.id}).$promise;
    };

    this.list_badrepo = function(){
	return shop.query({operation: "list_badrepo"}).$promise;
    };

    this.add_promotion = function(type, shopId, promotion){
	return shop.save(
	    {operation: "add_shop_promotion"},
	    {type: type,
	     shop: shopId,
	     promotion: promotion}).$promise;
    };
});
