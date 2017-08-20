function purchaserInventoryFixCtrlProvide(
    $scope, $q, $timeout, dateFilter, localStorageService, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter, purchaserService,
    user, filterEmployee, filterSizeGroup, filterColor, base){
    // console.log(user); 
    $scope.shops   = user.sortShops;    
    // $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season;
    // $scope.calc_row = stockUtils.calc_row;
    $scope.setting = {barcode_mode: diablo_no}; 
    
    var dialog = diabloUtilsService;
    // var fixDraft = new stockFile(diablo_fix_draft_path);
    var fix_time;
    var LODOP;
    
    if (needCLodop) loadCLodop();

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.has_saved = false; 
    }; 

    // focus
    $scope.focus = {style_number:false, barcode: false, fix:false};
    $scope.auto_focus = function(attr){
	if (!$scope.focus[attr]){
	    $scope.focus[attr] = true;
	}
	for (var o in $scope.focus){
	    if (o !== attr) $scope.focus[o] = false;
	} 
    };

    $scope.get_setting = function(shopId) {
	$scope.setting.barcode_mode = stockUtils.use_barcode(shopId, base);
    };

    $scope.change_shop = function() {
	$scope.get_setting($scope.select.shop.id);
    };

    $scope.get_employee = function(){
	var select = stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = select.login;
	$scope.employees = select.filter;
    };

    $scope.focus_good_or_barcode = function() {
	if ($scope.setting.barcode_mode)
	    $scope.auto_focus('barcode');
	else
	    $scope.auto_focus('style_number');
    }; 
    
    /*
     * init
     */ 
    // $scope.refresh();
    // var now = $.now();
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.select = {shop:$scope.shops[0], datetime: undefined, total:0}
    $scope.has_saved = false;
    
    $scope.get_employee();
    $scope.get_setting();
    $scope.focus_good_or_barcode();
       
    // $scope.base_settings = {
    // 	plimit : stockUtils.prompt_limit($scope.select.shop.id, base),
    // 	prompt : stockUtils.typeahead($scope.select.shop.id, base),
    // 	start_time : stockUtils.start_time($scope.select.shop.id, base, now, dateFilter)
    // }; 

    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    };

    $scope.on_select_good = function(item, model, label){
	// add at first allways 
	var add = $scope.inventories[0];

	add.id           = item.id;
	add.bcode        = item.bcode;
	add.full_bcode   = item.full_bcode; 
	add.style_number = item.style_number;
	
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	
	add.type         = item.type;
	add.type_id      = item.type_id;
	
	add.firm_id      = item.firm_id;
	
	add.sex          = item.sex; 
	add.season       = item.season;
	add.year         = item.year;
	
	add.tag_price    = item.tag_price;
	add.discount     = item.discount;

	add.free         = item.free;
	add.s_group      = item.s_group;
	add.path         = item.path;
	add.entry        = item.entry_date;

	add.full_name    = item.style_number + "/" + item.brand;

	console.log(add); 
	$scope.auto_focus("fix");
	$scope.add_inventory(add); 
	return;
    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
    	for (var i=1, l=$scope.inventories.length; i<l; i++){
    	    var one = $scope.inventories[i];
	    $scope.select.total += one.fix;
    	}	
    };

    /*
     * draft
     */ 
    
    $scope.get_draft = function(){
	var fixDraft = new stockFile(diablo_fix_draft_path);
	fixDraft.getLodop();

	var callbackIsFileExist = function(taskId, value) {
	    if (value) {
		// console.log(value);
		var callbackReadFile = function(taskId, value){
		    console.log(value); 
		    $scope.$apply(function() {
			var content = angular.fromJson(value);
			fix_time = content.t;
			$scope.select.datetime = dateFilter(fix_time, "yyyy-MM-dd HH:mm:ss");
			$scope.inventories = content.stock;
			console.log($scope.inventories);
			angular.forEach($scope.inventories, function(inv) {
			    if (!inv.$new) {
				inv.color = get_color(inv.color_id, inv.colors); 
			    }
			});
			
			// $scope.inventories.unshift({$edit:false, $new:true}); 
			// console.log($scope.select.datetime);
			console.log($scope.inventories);
			$scope.focus_good_or_barcode();
			$scope.re_calculate();
		    });
		}
		fixDraft.setCallback(callbackReadFile);
		fixDraft.readFile();
	    } else {
		dialog.response(false, "库存盘点", purchaserService.error[2083]);
	    }
	}
	fixDraft.setCallback(callbackIsFileExist);
	fixDraft.isFileExist(); 
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	return $scope.has_saved || $scope.inventories.length === 1 ? true : false;
    }; 

    var in_stocks = function(s, stocks) {
	var found = false;
	for (var i=0, l=stocks.length; i<l; i++) {
	    if (s.style_number === stocks[i].style_number
		&& s.brand_id === stocks[i].brand
		&& s.color.cid === stocks[i].color
		&& s.size === stocks[i].size) {
		stocks[i].fix += s.fix;
		found = true;
		break;
	    }
	}

	return found;
    };
    
    $scope.save_inventory = function(){
	$scope.has_saved = true
	// console.log($scope.inventories); 
	var added = []; 
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i]; 
	    if (!in_stocks(add, added)) {
		added.push({
		    style_number: add.style_number,
		    brand:        add.brand_id,
		    fix:          add.fix,
		    color:        add.color.cid,
		    size:         add.size,

		    type:         add.type_id,
		    firm:         add.firm_id,
		    season:       add.season,
		    year:         add.year,
		    tag_price:    add.tag_price
		});
	    }
	};
	
	var base = {
	    total:            $scope.select.total,
	    shop:             $scope.select.shop.id,
	    datetime:         $scope.select.datetime,
	    employee:         $scope.select.employee.id, 
	};

	console.log(added);
	console.log(base);

	if (added.length === 0) {
	    dialog.response(false, "库存盘点", "盘点失败", purchaserService.error[2084]);
	    return;
	}

	purchaserService.fix_purchaser_inventory({stock: added, base: base}).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		dialog.response(true,
				"库存盘点", "盘点成功！！单号："
				+ result.rsn + "，请查看盘点差异单！！");
	    } else {
		$scope.has_saved = false;
		dialog.response(
		    false,
		    "库存盘点",
		    "盘点失败", purchaserService.error[result.ecode]);
	    }
	}); 
    };

    /*
     * add
     */
    var get_color = function(colorId, colors) {
	for (var i=0, l=colors.length; i<l; i++){
	    if (colorId === colors[i].cid){
		return colors[i];
	    } 
	} 
    };

    var get_color_by_bcode = function(bcode, colors) {
	for (var i=0, l=colors.length; i<l; i++){
	    if (bcode === colors[i].bcode){
		return colors[i];
	    } 
	} 
    };

    var get_size = function(size, sizes) {
	for (var i=0, l=sizes.length; i<l; i++) {
	    if (size === sizes[i]) {
		return sizes [i];
	    }
	}
    };

    $scope.save_draft = function() {
	if ($scope.inventories.length === 2) {
	    fix_time = $.now();
	    $scope.select.datetime = dateFilter(fix_time, "yyyy-MM-dd HH:mm:ss");
	}

	var stocks = $scope.inventories.map(function(r) {
	    // return !r.$new;
	    if (r.$new) {
		return {$new: r.$new};
	    } else {
		return {
		    $new         :r.$new,
		    bcode        :r.bcode,
		    full_bcode   :r.full_bcode,
		    style_number :r.style_number,
		    brand        :r.brand,
		    brand_id     :r.brand_id, 
		    type         :r.type,
		    type_id      :r.type_id,
		    firm_id      :r.firm_id,

		    sex          :r.sex,
		    season       :r.season,
		    year         :r.year,

		    tag_price    :r.tag_price,
		    discount     :r.discount,

		    free         :r.free,
		    s_group      :r.s_group,
		    path         :r.path,
		    entry        :r.entry,

		    full_name    :r.full_name,

		    color_id     :r.color.cid,
		    colors       :r.colors,
		    size         :r.size,
		    sizes        :r.sizes, 
		    fix          :r.fix 
		};
	    }
	});

	var fixDraft = new stockFile(diablo_fix_draft_path);
	fixDraft.getLodop();
	// console.log(angular.toJson({t:fix_time, stock:stocks})); 
	// if (angular.isUndefined(LODOP)) LODOP = getLodop();
	// if (angular.isUndefined(LODOP.VERSION)) return; 
	fixDraft.writeFile(angular.toJson({t:fix_time, stock:stocks}));
    };

    $scope.barcode_scanner = function(full_bcode) {
    	console.log(full_bcode); 
	var barcode = diabloHelp.correct_barcode(full_bcode); 
	console.log(barcode);
	
	diabloFilter.get_stock_by_barcode(barcode.cuted, $scope.select.shop.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.response(false, "库存盘点", "盘点失败" + purchaserService.error[2085]);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.response(false, "库存盘点", "盘点失败" + purchaserService.error[result.ecode]);
	    }
	});
	
    };

    $scope.add_inventory = function(inv){
	purchaserService.list_purchaser_inventory(
	    {style_number:inv.style_number, brand:inv.brand_id, shop:$scope.select.shop.id}
	).then(function(invs){
	    console.log(invs); 
	    var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(invs, order_sizes, filterColor);
	    
	    // inv.total   = sort.total;
	    inv.sizes   = sort.size;
	    inv.colors  = sort.color; 
	    // inv.amounts = sort.sort;
	    
	    if ($scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
		if (inv.free === 0) {
		    inv.color = get_color(diablo_free_color, inv.colors);
		    inv.size  = get_size(diablo_free_size, inv.sizes);
		} else {
		    var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
		    console.log(color_size);
		    
		    var bcode_color = stockUtils.to_integer(color_size.substr(0, 3));
		    var bcode_size_index = stockUtils.to_integer(
			color_size.substr(3, color_size.length));
		    var bcode_size = size_to_barcode[bcode_size_index];
		    // var bcode_size = color_size.substr(3, color_size.length);

		    if (bcode_color === diablo_free_color) {
			inv.color = get_color(diablo_free_color, inv.colors);
		    } else {
			inv.color = get_color_by_bcode(bcode_color, inv.colors);
		    }

		    if (bcode_size === diablo_free_size) {
			inv.size = get_size(diablo_free_size, inv.sizes);
		    } else {
			inv.size = get_size(bcode_size, inv.sizes);
		    }
		} 
		inv.fix = 1;
		$scope.auto_save_free(inv); 
	    } else {
		inv.color = inv.colors[0];
		inv.size = inv.sizes[0];
	    } 
	    // }
	}); 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	// console.log($scope.inventories)

	// var deleteIndex = -1;
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	$scope.re_calculate();
	$scope.save_draft();
    };

    $scope.add_free_inventory = function(inv){
	console.log(inv);
	inv.$new = false; 
	// oreder
	inv.order_id = $scope.inventories.length; 
	$scope.inventories.unshift({$edit:false, $new:true});
	$scope.focus_good_or_barcode();
	$scope.re_calculate();
	$scope.save_draft();
    };
    
    $scope.save_free_update = function(inv){
    	$timeout.cancel($scope.timeout_auto_save);
    	$scope.re_calculate();
	$scope.save_draft();
    }

    // $scope.cancel_free_update = function(inv){
    // 	$timeout.cancel($scope.timeout_auto_save);
    // 	inv.free_update = false; 
    // }

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};;
    }

    $scope.timeout_auto_save = undefined;
    $scope.auto_save_free = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	if (0 === stockUtils.to_integer(inv.fix) ){
	    return;
	}

	$scope.timeout_auto_save = $timeout(function(){
	    if (inv.$new){
		$scope.add_free_inventory(inv);
	    } else {
		$scope.save_free_update(inv);
	    } 
	}, 500); 
	
    };
};



function purchaserInventoryFixDetailCtrlProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, user, filterEmployee, base){
    console.log(user);

    $scope.goto_page = diablo_goto_page;

    $scope.go_fix = function(){
	$scope.goto_page('#/inventory/inventory_fix');
    };

    $scope.go_fix_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/fix');
    };

    /*
    ** filter
    */ 

    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.sortShops);
    // diabloFilter.add_field("shop",     user.sortAvailabeShops);
    // diabloFilter.add_field("firm",     filterFirm);
    diabloFilter.add_field("employee", filterEmployee); 

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var now = $.now();
    $scope.qtime_start = function(shopId){
	return diablo_base_setting(
	    "qtime_start", shopId, base, diablo_set_date, diabloFilter.default_start_time(now));
    }();
    // console.log($scope.qtime_start);
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start); 
    // $scope.time   = diabloFilter.default_time();

    console.log($scope.filter);
    
    /*
     * pagination 
     */
    $scope.colspan = 15;
    $scope.items_perpage = 10;
    $scope.default_page = 1;
    // $scope.current_page = $scope.default_page;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = user.availableShopIds.length
		    === 0 ? undefined : user.shopIds; ;
	    }

	    purchaserService.filter_fix_w_inventory(
		$scope.match, search, page, $scope.items_perpage).then(function(result){
		    console.log(result);
		    if (page === 1){
			$scope.total_items = result.total
		    }
		    angular.forEach(result.data, function(d){
			d.shop = diablo_get_object(d.shop_id, user.sortShops);
			d.employee = diablo_get_object(d.employee_id, filterEmployee);
			d.metric = d.shop_total - d.db_total;
		    })
		    $scope.records = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.records);
		})

	    $scope.current_page = page;
	    
	})
    };
    
    // default the first page
    $scope.do_search($scope.default_page);

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	diablo_goto_page("#/inventory/inventory_rsn_detail/fix/" + r.rsn);
    }
    
};

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryFixCtrl", purchaserInventoryFixCtrlProvide);
    app.controller("purchaserInventoryFixDetailCtrl", purchaserInventoryFixDetailCtrlProvide);
});
