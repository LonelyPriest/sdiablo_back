"use strict";

define(["angular", "angular-router", "angular-resource", 
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern",
        "diablo-utils", "diablo-filter"], rightUserConfig);

 function rightUserConfig(angular){
     var rightUserApp = angular.module(
	 "rightUserApp",
	 ['ui.bootstrap', 'ngRoute', 'ngResource', 'diabloPattern', 'diabloUtils',
	  'diabloAuthenApp', 'rightApp'])
	 .config(function($httpProvider, authenProvider){
	     $httpProvider.interceptors.push(authenProvider.interceptor); 
	 });


     rightUserApp.config(['$routeProvider', function($routeProvider){
	 //console.log($rootScope);
	 $routeProvider.
	     when('/account_user/account_detail', {
		 templateUrl: '/private/right/html/account_user_detail.html',
		 controller: 'accountUserDetailCtrl'
	     }).
	     when('/account_user/account_new', {
		 templateUrl: '/private/right/html/account_user_new.html',
		 controller: 'accountUserNewCtrl'
	     }).
	     when('/role_user/role_new', {
		 templateUrl: '/private/right/html/role_user_new.html',
		 controller: 'roleUserNewCtrl'
	     }).
	     when('/role_user/role_detail', {
		 templateUrl: '/private/right/html/role_user_detail.html',
		 controller: 'roleUserDetailCtrl'
	     }). 
	     otherwise({
		 templateUrl: '/private/right/html/account_user_detail.html',
		 controller: 'accountUserDetailCtrl'
	     }) 
     }]);

     // rightUserApp.controller("rightUserCtrl", function($scope, $location){
	 
     // }); 

     rightUserApp.controller("loginOutCtrl", function($scope, $resource){
	 $scope.home = function () {
	     // console.log('home');
	     diablo_login_out($resource)
	 };
     });

     return rightUserApp;
 };

