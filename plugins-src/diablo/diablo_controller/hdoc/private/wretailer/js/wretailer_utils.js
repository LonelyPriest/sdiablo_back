var retailerUtils = function(){
    return {
	print_mode: function(shop, base){
	    return diablo_base_setting(
		"ptype", shop, base, parseInt, diablo_backend);
	},
	
	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	to_float: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	}, 

	to_decimal:function(v){
	    return diablo_rdight(v, 2);
	},
	
	first_day_of_month: function(){
	    var now = new Date(); 
	    var year = now.getFullYear();
	    var month = now.getMonth();

	    return {
		first:new Date(year, month, 1).getTime(), current:now.getTime()};
	},

	months: function(){
	    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
	},

	date_of_month: function() {
	    return [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31];
	},

	to_decimal:function(v){
	    return diablo_rdight(v, 2);
	},

	match_retailer_phone: function(viewValue, filterFun){
	    if (diablo_is_digit_string(viewValue)){
		if (viewValue.length < 4) return;
		else if (viewValue.startsWith("9"))
		    return filterFun.match_retailer_phone(viewValue, 3);
		else 
		    return filterFun.match_retailer_phone(viewValue, 0);
	    } else if (diablo_is_letter_string(viewValue)){
		return filterFun.match_retailer_phone(viewValue, 1);
	    } else if (diablo_is_chinese_string(viewValue)){
		return filterFun.match_retailer_phone(viewValue, 2);
	    } else {
		return;
	    } 
	}, 

	cache_page_condition: function(
	    storage, key, conditions, start_time, end_time, current_page, datetime){
	    storage.remove(key);
	    storage.set(key, {filter:conditions,
			      start_time:diablo_get_time(start_time),
			      end_time: diablo_get_time(end_time),
			      page: current_page,
			      t: datetime});
	},

	remove_cache_page: function(storage, key){
	    storage.remove(key);
	},
	
	order_fields: function(){
	    return {id:0, balance:1, consume:2}
	},

	authen: function(user_type, right_tree, action) {
	    return rightAuthen.authen(
		user_type,
		rightAuthen.retailer_action()[action],
		right_tree);
	}

	//
    }
}();

var retailerPrint = function(){
    return {
	gen_head: function(LODOP, retailer, shop, employee, date){
	    var hLine = 5;

	    // var left = diablo_round((178 - (shop.length * diablo_print_px * 2)) / 2);
	    // console.log(diablo_round(left))
	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 30, shop);
	    LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
	    LODOP.SET_PRINT_STYLEA(1,"bold",1);
	    LODOP.SET_PRINT_STYLEA(1,"Horient",2); 
	    hLine += 35;

	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 30, "（" + retailer + "-充值凭证）"); 
	    // LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
	    // LODOP.SET_PRINT_STYLEA(1,"bold",1);
	    LODOP.SET_PRINT_STYLEA(2,"Horient",2); 
	    hLine += 35;

	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, "经手人：" + employee);
	    hLine += 15
	    
	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, "充值日期：" + date);
	    hLine += 15
	    
	    return hLine;
	},

	gen_body: function(hLine, LODOP, charge){
	    var to_i = retailerUtils.to_integer;

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1); 
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"充值金额：" + charge.cbalance);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"赠送金额：" + charge.sbalance); 
	    hLine += 15;

	    var comment = comment ? comment : "";
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备注："+ comment); 
	    
	    return hLine;
	},
	
	start_print: function(LODOP){
	    LODOP.SET_PRINT_PAGESIZE(3, 178, 100, ""); 
	    // LODOP.PREVIEW();
	    LODOP.PRINT();
	},

	// first_day_of_month: function(){
	//     var now = new Date(); 
	//     var year = now.getFullYear();
	//     var month = now.getMonth();

	//     return {
	// 	first:new Date(year, month, 1).getTime(), current:now.getTime()};
	// }
    }
}();
