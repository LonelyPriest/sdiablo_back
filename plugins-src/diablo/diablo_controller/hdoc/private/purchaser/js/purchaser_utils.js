var stockUtils = function(){
    return {
	firm_prefix: 1000,
	
	typeahead: function(shop, base){
	    return diablo_base_setting("qtypeahead", shop, base, parseInt, diablo_backend);
	},

	reject_negative: function(shop, base){
	    return diablo_base_setting("reject_negative", shop, base, parseInt, diablo_no);
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting("qtime_start", shop, base, diablo_set_date,
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd")); 
	},

	prompt_limit: function(shop, base){
	    return diablo_base_setting("prompt", shop, base, parseInt, 8);
	},

	history_stock: function(shop, base){
	    return diablo_base_setting("h_stock_edit", shop, base, parseInt, diablo_no);
	},

	multi_sizegroup: function(shop, base){
	    return diablo_base_setting("m_sgroup", shop, base, parseInt, diablo_no);
	},

	t_trace: function(shop, base){
	    return diablo_base_setting("t_trace", shop, base, parseInt, diablo_no);
	},

	price_on_region: function(shop, base){
	    return diablo_base_setting("price_on_region", shop, base, parseInt, diablo_no);
	},

	d_sex: function(shop, base){
	    return diablo_base_setting("d_sex", shop, base, parseInt, diablo_female);
	},

	group_color: function(shop, base){
	    return diablo_base_setting("group_color", shop, base, parseInt, diablo_yes);
	},

	hide_color: function(shop, base) {
	    return diablo_base_setting("h_color", shop, base, parseInt, diablo_no);
	},

	hide_size: function(shop, base) {
	    return diablo_base_setting("h_size", shop, base, parseInt, diablo_no);
	},

	hide_sex: function(shop, base) {
	    return diablo_base_setting("h_sex", shop, base, parseInt, diablo_no);
	},

	stock_in_hide_mode: function(shop, base) {
	    var hide = diablo_base_setting("h_stock", shop, base, function(s) {return s}, diablo_stock_in_hide_mode);
	    var default_hide = function(v) {
		if (v === diablo_empty_string)
		    return diablo_yes;
		return stockUtils.to_integer(v);
	    }
	    
	    return {
		hide_color:     stockUtils.to_integer(hide.charAt(0)),
		hide_size:      stockUtils.to_integer(hide.charAt(1)),
		hide_sex:       stockUtils.to_integer(hide.charAt(2)),
		hide_expire:    default_hide(hide.charAt(3)),
		hide_image:     default_hide(hide.charAt(4)),
		select_type:    default_hide(hide.charAt(5)),
		hide_executive: default_hide(hide.charAt(6)),
		hide_category:  default_hide(hide.charAt(7)),
		hide_level:     default_hide(hide.charAt(8)),
		hide_fabric:    default_hide(hide.charAt(9)),
		hide_vprice:    default_hide(hide.charAt(10)) 
	    }
	    
	},

	stock_alarm: function(shop, base) {
	    return diablo_base_setting("stock_warning", shop, base, parseInt, diablo_no);
	},

	stock_alarm_a: function(shop, base) {
	    return diablo_base_setting("stock_warning_a", shop, base, parseInt, diablo_no);
	},
	
	stock_alarm_b: function(shop, base) {
	    return diablo_base_setting("stock_alarm", shop, base, parseInt, diablo_no);
	},

	stock_contailer: function(shop, base) {
	    return diablo_base_setting("stock_contailer", shop, base, parseInt, diablo_no);
	},

	image_allowed: function(shop, base){
	    return diablo_base_setting("image_mode", shop, base, parseInt, diablo_no);
	},

	stock_with_firm: function(shop, base) {
	    return diablo_base_setting("stock_firm", shop, base, parseInt, diablo_yes);
	},

	use_barcode: function(shop, base) {
	    return diablo_base_setting("bcode_use", shop, base, parseInt, diablo_no);
	},

	// barcode_width: function(shop, base) {
	//     return diablo_base_setting("bcode_width", shop, base, parseInt, 7);
	// },

	// barcode_height: function(shop, base) {
	//     return diablo_base_setting("bcode_height", shop, base, parseInt, 2);
	// },

	trans_orgprice: function(shop, base) {
	    return diablo_base_setting("trans_orgprice", shop, base, parseInt, diablo_yes);
	},

	saler_stock: function(shop, base) {
	    return diablo_base_setting("saler_stock", shop, base, parseInt, diablo_no);
	},

	gift_sale:function(shop, base) {
	    return diablo_base_setting("gift_sale", shop, base, parseInt, diablo_no);
	},

	check_oprice_with_reject_stock: function(shop, base) {
	    return diablo_base_setting("r_stock_oprice", shop, base, parseInt, diablo_yes);
	},

	check_oprice_with_check_stock_in: function(shop, base) {
	    return diablo_base_setting("c_stock_oprice", shop, base, parseInt, diablo_yes);
	},
	
	check_firm_with_check_stock_in: function(shop, base) {
	    return diablo_base_setting("c_stock_firm", shop, base, parseInt, diablo_yes);
	},

	// barcode_with_firm: function(shop, base) {
	//     return diablo_base_setting("bcode_firm", shop, base, parseInt, diablo_no);
	// },

	auto_barcode: function(shop, base) {
	    return diablo_base_setting("bcode_auto", shop, base, parseInt, diablo_yes);
	},

	printer_barcode: function(shop, base) {
	    return diablo_base_setting("prn_barcode", shop, base, parseInt, diablo_invalid_index);
	},

	dual_barcode_print: function(shop, base) {
	    return diablo_base_setting("dual_barcode", shop, base, parseInt, diablo_no);
	},
	
	printer_bill: function(shop, base) {
	    return diablo_base_setting("prn_bill", shop, base, parseInt, diablo_invalid_index);
	},

	scan_mode:function(shop, base) {
	    return diablo_base_setting("scan_only", shop, base, function(s) {return s}, diablo_scan_mode);
	},

	shop_mode: function(shop, base) {
	    return diablo_base_setting("shop_mode", shop, base, parseInt, diablo_clothes_mode);
	},

	type_sale:function(shop, base) {
	    return diablo_base_setting("type_sale", shop, base, parseInt, diablo_no);
	}, 
	
	yes_no: function() {return [{name:"否", id: 0}, {name:"是", id: 1}]},

	valid_season: function(month){
	    switch(month){
	    case 0: 
	    case 1:
	    case 2:
		return 0;
		
	    case 3:
	    case 4:
	    case 5:
		return 1;
		
	    case 6:
	    case 7:
	    case 8:
		return 2;

	    case 9:
	    case 10:
	    case 11:
		return 3;
	    default:
		return 0;
	    }
	},

	date_add: function(date, add) {
	    var dateAfter = new Date(diablo_set_date(date) + add * diablo_day_millisecond);
	    var m = (dateAfter.getMonth() + 1).toString();
	    if (m.length === 1)
		m = "0" + m;
	    var d = dateAfter.getDate().toString();
	    if (d.length === 1)
		d = "0" + d;
	    return m + "-" + d;
	    
	},
	
	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "/" + brand + "/" + type;
	    var prompt = name + "/" + diablo_pinyin(name); 
	    return {name: name, prompt: prompt};
	},

	calc_row: function(price, discount, count){
	    if ( 0 === stockUtils.to_float(price)
		 || 0 === stockUtils.to_float(discount)
		 || 0 === stockUtils.to_float(count)){
		return 0;
	    }
	    
	    return diablo_float_mul(
		diablo_price(price, discount),
		stockUtils.to_integer(count));
	},

	to_decimal:function(v){
	    return diablo_rdight(v, 2);
	},

	/*
	 * get stock price info: org_price, ediscount
	 * 0: get org_price by ediscount
	 * 1: get ediscount by org_price
	 */
	calc_stock_orgprice_info: function(tag_price, stock, direction){
	    // console.log(tag_price, stock, direction);
	    if (!stock.hasOwnProperty('org_price')
	       || !stock.hasOwnProperty('ediscount')
	       || !stock.hasOwnProperty('tag_price')){
		return stock;
	    } 

	    if (0 === direction){
		if (0 === stockUtils.to_float(stock.ediscount)
		    || 0 === stockUtils.to_float(tag_price)){
		    return stock;
		}
		
		stock.org_price =  diablo_price(
		    stockUtils.to_float(stock.tag_price),
		    stockUtils.to_float(stock.ediscount));
	    } else {
		if ( 0 === stockUtils.to_float(stock.org_price)
		     || 0 === stockUtils.to_float(tag_price)){
		    return stock;
		}
		
		stock.ediscount = diablo_discount(
		    stockUtils.to_float(stock.org_price),
		    stockUtils.to_float(stock.tag_price));
	    } 

	    return stock;
	},

	to_float: function(v) {
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v !== 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	// to_string: function(v) {
	//     if (angular.isUndefined(v) || !v) {
	// 	return undefined;
	//     } else {
	// 	return v;
	//     }
	// },

	ediscount: function(org_price, tag_price){
	    if (tag_price == 0) return 0; 
	    return parseFloat((diablo_float_div(org_price, tag_price) * 100).toFixed(1));
	},

	start_time_of_second: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		dateFun.default_start_time(now));
	},

	get_modified: function(newValue, oldValue){
	    return diablo_get_modified(newValue, oldValue);
	},

	get_opposite: function(value) {
	    if (angular.isUndefined(value)) return undefined;
	    return -value;
	},

	order_fields:function(){
	    return {id:0,
		    sell:1,
		    discount:2,
		    year:3,
		    season:4,
		    amount:5,
		    style_number:6,
		    brand:7,
		    type:8,
		    firm:9,
		    date: 10,
		    tag_price:11};
	},

	invalid_firm:function(firm) {
	   return stockUtils.get_object_id(firm);
	},

	get_object_id: function(obj){
	    if (angular.isDefined(obj) && angular.isObject(obj) && angular.isDefined(obj.id))
		return obj.id; 
	    return diablo_invalid_firm;
	},

	match_firm: function(firm){
	    if (diablo_invalid_firm !== stockUtils.invalid_firm(firm))
		return [firm.id, diablo_invalid_firm];
	    return diablo_invalid_firm;
	},

	is_same: function(newValue, oldValue){
	    if (angular.isNumber(newValue)){
		return stockUtils.to_float(newValue) === stockUtils.to_float(oldValue) ? true:false;
	    }

	    else if (angular.isString(newValue)){
		return newValue === oldValue ? true:false;
	    }
	    
	    else if (angular.isDate(newValue)){
		return newValue.getTime() === oldValue.getTime() ? true:false;
	    }
	    
	    else if (angular.isObject(newValue)){
		return !angular.isUndefined(oldValue) && newValue.id === oldValue.id ?  true : false; 
	    }
	    else {
		return newValue === oldValue ? true : false; 
	    }
	},

	on_focus_attr: function(attr, attrs){
	    if (!attrs[attr]){
		attrs[attr] = true;
		for (o in attrs){
		    if (o !== attr) attrs[o] = false;
		}
	    }
	},

	get_login_employee:function(shop, loginEmployee, employees){
	    var filterEmployees = employees.filter(function(e){
		return e.shop === shop && e.state === 0;
	    });

	    if (filterEmployees.length === 0) filterEmployees = angular.copy(employees);
	    
	    var select = undefined;
	    if (diablo_invalid_employee !== loginEmployee)
		select = diablo_get_object(loginEmployee, filterEmployees); 
	    
	    if (angular.isUndefined(select)) select = filterEmployees[0];

	    // console.log(select);
	    return {login:select, filter:filterEmployees};
	},

	get_prompt_firm: function(prompt, firms){
	    var pfirms = [];
	    angular.forEach(firms, function(f){
		if (-1 !== f.name.indexOf(prompt)){
		    pfirms.push(f); 
		} else {
		    if (-1 !== f.py.indexOf(prompt.toUpperCase())){
			pfirms.push(f);    
		    } else {
			if ((f.id + stockUtils.firm_prefix).toString() === prompt){
			    pfirms.push(f);
			}
		    }
		}
	    });

	    return pfirms;
	},

	authen_rainbow: function(user_type, user_right, action){
	    return rightAuthen.authen(
		user_type, rightAuthen.rainbow_action()[action], user_right);
	},

	authen_stock: function(user_type, user_right, action) {
	    return rightAuthen.authen(
		user_type, rightAuthen.stock_action()[action], user_right);
	},

	authen_shop: function(user_type, shop_right, shop_action) {
	    return rightAuthen.authen_shop_action(
		user_type, rightAuthen.stock_action()[shop_action], shop_right);
	},

	cache_page_condition: function(
	    storage, key, conditions, start_time, end_time, current_page, datetime){
	    storage.remove(key);
	    storage.set(key, {filter:conditions,
			      start_time:diablo_get_time(start_time),
			      end_time: diablo_get_time(end_time),
			      page: current_page,
			      t: datetime});
	},

	remove_cache_page: function(stroage){
	    stroage.remove(diablo_key_inventory_trans);
	    stroage.remove(diablo_key_inventory_note);
	    stroage.remove(diablo_key_inventory_note_link);
	    stroage.remove("inventory-trans-stastic"); 
	    stroage.remove("stock-note-stastic");
	},

	first_day_of_month: function(){
	    var now = new Date(); 
	    var year = now.getFullYear();
	    var month = now.getMonth();

	    return {
		first:new Date(year, month, 1).getTime(), current:now.getTime()};
	},

	get_object_by_name: function(name, objs) {
	    if (!angular.isArray(objs)) return undefined;

	    for (var i=0, l=objs.length; i<l; i++){
		if (objs[i].hasOwnProperty('name') && name === objs[i].name){
		    return objs[i]
		}
	    }

	    return undefined;
	},

	get_valid_shop_id: function(shopIds){
	    if (angular.isArray(shopIds) && shopIds.length > 0)
		return shopIds[0];
	    return DIABLO_DEFAULT_SETTING;
	},

	// get_printer_shop: function(shopIds, loginShop) {
	//     var pShop = loginShop;
	//     if (shopIds.length === 1) {
	// 	pShop = shopIds[0];
	//     }
	// },

	extra_error: function(state) {
	    if (state.ecode===2008)
		return "厂商欠款[" + state.cbalance + "]，"
		+ "上次欠款[" + state.lbalance + "]";
	    else if (state.ecode === 2010) 
		return "当前日期[" + state.fdate + "]，"
		+ "服务器日期[" + state.bdate + "]";
	    else if (state.ecode === 2011)
		return "序号：" + state.order_id.toString();
	    else if (state.ecode === 2012) 
		return "退货/采购总数：[" + state.total.toString() + "]"
		+ "明细总数：[" + state.ctotal.toString() + "]";
	    else 
		return ""; 
	},

	over_flow:function() {
	    return [{name:"!=0", id:0}];
	},

	patch_barcode:function(barcode, color, size) {
	    var patchColor = color.toString();
	    if ( 1 === patchColor.length) {
		patchColor = "00" + patchColor;
	    } else if (2 === patchColor.length) {
		patchColor = "0" + patchColor;
	    }
	    
	    var patchSize = size.toString();
	    if ( 1 === patchSize.length) {
		patchSize = "0" + patchSize;
	    }

	    return barcode + patchColor + patchSize; 
	},

	get_short_year:function(year) {
	    return year.toString().substr(2, 2);
	},

	gen_barcode_content2: function(barcode, color, size) {
	    var sizeIndex = size === diablo_free_size ? 0 : size_to_barcode.indexOf(size);
	    if (diablo_invalid_index !== sizeIndex) {
		var barcode2 = stockUtils.patch_barcode(barcode, color.bcode, sizeIndex); 
		console.log(barcode2);
		return {barcode:barcode2, cname:color.cname, size:size};
	    }; 
	},
	
	gen_barcode_content: function(barcode, colorId, size, filterColors) {
	    var color = diablo_find_color(colorId, filterColors);
	    return stockUtils.gen_barcode_content2(barcode, color, size); 
	},

	get_print_templates:function(shop, templates) {
	    return templates.filter(function(t) {
		return t.tshop_id === diablo_invalid_index || t.tshop_id === shop;
	    });
	},

	check_select_only: function(select, items){
	    // console.log(select); 
	    angular.forEach(items, function(e){
		if (e.id !== select.id){
		    e.select = false;
		}
	    })
	}
	//
    }
}();


var stock_gen_draft_key = function(firm, shop, employee, model){
    if (diablo_dkey_stock_price === model)
	return "wx-" + shop.toString() + "-" + employee.toString();
    else if (diablo_dkey_stock_in === model)
	return "wp-" + shop.toString() + "-" + employee.toString();
    else if (diablo_dkey_stock_fix === model)
	return "wf-" + shop.toString() + "-" + employee.toString();
};

var stockDraft = function(storage, firm, shop, employee, model){
    this.storage  = storage;
    this.firm     = firm;
    this.shop     = shop;
    this.employee = employee;
    this.model    = model;

    this.key = stock_gen_draft_key(firm, shop, employee, model);
};

stockDraft.prototype.key = function() {
    return this.key; 
};

stockDraft.prototype.change_key = function(firm, shop, employee){
    this.firm = firm;
    this.shop = shop;
    this.employee = employee;
    this.key = stock_gen_draft_key(firm, shop, employee, this.model);
};

stockDraft.prototype.keys = function(){
    var re;
    if (diablo_dkey_stock_price === this.model){
	re = /^wx-[0-9-]+$/; 
    } else if (diablo_dkey_stock_in === this.model){
	re = /^wp-[0-9-]+$/; 
    } else if (diablo_dkey_stock_fix === this.model){
	re = /^wf-[0-9-]+$/; 
    }

    var keys = this.storage.keys(); 
    return keys.filter(function(k){
	return re.test(k)
    });
};

stockDraft.prototype.save = function(resources){
    var keys = this.keys();
    for (var i=0, l=keys.length; i<l; i++) {
	if (keys[i] !== this.key)
	    this.storage.remove(keys[i]);
    } 
    // var key = this.key;
    // var now = $.now(); 
    this.storage.set(this.key, {t:$.now(), v:resources});
};

stockDraft.prototype.list = function(draftFilter){
    var keys = this.keys();
    return draftFilter(keys); 
};

stockDraft.prototype.remove = function(){
    this.storage.remove(this.key);
};

stockDraft.prototype.get = function(key) {
    return this.storage.get(key);
};

stockDraft.prototype.select = function(dialog, template, draftFilter, selectCallback){
    var storage = this.storage;
    
    var callback = function(params){
	var select_draft = params.drafts.filter(function(d){
	    return angular.isDefined(d.select) && d.select
	})[0];
	
	console.log(storage);
	var one = storage.get(select_draft.sn); 
	if (angular.isDefined(one) && null !== one){
	    selectCallback(select_draft, one.v);
	} 
    };

    var drafts = this.list(draftFilter); 
    dialog.edit_with_modal(
	template, undefined, callback, undefined,
	{drafts:drafts,
	 valid: function(drafts){
	     for (var i=0, l=drafts.length; i<l; i++){
		 if (angular.isDefined(drafts[i].select) && drafts[i].select){
		     return true;
		 }
	     } 
	     return false;
	 },
	 select: function(drafts, d){
	     for (var i=0, l=drafts.length; i<l; i++){
		 if (d.sn !== drafts[i].sn){
		     drafts[i].select = false;
		 }
	     }
	 }
	});
};

var stockFile = function(file) {
    this.file = file;
    // this.LODOP = getLodop();
    // default callback, do nothing
    this.callback = function(taskId, value) {};
};

stockFile.prototype.getLodop = function() {
    if (angular.isUndefined(this.LODOP)) {
	this.LODOP = getLodop(); 
    }
};

stockFile.prototype.useCLODOP = function() {
    return this.LODOP.CVERSION;
};

stockFile.prototype.setCallback = function(callback) {
    this.callback = callback;
}

stockFile.prototype.writeFile = function(content) {
    if (angular.isUndefined(this.LODOP)) {
	return;
    }
    
    if (this.useCLODOP) {
	CLODOP.On_Return = this.callback;
    }; 

    var result = this.LODOP.WRITE_FILE_TEXT(0, this.file, content);
    return result;
};

stockFile.prototype.isFileExist = function() {
    if (angular.isUndefined(this.LODOP)) {
	return;
    }
    
    if (this.useCLODOP) {
	CLODOP.On_Return = this.callback;
    };

    var result = this.LODOP.IS_FILE_EXIST(this.file);
    // if (!this.LODOP.CVERSION) return result;
    return result;
};

stockFile.prototype.readFile = function() {
    if (angular.isUndefined(this.LODOP)) {
	return;
    }
    
    if (this.useCLODOP) {
	CLODOP.On_Return = this.callback;
    }

    var result = this.LODOP.GET_FILE_TEXT(this.file); 
    return result;
};

var stockPrintU = function(autoBarcode, dualPrint) {
	this.autoBarcode = autoBarcode;
	this.dualPrint = dualPrint;
	this.barcodeFormat = "128C";
	this.first = {};
	this.second = {};
	this.third = {};
};

stockPrintU.prototype.getLodop = function() {
    if (angular.isUndefined(this.LODOP)) {
	this.LODOP = getLodop(); 
    }
};

stockPrintU.prototype.set_template = function(template) {
    console.log(template);
    if (angular.isDefined(template) && angular.isObject(template)) {
	this.template = template;
	
	this.hpx = Math.floor(this.template.height * 96 / 2.54);
	this.top = this.template.hpx_top;
	this.left = this.template.hpx_left;
	this.solo_snumber = stockUtils.to_integer(this.template.solo_snumber);
	this.len_snumber  = stockUtils.to_integer(this.template.len_snumber);
	
	if (this.dualPrint === 1) {
	    this.wpx = Math.floor((this.template.width * 2 + this.template.second_space * 0.1) * 96 / 2.54);
	} else if (this.dualPrint === 2) {
	    this.wpx = Math.floor((this.template.width * 3 + this.template.second_space * 0.1) * 96 / 2.54);
	}
	else {
	    this.wpx = Math.floor(this.template.width * 96 / 2.54); 
	}
    } 
};

stockPrintU.prototype.init = function() {
    this.getLodop();
    this.LODOP.PRINT_INITA(0, 0, this.wpx, this.hpx, "task_barcode_from_stock");
    this.LODOP.SET_PRINTER_INDEX(this.printerIndex);
    this.LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
    if (this.dualPrint === 1) {
	this.LODOP.SET_PRINT_PAGESIZE(
	    1,
	    this.template.width * 2 * 100 + this.template.second_space * 10,
	    this.template.height * 100,
	    ""); 
    }
    else if (this.dualPrint === 2) {
	this.LODOP.SET_PRINT_PAGESIZE(
	    1,
	    this.template.width * 3 * 100 + this.template.second_space * 10,
	    this.template.height * 100,
	    ""); 
    }
    else {
	this.LODOP.SET_PRINT_PAGESIZE(1, this.template.width * 100, this.template.height * 100, ""); 
    }
    
    
    if (stockUtils.to_integer(this.template.font) !== 0) {
	this.LODOP.SET_PRINT_STYLE("FontSize", stockUtils.to_integer(this.template.font));
    }
    if (this.template.font_name) {
	this.LODOP.SET_PRINT_STYLE("FontName", this.template.font_name);
    }
    if (stockUtils.to_integer(this.template.bold) !== 0) {
	this.LODOP.SET_PRINT_STYLE("Bold", stockUtils.to_integer(this.template.bold));
    }
};

stockPrintU.prototype.setPrinter = function(printerIndex) {
    this.printerIndex = printerIndex;
};

// stockPrintU.prototype.setBarcode = function(barcode) {
//     this.barcode = barcode;
// };

stockPrintU.prototype.setShop = function(shop) {
    this.shop = shop;
};

stockPrintU.prototype.setStock = function(stock) {
    this.stock = stock;
};

stockPrintU.prototype.setBrand = function(brand) {
    this.brand = brand;
};

stockPrintU.prototype.setFirm = function(firm) {
    this.firm = firm;
};

stockPrintU.prototype.setCodeFirm = function(code) {
    this.codeFirm = diablo_firm_code + code;
};


// stockPrintU.prototype.setColor = function(color) {
//     this.color = color;
// };

// stockPrintU.prototype.setSize = function(size) {
//     this.size = size;
// };

stockPrintU.prototype.reset = function() {
    // this.barcode = undefined;
    this.shop = undefined;
    this.stock = undefined;
    this.brand = undefined;
    this.firm  = undefined;
    this.codeFirm = undefined;

    // this.first = {barcode: undefined, color:undefined, size:undefined};
    // this.second = {barcode:undefined, color:undefined, size:undefined};
    // this.color = undefined;
    // this.size  = undefined; 
};

stockPrintU.prototype.free_prepare = function(
    shop,
    stock,
    brand,
    barcodes,
    firm,
    codeFirm) {
    this.reset();
    
    // this.init();
    this.setShop(shop);
    this.setStock(stock);
    this.setBrand(brand);
    this.setFirm(firm);
    this.setCodeFirm(codeFirm); 
    
    var i=0, l=barcodes.length;
    while (i<l) {
	this.first = {barcode: undefined, color:undefined, size:undefined};
	this.second = {barcode:undefined, color:undefined, size:undefined};
	this.third = {barcode:undefined, color:undefined, size:undefined};
	
	if (!this.autoBarcode)
	    this.first.barcode = stockUtils.patch_barcode(barcodes[i], diablo_free_color, diablo_free_size);
	else
	    this.first.barcode = barcodes[i];
	
	this.first.color = diablo_free_color;
	this.first.size = diablo_free_size;
	
	if (this.dualPrint - 1 >= 0) {
	    i++;
	    if (i<l) {
		if (!this.autoBarcode)
		    this.second.barcode = stockUtils.patch_barcode(barcodes[i], diablo_free_color, diablo_free_size);
		else
		    this.second.barcode = barcodes[i];
		
		this.second.color = diablo_free_color;
		this.second.size = diablo_free_size;
	    } 
	}
	
	if (this.dualPrint - 2 >= 0) {
	    i++;
	    if (i<l) {
		if (!this.autoBarcode)
		    this.third.barcode = stockUtils.patch_barcode(barcodes[i], diablo_free_color, diablo_free_size);
		else
		    this.third.barcode = barcodes[i];
		
		this.third.color = diablo_free_color;
		this.third.size = diablo_free_size;
	    } 
	}
	
	this.printBarcode2(); 
	
	if (i<l) i++; 
    }
    
    
    // if (!this.autoBarcode) {
    // 	this.setBarcode(stockUtils.patch_barcode(barcode, diablo_free_color, diablo_free_size));
    // } else {
    // 	this.setBarcode(barcode);
    // } 

};

stockPrintU.prototype.prepare = function(
    shop,
    stock,
    brand,
    barcodes, 
    firm,
    codeFirm) {
    console.log(stock, brand, barcodes, firm, codeFirm); 
    this.reset();
    // this.init();
    this.setShop(shop);
    this.setStock(stock);
    this.setBrand(brand);
    // this.setBarcode(barcode);
    this.setFirm(firm);
    this.setCodeFirm(codeFirm);
    // this.setColor(color);
    // this.setSize(size);

    // if (!this.autoBarcode) {
    // 	this.setBarcode(barcode);
    // } else {
    // 	if (stock.free === 0) {
    // 	    this.setBarcode(barcode.substr(0, barcode.length - diablo_barcode_lenth_of_color_size));
    // 	} else {
    // 	    this.setBarcode(barcode);
    // 	}
    // }
    
    var i=0, l=barcodes.length;
    while (i<l) {
	this.first = {barcode: undefined, color:undefined, size:undefined};
	this.second = {barcode:undefined, color:undefined, size:undefined};
	this.third = {barcode:undefined, color:undefined, size:undefined};
	
	this.first.barcode = barcodes[i].barcode; 
	this.first.color = barcodes[i].cname;
	this.first.size = barcodes[i].size;
	
	if (this.dualPrint - 1 >= 0) {
	    i++;
	    if (i<l) {
		this.second.barcode = barcodes[i].barcode; 
		this.second.color = barcodes[i].cname;
		this.second.size = barcodes[i].size;
	    } 
	}

	if (this.dualPrint - 2 >= 0) {
	    i++;
	    if (i<l) {
		this.third.barcode = barcodes[i].barcode; 
		this.third.color = barcodes[i].cname;
		this.third.size = barcodes[i].size;
	    } 
	}

	this.printBarcode2();
	
	if (i<l) i++; 
    }
    
};

stockPrintU.prototype.printBarcode2 = function() {
    console.log(this); 
    this.init();
    
    // var iwpx = this.wpx - this.left;
    var iwpx = Math.floor(this.template.width * 96 / 2.54) - this.left;
    var startSecond = 0;
    var startThird = 0;
    if (this.dualPrint - 1 >= 0) {
	startSecond = Math.floor((this.template.width + this.template.second_space * 0.1) * 96 / 2.54) + this.left;
    }

    if (this.dualPrint - 2 >= 0) {
	startThird = Math.floor((this.template.width * 2 + this.template.second_space * 0.1) * 96 / 2.54) + this.left;
    }
    
    var pSecond = false;
    if (this.dualPrint - 1 >= 0 && angular.isDefined(diablo_set_string(this.second.barcode)))
	pSecond = true;
    
    var pThird = false;
    if (this.dualPrint - 2 >= 0 && angular.isDefined(diablo_set_string(this.third.barcode)))
	pThird = true;

    var top = this.top; 
    var line, line2, line3;
    // console.log(iwpx, top);
    if (this.template.shop) {
	if (angular.isDefined(this.shop))
	    line = this.shop; 
    }

    if (this.template.shift_date && !this.template.size_date) {
	if (angular.isDefined(line) && diablo_trim(line))
	    // 2018-06-12 12:30:49 -> 180612
	    line += "-" + this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join("");
	else 
	    line = this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join("");
    }

    if (angular.isDefined(line) && diablo_trim(line)) {
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
	if (pSecond)
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
	if (pThird)
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);

	top += this.template.hpx_each;
    }
    
    var firm = angular.isUndefined(this.firm) ? diablo_empty_string : this.firm;
    if (this.template.firm) {
	if (this.template.code_firm && angular.isDefined(this.codeFirm)) {
	    line = "厂商：" + this.codeFirm;
	    // this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "厂商：" + this.codeFirm);
	} else {
	    line = "厂商：" + firm;
	    // this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "厂商：" + firm); 
	}

	if (this.template.firm_date) {
	    line += "-" + this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join("");
	}
	
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line); 
	if (pSecond)
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line); 
	if (pThird)
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	top += this.template.hpx_each;
    }
    
    // brand
    if (this.template.brand){
	if (this.template.solo_brand) {
	    line = "品牌：" + this.brand;
	    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
	    if (pSecond)
		this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
	    if (pThird)
		this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	    top += this.template.hpx_each;
	}
    } 

    // type
    if (this.template.type) {
	line = "品名：" + this.stock.type.name;
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
	
	if (pSecond)
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
	if (pThird)
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	top += this.template.hpx_each;
    }

    // style number
    if (this.template.style_number) {
	line = "款号：";
	if (this.solo_snumber && this.stock.style_number.length > this.len_snumber)
	{
	    line += this.stock.style_number.substr(0, this.len_snumber);
	    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
	    if (pSecond) 
		this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
	    if (pThird) 
		this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	    top += this.template.hpx_each;

	    line = "     " + this.stock.style_number.substr(this.len_snumber, this.stock.style_number.length);
	    if (this.template.expire && this.stock.expire_date !== diablo_none) {
		line += this.stock.expire_date.split(diablo_date_seprator).join("");
	    }
	    
	    if (this.template.brand && !this.template.solo_brand) {
		line += this.brand;
	    }
	    if (diablo_trim(line).length !== 0) {
		this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
		if (pSecond)
		    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
		if (pThird)
		    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	    }
	    
	    top += this.template.hpx_each; 
	} 
	else {
	    line += this.stock.style_number;
	    
	    if (this.template.expire && this.stock.expire_date !== diablo_none) {
		line += this.stock.expire_date.split(diablo_date_seprator).join("");
	    }
	    
	    if (this.template.brand && !this.template.solo_brand) {
		line += this.brand;
	    } 
	    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, line);
	    
	    if (pSecond)
		this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, line);
	    if (pThird)
		this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, line);
	    
	    top += this.template.hpx_each;
	}
    }

    // color
    // line = this.first.color === diablo_free_color ? "均色" : this.first.color;
    line = this.first.color === diablo_free_color ? "" : this.first.color;
    if (diablo_trim(line) && this.template.color) {
	if (this.template.solo_color) {
	    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "颜色：" + line);
	    
	    if (pSecond) {
		// line = this.second.color === diablo_free_color ? "均色" : this.second.color;
		line = this.second.color === diablo_free_color ? "" : this.second.color;
		this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "颜色：" + line); 
	    }
	    if (pThird) {
		// line = this.second.color === diablo_free_color ? "均色" : this.second.color;
		line = this.third.color === diablo_free_color ? "" : this.third.color;
		this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "颜色：" + line); 
	    }
	    
	    top += this.template.hpx_each;
	}
    }

    // size
    line = this.first.size && this.first.size !== diablo_free_size ? this.first.size : "均码";
    // line = this.first.size && this.first.size !== diablo_free_size ? this.first.size : "";
    if (diablo_trim(line) && this.template.size) {
	if (this.template.solo_size) {
	    if (this.template.size_spec
		&& angular.isDefined(this.stock.specs)
		&& this.stock.specs.length !== 0
		&& this.first.size !== diablo_free_size) {
		for (var i=0, l=this.stock.specs.length; i<l; i++) {
		    if (this.first.size.toString() === this.stock.specs[i].name) {
			line += " (" + this.stock.specs[i].spec + ")";
		    }
		}
	    }

	    var hpx_size = this.template.hpx_each;
	    var shift_date = this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join("");
	    
	    if (0 !== stockUtils.to_integer(this.template.hpx_size))
		hpx_size = stockUtils.to_integer(this.template.hpx_size);
	    
	    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_size, "规格：");
	    this.LODOP.ADD_PRINT_TEXT(top, this.left + this.template.offset_size, iwpx, this.template.hpx_size, line);
	    if (stockUtils.to_integer(this.template.font_size) !== 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
	    }

	    
	    if (this.template.shift_date && this.template.size_date) {		
		this.LODOP.ADD_PRINT_TEXT(
		    top, this.left + this.template.offset_size + 35, iwpx, this.template.hpx_size, shift_date);
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 8);
	    }

	    if (this.template.color && this.template.size_color) {
		if (this.first.color !== diablo_free_color) {
		    // line += "-" + this.first.color;
		    this.LODOP.ADD_PRINT_TEXT(
			top, this.left + this.template.offset_size + 40, iwpx, this.template.hpx_size, this.first.color);
		}
	    }

	    console.log(line);
	    
	    // this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "规格：" + line);
	    // if (stockUtils.to_integer(this.template.font_size) !== 0) {
	    // 	this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
	    // }
	    
	    // second
	    if (pSecond) {
		line = this.second.size && this.second.size !== diablo_free_size ? this.second.size : "均码";
		// line = this.second.size && this.second.size !== diablo_free_size ? this.second.size : "";
		if (this.template.size_spec
		    && angular.isDefined(this.stock.specs)
		    && this.stock.specs.length !== 0
		    && this.second.size !== diablo_free_size) {
		    for (var i=0, l=this.stock.specs.length; i<l; i++) {
			if (this.second.size.toString() === this.stock.specs[i].name) {
			    line += " (" + this.stock.specs[i].spec + ")";
			}
		    }
		};

		this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_size, "规格：");
		this.LODOP.ADD_PRINT_TEXT(top, startSecond + this.template.offset_size, iwpx, this.template.hpx_size, line);
		if (stockUtils.to_integer(this.template.font_size) !== 0) {
		    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
		}
		
		if (this.template.shift_date && this.template.size_date) {
		    // line += "-" + (this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join(""));
		    this.LODOP.ADD_PRINT_TEXT(
			top, this.startSecond + this.template.offset_size + 35, iwpx, this.template.hpx_size, shift_date);
		    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 8);
		}
		
		if (this.template.color && this.template.size_color) {
		    if (this.template.size_color) {
			if (this.second.color !== diablo_free_color) {
			    // line += "-" + this.second.color;
			    this.LODOP.ADD_PRINT_TEXT(
				top, startSecond + this.template.offset_size + 40, iwpx, this.template.hpx_size, this.second.color);
			}
		    }
		}
		
		// this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "规格：" + line);
		// if (stockUtils.to_integer(this.template.font_size) !== 0) {
		//     this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
		// }
	    }

	    if (pThird) {
		line = this.second.size && this.second.size !== diablo_free_size ? this.second.size : "均码";
		// line = this.third.size && this.third.size !== diablo_free_size ? this.second.size : "";
		if (this.template.size_spec
		    && angular.isDefined(this.stock.specs) 
		    && this.stock.specs.length !== 0
		    && this.third.size !== diablo_free_size) {
		    for (var i=0, l=this.stock.specs.length; i<l; i++) {
			if (this.third.size.toString() === this.stock.specs[i].name) {
			    line += " (" + this.stock.specs[i].spec + ")";
			}
		    }
		};

		this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_size, "规格：");
		this.LODOP.ADD_PRINT_TEXT(top, startThird + this.template.offset_size, iwpx, this.template.hpx_size, line);
		if (stockUtils.to_integer(this.template.font_size) !== 0) {
		    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
		}
		
		if (this.template.shift_date && this.template.size_date) {
		    // line += "-" + (this.stock.entry_date.substr(3,8).split(diablo_date_seprator).join(""));
		    this.LODOP.ADD_PRINT_TEXT(
			top, startThird + this.template.offset_size + 35, iwpx, this.template.hpx_size, shift_date);
		    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 8);
		}
		
		if (this.template.color && this.template.size_color) {
		    if (this.template.size_color) {
			if (this.third.color !== diablo_free_color) {
			    // line += "-" + this.third.color;
			    this.LODOP.ADD_PRINT_TEXT(
				top, startThird + this.template.offset_size + 40, iwpx, this.template.hpx_size, this.third.color);
			}
		    }
		}
		
		// this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "规格：" + line);
		// if (stockUtils.to_integer(this.template.font_size) !== 0) {
		//     this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_size));
		// }
	    }
	    
	    top += hpx_size;
	}
    }

    // level
    if (this.template.level) {
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "等级：" + diablo_level[this.stock.level]);
	if (pSecond) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "等级：" + diablo_level[this.stock.level]);
	}

	if (pThird) {
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "等级：" + diablo_level[this.stock.level]);
	}
	top += this.template.hpx_each;
    }

    // executive
    if (this.template.executive) {
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "执行标准：" );
	if (pSecond) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "执行标准：" );
	}
	if (pThird) {
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "执行标准：" );
	} 
	top += this.template.hpx_executive;
	
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "      " +  this.stock.executive.name);
	if (stockUtils.to_integer(this.template.font_executive) !== 0) {
	    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_executive));
	}
	
	if (pSecond) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "      " +  this.stock.executive.name);
	    if (stockUtils.to_integer(this.template.font_executive) !== 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_executive));
	    }
	}

	if (pThird) {
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "      " +  this.stock.executive.name);
	    if (stockUtils.to_integer(this.template.font_executive) !== 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_executive));
	    }
	} 
	
	top += this.template.hpx_executive;
    }

    // category
    if (this.template.category) {
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "安全技术类别：");
	if (pSecond) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "安全技术类别：");
	}
	if (pThird) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "安全技术类别：");
	}
	
	top += this.template.hpx_category; 
	this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "      " +  this.stock.category.name);
	if (stockUtils.to_integer(this.template.font_executive) !== 0) {
	    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_category));
	}
	
	if (pSecond) {
	    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "      " +  this.stock.category.name);
	    if (stockUtils.to_integer(this.template.font_executive) !== 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_category));
	    }
	}

	if (pThird) {
	    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "      " +  this.stock.category.name);
	    if (stockUtils.to_integer(this.template.font_executive) !== 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_category));
	    }
	}

	top += this.template.hpx_category;
    }

    // fabric
    if (this.template.fabric) {
	if (angular.isDefined(this.stock.fabrics) && angular.isArray(this.stock.fabrics)) {
	    for (var i=0, l=this.stock.fabrics.length; i<l; i++) {
		var f = this.stock.fabrics[i];
		
		if (i === 0) {
		    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "成份：");
		    if (pSecond) {
			this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "成份：");
		    }
		    if (pThird) {
			this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "成份：");
		    }
		    top += this.template.hpx_fabric;
		}
		
		this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "      " + f.p + "%" + f.name); 
		if (stockUtils.to_integer(this.template.font_fabric) !== 0) {
		    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_fabric));
		}

		if (pSecond) {
		    this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "      " + f.p + "%" + f.name);
		    if (stockUtils.to_integer(this.template.font_fabric) !== 0) {
			this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_fabric));
		    }
		}

		if (pThird) {
		    this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "      " + f.p + "%" + f.name);
		    if (stockUtils.to_integer(this.template.font_fabric) !== 0) {
			this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_fabric));
		    }
		} 
		
		top += this.template.hpx_fabric;
	    } 
	} 
    }

    line = line2 = line3 = this.stock.tag_price.toString();
    if (!this.template.solo_color && !this.template.size_color) {
	// line += " " + (this.first.color === diablo_free_color ? "均色" : this.first.color);
	line += " " + (this.first.color === diablo_free_color ? "" : this.first.color);
	if (pSecond)
	    // line2 += " " + (this.second.color === diablo_free_color ? "均色" : this.second.color);
	    line2 += " " + (this.second.color === diablo_free_color ? "" : this.second.color);
	if (pThird)
	    // line2 += " " + (this.second.color === diablo_free_color ? "均色" : this.second.color);
	    line3 += " " + (this.second.color === diablo_free_color ? "" : this.third.color); 
    }
    
    if (!this.template.solo_size) {
	// line += this.first.size && this.first.size !== diablo_free_size ? this.first.size : "均码";
	line += this.first.size && this.first.size !== diablo_free_size ? this.first.size : "";
	if (pSecond)
	    // line2 += this.second.size && this.second.size !== diablo_free_size ? this.second.size : "均码";
	    line2 += this.second.size && this.second.size !== diablo_free_size ? this.second.size : "";
	if (pThird)
	    // line2 += this.second.size && this.second.size !== diablo_free_size ? this.second.size : "均码";
	    line3 += this.third.size && this.third.size !== diablo_free_size ? this.third.size : "";
    }
    
    this.LODOP.ADD_PRINT_TEXT(top, this.left, iwpx, this.template.hpx_each, "￥：" + line);
    if (this.template.solo_color || this.template.solo_size) {
	if (this.template.font_price > 0) {
	    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_price)); 
	}
    }
    
    if (pSecond) {
	this.LODOP.ADD_PRINT_TEXT(top, startSecond, iwpx, this.template.hpx_each, "￥：" + line2);
	if (this.template.solo_color || this.template.solo_size) {
	    if (this.template.font_price > 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_price)); 
	    }
	}
    }

    if (pThird) {
	this.LODOP.ADD_PRINT_TEXT(top, startThird, iwpx, this.template.hpx_each, "￥：" + line3);
	if (this.template.solo_color || this.template.solo_size) {
	    if (this.template.font_price > 0) {
		this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_price)); 
	    }
	}
    }

    if (this.template.solo_color || this.template.solo_size) {
	// if (this.template.font_price > 0) {
	//     this.LODOP.SET_PRINT_STYLEA(0, "FontSize", stockUtils.to_integer(this.template.font_price)); 
	// } 
	if (this.template.hpx_price > 0)
	    top += this.template.hpx_price;
	else
	    top += this.template.hpx_each;
    } else {
	top += this.template.hpx_each; 
    }

    this.LODOP.ADD_PRINT_BARCODE(top, this.left, iwpx, this.template.hpx_barcode, this.barcodeFormat, this.first.barcode);
    this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 7);
    
    if (pSecond) {
	this.LODOP.ADD_PRINT_BARCODE(top, startSecond, iwpx, this.template.hpx_barcode, this.barcodeFormat, this.second.barcode);
	this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 7);
    }

    if (pThird) {
	this.LODOP.ADD_PRINT_BARCODE(top, startThird, iwpx, this.template.hpx_barcode, this.barcodeFormat, this.third.barcode);
	this.LODOP.SET_PRINT_STYLEA(0, "FontSize", 7);
    }
    
    // this.LODOP.SET_PRINT_STYLEA(0, "Alignment", 2);
    // this.LODOP.SET_PRINT_STYLEA(0, "Bold", 0);

    // this.LODOP.PRINT_SETUP();
    // this.LODOP.PRINT_DESIGN();
    // this.LODOP.PREVIEW();
    this.LODOP.PRINT(); 
};
