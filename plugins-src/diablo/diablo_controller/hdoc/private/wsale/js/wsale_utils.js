var wsaleUtils = function(){
    var in_sort = function(sorts, sell){
	var found = false;
	for (var i=0, l=sorts.length; i<l; i++){
	    if (sell.style_number === sorts[i].style_number && sell.brand_id === sorts[i].brand_id){
		// sorts[i].total += sell.sell;
		sorts[i].reject += sell.amount;
		if (!in_array(sorts[i].colors_id, sell.color_id)) {
		    sorts[i].colors_id.push(sell.color_id);
		}		
		sorts[i].amounts.push({
		    cid        :sell.color_id,
		    size       :sell.size,
		    sell_count :sell.amount});
		found = true;
		break;
	    } 
	}
	return found; 
    };

    var sort_wsale = function(base, sells) {
	console.log(base);
	var select             = {};
	select.rsn             = base.rsn;
	select.rsn_id          = base.id;
	select.rsn_datetime    = diablo_set_datetime(base.entry_date); 
	select.retailer_id     = base.retailer_id;
	select.shop_id         = base.shop_id; 
	select.employee_id     = base.employ_id; 
	
	select.surplus    = base.balance;
	select.verificate = base.verificate; 
	select.cash       = base.cash;
	select.card       = base.card;
	select.wxin       = base.wxin;
	select.aliPay     = base.aliPay;
	select.withdraw   = base.withdraw;
	select.should_pay = base.should_pay;
	select.g_ticket   = base.g_ticket;
	
	select.comment    = base.comment;
	select.state      = base.state;
	select.total      = base.total;
	select.oil        = base.oil;
	select.score      = base.score;
	
	select.tbatch        = base.tbatch === diablo_invalid_index ? [] : [].concat(base.tbatch);
	select.tcustom       = base.tcustom;
	select.ticket        = base.ticket; 
	select.ticket_score  = base.ticket_score;

	var sorts = [];
	for (var i=0, l=sells.length; i<l; i++){
	    var s = sells[i];
	    if (!in_sort(sorts, s)){
		var add = {$edit:true,
			   $new:false,
			   sizes: [],
			   colors_id: [],
			   amounts:[]};
		add.style_number = s.style_number;

		add.brand_id = s.brand_id; 
		add.type_id  = s.type_id;
		add.type    = s.type;
		add.sex     = s.sex;
		add.season  = s.season;
		add.firm_id = s.firm_id;
		add.year    = s.year;
		add.entry   = s.in_datetime;
		add.free    = s.free;
		add.path    = s.path;

		add.s_group = s.s_group;
		add.free_color_size = s.free === 0 ? true : false;
		add.comment = s.comment;
		
		add.org_price = s.org_price;
		add.tag_price = s.tag_price;
		add.discount  = s.discount;
		add.fprice    = s.fprice;
		add.rprice    = s.rprice;
		add.fdiscount = s.fdiscount;
		add.rdiscount   = s.rdiscount;
		add.o_fdiscount = s.fdiscount;
		add.o_fprice    = s.fprice;
		
		add.reject    = s.amount;
		add.total     = s.total;
		add.oil       = s.oil;
		
		add.has_rejected = wsaleUtils.to_integer(s.has_rejected.charAt(0));
		add.negative = wsaleUtils.to_integer(s.has_rejected.charAt(1)); 
		add.bargin_price = wsaleUtils.to_integer(s.has_rejected.charAt(2)) === 1 ? 3 : 0;
		add.ticket = wsaleUtils.to_integer(s.has_rejected.charAt(3));
		
		add.pid       = s.pid;
		add.mid       = s.mid;
		add.sid       = s.sid;

		add.sizes.push(s.size); 
		add.colors_id.push(s.color_id);
		
		add.amounts.push({cid: s.color_id, size:s.size, sell_count:s.amount});

		sorts.push(add);
	    }
	}

	return {select:select, details:sorts}
    };

    var get_size_group = function(gids, size_groups){
	var gnames = [];
	gids.split(",").map(function(id){
	    angular.forEach(size_groups, function(g){
		if (parseInt(id) === g.id){
		    angular.forEach(diablo_sizegroup, function(sname){
			if (g[sname]){
			    if (!in_array(gnames, g[sname]))
				gnames.push(g[sname]);
			}
		    })
		}
	    })
	}); 
	
	return gnames;
    }; 

    return {
	format_promotion: function(inv, promotions){
	    // if (angular.isUndefined(inv.promotion)){
	    // 	return promotions;
	    // }

	    var format = {
		order_id:  inv.order_id,
		name:      inv.style_number
		    + "-" + (inv.brand.name ? inv.brand.name : inv.brand)
		    + "-" + inv.type
		    + "-" + (wsaleUtils.to_integer(inv.bargin_price) === 3 ? "特价" : "正价"),
		
		promotion: inv.promotion,
		score:     inv.score
	    }; 

	    var found = false;
	    for (var i=0, l=promotions.length; i<l; i++){
		if (inv.order_id === promotions[i].order_id){
		    found = true;
		    break;
		}
	    }
	    
	    if (!found){
		promotions.unshift(format); 
	    }
	    
	    // console.log(promotions);
	    return promotions;
	},

	delete_format_promotion: function(inv, promotions){
	    if (-1 === inv.pid) return promotions;
	    
	    var found = false;
	    for (var i=0, l=promotions.length; i<l; i++){
		if (inv.order_id === promotions[i].order_id){
		    found = true;
		    break;
		}
	    }
	    
	    if (found){
		promotions.splice(i, 1); 
		// promotions.unshift(format); 
	    }
	    
	    console.log(promotions);
	    return promotions;
	},
	
	cover_wsale: function(
	    base,
	    sells,
	    shops,
	    brands,
	    retailers,
	    employees,
	    // types,
	    colors,
	    size_groups,
	    promotions,
	    commisions,
	    scores){
	    var wsale         = sort_wsale(base, sells);
	    // var details       = wsale.details;
	    var order_length  = wsale.details.length; 
	    var show_promotions = [];
	    angular.forEach(wsale.details, function(d){
		if (d.sizes.length !== 1 || d.sizes[0] !== diablo_free_size){
		    d.sizes = get_size_group(d.s_group, size_groups)
		}

		d.colors = d.colors_id.map(function(id){
		    return diablo_find_color(id, colors)
		});
		
		d.brand        = diablo_get_object(d.brand_id, brands);
		// d.type         = diablo_get_object(d.type_id, types);
		d.promotion    = diablo_get_object(d.pid, promotions);
		d.commision    = diablo_get_object(d.mid, commisions);
		d.score        = diablo_get_object(d.sid, scores); 
		d.select       = true; 
		
		d.order_id  = order_length;

		if (-1 !== d.pid && -1 !== d.sid){
		    wsaleUtils.format_promotion(d, show_promotions); 
		}
		
		order_length--; 
		
	    });

	    wsale.select.shop = diablo_get_object(wsale.select.shop_id, shops); 
	    wsale.select.retailer = diablo_get_object(wsale.select.retailer_id, retailers);
	    // console.log(wsale);
	    wsale.select.employee = diablo_get_object(wsale.select.employee_id, employees); 
	    wsale.show_promotions = show_promotions;
	    return wsale;
	},

	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "/" + brand + "/" + type;
	    var prompt = name + "/" + diablo_pinyin(name); 
	    return {name: name, prompt: prompt};
	},

	// base setting 
	get_round: function(shop, base){
	    return diablo_base_setting("pround", shop, base, parseInt, diablo_round_record);
	},

	typeahead: function(shop, base){
	    return diablo_base_setting("qtypeahead", shop, base, parseInt, diablo_yes);
	},

	im_print: function(shop, base){
	    return diablo_base_setting("pim_print", shop, base, parseInt, diablo_no); 
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd"));
	},

	check_sale: function(shop, base){
	    return diablo_base_setting("check_sale", shop, base, parseInt, diablo_yes);
	},

	negative_sale: function(shop, base){
	    return diablo_base_setting("m_sale", shop, base, parseInt, diablo_yes);
	},

	show_sale_day: function(shop, base){
	    // default current day
	    return diablo_base_setting("d_sale", shop, base, parseInt, 0);
	},

	print_mode: function(shop, base){
	    return diablo_base_setting("ptype", shop, base, parseInt, diablo_backend);
	},

	sequence_pagination: function(shop, base){
	    return diablo_base_setting("se_pagination", shop, base, parseInt, diablo_no);
	},

	no_vip: function(shop, base){
	    return diablo_base_setting("s_customer", shop, base, parseInt, diablo_no);
	},

	comment: function(shop, base){
	    var comments = [];
	    for (var i=1; i<5; i++) {
		var c= diablo_base_setting(
		    "comment" + i.toString(), shop, base, function(v){return v}, "");
		if (c) {comments.push({id:i, name:c})} 
	    } 
	    return comments;
	},

	print_num: function(shop, base){
	    var p = diablo_base_setting("pum", shop, base, function(s) {return s}, diablo_print_num);
	    return {common: wsaleUtils.to_integer(p.charAt(0)),
		    swiming: wsaleUtils.to_integer(p.charAt(1)),
		    protocal: wsaleUtils.to_integer(p.charAt(2)),
		    print_a4: wsaleUtils.to_integer(p.charAt(4))};
	},

	printer_bill: function(shop, base) {
	    return diablo_base_setting("prn_bill", shop, base, parseInt, diablo_invalid_index);
	},

	round: function(shop, base){
	    return wsaleUtils.to_integer(
		diablo_base_setting("round", shop, base, parseInt, diablo_yes));
	},

	scanner: function(shop, base) {
	    return diablo_base_setting("scanner", shop, base, parseInt, diablo_no);
	},

	solo_retailer: function(shop, base) {
	    return diablo_base_setting("s_member", shop, base, parseInt, diablo_no);
	},

	s_employee: function(shop, base) {
	    return diablo_base_setting("s_employee", shop, base, parseInt, diablo_no);
	},

	cake_mode: function(shop, base){
	    return diablo_base_setting("cake_mode", shop, base, parseInt, diablo_no);
	},

	barcode_mode: function(shop, base) {
	    return diablo_base_setting("bcode_use", shop, base, parseInt, diablo_no);
	},

	barcode_auto: function(shop, base) {
	    return diablo_base_setting("bcode_auto", shop, base, parseInt, diablo_no);
	},

	draw_score: function(shop, base) {
	    return diablo_base_setting("draw_score", shop, base, parseInt, diablo_yes);
	},

	draw_region: function(shop, base) {
	    return diablo_base_setting("draw_region", shop, base, parseInt, diablo_no);
	},

	vip_mode:function(shop, base) {
	    return diablo_base_setting("r_discount", shop, base, function(s) {return s}, diablo_vip_mode);
	},

	shop_mode: function(shop, base) {
	    return diablo_base_setting("shop_mode", shop, base, parseInt, diablo_clothes_mode);
	},

	gift_sale:function(shop, base) {
	    var gift = diablo_base_setting("gift_sale", shop, base, function(s) {return s}, diablo_gift_mode);
	    return {
		gift_sale: wsaleUtils.to_integer(gift.charAt(0)),
		commision: wsaleUtils.to_integer(gift.charAt(1))
	    }
	},

	scan_only:function(shop, base) {
	    return diablo_base_setting("scan_only", shop, base, function(s) {return s}, diablo_scan_mode);
	},

	maling_rang:function(shop, base) {
	    return diablo_base_setting("maling_rang", shop, base, parseInt, diablo_default_maling_rang);
	},

	type_sale:function(shop, base) {
	    return diablo_base_setting("type_sale", shop, base, parseInt, diablo_no);
	},

	sale_mode:function(shop, base) {
	    return diablo_base_setting("p_balance", shop, base, function(s) {return s}, diablo_sale_mode);
	},

	hide_fixed_stock:function(shop, base) {
	    var hide = diablo_base_setting("h_stock", shop, base, function(s) {return s}, diablo_stock_in_hide_mode);
	    return wsaleUtils.yes_default(hide.charAt(20));
	},

	hide_oil:function(shop, base) {
	    var hide = diablo_base_setting("h_stock", shop, base, function(s) {return s}, diablo_stock_in_hide_mode);
	    return wsaleUtils.yes_default(hide.charAt(21));
	},

	get_print_setting:function(sale_mode) {
	    return {
		print_discount: wsaleUtils.yes_default(sale_mode.charAt(15)),
		print_perform:  wsaleUtils.to_integer(sale_mode.charAt(3)),
		cake_mode:      wsaleUtils.cake_mode(shopId, settings),
		comments:       wsaleUtils.comment(shopId, settings),
		head_seperater: wsaleUtils.to_integer(sale_mode.charAt(23)),
		print_score:    wsaleUtils.yes_default(sale_mode.charAt(26))
	    };
	},
	
	get_login_employee:function(shop, loginEmployee, employees){
	    var filterEmployees = employees.filter(function(e){
		return e.shop === shop && e.state === 0;
	    });

	    if (filterEmployees.length === 0) filterEmployees = angular.copy(employees);
	    
	    var select = undefined;
	    if (diablo_invalid_employee !== loginEmployee)
		select = diablo_get_object(loginEmployee, filterEmployees); 

	    if (angular.isUndefined(select)) select = filterEmployees[0];
	    
	    return {login:select, filter:filterEmployees};
	},

	sort_amount: function(invs, amounts, colors){
	    var select_amounts = [];
	    var used_colors = [];
	    var total = 0;
	    for (var i=0, l=invs.length; i<l; i++){
		var inv = invs[i];
		var color = diablo_find_color(inv.color_id, colors);
		var amount = {cid:   color.cid,
			      size:  inv.size,
			      cname: color.cname,
			      count: inv.amount};

		total += inv.amount;
		select_amounts.push(amount);

		if (!diablo_in_colors(color, used_colors)){
		    used_colors.push(color); 
		}
		
		// get select
		for (var j=0, k=amounts.length; j<k; j++){
		    var s = amounts[j];
		    if (inv.color_id === s.cid && inv.size === s.size){
			// amount.old_reject = s.reject;
			var sell_count = diablo_set_integer(s.sell_count);
			if (angular.isDefined(sell_count)){
			    total += Math.abs(s.sell_count);
			    amount.count += Math.abs(s.sell_count);
			    amount.sell_count = Math.abs(s.sell_count); 
			}
			
			break;
		    }
		}
	    }

	    return {
		total: total, amounts:select_amounts, colors:used_colors};
	},

	sort_promotion:function(p, money, promotions){
	    var found = false;
	    for (var i=0, l=promotions.length; i<l; i++){
		if (p.id === promotions[i].p.id){
		    found = true;
		    promotions[i].money += money;
		    promotions[i].count += 1;
		    break;
		}
	    }

	    if (!found){
		promotions.push({p:p, money: money, count: 0});
	    }

	    return promotions;
	},

	sort_score: function(s, p, money, scores){
	    var found = false;
	    for (var i=0, l=scores.length; i<l; i++){
		if (s.id === scores[i].score.id){
		    found = true;
		    scores[i].money += money;
		    break;
		}
	    }

	    if (!found){
		scores.push({score:s, p: p, money: money});
	    }

	    return scores;
	},

	// calc_with_promotion: function(pmoneys, round){
	//     var balance = 0;
	//     var rbalance = 0;
	//     for ( var i=0, l=pmoneys.length; i<l; i++){
	// 	var p = pmoneys[i].p;
	// 	balance += pmoneys[i].money; 
		
	// 	if (p.rule_id === 1){
	// 	    if (pmoneys[i].money >= 0){
	// 		rbalance += Math.floor(pmoneys[i].money / p.cmoney) *  p.rmoney; 
	// 	    } else {
	// 		rbalance += Math.ceil(pmoneys[i].money / p.cmoney) *  p.rmoney; 
	// 	    }
	// 	} 
	//     }

	//     // console.log(round);
	//     if (angular.isUndefined(round) || round) 
	// 	return {balance: diablo_round(balance - rbalance), rbalance: rbalance};
	//     else
	// 	return {balance: wsaleUtils.to_decimal(balance - rbalance), rbalance: rbalance};
	// },

	// calc_discount_of_rmoney: function(fprice, count, promotion, pmoneys, inventories){
	//     // var r = {}; 
	//     if (promotion.rule_id === 0 ){
	// 	    return diablo_full_discount; 
	//     } else if (promotion.rule_id === 1){
	// 	var balance = 0;
	// 	var total_balance = 0;
	// 	var rmoney = 0;
		
	// 	for ( var i=0, l=pmoneys.length; i<l; i++ ){
	// 	    var p = pmoneys[i].p;
	// 	    if (promotion.id === p.id) {
	// 		if (p.rule_id === 1) {
	// 		    if (pmoneys[i].money >= 0){
	// 			rmoney = Math.floor(pmoneys[i].money / p.cmoney) * p.rmoney; 
	// 		    } else {
	// 			rmoney = Math.ceil(pmoneys[i].money / p.cmoney) * p.rmoney; 
	// 		    }
	// 		    total_balance += pmoneys[i].money;
	// 		    balance += pmoneys[i].money - rmoney;
	// 		} 
	// 	    } 
	// 	}
	// 	console.log(total_balance, balance, rmoney);
		
	// 	if (rmoney !== 0 ){
	// 	    return diablo_discount(balance, total_balance);
	// 	} else {
	// 	    return diablo_full_discount;
	// 	}
	//     } else if (promotion.rule_id === 2) {
	// 	if (count >= 0)
	// 	    rmoney = fprice * Math.floor(count / (promotion.cmoney + promotion.rmoney)) * promotion.rmoney;
	// 	else
	// 	    rmoney = fprice * Math.ceil(count / (promotion.cmoney + promotion.rmoney)) * promotion.rmoney;

	// 	var calc = wsaleUtils.to_decimal(fprice * count);
	// 	return diablo_discount(calc - rmoney, calc);
	//     } 
	// },

	// calc_discount_of_brand_money:function(saleMode, stock, stockWithRule3) {
	//     // var sameBrandStocks = [];
	//     var sellTotal = 0;
	//     for (var i=0, l=stockWithRule3.length; i<l; i++) {
	// 	sellTotal += wsaleCalc.get_inventory_count(stockWithRule3[i], saleMode);
	//     }

	//     // get valid discount
	//     var scounts = stock.promotion.scount.split(diablo_semi_seperator);
	//     var sdiscounts = stock.promotion.sdiscount.split(diablo_semi_seperator);

	//     var selectDiscount = diablo_full_discount;
	//     for (var i=0, l=scounts.length; i<l; i++) {
	//     	if ( wsaleUtils.to_integer(sellTotal) >= wsaleUtils.to_integer(scounts[i]) ) {
	//     	    selectDiscount = wsaleUtils.to_float(sdiscounts[i]);
	//     	}
	//     }

	//     angular.forEach(stockWithRule3, function(one) {
	//     	one.rdiscount = one.discount < selectDiscount ? one.discount : selectDiscount; 
	//     });

	//     return stockWithRule3;
	// },

	// calc_discount_of_minus_money:function(saleMode, stock, stockWithRule4) {
	//     var sellTotal = 0;
	//     var pay = 0; 
	//     for (var i=0, l=stockWithRule4.length; i<l; i++) {
	// 	sellTotal += wsaleCalc.get_inventory_count(stockWithRule4[i], saleMode);
	// 	pay += stockWithRule4[i].calc;
	//     }

	//     // get valid discount
	//     var scounts = stock.promotion.scount.split(diablo_semi_seperator);
	//     var minus = stock.promotion.sdiscount.split(diablo_semi_seperator);

	//     var selectMinus = 0;
	//     for (var i=0, l=scounts.length; i<l; i++) {
	//     	if ( wsaleUtils.to_integer(sellTotal) >= wsaleUtils.to_integer(scounts[i]) ) {
	//     	    selectMinus = wsaleUtils.to_integer(minus[i]);
	//     	}
	//     }

	//     var vdiscount = diablo_discount(selectMinus, pay);
	    
	//     angular.forEach(stockWithRule4, function(one) {
	// 	one.rdiscount = wsaleUtils.to_decimal(one.discount - vdiscount);
	//     });

	//     return stockWithRule4;
	// },

	calc_with_score: function(pscores, verificate){
	    // console.log(pscores, verificate);
	    var score = 0; 
	    if (pscores.length > 0){
		var s = pscores[0];
		if (angular.isDefined(s.score)) {
		    score = Math.floor((diablo_round(s.money) - verificate) / s.score.balance) * s.score.score; 
		    for (var i=1, l=pscores.length; i<l; i++){
			s = pscores[i];
			score += Math.round(Math.floor(s.money) / s.score.balance) * s.score.score; 
		    }
		} 
	    }
	    
	    return score;
	},

	calc_score_of_pay: function(pay, pscores){
	    // console.log(pscores);
	    var score = 0;
	    var pay_with_score = pay;
	    if (pscores.length > 0){
		if (pay > 0) {
		    for (var i=0, l=pscores.length; i<l; i++){
			s = pscores[i];
			pay_with_score -= s.money; 
			if (pay_with_score > 0) 
			    score += Math.floor(diablo_round(s.money) / s.score.balance) * s.score.score;
			else
			    score += Math.floor(
				diablo_round(s.money + pay_with_score) / s.score.balance) * s.score.score;
		    }
		} else if (pay < 0){
		    for (var i=0, l=pscores.length; i<l; i++){
			s = pscores[i];
			pay_with_score -= s.money; 
			if (pay_with_score < 0) 
			    score += Math.floor(diablo_round(s.money) / s.score.balance) * s.score.score;
			else
			    score += Math.floor(
				diablo_round(s.money + pay_with_score) / s.score.balance) * s.score.score;
		    } 
		}
	    }
	    
	    return score;
	},

	calc_score_of_money: function(money, score){
	    return Math.floor(money / score.balance) * score.score;
	},

	to_float: function(v) {
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	to_decimal:function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    }
	    return diablo_rdight(v, 2);
	},

	ediscount: function(org_price, tag_price){
	    if (tag_price == 0) return 0; 
	    return parseFloat((diablo_float_div(org_price, tag_price) * 100).toFixed(1));
	},

	authen_shop: function(user_type, shop, action){
	    return rightAuthen.authen_shop_action(
		user_type,
		rightAuthen.wsale_action()[action],
		shop)
	},

	authen_rainbow: function(user_type, action, right) {
	    return rightAuthen.modify_onsale(
		user_type,
		rightAuthen.rainbow_action()[action],
		right)
	},

	correct_query_time: function(isMaster, configDays, start_time, now, dateFilter){
	    if (isMaster || configDays === diablo_nolimit_day)
		return dateFilter.default_time(start_time, now);
	    else {
		var diff = now - diablo_get_time(start_time);
		// console.log(diff, diff - configDays * diablo_day_millisecond);
		if (diff - configDays * diablo_day_millisecond <= diablo_day_millisecond) {
		    return dateFilter.default_time(start_time, now);
		} else {
		    return dateFilter.default_time(now - diablo_day_millisecond * configDays, now); 
		}
	    } 
	},

	first_day_of_month: function(){
	    var now = new Date(); 
	    var year = now.getFullYear();
	    var month = now.getMonth();

	    return {
		first:new Date(year, month, 1).getTime(), current:now.getTime()};
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

	remove_cache_page: function(stroage){
	    stroage.remove(diablo_key_wsale_trans);
	    stroage.remove("wsale-trans-stastic"); 
	    stroage.remove(diablo_key_wsale_trans_detail);
	    stroage.remove("wsale-note-stastic");
	},

	order_fields:function(){
	    return {id:0, shop:1, brand:2, firm:3};
	},

	get_object_id: function(obj){
	    if (angular.isDefined(obj)
		&& angular.isObject(obj)
		&& angular.isDefined(obj.id))
		return obj.id; 
	    return diablo_invalid_firm;
	},

	format_time_from_second: function(time, dateFun) {
	    var o = {};
	    if (angular.isObject(time)) {
		if (time.hasOwnProperty('start_time'))
		    o.start_time = dateFun(time.start_time, "yyyy-MM-dd");
		if (time.hasOwnProperty('end_time'))
		    o.end_time = dateFun(time.start_time, "yyyy-MM-dd");
	    }
	    return o;
	},

	match_retailer_phone: function(viewValue, filterFun, shop, region){
	    if (diablo_is_digit_string(viewValue)){
		if (viewValue.length < 4) return;
		else if (viewValue.startsWith("9"))
		    return filterFun.match_retailer_phone(viewValue, 3, shop, region);
		else
		    return filterFun.match_retailer_phone(viewValue, 0, shop, region);
	    } else if (diablo_is_letter_string(viewValue)){
		return filterFun.match_retailer_phone(viewValue, 1, shop, region);
	    } else if (diablo_is_chinese_string(viewValue)){
		return filterFun.match_retailer_phone(viewValue, 2, shop, region);
	    } else {
		return;
	    } 
	},

	extra_error:function(result) {
	    if (result.ecode === 2705) 
		return "应付金额：" + result.should_pay.toString() +
		"，计算金额：" + result.check_pay.toString();
	    else if (result.ecode === 2708)
		return "当前日期[" + result.fdate + "]，"
		+ "服务器日期[" + result.bdate + "]";
	    else
		return ""
	},

	isVip:function(selectRetailer, customRetailer, sysRetailers) {
	    return  selectRetailer.id !== customRetailer
		&& selectRetailer.type_id !== 2
		&& sysRetailers.filter(function(r) {return selectRetailer.id === r.id}).length === 0
	},

	get_retailer_level:function(retailerLevel, levels) {
	    var filterLevels = levels.filter(function(l) {
		return retailerLevel === l.level;
	    });

	    return filterLevels.length === 0 ? undefined : filterLevels[0];
	},
	
	get_retailer_discount:function(retailerLevel, levels) {
	    var filterLevels = levels.filter(function(l) {
		return retailerLevel === l.level;
	    });

	    return filterLevels.length === 0 ? undefined : filterLevels[0].discount;
	}, 

	first_day_of_month: function(){
	    var now = new Date(); 
	    var year = now.getFullYear();
	    var month = now.getMonth();

	    return {
		first:new Date(year, month, 1).getTime(), current:now.getTime()};
	},

	yes_default: function(v) {
	    if (v === diablo_empty_string)
		return diablo_yes;
	    return wsaleUtils.to_integer(v);
	},

	correct_condition_with_shop: function(condition, shopIds, shops) {
	    if (wsaleUtils.to_integer(condition.region) === 0){
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
	},

	mark_phone: function(phone) {
	    return phone.replace(phone.substring(3,7), "****");
	},

	check_retailer_barcode: function(barcode) {
	    o_barcode = parseInt(barcode, 16).toString();
	    // console.log(o_barcode);
	    if (o_barcode.length === 10) {
		var year   = o_barcode.substring(0, 2);
		var month  = wsaleUtils.to_integer(o_barcode.substring(2, 4));
		var date   = wsaleUtils.to_integer(o_barcode.substring(4, 6));
		var hour   = wsaleUtils.to_integer(o_barcode.substring(6, 8));
		var minute = wsaleUtils.to_integer(o_barcode.substring(8, 10));

		var t2 = new Date();
		var t2_year = t2.getFullYear();
		var full_year = wsaleUtils.to_integer(t2_year.toString().substring(0, 2) + year);
		
		var t1 =  new Date(full_year, month - 1, date, hour, minute); 
		console.log(t1);
		// 5 minute
		return t2.getTime() - t1.getTime() <= 2 * 1000 * 60; 
	    }

	    return false;
	    
	}
	
	// 
	
    }

}();

var wsaleCalc = function(){
    return {
	// calc_count_with_promotion: function(count, promotion) {
	//     if (promotion.rule_id === 2)
	// 	return count - Math.floor(count / promotion.cmoney) * promotion.rmoney;
	//     else
	// 	return count;
	// },

	get_inventory_count: function(inv, sellMode) {
	    return sellMode === diablo_sale ? inv.sell : inv.reject;
	},

	calc_vip_discount: function(vipDiscountMode, vipDiscount, inv) {
	    if (angular.isDefined(vipDiscount)) {
		if ( vipDiscountMode === 1 )
		    inv.fdiscount = vipDiscount < inv.fdiscount ? vipDiscount : inv.fdiscount;
		else if (vipDiscountMode === 2)
		    inv.fdiscount = wsaleUtils.to_decimal(inv.fdiscount * vipDiscount * 0.01);
	    }

	    return inv.fdiscount;
	},

	sort_stock_with_promotion: function(stock, stocksWithPromotion) {
	    var find = false;
	    for (var i=0, l=stocksWithPromotion.length; i<l; i++) {
		var p = stocksWithPromotion[i];
		if (stock.pid === p.pid) {
		    p.stocks.push(stock)
		    find = true; 
		    break; 
		} 
	    }

	    if (!find) {
		stocksWithPromotion.push({pid:stock.pid, stocks:[].concat(stock)});
	    }

	    return stocksWithPromotion;
	},

	in_promotion_stock: function(stock, stocksWithPromotion) {
	    var find = false;
	    for (var i=0, l=stocksWithPromotion.length; i<l; i++) {
		var p = stocksWithPromotion[i];
		for (var j=0, k=p.stocks.length; j<k; j++) {
		    if (stock.style_number === p.stocks[j].style_number && stock.brand_id === p.stocks[j].brand_id) {
			find = true;
			break;
		    } 
		}
		
		if (find)
		    break; 
	    }

	    return find;
	},

	in_m2n_stocks:function(stock, m2nStocks) {
	    var find = false;
	    for (var i=0, l=m2nStocks.length; i<l; i++) {
		if (stock.style_number === m2nStocks[i].style_number
		    && stock.brand_id === m2nStocks[i].brand_id) {
		    find = true;
		    break;
		} 
	    }

	    return find;
	},

	get_valid_price:function(isVip, virPriceMode, stock) {
	    if (virPriceMode) {
		if (!isVip && (stock.vir_price) > 0 && (stock.vir_price > stock.tag_price)) {
		    return stock.vir_price; 
		}
		else {
		    return stock.tag_price;
		} 
	    } else {
		return stock.tag_price; 
	    }
	    
	},

	calc_commision: function(stock, count, mid, commision) {
	    var total_oil = 0;
	    if (mid !== diablo_invalid_index && mid !== 0) {
		if (commision.rule_id === 0) {
		    if (stock.rprice < diablo_price(stock.tag_price, stock.discount)) {
			stock.oil = diablo_price(commision.balance, commision.flat) * count;
		    } else {
			stock.oil = commision.balance * count;
		    }
		} else if (commision.rule_id === 1) {
		    if (stock.rprice < diablo_price(stock.tag_price, stock.discount)) {
			stock.oil = diablo_price(
			    stock.rprice, commision.balance * commision.flat * 0.01) * count;
		    } else {
			stock.oil = diablo_price(stock.rprice, commision.balance) * count;
		    }
		}
		total_oil += stock.oil;
	    } else {
		stock.oil = 0;
	    }

	    return total_oil;
	},

	
	
	calculate: function(isVip,
			    vipMode,
			    vipDiscount,
			    // vipLevel,
			    inventories,
			    show_promotions,
			    saleMode,
			    verificate,
			    round,
			    score_discount){
	    var total        = 0;
	    var abs_total    = 0;
	    var should_pay   = 0;
	    var base_pay     = 0;
	    var abs_pay      = 0;
	    var score        = 0;
	    var valid_price  = 0;
	    var can_draw     = 0;
	    var total_oil    = 0;
	    var noTicketBalance = 0;
	    
	    var vipDiscountMode    = wsaleUtils.to_integer(vipMode.charAt(0));
	    var virPriceMode       = wsaleUtils.to_integer(vipMode.charAt(2));
	    var scoreDiscountPerStock = wsaleUtils.to_integer(vipMode.charAt(3)); 

	    var stocksSortWithPromotion = [];
	    for (var i=0, l=inventories.length; i<l; i++) {
		var one = inventories[i];
		// console.log(one);
		valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);
		if ( (angular.isDefined(one.select) && !one.select) || one.has_rejected) continue;
		
		if (one.o_fprice !== one.fprice) {
		    // one.fdiscount = diablo_discount(one.fprice, one.tag_price);
		    one.fdiscount = diablo_discount(one.fprice, valid_price);
		    
		} else if (one.o_fdiscount !== one.fdiscount) {
		    // if (one.tag_price == 0) {
		    // 	one.fprice = diablo_price(one.fprice, one.fdiscount); 
		    // } else {
		    // 	one.fprice = diablo_price(one.tag_price, one.fdiscount); 
		    // }
		    if (valid_price == 0) {
		    	one.fprice = diablo_price(one.fprice, one.fdiscount); 
		    } else {
		    	one.fprice = diablo_price(valid_price, one.fdiscount); 
		    }
		} else {
		    if (diablo_sale === saleMode && !one.$update && one.bargin_price !== 3) {
			wsaleCalc.sort_stock_with_promotion(one, stocksSortWithPromotion); 
		    }
		}		
	    }

	    var stocksNoWithM2N = [];
	    angular.forEach(stocksSortWithPromotion, function(s) {
		if (s.pid !== diablo_invalid_index) {
		    var count, totalPay, rmoney, vdiscount, payAll;
		    var pm = s.stocks[0].promotion; 
		    // promotion on discount
		    if (pm.rule_id === 0) {
			angular.forEach(s.stocks, function(stock) {
			    stock.fdiscount = stock.discount < pm.discount ? stock.discount : pm.discount; 
			    // stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    stock.fprice = diablo_price(valid_price, stock.fdiscount);
			})
		    } 
		    else if (pm.rule_id === 1) {
			count = 0, totalPay = 0, rmoney = 0, vdiscount = 0, payAll = 0;
			var uPrice = 0; 
			angular.forEach(s.stocks, function(stock) {
			    count = wsaleCalc.get_inventory_count(stock, saleMode);
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    if (pm.prule_id === 0) {
				// uPrice = diablo_price(stock.tag_price, stock.discount);
				uPrice = diablo_price(valid_price, stock.discount);
			    } else if (pm.prule_id === 1) {
				// uPrice = stock.tag_price;
				uPrice = valid_price;
			    } 
			    totalPay += uPrice * count; 
			    // payAll += stock.tag_price * count;
			    payAll += valid_price * count;
			}); 
			totalPay = wsaleUtils.to_decimal(totalPay);

			var cms = pm.cmoney.split(diablo_semi_seperator);
			var rms = pm.rmoney.split(diablo_semi_seperator);
			var tm  = 0; 
			for (var i=0, l= cms.length; i<l; i++) {
			    var cm = wsaleUtils.to_integer(cms[i]);
			    var rm = wsaleUtils.to_integer(rms[i]);
			    if (Math.abs(totalPay) >= cm) {
				if (totalPay > 0) {
				    tm = Math.floor(totalPay / cm) * rm;
				    if (rmoney < tm) {
					rmoney = tm;
				    }
				}
				else {
				    tm = Math.ceil(totalPay / cm) * rm;
				    if (rmoney > tm) {
					rmoney = tm;
				    }
				}
			    }
			}

			console.log(totalPay, rmoney);
			vdiscount = diablo_discount(rmoney, payAll);

			angular.forEach(s.stocks, function(stock) {
			    if (pm.prule_id === 0) {
				stock.fdiscount = wsaleUtils.to_decimal(stock.discount - vdiscount); 
			    } else if (pm.prule_id === 1) {
				stock.fdiscount = wsaleUtils.to_decimal(diablo_full_discount - vdiscount); 
			    } 
			    // stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    stock.fprice = diablo_price(valid_price, stock.fdiscount);
			}); 
		    }
		    
		    else if (pm.rule_id === 2) {
			count = 0, totalPay = 0, rmoney = 0, vdiscount = 0, payAll = 0;

			var orderStocks = [];
			angular.forEach(s.stocks, function(stock) {
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    // var uPrice = stock.tag_price;
			    var uPrice = valid_price;
			    if (pm.prule_id === 0) {
				uPrice = diablo_price(valid_price, stock.discount);
			    }
			    var mCount =  wsaleCalc.get_inventory_count(stock, saleMode);
			    totalPay += uPrice * mCount;
			    count    += mCount; 
			    // payAll   += stock.tag_price * mCount;
			    payAll   += valid_price * mCount;
			    orderStocks.push({price:uPrice, count:mCount});
			});
			totalPay = wsaleUtils.to_decimal(totalPay);
			orderStocks.sort(function(s1,s2) {
			    return s1.price - s2.price;
			});

			var cms = pm.cmoney.split(diablo_semi_seperator);
			var rms = pm.rmoney.split(diablo_semi_seperator);
			var sendCount  = 0;
			for (var i=0, l= cms.length; i<l; i++) {
			    var cm = wsaleUtils.to_integer(cms[i]);
			    var rm = wsaleUtils.to_integer(rms[i]);
			    if (Math.abs(count) >= cm + rm) {
				if (count > 0) {
				    sendCount = Math.floor( count / (cm + rm) ) * rm; 
				}
				else {
				    sendCount = Math.ceil( count / (cm + rm) ) * rm; 
				}
			    }
			}

			angular.forEach(orderStocks, function(o) {
			    if (sendCount > 0) {
				if (sendCount > o.count) {
				    rmoney += o.count * o.price;
				    sendCount -= o.count; 
				} else {
				    rmoney += sendCount * o.price;
				    sendCount = 0; 
				}
			    }
			});
			
			vdiscount = diablo_discount(rmoney, payAll);
			angular.forEach(s.stocks, function(stock) {
			    if (vdiscount !== 0) {
				if (pm.prule_id === 0) {
				    stock.fdiscount = wsaleUtils.to_decimal(stock.discount - vdiscount); 
				} else if (pm.prule_id === 1) {
				    stock.fdiscount = wsaleUtils.to_decimal(diablo_full_discount - vdiscount); 
				}
			    } else {
				stock.fdiscount = stock.discount;
				stocksNoWithM2N.push(stock);
			    }
			    // stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    stock.fprice = diablo_price(valid_price, stock.fdiscount);
			}); 
		    }
		    
		    else if (pm.rule_id === 3) {
			count = 0, totalPay = 0, rmoney = 0, vdiscount = 0, payAll = 0; 
			angular.forEach(s.stocks, function(stock) {
			    count += wsaleCalc.get_inventory_count(stock, saleMode);
			}); 
			
			var scounts = pm.scount.split(diablo_semi_seperator);
			var sdiscounts = pm.sdiscount.split(diablo_semi_seperator);
			
			for (var i=0, l=scounts.length; i<l; i++) {
	    		    if ( Math.abs(count) >= wsaleUtils.to_integer(scounts[i]) ) {
	    			vdiscount = wsaleUtils.to_float(sdiscounts[i]);
	    		    }
			}

			angular.forEach(s.stocks, function(stock) {
			    if (vdiscount !== 0) {
				stock.fdiscount = vdiscount;
			    } else {
				stock.fdiscount = stock.discount;
			    }
			    // stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    stock.fprice = diablo_price(valid_price, stock.fdiscount);
			}); 
		    } 
		    else if (pm.rule_id === 4) {
			count = 0, totalPay = 0, rmoney = 0, vdiscount = 0, payAll = 0;
			var c = 0;
			angular.forEach(s.stocks, function(stock) {
			    c = wsaleCalc.get_inventory_count(stock, saleMode);
			    count += c 
			    // totalPay += diablo_price(stock.tag_price, stock.discount) * c;
			    // payAll += stock.tag_price * c;
			    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			    totalPay += diablo_price(valid_price, stock.discount) * c;
			    payAll += valid_price * c;
			}); 
			
			var scounts = pm.scount.split(diablo_semi_seperator);
			var sminus = pm.sdiscount.split(diablo_semi_seperator);
			
			for (var i=0, l=scounts.length; i<l; i++) {
	    		    if ( Math.abs(count) >= wsaleUtils.to_integer(scounts[i]) ) {
	    			rmoney = wsaleUtils.to_integer(sminus[i]);
	    		    }
			}

			if (rmoney !== 0) {
			    if (pm.prule_id === 0) {
				vdiscount = diablo_discount(rmoney, totalPay); 
			    } else if (pm.prule_id === 1) {
				vdiscount = diablo_discount(rmoney, payAll); 
			    }
			    
			    angular.forEach(s.stocks, function(stock) {
				stock.fdiscount = wsaleUtils.to_decimal(diablo_full_discount - vdiscount);
				valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
				if (pm.prule_id === 0) {
				    // stock.fprice = diablo_price(diablo_price(stock.tag_price, stock.discount), stock.fdiscount);
				    stock.fprice = diablo_price(diablo_price(valid_price, stock.discount), stock.fdiscount);
				}
				else if (pm.prule_id ===1) {
				    // stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
				    stock.fprice = diablo_price(valid_price, stock.fdiscount);
				}
			    }); 
			} else {
			    angular.forEach(s.stocks, function(stock) {
				stock.fdiscount = stock.discount;
				valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
				// stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
				stock.fprice = diablo_price(valid_price, stock.fdiscount);
			    });
			} 
		    }
		    else if (pm.rule_id === 5) {
			count = 0, totalPay = 0, rmoney = 0, vdiscount = 0, payAll = 0;
			// var c, stopCount = 0; 
			var scounts = pm.scount.split(diablo_semi_seperator);
			var sminus  = pm.sdiscount.split(diablo_semi_seperator);
			var average = 0;

			angular.forEach(s.stocks, function(stock){
			    count += wsaleCalc.get_inventory_count(stock, saleMode);
			}); 
			
			for (var i=0, l=scounts.length; i<l; i++) {
	    		    if ( Math.abs(count) >= wsaleUtils.to_integer(scounts[i]) ) {
	    			// rmoney = wsaleUtils.to_integer(sminus[i]);
				// stopCount = wsaleUtils.to_integer(scounts[i]);
				average = wsaleUtils.to_decimal(
				    wsaleUtils.to_integer(sminus[i]) / wsaleUtils.to_integer(scounts[i]));
	    		    }
			}

			if (average !== 0) {
			    for (var i=0, l=s.stocks.length; i<l; i++) {
				var stock = s.stocks[i];
				c = wsaleCalc.get_inventory_count(s.stocks[i], saleMode);
				valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
				// payAll += stock.tag_price * c;
				payAll += valid_price * c;
				rmoney += average * c; 
			    } 
			    vdiscount = diablo_discount(payAll - rmoney, payAll);
			    angular.forEach(s.stocks, function(stock) {
				stock.fdiscount = wsaleUtils.to_decimal(diablo_full_discount - vdiscount);
				valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
				// stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
				stock.fprice = diablo_price(valid_price, stock.fdiscount);
			    }); 
			} else {
			    angular.forEach(s.stocks, function(stock) {
				stock.fdiscount = stock.discount;
				valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
				// stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
				stock.fprice = diablo_price(valid_price, stock.fdiscount);
			    });
			}
		    } 
		} else {
		    angular.forEach(s.stocks, function(stock) {
			stock.fdiscount = stock.discount;
			valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, stock);
			// stock.fprice = diablo_price(stock.tag_price, stock.fdiscount);
			stock.fprice = diablo_price(valid_price, stock.fdiscount);
		    }); 
		}
	    });

	    // vip mode
	    if (isVip && diablo_sale === saleMode && diablo_vip_sale_by_balance !== vipDiscountMode) {
		for (var i=0, l=inventories.length; i<l; i++) {
		    // promotion first
		    var one = inventories[i]; 
		    // console.log(one);
		    if (one.bargin_price !== 3 && wsaleCalc.in_promotion_stock(one, stocksSortWithPromotion)) {
			if (one.pid !== diablo_invalid_index) {
			    // M2N stock
			    if (wsaleCalc.in_m2n_stocks(one, stocksNoWithM2N)) {
				one.fdiscount = wsaleCalc.calc_vip_discount(vipDiscountMode, vipDiscount, one);
				// one.fprice = diablo_price(one.tag_price, one.fdiscount);
			    }
			    
			    if (diablo_yes === one.promotion.member) {
				one.fdiscount = wsaleCalc.calc_vip_discount(vipDiscountMode, vipDiscount, one);
				// one.fprice = diablo_price(one.tag_price, one.fdiscount);
			    }
			} else {
			    one.fdiscount = wsaleCalc.calc_vip_discount(vipDiscountMode, vipDiscount, one);
			    // one.fprice = diablo_price(one.tag_price, one.fdiscount);
			}

			valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);
			// one.fprice = diablo_price(one.tag_price, one.fdiscount);
			one.fprice = diablo_price(valid_price, one.fdiscount);
		    } 
		}
		
	    }

	    for (var i=0, l=inventories.length; i<l; i++) {
		var one = inventories[i];
		var count = wsaleCalc.get_inventory_count(one, saleMode);
		
		// var valid_price =  one.vir_price > one.tag_price ? one.vir_price : one.tag_price;
		// var valid_price = one.tag_price;
		// if (!isVip && one.tag_price < one.vir_price) {
		//     valid_price = one.vir_price;
		// }
		valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);

		total      += wsaleUtils.to_integer(count);
		abs_total  += Math.abs(wsaleUtils.to_integer(count));
		abs_pay    += one.vir_price > one.tag_price ? one.vir_price * count : one.tag_price * count;

		if (diablo_sale === saleMode && isVip) can_draw += one.draw * count;

		// if (round === 2) {
		//     one.fprice = diablo_round(one.fprice);
		//     one.fdiscount = diablo_discount(one.fprice, one.tag_price);
		// } 

		// should_pay
		one.o_fprice = one.fprice;
		one.o_fdiscount = one.fdiscount;
		
		one.rprice = one.fprice;
		one.rdiscount = diablo_full_discount;
		
		one.calc = one.fprice * count; 
		should_pay += one.calc;

		// console.log(one);
		// base_pay
		if (one.$update) {
		    base_pay += diablo_price(valid_price * count, one.discount);
		} else {
		    base_pay += one.calc;
		}
		
		show_promotions = wsaleUtils.format_promotion(one, show_promotions);
		// if (one.sid !== diablo_invalid_index){
		//     pscores = wsaleUtils.sort_score(one.score, one.promotion, one.calc, pscores);
		// }
	    }

	    // calcuate with verificate
	    // console.log(verificate);
	    should_pay = wsaleCalc.calc_discount_of_verificate(inventories, saleMode, should_pay, verificate);
	    should_pay = wsaleUtils.to_decimal(should_pay); 
	    base_pay   = wsaleUtils.to_decimal(base_pay);
	    abs_pay    = wsaleUtils.to_decimal(abs_pay);
	    can_draw   = wsaleUtils.to_decimal(can_draw); 
	    
	    // console.log(should_pay);
	    // reset
	    var pscores = [];
	    for (var i=0, l=inventories.length; i<l; i++) {
		var one = inventories[i];
		var count = wsaleCalc.get_inventory_count(one, saleMode);
		valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);

		// oil
		total_oil += wsaleCalc.calc_commision(one, count, one.mid, one.commision);

		// can not use ticket
		if (diablo_no === one.ticket) {
		    noTicketBalance += one.calc;
		}
		
		// reset score
		if (wsaleUtils.to_integer(score_discount) !== 0) {
		    if (diablo_yes === scoreDiscountPerStock) {
			var ff = diablo_discount(
			    one.rprice, (diablo_price(valid_price, one.discount)));
			// console.log(ff);
			if (ff * diablo_full_discount < score_discount) {
			    continue;
			    // if (one.sid !== diablo_invalid_index){
			    // 	pscores = wsaleUtils.sort_score(
			    // 	    one.score, one.promotion, one.calc, pscores);
			    // }
			}
		    } else {
			if (diablo_discount(one.rprice, valid_price) < score_discount) {
			    continue;
			    // if (one.sid !== diablo_invalid_index){
			    // 	pscores = wsaleUtils.sort_score(
			    // 	    one.score, one.promotion, one.calc, pscores);
			    // }
			}
		    }
		}
		
		if (one.sid !== diablo_invalid_index){
		    pscores = wsaleUtils.sort_score(one.score, one.promotion, one.calc, pscores);
		} 
	    } 
	    
	    // if (wsaleUtils.to_integer(score_discount) !== 0) {
	    // 	for (var i=0, l=inventories.length; i<l; i++) {
	    // 	    var one = inventories[i];
	    // 	    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);
	    // 	    // if (diablo_discount(one.rprice, one.tag_price) >= score_discount) {
	    // 	    if (diablo_yes === scoreDiscountPerStock) {
	    // 		var ff = one.rprice * diablo_full_discount / (valid_price * one.discount);
	    // 		// console.log(ff);
	    // 		if (ff * diablo_full_discount >= score_discount) {
	    // 		    if (one.sid !== diablo_invalid_index){
	    // 			pscores = wsaleUtils.sort_score(
	    // 			    one.score, one.promotion, one.calc, pscores);
	    // 		    }
	    // 		}
	    // 	    } else {
	    // 		if (diablo_discount(one.rprice, valid_price) >= score_discount) {
	    // 		    if (one.sid !== diablo_invalid_index){
	    // 			pscores = wsaleUtils.sort_score(
	    // 			    one.score, one.promotion, one.calc, pscores);
	    // 		    }
	    // 		}
	    // 	    }
		    
	    // 	}
	    // }
	    
	    // score  = wsaleUtils.calc_with_score(pscores, verificate);
	    score  = wsaleUtils.calc_with_score(pscores, 0); 
	    
	    if (round === 1) {
		if (should_pay >= 0) {
		    should_pay = diablo_round(should_pay);
		    base_pay   = diablo_round(base_pay);
		    abs_pay    = diablo_round(abs_pay);
		    can_draw   = diablo_round(can_draw);
		} else {
		    should_pay = -diablo_round(Math.abs(should_pay));
		    base_pay   = -diablo_round(Math.abs(base_pay));
		    abs_pay    = -diablo_round(Math.abs(abs_pay));
		    can_draw   = -diablo_round(Math.abs(can_draw));
		}
	    } else if (round === 2) {
		should_pay = 0;
		base_pay   = 0;
		abs_pay    = 0;
		can_draw   = 0;
		for (var i=0, l=inventories.length; i<l; i++) {
		    var one = inventories[i];
		    valid_price = wsaleCalc.get_valid_price(isVip, virPriceMode, one);
		    one.calc = diablo_round(one.rprice * count); 
		    should_pay += one.calc;
		    abs_pay += one.vir_price > one.tag_price
			? diablo_round(one.vir_price * count) : diablo_round(one.tag_price * count);
		    if (one.$update) {
			base_pay += diablo_round(diablo_price(valid_price * count, one.discount));
		    } else {
			base_pay += one.calc;
		    }
		}
	    } else {
		// no round 
		should_pay = wsaleUtils.to_decimal(should_pay);
		base_pay   = wsaleUtils.to_decimal(base_pay);
		abs_pay    = wsaleUtils.to_decimal(abs_pay);
		can_draw   = wsaleUtils.to_decimal(can_draw);
	    }
	    
	    return {
		total:      total,
		abs_total:  abs_total,
		should_pay: should_pay,
		can_draw:   can_draw,
		oil:        total_oil,
		base_pay:   base_pay,
		abs_pay:    abs_pay,
		score:      score,
		pscores:    pscores,
		noTicketBalance: noTicketBalance
		// rbalance:   calc_p.rbalance, 
	    }; 
	},

	calc_discount_of_verificate: function(inventories, mode, pay, verificate){
	    if (wsaleUtils.to_integer(verificate) === 0){
		return pay;
	    }
	    
	    var p1 = 0;
	    var one;
	    var count; 
	    
	    for (var i=0, l=inventories.length; i<l; i++){
		one = inventories[i];
		count = wsaleCalc.get_inventory_count(one, mode);
		if (count >= 0)
		    p1 += one.fprice * count;
	    }

	    p1 = wsaleUtils.to_decimal(p1);
	    var vdiscount = diablo_discount(verificate, p1);
	    var calc = 0;
	    for (var i=0, l=inventories.length; i<l; i++){
		one = inventories[i];
		count = wsaleCalc.get_inventory_count(one, mode);
		if (count >=0 ){
		    // one.fdiscount = one.fdiscount * (diablo_full_discount - vdiscount) * 0.01;
		    // one.fprice = diablo_price(one.fprice, one.fdiscount); 
		    one.rdiscount = wsaleUtils.to_decimal(one.rdiscount - vdiscount);
		    one.rprice  = diablo_price(one.fprice, one.rdiscount);
		}
		
		one.calc = wsaleUtils.to_decimal(one.rprice * count);
		calc += one.calc;
		// console.log(one.calc);
	    }

	    return calc;
	},

	pay_order: function(should_pay, pays) {
	    // var pay = {ticket: 0, withdraw:0, wxin: 0, aliPay, card: 0, cash:0};
	    var orders = [];
	    var left = should_pay;
	    for (var i=0, l=pays.length; i<l; i++) {
		var pay = wsaleUtils.to_float(pays[i]);
		if (pay !== 0 && left > 0) {
		    left = left - pay;
		    if (left > 0)
			orders.push(pay);
		    else
			orders.push(left + pay);
		} else {
		    orders.push(0);
		} 
	    }

	    if (left > 0)
		orders[i - 1] += left;
	    // console.log(orders);
	    return orders;
	},

	pay_order_of_reject: function(should_pay, pays) {
	    // var pay = {ticket: 0, withdraw:0, wxin: 0, card: 0, cash:0};
	    var orders = [];
	    var left = should_pay;
	    
	    if (should_pay > 0) {
		for (var i=0, l=pays.length; i<l; i++) {
		    var pay = wsaleUtils.to_float(pays[i]); 
		    if ( pay !== 0 && left > 0) {
			left = left - pay;
			if (left > 0)
			    orders.push(pay);
			else
			    orders.push(left + pay);
		    } else {
			orders.push(0);
		    } 
		}

		if (left > 0)
		    orders[i - 1] += left;
	    } else {
		for (var i=0, l=pays.length; i<l; i++) {
		    var pay = wsaleUtils.to_float(pays[i]); 
		    if (pay !== 0 && left < 0) {
			left = left - pay;
			if (left < 0)
			    orders.push(pay);
			else
			    orders.push(left + pay);
		    } else {
			orders.push(0);
		    } 
		}

		if (left < 0)
		    orders[i - 1] += left;
	    }
	    
	    // console.log(orders);
	    return orders;
	},
	
	//
    }
}();

var gen_wsale_key = function(shop, retailer, dateFilter){
    var now = $.now();
    return "ws-"
    // + employee.toString()
	+ retailer.toString()
	+ "-" + shop.toString()
	+ "-" + dateFilter(now, 'mediumTime')
	+ "-" + now;
};

var wsaleDraft = function(storage, shop, retailer, dateFilter){
    this.storage  = storage;
    this.shop     = shop;
    this.retailer = retailer;
    // this.employee = employee;
    this.dateFilter = dateFilter;
    this.key = gen_wsale_key(this.shop, this.retailer, this.dateFilter);
};

wsaleDraft.prototype.get_key = function(){
    return this.key;
};

wsaleDraft.prototype.set_key = function(key){
    return this.key = key;
};

wsaleDraft.prototype.reset = function(){
    // console.log(this.key);
    this.key = gen_wsale_key(this.shop, this.retailer, this.dateFilter);
};

wsaleDraft.prototype.change_shop = function(shop){
    this.shop = shop;
    this.reset();
};

// wsaleDraft.prototype.change_employee = function(employee){
//     this.employee = employee; 
//     this.reset();
// };

wsaleDraft.prototype.change_retailer = function(retailer){
    // this.remove(this.key);
    this.retailer = retailer; 
    this.reset();
};

wsaleDraft.prototype.keys = function(){
    // var re = /^ws-\d+-\d+-\d+.*$/;
    var re = /^ws-\d+-\d+.*$/; 
    var keys = this.storage.keys();
    return keys.filter(function(k){
	return re.test(k)
    }).filter(function(k){
	return wsaleUtils.to_integer(k.split("-")[2]) === this.shop;
    }, this);
};

wsaleDraft.prototype.save = function(resources){
    var keys = this.keys().sort(function(k1, k2){
	return k2.split("-")[5] - k1.split("-")[5];
    });

    for (var i=4, l=keys.length; i<l; i++)
	this.remove(keys[i]);
    
    var key = this.key;
    this.storage.set(key, {v:resources});
};

wsaleDraft.prototype.list = function(draftFilter){
    var keys = this.keys();
    return draftFilter(keys).sort(function(k1, k2){
	// console.log(k1.sn.split("-")[5], k2.sn.split("-")[5]);
	return k2.sn.split("-")[4] - k1.sn.split("-")[4];
    }); 
};

wsaleDraft.prototype.remove = function(key){
    this.storage.remove(key);
};

wsaleDraft.prototype.select = function(dialog, template, draftFilter, selectCallback){
    var storage = this.storage;
    
    var callback = function(params){
	var select_draft = params.drafts.filter(function(d){
	    return angular.isDefined(d.select) && d.select
	})[0];
	
	// console.log(storage);
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
};

var diabloPaySpeak = function() {
    this.utterance = undefined;
    if('speechSynthesis' in window) {
	this.utterance = new SpeechSynthesisUtterance();
	if (angular.isDefined(this.utterance) && angular.isObject(this.utterance)) {
	    this.utterance.lang = 'zh-CN';
	    this.utterance.rate = 0.7;
	}
    }
    console.log(this.utterance);
};

diabloPaySpeak.prototype.set_text = function(text) {
    if (angular.isDefined(this.utterance) && angular.isObject(this.utterance)) {
	this.utterance.text = angular.isUndefined(text) ? "" : text; 
    }
};

diabloPaySpeak.prototype.speak = function() {
    if (angular.isDefined(this.utterance) && angular.isObject(this.utterance)) {
	window.speechSynthesis.cancel();
	window.speechSynthesis.speak(this.utterance);
    } 
};


var wsalePrint = function(){
    var left   = 1;
    var width  = 219; // inch, 5.8 / 2.45 * 96 
    var vWidth = width - left; 
    var hFont  = 20; // height of font
    
    var bold_style = function(LODOP) {
	LODOP.SET_PRINT_STYLEA(0, "FontSize", 9);
	LODOP.SET_PRINT_STYLEA(0, "Bold", 1);
    }
    
    var check_pay = function(cash, card, wxin, aliPay, withDraw, ticket, should_pay){
	console.log(cash, card, withDraw, ticket);
	var s = "", rdraw = 0;
	var left = should_pay; 
	if (wsaleUtils.to_float(ticket) != 0){
	    s += "券:" + ticket.toString(); 
	    if (ticket >= left) {
		left = 0;
	    } else {
		left -= ticket;
	    }
	}

	if (left > 0 && wsaleUtils.to_float(withDraw) != 0){
	    if (s) s += " ";
	    if (withDraw >= left) {
		rdraw = left; 
		s += "提现:" + left.toString();
		left = 0;
	    } else {
		rdraw = withDraw;
		s += "提现:" + withDraw.toString();
		left -= withDraw;
	    }
	}

	if (left > 0 && wsaleUtils.to_float(wxin) != 0) {
	    if (s) s += " ";
	    if (wxin >= left) {
		s += "微信:" + left.toString();
		left = 0;
	    } else {
		s += "微信:" + wxin.toString();
		left -= wxin;
	    }
	}

	if (left > 0 && wsaleUtils.to_float(aliPay) != 0) {
	    if (s) s += " ";
	    if (wxin >= left) {
		s += "支付宝:" + left.toString();
		left = 0;
	    } else {
		s += "支付宝:" + aliPay.toString();
		left -= wxin;
	    }
	}

	if (left > 0 && wsaleUtils.to_float(card) != 0){
	    if (s) s += " ";
	    
	    if (card >= left){
		s += "刷卡:" + left.toString();
		left = 0;
	    } else {
		s += "刷卡:" + card.toString();
		left -= card;
	    }
	}
	
	if (left > 0 && wsaleUtils.to_float(cash) != 0){
	    if (s) s += " "; 
	    if (cash >= left){
		s += "现金:" + left.toString();
		left = 0;
	    }
	    else {
		s += "现金:" + cash.toString();
		left -= cash;
	    }
	}

	return {rdraw:rdraw, s:s}; 
    };

    return {
	gen_head: function(LODOP, shop, rsn, employee, retailer, date, direct, pSetting){
	    // wsalePrint.init(LODOP);
	    wsalePrint.init(LODOP);

	    var top = 10;
	    if (pSetting.head_seperater !== 0) {
		var shopA = shop.split(diablo_dash_seperator);
		for (var i=0, l=shopA.length; i<l; i++) {
		    LODOP.ADD_PRINT_TEXT(top, left, vWidth, 30, shopA[i]); 
		    if (i===0) LODOP.SET_PRINT_STYLEA(0, "FontSize", 13);
		    else LODOP.SET_PRINT_STYLEA(0, "FontSize", 10);
		    if (pSetting.head_seperater === 1) {
			LODOP.SET_PRINT_STYLEA(0, "Alignment", 2); 
		    } else if (pSetting.head_seperater === 2) {
			LODOP.SET_PRINT_STYLEA(0, "Alignment", 1); 
		    }
		    LODOP.SET_PRINT_STYLEA(0, "Bold", 1);
		    top += 25
		}
	    } else {
		LODOP.ADD_PRINT_TEXT(
		    top,
		    left,
		    vWidth,
		    30,
		    wsaleUtils.to_integer(direct) === 0 ? shop : shop + "（退）"); 
		LODOP.SET_PRINT_STYLEA(0, "FontSize", 13);
		if (pSetting.head_seperater === 0) {
		    LODOP.SET_PRINT_STYLEA(0, "Alignment", 1); 
		} else if (pSetting.head_seperater === 3) {
		    LODOP.SET_PRINT_STYLEA(0, "Alignment", 2); 
		}
		LODOP.SET_PRINT_STYLEA(0, "Bold", 1);
		top += 25; 
		// LODOP.SET_PRINT_STYLEA(0, "Alignment", 2);
	    } 
	    
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

	gen_body: function(LODOP, top, sale, inventories, round, pSetting){
	    top += 15;
	    // var perform = 0;
	    // if (diablo_no === cakeMode) {
	    LODOP.ADD_PRINT_TEXT(top, left, 70, hFont, "款号"); 
	    LODOP.ADD_PRINT_TEXT(top, left + 70, 35, hFont, "单价"); 
	    LODOP.ADD_PRINT_TEXT(top, left + 105, 35, hFont, "数量");
	    if (pSetting.print_discount)
		LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, "折扣率");
	    else
		LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, "折后价");

	    top += 15;
	    
	    angular.forEach(inventories, function(d){
		console.log(d);
		var calc = function() {
		    if (angular.isUndefined(round) || round)
			return diablo_round(d.total * d.rprice).toString();
		    else
			return (d.total * d.rprice).toString();
		}();
		
		var vprice = d.tag_price;
		if (wsaleUtils.to_float(d.vir_price) > wsaleUtils.to_float(d.tag_price)) {
		    vprice = d.vir_price;
		}
		// perform += d.total * vprice - calc;

		LODOP.ADD_PRINT_TEXT(top, left + 70, 35, hFont, vprice.toString()); 
		LODOP.ADD_PRINT_TEXT(top, left + 105, 35, hFont, d.total.toString());
		
		var ediscount = wsaleUtils.ediscount(d.rprice, vprice).toString(); 
		if (pSetting.print_discount) {
		    LODOP.ADD_PRINT_TEXT(top, left + 140, left + 140, hFont, ediscount.toString()); 
		}
		else {
		    LODOP.ADD_PRINT_TEXT(
			top, left + 140, vWidth - left - 140, hFont, d.rprice.toString()); 
		}
		
		var maxLines = Math.ceil(d.style_number.length / 10);
		var i = 0;
		for (i=0; i<maxLines; i++) {
		    var s = d.style_number.substring(
			i*10,
			d.style_number.length - i*10 > 10 ? i*10 + 10 : d.style_number.length);
		    LODOP.ADD_PRINT_TEXT(top, left, 85, hFont, s);
		    top += 15;
		    if (i === 0) {
			if (pSetting.print_discount) {
			    LODOP.ADD_PRINT_TEXT(
				top, left + 140, vWidth - left - 140, hFont, d.rprice.toString());
			}
		    }
		}
		
		// LODOP.ADD_PRINT_TEXT(top, left, 70, hFont, d.style_number);
		    
		// LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, calc.toString()); 
		
		// top += 15; 
		// if (pSetting.print_discount) {
		//     LODOP.ADD_PRINT_TEXT(
		// 	top, left + 140, vWidth - left - 140, hFont, d.rprice.toString());
		// }
		// LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, calc.toString());

		var brand = angular.isObject(d.brand) && angular.isDefined(d.brand.name) ? d.brand.name : d.brand;
		brand += angular.isObject(d.type) && angular.isDefined(d.type.name) ? d.type.name : d.type;
		
		// var brand = angular.isObject(d.type) && angular.isDefined(d.type.name) ? d.type.name : d.type;
		maxLines = Math.ceil(brand.length / 10);
		for (i=0; i<maxLines; i++) {
		    LODOP.ADD_PRINT_TEXT(
			top,
			left,
			vWidth - left,
			hFont,
			brand.substring(i*10, brand.length - i*10 > 10 ? i*10 + 10 : brand.length));
		    
		    // if (i === 0) {
		    // 	LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, calc.toString()); 
		    // }
		    
		    top += 15; 
		}
		
		// LODOP.ADD_PRINT_TEXT(top, left, vWidth - left, hFont, brand); 
		// top += 5;
		if (wsaleUtils.to_integer(d.bargin_price) === 3) {
		    LODOP.ADD_PRINT_TEXT(top, left, vWidth - left, hFont, d.note + "/特价"); 
		} else {
		    LODOP.ADD_PRINT_TEXT(top, left, vWidth - left, hFont, d.note);
		}

		LODOP.ADD_PRINT_TEXT(top, left + 140, vWidth - left - 140, hFont, calc.toString()); 

		top += 15;
		LODOP.ADD_PRINT_LINE(top, left, top, vWidth, 0, 1);
		top += 5; 
	    }); 
	    // sale.perform = perform;
	    return top;
	},

	gen_stastic: function(LODOP, hLine, direct, sale, balance, vip, pSetting){
	    console.log(sale);
	    // console.log(hLine);
	    if (angular.isUndefined(direct)) direct = 0;
	    var cash     = sale.cash;
	    var card     = sale.card;
	    var withDraw = sale.withdraw;
	    var wxin     = sale.wxin;
	    var aliPay   = sale.aliPay;
	    var ticket   = angular.isDefined(sale.ticket) ? sale.ticket : sale.ticket_balance;
	    
	    var total = sale.total;
	    var should_pay = sale.should_pay;
	    var comment = angular.isUndefined(sale.comment) ? "" : sale.comment;
	    var score = direct === diablo_sale ? sale.score : -sale.score;
	    var ticketScore = sale.ticket_score;
	    
	    var lscore = function(){
		if (sale.hasOwnProperty("lscore")) return sale.lscore;
		else if (sale.hasOwnProperty("last_score")) return sale.last_score;
		else if (sale.hasOwnProperty("retailer")) return sale.retailer.score;
	    }();

	    var l1 = "总计：" + total.toString() + "  备注：" + comment;
	    console.log(l1);
	    hLine += 5;
	    LODOP.ADD_PRINT_TEXT(hLine, left, vWidth, hFont, l1);
	    hLine += 15; 
	    
	    if (diablo_sale === direct) l1 = "应付：";
	    if (diablo_reject === direct) l1 = "退款：";
	    
	    l1 += should_pay.toString();

	    var pay = check_pay(cash, card, wxin, aliPay, withDraw, ticket, should_pay);
	    l1 += " " + pay.s;
	    console.log(l1); 
	    LODOP.ADD_PRINT_TEXT(hLine, left, vWidth, hFont, l1);
	    hLine += 10
	    LODOP.ADD_PRINT_LINE(hLine + 5, left, hLine + 5, vWidth, 0, 1); 
	    hLine += 15; 
	    if (diablo_sale === direct) {
		LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont,  "实付");
		bold_style(LODOP);
		LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, "找零");
		bold_style(LODOP);
		LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 100, hFont, "优惠");
		bold_style(LODOP); 
		hLine += 15;
		
		if (angular.isDefined(sale.has_pay)) {
		    l1 = wsaleUtils.to_float(sale.has_pay).toString();
		    LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont, l1);
		    bold_style(LODOP);
		}
		
		if (angular.isDefined(sale.charge)) {
		    l1 = wsaleUtils.to_float(-sale.charge).toString()
		    LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, l1);
		    bold_style(LODOP);
		}
		
		if (pSetting.print_perform) {
		    l1 = wsaleUtils.to_float(sale.base_pay - sale.should_pay).toString();
		    LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 135, hFont, l1);
		    bold_style(LODOP);
		}

		hLine += 15;
	    }
		

	    if (vip && pSetting.print_score) {
		LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont,  "上次积分");
		LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, "本次积分");
		LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 100, hFont, "累计积分");

		hLine += 15;
		LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont,  lscore.toString());
		LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, score.toString());

		l1 = (lscore + score - ticketScore).toString();
		LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 100, hFont, l1); 
		hLine += 15;
	    } 

	    if (vip && wsaleUtils.to_integer(balance) != 0) {
		LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont,  "余额");
		LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, "提现");
		LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 100, hFont, "结余");

		hLine += 15;
		LODOP.ADD_PRINT_TEXT(hLine, left, 70, hFont, balance.toString());
		LODOP.ADD_PRINT_TEXT(hLine, left + 70, 65, hFont, pay.rdraw.toString());
		l1 = (balance - pay.rdraw).toString();
		LODOP.ADD_PRINT_TEXT(hLine, left + 135, vWidth - 135, hFont, l1);
		hLine += 15;
	    }

	    LODOP.ADD_PRINT_LINE(hLine + 5, left, hLine + 5, vWidth, 0, 1);
	    hLine += 15;
	    
	    return hLine;
	},
	
	gen_foot: function(LODOP, hLine, date, shop, pSetting){
	    // console.log(hLine);
	    // console.log(comments);
	    // console.log(date);
	    if (diablo_no === pSetting.cake_mode){
		var order = 1;
		LODOP.ADD_PRINT_TEXT(hLine, left, vWidth, hFont, "顾客需知：");
		hLine += 20;
		var char_per_line = pSetting.print_char_per_line;
		if ( 0 === char_per_line) {
		    char_per_line = 14;
		}
		
		angular.forEach(pSetting.comments, function(c){
		    if (c){
			var s = order.toString() + ":" + c.name;
			var maxLines = Math.ceil(s.length / char_per_line); 
			for (var i=0; i<maxLines; i++) {
			    LODOP.ADD_PRINT_TEXT(
				hLine,
				left,
				vWidth,
				hFont,
				s.substr(i*char_per_line,
					 s.length > i*char_per_line ? char_per_line : s.length));
			    hLine += 15; 
			} 
			order++;
		    }
		});

	    } else {
		LODOP.ADD_PRINT_TEXT(hLine, 50, 178, 20, "谢谢惠顾！！");
		hLine += 15;
	    }
	    // console.log(s);
	    // LODOP.ADD_PRINT_TEXT(hLine, 5, 178, 140, order.toString() + "：" + s);

	    var s = "打印日期:" + date;
	    LODOP.ADD_PRINT_TEXT(hLine, left, vWidth, hFont, s);

	    if (shop.addr) {
		hLine += 15;
		LODOP.ADD_PRINT_TEXT(hLine, left, vWidth, hFont, "地址:" + shop.addr);
	    }

	    if (shop.bcode_friend) {
		hLine += 15;
		LODOP.ADD_PRINT_IMAGE(
		    hLine, left + 25, 120, 120,
		    "<img src='https://qzgui.com/" + shop.bcode_friend + "?" + Math.random() + "'/>");
	    }
	    
	    hLine += 15;
	},

	init: function(LODOP) {
	    LODOP.PRINT_INIT("task_print_wsale");
	    LODOP.SET_PRINTER_INDEX(-1);
	    LODOP.SET_PRINT_PAGESIZE(3, 580, 0, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	},

	start_print: function(LODOP, callback){
	    // wsalePrint.init(LODOP);
	    // LODOP.PRINT_DESIGN();
	    // LODOP.PREVIEW();
	    if (angular.isFunction(callback)) {
		LODOP.SET_PRINT_MODE("CATCH_PRINT_STATUS",true);
		if (LODOP.CVERSION) {
		    LODOP.On_Return = function(task, job) {
			if (job) 
			    callback(job);
		    }
		    LODOP.PRINT();
		} else {
		    var job = LODOP.PRINT();
		    if (job) 
			callback(job); 
		}
	    } else {
		// LODOP.PREVIEW();
		LODOP.PRINT();
	    }
	    
	} 
    }
}();
