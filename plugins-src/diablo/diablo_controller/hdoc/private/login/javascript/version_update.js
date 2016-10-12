var version_update = function(){
    
    var updates = [
	{date: "2016-10-13",
         content: [
	     "移仓单可删除" ,
	     "采风明细价格小计统计",
	     "移仓记录增加店铺过滤条件",
	     "非管理员用户查看实时报表库存不正确问题"
	 ]
        },
	
	{date: "2016-10-09",
         content: [
	     "入库时增加厂商欠款校验" ,
	     "增加常用信息缓存处理，优化前台性能",
	     "禁用厂商欠款余额直接修改，只能直接从厂商结帐中修改厂商余额，以避免厂商对帐单上欠与下欠不相符的问题"
	 ]
        },
	
	{date: "2016-09-28",
         content: [
	     "修正重复登录问题" 
	 ]
        },
	
	{date: "2016-09-28",
         content: [
	     "修正重复登录问题",
	     "新增会员的初始积分只有管理员才能填入",
	     "修正修改厂商资料时，余额会变0的问题",
	     "修正厂商电话号码为11至12位",
	     "修正部分弹出未知错误的问题"
	 ]
        },
	
	{date: "2016-09-26",
         content: [
	     "修正连续退货时，保存按钮不可点击问题",
	     "修改日报表上期库存有时显示为0的问题",
	     "修正会员余额与累计消费汇总不显示问题",
	     "修正离开采购记录页面时，结束日期与页面重置的问题",
	     "修正离开采购明细页面时，结束日期与页面重置的问题"
	 ]
        },
	
	{date: "2016-09-24",
         content: [
	     "增加可根据月份查询会员生日",
	     "销售记录修改时，可查询货品的详细信息，如年度，季节，库存等",
	     "修正离开销售记录页面时，结束日期与页面重置的问题",
	     "修正离开销售明细页面时，结事日期与页面重置的问题",
	 ]
        },
	
	{date: "2016-09-23",
         content: [
	     "采购记录增加款号，品牌条件过滤",
	     "库存增加品牌，类型排序",
	     "修改日报表同步超时问题",
	     "修改实时日报表有时显示前期库存为0的问题",
	     "帐户查看销售天数增加不限制天数的设定",
	     "修改输入款号条件查询时，一定要从下拉列表选中才很过滤的问题",
	     "加深下接提示框选中时的颜色",
	     "当天日期颜色加深显示"
	 ]
        },
	
	{date: "2016-09-15",
         content: [
	     "优化手机显示效果",
	     "交易明细增加年度字段",
	     "修正退货单修改保存时，库存总数量不同步问题",
         ]
        },
	
	{date: "2016-09-14",
         content: [
	     "会员充值时，可打印单据",
	     "会员积分可直接修改",
	     "日报表字段显示增加权限控制",
	     "日报表增加统计项展示，并去除多余库存列"
         ]
        },
	
	{date: "2016-09-13",
         content: [
	     "优化打印格式",
	     "修正同一客户连续开单，小票上打印积分不累加问题",
	     "日报表增加入库，退货，调入，调出",
	     "前台打印进，可打印交班报表"
         ]
        },
	
	{date: "2016-09-11",
         content: [
	     "客户退货单可以修改",
	     "蛋糕店模式优化",
	     "会员密码修改权限可控制"
         ]
        },
	
	{date: "2016-09-10",
         content: [
	     "增加会员充值时可选择不同充值方案",
	     "增加会员充值记录展示",
	     "管理员可删除会员充值记录",
	     "管理员可直接修改充值会员余额",
	     "库存为零的货品资料可以删除",
	     "日报表增加提现与充值项"
         ]
        },
	
	{date: "2016-08-21",
         content: [
	     "非管理员，不能修改销售开单与退货的日期",
	     "取消单款备注",
	     "库存增加吊牌价过滤条件",
	     "批量修改库存增加取消积分方案选项",
	     "交易明细增加季节字段"
         ]
        },
	
	{date: "2016-08-16",
         content: [
	     "销售记录与明细，默认开始时间为当天",
	     "入库增加图片录入"
         ]
        },
	
	{date: "2016-08-14",
         content: [
	     "采购明细中增加季节字段",
	     "入库增加图片录入"
         ]
        },
	
	{date: "2016-08-08",
         content: [
	     "增加在采购明细中查看货品入库历史",
	     "修改销售开单时，保存快捷键由F3改为回车键",
	     "增加均色均码的货品可增加颜色" 
         ]
        },
	
	{date: "2016-08-06",
         content: [
	     "增加前台打印能力",
	     "修正非管理员帐号入库时，默认积分设置不生效问题",
	     "增加颜色不分组配置"
         ]
        },
	
	{date: "2016-07-17",
         content: [
	     "日报表增加同步能力",
	     "库存增加数量有于0与等于0的过滤项",
	     "采购记录只显示目前该记录状态能操作的按钮，以避免误操作",
	     "销售增加是否允许输入负数表示退货选项",
	     "款号联想可以从作何位置开始",
	     "非管理员帐号可设置库存查看天数"
         ]
        },
	
	{date: "2016-07-14",
         content: [
	     "单据查询条件自动保留最后一次查询状态" 
         ]
        },
	
	{date: "2016-07-13",
         content: [
	     "开单优化，开单完成后，自动清除当前记录开始下一单",
	     "修改小数点显示问题",
	     "增加采购记录鼠标双击可进入修改状态",
	     "增加采购明细可直接进入修改状态" 
         ]
        },
	
	{date: "2016-07-11",
         content: [
	     "增加系统每天凌晨2点自动生成日报表能力",
	     "优化报表展示，实时报表与日报表分别展示",
	     "增加日报表，交班报表显示",
	     "增加库存批量调价功能",
	     "增加库存按季节过滤能力",
	     "采购入库/退货等，增加入库参数限制" 
         ]
        },
	
	{date: "2016-07-09",
         content: [
	     "员工查看销售记录天数可设置，默认只能查看当天记录",
	     "增加按区域调价能力",
	     "交班可按员工统计业绩并在打印小票上显示",
	     "交班打印小票显示上次库存数目",
	     "交班打印增加备用金能力"
         ]
        },
	
	{date: "2016-07-05",
         content: [
	     "修正厂商编号联想功能，精确编号检索结果",
	     "库存增加款号排序功能"
         ]
        },
	
	{date: "2016-07-03",
         content: [
	     "增加管理员是否只查看当天销售记录的系统设置项" 
         ]
        },
	
	{date: "2016-07-02",
         content: [
	     "厂商增加编号联想",
	     "增加厂商导出功能",
	     "增加厂商欠款排序功能",
	     "修正采购入库时偶尔出现00:00:00时间的问题",
	     "采购入库时，厂商应付款改为保留两位小数",
	     "入库记录增加审核状态查询条件",
	     "修正同一会员连续开单时，小票积分不累计问题",
	     "修正开单时，当点击下一单时，会员不重置的问题",
	     "限制开单时的挂单数目不超过4个"
         ]
        },
	
	{date: "2016-06-29",
         content: [
	     "销售开单，可以核销负数金额，表示用户在买价基础上增加价格",
	     "采购入库时，保存时，自动清空上一单内容，不再需要用户点击下一单",
             "采购入库可以直接修改货品资料，解决需跳到货品详情中修改的问题",
	     "采购退货时，厂商根据货品自动生成，不再需要用户直接选择",
	     "日报表增加成本，毛利以及毛利率" 
         ]
        },
	
	{date: "2016-06-29",
         content: [
             "销售开单增加键盘快捷键操作",
	     "销售开单设置立即打印时，去掉打印成功对话框",
	     "采购入库，选择颜色时，增加颜色区分，以便用户寻找"
         ]
        },
	
	{date: "2016-06-28",
         content: [
             "销售记录（明细）改为默认只查看当天发生的交易"
         ]
        },
	
	{date: "2016-06-24", 
         content: [
             "库存，明细（采购，销售）增加性别筛选项",
	     "销售开单根据用户意见去掉红色闪烁",
	     "表格行选中时，增加蓝色背景以便区分",
	     "增加入库时，根据月份智能选择季节",
	     "增加可以选择店铺默认性别（男/女）的系统选项，以方便入库" 
         ]
        },
	
	{date: "2016-06-20",
         content: [
             "增加会员充值功能",
	     "会员增加生日字段",
	     "厂商增加备注字段，厂商名字段不再限制长度",
	     "促销方案增加可修改能力",
	     "开单时，草稿增加时间戳功能，以便按时间自动存储草稿",
	     "库存批量调价增增加是否积分与调价模式选项"
         ]
        },
	
	{date: "2016-06-15",
         content: [
             "优化进销存报表，增加库存自动核对能力",
	     "优化入库，入库审核等操作，减少按键次数与鼠标操作"
         ]
        },
	
        {date: "2016-06-14",
         content: [
             "报表增加成本统计"
         ]
        },
	{date: "2016-06-13",
	 content: [
	     "增加入库时，价格跟踪选项",
	     "修正入库时，折扣率自动运算"
	 ]
	},
	
	{date: "2016-06-09",
	 content: [
	     "增加用户登录时的默认店铺选择",
	     "增加员工与店铺对应关系，选择店铺时，只显示对应店铺的员工"
	 ]
	},
	
	{date: "2016-06-07",
	 content: [
	     "增加通过权限设定员工与店铺的关系",
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
