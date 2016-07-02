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

    /*
     * right
     */
    $scope.right = {
	show_stastic:  rightAuthen.authen_master(user.type),
	show_orgprice: rightAuthen.authen_master(user.type)
    };

    $scope.calc_colspan = function(){
	var column = 14;
	if ($scope.hidden.base) column -= 3;
	
	return column;
    }

    var dialog      = diabloUtilsService; 
    var use_storage = $routeParams.rsn ? false : true;

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
    $scope.setting.only_day = wsaleUtils.only_show_current(shopId, base);
    var storage = localStorageService.get(diablo_key_wsale_trans_detail);
    
    if (use_storage && angular.isDefined(storage) && storage !== null){
    	$scope.filters     = storage.filter;
	if (angular.isUndefined(storage.start_time))
	    $scope.qtime_start = wsaleUtils.start_time(shopId, base, now, dateFilter);
	else
    	    $scope.qtime_start  = storage.start_time; 
    } else{
	$scope.filters = []; 
	$scope.qtime_start = wsaleUtils.start_time(shopId, base, now, dateFilter);
    };

    if ($scope.right.show_orgprice && diablo_no === $scope.setting.only_day){
	$scope.time   = diabloFilter.default_time($scope.qtime_start, now); 
    } else {
	$scope.time   = diabloFilter.default_time(now, now); 
    }
    
    // console.log($scope.setting);
    // filter
    diabloFilter.reset_field();
    diabloFilter.add_field("retailer", filterRetailer);
    diabloFilter.add_field("style_number", $scope.match_style_number); 
    diabloFilter.add_field("brand",    filterBrand);
    diabloFilter.add_field("type",     filterType);
    diabloFilter.add_field("year",     diablo_full_year);
    diabloFilter.add_field("firm",     filterFirm); 
    diabloFilter.add_field("employee", filterEmployee); 
    diabloFilter.add_field("sell_type", sell_type);
    diabloFilter.add_field("rsn", []); 
    diabloFilter.add_field("shop",     $scope.shops);
   
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt(); 
    
    /*
     * pagination 
     */
    $scope.colspan = 17;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 10;
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	// save condition of query
	if (use_storage){
	    localStorageService.set(
		diablo_key_wsale_trans_detail,
		{filter:$scope.filters,
		 start_time: function(){
		     if ($scope.right.show_orgprice && diablo_no === $scope.setting.only_day){
			 return diablo_get_time($scope.time.start_time);
		     }
		     return undefined;
		 }(),
		 page:page, t:now});
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
});
