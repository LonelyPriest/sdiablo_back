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
	}
    }
}();


var reportPrint = function(){
    return {
	gen_head: function(LODOP, shop, employee, date){
	    var hLine = 5;
	    
	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 30, shop); 
	    LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
	    LODOP.SET_PRINT_STYLEA(1,"bold",1);
	    // LODOP.SET_PRINT_STYLEA(1,"Horient",2); 
	    hLine += 35;

	    LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 30, "（交班报表）"); 
	    LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
	    LODOP.SET_PRINT_STYLEA(1,"bold",1);
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

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine,45,135,20, "营业状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"数量  ：" + sale.total);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"营业额：" + sale.spay);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"现金  ：" + sale.cash);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"刷卡  ：" + sale.card); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"微信  ：" + sale.wxin); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"提现  ：" + sale.draw); 
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"电子券：" + sale.ticket); 
	    hLine += 15;

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine,45,135,20, "充值状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"充值：" + sale.cbalance);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"现金：" + sale.ccash);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"刷卡：" + sale.ccard);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"微信：" + sale.cwxin);
	    hLine += 15; 
	    
	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine,45,135,20, "库存状况");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1); 
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"昨日库存：" + sale.lastStock.total);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"当前库存：" + sale.currentStock.total);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"入库数量：" + to_i(sale.stock_in));
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"退货数量：" + to_i(sale.stock_out)); 
	    hLine += 15;

	    LODOP.ADD_PRINT_LINE(hLine,0,hLine,45,0,1);
	    LODOP.ADD_PRINT_TEXT(hLine,45,135,20, "备用金");
	    LODOP.ADD_PRINT_LINE(hLine,135,hLine,178,0,1); 
	    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
	    hLine += 15;
	    
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备用金：" + extra.pcash);
	    hLine += 15;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备用金余额：" + extra.pcash_in);
	    hLine += 25;
	    LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"备注："
				 + angular.isUndefined(extra.comment)?"":extra.comment); 
	    
	    return hLine;
	},
	
	start_print: function(LODOP){
	    LODOP.SET_PRINT_PAGESIZE(3,"58mm",50,""); 
	    // LODOP.PREVIEW();
	    LODOP.PRINT();
	}
    }
}();
