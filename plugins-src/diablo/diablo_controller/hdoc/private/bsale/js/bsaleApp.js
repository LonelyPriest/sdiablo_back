"use strict";

define(["angular",
	"angular-router",
	"angular-resource",
	"angular-local-storage", 
        "angular-ui-bootstrap",
	"diablo-authen",
	"diablo-pattern",
	"diablo-user-right",
        "diablo-authen-right",
	"diablo-utils",
	"diablo-filter"], bsaleConfig);


function bsaleConfig(angular){
    var bsaleApp = angular.module(
	'bsaleApp',
	['ui.bootstrap',
	 'ngRoute',
	 'ngResource',
	 'LocalStorageModule',
	 'diabloAuthenApp',
	 'diabloPattern',
	 'diabloUtils',
	 'diabloFilterApp',
	 'diabloNormalFilterApp',
	 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('bsaleApp')
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
    
    bsaleApp.config(['$routeProvider', function($routeProvider){
	// $locationProvider.html5Mode(true);
	var user = {"user": function(userService){
	    return userService()}};

	var region = {"filterRegion": function(diabloNormalFilter){
	    return diabloNormalFilter.get_region()}}; 

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
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}};

	var ctype = {"filterCType": function(diabloFilter) {
	    return diabloFilter.list_good_ctype()}};

	var department = {"filterDepartment": function(diabloNormalFilter){
	    return diabloNormalFilter.get_department()}};
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var sysbsaler = {"filterSysBSaler": function(diabloNormalFilter){
    	    return diabloNormalFilter.get_sys_bsaler()}};

	var card = {"filterCard": function(diabloNormalFilter){
	    return diabloNormalFilter.get_card()}};
	
	$routeProvider. 
	    when('/new_bsale', {
		templateUrl: '/private/bsale/html/new_bsale.html',
		controller: 'bsaleNewCtrl',
		resolve: angular.extend(
		    {},
		    employee, s_group, brand, type, color, region, department, sysbsaler, user, base)
	    }).
	    when('/update_bsale_detail/:rsn?', {
		templateUrl: '/private/bsale/html/update_bsale_detail.html',
		controller: 'updateBSaleDetailCtrl',
		resolve: angular.extend(
		    {},
		    employee, s_group, brand, type, color, region, department, user, base)
	    }).
	    when('/update_bsale_reject/:rsn?', {
		templateUrl: '/private/bsale/html/update_bsale_reject.html',
		controller: 'updateBSaleRejectCtrl',
		resolve: angular.extend(
		    {},
		    employee, s_group, brand, type, color, region, department, user, base)
	    }).
	    when('/print_bsale/:rsn?', {
		templateUrl: '/private/bsale/html/print_bsale_detail.html',
		controller: 'bsalePrintCtrl',
		resolve: angular.extend({}, employee, region, department, card, user, base)
	    }).
	    when('/list_bsale_new', {
		templateUrl: '/private/bsale/html/new_bsale_detail.html',
		controller: 'bsaleNewDetailCtrl',
		resolve: angular.extend({}, employee, region, department, user, base)
	    }).
	    when('/list_bsale_new_detail/:rsn?', {
		templateUrl: '/private/bsale/html/new_bsale_note.html',
		controller: 'bsaleNewNoteCtrl',
		resolve: angular.extend(
		    {}, employee, s_group, firm, brand, ctype, type, color, region, department, user, base)
	    }). 
	    when('/new_bsaler', {
		templateUrl: '/private/bsale/html/new_bsaler.html',
		controller: 'bsalerNewCtrl',
		resolve: angular.extend({}, region, user)
	    }).
	    when('/bsaler_detail', {
		templateUrl: '/private/bsale/html/bsaler_detail.html',
		controller: 'bsalerDetailCtrl',
		resolve: angular.extend({}, region, user)
	    }).
	    otherwise({
		templateUrl: '/private/bsale/html/new_bsale_detail.html',
		controller: 'bsaleNewDetailCtrl',
		resolve: angular.extend(
		    {},
		    employee, s_group, brand, type, color, region, department, user, base) 
            }) 
    }]);

    bsaleApp.service("bsaleService", function($http, $resource, dateFilter){
	this.error = {
	    2180: "库存不足，请选择另外货品！！",
	    2190: "该款号库存不存在！！请确认本店是否进货该款号！！",
	    2192: "客户或营业员不存在，请建立客户或营业员资料！！",
	    2193: "该款号吊牌价小于零，无法出售，请定价后再出售！！",
	    2194: "该款号无入库记录，请先入库后再出售或重新选择货品！！",
	    2195: "该条码对应的库存不存在，请确认条码是否正确，或通过款号模式开单！！",
	    2196: "非法条码，条码长度不小于9，请输入正确的条码值！！",
	    2401: "店铺打印机不存在或打印处理暂停状态！！",
	    
	    2705: "应付款项与开单项计算有不符！！",
	    2708: "系统时间与服务器时间相差大于30分钟， 请检查系统时间或重新操作！！",
	    2712: "货品数量校验不通过，请核对该货品数量后再导入！！", 
	    2699: "修改前后信息一致，请重新编辑修改项！！",
	    
	    9001: "数据库操作失败，请联系服务人员！！"
	};
	
	this.bsaler_types   = [{name: "普通客户", id:0}, {name: "系统客户", id:2}]; 
	this.bsale_types    =  [{name:"销售开单", id:0, py:diablo_pinyin("销售开单")},
    				{name:"销售退货", id:1, py:diablo_pinyin("销售退货")}];

	this.check_state    = [{name:"未审核", id:0}, {name:"已审核", id:1}];
	this.check_comment  = [{name:"不为空", id:0}];
	this.export_type    = {sale_new:0, sale_new_detail:1}; 
	// this.default_bsaler = {name: "", id:-1};
	
	this.diablo_key_bsale_detail  = "q-bsale-detail";
	
	this.diablo_key_bsale_note    = "q-bsale-note";
	this.diablo_key_bsale_note_stastic = "s-bsale-note-stastic";
	
	this.diablo_key_bsaler        = "q-bsaler-detail";
	this.diablo_key_bsaler_stastic= "s-bsaler-stastic";


	var request = $resource(
	    "/bsale/:operation/:id", {operation: '@operation', id: '@id'}, {post: {method: 'POST', isArray: true}});

	this.new_batch_sale = function(payload) {
	    return request.save({operation: "new_batch_sale"}, payload).$promise;
	};

	this.filter_bsale_new = function(match, fields, currentPage, itemsPerpage){
	    return request.save(
		{operation: "list_batch_sale"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_bsale_detail = function(mode, match, fields, currentPage, itemsPerpage){
	    return request.save(
		{operation: "list_batch_sale_new_detail"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.check_batch_sale = function(rsn){
	    return request.save({operation: "check_batch_sale"}, {rsn: rsn, mode:diablo_check}).$promise;
	};

	this.check_print_batch_sale = function(rsn){
	    return request.save({operation: "check_print_batch_sale"}, {rsn: rsn, mode:diablo_print}).$promise;
	};

	this.uncheck_batch_sale = function(rsn){
	    return request.save({operation: "check_batch_sale"}, {rsn: rsn, mode:diablo_uncheck}).$promise;
	};

	this.get_batch_sale = function(rsn, mode) {
	    return request.save({operation: "get_batch_sale"}, {rsn: rsn, mode:mode}).$promise;
	};

	this.update_batch_sale = function(stock) {
	    return request.save({operation: "update_batch_sale"}, stock).$promise;
	};

	this.delete_batch_sale = function(rsn) {
	    return request.save({operation: "delete_batch_sale"}, {rsn:rsn}).$promise;
	};

	this.csv_export = function(condition, type){
	    return request.save({operation: "export_batch_sale"}, {condition: condition, type:type}).$promise;
	}; 

	/*================================================================================
	 * batch saler
	 *================================================================================*/
	this.new_bsaler = function(s) {
	    return request.save(
		{operation: "new_batch_saler"},
		{shop:    s.shop,
		 region:  s.region,
		 name:    s.name,
		 py:      s.py,
		 type:    s.type,
		 balance: s.balance,
		 mobile:  s.mobile,
		 address: s.address,
		 remark:  s.remark}
	    ).$promise;
	};

	this.update_bsaler = function(bsalerId, payload) {
	    return request.save({operation: "update_batch_saler", id:bsalerId}, payload).$promise;
	};

	this.filter_bsaler = function(mode, match, fields, currentPage, itemsPerpage){
	    return request.save(
		{operation: "list_batch_saler"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	var match_phone = function(viewValue, mode) {
	    return request.post(
		{operation: "match_bsaler_phone"}, {prompt:viewValue, mode: mode}
	    ).$promise.then(function(phones) {
		return phones.map(function(s) {
		    return {id:   s.id,
			    name: s.name + "," + s.mobile,
			    mobile: s.mobile,
			    balance: s.balance,
			    region_id: s.region_id,
			    shop_id: s.shop_id};
		})
	    });
	};
	
	this.match_bsaler_phone = function(viewValue) {
	    if (diablo_is_digit_string(viewValue)){
		if (viewValue.length < 4) return; 
		else return match_phone(viewValue, 0)
	    } else if (diablo_is_letter_string(viewValue)){
		return match_phone(viewValue, 1);
	    } else if (diablo_is_chinese_string(viewValue)){
		return match_phone(viewValue, 2);
	    } else {
		return;
	    } 
	};

	this.match_bsale_rsn = function(mode, viewValue, conditions) {
	    return request.post(
		{operation: "match_bsale_rsn"}, {mode:mode, prompt: viewValue, condition:conditions}
	    ).$promise.then(function(rsns){
		return rsns.map(function(r){
		    return r.rsn;
		})
	    });
	};

	this.get_bsaler_batch = function(bsalers) {
	    return request.post({operation:'get_bsaler_batch'}, {bsaler:bsalers}).$promise;
	};
	
    });

    bsaleApp.controller("loginOutCtrl", function($scope, $resource, localStorageService){
    	$scope.home = function () {
    	    bsaleUtils.remove_cache_page(localStorageService); 
    	    diablo_login_out($resource);
    	};
    });

    // console.log(bsaleApp);
    bsaleApp.controller("bsalerNewCtrl", bsalerNewCtrlProvide);
    bsaleApp.controller("bsalerDetailCtrl", bsalerDetailCtrlProvide);

    bsaleApp.controller("bsaleNewCtrl", bsaleNewProvide);
    bsaleApp.controller("bsalePrintCtrl", bsalePrintCtrlProvide);
    bsaleApp.controller("bsaleNewDetailCtrl", bsaleNewDetailCtrlProvide);
    bsaleApp.controller("bsaleNewNoteCtrl", bsaleNewNoteCtrlProvide);
    
    return bsaleApp;
};

function bsaleNewProvide(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, bsaleService,
    filterEmployee, filterSizeGroup, filterType, filterColor, filterRegion,
    filterDepartment, filterSysBSaler, user, base){
    // console.log(filterRegion); 
    $scope.pattern    = {
	money:    diabloPattern.decimal_2,
	sell:     diabloPattern.integer_except_zero,
	discount: diabloPattern.discount,
	barcode:  diabloPattern.number,
	comment:  diabloPattern.comment};
    
    $scope.interval_per_5_minute = undefined;
    $scope.round  = diablo_round;
    
    $scope.today   = function(){return $.now();}; 
    $scope.back    = function(){diablo_goto_page("#/new_bsale_detail");};
    
    $scope.setting = {check_sale:true, negative_sale:true}; 
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenSaleRight(); 

    // console.log($scope.right);
    $scope.focus_attr = {style_number:false,
			 barcode:false,
			 sell:false,
			 cash:false,
			 card:false,
			 wxin:false};
    
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
    
    $scope.disable_refresh = true;
    
    $scope.select = {
	rsn:  undefined,
	cash: undefined,
	card: undefined,
	wxin: undefined,
	
	total:        0,
	abs_total:    0,
	should_pay:   0, 
	has_pay:      0, 
	surplus:      0,
	left_balance: 0,
	datetime:     $scope.today(),

	region: undefined,
	department: undefined
    };

    // init
    $scope.sale = {barcode:undefined, style_number:undefined};
    $scope.inventories = [];
    
    var dialog = diabloUtilsService; 
    var get_setting = function(shopId){
	angular.extend($scope.setting, bsaleUtils.sale_mode(shopId, base));
	angular.extend($scope.setting, bsaleUtils.batch_mode(shopId, base));
	
	$scope.setting.semployee     = bsaleUtils.select_employee(shopId, base);
	$scope.setting.check_sale    = bsaleUtils.check_sale(shopId, base);
	$scope.setting.negative_sale = bsaleUtils.negative_sale(shopId, base);
	$scope.setting.round         = bsaleUtils.round(shopId, base);
	$scope.setting.barcode_mode  = bsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = bsaleUtils.barcode_auto(shopId, base); 
	$scope.setting.scan_only     = bsaleUtils.to_integer(bsaleUtils.scan_only(shopId, base).charAt(0));
	$scope.setting.type_sale     = bsaleUtils.type_sale(shopId, base);
	$scope.setting.print_protocal = bsaleUtils.print_protocal(shopId, base);	
	console.log($scope.setting); 
    };
    
    // shops
    $scope.shops = user.sortShops;
    if ($scope.shops.length !== 0){
	$scope.select.shop = $scope.shops[0];
	get_setting($scope.select.shop.id); 
    }

    $scope.focus_good_or_barcode = function() {
	$scope.sale.style_number = undefined;
	$scope.sale.barcode = undefined;
	if ($scope.setting.barcode_mode) {
	    $scope.auto_focus('barcode'); 
	}
	else {
	    $scope.auto_focus('style_number'); 
	}
    };

    $scope.focus_by_element = function() {
	if ($scope.setting.barcode_mode) {
	    document.getElementById("barcode").focus();
	}
	else {
	    document.getElementById("snumber").focus();
	}
    };
    
    $scope.focus_good_or_barcode();
    // console.log($scope.focus_attr);

    $scope.get_valid_price = function(stock) {
	if (0 === $scope.setting.sale_price)
	    return stock.tag_price;
	else 
	    return stock.vir_price;
    };
    
    $scope.change_shop = function(){
	get_setting($scope.select.shop.id);	
	$scope.get_employee();
	$scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
	$scope.bsaleStorage.change_shop($scope.select.shop.id);
	
	$scope.refresh(); 
    };
    
    if (needCLodop()) {
	loadCLodop($scope.setting.print_protocal); 
	$scope.comments = bsaleUtils.comment($scope.select.shop.id, base);
    } 
    
    $scope.get_employee = function(){
	var select = bsaleUtils.get_login_employee($scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.employees = select.filter;
	$scope.select.employee = select.login;
	if ($scope.setting.semployee) $scope.select.employee = undefined;
    }; 
    $scope.get_employee();
    
    // batch saler;
    $scope.match_bsaler_phone = function(viewValue){
	return bsaleService.match_bsaler_phone(viewValue);
    };
    
    $scope.set_bsaler = function(){
    	if ($scope.select.bsaler.id !== diablo_invalid_index
	    && $scope.select.bsaler.type_id !== diablo_system_retailer){
    	    $scope.select.surplus = bsaleUtils.to_decimal($scope.select.bsaler.balance);
    	    $scope.select.left_balance = $scope.select.surplus;
    	} 
    };
    
    $scope.on_select_bsaler = function(item, model, label){
	// console.log(item);
	console.log($scope.select.bsaler);
	$scope.set_bsaler();

	$scope.select.region = diablo_get_object($scope.select.bsaler.region_id, filterRegion);
	// console.log($scope.select.region); 
	if (angular.isObject($scope.select.region))
	    $scope.select.department = diablo_get_object($scope.select.region.department_id, filterDepartment);

	console.log($scope.select.department);
	if (angular.isObject($scope.select.department)) {
	    $scope.select.department.master =
		diablo_get_object($scope.select.department.master_id, filterEmployee); 
	}
	
	$scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
	$scope.bsaleStorage.change_bsaler($scope.select.bsaler.id);
	// $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate(); 
    };

    $scope.reset_bsaler = function(){
	$scope.sysBSalers = filterSysBSaler.filter(function(s){
    	    return s.shop_id === $scope.select.shop.id;
    	});

	if ($scope.sysBSalers.length !== 0) {
	    $scope.select.bsaler = $scope.sysBSalers[0];
	} else {
	    $scope.select.bsaler = $scope.filterSysBSaler[0];
	}

	if ($scope.setting.hide_bsaler) {
	    $scope.select.bsaler.name = diablo_empty_string;
	} 
    };
    
    $scope.reset_bsaler();
    
    $scope.refresh = function(){
	$scope.inventories = [];
	
	$scope.select.form.cardForm.$invalid  = false;
	$scope.select.form.cashForm.$invalid  = false;
	$scope.select.form.wForm.$invalid  = false;
	$scope.select.form.vForm.$invalid  = false; 

	$scope.select.rsn          = undefined;
	$scope.select.cash         = undefined;
	$scope.select.card         = undefined;
	$scope.select.wxin         = undefined;
	$scope.select.verificate   = undefined; 

	$scope.select.should_pay   = 0; 
	$scope.select.has_pay      = 0;
	
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.comment      = undefined;
	
	$scope.select.datetime     = $scope.today();
	if ($scope.setting.semployee)
	    $scope.select.employee = undefined;
	
	$scope.disable_refresh     = true;
	$scope.has_saved           = false; 
	
	$scope.focus_good_or_barcode();
	$scope.bsaleStorage.reset();
	$scope.reset_bsaler();
    };

    
    $scope.refresh_datetime_per_5_minute = function(){
    	$scope.interval_per_5_minute = setInterval(function(){
    	    $scope.select.datetime  = $scope.today();
    	}, 300 * 1000);
    };

    var now = $scope.today(); 
    $scope.qtime_start = function(shopId){
	return bsaleUtils.start_time(shopId, base, now, dateFilter);
    };

    $scope.refresh_datetime_per_5_minute();

    /*
     * draft
     */
    $scope.bsaleStorage = new bsaleDraft(
	localStorageService,
	$scope.select.shop.id,
	$scope.select.bsaler.id,
	dateFilter);
    
    $scope.disable_draft = function(){
	return $scope.bsaleStorage.keys().length === 0 || $scope.inventories.length !== 0; 
    };

    $scope.hang_draft = function() {
	$scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.refresh();
	$scope.focus_by_element();
    };
    
    $scope.list_draft = function(){
	var keys = $scope.bsaleStorage.keys(); 
	var bsalerIds = keys.map(function(k){
	    var p = k.split("-");
	    return parseInt(p[1]);
	}); 
	
	bsaleService.get_bsaler_batch(bsalerIds).then(function(bsalers){
	    console.log(bsalers); 
	    var draft_filter = function(keys){
		return keys.map(function(k){
		    var p = k.split("-");
		    return {sn:k,
			    bsaler:diablo_get_object(parseInt(p[1]), bsalers),
			    shop:diablo_get_object(parseInt(p[2]), $scope.shops)}
		});
	    };

	    var select = function(draft, resource){
		if (draft.shop.id !== $scope.select.shop.id){
		    $scope.select.shop = diablo_get_object(draft.shop.id, $scope.shops); 
		    $scope.get_employee(); 
		};
		
		$scope.select_draft_key = draft.sn;
		$scope.bsaleStorage.set_key(draft.sn);
		// $scope.select.employee = diablo_get_object(draft.employee.id, $scope.employees);
		$scope.select.bsaler = diablo_get_object(draft.bsaler.id, bsalers);
		$scope.set_bsaler();
		$scope.get_employee(); 
		
		$scope.inventories = angular.copy(resource);
		// console.log($scope.inventoyies);
		// $scope.inventories.unshift({$edit:false, $new:true});
		$scope.disable_refresh = false; 
		$scope.re_calculate();
		$scope.focus_by_element();
	    };

	    $scope.bsaleStorage.select(dialog, "bsale-draft.html", draft_filter, select);  
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
	
	add.org_price    = src.org_price;
	add.ediscount    = src.ediscount;
	add.vir_price    = src.vir_price;
	add.tag_price    = src.tag_price; 
	add.discount     = src.discount;

	add.unit         = src.unit;
	add.path         = src.path; 
	add.s_group      = src.s_group;
	add.free         = src.free;
	add.entry        = src.entry_date;

	add.full_name    = add.style_number + "/" + add.brand + "/" + add.type;

	return add; 
    };

    var fail_response = function(code, callback){
	dialog.response_with_callback(
	    false,
	    "批发开单",
	    "开单失败：" + bsaleService.error[code],
	    undefined,
	    callback);
    };
    
    $scope.on_select_good = function(item, model, label){
	console.log(item); 
	if ($scope.get_valid_price(item) < 0){
	    fail_response(2193, function(){}); 
	    return;
	};
	
	// auto focus
	$scope.auto_focus("sell"); 
	var add  = {$new:true}; 
	$scope.copy_select(add, item);
	console.log(add);
	$scope.add_inventory(add); 
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
	    dialog.response(false, "销售开单", "开单失败：" + bsaleService.error[2196]);
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(barcode.cuted, $scope.select.shop.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.response(false, "销售开单", "开单失败：" + bsaleService.error[2195]);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.response(false, "销售开单", "开单失败：" + bsaleService.error[2195]);
	    }
	});
	
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	if ($scope.has_saved || $scope.draft || $scope.inventories.length === 0)
	    return true;
	    
	if (angular.isObject($scope.select.bsaler) &&
	    $scope.select.bsaler.type_id === 2
	    && $scope.select.should_pay > $scope.select.has_pay) {
	    return true;
	}
    };
    
    var get_sale_detail = function(amounts){
	var sale_amounts = [];
	for(var i=0, l=amounts.length; i<l; i++){
	    var a = amounts[i];
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		var new_a = {
		    cid:        a.cid,
		    size:       a.size, 
		    sell_count: bsaleUtils.to_integer(amounts[i].sell_count)}; 
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
    
    $scope.save_bsale = function(){
	$scope.has_saved = true; 
	console.log($scope.inventories); 
	// console.log($scope.select);
	if (!angular.isObject($scope.select.bsaler) || !angular.isObject($scope.select.employee)){
	    dialog.response(
		false,
		"批发开单",
		"开单失败：" + bsaleService.error[2192]);
	    $scope.has_saved = false; 
	    return;
	};

	if (!$scope.setting.hide_bsaler && $scope.select.bsaler.type_id === diablo_system_retailer) {
	    dialog.response(
		false,
		"批发开单",
		"开单失败：" + bsaleService.error[2192]);
	    $scope.has_saved = false; 
	    return;
	}
	
	var sets = diablo_set_string; 
	var added = [];
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var add = $scope.inventories[i];
	    var index = index_of_sale(add, added)
	    // console.log(index);
	    if (diablo_invalid_index !== index) {
		var existSale = added[index];
		existSale.sell_total += bsaleUtils.to_integer(add.sell)
		
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
		    sex         : add.sex,
		    season      : add.season,
		    year        : add.year,
		    entry       : add.entry,
		    sell_total  : bsaleUtils.to_integer(add.sell),
		    
		    org_price   : add.org_price,
		    ediscount   : add.ediscount,
		    tag_price   : add.tag_price,
		    fprice      : add.fprice,
		    fdiscount   : add.fdiscount,
		    rprice      : add.rprice,
		    rdiscount   : add.rdiscount,
		    stock       : add.total,
		    unit        : add.unit,
		    
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

	console.log(added); 
	var base = {
	    bsaler:         $scope.select.bsaler.id,
	    shop:           $scope.select.shop.id,
	    datetime:       dateFilter($scope.select.datetime, "yyyy-MM-dd HH:mm:ss"),
	    employee:       $scope.select.employee.id,
	    comment:        sets($scope.select.comment),
	    
	    // balance:        $scope.select.surplus, 
	    cash:           bsaleUtils.to_float($scope.select.cash),
	    card:           bsaleUtils.to_float($scope.select.card),
	    wxin:           bsaleUtils.to_float($scope.select.wxin), 
	    verificate:     bsaleUtils.to_float($scope.select.verificate), 
	    
	    should_pay:     bsaleUtils.to_float($scope.select.should_pay),
	    has_pay:        $scope.select.has_pay,
	    
	    total:          $scope.select.total, 
	    round:          $scope.setting.round
	};
	
	console.log(base);

	var payload = {inventory:added.length===0 ? undefined : added, base:base}; 
	bsaleService.new_batch_sale(payload).then(function(result){
	    console.log(result);
	    var success_callback = function(){
		// clear local storage
		if (angular.isDefined($scope.select_draft_key)){
		    $scope.bsaleStorage.remove($scope.select_draft_key);
		    $scope.select_draft_key = undefined;
		};
		
		$scope.bsaleStorage.remove($scope.bsaleStorage.get_key()); 
		$scope.refresh();

		$scope.focus_by_element();
	    }
	    
	    if (result.ecode === 0){
		$scope.select.rsn = result.rsn; 
		// print
		if ($scope.setting.print_with_check) {
		    dialog.response_with_callback(
			true,
			"销售开单", "开单成功，单号：" + result.rsn + ", 请等待审核...",
			undefined,
			function() {$scope.refresh()});
		} else {
		    dialog.response_with_callback(
			true,
			"销售开单", "开单成功，单号：" + result.rsn + ", 是否打印单据?",
			undefined,
			function() {
			    bsaleService.check_print_batch_sale(result.rsn).then(function(state){
				console.log(state);
				if (state.ecode == 0){
				    diablo_goto_page("#/print_bsale/" + result.rsn); 
				} else{
				    dialog.set_batch_error("销售单打印", state.ecode); 
				}
			    })
			});
		}
		
	    } else {
		dialog.response_with_callback(
	    	    false,
		    "销售开单",
		    "开单失败：" + bsaleService.error[result.ecode],
		    undefined,
		    function(){$scope.has_saved = false}); 
	    } 
	})
    };
    
    $scope.reset_payment = function(newValue){
	$scope.select.has_pay = 0;
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.cash); 
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.card);
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.wxin);
	$scope.select.has_pay += bsaleUtils.to_float($scope.select.verificate);
	$scope.select.has_pay = bsaleUtils.to_decimal($scope.select.has_pay);
    };
    
    $scope.$watch("select.cash", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	$scope.reset_payment(newValue);
    });

    $scope.$watch("select.card", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	$scope.reset_payment(newValue);
    });

    $scope.$watch("select.wxin", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	$scope.reset_payment(newValue);
    });

    $scope.$watch("select.verificate", function(newValue, oldValue){
	if (newValue === oldValue || angular.isUndefined(newValue)) return;
	$scope.reset_payment(newValue);
	$scope.re_calculate();
    }); 

    var get_amount = function(cid, sname, amounts){
	for (var i=0, l=amounts.length; i<l; i++){
	    if (amounts[i].cid === cid && amounts[i].size === sname){
		return amounts[i];
	    }
	}
	return undefined;
    };

    $scope.cut_bsale = function() {
	var callback = function(params) {
	    console.log(params);
	    for (var i=0, l=$scope.inventories.length; i<l; i++) {
		$scope.inventories[i].fdiscount = bsaleUtils.to_float(params.discount);
		$scope.inventories[i].$update = true;
	    }

	    $scope.re_calculate();
	};
	
	dialog.edit_with_modal(
	    "cut-bsale.html",
	    'small',
	    callback,
	    undefined,
	    {pattern: {discount:$scope.pattern.discount},
	     discount:undefined}
	)
    };
    
    $scope.re_calculate = function(){
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0;

	var calc = bsaleCalc.calculate(
	    $scope.inventories,
	    diablo_sale,
	    $scope.select.verificate,
	    $scope.setting.round,
	    $scope.get_valid_price);
	console.log(calc);
	$scope.select.total      = calc.total;
	$scope.select.abs_total  = calc.abs_total;
	$scope.select.should_pay = calc.should_pay;
    };

    var valid_sell = function(amount){
	var sell = diablo_set_integer(amount.sell_count);
	if (0 === bsaleUtils.to_integer(sell)) return true;

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
	    if (0 === bsaleUtils.to_integer(sell)){
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
	var sell_total = 0, note = "";
	angular.forEach(params.amounts, function(a){
	    if (angular.isDefined(a.sell_count) && a.sell_count){
		sell_total += bsaleUtils.to_integer(a.sell_count);
		note += diablo_find_color(a.cid, filterColor).cname + a.size + ";"
	    }
	}); 

	return {amounts:     params.amounts,
		sell:        sell_total,
		fdiscount:   params.fdiscount,
		fprice:      params.fprice,
		note:        note};
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
	for(var i=0, l=$scope.inventories.length; i<l; i++){
	    var s = $scope.inventories[i];
	    if (stock.style_number === s.style_number && stock.brand_id === s.brand_id){
		angular.forEach(stock.amounts, function(a) {
		    var sellCount = bsaleUtils.to_integer(a.sell_count);
		    if (sellCount !== 0) {
			for (var j=0,k=s.amounts.length; j<k; j++) {
			    if (a.cid === s.amounts[j].cid && a.size === s.amounts[j].size) {
				if (sellCount + bsaleUtils.to_integer(s.amounts[j].sell_count) > a.count) {
				    not_enought = true;
				    break;
				}
			    }
			}
		    } 
		})
	    }
	}

	console.log(not_enought);
	return not_enought;
    };
    
    $scope.add_free_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.bsaler) || diablo_is_empty($scope.select.bsaler)){
	    diabloUtilsService.response(false, "批发开单", "开单失败：" + bsaleService.error[2192]);
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
	    // $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
	    $scope.re_calculate();	    
	    $scope.focus_good_or_barcode(); 
	};
	
	// check stock total 
	if ($scope.setting.check_sale && free_stock_not_enought(inv)) {
	    diabloUtilsService.response(false, "销售开单", "开单失败：" + bsaleService.error[2180]);
	} else {
	    callback(false);
	} 
    };
    
    $scope.add_inventory = function(inv){
	// console.log(inv); 
	if (angular.isUndefined($scope.select.bsaler) || diablo_is_empty($scope.select.bsaler)){
	    diabloUtilsService.response(false, "批发开单", "开单失败：" + bsaleService.error[2192]);
	    return;
	};
	
	inv.fdiscount = inv.discount;
	// inv.fprice    = diablo_price(inv.tag_price, inv.discount);
	inv.fprice    = diablo_price($scope.get_valid_price(inv), inv.discount); 
	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.amounts         = [{cid:0, size:0}];
	    inv.sell = 1; 
	    $scope.auto_save_free(inv);
	    $scope.update_inventory(inv);
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
		    dialog.response(
			false, "批发开单", "开单失败：" + bsaleService.error[2194]);
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
		    inv.amounts = [{cid:0, size:0}];
		    inv.sell = 1; 
		    $scope.auto_save_free(inv);
		    $scope.update_inventory(inv);
		} else{
		    inv.free_color_size = false; 
		    if ($scope.setting.barcode_mode && angular.isDefined(inv.full_bcode)) {
			// get color, size from barcode
			// console.log(inv.bcode);
			// console.log(inv.full_bcode);
			// console.log(inv.full_bcode.length - inv.bcode.length);
			var color_size = inv.full_bcode.substr(inv.bcode.length, inv.full_bcode.length);
			console.log(color_size);

			var bcode_color = bsaleUtils.to_integer(color_size.substr(0, 3));
			var bcode_size_index = bsaleUtils.to_integer(color_size.substr(3, color_size.length));
			
			var bcode_size = bcode_size_index === 0 ? diablo_free_size:size_to_barcode[bcode_size_index];
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
				a.sell_count = 1; 
				a.focus = true;
			    }
			});
		    } else {
			// inv.amounts[0].focus = true;
			for (var i=0, l=inv.amounts.length; i<l; i++) {
			    var a = inv.amounts[i];
			    a.focus = false;
			    if (a.cid === inv.colors[0].cid && a.size === inv.sizes[0]) {
				a.focus = true;
			    }
			}
		    }
		    
		    var after_add = function(){
			if ($scope.setting.check_sale && cs_stock_not_enought(inv)) {
			    // diabloUtilsService.set_error("批发开单", 2180);
			    diabloUtilsService.response(false, "销售开单", "开单失败：" + bsaleService.error[2180]);
			} else {
			    inv.$edit = true;
			    inv.$new = false;
			    $scope.disable_refresh = false;
			    $scope.inventories.unshift(inv);
			    
			    inv.order_id = $scope.inventories.length; 
			    // $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
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
			after_add();
		    }; 
		    
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
			"bsale-new.html",
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
	//     $scope.bsaleStorage.save(
	// 	$scope.inventories.filter(function(r){return !r.$new})); 
	// } else {
	//     $scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
	// }

	if ($scope.inventories.length === 0)
	    $scope.bsaleStorage.remove($scope.bsaleStorage.get_key());

	$scope.re_calculate();
	$scope.focus_by_element();
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
	    "bsale-detail.html", undefined, undefined, $scope, payload)
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
	    	if (bsaleUtils.to_integer(inv.sell) === 0)
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

	    var bcode_color = bsaleUtils.to_integer(color_size.substr(0, 3));
	    var bcode_size_index = bsaleUtils.to_integer(color_size.substr(3, color_size.length));
	    
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
		    if (bsaleUtils.to_integer(a.sell_count) === 0)
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
	    if (inv.fprice !== result.fprice || inv.fdiscount !== result.fdiscount) {
		inv.$update = true;
	    }
	    
	    inv.amounts    = result.amounts;
	    inv.sell       = result.sell;
	    inv.fdiscount  = result.fdiscount;
	    inv.fprice     = result.fprice;
	    inv.note       = result.note; 

	    // inv.note 
	    // save
	    // $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	    $scope.re_calculate();

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
		       right:        $scope.right}; 
	diabloUtilsService.edit_with_modal("bsale-new.html", modal_size, callback, $scope, payload)
    };

    $scope.save_free_update = function(inv){
	// $timeout.cancel($scope.timeout_auto_save);
	inv.free_update = false;

	// if (inv.amounts[0].sell_count !== inv.sell)
	//     inv.$update_count = true; 
	inv.amounts[0].sell_count = inv.sell;
	if (inv.fprice !== inv.o_fprice || inv.fdiscount !== inv.o_fdiscount)
	    inv.$update = true;
	
	// save
	// $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
	$scope.re_calculate();

	// reset
	// $scope.inventories[0] = {$edit:false, $new:true};
	
	$scope.focus_good_or_barcode();
	inv.invalid_sell = false;
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

    $scope.check_free_stock = function(inv) {
	var sell = bsaleUtils.to_integer(inv.sell);
	inv.invalid_sell = false;
	
	if (!inv.$new && inv.free_update){
	    if ($scope.setting.check_sale && sell > inv.total){
		if (angular.isDefined(inv.form.sell)) {
		    inv.form.sell.$invalid = true;
		    inv.form.sell.$pristine = false; 
		}
		inv.invalid_sell = true; 
	    }
	    
	    if (!$scope.setting.negative_sale && sell < 0) {
		if (angular.isDefined(inv.form.sell)) {
		    inv.form.sell.$invalid = true;
		    inv.form.sell.$pristine = false;
		}
		inv.invalid_sell = true;
	    };
	    // $scope.save_free_update(inv); 
	} 
    };
    
    $scope.auto_save_free = function(inv){
	// $timeout.cancel($scope.timeout_auto_save); 
	var sell = bsaleUtils.to_integer(inv.sell);
	if (sell === 0) return
	if (angular.isUndefined(inv.style_number)) return;
	

	if (inv.$new && inv.free_color_size){
	    $scope.add_free_inventory(inv);
	};

	if (!$scope.check_free_stock(inv)) {
	    $scope.save_free_update(inv);
	} 
    }; 
};


function bsaleNewDetailCtrlProvide(
    $scope, $q, $timeout, $routeParams, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, bsaleService, filterEmployee, filterRegion, filterDepartment, user, base){
    $scope.shops     = user.sortShops;
    $scope.shopIds   = user.shopIds;

    $scope.bsaleDetails   = [];
    $scope.goto_page = diablo_goto_page;

    $scope.round     = diablo_round;
    $scope.css       = diablo_stock_css;
    
    $scope.total_items   = 0;
    $scope.default_page = 1; 
    $scope.disable_print = false;
    $scope.current_page = $scope.default_page;

    $scope.setting = bsaleUtils.batch_mode(user.loginShop, base);

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenBatchSaleRight();
    console.log($scope.right);

    var now = $.now();

    var show_sale_days = user.sdays;
    var storage = localStorageService.get(bsaleService.diablo_key_bsale_detail);

    if (null !== storage && angular.isDefined(storage) && angular.isObject(storage)){
	// console.log(storage);
    	$scope.filters      = storage.filter; 
    	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.current_page = storage.page;
    } else{
	$scope.filters = [];
	$scope.qtime_start = now;
	$scope.qtime_end = now;
    };

    $scope.time = bsaleUtils.correct_query_time(
	$scope.right.master,
	show_sale_days,
	$scope.qtime_start,
	$scope.qtime_end,
	diabloFilter);

    $scope.match_rsn = function(viewValue) {
	return bsaleService.match_bsale_rsn(
	    diablo_rsn_all,
	    viewValue,
	    bsaleUtils.format_time_from_second($scope.time, dateFilter));
    };

    $scope.match_bsaler_phone = bsaleService.match_bsaler_phone; 

    diabloFilter.reset_field();
    diabloFilter.add_field("shop",        $scope.shops);
    diabloFilter.add_field("account",     []); 
    diabloFilter.add_field("employee",    filterEmployee); 
    diabloFilter.add_field("bsaler",      bsaleService.match_bsaler_phone); 
    diabloFilter.add_field("rsn",         $scope.match_rsn);
    diabloFilter.add_field("check_state", bsaleService.check_state);
    diabloFilter.add_field("comment",     bsaleService.check_comment);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    // console.log($scope.filter);
    // console.log($scope.prompt);

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();

    $scope.do_search = function(page){
	// console.log(page); 
	$scope.current_page = page; 
	// console.log($scope.time); 
	if (!$scope.right.master && show_sale_days !== diablo_nolimit_day){
	    var diff = now - diablo_get_time($scope.time.start_time); 
	    if (diff - diablo_day_millisecond * show_sale_days > diablo_day_millisecond)
	    	$scope.time.start_time = now - show_sale_days * diablo_day_millisecond;
	    
	    if ($scope.time.end_time < $scope.time.start_time)
		$scope.time.end_time = now;
	}
	
	// save condition of query
	bsaleUtils.cache_page_condition(
	    localStorageService,
	    bsaleService.diablo_key_bsale_detail,
	    $scope.filters,
	    $scope.time.start_time,
	    $scope.time.end_time, page, now); 

	if (page !== $scope.default_page) {
	    var stastic = localStorageService.get("bsale-trans-stastic");
	    if (angular.isDefined(stastic) && angular.isObject(stastic)) {
		// console.log(stastic);
		$scope.total_items       = stastic.total_items;
		$scope.total_amounts     = stastic.total_amounts;
		$scope.total_spay        = stastic.total_spay;
		$scope.total_hpay        = stastic.total_hpay;
		$scope.total_cash        = stastic.total_cash;
		$scope.total_card        = stastic.total_card;
		$scope.total_wxin        = stastic.total_wxin; 
	    } 
	};
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    
	    bsaleService.filter_bsale_new($scope.match, search, page, $scope.items_perpage).then(function(result){
		console.log(result);
		if (page === 1) {
		    $scope.total_items       = result.total;
		    $scope.total_amounts     = result.t_amount;
		    $scope.total_spay        = result.t_spay;
		    $scope.total_hpay        = result.t_hpay;
		    $scope.total_cash        = result.t_cash;
		    $scope.total_card        = result.t_card;
		    $scope.total_wxin        = result.t_wxin; 
		    $scope.records = [];
		    $scope.save_stastic();
		} 
		
		// console.log($scope); 
		angular.forEach(result.data, function(d){
		    d.crsn       = diablo_array_last(d.rsn.split(diablo_date_seprator));
		    d.shop       = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee   = diablo_get_object(d.employee_id, filterEmployee);
		    d.has_pay    = d.has_pay;
		    d.should_pay = d.should_pay;
		    d.acc_balance = bsaleUtils.to_decimal(d.balance + d.should_pay - d.has_pay); 
		});

		
		diablo_order(result.data, (page - 1) * $scope.items_perpage + 1);
		$scope.records = $scope.records.concat(result.data); 
	    })
	})
    };

    $scope.page_changed = function(){
    	$scope.do_search($scope.current_page);
    };

    if ($scope.current_page !== $scope.default_page){
	$scope.do_search($scope.current_page); 
    } 
    
    $scope.save_stastic = function(){
	localStorageService.remove("bsale-detail-stastic");
	localStorageService.set(
	    "bsale-detail-stastic",
	    {total_items:       $scope.total_items,
	     total_amounts:     $scope.total_amounts,
	     total_spay:        $scope.total_spay,
	     total_hpay:        $scope.total_hpay,
	     total_cash:        $scope.total_cash,
	     total_card:        $scope.total_card,
	     total_wxin:        $scope.total_wxin, 
	     t:                 now});
    };

    $scope.goto_sale_note = function(r) {
	diablo_goto_page("#/list_bsale_new_detail/" + r.rsn);
    };

    var dialog = diabloUtilsService;
    $scope.check_sale = function(r){
	// console.log(r);
	bsaleService.check_batch_sale(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true,
		    "销售单审核",
		    "销售单审核成功！！单号：" + state.rsn,
		    undefined, function(){r.state = diablo_check})
	    	return;
	    } else{
		dialog.set_batch_error("销售单审核", state.ecode); 
	    }
	})
    };

    $scope.uncheck_sale = function(r){
	// console.log(r);
	bsaleService.uncheck_batch_sale(r.rsn, diablo_uncheck).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "销售单反审", "销售单反审成功！！单号：" + state.rsn,
		    undefined, function(){r.state = diablo_uncheck})
	    	return;
	    } else{
		dialog.set_batch_error("销售单反审", state.ecode); 
	    }
	})
    };

    $scope.delete_sale = function(r){
	bsaleService.delete_batch_sale(r.rsn).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true,
		    "销售单删除", "销售单删除成功！！单号：" + state.rsn,
		    undefined,
		    function(){$scope.do_search($scope.current_page)});
	    	return;
	    } else{
		dialog.set_batch_error("销售单删除", state.ecode); 
	    }
	});
    };

    $scope.update_sale = function(r) {
	if (r.type === 0){
	    diablo_goto_page('#/update_bsale_detail/' + r.rsn);
	} else {
	    diablo_goto_page('#/update_bsale_reject/' + r.rsn); 
	}
    };

    $scope.print_sale = function(r) {
	var callback = function() {
	    bsaleService.check_print_batch_sale(r.rsn).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    r.state = diablo_print;
		    diablo_goto_page("#/print_bsale/" + r.rsn); 
		} else{
		    dialog.set_batch_error("销售单打印", state.ecode); 
		}
	    })
	}
	
	dialog.request(
	    "销售单打印", "请确认打印机已连接好，确认要打印吗？", callback, undefined, undefined);
    };

    $scope.export_to = function(){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search); 
	    bsaleService.csv_export(bsaleService.export_type.sale_new, search)
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
			dialog.set_batch_error("文件导出", state.ecode); 
		    } 
		}); 
	}) 
    };
};

function bsaleNewNoteCtrlProvide(
    $scope, $q, $timeout, $routeParams, dateFilter, localStorageService, bsaleService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter, diabloPattern, 
    filterEmployee, filterSizeGroup, filterFirm, filterBrand, filterCType, filterType, filterColor,
    filterRegion, filterDepartment, user, base){
    $scope.shops    = user.sortShops;
    $scope.shopIds  = user.shopIds;
    
    $scope.setting     = {round:diablo_round_record};
    $scope.total_items = 0;
    $scope.goto_page = diablo_goto_page;
    $scope.sexs        = diablo_sex;

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page  = 1;
    
    $scope.tab  = {normal:true, additional:false};
    $scope.tab_normal = {current_page:$scope.default_page};

    $scope.hidden         = {base:true};
    $scope.is_linked      = $routeParams.rsn ? true : false;
    
    var LODOP       = undefined;
    var dialog      = diabloUtilsService;
    
    /*
     * right
     */
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenBatchSaleRight();
    
    /* hidden */
    $scope.toggle_base = function(){
	$scope.hidden.base = !$scope.hidden.base;
    };
    
    $scope.calc_colspan = function(){
	var column = 14;
	if ($scope.setting.show_note)
	    column += 1;
	if ($scope.hidden.base)
	    column -= 4;
	
	return column;
    };

    $scope.order_fields = bsaleUtils.order_fields();
    $scope.mode = $scope.order_fields.id;
    $scope.sort = 0;

    $scope.use_order = function(mode){
	$scope.mode = mode;
	$scope.sort = $scope.sort === 0 ? 1 : 0; 
	$scope.do_search($scope.tab_normal.current_page);
    }

    // prepare of print
    if ($scope.is_linked){
	var shop = diablo_get_object(parseInt($routeParams.rsn.split("-")[3]),$scope.shops);
	var print_protocal = bsaleUtils.print_protocal(shop.id, base);
	if (diablo_frontend === bsaleUtils.print_mode(shop.id, base))
	    if (needCLodop()) loadCLodop(print_protocal);
    };

    // style_number
    $scope.match_style_number = function(viewValue){
	if (angular.isUndefined(diablo_set_string(viewValue)) || viewValue.length < diablo_filter_length) return;
	return diabloFilter.match_w_inventory(viewValue, $scope.shopIds);
    };
    
    var now = $.now(); 
    
    // base setting 
    $scope.setting.show_sale_day = user.sdays; 
    angular.extend($scope.setting, bsaleUtils.sale_mode(diablo_default_shop, base));
    console.log($scope.setting);
    
    var storage = localStorageService.get(bsaleService.diablo_key_bsale_note);
    // console.log(storage);
    if (!$scope.is_linked && null !== storage && angular.isDefined(storage) && angular.isObject(storage)){
    	$scope.filters      = storage.filter;
	$scope.qtime_start  = storage.start_time;
	$scope.qtime_end    = storage.end_time;
	$scope.tab_normal.current_page = storage.page;
    } else{
	$scope.filters = [];
	if (angular.isDefined($routeParams.rsn)){
	    $scope.qtime_start = diablo_set_date(
		bsaleUtils.start_time(diablo_default_shop, base, now, dateFilter));
	} else {
	    $scope.qtime_start = now;
	} 
	$scope.qtime_end = now; 
    };
    // console.log($scope.qtime_start, $scope.qtime_end, now); 

    $scope.time = bsaleUtils.correct_query_time(
	$scope.right.master,
	$scope.setting.show_sale_day,
	$scope.qtime_start,
	$scope.qtime_end,
	diabloFilter);
    console.log($scope.time);

    $scope.match_rsn = function(viewValue) {
	return diabloFilter.match_bsale_rsn(
	    diablo_rsn_all,
	    viewValue,
	    bsaleUtils.format_time_from_second($scope.time, dateFilter));
    };
    
    // console.log($scope.setting);
    // filter
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", $scope.match_style_number); 
    diabloFilter.add_field("brand",        filterBrand);
    diabloFilter.add_field("type",         filterType); 
    diabloFilter.add_field("ctype",        filterCType);
    diabloFilter.add_field("sex",          diablo_sex2object);
    diabloFilter.add_field("season",       diablo_season2objects);
    diabloFilter.add_field("year",         diablo_full_year); 
    diabloFilter.add_field("firm",         filterFirm);
    diabloFilter.add_field("shop",         $scope.shops); 
    diabloFilter.add_field("bsaler",       bsaleService.match_bsaler_phone); 
    diabloFilter.add_field("employee",     filterEmployee); 
    diabloFilter.add_field("sell_type",    bsaleService.bsale_types);
    diabloFilter.add_field("rsn",          $scope.match_rsn);
    diabloFilter.add_field("org_price",    []);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.cache_stastic = function(){
	localStorageService.set(bsaleService.diablo_key_bsale_note_stastic,
				{total_items:       $scope.total_items,
				 total_tblance:     $scope.total_tblance,
				 total_amounts:     $scope.total_amounts, 
				 total_balance:     $scope.total_balance,
				 total_obalance:    $scope.total_obalance, t:now})};
    
    /*
     * pagination 
     */
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
	    bsaleUtils.cache_page_condition(
		localStorageService,
		bsaleService.diablo_key_bsale_note,
		$scope.filters,
		$scope.time.start_time,
		$scope.time.end_time, page, now);

	if (!$scope.is_linked && page !== $scope.default_page) {
	    var stastic = localStorageService.get(bsaleService.diablo_key_bsale_note_stastic);
	    console.log(stastic);
	    $scope.total_items       = stastic.total_items;
	    $scope.total_amounts     = stastic.total_amounts;
	    $scope.total_tblance     = stastic.total_tblance;
	    $scope.total_balance     = stastic.total_balance;
	    $scope.total_obalance    = stastic.total_obalance;
	}
	
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined;
	    }; 
	    
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
	    	search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    };
	    
	    console.log(search); 
	    // console.log($scope.setting);
	    bsaleService.filter_bsale_detail(
		{mode:$scope.mode, sort:$scope.sort, note:$scope.setting.show_note},
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
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
		    d.crsn      = diablo_array_last(d.rsn.split(diablo_date_seprator));
		    // d.brand     = diablo_get_object(d.brand_id, filterBrand);
		    d.firm      = diablo_get_object(d.firm_id, filterFirm);
		    d.shop      = diablo_get_object(d.shop_id, $scope.shops);
		    d.employee  = diablo_get_object(d.employee_id, filterEmployee);
		    // d.type      = diablo_get_object(d.type_id, filterType);
		    d.oseason   = diablo_get_object(d.season, diablo_season2objects); 
		    d.drate     = diablo_discount(d.rprice, d.tag_price);
		    d.gprofit   = d.rprice <= diablo_pfree ? 0 : diablo_discount(
			bsaleUtils.to_decimal(d.rprice - d.org_price), d.rprice);
		    d.calc      = bsaleUtils.to_decimal(d.rprice * d.total);
		    d.imbalance = bsaleUtils.to_decimal(d.tag_price - d.rprice);
		});

		$scope.inventories = result.data;
		diablo_order_page(page, $scope.items_perpage, $scope.inventories); 
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
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    };
	    
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    bsaleService.list_bsale_stastic_note(search).then(function(result){
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
	
	bsaleService.get_bsale_note({
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
	    if (angular.isUndefined(search.rsn)){
		search.rsn  =  $routeParams.rsn ? $routeParams.rsn : undefined; 
	    };
	    
	    if (angular.isUndefined(search.shop) || !search.shop || search.shop.length === 0){
		search.shop = $scope.shopIds.length === 0 ? undefined : $scope.shopIds; 
	    }
	    console.log(search);
	    
	    bsaleService.csv_export(search, bsaleService.export_type.sale_new_detail).then(function(result){
	    	console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "文件导出成功", "创建文件成功，请点击确认下载！！", undefined,
			function(){window.location.href = result.url;}) 
		} else {
		    dialog.set_batch_error("文件导出", result.ecode); 
		}
	    });
	}) 
    };

    $scope.back = function(){
	$scope.goto_page("#/detail_bsale") 
    };
    
    $scope.update_orgprice = function(inv) {
	var callback = function(params){
	    console.log(params); 
	    bsaleService.update_bsale_price(
		inv.rsn, {style_number:inv.style_number,
			  brand:inv.brand_id,
			  org_price:params.org_price,
			  tag_price:inv.tag_price}
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    inv.org_price = params.org_price; 
		    inv.gprofit   = inv.rprice <= diablo_pfree ? 0
			: diablo_discount(diablo_float_sub(inv.rprice, inv.org_price), inv.rprice);
		} else {
		    dialog.set_batch_error("交易单进货价编辑", result.ecode); 
		}
	    });
	};

	dialog.edit_with_modal(
	    "update-orgprice.html",
	    undefined,
	    callback,
	    undefined,
	    {style_number :inv.style_number,
	     brand        :inv.brand.name,
	     org_price    :inv.org_price}
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

function bsalePrintCtrlProvide(
    $scope, $routeParams, bsaleService, diabloFilter, diabloPattern, diabloUtilsService,
    filterEmployee, filterRegion, filterDepartment, filterCard, user, base){
    $scope.shops       = user.sortShops;
    $scope.employees   = filterEmployee;
    $scope.regions     = filterRegion;
    $scope.departments = filterDepartment;
    $scope.std_units   = diablo_std_units;
    // console.log(filterCard);
    $scope.bank_card   = filterCard.filter(function(c) {return c.type===1});
    
    var dialog = diabloUtilsService;

    var LODOP;
    var print_protocal = bsaleUtils.print_protocal(user.loginShop, base);
    if (needCLodop()) loadCLodop(print_protocal);

    var pageHeight = diablo_base_setting("prn_h_page", user.loginShop, base, parseFloat, 14);
    var pageWidth  = diablo_base_setting("prn_w_page", user.loginShop, base, parseFloat, 21.3);
    var batch_mode = bsaleUtils.batch_mode(user.loginShop, base);
    
    var contacts = diablo_base_setting("contact", user.loginShop, base, function(s) {return s}, "").split(diablo_semi_seperator);

    $scope.contacts = [];
    for (var i=0, l=contacts.length; i<l; i+=3) {
	var c = contacts[i];
	if ( i + 1 < l) 
	    c += '\xa0\xa0\xa0\xa0\xa0\xa0' + contacts[i+1];
	if ( i + 2 < l)
	    c += '\xa0\xa0\xa0\xa0\xa0\xa0' + contacts[i+2] ;
	$scope.contacts.push(c);
    }
    
    $scope.print_mode = bsaleUtils.print_cs_mode(user.loginShop, base);
	
    bsaleService.get_batch_sale($routeParams.rsn, diablo_batch_sale_print_mode).then(function(result) {
    	console.log(result);
	if (result.ecode === 0) {
	    $scope.detail = result.detail;
	    $scope.detail.shop = diablo_get_object($scope.detail.shop_id, $scope.shops);
	    $scope.detail.employee = diablo_get_object($scope.detail.employee_id, filterEmployee);
	    $scope.detail.acc_balance =
		bsaleUtils.to_decimal($scope.detail.balance + $scope.detail.should_pay - $scope.detail.has_pay);

	    $scope.detail.region = diablo_get_object($scope.detail.region_id, filterRegion);
	    if (angular.isObject($scope.detail.region))
		$scope.detail.department = diablo_get_object($scope.detail.region.department_id, filterDepartment);
	    
	    if (angular.isObject($scope.detail.department)) {
		$scope.detail.department.master =
		    diablo_get_object($scope.detail.department.master_id, filterEmployee); 
	    }
	    
	    $scope.notes = [];
	    $scope.total  = 0;
	    $scope.total_rprice = 0;
	    $scope.amount = 0;

	    var order_id = 1;
	    angular.forEach(result.note, function(n) {
		n.order_id = order_id;
		n.calc = bsaleUtils.to_decimal(n.rprice * n.total);
		$scope.notes.push(n);
		$scope.total += n.total;
		$scope.total_rprice = bsaleUtils.to_decimal($scope.total_rprice + n.calc);
		
		if ($scope.print_mode.both) {
		    for (var i=0, l=n.note.length; i<l; i++) {
			var s = n.note[i];
			$scope.amount += s.total;
			$scope.notes.push({
			    amount: s.total,
			    color:  diablo_find_color(s.color_id, filterColor),
			    size:   s.size
			});
		    }
		} 
		order_id++; 
	    });
	    
	} else {
	    dialog.response(
		false,
		"销售单打印",
		"销售单打印失败：获取采购单失败，请核对后再打印！！")
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
	    LODOP.PRINT_INIT("task_print_bsale_new");
	    LODOP.SET_PRINTER_INDEX(bsaleUtils.printer_bill(user.loginShop, base));
	    LODOP.SET_PRINT_PAGESIZE(0, pageWidth * 100, pageHeight * 100, "");
	    LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	    
	    LODOP.ADD_PRINT_HTM(
	    	"5%", "5%",  "90%", "BottomMargin:15mm",
	    	strBodyStyle + "<body>" + document.getElementById("bsale_new").innerHTML + "</body>");

	    LODOP.ADD_PRINT_IMAGE(
		"5%", "2%", 120, 120,
		"<img src='https://qzgui.com/" + $scope.detail.shop.bcode_pay + "?" + Math.random() + "'/>");
	    
	    LODOP.ADD_PRINT_IMAGE(
		"5%", "83%", 120, 120,
		"<img src='https://qzgui.com/" + $scope.detail.shop.bcode_friend + "?" + Math.random() + "'/>");
	    
	    LODOP.PREVIEW(); 
	}
    };

    $scope.go_back = function() {
	if (batch_mode.print_with_check)
	    diablo_goto_page("#/list_bsale_new");
	else {
	    diablo_goto_page("#/new_bsale");
	}
    };
};

/*================================================================================
 * batch saler
 *================================================================================*/
function bsalerNewCtrlProvide(
    $scope, bsaleService, diabloPattern, diabloUtilsService, filterRegion, user){
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      name:         diabloPattern.chinese_lname,
		      comment:      diabloPattern.comment};
    
    $scope.shops        = user.sortShops;
    $scope.regions      = [{id:-1, name:"无"}].concat(filterRegion);
    $scope.bsaler_types = bsaleService.bsaler_types;
    
    $scope.bsaler = {
	type :$scope.bsaler_types[0],
	shop :$scope.shops[0],
	region: $scope.regions[0]
    };

    var dialog = diabloUtilsService;
    $scope.new_bsaler = function(bsaler) {
	console.log(bsaler);
	var saler = {shop:    bsaler.shop.id,
		     region:  bsaler.region.id,
		     name:    diablo_trim(bsaler.name),
		     py:      diablo_pinyin(diablo_trim(bsaler.name)),
		     type:    bsaler.type.id,
		     balance: bsaleUtils.to_float(bsaler.balance),
		     mobile:  diablo_trim(bsaler.mobile),
		     address: bsaler.address ? diablo_trim(bsaler.address) : undefined,
		     remark:  bsaler.remark ? diablo_trim(bsaler.remark) : undefined};
	bsaleService.new_bsaler(saler).then(function(result) {
	    console.log(result);
	    if (result.ecode == 0) {
		diablo_goto_page("#/bsaler_detail");
	    } else {
		dialog.set_batch_error("新增客户", result.ecode);
	    }
	});
    };
};

function bsalerDetailCtrlProvide(
    $scope, bsaleService, diabloFilter, diabloPattern, diabloUtilsService, localStorageService,
    filterRegion, user){
    $scope.shops        = user.sortShops;
    $scope.regions      = [{id:-1, name:"无"}].concat(filterRegion);
    $scope.bsaler_types = bsaleService.bsaler_types;
    $scope.goto_page    = diablo_goto_page;
    
    $scope.pattern = {address: diabloPattern.ch_name_address,
		      phone:   diabloPattern.tel_mobile,
		      name:    diabloPattern.chinese_lname,
		      comment: diabloPattern.comment}; 
    
    $scope.filters = [];
    diabloFilter.reset_field(); 
    diabloFilter.add_field("region", $scope.regions);
    diabloFilter.add_field("shop", user.sortShops);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();
    
    var order_fields = {id:0, balance:1, consume:2};
    $scope.sort = {mode: order_fields.id, sort:diablo_desc}; 
    $scope.select         = {phone:undefined};

    $scope.match_bsaler_phone = function(viewValue){
	return bsaleService.match_bsaler_phone(viewValue);
    };

    var dialog = diabloUtilsService;
    
    /*
     * pagination
     */
    $scope.max_page_size = diablo_max_page_size();
    $scope.items_perpage = diablo_items_per_page();
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.total_items   = undefined;

    var storage = localStorageService.get(bsaleService.diablo_key_bsaler);
    if (storage !== null && angular.isDefined(storage) && angular.isObject(storage)){
	$scope.current_page = storage.page;
	$scope.filters      = storage.filter;
	$scope.select.phone = storage.phone;
    }

    var now = $.now();
    $scope.time = diabloFilter.default_time(now, now);

    $scope.save_stastic = function(){
	localStorageService.remove(bsaleService.diablo_key_bsaler_stastic);
	localStorageService.set(
	    bsaleService.diablo_key_bsaler_stastic,
	    {total_items:       $scope.total_items, 
	     total_balance:     $scope.total_balance,
	     t:                 now});
    };
    
    var add_search_condition = function(search) {
	if (angular.isDefined($scope.select.phone) && angular.isObject($scope.select.phone)){
	    search.mobile = $scope.select.phone.mobile;
	    search.py = $scope.select.phone.py;
	} 
	return search;
    };
    
    $scope.do_search = function(page){
	// console.log($scope.filters);
    	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    // console.log($scope.select.phone); 
	    search = add_search_condition(search);
	    console.log(search);
	    localStorageService.remove(bsaleService.diablo_key_bsaler);
	    localStorageService.set(
		bsaleService.diablo_key_bsaler,
		{filter:$scope.filters, phone: $scope.select.phone, page: page, t: now});

	    if (page !== $scope.default_page) {
	    	var stastic = localStorageService.get(bsaleService.diablo_key_bsaler_stastic);
	    	$scope.total_items       = stastic.total_items; 
	    	$scope.total_balance     = stastic.total_balance;
	    };
	    
    	    bsaleService.filter_bsaler(
		$scope.sort, $scope.match, search, page, $scope.items_perpage
    	    ).then(function(result){
    		console.log(result);
    		if (result.ecode === 0){
    		    if (page === $scope.default_page){
			$scope.total_items   = result.total;
			$scope.total_balance = result.balance;
			$scope.save_stastic();
    		    }
		    
		    $scope.salers = angular.copy(result.data); 
		    angular.forEach($scope.salers, function(s){
			s.type   = diablo_get_object(s.type_id, $scope.bsaler_types);
			s.region = diablo_get_object(s.region_id, $scope.regions);
			s.shop   = diablo_get_object(s.shop_id, $scope.shops);
		    });
		    
    		    diablo_order($scope.salers, (page - 1) * $scope.items_perpage + 1);
    		    $scope.current_page = page;
    		} 
    	    })
    	})
    };

    $scope.refresh = function(){
	localStorageService.remove(bsaleService.diablo_key_bsaler_stastic);
	$scope.select.phone = undefined;
	$scope.do_search($scope.default_page);
    };

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };

    $scope.refresh();

    $scope.update_bsaler = function(s) {
	var callback = function(params) {
	    console.log(params);
	    var newBSaler = params.bsaler;
	    
	    var update = {
		shop:    diablo_get_modified(params.bsaler.shop.id, s.shop_id),
		name:    diablo_get_modified(diablo_trim(params.bsaler.name), s.name),
		mobile:  diablo_get_modified(diablo_trim(params.bsaler.mobile), s.mobile),
		balance: diablo_get_modified(params.bsaler.balance, s.balance),
		address: diablo_get_modified(diablo_trim(params.bsaler.address), s.address),
		region:  diablo_get_modified(params.bsaler.region.id, s.region_id),
		comment: diablo_get_modified(diablo_trim(params.bsaler.remark), s.remark),
		py: diablo_get_modified(diablo_pinyin(params.bsaler.name), diablo_pinyin(s.name)),
	    };

	    console.log(update);
	    if (diablo_is_empty(update)) {
		dialog.set_batch_error("客户编辑", 9004); 
	    } else {
		bsaleService.update_bsaler(s.id, update).then(function(result) {
		    console.log(result);
		    if (result.ecode === 0) {
			dialog.response_with_callback(
			    true, "客户编辑", "会员 [" + s.name + "] 信息修改成功！！",
			    $scope, function(){
				$scope.do_search($scope.current_page);
			    });
		    } else {
			dialog.set_batch_error("客户编辑", result.ecode); 
		    }
		});
	    }
	};

	dialog.edit_with_modal(
	    "update-bsaler.html", undefined, callback, undefined,
	    {shops:$scope.shops,
	     regions:$scope.regions,
	     pattern:$scope.pattern,
	     bsaler:s});
    }
};
