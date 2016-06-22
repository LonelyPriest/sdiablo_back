firmApp.controller("firmNewCtrl", function(
    $scope, diabloPattern, firmService, diabloUtilsService){

    $scope.pattern = {name: diabloPattern.ch_name_address,
		      balance: diabloPattern.decimal_2,
		      tel_mobile: diabloPattern.tel_mobile,
		      address: diabloPattern.ch_name_address,
		      comment: diabloPattern.comment};
    
    // new firm 
    $scope.new_firm = function(){
	$scope.firm.balance = diablo_set_float($scope.firm.balance);
	firmService.new_firm($scope.firm).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "新增厂家",
		    "恭喜你，厂家 " + $scope.firm.name + " 成功创建！！",
	    	    $scope,
		    function(){diablo_goto_page("#/firm_detail")});
	    } else{
		diabloUtilsService.response(
	    	    false, "新增厂家",
	    	    "新增厂家失败：" + firmService.error[state.ecode]);
	    };
	})
    };
    
    $scope.cancel = function(){
	diablo_goto_page("#/firm_detail");
    };
});


firmApp.controller("firmDetailCtrl", function(
    $scope, $location, $routeParams, firmService, diabloUtilsService,
    diabloPagination, diabloPattern, localStorageService){

    $scope.pattern = {
	name: diabloPattern.ch_name_address,
	balance: diabloPattern.decimal_2,
	tel_mobile: diabloPattern.tel_mobile,
	address: diabloPattern.ch_name_address,
	comment: diabloPattern.comment};

    var f_add = diablo_float_add;
    var now   = $.now();

    $scope.save_to_local = function(search, t_firm){
	var s = localStorageService.get(diablo_key_firm);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_firm, {
		    search:angular.isDefined(search) ? search:s.search,
		    t_firm:angular.isDefined(t_firm) ? t_firm:s.t_firm,
		    page:$scope.current_page,
		    t:now})
	} else {
	    localStorageService.set(
		diablo_key_firm, {search:search, t_firm:t_firm,
				  page:$scope.current_page, t:now})
	}
    };

    $scope.reset_local_storage = function(){
	var s = localStorageService.get(diablo_key_firm);
	if (angular.isDefined(s) && s !== null){
	    localStorageService.set(
		diablo_key_firm, {search:undefined, t_firm:undefined,
				  page:$scope.current_page, t:now})
	}
    };
    
    
    /*
     * pagination
     */
    $scope.colspan       = 7;
    $scope.max_page_size = 10;
    $scope.items_perpage = diablo_items_per_page();
    $scope.default_page  = 1;

    var storage = localStorageService.get(diablo_key_firm);
    console.log(storage);
    if (angular.isDefined(storage) && storage !== null){
	$scope.current_page = storage.page;
	$scope.search       = storage.search;
	$scope.total_items  = storage.t_firm;
    } else {
	$scope.current_page = $scope.default_page;
	$scope.search       = undefined;
	$scope.total_items  = undefined;
    }

    $scope.page_changed = function(){
	// console.log(page);
	// $scope.current_page = page;
	console.log($scope.current_page);
	$scope.save_to_local();
	$scope.filter_firms = diabloPagination.get_page($scope.current_page);
    }
    
    $scope.do_search = function(search){
	console.log(search);
    	return $scope.firms.filter(function(f){
	    return search === f.name
		|| search === f.mobile 
		|| search === f.address
	})
    };

    $scope.on_select_firm = function(item, model, label){
	console.log(model); 
	// $scope.save_to_local(model.name); 
	
	var filters = $scope.do_search(model.name);
	diablo_order(filters);
	console.log(filters);

	$scope.total_balance = 0;
	angular.forEach(filters, function(f){
	    $scope.total_balance = f_add($scope.total_balance, f.balance);
	});
	
	// re pagination
	diabloPagination.set_data(filters);
	$scope.total_items  = diabloPagination.get_length();
	$scope.filter_firms = diabloPagination.get_page($scope.default_page);
	// save
	$scope.save_to_local(model.name, $scope.total_items);
    }
    
    var in_prompt = function(p, prompts){
	for (var i=0, l=prompts.length; i<l; i++){
	    if (p === prompts[i].name){
		return true;
	    }
	}

	return false;
    };

    $scope.refresh = function(){
	$scope.reset_local_storage();
	$scope.do_refresh($scope.default_page, undefined);
    };
    
    $scope.do_refresh = function(page, search){
	console.log(page); 
	$scope.current_page = page;
	$scope.search       = search;
	
	firmService.list_firm().then(function(data){
	    // console.log(data);
	    $scope.firms = angular.copy(data);
	    $scope.total_balance = 0;
	    angular.forEach($scope.firms, function(f){
		$scope.total_balance = f_add($scope.total_balance, f.balance);
	    })

	    var filters;
	    if (angular.isDefined(search)){
		filters = $scope.do_search(search);
	    } else {
		filters = $scope.firms;
	    }
	    
	    diablo_order(filters);

	    // pagination
	    diabloPagination.set_data(filters);
	    diabloPagination.set_items_perpage($scope.items_perpage);
	    $scope.total_items  =
		diabloPagination.get_length();
	    $scope.filter_firms =
		diabloPagination.get_page($scope.current_page);
	    // save
	    $scope.save_to_local($scope.search, $scope.total_items);
	    
	    $scope.prompts = [];
	    for(var i=0, l=$scope.firms.length; i<l; i++){
		var f = $scope.firms[i];

		if (!in_prompt(f.name, $scope.prompts)){
		    $scope.prompts.push({name: f.name, py:diablo_pinyin(f.name)}); 
		}
		if (!in_prompt(f.address, $scope.prompts)){
		    $scope.prompts.push({name: f.address, py:diablo_pinyin(f.address)}); 
		}
		if (!in_prompt(f.mobile, $scope.prompts)){
		    $scope.prompts.push({name: f.mobile, py:diablo_pinyin(f.mobile)}); 
		} 
	    } 

	    // console.log($scope.current_page);
	});
    }

    $scope.do_refresh($scope.current_page, $scope.search);
    

    $scope.new_firm = function(){
	location.href = "#/new_firm"; 
    };

    $scope.trans_info = function(f){
	console.log(f);
	$scope.save_to_local(); 
	diablo_goto_page("#/firm_trans/" + f.id.toString());
    };

    $scope.bill_firm = function(f){
	diablo_goto_page("#/firm/bill/" + f.id.toString());
    }

    var dialog = diabloUtilsService; 
    $scope.update_firm = function(old_firm){
	// console.log(old_firm);
	var callback = function(params){
	    console.log(params.firm);
	    
	    if (angular.equals(params.firm, old_firm)){
		dialog.response(
		    false, "厂商编辑", "厂商编辑失败：" + firmService.error[1699], undefined);
	    } else{
		var update = {};
		for (var o in params.firm){
		    if (!angular.equals(params.firm[o], old_firm[o])){
			update[o] = params.firm[o];
		    }
		}

		update.balance     = update.balance ? update.balance : 0;
		update.old_balance = old_firm.balance;
		update.firm_id     = params.firm.id;
		console.log(update);

		// update.name    = params.firm.name;

		firmService.update_firm(update).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "厂商编辑",
			    "厂商 [" + params.firm.name + "] 编辑成功！！",
			    $scope, $scope.refresh())
		    } else{
			dialog.response(
			    false, "厂商编辑", "厂商编辑失败："
				+ firmService.error[result.ecode], $scope);
		    }
		});
	    }
	}

	var valid_firm = function(new_firm){
	    for (var i=0, l=$scope.firms.length; i<l; i++){
		if (new_firm.name === $scope.firms[i].name
		    && new_firm.name !== old_firm.name){
		    return false;
		}
	    }
	    
	    return true;
	}

	dialog.edit_with_modal(
	    'update-firm.html', undefined, callback, undefined,
	    {firm:old_firm,
	     valid_firm:valid_firm,
	     has_update: function(new_firm){
		 return diablo_is_same(new_firm.name, old_firm.name)
		     && diablo_is_same(new_firm.balance ? new_firm.balance:0, old_firm.balance)
		     && diablo_is_same(new_firm.address, old_firm.address)
		     && diablo_is_same(new_firm.mobile, old_firm.mobile)
		     && diablo_is_same(new_firm.comment, old_firm.comment) ? false : true;
	     },
	     pattern: $scope.pattern})
    };

    $scope.delete_firm = function(f){
	var callback = function(){
	    firmService.delete_firm(f).then(function(result){
		console.log(result);
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true, "删除厂商", "厂商 [" + f.name + "] 删除成功！！",
			$scope, function(){$scope.refresh()})
		} else{
		    dialog.response(
			false, "删除厂商", "厂商删除失败："
			    + firmService.error[result.ecode], $scope);
		}
	    })
	};

	dialog.request("删除厂商", "确定要删除该厂商吗？", callback, undefined, $scope);
	
    }
});

firmApp.controller("firmCtrl", function($scope, localStorageService){
    diablo_remove_local_storage(localStorageService)
});

firmApp.controller("loginOutCtrl", function($scope, $resource){
    $scope.home = function () {
	diablo_login_out($resource)
    };
});
