
-- check stock org_price,  inventory and inventory_new_detail
select a.style_number, a.brand, a.amount, a.org_price, a.nprice, a.nprice*a.amount from (select a.style_number, a.brand, a.amount, a.org_price, b.org_price as nprice from (select style_number, brand, amount, org_price from w_inventory where merchant=3 and org_price=0) a, (select style_number, brand, org_price from w_inventory_new_detail where merchant=3) b where a.style_number=b.style_number and a.brand=b.brand and a.org_price != b.org_price) a;

select a.style_number, a.brand, a.amount, a.org_price, b.org_price as nprice from (select style_number, brand, amount, org_price from w_inventory where merchant=3 and org_price=0) a, (select style_number, brand, org_price from w_inventory_new_detail where merchant=3) b where a.style_number=b.style_number and a.brand=b.brand and a.org_price!=b.org_price;



-- check stock
select sum(x.intotal), sum(x.amount), sum(x.stotal) from (select a.style_number, a.brand, a.intotal, b.amount, c.stotal from (select style_number, brand, sum(amount) as intotal from w_inventory_new_detail where rsn like 'm-40-s-139-%' group by style_number, brand) a left join (select style_number, brand, amount from w_inventory where shop=139) b on a.style_number=b.style_number and a.brand=b.brand left join (select style_number, brand, sum(total) as stotal from w_sale_detail where rsn like 'm-40-s-139-%' group by style_number, brand) c on a.style_number=c.style_number and a.brand=c.brand) x;

-- all stock
select sum(x.intotal), sum(x.amount), sum(x.stotal), sum(x.ftotal), sum(x.ttotal) from \
(select a.style_number, a.brand, b.intotal, a.amount, c.stotal, d.ftotal, e.ttotal from \
(select style_number, brand, amount from w_inventory where shop=110) a \
left join (select style_number, brand, sum(amount) as intotal from w_inventory_new_detail where rsn like 'm-15-s-110-%' group by style_number, brand) b on a.style_number=b.style_number and a.brand=b.brand \
left join (select style_number, brand, sum(total) as stotal from w_sale_detail where rsn like 'm-15-s-110-%' group by style_number, brand) c on a.style_number=c.style_number and a.brand=c.brand \
left join (select a.style_number, brand, sum(a.amount) as ftotal from w_inventory_transfer_detail a, w_inventory_transfer b where a.fshop=110 and a.rsn=b.rsn and b.state=1 group by style_number, brand) d \
on a.style_number=d.style_number and a.brand=d.brand \
left join (select a.style_number, brand, sum(a.amount) as ttotal from w_inventory_transfer_detail a, w_inventory_transfer b where a.tshop=110 and a.rsn=b.rsn and b.state=1 group by style_number, brand) e \
on a.style_number=e.style_number and a.brand=e.brand) x;


-- w_inventory to transfer
select sum(x.amount), sum(x.ftotal) from (select a.style_number, a.brand, a.amount, b.ftotal from w_inventory a left join \
(select a.style_number, a.brand, sum(a.amount) as ftotal from  w_inventory_transfer_detail a, w_inventory_transfer b where a.fshop=16 and a.rsn=b.rsn and b.state=1 group by a.style_number, a.brand) b \
on a.style_number=b.style_number and a.brand=b.brand where a.shop=17) x;

-- transfer to w_inventory
select sum(x.ftotal), sum(x.amount) from
(select a.style_number, a.brand, a.ftotal, b.amount as amount from \
(select a.style_number, a.brand, sum(a.amount) as ftotal from w_inventory_transfer_detail a, w_inventory_transfer b where a.fshop=17 and a.rsn=b.rsn and b.state=1 group by a.style_number, a.brand) a \
left join w_inventory b on a.style_number=b.style_number and a.brand=b.brand and b.shop=17) x;

-- check transfer
select a.rsn, a.total, b.amount from (select rsn, total from w_inventory_transfer where fshop=93) a \
left join (select a.rsn, a.amount from (select rsn, sum(amount) as amount from w_inventory_transfer_detail where fshop=93 group by rsn) a) b on a.rsn=b.rsn where a.total!=b.amount;

/*
* check stock in
*/
select x.rsn, x.total, x.amount from \
(select a.rsn, b.style_number, b.brand, a.total, b.amount from w_inventory_new a left join \
(select rsn, style_number, brand, sum(amount) as amount from w_inventory_new_detail where rsn like 'm-23-s-93-%' group by rsn) b on \
a.rsn=b.rsn where a.rsn like 'm-23-s-93-%') x where x.total!=x.amount;

select a.rsn, a.style_number, a.brand, a.total, b.amount from \
(select rsn, style_number, brand, sum(total) as total from w_inventory_new_detail_amount where rsn like 'm-23-s-93-%' group by rsn) a left join \
(select rsn,style_number, brand, sum(amount) as amount from w_inventory_new_detail where rsn like 'm-23-s-93-%' group by rsn) b \
on a.rsn=b.rsn where a.total!=b.amount;

-- syn shop of w_inventory_new_detail
update w_inventory_new_detail s inner join (select id, substring_index(a.s1, "-", -1) as shop from (select id, substring_index(rsn, "-", 4) as s1 from w_inventory_new_detail where shop=-1) a) ss on s.id=ss.id set s.shop=ss.shop;

-- syn shop of w_inventory_new_detail_amount
update w_inventory_new_detail_amount s inner join (select id, substring_index(a.s1, "-", -1) as shop from (select id, substring_index(rsn, "-", 4) as s1 from w_inventory_new_detail_amount where shop=-1) a) ss on s.id=ss.id set s.shop=ss.shop;


-- syn merchant
update w_inventory_new_detail s inner join (select id, substring_index(a.s1, "-", -1) as merchant from (select id, substring_index(rsn, "-", 2) as s1 from w_inventory_new_detail where merchant=-1) a) ss on s.id=ss.id set s.merchant=ss.merchant;

update w_inventory_new_detail_amount s inner join (select id, substring_index(a.s1, "-", -1) as merchant from (select id, substring_index(rsn, "-", 2) as s1 from w_inventory_new_detail_amount where merchant=-1) a) ss on s.id=ss.id set s.merchant=ss.merchant;

-- syn in_datetime of w_sale_detail
update w_sale_detail a inner join(select style_number, brand, merchant, shop, entry_date from w_inventory) b on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand set a.in_datetime=b.entry_date where a.rsn like '%-R-%';

-- syn sex of w_sale_detail
update w_sale_detail a inner join(select style_number, brand, merchant, shop, sex from w_inventory) b on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand set a.sex=b.sex;

-- syn org_price of w_sale_detail
update w_sale_detail a inner join(select style_number, brand, merchant, shop, org_price, ediscount from w_inventory where merchant=87) b \
on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand \
set a.org_price=b.org_price, a.ediscount=b.ediscount;


-- check stock
select a.style_number, a.brand, a.amount, b.total from w_inventory a left join \
(select style_number, brand, sum(total) as total from w_inventory_amount a where a.merchant=35 and shop=129 group by a.style_number, a.brand) b \
on a.style_number=b.style_number and a.brand=b.brand where a.merchant=15 and a.shop=58 and a.amount!=b.total;

select a.style_number, a.brand, a.total , b.amount from (select style_number, brand, sum(total) as total from w_inventory_amount where merchant=15 and shop=53 group by style_number, brand) a \
left join (select style_number, brand, amount from w_inventory where merchant=15 and shop=53) b \
on a.style_number=b.style_number and a.brand=b.brand;

select a.merchant, a.shop, a.style_number, a.brand, a.amount, b.total from w_inventory a \
left join (select merchant, shop, style_number, brand, sum(total) as total from w_inventory_amount a group by merchant, shop, a.style_number, a.brand) b \
on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand where a.amount!=b.total;

select a.style_number, a.brand, a.amount, a.style_number_b, a.brand_b from \
(select a.style_number, a.brand, a.amount, b.style_number as style_number_b, b.brand as brand_b from \
(select style_number, brand,  sum(total) as amount from w_inventory_amount where merchant=16 and shop=62 group by style_number, brand) a left join \
(select style_number, brand from w_inventory where merchant=16 and shop=62) b on a.style_number=b.style_number and a.brand=b.brand) a where ba is null;

select a.merchant, a.amount, b.total from \
(select merchant, sum(amount) as amount from w_inventory group by merchant) a \
left join (select merchant, sum(total) as total from w_inventory_amount group by merchant) b on a.merchant=b.merchant;

-- check w_sale
select a.rsn, a.total from (select rsn, sum(total) as total from w_sale_detail where shop=56 group by rsn) a, w_sale b where a.rsn=b.rsn and a.total!=b.total;

-- export special record from special table
mysqldump -uroot -pbxh --where="rsn='M-2-S-12-695'" sdiablo w_inventory_new > w_inventory_new.sql;

-- export as csv
SELECT * INTO OUTFILE 'retailer_1.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '"' ESCAPED BY '\\' LINES TERMINATED BY '\n' FROM w_retailer where merchant=8;



select * from (select a.rsn, a.total, b.rsn as brsn, b.amount from w_inventory_new a left join (select rsn, sum(amount) as amount from w_inventory_new_detail where shop=2 group by rsn) b on a.rsn=b.rsn where a.rsn like 'm-2-s-2%' and a.type!=9) x where brsn is null;


-- update w_inventory_new_detail set shop=(select substring(rsn, instr(rsn, 'S')+2, 1));

select x.rsn, x.amount, x.brsn, x.total from (select a.rsn, a.amount, b.rsn as brsn, b.total from (select rsn, sum(amount) as amount from w_inventory_new_detail where merchant=2 group by rsn) a left join (select rsn, sum(total) as total from w_inventory_new_detail_amount where merchant=2 group by rsn) b on a.rsn=b.rsn) x where x.amount != x.total;


-- syn w_inventory and w_inventory_amount
update w_inventory a inner join (select a.style_number, a.brand, a.amount, b.total from w_inventory a left join (select style_number, brand, sum(total) as total from w_inventory_amount a where a.merchant=4 and shop=20 group by a.style_number, a.brand) b on a.style_number=b.style_number and a.brand=b.brand where a.merchant=4 and a.shop=20 and a.amount!=b.total) x set a.amount=x.total, a.sell=a.sell-1 where a.style_number=x.style_number and a.brand=x.brand and a.shop=20;


-- check w_sale_detail and w_inventory
select a.style_number, a.brand, a.stotal, b.sell from (select style_number, brand, sum(total) as stotal from w_sale_detail where rsn like 'm-4-s-20-%' group by style_number, brand) a left join w_inventory b on a.style_number=b.style_number and a.brand=b.brand and b.shop=20;


-- delete wsale
update w_inventory_amount a inner join(\
select style_number, brand, color, size, total from w_sale_detail_amount where rsn='M-4-S-18-R-1858') b \
on a.style_number=b.style_number and a.brand=b.brand and a.size=b.size and a.color=b.color set a.total=a.total+b.total \
where a.merchant=4 and a.shop=18;


update w_inventory a inner join(\
select style_number, brand, total from w_sale_detail where rsn='M-4-S-18-R-1858') b \
on a.style_number=b.style_number and a.brand=b.brand set a.amount=a.amount+b.total \
where a.merchant=4 and a.shop=18;

delete from w_sale_detail_amount where rsn='M-4-S-18-R-1858';
delete from w_sale_detail where rsn='M-4-S-18-R-1858';
delete from w_sale where rsn='M-4-S-18-R-1858';


-- syn w_sale_detail where org_price=0
update w_sale_detail a inner join(select style_number, brand, merchant, shop, org_price, ediscount from w_inventory where merchant=4) b \
on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand \
set a.org_price=b.org_price, a.ediscount=b.ediscount where a.org_price=0;

update w_inventory a inner join(select style_number, brand, merchant, org_price, ediscount from w_inventory_good where merchant=4) b \
on a.merchant=b.merchant and a.style_number=b.style_number and a.brand=b.brand \
set a.org_price=b.org_price, a.ediscount=b.ediscount where a.org_price=0;

update w_inventory_transfer_detail t inner join \
(select style_number, brand, org_price, tag_price, discount, ediscount, merchant from w_inventory where merchant=4 group by style_number, brand) w \
on t.merchant=w.merchant and t.style_number=w.style_number and t.brand=w.brand
set t.org_price=w.org_price, t.tag_price=w.tag_price, t.discount=w.discount, t.ediscount=w.ediscount \
where t.merchant=4;


-- w_inventory_new_detail to w_inventory
update w_inventory a inner join(select style_number, brand, merchant, shop, amount from w_inventory_new_detail where rsn='M-4-S-19-5002') b \
on a.style_number=b.style_number and a.brand=b.brand and a.merchant=b.merchant and a.shop=b.shop \
set a.amount=a.amount+b.amount where a.merchant=4 and a.shop=19;

update w_inventory_amount a inner join(select style_number, brand, color, size, merchant, shop, total from w_inventory_new_detail_amount where rsn='M-4-S-19-5002') b \
on a.style_number=b.style_number and a.brand=b.brand and a.color=b.color and a.size=b.size and a.merchant=b.merchant and a.shop=b.shop \
set a.total=a.total+b.total where a.merchant=4 and a.shop=19;


delete from w_inventory_good where (style_number, brand) in \
(select a.style_number, a.brand from (select style_number, brand from w_inventory_good where merchant=12) a \
where (a.style_number, a.brand) not in \
(select style_number, brand from w_inventory where merchant=12 group by style_number, brand)) and merchant=12;


-- check firm between w_inventory_new and w_inventory_new_detail
select a.rsn, a.firm, c.name, b.rsn, b.firm, b.fname from w_inventory_new a left join \
(select a.rsn, a.firm, b.name as fname from w_inventory_new_detail a \
left join suppliers b on a.firm=b.id where a.merchant=2 group by rsn) b on a.rsn=b.rsn \
left join suppliers c on a.firm=c.id where a.merchant=2 and a.firm!=b.firm;


update  w_inventory_transfer a inner join (select rsn, cost from (select rsn, sum(org_price * amount) as cost from w_inventory_transfer_detail group by rsn) a) b on a.rsn=b.rsn set a.cost=b.cost;


-- syn tagprice
update w_inventory a inner join (select style_number, brand, shop, tag_price, discount, ediscount from w_inventory_new_detail where merchant=42 group by style_number, brand, shop) b on \
a.style_number=b.style_number and a.brand=b.brand and a.shop=b.shop set a.tag_price=b.tag_price, a.discount=b.discount, a.ediscount=b.ediscount where a.merchant=42;

update w_inventory a inner join (select style_number, brand, state from w_inventory_good where merchant=42) b on \
a.style_number=b.style_number and a.brand=b.brand and a.shop=b.shop set a.state=b.state where a.merchant=42;

mysqldump -uroot -pbxh --where="merchant='10'" sdiablo w_inventory > w_inventory_10.sql;
update w_inventory a inner join (select style_number, brand, shop, merchant, tag_price, discount, ediscount, state, score from w_inventory_69 where merchant=69) b on \
a.style_number=b.style_number and a.brand=b.brand and a.shop=b.shop and a.merchant=b.merchant \
set a.tag_price=b.tag_price, a.discount=b.discount, a.ediscount=b.ediscount, a.state=b.state, a.score=b.score where a.merchant=69;
%s/w_inventory/w_inventory_back/g

-- syn level, category, executive, fabric
update w_inventory a inner join (select style_number, brand, merchant, level, category, executive, fabric from w_inventory_good where merchant=101) b \
on a.style_number=b.style_number and a.brand=b.brand and a.merchant=b.merchant set a.level=b.level, a.category=b.category, a.executive=b.executive, a.fabric=b.fabric
where a.merchant=101 and a.style_number='nph9831'

-- check sale
select a.merchant, a.rsn, a.total, b.rsn, c.name from w_sale a left join w_sale_detail b on a.rsn=b.rsn left join merchants c on a.merchant=c.id where b.rsn is null and a.total!=0;
select a.entry_date, a.rsn, a.total, b.rsn, b.total from w_sale a left join (select rsn, sum(total) as total from w_sale_detail group by rsn) b on a.rsn=b.rsn where a.total != b.total;

-- check firm
select * from \
(select a.id, a.name, a.balance, b.balance+b.should_pay-b.has_pay-b.verificate as acc, b.date from suppliers a left join \
(select firm, balance, should_pay, has_pay, verificate, max(entry_date) as date from w_inventory_new where merchant=4 group by firm order by entry_date) b \
on a.id=b.firm where a.merchant=4) a where a.balance!=a.acc;


-- check retailer balance
select a.id, a.type, a.retailer, a.merchant, a.balance, b.balance from w_retailer_bank a left join w_retailer b on a.retailer=b.id where a.balance!=b.balance;

-- change card csn
update w_card w inner join(\
select a.id, insert(a.csn1, 3, 2, '') as csn2 from (select id, insert(csn, 1,2, '') as csn1 from w_card where csn!='-1') a\
) b on w.id=b.id set w.csn=b.csn2;

update w_child_card w inner join(\
select a.id, insert(a.csn1, 3, 2, '') as csn2 from (select id, insert(csn, 1,2, '') as csn1 from w_child_card where csn!='-1') a\
) b on w.id=b.id set w.csn=b.csn2;

-- clear date
-- delete from w_inventory_good where merchant=93;

delete from w_inventory_new_detail_amount where merchant=1;
delete from w_inventory_new_detail where merchant=1;
delete from w_inventory_new where merchant=1;

-- clear stock
delete from w_inventory_amount where merchant=1;
delete from w_inventory where merchant=1;

-- clear sale
delete from w_sale_detail_amount where merchant=1;
delete from w_sale_detail where merchant=1;
delete from w_sale where merchant=1;

-- clear batch sale
delete from batch_sale where merchant=1;
delete from batch_sale_detail where merchant=1;
delete from batch_sale_detail_amount where merchant=1;
delete from batchsaler where merchant=34 and type!=1;

-- clear transefer
delete from w_inventory_transfer_detail_amount where merchant=1;
delete from w_inventory_transfer_detail where merchant=1;
delete from w_inventory_transfer where merchant=1;


-- report
delete from w_daily_report where merchant=1;
delete from w_change_shift where merchant=1;

-- charge
delete from w_charge_detail where merchant=1;


-- brands
delete from brands where merchant=1;
delete from inv_types where merchant=1;

-- types
delete from inv_types where merchant=1;

-- bill
delete from w_bill_detail where merchant=1

