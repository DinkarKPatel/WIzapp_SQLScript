CREATE PROCEDURE SP3S_PMTBUILD_expressions
AS
BEGIN
	
	DECLARE @CCurLocId CHAR(5),@cHoLocId CHAR(5),@bHoLoc BIT

	SELECT @CCurLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	
	SELECT @cHoLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		

	IF @CCurLocId=@cHoLocId or db_name()='master'
		SET @bHoLoc=1
	ELSE
		SET @bHoLoc=0
		
		
	DELETE FROM pmt_build_exp


	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)
	 SELECT 'ops' as xn_type,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	   SUM(a.quantity_OB) AS OBS
	 FROM [DATABASE].dbo.OPS01106 A WITH (NOLOCK) [JOIN]
	 WHERE CONVERT(DATE,A.xn_dt) BETWEEN [DFROMDT] AND [DTODT] AND [WHERE]  
	 group by [GROUPBY]' AS base_expr --- 4secs


	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'DCO' as xn_type,'B.location_code' as loc_join_col,'a.source_bin_id' as bin_join_col,
		'[LAYOUT_COL],    
	   SUM(A.QUANTITY)*-1 AS OBS
	 from [DATABASE].dbo.FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID [JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED = 0  AND [WHERE]
	' AS base_expr    --- 3ecs

	
	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	  SELECT 'DCI' as xn_type,'B.location_code' as loc_join_col,'a.item_target_bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs
	 from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 [JOIN] 
	 WHERE CONVERT(DATE,b.receipt_dt) BETWEEN [DFROMDT] AND [DTODT] AND b.receipt_Dt<>''''  AND B.CANCELLED = 0 AND [WHERE]
	' AS base_expr --- 2secs

		INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	SELECT 'PUR' as xn_type,'b.dept_id' as loc_join_col,'b.bin_id' as bin_join_col,
	'[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
	 [JOIN]
	 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode IN (0,1) AND  B.CANCELLED = 0 AND b.receipt_Dt<>'''' AND c.mrr_id IS NULL
	 AND a.product_code<>'''' AND [WHERE] 
	 ' AS base_expr
	

	IF @bHoLoc=1
		 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
		SELECT 'CHI_PUR' as xn_type,'b.dept_id' as loc_join_col,'b.bin_id' as bin_join_col,
		'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs
		 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID
		 [JOIN]
		 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND  B.CANCELLED = 0
		 AND c.cancelled=0 AND b.receipt_Dt<>'''' 
		 AND [WHERE] 
		 ' AS base_expr
	ELSE
		 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
		SELECT 'CHI_PUR' as xn_type,'b.dept_id' as loc_join_col,'b.bin_id' as bin_join_col,
		'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		 [JOIN]
		 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND  B.CANCELLED = 0
		 AND b.receipt_Dt<>'''' 
		  AND [WHERE] 
		 ' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)
	 SELECT 'GRNPSIN' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	sum(A.QUANTITY) AS Obs
	 from [DATABASE].dbo.GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND [WHERE]
	 ' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)--(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'GRNPSOUT' as xn_type,'b.dept_id' as loc_join_col,'b.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	[JOIN]
	 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND b.receipt_Dt<>''''
	 AND ISNULL(B.PIM_MODE,0)=6
	   AND [WHERE]
	 ' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'PRT' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	   SUM(quantity)*-1 as Obs
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.RM_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND mode=1 AND [WHERE]  
	 ' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'CHO_PRT' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	   SUM(quantity)*-1 as Obs
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 JOIN [DATABASE].dbo.location loc (NOLOCK) ON loc.dept_id=B.location_code
	[JOIN]
	 WHERE CONVERT(DATE,b.RM_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND mode=2  AND  [WHERE]  
	 ' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLS' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs
	 from [DATABASE].dbo.rps_det A (NOLOCK)    
	 JOIN  [DATABASE].dbo.rps_mst B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.LOCATION C WITH(NOLOCK) ON C.DEPT_ID=B.location_code
	[JOIN]
	 WHERE CONVERT(DATE,b.CM_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND  isnull( b.ref_cm_id  ,'''') =''''
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLS' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.LOCATION C WITH(NOLOCK) ON C.DEPT_ID=B.location_code  
	[JOIN]
	 WHERE CONVERT(DATE,b.CM_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
   AND ((A.QUANTITY<0 AND (ISNULL(C.SLR_RECON_REQD,0)<>1 OR B.CM_DT<ISNULL(C.SLR_RECON_CUTOFF_DATE,'''')))
	 OR A.QUANTITY>0)
	  AND [WHERE]    
	' AS base_expr

    INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr,product_code_col)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLS' as xn_type,'C.location_code' as loc_join_col,'b.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	  SUM(abs(A.QUANTITY)) as  Obs
	 from [DATABASE].dbo.SLR_RECON_DET A (NOLOCK)    
	 JOIN [DATABASE].dbo.CMD01106 b (NOLOCK) ON A.CMD_ROW_ID=b.ROW_ID
	 JOIN  [DATABASE].dbo.CMM01106 c (NOLOCK) ON c.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.LOCATION D (NOLOCK) ON D.DEPT_ID=C.location_code
	 JOIN [DATABASE].dbo.slr_recon_mst e (NOLOCK) ON e.memo_id=a.memo_id

	[JOIN]
	 WHERE CONVERT(DATE,e.memo_DT) BETWEEN [DFROMDT] AND [DTODT]  AND c.cancelled=0   AND e.cancelled=0   
    AND ISNULL(D.SLR_RECON_REQD,0)=1 AND C.CANCELLED = 0  AND C.CM_DT>=ISNULL(D.SLR_RECON_CUTOFF_DATE,'''') 

	  AND [WHERE]    
	' AS base_expr,'b.product_code'

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLS_CONS' as xn_type,'B.location_code' as loc_join_col,'''000''' as bin_join_col,
	 '[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs
	 from [DATABASE].dbo.cmd_cons A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.CM_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'APP' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr,product_code_col)    
	 SELECT 'APR' as xn_type,'B.location_code' as loc_join_col,'b.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	   SUM(b.QUANTITY) AS  Obs
	 from [DATABASE].dbo.APPROVAL_RETURN_DET B WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = B.MEMO_ID    
	 [JOIN]
	 WHERE CONVERT(DATE,c.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND c.cancelled=0 AND [WHERE]    
	' AS base_expr,'APD_product_code' as product_code_col

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	  SELECT 'CNC' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	   SUM(CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END) AS  Obs
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.CNC_MEMO_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	' as base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr) --(-1) avilable inside 
	SELECT 'WSL' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs
  
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.INV_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode IN (0,1) AND b.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 
	   AND [WHERE]
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr) --(-1) avilable inside 
	SELECT 'CHO_WSL' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs
  
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.INV_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND b.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 
	   AND [WHERE]
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	SELECT 'WPI' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs
	from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.ps_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr


	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	SELECT 'WPR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	'[LAYOUT_COL],
	SUM (a.quantity) as  Obs
	 from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID  
	JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id AND a.ps_id=c.ps_id
	[JOIN]
	 WHERE CONVERT(DATE,b.INV_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 AND [WHERE]	 
	group by [GROUPBY]' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'WSR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	SUM(quantity) AS  Obs
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE (MODE<>2 AND CONVERT(DATE,b.cn_dt) BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'CHI_WSR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL],    
	SUM(quantity) AS  Obs
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE 	(MODE=2 AND CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT] and b.receipt_Dt<>'''') 
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr,product_code_col)     
	SELECT 'SCF_IRR' as xn_type,'B.location_code' as loc_join_col,'b.bin_id' as bin_join_col,
	'[LAYOUT_COL], SUM(A.QUANTITY) AS  Obs
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	[JOIN]
	 WHERE CONVERT(DATE,b.IRM_MEMO_DT) BETWEEN [DFROMDT] AND [DTODT]
	 and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE]
	' AS base_expr,'new_product_code' as product_code_col

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)     
	  SELECT 'SCF' as xn_type,'B.location_code' as loc_join_col,'''000''' as bin_join_col,
	  '[LAYOUT_COL],   SUM(A.QUANTITY) AS  Obs
	 
	 from [DATABASE].dbo.SCF01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)   --(-1) avilable inside   
	  SELECT 'SCC_IRR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],
	  SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID 
	[JOIN]
	 WHERE CONVERT(DATE,b.IRM_MEMO_DT) BETWEEN [DFROMDT] AND [DTODT] and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND  [WHERE] 
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)     
	  SELECT 'SCC' as xn_type,'B.location_code' as loc_join_col,'''000''' as bin_join_col,
	  '[LAYOUT_COL],
	  SUM(A.QUANTITY+ADJ_QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.SCC01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr


	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr) --(-1) avilable inside     
	  SELECT 'JWI' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],
		  SUM(ABS(A.QUANTITY)) *-1 AS  Obs
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.ISSUE_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)     
	  SELECT 'JWR' as xn_type,'B.location_code' as loc_join_col,'d.bin_id' as bin_join_col,
	  '[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  Obs
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 [JOIN]
	 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'SCF_SNC' as xn_type,'B.location_code' as loc_join_col,'b2.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	 SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END) AS  Obs
	 from [DATABASE].dbo.SNC_DET B2 (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON B2.MEMO_ID = B.MEMO_ID    
	 JOIN  
	 (  
	 SELECT REFROW_ID AS [ROW_ID],PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]  
	 from [DATABASE].dbo.SNC_BARCODE_DET (NOLOCK)  
	 GROUP BY REFROW_ID,PRODUCT_CODE  
	 )A ON B2.ROW_ID = A.ROW_ID  
	 JOIN  [DATABASE].dbo.SKU S1(NOLOCK) ON S1.product_code=a.PRODUCT_CODE 
	 [JOIN]
	 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND B.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 ' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)      --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)    
	  SELECT 'SCC_SNC' as xn_type,'B.location_code' as loc_join_col,'isnull(a.bin_id,''000'')' as bin_join_col,
	  '[LAYOUT_COL], 
	  SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.SNC_CONSUMABLE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]   
	' AS base_expr

	 INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)  
	 SELECT 'TTM' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL], 
	 SUM(A.QUANTITY) AS  Obs	   
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	  SELECT 'CNPI' as xn_type,'left(b.ps_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	sum(A.QUANTITY) AS  Obs
	 
	 from [DATABASE].dbo.CNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.PS_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	   SELECT 'CNPR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	   '[LAYOUT_COL], 
		SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.Cnps_det A (NOLOCK)    
	 JOIN  [DATABASE].dbo.Cnps_mst B (NOLOCK) ON A.ps_ID = B.ps_ID 
	 JOIN  [DATABASE].dbo.cnm01106 C ON b.wsr_cn_id=c.cn_id
	[JOIN]
	 WHERE CONVERT(DATE,c.cn_DT) BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	  SELECT 'DNPI' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS  Obs
	 
	 from [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.PS_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)    
	   SELECT 'DNPR' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	   '[LAYOUT_COL], 
		SUM(A.QUANTITY) AS  Obs
	 from [DATABASE].dbo.dnps_det A (NOLOCK)    
	 JOIN  [DATABASE].dbo.dnps_mst B (NOLOCK) ON A.ps_ID = B.ps_ID 
	 JOIN  [DATABASE].dbo.rmm01106 C ON b.prt_rm_id=c.rm_id
	[JOIN]
	 WHERE CONVERT(DATE,c.RM_DT) BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 
	  AND [WHERE]    
	' AS base_expr

	INSERT pmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)
	   SELECT 'MIS' as xn_type,'B.location_code' as loc_join_col,'a.bin_id' as bin_join_col,
	   '[LAYOUT_COL],    
	SUM(CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end) as  Obs
	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	[JOIN]
	  WHERE CONVERT(DATE,b.ISSUE_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]     
	' AS base_expr
END
--***************** END OF CREATING PROCEDURE SP3S_Reporting_expressions