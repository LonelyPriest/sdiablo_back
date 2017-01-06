'use strict'

define(["wreportApp"], function(app){
    app.factory("wreportCommService", wreportCommServiceProvide);
});

function wreportCommServiceProvide(){

    var _employees = [];
    var _retailers = [];
    var _user;
    var _base;

    var service = {};
    service.set_employee = function(employees){
	_employees = employees;
    };
    service.get_employee = function(){
	return _employees;
    };

    service.set_retailer = function(retailers){
	_retailers =retailers;
    };
    service.get_retailer = function(){
	return _retailers;
    };

    service.set_user = function(user){
	_user = user;
    };
    service.get_user = function(){
	return _user;
    };
    
    service.get_shop_id = function(){
	return _user.shopIds.length === 0 ? undefined : _user.shopIds;
    };
    
    service.get_sort_shop = function(){
	return _user.sortShops;
    };

    service.set_base_setting = function(base){
	_base = base;
    };

    service.get_base_setting = function(){
	return _base;
    };

    return service;
};
