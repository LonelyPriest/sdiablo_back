#! /bin/bash
[ $# -ne 2 ] && echo "params error: [1]->db user; [2]->db password;" && exit 1

USER=$1
PASSWORD=$2

mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_sale_detail add column account INTEGER default -1 after rsn;
EOF

for t in 103 104 105 72
do
    echo w_sale_detail_${t}
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
alter table w_sale_detail_${t} add column account INTEGER default -1 after rsn;
EOF
done
