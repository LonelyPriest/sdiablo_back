var stockUtils = function(){
    return {
	typeahead: function(shop, base){
	    return diablo_base_setting(
		"qtypeahead", shop, base, parseInt, diablo_yes);
	},

	start_time: function(shop, base, now){
	    return diablo_base_setting(
		"qtime_start", shop, base, function(v){return v},
		dateFilter(
		    diabloFilter.default_start_time(now), "yyyy-MM-dd"));
	},

	prompt_name: function(style_number, brand, type) {
	    var name = style_number + "，" + brand + "，" + type;
	    var prompt = name + "," + diablo_pinyin(name); 
	    return {name: name, prompt: prompt};
	}
	//
    }
}();
