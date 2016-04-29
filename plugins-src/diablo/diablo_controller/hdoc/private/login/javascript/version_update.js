var version_update = function(){
    
    var updates = [
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
