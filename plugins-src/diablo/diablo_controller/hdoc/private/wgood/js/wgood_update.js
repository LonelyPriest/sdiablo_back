wgoodApp.controller("wgoodUpdateCtrl", function(
    $scope, $location, $routeParams, $q, diabloPattern,
    diabloUtilsService, diabloPromise, diabloFilter, wgoodService,
    filterPromotion, filterBrand, filterFirm, filterType, filterColor, user){
    // console.log(filterBrand); 
    $scope.seasons    = diablo_season2objects;
    $scope.sexs       = diablo_sex2object;
    $scope.full_years = diablo_full_year;

    $scope.pattern = {
	style_number: diabloPattern.style_number,
	brand: diabloPattern.ch_en_num,
	type:  diabloPattern.head_ch_en_num,
	discount: diabloPattern.discount,
	price: diabloPattern.positive_decimal_2};

    $scope.shops      = user.sortShops;
    $scope.promotions = filterPromotion;
    $scope.brands     = filterBrand; 
    $scope.firms      = filterFirm;
    $scope.types      = filterType;
    
    $scope.colors     = [];

    $scope.stock_right = {
	show_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	)
    };

    // [{type:"红色", tid:1
    // 	    colors:[{name:"深红", id:1},
    // 		    {name:"粉红", id:2}]},
    //  {type:"蓝色", tid:2
    //      colors:[{name:"深蓝", id:3},
    // 	            {name:"浅蓝", id:4}]}, 
    // ]; 
    var in_sys_color = function(syscolors, color){
	for(var i=0, l=syscolors.length; i<l; i++){
	    if(syscolors[i].tid === color.tid){
		syscolors[i].colors.push(
		    {name: color.name, id:color.id});
		return true;
	    }
	}

	return false;
    };

    // colors
    angular.forEach(filterColor, function(color){
	if (!in_sys_color($scope.colors, color)){
	    $scope.colors.push(
		{type:color.type, tid:color.tid,
		 colors:[{name:color.name, id:color.id}]})
	}
    });

    
    var dialog = diabloUtilsService;
    var promise = diabloPromise.promise;

    // console.log($scope.types);
    // console.log($scope.firms);
    wgoodService.get_purchaser_good_by_id($routeParams.id).then(function(
	good){
	console.log(good); 
	
	// old
	$scope.src_good = angular.copy(good);
	// $scope.src_good.brand =
	//     diablo_get_object(good.brand_id, $scope.brands);
	$scope.src_good.type  = diablo_get_object(
	    good.type_id, $scope.types).name;

	// now
	$scope.good = angular.copy(good);
	// $scope.good.brand = brand.name;
	$scope.good.type      = diablo_get_object(good.type_id, $scope.types);
	$scope.good.firm      = diablo_get_object(good.firm_id, $scope.firms);
	$scope.good.sex       = diablo_get_object(good.sex, $scope.sexs);
	$scope.good.season    = diablo_get_object(good.season, $scope.seasons);
	$scope.good.shop      = $scope.shops[0];
	// $scope.good.promotion = diablo_get_object(good.pid, $scope.promotions);
	// $scope.good.shop      = $scope.shops[0];

	// // image
	// $scope.image = {}; 
	// // $scope.org_image.image = new Image();
	// $scope.image.path = $scope.good.path;

	// get selected color
	$scope.selectColors = []; 
	// $scope.good.color_desc=""; 
	var descs = []; 
	angular.forEach($scope.colors, function(colorInfo){
	    angular.forEach(colorInfo.colors, function(color){
		var selectColorIds = $scope.good.color.split(",");
		for(var i=0, l=selectColorIds.length; i<l; i++){
		    if (color.id === parseInt(selectColorIds[i])){
			// $scope.good.color_desc += color.name + "；";
			descs.push(color.name);
			color.select = true;
			color.disabled = true;
			$scope.selectColors.push(angular.copy(color));
		    } 
		}
	    })
	});

	if ($scope.selectColors.length === 0){
	    descs.push("均色");
	}
	
	$scope.good.color_desc = descs.toString();
	$scope.src_good.color_desc = descs.toString();
	// console.log($scope.selectColors);
	// console.log($scope.good);
    });

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

    $scope.$watch("good.type", function(newValue, oldValue){
    	if(angular.isUndefined(newValue)){
    	    return;
    	}
	
    	var re = $scope.pattern.type;
    	if (!re.test(typeof(newValue) === "object" ? newValue.name : newValue)){
    	    $scope.goodForm.type.$invalid = true;
    	}else{
    	    $scope.goodForm.type.$invalid = false;
    	}
	
    }); 

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
			var newColor = {
			    id:      newColorId,
			    name:    params.color.name,
			    tid:     params.color.type.id,
			    type:    params.color.type.name, 
			    remark:  params.color.remark};
			
			if (!in_sys_color($scope.colors, newColor)){
			    $scope.colors.push(
				{type:newColor.type,
				 tid:newColor.tid,
				 colors:[{name:newColor.name,id:newColor.id}]})
			} 
			console.log($scope.colors); 
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
	    'new-color.html', undefined, callback,
	    $scope, {color: {types: $scope.colorTypes}})
    }
    

    // $scope.selectColors = []; 
    $scope.select_color = function(){
	var callback = function(params){
	    console.log(params.colors);
	    
	    $scope.selectColors = []; 
	    // $scope.good.color_desc="";
	    var descs = [];
	    angular.forEach(params.colors, function(colorInfo){
		angular.forEach(colorInfo.colors, function(color){
		    if(angular.isDefined(color.select)
		       && color.select
		       && !color.disabled){
			descs.push(color.name);
			$scope.selectColors.push(angular.copy(color));
		    }
		})
	    });
	    
	    $scope.good.color_desc = $scope.src_good.color_desc;
	    if (descs.length !== 0) $scope.good.color_desc += "," + descs.toString();
	    
	    console.log($scope.selectColors); 
	    // save select info
	    $scope.colors = params.colors; 
	}; 
	
	diabloUtilsService.edit_with_modal(
	    "select-color.html", undefined,
	    callback, $scope, {colors:$scope.colors});
    };

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
	// update_good.brand_id     = good.brand_id;
	update_good.brand  = typeof(good.barnd) === "object" ? good.brand.name: good.brand;
	update_good.type  = typeof(good.type) === "object" ? good.type.name: good.type;

	update_good.firm_id   = function() {
	    return angular.isDefined(good.firm) && good.firm.id ? good.firm.id : -1;
	}();
	update_good.sex       = good.sex.id;
	update_good.year      = good.year;
	update_good.season    = good.season.id;
	update_good.org_price = parseFloat(good.org_price);
	update_good.tag_price = parseFloat(good.tag_price); 
	update_good.ediscount = parseInt(good.ediscount);
	update_good.discount  = parseInt(good.discount);
	update_good.color     = function(){
	    if (angular.isDefined($scope.selectColors) && $scope.selectColors.length > 0){
		var colors = $scope.src_good.color.split(",").map(function(cid){return parseInt(cid)});

		for (var i=0, l=$scope.selectColors.length; i<l; i++)
		    if (!in_array(colors, $scope.selectColors[i])){
			colors.push($scope.selectColors[i].id); 
		    }
		
		return colors.toString();
	    } else{
		return wgoodService.free_color.toString();;
	    }
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
	
	var image  = angular.isDefined($scope.image) && $scope.image
	    ? $scope.image.dataUrl.replace(
		    /^data:image\/(png|jpg);base64,/, "") : undefined;
	
	if (diablo_is_empty(changed_good) && angular.isUndefined(image)){
	    diabloUtilsService.response(
		false, "修改货品",
		"修改货品资料失败：" + wgoodService.error[2099]);
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

	    wgoodService.update_purchaser_good(
		changed_good, image
	    ).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    diabloUtilsService.response_with_callback(
			true, "修改货品", "修改货品资料成功！！", $scope,
			function(){
			    // reset cache, refresh
			    diabloFilter.reset_firm();
			    diabloFilter.reset_brand();
			    diabloFilter.reset_type();
			    diablo_goto_page("#/good/wgood_detail");
			});
		} else{
		    diabloUtilsService.response(
			false,
			"修改货品",
			"修改货品资料失败："
			    + wgoodService.error[state.ecode]);
		}
	    });
	}
    };

    $scope.cancel = function(){
	diablo_goto_page("#/good/wgood_detail");
    }
});
