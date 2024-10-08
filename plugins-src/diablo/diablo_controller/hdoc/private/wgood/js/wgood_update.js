'use strict'

function wgoodUpdateCtrlProvide(
    $scope, $location, $routeParams, $q, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, wgoodService,
    filterPromotion,
    filterBrand,
    filterFirm,
    filterColor,
    filterSizeGroup,
    filterStdExecutive, filterCategory, filterFabric, filterTemplate, base, user){
    // console.log(filterSizeGroup);
    // console.log($routeParams);
    
    $scope.seasons    = diablo_season2objects;
    $scope.sexs       = diablo_sex2object;
    $scope.full_years = diablo_full_year;

    $scope.pattern = {
	style_number: diabloPattern.style_number,
	brand:        diabloPattern.brand,
	type:         diabloPattern.good_type,
	discount:     diabloPattern.discount,
	price:        diabloPattern.positive_decimal_2,
	expire:       diabloPattern.expire_date,
	percent:      diabloPattern.percent,
	barcode:      diabloPattern.number,
	product_batch:diabloPattern.number,
	date:         diabloPattern.date
    };

    $scope.shops      = user.sortShops;
    $scope.promotions = filterPromotion;
    $scope.brands     = filterBrand; 
    $scope.firms      = filterFirm;
    // $scope.types      = filterType;
    $scope.groups     = filterSizeGroup
    $scope.waynodes   = diablo_waynodes; 
    
    $scope.colors     = [];
    $scope.grouped_colors = [];

    var authen = new diabloAuthen(user.type, user.right, user.shop);
    $scope.stock_right = authen.authenStockRight();

    $scope.std_units      = diablo_std_units;
    // console.log($scope.std_units); 
    $scope.levels         = diablo_level;
    $scope.std_executives = filterStdExecutive;
    $scope.categories     = filterCategory;
    $scope.fabrics        = filterFabric;
    $scope.template       = filterTemplate.length!==0 ? filterTemplate[0] : undefined; 
    $scope.match_prompt_type = function(viewValue) {
	return diabloFilter.match_prompt_type(viewValue, diablo_is_ascii_string(viewValue));
    }; 
    // console.log($scope.template);
    
    // $scope.stock_right = {
    // 	show_orgprice :stockUtils.authen_rainbow(user.type, user.right, 'show_orgprice'),
    // 	update_tprice :stockUtils.authen_stock(user.type, user.right, 'update_tprice_on_stock_in'),
    // 	update_oprice :stockUtils.authen_stock(user.type, user.right, 'update_oprice_on_stock_in') 
    // };
    
    // $scope.price_readonly = $scope.stock_right.update_tprice ? false : true; 
    $scope.route_params = {shop:false, from: stockUtils.to_integer($routeParams.from)}; 
    // console.log($scope.route_params); 
        
    // [{type:"红色", tid:1
    // 	    colors:[{name:"深红", id:1},
    // 		    {name:"粉红", id:2}]},
    //  {type:"蓝色", tid:2
    //      colors:[{name:"深蓝", id:3},
    // 	            {name:"浅蓝", id:4}]}, 
    // ];
    
    // var in_sys_color = function(syscolors, color){
    // 	for(var i=0, l=syscolors.length; i<l; i++){
    // 	    if(syscolors[i].tid === color.tid){
    // 		syscolors[i].colors.push(
    // 		    {name: color.name, id:color.id});
    // 		return true;
    // 	    }
    // 	}

    // 	return false;
    // };

    // colors
    // angular.forEach(filterColor, function(color){
    // 	if (!in_sys_color($scope.colors, color)){
    // 	    $scope.colors.push(
    // 		{type:color.type, tid:color.tid,
    // 		 colors:[{name:color.name, id:color.id}]})
    // 	}
    // });

    $scope.colors = angular.copy(filterColor);
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
    
    var dialog = diabloUtilsService;
    var promise = diabloPromise.promise;
    // console.log($scope.types);
    // console.log($scope.firms);
    wgoodService.get_purchaser_good_by_id($routeParams.id).then(function(good){
	console.log(good); 
	
	// old
	good.gen_date = diablo_format_date(good.gen_date);
	good.valid_date = diablo_format_date(good.valid_date);
	$scope.src_good = angular.copy(good);
	// $scope.src_good.brand =
	//     diablo_get_object(good.brand_id, $scope.brands);
	// $scope.src_good.type  = diablo_get_object(good.type_id, $scope.types).name;

	// now
	$scope.good = angular.copy(good);
	// $scope.good.brand = brand.name;
	// $scope.good.type      = diablo_get_object(good.type_id, $scope.types);
	$scope.good.firm      = diablo_get_object(good.firm_id, $scope.firms);
	$scope.good.sex       = diablo_get_object(good.sex, $scope.sexs);
	$scope.good.season    = diablo_get_object(good.season, $scope.seasons);
	$scope.good.unit      = $scope.std_units[good.unit]; 

	if (good.executive_id === diablo_invalid_index) {
	    $scope.good.executive = $scope.std_executives.length === 0 ? undefined : $scope.std_executives[0];
	} else {
	    $scope.good.executive = diablo_get_object(good.executive_id, $scope.std_executives); 
	}

	if (good.category_id === diablo_invalid_index) {
	    $scope.good.category = $scope.categories.length === 0 ? undefined : $scope.categories[0];
	} else {
	    $scope.good.category  = diablo_get_object(good.category_id,  $scope.categories); 
	}

	$scope.good.fabrics = []; 
	$scope.good.fabric_desc = diablo_empty_string; 
	if (good.fabric_json) {
	    var fabrics = angular.fromJson(good.fabric_json);
	    // $scope.good.fabrics = angular.fromJson(good.fabric_json);
	    angular.forEach(fabrics, function(f) {
		var fabric = diablo_get_object(f.f, filterFabric);
		if (angular.isDefined(fabric) && angular.isObject(fabric)) {
		    $scope.good.fabrics.push({
			fabric:fabric.name,
			way:diablo_get_object(angular.isUndefined(f.w) ? 0:f.w, $scope.waynodes),
			percent:stockUtils.to_integer(f.p)});
		    $scope.good.fabric_desc += fabric.name + ":" + f.p.toString(); 
		} 
	    });
	};

	$scope.good.feathers = [];
	$scope.good.feather_desc = diablo_empty_string;
	if (good.feather_json) {
	    var feathers = angular.fromJson(good.feather_json);
	    angular.forEach(feathers, function(f) {
		if(!diablo_is_empty(f)) {
		    $scope.good.feathers.push({wsize:f.m, weight:f.w});
		    $scope.good.feather_desc += f.m.toString() + ":" + f.w.toString();
		} 
	    });
	}

	if ($scope.good.level === diablo_invalid_index) {
	    $scope.good.level = $scope.levels[0];
	} else {
	    $scope.good.level = $scope.levels[$scope.good.level];
	}
	
	console.log($scope.good);

	if (angular.isDefined($routeParams.shop)){
	    $scope.good.shop      = diablo_get_object(parseInt($routeParams.shop), $scope.shops);
	    $scope.route_params.shop = true;
	} else {
	    $scope.good.shop      = $scope.shops[0];
	}

	$scope.init_base_setting = function(shop) {
	    var hide_mode  = stockUtils.stock_in_hide_mode(shop, base); 
	    $scope.setting = {multi_sgroup:stockUtils.multi_sizegroup(shop, base),
			      // hide_color  :stockUtils.to_integer(hide_mode.charAt(0)),
			      // hide_size   :stockUtils.to_integer(hide_mode.charAt(1)),
			      // hide_sex    :stockUtils.to_integer(hide_mode.charAt(2)),
			      // hide_expire :function() {
			      //     var h = hide_mode.charAt(3);
			      //     if ( !h ) return diablo_yes;
			      //     else return stockUtils.to_integer(h);
			      // }(),
			      auto_barcode :stockUtils.auto_barcode(diablo_default_setting, base)
			     };
	    
	    angular.extend($scope.setting, hide_mode); 
	    console.log($scope.setting);
	}

	$scope.init_base_setting($scope.good.shop.id);
	
	// $scope.setting = {
	//     multi_sgroup :stockUtils.multi_sizegroup($scope.good.shop.id, base),
	//     auto_barcode :stockUtils.auto_barcode(diablo_default_setting, base),
	    
	// };

	// $scope.good.promotion = diablo_get_object(good.pid, $scope.promotions);
	// $scope.good.shop      = $scope.shops[0];

	// // image
	// $scope.image = {}; 
	// // $scope.org_image.image = new Image();
	// $scope.image.path = $scope.good.path;

	// get selected color
	$scope.selectColors = []; 
	var descs = [];

	angular.forEach($scope.colors, function(color){
	    var selectColorIds = $scope.good.color.split(",");
	    for(var i=0, l=selectColorIds.length; i<l; i++){
		if (color.id === parseInt(selectColorIds[i])){
		    descs.push(color.name);
		    color.select = true;
		    // color.disabled = true;
		    $scope.selectColors.push(angular.copy(color));
		} 
	    }
	});
	
	// angular.forEach($scope.colors, function(colorInfo){
	//     angular.forEach(colorInfo.colors, function(color){
	// 	var selectColorIds = $scope.good.color.split(",");
	// 	for(var i=0, l=selectColorIds.length; i<l; i++){
	// 	    if (color.id === parseInt(selectColorIds[i])){
	// 		// $scope.good.color_desc += color.name + "；";
	// 		descs.push(color.name);
	// 		color.select = true;
	// 		color.disabled = true;
	// 		$scope.selectColors.push(angular.copy(color));
	// 	    } 
	// 	}
	//     })
	// });

	// $scope.src_selectColors = angular.copy($scope.selectColors);

	if ($scope.selectColors.length === 0) descs.push("均色");
	
	$scope.good.color_desc = descs.toString();
	$scope.src_good.color_desc = descs.toString();

	$scope.group_color_with_8();

	var select_groups = $scope.good.s_group.split(",").map(function(s){
            return parseInt(s);
	})

        // console.log(select_groups);
	$scope.selectGroups = angular.copy($scope.groups);
	angular.forEach($scope.selectGroups, function(g){
            if (in_array(select_groups, g.id)){
                g.select = true;
		g.disabled = true;
            }
        });
    });

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
			"面料选择",
			"面料选择失败失败：面料输入不正确，请确保面料从下拉框中选择，面料成份不为零");
		    return;
		}
	    };

	    $scope.good.fabrics = cs.filter(function(c) {
		return angular.isDefined(c) && 0 !== stockUtils.to_float(c.percent);
	    });

	    $scope.good.fabric_desc = diablo_empty_string;
	    angular.forEach($scope.good.fabrics, function(f) {
		$scope.good.fabric_desc += f.fabric + ":" + f.percent.toString();
	    });

	    // console.log($scope.good.fabric_desc);
	};
	
	dialog.edit_with_modal(
	    "select-fabric.html",
	    undefined,
	    callback,
	    undefined,
	    {composites:function(){
		if(angular.isDefined($scope.good.fabrics)
		   && angular.isArray($scope.good.fabrics)
		   && $scope.good.fabrics.length > 0) {
		    angular.forEach($scope.good.fabrics, function(f) {
			f.way = diablo_get_object(f.way.id, $scope.waynodes);
		    });
		} 
		return $scope.good.fabrics;
	    }(),
	     
	     add_composite: function(composites, waynodes) {
		 composites.push({fabric:undefined, way:waynodes[0], percent:undefined});
	     },
	     
	     delete_composite: function(composites) {
		 composites.splice(-1, 1);
	     },
	     fabrics:   $scope.fabrics,
	     waynodes:  $scope.waynodes,
	     p_percent: $scope.pattern.percent});
    };

    $scope.select_feather = function() {
	var callback = function(params) {
	    console.log(params.composites);
	    var fs = params.composites; 
	    // check
	    for (var i=0, l=fs.length; i<l; i++) {
		var f = fs[i];
		if ( stockUtils.to_float(f.wsize) === 0 || stockUtils.to_float(f.weight) === 0 ) {
		    dialog.set_error("新增货品", 2059); 
		    return;
		}
	    };

	    $scope.good.feathers = fs.filter(function(f) {
		return angular.isDefined(f)
		    && 0 !== stockUtils.to_float(f.wsize)
		    && 0 !== stockUtils.to_float(f.weight)
		
	    });

	    $scope.good.feather_desc = diablo_empty_string;
	    angular.forEach($scope.good.feathers, function(f) {
		$scope.good.feather_desc += f.wsize.toString() + ":" + f.weight.toString();
	    });

	    // console.log($scope.good.fabric_desc);
	};
	
	dialog.edit_with_modal(
	    "select-feather.html",
	    undefined,
	    callback,
	    undefined,
	    {composites:$scope.good.feathers,
	     add_composite: function(composites) {
		 composites.push({wsize:undefined, weight:undefined});
	     },
	     delete_composite: function(composites) {
		 composites.splice(-1, 1);
	     },
	    });
    };

    $scope.delete_image = function(){
	$scope.image = undefined;
    };
    
    $scope.new_firm = function(){
	var callback = function(params){
	    console.log(params);

	    wgoodService.new_firm(params.firm).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增厂家",
			"恭喜你，厂家 " + params.firm.name + " 成功创建！！",
			$scope,
			function(){
			    $scope.good.firm = {
				id:state.id,
				name:params.firm.name,
				py:diablo_pinyin(params.firm.name)}; 
			});
		} else{
		    dialog.response(
	    		false, "新增厂家",
	    		"新增厂家失败：" + wgoodService.error[state.ecode]);
		};
	    })
	    
	};

	dialog.edit_with_modal(
	    "new-firm.html", undefined, callback, $scope, {firm:{}});
    } 

    $scope.$watch("good.brand", function(newValue, oldValue){
	if(angular.isUndefined(newValue)){
	    return;
	}
	
	var re = diabloPattern.ch_en_num;
	if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
	    $scope.goodForm.brand.$invalid = true;
	} else{
	    $scope.goodForm.brand.$invalid = false;
	}
	
    });

    // $scope.$watch("good.type", function(newValue, oldValue){
    // 	if(angular.isUndefined(newValue)){
    // 	    return;
    // 	}
	
    // 	var re = $scope.pattern.type;
    // 	if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
    // 	    $scope.goodForm.type.$invalid = true;
    // 	}else{
    // 	    $scope.goodForm.type.$invalid = false;
    // 	}
	
    // });

    wgoodService.list_color_type().then(function(data){
	// console.log(data);
	$scope.colorTypes = data;
    }); 
    
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    var append_color = function(newColorId){
			// var newColor = {
			//     id:      newColorId,
			//     name:    params.color.name,
			//     tid:     params.color.type.id,
			//     type:    params.color.type.name, 
			//     remark:  params.color.remark};
			
			// if (!in_sys_color($scope.colors, newColor)){
			//     $scope.colors.push(
			// 	{type:newColor.type,
			// 	 tid:newColor.tid,
			// 	 colors:[{name:newColor.name,id:newColor.id}]})
			// } 
			// console.log($scope.colors);
			$scope.colors.push({
			    id:newColorId,
			    name:params.color.name,
			    py:diablo_pinyin(params.color.name)
			});

			// filterColor.push({
			//     id:newColorId,
			//     name:params.color.name,
			//     py:diablo_pinyin(params.color.name)});

			$scope.group_color_with_8();
			diabloFilter.reset_color();
		    };
		    
		    dialog.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){append_color(state.id)});
		} else{
		    dialog.response(
			false, "新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html',
	    undefined,
	    callback,
	    undefined,
	    {color: {types: $scope.colorTypes}})
    }

    // $scope.selectColors = []; 
    // $scope.select_color = function(){
    // 	var callback = function(params){
    // 	    console.log(params.colors);
	    
    // 	    $scope.selectColors = []; 
    // 	    // $scope.good.color_desc="";
    // 	    var descs = [];
    // 	    angular.forEach(params.colors, function(colorInfo){
    // 		angular.forEach(colorInfo.colors, function(color){
    // 		    if(angular.isDefined(color.select)
    // 		       && color.select
    // 		       && !color.disabled){
    // 			descs.push(color.name);
    // 			$scope.selectColors.push(angular.copy(color));
    // 		    }
    // 		})
    // 	    });
	    
    // 	    $scope.good.color_desc = $scope.src_good.color_desc;
    // 	    if (descs.length !== 0) $scope.good.color_desc += "," + descs.toString();
	    
    // 	    console.log($scope.selectColors); 
    // 	    // save select info
    // 	    $scope.colors = params.colors; 
    // 	}; 
	
    // 	diabloUtilsService.edit_with_modal(
    // 	    "select-color.html", undefined,
    // 	    callback, $scope, {colors:$scope.colors});
    // };

    $scope.select_color = function(){
	var callback = function(params){
	    // console.log(params.colors);
	    // console.log(params.ucolors); 
	    // $scope.selectColors = angular.copy($scope.src_selectColors);
	    $scope.selectColors = [];
	    var descs = []; 
	    for (var i=0, l1=params.colors.length; i<l1; i++){
		for (var j in params.colors[i]){
		    var c = params.colors[i][j];
		    if(c.select && !c.disabled){
			descs.push(c.name);
			$scope.selectColors.push(angular.copy(c));
		    }
		}
	    }

	    $scope.good.color_desc = $scope.src_good.color_desc;
	    if (descs.length !== 0) $scope.good.color_desc += "," + descs.toString();
	    
	    console.log($scope.selectColors); 
	    $scope.grouped_colors = angular.copy(params.colors);
	}; 

	var on_select_ucolor = function(item, model, label){
	    model.select = true; 
	};
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html",
	    'lg',
	    callback,
	    undefined,
	    {colors:$scope.grouped_colors,
	     color_range: color_range,
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


    $scope.select_size = function(){
        var callback = function(params){
            $scope.good.size = "";
            angular.forEach(params.groups, function(g){
                if (angular.isDefined(g.select) && g.select){
                    $scope.good.size += g.name + "；";
                }
            });
            $scope.selectGroups = params.groups;
        };

        var select_group = function(groups, g){
            for(var i=0, l=groups.length; i<l; i++){
                if (!groups[i].disabled && groups[i].id !== g.id){
                    groups[i].select = false;
                }
            }
        };

        diabloUtilsService.edit_with_modal(
            "select-size.html", 'lg',
            callback,  undefined, {groups: $scope.selectGroups,
                               select_group: select_group}, true);
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

    $scope.on_change_shop = function(){
	$scope.init_base_setting($scope.good.shop.id); 
    };
    
    /*
     * update good
     */
    $scope.update_good = function(){
	console.log($scope.good);
	// console.log($scope.image);
	var good = $scope.good;
	var update_good = {};

	update_good.id           = good.id;
	// update_good.shop         = good.shop.id;
	update_good.style_number = good.style_number;
	update_good.bcode        = good.bcode;
	// update_good.brand_id     = good.brand_id;
	update_good.brand  = typeof(good.barnd) === "object" ? good.brand.name: good.brand;
	update_good.type   = good.type;

	update_good.firm_id   = function() {
	    return angular.isDefined(good.firm) && good.firm.id ? good.firm.id : -1;
	}();
	update_good.sex       = good.sex.id;
	update_good.year      = good.year;
	update_good.season    = good.season.id; 
	update_good.org_price = stockUtils.to_float(good.org_price);
	update_good.vir_price = stockUtils.to_float(good.vir_price);
	update_good.tag_price = stockUtils.to_float(good.tag_price);
	update_good.draw      = stockUtils.to_float(good.draw);
	update_good.ediscount = stockUtils.to_integer(good.ediscount);
	update_good.discount  = stockUtils.to_integer(good.discount);
	update_good.alarm_day = stockUtils.to_integer(good.alarm_day);
	update_good.unit      = $scope.std_units.indexOf(good.unit);
	update_good.product_batch = good.product_batch;
	update_good.gen_date      = good.gen_date;
	update_good.valid_date    = good.valid_date;
	
	update_good.level     = function() {
	    var levelIndex = $scope.levels.indexOf(good.level);
	    return levelIndex === 0 ? diablo_invalid_index : levelIndex;
	}();
	
	update_good.executive_id   = stockUtils.invalid_firm(good.executive);
	update_good.category_id    = stockUtils.invalid_firm(good.category);
	update_good.fabric_json = function() {
	    if (angular.isArray(good.fabrics) && good.fabrics.length !== 0) {
		var cs = good.fabrics.map(function(f){
		    return {
			f:stockUtils.get_object_by_name(f.fabric, filterFabric).id,
			w:f.way.id,
			p:f.percent};
		});
		console.log(cs); 
		return angular.toJson(cs);
	    } else {
		return undefined;
	    }
	}();

	update_good.feather_json = function() {
	    if (angular.isArray(good.feathers) && good.feathers.length !== 0) {
		var fs = good.feathers.map(function(f){
		    return {m:f.wsize, w:f.weight};
		});
		console.log(fs); 
		return angular.toJson(fs);
	    } else {
		return undefined;
	    }
	}();
	
	update_good.color     = function(){
	    if (angular.isDefined($scope.selectColors) && $scope.selectColors.length > 0){
		var colors = $scope.src_good.color.split(",").map(
		    function(cid){return parseInt(cid)});
		
		for (var i=0, l=$scope.selectColors.length; i<l; i++)
		    if (!in_array(colors, $scope.selectColors[i].id)){
			colors.push($scope.selectColors[i].id); 
		    }
		
		return colors.toString();
	    } else{
		return $scope.src_good.color;
		// return wgoodService.free_color.toString();;
	    }
	}();


	update_good.s_group  = function(){
            var s_group = $scope.selectGroups.filter(function(g){
                return g.select;
            }).map(function(g){
		return g.id;
            });

            return s_group.length !== 0 ? s_group.toString() : $scope.src_good.s_group;
        }();

        update_good.size = function(){
            var s_group = $scope.selectGroups.filter(function(g){
                return g.select;
            });

            var groups = [];
            angular.forEach(s_group, function(g){
                for(var i=0, l=diablo_sizegroup.length; i<l; i++){
                    var k = diablo_sizegroup[i];
                    if(g[k] && !in_array(groups, g[k])) groups.push(g[k]);
                }
            })

            return groups.length !== 0 ? groups.toString() : $scope.src_good.size;
        }();
	
	console.log(update_good);
	console.log($scope.src_good);
	
	// get changed
	var changed_good = {};
	for (var o in update_good){
	    // console.log($scope.update_good[o], $scope.src_good[o]);
	    if (!angular.equals(update_good[o], $scope.src_good[o])){
		changed_good[o] = update_good[o];
	    }
	}; 
	
	var image;
	if (angular.isDefined($scope.image) && $scope.image)
	    image = $scope.image.dataUrl.replace(/^data:image\/(png|jpg);base64,/, "");

	console.log(changed_good);

	if (diablo_is_empty(changed_good) && angular.isUndefined(image)){
	    diabloUtilsService.response(false, "修改货品", "修改货品资料失败：" + wgoodService.error[2099]);
	} else {
	    changed_good.good_id        = update_good.id;
	    // changed_good.shop           = update_good.shop; 
	    changed_good.o_style_number = $scope.src_good.style_number;
	    changed_good.o_brand        = $scope.src_good.brand_id;
	    changed_good.o_path         = $scope.src_good.path;
	    changed_good.o_firm         = $scope.src_good.firm_id; 
	    changed_good.image          = $scope.src_good.image;
	    changed_good.shop           = $scope.good.shop.id;

	    console.log(changed_good);
	    if (changed_good.bcode
		&& changed_good.bcode !== diablo_empty_barcode
		&& changed_good.bcode !== diablo_empty_db_barcode
		&& changed_good.bcode.length !== diablo_std_barcode_length) {
		    diabloUtilsService.response(
			false, "修改货品", "修改货品资料失败：" + wgoodService.error[2073]);
	    } else {
		wgoodService.update_purchaser_good(changed_good, image).then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "修改货品", "修改货品资料成功！！", $scope,
			    function(){
				// reset cache, refresh
				diabloFilter.reset_firm();
				diabloFilter.reset_brand();
				diabloFilter.reset_type();
				$scope.go_back();
			    });
		    } else{
			diabloUtilsService.response(
			    false,
			    "修改货品", "修改货品资料失败：" + wgoodService.error[state.ecode]);
		    }
		});
	    } 
	}
    };

    $scope.cancel = function(){
	$scope.go_back();
    };

    $scope.go_back = function(){
	if (angular.isDefined($routeParams.from)){
	    if (diablo_from_stock_new === stockUtils.to_integer($routeParams.from))
		diablo_goto_page("#/inventory_new");
	    else if (diablo_from_stock === stockUtils.to_integer($routeParams.from))
		diablo_goto_page("#/inventory_detail");
	} 
	else
	    diablo_goto_page("#/good/wgood_detail");
    }
};

define(["wgoodApp"], function(app){
    app.controller("wgoodUpdateCtrl", wgoodUpdateCtrlProvide);
});
