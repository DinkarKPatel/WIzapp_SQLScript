CREATE PROCEDURE SP3S_XPERTREPORTING_WOW
(
@iQueryId Int,
@cUserCode Varchar(10),
@cWhere Varchar(50)='',
@cXPertCode varchar(10)=''
)
AS BEGIN

    
IF @iQueryId = 1    
GOTO LBL1  
ELSE IF @iQueryId = 2  
GOTO LBL2  
ELSE IF @iQueryId = 3 
GOTO LBL3 
ELSE IF @iQueryId = 4 
GOTO LBL4
ELSE IF @iQueryId = 5 
GOTO LBL5
ELSE IF @iQueryId = 6
GOTO LBL6
ELSE IF @iQueryId = 7
GOTO LBL7
ELSE IF @iQueryId = 8
GOTO LBL8
ELSE IF @iQueryId = 9
GOTO LBL9
ELSE IF @iQueryId = 10
GOTO LBL10
ELSE  
GOTO LAST    

LBL1:

	SELECT 'X' AS XN_TYPE,a.rep_id,a.rep_name,
	case when a.XPERT_REP_CODE='R2' then 'Transaction Analysis'  
	when  a.XPERT_REP_CODE='R3' then 'Sales Order Analysis'	
	when  a.XPERT_REP_CODE='R4' then 'Stock Quantity'	
	when  a.XPERT_REP_CODE='R5' then 'Purchase Order Analysis'
	when  a.XPERT_REP_CODE='R6' then 'Eoss based Sales and Stock Reporting'
	Else  'Stock Analysis' End  as rep_type,0 as  inActive,
	isnull(a.rep_grouping,'ALL') as user_rep_type,a.remarks,c.username ,a.Last_update,a.XPERT_REP_CODE
	FROM wow_xpert_rep_mst a (NOLOCK) 	
	JOIN USERS C on a.user_code = c.user_code 
	WHERE  isnull(a.rep_item_type,1) = 1  AND isnull(a.xn_history,0)<> 1
	AND ISNULL(a.XPERT_REP_CODE ,'') NOT IN ('','XNHISTORY')
    and a.user_code = @cUserCode
	
	UNION 
	SELECT 'Y' AS XN_TYPE,a.rep_id,a.rep_name,	
	case when a.XPERT_REP_CODE='R2' then 'Transaction Analysis'  
	when  a.XPERT_REP_CODE='R3' then 'Sales Order Analysis'	
	when  a.XPERT_REP_CODE='R4' then 'Stock Quantity'
	when  a.XPERT_REP_CODE='R5' then 'Purchase Order Analysis'	
	when  a.XPERT_REP_CODE='R6' then 'Eoss based Sales and Stock Reporting'
	Else  'Stock Analysis' End  as rep_type,	
    0 as inActive, 
	isnull(a.rep_grouping,'ALL')as user_rep_type,a.remarks,c.username,a.Last_update,a.XPERT_REP_CODE
	FROM replocs r (nolock)
	join wow_xpert_rep_mst a (NOLOCK) on r.rep_id= a.rep_id 	
	JOIN USERS C (nolock) on r.user_code = c.user_code 
	WHERE   r.user_code = @cUserCode AND r.dept_id = @cWhere
	And isnull(a.XPERT_REP_CODE,'') <> ''   AND isnull(a.xn_history,0)<> 1	
	ORDER BY XPERT_REP_CODE,rep_type,user_rep_type,a.rep_name

	
GOTO LAST  

LBL2:

	Declare @val Varchar(MAX), @val2 Varchar(MAX);
	Select @val = COALESCE(@val + ', ' + col_header, col_header) 
	From wow_xpert_rep_det  (nolock) where rep_id = @cWhere 
	order by col_order
	Select @val


	Select @val2 = COALESCE(@val2 + ', ' + col_header, col_header) 
	From wow_xpert_rep_det (nolock) where rep_id = @cWhere 
	order by col_order
	Select @val2


GOTO LAST   

LBL10:

	Declare @val1 Varchar(MAX), @val3 Varchar(MAX);
	Select @val1= COALESCE(@val + ', ' + col_header, col_header) 
	From rep_det  (nolock) where rep_id = @cWhere 
	order by col_order
	Select @val1
	



GOTO LAST   



LBL3:
     
	 
	Select 'R1' as report_grp_code ,'Stock Analysis' as report_group 
	UNION ALL
	Select 'R2' as report_grp_code ,'Transaction Analysis' as report_group 	
	UNION ALL
	Select 'R3' as report_grp_code ,'Sales Order Analysis' as report_group 
	UNION ALL
	Select 'R4' as report_grp_code ,'Stock Quantity' as report_group 
	UNION ALL
	Select 'R5' as report_grp_code ,'Purchase Order Analysis' as report_group 
	UNION ALL
	Select 'R6' as report_grp_code ,'Eoss based Sales and Stock Reporting' as report_group 

	
	
	

GOTO LAST  



LBL4:

       If @cXPertCode = 'R1'

	   BEGIN


		SELECT  *
		FROM
		(
		SELECT 0 AS X , 'OPS' as CAL_COLUMN_GRP,*, cols_name as newcols_name, COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL  ,
		0 as Col_type_order
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001' AND XN_TYPE IN ('STOCK')  AND LEFT (COLS_NAME,2) = 'OB'  
		and cols_name not like '%TOTAL'
		UNION

		select   5 AS X ,b.Col_type,a.*, cols_name as newcols_name ,b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE,
		b.master_col AS ORG_BASIC_COL ,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a 
		join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code in ('Z001')  and  LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD')  
		and b.col_type <> '' and b.COL_EXPR <> ''-- and cols_name= 'PPW'
				
		UNION
				
		select 6 AS X ,'WTD' + b.COL_TYPE,a.*, 'WTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100)  as newcols_name ,
		'WTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE ,
		'WTD_' + BASIC_COL AS ORG_BASIC_COL ,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' 
		and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','VALUE AT LC','Value at WSP',
	   'Value at Xfer','Value at Xfer(W/O GST)','Tax/GST','Transaction Value(W/O GST)','Transaction Value')  
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD','GIT')  and b.col_type <> ''
		and b.COL_EXPR <> ''
			
		
		UNION

		select 6 AS X ,'MTD' + b.COL_TYPE,a.*,'MTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100) as newcols_name ,
		'MTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE  ,
		'MTD_'+BASIC_COL AS ORG_BASIC_COL,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a 
		join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' 
		and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','Value at LC','Value at WSP',
		'Value at Xfer','Value at Xfer(W/O GST)','Tax/GST','Transaction Value(W/O GST)','Transaction Value')  
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD','GIT')  and b.col_type <> ''
		and b.COL_EXPR <> ''

		UNION

		select 6 AS X ,'YTD' + b.COL_TYPE,a.*, 'YTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100)  as newcols_name ,
		'YTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE , 
		'YTD_' +BASIC_COL AS ORG_BASIC_COL,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a 
		join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' 
		and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','VALUE AT LC','Value at WSP',
	    'Value at Xfer','Value at Xfer(W/O GST)','Tax/GST','Transaction Value(W/O GST)','Transaction Value')  
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD','GIT')  and b.col_type <> '' 
		and b.COL_EXPR <> ''
			   		 	  	  	 

        UNION
		SELECT 998 AS X , 'STHP' as CAL_COLUMN_GRP,*,cols_name as newcols_name ,'Quantity' AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL,998 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001'  and cols_Name = 'STHP'


	    UNION
		SELECT 998 AS X , 'STHP' as CAL_COLUMN_GRP,*,'STHPPP' as newcols_name ,'Value at PP' AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL,998 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001'  and cols_Name = 'STHP'

	    UNION
		SELECT 998 AS X , 'STHP' as CAL_COLUMN_GRP,*,'STHPRSP' as newcols_name ,'Value at RSP' AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL,998 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001'  and cols_Name = 'STHP'


		UNION
		SELECT 998 AS X , 'STHP' as CAL_COLUMN_GRP,*,'STHPLC' as newcols_name ,'Value at LC' AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL,998 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001'  and cols_Name = 'STHP'

		UNION
		SELECT 998 AS X , 'STHP' as CAL_COLUMN_GRP,*,'STHPWSP' as newcols_name ,'Value at WSP' AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL,998 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001'  and cols_Name = 'STHP'
		

		UNION 
		SELECT 999 AS X , 'CBS' as CAL_COLUMN_GRP,*,cols_name as newcols_name ,COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE,BASIC_COL AS ORG_BASIC_COL, 999 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE REP_CODE= 'Z001' AND XN_TYPE IN ('STOCK')  
		AND LEFT (COLS_NAME,2) = 'CB'  and cols_name not like '%TOTAL'

	    UNION
		SELECT 1000 AS X , cols_name as CAL_COLUMN_GRP,*,cols_name as newcols_name ,COL_VALUE_TYPE  AS ORG_COL_VALUE_TYPE,
		BASIC_COL AS ORG_BASIC_COL,1000 as COL_TYPE_ORDER 
		FROM REPORTTYPEDETAILS  WHERE  cols_Name = 'CBS_AU'

	



		) A ORDER BY X 

		END


		If @cXPertCode = 'R2'

	   BEGIN

		SELECT  *
		FROM
		(

		select   5 AS X ,b.Col_type AS CAL_COLUMN_GRP,a.*, cols_name as newcols_name ,
		b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE,
		b.master_col AS ORG_BASIC_COL ,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code in ('Z001')  and  LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD')  and b.col_type <> ''-- and cols_name= 'PPW'
				
		UNION
				
		select 6 AS X ,'WTD' + b.COL_TYPE,a.*, 'WTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100)  as newcols_name
		,'WTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE ,
		'WTD_' + BASIC_COL AS ORG_BASIC_COL ,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','VALUE AT LC',
		'Value at WSP','Value at Xfer')  
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD')  and b.col_type <> ''
		UNION

		select 6 AS X ,'MTD' + b.COL_TYPE,a.*,'MTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100) as newcols_name ,
		'MTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE  ,
		'MTD_'+BASIC_COL AS ORG_BASIC_COL,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' 
		and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','Value at LC','Value at WSP',
		'Value at Xfer')  
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD')  and b.col_type <> ''

		UNION

		select 6 AS X ,'YTD' + b.COL_TYPE,a.*, 'YTD_'+LEFT(cols_name,1) + 'XX'+ Substring(cols_name,2,100)  as newcols_name ,'YTD'+b.COL_VALUE_TYPE AS ORG_COL_VALUE_TYPE , 
		'YTD_' +BASIC_COL AS ORG_BASIC_COL,b.COL_TYPE_ORDER 
		From REPORTTYPEDETAILS   a join xtreme_reports_exp_cols  b on a.cols_name= b.calculative_col  
		where a.rep_code= 'Z001' 
		and b.col_value_type in ('Quantity' ,'Value at PP','Value at RSP','VALUE AT LC','Value at WSP',
		'Value at Xfer') 
		and LEFT(COLS_NAME,3) NOT IN ('MTD','YTD','WTD')  and b.col_type <> '' 		 	  	  	 

  		) A ORDER BY X 

		END







GOTO LAST  




LBL5:


	If @cXPertCode = 'R1'
	BEGIN
		SELECT  *
		FROM
		(
		SELECT 0 as X, 'Opening Stock' as Col_type  ,'OPS' AS MASTER_TABLE, 'OPS' as CAL_COLUMN_GRP,cast(0 as bit) as required	
		UNION
		select distinct isnull(col_type_order,1) AS X,COL_TYPE,MASTER_TABLE ,COL_TYPE ,cast(0 as bit) as required from xtreme_reports_exp_cols where col_value_type <> ''  
		and col_type not in ( '' ,'INWARD','OUTWARD','BALANCE' )and master_table not in ('POM01106','GRN_PS_MST') 
		UNION
		SELECT 990 as X, 'Sell Thru%' as Col_type  ,'OPS' AS MASTER_TABLE, 'STHP' as CAL_COLUMN_GRP,cast(0 as bit) as required	
		UNION
		SELECT 999 AS X, 'Closing Stock' as col_type , 'OPS' ,'CBS' as CAL_COLUMN_GRP,cast(0 as bit) as required

		) A ORDER BY X 
	END

	If @cXPertCode = 'R2'
	BEGIN
		SELECT  *
		FROM
		(		
		select distinct isnull(col_type_order,1) AS X,COL_TYPE,MASTER_TABLE ,COL_TYPE AS  CAL_COLUMN_GRP,cast(0 as bit) as required from xtreme_reports_exp_cols where col_value_type <> ''  and col_type <> '' and master_table <> 'POM01106'
		
		) A ORDER BY X 
	END

	If @cXPertCode = 'R3'
	BEGIN
		SELECT  *
		FROM
		(		
		select distinct isnull(col_type_order,1) AS X,COL_TYPE,MASTER_TABLE ,COL_TYPE AS  CAL_COLUMN_GRP,cast(0 as bit) as required from xtreme_reports_exp_cols where col_value_type <> ''  and col_type <> '' and master_table <> 'POM01106'
		
		) A ORDER BY X 
	END


	
GOTO LAST  



LBL6:

   
    select cast(0 as bit ) as CHK ,* from Xpert_filter_Mst  where rep_code= @cWhere

GOTO LAST 


LBL7:

   --,'Transaction Value(W/O GST)','Transaction Value'
     select distinct COL_VALUE_TYPE,cast(0 as bit) as required,cast(0 as bit) as WTD,cast(0 as bit) as MTD,cast(0 as bit) as YTD	
	 From xtreme_reports_exp_cols 
	 where col_value_type in ( 'Quantity','Value at PP','Value at RSP','Value at LC','Value at WSP',
	 'Value at Xfer','Value at Xfer(W/O GST)','Tax/GST')  
	 AND  (COL_VALUE_TYPE <> @cWhere  or @cWhere='')
	 UNION ALL
	 select 'Altername Uom Qty' COL_VALUE_TYPE,cast(0 as bit) as required,cast(0 as bit) as WTD,cast(0 as bit) as MTD,
	 cast(0 as bit) as YTD	
	

GOTO LAST 




LBL8:

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Quantity' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBS','CBS')

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at PP' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBP1','CBP1')
				
		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at RSP' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBM','CBM')

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at LC' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBLC','CBLC')

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at WSP' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBW','CBW')

	    UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at Xfer' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBXP','CBXP')

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at Xfer' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBXP','CBXP')

		UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at Xfer(W/O GST)' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBXPWG','CBXPWG')
		
		--UPDATE REPORTTYPEDETAILS set col_value_type= 'Value at Xfer(W/O DEP)' where rep_code= 'Z001'   and xn_type= 'STOCK' and  cols_name in ( 'OBXFDEP','CBXFDEP')
		
		update reporttypedetails set col_value_type= 'Quantity' where rep_code= 'Z001' 
		and cols_name  in ('OUTQTY','NETQTY' ,'INQTY')

		UPDATE REPORTTYPEDETAILS set rep_code= 'Z001' where rep_code= 'X001'   and  cols_name in ( 'PPW','PRW','NPW')

		IF NOT EXISTS (SELECT TOP 1 cols_name FROM REPORTTYPEDETAILS (NOLOCK) WHERE cols_name='CBS_AU')
			INSERT REPORTTYPEDETAILS	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name,
			div_factor, rep_code, subtotal, xn_type )  
			SELECT TOP 1  BASIC_COL, CalCulated, col_expr, Col_header+ '(Alt. Uom)', col_Order, col_repeat,
			'Altername Uom Qty' COL_VALUE_TYPE, col_width,
			'CBS_AU' cols_Name, div_factor, 'Z001' as rep_code, subtotal,'MISC' xn_type FROM REPORTTYPEDETAILS
			where cols_name in ('CBS')


		IF NOT EXISTS (SELECT TOP 1 cols_name FROM REPORTTYPEDETAILS (NOLOCK) WHERE cols_name='PURSTKAGEDAYS')
			INSERT REPORTTYPEDETAILS	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name,
			div_factor, rep_code, subtotal, xn_type )  
			SELECT TOP 1  'STKDAYS', CalCulated, 'PURSTKAGEDAYS', 'Purchase Ageing Days', 438, col_repeat,
			'' COL_VALUE_TYPE, col_width,
			'PURSTKAGEDAYS' cols_Name, div_factor, 'Z001' as rep_code, subtotal,'Miscellaneous ' xn_type FROM REPORTTYPEDETAILS
			where cols_name in ('CBS')


		IF NOT EXISTS (SELECT TOP 1 cols_name FROM REPORTTYPEDETAILS (NOLOCK) WHERE cols_name='SHELFSTKAGEDAYS')
			INSERT REPORTTYPEDETAILS	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name,
			div_factor, rep_code, subtotal, xn_type )  
			SELECT TOP 1  'STKDAYS', CalCulated, 'SHELFSTKAGEDAYS', 'Shelf Ageing Days', 439, col_repeat,
			'' COL_VALUE_TYPE, col_width,
			'SHELFSTKAGEDAYS' cols_Name, div_factor, 'Z001' as rep_code, subtotal,'Miscellaneous ' xn_type FROM REPORTTYPEDETAILS
			where cols_name in ('CBS')


		IF NOT EXISTS (SELECT TOP 1 cols_name FROM REPORTTYPEDETAILS (NOLOCK) WHERE cols_name='SALESTKAGEDAYS')
			INSERT REPORTTYPEDETAILS	( BASIC_COL, CalCulated, col_expr, Col_header, col_Order, col_repeat, COL_VALUE_TYPE, col_width, cols_Name,
			div_factor, rep_code, subtotal, xn_type )  
			SELECT TOP 1  'STKDAYS', CalCulated, 'SALESTKAGEDAYS', 'Sale Ageing Days', 440, col_repeat,
			'' COL_VALUE_TYPE, col_width,
			'SALESTKAGEDAYS' cols_Name, div_factor, 'Z001' as rep_code, subtotal,'Miscellaneous ' xn_type FROM REPORTTYPEDETAILS
			where cols_name in ('CBS')
			
			
			

		GOTO LAST 
	


LBL9:

		DELETE FROM REP_DET WHERE ENFORCED_COL=1 and REP_ID = @cWhere

		INSERT REP_DET	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
		col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id,
		Required, row_id, table_name, total ) 
		SELECT 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, 'NSQ'col_expr, 'Net SLS Qty'col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, col_width,
		contr_per, cum_sum, Decimal_place, Dimension, 1 Enforced_col, Filter_col, grp_total, 'NSQ' key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, 
		Required, Newid() row_id, table_name, total FROM REP_DET WHERE REP_ID = @cWhere and  key_col in ('STHP') 


		INSERT REP_DET	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
		col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id,
		Required, row_id, table_name, total ) 
		SELECT 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, 'NSG'col_expr, 'Net SLS Val at Gross MRP'col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, col_width,
		contr_per, cum_sum, Decimal_place, Dimension, 1 Enforced_col, Filter_col, grp_total, 'NSG' key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, 
		Required, Newid() row_id, table_name, total FROM REP_DET WHERE REP_ID = @cWhere and  key_col in ('STHPRSP') 


		INSERT REP_DET	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
		col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id,
		Required, row_id, table_name, total ) 
		SELECT 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, 'NSP1'col_expr, 'Net SLS Val at PP'col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, col_width,
		contr_per, cum_sum, Decimal_place, Dimension, 1 Enforced_col, Filter_col, grp_total, 'NSP1' key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, 
		Required, Newid() row_id, table_name, total FROM REP_DET WHERE REP_ID = @cWhere and  key_col in ('STHPPP') 

	    INSERT REP_DET	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
		col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id,
		Required, row_id, table_name, total ) 
		SELECT 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, 'NSLC'col_expr, 'Net SLS Val at LC'col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, col_width,
		contr_per, cum_sum, Decimal_place, Dimension, 1 Enforced_col, Filter_col, grp_total, 'NSLC' key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, 
		Required, Newid() row_id, table_name, total FROM REP_DET WHERE REP_ID = @cWhere and  key_col in ('STHPLC') 


		INSERT REP_DET	( BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, col_expr, col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, 
		col_width, contr_per, cum_sum, Decimal_place, Dimension, Enforced_col, Filter_col, grp_total, key_col, Mesurement_col, order_by, order_on, rep_code, rep_id,
		Required, row_id, table_name, total ) 
		SELECT 	  BASIC_COL, CAL_COLUMN_GRP, Cal_function, Calculative_col, 'NSWSP'col_expr, 'Net SLS Val at WSP'col_header, col_mst, col_Order, col_repeat, col_Type, COL_VALUE_TYPE, col_width,
		contr_per, cum_sum, Decimal_place, Dimension, 1 Enforced_col, Filter_col, grp_total, 'NSLC' key_col, Mesurement_col, order_by, order_on, rep_code, rep_id, 
		Required, Newid() row_id, table_name, total FROM REP_DET WHERE REP_ID = @cWhere and  key_col in ('STHPWSP') 


 
GOTO LAST 

LAST:
END



