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
alter table w_inventory_amount add column alarm_a INTEGER default -1 after contailer;
