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
	select.withdraw   = base.withdraw;
	select.should_pay = base.should_pay;
	
	select.comment    = base.comment;
	select.total      = base.total;
	select.score      = base.score;

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
	    
	    console.log(promotions);
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
	    base, sells, shops, brands, retailers, employees,
	    types, colors, size_groups, promotions, scores){
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
		d.order_id  = order_length;

		if (-1 !== d.pid && -1 !== d.sid){
		    wsaleUtils.format_promotion(d, show_promotions); 
		}
		
		order_length--; 
		
	    });

	    wsale.select.shop = diablo_get_object(wsale.select.shop_id, shops); 
	    wsale.select.retailer = diablo_get_object(wsale.select.retailer_id, retailers);
	    wsale.select.employee = diablo_get_object(wsale.select.employee_id, employees);
	    
	    wsale.show_promotions = show_promotions;
	    return wsale;
	},

	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "，" + brand + "，" + type;
	    var prompt = name + "," + diablo_pinyin(name); 
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

	only_show_current: function(shop, base){
	    return diablo_base_setting(
		"d_sale", shop, base, parseInt, diablo_yes);
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
		if (c) {comments.push({id:1, name:c})} 
	    } 
	    return comments;
	},

	get_login_employee:function(shop, loginEmployee, employees){
	    var filterEmployees = employees.filter(function(e){
		return e.shop === shop;
	    });
	    
	    var select = undefined;
	    if (diablo_invalid_employee !== loginEmployee)
		select = diablo_get_object(loginEmployee, filterEmployees); 
	    
	    if (angular.isUndefined(select)) select = filterEmployees[0];

	    console.log(select);
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

	calc_with_promotion: function(pmoneys){
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

	    return {balance: diablo_round(balance - rbalance), rbalance: rbalance};
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
		score = Math.floor((diablo_round(s.money) - verificate) / s.score.balance) * s.score.score; 
		for ( var i=1, l=pscores.length; i<l; i++){
		    s = pscores[i];
		    score += Math.floor(diablo_round(s.money) / s.score.balance) * s.score.score; 
		} 
	    }
	    
	    return score;
	},

	calc_score_of_money: function(money, score){
	    return Math.floor(money / score.balance) * score.score;
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
	}

	//
	
    }

}();

var wsaleCalc = function(){
    return {
	calculate: function(o_retailer, retailer, no_vip, inventories, show_promotions, mode, verificate){
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
	    
	    console.log(pmoneys);
	    
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
	    
	    var calc_p = wsaleUtils.calc_with_promotion(pmoneys);
	    should_pay = calc_p.balance; 
	    score  = wsaleUtils.calc_with_score(pscores, verificate); 
	    // charge = should_pay - has_pay;

	    return {
		total:      total,
		abs_total:  abs_total,
		should_pay: should_pay - verificate,
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
		p1 += diablo_float_mul(one.fprice, count);
	    }

	    var vdiscount = diablo_discount(verificate, p1);
	    for (var i=1, l=inventories.length; i<l; i++){
		var one = inventories[i];
		var count = mode === 0 ? one.sell : one.reject;
		
		one.rdiscount = diablo_float_sub(one.rdiscount, vdiscount);
		one.rprice  = diablo_price(one.fprice, one.rdiscount);
		one.calc    = diablo_float_mul(one.rprice, count);
	    }
	}
    }
}();

var gen_wsale_key = function(shop, retailer, employee, dateFilter){
    var now = $.now();
    return "ws-"
	+ employee.toString()
	+ "-" + retailer.toString()
	+ "-" + shop.toString()
	+ "-" + dateFilter(now, 'mediumTime')
	+ "-" + now;
};

var wsaleDraft = function(storage, shop, retailer, employee, dateFilter){
    this.storage  = storage;
    this.shop     = shop;
    this.retailer = retailer;
    this.employee = employee;
    this.dateFilter = dateFilter;
    this.key = gen_wsale_key(this.shop, this.retailer, this.employee, this.dateFilter);
};

wsaleDraft.prototype.get_key = function(){
    return this.key;
};

wsaleDraft.prototype.set_key = function(key){
    return this.key = key;
};

wsaleDraft.prototype.reset = function(){
    // console.log(this.key);
    this.key = gen_wsale_key(this.shop, this.retailer, this.employee, this.dateFilter);
};

wsaleDraft.prototype.change_shop = function(shop){
    this.shop = shop;
    this.reset();
};

wsaleDraft.prototype.change_employee = function(employee){
    this.employee = employee; 
    this.reset();
};

wsaleDraft.prototype.change_retailer = function(retailer){
    // this.remove(this.key);
    this.retailer = retailer; 
    this.reset();
};

wsaleDraft.prototype.keys = function(){
    var re = /^ws-\d+-\d+-\d+.*$/; 
    var keys = this.storage.keys();
    return keys.filter(function(k){
	return re.test(k)
    }).filter(function(k){
	return wsaleUtils.to_integer(k.split("-")[3]) === this.shop;
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
	return k2.sn.split("-")[5] - k1.sn.split("-")[5];
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

