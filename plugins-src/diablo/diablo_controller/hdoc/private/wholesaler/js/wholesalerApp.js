"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], wholesalerConfig);

function wholesalerConfig(angular) {
    var wholesalerApp = angular.module(
	'wretailerApp',
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wholesalerApp')
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

    wholesalerApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
    	    return userService()}};
	
	$routeProvider. 
	    when('/wholesaler_new', {
		templateUrl: '/private/wholesaler/html/wholesaler_new.html',
		controller: 'wholesalerNewCtrl',
		resolve: angular.extend({}, user) 
	    }). 
	    // default
	    otherwise({
		templateUrl: '/private/wholesaler/html/wholesaler_detail.html',
		controller: 'wholesalerDetailCtrl',
		resolve: angular.extend({})
            })
    }]);

    wholesalerApp.service("wholesalerService", function($resource, dateFilter){
	var http = $resource("/wholesaler/:operation/:id", {operation: '@operation', id: '@id'});

	this.new_wholesaler = function(r){
	    return http.save(
		{operation:"new_wholesaler"},
		{name:     r.name,
		 py:       diablo_pinyin(r.name),
		 mobile:   r.mobile,
		 balance:  diablo_set_float(r.balance),
		 address:  diablo_set_string(r.address),
		 remark:   diablo_set_string(r.remark)
		}).$promise;
	};

	this.delete_wholesaler = function(salerId){
	    return http.delete({operation: "del_wholesaler", id:salerId}).$promise;
	};

	this.update_wholesaler = function(r){
	    return http.save(
		{operation: "update_wholesaler"},
		{id:       r.id,
		 name:     r.name,
		 py:       r.py, 
		 mobile:   r.mobile,
		 address:  r.address,
		 balance:  r.balance,
		 remark:   r.remark, 
		}).$promise;
	}; 

	this.filter_wholesaler = function(mode, match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_wholesaler_detail"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	}; 
    });

    wholesalerApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {diablo_login_out($resource)};
    });

    return wholesalerApp;
};



