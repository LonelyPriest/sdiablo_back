"use strict";
var userApp = angular.module("userApp", ['ngResource']); 
userApp.factory("userService", function($resource, $q){
    var _user = $resource("/right/:operation", {operation: '@operation'});

    var _shops     = [];
    var _rights    = [];
    var _loginType = undefined;
    var _loginRetailer = -1; 
    var _loginEmployee = undefined;
    var _loginShop = -1;
    
    var sort = function(){
	var shops = _shops;
	return {
    	    right: _rights,
	    type:  _loginType,
	    shop:  _shops,
	    loginRetailer: _loginRetailer,
	    loginEmployee: _loginEmployee,
	    loginShop: _loginShop,

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
    	    availableShopIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
			 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // shops, include the shop that bind to the repository but not repository
	    shopIds: function(){
		var ids   = [];
		angular.forEach(shops, function(s){
                    if (s.type === 0 && !in_array(ids, s.shop_id)){
                        if (s.shop_id === _loginShop){
                            ids.splice(0, 0, s.shop_id);
                        } else {
                            ids.push(s.shop_id);
                        }
                    }
                }) 
		return ids;
	    }(),

	    badrepoIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if (s.type === 2 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // repository only
	    repoIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    if (s.type === 1 && !in_array(ids, s.shop_id)){
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // shops only, include the shop bind to repository
	    sortShops: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var shop = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 0 && !in_array(sort, shop)){
			if (shop.id === _loginShop){
                            sort.splice(0, 0, shop);
                        } else {
                            sort.push(shop);
                        }
		    }
		})
		return sort;
	    }(),

	    // repository only
	    sortRepoes: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var repo = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 1 && !in_array(sort, repo)){
			sort.push(repo); 
		    }
		})
		return sort;
	    }(),

	    sortBadRepoes: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var shop = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				py:diablo_pinyin(s.name)};
		    if (s.type === 2 && !in_array(sort, shop)){
			sort.push(shop); 
		    }
		})
		return sort;
	    }(),

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
	    sortAvailabeShops: function(){
		var sort = []; 
		angular.forEach(shops, function(s){
		    var repo = {id:  s.shop_id,
				name:s.name,
				repo:s.repo_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				py:diablo_pinyin(s.name)};

		    if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
			 && !in_array(sort, repo)){
			if (s.shop_id === _loginShop){
                            sort.splice(0, 0, repo);
                        } else {
                            sort.push(repo);
                        }
		    } 
		})
		return sort;
	    }() 
	}
    };

    return function(){
	if (_shops.length !== 0
	    && _rights !== 0
	    && angular.isDefined(_loginType)){
	    return sort();
	    
	} else {
	    return _user.get({operation: "get_login_user_info"}).$promise.then(function(result){
		// console.log(result);
		_shops     = result.shop;
		_rights    = result.right;
		_loginType = result.type;
		_loginRetailer = result.login_retailer;
		_loginEmployee = result.login_employee;
		_loginShop = result.login_shop;
		return sort();
    	    });
	}
	
    }; 
    
});
