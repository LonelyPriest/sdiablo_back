
var rightAuthen = {
    account: {
	_master: 1,
	_user: 2
    },

    root_right : {
    	_shop     : 40000,
	_rainbow  : 800000,
	_wsale    : 90000,
	_stock    : 100000,
	_good     : 140000,
	_firm     : 110000,
	_retailer : 30000
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
	    show_orgprice: rightAuthen.root_right._rainbow + 4
	}
    },

    good_action: function(){
	return {
	    update_w_good : rightAuthen.root_right._good + 3,
	    delete_w_good : rightAuthen.root_right._good + 4,
	    new_promotion:  rightAuthen.root_right._good + 11 
	}
    },

    wsale_action: function(){
	return {
	    update_w_sale: rightAuthen.root_right._wsale + 5,
	    check_w_sale:  rightAuthen.root_right._wsale + 6,
	    update_w_sale_price: rightAuthen.root_right._wsale + 10
	}
    },

    stock_action: function(){
	return {
	    delete_w_stock: rightAuthen.root_right._stock + 5,
	    update_w_stock: rightAuthen.root_right._stock + 6,
	    check_w_stock:  rightAuthen.root_right._stock + 13,
	    update_w_stock_batch: rightAuthen.root_right._stock + 15,
	    update_price_of_w_stock_reject: rightAuthen.root_right._stock + 23,
	    reset_barcode: rightAuthen.root_right._stock + 26,
	    set_w_stock_promotion: rightAuthen.root_right._stock + 14,
	    
	    print_w_stock_new: rightAuthen.root_right._stock + 27,
	    print_stock_transfer: rightAuthen.root_right._stock + 28,
	    print_w_barcode: rightAuthen.root_right._stock + 29,
	    
	    cancel_stock_transfer: rightAuthen.root_right._stock + 20,
	    gift_w_stock: rightAuthen.root_right._stock + 30,

	    print_w_stock_new_note: rightAuthen.root_right._stock + 31,
	    
	    update_tprice_on_stock_in: rightAuthen.root_right._stock + 32,
	    update_oprice_on_stock_in: rightAuthen.root_right._stock + 33,
	    bill_firm_on_stock_in:     rightAuthen.root_right._stock + 34

	}
    },

    retailer_action: function(){
	return {
	    delete_retailer   :rightAuthen.root_right._retailer + 2, 
	    reset_password    :rightAuthen.root_right._retailer + 14,
	    update_score      :rightAuthen.root_right._retailer + 17,
	    export_retailer   :rightAuthen.root_right._retailer + 21,
	    query_balance     :rightAuthen.root_right._retailer + 22,
	    update_phone      :rightAuthen.root_right._retailer + 23,
	    set_withdraw      :rightAuthen.root_right._retailer + 24,
	    add_card_good     :rightAuthen.root_right._retailer + 28,
	    delete_card_good  :rightAuthen.root_right._retailer + 30,
	    update_level      :rightAuthen.root_right._retailer + 33,
	    syn_score_ticket  :rightAuthen.root_right._retailer + 34,
	    print_retailer    :rightAuthen.root_right._retailer + 35
	}
    },

    firm_action: function() {
	return {
	    firm_profit: rightAuthen.root_right._firm + 14,
	    firm_profit_export: rightAuthen.root_right._firm + 15
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

    authen_master: function(user_type){
	return user_type === rightAuthen.account._master;
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

var diabloAuthen = function(userType, userRight, userShopRight) {
    this.userType = userType;
    this.userRight = userRight;
    this.userShopRight = userShopRight;
    this.master = rightAuthen.authen_master(userType);
};

/*
 * rainbow
 */
diabloAuthen.prototype.authenRainbow = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.rainbow_action()[action], this.userRight);
};

/*
 * stock
 */
diabloAuthen.prototype.authenStock = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.stock_action()[action], this.userRight);
};

diabloAuthen.prototype.authenStockByShop = function(action) {
    return rightAuthen.authen_shop_action(
	this.userType, rightAuthen.stock_action()[action], this.userShopRight);
};

// diabloAuthen.prototype.master = function() {
//     return rightAuthen.authen_master(userType);
// };

/*
 * sale
 */
diabloAuthen.prototype.authenSaleByShop = function(action) {
    return rightAuthen.authen_shop_action(
	this.userType, rightAuthen.wsale_action()[action], this.userShopRight);
};


diabloAuthen.prototype.authenSale = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.wsale_action()[action], this.userRight);
};
/*
 * good
 */
 
diabloAuthen.prototype.authenGood = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.good_action()[action], this.userRight);
};

diabloAuthen.prototype.showOrgprice = function() {
    return this.authenRainbow('show_orgprice');
};

/*
 * stock action
 */
diabloAuthen.prototype.billFirmOnStockIn = function() {
    return this.authenStock('bill_firm_on_stock_in');
};

diabloAuthen.prototype.printBarcode = function() {
    return this.authenStock('print_w_barcode');
};

diabloAuthen.prototype.printStockIn = function() {
    return this.authenStock('print_w_stock_new');
};

diabloAuthen.prototype.printStockNote = function() {
    return this.authenStock('print_w_stock_new_note');
};


diabloAuthen.prototype.updateStock = function() {
    return this.authenStockByShop('update_w_stock');
};


diabloAuthen.prototype.checkStock = function() {
    return this.authenStockByShop('check_w_stock');
};

diabloAuthen.prototype.deleteStock = function() {
    return this.authenStockByShop('delete_w_stock');
};

diabloAuthen.prototype.updateTagPrice = function() {
    return this.authenStock('update_tprice_on_stock_in');
};

diabloAuthen.prototype.updateOrgPrice = function() {
    return this.authenStock('update_oprice_on_stock_in');
};

diabloAuthen.prototype.updateOrgPriceOnStockOut = function () {
    return this.authenStock('update_price_of_w_stock_reject');
};

/*
 * Good action
 */
diabloAuthen.prototype.updateGood = function() {
    return this.authenGood('update_w_good');
};

diabloAuthen.prototype.deleteGood = function() {
    return this.authenGood('delete_w_good');
};


/*
 * Raibow action
 */
diabloAuthen.prototype.updateDiscountOnSale = function() {
    return this.authenRainbow('modify_discount_onsale');
};

diabloAuthen.prototype.updatePriceOnSale = function() {
    return this.authenRainbow('modify_price_onsale');
};

/*
 * sale action
 */
diabloAuthen.prototype.updateSale = function() {
    return this.authenSaleByShop('update_w_sale');
};

diabloAuthen.prototype.checkSale = function() {
    return this.authenSaleByShop('check_w_sale');
};

diabloAuthen.prototype.updateOpriceAfterSale = function () {
    return this.authenSale('update_w_sale_price');
};

/*
 * retailre action
 */
diabloAuthen.prototype.authenRetailer = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.retailer_action()[action], this.userRight);
};

diabloAuthen.prototype.authenStockRight = function() {
    return {
	show_orgprice          :this.showOrgprice(),
	bill_firm_on_stock_in  :this.billFirmOnStockIn(),
	master                 :this.master,
	print_w_barcode        :this.printBarcode(),
	update_w_stock         :this.updateStock(), 
	update_tprice          :this.updateTagPrice(),
	update_oprice          :this.updateOrgPrice(),

	check_w_stock          :this.checkStock(),
	delete_w_stock         :this.deleteStock(),
	print_w_stock          :this.printStockIn(),
	print_w_stock_note     :this.printStockNote()
    }
};

diabloAuthen.prototype.authenGoodRight = function() {
    return {
	show_orgprice         :this.showOrgprice(), 
	update_w_good         :this.updateGood(),
	delete_w_good         :this.deleteGood()
	// update_oprice_stock_out :this.updateOrgPriceOnStockOut()
    }
};

diabloAuthen.prototype.authenSaleRight = function() {
    return {
	m_discount :this.updateDiscountOnSale(), 
	m_price    :this.updatePriceOnSale(),
	master     :this.master,

	show_orgprice  :this.showOrgprice(), 
	update_w_sale  :this.updateSale(),
	check_w_sale   :this.checkSale(),
	show_stastic   :this.master,

	update_oprice_after_sale : this.updateOpriceAfterSale()
    }
};


diabloAuthen.prototype.authenRetailerRight = function() {
    return {
	reset_password        :this.authenRetailer('reset_password'),
	delete_retailer       :this.authenRetailer('delete_retailer'),
	update_retailer_score :this.authenRetailer('update_score'),
	export_retailer       :this.authenRetailer('export_retailer'),
	query_balance         :this.authenRetailer('query_balance'),
	update_phone          :this.authenRetailer('update_phone'),
	set_withdraw          :this.authenRetailer('set_withdraw'),
	update_level          :this.authenRetailer('update_level'),
	print_retailer        :this.authenRetailer('print_retailer'),
	master                :this.master
    };
};


