var version_update = function(){
    var updates = [
	{date: "2021-04-21",
	 content:
	 ["货品可单独设置提成",
	  "库存导出增加条码项",
	  "增加会员消费频率查询"]
	},
	
	{date: "2020-07-18",
	 content:
	 ["修正修改采购记录厂商,特定情况下采购明细厂商不改变的问题",
	  "增加会员异常消费短信提醒，以防止营业员累加积分"]
	},
	
	{date: "2020-07-13",
	 content:
	 ["厂商信息显示增加权限控制",
	  "修正退货单无法修改的问题"]
	},
	
	{date: "2020-07-05",
	 content:
	 ["增加员工销售提成功能"]
	},
	
	{date: "2020-07-01",
	 content:
	 ["增加电子券赠送与货品关联，货品可选择是否参与电子券赠送"]
	},
	
	{date: "2020-06-01",
	 content:
	 ["标鉴打印优化，货品货号可单独设置字体大小，货号换行间距",
	  "优化采购退货功能，增加扫码快速退货",
	  "零库存销售时，系统增加提醒标识"]
	},
	
	{date: "2020-04-25",
	 content:
	 ["次卡充值时，消费次数可修改，以避免次卡充值方案过多",
	  "库存移仓增加草稿，以避免移仓数据丢失"]
	 },
	
	{date: "2020-04-19",
	 content:
	 ["增加需按年领取的会员礼品",
	  "修正开单负数问题",
	  "增加会员生日短信提醒"]
	},
	
	{date: "2020-04-16",
	 content:
	 ["增加会员生日公历/农历表示",
	  "开单界面增加公历/农历显示",
	  "会员生日增加公历/农历显示"]
	},
	
	{date: "2020-04-14",
	 content:
	 ["增加月/季/年卡有效期可更改",
	  "增加盘点差异单一键平仓功能，主要针对差异较大的情况下使用",
	  "盘点软件可扫描时可更改数量，针对无色无码货品，不再需要全部扫描，减少工作量"
	 ]
	},
	
	{date: "2020-03-07",
	 content:
	 ["日常费用增加可修改功能",
	  "入库单据增加帐号区分，方便多店时入库时区分由哪个端口入库"
	 ]
	},
	
	{date: "2020-1-30",
	 content:
	 ["盘点机增加扫描退货功能",
	  "增加盘点机对首次出现的包括颜色尺码的判定，以解决盘点时，仓库有时未挂版的问题",
	  "优化盘点机盘点功能，减少数据查询以加快盘点"
	 ]
	},
	
	{date: "2019-12-05",
	 content:
	 ["修正销售单可重复退货的问题，每张销售单中的货品仅可退一次",
	  "电子券送增加经手人",
	  "会员模块增加可赠送无销售额限制的电子券",
	  "修正多个店铺间移仓时，条码特定情况下不同步移动的问题"
	 ]
	},
	
	{date: "2019-11-30",
	 content:
	 ["优惠券增加使用阀值",
	  "修正货品修改图片时，查询仍然显示原来图片的问题",
	  "增加优惠券方案可删除，无需再废弃优惠券"
	 ]
	},

	{date: "2019-11-19",
	 content:
	 ["吊牌打印增加面料、里料、胆料、充绒量的选项打印"]
	},
	
	{date: "2019-11-14",
	 content:
	 ["开单扫码优化，有颜色或尺码的货品，扫码时不再弹出选择框，系统自动选择"]
	},
	
	{date: "2019-11-13",
	 content:
	 ["增加优惠券用券日期查询",
	  "增加支付明细支付条件查询",
	  "增加会员积分条件查询",
	  "增加货品自带条码可修改",
	  "增加会员余额卡模式，主要针对母婴、游乐场"]
	},
	
	{date: "2019-09-21",
	 content:
	 ["增加开单金额较验，避免把条码当金额扫入",
	  "增加支付明细查询",
	  "优惠电子券增加恢复功能"]
	},
	
	{date: "2019-09-16",
	 content:
	 ["增加多种电子券默认赠送策略，并可由用户主动修改赠送策略",
	  "完善电子券赠送流程，用户退货时，关联电子券自动废弃，不再需要用户主动点击",
	  "按单号退货时，智能判断券使用情况，并适当提示用户选择返券情况",
	  "实时报表增加净营业额，净毛利，净毛利率项"]
	},
	
	{date: "2019-07-21",
	 content:
	 ["开单增加支付宝项",
	  "销售记录增加支付宝统计",
	  "各报表增加支付宝统计",
	  "交班打印增加支付宝项"]
	},
	
	{date: "2019-06-26",
	 content:
	 ["增加店铺费用功能，商户可自定义费用类型(水费/电费等)",
	  "增加库存详情表格可收缩和扩展功能，以便商户在手机上查看库存数量"]
	},
	
	{date: "2019-06-24",
	 content:
	 ["增加按厂商店铺历史库存分析"]
	},
	
	{date: "2019-06-16",
	 content:
	 ["解决挂单再取单后，打印小标无客户联系方式的问题",
	  "解决在快速移仓模式下，均色均码与有色有码操作不一致的问题"]
	},
	
	{date: "2019-06-10",
	 content:
	 ["优化库存移仓，增加快速移仓模式，快速移仓模式下，扫码时不会弹出对话框",
	  "积分电子卷增加自动确信模式"]
	},
	
	{date: "2019-06-09",
	 content:
	 ["开单提取电子券增加纸质电子卷方式提取",
	  "优化扫码方式库存调出，扫码方式下不再需要输入调出数量",
	  "增加批发模式下的补单模式"]
	},
	
	{date: "2019-06-07",
	 content:
	 ["优化积分电子卷与优惠电子卷",
	  "完善优惠电子卷，取消纸质卷，直接绑定用户手机，并发送短信通知"]
	},
	
	{date: "2019-06-03",
	 content:
	 ["充值提现支持多种卡结算",
	  "优化次卡消费方式",
	  "增加折扣积分，某一折扣下，货品自动不计分"]
	},
	
	{date: "2019-05-26",
	 content:
	 ["优化部分促销方案算法",
	  "优化批量修改库存，不允许无条件批量修改库存"]
	},
	
	{date: "2019-05-06",
	 content:
	 ["会员充值功能扩展，会员余额可按次数与消费额度提现，如100提20，200提40",
	  "打印小票单增加打印选项配置"]
	},
	
	{date: "2019-05-03",
	 content:
	 ["盘点机功能增强，当实物货品超过电脑数据时，主动报警",
	  "盘点机功能增强，当实物货品第一次出现时，主动报警"]
	},
	
	{date: "2019-04-28",
	 content:
	 ["批售模式下增加并发开单时的实时库存检测",
	  "批售模式下增加部门可删除员工功能",
	  "批售模式下增加可按销售场景销售",
	  "批售模式下交易记录导出增加场景字段导出"]
	},
	
	{date: "2019-04-03",
	 content:
	 ["增加无厂商可退货配置"]
	},
	
	{date: "2019-03-18",
	 content:
	 ["库存详情增加区域筛选条件",
	  "采购明细增加区域筛选条件",
	  "日/月报表增加区域筛选条件上",
	  "批发销售增加批发价统计打印"]
	},
	
	{date: "2019-03-12",
	 content:
	 ["修正买M件N钱促销方式，当大于M件时，钱不改变的问题",
	  "修正库存在大类条件下无法导出的问题",
	  "N倍充值时，增加货品折扣充值",
	  "增加充值方式智能判断，智能调整售价",
	  "开单时，增加智能光标(条码，款号)跟随判断",
	  "修正充值会员免密码模式时，无法按单号退货问题",
	  "开单增加退货按键功能，不再需要用户主动输入负数表示",
	  "调入调出记录增加调出店铺与调入店铺条件过滤"]
	 },
	
	{date: "2019-03-11",
	 content:
	 ["修正开单时同一货品不能以不同价格出售的问题",
	  "优化盘点机App，增加同一货品扫描次数的显示"]
	},
	
	{date: "2019-03-02",
	 content:
	 ["增加买M件不同售价的促销方案"]
	},
	
	{date: "2019-02-28",
	 content:
	 ["优化开单键盘操作",
	  "估化开单时光标智能跳转能力"]
	},
	
	{date: "2019-02-21",
	 content:
	 ["优化入库键盘操作",
	  "优化开单入库操作",
	  "开单增加整单一口价功能"]
	},
	
	{date: "2019-01-26",
	 content:
	 ["优化小票打印，增加微信朋友圈二维码打印",
	  "修正使用三排条码打印纸时，纸张无法对齐的情况",
	  "修正货品属性修改时，同步修改库存",
	  "店铺增加上传微信付款码与朋友圈二维码功能",
	  "增加会员查询权限，非管理员用户无法列表会员信息"]
	},
	
	{date: "2018-12-29",
	 content:
	 ["优化小票打印，并增加会员余额打印",
	  "优化商品促销方案,增加对会员折扣的配置",
	  "交班报表增加登录帐号列"]
	},
	
	{date: "2018-12-29",
	 content:
	 ["优化小票打印，并增加会员余额打印",
	  "优化商品促销方案,增加对会员折扣的配置",
	  "交班报表增加登录帐号列"]
	},
	
	{date: "2018-12-23",
	 content:
	 ["优化买M送N促销方案，采用此方案时，系统自动获取单价最低的商品赠送",
	  "优化金额减免促销方案,可按实际情况根据不同金额减免，如200减50，300减80",
	  "优化N倍充值方案，销售时可选择多个商品充值，默认特价商品不能参与充值",
	  "修正库存特价标识时，需设置2次的问题"]
	},
	
	{date: "2018-12-13",
	 content:
	 ["修正开单时，新增会员无法实时打会员折扣的问题"]
	},
	
	{date: "2018-12-08",
	 content:
	 ["开单页面可新增会员",
	  "开单页面可修改会员名称，会员类型",
	  "开单业员可进行充值，N倍充值与普能充值分开",
	  "N倍充值可针对具体货品"]
	},
	
	{date: "2018-11-30",
	 content:
	 ["会员增加介绍人选项",
	  "优化盘点机在大量数据下的扫描速度"]
	},
	
	{date: "2018-11-23",
	 content:
	 ["增加交易明细打印",
	  "增加会员充值打印",
	  "修正部分bug, 优化程序性能"]
	},
	
	{date: "2018-11-09",
	 content:
	 ["增加https访问方式，解决dns劫持问题"]
	},
	
	{date: "2018-11-01",
	 content:
	 ["标签增加打印合格证字段"]
	},
	
	{date: "2018-10-17",
	 content:
	 ["优化标签打印"]
	},
	
	{date: "2018-10-16",
	 content:
	 ["增加盘点记录可导出",
	  "修正吊牌无法从库存中打印的问题"]
	},
	
	{date: "2018-10-13",
	 content:
	 ["增加员工业绩统计"]
	},
	
	{date: "2018-10-11",
	 content:
	 ["支持店铺同时选择多个条码打印模板，以支持不同的条码要求",
	  "增强条码打印模板，适应更多的条码打印要求"]
	},
	
	{date: "2018-10-06",
	 content:
	 ["采购入库界面增加删除货品资料功能，入错货品资料时可不需要离开该页面直接删除"]
	},
	
	{date: "2018-10-03",
	 content:
	 ["补单模式增加中增加现有库存查看",
	  "修正开单有时折扣变动问题"]
	},
	
	{date: "2018-09-29",
	 content:
	 ["销售开单界面回滚原来状态并优化",
	  "修正会员折扣有时不生效问题"]
	},
	
	{date: "2018-09-28",
	 content:
	 ["优化销售开单模式"]
	},
	
	{date: "2018-09-23",
	 content:
	 ["优化销售算法",
	  "修正由销售算法改动引起的问题"]
	},
	
	{date: "2018-09-15",
	 content:
	 ["增加购买不同数量的同品牌货品不同折扣的促销方式"]
	},
	
	{date: "2018-09-14",
	 content:
	 ["尺码个数扩展至999个",
	  "支持多种积分方案兑换钱方案"]
	},
	
	{date: "2018-09-11",
	 content:
	 ["修正负数退货时有时无法退货的问题",
	  "会员等级支持不同店铺不同会员定义",
	  "增加直接指定特价商品功能，不需要通过使用促销方案实现"]
	},
	
	{date: "2018-09-08",
	 content:
	 ["交易记录增加按收银员帐号区分营业额",
	  "支持最多三排条码打印",
	  "会员等级定义可编辑"]
	},
	
	{date: "2018-08-30",
	 content:
	 ["修正图片有时无法上传的问题"]
	},

	
	{date: "2018-08-15",
	 content:
	 ["盘点机增加盘点货品大类盘点方式",
	  "盘点机扫描系统不认识的条码时增加声音告警提示"]
	},
	
	{date: "2018-08-11",
	 content:
	 ["库存增加货品大类查询",
	  "交易明细增加款号，品牌模糊匹配功能",
	  "盘点机增加货品大类盘点"]
	},
	
	{date: "2018-07-19",
	 content:
	 ["销售单据打印增加颜色尺码", 
	  "交班报表中可在小票打印机上打印当天销售明细",
	  "采购退货单可以小票打印机上打印",
	  "增加盘点记录可打印"]
	},
	
	{date: "2018-07-09",
	 content:
	 ["交易明细可通过配置来是否直接显示颜色与尺码",
	  "库存详情增加吊牌价统计显示"]
	},
	
	{date: "2018-07-08",
	 content:
	 ["优化开单操作，同一款号多次开单时自动跳转到修改项",
	  "优化开单界面，颜色尺码与数量一同显示"]
	},
	
	{date: "2018-06-27",
	 content:
	 ["优化入库操作， 入库动态增加颜色与数量时，不需要离开当前页面"]
	},
	
	{date: "2018-06-21",
	 content:
	 ["增加销售可按货品大类查询",
	  "增加销售可按性别查询"]
	},
	
	{date: "2018-06-20",
	 content:
	 ["增加厂商大类，多个厂商可以归属于一个厂商大类",
	  "增加采购单按厂商大类批量打印，如退货单可一次性批量打印",
	  "增加扫码退货配置"]
	},
	
	{date: "2018-06-14",
	 content:
	 ["增加品类开单时，库存为0的货品不显示",
	  "权限优化，价格修改权限与价格查看权限分开",
	  "会员折扣模式优化",
	  "条码价格字段大小可定制",
	  "条码增加可打印入库日期",
	  "开单修改价格时，增加回车键控制"]
	},
	
	{date: "2018-06-11",
	 content:
	 ["修正会员折扣模式以适应更多场景"]
	},
	
	{date: "2018-06-10",
	 content:
	 ["条码打印增加款号是否换行打印选项",
	  "货品退货期限可在入库时输入，精确到款"]
	},
	
	{date: "2018-06-06",
         content:
	 ["增加品类开单模式，以适应家访店开单模式",
	  "移仓增加扫描枪模式移仓",
	  "小票单增加打印店铺地址项",
	  "小票单增加微信收款项"]
        },
	
	{date: "2018-05-16",
         content:
	 ["调出明细增加导出功能",
	  "完善货品资料中款号查询",
	  "结帐详情中增加店铺过滤条件",
	  "厂商对帐增加导出功能"]
        },
	
	{date: "2018-04-28",
         content:
	 ["库存查询增加模糊匹配，即匹配以某个款号开头",
	  "增加库存联想至少输入3个字符的限制",
	  "当设置折扣促销时，当货品原折扣小于促销折扣时，会自动采用原折扣"]
        },
	
	{date: "2018-04-26",
         content:
	 ["补单模式默认按销售数量排序"]
        },
	
	{date: "2018-04-24",
         content:
	 ["增加自定义核销范围设置"]
        },
	
	{date: "2018-04-23",
         content:
	 ["新增会员增加等级选择"]
        },
	
	{date: "2018-04-16",
         content:
	 ["增加会员自动升级功能",
	  "支持会员折扣与会员折上折功能"]
        },
	
	{date: "2018-04-14",
         content:
	 ["手机开放入库，查看厂商进销存功能",
	  "修正多店铺入库同一款货品，厂商不同时无法选择的问题"]
        },
	
	{date: "2018-04-06",
         content:
	 ["修正提现，电子卷不积分时，电子卷积分的问题",
	  "修正提现，电子卷不积分时，核销引起的积分问题",
	  "修正后台打印，小票积分重复打印问题"]
        },
	
	{date: "2018-03-25",
         content:
	 ["增加买M送N促销方式",
	  "修正后台打印交班报表有时无法打印的问题",
	  "后台打印交班报表可选择日期打印"]
        },
	
	{date: "2018-03-22",
         content:
	 ["增加会员折扣功能，即会员可享受单独折扣"]
        },
	
	{date: "2018-02-03",
         content:
	 ["修正次/月/季/年/卡充值同时删除后重新充值不成功的问题"]
        },
	
	{date: "2018-01-31",
         content:
	 ["增加次/月/季/年卡消费模式"]
        },
	
	{date: "2017-01-21",
         content:
	 ["修正入库记录与录入顺序不一致的问题"]
        },
	
	{date: "2017-12-10",
         content:
	 ["批量制卷时，调整允许最大金额为5000",
	  "增加限制充值用户指定区域提现功能"]
        },
	
	{date: "2017-11-10",
         content:
	 ["根据财务修改厂商进销存统计字段与算法"]
        },
	
	{date: "2017-11-09",
         content:
	 ["修正修改采购记录时有时会导致与采购明细的厂商不一致的问题",
	  "修改采购记录时，展现的历史记录按时间排序"]
        },
	
	{date: "2017-11-06",
         content:
	 ["增加批量制作电子券功能"]
        },
	
	{date: "2017-11-03",
         content:
	 ["销售交易记录增加备注过滤条件",
	  "修改相关权限关联问题"]
        },
	
	{date: "2017-10-25",
         content:
	 ["增加单一厂商货品盘点"]
        },
	
	{date: "2017-10-23",
         content:
	 ["增加厂商退货期限设置",
	  "条码可打印厂商对应的货品退货期限",
	  "增加可打印双排条码纸设置",
	  "交易明细增加季节过滤项",
	  "修正不能导出特定生日的会员问题"
	 ]
        },
	
	{date: "2017-10-10",
         content:
	 ["增加可查找当天生日的会员",
	  "无线扫描盘点模式改进",
	  ]
        },
	
	{date: "2017-10-07",
         content:
	 ["增加均码货品不能增加尺码组的限制",
	  "修正移仓时尺码组不同步导致开单有库存但无法显示的问题",
	  "销售交易明细增加补单模式选项，按款号品牌统计并显示颜色尺码",
	  "增加盘点机盘点功能"]
        },
	
	{date: "2017-09-28",
         content:
	 ["增加员工修改入职日期功能",
	  "增加调出记录删除的权限控制"]
        },
	
	{date: "2017-09-22",
         content:
	 ["修正新增会员时有时出现系统内部错误的问题",
	  "修正入库时，厂商选择后再删除时，出现无法入库的问题",
	  "修正使用单号退时，小票打印异常问题",
	  "增加小票居中显示"]
        },
	
	{date: "2017-09-17",
         content:
	 ["支持入库/移仓单自定义纸张大小",
	  "增加吊牌打印时，自定义成份字体大小"]
        },
	
	{date: "2017-09-16",
         content:
	 ["修正盘点时数量过多引起的显示问题"]
        },
	
	{date: "2017-09-13",
         content:
	 ["增加配置打印机功能"]
        },
	
	{date: "2017-09-08",
         content:
	 ["入库/调价草稿只保留一份",
	  "解决有色均码的货品扫条码时条码时数量不自动置1的问题"]
        },
	
	{date: "2017-08-29",
         content:
	 ["增加厂商进销存可按销售数量与库存数量排序",
	  "增加厂商进销存导出excel表格能力"]
        },
	
	{date: "2017-08-29",
         content:
	 ["增加采购单据打印功能",
	  "增加店铺调出单打印功能",
	  "修正移仓时，条码无法同步的问题"]
        },
	
	{date: "2017-08-27",
         content:
	 ["修正均色均码无法扫条形码的问题",
	  "增加货品类型大类，一个货品类型同时只能属于一个品类",
	  "标签打印可以打印尺码规格描述"]
        },
	
	{date: "2017-08-17",
         content:
	 ["条码打印增加打印模板以定制条码打印内容"]
        },
	
	{date: "2017-08-14",
         content:
	 ["增加销售明细颜色尺码导出功能"]
        },
	
	{date: "2017-08-12",
         content:
	 ["增加自定义条码设置"]
        },
	
	{date: "2017-08-08",
         content:
	 ["库存导出增加颜色，尺码导出配置",
	  "增加导出格式配置，以兼容WPS，Office",
	  "放开交易明细小计统计的权限，增加差价显示",
	  "调整关于库存操作的一些权限设置，如导出功能等",
	  "库存调价模式增加价格直减的模式"]
        },
	
	{date: "2017-08-03",
         content:
	 ["修正条码有时无法扫描识别的问题",
	  "增加营业员可查看所有库存的配置项",
	  "条码打印增加是否打印厂商配置项",
	  "增加退货是否检测进价配置项"]
        },
	
	{date: "2017-07-29",
         content:
	 ["会员增加会员卡号功能",
	  "修正库存盘点若干问题"]
        },
	
	{date: "2017-07-13",
         content:
	 ["增加条码功能，系统支持入库打印条码，开单支持条码扫描",
	  "条码大小支持各种纸张规格",
	  "小票打印增加打印颜色尺码能力配置",
	  "移仓增加是否检测进价配置"]
        },
	
	{date: "2017-06-20",
         content:
	 ["增加入库是否校验厂商配置项"]
        },

	{date: "2017-06-15",
         content:
	 ["修正入库记录导出时，已废弃单据记录同时导出的问题",
	  "修正移仓时，导至上架日期偶尔为0的问题"]
        },

	{date: "2017-05-25",
         content:
	 ["增加充值记录可修改店铺与经手人",
	  "修正充值时营业员只能选择与店铺相关的营业员",
	  "会员导出增加店铺过滤功能"]
        },
	
	{date: "2017-05-11",
         content:
	 ["增加入库单进价查询",
	  "增加入库单导出功能",
	  "厂商对帐中增加款号，品牌查询"]
        },
	
	{date: "2017-05-03",
         content:
	 ["增加入库单厂商为空时，无法审核",
	  "增加入库进价校验"]
        },
	
	{date: "2017-05-01",
         content:
	 ["充值会员返现时，增加短信提示",
	  "增加管理员可修改进价能力"]
        },
	
	{date: "2017-04-28",
         content:
	 ["解决N+1倍充值时，刷卡不赠送现金的问题",
	  "解决N+1倍充值时，刷卡，微信赠送现金不显示问题",
	  "解决移仓时，货品上架日期会改变的问题"]
        },
	
	{date: "2017-04-27",
         content:
	 ["充值付款方式增加现金，刷卡，微信选项",
	  "日报增加充值现金，刷卡，微信统计",
	  "解决前台打印时，营业员信息重叠问题",
	  "交班报表增加充值内容"]
        },
	
	{date: "2017-04-23",
         content:
	 ["充值方案增加倍数充值模式"]
        },
	
	{date: "2017-02-18",
         content:
	 ["货品价格可直接弹出窗口修改修改",
	  "增加货品数量预警",
	  "增加货品存放的货柜号"]
        },
	
	{date: "2017-01-24",
         content:
	 ["厂商进销存增加厂商过滤条件",
	  "增加会员删除限制条件，存在销售记录的会员不能被删除",
	  "厂商删除啬限制条件，存在入库记录的厂商无法被删除"]
        },
	
	{date: "2017-01-22",
         content:
	 ["增加销售单能删除功能，退货单不能删除",
	  "修正不能修改货品款号与品牌的问题",
	  "增加销售单号联想功能"]
        },
	
	{date: "2017-01-21",
         content:
	 ["库存调价，增加款号联想方式，并在不同的调价模式下显示不同的库存"]
        },
	
	{date: "2017-01-18",
         content:
	 ["修改销售退单不再限制1个月之内，统一退单时单号查询方式",
	  "增加按区域填写补单价格配置项，保证同一区域内同一货品的价格相同"]
        },
	
	{date: "2017-01-17",
         content:
	 ["增加会员提现上限功能"]
        },
	
	{date: "2017-01-16",
         content:
	 ["会员增加区域过滤项，可按区域查询该区域内的会员",
	  "厂商对帐时，可按区域过滤",
	  "库存导出增加厂商排序"]
         },
	
	{date: "2017-01-15",
         content:
	 ["增加厂商一段时间内的进销存报表分析"]
        },
	
	{date: "2017-01-13",
         content:
	 ["增加销售开单/退货时间与服务器时间校验，误差不允许超过30分钟",
	  "增加采购入库/退货/移仓时间较验，误差不允许超过2小时",
	  "增加采购入库/退货/移仓数量服务器端较验，确保数据正确性",
	  "增加会员充值记录导出",
	  "会员充值记录增加让铺过滤选项",
	  "增加交易记录导出功能",
	  "增加交易明细导出功能"]
        },
	
	{date: "2017-01-10",
         content:
	 ["修正开单时，部分错误无法弹出问题",
	  "修改销售单时，对充值会员增加退款短信提示",
	  "修改货品资料时，禁止修改款号，品版，进货价"]
        },
	
	{date: "2017-01-08",
         content:
	 ["修正修改采购入（退）库时，偶尔闪烁问题",
	  "采购入库（退）支持键盘上下左右键操作"]
        },
	
	{date: "2017-01-07",
         content: ["修正偶尔出现空白内容的问题"]
        },
	
	{date: "2016-12-31",
         content: ["加强会员录入约束条件",
		   "会员增加身份证字段，以便核对会员信息",
		   "会员增加帐户余额与累计消费排序",
		   "优化会员查询功能，优化服务器性能",
		   "短信充值实时生效",
		   "修正导出excel文件时发生乱码现象"]
        },
	
	{date: "2016-12-28",
         content: ["增加充值短信提醒功能",
		   "增加会员消费短信提醒功能",
		   "增加会员导出功能"]
        },
	
	{date: "2016-12-27",
         content: ["增加微信付款选项",
		   "报表增加微信统计项"]
        },
	
	{date: "2016-12-24",
         content: ["增加会员对帐功能"]
        },
	
	{date: "2016-12-18",
         content: ["增加月报表导出功能"]
        },
	
	{date: "2016-12-17",
         content: ["增加月报表"]
        },
	
	{date: "2016-12-16",
         content: [
	     "修正销售单数量为负数时，不允许进行退货处理",
	     "增加管理员可以修改入库（退货）单日期" 
	 ]
        },
	
	{date: "2016-12-11",
         content: [
	     "修正负数退货时，不输入退货金额也可以退单问题"
	 ]
        },
	
	{date: "2016-12-10",
         content: [
	     "增加无厂商的货品不能进行移仓限制",
	     "修正销售退货单无上架日期的问题"
	 ]
        },
	
	{date: "2016-12-06",
         content: [
	     "厂商对帐按时间顺序排序"
	 ]
        },
	
	{date: "2016-11-18",
         content: [
	     "增加颜色可编辑功能",
	     "增加充值方案可以删除功能"
	 ]
        },
	
	{date: "2016-11-16",
         content: [
	     "所有报表增加提现，电子券统计" 
	 ]
        },
	
	{date: "2016-11-15",
         content: [
	     "增加电子卷功能，用户可设置每天晚上自动生成电子卷，电子卷可与会员自动关联",
	     "修正多个货品退货时，只退一个货品引起付款方式不正确的问题",
	     "增加条件过滤时夫则，/06/表示只匹配06的货号，06/表示匹配以06结尾的货号",
	     "增加销售单可修改会员"
	 ]
        },
	
	{date: "2016-11-11",
         content: [
	     "优化开单，入库时款号提示算法，款号最短的最先提示",
	     "厂商对帐，溢出数量默认不显示",
	     "条件过滤时，款号联想增加06, /06, 06/分别为等于，以06开头，以06结尾的方式" 
	 ]
        },
	
	{date: "2016-11-09",
         content: [
	     "厂商对帐明细增加溢出字段，并增加溢出统计",
	     "入库单条件过滤优化",
	     "厂商过滤支持模糊匹配",
	     "修正入库单吊牌价统计方式",
	     "入库时增加已有库存显示",
	     "交易明细中增加到货年度显示"
	 ]
        },
	
	{date: "2016-11-02",
         content: [
	     "增加库存流水跟踪" ,
	     "增加员工状态（在职，离职）处理",
	     "增加入库单吊牌价统计"
	 ]
        },
	
	{date: "2016-11-01",
         content: [
	     "修正修改入库记录时，页面偶尔闪烁问题" ,
	     "增加货品尺码动态增加能力" 
	 ]
        },
	
	{date: "2016-10-31",
         content: [
	     "对帐备注可以输入小数点" ,
	     "增加厂商退货单价格修改权限，默认不开放此权限",
	     "增加开单时后台校验能力",
	     "采购记录中不显示对帐单",
	     "修正废弃单据可修改问题"
	 ]
        },
	
	{date: "2016-10-20",
         content: [
	     "采购记录增加区域查询" ,
	     "厂商对帐增加明细统计",
	     "厂商对帐增加备注功能",
	     "厂商对帐增加审核，反审功能"
	 ]
        },
	
	{date: "2016-10-13",
         content: [
	     "移仓单可删除" ,
	     "采购明细价格小计统计",
	     "移仓记录增加店铺过滤条件",
	     "非管理员用户查看实时报表库存不正确问题",
	     "单款流水审核过多时，增加翻页处理，避免流水过长引而遮盖审核库存"
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

	    var apk = "<div class='update-content'>"
		+ "<a type='button' href='/qzg_stock_fix-release2021-10-22_23-18-22.apk' download=''>"
		+ "<h5 class='text-center fg-pink'>盘点机软件(安卓)下载</h5>"
		+ "</a>"
		+ "</div>"
	    $('body').append(apk);

	    // var scan_apk = "<div class='update-content'>"
	    // 	+ "<a type='button' href='/iScan-V4.3.1.apk' download=''>"
	    // 	+ "<h5 class='text-center fg-pink'>盘点机辅助软件(安卓)下载</h5>"
	    // 	+ "</a>"
	    // 	+ "</div>"
	    // $('body').append(scan_apk);
	    
	    $('body').append(content);

	    var filing = "<div class='update-content'>"
		+ "<a type='butthon' href='http://www.beian.miit.gov.cn/'>"
		+ "<h5 class='text-center fg-pink'>粤ICP备19078475号</h5>"
		+ "</a>"
		+ "</div>"
	    $('body').append(filing);
		// .append("<div class='copyright'><span> 2015-2025 &copy;&nbsp钱掌柜&nbsp&nbsp&nbsp&nbsp</span>"
		// 			     + "<span><i class='glyphicon glyphicon-star'></i>"
		// 			     + "QQ群：261033201"
		// 			     + "</span></div>");
	}
    } 
}();
