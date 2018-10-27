'use strict'

function wgoodNewCtrlProvide(
    $scope, $timeout, diabloPattern, diabloUtilsService, diabloFilter,
    wgoodService, filterPromotion, filterFirm, filterBrand,
    filterType, filterSizeGroup,
    filterStdExecutive, filterCategory, filterFabric, filterTemplate, user, base) {
    // console.log(filterPromotion);
    $scope.promotions = filterPromotion;
    
    $scope.seasons    = diablo_season2objects;
    $scope.full_years = diablo_full_year; 
    $scope.sexs       = diablo_sex2object;
    $scope.std_units  = diablo_std_units;

    // use to print tag
    $scope.levels         = [1,2,3];
    $scope.std_executives = filterStdExecutive;
    $scope.categories     = filterCategory;
    $scope.fabrics        = filterFabric;
    // $scope.template       = filterTemplate.length!==0 ? filterTemplate[0] : undefined;

    // console.log($scope.fabrics);
    
    $scope.pattern = {
	style_number: diabloPattern.style_number,
	brand:        diabloPattern.ch_en_num,
	type:         diabloPattern.good_type,
	discount:     diabloPattern.discount,
	price:        diabloPattern.positive_decimal_2,
	percent:      diabloPattern.percent,
	expire:       diabloPattern.expire_date
    };

    var dialog     = diabloUtilsService;
    var set_float  = diablo_set_float;
    
    var hide_mode  = stockUtils.stock_in_hide_mode(diablo_default_shop, base); 
    $scope.base_settings = {m_sgroup :stockUtils.multi_sizegroup(-1, base)};
    angular.extend($scope.base_settings, hide_mode); 
    console.log($scope.base_settings);

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenStockRight();
    
    // $scope.colors = [{type:"红色", tid:1
    // 		  colors:[{name:"深红", id:1},
    // 			  {name:"粉红", id:2}]},
    // 		 {type:"蓝色", tid:2
    // 		  colors:[{name:"深蓝", id:3},
    // 			  {name:"浅蓝", id:4}]}, 
    
    // 		];

    // brands
    $scope.brands = angular.copy(filterBrand); 
    var get_brand = function(brand_name){
	for (var i=0, l=$scope.brands.length; i<l; i++){
	    if (brand_name === $scope.brands[i].name){
		return $scope.brands[i];
	    }
	}

	return undefined;
    };

    // firm
    $scope.firms = angular.copy(filterFirm);
    
    // type
    $scope.types = angular.copy(filterType);
    
    $scope.refresh_type = function(){
	$scope.types = wgoodService.list_purchaser_type().then(
	    function(types){
		return types.map(function(t){
		    return {id: t.id, name:t.name, py:diablo_pinyin(t.name)};
		})
	    });
    };

    $scope.is_same_good = false; 
    var timeout_brand = undefined;
    $scope.$watch("good.brand", function(newValue, oldValue){
	if(angular.isUndefined(newValue)
	   || angular.equals(newValue, oldValue)){
	    return;
	}

	$timeout.cancel(timeout_brand);
	timeout_brand = $timeout(function(){
	    // console.log(newValue, oldValue); 
	    check_same_good($scope.good.style_number, newValue);
	}, diablo_delay_300ms) 
    });
    
    // color
    $scope.colors = [];
    wgoodService.list_purchaser_color().then(function(colors){
	// console.log(colors); 
	angular.forEach(colors, function(color){
	    $scope.colors.push({id:color.id, name:color.name, py:diablo_pinyin(color.name)}); 
	});

	$scope.group_color_with_8();
	// console.log($scope.colors);
    });
    
    wgoodService.list_color_type().then(function(data){
    	// console.log(data);
    	$scope.colorTypes = data;
    });

    var max_color = diablo_max_color_per_line;
    var color_range = [0].concat(diablo_range(max_color - 1));
    $scope.group_color_with_8 = function(){
	var color = {};
	$scope.grouped_colors = [];
	for (var i=0, g=0, l=$scope.colors.length; i<l; i++){
	    var gc = $scope.colors[i];
	    var add_color = {id:gc.id, name:gc.name, py:diablo_pinyin(gc.name)};
	    if (gc.select) {
		add_color.select = true;
		add_color.disabled = true; 
	    };
	    
	    if (i <= (g+1)*max_color - 1){
		color[(i - g * max_color).toString()] = add_color;
	    } 
	    if (i === (g+1) * max_color){
		$scope.grouped_colors.push(color);
		g++;
		color = {};
		color[(i - g * max_color).toString()] = add_color;
	    }
	} 
	$scope.grouped_colors.push(color);
	// console.log($scope.grouped_colors);
    };
    
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		console.log(state);

		var append_color = function(newColorId){
		    $scope.colors.push({
			id:newColorId,
			name:params.color.name,
			py:diablo_pinyin(params.color.name)
		    });

		    $scope.group_color_with_8();
		    // console.log($scope.colors); 
		    // reset filter color
		    diabloFilter.reset_color();
		}; 
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){
			    append_color(state.id);
			    // diabloFilter.reset_color();
			});
		    
		} else{
		    dialog.response(
			false, "新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html', undefined, callback,
	    $scope, {color: {types: $scope.colorTypes}})
    }

    $scope.select_color = function(){
	var callback = function(params){
	    // console.log(params.colors);
	    // console.log(params.ucolors); 
	    $scope.selectColors = [];
	    $scope.good.colors="";
	    for (var i=0, l1=params.colors.length; i<l1; i++){
		for (var j in params.colors[i]){
		    var c = params.colors[i][j];
		    if(c.select){
			$scope.good.colors += c.name + "；";
			$scope.selectColors.push(angular.copy(c));
		    }
		}
	    }
	    
	    console.log($scope.selectColors); 
	    $scope.grouped_colors = angular.copy(params.colors);
	}; 

	var on_select_ucolor = function(item, model, label){
	    model.select = true; 
	};
	
	dialog.edit_with_modal(
	    "select-color.html",
	    'lg',
	    callback,
	    undefined,
	    {colors:$scope.grouped_colors,
	     color_range:color_range,
	     ucolors: function(){
		 var ucolors = [];
		 for (var i=0, l1=$scope.grouped_colors.length; i<l1; i++){
		     for (var j in $scope.grouped_colors[i]){
			 ucolors.push($scope.grouped_colors[i][j]); 
		     }
		 } 
		 return ucolors;
	     }(),
	     on_select_ucolor: on_select_ucolor});
    };

    /*
     * size group
     */
    $scope.groups = angular.copy(filterSizeGroup); 
    $scope.new_size = function(){
	var valid_group = function(size){
	    var all_size = [];
	    for (var s in size){
		if (s === 'name') continue;

		if (angular.isDefined(size[s]) && size[s]){
		    // same size in group
		    if (in_array(all_size, size[s])){
			return false;
		    } else{
			all_size.push(size[s]);
		    }
		}
	    }

	    // at lest one size was input 
	    return all_size.length === 0 ? false : true;
	};

	var check_same = function(size, key, value){
	    // console.log(size, key, value);
	    for (var s in size){
		if (s === 'name' || s === key) continue;

		if (angular.isDefined(size[s])
		    && size[s] && size[s] === value){
		    return false;
		}
	    }

	    return true;
	};
	
	var callback = function(params){
	    console.log(params);
	    var size = {};
	    for (var k in params.size){
		if (angular.isDefined(params.size[k]) && params.size[k]){
		    size[k] = params.size[k]
		}
	    }

	    console.log(size);

	    wgoodService.add_purchaser_size(size).then(function(state){
	        console.log(state);
	        if (state.ecode == 0){
		    var append_size_group = function(gid){
			$scope.groups.push(angular.extend({id:gid}, size));
		    }
		    
		    dialog.response_with_callback(
			true, "新增尺码组", "新增尺码组成功！！", $scope,
			function(){append_size_group(state.id)});
    	    	    
	        } else{
	    	    dialog.response(
	    		false, "尺码组", "新增尺码组失败，原因："
	    		    + wgoodService.error[state.ecode]);
	        }
	    })
	};
	
	dialog.edit_with_modal(
	    'new-size.html', undefined, callback, $scope,
	    {size: {},
	     valid_group: valid_group,
	     check_same:  check_same,
	     pattern: {size: diabloPattern.size}});
    };
    
    
    $scope.select_size = function(){
	var callback = function(params){
	    console.log(params.groups);
	    
	    $scope.selectGroups = [];
	    $scope.good.sizes = "";
	    angular.forEach(params.groups, function(g){
		if (angular.isDefined(g.select) && g.select){
		    $scope.good.sizes += g.name + "；";
		    $scope.selectGroups.push(angular.copy(g));
		}
	    }); 
	    console.log($scope.selectGroups); 
	    $scope.groups = params.groups;
	};

	var select_group = function(groups, g){
	    for(var i=0, l=groups.length; i<l; i++){
		if (groups[i].id !== g.id
		    && diablo_no === $scope.base_settings.m_sgroup){
		    groups[i].select = false;
		}
	    }
	}

	dialog.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.groups, select_group: select_group});
    };

    $scope.delete_image = function(){
	// console.log($scope.image);
	$scope.image = undefined;
    };

    $scope.select_fabric = function() {
	// $scope.selectFabrics = [];

	var callback = function(params) {
	    console.log(params.composites);
	    var cs = params.composites;
	    
	    // check
	    for (var i=0, l=cs.length; i<l; i++) {
		var c = cs[i];
		if ( (angular.isUndefined(c.fabric) && 0 !== stockUtils.to_float(c.percent))
		     || (angular.isDefined(c.fabric) && 0 === stockUtils.to_float(c.percent)) ) {
		    dialog.response(
			false,
			"新增货品",
			"新增货品失败：面料输入不正确，请确保面料从下拉框中选择，面料成份不为零");
		    return;
		}
	    };

	    $scope.good.fabric = cs.filter(function(c) {
		return angular.isDefined(c) && 0 !== stockUtils.to_float(c.percent);
	    });

	    $scope.good.fabric_desc = diablo_empty_string;
	    angular.forEach($scope.good.fabric, function(f) {
		$scope.good.fabric_desc += f.fabric + ":" + f.percent.toString();
	    });

	    // console.log($scope.good.fabric_desc);
	};
	
	dialog.edit_with_modal(
	    "select-fabric.html",
	    undefined,
	    callback,
	    undefined,
	    {composites:$scope.good.fabric,
	     add_composite: function(composites) {
		 composites.push({fabric:undefined, percent:undefined});
	     },
	     delete_composite: function(composites) {
		 composites.splice(-1, 1);
	     },
	     fabrics: $scope.fabrics,
	     p_percent: $scope.pattern.percent
	    });
    };

    /*
     * new good
     */
    var current_month = new Date().getMonth();
    $scope.good = {
	promotion : $scope.promotions.length != 0 ? $scope.promotions[0]:undefined,
	sex       : $scope.sexs[stockUtils.d_sex(-1, base)],
	org_price : 0,
	tag_price : 0,
	ediscount : 100,
	discount  : 100,
	alarm_day : -1,
	year      : diablo_now_year(),
	season    : $scope.seasons[stockUtils.valid_season(current_month)], 
	
	level     : $scope.levels[0],
	executive : $scope.std_executives.length!==0 ? $scope.std_executives[0] : undefined,
	category  : $scope.categories.length!==0 ? $scope.categories[0] : undefined,
	fabric    : [],
	
	unit      : $scope.std_units[0]
    };

    $scope.row_change_tag = function(good){
	good.ediscount = diablo_discount(
	    stockUtils.to_float(good.org_price),
	    stockUtils.to_float(good.tag_price));
    }
    
    $scope.row_change_price = function(good){
	// inv.org_price = stockUtils.to_float(inv.org_price);
	good.ediscount = diablo_discount(
	    stockUtils.to_float(good.org_price),
	    stockUtils.to_float(good.tag_price)); 
    };

    $scope.row_change_ediscount = function(good){
	good.org_price = diablo_price(
	    stockUtils.to_float(good.tag_price),
	    stockUtils.to_float(good.ediscount)); 
    }; 
    
    $scope.new_good = function(){
	console.log($scope.good);
	console.log($scope.image);
	var good = angular.copy($scope.good);
	if (good.hasOwnProperty('fabric_desc')) delete good.fabric_desc;
	
	good.firm      = good.firm.id;
	good.season    = good.season.id;
	good.sex       = good.sex.id;
	good.unit      = $scope.std_units.indexOf(good.unit);
	
	good.executive = stockUtils.invalid_firm(good.executive);
	good.category  = stockUtils.invalid_firm(good.category);
	good.fabric    = function() {
	    if (good.fabric.length !== 0) {
		var cs = good.fabric.map(function(f){
		    return {f:stockUtils.get_object_by_name(f.fabric, $scope.fabrics).id, p:f.percent};
		});
		console.log(cs); 
		return angular.toJson(cs);
	    } else {
		return undefined;
	    }
	}();
	// good.promotion = good.promotion.id;
	
	good.brand = typeof(good.brand) === "object" ? good.brand.name: good.brand; 
	good.type  = typeof(good.type) === "object" ? good.type.name: good.type;
	good.type = diablo_trim(good.type);
	good.type_py = diablo_pinyin(good.type);
	
	good.colors = function(){
	    if (angular.isDefined($scope.selectColors) && $scope.selectColors.length > 0){
		var colors = [];
		angular.forEach($scope.selectColors, function(color){
		    colors.push(color.id)
		});
		return colors;
	    } else{
		return undefined;
	    }
	}();
	
	good.sizes = function(){
	    if (angular.isDefined($scope.selectGroups)
		&& $scope.selectGroups.length > 0){
		var groups = [];
		angular.forEach($scope.selectGroups, function(group){
		    groups.push({id:group.id, group:function(){
			var validSize = [];
			for(var i=0, l=diablo_sizegroup.length; i<l; i++){
	    		    var k = diablo_sizegroup[i];
	    		    if(group[k]){
				validSize.push(group[k]);
			    }
	    		}
			return validSize;
		    }()})
		});
		return groups;
	    } else{
		return undefined;
	    }
	}();
	
	console.log(good);
	var image  = angular.isDefined($scope.image) && $scope.image
	    ? $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "") : undefined;
	
	// console.log(image); 
	wgoodService.add_purchaser_good(good, image).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增货品", "新增货品资料成功！！", $scope,
		    function(){
			// reset color
			$scope.selectColors = [];
			$scope.good.colors=""; 
			angular.forEach($scope.colors, function(color){
			    if (color.select) color.select = false;});

			// console.log($scope.grouped_colors); 
			$scope.good.style_number = undefined;
			$scope.good.type = undefined;
			$scope.goodForm.type.$pristine = true;
			$scope.goodForm.style_number.$pristine = true;

			/*
			 * add prompt
			 */
			var in_prompts = function(prompts, item){
			    for(var i=0, l=prompts.length; i<l; i++){
				if (prompts[i].name === item){
				    return true;
				}
			    };
			    return false;
			};
			
			// brand
			if (!in_prompts($scope.brands, good.brand)){
		    	    $scope.brands.push({
				// id   :$scope.brands.length + 1,
				id   :state.brand,
				name :good.brand,
				py   :diablo_pinyin(good.brand)});
			    diabloFilter.reset_brand(); 
			};
			// console.log($scope.brands);

			// type
			if (!in_prompts($scope.types, good.type)){
		    	    $scope.types.push({
				// id   :$scope.types.length + 1,
				id   :state.type,
				name :good.type,
				py   :good.type_py});

			    diabloFilter.reset_type();
			};
			// console.log($scope.types);
		    });
	    } else{
		dialog.response(
		    false, "新增货品",
		    "新增货品 ["
			+ good.style_number + "-" + good.brand + "-"
			+  good.type + "] 失败："
			+ wgoodService.error[state.ecode]);
	    }
	});
    };

    $scope.reset = function(){
	// $scope.selectGroups = [];
	$scope.selectColors = [];
	$scope.good = {
	    brand:       $scope.good.brand,
	    firm:        $scope.good.firm,
	    sex:         $scope.good.sex,
	    year:        $scope.good.year,
	    season:      $scope.good.season,
	    org_price:   $scope.good.org_price,
	    tag_price:   $scope.good.tag_price, 
	    ediscount:   $scope.good.ediscount,
	    discount:    $scope.good.discount,
	    alarm_day:   $scope.good.alarm_day,
	    sizes:       $scope.good.sizes, 

	    unit:        $scope.good.unit,
	    level:       $scope.good.level,
	    executive:   $scope.good.executive,
	    category:    $scope.good.category,
	    fabric:      $scope.good.fabric,
	    fabric_desc: $scope.good.fabric_desc,
	};
	
	$scope.goodForm.style_number.$pristine = true;
	$scope.goodForm.brand.$pristine = true;
	$scope.goodForm.type.$pristine = true;
	$scope.goodForm.firm.$pristine = true;
	$scope.goodForm.org_price.$pristine = true;
	$scope.goodForm.tag_price.$pristine = true; 
	$scope.goodForm.ediscount.$pristine = true;
	$scope.goodForm.discount.$pristine  = true;
	// $scope.goodForm.alarm.$pristine     = true;
	$scope.image = undefined;
    };
};

function wgoodDetailCtrlProvide(
    $scope, $location, dateFilter, diabloUtilsService,
    diabloPagination, wgoodService, diabloFilter,
    filterPromotion,
    filterBrand,
    filterFirm,
    filterType,
    filterColor,
    filterSizeSpec,
    filterStdExecutive, filterCategory, filterFabric, filterTemplate, base, user){
    console.log(filterSizeSpec);
    // $scope.template = filterTemplate.length !== 0 ? filterTemplate[0] : undefined;
    $scope.shops = user.sortShops;
    
    /*
     * authen
     */
    // console.log(user.right);
    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.right = authen.authenGoodRight(); 

    $scope.setting = {
	use_barcode  :stockUtils.use_barcode(diablo_default_shop, base),
	auto_barcode :stockUtils.auto_barcode(diablo_default_shop, base),
	printer_barcode: stockUtils.printer_barcode(user.loginShop, base),
	dual_barcode: stockUtils.dual_barcode_print(user.loginShop, base),
	
	// hide_expire :function() {
	//     var h = hide_mode.charAt(3);
	//     if ( !h ) return diablo_yes;
	//     else return stockUtils.to_integer(h);
	// }()
	
    };

    var hide_mode  = stockUtils.stock_in_hide_mode(diablo_default_shop, base); 
    angular.extend($scope.setting, hide_mode);

    $scope.templates = filterTemplate;
    $scope.printU = new stockPrintU($scope.setting.auto_barcode, $scope.setting.dual_barcode);
    $scope.printU.setPrinter($scope.setting.printer_barcode);
    // console.log($scope.right);
    /*
     * filter
     */ 
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", diabloFilter.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
    if ($scope.right.show_orgprice) {
	diabloFilter.add_field("org_price", []);
    }
    diabloFilter.add_field("type", filterType);
    diabloFilter.add_field("firm", filterFirm); 
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    var now = $.now();
    $scope.qtime_start = diablo_base_setting(
	"qtime_start", -1, base, diablo_set_date,
	diabloFilter.default_start_time(now));
    
    $scope.time   = diabloFilter.default_time($scope.qtime_start);
    
    // pagination
    $scope.colspan = 15;
    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 15;
    $scope.default_page = 1;

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    wgoodService.filter_purchaser_good(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		    if (page === 1){
			$scope.total_items      = result.total;
		    }
		    angular.forEach(result.data, function(d){
			// console.log(d);
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			d.type  = diablo_get_object(d.type_id, filterType);
			
			d.executive = diablo_get_object(d.executive_id, filterStdExecutive);
			d.category = diablo_get_object(d.category_id, filterCategory);

			d.specs = [];
			if (angular.isObject(d.type) && d.type.cid !== diablo_invalid_index) {
			    angular.forEach(filterSizeSpec, function(s) {
				if (s.cid === d.type.cid) {
				    d.specs.push(s);
				}
			    }) 
			}
			
			if (d.fabric_json) {
			    d.fabrics = angular.fromJson(d.fabric_json);
			    d.fabric_desc = diablo_empty_string;
			    angular.forEach(d.fabrics, function(f) {
				var fabric = diablo_get_object(f.f, filterFabric);
				if (angular.isDefined(fabric) && angular.isObject(fabric))
				    f.name = fabric.name; 
				    d.fabric_desc += fabric.name + ":" + f.p.toString();
			    });
			}

			d.expire_date = diablo_none;
			var expire = diablo_nolimit_day;
			if (d.alarm_day !== diablo_nolimit_day) {
			    expire = stockUtils.to_integer(d.alarm_day);
			} else {
			    if (diablo_invalid_firm !== stockUtils.invalid_firm(d.firm)) {
				if (angular.isDefined(d.firm.expire)
				    && d.firm.expire !== diablo_nolimit_day) {
				    expire = stockUtils.to_integer(d.firm.expire);
				}
			    }
			}

			if (expire !== diablo_nolimit_day) {
			    d.expire_date = stockUtils.date_add(d.entry_date, expire);
			}
		    })
		    $scope.goods = result.data;
		    diablo_order_page(page, $scope.items_perpage, $scope.goods);
		})
	});
    };

    $scope.page_changed = function(){
    	$scope.do_search($scope.current_page);
    }
    
    $scope.default_page = 1;
    $scope.total_items  = 0;
    // $scope.do_search($scope.default_page);
    
    var dialog = diabloUtilsService;
    $scope.lookup_detail = function(good){
	console.log(good);
	if (good.color === "0"){
	    dialog.edit_with_modal(
		"good-detail.html", undefined, undefined, $scope,
		{sizes:  good.size.split(","),
		 colors: [{id:0}],
		 path:   good.path});
	} else{
	    if (angular.isDefined(good.colors) && good.colors.length !== 0){
		dialog.edit_with_modal(
		    "good-detail.html", undefined, undefined, $scope,
		    {sizes:  good.size.split(","),
		     colors: good.colors,
		     path:   good.path});
	    } else{
		good.colors = good.color.split(",").map(function(cid){
		    return diablo_find_color(parseInt(cid), filterColor); 
		});
		dialog.edit_with_modal(
		    "good-detail.html", undefined, undefined, $scope,
		    {sizes:  good.size.split(","),
		     colors: good.colors,
		     path:   good.path});
		// })
	    }
	}
    };

    $scope.update_good = function(g){
	$location.path("/good/wgood_update/" + g.id.toString());
    };

    $scope.delete_good = function(g){
	var callback = function(){
	    diabloFilter.delete_purchaser_good(g.style_number, g.brand_id).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "删除货品",
			"货品资料 [" + g.style_number + "-" + g.brand + "-" + g.type.name + " ]删除成功！！",
			undefined,
			function(){$scope.do_search($scope.current_page)})
		} else {
		    dialog.set_error("删除货品资料", result.ecode);
		    // dialog.response(false, "删除货品", "删除货品失败：" + wgoodService.error[result.ecode]);
		}
	    })
	};
	
	dialog.request("删除货品", "确定要删除该货品资料吗？", callback);
	
	// if (angular.isDefined(g.deleted) && !g.deleted){
	//     dialog.response(false, "删除货品", wgoodService.error[2098]);
	// } else {
	//     wgoodService.get_used_purchaser_good({
	// 	style_number:g.style_number, brand:g.brand_id
	//     }).then(function(result){
	// 	console.log(result);
	// 	if (result.ecode === 0){
	// 	    var usedShops = [];
	// 	    angular.forEach(result.data, function(s){
	// 		if (s.amount !== 0)
	// 		    usedShops.push(s.shop)
	// 	    });

	// 	    if (usedShops.length !== 0) {
	// 		dialog.response(
	// 		    false, "删除货品", "删除货品失败：["
	// 			+ usedShops.toString() + "] "+ wgoodService.error[2098]);
	// 	    } else {
	// 		var callback = function(){
	// 		    wgoodService.delete_purchaser_good(g).then(function(
	// 			result){
	// 			if (result.ecode === 0){
	// 			    dialog.response_with_callback(
	// 				true, "删除货品",
	// 				"货品资料 [" + g.style_number + "-" + g.brand.name + "-"
	// 				    + g.type.name + " ]删除成功！！",
	// 				$scope,
	// 				function(){$scope.do_search($scope.current_page)})
	// 			} else {
	// 			    dialog.response(
	// 				false, "删除货品", "删除货品失败：" + wgoodService.error[result.ecode]);
	// 			}
	// 		    })
	// 		};
			
	// 		dialog.request("删除货品", "确定要删除该货品资料吗？", callback);
	// 	    } 
	// 	} else {
	// 	    dialog.response(false, "删除货品", "删除货品失败：" + wgoodService.error[result.ecode]);
	// 	} 
	//     }); 
	// } 
    };

    $scope.add_good = function(){
	diablo_goto_page("#/good/wgood_new");
    };

    $scope.add_inventory = function(){
	diablo_goto_page("#/inventory_new");
    };

    $scope.reset_barcode = function(g) {
	var callback = function() {
	    wgoodService.reset_barcode(g.style_number, g.brand_id).then(function(result) {
		console.log(result);
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"条码重置",
			"条码重置成功，重置后条码值为："
			    + result.barcode
			    + "请重新打印条码！！",
			undefined,
			function() {
			    g.bcode = result.barcode;
			});
		} else {
		    dialog.response(
			false,
			"条码重置", "条码重置失败："
			    + wgoodService.error[result.ecode]);
		}
	    });
	};
	dialog.request(
	    "条码重置", "所有与该货品关联的条码将会重置，确定要重置吗？",
	    callback, undefined, undefined);
    };

    var dialog_barcode_title = "货品条码打印";
    var dialog_barcode_title_failed = "货品条码打印失败：";
    var dialog_barcode_title_success = "货品条码打印成功：";

    if ($scope.setting.use_barcode && needCLodop())
	loadCLodop();
    
    $scope.print_barcode = function(g) {
	console.log(g);
	if (diablo_empty_barcode === g.bcode) {
	    dialog.response(
		false,
		dialog_barcode_title,
		dialog_barcode_title_failed + wgoodService.error[1997]);
	    return;
	}

	if (!angular.isDefined(g.amounts)) {
	    var colorIds = g.color.split(diablo_seperator);
	    var sizes = g.size.split(diablo_seperator);

	    var amounts = [];
	    for (var i=0, l=colorIds.length; i<l; i++) {
		for (var j=0, k=sizes.length; j<k; j++) {
		    amounts.push({
			cid:   stockUtils.to_integer(colorIds[i]),
			size:  sizes[j],
			focus: i===0 && j===0 ? true:false
		    });
		}
	    }
	    
	    // console.log(amounts);	    
	    g.colors = colorIds.map(function(cid){
		return diablo_find_color(parseInt(cid), filterColor); 
	    });
	    
	    g.sizes   = sizes;
	    g.amounts = amounts;
	}

	var start_barcode = function() {
	    var callback = function(params) {
		console.log(params);
		g.amounts = angular.copy(params.amounts);

		var barcode_amounts = [];
		for (var i=0, l=params.amounts.length; i<l; i++) {
		    var a = params.amounts[i];
		    if (stockUtils.to_integer(a.count) !== 0) {
			barcode_amounts.push(a);
		    }
		}

		if (0 === barcode_amounts.length) {
		    dialog.response(
			false,
			dialog_barcode_title,
			dialog_barcode_title_failed + wgoodService.error[1998]);
		} else {
		    // $scope.printU.setCodeFirm(g.firm_id);
		    var expire = diablo_nolimit_day;
		    g.expire_date = diablo_none;

		    if (g.alarm_day !== diablo_nolimit_day) {
			expire = stockUtils.to_integer(g.alarm_day);
		    } else {
			if (diablo_invalid_firm !== g.firm_id) {
			    if (angular.isDefined(g.firm.expire)
				&&  g.firm.expire !== diablo_nolimit_day) {
				expire = stockUtils.to_integer(g.firm.expire);
			    }
			}
		    } 

		    if (expire !== diablo_nolimit_day) {
			g.expire_date = stockUtils.date_add(g.entry_date, g.firm.expire);
		    }
		    
		    var firm = diablo_invalid_firm !== g.firm_id ? g.firm.name : undefined;

		    var barcodes = [];
		    if (g.free === 0) {
			angular.forEach(barcode_amounts, function(a) {
			    for (var i=0; i<a.count; i++) {
				barcodes.push(g.bcode); 
			    }
			});
			console.log(barcodes); 
			
			$scope.printU.free_prepare(
			    $scope.shops.length !== 0 ? $scope.shops[0].name : undefined,
			    g,
			    g.brand,
			    barcodes,
			    firm,
			    g.firm_id);
			
		    } else {
			barcodes = [];
			angular.forEach(barcode_amounts, function(a) {
			    var color = diablo_find_color(a.cid, filterColor);
			    for (var i=0; i<a.count; i++) {
				var o = stockUtils.gen_barcode_content2(g.bcode, color, a.size);
				if (angular.isDefined(o) && angular.isObject(o)) {
				    barcodes.push(o);
				} 
			    } 
			});
			
			console.log(barcodes); 
			$scope.printU.prepare(
			    $scope.shops.length !== 0 ? $scope.shops[0].name : undefined,
			    g,
			    g.brand,
			    barcodes,
			    firm,
			    g.firm_id); 
		    } 
		}
	    };

	    dialog.edit_with_modal(
		"good-barcode.html",
		undefined,
		callback,
		undefined,
		{sizes: g.sizes,
		 colors: g.colors,
		 amounts: g.amounts,
		 get_amount :function(cid, size, amounts) {
		     for (var i=0, l=amounts.length; i<l; i++) {
			 if (amounts[i].cid===cid && amounts[i].size===size) {
			     // console.log(g.amounts[i]);
			     return amounts[i];
			 }
		     }
		 },
		 path: g.path}); 
	};

	if ($scope.templates.length===1) {
	    $scope.printU.set_template($scope.templates[0]);
	    start_barcode($scope.templates[0]);
	} else {
	    var callback2 = function(params) {
		var select_template = params.templates.filter(function(t) {return t.select})[0];
		if (select_template.firm && g.firm_id === diablo_invalid_firm) {
		    dialog.response(
			false,
			dialog_barcode_title,
			dialog_barcode_title_failed + wgoodService.error[1999]);
		    return;
		}

		$scope.printU.set_template(select_template);
		start_barcode(select_template);
	    };
	    
	    dialog.edit_with_modal(
		"select-template.html",
		undefined,
		callback2,
		undefined,
		{templates: $scope.templates,
		 check_only: stockUtils.check_select_only}); 
	}
    };
    
};

define(["wgoodApp"], function(app){
    app.controller("wgoodNewCtrl", wgoodNewCtrlProvide);
    app.controller("wgoodDetailCtrl", wgoodDetailCtrlProvide);
});
