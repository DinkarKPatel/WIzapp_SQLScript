
CREATE PROCEDURE SP3S_WIPPMT_BUILD_expressions
AS
BEGIN
	
	DECLARE @CCurLocId CHAR(2),@cHoLocId CHAR(2),@bHoLoc BIT

	SELECT @CCurLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	
	SELECT @cHoLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		

	IF @CCurLocId=@cHoLocId
		SET @bHoLoc=1
	ELSE
		SET @bHoLoc=0
		
		
		
	DELETE FROM WIPPMT_BUILD_EXP


	 INSERT wippmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr) --(-1) avilable inside     
	  SELECT 'JWI' as xn_type,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '[LAYOUT_COL],SUM(A.QUANTITY) *-1 AS  Obs,0 AS FG_value,sum(a.JWI_BOM_VALUE ) as BOM_VALUE
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	[JOIN]
	 WHERE CONVERT(DATE,b.ISSUE_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	 AND ISNULL(B.ISSUE_MODE,0)=1 AND [WHERE]  
	' AS base_expr

	INSERT wippmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)     
	  SELECT 'JWR' as xn_type,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  '[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  Obs,SUM(D.JOB_RATE ) AS FG_value,0 as BOM_VALUE
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 [JOIN]
	 WHERE CONVERT(DATE,b.RECEIPT_DT) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND  ISNULL(B.RECEIVE_MODE,0)=1 AND [WHERE] 
	' AS base_expr

	 INSERT wippmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'JCC' as xn_type,'left(b.memo_id,2)' as loc_join_col,'b2.bin_id' as bin_join_col,
	  '[LAYOUT_COL],    
	 SUM(a.TOTAL_QTY ) AS  Obs,0 AS FG_value,0 as BOM_VALUE
	 from [DATABASE].dbo.Ord_plan_det B2 (NOLOCK)    
	 JOIN  [DATABASE].dbo.Ord_plan_mst B (NOLOCK) ON B2.MEMO_ID = B.MEMO_ID    
	 JOIN  
	 (  
	 SELECT REFROW_ID AS [ROW_ID],PRODUCT_CODE,1 AS [TOTAL_QTY]  
	 from [DATABASE].dbo.ord_plan_barcode_det (NOLOCK)  
	 )A ON B2.ROW_ID = A.ROW_ID  
	 [JOIN]
	 WHERE CONVERT(DATE,b.MEMO_DT) BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 ' AS base_expr

	
	 INSERT wippmt_build_exp (xn_type,loc_join_col,bin_join_col,base_expr)  
	 SELECT 'TTM' as xn_type,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '[LAYOUT_COL], 
	 SUM(A.QUANTITY)*-1 AS  Obs,0 AS FG_value,0 as BOM_VALUE	   
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	[JOIN]
	 WHERE CONVERT(DATE,b.memo_dt) BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr

END
--***************** END OF CREATING PROCEDURE SP3S_WIPPMT_BUILD_expressions




