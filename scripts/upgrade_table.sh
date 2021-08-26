#! /bin/bash
[ $# -ne 2 ] && echo "params error: [1]->db user; [2]->db password;" && exit 1

USER=$1
PASSWORD=$2

# mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_sale_detail add column exist integer not null default 0 after total;
# alter table w_sale_detail add column negative tinyint not null default 0 after exist;
# alter table w_sale_detail_amount add column exist integer not null default 0 after total;
# EOF

# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110
# do
#     echo w_sale_detail_${t}
#     echo w_sale_detail_amount_${t}
#     echo "alter table w_sale_detail_amount_${t} add column exist integer not null default 0 after total"
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_sale_detail_${t} add column exist integer not null default 0 after total;
# alter table w_sale_detail_${t} add column negative tinyint not null default 0 after exist;
# alter table w_sale_detail_amount_${t} add column exist integer not null default 0 after total;
# EOF
# done

# for t in 107 108 109 110
# do 
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_inventory_transfer_detail_${t} add column vir_price DECIMAL(10, 2) default 0 after year;
# EOF
# done


# mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_inventory add column draw DECIMAL(10, 2) default 0 after tag_price;
# alter table w_inventory_good add column draw DECIMAL(10, 2) default 0 after tag_price;
# EOF

# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110 111 112
# do
#     echo w_inventory__${t}
#     echo w_inventory_good_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_inventory_${t} add column draw DECIMAL(10, 2) default 0 after tag_price;
# alter table w_inventory_good_${t} add column draw DECIMAL(10, 2) default 0 after tag_price;
# EOF
# done

## 2020-06-30
# mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# update w_inventory set state=0 where state=-1;
# update w_inventory_good set state=0 where state=-1;
# alter table w_inventory modify column state VARCHAR(16) not null default 0;
# alter table w_inventory_good modify column state VARCHAR(16) not null default 0; 
# alter table w_inventory drop column gift;
# alter table w_sale_detail modify column reject VARCHAR(16) not null default 0;
# alter table w_sale_detail drop column negative;
# EOF

# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110 111 112 113
# do
#     echo w_inventory_${t}
#     echo w_inventory_good_${t}
#     echo w_sale_detail_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# update w_inventory_${t} set state=0 where state=-1;
# update w_inventory_good_${t} set state=0 where state=-1;
# alter table w_inventory_${t} modify column state VARCHAR(16) not null default 0;
# alter table w_inventory_good_${t} modify column state VARCHAR(16) not null default 0; 
# alter table w_inventory_${t} drop column gift;
# alter table w_sale_detail_${t} modify column reject VARCHAR(16) not null default 0;
# alter table w_sale_detail_${t} drop column negative;
# EOF
# done

## 2020-07-01
# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110 111 112 113
# do
#     echo w_inventory_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# update w_inventory_${t} set state=RPAD(state,7,'0100000') where merchant=${t};
# EOF
# done


## 2020-07-02
# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110 111 112 113
# do
#     echo w_inventory_${t}
#     echo w_sale_detail_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_inventory_${t} add column commision INTEGER not null default -1 after score;
# alter table w_sale_${t} add column oil DECIMAL(10,2) not null default 0 after total;
# alter table w_sale_detail_${t} add column commision INTEGER not null default -1;
# alter table w_sale_detail_${t} add column oil DECIMAL(10,2) default 0 after rprice;
# EOF
# done

## 2020-07-02
# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 72 73 74 90 101 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120
# do
#     echo w_sale_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_sale_${t} modify column pay_sn VARCHAR(16) not null default '-1';
# EOF
# done

## 2020-12-29
# for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 72 73 74 90 101 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125
# do
#     echo w_sale_${t}
#     mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
# alter table w_sale_${t} add column charge DECIMAL(10,2) not null default 0 after should_pay;
# EOF
# done

# 2021-08-26
for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 72 73 74 90 101 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125
do
    echo w_sale_${t}
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_inventory_fix_detail_amount_${t} add column type INTEGER not null default -1 after brand;
EOF
done




