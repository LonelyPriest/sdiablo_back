
-module(diablo_controller_error).

-include("../../../../include/knife.hrl").

-compile(export_all).

%% member
success(add_member, Mobile) ->
    {0, "Success to create a member with member " ++ ?to_s(Mobile)};
success(delete_member, Number) ->
    {0, "Success to delete a member with member " ++ ?to_s(Number)};
success(update_member, Number) ->
    {0, "Success to update member with member " ++ ?to_s(Number)};
success(score_to_money, Number) ->
    {0, "Success to consumed score with member " ++ ?to_s(Number)};

%% merchant
success(add_merchant, Name) ->
    {0, "Success to create a merchant " ++ ?to_s(Name)};
success(delete_merchant, Id) ->
    {0, "Success to delete the merchant " ++ ?to_s(Id)};
success(update_merchant, Id) ->
    {0, "Success to update the merchant " ++ ?to_s(Id)};
success(new_sms_rate, Merchant) ->
    {0, "Success to add sms of merchant " ++ ?to_s(Merchant)};
success(charge_sms, Merchant) ->
    {0, "Success to charge sms of merchant " ++ ?to_s(Merchant)};


%% employ
success(add_employ, Name) ->
    {0, "Success to create a employ " ++ ?to_s(Name)};
success(update_employ, Id) ->
    {0, "Success to update the employ " ++ ?to_s(Id)};
success(delete_employ, Id) ->
    {0, "Success to delete the employ " ++ ?to_s(Id)};


%% shop
success(add_shop, Name) ->
    {0, "Success to create a shop " ++ ?to_s(Name)};
success(update_shop, Id) ->
    {0, "Success to update the shop with id  " ++ ?to_s(Id)};
success(delete_shop, Id) ->
    {0, "Success to delete the shop with id " ++ ?to_s(Id)};
success(add_repo, Id) ->
    {0, "Success to create a repertory " ++ ?to_s(Id)};
success(add_shop_promotion, Id) ->
    {0, "Success to add the promotion of shop " ++ ?to_s(Id)};

%% right
success(add_account, Name) ->
    {0, "Success to create a account " ++ ?to_s(Name)};
success(delete_account, Account) ->
    {0, "Success to delete the account " ++ ?to_s(Account)};
success(update_account_role, Role) ->
    {0, "Success to update account's role with new role " ++ ?to_s(Role)};
success(add_role, Name) ->
    {0, "Success to create a role " ++ ?to_s(Name)};
success(update_role, RoleId) ->
    {0, "Success to update the role " ++ ?to_s(RoleId)};

%% supplier
success(add_supplier, Name) ->
    {0, "Success to create a supplier " ++ ?to_s(Name)};
success(update_supplier, Id) ->
    {0, "Success to update the supplier with id  " ++ ?to_s(Id)};
success(delete_supplier, Id) ->
    {0, "Success to delete the supplier with id " ++ ?to_s(Id)};
success(add_brand, Name) ->
    {0, "Success to create the brand " ++ ?to_s(Name)};
success(update_brand, Name) ->
    {0, "Success to update the brand " ++ ?to_s(Name)};
success(bill_firm, FirmId) ->
    {0, "Success to bill of firm " ++ ?to_s(FirmId)};
success(bill_check, RSN) ->
    {0, "Success to check bill of rsn " ++ ?to_s(RSN)};
success(bill_abandon, RSN) ->
    {0, "Success to abandon bill of rsn " ++ ?to_s(RSN)};
success(update_bill_check, RSN) ->
    {0, "Success to update bill detail with rsn " ++ ?to_s(RSN)};


%% inventory
success(add_inventory, Number) ->
    {0, "Success to create a inventory " ++ ?to_s(Number)};
success(update_inventory, Id) ->
    {0, "Success to update the inventory with id  " ++ ?to_s(Id)};
success(delete_inventory, Id) ->
    {0, "Success to delete the inventory with id " ++ ?to_s(Id)};
success(add_size_group, _) ->
    {0, "Success to add size group"};
success(add_color, Name) ->
    {0, "Success to add color of name " ++ ?to_s(Name)};
success(update_color, ColorId) ->
    {0, "Success to update color: " ++ ?to_s(ColorId)};
success(update_size_group, GroupId) ->
    {0, "Success to update size group [" ++ ?to_s(GroupId) ++ "]"};
success(delete_size_group, GroupId) ->
    {0, "Success to delete size group [" ++ ?to_s(GroupId) ++ "]"};
success(check_inventory, User) ->
    {0, "Success to check inventory with user " ++ ?to_s(User)};
success(pre_move_inventory, Sn) ->
    {0, "Success to pre move inventory with SN " ++ ?to_s(Sn)};
success(do_move_inventory, Sn) ->
    {0, "Success to do move inventory with SN " ++ ?to_s(Sn)};
success(do_reject_inventory, Sn) ->
    {0, "Success to do reject inventory with SN " ++ ?to_s(Sn)};
success(adjust_price, Inventory) ->
    {0, "Success to adjust price of inventory " ++ ?to_s(Inventory)};

%% sale
success(sale, Extra) ->
    {0, "Success to payment with extra: " ++ ?to_s(Extra)};
success(reject, RunningNo) ->
    {0, "Success to reject with running number: " ++ ?to_s(RunningNo)};

%% login
success(login, User) ->
    {0, "Success to login with user " ++ ?to_s(User)}; 
success(destroy_login_user, User) ->
    {0, "Success to destroy login user " ++ ?to_s(User)};

%%
%% about wholesale
%%
%% inventnory
success(add_purchaser_good, Number) ->
    {0, "Success to add purchaser good with style number " ++ ?to_s(Number)};
success(delete_purchaser_good, GoodId) ->
    {0, "Success to delete purchaser good " ++ ?to_s(GoodId)};
success(update_purchaser_good, Good) ->
    {0, "Success to update purchser good with good id " ++ ?to_s(Good)};
success(add_purchaser_inventory, RSN) ->
    {0, "Success to add purchaser inventory with rsn " ++ ?to_s(RSN)};
success(update_w_inventory, RSN) ->
    {0, "Success to update purchaser inventory with rsn " ++ ?to_s(RSN)};
success(check_w_inventory, RSN) ->
    {0, "Success to check purchaser inventory with rsn " ++ ?to_s(RSN)};
success(check_w_inventory_transfer, RSN) ->
    {0, "Success to check transfer inventory with rsn " ++ ?to_s(RSN)};
success(cancel_w_inventory_transfer, RSN) ->
    {0, "Success to cancel transfer inventory with rsn " ++ ?to_s(RSN)};
success(reject_w_inventory, Total) ->
    {0, "Success to reject purchaser inventory of total amount "
     ++ ?to_s(Total)};
success(fix_w_inventory, Rsn) ->
    {0, "Success to fix inventory with record no  " ++ ?to_s(Rsn)};
success(delete_w_inventory, Rsn) ->
    {0, "Success to delete inventory with record no  " ++ ?to_s(Rsn)};
success(set_w_inventory_promotion, Merchant) ->
    {0, "Success to set promotion of merchant  " ++ ?to_s(Merchant)};
success(update_w_inventory_batch, Merchant) ->
    {0, "Success to update inventory of merchant  " ++ ?to_s(Merchant)};
success(transfer_w_inventory, Rsn) ->    
    {0, "Success to transfer inventory with rsn  " ++ ?to_s(Rsn)};
success(adjust_w_inventory_price, Merchant) ->
    {0, "Success to adjust price of merchant  " ++ ?to_s(Merchant)};
success(syn_w_inventory_barcode, Barcode) ->
    {0, "Success to syn barcode:  " ++ ?to_s(Barcode)};


%% promotion
success(new_promotion, Promotion) ->
    {0, "Success to add promotion " ++ ?to_s(Promotion)};
success(update_promotion, Promotion) ->
    {0, "Success to update promotion " ++ ?to_s(Promotion)};

%% retailer
success(add_w_retailer, Retailer) ->
    {0, "Success to add retailer " ++ ?to_s(Retailer)};
success(update_w_retailer, Retailer) ->
    {0, "Success to update retailer " ++ ?to_s(Retailer)};
success(delete_w_retailer, Retailer) ->
    {0, "Success to delete retailer " ++ ?to_s(Retailer)};
success(check_w_retailer_password, Retailer) ->
    {0, "Success to check password of retailer " ++ ?to_s(Retailer)};
success(reset_w_retailer_password, Retailer) ->
    {0, "Success to reset password of retailer " ++ ?to_s(Retailer)};
success(add_retailer_charge, Charge) ->
    {0, "Success to add the chare promotion "++?to_s(Charge)++" of retailer."};
success(delete_retailer_charge, Charge) ->
    {0, "Success to delete the chare promotion "++?to_s(Charge)++" of retailer."};
success(add_retailer_score, Score) ->
    {0, "Success to add the score promotion "++?to_s(Score)++" of retailer."};
success(new_recharge, SN) ->
    {0, "Success to recharge of sn "++?to_s(SN)++"."};
success(delete_recharge, Charge) ->
    {0, "Success to delete recharge of charge "++?to_s(Charge)++"."};
success(update_recharge, Charge) ->
    {0, "Success to update recharge of charge "++?to_s(Charge)++"."};
success(effect_ticket, TicketId) ->
    {0, "Success to effect ticket: "++?to_s(TicketId)++"."};
success(consume_ticket, TicketId) ->
    {0, "Success to consume ticket: "++?to_s(TicketId)++"."};
success(syn_retailer_pinyin, Merchant) ->
    {0, "Success to syn retailer's pinyin of merchant: "++?to_s(Merchant)++"."};
success(set_retailer_withdraw, Merchant) ->
    {0, "Success to set the withdraw of merchant: "++?to_s(Merchant)++"."};
success(discard_ticket_one, TicketId) ->
    {0, "Success to discard ticket: "++?to_s(TicketId)++"."};
success(discard_ticket_all, Merchant) ->
    {0, "Success to discard all ticket of merchant: "++?to_s(Merchant)++"."};
success(charge_check_region, Region) ->
    {0, "Success to check region: "++?to_s(Region)++"."};
success(new_threshold_card_sale, Card) ->
    {0, "Success to threshold card sale: "++?to_s(Card)++"."};
success(add_threshold_card_good, Good) ->
    {0, "Success to add threshold card good:" ++ ?to_s(Good)};
success(syn_score_ticket, Merchant) ->
    {0, "Success syn ticket of merchant:" ++ ?to_s(Merchant)};
success(new_ticket_plan, Plan) ->
    {0, "Success to add a new ticket plan:" ++ ?to_s(Plan)};
success(add_retailer_gift, Gift) ->
    {0, "Success to add a new gift:" ++ ?to_s(Gift)};

%% wsale
success(new_w_sale, RSn) ->
    {0, "Success to new sale of rsn " ++ ?to_s(RSn)};
success(update_w_sale, RSn) ->
    {0, "Success to update sale of rsn " ++ ?to_s(RSn)};
success(check_w_sale, RSn) ->
    {0, "Success to check sale of rsn " ++ ?to_s(RSn)};
success(print_w_sale, RSn) ->
    {0, "Success to print sale with rsn " ++ ?to_s(RSn)};
success(new_w_sale_draft, Sn) ->
    {0, "Success to new sale draft of rsn " ++ ?to_s(Sn)};
success(get_w_sale_draft, Sn) ->
    {0, "Success to get draft " ++ ?to_s(Sn)};
success(reject_w_sale, RSn) ->
    {0, "Success to reject of rsn " ++ ?to_s(RSn)};
success(w_sale_uploaded, Shop) ->
    {0, "Success to upload wsale of shop " ++ ?to_s(Shop)};
success(pay_scan, Merchant) ->
    {0, "Success to pay scan " ++ ?to_s(Merchant)};
success(check_pay_scan, PayOrderNo) ->
    {0, "Success to check pay scan " ++ ?to_s(PayOrderNo)};

%% wprint
success(new_wprint_server, Server) ->
    {0, "Success to new print server " ++ ?to_s(Server)};
success(new_wprinter, PId) ->
    {0, "Success to new printer " ++ ?to_s(PId)};
success(update_wprinter, PId) ->
    {0, "Success to update printer " ++ ?to_s(PId)};
success(delete_wprinter, PId) ->
    {0, "Success to delete printer " ++ ?to_s(PId)};
success(new_wprinter_conn, CId) ->
    {0, "Success to connect the printer with connection" ++ ?to_s(CId)};
success(update_wprinter_conn, CId) ->
    {0, "Success to update the printer with connection  " ++ ?to_s(CId)};
success(delete_wprinter_conn, CId) ->
    {0, "Success to delete printer with connection" ++ ?to_s(CId)};
success(update_wprinter_format, FId) ->
    {0, "Success to update print format of " ++ ?to_s(FId)};
success(add_wprinter_format_to_shop, Shop) ->
    {0, "Success to add wprint format of shop " ++ ?to_s(Shop)};
success(print_wreport, Shop) ->
    {0, "Success to add print content of shop " ++ ?to_s(Shop)};
success(syn_daily_report, Merchant) ->
    {0, "Success to syn daily report or merchant ~p " ++ ?to_s(Merchant)};



%% base
success(base_new_card, CardNo) ->
    {0, "Success to new bank card " ++ ?to_s(CardNo)};
success(base_delete_card, CardId) ->
    {0, "Success to delete bank card " ++ ?to_s(CardId)};
success(base_update_card, CardNo) ->
    {0, "Success to update bank card " ++ ?to_s(CardNo)};
success(base_add_setting, Name) ->
    {0, "Success to add base setting of  " ++ ?to_s(Name)};
success(base_update_setting, Name) ->
    {0, "Success to update base setting of  " ++ ?to_s(Name)};
success(base_add_shop_setting, Shop) ->
    {0, "Success to add settings of shop " ++ ?to_s(Shop)};
success(base_delete_shop_setting, Shop) ->
    {0, "Success to delete settings of shop " ++ ?to_s(Shop)};
success(base_update_passwd, Account) ->
    {0, "Success to update password of user " ++ ?to_s(Account)}; 
success(good_update_std_executive, EId) ->
    {0, "Success to update executive standard " ++ ?to_s(EId)};
success(good_update_ctype, CId) ->
    {0, "Success to update ctype " ++ ?to_s(CId)};
success(create_print_template, Merchant) ->
    {0, "Success to create print template of merchant " ++ ?to_s(Merchant)};

%% batch
success(new_batch_saler, Id) ->
    {0, "Success to create a batch saler" ++ ?to_s(Id)}.

%% -----------------------------------------------------------------------------
%% error define
%% -----------------------------------------------------------------------------
%% members
error(number_exist, Number) ->
    {1001, "Member " ++ ?to_s(Number) ++ " has been exists."};
error(member_exist, Mobile) ->
    {1002, "Member " ++ ?to_s(Mobile) ++ " has been exists."};
error(member_not_exist, Number) ->
    {1003, "Member " ++ ?to_s(Number) ++ " does not exists."};
error(not_enough_score, Number) ->
    {1004, "Member " ++ ?to_s(Number) ++ " has not enough score."};
error(action_not_support, Action) ->
    {1004, "Action " ++ ?to_s(Action) ++ " does not supported now."};

%% login
error(login_error, _nouse) ->
    {1101, "User or password is invalid, please check."};
error(login_invalid_session, _nouse) ->
    {1102, "invalid session."}; 
error(login_no_user, _) ->
    {1103, "User name must be input."};
error(login_no_password, _) ->
    {1104, "User password must be input."};
error(login_user_active, User) ->
    {1105, "user " ++ ?to_s(User) ++ "has been logined and actitived."};
error(login_exceed_user, Merchant) ->
    {1106, "exceed the max user of merchant " ++ ?to_s(Merchant) ++ "."};
error(login_no_user_fire, Merchant) ->
    {1107, "there is no user can be fired of merchant " ++ ?to_s(Merchant) ++ "."};
error(login_invalid_user, User) ->
    {1108, "invalid user " ++ ?to_s(User) ++ "."};

%% merchant
error(merchant_exist, Name) ->
    {1201, "Merchant " ++ ?to_s(Name) ++ " has been exist."};
error(account_of_merchant_not_empty, Merchant) ->
    {1202, "Account of Merchant " ++ ?to_s(Merchant) ++ " is not empty."};
error(sms_rate_exist, Merchant) ->
    {1203, "sms rate of Merchant " ++ ?to_s(Merchant) ++ " has been exist."};
error(sms_rate_not_exist, Merchant) ->
    {1204, "sms rate does not exist " ++ ?to_s(Merchant) ++ "."};
error(sms_sign_same, Merchant) ->
    {1205, "same sms sign with merchant:" ++ ?to_s(Merchant) ++ "."};

%% shop
error(shop_exist, Name) ->
    {1301, "shop " ++ ?to_s(Name) ++ " has been exist."};
error(repo_exist, Name) ->
    {1302, "repo " ++ ?to_s(Name) ++ " has been exist."};
error(region_exist, Name) ->
    {1303, "region " ++ ?to_s(Name) ++ " has been exist."};
error(cost_class_exist, Name) ->
    {1304, "cost class " ++ ?to_s(Name) ++ " has been exist."};
error(cost_zero_balance, CostClass) ->
    {1305, "balance of cost less then zero: " ++ ?to_s(CostClass) ++ "."};
error(shop_with_stocks, ShopId) ->
    {1306, "stocks in shops: " ++ ?to_s(ShopId) ++ "."};

%% employ
error(employ_exist, Name) ->
    {1401, "employ " ++ ?to_s(Name) ++ " has been exist."};
error(department_exist, Name) ->
    {1402, "department " ++ ?to_s(Name) ++ " has been exist."};
error(department_employee_added, Employee) ->
    {1403, "the employee " ++ ?to_s(Employee) ++ " has been added."};


%% right
error(right_type_not_support, _nouse) ->
    {1501, "right type does not supported now."};
error(account_exist, Name) ->
    {1502, "account " ++ ?to_s(Name) ++ " has been exist."};
error(merchant_account_exist, Merchant) ->
    {1503, "account of merchant " ++ ?to_s(Merchant) ++ " has been exist."};
error(role_exist, Name) ->
    {1504, "role " ++ ?to_s(Name) ++ " has been exist."};
error(function_not_found, Name) ->
    {1505, "function " ++ ?to_s(Name) ++ " does not found."};
error(user_not_found, User) ->
    {1506, "user " ++ ?to_s(User) ++ " does not found."};
error(max_account, Merchant) ->
    {1507, "beyond the limit that merchant " ++ ?to_s(Merchant) ++ " was permited."};
error(role_empty_shop, Merchant) ->
    {1507, "shop of" ++ ?to_s(Merchant) ++ "must be created before create role."};

%% supplier
error(supplier_exist, Name) ->
    {1601, "supplier " ++ ?to_s(Name) ++ " has been exist."};
error(supplier_bill_not_exist, RSN) ->
    {1602, "bill " ++ ?to_s(RSN) ++ " of supplier is not exist."};
error(supplier_bill_discard, RSN) ->
    {1603, "bill " ++ ?to_s(RSN) ++ " of supplier has been discarded."};
error(bill_at_same_time, Firm) ->
    {1604, "bill of firm " ++ ?to_s(Firm) ++ " at same time."};
error(firm_retalted_stock, Firm) ->
    {1605, "firm retailed stock:" ++ ?to_s(Firm)};
error(brand_used, BrandId) ->
    {1606, "brand using:" ++ ?to_s(BrandId)};



%% inventory
error(inventory_exist, Name) ->
    {1703, "supplier " ++ ?to_s(Name) ++ " has been exist."};
error(brand_exist, Name) ->
    {1704, "brand " ++ ?to_s(Name) ++ " has been exist."};
error(move_invalid_inventory, Sn) ->
    {1705, "move invalid inventory with sn " ++ ?to_s(Sn) ++ "."};
error(move_inventory_moved, Sn) ->
    {1706, "inventory with sn " ++ ?to_s(Sn) ++ " had been moved."};
error(inventory_empty, Sn) ->
    {1707, "empty inventory with sn" ++ ?to_s(Sn) ++ "."};
error(inventory_not_enough, Sn) ->
    {1708, "not enought inventory with sn" ++ ?to_s(Sn) ++ "."};

%% sale
error(failed_to_payment, Error) ->
    {1802, "failed to payment with error " ++ ?to_s(Error)};
error(failed_to_record, Error) ->
    {1803, "failed to record sale with error " ++ ?to_s(Error)};
error(failed_to_add_score, Error) ->
    {1804, "failed to add the score of member with error " ++ ?to_s(Error)};
error(failed_to_check_amount, Sn) ->
    {1805, "inventory " ++ ?to_s(Sn) ++ " not enought."};

%% attribute
error(color_exist, Color) ->
    {1901, "color " ++ ?to_s(Color) ++ " has been existed."};
error(size_group_exist, Group) ->
    {1902, "size group " ++ ?to_s(Group) ++ " has been existed."};
error(size_group_invalid_name, GName) ->
    {1903, "size group has invalid size name:" ++ GName};
error(color_bcode_not_allowed, Merchant) ->
    {1904, "barcode of color not allowed:" ++ ?to_s(Merchant)};
error(color_bcode_exist, BCode) ->
    {1905, "barcode of color has been exist:" ++ ?to_s(BCode)};
error(type_bcode_not_allowed, Merchant) ->
    {1906, "barcode of type not allowed:" ++ ?to_s(Merchant)};
error(type_bcode_exist, BCode) ->
    {1907, "barcode of type has been exist:" ++ ?to_s(BCode)}; 
error(good_type_exist, TypeId) ->
    {1908, "type " ++ ?to_s(TypeId) ++ " has been existed."};
error(self_bcode_not_allowed, Merchant) ->
    {1909, ?to_s(Merchant) ++ "costome barcode can not be allowed while not in self barcode mode"};
error(good_barcode_exist, BCode) ->
    {1910, "barcode of this good has been exist:" ++ ?to_s(BCode)};
error(type_bcode_not_init, TypeId) ->
    {1911, "barcode of type not initial:" ++ ?to_s(TypeId)};
error(color_max_999, Total) ->
    {1912, "more then max count of color:" ++ ?to_s(Total)};




%%
%% about wholesale
%%

%% purchaser
error(purchaser_good_exist, Number) ->
    {2001, "purchaser good of number " ++ ?to_s(Number) ++ " does exist."};
error(promotion_exist, Promotion) ->
    {2002, "promotion " ++ ?to_s(Promotion) ++ " is been exist."};
error(failed_to_get_stock_new, RSN) ->
    {2003, "failed to get new stock of rsn " ++ ?to_s(RSN)};
error(stock_been_discard, RSN) ->
    {2004, "stock of rsn " ++ ?to_s(RSN) ++ " has been discard."}; 
error(error_state_of_check, RSN) ->
    {2005, "error_state_of_check " ++ ?to_s(RSN) ++ "."};
error(stock_been_checked, RSN) ->
    {2006, "stock of rsn " ++ ?to_s(RSN) ++ " has been checked."};
error(stock_been_canceled, RSN) ->
    {2007, "stock of rsn " ++ ?to_s(RSN) ++ " has been canceled."};
error(invalid_balance, Firm) ->
    {2008, "invalid balance of firm " ++ ?to_s(Firm)};
error(zero_price_of_check, RSN) ->
    {2009, "zero price of check " ++ ?to_s(RSN) ++ "."};
error(stock_invalid_date, Action) ->
    {2010, "invalid date of action: " ++ ?to_s(Action) ++ "."};
error(stock_invalid_inv, StyleNumber) ->
    {2011, "invalid stock of style_number: " ++ ?to_s(StyleNumber) ++ "."};
error(stock_invalid_total, CalcTotal) ->
    {2012, "invalid total of stock: " ++ ?to_s(CalcTotal) ++ "."};
error(empty_firm_of_check, RSN) ->
    {2013, "empty firm of rsn " ++ ?to_s(RSN) ++ "."};
error(stock_not_exist, StyleNumber) ->
    {2014, "stock not exist " ++ ?to_s(StyleNumber) ++ "."};
error(stock_same_barcode, Barcode) ->
    {2015, "same barcode of stock " ++ ?to_s(Barcode) ++ "."};
error(stock_invalid_barcode, Barcode) ->
    {2016, "invalid barcode of stock " ++ ?to_s(Barcode) ++ "."};
error(stock_barcode_not_init, StyleNumber) ->
    {2017, "barcode of stock " ++ ?to_s(StyleNumber) ++ " not initial."};
error(purchaser_good_non, _GoodId) ->
    {2018, "good information does not exit."};
error(purchaser_diff_time_with_empty_firm, Datetime) ->
    {2019, "empty firm but datetime has been changed:" ++ ?to_s(Datetime)};
error(purchaser_good_in_used, StyleNumber) ->
    {2020, "the good is used:" ++ ?to_s(StyleNumber)};
error(not_enought_stock, Stocks) ->
    {2021, "not enought stock:" ++ ?to_s(Stocks)};
error(stock_diff_detail_and_note, Shop) ->
    {2022, "stock detail not equal stock note:" ++ ?to_s(Shop)};



%% retailer
error(retailer_exist, Retailer) ->
    {2101, "retailer " ++ ?to_s(Retailer) ++ " does exist."};
error(retailer_invalid_password, Retailer) ->
    {2102, "invalid password of retailer " ++ ?to_s(Retailer) ++ "."};
error(retailer_charge_exist, Charge) ->
    {2103, "retailer of charge promotion " ++ ?to_s(Charge) ++ " does exist."};
error(retailer_score_exist, Score) ->
    {2104, "retailer of score promotion " ++ ?to_s(Score) ++ " does exist."};
error(ticket_not_exist, TicketId)->
    {2105, "tickiet " ++ ?to_s(TicketId) ++ " does exist."};
error(ticket_has_been_effect, TicketId) ->
    {2106, "tickiet " ++ ?to_s(TicketId) ++ " has been effected."};
error(ticket_has_been_consume, TicketId) ->
    {2107, "tickiet " ++ ?to_s(TicketId) ++ " has been consumed."};
error(retailer_score2money_exist, Score) ->
    {2108, "retailer of score promotion " ++ ?to_s(Score) ++ " does exist."};
error(invalid_charge_id, ChargeId) ->
    {2109, "invalid charge: " ++ ?to_s(ChargeId) ++ "."};
error(charge_has_been_used, ChargeId) ->
    {2110, "this charge " ++ ?to_s(ChargeId) ++ " has been used."};
error(wretailer_export_none, Merchant) ->
    {2111, "no date to export of merchant: " ++ ?to_s(Merchant)};
error(wretailer_export_error, Error) ->
    {2112, "failed to export file: " ++ ?to_s(Error)};
error(wretailer_retalted_sale, RetailerId) ->
    {2113, "some sales retailed on the retailer: " ++ ?to_s(RetailerId)};
error(wretailer_card_exist, Card) ->
    {2114, "retailer card has been used: " ++ ?to_s(Card)};
error(make_ticket_invalid_count, Count) ->
    {2115, "count can not be more than 1000: " ++ ?to_s(Count)};
error(make_ticket_invalid_balance, Balance) ->
    {2116, "balance can not be more than 500:" ++ ?to_s(Balance)};
error(make_ticket_batch_used, Batch) ->
    {2117, "batch number " ++ ?to_s(Batch) ++ " has been used"};
error(ticket_batch_length_error, Batch) ->
    {2118, "ticket batch is too long: " ++ ?to_s(Batch)};
error(charge_none, RetailerId) ->
    {2119, "never recharge of the retailer: " ++ ?to_s(RetailerId)};
error(charge_none_shop, ChargeShopId) ->
    {2120, "shop does not exist of recharging: " ++ ?to_s(ChargeShopId)};
error(charge_diff_region, Region) ->
    {2121, "different region of recharging: " ++ ?to_s(Region)};
error(charge_no_promotion, ChargeId) ->
    {2122, "can not find charge promotion of charge: " ++ ?to_s(ChargeId)};
error(threshold_card_not_exist, RetailerId) ->
    {2123, "can not find the threshold card of ther retailer: " ++ ?to_s(RetailerId)};
error(threshold_card_not_enought_count, RetailerId) ->
    {2124, "not enought count of the threshold card: " ++ ?to_s(RetailerId)};
error(threshold_card_expired, RetailerId) ->
    {2125, "threshold card expired: " ++ ?to_s(RetailerId)};
error(threshold_card_good_exist, Good) ->
    {2126, "threshold card good exist: " ++ ?to_s(Good)};
error(invalid_threshold_card_rule, Card) ->
    {2127, "invalid threshold card rule: " ++ ?to_s(Card)};
error(invalid_recharge, RechargeId) ->
    {2128, "can not find retailer's recharge:" ++ ?to_s(RechargeId)};
error(retailer_level_exist, Level) ->
    {2129, "the level of retailer exist:" ++ ?to_s(Level)};
error(retailer_level_not_exist, Level) ->
    {2130, "the level of retailer not exist:" ++ ?to_s(Level)};
error(ticket_plan_exist, Name) ->
    {2131, "ticket plan has been exist:" ++ ?to_s(Name)};
error(threshold_card_non_zero, Card) ->
    {2132, "threshold card's count is no zero:" ++ ?to_s(Card)};
error(threshold_card_non_expire, Card) ->
    {2133, "threshold card is in valid date:" ++ ?to_s(Card)};
error(balance_card_not_enought_money, Card) ->
    {2134, "balance limit card does not enought money:" ++ ?to_s(Card)};
error(balance_card_expire, Card) ->
    {2135, "balance limit card is in valid date:" ++ ?to_s(Card)};
error(invalid_ticket_state, State) ->
    {2136, "invalid ticket state:" ++ ?to_s(State)};
error(retailer_gift_exist, Code) ->
    {2137, "gift exist:" ++ ?to_s(Code)};
error(gift_drawed_last_month, Gift) ->
    {2138, "gift has been drawed:" ++ ?to_s(Gift)};
error(gift_rule_undefined, Rule) ->
    {2139, "undefined gift rule:" ++ ?to_s(Rule)};
error(gift_score_not_enought, Score) ->
    {2140, "gift not enought score:" ++ ?to_s(Score)};
error(gift_drawed_last_year, Gift) ->
    {2141, "gift has been drawed:" ++ ?to_s(Gift)};
error(max_trans, RetailerId) ->
    {2142, "more trans of the retailer:" ++ ?to_s(RetailerId)};
    
%% wprint
error(wprint_server_exist, Server) ->
    {2201, "wprint server " ++ ?to_s(Server) ++ " does exist."}; 
error(wprinter_exist, PId) ->
    {2202, "wprinter " ++ ?to_s(PId) ++ " does exist."}; 
error(wprinter_conn_exist, CId) ->
    {2203, "wprinter connection " ++ ?to_s(CId) ++ " does exist."}; 
error(wprinter_conn_used, CId) ->
    {2204, "wprinter connection " ++ ?to_s(CId) ++ " has been used."};

%% wsale
error(shop_not_printer, Shop) ->
    {2401, "the shop " ++ ?to_s(Shop) ++ " have not printer."};
error(wsale_draft_not_exist, SN) ->
    {2501, "draft " ++ ?to_s(SN) ++ " does not exist."};
error(wsale_history_failed, Retailer) ->
    {2601, "failed to get history of retailer " ++ ?to_s(Retailer)};
error(wsale_empty, RSN) ->
    {2602, "there is no sale of rsn:" ++ ?to_s(RSN)};
error(wsale_trans_detail_not_empty, RSN) ->
    {2603, "trans detail is not empty of rsn:" ++ ?to_s(RSN)};
error(wsale_export_error, Error) ->
    {2701, "failed to export file: " ++ ?to_s(Error)};
error(wsale_export_no_date, Merchant) ->
    {2702, "no date to export of merchant: " ++ ?to_s(Merchant)};
error(wsale_not_enought_balance, Retailer) ->
    {2703, "no enought balance of retailer: " ++ ?to_s(Retailer)};
error(wsale_invalid_inv, StyleNumber) ->
    {2704, "error style number " ++ ?to_s(StyleNumber) ++ "."};
error(wsale_invalid_pay, Pay) ->
    {2705, "error should pay " ++ ?to_s(Pay) ++ "."};
error(wsale_invalid_ticket_balance, Balance) ->
    {2706, "invalid ticket balance: " ++ ?to_s(Balance) ++ "."};
error(wsale_invalid_ticket_score, TicketSId) ->
    {2707, "invalid ticket promotion score: " ++ ?to_s(TicketSId) ++ "."};
error(wsale_invalid_date, Action) ->
    {2708, "invalid datetime of action: " ++ ?to_s(Action) ++ "."};
error(wsale_stock_not_found, StyleNumber) ->
    {2709, "stock not found: " ++ ?to_s(StyleNumber) ++ "."};
error(wsale_stock_not_enought, StyleNumber) ->
    {2710, "stock not enought: " ++ ?to_s(StyleNumber) ++ "."};
error(wsale_stock_not_unique, StyleNumber) ->
    {2711, "stock not unique: " ++ ?to_s(StyleNumber) ++ "."};
error(wsale_invalid_stock_total, StyleNumber) ->
    {2712, "invalid stock total: " ++ ?to_s(StyleNumber) ++ "."};
error(no_valid_ticket, Merchant) ->
    {2713, "No valid ticket: " ++ ?to_s(Merchant) ++ "."};
error(ticket_gifted, RSN) ->
    {2714, "the ticket has ben gifted: " ++ ?to_s(RSN) ++ "."};
error(invalid_ticket_balance, Batch) ->
    {2715, "invalid balance of ticket: " ++ ?to_s(Batch) ++ "."};
error(more_ticket_consume, Batchs) ->
    {2610, "there are more tickets with batchs: " ++ ?to_s(Batchs) ++ "."};
error(pay_http_failed, Reason) ->
    {2611, "start pay http failed: " ++ ?to_s(Reason) ++ "."};
error(check_pay_http_failed, Reason) ->
    {2612, "start query pay http failed: " ++ ?to_s(Reason) ++ "."};
error(pay_scan_not_open, Shop) ->
    {2613, "pay with scan not opened: " ++ ?to_s(Shop) ++ "."};
error(pay_scan_failed, Merchant) ->
    {2614, "failed to pay scan: " ++ ?to_s(Merchant) ++ "."};
error(check_pay_scan_failed, PayOrder) ->
    {2615, "failed to pay scan query: " ++ ?to_s(PayOrder) ++ "."};
error(pay_scan_no_shop, Shop) ->
    {2616, "failed to get shop with pay scan: " ++ ?to_s(Shop) ++ "."};
error(invalid_pay_scan_code_len, PayCode) ->
    {2617, "invalid pay code len:" ++ ?to_s(PayCode)};
error(pay_http_trans_failed, ECode) ->
    {2618, "failed to pay scan trade: " ++ ?to_s(ECode)};
error(check_pay_scan_but_db_error, PayOrderNo) ->
    {2686, "success to check pay, error to db:" ++ ?to_s(PayOrderNo)};
error(pay_scan_unkown, PayOrderNo) ->
    {2687, "unkown state while pay scan:" ++ ?to_s(PayOrderNo)};
error(pay_scan_success_but_db_error, PayOrderNo) ->
    {2688, "success to pay, error to db:" ++ ?to_s(PayOrderNo)};

%% about print
error(invalid_sn, PrintSN) ->
    {2411, "invalid SN of print " ++ ?to_s(PrintSN)};
error(fail_to_process, PrintSN) ->
    {2412, "fail to process order of print " ++ ?to_s(PrintSN)};
error(long_content, PrintSN) ->
    {2413, "more than the content of print" ++ ?to_s(PrintSN)};
error(invalid_params, PrintSN) ->
    {2414, "invalid parameter of print " ++ ?to_s(PrintSN)};
error(print_timeout, RSN) ->
    {2415, "timeout of rsn " ++ ?to_s(RSN)};
error(print_unkown_error, RSN) ->
    {2416, "unkown error of print " ++ ?to_s(RSN)};
error(print_http_failed, Reason) ->
    {2417, "fail to request http message of printing:" ++ ?to_s(Reason)};
error(print_content_error, Printer) ->
    {2418, "failed to print " ++ ?to_s(Printer)};
error(printer_unconnect, Printer) ->
    {2419, "printer " ++ ?to_s(Printer) ++ " does not connected."};
error(printer_no_paper, Printer) ->
    {2420, "printer " ++ ?to_s(Printer) ++ " is not enought paper."};
error(printer_unkown_state, Printer) ->
    {2421, "printer " ++ ?to_s(Printer) ++ " in unkown state."};
error(printer_conn_not_found, Printer) ->
    {2422, "printer device " ++ ?to_s(Printer) ++ " not found."};
error(print_size_not_include, Shop) ->
    {2423, "print field size must be include of shop " ++ ?to_s(Shop)};

%% sms notify
error(sms_center_not_found, Merchant) ->
    {2501, "SMS center does not found: " ++ ?to_s(Merchant)};
error(sms_not_enought_blance, Merchant) ->
    {2502, "there is not enought balance of merchant: " ++ ?to_s(Merchant)};
error(sms_rate_not_found, Merchant) ->
    {2503, "SMS rate does not found: " ++ ?to_s(Merchant)};
error(sms_template_not_found, Merchant) ->
    {2597, "faile to get zz SMS template: " ++ ?to_s(Merchant)};
error(sms_http_failed, Reason) ->
    {2598, "faile to request SMS: " ++ ?to_s(Reason)};
error(sms_send_failed, Reason) ->
    {2599, "aili to send SMS: " ++ ?to_s(Reason)};

%% profile
error(get_score_profile_filed, Merchant) ->
    {6001, "failed to get score profile: " ++ ?to_s(Merchant)};

%% batch saler
error(batch_saler_exist, Name) ->
    {7001, "batch saler exist: " ++ ?to_s(Name)};
error(batch_sale_prop_exist, Name) ->
    {7002, "batch sale prop exist: " ++ ?to_s(Name)};

%% base
error(base_card_exist, CardNo) ->
    {8001, "card:" ++ ?to_s(CardNo) ++ "has been exist"};
error(base_setting_exist, EName) ->
    {8002, "name " ++ ?to_s(EName) ++ " of base setting has been exist"};
error(base_invalid_update_passwd, User) ->
    {8003, "invalid password of user " ++ ?to_s(User)};
error(good_executive_exist, Name) ->
    {8005, "good executive standard has been exist " ++ ?to_s(Name)};
error(good_safety_exist, Name) ->
    {8006, "good safty category has been exist " ++ ?to_s(Name)};
error(good_fabric_exist, Name) ->
    {8007, "good fabric has been exist " ++ ?to_s(Name)};
error(good_ctype_exist, TypeId) ->
    {8008, "ctype" ++ ?to_s(TypeId) ++ " has been existed."};
error(good_size_spec_exist, SpecId) ->
    {8009, "size sepcific " ++ ?to_s(SpecId) ++ " has been existed."};
error(good_size_spec_invalid_size, Name) ->
    {8011, "invalid size name " ++ ?to_s(Name) ++ " of size specific."};

%% DB
error(db_error, EInfo) ->
    {9001, "DB error: " ++ ?to_s(EInfo)};
error(db_timeout, _) ->
    {9003, "DB timeout."};
%% unkown method
error(unkown_operation, Method) ->
    {9002, "unkown operation: " ++ ?to_s(Method)};

%% not enought right
error(not_enought_right, Action) ->
    {9901, "not enougth right of action " ++ ?to_s(Action)};
error(operation_invalid_session, Error) ->
    {9902, "operation with invalid session with error " ++ ?to_s(Error)};

error(file_op_error, Error) ->
    {9101, "failed to operator file:" ++ ?to_s(Error)};
error(params_error, Name) ->
    {9102, "parameter input error: " ++ ?to_s(Name)}.

%% batch
