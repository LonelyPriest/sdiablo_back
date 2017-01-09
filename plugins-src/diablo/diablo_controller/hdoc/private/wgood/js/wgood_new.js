'use strict'

function wgoodNewCtrlProvide(
    $scope, $timeout, diabloPattern, diabloUtilsService, diabloFilter,
    wgoodService, filterPromotion, filterFirm, filterBrand,
    filterType, filterSizeGroup, base) {
    // console.log(filterPromotion);
    $scope.promotions = filterPromotion;
    
    $scope.seasons    = diablo_season2objects;
    $scope.full_years = diablo_full_year; 
    $scope.sexs       = diablo_sex2object;
    
    $scope.pattern = {
	style_number: diabloPattern.style_number,
	brand:        diabloPattern.ch_en_num,
	type:         diabloPattern.head_ch_en_num,
	discount:     diabloPattern.discount,
	price:        diabloPattern.positive_decimal_2};

    var dialog     = diabloUtilsService;
    var set_float  = diablo_set_float;

    $scope.base_settings = {
	m_sgroup    :stockUtils.multi_sizegroup(-1, base),
	hide_color  :stockUtils.hide_color(-1, base),
	hide_size   :stockUtils.hide_size(-1, base),
	hide_sex    :stockUtils.hide_sex(-1, base)
    };

    // console.log($scope.base_settings);

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
    var check_same_good = function(style_number, brand_name){
	// console.log(brand_name);
	var brand = get_brand(brand_name);
	if (angular.isUndefined(brand)
	    || angular.isUndefined(style_number) || !style_number){
	    $scope.good.firm = undefined;
	    $scope.is_same_good = false;
	} else {
	    wgoodService.get_purchaser_good({
		style_number:style_number, brand:brand.id
	    }).then(function(result){
		console.log(result);
		if (angular.isDefined(result.style_number)){
		    $scope.good.firm = undefined;
		    $scope.is_same_good = true;
		} else {
		    $scope.good.firm = diablo_get_object(
			brand.firm_id, $scope.firms);
		    $scope.is_same_good = false;
		}
		
	    })
	} 
    };

    var timeout_sytle_number = undefined;
    $scope.$watch("good.style_number", function(newValue, oldValue){
	if(angular.isUndefined(newValue)
	   || angular.equals(newValue, oldValue)){
	    return;
	};

	$timeout.cancel(timeout_sytle_number);
	timeout_sytle_number = $timeout(function(){
	    // console.log(newValue, oldValue);
	    check_same_good(newValue, $scope.good.brand);
	}, diablo_delay)
    });


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
    
    // get all color
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

    // color
    $scope.colors = [];
    wgoodService.list_purchaser_color().then(function(colors){
	// console.log(colors); 
	angular.forEach(colors, function(color){
	    $scope.colors.push({id:color.id, name:color.name, py:diablo_pinyin(color.name)});
	    // if (!in_sys_color($scope.colors, color)){
	    // 	$scope.colors.push(
	    // 	    {type:color.type, tid:color.tid,
	    // 	     colors:[{name:color.name, id:color.id}]})
	    // }
	});

	$scope.group_color_with_8();
	// console.log($scope.colors);
    });
    
    wgoodService.list_color_type().then(function(data){
    	// console.log(data);
    	$scope.colorTypes = data;
    });

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
	    
	    if (i <= (g+1)*10 - 1){
		color[(i - g * 10).toString()] = add_color;
	    } 
	    if (i === (g+1) * 10){
		$scope.grouped_colors.push(color);
		g++;
		color = {};
		color[(i - g * 10).toString()] = add_color;
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
		    // var newColor = {
		    // 	id:      newColorId,
		    // 	name:    params.color.name,
		    // 	tid:     params.color.type.id,
		    // 	type:    params.color.type.name, 
		    // 	remark:  params.color.remark};
		    
		    // if (!in_sys_color($scope.colors, newColor)){
		    // 	$scope.colors.push(
		    // 	    {type: newColor.type,
		    // 	     tid:  newColor.tid,
		    // 	     colors:[{name:newColor.name, id:newColor.id}]})
		    // }

		    $scope.colors.push({
			id:newColorId,
			name:params.color.name,
			py:diablo_pinyin(params.color.name)
		    });

		    $scope.group_color_with_8();
		    // console.log($scope.colors); 
		}; 
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增颜色", "新增颜色成功！！", $scope,
			function(){
			    append_color(state.id);
			    diabloFilter.reset_color();
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
    

    // $scope.selectColors = []; 
    // $scope.select_color = function(){
    // 	var callback = function(params){
    // 	    console.log(params.colors);
	    
    // 	    $scope.selectColors = []; 
    // 	    $scope.good.colors="";
    // 	    angular.forEach(params.colors, function(colorInfo){
    // 		angular.forEach(colorInfo.colors, function(color){
    // 		    if(angular.isDefined(color.select) && color.select){
    // 			$scope.good.colors += color.name + "；";
    // 			$scope.selectColors.push(angular.copy(color));
    // 		    }
    // 		})
    // 	    }); 
    // 	    console.log($scope.selectColors);

    // 	    // save select info
    // 	    $scope.colors = angular.copy(params.colors);

	    
    // 	}; 
	
    // 	diabloUtilsService.edit_with_modal(
    // 	    "select-color.html", 'lg',
    // 	    callback, $scope, {colors:$scope.colors});
    // };

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
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html",
	    'lg',
	    callback,
	    undefined,
	    {colors:$scope.grouped_colors,
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

	diabloUtilsService.edit_with_modal(
	    "select-size.html", undefined,
	    callback, $scope, {groups: $scope.groups,
			       select_group: select_group});
    };

    $scope.delete_image = function(){
	// console.log($scope.image);
	$scope.image = undefined;
    };

    /*
     * new good
     */
    $scope.good = {
	promotion : $scope.promotions.length > 0
	    ? $scope.promotions[0]:undefined,
	org_price : 0,
	tag_price : 0,
	ediscount : 100,
	discount  : 100,
	alarm_day : 7,
	year      : diablo_now_year(),
	season    : $scope.seasons[0]
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

    // $scope.on_select_brand = function(item, model, label){
    // 	// console.log(item, model, label)
    // 	$scope.good.firm = diablo_get_object(item.firm_id, $scope.firms);
    // };

    // $scope.on_select_brand = function(){
    // 	console.log();
    // };
    
    $scope.new_good = function(){
	console.log($scope.good);
	console.log($scope.image);
	var good       = angular.copy($scope.good);
	good.firm      = good.firm.id;
	good.season    = good.season.id;
	good.sex       = good.sex.id;
	// good.promotion = good.promotion.id;
	
	good.brand     = typeof(good.brand) === "object"
	    ? good.brand.name: good.brand;
	
	good.type     = typeof(good.type) === "object"
	    ? good.type.name: good.type;
	
	good.colors   = function(){
	    if (angular.isDefined($scope.selectColors)
		&& $scope.selectColors.length > 0){
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
	    ? $scope.image.dataUrl.replace(
		    /^data:image\/(png|jpg);base64,/, "") : undefined;
	
	// console.log(image);
	
	wgoodService.add_purchaser_good(good, image).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		dialog.response_with_callback(
		    true, "新增货品", "新增货品资料成功！！", $scope,
		    function(){
			// console.log("callback");
			// reset size 
			// $scope.selectGroups = [];
			// $scope.good.sizes = "";
			// angular.forEach($scope.groups, function(g){
			//     if (angular.isDefined(g.select)){
			// 	g.select = false;
			//     }
			// });

			// reset color
			$scope.selectColors = [];
			$scope.good.colors="";
			
			// console.log($scope.colors);
			angular.forEach($scope.colors, function(color){
			    if (color.select) color.select = false;
			});

			console.log($scope.grouped_colors);
			
			// angular.forEach($scope.colors, function(colorInfo){
			//     angular.forEach(colorInfo, function(color){
			// 	// console.log(color);
			// 	angular.forEach(color, function(c){
			// 	    if (angular.isDefined(c.select)){
			// 		c.select = false;
			// 	    }
			// 	}) 
			//     })
			// });

			// console.log($scope.colors);
			
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
				py   :diablo_pinyin(good.type)});

			    diabloFilter.reset_type();
			};
			// console.log($scope.types);
		    });
	    } else{
		diabloUtilsService.response(
		    false, "新增货品",
		    "新增货品 ["
			+ good.style_number + "-" + good.brand + "-"
			+  good.type + "] 失败："
			+ wgoodService.error[state.ecode]);
	    }
	});
    };

    $scope.reset = function(){
	$scope.selectGroups = [];
	$scope.selectColors = [];
	$scope.good = {
	    sex:       $scope.good.sex,
	    year:      $scope.good.year,
	    season:    $scope.good.season,
	    org_price: $scope.good.org_price,
	    tag_price: $scope.good.tag_price, 
	    ediscount: $scope.good.ediscount,
	    discount:  $scope.good.discount,
	    alarm_day: $scope.good.alarm_day
	};
	
	$scope.goodForm.style_number.$pristine = true;
	$scope.goodForm.brand.$pristine = true;
	$scope.goodForm.type.$pristine = true;
	// $scope.goodForm.firm.$pristine = true;
	$scope.goodForm.org_price.$pristine = true;
	$scope.goodForm.tag_price.$pristine = true; 
	$scope.goodForm.ediscount.$pristine = true;
	$scope.goodForm.discount.$pristine  = true;
	$scope.goodForm.alarm.$pristine     = true;
	$scope.image = undefined;
    };
};

function wgoodDetailCtrlProvide(
    $scope, $location, dateFilter, diabloUtilsService,
    diabloPagination, wgoodService, user, diabloFilter,
    filterPromotion, filterBrand, filterFirm, filterType, filterColor, base){
    /*
     * authen
     */
    // console.log(user.right);
    $scope.right = {
	update_w_good: rightAuthen.authen(
	    user.type,
	    rightAuthen.good_action()["update_w_good"],
	    user.right),

	delete_w_good: rightAuthen.authen(
	    user.type,
	    rightAuthen.good_action()["delete_w_good"],
	    user.right),

	lookup_w_good_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.good_action()["lookup_w_good_orgprice"],
	    user.right)
    };

    console.log($scope.right);
    /*
     * filter
     */ 
    // initial
    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("style_number", diabloFilter.match_style_number);
    diabloFilter.add_field("brand", filterBrand);
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
			d.firm  = diablo_get_object(d.firm_id, filterFirm);
			d.type  = diablo_get_object(d.type_id, filterType);
			// d.promotion =
			//     diablo_get_object(d.pid, filterPromotion);
		    })
		    $scope.goods = result.data;
		    diablo_order_page(
			page, $scope.items_perpage, $scope.goods);
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
	if (angular.isDefined(g.deleted) && !g.deleted){
	    dialog.response(false, "删除货品", wgoodService.error[2098]);
	} else {
	    wgoodService.get_used_purchaser_good({
		style_number:g.style_number, brand:g.brand_id
	    }).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    var usedShops = [];
		    angular.forEach(result.data, function(s){
			if (s.amount !== 0)
			    usedShops.push(s.shop)
		    });

		    if (usedShops.length !== 0) {
			dialog.response(
			    false, "删除货品", "删除货品失败：["
				+ usedShops.toString() + "] "+ wgoodService.error[2098]);
		    } else {
			var callback = function(){
			    wgoodService.delete_purchaser_good(g).then(function(
				result){
				if (result.ecode === 0){
				    dialog.response_with_callback(
					true, "删除货品",
					"货品资料 [" + g.style_number
					    + "-" + g.brand.name + "-"
					    + g.type.name + " ]删除成功！！",
					$scope,
					function(){$scope.do_search(
					    $scope.current_page)})
				} else {
				    dialog.response(
					false, "删除货品", "删除货品失败："
					    + wgoodService.error[result.ecode]);
				}
			    })
			};
			
			dialog.request(
			    "删除货品", "确定要删除该货品资料吗？", callback);
		    } 
		} else {
		    dialog.response(
			false, "删除货品", "删除货品失败："
			    + wgoodService.error[result.ecode]);
		}
		
		// if (angular.isDefined(result.id)){
		//     g.deleted = false;
		//     dialog.response(
		// 	false, "删除货品",
		// 	"删除货品失败：" + wgoodService.error[2098], $scope);
		// } else {
		//     var callback = function(){
		// 	wgoodService.delete_purchaser_good(g).then(function(
		// 	    result){
		// 	    if (result.ecode === 0){
		// 		dialog.response_with_callback(
		// 		    true, "删除货品",
		// 		    "货品资料 [" + g.style_number
		// 			+ "-" + g.brand.name + "-"
		// 			+ g.type.name + " ]删除成功！！",
		// 		    $scope,
		// 		    function(){$scope.do_search(
		// 			$scope.current_page)})
		// 	    } else {
		// 		dialog.response(
		// 		    false, "删除货品", "删除货品失败："
		// 			+ wgoodService.error[result.ecode]);
		// 	    }
		// 	})
		//     };
		    
		//     dialog.request(
		// 	"删除货品", "确定要删除该货品资料吗？", callback);
		// }
	    })    
	} 
    };

    $scope.add_good = function(){
	diablo_goto_page("#/good/wgood_new");
    };

    $scope.add_inventory = function(){
	diablo_goto_page("#/inventory_new");
    };
    
};

define(["wgoodApp"], function(app){
    app.controller("wgoodNewCtrl", wgoodNewCtrlProvide);
    app.controller("wgoodDetailCtrl", wgoodDetailCtrlProvide);
});
