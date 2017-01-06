'use strict'

require.config({
    baseUrl: '/private/shop/javascript',
    paths: {
	"jquery": "/public/assets/metronic/plugins/jquery-1.11.3.min",
	"jquery-migrate": "/public/assets/metronic/plugins/jquery-migrate-1.2.1.min",
	"jquery-custom": "/public/assets/metronic/plugins/jquery-ui/jquery-ui-1.10.3.custom.min", 
	"jquery-cookie": "/public/assets/metronic/plugins/jquery.cokie.min",
	"jquery-block": "/public/assets/metronic/plugins/jquery.blockui.min",
	"bootstrap": "/public/assets/bootstrap/js/bootstrap.min",
	"fastclick": "/public/assets/fastclick/fastclick.min",
	"diablo-init": "/public/assets/metronic/scripts/app",

	
        "angular": "/public/assets/angular-1.3.9/angular.min",
        "angular-router": "/public/assets/angular-1.3.9/angular-route.min",
	"angular-resource": "/public/assets/angular-1.3.9/angular-resource.min",
	"angular-zh": "/public/assets/angular-1.3.9/i18n/angular-locale_zh",
	// "angular-local-storage": "/public/assets/angular-local-storage/angular-local-storage",
	"angular-ui-bootstrap": "/public/assets/bootstrap/ui-bootstrap-tpls-0.14.3",
	
        
	"diablo-function": "/private/utils/javascript/diablo_function", 
	"diablo-authen": "/private/utils/javascript/diablo_authen_app",
	"diablo-pattern": "/private/utils/javascript/diablo_pattern",
	"diablo-utils": "/private/utils/javascript/diablo_utils",
	"diablo-user-right": "/private/right/javascript/user_right_app",
	"diablo-authen-right": "/private/right/javascript/user_right_map",
	"diablo-login-out": "/private/login/javascript/login_out_app", 
	
	"diablo-filter": "/private/utils/javascript/diablo_filter_app" 
    },
    
    shim: {
	// jquery
	"jquery": {
            exports: "jquery"
        },

	"jquery-custom": {
	    deps: ["jquery"],
	},

	"jquery-cookie": {
	    deps: ["jquery"]
        },

	"jquery-block": {
	    deps: ["jquery"]
        },
	
	"jquery-migrate": {
	    deps: ["jquery"]
        },

	"fastclick": {},

	"bootstrap": {
	    deps: ["jquery"]
	},

	// angular
        "angular": {
            exports: "angular",
            deps: ["jquery"]
        },
        "angular-router": {
            exports: "angular-router",
            deps: ["angular"]
        },

	"angular-resource": {
            exports: "angular-esource",
            deps: ["angular"]
        },

	"angular-zh": {
            deps: ["angular"]
        },

	// "angular-local-storage": {
        //     exports: "angular-local-storage",
        //     deps: ["angular"]
        // },

	"angular-ui-bootstrap": {
            exports: "angular-ui-bootstrap",
            deps: ["angular"]
        },

	// diablo
	"diablo-function": {
	    deps: ["jquery"] 
	},

	"diablo-authen": {
            exports: "diablo-authen",
            deps: ["angular"]
        },

	"diablo-pattern": {
            exports: "diablo-pattern",
            deps: ["angular"]
	},

	"diablo-user-right": {
            exports: "diablo-user-right",
            deps: ["angular"]
	},

	"diablo-authen-right": {
            exports: "diablo-authen-right",
            deps: ["angular"]
	},

	"diablo-login-out":{
	    deps: ["angular"]
	},

	"diablo-utils": {
            exports: "diablo-utils",
            deps: ["angular"]
	}, 
	
	"diablo-filter": {
            exports: "diablo-filter",
            deps: ["angular", "diablo-utils"]
	},

	"diablo-init":{
	    deps:["jquery",
		  "jquery-custom",
		  "jquery-cookie",
		  "jquery-block",
		  "jquery-migrate",
		  "fastclick"]
	}, 
    }
});

require([
    "jquery",
    "angular", "angular-router", "angular-resource", "angular-zh", "angular-ui-bootstrap",
    // "angular-local-storage",
    
    "jquery-custom", "jquery-cookie", "jquery-migrate", "jquery-block",
    "bootstrap", "fastclick",
    
    "diablo-init", "diablo-function", "diablo-authen",
    "diablo-pattern", "diablo-user-right", "diablo-authen-right",
    "diablo-login-out", "diablo-utils", "diablo-filter", 
    "shopApp", "shop", "repertory"
], function($, angular) {
    $(function() {
	angular.bootstrap(document, ["shopApp"]);
    });

    var app = require("diablo-init");
    if (app !== undefined) app.init();
    
    var attachFastClick = require('fastclick');
    if (typeof(attachFastClick) === 'function') attachFastClick(document.body);	    
});
