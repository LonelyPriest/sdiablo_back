wsaleApp.controller("wsaleRsnDetailCtrl", function(
    $scope, $routeParams, dateFilter, diabloUtilsService, diabloFilter,
    purchaserService, wgoodService, wsaleService, localStorageService,
    user, filterPromotion, filterScore, filterBrand,
    filterRetailer, filterEmployee, filterFirm, filterSizeGroup,
    filterType, filterColor, base){
    // console.log($routeParams);
    // console.log(filterEmployee);
    $scope.shops    = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds  = user.shopIds.concat(user.badrepoIds);
    
    $scope.f_mul       = diablo_float_mul;
    $scope.round       = diablo_round;
    $scope.setting     = {round:diablo_round_record};
    $scope.total_items = 0;

    /*
     * hidden
     */
    $scope.hidden   = {base:true}; 
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };

    var LODOP;

    /*
     * right
     */
    $scope.right = {
	master:        rightAuthen.authen_master(user.type),
	show_stastic:  rightAuthen.authen_master(user.type),
	show_orgprice: rightAuthen.authen_master(user.type)
    };

    $scope.calc_colspan = function(){
	var column = 15;
	if ($scope.hidden.base) column -= 3;
	
	return column;
    }

    var dialog      = diabloUtilsService; 
    var use_storage = $routeParams.rsn ? false : true;
    $scope.show_print_btn = $routeParams.rsn ? true : false;
    if ($scope.show_print_btn){
	var shop = diablo_get_object(parseInt($routeParams.rsn.split("-")[3]), $scope.shops);
	var p_mode = wsaleUtils.print_mode(shop.id, base);
	if (diablo_frontend === p_mode){
	    if (needCLodop()) loadCLodop();
	};
    };

    // style_number
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };
    
    $scope.goto_page = diablo_goto_page;

    $scope.back = function(){
	var ppage = diablo_set_integer($routeParams.ppage);
	if(angular.isDefined(ppage)){
	    localStorageService.remove(diablo_key_wsale_trans_detail);
	    $scope.goto_page("#/new_wsale_detail/" + ppage.toString()) 
	} else{
	    $scope.goto_page("#/new_wsale_detail") 
	}
    };
    
    var sell_type =  [{name:"销售开单", id:0, py:diablo_pinyin("销售开单")},
    		      {name:"销售退货", id:1, py:diablo_pinyin("销售退货")}];

    var now = $.now(); 
    var shopId = $scope.shopIds.length === 1 ? $scope.shopIds[0]: -1;
    
    // base setting 
    $scope.setting.se_pagination = wsaleUtils.sequence_pagination(shopId, base);
    // $scope.setting.show_sale_day = wsaleUtils.show_sale_day(shopId, base);
    $scope.setting.show_sale_day = user.sdays; 
    var storage = localStorageService.get(diablo_key_wsale_trans_detail);
    
    if (use_storage && angular.isDefined(storage) && storage !== null){
    	$scope.filters     = storage.filter;
	$scope.qtime_start  = storage.start_time; 
    } else{
	$scope.filters = [];
	if (angular.isDefined($routeParams.rsn))
	    $scope.qtime_start = diablo_set_date(wsaleUtils.start_time(shopId, base, now, dateFilter));
	else 
	    $scope.qtime_start = now;
    };

    $scope.time = wsaleUtils.correct_query_time(
	$scope.right.master, $scope.setting.show_sale_day, $scope.qtime_start, now, diabloFilter); 
    
    // console.log($scope.setting);
    // filter
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number); 
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("type",     filterType);
    diabloFilter.add_field("year",     diablo_full_year);
    diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("shop",     $scope.shops); 
    diabloFilter.add_field("retailer", filterRetailer); 
    diabloFilter.add_field("employee", filterEmployee); 
    diabloFilter.add_field("sell_type", sell_type);
    diabloFilter.add_field("rsn", []); 
   
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt(); 
    
    /*
     * pagination 
     */
    // $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	if (!$scope.right.master){
	    var diff = now - diablo_get_time($scope.time.start_time);
	    // console.log(diff);
	    if (diff - diablo_day_millisecond * $scope.setting.show_sale_day > diablo_day_millisecond){
	    	$scope.time.start_time = now - $scope.setting.show_sale_day * diablo_day_millisecond;
	    }
	}
	
	// save condition of query
	if (use_storage){
	    localStorageService.set(
		diablo_key_wsale_trans_detail,
		{filter:$scope.filters,
		 start_time: diablo_get_time($scope.time.start_time), page:page, t:now});
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined;
	    };
	    
	    if (angular.isUndefined(search.shop)
	    	|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    };
	    
	    console.log(search);

	    wsaleService.filter_w_sale_rsn_group(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		    $scope.total_amounts = result.total === 0 ? 0 : result.t_amount;
		    $scope.total_balance = result.total === 0 ? 0 : $scope.round(result.t_balance);
		    $scope.total_obalance = result.total === 0 ? 0 : $scope.round(result.t_obalance);
		    $scope.inventories = [];
		}
		angular.forEach(result.data, function(d){
		    d.brand    = diablo_get_object(d.brand_id, filterBrand);
		    d.firm     = diablo_get_object(d.firm_id, filterFirm);
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    d.type      = diablo_get_object(d.type_id, filterType);
		    d.oseason    = diablo_get_object(d.season, diablo_season2objects);
		    d.promotion = diablo_get_object(d.pid, filterPromotion);
		    d.score     = diablo_get_object(d.sid, filterScore);
		    d.drate     = diablo_discount(d.rprice, d.tag_price);
		    d.gprofit   = d.rprice <= diablo_pfree ? 0 : diablo_discount(
			diablo_float_sub(d.rprice, d.org_price), d.rprice);
		    d.calc      = diablo_float_mul(d.rprice, d.total); 
		});

		if ($scope.setting.se_pagination === diablo_no){
		    $scope.inventories = result.data;
		    diablo_order_page(
			page, $scope.items_perpage, $scope.inventories);
		} else {
		    diablo_order(
			result.data, (page - 1) * $scope.items_perpage + 1);
		    $scope.inventories = $scope.inventories.concat(result.data);
		}

		$scope.current_page = page;
		
	    })
	})
    }; 

    // default the first page
    if (!use_storage){
	$scope.do_search($scope.default_page);
    }

    $scope.auto_pagination = function(){
	$scope.current_page += 1;
	$scope.do_search($scope.current_page);
    };
    
    $scope.page_changed = function(){
	console.log($scope.current_page);
	$scope.do_search($scope.current_page);
    } 

    var get_amount = function(cid, size, amounts){
	for(var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === size){
		return amounts[i].count;
	    }
	}
	return undefined;
    };

  
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
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
	if (angular.isDefined(inv.amounts)
	    && angular.isDefined(inv.colors)
	    && angular.isDefined(inv.order_sizes)){

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
	    
	    var order_sizes = wgoodService.format_size_group(inv.s_group, filterSizeGroup);
	    var sort = purchaserService.sort_inventory(result.data, order_sizes, filterColor);
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
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    };
	    
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    wsaleService.csv_export(
		wsaleService.export_type.trans_note, search
	    ).then(function(result){
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

    var dialog = diabloUtilsService;
    $scope.print = function(){
	var rsn = $routeParams.rsn; 
	var shop = diablo_get_object(parseInt(rsn.split("-")[3]), $scope.shops);
	var p_mode = wsaleUtils.print_mode(shop.id, base);
	var no_vip = wsaleUtils.no_vip(shop.id, base);
	var comments = wsaleUtils.comment(shop.id, base);
	var isRound = wsaleUtils.round(shop.id, base);
	var cakeMode = wsaleUtils.cake_mode(shop.id, base);
	var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");

	console.log(isRound, cakeMode);
	
	if (diablo_frontend === p_mode){
	    if (angular.isUndefined(LODOP)) LODOP=getLodop();
	    console.log(LODOP);

	    if (angular.isDefined(LODOP)){
		wsaleService.get_w_sale_new(rsn).then(function(result){
		    console.log(result);
		    var sale = result.sale;
		    var detail = angular.copy(result.detail);
		    angular.forEach(detail, function(d){
			d.brand = diablo_get_object(d.brand_id, filterBrand).name;
			d.type = diablo_get_object(d.type_id, filterType).name;
		    })
		    
		    console.log(wsalePrint);
		    wsalePrint.gen_head(LODOP,
					shop.name,
					rsn,
					diablo_get_object(sale.employ_id, filterEmployee).name,
					diablo_get_object(sale.retailer_id, filterRetailer).name,
					sale.entry_date);

		    var hLine = wsalePrint.gen_body(LODOP, detail, isRound, cakeMode); 
		    var isVip = sale.retailer_id !== no_vip ? true : false;
		    
		    hLine = wsalePrint.gen_stastic(LODOP, hLine, sale.direct, sale, isVip); 
		    wsalePrint.gen_foot(LODOP, hLine, comments, pdate, cakeMode);
		    wsalePrint.start_print(LODOP);
		    
		    // LODOP.PRINT_INITA("");
		    // LODOP.ADD_PRINT_TEXT(15,5,"40mm",30,shop.name); 
		    // LODOP.SET_PRINT_STYLEA(1,"FontSize",13);
		    // LODOP.SET_PRINT_STYLEA(1,"bold",1);
		    // // LODOP.SET_PRINT_STYLEA(0,"Horient",2);

		    // // console.log(diablo_get_object(sale.retailer_id, filterRetailer));
		    // // console.log(diablo_get_object(sale.employ_id, filterEmployee));
		    // LODOP.ADD_PRINT_TEXT(50,5,"58mm",20,"单号：" + rsn);
		    // LODOP.ADD_PRINT_TEXT(65,5,"58mm",20,"客户：" + diablo_get_object(sale.employ_id, filterEmployee).name);
		    // LODOP.ADD_PRINT_TEXT(80,5,"58mm",20,"店员：" + diablo_get_object(sale.retailer_id, filterRetailer).name);
		    // LODOP.ADD_PRINT_TEXT(95,5,"58mm",20,"日期：" + sale.entry_date);

		    // LODOP.ADD_PRINT_LINE(115,5,115,178,0,1);


		    // var hLine = 125;
		    // angular.forEach(result.detail, function(d){
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"款号：" + d.style_number);
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"品名：" + diablo_get_object(d.brand_id, filterBrand).name);
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"单价：" + d.tag_price.toString());
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"成交价：" + d.rprice.toString());
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"数量：" + d.total.toString());
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"小计：" + wsaleUtils.to_decimal(d.total * d.rprice).toString());
		    // 	hLine += 15;
		    // 	LODOP.ADD_PRINT_TEXT(hLine,5,100,20,"折扣率：" + wsaleUtils.ediscount(d.rprice, d.tag_price).toString());

		    // 	hLine += 15;
			
		    // });

		    // // LODOP.ADD_PRINT_LINE(hLine + 5,5,hLine + 5,178,0,1);
		    
		    // LODOP.SET_PRINT_PAGESIZE(3,"58mm",50,""); 
		    // // LODOP.PREVIEW();
		    // LODOP.PRINT();
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
});
