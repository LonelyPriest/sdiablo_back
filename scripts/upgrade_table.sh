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


mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_inventory add column draw DECIMAL(10, 2) default 0 after tag_price;
alter table w_inventory_good add column draw DECIMAL(10, 2) default 0 after tag_price;
EOF

for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109 110 111 112
do
    echo w_inventory__${t}
    echo w_inventory_good_${t}
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_inventory_${t} add column draw DECIMAL(10, 2) default 0 after tag_price;
alter table w_inventory_good_${t} add column draw DECIMAL(10, 2) default 0 after tag_price;
EOF
done
