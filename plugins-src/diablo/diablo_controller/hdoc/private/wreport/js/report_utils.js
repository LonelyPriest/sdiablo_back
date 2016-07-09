var reportUtils = function(){
    return {
	filter_by_shop: function(shopId, stastics){
	    if (!angular.isArray(stastics)) return {};
	    
	    var s = stastics.filter(function(s){
		if (s.hasOwnProperty("shop_id")){
		    return s.shop_id === shopId; 
		} else if (s.hasOwnProperty("fshop_id")){
		    return s.fshop_id === shopId; 
		}
		else if (s.hasOwnProperty("tshop_id")){
		    return s.tshop_id === shopId; 
		} else {
		    return false;
		} 
	    });

	    if (s.length === 1) return s[0];
	    else return {};
	},

	to_integer: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseInt(v)
	    }
	},

	to_float: function(v){
	    if (angular.isUndefined(v) || isNaN(v) || (!v && v != 0)){
		return 0;
	    } else{
		return parseFloat(v)
	    }
	},

	calc_profit: function(m1, m2){
	    if ( angular.isUndefined(m1) || angular.isUndefined(m2)) return undefined;
	    if ( 0 === m1 || 0 === m2 ) return 0;
	    return parseFloat(diablo_float_div((m2 - m1), m2) * 100).toFixed(1);
	},

	start_time: function(base, datetime, dateFun){
	    return diablo_base_setting(
		"qtime_start",
		    -1,
		base,
		diablo_set_date,
		dateFun.default_start_time(datetime));
	},

	f_sub:function(v1, v2){
	    return diablo_rdight(reportUtils.to_float(v1) - reportUtils.to_float(v2), 2);
	},

	to_decimal:function(v){
	    return diablo_rdight(v, 2);
	}
    }
}();
