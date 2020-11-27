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
	
	var sysretailer = {"filterSysRetailer": function(diabloFilter){
    	    return diabloFilter.get_sys_wretailer()}};

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}};

	var promotion = {"filterPromotion": function(diabloFilter){
	    return diabloFilter.get_promotion()}};

	var commision = {"filterCommision": function(diabloFilter){
	    return diabloFilter.get_commision()}};

	var score = {"filterScore": function(diabloNormalFilter){
	    return diabloNormalFilter.get_score()}};
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}}; 
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var charge = {"filterCharge": function(diabloNormalFilter){
	    return diabloNormalFilter.get_charge()}};

	var level = {"filterLevel": function(diabloFilter){
	    return diabloFilter.get_retailer_level()}};

	var ctype = {"filterCType": function(diabloFilter) {
	    return diabloFilter.list_good_ctype()}};

	var plan = {"filterTicketPlan": function(diabloFilter){
            return diabloFilter.get_ticket_plan()}};

	var region = {"filterRegion": function(diabloNormalFilter){
	    return diabloNormalFilter.get_region()}};
	
	$routeProvider. 
	    when('/new_wsale', {
		templateUrl: '/private/wsale/html/new_wsale.html',
		controller: 'wsaleNewCtrl',
		resolve: angular.extend(
		    {}, user, promotion, commision, charge, score, sysretailer, employee, s_group, brand, type, color, level, plan, base)
	    }).
	    when('/new_wsale_detail/:page?', {
		templateUrl: '/private/wsale/html/new_wsale_detail.html',
		controller: 'wsaleNewDetailCtrl',
		resolve: angular.extend({}, user, employee, plan, base) 
	    }).
	    when('/update_wsale_detail/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/update_wsale_detail.html',
		controller: 'wsaleUpdateDetailCtrl',
		resolve: angular.extend(
		    {}, user, promotion, commision, score, sysretailer, employee, s_group, brand, color, type, level, base)
	    }). 
	    when('/wsale_rsn_detail/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/wsale_rsn_detail.html',
		controller: 'wsaleRsnDetailCtrl',
		resolve: angular.extend(
		    {}, user, promotion, commision, score, sysretailer, brand, employee, firm, s_group, type, color, ctype, base)
	    }).
	    when('/wsale_print_note/:note?', {
		templateUrl: '/private/wsale/html/wsale_print_note.html',
		controller: 'wsalePrintNoteCtrl',
		resolve: angular.extend({}, user, brand, firm, s_group, type, color, base)
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
		    {}, user, promotion, commision, score, sysretailer, brand, type, employee, s_group, color, level, base) 
	    }).
	    when('/update_wsale_reject/:rsn?/:ppage?', {
		templateUrl: '/private/wsale/html/update_wsale_reject.html',
		controller: 'wsaleUpdateRejectCtrl',
		resolve: angular.extend(
		    {}, user, promotion, commision, score, sysretailer, employee, s_group, brand, color, type, level, base)
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
	    when('/employee_evaluation', {
		templateUrl: '/private/wsale/html/wsale_employee_evaluation.html',
		controller: 'wsaleEmployeeEvaluationCtrl',
		resolve: angular.extend({}, employee, user) 
	    }).
	    when('/list_daily_cost', {
		templateUrl: '/private/wsale/html/list_daily_cost.html',
		controller: 'dailyCostCtrl',
		resolve: angular.extend({}, region, user) 
	    }).
	    when('/list_pay_scan', {
		templateUrl: '/private/wsale/html/pay_scan_detail.html',
		controller: 'payScanCtrl',
		resolve: angular.extend({}, user) 
	    }). 
	    otherwise({
		templateUrl: '/private/wsale/html/new_wsale_detail.html',
		controller: 'wsaleNewDetailCtrl',
		resolve: angular.extend({}, user, employee, plan, base)
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
	    2197: "核销超过限定金额，请重新填写核销金额！！",
	    2021: "库存不足，请检测库存后再销售！！",
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
	    2697: "没有要退货的货品或该货品已退货，请重新选择货品！！",
	    2698: "会员提取金额超过系统上限！！",
	    2699: "修改前后信息一致，请重新编辑修改项！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	this.rsn_title = ["开单明细", "退货明细", "销售明细"];

	this.direct = {wsale: 0, wreject: 1}; 
	this.wsale_mode = [{title: "款号模式"}, {title: "图片模式"}, {title: "条码模式"}]; 
	this.check_state = [{name:"未审核", id:0},	{name:"已审核", id:1}];
	this.check_comment = [{name:"不为空", id:0}];
	this.export_type = {trans:0, trans_note:1};
	this.pay_type = [{name:"微信", id:0}, {name:"支付宝", id:1}];
	this.pay_state = [{name:"支付成功", id:0},
			  {name:"支付失败", id:1},
			  {name:"支付中",   id:2}];
	

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

	this.filter_employee_evaluation = function(match, fields, currentPage, itemsPerpage) {
	    return http.save(
		{operation: "filter_employee_evaluation"},
		{match:  angular.isDefined(match) ? match.op : undefined,
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

	/*
	 * daily cost
	 */
	this.new_daily_cost = function(cost) {
	    return http.save({operation:"new_daily_cost"}, cost).$promise;
	};

	this.update_daily_cost = function(cost) {
	    return http.save({operation:"update_daily_cost"}, cost).$promise;
	};
	
	this.list_daily_cost = function(match, fields, currentPage, itemsPerpage) {
	    return http.save(
		{operation: "list_daily_cost"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	/*
	 * print
	 */
	this.print_w_sale_note = function(e_type, condition) {
	    return http.save(
		{operation: "print_w_sale_note"},
		{fields:condition, e_type: e_type}).$promise;
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
    $scope, $q, $timeout, $interval, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, wsaleService, wsaleGoodService,
    user, filterPromotion, filterCommision, filterCharge, filterScore,
    filterSysRetailer, filterEmployee,
    filterSizeGroup, filterType, filterColor, filterLevel, filterTicketPlan, base){
    // console.log(base);
    // console.log(filterLevel);
    $scope.promotions = filterPromotion;
    $scope.commisions = filterCommision;
    // console.log($scope.commisions); 
    $scope.scores     = filterScore;
    $scope.draws      = filterCharge.filter(function(d){return d.type === diablo_withdraw});
    $scope.ticketPlans = filterTicketPlan.filter(function(p) {
	return !p.deleted && p.mbalance === diablo_invalid;
    }).map(function(p) {
	return {id:       p.id,
		rule:     p.rule,
		name:     p.name + "-" + p.balance + "元",
		balance:  p.balance,
		mbalance: p.mbalance,
		effect:   p.effect,
		expire:   p.expire,
		stime:    p.stime,
		etime:    p.etime,
		scount:   p.scount}
    });
    // console.log(filterCharge);
    $scope.charges = filterCharge.filter(function(d) {
	return d.type === diablo_charge
	    && d.deleted === diablo_no
	    && (d.rule_id === diablo_times_charge || d.rule_id === diablo_giving_charge)}); 
    $scope.tcharges = $scope.charges.filter(function(d){return d.rule_id === diablo_times_charge});
    $scope.mcharges = $scope.charges.filter(function(d){return d.rule_id === diablo_giving_charge});
    // console.log($scope.tcharges);
    // console.log($scope.mcharges);
    // $scope.levels     = filterLevel; 
    
    // console.log($scope.draws);
    // console.log($scope.scores);
    
    $scope.pattern    = {
	money:        diabloPattern.decimal_2,
	sell:         diabloPattern.integer_except_zero,
	discount:     diabloPattern.discount,
	barcode:      diabloPattern.number,
	name:         diabloPattern.chinese_name,
	comment:      diabloPattern.comment,
	tel_mobile:   diabloPattern.tel_mobile
    };
    
    // $scope.timeout_auto_save = undefined;
    $scope.interval_per_5_minute = undefined;
    $scope.round  = diablo_round;
    $scope.timer_of_print = undefined;
    $scope.calendar = require('diablo-calendar');
    
    $scope.today = function(){return $.now();}; 
    $scope.back  = function(){diablo_goto_page("#/new_wsale_detail");};

    $scope.setting = {q_backend:true, check_sale:true, negative_sale:false};

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight();
    
    // console.log($scope.right);
    $scope.focus_attr = {style_number:false,
			 barcode:false,
			 sell:false,
			 cash:false,
			 card:false,
			 wxin:false,
			 aliPay:false};
    
    $scope.auto_focus = function(attr){
	for (var o in $scope.focus_attr){
	    $scope.focus_attr[o] = false;
	}
	$scope.focus_attr[attr] = true; 
    };
    
    $scope.disable_focus = function() {
	for (var o in $scope.focus_attr){
	    $scope.focus_attr[o] = false;
	} 
    };

    $scope.disable_start_sale = function() {
	return $scope.inventories.length === 0;
    };

    
    // $scope.key_action = function(key){
    // 	console.log(key); 
    // 	if (key === 113)
    // 	    $scope.auto_focus("cash")
	
    // 	else if (key === 114)
    // 	    $scope.auto_focus("wxin")

    // 	else if (key === 117) 
    // 	    $scope.auto_focus("card") 
    // };
    
    // wsaleGoodService.set_brand(filterBrand);
    wsaleGoodService.set_type(filterType);
    wsaleGoodService.set_size_group(filterSizeGroup);
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
    $scope.retailer_types  = diablo_retailer_types.filter(function(t) {
	return t.id !== 2;
    });
    
    $scope.f_add           = diablo_float_add;
    $scope.f_sub           = diablo_float_sub;
    $scope.f_mul           = diablo_float_mul;
    $scope.f_discount      = diablo_discount;
    $scope.wsale_mode      = wsaleService.wsale_mode;
    $scope.face            = window.face;
    $scope.show_promotions = [];
    $scope.disable_refresh = true;
    $scope.has_withdrawed  = false;
    $scope.has_gift_ticket = false;
    $scope.solar2lunar = function(date) {
	// console.log(date);
	return $scope.calendar.solar2lunar(date.year, date.month, date.day);
    };
    
    $scope.select = {
	rsn:  undefined,
	cash: undefined,
	card: undefined,
	wxin: undefined,
	aliPay: undefined,
	withdraw: undefined,
	limitdraw: undefined,
	unlimitdraw: undefined,
	draw_cards:   undefined, 
	
	ticket_batchs: [],
	ticket_balance: 0,
	ticket_score: 0, 
	ticket_sid: diablo_invalid_index,
	ticket_custom: diablo_invalid_index,

	sysVip:          diablo_yes,
	total:           0,
	oil:             0,
	noTicketBalance: 0,
	abs_total:       0,
	has_pay:         0,
	should_pay:   0,
	can_draw:     0,
	base_pay:     0,
	abs_pay:      0,
	score:        0,
	pscores:      [],
	charge:       0,
	recharge:     0,
	surplus:      0,
	left_balance: 0,
	// sid:          diablo_invalid_index,
	pay_order:    diablo_invalid_index,
	datetime:     $scope.today(),
	lunar:        $scope.solar2lunar(diablo_get_now_full_date()),
    };
    console.log($scope.select);

    // init
    $scope.sale = {barcode:undefined, style_number:undefined};
    $scope.inventories = [];

    $scope.color_negative_sale = function(negative) {
    	return negative ? "bg-red" : "";
    };
    
    var dialog = diabloUtilsService; 
    
    var get_setting = function(shopId){
	$scope.setting.check_sale    = wsaleUtils.check_sale(shopId, base);
	$scope.setting.negative_sale = wsaleUtils.negative_sale(shopId, base);
	$scope.setting.no_vip        = wsaleUtils.no_vip(shopId, base);
	$scope.setting.q_backend     = $scope.q_typeahead(shopId);
	$scope.setting.round         = wsaleUtils.round(shopId, base);
	$scope.setting.solo_retailer = wsaleUtils.solo_retailer(shopId, base);
	$scope.setting.semployee     = wsaleUtils.s_employee(shopId, base);
	//$scope.setting.cake_mode     = wsaleUtils.cake_mode(shopId, base);
	$scope.setting.barcode_mode  = wsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = wsaleUtils.barcode_auto(shopId, base);
	$scope.setting.draw_score    = wsaleUtils.draw_score(shopId, base);
	$scope.setting.draw_region   = wsaleUtils.draw_region(shopId, base);
	$scope.setting.hide_fixed_stock = wsaleUtils.hide_fixed_stock(shopId, base); 
	$scope.setting.vip_mode      = wsaleUtils.vip_mode(shopId, base);
	$scope.setting.vip_discount_mode = wsaleUtils.to_integer($scope.setting.vip_mode.charAt(0));
	// console.log($scope.setting.vip_discount_mode);
	// $scope.setting.gift_sale     = wsaleUtils.gift_sale(shopId, base);

	var scan_mode = wsaleUtils.scan_only(shopId, base);
	$scope.setting.scan_only     = wsaleUtils.to_integer(scan_mode.charAt(0));
	$scope.setting.focus_style_number = wsaleUtils.to_integer(scan_mode.charAt(4));
					     
	$scope.setting.maling_rang   = wsaleUtils.maling_rang(shopId, base);
	$scope.setting.type_sale     = wsaleUtils.type_sale(shopId, base);

	$scope.setting.shop_mode     = wsaleUtils.shop_mode(shopId, base);

	var sale_mode = wsaleUtils.sale_mode(shopId, base);
	// $scope.setting.print_perform  = wsaleUtils.to_integer(sale_mode.charAt(3));
	$scope.setting.hide_charge    = wsaleUtils.to_integer(sale_mode.charAt(5));
	$scope.setting.hide_pwd       = wsaleUtils.to_integer(sale_mode.charAt(9));
	$scope.setting.show_wprice    = wsaleUtils.to_integer(sale_mode.charAt(14));
	$scope.setting.score_discount = wsaleUtils.to_integer(sale_mode.charAt(16)) * 10
	    + wsaleUtils.to_integer(sale_mode.charAt(17));
	$scope.setting.gift_direct    = wsaleUtils.to_integer(sale_mode.charAt(18));
	$scope.setting.gift_ticket_on_sale = wsaleUtils.to_integer(sale_mode.charAt(19));
	$scope.setting.charge_with_special = wsaleUtils.to_integer(sale_mode.charAt(20));
	$scope.setting.multi_ticket = wsaleUtils.to_integer(sale_mode.charAt(21));
	$scope.setting.pay_scan = wsaleUtils.to_integer(sale_mode.charAt(24));
	$scope.setting.disableWithDraw = wsaleUtils.to_integer(sale_mode.charAt(25));
	$scope.setting.interval_print = wsaleUtils.to_integer(sale_mode.charAt(27));
	$scope.setting.fixed_mode = wsaleUtils.to_integer(sale_mode.charAt(28));
	$scope.setting.trans_count = wsaleUtils.to_integer(sale_mode.charAt(29));
	$scope.setting.pay_scan_use = wsaleUtils.to_integer(sale_mode.charAt(32));

	angular.extend($scope.setting, wsaleUtils.gift_sale(shopId, base));
	// $scope.setting.print_discount = wsaleUtils.to_integer(sale_mode.charAt(15));

	$scope.print_setting = {
	    print_discount: wsaleUtils.yes_default(sale_mode.charAt(15)),
	    print_perform:  wsaleUtils.to_integer(sale_mode.charAt(3)),
	    cake_mode:      wsaleUtils.cake_mode(shopId, base),
	    comments:       wsaleUtils.comment(shopId, base),
	    head_seperater: wsaleUtils.to_integer(sale_mode.charAt(23)),
	    print_score:    wsaleUtils.yes_default(sale_mode.charAt(26))
	};


	if ($scope.p_mode($scope.select.shop.id) === diablo_frontend){
	    var print_access = wsaleUtils.print_num($scope.select.shop.id, base); 
	    if (needCLodop()) loadCLodop(print_access.protocal); 
	    $scope.p_num = print_access.common;
	}
	
	
	if (diablo_no === $scope.print_setting.cake_mode) {
	    $scope.vpays = [0].concat(diablo_num2arrary($scope.setting.maling_rang)
				      .concat(diablo_num2arrary(-3)));
	} else {
	    $scope.vpays = wsaleService.cake_vpays;
	}

	$scope.select.verificate = $scope.vpays[0];
	// console.log($scope.vpays); 
	console.log($scope.setting);

	// get valid levels
	// console.log(shopId);
	$scope.levels = filterLevel.filter(function(l) {
	    return l.shop_id === shopId;
	})

	if ($scope.levels.length === 0) {
	    $scope.levels = filterLevel.filter(function(l) {
		return l.shop_id === diablo_default_shop;
	    })
	}

	// console.log($scope.levels);
    };

    // var isVip = function() {
    // 	return  $scope.select.retailer.id !== $scope.setting.no_vip
    // 	    && $scope.sysRetailers.filter(function(r) {return $scope.select.retailer.id === r.id}).length === 0
    // };
    
    // shops
    // console.log(user.sortShops);
    $scope.shops = user.sortShops.filter(function(s) {return s.deleted===0});
    // $scope.shops = user.sortShops;
    // console.log($scope.shops);
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0];
	get_setting($scope.select.shop.id);
	// console.log($scope.face($scope.setting.shop_mode));
    }

    $scope.focus_good_or_barcode = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.scan_only) {
	    $scope.auto_focus('barcode');
	} else {
	    if ($scope.setting.barcode_mode && !$scope.setting.focus_style_number) {
		// document.getElementById("barcode").focus();
		$scope.auto_focus('barcode'); 
	    } else {
		$scope.auto_focus('style_number');
	    }
	} 
    };

    $scope.focus_by_element = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.scan_only) {
	    document.getElementById("barcode").focus();
	} else {
	    if ($scope.setting.barcode_mode && !$scope.setting.focus_style_number) {
		document.getElementById("barcode").focus();
	    }
	    else {
		document.getElementById("snumber").focus();
	    }
	} 
    };
    
    $scope.focus_good_or_barcode();
    console.log($scope.focus_attr);

    $scope.change_shop = function(){
	get_setting($scope.select.shop.id);	
	// $scope.match_all_w_inventory(); 
	$scope.get_employee();
	$scope.reset_retailer();

	$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	$scope.wsaleStorage.change_shop($scope.select.shop.id);
	// $scope.wsaleStorage.change_employee($scope.select.employee.id);
	$scope.refresh(); 
    };
    
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
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.select.shop.id,
	    $scope.setting.solo_retailer);
    };
    
    $scope.set_retailer = function(){
    	if ($scope.select.retailer.type_id === diablo_charge_retailer){
    	    $scope.select.surplus = wsaleUtils.to_decimal(
		wsaleUtils.to_float($scope.select.retailer.balance));
    	    $scope.select.left_balance = $scope.select.surplus;
    	}
    	$scope.select.o_retailer = $scope.select.retailer;
    	$scope.select.ticket_batchs = [];
    	$scope.select.ticket_balance = 0;
    };
    
    $scope.on_select_retailer = function(item, model, label){
	// console.log(item);
	console.log($scope.select.retailer);
	$scope.set_retailer();
	$scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	$scope.wsaleStorage.change_retailer($scope.select.retailer.id);
	// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.select.sysVip = !wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers);
	
	// console.log($scope.select.sysVip);
	if ($scope.setting.vip_discount_mode === diablo_vip_sale_by_balance && !$scope.select.sysVip) {
	    $scope.select.verificate = wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels);
	}
	
	$scope.re_calculate();
	
	// image mode, refresh image
	if ($scope.wsale_mode[1].active){
	    $scope.page_changed($scope.current_page); 
	}
    };

    // $scope.check_verificate = function(retailer) {
    // 	if (angular.isDefined($scope.select.retailer)
    // 	    && angular.isObject($scope.select.retailer)
    // 	    && $scope.select.retailer.hasOwnProperty('type_id')) {
	    
    // 	}
    // 	// console.log(retailer); 
    // 	return true;
    // };

    // $scope.sysRetailers = filterSysRetailer;
    // console.log($scope.sysRetailers);
    $scope.reset_retailer = function(){
    	// if (diablo_yes === $scope.setting.smember){
    	//     $scope.sysRetailers = $scope.sysRetailers.filter(function(r){
    	// 	return r.shop_id === $scope.select.shop.id;
    	//     });
    	// };

	$scope.sysRetailers = filterSysRetailer.filter(function(r){
    	    return r.shop_id === $scope.select.shop.id;
    	});
	
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
    	    // $scope.set_retailer(); 
    	} else {
	    $scope.select.retailer = filterSysRetailer[0];
	}
	// console.log($scope.select.retailer);
	$scope.set_retailer();
	$scope.select.sysVip = diablo_yes;
	// $scope.select.retailer.name = diablo_empty_string;
    };

    $scope.reset_retailer();

    /*
     * with draw
     */
    var get_min_value = function(v1, v2) {
	return v1 > v2 ? v2 : v1;
    };

    // var get_limit_balance = function(mbalance, ibalance, icount, balance){
    // 	var max_draw = 0; 
    // 	if ($scope.select.should_pay > 0) {
    // 	    max_draw = get_min_value($scope.select.surplus, $scope.select.should_pay); 
    // 	    // threshold first
    // 	    if (ibalance !== diablo_invalid && ibalance !== 0) {
    // 		if ($scope.select.should_pay < mbalance) {
    // 		    max_draw = get_min_value(ibalance, max_draw);
    // 		} else {
    // 		    max_draw = get_min_value(
    // 			Math.floor($scope.select.should_pay / mbalance) * ibalance, max_draw);
    // 		}
    // 	    } else if (icount !== diablo_invalid && icount !== 0) {
    // 		max_draw = get_min_value(oneTakeBalance, Math.floor(balance / icount));
    // 	    }

    // 	    if ($scope.select.retailer.draw_id !== diablo_invalid_index){
    // 		var limit = diablo_get_object($scope.select.retailer.draw_id, $scope.draws);
    // 		console.log(limit);
    // 		if (angular.isObject(limit))
    // 		    max_draw = get_min_value(max_draw, limit.charge); 
    // 	    } 
    // 	} 
    // 	return max_draw; 
    // };
    
    $scope.disable_withdraw = function(){
	if (angular.isDefined($scope.select.retailer) && angular.isObject($scope.select.retailer)) {
	    if ($scope.select.retailer.type_id !== diablo_charge_retailer)
		return true;
	    else {
		if ($scope.select.retailer.surplus < 0 || $scope.has_withdrawed)
		    return true;
	    }
	} 
	return false;
    };

    // var get_unlimit_draw = function(limitCardDraw, unlimitCardDraw, payLeftBalance, draw_cards) {
    // 	var cardDraw = unlimitCardDraw;
    // 	if ($scope.select.should_pay > 0 && retailerLeftBalance > 0) {
    // 	    var max_draw = get_min_value($scope.select.surplus, $scope.select.should_pay); 
    // 	    cardDraw = get_min_value(
    // 		retailerLeftBalance, max_draw - limitCardDraw - unlimitCardDraw) + unlimitCardDraw;
    // 	} 

    // 	if (cardDraw > unlimitCardDraw) {
    // 	    for (var i=0, l=draw_cards.length; i<l; i++) {
    // 		if (draw_cards[i].card === diablo_default_card) {
    // 		    draw_cards[i].draw = cardDraw;
    // 		    break; 
    // 		}
    // 	    }
    // 	}
	
    // 	return cardDraw;
    // };
    
    $scope.withdraw = function(){
	var callback = function(params){
	    console.log(params);
	    var all_widthdraw = params.retailer.limitWithdraw + params.retailer.unlimitWithdraw;
	    diabloFilter.check_retailer_password(
		params.retailer.id, params.retailer.password, params.hide_pwd ? diablo_no:diablo_yes
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    if (result.limit !== 0 && all_widthdraw > result.limit){
			diabloUtilsService.response(
			    false,
			    "会员现金提取",
			    "会员现金提取失败："
				+ wsaleService.error[2698]
				+ "上限[" + result.limit + "]，实际提取[" + all_widthdraw + "]",
			    undefined) 
		    } else {
			var limitWithdraw = params.retailer.limitWithdraw;
			var unlimitWithdraw = params.retailer.unlimitWithdraw;
			for (var i=0, l=params.cards.length; i<l; i++) {
			    var c = params.cards[i];
			    if (1 === c.type && limitWithdraw > 0) {
				c.draw = get_min_value(c.draw, limitWithdraw);
				limitWithdraw -= c.draw;
			    }

			    if (0 === c.type && unlimitWithdraw > 0) {
				c.draw = get_min_value(c.draw, unlimitWithdraw);
				unlimitWithdraw -= c.draw;
			    }
			} 
			$scope.select.draw_cards = params.cards;
			console.log($scope.select.draw_cards);

			$scope.select.withdraw = all_widthdraw;
			$scope.select.limitWithdraw = params.retailer.limitWithdraw;
			$scope.select.unlimitWithdraw = params.retailer.unlimitWithdraw;
			$scope.has_withdrawed  = true;
			
			$scope.reset_payment();
		    } 
		} else {
		    diabloUtilsService.set_error("会员现金提取", result.ecode); 
		}
	    }); 
	};
	
	var startWithdraw = function(limitCardDraw, unlimitCardDraw, payLeftBalance, draw_cards) {
	    // var unlimitWithdraw =
	    // 	get_unlimit_draw(limitCardDraw, unlimitCardDraw, payLeftBalance, draw_cards);
	    diabloUtilsService.edit_with_modal(
	    	"new-withdraw.html",
	    	undefined,
	    	callback,
	    	undefined,
	    	{retailer: {
	    	    id             :$scope.select.retailer.id,
	    	    name           :$scope.select.retailer.name,
	    	    surplus        :$scope.select.surplus, 
	    	    limitWithdraw  :limitCardDraw,
		    // unlimitWithdraw:unlimitWithdraw
		    unlimitWithdraw:unlimitCardDraw
	    	},

		 cards: draw_cards, 
	    	 hide_pwd: $scope.setting.hide_pwd,
		 check_limit: function(limitWithdraw) {
		     return limitWithdraw <= limitCardDraw;
		 }, 
	    	 check_withdraw: function(balance, limitWithdraw){
		     // return balance <= unlimitWithdraw + limitCardDraw - limitWithdraw;
		     return balance <= unlimitCardDraw + limitCardDraw - limitWithdraw;
		 }, 
	    	 check_zero: function(balance) {return balance === 0 ? true:false}
	    	})
	};
	
	// check
	diabloFilter.check_retailer_charge(
	    $scope.select.retailer.id,
	    $scope.select.shop.id,
	    $scope.setting.fixed_mode===diablo_fixed_draw  ? $scope.select.can_draw:$scope.select.should_pay,
	    $scope.select.surplus,
	    $scope.select.retailer.draw_id
	).then(function(result) {
	    console.log(result);
	    if (result.ecode === 0) {
		var calcDraw = result.cdraw; 
		var cards = result.cards;

		var payLeftBalance = $scope.select.should_pay;
		var limitCardDraw = 0; 
		var unlimitCardDraw = 0;

		var draw_cards = [];
		for (var i=0, l=cards.length; i<l; i++) {
		    var c = cards[i] 
		    if (payLeftBalance < 0) {
			break;
		    } else {
			if (c.type === 1) {
			    if ( !c.limit_shop || (c.limit_shop && c.same_shop) ) {
				limitCardDraw += c.draw;
				draw_cards.push({card: c.card, draw:c.draw, type:c.type});
			    }
			} else {
			    unlimitCardDraw += c.draw;
			    draw_cards.push({card: c.card, draw:c.draw, type:c.type});
			}
		    }
		    payLeftBalance -= c.balance;
		}
		
		// angular.forEach(cards, function(c) {
		//     // allCardBalance =+ c.cardBalance;
		//     // retailerLeftBalance -= c.balance;
		//     payLeftBalance -= c.balance;
		//     if (c.type === 1) {
		// 	if ( !c.limit_shop || (c.limit_shop && c.same_shop) ) {
		// 	    limitCardDraw += c.draw;
		// 	    draw_cards.push({card: c.card, draw:c.draw, type:c.type});
		// 	}
		//     } else {
		// 	unlimitCardDraw += c.draw;
		// 	draw_cards.push({card: c.card, draw:c.draw, type:c.type});
		//     } 
		// });

		// consume with limited shop
		console.log(limitCardDraw);
		console.log(unlimitCardDraw);
		console.log(payLeftBalance);
		console.log(draw_cards);
		// startWithdraw(limitCardDraw, unlimitCardDraw, retailerLeftBalance, draw_cards);
		startWithdraw(limitCardDraw, unlimitCardDraw, payLeftBalance, draw_cards);
	    } else {
		dialog.set_error("会员提现", result.ecode);
	    } 
	}) 
    }; 

    $scope.get_ticket = function() {
	$scope.select.ticket_batchs   = [];
	$scope.select.ticket_balance  = 0;
	$scope.select.ticket_custom   = diablo_invalid_index; 
	diabloFilter.get_all_ticket_by_retailer(
	    $scope.select.retailer.id,
	    $scope.select.shop.id
	).then(function(result){
    	    console.log(result);
	    
	    var callback = function(params) {
		console.log(params);
		if (wsaleUtils.to_integer(params.self_batch) > 0) {
		    diabloFilter.get_ticket_by_batch(params.self_batch).then(function(result){
			console.log(result);
			if (result.ecode === 0 && result.data.length !== 0) {
			    $scope.select.ticket_custom = diablo_custom_ticket; 
			    for (var i=0, l=result.data.length; i<l; i++) {
				$scope.select.ticket_batchs.push(result.data[i].batch);
				$scope.select.ticket_balance += result.data[i].balance;
			    }
			    $scope.reset_payment(); 
			} else {
			    if (result.data.length === 0) {
				dialog.set_error("会员电子卷获取", 2105); 
			    }
			    else {
				dialog.set_error("会员电子卷获取", result.ecode); 
			    }
			}
		    });
		} else {
		    var select_ticket;
		    for (var i=0, l=params.stickets.length; i<l; i++) {
			if (angular.isDefined(params.stickets[i].select) && params.stickets[i].select) {
			    
			    $scope.select.ticket_custom = diablo_score_ticket;

			    select_ticket = params.stickets[i];
			    $scope.select.ticket_sid    = select_ticket.sid; 
			    $scope.select.ticket_batchs.push(select_ticket.batch);
			    $scope.select.ticket_balance += select_ticket.balance;
			    break;
			}
		    }
		    console.log(select_ticket);

		    if (angular.isUndefined(select_ticket)) {
			for (var j=0, k=params.ptickets.length; j<k; j++) {
			    if (angular.isDefined(params.ptickets[j].select) && params.ptickets[j].select){
				$scope.select.ticket_custom = diablo_custom_ticket; 

				select_ticket = params.ptickets[j];
				$scope.select.ticket_batchs.push(select_ticket.batch); 
				$scope.select.ticket_balance += select_ticket.balance;
				// break;
			    }
			}   
		    }

		    // console.log(select_ticket);
		    // $scope.select.ticket_batchs   = select_ticket.batch;
		    // $scope.select.ticket_balance = select_ticket.balance;
		    console.log($scope.select.ticket_batchs);
		    $scope.reset_payment(); 
		}
		
	    };
	    
    	    if (result.ecode === 0){
		var scoreTicket = result.sticket;
		var promotionTickets = result.pticket.filter(function(p) {
		    return p.ubalance === diablo_invalid
			|| p.ubalance <= $scope.select.should_pay - $scope.select.noTicketBalance;
		});
		
    		diabloUtilsService.edit_with_modal(
    		    "new-ticket.html",
    		    undefined,
    		    callback,
    		    undefined,
    		    {stickets: diablo_is_empty(scoreTicket) ? [] : [scoreTicket],
		     ptickets: promotionTickets,
		     check_select_sticket: function(select, stickets, ptickets) {
			 angular.forEach(stickets, function(s) {
			     if (select.batch !== s.batch) {
				 s.select = false;
			     }
			 });
			 angular.forEach(ptickets, function(p) {
			     p.select = false;
			 });
		     },

		     check_select_pticket: function(select, stickets, ptickets) {
			 if (!$scope.setting.multi_ticket) {
			     angular.forEach(ptickets, function(p) {
				 if (select.batch !== p.batch) {
			 	     p.select = false;
				 }
			     });
			 } 
			 
			 angular.forEach(stickets, function(s) {
			     s.select = false;
			 });
		     },

		     check_valid: function(batch, stickets, ptickets) {
			 var autoTicket = false;
			 for (var i=0, l=stickets.length; i<l; i++) {
			     if (angular.isDefined(stickets[i].select) && stickets[i].select) {
				 autoTicket = true;
				 break;
			     }
			 }

			 if (!autoTicket) {
			     for (var j=0, k=ptickets.length; j<k; j++) {
				 if (angular.isDefined(ptickets[j].select) && ptickets[j].select) {
				     autoTicket = true;
				     break;
				 }
			     }
			 }

			 if (batch && autoTicket) return false;
			 if (!batch && !autoTicket) return false;

			 return true;
		     }
		    });
    	    } else {
		dialog.set_error("会员电子卷获取", result.ecode); 
    	    }
    	}); 
    }

    $scope.gift_ticket = function() {
	if (angular.isUndefined($scope.select.employee)) {
	    diabloUtilsService.response(
		false,
		"会员赠券",
		"赠券失败：" + wsaleService.error[2192]);
	} else {	    
	    var callback = function(params) {
		console.log(params);
		// get all ticket
		var send_tickets = [];
		angular.forEach(params.tickets, function(t) {
	    	    if (t.plan.id !== diablo_invalid_index) {
	    		send_tickets.push({id      :t.plan.id,
					   rule    :t.plan.rule,
					   balance :t.plan.balance,
					   count   :t.count,
					   effect  :t.plan.effect,
					   expire  :t.plan.expire,
					   stime   :t.plan.stime,
					   etime   :t.plan.etime});
	    	    }
		});
		
		console.log(send_tickets);

		diabloFilter.wretailer_gift_ticket({
		    shop           :$scope.select.shop.id,
		    shop_name      :$scope.select.shop.name,
		    retailer       :$scope.select.retailer.id,
		    employee       :$scope.select.employee.id,
		    retailer_name  :$scope.select.retailer.name,
		    retailer_phone :$scope.select.retailer.mobile,
		    ticket         :send_tickets
		}).then(function(result) {
		    console.log(result);
		    if (result.ecode === 0) {
			$scope.has_gift_ticket = true;
			dialog.response(
			    true,
			    "会员优惠卷赠送",
			    "会员[" + $scope.select.retailer.name + "] 卷赠送成功！！"
				+ function() {
				    if (result.sms_code !== 0) {
					var ERROR = require("diablo-error");
					return "发送短消息失败：" + ERROR[result.sms_code];
				    } 
				    else return ""; 
				}()
			);
		    } else {
			dialog.set_error("会员电子券赠送", result.ecode);
		    }
		});
	    };

	    // get max send count
	    var maxSend = 0, validPlans = [];
	    for (var i=0, l=$scope.ticketPlans.length; i<l; i++) {
		validPlans.push($scope.ticketPlans[i]);
		if ($scope.ticketPlans[i].scount > maxSend) {
		    maxSend = $scope.ticketPlans[i]; 
		} 
	    }; 
	    
	    dialog.edit_with_modal(
		"gift-ticket.html",
		undefined,
		callback,
		undefined,
		{tickets: [],
		 add_ticket: function(tickets, planes) {
		     tickets.push({plan:planes[0], count:1});
		 }, 
		 delete_ticket: function(tickets) {
		     tickets.splice(-1, 1);
		 },
		 check_ticket: function(tickets) {
		     var invalid = false;
		     for (var i=0, l=tickets.length; i<l; i++) {
			 if (tickets[i].plan.id === diablo_invalid_index) {
			     invalid = true;
			     break;
			 } 
		     } 
		     return !invalid && tickets.length !== 0;
		 },
		 maxSend: maxSend,
		 planes: [{id:-1, name:"请选择电子券金额"}].concat(validPlans)});
	};
    }

    var get_charge_by_shop = function(charges) {
	var charge_with_shop;
	for (var i=0, l=charges.length; i<l; i++){
	    if ($scope.select.shop.charge_id === charges[i].id){
		charge_with_shop = charges[i];
		break;
	    }
	} 

	return charge_with_shop;
    };
    
    $scope.start_charge = function() {
	var stocks = [];
	for (var i=0,l=$scope.inventories.length; i<l; i++) {
	    var stock = $scope.inventories[i];
	    if (stock.charge) {
		stocks.push(stock);
	    }
	}

	var default_charge;
	if (stocks.length !== 0) {
	    if ($scope.select.shop.charge_id === diablo_invalid_index) {
		default_charge = $scope.tcharges.length !== 0 ? $scope.tcharges[0] : undefined;
	    } else {
		// default_charge = get_charge_by_shop($scope.charges);
		default_charge = $scope.charges.length !== 0 ? get_charge_by_shop($scope.charges) : undefined;
		if (angular.isDefined(default_charge)
		    && default_charge.rule_id === diablo_giving_charge) {
		    default_charge = $scope.tcharges.length !== 0 ? $scope.tcharges[0] : undefined;
		}
	    } 
	    console.log(default_charge);
	    if (angular.isUndefined(default_charge)) {
		dialog.set_error("会员充值", 2170);
	    } else {
		// if (default_charge.rule_id === diablo_giving_charge) {
		//     $scope.common_charge(default_charge, stocks);
		// } else if (default_charge.rule_id === diablo_times_charge) {
		//     $scope.times_charge(default_charge, stocks); 
		// }
		$scope.times_charge(default_charge, stocks); 
	    } 
	} else {
	    default_charge = get_charge_by_shop($scope.mcharges);
	    if (angular.isUndefined(default_charge)) {
		default_charge = $scope.mcharges.length !== 0 ? $scope.mcharges[0] : undefined; 
	    }
	    
	    console.log(default_charge);
	    if (angular.isUndefined(default_charge)) {
		dialog.set_error("会员充值", 2170);
	    } else {
		$scope.common_charge(default_charge, undefined); 
	    }
	}
    };
    
    $scope.times_charge = function(default_charge, stocks) {
	if ($scope.tcharges.length === 0) {
	    dialog.set_error("会员充值", 2170);
	} else {
	    // var select_charge = $scope.tcharges[0];
	    // for (var i=0, l=$scope.tcharges.length; i<l; i++){
	    // 	if ($scope.select.shop.charge_id === $scope.tcharges[i].id){
	    // 	    select_charge = $scope.tcharges[i];
	    // 	    break;
	    // 	}
	    // }
	    // console.log(select_charge); 

	    var pay = 0;
	    var desc = "";
	    for (var i=0,l=stocks.length; i<l; i++) {
		pay  += diablo_price(stocks[i].tag_price * stocks[i].sell, default_charge.xdiscount);
		desc += stocks[i].style_number + "/";
	    }
	    
	    if (desc.length > 64) {
		desc = desc.substr(0, 64);
	    }
	    
	    var charge_balance = diablo_round(diablo_round(pay) * default_charge.xtime);
	    var retailer = $scope.select.retailer;
	    var callback = function(params) {
		console.log(params);
		if (!wsaleUtils.isVip(retailer, $scope.setting.no_vip, $scope.sysRetailers)
		    || retailer.type_id === diablo_common_retailer) {
		    dialog.set_error("会员充值", 2171);
		} else {
		    var has_charged = (params.cash + params.card + params.wxin);
		    diabloFilter.wretailer_charge({
			shop:           $scope.select.shop.id,
			retailer:       $scope.select.retailer.id,
			employee:       params.employee.id,
			charge_balance: has_charged,
			cash:           wsaleUtils.to_decimal(params.cash),
			card:           wsaleUtils.to_decimal(params.card),
			wxin:           wsaleUtils.to_decimal(params.wxin),
			charge:         params.select_charge.id,
			stock:          desc,
			comment:        params.comment 
		    }).then(function(result) {
			console.log(result);
			if (result.ecode === 0) {
			    retailer.balance = wsaleUtils.to_decimal(retailer.balance + has_charged); 
			    // $scope.select.retailer = params.retailer;
			    // $scope.select.retailer.balance = balance;
			    $scope.set_retailer();
			    // $scope.on_select_retailer();
			    $scope.select.employee = params.employee;
			    $scope.select.recharge = has_charged;
			    angular.forEach(stocks, function(s) {
				s.fprice = 0;
				s.$update = true;
			    });
			    // $scope.wsaleStorage.save(
			    // 	$scope.inventories.filter(function(r){return !r.$new}));
			    $scope.re_calculate(); 
			    dialog.response_with_callback(
				true,
				"会员充值",
				"会员 [" + retailer.name + "] 充值成功，"
				    + "帐户余额 [" + retailer.balance.toString() + " ]！！"
				    + function(){
					if (result.sms_code !== 0) {
					    var ERROR = require("diablo-error");
					    return "发送短消息失败：" + ERROR[result.sms_code];
					} 
					else return ""; 
				    }(),
				undefined,
				undefined);
			} else {
			    dialog.set_error("会员充值", result.ecode); 
			}
		    })
		}
	    };
	    
	    dialog.edit_with_modal(
		"wretailer-charge.html",
		undefined,
		callback,
		$scope,
		{$tcharge:true,
		 select_charge: default_charge,
		 charge_balance: charge_balance,
		 cash: 0,
		 card: 0,
		 wxin: 0,
		 charges: $scope.tcharges,
		 pattern:  {comment:diabloPattern.comment, number:diabloPattern.number},
		 // should_charge: function(cash, card, wxin) {
		 //     return charge_balance - wsaleUtils.to_integer(cash)
		 // 	 - wsaleUtils.to_integer(card)
		 // 	 - wsaleUtils.to_integer(wxin);
		 // },
		 
		 check_charge: function(cash, card, wxin) {
		     return wsaleUtils.to_integer(cash)
			 + wsaleUtils.to_integer(card)
			 + wsaleUtils.to_integer(wxin) >= charge_balance;
		 },
		 calc_charge_balance: function(charge) {
		     pay = 0;
		     for (var i=0,l=stocks.length; i<l; i++) {
			 pay += diablo_price(stocks[i].tag_price * stocks[i].sell, charge.xdiscount);
		     } 
		     
		     return diablo_round(diablo_round(pay) * charge.xtime);
		 }
		}
	    );
	} 
    };

    $scope.common_charge = function(default_charge, stocks) {	
	var retailer = $scope.select.retailer;
	var callback = function(params) {
	    console.log(params);
	    if (!wsaleUtils.isVip(retailer, $scope.setting.no_vip, $scope.sysRetailers)
		|| retailer.type_id === diablo_common_retailer) {
		dialog.set_error("会员充值", 2171);
	    } else {
		var cbalance  = wsaleUtils.to_integer(params.cash)
		    + wsaleUtils.to_integer(params.card)
		    + wsaleUtils.to_integer(params.wxin);
		
		var sbalance  = 0;
		var promotion = params.select_charge;
		if (promotion.charge !== 0 && cbalance >= promotion.charge) {
		    sbalance = Math.floor(cbalance / promotion.charge) * promotion.balance;
		}
		
		if (sbalance !== 0 && sbalance !== wsaleUtils.to_integer(params.sbalance)) {
		    dialog.set_error("会员充值", 2172);
		} else {
		    diabloFilter.wretailer_charge({
			shop:           $scope.select.shop.id,
			retailer:       $scope.select.retailer.id,
			employee:       params.employee.id,
			charge_balance: cbalance,
			send_balance:   wsaleUtils.to_integer(params.sbalance),
			cash:           wsaleUtils.to_integer(params.cash),
			card:           wsaleUtils.to_integer(params.card),
			wxin:           wsaleUtils.to_integer(params.wxin),
			charge:         promotion.id,
			comment:        params.comment 
		    }).then(function(result) {
			console.log(result);
			if (result.ecode === 0) {
			    retailer.balance = wsaleUtils.to_decimal(retailer.balance + cbalance)
				+ wsaleUtils.to_integer(params.sbalance);
			    $scope.set_retailer();
			    $scope.select.employee = params.employee;
			    $scope.select.recharge = cbalance;

			    angular.forEach(stocks, function(s) {
				s.fprice = 0;
				s.$update = true;
			    });
			    $scope.re_calculate();
			    
			    dialog.response_with_callback(
				true,
				"会员充值",
				"会员 [" + retailer.name + "] 充值成功，"
				    + "帐户余额 [" + retailer.balance.toString() + " ]！！"
				    + function(){
					if (result.sms_code !== 0) {
					    var ERROR = require("diablo-error");
					    return "发送短消息失败：" + ERROR[result.sms_code];
					} 
					else return ""; 
				    }(),
				undefined,
				undefined);
			} else {
			    dialog.set_error("会员充值", result.ecode); 
			}
		    })
		}
	    } 
	};

	// var select_charge = $scope.mcharges[0];
	// for (var i=0, l=$scope.mcharges.length; i<l; i++){
	// 	if ($scope.select.shop.charge_id === $scope.mcharges[i].id){
	// 	    select_charge = $scope.mcharges[i];
	// 	    break;
	// 	}
	// }
	// console.log(select_charge);
	
	dialog.edit_with_modal(
	    "wretailer-charge.html",
	    undefined,
	    callback,
	    $scope,
	    {$mcharge:true,
	     select_charge: default_charge,
	     cash:     0,
	     card:     0,
	     wxin:     0,
	     sbalance: 0,
	     charges: $scope.mcharges,
	     pattern:  {comment:diabloPattern.comment, number:diabloPattern.number},
	     
	     check_charge: function(cash, card, wxin, sbalance) {
		 return wsaleUtils.to_integer(cash)
		     + wsaleUtils.to_integer(card)
		     + wsaleUtils.to_integer(wxin)
		     + wsaleUtils.to_integer(sbalance) > 0;
	     }}
	);
    };

    $scope.new_retailer = function() {
	var callback = function(params) {
	    console.log(params);
	    var r = params.retailer;
	    var addedRetailer =
		{name:     r.name,
		 intro:    r.intro && angular.isObject(r.intro) ? r.intro.id : undefined,
		 py:       diablo_pinyin(r.name),
		 password: diablo_set_string(r.password),
		 mobile:   r.mobile,
		 type:     r.type.id,
		 level:    r.level.level,
		 shop:     $scope.select.shop.id,
		 birth:    dateFilter(r.birth, "yyyy-MM-dd"),
		 lunar:    r.lunar.id};

	    console.log(addedRetailer);
	    diabloFilter.new_wretailer(addedRetailer).then(function(result){
	        console.log(result);
	        if (result.ecode === 0){
		    var nRetailer = {
			id:      result.id,
			name:    addedRetailer.name + "/" + addedRetailer.mobile,
			wname:   addedRetailer.name,
			birth:   addedRetailer.birth.substr(5,8),
			wbirth:  addedRetailer.birth,
			lunar_id:addedRetailer.lunar,
			level:   addedRetailer.level,
			mobile:  addedRetailer.mobile,
			type_id: addedRetailer.type,
			score:   0,
			shop_id: addedRetailer.shop,
			py:      addedRetailer.py,
			balance: 0
		    }; 
		    $scope.select.retailer = nRetailer;
		    // $scope.set_retailer();
		    $scope.on_select_retailer();
	        } else {
	    	    dialog.set_error("新增会员", result.ecode);
	    	}
	    });
	};
	
	dialog.edit_with_modal(
	    "new-retailer.html",
	    undefined,
	    callback,
	    $scope,
	    {
		retailer: {
		    $new:true,
		    birth:$.now(),
		    lunar:diablo_lunar[0],
		    type :$scope.retailer_types[0],
		    level:diablo_retailer_levels[0]
		},
		levels: diablo_retailer_levels,
		lunars: diablo_lunar,
		retailer_types:$scope.retailer_types,
		pattern: {name:diabloPattern.chinese_name,
			  tel_mobile: diabloPattern.tel_mobile,
			  password:   diabloPattern.num_passwd}
	    }
	    
	); 
    };

    $scope.update_retailer = function() {
	var oRetailer = angular.copy($scope.select.retailer);
	var get_modified = diablo_get_modified;
	var pinyin = diablo_pinyin;
	var set_date = diablo_set_date_obj;
	
	var callback = function(params) {
	    console.log(params);
	    var u = params.retailer;
	    var uRetailer = {
		id:       oRetailer.id,
		shop:     $scope.select.shop.id,
		name:     get_modified(u.name, oRetailer.wname),
		py:       get_modified(pinyin(u.name), pinyin(oRetailer.wname)),
		password: get_modified(u.password, oRetailer.password),
		type:     get_modified(u.type.id, oRetailer.type_id),
		birth:    get_modified(u.birth.getTime(), set_date(oRetailer.wbirth).getTime()),
		lunar:    get_modified(u.lunar.id, oRetailer.lunar_id)
	    };
	    
	    console.log(uRetailer);
	    diabloFilter.update_wretailer(uRetailer).then(function(result){
	        console.log(result);
	        if (result.ecode === 0){
		    if (angular.isDefined(uRetailer.name)) {
			oRetailer.wname = uRetailer.name;
			oRetailer.name  = uRetailer.name + "/" + uRetailer.mobile;
			oRetailer.py    = diablo_pinyin(uRetailer.name);
		    }

		    if (angular.isDefined(uRetailer.type)) {
			oRetailer.type_id = uRetailer.type; 
		    }

		    if (angular.isDefined(uRetailer.lunar)) {
			oRetailer.lunar_id = uRetailer.lunar;
			oRetailer.lunar = diablo_get_object(oRetailer.lunar_id, diablo_lunar);
		    }

		    if (angular.isDefined(uRetailer.birth)) {
			oRetailer.wbirth = dateFilter(uRetailer.birth, "yyyy-MM-dd");
			oRetailer.birth = oRetailer.wbirth.substr(5,8);
		    }
		    $scope.select.retailer = oRetailer;
		    $scope.set_retailer();
		    // console.log($scope.select.retailer);
	        } else {
	    	    dialog.set_error("会员编辑", result.ecode);
	    	}
	    });
	};

	dialog.edit_with_modal(
	    "new-retailer.html",
	    undefined,
	    callback,
	    $scope,
	    {
		retailer: {
		    name:    oRetailer.wname,
		    mobile:  oRetailer.mobile,
		    birth:   set_date(oRetailer.wbirth),
		    lunar:   diablo_get_object(oRetailer.lunar_id, diablo_lunar),
		    type_id: oRetailer.type_id,
		    type:    diablo_get_object(oRetailer.type_id, $scope.retailer_types),
		},
		retailer_types:$scope.retailer_types,
		lunars: diablo_lunar,
		pattern: {name:diabloPattern.chinese_name,
			  password: diabloPattern.num_passwd}
	    }
	    
	); 
    };
    
    $scope.refresh = function(){
	$scope.inventories = [];
	$scope.show_promotions = [];
	
	$scope.select.form.c.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	if ($scope.setting.show_wprice) $scope.select.form.wForm.$invalid  = false; 

	$scope.select.rsn             = undefined;
	$scope.select.cash            = undefined;
	$scope.select.card            = undefined;
	$scope.select.wxin            = undefined;
	$scope.select.aliPay          = undefined;
	$scope.select.withdraw        = undefined;
	$scope.select.limitWithdraw   = undefined;
	$scope.select.unlimitWithdraw = undefined;
	$scope.select.draw_cards      = undefined;
	
	$scope.select.ticket_batchs = [];
	$scope.select.ticket_balance = 0;
	$scope.select.ticket_score = 0;
	$scope.select.ticket_sid   = diablo_invalid_index;
	$scope.select.ticket_custom = diablo_invalid_index;

	$scope.select.sysVip       = diablo_yes,
	$scope.select.total        = 0;
	$scope.select.oil          = 0;
	$scope.select.noTicketBalance = 0;
	$scope.select.abs_total    = 0;
	$scope.select.has_pay      = 0;
	$scope.select.should_pay   = 0;
	$scope.select.can_draw     = 0;
	$scope.select.base_pay     = 0;
	$scope.select.abs_pay      = 0;
	$scope.select.score        = 0;
	$scope.select.pscores      = [];
	$scope.select.charge       = 0;
	$scope.select.recharge     = 0;
	$scope.select.surplus      = $scope.select.retailer.balance;
	$scope.select.left_balance = $scope.select.surplus;
	$scope.select.pay_order    = diablo_invalid_index,
	
	$scope.select.verificate   = $scope.vpays[0],
	$scope.select.wprice       = undefined; 
	
	$scope.select.comment      = undefined; 
	$scope.select.datetime     = $scope.today();
	$scope.select.lunar        = $scope.solar2lunar(diablo_get_now_full_date());
	
	if ($scope.setting.semployee)
	    $scope.select.employee = undefined;
	
	$scope.disable_refresh     = true;
	$scope.has_saved           = false;
	$scope.has_withdrawed      = false;

	$scope.disable_focus();
	$scope.focus_good_or_barcode();
	$scope.wsaleStorage.reset();
	$scope.reset_retailer();
    };

    
    $scope.refresh_datetime_per_5_minute = function(){
    	$scope.interval_per_5_minute = setInterval(function(){
    	    $scope.select.datetime  = $scope.today();
	    $scope.select.lunar     = $scope.solar2lunar(diablo_get_now_full_date());
	    // console.log(dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"));
    	}, 300 * 1000);
    };

    var now = $scope.today(); 
    $scope.qtime_start = function(shopId){
	return wsaleUtils.start_time(shopId, base, now, dateFilter);
    };
    
    $scope.setting.q_backend = $scope.q_typeahead($scope.select.shop.id);
    // console.log($scope.setting.q_backend);
    
    // $scope.match_all_w_inventory = function(){
    // 	if (!$scope.setting.q_backend){
    // 	    diabloNormalFilter.match_all_w_inventory(
    // 		{shop:$scope.select.shop.id,
    // 		 start_time:$scope.qtime_start($scope.select.shop.id)}
    // 	    ).$promise.then(function(invs){
    // 		$scope.all_w_inventory = 
    // 		    invs.sort(function(inv1, inv2){
    // 			return inv1.style_number.length - inv2.style_number.length;
    // 		    }).map(function(inv){
    // 			var p = wsaleUtils.prompt_name(
    // 			    inv.style_number, inv.brand, inv.type); 
    // 			return angular.extend(
    //                         inv, {name:p.name, prompt:p.prompt}); 
    // 		    });
    // 	    });
    // 	};
    // }

    // $scope.match_all_w_inventory();
    $scope.refresh_datetime_per_5_minute();

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
	return $scope.wsaleStorage.keys().length === 0 || $scope.inventories.length !== 0;
	    
    };

    $scope.hang_draft = function() {
	$scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.refresh();
	$scope.focus_by_element();
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
		var r = diablo_get_object(draft.retailer.id, retailers);
		r.name  = r.name + "/" + r.mobile;
		r.birth = r.birth.substr(5,8);
		$scope.select.retailer = r;
		$scope.select.surplus  = r.balance;
		$scope.get_employee(); 
		
		$scope.inventories = angular.copy(resource);
		// console.log($scope.inventoyies);
		// $scope.inventories.unshift({$edit:false, $new:true});
		$scope.disable_refresh = false;

		if ($scope.setting.vip_discount_mode === diablo_vip_sale_by_balance
		    && wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers)) {
		    $scope.select.verificate = wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels);
		}
		
		$scope.re_calculate();
		$scope.focus_by_element();
	    };

	    $scope.wsaleStorage.select(diabloUtilsService, "wsale-draft.html", draft_filter, select);  
	}); 
    };
    
    $scope.match_style_number = function(viewValue){
	if (diablo_yes === $scope.setting.type_sale) {
	    return diabloFilter.match_w_sale(
		viewValue,
		$scope.select.shop.id,
		diablo_type_sale,
		diablo_is_ascii_string(viewValue));
	} else {
	    if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return; 
	    
	    return diabloFilter.match_w_sale(viewValue, $scope.select.shop.id);
	} 
    };

    $scope.copy_select = function(add, src){
	console.log(src);
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
	add.mid          = src.mid;
	add.commision    = diablo_get_object(src.mid, $scope.commisions);
	
	add.org_price    = src.org_price;
	add.ediscount    = src.ediscount;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;
	add.vir_price    = src.vir_price;
	add.draw         = src.draw;
	
	add.path         = src.path; 
	add.s_group      = src.s_group;
	add.free         = src.free;
	
	add.state        = src.state;
	add.bargin_price = wsaleUtils.to_integer(src.state.charAt(0)); 
	add.gift         = wsaleUtils.to_integer(src.state.charAt(1));
	add.ticket       = wsaleUtils.to_integer(src.state.charAt(2));
	
	add.entry        = src.entry_date;

	// add.full_bcode   = angular.isUndefined(src.full_bcode) ? src.bcode : src.full_bcode;
	add.full_name    = add.style_number + "/" + add.brand + "/" + add.type;

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
	    fail_response(2193, function(){}); 
	} else {
	    // auto focus
	    $scope.auto_focus("sell"); 
	    var add  = {$new:true}; 
	    $scope.copy_select(add, item);
	    console.log(add);
	    $scope.add_inventory(add); 
	}
	
	// has been added
	// var existStock = undefined;
	// for(var i=1, l=$scope.inventories.length; i<l; i++){
	//     var s = $scope.inventories[i];
	//     if (item.style_number === s.style_number && item.brand_id === s.brand_id){
	// 	existStock = $scope.inventories[i];
	// 	if (angular.isDefined(item.full_bcode)) existStock.full_bcode = item.full_bcode;
	//     }
	// }; 

	// if (angular.isDefined(existStock)) {
	//     $scope.update_inventory(
	// 	existStock, function() {
	// 	    // $scope.inventories[0] = {$edit:false, $new:true}
	// 	}, true)
	// } else {
	//     // add at first allways 
	//     var add = $scope.inventories[0];
	//     add = $scope.copy_select(add, item);
	//     console.log(add);
	//     $scope.add_inventory(add);
	// } 
    };

    /*
     * image mode
     */
    // filter
    $scope.filters = [];
    diabloFilter.reset_field();
    // diabloFilter.add_field("firm", filterFirm);
    // diabloFilter.add_field("brand", wsaleGoodService.get_brand());
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
	if (angular.isUndefined(full_bcode) || !diablo_trim(full_bcode))
	    return;
	
	// get stock by barcode
	// stock info 
	var barcode = diabloHelp.correct_barcode(full_bcode, $scope.setting.barcode_auto); 
	console.log(barcode);

	// invalid barcode
	if (!barcode.cuted || !barcode.correct) {
	    dialog.set_error("销售开单", 2196);
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(
	    barcode.cuted, $scope.select.shop.id
	).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.set_error("销售开单", 2195);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.set_error("销售开单", result.ecode);
	    }
	});
	
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	// save one time only
	if ($scope.has_saved || $scope.draft || $scope.inventories.length === 0)
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
		"销售开单", "开单成功，是否打印销售单？", ok_print, undefined, $scope);
	}
	
    };
    
    var LODOP;
    $scope.print_front = function(result, im_print, callback){
	var pdate = dateFilter($.now(), "yyyy-MM-dd HH:mm:ss");
	var pinvs = [];
	for (var i=0, l=$scope.inventories.length; i<l; i++){
	    $scope.inventories[i].total = $scope.inventories[i].sell;
	    pinvs.push($scope.inventories[i]);
	};
	// if (angular.isUndefined(LODOP)) LODOP = getLodop();
	// if (angular.isDefined(LODOP)) {
	console.log($scope.select);

	var sms_notify = function() {
	    if (result.sms_code !== 0) {
		var ERROR = require("diablo-error");
		dialog.response(false,
				"销售开单",
				"开单成功！！发送短消息失败：" + ERROR[result.sms_code]); 
	    }
	};
	
	var start_print = function(print_callback){
	    if (angular.isUndefined(LODOP)) LODOP = getLodop();
	    if (angular.isUndefined(LODOP.PRINT_INIT) && !angular.isFunction(LODOP.PRINT_INIT)) {
		var ERROR = require("diablo-error"); 
		dialog.response_with_callback(
		    false,
		    "销售开单", "打印失败！！" + ERROR[9801],
		    undefined,
		    function() {window.location.reload()}); 
	    } else {
		$scope.select.ticket_score = 0; 
		var sid = $scope.select.ticket_sid;
		if ($scope.select.ticket_custom === diablo_score_ticket
		    && angular.isDefined(sid) && diablo_invalid_index !== sid) {
		    var s = diablo_get_object(sid, $scope.scores);
		    if (angular.isObject(s)) {
			$scope.select.ticket_score =
			    parseInt($scope.select.ticket_balance / s.balance) * s.score;
		    } 
		}
		
		var top = wsalePrint.gen_head(
		    LODOP,
		    $scope.select.shop.name,
		    $scope.select.rsn,
		    $scope.select.employee.name,
		    $scope.select.retailer.name, 
		    dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
		    wsaleService.direct.wsale,
		    $scope.print_setting);

		var isRound = $scope.setting.round; 
		// var cakeMode = $scope.setting.cake_mode;
		top = wsalePrint.gen_body(
		    LODOP,
		    top,
		    $scope.select,
		    pinvs,
		    isRound,
		    $scope.print_setting);
		
		var selectRetailer = $scope.select.retailer.id; 
		// console.log($scope.select);
		top = wsalePrint.gen_stastic(
		    LODOP,
		    top,
		    0,
		    $scope.select,
		    $scope.select.retailer.balance,
		    wsaleUtils.isVip(
			$scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
		    $scope.print_setting);
		
		wsalePrint.gen_foot(LODOP, top, pdate, $scope.select.shop, $scope.print_setting);
		return wsalePrint.start_print(LODOP, print_callback);
	    }
	}; 
	
	var print_interval = function(job) {
	    console.log("print_job:", job);
	    if ($$scope.p_num > 1) {
		if ($scope.timer_of_print) {
		    $interval.cancel($scope.timer_of_print); 
		}

		var interval = 0; 
		$scope.timer_of_print = $interval(function() {
		    interval++;
		    console.log("interval:", interval);

		    var wait_print = function(status) {
			console.log("wait_print:", status);
			if ("1" === status) {
			    if ($scope.timer_of_print) $interval.cancel($scope.timer_of_print); 
			    
			    var t0 = $timeout(function() {
				$timeout.cancel(t0);
				for (var i=1; i<$scope.p_num; i++){
				    start_print(); 
				}
				if (angular.isFunction(callback)) {
				    $scope.$apply(function() {callback();});
				} 
			    }, 3000, false);
			} else {
			    if (interval >= 3) {
				console.log("wait for long, start print any way");
				if ($scope.timer_of_print) $interval.cancel($scope.timer_of_print); 
				for (var i=1; i<$scope.p_num; i++){
				    start_print(); 
				}
				
				if (angular.isFunction(callback)) 
				    $scope.$apply(function() {callback();});
			    }
			}
		    };
		    
		    if (LODOP.CVERSION) {
			LODOP.On_Return = function(task, status) {
			    wait_print(status);
			}; 
			LODOP.GET_VALUE('PRINT_STATUS_OK', job); 
		    } else {
			var status = LODOP.GET_VALUE('PRINT_STATUS_OK', job);
			wait_print(status);
		    }
		    
		}, 2000, 3, false);
		
	    } else {
		if (angular.isFunction(callback))
		    $scope.$apply(function() {callback();});
	    } 
	};

	var print_direct = function() {
	    for (var i=0; i<$scope.p_num; i++){
		start_print(); 
	    }
	    if (angular.isFunction(callback)) {
		callback();
	    } 
	}
	    
	if (im_print === diablo_yes) {
	    sms_notify();
	    if ($scope.setting.interval_print) {
		start_print(function(job) {print_interval(job);});
	    } else {
		print_direct();
	    }
	} else {
	    var request = dialog.request(
		"销售开单", "开单成功，是否打印销售单？", undefined, undefined, undefined);
	    request.result.then(function(close){
		console.log(close);
		sms_notify();
		if ($scope.setting.interval_print) {
		    start_print(function(job) {print_interval(job);});
		} else {
		    print_direct();
		}
	    }, function(success) {
		if (angular.isFunction(callback))
		    callback(); 
	    }, function(error) {
		// console.log(error);
	    });
	}
	// };
	// console.log(pinvs); 
	// var ok_print = function(){
	//     console.log($scope.select);
	//     if (angular.isUndefined(LODOP)) LODOP = getLodop(); 
	//     if (angular.isDefined(LODOP)){
		
		
	// 	var job = start_print();
	// 	console.log(job); 
	// 	var interval = 0;
		
	// 	if ($scope.timer_of_print) $interval.cancel($scope.timer_of_print);
	// 	$scope.timer_of_print = $interval(function() {
	// 	    interval++;
	// 	    console.log(interval);
		    
	// 	    var print_status = LODOP.GET_VALUE('PRINT_STATUS_OK', job);
	// 	    console.log(print_status);
		    
	// 	    if (0 === print_status); {
	// 		if ($scope.timer_of_print) $interval.cancel($scope.timer_of_print);
	// 		var t0 = $timeout(function() {
	// 		    $timeout.cancel(t0);
	// 		    for (var i=1; i<$scope.p_num; i++){
	// 			start_print(); 
	// 		    }
	// 		}, 3000, false);
	// 	    }
	// 	}, 2000, 5, false); 
	//     }
	// }; 
	
	// if (im_print === diablo_yes){
	//     ok_print();
	//     sms_notify(result); 
	//     if (angular.isFunction(callback))
	// 	callback();
	// } else {
	//     var request = dialog.request(
	// 	"销售开单", "开单成功，是否打印销售单？", undefined, undefined, undefined); 
	//     request.result.then(function(close){
	// 	console.log(close);
	// 	ok_print(); 
	// 	sms_notify(result);
	// 	if (angular.isFunction(callback))
	// 	    callback();
	//     }, function(success) {
	// 	if (angular.isFunction(callback))
	// 	    callback();
	//     }, function(error) {
	// 	// console.log(error);
	//     });
	// }
    };

    var get_sale_detail = function(amounts){
	var sale_amounts = [];
	for(var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		var new_a = {
		    cid:        a.cid,
		    size:       a.size, 
		    sell_count: wsaleUtils.to_integer(amounts[i].sell_count),
		    exist:      a.count
		}; 
		sale_amounts.push(new_a); 
	    }
	}; 
	return sale_amounts;
    };

    var index_of_sale = function(sale, exists) {
	var index = diablo_invalid_index;;
	for (var i=0, l=exists.length; i<l; i++) {
	    if (sale.style_number === exists[i].style_number && sale.brand_id === exists[i].brand) {
		index = i;
		break;
	    }
	} 
	return index;
    };

    var index_of_sale_detail = function(existDetails, detail) {
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

	if ($scope.setting.vip_discount_mode === diablo_vip_sale_by_balance) {
	    if ($scope.select.sysVip) {
		if (diablo_abs($scope.select.verificate) > $scope.setting.maling_rang) {
		    diabloUtilsService.response(
			false,
			"销售开单",
			"开单失败：" + wsaleService.error[2197]);
		    $scope.has_saved = false; 
		    return;
		}
	    } else {
		if ($scope.select.verificate > wsaleUtils.get_retailer_discount(
		    $scope.select.retailer.level, $scope.levels))
		{
		    diabloUtilsService.response(
			false,
			"销售开单",
			"开单失败：" + wsaleService.error[2197]);
		    $scope.has_saved = false; 
		    return;
		}
	    }
	} 
	
	if ($scope.select.cash > diablo_max_sale_money
	    || $scope.select.wxin > diablo_max_sale_money
	    || $scope.select.aliPay > diablo_max_sale_money
	    || $scope.select.card > diablo_max_sale_money) {
	    diabloUtilsService.set_error("销售开单", 2197);
	    $scope.has_saved = false;
	    return;
	}

	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    if ($scope.inventories[i].free_update) {
		diabloUtilsService.set_error("销售开单", 2198);
		$scope.has_saved = false;
		return; 
	    } 
	}
	
	var setv = diablo_set_float;
	var seti = diablo_set_integer;
	var sets = diablo_set_string; 
	var added = [];
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    console.log(add);
	    var sell_total = wsaleUtils.to_integer(add.sell); 
	    var index = index_of_sale(add, added)
	    // console.log(index);
	    if (diablo_invalid_index !== index) {
		var existSale = added[index];
		existSale.sell_total += sell_total;
		existSale.all_tagprice += wsaleUtils.to_decimal(add.tag_price * sell_total);
		existSale.all_fprice += wsaleUtils.to_decimal(add.fprice * sell_total);
		existSale.all_rprice += wsaleUtils.to_decimal(add.rprice * sell_total);
		
		// reset fdiscount
		if (existSale.fdiscount !== add.fdiscount) {
		    existSale.fdiscount = diablo_discount(existSale.all_fprice, existSale.all_tagprice) ;
		    existSale.rdiscount = diablo_discount(existSale.all_rprice, existSale.all_fprice);
		    
		    existSale.fprice = diablo_price(existSale.tag_price, existSale.fdiscount);
		    existSale.rprice = diablo_price(existSale.fprice, existSale.rdiscount);
		} 
		
		// if (existSale.rdiscount !== add.rdiscount) {
		//     existSale.rdiscount = diablo_discount(existSale.all_rprice, existSale.all_fprice);
		//     existSale.rprice = diablo_price(existSale.fprice, existSale.rdiscount);
		// }
		
		var details1 = get_sale_detail(add.amounts);
		var existDetails = existSale.amounts;
		// console.log(existDetails);
		// console.log(details1);
		angular.forEach(details1, function(d) {
		    var indexDetail = index_of_sale_detail(existDetails, d);
		    if (diablo_invalid_index !== indexDetail) {
			existDetails[indexDetail].sell_count += d.sell_count;
		    } else {
			existDetails.push(d);
		    } 
		})
	    } else {
		// var batch = add.batch;
		// console.log(batch);
		var details0 = get_sale_detail(add.amounts);
		added.push({
		    id          : add.id,
		    style_number: add.style_number,
		    brand       : add.brand_id,
		    brand_name  : add.brand,
		    type        : add.type_id,
		    type_name   : add.type,
		    sex         : add.sex,
		    firm        : add.firm_id,
		    // sex         : add.sex,
		    season      : add.season,
		    year        : add.year,
		    entry       : add.entry,
		    sell_total  : sell_total,

		    promotion   : add.pid,
		    score       : add.sid,
		    commision   : add.mid,

		    org_price   : add.org_price,
		    ediscount   : add.ediscount,
		    tag_price   : add.tag_price,
		    discount    : add.discount,
		    fprice      : add.fprice,
		    rprice      : add.rprice,
		    fdiscount   : add.fdiscount,
		    rdiscount   : add.rdiscount,
		    oil         : add.oil,

		    all_fprice  : wsaleUtils.to_decimal(add.fprice * sell_total),
		    all_rprice  : wsaleUtils.to_decimal(add.rprice * sell_total),
		    all_tagprice: wsaleUtils.to_decimal(add.tag_price * sell_total),
		    
		    stock       : add.total,
		    negative    : add.negative ? diablo_yes : diablo_no,
		    sprice      : add.bargin_price === 3 ? diablo_yes : diablo_no,
		    ticket      : add.ticket,
		    
		    path        : sets(add.path), 
		    sizes       : add.sizes,
		    s_group     : add.s_group,
		    colors      : add.colors,
		    free        : add.free,
		    comment     : sets(add.comment), 
		    amounts     : details0
		})
	    } 
	};

	// reset oil
	$scope.select.oil = 0;
	angular.forEach(added, function(stock){
	    $scope.select.oil += wsaleCalc.calc_commision(
		stock,
		stock.sell_total,
		stock.commision,
		diablo_get_object(stock.commision, $scope.commisions));
	});
	
	console.log($scope.select); 
	console.log(added);
	
	// console.log($scope.select);
	var im_print = $scope.immediately_print($scope.select.shop.id);
	var p_mode = $scope.p_mode($scope.select.shop.id);
	var selectRetailer = $scope.select.retailer.id; 
	// console.log(im_print);
	var base = {
	    retailer:       $scope.select.retailer.id,
	    retailer_type:  $scope.select.retailer.type_id,
	    vip:            wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        sets($scope.select.comment),
	    ticket_batchs:  $scope.select.ticket_batchs,
	    ticket_custom:  $scope.select.ticket_custom,

	    balance:        $scope.select.surplus, 
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wxin:           setv($scope.select.wxin),
	    aliPay:         setv($scope.select.aliPay),
	    withdraw:       setv($scope.select.withdraw),
	    ticket:         setv($scope.select.ticket_balance),
	    verificate:     setv($scope.select.verificate), 

	    base_pay:       setv($scope.select.base_pay),
	    should_pay:     setv($scope.select.should_pay),
	    limitWithdraw:  setv($scope.select.limitWithdraw),
	    unlimitWithdraw:setv($scope.select.unlimitWithdraw),
	    // has_pay:        $scope.select.has_pay,
	    pay_order:      $scope.select.pay_order,
	    charge:         $scope.select.charge,
	    total:          $scope.select.total,
	    oil:            $scope.select.oil,
	    last_score:     $scope.select.retailer.score,
	    score:          $scope.select.score,
	    cards:          angular.isArray($scope.select.draw_cards)
		&& $scope.select.draw_cards.length !== 0 ? $scope.select.draw_cards : undefined,
	    
	    round:          $scope.setting.round,
	};

	var print = {
	    im_print:    im_print,
	    p_mode:      p_mode,
	    shop:        $scope.select.shop.name,
	    employ:      $scope.select.employee.name,
	    retailer_id: $scope.select.retailer.id,
	    retailer:    $scope.select.retailer.name
	};

	console.log(base);

	var dialog = diabloUtilsService; 
	wsaleService.new_w_sale({inventory:added.length===0 ? undefined:added, base:base, print:print}).then(function(result){
	    console.log(result);
	    var success_callback = function(){
		// clear local storage
		if (angular.isDefined($scope.select_draft_key)){
		    $scope.wsaleStorage.remove($scope.select_draft_key);
		    $scope.select_draft_key = undefined;
		};
		
		$scope.wsaleStorage.remove($scope.wsaleStorage.get_key()); 
		$scope.refresh();
		// $scope.focus_good_or_barcode();
		$scope.focus_by_element();
	    }
	    
	    if (result.ecode === 0){
		// check retailer trans count
		if (!$scope.select.sysVip && $scope.setting.trans_count !== 0 ) {
		    diabloFilter.check_retailer_trans_count(
			$scope.select.retailer.id,
			$scope.select.retailer.mobile,
			$scope.select.shop.id,
			$scope.setting.trans_count
		    ).then(function(check_result) {
			console.log(check_result);
		    })
		};
		
		$scope.select.rsn = result.rsn;
		if (diablo_backend === p_mode){
		    $scope.print_backend(result, im_print);
		    success_callback(); 
		} else {
		    $scope.print_front(result, im_print, success_callback); 
		}
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
	$scope.select.has_pay += wsaleUtils.to_float($scope.select.aliPay);
	
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

    $scope.calc_pay_order = function() {
	return wsaleCalc.pay_order(
	    $scope.select.should_pay,
	    [$scope.select.ticket_balance,
	     $scope.select.withdraw,
	     $scope.select.wxin,
	     $scope.select.aliPay,
	     $scope.select.card,
	     $scope.select.cash]);
    };
    
    $scope.reset_score = function() {
	// only score with cash, card, wxin, aliPay
	if (diablo_score_only_cash === $scope.setting.draw_score
	    && ( wsaleUtils.to_float($scope.select.withdraw) !== 0
		 || wsaleUtils.to_float($scope.select.ticket_balance) !== 0)) {
	    var pay_orders = $scope.calc_pay_order();
	    var pay_with_score = pay_orders[2] + pay_orders[3] + pay_orders[4] + pay_orders[5];
	    $scope.select.score = wsaleUtils.calc_score_of_pay(pay_with_score, $scope.select.pscores);
	} else if (diablo_score_none === $scope.setting.draw_score
		   && ( wsaleUtils.to_float($scope.select.withdraw) !== 0
			|| wsaleUtils.to_float($scope.select.ticket_balance) !== 0)) {
	    $scope.select.score = 0;
	}
    };
    
    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	// if ($scope.select.form.cashForm.$invalid) return; 
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	// if ($scope.select.form.cardForm.$invalid) return;
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.wxin", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	// if ($scope.select.form.wForm.$invalid) return;
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.aliPay", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	// if ($scope.select.form.wForm.$invalid) return;
	$scope.reset_payment(newValue);
	// $scope.reset_score();
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
	if ($scope.setting.show_wprice) return;
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	// $scope.reset_payment(newValue);
	$scope.re_calculate();
	// $scope.reset_score();
    });

    $scope.$watch("select.wprice", function(newValue, oldValue){
	// console.log(newValue);
	$scope.select.verificate = 0;
	if (newValue === oldValue ) return;
	if (angular.isUndefined(newValue) || null === newValue) {
	    for(var i=0, l=$scope.inventories.length; i<l; i++){
		var s = $scope.inventories[i];
		s.$update = false;
		s.o_fprice = s.fprice;
		s.o_fdiscount = s.fdiscount; 
		// s.fdiscount = s.discount;
		// s.fprice = diablo_price(s.tag_price, s.fdiscount);
	    }	    
	} else {
	    // var totalPay = 0;
	    // for(var i=0, l=$scope.inventories.length; i<l; i++){
	    // 	var s = $scope.inventories[i];
	    // 	totalPay += diablo_price(s.tag_price * s.sell, s.discount); 
	    // }
	    
	    // var mdiscount = diablo_discount(newValue, totalPay);
	    // for(var i=0, l=$scope.inventories.length; i<l; i++){
	    // 	var s = $scope.inventories[i];
	    // 	s.$update = true;
	    // 	s.fdiscount = wsaleUtils.to_decimal(s.discount * mdiscount / 100);
	    // 	s.fprice = diablo_price(s.tag_price, s.fdiscount);
	    // }
	    // console.log($scope.select.base_pay, $scope.select.should_pay);
	    $scope.select.verificate = $scope.select.base_pay - newValue;
	    // console.log($scope.select.base_pay, newValue, $scope.select.verificate);
	    // use original
	    for(var i=0, l=$scope.inventories.length; i<l; i++){
	    	var s = $scope.inventories[i];
		s.$update = false;
		s.o_fprice = s.fprice;
		s.o_fdiscount = s.fdiscount;
		
	    	// s.fdiscount = s.discount;
		// s.fprice = diablo_price(s.tag_price, s.fdiscount);
	    }
	    // $scope.select.verificate = $scope.select.should_pay - newValue;
	}
	
	$scope.re_calculate();
    });
    
    // var in_amount = function(amounts, inv){
    // 	for(var i=0, l=amounts.length; i<l; i++){
    // 	    if(amounts[i].cid === inv.color_id
    // 	       && amounts[i].size === inv.size){
    // 		amounts[i].count += parseInt(inv.amount);
    // 		return true;
    // 	    }
    // 	}
    // 	return false;
    // };

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
	$scope.select.oil          = 0;
	$scope.select.noTicketBalance = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;
	$scope.select.can_draw     = 0;
	$scope.select.base_pay     = 0;
	$scope.select.abs_pay      = 0;
	$scope.select.score        = 0;

	// console.log($scope.inventoyies);
	var calc = wsaleCalc.calculate(
	    // $scope.select.o_retailer,
	    // $scope.select.retailer,
	    wsaleUtils.isVip($scope.select.retailer, $scope.setting.no_vip, $scope.sysRetailers),
	    $scope.setting.vip_mode,
	    wsaleUtils.get_retailer_discount($scope.select.retailer.level, $scope.levels),
	    // wsaleUtils.get_retailer_level($scope.select.retailer.level, $scope.levels),
	    $scope.inventories,
	    $scope.show_promotions,
	    diablo_sale,
	    $scope.select.verificate,
	    $scope.setting.round,
	    $scope.setting.score_discount);
	
	// console.log(calc);
	// console.log($scope.show_promotions);
	$scope.select.total      = calc.total;
	$scope.select.oil        = calc.oil;
	$scope.select.noTicketBalance = calc.noTicketBalance;
	$scope.select.abs_total  = calc.abs_total;
	$scope.select.should_pay = calc.should_pay;
	$scope.select.can_draw   = calc.can_draw;
	$scope.select.base_pay   = calc.base_pay;
	$scope.select.abs_pay    = calc.abs_pay;
	$scope.select.score      = calc.score; 
	$scope.select.pscores    = calc.pscores;
	$scope.select.charge     = $scope.select.should_pay - $scope.select.has_pay;
	
	// if ($scope.setting.show_wprice && wsaleUtils.to_integer($scope.select.wprice) !==0) {
	//     // $scope.select.wprice = $scope.select.should_pay;
	//     // $scope.select.verificate = $scope.select.base_pay - $scope.select.should_pay;
	// }
	
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
	var sell_total = 0, note = "", negative = false;
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += wsaleUtils.to_integer(a.sell_count);
		note += diablo_find_color(a.cid, filterColor).cname + a.size + ";"
		if (a.sell_count > a.count) negative = true;
	    }
	}); 

	return {amounts:     params.amounts,
		sell:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,
		note:        note,
		negative:    negative};
    };

    var free_stock_not_enought = function(stock) {
	var existSaleStock = 0;
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var s = $scope.inventories[i];
	    if (stock.style_number === s.style_number && stock.brand_id === s.brand_id){
		existSaleStock += s.sell;
	    }
	} 
	return existSaleStock + stock.sell > stock.total;
    };

    var cs_stock_not_enought = function(stock) {
	var not_enought = false;
	if (stock.total < stock.sell) {
	    not_enought = true; 
	} else {
	    var existStocks = [];
	    for(var i=0, l=$scope.inventories.length; i<l; i++){
		var s = $scope.inventories[i];
		if (stock.style_number === s.style_number && stock.brand_id === s.brand_id){
		    existStocks.push(s); 
		}
	    }
	    
	    var willAmounts = stock.amounts.filter(function(a) {
		return wsaleUtils.to_integer(a.sell_count) > 0;
	    }).map(function(m) {
		return {cid:m.cid, size:m.size, sell_count:m.sell_count, count:m.count}
	    });
	    // console.log(willAmounts); 
	    
	    angular.forEach(existStocks, function(e) {
		var existAmounts = e.amounts;
		for (var j=0, k=willAmounts.length; j<k; j++) {
		    for (var m=0, n=existAmounts.length; m<n; m++) {
			if (existAmounts[m].sell_count > 0) {
			    if (existAmounts[m].cid === willAmounts[j].cid
				&& existAmounts[m].size === willAmounts[j].size) {
				willAmounts[j].sell_count += existAmounts[m].sell_count;
				if (willAmounts[j].sell_count > willAmounts[j].count) {
				    not_enought = true;
				    break;
				}
			    }
			    
			}
			
		    }
		}
	    });
	}
	
	return not_enought;
    };
    
    // var cs_stock_not_enought = function(stock) {
    // 	var not_enought = false;
    // 	for(var i=0, l=$scope.inventories.length; i<l; i++){
    // 	    var s = $scope.inventories[i];
    // 	    if (stock.style_number === s.style_number && stock.brand_id === s.brand_id){
    // 		angular.forEach(stock.amounts, function(a) {
    // 		    var sellCount = wsaleUtils.to_integer(a.sell_count);
    // 		    if (sellCount !== 0) {
    // 			for (var j=0,k=s.amounts.length; j<k; j++) {
    // 			    if (a.cid === s.amounts[j].cid && a.size === s.amounts[j].size) {
    // 				if (sellCount + wsaleUtils.to_integer(s.amounts[j].sell_count) > a.count) {
    // 				    not_enought = true;
    // 				    break;
    // 				}
    // 			    }
    // 			}
    // 		    } 
    // 		})
    // 	    }
    // 	}

    // 	// console.log(not_enought);
    // 	return not_enought;
    // };
    
    $scope.add_free_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer) || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return; 
	};

	var callback = function(reject) {
	    inv.$edit = true;
	    inv.$new  = false;
	    inv.sell = reject ? -inv.sell : inv.sell;
	    inv.amounts[0].sell_count = inv.sell;
	    $scope.inventories.unshift(inv);
	    inv.order_id = $scope.inventories.length;
	    
	    $scope.disable_refresh = false;
	    // $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
	    $scope.re_calculate();	    
	    $scope.focus_good_or_barcode(); 
	};
	
	// check stock total
	if ($scope.setting.check_sale && free_stock_not_enought(inv)) {
	    var ERROR = require("diablo-error");
	    if ($scope.setting.negative_sale) {
		diabloUtilsService.request("销售开单", ERROR[2180], callback, true, undefined); 
	    } else {
		diabloUtilsService.response_with_callback(
		    false,
		    "销售开单",
		    ERROR[2021],
		    undefined,
		    $scope.focus_by_element);
	    }
	} else {
	    callback(false); 
	}
	
	// if ($scope.setting.check_sale && free_stock_not_enought(inv)) {
	// 	// diabloUtilsService.set_error("销售开单", 2180); 
	//     var ERROR = require("diablo-error"); 
	//     diabloUtilsService.request("销售开单", ERROR[2180], callback, true, undefined);
	// } else {
	//     callback(false);
	// } 
	
    };
    
    $scope.calc_discount = function(inv){
	if (inv.pid !== -1 && inv.promotion.rule_id === 0){
	    return inv.discount < inv.promotion.discount ? inv.discount : inv.promotion.discount;
	} 
	else {
	    return inv.discount;
	}
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.retailer) || diablo_is_empty($scope.select.retailer)){
	    diabloUtilsService.response(
	    	false, "销售开单", "开单失败：" + wsaleService.error[2192]);
	    return;
	    // $scope.reset_retailer();
	};

	// inv.cdiscount      = inv.discount;
	// inv.cprice         = inv.tag_price;

	inv.fdiscount = inv.discount;
	inv.fprice    = diablo_price(inv.tag_price, inv.discount);

	// inv.fdiscount = $scope.calc_discount(inv); 
	// inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);

	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	// if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	//     inv.free_color_size = true;
	//     inv.amounts         = [{cid:0, size:0}];
	//     inv.sell = 1; 
	//     $scope.auto_save_free(inv);
	// }
	// else {
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
		$scope.auto_focus("sell");
		inv.free_color_size = true;
		inv.amounts = [{cid:0, size:0, count:inv.total}];
		inv.sell = 1; 
		$scope.auto_save_free(inv);
	    } else{
		var after_add = function(){
		    if ($scope.setting.check_sale
			&& cs_stock_not_enought(inv)
			&& !$scope.setting.negative_sale) {
			var ERROR = require("diablo-error");
			diabloUtilsService.response_with_callback(
			    false,
			    "销售开单",
			    ERROR[2021],
			    undefined,
			    $scope.focus_by_element);
		    } else {
			inv.$edit = true;
			inv.$new = false;
			$scope.disable_refresh = false;
			$scope.inventories.unshift(inv);
			
			inv.order_id = $scope.inventories.length;
			// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
			$scope.re_calculate();
			$scope.focus_good_or_barcode();
		    } 
		};

		var callback = function(params){
		    console.log(params);
		    var result  = add_callback(params);
		    // console.log(result);
		    if (inv.fprice !== result.fprice || inv.fdiscount !== result.fdiscount) {
			inv.$update = true;
		    }
		    inv.amounts    = result.amounts;
		    inv.sell       = result.sell;
		    inv.fdiscount  = result.fdiscount;
		    inv.fprice     = result.fprice;
		    inv.note       = result.note;
		    inv.negative   = result.negative;
		    after_add();
		};

		var focus_first = function() {
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			inv.amounts[i].focus = false;
			if (wsaleUtils.to_integer(inv.amounts[i].count) !==0) {
			    inv.amounts[i].focus = true;
			}
		    }
		}

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
		    cancel_callback:  function(close) {
			$scope.focus_by_element();},
		    right:          $scope.right
		}; 
		
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
		    
		    var bcode_size = bcode_size_index === 0 ? diablo_free_size:size_to_barcode[bcode_size_index];
		    // console.log(bcode_color);
		    // console.log(bcode_size);
		    // angular.forEach(inv.amounts, function(a) {
		    // console.log(a.cid, inv.colors);
		    var scan_found = false;
		    for (var i=0, l=inv.amounts.length; i<l; i++) {
			var color;
			inv.amounts[i].focus = false; 
			// find color first
			for (var j=0, k=inv.colors.length; j<k; j++) {
			    if (inv.amounts[i].cid === inv.colors[j].cid) {
				color = inv.colors[j];
				break;
			    }
			} 
			// console.log(color);
			
			// find size
			if ( angular.isDefined(color) && angular.isObject(color)
			     && color.bcode === bcode_color
			     && inv.amounts[i].size === bcode_size ) {
			    inv.amounts[i].sell_count = 1; 
			    inv.amounts[i].focus = true;

			    inv.sell      = inv.amounts[i].sell_count;
			    inv.fdiscount = inv.discount;
			    inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);
			    inv.note      = color.cname + inv.amounts[i].size + ";"
			    scan_found    = true;
			    break;
			}
		    }
		    
		    if (scan_found){
			after_add();
		    } 
		    else {
			focus_first();
			diabloUtilsService.edit_with_modal(
			    "wsale-new.html",
			    modal_size,
			    callback,
			    undefined,
			    payload); 
		    }
		} else {
		    focus_first();
		    diabloUtilsService.edit_with_modal(
			"wsale-new.html",
			modal_size,
			callback,
			undefined,
			payload); 
		    
		}
	    }
	});
	// } 
    };
    
    /*
     * delete inventory
     */
    $scope.delete_inventory_head = function() {
	$scope.inventories.splice(0, 1);
	$scope.focus_good_or_barcode();
    };
    
    $scope.delete_inventory = function(inv){
	console.log(inv); 
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

	// if ($scope.inventories.length > 1){
	//     $scope.wsaleStorage.save(
	// 	$scope.inventories.filter(function(r){return !r.$new})); 
	// } else {
	//     $scope.wsaleStorage.remove($scope.wsaleStorage.get_key());
	// }

	if ($scope.inventories.length === 0) {
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
	
	// document.getElementById("barcode").focus();
	$scope.focus_by_element();
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
    $scope.update_inventory = function(inv, updateCallback, scan){
	console.log(inv);
	// inv.$update = true; 
	if (inv.free_color_size){
	    inv.free_update = true;
	    if (angular.isDefined(scan) && scan) {
	    	if (wsaleUtils.to_integer(inv.sell) === 0)
	    	    inv.sell = 1;
	    	else
	    	    inv.sell += 1;

	    	$scope.auto_save_free(inv);
	    } else {
	    	$scope.auto_focus("sell");
	    }
	    
	    return;
	}

	if (angular.isDefined(scan) && scan && $scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
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
		a.focus = false;
		var color;
		for (var i=0, l=inv.colors.length; i<l; i++) {
		    if (a.cid === inv.colors[i].cid) {
			color = inv.colors[i];
			break;
		    }
		} 
		// console.log(color); 
		if (angular.isDefined(color) && color.bcode === bcode_color && a.size === bcode_size) {
		    if (wsaleUtils.to_integer(a.sell_count) === 0)
			a.sell_count = 1;
		    else
			a.sell_count += 1;
		    a.focus = true;
		}
	    });
	} else {
	    for (var i=0, l=inv.amounts.length; i<l; i++) {
		var a = inv.amounts[i];
		a.focus = false;
		if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
		    a.focus = true;
		}
	    }
	}
	
	var callback = function(params){
	    var result  = add_callback(params);
	    console.log(result); 
	    // if (inv.sell !== result.sell) 
	    // 	inv.$update_count = true;
	    if (!$scope.setting.hide_fixed_stock
		&& $scope.setting.fixed_mode === diablo_fixed_reduction
		&& !$scope.right.master) {
		if (inv.fprice !== result.fprice && inv.tag_price - result.fprice > inv.draw) {
		    dialog.set_error("销售开单", 2718);
		    return;
		}
		else if (inv.fdiscount !== result.fdiscount
			 && inv.tag_price - diablo_price(inv.tag_price, result.fdiscount) > inv.draw) {
		    dialog.set_error("销售开单", 2718);
		    return;
		} 
	    }
	    
	    if (inv.fprice !== result.fprice || inv.fdiscount !== result.fdiscount) inv.$update = true;
	    
	    inv.amounts    = result.amounts;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    inv.note       = result.note;
	    inv.negative   = result.negative;

	    // inv.note 
	    // save
	    // $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate();
	    $scope.focus_by_element();

	    if (angular.isDefined(updateCallback) && angular.isFunction(updateCallback))
		updateCallback();
	    // inv.$update = false;
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
		       cancel_callback:  function() {
			   $scope.focus_by_element();
		       },
		       right:        $scope.right};
	console.log(payload);
	diabloUtilsService.edit_with_modal("wsale-new.html", modal_size, callback, undefined, payload)
    };

    $scope.save_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;

	// if (inv.amounts[0].sell_count !== inv.sell)
	//     inv.$update_count = true; 
	inv.amounts[0].sell_count = inv.sell;

	
	// 	inv.$update_count = true;
	if (!$scope.setting.hide_fixed_stock
	    && $scope.setting.fixed_mode === diablo_fixed_reduction
	    && !$scope.right.master) {
	    if (inv.fprice !== inv.o_fprice && inv.tag_price - inv.fprice > inv.draw) {
		inv.free_update = true;
		inv.fprice = inv.o_fprice;
		inv.fdiscount = inv.o_fdiscount;
		dialog.set_error("销售开单", 2718); 
		return;
	    }
	    else if (inv.fdiscount !== inv.o_fdiscount
		     && inv.tag_price - diablo_price(inv.tag_price, inv.fdiscount) > inv.draw) {
		inv.free_update = true;
		inv.fprice = inv.o_fprice;
		inv.fdiscount = inv.o_fdiscount;
		dialog.set_error("销售开单", 2718);
		return;
	    }
	}
		
	// save
	// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	if (inv.fprice !== inv.o_fprice || inv.fdiscount !== inv.o_fdiscount) inv.$update = true;

	$scope.re_calculate();
	
	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode();
	
	// inv.$update = false; 
    };

    $scope.cancel_free_update = function(inv){
	// console.log(inv);
	// $timeout.cancel($scope.timeout_auto_save);
	// inv.$update = false;
	inv.free_update = false;
	inv.sell      = inv.amounts[0].sell_count;
	inv.fdiscount = inv.o_fdiscount;
	inv.fprice    = inv.o_fprice;
	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.re_calculate(); 
    };

    $scope.reset_inventory = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	// $scope.inventories[0] = {$edit:false, $new:true};
	$scope.focus_good_or_barcode(); 
    };

    $scope.auto_save_free = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	
	var sell = wsaleUtils.to_integer(inv.sell);
	if (sell !== 0 && angular.isDefined(inv.style_number)) {
	    if (inv.$new && inv.free_color_size){
		$scope.add_free_inventory(inv);
	    } 

	    if (!inv.$new && inv.free_update){
		if ($scope.setting.check_sale && sell > inv.total){
		    if (angular.isDefined(inv.form.sell)) {
			inv.form.sell.$invalid = true;
			inv.form.sell.$pristine = false; 
		    }
		    inv.invalid_sell = true; 
		} else if (!$scope.setting.negative_sale && sell < 0) {
		    if (angular.isDefined(inv.form.sell)) {
			inv.form.sell.$invalid = true;
			inv.form.sell.$pristine = false;
		    }
		    inv.invalid_sell = true;
		} else {
		    $scope.save_free_update(inv); 
		}
	    } 
	} 
    };


    var get_pay_scan_balance = function(pay_order, pay_type, pay_balance) {
	if (pay_type === diablo_wxin_scan) {
	    $scope.select.wxin = wsaleUtils.to_float(pay_balance);
	    $scope.select.pay_order = pay_order;
	}
	else if (pay_type === diablo_alipay_scan) {
	    $scope.select.aliPay = wsaleUtils.to_float(pay_balance);
	    $scope.select.pay_order = pay_order;
	}
	else {
	    // default alipay
	    $scope.select.pay_order = pay_order; 
	    $scope.select.wxin = 0;
	    $scope.select.aliPay = wsaleUtils.to_float(pay_balance);
	} 
    };
    
    $scope.check_pay_scan = function(pay) {
	diabloFilter.check_pay_scan(
	    pay.sn, pay.shop_id, $scope.setting.pay_scan_use
	).then(function(result) {
	    console.log(result); 
	    if (result.ecode === 0) {
		// success
		get_pay_scan_balance(pay.sn, result.pay_type, result.balance);
		pay.state = result.pay_state;
		pay.balance = result.balance;
	    } else if (result.ecode === 2686) {
		get_pay_scan_balance(pay.sn, result.pay_type, result.balance);
		pay.state = result.pay_state; 
		dialog.response(
		    true,
		    "扫码支付核实",
		    "扫码支付核实成功，系统更新支付信息失败！！");
	    } else if (result.ecode === 2615) {
		dialog.response(
		    false,
		    "扫码支付核实",
		    "扫码支付核实失败，请尝试重新核实！！" + "错误码=" + result.pay_code.toString());
	    } else {
		dialog.set_error("扫码支付", result.ecode);
	    }
	});
    };
    
    $scope.refresh_pay_scan = function(pay_order) {
	var shopIds = user.shopIds.length === 0 ? undefined : user.shopIds; 
	diabloFilter.filter_pay_scan(
	    undefined, {shop:shopIds, sn:pay_order}, 1, diablo_items_per_page()
	).then(function(result) {
	    console.log(result);
	    $scope.pay_scan_history = result.data;
	    diablo_order($scope.pay_scan_history);
	})
    }; 

    // paySpeak.set_text("300");
    // paySpeak.speak();
    $scope.pay_scan = function(pay_type) {
	var callback = function(params) {
	    console.log(params);
	    if (params.pay_code.toString().length !== diablo_scan_code_length) {
		dialog.set_error("扫码支付：", 2617);
	    } else {
		diabloFilter.pay_scan(
		    $scope.select.shop.id,
		    pay_type,
		    $scope.setting.pay_scan_use,
		    params.pay_code,
		    params.balance
		).then(function(result) {
		    console.log(result); 
		    if (result.ecode === 0) {
			// play sound
			var paySpeak = new diabloPaySpeak(); 
			if (pay_type === diablo_wxin_scan) {
			    paySpeak.set_text(
				"微信收款" + diablo_set_string(result.balance) + "元"); 
			} else {
			    paySpeak.set_text(
				"支付宝收款" + diablo_set_string(result.balance) + "元"); 
			}
			paySpeak.speak();
			
			get_pay_scan_balance(result.pay_order, result.pay_type, result.balance);
			$scope.refresh_pay_scan(result.pay_order);
		    } else if (result.ecode === 2687) {
			$scope.refresh_pay_scan(result.pay_order);
			dialog.response(
			    false,
			    "扫码支付",
			    "用户支付状态未知，请主动通过支付记录核对支付结果后操作！！") 
		    } else if (result.ecode === 2688) {
			get_pay_scan_balance(result.pay_order, result.pay_type, result.balance);
			dialog.response(
			    true,
			    "扫码支付",
			    "扫码支付成功，系统记录支付信息失败！！");
		    } else if (result.ecode === 2614) {
			dialog.response(
			    false,
			    "扫码支付",
			    "扫码支付失败，请重新扫码！！" + "错误码=" + result.pay_code.toString());
		    } else {
			dialog.set_error("扫码支付", result.ecode);
		    } 
		})
	    } 
	};
	
	var balance = $scope.select.charge;
	if (balance > 0 &&  balance < diablo_max_pay_scan) {
	    // var paySpeak = new diabloPaySpeak(); 
	    // if (pay_type === diablo_wxin_scan) {
	    // 	paySpeak.set_text(
	    // 	    "微信收款" + diablo_set_string(balance) + "元"); 
	    // } else {
	    // 	paySpeak.set_text(
	    // 	    "支付宝收款" + diablo_set_string(balance) + "元"); 
	    // }
	    // paySpeak.speak();
	    dialog.edit_with_modal(
		"pay-scan.html",
		undefined,
		callback,
		undefined,
		{balance: balance});
	}
    };

    $scope.reject_inventory = function(inv) {
	console.log(inv);
	if (wsaleUtils.to_integer(inv.sell) > 0) {
	    inv.sell = -inv.sell;
	    angular.forEach(inv.amounts, function(a) {
		if (angular.isDefined(a.sell_count) && wsaleUtils.to_integer(a.sell_count) > 0) {
		    a.sell_count = -a.sell_count;
		}
	    });

	    $scope.re_calculate();
	} 
    };

    $scope.gift_sale = function(inv) {
	inv.fprice = 0;
	inv.$update = true;
	// $scope.wsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
    };
};

function wsaleNewDetailProvide(
    $scope, $routeParams, $location, dateFilter, diabloUtilsService,
    localStorageService, diabloFilter, wsaleService,
    user, filterEmployee, filterTicketPlan, base){
    $scope.shops     = user.sortShops.filter(function(s) {return s.deleted===0});
    $scope.shopIds   = user.shopIds;
    $scope.records   = [];
    
    $scope.goto_page = diablo_goto_page;
    $scope.f_add     = diablo_float_add;
    $scope.f_sub     = diablo_float_sub;
    $scope.f_mul     = diablo_float_mul;
    $scope.round     = diablo_round;
    $scope.css       = diablo_stock_css;

    $scope.setting   = {};
    
    $scope.total_items   = 0;
    $scope.default_page = 1; 
    $scope.disable_print = false;
    $scope.current_page = $scope.default_page;

    $scope.ticketPlans = filterTicketPlan.filter(function(p) {
	return !p.deleted && p.mbalance !== diablo_invalid;
    }).sort(function(p1, p2) {
	return p2.balance - p1.balance;
    }).map(function(p) {
	return {id:       p.id,
		rule:     p.rule,
		name:     p.name + "-" + p.balance + "元",
		balance:  p.balance,
		mbalance: p.mbalance,
		effect:   p.effect,
		expire:   p.expire,
		stime:    p.stime,
		etime:    p.etime,
		scount:   p.scount}
    }); 

    // console.log($scope.ticketPlans);

    // var calendar = require("diablo-calendar"); 
    // console.log(calendar.solar2lunar(2020,7,20));
    
    // var LODOP = undefined;
    // if (diablo_frontend === wsaleUtils.print_mode(user.loginShop, base)) {
    // 	var print_access = wsaleUtils.print_num(user.loginShop, base); 
    // 	if (needCLodop()) loadCLodop(print_access.protocal);
    // }
    
    // var im_print = function(shopId){
    // 	return wsaleUtils.im_print(shopId, base); 
    // };

    // var print_mode = 
    // console.log($scope.im_print); 
    /*
     * authen
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.shop_right = authen.authenSaleRight();
    // console.log($scope.shop_right);
    // $scope.shop_right = {
    // 	update_w_sale: wsaleUtils.authen_shop(user.type, user.shop, 'update_w_sale'),
    // 	check_w_sale: wsaleUtils.authen_shop(user.type, user.shop, 'check_w_sale'),
    // 	master:rightAuthen.authen_master(user.type),
    // 	show_stastic: rightAuthen.authen_master(user.type) 
    // }; 

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
	return wsaleUtils.match_retailer_phone(
	    viewValue,
	    diabloFilter,
	    $scope.shopIds.length === 1 ? $scope.shopIds[0] : [],
	    $scope.setting.solo_retailer);
    };
    
    // initial
    diabloFilter.reset_field();
    diabloFilter.add_field("shop",        $scope.shops);
    diabloFilter.add_field("account",     []); 
    diabloFilter.add_field("employee",    filterEmployee); 
    diabloFilter.add_field("retailer",    $scope.match_retailer); 
    diabloFilter.add_field("rsn",         $scope.match_rsn);
    diabloFilter.add_field("check_state", wsaleService.check_state);
    diabloFilter.add_field("comment",     wsaleService.check_comment);
    diabloFilter.add_field("mticket",     []);

    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    // console.log($scope.filter);
    // console.log($scope.prompt); 
    $scope.sequence_pagination = wsaleUtils.sequence_pagination(diablo_default_shop, base); 
    var sale_mode = wsaleUtils.sale_mode(diablo_default_shop, base);
    $scope.setting.gift_ticket_on_sale = wsaleUtils.to_integer(sale_mode.charAt(19));
    $scope.setting.gift_ticket_strategy = wsaleUtils.to_integer(sale_mode.charAt(22));
    $scope.setting.solo_retailer = wsaleUtils.solo_retailer(
	$scope.shopIds.length === 1 ? $scope.shopIds[0] : diablo_default_shop, base);
    
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
	// console.log(page); 
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
	    $scope.total_bpay        = stastic.total_bpay;
	    $scope.total_spay        = stastic.total_spay;
	    $scope.total_veri        = stastic.total_veri;
	    $scope.total_cash        = stastic.total_cash;
	    $scope.total_card        = stastic.total_card;
	    $scope.total_wxin        = stastic.total_wxin;
	    $scope.total_aliPay      = stastic.total_aliPay;
	    $scope.total_withdraw    = stastic.total_withdraw;
	    $scope.total_ticket      = stastic.total_ticket;
	    $scope.total_balance     = stastic.total_balance;
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
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
		    $scope.total_bpay        = result.t_bpay;
		    $scope.total_spay        = result.t_spay;
		    $scope.total_veri        = result.t_veri;
		    $scope.total_cash        = result.t_cash;
		    $scope.total_card        = result.t_card;
		    $scope.total_wxin        = result.t_wxin;
		    $scope.total_aliPay      = result.t_aliPay;
		    $scope.total_withdraw    = result.t_withdraw;
		    $scope.total_ticket      = result.t_ticket;
		    $scope.total_balance     = result.t_balance;

		    $scope.records = [];
		    $scope.save_stastic();
		}
		
		// console.log($scope); 
		angular.forEach(result.data, function(d){
		    d.crsn     = diablo_array_last(d.rsn.split(diablo_date_seprator));
		    d.shop     = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee = diablo_get_object(d.employee_id, filterEmployee);
		    // d.retailer = diablo_get_object(d.retailer_id, filterRetailer);
		    d.has_pay  = d.should_pay;
		    d.should_pay = wsaleUtils.to_decimal(d.should_pay + d.verificate);
		    // charge
		    d.left_balance = wsaleUtils.to_decimal(d.balance - d.withdraw);
		    d.check  = wsaleUtils.to_integer(d.state.charAt(0)),
		    d.reject = wsaleUtils.to_integer(d.state.charAt(1))
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
	     total_bpay:        $scope.total_bpay,
	     total_spay:        $scope.total_spay,
	     total_veri:        $scope.total_veri,
	     total_cash:        $scope.total_cash,
	     total_card:        $scope.total_card,
	     total_wxin:        $scope.total_wxin,
	     total_aliPay:      $scope.total_aliPay,
	     total_withdraw:    $scope.total_withdraw,
	     total_ticket:      $scope.total_ticket,
	     total_balance:     $scope.total_balance,
	     t:                 now});
    };
    
    $scope.rsn_detail = function(r){
	// console.log(r);
	// $scope.save_stastic(); 
	diablo_goto_page("#/wsale_rsn_detail/" + r.rsn + "/" + $scope.current_page.toString());
    };

    $scope.update_detail = function(r){
	// $scope.save_stastic();
	if (r.type === 0){
	    diablo_goto_page('#/update_wsale_detail/' + r.rsn + "/" + $scope.current_page.toString()); 
	} else {
	    diablo_goto_page('#/update_wsale_reject/' + r.rsn + "/" + $scope.current_page.toString()); 
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
		    $scope, function(){r.check = 1})
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
		    $scope, function(){r.check = 0})
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

    var giftTitle = "会员电子券赠送";
    $scope.gift_ticket = function(r) {
	console.log(r);
	if (r.g_ticket === diablo_yes) {
	    dialog.set_error(giftTitle, 2714);
	} else if ($scope.ticketPlans.length === 0) {
	    dialog.set_error(giftTitle, 2715);
	} else {	    
	    // wsaleService.get_w_sale_new(r.rsn).then(function(result) {
	    // 	console.log(result);
	    // 	var noTicketBalance = 0;
	    // 	if (result.ecode === 0) {
	    // 	    for (var i=0, l=result.detail.length; i<l; i++) {
	    // 		var d = result.detail[i];
	    // 		// the stock can not gift ticket
	    // 		if (diablo_no === wsaleUtils.yes_default(d.has_rejected.charAt(3))) {
	    // 		    noTicketBalance += d.rprice * d.total;
	    // 		}
	    // 	    } 
	    // 	    noTicketBalance = diablo_round(noTicketBalance);

	    // var wholeBalance = (r.has_pay - r.ticket - noTicketBalance)
	    // 	- (r.has_pay - r.ticket - noTicketBalance) % 100;
	    var wholeBalance = (r.has_pay - r.ticket) - (r.has_pay - r.ticket ) % 100;
	    var realBalance  = wholeBalance;
	    var ticketLength = $scope.ticketPlans.length;
	    var validPlans   = [], maxSend;
	    
	    var callback = function(params) {
		console.log(params);
		// get all ticket
		var send_tickets = [];
		var gift_balance = 0; 
		angular.forEach(params.tickets, function(t) {
	    	    if (t.plan.id !== diablo_invalid_index) {
	    		send_tickets.push({id      :t.plan.id,
					   rule    :t.plan.rule,
					   balance :t.plan.balance,
					   count   :t.count,
					   effect  :t.plan.effect,
					   expire  :t.plan.expire,
					   stime   :t.plan.stime,
					   etime   :t.plan.etime});
			gift_balance += t.plan.mbalance * t.count;
	    	    }
		}); 
		console.log(send_tickets); 
		
		if (gift_balance > wholeBalance) {
		    dialog.set_error("会员电子券赠送", 2716);
		} else {
		    diabloFilter.wretailer_gift_ticket({
			shop           :r.shop_id,
			shop_name      :r.shop.name,
			retailer       :r.retailer_id,
			employee       :r.employee_id,
			retailer_name  :r.retailer,
			retailer_phone :r.rphone,
			ticket         :send_tickets,
			rsn            :r.rsn
		    }).then(function(result) {
			console.log(result);
			if (result.ecode === 0) {
			    r.g_ticket = diablo_yes;
			    dialog.response(
				true,
				"会员优惠卷赠送",
				"会员[" + r.retailer + "] 卷赠送成功！！"
				    + function() {
					if (result.sms_code !== 0) {
					    var ERROR = require("diablo-error");
					    return "发送短消息失败：" + ERROR[result.sms_code];
					} 
					else return ""; 
				    }()
			    );
			} else {
			    dialog.set_error("会员电子券赠送", result.ecode);
			}
		    });
		} 
	    };
	    
	    if (0 === $scope.setting.gift_ticket_strategy) {
		maxSend = 5;
		// max
		if (realBalance >= $scope.ticketPlans[0].mbalance) {
		    validPlans.push({plan:$scope.ticketPlans[0], count: 1});
		    realBalance -= $scope.ticketPlans[0].mbalance;
		    maxSend -= 1;
		}

		// min
		if (realBalance >= $scope.ticketPlans[ticketLength - 1].mbalance) {
		    validPlans.push({plan:$scope.ticketPlans[ticketLength - 1], count: 1});
		    realBalance -= $scope.ticketPlans[ticketLength - 1].mbalance;
		    maxSend -= 1;
		}

		for (var i=1, l=ticketLength - 1; i<l; i++) {
		    if (realBalance >= $scope.ticketPlans[i].mbalance) {
			validPlans.push({plan:$scope.ticketPlans[i], count: 1});
			realBalance -= $scope.ticketPlans[i].mbalance;
			maxSend -= 1;
		    }
		}

		// left use min
		while (maxSend > 0 && realBalance > $scope.ticketPlans[ticketLength - 1].mbalance) {
		    validPlans.push({plan:$scope.ticketPlans[ticketLength - 1], count: 1});
		    realBalance -= $scope.ticketPlans[ticketLength - 1].mbalance;
		    maxSend -= 1;
		}
	    } else if (1 === $scope.setting.gift_ticket_strategy) {
		for (var i=0; i<ticketLength; i++) {
		    if (realBalance >= $scope.ticketPlans[i].mbalance) {
			validPlans.push({plan:$scope.ticketPlans[i], count: 1});
			realBalance -= $scope.ticketPlans[i].mbalance;
			break;
		    }
		}
	    } else if (2 === $scope.setting.gift_ticket_strategy){
		var i, use;
		for (var i=0; i<ticketLength; i++) {
		    if (realBalance >= $scope.ticketPlans[i].mbalance) {
			use = Math.floor(realBalance / $scope.ticketPlans[i].mbalance);
			if (use > 0) {
			    validPlans.push({plan:$scope.ticketPlans[i], count: use}); 
			    realBalance -= $scope.ticketPlans[i].mbalance * use;
			}
		    }
		}

		if (validPlans.length !== 0 && realBalance > 0) {
		    validPlans[validPlans.length - 1].count -= 1;
		    realBalance += validPlans[validPlans.length - 1].plan.mbalance;
		    i--;
		    for (i; i<ticketLength; i++) {
			if (realBalance >= $scope.ticketPlans[i].mbalance) {
			    use = Math.floor(realBalance / $scope.ticketPlans[i].mbalance);
			    if (use > 0) {
				validPlans.push({plan:$scope.ticketPlans[i], count: use}); 
				realBalance -= $scope.ticketPlans[i].mbalance * use;
			    }
			} 
		    }
		}
	    }

	    dialog.edit_with_modal(
		"detail-gift-ticket.html",
		undefined,
		callback,
		undefined,
		{tickets: validPlans.filter(function(p) {return p.count !== 0}),
		 add_ticket: function(tickets, planes, balance) {
		     tickets.push({plan:planes[planes.length-1], count:1});
		     balance -= tickets[tickets.length - 1].plan.mbalance;
		     return balance;
		 }, 
		 delete_ticket: function(tickets, balance) {
		     balance += tickets[tickets.length - 1].plan.mbalance * tickets[tickets.length - 1].count; 
		     tickets.splice(-1, 1);
		     return balance;
		 }, 
		 check_ticket: function(planes, balance) {
		     return balance >= planes[planes.length - 1].mbalance;
		 },
		 calc_balance: function(tickets) {
		     var useBalance = 0;
		     for (var i=0, l=tickets.length; i<l; i++) {
			 useBalance += tickets[i].plan.mbalance * tickets[i].count;
		     }
		     return wholeBalance - useBalance;
		 },
		 balance: realBalance,
		 planes: $scope.ticketPlans
		});
	    
	    // } else {
	    //     dialog.set_error(giftTitle, 2717);
	    // }
	    // }); 
	} 
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
			    "创建文件成功，请点击确认下载！！",
			    undefined,
			    function(){window.location.href = result.url;}) 
		    } else {
			diablo.response(
			false,
			    "文件导出失败", "创建文件失败：" + wsaleService.error[result.ecode]);
		    } 
		}); 
	}) 
    };
};
