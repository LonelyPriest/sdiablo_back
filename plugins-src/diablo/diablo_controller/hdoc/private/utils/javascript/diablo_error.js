
define (function(){
    var ERROR =
	{
	    // stock
	    2001: "货品资料已存在！！",
	    2018: "该货品资料不存在，请重建货品资料后再进行操作！！",
	    2020: "该货品资料正在使用，请先删除该货品对应的库存！！",
	    2021: "库存不足，请检测库存后再销售！！",
	    2022: "库存详情与库存明细总数不致，请核对库存数量后再操作！！",
	    2040: "该货品吊牌价小于0，请核对商品信息后再进行操作！！",
	    2058: "该库存无厂商信息，请填写厂商后再进行退货操作！！",
	    2059: "含绒量输入错误，请重新输入",
	    2060: "面料输入不正确，请确保面料从下拉框中选择，面料成份不为零！！",
	    2061: "无法定位店铺，请确认单号信息！！",
	    2070: "库存不足，请重新选择货品？", 
	    2071: "不能无条件对所有库存进行批改操作，请选择条件后再操作！！",
	    2072: "货品条码为空，请重新输入货品条码！！",
	    2080: "款号或品牌为空，无法删除该货品资料，请重新填写！！",
	    2081: "该货品正在使用，请先删除后再操作！！",
	    2082: "该货品资料已存在，请重新选择！！",
	    // 2098: "该货品资料正在使用，请先删除该货品对应的库存！！",
	    2083: "盘点草稿不存在或为空，请检查C盘目录下的盘点文件！！",
	    2084: "盘点库存为空，请重新选择库存！！",
	    2085: "该条码对应的库存不存在，请确认厂商或条码是否正确，或通过款号模式盘点！！",
	    2086: "该货品无厂商信息，无法生成条码，请填写厂商信息后再重新操作！！",
	    2088: "该货品无进货价，请核对该货品进货价后再操作！！",
	    2089: "该货品无厂商信息，请填写厂商后再操作！！",
	    2093: "厂商信息不一致，请重新选择货品！！", 
	    2099: "修改前后数据一致，请重新编辑修改项！！",
	    1601: "厂商创建失败，已存在同样的厂商！！",
	    1901: "该颜色已存在，请重新输入颜色名！！",
	    1902: "该尺码组已存在！！", 

	    // retailer
	    2101: "会员信息重复，该手机号码已注册！！",
	    2102: "会员密码不正确，请重新输入！！",
	    2103: "充值方案名称已存在，请重新输入方案名称!!",
	    2104: "积分方案已存在，请重新输入方案，！！",
	    2105: "该电子卷已使用或不存在，请重新选择电子卷！！",
	    2106: "该电子卷已经确认过，无法再确认，请重新选择电子卷！！",
	    2107: "该电子卷已被消费，请重新选择电子卷",
	    2108: "积分况换钱的方案有且只能有一个！！",
	    2109: "非法充值方案标识，请重新选择充值方案！！",
	    2115: "制券数量一次不能超过1000张，请重新输入制券数量",
	    2116: "券金额不能超过500元，请重新输入券金额！！",
	    2117: "批次号已存在，请重新输入批次号",
	    2118: "批次号不能超过9位，请重新输入批次号！！",
	    2132: "该卡剩余次数不为0，无法删除！！",
	    2133: "该卡未过期，无法删除！！",
	    2134: "该充值瞳余额不足，请充值",
	    2135: "谇充值卡已过期！！",
	    2501: "短信中心不存在，请联系服务人员！！",
	    2502: "短信发送失败，余额不足，请联系服务人员充值！！",
	    2503: "短信提醒服务没有开通，请联系服务人员开通该功能！！",

	    2597: "获取短信发送模板失败，请联系服务人员！！",
	    2598: "短信中心请求失败，请联系服务人员！！",
	    2599: "短信发送失败，请核对号码后人工重新发送！！",
	    
	    2110: "该充值方案正在使用，请解挂该充值方案后再删除！！",
	    2119: "该用户没有充值记录，请充值后再进行提现操作！！",
	    2120: "该用户充值所在的店铺不存在，请确保店铺没有被删除或注销后再操作！！",
	    2121: "该用户的最近一次充值不允许在该区域消费，请在对应区域购买商品！！",

	    2123: "该用户对应的卡不存在！！请重新办理后再操作",
	    2124: "该用户对应的卡剩余使用次数不足，请重新充值续卡后再操作！！",
	    2125: "该用户对应的卡已过期，请续卡后再操作！！",
	    2126: "该按次消费商品已存在！！",
	    2129: "该会员等级已存在，请重新选择会员等级！！",
	    2130: "该会员等不存在，请选择会员等级！！",
	    2137: "该礼品编号己存在，请重新录入！！",
	    2138: "该礼品已于当月已领取，不可重复领取！！",
	    2139: "该礼品规则未定义，无法领取！！",
	    2150: "该用户的最近一次充值不允许在该店铺消费，请在对应店铺购买商品！！",
	    2140: "该用户积分不足，无法况换礼品！！",
	    2141: "该礼品已于当年已领取，不可重复领取！！",
	    2191: "制卷方案不存在，请先制定制卷方案！！",
	    2195: "该条码对应的库存不存在，请确认条码是否正确，或通过款号模式开单！！",
	    2196: "非法条码，条码长度不小于9，请输入正确的条码值！！",
	    2197: "非法金额，销售金额不能大于99999，请重新输入金额！！",
	    2198: "非法销售项，存在修改后没有保存的销售项！！",
	    2180: "库存不足，是否将该货品以退单处理？",
	    2181: "库存不足，请核对库存或选别另外的货品进行销售！！",
	    2189: "不存在与该条码对应的颜色或尺码",
	    2170: "会员充值方案不存在，请先增加充值方案后再进行操作！！",
	    2171: "系统会员与普通会员不能进行充值，请选择充值会员后再操作！！",
	    2172: "赠送金额与充值方案不一致，请重新填写赠送金额！！",
	    2173: "次卡充值充值次数不能为0且至少选择一个次卡项目！！",

	    // sale
	    2702: "文件导出失败，没有任何数据需要导出，请重新设置查询条件！！",
	    2713: "电子券不存在，请先制券后再操作！！",
	    2714: "该销售单电子券已赠送，请重新选择销售单！！",
	    2715: "赠券方案不存在，请先设置赠券方案！！",
	    2716: "赠送超过最大金额，请重新选择电子券！！",
	    2610: "该销售单存在多张电子券，请先选择返券后再重新退货！！",
	    2611: "支付失败，网络请求失败，请检查网络并重新操作！！",
	    2612: "支付核对失败， 网络请求失败，请使用公众号或App核对后再进行操作！！",
	    2613: "该店铺没有开通扫码支付功能，请联系服务人员开通后再进行操作！！",
	    2616: "支付失败，获取店铺失败，请重新登录系统后再进行操作！！",
	    2617: "支付失败，扫码支持授权码长度为18位，并以10/11/12/13/14/15开头！！",
	    2687: "用户支付状态未知，请主动通过支付记录核对支付结果后操作！！",
	    2688: "扫码支付成功，系统记录支付信息失败！！",

	    // color
	    1901: "该颜色已存在，请重新输入颜色名！！", 
	    1905: "该颜色对应的条码编码已存在，请重新填写条码编码！！",
	    // type 
	    1907: "该品类对应的条码编码已存在，请重新填写条码编码！！",
	    1908: "该品类已存在，请重新输入品类名！！",
	    
	    9001: "数据库操作失败，请联系服务人员！！",
	    9102: "参数输入错误！！"
	};

    return ERROR;
});


