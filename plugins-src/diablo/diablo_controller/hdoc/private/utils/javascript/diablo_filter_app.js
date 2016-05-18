var diabloFilterApp = angular.module("diabloFilterApp", [], function($provide){
    $provide.provider('diabloFilter', filterProvider)
});


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
    
    
    this.$get = function($resource, dateFilter, wgoodService){
	var resource = $resource(
	    "/purchaser/:operation", {operation: '@operation'},
	    {query_by_post: {method: 'POST', isArray:true}});

	return{
	    default_time: function(start){
		var now = $.now();
		if (angular.isUndefined(start)){
		    return {start_time: now - diablo_day_millisecond * 30,
			    end_time: now}; 
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
		} else if (name === 'year'){
		    _filter.fields.push({name:"year", chinese:"年度"});
		    _prompt.year = promptValues;
		}

		else if (name === 'rsn'){
		    _filter.fields.push({name:"rsn", chinese:"单号"});
		    // _prompt.rsn = promptValues;
		} else if(name === 'shop'){
		    _filter.fields.push({name:"shop", chinese:"店铺"});
		    _prompt.shop = promptValues;
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
			var value = typeof(f.value) === 'object' ? f.value.id : f.value;
			
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

		
		search.start_time =
		    diablo_filter_time(time.start_time, 0, dateFilter); 
		search.end_time   =
		    diablo_filter_time(time.end_time, 1, dateFilter);
		console.log(search);

		return callback(search);
	    },
	    
	    match_style_number: function(viewValue){
		return wgoodService.match_purchaser_style_number(
		    viewValue
		).then(function(result){
		    // console.log(result);
		    return result.map(function(s){
			return s.style_number;
		    }) 
		})
	    },

	    match_wgood_with_firm: function(viewValue, firm){
		return wgoodService.match_purchaser_good_with_firm(
		    viewValue, firm
		).then(function(goods){
		    // console.log(goods); 
		    return goods.map(function(g){
			return angular.extend(
			    g, {name:g.style_number
				+ "，" + g.brand + "，" + g.type})
		    })
		})
	    },

	    match_all_w_good: function(start_time, firm){
		return wgoodService.match_all_purchaser_good(
		    start_time, firm);
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
			console.log(invs);
			if (angular.isUndefined(firm)){
			    return invs.map(function(inv){
				return inv.style_number;
			    })
			} else{
			    return invs.map(function(inv){
				return angular.extend(
				    inv,
				    {name:inv.style_number
				     + "，" + inv.brand + "，" + inv.type})
			    })
			}
		    })
	    },

	    match_w_fix: function(viewValue, shop){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:[]})
		    .$promise.then(function(invs){
			console.log(invs);
			return invs.map(function(inv){
			    return angular.extend(
				inv, {name:inv.style_number
				      + "，" + inv.brand + "，" + inv.type})
			})
		    })
	    },

	    match_w_sale: function(viewValue, shop){
		return resource.query_by_post(
		    {operation:'match_w_inventory'},
		    {prompt:viewValue, shop:shop, firm:[]})
		    .$promise.then(function(invs){
			console.log(invs);
			return invs.map(function(inv){
			    return angular.extend(
				inv, {name:inv.style_number
				      + "，" + inv.brand + "，" + inv.type})
			})
		    })
	    }, 

	    reset_firm: function(){
		_firms = [];
	    },
	    
	    get_firm: function(){
		if (_firms.length !== 0 ){
		    // console.log("cache");
		    return _firms;
		} else {
		    return wgoodService.list_purchaser_firm(
		    ).then(function(firms){
			// console.log(firms); 
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
		_brands = [];
	    },
	    
	    get_brand: function(){
		if (_brands.length !== 0 ){
		    // console.log("cache brands");
		    return _brands;
		} else {
		    return wgoodService.list_purchaser_brand(
		    ).then(function(brands){
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

			return _brands;
		    });    
		}
		
	    },

	    reset_type: function(){
		_types = [];
	    },
	    
	    get_type: function(){
		if (_types.length !== 0){
		    return _types;
		} else {
		    return wgoodService.list_purchaser_type(
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
		_colors = [];
	    },
	    
	    get_color: function(){
		if (_colors.length !== 0){
		    // console.log("cache color");
		    return _colors;
		} else {
		    return wgoodService.list_purchaser_color(
		    ).then(function(colors){
			// console.log(colors);
			_colors = colors.map(function(c){
			    return {id:c.id,
				    name:c.name,
				    tid:c.tid,
				    type:c.type}
			});

			return _colors;
		    })   
		} 
	    },

	    get_color_type: function(){
		if (_color_types.length !== 0){
		    return _color_types;
		} else {
		    return wgoodService.list_color_type().then(function(types){
			return types;
		    }); 
		} 
	    },

	    get_size_group: function(){
		if (_size_groups.length !== 0){
		    return _size_groups;
		} else {
		    return wgoodService.list_purchaser_size().then(
			function(sizes){
			    // console.log(sizes);
			    return sizes.map(function(s){
				return diablo_obj_strip(s);
			    })
			});
		}
	    },

	    reset_promotion: function(){
		_promotions = [];
	    },
	    
	    get_promotion: function(){
		if (_promotions.length !== 0){
		    return _promotions;
		} else {
		    return wgoodService.list_w_promotion().then(function(
			promotions
		    ){
			console.log(promotions);
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

			return _promotions;
		    }) 
		}
	    },

	    get_employee: function(){
		if (_employees.length !== 0){
		    return _employees;
		} else {
		    var http = $resource(
			"/employ/:operation", {operation: '@operation'});
		    
		    return http.query(
			{operation: 'list_employe'}
		    ).$promise.then(function(employees){
			// console.log(employees);
			_employees =  employees.map(function(e){
			    return {name:e.name,
				    id:e.number,
				    py:diablo_pinyin(e.name)}
			});

			return _employees;
		    });
		} 
	    },

	    get_wretailer: function(){
		if (_retailers.length !== 0 ){
		    return _retailers;
		} else {
		    var http =
			$resource("/wretailer/:operation",
				  {operation: '@operation'});
		    
		    return http.query(
			{operation: 'list_w_retailer'}
		    ).$promise.then(function(retailers){
			console.log(retailers); 
			_retailers =  retailers.map(function(r){
			    return {name:r.name,
				    lname: r.mobile + "，" + r.name,
				    type_id: r.type_id,
				    score: r.score,
				    id:r.id,
				    py:diablo_pinyin(r.name), 
				    balance:r.balance}
			})

			return _retailers;
		    });    
		}
		
	    }
	    
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

	return{
	    match_all_w_inventory: function(condition){
		return _invHttp.post_get(
		    {operation: 'match_all_w_inventory'}, condition)
	    }, 
	    
	    get_employee: function(){
		if (_employees.length !== 0){
		    return _employees;
		} else {
		    return _employeeHttp.query(
			{operation: 'list_employe'}
		    ).$promise.then(function(employees){
			// console.log(employees);
			_employees = employees.map(function(e){
			    return {name:e.name,
				    id:e.number, py:diablo_pinyin(e.name)}
			});

			return _employees;
		    });   
		} 
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
				    cid: r.cid,
				    pid: r.pid}
			    });
			return _retailers;
		    });
		} 
	    }, 

	    get_repo: function(){
		return _shopHttp.query(
		    {operation: "list_repo"}
		).$promise.then(function(repo){
		    console.log(repo);
		    return repo.map(function(r){
			return {name: r.name,
				id:r.id, py:diablo_pinyin(r.name)};
		    })
		});
	    },
	    
	    get_base_setting: function(){
		if (_baseSettings.length !== 0 ){
		    return _baseSettings;
		} else {
		    return _baseHttp.query(
			{operation: "list_base_setting"}
		    ).$promise.then(function(ss){
			_baseSettings = ss.map(function(s){
			    return {name:s.ename, value:s.value, shop:s.shop}; 
			});
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
		if (_promotions.length !== 0){
		    return _promotions;
		} else {
		    return _goodHttp.query(
			{operation: 'list_w_promotion'}
		    ).$promise.then(function(ps){
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


	    get_charge: function(){
		if (_charges.length !== 0){
		    return _charges;
		} else {
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
				sdate:    c.sdate,
				edate:    c.edate
			    }
			});

			return _charges;
		    })
		}
		
	    },

	    get_shop: function(){
                if (_shops.length !== 0){
                    return _shops;
                } else {
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

                        return _shops;

                    })
                }
            }, 

	    get_score: function(){
		if (_scores.length !== 0){
		    return _scores;
		} else {
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

			return _scores;
		    })
		}
		
	    }

	    //
	}
    }
};

