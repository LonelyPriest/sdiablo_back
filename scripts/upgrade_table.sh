#! /bin/bash
[ $# -ne 2 ] && echo "params error: [1]->db user; [2]->db password;" && exit 1

USER=$1
PASSWORD=$2

mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_inventory_transfer_detail add column vir_price DECIMAL(10, 2) default 0 after year;
EOF

for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 71 72 73 74 79 90 98 101 103 104 105 106
do
    echo w_inventory_transfer_detail_${t}
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_inventory_transfer_detail_${t} add column vir_price DECIMAL(10, 2) default 0 after year;
EOF
done
