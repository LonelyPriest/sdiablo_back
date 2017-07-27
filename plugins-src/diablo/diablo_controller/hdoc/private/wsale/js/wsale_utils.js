var wsaleUtils = function(){
    var in_sort = function(sorts, sell){
	for (var i=0, l=sorts.length; i<l; i++){
	    if (sell.style_number === sorts[i].style_number 
		&& sell.brand_id   === sorts[i].brand_id){
		// sorts[i].total += sell.sell;
		sorts[i].reject += sell.amount;
		sorts[i].amounts.push({
		    cid        :sell.color_id,
		    size       :sell.size,
		    sell_count :sell.amount});
		return true;
	    } 
	}
	return false; 
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
	select.withdraw   = base.withdraw;
	select.should_pay = base.should_pay;
	
	select.comment    = base.comment;
	select.total      = base.total;
	select.score      = base.score;
	
	select.tbatch     = base.tbatch;
	select.ticket     = base.ticket; 
	select.ticket_score = base.ticket_score;

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
		// add.sex     = s.sex;
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
		add.fprice    = s.fprice;
		add.rprice    = s.rprice;
		add.fdiscount = s.fdiscount;
		add.rdiscount   = s.rdiscount;
		add.o_fdiscount = s.fdiscount;
		add.o_fprice    = s.fprice;
		
		add.reject    = s.amount;
		add.total     = s.total;
		
		add.pid       = s.pid;
		add.sid       = s.sid;
		
		add.sizes.push(s.size);
		add.colors_id.push(s.color_id);
		
		add.amounts.push({
		    cid: s.color_id,
		    size:s.size,
		    sell_count:s.amount});

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
		    + "，" + (inv.brand.name ? inv.brand.name : inv.brand)
		    + "，" + (inv.type.name  ? inv.type.name: inv.type),
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
	    base, sells, shops, brands, retailers,
	    employees, types, colors, size_groups, promotions, scores){
	    var wsale         = sort_wsale(base, sells);
	    var details       = wsale.details;
	    var order_length  = details.length;
	    
	    var show_promotions = [];
	    angular.forEach(details, function(d){

		if (d.sizes.length !== 1 || d.sizes[0] !== "0"){
		    d.sizes = get_size_group(d.s_group, size_groups)
		}

		d.colors = d.colors_id.map(function(id){
		    return diablo_find_color(id, colors)
		});
		
		d.brand     = diablo_get_object(d.brand_id, brands);
		d.type      = diablo_get_object(d.type_id, types); 
		d.promotion = diablo_get_object(d.pid, promotions);
		d.score     = diablo_get_object(d.sid, scores);
		d.select    = true;
		// d.select    = d.total > 0 ? true : false;
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
	    return diablo_base_setting(
		"pround", shop, base, parseInt, diablo_round_record);
	},

	typeahead: function(shop, base){
	    return diablo_base_setting(
		"qtypeahead", shop, base, parseInt, diablo_yes);
	},

	im_print: function(shop, base){
	    return diablo_base_setting(
		"pim_print", shop, base, parseInt, diablo_no); 
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd"));
	},

	check_sale: function(shop, base){
	    return diablo_base_setting(
		"check_sale", shop, base, parseInt, diablo_yes);
	},

	negative_sale: function(shop, base){
	    return diablo_base_setting(
		"m_sale", shop, base, parseInt, diablo_yes);
	},

	show_sale_day: function(shop, base){
	    // default current day
	    return diablo_base_setting("d_sale", shop, base, parseInt, 0);
	},

	print_mode: function(shop, base){
	    return diablo_base_setting(
		"ptype", shop, base, parseInt, diablo_backend);
	},

	sequence_pagination: function(shop, base){
	    return diablo_base_setting(
		"se_pagination", shop, base, parseInt, diablo_no);
	},

	no_vip: function(shop, base){
	    return diablo_base_setting(
		"s_customer", shop, base, parseInt, diablo_no);
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
	    return diablo_base_setting("pum", shop, base, parseInt, 1);
	},

	round: function(shop, base){
	    return diablo_base_setting("round", shop, base, parseInt, diablo_yes);
	},

	scanner: function(shop, base) {
	    return diablo_base_setting("scanner", shop, base, parseInt, diablo_no);
	},

	s_member: function(shop, base) {
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
		scores.push({
		    score:s, p: p, money: money});
	    }

	    return scores;
	},

	calc_with_promotion: function(pmoneys, round){
	    var balance = 0;
	    var rbalance = 0;
	    var f_mul = diablo_float_mul;
	    
	    for ( var i=0, l=pmoneys.length; i<l; i++){
		var p = pmoneys[i].p;
		balance += pmoneys[i].money;
		
		// if (p.rule_id === -1){
		//     balance += pmoneys[i].money;
		//     continue;
		// }

		// if (p.rule_id === 0){
		//     balance += pmoneys[i].money;
		//     continue;
		// }

		if (p.rule_id === 1){
		    if (pmoneys[i].money >= 0){
			rbalance += Math.floor(pmoneys[i].money / p.cmoney) *  p.rmoney; 
		    } else {
			rbalance += Math.ceil(pmoneys[i].money / p.cmoney) *  p.rmoney; 
		    }
		    continue;
		}
	    }

	    // console.log(round);
	    if (angular.isUndefined(round) || round) 
		return {balance: diablo_round(balance - rbalance), rbalance: rbalance};
	    else
		return {balance: wsaleUtils.to_decimal(balance - rbalance), rbalance: rbalance};
	},

	calc_discount_of_rmoney: function(discount, promotion, pmoneys){
	    // var r = {};
	    if (promotion.rule_id === 0 ){
		    return diablo_full_discount; 
	    } else {
		var balance = 0;
		var total_balance = 0;
		var rmoney = 0;
		var f_mul = diablo_float_mul;
		for ( var i=0, l=pmoneys.length; i<l; i++ ){
		    var p = pmoneys[i].p; 
		    if (p.rule_id === 1 && promotion.id === p.id){
			if (pmoneys[i].money >= 0){
			    rmoney = Math.floor(pmoneys[i].money / p.cmoney) * p.rmoney; 
			} else {
			    rmoney = Math.ceil(pmoneys[i].money / p.cmoney) * p.rmoney; 
			}
			total_balance += pmoneys[i].money;
			balance += pmoneys[i].money - rmoney;
		    }
		}
		console.log(total_balance, balance, rmoney);
		if (rmoney !== 0 ){
		    return diablo_discount(balance, total_balance);
		} else {
		    return diablo_full_discount;
		}
	    } 
	},

	calc_with_score: function(pscores, verificate){
	    // console.log(pscores, verificate);
	    var score = 0; 
	    if (pscores.length > 0){
		var s = pscores[0];
		if (angular.isDefined(s.score)) {
		    score = Math.floor((diablo_round(s.money) - verificate) / s.score.balance) * s.score.score; 
		    for ( var i=1, l=pscores.length; i<l; i++){
			s = pscores[i];
			score += Math.floor(diablo_round(s.money) / s.score.balance) * s.score.score; 
		    } 
		} 
	    }
	    
	    return score;
	},

	calc_score_of_money: function(money, score){
	    return Math.floor(money / score.balance) * score.score;
	    // return Math.ceil(money / score.balance) * score.score;
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

	to_decimal:function(v){
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

	extra_error:function(result) {
	    if (result.ecode === 2705) 
		return "应付金额：" + result.should_pay.toString() +
		"，计算金额：" + result.check_pay.toString();
	    else if (result.ecode === 2708)
		return "当前日期[" + result.fdate + "]，"
		+ "服务器日期[" + result.bdate + "]";
	    else
		return ""
	}

	// 
	
    }

}();

var wsaleCalc = function(){
    return {
	calculate: function(o_retailer,
			    retailer,
			    no_vip,
			    inventories,
			    show_promotions,
			    mode,
			    verificate,
			    round){
	    var total        = 0;
	    var abs_total    = 0;
	    var should_pay   = 0;
	    var score        = 0;
	    // var charge       = 0;
	    
	    var pmoneys = []; 
	    var pscores = []; 
	    for (var i=1, l=inventories.length; i<l; i++){
		var one = inventories[i];
		
		if (angular.isDefined(one.select) && !one.select) continue;
		
		var count = (mode === 0 ? one.sell : one.reject);
		// console.log(count);
		
		total      += parseInt(count);
		abs_total  += Math.abs(parseInt(count));
		
		// if (retailer.id !== o_retailer.id){
		//     if (o_retailer.id === no_vip){
		// 	if (retailer.id !== no_vip){
		// 	    if (one.pid !== -1 && one.promotion.rule_id === 0){
		// 		one.fdiscount = one.promotion.discount;
		// 	    }	
		// 	}
		//     } else {
		// 	if (retailer.id === no_vip){
		// 	    one.fdiscount = one.discount;
		// 	}
		//     }
		// }

		// console.log(one);
		if (one.o_fprice !== one.fprice){
		    one.fdiscount = diablo_discount(one.fprice, one.tag_price);
		} else if (one.o_fdiscount !== one.fdiscount){
		    if (one.tag_price == 0){
			one.fprice = diablo_price(one.fprice, one.fdiscount); 
		    } else {
			one.fprice = diablo_price(one.tag_price, one.fdiscount); 
		    }
		}

		one.o_fprice    = one.fprice;
		one.o_fdiscount = one.fdiscount;
		one.rdiscount   = diablo_full_discount;
		one.rprice      = one.fprice;
		one.calc        = diablo_float_mul(one.fprice, count);
		// console.log(one.calc);

		// if (retailer.id === no_vip){
		//     wsaleUtils.sort_promotion({id: -1, rule_id: -1}, one.calc, pmoneys);
		//     wsaleUtils.delete_format_promotion(one, show_promotions);
		// } else {
		if (one.pid === -1){
		    wsaleUtils.sort_promotion({id: -1, rule_id: -1}, one.calc, pmoneys);
		    wsaleUtils.format_promotion(one, show_promotions);
		    // if (one.sid === -1){
		    // 	wsaleUtils.delete_format_promotion(one, show_promotions);
		    // } else {
		    // 	wsaleUtils.format_promotion(one, show_promotions);
		    // }
		} else {
		    wsaleUtils.sort_promotion(one.promotion, one.calc, pmoneys);
		    wsaleUtils.format_promotion(one, show_promotions);
		}
		// }
		// console.log(one.calc); 
	    }
	    
	    // console.log(pmoneys);
	    
	    // calculate rmoney, all the promotion change to discount
	    for (var i=1, l=inventories.length; i<l; i++){
		var one = inventories[i];

		var count = (mode === 0 ? one.sell : one.reject);
		
		// if (one.pid !== -1 && retailer.id !== no_vip){
		if (one.pid !== diablo_invalid_index){
		    one.rdiscount = wsaleUtils.calc_discount_of_rmoney(
			one.fdiscount, one.promotion, pmoneys);
		    
		    if (one.fdiscount !== one.rdiscount){
			one.rprice  = diablo_price(one.fprice, one.rdiscount);
			console.log(one.rprice);
			one.calc    = diablo_float_mul(one.rprice, count);
		    }		    
		    // wsaleUtils.sort_score(one.score, one.promotion, one.calc, pscores);
		}

		// if (one.sid !== -1 && retailer.id !== no_vip){
		if (one.sid !== diablo_invalid_index){
		    wsaleUtils.sort_score(one.score, one.promotion, one.calc, pscores);
		} 
		// console.log(one.calc);
	    }

	    // calcuate with verificate
	    wsaleCalc.calc_discount_of_verificate(inventories, mode, verificate); 
	    
	    var calc_p = wsaleUtils.calc_with_promotion(pmoneys, round);
	    // console.log(calc_p);
	    should_pay = wsaleUtils.to_decimal(calc_p.balance - verificate); 
	    score  = wsaleUtils.calc_with_score(pscores, verificate); 
	    // charge = should_pay - has_pay;

	    return {
		total:      total,
		abs_total:  abs_total,
		should_pay: should_pay,
		score:      score,
		rbalance:   calc_p.rbalance
		// charge:     charge 
	    }; 
	},

	calc_discount_of_verificate: function(inventories, mode, verificate){
	    if (!angular.isDefined(verificate) || !verificate){
		return;
	    }
	    
	    var p1 = 0;
	    for (var i=1, l=inventories.length; i<l; i++){
		var one = inventories[i];
		var count = mode === 0 ? one.sell : one.reject;
		p1 += one.fprice * count;
	    }

	    var vdiscount = diablo_discount(verificate, p1);
	    for (var i=1, l=inventories.length; i<l; i++){
		var one = inventories[i];
		var count = mode === 0 ? one.sell : one.reject;
		one.rdiscount = wsaleUtils.to_decimal(one.rdiscount - vdiscount);
		one.rprice  = diablo_price(one.fprice, one.rdiscount);
		one.calc    = wsaleUtils.to_decimal(one.rprice * count);
		console.log(one.calc);
	    }
	}
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

    for (var i=3, l=keys.length; i<l; i++)
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

var wsalePrint = function(){
    var pay = function(cash, card, withDraw, ticket, should_pay){
	console.log(cash, card, withDraw);
	var s = "";
	var left = should_pay;
	if (wsaleUtils.to_float(cash) != 0){
	    if (cash >= left){
		s += "现金：" + left.toString();
		left = 0;
	    }
	    else {
		s += "现金：" + cash.toString();
		left -= cash;
	    }
	}
	if (wsaleUtils.to_float(card) != 0){
	    if (s) s += " ";
	    
	    if (card >= left){
		s += "刷卡：" + left.toString();
		left = 0;
	    } else {
		s += "刷卡：" + card.toString();
		left -= card;
	    }
	}
	if (wsaleUtils.to_float(withDraw) != 0){
	    if (s) s += " "; 
	    s += "提现：" + withDraw.toString();
	}
	if (wsaleUtils.to_float(ticket) != 0){
	    if (s) s += " "; 
	    s += "券：" + ticket.toString();
	}

	return s;
	// if (wsaleUtils.to_float(veri) != 0){
	//     if (s) {
	// 	s += "  ";
	//     }
	//     s += "核销：" + veri.toString();
	// }
    };
    
    return {
	gen_head: function(LODOP, shop, rsn, employee, retailer, date){
	    LODOP.ADD_PRINT_TEXT(5, 0, "58mm", 30, shop); 
	    LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
	    LODOP.SET_PRINT_STYLEA(1,"bold",1);
	    // LODOP.SET_PRINT_STYLEA(1,"Horient",2); 
	    LODOP.ADD_PRINT_TEXT(40,0,"58mm",20,"单号：" + rsn);
	    LODOP.ADD_PRINT_TEXT(55,0,"58mm",20,"客户：" + retailer);
	    
	    LODOP.ADD_PRINT_TEXT(70,0,"58mm",20,"店员：" + employee);
	    LODOP.ADD_PRINT_TEXT(85,0,"58mm",20,"日期：" + date); 
	    LODOP.ADD_PRINT_LINE(105,0,105,178,0,1);

	    return;
	},

	gen_body: function(LODOP, inventories, round, cakeMode){
	    var hLine = 115;
	    if (diablo_no === cakeMode) {
		LODOP.ADD_PRINT_TEXT(hLine,0,67,20,"款号"); 
		LODOP.ADD_PRINT_TEXT(hLine,67,100,20,"单价"); 
		LODOP.ADD_PRINT_TEXT(hLine,100,133,20,"数量"); 
		LODOP.ADD_PRINT_TEXT(hLine,133,178,20,"折扣率");

		hLine += 15;
		
		angular.forEach(inventories, function(d){
		    var calc = function() {
			if (angular.isUndefined(round) || round)
			    return diablo_round(d.total * d.rprice).toString();
			else
			    return (d.total * d.rprice).toString();
		    }();
		    
		    var ediscount = wsaleUtils.ediscount(d.rprice, d.tag_price).toString();
			
		    LODOP.ADD_PRINT_TEXT(hLine,0,67,20, d.style_number);
		    LODOP.ADD_PRINT_TEXT(hLine, 67, 100, 20, d.tag_price.toString());
		    LODOP.ADD_PRINT_TEXT(hLine,100,133,20, d.total.toString());
		    LODOP.ADD_PRINT_TEXT(hLine,133,178,20, ediscount.toString());
		    
		    hLine += 15;
		    LODOP.ADD_PRINT_TEXT(hLine, 0, 67, 20, d.brand);
		    LODOP.ADD_PRINT_TEXT(hLine, 133, 178, 20, d.rprice.toString());

		    hLine += 15;
		    LODOP.ADD_PRINT_TEXT(hLine, 133, 178, 20, calc.toString());

		    hLine += 15;
		    LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
		    hLine += 5;
			
		    // LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"款号：" + d.style_number);
		    // LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"品名：" + d.brand);
		    // hLine += 15;
		    // } else {
		    // 	LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"类型：" + d.type);
		    // 	hLine += 15;
		    // }
		    
		    

		    // if (diablo_no === cakeMode){
		    //     LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"成交价：" + d.rprice.toString());
		    //     hLine += 15;
		    // }
		    
		    // LODOP.ADD_PRINT_TEXT(hLine,100,133,20, d.total.toString());
		    // hLine += 15;
		    
		    // LODOP.ADD_PRINT_TEXT(hLine,0,178,20,"小计："
		    // 		     + function() {
		    // 			 if (angular.isUndefined(round) || round)
		    // 			     return diablo_round(d.total * d.rprice).toString();
		    // 			 else
		    // 			     return (d.total * d.rprice).toString();
		    // 		     }())
		    // hLine += 15;

		    // if (diablo_no === cakeMode){
		    //     var ediscount = wsaleUtils.ediscount(d.rprice, d.tag_price).toString();
		    //     LODOP.ADD_PRINT_TEXT(hLine,133,178,20, ediscount);
		    //     hLine += 20; 
		    // } else {
		    //     hLine += 5;
		    // }
		    
		    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
		    // hLine += 10;
		});
	    } else {
		LODOP.ADD_PRINT_TEXT(hLine,0,80,20,"类型 "); 
		LODOP.ADD_PRINT_TEXT(hLine,80,113,20,"数量"); 
		LODOP.ADD_PRINT_TEXT(hLine,113,146,20,"单价"); 
		LODOP.ADD_PRINT_TEXT(hLine,146,178,20,"小计");

		hLine += 15;
		
		angular.forEach(inventories, function(d){
		    var calc = function() {
			if (angular.isUndefined(round) || round)
			    return diablo_round(d.total * d.rprice).toString();
			else
			    return (d.total * d.rprice).toString();
		    }();
		    
		    LODOP.ADD_PRINT_TEXT(hLine,0, 80, 20, d.type);
		    LODOP.ADD_PRINT_TEXT(hLine, 80, 113, 20, d.total.toString());
		    LODOP.ADD_PRINT_TEXT(hLine,113,146,20, d.tag_price.toString());
		    LODOP.ADD_PRINT_TEXT(hLine,146,178,20, calc.toString());
		    
		    hLine += 15;
		    // LODOP.ADD_PRINT_TEXT(hLine, 0, 67, 20, d.brand);
		    // LODOP.ADD_PRINT_TEXT(hLine, 133, 178, 20, d.rprice.toString());
		    
		    // hLine += 15;
		    // LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
		    // hLine += 5; 
		});

		// hLine += 5;
		LODOP.ADD_PRINT_LINE(hLine,0,hLine,178,0,1);
		hLine += 5;
	    } 
	    return hLine;
	},

	gen_stastic: function(LODOP, hLine, direct, sale, vip){
	    // console.log(sale);
	    console.log(hLine);
	    if (angular.isUndefined(direct)) direct = 0;
	    var cash = sale.cash;
	    var card = sale.card;
	    var withDraw = sale.withdraw;
	    var ticket = sale.ticket;
	    
	    var total = sale.total;
	    var should_pay = sale.should_pay;
	    var comment = angular.isUndefined(sale.comment) ? "" : sale.comment;
	    var score = sale.score;
	    var ticketScore = sale.ticket_score;
	    
	    var lscore = function(){
		if (sale.hasOwnProperty("lscore")) return sale.lscore;
		else if (sale.hasOwnProperty("last_score")) return sale.last_score;
		else if (sale.hasOwnProperty("retailer")) return sale.retailer.score;
	    }();

	    var l1 = "总计：" + total.toString() + "  备注：" + comment;
	    console.log(l1);
	    LODOP.ADD_PRINT_TEXT(hLine, 0, "52mm", 20, l1);
	    hLine += 15; 
	    
	    if (0 === direct) l1 = "实付：";
	    if (1 === direct) l1 = "退款：";
	    l1 += should_pay.toString(); 
	    l1 += " " + pay(cash, card, withDraw, ticket, should_pay);
	    console.log(l1);
	    LODOP.ADD_PRINT_TEXT(hLine, 0, "52mm", 20, l1);
	    hLine += 15;

	    if (vip) {
		l1 = "上次积分：" + lscore.toString();
		LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, l1);
		hLine += 15;
		l1 = "本次积分：" + score.toString() + "\n";
		LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, l1);
		hLine += 15;
		l1 = "累积积分：" + (lscore + score - ticketScore).toString() + "\n";
		LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, l1);
		hLine += 15;
	    }

	    LODOP.ADD_PRINT_LINE(hLine + 5, 0, hLine + 5, 178, 0, 1);

	    return hLine + 15;
	},
	
	gen_foot: function(LODOP, hLine, comments, date, cakeMode){
	    // console.log(hLine);
	    // console.log(comments);
	    // console.log(date);
	    if (diablo_no === cakeMode){
		var order = 1;
		// var height = 0;
		LODOP.ADD_PRINT_TEXT(hLine, 0, 178, 20, "顾客需知：");
		hLine += 20;
		angular.forEach(comments, function(c){
		    if (c){
			var s = order.toString() + "：" + c.name;
			LODOP.ADD_PRINT_TEXT(hLine, 0, "52mm", 40, order.toString() + "：" + c.name);
			hLine += 35;

			console.log(s.length); 
			if (s.length > 30) hLine += 15;
			
			order++;
		    }
		});
	    } else {
		LODOP.ADD_PRINT_TEXT(hLine, 50, 178, 20, "谢谢惠顾！！");
		hLine += 15;
	    }
	    // console.log(s);
	    // LODOP.ADD_PRINT_TEXT(hLine, 5, 178, 140, order.toString() + "：" + s);

	    var s = "打印日期：" + date;
	    LODOP.ADD_PRINT_TEXT(hLine, 0, "58mm", 20, s);
	},

	start_print: function(LODOP){
	    LODOP.SET_PRINT_PAGESIZE(3,"58mm",50,""); 
	    // LODOP.PREVIEW();
	    LODOP.PRINT();
	}
    }
}();
