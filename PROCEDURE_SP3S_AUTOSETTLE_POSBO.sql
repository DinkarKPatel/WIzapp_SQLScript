CREATE PROCEDURE SP3S_AUTOSETTLE_POSBO
AS
BEGIN
	
	DECLARE @cErrormsg VARCHAR(MAX),@cCollist VARCHAR(2000),@cJoinstr varchar(2000),@cStep VARCHAR(10),
			@cCmd NVARCHAR(MAX),@cRepCols VARCHAR(1000),@cOrderId VARCHAR(40),@cRepColsIns VARCHAR(1000),
		    @cBoJoinstr VARCHAR(2000),@cFilter VARCHAR(500),@cAutoCloseBO VARCHAR(2),@dOrderDt DATETIME ,
			@cNewJoinStr VARCHAR(1000)
			 

BEGIN TRY
	SET @cStep='5'
	SELECT TOP 1 @cAutoCloseBO=value FROM config(NOLOCK) WHERE config_option='auto_close_bo'

	IF ISNULL(@cAutoCloseBO,'')<>'1'
		RETURN
	
	SET @cStep='7'
	SELECT @cCollist = coalesce(@cColList+',','')+'a.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
	WHERE isnull(open_key,0)=1

	SELECT article_no,para1_name,para2_name,para3_name,para4_name,para5_name,para6_name,quantity as order_qty,
	product_code,quantity as pending_order_qty,dept_id
	INTO #pos_bo FROM buyer_order_det a (NOLOCK)
	JOIN buyer_order_mst b (NOLOCK) ON a.order_id=b.order_id
	LEFT JOIN article c (NOLOCK) ON a.article_code=c.article_code
	LEFT JOIN para1 p1 (NOLOCK) ON p1.para1_code=a.para1_code
	LEFT JOIN para2 p2 (NOLOCK) ON p2.para2_code=a.para2_code
	LEFT JOIN para3 p3 (NOLOCK) ON p3.para3_code=a.para3_code
	LEFT JOIN para4 p4 (NOLOCK) ON p4.para4_code=a.para4_code
	LEFT JOIN para5 p5 (NOLOCK) ON p5.para5_code=a.para5_code
	LEFT JOIN para6 p6 (NOLOCK) ON p6.para6_code=a.para6_code
	WHERE 1=2

	SET @cStep='10'
	SELECT DISTINCT a.order_id,b.dept_id,order_dt INTO #pending_orders from buyer_order_det a 
	JOIN buyer_order_mst b on a.order_id=b.order_id
	WHERE cancelled=0 AND ISNULL(b.Short_close,0)=0 AND a.quantity-ISNULL(a.inv_qty,0)>0

	SELECT @cRepCols='b.dept_id'+
		(CASE WHEN charindex('product_code',@cColList)>0 THEN ',a.product_code ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ',article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ',para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ',para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ',para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ',para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ',para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ',para6_name ' ELSE '' END)
	
	SET @cStep='12'
	SELECT @cJoinstr='1=1 '+
		(CASE WHEN charindex('product_code',@cColList)>0 THEN  ' AND b.product_code=a.product_code ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' AND b.article_no=a.article_no ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' AND b.para1_name=a.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' AND b.para2_name=a.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' AND b.para3_name=a.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' AND b.para4_name=a.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' AND b.para5_name=a.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' AND b.para6_name=a.para6_name ' ELSE '' END)
	
	SET @cBoJoinstr=''

	SELECT @cBoJoinstr=
		(CASE WHEN charindex('ARTICLE_NO',@cColList)>0 THEN  ' JOIN article art (NOLOCK) ON art.article_code=a.article_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cColList)>0 THEN  ' JOIN para1 p1 ON p1.para1_code=a.para1_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cColList)>0 THEN  ' JOIN para2 p2 ON p2.para2_code=a.para2_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cColList)>0 THEN  ' JOIN para3 p3 ON p3.para3_code=a.para3_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cColList)>0 THEN  ' JOIN para4 p4 ON p4.para4_code=a.para4_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cColList)>0 THEN  ' JOIN para5 p5 ON p5.para5_code=a.para5_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cColList)>0 THEN  ' JOIN para6 p6 ON p6.para6_code=a.para6_code ' ELSE '' END)
	

	SET @cStep='15'
	SET @cRepColsIns=REPLACE(REPLACE(@cRepCols,'b.',''),'a.','')

	WHILE EXISTS (SELECT TOP 1 order_id FROM  #pending_orders)
	BEGIN
		SET @cStep='20'
		
		SELECT TOP 1 @cOrderId=order_id,@dOrderDt=order_dt FROM #pending_orders
		ORDER by order_dt

		DELETE FROM #pos_bo

		PRINT 'Checking Pending Order Dated:'+convert(varchar,@dOrderDt,105)

		SET @cCmd=N'INSERT INTO #pos_bo ('+@cRepColsIns+',order_qty,pending_order_qty)
		SELECT '+@cRepCols+',(a.quantity-isnull(a.adj_qty,0)- isnull(inv_qty,0)),(a.quantity-isnull(a.adj_qty,0)- isnull(inv_qty,0))  
		FROM buyer_order_det a 
		JOIN buyer_order_mst b ON a.order_id=b.order_id '+@cBoJoinstr+'
		WHERE b.order_id='''+@cOrderId+''' AND a.quantity-isnull(a.adj_qty,0)-ISNULL(inv_qty,0)>0'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		
		SET @cStep='25'			
		SELECT @cFilter=REPLACE(@cCollist,',','+')+' IN (SELECT DISTINCT '+REPLACE(@cCollist,',','+')+' FROM buyer_order_det a 
		JOIN buyer_order_mst b ON a.order_id=b.order_id '+@cBoJoinstr+'
		WHERE a.order_id='''+@cOrderId+''')'

		SET @cStep='30'		
		SET @cCmd=N'UPDATE a SET pending_order_qty=pending_order_qty-isnull(b.stock_qty,0)
			FROM #pos_bo a
			JOIN 
			(SELECT '+replace(@cRepCols,'b.dept_id','a.dept_id') +',sum(quantity_in_stock) as stock_qty
				FROM pmt01106 a (NOLOCK)
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
				WHERE '+@cFilter+' AND quantity_in_stock>0
				GROUP BY '+replace(@cRepCols,'b.dept_id','a.dept_id')+'
				HAVING sum(quantity_in_stock)>0
				) b on '+@cJoinStr
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		IF CHARINDEX('product_code',@cColList)>0
		AND NOT EXISTS (SELECT TOP 1 * FROM #pos_bo WHERE pending_order_qty<>order_qty)
		BEGIN
			SET @cStep='35'		
			SET @cNewJoinStr=REPLACE(@cJoinstr,'b.product_code','LEFT(b.PRODUCT_CODE, ISNULL(NULLIF(CHARINDEX (''@'',b.PRODUCT_CODE)-1,-1),LEN(b.PRODUCT_CODE )))')
			
			SET @cStep='37'		
			SET @cCmd=N'UPDATE a SET pending_order_qty=pending_order_qty-isnull(b.stock_qty,0)
				FROM #pos_bo a
				JOIN 
				(SELECT '+replace(@cRepCols,'b.dept_id','a.dept_id') +',sum(quantity_in_stock) as stock_qty
					FROM pmt01106 a (NOLOCK)
					JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code 
					WHERE '+@cFilter+' AND quantity_in_stock>0
					GROUP BY '+replace(@cRepCols,'b.dept_id','a.dept_id')+'
					HAVING sum(quantity_in_stock)>0
					) b on '+@cNewJoinStr
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		
		END

		SET @cStep='40'		
		IF NOT EXISTS (SELECT TOP 1 * FROM #pos_bo WHERE pending_order_qty<>order_qty)
		BEGIN
			BEGIN TRAN
			UPDATE buyer_order_mst SET Short_close=1,Short_Close_Remarks='Auto Close' WHERE order_id=@cOrderId
			COMMIT
		END
		ELSE
			PRINT 'Order Id stock lying :'+@cOrderId

		SET @cStep='45'		
		DELETE FROM #pending_orders WHERE order_id=@cOrderId

	 END

END TRY
BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_AUTOSETTLE_POSBO at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg
END