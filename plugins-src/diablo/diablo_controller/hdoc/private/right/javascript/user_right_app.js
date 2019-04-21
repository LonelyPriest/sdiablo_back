"use strict";

var userApp = angular.module("userApp", ['ngResource']); 
userApp.factory("userService", function($resource, $q){
    var _user = $resource("/right/:operation", {operation: '@operation'});
    // console.log(_user);
    
    var _shops     = [];
    var _rights    = [];
    var _loginType = undefined;
    var _loginRetailer = -1; 
    var _loginEmployee = undefined;
    var _loginShop = -1;
    var _sdays = 0;
    var _loginName = undefined;
    var _cookie = undefined;
    
    var sort = function(){
	var shops = _shops;
	return {
    	    right: _rights,
	    type:  _loginType,
	    shop:  _shops,
	    loginRetailer: _loginRetailer,
	    loginEmployee: _loginEmployee,
	    loginShop: _loginShop,
	    loginName: _loginName,
	    sdays: _sdays,
	    cookie: _cookie,

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
    	    availableShopIds: function(){
		var ids   = []; 
		angular.forEach(shops, function(s){
		    // if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
		    // 	 && !in_array(ids, s.shop_id))
		    if (!in_array(ids, s.shop_id)) {
			ids.push(s.shop_id);
		    }
		})
		return ids;
	    }(),

	    // shops, include the shop that bind to the repository but not repository
	    shopIds: function(){
		var ids   = [];
		angular.forEach(shops, function(s){
                    if (!in_array(ids, s.shop_id)){
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
		// var ids   = []; 
		// angular.forEach(shops, function(s){
		//     if (s.type === 2 && !in_array(ids, s.shop_id)){
		// 	ids.push(s.shop_id);
		//     }
		// })
		// return ids;
		return [];
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
		    // console.log(s);
		    var shop = {id:  s.shop_id,
				name:s.name,
				addr:s.addr,
				type:s.type,
				// repo:s.repo_id,
				region: s.region_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				bcode_friend: s.bcode_friend,
				bcode_pay: s.bcode_pay,
				py:diablo_pinyin(s.name)};
		    if (!in_array(sort, shop)){
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
				addr:s.addr,
				// repo:s.repo_id,
				type: s.type,
				region: s.region_id,
				charge_id: s.charge_id,
				score_id: s.score_id,
				bcode_friend: s.bcode_friend,
				bcode_pay: s.bcode_pay,
				py:diablo_pinyin(s.name)};
		    if (s.type === 1 && !in_array(sort, repo)){
			sort.push(repo); 
		    }
		})
		return sort;
	    }(),

	    sortBadRepoes: function(){
		// var sort = []; 
		// angular.forEach(shops, function(s){
		//     var shop = {id:  s.shop_id,
		// 		name:s.name,
		// 		repo:s.repo_id,
		// 		charge_id: s.charge_id,
		// 		score_id: s.score_id,
		// 		py:diablo_pinyin(s.name)};
		//     if (s.type === 2 && !in_array(sort, shop)){
		// 	sort.push(shop); 
		//     }
		// })
		// return sort;
		return [];
	    }(),

	    // shops exclude the shop that bind to the repository,
	    // or repository itself
	    sortAvailabeShops: function(){
		// var sort = []; 
		// angular.forEach(shops, function(s){
		//     var repo = {id:  s.shop_id,
		// 		name:s.name,
		// 		addr:s.addr,
		// 		repo:s.repo_id,
		// 		charge_id: s.charge_id,
		// 		score_id: s.score_id,
		// 		region: s.region_id,
		// 		bcode_friend: s.bcode_friend,
		// 		bcode_pay: s.bcode_pay,
		// 		py:diablo_pinyin(s.name)};

		//     if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
		// 	 && !in_array(sort, repo)){
		// 	if (s.shop_id === _loginShop){
                //             sort.splice(0, 0, repo);
                //         } else {
                //             sort.push(repo);
                //         }
		//     } 
		// })
		// return sort;
		return [];
	    }() 
	}
    };

    return function(){
	// console.log(_userCache.get('login_user'));
	// if (_shops.length !== 0
	//     && _rights !== 0
	//     && angular.isDefined(_loginType)){
	//     return sort(); 
	// } 
	var cookie  = 'login-' + diablo_get_cookie("qzg_dyty_session"); 
	var storage = localStorage.getItem(cookie);
	if (angular.isDefined(storage) && storage !== null) {
	    return JSON.parse(storage);
	} 
	else {
	    return _user.get({operation: "get_login_user_info"}).$promise.then(function(result){
		// console.log(result);
		_shops         = result.shop;
		_rights        = result.right;
		_loginType     = result.type;
		_loginRetailer = result.login_retailer;
		_loginEmployee = result.login_employee;
		_loginShop     = result.login_shop;
		_loginName     = result.login_name;
		_sdays         = result.sdays;
		_cookie        = cookie;
		var            cache = sort();

		var re  = /^login-.*$/; 
		for (var key in localStorage){
		    // console.log(key);
		    if (re.test(key)) localStorage.removeItem(key);
		}
		
		localStorage.setItem(cookie, JSON.stringify(cache));
		return cache;
		// var cache      = sort();
		// _userCache.put('login_user', sort());
		// console.log(_userCache.get('login_user'));
		// return _userCache.get('login_user');
    	    });
	}
	
    }; 
    
});
