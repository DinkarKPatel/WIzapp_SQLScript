CREATE PROCEDURE SP3S_CREATEDEFAULTREPORTFORTH
(
 @cRepID varchar(10)
)
AS
BEGIN

Delete From rep_det where  rep_id= @cRepID
Delete From rep_mst where  rep_id= @cRepID


INSERT rep_mst	( Address, Ageing_on, City, company, contr_per, CrossTab_Rep, CrossTab_Type, EDT_USER_CODE, For_Mgmt, For_MWizApp,
For_wizapplive, InActive, last_update, multi_page, OLAP_SYNCH_LAST_UPDATE, Phone, Pin, ref_rep_id, Remarks, rep_code, rep_id, rep_name, 
rep_operator, report_item_type, RTitle1, RTitle2, RTitle3, SMS, sold_item, user_code, user_rep_type, xn_history, XPERT_REP_CODE )  
SELECT    0, 0, 0, 0, 0, 0, 0, '0000000',0,0, 0,  0,  getdate(), 0, '', 0, 0, '', '', 'X001', @cRepID , 'Transaction History', 'AND', 1, '', '', '', '', 0, '0000000', 'ALL', 1, 'R2'

INSERT rep_det	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE,
col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, old_key_col, order_by, order_on, rep_code, rep_id, 
Required, row_id, table_name, total )  
SELECT 	  '', '', '', 0, 'Xn_type', 'Transaction Type', 'xn_type', 0, 0, '', '',  15, 0, 0, 0, 0, 0, 0, 0, 'xn_type', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 0 
UNION
SELECT 	  '', '', '', 0, 'Transaction_Date', 'Transaction Date', 'Transaction_Date', 1, 0, '', '',  15, 0, 0, 0, 0, 0, 0, 0, 'Transaction_Date', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 0 
UNION
SELECT 	  '', '', '', 0, 'Transaction_No', 'Transaction No.', 'Transaction_No', 1, 0, '', '',  15, 0, 0, 0, 0, 0, 0, 0, 'Transaction_No', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 0 
Union
SELECT 	  '', '', '', 0, 'Transaction_Location_Id', 'Transaction Location Id', 'Transaction_Location_Id', 2, 0, '', '',  15, 0, 0, 0, 0, 0, 0, 0, 'Transaction_Location_Id', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 0 
Union
SELECT 	  '', '', '', 0, 'Transaction_Location_Bin', 'Transaction Location Bin', 'Transaction_Location_Bin', 3, 0, '', '',  15, 0, 0, 0, 0, 0, 0, 0, 'Transaction_Location_Bin', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 0 
Union
SELECT 	  '', '', '', 1, 'Transaction_Qty', 'Transaction Qty', 'Transaction_Qty', 4, 0, '', '',  15, 0, 0, 2, 0, 0, 0, 0, 'Transaction_Qty', 0, '', '', '', 'X001', @cRepID, 1, newid(), '', 1 

END


