
CREATE PROC SP3S_CRERATFIXPETTYCASHREPS
As
Begin

Delete from rep_det  where   rep_id = 'PCFIX00001' 
delete From  rep_crm  where   rep_id = 'PCFIX00001' 
delete From  rep_sch  where   rep_id = 'PCFIX00001' 
Delete from rep_mst  where   rep_id = 'PCFIX00001' 


Delete from rep_det  where   rep_id = 'PCFIX00002' 
delete From  rep_crm  where   rep_id = 'PCFIX00002' 
delete From  rep_sch  where   rep_id = 'PCFIX00002' 
Delete from rep_mst  where   rep_id = 'PCFIX00002' 


 INSERT rep_mst	( Address, Ageing_on, City, company, contr_per, CrossTab_Rep, CrossTab_Type, EDT_USER_CODE, For_Mgmt, 
 For_MWizApp, For_wizapplive, InActive, last_update, multi_page, OLAP_SYNCH_LAST_UPDATE, Phone, Pin, ref_rep_id, Remarks, rep_code, rep_id,  rep_name, 
 rep_operator, report_item_type, RTitle1, RTitle2, RTitle3, SMS, sold_item, user_code, user_rep_type, xn_history, XPERT_REP_CODE )  
 SELECT 	top 1  Address, Ageing_on, City, company, contr_per, CrossTab_Rep, CrossTab_Type, EDT_USER_CODE, For_Mgmt, 1 as For_MWizApp,
 1 as For_wizapplive, InActive, last_update, multi_page, OLAP_SYNCH_LAST_UPDATE, Phone, Pin, ref_rep_id, Remarks, rep_code, 'PCFIX00001' as  rep_id, 
 'Location Wise Petty Cash Report' as rep_name, 
 rep_operator, report_item_type, RTitle1, RTitle2, RTitle3, SMS, sold_item, user_code, 'Fix Format' as user_rep_type, xn_history, XPERT_REP_CODE 
 FROM rep_mst where rep_code= 'A002'


  INSERT rep_det	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
  col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, old_key_col, order_by, order_on, 
  rep_code, rep_id, Required, row_id, table_name, total ) 
  SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'LOC_ID' as  col_expr, 'Loc id'  as col_header, 'LOC_ID' as col_mst, 0 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'LOC_ID' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 
 UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'DEPT_NAME' as  col_expr, 'Loc Name'  as col_header, 'DEPT_NAME' as col_mst, 1 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'DEPT_NAME' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 

  UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'OB' as  col_expr, 'Opening'  as col_header, 'OB' as col_mst, 2 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'OB' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 

  UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'EXPENSES' as  col_expr, 'Expenses'  as col_header, 'EXPENSES' as col_mst, 3 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'EXPENSES' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 
   UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'RECEIPTS' as  col_expr, 'Receipts'  as col_header, 'RECEIPTS' as col_mst, 3 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'RECEIPTS' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 

    UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'CB' as  col_expr, 'Closeing'  as col_header, 'CB' as col_mst, 3 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'CB' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00001' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 




 
 INSERT rep_mst	( Address, Ageing_on, City, company, contr_per, CrossTab_Rep, CrossTab_Type, EDT_USER_CODE, For_Mgmt, 
 For_MWizApp, For_wizapplive, InActive, last_update, multi_page, OLAP_SYNCH_LAST_UPDATE, Phone, Pin, ref_rep_id, Remarks, rep_code, rep_id,  rep_name, 
 rep_operator, report_item_type, RTitle1, RTitle2, RTitle3, SMS, sold_item, user_code, user_rep_type, xn_history, XPERT_REP_CODE )  
 SELECT 	top 1  Address, Ageing_on, City, company, contr_per, CrossTab_Rep, CrossTab_Type, EDT_USER_CODE, For_Mgmt, 1 as For_MWizApp,
 1 as For_wizapplive, InActive, last_update, multi_page, OLAP_SYNCH_LAST_UPDATE, Phone, Pin, ref_rep_id, Remarks, rep_code, 'PCFIX00002' as  rep_id, 
 'Ledger Wise Petty Cash Report' as rep_name, 
 rep_operator, report_item_type, RTitle1, RTitle2, RTitle3, SMS, sold_item, user_code, 'Fix Format' as user_rep_type, xn_history, XPERT_REP_CODE 
 FROM rep_mst where rep_code= 'A002'


   INSERT rep_det	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
  col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, old_key_col, order_by, order_on, 
  rep_code, rep_id, Required, row_id, table_name, total ) 


   SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'dept_id' as  col_expr, 'Loc Id'  as col_header, 'dept_id' as col_mst, 0 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'dept_id' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 

 UNION ALL

 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'XN_DT' as  col_expr, 'XN  Date'  as col_header, 'XN_DT' as col_mst, 1 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'XN_DT' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 
 UNION ALL
  SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'AC_NAME' as  col_expr, 'Ac Name'  as col_header, 'AC_NAME' as col_mst, 2 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'AC_NAME' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 
 UNION ALL
   SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, 0 as Calculative_col, 'NARRATION' as  col_expr, 'Narration'  as col_header, 'NARRATION' as col_mst, 3 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 ascum_sum, 0 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'NARRATION' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 

  UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'DR_AMOUNT' as  col_expr, 'Dr'  as col_header, 'DR_AMOUNT' as col_mst, 4 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'DR_AMOUNT' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 1 as total
 FROM rep_det where rep_code= 'A002' 

   UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'CR_AMOUNT' as  col_expr, 'Cr'  as col_header, 'CR_AMOUNT' as col_mst, 5 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'CR_AMOUNT' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 1 as total
 FROM rep_det where rep_code= 'A002' 

    UNION ALL
 SELECT top 1 	  BASIC_COL, CAL_COLUMN_GRP, 'SUM' as Cal_function,  1 as Calculative_col, 'CLOSING' as  col_expr, 'Closing'  as col_header, 'CLOSING' as col_mst, 6 as col_Order, 
  0 as col_repeat, 'ACT'as col_Type, 
  '' as COL_VALUE_TYPE, 14 as col_width, 0 as contr_per, 0 as cum_sum, 2 as Decimal_place, 0 as Dimension, 0 as Enforced_col, 0 as Filter_col, 0 as grp_total, 
  'CLOSING' as key_col, 0 as Mesurement_col, 
 '' as  old_key_col, 'ASC' as order_by, 0 as order_on, 'A002' as  rep_code,'PCFIX00002' as  rep_id,0 as  Required, newid() as row_id, 'VW_PETTY_CASH' as table_name, 0 as total
 FROM rep_det where rep_code= 'A002' 


 END


