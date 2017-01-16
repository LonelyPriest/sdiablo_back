
-- check stock org_price,  inventory and inventory_new_detail
select a.style_number, a.brand, a.amount, a.org_price, a.nprice, a.nprice*a.amount from (select a.style_number, a.brand, a.amount, a.org_price, b.org_price as nprice from (select style_number, brand, amount, org_price from w_inventory where merchant=3 and org_price=0) a, (select style_number, brand, org_price from w_inventory_new_detail where merchant=3) b where a.style_number=b.style_number and a.brand=b.brand and a.org_price != b.org_price) a;

select a.style_number, a.brand, a.amount, a.org_price, b.org_price as nprice from (select style_number, brand, amount, org_price from w_inventory where merchant=3 and org_price=0) a, (select style_number, brand, org_price from w_inventory_new_detail where merchant=3) b where a.style_number=b.style_number and a.brand=b.brand and a.org_price!=b.org_price;



-- check stock
select sum(x.intotal), sum(x.amount), sum(x.stotal) from (select a.style_number, a.brand, a.intotal, b.amount, c.stotal from (select style_number, brand, sum(amount) as intotal from w_inventory_new_detail where rsn like 'm-4-s-19-%' group by style_number, brand) a left join (select style_number, brand, amount from w_inventory where shop=18) b on a.style_number=b.style_number and a.brand=b.brand left join (select style_number, brand, sum(total) as stotal from w_sale_detail where rsn like 'm-4-s-19-%' group by style_number, brand) c on a.style_number=c.style_number and a.brand=c.brand) x;

-- all stock
select sum(x.intotal), sum(x.amount), sum(x.stotal), sum(x.ftotal), sum(x.ttotal) from \
(select a.style_number, a.brand, b.intotal, a.amount, c.stotal, d.ftotal, e.ttotal from \
(select style_number, brand, amount from w_inventory where shop=9) a \
left join (select style_number, brand, sum(amount) as intotal from w_inventory_new_detail where rsn like 'm-2-s-9-%' group by style_number, brand) b on a.style_number=b.style_number and a.brand=b.brand \
left join (select style_number, brand, sum(total) as stotal from w_sale_detail where rsn like 'm-2-s-9-%' group by style_number, brand) c on a.style_number=c.style_number and a.brand=c.brand \
left join (select a.style_number, brand, sum(a.amount) as ftotal from w_inventory_transfer_detail a, w_inventory_transfer b where a.fshop=9 and a.rsn=b.rsn and b.state=1 group by style_number, brand) d \
on a.style_number=d.style_number and a.brand=d.brand \
left join (select a.style_number, brand, sum(a.amount) as ttotal from w_inventory_transfer_detail a, w_inventory_transfer b where a.tshop=9 and a.rsn=b.rsn and b.state=1 group by style_number, brand) e \
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
select a.rsn, a.total, b.amount from (select rsn, total from w_inventory_transfer where fshop=9) a \
left join (select a.rsn, a.amount from (select rsn, sum(amount) as amount from w_inventory_transfer_detail where fshop=9 group by rsn) a) b on a.rsn=b.rsn where a.total!=b.amount;

/*
* check stock in
*/
select x.rsn, x.total, x.amount from (select a.rsn, b.style_number, b.brand, a.total, b.amount from w_inventory_new a left join (select rsn, style_number, brand, sum(amount) as amount from w_inventory_new_detail where rsn like 'm-2-s-8-%' group by rsn) b on a.rsn=b.rsn where a.rsn like 'm-2-s-8-%') x where x.total!=x.amount;

select a.rsn, a.style_number, a.brand, a.total, b.amount from (select rsn, style_number, brand, sum(total) as total from w_inventory_new_detail_amount where rsn like 'm-4-s-16-%' group by rsn) a left join (select rsn,style_number, brand, sum(amount) as amount from w_inventory_new_detail where rsn like 'm-4-s-16%' group by rsn) b on a.rsn=b.rsn where a.total!=b.amount;

-- syn shop of w_inventory_new_detail
update w_inventory_new_detail s inner join (select id, substring_index(a.s1, "-", -1) as shop from (select id, substring_index(rsn, "-", 4) as s1 from w_inventory_new_detail where shop=-1) a) ss on s.id=ss.id set s.shop=ss.shop;

-- syn shop of w_inventory_new_detail_amount
update w_inventory_new_detail_amount s inner join (select id, substring_index(a.s1, "-", -1) as shop from (select id, substring_index(rsn, "-", 4) as s1 from w_inventory_new_detail_amount where shop=-1) a) ss on s.id=ss.id set s.shop=ss.shop;


-- syn merchant
update w_inventory_new_detail s inner join (select id, substring_index(a.s1, "-", -1) as merchant from (select id, substring_index(rsn, "-", 2) as s1 from w_inventory_new_detail where merchant=-1) a) ss on s.id=ss.id set s.merchant=ss.merchant;

update w_inventory_new_detail_amount s inner join (select id, substring_index(a.s1, "-", -1) as merchant from (select id, substring_index(rsn, "-", 2) as s1 from w_inventory_new_detail_amount where merchant=-1) a) ss on s.id=ss.id set s.merchant=ss.merchant;

-- syn in_datetime of w_sale_detail
update w_sale_detail a inner join(select style_number, brand, merchant, shop, entry_date from w_inventory) b on a.merchant=b.merchant and a.shop=b.shop and a.style_number=b.style_number and a.brand=b.brand set a.in_datetime=b.entry_date where a.rsn like '%-R-%';


-- check stock
select a.style_number, a.brand, a.amount, b.total from w_inventory a left join (select style_number, brand, sum(total) as total from w_inventory_amount a where a.merchant=4 and shop=19 group by a.style_number, a.brand) b on a.style_number=b.style_number and a.brand=b.brand where a.merchant=4 and a.shop=19 and a.amount!=b.total;

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
