CREATE PROCEDURE SP3S_BUILD_XPERTGIT_EXPRESSIONS
AS

BEGIN


	SELECT * INTO #transaction_pending_calculative_COLS FROM transaction_analysis_calculative_COLS	
	WHERE 1=2

	SELECT * INTO #transaction_pending_master_COLS FROM  transaction_analysis_master_COLS	
	WHERE 1=2
	
	DELETE from transaction_PENDING_expr WHERE XN_TYPE= 'GIT'


	INSERT transaction_PENDING_expr (xn_type,base_expr)    
	SELECT 'GIT' xn_type,'[LAYOUT_COLS]
	from [DATABASE].dbo.[GITTABLE] A (NOLOCK)  	
	JOIN location sl (NOLOCK) ON sl.dept_id=RIGHT(A.xn_party_code,2)
	JOIN location Tl (NOLOCK) ON sl.dept_id=A.dept_id	
	[JOIN]
	WHERE [WHERE]    
	group by [GROUPBY]' AS base_expr

	--GIT

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty)' as COL_EXPR,'GIT Qty' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sku_names.pp)' as COL_EXPR,'GIT Value at PP' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sku_names.mrp)' as COL_EXPR,'GIT Value at Mrp' AS col_header 
	
	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sxfp.xfer_price_without_gst)' as COL_EXPR,'GIT Value at Transfer Price Taxable Value' AS col_header 

	INSERT #transaction_pending_calculative_COLS	(xn_type,col_expr,col_header)
	SELECT 'GIT' xn_type,'SUM(a.git_qty*sxfp.xfer_price)' as COL_EXPR,'GIT Value at Transfer Price' AS col_header 
	   
		
   --MASTER
   
	 INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type, joining_table,joining_column)     
	SELECT 'dept_id' as COL_EXPR,'Tl.dept_id' AS keyfield,'Target Location Id' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'Tl.dept_id' AS keyfield,'Target Location Name' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Area_name' as COL_EXPR,'Tl.dept_id' AS keyfield,'Target Location Area' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'Tl.dept_id' AS keyfield,'Target Location City' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'Tl.dept_id' AS keyfield,'Target Location State' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column


	

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type, joining_table,joining_column)     
	SELECT 'dept_id' as COL_EXPR,'Sl.dept_id' AS keyfield,'Source Location Id' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'dept_name' as COL_EXPR,'Sl.dept_id' AS keyfield,'Source Location Name' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Area_name' as COL_EXPR,'Sl.dept_id' AS keyfield,'Source Location Area' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column


	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'city' as COL_EXPR,'Sl.dept_id' AS keyfield,'Source Location City' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'state' as COL_EXPR,'Sl.dept_id' AS keyfield,'Source Location State' AS col_header ,
	'GIT' xn_type,'#loc_view' as joining_table,'dept_id' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Xn_no' as COL_EXPR,'' AS keyfield,'Challan No' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column

	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column)     
	SELECT 'Xn_dt' as COL_EXPR,'' AS keyfield,'Challan Date' AS col_header ,
	'GIT' xn_type,'' as joining_table,'' joining_column


	
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
		

	
	INSERT #transaction_pending_master_COLS	(COL_EXPR,keyfield,COL_HEADER,xn_type,joining_table,joining_column,col_name,Col_order)     
	SELECT 'xn_type' as COL_EXPR,'' AS keyfield,'Transaction Type' AS col_header ,
	'Common' xn_type,'' as joining_table,'' joining_column,'xn_type' col_name,0  Col_order
	   	

	UPDATE #transaction_pending_master_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''
	UPDATE #transaction_pending_calculative_COLS SET col_name=REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(col_header,' %','_pct'),' ','_'),'/',''),'(',''),')',''),'.',''),'%','_pct')
	where isnull(col_name,'')=''

	UPDATE #transaction_pending_master_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_pending_calculative_COLS set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE transaction_pending_expr set group_xn_type=REPLACE(REPLACE(xn_type,'1',''),'2','')
	UPDATE #transaction_pending_master_COLS SET datecol=1 WHERE right(col_name,4)='DATE'

	DELETE FROM transaction_analysis_calculative_COLS WHERE rep_type='GIT'
	DELETE FROM transaction_analysis_master_COLS WHERE rep_type='GIT'


	INSERT transaction_analysis_calculative_COLS	( xn_type, col_expr, col_header, col_name, group_xn_type, rep_type )
	SELECT 	  xn_type, col_expr, col_header, col_name, group_xn_type,'GIT' rep_type 
	FROM #transaction_pending_calculative_COLS 


	INSERT transaction_analysis_MASTER_COLS	( col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column,
	col_name, addnl_join, group_xn_type, datecol, Col_order, joining_table_alias, rep_type )  
	SELECT 	  col_expr, COL_HEADER, xn_type, joining_table, keyfield, joining_column, col_name, addnl_join, 
	group_xn_type, datecol, Col_order, joining_table_alias,'GIT' rep_type 
	FROM #transaction_pending_master_COLS
		

END