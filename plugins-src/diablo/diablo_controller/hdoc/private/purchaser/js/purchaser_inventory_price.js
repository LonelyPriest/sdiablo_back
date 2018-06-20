'use strict'

function purchaserInventoryPriceCtrlProvide(
    $scope, $q, $timeout, dateFilter, localStorageService, diabloPattern,
    diabloUtilsService, diabloFilter, diabloNormalFilter, purchaserService,
    user, filterBrand, filterFirm, filterEmployee, filterRegion, base){
    // console.log(user); 
    $scope.shops     = user.sortShops;
    $scope.sexs      = diablo_sex;
    $scope.seasons   = diablo_season;
    $scope.brands    = filterBrand;
    $scope.employees = filterEmployee;
    $scope.firms     = filterFirm;
    $scope.regions   = filterRegion;
    $scope.p_modes   = [{id:0, name:"价格关联"}, {id:1, name:"价格独立"}];
    $scope.s_modes   = [{id:0, name:"参与积分"}, {id:1, name:"不参与积分"}];
    $scope.u_modes   = [{id:0, name:"店铺调价"}, {id:1, name:"区域调价"}];

    $scope.pattern = {
	price: diabloPattern.positive_decimal_2,
	discount: diabloPattern.discount,
	comment: diabloPattern.comment
    };

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight(); 
    
    $scope.refresh = function(){
	$scope.h_inventories = [];
	$scope.select_history = [];
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true}); 
	$scope.has_saved = false;
	$scope.select.total = 0;
	$scope.select.datetime = $.now();
    }; 

    // focus
    $scope.focus      = {style_number:true, tag_price:false, discount:false};
    
    $scope.auto_focus = function(attr){
	console.log(attr);
	stockUtils.on_focus_attr(attr, $scope.focus)
    };
    
    $scope.on_focus_attr = function(attr, inv){
	// $scope.auto_focus(attr);
	// if ($scope.select.u_mode.id === 1){
	//     $scope.select_history = $scope.h_inventories.filter(function(h){
	// 	return h.style_number === inv.style_number
	// 	    && h.brand_id === inv.brand.id
	//     })[0];
	// }
    }
    
    /*
     * init
     */
    var now = $.now();
    
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});
    $scope.h_inventories = [];
    $scope.select = {
	shop:$scope.shops[0],
	employee: $scope.employees[0],
	region:   $scope.regions[0],
	p_mode:   $scope.p_modes[0],
	s_mode:   $scope.s_modes[0],
	u_mode:   $scope.u_modes[0],
	datetime: now
    }; 
    // console.log($scope.select);
    $scope.has_saved = false;
    var valid_shop_id = stockUtils.get_valid_shop_id(user.shopIds);
    // console.log(valid_shop_id);
    $scope.base_settings = {
	plimit : stockUtils.prompt_limit(valid_shop_id, base),
	prompt : stockUtils.typeahead(valid_shop_id, base),
	start_time : dateFilter(
	    stockUtils.start_time(valid_shop_id, base, now, dateFilter), "yyyy-MM-dd")
    };
    
    $scope.get_select_shop = function(){
	if ($scope.select.u_mode.id === 0)
	    return $scope.select.shop.id;
	else if ($scope.select.u_mode.id === 1)
	    return $scope.shops.filter(function(s){
		return s.region === $scope.select.region.id;
	    }).map(function(s){return s.id});
    };

    $scope.match_stock_by_shop = function($viewValue){
	// if ($viewValue.length < 2) return;
	return diabloFilter.match_stock_backend_by_shop(
	    $scope.get_select_shop(), $scope.base_settings.start_time, $viewValue);
    };
    
    // $scope.match_style_number = function(viewValue){
    // 	return diabloFilter.match_w_fix(viewValue, $scope.select.shop.id);
    // }
    
    $scope.get_all_prompt_inventory = function(){
	diabloNormalFilter.match_all_w_inventory(
	    {shop:$scope.get_select_shop(),
	     start_time:$scope.base_settings.start_time}
	).$promise.then(function(invs){
	    $scope.all_w_inventory = 
		invs.map(function(inv){
		    var p = stockUtils.prompt_name(inv.style_number, inv.brand, inv.type); 
		    return angular.extend(inv, {name:p.name, prompt:p.prompt}); 
		})
	}); 
    };

    $scope.fronted_prompt_inventory = function(){
	if ($scope.base_settings.prompt === diablo_frontend){
	    $scope.get_all_prompt_inventory();
	}
    };
    
    $scope.change_mode = function(){
	// console.log($scope.select.u_mode);
	$scope.refresh();
	$scope.fronted_prompt_inventory();
    };

    $scope.change_shop = function(){
	$scope.refresh();
	$scope.fronted_prompt_inventory();
    };

    $scope.change_region = function(){
	$scope.refresh();
	$scope.fronted_prompt_inventory();
    };


    $scope.fronted_prompt_inventory();
    
    $scope.on_select_good = function(item, model, label){
	console.log(item); 
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		diabloUtilsService.response_with_callback(
		    false, "库存调价", "调价失败：" + purchaserService.error[2099],
		    $scope, function(){ $scope.inventories[0] = {$edit:false, $new:true}});
		return;
	    }
	};

	// add at first allways 
	var add = $scope.inventories[0];

	add.id           = item.id;
	add.style_number = item.style_number;
	add.brand        = item.brand;
	add.brand_id     = item.brand_id;
	add.type         = item.type;
	add.type_id      = item.type_id;
	add.firm         = diablo_get_object(item.firm_id, $scope.firms);
	add.firm_id      = item.firm_id;

	// add.s_group      = item.s_group;
	// add.free         = item.free;
	add.sex          = item.sex;
	add.year         = item.year;
	add.season       = item.season;

	add.total        = item.total;
	add.org_price    = item.org_price;
	add.tag_price    = item.tag_price;
	add.ediscount    = item.ediscount;
	add.discount     = item.discount;
	add.path         = item.path;

	add.n_discount   = item.discount;
	add.n_tag_price  = diablo_price(item.tag_price, item.discount); 

	$scope.auto_focus("tag_price");

	if ($scope.select.u_mode.id === 1){
	    // flow
	    var filter_history = $scope.h_inventories.filter(function(h){
		return h.style_number === add.style_number
		    && h.brand_id === add.brand.id
	    });

	    // console.log($scope.old_select.datetime.getTime());
	    if (filter_history.length === 0){
		purchaserService.list_w_inventory_info({
		    style_number:add.style_number,
		    brand:add.brand_id,
		    shop:$scope.get_select_shop(),
		    start_time: $scope.base_settings.start_time
		}).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			var history = angular.copy(result.data);
			angular.forEach(history, function(h){
			    h.brand = diablo_get_object(h.brand_id, $scope.brands);
			    h.firm  = diablo_get_object(h.firm_id, $scope.firms);
			    h.shop  = diablo_get_object(h.shop_id, $scope.shops);
			});

			$scope.select_history = {style_number:add.style_number,
						 brand_id:    add.brand_id,
						 history: history};
			
			$scope.h_inventories.push($scope.select_history); 
			// console.log($scope.h_inventories); 
		    }
		}) 
	    } else {
		$scope.select_history = filter_history[0];
	    }
	}
	
	return;
    };

    var sDraft = new stockDraft(localStorageService,
				undefined,
				$scope.select.shop.id,
				$scope.select.employee.id,
				diablo_dkey_stock_price);
    
    $scope.disable_draft = function(){
	if (sDraft.keys().length === 0) return true; 
	if ($scope.inventories.length !== 1) return true; 
	return false;
    };

    $scope.list_draft = function(){
	var draft_filter = function(keys){
	    return keys.map(function(k){
		var p = k.split("-");
		return {sn:k,
			employee:diablo_get_object(p[2], $scope.employees),
			shop:diablo_get_object(parseInt(p[1]), $scope.shops)}
	    });
	};

	var select = function(draft, resource){
	    $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
	    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops);
	    $scope.inventories = angular.copy(resource);
	    $scope.inventories.unshift({$edit:false, $new:true}); 
	    re_calculate(); 
	};

	sDraft.select(diabloUtilsService, "wfix-draft.html", draft_filter, select); 
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved) return true; 
	if ($scope.inventories.length === 1) return true; 
	return false;
    }; 
    
    $scope.save_inventory = function(){
	$scope.has_saved = true
	// console.log($scope.inventories);
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i]; 
	    added.push({
		style_number    : add.style_number,
		brand           : add.brand_id,
		org_price       : add.org_price,
		tag_price       : add.n_tag_price,
		discount        : add.n_discount
	    })
	}; 

	var base = {
	    shop:             $scope.get_select_shop(),
	    date:             dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:         $scope.select.employee.id ,
	    smode:            $scope.select.s_mode.id,
	    pmode:            $scope.select.p_mode.id
	};

	console.log(added);
	console.log(base);
	// return;

	// $scope.has_saved = true
	purchaserService.adjust_price({
	    inventory: added.length === 0 ? undefined : added, base: base
	}).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
	    	diabloUtilsService.response_with_callback(
	    	    true, "库存调价", "库存调价成功！！", undefined, function(){sDraft.remove()})
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "库存调价",
	    	    "调价失败：" + purchaserService.error[state.ecode],
		    $scope, function(){$scope.has_saved = false});
	    }
	})
    }; 
    
    var re_calculate = function(){
	$scope.select.total = $scope.inventories.length - 1; 
    }; 
    
    $scope.timeout_auto_save = undefined; 
    $scope.add_inventory = function(inv, direct){
	$timeout.cancel($scope.timeout_auto_save);
	if ($scope.select.p_mode.id === 0){
	    if (0 === direct){
		if ( 0 === stockUtils.to_float(inv.n_tag_price)
		     || inv.n_tag_price === inv.tag_price) {
		    inv.n_discount = inv.discount;
		    return
		}; 
		inv.n_discount = diablo_discount(inv.n_tag_price, inv.tag_price);
	    } else if (1 === direct){
		if (0 === stockUtils.to_float(inv.n_discount)
		    || inv.n_discount === inv.discount) {
		    inv.n_tag_price = inv.tag_price;
		    return;
		};
		inv.n_tag_price = diablo_price(inv.tag_price, inv.n_discount);
	    }
	} else {
	    if (0 === stockUtils.to_float(inv.n_tag_price)) return;
	    inv.ediscount = stockUtils.ediscount(inv.org_price, inv.n_tag_price);
	}
	
	if (angular.isUndefined(inv.order_id)){
	    $scope.timeout_auto_save = $timeout(function(){
		console.log(inv.n_tag_price, inv.n_discount);
		inv.$new = false; 
		inv.order_id = $scope.inventories.length; 
		// add new line
		$scope.inventories.unshift({$edit:false, $new:true});
		re_calculate();
		
		sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
		
		$scope.auto_focus("style_number");
		$timeout.cancel($scope.timeout_auto_save);
	    }, 1000); 
	} 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory = function(inv){
	console.log(inv);
	
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if(inv.order_id === $scope.inventories[i].order_id){
		break;
	    }
	}

	$scope.inventories.splice(i, 1);
	
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}
	
	sDraft.save($scope.inventories.filter(function(r){return !r.$new}));
	re_calculate();
	
    }; 
};

function stockNewDetailPrintCtrlProvide(
    $scope, $routeParams, diabloUtilsService, purchaserService,
    filterBrand, filterFirm, filterType, filterColor, filterEmployee, user, base){
    // console.log($routeParams);
    // $scope.rsn = $routeParams.rsn;

    $scope.shops = user.sortShops; 
    // console.log($scope.shops);

    var LODOP;
    if (needCLodop()) loadCLodop(); 
    var dialog = diabloUtilsService;

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);
    $scope.rbill_comment  = diablo_base_setting("rbill", diablo_default_shop, base, diablo_set_string, "");
    // console.log(base);
    // console.log($scope.rbill_comment);
    
    purchaserService.print_w_inventory_new($routeParams.rsn).then(function(result) {
    	// console.log(result);
	if (result.ecode === 0) {
	    $scope.detail = result.detail;
	    $scope.detail.shop = diablo_get_object($scope.detail.shop_id, $scope.shops);
	    $scope.detail.employee = diablo_get_object($scope.detail.employee_id, filterEmployee);
	    $scope.detail.firm = diablo_get_object($scope.detail.firm_id, filterFirm);
	    
	    $scope.notes = [];
	    $scope.total  = 0;
	    $scope.amount = 0;

	    var order_id = 1;
	    angular.forEach(result.note, function(n) {
		n.brand = diablo_get_object(n.brand_id, filterBrand);
		n.type  = diablo_get_object(n.type_id, filterType);
		n.order_id = order_id; 
		$scope.notes.push(n);
		$scope.total += n.total;
		
		for (var i=0, l=n.note.length; i<l; i++) {
		    var s = n.note[i];
		    $scope.amount += s.total;
		    $scope.notes.push({
			amount: s.total,
			color:  diablo_find_color(s.color_id, filterColor),
			size:   s.size
		    });
		}

		order_id++; 
	    });

	    // console.log($scope.notes);
	    
	} else {
	    dialog.response(
		false,
		"采购单打印",
		"采购单打印失败：获取采购单失败，请核对后再打印！！")
	}
    });

    // var css = "<style>table { border-splice:0; border-collapse:collapse }</style>"
    // var strBodyStyle="<style>table,td { border: 1 solid #000000;border-collapse:collapse }</style>"; 
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
	    LODOP.PRINT_INIT("task_print_stock_new");
	    LODOP.SET_PRINTER_INDEX(stockUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	    LODOP.ADD_PRINT_HTM(
		"5%", "5%",  "90%", "BottomMargin:15mm",
		strBodyStyle + "<body>" + document.getElementById("stock_new").innerHTML + "</body>");
	    LODOP.PREVIEW(); 
	}
    };

    $scope.go_back = function() {
	diablo_goto_page("#/inventory_new_detail");
    };
    
};


function stockNewNotePrintCtrlProvide(
    $scope, $routeParams, diabloUtilsService, purchaserService,
    filterBrand, filterFirm, filterType, user, base){
    // console.log($routeParams); 
    $scope.shops = user.sortShops;
    $scope.search = angular.fromJson($routeParams.note);
    console.log($scope.search);
    // console.log($scope.shops);

    var LODOP;
    if (needCLodop()) loadCLodop(); 
    var dialog = diabloUtilsService;

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);
    $scope.rbill_comment  = diablo_base_setting("rbill", diablo_default_shop, base, diablo_set_string, "");
    // console.log(pageHeight, pageWidth);
    // console.log($scope.rbill_comment); 
    var notes = []; 
    purchaserService.print_w_inventory_new_note($scope.search).then(function(result) {
    	console.log(result);
	if (result.ecode === 0) {
	    angular.forEach(result.data, function(d) {
		var notes_of_shop = [];
		angular.forEach($scope.shops, function(s) {
		    notes_of_shop.push({shop_id: s.id, shop:s.name, total: 0, note: []});
		});
		// console.log(notes_of_shop); 
		angular.forEach(d.note, function(n) {
		    for (var i=0, l=notes_of_shop.length; i<l; i++) {
			if (n.shop_id === notes_of_shop[i].shop_id){
			    notes_of_shop[i].note.push(n)
			    notes_of_shop[i].total += n.total;
			}
		    }
		});

		notes.push({fid:d.fid, firm:d.firm, addr:d.addr, ns: notes_of_shop});
		
	    }); 

	    // console.log(notes);
	    $scope.notes = [];
	    for (var i=0, l=notes.length; i<l; i++) {
		var total = 0;
		var ns = notes[i].ns.filter(function(n) {
		    diablo_order(n.note);
		    total += n.total;
		    return n.note.length !== 0
		});

		// diablo_order(ns); 
		$scope.notes.push({
		    fid: notes[i].fid,
		    firm:notes[i].firm,
		    addr:notes[i].addr,
		    total:total, ns:ns});
	    }

	    diablo_order($scope.notes);
	    console.log($scope.notes);
	    
	} else {
	    dialog.response(
		false,
		"采购单打印",
		"采购单打印失败：获取采购单失败，请核对后再打印！！")
	}
    });

    // var css = "<style>table { border-splice:0; border-collapse:collapse }</style>"
    // var strBodyStyle="<style>table,td { border: 1 solid #000000;border-collapse:collapse }</style>"; 
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
	    LODOP.PRINT_INIT("task_print_stock_new");
	    LODOP.SET_PRINTER_INDEX(stockUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);

	    angular.forEach($scope.notes, function(n) {
		LODOP.NEWPAGEA(); 
		LODOP.ADD_PRINT_HTM(
		    "5%", "5%",  "90%", "BottomMargin:15mm",
		    strBodyStyle
			+ "<body>"
			+ document.getElementById(n.fid.toString()).innerHTML
			+ "</body>"); 
	    })

	    LODOP.PREVIEW(); 
	}
    };

    $scope.go_back = function() {
	diablo_goto_page("#/inventory_rsn_detail");
    };
    
};

function stockTransferPrintCtrlProvide(
    $scope, $routeParams, diabloUtilsService, purchaserService,
    filterBrand, filterShop, filterType, filterColor, filterEmployee, user, base){
    // console.log($routeParams);
    // $scope.rsn = $routeParams.rsn;

    $scope.shops = filterShop; 
    // console.log($scope.shops);

    var LODOP;
    if (needCLodop()) loadCLodop(); 
    var dialog = diabloUtilsService;

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);
    // console.log(pageHeight, pageWidth);
    
    purchaserService.print_w_inventory_transfer($routeParams.rsn).then(function(result) {
    	// console.log(result);
	if (result.ecode === 0) {
	    $scope.detail = result.detail;
	    $scope.detail.fshop = diablo_get_object($scope.detail.fshop_id, $scope.shops);
	    $scope.detail.tshop = diablo_get_object($scope.detail.tshop_id, $scope.shops);
	    $scope.detail.employee = diablo_get_object($scope.detail.employee_id, filterEmployee);
	    
	    $scope.notes = [];
	    $scope.total  = 0;
	    $scope.amount = 0;
	    
	    var order_id = 1;
	    angular.forEach(result.note, function(n) {
		n.brand = diablo_get_object(n.brand_id, filterBrand);
		n.type  = diablo_get_object(n.type_id, filterType);
		n.order_id = order_id; 
		$scope.notes.push(n);
		$scope.total += n.total;
		
		for (var i=0, l=n.note.length; i<l; i++) {
		    var s = n.note[i];
		    $scope.amount += s.total;
		    $scope.notes.push({
			amount: s.total,
			color:  diablo_find_color(s.color_id, filterColor),
			size:   s.size
		    });
		}

		order_id++; 
	    });

	    // console.log($scope.notes);
	    
	} else {
	    dialog.response(
		false,
		"调出单打印",
		"调出单单打印失败：获取调出单失败，请核对后再打印！！")
	}
    });

    // var css = "<style>table { border-splice:0; border-collapse:collapse }</style>"
    // var strBodyStyle="<style>table,td { border: 1 solid #000000;border-collapse:collapse }</style>"; 
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

	if (LODOP.VERSION) {
	    LODOP.PRINT_INIT("task_print_stock_transfer");
	    LODOP.SET_PRINTER_INDEX(stockUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	    // LODOP.SET_PRINT_PAGESIZE(1, 0, 0,"A4");
	    LODOP.ADD_PRINT_HTM(
		"5%", "5%",  "90%", "BottomMargin:15mm",
		strBodyStyle
		    + "<body>"
		    + document.getElementById("stock_transfer").innerHTML
		    + "</body>");
	    LODOP.PREVIEW();
	}
    };

    $scope.go_back = function() {
	diablo_goto_page("#/inventory/inventory_transfer_from_detail");
    };
    
};

define(["purchaserApp"], function(app){
    app.controller("purchaserInventoryPriceCtrl", purchaserInventoryPriceCtrlProvide);
    app.controller("stockNewDetailPrintCtrl", stockNewDetailPrintCtrlProvide);
    app.controller("stockTransferPrintCtrl", stockTransferPrintCtrlProvide);
    app.controller("stockNewNotePrintCtrl", stockNewNotePrintCtrlProvide);
});
