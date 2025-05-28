CREATE PROCEDURE SP3S_BUILD_XPERTPENDENCY_EXPRESSIONS
AS

BEGIN


	SELECT * INTO #transaction_pending_calculative_COLS FROM transaction_analysis_calculative_COLS	
	WHERE 1=2

	SELECT * INTO #transaction_pending_master_COLS FROM  transaction_analysis_master_COLS	
	WHERE 1=2
	
	DELETE from transaction_PENDING_expr  

	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Purchase Order Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.POD01106 A (NOLOCK)    
	JOIN  [DATABASE].dbo.POM01106 B (NOLOCK) ON A.Po_id = B.Po_id    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.po_dt BETWEEN [DFROMDT] AND [DTODT]  
	AND quantity-pi_qty-adj_quantity>0 AND ISNULL(short_close,0)=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Buyer Order Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.BUYER_ORDER_DET A (NOLOCK)    
	JOIN [DATABASE].dbo.BUYER_ORDER_MST B (NOLOCK) ON A.order_id = B.order_id    
	JOIN location sl (NOLOCK) ON sl.dept_id=b.dept_id
	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=b.ac_code
	[JOIN]
	WHERE b.order_dt between [dfromdt] and [DTODT]  
	AND quantity-inv_qty-adj_qty>0  AND ISNULL(short_close,0)=0 AND [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'GIT' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[GITTABLE] A (NOLOCK)  	
	JOIN location sl (NOLOCK) ON sl.dept_id=RIGHT(A.xn_party_code,2)
	JOIN location Tl (NOLOCK) ON tl.dept_id=A.dept_id	
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr

	
	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[WPSTABLE] A (NOLOCK)  	
	Left outer Join wps_mst  b  (NOLOCK)  on A.memo_id= b.ps_id
	Left outer JOIN Loc_view sl (NOLOCK) ON sl.dept_id=RIGHT(A.xn_party_code,2)	
	Left outer JOIN lmv01106 lm (NOLOCK) ON lm.ac_code=RIGHT(A.xn_party_code,10)
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Approval Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[APPTABLE] A (NOLOCK)  			
	Left outer JOIN cust_attr_names CUS (NOLOCK) ON CUS.customer_code=RIGHT(A.xn_party_code,12)
	Left outer JOIN lmv01106 lm (NOLOCK) ON lm.ac_code=RIGHT(A.xn_party_code,10)	
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr


	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[RPSTABLE] A (NOLOCK)  			
	Left outer JOIN cust_attr_names CUS (NOLOCK) ON CUS.customer_code=RIGHT(A.xn_party_code,12)
	Left outer JOIN lmv01106 lm (NOLOCK) ON lm.ac_code=RIGHT(A.xn_party_code,10)
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr



	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[DNPSTABLE] A (NOLOCK)  	
	Left outer JOIN Loc_view sl (NOLOCK) ON sl.dept_id=RIGHT(A.xn_party_code,2)	
	Left outer JOIN lmv01106 lm (NOLOCK) ON lm.ac_code=RIGHT(A.xn_party_code,10)
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr

	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[CNPSTABLE] A (NOLOCK)  	
	Left outer JOIN Loc_view sl (NOLOCK) ON sl.dept_id=RIGHT(A.xn_party_code,2)	
	Left outer JOIN lmv01106 lm (NOLOCK) ON lm.ac_code=RIGHT(A.xn_party_code,10)
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr


	

	--LOCNAMES
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'b.dept_id' AS keyfield,table_caption AS col_header ,
	'Purchase Order Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'b.dept_id' AS keyfield,table_caption AS col_header ,
	'Buyer Order Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'A.dept_id' AS keyfield,table_caption AS col_header ,
	'GIT' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'A.dept_id' AS keyfield,table_caption AS col_header ,
	'Approval Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'A.dept_id' AS keyfield,table_caption AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'A.dept_id' AS keyfield,table_caption AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'LOC'+column_name as COL_EXPR,'A.dept_id' AS keyfield,table_caption AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'LOC_NAMES' as joining_table,'dept_id' joining_column
	From config_locattr  where table_caption <> ''



	
	--GIT
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Adj Qty' AS col_header 
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty)' as COL_EXPR,'Net Transaction Qty' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Common' xn_type,'0' as COL_EXPR,'Settled Qty' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty)' as COL_EXPR,'Pending Qty' AS col_header 
	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 
	   	
	--WPS	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 		
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 		
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Pending Qty' AS col_header 	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Wholesale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 

	 --Debit Note Pack Slip Pendency
	 INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 		
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 		
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Pending Qty' AS col_header 	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Debit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 

	
	 --Credit Note Pack Slip Pendency
	 INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 		
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 		
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Pending Qty' AS col_header 	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Credit Note Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 

	 --Retail Sale Pack Slip Pendency
	 INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 		
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 		
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Pending Qty' AS col_header 	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Retail Sale Pack Slip Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 


	--Approval Pendency
	 INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 		
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 		
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Pending Qty' AS col_header 	
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Approval Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 
	   	 

	--PO	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.adj_quantity)' as COL_EXPR,'Adj Qty' AS col_header 
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity-a.adj_quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.PI_QTY)' as COL_EXPR,'Settled Qty' AS col_header 


	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.pi_qty)' as COL_EXPR,'Purchase Invoice Qty' AS col_header 
	   
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity-a.adj_quantity-isnull(a.pi_qty,0))' as COL_EXPR,'Pending Qty' AS col_header 
		

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity*sku_names.pp)' as COL_EXPR,'Net Transaction Value at PP' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price_without_gst)' as COL_EXPR,'Net Transaction Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity*sxfp.xfer_price)' as COL_EXPR,'Net Transaction Value at Transfer Price' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity*sku_names.mrp)' as COL_EXPR,'Net Transaction Value at MRP' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Purchase Order Pendency' xn_type,'SUM(a.quantity*sku_names.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 
	   

  --BUYER ORDER

    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.GROSS_QUANTITY)' as COL_EXPR,'Grosss Transaction Qty' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.adj_qty)' as COL_EXPR,'Adj Qty' AS col_header 
		
    INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.quantity)' as COL_EXPR,'Net Transaction Qty' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.inv_qty)' as COL_EXPR,'Settled Qty' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.quantity-isnull(a.inv_qty,0)-isnull(a.adj_qty,0))' as COL_EXPR,'Pending Qty' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.pl_qty)' as COL_EXPR,'PickList Qty' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.po_qty)' as COL_EXPR,'Purchase order Qty (BO)' AS col_header 
		
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.pi_qty)' as COL_EXPR,'Purchase Invoice Qty (BO)' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'COMMON' xn_type,'0' as COL_EXPR,'Purchase Invoice Qty (BO)' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'COMMON' xn_type,'0' as COL_EXPR,'PickList Qty' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'COMMON' xn_type,'0' as COL_EXPR,'Purchase order Qty (BO)' AS col_header 
		   	  		
		

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Buyer Order Pendency' xn_type,'SUM(a.quantity*a.ws_price)' as COL_EXPR,'Net Transaction Value at WSP' AS col_header 
	   


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'article_no' as COL_EXPR,'a.article_code' AS keyfield,'Article no.' AS col_header ,
	'Purchase Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,3



	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1.para1_name' as COL_EXPR,'a.para1_code' AS keyfield,'Para1 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para1' as joining_table,'para1_code' joining_column,5

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2.para2_name' as COL_EXPR,'a.para2_code' AS keyfield,'Para2 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para2' as joining_table,'para2_code' joining_column,6

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3.para3_name' as COL_EXPR,'a.para3_code' AS keyfield,'Para3 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para3' as joining_table,'para3_code' joining_column,7

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4.para4_name' as COL_EXPR,'a.para4_code' AS keyfield,'Para4 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para4' as joining_table,'para4_code' joining_column,8

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5.para5_name' as COL_EXPR,'a.para5_code' AS keyfield,'Para5 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para5' as joining_table,'para5_code' joining_column,9

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6.para6_name' as COL_EXPR,'a.para6_code' AS keyfield,'Para6 name' AS col_header ,
	'Purchase Order Pendency' xn_type,'para6' as joining_table,'para6_code' joining_column,10





	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Purchase Order Pendency' xn_type,'lm01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lm01106.ALIAS' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Purchase Order Pendency' xn_type,'lm01106' as joining_table,'ac_code' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.region_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Region Name' AS col_header ,
	'Purchase Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.state' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Purchase Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'lmv01106.city' as COL_EXPR,'b.ac_code' AS keyfield,'Party city' AS col_header ,
	'Purchase Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column


	   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.PO_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.PO_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.DELIVERY_DT' as COL_EXPR,'' AS keyfield,'Delivery Date' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.ref_no' as COL_EXPR,'' AS keyfield,'Ref No' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
 	
	--1-Direct',2 Buyer Order(Retail) 3-Buyer Order(WSL-FG) 4 Buy Plan 5 Buyer Order(WSL-RM)
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '(CASE WHEN b.entry_mode=1 THEN ''Direct'' WHEN b.entry_mode=2 THEN ''Buyer Order(Retail)'' WHEN b.entry_mode=3 THEN ''Buyer Order(WSL-FG)'' WHEN b.entry_mode=4 THEN ''Buy Plan'' else ''Buyer Order(WSL-RM)'' end)' as COL_EXPR,
	'' AS keyfield,'Against' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.dept_id' as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'b.dept_id' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'Purchase Order Pendency' xn_type,'#loc_view' as joining_table,'dept_id' joining_column,'loc_tl'
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(po_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'oem_name' as COL_EXPR,'b.oem_code' AS keyfield,'OEM (SHIPPING PARTY NAME)' AS col_header ,
	'Purchase Order Pendency' xn_type,'oem_mst' as joining_table,'oem_code' joining_column
		
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.remarks' as COL_EXPR,'' AS keyfield,'Remarks' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Approval PendencyrovedLevelNo' as COL_EXPR,'' AS keyfield,'Approval Pendencyroval Level No.' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.cancelled' as COL_EXPR,'' AS keyfield,'Cancelled' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'b.Short_close' as COL_EXPR,'' AS keyfield,'Close Status' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.gst_percentage' as COL_EXPR,'' AS keyfield,'GST%' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.gross_purchase_price' as COL_EXPR,'' AS keyfield,'Gross Purchase price' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.discount_amount' as COL_EXPR,'' AS keyfield,'Total discount Amount' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.purchase_price' as COL_EXPR,'' AS keyfield,'Net purchase Price' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.MRP' as COL_EXPR,'' AS keyfield,'MRP' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.wholesale_price' as COL_EXPR,'' AS keyfield,'Wholesale Price' AS col_header ,
	'Purchase Order Pendency' xn_type,'' as joining_table,'' joining_column

	--BUYER ORDER MASTER

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'lm01106.ac_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'lm01106' as joining_table,'ac_code' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'lm01106.ALIAS' as COL_EXPR,'b.ac_code' AS keyfield,'Party Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'lm01106' as joining_table,'ac_code' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'lmv01106.region_name' as COL_EXPR,'b.ac_code' AS keyfield,'Party Region Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'lmv01106.state' as COL_EXPR,'b.ac_code' AS keyfield,'Party State' AS col_header ,
	'Buyer Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'lmv01106.city' as COL_EXPR,'b.ac_code' AS keyfield,'Party city' AS col_header ,
	'Buyer Order Pendency' xn_type,'lmv01106' as joining_table,'ac_code' joining_column,'POPEND'
	  
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.ORDER_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.ORDER_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.DELIVERY_DT' as COL_EXPR,'' AS keyfield,'Delivery Date' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.ref_no' as COL_EXPR,'' AS keyfield,'Ref No' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
 	
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT '(CASE WHEN b.memo_type=1 THEN ''Direct'' WHEN b.memo_type=2 THEN ''Pick List)''  else ''Bin Transfer'' end)' as COL_EXPR,
	'' AS keyfield,'Against' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.DEPT_ID' as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias,rep_type)     
	SELECT 'dept_name' as COL_EXPR,'b.DEPT_ID' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'Buyer Order Pendency' xn_type,'#loc_view' as joining_table,'dept_id' joining_column,'loc_tl' joining_table_alias,'POPEND'
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'dbo.FN_GETFINYEARSTR(order_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT '''''' as COL_EXPR,'b.oem_code' AS keyfield,'OEM (SHIPPING PARTY NAME)' AS col_header ,
	'Buyer Order Pendency' xn_type,'oem_mst' as joining_table,'oem_code' joining_column,'POPEND'
		
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.remarks' as COL_EXPR,'' AS keyfield,'Remarks' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.Approval PendencyrovedLevelNo' as COL_EXPR,'' AS keyfield,'Approval Pendencyroval Level No.' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.cancelled' as COL_EXPR,'' AS keyfield,'Cancelled' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.Short_close' as COL_EXPR,'' AS keyfield,'Close Status' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.gst_percentage' as COL_EXPR,'' AS keyfield,'GST%' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.gross_wsp' as COL_EXPR,'' AS keyfield,'Gross Purchase price' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.discount_amount' as COL_EXPR,'' AS keyfield,'Total discount Amount' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.ws_price' as COL_EXPR,'' AS keyfield,'Net purchase Price' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.gross_wsp' as COL_EXPR,'' AS keyfield,'MRP' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'a.gross_wsp' as COL_EXPR,'' AS keyfield,'Wholesale Price' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'
	
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.SHIPPING_FNAME' as COL_EXPR,'' AS keyfield,'Shipping F Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.SHIPPING_LNAME' as COL_EXPR,'' AS keyfield,'Shipping L Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.SHIPPING_MOBILE' as COL_EXPR,'' AS keyfield,'Shipping Mobile' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'



	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_Address' as COL_EXPR,'' AS keyfield,'Shipping Address' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_Address2' as COL_EXPR,'' AS keyfield,'Shipping Address 2' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_Address3' as COL_EXPR,'' AS keyfield,'Shipping Address 3' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_area_name' as COL_EXPR,'' AS keyfield,'Shipping Area' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_city_name' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT 'b.shipping_state_name' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Buyer Order Pendency' xn_type,'' as joining_table,'' joining_column,'POPEND'





	
	--GIT	   		
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'SL.dept_name' as COL_EXPR,'Sl.dept_id' AS keyfield,'Party Name' AS col_header ,
	'GIT' xn_type,'' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'SL.dept_id' as COL_EXPR,'Sl.dept_id' AS keyfield,'Party Id' AS col_header ,
	'GIT' xn_type,'' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Sl.dept_alias' as COL_EXPR,'Sl.dept_id' AS keyfield,'Party Alias' AS col_header ,
	'GIT' xn_type,'' as joining_table,'dept_id' joining_column
			
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column
 	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'TL.dept_name' as COL_EXPR,'Tl.dept_id' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'GIT' xn_type,'' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'TL.dept_alias' as COL_EXPR,'Tl.dept_id' AS keyfield,'RECEIVING LOCATION ALIAS' AS col_header ,
	'GIT' xn_type,'' as joining_table,'dept_id' joining_column
	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,addnl_join)     
	SELECT 'ISNULL(inm.remarks,rmm.remarks)' as COL_EXPR,'' AS keyfield,'Remarks' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column,' LEFT JOIN inm01106 inm (NOLOCK) ON ''WSL''+inm.inv_id=a.memo_id  
	 LEFT JOIN rmm01106 rmm (NOLOCK) ON ''PRT''+rmm.rm_id=a.memo_id'
	
	--WPS	   		
				
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ac_name,sl.dept_name)' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ALIAS,sl.dept_alias)' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.region_name,sl.REGION_NAME)' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.state,sl.state)' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.city,sl.city)' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
	   
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
 		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'Tl.dept_id' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'#loc_view' as joining_table,'dept_id' joining_column,'loc_tl' joining_table_alias



	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS ' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS2' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_ADDRESS3' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.SHIPPING_AREA_NAME' as COL_EXPR,'' AS keyfield,
	'Shipping Area' AS col_header ,	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT ' b.shipping_city_name' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	SELECT 'b.shipping_state_name' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Wholesale Pack Slip Pendency' xn_type,'' as joining_table,'' as addnl_join


	
	--Debit Note Pack Slip Pendency	   		
				
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ac_name,sl.dept_name)' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ALIAS,sl.dept_alias)' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.region_name,sl.REGION_NAME)' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.state,sl.state)' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.city,sl.city)' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
	   
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
 			

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Debit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	
	--Credit Note Pack Slip Pendency	   		
				
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ac_name,sl.dept_name)' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ALIAS,sl.dept_alias)' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.region_name,sl.REGION_NAME)' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.state,sl.state)' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.city,sl.city)' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
	   
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
 			

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Credit Note Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	
	--Retail Sale Pack Slip Pendency	   		
				
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ac_name,cus.customer_fname)' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ALIAS)' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.region_name,cus.REGION_NAME)' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.state,cus.state)' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.city,cus.city)' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
	   
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column
 			

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Retail Sale Pack Slip Pendency' xn_type,'' as joining_table,'' joining_column

	
	--Approval Pendency	   		
				
	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	--SELECT 'isnull(lm.ac_name,cus.customer_fname)' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	--'Approval Pendency' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus.customer_fname' as COL_EXPR,'' AS keyfield,'Party Name' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	

				
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus.mobile' as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

					
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'cus.user_customer_code' as COL_EXPR,'' AS keyfield,'Party Code' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.ALIAS)' as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.region_name,cus.REGION_NAME)' as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.state,cus.state)' as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'isnull(lm.city,cus.city)' as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column
	   
		   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.product_code' as COL_EXPR,'' AS keyfield,'Item Code' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column
		

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.XN_NO' as COL_EXPR,'' AS keyfield,'Transaction No.' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'A.XN_DT' as COL_EXPR,'' AS keyfield,'Transaction Date' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column
 			

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dbo.FN_GETFINYEARSTR(xn_dt)' as COL_EXPR,'' AS keyfield,'Transaction Financial Year' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.dept_id' as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'Approval Pendency' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,joining_table_alias)     
	SELECT 'dept_name' as COL_EXPR,'Tl.dept_id' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'Approval Pendency' xn_type,'#loc_view' as joining_table,'dept_id' joining_column,'loc_tl' joining_table_alias

   --COMMON


   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping F Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping L Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping Mobile' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'



	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping Address' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping Address 2' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Shipping Address 3' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping Area' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,rep_type)     
	SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'POPEND'
		


    INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party Mobile' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	
    INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	 INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ID' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	 INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'RECEIVING LOCATION ALIAS' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

		

    INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party Alias' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party Id' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	   


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party Region Name' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party State' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT  ''''''  as COL_EXPR,'' AS keyfield,'Party city' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

   
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,	'' AS keyfield,'Against' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Delivery Date' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Ref No' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'OEM (SHIPPING PARTY NAME)' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column
		
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Remarks' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Approval Pendencyroval Level No.' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column
 	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Cancelled' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '''''' as COL_EXPR,'' AS keyfield,'Close Status' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'GST%' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column
	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Gross Purchase price' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Total discount Amount' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT '0' as COL_EXPR,'' AS keyfield,'Net purchase Price' AS col_header ,
	'COMMON' xn_type,'' as joining_table,'' joining_column



	
	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping address' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join

	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping address 2' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join
	
	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping address 3' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join

	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,
	--'Shipping Area' AS col_header ,	'COMMON' xn_type,'' as joining_table,'' as addnl_join
	
	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping City' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join

	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping State' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join

	--INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,addnl_join)     
	--SELECT  '''''' as COL_EXPR,'' AS keyfield,'Shipping Pin' AS col_header ,
	--'COMMON' xn_type,'' as joining_table,'' as addnl_join

		







	   	  

	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'article_no' as COL_EXPR,'a.product_code' AS keyfield,'Article no.' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,3

	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'uom' as COL_EXPR,'a.product_code' AS keyfield,'Uom Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,4

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sub_section_name' as COL_EXPR,'a.product_code' AS keyfield,'Sub Section Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'section_name' as COL_EXPR,'a.product_code' AS keyfield,'Section Name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_name' as COL_EXPR,'a.product_code' AS keyfield,'Para1 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_name' as COL_EXPR,'a.product_code' AS keyfield,'Para2 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3_name' as COL_EXPR,'a.product_code' AS keyfield,'Para3 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4_name' as COL_EXPR,'a.product_code' AS keyfield,'Para4 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5_name' as COL_EXPR,'a.product_code' AS keyfield,'Para5 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6_name' as COL_EXPR,'a.product_code' AS keyfield,'Para6 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para3 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,7.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para4 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,8.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para5 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,9.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6_alias' as COL_EXPR,'a.product_code' AS keyfield,'Para6 Alias' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,10.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_set' as COL_EXPR,'a.product_code' AS keyfield,'Para1 Set' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,5.2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_set' as COL_EXPR,'a.product_code' AS keyfield,'Para2 Set' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'MRP' as COL_EXPR,'a.product_code' AS keyfield,'MRP' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.3

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ws_price' as COL_EXPR,'a.product_code' AS keyfield,'Wholesale Price' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,6.4

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR1_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR1 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,11

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR2_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR2 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,12

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR3_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR3 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR4_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR4 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,13.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR5_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR5 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,14

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR6_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR6 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,15

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR7_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR7 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,16

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR8_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR8 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,17

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR9_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR9 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,18

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR10_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR10 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,19

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR11_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR11 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,20

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR12_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR12 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,21
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR13_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR13 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,22

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR14_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR14 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,23

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR15_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR15 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR16_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR16 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,25

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR17_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR17 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,24

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR18_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR18 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,26

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR19_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR19 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,27

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR20_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR20 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,28

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR21_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR21 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,29

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR22_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR22 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,30

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR23_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR23 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,31

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR24_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR24 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,32

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR25_KEY_NAME' as COL_EXPR,'a.product_code' AS keyfield,'ATTR25 name' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,33

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'a.hsn_code' as COL_EXPR,'' AS keyfield,'HSN/SAC Code' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,34
		
    INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'SKU_ITEM_TYPE_DESC' as COL_EXPR,'a.product_code' AS keyfield,'Transaction Item type' AS col_header ,
	'Common' xn_type,'sku_names' as joining_table,'product_code' joining_column,35
	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name,Col_order)     
	SELECT 'xn_type' as COL_EXPR,'' AS keyfield,'Transaction Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'xn_type' col_name,0  Col_order


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'article_no' as COL_EXPR,'a.article_code' AS keyfield,'Article no.' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,3

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'sub_section_name' as COL_EXPR,'a.article_code' AS keyfield,'Sub Section Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'section_name' as COL_EXPR,'a.article_code' AS keyfield,'Section Name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1.para1_name' as COL_EXPR,'a.para1_code' AS keyfield,'Para1 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para1' as joining_table,'para1_code' joining_column,5

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2.para2_name' as COL_EXPR,'a.para2_code' AS keyfield,'Para2 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para2' as joining_table,'para2_code' joining_column,6

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3.para3_name' as COL_EXPR,'a.para3_code' AS keyfield,'Para3 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para3' as joining_table,'para3_code' joining_column,7

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4.para4_name' as COL_EXPR,'a.para4_code' AS keyfield,'Para4 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para4' as joining_table,'para4_code' joining_column,8

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5.para5_name' as COL_EXPR,'a.para5_code' AS keyfield,'Para5 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para5' as joining_table,'para5_code' joining_column,9

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6.para6_name' as COL_EXPR,'a.para6_code' AS keyfield,'Para6 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'para6' as joining_table,'para6_code' joining_column,10

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1.alias' as COL_EXPR,'a.para1_code' AS keyfield,'Para1 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para1' as joining_table,'para1_code' joining_column,5.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2.alias' as COL_EXPR,'a.para2_code' AS keyfield,'Para2 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para2' as joining_table,'para2_code' joining_column,6.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para3.alias' as COL_EXPR,'a.para3_code' AS keyfield,'Para3 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para3' as joining_table,'para3_code' joining_column,7.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para4.alias' as COL_EXPR,'a.para4_code' AS keyfield,'Para4 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para4' as joining_table,'para4_code' joining_column,8.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para5.alias' as COL_EXPR,'a.para5_code' AS keyfield,'Para5 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para5' as joining_table,'para5_code' joining_column,9.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para6.alias' as COL_EXPR,'a.para6_code' AS keyfield,'Para6 Alias' AS col_header ,
	'Buyer Order Pendency' xn_type,'para6' as joining_table,'para6_code' joining_column,10.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para1_set' as COL_EXPR,'a.para1_code' AS keyfield,'Para1 Set' AS col_header ,
	'Buyer Order Pendency' xn_type,'para1' as joining_table,'para1_code' joining_column,5.2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'para2_set' as COL_EXPR,'a.para2_code' AS keyfield,'Para2 Set' AS col_header ,
	'Buyer Order Pendency' xn_type,'para2' as joining_table,'para2_code' joining_column,6.2

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR1_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR1 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,11

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR2_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR2 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,12

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR3_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR3 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,13

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR4_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR4 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,13.1

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR5_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR5 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,14

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR6_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR6 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,15

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR7_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR7 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,16

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR8_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR8 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,17

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR9_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR9 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,18

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR10_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR10 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,19

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR11_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR11 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,20

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR12_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR12 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,21

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR13_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR13 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,22

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR14_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR14 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,23

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR15_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR15 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,24

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR16_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR16 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,25

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR17_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR17 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,24

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR18_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR18 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,26

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR19_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR19 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,27

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR20_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR20 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,28

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR21_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR21 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,29

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR22_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR22 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,30

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR23_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR23 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,31

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR24_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR24 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,32

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,Col_order)     
	SELECT 'ATTR25_KEY_NAME' as COL_EXPR,'a.article_code' AS keyfield,'ATTR25 name' AS col_header ,
	'Buyer Order Pendency' xn_type,'art_names' as joining_table,'article_code' joining_column,33
	
	DECLARE @cBoPcCol VARCHAR(100)
	SELECT TOP 1 @cBoPcCol=column_name FROM config_buyerorder (NOLOCK) WHERE open_key=1
	AND column_name='product_code'

	IF ISNULL(@cBoPcCol,'')<>''
		DELETE a FROM #transaction_pending_master_COLS a 
		WHERE a.xn_type='Buyer Order Pendency' AND rep_type=''

	UPDATE #transaction_pending_master_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''
	UPDATE #transaction_pending_calculative_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''

	UPDATE #transaction_pending_master_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_pending_calculative_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE transaction_pending_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_pending_master_COLS SET datecol=1 WHERE right(col_name,4)='DATE'

	DELETE FROM transaction_analysis_calculative_COLS WHERE rep_type='POPEND'
	DELETE FROM transaction_analysis_master_COLS WHERE rep_type='POPEND'


	INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header, col_name, group_xn_type, rep_type )
	SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'POPEND' rep_type 
	FROM #transaction_pending_calculative_COLS 


	INSERT transaction_analysis_MASTER_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
	col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
	SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
	group_xn_type, datecol, Col_order, joining_table_alias,'POPEND' rep_type 
	FROM #transaction_pending_master_COLS
		
	
END
