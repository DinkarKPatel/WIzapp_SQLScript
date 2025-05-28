CREATE PROCEDURE SP3S_BUILD_XPERTREPORTING_EXPRESSIONS
AS
BEGIN

	DELETE FROM xpert_report_filtercols
	
	delete from transaction_analysis_calculative_COLS
	delete from transaction_analysis_master_COLS
	delete from transaction_analysis_expr

	SELECT * INTO #transaction_analysis_calculative_COLS FROM transaction_analysis_calculative_COLS	
	WHERE 1=2

	SELECT * INTO #transaction_analysis_master_COLS FROM  transaction_analysis_master_COLS	
	WHERE 1=2
	
	DECLARE @cHoLocId VARCHAR(4),@cCurLocId VARCHAR(4)

	SELECT TOP 1 @cHoLocId=value FROM  config (NOLOCK) WHERE config_option='ho_location_id'
	SELECT TOP 1 @cCurLocId=value FROM  config (NOLOCK) WHERE config_option='location_id'


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail Sale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID   
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Gross Retail Sale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID   
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND A.QUANTITY >0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail Sale Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID   
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.QUANTITY <0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Approval Issue' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.apd01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.apm01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	WHERE b.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Approval Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.approval_return_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.approval_return_mst B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	WHERE b.MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Opening Stock' xn_type,'[LAYOUT_COLS]
	FROM [TABLENAME] A WITH (NOLOCK) 
	LEFT JOIN year_wise_cbsstk_depcn_det c WITH (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id
	AND c.fin_year=''01''+dbo.fn_getfinyear([DTODT]) [JOIN]
	WHERE A.BIN_ID <> ''999''  AND [WHERE]  
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Job Work Issue' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.jobwork_issue_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.jobwork_issue_mst B (NOLOCK) ON A.issue_id = B.issue_id 
	 JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON B.agency_code = PAM.agency_code  
	[JOIN]
	WHERE b.issue_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Job Work Receive' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.jobwork_receipt_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.jobwork_receipt_mst B (NOLOCK) ON A.receipt_id = B.receipt_id   
	JOIN  [DATABASE].dbo.prd_agency_mst PAM (NOLOCK) ON B.agency_code = PAM.agency_code  
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	   

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Retail PackSlip' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.rps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.rps_mst B (NOLOCK) ON A.cm_id = B.cm_id    
	[JOIN]
	WHERE b.cm_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2



	--INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    	
	--SELECT 'Wholesale Pack Slip Out' xn_type,'[LAYOUT_COLS]
	--from [DATABASE].dbo.wps_det A (NOLOCK)    
	--JOIN  [DATABASE].dbo.wps_mst B (NOLOCK) ON A.ps_id = B.ps_id    
	--[JOIN]
	--WHERE   B.PS_MODE =1 AND b.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	--AND [WHERE]    
	--group by [GROUPBY]' AS base_expr,2



	
	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    	
	SELECT 'Creditnote PackSlip' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.cnps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.cnps_mst B (NOLOCK) ON A.ps_id = B.ps_id    
	[JOIN]
	WHERE   b.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    	
	SELECT 'Creditnote PackSlip Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.cnps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.cnps_mst B (NOLOCK) ON A.ps_id = B.ps_id    
	JOIN cnm01106 C (NOLOCK) ON b.wsr_cn_id=c.cn_id
	[JOIN]
	WHERE   b.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    	
	SELECT 'Debitnote PackSlip' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.dnps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.dnps_mst B (NOLOCK) ON A.ps_id = B.ps_id    
	[JOIN]
	WHERE   B.PS_MODE =1 AND b.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    	
	SELECT 'Debitnote PackSlip Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.dnps_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.dnps_mst B (NOLOCK) ON A.ps_id = B.ps_id    
	JOIN rmm01106 C (NOLOCK) ON b.prt_rm_id=c.rm_id
	[JOIN]
	WHERE   b.ps_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1



	INSERT transaction_analysis_expr (xn_type,base_expr)    
	SELECT 'Common' xn_type,'' AS base_expr

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Purchase' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.PID01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=b.ref_converted_mrntobill_mrrid
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND pim_conv.mrr_id IS NULL AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Delivery Challan In(Purchase)2' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.PID01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(sl.loc_gst_no,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Debit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Wholesale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code	
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,oh_parent_xn_type,base_expr)    
	SELECT 'Wholesale(OH)' xn_type,'Wholesale' as oh_parent_xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.INM01106 b (NOLOCK)    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.pan_no,'''')<>ISNULL(sl.pan_no,'''')

	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_analysis_expr (xn_type,oh_parent_xn_type,base_expr)    
	SELECT 'Retail Sale(OH)' xn_type,'Retail Sale' as oh_parent_xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CMM01106 b (NOLOCK)    
	[JOIN]
	WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 and isnull(atd_charges,0)<>0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_analysis_expr (xn_type,oh_parent_xn_type,base_expr)    
	SELECT 'Purchase(OH)' xn_type,'Purchase' as oh_parent_xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.PIM01106 b (NOLOCK)    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=b.ref_converted_mrntobill_mrrid
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND pim_conv.mrr_id IS NULL AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Credit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.pan_no,'''')<>ISNULL(sl.pan_no,'''')

	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.CND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.cn_id,2)
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(lmp.ac_gst_no,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Sale' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND b.cancelled=0 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	LEFT JOIN pim01106 c (NOLOCK) ON c.inv_id=b.inv_id AND c.cancelled=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	LEFT JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	LEFT JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	((b.inv_mode=2 AND SUBSTRING(ISNULL(tl.loc_gst_no,''''),3,10)=substring(ISNULL(sl.loc_gst_no,''''),3,10)) OR
	 (b.inv_mode=1 AND SUBSTRING(ISNULL(lmp.ac_gst_no,''''),3,10)=SUBSTRING(ISNULL(sl.loc_gst_no,''''),3,10)))
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2


	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Delivery Challan Out(Debit note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.rm_id = B.rm_id    
	LEFT JOIN  [DATABASE].dbo.CNM01106 C (NOLOCK) ON A.rm_id = C.rm_id    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	((b.mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')) OR
	 (b.mode=1 AND ISNULL(lmp.ac_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')))
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Debit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.rm_id = B.rm_id    
	LEFT JOIN cnm01106 c (NOLOCK) ON c.rm_id=b.rm_id AND c.cancelled=0
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''') AND
	ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.IND01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	LEFT JOIN [DATABASE].dbo.PIM01106 C (NOLOCK) ON A.INV_ID = C.INV_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID    
	LEFT JOIN [DATABASE].dbo.CNM01106 c (NOLOCK) ON c.RM_ID = B.RM_ID
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=b.party_dept_id
	[JOIN]
	WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	IF @cCurLocId=@cHoLocId
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Delivery Challan In(Purchase)' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.IND01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	ELSE
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Delivery Challan In(Purchase)' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.PID01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	
	IF @cCurLocId=@cHoLocId
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Group Transfer In(Purchase)' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.IND01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
		JOIN  [DATABASE].dbo.INM01106 c (NOLOCK) ON A.INV_ID = c.INV_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
		AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	ELSE
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Group Transfer In(Purchase)' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.PID01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.mrr_ID = B.mrr_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
		AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	
	IF @cHoLocId=@cCurLocId
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Group Purchase' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.IND01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
		LEFT JOIN [DATABASE].dbo.INM01106 c (NOLOCK) ON A.INV_ID = c.INV_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
		AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	ELSE
		INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
		SELECT 'Group Purchase' xn_type,'[LAYOUT_COLS]
		from [DATABASE].dbo.PID01106 A (NOLOCK)    
		JOIN  [DATABASE].dbo.PIM01106 B (NOLOCK) ON A.MRR_ID = B.MRR_ID    
		JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.inv_id,2)
		JOIN location tl (NOLOCK) ON tl.dept_id=b.dept_id
		[JOIN]
		WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
		b.inv_mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
		AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
		AND [WHERE]    
		group by [GROUPBY]' AS base_expr,1
	
	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_ID,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=LEFT(b.cn_id,2)
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')=ISNULL(sl.loc_gst_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Credit Note' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	LEFT JOIN [DATABASE].dbo.RMM01106 c (NOLOCK) ON C.RM_ID = b.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_ID,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=LEFT(b.cn_id,2)
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')<>ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	SELECT 'Group Transfer In(Credit Note)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.rm_ID = B.rm_ID    
	JOIN location sl (NOLOCK) ON sl.dept_id=LEFT(b.rm_id,2)
	JOIN location tl (NOLOCK) ON tl.dept_id=LEFT(b.cn_id,2)
	[JOIN]
	WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND 
	b.mode=2 AND ISNULL(tl.loc_gst_no,'''')<>ISNULL(sl.loc_gst_no,'''')
	AND ISNULL(tl.pan_no,'''')=ISNULL(sl.pan_no,'''')
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Wholesale Pack Slip Out' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.WPS_DET A (NOLOCK)    
	JOIN  [DATABASE].dbo.WPS_mst B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Wholesale Pack Slip Return' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.WPS_DET A (NOLOCK)    
	JOIN  [DATABASE].dbo.WPS_mst B (NOLOCK) ON A.PS_ID = B.PS_ID    
	JOIN [DATABASE].dbo.INM01106 C (nolock) on C.INV_ID=b.wsl_inv_id
	[JOIN]
	WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock Cancellation' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.icd01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.icm01106 B (NOLOCK) ON A.cnc_memo_ID = B.cnc_memo_ID    
	[JOIN]
	WHERE b.cnc_memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND cnc_type=1
	AND ISNULL(stock_adj_note,0)=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock UnCancellation' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.icd01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.icm01106 B (NOLOCK) ON A.cnc_memo_ID = B.cnc_memo_ID    
	[JOIN]
	WHERE b.cnc_memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND cnc_type=2
	AND ISNULL(stock_adj_note,0)=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1
	--LOCATTR START

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock Creation (IRR)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.ird01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.irm01106 B (NOLOCK) ON A.irm_memo_ID = B.irm_memo_ID    
	[JOIN]
	WHERE b.irm_memo_dt BETWEEN [DFROMDT] AND [DTODT] AND ISNULL(new_product_code,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock consumption (IRR)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.ird01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.irm01106 B (NOLOCK) ON A.irm_memo_ID = B.irm_memo_ID    
	[JOIN]
	WHERE b.irm_memo_dt BETWEEN [DFROMDT] AND [DTODT] AND ISNULL(new_product_code,'''')<>''''
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2
	
	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock Creation (SNC)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.snc_barcode_det A (NOLOCK)    
	JOIN [DATABASE].dbo.snc_det c (NOLOCK) ON c.row_id=a.REFROW_ID
	JOIN  [DATABASE].dbo.snc_mst B (NOLOCK) ON c.memo_ID = B.memo_ID    
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,1

	INSERT transaction_analysis_expr (xn_type,base_expr,xn_mode)    
	--CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	SELECT 'Stock consumption (SNC)' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.snc_consumable_det A (NOLOCK)    
	JOIN  [DATABASE].dbo.snc_mst B (NOLOCK) ON A.memo_ID = B.memo_ID    
	[JOIN]
	WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr,2



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cm_id,2)' AS keyfield,table_caption AS col_header ,
	'Gross Retail Sale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cm_id,2)' AS keyfield,table_caption AS col_header ,
	'Retail Sale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cm_id,2)' AS keyfield,table_caption AS col_header ,
	'Retail Sale Return' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'b.dept_id' AS keyfield,table_caption AS col_header ,
	'Purchase' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
	'Debit note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Debit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.rm_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Wholesale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Sale' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.inv_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
	'Credit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Credit Note' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,table_caption AS col_header ,
	'Group Purchase' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.ps_id,2)' AS keyfield,table_caption AS col_header ,
	'Creditnote PackSlip' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.ps_id,2)' AS keyfield,table_caption AS col_header ,
	'Debitnote PackSlip' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''
	   	  

	--LOCATTR END





	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT'max_cm_dt' as COL_EXPR,'b.dept_id' AS keyfield,'Max Sale Date' AS col_header ,
	'Purchase' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT'max_cm_dt' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Creditnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'max_cm_dt' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Max Sale Date' AS col_header ,
	'Debitnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column
	






	--GST STATE CODE

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Purchase' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.MRR_ID,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Purchase' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Debit note' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.rm_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Debit note' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Debit Note' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.rm_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Debit Note' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.rm_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.rm_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''



	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Sale' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID = LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Sale' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''



	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''


	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Delivery Challan In(Purchase)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Purchase)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''


	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Transfer In(Purchase)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer In(Purchase)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Credit Note' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.cn_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Credit Note' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''
	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Credit Note' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.cn_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Credit Note' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.cn_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.cn_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''
	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.cn_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''
		   	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Group Purchase' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	' LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID = LEFT (b.mrr_id,2)
     LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'		
			
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Purchase' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''
	


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'a.ref_sls_memo_no' as COL_EXPR,'' keyfield,'Ref SLS Memo No' AS col_header,	'',''

     INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'a.ref_sls_memo_dt' as COL_EXPR,'' keyfield,'Ref SLS Memo Dt' AS col_header,	'',''


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'a.ref_sls_memo_no' as COL_EXPR,'' keyfield,'Ref SLS Memo No' AS col_header,	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'a.ref_sls_memo_dt' as COL_EXPR,'' keyfield,'Ref SLS Memo Dt' AS col_header,	'',''
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.sisloc_eoss_discount_percentage' as COL_EXPR,'' AS keyfield,'SIS Loc Eoss Disc %' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_mrp)' as COL_EXPR,'SIS Loc Mrp' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_eoss_discount_amount)' as COL_EXPR,'SIS Loc Eoss Disc Amt' AS col_header 

	--NETSLS

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'a.ref_sls_memo_no' as COL_EXPR,'' keyfield,'Ref SLS Memo No' AS col_header,	'',''

     INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'a.ref_sls_memo_dt' as COL_EXPR,'' keyfield,'Ref SLS Memo Dt' AS col_header,	'',''
	   	 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.sisloc_eoss_discount_percentage' as COL_EXPR,'' AS keyfield,'SIS Loc Eoss Disc %' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_mrp)' as COL_EXPR,'SIS Loc Mrp' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_eoss_discount_amount)' as COL_EXPR,'SIS Loc Eoss Disc Amt' AS col_header 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.sisloc_gst_percentage' as COL_EXPR,'' AS keyfield,'SIS GST %' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'SIS GST %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party City' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column






	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_taxable_value)' as COL_EXPR,'SIS Loc Taxable Value' AS col_header 


	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_taxable_value)' as COL_EXPR,'SIS Loc Taxable Value' AS col_header 



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_igst_amount)' as COL_EXPR,'SIS Loc IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_igst_amount)' as COL_EXPR,'SIS Loc IGST Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc IGST Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_lgst_amount)' as COL_EXPR,'SIS Loc LGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_igst_amount+a.sisloc_cgst_amount+sisloc_sgst_amount)' as COL_EXPR,
	'SIS Loc Total GST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_itemnet_difference)' as COL_EXPR,
	'SIS Loc Item Net Diff' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sisloc_gst_difference)' as COL_EXPR,
	'SIS Loc Gst Diff' AS col_header 

	   	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_lgst_amount)' as COL_EXPR,'SIS Loc LGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_igst_amount+a.sisloc_cgst_amount+sisloc_sgst_amount)' as COL_EXPR,
	'SIS Loc Total GST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_itemnet_difference)' as COL_EXPR,
	'SIS Loc Item Net Diff' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sisloc_gst_difference)' as COL_EXPR,
	'SIS Loc Gst Diff' AS col_header 

	   	 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc LGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.lc)' as COL_EXPR,'Transaction Value at LC' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.mrp)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'Avg Unit Price' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'Basket Size' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'GM%' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 
	UNION ALL
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty*sku_names.mrp)' as COL_EXPR,'Transaction Value with GST' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 
	UNION ALL
	SELECT 'Common' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 
	UNION ALL
	SELECT 'Common' xn_type,'0' as COL_EXPR,'GM%' AS col_header 
	UNION ALL
	SELECT 'Common' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 
	UNION ALL
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Item Discount Amount' AS col_header 
	UNION ALL
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 


	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.old_discount_percentage' as COL_EXPR,'' AS keyfield,'Old Discount %' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.old_discount_percentage' as COL_EXPR,'' AS keyfield,'Old Discount %' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Old Discount %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	
	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.old_gst_percentage' as COL_EXPR,'' AS keyfield,'Old GST %' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	
	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.old_gst_percentage' as COL_EXPR,'' AS keyfield,'Old GST %' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column



		INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Old GST %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'Old Bill Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'Old Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.old_cmm_discount_amount)' as COL_EXPR,'Old Bill Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.old_gst_Amount)' as COL_EXPR,'Old GST Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.old_gst_Amount)' as COL_EXPR,'Old GST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.old_gst_Amount)' as COL_EXPR,'Old GST Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old GST Amount' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'Old Transaction Value with GST' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'Old Transaction Value with GST' AS col_header 

		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.old_xn_value_with_gst)' as COL_EXPR,'Old Transaction Value with GST' AS col_header 

	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old Transaction Value with GST' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'Old Taxable Value' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'Old Taxable Value' AS col_header 

	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return ' xn_type,'SUM(a.old_xn_value_without_gst)' as COL_EXPR,'Old Taxable Value' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old Taxable Value' AS col_header 

	   	  
    INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'Transaction Value at Old MRP' AS col_header 



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'Transaction Value at Old MRP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*a.old_mrp)' as COL_EXPR,'Transaction Value at Old MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Transaction Value at Old MRP' AS col_header 


	 INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(old_discount_amount)' as COL_EXPR,'Old Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(old_discount_amount)' as COL_EXPR,'Old Discount Amount' AS col_header 

	
	 INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(old_discount_amount)' as COL_EXPR,'Old Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old Discount Amount' AS col_header 



	 INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(OLD_NET)' as COL_EXPR,'Old Net Amount' AS col_header 



	 INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(OLD_NET)' as COL_EXPR,'Old Net Amount' AS col_header 
	
	 INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(OLD_NET)' as COL_EXPR,'Old Net Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Old Net Amount' AS col_header 


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'SIS Loc Eoss Disc %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc Mrp' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Loc Eoss Disc Amt' AS col_header 






	

	--AVG
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'(SUM(A.quantity)/SUM(WeightedQtyBillCount))' as COL_EXPR,'Basket Size' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'(SUM(A.RFNET)/SUM(WeightedQtyBillCount)) ' as COL_EXPR,'Avg Bill Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(RFNET)/(SUM(quantity)+0.001)' as COL_EXPR,'Avg Unit Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(WeightedQtyBillCount)' as COL_EXPR,'Bill Count' AS col_header 
		

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'(SUM(A.quantity)/SUM(WeightedQtyBillCount))' as COL_EXPR,'Basket Size' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'(SUM(A.RFNET)/SUM(WeightedQtyBillCount)) ' as COL_EXPR,'Avg Bill Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(RFNET)/(SUM(quantity)+0.001)' as COL_EXPR,'Avg Unit Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(WeightedQtyBillCount)' as COL_EXPR,'Bill Count' AS col_header 
	   	 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'(SUM(A.quantity)/SUM(WeightedQtyBillCount))' as COL_EXPR,'Basket Size' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'(SUM(A.RFNET)/SUM(WeightedQtyBillCount)) ' as COL_EXPR,'Avg Bill Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(RFNET)/(SUM(quantity)+0.001)' as COL_EXPR,'Avg Unit Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(WeightedQtyBillCount)' as COL_EXPR,'Bill Count' AS col_header 




	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Basket Size' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Avg Bill Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Avg Unit Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Bill Count' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Opening Stock' xn_type,'SUM(a.cbs_qty)' as COL_EXPR,'Transaction Qty' AS col_header,-1 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header,-1 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*(case when left(a.cm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'(case  when sum(a.quantity*sku_names.pp) <> 0 then SUM(a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/sum(a.quantity*sku_names.pp) else 0 end )' as COL_EXPR,'GM%' AS col_header 


	--INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	--SELECT 'Retail Sale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM%' AS col_header 

	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.xn_value_without_gst-a.quantity*sku_names.pp)' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*a.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.MRP' as COL_EXPR,'' AS keyfield,'Transaction MRP' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column,6.3	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at SKU MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.item_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'a.basic_discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.basic_discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'Avg(a.selling_days)' as COL_EXPR,'Selling Days' AS col_header 
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'a.card_discount_percentage' as COL_EXPR,'' keyfield,'Card Discount %' AS col_header,	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''
		


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Retail Sale' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	'LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.CM_ID,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'

		
		
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Retail Sale' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale' xn_type,'CONVERT(NUMERIC(10,2),ROUND((a.net-a.cmm_discount_amount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.card_discount_amount)' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.cmm_discount_amount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'(CASE WHEN SUM(a.quantity*a.mrp)<>0 then ROUND(SUM(a.discount_amount+a.cmm_discount_amount)*100/SUM(a.quantity*a.mrp),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'Total Discount Amount' AS col_header 
			
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale' xn_type,'SUM(a.sis_net)' as COL_EXPR,'SIS Amount' AS col_header 

	--GROSSSLS
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header,-1 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*(case when left(a.cm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'(case  when sum(a.quantity*sku_names.pp) <> 0 then SUM(a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/sum(a.quantity*sku_names.pp) else 0 end )' as COL_EXPR,'GM%' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.xn_value_without_gst-a.quantity*sku_names.pp)' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*a.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at SKU MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.MRP' as COL_EXPR,'' AS keyfield,'Transaction MRP' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column,6.3	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.item_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'a.basic_discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.basic_discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'Avg(a.selling_days)' as COL_EXPR,'Selling Days' AS col_header 
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'a.card_discount_percentage' as COL_EXPR,'' keyfield,'Card Discount %' AS col_header,	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''
		


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Gross Retail Sale' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	'LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.CM_ID,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'

		
		
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Gross Retail Sale' xn_type,'CONVERT(NUMERIC(10,2),ROUND((a.net-a.cmm_discount_amount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.card_discount_amount)' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.cmm_discount_amount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'(CASE WHEN SUM(a.quantity*a.mrp)<>0 then ROUND(SUM(a.discount_amount+a.cmm_discount_amount)*100/SUM(a.quantity*a.mrp),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'Total Discount Amount' AS col_header 
			
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Gross Retail Sale' xn_type,'SUM(a.sis_net)' as COL_EXPR,'SIS Amount' AS col_header 



	--SLR

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*(case when left(a.cm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at SKU MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*a.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.MRP' as COL_EXPR,'' AS keyfield,'Transaction MRP' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column,6.3	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.item_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'a.basic_discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.basic_discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'Avg(a.selling_days)' as COL_EXPR,'Selling Days' AS col_header 
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'a.card_discount_percentage' as COL_EXPR,'' keyfield,'Card Discount %' AS col_header,	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''
		


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Retail Sale Return' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	'LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.CM_ID,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'

		
		
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Retail Sale Return' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail Sale Return' xn_type,'CONVERT(NUMERIC(10,2),ROUND((a.net-a.cmm_discount_amount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.card_discount_amount)' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_master_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Card Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.cmm_discount_amount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'(CASE WHEN SUM(a.quantity*a.mrp)<>0 then ROUND(SUM(a.discount_amount+a.cmm_discount_amount)*100/SUM(a.quantity*a.mrp),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.discount_amount+a.cmm_discount_amount)' as COL_EXPR,'Total Discount Amount' AS col_header 
			
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Return' xn_type,'SUM(a.sis_net)' as COL_EXPR,'SIS Amount' AS col_header 
	   	  

	
		--APP
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Approval Issue' xn_type,'a.discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'' keyfield,'GST Cess%' AS col_header,	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Approval Issue' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''


	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Approval Issue' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header


	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Approval Issue' xn_type,'SUM(a.net*a.quantity)' as COL_EXPR,'Transaction Value (After Discount)' AS col_header

	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Approval Issue' xn_type,'a.net' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'b.discount_amount' as COL_EXPR,'Bill Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Issue' xn_type,'SUM(a.rfnet)' as COL_EXPR,	'Net Transaction Value' AS col_header 

	--APR
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.rfnet)' as COL_EXPR,
	'Net Transaction Value' AS col_header 



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Approval Return' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Approval Return' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Approval Return' xn_type,'a.rfnet' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.apd_product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(a.apd_product_code, ISNULL(NULLIF(CHARINDEX (''@'',a.apd_product_code)-1,-1),LEN(a.apd_product_code )))' as COL_EXPR,'' AS keyfield,'Item Code (without Batch)' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sku.basic_purchase_price' as COL_EXPR,'a.apd_product_code' AS keyfield,'Basic Purchase Price' AS col_header ,
	'Approval Return' xn_type,'sku' as joining_table,'product_code' joining_column

			
	--JWI
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header,-1 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.xn_value_with_gst)' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Issue' xn_type,'a.job_rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Job Work Issue' xn_type,'SUM(a.job_rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Issue' xn_type,'a.job_rate' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Issue' xn_type,'SUM(a.xn_value_with_gst)' as COL_EXPR,
	'Net Transaction Value' AS col_header 


	--JWR
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 
	
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.xn_value_with_gst)' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Receive' xn_type,'a.job_rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Job Work Receive' xn_type,'SUM(a.job_rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Job Work Receive' xn_type,'a.job_rate' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Job Work Receive' xn_type,'SUM(a.xn_value_with_gst)' as COL_EXPR,
	'Net Transaction Value' AS col_header 



	
	--RPS
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail PackSlip' xn_type,'a.basic_discount_percentage' as COL_EXPR,'' as keyfield,
	'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.basic_discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail PackSlip' xn_type,'a.card_discount_percentage' as COL_EXPR,'' keyfield,'Card Discount %' AS col_header,
	'',''

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Retail PackSlip' xn_type,'a.mrp' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Retail PackSlip' xn_type,'SUM(a.mrp*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Retail PackSlip' xn_type,'CONVERT(NUMERIC(10,2),a.Net/a.quantity)' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.card_discount_amount)' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'b.discount_amount' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Total Discount Amount' AS col_header 


	 --CNPS	 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 
	

	   	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Creditnote PackSlip' xn_type,'a.Rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Creditnote PackSlip' xn_type,'SUM(a.Rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Creditnote PackSlip' xn_type,'a.rate' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Creditnote PackSlip' as xn_type,'' as joining_table,'' joining_column,54


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sku_names.sn_hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column,34
	   	  
	 --DNPS


	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sku_names.sn_hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column,34

	 	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 
	

	   	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Debitnote PackSlip' xn_type,'a.Rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Debitnote PackSlip' xn_type,'SUM(a.Rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Debitnote PackSlip' xn_type,'a.rate' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Debitnote PackSlip' as xn_type,'' as joining_table,'' joining_column,54

	--DNPR



	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sku_names.sn_hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column,34

	 	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 
	

	   	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Debitnote PackSlip Return' xn_type,'a.Rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Debitnote PackSlip Return' xn_type,'SUM(a.Rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Debitnote PackSlip Return' xn_type,'a.rate' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debitnote PackSlip Return' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Debitnote PackSlip Return' as xn_type,'' as joining_table,'' joining_column,54

	--cnpr

	

	 INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sku_names.sn_hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column,34

	 	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 
		
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Item Round off' AS col_header 
	

	   	   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 
	
	

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Creditnote PackSlip Return' xn_type,'a.Rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Creditnote PackSlip Return' xn_type,'SUM(a.Rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	INSERT #transaction_analysis_master_COLS	(xn_type,COL_EXPR, COL_HEADER) 
	SELECT 'Creditnote PackSlip Return' xn_type,'a.rate' as COL_EXPR,'Transaction Rate (After Discount)' AS col_header
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Card Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Creditnote PackSlip Return' xn_type,'0' as COL_EXPR,'Total Discount Amount' AS col_header 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Creditnote PackSlip Return' as xn_type,'' as joining_table,'' joining_column,54

	




	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*(case when left(b.mrr_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.PIMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.pimdiscountamount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase' xn_type,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Purchase' xn_type,'a.purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Purchase' xn_type,'SUM(a.purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Purchase' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.pimdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then 	ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Debit Note' xn_type,'a.purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Debit Note' xn_type,'SUM(a.purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Debit Note' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'Avg(a.wsl_selling_days)' as COL_EXPR,'Selling Days' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'(SUM(A.quantity)/(SUM(WSL_WeightedQtyBillCount)+0.001))' as COL_EXPR,'Basket Size' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'(SUM(A.RFNET)/(SUM(WSL_WeightedQtyBillCount)+0.001))' as COL_EXPR,'Avg Bill Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(RFNET)/(SUM(quantity)+0.001)' as COL_EXPR,'Avg Unit Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(wsl_WeightedQtyBillCount)' as COL_EXPR,'Bill Count' AS col_header 



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*(case when left(a.inv_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.pp))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM((a.xn_value_without_gst-(a.quantity*sku_names.PP_WO_DP))*100/(a.quantity*sku_names.pp))' as COL_EXPR,
	'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Wholesale' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,	'',''

		

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Wholesale' xn_type,'LMB.ac_name' as COL_EXPR,'' keyfield,'Broker Name' AS col_header,	'','',
	'  LEFT JOIN LM01106 LMB (NOLOCK)  ON LMB.Ac_Code =b.Broker_ac_code'


		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	  SELECT 'Credit Note' xn_type,'LMBR.ac_name' as COL_EXPR,'' keyfield,'Broker Name' AS col_header,	'','',
	'  LEFT JOIN LM01106 LMBR (NOLOCK)  ON LMBR.Ac_Code =b.Broker_ac_code'

		

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column,addnl_join)     
	SELECT 'Wholesale' xn_type,'GSTSTCODE.GST_STATE_CODE' as COL_EXPR,'' keyfield,'Transaction Location GST State Code' AS col_header,	'','',
	'LEFT JOIN LOCATION LGST (NOLOCK) ON LGST.DEPT_ID =LEFT (b.inv_id,2)
    LEFT JOIN GST_STATE_MST GSTSTCODE (NOLOCK)  ON GSTSTCODE.GST_STATE_CODE =LGST.GST_STATE_CODE'


		
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Wholesale' xn_type,'b.party_state_code' as COL_EXPR,'' keyfield,'Party GST State Code' AS col_header,	'',''

	   

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Wholesale' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Wholesale' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale(OH)' xn_type,'' as joining_table,'' joining_column
	
	


	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Purchase(OH)' xn_type,'OH Amount' as COL_EXPR,'OH Amount' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale(OH)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Wholesale(OH)' xn_type,'OH Amount' as COL_EXPR,'OH Amount' AS col_header
	   	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Wholesale(OH)' xn_type,'OH GST' as COL_EXPR,'OH GST' AS col_header


	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Retail Sale(OH)' xn_type,'OH Amount' as COL_EXPR,'OH Amount' AS col_header
	   	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Retail Sale(OH)' xn_type,'OH GST' as COL_EXPR,'OH GST' AS col_header

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Retail Sale Return(OH)' xn_type,'OH Amount' as COL_EXPR,'OH Amount' AS col_header
	   	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR,COL_HEADER)     
	SELECT 'Retail Sale Return(OH)' xn_type,'OH GST' as COL_EXPR,'OH GST' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '[OPSDT]' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Opening Stock' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Opening Stock' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Opening Stock' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'a.dept_id' AS keyfield,'Transaction Location Name' AS col_header ,
	'Opening Stock' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''CNC''+b.cnc_memo_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Opening Stock' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'new_product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Stock Creation (IRR)' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Stock Creation (IRR)' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Stock Consumption (IRR)' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Stock Creation (SNC)' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Stock Consumption (SNC)' as xn_type,'' as joining_table,'' joining_column,54


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cnc_memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.irm_memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Stock Creation (IRR)' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.irm_memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Stock Consumption (IRR)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Stock Creation (SNC)' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Stock Consumption (SNC)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.irm_memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Stock Creation (IRR)' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.irm_memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Stock Consumption (IRR)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Stock Creation (SNC)' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Stock Consumption (SNC)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cnc_memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cnc_memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cnc_memo_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Stock Cancellation' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cnc_memo_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Stock Cancellation' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'bin' as joining_table,'bin_id' joining_column,'bin_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WPS''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.ps_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.ps_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Wholesale Pack Slip out' xn_type,'location' as joining_table,'dept_id' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'bin' as joining_table,'bin_id' joining_column,'bin_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WPS''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale Pack Slip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*(case when left(a.cn_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.CNMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.CNMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note' xn_type,'SUM(a.discount_amount+a.CNMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Credit Note' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Credit Note' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Credit Note' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.cnmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column


	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT 'Inactive' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column






	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'party_code' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Party Erp Code' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column
	   	  


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Retail Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''SLS''+b.cm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.passport_no' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ticket_no' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.flight_no' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dt_name' as COL_EXPR,'b.dt_code' AS keyfield,'Discount Type' AS col_header ,
	'Retail Sale' xn_type,'dtm' as joining_table,'dt_code' joining_column,'' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ' (case when tax_method= 2 then ''Exclusive'' Else ''Inclusive'' End)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	   
	--GROSSSLS

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT 'Inactive' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column





	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'party_code' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Party Erp Code' AS col_header ,
	'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Gross Retail Sale' xn_type,'location' as joining_table,'dept_id' joining_column
	   	  


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Gross Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Gross Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Gross Retail Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Gross Retail Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''SLS''+b.cm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Gross Retail Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.passport_no' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ticket_no' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.flight_no' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dt_name' as COL_EXPR,'b.dt_code' AS keyfield,'Discount Type' AS col_header ,
	'Gross Retail Sale' xn_type,'dtm' as joining_table,'dt_code' joining_column,'' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ' (case when tax_method= 2 then ''Exclusive'' Else ''Inclusive'' End)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column





	--SLR

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column


	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT 'Inactive' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'party_code' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Party Erp Code' AS col_header ,
	'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Retail Sale Return' xn_type,'location' as joining_table,'dept_id' joining_column
	   	  


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Retail Sale Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Retail Sale Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Retail Sale Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Retail Sale Return' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''SLS''+b.cm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column
 
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Retail Sale Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.passport_no' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ticket_no' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.flight_no' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.scheme_name' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dt_name' as COL_EXPR,'b.dt_code' AS keyfield,'Discount Type' AS col_header ,
	'Retail Sale Return' xn_type,'dtm' as joining_table,'dt_code' joining_column,'' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ' (case when tax_method= 2 then ''Exclusive'' Else ''Inclusive'' End)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column


	 --APP
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Approval Issue' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Approval Issue' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Approval Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Approval Issue' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''APP''+b.memo_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Approval Issue' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column
	
	--APR
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Approval Return' xn_type,'location' as joining_table,'dept_id' joining_column
	   

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Approval Return' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.memo_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Approval Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Approval Return' xn_type,'bin' as joining_table,'bin_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''APR''+b.memo_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.memo_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column
 
 	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Approval Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person 2' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column,'' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person 3' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column,'' as  joining_table_alias

	
	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Approval Return' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person alias 2' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column,'' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person alias 3' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column,'' as  joining_table_alias




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(memo_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column
	
	--JWI	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.issue_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.issue_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Job Work Issue' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.issue_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Job Work Issue' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.issue_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Job Work Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.issue_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Job Work Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.issue_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Job Work Issue' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Job Work Issue' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.issue_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''JWI''+b.issue_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.issue_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column
 	
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(issue_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'' joining_column
	
	--JWR
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.receipt_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.receipt_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Job Work Receive' xn_type,'location' as joining_table,'dept_id' joining_column
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.REF_NO' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.challan_no' as COL_EXPR,'' AS keyfield,'Challan No' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.challan_dt' as COL_EXPR,'' AS keyfield,'Challan Date' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.receipt_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Job Work Receive' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.receipt_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Job Work Receive' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.receipt_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Job Work Receive' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.receipt_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Job Work Receive' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Job Work Receive' xn_type,'bin' as joining_table,'bin_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''JWR''+b.receipt_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column
 
 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'' joining_column
	
	
	
	--RPS
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Retail PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Retail PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.cm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Retail PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Retail PackSlip' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''RPS''+b.cm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Retail PackSlip' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column
	
	
   --CNPS

		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Creditnote PackSlip' xn_type,'lm01106' as joining_table,'ac_code' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.ps_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Creditnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Creditnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Creditnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Creditnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Creditnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Creditnote PackSlip' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Ps_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''CNP''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column
 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Creditnote PackSlip' xn_type,'' as joining_table,'' joining_column

	--DNPS

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Debitnote PackSlip' xn_type,'lm01106' as joining_table,'ac_code' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.ps_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Debitnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Debitnote PackSlip' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Debitnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Debitnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Debitnote PackSlip' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Debitnote PackSlip' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Ps_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''DNP''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column
 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Debitnote PackSlip' xn_type,'' as joining_table,'' joining_column

	--DNPR

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'lm01106' as joining_table,'ac_code' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.ps_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Ps_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''DNR''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column
 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Debitnote PackSlip Return' xn_type,'' as joining_table,'' joining_column






	--CNPR

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'lm01106' as joining_table,'ac_code' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.ps_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'left(b.ps_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'bin' as joining_table,'bin_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Ps_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''DNR''+b.ps_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ps_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column
 	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(ps_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Creditnote PackSlip Return' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(CASE WHEN ISNULL(b.xn_item_type,0) IN (0,1) then b.dept_id else b.pur_for_dept_id END)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.dept_name' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Name' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.loc_gst_no' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.dept_alias' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location Area' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location City' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'b.dept_id' AS keyfield,'Transaction Location State' AS col_header ,
	'Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PUR''+b.mrr_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column
	   


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'ac_name' as COL_EXPR,'b.SHIPPING_FROM_AC_CODE' AS keyfield,'Oem party Name' AS col_header ,
	'Purchase' xn_type,'lm01106' as joining_table,'ac_code' joining_column,'oem' as  joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.mp_percentage' as COL_EXPR,'' AS keyfield,'MP %' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.md_percentage' as COL_EXPR,'' AS keyfield,'MD %' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when b.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when a.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'ac_name' as COL_EXPR,'b.SHIPPING_AC_CODE' AS keyfield,'Oem party Name' AS col_header ,
	'Debit note' xn_type,'lm01106' as joining_table,'ac_code' joining_column,'oemprt' as  joining_table_alias
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(B.RM_ID,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.RM_ID,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(B.RM_ID,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Debit note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Debit note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Debit note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PRT''+b.rm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	   
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.gst_itc_dt' as COL_EXPR,'' AS keyfield,'GST ITC Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column
	
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when b.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column

	   	 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Wholesale' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Wholesale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Wholesale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSL''+b.inv_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column, 'emp1' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as joining_table_alias
	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Wholesale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Order_no' as COL_EXPR,'' AS keyfield,'Order No' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ONLINE_BILL_REF_NO' as COL_EXPR,'' AS keyfield,'ONLINE BILL REF NO' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.buyer_order_no' as COL_EXPR,'' AS keyfield,'Manual Buyer Order No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'lmp.party_erp_code' as COL_EXPR,'' AS keyfield,'Party Erp Code' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column, '' as joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.packing_gst_percentage' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'packing gst%' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sku.basic_purchase_price' as COL_EXPR,'a.product_code' AS keyfield,'Basic Purchase Price' AS col_header ,
	'Common' xn_type,'sku' as joining_table,'product_code' joining_column

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Wholesale' xn_type,'(packing_igst_amount + packing_cgst_amount + packing_sgst_amount)' as COL_EXPR,'Packing GST Amt' AS col_header
	
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Sale' xn_type,'(packing_igst_amount + packing_cgst_amount + packing_sgst_amount)' as COL_EXPR,'Packing GST Amt' AS col_header


	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'(packing_igst_amount + packing_cgst_amount + packing_sgst_amount)' as COL_EXPR,'Packing GST Amt' AS col_header

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'(packing_igst_amount + packing_cgst_amount + packing_sgst_amount)' as COL_EXPR,'Packing GST Amt' AS col_header



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Packing GST Amt' AS col_header 

	

	
	



	--COMMON


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Bill Remarks' AS col_header ,
	'Opening Stock' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Remarks' as COL_EXPR,'' AS keyfield,'Bill Remarks' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(a.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',a.PRODUCT_CODE)-1,-1),LEN(a.PRODUCT_CODE )))' as COL_EXPR,'' AS keyfield,'Item Code (without Batch)' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Scheme Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Challan No' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Challan Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	   	 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	   	 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Order No' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'ONLINE BILL REF NO' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Oem party Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  '0' as COL_EXPR,'' AS keyfield,'MP %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  '0' as COL_EXPR,'' AS keyfield,'MD %' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Manual Buyer Order No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person alias 1' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person alias 2' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person alias 3' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
			

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT ''''''  as COL_EXPR,'' AS keyfield,'Transaction Location Inactive' AS col_header ,
	--'Common' xn_type,'' as joining_table,'' joining_column
	
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when a.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Order_no' as COL_EXPR,'' AS keyfield,'Order No' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'ONLINE_BILL_REF_NO' as COL_EXPR,'' AS keyfield,'ONLINE BILL REF NO' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Order_no' as COL_EXPR,'' AS keyfield,'Manual Buyer Order No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column






	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'a.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Bin' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSR''+b.cn_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EInv_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as joining_table_alias
	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Credit Note' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias
	   	 


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(cn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'' joining_column

	   		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

		   	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column




	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Party_Gst_No' as COL_EXPR,'' AS keyfield,'Party GST no.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	
	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	--SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	--'Retail Sale' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(b.Party_Gst_No,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column, '' as  addnl_join 

		



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ''''''  as COL_EXPR,'' AS keyfield,'Party Pan no.' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column


		INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.CITY' as COL_EXPR,'b.customer_code' AS keyfield,'Party City' AS col_header ,
	'Retail Sale' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.STATE' as COL_EXPR,'b.customer_code' AS keyfield,'Party State' AS col_header ,
	'Retail Sale' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column



	--GROSSSLS

			

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

		   	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column




	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Party_Gst_No' as COL_EXPR,'' AS keyfield,'Party GST no.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	
	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	--SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	--'Gross Retail Sale' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(b.Party_Gst_No,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column, '' as  addnl_join 

		



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ''''''  as COL_EXPR,'' AS keyfield,'Party Pan no.' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Gross Retail Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Gross Retail Sale' xn_type,'custdym' as joining_table,'customer_code' joining_column


		INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.CITY' as COL_EXPR,'b.customer_code' AS keyfield,'Party City' AS col_header ,
	'Gross Retail Sale' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.STATE' as COL_EXPR,'b.customer_code' AS keyfield,'Party State' AS col_header ,
	'Gross Retail Sale' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column




	--SLR

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column


	
	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	--SELECT 'customer_fname+'' ''+customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Ref Party Name' AS col_header ,
	--'Retail Sale Return' xn_type,'custdym' as joining_table,'ref_customer_code' joining_column, 'REFCUS' as joining_table_alias

	   	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 

		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT ''''''  as COL_EXPR,'' AS keyfield,'Party Pan no.' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Retail Sale Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Retail Sale Return' xn_type,'custdym' as joining_table,'customer_code' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.CITY' as COL_EXPR,'b.customer_code' AS keyfield,'Party City' AS col_header ,
	'Retail Sale Return' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.STATE' as COL_EXPR,'b.customer_code' AS keyfield,'Party State' AS col_header ,
	'Retail Sale Return' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column





	--APP
    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 
	



		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Approval Issue' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.CITY' as COL_EXPR,'b.customer_code' AS keyfield,'Party City' AS col_header ,
	'Approval Issue' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.STATE' as COL_EXPR,'b.customer_code' AS keyfield,'Party State' AS col_header ,
	'Approval Issue' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	--APR
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 
		

		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Approval Return' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.CITY' as COL_EXPR,'b.customer_code' AS keyfield,'Party City' AS col_header ,
	'Approval Return' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CUST_ATTR_NAMES.STATE' as COL_EXPR,'b.customer_code' AS keyfield,'Party State' AS col_header ,
	'Approval Return' xn_type,'CUST_ATTR_NAMES' as joining_table,'customer_code' joining_column
	   
	   --JWI 

	   
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Job Work Issue' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Job Work Issue' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON PAM.ac_code= REGAC.ac_code ' as  addnl_join 
		


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Job Work Issue' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.mobile' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Job Work Issue' xn_type,'lmp01106' as joining_table,'ac_code' joining_column


		INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party City' AS col_header ,
	'Job Work Issue' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party State' AS col_header ,
	'Job Work Issue' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 



	--JWR
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Job Work Receive' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Job Work Receive' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON PAM.ac_code= REGAC.ac_code ' as  addnl_join 

	   	  
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Job Work Receive' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Job Work Receive' xn_type,'lmp01106' as joining_table,'ac_code' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party City' AS col_header ,
	'Job Work Receive' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'PAM.ac_code' AS keyfield,'Party State' AS col_header ,
	'Job Work Receive' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 


	   
	   --RPS
	    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.customer_fname+'' ''+custdym.customer_lname' as COL_EXPR,'b.customer_code' AS keyfield,'Party Name' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'card_no' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card No.' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_card_expiry' as COL_EXPR,'b.customer_code' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus_gst_no' as COL_EXPR,'b.customer_code' AS keyfield,'Party GST no.' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column


	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGCUST.cus_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.customer_code' AS keyfield,'Party registration status' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'customer_code' joining_column, '  JOIN CUSTDYM  REGCUST ON b.CUSTOMER_CODE= REGCUST.CUSTOMER_CODE ' as  addnl_join 



		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'custdym.mobile' as COL_EXPR,'b.customer_code' AS keyfield,'Party Mobile' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Email' as COL_EXPR,'b.customer_code' AS keyfield,'Party Email' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_birth' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Birth' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dt_anniversary' as COL_EXPR,'b.customer_code' AS keyfield,'Date of Anniversary' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address1' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.customer_code' AS keyfield,'Party Address2' AS col_header ,
	'Retail PackSlip' xn_type,'custdym' as joining_table,'customer_code' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Purchase' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)  
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Purchase' xn_type ,'lmp01106' as joining_table,'ac_code' joining_column

	   

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON b.ac_code= REGAC.ac_code ' as  addnl_join 

	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Purchase' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Purchase' xn_type,'lmp01106' as joining_table,'ac_code' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'b.ac_code' AS keyfield,'Party City' AS col_header ,
	'Purchase' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Purchase' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Vendor Bill Date' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Debit note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	   
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Debit note' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON b.ac_code= REGAC.ac_code ' as  addnl_join 




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Debit note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Debit note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'b.ac_code' AS keyfield,'Party City' AS col_header ,
	'Debit note' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Debit note' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 





	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Wholesale' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Wholesale' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON b.ac_code= REGAC.ac_code ' as  addnl_join 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Wholesale' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Wholesale' xn_type,'lmp01106' as joining_table,'ac_code' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'b.ac_code' AS keyfield,'Party City' AS col_header ,
	'Wholesale' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Wholesale' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Credit Note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmp01106.ac_gst_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party GST no.' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column


	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGAC.ac_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.ac_code' AS keyfield,'Party registration status' AS col_header ,
	'Credit Note' xn_type,'' as joining_table,'ac_code' joining_column, '  JOIN lmp01106  REGAC ON b.ac_code= REGAC.ac_code ' as  addnl_join 




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.ac_code' AS keyfield,'Party Pan no.' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'alias' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Credit Note' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'mobile' as COL_EXPR,'b.ac_code' AS keyfield,'Party Mobile' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'E_MAIL' as COL_EXPR,'b.ac_code' AS keyfield,'Party Email' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address1' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.ac_code' AS keyfield,'Party Address2' AS col_header ,
	'Credit Note' xn_type,'lmp01106' as joining_table,'ac_code' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.CITY' as COL_EXPR,'b.ac_code' AS keyfield,'Party City' AS col_header ,
	'Credit Note' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.State' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Credit Note' xn_type,'lmv01106' as joining_table,'ac_code' joining_column 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Purchase' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Purchase' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PUR''+b.mrr_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Vendor Bill Date' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.inv_id,2)= REGLOC.dept_id ' as  addnl_join 
	



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Purchase' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Purchase' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party City' AS col_header ,
	'Group Purchase' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party State' AS col_header ,
	'Group Purchase' xn_type,'loc_view' as joining_table,'dept_id' joining_column 




	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Purchase' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Purchase' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Purchase' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Purchase' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Purchase' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Purchase' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.pimdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Credit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Credit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSR''+b.cn_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.rm_id,2)= REGLOC.dept_id ' as  addnl_join 


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Credit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Credit Note' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party City' AS col_header ,
	'Group Credit Note' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party State' AS col_header ,
	'Group Credit Note' xn_type,'loc_view' as joining_table,'dept_id' joining_column 



	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Credit Note' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Credit Note' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Credit Note' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Sale' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Sale' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSL''+b.inv_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Group Sale' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	   	  
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON b.party_dept_id = REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Sale' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Sale' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Group Sale' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Group Sale' xn_type,'loc_view' as joining_table,'dept_id' joining_column 




	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Sale' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Sale' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Sale' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.dept_name' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'sl.dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Debit Note' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Debit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Debit Note' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PRT''+b.rm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

		

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'dept_id' joining_column, 
	'  JOIN location  REGLOC ON b.party_dept_id= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Debit Note' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Debit Note' xn_type,'location' as joining_table,'dept_id' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Group Debit Note' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Group Debit Note' xn_type,'loc_view' as joining_table,'dept_id' joining_column 





	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Debit Note' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
   SELECT 'A.bill_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
   'Group Debit Note' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Debit Note' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Debit Note' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )     
	SELECT 'dept_name' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )          
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )          
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PRT''+b.rm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'
	
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,
	'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'dept_id' joining_column, 
	'  JOIN location  REGLOC ON b.party_dept_id= REGLOC.dept_id ' as  addnl_join 
	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_target'


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan Out(Debit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 






	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )     
	SELECT 'dept_name' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column,'bin_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'bin_name' as COL_EXPR,'b.target_bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column,'bin_target'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSL''+b.inv_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column, 'emp1' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias
	   


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	  

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON party_dept_id= REGLOC.dept_id ' as  addnl_join 

	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan Out(Wholesale)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 




	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )     
	SELECT 'dept_name' as COL_EXPR,'left(b.MRR_ID,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PUR''+b.mrr_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	
		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.inv_id,2)= REGLOC.dept_id ' as  addnl_join 



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.CITY' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 

    INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan In(Purchase)' xn_type,'loc_view' as joining_table,'dept_id' joining_column 



	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Delivery Challan In(Purchase)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.pimdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSR''+b.cn_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column


	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'CAST(CASE WHEN ISNULL(location.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.cnmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)         
	SELECT 'dept_name' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)    
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Delivery Challan In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSR''+b.cn_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column
		
			
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,
	'LEFT(b.rm_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'dept_id' joining_column,
	'  JOIN location  REGLOC ON LEFT(b.rm_id,2)= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan In(Credit Note)2' xn_type,'loc_view' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Credit Note)2' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.rm_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.rm_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PRT''+b.rm_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.rm_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.rm_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,
	'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON b.party_dept_id= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.state' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Group Transfer Out(Debit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.inv_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.inv_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)          
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)          
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_src'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.manual_inv_no' as COL_EXPR,'' AS keyfield,'Refrence No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'sbin.bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column,'sbin' joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'tbin.bin_name' as COL_EXPR,'b.target_bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'bin' as joining_table,'bin_id' joining_column,'tbin' joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSL''+b.inv_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.inv_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person 1' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person 2' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_name' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person 3' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code' AS keyfield,'Sales person alias 1' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp1' as  joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code1' AS keyfield,'Sales person alias 2' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp2' as  joining_table_alias

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'emp_alias' as COL_EXPR,'a.emp_code2' AS keyfield,'Sales person alias 3' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'employee' as joining_table,'emp_code' joining_column,'emp3' as  joining_table_alias

	   

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.inv_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column
	   	
		

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party registration status' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON b.party_dept_id= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Loc_view.city' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party City' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Loc_view.State' as COL_EXPR,'b.party_dept_id' AS keyfield,'Party State' AS col_header ,
	'Group Transfer Out(Wholesale)' xn_type,'loc_view' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_mrr'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''PUR''+b.mrr_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'c.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.inv_id,2)= REGLOC.dept_id ' as  addnl_join 
	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party City' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.inv_id,2)' AS keyfield,'Party State' AS col_header ,
	'Group Transfer In(Purchase)' xn_type,'loc_view' as joining_table,'dept_id' joining_column


	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'a.rate' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
		'',''
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.net_rate*a.quantity)-a.inmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
	ELSE
		INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
		SELECT 'Group Transfer In(Purchase)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.pimdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
		'Transaction Rate (After Discount)' AS col_header,'',''
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.cn_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )     
	SELECT 'dept_name' as COL_EXPR,'left(b.cn_id,2)' AS keyfield,'Transaction Location Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )      
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias )      
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column,'loc_cn'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.cn_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cn_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''WSR''+b.cn_id' as COL_EXPR,'' AS keyfield,'Transaction Id' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.EINV_IRN_NO' as COL_EXPR,'' AS keyfield,'IRN No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_DT' as COL_EXPR,'' AS keyfield,'IRN Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ACH_NO' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Acknowledgement No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column
	
		   
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.rm_id,2)= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'location' as joining_table,'dept_id' joining_column


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party City' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.rm_id,2)' AS keyfield,'Party State' AS col_header ,
	'Group Transfer In(Credit Note)' xn_type,'loc_view' as joining_table,'dept_id' joining_column




	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'left(b.mrr_id,2)' AS keyfield,table_caption AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

		INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.mrr_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Alias' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'area_name' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location Area' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location City' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Transaction Location State' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Transaction Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'bin_name' as COL_EXPR,'b.bin_id' AS keyfield,'Target Location Bin' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'bin' as joining_table,'bin_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.mrr_no' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column
 
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.receipt_dt' as COL_EXPR,'' AS keyfield,'Target Location Receipt Date' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(week,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Week No.' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month No.' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datename(month,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Month Name' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(year,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Year' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'datepart(day,b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Day' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(b.receipt_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party Name' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_gst_no' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party GST no.' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column
	
	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'CAST(CASE WHEN ISNULL(REGLOC.loc_gst_no,'''')<>'''' THEN ''Registered'' ELSE ''Unregistered'' END AS VARCHAR(50))' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party registration status' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'dept_id' joining_column, '  JOIN location  REGLOC ON LEFT(b.mrr_id,2)= REGLOC.dept_id ' as  addnl_join 

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'pan_no' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party Pan no.' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_alias' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party Alias' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Email' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address1' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party Address1' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'address2' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party Address2' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'location' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.city' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party City' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'loc_view.State' as COL_EXPR,'LEFT(b.mrr_id,2)' AS keyfield,'Party State' AS col_header ,
	'Delivery Challan In(Purchase)2' xn_type,'loc_view' as joining_table,'dept_id' joining_column



	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Purchase)2' xn_type,'a.gross_purchase_price' as COL_EXPR,'' keyfield,'Transaction Rate (Before Discount)' AS col_header,
	'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_dt' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Delivery Challan In(Purchase)2' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_dt' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Delivery Challan In(Purchase)' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_dt' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Group Purchase' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_dt' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Group Transfer In(Purchase)' as xn_type,'' as joining_table,'' joining_column,52	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_no' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Delivery Challan In(Purchase)2' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_no' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Delivery Challan In(Purchase)' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_no' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Group Purchase' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_no' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Group Transfer In(Purchase)' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_no' as COL_EXPR,'' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,52

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Delivery Challan In(Purchase)2' xn_type,'SUM(a.gross_purchase_price*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header
	
	
	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Delivery Challan In(Purchase)2' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.pimdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''

	INSERT #transaction_analysis_calculative_COLS	(xn_type,COL_EXPR, COL_HEADER)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.rate*a.quantity)' as COL_EXPR,'Transaction Value (Before Discount)' AS col_header

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR, keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Group Transfer In(Credit Note)' xn_type,'CONVERT(NUMERIC(10,2),ROUND(((a.purchase_price*a.quantity)-a.rmmdiscountamount)/a.quantity,2))' as COL_EXPR,'' keyfield,
	'Transaction Rate (After Discount)' AS col_header,'',''


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header,-1 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*(case when left(a.rm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 
		



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Debit Note)' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*(case when left(a.rm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 
		

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Debit Note)' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*(case when left(b.mrr_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.PIMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
		
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.inmdiscountamount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.pimdiscountamount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 
	

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Delivery Challan In(Purchase)' xn_type,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*(case when left(b.mrr_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.PIMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
	
	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.inmdiscountamount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.pimdiscountamount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Transfer In(Purchase)' xn_type,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*(case when left(a.inv_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

			   
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan Out(Wholesale)' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*(case when left(a.inv_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.INMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.INMDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer Out(Wholesale)' xn_type,'SUM(a.discount_amount+a.INMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*(case when left(B.cn_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


		


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.cnMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.cnmDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Delivery Challan In(Credit Note)' xn_type,'SUM(a.discount_amount+a.cnMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*(case when left(B.cn_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'0' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 
	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.rmMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.rmmDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Transfer In(Credit Note)' xn_type,'SUM(a.discount_amount+a.rmMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*(case when left(b.mrr_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Purchase' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.inmdiscountamount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.pimdiscountamount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 
	

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'SUM(a.discount_amount+a.inmdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'SUM(a.discount_amount+a.pimdiscountamount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	IF @cCurLocId=@cHoLocId
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'SUM(a.InMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
	ELSE
		INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
		SELECT 'Group Purchase' xn_type,'SUM(a.piMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header ,-1

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*(case when left(a.rm_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Debit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header,-1 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*(case when left(a.inv_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.InMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'(CASE WHEN SUM(a.quantity*a.rate)<>0 then ROUND(SUM(a.discount_amount+a.InmDiscountAmount)*100/SUM(a.quantity*a.rate),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Sale' xn_type,'SUM(a.discount_amount+a.InmDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*(case when left(b.cn_id,2)= [GHOLOCATION] THEN sku_names.pp else sxfp.LOC_PP end))' as COL_EXPR,'Transaction Value at PP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM%' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM% (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'0' as COL_EXPR,'GM Amount (w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Value at Transaction MRP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Transaction Value at WSP' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.tax_round_off)' as COL_EXPR,'Item Round off' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.discount_amount)' as COL_EXPR,'Item Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.RMMDiscountAmount)' as COL_EXPR,'Bill Discount Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'(CASE WHEN SUM(a.quantity*a.gross_purchase_price)<>0 then ROUND(SUM(a.discount_amount+a.RMMDiscountAmount)*100/SUM(a.quantity*a.gross_purchase_price),2) else 0 end)' as COL_EXPR,'Total Discount %' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Group Credit Note' xn_type,'SUM(a.discount_amount+a.RMMDiscountAmount)' as COL_EXPR,'Total Discount Amount' AS col_header 



	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Return' xn_type,'0' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'SUM(rate*quantity)' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail PackSlip' xn_type,'SUM(a.net)' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.xn_value_without_gst+a.cgst_amount+a.sgst_amount+a.igst_amount)' as COL_EXPR,
	'Transaction Value (After Discount)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.cgst_amount+a.sgst_amount+a.igst_amount)' as COL_EXPR,
	'Total Gst Amount' AS col_header 
	

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,
	'Net Transaction Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,
	'Net Transaction Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'SUM(rate*quantity)' as COL_EXPR,
	'Net Transaction Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.rfnet)' as COL_EXPR,
	'Net Transaction Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'SIS Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Selling Days' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Stock Creation (SNC)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Stock Consumption (SNC)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.irm_memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Stock Creation (IRR)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LEFT(b.irm_memo_id,2)' as COL_EXPR,'' AS keyfield,'Transaction Location Id' AS col_header ,
	'Stock Consumption (IRR)' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Creation (SNC)' xn_type,'SUM(c.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Creation (SNC)' xn_type,'SUM(c.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	
	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.quantity)' as COL_EXPR,'Transaction Qty' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'Taxable Value' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.xn_value_without_gst)' as COL_EXPR,'Taxable Value' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'OPening Stock' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.gst_cess_amount)' as COL_EXPR,'Gst Cess Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.igst_amount)' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Opening Stock' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'IGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.cgst_amount)' as COL_EXPR,'CGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.sgst_amount)' as COL_EXPR,'SGST Amount' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Transaction Value at PP' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.quantity*sku_names.LC)' as COL_EXPR,'Transaction Value at LC' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.quantity*sku_names.PP_WO_DP)' as COL_EXPR,'Transaction Value at PP(w/o Dep)' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Stock Cancellation' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Openning Stock' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Out' xn_type,'0' as COL_EXPR,'Transaction Value with GST' AS col_header 


	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'SUM(a.xn_value_with_gst)' as COL_EXPR,'Transaction Value with GST' AS col_header 

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person 1' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Transaction Location GST No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person 2' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Sales person 3' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party Erp Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias

	   
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party registration status' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'' as joining_table_alias

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'XN_ITEM_TYPE_DESC' as COL_EXPR,'b.XN_ITEM_TYPE' AS keyfield,'Transaction Item type' AS col_header ,
	'Purchase' xn_type,'XN_ITEM_TYPE_DESC_mst' as joining_table,'XN_ITEM_TYPE' joining_column,3

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ISNULL(sku_names.SKU_ITEM_TYPE_DESC,'''')' as COL_EXPR,'a.product_code' AS keyfield,'Transaction Item type' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'article_no' as COL_EXPR,'a.product_code' AS keyfield,'Article no.' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'article_alias' as COL_EXPR,'a.product_code' AS keyfield,'Article Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Broker Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,3

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'uom' as COL_EXPR,'a.product_code' AS keyfield,'Uom Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,4

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sub_section_name' as COL_EXPR,'a.product_code' AS keyfield,'Sub Section Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,2


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sub_section_alias' as COL_EXPR,'a.product_code' AS keyfield,'Sub Section Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,2


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'section_name' as COL_EXPR,'a.product_code' AS keyfield,'Section Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,1


	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'section_alias' as COL_EXPR,'a.product_code' AS keyfield,'Section Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_name' as COL_EXPR,'a.product_code' AS keyfield,'Para1 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_name' as COL_EXPR,'a.product_code' AS keyfield,'Para2 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3_name' as COL_EXPR,'a.product_code' AS keyfield,'Para3 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4_name' as COL_EXPR,'a.product_code' AS keyfield,'Para4 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5_name' as COL_EXPR,'a.product_code' AS keyfield,'Para5 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6_name' as COL_EXPR,'a.product_code' AS keyfield,'Para6 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para3 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para4 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para5 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para6 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_set' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Set' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.2

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_set' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Set' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.2

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_NAMES.MRP' as COL_EXPR,'a.product_code' AS keyfield,'SKU MRP' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.3	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_NAMES.MRP' as COL_EXPR,'a.product_code' AS keyfield,'Transaction MRP' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.3	

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_NAMES.PP' as COL_EXPR,'a.product_code' AS keyfield,'Pur Price' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.4	

	
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_NAMES.WS_PRICE' as COL_EXPR,'a.product_code' AS keyfield,'WSP' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.5	

	

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_NAMES.Fix_mrp' as COL_EXPR,'a.product_code' AS keyfield,'Fix MRP' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.7	

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_ER_FLAG' as COL_EXPR,'a.product_code' AS keyfield,'Er Flag' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.6	




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR1_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR1 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,11

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR2_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR2 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,12

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR3_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR3 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR4_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR4 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR5_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR5 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,14

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR6_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR6 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,15

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR7_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR7 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,16

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR8_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR8 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,17

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR9_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR9 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,18

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR10_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR10 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,19

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR11_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR11 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,20

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR12_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR12 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,21
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR13_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR13 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,22

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR14_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR14 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,23

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR15_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR15 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR16_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR16 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,25

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR17_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR17 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR18_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR18 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,26

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR19_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR19 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,27

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR20_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR20 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,28

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR21_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR21 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,29

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR22_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR22 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,30

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR23_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR23 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,31

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR24_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR24 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,32

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR25_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR25 Key name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT COL_EXPR,'a.apd_product_code' AS keyfield,col_header ,
	'Approval Return' xn_type,joining_table,joining_column,col_order
	FROM #transaction_analysis_MASTER_COLS where joining_table='sku_names'


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Stock Cancellation' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Wholesale Pack Slip Out' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Approval Issue' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Approval Return' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Opening Stock' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Retail PackSlip' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sku_names.sn_hsn_code' as COL_EXPR,'product_code' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'batch_no' as COL_EXPR,'a.product_code' AS keyfield,'Batch no.' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,35

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'expiry_dt' as COL_EXPR,'a.product_code' AS keyfield,'Expiry Date' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,36


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ac_name' as COL_EXPR,'a.product_code' AS keyfield,'Supplier name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,37




	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,
	joining_table_alias,joining_column,Col_order)     
	SELECT 'Alias' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier Alias' AS col_header ,
	'Common' as xn_type,'lm01106' as joining_table,'lm_supp' joining_table_alias,'ac_code' joining_column,39
	   	  	   

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,
	joining_table_alias,joining_column,Col_order)     
	SELECT 'address1' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier Address1' AS col_header ,
	'Common' as xn_type,'lmp01106' as joining_table,'lmp_supp' joining_table_alias,'ac_code' joining_column,38

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,
	joining_column,Col_order)     
	SELECT 'address2' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier Address2' AS col_header ,
	'Common' as xn_type,'lmp01106' as joining_table,'lmp_supp' joining_table_alias,'ac_code' joining_column,39

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,joining_column,
	addnl_join,Col_order)     
	SELECT 'area_name' as COL_EXPR,'lmpa_supp.area_code' AS keyfield,'Supplier Area' AS col_header ,
	'Common' as xn_type,'area' as joining_table,'lmp_area' as joining_table_alias,'area_code' joining_column,
	' JOIN lmp01106 lmpa_supp (NOLOCK) ON lmpa_supp.ac_code=sku_names.ac_code' addnl_join,40

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,joining_column,
	addnl_join,Col_order)     
	SELECT 'city' as COL_EXPR,'lmpc_area.city_code' AS keyfield,'Supplier City' AS col_header ,
	'Common' as xn_type,'city' as joining_table,'lmpc_city' as joining_table_alias,'city_code' joining_column,
	' JOIN lmp01106 lmpc_supp (NOLOCK) ON lmpc_supp.ac_code=sku_names.ac_code
	  JOIN area lmpc_area (NOLOCK) ON lmpc_area.area_code=lmpc_supp.area_code' addnl_join,41

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,
	joining_column,addnl_join,Col_order)     
	SELECT 'state' as COL_EXPR,'lmps_city.state_code' AS keyfield,'Supplier State' AS col_header ,
	'Common' as xn_type,'state' as joining_table,'lmps_state' as joining_table_alias,'state_code' joining_column,
	' JOIN lmp01106 lmps_supp (NOLOCK) ON lmps_supp.ac_code=sku_names.ac_code
	  JOIN area lmps_area (NOLOCK) ON lmps_area.area_code=lmps_supp.area_code
	JOIN city lmps_city(NOLOCK) ON lmps_city.city_code=lmps_area.city_code' addnl_join,41.1

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_table_alias,
	 joining_column,Col_order)     
	SELECT 'lmp_supp.ac_gst_no' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier GST no.' AS col_header ,
	'Common' as xn_type,'lmp01106' as joining_table,'lmp_supp' as joining_table_alias,'ac_code' joining_column,42

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,
	joining_table_alias,Col_order)     
	SELECT 'mobile' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier Mobile' AS col_header ,
	'Common' as xn_type,'lmp01106' as joining_table,'ac_code' joining_column,'lmp_supp' as joining_table_alias,43

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,
	joining_column,joining_table_alias,Col_order)     
	SELECT 'E_mail' as COL_EXPR,'sku_names.ac_code' AS keyfield,'Supplier Email' AS col_header ,
	'Common' as xn_type,'lmp01106' as joining_table,'ac_code' joining_column,'lmp_supp' as joining_table_alias,44

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'purchase_challan_no' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Challan No.' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,50

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'purchase_receipt_Dt' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Receipt Date' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,51

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_BILL_NO' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Bill No.' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,51.2


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_BILL_DT' as COL_EXPR,'a.product_code' AS keyfield,'GST ITC Date' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,51.3


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_BILL_DT' as COL_EXPR,'a.product_code' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,52


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.bill_dt' as COL_EXPR,'' AS keyfield,'Purchase Bill Date' AS col_header ,
	'Purchase' as xn_type,'' as joining_table,'' joining_column,52


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Purchase' xn_type,'' as joining_table,'' joining_column,34

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_gst_percentage' as COL_EXPR,'a.product_code' AS keyfield,'Purchase GST%' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Approval Issue' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Approval Return' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Stock Cancellation' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Opening Stock' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.gst_percentage' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Approval Return' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Wholesale Pack Slip Out' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Wholesale Pack Slip Out' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst%' AS col_header ,
	'Retail PackSlip' as xn_type,'' as joining_table,'' joining_column,53
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Stock Cancellation' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'OPening Stock' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Retail PackSlip' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.gst_cess_percentage' as COL_EXPR,'' AS keyfield,'Gst Cess%' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,53

	INSERT #transaction_analysis_MASTER_COLS	(xn_type,COL_EXPR,keyfield,COL_HEADER,joining_table,joining_column)     
	SELECT 'Common' xn_type,'0' as COL_EXPR,'' as keyfield,'Item Discount %' AS col_header ,'',''

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'PURCHASE_gst_amount' as COL_EXPR,'a.product_code' AS keyfield,'Purchase GST Amount' AS col_header ,
	'Common' as xn_type,'sku_names' as joining_table,'product_code' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Approval Return' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Wholesale Pack Slip Out' as xn_type,'' as joining_table,'' joining_column,54

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '0' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Opening Stock' as xn_type,'' as joining_table,'' joining_column,54
		
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	'Approval Return' xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=LEFT(b.memo_id,2) AND  sxfp.product_code=a.apd_product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	'Job Work Receive' xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=LEFT(b.receipt_id,2) AND  sxfp.product_code=a.product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	 xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=b.dept_id AND  sxfp.product_code=a.product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'
	FROM transaction_analysis_expr WHERE xn_type IN ('Purchase','Delivery Challan In(Purchase)2')

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	'Common' xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=a.dept_id AND  sxfp.product_code=a.product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=LEFT(b.irm_memo_id,2) AND  sxfp.product_code=a.new_product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'
	FROM transaction_analysis_expr WHERE xn_type IN ('Stock Creation (IRR)')

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=LEFT(b.irm_memo_id,2) AND  sxfp.product_code=a.product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'
	FROM transaction_analysis_expr WHERE xn_type IN ('Stock Consumption (IRR)')

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_column,joining_table,addnl_join,col_name)     
	SELECT 'ISNULL(lmsrcloc.ac_name,'''')' as COL_EXPR,'' AS keyfield,'Group Supplier' AS col_header ,
	xn_type,'' joining_column,'' as joining_table,
	' LEFT JOIN sku_xfp sxfp (NOLOCK) ON sxfp.dept_id=LEFT(b.memo_id,2) AND  sxfp.product_code=a.product_code '+
	' LEFT JOIN location srcloc (NOLOCK) ON srcloc.dept_id=LEFT(sxfp.group_inv_no,2) '+
	' LEFT JOIN lm01106 lmsrcloc (NOLOCK) ON lmsrcloc.ac_code=srcloc.dept_ac_code' as addnl_join,'Group_supplier'
	FROM transaction_analysis_expr WHERE xn_type IN ('Stock Creation (SNC)','Stock Consumption (SNC)')

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,col_name,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'b.discount_percentage' as COL_EXPR,'Bill_discount_pct' col_name,'' AS keyfield,'Bill Discount %' AS col_header ,
	'Common' as xn_type,'' as joining_table,'' joining_column,54
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Passport No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,60

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Ticket No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,61

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Flight No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,62

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Card No.' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,63

	--INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	--SELECT '''''' as COL_EXPR,'' AS keyfield,'Ref Party Name' AS col_header ,
	--'Common' xn_type,'' as joining_table,'' joining_column,63

	


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Image' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,63
			

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Discount Card Expiry Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,65


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Vendor Bill Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,65

	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Transaction Location GST State Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,66

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Party GST State Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,67
		   

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name,Col_order)     
	SELECT 'xn_type' as COL_EXPR,'' AS keyfield,'Transaction Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'xn_type' col_name,0  Col_order

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT a.COL_EXPR,a.keyfield,a.COL_HEADER,'Wholesale Pack Slip Return' xn_type,a.joining_table,
	a.joining_column,a.Col_order
	FROM #transaction_analysis_MASTER_COLS a
	LEFT JOIN #transaction_analysis_MASTER_COLS b ON b.xn_type='Wholesale Pack Slip Return'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='Wholesale Pack Slip Out'
	AND b.xn_type IS NULL

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT a.COL_EXPR,a.keyfield,a.COL_HEADER,'Stock UnCancellation' xn_type,a.joining_table,
	a.joining_column,a.Col_order
	FROM #transaction_analysis_MASTER_COLS a
	LEFT JOIN #transaction_analysis_MASTER_COLS b ON b.xn_type='Stock UnCancellation'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='Stock Cancellation'
	AND b.xn_type IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Stock UnCancellation' xn_type,a.col_expr,a.col_header,-1
	FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON b.xn_type='Stock UnCancellation'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='Stock Cancellation'
	AND b.xn_type IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Wholesale Pack Slip Return' xn_type,a.col_expr,a.col_header,-1
	FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON b.xn_type='Wholesale Pack Slip Return'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='Wholesale Pack Slip Out'
	AND b.xn_type IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT a.xn_type,a.COL_EXPR,a.col_header+'(MTD)' AS col_header,a.qty_multiple FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON b.col_header=a.col_header+'(MTD)' AND a.xn_type=b.xn_type
	where a.col_header IN ('Transaction Qty','Net Transaction Value') AND b.col_header IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT a.xn_type,a.COL_EXPR,a.col_header+'(YTD)' AS col_header,a.qty_multiple FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON b.col_header=a.col_header+'(YTD)' AND a.xn_type=b.xn_type
	where a.col_header IN ('Transaction Qty','Net Transaction Value') AND b.col_header IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT a.xn_type,a.COL_EXPR,'Value at SKU MRP' AS col_header FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON a.xn_type=b.xn_type AND b.col_header='Value at SKU MRP'
	WHERE a.col_header='Value at Transaction MRP' AND b.col_header IS NULL


	--Anil
	UPDATE #transaction_analysis_MASTER_COLS set COL_expr=b.table_caption from #transaction_analysis_MASTER_COLS a
	JOIN config_locattr b ON a.col_expr=b.column_name   where joining_table= 'LOC_NAMES'
	
	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when b.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	a.xn_type,'' as joining_table,'' joining_column
	FROM transaction_analysis_expr a
	LEFT JOIN #transaction_analysis_master_COLS b ON a.xn_type=b.xn_type AND b.COL_HEADER='Tax Method'
	WHERE (a.xn_type LIKE '%wholesale%' or a.xn_type like '%purchase%'  or a.xn_type='Group Sale') and a.xn_type not like '%pack%slip%'
	AND b.xn_type IS NULL


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(case when a.bill_level_tax_method =1 then  ''Exclusive'' else ''Inclusive'' end)' as COL_EXPR,'' AS keyfield,'Tax Method' AS col_header ,
	a.xn_type,'' as joining_table,'' joining_column
	FROM transaction_analysis_expr a
	LEFT JOIN #transaction_analysis_master_COLS b ON a.xn_type=b.xn_type AND b.COL_HEADER='Tax Method'
	WHERE (a.xn_type LIKE '%Debit note%' or a.xn_type like '%Credit Note%') and a.xn_type not like '%pack%slip%'
	AND b.xn_type IS NULL

	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT a.COL_EXPR,'new_product_code' keyfield,a.COL_HEADER,'Stock Creation (IRR)' xn_type,a.joining_table,
	a.joining_column,a.Col_order
	FROM #transaction_analysis_MASTER_COLS a
	LEFT JOIN #transaction_analysis_MASTER_COLS b ON b.xn_type='Stock Creation (IRR)'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='common'
	AND a.joining_table='sku_names' AND b.xn_type IS NULL

	INSERT #transaction_analysis_calculative_COLS	(xn_type,col_expr,col_header,qty_multiple)
	SELECT 'Stock Creation (IRR)' xn_type,a.col_expr,a.col_header,-1
	FROM #transaction_analysis_calculative_COLS a
	LEFT JOIN #transaction_analysis_calculative_COLS b ON b.xn_type='Stock Creation (IRR)'
	AND a.COL_HEADER=b.COL_HEADER WHERE a.xn_type='Common'
	AND a.col_expr LIKE '%sku_names%' AND b.xn_type IS NULL


	INSERT #transaction_analysis_MASTER_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT DISTINCT '''''' as COL_EXPR,'' AS keyfield,a.col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column FROM  
	#transaction_analysis_MASTER_COLS a 
	LEFT JOIN #transaction_analysis_MASTER_COLS b ON a.COL_HEADER=b.COL_HEADER AND b.xn_type='Common'
	WHERE a.xn_type<>'Common' AND b.COL_HEADER  IS NULL


	--- Start of Batch Command for correcting some specific Expressions
	update #transaction_analysis_MASTER_COLS set joining_table_alias='loc_cn'
	WHERE xn_type IN ('Delivery Challan In(Credit Note)','Delivery Challan In(Credit Note)2') and joining_table='LOCATION' AND keyfield='LEFT(b.cn_id,2)'

	update #transaction_analysis_MASTER_COLS set joining_table_alias='loc_dn'
	WHERE xn_type IN ('Delivery Challan In(Credit Note)','Delivery Challan In(Credit Note)2') 
	and joining_table='LOCATION' AND keyfield='LEFT(b.rm_id,2)' AND col_header NOT IN ('Party registration status')

	--- End of Batch Command for correcting some specific Expressions

	update #transaction_analysis_MASTER_COLS set col_expr='ISNULL(CUSTDYM.CUS_GST_NO,'''')'
	WHERE COL_EXPR='CUS_GST_NO'


	
	--select * from transaction_analysis_MASTER_COLS where COL_EXPR='xn_type'
	UPDATE #transaction_analysis_MASTER_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''
	UPDATE #transaction_analysis_calculative_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''

	UPDATE #transaction_analysis_MASTER_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_analysis_calculative_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE transaction_analysis_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	
	UPDATE a SET datecol=1 from #transaction_analysis_MASTER_COLS a 
	left join config_locattr b on a.col_expr=b.table_caption
	left join config_locattr c on a.col_expr='loc'+c.column_name
	WHERE (right(col_name,4)='DATE' OR RIGHT(COL_HEADER,4)='DATE') and b.table_caption IS NULL
	
	UPDATE #transaction_analysis_MASTER_COLS SET joining_table_alias='lv' where joining_table='#loc_view'

	INSERT INTO xpert_report_filtercols (filtercol_name,BASE_TABLE_NAME)
	SELECT 'article_no','article'
	UNION ALL
	SELECT 'section_name','sectionm'
	UNION ALL
	SELECT 'sub_section_name','sectiond'
	UNION ALL
	SELECT 'para1_name','para1'
	UNION ALL
	SELECT 'para2_name','para2'
	UNION ALL
	SELECT 'para3_name','para3'
	UNION ALL
	SELECT 'para4_name','para4'
	UNION ALL
	SELECT 'para5_name','para5'
	UNION ALL
	SELECT 'para6_name','para6'
	UNION ALL
	SELECT 'ATTR1_KEY_NAME','attr1_mst'
	UNION ALL
	SELECT 'ATTR2_KEY_NAME','attr2_mst'
	UNION ALL
	SELECT 'ATTR3_KEY_NAME','attr3_mst'
	UNION ALL
	SELECT 'ATTR4_KEY_NAME','attr4_mst'
	UNION ALL
	SELECT 'ATTR5_KEY_NAME','attr5_mst'
	UNION ALL
	SELECT 'ATTR6_KEY_NAME','attr6_mst'
	UNION ALL
	SELECT 'ATTR7_KEY_NAME','attr7_mst'
	UNION ALL
	SELECT 'ATTR8_KEY_NAME','attr8_mst'
	UNION ALL
	SELECT 'ATTR9_KEY_NAME','attr9_mst'
	UNION ALL
	SELECT 'ATTR10_KEY_NAME','attr10_mst'
	UNION ALL
	SELECT 'ATTR11_KEY_NAME','attr11_mst'
	UNION ALL
	SELECT 'ATTR12_KEY_NAME','attr12_mst'
	UNION ALL
	SELECT 'ATTR13_KEY_NAME','attr13_mst'
	UNION ALL
	SELECT 'ATTR14_KEY_NAME','attr14_mst'
	UNION ALL
	SELECT 'ATTR15_KEY_NAME','attr15_mst'
	UNION ALL
	SELECT 'ATTR16_KEY_NAME','attr16_mst'
	UNION ALL
	SELECT 'ATTR17_KEY_NAME','attr17_mst'
	UNION ALL
	SELECT 'ATTR18_KEY_NAME','attr18_mst'
	UNION ALL
	SELECT 'ATTR19_KEY_NAME','attr19_mst'
	UNION ALL
	SELECT 'ATTR20_KEY_NAME','attr20_mst'
	UNION ALL
	SELECT 'ATTR21_KEY_NAME','attr21_mst'
	UNION ALL
	SELECT 'ATTR22_KEY_NAME','attr22_mst'
	UNION ALL
	SELECT 'ATTR23_KEY_NAME','attr23_mst'
	UNION ALL
	SELECT 'ATTR24_KEY_NAME','attr24_mst'
	UNION ALL
	SELECT 'ATTR25_KEY_NAME','attr25_mst'
	UNION ALL
	SELECT 'dept_id','location'
	UNION ALL
	SELECT 'area_name','area'
	UNION ALL
	SELECT 'city','city'
	UNION ALL
	SELECT 'State','state'
	UNION ALL
	SELECT 'uom','uom'
	UNION ALL
	SELECT 'LOCATTR1_KEY_NAME','locattr1_mst'
	UNION ALL
	SELECT 'LOCATTR2_KEY_NAME','locattr2_mst'
	UNION ALL
	SELECT 'LOCATTR3_KEY_NAME','locattr3_mst'
	UNION ALL
	SELECT 'LOCATTR4_KEY_NAME','locattr4_mst'
	UNION ALL
	SELECT 'LOCATTR5_KEY_NAME','locattr5_mst'
	UNION ALL
	SELECT 'LOCATTR6_KEY_NAME','locattr6_mst'
	UNION ALL
	SELECT 'LOCATTR7_KEY_NAME','locattr7_mst'
	UNION ALL
	SELECT 'LOCATTR8_KEY_NAME','locattr8_mst'
	UNION ALL
	SELECT 'LOCATTR9_KEY_NAME','locattr9_mst'
	UNION ALL
	SELECT 'LOCATTR10_KEY_NAME','locattr10_mst'
	UNION ALL
	SELECT 'LOCATTR11_KEY_NAME','locattr11_mst'
	UNION ALL
	SELECT 'LOCATTR12_KEY_NAME','locattr12_mst'
	UNION ALL
	SELECT 'LOCATTR13_KEY_NAME','locattr13_mst'
	UNION ALL
	SELECT 'LOCATTR14_KEY_NAME','locattr14_mst'
	UNION ALL
	SELECT 'LOCATTR15_KEY_NAME','locattr15_mst'
	UNION ALL
	SELECT 'LOCATTR16_KEY_NAME','locattr16_mst'
	UNION ALL
	SELECT 'LOCATTR17_KEY_NAME','locattr17_mst'
	UNION ALL
	SELECT 'LOCATTR18_KEY_NAME','locattr18_mst'
	UNION ALL
	SELECT 'LOCATTR19_KEY_NAME','locattr19_mst'
	UNION ALL
	SELECT 'LOCATTR20_KEY_NAME','locattr20_mst'
	UNION ALL
	SELECT 'LOCATTR21_KEY_NAME','locattr21_mst'
	UNION ALL
	SELECT 'LOCATTR22_KEY_NAME','locattr22_mst'
	UNION ALL
	SELECT 'LOCATTR23_KEY_NAME','locattr23_mst'
	UNION ALL
	SELECT 'LOCATTR24_KEY_NAME','locattr24_mst'
	UNION ALL
	SELECT 'LOCATTR25_KEY_NAME','locattr25_mst'
	   	 

	INSERT INTO xpert_report_filtercols (filtercol_name,data_type)
	SELECT 'Acknowledgement_No','String'
	UNION ALL
	SELECT 'Date_of_Anniversary','Date'
	UNION ALL
	SELECT 'Date_of_Birth','Date'
	UNION ALL
	SELECT 'Discount_Card_Expiry_Date','Date'
	UNION ALL
	SELECT 'Discount_Card_No','String'
	UNION ALL
	SELECT 'Flight_No','String'
	UNION ALL
	SELECT 'IRN_Date','Date'
	UNION ALL
	SELECT 'IRN_No','String'
	UNION ALL
	SELECT 'Item_Code','String'
	UNION ALL
	SELECT 'Item_Code_without_Batch','String'
	UNION ALL
	SELECT 'Party_Address1','String'
	UNION ALL
	SELECT 'Party_Address2','String'
	UNION ALL
	SELECT 'Party_Alias','String'
	UNION ALL
	SELECT 'Party_Email','String'
	UNION ALL
	SELECT 'Party_GST_no','String'
	UNION ALL
	SELECT 'Party_Mobile','String'
	UNION ALL
	SELECT 'Party_Name','String'
	UNION ALL
	SELECT 'Party_Pan_no','String'
	UNION ALL
	SELECT 'Passport_No','String'
	UNION ALL
	SELECT 'Sales_person_1','String'
	UNION ALL
	SELECT 'Sales_person_2','String'
	UNION ALL
	SELECT 'Sales_person_3','String'
	UNION ALL
	SELECT 'Target_Location_Bin','String'
	UNION ALL
	SELECT 'Target_Location_Receipt_Date','Date'
	UNION ALL
	SELECT 'Ticket_No','String'
	UNION ALL
	SELECT 'Transaction_Date','Date'
	UNION ALL
	SELECT 'Transaction_Day','Numeric'
	UNION ALL
	SELECT 'Transaction_Financial_Year','String'
	UNION ALL
	SELECT 'Transaction_Location_id','String'
	UNION ALL
	SELECT 'Transaction_Location_name','String'
	UNION ALL
	SELECT 'Transaction_Location_Alias','String'
	UNION ALL
	SELECT 'Transaction_Location_Area','String'
	UNION ALL
	SELECT 'Transaction_Location_Bin','String'
	UNION ALL
	SELECT 'Transaction_Location_City','String'
	UNION ALL
	SELECT 'Transaction_Location_State','String'
	UNION ALL
	SELECT 'Transaction_Month_Name','String'
	UNION ALL
	SELECT 'Transaction_Month_No','Numeric'
	UNION ALL
	SELECT 'Transaction_No','String'
	UNION ALL
	SELECT 'Transaction_Week_No','Numeric'
	UNION ALL
	SELECT 'Transaction_Year','Numeric'
	UNION ALL
	SELECT 'Expiry_Date','Date'
	UNION ALL
	SELECT 'Purchase_GST_Amount','Numeric'
	UNION ALL
	SELECT 'Purchase_Bill_Date','Date'	
	UNION ALL
	SELECT 'Purchase_Receipt_Date','Date'
	UNION ALL
	SELECT 'Item_Discount_pct','Numeric'
	UNION ALL
	SELECT 'Bill_discount_pct','Numeric'
	UNION ALL
	SELECT 'ONLINE_BILL_REF_NO','String'
	UNION ALL
	SELECT 'ORDER_NO','String'
	UNION ALL
	SELECT 'HSNSAC_CODE','String'
	UNION ALL
	SELECT 'Purchase_Challan_No','String'	
	UNION ALL
	SELECT 'Purchase_Bill_No','String'
	UNION ALL
	SELECT 'broker.ac_name','String'
	UNION ALL
	SELECT 'Edit_User_Name','String'
	UNION ALL
	SELECT 'User_Name','String'
	UNION ALL
	SELECT 'COPIES_PRINTED','Numeric'
	UNION ALL
	SELECT 'Modified','Numeric'
	UNION ALL
	SELECT 'SKU_NAMES.MRP','Numeric'
	UNION ALL
	SELECT 'BILTY_DATE','Date'
	UNION ALL
	SELECT 'MRP','Numeric'
	UNION ALL
	SELECT 'FIX_MRP','Numeric'
	UNION ALL
   SELECT 'SKU_NAMES.FIX_MRP','Numeric'
	


	INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header, col_name, group_xn_type, rep_type,qty_multiple )
	SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'DETAIL' rep_type ,qty_multiple
	FROM #transaction_analysis_calculative_COLS 



	INSERT transaction_analysis_MASTER_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
	col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
	SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
	group_xn_type, datecol, Col_order, joining_table_alias,'DETAIL' rep_type 
	FROM #transaction_analysis_master_COLS



	PRINT 'Recreating Summary Columns expressions'
	EXEC SP3S_BUILD_XPERT_TRANSUMMARY_EXPRESSIONS

	PRINT 'Recreating Pendency Columns expressions'
	EXEC SP3S_BUILD_XPERTPENDENCY_EXPRESSIONS

	PRINT 'Recreating Customer Analysis Columns expressions'
	EXEC SP3S_BUILD_XPERTCUSTOMER_EXPRESSIONS

	PRINT 'Recreating Stock Analysis Columns expressions'
	
	EXEC SP3S_BUILD_XPERTREPORTING_STKANALYSIS_EXPRESSIONS

	PRINT 'Shiping Address '

	INSERT transaction_analysis_MASTER_COLS	( addnl_join, col_expr, COL_HEADER, col_name, 
	Col_order, datecol, group_xn_type, joining_column, joining_table, joining_table_alias, keyfield, rep_type, xn_type ) 
	SELECT 	  addnl_join, col_expr, COL_HEADER, col_name, Col_order, datecol, group_xn_type, joining_column, joining_table, 
	joining_table_alias, keyfield, 'DETAIL', xn_type 
	FROM transaction_analysis_MASTER_COLS
	where COL_HEADER like 'Ship%' and  rep_type = 'SMRY'

	PRINT 'Location Inactive '

	 Delete From   transaction_analysis_MASTER_COLS  where col_name like '%Transaction_Location_inactive%'

	 INSERT transaction_analysis_MASTER_COLS	( addnl_join, col_expr, COL_HEADER, col_name, 
	 Col_order, datecol, group_xn_type, joining_column, joining_table, joining_table_alias, keyfield, rep_type, xn_type ) 
	 SELECT 	  addnl_join, case  when group_xn_type= 'Common' then ''''''  else  'Inactive' end  as col_expr,
	 'Transaction Location Inactive' as COL_HEADER, 'Transaction_Location_Inactive' as col_name, Col_order, datecol, group_xn_type, joining_column, 
	 joining_table, joining_table_alias, keyfield, rep_type, xn_type
	 FROM transaction_analysis_MASTER_COLS  where col_name like '%Transaction_Location_name%'




	PRINT 'MTD YTD'
	Delete From  transaction_analysis_calculative_COLS where  rep_type= 'STOCK' and col_name like 'MTD_%'
	Delete From  transaction_analysis_calculative_COLS where  rep_type= 'STOCK' and col_name like 'YTD_%'
	--QTY

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'NPQ','NSQ','ARQ','CNQ','CPQ','CRQ','APQ','PPQ','SPQ',
	'WPQ','FCI','FCO','JWIOQ','JWROQ','NAQ','NQC','NCQ','NJWOQ','NWQ','PRQ','SRQ','UNQ','WRQ')
	   
	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'NPQ','NSQ','ARQ','CNQ','CPQ','CRQ','APQ','PPQ','SPQ',
	'WPQ','FCI','FCO','JWIOQ','JWROQ','NAQ','NQC','NCQ','NJWOQ','NWQ','PRQ','SRQ','UNQ','WRQ')
	
	--LC
	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CNLC','CPLC','CRLC','PPLC','SPLC','WPLC',
	'NQLC','NCLC','NPLC','NSLC','NWLC','PRLC','SRLC','UNLC','WRLC')

	
	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CNLC','CPLC','CRLC','PPLC','SPLC','WPLC',
	'NQLC','NCLC','NPLC','NSLC','NWLC','PRLC','SRLC','UNLC','WRLC')

	--PP

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CNP1','CPP1','CRP1','PPP1','SPP1','WPP1','NQP1','NCP1','NPP1',
	'NSP1','NWP1','PRP1','SRP1','UNP1','WRP1')

	
	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CNP1','CPP1','CRP1','PPP1','SPP1','WPP1','NQP1','NCP1','NPP1',
	'NSP1','NWP1','PRP1','SRP1','UNP1','WRP1')
	
	--RSp

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'ARM','CNCVM','CPM','CRM','APPVM','PPM','SPG','WPM','JWIOM','JWROM','NAPMRP','NQM',
	'NCM','NJWOM','NPM','NSG','NWM','PRM','SRG','UNM','WRM','WRNW','NSM','NVWOGST')
	

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'ARM','CNCVM','CPM','CRM','APPVM','PPM','SPG','WPM','JWIOM','JWROM','NAPMRP','NQM',
	'NCM','NJWOM','NPM','NSG','NWM','PRM','SRG','UNM','WRM','WRNW','NSM','NVWOGST')
	
	--WSp

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'SRWP','PPW','PRW','NPW','CHIWSP','CRW','NCHRW','SPWP','NSWP','NAPWSP',
	'WPNW','NWNW')

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'SRWP','PPW','PRW','NPW','CHIWSP','CRW','NCHRW','SPWP','NSWP','NAPWSP',
	'WPNW','NWNW')

	--XFER

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CPXP','CRXP','SPXP','WSLRXP','NCXP','NSXFP','NWXFP','SRXP','WSRRXP')

	
	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CPXP','CRXP','SPXP','WSLRXP','NCXP','NSXFP','NWXFP','SRXP','WSRRXP')

	--CXFER

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'MTD '+ col_header, 
	'MTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CPXPWGST','CRXPWGST','SLRXPWGST','SPXPWGST',
	'WSLCRXPWGSTC','NCXPWGST','NWCXPWGST','WSRCRXPWGST')
	

	INSERT transaction_analysis_calculative_COLS
	( col_expr, col_header, col_name, group_xn_type, multi_column_based, qty_multiple, rep_type,
	xn_type ) 
	SELECT  col_expr,'YTD '+ col_header, 
	'YTD_'+LEFT(col_name,1) + 'XX'+ Substring(col_name,2,100) as col_name, group_xn_type, multi_column_based,
	qty_multiple, rep_type, xn_type
	FROM transaction_analysis_calculative_COLS
	where  rep_type= 'STOCK'  and COL_NAME in
	( 'CPXPWGST','CRXPWGST','SLRXPWGST','SPXPWGST',
	'WSLCRXPWGSTC','NCXPWGST','NWCXPWGST','WSRCRXPWGST')

	   	  	
	INSERT INTO xpert_report_filtercols (filtercol_name,data_type)
	select distinct col_name,'string' from transaction_analysis_MASTER_COLS where
	col_name not in(select filtercol_name from xpert_report_filtercols)
	and col_expr not in(select filtercol_name from xpert_report_filtercols)
	AND col_name<>'xn_type' AND NOT (col_name LIKE '%mrp%' OR col_expr LIKE '%mrp%')

	UPDATE xpert_report_filtercols
	SET data_type='String' where isnull(data_type,'')=''

	update  xpert_report_filtercols  set  data_type= 'Date'  where  filtercol_name like '%GST_ITC_Date%'


	UPDATE transaction_analysis_MASTER_COLS set col_expr='lmp01106.mobile' WHERE col_name='party_mobile'
	and col_expr='mobile' and joining_table='lmp01106'
	
	DELETE FROM xpert_xntypes

	insert into xpert_xntypes (xn_type,inactive)
	SELECT xn_type,0 inactive FROM transaction_analysis_expr
END