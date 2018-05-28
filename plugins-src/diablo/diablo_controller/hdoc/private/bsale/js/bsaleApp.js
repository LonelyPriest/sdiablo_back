"use strict";

define(["angular",
	"angular-router",
	"angular-resource",
	"angular-local-storage", 
        "angular-ui-bootstrap",
	"diablo-authen",
	"diablo-pattern",
	"diablo-user-right",
        "diablo-authen-right",
	"diablo-utils",
	"diablo-filter"], bsaleConfig);


function bsaleConfig(angular){
    var bsaleApp = angular.module(
	'bsaleApp',
	['ui.bootstrap',
	 'ngRoute',
	 'ngResource',
	 'LocalStorageModule',
	 'diabloAuthenApp',
	 'diabloPattern',
	 'diabloUtils',
	 'diabloFilterApp',
	 'diabloNormalFilterApp',
	 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('bsaleApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    }).config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
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
    }]);
    
    bsaleApp.config(['$routeProvider', function($routeProvider){
	// $locationProvider.html5Mode(true);
	var user = {"user": function(userService){
	    return userService()}}; 

	var brand = {"filterBrand": function(diabloFilter){
	    return diabloFilter.get_brand()}};
	
	var firm = {"filterFirm": function(diabloFilter){
	    return diabloFilter.get_firm()}}; 
	
	var type = {"filterType": function(diabloFilter){
	    return diabloFilter.get_type()}};

	var employee = {"filterEmployee": function(diabloFilter){
	    return diabloFilter.get_employee()}}; 

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}}; 
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}}; 
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}}; 
	
	$routeProvider. 
	    when('/new_bsale', {
		templateUrl: '/private/bsale/html/new_bsale.html',
		controller: 'bsaleNewCtrl',
		resolve: angular.extend(
		    {},
		    user, employee, s_group, brand, type, color, base)
	    }).
	    otherwise({
		templateUrl: '/private/bsale/html/new_bsale.html',
		controller: 'bsaleNewDetailCtrl',
		resolve: angular.extend(
		    {},
		    user, employee, s_group, brand, type, color, base)
            }) 
    }]);

    bsaleApp.service("bsaleService", function($http, $resource, dateFilter){
	
    });

    bsaleApp.controller("baleNewCtrl", bsaleNewProvide);

    bsaleApp.controller("loginOutCtrl", function($scope, $resource, localStorageService){
    	$scope.home = function () {
    	    bsaleUtils.remove_cache_page(localStorageService); 
    	    diablo_login_out($resource);
    	};
    });
    
    return bsaleApp;
};

function bsaleNewProvide(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, bsaleService,
    user, 
    filterEmployee,
    filterSizeGroup, filterType, filterColor, base){
    
};
