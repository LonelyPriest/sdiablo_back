var version_update = function(){
    
    var updates = [
	// {date: "2015-12-17",
	//  content: [
	//      "库存销售统计分布增加前进后退功能",
	//      "优化打印处理",
	//      "优化手机，平板横屏，竖屏内容显示"
	//  ]
	// } 
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
