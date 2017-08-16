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
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
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

	barcode_width: function(shop, base) {
	    return diablo_base_setting("bcode_width", shop, base, parseInt, 7);
	},

	barcode_height: function(shop, base) {
	    return diablo_base_setting("bcode_height", shop, base, parseInt, 2);
	},

	trans_orgprice: function(shop, base) {
	    return diablo_base_setting("trans_orgprice", shop, base, parseInt, diablo_yes);
	},

	saler_stock: function(shop, base) {
	    return diablo_base_setting("saler_stock", shop, base, parseInt, diablo_no);
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

	barcode_with_firm: function(shop, base) {
	    return diablo_base_setting("bcode_firm", shop, base, parseInt, diablo_no);
	},

	barcode_self: function(shop, base) {
	    return diablo_base_setting("bcode_self", shop, base, parseInt, diablo_no);
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
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
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
		    firm:9};
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
	    return rightAuthen.authen(user_type, rightAuthen.rainbow_action()[action], user_right);
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
    var key = this.key;
    var now = $.now();
    this.storage.set(key, {t:now, v:resources});
};

stockDraft.prototype.list = function(draftFilter){
    var keys = this.keys();
    return draftFilter(keys); 
};

stockDraft.prototype.remove = function(){
    this.storage.remove(this.key);
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

var stockPrintU = function(pageWidth, pageHeight, includeFirm, selfBarcode) {
    this.pageWidth = pageWidth;
    this.pageHeight = pageHeight;
    this.wpx = Math.floor(pageWidth * 96 / 2.54);
    this.hpx = Math.floor(pageHeight * 96 / 2.54);
    // px, top from paper
    this.top = 5;
    // px, left from paper
    this.left = 10;
    this.barcodeFormat = "128C";
    this.includeFirm = includeFirm;
    this.selfBarcode = selfBarcode;
};

stockPrintU.prototype.getLodop = function() {
    if (angular.isUndefined(this.LODOP)) {
	this.LODOP = getLodop(); 
    }
};

stockPrintU.prototype.init = function() {
    this.getLodop();
    this.LODOP.PRINT_INITA(0, 0, this.wpx, this.hpx, "task_barcode_from_stock");
    this.LODOP.SET_PRINT_MODE("PROGRAM_CONTENT_BYVAR", true);
    this.LODOP.SET_PRINT_PAGESIZE(1, this.pageWidth * 100, this.pageHeight * 100, "");
};

stockPrintU.prototype.setBarcode = function(barcode) {
    this.barcode = barcode;
};

stockPrintU.prototype.setStyleNumber = function(styleNumber) {
    this.styleNumber = styleNumber;
};

stockPrintU.prototype.setBrand = function(brand) {
    this.brand = brand;
};

stockPrintU.prototype.setPrice = function(price) {
    this.price = price;
};

stockPrintU.prototype.setFirm = function(firm) {
    this.firm = firm;
};

stockPrintU.prototype.setColor = function(color) {
    this.color = color;
};

stockPrintU.prototype.setSize = function(size) {
    this.size = size;
};

stockPrintU.prototype.reset = function() {
    this.barcode = undefined;
    this.styleNumber = undefined;
    this.brand = undefined;
    this.price = undefined;
    this.firm  = undefined;
    this.color = undefined;
    this.size  = undefined;
};

stockPrintU.prototype.free_prepare = function(
    styleNumber,
    brand,
    tagPrice,
    barcode,
    firm) {
    this.reset();
    this.init();
    this.setStyleNumber(style_number);
    this.setBrand(brand);
    this.setPrice(tagPrice);

    if (this.selfBarcode) {
	this.setBarcode(stockUtils.patch_barcode(barcode, diablo_free_color, diablo_free_size));
    } else {
	this.setBarcode(barcode);
    }

    if (this.includeFirm)
	this.setFirm(firm);

    this.printBarcode(); 
};

stockPrintU.prototype.prepare = function(
    styleNumber,
    brand,
    tagPrice,
    barcode,
    color,
    size,
    firm) {
    console.log(styleNumber, brand, barcode, color, size, firm);
    this.reset();
    this.init();
    this.setStyleNumber(styleNumber);
    this.setBrand(brand);
    this.setPrice(tagPrice);
    this.setBarcode(barcode);
    this.setColor(color);
    this.setSize(size);
    
    if (this.includeFirm)
	this.setFirm(firm);

    this.printBarcode(); 
};



stockPrintU.prototype.printBarcode = function() {
    var hpxOfStyleNumber = Math.ceil(this.hpx/6);
    var hpxOfBrand       = Math.ceil(this.hpx/6);
    var hpxOfPrice       = Math.ceil(this.hpx/6);
    var hpxOfBarCode     = Math.ceil(this.hpx/3);

    var topOfStyleNumber = this.top; 
    
    var textStyleNumber = "货号:" + this.styleNumber; 
    var textBrand; 
    var hpxOfFirm; 
    var textFirm;
    if (angular.isDefined(this.firm)) {
	hpxOfFirm = Math.ceil(this.hpx/6);
	textFirm = "厂商" + this.firm;
	textStyleNumber += this.brand;
	topOfStyleNumber += hpxOfFirm;
    } else {
	textBrand = "品牌:" + this.brand;
	topOfStyleNumber += hpxOfBrand;
    }

    // console.log(this);
    var textPrice = "RMB:" + this.price.toString() + " "; 
    if (angular.isDefined(this.color)) {
	textPrice += this.color;
    } else {
	textPrice += "均色";
    }
    if (angular.isDefined(this.size) && this.size.toString() !== diablo_free_size) {
	textPrice += this.size;
    } else {
	textPrice += "均码";
    }

    // console.log(textPrice);
    
    var iwpx = this.wpx - this.left; 
    if (angular.isDefined(this.firm)) {
	this.LODOP.ADD_PRINT_TEXT(this.top, this.left, iwpx, hpxOfFirm, textFirm);
    } else {
	this.LODOP.ADD_PRINT_TEXT(this.top, this.left, iwpx, hpxOfBrand, textBrand);
    }

    LODOP.ADD_PRINT_TEXT(
	topOfStyleNumber,
	this.left,
	iwpx,
	hpxOfStyleNumber,
	textStyleNumber);
    
    LODOP.ADD_PRINT_TEXT(
	topOfStyleNumber + hpxOfStyleNumber,
	this.left,
	iwpx,
	hpxOfPrice,
	textPrice);

    LODOP.ADD_PRINT_BARCODE(
	topOfStyleNumber + hpxOfStyleNumber + hpxOfPrice,
	this.left,
	iwpx,
	hpxOfBarCode,
	this.barcodeFormat,
	this.barcode);

    LODOP.SET_PRINT_STYLEA(0, "FontSize", 7);
    LODOP.PRINT(); 
};
