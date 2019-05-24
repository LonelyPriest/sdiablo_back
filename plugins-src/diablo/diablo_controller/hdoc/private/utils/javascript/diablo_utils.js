var diabloUtils = angular.module("diabloUtils", []);

diabloUtils.directive('barcodeScanner', function() {
    return {
	restrict: 'A',    
	scope: {
            scanner: '&',
	},

	require: 'ngModel',
	
	link:  function(scope, element, attrs, modelCtrl){
	    var callback = scope.scanner(); 
	    element.bind("keydown", function(event) {
		var value = modelCtrl.$modelValue;
		if (13 === event.which) {
		    scope.$apply(function() {
			if (angular.isFunction(callback)) {
			    callback(value)
			}
		    });
		} 
	    }); 
	}
    };
});

(function () {
    // var module;
    // module = angular.module("scanner.detection", []);

    diabloUtils.controller('ngScannerDetectController', ['$scope',
        function ($scope) {
            var firstCharTime = 0,
                lastCharTime = 0,
                callIsScanner = false,
                testTimer = false,
                scanButtonCounter = 0;

            $scope.onKeyDown = function (e) {
                // If it's just the button of the scanner, ignore it and wait for the real input
                if ($scope.options.scanButtonKeyCode !== false && e.which == $scope.options.scanButtonKeyCode) {
                    scanButtonCounter++;
                    // Cancel default
                    e.preventDefault();
                    e.stopImmediatePropagation();
                }
                // Add event on keydown because keypress is not triggered for non character keys (tab, up, down...)
                // So need that to check endChar and startChar (that is often tab or enter) and call keypress if necessary
                else if ((firstCharTime && $scope.options.endChar.indexOf(e.which) !== -1) || (!firstCharTime && $scope.options.startChar.indexOf(e.which) !== -1)) {
                    $scope.onKeyPress(e);
                    e.preventDefault();
                    e.stopImmediatePropagation();
                }
            };

            $scope.onKeyPress = function (e) {
		console.log($scope);

                if ($scope.options.stopPropagation) e.stopImmediatePropagation();
                if ($scope.options.preventDefault) e.preventDefault();

                if (firstCharTime && $scope.options.endChar.indexOf(e.which) !== -1) {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    callIsScanner = true;
                } else if (!firstCharTime && $scope.options.startChar.indexOf(e.which) !== -1) {
                    e.preventDefault();
                    e.stopImmediatePropagation();
                    callIsScanner = false;
                } else {
                    if (typeof (e.which) != 'undefined') {
                        $scope.options.model += String.fromCharCode(e.which);
                    }
                    callIsScanner = false;
                }

                if (!firstCharTime) {
                    firstCharTime = Date.now();
                }
                lastCharTime = Date.now();

                if (testTimer) clearTimeout(testTimer);
                if (callIsScanner) {
                    scannerDetectionTest();
                    testTimer = false;
                }

                if ($scope.options.onReceive) $scope.options.onReceive(e);
            };

            var scannerDetection = function (options) {
                var defaults = {
                    onComplete: false, // Callback after detection of a successfull scanning (scanned string in parameter)
                    onError: false, // Callback after detection of a unsuccessfull scanning (scanned string in parameter)
                    onReceive: false, // Callback after receiving and processing a char (scanned char in parameter)
                    onKeyDetect: false, // Callback after detecting a keyDown (key char in parameter) - in contrast to onReceive, this fires for non-character keys like tab, arrows, etc. too!
                    timeBeforeScanTest: 100, // Wait duration (ms) after keypress event to check if scanning is finished
                    avgTimeByChar: 300, // Average time (ms) between 2 chars. Used to do difference between keyboard typing and scanning
                    minLength: 6, // Minimum length for a scanning
                    endChar: [9, 13], // Chars to remove and means end of scanning
                    startChar: [], // Chars to remove and means start of scanning
                    ignoreIfFocusOn: false, // do not handle scans if the currently focused element matches this selector
                    scanButtonKeyCode: false, // Key code of the scanner hardware button (if the scanner button a acts as a key itself) 
                    scanButtonLongPressThreshold: 3, // How many times the hardware button should issue a pressed event before a barcode is read to detect a longpress
                    onScanButtonLongPressed: false, // Callback after detection of a successfull scan while the scan button was pressed and held down
                    stopPropagation: false, // Stop immediate propagation on keypress event
                    preventDefault: false // Prevent default action on keypress event
                };
                if (typeof options === "function") {
                    options = {
                        onComplete: options
                    };
                }
                if (typeof options !== "object") {
                    options = $.extend({}, defaults);
                } else {
                    options = $.extend({}, defaults, options);
                }
                return options;
            };
            var scannerDetectionTest = function () {
                // If string is given, test it
                if (!scanButtonCounter) {
                    scanButtonCounter = 1;
                }

                // If all condition are good (length, time...), call the callback and re-initialize the plugin for next scanning
                // Else, just re-initialize
                if ($scope.options.model.length >= $scope.options.minLength && lastCharTime - firstCharTime < $scope.options.model.length * $scope.options.avgTimeByChar) {
                    if ($scope.options.onScanButtonLongPressed && scanButtonCounter > $scope.options.scanButtonLongPressThreshold) {
                        $scope.options.onScanButtonLongPressed();
                    } else if ($scope.options.onComplete) {
                        $scope.options.onComplete();
                    }

                    initScannerDetection();
                    return true;
                } else {
                    if ($scope.options.onError) $scope.options.onError();
                    initScannerDetection();
                    return false;
                }
            };
            var init = function () {
                $scope.options = scannerDetection($scope.ngScannerDetect);
                initScannerDetection();
            };

            var initScannerDetection = function () {
                firstCharTime = 0;
                scanButtonCounter = 0;
            };

            init();
        }
    ]);

    diabloUtils.directive('ngScannerDetect',
        function () {
            return {
                restrict: 'A',
                scope: {
                    ngScannerDetect: '='
                },
                controller: 'ngScannerDetectController',
                link: function (scope, elm, attrs) {
		    // console.log(scope);
                    elm.bind('keypress', function (e) {
                        scope.onKeyPress(e);
                    });
                    elm.bind('keydown', function (e) {
                        scope.onKeyDown(e);
                    });
                }
            };
        }
    );

}).call(this);

diabloUtils.directive('diabloDropdown', function () {
    return function (scope, element, attrs) {
        element.on("show.bs.dropdown", function () {	    
            element.css("overflow", "inherit");
	    console.log(1);
        });
	element.on("hide.bs.dropdown", function () {
	    console.log(2);
            element.css("overflow", "auto");
        });
    };
});

diabloUtils.directive('navtable', function() {
    return function(scope, element, attr){
	
	element.on("keydown", function(event){
	    // console.log(event);
	    var $table = $(this);
	    var $active = $('input:focus,select:focus',$table);
	    // var $cur_row = $active.closest('tr');
	    
	    var $next = null;
	    var focusableQuery = 'input:visible,select:visible,textarea:visible';
	    
	    var position = parseInt( $active.closest('td').index()) + 1;
	    // console.log('position :',position);
	    
	    switch(event.which){
            case 37: // <Left>
		$next = $active.closest('td').prev().find(focusableQuery);   
		break;
            case 38: // <Up>                    
		$next = $active
                    .closest('tr')
                    .prev()                
                    .find('td:nth-child(' + position + ')')
                    .find(focusableQuery)
		;
		
		break;
            case 39: // <Right>
		$next = $active.closest('td').next().find(focusableQuery);            
		break;
            case 40: // <Down>
		$next = $active
                    .closest('tr')
                    .next()                
                    .find('td:nth-child(' + position + ')')
                    .find(focusableQuery)
		;
		break;
	    }       
	    if($next && $next.length)
	    {
		// $cur_row.closest('tr').css("background-color", "");
		// $next.closest('tr').css("background-color", "pink");
		$next.focus();
		// console.log($next[0]);
		// $next.select();
	    }
	})
    };
});

diabloUtils.directive('navform', function() {
    var setFoucs = function(es, direct) {
	// console.log(ngModelCtrl);
	var i=-1, l, select;
	for (i=0, l=es.length; i<l; i++) {
	    if ($(es[i]).is(":focus")) {
	    	break;
	    }
	}
	
	// if ($(es[i]).is("select")) {
	//     select = $(es[i]).val();
	//     $(es[i]).on('change', function(event) {
	// 	event.preventDefault();
	// 	$(es[i]).get(0).selectedIndex = parseInt(select);
	// 	ngModelCtrl.$render();
	//     })
	// }

	switch(direct) {
	case 0:
	    if (i !== -1 && i !== 0) {
		$(es[i-1]).focus().select();
		// if ($(es[i-1]).is("input"))
		//     $(es[i-1]).select();
	    };
	    break;
	case 1:
	    if (i !== -1 || i !== l) {
		$(es[i+1]).focus().select();
		// if ($(es[i+1]).is("input"))
		//     $(es[i+1]).select();
	    };
	    break;
	default:
	    break;
	}
    };
    
    return {
	restrict: 'AE',
	link: function(scope, element, attr) {
	    // console.log(element, attr, ngModelCtrl);
	    element.on("keydown", 'input', function(event){
		event.stopImmediatePropagation();
		var form = $(this).parents('form:eq(0)');
		var es = form.find('input').filter(':visible'); 
		switch(event.which) {
		case 37:  // <Left>
		    setFoucs(es, 0);
		    break;
		case 39:  // <Right>
		    setFoucs(es, 1);
		    break;
		} 
		return true;
	    })
	}
	
    };
});

diabloUtils.directive('navdiv', function() {
    return function(scope, element, attr){
	var setFoucs = function(es, direct) {
	    var i=-1, l, select;
	    for (i=0, l=es.length; i<l; i++) {
	    	if ($(es[i]).is(":focus")) {
	    	    break;
	    	}
	    }
	    
	    // if ($(es[i]).is("select")) {
	    // 	select = $(es[i]).val();
	    // 	$(es[i]).on('change', function() {
	    // 	    $(es[i]).val(select);
	    // 	})
	    // }

	   switch(direct) {
	   case 0:
	       if (i !== -1 && i !== 0) {
		   $(es[i-1]).focus();
	       }
	       break;
	   case 1:
	       if (i !== -1 || i !== l) {
		   $(es[i+1]).focus();
		   // $(es[i+1]).focus( function() {
		   //     if ($(this).is("input"))
		   //     	   $(this).select();
		   // });
		   
	       };
	       break; 
	   }
	};
	
	element.on("keydown", function(event){
	    // console.log($(this));
	    var es = $(this).find('input').filter(':visible');
	    // console.log(es); 
	    switch(event.which) {
	    case 37:  // <Left> 
		setFoucs(es, 0);
		break;
	    case 39: // <Right>
		setFoucs(es, 1);
		break;
	    }

	    return true;
	})
    };
});

diabloUtils.directive('focusTable', function() {
    return function(scope, element, attrs){
	
    };
});

diabloUtils.directive('ngEdit', function () {
    return function (scope, element, attrs) {
        element.bind("focus", function (event) {
            element[0].select();
        });
    };
});


diabloUtils.directive('ngAffix', function(){
    return  function(scope, element, attrs){
	element.affix({
	    offset: {
		// top: function() {return element.offset().top},
		top: 50,
		// bottom: 100
		bottom: function () {
		    return (element.bottom = $('.footer').outerHeight(true))
		}
	    }
	})
    }
});

diabloUtils.directive('ngShortcut', function(){
    return {
	restrict: 'AE',
	scope: {
	    key: "=",
	    go: '&'
	},
	
	link:function (scope, element, attrs) {
            element.bind("keydown", function (event) {
		if(event.which === scope.key) {
		    // console.log(scope.key);
		    var f = scope.go; 
                    scope.$apply(function(){
			if (angular.isFunction(f)) f()
		    });

		    event.preventDefault(); 
		}
            });
	}
    }
});

diabloUtils.directive('saleShortcut', function(){
    return {
	restrict: 'AE',
	scope: {
	    go: '&'
	},
	
	link:function (scope, element, attrs) {
            element.bind("keydown", function (event) {
		// console.log(event.keyCode);
		if(event.which === 112
		   || event.which === 113
		   || event.which === 114
		   || event.which === 117) {
		    var f = scope.go(); 
                    scope.$apply(function(){
			if (angular.isFunction(f)) f(event.which)
		    });

		    event.preventDefault(); 
		}
            });
	}
    }
});

diabloUtils.directive('goRow', function() {
    return {
	restrict: 'AE',
	scope: {
	    autoRow: '&'
	    // leftAttr: '='
	},
	
	link:function (scope, element, attrs) {
	    // console.log(modelCtrl);

            element.bind("keyup", function (event) {
		if(event.which === 40) {
		    event.preventDefault();
		    var f = scope.autoRow(); 
                    scope.$apply(function(){
			if (angular.isFunction(f)) {
			    scope.autoRow()(2)
			}
		    }); 
		}
		if(event.which === 38) {
		    event.preventDefault();
		    var f = scope.autoRow();
                    scope.$apply(function(){
			if (angular.isFunction(f)) {
			    scope.autoRow()(0) 
			}
		    }); 
		} 
            }); 
	}
    } 
});


diabloUtils.directive('goNextField', function() {
    return {
	restrict: 'AE',
	scope: {
	    autoRow: '&',
	    pre: '@',
	    next: '@'
	    // leftAttr: '='
	},
	
	link:function (scope, element, attrs) {
	    // console.log(modelCtrl);
            element.bind("keydown", function (event) {
		// console.log("keydown", event.which);
		if(event.which === 39) {
		    event.preventDefault();
		    var f = scope.autoRow(); 
                    scope.$apply(function(){
			if (angular.isFunction(f)) {
			    scope.autoRow()(2, scope.next)
			}
		    }); 
		}
		if(event.which === 37) {
		    event.preventDefault();
		    var f = scope.autoRow();
                    scope.$apply(function(){
			if (angular.isFunction(f)) {
			    scope.autoRow()(0, scope.pre) 
			}
		    }); 
		} 
            });
	}
    } 
});

diabloUtils.directive('disableKey', function() {
    return function (scope, element, attrs) {
	// console.log(attrs);
        element.bind("keydown", function (event) {
	    // down
            if(event.which === 38 || event.which === 40) {
                // scope.$apply(function (){
                //     scope.$eval(attrs.goRowUp);
                // });
		
                event.preventDefault();
            }
        });

	element.bind("mousewheel", function (event) {
	    // console.log("mousewheel");
            event.preventDefault();
        });
    }; 
});

diabloUtils.directive('disableWheel', function() {
    return function (scope, element, attrs) {
	// console.log(attrs);
        element.bind("mousewheel", function (event) {
	    // console.log("mousewheel");
            event.preventDefault();
        });
    }; 
});

diabloUtils.directive('focusAuto', function($timeout, $parse) {
    return {
	link: function(scope, element, attrs) {
	    // attrs.$observe('focusAuto', function(value) {
	    // 	console.log('focusAuto', value);
	    // });
	    
	    var model = $parse(attrs.focusAuto);
	    
	    scope.$watch(model, function(value) {
		// console.log(value);
		if(value) {
		    // console.log("focus");
		    $timeout(function(){
			element[0].focus();
		    }, 100);
		} else {
		    $timeout(function() {
			// console.log("blur");
			element[0].blur(); 
		    }, 100);
		}
	    }, true); 
	}
    };
});

diabloUtils.directive('ngEnter', function () {
    return function (scope, element, attrs) {
        element.bind("keydown keypress", function (event) {
            if(event.which === 13) {
                scope.$apply(function (){
                    scope.$eval(attrs.ngEnter);
                });

                event.preventDefault();
            }
        });
    };
});

diabloUtils.directive('ngPlus', function () {
    return function (scope, element, attrs) {
        element.bind("keydown keypress", function (event) {
            if(event.which === 43) {
                scope.$apply(function (){
                    scope.$eval(attrs.ngPlus);
                });

                event.preventDefault();
            }
        });
    };
});


diabloUtils.directive('ngPulsate', function () {
    return {
	restrict: 'AE',
	link: function(scope, element, attrs){
	    element.pulsate({
                color: "#bf1c56"
            });
	}
    }
});

diabloUtils.directive("barChart", function($parse, $compile){
    function postLinkFn (scope, element, attrs){
	
	var ctx = element.get(0).getContext("2d"); 
	var chart = new Chart(ctx);

	var colorLeft = "rgba(220,220,220,0.5)";
	var strokeColorLeft = "rgba(220,220,220,1)";
	
	var colorRight = "rgba(151,187,205,0.5)";
	var strokeColorRight = "rgba(151,187,205,1)";
	
	var barLeft = function(dataLeft){
	    return {
		fillColor: colorLeft,
		strokeColor: strokeColorLeft,
		data: dataLeft
	    }
	};

	var barRight = function(dataRight){
	    return {
		fillColor: colorRight,
		strokeColor: strokeColorRight,
		data: dataRight
	    }
	};

	var barData = function(chartData){
	    return {
		labels: chartData.label,
		datasets: [
		    barLeft(chartData.left),
		    barRight(chartData.right)
		]
	    }
	};
	
	if (angular.isDefined(scope.chartData)){
	    scope.barChart = chart.Bar(barData(scope.chartData), {
		datasetFill: false
	    });
	}
	
	scope.$watch("chartData", function(newValue, oldValue){
	    console.log(newValue);
	    console.log(oldValue);
	    if (angular.isUndefined(newValue)
	       && angular.isUndefined(oldValue)){
		return;
	    };
	    
	    if (!angular.equals(newValue, oldValue)){
		if (angular.isDefined(scope.barChart)){
		    scope.barChart.destroy();
		    scope.barChart = chart.Bar(barData(newValue), {
			datasetFill: false
		    });
		} else{
		    scope.barChart = chart.Bar(barData(newValue), {
			datasetFill: false
		    });
		}
		
	    };

	    // chart.Line(scope.chartData);
	}, false);
    };
    
    return{
	restrict: 'AE',
	// template: '<canvas height="400" width="300"></canvas>',
	template: '<canvas class="canvas"></canvas>', 
	replace: true,
	transclude: true,
	// require: "ngModel",
	scope: {
	    chartData: '=',
	},

	compile: function(element, attrs){
	    element.attr("Width", $(document).width());
	    element.attr("Height", $(document).height()/2);
	    // element.attr("height", diablo_viewport().height);
	    return postLinkFn;
	}
    }
}); 

diabloUtils.directive('nextPage', function ($parse) {
    return {
	restrict: 'A',
	link: function(scope, element, attrs){

	    // console.log(scope);
	    var hander = $parse(attrs['pageByscroll']).bind(null, scope);
	    
	    $(window).on("scroll", function() {
		var scrollHeight = $(document).height();
		var top = $(window).scrollTop();
		var scrollPosition = $(window).height() + top;
		
		// console.log(scrollHeight, top);
		// console.log($(window).height());
		
		if ((scrollHeight - scrollPosition) / scrollHeight === 0) {
		    if (scope.scroll_page){
			
			// scope.$apply(function(){
			//     hander();
			// 	$('html, body').animate({
			//             scrollTop: top
			// 	}, 'slow')
			// })
		    }
		    
		} 
	    });
	}
    }
});


diabloUtils.directive('capitalize', function() {
   return {
       require: 'ngModel',
       link: function(scope, element, attrs, modelCtrl) {
           var capitalize = function(inputValue) {
               if(inputValue == undefined) inputValue = '';
               var capitalized = inputValue.toUpperCase();
               if(capitalized !== inputValue) {
		   modelCtrl.$setViewValue(capitalized);
		   modelCtrl.$render();
               }         
               return capitalized;
           }

           modelCtrl.$parsers.push(capitalize);
           capitalize(scope[attrs.ngModel]);  // capitalize initial value
       }
   };
});

diabloUtils.directive('ngModelOnblur', function() {
    return {
        restrict: 'A',
        require: 'ngModel',
        priority: 1, // needed for angular 1.2.x
        link: function(scope, elm, attr, ngModelCtrl) {
            if (attr.type === 'radio' || attr.type === 'checkbox') return;

            elm.unbind('input').unbind('keydown').unbind('change');
            elm.bind('blur', function() {
                scope.$apply(function() {
                    ngModelCtrl.$setViewValue(elm.val());
                });         
            });
        }
    };
});

diabloUtils.directive('queryGroup', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/queryGroup.html',
	replace: true,
	transclude: true,
	scope: {
	    filters:      '=', 
	    prompt:       '=',
	    ok:  '&'
	},
	
	link: function(scope, element, attrs){
	    // console.log(scope.filters);
	    // console.log(scope.prompt);
	    

	    var get_prompt = function(value, prompts){
		if (angular.isUndefined(value))
		    return prompts[0]
		var v = diablo_get_object(value.id, prompts);
		return angular.isUndefined(v) ? prompts[0] : v;
	    };

	    var get_field = function(name, fields) {
		for (var i=0,l=fields.length; i<l; i++) {
		    if (name === fields[i].name)
			return fields[i]
		}
	    };

	    angular.forEach(scope.filters, function(f){
		f.field = get_field(f.field.name, f.fields);
	    	angular.forEach(f.fields, function(e){
		    // console.log(e);
		    // f.field = get_field(e.name, f.fields);
		    // console.log(f.field);
	    	    if (e.name === f.field.name){
			// f.field = e;
			switch (e.name){
			case "sex":
			    f.value = get_prompt(f.value, scope.prompt.sex);
			    break;
			case "purchaser_type":
			    f.value = get_prompt(f.value, scope.prompt.purchaser_type);
			    break;
			case "sell_type":
			    f.value = get_prompt(f.value, scope.prompt.sell_type);
			    break;
			case "check_state":
			    f.value = get_prompt(f.value, scope.prompt.check_state);
			    break;
			case "ctype":
			    f.value = get_prompt(f.value, scope.prompt.ctype);
			case "year":
			    // f.value = get_prompt(f.value, scope.prompt.year);
			    break;
			case "season":
			    f.value = get_prompt(f.value, scope.prompt.season);
			    break;
			case "shop":
			    f.value = get_prompt(f.value, scope.prompt.shop);
			    break;
			case "region":
			    f.value = get_prompt(f.value, scope.prompt.region);
			    break;
			case "fshop":
			    f.value = get_prompt(f.value, scope.prompt.fshop);
			    break;
			case "tshop":
			    f.value = get_prompt(f.value, scope.prompt.tshop);
			    break;
			case "month":
			    f.value = get_prompt(f.value, scope.prompt.month);
			    break;
			case "level":
			    f.value = get_prompt(f.value, scope.prompt.level);
			    break;
			case "date":
			    f.value = get_prompt(f.value, scope.prompt.date);
			    break;
			case "comment":
			    f.value = get_prompt(f.value, scope.prompt.comment);
			    break;
			case "sprice":
			    f.value = get_prompt(f.value, scope.prompt.sprice);
			default: 
			    break;
			}

			// console.log(f);
	    	    }
	    	})
	    });

	    scope.change_field = function(field){
		// console.log(field);
		field.value = undefined;
	    };
	}
    }
});

diabloUtils.directive('queryPattern', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/queryPattern.html',
	replace: true,
	transclude: true,
	require: "ngModel",
	scope:{
	    filters:  '=',
	    filter:   '=',
	    likeMatch: '@'
	},
	link: function(scope, element, attr, ngModel){
	    // console.log(scope);
	    // pattern
	    scope.pattern = {};
	    if (angular.isDefined(scope.likeMatch) && scope.$eval(scope.likeMatch)) 
		scope.pattern.matches = [{op:"and",   chinese:"匹配所有"},
					 {op:"like",  chinese:"模糊匹配"}];
	    else
		scope.pattern.matches = [{op:"and",   chinese:"匹配所有"}];
	    
	    scope.pattern.match = scope.pattern.matches[0];

	    ngModel.$setViewValue(scope.pattern.match);
	    scope.$watch('pattern.match', function(newValue, oldValue){
		if (angular.equals(newValue, oldValue)) return;
		
		ngModel.$setViewValue(newValue);
	    });

	    // console.log(scope.filters);

	    // scope.increment = 0;
	    scope.increment = scope.filters.length;
	    // angular.forEach(scope.filters, function(f){
	    // 	angular.forEach(f.fields, function(e){
	    // 	    if (e.name === f.field.name){
	    // 		f.field = e;
	    // 		// console.log(f.value);
	    // 	    }
	    // 	})
	    // });
	    
	    // add a filter
	    scope.add_filter = function(){
		// console.log("add_filter...");
		// console.log(scope.filters);
		// scope.filters[scope.increment] = angular.copy(scope.filter);
		scope.filters.push(angular.copy(scope.filter));
		// use first as default field
		scope.filters[scope.increment].field = scope.filters[scope.increment].fields[scope.increment];
		scope.increment++;
	    };

	    // delete a filter
	    scope.del_filter = function(){
		scope.filters.splice(-1, 1);
		scope.increment--; 
	    };
	    
	}
    }
});


diabloUtils.directive('addDeleteFilter', function () {
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/add-delete-filter.html',
	replace: true,
	transclude: true,
	// require: "ngModel",
	scope:{
	    filters:  '=',
	    filter:   '=',
	},
	link: function(scope, element, attr){
	    scope.increment = 0;
	    // add a filter
	    scope.add_filter = function(){
		// console.log("add_filter...");
		scope.filters[scope.increment] = angular.copy(scope.filter);
		// use first as default field
		scope.filters[scope.increment].field
		    = scope.filters[scope.increment].fields[scope.increment];
		scope.increment++;
	    };

	    // delete a filter
	    scope.del_filter = function(){
		scope.filters.splice(-1, 1);
		scope.increment--; 
	    };
	}
    } 
});

diabloUtils.directive('timeSearch', function (){
    return {
	restrict: 'AE',
	templateUrl: '/private/utils/html/timeSearch.html',
	replace: true,
	transclude: true,
	scope: {
	    glyphicon: '@',
	    time:      '=',
	    ok:        '&',
	    clickOk:   '=',
	    change:    '&',
	    oread:      '='
	},
	
	link: function(scope, element, attrs){
	    // console.log(scope);
	    scope.open_calendar = function(event){
		event.preventDefault();
		event.stopPropagation();
		scope.opened = true;
	    };
	}
    }
});

diabloUtils.service("diabloUtilsService", function($uibModal){
    // response dialog
    this.response = function(result, title, body, scope){
	return $uibModal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    // scope: scope,
	    resolve:{
		message: function(){
		    return {
			success     :result,
			title       :title,
			body        :body,
			show_cancel :false,
		    }
		}
	    }
	})
    };

    this.response_with_callback = function(result, title, body, scope, callback){
	return $uibModal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    // scope: scope,
	    resolve:{
		message: function(){
		    return {
			success     :result,
			title       :title,
			body        :body,
			callback    :callback,
			show_cancel :false,
		    }
		}
	    }
	})
    };

    this.request = function(title, body, callback, params, scope){
	return $uibModal.open({
	    templateUrl: '/private/utils/html/modalResponse.html',
	    controller: 'diabloDialogCtrl',
	    // backdrop: 'true',
	    backdrop: 'static',
	    // animation: true,
	    // openedClass: "modal-open-noscroll",
	    backdropClass: "hidden-print",
	    windowClass: "hidden-print",
	    scope: scope,
	    resolve:{
		message: function(){
		    return {
			success :false,
			title   :title,
			body    :body,
			callback:callback,
			params  :params
		    }
		}
	    }
	})
    };

    this.edit_with_modal = function(templateUrl, size, callback, scope, params){
	return $uibModal.open({
	    templateUrl: templateUrl,
	    controller: 'diabloEditDialogCtrl',
	    // backdrop: 'false',
	    backdrop: 'static',
	    openedClass: "modal-open-noscroll",
	    size:  size,
	    scope: scope,
	    resolve:{
		message: function(){
		    return {
			callback:callback,
			params: params
		    }
		}
	    }
	})
    };

    this.set_error = function(title, ecode) {
	var ERROR = require("diablo-error");
	this.response(false, title, ERROR[ecode], undefined);
    };

    this.set_batch_error = function(title, ecode) {
	var ERROR = require("diablo-batch-error");
	this.response(false, title, ERROR[ecode], undefined);
    };

    this.set_batch_error_with_callback = function(title, ecode, callback) {
	var ERROR = require("diablo-batch-error");
	this.response_with_callback(false, title, ERROR[ecode], undefined, callback);
    }
    
    this.success_response_with_callback = function(title, body, callback) {
	this.response_with_callback(true, title, body, undefined, callback);
    };
});

diabloUtils.controller("diabloDialogCtrl", function($scope, $uibModalInstance, message){
    // console.log($scope);
    console.log($uibModalInstance);
    console.log(message);
    $scope.success = message.success;
    $scope.title = message.title;
    $scope.body  = message.body; 

    $scope.show_cancel = angular.isDefined(message.show_cancel) ? message.show_cancel : true;

    $scope.cancel = function(){
	$uibModalInstance.dismiss('cancel');
	// if (angular.isDefined(message.cancel) && angular.isFunction(message.cancel)){
	//     message.cancel()
	// }
    };

    $scope.ok = function() {
	$uibModalInstance.close('ok'); 
	var ok_call = function(){
	    if (angular.isDefined(message.callback) && typeof(message.callback) === "function"){
		var callback = message.callback;
		if (angular.isDefined(message.params)){
		    callback(message.params)
		} else{
		    callback();
		}
	    }
	};
	
	$uibModalInstance.result.then(function(result) {
	    if (result === 'ok'){
		ok_call() 
	    }
    	}, function (success) {
	    
    	}, function(error){
	    
    	});
    };
});


diabloUtils.controller("diabloEditDialogCtrl", function($scope, $uibModalInstance, message){
    // console.log($scope);
    // console.log($modalInstance);
    console.log(message);

    var callback = message.callback;
    $scope.params = angular.copy(message.params);

    var cancel_callback = function() {
	if (angular.isDefined($scope.params.cancel_callback)
	    && typeof($scope.params.cancel_callback) === "function"){
	    $scope.params.cancel_callback();
	}
    };
    
    var deviceAgent = navigator.userAgent.toLowerCase();
    if (deviceAgent.match(/iphone|ipod|ipad/i)) {
    	$uibModalInstance.opened.then(function(){
    	    $('.header').hide();
            $('.footer').hide();

	    var styleEl = document.createElement('style'), styleSheet;
            document.head.appendChild(styleEl);
            styleSheet = styleEl.sheet;
            styleSheet.insertRule(".modal { position:absolute}", 0); 
    	});

	var unbind = function(){
            $('.header').show();
            $('.footer').show();
	};
	    
    	$uibModalInstance.result.then(function () {
            unbind();
	    $scope.cancel();
    	}, function () {
            unbind();
	    $scope.cancel();
    	}, function(){
            unbind();
	    $scope.cancel();
    	});
    } else {
	$uibModalInstance.result.then(function (reason) {
	    console.log(reason);
	}, function (reason) {
	    console.log(reason);
	    cancel_callback();
	}, function(reason){
	    console.log(reason);
	    // $scope.cancel();
	    cancel_callback();
	});
    }
    // $scope.out = {};
    
    // console.log($scope.params);
    $scope.cancel = function(){
	// console.log("cancel");
	$uibModalInstance.close('cancel');
	cancel_callback();
    };

    $scope.ok_cancel = function() {
	$uibModalInstance.close('ok_cancel');
    };

    $scope.ok = function() {
	$uibModalInstance.close('ok');
	if (angular.isDefined(callback) && typeof(callback) === "function"){
	    delete $scope.params.edit;
	    delete $scope.params.cancel_callback;
	    callback($scope.params);
	}
    };

    var edit_callback = $scope.params.edit;
    $scope.edit = function(){
	$uibModalInstance.dismiss('ok');
	if (angular.isDefined(edit_callback) && typeof(edit_callback) === "function"){
	    edit_callback();
	}
    }
});

// =============================================================================
// @desc :$q.all([
//          promise(rightService.list_role)(),
//          promise(rightService.list_account_right, account)()
// ]).then
// =============================================================================

diabloUtils.service("diabloPromise", function($q){
    this.promise = function(callback, params){
	return function(){
	    var deferred = $q.defer();
	    callback(params).then(function(data){
		// console.log(data);
		deferred.resolve(data);
	    });
	    return deferred.promise;
	}
    }
});

diabloUtils.service("diabloPagination", function(){
    var _pageData = null;
    var _itemsPerpage = null;
    var _index = [];
    
    this.set_data = function(data){
	_pageData = data;
    };

    this.get_data = function(){
	return _pageData;
    }

    this.set_items_perpage = function(items){
	_itemsPerpage = items;
    };

    this.get_length = function(){
	return _pageData.length;
    };

    this.get_itmes_perpage = function(){
	return _itemsPerpage;
    };
    
    this.get_page = function(currentPage){
	var begin = (currentPage - 1) * _itemsPerpage;
	var end = begin + _itemsPerpage > this.get_length()
	    ? (this.get_length()) : begin + _itemsPerpage; 
	return _pageData.slice(begin, end);
    };
});

diabloUtils.directive('diabloSwitch', function(){
    return {
	restrict: 'AE',
	require: '?ngModel', 
	
	link: function(scope, element, attrs, ngModel){
	    element.bootstrapSwitch();

	    element.on('switchChange.bootstrapSwitch', function(event, state) {
                if (ngModel) {
		    console.log(scope.$parent);
                    scope.$apply(function() {
			// var newValue = state === true ? 1:0;
                        ngModel.$setViewValue(state);
                    });
                }
            });

	     scope.$watch(attrs.ngModel, function(newValue, oldValue) {
		 console.log(newValue, oldValue);
                 if (newValue) {
                     element.bootstrapSwitch('state', true, true);
                 } else {
                     element.bootstrapSwitch('state', false, true);
                 }
             });
	}
    }
});

diabloUtils.directive('defaultImg', function () {
        return{
            restrict: 'AE',
            // template: '<canvas width="800" height="400"></canvas>',
            template:'<img ng-src={{default_img}}></img>', 
            replace: true,
            transclude: true,
            scope: {
		// styleNumber: '=',
		// brand:       '=',
		// type:        '=',
		// total:       '='
            },

            link: function(scope, element, attrs){
		scope.default_img =
		    "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAKAAAAB4CAYAAAB1ovlvAAAFeUlEQVR4Xu2Zr1MjQRCF5wRgwIABhUKhUGBQYMCA4a/EgAEDCgMGMGBQYMAQAwbMXfVWTWoz2c2vq8rrVH8x3CXZ7dfvfendmf3T6XT+Jl44IHLgDwCKnKds5QAAAoLUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4gAIA1IHAFBqP8UBEAakDgCg1H6KAyAMSB0AQKn9FAdAGJA6AIBS+ykOgDAgdQAApfZTHABhQOoAAErtpzgAwoDUAQCU2k9xAIQBqQMAKLWf4m4AfH9/T09PT2l/f78xla+vr3R6eprsr73m5+fT8fFxWltb6/v+xcVFenl5qd7f2NhIh4eH3e9YnbOzs/T7+5uWlpbSyclJda7z8/Nkn9nLvm/H1V/D9Nl36+e2/+/s7KTt7e2x9EVDUgrgz89PT/AlLDkMC9agMjAycHd3d+n+/r4PQvve9/d3Ojo6qg43sBYXF/sgLM9nWq6vr9Pu7m4Fpr1G1WffNT32AzKg7Xj7AVxdXU2kLxKEUgDrRluAn5+fPaDkzw2WlZWVnmmS4VhfX+++3xR6nko2WetTraxnx3Y6ncaJlQFr09f0A2nSMo6+KBDODID50lgPpgSzPv0WFhZ6plg5Be1SbtNxb28vLS8vVxPMLpf5uBKAQT+QQZ+VevN0HqYPAKfswLAJ+PHx0b281S+PW1tb1WRrmoj1CVoGX59qeTKW932jTOhBdevHT6JvyhFIys3EBGxyxi5nDw8P1b2eTZO8SNnc3Oy7jJb3Z/l8+Ribjvk8bSm0/UDqdW2S2hTOr/oiZBJ9EiKmXHQmAbQwLy8v08HBQXfBMGnABtbr6+t/Azg3N1fdp+YVd3nvOam+KfMw9XIzB2ATfObaJAHnc9niolykjHoPmOuurq72LaDqcNu2j20jjTOhp06DoOBMAdgGX/2esL4qHnYPaJdwA+ft7W3oFBzlElzu+dltws3NTc9e4zj6BDxMveTMADgIvkGg5Zv/plXw4+Njte+Xp5j9u20h0gZg2/lNUx1A2xscZ5U+dRJEBWcCwKZN4jz1np+fk62Ec+Dl5m/bPmCefvWN7UH3gsO2Yeqb0DnL8v6SfcB+yt0A2DQdslyDyu6dysduTZvHozwJsYmXp1+5Im6bgoP0Na2m28AfRZ9oGEnKSgEsH3VlB/IzWvtbPgMuXWp6bjvoWbBNpdvb2+o0eZuk1NH2fpO+/F55jkmfVUsoEBaVAijsm9JOHABAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k74B0EkQUWUAYNTknfQNgE6CiCoDAKMm76RvAHQSRFQZABg1eSd9A6CTIKLKAMCoyTvpGwCdBBFVBgBGTd5J3wDoJIioMgAwavJO+gZAJ0FElQGAUZN30jcAOgkiqgwAjJq8k77/Aa0A9u1tG0GmAAAAAElFTkSuQmCC"; 
            }
        }
});

diabloUtils.directive('drawDefaultImg', function () {
    return{
        restrict: 'AE',
        // template: '<canvas width="800" height="400"></canvas>',
        template: '<canvas></canvas>',
        replace: true,
        transclude: true,
        // require: "ngModel",
        scope: {
            // orgImage: '=',
	    // options: '='
        },

        link: function(scope, element, attrs){
	    // set default width and height
	    
	    var height = 120;
	    var width  = 160;
	    element.attr("width", width);
            element.attr("height", height);
	    
            var ctx = element.get(0).getContext("2d");
	    ctx.fillStyle="rgba(238,238,238,1)";
	    ctx.fillRect(0, 0, width, height);
	    
	    ctx.fillStyle = "rgba(127, 127, 127, 1)";
	    ctx.font = "20px sans-serif";
	    ctx.textAlign = "start"
            ctx.textBaseline = 'top';
	    ctx.fillText("120X160", 30, 50);

	    w = element.get(0).toDataURL("image/png");
	    console.log(w);

	    // var context = ctx;
	    // context.fillStyle = "#EEEEFF";
            // context.fillRect(0,0,400,300);
            // context.fillStyle = "#00f";
            // context.font = "italic 30px sans-serif";
            // context.textBaseline = 'top';
            // var txt="fill示例文字"
            // context.fillText(txt, 0, 0);
        }
    }
});


diabloUtils.directive('imageDraw', function ($q) {
    function postLinkFn (scope, element, attrs){
	var ctx = element.get(0).getContext("2d");

	scope.$watch("orgImage.image", function(newValue, oldValue){
	    // console.log(scope);
	    if (angular.isUndefined(newValue)
		|| angular.equals(newValue, oldValue)){
		return;
	    };

	    var options = scope.options; 
	    // var maxHeight = options ? options.maxHeight : 150;
	    // var maxWidth = options ? options.maxWidth : 200;
	    var quality = options ? options.quality : 0.5;
	    // var type = options ? options.type : 'image/jpg';

	    var orgImage = scope.orgImage.image;
	    console.log(orgImage);
	    var height = 320;
	    var width  = 240;
	    // var height = orgImage.height;
	    // var width = orgImage.width;

	    // console.log(height, width, quality);

	    // if (width > height) {
	    // 	if (width > maxWidth) {
	    // 	    height = Math.round(height *= maxWidth / width);
	    // 	    width = maxWidth;
	    // 	}
	    // } else {
	    // 	if (height > maxHeight) {
	    // 	    width = Math.round(width *= maxHeight / height);
	    // 	    height = maxHeight;
	    // 	}
	    // }

	    console.log(height, width, quality);
	    
            element.attr("width", width);
            element.attr("height", height);

	    //draw image on canvas
	    ctx.drawImage(orgImage, 0, 0, width, height); 
	    // get the data from canvas as 70% jpg (or specified type). 
	    scope.orgImage.dataUrl = element.get(0).toDataURL("image/png", quality);
	})
    };
    
    return{
        restrict: 'AE',
        // template: '<canvas width="800" height="400"></canvas>',
        template: '<canvas></canvas>',
        replace: true,
        transclude: true,
        // require: "ngModel",
        scope: {
            orgImage: '=',
	    options: '='
        },

        compile: function(element, attrs){
            return postLinkFn;
        }
    }
});

diabloUtils.directive('imageDraw2', function ($q) {
    function postLinkFn (scope, element, attrs){
	var ctx = element.get(0).getContext("2d");

	scope.$watch("orgImage.image", function(newValue, oldValue){
	    console.log(scope);
	    if (angular.isUndefined(newValue)
		|| angular.equals(newValue, oldValue)){
		return;
	    };

	    var options = scope.options; 
	    var quality = options ? options.quality : 0.7; 
	    var orgImage = scope.orgImage.image;
	    console.log(orgImage);
	    var height = scope.height ? scope.height : 70;
	    var width = scope.width ? scope.width : 70; 
	    console.log(height, width, quality);
	    
            element.attr("width", width);
            element.attr("height", height);

	    //draw image on canvas
	    ctx.drawImage(orgImage, 0, 0, width, height); 
	    scope.orgImage.dataUrl = element.get(0).toDataURL("image/png", quality);
	})
    };
    
    return{
        restrict: 'AE',
        template: '<canvas></canvas>',
        replace: true,
        transclude: true,
        // require: "ngModel",
        scope: {
            orgImage: '=',
	    options: '=',
	    height: '=',
	    width: '='
        },

        compile: function(element, attrs){
            return postLinkFn;
        }
    }
});

diabloUtils.directive('imageUpload', function ($q) {
    'use strict'

    var URL = window.URL || window.webkitURL; 
    
    var createImage = function(url, callback) {
	var image = new Image();
	image.onload = function() {
	    callback(image);
	};
	image.src = url;
    };

    var fileToDataURL = function (file) {
	// console.log(file);
	var deferred = $q.defer();
	var reader = new FileReader(); 
	reader.readAsDataURL(file);
	
	reader.onload = function (e) {
	    deferred.resolve(e.target.result);
	};
	return deferred.promise;
    };
    
    return {
	restrict: 'AE',
	template: '<span class=\"btn btn-primary btn-file\">'
	    +'<i class="glyphicon glyphicon-arrow-right"></i>'
	    +'<input type="file" accept="image/*"/>'
	    +'</span>',
	replace: true,
	transclude: true,
	scope: {
	    image: '=',
	    maxHeight: '@?',
	    maxWidth: '@?',
	    quality: '@?',
	    type: '@?'
	},
	
	link: function(scope, element, attrs){
	    var doResizing = function(imageResult, callback) {
		createImage(imageResult.url, function(image) {
		    console.log(image);
		    // var dataURL = resizeImage(image, scope);
		    // imageResult.resized = {
		    // 	dataURL: dataURL,
		    // 	type: dataURL.match(/:(.+\/.+);/)[1],
		    // };
		    imageResult.image = image; 
		    callback(imageResult);
		});
	    };

	    var applyScope = function(imageResult) {
		scope.$apply(function() {
		    console.log(imageResult);
		    scope.image = imageResult;
		});
	    };
	    
	    angular.element('.btn-file :file').bind('change', function(evt){
		// console.log(evt);
		var file = evt.target.files[0];
		// console.log(file);
		if (angular.isDefined(file)) {
		    var imageResult = {
			file: file,
			url:  URL.createObjectURL(file)
		    };

		    fileToDataURL(file).then(function (dataURL) {
			// imageResult.dataURL = dataURL; 
		    });

		    
		    doResizing(imageResult, function(imageResult) {
			applyScope(imageResult);
		    });
		}
		evt.stopPropagation(); 
		return false;
	    }) 
	}
    }
});

diabloUtils.directive('imageUpload2', function ($q) {
    'use strict' 
    var URL = window.URL || window.webkitURL; 
    var createImage = function(url, callback) {
	var image = new Image();
	image.onload = function() {
	    callback(image);
	};
	image.src = url;
    };

    var fileToDataURL = function (file) {
	// console.log(file);
	var deferred = $q.defer();
	var reader = new FileReader(); 
	reader.readAsDataURL(file);
	
	reader.onload = function (e) {
	    deferred.resolve(e.target.result);
	};
	return deferred.promise;
    };
    
    return {
	restrict: 'AE', 
	replace: true,
	transclude: true,
	scope: {
	    id: '@',
	    image: '=',
	    maxHeight: '@?',
	    maxWidth: '@?',
	    quality: '@?',
	    type: '@?'
	},
	
	link: function(scope, element, attrs){
	    var doResizing = function(imageResult, callback) {
		createImage(imageResult.url, function(image) {
		    console.log(image);
		    // var dataURL = resizeImage(image, scope);
		    // imageResult.resized = {
		    // 	dataURL: dataURL,
		    // 	type: dataURL.match(/:(.+\/.+);/)[1],
		    // };
		    imageResult.image = image; 
		    callback(imageResult);
		});
	    };

	    var applyScope = function(imageResult) {
		scope.$apply(function() {
		    console.log(imageResult);
		    scope.image = imageResult;
		});
	    };
	    
	    // angular.element('.btn-file :file').bind('change', function(evt){
	    angular.element('#'+scope.id).bind('change', function(evt){
		// console.log(evt);
		evt.stopImmediatePropagation();
		var file = evt.target.files[0];
		// console.log(file);
		if (angular.isDefined(file)) {
		    var imageResult = {
			file: file,
			url:  URL.createObjectURL(file)
		    };

		    fileToDataURL(file).then(function (dataURL) {
			// imageResult.dataURL = dataURL; 
		    });

		    
		    doResizing(imageResult, function(imageResult) {
			applyScope(imageResult);
		    });
		}
	    });
	}
    }
});


