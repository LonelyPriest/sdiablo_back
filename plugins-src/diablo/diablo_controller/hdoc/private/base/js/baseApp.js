'use strict'

define(["angular", "angular-router", "angular-resource",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], baseConfig);

function baseConfig(angular){
    var baseApp = angular.module(
	'baseApp', [
	    'ui.bootstrap', 'ngRoute', 'ngResource',
	    'diabloAuthenApp', 'diabloPattern', 'diabloUtils',
	    'userApp', 'wprintApp'])
	.config(function($httpProvider, authenProvider){
	    $httpProvider.interceptors.push(authenProvider.interceptor); 
	});

    baseApp.config(['$routeProvider', function($routeProvider){	
	var user = {"user": function(userService){
	    return userService()}};
	
	$routeProvider.
	    when('/passwd', {
		templateUrl: '/private/base/html/reset_password.html',
		controller: 'resetPasswdCtrl'
	    }).
	    when('/del_data', {
		templateUrl: '/private/base/html/delete_data.html',
		controller: 'delDataCtrl'
	    }).
	    when('/bank/new_bank_card/:cardId?', {
		templateUrl: '/private/base/html/bank_card_new.html',
		controller: 'bankCardNewCtrl'
	    }).
	    when('/bank/bank_card_detail', {
		templateUrl: '/private/base/html/bank_card_detail.html',
		controller: 'bankCardDetailCtrl'
	    }).
	    when('/setting/print_option', {
		templateUrl: '/private/base/html/print_detail.html',
		controller: 'printOptionCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/setting/print_format', {
		templateUrl: '/private/base/html/base_print_format.html',
		controller: 'printFormatCtrl',
		resolve: angular.extend({}, user)
		
	    }). 
	    when('/setting/table_detail', {
		templateUrl: '/private/base/html/table_detail.html',
		controller: 'tableDetailCtrl'
	    }).
	    when('/printer/connect_new', {
		templateUrl: '/private/base/html/base_printer_connect.html',
		controller: 'basePrinterConnectNewCtrl',
		resolve: angular.extend({}, user) 
	    }). 
	    when('/printer/connect_detail', {
		templateUrl: '/private/base/html/base_printer_connect_detail.html',
		controller: 'basePrinterConnectDetailCtrl',
		resolve: angular.extend({}, user) 
	    }).
	    otherwise({
		templateUrl: '/private/base/html/base_printer_connect_detail.html',
		controller: 'basePrinterConnectDetailCtrl',
		resolve: angular.extend({}, user) 
            })
    }]);

    baseApp.service("baseService", function($resource){
	// error
	this.error = {8010: "修改前后信息一致，请重新编辑修改项！！",
		      8001: "该银行卡已存在！！",
		      8002: "该设置项已存在，请选择其它设置项！！",
		      8003: "旧密码不正确，请重新输入！！",
		      8004: "用户权限不足！！",
		      9001: "数据库操作失败，请联系服务人员！！"};

	this.print_setting = 0;
	this.table_setting = 1;

	this.option_names = [
	    {cname: "备注1", ename: "comment1"},
	    {cname: "备注2", ename: "comment2"},
	    {cname: "备注3", ename: "comment3"},
	    {cname: "备注4", ename: "comment4"}];

	this.print_types = [{cname:"前台打印", value: 0},
			    {cname:"后台打印", value: 1}]; 

	this.yes_no = [
	    {cname:"否", value: 0},
	    {cname:"是", value: 1}, 
	];

	this.prompt_types = [{cname:"前台联想", value: 0},
			     {cname:"后台联想", value: 1}]; 

	var http = $resource("/wbase/:operation/:id", {operation: '@operation'},
			     {
				 query_by_post: {method: 'POST', isArray: true}
			     });

	
	this.new_card = function(card){
	    return http.save({operation: 'new_w_bank_card'}, card).$promise;
	};

	this.list_card = function(){
	    return http.query({operation: 'list_w_bank_card'}).$promise; 
	};

	this.update_card = function(card){
	    return http.save({operation: 'update_w_bank_card'},
			     {no:   card.no,
			      bank: card.bank,
			      id:   card.id}).$promise;
	};

	this.delete_card = function(card){
	    return http.save({operation: 'del_w_bank_card'},
			     {id: card.id}).$promise;
	};

	// base
	this.list_setting = function(type){
	    return http.query_by_post({operation: 'list_base_setting'},
				      {type: type}).$promise;
	};

	this.add_setting = function(s){
	    return http.save({operation: 'add_base_setting'}, s).$promise
	};
	
	this.update_setting = function(s){
	    return http.save({operation: 'update_base_setting'},
			     {id:     s.id,
			      ename:  s.ename,
			      value:  s.value,
			      remark: s.remark,
			      shop:   s.shop}).$promise;
	};

	this.add_shop_setting = function(shop) {
	    return http.save({operation: 'add_shop_setting'}, {shop:shop}).$promise;
	};

	/*
	 * passwd
	 */
	this.reset_passwd = function(p){
	    return http.save({operation: 'update_user_passwd'},p).$promise;
	};

	this.delete_expire_data = function(
	    expire_date, delete_stock_data, delete_sell_data){
	    return http.save(
		{operation: 'delete_expire_data'},
		{expire: expire_date,
		 stock: delete_stock_data,
		 sell: delete_sell_data}).$promise;
	};

	var httpGood = $resource("/wgood/:operation/:id",
    				 {operation: '@operation', id: '@id'});
	
	this.list_purchaser_size = function(){
	    return httpGood.query({operation: 'list_w_size'}).$promise;
	};

	var retailerHttp = $resource("/wretailer/:operation", {operation: '@operation'});
	this.list_sys_wretailer = function(){
	    return retailerHttp.query({operation: 'list_sys_wretailer'}).$promise;
	}
	
    });

    // baseApp.controller("baseCtrl", function($scope){
    // });

    baseApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {
	    diablo_login_out($resource)
	}; 
    });

    return baseApp;

};






