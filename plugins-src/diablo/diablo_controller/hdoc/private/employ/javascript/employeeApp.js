'use strict'

define(["angular", "angular-router", "angular-resource",
        "angular-ui-bootstrap", "diablo-authen", "diablo-pattern", "diablo-user-right",
        "diablo-authen-right", "diablo-utils", "diablo-filter"], employeeConfig);

function employeeConfig(angular){
    var employeeApp = angular.module(
	"employeeApp",
	['ngRoute', 'ngResource', 'diabloPattern',
	 'diabloAuthenApp', 'diabloNormalFilterApp', 'userApp', 'diabloUtils', 'ui.bootstrap']
    ).config(function($httpProvider, authenProvider){
	// $httpProvider.responseInterceptors.push(authenProvider.interceptor);
	$httpProvider.interceptors.push(authenProvider.interceptor); 
    });

    employeeApp.config(['$routeProvider', function($routeProvider){
	var user = {"user": function(userService){
	    return userService()}};

	var employee = {"filterEmployee": function(diabloNormalFilter){
	    return diabloNormalFilter.get_employee()}};
	
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
	    when('/department_detail', {
		templateUrl: '/private/employ/html/department_detail.html',
		controller: 'departmentDetailCtrl',
		resolve: angular.extend({}, employee, user)
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
	    1401: "员工创建失败，已存在同样的员工手机号码！！",
	    1402: "该部门已存在，请重新输入部门名称！！",
	    1403: "该员工已加入该门，请重新选择部门或员工！！"
	};
	

	// =========================================================================    
	var employ = $resource("/employ/:operation/:id",
    			       {operation: '@operation', id: '@id'});
	// var members = $resource("/member/:operation/:number");
	this.positions = [{id:0, name: "管理员"},
			  {id:1, name: "店长"},
			  {id:2, name: "普通员工"}];

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

	this.recover = function(one){
	    return employ.delete(
		{operation: "recover_employe", id: one.id}
	    )};

	this.edit = function(one){
	    return employ.save(
		{operation: "update_employe", id: one.id}, one).$promise;
	};

	this.add_department = function(name, master, comment) {
	    return employ.save(
		{operation: "new_department"},
		{name: name, master: master, comment: comment}).$promise;
	};

	this.list_department = function() {
	    return employ.query({operation: "list_department"}).$promise;
	};

	this.add_employee_of_department = function(department, employee) {
	    return employ.save(
		{operation: "add_employee_of_department"},
		{department: department, employee:employee}).$promise;
	};

	this.del_employee_of_department = function(department, employee) {
	    return employ.save(
		{operation: "del_employee_of_department"},
		{department: department, employee:employee}).$promise;
	};

	this.list_employee_of_department = function(department) {
	    return employ.save(
		{operation: "list_employee_of_department"}, {department: department}).$promise;
	};
    }); 

    employeeApp.controller("employDetailCtrl", function(
	$scope, dateFilter, diabloPattern, diabloUtilsService, employService, user){
	$scope.shops = user.sortShops;
	$scope.goto_page = diablo_goto_page;
	$scope.positions = employService.positions;
	// console.log($scope.positions);
	
	$scope.refresh = function(){
	    employService.list().$promise.then(function(employees){
		// console.log(employees);
		angular.forEach(employees, function(e){
		    e.sex = diablo_sex2object[e.sex];
		    e.shop = diablo_get_object(e.shop_id, $scope.shops);
		    e.position = diablo_get_object(e.pos_id, $scope.positions);
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
		    shop: diablo_get_modified(n_employee.shop, o_employee.shop),
		    entry: diablo_get_modified(dateFilter(n_employee.entry, "yyyy-MM-dd"), o_employee.entry),
		    position: diablo_get_modified(n_employee.position.id, o_employee.pos_id)
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
		    && diablo_is_same(dateFilter(new_employee.entry, "yyyy-MM-dd"), o_employee.entry)
		    && diablo_is_same(new_employee.position, o_employee.position);
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
	    o_employee.position = diablo_get_object(o_employee.pos_id, $scope.positions);
	    
	    diabloUtilsService.edit_with_modal(
		"edit-employ.html", undefined, callback, $scope,
		{employee:    o_employee,
		 entry:       {
		     isOpened:false,
		     open_calendar: function(event) {
			 event.preventDefault();
			 event.stopPropagation();
		     }},
		 
		 pattern:     {name:    diabloPattern.chinese_name,
			       mobile:  diabloPattern.mobile,
			       address: diabloPattern.ch_name_address},
		 sexes:       diablo_sex2object,
		 shops:       $scope.shops,
		 positions:   $scope.positions,
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

	// recover
	$scope.recover_employ = function(employ){
	    var callback = function(){
		employService.recover(employ).$promise.then(function(state){
    		    console.log(state);
    		    if (state.ecode == 0){
			diabloUtilsService.response_with_callback(
			    true, "恢复员工",
			    "恭喜你，员工 [" + employ.name + "] 恢复成功！！", $scope,
			    function(){employ.state=0}
			);
    		    } else{
			diabloUtilsService.response(
			    false, "恢复员工",
			    "恢复员工失败：" + employService.error[state.ecode]);
    		    }
    		})
	    };
	    
	    diabloUtilsService.request(
		"恢复员工", "确定要恢复该员工吗？", callback, undefined, undefined);
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

    employeeApp.controller("departmentDetailCtrl", departmentDetailCtrlProvide);
	
    employeeApp.controller("loginOutCtrl", function($scope, $resource){
	$scope.home = function () {
	    diablo_login_out($resource)
	};
    });

    return employeeApp;
};


function departmentDetailCtrlProvide($scope, employService, diabloUtilsService, filterEmployee){
    $scope.employees = filterEmployee;
    var dialog = diabloUtilsService;

    $scope.refresh = function(){
	employService.list_department().then(function(data){
	    console.log(data); 
	    $scope.departments = angular.copy(data);
	    diablo_order($scope.departments); 
	    angular.forEach($scope.departments, function(d) {
		d.master = diablo_get_object(d.master_id, filterEmployee);
	    })
	});	
    }; 
    $scope.refresh();

    $scope.new_department = function(){
	var callback = function(params){
	    console.log(params);
	    var master = params.master;
	    employService.add_department(
		params.name,
		angular.isObject(master) && angular.isDefined(master.id) ? master.id : undefined,
		params.comment
	    ).then(function(state){
		if (state.ecode === 0){
		    dialog.response_with_callback
		    (true,
		     "新增部门",
		     "新增部门 [" + params.name + "] 成功",
		     undefined,
		     function() {$scope.refresh()});
		} else {
		    dialog.response(
			false,
			"新增部门",
			"新增部门失败：" + employService.error[state.ecode]);
		}
	    });
	};

	dialog.edit_with_modal("new-department.html", undefined, callback, $scope, {});
    };

    $scope.update_department = function(region){
	dialog.response(false, "部门编辑", "部门编辑失败：暂不支持此操作！！")
    };

    $scope.add_employee = function(department) {
	var callback = function(params) {
	    console.log(params);
	    employService.add_employee_of_department(params.department.id, params.employee.id).then(function(state){
		if (state.ecode === 0){
		    dialog.response(true, "新增部门员工", "新增部门员工[" + params.employee.name + "]成功");
		} else {
		    dialog.response(false, "新增部门员工", "新增部门员工失败：" + employService.error[state.ecode]);
		}
	    });
	};

	dialog.edit_with_modal("add-employee.html", undefined, callback, $scope, {department:department});
    };

    $scope.delete_employee_of_department = function(emp) {
	employService.del_employee_of_department(
	    emp.department, emp.employee_id
	).then(function(result) {
	    console.log(result);
	    if (result.ecode === 0) {
		dialog.response(
		    true,
		    "删除部门员工",
		    "删除部门员工[" + emp.employee.name + "]成功！！");
	    } else {
		dialog.response(
		    false,
		    "删除部门员工",
		    "删除部门员工[" + emp.employee.name + "]失败！！"
		    + employService.error[result.ecode]);
	    }
	})
    };


    var check_select_only = function(select, items){
	angular.forEach(items, function(e){
	    if (e.id !== select.id){
		e.select = false;
	    }
	})
    }
    
    $scope.list_employee = function(d) {
	employService.list_employee_of_department(d.id).then(function(result){
	    if (result.ecode === 0){
		var callback = function(params) {
		    console.log(params);
		};
		
		var employees = result.data; 
		angular.forEach(employees, function(e) {
		    e.employee = diablo_get_object(e.employee_id, $scope.employees);
		});
		
		console.log(employees);
		
		dialog.edit_with_modal(
		    "list-employee.html",
		    undefined,
		    callback,
		    undefined,
		    {department:d,
		     employees:employees,
		     check_only:check_select_only,
		     checked:function(employees) {
			 var checked = false;
			 for (var i=0, l=employees.length; i<l; i++) {
			     if (employees[i].select) {
				 checked = true;
				 break;
			     }
			     
			 }
			 return checked;
		     }, 
		     delete_employee:function(close, employees) {
			 if (angular.isFunction(close))
			     close();
			 var del_employee;
			 for (var i=0, l=employees.length; i<l; i++) {
			     if (employees[i].select) {
				 del_employee = employees[i];
				 break;
			     }
				 
			 }

			 if (angular.isDefined(del_employee))
			     $scope.delete_employee_of_department(del_employee);
		     }
		    });
	    } else {
		dialog.response(false,
				"查看部门员工",
				"查看部门员工失败：" + employService.error[result.ecode]);
	    }
	});
    };
    
};
