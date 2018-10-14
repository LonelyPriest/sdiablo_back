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
	
	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}}; 
	
	$routeProvider. 
	    when('/new_bsale', {
		templateUrl: '/private/bsale/html/new_bsale.html',
		controller: 'bsaleNewCtrl',
		resolve: angular.extend(
		    {},
		    user, employee, s_group, brand, type, color, base)
	    }). 
	    when('/new_bsaler', {
		templateUrl: '/private/bsale/html/new_bsaler.html',
		controller: 'bsalerNewCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/bsaler_detail', {
		templateUrl: '/private/bsale/html/bsaler_detail.html',
		controller: 'bsalerDetailCtrl',
		resolve: angular.extend({}, user)
	    }). 
	    otherwise({
		templateUrl: '/private/bsale/html/new_bsale.html',
		controller: 'bsaleNewDetailCtrl',
		resolve: angular.extend(
		    {},
		    user, employee, s_group, brand, type, color, base)
            }) 
    }]);

    bsaleApp.service("bsaleService", function($http, $resource, dateFilter){
	this.bsaler_types = [{name: "普通客户", id:0},
			    {name: "系统客户", id:2}];


	var request = $resource("/bsale/:operation/:id", {operation: '@operation', id: '@id'});

	this.new_bsaler = function(s) {
	    return request.save(
		{operation: "new_batch_saler"},
		{shop:    s.shop,
		 name:    s.name,
		 py:      s.py,
		 type:    s.type,
		 balance: s.balance,
		 mobile:  s.mobile,
		 address: s.address,
		 remark:  s.remark}
	    ).$promise;
	}
	
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

    
    return bsaleApp;
};

function bsaleNewProvide(
    $scope, $q, $timeout, dateFilter, localStorageService,
    diabloUtilsService, diabloPromise, diabloFilter, diabloNormalFilter,
    diabloPattern, bsaleService,
    user, 
    filterEmployee,
    filterSizeGroup, filterType, filterColor, base){
    // console.log(base); 
    $scope.pattern    = {
	money:    diabloPattern.decimal_2,
	sell:     diabloPattern.integer_except_zero,
	discount: diabloPattern.discount,
	barcode:  diabloPattern.number};
    
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
	datetime:     $scope.today()
    };

    // init
    $scope.sale = {barcode:undefined, style_number:undefined};
    $scope.inventories = [];
    
    var dialog = diabloUtilsService; 
    var get_setting = function(shopId){
	$scope.setting.check_sale    = bsaleUtils.check_sale(shopId, base);
	$scope.setting.negative_sale = bsaleUtils.negative_sale(shopId, base);
	$scope.setting.round         = bsaleUtils.round(shopId, base);
	$scope.setting.semployee     = bsaleUtils.s_employee(shopId, base);
	$scope.setting.barcode_mode  = bsaleUtils.barcode_mode(shopId, base);
	$scope.setting.barcode_auto  = bsaleUtils.barcode_auto(shopId, base); 
	$scope.setting.scan_only     = bsaleUtils.to_integer(bsaleUtils.scan_only(shopId, base).charAt(0));
	$scope.setting.type_sale     = bsaleUtils.type_sale(shopId, base); 
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
    $scope.focus_good_or_barcode();
    console.log($scope.focus_attr);

    $scope.change_shop = function(){
	get_setting($scope.select.shop.id);	
	$scope.get_employee();
	$scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
	$scope.bsaleStorage.change_shop($scope.select.shop.id);
	$scope.refresh(); 
    };
    
    if (needCLodop()) {
	loadCLodop(); 
	$scope.comments = bsaleUtils.comment($scope.select.shop.id, base);
    } 
    
    $scope.get_employee = function(){
	var select = bsaleUtils.get_login_employee($scope.select.shop.id, user.loginEmployee, filterEmployee); 
	$scope.employees = select.filter;
	$scope.select.employee = select.login;
	if ($scope.setting.semployee) $scope.select.employee = undefined;
    };
    
    $scope.get_employee();
    
    // retailer;
    $scope.match_bsaler_phone = function(viewValue){
	return bsaleUtils.match_bsaler_phone(viewValue, diabloFilter)
    };
    
    $scope.set_bsaler = function(){
    	if ($scope.select.bsaler.type_id !== diablo_system_retailer){
    	    $scope.select.surplus = bsaleUtils.to_decimal($scope.select.bsaler.balance);
    	    $scope.select.left_balance = $scope.select.surplus;
    	} 
    };
    
    $scope.on_select_bsaler = function(item, model, label){
	// console.log(item);
	console.log($scope.select.bsaler);
	$scope.set_bsaler();
	
	$scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
	$scope.bsaleStorage.change_bsaler($scope.select.bsaler.id);
	$scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate(); 
    };

    $scope.sysBSalers = filterSysBSalers;
    $scope.reset_bsaler = function(){
    	if (diablo_yes === $scope.setting.smember){
    	    $scope.sysBSalers = filterSysBSalers.filter(function(r){
    		return r.shop_id === $scope.select.shop.id;
    	    });
    	};
	
    	// console.log($scope.retailer);
    	if ($scope.sysBSalers.length !== 0){
    	    $scope.select.bsaler = $scope.sysBSalers[0];
    	    if (user.loginBSaler !== diablo_invalid){
    		for (var i=0, l=$scope.sysBSalers.length; i<l; i++){
		    if (user.loginBSaler === $scope.sysBSalers[i].id){
    			$scope.select.bsaler = $scope.sysBSalers[i]
    			break;
		    }
    		}
	    }
	    
    	    $scope.set_bsaler(); 
    	};
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
    // console.log($scope.wsaleStorage);
    
    $scope.disable_draft = function(){
	return $scope.bsaleStorage.keys().length === 0 || $scope.inventories.length !== 0;
	
    };

    $scope.list_draft = function(){
	var keys = $scope.bsaleStorage.keys(); 
	var bsalerIds = keys.map(function(k){
	    var p = k.split("-");
	    return parseInt(p[1]);
	}); 
	// console.log(retailerIds);
	
	diabloFilter.get_bsaler_batch(bsalerIds).then(function(bsalers){
	    console.log(bsalers); 
	    var draft_filter = function(keys){
		return keys.map(function(k){
		    var p = k.split("-");
		    return {sn:k,
			    // employee:diablo_get_object(p[1], $scope.employees),
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
	add.state        = src.state;
	add.entry        = src.entry_date;

	// add.full_bcode   = angular.isUndefined(src.full_bcode) ? src.bcode : src.full_bcode;
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
	if (item.tag_price < 0){
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
	    dialog.set_error("批发开单", 2196);
	    return;
	}
	
	diabloFilter.get_stock_by_barcode(barcode.cuted, $scope.select.shop.id).then(function(result){
	    console.log(result);
	    if (result.ecode === 0) {
		if (diablo_is_empty(result.stock)) {
		    dialog.set_error("批发开单", 2195);
		} else {
		    result.stock.full_bcode = barcode.correct;
		    $scope.on_select_good(result.stock);
		}
	    } else {
		dialog.set_error("批发开单", result.ecode);
	    }
	});
	
    };
    
    /*
     * save all
     */
    $scope.disable_save = function(){
	return $scope.has_saved || $scope.draft || $scope.inventories.length === 0 ? true : false; 
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
	
	var setv = diablo_set_float;
	var seti = diablo_set_integer;
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
	    cash:           setv($scope.select.cash),
	    card:           setv($scope.select.card),
	    wxin:           setv($scope.select.wxin), 
	    verificate:     setv($scope.select.verificate), 
	    
	    should_pay:     setv($scope.select.should_pay),
	    has_pay:        $scope.select.has_pay,
	    
	    total:          $scope.select.total, 
	    round:          $scope.setting.round
	};
	
	console.log(base);

	bsaleService.new_bsale({inventory:added.length===0 ? undefined:added, base:base, print:print}).then(function(result){
	    console.log(result);
	    var success_callback = function(){
		// clear local storage
		if (angular.isDefined($scope.select_draft_key)){
		    $scope.bsaleStorage.remove($scope.select_draft_key);
		    $scope.select_draft_key = undefined;
		};
		
		$scope.bsaleStorage.remove($scope.bsaleStorage.get_key()); 
		$scope.refresh(); 
	    }
	    
	    if (result.ecode === 0){
		$scope.select.rsn = result.rsn; 
		// print
	    } else {
		dialog.response_with_callback(
	    	    false,
		    "批发开单",
		    "开单失败：" + bsaleService.error[result.ecode]
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
	$scope.select.has_pay -= bsaleUtils.to_float($scope.select.verificate);
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
    
    $scope.re_calculate = function(){
	// console.log("re_calculate");
	$scope.select.total        = 0;
	$scope.select.abs_total    = 0;
	$scope.select.should_pay   = 0; 
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
	    $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
	    $scope.re_calculate();	    
	    $scope.focus_good_or_barcode(); 
	};
	
	// check stock total 
	if ($scope.setting.check_sale && free_stock_not_enought(inv)) {
	    // diabloUtilsService.set_error("销售开单", 2180); 
	    var ERROR = require("diablo-batch-error"); 
	    diabloUtilsService.request("批发开单", ERROR[2180], callback, true, undefined);
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

	// inv.cdiscount      = inv.discount;
	// inv.cprice         = inv.tag_price;

	inv.fdiscount = inv.discount;
	inv.fprice    = diablo_price(inv.tag_price, inv.discount);

	// inv.fdiscount = $scope.calc_discount(inv); 
	// inv.fprice    = diablo_price(inv.tag_price, inv.fdiscount);

	inv.o_fdiscount = inv.discount;
	inv.o_fprice    = inv.fprice;
	
	if ($scope.setting.check_sale === diablo_no && inv.free === 0){
	    inv.free_color_size = true;
	    inv.amounts         = [{cid:0, size:0}];
	    inv.sell = 1; 
	    $scope.auto_save_free(inv);
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
			    diabloUtilsService.set_error("批发开单", 2180);
			} else {
			    inv.$edit = true;
			    inv.$new = false;
			    $scope.disable_refresh = false;
			    $scope.inventories.unshift(inv);
			    
			    inv.order_id = $scope.inventories.length; 
			    $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new})); 
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

	if ($scope.inventories.length > 1){
	    $scope.bsaleStorage.save(
		$scope.inventories.filter(function(r){return !r.$new})); 
	} else {
	    $scope.bsaleStorage.remove($scope.bsaleStorage.get_key());
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
	    $scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
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
	$scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));

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
	
	var sell = bsaleUtils.to_integer(inv.sell);
	if (sell === 0) return
	if (angular.isUndefined(inv.style_number)) return;
	

	if (inv.$new && inv.free_color_size){
	    $scope.add_free_inventory(inv);
	}; 

	if (!inv.$new && inv.free_update){
	    if ($scope.setting.check_sale && sell > inv.total){
		if (angular.isDefined(inv.form.sell)) {
		    inv.form.sell.$invalid = true;
		    inv.form.sell.$pristine = false; 
		}
		inv.invalid_sell = true; 
		return;
	    }
	    
	    if (!$scope.setting.negative_sale && sell < 0) {
		if (angular.isDefined(inv.form.sell)) {
		    inv.form.sell.$invalid = true;
		    inv.form.sell.$pristine = false;
		}
		inv.invalid_sell = true;
		return;
	    }; 
	    $scope.save_free_update(inv); 
	} 
    };

    $scope.gift_sale = function(inv) {
	inv.fprice = 0;
	$scope.bsaleStorage.save($scope.inventories.filter(function(r){return !r.$new}));
	$scope.re_calculate();
    };
};


function bsalerNewCtrlProvide(
    $scope, bsaleService, diabloPattern, diabloUtilsService, user){
    $scope.pattern = {name_address: diabloPattern.ch_name_address,
		      tel_mobile:   diabloPattern.tel_mobile,
		      name:         diabloPattern.chinese_name};
    $scope.shops = user.sortShops;
    $scope.bsaler_types = bsaleService.bsaler_types;
    
    $scope.bsaler = {
	type :$scope.bsaler_types[0],
	shop :$scope.shops[0]
    };

    var dialog = diabloUtilsService;
    $scope.new_bsaler = function(bsaler) {
	console.log(bsaler);
	var saler = {shop:    bsaler.shop.id,
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
		diablo_goto_page("#/basler_detail")
	    } else {
		dialog.set_batch_error("新增客户", result.ecode)
	    }
	});
    };
};

function bsalerDetailCtrlProvide(
    $scope, bsaleService, diabloPattern, diabloUtilsService, user){
    
};


