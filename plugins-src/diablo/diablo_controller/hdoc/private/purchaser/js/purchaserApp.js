"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage", "angular-file-upload",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], stockConfg);

function stockConfg(angular){
    var purchaserApp = angular.module(
	'purchaserApp',
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule', 'angularFileUpload',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('purchaserApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
    }).config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    }).run(['$route', '$rootScope', '$location', function ($route, $rootScope, $location) {
	var original = $location.path;
	$location.path = function (path, reload) {
	    if (reload === false) {
		var lastRoute = $route.current;
		var un = $rootScope.$on(
		    '$locationChangeSuccess',
		    function () {
			$route.current = lastRoute;
			un();
		    });
	    }
	    return original.apply($location, [path]);
	}; 
    }]);
    
    purchaserApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
	    return userService()}}; 

	var brand = {"filterBrand": function(diabloFilter){
	    return diabloFilter.get_brand()}};
	
	var firm = {"filterFirm": function(diabloFilter){
    	    return diabloFilter.get_firm()}};
	
	var type = {"filterType": function(diabloFilter){
	    return diabloFilter.get_type()}};

	var employee = {"filterEmployee": function(diabloFilter){
	    return diabloFilter.get_employee()}};

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}};

	var promotion = {"filterPromotion": function(diabloFilter){
	    return diabloFilter.get_promotion()}};
	
	var commision = {"filterCommision": function(diabloFilter){
	    return diabloFilter.get_commision()}};

	var score = {"filterScore": function(diabloNormalFilter){
	    return diabloNormalFilter.get_score()}};

	var color_type = {"filterColorType": function(diabloFilter){
            return diabloFilter.get_color_type()}};
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}};

	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var shop = {"filterShop": function(diabloNormalFilter){
            return diabloNormalFilter.get_shop()}};

	var region = {"filterRegion": function(diabloNormalFilter){
	    return diabloNormalFilter.get_region()}};

	var std_executive = {"filterStdExecutive":function(diabloFilter) {
	    return diabloFilter.list_good_std_executive()}};

	var safety_category = {"filterCategory":function(diabloFilter) {
	    return diabloFilter.list_good_safety_category()}};

	var fabric = {"filterFabric":function(diabloFilter) {
	    return diabloFilter.list_good_fabric()}};

	var ptemplate = {"filterTemplate":function(diabloFilter) {
	    return diabloFilter.list_print_template()}};

	var ctype = {"filterCType": function(diabloFilter) {
	    return diabloFilter.list_good_ctype()}};

	var size_spec = {"filterSizeSpec": function(diabloFilter) {
	    return diabloFilter.list_good_size_spec()}};

	var sysretailer = {"filterSysRetailer": function(diabloFilter){
    	    return diabloFilter.get_sys_wretailer()}};
	
	$routeProvider.
	    // new
	    when('/inventory_new', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_new.html',
		controller: 'purchaserInventoryNewCtrl',
		resolve: angular.extend(
		    {}, user, brand, type, s_group, firm, employee, color, color_type,
		    std_executive, safety_category, fabric, base)
	    }).
	    when('/update_new_detail/:rsn?/:ppage?/:from?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail_update.html',
		controller: 'purchaserInventoryNewUpdateCtrl',
		resolve: angular.extend(
		    {}, user, brand, firm, type, employee, s_group, color,
		    std_executive, safety_category, fabric, size_spec, ptemplate, base)
	    }).
	    // reject
	    when('/inventory_reject', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_reject.html',
		controller: 'purchaserInventoryRejectCtrl',
		resolve: angular.extend(
		    {}, user, firm, employee, s_group, color, base)
	    }). 
	    when('/update_new_detail_reject/:rsn?/:ppage?/:from?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_reject_update.html',
		controller: 'purchaserInventoryRejectUpdateCtrl',
		resolve: angular.extend(
		    {}, user, brand, firm, type, employee, s_group, color, base)
	    }).
	    // detail
	    when('/inventory_rsn_detail/:rsn?/:ppage?/:from?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_new_rsn_detail.html',
		controller: 'purchaserInventoryNewRsnDetailCtrl',
		resolve: angular.extend(
		    {}, user, brand, firm, type, employee, s_group, color, ptemplate, region, base)
	    }).
	    when('/inventory_new_detail/:page?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail.html',
		controller: 'purchaserInventoryNewDetailCtrl',
		resolve: angular.extend({}, user, firm, employee, brand, region, base)
	    }). 
	    when('/inventory_detail/:rsn?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_detail.html',
		controller: 'purchaserInventoryDetailCtrl' ,
		resolve: angular.extend(
		    {}, promotion, commision, score,
		    brand, firm, type, ctype, s_group, color,
		    size_spec, std_executive, safety_category, fabric, ptemplate , region, base, user)
	    }).
	    when('/inventory_history', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_history.html',
		controller: 'purchaserInventoryHistoryCtrl' ,
		resolve: angular.extend({}, shop, user)
	    }).
	    when('/inventory_detail/inventory_flow/:snumber?/:brand?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_flow.html',
		controller: 'purchaserInventoryFlowCtrl' ,
		resolve: angular.extend({}, user, brand, firm, base)
	    }).
	    when('/inventory_new_history/:snumber?/:brand?/:rsn?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_new_history.html',
		controller: 'stockHistoryCtrl' ,
		resolve: angular.extend({}, user, brand, firm, base)
	    }). 
	    // fix
	    when('/inventory/inventory_fix', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_fix.html',
		controller: 'purchaserInventoryFixCtrl' ,
		resolve: angular.extend({}, user, employee, s_group, color, firm, base)
	    }).
	    when('/inventory/inventory_import_fix', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_import_fix.html',
		controller: 'purchaserInventoryImportFixCtrl' ,
		resolve: angular.extend({}, user, employee, base)
	    }).
	    when('/inventory/inventory_fix_detail', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_fix_detail.html',
		controller: 'purchaserInventoryFixDetailCtrl' ,
		resolve: angular.extend({}, sysretailer, user, employee, firm, base) 
	    }).
	    when('/inventory/inventory_rsn_detail/fix/:rsn?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_fix_rsn_detail.html',
		controller: 'purchaserInventoryFixRsnDetailCtrl',
		resolve: angular.extend({}, user, brand, s_group, color, base)
	    }).
	    // print
	    when('/print_inventory_new/:rsn', {
		templateUrl: '/private/purchaser/html/stock_new_detail_print.html',
		controller: 'stockNewDetailPrintCtrl' ,
		resolve: angular.extend({}, brand, firm, type, color, employee, user, base)
	    }).
	    when('/print_inventory_transfer/:rsn', {
		templateUrl: '/private/purchaser/html/stock_transfer_print.html',
		controller: 'stockTransferPrintCtrl' ,
		resolve: angular.extend({}, brand, shop, type, color, employee, user, base)
	    }).
	    when('/print_inventory_new_note/:note', {
		templateUrl: '/private/purchaser/html/stock_new_note_print.html',
		controller: 'stockNewNotePrintCtrl' ,
		resolve: angular.extend({}, brand, firm, type, user, base)
	    }).
	    when('/print_inventory_fix_note/:note', {
		templateUrl: '/private/purchaser/html/stock_fix_note_print.html',
		controller: 'stockFixNotePrintCtrl' ,
		resolve: angular.extend({}, brand, user, base)
	    }). 
	    // wgood
	    when('/good/size', {
		templateUrl: '/private/wgood/html/wgood_size.html',
		controller: 'wgoodSizeDetailCtrl',
		resolve: angular.extend({}, s_group, base)
	    }).
	    when('/good/color', {
		templateUrl: '/private/wgood/html/wgood_color.html',
		controller: 'wgoodColorDetailCtrl',
		resolve: angular.extend({}, color_type, color, base)
	    }).
	    when('/good/type', {
		templateUrl: '/private/wgood/html/wgood_type.html',
		controller: 'wgoodTypeDetailCtrl',
		resolve: angular.extend({}, type, ctype, base)
	    }).
	    when('/good/wgood_new', {
		templateUrl: '/private/wgood/html/wgood_new.html',
		controller: 'wgoodNewCtrl',
		resolve: angular.extend(
		    {},
		    promotion,
		    firm,
		    brand,
		    type,
		    s_group, std_executive, safety_category, fabric, ptemplate, user, base)
	    }).
	    when('/good/wgood_update/:id?/:shop?/:from?', {
		templateUrl: '/private/wgood/html/wgood_update.html',
		controller: 'wgoodUpdateCtrl',
		resolve: angular.extend(
		    {},
		    promotion,
		    brand,
		    firm,
		    type,
		    color,
		    s_group,
		    std_executive, safety_category, fabric, ptemplate, base, user)
	    }).
	    when('/good/wgood_detail', {
		templateUrl: '/private/wgood/html/wgood_detail.html',
		controller: 'wgoodDetailCtrl',
		resolve: angular.extend(
		    {},
		    promotion,
		    brand,
		    firm,
		    type,
		    color,
		    size_spec,
		    std_executive, safety_category, fabric, ptemplate, base, user) 
	    }).
	    // promotion
	    when('/promotion/promotion_new', {
		templateUrl: '/private/purchaser/html/purchaser_promotion_new.html',
		controller: 'stockPromotionNew'
		// resolve: angular.extend({}, user) 
	    }).
	    when('/promotion/promotion_detail', {
		templateUrl: '/private/purchaser/html/purchaser_promotion_detail.html',
		controller: 'stockPromotionDetail' ,
		resolve: angular.extend({}, user) 
	    }).
	    // commision
	    when('/promotion/commision_detail', {
		templateUrl: '/private/purchaser/html/stock_commision_detail.html',
		controller: 'stockCommisionDetail' ,
		resolve: angular.extend({}, user) 
	    }).
	    //transfer
            when('/inventory/inventory_transfer', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_transfer.html',
		controller: 'purchaserInventoryTransferCtrl',
		resolve: angular.extend({}, user, shop, firm, employee, s_group, color, base)
            }).
            when('/inventory/inventory_transfer_to_detail', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_transfer_to_detail.html',
		controller: 'purchaserInventoryTransferToDetailCtrl' ,
	        resolve: angular.extend({}, user, shop, employee, base)
            }).
	    when('/inventory/inventory_transfer_from_detail', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_transfer_from_detail.html',
		controller: 'purchaserInventoryTransferFromDetailCtrl' ,
		resolve: angular.extend({}, user, shop, employee, base)
	    }).
            when('/inventory/inventory_rsn_detail/transfer_to/:rsn?', {
	        templateUrl: '/private/purchaser/html/purchaser_inventory_transfer_to_rsn_detail.html',
		controller: 'purchaserInventoryTransferToRsnDetailCtrl',
		resolve: angular.extend({}, user, shop, brand, type, firm, s_group, color, base)
	    }).
	    when('/inventory/inventory_rsn_detail/transfer_from/:rsn?', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_transfer_from_rsn_detail.html',
	        controller: 'purchaserInventoryTransferFromRsnDetailCtrl',
		resolve: angular.extend(
		    {}, user, shop, brand, type, firm, s_group, color,
		    std_executive, safety_category, fabric, size_spec, ptemplate, base)
            }).
	    // order
	    when('/order/new_order', {
	    	templateUrl: '/private/purchaser/html/purchaser_inventory_order.html',
	    	controller: 'purchaserOrderNewCtrl',
	    	resolve: angular.extend(
	    	    {}, user, brand, type, s_group, firm, employee, color, color_type,
	    	    std_executive, safety_category, fabric, base)
	    }).
	    when('/order_detail', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_order_detail.html',
		controller: 'purchaserInventoryOrderDetailCtrl',
		resolve: angular.extend(
		    {}, user, brand, firm, type, employee, s_group, color, base)
	    }).
	    
	    // when('/order/update_order', {
	    // 	templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail_update.html',
	    // 	controller: 'purchaserInventoryNewUpdateCtrl',
	    // 	resolve: angular.extend(
	    // 	    {}, user, brand, firm, type, employee, s_group, color,
	    // 	    std_executive, safety_category, fabric, size_spec, ptemplate, base)
	    // }).
	    // adjust price
	    when('/inventory_price', {
		templateUrl: '/private/purchaser/html/purchaser_inventory_price.html',
		controller: 'purchaserInventoryPriceCtrl',
		resolve: angular.extend({}, user, brand, firm, employee, region, base)
            }).
	    // default
	    otherwise({
		templateUrl: '/private/purchaser/html/purchaser_inventory_new_detail.html',
		controller: 'purchaserInventoryNewDetailCtrl' ,
		resolve: angular.extend({}, user, firm, employee, brand, region, base)
            })
    }]);


    purchaserApp.service("purchaserService", function($resource, dateFilter){
	// error information
	this.error = {
	    2001: "货品资料已存在！！",
	    2002: "该促销方案已存在，请检查后重新输入！！",
	    2003: "获取入库记录失败，请检查该入库记录！！",
	    2004: "该入库记录已废弃，请选择其它入库记录！！",
	    2005: "该单已废弃或属于结帐单，无法进行审核操作！！",
	    2006: "该单已审核，请选择其它单据！！",
	    2007: "该单己废弃，请选择其它单据！！",
	    2008: "厂商累计欠款不正确，请核对该厂商欠款！！",
	    2009: "该单存在进价为零的货品或厂商为空，无法审核，请填写进价后再审核！！",
	    2010: "系统时间与服务器时间超过2小时，请检查系统日期或重新选择日期后再进行操作！！",
	    2011: "款号未知，请重新输入款号！！",
	    2012: "采购/退货总数与明细总数不一致，请核对该退货单后再进行操作！！",
	    2013: "该单无厂商，无法审核，请填写厂商后再审核！！",
	    2014: "该货品不存在，请重新选择货品！！",
	    2015: "条码值已使用，请重试！！",
	    2016: "服务器条码校验失败，请注销当前用户后再操作！！",
	    2017: "该货品无条码值，请先重置该货品条码值后再打印！！",
	    2019: "厂商为空的情况下，不允许修改入库时间，请先填写厂商！！",
	    2021: "库存不足，请检查库存后再操作！！",
	    2060: "面料输入不正确，请确保面料从下拉框中选择，面料成份不为零！！",
	    2073: "自定义条码不支持非标准国际条码，请重新输入！！",
	    2074: "非均色均码不支持自定义条码输入！！", 
	    2075: "条码生成失败，请重新操作！！", 
	    2076: "非法条码，条码长度不小于9，请输入正确的条码值！！",
	    2077: "导入的文件数量不能超过了2个！！", 
	    2078: "无法单独修改积分方案，请关联修改吊牌价或折扣！！",
	    2079: "该系统模式下，不能重置条码，请在货品详情中重置条码值！！",
	    2081: "条码值为空，无法重置该条码，请先生成该货品条码后再操作！！",
	    2082: "盘点草稿获取失败，请检查盘点文件内容并确保该文件可读！！",
	    2083: "盘点草稿不存在或为空，请检查C盘目录下的盘点文件！！",
	    2084: "盘点库存为空，请重新选择库存！！",
	    2085: "该条码对应的库存不存在，请确认厂商或条码是否正确，或通过款号模式盘点！！",
	    2086: "该货品无厂商信息，无法生成条码，请填写厂商信息后再重新操作！！",
	    2087: "请选择需要打印条码的库存！！",
	    2088: "该货品无进货价，请核对该货品进货价后再移仓！！",
	    2089: "该货品无厂商信息，请填写厂商后再进行移仓！！",
	    2090: "已废弃单据，无法修改！！",
	    2091: "厂商不能为空，该单无厂商，需审核后再进行退货操作！！",
	    2092: "空白款号，请重新选择款号！！",
	    2093: "厂商信息不一致，请重新选择货品！！", 
	    2094: "修改前后信息一致，请重新编辑修改项！！", 
	    2095: "请先选择厂商！！",
	    2096: "客户，营业员或店铺为空，请先建立客户，营业员或店铺资料！！",
	    2097: "该货品在店铺中不存在，请选择另外的货品或店铺！！",
	    2098: "该货品库存为0，无法退货，请选择另外的货品！！",
	    2099: "该货号已存在，请选择新的货号！！",
	    2701: "文件导出失败，请重试或联系服务人员查找原因！！",
	    2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	this.purchaser_type =  [{name:"采购开单", id:0},{name:"采购退货", id:1}]; 
	this.check_state = [{name:"未审核", id:0},	{name:"已审核", id:1}];

	this.extra_pay_types = [
	    {id:0, name: "代付运费"},
	    {id:1, name: "样衣"},
	    {id:2, name: "少配饰"},
	];

	this.promotion_rules = [
	    {name: "折扣优惠", id:0, remark: "打折优惠"},
	    {name: "金额减免", id:1, remakr: "交易金额达到目标值减免一定金额"},
	    {name: "买M送N",   id:2, remakr: "同一类型的产品买M年送N件"},
	    {name: "M件N折",   id:3, remakr: "一件8折二件7折"},
	    {name: "M件减N",   id:4, remakr: "一件少50二件少100"},
	    {name: "M件N钱",   id:5, remakr: "一件100二件80"},
	]; 

	this.promotion_prules = [
	    {id:0, name: "针对折后价促销"},
	    {id:1, name: "针对吊牌价促销"}
	];

	this.commision_rules = [
	    {id:0, name: "按商品定额提成"},
	    {id:1, name: "按商品售价百分比提成"}
	];
	
	this.export_type = {trans:0, trans_note:1, stock:2, shift:3, shift_note:4};

	this.get_inventory_from_sort = function(cid, size, sorts){
	    for(var i=0, l=sorts.length; i<l; i++){
		if (sorts[i].cid === cid && sorts[i].size === size){
		    return sorts[i];
		}
	    }
	    return undefined;
	}; 
	
	// =========================================================================
	var http = $resource(
	    "/purchaser/:operation/:id",
    	    {operation: '@operation', id: '@id'},
	    {
		get_inventory_group: {method: 'POST', isArray: true},
		get_inventory: {method: 'POST', isArray: true},
		print_new_note: {method: 'POST', isArray: true}
	    }); 
	
	/*
	 * new
	 */
	this.add_purchaser_inventory = function(inventory, base){
	    return http.save({operation: "new_w_inventory"}, inventory).$promise;
	};

	this.update_w_inventory_new = function(inventory, base){
	    return http.save({operation: "update_w_inventory"}, inventory).$promise;
	};

	this.check_w_inventory_new = function(rsn, check_firm, check_price){
	    return http.save({operation: "check_w_inventory"},
			     {rsn:   rsn,
			      mode:  diablo_check,
			      firm:  check_firm,
			      price: check_price}).$promise;
	};

	this.uncheck_w_inventory_new = function(rsn){
	    return http.save({operation: "check_w_inventory"},
			     {rsn:  rsn,
			      mode: diablo_uncheck}).$promise;
	};

	this.delete_w_inventory_new = function(rsn, mode){
	    return http.save({operation: "del_w_inventory"},
			     {rsn: rsn,
			      mode: mode}).$promise;
	};
	
	this.filter_purchaser_inventory_group = function(
	    mode, match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_inventory_group"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.list_purchaser_inventory = function(condition){
    	    return http.get_inventory(
    		{operation: "list_w_inventory"}, condition).$promise;
	};

	this.list_w_inventory_info = function(condition){
    	    return http.save(
    		{operation: "list_w_inventory_info"}, condition).$promise;
	};

	this.get_purchaser_tagprice = function(condition){
	    return http.save(
		{operation: "get_w_inventory_tagprice"}, condition).$promise;
	};

	this.get_w_invnetory_new = function(RSN){
    	    return http.get({operation: "get_w_inventory_new", id: RSN}).$promise;
	};

	this.get_w_invnetory_new_amount = function(condition){
    	    return http.save(
		{operation: "get_w_inventory_new_amount"}, condition).$promise;
	};

	this.filter_w_inventory_new = function(
	    match, fields, currentPage, itemsPerpage
	){
	    return http.save(
		{operation: "filter_w_inventory_new"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_w_inventory_new_rsn_group = function(
	    match, fields, currentPage, itemsPerpage
	){
	    return http.save(
		{operation: "filter_w_inventory_new_rsn_group"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_inventory_new_rsn_detail = function(inv){
	    return http.save(
		{operation: "w_inventory_new_rsn_detail"},
		{rsn:inv.rsn,
		 style_number:inv.style_number,
		 brand:inv.brand}).$promise;
	};

	/*
	 * order
	 */
	this.add_purchaser_order = function(inventory, base){
	    return http.save({operation: "new_stock_order"}, inventory).$promise;
	};

	/*
	 * reject
	 */
	this.reject_purchaser_inventory = function(inventory){
	    return http.save(
		{operation: "reject_w_inventory"}, inventory).$promise;
	}
	
	this.filter_w_inventory_reject = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_inventory_reject"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_w_inventory_reject_rsn_group = function(
	    match, fields, currentPage, itemsPerpage
	){
	    return http.save(
		{operation: "filter_w_inventory_reject_rsn_group"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_invnetory_reject_rsn_detail = function(inv){
	    return http.save(
		{operation: "w_inventory_reject_rsn_detail"},
		{rsn:inv.rsn,
		 style_number:inv.style_number,
		 brand:inv.brand}).$promise;
	};

	/*
	 * fix
	 */
	this.fix_purchaser_inventory = function(inventory){
	    return http.save({operation: "fix_w_inventory"}, inventory).$promise;
	}

	this.filter_fix_w_inventory = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_fix_w_inventory"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_w_inventory_fix_rsn_group = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_inventory_fix_rsn_group"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_invnetory_fix_rsn_detail = function(inv){
	    return http.save(
		{operation: "w_inventory_fix_rsn_detail"},
		{rsn:inv.rsn,
		 style_number:inv.style_number,
		 brand:inv.brand}).$promise;
	};

	this.csv_export = function(e_type, condition, mode){
	    return http.save(
		{operation: "w_inventory_export"},
		{condition: condition, e_type:e_type, mode:mode}).$promise;
	};

	this.export_fix_note = function(rsn) {
	    return http.save(
		{operation: "export_w_inventory_fix_note"}, {rsn: rsn}).$promise;
	};

	// transfer
	this.transfer_purchaser_inventory = function(inventory){
            return http.save(
		{operation: "transfer_w_inventory"}, inventory).$promise;
	};

	this.filter_transfer_w_inventory = function(match, fields, currentPage, itemsPerpage){
            return http.save(
		{operation: "filter_transfer_w_inventory"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_transfer_rsn_w_inventory = function(match, fields, currentPage, itemsPerpage){
            return http.save(
		{operation: "filter_transfer_rsn_w_inventory"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_invnetory_transfer_rsn_detail = function(inv){
            return http.save(
		{operation: "w_inventory_transfer_rsn_detail"},
		{rsn:inv.rsn, style_number:inv.style_number,
		 brand:inv.brand}).$promise;
	};

	this.check_w_inventory_transfer = function(check){
            return http.save(
		{operation: "check_w_inventory_transfer"}, check).$promise;
	};

	this.cancel_w_inventory_transfer = function(rsn){
	    return http.save(
		{operation: "cancel_w_inventory_transfer"}, {rsn:rsn}).$promise;
	};

	this.get_stock_by_shop = function(shop) {
	    return http.save(
		{operation: "get_stock_by_shop"}, {shop:shop}).$promise;
	};
	
	/*
	 * promotion 
	 */
	this.set_w_inventory_promotion = function(condition, promotion, score){
	    return http.save(
		{operation: "set_w_inventory_promotion"},
		{condition: condition,
		 promotion: promotion,
		 score:     score}).$promise;
	};
	
	/*
	 * update batch
	 */
	this.update_w_inventory_batch = function(match, condition, attrs){
	    return http.save(
		{operation: "update_w_inventory_batch"},
		{match: angular.isDefined(match) ? match.op : undefined,
		 condition: condition,
		 attrs: attrs}).$promise;
	};

	this.update_w_inventory_alarm = function(condition, attrs){
	    return http.save(
		{operation: "update_w_inventory_alarm"}, {condition: condition, attrs: attrs}).$promise;
	};

	this.adjust_price = function(inventory){
	    return http.save({operation: "adjust_w_inventory_price"}, inventory).$promise;
	};

	this.gift_stock = function(condition, attrs) {
	    return http.save({operation: "gift_w_stock"}, {condition:condition, attrs:attrs}).$promise;
	};

	this.offering_stock = function(condition, attrs) {
	    return http.save({operation: "offering_w_stock"}, {condition:condition, attrs:attrs}).$promise;
	};

	this.copy_stock_attr = function(style_number, brand, shop) {
	    return http.save({operation: "copy_w_stock_attr"},
			     {style_number:style_number,
			      brand:brand,
			      shop:shop}).$promise;
	};

	this.analysis_history_stock = function(condition) {
	    return http.save(
    		{operation: "analysis_history_stock"}, condition).$promise;
	};

	/*
	 * trace
	 */
	this.list_w_inventory_new_detail = function(conditions){
	    return http.save({operation: "list_w_inventory_new_detail"}, conditions).$promise;
	};

	this.list_w_inventory_flow = function(conditions){
	    return http.save({operation: "list_w_inventory_flow"}, conditions).$promise;
	};

	/*
	 * barcode
	 */
	this.syn_barcode = function(style_number, brand, shop, barcode) {
	    return http.save({operation: "syn_w_inventory_barcode"},
			     {style_number:style_number,
			      brand:brand,
			      shop:shop,
			      barcode:barcode}).$promise;
	};

	this.gen_barcode = function(style_number, brand, shop) {
	    return http.save({operation: "gen_stock_barcode"},
			     {style_number:style_number,
			      brand:brand,
			      shop:shop}).$promise;
	};

	this.gen_barcode_all = function(stocks, shop, auto_barcode) {
	    return http.save({operation: "gen_stock_barcode_all"},
			     {stock: stocks, shop:shop, auto:auto_barcode}).$promise;
	};

	this.reset_barcode = function(style_number, brand, shop) {
	    return http.save({operation: "reset_stock_barcode"},
			     {style_number:style_number,
			      brand:brand,
			      shop:shop}).$promise;
	};

	
	this.auto_balance_fix_stock = function(stock){
	    return http.save({operation: "auto_balance_fix_stock"}, stock).$promise;
	};

	/*
	 * print
	 */
	this.print_w_inventory_new = function(rsn) {
	    return http.save({operation: "print_w_inventory_new"}, {rsn: rsn}).$promise;
	};

	this.print_w_inventory_new_note = function(condition) {
	    return http.save(
		{operation: "print_w_inventory_new_note"},
		{condition:condition, e_type: this.export_type.trans_note}).$promise;
	};

	this.print_w_inventory_transfer = function(rsn) {
	    return http.save({operation: "print_w_inventory_transfer"}, {rsn: rsn}).$promise;
	};

	this.print_w_inventory_fix_note = function(condition) {
	    return http.save({operation: "print_w_inventory_fix_note"}, condition).$promise;
	};
	
    });

    // purchaserApp.controller("purchaserCtrl", function($scope, localStorageService){
    // 	diablo_remove_local_storage(localStorageService);
    // });

    purchaserApp.controller("loginOutCtrl", function($scope, $resource, localStorageService){
	$scope.home = function () {
	    stockUtils.remove_cache_page(localStorageService); 
	    diablo_login_out($resource)
	};
    });

    // diablo_remove_app_storage(/^purchaserApp.*$/);
    
    return purchaserApp;
};



