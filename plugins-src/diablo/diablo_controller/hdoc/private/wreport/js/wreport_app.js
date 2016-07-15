var wreportApp = angular.module(
    "wreportApp", ['ngRoute', 'ngResource', 'diabloPattern',
		   'diabloUtils', 'userApp', 'diabloFilterApp',
		   'diabloNormalFilterApp', 'diabloAuthenApp', 'fsm',
		   'ui.bootstrap', 'wgoodApp'])
    .config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor);
    });

wreportApp.config(['$routeProvider', function($routeProvider){
    var user = {"user": function(userService){
    	return userService()}};

    var retailer = {"filterRetailer": function(diabloFilter){
	return diabloFilter.get_wretailer()}};
    
    var employee = {"filterEmployee": function(diabloNormalFilter){
	return diabloNormalFilter.get_employee()}};

    var base = {"base": function(diabloNormalFilter){
	return diabloNormalFilter.get_base_setting()}};
    
    $routeProvider.
    	when('/wreport_daily', {
    	    templateUrl: '/private/wreport/html/wreport_daily.html',
            controller: 'wreportDailyCtrl',
    	    resolve: angular.extend({}, employee, user, base)
    	}). 
	when('/stastic', {
    	    templateUrl: '/private/wreport/html/stock_stastic.html',
            controller: 'stockStasticCtrl',
    	    resolve: angular.extend({}, employee, user, base)
	}). 
	when('/switch_shift', {
    	    templateUrl: '/private/wreport/html/shift_report.html',
            controller: 'switchShiftCtrl',
    	    resolve: angular.extend({}, employee, user)
	}). 
    	otherwise({
	    templateUrl: '/private/wreport/html/wreport_daily.html',
            controller: 'wreportDailyCtrl',
    	    resolve: angular.extend({}, employee, user, base) 
        })
}]);

wreportApp.service("wreportService", function($resource, dateFilter){
    this.error = {
	2401: "店铺打印机不存在或打印处理暂停状态！！",
	2411: "打印机编号错误！！",
	2412: "服务器处理订单失败！！",
	2413: "打印内容太长！！",
	2414: "打印请求参数错误！！",
	2415: "打印请求超时，请稍后再试或联系服务人员！！",
	2416: "未知原因，请系统服务人员！！",

	2417: "发送打印请求失败，请确保网络通畅！！",

	2418: "打印机打印失败，请联系服务人员查找原因！！",
	2419: "打印机未连接！！",
	2420: "打印机缺纸！！",
	2421: "打印状态未知，请联系服务人员！！",
	2422: "打印机连接设备不存在，请检查设备编号是否正确！！",

	9001: "数据库操作失败，请联系服务人员！！"};
    
    var http = $resource("/wreport/:operation/:type",
    			 {operation: '@operation', type: '@type'});
    
    /*
     * restful
     */
    this.daily_report = function(type, condition, itemsPerpage, currentPage){
	// console.log(itemsPerpage, currentPage);
	return http.save({operation: "daily_wreport", type: type},
			 {condition: condition,
			  page:      currentPage,
			  count:     itemsPerpage}).$promise;
    };
    
    this.stock_stastic = function(match, conditions){
	return http.save({operation: "stock_stastic"}, conditions).$promise;
    };

    this.print_wreport = function(type, content) {
	return http.save({operation: "print_wreport"},
                         {type:type, content: content}).$promise;
    };

    this.h_daily_report = function(conditions, itemsPerpage, currentPage){
	return http.save({operation: "h_daily_wreport"},
			 {condition: conditions,
			  page: currentPage,
			  count: itemsPerpage}).$promise;
    };

    this.switch_shift_report = function(conditions, itemsPerpage, currentPage){
	return http.save({operation: "switch_shift_report"},
			 {condition: conditions,
			  page: currentPage,
			  count: itemsPerpage}).$promise;
    };

    this.syn_daily_report = function(conditions){
	return http.save({operation: "syn_daily_report"}, conditions).$promise;
    };
    
});

wreportApp.controller("wreportCtrl", function($scope){
});

wreportApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
