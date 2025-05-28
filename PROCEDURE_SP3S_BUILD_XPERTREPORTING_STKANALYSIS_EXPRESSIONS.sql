CREATE PROCEDURE SP3S_BUILD_XPERTREPORTING_STKANALYSIS_EXPRESSIONS
AS
BEGIN

SELECT * INTO #transaction_analysis_derived_COLS_link_STK from  transaction_analysis_derived_COLS_link
where 1=2

SELECT * INTO #transaction_analysis_calculative_COLS_stk FROM transaction_analysis_calculative_COLS	
WHERE 1=2

SELECT * INTO #transaction_analysis_MASTER_COLS_stk FROM  transaction_analysis_master_COLS	
WHERE 1=2
	
DECLARE @cHoLocId VARCHAR(4),@cCurLocId VARCHAR(4)

SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='ho_location_id'
SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'


truncate table  transaction_analysis_stock_expr

DELETE FROM  transaction_analysis_derived_COLS_link WHERE rep_type='STOCK'

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT xn_type,base_expr FROM  transaction_analysis_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Stock' xn_type,'[LAYOUT_COLS]
FROM [TABLENAME] A WITH (NOLOCK) 
LEFT JOIN year_wise_cbsstk_depcn_det c WITH (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id
AND c.fin_year=''01''+dbo.fn_getfinyear([DTODT]) [JOIN]
WHERE A.BIN_ID <> ''999''  AND [WHERE]  
group by [GROUPBY]' AS base_expr





INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Purchase(Gross)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.PID01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=b.ref_converted_mrntobill_mrrid
[JOIN]
WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 
AND pim_conv.mrr_id IS NULL AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Purchase(Net)1' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.PID01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=b.ref_converted_mrntobill_mrrid
[JOIN]
WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 
AND pim_conv.mrr_id IS NULL AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Purchase(Net)2' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.RMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
[JOIN]
WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
AND b.mode=1 AND b.cancelled=0 AND [WHERE]    
group by [GROUPBY]' AS base_expr




INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan Out(WSL)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.IND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
[JOIN]
WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.inv_mode=2 AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Retail Sale(SLS)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.CMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
[JOIN]
WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND quantity>0 AND [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Retail Sale(SLR)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.CMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
[JOIN]
WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND quantity<0 AND [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan Out(PRT)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.RMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
[JOIN]
WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.mode=2 AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Wholesale (Party)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.IND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
[JOIN]
WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.inv_mode=1  AND ISNULL(bin_transfer,0)<>1 AND [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Wholesale(Net)1' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.IND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
[JOIN]
WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.inv_mode=1  AND ISNULL(bin_transfer,0)<>1 AND [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Wholesale(Net)2' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.CND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
[JOIN]
WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 
AND [WHERE]    
group by [GROUPBY]' AS base_expr




INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Debit note (Party)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.RMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
[JOIN]
WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.mode=1  AND B.DN_TYPE IN (0,1) AND [WHERE]    
group by [GROUPBY]' AS base_expr

IF @cHoLocId=@cCurLocId
BEGIN
INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan In(PUR)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.IND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
[JOIN]
WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.inv_mode=2 AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan In(WSR)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.RMD01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
[JOIN] WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.mode=2 AND [WHERE]    
group by [GROUPBY]' AS base_expr

END
ELSE
BEGIN
INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan In(PUR)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.PID01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
[JOIN]
WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
b.inv_mode=2 AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Challan In(WSR)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.CND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
[JOIN]
WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0
AND [WHERE]    
group by [GROUPBY]' AS base_expr
END

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Credit Note(Gross)' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.CND01106 A (NOLOCK)    
JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
[JOIN]
WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 
AND [WHERE]    
group by [GROUPBY]' AS base_expr





INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Inter Bin Transfer Out' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
[JOIN]
WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND  [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Inter Bin Transfer In' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
[JOIN]
WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND  [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'Split/Combine' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.snc_det A (NOLOCK)    
JOIN  [DATABASE].dbo.snc_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
[JOIN]
WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND  [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
SELECT 'GIT' xn_type,'[LAYOUT_COLS]
FROM [TABLENAME] A WITH (NOLOCK) 	 
left outer  JOIN INM01106 B ON B.INV_ID=SUBSTRING(A.MEMO_ID,4,LEN(A.memo_id))  
LEFT OUTER JOIN [DATABASE].dbo.PARCEL_DET PD  WITH(NOLOCK) ON A.Memo_id = PD.REF_MEMO_ID 
LEFT OUTER JOIN [DATABASE].dbo.parcel_mst  WITH(NOLOCK) on PD.parcel_memo_id = parcel_mst.parcel_memo_id 
and parcel_mst.xn_type= Left( A.Memo_id,3)  AND parcel_mst.CANCELLED=0
LEFT OUTER JOIN [DATABASE].dbo.ANGM  WITH(NOLOCK)  ON parcel_mst.angadia_code = ANGM.Angadia_code 	 
JOIN location c (NOLOCK) ON a.dept_id=c.dept_id
[JOIN]
WHERE [WHERE]  
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
SELECT 'Job Work(Net)1' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.jobwork_issue_det A (NOLOCK)    
JOIN  [DATABASE].dbo.jobwork_issue_mst B (NOLOCK) ON A.issue_id = B.issue_id 
	JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON B.agency_code = PAM.agency_code  
[JOIN]
WHERE b.issue_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
AND [WHERE]    
group by [GROUPBY]' AS base_expr


INSERT transaction_analysis_stock_expr (xn_type,base_expr)    
--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
SELECT 'Job Work(Net)2' xn_type,'[LAYOUT_COLS]
from [DATABASE].dbo.jobwork_receipt_det A (NOLOCK)    
JOIN  [DATABASE].dbo.jobwork_receipt_mst B (NOLOCK) ON A.receipt_id = B.receipt_id   
JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON B.agency_code = PAM.agency_code  
[JOIN]
WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
AND [WHERE]    
group by [GROUPBY]' AS base_expr

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT DISTINCT COL_EXPR,keyfield,col_header ,coalesce(b.xn_type,c.xn_type,d.xn_type,e.xn_type,f.xn_type,g.xn_type) xn_type,joining_table,joining_column
From transaction_analysis_MASTER_COLS a
LEFT JOIN transaction_analysis_stock_expr b ON a.xn_type=b.xn_type
LEFT JOIN transaction_analysis_stock_expr c ON a.xn_type=REPLACE(c.xn_type,'(NET)1','')
LEFT JOIN transaction_analysis_stock_expr d ON a.xn_type=REPLACE(d.xn_type,'(NET)2','')
LEFT JOIN transaction_analysis_stock_expr e ON a.xn_type=REPLACE(e.xn_type,'(Gross)','')
LEFT JOIN transaction_analysis_stock_expr f ON a.xn_type=REPLACE(f.xn_type,'(SLS)','')
LEFT JOIN transaction_analysis_stock_expr g ON a.xn_type=REPLACE(g.xn_type,'(SLR)','')
WHERE joining_table='loc_names' AND a.rep_type='DETAIL'
AND coalesce(b.xn_type,c.xn_type,d.xn_type,e.xn_type,f.xn_type,g.xn_type)  IS NOT NULL



INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'a.dept_id' AS keyfield,table_caption AS col_header ,
'Common' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''



INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'inactive' as COL_EXPR,'a.dept_id' AS keyfield,'Location InActive' AS col_header ,
'Common' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column

--LOCATTR END


--AGEDAYS
--sum(a.cbs_qty*a.purchase_ageing_days)/sum(a.cbs_qty)
--Stock

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'sum(a.cbs_qty*a.purchase_ageing_days)/(sum(a.cbs_qty))' as  COL_EXPR ,'Purchase Ageing Days'  as col_header , 'PURSTKAGEDAYS'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'sum(a.cbs_qty*a.shelf_ageing_days)/(sum(a.cbs_qty))' as  COL_EXPR ,'Shelf Ageing Days'  as col_header , 'SHELFSTKAGEDAYS'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'sum(a.quantity*a.selling_days)/(sum(a.quantity))' as  COL_EXPR ,'Sale Ageing Days'  as col_header , 'SALESTKAGEDAYS'




--GROSS SLS

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.basic_discount_amount)' as  COL_EXPR ,'Gross Sale Item Discount Amount'  as col_header , 'GBASICDMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.card_discount_amount)' as  COL_EXPR ,'Gross Sale Card Discount Amt'  as col_header , 'GCARDDMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(A.CMM_DISCOUNT_AMOUNT)' as  COL_EXPR ,'Gross Sale Bill Disc Amt'  as col_header , 'SLSBILLDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(A.discount_amount+a.cmm_discount_amount)' as  COL_EXPR ,'SLS Total Discount'  as col_header , 'SLSDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'(ROUND((SUM(A.discount_amount+a.cmm_discount_amount)/SUM(a.quantity*a.mrp))*100,2))' as  COL_EXPR ,'Gross Sale Disc %'  as col_header , 'SLSDISPER'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sku.basic_purchase_price)' as  COL_EXPR ,'Gross SLS Val at Basic Pur Price'  as col_header , 'SPBASICP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.cgst_amount)' as  COL_EXPR ,'Gross SLS CGST Amt'  as col_header , 'SPCGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*a.mrp)' as  COL_EXPR ,'Gross SLS Val at MRP'  as col_header , 'SPG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*a.old_mrp)' as  COL_EXPR ,'Gross SLS Val at Old MRP'  as col_header , 'SPGOLD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'Gross SLS GST Amt'  as col_header , 'SPGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.igst_amount)' as  COL_EXPR ,'Gross SLS IGST Amt'  as col_header , 'SPIGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'Gross SLS Val at LC'  as col_header , 'SPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'Gross SLS Val at PP'  as col_header , 'SPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Gross SLS Qty'  as col_header , 'SPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.sgst_amount)' as  COL_EXPR ,'Gross SLS SGST Amt'  as col_header , 'SPSGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Gross SLS Val at WSP'  as col_header , 'SPWP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'Gross SLS Val at XFP'  as col_header , 'SPXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'Gross SLS Val at Current XFP'  as col_header , 'SPXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,''  as col_header , 'SPXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'Gross SLS Val at PP(W/O DEP.)'  as col_header , 'GSVPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.xn_value_with_gst) ' as  COL_EXPR ,'Gross SLS Transaction Value'  as col_header , 'GSTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.xn_value_without_gst) ' as  COL_EXPR ,'Gross SLS Transaction Value (W/O GST)'  as col_header , 'GSTRANWOGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale(SLS)' as xn_type,'SUM(a.quantity*a.old_mrp)' as  COL_EXPR ,'SLR Val at Old MRP'  as col_header , 'SRGOLD'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Stock' xn_type,'' as joining_table

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,col_name)     
SELECT 'dept_name' as COL_EXPR,'a.dept_id' AS keyfield,'Location Name' AS col_header ,
'Stock' xn_type,'dept_id' joining_column,'location' as joining_table,'dept_name' as col_name



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,col_name)     
SELECT 'ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Group Supplier' AS col_header ,
'Challan In(PUR)' xn_type,'ac_code' joining_column,'lm01106' as joining_table,'Group_supplier'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
'Common' xn_type,'' joining_column,'' as joining_table,
' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=a.dept_id AND  sxfp.product_code=a.product_code '+
' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'







INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,col_name)     
SELECT 'selling_days' as COL_EXPR,'' AS keyfield,'Sale Ageing' AS col_header ,
'Retail Sale' xn_type,'' as joining_table,'' col_name

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(a.cm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Retail Sale(SLS)' xn_type,'' as joining_table

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,col_name)     
SELECT 'scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
'Retail Sale(SLS)' xn_type,'' as joining_table,'scheme_name' col_name

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,col_name)     
SELECT 'scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
'Retail Sale' xn_type,'' as joining_table,'scheme_name' col_name

--SLR

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.basic_discount_amount)*-1' as  COL_EXPR ,'SLR Item Discount'  as col_header , 'SLRBASICDMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(A.CMM_DISCOUNT_AMOUNT)' as  COL_EXPR ,'SLR Bill Disc Amt'  as col_header , 'SLRBILLDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.card_discount_amount)*-1' as  COL_EXPR ,'SLR Card Discount'  as col_header , 'SLRCARDDMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(A.discount_amount+a.cmm_discount_amount)*-1' as  COL_EXPR ,'SLR Total Discount'  as col_header , 'SLRDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'(ROUND((SUM(A.discount_amount+a.cmm_discount_amount)/SUM(a.quantity*a.mrp))*100,2))' as  COL_EXPR ,'SLR Discount %'  as col_header , 'SLRDISPER'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,col_name)     
SELECT 'scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
'Retail Sale(SLR)' xn_type,'' as joining_table,'scheme_name' col_name


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst) *-1' as  COL_EXPR ,''  as col_header , 'SLRXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sku.basic_purchase_price)' as  COL_EXPR ,'SLR Val at Basic Pur Price'  as col_header , 'SRBASICP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.cgst_amount)*-1' as  COL_EXPR ,'SLR CGST Amt'  as col_header , 'SRCGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*a.mrp)*-1' as  COL_EXPR ,'SLR Val at MRP'  as col_header , 'SRG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)*-1' as  COL_EXPR ,'SLR GST Amt'  as col_header , 'SRGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.igst_amount)*-1' as  COL_EXPR ,'SLR IGST Amt'  as col_header , 'SRIGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sku_names.lc)*-1' as  COL_EXPR ,'SLR Val at LC'  as col_header , 'SRLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sku_names.pp)*-1' as  COL_EXPR ,'SLR Val at PP'  as col_header , 'SRP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'SLR Qty'  as col_header , 'SRQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.sgst_amount)*-1' as  COL_EXPR ,'SLR SGST Amt'  as col_header , 'SRSGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*Sku_NAMES.Ws_price)*-1' as  COL_EXPR ,'SLR Val at WSP'  as col_header , 'SRWP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)*-1' as  COL_EXPR ,'SLR Val at XFP'  as col_header , 'SRXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)*-1' as  COL_EXPR ,'SLR Val at Current XFP'  as col_header , 'SRXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as  COL_EXPR ,'SLR Val at PP(W/O DEP.)'  as col_header , 'SRPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.xn_value_with_gst)*-1 ' as  COL_EXPR ,'SLR Transaction Value'  as col_header , 'SRTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale(SLR)' as xn_type,'SUM(a.xn_value_without_gst)*-1 ' as  COL_EXPR ,'SLR Transaction Value (W/O GST)'  as col_header , 'SRTRANWOGST'


INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(a.cm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Retail Sale(SLR)' xn_type,'' as joining_table




--NET SLS


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'Round((SUM(A.QUANTITY *isnull(selling_days,0))/SUM(A.QUANTITY + 0.0001)),0)' as  COL_EXPR ,'Average Sale Days'  as col_header , 'AVGSALEDAYS'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'(SUM(A.quantity)/SUM(WeightedQtyBillCount)) ' as  COL_EXPR ,'Basket Size'  as col_header , 'BASKETSIZE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale' as xn_type,'(SUM(A.RFNET)/SUM(WeightedQtyBillCount))' as  COL_EXPR ,'Average Bill Value'  as col_header , 'BILLVALUEAVG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale' as xn_type,'SUM(A.COMMISSION_AMOUNT)' as  COL_EXPR ,'Commission Amount'  as col_header , 'COMMISSION_AMOUNT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(WeightedQtyBillCount)' as  COL_EXPR ,'Bill Count'  as col_header , 'COUNTBILL'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.basic_discount_amount)' as  COL_EXPR ,'Net SLS Item Discount'  as col_header , 'NETSBASICDMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.card_discount_amount)' as  COL_EXPR ,'Net SLS Card Discount'  as col_header , 'NETSCARDDMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(1)' as  COL_EXPR ,'Total Thaan'  as col_header , 'NETTHAAN'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sku.basic_purchase_price)' as  COL_EXPR ,'Net SLS Val at Basic  PP'  as col_header , 'NSBASICP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.cgst_amount)' as  COL_EXPR ,'Net SLS CGST Amt'  as col_header , 'NSCGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'Net SLS Val at Current XFP'  as col_header , 'NSCXFP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(A.discount_amount+a.cmm_discount_amount)' as  COL_EXPR ,'Net SLS Total Discount'  as col_header , 'NSDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'(ROUND((SUM(A.DISCOUNT_AMOUNT+A.CMM_DISCOUNT_AMOUNT)/SUM((A.QUANTITY*A.MRP)+0.0001))*100,2))' as  COL_EXPR ,'Net Sls Disc%'  as col_header , 'NSDISPER'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*a.mrp)' as  COL_EXPR ,'Net SLS Val at Gross MRP'  as col_header , 'NSG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*a.old_mrp)' as  COL_EXPR ,'Net SLS Val at Old Mrp'  as col_header , 'NSGOLD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(isnull(a.igst_amount,0)+isnull(a.sgst_amount,0)+isnull(a.cgst_amount,0)+isnull(a.tax_amount,0))' as  COL_EXPR ,'Net SLS GST'  as col_header , 'NSGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale' as xn_type,'SUM(a.igst_amount)' as  COL_EXPR ,'Net SLS IGST Amt'  as col_header , 'NSIGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'Net SLS Val at LC'  as col_header , 'NSLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(A.CMM_DISCOUNT_AMOUNT)' as  COL_EXPR ,'Net Sls Bill Discount'  as col_header , 'NSLSBILLDISAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'sum(a.net-a.cmm_discount_amount)' as  COL_EXPR ,'Net SLS Realized Value'  as col_header , 'NSM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'Net SLS Val at PP'  as col_header , 'NSP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'(SUM(A.rfnet)/(CASE WHEN LOC_VIEW.AREA_COVERED<=0 THEN 1 ELSE LOC_VIEW.AREA_COVERED END))/   (datediff(day,''dFromDt'', ''dToDt'')+1)' as  COL_EXPR ,'Sale PSFPD'  as col_header , 'NSPSQFPD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Retail Sale' as xn_type,'SUM(A.quantity*sku_oh.tax_amount)' as  COL_EXPR ,'Net SLS Pur Tax/GST Amt'  as col_header , 'NSPURGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net SLS Qty'  as col_header , 'NSQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.sgst_amount)' as  COL_EXPR ,'Net SLS SGST Amt'  as col_header , 'NSSGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Net SLS Val at WSP'  as col_header , 'NSWP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'Net SLS Val at XFP'  as col_header , 'NSXFP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'Net SLS Val at XFP(w/o gst)'  as col_header , 'NSXFPWG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(A.xn_value_without_gst)' as  COL_EXPR ,'Net Sls Taxable Value'  as col_header , 'NVWOGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'(SUM(RFNET)/SUM(quantity))' as  COL_EXPR ,'Average Unit Price'  as col_header , 'UNITPRICEAVG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'Net SLS Val at PP(W/O DEP.)'  as col_header , 'NSPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.xn_value_with_gst) ' as  COL_EXPR ,'Net SLS Transaction Value'  as col_header , 'NSTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(a.xn_value_without_gst) ' as  COL_EXPR ,'Net SLS Transaction Value (W/O GST)'  as col_header , 'NSTRANWOGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(CASE WHEN ISNULL(ecoupon_id,'')<>'' THEN rfnet ELSE 0 END)' as  COL_EXPR ,'Net WizClip Realized Value'  as col_header , 'NSWCLPRV'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'ROUND((SUM(CASE WHEN ISNULL(ecoupon_id,'')<>'' THEN rfnet ELSE 0 END)/SUM(rfnet))*100,2)' as  COL_EXPR ,'WizClip Contribution %'  as col_header , 'NSWCLCONPER'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(rfnet+(CASE WHEN ISNULL(ecoupon_id,'') = '' THEN 0 ELSE cmm_discount_amount   END))' as  COL_EXPR ,'Realized Value Without Coupon Disc'  as col_header , 'NSWCD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(CASE WHEN ISNULL(ecoupon_id,'')<>'' THEN cmm_discount_amount ELSE 0 END)' as  COL_EXPR ,'Wizclip Discount'  as col_header , 'ECPNDA'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)  
Select  'Retail Sale' as xn_type,'SUM(tax_round_off)' as  COL_EXPR ,'Net Tax Round Off'  as col_header , 'NETTAXROND'

	
INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(a.cm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Retail Sale' xn_type,'' as joining_table


--CHO WSL

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Challan Out(WSL)' xn_type,'' as joining_table 

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'CHO Qty'  as col_header , 'CRQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net Ch Qty'  as col_header , 'NCQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'CHO Val at PP'  as col_header , 'CRP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'CHO Val at LC'  as col_header , 'CRLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'CHO Val at WSP'  as col_header , 'CRW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'CHO Val at MRP'  as col_header , 'CRM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'CHO Val at XFP'  as col_header , 'CRXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'CHO Val at Current XFP'  as col_header , 'CRXPC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'CHO Tax Amt'  as col_header , 'CRTAXAMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'CHO Val at XFP (W/O GST)'  as col_header , 'CRXPWGST'




--CHO PRT
INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Challan Out(PRT)' xn_type,'' as joining_table



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'CHO Qty'  as col_header , 'CRQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net Ch Qty'  as col_header , 'NCQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'CHO Val at PP'  as col_header , 'CRP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'CHO Val at LC'  as col_header , 'CRLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'CHO Val at WSP'  as col_header , 'CRW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'CHO Val at MRP'  as col_header , 'CRM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'CHO Val at XFP'  as col_header , 'CRXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'CHO Val at Current XFP'  as col_header , 'CRXPC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'CHO Tax Amt'  as col_header , 'CRTAXAMT'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'CHO Val at XFP (W/O GST)'  as col_header , 'CRXPWGST'

--CHI PUR

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Challan In(PUR)' xn_type,'' as joining_table

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sku_names.ws_price))' as  COL_EXPR ,'CHI Val at WSP'  as col_header , 'CHIWSP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sku_names.pp))' as  COL_EXPR ,'CHI Val at PP'  as col_header , 'CPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sku_names.lc))' as  COL_EXPR ,'CHI Val at LC'  as col_header , 'CPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sku_names.mrp))' as  COL_EXPR ,'CHI Val at MRP'  as col_header , 'CPM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sxfp.XFER_PRICE))' as  COL_EXPR ,'CHI Val at XFP'  as col_header , 'CPXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*(sxfp.xfer_price_without_gst))' as  COL_EXPR ,'CHI Val at XFP (W/O GST)'  as col_header , 'CPXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'CHI Qty'  as col_header , 'CPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net Ch Qty'  as col_header , 'NCQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.igst_amount+a.cgst_amount+a.sgst_amount)' as  COL_EXPR ,'CHI Tax Amt'  as col_header , 'CPTAXAMT'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'b.dept_id' AS keyfield,table_caption AS col_header ,
'Challan In(PUR)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

--CHI WSR

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Challan In(WSR)' xn_type,'' as joining_table


INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)          
SELECT 'LOC'+column_name as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
'Challan In(WSR)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sku_names.ws_price))' as  COL_EXPR ,'CHI Val at WSP'  as col_header , 'CHIWSP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'CHI Qty'  as col_header , 'CPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net Ch Qty'  as col_header , 'NCQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sku_names.pp))' as  COL_EXPR ,'CHI Val at PP'  as col_header , 'CPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sku_names.lc))' as  COL_EXPR ,'CHI Val at LC'  as col_header , 'CPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sku_names.mrp))' as  COL_EXPR ,'CHI Val at MRP'  as col_header , 'CPM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sxfp.XFER_PRICE))' as  COL_EXPR ,'CHI Val at XFP'  as col_header , 'CPXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'CHI Val at XFP (W/O GST)'  as col_header , 'CPXPWGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.quantity*(sxfp.CURRENT_XFER_PRICE))' as  COL_EXPR ,'CHI Val at Current XFP'  as col_header , 'CPXPC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(wsr)' as xn_type,'SUM(a.igst_amount+a.cgst_amount+a.sgst_amount)' as  COL_EXPR ,'CHI Tax Amt'  as col_header , 'CPTAXAMT'




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'APP Val at LC'  as col_header , 'APPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'APP Qty'  as col_header , 'APQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'APP Val at PP'  as col_header , 'APP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'APP Val at MRP'  as col_header , 'APPVM'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Approval Issue' xn_type,'' as joining_table

--APR

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'APR Val at LC'  as col_header , 'CMALC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'APR Qty'  as col_header , 'ARQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'APR Val at PP'  as col_header , 'ARP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'APR Val at MRP'  as col_header , 'ARM'



--NET_APP

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net APP Qty'  as col_header , 'NAQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net APP Qty'  as col_header , 'NAQ'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'Net APP Val at MRP'  as col_header , 'NAPMRP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'Net APP Val at MRP'  as col_header , 'NAPMRP'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'Net APP Val at PP'  as col_header , 'NAP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.pp)*-1' as  COL_EXPR ,'Net APP Val at PP'  as col_header , 'NAP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Issue' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Net APP Val at WSP'  as col_header , 'NAPWSP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Approval Return' as xn_type,'SUM(a.quantity*sku_names.ws_price)*-1' as  COL_EXPR ,'Net APP Val at WSP'  as col_header , 'NAPWSP'


--NET CHI

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)  
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Challan Out(WSL)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'Net CH Val at Current XFP'  as col_header , 'NCXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'Net CH Val at Current XFP'  as col_header , 'NCXPC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)*-1' as  COL_EXPR ,'Net CH Val at Current XFP'  as col_header , 'NCXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)*-1' as  COL_EXPR ,'Net CH Val at Current XFP'  as col_header , 'NCXPC'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)          
SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
'Challan Out(PRT)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'Net CH Val at LC'  as col_header , 'NCLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'Net CH Val at LC'  as col_header , 'NCLC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.lc)*-1' as  COL_EXPR ,'Net CH Val at LC'  as col_header , 'NCLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.lc)*-1' as  COL_EXPR ,'Net CH Val at LC'  as col_header , 'NCLC'




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'Net CH Val at MRP'  as col_header , 'NCM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'Net CH Val at MRP'  as col_header , 'NCM'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'Net CH Val at MRP'  as col_header , 'NCM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'Net CH Val at MRP'  as col_header , 'NCM'




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'Net CH Val at PP'  as col_header , 'NCP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'Net CH Val at PP'  as col_header , 'NCP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.pp)*-1' as  COL_EXPR ,'Net CH Val at PP'  as col_header , 'NCP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.pp)*-1' as  COL_EXPR ,'Net CH Val at PP'  as col_header , 'NCP1'





INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Net CH Val at WSP'  as col_header , 'NCHRW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Net CH Val at WSP'  as col_header , 'NCHRW'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sku_names.ws_price)*-1' as  COL_EXPR ,'Net CH Val at WSP'  as col_header , 'NCHRW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sku_names.ws_price)*-1' as  COL_EXPR ,'Net CH Val at WSP'  as col_header , 'NCHRW'




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE)' as  COL_EXPR ,'Net CH Val at XFP'  as col_header , 'NCXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE)' as  COL_EXPR ,'Net CH Val at XFP'  as col_header , 'NCXP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE)*-1' as  COL_EXPR ,'Net CH Val at XFP'  as col_header , 'NCXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE)*-1' as  COL_EXPR ,'Net CH Val at XFP'  as col_header , 'NCXP'




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(PUR)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'Net CHI Val at XFP (W/O GST)'  as col_header , 'NCXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan In(WSR)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'Net CHI Val at XFP (W/O GST)'  as col_header , 'NCXPWGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(WSL)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)*-1' as  COL_EXPR ,'Net CHI Val at XFP (W/O GST)'  as col_header , 'NCXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Challan Out(PRT)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)*-1' as  COL_EXPR ,'Net CHI Val at XFP (W/O GST)'  as col_header , 'NCXPWGST'




--



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Approval Return' xn_type,'' as joining_table

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name)     
SELECT 'a.apd_product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
'Approval Return' xn_type,'' as joining_table,'' joining_column,'Product_code'

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name)     
SELECT 'LEFT(a.apd_product_code, ISNULL(NULLIF(CHARINDEX (''@'',a.apd_product_code)-1,-1),LEN(a.apd_product_code )))' as COL_EXPR,'' AS keyfield,
'Item Code (w/o Batch)' AS col_header ,
'Approval Return' xn_type,'' as joining_table,'' joining_column,'PRODUCT_CODE_WB'
	
			
--JWI


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Issue' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'JWI Qty'  as col_header , 'JWIOQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Issue' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'JWI Val at PP'  as col_header , 'JWIOP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Issue' as xn_type,'SUM(A.quantity*sku_names.mrp)' as  COL_EXPR ,'JWI Val at MRP'  as col_header , 'JWIOM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)1' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net JW Qty'  as col_header , 'NJWOQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)1' as xn_type,'SUM(A.quantity*sku_names.mrp)' as  COL_EXPR ,'Net JW at MRP'  as col_header , 'NJWOM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)1' as xn_type,'SUM(A.quantity*sku_names.PP)' as  COL_EXPR ,'Net JW AT PP'  as col_header , 'NJWOP'





--JWR
	
INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Receive' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'JWR Qty'  as col_header , 'JWROQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Receive' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'JWR Val at PP'  as col_header , 'JWROP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work Receive' as xn_type,'SUM(A.quantity*sku_names.mrp)' as  COL_EXPR ,'JWR Val at MRP'  as col_header , 'JWROM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)2' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net JW Qty'  as col_header , 'NJWOQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)2' as xn_type,'SUM(A.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'Net JW at MRP'  as col_header , 'NJWOM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Job Work(Net)2' as xn_type,'SUM(A.quantity*sku_names.PP)*-1' as  COL_EXPR ,'Net JW AT PP'  as col_header , 'NJWOP'


--PUR

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net PUR Qty'  as col_header , 'NPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net PUR Qty'  as col_header ,'NPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.pp)' as  COL_EXPR ,'Net PUR Val at PP'  as col_header , 'NPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.pp)*-1' as  COL_EXPR ,'Net PUR Val at PP'  as col_header ,'NPP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.ws_price)' as  COL_EXPR ,'Net PUR Val at WSP'  as col_header , 'NPW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.ws_price)*-1' as  COL_EXPR ,'Net PUR Val at WSP'  as col_header ,'NPW'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.lc)' as  COL_EXPR ,'Net PUR Val at LC'  as col_header , 'NPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.lc)*-1' as  COL_EXPR ,'Net PUR Val at LC'  as col_header ,'NPLC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.mrp)' as  COL_EXPR ,'Net PUR Val at MRP'  as col_header , 'NPM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.mrp)*-1' as  COL_EXPR ,'Net PUR Val at MRP'  as col_header ,'NPM'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'Net Pur Tax/GST Amt'  as col_header , 'NPTAXAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount) * -1' as  COL_EXPR ,'Net Pur Tax/GST Amt'  as col_header ,'NPTAXAMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'Net PUR Transaction Value'  as col_header , 'NPTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(a.xn_value_with_gst) *-1' as  COL_EXPR ,'Net PUR Transaction Value'  as col_header ,'NPTRANVALUE'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)1' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'Net PUR Transaction Value (W/O GST)'  as col_header , 'NPTRANWOGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Net)2' as xn_type,'SUM(a.xn_value_without_gst)*-1' as  COL_EXPR ,'Net PUR Transaction Value (W/O GST)'  as col_header ,'NPTRANWOGST'




INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'b.dept_id' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Purchase(Net)1' xn_type,'' as joining_table

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Purchase(Net)2' xn_type,'' as joining_table

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'PUR Qty'  as col_header , 'PPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'PUR Val at PP'  as col_header , 'PPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.quantity*sku_names.LC)' as  COL_EXPR ,'PUR Val at LC'  as col_header , 'PPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'PUR Val at MRP'  as col_header , 'PPM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'Pur Tax/GST Amt'  as col_header , 'PUTAXA'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'PUR Val at WSP'  as col_header , 'PPW'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'PUR Transaction Value'  as col_header , 'PURTRANVALUE'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Purchase(Gross)' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'PUR Transaction Value (W/O GST)'  as col_header , 'PURTRANWOGST'




INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Purchase(Gross)' xn_type,'' as joining_table



--PRT

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'PRT Qty'  as col_header , 'PRQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'PRT Val at PP'  as col_header , 'PRP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'PRT Val at LC'  as col_header , 'PRLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'PRT Val at MRP'  as col_header , 'PRM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'PRT Tax/GST Amt'  as col_header , 'PRTAXA'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'PRT Val at WSP'  as col_header , 'PRW'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'PRT Transaction Value'  as col_header , 'PRTTRANVALUE'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Debit Note (Party)' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'PRT Transaction Value (W/O GST)'  as col_header , 'PRTTRANWOGST'




INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Debit Note (Party)' xn_type,'' as joining_table

--WSL

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'WSL Qty'  as col_header , 'WPQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net Wsl Qty'  as col_header , 'NWQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(A.QUANTITY*sku_names.pp)' as  COL_EXPR ,'Net Wsl Val at PP'  as col_header , 'NWP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'WSL Val at PP'  as col_header , 'WPP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'WSL Val at LC'  as col_header , 'WPLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'WSL Val at WSP'  as col_header , 'WPNW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'WSL val at MRP'  as col_header , 'WPM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.rfnet)' as  COL_EXPR ,'WSL value at Net Rate'  as col_header , 'GWSLNETRATE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name)
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'WSL Val at XFP'  as col_header , 'WSLRXP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst) *-1' as  COL_EXPR ,'WSL Val at XFP (W/O GST)'  as col_header , 'WSLCRXPWGSTC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'WSL Val at Current XFP'  as col_header , 'WSLCRXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'WSL Tax/GST Amt'  as col_header , 'WSLTAXAMT'


--NET_WSL

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'Net WSL Tax/GST Amt'  as col_header , 'NWTAXAMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount) *-1' as  COL_EXPR ,'Net WSL Tax/GST Amt'  as col_header , 'NWTAXAMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'Net WSL Transaction Value'  as col_header , 'NWSLTRANVALUE'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.xn_value_with_gst)*-1' as  COL_EXPR ,'Net WSL Transaction Value'  as col_header , 'NWSLTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'Net WSL Transaction Value (W/O GST)'  as col_header , 'NWSLTRANWOGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.xn_value_without_gst) *-1' as  COL_EXPR ,'Net WSL Transaction Value (W/O GST)'  as col_header , 'NWSLTRANWOGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'Net WSL Val at Current XFP'  as col_header , 'NWCXFP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE) *-1' as  COL_EXPR ,'Net WSL Val at Current XFP'  as col_header , 'NWCXFP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'Net WSL Val at LC'  as col_header , 'NWLC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.lc)*-1' as  COL_EXPR ,'Net WSL Val at LC'  as col_header , 'NWLC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'Net WSL Val at MRP'  as col_header , 'NWM'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'Net WSL Val at MRP'  as col_header , 'NWM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'Net WSL Val at WSP'  as col_header , 'NWNW'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.ws_price)*-1' as  COL_EXPR ,'Net WSL Val at WSP'  as col_header , 'NWNW'







INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE)' as  COL_EXPR ,'Net WSL Val at XFP'  as col_header , 'NWXFP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sxfp.XFER_PRICE) *-1' as  COL_EXPR ,'Net WSL Val at XFP'  as col_header , 'NWXFP'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'Net WSL Val at XFP (W/O GST)'  as col_header , 'NWCXPWGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst) *-1' as  COL_EXPR ,'Net WSL Val at XFP (W/O GST)'  as col_header , 'NWCXPWGST'





--END




INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'WSL Transaction Value'  as col_header , 'WSLTRANVALUE'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale (Party)' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'WSL Transaction Value (W/O GST)'  as col_header , 'WSLTRANWOGST'



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Wholesale (Party)' xn_type,'' as joining_table


--WSR


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'WSR Qty'  as col_header , 'WRQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net Wsl Qty'  as col_header , 'NWQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(A.QUANTITY*sku_names.pp)*-1' as  COL_EXPR ,'Net Wsl Val at PP'  as col_header , 'NWP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'WSR Val at PP'  as col_header , 'WRP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'WSR Val at LC'  as col_header , 'WRLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'WSR val at MRP'  as col_header , 'WRM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.rfnet)' as  COL_EXPR ,'WSR value at Net Rate'  as col_header , 'GWSRNETRATE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sku_names.ws_price)' as  COL_EXPR ,'WSR Val at WSP'  as col_header , 'WRNW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sxfp.xfer_price)' as  COL_EXPR ,'WSR Val at XFP'  as col_header , 'WSRRXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.quantity*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'WSR Val at Current XFP'  as col_header , 'WSRCRXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(A.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'WSR Tax/GST Amt'  as col_header , 'WSRTAXAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.xn_value_with_gst) ' as  COL_EXPR ,'WSR Transaction Value'  as col_header , 'WSRTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Credit Note(Gross)' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'WSR Transaction Value (W/O GST)'  as col_header , 'WSRTRANWOGST'


--NET_WLS


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'Net WSL Qty'  as col_header , 'NWQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'Net WSL Qty'  as col_header ,'NWQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.pp)' as  COL_EXPR ,'Net WSL Val at PP'  as col_header , 'NWP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.pp)*-1' as  COL_EXPR ,'Net WSL Val at PP'  as col_header ,'NWP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.ws_price)' as  COL_EXPR ,'Net WSL Val at WSP'  as col_header , 'NWW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.ws_price)*-1' as  COL_EXPR ,'Net WSL Val at WSP'  as col_header ,'NWW'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.lc)' as  COL_EXPR ,'Net WSL Val at LC'  as col_header , 'NWLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.lc)*-1' as  COL_EXPR ,'Net WSL Val at LC'  as col_header ,'NWLC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(A.QUANTITY*sku_names.mrp)' as  COL_EXPR ,'Net WSL Val at MRP'  as col_header , 'NWM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(A.QUANTITY*sku_names.mrp)*-1' as  COL_EXPR ,'Net WLS Val at MRP'  as col_header ,'NWM'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount)' as  COL_EXPR ,'Net WSL Tax/GST Amt'  as col_header , 'NWTAXAMT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(a.igst_amount+a.sgst_amount+a.cgst_amount) * -1' as  COL_EXPR ,'Net WLS Tax/GST Amt'  as col_header ,'NWTAXAMT'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(a.xn_value_with_gst)' as  COL_EXPR ,'Net WSL Transaction Value'  as col_header , 'NWSLTRANVALUE'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(a.xn_value_with_gst) *-1' as  COL_EXPR ,'Net WSL Transaction Value'  as col_header ,'NWSLTRANVALUE'



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)1' as xn_type,'SUM(a.xn_value_without_gst)' as  COL_EXPR ,'Net WSL Transaction Value (W/O GST)'  as col_header , 'NWSLTRANWOGST'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Wholesale(Net)2' as xn_type,'SUM(a.xn_value_without_gst)*-1' as  COL_EXPR ,'Net WSL Transaction Value (W/O GST)'  as col_header ,'NWSLTRANWOGST'




INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table)     
SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Credit Note(Gross)' xn_type,'' as joining_table

--STOCK



INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty)' as  COL_EXPR ,'CBS Qty'  as col_header , 'CBS'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*alt_uom_conversion_factor)' as  COL_EXPR ,'CBS Qty (Alt. UOM)'  as col_header , 'CBS_AU'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(isnull(sxfp.xfer_price_without_gst,0)))' as  COL_EXPR ,'CBS Val at  XFP(W/O DP)'  as col_header , 'CBXFDEP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(sxfp.xfer_price_without_gst + isnull(sxfp.xfer_depreciation,0)))' as  COL_EXPR ,'CBS Val at  XFP(W/O GST)'  as col_header , 'CBXPWG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.lc) ' as  COL_EXPR ,'CBS Val at LC'  as col_header , 'CBLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.mrp)' as  COL_EXPR ,'CBS Val at MRP'  as col_header , 'CBM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*((CASE WHEN 1=1 THEN SKU_NAMES.PP ELSE sxfp.loc_pp END)-ISNULL(c.depcn_value,0)-ISNULL(c.prev_depcn_value,0)))' as  COL_EXPR ,'CBS Val at PP'  as col_header , 'CBP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,' SUM(a.cbs_qty*sku_names.PP_WO_DP)' as  COL_EXPR ,'CBS Value at PP(W/O DEP.)'  as col_header , 'CBPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.ws_price) ' as  COL_EXPR ,'CBS Val at WSP'  as col_header , 'CBW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(sxfp.xfer_price + isnull(sxfp.xfer_depreciation,0))) ' as  COL_EXPR ,'CBS Val at XFP'  as col_header , 'CBXP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*((CASE WHEN A.DEPT_ID = [GHOLOCATION] OR ISNULL(sxfp.loc_pp,0)=0 THEN SKU_NAMES.PP ELSE sxfp.loc_pp END)))' as  COL_EXPR ,'CBS Val at Sec PP'  as col_header , 'CBSP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'COUNT(DISTINCT CASE WHEN  a.cbs_qty  <>0 THEN  SKU_NAMES.PRODUCT_CODE ELSE NULL END )' as  COL_EXPR ,'CBS Thaan'  as col_header , 'CBS_CNT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty)' as  COL_EXPR ,'OBS Qty'  as col_header , 'OBS'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(isnull(sxfp.xfer_price_without_gst,0)))' as  COL_EXPR ,'OBS Val at  XFP(W/O DP)'  as col_header , 'OBXFDEP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(sxfp.xfer_price_without_gst + isnull(sxfp.xfer_depreciation,0)))' as  COL_EXPR ,'OBS Val at  XFP(W/O GST)'  as col_header , 'OBXPWG'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.lc)' as  COL_EXPR ,'OBS Val at LC'  as col_header , 'OBLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.mrp)' as  COL_EXPR ,'OBS Val at MRP'  as col_header , 'OBM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*((CASE WHEN 1=1 THEN SKU_NAMES.PP ELSE sxfp.loc_pp END)-ISNULL(c.depcn_value,0)-ISNULL(c.prev_depcn_value,0)))' as  COL_EXPR ,'OBS Val at PP'  as col_header , 'OBP1'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,' SUM(a.cbs_qty*sku_names.PP_WO_DP)' as  COL_EXPR ,'OBS Value at PP(W/O DEP.)'  as col_header , 'OBPWD'





INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*sku_names.ws_price)' as  COL_EXPR ,'OBS Val at WSP'  as col_header , 'OBW'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*(sxfp.xfer_price + isnull(sxfp.xfer_depreciation,0)))' as  COL_EXPR ,'OBS Val at XFP'  as col_header , 'OBXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'SUM(a.cbs_qty*((CASE WHEN A.DEPT_ID = [GHOLOCATION] OR ISNULL(sxfp.loc_pp,0)=0 THEN SKU_NAMES.PP ELSE sxfp.loc_pp END)))' as  COL_EXPR ,'OBS Val at Sec PP'  as col_header , 'OBSP'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock' as xn_type,'COUNT(DISTINCT CASE WHEN  a.cbs_qty  <>0 THEN  SKU_NAMES.PRODUCT_CODE ELSE NULL END )' as  COL_EXPR ,'OBS Thaan'  as col_header , 'OBS_CNT'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name,multi_column_based) 
Select  'Stock' as xn_type,'(CASE WHEN (NSQ+CBS)<>0 then (NSQ/(NSQ+CBS))*100 ELSE 0 END)' as  COL_EXPR ,'Sell Thru Quantity %'  as col_header , 'STHP',1 multi_column_based


--Inter Bin Transfer Out

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer Out' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'FCO Val at PP(W/O DEP.)'  as col_header , 'FCPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer Out' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'FCO Qty'  as col_header , 'FCO'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer Out' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'FCO Val at PP'  as col_header , 'FCOP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer Out' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'FCO Val at MRP'  as col_header , 'FCOM'



--Inter Bin Transfer IN

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer In' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'FCI Val at PP(W/O DEP.)'  as col_header , 'FCIPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer In' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'FCI Qty'  as col_header , 'FCI'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer In' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'FCI Val at PP'  as col_header , 'FCIP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Inter Bin Transfer In' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'FCI Val at MRP'  as col_header , 'FCIM'

--Split/Combine

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Split/Combine' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'SCF Val at PP(W/O DEP.)'  as col_header , 'FCIPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Split/Combine' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'SCF Qty'  as col_header , 'FCI'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Split/Combine' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'SCF Val at PP'  as col_header , 'FCIP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Split/Combine' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'SCF Val at MRP'  as col_header , 'FCIM'


--CNC
INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'CNC Val at PP(W/O DEP.)'  as col_header , 'CNPPWD'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'CNC Qty'  as col_header , 'CNQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'CNC Val at PP'  as col_header , 'CNP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'CNC Val at LC'  as col_header , 'CNLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'CNC Val at MRP'  as col_header , 'CNCVM'


--UNC

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'UNC Val at PP(W/O DEP.)'  as col_header , 'UNCPPWD'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'UNC Qty'  as col_header , 'UNQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(a.quantity*sku_names.pp)' as  COL_EXPR ,'UNC Val at PP'  as col_header , 'UNP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(a.quantity*sku_names.lc)' as  COL_EXPR ,'UNC Val at LC'  as col_header , 'UNLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(a.quantity*sku_names.mrp)' as  COL_EXPR ,'UNC Val at MRP'  as col_header , 'UNM'



--NET_CNC


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM(A.QUANTITY)' as  COL_EXPR ,'NCN Qty'  as col_header , 'NQC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM(A.QUANTITY)*-1' as  COL_EXPR ,'NCN Qty'  as col_header , 'NQC'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM((a.quantity*sku_names.lc)' as  COL_EXPR ,'NCN Val at LC'  as col_header , 'NQLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM((a.quantity*sku_names.lc)*-1' as  COL_EXPR ,'NCN Val at LC'  as col_header , 'NQLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM((a.quantity*sku_names.mrp)' as  COL_EXPR ,'NCN Val at MRP'  as col_header , 'NQM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM((a.quantity*sku_names.mrp)*-1' as  COL_EXPR ,'NCN Val at MRP'  as col_header , 'NQM'


INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock Cancellation' as xn_type,'SUM((a.quantity*sku_names.pp)' as  COL_EXPR ,'NCN Val at PP'  as col_header , 'NQP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'Stock UnCancellation' as xn_type,'SUM((a.quantity*sku_names.pp)*-1' as  COL_EXPR ,'NCN Val at PP'  as col_header , 'NQP1'



--GIT

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sku_names.ws_price)' as  COL_EXPR ,'GIT Val at WSP'  as col_header , 'GITWSP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sxfp.xfer_price_without_gst)' as  COL_EXPR ,'GIT Val at XFP (W/O GST)'  as col_header , 'GITXPWGST'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(A.git_qty)' as  COL_EXPR ,'GIT Qty'  as col_header , 'GITQ'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_pp)' as  COL_EXPR ,'GIT Val at PP'  as col_header , 'GITP1'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sku_names.lc)' as  COL_EXPR ,'GIT Val at LC'  as col_header , 'GITLC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sku_names.mrp)' as  COL_EXPR ,'GIT Val at MRP'  as col_header , 'GITM'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sxfp.xfer_price)' as  COL_EXPR ,'GIT Val at XFP'  as col_header , 'GITXP'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.git_qty*sxfp.CURRENT_XFER_PRICE)' as  COL_EXPR ,'GIT Val at Current XFP'  as col_header , 'GITXPC'

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select  'GIT' as xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as  COL_EXPR ,'GIT Val at PP(W/O DEP.)'  as col_header , 'GITPWD'








--COMMON

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'article_no' as COL_EXPR,'a.product_code' AS keyfield,'Article no.' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'sn_article_desc' as COL_EXPR,'a.product_code' AS keyfield,'Article Desc' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3,'article_desc' col_name

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'article_name' as COL_EXPR,'a.product_code' AS keyfield,'Article Name.' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'article_alias' as COL_EXPR,'a.product_code' AS keyfield,'Article Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'sku_item_type_desc' as COL_EXPR,'a.product_code' AS keyfield,'Item Type' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3,'sku_item_type' col_name

	--Anil

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'sn_barcode_coding_scheme' as COL_EXPR,'a.product_code' AS keyfield,'Coding Scheme ' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,4



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'uom' as COL_EXPR,'a.product_code' AS keyfield,'Uom Name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,4,'UOM_NAME'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'alternate_uom_name' as COL_EXPR,'a.product_code' AS keyfield,'Alternate Uom Name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,4,'alternate_uom_name'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'sub_section_name' as COL_EXPR,'a.product_code' AS keyfield,'Sub Section Name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,2

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'sub_Section_alias' as COL_EXPR,'a.product_code' AS keyfield,'Sub Section Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,2,'sectd_alias'


INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'section_name' as COL_EXPR,'a.product_code' AS keyfield,'Section Name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'section_alias' as COL_EXPR,'a.product_code' AS keyfield,'Section Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,1,'sectm_alias' col_name

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para1_name' as COL_EXPR,'a.product_code' AS keyfield,'Para1 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para2_name' as COL_EXPR,'a.product_code' AS keyfield,'Para2 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para3_name' as COL_EXPR,'a.product_code' AS keyfield,'Para3 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para4_name' as COL_EXPR,'a.product_code' AS keyfield,'Para4 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para5_name' as COL_EXPR,'a.product_code' AS keyfield,'Para5 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para6_name' as COL_EXPR,'a.product_code' AS keyfield,'Para6 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para1_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para2_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para3_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para3 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para4_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para4 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para5_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para5 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para6_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para6 Alias' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para1_set' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Set' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.2

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'para2_set' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Set' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.2

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'MRP' as COL_EXPR,'a.product_code' AS keyfield,'MRP' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.3,'MRP'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'pp' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Price' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.3,'PP'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ws_price' as COL_EXPR,'a.product_code' AS keyfield,'Wholesale Price' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.4

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR1_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR1 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,11

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR2_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR2 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,12

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR3_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR3 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR4_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR4 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR5_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR5 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,14

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR6_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR6 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,15

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR7_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR7 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,16

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR8_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR8 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,17

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR9_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR9 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,18

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR10_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR10 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,19

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR11_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR11 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,20

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR12_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR12 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,21
INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR13_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR13 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,22

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR14_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR14 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,23

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR15_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR15 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR16_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR16 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,25

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR17_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR17 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR18_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR18 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,26

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR19_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR19 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,27

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR20_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR20 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,28

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR21_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR21 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,29

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR22_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR22 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,30

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR23_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR23 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,31

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR24_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR24 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,32

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ATTR25_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR25 name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33


INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'sku_er_flag' as COL_EXPR,'a.product_code' AS keyfield,'Er Flag' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'hsn_code' as COL_EXPR,'a.product_code' AS keyfield,'HSN/SAC Code' AS col_header ,
'Common' xn_type,'sku' as joining_table,'product_code' joining_column,34,'hsn_code'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'gst_percentage' as COL_EXPR,'a.product_code' AS keyfield,'GST %' AS col_header ,
'Common' xn_type,'sku' as joining_table,'product_code' joining_column,34,'gst_percentage'


INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name)     
SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,'Product_code'






INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name)     
SELECT 'LEFT(a.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',a.PRODUCT_CODE)-1,-1),LEN(a.PRODUCT_CODE )))' as COL_EXPR,'' AS keyfield,
'Item Code (W/O Batch)' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,'PRODUCT_CODE_WB'


INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name)     
SELECT 'a.bin_id' as COL_EXPR,'' AS keyfield,'Bin Id' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,'bin_id'



INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Bin Name' AS col_header ,
'Common' xn_type,'bin' as joining_table,'bin_id' joining_column

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'BIN_ALIAS' as COL_EXPR,'a.bin_id' AS keyfield,'BIN ALIAS' AS col_header ,
'Common' xn_type,'bin' as joining_table,'bin_id' joining_column

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'ac_name' as COL_EXPR,'a.product_code' AS keyfield,'Supplier Name' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'PURCHASE_BILL_DT' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Bill Date' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'purchase_receipt_Dt' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Receipt Date' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'PURCHASE_BILL_NO' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Bill no.' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33,'inv_no'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'purchase_challan_no' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Challan no.' AS col_header ,
'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33,'challan_no'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,joining_column,
addnl_join,Col_order)     
SELECT 'area_name' as COL_EXPR,'lmp_area.area_code' AS keyfield,'Supplier Area' AS col_header ,
'Common' as xn_type,'area' as joining_table,'lmp_area' as joining_table_alias,'area_code' joining_column,
' JOIN lmp01106 lmpa_supp (NOLOCK) ON lmpa_supp.ac_code=sku_names.ac_code' addnl_join,40

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,joining_column,
addnl_join,Col_order)     
SELECT 'city' as COL_EXPR,'lmpc_city.city_code' AS keyfield,'Supplier City' AS col_header ,
'Common' as xn_type,'city' as joining_table,'lmpc_city' as joining_table_alias,'city_code' joining_column,
' JOIN lmp01106 lmpc_supp (NOLOCK) ON lmpc_supp.ac_code=sku_names.ac_code
JOIN area lmpc_area (NOLOCK) ON lmpc_area.area_code=lmpc_supp.area_code' addnl_join,41

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,
joining_column,addnl_join,Col_order)     
SELECT 'state' as COL_EXPR,'lmps_state.state_code' AS keyfield,'Supplier State' AS col_header ,
'Common' as xn_type,'state' as joining_table,'lmps_state' as joining_table_alias,'state_code' joining_column,
' JOIN lmp01106 lmps_supp (NOLOCK) ON lmps_supp.ac_code=sku_names.ac_code
JOIN area lmps_area (NOLOCK) ON lmps_area.area_code=lmps_supp.area_code
JOIN city lmps_city(NOLOCK) ON lmps_city.city_code=lmps_area.city_code' addnl_join,41.1

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'Location Id' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column



INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'dept_alias' as COL_EXPR, col_expr AS keyfield,'Location Alias' AS col_header ,
xn_type,'location' as joining_table,'dept_id' joining_column
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'area_name' as COL_EXPR,col_expr AS keyfield,'Location Area' AS col_header ,
xn_type,'#loc_view' as joining_table,'dept_id' joining_column
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id'
AND xn_type<>'common'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'city' as COL_EXPR,col_expr AS keyfield,'Location City' AS col_header ,
xn_type,'#loc_view' as joining_table,'dept_id' joining_column
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id'
AND xn_type<>'common'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'state' as COL_EXPR,col_expr AS keyfield,'Location State' AS col_header ,
xn_type,'#loc_view' as joining_table,'dept_id' joining_column
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id'
AND xn_type<>'common'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'region_name' as COL_EXPR,col_expr AS keyfield,'Location Region' AS col_header ,
xn_type,'#loc_view' as joining_table,'dept_id' joining_column
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id'
AND xn_type<>'common'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,col_name)     
SELECT 'dept_name' as COL_EXPR,col_expr AS keyfield,'Location Name' AS col_header ,
xn_type,'dept_id' joining_column,'location' as joining_table,'dept_name' as col_name
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id' 
AND xn_type<>'Stock'

INSERT #transaction_analysis_master_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,col_name)     
SELECT 'location.inactive' as COL_EXPR,col_expr AS keyfield,'Location InActive' AS col_header ,
xn_type,'dept_id' joining_column,'location' as joining_table,'inactive' as col_name
FROM #transaction_analysis_master_COLS_stk WHERE col_header='Location Id' 
AND xn_type NOT IN ('COMMON','Stock')

INSERT #transaction_analysis_calculative_COLS_stk (xn_type,col_expr,col_header,col_name) 
Select DISTINCT 'Stock' as xn_type,'' as  COL_EXPR ,col_header , '' col_name
FROM #transaction_analysis_calculative_COLS_stk WHERE col_header 
NOT IN (SELECT COL_HEADER FROM #transaction_analysis_calculative_COLS_stk WHERE xn_type in ('Common','Stock'))


INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT '''''' as COL_EXPR,'' AS keyfield,'Image' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,63


INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'EOSS_CATEGORY' as COL_EXPR,'' AS keyfield,'Eoss Category' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,64

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,col_name)     
SELECT 'tc.DISCOUNT_PERCENTAGE' as COL_EXPR,'' AS keyfield,'Eoss Discount %' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,64,'eoss_discount_percentage'

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'EOSS_DISCOUNT_AMOUNT' as COL_EXPR,'' AS keyfield,'Eoss Discount Amt' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,64

INSERT #transaction_analysis_MASTER_COLS_stk	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
SELECT 'Eoss_scheme_name' as COL_EXPR,'' AS keyfield,'Eoss Scheme Name' AS col_header ,
'Common' xn_type,'' as joining_table,'' joining_column,64

			

INSERT #transaction_analysis_derived_COLS_link_stk (rep_type,col_name,linked_col_name) 
Select 'Stock',  'STHP' as xn_type,'NSQ' linked_col_name

INSERT #transaction_analysis_derived_COLS_link_stk (rep_type,col_name,linked_col_name) 
Select  'Stock','STHP' as xn_type,'CBS' linked_col_name

UPDATE #transaction_analysis_MASTER_COLS_stk set COL_expr=b.table_caption from #transaction_analysis_MASTER_COLS_stk a
JOIN config_locattr b ON a.col_expr=b.column_name

--select * from transaction_analysis_MASTER_COLS where COL_EXPR='xn_type'
UPDATE #transaction_analysis_MASTER_COLS_stk SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
where isnull(col_name,'')=''
UPDATE #transaction_analysis_calculative_COLS_stk SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
where isnull(col_name,'')=''

UPDATE #transaction_analysis_MASTER_COLS_stk set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
UPDATE #transaction_analysis_calculative_COLS_stk set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
UPDATE transaction_analysis_stock_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')

UPDATE a SET datecol=1 from #transaction_analysis_MASTER_COLS_stk a 
left join config_locattr b on a.col_expr=b.table_caption
left join config_locattr c on a.col_expr='loc'+c.column_name
WHERE (right(col_name,4)='DATE' OR RIGHT(COL_HEADER,4)='DATE') and b.table_caption IS NULL and c.table_caption is null


UPDATE #transaction_analysis_MASTER_COLS_stk SET joining_table_alias='lv' where joining_table='#loc_view'




UPDATE #transaction_analysis_MASTER_COLS_stk SET col_name=col_expr where 
col_name NOT IN ('image','Supplier_name','ageing_1','ageing_2','ageing_3','Group_supplier','sectd_alias','sectm_alias',
'gst_percentage','hsn_code','bin_id','Product_code','inv_no','challan_no','PRODUCT_CODE_WB','UOM_NAME','alternate_uom_name',
'article_desc','eoss_discount_percentage','sku_item_type')

UPDATE #transaction_analysis_MASTER_COLS_stk SET col_name='major_dept_id' WHERE col_header='Location Id'

INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header,col_name, group_xn_type, rep_type,multi_column_based )
SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'STOCK' rep_type ,multi_column_based
FROM #transaction_analysis_calculative_COLS_stk 


delete from #transaction_analysis_MASTER_COLS_stk where col_name=''

INSERT transaction_analysis_MASTER_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
group_xn_type, datecol, Col_order, joining_table_alias,'STOCK' rep_type 
FROM #transaction_analysis_MASTER_COLS_stk

INSERT INTO transaction_analysis_derived_COLS_link (REP_TYPE,col_name,linked_col_name)
SELECT rep_type,col_name,linked_col_name FROM  #transaction_analysis_derived_COLS_link_stk

END