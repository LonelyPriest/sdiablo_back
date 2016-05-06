var stockUtils = function(){
    return {
	typeahead: function(shop, base){
	    return diablo_base_setting(
		"qtypeahead", shop, base, parseInt, diablo_backend);
	},

	reject_negative: function(shop, base){
	    return diablo_base_setting(
		"reject_negative", shop, base, parseInt, diablo_no);
	},

	start_time: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFun(now - diablo_day_millisecond * 30, "yyyy-MM-dd")); 
	},

	prompt_limit: function(shop, base){
	    return diablo_base_setting(
		"prompt", shop, base, parseInt, 8);
	},

	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "，" + brand + "，" + type;
	    var prompt = name + "," + diablo_pinyin(name); 
	    return {name: name, prompt: prompt};
	},

	calc_row: function(price, discount, count){
	    return diablo_float_mul(
		diablo_price(price, discount),
		stockUtils.to_integer(count));
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

	start_time_of_second: function(shop, base, now, dateFun){
	    return diablo_base_setting(
		"qtime_start", shop, base, diablo_set_date,
		dateFun.default_start_time(now));
	}
	    
	//
    }
}();
