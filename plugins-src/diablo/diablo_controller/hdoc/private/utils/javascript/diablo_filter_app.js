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
    // var _chargs      = [];
    // var _scores      = [];

    this.$get = function($resource, dateFilter){
	var resource = $resource(
	    "/purchaser/:operation", {operation: '@operation'},
	    {query_by_post: {method: 'POST', isArray:true}});

	var _goodHttp = $resource("/wgood/:operation/:id", {operation: '@operation', id:'@id'},
				  {query_by_post: {method: 'POST', isArray: true}});

	var _retailerHttp = $resource("/wretailer/:operation/:id",
				      {operation: '@operation', id:'@id'},
				      {post: {method: 'POST', isArray: true}}
				     );

	var _wsaleHttp = $resource("/wsale/:operation/:id",
    				   {operation: '@operation', id: '@id'},
				   {
				       query_by_post: {method: 'POST', isArray: true}
				   });
	
	var cookie = 'filter-' + diablo_get_cookie("qzg_dyty_session");

	function list_w_promotion() {
	    return _goodHttp.query({operation: 'list_w_promotion'}).$promise;
	};

	function list_purchaser_firm() {
	    return _goodHttp.query({operation: "list_supplier"}).$promise;
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

	function add_purchaser_color(color){
	    return _goodHttp.save(
		{operation: "new_w_color"},
		{name: color.name, type: color.type, remark: color.remark}).$promise;
	};

	function get_purchaser_good(good){
	    return _goodHttp.save({operation: "get_w_good"}, good).$promise;
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
		} else if (name === 'has_pay'){
		    _filter.fields.push({name:"has_pay", chinese:"实付查询"});
		    _prompt.has_pay = promptValues;
		} else if (name === 'card'){
		    _filter.fields.push({name:"card", chinese:"银行卡号"});
		    _prompt.cards = promptValues;
		} else if (name === 'discount'){
		    _filter.fields.push({name:"discount", chinese:"折扣"});
		    // _prompt.rsn = promptValues;
		}else if (name === 'tag_price'){
		    _filter.fields.push({name:"tag_price", chinese:"吊牌价"});
		    // _prompt.rsn = promptValues;
		} else if (name === 'check_state'){
		    _filter.fields.push({name:"check_state", chinese:"审核状态"});
		    _prompt.check_state = promptValues;
		} else if(name === 'fshop'){
		    _filter.fields.push({name:"fshop", chinese:"店铺"});
		    _prompt.fshop = promptValues;
		} else if(name === 'tshop'){
		    _filter.fields.push({name:"tshop", chinese:"店铺"});
		    _prompt.tshop = promptValues;
		} else if(name === 'month'){
		    _filter.fields.push({name:"month", chinese:"月份"});
		    _prompt.month = promptValues;
		} else if(name === 'region'){
		    _filter.fields.push({name:"region", chinese:"区域"});
		    _prompt.region = promptValues;
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
		    if (angular.isDefined(f.value) && f.value){
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
			    g, {name:g.style_number + "，" + g.brand + "，" + g.type})
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
	    
	    match_w_query_inventory:function(viewValue, Shop){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, type:1})
		    .$promise.then(function(invs){
			console.log(invs);
			return invs.map(function(inv){
			    return inv.style_number;
			})
		    })
	    },

	    match_w_reject_inventory: function(viewValue, shop, firm){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:firm, type:1})
		    .$promise.then(function(invs){
			console.log(invs);
			return invs.map(function(inv){
			    var name = inv.style_number + "，"
				+ inv.brand + "，"
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
				    inv,
				    {name:inv.style_number + "，" + inv.brand + "，" + inv.type})
			    })
			}
		    })
	    },

	    match_w_fix: function(viewValue, shop){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:[]})
		    .$promise.then(function(invs){
			// console.log(invs);
			return invs.map(function(inv){
			    return angular.extend(
				inv, {name:inv.style_number + "，" + inv.brand + "，" + inv.type})
			})
		    })
	    },

	    match_w_sale: function(viewValue, shop){
		return resource.query_by_post(
		    {operation:'match_w_inventory'}, {prompt:viewValue, shop:shop, firm:[]}
		).$promise.then(function(invs){
		    return invs.map(function(inv){
			return angular.extend(
			    inv, {name:inv.style_number
				  + "，" + inv.brand + "，" + inv.type})
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

	    match_retailer_phone:function(viewValue, mode) {
		var http = $resource("/wretailer/:operation",
				     {operation: '@operation'},
				     {post: {method: 'POST', isArray: true}});
		
		return http.post({operation:'match_retailer_phone'},
				 {prompt:viewValue, mode:mode})
		    .$promise.then(function(phones){
			// console.log(phones);
			return phones.map(function(r){
			    return {id:      r.id,
				    name:    r.name+ "," + r.mobile, 
				    mobile:  r.mobile,
				    type_id: r.type_id,
				    score:   r.score,
				    shop_id: r.shop_id,
				    draw_id: r.draw_id,
				    py:      r.py,
				    balance: r.balance} 
			})
		    })
	    }, 

	    check_retailer_password: function(retailerId, password){
		return _retailerHttp.save(
		    {operation: "check_w_retailer_password"},
		    {id:retailerId, password:password}).$promise;
	    },

	    get_ticket_by_batch: function(batchNo){
		return _retailerHttp.save(
		    {operation: "get_w_retailer_ticket"}, {batch:batchNo, mode:1}).$promise;
	    },

	    get_ticket_by_retailer: function(retailerId){
		return _retailerHttp.save(
		    {operation: "get_w_retailer_ticket"}, {retailer:retailerId, mode:0}).$promise;
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
		    		    name:b.name,
		    		    py:diablo_pinyin(b.name),
		    		    // firm: supplier,
		    		    firm_id: b.supplier_id,
		    		    // remark: b.remark,
		    		    // entry: b.entry
		    		   };
		    	})
			set_storage(cookie, "brand", _brands)
		    	return _brands;
		    });    
		}
		// if (_brands.length !== 0 ){
		//     // console.log("cache brands");
		//     return _brands;
		// } else {
		//     return wgoodService.list_purchaser_brand(
		//     ).then(function(brands){
		// 	// console.log(brands);
		// 	_brands =  brands.map(function(b){
		// 	    return {id: b.id,
		// 		    name:b.name,
		// 		    py:diablo_pinyin(b.name),
		// 		    // firm: supplier,
		// 		    firm_id: b.supplier_id,
		// 		    // remark: b.remark,
		// 		    // entry: b.entry
		// 		   };
		// 	})

		// 	return _brands;
		//     });    
		// }
		
	    },

	    reset_type: function(){
		_types = [];
	    },
	    
	    get_type: function(){
		if (_types.length !== 0){
		    return _types;
		} else {
		    return list_purchaser_type(
		    ).then(function(types){
			// console.log(types);
			_types =  types.map(function(t){
			    return {id: t.id,
				    name:t.name, py:diablo_pinyin(t.name)};
			})

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
				    name:c.name,
				    tid:c.tid,
				    type:c.type}
			});
			set_storage(cookie, "color", _colors)
			return _colors;
		    })
		}
		// if (_colors.length !== 0){
		//     // console.log("cache color");
		//     return _colors;
		// } else {
		//     return wgoodService.list_purchaser_color(
		//     ).then(function(colors){
		// 	// console.log(colors);
		// 	_colors = colors.map(function(c){
		// 	    return {id:c.id,
		// 		    name:c.name,
		// 		    tid:c.tid,
		// 		    type:c.type}
		// 	});

		// 	return _colors;
		//     })   
		// } 
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
		// if (_color_types.length !== 0){
		//     return _color_types;
		// } else {
		//     return wgoodService.list_color_type().then(function(types){
		// 	return types;
		//     }); 
		// } 
	    },

	    get_size_group: function(){
		var cached = get_from_storage(cookie, "size");
		if (angular.isDefined(cached) && angular.isArray(cached)) return cached;
		// if (_size_groups.length !== 0){
		//     return _size_groups;
		// }
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

	    reset_promotion: function(){
		_promotions = [];
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

	    reset_retailer: function(){
		_retailers = [];
	    },
	    
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

	    add_purchaser_color: function(color){
		return add_purchaser_color(color);
	    },

	    get_purchaser_good: function(good){
		return get_purchaser_good(good);
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

    
    this.$get = function($resource){
	var _employeeHttp =
	    $resource("/employ/:operation", {operation: '@operation'});
	var _retailerHttp =
	    $resource("/wretailer/:operation", {operation: '@operation'}); 
	var _baseHttp =
	    $resource("/wbase/:operation", {operation: '@operation'});
	var _invHttp  =
	    $resource("/purchaser/:operation",
		      {operation:'@operation'},
		      {
			  post_get: {method: 'POST', isArray: true}
		      }); 
	var _goodHttp =
	    $resource("/wgood/:operation/:id", {operation: '@operation'});

	var _shopHttp =
	    $resource("/shop/:operation", {operation: '@operation'});

	var cookie = 'filter-' + diablo_get_cookie("qzg_dyty_session");

	return{
	    match_all_w_inventory: function(condition){
		return _invHttp.post_get(
		    {operation: 'match_all_w_inventory'}, condition)
	    }, 
	    
	    get_employee: function(){
		var cached = get_from_storage(cookie, "employee");
		if (angular.isArray(cached) && cached.length !== 0) return cached; 
		// if (_employees.length !== 0){
		//     return _employees;
		// }
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
		    return _shopHttp.query({operation: "list_region"}).$promise.then(function(
			regions){
			// console.log(regions);
			var rs =  regions.map(function(r){
			    return {name: r.name, id:r.id};
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
			_cards = cs.map(function(c){
			    return {id:c.id, name:c.name, bank:c.bank, no:c.no};
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
				id:       c.id,
				name:     c.name,
				charge:   c.charge,
				balance:  c.balance,
				type:     c.type,
				sdate:    c.sdate,
				edate:    c.edate,
				deleted:  c.deleted
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
                    return _shopHttp.query(
                        {operation: "list_shop"}
                    ).$promise.then(function(shops){
                        // console.log(shops);
                        _shops = shops.map(function(s){
                            return {id: s.id,
                                    name:s.name,
                                    repo: s.repo,
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

