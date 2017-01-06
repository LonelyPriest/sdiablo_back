'use strict'

function firmNewCtrlProvide(
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
};


function firmDetailCtrlProvide(
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
    // console.log(storage);
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
	// console.log($scope.current_page);
	$scope.save_to_local();
	$scope.filter_firms = diabloPagination.get_page($scope.current_page);
    }

    // console.log($scope.search);
    
    $scope.do_search = function(search){
	// console.log(search); 
	$scope.search = search;
    	return $scope.firms.filter(function(f){
	    // console.log(f);
	    return -1 !== f.name.indexOf(search)
		||  -1 !== f.address.indexOf(search)
		|| -1 !== f.code.toString().indexOf(search);
	    // search === f.name
	    // // || search === f.mobile 
	    // 	|| search === f.address
	    // 	|| search === f.code
	}) 
    };

    var reset_pagination = function(firms, search){
	diablo_order(firms);
	diabloPagination.set_data(firms);
	diabloPagination.set_items_perpage($scope.items_perpage);
	$scope.total_items  = diabloPagination.get_length();
	$scope.filter_firms = diabloPagination.get_page($scope.current_page);
	$scope.save_to_local(search, $scope.total_items);
    }

    var get_filter_firm = function(search){
	var filters;
	if (angular.isDefined(search)){
	    filters = $scope.do_search(search);
	} else {
	    filters = $scope.firms; 
	};

	filters = filters.sort(function(f1, f2){
	    if ($scope.sort_field.balance.sort_desc){
	    	return f2.balance - f1.balance; 
	    } else {
	    	return f1.balance - f2.balance; 
	    }
	});

	$scope.sort_field.balance.sort_desc = !$scope.sort_field.balance.sort_desc;

	return filters;
    }

    $scope.on_select_firm = function(item, model, label){
	var filters = $scope.do_search(item.name); 
	$scope.total_balance = 0;
	angular.forEach(filters, function(f){$scope.total_balance += f.balance});
	
	$scope.total_balance = diablo_rdight($scope.total_balance, 2); 
	reset_pagination(filters, item.name);
    };

    $scope.match_firm = function(match){
	$scope.on_select_firm({name:match});
    };
    
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
	    $scope.prompts = []; 
	    angular.forEach($scope.firms, function(f){
		$scope.total_balance += f.balance;
		f.code = 1000 + f.id;

		if (!in_prompt(f.name, $scope.prompts)){
		    $scope.prompts.push({name: f.name, py:diablo_pinyin(f.name)}); 
		}
		if (!in_prompt(f.address, $scope.prompts)){
		    $scope.prompts.push({name: f.address, py:diablo_pinyin(f.address)}); 
		}
		// if (!in_prompt(f.mobile, $scope.prompts)){
		//     $scope.prompts.push({name: f.mobile, py:diablo_pinyin(f.mobile)}); 
		// }

		if (!in_prompt(f.code, $scope.prompts)){
		    $scope.prompts.push({name: f.code, py:f.code}); 
		}
	    }); 
	    $scope.total_balance = diablo_rdight($scope.total_balance, 2);

	    var filters = get_filter_firm(search); 
	    reset_pagination(filters, search);
	    
	    // for(var i=0, l=$scope.firms.length; i<l; i++){
	    // 	var f = $scope.firms[i];

	    // 	if (!in_prompt(f.name, $scope.prompts)){
	    // 	    $scope.prompts.push({name: f.name, py:diablo_pinyin(f.name)}); 
	    // 	}
	    // 	if (!in_prompt(f.address, $scope.prompts)){
	    // 	    $scope.prompts.push({name: f.address, py:diablo_pinyin(f.address)}); 
	    // 	}
	    // 	if (!in_prompt(f.mobile, $scope.prompts)){
	    // 	    $scope.prompts.push({name: f.mobile, py:diablo_pinyin(f.mobile)}); 
	    // 	} 
	    // } 

	    // console.log($scope.current_page);
	});
    }

    $scope.sort_field ={balance:{sort_desc:true}};
    $scope.sort_balance = function(){
	// console.log($scope.search);
	var filters = get_filter_firm($scope.search);
	// console.log(filters);
	reset_pagination(filters, undefined);
    };
    
    $scope.do_refresh($scope.current_page, $scope.search); 

    $scope.new_firm = function(){location.href = "#/new_firm";};

    $scope.trans_info = function(f){
	// console.log(f);
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

		update.balance     = params.firm.balance;
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
	
    };

    $scope.export_firm = function() {
	firmService.export_w_firm().then(function(state){
	    if (state.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "文件导出成功",
		    "创建文件成功，请点击确认下载！！",
		    undefined,
		    function(){window.location.href = state.url;})
	    } else {
		dialog.response(
		    false, "文件导出失败", "创建文件失败："
			+ firmService.error[state.ecode]);
	    }
	})
    };
};


define(["firmApp"], function(app){
    app.controller("firmNewCtrl", firmNewCtrlProvide);
    app.controller("firmDetailCtrl", firmDetailCtrlProvide);
});
