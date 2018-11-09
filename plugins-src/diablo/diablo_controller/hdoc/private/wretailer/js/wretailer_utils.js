var retailerUtils = function(){
    return {
	print_mode: function(shop, base){
	    return diablo_base_setting(
		"ptype", shop, base, parseInt, diablo_backend);
	},

	sale_mode:function(shop, base) {
	    return diablo_base_setting("p_balance", shop, base, function(s) {return s}, diablo_sale_mode);
	},

	printer_bill: function(shop, base) {
	    return diablo_base_setting("prn_bill", shop, base, parseInt, diablo_invalid_index);
	},

	print_num: function(shop, base){
	    var p = diablo_base_setting(
		"pum", shop, base, function(s) {return s}, diablo_print_num);
	    return {common: stockUtils.to_integer(p.charAt(0)),
		    swiming: stockUtils.to_integer(p.charAt(1)),
		    protocal: stockUtils.to_integer(p.charAt(2))};
	},
	
	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	to_float: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
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
	    return {id:0, balance:1, consume:2, level:3};
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
    var left = 5;
    var width = 219; // inch, 5.8 / 2.45 * 96 
    var vWidth = width - 5; 
    var hFont = 20; // height of font
    
    return {
	init: function(LODOP) {LODOP.SET_PRINT_PAGESIZE(3, 580, 0, "")},
	    
	gen_head: function(LODOP, shop, rsn, employee, retailer, date){
	    LODOP.ADD_PRINT_TEXT(10, left, vWidth, 30, shop); 
	    LODOP.SET_PRINT_STYLEA(0, "FontSize", 13);
	    LODOP.SET_PRINT_STYLEA(0, "Bold", 1);
	    // LODOP.SET_PRINT_STYLEA(0, "Alignment", 2);

	    var top = 40; 
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "单号：" + rsn); 
	    top += 15; // 55
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "客户：" + retailer);
	    top += 15; // 70
	    LODOP.ADD_PRINT_TEXT(top,  left, vWidth, hFont, "店员：" + employee);
	    top += 15; // 85
	    LODOP.ADD_PRINT_TEXT(top,  left, vWidth, hFont, "日期：" + date); 
	    top += 20; // 105
	    LODOP.ADD_PRINT_LINE(top,  left, top, vWidth, 0, 1);

	    return top;
	},

	gen_body: function(LODOP, top, sale){
	    top += 10;
	    LODOP.ADD_PRINT_TEXT(top, left, 70, hFont, "商品");
	    LODOP.ADD_PRINT_TEXT(top, left + 70, 35, hFont, "单价");
	    LODOP.ADD_PRINT_TEXT(top, left + 105, 35, hFont, "次数");
	    
	    top += 15; 
	    LODOP.ADD_PRINT_TEXT(top, left, 70, hFont, sale.good_name);
	    top += 15;
	    LODOP.ADD_PRINT_TEXT(top, left + 70, 35, hFont, sale.tag_price);
	    LODOP.ADD_PRINT_TEXT(top, left + 105, 35, hFont, sale.count);

	    top += 15;
	    LODOP.ADD_PRINT_LINE(top, left, top, vWidth, 0, 1);

	    return top;
	},

	gen_stastic: function(LODOP, top, card, comment){
	    top += 10;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "会员项目：" + card.cname);
	    
	    top += 15;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "消费类型：" + card.rule.name);
	    
	    var l = "";
	    if(card.rule.id === diablo_theoretic_charge) 
		l += "剩余次数：" + card.left_time;
	    else
		l += "过期日期：" + card.expire_date;
	    
	    console.log(l);
	    top += 15;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, l);
	    
	    top += 15;
	    l = "备注：" + (comment ? comment : "");
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, l);

	    top += 15;
	    LODOP.ADD_PRINT_LINE(top, left, top, vWidth, 0, 1);

	    top += 5;
	    return top;
	},

	gen_foot: function(LODOP, top, date) {
	    top += 5;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "月/季/年卡类限每天只可消费一次");
	    top += 15;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "谢谢惠顾！！"); 
	    top += 15;
	    LODOP.ADD_PRINT_TEXT(top, left, vWidth, hFont, "打印日期：" + date);
	},
	
	start_print: function(LODOP){
	    // LODOP.PREVIEW();
	    LODOP.PRINT();
	} 
    }
}();
