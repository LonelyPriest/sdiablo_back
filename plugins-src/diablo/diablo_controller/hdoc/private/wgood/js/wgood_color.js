'use strict'

function wgoodColorDetailCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern,
    wgoodService, filterColorType, filterColor, base){
    $scope.colorTypes = angular.copy(filterColorType); 
    $scope.colors = angular.copy(filterColor);
    $scope.pattern = {
	color:diabloPattern.color,
	comment: diabloPattern.comment,
	barcode: diabloPattern.number_3,
    };
    $scope.auto_barcode = stockUtils.auto_barcode(diablo_default_shop, base);
    console.log($scope.auto_barcode);

    var dialog = diabloUtilsService;

    diablo_order($scope.colors);
    $scope.new_color = function(){
	var callback = function(params){
	    console.log(params.color);
	    var color = {name:   params.color.name,
			 bcode:  params.color.bcode,
			 type:   params.color.type.id,
			 remark: params.color.remark};
	    wgoodService.add_purchaser_color(color).then(function(state){
		console.log(state);

		var append_color = function(newColorId){
		    $scope.colors.push({
			order_id: $scope.colors.length + 1,
			id:      newColorId,
			bcode:   params.color.bcode,
			name:    params.color.name,
			tid:     params.color.type.id,
			type:    params.color.type.name, 
			remark:  params.color.remark ? params.color.remark : "NULL"});
		    // console.log($scope.colors); 
		};
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增颜色", "新增颜色成功！！",
			undefined,
			function(){
			    append_color(state.id);
			    diabloFilter.reset_color(); 
			});
		} else{
		    dialog.response(
			false,
			"新增颜色",
			"新增颜色失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-color.html',
	    undefined,
	    callback,
	    undefined,
	    {color: {types: $scope.colorTypes},
	     pattern: $scope.pattern,
	     auto_barcode: $scope.auto_barcode
	    });
    };

    /*
     * Update
     */
    $scope.modify_color = function(color){
	console.log(color);
	var callback = function(params){
	    console.log(params);
	    // check
	    var uBarcode = stockUtils.to_integer(params.color.bcode);
	    if (params.color.name === color.name
		&& params.color.type.name === color.type
		&& uBarcode === color.bcode){
		dialog.response(
		    false, "颜色编辑", wgoodService.error[2099], undefined);
		return;
	    };
	    
	    for (var i=0, l=$scope.colors.length; i<l; i++){
		if (params.color.name === $scope.colors[i].name
		    && params.color.name !== color.name){
		    dialog.response(
			false, "颜色编辑", wgoodService.error[1901], undefined);
		    return;
		}

		if (uBarcode === $scope.colors[i].bcode && uBarcode !== color.bcode){
		    dialog.response(
			false, "颜色编辑", wgoodService.error[1905], undefined);
		    return;
		}
	    };

	    var update = {
		cid:  color.id,
		bcode: diablo_get_modified(uBarcode, color.bcode),
		name: diablo_get_modified(params.color.name, color.name),
		type: params.color.type.name === color.type ? undefined:params.color.type.id,
		remark: params.color.remark ? params.color.remark:undefined};

	    console.log(update);

	    wgoodService.update_color(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"颜色编辑",
			"颜色编辑成功！！",
			undefined,
			function() {
			    color.name = params.color.name;
			    color.bcode = uBarcode;
			    color.type = params.color.type.name;
			    color.remark = params.color.remark;
			    diabloFilter.reset_color();
			});
		} else {
		    dialog.response(false,
				    "颜色编辑",
				    "颜色编辑失败！！" + wgoodService.error[result.ecode],
				    undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-color.html",
	    undefined,
	    callback,
	    undefined,
	    {
		color:{
		    name:color.name,
		    bcode:color.bcode,
		    type:function(){
			return $scope.colorTypes.filter(function(t){
			    return t.name === color.type;
			})[0]; 
		    }() 
		},
		pattern: $scope.pattern,
		auto_barcode: $scope.auto_barcode,
		types: $scope.colorTypes
	    })
    };

    /*
     * delete 
     */
    $scope.delete_color = function(color){
	console.log(color);
	diabloUtilsService.response(false, "删除颜色", "暂不支持此操作！！", $scope);
	// var callback = function() {
    // 	    wgoodService.delete_color(color.id).then(function(result) {
    // 		if (result.ecode === 0) {
    // 		    dialog.response_with_callback(
    // 			true,
    // 			"删除颜色",
    // 			"删除颜色成功！！",
    // 			undefined,
    // 			function() {
    // 			    $scope.colors = $scope.colors.filter(function(c) {
    // 				return c.id !== color.id;
    // 			    });
    // 			    diabloFilter.reset_color();
    // 			});
    // 		} else {
    // 		    dialog.response(false,
    // 				    "颜色编辑",
    // 				    "颜色编辑失败！！" + wgoodService.error[result.ecode],
    // 				    undefined);
    // 		};
    // 	    });
    // 	};
    // 	dialog.request("删除颜色", "确认要删除颜色吗？", callback, undefined, undefined);
    };
};


function wgoodTypeDetailCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern,
    wgoodService, filterCType, base){
    // $scope.goodTypes = angular.copy(filterType);
    // console.log($scope.goodTypes);
    $scope.ctypes = [{id:-1, name:"===请选择大类==="}].concat(filterCType);

    // angular.forEach($scope.goodTypes, function(t) {
    // 	t.ctype = diablo_get_object(t.cid, $scope.ctypes);
    // });
    
    // diablo_order($scope.goodTypes);
    
    $scope.auto_barcode = stockUtils.auto_barcode(diablo_default_shop, base);
    $scope.pattern = {
	type:diabloPattern.ch_name_address,
	barcode: diabloPattern.number_3
    };

    $scope.match_prompt_type = function(viewValue) {
	return diabloFilter.match_prompt_type(viewValue, diablo_is_ascii_string(viewValue));
    };
    
    var dialog = diabloUtilsService;

    $scope.page_changed = function(){
    	$scope.do_search($scope.current_page);
    }

    $scope.items_perpage = diablo_items_per_page();
    $scope.max_page_size = 15;
    $scope.default_page = 1;
    $scope.default_page = 1;
    $scope.total_items  = 0;
    $scope.current_page = $scope.default_page;

    $scope.filters = [];
    diabloFilter.reset_field();
    diabloFilter.add_field("type", $scope.match_prompt_type);
    $scope.filter = diabloFilter.get_filter();
    $scope.prompt = diabloFilter.get_prompt();

    $scope.do_search = function(page){
	diabloFilter.do_filter($scope.filters, undefined, function(search){
	    wgoodService.filter_good_type(
		$scope.match, search, page, $scope.items_perpage
	    ).then(function(result){
		console.log(result);
		if (page === 1){
		    $scope.total_items = result.total;
		}

		angular.forEach(result.data, function(t) {
		    t.ctype = diablo_get_object(t.ctype_id, $scope.ctypes);
		});
		
		$scope.good_types = result.data;
		diablo_order_page(page, $scope.items_perpage, $scope.good_types);
	    })
	});

	$scope.current_page=page;
    };

    $scope.refresh = function() {
	$scope.do_search($scope.current_page);
    };
    
    $scope.new_type = function(){
	var callback = function(params){
	    console.log(params.type);
	    var goodType = {name:   diablo_trim(params.type.name),
			    bcode:  params.type.bcode,
			    py:     diablo_pinyin(diablo_trim(params.type.name))
			   };
	    wgoodService.add_good_type(goodType).then(function(state){
		console.log(state);

		// var append_type = function(typeId){
		//     $scope.goodTypes.push({
		// 	order_id:$scope.goodTypes.length + 1,
		// 	id:      typeId,
		// 	bcode:   stockUtils.to_integer(params.type.bcode),
		// 	name:    params.type.name});
		// };
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增品类", "新增品类成功！！",
			undefined,
			function(){
			    // append_type(state.id);
			    // diabloFilter.reset_type();
			    $scope.refresh();
			});
		} else{
		    dialog.response(
			false,
			"新增品类",
			"新增品类失败：" + wgoodService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-type.html',
	    undefined,
	    callback,
	    undefined,
	    {type: {},
	     pattern: $scope.pattern,
	     auto_barcode: $scope.auto_barcode
	    });
    };


    $scope.update_type = function(type){
	console.log(type);
	var callback = function(params){
	    console.log(params);
	    // check
	    var uBarcode = stockUtils.to_integer(params.type.bcode);
	    console.log(uBarcode);

	    if (params.type.name === type.name
		&& uBarcode === type.bcode
		&& params.type.ctype.id === type.cid){
		dialog.response(
		    false, "品类编辑", wgoodService.error[2099], undefined);
		return;
	    };

	    
	    // for (var i=0, l=$scope.goodTypes.length; i<l; i++){
	    // 	if (params.type.name === $scope.goodTypes[i].name
	    // 	    && params.type.name !== type.name){
	    // 	    dialog.response(
	    // 		false, "品类编辑", wgoodService.error[1908], undefined);
	    // 	    return;
	    // 	}
		
	    // 	// if (uBarcode === $scope.goodTypes[i].bcode && uBarcode !== type.bcode){
	    // 	//     dialog.response(
	    // 	// 	false, "品类编辑", wgoodService.error[1907], undefined);
	    // 	//     return;
	    // 	// }
	    // };

	    var update = {
		tid:  type.id,
		cid:   diablo_get_modified(params.type.ctype.id, type.cid),
		bcode: diablo_get_modified(uBarcode, type.bcode),
		name: diablo_get_modified(params.type.name, type.name)}; 
	    console.log(update);

	    wgoodService.update_good_type(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"品类编辑",
			"品类编辑成功！！",
			undefined,
			$scope.refresh);
		} else {
		    dialog.response(false,
				    "品类编辑",
				    "品类编辑失败！！" + wgoodService.error[result.ecode],
				    undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-type.html",
	    undefined,
	    callback,
	    undefined,
	    {type:{name:type.name, bcode:type.bcode, ctype:type.ctype},
	     
	     pattern: $scope.pattern,
	     auto_barcode: $scope.auto_barcode,
	     ctypes: $scope.ctypes});
    };

    $scope.syn_pinyin = function() {
	var ts = [];
	angular.forEach($scope.good_types, function(t) {
	    ts.push({id:t.id, py:diablo_pinyin(t.name)});
	});

	wgoodService.syn_type_pinyin(ts).then(function(result) {
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "同步品类拼音",
		    "同步成功！！",
		    undefined,
		    function() {$scope.do_search($scope.current_page)});
	    } else {
		dialog.response(
		    true, "同步品类拼音", "同步失败！！" + wgoodService.error[result.ecode]);
	    }
	});
    };

    $scope.delete_type = function(t) {
	console.log(t);
	wgoodService.delete_good_type(t.id, diablo_delete).then(function(result) {
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "删除品类",
		    "删除成功！！",
		    undefined,
		    function() {t.deleted = diablo_yes});
	    } else {
		dialog.response(
		    true, "删除品类", "删除失败！！" + wgoodService.error[result.ecode]);
	    }
	});
    };

    $scope.recover_type = function(t) {
	console.log(t);
	wgoodService.delete_good_type(t.id, diablo_recover).then(function(result) {
	    if (result.ecode === 0){
		dialog.response_with_callback(
		    true,
		    "恢复品类",
		    "恢复成功！！",
		    undefined,
		    function() {t.deleted = diablo_no});
	    } else {
		dialog.response(
		    true, "恢复品类", "恢复失败！！" + wgoodService.error[result.ecode]);
	    }
	});
    };
};

define(["wgoodApp"], function(app){
    app.controller("wgoodColorDetailCtrl", wgoodColorDetailCtrlProvide);
    app.controller("wgoodTypeDetailCtrl", wgoodTypeDetailCtrlProvide);
});



