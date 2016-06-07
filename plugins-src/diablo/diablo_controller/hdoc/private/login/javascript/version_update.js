var version_update = function(){
    
    var updates = [
	{date: "2016-06-07",
	 content: [
	     "增加员工与店铺对应关系",
	     "增加通过折扣过滤库存",
	     "交易记录增加反审能力"
	 ]
	},
	
	{date: "2016-06-04",
	 content: [
	     "增加交班打印",
	     "进销存统计时，增加剩余库存字段"
	 ]
	},
	
	{date: "2016-06-02",
	 content: [
	     "采购单可修改费用",
	     "增加库存按字货排序"
	 ]
	},
	
	{date: "2016-05-28",
	 content: [
	     "增加批量调价功能",
	     "增加商品赠送功能",
	     "增加销售统计功能",
	     "修改部分用户体验功能"
	 ]
	},
	
	{date: "2016-05-20",
	 content: [
	     "增加多店铺之间的移仓能力"
	 ]
	},
	{date: "2016-05-15",
	 content: [
	     "增加采购入库，退货时进价，折扣率相互计算能力"
	 ]
	},
	
	{date: "2016-05-13",
	 content: [
	     "采购入库智能提示",
	     "入库修改自动显示流水，并标记颜色",
	     "厂商详情增加结帐关联操作",
	     "采购入库单，退货单增加折扣率显示"
	 ]
	},
	
	{date: "2016-05-11",
	 content: [
	     "电脑上智能光标跟随，增强用户体验",
	     "增加打印测试功能"
	 ]
	},
	
	{date: "2016-05-09",
	 content: [
	     "编辑采购退货单时，自动进入编辑模式",
	     "银行卡结帐增加核销功能",
	     "销售明细中增加折扣率与毛利润的显示" 
	 ]
	},
	
	{date: "2016-05-07",
	 content: [
	     "增加厂商结帐功能",
	     "增加银行卡结帐功能",
	     "调整采购单，厂商对帐单的状态显示颜色" 
	 ]
	},
	
	{date: "2016-05-04",
	 content: [
	     "修改退货单无法审核的问题",
	     "增加用户可以选择默认登录客户，通常默认为非会员客户",
	     "增加非管理员帐号限定时间段登录",
	     "增加入库，采购退货时，智能光标选择"
	 ]
	},
	
	{date: "2016-04-30",
	 content: [
	     "修改入库记录时，同步修改货品资料"
	 ]
	},
	
	{date: "2016-04-29",
	 content: [
	     "增加店铺默认积分方案设置，入库时，所有货品都设置成默认积分方案",
	     "增加自动对焦能力",
	     "增加修改空白厂商能力" 
	 ]
	},
	
	{date: "2016-03-19",
	 content: [
	     "调整会员处理",
	     "调整打印处理",
	     "修改入库时，草稿不保存的问题"
	 ]
	} 
    ]; 

    return {
	init: function(){
	    var content="";

	    for (var i=0, l=updates.length; i<l; i++){
		var s =  "<div class='update-content'><div class='text-left'>"
		 + "<h4 class='text-center' style='margin-top:20px'><span class='fg-red'><strong>"
		    + "<u>" + updates[i].date + "日更新</u>"
		    + "</strong></span></h4>"
		    + "<h5 class='text-center'><span class='fg-red'>注：首次登录时，请务必清除浏览器缓存后再登陆！！</span></h5>"
		    + "<ol style='padding:0;color:orange'>"

		var c = ""
		for (var j=0, k=updates[i].content.length; j<k; j++){
		    c += "<li style='padding-bottom:5px'><span class='fg-orange'>"
			+ updates[i].content[j] + "</span></li>" 
		}
		var e = "</ol></div></div>";

		content += s + c + e;
	    }

	    $('body').append(content);
		// .append("<div class='copyright'><span> 2015-2025 &copy;&nbsp钱掌柜&nbsp&nbsp&nbsp&nbsp</span>"
		// 			     + "<span><i class='glyphicon glyphicon-star'></i>"
		// 			     + "QQ群：261033201"
		// 			     + "</span></div>");
	}
    } 
}();
