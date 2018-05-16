"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], firmConfig);

function firmConfig(angular){
    var firmApp = angular.module(
	'firmApp',
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('firmApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    }).run(['$route', '$rootScope', '$location', function ($route, $rootScope, $location) {
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
    }]).config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });


    firmApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
    	    return userService()}};

	var brand = {"filterBrand": function(diabloFilter){
	    return diabloFilter.get_brand()}};

	var firm = {"filterFirm": function(diabloFilter){
	    return diabloFilter.get_firm()}};

	var type = {"filterType": function(diabloFilter){
	    return diabloFilter.get_type()}};

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}};
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}};

	var employee = {"filterEmployee": function(diabloFilter){
	    return diabloFilter.get_employee()}};

	var card = {"filterCard": function(diabloNormalFilter){
	    return diabloNormalFilter.get_card()}};
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var region = {"filterRegion": function(diabloNormalFilter){
	    return diabloNormalFilter.get_region()}};
	
	$routeProvider.
	    when('/firm_detail', {
		templateUrl: '/private/firm/html/firm_detail.html',
		controller: 'firmDetailCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/firm_trans/:firm?/:page?', {
		templateUrl: '/private/firm/html/firm_trans.html',
		controller: 'firmTransCtrl',
		resolve: angular.extend({}, brand, firm, employee, region, user, base)
	    }).
	    when('/firm_trans_rsn/:firm?/:rsn?/:ppage?', {
		templateUrl: '/private/firm/html/firm_trans_rsn_detail.html',
		controller: 'firmTransRsnDetailCtrl',
		resolve: angular.extend(
		    {}, brand, firm, employee, s_group, type, color, user, base)
	    }). 
	    when('/new_firm', {
		templateUrl: '/private/firm/html/new_firm.html',
		controller: 'firmNewCtrl'
	    }).
	    when('/firm_profit', {
		templateUrl: '/private/firm/html/firm_profit.html',
		controller: 'firmAnalysisProfitCtrl',
		resolve: angular.extend({}, firm, region)
	    }).
	    // brand
	    when('/new_brand', {
		templateUrl: '/private/firm/html/new_brand.html',
		controller: 'brandNewCtrl',
		resolve: angular.extend({}, brand, firm) 
	    }).
	    when('/brand_detail', {
		templateUrl: '/private/firm/html/brand_detail.html',
		controller: 'brandDetailCtrl', 
		resolve: angular.extend({}, firm)
	    }).
	    // bill
	    when('/firm/bill/:firm?/:page?', {
		templateUrl: '/private/firm/html/firm_bill_check.html',
		controller: 'firmBillCtrl', 
		resolve: angular.extend({}, card, employee, user)
	    }).
	    when('/firm/bill_detail', {
		templateUrl: '/private/firm/html/firm_bill_detail.html',
		controller: 'firmBillDetailCtrl', 
		resolve: angular.extend({}, firm, card, employee, user, base)
	    }).
	    when('/firm/bill_update/:rsn?', {
		templateUrl: '/private/firm/html/firm_bill_update.html',
		controller: 'firmBillUpdateCtrl',
		resolve: angular.extend({}, firm, card, employee, user)
		// resolve: angular.extend({}, firm, card, employee, user, base)
	    }). 
	    // default
	    otherwise({
		templateUrl: '/private/firm/html/firm_detail.html',
		controller: 'firmDetailCtrl', 
		resolve: angular.extend({}, user)
            })
    }]);

    firmApp.service("firmService", function($resource, dateFilter){    
	// error information
	this.error = {
    	    1601: "厂商创建失败，已存在同样的厂商！！",
	    1604: "一个时间点只能结帐一次，请重新选择结帐时间！！",
	    1605: "该厂商存在入库记录，无法删除，请先删除入库记录后再重新操作！！",
	    1606: "该品牌正在使用，无法删除！！",
	    1699: "修改前后信息一致，请重新编辑修改项！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	// =========================================================================
	this.bill_modes = [{id:0, name:"现金"},
			   {id:1, name:"刷卡"},
			   {id:2, name:"汇款"}];
	
	var http = $resource("/firm/:operation/:id",
    			     {operation: '@operation', id: '@id'});

	this.new_firm = function(firm){
	    return http.save(
		{operation:"new_firm"},
		{name:    firm.name,
		 balance: firm.balance ? parseInt(firm.balance) : 0,
		 mobile:  firm.mobile,
		 address: firm.address,
		 expire:  firm.expire,
		 comment: diablo_set_string(firm.comment)}).$promise
	};

	this.update_firm = function(firm){
	    return http.save({operation: "update_firm"}, firm).$promise;
	}

	this.delete_firm = function(firm){
	    return http.save({operation: "delete_firm"},
			     {firm_id: firm.id}).$promise;
	}

	this.list_firm = function(){
	    return http.query({operation: "list_firm"}).$promise;
	}

	/*
	 * brand
	 */ 
	this.new_brand = function(brand){
	    return http.save(
		{operation:"new_brand"},
		{name:      brand.name,
		 firm:      brand.firm.id,
		 remark:    brand.remark}).$promise
	};

	this.list_brand = function(){
	    return http.query({operation: "list_brand"}).$promise;
	};

	this.update_brand = function(brand){
	    return http.save(
		{operation:"update_brand"},
		{name:      brand.name,
		 bid:       brand.id,
		 firm:      brand.firm,
		 remark:    brand.remark}).$promise
	};

	this.delete_brand = function(brandId) {
	    return http.delete({operation:"delete_brand", id:brandId}).$promise;
	};

	this.bill_w_firm = function(bill){
	    return http.save({operation:"bill_w_firm"}, bill).$promise
	};

	this.filter_bill_detail = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_firm_bill_detail"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.get_bill_by_rsn = function(rsn){
	    return http.save({operation:"get_firm_bill"}, {rsn:rsn}).$promise;
	};

	this.update_bill_w_firm = function(bill){
	    return http.save({operation:"update_bill_w_firm"}, bill).$promise
	};

	this.check_bill_w_firm = function(rsn){
	    return http.save({operation:"check_w_firm_bill"},
			     {rsn:rsn,
			      mode: diablo_check}).$promise;
	};

	this.uncheck_bill_w_firm = function(rsn){
	    return http.save({operation:"check_w_firm_bill"},
			     {rsn:rsn,
			      mode: diablo_uncheck}).$promise;
	};

	this.abandon_bill_w_firm = function(rsn){
	    return http.save({operation:"abandon_w_firm_bill"}, {rsn:rsn}).$promise;
	};

	this.export_w_firm = function(){
	    return http.save({operation: "export_w_firm"}).$promise;
	};

	this.export_firm_profit = function(mode, condition) {
	    return http.save({operation: "export_firm_profit"},
			     {mode      :mode,
			      condition :condition}).$promise;
	};

	this.analysis_profit_w_firm = function(mode, match, condition, currentPage, itemsPerpage){
	    return http.save({operation: "analysis_profit_w_firm"},
			     {mode:      mode,
			      match:     angular.isDefined(match) ? match.op : undefined,
			      condition: condition,
			      page:      currentPage,
			      count:     itemsPerpage}).$promise;
	};

	/*
	 * transaction
	 */
	var http_p = $resource("/purchaser/:operation/:id",
    			       {operation: '@operation', id: '@id'});
	
	this.filter_w_inventory_new = function(match, fields, currentPage, itemsPerpage){
	    return http_p.save(
		{operation: "filter_w_inventory_new"},
		{mode:   diablo_sort_by_date,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.check_w_inventory_new = function(rsn){
	    return http_p.save({operation: "check_w_inventory"},
			       {rsn: rsn, mode:diablo_check}).$promise;
	};

	this.uncheck_w_inventory_new = function(rsn){
	    return http_p.save({operation: "check_w_inventory"},
			       {rsn: rsn,
				mode: diablo_uncheck}).$promise;
	};

	this.comment_w_inventory_new = function(rsn, comment){
	    return http_p.save({operation: "comment_w_inventory_new"},
			       {rsn:rsn, comment:comment}).$promise;
	};

	this.modify_w_inventory_new_balance = function(rsn, balance) {
	    return http_p.save({operation: "modify_w_inventory_new_balance"},
			       {rsn:rsn, balance:balance}).$promise;
	};

	this.filter_w_inventory_new_rsn_group = function(match, fields, currentPage, itemsPerpage){
	    return http_p.save(
		{operation: "filter_w_inventory_new_rsn_group"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_inventory_new_rsn_detail = function(inv){
	    return http_p.save(
		{operation: "w_inventory_new_rsn_detail"},
		{rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand}).$promise;
	};

	this.export_firm_trans = function (e_type, condition, mode) {
	    return http_p.save(
		{operation: "w_inventory_export"},
		{condition: condition, e_type:e_type, mode:mode}).$promise;
	};
	
    });
    
    firmApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {
	    diablo_login_out($resource)
	};
    });

    // diablo_remove_app_storage(/^firmApp.*$/);

    return firmApp;
};

    




