#! /bin/bash
[ $# -ne 2 ] && echo "params error: [1]->db user; [2]->db password;" && exit 1

USER=$1
PASSWORD=$2

TABLE_WSALE_ORDER=w_sale_order_${SUFFIX}
TABLE_WSALE_ORDER_DETAILI=w_sale_order_detail_${SUFFIX}
TABLE_WSALE_ORDER_NOTE=w_sale_order_note_${SUFFIX}

for t in 2 4 7 9 15 16 19 26 35 41 42 68 70 72 73 74 90 101 103 104 105 106 107 108 109 110 111 112 113 114 115 116 117 118 119 120 121 122 123 124 125
do
    echo w_sale_order_${t}
    echo w_sale_order_detail_${t}
    echo w_sale_order_note_${t}
    mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
CREATE TABLE w_sale_order_${t} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  account int(11) NOT NULL DEFAULT '-1',
  employ varchar(8) NOT NULL,
  retailer int(11) NOT NULL DEFAULT '-1',
  shop int(11) NOT NULL DEFAULT '-1',
  merchant int(11) NOT NULL DEFAULT '-1',
  abs_pay decimal(10,2) NOT NULL DEFAULT '0.00',
  should_pay decimal(10,2) DEFAULT '0.00',
  total int(11) NOT NULL DEFAULT '0',
  finish int(11) NOT NULL DEFAULT '0',
  comment varchar(255) DEFAULT NULL,
  state tinyint(4) NOT NULL DEFAULT '0',
  op_date datetime DEFAULT '0000-00-00 00:00:00',
  entry_date datetime DEFAULT '0000-00-00 00:00:00',
  deleted int(11) DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn),
  KEY dk (merchant,shop,employ,retailer)
) DEFAULT CHARSET=utf8;

CREATE TABLE w_sale_order_detail_${t} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  merchant int(11) NOT NULL DEFAULT '-1',
  shop int(11) NOT NULL DEFAULT '-1',
  retailer int(11) NOT NULL DEFAULT '-1',
  style_number varchar(64) NOT NULL,
  brand int(11) NOT NULL DEFAULT '-1',
  type int(11) DEFAULT '-1',
  sex tinyint(4) DEFAULT '-1',
  s_group varchar(32) DEFAULT '0',
  free tinyint(4) DEFAULT '0',
  season tinyint(4) DEFAULT '-1',
  firm int(11) DEFAULT '-1',
  year year(4) DEFAULT NULL,
  in_datetime datetime DEFAULT '0000-00-00 00:00:00',
  total int(11) DEFAULT '0',
  finish int(11) NOT NULL DEFAULT '0',
  org_price decimal(10,2) DEFAULT '0.00',
  tag_price decimal(10,2) DEFAULT '0.00',
  discount decimal(4,1) DEFAULT NULL,
  fdiscount decimal(4,1) DEFAULT NULL,
  fprice decimal(10,2) DEFAULT '0.00',
  path varchar(255) DEFAULT NULL,
  comment varchar(127) DEFAULT NULL,
  state tinyint(4) NOT NULL DEFAULT '0',
  op_date datetime DEFAULT '0000-00-00 00:00:00',
  entry_date datetime DEFAULT '0000-00-00 00:00:00',
  deleted int(11) DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand),
  KEY dk (merchant,shop,retailer,style_number,brand)
) DEFAULT CHARSET=utf8;

CREATE TABLE w_sale_order_note_${t} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  merchant int(11) DEFAULT '-1',
  shop int(11) DEFAULT '-1',
  style_number varchar(64) NOT NULL,
  brand int(11) DEFAULT '-1',
  color int(11) DEFAULT '-1',
  size varchar(8) DEFAULT NULL,
  total int(11) DEFAULT '0',
  finish int(11) NOT NULL DEFAULT '0',
  state tinyint(4) NOT NULL DEFAULT '0',
  op_date datetime DEFAULT '0000-00-00 00:00:00',
  entry_date datetime DEFAULT '0000-00-00 00:00:00',
  deleted int(11) DEFAULT '0',
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand,color,size),
  KEY dk (merchant,shop)
) DEFAULT CHARSET=utf8;

EOF
done
