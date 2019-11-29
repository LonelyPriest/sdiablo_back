function wsaleRsnDetailCtrlProvide (
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    wsaleService, localStorageService,
    user, filterPromotion, filterScore, filterSysRetailer, filterBrand,
    filterEmployee, filterFirm, filterSizeGroup,
    filterType, filterColor, filterCType, base){
    // console.log($routeParams);
    // console.log(filterEmployee);
    $scope.shops    = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds  = user.shopIds.concat(user.badrepoIds);
    
    $scope.f_mul       = diablo_float_mul;
    $scope.round       = diablo_round;
    $scope.setting     = {round:diablo_round_record};
    $scope.total_items = 0;
    $scope.goto_page = diablo_goto_page;
    $scope.sexs         = diablo_sex;

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page  = 1;
    // $scope.current_page  = $scope.default_page;

    $scope.tab  = {normal:true, additional:false};
    $scope.tab_normal = {current_page:$scope.default_page};

    $scope.hidden         = {base:true};
    $scope.is_linked      = $routeParams.rsn ? true : false;
    
    // $scope.show_print_btn = $routeParams.rsn ? true : false;
    
    var LODOP       = undefined;
    var dialog      = diabloUtilsService;
    // var use_storage = $routeParams.rsn ? false : true;
    
    /*
     * right
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();
    console.log($scope.right);
    
    /* hidden */
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };
    
    $scope.calc_colspan = function(){
	var column = 16;
	if ($scope.setting.show_note)
	    column += 1;
	if ($scope.hidden.base)
	    column -= 3;
	
	return column;
    };

    $scope.order_fields = wsaleUtils.order_fields();
    $scope.mode = $scope.order_fields.id;
    $scope.sort = 0;

    $scope.use_order = function(mode){
	$scope.mode = mode;
	$scope.sort = $scope.sort === 0 ? 1 : 0; 
	$scope.do_search($scope.tab_normal.current_page);
    }

    // prepare of print
    if ($scope.is_linked){
	var shop = diablo_get_object(parseInt($routeParams.rsn.split("-")[3]), $scope.shops);
	var print_access = wsaleUtils.print_num(shop.id, base); 
	if (diablo_frontend === wsaleUtils.print_mode(shop.id, base)) {
	    if (needCLodop()) loadCLodop(print_access.protocal);
	} 
	    
    };

    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };
    
    var sell_type =  [{name:"销售开单", id:0, py:diablo_pinyin("销售开单")},
    		      {name:"销售退货", id:1, py:diablo_pinyin("销售退货")}];

    var now = $.now(); 
    // var shopId = $scope.shopIds.length === 1 ? $scope.shopIds[0]: -1;
    
    // base setting 
    $scope.setting.se_pagination = wsaleUtils.sequence_pagination(diablo_default_shop, base); 
    $scope.setting.show_sale_day = user.sdays;
    
    var sale_mode = wsaleUtils.sale_mode(diablo_default_shop, base);
    $scope.setting.show_note     = wsaleUtils.to_integer(sale_mode.charAt(1));
    
    var storage = localStorageService.get(diablo_key_wsale_trans_detail);
    console.log(storage);
    if (!$scope.is_linked && angular.isDefined(storage) && storage !== null){
    	$scope.filters      = storage.filter;
	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.tab_normal.current_page = storage.page;
    } else{
	$scope.filters = [];
	if (angular.isDefined($routeParams.rsn)){
	    $scope.qtime_start = diablo_set_date(
		wsaleUtils.start_time(diablo_default_shop, base, now, dateFilter));
	} else {
	    $scope.qtime_start = now;
	}

	$scope.qtime_end = now; 
    };
    // console.log($scope.qtime_start, $scope.qtime_end, now); 

    $scope.time = wsaleUtils.correct_query_time(
	$scope.right.master,
	$scope.setting.show_sale_day,
	$scope.qtime_start,
	$scope.qtime_end,
	diabloFilter);
    console.log($scope.time);

    $scope.match_rsn = function(viewValue) {
	return diabloFilter.match_wsale_rsn_of_all(
	    diablo_rsn_all,
	    viewValue,
	    wsaleUtils.format_time_from_second($scope.time, dateFilter));
    };
    
    // console.log($scope.setting);
    // filter
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number); 
    diabloFilter.add_field("brand",    filterBrand);
    // diabloFilter.add_field("lbrand",   []);
    diabloFilter.add_field("type",     filterType); 
    diabloFilter.add_field("ctype",    filterCType);
    diabloFilter.add_field("sex",      diablo_sex2object);
    diabloFilter.add_field("season",   diablo_season2objects);
    diabloFilter.add_field("year",     diablo_full_year); 
    diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("shop",     $scope.shops); 
    diabloFilter.add_field("retailer", function(viewValue){
	return wsaleUtils.match_retailer_phone(viewValue, diabloFilter)
    }); 
    diabloFilter.add_field("employee",  filterEmployee); 
    diabloFilter.add_field("sell_type", sell_type);
    diabloFilter.add_field("rsn",       $scope.match_rsn);
    diabloFilter.add_field("org_price", []);
    diabloFilter.add_field("mdiscount", []);
    diabloFilter.add_field("ldiscount", []);
    diabloFilter.add_field("lsell",     []);
    diabloFilter.add_field("msell",     []);
   
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.cache_stastic = function(){
	localStorageService.set(
	    "wsale-note-stastic", {total_items:       $scope.total_items,
				   total_tblance:     $scope.total_tblance,
				   total_amounts:     $scope.total_amounts, 
				   total_balance:     $scope.total_balance,
				   total_obalance:    $scope.total_obalance,
				   t:now});
    };

    var add_search_condition = function(search){
	if (angular.isUndefined(search.rsn)){
	    search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined;
	}; 
	
	if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
	    search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	};
	
	console.log(search);

	return search;
    };
    
    /*
     * pagination 
     */
    // $scope.colspan = 17;
    $scope.do_search = function(page){
	console.log(page);
	if (!$scope.right.master && $scope.setting.show_sale_day !== diablo_nolimit_day){
	    var diff = now - diablo_get_time($scope.time.start_time);
	    // console.log(diff);
	    if (diff - diablo_day_millisecond * $scope.setting.show_sale_day > diablo_day_millisecond)
	    	$scope.time.start_time = now - $scope.setting.show_sale_day * diablo_day_millisecond;
	    
	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now;
	}
	
	// save condition of query
	if (!$scope.is_linked)
	    wsaleUtils.cache_page_condition(
		localStorageService,
		diablo_key_wsale_trans_detail,
		$scope.filters,
		$scope.time.start_time,
		$scope.time.end_time, page, now);

	if (!$scope.is_linked && page !== $scope.default_page) {
	    var stastic = localStorageService.get("wsale-note-stastic");
	    console.log(stastic);
	    $scope.total_items       = stastic.total_items;
	    $scope.total_amounts     = stastic.total_amounts;
	    $scope.total_tblance     = stastic.total_tblance;
	    $scope.total_balance     = stastic.total_balance;
	    $scope.total_obalance    = stastic.total_obalance;
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    var items    = $scope.items_perpage;
	    var page_num = page; 
	    if ($scope.setting.se_pagination === diablo_yes){
		items = page * $scope.items_perpage;
		page_num = 1;
		$scope.inventories= []; 
	    };
	    
	    // console.log($scope.setting);
	    wsaleService.filter_w_sale_rsn_group(
		{mode:$scope.mode, sort:$scope.sort, note: $scope.setting.show_note},
		$scope.match, search, page_num, items
	    ).then(function(result){
		console.log(result);
		// if (!$scope.is_linked && page === 1){
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.total === 0 ? 0 : result.t_amount;
		    $scope.total_tblance = result.total === 0 ? 0 : result.t_tbalance;
		    $scope.total_balance = result.total === 0 ? 0 : result.t_balance;
		    $scope.total_obalance = result.total === 0 ? 0 : result.t_obalance;
		    $scope.inventories = [];
		    if (!$scope.is_linked) $scope.cache_stastic();
		}
		
		angular.forEach(result.data, function(d){
		    // d.rsn      = diablo_array_last(d.rsn.split(diablo_date_seprator));
		    d.crsn      = diablo_array_last(d.rsn.split(diablo_date_seprator));
		    d.brand    = diablo_get_object(d.brand_id, filterBrand);
		    d.firm     = diablo_get_object(d.firm_id, filterFirm);
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    // d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.type      = diablo_get_object(d.type_id, filterType);
		    d.oseason    = diablo_get_object(d.season, diablo_season2objects);
		    d.promotion = diablo_get_object(d.pid, filterPromotion);
		    d.score     = diablo_get_object(d.sid, filterScore);
		    d.drate     = diablo_discount(d.rprice, d.tag_price);
		    d.gprofit   = d.rprice <= diablo_pfree ? 0 : diablo_discount(
			diablo_float_sub(d.rprice, d.org_price), d.rprice);
		    d.calc      = diablo_float_mul(d.rprice, d.total);
		    d.imbalance = wsaleUtils.to_decimal(d.tag_price - d.rprice);
		});

		if ($scope.setting.se_pagination === diablo_no){
		    $scope.inventories = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.inventories);
		} else {
		    diablo_order(result.data, (page - 1) * $scope.items_perpage + 1);
		    $scope.inventories = $scope.inventories.concat(result.data);
		}

		$scope.tab_normal.current_page = page;
		
	    })
	})
    };

    $scope.refresh = function() {
	if ($scope.tab.normal) {
	    $scope.do_search($scope.default_page);
	} else if ($scope.tab.additional) {
	    $scope.additional_mode();
	} 
    };

    $scope.additional_mode = function() {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    wsaleService.list_wsale_group_by_style_number(search).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    $scope.notes = [];
		    $scope.total = result.total;
		    $scope.amount = 0;

		    var sorted_notes = result.note.sort(function(n1, n2) {return n2.total - n1.total}); 
		    var order_id = 1;
		    angular.forEach(sorted_notes, function(n) {
			n.order_id = order_id; 
			$scope.notes.push(n);
			
			for (var i=0, l=n.note.length; i<l; i++) {
			    var s = n.note[i];
			    $scope.amount += s.total;
			    $scope.notes.push({
				amount: s.total,
				color:  s.color,
				size:   s.size
			    });
			}

			order_id++; 
		    });
		}
	    });
	})
    };

    if ($scope.is_linked || $scope.tab_normal.current_page !== $scope.default_page){
	$scope.do_search($scope.tab_normal.current_page);
	// $scope.additional_mode();
    }
    
    $scope.page_changed = function(page){
	// console.log($scope.current_page);
	$scope.do_search($scope.tab_normal.current_page);
    } 

    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === size){
		return amounts[i].count;
	    }
	}
	return undefined;
    }; 

    var sort_amounts_by_color = function(colors, amounts){
	console.log(amounts);
	return colors.map(function(c){
	    var row = {total:0, cid:c.cid, cname:c.cname};
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (a.cid === c.cid){
		    row.total += a.count;
		}
	    };
	    return row;
	})
    }
    
    $scope.rsn_detail = function(inv){
	console.log(inv);
	var color_sorts;
	if (angular.isDefined(inv.amounts) && angular.isDefined(inv.colors) && angular.isDefined(inv.order_sizes)){
	    color_sorts = sort_amounts_by_color(inv.colors, inv.amounts); 
	    dialog.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:        inv.colors,
		 sizes:         inv.order_sizes,
		 amounts:       inv.amounts,
		 total:         inv.total, 
		 path:          inv.path,
		 colspan:       inv.sizes.length + 1,
		 get_amount:    get_amount,
		 row_total:     function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		});
	    return;
	}
	
	wsaleService.w_sale_rsn_detail({
	    rsn:inv.rsn, style_number:inv.style_number, brand:inv.brand_id
	}).then(function(result){
	    console.log(result);
	    
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(result.data, order_sizes, filterColor);
	    // inv.total    = sort.total;
	    inv.colors      = sort.color;
	    inv.sizes       = sort.size;
	    inv.amounts     = sort.sort;
	    
	    // console.log(inv.amounts);
	    color_sorts     = sort_amounts_by_color(inv.colors, inv.amounts),
	    console.log(color_sorts);
	    dialog.edit_with_modal(
		"rsn-detail.html", undefined, undefined, $scope,
		{colors:     inv.colors,
		 sizes:      inv.sizes,
		 amounts:    inv.amounts,
		 total:      inv.total,
		 path:       inv.path,
		 colspan:    inv.sizes.length + 1,
		 get_amount: get_amount,
		 row_total:  function(cid){
		     return color_sorts.filter(function(s){
			 return cid === s.cid
		     })}
		 });
	});
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    add_search_condition(search); 
	    wsaleService.csv_export(wsaleService.export_type.trans_note, search).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.response(
			false, "文件导出失败", "创建文件失败：" + wsaleService.error[result.ecode]);
		}
	    });
	}) 
    };

    $scope.back = function(){
	var ppage = diablo_set_integer($routeParams.ppage);
	if(angular.isDefined(ppage)){
	    // localStorageService.remove(diablo_key_wsale_trans_detail);
	    $scope.goto_page("#/new_wsale_detail/" + ppage.toString());
	} else{
	    $scope.goto_page("#/new_wsale_detail") 
	}

	// $scope.goto_page("#/new_wsale_detail/");
    };
    
    var dialog = diabloUtilsService;
    $scope.print = function(){
    	var rsn = $routeParams.rsn;
    	var shop = diablo_get_object(parseInt(rsn.split("-")[3]), $scope.shops);
    	console.log(shop);
    	var no_vip = wsaleUtils.no_vip(shop.id, base); 
    	var p_mode = wsaleUtils.print_mode(shop.id, base);
    	// var comments = wsaleUtils.comment(shop.id, base);
    	var isRound  = wsaleUtils.round(shop.id, base);
    	// var cakeMode = wsaleUtils.cake_mode(shop.id, base);
	// var print_perform = wsaleUtils.to_integer(sale_mode.charAt(3));
    	var pdate    = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");

	var sale_mode = wsaleUtils.sale_mode(shop.id, base);
	var print_setting = {
	    print_perform:  wsaleUtils.to_integer(sale_mode.charAt(3)),
	    print_discount: wsaleUtils.yes_default(sale_mode.charAt(15)),
	    cake_mode:      wsaleUtils.cake_mode(shop.id, base),
	    comments:       wsaleUtils.comment(shop.id, base),
	    head_seperater: wsaleUtils.to_integer(sale_mode.charAt(23)),
	    print_score:    wsaleUtils.to_integer(sale_mode.charAt(26))
	};
	
    	if (diablo_frontend === p_mode){
    	    if (angular.isUndefined(LODOP)) LODOP=getLodop();
    	    console.log(LODOP);

    	    if (angular.isDefined(LODOP)){
    		wsaleService.get_w_sale_new(rsn).then(function(result){
    		    console.log(result);
    		    var sale = result.sale;
    		    var detail = angular.copy(result.detail);
    		    // angular.forEach(detail, function(d){
    		    // 	d.brand = diablo_get_object(d.brand_id, filterBrand).name;
    		    // 	d.type = diablo_get_object(d.type_id, filterType).name;
    		    // });

    		    diabloFilter.get_wretailer_batch([sale.retailer_id]).then(function(retailers){
    			console.log(retailers);
    			// console.log(diablo_get_object(sale.retailer_id, retailers).name);
    			var retailer = diablo_get_object(sale.retailer_id, retailers);
    			var top = wsalePrint.gen_head(
    			    LODOP,
    			    shop.name,
    			    rsn,
    			    diablo_get_object(sale.employ_id, filterEmployee).name,
    			    retailer.name,
    			    sale.entry_date,
			    sale.direct,
			    print_setting
			);

    			// sort sale
    			var notes= [];
    			for (var i=0, l=detail.length; i<l; i++) {
    			    var d = detail[i];

    			    var found = false; 
    			    for (var j=0, k=notes.length; j<k; j++) {
    				var ns = notes[j];
    				if (d.style_number === ns.style_number
    				    && d.brand_id === ns.brand_id) {
    				    // console.log(d.color_id);
    				    ns.note += ";"
    					+ diablo_find_color(d.color_id, filterColor).cname
    					+ ":" + d.size;
    				    found = true;
    				} 
    			    }

    			    if (!found) {
    				// console.log(diablo_find_color(d.color_id, filterColor));
    				d.brand = diablo_get_object(d.brand_id, filterBrand).name;
    				d.type = diablo_get_object(d.type_id, filterType).name;
    				d.note = diablo_find_color(d.color_id, filterColor).cname + ":" + d.size;
    				notes.push(d)
    			    }
    			}

    			// console.log(notes);
    			top = wsalePrint.gen_body(
			    LODOP, top, sale, notes, isRound, print_setting);
			
    			// var vip = wsaleUtils.isVip(retailer, no_vip, filterSysRetailer), 
    			top = wsalePrint.gen_stastic(
			    LODOP,
			    top,
			    sale.direct,
			    sale,
			    sale.balance,
			    wsaleUtils.isVip(retailer, no_vip, filterSysRetailer),
			    print_setting);
			
    			wsalePrint.gen_foot(LODOP, top, pdate, shop, print_setting);
    			wsalePrint.start_print(LODOP); 
    		    }); 
    		}); 
    	    }	    
    	} else {
    	    $scope.disable_print = true;
    	    wsaleService.print_w_sale(rsn).then(function(result){
    		console.log(result);
    		$scope.disable_print = false; 
    		if (result.ecode == 0){
    		    var msg = "";
    		    if (result.pcode == 0){
    			msg = "销售单打印成功！！单号："
    			    + result.rsn + "，请等待服务器打印";
    			dialog.response(true, "销售单打印", msg, $scope); 
    		    } else {
    			if (result.pinfo.length === 0){
    			    msg += wsaleService.error[result.pcode]
    			} else {
    			    angular.forEach(result.pinfo, function(p){
    				msg += "[" + p.device + "] "
    				    + wsaleService.error[p.ecode]
    			    })
    			};
    			msg = "销售单打印失败！！单号："
    			    + result.rsn + "，打印失败：" + msg;
    			dialog.response(false, "销售单打印", msg, $scope); 
    		    }
		    
    		} else{
    	    	    dialog.response(
    	    		false, "销售单打印",
    			"销售单打印失败：" + wsaleService.error[result.ecode]);
    		}
    	    })   
    	} 
    };

    $scope.print_note = function() {
	var callback = function() {
	    diabloFilter.do_filter($scope.filters, $scope.time, function(search){
		add_search_condition(search);
		diablo_goto_page("#/wsale_print_note/" + angular.toJson(search)); 
	    }); 
	}
	
	dialog.request(
	    "交易明细打印", "请确认打印机已连接好，确认要打印吗？", callback, undefined, undefined); 
    };


    $scope.update_orgprice = function(inv) {
	var callback = function(params){
	    console.log(params);

	    wsaleService.update_w_sale_price(
		inv.rsn,
		{style_number:inv.style_number,
		 brand:inv.brand_id,
		 org_price:params.org_price,
		 tag_price:inv.tag_price}
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    inv.org_price = params.org_price; 
		    inv.gprofit   = inv.rprice <= diablo_pfree ? 0
			: diablo_discount(
			    diablo_float_sub(inv.rprice, inv.org_price), inv.rprice);
		} else {
		    dialog.response(
			false,
			"交易单进货价编辑",
			"交易单进货价编辑失败："
			    + wsaleService.error[result.ecode]);
		}
	    });
	};

	dialog.edit_with_modal(
	    "rsn-update-orgprice.html",
	    undefined,
	    callback,
	    undefined,
	    {
		style_number :inv.style_number,
		brand        :inv.brand.name,
		org_price    :inv.org_price
	    }
	);
    };

    $scope.stock_info = function(inv) {
	console.log(inv);
	diabloFilter.list_purchaser_inventory(
	    {style_number:inv.style_number, brand:inv.brand_id, shop: inv.shop_id}
	).then(function(stocks) {
	    console.log(stocks);
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(stocks, order_sizes, filterColor);
	    
	    var payload = {
		style_number: inv.style_number,
		brand:        inv.brand,
		sizes:        sort.size,
		colors:       sort.color,
		path:         inv.path,
		get_amount: function(cid, size){
		    return get_amount(cid, size, sort.sort);
		}};
	    dialog.edit_with_modal("stock-add.html", undefined, undefined, undefined, payload); 
	});
    };
};

function dailyCostCtrlProvide (
    $scope, dateFilter, diabloUtilsService, diabloFilter, diabloPattern, wsaleService, user) {
    $scope.shops   = user.sortShops;
    $scope.shopIds = user.shopIds;

    $scope.filters = [];
    diabloFilter.reset_field();
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // pagination
    $scope.total_items   = 0;
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.items_perpage = diablo_items_per_page();
    $scope.daily_costs   = [];
    
    var dialog = diabloUtilsService; 
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();

    var now = wsaleUtils.first_day_of_month();
    $scope.time = wsaleUtils.correct_query_time(
	$scope.right.master,
	user.sdays,
	now.first,
	now.current,
	diabloFilter);
    // console.log($scope.time);
    
    $scope.do_search = function(page) {
	console.log(page);
	if (!$scope.right.master && user.sdays !== diablo_nolimit_day){
	    var diff = now - diablo_get_time($scope.time.start_time);
	    // console.log(diff);
	    if (diff - diablo_day_millisecond * user.sdays > diablo_day_millisecond)
	    	$scope.time.start_time = now - user.sdays * diablo_day_millisecond;
	    
	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now;
	}

	diabloFilter.do_filter($scope.filters, $scope.time, function(search) {
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    wsaleService.list_daily_cost(
		$scope.match, search, page, $scope.itemsPerpage
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    $scope.current_page = page; 
		    if (page === 1) {
			$scope.total_items   = result.total;
			$scope.total_balance = result.t_balance;
			$scope.total_cash    = result.t_cash;
			$scope.total_card    = result.t_card;
			$scope.total_wxin    = result.t_wxin; 
		    }

		    diablo_order_page(page, $scope.items_perpage, result.data);
		    $scope.daily_costs = result.data;
		}
	    })
	});
    };

    $scope.refresh = function() {
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function() {
	$scope.do_search($scope.current_page)
    };

    $scope.match_cost_class = function(viewValue) {
	return diabloFilter.match_cost_class(viewValue, diablo_is_ascii_string(viewValue));
    };

    $scope.new_daily_cost = function() {
	var callback = function(params) {
	    console.log(params);
	    wsaleService.new_daily_cost(
		{shop: params.shop.id,
		 cost_class: params.cost_class.id,
		 cash:wsaleUtils.to_integer(params.cash),
		 card:wsaleUtils.to_integer(params.card),
		 wxin:wsaleUtils.to_integer(params.wxin),
		 comment: diablo_set_string(params.comment)
		}).then(function(result) {
		     console.log(result);
		     if (result.ecode === 0) {
			 $scope.refresh()
		     } else {
			 dialog.set_error("新增日常费用", result.ecode);
		     }
		 })
	};
	
	dialog.edit_with_modal(
	    "new-daily-cost.html",
	    undefined,
	    callback,
	    undefined,
	    {cash: 0,
	     card: 0,
	     wxin: 0,
	     shops: $scope.shops,
	     shop: $scope.shops[0],
	     pattern:  {comment:diabloPattern.comment, number:diabloPattern.number},
	     match_cost_class: $scope.match_cost_class,
	     check_cost: function(cash, card, wxin) {
		 return wsaleUtils.to_integer(cash)
		     + wsaleUtils.to_integer(card)
		     + wsaleUtils.to_integer(wxin) > 0;
	     }
	    }
	);
    };
};

function payScanCtrlProvide (
    $scope, dateFilter, diabloUtilsService, diabloFilter, diabloPattern, wsaleService, user) {
    $scope.shops   = user.sortShops;
    $scope.shopIds = user.shopIds;

    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("pay_state", wsaleService.pay_state);
    diabloFilter.add_field("pay_type", wsaleService.pay_type);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    console.log($scope.filter);
    console.log($scope.prompt);

    // pagination
    $scope.total_items   = 0;
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.items_perpage = diablo_items_per_page();
    $scope.pay_detail    = [];
    
    var dialog = diabloUtilsService; 
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();
    
    var now = wsaleUtils.first_day_of_month();
    $scope.time = wsaleUtils.correct_query_time(
	$scope.right.master,
	user.sdays,
	now.current,
	now.current,
	diabloFilter);
    // console.log($scope.time);
    
    $scope.do_search = function(page) {
	console.log(page);
	if (!$scope.right.master && user.sdays !== diablo_nolimit_day){
	    var diff = now - diablo_get_time($scope.time.start_time);
	    // console.log(diff);
	    if (diff - diablo_day_millisecond * user.sdays > diablo_day_millisecond)
	    	$scope.time.start_time = now - user.sdays * diablo_day_millisecond;
	    
	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now;
	}

	diabloFilter.do_filter($scope.filters, $scope.time, function(search) {
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    diabloFilter.filter_pay_scan(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    $scope.current_page = page; 
		    if (page === 1) {
			$scope.total_items   = result.total;
			$scope.total_balance = result.t_balance; 
		    }

		    diablo_order_page(page, $scope.items_perpage, result.data);
		    $scope.pay_detail = result.data;
		}
	    })
	});
    };

    $scope.refresh = function() {
	$scope.do_search($scope.default_page)
    };

    $scope.page_changed = function() {
	$scope.do_search($scope.current_page)
    }; 
};

function wsaleUploadCtrlProvide (
    $scope, $routeParams, dateFilter, FileUploader, diabloUtilsService, diabloFilter,
    wsaleService, user, base){

    $scope.shops = user.sortShops;
    $scope.select = {shop:$scope.shops[0]};
    
    $scope.uploader = new FileUploader({
        url: '/wsale/upload_w_sale/' + $scope.select.shop.id.toString()
    });

    $scope.change_shop = function(){
	$scope.uploader.url = '/wsale/upload_w_sale/' + $scope.select.shop.id.toString();
	console.log($scope.uploader.url);
    };

    $scope.uploader.filters.push({
        name: 'syncFilter',
        fn: function(item /*{File|FileLikeObject}*/, options) {
            console.log('syncFilter');
            return this.queue.length < 10;
        }
    });

    $scope.uploader.onWhenAddingFileFailed = function(item /*{File|FileLikeObject}*/, filter, options) {
            console.info('onWhenAddingFileFailed', item, filter, options);
        };
    
    $scope.uploader.onAfterAddingFile = function(fileItem) {
            console.info('onAfterAddingFile', fileItem);
    };
    
    $scope.uploader.onAfterAddingAll = function(addedFileItems) {
        console.info('onAfterAddingAll', addedFileItems);
    };
    
    $scope.uploader.onBeforeUploadItem = function(item) {
        console.info('onBeforeUploadItem', item);
    };
    $scope.uploader.onProgressItem = function(fileItem, progress) {
        console.info('onProgressItem', fileItem, progress);
    };
    $scope.uploader.onProgressAll = function(progress) {
        console.info('onProgressAll', progress);
    };
    $scope.uploader.onSuccessItem = function(fileItem, response, status, headers) {
        // console.info('onSuccessItem', fileItem, response, status, headers);
	console.info('onSuccessItem', response);
    };
    $scope.uploader.onErrorItem = function(fileItem, response, status, headers) {
        console.info('onErrorItem', fileItem, response, status, headers);
    };
    $scope.uploader.onCancelItem = function(fileItem, response, status, headers) {
        // console.info('onCancelItem', fileItem, response, status, headers);
	console.info('onCancelItem', fileItem, response);
    };

    $scope.uploader.onCompleteItem = function(fileItem, response, status, headers) {
	console.info('onCompletedItem', fileItem, response);
	var dialog = diabloUtilsService;
	if (response.ecode === 0){
	    dialog.response(true, "销售单导入", "销售单据导入成功！！导入店铺：" + $scope.select.shop.name);
	} else if (response.ecode === 2712) {
	    fileItem.isSuccess = false;
	    fileItem.isError = true;
	    fileItem.isUploaded = false;
	    fileItem.progress = 0;
	    var message = wsaleService.error[2712]
		+ "[款号：" + response.style_number
		+ "，总数量：" + response.total
		+ "，校验数量：" + response.amount +"]";
	    dialog.response(false, "销售单导入", "销售单导入失败：" + message)
	} else {
	    fileItem.isSuccess = false;
	    fileItem.isError = true;
	    fileItem.isUploaded = false;
	    fileItem.progress = 0;
	    var message = wsaleService.error[response.ecode] + "[款号：" + response.style_number + "]";
	    dialog.response(false, "销售单导入", "销售单导入失败：" + message);
	} 
    };
    $scope.uploader.onCompleteAll = function() {
        console.info('onCompleteAll');
    };

    console.info('uploader', $scope.uploader);  
};

function wsalePrintNoteCtrlProvide(
    $scope, $routeParams, diabloUtilsService, wsaleService,
    filterBrand, filterFirm, filterType, filterColor, user, base){
    // console.log($routeParams);
    // $scope.rsn = $routeParams.rsn; 
    $scope.shops = user.sortShops;
    $scope.search = angular.fromJson($routeParams.note);
    // console.log($scope.shops);
    
    var LODOP;
    var print_access  = wsaleUtils.print_num(user.loginShop, base); 
    if (needCLodop()) loadCLodop(print_access.protocal); 
    var dialog = diabloUtilsService;

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);
    
    // console.log(base);
    // console.log($scope.rbill_comment);
    
    wsaleService.print_w_sale_note(
	wsaleService.export_type.trans_note,
	$scope.search
    ).then(function(result){
    	console.log(result);
	if (result.ecode === 0) {
	    var order_id = 1;
	    $scope.notes = result.data;
	    $scope.total = 0;
	    $scope.calc  = 0;
	    for (var i=0,l=$scope.notes.length; i<l; i++) {
		var n = $scope.notes[i];
		n.order_id = order_id;
		n.calc = wsaleUtils.to_decimal(n.rprice * n.total);
		$scope.total += n.total;
		$scope.calc += n.calc;
		order_id++;
	    } 
	    $scope.calc = wsaleUtils.to_decimal($scope.calc);
	} else {
	    dialog.response(
		false,
		"交易明细打印",
		"交易明细打印失败：获取交易明细失败，请核对后再打印！！")
	}
    });
    
    var strBodyStyle="<style>"
	+ ".table-response {min-height: .01%; overflow-x:auto;}"
	+ "table {border-spacing:0; border-collapse:collapse; width:100%}"
	+ "td,th {padding:0; border:1 solid #000000; text-align:center;}"
	+ ".table-bordered {border:1 solid #000000;}" 
	+ "</style>";
    $scope.print = function() {
	if (angular.isUndefined(LODOP)) {
	    LODOP = getLodop();
	}

	if (LODOP.CVERSION) {
	    LODOP.PRINT_INIT("task_print_sale_note");
	    LODOP.SET_PRINTER_INDEX(wsaleUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	    LODOP.ADD_PRINT_HTM(
		"5%", "5%",  "90%", "BottomMargin:15mm",
		strBodyStyle + "<body>" + document.getElementById("sale_note").innerHTML + "</body>");
	    LODOP.PREVIEW(); 
	}
    };

    $scope.go_back = function() {diablo_goto_page("#/wsale_rsn_detail");};
    
};

define (["wsaleApp"], function(app){
    app.controller("wsaleRsnDetailCtrl", wsaleRsnDetailCtrlProvide);
    app.controller("dailyCostCtrl", dailyCostCtrlProvide);
    app.controller("payScanCtrl", payScanCtrlProvide);
    app.controller("wsalePrintNoteCtrl", wsalePrintNoteCtrlProvide);
    app.controller("wsaleUploadCtrl", wsaleUploadCtrlProvide);
});
