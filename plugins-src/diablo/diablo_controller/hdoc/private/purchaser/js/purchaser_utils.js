var stockUtils = function(){
    return {
	typeahead: function(shop, base){
	    return diablo_base_setting(
		"qtypeahead", shop, base, parseInt, diablo_backend);
	},

	reject_negative: function(shop, base){
	    return diablo_base_setting(
		"reject_negative", shop, base, parseInt, diablo_no);
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd")); 
	},

	prompt_limit: function(shop, base){
	    return diablo_base_setting(
		"prompt", shop, base, parseInt, 8);
	},

	history_stock: function(shop, base){
	    return diablo_base_setting(
		"h_stock_edit", shop, base, parseInt, diablo_no);
	},

	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "，" + brand + "，" + type;
	    var prompt = name + "," + diablo_pinyin(name); 
	    return {name: name, prompt: prompt};
	},

	calc_row: function(price, discount, count){
	    if ( 0 === stockUtils.to_float(price)
		 || 0 === stockUtils.to_float(discount)
		 || 0 === stockUtils.to_float(count)){
		return 0;
	    }
	    
	    return diablo_float_mul(
		diablo_price(price, discount),
		stockUtils.to_integer(count));
	},

	/*
	 * get stock price info: org_price, ediscount
	 * 0: get org_price by ediscount
	 * 1: get ediscount by org_price
	 */
	calc_stock_orgprice_info: function(tag_price, stock, direction){
	    // console.log(org_price, ediscount, tag_price);
	    if (!stock.hasOwnProperty('org_price')
	       || !stock.hasOwnProperty('ediscount')){
		return stock;
	    } 

	    if (0 === direction){
		if (0 === stockUtils.to_float(stock.ediscount)
		    || 0 === stockUtils.to_float(tag_price)){
		    return stock;
		}
		
		stock.org_price =  diablo_price(
		    stockUtils.to_float(stock.tag_price),
		    stockUtils.to_float(stock.ediscount));
	    } else {
		if ( 0 === stockUtils.to_float(stock.org_price)
		     || 0 === stockUtils.to_float(tag_price)){
		    return stock;
		}
		
		stock.ediscount = diablo_discount(
		    stockUtils.to_float(stock.org_price),
		    stockUtils.to_float(stock.tag_price));
	    }

	    return stock;
	},

	to_float: function(v) {
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	start_time_of_second: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		dateFun.default_start_time(now));
	}
	    
	//
    }
}();


var stockDraft = function(storage, shop, employee, model){
    this.storage  = storage;
    this.shop     = shop;
    this.employee = employee;
    this.model    = model;
    if (diablo_dkey_stock_price === this.model)
	this.key = "wx-" + this.shop.toString() + "-" + this.employee.toString();
};

stockDraft.prototype.key = function() {
    return this.key;
    // if (diablo_dkey_stock_price === this.model)
    // 	this.key = "wx-" + this.shop.toString() + "-" + this.employee.toString();
};

stockDraft.prototype.keys = function(){
    if (diablo_dkey_stock_price === this.model){
	var re = /^wx-[0-9-]+$/;
	var keys = this.storage.keys(); 
	return keys.filter(function(k){
	    return re.test(k)
	});
    }
},

stockDraft.prototype.save = function(resources){
    var key = this.key;
    var now = $.now();
    this.storage.set(key, {t:now, v:resources});
},

stockDraft.prototype.list = function(draftFilter){
    var keys = this.keys();
    return draftFilter(keys); 
},

stockDraft.prototype.remove = function(){
    this.storage.remove(this.key);
},

stockDraft.prototype.select = function(dialog, template, draftFilter, selectCallback){
    var storage = this.storage;
    
    var callback = function(params){
	var select_draft = params.drafts.filter(function(d){
	    return angular.isDefined(d.select) && d.select
	})[0];
	
	console.log(storage);
	var one = storage.get(select_draft.sn); 
	if (angular.isDefined(one) && null !== one){
	    selectCallback(select_draft, one.v);
	} 
    };

    var drafts = this.list(draftFilter); 
    dialog.edit_with_modal(
	template, undefined, callback, undefined,
	{drafts:drafts,
	 valid: function(drafts){
	     for (var i=0, l=drafts.length; i<l; i++){
		 if (angular.isDefined(drafts[i].select) && drafts[i].select){
		     return true;
		 }
	     } 
	     return false;
	 },
	 select: function(drafts, d){
	     for (var i=0, l=drafts.length; i<l; i++){
		 if (d.sn !== drafts[i].sn){
		     drafts[i].select = false;
		 }
	     }
	 }
	});
} 

    

