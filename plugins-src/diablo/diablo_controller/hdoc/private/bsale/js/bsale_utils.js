var bsaleUtils = function(){
    var default_hide = function(v) {
	if (v === diablo_empty_string)
	    return diablo_yes;
	return bsaleUtils.to_integer(v);
    };
    
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

    var sort_bsale = function(base, sells) {
	console.log(base);
	var select             = {};
	select.rsn             = base.rsn;
	select.rsn_id          = base.id;
	select.rsn_datetime    = diablo_set_datetime(base.entry_date);
	select.region_id       = base.region_id,
	select.bsaler_id       = base.bsaler_id;
	select.shop_id         = base.shop_id; 
	select.employee_id     = base.employee_id; 
	
	select.surplus    = base.balance;
	select.cash       = base.cash;
	select.card       = base.card;
	select.wxin       = base.wxin;
	select.verificate = base.verificate; 
	select.should_pay = base.should_pay;
	select.has_pay    = base.has_pay;
	
	select.comment    = base.comment;
	select.total      = base.total;
	
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
		add.sex     = s.sex;
		add.season  = s.season;
		add.firm_id = s.firm_id;
		add.year    = s.year;
		add.entry   = s.in_datetime;
		add.free    = s.free;
		add.path    = s.path;
		add.unit    = s.unit;

		add.free_color_size = s.free === 0 ? true : false; 
		add.s_group = s.s_group;
		add.comment = s.comment;
		
		add.org_price = s.org_price;
		add.tag_price = s.tag_price;
		add.ediscount = s.ediscount;
		add.fprice    = s.fprice;
		add.rprice    = s.rprice;
		add.fdiscount = s.fdiscount;
		add.rdiscount   = s.rdiscount;
		add.o_fdiscount = s.fdiscount;
		add.o_fprice    = s.fprice;
		
		add.reject    = s.amount;
		add.total     = s.total;
		
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
	cover_bsale: function(base, sells, shops, brands, bsalers, employees, types, colors, size_groups, regions){
	    var bsale         = sort_bsale(base, sells);
	    var details       = bsale.details;
	    var order_length  = details.length;
	    
	    angular.forEach(details, function(d){
		if (d.sizes.length !== 1 || d.sizes[0] !== diablo_free_size){
		    d.sizes = get_size_group(d.s_group, size_groups);
		}

		d.colors = d.colors_id.map(function(id){return diablo_find_color(id, colors);});
		
		d.brand     = diablo_get_object(d.brand_id, brands);
		d.type      = diablo_get_object(d.type_id, types); 
		d.select    = true;
		// d.select    = d.total > 0 ? true : false;
		d.full_name = d.style_number + "/" + d.brand.name + "/" + d.type.name;
		d.order_id  = order_length; 
		order_length--; 
		
	    });

	    bsale.select.shop = diablo_get_object(bsale.select.shop_id, shops); 
	    bsale.select.bsaler = diablo_get_object(bsale.select.bsaler_id, bsalers);
	    bsale.select.region = diablo_get_object(bsale.select.region_id, regions); 
	    // console.log(bsale);
	    bsale.select.employee = diablo_get_object(bsale.select.employee_id, employees); 
	    return bsale;
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
	    
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd"));
	},

	to_decimal:function(v){
	    return diablo_rdight(v, 2);
	},
	
	to_float: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return bsaleUtils.to_decimal(parseFloat(v));
	    }
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	correct_query_time: function(isMaster, configDays, start_time, now, dateFilter){
	    if (isMaster || configDays === diablo_nolimit_day)
		return dateFilter.default_time(start_time, now);
	    else {
		var diff = now - diablo_get_time(start_time); 
		if (diff - configDays * diablo_day_millisecond <= diablo_day_millisecond) {
		    return dateFilter.default_time(start_time, now);
		} else {
		    return dateFilter.default_time(now - diablo_day_millisecond * configDays, now); 
		}
	    } 
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

	order_fields:function(){
	    return {id:0, shop:1, brand:2, firm:3};
	},

	print_mode: function(shop, base){
	    return diablo_base_setting("ptype", shop, base, parseInt, diablo_frontend);
	},

	print_protocal: function(shop, base){
	    var p = diablo_base_setting("pum", shop, base, function(s) {return s}, diablo_print_num);
	    return bsaleUtils.to_integer(p.charAt(2)); 
	},

	sale_mode:function(shop, base) {
	    var mode = diablo_base_setting("p_balance", shop, base, function(s) {return s}, diablo_sale_mode);
	    return {
		show_note: default_hide(mode.charAt(1)),
		hide_bsaler: default_hide(mode.charAt(11))
	    };
	},

	// print color or size or both
	print_cs_mode:function(shop, base) {
	    var mode = diablo_base_setting(
		"p_color_size", shop, base, function(s) {return s}, diablo_bsale_print_cs_mode);
	    return {
		both: bsaleUtils.to_integer(mode.charAt(0)),
		color_only: bsaleUtils.to_integer(mode.charAt(1)),
		size_only: bsaleUtils.to_integer(mode.charAt(2))
	    };
	},
	
	select_employee: function(shop, base) {
	    return diablo_base_setting("s_employee", shop, base, parseInt, diablo_no);
	},
	
	check_sale: function(shop, base){
	    return diablo_base_setting("check_sale", shop, base, parseInt, diablo_yes);
	},

	negative_sale: function(shop, base){
	    return diablo_base_setting("m_sale", shop, base, parseInt, diablo_yes);
	},

	round: function(shop, base){
	    return diablo_base_setting("round", shop, base, parseInt, diablo_yes);
	},

	printer_bill: function(shop, base) {
	    return diablo_base_setting("prn_bill", shop, base, parseInt, diablo_invalid_index);
	},

	barcode_mode: function(shop, base) {
	    return diablo_base_setting("bcode_use", shop, base, parseInt, diablo_no);
	},

	barcode_auto: function(shop, base) {
	    return diablo_base_setting("bcode_auto", shop, base, parseInt, diablo_no);
	},

	scan_only:function(shop, base) {
	    return diablo_base_setting("scan_only", shop, base, function(s) {return s}, diablo_scan_mode);
	},

	type_sale:function(shop, base) {
	    return diablo_base_setting("type_sale", shop, base, parseInt, diablo_no);
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
	}
    }
}();


var bsaleCalc = function(){
    return {
	get_inventory_count: function(inv, sellMode) {
	    return sellMode === diablo_sale ? inv.sell : inv.reject;
	},

	calc_discount_of_verificate: function(inventories, mode, pay, verificate){
	    if (bsaleUtils.to_integer(verificate) === 0){
		return pay;
	    } 
	    var p1 = 0;
	    var one;
	    var count;
	    for (var i=0, l=inventories.length; i<l; i++){
		one = inventories[i];
		// count = mode === diablo_sale ? one.sell : one.reject;
		count = bsaleCalc.get_inventory_count(one, mode);
		if (count >=0 )
		    p1 += one.fprice * count;
	    }

	    var vdiscount = diablo_discount(verificate, p1);
	    var calc = 0;
	    for (var i=0, l=inventories.length; i<l; i++){
		one = inventories[i];
		count = bsaleCalc.get_inventory_count(one, mode);
		if (count >=0 ) {
		    one.rdiscount = bsaleUtils.to_decimal(one.rdiscount - vdiscount);
		    one.rprice  = diablo_price(one.fprice, one.rdiscount); 
		}

		one.calc = bsaleUtils.to_decimal(one.rprice * count);
		calc = bsaleUtils.to_decimal(calc + one.calc);
		console.log(one.calc);
	    }

	    return calc;
	},
	
	calculate: function(inventories, saleMode, verificate, round){
	    var total        = 0;
	    var abs_total    = 0;
	    var should_pay   = 0;
	    var score        = 0; 

	    for (var i=0, l=inventories.length; i<l; i++){
		var one = inventories[i];
		if (angular.isDefined(one.select) && !one.select) continue;

		if (one.o_fprice !== one.fprice) {
		    one.fdiscount = diablo_discount(one.fprice, one.tag_price); 
		} else if (one.o_fdiscount !== one.fdiscount) {
		    if (one.tag_price == 0) {
		    	one.fprice = diablo_price(one.fprice, one.fdiscount); 
		    } else {
		    	one.fprice = diablo_price(one.tag_price, one.fdiscount); 
		    }
		}
	    }
	    
	    for (var i=0, l=inventories.length; i<l; i++) {
		var one = inventories[i];
		var count = bsaleCalc.get_inventory_count(one, saleMode);

		total      += bsaleUtils.to_integer(count);
		abs_total  += Math.abs(bsaleUtils.to_integer(count)); 
		
		one.o_fprice = one.fprice;
		one.o_fdiscount = one.fdiscount; 
		one.rprice = one.fprice;
		one.rdiscount = diablo_full_discount;
		one.calc = bsaleUtils.to_decimal(one.fprice * count); 
		should_pay = bsaleUtils.to_decimal(should_pay + one.calc);		
	    } 

	    // calcuate with verificate 
	    should_pay = bsaleCalc.calc_discount_of_verificate(inventories, saleMode, should_pay, verificate); 
	    if (bsaleUtils.to_integer(round) === diablo_yes) {
		if (should_pay >= 0)
		    should_pay = diablo_round(should_pay)
		else {
		    should_pay = -diablo_round(Math.abs(should_pay))
		}
	    }
	    
	    return {
		total:      total,
		abs_total:  abs_total,
		should_pay: should_pay
	    }; 
	}
    }
}();
	
var gen_bsale_key = function(shop, bsaler, dateFilter){
    var now = $.now();
    return "bts-"
    // + employee.toString()
	+ bsaler.toString()
	+ "-" + shop.toString()
	+ "-" + dateFilter(now, 'mediumTime')
	+ "-" + now;
};

var bsaleDraft = function(storage, shop, bsaler, dateFilter){
    this.storage  = storage;
    this.shop     = shop;
    this.bsaler   = bsaler;
    // this.employee = employee;
    this.dateFilter = dateFilter;
    this.key = gen_bsale_key(this.shop, this.bsaler, this.dateFilter);
};

bsaleDraft.prototype.get_key = function(){
    return this.key;
};

bsaleDraft.prototype.set_key = function(key){
    return this.key = key;
};

bsaleDraft.prototype.reset = function(){
    // console.log(this.key);
    this.key = gen_bsale_key(this.shop, this.bsaler, this.dateFilter);
};

bsaleDraft.prototype.change_shop = function(shop){
    this.shop = shop;
    this.reset();
};

bsaleDraft.prototype.change_bsaler = function(bsaler){
    this.bsaler = bsaler; 
    this.reset();
};

bsaleDraft.prototype.keys = function(){
    // var re = /^ws-\d+-\d+-\d+.*$/;
    var re = /^bts-\d+-\d+.*$/; 
    var keys = this.storage.keys();
    return keys.filter(function(k){
	return re.test(k)
    }).filter(function(k){
	return bsaleUtils.to_integer(k.split("-")[2]) === this.shop;
    }, this);
};

bsaleDraft.prototype.save = function(resources){
    var keys = this.keys().sort(function(k1, k2){
	return k2.split("-")[5] - k1.split("-")[5];
    });

    for (var i=4, l=keys.length; i<l; i++)
	this.remove(keys[i]);
    
    var key = this.key;
    this.storage.set(key, {v:resources});
};

bsaleDraft.prototype.list = function(draftFilter){
    var keys = this.keys();
    return draftFilter(keys).sort(function(k1, k2){
	return k2.sn.split("-")[4] - k1.sn.split("-")[4];
    }); 
};

bsaleDraft.prototype.remove = function(key){
    this.storage.remove(key);
};

bsaleDraft.prototype.select = function(dialog, template, draftFilter, selectCallback){
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
}

