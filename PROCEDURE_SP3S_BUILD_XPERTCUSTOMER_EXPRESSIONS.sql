CREATE PROCEDURE SP3S_BUILD_XPERTCUSTOMER_EXPRESSIONS
AS

BEGIN


	SELECT * INTO #transaction_Customer_calculative_COLS FROM transaction_analysis_calculative_COLS	
	WHERE 1=2

	SELECT * INTO #transaction_customer_master_COLS FROM  transaction_analysis_master_COLS	
	WHERE 1=2
	
	DELETE from transaction_analysis_expr Where   xn_type= 'Customer Analysis'
	

	INSERT transaction_analysis_expr (xn_type,base_expr)    
	SELECT 'Customer Analysis' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[CRM] A (NOLOCK)    	
	WHERE a.cm_dt BETWEEN [DFROMDT] AND [DTODT]  
	AND [WHERE]    
	group by [GROUPBY]' AS base_expr
		
	
	INSERT #transaction_Customer_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Customer Analysis' xn_type,'SUM(a.cal_quantity)' as COL_EXPR,'Quantity' AS col_header 
		
	INSERT #transaction_Customer_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Customer Analysis' xn_type,'SUM(a.cal_nrv)' as COL_EXPR,'Nrv' AS col_header 

	INSERT #transaction_Customer_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'Customer Analysis' xn_type,'SUM(a.cal_net_discount_amount)' as COL_EXPR,'Net Discount Amount' AS col_header 
		
	--MASTER	

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DEPT_ID' as COL_EXPR,'' AS keyfield,'Dept Id' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DEPT_NAME' as COL_EXPR,'' AS keyfield,'Dept Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CUSTOMER_ID' as COL_EXPR,'' AS keyfield,'Customer Id' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.MOBILE' as COL_EXPR,'' AS keyfield,'Mobile ' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CUSTOMER_NAME' as COL_EXPR,'' AS keyfield,'Customer Name ' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DT_BIRTH' as COL_EXPR,'' AS keyfield,'Date of Birth' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DT_ANNIVERSARY' as COL_EXPR,'' AS keyfield,'Date of Anv' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DT_CARD_ISSUE' as COL_EXPR,'' AS keyfield,'Card issue Date' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DT_CARD_EXPIRY' as COL_EXPR,'' AS keyfield,'Card Expiry Date' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CARD_NO' as COL_EXPR,'' AS keyfield,'Card No' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.AREA_NAME' as COL_EXPR,'' AS keyfield,'Area' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CITY' as COL_EXPR,'' AS keyfield,'City' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.STATE' as COL_EXPR,'' AS keyfield,'State' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PIN' as COL_EXPR,'' AS keyfield,'PIN' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ADDRESS0' as COL_EXPR,'' AS keyfield,'ADDRESS0' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ADDRESS1' as COL_EXPR,'' AS keyfield,'ADDRESS1' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ADDRESS2' as COL_EXPR,'' AS keyfield,'ADDRESS2' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ADDRESS9' as COL_EXPR,'' AS keyfield,'ADDRESS9' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.EMAIL' as COL_EXPR,'' AS keyfield,'EMAIL' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DATE_OF_FIRST_VISIT' as COL_EXPR,'' AS keyfield,'Date of First Visit' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DATE_OF_LAST_VISIT' as COL_EXPR,'' AS keyfield,'Date of last Visit' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.NO_OF_VISITS' as COL_EXPR,'' AS keyfield,'No of Visit' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.TOTAL_SPEND' as COL_EXPR,'' AS keyfield,'Total Spend' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.FIRST_VISIT_STORE_ID' as COL_EXPR,'' AS keyfield,'First Visit Store Id' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.LAST_VISIT_STORE_ID' as COL_EXPR,'' AS keyfield,'Last Visit Store Id' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.DAYS_SINCE_LAST_VISIT' as COL_EXPR,'' AS keyfield,'Days Since Last Visit' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.AFD' as COL_EXPR,'' AS keyfield,'AFD' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ATS' as COL_EXPR,'' AS keyfield,'ATS' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ABS' as COL_EXPR,'' AS keyfield,'ABS' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CM_NO' as COL_EXPR,'' AS keyfield,'CM NO' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.CM_DT' as COL_EXPR,'' AS keyfield,'CM DT' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PRODUCT_CODE' as COL_EXPR,'' AS keyfield,'Product Code' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.NET_DISCOUNT_PERCENTAGE' as COL_EXPR,'' AS keyfield,'Net Discount %' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.MRP' as COL_EXPR,'' AS keyfield,'MRP' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.SECTION_NAME' as COL_EXPR,'' AS keyfield,'Section Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.SUB_SECTION_NAME' as COL_EXPR,'' AS keyfield,'Sub Section Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.ARTICLE_NO' as COL_EXPR,'' AS keyfield,'Article No' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA1_NAME' as COL_EXPR,'' AS keyfield,'Para1 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA2_NAME' as COL_EXPR,'' AS keyfield,'Para2 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA3_NAME' as COL_EXPR,'' AS keyfield,'Para3 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column
	
	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA4_NAME' as COL_EXPR,'' AS keyfield,'Para4 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA5_NAME' as COL_EXPR,'' AS keyfield,'Para5 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.PARA6_NAME' as COL_EXPR,'' AS keyfield,'Para6 Name' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.MEMBERSHIP_YEARS' as COL_EXPR,'' AS keyfield,'Membership years' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_customer_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'a.MEMBERSHIP_DAYS' as COL_EXPR,'' AS keyfield,'Membership Days' AS col_header ,
	'Customer Analysis' xn_type,'' as joining_table,'' joining_column



  


	UPDATE #transaction_customer_master_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''
	UPDATE #transaction_Customer_calculative_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''

	UPDATE #transaction_customer_master_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_Customer_calculative_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE transaction_analysis_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_customer_master_COLS SET datecol=1 WHERE right(col_name,4)='DATE'
	UPDATE #transaction_customer_master_COLS SET datecol=1 WHERE left(col_name,4)='DATE'

	DELETE FROM transaction_analysis_calculative_COLS WHERE rep_type='CAR'
	DELETE FROM transaction_analysis_master_COLS WHERE rep_type='CAR'


	INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header, col_name, group_xn_type, rep_type )
	SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'CAR' rep_type 
	FROM #transaction_Customer_calculative_COLS 


	INSERT transaction_analysis_MASTER_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
	col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
	SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
	group_xn_type, datecol, Col_order, joining_table_alias,'CAR' rep_type 
	FROM #transaction_customer_master_COLS
		
	
END