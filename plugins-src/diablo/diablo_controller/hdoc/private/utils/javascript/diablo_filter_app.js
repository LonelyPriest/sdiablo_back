'use strict'

var diabloFilterApp = angular.module("diabloFilterApp", [], function($provide){
    $provide.provider('diabloFilter', filterProvider)
});


var set_storage = function(key, name, value){
    var storage = localStorage.getItem(key);
    if (angular.isDefined(storage) && storage !== null) {
	var caches = JSON.parse(storage);
	caches[name] = value;
	// console.log(caches); 
	localStorage.setItem(key, JSON.stringify(caches));
    } else {
	var obj = {};
	obj[name] = value;
	localStorage.setItem(key, JSON.stringify(obj));
    }
};

var get_from_storage = function(key, name){
    var storage = localStorage.getItem(key);
    if (angular.isDefined(storage) && storage !== null) {
	var caches = JSON.parse(storage);
	// console.log(caches);
	// console.log(caches[name]);
	return angular.isDefined(caches[name]) ? caches[name] : undefined;
    }
    
    return undefined;
};

var clear_from_storage = function(key, name){
    var storage = localStorage.getItem(key);
    if (angular.isDefined(storage) && storage !== null) {
	var caches = JSON.parse(storage);
	for (var o in caches){
	    if (o === name) delete caches[o];
	}
	
	localStorage.setItem(key, JSON.stringify(caches));   
    }

};

function filterProvider(){
    // one filter include many fileds that used to filter
    var _filter = {fields: []}; 
    // prompt
    var _prompt = {};

    // cache
    var _retailers   = [];
    var _firms       = [];
    var _brands      = [];
    var _types       = [];
    var _colors      = [];
    var _color_types = [];
    var _employees   = [];
    var _size_groups = [];
    var _promotions  = [];
    var _commisions  = [];

    // var _executives  = [];
    // var _category    = [];
    // var _fabric      = [];
    
    // var _chargs      = [];
    // var _scores      = [];

    this.$get = function($resource, dateFilter){
	var resource = $resource(
	    "/purchaser/:operation", {operation: '@operation'},
	    {query_by_post: {method: 'POST', isArray:true}});

	var _shopHttp = $resource("/shop/:operation", {operation: '@operation'},
				  {query_by_post: {method: 'POST', isArray:true}});
	
	var _goodHttp = $resource("/wgood/:operation/:id",
				  {operation: '@operation', id:'@id'},
				  {query_by_post: {method: 'POST', isArray: true}});

	var _firmHttp = $resource("/firm/:operation/:id",
    				  {operation: '@operation', id: '@id'},
				  {query_by_post: {method: 'POST', isArray: true}});

	var _retailerHttp = $resource("/wretailer/:operation/:id",
				      {operation: '@operation', id:'@id'},
				      {post: {method: 'POST', isArray: true}});

	var _wsaleHttp = $resource("/wsale/:operation/:id",
    				   {operation: '@operation', id: '@id'},
				   {query_by_post: {method: 'POST', isArray: true}});

	var _baseSettingHttp = $resource("/wbase/:operation/:id", {operation: '@operation'},
					 {query_by_post: {method: 'POST', isArray: true}});
	
	var cookie = 'filter-' + diablo_get_cookie("qzg_dyty_session");

	function list_wsale_group_by_style_number(condition) {
	    return _wsaleHttp.save(
		{operation: "list_wsale_group_by_style_number"},
		{condition: condition}).$promise;  
	};
	
	function list_w_promotion() {
	    return _goodHttp.query({operation: 'list_w_promotion'}).$promise;
	};

	function list_w_commision() {
	    return _goodHttp.query({operation: 'list_w_commision'}).$promise;
	};

	function list_purchaser_firm() {
	    return _goodHttp.query({operation: "list_supplier"}).$promise;
	};

	function match_vfirm(viewValue, mode) {
	    return _firmHttp.query_by_post(
		{operation: "match_vfirm"},
		{prompt_value: viewValue, mode:mode}).$promise;
	};

	function list_purchaser_size(){
	    return _goodHttp.query({operation: 'list_w_size'}).$promise;
	};

	function list_purchaser_brand() {
	    return _goodHttp.query({operation: "list_brand"}).$promise;
	};

	function list_purchaser_type() {
	    return _goodHttp.query({operation: "list_type"}).$promise;
	};

	function list_purchaser_color() {
	    return _goodHttp.query({operation: 'list_w_color'}).$promise;
	};

	function list_color_type() {
	    return _goodHttp.query({operation: 'list_color_type'}).$promise;
	};

	function match_all_purchaser_good(start_time, firm){
	    return _goodHttp.query_by_post(
		{operation: "match_all_w_good"},
		{start_time: start_time, firm: firm}).$promise;
	};

	function match_purchaser_style_number(viewValue){
	    return _goodHttp.query_by_post(
		{operation: "match_w_good_style_number"},
		{prompt_value: viewValue}).$promise;
	};

	function match_purchaser_good_with_firm(viewValue, firm){
	    return _goodHttp.query_by_post(
		{operation: "match_w_good"},
		{prompt_value: viewValue, firm: firm}).$promise;
	};

	function add_purchaser_good (good, image){
	    return _goodHttp.save({operation: "new_w_good"}, {good:good, image:image}).$promise;
	};

	function get_good_by_barcode(barcode) {
	    return _goodHttp.save({operation: "get_good_by_barcode"}, {barcode:barcode}).$promise;
	};

	function update_purchaser_good(good, image) {
	    return _goodHttp.save({operation: "update_w_good"}, {good:good, image:image}).$promise;  
	};

	function delete_purchaser_good(style_number, brand) {
	    return _goodHttp.save(
		{operation:"delete_w_good"},
		{style_number: style_number, brand: brand}).$promise;
	};

	function add_purchaser_color(color){
	    return _goodHttp.save(
		{operation: "new_w_color"},
		{name: color.name, type: color.type, remark: color.remark}).$promise;
	};

	function get_purchaser_good(good){
	    return _goodHttp.save({operation: "get_w_good"}, good).$promise;
	}; 

	function list_good_std_executive() {
	    return _baseSettingHttp.query({operation: 'list_std_executive'}).$promise;
	};

	function list_good_safety_category() {
	    return _baseSettingHttp.query({operation: 'list_safety_category'}).$promise;
	};

	function list_good_fabric() {
	    return _baseSettingHttp.query({operation: 'list_fabric'}).$promise;
	};

	function list_good_ctype() {
	    return _baseSettingHttp.query({operation: 'list_ctype'}).$promise;
	};

	function list_good_size_spec() {
	    return _baseSettingHttp.query({operation: 'list_size_spec'}).$promise;
	};

	function list_print_template() {
	    return _baseSettingHttp.query({operation: 'list_print_template'}).$promise;
	};

	function list_threshold_card_good(shopIds) {
	    return _retailerHttp.post(
		{operation: "list_threshold_card_good"}, {shop: shopIds}).$promise;
	};

	function list_retailer_level() {
	    return _retailerHttp.query(
		{operation: "list_retailer_level"}).$promise;
	};

	function list_ticket_plan() {
	    return _retailerHttp.query(
		{operation: "list_ticket_plan"}).$promise;
	};
	
	return{
	    default_time: function(start, end){
		var now = end;
		if (angular.isUndefined(now)){
		    now = $.now();
		}
		if (angular.isUndefined(start)){
		    return {start_time: now - diablo_day_millisecond * 30, end_time: now}; 
		} else{
		    return {start_time: start, end_time: now}; 
		}
		
	    },

	    default_start_time: function(now){
	    	return now - diablo_day_millisecond * 30;
	    },
	    
	    reset_field: function(){
		_filter.fields = [];
	    },
	    
	    add_field: function(name, promptValues, onSelect){
		if (name === 'firm'){
		    _filter.fields.push({name:"firm", chinese:"厂商"});
		    _prompt.firm = promptValues;
		} else if (name === 'style_number'){
		    _filter.fields.push({name:"style_number", chinese:"款号"});
		    _prompt.style_number = promptValues;
		    // _prompt.on_select_style_number = onSelect;
		} else if (name === 'brand'){
		    _filter.fields.push({name:"brand", chinese:"品牌"});
		    _prompt.brand = promptValues;
		} else if (name === 'ctype'){
		    _filter.fields.push({name:"ctype", chinese:"大类"});
		    _prompt.ctype = promptValues;
		} else if (name === 'type'){
		    _filter.fields.push({name:"type", chinese:"类别"});
		    _prompt.type = promptValues;
		} else if (name === 'season'){
		    _filter.fields.push({name:"season", chinese:"季节"});
		    _prompt.season = promptValues;
		} 
		else if (name === 'sex'){
		    _filter.fields.push({name:"sex", chinese:"性别"});
		    _prompt.sex = promptValues;
		}
		else if (name === 'year'){
		    _filter.fields.push({name:"year", chinese:"年度"});
		    _prompt.year = promptValues;
		}

		else if (name === 'rsn'){
		    _filter.fields.push({name:"rsn", chinese:"单号"});
		    _prompt.rsn = promptValues;
		} else if(name === 'shop'){
		    _filter.fields.push({name:"shop", chinese:"店铺"});
		    _prompt.shop = promptValues;
		} else if(name === 'stock'){
		    _filter.fields.push({name:"stock", chinese:"库存"});
		    _prompt.stock = promptValues;
		} else if(name === 'employee'){
		    _filter.fields.push({name:"employ", chinese:"店员"});
		    _prompt.employee = promptValues;
		}else if(name === 'retailer'){
		    _filter.fields.push({name:"retailer", chinese:"客户"});
		    _prompt.retailer = promptValues;
		}else if (name === 'sell_type') {
		    _filter.fields.push({name:"sell_type", chinese:"销售类型"});
		    _prompt.sell_type = promptValues;
		}else if (name === 'purchaser_type'){
		    _filter.fields.push({name:"purchaser_type", chinese:"采购类型"});
		    _prompt.purchaser_type = promptValues; 
		}else if (name === 'comment') {
		    _filter.fields.push({name:"comment", chinese:"备注"});
		    _prompt.comment = promptValues; 
		} else if (name === 'has_pay'){
		    _filter.fields.push({name:"has_pay", chinese:"实付查询"});
		    _prompt.has_pay = promptValues;
		} else if (name === 'card'){
		    _filter.fields.push({name:"card", chinese:"银行卡号"});
		    _prompt.cards = promptValues;
		} else if (name === 'discount'){
		    _filter.fields.push({name:"discount", chinese:"折扣"});
		} else if (name === 'mdiscount'){
		    _filter.fields.push({name:"mdiscount", chinese:"折扣大于"}); 
		} else if (name === 'ldiscount'){
		    _filter.fields.push({name:"ldiscount", chinese:"折扣小于"});
		} else if (name === 'rprice'){
		    _filter.fields.push({name:"rprice", chinese:"成交价"});
		} else if (name === 'tag_price'){
		    _filter.fields.push({name:"tag_price", chinese:"吊牌价"});
		} else if (name === 'org_price'){
		    _filter.fields.push({name:"org_price", chinese:"进货价"});
		} else if (name === 'msell'){
		    _filter.fields.push({name:"msell", chinese:"销售>"});
		} else if (name === 'esell'){
		    _filter.fields.push({name:"esell", chinese:"销售="});
		} else if (name === 'lsell'){
		    _filter.fields.push({name:"lsell", chinese:"销售<"});
		} else if (name === 'check_state'){
		    _filter.fields.push({name:"check_state", chinese:"审核状态"});
		    _prompt.check_state = promptValues;
		} else if(name === 'fshop'){
		    _filter.fields.push({name:"fshop", chinese:"调出店铺"});
		    _prompt.fshop = promptValues;
		} else if(name === 'tshop'){
		    _filter.fields.push({name:"tshop", chinese:"调入店铺"});
		    _prompt.tshop = promptValues;
		} else if(name === 'month'){
		    _filter.fields.push({name:"month", chinese:"月份"});
		    _prompt.month = promptValues;
		} else if(name === 'date'){
		    _filter.fields.push({name:"date", chinese:"日期"});
		    _prompt.date = promptValues;
		} else if(name === 'region'){
		    _filter.fields.push({name:"region", chinese:"区域"});
		    _prompt.region = promptValues;
		} else if(name === 'over'){
		    _filter.fields.push({name:"over", chinese:"溢出"});
		    _prompt.over = promptValues;
		} else if (name === 'mconsume'){
		    _filter.fields.push({name:"mconsume", chinese:"消费>"});
		    _prompt.mconsume = promptValues;
		} else if (name ==='mscore') {
		    _filter.fields.push({name:"mscore", chinese:"积分>="});
		    _prompt.mscore = promptValues;
		} else if (name ==='lscore') {
		    _filter.fields.push({name:"lscore", chinese:"积分<="});
		    _prompt.lscore = promptValues;
		} else if (name === 'account'){
		    _filter.fields.push({name:"account", chinese:"收银员"});
		    _prompt.account = promptValues;
		} else if (name === 'level'){
		    _filter.fields.push({name:"level", chinese:"等级"});
		    _prompt.level = promptValues; 
		} else if (name === 'bsaler'){
		    _filter.fields.push({name:"bsaler", chinese:"客户"});
		    _prompt.bsaler = promptValues;
		} else if (name === 'sprice'){
		    _filter.fields.push({name:"sprice", chinese:"特价"});
		    _prompt.sprice = promptValues;
		} else if (name === 'sale_prop') {
		    _filter.fields.push({name:"prop", chinese:"销售场景"});
		    _prompt.bsale_prop = promptValues;
		} else if (name === 'ticket_state') {
		    _filter.fields.push({name:"ticket_state", chinese:"状态"});
		    _prompt.ticket_state = promptValues;
		} else if (name === 'ticket_pshop') {
		    _filter.fields.push({name:"ticket_pshop", chinese:"赠送电铺"});
		    _prompt.ticket_pshop = promptValues;
		} else if (name === 'ticket_plan') {
		    _filter.fields.push({name:"ticket_plan", chinese:"优惠券方案"});
		    _prompt.ticket_plan = promptValues;
		} else if (name === 'ticket_batch') {
		    _filter.fields.push({name:"ticket_batch", chinese:"优惠券券号"});
		    _prompt.ticket_batch = promptValues;
		} else if (name === 'ticket_cshop') {
		    _filter.fields.push({name:"ticket_cshop", chinese:"消费店铺"});
		    _prompt.ticket_cshop = promptValues;
		} else if (name === 'score') {
		    _filter.fields.push({name:"score", chinese:"积分方案"});
		    _prompt.score = promptValues;
		} else if (name === 'pay_type') {
		    _filter.fields.push({name:"pay_type", chinese:"支付方式"});
		    _prompt.pay_type = promptValues;
		} else if (name === 'pay_state') {
		    _filter.fields.push({name:"pay_state", chinese:"支付状态"});
		    _prompt.pay_state = promptValues;
		} else if (name === 'mticket') {
		    _filter.fields.push({name:"mticket", chinese:"用券>="});
		    _prompt.pay_state = promptValues;
		}
		
		return _filter;
	    },

	    get_filter: function(){
		return _filter;
	    },

	    get_prompt: function(){
		return _prompt;
	    },

	    do_filter: function(filters, time, callback){
		var search = {};
		angular.forEach(filters, function(f){
		    if (angular.isDefined(f.value) && (f.value || f.value===0) ){
			var value = undefined;
			if (angular.isObject(f.value))
			    value = f.value.id;
			else 
			    value = f.value;
			// var value = typeof(f.value) === 'object' ? f.value.id : f.value;

			// employ use the number, not id
			// value = f.field.name === "employ" ? f.value.number : value;
			// repeat
			if (search.hasOwnProperty(f.field.name)){
			    var old = [].concat(search[f.field.name]);
			    if (!in_array(old, value)){
				search[f.field.name] = old.concat(value);
			    }
			} else{
			    search[f.field.name] = value;
			}
		    }
		});

		if (angular.isDefined(time)){
		    search.start_time = diablo_filter_time(time.start_time, 0, dateFilter); 
		    search.end_time   = diablo_filter_time(time.end_time, 1, dateFilter);    
		} 
		console.log(search); 
		return callback(search);
	    },
	    
	    match_style_number: function(viewValue){
		if (angular.isUndefined(viewValue) || viewValue.length < diablo_filter_length) return;
		return match_purchaser_style_number(viewValue).then(function(result){
		    // console.log(result);
		    return result.map(function(s){
			return s.style_number;
		    }) 
		})
	    },

	    match_wgood_with_firm: function(viewValue, firm){
		return match_purchaser_good_with_firm(viewValue, firm).then(function(goods){
		    // console.log(goods); 
		    return goods.map(function(g){
			return angular.extend(
			    g, {name:g.style_number + "/" + g.brand + "/" + g.type})
		    })
		})
	    },

	    match_all_w_good: function(start_time, firm){
		return match_all_purchaser_good(start_time, firm);
	    },

	    /*
	     * stock
	     */
	    list_purchaser_inventory: function (condition){
    		return resource.query_by_post(
    		    {operation: "list_w_inventory"}, condition).$promise;
	    },

	    list_w_inventory_info: function(condition){
    		return resource.save(
    		    {operation: "list_w_inventory_info"}, condition).$promise;
	    },
	    
	    // match_w_query_inventory:function(viewValue, Shop){
	    // 	return resource.query_by_post(
	    // 	    {operation:'match_w_inventory'},
	    // 	    {prompt:viewValue, shop:shop, type:1})
	    // 	    .$promise.then(function(invs){
	    // 		console.log(invs);
	    // 		return invs.map(function(inv){
	    // 		    return inv.style_number;
	    // 		})
	    // 	    })
	    // },

	    match_w_reject_inventory: function(viewValue, shop, firm){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:firm, type:1})
		    .$promise.then(function(invs){
			console.log(invs);
			return invs.map(function(inv){
			    var name = inv.style_number + "/"
				+ inv.brand + "/"
				+ inv.type;
			    // var prompt = name + "," + diablo_pinyin(name); 
			    return angular.extend(inv, {name:name});
			})
		    })
	    },

	    match_all_w_reject_inventory: function(start_time, shop, firm){
	    	return resource.query_by_post(
	    	    {operation:'match_all_reject_w_inventory'},
	    	    {start_time: start_time,
	    	     shop:shop,
	    	     firm:firm,
	    	     type:1}
	    	).$promise;
	    },
	    
	    match_w_inventory: function(viewValue, shop, firm){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:firm})
		    .$promise.then(function(invs){
			// console.log(invs);
			if (angular.isUndefined(firm)){
			    return invs.map(function(inv){
				return inv.style_number;
			    })
			} else{
			    return invs.map(function(inv){
				return angular.extend(
				    inv, {name:inv.style_number + "/" + inv.brand + "/" + inv.type})
			    })
			}
		    })
	    },

	    // match_w_fix: function(viewValue, shop){
	    // 	return resource.query_by_post(
	    // 	    {operation:'match_w_inventory'},
	    // 	    {prompt:viewValue, shop:shop, firm:[]})
	    // 	    .$promise.then(function(invs){
	    // 		// console.log(invs);
	    // 		return invs.map(function(inv){
	    // 		    return angular.extend(
	    // 			inv, {name:inv.style_number + "，" + inv.brand + "，" + inv.type})
	    // 		})
	    // 	    })
	    // },

	    list_wsale_group_by_style_number: function(condition) {
		return list_wsale_group_by_style_number(condition);
	    },

	    match_w_sale: function(viewValue, shop, mode, ascii){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:[], mode:mode, ascii:ascii}
		).$promise.then(function(invs){
		    return invs.map(function(inv){
			return angular.extend(
			    inv,
			    {name:inv.style_number
			     + "/" + inv.brand
			     + "/" + inv.type
			     // + (inv.vir_price ? "/" + inv.vir_price.toString() : "") + "/" + inv.tag_price.toString()
			     + "/" + inv.tag_price.toString()
			    })
		    })
		})
	    },

	    match_wsale_rsn_of_new:function(mode, viewValue, shops, conditions) {
		return _wsaleHttp.query_by_post(
		    {operation: "match_wsale_rsn"},
		    {mode:mode, prompt: viewValue, shop: shops, condition:conditions}
		).$promise.then(function(rsns){
		    // console.log(rsns);
		    return rsns.map(function(r){
			return r.rsn;
		    })
		});
	    },

	    match_wsale_rsn_of_all:function(mode, viewValue, conditions) {
		return _wsaleHttp.query_by_post(
		    {operation: "match_wsale_rsn"},
		    {mode:mode, prompt: viewValue, condition:conditions}
		).$promise.then(function(rsns){
		    return rsns.map(function(r){
			return r.rsn;
		    })
		});
	    },

	    match_stock_backend_by_shop: function(shopIds, startTime, viewValue){
		return resource.query_by_post(
		    {operation:'match_stock_by_shop'},
		    {shop:shopIds, stime:startTime, prompt:viewValue}
		).$promise.then(function(stocks){
		    console.log(stocks);
		    return stocks.map(function(s){
			// console.log(s);
			return angular.extend(s, {
			    name:s.style_number + "/" + s.brand + "/" + s.type
			})
		    })
		})
	    },

	    match_retailer_phone:function(viewValue, mode, shop, region) {
		var http = $resource("/wretailer/:operation",
				     {operation: '@operation'},
				     {post: {method: 'POST', isArray: true}});
		
		return http.post({operation:'match_retailer_phone'},
				 {prompt:viewValue, mode:mode, shop:shop, region:region})
		    .$promise.then(function(phones){
			// console.log(phones);
			return phones.map(function(r){
			    return {id:      r.id,
				    name:    r.name+ "/" + r.mobile,
				    wname:   r.name,
				    birth:   r.birth.substr(5,8),
				    wbirth:  r.birth,
				    lunar_id: r.lunar_id,
				    level:   r.level,
				    mobile:  r.mobile,
				    type_id: r.type_id,
				    score:   r.score,
				    shop_id: r.shop_id,
				    draw_id: r.draw_id,
				    py:      r.py,
				    comment: r.comment,
				    balance: r.balance} 
			})
		    })
	    },

	    match_cost_class: function(viewValue, ascii) {
		return _shopHttp.query_by_post(
		    {operation: 'match_cost_class'},
		    {prompt: viewValue, ascii:ascii}
		).$promise.then(function(costs_class) {
		    return costs_class.map(function(c) {
			return {id:c.id, name:c.name};
		    });
		})
	    },

	    wretailer_charge: function(charge) {
		return _retailerHttp.save({operation:"new_recharge"}, charge).$promise;
	    },

	    wretailer_gift_ticket: function(tickets) {
		return _retailerHttp.save({operation:"gift_ticket"}, tickets).$promise;
	    },

	    new_wretailer:function(r) {
		return _retailerHttp.save(
		    {operation:"new_w_retailer"},
		    {name:     r.name,
		     intro:    r.intro,
		     py:       r.py,
		     password: r.password, 
		     mobile:   r.mobile,
		     type:     r.type,
		     level:    r.level,
		     shop:     r.shop,
		     birth:    r.birth,
		     lunar:    r.lunar}).$promise;
	    },

	    update_wretailer:function(r) {
		return _retailerHttp.save(
		    {operation: "update_w_retailer"},
		    {id:       r.id,
		     name:     r.name,
		     py:       r.py,
		     password: r.password,
		     type:     r.type,
		     birth:    dateFilter(r.birth, "yyyy-MM-dd"),
		     lunar:    r.lunar
		    }).$promise;
	    },

	    match_vfirm: function(viewValue, mode) {
		return match_vfirm(viewValue, mode).then(function(vfirms){
		    return vfirms.map(function(v) {
			return {vid: v.id, name:v.name};
		    });
		});
	    },

	    get_stock_by_barcode: function(barcode, shop, firm) {
		return resource.save(
		    {operation:'get_stock_by_barcode'}, {barcode:barcode, shop:shop, firm:firm}).$promise;
	    },

	    check_retailer_password: function(retailerId, password, checkPwd){
		return _retailerHttp.save(
		    {operation: "check_w_retailer_password"},
		    {id:retailerId, password:password, check:checkPwd}).$promise;
	    },

	    check_retailer_region: function(retailerId, shopId) {
		return _retailerHttp.save(
		    {operation: "check_w_retailer_region"},
		    {id:retailerId, shop:shopId}).$promise;
	    },

	    check_retailer_charge: function(retailerId, shopId, pay, balance, retailerDraw) {
		return _retailerHttp.save(
		    {operation: "check_w_retailer_charge"},
		    {id:retailerId, shop:shopId, pay:pay, balance:balance, draw:retailerDraw}).$promise;
	    },

	    check_retailer_trans_count: function(retailerId, retailerPhone, shopId, count) {
		return _retailerHttp.save(
		    {operation: "check_w_retailer_transe_count"},
		    {id:retailerId, phone:retailerPhone, shop:shopId, count:count}).$promise;
	    },
	    
	    list_threshold_card_good:function(deferred, shopIds) {
		var cached = get_from_storage(cookie, "tcard_good");
		if (angular.isArray(cached) && cached.length !== 0)
		    deferred.resolve(cached);
		else {
		    return list_threshold_card_good(shopIds).then(function(goods) {
			var goods = goods.map(function(g) {
			    return {id        :g.id,
				    name      :g.name,
				    shop_id   :g.shop_id,
				    tag_price :g.tag_price}
			});

			set_storage(cookie, "tcard_good", goods);
			deferred.resolve(goods);
		    }); 
		} 
	    },

	    reset_threshold_card_good: function() {
		clear_from_storage(cookie, "tcard_good");
	    },

	    get_retailer_level:function() {
		var cached = get_from_storage(cookie, "r_level");
		if (angular.isArray(cached) && cached.length !== 0) return cached
		else {
		    return list_retailer_level().then(function(levels) {
			var rlevels = levels.map(function(l) {
			    return {name      :l.name,
				    level     :l.level,
				    shop_id   :l.shop_id,
				    discount  :l.discount}
			});

			set_storage(cookie, "r_level", rlevels);
			return rlevels;
		    }); 
		}
		    
	    },

	    reset_retailer_level: function() {
		clear_from_storage(cookie, "r_level");
	    },

	    get_ticket_by_batch: function(batchNo){
		return _retailerHttp.save(
		    {operation: "get_w_retailer_ticket"},
		    {batch:batchNo, mode:diablo_ticket_by_batch, custom:diablo_custom_ticket}).$promise;
	    }, 

	    get_ticket_by_retailer: function(retailer){
		return _retailerHttp.save(
		    {operation: "get_w_retailer_ticket"},
		    {retailer:retailer, mode:diablo_ticket_by_retailer}).$promise;
	    },

	    get_all_ticket_by_retailer: function(retailerId, iShop) {
		return _retailerHttp.save(
		    {operation: "get_w_retailer_all_ticket"},
		    {retailer:retailerId, ishop: iShop}).$promise;
	    },

	    get_ticket_by_sale: function(sale_rsn, custom) {
		return _retailerHttp.save(
		    {operation: "get_w_retailer_ticket"},
		    {sale:sale_rsn, mode:diablo_ticket_by_sale, custom:custom}).$promise;
	    },

	    get_ticket_plan:function() {
		var cached = get_from_storage(cookie, "ticket_plan");
		if (angular.isArray(cached) && cached.length !== 0) return cached
		else {
		    return list_ticket_plan().then(function(planes) {
			var ps = planes.map(function(p) {
			    return {id        :p.id,
				    name      :p.name,
				    py:diablo_pinyin(p.name),
				    balance   :p.balance,
				    mbalance  :p.mbalance,
				    effect    :p.effect,
				    expire    :p.expire,
				    scount    :p.scount}
			});

			set_storage(cookie, "ticket_plan", ps);
			return ps;
		    }); 
		}
		
	    },
	    
	    reset_ticket_plan: function() {
		clear_from_storage(cookie, "ticket_plan");
	    },

	    reset_firm: function(){
		_firms = [];
	    },
	    
	    get_firm: function(){
		if (_firms.length !== 0 ){
		    // console.log("cache");
		    return _firms;
		} else {
		    return list_purchaser_firm(
		    ).then(function(firms){
			_firms = firms.map(function(f){
			    return {id: f.id,
				    bcode: f.bcode,
				    expire: f.expire,
				    name:f.name,
				    py:diablo_pinyin(f.name),
				    balance:f.balance};
			}); 
			return _firms; 
		    });
		}
	    },

	    reset_brand: function(){
		// _brands = [];
		clear_from_storage(cookie, "brand");
	    },
	    
	    get_brand: function(){
		var cached = get_from_storage(cookie, "brand");
		if (angular.isArray(cached) && cached.length !== 0) return cached;
		else {
		    return list_purchaser_brand().then(function(brands){
		    	// console.log(brands);
		    	_brands =  brands.map(function(b){
		    	    return {id: b.id,
				    bcode: b.bcode,
		    		    name:b.name,
		    		    py:diablo_pinyin(b.name),
		    		    // firm: supplier,
		    		    firm_id: b.supplier_id,
		    		    // remark: b.remark,
		    		    // entry: b.entry
		    		   };
		    	})
			set_storage(cookie, "brand", _brands);
		    	return _brands;
		    });    
		} 
	    },

	    reset_type: function(){
		clear_from_storage(cookie, "type");
	    },
	    
	    get_type: function(){
		var cached = get_from_storage(cookie, "type");
		if (angular.isArray(cached) && cached.length !== 0) return cached;
		else {
		    return list_purchaser_type().then(function(types){
			// console.log(types);
			var _types =  types.map(function(t){
			    return {id: t.id, 
				    bcode: t.bcode,
				    cid: t.cid,
				    name:t.name,
				    py:t.py};
			});
			set_storage(cookie, "type", _types) 
			return _types;
		    }); 
		} 
	    },

	    reset_color: function(){
		clear_from_storage(cookie, "color");
	    },
	    
	    get_color: function(){
		var cached = get_from_storage(cookie, "color");
		if (angular.isArray(cached) && cached.length !== 0) return cached;
		else {
		    return list_purchaser_color().then(function(colors){
			_colors = colors.map(function(c){
			    return {id:c.id,
				    bcode:c.bcode,
				    name:c.name,
				    tid:c.tid,
				    type:c.type}
			});
			set_storage(cookie, "color", _colors)
			return _colors;
		    })
		} 
	    },

	    get_color_type: function(){
		var cached = get_from_storage(cookie, "color_type");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_color_type().then(function(types){
			set_storage(cookie, "color_type", types);
			return types;
		    }); 
		}
	    },

	    get_size_group: function(){
		var cached = get_from_storage(cookie, "size");
		if (angular.isDefined(cached) && angular.isArray(cached)) return cached; 
		else {
		    return list_purchaser_size().then(
			function(sizes){
			    // console.log(sizes);
			    _size_groups = sizes.map(function(s){
				return diablo_obj_strip(s);
			    });
			    set_storage(cookie, "size", _size_groups)
			    return _size_groups; 
			});
		}
	    },

	    get_promotion: function(){
		// console.log("get promotion");
		var cached = get_from_storage(cookie, "promotion");
		// console.log(cached);
		if (angular.isDefined(cached) && angular.isArray(cached)) return cached; 
		// if (_promotions.length !== 0){
		//     return _promotions;
		// }
		else {
		    return list_w_promotion().then(function(promotions){
			// console.log(promotions);
			_promotions = promotions.map(function(p){
			    return {
				id:        p.id,
				name:      p.name,
				rule_id:   p.rule_id,
				prule_id:  p.prule_id,
				discount:  p.discount, 
				cmoney:    p.cmoney,
				rmoney:    p.rmoney,
				scount:    p.scount,
				sdiscount: p.sdiscount,
				member:    p.member,
				sdate:     p.sdate,
				edate:     p.edate
			    }
			});
			set_storage(cookie, "promotion", _promotions);
			return _promotions;
		    }); 
		}
	    },

	    reset_promotion: function(){
		clear_from_storage(cookie, "promotion");
	    },

	    get_commision: function() {
		var cached = get_from_storage(cookie, "commision");
		if (angular.isDefined(cached) && angular.isArray(cached)) return cached;
		else {
		    return list_w_commision().then(function(commisions) {
			_commisions = commisions.map(function(m) {
			    return {
				id: m.id,
				name: m.name,
				rule_id: m.rule_id,
				balance: m.balance,
				flat: m.flat
			    }
			}); 
			set_storage(cookie, "commision", _commisions);
			return _commisions;
		    });
		};
	    },

	    reset_commision: function(){
		clear_from_storage(cookie, "commision");
	    },

	    get_employee: function(){
		var cached = get_from_storage(cookie, "employee");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		else {
		    var http = $resource(
			"/employ/:operation", {operation: '@operation'}); 
		    return http.query(
			{operation: 'list_employe'}
		    ).$promise.then(function(employees){
			// console.log(employees);
			_employees =  employees.map(function(e){
			    return {name:e.name,
				    id:e.number,
				    shop:e.shop_id,
				    state: e.state,
				    py:diablo_pinyin(e.name)}
			}); 
			set_storage(cookie, "employee", _employees); 
			return _employees;
		    });
		} 
	    },

	    // reset_retailer: function(){
	    // 	_retailers = [];
	    // },
	    
	    // get_wretailer: function(){
	    // 	if (_retailers.length !== 0 ){
	    // 	    return _retailers;
	    // 	} else {
	    // 	    var http = $resource("/wretailer/:operation",
	    // 				 {operation: '@operation'}); 
	    // 	    return http.query(
	    // 		{operation: 'list_w_retailer'}
	    // 	    ).$promise.then(function(retailers){
	    // 		// console.log(retailers); 
	    // 		_retailers =  retailers.map(function(r){
	    // 		    return {name:  r.name,
	    // 			    lname: r.mobile + "，" + r.name,
	    // 			    type:  r.type_id,
	    // 			    score: r.score,
	    // 			    id:r.id,
	    // 			    shop:  r.shop_id,
	    // 			    py:diablo_pinyin(r.name),
	    // 			    balance:r.balance}
	    // 		})

	    // 		return _retailers;
	    // 	    });    
	    // 	},

	    get_sys_wretailer: function(){
		if (_retailers.length !== 0 ){
		    return _retailers;
		} else {
		    var http = $resource("/wretailer/:operation",
					 {operation: '@operation'}); 
		    return http.query(
			{operation: 'list_sys_wretailer'}
		    ).$promise.then(function(retailers){
			// console.log(retailers); 
			_retailers =  retailers.map(function(r){
			    return {id:      r.id,
				    name:    r.name + "," + r.mobile,
				    mobile:  r.mobile,
				    type_id: r.type_id,
				    score:   r.score,
				    shop_id: r.shop_id,
				    py:      r.py,
				    balance: r.balance}
			})

			return _retailers;
		    });    
		} 
	    },

	    get_wretailer_batch:function(retailerIds) {
		var http = $resource("/wretailer/:operation",
				     {operation: '@operation'},
				     {post: {method: 'POST', isArray: true}});
		
		return http.post(
		    {operation:'get_w_retailer_batch'}, {retailer:retailerIds}
		).$promise;// .then(function(retailers){
		//     return retailers.map(function(r){
		// 	return {name:    r.name, 
		// 		id:      r.id,
		// 		type_id: r.type_id,
		// 		score:   r.score,
		// 		shop_id: r.shop_id,
		// 		py:      r.py,
		// 		balance: r.balance} 
		//     })
		// })
	    },

	    add_purchaser_good: function(good){
		return add_purchaser_good(good);
	    },

	    get_good_by_barcode: function(barcode) {
		return get_good_by_barcode(barcode);
	    }, 

	    update_purchaser_good:function(good, image) {
		return update_purchaser_good(good, image);
	    },

	    delete_purchaser_good:function(style_number, brand) {
		return delete_purchaser_good(style_number, brand);
	    },

	    add_purchaser_color: function(color){
		return add_purchaser_color(color);
	    },

	    get_purchaser_good: function(good){
		return get_purchaser_good(good);
	    }, 

	    list_good_std_executive: function() {
		var cached = get_from_storage(cookie, "std_executive");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_good_std_executive().then(function(es){
			set_storage(cookie, "std_executive", es);
			return es;
		    }); 
		}
	    }, 

	    reset_good_std_executive: function() {
		clear_from_storage(cookie, "std_executive");
	    },

	    list_good_safety_category: function() {
		var cached = get_from_storage(cookie, "safety_category");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_good_safety_category().then(function(cs){
			set_storage(cookie, "safety_category", cs);
			return cs;
		    }); 
		}
	    }, 

	    reset_good_safety_category: function() {
		clear_from_storage(cookie, "safety_category");
	    },

	    list_good_fabric: function() {
		var cached = get_from_storage(cookie, "fabric");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_good_fabric().then(function(fabrics){
			var _fabrics = fabrics.map(function(f) {
			    return {id:f.id, name:f.name, py:diablo_pinyin(f.name)};
			});
			set_storage(cookie, "fabric", _fabrics);
			return _fabrics;
		    }); 
		}
	    }, 

	    reset_good_fabric: function() {
		clear_from_storage(cookie, "fabric");
	    },

	    list_good_ctype: function() {
		var cached = get_from_storage(cookie, "ctype");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_good_ctype().then(function(ctypes){
			var _ctypes = ctypes.map(function(c) {
			    return {id:c.id, name:c.name, py:diablo_pinyin(c.name)};
			});
			set_storage(cookie, "ctype", _ctypes);
			return _ctypes;
		    }); 
		}
	    }, 

	    reset_good_ctype: function() {
		clear_from_storage(cookie, "ctype");
	    },

	    list_good_size_spec: function() {
		var cached = get_from_storage(cookie, "size_spec");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_good_size_spec().then(function(specs){
			set_storage(cookie, "size_spec", specs);
			return specs;
		    }); 
		}
	    }, 

	    reset_good_size_spec: function() {
		clear_from_storage(cookie, "size_spec");
	    },

	    list_print_template: function() {
		var cached = get_from_storage(cookie, "p_template");
		if (angular.isArray(cached) && cached.length !== 0){
		    return cached;
		} else {
		    return list_print_template().then(function(t){
			console.log(t);
			set_storage(cookie, "p_template", t);
			return t;
		    }); 
		}
	    },

	    reset_print_template: function() {
		clear_from_storage(cookie, "p_template");
	    },

	    pay_scan: function(shop, pay_type, pay_code, balance) {
		return _wsaleHttp.save(
		    {operation:"w_pay_scan"},
		    {shop:shop, type:pay_type, code:pay_code, balance:balance}).$promise;
	    },

	    filter_pay_scan: function(match, fields, currentPage, itemsPerpage) {
		return _wsaleHttp.save(
		    {operation:"filter_w_pay_scan"},
		    {match:  angular.isDefined(match) ? match.op : undefined,
		     fields: fields,
		     page:   currentPage,
		     count:  itemsPerpage}).$promise;
	    },

	    check_pay_scan:function(pay_order, shop) {
		return _wsaleHttp.save(
		    {operation:"check_w_pay_scan"}, {pay_order:pay_order, shop:shop}).$promise;
	    }
	    
	    // 
	}
    }
};


var diabloNormalFilterApp = angular.module("diabloNormalFilterApp", [], function($provide){
    $provide.provider('diabloNormalFilter', normalFilterProvider)
});


function normalFilterProvider(){

    var _retailers      = [];
    var _employees      = [];
    var _baseSettings   = [];
    var _promotions     = [];
    var _shopPromotions = [];

    var _charges        = [];
    var _shopCharges    = [];
    var _scores         = [];

    var _cards          = [];
    var _shops          = [];
    var _departments    = [];

    var _sysbsalers     = [];

    
    this.$get = function($resource){
	var _employeeHttp =
	    $resource("/employ/:operation", {operation: '@operation'});
	var _retailerHttp =
	    $resource("/wretailer/:operation", {operation: '@operation'}); 
	var _baseHttp =
	    $resource("/wbase/:operation", {operation: '@operation'});
	var _invHttp  =
	    $resource("/purchaser/:operation",
		      {operation:'@operation'}, {post_get: {method: 'POST', isArray: true}}); 
	var _goodHttp = $resource("/wgood/:operation/:id", {operation: '@operation'});

	var _shopHttp = $resource("/shop/:operation", {operation: '@operation'});

	var _bsaleHttp = $resource("/bsale/:operation/:id", {operation: '@operation', id: '@id'});

	var cookie = 'filter-' + diablo_get_cookie("qzg_dyty_session");

	return{
	    match_all_w_inventory: function(condition){
		return _invHttp.post_get(
		    {operation: 'match_all_w_inventory'}, condition)
	    }, 
	    
	    get_employee: function(){
		var cached = get_from_storage(cookie, "employee");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		else {
		    return _employeeHttp.query(
			{operation: 'list_employe'}
		    ).$promise.then(function(employees){
			// console.log(employees);
			_employees = employees.map(function(e){
			    return {name:e.name,
				    shop:e.shop_id,
				    id:e.number,
				    state: e.state,
				    py:diablo_pinyin(e.name)}
			});
			set_storage(cookie, "employee", _employees);
			return _employees;
		    });   
		} 
	    },

	    get_department:function() {
		var cached = get_from_storage(cookie, "department");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		else {
		    return _employeeHttp.query({operation: 'list_department'}).$promise.then(function(departments){
			_departments = departments.map(function(d){
			    return {id:d.id,
				    name:d.name,
				    py:diablo_pinyin(d.name),
				    master_id: d.master_id};
			});
			set_storage(cookie, "department", _departments);
			return _departments;
		    });   
		} 
	    },

	    get_sys_bsaler:function() {
		var cached = get_from_storage(cookie, "sysbsaler");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		else {
		    return _bsaleHttp.query({operation: 'list_sys_bsaler'}).$promise.then(function(ss){
			_sysbsalers = ss.map(function(s){
			    return {id:      s.id,
				    name:    s.name,
				    type_id: s.type_id,
				    shop_id: s.shop_id};
			});
			set_storage(cookie, "sysbsaler", _sysbsalers);
			return _sysbsalers;
		    });   
		} 
	    },

	    reset_retailer: function(){
		_retailers = [];
	    },
	    
	    get_wretailer: function(){
		if (_retailers.length !== 0){
		    return _retailers;
		} else {
		    return _retailerHttp.query(
			{operation: 'list_w_retailer'}
		    ).$promise.then(function(retailers){
			// console.log(retailers);
			_retailers = retailers.map(function(r){
			    return {name:r.name,
				    id:r.id,
				    py:diablo_pinyin(r.name),
				    balance:r.balance,
				    shop: r.shop_id,
				    type: r.type_id}
			    });
			return _retailers;
		    });
		} 
	    }, 

	    get_repo: function(){
		return _shopHttp.query({operation: "list_repo"}).$promise.then(function(repo){
		    console.log(repo);
		    return repo.map(function(r){
			return {name: r.name,
				id:r.id, py:diablo_pinyin(r.name)};
		    })
		});
	    },

	    get_region: function(){
		var cached = get_from_storage(cookie, "region");
		if (angular.isDefined(cached) && angular.isArray(cached)) return cached;
		else {
		    return _shopHttp.query({operation: "list_region"}).$promise.then(function(regions){
			// console.log(regions);
			var rs =  regions.map(function(r){
			    return {id:r.id, name: r.name, department_id:r.department_id};
			});
			
			set_storage(cookie, "region", rs);
			return rs;
		    })
		}
	    },
	    
	    get_base_setting: function(){
		var cached = get_from_storage(cookie, "base_setting");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		// if (_baseSettings.length !== 0 ){
		//     return _baseSettings;
		// }
		else {
		    return _baseHttp.query(
			{operation: "list_base_setting"}
		    ).$promise.then(function(ss){
			// console.log(ss);
			_baseSettings = ss.map(function(s){
			    return {name:s.ename, value:s.value, shop:s.shop}; 
			});
			set_storage(cookie, "base_setting", _baseSettings);
			return _baseSettings;
		    })
		}
		
	    },

	    get_card: function(){
		if (_cards.length !== 0){
		    return _cards;
		} else {
		    return _baseHttp.query(
			{operation: "list_w_bank_card"}
		    ).$promise.then(function(cs){
			console.log(cs);
			_cards = cs.map(function(c){
			    return {id:c.id, name:c.name, bank:c.bank, no:c.no, type:c.type};
			});
			return _cards;
		    })
		}
	    },

	    get_promotion: function(){
		// console.log("get promotion");
		var cached = get_from_storage(cookie, "promotion");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		// if (_promotions.length !== 0){
		//     return _promotions;
		// } 
		else {
		    return _goodHttp.query({operation: 'list_w_promotion'}).$promise.then(
			function(ps){
			    // console.log(ps);
			    _promotions = ps.map(function(p){
				return {
				    id:       p.id,
				    name:     p.name,
				    rule_id:  p.rule_id,
				    discount: p.discount,
				    cmoney:   p.cmoney,
				    rmoney:   p.rmoney,
				    sdate:    p.sdate,
				    edate:    p.edate
				}
			    });
			    set_storage(cookie, "promotion", _promotions); 
			    return _promotions;
		    })
		}
		
	    },

	    get_shop_promotion: function(){
		if (_shopPromotions.length !== 0){
		    return _shopPromotions;
		} else {
		    return _shopHttp.query(
			{operation:'list_shop_promotion'}
		    ).$promise.then(function(ps){
			_shopPromotions = ps.map(function(p){
			    return {
				id:       p.id,
				shop_id:  p.shop_id,
				pid:      p.pid,
				entry:    p.entry
			    }
			});

			return _shopPromotions;
		    });
		}
	    },


	    reset_charge: function() {
		clear_from_storage(cookie, "recharge");
	    },
	    
	    get_charge: function(){
		var cached = get_from_storage(cookie, "recharge");
		if (angular.isArray(cached) && cached.length !== 0) return cached;
		
		// if (_charges.length !== 0){
		//     return _charges;
		// }
		else {
		    return _retailerHttp.query(
			{operation: 'list_w_retailer_charge'}
		    ).$promise.then(function(cs){
			// console.log(cs);
			_charges = cs.map(function(c){
			    return {
				id:        c.id,
				name:      c.name,
				rule_id:   c.rule_id,
				xtime:     c.xtime,
				xdiscount: c.xdiscount,
				ctime:     c.ctime,
				charge:    c.charge,
				balance:   c.balance,
				type:      c.type,
				sdate:     c.sdate,
				edate:     c.edate,
				deleted:   c.deleted
			    }
			});

			set_storage(cookie, "recharge", _charges);
			return _charges;
		    })
		}
		
	    },

	    get_shop: function(){
		var cached = get_from_storage(cookie, "shop");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
                // if (_shops.length !== 0){
                //     return _shops;
                // }
		else {
                    return _shopHttp.query({operation: "list_shop"}).$promise.then(function(shops){
                        // console.log(shops);
                        _shops = shops.map(function(s){
                            return {id: s.id,
                                    name:s.name,
                                    // repo: s.repo,
				    type: s.type,
				    deleted: s.deleted,
                                    py:diablo_pinyin(s.name)};
                        });
			set_storage(cookie, "shop", _shops)
                        return _shops;

                    })
                }
            }, 

	    get_score: function(){
		var cached = get_from_storage(cookie, "score");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		// if (_scores.length !== 0){
		//     return _scores;
		// }
		else {
		    return _retailerHttp.query(
			{operation: 'list_w_retailer_score'}
		    ).$promise.then(function(ss){
			_scores = ss.map(function(s){
			    return {
				id:       s.id,
				name:     s.name,
				balance:  s.balance,
				score:    s.score,
				type_id:  s.type_id,
				sdate:    s.sdate,
				edate:    s.edate
			    }
			});

			set_storage(cookie, "score", _scores);
			return _scores;
		    })
		}
		
	    }

	    //
	}
    }
};

