'use strict'

define(["angular", "angular-router", "angular-resource",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], baseConfig);

function baseConfig(angular){
    var baseApp = angular.module(
	'baseApp', [
	    'ui.bootstrap', 'ngRoute', 'ngResource',
	    'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	    'userApp', 'wprintApp'])
	.config(function($httpProvider, authenProvider){
	    $httpProvider.interceptors.push(authenProvider.interceptor); 
	});

    baseApp.config(['$routeProvider', function($routeProvider){	
	var user = {"user": function(userService){
	    return userService()}};

	var ctype = {"filterCType": function(diabloFilter) {
	    return diabloFilter.list_good_ctype()}};
	
	$routeProvider.
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
	    when('/printer/detect', {
		templateUrl: '/private/base/html/printer_detect.html',
		controller: 'printerDetectCtrl'
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
	    when('/setting/std_executive', {
		templateUrl: '/private/base/html/good_executive_standard.html',
		controller: 'goodStdStandardCtrl',
		resolve: angular.extend({})
	    }).
	    when('/setting/safety_category', {
		templateUrl: '/private/base/html/good_safety_category.html',
		controller: 'goodSafetyCategoryCtrl',
		resolve: angular.extend({})
	    }).
	    when('/setting/fabric', {
		templateUrl: '/private/base/html/good_fabric.html',
		controller: 'goodFabricCtrl',
		resolve: angular.extend({})
	    }).
	    when('/setting/ctype', {
		templateUrl: '/private/base/html/good_ctype.html',
		controller: 'goodCTypeCtrl',
		resolve: angular.extend({})
	    }).
	    when('/setting/size_spec', {
		templateUrl: '/private/base/html/size_spec.html',
		controller: 'goodSizeSpecCtrl',
		resolve: angular.extend({}, ctype)
	    }).
	    when('/setting/print_template', {
		templateUrl: '/private/base/html/print_template.html',
		controller: 'goodPrintTemplateCtrl',
		resolve: angular.extend({})
	    }).
	    when('/passwd', {
		templateUrl: '/private/base/html/reset_password.html',
		controller: 'resetPasswdCtrl'
	    }).
	    when('/setting/soft_stock_fix', {
		templateUrl: '/private/base/html/download_stock_fix.html',
		controller: 'downloadStockFixCtrl'
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
		      8005: "该标准已存在，请重新输入！！",
		      8006: "该安全类别已存在，请重新输入！！",
		      8007: "该面料已存在，请重新输入！！",
		      8008: "该大类已存在，请重新输入！！",
		      8009: "该大类所对应的尺码规格已存在，请重新输入！！",
		      8010: "尺码名称不规范，请重新输入尺码！！",
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

	this.delete_setting = function(shop) {
	    return http.save({operation: 'delete_shop_setting'}, {shop:shop}).$promise;
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
	};

	/*
	 * good standard
	 */
	this.add_std_executive = function(e) {
	    return http.save({operation: 'add_std_executive'}, e).$promise;
	};

	this.list_std_executive = function(){
	    return http.query({operation: 'list_std_executive'}).$promise;
	};

	this.update_std_executive = function(e) {
	    return http.save({operation: 'update_std_executive'}, e).$promise;
	};

	// safety category
	this.add_safety_category = function(c) {
	    return http.save({operation: 'add_safety_category'}, c).$promise;
	};

	this.list_safety_category = function(){
	    return http.query({operation: 'list_safety_category'}).$promise;
	};

	this.update_safety_category = function(c) {
	    return http.save({operation: 'update_safety_category'}, c).$promise;
	};

	// fabric
	this.add_fabric = function(f) {
	    return http.save({operation: 'add_fabric'}, f).$promise;
	};

	this.list_fabric = function(){
	    return http.query({operation: 'list_fabric'}).$promise;
	};

	this.update_fabric = function(f) {
	    return http.save({operation: 'update_fabric'}, f).$promise;
	};

	// ctype
	this.add_ctype = function(c) {
	    return http.save({operation: 'add_ctype'}, c).$promise;
	};

	this.list_ctype = function(){
	    return http.query({operation: 'list_ctype'}).$promise;
	};

	this.update_ctype = function(c) {
	    return http.save({operation: 'update_ctype'}, c).$promise;
	};

	// size spec
	this.add_size_spec = function(s) {
	    return http.save({operation: 'add_size_spec'}, s).$promise;
	};

	this.list_size_spec = function(){
	    return http.query({operation: 'list_size_spec'}).$promise;
	};

	this.update_size_spec = function(s) {
	    return http.save({operation: 'update_size_spec'}, s).$promise;
	};
	
	// print template
	this.create_print_template = function() {
	    return http.save({operation: 'create_print_template'}, {}).$promise;
	};
	
	this.update_print_template = function(t) {
	    return http.save({operation: 'update_print_template'}, t).$promise;
	};
	
	this.list_print_template = function(){
	    return http.query({operation: 'list_print_template'}).$promise;
	};

	// download
	this.download_stock_fix = function() {
	    return http.save({operation: 'download_stock_fix'}, {}).$promise;
	};
	
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






