firmApp.controller("brandNewCtrl", function(
    $scope, diabloUtilsService, diabloPattern,
    firmService, filterBrand, filterFirm){
    // console.log(filterFirm);
    // console.log(filterBrand);
    $scope.firms  = filterFirm;
    $scope.brands = angular.copy(filterBrand);

    $scope.pattern = {remark: diabloPattern.comment};

    $scope.check_name = function(brand_name){
	for (var i=0, l=$scope.brands.length; i<l; i++){
	    if ($scope.brands[i].name === brand_name){
		return false; 
	    }
	}

	return true;
    }
    
    var dialog = diabloUtilsService;
    $scope.new_brand = function(){
	firmService.new_brand($scope.brand).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		var callback = function(){
		    $scope.brands.push({
			id:result.id,
			name:$scope.brand.name,
			py: diablo_pinyin($scope.brand.name)});
		    $scope.brand.name = undefined;
		}
		
		// console.log($scope.brands);
		dialog.response_with_callback(
		    true,
		    "新增品牌",
		    "品牌 [" + $scope.brand.name + "] 创建创功！！",
		    $scope,
		    callback);
	    } else {
		dialog.response(
		    false,
		    "新增品牌",
		    "品牌 [" + $scope.brand.name + "] 创建失败："
			+ firmService.error[result.ecode]);
	    } 
	    
	});
    };

    $scope.cancel = function(){
	diablo_goto_page("#/brand_detail");
    };
    
});


firmApp.controller("brandDetailCtrl", function(
    $scope, diabloUtilsService, diabloPattern, diabloPagination,
    firmService, filterFirm){
    // console.log(filterBrand);

    $scope.max_page_size = 10;
    $scope.items_perpage = diablo_items_per_page();
    $scope.default_page  = 1;
    $scope.current_page = $scope.default_page;

    
    $scope.new_brand = function(){
	diablo_goto_page("#/new_brand");
    };

    $scope.refresh = function(){
	$scope.do_refresh($scope.default_page, undefined);
    }; 
    
    
    var in_prompt = function(p, prompts){
	for (var i=0, l=prompts.length; i<l; i++){
	    if (p === prompts[i].name){
		return true;
	    }
	}

	return false;
    };

    $scope.page_changed = function(){
	console.log($scope.current_page);
	$scope.filter_brands = diabloPagination.get_page($scope.current_page);
    };
    
    $scope.do_search = function(search){
	console.log(search);
    	return $scope.brands.filter(function(b){
	    return search === b.name
		|| search === b.supplier
	})
    };

    $scope.select_brand = function(item, model, label){
	console.log(model); 
	
	var filters = $scope.do_search(model.name);
	diablo_order(filters);
	console.log(filters); 
	
	// re pagination
	diabloPagination.set_data(filters);
	$scope.total_items  = diabloPagination.get_length();
	$scope.filter_brands = diabloPagination.get_page($scope.default_page); 
    };
    
    $scope.do_refresh = function(page, search){
	firmService.list_brand().then(function(data){
	    $scope.brands = angular.copy(data);
	    
	    // pagination
	    var filters;
	    if (angular.isDefined(search))
		filters = $scope.do_search(search);
	     else 
		 filters = $scope.brands;

	    diablo_order(filters);
	    
	    diabloPagination.set_data(filters);
	    diabloPagination.set_items_perpage($scope.items_perpage);
	    $scope.total_items   = diabloPagination.get_length();
	    $scope.filter_brands = diabloPagination.get_page($scope.current_page); 
	    // console.log($scope.filter_brands);

	    
	    $scope.prompts = []; 
	    for (var i=0, l=$scope.brands.length; i<l; i++){
		var b = $scope.brands[i];

		if (!in_prompt(b.name, $scope.prompts)){
		    $scope.prompts.push(
			{name: b.name, py: diablo_pinyin(b.name)});
		}

		if (!in_prompt(b.firm, $scope.prompts)){
		    $scope.prompts.push(
			{name:b.supplier, py:diablo_pinyin(b.supplier)});
		}
	    }
	});
    };

    $scope.do_refresh($scope.current_page, $scope.search);


    var dialog = diabloUtilsService;
    $scope.update_brand = function(brand){
	console.log(brand);
	var check_same = function(name){
	    for (var i=0, l=$scope.brands.length; i<l; i++){
		if (name === $scope.brands[i].name
		    && name !== brand.name){
		    return false;
		}
	    }

	    return true;
	};

	var has_update = function(newBrand) {
	    if (newBrand.name === brand.name
		&& diablo_is_same(newBrand.firm, brand.supplier)
		&& newBrand.remark === brand.remark){
		return false;
	    }

	    return true;
	};
	
	var callback = function(params){
	    console.log(params.brand);
	    firmService.update_brand(
		{name:   params.brand.name,
		 id:     brand.id,
		 firm:   params.brand.firm.id,
		 remark: params.brand.remark}
	    ).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "品牌编辑",  "品牌编辑成功！！",
			$scope, $scope.refresh);
		} else {
		    dialog.response(
			false, "品牌编辑",
			"品牌编辑失败：" + firmService.error[result.ecode])
		}
	    })
	};
	
	dialog.edit_with_modal(
	    "update-brand.html", undefined, callback, $scope,
	    {brand: {name   :brand.name,
		     firm   :diablo_get_object(brand.supplier_id, filterFirm),
		     remark :brand.remark},
	     firms: filterFirm,
	     pattern: {remark: diabloPattern.comment},
	     check_same: check_same,
	     has_update: has_update
	    });
	// dialog.response(false, "修改品牌", "暂不支持此操作！！")
    };

    $scope.delete_brand = function(brand){
	dialog.response(false, "删除品牌", "暂不支持此操作！！")
    };
});
