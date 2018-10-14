%%%-------------------------------------------------------------------
%%% @author buxianhui <buxianhui@myowner.com>
%%% @copyright SeasunGame(C) 2014, buxianhui
%%% @doc
%%%
%%% @end
%%% Created : 20 Jun 2014 by buxianhui <buxianhui@myowner.com>
%%%-------------------------------------------------------------------
-module(diablo_controller_sup).

-include("../../../../include/knife.hrl").
-include("diablo_controller.hrl").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%%%===================================================================
%%% Supervisor callbacks
%%%===================================================================

init([]) ->
    RestartStrategy = one_for_one,
    MaxRestarts = 1000,
    MaxSecondsBetweenRestarts = 3600,

    SupFlags = {RestartStrategy, MaxRestarts, MaxSecondsBetweenRestarts},

    Restart = permanent,
    Shutdown = 2000,
    Type = worker,

    IConv = {diablo_iconv,
	     {diablo_iconv, start_link, []},
	     Restart, Shutdown, Type, [diablo_iconv]},
    
    Mysql = {diablo_controller_mysql,
    	      {diablo_controller_mysql, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_mysql]},

    %% Member = {diablo_controller_member,
    %% 	      {diablo_controller_member, start_link, []},
    %% 	      Restart, Shutdown, Type, [diablo_controller_member]},

    Employ = {diablo_controller_employ,
    	      {diablo_controller_employ, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_employ]},

    Merchant = {diablo_controller_merchant,
    	      {diablo_controller_merchant, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_merchant]},

    Shop = {diablo_controller_shop,
    	      {diablo_controller_shop, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_shop]},

    Right = {diablo_controller_right,
    	      {diablo_controller_right, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_right]},

    Supplier = {diablo_controller_supplier,
    	      {diablo_controller_supplier, start_link, []},
    	      Restart, Shutdown, Type, [diablo_controller_supplier]},

    %% Inventory = {diablo_controller_inventory,
    %% 	      {diablo_controller_inventory, start_link, []},
    %% 	      Restart, Shutdown, Type, [diablo_controller_inventory]},

    InventorySN = {diablo_controller_inventory_sn,
		 {diablo_controller_inventory_sn, start_link, []},
		 Restart, Shutdown, Type, [diablo_controller_inventory_sn]},

    %% Sale = {diablo_controller_sale,
    %% 	      {diablo_controller_sale, start_link, []},
    %% 	      Restart, Shutdown, Type, [diablo_controller_sale]},

    Login = {diablo_controller_login,
	     {diablo_controller_login, start_link, []},
	     Restart, Shutdown, Type, [diablo_controller_login]},

    Session = {diablo_controller_session_manager,
	       {diablo_controller_session_manager, start_link, []},
	       Restart, Shutdown, Type, [diablo_controller_session_manager]},

    RightTree = {diablo_controller_right_init,
	       {diablo_controller_right_init, start_link, []},
	       Restart, Shutdown, Type, [diablo_controller_right_init]},

    Authen = {diablo_controller_authen,
	       {diablo_controller_authen, start_link, []},
	       Restart, Shutdown, Type, [diablo_controller_authen]},

    %% ablout wholesale 
    %% WInventory =
    %% 	{diablo_purchaser,
    %% 	 {diablo_purchaser, start_link, []},
    %% 	 Restart, Shutdown, Type, [diablo_purchaser]},

    %% WRetailer =
    %% 	{diablo_w_retailer,
    %% 	 {diablo_w_retailer, start_link, []},
    %% 	 Restart, Shutdown, Type, [diablo_w_retailer]},

    %% WSale =
    %% 	{diablo_w_sale,
    %% 	 {diablo_w_sale, start_link, []},
    %% 	 Restart, Shutdown, Type, [diablo_w_sale]},

    %% WSaleDraft =
    %% 	{diablo_w_sale_draft,
    %% 	 {diablo_w_sale_draft, start_link, []},
    %% 	 Restart, Shutdown, Type, [diablo_w_sale_draft]},

    WPrint =
	{diablo_w_print,
	 {diablo_w_print, start_link, []},
	 Restart, Shutdown, Type, [diablo_w_print]},

    WBase =
	{diablo_w_base,
	 {diablo_w_base, start_link, []},
	 Restart, Shutdown, Type, [diablo_w_base]},
    
    Attr =
	{diablo_attribute,
	 {diablo_attribute, start_link, []},
	 Restart, Shutdown, Type, [diablo_attribute]},
     

    WProfile = 
    	{diablo_wuser_profile,
    	 {diablo_wuser_profile, start_link, []},
    	 Restart, Shutdown, Type, [diablo_wuser_profile]},
    
    %% wifi printer
    HttpPrint =
    	{diablo_http_print,
    	 {diablo_http_print, start_link, []},
    	 Restart, Shutdown, Type, [diablo_http_print]},

    %% wreport
    WReport = 
	{diablo_w_report,
	 {diablo_w_report, start_link, []},
	 Restart, Shutdown, Type, [diablo_w_report]},

    WGenReport = 
	{diablo_auto_gen_report,
	 {diablo_auto_gen_report, start_link, []},
	 Restart, Shutdown, Type, [diablo_auto_gen_report]},

    %% about cron
    CronRegister =
	{diablo_cron_job_register,
	 {diablo_cron_job_register, start_link, []},
	 Restart, Shutdown, Type, [diablo_cron_job_register]},

    CronController =
	{diablo_cron_control,
	 {diablo_cron_control, start_link, []},
	 Restart, Shutdown, Type, [diablo_cron_control]},
    
    
    WholeSale = [WPrint, WBase, WProfile, HttpPrint, WReport, WGenReport,
    		 CronRegister, CronController],

    %% WholeSale = [WPrint, WBase, HttpPrint, WReport, WGenReport,
    %% 		 CronRegister, CronController],

    %% WProfileSup = ?to_a(lists:concat([?w_user_profile, "_sup"])),
    %% WProfilePoolSup = {
    %%   WProfileSup,
    %%   {diablo_work_pool_sup, start_link, [?w_user_profile]},
    %%   Restart, Shutdown, supervisor, [WProfileSup]},

    WRetailerSup = ?to_a(lists:concat([?w_retailer, "_sup"])),
    WRetailerPoolSup = {
      WRetailerSup,
      {diablo_work_pool_sup, start_link, [?w_retailer]},
      Restart, Shutdown, supervisor, [WRetailerSup]},
    
    WInvSup = ?to_a(?to_s(?w_inventory) ++ "_sup"),
    WInvPoolSup = {WInvSup,
		   {diablo_work_pool_sup, start_link, [?w_inventory]},
		   Restart, Shutdown, supervisor, [WInvSup]},


    WSaleSup = ?to_a(?to_s(?w_sale) ++ "_sup"), 
    WSalePoolSup = {WSaleSup,
		    {diablo_work_pool_sup, start_link, [?w_sale]},
		    Restart, Shutdown, supervisor, [WSaleSup]},

    PromotionSup = ?to_a(?to_s(?promotion) ++ "_sup"),
    PromotionPoolSup = {PromotionSup,
			{diablo_work_pool_sup, start_link, [?promotion]},
			Restart, Shutdown, supervisor, [PromotionSup]},
    

    CronSup = ?to_a(?to_s(?cron_agent) ++ "_sup"),
    CronPoolSup = {CronSup,
		   {diablo_work_pool_sup, start_link, [?cron_agent]},
		   Restart, Shutdown, supervisor, [CronSup]},

    %% batch
    BatchSalerSup = ?to_a(lists:concat([?b_saler, "_sup"])),
    BatchSalerPoolSup = {
      BatchSalerSup,
      {diablo_work_pool_sup, start_link, [?b_saler]},
      Restart, Shutdown, supervisor, [BatchSalerSup]},
    
    PoolSup = [
	       %% WProfilePoolSup,
	       WRetailerPoolSup,
	       WInvPoolSup,
	       WSalePoolSup,
	       PromotionPoolSup,
	       CronPoolSup,

	       %% Batch Saler
	       BatchSalerPoolSup
	      ],

    {ok, {SupFlags, [IConv, Mysql, Employ, Merchant,
    		     Shop, Right, Supplier,
    		     InventorySN, Login, Session,
    		     RightTree, Authen, Attr]
	  ++ WholeSale ++ PoolSup}}.
