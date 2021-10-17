function purchaserInventoryFixCtrlProvide(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloFilter, diabloPagination, purchaserService, diabloPattern,
    user, filterEmployee, filterSizeGroup, filterColor, filterFirm, base){
    // console.log(user); 
    $scope.shops   = user.sortShops;    
    // $scope.sexs    = diablo_sex;
    $scope.seasons = diablo_season;
    $scope.firms   = filterFirm;
    // $scope.calc_row = stockUtils.calc_row;
    $scope.setting = {barcode_mode: diablo_no};
    $scope.useFile = false;
    $scope.pattern = {barcode:diabloPattern.number, fix:diabloPattern.number_3};
    $scope.fix = {scanner:false};
    $scope.fix_attr = {colors:undefined, sizes:undefined};
    
    var dialog = diabloUtilsService;
    // var fixDraft = new stockFile(diablo_fix_draft_path);
    var fix_time;
    // var LODOP;
    
    if (needCLodop()) {
	$scope.useFile = true;
	
	var print_access = stockUtils.print_num(diablo_default_shop, base);
	loadCLodop(print_access.protocal); 
    }

    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.has_saved = false;
	$scope.select.total = 0;
	$scope.current_page  = 1;
	$scope.reset_pagination();
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

    $scope.reset_focus = function() {
    	for (var o in $scope.focus){
    	    $scope.focus[o] = false;
    	} 
    };

    // $scope.get_setting = function(shopId) {
    // 	$scope.setting.barcode_mode = stockUtils.use_barcode(shopId, base);
    // };

    // $scope.change_shop = function() {
    // 	$scope.get_setting($scope.select.shop.id);
    // };

    $scope.setting.barcode_mode = stockUtils.use_barcode(diablo_default_shop, base);
    $scope.setting.auto_barcode    = stockUtils.auto_barcode(diablo_default_shop, base);
    
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


    $scope.get_prompt_firm = function(prompt){
	return stockUtils.get_prompt_firm(prompt, $scope.firms)
    };
    
    /*
     * init
     */ 
    // $scope.refresh();
    // var now = $.now();
    $scope.inventories = [];
    // $scope.inventories.push({$edit:false, $new:true});
    $scope.select = {shop:$scope.shops[0], datetime: undefined, total:0}
    $scope.has_saved = false;
    
    $scope.get_employee();
    // $scope.get_setting();
    $scope.focus_good_or_barcode();
    
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    };

    $scope.on_select_good = function(item, model, label){
	console.log(item);
	// $scope.reset_focus();
	// var add = {};
	
	// add.id           = item.id;
	// $scope.fix.s_barcode    = item.full_bcode;
	
	$scope.fix.bcode        = item.bcode; 
	// $scope.fix.full_bcode   = item.full_bcode; 
	$scope.fix.style_number = item.style_number;
	
	$scope.fix.brand        = item.brand;
	$scope.fix.brand_id     = item.brand_id;
	
	$scope.fix.type         = item.type;
	$scope.fix.type_id      = item.type_id;
	
	$scope.fix.firm_id      = item.firm_id;
	
	$scope.fix.sex          = item.sex; 
	$scope.fix.season       = item.season;
	$scope.fix.year         = item.year;
	
	$scope.fix.tag_price    = item.tag_price;
	$scope.fix.discount     = item.discount;

	$scope.fix.free         = item.free;
	$scope.fix.s_group      = item.s_group;
	$scope.fix.path         = item.path;
	$scope.fix.entry        = item.entry_date;

	// console.log($scope.focus);
	$scope.fix.full_name    = item.style_number + "/" + item.brand + "/" + item.type;
	if ($scope.fix.full_bcode !== diablo_empty_db_barcode
	    && $scope.fix.full_bcode !== diablo_empty_barcode
	    && angular.isDefined(diablo_set_string($scope.fix.full_bcode))) {
	    $scope.fix.full_name = $scope.fix.full_bcode + "/" + $scope.fix.full_name;
	}
	
	// console.log(add);
	if (!$scope.fix.scanner) {
	    $scope.auto_focus("fix");
	} 
	$scope.add_inventory(); 
	return;
    };

    $scope.re_calculate = function(){
	$scope.select.total = 0;
    	for (var i=0, l=$scope.inventories.length; i<l; i++){
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
		    var content = angular.fromJson(value);
		    fix_time = content.t; 

		    if (angular.isDefined(content.t)) {
			$scope.$apply(function() {
			    $scope.select.datetime = dateFilter(fix_time, "yyyy-MM-dd HH:mm:ss");
			    $scope.select.firm = diablo_get_object(content.f, $scope.firms);
			    $scope.inventories = content.stock; 
			    $scope.current_page = 1;
			    $scope.reset_pagination();
			    $scope.re_calculate(); 
			});
		    } else {
			dialog.response(false, "库存盘点", purchaserService.error[2083]);
		    }
		    
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
	return $scope.has_saved || $scope.inventories.length === 0 ? true : false;
    };

    $scope.disable_draft = function() {
	return !$scope.useFile;
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
	console.log($scope.inventories); 
	var added = []; 
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    if (0 === stockUtils.to_integer(add.fix))
		continue;
	    if (angular.isUndefined(add.color) || !angular.isObject(add.color))
		continue;
	    
	    if (!in_stocks(add, added)) {
		added.push({
		    style_number: add.style_number,
		    brand:        add.brand_id,
		    firm:         add.firm_id,
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
	    firm:             stockUtils.invalid_firm($scope.select.firm),
	    datetime:         $scope.select.datetime,
	    employee:         $scope.select.employee.id, 
	};

	console.log(added);
	console.log(base);
	if (added.length === 0) {
	    dialog.response(false, "库存盘点", "盘点失败" + purchaserService.error[2084]);
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
	if ($scope.inventories.length === 1) {
	    fix_time = $.now();
	    $scope.select.datetime = dateFilter(fix_time, "yyyy-MM-dd HH:mm:ss");
	}

	var stocks = $scope.inventories.map(function(r) {
	    // return !r.$new; 
	    return {
		order_id     :r.order_id,
		// bcode        :r.bcode,
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

		color        :r.color,
		size         :r.size,
		// color_id     :r.color.cid,
		// colors       :r.colors,
		// size         :r.size,
		// sizes        :r.sizes, 
		fix          :r.fix
	    };
	});

	if ($scope.useFile) {
	    var fixDraft = new stockFile(diablo_fix_draft_path);
	    fixDraft.getLodop(); 
	    fixDraft.writeFile(angular.toJson({
		t:fix_time, f:stockUtils.invalid_firm($scope.select.firm), stock:stocks}));
	}
    };

    $scope.barcode_scanner = function(full_bcode) {
    	console.log(full_bcode); 
	var barcode = diabloHelp.correct_barcode(full_bcode, $scope.setting.auto_barcode); 
	console.log(barcode); 
	// invalid barcode
	if (!barcode.cuted || !barcode.correct) {
	    $scope.fix.s_barcode = undefined;
	    dialog.response(false, "库存盘点", "盘点失败：" + purchaserService.error[2076]); 
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(
	    barcode.cuted,
	    $scope.select.shop.id,
	    stockUtils.invalid_firm($scope.select.firm)
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    $scope.fix.s_barcode = undefined;
		    dialog.response(false, "库存盘点", "盘点失败：" + purchaserService.error[2085]);
		} else {
		    $scope.fix.scanner = true; 
		    $scope.fix.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.response(false, "库存盘点", "盘点失败" + purchaserService.error[result.ecode]);
	    }
	});
	
    };

    $scope.add_inventory = function(){
	purchaserService.list_purchaser_inventory(
	    {style_number:$scope.fix.style_number, brand:$scope.fix.brand_id, shop:$scope.select.shop.id}
	).then(function(invs){
	    // console.log(invs); 
	    var order_sizes = diabloHelp.usort_size_group($scope.fix.s_group, filterSizeGroup);
	    var sort = diabloHelp.sort_stock(invs, order_sizes, filterColor);
	    
	    // inv.total   = sort.total;
	    $scope.fix_attr.sizes   = sort.size;
	    $scope.fix_attr.colors  = sort.color; 
	    // inv.amounts = sort.sort;
	    
	    if ($scope.setting.barcode_mode && angular.isDefined($scope.fix.full_bcode)) {
		if ($scope.fix.free === 0) {
		    $scope.fix.color = get_color(diablo_free_color, $scope.fix_attr.colors);
		    $scope.fix.size  = get_size(diablo_free_size, $scope.fix_attr.sizes);
		} else {
		    var color_size = $scope.fix.full_bcode.substr($scope.fix.bcode.length, $scope.fix.full_bcode.length);
		    console.log(color_size);
		    
		    var bcode_color = stockUtils.to_integer(color_size.substr(0, 3));
		    var bcode_size_index = stockUtils.to_integer(color_size.substr(3, color_size.length));
		    
		    var bcode_size = bcode_size_index === 0 ? diablo_free_size : size_to_barcode[bcode_size_index];
		    // var bcode_size = color_size.substr(3, color_size.length);

		    if (bcode_color === diablo_free_color) {
			$scope.fix.color = get_color(diablo_free_color, $scope.fix_attr.colors);
		    } else {
			$scope.fix.color = get_color_by_bcode(bcode_color, $scope.fix_attr.colors);
		    }

		    if (bcode_size === diablo_free_size) {
			$scope.fix.size = get_size(diablo_free_size, $scope.fix_attr.sizes);
		    } else {
			$scope.fix.size = get_size(bcode_size, $scope.fix_attr.sizes);
		    }
		}

		$scope.fix.fix = 1; 
		$scope.auto_save_free();
		
	    } else {
		$scope.fix.color = $scope.fix_attr.colors[0];
		$scope.fix.size = $scope.fix_attr.sizes[0]; 
	    } 
	    // }
	}); 
    };

    /*
     * pagination
     */
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    // $scope.default_page  = 1;
    $scope.current_page  = 1;
    $scope.reset_pagination = function() {
	diabloPagination.set_data($scope.inventories);
	diabloPagination.set_items_perpage($scope.items_perpage);
	$scope.total_items = diabloPagination.get_length();
	$scope.page_items  = diabloPagination.get_page($scope.current_page);
    };

    $scope.page_changed = function(page) {
	$scope.current_page = page;
	$scope.page_items   = diabloPagination.get_page($scope.current_page);
    };

    $scope.reset_pagination();
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	// console.log($scope.inventories)

	// var deleteIndex = -1;
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	// reorder
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	$scope.reset_pagination();
	$scope.re_calculate();
	$scope.save_draft();
    }; 

    $scope.add_free_inventory = function(){
	console.log($scope.fix);
	$scope.fix.order_id = $scope.inventories.length + 1; 
	$scope.inventories.unshift($scope.fix);
	$scope.re_calculate();
	
	$scope.reset_pagination(); 
	$scope.save_draft();
	
	$scope.reset_fix();
	$scope.focus_good_or_barcode();

    };
    
    $scope.save_free_update = function(inv){
    	$timeout.cancel($scope.timeout_auto_save);
    	$scope.re_calculate();
	$scope.save_draft();
    } 

    $scope.reset_fix = function(){
	// console.log($scope.fix);
	$timeout.cancel($scope.timeout_auto_save); 
	$scope.fix = {scanner:false};
	$scope.fix_attr = {};
    }

    $scope.timeout_auto_save = undefined;
    $scope.auto_save_free = function(){
	// console.log($scope.fix);
	$timeout.cancel($scope.timeout_auto_save);
	var re = $scope.pattern.fix;
	if (0 === stockUtils.to_integer($scope.fix.fix) || !re.test(stockUtils.to_integer($scope.fix.fix))){
	    return;
	}

	$scope.timeout_auto_save = $timeout(function(){
	    $scope.add_free_inventory();
	}, 500); 
	
    };
};


function purchaserInventoryImportFixCtrlProvide(
    $scope, $q, $timeout, dateFilter, FileUploader,
    diabloUtilsService, diabloFilter, purchaserService,
    user, filterEmployee, base){
    $scope.shops   = user.sortShops;    
    var dialog = diabloUtilsService; 
    $scope.select = {shop:$scope.shops[0], total:0}
    $scope.select.datetime = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
    
    $scope.get_employee = function(){
	var select = stockUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.select.employee = select.login;
	$scope.employees = select.filter;
    };

    $scope.get_employee();

    $scope.uploader = new FileUploader({
        url: '/purchaser/upload_stock/' + $scope.select.shop.id.toString()
    });

    $scope.change_shop = function(){
	$scope.uploader.url = '/purchaser/upload_stock/' + $scope.select.shop.id.toString();
	console.log($scope.uploader.url);
    };

    $scope.uploader.filters.push({
        name: 'syncFilter',
        fn: function(item /*{File|FileLikeObject}*/, options) {
            console.log('syncFilter');
            return this.queue.length < 1;
        }
    });

    $scope.uploader.onWhenAddingFileFailed = function(item /*{File|FileLikeObject}*/, filter, options) {
	console.info('onWhenAddingFileFailed', item, filter, options);
	dialog.response(false, "库存导入", "库存导入失败：" + purchaserService.error[2077]); 
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
	// if (response.ecode === 0){
	//     dialog.response(true, "库存导入", "库存导入成功！！导入店铺：" + $scope.select.shop.name);
	// } else if (response.ecode === 2712) {
	//     fileItem.isSuccess = false;
	//     fileItem.isError = true;
	//     fileItem.isUploaded = false;
	//     fileItem.progress = 0;
	//     var message = wsaleService.error[2712]
	// 	+ "[款号：" + response.style_number
	// 	+ "，总数量：" + response.total
	// 	+ "，校验数量：" + response.amount +"]";
	//     dialog.response(false, "销售单导入", "销售单导入失败：" + message)
	// } else {
	//     fileItem.isSuccess = false;
	//     fileItem.isError = true;
	//     fileItem.isUploaded = false;
	//     fileItem.progress = 0;
	//     var message = wsaleService.error[response.ecode] + "[款号：" + response.style_number + "]";
	//     dialog.response(false, "销售单导入", "销售单导入失败：" + message);
	// } 
    };
    
    $scope.uploader.onCompleteAll = function() {
        console.info('onCompleteAll');
    };

    console.info('uploader', $scope.uploader);
};



function purchaserInventoryFixDetailCtrlProvide(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    diabloFilter, purchaserService, filterSysRetailer, user, filterEmployee, filterFirm, base){
    // console.log(user);
    console.log(filterSysRetailer);
    $scope.goto_page = diablo_goto_page;
    
    $scope.go_fix = function(){
	$scope.goto_page('#/inventory/inventory_fix');
    };
    
    $scope.go_fix_rsn = function(){
	$scope.goto_page('#/inventory/inventory_rsn_detail/fix');
    };

    var dialog = diabloUtilsService;
    
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight();
    // console.log($scope.stock_right); 
    
    // initial
    $scope.filters = [];
    
    diabloFilter.reset_field();
    diabloFilter.add_field("rsn", []);
    diabloFilter.add_field("shop",     user.sortShops);
    // diabloFilter.add_field("shop",     user.sortAvailabeShops);
    diabloFilter.add_field("firm",     filterFirm);
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
			d.firm = diablo_get_object(d.firm_id, filterFirm);
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

    var index_of_stock = function(stock, exists) {
	var index = diablo_invalid_index;;
	for (var i=0, l=exists.length; i<l; i++) {
	    if (stock.style_number === exists[i].style_number && stock.brand_id === exists[i].brand) {
		index = i;
		break;
	    }
	} 
	return index;
    };

    var index_of_stock_detail = function(existDetails, detail) {
	var index = diablo_invalid_index;
	for (var j=0, k=existDetails.length; j<k; j++) {
	    if (detail.cid === existDetails[j].cid && detail.size === existDetails[j].size) {
		// existDetails[j].sell_count += d.sell_count;
		index = j;
		break;
	    } 
	}

	return index;
    }

    // var get_stock_detail = function(amounts){
    // 	var sale_amounts = [];
    // 	for(var i=0, l=amounts.length; i<l; i++){
    // 	    var a = amounts[i];
    // 	    if (angular.isDefined(a.sell_count) && a.sell_count){
    // 		var new_a = {
    // 		    cid:        a.cid,
    // 		    size:       a.size, 
    // 		    sell_count: wsaleUtils.to_integer(amounts[i].sell_count)}; 
    // 		sale_amounts.push(new_a); 
    // 	    }
    // 	}; 
    // 	return sale_amounts;
    // };
    
    $scope.balance_stock = function(r) {
	// get all fix note
	var callback = function() {
	    purchaserService.print_w_inventory_fix_note({rsn:r.rsn}).then(function(result) {
    		console.log(result);
		if (result.ecode === 0) {
		    var notes = result.note; 
		    var base_pay = 0;
		    var total = 0;
		    var existStocks = [];
		    for (var i=0, l=notes.length; i<l; i++) {
			var n = notes[i];
			base_pay += diablo_price(n.tag_price, n.discount);
			var sell_total = n.db_total - n.shop_total;
			total += sell_total;
			
			var index = index_of_stock(n, existStocks);
			if (index !== diablo_invalid_index) {
			    var e = existStocks[index];
			    e.sell_total += sell_total;

			    var d = {cid:n.color_id, size:n.size, sell_count:sell_total};
			    var indexDetail = index_of_stock_detail(e.amounts, d);
			    if (diablo_invalid_index !== indexDetail) {
				e.amounts[indexDetail].sell_count += d.sell_count;
			    } else {
				e.amounts.push(d);
			    } 
			} else {
			    existStocks.push({
				style_number: n.style_number,
				brand:        n.brand_id,
				type:         n.type,
				sex:          n.sex,
				firm:         n.firm,
				season:       n.season,
				year:         n.year,
				entry:        n.entry_date,
				sell_total:   sell_total, 
				org_price:    n.org_price,
				ediscount:    n.ediscount,
				tag_price:    n.tag_price,
				discount:     n.discount,
				fprice:       0,
				rprice:       0,
				fdiscount:    0,
				rdiscount:    0,
				path:         n.path,
				free:         n.free,
				amounts:      [{cid:n.color_id, size:n.size, sell_count:sell_total}] 
			    });
			}
			
		    }; 
		    console.log(existStocks);
		    
		    var base = {
			retailer: filterSysRetailer[0].id,
			vip: false,
			
			shop: result.detail.shop_id,
			datetime: dateFilter(diablo_now_datetime(), "yyyy-MM-dd HH:mm:ss"),
			employee: result.detail.employee_id,

			base_pay: stockUtils.to_float(base_pay),
			should_pay: 0,
			total: total,
			round: diablo_yes
		    };
		    console.log(base);

		    var print = {im_print: diablo_no};

		    purchaserService.auto_balance_fix_stock(
			{stock:existStocks, base:base, print:print}
		    ).then(function(result) {
			console.log(result);
			if (result.ecode === 0) {
			    dialog.response(true, "盘点平仓", "智能平仓成功，请在销售明细中核对！！");
			} else {
			    dialog.set_error("盘点平仓", result.ecode);
			}
		    })

		    
		} else {
		    dialog.response(
			false,
			"盘点平仓",
			"平仓失败失败：获取盘点明细失败，请核对后再操作！！")
		}
	    });
	} 
	
	dialog.request(
	    "盘点平仓",
	    "智能平仓操作容量产生误差，确认要进行该操作吗！！",
	    callback, undefined, $scope);
	
    };


    // details
    $scope.rsn_detail = function(r){
	console.log(r);
	diablo_goto_page("#/inventory/inventory_rsn_detail/fix/" + r.rsn);
    }
    
};

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryFixCtrl", purchaserInventoryFixCtrlProvide);
    app.controller("purchaserInventoryImportFixCtrl", purchaserInventoryImportFixCtrlProvide);
    app.controller("purchaserInventoryFixDetailCtrl", purchaserInventoryFixDetailCtrlProvide);
});
