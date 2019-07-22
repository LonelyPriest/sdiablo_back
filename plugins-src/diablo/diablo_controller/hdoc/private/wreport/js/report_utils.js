var reportUtils = function(){
    return {
	filter_by_shop: function(shopId, stastics){
	    if (!angular.isArray(stastics)) return {};
	    
	    var s = stastics.filter(function(s){
		if (s.hasOwnProperty("shop_id")){
		    return s.shop_id === shopId; 
		} else if (s.hasOwnProperty("fshop_id")){
		    return s.fshop_id === shopId; 
		}
		else if (s.hasOwnProperty("tshop_id")){
		    return s.tshop_id === shopId; 
		} else {
		    return false;
		} 
	    });

	    if (s.length === 1) return s[0];
	    else return {};
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

	calc_profit: function(m1, m2){
	    if ( angular.isUndefined(m1) || angular.isUndefined(m2)) return undefined;
	    if ( 0 === m1 || 0 === m2 ) return 0;
	    return parseFloat(diablo_float_div((m2 - m1), m2) * 100).toFixed(1);
	},

	start_time: function(base, datetime, dateFun){
	    return diablo_base_setting(
		"qtime_start",
		    -1,
		base,
		diablo_set_date,
		dateFun.default_start_time(datetime));
	},

	print_mode: function(shop, base){
	    return diablo_base_setting(
		"ptype", shop, base, parseInt, diablo_backend);
	},

	sale_mode:function(shop, base) {
	    return diablo_base_setting("p_balance", shop, base, function(s) {return s}, diablo_sale_mode);
	},

	print_protocal: function(shop, base){
	    var p = diablo_base_setting("pum", shop, base, function(s) {return s}, diablo_print_num);
	    return reportUtils.to_integer(p.charAt(2)); 
	},

	f_sub:function(v1, v2){
	    return diablo_rdight(reportUtils.to_float(v1) - reportUtils.to_float(v2), 2);
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

	correct_condition_with_shop: function(condition, shopIds, shops) {
	    if (reportUtils.to_integer(condition.region) === 0){
		if (angular.isUndefined(condition.shop) || condition.shop.length === 0){
		    condition.shop = shopIds === 0 ? undefined : shopIds; 
		}
	    } else {
		if (angular.isArray(condition.shop) && condition.shop.length !== 0){
		    delete condition.region;
		}
		else {
		    condition.shop = shops.filter(function(s){
			return s.region === condition.region;
		    }).map(function(s) { return s.id});
		}
	    }
	    
	    return condition;
	}

    }
}();


var reportPrint = function(){
    return {
	init: function(LODOP) {
	    LODOP.PRINT_INIT("task_print_shift");
	    LODOP.SET_PRINT_PAGESIZE(3, 580, 0, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	},
	
	gen_head: function(LODOP, shop, employee, date, account){
	    // wsalePrint.init(LODOP);
	    
	    var hLine = 5;
	    
	    LODOP.ADD_PRINT_TEXT(hLine, 0, 218, 30, shop); 
	    LODOP.SET_PRINT_STYLEA(0,"FontSize",13);
	    // LODOP.SET_PRINT_STYLEA(0, "Alignment", 2); 
	    LODOP.SET_PRINT_STYLEA(0,"bold",1);
	    // LODOP.SET_PRINT_STYLEA(1,"Horient",2); 
	    hLine += 35;

	    LODOP.ADD_PRINT_TEXT(
		hLine,
		0,
		178,
		30,
		"交班报表-" + angular.isDefined(account) ? account : diablo_empty_string); 
	    LODOP.SET_PRINT_STYLEA(0,"FontSize",10);
	    LODOP.SET_PRINT_STYLEA(0, "Alignment", 2); 
	    LODOP.SET_PRINT_STYLEA(0,"bold",1);
	    // LODOP.SET_PRINT_STYLEA(1,"Horient",2); 
	    hLine += 35;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,"58mm",20,"日期：" + date);
	    hLine += 15
	    
	    if (employee.id !== diablo_invalid_employee){
		LODOP.ADD_PRINT_TEXT(hLine,0,"58mm",20, "店员：" + employee.name);
		hLine += 15
	    }

	    // hLine += 15
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    // LODOP.ADD_PRINT_TEXT(hLine,45,135,20, "营业状况");
	    // LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1);
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1); 
	    return hLine;
	},

	gen_body: function(hLine, LODOP, sale, extra){
	    console.log(sale);
	    var to_i = reportUtils.to_integer;
	    var to_f = reportUtils.to_float;

	    hLine += 15; 
	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine-6,45 + 10,135,20, "营业状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    hLine += 10;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"数量  ：" + to_i(sale.sell_total));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"营业额：" + to_f(sale.sell_balance));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"现金  ：" + to_f(sale.sell_cash));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"刷卡  ：" + to_f(sale.sell_card)); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"微信  ：" + to_f(sale.sell_wxin));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"支付宝：" + to_f(sale.sell_aliPay)); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"提现  ：" + to_f(sale.sell_draw)); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"电子券：" + to_f(sale.sell_ticket)); 
	    hLine += 25;

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine-6,45+10,135,20, "充值状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"充值：" + to_f(sale.charge_balance));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"现金：" + to_f(sale.charge_cash));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"刷卡：" + to_f(sale.charge_card));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"微信：" + to_f(sale.charge_wxin));
	    hLine += 25; 
	    
	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine-6,45+10,135,20, "库存状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1); 
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"昨日库存：" + to_i(sale.lstock));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"当前库存：" + to_i(sale.cstock));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"入库数量：" + to_i(sale.stock_in));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"退货数量：" + to_i(sale.stock_out)); 
	    hLine += 25;

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine-6,45+10,135,20, "备用金");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备用金：" + to_f(extra.pcash));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备用金余额：" + to_f(extra.pcash_in));
	    hLine += 25;
	    LODOP.ADD_PRINT_TEXT(
		hLine,0,178,20,"备注：" + extra.comment ? extra.comment : ""); 
	    
	    return hLine;
	},

	gen_note: function(LODOP, top, notes) {
	    top += 15; 

	    var left = 0;
	    var width = 219; // inch, 5.8 / 2.45 * 96
	    var font = 20; // height of font
	    
	    LODOP.ADD_PRINT_LINE(top,0,top,45,0,1);
	    LODOP.ADD_PRINT_TEXT(top-6,45+10,135,font, "货品统计");
	    LODOP.ADD_PRINT_LINE(top,135,top,178,0,1); 

	    top += 25;
	    
	    LODOP.ADD_PRINT_TEXT(top, left, 60, font, "款号");
	    LODOP.ADD_PRINT_TEXT(top, left + 60, 35, font, "单价");
	    // LODOP.ADD_PRINT_TEXT(top, left + 95, 35, font, "数量");
	    LODOP.ADD_PRINT_TEXT(top, left + 95, 45, font, "颜色");
	    LODOP.ADD_PRINT_TEXT(top, left + 140, width - left - 140, font, "尺码");
	    
	    angular.forEach(notes, function(ns) {
		top += 15; 
		LODOP.ADD_PRINT_TEXT(top, left, 60, font, ns.style_number); 
		LODOP.ADD_PRINT_TEXT(top, left + 60, 35, font, ns.tag_price.toString() );
		// LODOP.ADD_PRINT_TEXT(top, left + 95, 35, font, n.total);
		
		top += 15 ; 
		LODOP.ADD_PRINT_TEXT(top, left, 70, font, ns.brand);
		LODOP.ADD_PRINT_TEXT(top, left + 65, 35, font, ns.total.toString() );

		// console.log(ns);
		if (ns.note.length !== 0) {
		    top -= 15;
		    LODOP.ADD_PRINT_TEXT(top, left + 95, 45, font, ns.note[0].color);
		    LODOP.ADD_PRINT_TEXT(
			top, left + 140, width - left - 140, font, ns.note[0].size); 
		}

		for (var i=1, l=ns.note.length; i<l; i++) {
		    top += 15;
		    var ne = ns.note[i];
		    LODOP.ADD_PRINT_TEXT(top, left + 95, 45, font, ne.color);
		    LODOP.ADD_PRINT_TEXT(top, left + 140, width - left - 140, font, ne.size);
		}

		if (ns.note.length > 1)
		    top += 5; 
		else if (ns.note.length === 1)
		    top += 20; 
	    });

	},
	
	start_print: function(LODOP){
	    // LODOP.SET_PRINT_PAGESIZE(3,"58mm",50,""); 
	    // LODOP.PREVIEW();
	    LODOP.PRINT();
	}
    }
}();
