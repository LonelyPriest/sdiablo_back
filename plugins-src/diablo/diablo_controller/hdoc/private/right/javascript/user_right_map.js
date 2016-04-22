
var rightAuthen = {
    account: {
	_master: 1,
	_user: 2
    },

    root_right : {
    	_shop: 40000,
	_rainbow: 800000,
	_wsale: 90000,
	_stock: 100000,
	_good: 140000
    },

    shop_action: function(){
    	return {
    	    new_repo     : rightAuthen.root_right._shop + 5,
    	    del_repo     : rightAuthen.root_right._shop + 6,
    	    update_repo  : rightAuthen.root_right._shop + 7,
    	    list_repo    : rightAuthen.root_right._shop + 8
    	}
    },

    rainbow_action: function(){
	return {
	    modify_price_onsale  : rightAuthen.root_right._rainbow + 2,
	    modify_discount_onsale : rightAuthen.root_right._rainbow + 3,
	    show_orgprice: rightAuthen.root_right._rainbow + 4,
	}
    },

    good_action: function(){
	return {
	    update_w_good : rightAuthen.root_right._good + 3,
	    delete_w_good : rightAuthen.root_right._good + 4,
	    lookup_w_good_orgprice: rightAuthen.root_right._good + 15
	}
    },

    wsale_action: function(){
	return {
	    update_w_sale: rightAuthen.root_right._wsale + 5,
	    check_w_sale:  rightAuthen.root_right._wsale + 6
	}
    },

    stock_action: function(){
	return {
	    update_w_stock: rightAuthen.root_right._stock + 6,
	    check_w_stock:  rightAuthen.root_right._stock + 13
	}
    },

    authen_menu: function(authenAction, rights){
    	for (var i = 0, l = rights.length; i < l; i++){
    	    if (rights[i].id === authenAction){
    		return true;
    	    };
    	};
	
    	return false;
    },
    
    authen: function(user_type, authenAction, rights){
	//console.log(authenAction, rights);
	if (user_type === rightAuthen.account._master) {
	    return true;
	};
	
    	for (var i = 0, l = rights.length; i < l; i++){
    	    if (rights[i].id === authenAction){
    		return true;
    	    };
    	};
	
    	return false;
    },

    authen_shop_action: function(user_type, authenAction, shop_rights){
	if (user_type === rightAuthen.account._master) {
	    return true;
	}
	
	for (var i = 0, l = shop_rights.length; i < l; i++){
    	    if (shop_rights[i].func_id === authenAction){
    		return true;
    	    };
    	};

    	return false;
    },

    // show_orgprice: function(userType) {
    // 	return userType === rightAuthen.account._master ? true:false;
    // },

    modify_onsale: function(userType, action, rights){
	if (userType === rightAuthen.account._master) {
	    return true;
	}
	
	return rightAuthen.authen(userType, action, rights);
    }
};
