%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright (C) 2020, buxianhui
%%% @doc
%%% @end
%%% Created : 10 Mar 2020 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_table).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

%% API
-compile(export_all).

%%%===================================================================
%%% API
%%%===================================================================
t_suffix(_Merchant, UTable) when UTable =:= 0 ->
    "";
t_suffix(Merchant, UTable) when UTable =:= 1 ->
    "_" ++ ?to_s(Merchant).

t(good, Merchant, UTable) ->
    " w_inventory_good" ++ t_suffix(Merchant, UTable);
t(good_extra, Merchant, UTable) ->
    " w_inventory_good_extra" ++ t_suffix(Merchant, UTable);

t(stock_new, Merchant, UTable) ->
    " w_inventory_new" ++ t_suffix(Merchant, UTable);
t(stock_new_detail, Merchant, UTable) ->
    " w_inventory_new_detail" ++ t_suffix(Merchant, UTable);
t(stock_new_note, Merchant, UTable) ->
    " w_inventory_new_detail_amount" ++ t_suffix(Merchant, UTable);

%% ================================================================================
%% order
%% ================================================================================
t(stock_order, Merchant, UTable) ->
    " w_inventory_order" ++ t_suffix(Merchant, UTable);
t(stock_order_detail, Merchant, UTable) ->
    " w_inventory_order_detail" ++ t_suffix(Merchant, UTable);
t(stock_order_note, Merchant, UTable) ->
    " w_inventory_order_note" ++ t_suffix(Merchant, UTable);

t(stock, Merchant, UTable) ->
    " w_inventory" ++ t_suffix(Merchant, UTable);
t(stock_note, Merchant, UTable) ->
    " w_inventory_amount" ++ t_suffix(Merchant, UTable);


t(sale_order, Merchant, UTable) ->
    " w_sale_order" ++ t_suffix(Merchant, UTable);
t(sale_order_detail, Merchant, UTable) ->
    " w_sale_order_detail" ++ t_suffix(Merchant, UTable);
t(sale_order_note, Merchant, UTable) ->
    " w_sale_order_note" ++ t_suffix(Merchant, UTable);

t(sale_new, Merchant, UTable) ->
    " w_sale" ++ t_suffix(Merchant, UTable);
t(sale_detail, Merchant, UTable) ->
    " w_sale_detail" ++ t_suffix(Merchant, UTable);
t(sale_note, Merchant, UTable) ->
    " w_sale_detail_amount" ++ t_suffix(Merchant, UTable);

t(stock_transfer, Merchant, UTable) ->
    " w_inventory_transfer" ++ t_suffix(Merchant, UTable);
t(stock_transfer_detail, Merchant, UTable) ->
    " w_inventory_transfer_detail" ++ t_suffix(Merchant, UTable);
t(stock_transfer_note, Merchant, UTable) ->
    " w_inventory_transfer_detail_amount" ++ t_suffix(Merchant, UTable);

t(stock_fix, Merchant, UTable) ->
    " w_inventory_fix" ++ t_suffix(Merchant, UTable);
t(stock_fix_note, Merchant, UTable) ->
    " w_inventory_fix_detail_amount" ++ t_suffix(Merchant, UTable).


    
