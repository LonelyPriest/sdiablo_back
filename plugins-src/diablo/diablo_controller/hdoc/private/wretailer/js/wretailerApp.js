"use strict";

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], wretailerConfig);

function wretailerConfig(angular) {
    var wretailerApp = angular.module(
	'wretailerApp',
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function(localStorageServiceProvider){
	localStorageServiceProvider
	    .setPrefix('wretailerApp')
	    .setStorageType('localStorage')
	    .setNotify(true, true)
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
    }]).config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

    wretailerApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
    	    return userService()}};

	var brand = {"filterBrand": function(diabloFilter){
	    return diabloFilter.get_brand()}};

	var firm = {"filterFirm": function(diabloFilter){
	    return diabloFilter.get_firm()}};

	// var type = {"filterType": function(diabloFilter){
	//     return diabloFilter.get_type()}};
	
	var s_group = {"filterSizeGroup": function(diabloFilter){
	    return diabloFilter.get_size_group()}};
	
	var employee = {"filterEmployee": function(diabloNormalFilter){
	    return diabloNormalFilter.get_employee()}}; 

	var base = {"base": function(diabloNormalFilter){
	    return diabloNormalFilter.get_base_setting()}};

	var charge = {"filterCharge": function(diabloNormalFilter){
	    return diabloNormalFilter.get_charge()}};

	var promotion = {"filterPromotion": function(diabloFilter){
	    return diabloFilter.get_promotion()}};

	var score = {"filterScore": function(diabloNormalFilter){
	    return diabloNormalFilter.get_score()}};

	var color = {"filterColor": function(diabloFilter){
	    return diabloFilter.get_color()}};

	var region = {"filterRegion": function(diabloNormalFilter){
	    return diabloNormalFilter.get_region()}};

	var shop = {"filterShop": function(diabloNormalFilter){
            return diabloNormalFilter.get_shop()}};

	var ticket_plan = {"filterTicketPlan": function(diabloFilter){
            return diabloFilter.get_ticket_plan()}};
	
	$routeProvider. 
	    when('/wretailer_new', {
		templateUrl: '/private/wretailer/html/wretailer_new.html',
		controller: 'wretailerNewCtrl',
		resolve: angular.extend({}, user, base) 
	    }).
	    when('/wretailer_detail', {
		templateUrl: '/private/wretailer/html/wretailer_detail.html',
		controller: 'wretailerDetailCtrl',
		resolve: angular.extend({}, employee, charge, region, ticket_plan, user, base)
	    }).
	    when('/print_w_retailer/:search/:sort?', {
		templateUrl: '/private/wretailer/html/print_w_retailer.html',
		controller: 'wretailerDetailPrintCtrl',
		resolve: angular.extend({}, user, base)
	    }).
	    when('/wretailer_charge_detail', {
		templateUrl: '/private/wretailer/html/wretailer_charge_detail.html',
		controller: 'wretailerChargeDetailCtrl',
		resolve: angular.extend({}, employee, charge, user, base)
	    }).
	    when('/wretailer_trans/:retailer?/:page?', {
		templateUrl: '/private/wretailer/html/wretailer_trans.html',
		controller: 'wretailerTransCtrl',
		resolve: angular.extend({}, employee, user, base)
	    }). 
	    when('/wretailer_trans_rsn/:retailer?/:rsn?/:ppage?', {
		templateUrl: '/private/wretailer/html/wretailer_trans_rsn_detail.html',
		controller: 'wretailerTransRsnDetailCtrl',
		resolve: angular.extend({}, brand, firm, employee, s_group, promotion, score, color, user, base)
	    }).
	    // recharge and score
	    when('/promotion/recharge_new/:action?', {
		templateUrl: '/private/wretailer/html/recharge_new.html',
		controller: 'wretailerRechargeNewCtrl'
	    }). 
	    when('/promotion/recharge_detail', {
		templateUrl: '/private/wretailer/html/recharge_detail.html',
		controller: 'wretailerRechargeDetailCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/promotion/score_new', {
		templateUrl: '/private/wretailer/html/score_new.html',
		controller: 'wretailerScoreNewCtrl'
	    }).
	    when('/promotion/score_detail', {
		templateUrl: '/private/wretailer/html/score_detail.html',
		controller: 'wretailerScoreDetailCtrl',
		resolve: angular.extend({}, user)
	    }).
	    // ticket
	    when('/ticket/score_ticket_detail', {
		templateUrl: '/private/wretailer/html/ticket_detail.html',
		controller: 'wretailerTicketDetailCtrl',
		resolve: angular.extend({}, shop, score, user)
	    }).
	    when('/ticket/custom_ticket_detail', {
		templateUrl: '/private/wretailer/html/custom_ticket_detail.html',
		controller: 'wretailerCustomTicketDetailCtrl',
		resolve: angular.extend({}, ticket_plan, shop, employee)
	    }).
	    when('/ticket/plan_custom_ticket', {
		templateUrl: '/private/wretailer/html/custom_ticket_plan.html',
		controller: 'wretailerPlanCustomTicketCtrl',
		resolve: angular.extend({}, user)
	    }).
	    // threshold card
	    when('/threshold_card/card_detail', {
		templateUrl: '/private/wretailer/html/threshold_card_detail.html',
		controller: 'wretailerThresholdCardDetailCtrl',
		resolve: angular.extend({}, employee, user, base)
	    }).
	    when('/threshold_card/card_good', {
		templateUrl: '/private/wretailer/html/threshold_card_good.html',
		controller: 'wretailerThresholdCardGoodCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/threshold_card/card_sale', {
		templateUrl: '/private/wretailer/html/threshold_card_sale.html',
		controller: 'wretailerThresholdCardSaleCtrl',
		resolve: angular.extend({}, employee, shop)
	    }).
	    when('/threshold_card/card_sale_note', {
		templateUrl: '/private/wretailer/html/threshold_card_sale_note.html',
		controller: 'wretailerThresholdCardSaleNoteCtrl',
		resolve: angular.extend({}, employee, shop)
	    }).
	    // level
	    when('/level', {
		templateUrl: '/private/wretailer/html/retailer_level.html',
		controller: 'wretailerLevelCtrl',
		resolve: angular.extend({}, user, base)
	    }).
	    // consume
	    when('/consume', {
		templateUrl: '/private/wretailer/html/retailer_consume.html',
		controller: 'wretailerConsumeCtrl',
		resolve: angular.extend({}, shop, user, base)
	    }).
	    // gift
	    when('/gift', {
		templateUrl: '/private/wretailer/html/retailer_gift.html',
		controller: 'wretailerGiftCtrl',
		resolve: angular.extend({}, employee, shop, user)
	    }).
	    when('/gift_exchange', {
		templateUrl: '/private/wretailer/html/gift_exchange.html',
		controller: 'wretailerGiftExchangeCtrl',
		resolve: angular.extend({}, employee, shop, user)
	    }).
	    
	    // default
	    otherwise({
		templateUrl: '/private/wretailer/html/wretailer_detail.html',
		controller: 'wretailerDetailCtrl',
		resolve: angular.extend({}, employee, charge, region, ticket_plan, user, base)
            })
    }]);

    wretailerApp.service("wretailerService", function($resource, dateFilter){
	this.error = {
     	    2101: "会员信息重复，该手机号码已注册！！",
	    2102: "会员密码不正确，请重新输入！！",
	    2103: "充值方案名称已存在，请重新输入方案名称!!",
	    2104: "积分方案已存在，请重新输入方案，！！",
	    2105: "该电子卷不存在，请重新选择电子卷！！",
	    2106: "该电子卷已经确认过，无法再确认，请重新选择电子卷！！",
	    2107: "该电子卷已被消费，请重新选择电子卷",
	    2108: "积分况换钱的方案有且只能有一个！！",
	    2109: "非法充值方案标识，请重新选择充值方案！！",
	    // 2115: "制券数量一次不能超过1000张，请重新输入制券数量",
	    // 2116: "券金额不能超过500元，请重新输入券金额",
	    2117: "批次号已存在，请重新输入批次号",
	    // 2118: "批次号不能超过9位，请重新输入批次号",
	    2199: "介绍人不能是自己,请重新选择介绍人", 
	    2501: "短信中心不存在，请联系服务人员！！",
	    2502: "短信发送失败，余额不足，请联系服务人员充值！！",
	    2503: "短信提醒服务没有开通，请联系服务人员开通该功能！！", 
	    2599: "短信发送失败，请核对号码后人工重新发送！！",
	    2110: "该充值方案正在使用，请解挂该充值方案后再删除！！",
	    2113: "该会员存在充值或销售记录，无法删除，请先删除该会员充值或销售记录后再删除！！",
	    2114: "会员卡号已被使用，请选择新的会员卡号！！",
	    2136: "已消费电子券无法废弃，请重新选择条件！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	this.score_rules = [
	    {name: "钱兑换积分", id:0, remark: "钱换积分"},
	    {name: "积分兑换钱", id:1, remakr: "积分换钱"}
	];

	this.gift_rules = [
	    {name: "按月需积分领取", id:0, remark: "每个月按积分仅能领取一次"},
	    {name: "按月免费领取", id:1, remark: "每个月免费仅能领取一次"},
	    {name: "按积分领取", id:2, remark: "按积分领取无限制"},
	    {name: "按年需积分领取", id:3, remark: "每年按积分仅能领取一次"},
	    {name: "按年免费领取", id:4, remark: "每年按积分仅能领取一次"}
	];

	this.gift_exchange_modes = [{name: "免费领取", id:0}, {name: "积分兑换", id:1}];

	this.charge_rules = [
	    {name:"固定赠送模式", id:diablo_giving_charge, remark: "充值多少赠送固定金额"},
	    {name:"N倍模式",  id:diablo_times_charge, remark: "N倍充值"},
	    {name:"次卡模式", id:diablo_theoretic_charge, remark: "充值与消费次数相关"},
	    {name:"月卡模式", id:diablo_month_unlimit_charge, remark: "一个月内任意消费次数"},
	    {name:"季卡模式", id:diablo_quarter_unlimit_charge, remark: "一个季度内内任意消费次数"},
	    {name:"年卡模式", id:diablo_year_unlimit_charge, remark: "一年内任意消费次数"},
	    {name:"半年卡模式", id:diablo_half_of_year_unlimit_charge, remark: "一年内任意消费次数"},
	    {name:"余额卡模式", id:diablo_balance_limit_charge, remark: "帐户余额消费模式"}
	];

	this.threshold_cards = [{name:"次卡模式", id:diablo_theoretic_charge},
				{name:"月卡模式", id:diablo_month_unlimit_charge},
				{name:"季卡模式", id:diablo_quarter_unlimit_charge},
				{name:"年卡模式", id:diablo_year_unlimit_charge},
				{name:"半年卡模式", id:diablo_half_of_year_unlimit_charge},
				{name:"余额卡模式", id:diablo_balance_limit_charge}];
	
	this.custom_ticket_plan_rules = [
	    {name:"期限模式", id:0},
	    {name:"日期模式", id:1}];

	// this.sale_rules = [{name:"折扣模式", id:diablo_retailer_sale_by_discount},
	// 		   {name:"直减模式", id:diablo_retailer_sale_by_balance}];
	
	this.retailer_types = diablo_retailer_types;
	
	var http = $resource("/wretailer/:operation/:id",
    			     {operation: '@operation', id: '@id'});

	this.new_wretailer = function(r){
	    return http.save(
		{operation:"new_w_retailer"},
		{name:     r.name,
		 intro:    r.intro && angular.isObject(r.intro) ? r.intro.id : undefined,
		 card:     r.card ? r.card : undefined,
		 py:       diablo_pinyin(r.name),
		 id_card:  r.id_card ? r.card : undefined,
		 password: diablo_set_string(r.password), 
		 score:    diablo_set_float(r.score),
		 mobile:   r.mobile,
		 address:  diablo_set_string(r.address),
		 type:     r.type.id,
		 level:    r.level.level,
		 shop:     r.shop.id,
		 birth:    dateFilter(r.birth, "yyyy-MM-dd"),
		 lunar:    r.lunar.id
		}).$promise;
	};

	this.delete_retailer = function(wretailerId){
	    return http.delete({operation: "del_w_retailer", id:wretailerId}).$promise;
	};

	this.update_retailer = function(r){
	    return http.save(
		{operation: "update_w_retailer"},
		{id:       r.id,
		 card:     r.card,
		 name:     r.name,
		 intro:    r.intro,
		 py:       r.py,
		 id_card:  r.id_card,
		 mobile:   r.mobile,
		 address:  r.address,
		 comment:  r.comment,
		 shop:     r.shop,
		 password: r.password,
		 type:     r.type,
		 level:    r.level,
		 birth:    dateFilter(r.birth, "yyyy-MM-dd"),
		 lunar:    r.lunar,
		 // obalance: r.obalance,
		 balance:  r.balance, 
		}).$promise;
	};

	this.check_retailer_password = function(retailerId, password){
	    return http.save(
		{operation: "check_w_retailer_password"},
		{id:         retailerId,
		 password:   password}).$promise;
	};

	this.reset_password = function(retailerId, password){
	    return http.save(
		{operation: "reset_w_retailer_password"},
		{id:         retailerId,
		 password:   password}).$promise;
	};

	this.update_retailer_score = function(id, score){
	    return http.save(
		{operation: "update_retailer_score"},
		{id:id, score:score}).$promise;
	};

	this.list_retailer = function(){
	    return http.query({operation: "list_w_retailer"}).$promise;
	};

	this.get_retailer = function(retailerId){
	    return http.get({operation: "get_w_retailer", id:retailerId}).$promise;
	};

	this.filter_retailer = function(mode, match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_retailer_detail"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.new_retailer_level = function(shop, level, name, score, discount, rule) {
	    return http.save(
		{operation: "add_retailer_level"},
		{shop: shop,
		 level: level,
		 name: name,
		 score: score,
		 discount: discount,
		 rule: rule}).$promise;
	};

	this.update_retailer_level = function(level, shop, score, discount) {
	    return http.save(
		{operation: "update_retailer_level"}, {
		    level: level, 
		    shop:  shop,
		    score: score,
		    discount: discount}).$promise;
	};

	this.list_retailer_level = function() {
	    return http.query({operation: "list_retailer_level"}).$promise;
	};

	var http_wsale = $resource("/wsale/:operation/:id", {operation: '@operation', id: '@id'});
	
	this.filter_w_sale_new = function(match, fields, currentPage, itemsPerpage){
	    return http_wsale.save(
		{operation: "filter_w_sale_new"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_w_sale_rsn_group = function(
	    mode, match, fields, currentPage, itemsPerpage){
	    return http_wsale.save(
		{operation: "filter_w_sale_rsn_group"},
		{mode:   mode,
		 match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.w_sale_rsn_detail = function(inv){
	    return http_wsale.save(
		{operation: "w_sale_rsn_detail"},
		{rsn:inv.rsn,
		 style_number:inv.style_number, brand:inv.brand}).$promise;
	};

	this.check_w_sale_new = function(rsn){
	    return http_wsale.save({operation: "check_w_sale"},
				   {rsn: rsn}).$promise;
	};

	/*
	 * charge strategy
	 */
	this.new_charge_promotion = function(promotion){
	    return http.save(
		{operation: "add_w_retailer_charge"}, promotion).$promise;
	};

	this.delete_charge_promotion = function(chargeId){
	    return http.save(
		{operation: "del_w_retailer_charge"}, {cid:chargeId}).$promise;
	};

	this.list_charge_promotion = function(){
	    return http.query({operation:"list_w_retailer_charge"}).$promise;
	};

	this.set_withdraw = function(drawId, conditions) {
	    return http.save({operation:"set_w_retailer_withdraw"},
			     {draw_id:drawId, condition:conditions}).$promise;
	};

	/*
	 * recharge of retailer
	 */
	this.new_recharge = function(charge){
	    return http.save({operation:"new_recharge"}, charge).$promise;
	};

	this.delete_recharge = function(rechargeId){
	    return http.save({operation:"delete_recharge"},
			     {recharge: rechargeId}).$promise;
	};

	this.update_recharge = function(charge){
	    return http.save({operation:"update_recharge"},
			     {charge_id: charge.id,
			      employee: charge.employee,
			      shop: charge.shop,
			      datetime: charge.datetime,
			      comment: charge.comment}).$promise;
	};

	this.export_recharge_detail = function(condition){
	    return http.save({operation: "export_recharge_detail"},
			     {condition: condition}).$promise;
	};


	this.filter_charge_detail = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_charge_detail"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	/*
	 * score
	 */
	this.new_score_promotion = function(promotion){
	    return http.save(
		{operation: "add_w_retailer_score"}, promotion).$promise;
	};

	this.list_score_promotion = function(){
	    return http.query({operation:"list_w_retailer_score"}).$promise;
	};

	/*
	 * ticket
	 */
	this.filter_ticket_detail = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_ticket_detail"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.effect_ticket = function(tid){
	    return http.save(
		{operation: "effect_w_retailer_ticket"}, {tid:tid}).$promise;
	};

	this.consume_ticket = function(tid, sid, comment){
	    return http.save(
		{operation: "consume_w_retailer_ticket"}, {tid:tid, sid:sid, comment:comment}).$promise;
	};

	this.syn_ticket = function(conditions) {
	    return http.save({operation: "syn_score_ticket"}, conditions).$promise;
	};

	this.new_ticket_plan = function(plan) {
	    return http.save({operation: "new_ticket_plan"}, plan).$promise;
	};

	this.delete_ticket_plan = function(plan) {
	    return http.delete({operation: "delete_ticket_plan", id:plan}).$promise;
	};

	this.update_ticket_plan = function(plan) {
	    return http.save({operation: "update_ticket_plan"}, plan).$promise;
	};
	

	this.list_ticket_plan = function() {
	    return http.query({operation: "list_ticket_plan"}).$promise;
	};
	
	// this.get_ticket_by_retailer = function(retailerId) {
	//     return http.save(
	// 	{operation: "get_w_retailer_ticket"}, {retailer:retailerId, mode:0}).$promise;
	// };

	// this.get_ticket_by_batch = function(batch) {
	//     return http.save(
	// 	{operation: "get_w_retailer_ticket"}, {batch:batch, mode:1}).$promise;
	// };

	/*
	 * custom ticket
	 */
	this.make_ticket_batch = function(ticket) {
	    return http.save(
		{operation: "make_ticket_batch"}, ticket).$promise;
	};

	this.discard_custom_ticket = function(condition, batch, mode, active) {
	    return http.save(
		{operation: "discard_custom_ticket"},
		{condition:condition, batch:batch, mode:mode, active:active}).$promise;
	};

	this.filter_custom_ticket_detail = function(match, mode, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_custom_ticket_detail"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 mode:   mode,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};


	/*
	 * threshold card
	 */
	this.filter_threshold_card_detail = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_threshold_card_detail"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.add_threshold_card_good = function(card) {
	    return http.save({operation: "add_threshold_card_good"},
			     {shop: card.shop,
			      name: card.name,
			      price: card.price,
			      oil: card.oil}).$promise;
	};

	this.update_threshold_card_good = function(card) {
	    return http.save({operation: "update_threshold_card_good"},
			     {id: card.id,
			      shop: card.shop,
			      name: card.name,
			      price: card.price,
			      oil: card.oil}).$promise;
	};

	this.filter_threshold_card_good = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_threshold_card_good"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_threshold_card_sale = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_threshold_card_sale"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.filter_threshold_card_sale_note = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_threshold_card_sale_note"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.new_threshold_card_sale = function(sale) {
	    return http.save(
		{operation: "new_threshold_card_sale"}, sale).$promise;
	};

	this.delete_threshold_card_sale = function(sale) {
	    return http.save(
		{operation: "delete_threshold_card_sale"}, sale).$promise;
	};

	this.delete_threshold_card = function(card) {
	    return http.save(
		{operation: "delete_threshold_card"}, {card:card}).$promise;
	};

	this.list_threshold_child_card = function(retailer, card_sn) {
	    return http.save(
		{operation: "list_threshold_child_card"},
		{retailer:retailer, csn:card_sn}).$promise;
	};

	this.update_card_expire = function(card_id, expire) {
	    return http.save(
		{operation: "update_card_expire"},
		{card:card_id, expire:expire}).$promise;
	}

	/*
	 * gift
	 */
	this.add_gift = function(gift) {
	    return http.save(
		{operation: "add_w_gift"},
		{code: gift.code,
		 name: gift.name,
		 org_price: gift.org_price,
		 tag_price: gift.tag_price,
		 count:gift.count,
		 py:   angular.isUndefined(gift.name) ? undefined : diablo_pinyin(gift.name),
		 rule: gift.rule,
		 score:gift.score}).$promise;
	};

	this.update_gift = function(gift) {
	    return http.save(
		{operation: "modify_w_gift"},
		{id: gift.id,
		 name: gift.name,
		 org_price: gift.org_price,
		 tag_price: gift.tag_price,
		 count:gift.count,
		 py:   angular.isUndefined(gift.name) ? undefined : diablo_pinyin(gift.name),
		 rule: gift.rule,
		 score:gift.score}).$promise;
	}

	this.filter_gift = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "list_w_gift"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.exchange_gift = function(gift) {
	    return http.save({operation: "exchange_w_gift"}, gift).$promise;
	};

	this.filter_gift_exchange = function(match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "list_w_gift_exchange"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};
	
	/*
	 * 
	 */
	this.export_w_retailer = function(conditions){
	    return http.save({operation: "export_w_retailer"}, conditions).$promise;
	};

	this.print_w_retailer = function(mode, conditions) {
	    return http.save(
		{operation: "print_w_retailer"}, {mode:mode, condition:conditions}).$promise;
	};

	this.syn_retailer_pinyin = function(retailers){
	    return http.save({operation: "syn_retailer_pinyin"},
			     {retailer:retailers}).$promise;
	};

	this.filter_retailer_consume = function(match, mode, fields, currentPage, itemsPerpage) {
	    return http.save(
		{operation: "filter_retailer_consume"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 mode:   mode,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	}
	
    });

    wretailerApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {diablo_login_out($resource)};
    });

    // diablo_remove_app_storage(/^wretailerApp.*$/);

    return wretailerApp;
};



