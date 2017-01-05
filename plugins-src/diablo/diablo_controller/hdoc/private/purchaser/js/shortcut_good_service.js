'use strict'

function shortCutGoodServiceProvide() {
    
    var _brands      = [];
    var _firms       = [];
    var _types       = [];
    var _sizeGroups  = [];
    var _colors      = [];
    var _color_types = [];
    var _base        = [];
    var _promotions  = [];
    
    var service      = {};

    service.set_brand = function(brands){
	_brands = brands;
    }; 
    service.get_brand = function(){
	return _brands;
    };


    service.set_firm = function(firms) {
	_firms = firms;
    };
    service.get_firm = function(firms){
	return _firms;
    };


    service.set_type = function(types){
	_types = types;
    };
    service.get_type = function(){
	return _types;
    };


    service.set_size_group = function(gs){
	_sizeGroups = gs;
    };
    service.get_size_group = function(){
	return _sizeGroups;
    };

    service.set_color = function(colors){
	_colors = colors;
    };
    service.get_color = function(){
	return _colors;
    };

    service.set_color_type = function(types){
	_color_types = types;
    };
    service.get_color_type = function(){
	return _color_types;
    };
    
    
    service.set_base = function(base){
	_base = base;
    };
    service.get_base = function(){
	return _base;
    };


    service.set_promotion = function(ps){
	_promotions = ps;
    };
    service.get_promotion = function(){
	return _promotions;
    };

    return service;
};

define (["purchaserApp"], function(app){
    app.factory("shortCutGoodService", shortCutGoodServiceProvide);
});

