"use strict";

define(["angular", "angular-router", "angular-resource", 
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern",
        "diablo-utils", "diablo-filter"], rightMerchantConfig);

function rightMerchantConfig (angular){
    var rightMerchantApp = angular.module(
	"rightMerchantApp",
	['ui.bootstrap', 'ngRoute', 'ngResource', 'diabloPattern', 'diabloUtils',
	 'diabloAuthenApp', "rightApp"]
    ).config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });
    

    rightMerchantApp.config(['$routeProvider', function($routeProvider){
	//console.log($rootScope);
	$routeProvider. 
	    when('/account_merchant/account_new', {
		templateUrl: '/private/right/html/account_merchant_new.html',
		controller: 'accountMerchantNewCtrl'
	    }).
	    when('/account_merchant/account_detail', {
		templateUrl: '/private/right/html/account_merchant_detail.html',
		controller: 'accountMerchantDetailCtrl'
	    }).
	    when('/role_merchant/role_detail', {
		templateUrl: '/private/right/html/role_merchant_detail.html',
		controller: 'roleMerchantDetailCtrl'
	    }).
	    when('/role_merchant/role_new', {
		templateUrl: '/private/right/html/role_merchant_new.html',
		controller: 'roleMerchantNewCtrl'
	    }).
	    otherwise({
		templateUrl: '/private/right/html/account_merchant_detail.html',
		controller: 'accountMerchantDetailCtrl' 
	    }) 
    }]);

    rightMerchantApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {
	    // console.log('home');
	    diablo_login_out($resource)
	};
    });

    return rightMerchantApp;
};




// rightMerchantApp.controller("rightMechantCtrl", function($scope, $location){
    
// });

