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

## mysqldump -uroot -pbxh sdiablo -d w_inventory_good > w_inventory_good.sql;
mysql -u${USER} -p${PASSWORD} sdiablo <<EOF
CREATE TABLE ${TABLE_GOOD} (
  id int(11) NOT NULL AUTO_INCREMENT,
  bcode varchar(32) DEFAULT '0',
  style_number varchar(64) NOT NULL,
  brand int(11) DEFAULT -1,
  firm int(11) DEFAULT -1,
  color varchar(255) DEFAULT '',
  size varchar(255) DEFAULT '0',
  type int(11) DEFAULT -1,
  sex tinyint(4) DEFAULT -1,
  season tinyint(4) DEFAULT -1,
  year year(4) NOT NULL DEFAULT 0,
  s_group varchar(32) DEFAULT 0,
  free tinyint(4) DEFAULT 0,
  vir_price decimal(10,2) DEFAULT 0,
  org_price decimal(10,2) DEFAULT 0,
  tag_price decimal(10,2) DEFAULT 0,
  ediscount decimal(4,1) DEFAULT  0,
  discount decimal(4,1) DEFAULT 0,
  path varchar(255) DEFAULT NULL, 
  alarm_day tinyint(4) DEFAULT -1,
  unit tinyint(4) DEFAULT 0,
  state tinyint(4) DEFAULT 0,
  contailer int(11) DEFAULT -1,
  alarm_a int(11) DEFAULT -1,
  comment VARCHAR(128) default '',
  merchant int(11) DEFAULT -1,
  change_date datetime DEFAULT 0,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (merchant,style_number,brand),
  KEY firm (firm),
  KEY bcode (bcode)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_GOOD_EXTRA} (
  id int(11) NOT NULL AUTO_INCREMENT,
  style_number     VARCHAR(64) NOT NULL DEFAULT '',
  brand            INTEGER DEFAULT -1,
        
  level            TINYINT DEFAULT -1,
  executive        INTEGER DEFAULT -1,
  category         INTEGER DEFAULT -1,
  fabric           VARCHAR(256) DEFAULT '',
  feather          VARCHAR(256) DEFAULT '',

  merchant         INTEGER default -1,    
  entry_date       DATETIME default 0,
  deleted          INTEGER default 0, -- 0: no;  1: yes

  unique key       uk (merchant, style_number, brand),    
  primary key      (id)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_NEW} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  account int(11) DEFAULT -1,
  employ varchar(8) NOT NULL default '',
  firm int(11) DEFAULT -1,
  shop int(11) DEFAULT -1,
  merchant int(11) DEFAULT -1,
  balance decimal(10,2) DEFAULT 0,
  should_pay decimal(10,2) DEFAULT 0,
  has_pay decimal(10,2) DEFAULT 0,
  cash decimal(10,2) DEFAULT 0,
  card decimal(10,2) DEFAULT 0,
  wire decimal(10,2) DEFAULT 0,
  verificate decimal(10,2) DEFAULT 0,
  total int(11) DEFAULT 0,
  comment varchar(255) not null DEFAULT '',
  e_pay_type tinyint(4) DEFAULT -1,
  e_pay decimal(10,2) DEFAULT 0,
  type tinyint(4) DEFAULT -1,
  state tinyint(4) DEFAULT 0,
  check_date datetime DEFAULT 0,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  op_date datetime DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn),
  KEY dk (merchant, shop, firm, employ)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_NEW_DETAIL} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  style_number varchar(64) NOT NULL,
  brand int(11) DEFAULT -1,
  type int(11) DEFAULT -1,
  sex tinyint(4) DEFAULT -1,
  season tinyint(4) DEFAULT -1,
  firm int(11) DEFAULT -1,
  s_group varchar(32) DEFAULT '0',
  free tinyint(4) DEFAULT 0,
  year year(4) DEFAULT 0,
  alarm_day tinyint(4) DEFAULT -1,
  vir_price decimal(10,2) DEFAULT 0,
  org_price decimal(10,2) DEFAULT 0,
  tag_price decimal(10,2) DEFAULT 0,
  ediscount decimal(4,1) DEFAULT 0,
  discount decimal(4,1) DEFAULT 0,
  amount int(11) DEFAULT 0,
  over int(11) DEFAULT 0,
  path varchar(255) DEFAULT '',
  merchant int(11) DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  shop int(11) DEFAULT -1,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand),
  KEY dk (merchant,shop,style_number,brand,type,firm,year)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_NEW_DETAIL_AMOUNT} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL,
  style_number varchar(64) NOT NULL,
  brand int(11) DEFAULT -1,
  color int(11) DEFAULT -1,
  size varchar(8) DEFAULT '0',
  total int(11) DEFAULT 0,
  merchant int(11) DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  shop int(11) DEFAULT -1,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand,color,size),
  KEY dk (merchant,shop,style_number,brand)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK} (
  id int(11) NOT NULL AUTO_INCREMENT,
  bcode varchar(32) DEFAULT '0',
  rsn varchar(32) DEFAULT '-1',
  style_number varchar(64) NOT NULL,
  brand int(11) DEFAULT -1,
  firm int(11) DEFAULT -1,
  type int(11) DEFAULT -1,
  sex tinyint(4) DEFAULT -1,
  season tinyint(4) DEFAULT -1,
  year year(4) DEFAULT 0,
  amount int(11) DEFAULT 0,
  s_group varchar(32) DEFAULT '0',
  free tinyint(4) DEFAULT 0,
  vir_price decimal(10,2) DEFAULT 0,
  promotion int(11) NOT NULL DEFAULT -1,
  score int(11) NOT NULL DEFAULT -1,
  org_price decimal(10,2) DEFAULT 0,
  tag_price decimal(10,2) DEFAULT 0,
  ediscount decimal(4,1) DEFAULT 0,
  discount decimal(4,1) DEFAULT 0,
  path varchar(255) DEFAULT '',
  alarm_day tinyint(4) DEFAULT -1,
  unit tinyint(4) DEFAULT 0,
  sell int(11) DEFAULT 0,
  contailer int(11) DEFAULT -1,
  alarm_a int(11) DEFAULT -1,
  level tinyint(4) DEFAULT -1,
  executive int(11) DEFAULT -1,
  category int(11) DEFAULT -1,
  fabric varchar(256) DEFAULT '',
  feather varchar(256) DEFAULT '',
  shop int(11) DEFAULT -1,
  state tinyint(4) DEFAULT 0,
  gift tinyint(4) DEFAULT 0,
  merchant int(11) DEFAULT -1,
  last_sell datetime NOT NULL DEFAULT 0,
  change_date datetime NOT NULL DEFAULT 0,
  entry_date datetime NOT NULL DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (merchant,shop,style_number,brand),
  KEY dk (merchant,firm),
  KEY bcode (bcode)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_NOTE} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) DEFAULT '-1',
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) DEFAULT -1,
  color int(11) DEFAULT -1,
  size varchar(8) DEFAULT '0',
  shop int(11) DEFAULT -1,
  alarm_a int(11) DEFAULT -1,
  merchant int(11) DEFAULT -1,
  total int(11) DEFAULT 0,
  entry_date datetime NOT NULL DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (merchant,shop,style_number,brand,color,size)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_SALE} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL default '',
  pay_sn int(11) NOT NULL DEFAULT -1,
  account int(11) DEFAULT -1,
  employ varchar(8) NOT NULL default '',
  retailer int(11) NOT NULL DEFAULT -1,
  shop int(11) NOT NULL DEFAULT -1,
  merchant int(11) NOT NULL DEFAULT -1,
  tbatch int(11) DEFAULT -1,
  tcustom tinyint(4) DEFAULT -1,
  balance decimal(10,2) DEFAULT 0,
  base_pay decimal(10,2) DEFAULT 0,
  should_pay decimal(10,2) DEFAULT 0,
  cash decimal(10,2) DEFAULT 0,
  card decimal(10,2) DEFAULT 0,
  withdraw decimal(10,2) DEFAULT 0,
  verificate decimal(10,2) DEFAULT 0,
  total int(11) NOT NULL DEFAULT 0,
  lscore int(11) NOT NULL DEFAULT 0,
  score int(11) NOT NULL DEFAULT 0,
  comment varchar(255) NOT NULL DEFAULT '',
  g_ticket tinyint(4) NOT NULL DEFAULT 0,
  type tinyint(4) DEFAULT -1,
  state varchar(16) NOT NULL DEFAULT '0',
  check_date datetime DEFAULT 0,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  ticket decimal(10,2) DEFAULT 0,
  wxin decimal(10,2) NOT NULL DEFAULT 0,
  aliPay decimal(10,2) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn),
  KEY dk (merchant,shop,employ,retailer)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_SALE_DETAIL} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) NOT NULL DEFAULT -1,
  merchant int(11) NOT NULL DEFAULT -1,
  type int(11) DEFAULT -1,
  sex tinyint(4) DEFAULT -1,
  s_group varchar(32) DEFAULT '0',
  free tinyint(4) DEFAULT 0,
  season tinyint(4) DEFAULT -1,
  firm int(11) DEFAULT -1,
  year year(4) DEFAULT 0,
  total int(11) DEFAULT 0,
  promotion int(11) NOT NULL DEFAULT -1,
  score int(11) NOT NULL DEFAULT -1,
  org_price decimal(10,2) DEFAULT 0,
  tag_price decimal(10,2) DEFAULT 0,
  discount decimal(4,1) DEFAULT 0,
  fdiscount decimal(4,1) DEFAULT 0,
  rdiscount decimal(4,1) DEFAULT 0,
  fprice decimal(10,2) DEFAULT 0,
  rprice decimal(10,2) DEFAULT 0,
  path varchar(255) DEFAULT '',
  comment varchar(127) DEFAULT '',
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  ediscount decimal(4,1) DEFAULT 0,
  shop int(11) DEFAULT -1,
  in_datetime datetime DEFAULT 0,
  reject tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand),
  KEY dk (merchant,style_number,brand,type,firm,year),
  KEY shop (shop)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_SALE_DETAIL_AMOUNT} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) DEFAULT -1,
  color int(11) DEFAULT -1,
  size varchar(8) DEFAULT '0',
  total int(11) DEFAULT 0,
  entry_date datetime DEFAULT 0,
  merchant int(11) DEFAULT -1,
  deleted int(11) DEFAULT 0,
  shop int(11) DEFAULT -1,
  PRIMARY KEY (id),
  UNIQUE KEY uk (merchant,rsn,style_number,brand,color,size)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_TRANSFER} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  fshop int(11) DEFAULT -1,
  tshop int(11) DEFAULT -1,
  employ varchar(8) NOT NULL DEFAULT '',
  total int(11) DEFAULT 0,
  cost decimal(10,2) DEFAULT 0,
  comment varchar(255) DEFAULT '',
  merchant int(11) DEFAULT -1,
  state tinyint(4) DEFAULT 0,
  check_date datetime DEFAULT 0,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn),
  KEY dk (merchant,fshop,tshop,employ)
) DEFAULT CHARSET=utf8;


CREATE TABLE ${TABLE_STOCK_TRANSFER_DETAIL} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  bcode varchar(32) DEFAULT '0',
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) DEFAULT -1,
  type int(11) DEFAULT -1,
  sex tinyint(4) DEFAULT -1,
  season tinyint(4) DEFAULT -1,
  firm int(11) DEFAULT -1,
  s_group varchar(32) DEFAULT '0',
  free tinyint(4) DEFAULT 0,
  year year(4) DEFAULT 0,
  org_price decimal(10,2) DEFAULT 0,
  tag_price decimal(10,2) DEFAULT 0,
  discount decimal(4,1) DEFAULT 0,
  ediscount decimal(4,1) DEFAULT 0,
  amount int(11) DEFAULT 0,
  path varchar(255) DEFAULT '',
  merchant int(11) DEFAULT -1,
  fshop int(11) DEFAULT -1,
  tshop int(11) DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,merchant,style_number,brand),
  KEY dk (merchant,fshop,tshop,style_number,brand)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_TRANSFER_DETAIL_AMOUNT} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) DEFAULT -1,
  color int(11) DEFAULT -1,
  size varchar(8) DEFAULT '0',
  total int(11) DEFAULT 0,
  merchant int(11) DEFAULT -1,
  fshop int(11) DEFAULT -1,
  tshop int(11) DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,merchant,style_number,brand,color,size),
  KEY dk (merchant,fshop,tshop,style_number,brand,color,size)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_FIX} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  merchant int(11) NOT NULL DEFAULT -1,
  shop int(11) DEFAULT -1,
  firm int(11) DEFAULT -1,
  employ varchar(8) NOT NULL DEFAULT '',
  shop_total int(11) NOT NULL DEFAULT -1,
  db_total int(11) NOT NULL DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn),
  KEY dk (merchant,shop,employ)
) DEFAULT CHARSET=utf8;

CREATE TABLE ${TABLE_STOCK_FIX_DETAIL_AMOUNT} (
  id int(11) NOT NULL AUTO_INCREMENT,
  rsn varchar(32) NOT NULL DEFAULT '',
  merchant int(11) DEFAULT -1,
  shop int(11) DEFAULT -1,
  style_number varchar(64) NOT NULL DEFAULT '',
  brand int(11) DEFAULT -1,
  color int(11) DEFAULT -1,
  size varchar(8) DEFAULT '0',
  shop_total int(11) NOT NULL DEFAULT -1,
  db_total int(11) NOT NULL DEFAULT -1,
  entry_date datetime DEFAULT 0,
  deleted int(11) DEFAULT 0,
  PRIMARY KEY (id),
  UNIQUE KEY uk (rsn,style_number,brand,color,size),
  KEY dk (merchant,style_number,brand,color,size)
) DEFAULT CHARSET=utf8;

EOF
