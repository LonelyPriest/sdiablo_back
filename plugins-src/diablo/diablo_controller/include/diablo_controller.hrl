-define(NO, 0).
-define(YES, 1).

-define(TABLET, 1).
-define(SUCCESS, 0).

%% match
-define(AND, 'and').
-define(LIKE, 'like').

%% user type
-define(SUPER, 0).
-define(MERCHANT, 1).
-define(USER, 2).

%% shop
-define(SHOP_MASTER, 1).
-define(SHOP, 0).
-define(REPERTORY, 1).
-define(BAD_REPERTORY, 2).

%% merchant type
-define(SALER, 0).
-define(WHOLESALER, 1).

%% move state
-define(MOVING, 0).
-define(MOVED, 1).

%% check state
-define(CHECKING, 0).
-define(CHECKED, 1).
-define(PRINTED, 2).
-define(DISCARD, 7).

-define(CHECK, 1).
-define(UNCHECK, 0).

-define(DELETE, 0).
-define(ABANDON, 1).

%% wsale
-define(NEW_SALE, 0).
-define(REJECT_SALE, 1).
-define(RSN_OF_ALL, 0).
-define(RSN_OF_NEW, 1).

%% pay scan
-define(MAX_PAY_SCAN, 10000).
-define(PAY_SCAN_CODE_LEN, 18).
-define(PAY_SCAN_SUCCESS, 0).
-define(PAY_SCAN_FAILED, 1).
-define(PAY_SCAN_PAYING, 2).
-define(PAY_SCAN_REFUND, 3).
-define(PAY_SCAN_REFUND_SUCCESS, 4).
-define(PAY_SCAN_REFUND_FAILED, 5).
-define(PAY_SCAN_UNKOWN, 9).

%% transfer
-define(IN_ROAD, 0).
-define(IN_STOCK, 1).
-define(IN_BACK, 2).

%% inventory action
-define(NEW_INVENTORY, 0).
-define(REJECT_INVENTORY, 1).
-define(UPDATE_INVENTORY, 2).
-define(UPDATE_FIRM, 3).
-define(DELETE_INVENTORY, 4).
-define(TRANSFER_INVENTORY, 5).

%% retailer
-define(UPDATE_RETAILER, 0).
-define(DELETE_RECHARGE, 1).
-define(COMMON_RETAILER, 0).
-define(CHARGE_RETAILER, 1).
-define(SYSTEM_RETAILER, 2).

-define(FIRM_BILL, 9).
-define(INVALID_OR_EMPTY, -1).

-define(FIRM_PREFIX, 1000).
-define(ONE_DAY, (24 * 60 * 60)).
-define(SQL_TIME_OUT, 10 * 1000).

%% ticket
-define(SCORE_TICKET, 0). 
-define(CUSTOM_TICKET, 1).
-define(TICKET_BY_RETAILER, 0).
-define(TICKET_BY_BATCH, 1).
-define(TICKET_BY_SALE, 2).

-define(TICKET_CHECKED, 0). 
-define(TICKET_ALL, 1).

-define(TICKET_STATE_CONSUMED, 2).
-define(TICKET_STATE_CHECKED, 1).
-define(TICKET_STATE_CHECKING, 0).

-define(CUSTOM_TICKET_STATE_DISCARD, 0).
-define(CUSTOM_TICKET_STATE_UNUSED, 3).

-define(TICKET_DISCARD_ONE, 0).
-define(TICKET_DISCARD_ALL, 1).

%% bill mode
-define(CASH, 0).
-define(CARD, 1).
-define(WIRE, 2).

%% free size
-define(FREE_SIZE, 0).
%% free color
-define(FREE_COLOR, 0).

%% print
-define(COLUMN, 0).
-define(ROW, 1).
-define(START, 0).
-define(STOP, 1).
-define(TABLE, 1).
-define(STRING, 0).
-define(PRINT_FRONTE, 0).
-define(PRINT_BACKEND, 1).

-define(DEFAULT_ALARM_DAY, 7).
-define(DEFAULT_BASE_SETTING, -1).

%% shop mode
-define(CLOTHES_MODE, 1).
-define(CHILD_MODE, 2).
-define(HOME_MODE, 3).

%% merchant state
-define(MERCHANT_NORMAN, 0).
-define(MERCHANT_NO_MONEY, 1).

%% vip mode
-define(VIP_DEFAULT_MODE, <<"0000">>).

%% hide mode
-define(HIDE_DEFAULT_MODE, <<"000110111111011">>).

%% print mode
-define(PRINT_DEFAULT_MODE, <<"000">>).

%% sms
-define(SMS_NOTIFY, <<"000">>).

%% sort
-define(SORT_BY_ID, 0).
-define(SORT_BY_DATE, 1).

%% recharge
-define(RECHARGE, 0).
-define(WITHDRAW, 1).

%% charge type
-define(GIVING_CHARGE, 0).
-define(TIMES_CHARGE, 1).
-define(THEORETIC_CHARGE, 2).
-define(MONTH_UNLIMIT_CHARGE, 3).
-define(QUARTER_UNLIMIT_CHARGE, 4).
-define(YEAR_UNLIMIT_CHARGE, 5).
-define(HALF_YEAR_UNLIMIT_CHARGE, 6).
-define(BALANCE_LIMIT_CHARGE, 7).

%% sale mode
-define(GOOD_SALE, 0).
-define(BRAND_TYPE_SALE, 1).

%% Match Mode
-define(PY_MATCH, 0).
-define(CH_MATCH, 1).

%% special price
-define(SPRICE, 3).

%% bank card
-define(DEFAULT_BANK_CARD, -1).
-define(CARD_CASH_OUT, 0).
-define(CARD_CASH_IN, 1).

-define(TICKET_DATE_UNLIMIT, <<"0000-00-00">>).
-define(TICKET_EFFECT_NEVER, 9999).

%% pagination
-define(DEFAULT_ITEMS_PERPAGE, 5).

-define(INVALID_DATE, {0,0,0}).

-define(EMPTY_DB_BARCODE, <<"-1">>).
%% seconds begin 0 year, 0 month, 0 day to 1970.1.1
%% calendar:datetime_to_gregorian_seconds({{1970, 1, 1}, {0,0,0}}).
-define(SECONDS_BEFOR_1970, 62167219200).

%% session
-define(QZG_DY_SESSION, "qzg_dyty_session").

%% the order must not be changed, if want to add size, add it at end
-define(SIZE_TO_BARCODE,
	["FF",
	 "XS",  "S",   "M",   "L",   "XL",  "2XL",  "3XL", "4XL", "5XL", "6XL", "7XL",
	 "0",   "8",   "9",   "10",  "11",  "12",  "13",   "14",  "15",  "16",  "17",
	 "18",  "19",  "20",  "21",  "22",  "23",  "24",   "25",  "26",  "27",  "28",
	 "29",  "30",  "31",   "32",  "33",  "34",  "35",  "36",  "37",  "38",  "39",
	 "40",  "41",  "42",  "43",   "44",  "46",   "48",  "50",  "52",  "54", "56",
	 "58",  "80",  "90",  "100", "105", "110", "115",  "120", "125", "130", "135",
	 "140", "145", "150", "155", "160", "165", "170",  "175", "180", "185", "190",
	 "195", "200", "4",   "6",   "7",   "5",   "45",   "47",

	 "70A", "70B", "70C", "70D", "70E",
	 "75A", "75B", "75C", "75D", "75E",
	 "80A", "80B", "80C", "80D", "80E", "80F",
	 "85A", "85B", "85C", "85D", "85E", "85F",
	 "90A", "90B", "90C", "90D", "90E", "90F",
	 "95A", "95B", "95C", "95D", "95E", "95F",

	 "55", "60", "65", "70", "75", "85", "95", "73", "78", "66",  "51",
	 "62", "67", "79", "72", "84", "59", "53", "2",  "3",  "8XL", "9XL"
	 ]).

%% right module
-define(right_shop, 40000).
-define(right_employe, 50000).
-define(right_right, 60000).
-define(right_merchant, 80000).

%% about wholesale
-define(right_w_sale,      90000).
-define(right_w_inventory, 100000).
-define(right_w_firm,      110000).
-define(right_w_retailer,  30000). 
-define(right_w_print,     130000).
-define(right_w_good,      140000).
-define(right_w_report,    150000).
-define(right_b_sale,      160000).

%% rainbow
-define(right_rainbow, 800000).

%% base setting
-define(right_w_base, 900000).

%% retailer
-define(new_w_retailer,                        ?right_w_retailer + 1).
-define(del_w_retailer,                        ?right_w_retailer + 2).
-define(update_w_retailer,                     ?right_w_retailer + 3).
-define(list_w_retailer,                       ?right_w_retailer + 4).

-define(add_w_retailer_charge,       ?right_w_retailer + 5).
-define(update_w_retailer_charge,    ?right_w_retailer + 6).
-define(del_w_retailer_charge,       ?right_w_retailer + 7).
-define(list_w_retailer_charge,      ?right_w_retailer + 8).

-define(add_w_retailer_score,        ?right_w_retailer + 9).
-define(update_w_retailer_score,     ?right_w_retailer + 10).
-define(del_w_retailer_score,        ?right_w_retailer + 11).
-define(list_w_retailer_score,       ?right_w_retailer + 12).
-define(new_recharge,                ?right_w_retailer + 13).
-define(reset_w_retailer_password,   ?right_w_retailer + 14).
-define(delete_recharge,             ?right_w_retailer + 15).
-define(update_recharge,             ?right_w_retailer + 16).
-define(update_retailer_score,       ?right_w_retailer + 17).
%% ticket
-define(filter_ticket_detail,        ?right_w_retailer + 18).
-define(effect_ticket,               ?right_w_retailer + 19).
-define(consume_ticket,              ?right_w_retailer + 20).
-define(export_w_retailer,           ?right_w_retailer + 21).
-define(query_w_retailer_balance,    ?right_w_retailer + 22).
-define(update_w_retailer_phone,     ?right_w_retailer + 23).
-define(set_w_retailer_withdraw,     ?right_w_retailer + 24).
-define(make_ticket_batch,           ?right_w_retailer + 25).
-define(filter_custom_ticket_detail, ?right_w_retailer + 26).
-define(discard_custom_ticket,       ?right_w_retailer + 27).
%% threshold card
-define(add_threshold_card_good,     ?right_w_retailer + 28).
-define(update_threshold_card_good,  ?right_w_retailer + 29).
-define(delete_threshold_card_good,  ?right_w_retailer + 30).
-define(new_threshold_card_sale,     ?right_w_retailer + 31).

-define(add_retailer_level,          ?right_w_retailer + 32).
-define(update_retailer_level,       ?right_w_retailer + 33).
-define(syn_score_ticket,            ?right_w_retailer + 34).
-define(print_w_retailer,            ?right_w_retailer + 35).
-define(new_ticket_plan,             ?right_w_retailer + 36).
-define(update_ticket_plan,          ?right_w_retailer + 37).
-define(list_ticket_plan,            ?right_w_retailer + 38).
-define(page_w_retailer,             ?right_w_retailer + 39).
-define(gift_ticket,                 ?right_w_retailer + 40).
-define(delete_threshold_card_sale,  ?right_w_retailer + 41).
-define(delete_threshold_card,       ?right_w_retailer + 42).

%% shop
-define(new_shop,       ?right_shop + 1).
-define(del_shop,       ?right_shop + 2).
-define(update_shop,    ?right_shop + 3).
-define(list_shop,      ?right_shop + 4).
-define(new_repo,       ?right_shop + 5).
-define(del_repo,       ?right_shop + 6).
-define(update_repo,    ?right_shop + 7).
-define(list_repo,           ?right_shop + 8).
-define(new_badrepo,         ?right_shop + 9).
-define(del_badrepo,         ?right_shop + 10).
-define(update_badrepo,      ?right_shop + 11).
-define(list_badrepo,        ?right_shop + 12).
-define(add_shop_promotion,  ?right_shop + 13).
-define(new_region,          ?right_shop + 14).
-define(list_region,         ?right_shop + 15).
-define(update_shop_charge,  ?right_shop + 16).
-define(update_region,       ?right_shop + 17).
-define(new_cost_class,      ?right_shop + 18).
-define(update_cost_class,   ?right_shop + 19).
-define(list_cost_class,     ?right_shop + 20).

%% employ
-define(new_employe,     ?right_employe + 1).
-define(del_employe,     ?right_employe + 2).
-define(update_employe,  ?right_employe + 3).
-define(list_employe,    ?right_employe + 4).
-define(recover_employe, ?right_employe + 5).

-define(new_department,     ?right_employe + 6).
-define(update_department,  ?right_employe + 7).
-define(list_department,    ?right_employe + 8).
-define(del_department,     ?right_employe + 9).

-define(add_employee_of_department, ?right_employe + 10).
-define(del_employee_of_department, ?right_employe + 11).
-define(list_employee_of_department, ?right_employe + 12).

%% right
-define(new_role,       ?right_right + 1).
-define(del_role,       ?right_right + 2).
-define(update_role,    ?right_right + 3).
-define(list_role,      ?right_right + 4).
-define(new_account,    ?right_right + 5).
-define(del_account,    ?right_right + 6).
-define(update_account, ?right_right + 7).
-define(list_account,   ?right_right + 8).

%% merchant
-define(new_merchant,       ?right_merchant + 1).
-define(del_merchant,       ?right_merchant + 2).
-define(update_merchant,    ?right_merchant + 3).
-define(list_merchant,      ?right_merchant + 4).


%%
%% wholesale
%%

%% sale
-define(new_w_sale,         ?right_w_sale + 1).
-define(reject_w_sale,      ?right_w_sale + 2).
-define(list_reject_w_sale, ?right_w_sale + 3).
-define(print_w_sale,       ?right_w_sale + 4).
-define(update_w_sale,      ?right_w_sale + 5).
-define(check_w_sale,       ?right_w_sale + 6).
-define(list_w_sale,        ?right_w_sale + 7).
-define(delete_w_sale,      ?right_w_sale + 8).
-define(upload_w_sale,      ?right_w_sale + 9).
-define(update_w_sale_price,   ?right_w_sale + 10).
-define(employee_evaluation,   ?right_w_sale + 11).
-define(print_w_sale_note,     ?right_w_sale + 12).
-define(export_w_sale_note,    ?right_w_sale + 13).
-define(new_daily_cost,         ?right_w_sale + 14).
-define(delete_daily_cost,      ?right_w_sale + 15).
-define(update_daily_cost,      ?right_w_sale + 16).
-define(list_daily_cost,        ?right_w_sale + 17).
-define(export_w_sale_new,      ?right_w_sale + 18).

%% inventory
-define(new_w_inventory,             ?right_w_inventory + 4).
-define(del_w_inventory,             ?right_w_inventory + 5).
-define(update_w_inventory,          ?right_w_inventory + 6).
-define(update_w_inventory_price,    ?right_w_inventory + 7). 
-define(list_w_inventory,            ?right_w_inventory + 8).
-define(list_new_w_inventory,        ?right_w_inventory + 9).
-define(reject_w_inventory,          ?right_w_inventory + 10).
-define(fix_w_inventory,             ?right_w_inventory + 11).
-define(filter_fix_w_inventory,      ?right_w_inventory + 12).
-define(check_w_inventory,           ?right_w_inventory + 13).
-define(set_w_inventory_promotion,   ?right_w_inventory + 14).
-define(update_w_inventory_batch,    ?right_w_inventory + 15).

%% transfer
-define(transfer_w_inventory,            ?right_w_inventory + 16).
-define(filter_transfer_w_inventory,     ?right_w_inventory + 17).
-define(filter_transfer_rsn_w_inventory, ?right_w_inventory + 18).
-define(check_w_inventory_transfer,      ?right_w_inventory + 19).
-define(cancel_w_inventory_transfer,     ?right_w_inventory + 20).
-define(adjust_w_inventory_price,        ?right_w_inventory + 21).
-define(comment_w_inventory_new,         ?right_w_inventory + 22).
%% update original price when reject stock to firm
-define(update_price_of_w_inventory_reject, ?right_w_inventory + 23).
-define(modify_w_inventory_new_balance,     ?right_w_inventory + 24).
-define(update_w_inventory_alarm,           ?right_w_inventory + 25).
-define(reset_stock_barcode,                ?right_w_inventory + 26).
-define(print_w_inventory_new,              ?right_w_inventory + 27).
-define(print_w_inventory_transfer,         ?right_w_inventory + 28).
-define(print_w_barcode,                    ?right_w_inventory + 29).
-define(gift_w_stock,                       ?right_w_inventory + 30).
-define(print_w_inventory_new_note,         ?right_w_inventory + 31).

-define(update_tprice_on_stock_in,          ?right_w_inventory + 32).
-define(update_oprice_on_stock_in,          ?right_w_inventory + 33).
-define(bill_firm_on_stock_in,              ?right_w_inventory + 34).
-define(export_w_inventory_fix_note,        ?right_w_inventory + 35).
-define(offering_w_stock,                   ?right_w_inventory + 36).
-define(analysis_history_stock,             ?right_w_inventory + 37).




%% -define(set_stock_promotion,    ?right_w_inventory + 27).

%% firm
-define(new_w_firm,    ?right_w_firm + 1).
-define(del_w_firm,    ?right_w_firm + 2).
-define(update_w_firm, ?right_w_firm + 3).
-define(list_w_firm,   ?right_w_firm + 4).

-define(new_w_brand,   ?right_w_firm + 5).
-define(del_w_brand,   ?right_w_firm + 6).
-define(update_w_brand,?right_w_firm + 7).
-define(list_w_brand,  ?right_w_firm + 8).
-define(bill_w_firm,   ?right_w_firm + 9).
-define(update_bill_w_firm,   ?right_w_firm + 10).
-define(check_w_firm_bill,    ?right_w_firm + 11).
-define(abandon_w_firm_bill,  ?right_w_firm + 12).
-define(export_w_firm,        ?right_w_firm + 13).
-define(analysis_profit_w_firm, ?right_w_firm + 14).
-define(export_firm_profit,     ?right_w_firm + 15).
-define(new_virtual_firm,       ?right_w_firm + 16).
-define(list_virtual_firm,      ?right_w_firm + 17).
-define(update_virtual_firm,    ?right_w_firm + 18).


%% wprint
-define(new_w_print_server,  ?right_w_print + 1).
-define(del_w_print_server,  ?right_w_print + 2).
-define(list_w_print_server, ?right_w_print + 3).

-define(new_w_printer,    ?right_w_print + 4).
-define(del_w_printer,    ?right_w_print + 5).
-define(update_w_printer, ?right_w_print + 6).
-define(list_w_printer,   ?right_w_print + 7).

%% good
-define(new_w_good,           ?right_w_good + 1).
-define(del_w_good,           ?right_w_good + 2).
-define(update_w_good,        ?right_w_good + 3).
-define(list_w_good,          ?right_w_good + 4).

-define(new_w_size,     ?right_w_good + 5).
-define(del_w_size,     ?right_w_good + 6).
-define(update_w_size,  ?right_w_good + 7).

-define(new_w_color,    ?right_w_good + 8).
-define(del_w_color,    ?right_w_good + 9).
-define(update_w_color, ?right_w_good + 10).

-define(new_w_promotion,    ?right_w_good + 11).
-define(del_w_promotion,    ?right_w_good + 12).
-define(update_w_promotion, ?right_w_good + 13).
-define(list_w_promotion,   ?right_w_good + 14). 
-define(lookup_good_orgprice, ?right_w_good + 15).

-define(new_w_type,    ?right_w_good + 16).
-define(del_w_type,    ?right_w_good + 17).
-define(update_w_type, ?right_w_good + 18).
-define(reset_w_good_barcode, ?right_w_good + 19).

%% report
-define(daily_wreport,   ?right_w_report + 1).
-define(stock_stastic,   ?right_w_report + 2).
-define(h_daily_wreport, ?right_w_report + 3).
-define(switch_shift_report, ?right_w_report + 4).
-define(syn_daily_report, ?right_w_report + 5).
-define(h_month_wreport, ?right_w_report + 6).
-define(export_month_report, ?right_w_report + 7).


%% -----------------------------------------------------------------------------
%% rainbow
%% -----------------------------------------------------------------------------
%% -define(inventory_eifo_onreject,      ?right_rainbow + 1).
-define(wsale_modify_price_onsale,    ?right_rainbow + 2).
-define(wsale_modify_discount_onsale, ?right_rainbow + 3).
-define(stock_show_orgprice,          ?right_rainbow + 4).
-define(report_show_gross_profit,     ?right_rainbow + 5).
%% -define(sms_notify,                   ?right_rainbow + 5).

%% =============================================================================
%% base setting
%% =============================================================================
-define(new_w_bank_card,       ?right_w_base + 1). 
-define(del_w_bank_card,       ?right_w_base + 2). 
-define(update_w_bank_card,    ?right_w_base + 3).
-define(list_w_bank_card,      ?right_w_base + 4).
-define(new_w_printer_conn,    ?right_w_base + 5).
-define(del_w_printer_conn,    ?right_w_base + 6).
-define(update_w_printer_conn, ?right_w_base + 7).
-define(list_w_printer_conn,   ?right_w_base + 8).
-define(add_std_executive,     ?right_w_base + 9).
-define(add_safety_category,   ?right_w_base + 10).
-define(add_fabric,            ?right_w_base + 11).

-define(update_std_executive,     ?right_w_base + 12).
-define(update_safety_category,   ?right_w_base + 13).
-define(update_fabric,            ?right_w_base + 14).
-define(update_print_template,    ?right_w_base + 15).

-define(add_ctype,                ?right_w_base + 16).
-define(update_ctype,             ?right_w_base + 17).

-define(add_size_spec,            ?right_w_base + 18).
-define(update_size_spec,         ?right_w_base + 19).

%% ================================================================================
%% batch sale
%% ================================================================================
-define(new_batch_sale,              ?right_b_sale + 1).
-define(reject_batch_sale,           ?right_b_sale + 2).
-define(update_batch_sale,           ?right_b_sale + 3).
-define(list_batch_sale,             ?right_b_sale + 4).
-define(check_batch_sale,            ?right_b_sale + 5).
-define(del_batch_sale,              ?right_b_sale + 6).
-define(list_batch_sale_new_detail,  ?right_b_sale + 7).
-define(book_batch_sale,             ?right_b_sale + 8).

-define(new_batch_saler,      ?right_b_sale + 9).
-define(list_batch_saler,     ?right_b_sale + 10).
-define(del_batch_saler,      ?right_b_sale + 11).
-define(update_batch_saler,   ?right_b_sale + 12).
-define(bill_batch_saler,     ?right_b_sale + 13).

-define(print_batch_sale,     ?right_b_sale + 14).
-define(export_batch_sale,    ?right_b_sale + 15).

-define(new_batch_sale_prop,    ?right_b_sale + 16).
-define(list_batch_sale_prop,   ?right_b_sale + 17).
-define(update_batch_sale_prop, ?right_b_sale + 18).
-define(delete_batch_sale_prop, ?right_b_sale + 19).

%% public
-define(http_route, diablo_controller_http_route).
-define(mysql, diablo_controller_mysql).
-define(utils, diablo_controller_utils).
-define(menu, diablo_controller_menu).

-define(sql_utils, diablo_sql_utils).
-define(pagination, diablo_pagination).

%% login
-define(login_request, diablo_controller_login_request).
-define(login, diablo_controller_login).
-define(session, diablo_controller_session_manager).

%% sale
-define(sale_request, diablo_controller_sale_request).
-define(sale, diablo_controller_sale).

%% batch_sale
-define(b_sale_request, diablo_batch_sale_request).
-define(b_sale, diablo_batch_sale).
-define(b_saler, diablo_batch_saler).

%% shop
-define(shop_request, diablo_controller_shop_request).
-define(shop, diablo_controller_shop).

%% merchant
-define(merchant_request, diablo_controller_merchant_request).
-define(merchant, diablo_controller_merchant).

%% emmploy
-define(employ_request, diablo_controller_employ_request).
-define(employ, diablo_controller_employ).

%% retailer
-define(w_retailer_request, diablo_w_retailer_request).
-define(w_retailer, diablo_w_retailer).

%% inventory
%% -define(inventory_request, diablo_controller_inventory_request).
%% -define(inventory, diablo_controller_inventory).
-define(inventory_sn, diablo_controller_inventory_sn).

%% right
-define(right_init, diablo_controller_right_init).
-define(right_auth, diablo_controller_authen).
-define(tree, diablo_controller_tree).
-define(right_request, diablo_controller_right_request).
-define(right, diablo_controller_right).

%% about whole sale
-define(firm_request, diablo_firm_request).
-define(supplier, diablo_controller_supplier).

%% sale
-define(w_sale_request, diablo_w_sale_request).
-define(w_sale, diablo_w_sale).

%% inventory
-define(inventory_request, diablo_controller_inventory_request).
-define(w_inventory_request, diablo_purchaser_request).
-define(w_inventory, diablo_purchaser).

%% print
-define(w_print_request, diablo_w_print_request).
-define(w_print, diablo_w_print).
-define(wifi_print, diablo_http_print).
-define(f_print, diablo_format_print).

%% good
-define(w_good_request, diablo_w_good_request).
-define(w_good, diablo_w_good).
-define(w_good_sql, diablo_purchaser_sql).
-define(w_transfer_sql, diablo_purchaser_transfer).
-define(w_stock_match, diablo_purchaser_match).

%% report
-define(w_report_request, diablo_w_report_request).
-define(w_report, diablo_w_report).
-define(w_report_sql, diablo_w_report_sql).

%% base setting
-define(w_base_request, diablo_w_base_request).
-define(w_base, diablo_w_base).

%% base attribute
-define(attr, diablo_attribute).

%% promotion
-define(promotion, diablo_w_promotion).

%% profile
-define(w_user_profile, diablo_wuser_profile).

%% report
-define(gen_report, diablo_auto_gen_report).

%% cron
-define(cron_agent, diablo_cron_agent).
-define(cron_control, diablo_cron_control).
-define(cron_job_regist, diablo_cron_job_register).
-define(cron, diablo_cron).

%% pool
-define(wpool, diablo_work_pool_sup).

%% sms notify
-define(notify, diablo_sms_notify).

-define(value(Key, Proplists),
	diablo_controller_utils:value_from_proplists(Key, Proplists)).
-define(value(Key, Proplists, Default),
	proplists:get_value(Key, Proplists, Default)).
-define(v(K, L), ?value(K, L)).
-define(v(K, L, D), ?value(K, L, D)).

-define(split_url(S),  erlang:list_to_tuple(string:tokens(S, "/"))).

-define(err(Err, Key), diablo_controller_error:error(Err, Key)).
-define(succ(Action, Key), diablo_controller_error:success(Action, Key)). 

-define(SESSION, tbl_session).
-record(session, {
	  id          = <<>>       :: binary(),
	  user_id     = -1         :: integer(), 
	  user_name   = <<>>       :: binary(),  
	  user_type   = -1         :: integer(),
	  merchant    = -1         :: integer(),
	  retailer_id = -1         :: integer(),
	  employee_id = <<>>       :: binary(),
	  shop_id     = -1         :: integer(),
	  mtype       = -1         :: integer(),
	  sdays       = 0          :: integer(),
	  tablet      = 0          :: integer(),
	  login_time  = undefined  :: string()   
	 }).

-define(WSALE_DRAFT, tbl_wsale_draft).
-record(wsale_draft, {
	  merchant   = -1 :: integer(),
	  shop       = -1 :: integer(),
	  employee   = -1 :: integer(),
	  attrs      = [] :: list(),
	  invs       = [] :: list()
	 }).

-define(WFIX_DRAFT, tbl_wsale_draft).
-record(wfix_draft, {
	  merchant   = -1 :: integer(),
	  shop       = -1 :: integer(),
	  employee   = -1 :: integer(),
	  attrs      = [] :: list(),
	  invs       = [] :: list()
	 }).

-define(WUSER_PROFILE, tbl_wuser_profile).
-record(wuser_profile, {
	  merchant    = -1 :: integer(), 
	  info        = [] :: list(),
	  shop        = [] :: list(), %% all shop of merchant
	  repo        = [] :: list(), %% all repository of merchant
	  region      = [] :: list(),
	  print       = [] :: list(),
	  pformat     = [] :: list(),
	  %% bank        = [] :: list(), %% all bank of merchant
	  setting     = [] :: list(),
	  size_groups = [] :: list(),
	  itype       = [] :: list(), %% type of inventory
	  brand       = [] :: list(), %% brand of inventory
	  employee    = [] :: list(), %% all employee of merchant
	  sysretailer = [] :: list(), %% all retailer
	  firm        = [] :: list(), %% all firms of merchant
	  color_type  = [] :: list(),
	  color       = [] :: list(), 
	  good        = [] :: list(),
	  promotion   = [] :: list(),
	  charge      = [] :: list(),
	  score       = [] :: list(),
	  sms_rate    = [] :: list(),
	  sms_center  = [] :: list(),
	  level       = [] :: list(),
	  ticket_plan = [] :: list(),
	  department  = [] :: list(),
	  sysbsaler   = [] :: list()
	  %% login_right = [] :: list(),
	  %% login_shop  = [] :: list()
	 }).

-define(WUSER_SESSION_PROFILE, tbl_wuser_session_profile).
-record(wuser_session_profile, {
	  merchant = -1 :: integer(),
	  user     = -1 :: integer(),
	  %% userId   = -1 :: integer(),
	  type     = -1 :: integer(),
	  right = [] :: list(),
	  shop  = [] :: list(),
	  nav   = [] :: list()
	  %% color_type  = [] :: list() 
	 }).


-record(diablo_node,
       {
	 id       = -1  :: integer(),
	 name           :: string(),
	 action   = ""  :: string(),
	 parent   = -1  :: integer(),
	 children = []
       }).
-type tree() :: #diablo_node{}.


