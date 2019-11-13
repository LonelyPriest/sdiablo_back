-- 2016-05-15
/*
*change ediscount
*/
alter table w_inventory_good modify column ediscount decimal(4,1) default 0;
alter table w_inventory modify column ediscount decimal(4,1) default 0;
alter table w_inventory_new_detail modify column ediscount decimal(4,1) default 0;
alter table w_sale_detail modify column ediscount decimal(4,1) default 0;

update w_inventory set ediscount=100 where merchant=2 and ediscount != 100;
update w_inventory a set a.ediscount=0 where style_number='zp'; 
update w_inventory a set a.ediscount=(a.org_price/a.tag_price)*100;

update w_inventory_new_detail a set a.ediscount=(a.org_price/a.tag_price)*100;
update w_inventory_new_detail set merchant=2 where rsn like 'M-2%';
update w_inventory_new_detail a set a.ediscount=0 where style_number='zp'; 

update w_sale_detail a set a.ediscount=(a.org_price/a.tag_price)*100 where a.tag_price != 0;
update w_sale_detail a set a.ediscount=0 where style_number='zp';


-- 2016-05-17
alter table w_inventory_new_detail modify column discount decimal(4,1) default 0;
alter table w_inventory_good modify column discount decimal(4,1) default 0;
alter table w_inventory modify column discount decimal(4,1) default 0;

-- 2016-05-25
alter table w_sale_detail add column shop integer default -1;
alter table w_sale_detail_amount add column shop integer default -1;
alter table w_inventory_new_detail add column shop integer default -1;
alter table w_inventory_new_detail_amount add column shop integer default -1;
alter table w_inventory_fix_detail add column shop integer default -1;
alter table w_inventory_fix_detail_amount add column shop integer default -1;

alter table w_inventory_transfer_detail add column fshop integer default -1;
alter table w_inventory_transfer_detail add column tshop integer default -1;
alter table w_inventory_transfer_detail_amount add column fshop integer default -1;
alter table w_inventory_transfer_detail_amount add column tshop integer default -1;


alter table w_inventory_fix modify column shop integer default -1;


update w_inventory_new_detail set shop=1 where rsn like 'm-1-s-1-%';
update w_inventory_new_detail_amount set shop=1 where rsn like 'm-1-s-1-%';

update w_inventory_new_detail set merchant=2, shop=2 where rsn like 'm-2-s-2-%';
update w_inventory_new_detail_amount set merchant=2, shop=2 where rsn like 'm-2-s-2-%';


update w_sale_detail set merchant=1, shop=1 where rsn like 'm-1-s-1-%';
update w_sale_detail_amount set merchant=1, shop=1 where rsn like 'm-1-s-1-%';
update w_sale_detail set merchant=2, shop=2 where rsn like 'm-2-s-2-%';
update w_sale_detail_amount set merchant=2, shop=2 where rsn like 'm-2-s-2-%';

-- 2016-06-07
update w_inventory_good set color='10,11' where id=628;
update w_inventory_good set color='5,16' where id=599;
update w_inventory_good set color='2,6' where id=425;
update w_inventory_good set color='14,15' where id=558;
update w_inventory_good set color='16' where id=590;
update w_inventory_good set color='2' where id=480;
update w_inventory_good set color='6,8' where id=321;

alter table users add column employee varchar(8) default '-1';

-- 2016-06-09
alter table employees add column shop integer default -1;
update employees set shop=3 where id in (3, 4);
update employees set shop=2 where id in (1);
update employees set shop=1 where id in (2);

alter table users add column shop integer default -1;

-- 2016-06-16
alter table w_retailer add column type tinyint default 0;
alter table w_retailer add column birth date default 0;
alter table w_retailer add column shop integer default -1;
alter table suppliers add column comment varchar(256) default null;

-- 2016-06-22
source db.sql; -- add table firm_balance_history


-- 2016-07-08
-- add region of shop
alter table shops add column region integer default -1;


-- 2016-07-16
alter table w_daily_report add column stockc integer not null default -1;
alter table users add column sdays integer default 0;

-- 2016-08-05
alter table color_type add column merchant integer default 0;
insert into color_type(name, merchant) values('波司登专用', 4);


-- 2016-10-30
update w_sale_detail set style_number='M6-11' where rsn='M-4-S-20-7095';
update w_sale_detail_amount set style_number='M6-11' where rsn='M-4-S-20-7095';

update w_inventory set amount=amount-1, sell=sell+1 where style_number='m6-11' and shop=20;
update w_inventory_amount set total=total-1 where style_number='m6-11' and shop=20;


-- 2016-11-01
delete from w_inventory_good where merchant=3 and brand!=2537;
delete from w_inventory where merchant=3 and brand!=2537;
delete from w_inventory_amount where merchant=3 and brand!=2537;

delete from w_inventory_new where merchant=3 and rsn not in (select x.rsn from (select a.rsn from w_inventory_new a inner join (select rsn from w_inventory_new_detail where rsn like 'M-3%' and brand=2537) b on a.rsn=b.rsn)x);

delete from w_inventory_new_detail where rsn like 'M-3%' and rsn not in (select x.rsn from (select a.rsn from w_inventory_new a inner join (select rsn from w_inventory_new_detail where rsn like 'M-3%' and brand=2537) b on a.rsn=b.rsn)x);

delete from w_inventory_new_detail_amount where rsn like 'M-3%' and rsn not in (select x.rsn from (select a.rsn from w_inventory_new a inner join (select rsn from w_inventory_new_detail where rsn like 'M-3%' and brand=2537) b on a.rsn=b.rsn)x);

delete from w_sale where merchant=3 and rsn not in('M-3-S-30-1449', 'M-3-S-30-1438');
delete from w_sale_detail where rsn like 'M-3%' and rsn not in('M-3-S-30-1449', 'M-3-S-30-1438');
delete from w_sale_detail_amount where rsn like 'M-3%' and rsn not in('M-3-S-30-1449', 'M-3-S-30-1438');

delete from w_daily_report where merchant=3;
delete from w_change_shift where merchant=3;
delete from w_bill_detail where merchant=3;


-- 2016-11-08
alter table w_sale_detail add column in_datetime DATETIME default 0;

-- 2016-11-12
alter table w_sale add column ticket decimal(10,2) default 0;
alter table w_sale change column promotion tbatch integer default -1;


-- 2016-11-16
alter table w_daily_report add column draw decimal(10,2) default 0;
alter table w_daily_report add column ticket decimal(10,2) default 0;


-- 2016-12-02
alter table w_inventory_new add column op_date datetime default 0;
alter table w_bill_detail add column op_date datetime default 0;

update w_inventory_new s inner join (select id, entry_date from w_inventory_new) b on s.id=b.id set s.op_date=b.entry_date;
update w_bill_detail s inner join (select id, entry_date from w_bill_detail) b on s.id=b.id set s.op_date=b.entry_date;


-- 2016-12-26
alter table merchants add column balance DECIMAL(10, 2) not null default 0;

-- 2016-12-27
alter table w_sale add column wxin DECIMAL(10, 2) not null default 0;
alter table w_daily_report add column wxin DECIMAL(10, 2) not null default 0;
alter table w_change_shift add column wxin DECIMAL(10, 2) not null default 0;
alter table w_change_shift add column withdraw DECIMAL(10, 2) not null default 0;
alter table w_change_shift add column ticket DECIMAL(10, 2) not null default 0;


-- 2016-12-28
insert into sms_center(url, app_key, app_secret, sms_sign_name, sms_sign_method, sms_send_method, sms_template, sms_type, sms_version) \
values("http://gw.api.taobao.com/router/rest", "23581677", "eab38d8733faf9d5c813a639afbcfbf2", "钱掌柜", "md5", "alibaba.aliqin.fc.sms.num.send", "SMS_36280065", "normal", "2.0");

-- 2016-12-29
alter table merchants add column sms_send integer not null default 0;
alter table merchants drop column province;
alter table sms_rate drop column send;


-- 2016-12-30
alter table w_retailer add column py VARCHAR(8) not null;
alter table w_retailer add column id_card VARCHAR(18) default null;

-- 2017-01-16
alter table w_charge add column type TINYINT default 0 after balance;
alter table shops add column draw INTEGER default -1 after charge;
alter table w_retailer add column draw INTEGER default -1 after shop;


-- 2017-02-17
alter table w_inventory_good add column contailer INTEGER default -1 after alarm_day;
alter table w_inventory_good add column alarm_a INTEGER default -1 after contailer;

alter table w_inventory add column contailer INTEGER default -1 after sell;
alter table w_inventory add column alarm_a INTEGER default -1 after contailer;

-- alter table w_inventory_amount add column contailer INTEGER default -1 after shop;
alter table w_inventory_amount add column alarm_a INTEGER default -1 after shop;



-- 2017-04-22
alter table w_charge add column rule TINYINT default 0 after name;
alter table w_charge add column xtime TINYINT default 1 after rule;

-- 2017-04-26
alter table w_charge_detail add column cash INTEGER not null default 0 after cbalance;
alter table w_charge_detail add column card INTEGER not null default 0 after cash;
alter table w_charge_detail add column wxin INTEGER not null default 0 after card;

alter table w_change_shift add column charge INTEGER not null default 0 after ticket;
alter table w_change_shift add column ccash INTEGER not null default 0 after charge;
alter table w_change_shift add column ccard INTEGER not null default 0 after ccash;
alter table w_change_shift add column cwxin INTEGER not null default 0 after ccard;


-- 2017-06-10
alter table w_daily_report add column charge DECIMAL(10, 2) not null default 0 after ticket;


-- 2017-07-03
alter table suppliers add column bcode INTEGER default 0 after id;
alter table colors add column bcode INTEGER default 0 after id;
alter table brands add column bcode INTEGER default 0 after id;
alter table inv_types add column bcode INTEGER default 0 after id;
alter table w_inventory add column bcode VARCHAR(32) default 0 after id;


-- 2017-07-23
alter table w_retailer modify column card VARCHAR(18) default null;
drop table w_inventory_fix;
drop table w_inventory_fix_detail;
drop table w_inventory_fix_detail_amount;


-- 2017-08-11
alter table w_inventory_good add column bcode VARCHAR(32) default 0 after id;
alter table w_inventory_good add index bcode (bcode);
alter table w_inventory add index bcode (bcode);

-- 2017-08-16
alter table w_inventory_good add column level TINYINT default -1 after path;
alter table w_inventory_good add column executive INTEGER default -1 after level;
alter table w_inventory_good add column category INTEGER default -1 after executive;
alter table w_inventory_good add column fabric VARCHAR(256) default null after category;


-- 2017-08-19
alter table print_template add column font_name VARCHAR(32) default "" after font;
alter table print_template add column font_executive TINYINT default 0 after font_name;
alter table print_template add column font_category TINYINT default 0 after font_executive;
alter table print_template add column font_price  TINYINT default 0 after font_category;
alter table print_template add column font_fabric TINYINT default 0 after font_price;

alter table print_template add column hpx_executive TINYINT default 0 after hpx_each;
alter table print_template add column hpx_category TINYINT default 0 after hpx_executive;
alter table print_template add column hpx_fabric TINYINT default 0 after hpx_category;

-- 2017-08-26
alter table inv_types add column ctype INTEGER default -1 after bcode;


-- 2017-08-27
alter table w_inventory_transfer_detail add column bcode VARCHAR(32) default 0 after rsn;

-- 2017-09-20
alter table print_template add column code_firm TINYINT default 0 after firm;

alter table w_retailer add column comment VARCHAR(255) after entry_date;

-- 2017-10-19
alter table suppliers add column expire INTEGER default -1 after address;
alter table print_template add column expire TINYINT default 0 after code_firm;
-- alter table print_template add column dual_column TINYINT default 0 after height;
alter table print_template add column second_space TINYINT default 0 after hpx_left;

drop index uk on w_inventory_new_detail_amount;
alter table w_inventory_new_detail_amount add unique index uk(rsn, style_number, brand, color, size);
alter table w_inventory_new_detail_amount add index dk(merchant, shop, style_number, brand);
-- alter table print_template modify column width DECIMAL(3, 1) default 0;

-- 2017-10-25
alter table w_inventory_fix add column firm INTEGER default -1 after shop;

-- 2017-10-26
delete from w_inventory_amount where shop=53 and style_number='1' and brand=4734;
delete from w_inventory_amount where shop=53 and style_number='1' and brand=4826;
delete from w_inventory_amount where shop=53 and style_number='1' and brand=4856;
delete from w_inventory_amount where shop=53 and style_number='9396' and brand=5612;
delete from w_inventory_amount where shop=53 and style_number='9988' and brand=4970;
update w_inventory set amount=0 where shop=53 and style_number='0001' and brand=4734;
update w_sale set total=-2 where rsn='M-15-S-53-R-444';
update w_sale set total=-2 where rsn='M-15-S-56-R-459';
update w_sale set total=-2 where rsn='M-15-S-58-R-434';

-- 2017-11-05
alter table w_sale add column tcustom TINYINT default -1 after tbatch;

--2018-01-02
alter table print_template add column shop TINYINT default 0 after height;


-- 2018-01-02
alter table w_charge add column ctime INTEGER default -1 after xtime;

-- 2018-01-31
alter table w_card add column cid INTEGER default -1 after edate;
alter table w_card_sale add column cid INTEGER default -1 after card;


--2018-02-03
alter table w_charge_detail add column ledate DATE default 0 after cid;


--2018-03-18
alter table w_retailer add column level TINYINT default 0 after name;
update w_retailer set level=-1 where type=2;


--2018-03-25
alter table w_change_shift modify column entry_date date default 0;

--2018-03-28
alter table w_retailer add index type (type);

--2018-04-16
alter table w_retailer add index shop (shop);

--2018-06-05
alter table inv_types add column py varchar(64) not null after name;


--2018-06-06
alter table print_template add column solo_snumber TINYINT default 0 after second_space;
alter table print_template add column len_snumber TINYINT default 0 after solo_snumber;
alter table w_inventory_new_detail add column alarm_day TINYINT default -1 after year;
update w_inventory_good set alarm_day=-1 where merchant=31;
update w_inventory set alarm_day=-1 where merchant=31;


--2018-06-12
alter table print_template add column shift_date TINYINT default 0 after expire;

--2018-06-19
alter table suppliers add column vfirm INTEGER default -1 after id;

--2018-06-21
alter table w_sale_detail add column sex TINYINT default -1 after type;

--2018-09-07
alter table w_sale add column account INTEGER default -1 after rsn;
alter table w_change_shift add column account INTEGER default -1 after merchant;

--2018-09-11
alter table print_template add column size_date TINYINT default 0 after len_snumber;
alter table print_template add column size_color TINYINT default 0 after size_date;
alter table print_template add column firm_date TINYINT default 0 after size_color;


--2018-09-12
alter table w_retailer_level add column shop INTEGER default -1 after discount;
alter table w_retailer_level drop index uk;
alter table w_retailer_level add unique index uk(merchant, shop, level);


--2018-09-14
alter table w_promotion add column scount varchar(32) default '' after rmoney;
alter table w_promotion add column sdiscount varchar(32) default '' after scount;



--2018-09-19
alter table w_inventory add column level TINYINT default -1 after alarm_a;
alter table w_inventory add column executive INTEGER default -1 after level;
alter table w_inventory add column category INTEGER default -1 after executive;
alter table w_inventory add column fabric VARCHAR(256) default null after category;

--2018-10-02
update shops set merchant=51 where merchant=24 and id=164;
-- firm
update suppliers set merchant=51 where id in (4036, 4034);
-- size
update size_group set merchant=51 where id in (386,387);
-- brand
update brands set merchant=51 where id in (23578, 23581, 23684);
-- type
update inv_types set merchant=51 where merchant=24 and id=6801;


-- good
update w_inventory_good set merchant=51 where type=6801 and merchant=24;

-- color
update colors set merchant=51 where id in (4843, 4846, 4847, 4848, 4849, 4850);
into colors (name, type, merchant) select name, type, 51 from colors where id in(2943,2944,2946,2947,2948,2949,2953,2956,2957,2958,2960,3024,3063,4868,3026,3064,3065);

update w_inventory_good set color='4892' where merchant=51 and color='2944';
update w_inventory_amount set color=4892 where merchant=51 and color=2944;

insert into w_inventory_good(bcode, style_number, brand, firm, color, size, type, sex, season, year, \
s_group, free, org_price, tag_price, ediscount, discount, path, level, executive, category, fabric, alarm_day, contailer, alarm_a, merchant, change_date, entry_date) \
select a.bcode, a.style_number, a.brand, a.firm, a.color, a.size, a.type, a.sex, a.season, a.year,\
a.s_group, a.free, a.org_price, a.tag_price, a.ediscount, a.discount, a.path, a.level, a.executive, \
a.category, a.fabric, a.alarm_day, a.contailer, a.alarm_a, 51, a.change_date, a.entry_date from w_inventory_good a \
inner join(select style_number, brand from w_inventory_new_detail where shop=164 group by style_number, brand) b on a.style_number=b.style_number and a.brand=b.brand;


update w_inventory set merchant=51 where shop=164;
update w_inventory_amount set merchant=51 where shop=164;

update w_sale set merchant=51 where shop=164;
update w_sale_detail set merchant=51 where shop=164;
update w_sale_detail_amount set merchant=51 where shop=164;

update w_inventory_new set merchant=51 where shop=164;
update w_inventory_new_detail set merchant=51 where shop=164;
update w_inventory_new_detail_amount set merchant=51 where shop=164;

update users set merchant=51 where name in ('mst880', 'mst888');
update roles set created_by=270 where id in(162,164);
update role_to_shop set merchant=51 where merchant=24 and shop_id=164;
update roles set merchant=51 where merchant=24 and id in(164,166);
update role_to_right set merchant=51 where role_id in(164,166);


update w_retailer set merchant=51 where shop=164;



-- 2018-10-10
alter table print_template drop index merchant;
alter table print_template add column name VARCHAR(64) default '' after id;
alter table print_template add column tshop INTEGER default -1 after name;

alter table print_template add column p_virprice TINYINT default 0 after code_firm;
alter table print_template add column tag_price VARCHAR(32) default '' after firm_date;
alter table print_template add column vir_price VARCHAR(32) default '' after tag_price;

alter table print_template add column offset_size INTEGER default 40  after vir_price;

alter table print_template add column font_size TINYINT default 0 after font_price;
alter table print_template add column hpx_size TINYINT default 0 after hpx_price;


alter table print_template add unique index uk(merchant, tshop, name);



alter table w_inventory_good add column vir_price DECIMAL(10,2) default 0 after free;
alter table w_inventory add column vir_price DECIMAL(10,2) default 0 after free;


alter table print_template add column size_spec TINYINT default 0 after size;


-- 2018-10-16
-- alter table print_template add column font_vprice TINYINT default 0 after font_fabric;
alter table print_template add column offset_tagprice INTEGER default 0  after offset_size;
alter table print_template add column offset_virprice INTEGER default 40  after offset_tagprice;
alter table print_template add column p_tagprice TINYINT default 1 after p_virprice;

-- 2018-10-19 --
alter table region add column master VARCHAR(8) default '' after name;


---------------------------------------------------------------------------------
-- 2018-10-19
-- alter table batchsaler add column region INTEGER default -1 after shop;
alter table region drop column master;
alter table region add column department INTEGER default -1 after name;
---------------------------------------------------------------------------------


-- 2018-10-20
alter table w_inventory add column gift TINYINT default 0 after state;
alter table w_inventory modify column state TINYINT default 0;
alter table w_inventory_good add column state TINYINT default 0 after alarm_day;
update w_inventory set gift=1 where state=2;

-- 2018-10-26
alter table w_inventory_good add column unit TINYINT default 0 after alarm_day;
alter table w_inventory add column unit TINYINT default 0 after alarm_day;
drop table batch_sale_detail;

-- 2018-11-02
alter table print_template add column label VARCHAR(8) default '' after name;
alter table print_template add column offset_label INTEGER default 0  after offset_virprice;
alter table print_template add column font_label INTEGER default 0  after font_fabric;
alter table print_template add column hpx_label INTEGER default 0  after hpx_barcode;

-- 2018-11-06
alter table print_template add column w_barcode INTEGER default 0  after offset_label;

-- 2018-11-18
alter table w_inventory_new_detail add column vir_price DECIMAL(10, 2) default 0 after alarm_day;


-- 2018-11-20
alter table print_template add column self_brand VARCHAR(32) default '' after vir_price;
alter table print_template add column printer TINYINT default -1  after w_barcode;
alter table print_template add column dual_print TINYINT default -1  after printer;


--2018-11-30
alter table w_retailer add column intro INTEGER default -1 after name;

--2018-12-06
alter table w_charge_detail add column stock VARCHAR(64) not null default '' after wxin;

--2018-12-08
alter table w_promotion add column prule TINYINT default 0 after sdiscount;


--2018-12-23
alter table w_promotion modify column cmoney integer not null default 0;
alter table w_promotion modify column rmoney integer not null default 0;

alter table w_promotion modify column cmoney VARCHAR(32) not null default '';
alter table w_promotion modify column rmoney VARCHAR(32) not null default '';

--2018-12-26
alter table w_promotion add column member TINYINT default 0 after prule;

--2019-01-20
alter table print_template add column barcode TINYINT default 1  after offset_label;

--2019-01-25
alter table shops add column bcode_friend VARCHAR(255) default '' not null after score;
alter table shops add column bcode_pay VARCHAR(255) default '' not null after bcode_friend;


--2019-01-27
alter table w_bank_card add column type TINYINT default 0 not null after bank;


--2019-02-04
alter table merchants add column state TINYINT default 0 not null after sms_send;
alter table w_ticket_custom add column stime DATE default 0 not null after shop;
alter table w_ticket_custom add column plan integer default -1 not null after batch;


--2019-02-18
alter table print_template add column stock TINYINT default 0  after type;
alter table print_template add column solo_date TINYINT default 0  after solo_size;

--2019-03-12
alter table w_charge add column xdiscount TINYINT default 100 after ctime;


--2019-03-14
alter table batch_sale_detail add column vir_price decimal(10,2) not null default 0 after tag_price;
--update batch_sale_detail set vir_price = fprice;
update batch_sale_detail a
inner join(select style_number, brand, merchant, shop, vir_price from w_inventory) b \
on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand \
set a.vir_price=b.vir_price where a.merchant=61;


--2019-04-27
alter table batch_sale add column prop integer default -1 after type;

--2019-04-30
alter table w_charge add column ibalance integer default -1 after type;
alter table w_charge add column mbalance integer default -1 after ibalance;

alter table w_charge add column ishop integer default 0 after ibalance;
alter table w_charge add column icount tinyint default -1 after ishop;


--2019-05-10
alter table print_template add column font_type tinyint default 0 after font_label;
alter table print_template add column hpx_type tinyint default 0 after hpx_label;
alter table print_template add column offset_type tinyint default 0 after offset_label;
alter table print_template add column count_type tinyint default 0 after len_snumber;

alter table print_template add column offset_width INTEGER default 0 after offset_type;

alter table print_template add column my_price VARCHAR(32) default '' after vir_price;
alter table print_template add column offset_myprice tinyint default 0 after offset_virprice;



--2019-05-31
insert into w_retailer_bank(retailer, balance, cid, type, merchant, shop, entry_date) \
values(45666,200,218,1,12,65,'2019-05-22 16:44:16');

insert into w_retailer_bank(retailer, balance, cid, type, merchant, shop, entry_date) \
values(46085,200,218,1,12,65,'2019-05-07 10:10:13');

insert into w_retailer_bank(retailer, balance, cid, type, merchant, shop, entry_date) \
values(46131,200,218,1,12,65,'2019-05-07 14:01:14');

insert into w_retailer_bank(retailer, balance, cid, type, merchant, shop, entry_date) \
values(45563,160,218,1,12,65,'2019-05-09 15:41:36');



alter table w_card add column csn VARCHAR(32) not null default '-1' after id;

insert into w_card_sale_detail(rsn, employee, retailer, card, cid, amount, good, tag_price, merchant, shop, entry_date) select rsn, employee, retailer, card, cid, amount, cgood, tag_price, merchant, shop, entry_date from w_card_sale


--2019-06-07
alter table w_ticket_custom add column in_shop integer default -1 after state;

--2019-06-15
-- alter table w_card drop column csn;
-- alter table w_child_card drop column csn;
-- alter table w_card add column good VARCHAR(64) not null default '' after shop;


alter table w_charge_detail add column csn VARCHAR(32) not null default '-1' after rsn;
alter table w_card add column deleted TINYINT not null default 0;
alter table w_child_card add column deleted TINYINT not null default 0;



--2019-06-17
alter table w_ticket add column sale_rsn VARCHAR(32) not null default '-1' after batch;
alter table w_ticket_custom add column sale_rsn VARCHAR(32) not null default '-1' after batch;

--2019-06-18
alter table w_inventory_new_detail drop index dk;
alter table w_inventory_new_detail add index dk (merchant, shop, style_number, brand, type, firm, year);

--2019-07-02
alter table batchsaler add column code varchar(32) not null default '' after name;

--2019-07-15
alter table w_ticket_plan add column mbalance integer not null default -1 after scount;
alter table w_ticket_custom add column etime DATE not null default 0 after stime;

--2019-07-16
alter table w_ticket_plan add column ishop tinyint not null default 0 after mbalance;
-- alter table w_ticket_custom add column ishop tinyint not null default 0 after etime;


--2019-07-17
alter table w_sale add column aliPay DECIMAL(10, 2) default 0 after wxin
alter table w_daily_report add column aliPay DECIMAL(10, 2) default 0 after wxin


--2019-07-22
alter table w_change_shift add column aliPay DECIMAL(10, 2) default 0 after wxin;
alter table w_sale change column alipay aliPay DECIMAL(10, 2) default 0;
alter table w_daily_report change column alipay aliPay DECIMAL(10, 2) default 0;
alter table w_change_shift modify column account integer not null default -1;
alter table w_change_shift modify column comment varchar(137) not null default '';


--2019-09-02
alter table print_template change column offset_width offset_fabric TINYINT default 0;
alter table print_template add column offset_color TINYINT default 0 after offset_size;


alter table w_charge_detail add column alipay DECIMAL(10, 2) default 0 after wxin


--2019-08-20
alter table w_sale add column g_ticket TINYINT not null default 0 after comment;

--2019-09-15
alter table w_ticket_custom add column sale_new varchar(32) not null default '' after batch;

--2019-09-16
alter table shops add column pay_cd varchar(32) not null default '' after region;

--2019-09-17
alter table w_sale add column pay_sn integer not null default -1 after rsn;

--2019-09-21
alter table w_ticket_custom add column mtime DATE not null default 0 after mtime;


--2019-10-02
update w_ticket_custom a inner join \
(select id, stime from w_ticket_custom where merchant=4 and stime!=0 and mtime=0) b \
on a.id=b.id set a.mtime=b.stime;

alter table print_template modify column label varchar(32) default '' after name;

--2019-11-13
alter table w_ticket_custom add column ctime DATETIME not null default 0 after stime;

update w_ticket_custom a inner join \
(select rsn, entry_date from w_sale where merchant=4) b \
on a.sale_rsn = b.rsn set a.ctime=b.entry_date;

--9999-99-99
alter table merchants add column shop_count integer default -1 after sms_send;

