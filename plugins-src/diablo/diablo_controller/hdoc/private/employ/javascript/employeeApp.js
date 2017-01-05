'use strict'

define(["angular", "angular-router", "angular-resource", "angular-local-storage",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], employeeConfig);

function employeeConfig(angular){
    var employeeApp = angular.module(
	"employeeApp",
	['ngRoute', 'ngResource', 'diabloPattern',
	 'diabloAuthenApp', 'userApp', 'diabloUtils', 'ui.bootstrap']
    ).config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

    employeeApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
	    return userService()}};
	
	$routeProvider.
	    when('/employ_detail', {
		templateUrl: '/private/employ/html/employ_detail.html',
		controller: 'employDetailCtrl',
		resolve: angular.extend({}, user)
	    }).
	    when('/employ_new', {
		templateUrl: '/private/employ/html/employ_new.html',
		controller: 'employNewCtrl',
		resolve: angular.extend({}, user)
	    }).
	    otherwise({
		templateUrl: '/private/employ/html/employ_detail.html',
		controller: 'employDetailCtrl',
		resolve: angular.extend({}, user)
            })
    }]);

    employeeApp.service("employService", function($resource, dateFilter){
	// error information
	this.error = {
	    1401: "员工创建失败，已存在同样的员工手机号码"};

	// =========================================================================    
	var employ = $resource("/employ/:operation/:id",
    			       {operation: '@operation', id: '@id'});
	// var members = $resource("/member/:operation/:number");

	this.list = function(){
	    return employ.query({operation: "list_employe"})};

	this.query = function(employId){
	    return employ.get(
		{operation: "get_employ", id: employId}
	    )};

	this.add = function(one){
	    console.log(one);
	    return employ.save(
		{operation: "new_employe"},
		{name:      one.name,
		 sex:       one.sex.id,
		 mobile:    one.mobile,
		 address:   one.address,
		 entry:     dateFilter(one.entry, "yyyy-MM-dd"),
		 shop:      one.shop.id
		}
	    )};

	this.destroy = function(one){
	    return employ.delete(
		{operation: "delete_employe", id: one.id}
	    )};

	this.edit = function(one){
	    return employ.save(
		{operation: "update_employe", id: one.id}, one).$promise;
	};
    });


    employeeApp.controller("employDetailCtrl", function(
	$scope, diabloPattern, diabloUtilsService, employService, user){
	$scope.shops = user.sortShops;
	$scope.goto_page = diablo_goto_page;
	
	$scope.refresh = function(){
	    employService.list().$promise.then(function(employees){
		console.log(employees)
		angular.forEach(employees, function(e){
		    e.sex = diablo_sex2object[e.sex];
		    e.shop = diablo_get_object(e.shop_id, $scope.shops);
		});	    
		$scope.employees = employees;
		diablo_order($scope.employees);
	    }); 
	}

	$scope.edit_employ = function(employee){
	    var o_employee = angular.copy(employee); 
	    var callback = function(params){
		// console.log(employee);
		console.log(params.employee); 
		var n_employee = params.employee;
		var u_employee = {
		    id: employee.id,
		    name: diablo_get_modified(n_employee.name, o_employee.name),
		    sex:  diablo_get_modified(n_employee.sex, o_employee.sex),
		    mobile: diablo_get_modified(n_employee.mobile, o_employee.mobile),
		    address: diablo_get_modified(n_employee.address, o_employee.address),
		    shop: diablo_get_modified(n_employee.shop, o_employee.shop)
		}; 
		console.log(u_employee);
		
		employService.edit(u_employee).then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "员工编辑",
			    "恭喜你，员工 [" + employee.name + "] 信息修改成功！！",
			    $scope, function(){$scope.refresh()});
    		    } else{
			diabloUtilsService.response(
			    false, "员工编辑",
			    "员工编辑失败：" + employService.error[state.ecode]);
    		    }
    		})
	    };

	    var check_same = function(new_employee){
		return diablo_is_same(new_employee.name, o_employee.name)
		    && diablo_is_same(new_employee.sex, o_employee.sex)
		    && diablo_is_same(new_employee.mobile, o_employee.mobile)
		    && diablo_is_same(new_employee.address, o_employee.address)
		    && diablo_is_same(new_employee.shop, o_employee.shop)
	    };
	    
	    
	    var check_exist = function(new_employee){
		for(var i=0, l=$scope.employees.length; i<l; i++){
		    if(new_employee.name === $scope.employees[i].name
		       && new_employee.name !== o_employee.name){
			return true;
		    }
		}

		return false;
	    }

	    o_employee.sex = diablo_sex2object[o_employee.sex.id];
	    o_employee.shop = diablo_get_object(o_employee.shop_id, $scope.shops); 
	    
	    diabloUtilsService.edit_with_modal(
		"edit-employ.html", undefined, callback, $scope,
		{employee:    o_employee,
		 pattern:     {name:    diabloPattern.chinese_name,
			       mobile:  diabloPattern.mobile,
			       address: diabloPattern.ch_name_address},
		 sexes:       diablo_sex2object,
		 shops:       $scope.shops,
		 check_same:  check_same,
		 check_exist: check_exist});
	};

	// delete
	$scope.delete_employ = function(employ){
	    var callback = function(){
		employService.destroy(employ).$promise.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "删除员工",
			    "恭喜你，员工 [" + employ.name + "] 删除成功！！", $scope,
			    function(){employ.state=1}
			);
    		    } else{
			diabloUtilsService.response(
			    false, "删除员工",
			    "删除员工失败：" + employService.error[state.ecode]);
    		    }
    		})
	    };
	    
	    diabloUtilsService.request(
		"删除员工", "确定要删除该员工吗？", callback, undefined, $scope);
	};
	
	$scope.employ_delete_submit = function(){
	    // console.log($scope.selectedDeleteEmploy);
	    employService.destroy($scope.selectedDeleteEmploy).$promise
		.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
    			$scope.delete_response = function(){
    			    $scope.response_success_delete_info = "恭喜你，员工 "
				+ $scope.selectedDeleteEmploy.name + " 删除成功";
    			    return true;
    			};
			$scope.after_delete_response = function(){
    			    location.reload();
    			};
    		    } else{
    			$scope.delete_response = function(){
    			    $scope.response_error_delete_info = employService.error[state.ecode];
    			    return false;
    			}
    		    }
    		})
	};

	$scope.refresh();

    });

    employeeApp.controller("employNewCtrl", function(
	$scope, $location, diabloPattern, diabloUtilsService, employService, user){
	$scope.name_pattern = diabloPattern.chinese_name;
	$scope.mobile_pattern = diabloPattern.mobile;
	$scope.address_pattern = diabloPattern.ch_name_address; 
	$scope.shops = user.sortShops;
	$scope.sexes = diablo_sex2object;

	// canlendar
	$scope.open_calendar = function(event){
	    event.preventDefault();
	    event.stopPropagation();
	    $scope.isOpened = true; 
	}

	$scope.employ = {shop: $scope.shops[0]};
	
	// new merchant
	var dialog = diabloUtilsService;
	$scope.new_employ = function(){
	    employService.add($scope.employ).$promise.then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true, "新增员工", "恭喜你，员工 " + $scope.employ.name + " 成功创建！！",
			$scope, function(){diablo_goto_page("#/employ_detail")});
		} else{
		    dialog.response(
			false, "新增员工", "员工 [" + $scope.employ.name + "] 创建失败："
			    + employService.error[state.ecode]); 
		}
	    })};
	
	$scope.cancel = function(){
	    $location.path("/employ_detail");
	};
	
    });
    
    employeeApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {
	    diablo_login_out($resource)
	};
    });

    return employeeApp;
};




