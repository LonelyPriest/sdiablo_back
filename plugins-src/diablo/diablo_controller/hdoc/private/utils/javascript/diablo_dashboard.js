(function(window) {
    var DASHBOARD_MODE = ["clothes_common", "water_common"];
    var DASHBOARD = {
	clothes_common: {
	    new_sale: {employee: "导购"},
	    retailer_name: {name: "会员"},
	    retailer_levels: [{id:0, level:0, name:"普通级"},
			      {id:1, level:1, name:"贵宾级"},
			      {id:2, level:2, name:"银卡级"},
			      {id:3, level:3, name:"金卡级"}],
	    charge: {name: "充值"}
	},
	
	water_common: {
	    new_sale: {employee:"业务员"},
	    retailer_name: {name: "客户员"},
	    retailer_levels: [{id:0, level:0, name:"个人"},
			      {id:1, level:1, name:"门店"},
			      {id:2, level:2, name:"企业"}],
	    charge: {name: "押金"}
	}
    };

    window.face = function(shop_mode) {
	return DASHBOARD[DASHBOARD_MODE[shop_mode]];
    }
})(window);

