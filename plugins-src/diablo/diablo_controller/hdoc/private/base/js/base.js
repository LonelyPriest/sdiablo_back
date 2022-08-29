'use strict'

function bankCardNewCtrlProvide($scope, baseService, diabloUtilsService){
    // console.log($scope);
    $scope.card_types = baseService.bank_card_types;
    $scope.card = {type: $scope.card_types[0]};
    
    $scope.new_card = function(){
	console.log($scope.card);
	baseService.new_card(
	    {name:$scope.card.name,
	     no:$scope.card.no,
	     bank: $scope.card.bank,
	     type: $scope.card.type.value,
	     remark: $scope.card.remark}
	).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
		    true, "新增银行卡", "恭喜您，银行卡 " + $scope.card.no + " 成功创建！！",
		    $scope, function(){diablo_goto_page("#/bank/bank_card_detail")});
	    } else{
		diabloUtilsService.response(
		    false, "新增银行卡", "新增银行卡失败：" + baseService.error[state.ecode]); 
	    }
	})
    };

    $scope.refresh = function(){
	baseService.list_card().then(function(cards){
	    console.log(cards);
	})
    }

    $scope.cancel_new_card = function(){
	diablo_goto_page("#/bank/bank_card_detail");
    }
};


function bankCardDetailCtrlProvide($scope, baseService, diabloUtilsService){
    console.log($scope); 

    $scope.goto_page = diablo_goto_page;
    var dialog = diabloUtilsService;
    
    $scope.refresh = function(){
	baseService.list_card().then(function(cards){
	    console.log(cards);
	    diablo_order(cards);
	    $scope.cards = cards;
	})
    };

    $scope.refresh();

    $scope.update_card = function(card){
	var callback = function(params){
	    console.log(params);

	    if (card.no === params.card.no && card.bank === params.card.bank){
		dialog.response(
		    false, "银行卡编辑",
		    "银行卡编辑失败：" + baseService.error[8010]);
	    } else {
		baseService.update_card(params.card).then(function(state){
		    console.log(state);
		    if (state.ecode == 0){
			dialog.response_with_callback(
			    true,
			    "银行卡编辑",
			    "银行卡 " + card.no + " 修改成功！！",
			    $scope, function(){$scope.refresh()});
		    } else{
			dialog.response(
			    false,
			    "银行卡编辑",
			    "银行卡编辑失败："
				+ baseService.error[state.ecode]); 
		    }
		})
	    } 
	};

	dialog.edit_with_modal(
	    "edit-card.html", undefined, callback, $scope, {card:card});
    };

    $scope.delete_card = function(card){

	var callback = function(){
	    baseService.delete_card(card).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"银行卡删除",
			"银行卡 " + card.no + " 删除成功！！",
			$scope, function(){$scope.refresh()});
		} else{
		    dialog.response(
			false,
			"银行卡删除",
			"银行卡删除失败：" + baseService.error[state.ecode]); 
		}
	    }) 
	};

	dialog.request(
	    "删除银行卡",
	    "确定要删除该银行卡吗？", callback, undefined, $scope); 
    }
};


function printOptionCtrlProvide(
    $scope, dateFilter, baseService, diabloPattern, diabloUtilsService, user){

    // retailer
    baseService.list_sys_wretailer().then(function(retailers){
	$scope.retailers = retailers.map(function(r){
	    return {name: r.name, id:r.id, py:r.py};
	}).concat([{name:"== 系统默认 ==", id:0}]);
	// console.log($scope.retailers);
    });

    // baseService.list_purchaser_size().then(function(sizes){
    // 	console.log(sizes);
    // 	$scope.size_groups = [{id:0, name:"== 无尺码组 =="}].concat(sizes); 
    // });
    
    $scope.shops = [
	{id: -1, name:"== 请选择店铺或仓库，默认所有店铺配置相同 =="}]
	.concat(user.sortShops, user.sortRepoes); 
    
    $scope.print_types   = baseService.print_types;
    $scope.yes_no        = baseService.yes_no;
    $scope.prompt_types  = baseService.prompt_types;
    
    var dialog = diabloUtilsService;

    $scope.shop_setting = function(shop){
	// console.log(shop);
	for(var i=0, l=$scope.settings.length; i<l; i++){
	    var s = $scope.settings[i];
	    if (shop.id === s.shop.id){
		if (s.setting.length === 0){
		    var callback = function(){
			baseService.add_shop_setting(
			    shop.id
			).then(function(result){
			    if (result.ecode == 0){
				dialog.response_with_callback(
				    true, "新增打印选项", "店铺 " + shop.name
					+ " 打印选项新增成功！！",
				    $scope, function(){$scope.refresh(shop)});
			    } else {
				dialog.response(
				    false,
				    "新增打印选项",
				    "店铺 " + shop.name
					+ " 打印选项新增失败："
					+ baseService.error[result.ecode]); 
			    }
			})
		    };
		    
		    dialog.request(
			"新增打印选项",
			"该店铺无打印选项，确定要新增打印选项吗？",
			callback, undefined, $scope);
		}
		// $scope.pformats[i].$new = false;
		return s.setting;
	    }
	}
    };

    $scope.get_object = function(id, objs){
	return diablo_get_object(parseInt(id), objs);
    };
    
    $scope.refresh = function(shop){
	baseService.list_setting(
	    baseService.print_setting
	).then(function(data){
	    // console.log(data); 
	    $scope.settings = 
		$scope.shops.map(function(s){
		    var setting = data.filter(function(d){
			return d.shop === s.id;
		    });

		    return {shop:s, setting:diablo_order(setting)};
		})
	    
	    // console.log($scope.settings);
	    $scope.select = {shop:shop, setting: $scope.shop_setting(shop)};
	})
    };

    $scope.refresh($scope.shops[0]);
    // console.log($scope.select.shop);

    var get_set_v = function(name){
	// console.log(name);
	var v = {value:undefined, comment:undefined};
	for (var i=0, l=$scope.select.setting.length; i<l; i++){
	    if (name === $scope.select.setting[i].ename){
		v.value = $scope.select.setting[i].value;
		v.comment = $scope.select.setting[i].comment;
		break;
	    }
	}
	
	return v;
    };
    
    $scope.add_setting = function(){
	var callback = function(params){
	    console.log(params.setting);
	    var s = params.setting;
	    baseService.add_setting({
		cname:   s.name.cname,
		ename:   s.name.ename,
		value:   s.value,
		remark:  s.remark,
		type:  baseService.print_setting,
		shop:  $scope.select.shop.id
	    }).then(function(result){
		console.log(result)
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"新增系统选项",
			"系统选项 " + s.name.cname + " 新增成功！！",
			$scope,
			function(){
			    $scope.refresh($scope.select.shop)});
		} else {
		    dialog.response(
			false, "新增系统选项", "新增系统选项失败："
			    + baseService.error[result.ecode]); 
		}
	    })
	}

	// console.log(baseService.option_names[0].ename);
	var default_set = get_set_v(baseService.option_names[0].ename);
	console.log(default_set);
	dialog.edit_with_modal(
	    "add-setting.html", undefined, callback, $scope,
	    {names:    baseService.option_names,
	     patterns: {tel_mobile: diabloPattern.tel_mobile,
			comment:    diabloPattern.comment},
	     setting:  {name: baseService.option_names[0],
			value: default_set.value,
			remark: default_set.remark},
	     get_set_v: get_set_v
	    });
    }
    
    $scope.update_setting = function(s){
	console.log(s);

	var callback = function(params){
	    console.log(params);

	    var setting = params.setting;

	    var update;
	    if (s.ename==="qtime_start"){
		update = dateFilter(setting.value, "yyyy-MM-dd");
	    } else if (s.ename === 's_customer'){
		update = setting.value.id;
	    } else {
		update = typeof(setting.value) === 'object'
		    ? setting.value.value : setting.value;
	    };

	    console.log(update);
	    baseService.update_setting({
		id:      setting.id,
		ename:   setting.ename,
		value:   update,
		remark:  setting.remark,
		shop:    $scope.select.shop.id
	    }).then(function(state){
		console.log(state);
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"系统选项编辑",
			"系统选项 " + s.cname + " 编辑成功！！",
			undefined,
			function(){$scope.refresh($scope.select.shop)});
		} else{
		    dialog.response(
			false,
			"系统选项编辑",
			"系统选项 " + s.cname + " 编辑失败："
			    + baseService.error[state.ecode]); 
		}
	    })
	};

	if (s.ename === 'ptype'){
	    angular.extend(s, {ptypes: $scope.print_types}); 
	};
	
	if (s.ename === 'qtypeahead'){
	    angular.extend(s, {prompt_types: $scope.prompt_types}); 
	};
	
	if (s.ename === 's_customer'){
	    angular.extend(s, {retailers: $scope.retailers});
	};
	
	if (s.ename === 'reject_negative'
	    || s.ename === 'check_sale'
	    || s.ename === 'se_pagination'
	    || s.ename === 'stock_alarm'
	    || s.ename === 'h_stock_edit'
	   ){
	    angular.extend(s, {yes_no: $scope.yes_no}); 
	};

	var v; 
	
	if (s.ename === 's_customer'){
	    v = $scope.get_object(s.value, $scope.retailers);
	};

	var qtime = {};
	if (s.ename === 'qtime_start'){
	    qtime.isOpened = false;
	    qtime.open_calendar = function(event){
		event.preventDefault();
		event.stopPropagation();
	    };
	}; 
	
	dialog.edit_with_modal(
	    "edit-setting.html", undefined, callback, $scope,
	    {setting:    s,
	     init_v:     v,
	     qtime:      qtime,
	     to_i:       diablo_set_integer,
	     patterns: {tel_mobile: diabloPattern.tel_mobile,
			remark:    diabloPattern.comment}});
    };

    $scope.delete_setting = function(shop){
	console.log(shop);
	if (shop.id === diablo_invalid_index){
	    dialog.response(false, "删除系统配置项", "删除系统配置项失败：不能系统默认配置项！！")
	} else {
	    baseService.delete_setting(shop.id).then(function(result){
		if (result.ecode === 0){
		    dialog.response_with_callback(
			true,
			"删除系统配置项",
			"删除系统配置项成功！！",
			undefined,
			function(){$scope.refresh($scope.shops[0])}
		    )
		} else {
		    dialog.response(
			false,
			"删除系统配置项",
			"删除系统配置项 " + shop.name + " 删除失败："
			    + baseService.error[result.ecode]); 
		}
	    });
	};
    };
};


function basePrinterConnectNewCtrlProvide(
    $scope, diabloPattern, wprintService, diabloUtilsService, user){
    // console.log(user);
    $scope.shops = [].concat(user.sortShops, user.sortRepoes);
    // console.log($scope.shops);

    $scope.paper_columns = wprintService.paper_columns;
    $scope.paper_heights = wprintService.paper_heights;
    
    $scope.printer = {
	column: $scope.paper_columns[0],
	height: $scope.paper_heights[0]
    }; 

    // printer
    wprintService.list_wprinter().then(function(printers){
	console.log(printers);
	$scope.brands = printers.map(function(p){
	    return {id      :p.id,
		    brand   :p.brand,
		    model   :p.model,
		    column  :p.col_width,
		    remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model}
	});
	
	if ($scope.brands.length !== 0){
	    $scope.printer.brand = $scope.brands[0];
	}
    });
    
    // server
    wprintService.list_wprint_server().then(function(servers){
	console.log(servers);
	$scope.servers = servers.map(function(s){
	    return {id: s.id, name:s.name}
	});
	
	if ($scope.servers.length !== 0){
	    $scope.printer.server = $scope.servers[0]
	};
    }); 

    $scope.new_printer = function(){
	console.log($scope.printer);
	wprintService.new_wprinter_conn($scope.printer).then(function(state){
	    console.log(state);
	    if (state.ecode == 0){
		diabloUtilsService.response_with_callback(
	    	    true, "打印机关联",
		    "打印机 " + $scope.printer.sn + " 关联成功！！",
	    	    $scope,
		    function(){diablo_goto_page("#/printer/connect_detail");});
	    } else{
		diabloUtilsService.response(
	    	    false, "打印机关联",
	    	    "打印机关联失败：" + wprintService.error[state.ecode]);
	    };
	})
    };

    $scope.cancel = function(){
	diablo_goto_page("#/print/connect_detail");
    }   
};


function basePrinterConnectDetailCtrlProvide(
    $scope, $q, $location, wprintService, diabloPromise, diabloUtilsService, user){
    // $scope.shops = user.sortShops;
    $scope.shops = [].concat(user.sortShops, user.sortRepoes);
    $scope.goto_page = diablo_goto_page;
    $scope.print_status = wprintService.print_status;

    $scope.master = user.type === 1 ? true : false;
    
    var dialog = diabloUtilsService; 
    $scope.refresh = function(){
	wprintService.list_wprinter_conn().then(function(printers){
	    console.log(printers); 
	    $scope.printers = printers;
	    angular.forEach($scope.printers, function(p){
		p.brand_chinese = wprintService.get_chinese_brand(p.brand)
	    });
	    diablo_order($scope.printers);
	});
    };
    

    $scope.refresh();

    $scope.test_printer = function(p){
	console.log(p);
	wprintService.test_printer(p).then(function(result){
	    console.log(result);
	    if (result.ecode === 0){
		dialog.response(
		    true, "打印机测试", "打印机测试成功，请等待打印！！", $scope);
	    } else{
		var error = "";
		angular.forEach(result.einfo, function(e){
		    console.log(wprintService.error[e.ecode]);
		    error += (e.device ? "[" + e.device + "]":"") + wprintService.error[e.ecode]
		});
		
		dialog.response(
		    false, "打印机测试", "打印机测试失败：" + error, $scope);
	    }
	})
    };
    
    $scope.update_printer = function(p){
	console.log(p);
	var has_update = function(new_printer){
	    // console.log(new_printer);
	    if (new_printer.server.id         === p.server_id
		&& new_printer.brand.id       === p.printer_id
		&& new_printer.shop.id        === p.shop_id
		&& new_printer.column         === p.pcolumn
		&& new_printer.height         === p.pheight
		&& new_printer.sn             === p.sn
		&& new_printer.key            === p.code
		&& new_printer.status.value   === p.status){
		return false;
	    }

	    return true;
	};
	
	var promise = diabloPromise.promise;
	$q.all([
	    promise(wprintService.list_wprint_server)(),
	    promise(wprintService.list_wprinter)(),
	    // promise(wprintService.list_shop_by_merchant, p.merchant_id)()
	]).then(function(result){
	    console.log(result);
	    // result[0] are the servers
	    // result[1] are the printers
	    // result[2] are the shops
	    var servers = result[0].map(function(s){
		return {id:s.id, name:s.name, path:s.path};
	    });

	    var brands = result[1].map(function(p){
		return {id      :p.id,
			brand   :p.brand,
			model   :p.model,
			column  :p.col_width,
			remark  :wprintService.get_chinese_brand(p.brand) + "，" + p.model
		       }
	    });
	    
	    // var shops = result[2].map(function(s){
	    // 	return {id:s.id, name:s.name, py:diablo_pinyin(s.name)};
	    // });
	    var get_object = diablo_get_object;
	    var printer = {
		// servers: servers,
		// brands : brands,
		// shops:   shops,
		status:  $scope.print_status.filter(
		    function(s) {
			return s.value===p.status
		    })[0],
		server:  get_object(p.server_id, servers),
		brand:   get_object(p.printer_id, brands), 
		shop:    get_object(p.shop_id, $scope.shops),
		column:  p.pcolumn,
		height:  p.pheight,
		sn:      p.sn,
		key:     p.code, 
	    };

	    var callback = function(params){
	        console.log(params);

		var update = {id: p.id};
		for (var o in params.printer){
		    if (!angular.equals(params.printer[o], printer[o])){
			update[o] = params.printer[o];
		    }
		}

		console.log(update);

		wprintService.update_wprinter_conn(update).then(function(result){
		    console.log(result);
		    if (result.ecode == 0){
			dialog.response_with_callback(
			    true, "打印机编辑", "打印机关联信息修改成功！！",
			    $scope, function(){$scope.refresh()});
    		    } else{
			dialog.response(
			    false, "打印机编辑",
			    "打印机关联信息编辑失败：" + wprintService.error[result.ecode]);
    		    }
		})
	    };
	    
	    dialog.edit_with_modal(
	        "update-printer.html", undefined, callback, $scope,
		{has_update: has_update,
		 paper_columns: wprintService.paper_columns,
		 paper_heights: wprintService.paper_heights,
		 servers: servers,
		 brands:  brands,
		 shops:   $scope.shops,
		 status:  $scope.print_status, 
		 printer: printer});
	}) 
	
    };

    $scope.delete_printer = function(printer){
	var callback = function(){
	    wprintService.delete_wprinter_conn(printer.id).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    dialog.response_with_callback(
			true, "删除关联", "打印机 [" + printer.sn + "] 关联信息成功删除！！",
			$scope, function(){$scope.refresh()})
		} else{
		    dialog.response(
			false, "删除关联",
			"删除打印机关联信息失败：" + wprintService.error[result.ecode], $scope);
		}
	    })
	};
	
	dialog.request(
	    "删除打印机关联信息", "确定要删除该打印机关联信息吗？", callback, undefined, $scope);
    }
};


function resetPasswdCtrlProvide($scope, diabloPattern, diabloUtilsService, baseService){
    $scope.passwd_pattern = diabloPattern.passwd;

    var dialog = diabloUtilsService;

    $scope.ok = function(){
	console.log($scope.p);

	if ($scope.p.newp !== $scope.p.checkp){
	    dialog.response(
		false, "密码重置", "密码重置失败：两次输入密码不匹配，请重新输入！！", undefined);
	} else {
	    baseService.reset_passwd($scope.p).then(function(result){
		console.log(result);
		if (result.ecode == 0){
		    dialog.response(
			true, "密码重置", "密码重置成功！！", undefined);
		} else{
		    dialog.response(
			false, "密码重置失败", "密码重置失败："
			    + baseService.error[result.ecode], undefined);
		}
	    });
	}
    }
};


function goodStdStandardCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService){
    $scope.pattern = {
	name:    diabloPattern.char_number_space_slash_bar,
    }; 
    var dialog = diabloUtilsService;

    $scope.refresh = function() {
	baseService.list_std_executive().then(function(es) {
	    console.log(es);
	    diablo_order(es);
	    $scope.es = es; 
	});
    };

    $scope.refresh(); 
    $scope.new_std_executive = function(){
	var callback = function(params){
	    console.log(params.type);
	    var t = {name:   params.std.name};
	    baseService.add_std_executive(t).then(function(state){
		console.log(state); 
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增执行标准", "新增执行标准成功！！",
			undefined,
			function(){
			    diabloFilter.reset_good_std_executive();
			    $scope.refresh(); 
			});
		} else{
		    dialog.response(
			false,
			"新增执行标准",
			"新增执行标准失败：" + baseService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-std-executive.html',
	    undefined,
	    callback,
	    undefined,
	    {std: {}, pattern: $scope.pattern});
    };


    $scope.update_executive = function(e){
	console.log(e);
	var callback = function(params){
	    console.log(params); 
	    if (params.std.name === e.name){
		dialog.response(
		    false, "执行标准编辑", baseService.error[8010], undefined);
		return;
	    };

	    
	    for (var i=0, l=$scope.es.length; i<l; i++){
		if (params.std.name === $scope.es[i].name && params.std.name !== e.name){
		    dialog.response(
			false, "执行标准编辑", baseService.error[8005], undefined);
		    return;
		} 
	    };

	    var update = {
		eid:  e.id,
		name: diablo_get_modified(params.std.name, e.name)}; 
	    console.log(update);

	    baseService.update_std_executive(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"执行标准编辑",
			"执行标准编辑成功！！",
			undefined,
			function() {
			    e.name = params.std.name;
			    diabloFilter.reset_good_std_executive();
			});
		} else {
		    dialog.response(
			false,
			"执行标准编辑",
			"执行标准编辑失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-std-executive.html",
	    undefined,
	    callback,
	    undefined,
	    {std:{name:e.name}, pattern: $scope.pattern});
    };
};


function goodSafetyCategoryCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService){
    $scope.pattern = {
	name:    diabloPattern.char_number_space_chinese,
    }; 
    var dialog = diabloUtilsService;

    $scope.refresh = function() {
	baseService.list_safety_category().then(function(cs) {
	    console.log(cs);
	    diablo_order(cs);
	    $scope.categories = cs; 
	});
    };

    $scope.refresh(); 
    $scope.new_safety_category = function(){
	var callback = function(params){
	    console.log(params.category);
	    var c = {name:   params.category.name};
	    baseService.add_safety_category(c).then(function(state){
		console.log(state); 
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增安全类别", "新增安全类别成功！！",
			undefined,
			function(){
			    diabloFilter.reset_good_safety_category();
			    $scope.refresh(); 
			});
		} else{
		    dialog.response(
			false,
			"新增安全类别",
			"新增安全类别失败：" + baseService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-safety-category.html',
	    undefined,
	    callback,
	    undefined,
	    {categroy: {}, pattern: $scope.pattern});
    };


    $scope.update_category = function(c){
	console.log(c);
	var callback = function(params){
	    console.log(params.category); 
	    if (params.category.name === c.name){
		dialog.response(
		    false, "安全类别编辑", baseService.error[8010], undefined);
		return;
	    };

	    
	    for (var i=0, l=$scope.categories.length; i<l; i++){
		if (params.category.name === $scope.categories[i].name
		    && params.category.name !== c.name){
		    dialog.response(
			false, "安全类别编辑", baseService.error[8006], undefined);
		    return;
		} 
	    };

	    var update = {
		cid:  c.id,
		name: diablo_get_modified(params.category.name, c.name)}; 
	    console.log(update);

	    baseService.update_safety_category(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"安全类别编辑",
			"安全类别编辑成功！！",
			undefined,
			function() {
			    c.name = params.category.name;
			    diabloFilter.reset_good_safety_category();
			});
		} else {
		    dialog.response(
			false,
			"安全类别编辑",
			"安全类别编辑失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-safety-category.html",
	    undefined,
	    callback,
	    undefined,
	    {category:{name:c.name}, pattern: $scope.pattern});
    };
};


function goodFabricCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService){
    $scope.pattern = {
	name:    diabloPattern.ch_en_num,
    }; 
    var dialog = diabloUtilsService;

    $scope.refresh = function() {
	baseService.list_fabric().then(function(fabrics) {
	    console.log(fabrics);
	    diablo_order(fabrics);
	    $scope.fabrics = fabrics; 
	});
    };

    $scope.refresh(); 
    $scope.new_fabric = function(){
	var callback = function(params){
	    console.log(params.fabric);
	    var c = {name: params.fabric.name};
	    baseService.add_fabric(c).then(function(state){
		console.log(state); 
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增面料", "新增面料成功！！",
			undefined,
			function(){
			    diabloFilter.reset_good_fabric();
			    $scope.refresh(); 
			});
		} else{
		    dialog.response(
			false,
			"新增面料",
			"新增面料失败：" + baseService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-fabric.html',
	    undefined,
	    callback,
	    undefined,
	    {categroy: {}, pattern: $scope.pattern});
    };


    $scope.update_fabric = function(f){
	console.log(f);
	var callback = function(params){
	    console.log(params.fabric); 
	    if (params.fabric.name === f.name){
		dialog.response(
		    false, "面料编辑", baseService.error[8010], undefined);
		return;
	    };

	    
	    for (var i=0, l=$scope.fabrics.length; i<l; i++){
		if (params.fabric.name === $scope.fabrics[i].name && params.fabric.name !== f.name){
		    dialog.response(
			false, "面料编辑", baseService.error[8007], undefined);
		    return;
		} 
	    };

	    var update = {
		fid:  f.id,
		name: diablo_get_modified(params.fabric.name, f.name)}; 
	    console.log(update);

	    baseService.update_fabric(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"面料编辑",
			"面料编辑成功！！",
			undefined,
			function() {
			    f.name = params.fabric.name;
			    diabloFilter.reset_good_fabric();
			});
		} else {
		    dialog.response(
			false,
			"面料编辑",
			"面料编辑失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-fabric.html",
	    undefined,
	    callback,
	    undefined,
	    {fabric:{name:f.name}, pattern: $scope.pattern});
    };
};


function goodPrintTemplateCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService, user){
    var dialog = diabloUtilsService;
    $scope.shops = [{id: -1, name:"默认店铺"}].concat(user.sortShops);

    $scope.pattern = {name:diabloPattern.ch_en_num};

    $scope.refresh = function() {
	baseService.list_print_template().then(function(templates) {
	    console.log(templates);
	    if (templates.length !== 0) {
		$scope.o_templates = angular.copy(templates);
		$scope.templates  = templates; 
		angular.forEach($scope.templates, function(t) {
		    t.tshop = diablo_get_object(t.tshop_id, $scope.shops); 
		    t.tname = t.tshop.name + "-" + t.name;
		});

		$scope.template = $scope.templates[0];
		console.log($scope.templates); 
	    } 
	});
    };

    $scope.refresh();

    var p = ["name", "label", "width", "height"
	     
	     , "shop", "style_number", "brand", "type", "stock", "firm", "code_firm"

	     , "p_virprice", "p_tagprice"
	     
	     , "expire", "shift_date" , "color", "size", "size_spec"
	     
	     , "level", "executive", "category", "fabric", "feather"
	     
	     , "font", "font_name", "font_executive", "font_category"
	     , "font_price", "font_size", "font_fabric", "font_feather"
	     , "font_label", "font_type", "font_sn"
	     
	     , "bold" 
	     , "solo_brand", "solo_color", "solo_size", "solo_date"
	     
	     , "hpx_each", "hpx_executive", "hpx_category", "hpx_fabric", "hpx_feather"
	     , "hpx_price", "hpx_size", "hpx_barcode", "hpx_label", "hpx_type", "hpx_sn"
	     
	     , "hpx_top", "hpx_left", "second_space"
	     
	     , "solo_snumber", "len_snumber", "count_type"
	     
	     , "size_date", "size_color", "firm_date"

	     , "tag_price", "vir_price", "my_price", "self_brand"
	     
	     , "offset_size", "offset_color"
	     , "offset_tagprice", "offset_virprice" , "offset_myprice"
	     , "offset_label" , "offset_type", "offset_fabric", "offset_fabric3"
	     , "offset_feather", "offset_barcode", "offset_sn"

	     , "printer", "dual_print"
	     
	     , "barcode", "w_barcode"];
    
    $scope.save_template = function() {
	var update = {};
	var o_template = diablo_get_object($scope.template.id, $scope.o_templates);
	console.log($scope.template);
	angular.forEach(p, function(o) {
	    if ($scope.template[o] !== o_template[o]) {
		update[o] = $scope.template[o]
	    }
	});
	if (diablo_is_empty(update)) {
	    dialog.response(
		false,
		"打印模板编辑",
		"打印模板编辑失败！！" + baseService.error[8010],
		undefined);
	    return;
	};
	
	console.log(update); 
	update.id = $scope.template.id;
	baseService.update_print_template(update).then(function(result){
	    if (result.ecode === 0) {
		dialog.response_with_callback(
		    true,
		    "打印模板编辑",
		    "打印模板编辑成功！！",
		    undefined,
		    function() {
			$scope.refresh();
			diabloFilter.reset_print_template();
		    });
	    } else {
		dialog.response(
		    false,
		    "打印模板编辑",
		    "打印模板编辑失败！！" + baseService.error[result.ecode],
		    undefined);
	    };
	});
    };

    $scope.create_template = function() {
	var callback = function(params) {
	    console.log(params);
	    baseService.create_print_template(
		params.shop.id, params.name
	    ).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"打印模板创建",
			"打印模板创建成功！！",
			undefined,
			function() {
			    $scope.refresh();
			    // diabloFilter.reset_print_template();
			});
		} else {
		    dialog.response(
			false,
			"打印模板创建",
			"打印模板创建失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "new-template.html",
	    undefined,
	    callback,
	    undefined,
	    {shop:$scope.shops[0], shops: $scope.shops, pattern:$scope.pattern});
    }
};

function goodCTypeCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService){
    $scope.pattern = {
	name:    diabloPattern.ch_en_num,
	spec:    diabloPattern.size_specific
    }; 
    var dialog = diabloUtilsService;

    $scope.refresh = function() {
	baseService.list_ctype().then(function(ctypes) {
	    console.log(ctypes);
	    diablo_order(ctypes);
	    $scope.ctypes = ctypes; 
	});
    };

    $scope.refresh(); 
    $scope.new_ctype = function(){
	var callback = function(params){
	    console.log(params.ctype);
	    var c = {name: params.ctype.name};
	    baseService.add_ctype(c).then(function(state){
		console.log(state); 
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增大类", "新增货品大类成功！！",
			undefined,
			function(){
			    diabloFilter.reset_good_ctype();
			    $scope.refresh(); 
			});
		} else{
		    dialog.response(
			false,
			"新增大类",
			"新增大类失败：" + baseService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-ctype.html',
	    undefined,
	    callback,
	    undefined,
	    {ctype: {}, pattern: $scope.pattern});
    };


    $scope.update_ctype = function(c){
	console.log(c);
	var callback = function(params){
	    console.log(params.ctype); 
	    if (params.ctype.name === c.name){
		dialog.response(
		    false, "大类编辑", baseService.error[8010], undefined);
		return;
	    };
	    
	    for (var i=0, l=$scope.ctypes.length; i<l; i++){
		if (params.ctype.name === $scope.ctypes[i].name && params.ctype.name !== c.name){
		    dialog.response(
			false, "大类编辑", baseService.error[8007], undefined);
		    return;
		} 
	    };

	    var update = {
		cid:  c.id,
		name: diablo_get_modified(params.ctype.name, c.name)
		// spec: diablo_get_modified(params.ctype.spec, c.spec)
	    }; 
	    console.log(update);

	    baseService.update_ctype(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"大类编辑",
			"大类编辑成功！！",
			undefined,
			function() {
			    c.name = params.ctype.name;
			    // c.spec = angular.isDefined(update.spec) ? update.spec : c.spec;
			    diabloFilter.reset_good_ctype();
			});
		} else {
		    dialog.response(
			false,
			"大类编辑",
			"大类编辑失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-ctype.html",
	    undefined,
	    callback,
	    undefined,
	    {ctype:{name:c.name}, pattern: $scope.pattern});
    };
};


function goodSizeSpecCtrlProvide(
    $scope, diabloUtilsService, diabloFilter, diabloPattern, baseService, filterCType){
    $scope.pattern = {
	name:    diabloPattern.size,
	spec:    diabloPattern.size_specific}; 
    $scope.ctypes = filterCType;
    
    var dialog = diabloUtilsService;

    $scope.refresh = function() {
	baseService.list_size_spec().then(function(specs) {
	    console.log(specs);
	    diablo_order(specs);
	    $scope.specs = specs;
	    angular.forEach($scope.specs, function(s){
		s.ctype = diablo_get_object(s.cid, $scope.ctypes);
	    }); 
	});
    };

    $scope.refresh(); 
    $scope.new_size_spec = function(){
	var callback = function(params){
	    console.log(params.size);
	    var s = {name:  params.size.name,
		     spec:  params.size.spec,
		     cid:   params.size.ctype.id}; 
	    baseService.add_size_spec(s).then(function(state){
		console.log(state); 
		if (state.ecode == 0){
		    dialog.response_with_callback(
			true,
			"新增尺码规格", "新增尺码规格成功！！",
			undefined,
			function(){
			    diabloFilter.reset_good_size_spec();
			    $scope.refresh(); 
			});
		} else{
		    dialog.response(
			false,
			"新增尺码规格",
			"新增尺码规格失败：" + baseService.error[state.ecode]);
		}
	    })
	};
	
	dialog.edit_with_modal(
	    'new-size-spec.html',
	    undefined,
	    callback,
	    undefined,
	    {size: {ctype:$scope.ctypes[0]},
	     pattern: $scope.pattern,
	     ctypes: $scope.ctypes});
    };


    $scope.update_size_spec = function(s){
	console.log(s);
	var callback = function(params){
	    console.log(params.size); 
	    if (params.size.name === s.name
		&& params.size.spec === s.spec
		&& params.size.ctype.id === s.cid){
		dialog.response(
		    false, "尺码规格编辑", baseService.error[8010], undefined);
		return;
	    };
	    
	    // for (var i=0, l=$scope.specs.length; i<l; i++){
	    // 	if (params.size.name === $scope.specs[i].name
	    // 	    && params.size.name !== s.name
	    // 	    && params.size.ctype.id === s.cid){
	    // 	    dialog.response(
	    // 		false, "尺码规格编辑", baseService.error[8007], undefined);
	    // 	    return;
	    // 	} 
	    // };

	    var update = {
		sid:  s.id,
		name: diablo_set_string(params.size.name),
		spec: diablo_get_modified(params.size.spec, s.spec),
		cid:  params.size.ctype.id,
	    }; 
	    console.log(update);

	    baseService.update_size_spec(update).then(function(result){
		if (result.ecode === 0) {
		    dialog.response_with_callback(
			true,
			"尺码规格编辑",
			"尺码规格编辑成功！！",
			undefined,
			function() {
			    // s.name = params.size.name;
			    // s.spec = params.size.spec;
			    // s.ctype = params.size.ctype;
			    // s.cid   = params.size.ctype.id;
			    $scope.refresh();
			    diabloFilter.reset_good_size_spec();
			});
		} else {
		    dialog.response(
			false,
			"尺码规格编辑",
			"尺码规格编辑失败！！" + baseService.error[result.ecode],
			undefined);
		};
	    });
	};
	
	dialog.edit_with_modal(
	    "update-size-spec.html",
	    undefined,
	    callback,
	    undefined,
	    {size: {name:s.name, spec:s.spec, ctype:s.ctype},
	     pattern: $scope.pattern,
	     ctypes: $scope.ctypes});
    };
};

function printerDetectCtrlProvide($scope, diabloUtilsService, user, base){
    var LODOP;
    var dialog = diabloUtilsService;
    var print_protocal = diablo_set_integer(diablo_base_setting(
	"pum", user.loginShop, base, function(s) {return s}, diablo_print_num).charAt(2));

    if (needCLodop()) loadCLodop(angular.isUndefined(print_protocal) || print_protocal === 0 ? 0 : 1);

    $scope.refresh = function() {
	if (angular.isUndefined(LODOP))
	    LODOP = getLodop(); 
	if (LODOP.CVERSION) {
	    $scope.printers = [];
	    var count = LODOP.GET_PRINTER_COUNT();
	    for (var i=0; i<count; i++) {
		var pName = LODOP.GET_PRINTER_NAME(i);
		var pSize = LODOP.GET_PRINTER_NAME(i.toString() + ":PaperSize");
		var pWidth = LODOP.GET_PRINTER_NAME(i.toString() + ":PaperWidth");
		var pHeight = LODOP.GET_PRINTER_NAME(i.toString() + ":PaperLength"); 
		$scope.printers.push({index:i, name:pName, size:pSize, width:pWidth, height:pHeight});
	    }
	}
    }

    $scope.design = function(p) {
	LODOP = getLodop();
	LODOP.PRINT_INIT("task_print_design");
	LODOP.SET_PRINTER_INDEX(p.index);
	LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
	if (LODOP.CVERSION) {
	    LODOP.PRINT_DESIGN()
	}
    }
};

// function downloadStockFixCtrlProvide($scope, diabloUtilsService, baseService) {
//     var dialog = diabloUtilsService;
//     baseService.download_stock_fix().then(function(result) {
// 	console.log(result);
// 	if (result.ecode === 0) {
// 	    $scope.download_url = result.url;
// 	    // dialog.response_with_callback(
// 	    // 	true,
// 	    // 	"盘点软件更新",
// 	    // 	"获取软件成功，请点击确认下载！！", undefined,
// 	    // 	function(){window.location.href = result.url;}) 
// 	} else {
// 	    diablo.response(
// 		false,
// 		"盘点软件更新",
// 		"获取软件失败："
// 		    + baseService.error[result.ecode]);
// 	}
//     });
// };
    
define(["baseApp"], function(app){
    app.controller("bankCardNewCtrl", bankCardNewCtrlProvide);
    app.controller("bankCardDetailCtrl", bankCardDetailCtrlProvide);
    app.controller("printOptionCtrl", printOptionCtrlProvide); 
    app.controller("basePrinterConnectNewCtrl", basePrinterConnectNewCtrlProvide);
    app.controller("basePrinterConnectDetailCtrl", basePrinterConnectDetailCtrlProvide);

    app.controller("goodStdStandardCtrl", goodStdStandardCtrlProvide);
    app.controller("goodSafetyCategoryCtrl", goodSafetyCategoryCtrlProvide);
    app.controller("goodFabricCtrl", goodFabricCtrlProvide);
    app.controller("goodPrintTemplateCtrl", goodPrintTemplateCtrlProvide);

    app.controller("goodCTypeCtrl", goodCTypeCtrlProvide);
    app.controller("goodSizeSpecCtrl", goodSizeSpecCtrlProvide);
    
    app.controller("printerDetectCtrl", printerDetectCtrlProvide);
    app.controller("resetPasswdCtrl", resetPasswdCtrlProvide);
});
