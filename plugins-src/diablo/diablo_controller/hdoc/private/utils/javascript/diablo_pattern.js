angular.module("diabloPattern", []).service("diabloPattern", [function(){
    // mobile
    this.mobile = /^0?(13[0-9]|15[0-35-9]|17[35-8]|18[0-9]|14[57])[0-9]{8}$/;

    // telphone or mobile
    this.tel_mobile = /^\d{3,4}[\-]?\d{7,8}(-\d{3,4})?$|^0?(13[0-9]|15[0-35-9]|17[35-8]|18[0-9]|14[57])[0-9]{8}$/;

    // only number
    this.number = /^[0-9]*$/;
    
    this.positive_num = /^[1-9][0-9]*$/;
    this.expire_date = /^[1-9][0-9]*$|-1$/;
    
    this.positive_decimal_2 = /^\d+(\.\d{1,2})?$/;
    
    this.decimal_2 = /^[+|\-]?\d+(\.\d{1,2})?$/;

    this.number_2 = /^[0-9]{1,2}$/; 
    this.number_3 = /^[0-9]{1,3}$/;
    this.number_4 = /^[0-9]{1,4}$/;
    this.date = /^[0-9]{8}$/;
    
    this.percent  = /^\d{1,2}(\.\d{1,2})?$|100$/;
    this.size_specific = /^[A-Za-z0-9\/\s]{2,}$/;
    
    // this.discount = /^\d{2}$|100$/;
    this.discount = /(^\d{1,2}(\.\d{1,2})?)$|100$/;

    this.integer_except_zero = /^[+|\-]?[1-9][0-9]*$/

    // character or number
    this.char_number = /^[A-Za-z0-9]+$/;

    this.semicolon_number = /[0-9\;]+$/;

    // character, number or -
    this.char_number_slash_bar = /^[A-Za-z0-9-\/]{2,20}$/;

    this.char_number_space_slash_bar = /^[A-Za-z0-9-\/\s]{2,}$/;

    this.char_number_space_chinese = /^[A-Za-z0-9\u4e00-\u9fa5\s]{2,}$/;

    this.id_card = /^[A-Za-z0-9]{8,18}$/;

    this.card = /^9[A-Za-z0-9]{3,18}$/;

    // character, number or _
    this.char_number_underline = /^\w+$/;

    // comment
    this.comment = /^[\u4e00-\u9fa5A-Za-z0-9\-_\.\;\uFF00-\uFFFF]+$/;

    // size group
    this.size = /^[A-Za-z0-9\/]{1,3}$/;
    this.home_size = /^[0-9\*\/]{3,8}$/;

    this.chinese = /^[\u4e00-\u9fa5]+$/;
    
    this.chinese_name = /^[0-9\u4e00-\u9fa5]{2,6}$/;
    this.chinese_lname = /^[0-9A-Za-z\u4e00-\u9fa5]{2,20}$/;

    this.ch_en_num = /^[\u4e00-\u9fa5A-Za-z0-9]+$/;
    
    this.head_ch_en_num  = /^[\u4e00-\u9fa5][\u4e00-\u9fa5A-Za-z0-9\s]+$/;
    this.good_type  = /^[\u4e00-\u9fa5A-Za-z0-9\-\s]+$/;

    this.ch_name_address = /^[\u4e00-\u9fa5A-Za-z0-9\-_\s]+$/;

    this.ch_en_num_beside_underline_bars = /^[\u4e00-\u9fa5A-Za-z0-9\-_\/]{4,20}$/;

    // this.style_number = /^[A-Za-z0-9\-\#]{2,20}$/;
    this.style_number = /^[A-Za-z0-9\u4e00-\u9fa5\-\#\/]{2,20}$/;
    this.brand = /^[\u4e00-\u9fa5A-Za-z0-9\&\/\-]+$/;

    // this.passwd = /^(?=.*[A-Z])(?=.*[a-z])(?=.*[0-9])[a-zA-Z0-9]{6,15}/;
    this.passwd = /^(?=.*[a-zA-Z])(?=.*[0-9])[a-zA-Z0-9]{6,15}/;

    this.num_passwd = /^\d{6}$/;
    this.bsaler_code = /^\d{9}$/;

    this.color=/^[A-Za-z0-9-_\u4e00-\u9fa5]{1,3}$/;

    this.url = '^((https|http|ftp|rtsp|mms)?://)'
	+ '?(([0-9a-z_!~*\'().&=+$%-]+: )?[0-9a-z_!~*\'().&=+$%-]+@)?' //user@ of ftp
	+ '(([0-9]{1,3}.){3}[0-9]{1,3}' // IP199.194.52.184
	+ '|' // or domain
	+ '([0-9a-z_!~*\'()-]+.)*' // domain - www.
	+ '([0-9a-z][0-9a-z-]{0,61})?[0-9a-z].' // level-2 domain
	+ '[a-z]{2,6})' // first level domain
	+ '(:[0-9]{1,4})?' // port :80
	+ '((/?)|' // a slash isn't required if there is no file name
	+ '(/[0-9a-zA-Z_!~*\'().;?:@&=+$,%#-]+)+/?)$';
}]);
