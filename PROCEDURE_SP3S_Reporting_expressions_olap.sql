CREATE PROCEDURE SP3S_Reporting_expressions_OLAP
AS
BEGIN
	
	DECLARE @CCurLocId CHAR(2),@cHoLocId CHAR(2),@bHoLoc BIT

	SELECT @CCurLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'
	
	SELECT @cHoLocId = [VALUE] FROM CONFIG WHERE CONFIG_OPTION='HO_LOCATION_ID'		

	IF @CCurLocId=@cHoLocId
		SET @bHoLoc=1
	ELSE
		SET @bHoLoc=0

		

	

	DELETE FROM xtreme_reports_exp_olap 
	
	

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	SELECT 'ops_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(a.cbs_qty) AS OBS,COUNT(DISTINCT CASE WHEN  a.cbs_qty  <>0 THEN  SKU_NAMES.PRODUCT_CODE ELSE NULL END ) AS OBS_CNT,SUM(a.cbs_qty*sku_names.lc) as OBLC,
	   SUM(a.cbs_qty*(SKU_XFP.XFER_PRICE + isnull(SKU_XFP.xfer_depreciation,0))) as OBXP,
	   SUM(a.cbs_qty*(SKU_XFP.CURRENT_XFER_PRICE + isnull(SKU_XFP.xfer_depreciation,0))) as OBXPC,
	   SUM(a.cbs_qty*((CASE WHEN B.DEPT_ID = [GHOLOCATION] OR ISNULL(sku_xfp.loc_pp,0)=0 THEN SKU_NAMES.PP ELSE SKU_XFP.LOC_PP END))) as OBSP,
	   SUM(a.cbs_qty*((CASE WHEN 1=1 THEN SKU_NAMES.PP ELSE SKU_XFP.LOC_PP END)-ISNULL(c.depcn_value,0)-ISNULL(c.prev_depcn_value,0))) as OBP1,	   
	   SUM(a.cbs_qty*sku_names.ws_price) as OBW,SUM(a.cbs_qty*sku_names.mrp) as OBM,
	   SUM(a.cbs_qty*sku_names.PP_WO_DP) as OBPWD,
	   SUM(a.cbs_qty*(SKU_XFP.xfer_price_without_gst + isnull(SKU_XFP.xfer_depreciation,0))) as OBXPWG ,
	   SUM(a.cbs_qty*(isnull(SKU_XFP.xfer_price_without_gst,0))) as OBXFDEP	   
	 FROM [TABLENAME] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 LEFT JOIN [DATABASE].dbo.year_wise_cbsstk_depcn_det c WITH (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id
	 AND c.fin_year=''01''+dbo.fn_getfinyear([DTODT])
	 WHERE A.BIN_ID <> ''999''  AND [WHERE]  
	 group by [GROUPBY]
	 ' AS base_expr --- 4secs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	SELECT 'git_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'XN_NO' as xn_no_col,'XN_DT' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [TABLENAME] A WITH (NOLOCK) 	 
	 left outer  JOIN [DATABASE].dbo.INM01106 B ON B.INV_ID=SUBSTRING(A.MEMO_ID,4,LEN(A.memo_id))  
	 
	 JOIN [DATABASE].dbo.location c (NOLOCK) ON a.dept_id=c.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	SELECT 'PENDING_APPROVALS_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_APPROVALS_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	SELECT 'pending_wip_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.WIPSTOCK_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	SELECT 'pending_JOBWORK_TRADING_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_JOBWORK_TRADING_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'pending_RPS_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_RPS_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'pending_wps_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_WPS_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'pending_dnps_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_DNPS_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'pending_cnps_qty_opt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],
	 [calculative_col]
	 FROM [DATABASE].dbo.PENDING_WPS_[DOCDT] A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 WHERE [WHERE]  
	 group by [GROUPBY]'

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(a.quantity_in_stock) AS OBS,COUNT(DISTINCT CASE WHEN  QUANTITY_IN_STOCK  <>0 THEN  SKU_NAMES.PRODUCT_CODE ELSE NULL END ) AS OBS_CNT,SUM(a.quantity_in_stock*sku_names.lc) as OBLC,
	   SUM(a.quantity_in_stock*(SKU_XFP.XFER_PRICE + isnull(SKU_XFP.xfer_depreciation,0))) as OBXP,
	   SUM(a.quantity_in_stock*(SKU_XFP.CURRENT_XFER_PRICE + isnull(SKU_XFP.xfer_depreciation,0))) as OBXPC,	   
	   SUM(a.quantity_in_stock*((CASE WHEN B.DEPT_ID = [GHOLOCATION] OR ISNULL(sku_xfp.loc_pp,0)=0 THEN SKU_NAMES.PP ELSE SKU_XFP.LOC_PP END))) as OBSP,
	SUM(a.quantity_in_stock*((CASE WHEN 1=1 THEN SKU_NAMES.PP ELSE SKU_XFP.LOC_PP END)-ISNULL(c.depcn_value,0)-ISNULL(c.prev_depcn_value,0))) as OBP1,	   
	   SUM(a.quantity_in_stock*sku_names.ws_price) as OBW,SUM(a.quantity_in_stock*sku_names.mrp) as OBM,
	   SUM(a.quantity_in_stock*sku_names.PP_WO_DP) as OBPWD,SUM(a.quantity_in_stock*(SKU_XFP.xfer_price_without_gst + isnull(SKU_XFP.xfer_depreciation,0))) as OBXPWG,
	   SUM(a.quantity_in_stock*(isnull(SKU_XFP.xfer_price_without_gst,0))) as OBXFDEP
	 FROM [DATABASE].dbo.pmt01106 A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location b (NOLOCK) ON a.dept_id=b.dept_id [JOIN]
	 LEFT JOIN [DATABASE].dbo.year_wise_cbsstk_depcn_det c WITH (NOLOCK) ON c.product_code=a.product_code AND c.dept_id=a.dept_id
	 AND c.fin_year=''01''+dbo.fn_getfinyear([DTODT])
	 WHERE A.BIN_ID <> ''999'' AND [WHERE]  
	 group by [GROUPBY] HAVING SUM(a.quantity_in_stock)<>0'

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'A.XN_DT' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(a.quantity_OB) AS OBS,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity_ob*sku_names.lc) as OBLC,
	   SUM(a.quantity_OB*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity_OB*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity_OB*sku_names.pp) as OBP1,
	   SUM(a.quantity_OB*sku_names.ws_price) as OBW,SUM(a.quantity_OB*sku_names.mrp) as OBM,
	    SUM(a.quantity_OB*sku_names.PP_WO_DP) as OBPWD,
		SUM(a.quantity_OB*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 FROM [DATABASE].dbo.OPS01106 A WITH (NOLOCK) [JOIN]
	 WHERE A.BIN_ID <> ''999'' AND  A.xn_dt BETWEEN [DFROMDT] AND [DTODT] AND [WHERE]  
	 group by [GROUPBY]' AS base_expr --- 4secs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_comp' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'A.XN_DT' as xn_dt_col,
	  '[LAYOUT_COL],    
	   SUM(a.quantity_OB) AS OBS
	 FROM [DATABASE].dbo.OPS01106 A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=a.dept_id [JOIN]
	 WHERE A.xn_dt BETWEEN [DFROMDT] AND [DTODT] AND [WHERE]  
	 group by [GROUPBY]' AS base_expr --- 4secs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_build' as master_col,'a.dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'' as xn_no_col,'A.XN_DT' as xn_dt_col,
	  '[LAYOUT_COL],    
	   SUM(a.quantity_OB) AS OBS,SUM(a.quantity_OB*sku_names.pp) as OBP1
	 FROM [DATABASE].dbo.OPS01106 A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=a.dept_id [JOIN]
	 WHERE A.xn_dt BETWEEN [DFROMDT] AND [DTODT] AND [WHERE]  
	 group by [GROUPBY]' AS base_expr --- 4secs

	 
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.source_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	 SUM(A.QUANTITY)*-1 AS OBS,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM, 
	   SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)   
	 [JOIN]
	 WHERE A.source_bin_id <> ''999'' AND b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED = 0  AND [WHERE]
	group by [GROUPBY]' AS base_expr    --- 3ecs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.source_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(A.QUANTITY)*-1 AS OBS
	 from [DATABASE].dbo.FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED = 0  AND [WHERE]
	' AS base_expr    --- 3ecs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
		SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.source_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(A.QUANTITY)*-1 AS OBS,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2) [JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED = 0  AND [WHERE]
	group by [GROUPBY]' AS base_expr    --- 3ecs


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 SELECT 'DCO_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.source_bin_id' as bin_join_col,'' as xnparty_join_col,
	 'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.FLOOR_ST_DET A WITH (NOLOCK)
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B WITH (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 [JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND B.CANCELLED = 0  AND [WHERE]
	group by [GROUPBY]' AS base_expr    --- 3ecs

	 -- DCI    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.item_target_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(A.QUANTITY)  AS Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM,
	   SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 [JOIN] 
	 WHERE A.item_target_bin_id  <> ''999'' AND b.receipt_dt BETWEEN [DFROMDT] AND [DTODT] AND b.receipt_Dt<>'''' AND B.CANCELLED = 0 AND [WHERE]
	group by [GROUPBY]' AS base_expr --- 2secs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.item_target_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs
	 from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 [JOIN] 
	 WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT] AND b.receipt_Dt<>''''  AND B.CANCELLED = 0 AND [WHERE]
	' AS base_expr --- 2secs

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.item_target_bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	 [JOIN] 
	 WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT] AND b.receipt_Dt<>''''  AND B.CANCELLED = 0 AND [WHERE]
	group by [GROUPBY]' AS base_expr --- 2secs


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'DCI_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.item_target_bin_id' as bin_join_col,
	  '' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.FLOOR_ST_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.FLOOR_ST_MST B (NOLOCK) ON A.MEMO_ID  = B.MEMO_ID      
	 [JOIN] 
	 WHERE b.receipt_dt BETWEEN [DFROMDT] AND [DTODT] AND B.CANCELLED = 0 AND [WHERE]
	group by [GROUPBY]' AS base_expr --- 2secs

	 -- PURCHASE INVOICE    
	 
	
	IF @bHoLoc=0
	BEGIN
		INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])
		SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
		   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
		   SUM(a.quantity*sku_names.mrp) as OBM,
		   SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD,
	      SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
		 [JOIN]
		 WHERE b.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND b.receipt_Dt<>'''' AND c.mrr_id IS NULL
		  AND a.product_code<>'''' AND [WHERE] 
		 group by [GROUPBY]' AS base_expr
	END
	ELSE
	BEGIN
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
		   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
		   SUM(a.quantity*sku_names.mrp) as OBM,  SUM(a.quantity*sku_names.PP_WO_DP) as  OBPWD,
		   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
		 [JOIN]
		 WHERE b.bin_id  <> ''999'' AND  b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  b.inv_mode=1 AND B.CANCELLED = 0 AND b.receipt_Dt<>'''' AND c.mrr_id IS NULL
		 AND a.product_code<>'''' AND [WHERE] 
		 group by [GROUPBY]' AS base_expr

		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs,COUNT(DISTINCT SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
		   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
		   SUM(a.quantity*sku_names.mrp) as OBM,SUM(a.quantity*sku_names.PP_WO_DP) as  OBPWD,
		   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
		 from [DATABASE].dbo.InD01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 [JOIN]
		 WHERE b.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  b.inv_mode=2 AND B.CANCELLED = 0 AND c.CANCELLED = 0 AND b.receipt_Dt<>''''
		 AND a.product_code<>'''' AND [WHERE] 
		 group by [GROUPBY]' AS base_expr
	END
	
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
	 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=1 AND  B.CANCELLED = 0 AND b.receipt_Dt<>'''' AND c.mrr_id IS NULL
	 AND a.product_code<>'''' AND [WHERE] 
	 ' AS base_expr
	
	IF @bHoLoc=1
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs
		 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 [JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND  B.CANCELLED = 0
		 AND c.cancelled=0 AND b.receipt_Dt<>'''' 
		 AND [WHERE] 
		 ' AS base_expr
	ELSE
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		SUM(A.QUANTITY)  AS Obs
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 [JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.inv_mode=2 AND  B.CANCELLED = 0
		 AND b.receipt_Dt<>'''' 
		  AND [WHERE] 
		 ' AS base_expr


	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)  AS Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
	 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND b.receipt_Dt<>'''' AND c.mrr_id IS NULL
	 AND b.inv_mode=1
	 AND a.product_code<>'''' AND [WHERE] 
	 group by [GROUPBY]' AS base_expr


	 IF @bHoLoc=1
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		 SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		 SUM(A.QUANTITY)  AS Obs,SUM(a.quantity*sku_names.pp) as OBP1
		 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 [JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND  c.CANCELLED = 0 AND b.receipt_Dt<>'''' 
		 AND b.inv_mode=2
		 AND [WHERE] 
		 group by [GROUPBY]' AS base_expr
	ELSE
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		 SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
		 SUM(A.QUANTITY)  AS Obs,SUM(a.quantity*sku_names.pp) as OBP1
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
		 [JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND b.receipt_Dt<>'''' 
		 AND b.inv_mode=2
		 AND [WHERE] 
		 group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])
	SELECT 'PUR_QTY' as master_col,'b.dept_Id' as loc_join_col,'b.bin_id' as bin_join_col,'''LM''+B.AC_CODE' as xnparty_join_col,
	'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0
	 AND b.inv_mode=1 AND c.mrr_id IS NULL AND a.product_Code<>'''' AND [WHERE] 
	 group by [GROUPBY]' AS base_expr
	
	 
	 
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 
	 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])
	SELECT 'PO_QTY' as master_col,'b.dept_Id' as loc_join_col,'b.bin_id' as bin_join_col,'''LM''+B.AC_CODE' as xnparty_join_col,
		'b.po_no' as xn_no_col,'b.po_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.PoD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PoM01106 B WITH(NOLOCK) ON A.Po_id = B.po_id	
	 [JOIN]
	 WHERE b.po_dt BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0	 AND [WHERE] 
	 group by [GROUPBY]' AS base_expr
	 
	 
	 
	 
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 
	 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])
	SELECT 'CHI_QTY_HO' as master_col,'b.dept_Id' as loc_join_col,'b.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 C WITH(NOLOCK) ON A.INV_ID = C.INV_ID
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID


	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND c.cancelled=0
	 AND b.inv_mode=2 AND [WHERE] 
	 group by [GROUPBY]' AS base_expr

	 IF @bHoloc=0
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		SELECT 'CHI_QTY' as master_col,'b.dept_Id' as loc_join_col,'b.bin_id' as bin_join_col,
		'''LM''+B.AC_CODE' as xnparty_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
		 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
		
		 [JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 and B.bin_id <> ''999''
		AND  b.inv_mode=2 AND [WHERE] 
		 group by [GROUPBY]' AS base_expr
	ELSE
		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
		SELECT 'CHI_QTY' as master_col,'b.dept_Id' as loc_join_col,'b.bin_id' as bin_join_col,
		'''LM''+B.AC_CODE' as xnparty_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
		from [DATABASE].dbo.InD01106 A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
		 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID	 		 
		[JOIN]
		 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0  AND  c.CANCELLED = 0 and B.bin_id <> ''999''
		  AND b.inv_mode=2 AND [WHERE] 
		 group by [GROUPBY]' AS base_expr

	  
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty' as master_col,'left(b.memo_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY) AS Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM,SUM(a.quantity*sku_names.PP_WO_DP) as  OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	[JOIN]
	 WHERE b.bin_id  <> ''999'' AND b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND [WHERE]
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.memo_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY) AS Obs
	 from [DATABASE].dbo.GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND [WHERE]
	 ' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.memo_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY) AS Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND [WHERE]
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'GRNPSIN_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'b.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.GRN_PS_DET  A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.GRN_PS_MST B WITH(NOLOCK) ON A.MEMO_ID  = B.MEMO_ID
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND [WHERE]
	 group by [GROUPBY]' AS base_expr

	 
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)--(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,SUM(a.quantity*sku_names.PP_WO_DP)*-1 as  OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
	[JOIN]
	 WHERE b.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND b.receipt_Dt<>''''
	 
	 AND ISNULL(B.PIM_MODE,0)=6
	  AND [WHERE]
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)--(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND b.receipt_Dt<>''''
	 AND ISNULL(B.PIM_MODE,0)=6
	   AND [WHERE]
	 ' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)--(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.dept_id
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND b.receipt_Dt<>''''
	 AND ISNULL(B.PIM_MODE,0)=6
	  AND [WHERE]
	 group by [GROUPBY]
	 ' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	 SELECT 'GRNPSOUT_QTY' as master_col,'b.dept_id' as loc_join_col,'b.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 
	 AND ISNULL(B.PIM_MODE,0)=6
	  AND [WHERE]
	 group by [GROUPBY]' AS base_expr
	      
	   
	 -- PURCHASE RETURN    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty' as master_col,'LOc.MAJOR_dEPT_ID' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(quantity)*-1 as Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,SUM(a.quantity*sku_names.PP_WO_DP)*-1 as  OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.RM_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND [WHERE]  
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_comp' as master_col,'LOc.MAJOR_dEPT_ID' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(quantity)*-1 as Obs
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.RM_ID,2)
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND [WHERE]  
	 ' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_build' as master_col,'LOc.MAJOR_dEPT_ID' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(quantity)*-1 as Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.RM_ID,2)
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	 AND [WHERE]  
	 group by [GROUPBY]' AS base_expr
	 
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 SELECT 'PRT_QTY' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND [WHERE]  
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,
	 xnparty_join_col,xnparty_join_col_2,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	 
	 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	SELECT 'NET_PUR_QTY' as master_col,'b.dept_Id' as loc_join_col,'LEFT(b.rm_id,2)' as loc_join_col2,'b.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,
	'b.mrr_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,
	'b.rm_no' as xn_no_col_2,'b.rm_dt' as xn_dt_col_2,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.PID01106 A WITH(NOLOCK) 
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.MRR_ID = B.MRR_ID
	 LEFT OUTER JOIN  [DATABASE].dbo.pim01106 c (NOLOCK) ON c.ref_converted_mrntobill_mrrid=b.mrr_id
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0
	  AND b.inv_mode=1 AND c.mrr_id IS NULL AND  a.product_code<>'''' AND [WHERE] 
	 group by [GROUPBY]
	 
	 UNION ALL 
	 SELECT [LAYOUT_COL_2],[CALCULATIVE_COL_2] 
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	[JOIN_2]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=1 AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	  AND [WHERE_2]  
	 group by [GROUPBY_2]' AS base_expr
	 
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 SELECT 'CHO_QTY' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]     
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID   
	


	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=2 AND b.cancelled=0 AND B.DN_TYPE IN (0,1)  and A.bin_id <> ''999''
	
	 AND [WHERE]  
	 group by [GROUPBY]' AS base_expr
	   
	 ---RETAIL SALE     
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,SUM(a.quantity*sku_names.PP_WO_DP)*-1 as  OBPWD
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr



	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,SUM(a.quantity*sku_names.PP_WO_DP)*-1 as  OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.CMD_CONS A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	
	--CONSUME
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.cm_id,2)' as loc_join_col,'ISNULL(a.bin_id,''000'')' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs
	 from [DATABASE].dbo.cmd_cons A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],    
	  SUM( A.QUANTITY)*-1 as  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.cmd_cons A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cM_ID,2)
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr




	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLS_QTY' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND quantity>0  
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	---yahan tak ho gaya
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'SLR_QTY' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]   
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID    
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND quantity<0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'NET_SLS_QTY' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID   	
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
		
	--WTD_SLS
	
	
	
	 -- APPROVAL ISSUE    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)*-1 AS  Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE)*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,SUM(a.quantity*sku_names.PP_WO_DP)*-1 as  OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(A.QUANTITY)*-1 AS  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 SELECT 'APP_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '(case when B.CUSTOMER_CODE= ''000000000000'' then''lm''+ b.ac_code else  ''CUS''+B.CUSTOMER_CODE END )' as xnparty_join_col,
	 'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  
	 AND b.cancelled=0  AND  B.MEMO_NO  NOT like''%OPS%''  
	 AND  [WHERE] group by [GROUPBY]' AS base_expr    

	
	   
	 -- APPROVAL RETURN    
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr,product_code_col)    
	 SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'c.memo_no' as xn_no_col,'c.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(b.QUANTITY) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE) AS OBS_CNT,SUM(b.QUANTITY*sku_names.lc) as OBLC,SUM(b.QUANTITY*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(b.QUANTITY*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(b.QUANTITY*sku_names.pp) as OBP1,SUM(b.QUANTITY*sku_names.ws_price) as OBW,
	   SUM(b.QUANTITY*sku_names.mrp) as OBM,SUM(B.quantity*sku_names.PP_WO_DP) as  OBPWD,
	   SUM(b.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.APPROVAL_RETURN_DET B WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(c.Memo_ID,2)
	 [JOIN]
	 WHERE b.bin_id  <> ''999'' AND c.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND c.cancelled=0   
	 AND  [WHERE]    
	group by [GROUPBY]' AS base_expr,'APD_product_code' as product_code_col




	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr,product_code_col)    
	 SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'c.memo_no' as xn_no_col,'c.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(b.QUANTITY) AS  Obs
	 from [DATABASE].dbo.APPROVAL_RETURN_DET B WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(c.Memo_ID,2)
	 [JOIN]
	 WHERE c.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND c.cancelled=0 AND [WHERE]    
	' AS base_expr,'APD_product_code' as product_code_col

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr,product_code_col)    
	 SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'c.memo_no' as xn_no_col,'c.memo_dt' as xn_dt_col,'[LAYOUT_COL],    
	   SUM(b.QUANTITY) AS  Obs,SUM(b.QUANTITY*sku_names.pp) as OBP1
	 from [DATABASE].dbo.APPROVAL_RETURN_DET B WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APPROVAL_RETURN_MST C WITH(NOLOCK) ON C.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(c.Memo_ID,2)
	 [JOIN]
	 WHERE c.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND c.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr,'APD_product_code' as product_code_col

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr,product_code_col)    
	 SELECT 'APR_QTY' as master_col,'left(B.memo_id,2)' as loc_join_col,'A.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'B.memo_no' as xn_no_col,'B.memo_dt' as xn_dt_col,
	 '[LAYOUT_COL],[CALCULATIVE_COL]    
	  from [DATABASE].dbo.APPROVAL_RETURN_DET A WITH(NOLOCK)     
	 JOIN  [DATABASE].dbo.APPROVAL_RETURN_MST B WITH(NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 [JOIN]
	 WHERE B.memo_dt BETWEEN [DFROMDT] AND [DTODT] 
	 AND B.cancelled=0   	 AND [WHERE]    
	group by [GROUPBY]' AS base_expr,'APD_product_code' as product_code_col
		

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,
	 xnparty_join_col,xnparty_join_col_2,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    


	 --CREATE NONCLUSTERED INDEX IX_PCODE_PID01106_INCL ON [dbo].[pid01106] ([product_code]) INCLUDE ([quantity],[mrr_id],[TAX_AMOUNT])  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	SELECT 'PENDING_APP_QTY' as master_col,'b.dept_Id' as loc_join_col,'LEFT(b.memo_id,2)' as loc_join_col2,'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	'''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'''CUS''+B.CUSTOMER_CODE' as xnparty_join_col_2,
	'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,
	'b.memo_no' as xn_no_col_2,'b.memo_dt' as xn_dt_col_2,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.APD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.APM01106 B WITH(NOLOCK) ON A.Memo_ID = B.Memo_ID
	 [JOIN]
	 WHERE b.memo_DT<=[DTODT]  AND  B.CANCELLED = 0  AND  B.MEMO_NO  NOT like''%OPS%''  
	 AND [WHERE] 
	 group by [GROUPBY]'
	 
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,
	 xnparty_join_col,xnparty_join_col_2,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr,product_code_col)    
     
     SELECT 'PENDING_APP_QTY' as master_col,'LEFT(b.memo_id,2)' as loc_join_col,'LEFT(b.memo_id,2)' as loc_join_col2,'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	'''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'''CUS''+B.CUSTOMER_CODE' as xnparty_join_col_2,
	'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,
	'b.memo_no' as xn_no_col_2,'b.memo_dt' as xn_dt_col_2,'[LAYOUT_COL],[CALCULATIVE_COL_2]    
	 from [DATABASE].dbo.approval_return_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.approval_return_mst B WITH(NOLOCK) ON A.Memo_ID = B.Memo_ID
	 LEFT OUTER  JOIN  [DATABASE].DBO.APD01106 APD WITH(NOLOCK) ON A.APD_ROW_ID  = APD.ROW_ID
	 LEFT OUTER  JOIN  [DATABASE].DBO.APM01106 APM WITH(NOLOCK) ON APD.MEMO_ID  = APM.MEMO_ID
	 [JOIN]
	 WHERE b.memo_DT <=[DTODT]  AND  B.CANCELLED = 0   
	 AND [WHERE] 
	 group by [GROUPBY]','APD_product_code' AS product_code_col
	 

	 -- CANCELLATION AND STOCK ADJUSTMENT    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,
	 loc_join_col_2,bin_join_col_2,XN_NO_COL_2,XN_DT_COL_2,
	 loc_join_col_3,bin_join_col_3,XN_NO_COL_3,XN_DT_COL_3,base_expr)    
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cnc_memo_no' as xn_no_col,'b.CNC_MEMO_DT' as xn_dt_col,
	  'loc.major_dept_id' as loc_join_col_2,'a.bin_id' as bin_join_col_2,'b.cnc_memo_no' as xn_no_col_2,'b.CNC_MEMO_DT' as xn_dt_col_2,
	  'loc.major_dept_id' as loc_join_col_3,'a.bin_id' as bin_join_col_3,'b.cnc_memo_no' as xn_no_col_3,'b.CNC_MEMO_DT' as xn_dt_col_3,
	  '[LAYOUT_COL],    
	   SUM(CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )  AS OBS_CNT,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.lc) as OBLC,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.pp) as OBP1,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.ws_price) as OBW,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.mrp) as OBM,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.PP_WO_DP) as OBPWD,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	   
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cnc_Memo_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY]
	
	UNION ALL
	 SELECT [LAYOUT_COL_2],0 AS OBS,0 AS OBS_CNT,0 as OBLC,0 as OBXP,
	 0 as OBXPC,SUM(depcn_value+ISNULL(prev_depcn_value,0)) as OBP1,
	 0 as OBW,0 as OBM,0 as OBPWD,0 AS OBXPWG
	 FROM [DATABASE].dbo.year_wise_cbsstk_depcn_det A WITH (NOLOCK) 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=a.dept_id [JOIN_2]
	 WHERE a.fin_year=''01''+dbo.fn_getfinyear([DTODT])   AND [WHERE_2]  
	 group by [GROUPBY_2]

	 UNION ALL
	 SELECT [LAYOUT_COL_3],0 AS OBS,0 AS OBS_CNT,0 as OBLC,0 as OBXP,
	 0 as OBXPC,0 as OBP1,
	 0 as OBW,SUM(CASE WHEN cnc_type=1 THEN -rate 
	 WHEN cnc_type=2 THEN rate ELSE 0 END) as OBM,0 as OBPWD,0 AS OBXPWG
	 FROM [DATABASE].dbo.icd01106 A WITH (NOLOCK)
	 JOIN [DATABASE].dbo.icm01106 b (NOLOCK) ON b.cnc_memo_id=a.cnc_memo_id
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cnc_Memo_ID,2) [JOIN_3]
	 WHERE b.bin_id  <> ''999'' AND cnc_memo_dt<=[DTODT] AND ISNULL(stock_adj_note,0)=1 AND  isnull(stock_adj_type,1)=2 AND cancelled=0 AND  [WHERE_3]  
	 group by [GROUPBY_3]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,
	 loc_join_col_2,bin_join_col_2,XN_NO_COL_2,XN_DT_COL_2,
	 loc_join_col_3,bin_join_col_3,XN_NO_COL_3,XN_DT_COL_3,base_expr)    
	  SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cnc_memo_no' as xn_no_col,'b.CNC_MEMO_DT' as xn_dt_col,
	  'loc.major_dept_id' as loc_join_col_2,'a.bin_id' as bin_join_col_2,'b.cnc_memo_no' as xn_no_col_2,'b.CNC_MEMO_DT' as xn_dt_col_2,
	  'loc.major_dept_id' as loc_join_col_3,'a.bin_id' as bin_join_col_3,'b.cnc_memo_no' as xn_no_col_3,'b.CNC_MEMO_DT' as xn_dt_col_3,
	  '[LAYOUT_COL],    
	   SUM(CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END) AS  Obs
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cnc_Memo_ID,2)
	[JOIN]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	' as base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,
	 loc_join_col_2,bin_join_col_2,XN_NO_COL_2,XN_DT_COL_2,
	 loc_join_col_3,bin_join_col_3,XN_NO_COL_3,XN_DT_COL_3,base_expr)    
	  SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cnc_memo_no' as xn_no_col,'b.CNC_MEMO_DT' as xn_dt_col,
	  'loc.major_dept_id' as loc_join_col_2,'a.bin_id' as bin_join_col_2,'b.cnc_memo_no' as xn_no_col_2,'b.CNC_MEMO_DT' as xn_dt_col_2,
	  'loc.major_dept_id' as loc_join_col_3,'a.bin_id' as bin_join_col_3,'b.cnc_memo_no' as xn_no_col_3,'b.CNC_MEMO_DT' as xn_dt_col_3,
	  '[LAYOUT_COL],    
	   SUM(CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END) AS  Obs,
	   SUM((CASE WHEN CNC_TYPE=1 THEN -quantity ELSE quantity END)*sku_names.pp) as OBP1
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.cnc_Memo_ID,2)
	[JOIN]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY]' as base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'CNC_QTY' as master_col,'left(b.cnc_memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''''' as xnparty_join_col,'b.cnc_memo_no' as xn_no_col,'b.cnc_memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	  from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	[JOIN]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND CNC_TYPE=1
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'UNC_QTY' as master_col,'left(b.cnc_memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''' as xnparty_join_col,'b.cnc_memo_no' as xn_no_col,'b.cnc_memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	  from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	[JOIN]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND CNC_TYPE=2
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 xnparty_join_col,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	  SELECT 'NET_CNC_QTY' as master_col,'left(b.cnc_memo_id,2)' as loc_join_col,
	  'left(b.cnc_memo_id,2)' as loc_join_col_2,'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	  '''' as xnparty_join_col,'b.cnc_memo_no' as xn_no_col,'b.cnc_memo_dt' as xn_dt_col,
	  'b.cnc_memo_no' as xn_no_col_2,'b.cnc_memo_dt' as xn_dt_col_2,'[layout_col],[CALCULATIVE_COL]
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	[JOIN]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND CNC_TYPE=1
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY]

	UNION ALL
	SELECT [layout_col_2],[CALCULATIVE_COL_2]
	 from [DATABASE].dbo.ICD01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.ICM01106 B WITH(NOLOCK) ON A.CNC_MEMO_ID = B.CNC_MEMO_ID    
	[JOIN_2]
	 WHERE b.CNC_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND CNC_TYPE=2
	 AND B.STOCK_ADJ_NOTE=0 AND [WHERE]
	group by [GROUPBY_2]' AS base_expr
	     
	 --WHOLESALE INVOICE     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside 
	SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.inv_no' as xn_no_col,'b.INV_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,    SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD,
	   SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) *-1 as OBXPWG
	  
	  
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.inv_ID,2)
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND ISNULL(PENDING_GIT,0)=0
	  AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside 
	SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.inv_no' as xn_no_col,'b.INV_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs
  
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.inv_ID,2)
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 
	   AND [WHERE]
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside 
	SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.inv_no' as xn_no_col,'b.INV_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
  
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.inv_ID,2)
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND ISNULL(PENDING_GIT,0)=0
	  AND [WHERE]
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'WSL_QTY' as master_col,'left(b.inv_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND b.inv_mode=1 AND ISNULL(bin_transfer,0)<>1
	  AND [WHERE]
	group by [GROUPBY]' AS base_expr



		 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	    SELECT 'WBO_QTY' as master_col,'left(b.order_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
		'''LM''+B.AC_CODE' as xnparty_join_col,'b.order_no' as xn_no_col,'b.order_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
		 from [DATABASE].dbo.BUYER_ORDER_DET A WITH(NOLOCK)    
		 JOIN  [DATABASE].dbo.BUYER_ORDER_MST B WITH(NOLOCK) ON A.order_id = B.order_id    
		LEFT OUTER JOIN [DATABASE].DBO.ARTICLE  WITH(NOLOCK) ON A.ARTICLE_CODE = ARTICLE.ARTICLE_CODE  
		LEFT OUTER JOIN [DATABASE].DBO.SECTIOND  WITH(NOLOCK) ON ARTICLE.SUB_SECTION_CODE = SECTIOND.SUB_SECTION_CODE  
		LEFT OUTER JOIN [DATABASE].DBO.SECTIONM WITH(NOLOCK) ON SECTIOND.SECTION_CODE = SECTIONM.SECTION_CODE  
		LEFT OUTER JOIN [DATABASE].DBO.PARA1  WITH(NOLOCK) ON A.PARA1_CODE = PARA1.PARA1_CODE  
		LEFT OUTER JOIN [DATABASE].DBO.PARA2  WITH(NOLOCK) ON A.PARA2_CODE = PARA2.PARA2_CODE  
		LEFT OUTER JOIN [DATABASE].DBO.PARA3  WITH(NOLOCK) ON A.PARA3_CODE = PARA3.PARA3_CODE  
		[JOIN]
		 WHERE b.ORDER_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 	 
		  AND [WHERE]
		group by [GROUPBY]' AS base_expr





	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'APO_QTY' as master_col,'left(b.inv_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	SUM (quantity) as APOQ
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND b.inv_mode=1 AND ISNULL(bin_transfer,0)=1
	  AND [WHERE]
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'CHO_QTY' as master_col,'left(b.inv_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID   
	
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND ISNULL(PENDING_GIT,0)=0 and A.bin_id <> ''999''
	
	 AND b.inv_mode=2
	  AND [WHERE]
	group by [GROUPBY]' AS base_expr

	----- Net Challan Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,loc_join_col_3,loc_join_col_4, --(-1) avilable inside 
	bin_join_col,bin_join_col_2,bin_join_col_3,bin_join_col_4,
	xnparty_join_col,xnparty_join_col_2,xnparty_join_col_3,xnparty_join_col_4,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,
	XN_NO_COL_3,XN_DT_COL_3,XN_NO_COL_4,XN_DT_COL_4,base_expr)    
	 
	SELECT 'NET_CHI_QTY' as master_col,'b.dept_Id' as loc_join_col,'LEFT(b.CN_ID,2)' as loc_join_col_2,
	'left(b.rm_id,2)' as loc_join_col_3,'left(b.inv_id,2)' as loc_join_col_4,
	'b.bin_id' as bin_join_col,'b.bin_id' as bin_join_col_2,'a.bin_id' as bin_join_col_3,'a.bin_id' as bin_join_col_4,
	'b.mrr_no' as xn_no_col,'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,
	'''LM''+B.AC_CODE' as xnparty_join_col_3,'''LM''+B.AC_CODE' as xnparty_join_col_4,'b.receipt_dt' as xn_dt_col,'b.cn_no' as xn_no_col_2,'b.receipt_dt' as xn_dt_col_2,
	'b.rm_no' as xn_no_col_3,'b.rm_dt' as xn_dt_col_3,'b.inv_no' as xn_no_col_4,'b.inv_dt' as xn_dt_col_4,
	'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 C WITH(NOLOCK) ON A.INV_ID = C.INV_ID
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID

	 	   
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND  B.CANCELLED = 0 AND c.cancelled=0 and B.bin_id <> ''999''
	
	 AND b.inv_mode=2  AND [WHERE] 
	 group by [GROUPBY]
	 
	 UNION ALL
	 SELECT [LAYOUT_COL_2],[CALCULATIVE_COL_2]
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
	 
	 		 		

	[JOIN_2]
	 WHERE (B.MODE=2 AND b.receipt_dt BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	
	  AND [WHERE_2]    
	group by [GROUPBY_2]
	
	UNION ALL	 
	SELECT [LAYOUT_COL_3],[CALCULATIVE_COL_3]  
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    

	


	[JOIN_3]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.mode=2 AND b.cancelled=0 AND B.DN_TYPE IN (0,1)  and A.bin_id <> ''999''
	
	  AND [WHERE_3]  
	 group by [GROUPBY_3]
	
	UNION ALL	
	SELECT  [LAYOUT_COL_4],[CALCULATIVE_COL_4]
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    

	

	[JOIN_4]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND ISNULL(PENDING_GIT,0)=0  and A.bin_id <> ''999''
	
	 AND b.inv_mode=2
	  AND [WHERE_4]
	 group by [GROUPBY_4]' AS base_expr
	
	----- Git Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,loc_join_col_3,loc_join_col_4,loc_join_col_5,--(-1) avilable inside 
	bin_join_col,bin_join_col_2,bin_join_col_3,bin_join_col_4,bin_join_col_5,
	xnparty_join_col,xnparty_join_col_2,xnparty_join_col_3,xnparty_join_col_4,
	XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,
	XN_NO_COL_3,XN_DT_COL_3,XN_NO_COL_4,XN_DT_COL_4,
	XN_NO_COL_5,XN_DT_COL_5,
	base_expr)    
	 
	SELECT 'GIT_QTY' as master_col,'b.dept_Id' as loc_join_col,'LEFT(b.CN_ID,2)' as loc_join_col_2,
	'b.party_dept_id' as loc_join_col_3,'b.party_dept_id' as loc_join_col_4,'a.dept_id' as loc_join_col_5,
	'b.bin_id' as bin_join_col,'b.bin_id' as bin_join_col_2,'a.bin_id' as bin_join_col_3,'a.bin_id' as bin_join_col_4,'a.bin_id' as bin_join_col_5,
	'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'''LM''+loclm.dept_AC_CODE' as xnparty_join_col_3,
	'''LM''+loclm.dept_AC_CODE' as xnparty_join_col_4,'b.inv_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'b.manual_inv_no' as xn_no_col_2,'b.receipt_dt' as xn_dt_col_2,
	'b.rm_no' as xn_no_col_3,'b.rm_dt' as xn_dt_col_3,'b.inv_no' as xn_no_col_4,'b.inv_dt' as xn_dt_col_4,
	'A.DEPT_ID' as xn_no_col_5,'A.XN_DT' as xn_dt_col_5,
	'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.PIM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID
	 JOIN  [DATABASE].dbo.INM01106 c WITH(NOLOCK) ON c.inv_ID = a.inv_ID
	 [JOIN]
	 WHERE b.RECEIPT_DT<=[DTODT] AND B.RECEIPT_dT<>''''  AND  B.CANCELLED = 0 AND c.cancelled=0
	 AND b.inv_mode=2  AND [WHERE]
	 group by [GROUPBY]

	 UNION ALL
	 SELECT [LAYOUT_COL_2],[CALCULATIVE_COL_2]
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN_2]
	 WHERE (MODE=2 AND  b.RECEIPT_DT<=[DTODT] AND B.RECEIPT_dT<>'''')
	 AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	 AND [WHERE_2]    
	group by [GROUPBY_2]
	
	UNION ALL	 
	SELECT [LAYOUT_COL_3],[CALCULATIVE_COL_3]
	 from [DATABASE].dbo.RMD01106 A WITH(NOLOCK)
	 JOIN  [DATABASE].dbo.RMM01106 B WITH(NOLOCK) ON A.RM_ID = B.RM_ID    
	 join [DATABASE].dbo.location loclm on loclm.dept_id=LEFT(b.rm_id,2)
	[JOIN_3]
	 WHERE b.RM_DT BETWEEN '''' AND [DTODT]  AND b.mode=2 AND b.cancelled=0 AND B.DN_TYPE IN (0,1) 
	 AND [WHERE_3]  
	 group by [GROUPBY_3]
	
	UNION ALL	
	SELECT  [LAYOUT_COL_4],[CALCULATIVE_COL_4]
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    
	 join [DATABASE].dbo.location loclm on loclm.dept_id=LEFT(b.inv_id,2)
	[JOIN_4]
	 WHERE b.INV_DT BETWEEN '''' AND [DTODT]  AND b.cancelled=0  
	 AND b.inv_mode=2
	  AND [WHERE_4]
	 group by [GROUPBY_4] ' AS base_expr

	 --AND ISNULL(PENDING_GIT,0)=0

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,
	xnparty_join_col,XN_NO_COL,XN_NO_COL_2,XN_NO_COL_3,XN_NO_COL_4,XN_NO_COL_5,XN_DT_COL,base_expr)    
	 
	SELECT 'GIT_QTY' as master_col,'b.dept_Id' as loc_join_col,'A.bin_id' as bin_join_col,
	'''LM''+C.AC_CODE' as xnparty_join_col,'XN_NO' as xn_no_col, 'XN_NO' as xn_no_col_2,'XN_NO' as xn_no_col_3,'XN_NO' as xn_no_col_4,
	'XN_NO' as xn_no_col_5,  
	'b.receipt_dt' as xn_dt_col,
	'[LAYOUT_COL_5],[CALCULATIVE_COL_5]
	 from [DATABASE].dbo.OPS01106 A WITH(NOLOCK)    
	 JOIN [DATABASE].dbo.location b WITH (NOLOCK) ON b.dept_id=a.dept_id
	 JOIN [DATABASE].dbo.lm01106 c (NOLOCK) ON c.ac_code=b.dept_ac_code
	[JOIN]
	 WHERE a.receipt_dt<=[DTODT] AND ISNULL(a.git_qty,0)<>0  AND [WHERE]
	 group by [GROUPBY]'
	 	 	 
	----- Wholesale PackSlip
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty' as master_col,'left(b.ps_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'b.ps_no' as xn_no_col,'b.ps_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	SUM(a.quantity*sku_names.mrp)*-1 as OBM, SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD,
	SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	  
	 from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.ps_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_comp' as master_col,'left(b.ps_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'b.ps_no' as xn_no_col,'b.ps_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs
	from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.ps_ID,2)
	[JOIN]
	 WHERE b.ps_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_build' as master_col,'left(b.ps_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'b.ps_no' as xn_no_col,'b.ps_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity)*-1 as  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.ps_ID,2)
	[JOIN]
	 WHERE b.ps_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'wpi_qty' as master_col,'left(b.ps_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.ps_no' as xn_no_col,'b.ps_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]   
	 from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	[JOIN]
	 WHERE b.ps_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	----- Wholesale PackSlip Return (WPR)
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'wpr_qty' as master_col,'left(b.inv_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID   
	 JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id AND a.ps_id=c.ps_id
 	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND ISNULL(PENDING_GIT,0)=0 AND  c.cancelled=0 AND [WHERE]	 
	group by [GROUPBY]' AS base_expr

	
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty' as master_col,'left(b.INV_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM (quantity) as  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,
	SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,
	   SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM, SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	  from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID   
	 JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id  AND a.ps_id=c.ps_id
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.inv_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_comp' as master_col,'left(b.inv_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],
	SUM (a.quantity) as  Obs
	 from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID   
	JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id   AND a.ps_id=c.ps_id
	JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.inv_ID,2) 
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0 AND ISNULL(PENDING_GIT,0)=0 AND [WHERE]	 
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	SELECT 'ops_qty_pmt_build' as master_col,'left(b.inv_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	'''LM''+B.AC_CODE' as xnparty_join_col,'b.inv_no' as xn_no_col,'b.inv_dt' as xn_dt_col,'[LAYOUT_COL],
	SUM (a.quantity) as  Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID   
	 JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id   AND a.ps_id=c.ps_id
	JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.inv_ID,2)  	  
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND c.cancelled=0  AND ISNULL(PENDING_GIT,0)=0 AND [WHERE]	 
	group by [GROUPBY]' AS base_expr

    ---- Net Wps Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,xnparty_join_col_2,
	XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	SELECT 'PENDING_WPS_QTY' as master_col,'left(b.ps_id,2)' as loc_join_col,'LEFT(b.inv_id,2)' as loc_join_col_2,
	'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'b.inv_no' as XN_NO_COL,
	'b.inv_dt' as XN_DT_COL,'b.cn_no' as XN_NO_COL_2,'b.cn_dt' as XN_DT_COL_2,'[layout_col],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.wps_det A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.wps_mst B WITH(NOLOCK) ON A.ps_ID = B.ps_ID    
	[JOIN]
	 WHERE b.ps_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]

	UNION ALL
	SELECT [layout_col_2], [CALCULATIVE_COL_2]   
	 from [DATABASE].dbo.ind01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.inm01106 B WITH(NOLOCK) ON A.inv_ID = B.inv_ID   
	 JOIN [DATABASE].dbo.WPS_MST C WITH(NOLOCK) ON b.inv_id=c.wsl_inv_id   AND a.ps_id=c.ps_id 
	 	  
	[JOIN_2]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0  AND ISNULL(PENDING_GIT,0)=0 AND c.cancelled=0  AND [WHERE_2]	 
	group by [GROUPBY_2]' AS base_expr

		---- Net Debit note Pack Slip Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'PENDING_RPS_QTY' as master_col,'left(b.cm_id,2)' as loc_join_col,
	   'a.bin_id' as bin_join_col,'''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.ps_no' as xn_no_col,
	   'b.cm_dt' as xn_dt_col,'[LAYOUT_COL], [CALCULATIVE_COL]   
	   FROM [DATABASE].dbo.RPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RPS_MST B (NOLOCK) ON A.CM_ID = B.CM_ID    
	 LEFT OUTER JOIN [DATABASE].dbo.cmm01106 c (NOLOCK) ON c.cm_id=b.ref_cm_id
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND
	 ISNULL(c.cm_dt,'''')<=[DTODT] AND [WHERE]    
	group by [GROUPBY]' as base_expr

	---- Net Debit note Pack Slip Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,
	  xnparty_join_col_2,
	  XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'PENDING_DNPS_QTY' as master_col,'left(b.ps_id,2)' as loc_join_col,'left(b.rm_id,2)' as loc_join_col_2,
	   'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	   '''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'b.ps_no' as xn_no_col,'b.rm_no' as xn_no_col_2,
	   'b.ps_dt' as xn_dt_col,'b.rm_dt' as xn_dt_col_2,'
	   [LAYOUT_COL], [CALCULATIVE_COL]   
	   FROM [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]
	
	UNION ALL
	SELECT [LAYOUT_COL_2],[CALCULATIVE_COL_2]
	 from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID 
	 JOIN  [DATABASE].dbo.dnps_mst C ON A.PS_ID =C.PS_ID    
	[JOIN_2]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(c.prt_rm_id,'''')<>''''
	  AND [WHERE_2]    
	group by [GROUPBY_2]' AS base_expr
	
	---- Net Credit note Pack Slip Qty  --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,
	  xnparty_join_col_2,
	  XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'PENDING_CNPS_QTY' as master_col,'left(b.ps_id,2)' as loc_join_col,'left(b.cn_id,2)' as loc_join_col_2,
	   'a.bin_id' as bin_join_col,'a.bin_id' as bin_join_col_2,
	   '''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'b.ps_no' as xn_no_col,'b.cn_no' as xn_no_col_2,
	   'b.ps_dt' as xn_dt_col,'b.cn_dt' as xn_dt_col_2,'
	   [LAYOUT_COL],[CALCULATIVE_COL]    
	 FROM [DATABASE].dbo.CNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]
	
	UNION ALL
	SELECT [LAYOUT_COL_2],[CALCULATIVE_COL_2]
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID 
	 JOIN  [DATABASE].dbo.cnps_mst C ON A.ps_id =C.ps_id    
	[JOIN_2]
	 WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(A.PS_ID,'''')<>''''
	  AND [WHERE_2]    
	group by [GROUPBY_2]' AS base_expr
					     
	 --WHOLESALE CREDIT NOTE    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'ops_qty' as master_col,'LEFT(B.CN_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.cn_no' as xn_no_col,'b.cn_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(quantity) AS  Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM, SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	   ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND ((MODE=2 AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT] and b.receipt_Dt<>'''') OR (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT]))
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'ops_qty_pmt_comp' as master_col,'billed_from_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cn_no' as xn_no_col,'b.cn_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(quantity) AS  Obs
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.billed_from_dept_id
	[JOIN]
	 WHERE ((MODE=2 AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT] and b.receipt_Dt<>'''') OR (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT]))
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'ops_qty_pmt_build' as master_col,'billed_from_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.cn_no' as xn_no_col,'b.cn_dt' as xn_dt_col,'[LAYOUT_COL],    
	SUM(quantity) AS  Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID  
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=b.billed_from_dept_id
	[JOIN]
	 WHERE ((MODE=2 AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT] and b.receipt_Dt<>'''') OR (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT]))
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'WSR_QTY' as master_col,'LEFT(B.CN_ID,2)' as loc_join_col,'b.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.cn_no' as xn_no_col,'b.cn_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
 --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,xnparty_join_col_2,
	XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	SELECT 'NET_WSL_QTY' as master_col,'left(b.inv_id,2)' as loc_join_col,'LEFT(B.CN_ID,2)' as loc_join_col_2,
	'a.bin_id' as bin_join_col,'b.bin_id' as bin_join_col_2,
	'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'b.inv_no' as XN_NO_COL,'b.inv_dt' as XN_DT_COL,
	'b.cn_no' as XN_NO_COL_2,'b.cn_dt' as XN_DT_COL_2,'[layout_col],[CALCULATIVE_COL]     
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    	
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND b.inv_mode=1 AND ISNULL(bin_transfer,0)<>1
	  AND [WHERE]
	group by [GROUPBY]

	UNION ALL
	SELECT [layout_col_2],[CALCULATIVE_COL_2]    
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    	
	[JOIN_2]
	 WHERE (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE_2]    
	group by [GROUPBY_2] ' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CNM01106_INCL ON [dbo].[cnm01106] ([cancelled],[CN_TYPE]) INCLUDE ([cn_id],[billed_from_dept_id],[mode],[receipt_dt],[BIN_TRANSFER],[cn_no],[cn_dt],[ac_code])
	 SELECT 'CHI_QTY' as master_col,'LEFT(B.CN_ID,2)' as loc_join_col,'b.bin_id' as bin_join_col,
	 '''LM''+B.AC_CODE' as xnparty_join_col,'b.cn_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    

	[JOIN]
	 WHERE (B.MODE=2 AND b.receipt_dt BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1) and A.bin_id <> ''999''
	 
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	    
	 -- GENERATION OF NEW BAR CODES IN RATE REVISION    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,xn_no_col,xn_dt_col,base_expr,product_code_col)     
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'''' as xnparty_join_col,'b.irm_memo_no' as xn_no_col,
	  'b.IRM_MEMO_DT' as xn_dt_col,'[LAYOUT_COL], SUM(A.QUANTITY) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,
	  SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM, SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	   ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)
	[JOIN]
	 WHERE b.bin_id  <> ''999'' AND b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]
	 and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE]
	group by [GROUPBY]' AS base_expr,'new_product_code' as product_code_col

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,xn_no_col,xn_dt_col,base_expr,product_code_col)     
	SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'''' as xnparty_join_col,'b.irm_memo_no' as xn_no_col,
	  'b.IRM_MEMO_DT' as xn_dt_col,'[LAYOUT_COL], SUM(A.QUANTITY) AS  Obs
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]
	 and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE]
	' AS base_expr,'new_product_code' as product_code_col

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,xn_no_col,xn_dt_col,base_expr,product_code_col)     
	SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'b.bin_id' as bin_join_col,'''' as xnparty_join_col,'b.irm_memo_no' as xn_no_col,
	  'b.IRM_MEMO_DT' as xn_dt_col,'[LAYOUT_COL], SUM(A.QUANTITY) AS  Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]
	 and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE]
	group by [GROUPBY]' AS base_expr,'new_product_code' as product_code_col

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,xn_dt_col,base_expr,product_code_col)     
	  SELECT 'PFI_QTY' as master_col,'left(b.irm_memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''' as xnparty_join_col,'b.irm_memo_no' as xn_no_col,'b.irm_memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]  
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT]
	 and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE]
	group by [GROUPBY]' AS base_expr,'new_product_code' as product_code_col

	    
	 -- GENERATION OF NEW BAR CODES IN SPLIT/COMBINE(OLD)
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,
	  'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],   SUM(A.QUANTITY) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM, SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	   ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 
	 from [DATABASE].dbo.SCF01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,
	  'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],   SUM(A.QUANTITY) AS  Obs
	 
	 from [DATABASE].dbo.SCF01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,
	  'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],   SUM(A.QUANTITY) AS  Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 
	 from [DATABASE].dbo.SCF01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'SCF_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'''000''' as bin_join_col,
	  '''' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	   	 
	 from [DATABASE].dbo.SCF01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr
	    
	 -- CONSUMPTION OF OLD BARCODES IN RATE REVISION     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   --(-1) avilable inside   
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.irm_memo_no' as xn_no_col,'b.irm_memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY)*-1 AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM, SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD
	   ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))* -1 as OBXPWG
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)  
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT] and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND  [WHERE] 
	group by [GROUPBY]' AS base_expr
	
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   --(-1) avilable inside   
	  SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.irm_memo_no' as xn_no_col,'b.irm_memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)  
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT] and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND  [WHERE] 
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   --(-1) avilable inside   
	  SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'a.bin_id' as bin_join_col,'b.irm_memo_no' as xn_no_col,'b.irm_memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY)*-1 AS  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID 
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.irm_Memo_ID,2)  
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT] and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND  [WHERE] 
	group by [GROUPBY]' AS base_expr
	

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'CIP_QTY' as master_col,'left(b.irm_memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''' as xnparty_join_col,'b.irm_memo_no' as xn_no_col,'b.irm_memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	  from [DATABASE].dbo.IRD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.IRM01106 B (NOLOCK) ON A.IRM_MEMO_ID = B.IRM_MEMO_ID   
	[JOIN]
	 WHERE b.IRM_MEMO_DT BETWEEN [DFROMDT] AND [DTODT] and ISNULL(A.NEW_PRODUCT_CODE,'''')<>'''' AND [WHERE] 
	group by [GROUPBY]' AS base_expr
	    
 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY+ADJ_QUANTITY)*-1 AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,
	  SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.lc)*-1 as OBLC,SUM((A.QUANTITY+ADJ_QUANTITY)*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM((A.QUANTITY+ADJ_QUANTITY)*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.pp)*-1 as OBP1,
	   SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.ws_price)*-1 as OBW,
	   SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.mrp)*-1 as OBM,
	    SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.PP_WO_DP)*-1 as OBPWD,
		SUM((A.QUANTITY+ADJ_QUANTITY)*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	
	  
	 from [DATABASE].dbo.SCC01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)  
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_comp' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY+ADJ_QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.SCC01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)  
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_build' as master_col,'loc.major_dept_id' as loc_join_col,'''000''' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],
	  SUM(A.QUANTITY+ADJ_QUANTITY)*-1 AS  Obs,SUM((A.QUANTITY+ADJ_QUANTITY)*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.SCC01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(B.Memo_ID,2)  
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'SCC_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'''000''' as bin_join_col,
	  '''' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.SCC01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SCM01106 B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]
	group by [GROUPBY]' AS base_expr
	                                                                    
    
	
	 -- OPS JOB WORK ISSUE     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,xnparty_join_col,base_expr)     
	  SELECT 'JWI_QTY_OPS' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'''LM''+D.AC_CODE' as xnparty_join_col,'[LAYOUT_COL],
		  SUM(A.QUANTITY) *-1 AS  OPSNNJWQ,SUM(a.quantity*sku_names.pp)*-1 as OPSPENNJWP
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE b.ISSUE_DT < [DFROMDT]   AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	 group by [GROUPBY]' AS base_expr
	
	
	
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,xnparty_join_col,base_expr)     
	  SELECT 'JWI_QTY_OPS' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  'b.receipt_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'''LM''+pa.AC_CODE' as xnparty_join_col,'[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  OPSNNJWQ,SUM(D.quantity*sku_names.pp) as OPSPENNJWP	  
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST pa (NOLOCK) ON pa.AGENCY_CODE=e.AGENCY_CODE    
	 [JOIN]
	 WHERE b.RECEIPT_DT < [DFROMDT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	group by [GROUPBY]' AS base_expr
	
	
	 -- CBS JOB WORK ISSUE    --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019 
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,xnparty_join_col,base_expr)     --(-1) avilable inside 
	  SELECT 'JWI_QTY_CBS' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'''LM''+D.AC_CODE' as xnparty_join_col,'[LAYOUT_COL],
		  SUM(A.QUANTITY) *-1 AS  PENNJWQ,SUM(a.quantity*sku_names.pp)*-1 as PENVJWP
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE b.ISSUE_DT <= [DTODT]   AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	 group by [GROUPBY]' AS base_expr
	
	
	
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,xnparty_join_col,base_expr)     
	  SELECT 'JWI_QTY_CBS' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  'b.receipt_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'''LM''+pa.AC_CODE' as xnparty_join_col,'[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  PENNJWQ,SUM(D.quantity*sku_names.pp) as PENNJWP		    
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST pa (NOLOCK) ON pa.AGENCY_CODE=e.AGENCY_CODE    
	 [JOIN]
	 WHERE b.RECEIPT_DT <= [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	group by [GROUPBY]' AS base_expr
	
	
	
	
	      
	 -- JOB WORK ISSUE     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside     
	  SELECT 'ops_qty' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],
		  SUM(A.QUANTITY) *-1 AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,  SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD
	   	,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside     
	  SELECT 'ops_qty_pmt_comp' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],
		  SUM(A.QUANTITY) *-1 AS  Obs
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	 WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr) --(-1) avilable inside     
	  SELECT 'ops_qty_pmt_build' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],
		  SUM(A.QUANTITY) *-1 AS  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	 WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	group by [GROUPBY]' AS base_expr

	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     --(-1) avilable inside 
	  SELECT 'JWI_QTY' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''LM''+D.AC_CODE' as xnparty_join_col,'b.issue_no' as xn_no_col,'b.issue_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]  
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	group by [GROUPBY]' AS base_expr
	     
	 -- JOB WORK RECEIPT    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  'b.receipt_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,SUM(D.quantity*sku_names.lc) as OBLC,SUM(D.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(D.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(D.quantity*sku_names.pp) as OBP1,
	   SUM(D.quantity*sku_names.ws_price) as OBW,
	   SUM(D.quantity*sku_names.mrp) as OBM,  SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	 ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST pa (NOLOCK) ON pa.AGENCY_CODE=e.AGENCY_CODE    
	 [JOIN]
	 WHERE D.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_comp' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  'b.receipt_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  Obs
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.receipt_id,2)
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	  SELECT 'ops_qty_pmt_build' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  'b.receipt_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(D.QUANTITY) AS  Obs,SUM(D.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.receipt_id,2)
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     --(-1) avilable inside 
	  SELECT 'JWR_QTY' as master_col,'left(b.receipt_id,2)' as loc_join_col,'d.bin_id' as bin_join_col,
	  '''LM''+pa.AC_CODE' as xnparty_join_col,'b.receipt_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL] 
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST pa (NOLOCK) ON pa.AGENCY_CODE=E.AGENCY_CODE    
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE] 
	group by [GROUPBY]' AS base_expr

 --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,xnparty_join_col_2,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)     --(-1) avilable inside 
	  SELECT 'PENDINGT_JWI_QTY' as master_col,'left(b.issue_id,2)' as loc_join_col,'left(b.receipt_id,2)' as loc_join_col_2,
	  'a.bin_id' as bin_join_col,'d.bin_id' as bin_join_col_2,
	  '''LM''+d.AC_CODE' as xnparty_join_col,'''LM''+f.AC_CODE' as xnparty_join_col_2,'b.issue_no' as XN_NO_COL,'b.issue_dt' as XN_DT_COL,'b.receipt_no' as XN_NO_COL,
	  'b.receipt_dt' as XN_DT_COL,'[layout_col],[CALCULATIVE_COL]  
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	group by [GROUPBY]

	union all
	SELECT [layout_col_2],[CALCULATIVE_COL_2] 
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST f (NOLOCK) ON f.AGENCY_CODE=b.AGENCY_CODE 
	 [JOIN_2]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE_2] 
	group by [GROUPBY_2]' AS base_expr





	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,xnparty_join_col_2,XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)     --(-1) avilable inside 
	  SELECT 'NET_JWI_QTY' as master_col,'left(b.issue_id,2)' as loc_join_col,'left(b.receipt_id,2)' as loc_join_col_2,
	  'a.bin_id' as bin_join_col,'d.bin_id' as bin_join_col_2,
	  '''LM''+d.AC_CODE' as xnparty_join_col,'''LM''+f.AC_CODE' as xnparty_join_col_2,'b.issue_no' as XN_NO_COL,'b.issue_dt' as XN_DT_COL,'b.receipt_no' as XN_NO_COL,
	  'b.receipt_dt' as XN_DT_COL,'[layout_col],[CALCULATIVE_COL]  
	 from [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE    
	[JOIN]
	 WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0    
	  AND B.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0 
	 AND ISNULL(B.ISSUE_MODE,0)<>1 AND [WHERE]  
	group by [GROUPBY]

	union all
	SELECT [layout_col_2],[CALCULATIVE_COL_2] 
	 from [DATABASE].dbo.JOBWORK_RECEIPT_DET D (NOLOCK)    
	 JOIN  [DATABASE].dbo.JOBWORK_RECEIPT_MST B (NOLOCK) ON D.RECEIPT_ID = B.RECEIPT_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_DET A (NOLOCK) ON A.ROW_ID=D.REF_ROW_ID    
	 JOIN  [DATABASE].dbo.JOBWORK_ISSUE_MST E (NOLOCK) ON E.ISSUE_ID = A.ISSUE_ID    
	 JOIN  [DATABASE].dbo.PRD_AGENCY_MST f (NOLOCK) ON f.AGENCY_CODE=b.AGENCY_CODE 
	 [JOIN_2]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	 AND E.ISSUE_TYPE=1  AND ISNULL(B.WIP,0)=0  AND ISNULL(B.RECEIVE_MODE,0)<>1 AND [WHERE_2] 
	group by [GROUPBY_2]' AS base_expr


	    
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'ops_qty' as master_col,'left(b.memo_id,2)' as loc_join_col,'b2.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL],    
	 SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  ) AS Obs_CNT,
	 SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.lc) as OBLC,
	 SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.pp) as OBP1,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.ws_price) as OBW,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.mrp) as OBM,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.PP_WO_DP) as OBPWD
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
	 WHERE b2.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND B.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'ops_qty_pmt_comp' as master_col,'left(b.memo_id,2)' as loc_join_col,'b2.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL],    
	 SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END) AS  Obs
	 from [DATABASE].dbo.SNC_DET B2 (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON B2.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	 JOIN  
	 (  
	 SELECT REFROW_ID AS [ROW_ID],PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]  
	 from [DATABASE].dbo.SNC_BARCODE_DET (NOLOCK)  
	 GROUP BY REFROW_ID,PRODUCT_CODE  
	 )A ON B2.ROW_ID = A.ROW_ID  
	 JOIN  [DATABASE].dbo.SKU S1(NOLOCK) ON S1.product_code=a.PRODUCT_CODE 
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND B.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 ' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'ops_qty_pmt_build' as master_col,'left(b.memo_id,2)' as loc_join_col,'b2.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL],    
	 SUM(CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END) AS  Obs,
	   SUM((CASE WHEN S1.BARCODE_CODING_SCHEME=3 THEN a.TOTAL_QTY ELSE b2.QUANTITY END)*sku_names.pp) as OBP1
	 from [DATABASE].dbo.SNC_DET B2 (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON B2.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	 JOIN  
	 (  
	 SELECT REFROW_ID AS [ROW_ID],PRODUCT_CODE,COUNT(*) AS [TOTAL_QTY]  
	 from [DATABASE].dbo.SNC_BARCODE_DET (NOLOCK)  
	 GROUP BY REFROW_ID,PRODUCT_CODE  
	 )A ON B2.ROW_ID = A.ROW_ID  
	 JOIN  [DATABASE].dbo.SKU S1(NOLOCK) ON S1.product_code=a.PRODUCT_CODE 
	 [JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND B.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 group by [GROUPBY]' AS base_expr

	   
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)   
	 -- FINISHED BARCODES IN SPLIT/COMBINE NEW(SCF : SPLIT COMBILE FINISHED)  
	  SELECT 'SCF_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'b2.bin_id' as bin_join_col,
	  '''LM''+pa.AC_CODE' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL_2]    
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
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND B.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]    
	 group by [GROUPBY]' AS base_expr


	  
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)      --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)    
	  SELECT 'ops_qty' as master_col,'left(b.memo_id,2)' as loc_join_col,'isnull(a.bin_id,''000'')' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(A.QUANTITY)*-1 AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM,  SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD
	  ,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 from [DATABASE].dbo.SNC_CONSUMABLE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]   
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)      --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)    
	  SELECT 'ops_qty_pmt_comp' as master_col,'left(b.memo_id,2)' as loc_join_col,'isnull(a.bin_id,''000'')' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(A.QUANTITY)*-1 AS  Obs
	 from [DATABASE].dbo.SNC_CONSUMABLE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]   
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)      --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)    
	  SELECT 'ops_qty_pmt_build' as master_col,'left(b.memo_id,2)' as loc_join_col,'isnull(a.bin_id,''000'')' as bin_join_col,'b.memo_no' as xn_no_col,'b.RECEIPT_DT' as xn_dt_col,'[LAYOUT_COL], 
	  SUM(A.QUANTITY)*-1 AS  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 from [DATABASE].dbo.SNC_CONSUMABLE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.memo_id,2)
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]   
	group by [GROUPBY]' AS base_expr
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)     
	 -- CONSUMPTION OF BARCODES IN SPLIT/COMBINE NEW(SCC : SPLIT COMBILE CONSUMPTION)    
	  SELECT 'SCC_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'isnull(a.bin_id,''000'')' as bin_join_col,
	  '''LM''+B.AC_CODE' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.receipt_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL_2]  
	 from [DATABASE].dbo.SNC_CONSUMABLE_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.SNC_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.RECEIPT_DT BETWEEN [DFROMDT] AND [DTODT]  AND A.WIP=0 AND B.CANCELLED=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]   
	group by [GROUPBY]' AS base_expr
	 
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  
	 SELECT 'ops_qty' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL], 
	 SUM(A.QUANTITY) AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM ,  SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	   	,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	   
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	 
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  
	 SELECT 'ops_qty_pmt_build' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL], 
	 SUM(A.QUANTITY) AS  Obs,SUM(a.quantity*sku_names.pp) as OBP1	   
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(A.MEMO_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)  
	 SELECT 'ops_qty_pmt_comp' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL], 
	 SUM(A.QUANTITY) AS  Obs	   
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID   
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(A.MEMO_ID,2)
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr


	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)  
	 SELECT 'TTM_QTY' as master_col,'left(b.memo_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''LM''+a.AC_CODE' as xnparty_join_col,'b.memo_no' as xn_no_col,'b.memo_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.TRANSFER_TO_TRADING_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.TRANSFER_TO_TRADING_MST B (NOLOCK) ON A.MEMO_ID = B.MEMO_ID    
	[JOIN]
	 WHERE b.memo_dt BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND A.PRODUCT_CODE<>'''' AND [WHERE]            
	group by [GROUPBY]' AS base_expr

	 --DEBITNOTE PACKSLIP     --(-1) avilable inside CHANGES MADE BY CHANDAN ON 24-06-2019
	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty' as master_col,'left(b.ps_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.ps_no' as xn_no_col,'b.PS_DT' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS  Obs,COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  )*-1 AS OBS_CNT,SUM(a.quantity*sku_names.lc)*-1 as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE))*-1 as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE))*-1 as OBXPC,SUM(a.quantity*sku_names.pp)*-1 as OBP1,SUM(a.quantity*sku_names.ws_price)*-1 as OBW,
	   SUM(a.quantity*sku_names.mrp)*-1 as OBM ,  SUM(a.quantity*sku_names.PP_WO_DP)*-1 as OBPWD
	   	,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst))*-1 as OBXPWG
	 
	 from [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE  a.bin_id  <> ''999'' AND b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty_pmt_comp' as master_col,'left(b.ps_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.ps_no' as xn_no_col,'b.PS_DT' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS  Obs
	 
	 from [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.ps_id,2)
	[JOIN]
	 WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'ops_qty_pmt_build' as master_col,'left(b.ps_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.ps_no' as xn_no_col,'b.PS_DT' as xn_dt_col,'[LAYOUT_COL],    
	sum(A.QUANTITY)*-1 AS  Obs,SUM(a.quantity*sku_names.pp)*-1 as OBP1
	 
	 from [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.ps_id,2)
	[JOIN]
	 WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	  SELECT 'DNPI_QTY' as master_col,'left(b.ps_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	  '''LM''+B.AC_CODE' as xnparty_join_col,'b.ps_no' as xn_no_col,'b.ps_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.DNPS_DET A (NOLOCK)    
	 JOIN  [DATABASE].dbo.DNPS_MST B (NOLOCK) ON A.PS_ID = B.PS_ID    
	[JOIN]
	 WHERE b.PS_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	  --ADD NEW FOR PACKSLIP RETURN
	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'ops_qty' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.RM_DT' as xn_dt_col,'[LAYOUT_COL], 
		SUM(A.QUANTITY) AS  Obs,COUNT(DISTINCT  SKU_NAMES.PRODUCT_CODE ) AS OBS_CNT,SUM(a.quantity*sku_names.lc) as OBLC,SUM(a.quantity*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM(a.quantity*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,SUM(a.quantity*sku_names.pp) as OBP1,SUM(a.quantity*sku_names.ws_price) as OBW,
	   SUM(a.quantity*sku_names.mrp) as OBM,  SUM(a.quantity*sku_names.PP_WO_DP) as OBPWD
	   	,SUM(a.quantity*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
	 from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID 
	 JOIN  [DATABASE].dbo.dnps_mst C ON A.PS_ID =C.PS_ID    
	[JOIN]
	 WHERE a.bin_id  <> ''999'' AND b.RM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(c.prt_rm_id,'''')<>''''
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])



	   SELECT 'ops_qty_pmt_comp' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.RM_DT' as xn_dt_col,'[LAYOUT_COL], 
		SUM(A.QUANTITY) AS  Obs
	 from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID 
	 JOIN  [DATABASE].dbo.dnps_mst C ON A.ps_id =C.ps_id    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.rm_id,2)
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(A.PS_ID,'''')<>''''
	  AND [WHERE]    
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'ops_qty_pmt_build' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.rm_no' as xn_no_col,'b.RM_DT' as xn_dt_col,'[LAYOUT_COL], 
		SUM(A.QUANTITY) AS  Obs,SUM(a.quantity*sku_names.pp) as OBP1
	 from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID 
	 JOIN  [DATABASE].dbo.dnps_mst C ON A.ps_id =C.ps_id    
	 JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.rm_id,2)
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(A.PS_ID,'''')<>''''
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr

	  INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	  --CREATE NONCLUSTERED INDEX IX_PSID_RMD_INCL ON [dbo].[rmd01106] ([PS_ID]) INCLUDE ([product_code],[quantity],[rm_id],[RFNET],[item_tax_amount],[BIN_ID])
	   SELECT 'DNPR_QTY' as master_col,'left(b.rm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	   '''LM''+B.AC_CODE' as xnparty_join_col,'b.rm_no' as xn_no_col,'b.rm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]
	 from [DATABASE].dbo.RMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.RMM01106 B (NOLOCK) ON A.RM_ID = B.RM_ID 
	 JOIN  [DATABASE].dbo.dnps_mst C ON A.PS_ID =C.PS_ID    
	[JOIN]
	 WHERE b.RM_DT BETWEEN [DFROMDT] AND [DTODT] AND b.cancelled=0 AND ISNULL(c.prt_rm_id,'''')<>''''
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	   SELECT 'ops_qty' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM(CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end) as  Obs,
	COUNT(DISTINCT   SKU_NAMES.PRODUCT_CODE  ) AS OBS_CNT,
	SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.lc) as OBLC,
	SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*(SKU_XFP.XFER_PRICE)) as OBXP,
	   SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*(SKU_XFP.CURRENT_XFER_PRICE)) as OBXPC,
	   SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.pp) as OBP1,
	   SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.ws_price) as OBW,
	   SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.mrp) as OBM,
	      SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.PP_WO_DP) as OBPWD,
		  SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*(SKU_XFP.xfer_price_without_gst)) as OBXPWG
		   
	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	[JOIN]
	  WHERE a.bin_id  <> ''999'' AND b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]     
	group by [GROUPBY]' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	   SELECT 'ops_qty_pmt_comp' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM(CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end) as  Obs
	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	  JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	  WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]     
	' AS base_expr

	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	   SELECT 'ops_qty_pmt_build' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,'b.issue_no' as xn_no_col,'b.ISSUE_DT' as xn_dt_col,'[LAYOUT_COL],    
	SUM(CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end) as  Obs,
	 SUM((CASE WHEN ISNULL(B.ISSUE_TYPE,0)<>0 THEN a.STOCK_QTY else -A.STOCK_QTY end)*sku_names.pp) as OBP1
	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	  JOIN [DATABASE].dbo.location LOc (NOLOCK) ON loc.dept_id=left(b.issue_id,2)
	[JOIN]
	  WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND [WHERE]     
	group by [GROUPBY]' AS base_expr
	
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	   SELECT 'MIS_QTY' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	   '''LM''+D.AC_CODE' as xnparty_join_col,'b.issue_no' as xn_no_col,'b.issue_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
 	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	[JOIN]
	  WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	  AND ISNULL(B.ISSUE_TYPE,0)=0 AND [WHERE]     
	  
	group by [GROUPBY]' AS base_expr

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)
	   SELECT 'MIR_QTY' as master_col,'left(b.issue_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	   '''LM''+D.AC_CODE' as xnparty_join_col,'b.issue_no' as xn_no_col,'b.issue_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	  from [DATABASE].dbo.BOM_ISSUE_DET A (NOLOCK)  
	  JOIN  [DATABASE].dbo.BOM_ISSUE_MST B (NOLOCK) ON A.ISSUE_ID = B.ISSUE_ID  
	  JOIN  [DATABASE].dbo.PRD_AGENCY_MST D (NOLOCK) ON D.AGENCY_CODE=B.AGENCY_CODE  
	[JOIN]
	  WHERE b.ISSUE_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 AND ISNULL(B.ISSUE_TYPE,0)<>0 AND [WHERE]     
	group by [GROUPBY]' AS base_expr
	
	--WSL xtreme_reports_exp_olap ADDED BY CHANDAN ON 26-06-2019

	--WTD_wsl
		
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'WTD_WSL' as master_col,'left(b.INV_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.INV_no' as xn_no_col,'b.INV_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND inv_mode=1 AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	--MTD_WSL
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'MTD_WSL' as master_col,'left(b.INV_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.INV_NO' as xn_no_col,'b.INV_DT' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND inv_mode=1 AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	
		--YTD_WSL
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'YTD_WSL' as master_col,'left(b.INV_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.INV_NO' as xn_no_col,'b.INV_DT' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.IND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B (NOLOCK) ON A.INV_ID = B.INV_ID    
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND inv_mode=1 AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	--WSR xtreme_reports_exp_olap ADDED BY CHANDAN ON 26-06-2019

	--WTD_WSR
	
	
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'WTD_WSR' as master_col,'left(b.CN_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.CN_no' as xn_no_col,'b.CN_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]        
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	--MTD_WSR
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'MTD_WSR' as master_col,'left(b.CN_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.CN_NO' as xn_no_col,'b.CN_DT' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	
		--YTD_WSR
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)    
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'YTD_WSR' as master_col,'left(b.CN_ID,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.CN_NO' as xn_no_col,'b.CN_DT' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    
	[JOIN]
	 WHERE b.CN_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	

	 INSERT xtreme_reports_exp_olap (master_col,loc_join_col,bin_join_col,xnparty_join_col,XN_NO_COL,XN_DT_COL,base_expr)   
	 --CREATE NONCLUSTERED INDEX IX_CAN_CMM_INCL ON [dbo].[cmm01106] ([CANCELLED]) INCLUDE ([CM_NO],[CM_DT],[DISCOUNT_PERCENTAGE],[CUSTOMER_CODE],[cm_id])
	 SELECT 'NET_SLS_WSL_QTY' as master_col,'left(b.cm_id,2)' as loc_join_col,'a.bin_id' as bin_join_col,
	 '''CUS''+B.CUSTOMER_CODE' as xnparty_join_col,'b.cm_no' as xn_no_col,'b.cm_dt' as xn_dt_col,'[LAYOUT_COL],[CALCULATIVE_COL]    
	 from [DATABASE].dbo.CMD01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CMM01106 B (NOLOCK) ON A.CM_ID = B.CM_ID  
	
	[JOIN]
	 WHERE b.CM_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0
	  AND [WHERE]    
	group by [GROUPBY]' AS base_expr
	
	
	
	
	
	
	INSERT xtreme_reports_exp_olap (master_col,loc_join_col,loc_join_col_2,bin_join_col,bin_join_col_2,xnparty_join_col,xnparty_join_col_2,
	XN_NO_COL,XN_DT_COL,XN_NO_COL_2,XN_DT_COL_2,base_expr)    
	SELECT 'NET_SLS_WSL_QTY' as master_col,'left(b.inv_id,2)' as loc_join_col,'LEFT(B.CN_ID,2)' as loc_join_col_2,
	'a.bin_id' as bin_join_col,'b.bin_id' as bin_join_col_2,
	'''LM''+B.AC_CODE' as xnparty_join_col,'''LM''+B.AC_CODE' as xnparty_join_col_2,'b.inv_no' as XN_NO_COL,'b.inv_dt' as XN_DT_COL,
	'b.cn_no' as XN_NO_COL_2,'b.cn_dt' as XN_DT_COL_2,'[layout_col],[CALCULATIVE_COL_2]    
	 from [DATABASE].dbo.IND01106 A WITH(NOLOCK)    
	 JOIN  [DATABASE].dbo.INM01106 B WITH(NOLOCK) ON A.INV_ID = B.INV_ID    	
	[JOIN]
	 WHERE b.INV_DT BETWEEN [DFROMDT] AND [DTODT]  AND b.cancelled=0 
	 AND b.inv_mode=1 AND ISNULL(bin_transfer,0)<>1
	   AND [WHERE]
	group by [GROUPBY]

	UNION ALL
	SELECT [layout_col_2],[CALCULATIVE_COL_3]     
	 from [DATABASE].dbo.CND01106 A (NOLOCK)    
	 JOIN  [DATABASE].dbo.CNM01106 B (NOLOCK) ON A.CN_ID = B.CN_ID    	
	[JOIN_2]
	 WHERE (MODE=1 AND b.cn_dt BETWEEN [DFROMDT] AND [DTODT])
	  AND b.cancelled=0 AND isnull(B.CN_TYPE,0) in (0,1)
	  AND [WHERE_2]    
	group by [GROUPBY_2] ' AS base_expr
	
	
END
--***************** END OF CREATING PROCEDURE SP3S_Reporting_expressions





