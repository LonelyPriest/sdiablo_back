/*
Script of create DB tables, of cause, Mysql was used
*/
--
/*
shopman(1..*)---------(1)shops(0..*)--------(0..*)stocks
                           |(1..*)
                           |
                           |(1..*)
			 customer
			   |(1)
			   |
			   |(0..1)
			 member
*/

/* ***BEING*** CRM *** */
create table employees
(
    id              INTEGER AUTO_INCREMENT,	
    number          VARCHAR(8),
    name            VARCHAR(64),
    sex             SMALLINT(1), -- 0:woman, 1:man
    entry           DATE,
    position        SMALLINT(1) default 2, -- 0:supper, 1: shopowner; 2: saler
    mobile          VARCHAR(11),
    address         VARCHAR(64),
    shop            INTEGER default -1,
    merchant        INTEGER, -- which merchant belong to
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique  key     index_mn (merchant, name),
    -- key             index_m  (merchant),
    primary key     (id)
) default charset=utf8;

create table merchants
(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(64) not null,
    owner            VARCHAR(64) not null,  -- the merchant belonged to
    mobile           VARCHAR(11) not null,
    address          VARCHAR(256) not null,
    balance          INTEGER not null default 0, -- fen
    sms_send         INTEGER not null default 0,
    type             TINYINT default 0,
    -- province         TINYINT default -1, -- which province
    entry_date       DATE,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique  key      name (name),
    primary key      (id)
) default charset=utf8;


create table region
(
    id               INTEGER AUTO_INCREMENT, 
    merchant         INTEGER not null default -1, 
    name             VARCHAR(64) not null,
    comment          VARCHAR(256) default null,
    entry_date       DATETIME not null,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique  key   uk (merchant, name),
    primary key      (id)
) default charset=utf8;

create table shops
(
    id                 INTEGER AUTO_INCREMENT,
    repo               INTEGER default -1, -- which repertory
    type               TINYINT default 0, -- 0: shop, 1: repo
    name               VARCHAR(255) not null,
    address            VARCHAR(255),
    open_date          DATE,
    master             VARCHAR(8) default null,
    region             INTEGER default -1, -- which repertory

    charge             INTEGER default -1, -- charge strategy
    draw               INTEGER default -1, -- withdraw strategy
    score              INTEGER default -1, -- score strategy
    merchant           INTEGER default -1, -- which merchant belong to
    deleted            INTEGER default 0, -- 0: no;  1: yes
    entry_date         DATETIME not null,
    
    unique key index_mn (merchant, name),
    -- key        index_s  (merchant),
    primary key        (id)
) default charset=utf8;

create table suppliers
(
    id              INTEGER AUTO_INCREMENT,
    bcode           INTEGER default 0, -- use to bar code
    code            INTEGER default -1,
    name            VARCHAR(128) not null,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99
    mobile          VARCHAR(12),
    address         VARCHAR(256),
    expire          INTEGER default -1,
    comment         VARCHAR(256),
    merchant        INTEGER default -1, -- which merchant belong to
    change_date     DATETIME,
    entry_date      DATETIME,
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique key      index_mn (merchant, name),
    -- key             index_m (merchant),
    primary key     (id)
) default charset=utf8;

create table firm_balance_history
(
    id              INTEGER AUTO_INCREMENT,
    rsn             VARCHAR(32) default -1, 
    firm            INTEGER default -1,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99
    metric          DECIMAL(10, 2) default 0, -- max: 99999999.99
    action          TINYINT default -1,
    shop            INTEGER default -1,
    merchant        INTEGER default -1,
    entry_date      DATETIME,
    key     dk (merchant, firm, shop),
    primary key     (id)
) default charset=utf8;

create table size_group(
   id               INTEGER AUTO_INCREMENT,
   name             VARCHAR(16),
   si               VARCHAR(8),
   sii              VARCHAR(8),
   siii             VARCHAR(8),
   siv              VARCHAR(8),
   sv               VARCHAR(8),
   svi              VARCHAR(8),
   svii             VARCHAR(8),
   merchant         INTEGER,
   deleted          INTEGER default 0, -- 0: no;  1: yes
   unique key       index_nm (merchant, name),
   primary key      (id)
)default charset=utf8;

create table size_spec(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(8) not null,
    spec             VARCHAR(64) default '',  -- 150/76A; 155/80A
    ctype            INTEGER default -1,
    merchant         INTEGER default -1, -- type belong to
    deleted          INTEGER default 0, -- 0: no;  1: yes 
    unique  key uk   (merchant, name, ctype),
    primary key      (id)
)default charset=utf8;

create table colors
(
    id               INTEGER AUTO_INCREMENT,
    bcode            INTEGER default 0, -- use to bar code
    name             VARCHAR(8) not null,
    type             TINYINT default 0, -- color type, 0: nothing
    remark           VARCHAR(255),
    merchant         INTEGER default null,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique key       index_mn (merchant, name),
    primary key      (id)
) default charset=utf8;

-- 1:red;  2:yellow;  3:green;  4:blue;
-- 5:dark; 6:white;   7:purple; 8:gray
create table color_type(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(8),
    merchant         INTEGER default 0,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    unique key name (name),
    primary key      (id)
)default charset=utf8;

create table brands(
    id               INTEGER AUTO_INCREMENT,
    bcode            INTEGER default 0, -- use to bar code
    name             VARCHAR(8) default null,
    supplier         INTEGER default -1,  -- supplier of brand
    merchant         INTEGER default -1,  -- brand belong to
    remark           VARCHAR(255) default null,
    deleted          INTEGER default 0, -- 0: no;  1: yes
    entry            DATETIME NOT NULL DEFAULT 0,
    
    unique  key      index_nm (merchant, name, supplier),
    primary key      (id)
)default charset=utf8;

create table inv_types(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(64) not null,
    bcode            INTEGER default 0, -- use to bar code
    ctype            INTEGER default -1,
    merchant         INTEGER default -1, -- type belong to
    deleted          INTEGER default 0, -- 0: no;  1: yes

    unique  key     index_nm (merchant, name),
    primary key      (id)
)default charset=utf8;

create table type_class(
    id               INTEGER AUTO_INCREMENT,
    name             VARCHAR(64) not null,
    -- spec             VARCHAR(64) default '',  -- 150/76A; 155/80A
    merchant         INTEGER default -1, -- type belong to
    deleted          INTEGER default 0, -- 0: no;  1: yes

    unique  key uk   (merchant, name),
    primary key      (id)
)default charset=utf8;


/* --------------------------------------------------------------------------------
** right
-------------------------------------------------------------------------------- */
create table users
(
    id             INTEGER AUTO_INCREMENT,
    name           VARCHAR(64) not null,
    password       VARCHAR(128) not null, -- should be encrypt
    type           TINYINT default -1, -- type to user 0: supper, 1: merchant 2:user
    merchant       INTEGER default -1, -- which merchant belong to, 0: means super
    
    retailer       INTEGER default -1,
    employee       VARCHAR(8) not null,
    stime          INTEGER default 0,
    etime          INTEGER default 0,
    sdays          INTEGER default 0,
    
    max_create     INTEGER default -1, -- max users can be created of the user
    create_date    DATETIME,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key    index_name (name),
    key            merchant (merchant),
    primary key    (id)
) default charset=utf8;

create table user_to_role(
    id             INTEGER AUTO_INCREMENT,
    user_id        INTEGER not null,
    role_id        INTEGER not null,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key    index_ur (user_id, role_id),
    primary key    (id)
)default charset=utf8;

create table role_to_shop(
    id             INTEGER AUTO_INCREMENT,
    role_id        INTEGER not null,
    shop_id        INTEGER not null,
    func_id        INTEGER not null,   -- right id of this shop
    merchant       INTEGER default -1,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key    index_mrsf (merchant, role_id, shop_id, func_id),
    primary key    (id)
)default charset=utf8; 

create table roles(
    id             INTEGER AUTO_INCREMENT,
    name           VARCHAR(127) not null,
    remark         VARCHAR(255),
    type           TINYINT default -1, -- type to role 1: merchant 2:user
    merchant       INTEGER default -1,
    created_by     INTEGER default -1, -- who create this role
    create_date    DATETIME,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key index_mn (merchant, name),
    primary key    (id)
)default charset=utf8;

create table role_to_right(
    id             INTEGER AUTO_INCREMENT,
    role_id        INTEGER not null,
    right_id       INTEGER not null,
    merchant       INTEGER default -1,
    deleted        INTEGER default 0,  -- 0: no;  1: yes
    unique  key index_mrr (merchant, role_id, right_id),
    primary key    (id)
)default charset=utf8;

create table catlog(
    id             INTEGER AUTO_INCREMENT,
    catlog_id      INTEGER not null,
    name           VARCHAR(255) not null,
    path           VARCHAR(255) not null,
    parent         INTEGER default 0, -- 0: root
    deleted        INTEGER default 0, -- 0: no;  1: yes
    primary key    (id)
)default charset=utf8;

create table funcs(
    id             INTEGER AUTO_INCREMENT,
    fun_id         INTEGER not null,
    name           VARCHAR(255) not null,
    call_fun       VARCHAR(255) not null,
    catlog         INTEGER default -1, -- -1: nothing
    deleted        INTEGER default 0, -- 0: no;  1: yes
    primary key    (id)
)default charset=utf8;
/* --------------------------------------------------------------------------------
** end right
-------------------------------------------------------------------------------- */


/* --------------------------------------------------------------------------------
** print
-------------------------------------------------------------------------------- */
create table w_print_server(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(64) not null, 
   path            VARCHAR(128) not null,
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   -- unique  key     (path),
   primary key     (id)
)default charset=utf8;

create table w_printer(
   id              INTEGER AUTO_INCREMENT,
   brand           VARCHAR(64) not null,
   model           VARCHAR(32) not null,
   -- col_width       INTEGER not null,
   entry_date      DATETIME not null default 0, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   unique  key     (brand, model),
   primary key     (id)
)default charset=utf8;

create table w_printer_conn(
   id              INTEGER AUTO_INCREMENT,
   printer         INTEGER not null,
   paper_column    INTEGER not null,
   paper_height    INTEGER not null, 
   server          INTEGER, 
   sn              VARCHAR(16),
   code            VARCHAR(16),
   shop            INTEGER,
   -- type            TINYINT default 0, -- 0: shop 1: respo
   status          TINYINT default 0, -- 0: start 1: pause
   merchant        INTEGER, 
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   unique key      (sn, code),
   primary key     (id)
)default charset=utf8;


create table w_bank_card(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(16) not null,
   no              VARCHAR(32) not null,
   bank            VARCHAR(64) not null,
   remark          VARCHAR(64) default null,
   merchant        INTEGER not null,
   entry_date      DATE, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   
   unique  key     index_nm (no, merchant), 
   primary key     (id)
)default charset=utf8;

-- about base setting
create table w_base_setting(
   id              INTEGER AUTO_INCREMENT,
   ename           VARCHAR(16) not null,  -- english name
   cname           VARCHAR(16) not null,  -- chinese name
   value           VARCHAR(255) not null,
   type            TINYINT not null, -- 0: print 1: table
   remark          VARCHAR(255) default null,
   shop            INTEGER default -1,
   merchant        INTEGER default -1,
   entry_date      DATETIME default 0, 
   deleted         INTEGER default 0, -- 0: no;  1: yes
   unique key      index_me (merchant, shop, ename),
   primary key     (id)
)default charset=utf8;

-- about print format
create table w_print_format(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(16) not null,
   print           TINYINT default 1,  -- 1: yes, print 0; no
   -- width           TINYINT default -1,
   shop            INTEGER default -1, 
   merchant        INTEGER default -1,
   entry_date      DATETIME default 0,
   deleted         INTEGER default 0, -- 0: no;  1: yes
   unique key      index_msn (merchant, shop, name),
   primary key     (id)
)default charset=utf8;


/** ----------------------------------------------------------------------------
member
-----------------------------------------------------------------------------**/
create table w_retailer
(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64) not null,
    card            VARCHAR(16) default null,
    birth           DATE default 0,
    password        VARCHAR(128) default null,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99
    consume         DECIMAL(10, 2) default 0, -- max: 99999999.99
    score           INTEGER not null default 0,
    mobile          VARCHAR(11),
    address         VARCHAR(255),
    shop            INTEGER default -1,
    draw            INTEGER default -1, -- with draw strategy
    merchant        INTEGER default -1, -- which merchant belong to
    type            TINYINT default 0,  -- 0: common, 1: charge
    py              VARCHAR(8) default null,
    id_card         VARCHAR(18) default null,
    change_date     DATETIME default 0, -- last changed
    entry_date      DATETIME default 0, -- last changed
    deleted         INTEGER default 0, -- 0: no;  1: yes
    
    unique  key  uk (merchant, name, mobile),
    primary key     (id)
) default charset=utf8;

create table w_card
(
    id              INTEGER AUTO_INCREMENT,
    retailer        INTEGER not null default -1,
    ctime           INTEGER default -1,
    sdate           DATE default 0,
    edate           DATE default 0,
    cid             INTEGER default -1,
    rule            TINYINT default -1, -- 2: therotic times card, 3: month card, 4: quarter card, 5: year card
    merchant        INTEGER default -1,
    shop            INTEGER default -1, 
    entry_date      DATETIME,
    unique key      uk (merchant, retailer, cid),
    primary key     (id)
) default charset=utf8;

create table w_card_good
(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64) not null,
    tag_price       INTEGER default -1, 
    merchant        INTEGER default -1,
    shop            INTEGER default -1,
    entry_date      DATETIME,
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique key      uk (name, merchant, shop),
    primary key     (id)
) default charset=utf8;

create table w_card_sale
(
    id              INTEGER AUTO_INCREMENT,
    rsn             VARCHAR(32) default -1,
    employee        VARCHAR(8) not null,
    retailer        INTEGER not null default -1,
    card            INTEGER not null default -1, -- refer to w_card
    cid             INTEGER not null default -1, -- refer to w_card
    amount          INTEGER not null default -1, -- refer to w_charge
    cgood           INTEGER default -1, -- refer to card_good
    tag_price       INTEGER default -1,
    
    merchant        INTEGER default -1,
    shop            INTEGER default -1,
    comment         VARCHAR(127) default null,
    entry_date      DATETIME,
    deleted         INTEGER default 0, -- 0: no;  1: yes
    unique key      uk (rsn),
    key     dk     (merchant, shop, retailer),
    primary key     (id)
) default charset=utf8;

create table retailer_balance_history
(
    id              INTEGER AUTO_INCREMENT,
    rsn             VARCHAR(32) default -1, 
    retailer        INTEGER default -1,
    obalance        DECIMAL(10, 2) default 0, -- max: 99999999.99
    nbalance        DECIMAL(10, 2) default 0, -- max: 99999999.99
    action          TINYINT default -1,
    shop            INTEGER default -1,
    merchant        INTEGER default -1,
    entry_date      DATETIME,
    key     dk (merchant, retailer, shop),
    primary key     (id)
) default charset=utf8;

/*
 * promotion
*/
create table w_charge(
    id              INTEGER AUTO_INCREMENT,
    merchant        INTEGER not null default -1,
    name            VARCHAR(64) not null,
    rule	    TINYINT default 0, -- [0, 1, 2, 3]
    
    xtime           TINYINT default 1, 
    ctime           INTEGER not null default -1, -- consume time 
    charge          INTEGER not null default 0,
    balance         INTEGER not null default 0, -- send balance when charge
    type            TINYINT default 0, -- 0:recharge 1:withdraw
    sdate           DATE default 0,
    edate           DATE default 0,
    remark          VARCHAR(128) default null,
   
    entry           DATETIME default 0,
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk  (merchant, name),
    primary key     (id)
) default charset=utf8;

create table w_score(
   id              INTEGER AUTO_INCREMENT,
   name            VARCHAR(64) not null,
   merchant        INTEGER not null default -1,
   balance         INTEGER not null default 0,
   score           INTEGER not null default 0,
   type            TINYINT not null default 0, -- 0: to score 1: to money
   sdate           DATE default 0,
   edate           DATE default 0,
   remark          VARCHAR(128) default null,
   
   entry           DATETIME default 0,
   deleted         INTEGER default 0, -- 0: no;  1: yes 
   
   unique  key uk  (merchant, name),
   primary key     (id)
) default charset=utf8;


create table w_promotion(
    id              INTEGER AUTO_INCREMENT,
    merchant        INTEGER not null default -1,
    -- shop            INTEGER not null default -1,
    name            VARCHAR(64) default NULL,
    
    rule            TINYINT not null default -1, 
    discount        DECIMAL(3, 0)  not null default 100,
    cmoney          DECIMAL(10, 2) not null default 0,  -- consume money
    rmoney          DECIMAL(10, 2) not null default 0,  -- reduce money
    sdate           DATE default 0,
    edate           DATE default 0,

    remark          VARCHAR(128) default null,
    entry           DATETIME default 0,
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk  (merchant, name),
    primary key     (id)
    
) default charset=utf8;

create table w_ticket(
    id              INTEGER AUTO_INCREMENT,
    batch           INTEGER not null,
    sid             INTEGER default -1, -- score promotion
    balance         INTEGER not null,
    retailer        INTEGER default -1, -- -1: means no retailer to related
    state           INTEGER default 0, -- 0: checking; 1: checked; 2: consumed
    remark          VARCHAR(128) default null,
    merchant        INTEGER not null default -1, 
    entry_date      DATETIME default 0, 
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk  (merchant, batch),
    key         dk  (merchant, retailer),
    primary key     (id)
    
) default charset=utf8;


create table w_ticket_custom(
    id              INTEGER AUTO_INCREMENT,
    batch           INTEGER not null,
    balance         INTEGER not null,
    retailer        INTEGER default -1, -- -1: who consumed
    state           INTEGER default 1, -- 0: discard; 1: checked; 2: consumed
    shop            INTEGER default -1, -- consumed shop
    remark          VARCHAR(128) not null,
    merchant        INTEGER not null default -1, 
    entry_date      DATETIME default 0, 
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk  (merchant, batch),
    key         dk  (merchant, retailer),
    primary key     (id)
    
) default charset=utf8;

-- create table shop_promotion(
--     id              INTEGER AUTO_INCREMENT,
--     merchant        INTEGER not null default -1,
--     shop            INTEGER not null default -1,
--     pid             INTEGER not null default -1, -- reference to promotion
--     entry           DATETIME default 0,
--     deleted         INTEGER default 0, -- 0: no;  1: yes

--     unique  key uk  (merchant, shop, pid),
--     primary key     (id)
    
-- ) default charset=utf8;


/*
* invnentory
*/
create table w_inventory_good
(
    id               INTEGER AUTO_INCREMENT,
    bcode            VARCHAR(32) default 0, -- use to bar code
    style_number     VARCHAR(64) not null,
    brand            INTEGER default -1,
    firm             INTEGER default -1,

    color            VARCHAR (255), -- all of the color seperate by comma "1, 2, 3..."
    size             VARCHAR(255), -- all of the size seperate by comma "S/26, M/27...."
    type             INTEGER default -1, -- reference to inv_type 
    sex              TINYINT default -1, -- 0: man, 1:woman 
    season           TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    year             YEAR(4) not null default 0,
       
    s_group          VARCHAR(32) default 0,  -- which size group "1, 2"
    free             TINYINT default 0,  -- 0: free color and free size 1: others	 

    -- promotion        INTEGER not null default -1,
    org_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    ediscount        DECIMAL(4, 1), -- max: 100, discount of entry
    discount         DECIMAL(4, 1), -- max: 100, discount of sell
    path             VARCHAR(255) default null, -- the image path
    alarm_day        TINYINT default -1,  -- the days of alarm

    --
    contailer        INTEGER default -1,
    alarm_a          INTEGER default 0,

    --
    level            TINYINT default -1,
    executive        INTEGER default -1,
    category         INTEGER default -1,
    fabric           VARCHAR(256) default null,

    --
    merchant         INTEGER default -1,
    
    change_date      DATETIME default 0, -- date of last change 
    entry_date       DATETIME default 0,
    deleted          INTEGER default 0, -- 0: no;  1: yes

    unique key       uk (merchant, style_number, brand),
    key              firm  (firm),
    key              bcode (bcode),
    
    primary key      (id)
)default charset=utf8;

create table w_inventory
(
    id               INTEGER AUTO_INCREMENT,
    bcode            VARCHAR(32) default 0, -- use to bar code
    rsn              VARCHAR(32) default null, -- record sn    
    style_number     VARCHAR(64) not null,
    brand            INTEGER default -1,
    firm             INTEGER default -1,

    type             INTEGER default -1, -- reference to inv_type
    sex              TINYINT default -1, -- 0: man, 1:woman
    season           TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    year             YEAR(4),

    amount           INTEGER default 0,
    s_group          VARCHAR(32) default 0,  -- which size group
    free             TINYINT default 0,  -- free color and free size 

    promotion        INTEGER not null default -1, -- promotion
    score            INTEGER not null default -1, -- score
    
    org_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price        DECIMAL(10, 2) default 0, -- max: 99999999.99
    
    ediscount        DECIMAL(4, 1), -- max: 100, discount of entry
    discount         DECIMAL(4, 0), -- max: 100
    
    path             VARCHAR(255) default null, -- the image path
    alarm_day        TINYINT default -1,  -- the days of alarm 
    sell             INTEGER default 0,  -- how many selled

    --
    contailer        INTEGER default -1,
    alarm_a          INTEGER default 0,

    --
    shop             INTEGER default -1,
    state            INTEGER default 0,  -- 0: wait for check, 1: checked

    merchant         INTEGER default -1,
    
    last_sell        DATETIME NOT NULL default 0,
    change_date      DATETIME NOT NULL default 0, -- date of last change 
    entry_date       DATETIME NOT NULL default 0,
    
    deleted          INTEGER default 0, -- 0: no;  1: yes
    
    unique key       uk (merchant, shop, style_number, brand),
    key              dk (merchant, firm),
    key              bcode (bcode),
    primary key      (id)
)default charset=utf8;

create table w_inventory_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) default -1, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    shop           INTEGER default -1,

    --
    alarm_a        INTEGER default 0, 
    --
    
    merchant       INTEGER default -1,
    total          INTEGER default 0,
    entry_date     DATETIME not null default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique key     uk (merchant, shop, style_number, brand, color, size),
    -- key            index_sbsm (style_number, brand, shop, merchant),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    employ         VARCHAR(8) not null,
    firm           INTEGER default -1, 
    shop           INTEGER default -1,  -- which shop saled the goods
    merchant       INTEGER default -1,
    
    balance        DECIMAL(10, 2) default 0, -- max: 99999999.99, balance of last record 
    should_pay     DECIMAL(10, 2) default 0, -- max: 99999999.99
    has_pay        DECIMAL(10, 2) default 0, -- max: 99999999.99
    cash           DECIMAL(10, 2) default 0, -- max: 99999999.99
    card           DECIMAL(10, 2) default 0, -- max: 99999999.99
    wire           DECIMAL(10, 2) default 0, -- max: 99999999.99
    verificate     DECIMAL(10, 2) default 0, -- max: 99999999.99
    total          INTEGER default 0,
    comment        VARCHAR(255) default null,

    e_pay_type     TINYINT  default -1,
    e_pay          DECIMAL(10, 2) default 0, -- max: 99999999.99

    type           TINYINT default -1,  -- 0: new inventory 1: reject inventory
    
    state          TINYINT  default 0,  -- 0: wait for check, 1: checked
    check_date     DATETIME default 0, -- date of last change 
    entry_date     DATETIME default 0,
    op_date        DATETIME default 0, 
    deleted        INTEGER  default 0, -- 0: no;  1: yes
    unique  key uk (rsn),
    key     dk (merchant, shop, firm, employ),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new_detail(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1, 
    
    type           INTEGER default -1, -- reference to inv_type 
    sex            TINYINT default -1, -- 0: man, 1:woman
    season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter 
    firm           INTEGER default -1, 
    s_group        VARCHAR(32) default 0,  -- which size group 
    free           TINYINT default 0,  -- free color and free size
    year           YEAR(4),

    -- promotion      INTEGER not null default -1,
    org_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    ediscount      DECIMAL(4, 1)  default 100, -- max: 100
    discount       DECIMAL(4, 1)  default 100, -- max: 100
    amount         INTEGER default 0,
    over           INTEGER default 0, -- overflow
    
    path           VARCHAR(255) default null, -- the image path
    merchant       INTEGER default -1,
    shop           INTEGER default -1,

    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    
    unique  key uk (rsn, style_number, brand),
    key     dk (merchant, style_number, brand, type, firm, year),
    primary key    (id)
)default charset=utf8;

create table w_inventory_new_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    
    total          INTEGER default 0,
    merchant       INTEGER default -1,
    shop           INTEGER default -1,
    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique  key uk (rsn, style_number, brand, color, size),
    key dk (merchant, shop, style_number, brand),
    -- key     index_msbc (merchant, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;

create table w_inventory_fix(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    merchant       INTEGER not null default -1,
    shop           INTEGER default -1,                 -- which shop saled the goods
    firm           INTEGER default -1,
    employ         VARCHAR(8) not null, 
    
    shop_total     INTEGER not null default -1,
    db_total       INTEGER not null default -1,
    
    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key uk (rsn),
    key     dk (merchant, shop, employ),
    primary key    (id)
)default charset=utf8;

-- create table w_inventory_fix_detail(
--     id             INTEGER AUTO_INCREMENT,
--     rsn            VARCHAR(32) not null, -- record sn
    
--     style_number   VARCHAR(64) not null,
--     brand          INTEGER default -1,
    
--     type           INTEGER default -1,
--     year           YEAR(4),
--     season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter 
--     firm           INTEGER default -1,
    
--     s_group        VARCHAR(32) default 0,  -- which size group 
--     free           TINYINT default 0,  -- free color and free size 
--     path           VARCHAR(255) default null, -- the image path
        
--     exist          INTEGER not null,
--     fixed          INTEGER default 0,
--     metric         INTEGER default 0,
--     org_price      DECIMAL(10, 2) default 0, -- max: 99999999.99

--     merchant       INTEGER default -1,
--     shop           INTEGER default -1,
    
--     entry_date     DATETIME default 0,
--     deleted        INTEGER default 0, -- 0: no;  1: yes

--     unique  key uk (rsn, style_number, brand),
--     key dk (merchant, style_number, brand, type, firm),
--     primary key    (id)
-- )default charset=utf8;

create table w_inventory_fix_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    merchant       INTEGER default -1,
    shop           INTEGER default -1,
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default 0, -- S/26, M/27....

    shop_total     INTEGER not null default -1,
    db_total       INTEGER not null default -1,

    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    
    unique  key uk (rsn, style_number, brand, color, size),
    key dk (merchant, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;


/*
* transfer
*/
create table w_inventory_transfer(
    id		   INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    fshop          INTEGER default -1,                 -- which shop saled the goods
    tshop          INTEGER default -1,                 -- which shop saled the goods
    employ         VARCHAR(8) not null,     -- employ
    total          INTEGER default 0,
    cost           DECIMAL(10, 2) default 0, -- max: 99999999.99
    comment        VARCHAR(255) default null,
    merchant       INTEGER,
    
    state          TINYINT  default 0,  -- 0: wait for check, 1: checked
    check_date     DATETIME default null, -- date of last change
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key  uk (rsn),
    key          dk (merchant, fshop, tshop, employ),
    primary key     (id)
)default charset=utf8;

create table w_inventory_transfer_detail(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    bcode          VARCHAR(32) default 0, -- use to bar code
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,

    type           INTEGER default -1, -- reference to inv_type
    sex            TINYINT default -1, -- 0: man, 1:woman
    season         TINYINT, -- 0:spring, 1:summer, 2:autumn, 3:winter
    firm           INTEGER default -1,
    s_group        VARCHAR(32) default 0,  -- which size group
    free           TINYINT default 0,  -- free color and free size
    year           YEAR(4),

    org_price      DECIMAL(10, 2) default 0, -- max: 99999999.99
    tag_price      DECIMAL(10, 2) default 0, -- max: 99999999.99 
    discount       DECIMAL(4, 1)  default 100, -- max: 100
    ediscount      DECIMAL(4, 1)  default 100, -- max: 100 
    amount         INTEGER default 0,

    path           VARCHAR(255) default null, -- the image path
    merchant       INTEGER default -1,
    fshop          INTEGER default -1,                 -- which shop saled the goods
    tshop          INTEGER default -1,                 -- which shop saled the goods
    
    entry_date     DATETIME, 
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key    uk (rsn, merchant, style_number, brand),
    key            dk (merchant, fshop, tshop, style_number, brand),
    primary key    (id)
)default charset=utf8;

create table w_inventory_transfer_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    total          INTEGER default 0,
    merchant       INTEGER default -1,
    fshop          INTEGER default -1,                 -- which shop saled the goods
    tshop          INTEGER default -1,                 -- which shop saled the goods
    entry_date     DATETIME,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    unique key uk  (rsn, merchant, style_number, brand, color, size),
    key        dk  (merchant, fshop, tshop, style_number, brand, color, size),
    primary key    (id)
)default charset=utf8;

/*
* sale
*/
create table w_sale(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    employ         VARCHAR(8) not null,
    retailer       INTEGER not null default -1, 
    shop           INTEGER not null default -1, 
    merchant       INTEGER not null default -1,

    -- promotion     INTEGER not null default -1,
    tbatch        INTEGER not null default -1, -- ticket batch number
    tcustome      TINYINT default -1, -- 0:score_ticket 1:custom_ticket -1: none
    
    -- charge        INTEGER not null default -1,
    
    balance        DECIMAL(10, 2) default 0, -- max: 99999999.99
    should_pay     DECIMAL(10, 2) default 0, -- max: 99999999.99
    -- has_pay        DECIMAL(10, 2) default 0, -- max: 99999999.99
    cash           DECIMAL(10, 2) default 0, -- max: 99999999.99
    card           DECIMAL(10, 2) default 0, -- max: 99999999.99
    wxin           DECIMAL(10, 2) default 0, -- max: 99999999.99
    withdraw       DECIMAL(10, 2) default 0, -- max: 99999999.99
    ticket         DECIMAL(10, 2) default 0, -- max: 99999999.99
    verificate     DECIMAL(10, 2) default 0, -- max: 99999999.99

    -- cbalance       INTEGER not null default 0, -- charge balance
    -- sbalance       INTEGER not null default 0, -- send balance of charging
    
    total          INTEGER not null default 0,
    lscore         INTEGER not null default 0,
    score          INTEGER not null default 0,
    comment        VARCHAR(255) default null, 
    
    type           TINYINT  default -1, -- 0:sale 1:reject
    state          TINYINT  default 0,  -- 0: wait for check, 1: checked
    check_date     DATETIME default 0,  -- date of last change
    entry_date     DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes
    
    unique  key uk (rsn),
    key     dk     (merchant, shop, employ, retailer),
    primary key    (id)
    
)default charset=utf8;

/*
* sale
*/
create table w_sale_detail(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER not null default -1,
    merchant       INTEGER not null default -1,
    shop           INTEGER not null default -1,
    
    type           INTEGER default -1, -- reference to inv_type 
    s_group        VARCHAR(32) default 0,  -- which size group
    free           TINYINT default 0,  -- free color and free size 
    
    season         TINYINT default -1, -- 0:spring, 1:summer, 2:autumn, 3:winter
    firm           INTEGER default -1,
    year           YEAR(4),
    in_datetime    DATETIME default 0,
    
    total          INTEGER default 0,
    promotion      INTEGER not null default -1, -- promotion
    score          INTEGER not null default -1, -- score

    org_price      DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance
    ediscount      DECIMAL(4, 1)  default 0, -- max: 100
    
    tag_price      DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance 
    fdiscount      DECIMAL(4, 1), -- max: 100
    rdiscount      DECIMAL(4, 1), -- max: 100
    fprice         DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance
    rprice         DECIMAL(10, 2) default 0, -- max: 99999999.99, left blance
    
    path           VARCHAR(255) default null, -- the image path
    comment        VARCHAR(127) default null,
    entry_date     DATETIME default 0,
    op_date        DATETIME default 0,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key uk (rsn, style_number, brand),
    key     dk     (merchant, shop, style_number, brand, type, firm, year),
    primary key    (id)
)default charset=utf8;

create table w_sale_detail_amount(
    id             INTEGER AUTO_INCREMENT,
    rsn            VARCHAR(32) not null, -- record sn
    style_number   VARCHAR(64) not null,
    brand          INTEGER default -1,
    color          INTEGER default -1,
    size           VARCHAR(8) default null, -- S/26, M/27....
    total          INTEGER default 0,
    entry_date     DATETIME default 0,
    merchant       INTEGER default -1,
    shop           INTEGER default -1,
    deleted        INTEGER default 0, -- 0: no;  1: yes

    unique  key  uk (rsn, style_number, brand, color, size),
    key     dk      (merchant, shop),
    primary key    (id)
)default charset=utf8;

/* charge */
create table w_charge_detail(
    id              INTEGER AUTO_INCREMENT,
    rsn             VARCHAR(32) not null, -- record sn
    merchant        INTEGER not null default -1,
    shop            INTEGER not null default -1, 
    employ          VARCHAR(8) not null,
    cid             INTEGER not null default -1, -- charge

    retailer        INTEGER not null default -1,
    lbalance        INTEGER not null default 0, -- last balance
    cbalance        INTEGER not null default 0, -- charge balance
    sbalance        INTEGER not null default 0, -- send balance
    cash            INTEGER not null default 0, -- cash
    card            INTEGER not null default 0, -- card
    wxin            INTEGER not null default 0, -- wxin
    comment         VARCHAR(256) default null,
    
    entry_date      DATETIME default 0,
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk (rsn),
    key dk  (merchant, shop, retailer, employ),
    primary key     (id)
    
) default charset=utf8;

/* bill to supplier */
create table w_bill_detail(
    id              INTEGER AUTO_INCREMENT,
    rsn             VARCHAR(32) not null, -- record sn

    shop            INTEGER not null default -1, 
    firm            INTEGER not null default -1, -- charge
    mode            TINYINT not null default -1,
    balance         DECIMAL(10, 2) not null default 0,
    bill            DECIMAL(10, 2) not null default 0,
    veri            DECIMAL(10, 2) not null default 0,
    card            INTEGER not null default -1,
    employee        VARCHAR(8) not null,
    comment         VARCHAR(127) default null,
    state           INTEGER not null default 0,
    merchant        INTEGER not null default -1, 
    entry_date      DATETIME default 0,
    op_date         DATETIME default 0,
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key uk (rsn),
    key         dk (merchant, shop, firm, employee),
    primary key     (id)
    
) default charset=utf8;

/*
* change shift
*/
create table w_change_shift(
    id              INTEGER AUTO_INCREMENT,
    
    merchant        INTEGER not null default -1, 
    employ          VARCHAR(8) not null, 
    shop            INTEGER not null default -1,
        
    total           INTEGER not null default -1, 
    balance         DECIMAL(10, 2) not null default 0,
    cash            DECIMAL(10, 2) not null default 0,
    card            DECIMAL(10, 2) not null default 0,
    wxin            DECIMAL(10, 2) not null default 0,
    withdraw        DECIMAL(10, 2) not null default 0,
    ticket          DECIMAL(10, 2) not null default 0,

    charge          INTEGER not null default 0,
    ccash           INTEGER not null default 0,
    ccard           INTEGER not null default 0,
    cwxin           INTEGER not null default 0,

    y_stock         INTEGER not null default -1, 
    stock           INTEGER not null default -1, 
    stock_in        INTEGER not null default -1,
    stock_out       INTEGER not null default -1,
    
    pcash           DECIMAL(10, 2) not null default 0,
    pcash_in        DECIMAL(10, 2) not null default 0,
    
    comment         VARCHAR(127) default null,
    entry_date      DATETIME default 0,
    
    key     dk (merchant, shop, employ),
    primary key    (id)
    
) default charset=utf8;

/*
* daily record
*/
create table w_daily_report(
    id              INTEGER AUTO_INCREMENT,
    
    merchant        INTEGER not null default -1, 
    shop            INTEGER not null default -1,
        
    sell            INTEGER not null default -1,
    sell_cost       DECIMAL(10, 2) not null default 0,
    balance         DECIMAL(10, 2) not null default 0,
    cash            DECIMAL(10, 2) not null default 0,
    card            DECIMAL(10, 2) not null default 0,
    wxin            DECIMAL(10, 2) not null default 0,
    veri            DECIMAL(10, 2) not null default 0,
    draw            DECIMAL(10, 2) not null default 0,
    ticket          DECIMAL(10, 2) not null default 0,

    charge          DECIMAL(10, 2) not null default 0,

    stockc          INTEGER not null default -1,
    stock           INTEGER not null default -1,
    stock_cost      DECIMAL(10, 2) not null default 0,
    
    stock_in        INTEGER not null default -1,
    stock_out       INTEGER not null default -1,
    stock_in_cost   DECIMAL(10, 2) not null default 0,
    stock_out_cost  DECIMAL(10, 2) not null default 0,

    t_stock_in       INTEGER not null default -1,
    t_stock_out      INTEGER not null default -1,
    t_stock_in_cost  DECIMAL(10, 2) not null default 0, 
    t_stock_out_cost DECIMAL(10, 2) not null default 0,
    
    stock_fix        INTEGER not null default -1,
    stock_fix_cost   DECIMAL(10, 2) not null default 0,

    day             DATE default 0,
    entry_date      DATETIME default 0,

    unique key uk (merchant, shop, day),
    key     dk (merchant, shop),
    primary key    (id)
    
) default charset=utf8;


create table sms_rate(
    id              INTEGER AUTO_INCREMENT,
    merchant        INTEGER not null default -1,
    rate            INTEGER default 0, -- fen
    -- send            INTEGER not null default 0,    
    unique  key uk (merchant),
    primary key    (id)
) default charset=utf8;


create table sms_center(
    id              INTEGER AUTO_INCREMENT,
    merchant        INTEGER not null default -1, 
    url             VARCHAR(128) not null,
    app_key         VARCHAR(64) default -1,
    app_secret      VARCHAR(64) default -1,
    sms_sign_name   VARCHAR(64) default -1,
    sms_sign_method VARCHAR(64) default -1, 
    sms_send_method VARCHAR(128) default -1,
    sms_template    VARCHAR(64) default -1,
    sms_type        VARCHAR(64) default -1,
    sms_version     VARCHAR(8) default -1, 
    
    unique  key uk (merchant),
    primary key    (id)
) default charset=utf8;

/*
** print tag
*/
create table std_executive (
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64) not null,
    merchant        INTEGER not null default -1,
    deleted         INTEGER default 0,

    unique   key  (merchant, name),
    primary key   (id)
) default charset=utf8;

create table safety_category(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64) not null,
    merchant        INTEGER not null default -1,
    deleted         INTEGER default 0,

    unique   key  (merchant, name),
    primary key   (id)
) default charset=utf8;

create table fabric(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(64) not null,
    merchant        INTEGER not null default -1,
    deleted         INTEGER default 0,

    unique   key  (merchant, name),
    primary key   (id)
) default charset=utf8;


create table print_template(
   id              INTEGER AUTO_INCREMENT,
   width           TINYINT default 0,
   height          TINYINT default 0,

   shop            TINYINT default 0,
   style_number    TINYINT default 0,
   brand           TINYINT default 0,
   type            TINYINT default 0,
   firm            TINYINT default 0,
   code_firm       TINYINT default 0,
   expire          TINYINT default 0, -- print expire data of the firm
   
   color           TINYINT default 0,
   size            TINYINT default 0,

   level           TINYINT default 0,
   executive       TINYINT default 0,
   category        TINYINT default 0, 
   fabric          TINYINT default 0,
   
   font            TINYINT default 0,
   font_name       VARCHAR(32) default "",
   font_executive  TINYINT default 0,
   font_category   TINYINT default 0,
   font_price      TINYINT default 0,
   font_fabric     TINYINT default 0,
   
   bold            TINYINT default 0,
   
   solo_brand      TINYINT default 0,
   solo_color      TINYINT default 0,
   solo_size       TINYINT default 0,
   
   hpx_each        TINYINT default 0,
   hpx_executive   TINYINT default 0,
   hpx_category    TINYINT default 0,
   hpx_fabric      TINYINT default 0,
   
   hpx_price       TINYINT default 0,
   hpx_barcode     TINYINT default 0,

   hpx_top         TINYINT default 0,
   hpx_left        TINYINT default 0,
   second_space    INTEGER default 0,
   
   merchant        INTEGER not null default -1,
   unique   key    (merchant),
   primary key     (id)
   
)default charset=utf8;


-- wholesalers

create table wholesaler
(
    id              INTEGER AUTO_INCREMENT,
    name            VARCHAR(127) not null,
    py              VARCHAR(8) default null,
    balance         DECIMAL(10, 2) default 0, -- max: 99999999.99
    mobile          VARCHAR(11),
    address         VARCHAR(255), 
    merchant        INTEGER default -1,
    remark          VARCHAR(255),
    entry_date      DATETIME default 0, 
    deleted         INTEGER default 0, -- 0: no;  1: yes

    unique  key  uk (name, merchant),
    key          dk (merchant),
    primary key     (id)
) default charset=utf8;
