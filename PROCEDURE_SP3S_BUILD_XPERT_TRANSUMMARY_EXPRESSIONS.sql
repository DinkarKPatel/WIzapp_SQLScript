CREATE PROCEDURE SP3S_BUILD_XPERT_TRANSUMMARY_EXPRESSIONS
AS
BEGIN
	
	DECLARE @cHoLocId VARCHAR(4),@cCurLocId VARCHAR(4),@cShipJoin VARCHAR(MAX)

	SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='ho_lcoation_id'
	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='lcoation_id'


	SELECT @cShipJoin=' LEFT JOIN lm01106 SHLM (NOLOCK) ON SHLM.ac_code=b.shipping_ac_code  LEFT JOIN lmp01106 SHLMP (NOLOCK) ON SHLMP.ac_code=b.shipping_ac_code '+
	' LEFT JOIN area SHLMP_area (NOLOCK) ON SHLMP_area.area_code=shlmp.area_code '+
	' LEFT JOIN city SHLMP_city (NOLOCK) ON SHLMP_city.city_code=shlmp_area.city_code '+
	' LEFT JOIN state SHLMP_state (NOLOCK) ON SHLMP_state.state_code=shlmp_city.state_code '+
	' LEFT JOIN LM01106 PRLM (NOLOCK) ON PRLM.AC_CODE=b.AC_CODE LEFT JOIN LMP01106 PRLMP (NOLOCK) ON PRLMP.AC_CODE=b.AC_CODE'+
	' LEFT JOIN area PRLMP_area (NOLOCK) ON PRLMP_area.area_code=prlmp.area_code'+
	' LEFT JOIN city PRLMP_city (NOLOCK) ON PRLMP_city.city_code=shlmp.city_code'+
	' LEFT JOIN state PRLMP_state (NOLOCK) ON PRLMP_state.state_code=prlmp_city.state_code '

	SELECT * INTO #transaction_summary_calculative_COLS FROM transaction_analysis_calculative_COLS	
	WHERE 1=2

	SELECT * INTO #transaction_summary_master_COLS FROM  transaction_analysis_master_COLS	
	WHERE 1=2

	DELETE from transaction_summary_expr



	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Wholesale Pack Slip Out' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.WPS_DET A (NOLOCK)    
	JOIN  [DATABASE].dbo.WPS_mst B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Wholesale Pack Slip Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.WPS_DET A (NOLOCK)    
	JOIN  [DATABASE].dbo.WPS_mst B (NOLOCK) ON A.PS_ID = B.PS_ID    
	JOIN [DATABASE].dbo.INM01106 C (nolock) on C.INV_ID=b.wsl_inv_id
	[JOIN]
	WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr



	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail Sale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.QUANTITY >0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail Sale Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.QUANTITY <0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	   	  
	 INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail Sale_Pay' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMM01106 b (NOLOCK)    
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	 INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'WholeSale_Pay' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.INM01106 b (NOLOCK)    
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Approval Issue' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.apd01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.apm01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	WHERE b.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Approval Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.approval_return_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.approval_return_mst B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	WHERE b.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr) 
	SELECT 'Retail PackSlip' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.rps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.rps_mst B (NOLOCK) ON A.cm_id = B.cm_id    
	[JOIN]
	WHERE b.cm_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr



	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Common' xn_type,'' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Purchase' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.PID01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=b.ref_converted_mrntobill_mrrid
	[JOIN]
	WHERE b.mrr_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND pim_conv.mrr_id IS NULL AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan In(Purchase)2' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.PID01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.mrr_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(sl.loc_gst_no,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Debit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Wholesale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID 
	Left outer join parcel_det PD (nolock) on B.INV_ID= PD.REF_MEMO_ID
    Left outer join parcel_mst PM  (nolock ) on PD.parcel_memo_id= PM.parcel_memo_id 
    and PM.xn_type = ''WSL'' and b.CANCELLED=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.pan_no,'''')<>ISNULL(sl.pan_no,'''')

	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Credit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.pan_no,'''')<>ISNULL(sl.pan_no,'''')

	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.ac_gst_no,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Sale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID   
	Left outer join parcel_det PD (nolock) on B.INV_ID= PD.REF_MEMO_ID
    Left outer join parcel_mst PM  (nolock ) on PD.parcel_memo_id= PM.parcel_memo_id  
    and PM.xn_type = ''WSL'' and b.CANCELLED=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND b.cancelled=0 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	Left outer join parcel_det PD (nolock) on B.INV_ID= PD.REF_MEMO_ID
    Left outer join parcel_mst PM  (nolock ) on PD.parcel_memo_id= PM.parcel_memo_id 
    and PM.xn_type = ''WSL'' and b.CANCELLED=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	LEFT JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	((b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')) OR
	 (b.inv_mode=1 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')))
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan Out(Debit note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.rm_id = B.rm_id    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	((b.mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')) OR
	 (b.mode=1 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')))
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Debit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.rm_id = B.rm_id    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''') AND
	ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID 
	Left outer join parcel_det PD (nolock) on B.INV_ID= PD.REF_MEMO_ID
    Left outer join parcel_mst PM  (nolock ) on PD.parcel_memo_id= PM.parcel_memo_id 
    and PM.xn_type = ''WSL'' and b.CANCELLED=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan In(Purchase)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Transfer In(Purchase)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Purchase' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_ID,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Credit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_ID,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=LEFT(b.cn_id,2)
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_summary_expr (xn_type,base_expr)    
	SELECT 'Group Transfer In(Credit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	--LOCATTR START
	
INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.cm_id,2)' AS keyfield,table_caption AS col_header ,
'Retail Sale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''



INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'b.dept_id' AS keyfield,table_caption AS col_header ,
'Purchase' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
'Debit note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
'Group Debit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
'Delivery Challan Out(Debit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
'Group Transfer Out(Debit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Wholesale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Group Sale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Delivery Challan Out(Wholesale)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Delivery Challan In(Purchase)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Group Transfer Out(Wholesale)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
'Group Transfer In(Purchase)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
'Credit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
'Group Credit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
'Delivery Challan In(Credit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
'Group Transfer In(Credit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''


INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
SELECT 'LOC'+column_name as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,table_caption AS col_header ,
'Group Purchase' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
From config_locattr  where table_caption <> ''

UPDATE #transaction_summary_master_COLS set COL_HEADER=col_expr where joining_table='LOC_NAMES'
	--LOCATTR END


  --CALSTART


	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.sisloc_eoss_discount_percentage' as COL_EXPR,'' AS keyfield,'SIS Loc Eoss Disc %' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_mrp)' as COL_EXPR,'SIS Loc Mrp' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_eoss_discount_amount)' as COL_EXPR,'SIS Loc Eoss Disc Amt' AS col_header 


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'SIS Loc Eoss Disc %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc Mrp' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc Eoss Disc Amt' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
    SELECT 'Retail Sale' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header




	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Retail Sale' xn_type,'SUM(a.item_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_master_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	--SELECT 'Retail Sale' xn_type,'a.basic_discount_percentage' as COL_EXPR,'' as keyfield,
	--'Item Discount %' AS col_header ,'',''

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Retail Sale' xn_type,'SUM(a.basic_discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_master_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	--SELECT 'Retail Sale' xn_type,'a.card_discount_percentage' as COL_EXPR,'' keyfield,'Card Discount %' AS col_header,
	--'',''

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Retail Sale' xn_type,'SUM(a.card_discount_amount)' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.cmm_discount_amount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'(CASE WHEN SUM(a.quantity*a.mrp)<>0 then ROUND(SUM(a.discount_amount+a.cmm_discount_amount)*100/SUM(a.quantity*a.mrp),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'b.atd_charges' as COL_EXPR,'Other Charges' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'0' as COL_EXPR,'freight' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.WeightedQtyBillCount)' as COL_EXPR,'Bill Count' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.cash_tendered)' as COL_EXPR,'Cash Tender' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.payback)' as COL_EXPR,'Payback' AS col_header 



	--SLR

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
    SELECT 'Approval Issue' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'b.discount_amount' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'b.atd_charges' as COL_EXPR,'Other Charges' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'freight' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Bill Count' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Cash Tender' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Payback' AS col_header 

	--APR
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity)*-1' as COL_EXPR,'Transaction Qty' AS col_header 

	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.pp)*-1' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)*-1' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)*-1' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)*-1' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.mrp)*-1' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.ws_price)*-1' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
    SELECT 'Approval Return' xn_type,'SUM(a.mrp*a.quantity)*-1' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'b.discount_amount*-1' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'b.atd_charges*-1' as COL_EXPR,'Other Charges' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'freight' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Bill Count' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Cash Tender' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Payback' AS col_header 
	   	  
    	--RPS
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 
		

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'b.atd_charges' as COL_EXPR,'Other Charges' AS col_header 
	
	--COMMON
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'Payment_groups' as COL_EXPR,'Payment Groups' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'Payment_modes' as COL_EXPR,'Payment Modes' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Bill Count' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Cash Tender' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'payback' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header 
		

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'b.other_charges' as COL_EXPR,'Other Charges' AS col_header 
	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'b.freight' as COL_EXPR,'freight' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'b.round_off' as COL_EXPR,'Round Off' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'b.gst_round_off' as COL_EXPR,'Gst Round Off' AS col_header 

    INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.rfnet_with_other_charges)' as COL_EXPR,
	'Net Transaction Value' AS col_header 
		
    INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.rfnet)' as COL_EXPR,
	'Net Transaction Value' AS col_header 
	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Purchase' xn_type,'SUM(a.purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.PIMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.pimdiscountamount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'b.Tcs_Amount' as COL_EXPR,'TCS Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'b.tds_Amount' as COL_EXPR,'TDS Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'TDS Amount' AS col_header 
	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Debit Note' xn_type,'SUM(a.purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header



	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 


	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 
	
	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then 	ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Wholesale' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header



	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	--'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	--'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Wholesale' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'insurance' as COL_EXPR,'insurance' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'insurance' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'Tcs_Amount' as COL_EXPR,'TCS Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'TCS Amount' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type, '0' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'freight cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0'as COL_EXPR,'freight igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'freight sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'insurance cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'insurance igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'insurance sgst Amt' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'packing cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'packing igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'common' xn_type,'0' as COL_EXPR,'packing sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'other_charges_cgst_amount' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'other_charges_igst_amount' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'other_charges_sgst_amount' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
	   	 	
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.other_charges_gst_percentage' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	--SLR





	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'other_charges_cgst_amount' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'other_charges_igst_amount' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'other_charges_sgst_amount' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'freight_cgst_amount' as COL_EXPR,'freight cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'freight_igst_amount' as COL_EXPR,'freight igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'freight_sgst_amount' as COL_EXPR,'freight sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'insurance_cgst_amount' as COL_EXPR,'insurance cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'insurance_igst_amount' as COL_EXPR,'insurance igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'insurance_sgst_amount' as COL_EXPR,'insurance sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'packing_cgst_amount' as COL_EXPR,'packing cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'packing_igst_amount' as COL_EXPR,'packing igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'packing_sgst_amount' as COL_EXPR,'packing sgst Amt' AS col_header 
	   	 	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Credit Note' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header




	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.CNMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.CNMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.discount_amount+a.CNMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	--CALEND
	--MASTERSTART




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dt_name' as COL_EXPR,'b.dt_code' AS keyfield,'Discount Type' AS col_header ,
	'Retail Sale' xn_type,'dtm' as joining_table,'dt_code' joining_column,'' as  joining_table_alias --


	


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Transaction Location Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	
	--INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT '''''' as COL_EXPR,'' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Common' xn_type,'' as joining_table,'' joining_column
	  	 

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	
	--INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT 'Inactive' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Retail Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.passport_no' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ticket_no' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.flight_no' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ecoupon_id' as COL_EXPR,'' AS keyfield,'Ecoupon Id' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ref_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ref_no_paytm' as COL_EXPR,'' AS keyfield,'Paytm Ref. No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.copies_ptd' as COL_EXPR,'' AS keyfield,'Copies printed' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Edit_Count' as COL_EXPR,'' AS keyfield,'Modified' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	   	  
	INSERT #transaction_summary_master_COLS(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Broker Name' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column,3




	  INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Approval Issue' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Approval Issue' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Approval Issue' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column
 
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ref_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column



	--APR

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Approval Return' xn_type,'location' as joining_table,'dept_id' joining_column





	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Approval Return' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Approval Return' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column
 
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ref_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column
		   	
	--RPS
	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Retail PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Retail PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Retail PackSlip' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column
 
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column
	


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.dept_id' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Name' AS col_header ,
	'Purchase' xn_type,'location' as joining_table,'dept_id' joining_column





	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Area' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location City' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location State' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(B.RM_ID,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.RM_ID,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(B.RM_ID,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Debit note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,
	joining_column,addnl_Join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=1 THEN SHLM.AC_NAME  
					    ELSE SHLM.AC_NAME  END) ELSE PRLM.AC_NAME END)' as COL_EXPR,
						'' AS keyfield,'Shipping Name' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=1 THEN SHLMP.AC_GST_NO  
					    ELSE SHLMP.AC_GST_NO END) ELSE PRLMP.AC_GST_NO END)' as COL_EXPR,
						'' AS keyfield,'Shipping GST No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join

		
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP.ADDRESS0  ELSE b.SHIPPING_ADDRESS END       
		ELSE PRLMP.ADDRESS0 END)' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP.ADDRESS1  ELSE b.SHIPPING_ADDRESS2 END       
		ELSE PRLMP.ADDRESS1 END)' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP.ADDRESS2  ELSE b.SHIPPING_ADDRESS3 END       
		ELSE PRLMP.ADDRESS2 END)' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)   
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP_AREA.area_name  ELSE b.SHIPPING_area_NAME END       
		ELSE PRLMP_area.area_name END)' as COL_EXPR,'' AS keyfield,'Shipping Area' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP_city.city  ELSE b.shipping_city_name END       
		ELSE PRLMP_city.city END)' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP_state.state  ELSE b.shipping_state_name END       
		ELSE PRLMP_state.state END)' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =1                 
		THEN CASE WHEN ISNULL(SHIPPING_MODE,0)<>1 
		THEN SHLMP_area.pincode  ELSE b.shipping_pin END       
		ELSE PRLMP_area.pincode END)' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Debit note' xn_type,'' as joining_table,@cShipJoin as addnl_join
		
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Wholesale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN SHLM.AC_NAME  
					    ELSE SHLM.AC_NAME  END) ELSE PRLM.AC_NAME END)' as COL_EXPR,
						'' AS keyfield,'Shipping Name' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN SHLMP.AC_GST_NO  
					    ELSE SHLMP.AC_GST_NO END) ELSE PRLMP.AC_GST_NO END)' as COL_EXPR,
						'' AS keyfield,'Shipping GST No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS0  ELSE b.SHIPPING_ADDRESS END) ELSE PRLMP.ADDRESS0 END' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS1  ELSE b.SHIPPING_ADDRESS2 END) ELSE PRLMP.ADDRESS1 END' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS2  ELSE b.SHIPPING_ADDRESS3 END) ELSE PRLMP.ADDRESS2 END' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_AREA.AREA_NAME  ELSE b.SHIPPING_AREA_NAME END) ELSE PRLMP_AREA.AREA_NAME END' as COL_EXPR,'' AS keyfield,
	'Shipping Area' AS col_header ,	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_CITY.CITY  ELSE b.shipping_city_name END) ELSE PRLMP_CITY.CITY END' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_STATE.STATE  ELSE b.shipping_state_name END) ELSE PRlmp_STATE.STATE END' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_AREA.pincode  ELSE b.SHIPPING_PIN END) ELSE PRlmp_AREA.pincode END' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN SHLM.AC_NAME  
					    ELSE SHLM.AC_NAME  END) ELSE PRLM.AC_NAME END)' as COL_EXPR,
						'' AS keyfield,'Shipping Name' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT '(CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0                 
			 THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 THEN SHLMP.AC_GST_NO  
					    ELSE SHLMP.AC_GST_NO END) ELSE PRLMP.AC_GST_NO END)' as COL_EXPR,
						'' AS keyfield,'Shipping GST No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS0  ELSE b.SHIPPING_ADDRESS END) ELSE PRLMP.ADDRESS0 END' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS1  ELSE b.SHIPPING_ADDRESS2 END) ELSE PRLMP.ADDRESS1 END' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP.ADDRESS2  ELSE b.SHIPPING_ADDRESS3 END) ELSE PRLMP.ADDRESS2 END' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_AREA.AREA_NAME  ELSE b.SHIPPING_AREA_NAME END) ELSE PRLMP_AREA.AREA_NAME END' as COL_EXPR,'' AS keyfield,
	'Shipping Area' AS col_header ,	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_CITY.CITY  ELSE b.shipping_city_name END) ELSE PRLMP_CITY.CITY END' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_STATE.STATE  ELSE b.shipping_state_name END) ELSE PRlmp_STATE.STATE END' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'CASE WHEN ISNULL(SHIPPING_SAME_AS_BILLING_ADD,0) =0  THEN (CASE WHEN ISNULL(SHIPPING_MODE,0)=0 
	THEN SHLMP_AREA.pincode  ELSE b.SHIPPING_PIN END) ELSE PRlmp_AREA.pincode END' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,@cShipJoin as addnl_join
		
		
--Anil 


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS ' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS2' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS3' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_AREA_NAME' as COL_EXPR,'' AS keyfield,
	'Shipping Area' AS col_header ,	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT ' b.shipping_city_name' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.shipping_state_name' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_PIN' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' as addnl_join


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS ' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS2' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS3' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_AREA_NAME' as COL_EXPR,'' AS keyfield,
	'Shipping Area' AS col_header ,	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT ' b.shipping_city_name' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.shipping_state_name' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_PIN' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' as addnl_join




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.copies_ptd' as COL_EXPR,'' AS keyfield,'Copies printed' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Edit_Count' as COL_EXPR,'' AS keyfield,'Modified' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.other_charges_gst_percentage' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.freight_gst_percentage' as COL_EXPR,'' AS keyfield,'Freight gst%' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.insurance_gst_percentage' as COL_EXPR,'' AS keyfield,'insurance gst%' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Freight gst%' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'insurance gst%' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	   	    
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

		
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EInv_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'customer_fname+'' ''+customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column
		
	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Pan no.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column







	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'customer_fname+'' ''+customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column
			
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	--APR
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'customer_fname+'' ''+customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column
			
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column
	   	  
	    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'customer_fname+'' ''+customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column
			
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column
	  	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Purchase' xn_type,'lm01106' as joining_table,'ac_code' joining_column ,'lm_pur' as joining_table_alias

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Purchase' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Debit note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Debit note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Wholesale' xn_type,'lm01106' as joining_table,'ac_code' joining_column, 'lm_wsl' as joining_table_alias


	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.region_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Region Name' AS col_header ,
	'Wholesale' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.state' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Wholesale' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.city' as COL_EXPR,'b.ac_code' AS keyfield,'Party city' AS col_header ,
	'Wholesale' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bilty_no' as COL_EXPR,'' AS keyfield,'Bilty No' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'PM.receipt_dt' as COL_EXPR,'' AS keyfield,'Bilty Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Wholesale' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Credit Note' xn_type,'lm01106' as joining_table,'ac_code' joining_column ,'LM_WSR' as joining_table_alias

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Credit Note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column



	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.mrr_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	   	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column
	   

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.other_charges_gst_percentage' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.freight_gst_percentage' as COL_EXPR,'' AS keyfield,'Freight gst%' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.insurance_gst_percentage' as COL_EXPR,'' AS keyfield,'insurance gst%' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
	  	 		 		

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Debit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Debit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column
	   
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
	   	 	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rmv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.target_bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.region_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Region Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.state' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.city' as COL_EXPR,'b.ac_code' AS keyfield,'Party city' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bilty_no' as COL_EXPR,'' AS keyfield,'Bilty No' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'PM.receipt_dt' as COL_EXPR,'' AS keyfield,'Bilty Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.other_charges_gst_percentage' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.freight_gst_percentage' as COL_EXPR,'' AS keyfield,'Freight gst%' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.insurance_gst_percentage' as COL_EXPR,'' AS keyfield,'insurance gst%' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
	   	 
		 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.mrr_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column
	   

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column



	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column
	   	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
	   	
	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rmv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)   
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.target_bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.region_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Region Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.state' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.city' as COL_EXPR,'b.ac_code' AS keyfield,'Party city' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'lmv01106' as joining_table,'ac_code' joining_column
  
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bilty_no' as COL_EXPR,'' AS keyfield,'Bilty No' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'PM.receipt_dt' as COL_EXPR,'' AS keyfield,'Bilty Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
   
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	
    INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.other_charges_gst_percentage' as COL_EXPR,'' AS keyfield,'Other Charges gst%' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.freight_gst_percentage' as COL_EXPR,'' AS keyfield,'Freight gst%' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.insurance_gst_percentage' as COL_EXPR,'' AS keyfield,'insurance gst%' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
	   	  
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.mrr_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column


	
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(B.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column





	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	
    INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header




	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 


	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 
	
	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	IF @cCurLocId=@cHoLocId
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.inmdiscountamount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'tcs_amount' as COL_EXPR,'TCS Amount' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'tcs_amount' as COL_EXPR,'TCS Amount' AS col_header 



	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 
	   	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.inmdiscountamount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'tcs_amount' as COL_EXPR,'TCS Amount' AS col_header 




	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header




	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	    INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'other_charges_cgst_amount' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'other_charges_igst_amount' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'other_charges_sgst_amount' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'freight_cgst_amount' as COL_EXPR,'freight cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'freight_igst_amount' as COL_EXPR,'freight igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'freight_sgst_amount' as COL_EXPR,'freight sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'insurance_cgst_amount' as COL_EXPR,'insurance cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'insurance_igst_amount' as COL_EXPR,'insurance igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'insurance_sgst_amount' as COL_EXPR,'insurance sgst Amt' AS col_header 
	   
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'packing_cgst_amount' as COL_EXPR,'packing cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'packing_igst_amount' as COL_EXPR,'packing igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'packing_sgst_amount' as COL_EXPR,'packing sgst Amt' AS col_header 
	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'tcs_amount' as COL_EXPR,'TCS Amount' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	    INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'other_charges_cgst_amount' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'other_charges_igst_amount' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'other_charges_sgst_amount' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'freight_cgst_amount' as COL_EXPR,'freight cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'freight_igst_amount' as COL_EXPR,'freight igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'freight_sgst_amount' as COL_EXPR,'freight sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'insurance_cgst_amount' as COL_EXPR,'insurance cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'insurance_igst_amount' as COL_EXPR,'insurance igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'insurance_sgst_amount' as COL_EXPR,'insurance sgst Amt' AS col_header 
	   
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'packing_cgst_amount' as COL_EXPR,'packing cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'packing_igst_amount' as COL_EXPR,'packing igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'packing_sgst_amount' as COL_EXPR,'packing sgst Amt' AS col_header 
	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header



	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.CNMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.CNMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.discount_amount+a.CNMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	   
	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.CNMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.CNMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.discount_amount+a.CNMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'tcs_amount' as COL_EXPR,'TCS Amount' AS col_header 


	

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 
		
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Purchase' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Purchase' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.InMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.InmDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.discount_amount+a.InmDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Debit Note' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.InMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.InmDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.discount_amount+a.InmDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'tcs_amount' as COL_EXPR,'Tcs Amount' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'insurance' as COL_EXPR,'insurance' AS col_header 
	   

	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Sale' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	    INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'other_charges_cgst_amount' as COL_EXPR,'Other Charges cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'other_charges_igst_amount' as COL_EXPR,'Other Charges igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'other_charges_sgst_amount' as COL_EXPR,'Other Charges sgst Amt' AS col_header 
		
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'freight_cgst_amount' as COL_EXPR,'freight cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'freight_igst_amount' as COL_EXPR,'freight igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'freight_sgst_amount' as COL_EXPR,'freight sgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'insurance_cgst_amount' as COL_EXPR,'insurance cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'insurance_igst_amount' as COL_EXPR,'insurance igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'insurance_sgst_amount' as COL_EXPR,'insurance sgst Amt' AS col_header 
	   
	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'packing_cgst_amount' as COL_EXPR,'packing cgst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'packing_igst_amount' as COL_EXPR,'packing igst Amt' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'packing_sgst_amount' as COL_EXPR,'packing sgst Amt' AS col_header 
	

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 


	INSERT #transaction_summary_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Credit Note' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	   

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Transaction Value at MRP' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	--INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	
	INSERT #transaction_summary_master_COLS	(xn_type,COL_EXPR,keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Common' xn_type,'b.Remarks' as COL_EXPR,'' as keyfield,
	'Bill Remarks' AS col_header ,'',''

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order,joining_table_alias)     
	SELECT 'broker.ac_name' as COL_EXPR,'b.broker_ac_code' AS keyfield,'Broker Name' AS col_header ,
	'Common' xn_type,'lm01106' as joining_table,'ac_code' joining_column,3,'broker'


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.challan_no' as COL_EXPR,'' AS keyfield,'Purchase Challan No.' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.receipt_Dt' as COL_EXPR,'' AS keyfield,'Purchase Receipt Date' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.BILL_NO' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.INV_DT' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,50


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Purchase Challan No.' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Purchase Receipt Date' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,50

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.gst_percentage' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.gst_cess_percentage' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_summary_master_COLS	(xn_type,COL_EXPR,keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Common' xn_type,'a.discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_gst_amount' as COL_EXPR,'a.product_code' AS keyfield,'Purchase GST Amount' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,54

	INSERT #transaction_summary_master_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.discount_percentage' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,54
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,60

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,61

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,62

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Card No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,63


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_ER_FLAG' as COL_EXPR,'a.product_code' AS keyfield,'Er Flag' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,64.1	

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_ITEM_TYPE_DESC' as COL_EXPR,'a.product_code' AS keyfield,'Transaction Item type' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,65
		
		
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,''
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping GST No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,''
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping Area' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Ecoupon Id' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Paytm Ref. No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Copies printed' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Edit_count' as COL_EXPR,'' AS keyfield,'Modified' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'username' as COL_EXPR,'b.user_code' AS keyfield,'User Name' AS col_header ,
	'Common' as xn_type,'users' as joining_table,'user_code' joining_column
	   
	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'username' as COL_EXPR,'b.edt_user_code' AS keyfield,'Edit User Name' AS col_header ,
	'Common' as xn_type,'users' as joining_table,'user_code' joining_column,'EDTUSER'
	   

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
  
     INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Bilty No' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	 INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Bilty Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
  
   

	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name,Col_order)     
	SELECT 'xn_type' as COL_EXPR,'' AS keyfield,'Transaction Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'xn_type' col_name,0  Col_order


	----- Special Case of Sale REturn WHich will have all columns sam as that of REtail Sale
	INSERT #transaction_summary_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT COL_EXPR,keyfield,col_header ,'Retail Sale Return' xn_type,joining_table,joining_column
	From #transaction_summary_master_COLS WHERE xn_type='Retail Sale'

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,col_expr,col_header FROM #transaction_summary_calculative_COLS
	WHERE xn_type='Retail Sale'

	INSERT #transaction_summary_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT xn_type,'SUM(a.cgst_amount+a.sgst_amount)' as COL_EXPR,'LGST Amount' AS col_header 	
	FROM #transaction_summary_calculative_COLS WHERE col_header='CGST AMOUNT'

	--select * from #transaction_summary_master_COLS where COL_EXPR='xn_type'
	UPDATE #transaction_summary_master_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''
	UPDATE #transaction_summary_calculative_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''

	UPDATE #transaction_summary_master_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_summary_calculative_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE transaction_summary_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_summary_master_COLS SET datecol=1 WHERE right(col_name,4)='DATE'
	
	UPDATE #transaction_summary_master_COLS SET joining_table_alias='lv' where joining_table='#loc_view'
	
	UPDATE #transaction_summary_master_COLS SET joining_column=ISNULL(joining_column,'')

	DELETE FROM transaction_analysis_calculative_COLS WHERE rep_type='SMRY'
	DELETE FROM transaction_analysis_master_COLS WHERE rep_type='SMRY'

	INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header, col_name, group_xn_type, rep_type )
	SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'SMRY' rep_type 
	FROM #transaction_summary_calculative_COLS 
		
	INSERT transaction_analysis_master_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
	col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
	SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
	group_xn_type, datecol, Col_order, joining_table_alias,'SMRY' rep_type 
	FROM #transaction_summary_master_COLS
END

