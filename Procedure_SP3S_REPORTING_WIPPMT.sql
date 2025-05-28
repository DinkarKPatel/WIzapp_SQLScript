
create PROCEDURE SP3S_REPORTING_WIPPMT
AS
BEGIN
	
	
	
	DECLARE @CCurLocId CHAR(2),@cHoLocId CHAR(2),@bHoLoc BIT

	SELECT @CCurLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	
	SELECT @cHoLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		

	IF @CCurLocId=@cHoLocId
		SET @bHoLoc=1
	ELSE
		SET @bHoLoc=0

		truncate table XTREME_WIPPMT_EXP


	INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.source_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( 1) AS OBS
	 from [DATABASE].dbo.ORD_PLAN_BARCODE_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.ORD_PLAN_DET B WITH (NOLOCK) ON A.REFROW_ID  = B.ROW_ID
	  JOIN  [DATABASE].dbo.ORD_PLAN_MST C WITH (NOLOCK) ON B.MEMO_ID  = C.MEMO_ID
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 [JOIN]
	 WHERE C.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND C.CANCELLED = 0  AND [WHERE]
	' AS base_expr    --- 3ecs

	INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(1) AS OBS
	 from [DATABASE].dbo.ORD_PLAN_BARCODE_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.ORD_PLAN_DET B WITH (NOLOCK) ON A.REFROW_ID  = B.ROW_ID
	  JOIN  [DATABASE].dbo.ORD_PLAN_MST C WITH (NOLOCK) ON B.MEMO_ID  = C.MEMO_ID
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 [JOIN]
	 WHERE c.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND C.CANCELLED = 0  AND [WHERE]
	group by [GROUPBY]' AS base_expr    --- 3ecs




	 INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.issue_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.issue_dt' as xn_dt_col,'[LAYOUT_COL],    
	  sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_mst B WITH(NOLOCK) ON A.issue_id  = B.issue_id
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	 WHERE b.issue_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 and isnull(b.issue_mode,0) =1 AND [WHERE]
	 ' AS base_expr

	 INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.issue_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.issue_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_mst B WITH(NOLOCK) ON A.issue_id  = B.issue_id
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	 WHERE b.issue_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  and isnull(b.issue_mode,0)=1  AND [WHERE]
	 group by [GROUPBY]' AS base_expr



	
	

	 INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.RECEIPT_ID,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.RECEIPT_no' as xn_no_col,'b.RECEIPT_dt' as xn_dt_col,'[LAYOUT_COL],    
	  sum(A.QUANTITY) AS Obs
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B WITH(NOLOCK) ON A.RECEIPT_ID  = B.RECEIPT_ID
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.RECEIPT_ID,2)
	[JOIN]
	 WHERE b.RECEIPT_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 and isnull(b.Receive_Mode,0) =1 AND [WHERE]
	 ' AS base_expr

	 INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.RECEIPT_ID,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.RECEIPT_NO' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY) AS Obs
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B WITH(NOLOCK) ON A.RECEIPT_ID  = B.RECEIPT_ID
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.RECEIPT_ID,2)
	[JOIN]
	 WHERE b.RECEIPT_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  and isnull(b.Receive_Mode,0)=1  AND [WHERE]
	 group by [GROUPBY]' AS base_expr


	  INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.memo_id,2)' as loc_join_col,'A.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	  sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B WITH(NOLOCK) ON A.memo_id  = B.memo_id
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  
	 AND b.cancelled=0 and  [WHERE]
	 ' AS base_expr

	 INSERT XTREME_WIPPMT_EXP (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.memo_id,2)' as loc_join_col,'A.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_mst B WITH(NOLOCK) ON A.memo_id  = B.memo_id
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0   AND [WHERE]
	 group by [GROUPBY]' AS base_expr


	
END
--***************** END OF CREATING PROCEDURE SP3S_Reporting_expressions


