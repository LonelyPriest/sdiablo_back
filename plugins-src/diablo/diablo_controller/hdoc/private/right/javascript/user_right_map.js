
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
	_retailer : 30000,
	_bsale    : 160000
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
	    gross_profit:  rightAuthen.root_right._rainbow + 5
	}
    },

    good_action: function(){
	return {
	    update_w_good : rightAuthen.root_right._good + 3,
	    delete_w_good : rightAuthen.root_right._good + 4,
	    new_promotion:  rightAuthen.root_right._good + 11,
	    new_commision:  rightAuthen.root_right._good + 20,
	    del_commision:  rightAuthen.root_right._good + 21,
	    update_commision: rightAuthen.root_right._good + 22,
	}
    },

    wsale_action: function(){
	return {
	    new_w_sale:    rightAuthen.root_right._wsale + 1,
	    reject_w_sale: rightAuthen.root_right._wsale + 2,
	    update_w_sale: rightAuthen.root_right._wsale + 5,
	    check_w_sale:  rightAuthen.root_right._wsale + 6,
	    filter_w_sale_new: rightAuthen.root_right._wsale + 7,
	    update_w_sale_price: rightAuthen.root_right._wsale + 10,
	    export_w_sale_note:  rightAuthen.root_right._wsale + 13,
	    // cost
	    new_daily_cost:    rightAuthen.root_right._wsale + 14,
	    delete_daily_cost: rightAuthen.root_right._wsale + 15,
	    update_daily_cost: rightAuthen.root_right._wsale + 16,
	    export_w_sale_new: rightAuthen.root_right._wsale + 18
	};
    },

    batchsale_action: function() {
	return {
	    new_batch_sale:     rightAuthen.root_right._bsale + 1,
	    reject_batch_sale:  rightAuthen.root_right._bsale + 2,
	    update_batch_sale:  rightAuthen.root_right._bsale + 3,
	    check_batch_sale:   rightAuthen.root_right._bsale + 5,
	    delete_batch_sale:  rightAuthen.root_right._bsale + 6,
	    book_batch_sale:    rightAuthen.root_right._bsale + 8,

	    delete_batch_saler: rightAuthen.root_right._bsale + 11,
	    bill_batch_saler:   rightAuthen.root_right._bsale + 13,

	    print_batch_sale:   rightAuthen.root_right._bsale + 14
	};
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
	    bill_firm_on_stock_in:     rightAuthen.root_right._stock + 34,
	    auto_balance_fix_stock:    rightAuthen.root_right._stock + 38,

	    transfer_w_inventory_fast: rightAuthen.root_right._stock + 44,
	    show_stock_firm_info:   rightAuthen.root_right._stock + 45 
	}
    },

    retailer_action: function(){
	return {
	    delete_retailer   :rightAuthen.root_right._retailer + 2, 
	    reset_password    :rightAuthen.root_right._retailer + 14,
	    delete_recharge   :rightAuthen.root_right._retailer + 15,
	    update_recharge   :rightAuthen.root_right._retailer + 16,
	    update_score      :rightAuthen.root_right._retailer + 17,
	    export_retailer   :rightAuthen.root_right._retailer + 21,
	    query_balance     :rightAuthen.root_right._retailer + 22,
	    update_phone      :rightAuthen.root_right._retailer + 23,
	    set_withdraw      :rightAuthen.root_right._retailer + 24,
	    add_card_good     :rightAuthen.root_right._retailer + 28,
	    delete_card_good  :rightAuthen.root_right._retailer + 30,
	    update_level      :rightAuthen.root_right._retailer + 33,
	    syn_score_ticket  :rightAuthen.root_right._retailer + 34,
	    print_retailer    :rightAuthen.root_right._retailer + 35,
	    page_retailer     :rightAuthen.root_right._retailer + 39,
	    add_gift          :rightAuthen.root_right._retailer + 44,
	    delete_gift       :rightAuthen.root_right._retailer + 45,
	    modify_gift       :rightAuthen.root_right._retailer + 46
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

diabloAuthen.prototype.showGrossProfit = function() {
    return this.authenRainbow('gross_profit');
};

/*
 * sale action
 */
diabloAuthen.prototype.newSale = function() {
    return this.authenSaleByShop('new_w_sale');
};

diabloAuthen.prototype.rejectSale = function() {
    return this.authenSaleByShop('reject_w_sale');
};

diabloAuthen.prototype.updateSale = function() {
    return this.authenSaleByShop('update_w_sale');
};

diabloAuthen.prototype.checkSale = function() {
    return this.authenSaleByShop('check_w_sale');
};

diabloAuthen.prototype.listSale = function() {
    return this.authenSaleByShop('filter_w_sale_new');
};

diabloAuthen.prototype.updateOpriceAfterSale = function () {
    return this.authenSale('update_w_sale_price');
};

diabloAuthen.prototype.exportSaleNote = function() {
    return this.authenSale('export_w_sale_note');
};

diabloAuthen.prototype.exportSaleNew = function() {
    return this.authenSale('export_w_sale_new');
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
	print_w_stock_note     :this.printStockNote(),
	auto_balance_fix_stock :this.authenStock('auto_balance_fix_stock'),
	transfer_w_stock_fast  :this.authenStock('transfer_w_inventory_fast'),
	show_stock_firm_info   :this.authenStock('show_stock_firm_info')
    }
};

diabloAuthen.prototype.authenGoodRight = function() {
    return {
	show_orgprice         :this.showOrgprice(), 
	update_w_good         :this.updateGood(),
	delete_w_good         :this.deleteGood(),
	new_w_promotion       :this.authenGood('new_promotion'),
	new_w_commision       :this.authenGood('new_commision'),
	update_w_commision    :this.authenGood('update_commision'),
	del_w_commision       :this.authenGood('del_commision'),
	show_stock_firm_info   :this.authenStock('show_stock_firm_info')
	// update_oprice_stock_out :this.updateOrgPriceOnStockOut()
    }
};

diabloAuthen.prototype.authenSaleRight = function() {
    return {
	m_discount :this.updateDiscountOnSale(), 
	m_price    :this.updatePriceOnSale(),
	master     :this.master,

	show_orgprice  :this.showOrgprice(),
	new_w_sale     :this.newSale(),
	reject_w_sale  :this.rejectSale(),
	update_w_sale  :this.updateSale(),
	check_w_sale   :this.checkSale(),
	show_stastic   :this.master,
	list_w_sale    :this.listSale(),

	update_oprice_after_sale : this.updateOpriceAfterSale(),
	show_gross_profit:  this.showGrossProfit(),
	export_w_sale_note: this.exportSaleNote(),
	export_w_sale_new:  this.exportSaleNew(),

	// daily cost
	new_daily_cost:    this.authenSale('new_daily_cost'),
	update_daily_cost: this.authenSale('update_daily_cost'),
	delete_daily_cost: this.authenSale('delete_daily_cost'),
	
	show_stock_firm_info   :this.authenStock('show_stock_firm_info')
    }
};


diabloAuthen.prototype.authenRetailerRight = function() {
    return {
	reset_password        :this.authenRetailer('reset_password'),
	delete_retailer       :this.authenRetailer('delete_retailer'),
	delete_recharge       :this.authenRetailer('delete_recharge'),
	update_recharge       :this.authenRetailer('update_recharge'),
	update_retailer_score :this.authenRetailer('update_score'),
	export_retailer       :this.authenRetailer('export_retailer'),
	query_balance         :this.authenRetailer('query_balance'),
	update_phone          :this.authenRetailer('update_phone'),
	set_withdraw          :this.authenRetailer('set_withdraw'),
	update_level          :this.authenRetailer('update_level'),
	print_retailer        :this.authenRetailer('print_retailer'),
	page_retailer         :this.authenRetailer('page_retailer'),
	master                :this.master,

	//gift
	add_gift              :this.authenRetailer('add_gift'),
	delete_gift           :this.authenRetailer('delete_gift'),
	modify_gift           :this.authenRetailer('moidfy_gift'),

	show_orgprice         :this.showOrgprice()
    };
};

diabloAuthen.prototype.authenReportRight = function() {
    return {
	show_orgprice:      this.showOrgprice(),
	show_gross_profit:  this.showGrossProfit(),
	master:             this.master
    };
};


diabloAuthen.prototype.authenBatchSale = function(action) {
    return rightAuthen.authen(
	this.userType, rightAuthen.batchsale_action()[action], this.userRight);
};

diabloAuthen.prototype.authenBatchSaleRight = function() {
    return {
	master         :this.master,
	show_orgprice  :this.showOrgprice(), 
	show_stastic   :this.master,

	new_sale       :this.authenBatchSale('new_batch_sale'),
	reject_sale    :this.authenBatchSale('reject_batch_sale'),
	update_sale    :this.authenBatchSale('update_batch_sale'),
	check_sale     :this.authenBatchSale('check_batch_sale'),
	delete_sale    :this.authenBatchSale('delete_batch_sale'),
	book_sale      :this.authenBatchSale('book_batch_sale'),
	print_sale     :this.authenBatchSale('print_batch_sale'),

	bill_saler     :this.authenBatchSale('bill_batch_saler')
	
    };
};


