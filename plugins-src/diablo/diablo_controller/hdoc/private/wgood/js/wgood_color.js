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
    $scope.self_barcode = stockUtils.barcode_self(diablo_default_shop, base);
    console.log($scope.self_barcode);

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
	     self_barcode: $scope.self_barcode
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
		self_barcode: $scope.self_barcode,
		types: $scope.colorTypes
	    })
    };

    /*
     * delete 
     */
    $scope.delete_color = function(color){
	diabloUtilsService.response(false, "删除颜色", "暂不支持此操作！！", $scope);
    };
};


function wgoodTypeDetailCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern,
    wgoodService, filterType, base){
    $scope.goodTypes = angular.copy(filterType);
    diablo_order($scope.goodTypes); 
    $scope.self_barcode = stockUtils.barcode_self(diablo_default_shop, base);
    $scope.pattern = {
	type:diabloPattern.ch_name_address,
	barcode: diabloPattern.number_3,
    };
    
    var dialog = diabloUtilsService;
    
    $scope.new_type = function(){
	var callback = function(params){
	    console.log(params.type);
	    var goodType = {name:   params.type.name,
			    bcode:  params.type.bcode};
	    wgoodService.add_good_type(goodType).then(function(state){
		console.log(state);

		var append_type = function(typeId){
		    $scope.goodTypes.push({
			order_id: $scope.goodTypes.length + 1,
			id:      typeId,
			bcode:   stockUtils.to_integer(params.type.bcode),
			name:    params.type.name});
		};
		
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增品类", "新增品类成功！！",
			undefined,
			function(){
			    append_type(state.id);
			    diabloFilter.reset_type(); 
			});
		} else{
		    dialog.response(
			false,
			"新增类",
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
	     self_barcode: $scope.self_barcode
	    });
    };


    $scope.update_type = function(type){
	console.log(type);
	var callback = function(params){
	    console.log(params);
	    // check
	    var uBarcode = stockUtils.to_integer(params.type.bcode);
	    console.log(uBarcode);

	    if (params.type.name === type.name && uBarcode === type.bcode){
		dialog.response(
		    false, "品类编辑", wgoodService.error[2099], undefined);
		return;
	    };

	    
	    for (var i=0, l=$scope.goodTypes.length; i<l; i++){
		if (params.type.name === $scope.goodTypes[i].name
		    && params.type.name !== type.name){
		    dialog.response(
			false, "品类编辑", wgoodService.error[1908], undefined);
		    return;
		}
		
		// if (uBarcode === $scope.goodTypes[i].bcode && uBarcode !== type.bcode){
		//     dialog.response(
		// 	false, "品类编辑", wgoodService.error[1907], undefined);
		//     return;
		// }
	    };

	    var update = {
		tid:  type.id,
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
			function() {
			    type.name = params.type.name;
			    type.bcode = uBarcode; 
			    diabloFilter.reset_type();
			});
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
	    {type:{name:type.name, bcode:type.bcode},
	     pattern: $scope.pattern,
	     self_barcode: $scope.self_barcode});
    };
}

define(["wgoodApp"], function(app){
    app.controller("wgoodColorDetailCtrl", wgoodColorDetailCtrlProvide);
    app.controller("wgoodTypeDetailCtrl", wgoodTypeDetailCtrlProvide);
});



