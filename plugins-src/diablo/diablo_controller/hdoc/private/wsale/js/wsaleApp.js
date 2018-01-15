"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage", "angular-file-upload",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], wsaleConfg);

function wsaleConfg(angular){
    var wsaleApp = angular.module(
	'wsaleApp',
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule', 'angularFileUpload',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wsaleApp')
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
   
    wsaleApp.config(['$routeProvider', function($routeProvider){
	// $locationProvider.html5Mode(true);
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

	// var retailer = {"filterRetailer": function(diabloFilter){
	// 	return diabloFilter.get_wretailer()}};

	var sysretailer = {"filterSysRetailer": function(diabloFilter){
    	    return diabloFilter.get_sys_wretailer()}};

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}};

	var promotion = {"filterPromotion": function(diabloFilter){
	    return diabloFilter.get_promotion()}};

	var score = {"filterScore": function(diabloNormalFilter){
	    return diabloNormalFilter.get_score()}};
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}}; 
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var charge = {"filterCharge": function(diabloNormalFilter){
	    return diabloNormalFilter.get_charge()}};
	
	$routeProvider. 
	    when('/new_wsale', {
		templateUrl: '/private/wsale/html/new_wsale.html',
		controller: 'wsaleNewCtrl',
		resolve: angular.extend(
		    {}, user, promotion, charge, score, firm, sysretailer,
		    employee, s_group, brand, type, color, base)
	    }).
	    when('/new_wsale_detail/:page?', {
		templateUrl: '/private/wsale/html/new_wsale_detail.html',
		controller: 'wsaleNewDetailCtrl',
		resolve: angular.extend({}, user, employee, base) 
	    }).
	    when('/update_wsale_detail/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/update_wsale_detail.html',
		controller: 'wsaleUpdateDetailCtrl',
		resolve: angular.extend(
		    {}, user, promotion, score, employee,
		    s_group, brand, color, type, base)
	    }). 
	    when('/wsale_rsn_detail/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/wsale_rsn_detail.html',
		controller: 'wsaleRsnDetailCtrl',
		resolve: angular.extend(
		    {}, user, promotion, score, brand, employee,
		    firm, s_group, type, color, base)
	    }).
	    when('/wsale_firm_detail', {
		templateUrl: '/private/wsale/html/wsale_firm_detail.html',
		controller: 'wsaleFirmDetailCtrl',
		resolve: angular.extend({}, user, brand, firm,  type, base)
	    }).
	    when('/reject_wsale', {
		templateUrl: '/private/wsale/html/reject_wsale.html',
		controller: 'wsaleRejectCtrl',
		resolve: angular.extend(
		    {}, user, promotion, score, brand, type, employee,
		    s_group, color, base) 
	    }).
	    when('/update_wsale_reject/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/update_wsale_reject.html',
		controller: 'wsaleUpdateRejectCtrl',
		resolve: angular.extend(
		    {}, user, promotion, score, employee,
		    s_group, brand, color, type, base)
	    }). 
	    when('/wsale_print_preview/:rsn?', {
		templateUrl: '/private/wsale/html/wsale_print_preview.html',
		controller: 'wsalePrintPreviewCtrl',
		resolve: angular.extend({}, s_group, base) 
	    }).
	    when('/upload_wsale', {
		templateUrl: '/private/wsale/html/wsale_upload.html',
		controller: 'wsaleUploadCtrl',
		resolve: angular.extend({}, user, base) 
	    }).
	    otherwise({
		templateUrl: '/private/wsale/html/new_wsale_detail.html',
		controller: 'wsaleNewDetailCtrl',
		resolve: angular.extend({}, user, employee, base)
            }) 
    }]);

    wsaleApp.service("wsaleService", function($http, $resource, dateFilter){
	this.error = {
	    2190: "该款号库存不存在！！请确认本店是否进货该款号！！",
	    2191: "该款号已存在，请选择新的款号！！",
	    2192: "客户或营业员不存在，请建立客户或营业员资料！！",
	    2193: "该款号吊牌价小于零，无法出售，请定价后再出售！！",
	    2194: "该款号无入库记录，请先入库后再出售或重新选择货品！！",
	    2195: "该条码对应的库存不存在，请确认条码是否正确，或通过款号模式开单！！",
	    2196: "非法条码，条码长度不小于9，请输入正确的条码值！！",
	    2401: "店铺打印机不存在或打印处理暂停状态！！",
	    
	    2411: "打印机编号错误！！",
	    2412: "服务器处理订单失败！！", 
	    2413: "打印内容太长！！",
    	    2414: "打印请求参数错误！！",
	    2415: "打印请求超时，请稍后再试或联系服务人员！！",
	    2416: "未知原因，请系统服务人员！！",
	    
	    2417: "发送打印请求失败，请确保网络通畅！！",
	    
	    2418: "打印机打印失败，请联系服务人员查找原因！！",
	    2419: "打印机未连接！！",
	    2420: "打印机缺纸！！",
	    2421: "打印状态未知，请联系服务人员！！",
	    2422: "打印机连接设备不存在，请检查设备编号是否正确！！",
	    2423: "打印格式缺少尺码，请在打印格式设置中选中尺码！！",
	    2601: "获取零售商历史记录失败！！",
	    2602: "单号不存在，请重新选择销售单",
	    2603: "该销售单交易明细不为空，请删除交易明细后再重新删除！！",
	    2701: "文件导出失败，请重试或联系服务人员查找原因！！",
	    2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
	    2703: "用户余额不足！！",
	    2704: "款号或明细未知，请删除后重新添加！！",
            2705: "应付款项与开单项计算有不符！！",
	    2706: "该电子卷金额与系统不一致，请核对该电子卷后再使用！！",
	    2707: "该电子卷对应的优惠规则不存在！！",
	    2708: "系统时间与服务器时间相差大于30分钟， 请检查系统时间或重新操作！！",
	    2709: "货品不存在，请修改文件后再导入！！",
	    2710: "货品库存不足，无法开单，请核对库存后再导入！！",
	    2711: "货品款号不唯一，无法定位库存，请核对款号后再导入！！",
	    2712: "货品数量校验不通过，请核对该货品数量后再导入！！",
	    2697: "没有要退货的货品，请重新选择货品！！",
	    2698: "会员提取金额超过系统上限！！",
	    2699: "修改前后信息一致，请重新编辑修改项！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	this.rsn_title = ["开单明细", "退货明细", "销售明细"];

	this.direct = {wsale: 0, wreject: 1}; 
	this.wsale_mode = [{title: "款号模式"}, {title: "图片模式"}, {title: "条码模式"}]; 
	this.check_state = [{name:"未审核", id:0},	{name:"已审核", id:1}];
	this.check_comment = [{name:"不为空", id:0}];
	this.export_type = {trans:0, trans_note:1};
	

	this.vpays = [0, 1, 2, 3, -1, -2, -3];
	this.cake_vpays = [0, -0.1, -0.2, -0.3, -0.4, -0.5, -0.6];
	
	// =========================================================================
	var http = $resource("/wsale/:operation/:id",
    			     {operation: '@operation', id: '@id'},
			     {
				 query_by_post: {method: 'POST', isArray: true}
			     });

	this.new_w_sale = function(inventory){
	    return http.save({operation: "new_w_sale"}, inventory).$promise;
	};

	this.update_w_sale_new = function(inventory){
	    return http.save({operation: "update_w_sale"}, inventory).$promise;
	};

	this.update_w_sale_price = function(rsn, updates) {
	    return http.save({operation: "update_w_sale_price"},
			     {rsn:rsn, update: updates}).$promise;
	};

	this.check_w_sale_new = function(rsn){
	    return http.save({operation: "check_w_sale"},
			     {rsn: rsn, mode:diablo_check}).$promise;
	};

	this.uncheck_w_sale_new = function(rsn){
	    return http.save({operation: "check_w_sale"},
			     {rsn: rsn, mode:diablo_uncheck}).$promise;
	};

	this.delete_w_sale_new = function(rsn){
	    return http.save({operation: "delete_w_sale"}, {rsn: rsn}).$promise;
	};

	this.new_w_sale_draft = function(inventory){
	    return http.save({operation: "new_w_sale_draft"}, inventory).$promise;
	};

	this.print_w_sale = function(rsn){
	    return http.save({operation: "print_w_sale"}, {rsn:rsn}).$promise;
	};
	

	this.filter_w_sale_image = function(
	    match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_sale_image"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	}; 

	this.filter_w_sale_new = function(
	    match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_sale_new"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_w_sale_rsn_group = function(
	    mode, match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_sale_rsn_group"},
		{mode: mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.list_wsale_group_by_style_number = function(condition) {
	    return http.save(
		{operation: "list_wsale_group_by_style_number"},
		{condition: condition}).$promise;
	};

	this.get_w_sale_new = function(rsn){
	    return http.get({operation: "get_w_sale_new", id:rsn}).$promise;
	};

	this.get_w_print_content = function(rsn){
	    return http.get({operation: "get_w_print_content", id:rsn}).$promise;
	};

	this.list_w_sale_draft = function(shop){
	    return http.query_by_post(
		{operation: "list_w_sale_draft"}, shop).$promise;
	};

	this.get_w_sale_draft = function(draft_sn){
	    return http.save({operation: "get_w_sale_draft"}, draft_sn).$promise;
	}; 

	this.reject_w_sale = function(inventory){
	    return http.save({operation: "reject_w_sale"}, inventory).$promise;
	};

	
	this.get_wsale_rsn = function(condition){
	    return http.query_by_post(
		{operation: "get_wsale_rsn"}, condition).$promise;
	};
	
	this.get_last_sale = function(inv){
	    return http.query_by_post(
		{operation:    "get_last_sale"},
		{style_number: inv.style_number,
		 brand:        inv.brand,
		 shop:         inv.shop,
		 retailer:     inv.retailer}).$promise;
	};

	this.w_sale_rsn_detail = function(inv){
	    return http.save(
		{operation: "w_sale_rsn_detail"},
		{rsn         :inv.rsn,
		 style_number:inv.style_number,
		 brand       :inv.brand}).$promise;
	};

	this.csv_export = function(e_type, condition){
	    return http.save({operation: "w_sale_export"},
			     {condition: condition, e_type:e_type}).$promise;
	}; 
    });

    wsaleApp.controller("wsaleNewDetailCtrl", wsaleNewDetailProvide);
    wsaleApp.controller("wsaleNewCtrl", wsaleNewProvide);

    wsaleApp.controller("loginOutCtrl", function($scope, $resource, localStorageService){
    	$scope.home = function () {
    	    wsaleUtils.remove_cache_page(localStorageService); 
    	    diablo_login_out($resource);
    	};
    });

    diablo_remove_wsale_local_storage();

    return wsaleApp;
};

function wsaleNewProvide(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wsaleService, wsaleGoodService,
    user, filterPromotion, filterCharge, filterScore,
    filterFirm, filterSysRetailer, filterEmployee,
    filterSizeGroup, filterBrand, filterType, filterColor, base){
    // console.log(base);
    $scope.promotions = filterPromotion;
    $scope.scores     = filterScore;
    $scope.draws      = filterCharge.filter(function(d){return d.type === diablo_withdraw}),
    
    // console.log($scope.draws);
    // console.log($scope.scores);
    
    $scope.pattern    = {
	money:    diabloPattern.decimal_2,
	sell:     diabloPattern.integer_except_zero,
	discount: diabloPattern.discount};
    
    $scope.timeout_auto_save = undefined;
    $scope.interval_per_5_minute = undefined;
    $scope.round  = diablo_round;
    
    $scope.today = function(){
	return $.now();
    };
    
    $scope.back  = function(){
	diablo_goto_page("#/new_wsale_detail");
    };

    $scope.setting = {q_backend:true, check_sale:true, negative_sale:true};

    $scope.right = {
	m_discount: wsaleUtils.authen_rainbow(user.type, 'modify_discount_onsale', user.right),
	m_price: wsaleUtils.authen_rainbow(user.type, 'modify_price_onsale', user.right), 
	master:rightAuthen.authen_master(user.type)
    };

    console.log($scope.right);

    $scope.focus_attr = {style_number:false,
			 barcode:false,
			 sell:false,
			 cash:false,
			 card:false,
			 wxin:false};
    
    $scope.auto_focus = function(attr){
	if (!$scope.focus_attr[attr]){
	    $scope.focus_attr[attr] = true;
	}
	for (var o in $scope.focus_attr){
	    if (o !== attr) $scope.focus_attr[o] = false;
	} 
    };

    $scope.disable_focus = function() {
	for (var o in $scope.focus_attr){
	    $scope.focus_attr[o] = false;
	} 
    };

    $scope.key_action = function(key){
	if (key === 113) $scope.auto_focus('cash');
	if (key === 114) $scope.auto_focus('card');
	// if (key === 114) {
	//     if (!$scope.disable_save()) $scope.save_wsale();
	// }
	if (key === 117){
	    if (!$scope.disable_refresh) $scope.refresh();
	}
    }
    
    wsaleGoodService.set_brand(filterBrand);
    wsaleGoodService.set_type(filterType);
    wsaleGoodService.set_size_group(filterSizeGroup);
    wsaleGoodService.set_firm(filterFirm);
    wsaleGoodService.set_color(filterColor);

    // base setting 
    $scope.immediately_print = function(shopId){
	return wsaleUtils.im_print(shopId, base); 
    };

    $scope.q_typeahead = function(){
	// default prompt comes from backend
	return wsaleUtils.typeahead($scope.select.shop.id, base); 
    };
    
    $scope.p_mode = function(shopId){
	return wsaleUtils.print_mode(shopId, base);
    };
    
    $scope.sexs            = diablo_sex;
    $scope.seasons         = diablo_season;
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.f_discount      = diablo_discount;
    $scope.wsale_mode      = wsaleService.wsale_mode;
    $scope.show_promotions = [];
    $scope.disable_refresh = true;
    $scope.has_withdrawed  = false;

    $scope.select = {
	rsn:  undefined,
	cash: undefined,
	card: undefined,
	wxin: undefined,
	withdraw: undefined,
	
	ticket_batch: undefined,
	ticket_balance: undefined,
	ticket_sid: -1,
	ticket_score: 0,
	ticket_custom: diablo_invalid,
	
	total:        0,
	abs_total:    0,
	has_pay:      0,
	should_pay:   0,
	score:        0,
	pscores:      [],
	charge:       0,
	surplus:      0,
	left_balance: 0,
	sid:          -1,
	datetime:     $scope.today()
    };

    var dialog = diabloUtilsService;
    
    var get_setting = function(shopId){
	$scope.setting.check_sale    = wsaleUtils.check_sale(shopId, base);
	$scope.setting.negative_sale = wsaleUtils.negative_sale(shopId, base);
	$scope.setting.no_vip        = wsaleUtils.no_vip(shopId, base);
	$scope.setting.q_backend     = $scope.q_typeahead(shopId);
	$scope.setting.round         = wsaleUtils.round(shopId, base);
	$scope.setting.smember       = wsaleUtils.s_member(shopId, base);
	$scope.setting.semployee     = wsaleUtils.s_employee(shopId, base);
	$scope.setting.cake_mode     = wsaleUtils.cake_mode(shopId, base);
	$scope.setting.barcode_mode  = wsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = wsaleUtils.barcode_auto(shopId, base);
	$scope.setting.draw_score    = wsaleUtils.draw_score(shopId, base);
	$scope.setting.draw_region   = wsaleUtils.draw_score(shopId, base); 

	if (diablo_no === $scope.setting.cake_mode) {
	    $scope.vpays = wsaleService.vpays;
	} else {
	    $scope.vpays = wsaleService.cake_vpays;
	}

	$scope.select.verificate = $scope.vpays[0];
	// console.log($scope.setting);
    };
    
    // shops
    $scope.shops = user.sortShops;
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0];
	get_setting($scope.select.shop.id); 
    }

    $scope.focus_good_or_barcode = function() {
	if ($scope.setting.barcode_mode)
	    $scope.auto_focus('barcode');
	else
	    $scope.auto_focus('style_number');
    }; 
    $scope.focus_good_or_barcode(); 

    $scope.change_shop = function(){
	get_setting($scope.select.shop.id);	
	// $scope.match_all_w_inventory(); 
	$scope.get_employee();

	$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	$scope.wsaleStorage.change_shop($scope.select.shop.id);
	// $scope.wsaleStorage.change_employee($scope.select.employee.id);
	$scope.refresh(); 
    };
    
    if ($scope.p_mode($scope.select.shop.id) === diablo_frontend){
	if (needCLodop()) loadCLodop();
	
	$scope.comments = wsaleUtils.comment($scope.select.shop.id, base);
	$scope.p_num = wsaleUtils.print_num($scope.select.shop.id, base);
	// console.log($scope.comments, $scope.p_num);
    }
    
    $scope.get_employee = function(){
	var select = wsaleUtils.get_login_employee(
	    $scope.select.shop.id, user.loginEmployee, filterEmployee);

	$scope.employees = select.filter;
	$scope.select.employee = select.login;
	if ($scope.setting.semployee) $scope.select.employee = undefined;
    };
    
    $scope.get_employee(); 
    // retailer;
    $scope.match_retailer_phone = function(viewValue){
	return wsaleUtils.match_retailer_phone(viewValue, diabloFilter)
    };
    
    $scope.set_retailer = function(){
    	if ($scope.select.retailer.type_id === diablo_charge_retailer){
    	    $scope.select.surplus = wsaleUtils.to_decimal($scope.select.retailer.balance);
    	    $scope.select.left_balance = $scope.select.surplus;
    	} 
    	$scope.select.o_retailer = $scope.select.retailer;
    	$scope.select.ticket_batch = undefined;
    	$scope.select.ticket_balance = undefined;
    };
    
    $scope.on_select_retailer = function(item, model, label){
	// console.log(item);
	console.log($scope.select.retailer);
	$scope.set_retailer();
	$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	$scope.wsaleStorage.change_retailer($scope.select.retailer.id);
	$scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
	
	// image mode, refresh image
	if ($scope.wsale_mode[1].active){
	    $scope.page_changed($scope.current_page); 
	}
    };

    $scope.sysRetailers = filterSysRetailer;
    // console.log($scope.sysRetailers);
    $scope.reset_retailer = function(){
    	if (diablo_yes === $scope.setting.smember){
    	    $scope.sysRetailers = $scope.sysRetailers.filter(function(r){
    		return r.shop_id === $scope.select.shop.id;
    	    });
    	};
	
    	// console.log($scope.retailer);
    	if ($scope.sysRetailers.length !== 0){
    	    $scope.select.retailer = $scope.sysRetailers[0];
    	    if (user.loginRetailer !== diablo_invalid){
    		for (var i=0, l=$scope.sysRetailers.length; i<l; i++){
                    if (user.loginRetailer === $scope.sysRetailers[i].id){
    			$scope.select.retailer = $scope.sysRetailers[i]
    			break;
                    }
    		}
            } 
    	    $scope.set_retailer(); 
    	};
    };

    $scope.reset_retailer();

    /*
     * with draw
     */ 
    $scope.disable_withdraw = function(){
	return angular.isDefined($scope.select.retailer)
	    && $scope.select.retailer.type_id === diablo_charge_retailer
	    && $scope.select.retailer.surplus <= 0
	    || $scope.select.charge <= 0
	    || $scope.has_withdrawed;
    };
    
    $scope.withdraw = function(){
	var callback = function(params){
	    console.log(params);
	    diabloFilter.check_retailer_password(
		params.retailer.id, params.retailer.password, $scope.select.shop.id
	    ).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			if (result.limit !== 0 && params.retailer.withdraw > result.limit){
			    diabloUtilsService.response(
				false,
				"会员现金提取",
				"会员现金提取失败："
				    + wsaleService.error[2698]
				    + "上限[" + result.limit + "]，"
				    + "实际提取[" + params.retailer.withdraw + "]",
				undefined) 
			} else {
			    $scope.select.withdraw = params.retailer.withdraw;
			    $scope.has_withdrawed  = true;
			    $scope.reset_payment();
			    // $scope.reset_score();
			} 
		    } else {
			var ERROR = require("diablo-error");
			diabloUtilsService.response(
			    false,
			    "会员现金提取",
			    ERROR[result.ecode],
			    undefined)
		    }
		}); 
	};

	var get_max_draw = function(){

	    var max_draw = 0;
	    if ($scope.select.surplus >= $scope.select.charge){
		max_draw =  $scope.select.charge;
	    }  else {
		max_draw = $scope.select.surplus; 
	    }

	    var limit = diablo_get_object($scope.select.retailer.draw_id, $scope.draws);
	    console.log(limit);
	    if (angular.isObject(limit)){
		if (max_draw >=limit.charge)
		    return limit.charge;
	    } else {
		return max_draw;
	    } 
	}; 
	var limit_balance = get_max_draw();
	
	var startWithdraw = function() {
	    diabloUtilsService.edit_with_modal(
		"new-withdraw.html",
		undefined,
		callback,
		undefined,
		{retailer: {
		    id        :$scope.select.retailer.id,
		    name      :$scope.select.retailer.name,
		    surplus   :$scope.select.surplus, 
		    withdraw  :limit_balance 
		},
		 
		 check_withdraw: function(balance){
		     // return balance > $scope.select.retailer.balance
		     //     || balance > $scope.select.charge ? false : true;
		     return balance <= limit_balance;
		 },
		 
		 check_zero: function(balance) {return balance === 0 ? true:false}
		}
	    )
	}

	if (diablo_yes === $scope.setting.draw_region) {
	    diabloFilter.check_retailer_region(
		$scope.select.retailer.id, $scope.select.shop.id
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    startWithdraw();
		} else {
		    var ERROR = require("diablo-error");
		    diabloUtilsService.response(
			false,
			"会员现金提取",
			ERROR[result.ecode],
			undefined)
		}
	    })
	} else {
	    startWithdraw();
	}
	
    };

    /*
     * ticket
     */
    $scope.ticket = function(){
	$scope.select.ticket_batch   = undefined;
	$scope.select.ticket_balance = undefined;
	$scope.select.ticket_custom  = undefined; 
	
	var callback = function(params){
	    // console.log(params); 
	    if (!params.auto_batch) {
	    	diabloFilter.get_ticket_by_batch(params.ticket.batch).then(function(result){
	    	    console.log(result);
	    	    var ecode = result.ecode;
	    	    if (ecode === 0 && !diablo_is_empty(result.data)) {
	    		$scope.select.ticket_batch = diablo_set_integer(result.data.batch);
	    		$scope.select.ticket_balance = diablo_set_integer(result.data.balance);
			$scope.select.ticket_custom = params.auto_batch ? diablo_score_ticket:diablo_custom_ticket;
	    		$scope.reset_payment();
	    	    } else {
	    		if (diablo_is_empty(result.data)) ecode = 2105;
	    		var ERROR = require("diablo-error");
	    		diabloUtilsService.response(
	    		    false,
	    		    "会员电子卷获取",
	    		    ERROR[ecode],
	    		    undefined);
	    	    } 
	    	});
	    } else {
	    	$scope.select.ticket_batch = params.ticket.batch;
	    	$scope.select.ticket_balance = params.ticket.balance;
		$scope.select.ticket_custom = params.auto_batch ? diablo_score_ticket:diablo_custom_ticket;
	    	$scope.reset_payment();
	    } 
	};
	
	diabloFilter.get_ticket_by_retailer($scope.select.retailer.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var batch;
		var balance;
		var auto_batch = false;
		$scope.select.ticket_sid = diablo_invalid_index;
		
		if (!diablo_is_empty(result.data)) {
		    batch   = diablo_set_integer(result.data.batch);
		    balance = diablo_set_integer(result.data.balance);
		    $scope.select.ticket_sid = wsaleUtils.to_integer(result.data.sid);
		    auto_batch = true; 
		}
		
		diabloUtilsService.edit_with_modal(
		    "new-ticket.html",
		    undefined,
		    callback,
		    undefined,
		    {ticket: {batch: batch, balance: balance},
		     auto_batch: auto_batch});
	    } else {
		var ERROR = require("diablo-error");
		diabloUtilsService.response(
		    false,
		    "会员电子卷获取",
		    ERROR[result.ecode],
		    undefined);
	    }
	}); 
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.inventories.push({$edit:false, $new:true});
	$scope.show_promotions = [];
	
	$scope.select.form.cardForm.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	$scope.select.form.wForm.$invalid  = false; 

	$scope.select.rsn          = undefined;
	$scope.select.cash         = undefined;
	$scope.select.card         = undefined;
	$scope.select.wxin         = undefined;
	$scope.select.withdraw     = undefined;
	
	$scope.select.ticket_batch = undefined;
	$scope.select.ticket_balance = undefined;
	$scope.select.ticket_score = 0;
	$scope.select.ticket_sid   = diablo_invalid_index;
	$scope.select.ticket_custom = diablo_invalid;
	
	$scope.select.has_pay      = 0;
	$scope.select.should_pay   = 0;
	$scope.select.score        = 0;
	$scope.select.pscores      = [];
	$scope.select.charge       = 0;
	$scope.select.surplus      = $scope.select.retailer.balance;
	$scope.select.left_balance = $scope.select.surplus;
	$scope.select.verificate   = $scope.vpays[0],
	
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.comment      = undefined;
	
	$scope.select.datetime     = $scope.today();
	
	if ($scope.setting.semployee)
	    $scope.select.employee = undefined;
	
	$scope.disable_refresh     = true;
	$scope.has_saved           = false;
	$scope.has_withdrawed      = false;
	
	$scope.focus_good_or_barcode();
	$scope.wsaleStorage.reset();
	$scope.reset_retailer();
    };

    
    $scope.refresh_datetime_per_5_minute = function(){
    	$scope.interval_per_5_minute = setInterval(function(){
    	    $scope.select.datetime  = $scope.today();
	    // console.log(dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"));
    	}, 300 * 1000);
    };

    var now = $scope.today(); 
    $scope.qtime_start = function(shopId){
	return wsaleUtils.start_time(shopId, base, now, dateFilter);
    };
    
    $scope.setting.q_backend = $scope.q_typeahead($scope.select.shop.id);
    // console.log($scope.setting.q_backend);
    
    $scope.match_all_w_inventory = function(){
	// var as = ["a", "abcd", "abc", "df"].sort(function(a1, a2){
	//     return a1.length - a2.length;
	// });	
	if (!$scope.setting.q_backend){
	    diabloNormalFilter.match_all_w_inventory(
		{shop:$scope.select.shop.id,
		 start_time:$scope.qtime_start($scope.select.shop.id)}
	    ).$promise.then(function(invs){
		$scope.all_w_inventory = 
		    invs.sort(function(inv1, inv2){
			return inv1.style_number.length - inv2.style_number.length;
		    }).map(function(inv){
			var p = wsaleUtils.prompt_name(
			    inv.style_number, inv.brand, inv.type); 
			return angular.extend(
                            inv, {name:p.name, prompt:p.prompt}); 
		    });
	    });
	};
    }

    // $scope.match_all_w_inventory();
    $scope.refresh_datetime_per_5_minute();

    // init
    $scope.inventories = [];
    $scope.inventories.push({$edit:false, $new:true});

    /*
     * draft
     */
    $scope.wsaleStorage = new wsaleDraft(
	localStorageService,
	$scope.select.shop.id,
	$scope.select.retailer.id,
	// $scope.select.employee.id,
	dateFilter);
    // console.log($scope.wsaleStorage);
    
    $scope.disable_draft = function(){
	if ($scope.wsaleStorage.keys().length === 0 || $scope.inventories.length !== 1)
	    return true; 
	return false;
    };

    $scope.list_draft = function(){
	var keys = $scope.wsaleStorage.keys(); 
	var retailerIds = keys.map(function(k){
	    var p = k.split("-");
	    return parseInt(p[1]);
	}); 
	// console.log(retailerIds);
	
	diabloFilter.get_wretailer_batch(retailerIds).then(function(retailers){
	    console.log(retailers); 
	    var draft_filter = function(keys){
		return keys.map(function(k){
		    var p = k.split("-");
		    return {sn:k,
			    // employee:diablo_get_object(p[1], $scope.employees),
			    retailer:diablo_get_object(parseInt(p[1]), retailers),
			    shop:diablo_get_object(parseInt(p[2]), $scope.shops)}
		});
	    };

	    var select = function(draft, resource){
		if (draft.shop.id !== $scope.select.shop.id){
		    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops); 
		    $scope.get_employee(); 
		};
		
		$scope.select_draft_key = draft.sn;
		$scope.wsaleStorage.set_key(draft.sn);
		// $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
		$scope.select.retailer = diablo_get_object(draft.retailer.id, retailers);
		$scope.select.surplus  = $scope.select.retailer.balance;
		$scope.get_employee(); 
		
		$scope.inventories = angular.copy(resource);
		// console.log($scope.inventoyies);
		$scope.inventories.unshift({$edit:false, $new:true});
		$scope.disable_refresh = false;
		$scope.re_calculate(); 
	    };

	    $scope.wsaleStorage.select(diabloUtilsService, "wsale-draft.html", draft_filter, select);  
	}); 
    };
    
    $scope.match_style_number = function(viewValue){
	return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
    } 

    $scope.copy_select = function(add, src){
	// console.log(src);
	add.id           = src.id;
	add.bcode        = src.bcode;
	add.full_bcode   = src.full_bcode;
	add.style_number = src.style_number;
	
	add.brand_id     = src.brand_id;
	add.brand        = src.brand;
	
	add.type_id      = src.type_id;
	add.type         = src.type;
	
	add.firm_id      = src.firm_id; 
	
	add.sex          = src.sex;
	add.season       = src.season;
	add.year         = src.year;
	
	add.pid          = src.pid;
	add.promotion    = diablo_get_object(src.pid, $scope.promotions);
	add.sid          = src.sid;
	add.score        = diablo_get_object(src.sid, $scope.scores);

	add.org_price    = src.org_price;
	add.ediscount    = src.ediscount;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;
	
	add.path         = src.path; 
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.entry        = src.entry_date;

	// add.full_bcode   = angular.isUndefined(src.full_bcode) ? src.bcode : src.full_bcode;
	add.full_name    = add.style_number + "/" + add.brand;

	return add; 
    };

    var fail_response = function(code, callback){
	diabloUtilsService.response_with_callback(
	    false,
	    "销售开单",
	    "开单失败：" + wsaleService.error[code],
	    undefined,
	    callback);
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item);

	if (item.tag_price < 0){
	    fail_response(2193, function(){
		$scope.inventories[0] = {$edit:false, $new:true}});
	    return;
	};
	
	// one good can be add only once at the same time
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    if (item.style_number === $scope.inventories[i].style_number
		&& item.brand_id  === $scope.inventories[i].brand_id){
		fail_response(2191, function(){
		    $scope.inventories[0] = {$edit:false, $new:true}});
		return; 
	    }
	}; 

	// auto focus
	$scope.auto_focus("sell");
	
	// add at first allways 
	var add = $scope.inventories[0];
	add = $scope.copy_select(add, item);
	console.log(add);
	$scope.add_inventory(add);
	
	return;
    };

    
    /*
     * image mode
     */
    // filter
    $scope.filters = [];
    diabloFilter.reset_field();
    // diabloFilter.add_field("firm", filterFirm);
    diabloFilter.add_field("brand", wsaleGoodService.get_brand());
    diabloFilter.add_field("type",  wsaleGoodService.get_type());

    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    $scope.time   = diabloFilter.default_time();

    // tale
    $scope.default_image_column = 6;
    $scope.default_image_row = 2;
    $scope.colspan = $scope.default_image_column;
    // $scope.image_inventories = [];
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size(); 
    // default the first page
    $scope.default_page = 1;
    $scope.current_page = $scope.default_page;
    var last_image_page = 0;
    var last_select_shop = 0;
    var last_select_retailer = 0;
    
    $scope.row_range = diablo_range($scope.default_image_row).map(function(r){
	return r - 1;
    });
    
    $scope.select_image = function(inv){
	$scope.on_select_good(inv);
    } 
    
    $scope.image_mode = function(page){
	if (page !== last_image_page
	    || last_select_shop !== $scope.select.shop.id
	    || last_select_retailer !== $scope.select.retailer.id){
	    $scope.page_changed(page); 
	}
    };

    $scope.do_search = function(page){
	$scope.page_changed(page);
    };
    
    $scope.page_changed = function(page){
	console.log(page); 
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    search.shop = $scope.select.shop.id;
	    search.retailer = $scope.select.retailer.id;
	    
	    wsaleService.filter_w_sale_image(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    if (page === 1){
			$scope.total_items = result.total;
		    }

		    // get sale history of retailer
		    // $scope.retailer_sale_history = result.history;
		    
		    // grouping
		    $scope.image_inventories = [];
		    var row     = $scope.default_image_row; 
    		    var column  = $scope.default_image_column;
		    var history = result.history;
		    var data    = result.data;
		    for (var i=0; i<row; i++){
			var r = [];
			for(var j=0; j<column; j++){
			    // console.log(i * column + j);
			    var index = i * column + j;
			    if (index >= data.length){
    	            		break;
    			    }

			    for(var k=0, l=history.length; k<l; k++){
				if ( data[index].style_number
				     === history[k].style_number
				     && data[index].brand_id
				     === history[k].brand ){
				    // console.log(data[index]);
				    data[index].history = true;
				}
			    }
    			    r.push(data[index]); 
    			}

			// console.log(r);
			$scope.image_inventories[i] = r;
		    }

		    console.log($scope.image_inventories);
		    last_image_page = page;
		    last_select_shop = $scope.select.shop.id;
		    last_select_retailer = $scope.select.retailer.id;
		} else{
		    diabloUtilsService.response(
			false,
			"获取库存",
			"获取库存失败："
			    + wsaleService.error[result.ecode], $scope)
		}
		
	    })
	})
    };

    $scope.barcode_scanner = function(full_bcode) {
	// console.log($scope.inventories);
    	console.log(full_bcode);
	// get stock by barcode
	// stock info 
	var barcode = diabloHelp.correct_barcode(full_bcode, $scope.setting.barcode_auto); 
	console.log(barcode);

	// invalid barcode
	if (!barcode.cuted || !barcode.correct) {
	    dialog.response(false, "销售开单", "开单失败" + wsaleService.error[2196]);
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(barcode.cuted, $scope.select.shop.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.response(false, "销售开单", "开单失败" + wsaleService.error[2195]);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.response(false, "销售开单", "开单失败" + wsaleService.error[result.ecode]);
	    }
	});
	
    };
    
    // $scope.barcode_scanner_options = {
    // 	onComplete: function(barcode) {
    // 	    console.log(barcode);
    // 	},
    // 	minLength: 3
    // };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved || $scope.draft || $scope.inventories.length === 1)
	    return true;
	
	if ($scope.select.should_pay >=0 && $scope.select.charge > 0)
	    return true;

	if ($scope.select.should_pay < 0 && $scope.select.charge > 0)
	    return true; 
	
	return false;
    };

    $scope.print_backend = function(result, im_print){
	var print = function(status){
	    var messsage = "";
	    if (status.pcode == 0){
		messsage = "单号：" + result.rsn + "，打印成功，请等待服务器打印！！";
	    } else {
		if (status.pinfo.length === 0){
		    messsage += wsaleService.error[status.pcode]
		} else {
		    angular.forEach(status.pinfo, function(p){
			messsage += "[" + p.device + "] "
			    + wsaleService.error[p.ecode]
		    })
		};
		messsage = "单号：" + result.rsn + "，打印失败：" + messsage;
	    }

	    return messsage;
	};

	var error = function(status) {
	    var error_message = "";
	    if (status.pcode !== 0)
		error_message += print(status);

	    if (status.sms_code !== 0){
		// if (status.sms_code !== 0) {
		var ERROR = require("diablo-error");
		error_message += "发送短消息失败：" + ERROR[status.sms_code];
		// }		
	    }

	    return error_message;
	};

	var show_dialog = function(title, message){
	    dialog.response(true, title, message, undefined)
	};

	if (im_print === diablo_yes){
	    if (result.pcode !== 0 || result.sms_code !== 0)
		show_dialog("销售开单", "开单成功！！" + error(result));
	} else{
	    var ok_print = function(){
		wsaleService.print_w_sale(result.rsn).then(function(presult){
		    if (result.pcode !== 0 || result.sms_code !== 0)
			show_dialog("销售开单", "开单成功" + error(presult)); 
		})
	    };
	    
	    dialog.request(
		"销售开单", "开单成功，是否打印销售单？",
		ok_print, undefined, $scope);
	}
	
    };

    var LODOP;
    $scope.print_front = function(result, im_print){
	// var oscript = document.createElement("script");
	// oscript.src ="/public/assets/lodop/LodopFuncs.js";
	// var head = document.head
	//     || document.getElementsByTagName("head")[0]
	//     || document.documentElement;
	// head.insertBefore(oscript, head.firstChild);
	// console.log($scope.inventories.filter(function(r){return !r.$new}));
	var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
	var pinvs = [];
	for (var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].total = $scope.inventories[i].sell;
	    pinvs.push($scope.inventories[i]);
	};

	// console.log(pinvs);
	
	if (angular.isUndefined(LODOP)) LODOP = getLodop();

	var timeout_to_print = undefined;
	var ok_print = function(){
	    console.log($scope.select);
	    if (angular.isDefined(LODOP)){
		var start_print = function(){
		    $scope.select.ticket_score = 0; 
		    var sid = $scope.select.ticket_sid;
		    if (diablo_invalid_index !== sid) {
			var s = diablo_get_object(sid, $scope.scores);
			$scope.select.ticket_score =
			    parseInt($scope.select.ticket_balance / s.balance) * s.score
		    }
			
		    wsalePrint.gen_head(
			LODOP,
			$scope.select.shop.name,
			$scope.select.rsn,
			$scope.select.employee.name,
			$scope.select.retailer.name, 
			dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
			wsaleService.direct.wsale);

		    var isRound = $scope.setting.round; 
		    var cakeMode = $scope.setting.cake_mode;
		    var hLine = wsalePrint.gen_body(LODOP, pinvs, isRound, cakeMode);
		    
		    var isVip = ($scope.select.retailer.id !== $scope.setting.no_vip
				 || $scope.select.retailer.id !== user.loginRetailer) ? true : false;
		    
		    // console.log($scope.select);
		    hLine = wsalePrint.gen_stastic(
			LODOP,
			hLine,
			0,
			$scope.select,
			isVip); 
		    wsalePrint.gen_foot(LODOP, hLine, $scope.comments, pdate, cakeMode);
		    wsalePrint.start_print(LODOP); 
		};
		
		for (var i=0; i<$scope.p_num; i++){
		    start_print(); 
		}
		
		if (angular.isDefined(timeout_to_print))
		    $timeout.cancel(timeout_to_print);
	    }
	};

	var sms_notify = function(status) {
	    if (status.sms_code !== 0) {
		var ERROR = require("diablo-error");
		dialog.response(
		    false,
		    "销售开单",
		    "开单成功！！发送短消息失败：" + ERROR[status.sms_code]); 
	    }
	};
	
	if (im_print === diablo_yes){
	    ok_print();
	    sms_notify(result);
	} else {
	    var request = dialog.request(
		"销售开单", "开单成功，是否打印销售单？", undefined, undefined, undefined); 
	    request.result.then(function(close){
		ok_print();
		sms_notify(result);
	    })
	}
    };
    
    $scope.save_wsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	// console.log($scope.select);
	if (angular.isUndefined($scope.select.retailer)
		|| diablo_is_empty($scope.select.retailer)
		|| angular.isUndefined($scope.select.employee)
		|| diablo_is_empty($scope.select.employee)){
		diabloUtilsService.response(
		    false,
		    "销售开单",
		    "开单失败：" + wsaleService.error[2192]);
	    $scope.has_saved = false; 
	    return;
	};
	
	var get_sales = function(amounts){
	    var sale_amounts = [];
	    for(var i=0, l=amounts.length; i<l; i++){
		var a = amounts[i];
		if (angular.isDefined(a.sell_count) && a.sell_count){
		    var new_a = {
			cid:        a.cid,
			size:       a.size, 
			sell_count: parseInt(amounts[i].sell_count)}; 
		    
		    sale_amounts.push(new_a); 
		}
	    }; 

	    return {amounts:sale_amounts};
	};

	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string;
	
	var added = [];
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    // var batch = add.batch;
	    // console.log(batch);
	    var amount_info = get_sales(add.amounts);
	    added.push({
		id          : add.id,
		style_number: add.style_number,
		brand       : add.brand_id,
		brand_name  : add.brand,
		type        : add.type_id,
		type_name   : add.type,
		firm        : add.firm_id,
		sex         : add.sex,
		season      : add.season,
		year        : add.year,
		entry       : add.entry,
		sell_total  : parseInt(add.sell),

		promotion   : add.pid,
		score       : add.sid,

		org_price   : add.org_price,
		ediscount   : add.ediscount,
		tag_price   : add.tag_price,
		fprice      : add.fprice,
		rprice      : add.rprice,
		fdiscount   : add.fdiscount,
		rdiscount   : add.rdiscount,
		stock       : add.total,
		
		path        : sets(add.path), 
		sizes       : add.sizes,
		s_group     : add.s_group,
		colors      : add.colors,
		free        : add.free,
		comment     : sets(add.comment), 
		amounts     : amount_info.amounts
	    })
	}; 

	// console.log($scope.select);
	var im_print = $scope.immediately_print($scope.select.shop.id);
	var p_mode = $scope.p_mode($scope.select.shop.id);
	// console.log(im_print);
	var base = {
	    retailer:       $scope.select.retailer.id,
	    vip:            $scope.select.retailer.id !== $scope.setting.no_vip,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        sets($scope.select.comment),
	    ticket_batch:   seti($scope.select.ticket_batch),
	    ticket_custom:  $scope.select.ticket_custom,

	    balance:        $scope.select.surplus, 
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wxin:           setv($scope.select.wxin),
	    withdraw:       setv($scope.select.withdraw),
	    ticket:         setv($scope.select.ticket_balance),
	    verificate:     setv($scope.select.verificate), 
	    
	    should_pay:     setv($scope.select.should_pay),
	    // has_pay:        $scope.select.has_pay,
	    
	    charge:         $scope.select.charge,
	    total:          $scope.select.total,
	    last_score:     $scope.select.retailer.score,
	    score:          $scope.select.score,
	    // sid             wsaleUtils.to_integer($scope.select.sid),
	    // draw_score:     $scope.setting.draw_score,
	    
	    round:          $scope.setting.round
	    // draw_score:     $scope.setting.draw_score
	};

	var print = {
	    im_print:    im_print,
	    p_mode:      p_mode,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    retailer_id: $scope.select.retailer.id,
	    retailer:    $scope.select.retailer.name
	};

	console.log(added);
	console.log(base);
	
	var dialog = diabloUtilsService; 
	wsaleService.new_w_sale({
	    inventory:added.length === 0 ? undefined : added,
	    base:base, print:print
	}).then(function(result){
	    console.log(result);
	    var success_callback = function(){
		// clear local storage
		if (angular.isDefined($scope.select_draft_key)){
		    $scope.wsaleStorage.remove($scope.select_draft_key);
		    $scope.select_draft_key = undefined;
		};
		$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());

		if ($scope.select.retailer.id !== $scope.setting.no_vip) {
		    $scope.select.retailer.score += $scope.select.score;
		    $scope.select.retailer.score -= $scope.select.ticket_score;
		}
		
		$scope.refresh();
		
		// $scope.disable_refresh = false;
		// modify current balance of retailer
		// $scope.select.retailer.balance = $scope.select.left_balance;
		// $scope.select.surplus = $scope.select.left_balance;
	    }

	    
	    if (result.ecode === 0){
		$scope.select.rsn = result.rsn;
		if (diablo_backend === p_mode){
		    $scope.print_backend(result, im_print);
		} else {
		    $scope.print_front(result, im_print); 
		}
		success_callback();
	    } else {
		dialog.response_with_callback(
	    	    false,
		    "销售开单",
		    "开单失败："
			+ wsaleService.error[result.ecode]
			+ wsaleUtils.extra_error(result), 
		    undefined,
		    function(){$scope.has_saved = false});
		
	    } 
	})
    };
    
    $scope.reset_payment = function(newValue){
	$scope.select.has_pay = 0;
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.cash); 
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.card);
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.wxin);
	
	var withdraw = wsaleUtils.to_float($scope.select.withdraw);
	if($scope.select.retailer.type_id === diablo_charge_retailer && withdraw > 0){
	    $scope.select.has_pay += withdraw;
	    $scope.select.left_balance = $scope.select.surplus - withdraw;
	}

	var ticket_balance = wsaleUtils.to_integer($scope.select.ticket_balance);
	if (ticket_balance > 0) {
	    $scope.select.has_pay += ticket_balance;
	}
	
	$scope.select.charge = $scope.select.should_pay - $scope.select.has_pay;

	$scope.reset_score();
    };

    $scope.reset_score = function() {
	// only score with cash, card, wxin
	if (diablo_no === $scope.setting.draw_score && $scope.select.withdraw !== 0) {
	    var pay_orders = wsaleCalc.pay_order(
		$scope.select.should_pay, [
		    $scope.select.ticket_balance,
		    $scope.select.withdraw,
		    $scope.select.wxin,
		    $scope.select.card,
		    $scope.select.cash]);
	    var pay_with_score = pay_orders[2] + pay_orders[3] + pay_orders[4] - $scope.select.verificate;
	    $scope.select.score = wsaleUtils.calc_score_of_pay(pay_with_score, $scope.select.pscores);
	}
    };
    
    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cashForm.$invalid) return; 
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.cardForm.$invalid) return;
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.wxin", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	if ($scope.select.form.wForm.$invalid) return;
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	$scope.reset_payment(newValue); 
	$scope.re_calculate();
	// $scope.reset_score();
    });
    
    var in_amount = function(amounts, inv){
	for(var i=0, l=amounts.length; i<l; i++){
	    if(amounts[i].cid === inv.color_id
	       && amounts[i].size === inv.size){
		amounts[i].count += parseInt(inv.amount);
		return true;
	    }
	}
	return false;
    };

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    }; 
    
    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;
	$scope.select.score        = 0; 

	// console.log($scope.inventoyies);
	var calc = wsaleCalc.calculate(
	    $scope.select.o_retailer,
	    $scope.select.retailer,
	    $scope.setting.no_vip, 
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_sale,
	    $scope.select.verificate,
	    $scope.setting.round);
	
	console.log(calc);
	$scope.select.total     = calc.total; 
	$scope.select.abs_total = calc.abs_total;
	$scope.select.should_pay= calc.should_pay; 
	$scope.select.score     = calc.score; 
	$scope.select.pscores   = calc.pscores;
	$scope.select.charge    = $scope.select.should_pay - $scope.select.has_pay;

	$scope.reset_score();
    };

    var valid_sell = function(amount){
	var sell = diablo_set_integer(amount.sell_count);
	if (0 === wsaleUtils.to_integer(sell)) return true;

	var valid = false; 
	if ($scope.setting.check_sale && sell > amount.count) return false;

	if (diablo_no === $scope.setting.negative_sale && sell < 0) return false;
	
	return true;
    };
    
    var valid_all_sell = function(amounts){
	var renumber = /^[+|\-]?[1-9][0-9]*$/; 
	var unchanged = 0;

	for(var i=0, l=amounts.length; i<l; i++){
	    var sell = amounts[i].sell_count;
	    if (0 === wsaleUtils.to_integer(sell)){
		unchanged++;
		continue;
	    }
	    
	    if (!renumber.test(sell)) return false;

	    if ($scope.setting.check_sale && sell > amounts[i].count) return false 
	    if (diablo_no === $scope.setting.negative_sale && sell < 0) return false; 
	};

	return unchanged === l ? false : true;

    };

    var add_callback = function(params){
	console.log(params.amounts);
	
	var sell_total = 0;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += parseInt(a.sell_count);
	    }
	}); 

	return {amounts:     params.amounts,
		sell:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice};
    };
    
    $scope.add_free_inventory = function(inv){
	// console.log(inv);

	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};
	
	inv.$edit = true;
	inv.$new  = false;
	inv.amounts[0].sell_count = inv.sell;
	inv.order_id = $scope.inventories.length; 
	$scope.inventories.unshift({$edit:false, $new:true});
	
	// save
	$scope.disable_refresh = false;
	$scope.wsaleStorage.save(
	    $scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
	
	$timeout.cancel($scope.timeout_auto_save);

	$scope.focus_good_or_barcode(); 
    };

    $scope.calc_discount = function(inv){
	if (inv.pid !== -1 && inv.promotion.rule_id === 0){
	    return inv.promotion.discount;
	} else {
	    return inv.discount;
	}
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer)
	    || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
		false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	};

	inv.fdiscount = $scope.calc_discount(inv); 
	inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);

	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice; 
	
	if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.amounts         = [{cid:0, size:0}];
	    if ($scope.setting.barcode_mode) {
		inv.sell = 1;
		$scope.auto_save_free(inv);
	    }
	} else {
	    var promise = diabloPromise.promise; 
	    var calls = [promise(diabloFilter.list_purchaser_inventory,
				 {style_number: inv.style_number,
				  brand:        inv.brand_id,
				  shop:         $scope.select.shop.id
				 })()];
	    
	    $q.all(calls).then(function(data){
		// console.log(data);
		// data[0] is the inventory belong to the shop
		// data[1] is the last sale of the shop
		if (data.length === 0 ){
		    diabloUtilsService.response(
			false, "销售开单", "开单失败：" + wsaleService.error[2194]);
		    return; 
		};
		
		var shop_now_inv = data[0];
		
		var order_sizes = diabloHelp.usort_size_group(inv.s_group, filterSizeGroup);
		var sort = diabloHelp.sort_stock(shop_now_inv, order_sizes, filterColor);
		
		inv.total   = sort.total;
		inv.sizes   = sort.size;
		inv.colors  = sort.color;
		inv.amounts = sort.sort; 

		// console.log(inv.sizes);
		// console.log(inv.colors);
		// console.log(inv.amounts); 

		if(inv.free === 0){
		    inv.free_color_size = true;
		    inv.amounts         = [{cid:0, size:0}];
		    if ($scope.setting.barcode_mode) {
			inv.sell = 1;
			$scope.auto_save_free(inv);
		    }
		} else{
		    inv.free_color_size = false; 
		    if ($scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
			// get color, size from barcode
			// console.log(inv.bcode);
			// console.log(inv.full_bcode);
			// console.log(inv.full_bcode.length - inv.bcode.length);
			var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
			console.log(color_size);

			var bcode_color = wsaleUtils.to_integer(color_size.substr(0, 3));
			var bcode_size_index = wsaleUtils.to_integer(color_size.substr(3, color_size.length));
			
			var bcode_size = bcode_size_index === 0 ? diablo_free_size : size_to_barcode[bcode_size_index];
			// console.log(bcode_color);
			// console.log(bcode_size);
			angular.forEach(inv.amounts, function(a) {
			    // console.log(a.cid, inv.colors);
			    var color;
			    for (var i=0, l=inv.colors.length; i<l; i++) {
				if (a.cid === inv.colors[i].cid) {
				    color = inv.colors[i];
				    break;
				}
			    } 
			    // console.log(color); 
			    if (angular.isDefined(color)
				&& color.bcode === bcode_color && a.size === bcode_size) {
				a.sell_count = 1;
				a.focus = true;
			    }
			});
		    } else {
			// inv.amounts[0].focus = true;
			for (var i=0, l=inv.amounts.length; i<l; i++) {
			    var a = inv.amounts[i]; 
			    if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
				a.focus = true;
			    }
			}
		    }
		    
		    var after_add = function(){
			inv.$edit = true;
			inv.$new = false;
			inv.order_id = $scope.inventories.length;
			if (angular.isUndefined(inv.full_bcode)) {
			    inv.full_bcode = inv.bcode;
			}
			$scope.inventories.unshift({$edit:false, $new:true}); 
			$scope.disable_refresh = false;

			$scope.wsaleStorage.save(
			    $scope.inventories.filter(function(r){return !r.$new}));
			
			$scope.re_calculate();
			$scope.focus_good_or_barcode(); 
		    };
		    
		    var callback = function(params){
			// console.log(params);
			var result  = add_callback(params);
			// console.log(result);
			inv.amounts    = result.amounts;
			inv.sell       = result.sell;
			inv.fdiscount  = result.fdiscount;
			inv.fprice     = result.fprice;
			after_add();
		    };

		    // set auto focus
		    // for (var i=0, l=inv.amounts.length; i<l; i++) {
		    // 	var a = inv.amounts[i];
		    // 	console.log(a.sell_count);
		    // 	if (a.sell_count > 0) {
		    // 	    a.focus = true;
		    // 	    break;
		    // 	} else {
		    // 	    if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
		    // 		a.focus = true;
		    // 		break;
		    // 	    }
		    // 	} 
		    // }
		    
		    var modal_size = diablo_valid_dialog(inv.sizes);
		    var large_size = modal_size === 'lg' ? true : false;
		    var payload = {
			fdiscount:      inv.fdiscount,
			fprice:         inv.fprice,
			sizes:          inv.sizes,
			large_size:     large_size,
			colors:         inv.colors,
			amounts:        inv.amounts,
			path:           inv.path,
			get_amount:     get_amount,
			valid_sell:     valid_sell,
			valid:          valid_all_sell,
			right:          $scope.right};

		    diabloUtilsService.edit_with_modal(
			"wsale-new.html",
			modal_size,
			callback,
			$scope,
			payload); 
		}; 
	    });
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
	
	// reorder
	for(var i=1, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].order_id = l - i;
	}

	if ($scope.inventories.length > 1){
	    $scope.wsaleStorage.save(
		$scope.inventories.filter(function(r){return !r.$new})); 
	} else {
	    $scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	}
	
	$scope.re_calculate();
	
	// promotion
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    if (inv.order_id === $scope.show_promotions[i].order_id){
		break;
	    }
	}

	$scope.show_promotions.splice(i, 1);
	for (var i=0, l=$scope.show_promotions.length; i<l; i++){
	    $scope.show_promotions[i].order_id = l - i; 
	}

	// $scope.disable_focus();
	// $scope.focus_good_or_barcode();
    };

    /*
     * lookup inventory 
     */
    $scope.inventory_detail = function(inv){
	var payload = {sizes:        inv.sizes,
		       colors:       inv.colors,
		       fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount};
	diabloUtilsService.edit_with_modal(
	    "wsale-detail.html", undefined, undefined, $scope, payload)
    };

    /*
     * update inventory
     */
    $scope.update_inventory = function(inv){
	console.log(inv);
	inv.$update = true; 
	// inv.fdiscount = $scope.calc_discount(inv); 
	// inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);
	
	if (inv.free_color_size){
	    inv.free_update = true; 
	    return;
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result);
	    inv.amounts    = result.amounts;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice; 
	    // save
	    $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate(); 
	};

	var modal_size = diablo_valid_dialog(inv.sizes);
	var large_size = modal_size === 'lg' ? true : false;
	
	var payload = {fdiscount:    inv.fdiscount,
		       fprice:       inv.fprice,
		       sizes:        inv.sizes,
		       large_size:   large_size,
		       colors:       inv.colors, 
		       amounts:      inv.amounts,
		       path:         inv.path,
		       get_amount:   get_amount, 
		       valid_sell:   valid_sell,
		       valid:        valid_all_sell,
		       right:        $scope.right}; 
	diabloUtilsService.edit_with_modal(
	    "wsale-new.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false; 
	inv.amounts[0].sell_count = inv.sell; 
	// save
	$scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv);
	$timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;
	inv.sell      = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	$scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode(); 
    };

    $scope.auto_save_free = function(inv){
	$timeout.cancel($scope.timeout_auto_save);
	
	var sell = wsaleUtils.to_integer(inv.sell);
	if (sell === 0) return
	if (angular.isUndefined(inv.style_number)) return;

	if ($scope.setting.check_sale && sell > inv.total){
	    if (angular.isDefined(inv.form.sell)) {
		inv.form.sell.$invalid = true;
		inv.form.sell.$pristine = false; 
	    }
	    inv.invalid_sell = true;
	    
	    return;
	}

	if (diablo_no === $scope.setting.negative_sale && sell < 0) {
	    if (angular.isDefined(inv.form.sell)) {
		inv.form.sell.$invalid = true;
		inv.form.sell.$pristine = false;
	    }
	    inv.invalid_sell = true;
	    return;
	};
	
	$scope.timeout_auto_save = $timeout(function(){
	    // console.log(inv); 
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    }; 

	    if (!inv.$new && inv.free_update){
		$scope.save_free_update(inv); 
	    }
	}, 1000); 
    };
};

function wsaleNewDetailProvide(
    $scope, $routeParams, $location, dateFilter, diabloUtilsService,
    localStorageService, diabloFilter, wsaleService,
    user, filterEmployee, base){
    $scope.shops     = user.sortShops.concat(user.sortBadRepoes);
    $scope.shopIds   = user.shopIds.concat(user.badrepoIds);
    $scope.records   = [];
    
    $scope.goto_page = diablo_goto_page;
    $scope.f_add     = diablo_float_add;
    $scope.f_sub     = diablo_float_sub;
    $scope.f_mul     = diablo_float_mul;
    $scope.round     = diablo_round;
    $scope.css       = diablo_stock_css;
    
    $scope.total_items   = 0;
    $scope.default_page = 1; 
    $scope.disable_print = false;
    $scope.current_page = $scope.default_page;

    // var im_print = function(shopId){
    // 	return wsaleUtils.im_print(shopId, base); 
    // };

    // var print_mode = 
    // console.log($scope.im_print); 
    /*
     * authen
     */
    $scope.shop_right = {
	update_w_sale: wsaleUtils.authen_shop(user.type, user.shop, 'update_w_sale'),
	check_w_sale: wsaleUtils.authen_shop(user.type, user.shop, 'check_w_sale'),
	master:rightAuthen.authen_master(user.type),
	show_stastic: rightAuthen.authen_master(user.type) 
    }; 

    /*
     * hidden
     */
    $scope.show = {base:false, action:false, balance:false}; 
    $scope.toggle_base = function(){$scope.show.base = !$scope.show.base;}; 
    $scope.toggle_action = function(){$scope.show.action = !$scope.show.action;}; 
    $scope.toggle_balance = function(){$scope.show.balance = !$scope.show.balance;}; 
    
    /* 
     * filter operation
     */

    var now = $.now();
    // var shopId = $scope.shopIds.length === 1 ? $scope.shopIds[0]: -1;
    // var show_sale_days = wsaleUtils.show_sale_day(shopId, base);
    var show_sale_days = user.sdays;
    var storage = localStorageService.get(diablo_key_wsale_trans);

    if (angular.isDefined(storage) && storage !== null){
	// console.log(storage);
    	$scope.filters      = storage.filter; 
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else{
	$scope.filters = [];
	// $scope.qtime_start = diablo_set_date(wsaleUtils.start_time(shopId, base, now, dateFilter));
	$scope.qtime_start = now;
	$scope.qtime_end = now;
    };

    //console.log($scope.qtime_start);
    $scope.time = wsaleUtils.correct_query_time(
	$scope.shop_right.master,
	show_sale_days,
	$scope.qtime_start,
	$scope.qtime_end,
	diabloFilter);
    
    $scope.match_rsn = function(viewValue) {
	return diabloFilter.match_wsale_rsn_of_all(
	    diablo_rsn_all,
	    viewValue,
	    wsaleUtils.format_time_from_second($scope.time, dateFilter));
    };

    $scope.match_retailer = function(viewValue) {
	return wsaleUtils.match_retailer_phone(viewValue, diabloFilter);
    };
    
    // initial
    diabloFilter.reset_field();
    diabloFilter.add_field("shop",        $scope.shops);
    diabloFilter.add_field("employee",    filterEmployee); 
    diabloFilter.add_field("retailer",    $scope.match_retailer); 
    diabloFilter.add_field("rsn",         $scope.match_rsn);
    diabloFilter.add_field("check_state", wsaleService.check_state);
    diabloFilter.add_field("comment",     wsaleService.check_comment);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    console.log($scope.filter);
    console.log($scope.prompt);

    
    
    $scope.sequence_pagination = wsaleUtils.sequence_pagination(-1, base);
    
    /*
     * pagination 
     */
    $scope.colspan = 19;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size(); 

    // console.log($routeParams);
    var return_back_page = angular.isDefined($routeParams.page) ? true : false;
    if (return_back_page) $location.path("/new_wsale_detail", false);
    
    // if (angular.isDefined(back_page)){
    // 	$scope.current_page = back_page;
    // };

    $scope.do_search = function(page){
	console.log(page); 
	$scope.current_page = page; 
	// console.log($scope.time); 
	if (!$scope.shop_right.master && show_sale_days !== diablo_nolimit_day){
	    var diff = now - diablo_get_time($scope.time.start_time);
	    // console.log(diff);
	    // $scope.time.end_time = now; 
	    if (diff - diablo_day_millisecond * show_sale_days > diablo_day_millisecond)
	    	$scope.time.start_time = now - show_sale_days * diablo_day_millisecond;

	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now;
	}
	
	// save condition of query
	wsaleUtils.cache_page_condition(
	    localStorageService,
	    diablo_key_wsale_trans,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now); 

	if (page !== $scope.default_page) {
	    var stastic = localStorageService.get("wsale-trans-stastic");
	    // console.log(stastic);
	    $scope.total_items       = stastic.total_items;
	    $scope.total_amounts     = stastic.total_amounts;
	    $scope.total_spay        = stastic.total_spay;
	    $scope.total_rpay        = stastic.total_rpay;
	    // $scope.total_hpay        = stastic.total_hpay;
	    $scope.total_cash        = stastic.total_cash;
	    $scope.total_card        = stastic.total_card;
	    $scope.total_wxin        = stastic.total_wxin;
	    $scope.total_withdraw    = stastic.total_withdraw;
	    $scope.total_ticket      = stastic.total_ticket;
	    $scope.total_balance     = stastic.total_balance;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0
		    ? undefined : $scope.shopIds; 
	    }

	    var items    = $scope.items_perpage;
	    var page_num = page; 
	    // if (angular.isDefined(back_page) && $scope.sequence_pagination === diablo_yes){
	    // 	items = page * $scope.items_perpage;
	    // 	$scope.records = []; 
	    // 	page_num = 1;
	    // 	back_page = undefined;
	    // }
	    if ($scope.sequence_pagination === diablo_yes){
		items = page * $scope.items_perpage;
		page_num = 1;
		$scope.records = []; 
	    };
	    
	    wsaleService.filter_w_sale_new(
		$scope.match, search, page_num, items
	    ).then(function(result){
		console.log(result);
		if (page === 1) {
		    $scope.total_items       = result.total;
		    $scope.total_amounts     = result.t_amount;
		    $scope.total_spay        = result.t_spay;
		    $scope.total_rpay        = result.t_rpay;
		    $scope.total_cash        = result.t_cash;
		    $scope.total_card        = result.t_card;
		    $scope.total_wxin        = result.t_wxin;
		    $scope.total_withdraw    = result.t_withdraw;
		    $scope.total_ticket      = result.t_ticket;
		    $scope.total_balance     = result.t_balance;

		    $scope.records = [];
		    $scope.save_stastic();
		}
		
		// if (page === 1 && angular.isUndefined(back_page)){
		//     $scope.total_items       = result.total;
		//     $scope.total_amounts     = result.t_amount;
		//     $scope.total_spay        = result.t_spay;
		//     $scope.total_rpay        = result.t_rpay;
		//     $scope.total_cash        = result.t_cash;
		//     $scope.total_card        = result.t_card;
		//     $scope.total_withdraw    = result.t_withdraw;
		//     $scope.total_balance     = result.t_balance;

		//     $scope.records = [];
		// }
		
		// console.log($scope); 
		angular.forEach(result.data, function(d){
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    // d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.has_pay  = d.should_pay;
		    d.should_pay = wsaleUtils.to_decimal(d.should_pay + d.verificate);
		    // charge
		    d.left_balance = wsaleUtils.to_decimal(d.balance - d.withdraw); 
		    // if (d.type === diablo_charge){
		    // 	d.left_balance += d.cbalance + d.sbalance;
		    // } 
		});

		if ($scope.sequence_pagination === diablo_no){
		    $scope.records = result.data; 
		    diablo_order_page(
			page, $scope.items_perpage, $scope.records);
		} else {
		    diablo_order(
			result.data,
			(page_num - 1) * $scope.items_perpage + 1);
		    $scope.records = $scope.records.concat(result.data); 
		} 
	    })
	})
    };

    // $scope.do_search($scope.current_page);
    
    $scope.page_changed = function(){
    	$scope.do_search($scope.current_page);
    };

    $scope.auto_pagination = function(){
	if ($scope.sequence_pagination === diablo_no){
	    return;
	} else {
	    $scope.current_page += 1;
	    $scope.do_search($scope.current_page);
	} 
    };

    // console.log($scope.current_page, $scope.default_page);
    if ($scope.current_page !== $scope.default_page){
	$scope.do_search($scope.current_page); 
    } else if (return_back_page) {
	$scope.do_search($scope.current_page);
    }

    $scope.save_stastic = function(){
	localStorageService.remove("wsale-trans-stastic");
	localStorageService.set(
	    "wsale-trans-stastic",
	    {total_items:       $scope.total_items,
	     total_amounts:     $scope.total_amounts,
	     total_spay:        $scope.total_spay,
	     total_rpay:        $scope.total_rpay,
	     total_cash:        $scope.total_cash,
	     total_card:        $scope.total_card,
	     total_wxin:        $scope.total_wxin,
	     total_withdraw:    $scope.total_withdraw,
	     total_ticket:      $scope.total_ticket,
	     total_balance:     $scope.total_balance,
	     t:                 now});
    };
    
    $scope.rsn_detail = function(r){
	// console.log(r);
	// $scope.save_stastic(); 
	diablo_goto_page(
	    "#/wsale_rsn_detail/"
		+ r.rsn
		+ "/" + $scope.current_page.toString()
		// + "/" + r.shop_id.toString()
	);
    };

    $scope.update_detail = function(r){
	// $scope.save_stastic();
	if (r.type === 0){
	    diablo_goto_page(
		'#/update_wsale_detail/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	} else {
	    diablo_goto_page(
		'#/update_wsale_reject/'
		    + r.rsn + "/" + $scope.current_page.toString()); 
	}
    };

    var dialog = diabloUtilsService;
    $scope.check_detail = function(r){
	// console.log(r);
	wsaleService.check_w_sale_new(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true,
		    "销售单审核",
		    "销售单审核成功！！单号：" + state.rsn,
		    $scope, function(){r.state = 1})
	    	return;
	    } else{
	    	dialog.response(
	    	    false,
		    "销售单审核",
	    	    "销售单审核失败：" + wsaleService.error[state.ecode]);
	    }
	})
    };

    $scope.uncheck_detail = function(r){
	// console.log(r);
	wsaleService.uncheck_w_sale_new(r.rsn, diablo_uncheck).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "销售单反审", "销售单反审成功！！单号：" + state.rsn,
		    $scope, function(){r.state = 0})
	    	return;
	    } else{
	    	diabloUtilsService.response(
	    	    false, "销售单反审",
	    	    "销售反审失败：" + wsaleService.error[state.ecode]);
	    }
	})
    };

    $scope.delete_detail = function(r){
	console.log(r);
	wsaleService.delete_w_sale_new(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "销售单删除", "销售单删除成功！！单号：" + state.rsn,
		    $scope, function(){$scope.do_search($scope.current_page)})
	    	return;
	    } else{
	    	dialog.response(
	    	    false, "销售单删除",
	    	    "销售删除失败：" + wsaleService.error[state.ecode]);
	    }
	});
    };
    

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop)
		|| !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0
		    ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    wsaleService.csv_export(wsaleService.export_type.trans, search)
		.then(function(result){
	    	    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			true,
			    "文件导出成功",
			    "创建文件成功，请点击确认下载！！", undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			diablo.response(
			false,
			    "文件导出失败",
			    "创建文件失败："
				+ wsaleService.error[result.ecode]);
		    } 
		}); 
	}) 
    };
};

// wsaleApp.controller("wsaleCtrl", function(
//     $scope, localStorageService){
//     diablo_remove_wsale_local_storage(localStorageService); 
// });
