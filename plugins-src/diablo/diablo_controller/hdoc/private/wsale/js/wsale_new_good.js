wsaleApp.factory("wsaleGoodService", function(){
    
    var _brands     = [];
    var _firms      = [];
    var _types      = [];
    var _sizeGroups = [];
    var _colors     = [];

    var _shop = -1;

    /*
     * 
     */
    var _employees = [];
    var _retailers = [];
    var _base      = [];
    var _user      = {};
    // var _shops     = [];
    // var _rights    = [];
    
    var service = {};

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

    service.set_shop = function(shop){
	_shop = shop;
    };
    service.get_shop = function(){
	return _shop;
    };

    /*
     *
     */ 
    service.set_employee = function(employees){
	_employees = employees;
    };
    service.get_employee = function(){
	return _employees;
    };

    service.set_retailer = function(retailers){
	_retailers = retailers;
    };
    service.get_retailer = function(){
	return _retailers;
    };

    service.set_base = function(base){
	_base = base;
    };
    service.get_base = function(){
	return _base;
    }; 

    service.set_user = function(right, shops){
	_user.right = right;
	
	// shops exclude the shop that bind to the repository,
	// or repository itself
	_user.availableShopIds = function(){
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
	_user.shopIds = function(){
	    var ids   = []; 
	    angular.forEach(shops, function(s){
		if (s.type === 0 && !in_array(ids, s.shop_id)){
		    ids.push(s.shop_id);
		}
	    })
	    return ids;
	}(),

	// repository only
	_user.repoIds = function(){
	    var ids   = []; 
	    angular.forEach(shops, function(s){
		if (s.type === 1 && !in_array(ids, s.shop_id)){
		    ids.push(s.shop_id);
		}
	    })
	    return ids;
	}(),

	// shops only, include the shop bind to repository
	_user.sortShops = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var shop = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};
		if (s.type === 0 && !in_array(sort, shop)){
		    sort.push(shop); 
		}
	    })
	    return sort;
	}(),

	// repository only
	_user.sortRepoes = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var repo = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};
		if (s.type === 1 && !in_array(sort, repo)){
		    sort.push(repo); 
		}
	    })
	    return sort;
	}(),

	// shops exclude the shop that bind to the repository,
	// or repository itself
	_user.sortAvailabeShops = function(){
	    var sort = []; 
	    angular.forEach(shops, function(s){
		var repo = {id:  s.shop_id,
			    name:s.name,
			    repo:s.repo_id,
			    py:diablo_pinyin(s.name)};

		if ( ((s.type === 0 && s.repo_id === -1) || s.type === 1)
		     && !in_array(sort, repo)){
		    sort.push(repo); 
		} 
	    })
	    return sort;
	}() 
    };
    
    service.get_user = function(){
	return _user;
    };

    return service;
});
