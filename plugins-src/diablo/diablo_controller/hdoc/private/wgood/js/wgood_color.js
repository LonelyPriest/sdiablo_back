wgoodApp.controller("wgoodColorDetailCtrl", function(
    $scope, diabloUtilsService, diabloFilter, diabloPattern,
    wgoodService, filterColorType, filterColor){
    $scope.colorTypes = angular.copy(filterColorType); 
    $scope.colors = angular.copy(filterColor);
    $scope.pattern = {color:diabloPattern.color, comment: diabloPattern.comment};

    var dialog = diabloUtilsService;

    diablo_order($scope.colors)
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
			order_id: $scope.colors.length + 1,
			id:      newColorId,
			name:    params.color.name,
			tid:     params.color.type.id,
			type:    params.color.type.name, 
			remark:  params.color.remark ? params.color.remark : "NULL"}), 
		    console.log($scope.colors); 
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
	    {color: {types: $scope.colorTypes}})
    }

    /*
     * Update
     */
    $scope.modify_color = function(color){
	console.log(color);
	var callback = function(params){
	    console.log(params);
	    // check
	    if (params.color.name === color.name
		&& params.color.type.name === color.type){
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
	    };

	    var update = {
		cid:  color.id,
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
	    {color:{name:color.name,
		    type:function(){
			return $scope.colorTypes.filter(function(t){
			    return t.name === color.type;
			})[0]; 
		    }()
		   },
	     pattern: $scope.pattern,
	     types: $scope.colorTypes})
    };

    /*
     * delete 
     */
    $scope.delete_color = function(color){
	diabloUtilsService.response(false, "删除颜色", "暂不支持此操作！！", $scope);
    };
});



