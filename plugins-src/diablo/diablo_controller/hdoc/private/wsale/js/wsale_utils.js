var wsaleUtils = function(){
    var in_sort = function(sorts, sell){
	for (var i=0, l=sorts.length; i<l; i++){
	    if (sell.style_number === sorts[i].style_number 
		&& sell.brand_id   === sorts[i].brand_id){

		// sorts[i].total += sell.sell;
		sorts[i].reject += Math.abs(sell.amount);
		sorts[i].amounts.push({
		    cid        :sell.color_id,
		    size       :sell.size,
		    sell_count :Math.abs(sell.amount)});
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
	select.cash       = Math.abs(base.cash);
	select.card       = Math.abs(base.card);
	select.withdraw   = Math.abs(base.withdraw);
	select.should_pay = Math.abs(base.should_pay);

	select.comment    = base.comment;
	select.total      = Math.abs(base.total);

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
		
		add.season  = s.season;
		add.firm_id = s.firm_id;
		add.year    = s.year;
		add.free    = s.free;
		add.path    = s.path;

		add.s_group = s.s_group;
		add.free_color_size = s.free === 0 ? true : false;

		add.fprice    = s.fprice;
		add.fdiscount = s.fdiscount;
		add.reject    = Math.abs(s.amount);
		add.total     = Math.abs(s.total);
		
		add.pid       = s.pid;
		add.sid       = s.sid;

		add.sizes.push(s.size);
		add.colors_id.push(s.color_id);
		
		add.amounts.push({
		    cid: s.color_id,
		    size:s.size,
		    sell_count:Math.abs(s.amount)});

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
		
		d.brand = diablo_get_object(d.brand_id, brands);
		// d.retailer = diablo_get_object(d.retailer_id, retailers);
		d.type = diablo_get_object(d.type_id, types);

		d.promotion = diablo_get_object(d.pid, promotions);
		d.score     = diablo_get_object(d.sid, scores);

		d.order_id = order_length;

		var show = {
		    order_id:  d.order_id,
		    name:      d.style_number
			+ "，" + d.brand.name + "，" + d.type.name,
		    promotion: d.promotion,
		    score:     d.score,
		}; 
		show_promotions.unshift(show);
		
		order_length--; 
		
	    });

	    wsale.select.shop = diablo_get_object(
		wsale.select.shop_id, shops); 
	    wsale.select.retailer = diablo_get_object(
		wsale.select.retailer_id, retailers);
	    wsale.select.employee = diablo_get_object(
		wsale.select.employee_id, employees);
	    
	    wsale.show_promotions = show_promotions;
	    return wsale;
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

	start_time: function(shop, base, now){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFilter(
		    diabloFilter.default_start_time(now), "yyyy-MM-dd"));
	},

	check_sale: function(shop, base){
	    return diablo_base_setting(
		"check_sale", shop, base, parseInt, diablo_yes);
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
			total += Math.abs(s.sell_count);
			amount.count += Math.abs(s.sell_count);
			amount.sell_count = Math.abs(s.sell_count); 
			break;
		    }
		}
	    }

	    return {
		total: total, amounts:select_amounts, colors:used_colors};
	}

	//
	
    }

}();







