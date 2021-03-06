'use strict'

function firmNewCtrlProvide(
    $scope, diabloPattern, firmService, diabloUtilsService){

    $scope.pattern = {name:       diabloPattern.ch_name_address,
		      balance:    diabloPattern.decimal_2,
		      tel_mobile: diabloPattern.tel_mobile,
		      address:    diabloPattern.ch_name_address,
		      comment:    diabloPattern.comment,
		      expire:     diabloPattern.expire_date};
    
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
    $scope, $location, $routeParams, firmService, diabloUtilsService, diabloFilter,
    diabloPagination, diabloPattern, localStorageService, user){

    $scope.pattern = {
	name:       diabloPattern.ch_name_address,
	balance:    diabloPattern.decimal_2,
	tel_mobile: diabloPattern.tel_mobile,
	address:    diabloPattern.ch_name_address,
	comment:    diabloPattern.comment,
	expire:     diabloPattern.expire_date};

    $scope.right = {
	show_orgprice: rightAuthen.authen(
	    user.type,
	    rightAuthen.rainbow_action()['show_orgprice'],
	    user.right
	),

	firm_profit: rightAuthen.authen(
	    user.type,
	    rightAuthen.firm_action()['firm_profit'],
	    user.right
	) 
    }; 

    var to_float = function(v) {
	if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
	    return 0;
	} else{
	    return parseFloat(v)
	}
    };
    
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
	    return -1 !== f.name.indexOf(search)
		||  -1 !== f.address.indexOf(search)
		|| -1 !== f.code.toString().indexOf(search); 
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
	// console.log(page); 
	$scope.current_page = page;
	$scope.search       = search;
	
	firmService.list_firm().then(function(data){
	    // console.log(data);
	    $scope.firms = angular.copy(data);
	    $scope.total_balance = 0;
	    $scope.prompts = []; 
	    angular.forEach($scope.firms, function(f){
		$scope.total_balance += f.balance;
		f.code = diablo_firm_code + f.id; 
		f.vfirm = {vid: f.vid, name: f.vname};
		
		if (!in_prompt(f.name, $scope.prompts)){
		    $scope.prompts.push({name: f.name, py:diablo_pinyin(f.name)}); 
		}
		if (!in_prompt(f.address, $scope.prompts)){
		    $scope.prompts.push({name: f.address, py:diablo_pinyin(f.address)}); 
		}
		
		if (!in_prompt(f.code, $scope.prompts)){
		    $scope.prompts.push({name: f.code, py:f.code}); 
		}
	    }); 
	    $scope.total_balance = diablo_rdight($scope.total_balance, 2);

	    var filters = get_filter_firm(search); 
	    reset_pagination(filters, search); 
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

    $scope.goto_firm_profit = function() {
	diablo_goto_page("#/firm_profit");
    };

    $scope.trans_info = function(f){
	// console.log(f);
	$scope.save_to_local(); 
	diablo_goto_page("#/firm_trans/" + f.id.toString());
    };

    $scope.bill_firm = function(f){
	diablo_goto_page("#/firm/bill/" + f.id.toString());
    };

    $scope.match_vfirm = function(view) {
	return diabloFilter.match_vfirm(view, diablo_py_or_ch_match(view));
    }; 

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
		    if (!angular.isObject(params.firm[o]) 
			&& !angular.equals(params.firm[o], old_firm[o])){
			update[o] = params.firm[o];
		    }
		}

		update.balance     = params.firm.balance;
		update.old_balance = old_firm.balance;
		update.firm_id     = params.firm.id;
		update.vid = diablo_get_modified(params.firm.vfirm.vid, old_firm.vid);
		console.log(update);

		// update.name    = params.firm.name;

		firmService.update_firm(update).then(function(result){
		    console.log(result);
		    if (result.ecode === 0){
			dialog.response_with_callback(
			    true, "厂商编辑",
			    "厂商 [" + params.firm.name + "] 编辑成功！！",
			    undefined, function() {
				diabloFilter.reset_firm();
				$scope.refresh();
			    });
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
	     match_vfirm: $scope.match_vfirm, 
	     valid_firm:valid_firm,
	     has_update: function(new_firm){
		 return !(diablo_is_same(new_firm.name, old_firm.name)
			  && diablo_is_same(to_float(new_firm.balance),
					    to_float(old_firm.balance))
			  && diablo_is_same(new_firm.address, old_firm.address)
			  && diablo_is_same(new_firm.mobile, old_firm.mobile)
			  && diablo_is_same(new_firm.comment, old_firm.comment)
			  && diablo_is_same(new_firm.expire, old_firm.expire)
			  && diablo_is_same(new_firm.vfirm.vid, old_firm.vid)
			 );
	     },
	     
	     pattern: $scope.pattern,
	     right: $scope.right})
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


function firmAnalysisProfitCtrlProvide(
    $scope, $location, $routeParams, firmService, diabloUtilsService,
    diabloFilter, diabloPagination, diabloPattern, localStorageService,
    filterFirm, filterRegion){
    $scope.regions = filterRegion;
    $scope.firms   = filterFirm;
    $scope.analysises = [];
    
    var now = stockUtils.first_day_of_month();
    $scope.time = diabloFilter.default_time(now.first, now.current);

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = diablo_max_page_size();
    $scope.default_page  = 1; 
    $scope.current_page  = $scope.default_page;
    $scope.total_items   = 0; 
    $scope.order_fields  = {sell:1, amount:5}; 
    
    $scope.filters = [];
    diabloFilter.reset_field(); 
    // diabloFilter.add_field("region",  $scope.regions);
    diabloFilter.add_field("firm",    $scope.firms);
    
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt(); 

    var select_by_firm = function(firmId, stastics){
	if (!angular.isArray(stastics)) return {};

	var filter = stastics.filter(function(s){
	    return firmId === s.firm_id;
	});

	if (filter.length === 1) return filter[0];
	return {};
    };

    $scope.mode = $scope.order_fields.sell;
    $scope.sort = 0;
    
    $scope.use_order = function(mode) {
	$scope.mode = mode;
	$scope.sort = $scope.sort === 0 ? 1 : 0; 
	$scope.do_search($scope.current_page);
    }
    
    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    firmService.analysis_profit_w_firm(
		{mode:$scope.mode, sort:$scope.sort},
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (result.ecode === 0) {
		    if (page === 1) {
			$scope.total_items = result.total;
			$scope.total_stat = result.other;
		    };
		    
		    var firms        = result.firm;
		    var sale         = result.sale;
		    var stockIn      = result.stockin;
		    var stockOut     = result.stockout;
		    // var stockAll     = result.stockall;
		    var startBalance = result.sbalance;
		    var endBalance   = result.ebalance;
		    var billBalance  = result.fbalance;
		    

		    $scope.analysises = []; 
		    angular.forEach(firms, function(f){
			var s = {firm:f};
			s.sale         = select_by_firm(f.id, sale);
			s.stockIn      = select_by_firm(f.id, stockIn);
			s.stockOut     = select_by_firm(f.id, stockOut);
			s.startBalance = select_by_firm(f.id, startBalance);
			s.endBalance   = select_by_firm(f.id, endBalance);
			s.billBalance  = select_by_firm(f.id, billBalance);
			$scope.analysises.push(s);
		    });

		    diablo_order_page(page, $scope.items_perpage, $scope.analysises);
		    console.log($scope.analysises); 
		    $scope.current_page = page;
		}
		
	    });
	});
    };

    $scope.page_changed = function(page) {
	$scope.do_search(page);
    };

    $scope.refresh = function(){
	$scope.do_search($scope.default_page);
    };

    $scope.go_back = function() {
	diablo_goto_page("#/firm_detail");
    };

    // $scope.do_search($scope.current_page);

    var dialog = diabloUtilsService;
    $scope.export_firm_profit = function() {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    firmService.export_firm_profit(
		{mode:$scope.mode, sort:$scope.sort}, search
	    ).then(function(state){
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
	}); 
    };
};

function virtualFirmCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, firmService){
    $scope.pattern = {
	name:    diabloPattern.ch_en_num_beside_underline_bars,
	comment: diabloPattern.comment,
	address: diabloPattern.ch_name_address,
    };

    $scope.max_page_size = diablo_max_page_size();
    $scope.items_perpage = diablo_items_per_page();
    $scope.default_page  = 1;
    $scope.current_page  = $scope.default_page;
    $scope.total_items   = undefined;
    
    var dialog = diabloUtilsService;

    $scope.do_search = function(page) {
	diabloFilter.do_filter($scope.filters, $scope.time, function(search){
	    firmService.filter_vfirm(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result) {
		console.log(result);
		if (result.ecode === 0){
		    if (page === $scope.default_page) {
			$scope.total_items   = result.total;
		    }
		}

		$scope.vfirms = result.data;

		diablo_order($scope.vfirms, (page - 1) * $scope.items_perpage + 1);
    		$scope.current_page = page;
	    })
	});
    };

    $scope.page_changed = function(){
	$scope.do_search($scope.current_page);
    };

    $scope.refresh = function() {
	$scope.do_search($scope.current_page);
    };

    $scope.refresh();

    $scope.new_vfirm = function(){
	var callback = function(params){
	    console.log(params.vfirm);
	    var v = {name: params.vfirm.name,
		     address: params.vfirm.address,
		     py: diablo_pinyin(params.vfirm.name), 
		     comment: params.vfirm.comment};
	    
	    firmService.new_vfirm(v).then(function(result){
		console.log(result); 
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"新增厂商大类", "新增厂商大类成功！！",
			undefined,
			function(){
			    
			});
		} else{
		    dialog.response(
			false,
			"新增厂商大类",
			"新增厂商大类失败：" + firmService.error[result.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-vfirm.html',
	    undefined,
	    callback,
	    undefined,
	    {ctype: {}, pattern: $scope.pattern});
    };


    $scope.update_vfirm = function(vfirm){
	console.log(vfirm);
	var callback = function(params){
	    console.log(params.vfirm); 
	    if (params.vfirm.name === vfirm.name
		&& params.vfirm.address === vfirm.address
		&& params.vfirm.comment === vfirm.comment){
		dialog.response(
		    false, "厂商大类编辑", firmService.error[1699], undefined);
		return;
	    }; 

	    var update = {
		fid:  vfirm.id,
		name: diablo_get_modified(params.vfirm.name, vfirm.name),
		address: diablo_get_modified(params.vfirm.address, vfirm.address),
		py:   diablo_get_modified(diablo_pinyin(params.vfirm.name), vfirm.py),
		comment: diablo_get_modified(params.vfirm.comment, vfirm.comment)
	    }; 
	    console.log(update);

	    firmService.update_vfirm(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"厂商大类编辑",
			"厂商大类编辑成功！！",
			undefined,
			function() {
			    $scope.do_search($scope.current_page);
			});
		} else {
		    dialog.response(
			false,
			"厂商大类编辑",
			"厂商大类编辑失败！！" + firmService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-vfirm.html",
	    undefined,
	    callback,
	    undefined,
	    {vfirm:{name:vfirm.name, comment:vfirm.comment}, pattern: $scope.pattern});
    };
};
    
define(["firmApp"], function(app){
    app.controller("firmNewCtrl", firmNewCtrlProvide);
    app.controller("firmDetailCtrl", firmDetailCtrlProvide);
    app.controller("firmAnalysisProfitCtrl", firmAnalysisProfitCtrlProvide);
    app.controller("virtualFirmCtrl", virtualFirmCtrlProvide);
});
