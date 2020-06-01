#! /bin/bash
[ $# -ne 2 ] && echo "params error: [1]->db user; [2]->db password;" && exit 1

USER=$1
PASSWORD=$2

mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_sale_detail add column exist integer not null default 0 after total;
alter table w_sale_detail add column negative tinyint not null default 0 after exist;
alter table w_sale_detail_amount add column exist integer not null default 0 after total;
EOF

for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106 107 108 109
do
    echo w_sale_detail_${t}
    echo w_sale_detail_amount_${t}
    echo "alter table w_sale_detail_amount_${t} add column exist integer not null default 0 after total"
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_sale_detail_amount_${t} add column exist integer not null default 0 after total;
alter table w_sale_detail_${t} add column exist integer not null default 0 after total;
alter table w_sale_detail_${t} add column negative tinyint not null default 0 after exist;
EOF
done
