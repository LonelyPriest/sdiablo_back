'use strict'

function wgoodSizeDetailCtrlProvide(
    $scope, diabloPattern, diabloUtilsService, diabloFilter, wgoodService, filterSizeGroup, base){
    $scope.size_group = angular.copy(filterSizeGroup); 
    // console.log($scope.size_group);
    diablo_order($scope.size_group);
    $scope.shop_mode = stockUtils.shop_mode(diablo_default_shop, base);
    // console.log($scope.shop_mode);

    $scope.pattern = {
	size: function() {
	    if ($scope.shop_mode !== diablo_home_mode)
		return diabloPattern.size;
	    else
		return diabloPattern.home_size;
	}()
    };

    console.log($scope.pattern);
    
    $scope.refresh = function(){
	wgoodService.list_purchaser_size().then(function(groups){
	    $scope.size_group = groups.map(function(s) {
		return diablo_obj_strip(s);
	    });
	    diablo_order($scope.size_group);
	    // console.log($scope.size_group);
	})
    }
    
    /*
     * add
     */
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
	if (value) {
	    if ($scope.shop_mode !== diablo_home_mode) 
		if (diablo_invalid_index === size_to_barcode.indexOf(value))
		    return false;
	}
	
	for (var s in size){
	    if (s === 'name' || s === key) continue;

	    if (angular.isDefined(size[s]) && size[s] && size[s] === value){
		return false;
	    }
	}

	return true;
    };
    
    $scope.new_size = function(){

	var callback = function(params){
	    console.log(params);
	    var size = {};
	    for (var k in params.size){
		if (angular.isDefined(params.size[k]) && params.size[k]){
		    size[k] = params.size[k]
		}
	    }

	    console.log(size);

	    wgoodService.add_purchaser_size(size, $scope.shop_mode).then(function(state){
	        console.log(state);
	        if (state.ecode == 0){
		    var append_size_group = function(gid){
			$scope.size_group.push(
			    angular.extend({
				id:gid,
				order_id:$scope.size_group.length + 1}, size));
		    };
		    
		    diabloUtilsService.response_with_callback(
			true, "新增尺码组", "新增尺码组成功！！", $scope,
			function(){append_size_group(state.id)}); 
	        } else{
	    	diabloUtilsService.response(
	    	    false, "尺码组", "新增尺码组失败，原因："
	    		+ wgoodService.error[state.ecode]);
	        };
	    });
	}
	
	diabloUtilsService.edit_with_modal(
	    'new-size.html', undefined, callback, $scope,
	    {size: {}, valid_group: valid_group, check_same: check_same}) 
    };


    /*
     * modify
     */
    $scope.do_modify = function(g){
	// group.$editable=true;
	diabloUtilsService.response(
	    false, "修改尺码组", "暂不支持此操作！！", undefined);
    };

    /*
     * delete
     */ 
    $scope.do_delete = function(g){
	diabloUtilsService.response(
	    false, "删除尺码组", "暂不支持此操作！！",undefined);
    }
    
};


define(["wgoodApp"], function(app){
    app.controller("wgoodSizeDetailCtrl", wgoodSizeDetailCtrlProvide);
});
