#! /bin/bash
[ $# -ne 3 ] && echo "params error: [1]->db user; [2]->db password; [3]->merchant" && exit 1

USER=$1
PASSWORD=$2
SUFFIX=$3

TABLE_GOOD=w_inventory_good_${SUFFIX}
TABLE_GOOD_EXTRA=w_inventory_good_extra_${SUFFIX}
TABLE_STOCK_NEW=w_inventory_new_${SUFFIX}
TABLE_STOCK_NEW_DETAIL=w_inventory_new_detail_${SUFFIX}
TABLE_STOCK_NEW_DETAIL_AMOUNT=w_inventory_new_detail_amount_${SUFFIX}

TABLE_STOCK=w_inventory_${SUFFIX}
TABLE_STOCK_NOTE=w_inventory_amount_${SUFFIX}

TABLE_SALE=w_sale_${SUFFIX}
TABLE_SALE_DETAIL=w_sale_detail_${SUFFIX}
TABLE_SALE_DETAIL_AMOUNT=w_sale_detail_amount_${SUFFIX}

TABLE_STOCK_TRANSFER=w_inventory_transfer_${SUFFIX}
TABLE_STOCK_TRANSFER_DETAIL=w_inventory_transfer_detail_${SUFFIX}
TABLE_STOCK_TRANSFER_DETAIL_AMOUNT=w_inventory_transfer_detail_amount_${SUFFIX}

TABLE_STOCK_FIX=w_inventory_fix_${SUFFIX}
TABLE_STOCK_FIX_DETAIL_AMOUNT=w_inventory_fix_detail_amount_${SUFFIX}

mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
INSERT INTO ${TABLE_GOOD} (bcode,style_number,brand,firm,color,size,type,sex,season,year,s_group,
free,
vir_price,
org_price,
tag_price,
ediscount,
discount,
path,
alarm_day,
unit,
state,
contailer,
alarm_a,
comment,
merchant,
change_date,
entry_date,
deleted) \

select bcode,style_number,brand,firm,color,size,type,sex,season,year,s_group,free,
vir_price,
org_price,
tag_price,
ediscount,
discount,
path,
alarm_day,
unit,
state,
contailer,
alarm_a,
comment,
merchant,
change_date,
entry_date,
deleted FROM w_inventory_good WHERE merchant=${SUFFIX};

INSERT INTO ${TABLE_GOOD_EXTRA} (
style_number,
brand,
level,
executive,
category,
fabric,
feather,
merchant,
entry_date,
deleted) \

select style_number,
brand,
level,
executive,
category,
fabric,
feather,
merchant,
entry_date,
deleted FROM w_inventory_good_extra WHERE merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_NEW} (
rsn,
account,
employ,
firm,
shop,
merchant,
balance,
should_pay,
has_pay,
cash,
card,
wire,
verificate,
total,
comment,
e_pay_type,
e_pay,
type,
state,
check_date,
entry_date,
deleted,
op_date) \

SELECT rsn,
account,
employ,
firm,
shop,
merchant,
balance,
should_pay,
has_pay,
cash,
card,
wire,
verificate,
total,
comment,
e_pay_type,
e_pay,
type,
state,
check_date,
entry_date,
deleted,
op_date FROM w_inventory_new where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_NEW_DETAIL} (
rsn,
style_number,
brand,
type,
sex,
season,
firm,
s_group,
free,
year,
alarm_day,
vir_price,
org_price,
tag_price,
ediscount,
discount,
amount,
over,
path,
merchant,
entry_date,
deleted,
shop) \

SELECT rsn,
style_number,
brand,
type,
sex,
season,
firm,
s_group,
free,
year,
alarm_day,
vir_price,
org_price,
tag_price,
ediscount,
discount,
amount,
over,
path,
merchant,
entry_date,
deleted,
shop FROM w_inventory_new_detail where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_NEW_DETAIL_AMOUNT} (
rsn,
style_number,
brand,
color,
size,
total,
merchant,
entry_date,
deleted,
shop) \
SELECT rsn,style_number,brand,color,size,total,merchant,entry_date,deleted,shop \
FROM w_inventory_new_detail_amount where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK} (
bcode,
rsn,
style_number,
brand,
firm,
type,
sex,
season,
year,
amount,
s_group,
free,
vir_price,
promotion,
score,
org_price,
tag_price,
ediscount,
discount,
path,
alarm_day,
unit,
sell,
contailer,
alarm_a,
level,
executive,
category,
fabric,
feather,
shop,
state,
gift,
merchant,
last_sell,
change_date,
entry_date,
deleted) \

SELECT bcode,
rsn,
style_number,
brand,
firm,
type,
sex,
season,
year,
amount,
s_group,
free,
vir_price,
promotion,
score,
org_price,
tag_price,
ediscount,
discount,
path,
alarm_day,
unit,
sell,
contailer,
alarm_a,
level,
executive,
category,
fabric,
feather,
shop,
state,
gift,
merchant,
last_sell,
change_date,
entry_date,
deleted FROM w_inventory where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_NOTE} (
rsn,style_number,brand,color,size,shop,alarm_a,merchant,total,entry_date,deleted)
SELECT rsn,style_number,brand,color,size,shop,alarm_a,merchant,total,entry_date,
deleted FROM w_inventory_amount where merchant=${SUFFIX};

INSERT INTO ${TABLE_SALE} (
rsn,
pay_sn,
account,
employ,
retailer,
shop,
merchant,
tbatch,
tcustom,
balance,
base_pay,
should_pay,
cash,
card,
withdraw,
verificate,
total,
lscore,
score,
comment,
g_ticket,
type,
state,
check_date,
entry_date,
deleted,
ticket,
wxin,
aliPay) \

SELECT rsn,
pay_sn,
account,
employ,
retailer,
shop,
merchant,
tbatch,
tcustom,
balance,
base_pay,
should_pay,
cash,
card,
withdraw,
verificate,
total,
lscore,
score,
comment,
g_ticket,
type,
state,
check_date,
entry_date,
deleted,
ticket,
wxin,
aliPay FROM w_sale where merchant=${SUFFIX};

INSERT INTO ${TABLE_SALE_DETAIL} (
rsn,
style_number,
brand,
merchant,
type,
sex,
s_group,
free,
season,
firm,
year,
total,
promotion,
score,
org_price,
tag_price,
discount,
fdiscount,
rdiscount,
fprice,
rprice,
path,
comment,
entry_date,
deleted,
ediscount,
shop,
in_datetime,
reject) \

SELECT rsn,
style_number,
brand,
merchant,
type,
sex,
s_group,
free,
season,
firm,
year,
total,
promotion,
score,
org_price,
tag_price,
discount,
fdiscount,
rdiscount,
fprice,
rprice,
path,
comment,
entry_date,
deleted,
ediscount,
shop,
in_datetime,
reject FROM w_sale_detail where merchant=${SUFFIX};

INSERT INTO ${TABLE_SALE_DETAIL_AMOUNT} (
rsn, style_number, brand, color, size, total, entry_date, merchant, deleted, shop) \
SELECT rsn, style_number, brand, color, size, total, entry_date, merchant, deleted, shop \
FROM w_sale_detail_amount where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_TRANSFER} (
rsn,
fshop,
tshop,
employ,
total,
cost,
comment,
merchant,
state,
check_date,
entry_date,
deleted) \

SELECT rsn,
fshop,
tshop,
employ,
total,
cost,
comment,
merchant,
state,
check_date,
entry_date,
deleted FROM w_inventory_transfer where merchant=${SUFFIX};


INSERT INTO ${TABLE_STOCK_TRANSFER_DETAIL} (
rsn,
bcode,
style_number,
brand,
type,
sex,
season,
firm,
s_group,
free,
year,
org_price,
tag_price,
discount,
ediscount,
amount,
path,
merchant,
fshop,
tshop,
entry_date,
deleted) \

SELECT rsn,
bcode,
style_number,
brand,
type,
sex,
season,
firm,
s_group,
free,
year,
org_price,
tag_price,
discount,
ediscount,
amount,
path,
merchant,
fshop,
tshop,
entry_date,
deleted FROM w_inventory_transfer_detail where merchant=${SUFFIX};


INSERT INTO ${TABLE_STOCK_TRANSFER_DETAIL_AMOUNT} (
rsn,
style_number,
brand,
color,
size,
total,
merchant,
fshop,
tshop,
entry_date,
deleted) \

SELECT rsn,
style_number,
brand,
color,
size,
total,
merchant,
fshop,
tshop,
entry_date,
deleted FROm w_inventory_transfer_detail_amount where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_FIX} (
rsn,
merchant,
shop,
firm,
employ,
shop_total,
db_total,
entry_date,
deleted) \

SELECT rsn,
merchant,
shop,
firm,
employ,
shop_total,
db_total,
entry_date,
deleted FROM w_inventory_fix where merchant=${SUFFIX};

INSERT INTO ${TABLE_STOCK_FIX_DETAIL_AMOUNT} (
rsn,
merchant,
shop,
style_number,
brand,
color,
size,
shop_total,
db_total,
entry_date,
deleted) \

SELECT rsn,
merchant,
shop,
style_number,
brand,
color,
size,
shop_total,
db_total,
entry_date,
deleted FROM w_inventory_fix_detail_amount where merchant=${SUFFIX};

EOF

