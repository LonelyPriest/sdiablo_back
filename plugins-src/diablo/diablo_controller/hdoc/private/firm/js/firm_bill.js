firmApp.controller("firmBillCtrl", function(
    $scope, dateFilter, diabloPattern, diabloUtilsService,
    firmService, filterCard, filterEmployee, user){
    // console.log(filterCard);
    // $scope.retailer = {};
    $scope.pattern = {
	decimal_2:    diabloPattern.decimal_2
    };

    // $scope.full_years = diablo_full_year; 
    // $scope.check_year = diablo_now_year();
    $scope.cards = [{no:"== 请选择银行卡号 ==", id:-1}] .concat(filterCard);
    $scope.employees  = filterEmployee;
    $scope.shops      = user.sortShops; 
    $scope.bill_modes = firmService.bill_modes;
    console.log($scope.cards);
    
    $scope.employee   = filterEmployee[0];
    $scope.shop       = $scope.shops[0];
    $scope.bill_mode  = $scope.bill_modes[0];
    $scope.bill_card  = $scope.cards[0];
    $scope.bill_date  = $.now();
    $scope.has_billed = false;

    // canlender
    $scope.open_calendar = function(event){
	event.preventDefault();
	event.stopPropagation();
	$scope.isOpened = true; 
    }

    var dialog = diabloUtilsService;
    
    firmService.list_firm().then(function(firms){
	// console.log(firms);
	$scope.firms = firms.map(function(f){
	    return {id      :f.id,
		    name    :f.name, 
		    balance :f.balance,
		    mobile  :f.mobile,
		    address :f.address,
		    prompt  :f.name + diablo_pinyin(f.name)}
	});
	// console.log($scope.firms);
    });

    $scope.check_bill = function(){
	// console.log($scope.firm, $scope.bill, $scope.bill_mode, $scope.bill_card);
	$scope.has_billed = true;
	firmService.bill_w_firm({
	    shop:       $scope.shop.id, 
	    firm:       $scope.firm.id,
	    mode:       $scope.bill_mode.id,
	    bill:       $scope.bill,
	    card:       $scope.bill_card.id,
	    employee:   $scope.employee.id,
	    comment:    $scope.comment,
	    datetime:   dateFilter($scope.bill_date, "yyyy-MM-dd hh:mm:ss")
	}).then(function(status){
	    console.log(status);
	    $scope.has_billed = false; 
	    if (status.ecode === 0){
		var left_balance = $scope.firm.balance - $scope.bill;
		dialog.response_with_callback(
		    true,
		    "厂商结帐",
		    "厂商结账成功！！剩余欠款：" +  left_balance.toString(),
		    undefined,
		    function() {
			$scope.firm.balance = left_balance;
			$scope.firm = undefined;
			$scope.rForm.name.$pristine = true;
			$scope.bill = undefined;
			$scope.rForm.bill.$pristine = true;
		    });
	    } else {
		dialog.response(
		    false,
		    "厂商结账",
		    "厂商结账失败！！" + firmService.error[status.ecode]);
	    }
	})
    }; 
});
