'use strict'

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], wgoodConfig);

function wgoodConfig(){
    var wgoodApp = angular.module(
	"wgoodApp",
	['ui.bootstrap', 'ngRoute', 'ngResource', 'LocalStorageModule',
	 'diabloAuthenApp', 'diabloPattern', 'diabloUtils', 'diabloFilterApp',
	 'diabloNormalFilterApp', 'userApp']
    ).config(function($httpProvider, authenProvider){
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

    wgoodApp.service("wgoodService", function($resource, $http){
	// error
	this.error = {
	    2001: "货品资料已存在！！",
	    // 2098: "该货品资料正在使用，请先删除该货品对应的库存！！",
	    2073: "自定义条码不支持非标准国际条码，请重新输入！！",
	    2099: "修改前后数据一致，请重新编辑修改项！！",
	    1601: "厂商创建失败，已存在同样的厂商！！",
	    1901: "该颜色已存在，请重新输入颜色名！！",
	    1902: "该尺码组已存在！！",
	    1903: "该尺码组存在不规范的尺码名称，请核对后重试！！",
	    1905: "该颜色对应的条码编码已存在，请重新填写条码编码！！",
	    1906: "品类不允许自定谇条码编码！！",
	    1907: "该品类对应的条码编码已存在，请重新填写条码编码！！",
	    1908: "该品类已存在！！请重新填入品类名！！",
	    1909: "该模式下不允许自定义条码！！",
	    1910: "该货品条码已存在，请重新操作！！",
	    1911: "该货品品类条码编码未设置，无法重置！！",
	    1997: "该货品无条码值，请先重置该货品条码值后再打印！！",
	    1998: "请选择需要打印条码的货品！！",
	    1999: "该货品无厂商，请先设置厂商后再打印条码！！",
	    9001: "数据库操作失败，请联系服务人员！！"};

	// free color, size
	this.free_color = 0;
	this.free_size  = 0;
	
	// =========================================================================    
	var http = $resource("/wgood/:operation/:id",
    			     {operation: '@operation', id: '@id'},
			     {
				 query_by_post: {method: 'POST', isArray:true}
			     });

	this.list_purchaser_brand = function(){
	    return http.query({operation: "list_brand"}).$promise
	};
	
	this.list_purchaser_firm = function(){
	    return http.query({operation: "list_supplier"}).$promise;
	};

	this.list_purchaser_type = function(){
	    return http.query({operation: "list_type"}).$promise;
	};

	/*
	 * color
	 */
	this.list_color_type = function(){
	    return http.query({operation: 'list_color_type'}).$promise;
	};
	
	this.list_purchaser_color = function(){
	    return http.query({operation: 'list_w_color'}).$promise;
	};

	this.get_colors = function(colors){
	    return http.query_by_post(
		{operation: 'get_colors'}, {color: colors}).$promise;
	};

	this.add_purchaser_color = function(color){
	    return http.save(
		{operation: "new_w_color"},
		{name: color.name,
		 bcode: color.bcode,
		 type: color.type,
		 remark: color.remark}).$promise;
	};

	this.update_color = function(color){
	    return http.save(
		{operation: "update_w_color"}, color).$promise;
	};

	this.delete_color = function(colorId){
	    return http.save(
		{operation: "delete_w_color"}, {cid: colorId}).$promise;
	};

	

	/*
	 * good type
	 */
	this.add_good_type = function(type) {
	    return http.save(
		{operation: "new_w_type"},
		{name: type.name, bcode: type.bcode}).$promise;
	};

	this.update_good_type = function(type) {
	    return http.save(
		{operation: "update_w_type"},
		{tid:type.tid, name: type.name, cid: type.cid, bcode: type.bcode}).$promise;
	};

	this.syn_type_pinyin = function(types) {
	    return http.save({operation: "syn_type_pinyin"},
			     {type:types}).$promise;
	};

	/*
	 * size
	 */
	this.list_purchaser_size = function(){
	    return http.query({operation: 'list_w_size'}).$promise;
	};

	// this.add_purchaser_good = function(good){
	// 	return http.save({operation: "new_w_good"}, good).$promise;
	// };

	this.add_purchaser_size = function(group, mode){
	    return http.save(
		{operation: "new_w_size"},
		{mode:   mode,
		 name:   group.name,
		 si:     group.si,
		 sii:    group.sii,
		 siii:   group.siii,
		 siv:    group.siv,
		 sv:     group.sv,
		 svi:    group.svi,
		 svii:   group.svii}).$promise;
	};

	/*
	 * good
	 */
	this.list_purchaser_good = function(){
    	    return http.query({operation: "list_w_good"}).$promise;
	};

	this.filter_purchaser_good = function(
	    match, fields, currentPage, itemsPerpage){
	    return http.save(
		{operation: "filter_w_good"},
		{match:  angular.isDefined(match) ? match.op : undefined,
		 fields: fields,
		 page:   currentPage,
		 count:  itemsPerpage}).$promise;
	};

	this.get_purchaser_good = function(good){
    	    return http.save({operation: "get_w_good"}, good).$promise;
	};

	this.get_purchaser_good_by_id = function(id){
	    return http.get({operation: "get_w_good", id: id}).$promise;
	};

	this.get_used_purchaser_good = function(good){
	    return http.save(
		{operation: "get_used_w_good"},
		{style_number: good.style_number,
		 brand:        good.brand}).$promise;
	};

	this.match_purchaser_style_number = function(viewValue){
	    return http.query_by_post(
		{operation: "match_w_good_style_number"},
		{prompt_value: viewValue}).$promise;
	};

	this.match_purchaser_good_with_firm = function(viewValue, firm){
	    return http.query_by_post(
		{operation: "match_w_good"},
		{prompt_value: viewValue, firm: firm}).$promise;
	};

	this.match_all_purchaser_good = function(start_time, firm){
	    return http.query_by_post(
		{operation: "match_all_w_good"},
		{start_time: start_time, firm: firm}).$promise;
	};

	this.add_purchaser_good = function(good, image){
	    return http.save(
		{operation: "new_w_good"},
		{good:good, image:image}).$promise;
	};

	// this.delete_purchaser_good = function(good){
	//     return http.save(
	// 	{operation:"delete_w_good", id:good.id},
	// 	{style_number: good.style_number, brand: good.brand_id}).$promise;
	// }

	this.update_purchaser_good = function(good, image){
	    return http.save(
		{operation: "update_w_good"},
		{good:good, image:image}).$promise;
	};

	/*
	 * promotion
	 */
	this.new_w_promotion = function(promotion){
	    return http.save(
		{operation: "new_w_promotion"}, promotion).$promise;
	};

	this.update_w_promotion = function(promotion){
	    return http.save(
		{operation: "update_w_promotion"}, promotion).$promise;
	};

	this.list_w_promotion = function(){
	    return http.query({operation: 'list_w_promotion'}).$promise;
	};

	/*
	 * commision
	 */
	this.new_commision = function(name, rule, balance, flat) {
	    return http.save(
		{operation: "new_w_commision"},
		{name:name, rule:rule, balance:balance, flat:flat}).$promise;
	};

	this.list_commision = function() {
	    return http.query({operation: "list_w_commision"}).$promise;
	};

	this.update_commision = function(name, rule, balance, flat) {
	    return http.save(
		{operation: "update_w_commision"},
		{name:name, rule:rule, balance:balance, flat:flat}).$promise;
	};

	/*
	 * barcode
	 */
	this.reset_barcode = function(style_number, brand) {
	    return http.save({operation: 'reset_w_good_barcode'},
			     {style_number:style_number, brand:brand}).$promise;
	};

	/*
	 * firm
	 */
	var firm_http = $resource("/firm/:operation", {operation: '@operation'});
	this.new_firm = function(firm){
    	    var balance = firm.balance;
    	    return firm_http.save(
    		{operation:"new_firm"},
    		{name:    firm.name,
    		 balance: angular.isDefined(balance) ? parseInt(balance) : 0,
    		 mobile:  (angular.isDefined(firm.mobile)
			   && firm.mobile ? firm.mobile:undefined),
    		 address: firm.address}).$promise
	}; 
	
    });

    return wgoodApp;
};
