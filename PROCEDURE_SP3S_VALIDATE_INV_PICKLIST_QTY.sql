create PROCEDURE SP3S_VALIDATE_INV_PICKLIST_QTY
@cKeyFieldVal VARCHAR(40),
@nRevertFlag NUMERIC(1,0)=0,
@nUpdatemode NUMERIC(1,0),
@cXnType VARCHAR(10),
@NBOXNO NUMERIC(3,0)=0,
@cProductCode VARCHAR(50)='',
@bOrderValidationFailed BIT OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-1'+@cXntype
	SET @bOrderValidationFailed=0

BEGIN TRY
	DECLARE @cInvId VARCHAR(40),@cConfigCols VARCHAR(2000),@cJoinstr VARCHAR(MAX),@cStep VARCHAR(5),@cColList VARCHAR(1000),
			@cCmd NVARCHAR(MAX),@cColListCodes VARCHAR(1000),@cColListBo VARCHAR(1000),@cCurLocId VARCHAR(5),
			@cUploadTable VARCHAR(200),@nSpId VARCHAR(50),
			@nEntrymode NUMERIC(1,0),@cInvoiceMstTable VARCHAR(200),@cInvoiceDetTable VARCHAR(200),@cInvKeyField VARCHAR(50)
	
	SET @nSpId=@cKeyFieldVal
	
	SET @cStep='125.10'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1	 	       
	SELECT TOP 1 @cCurLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
	

	CREATE TABLE #BUYERORDER (inv_qty NUMERIC(10,2),stock_qty NUMERIC(10,2),order_qty NUMERIC(10,2),
	pending_pl_qty NUMERIC(10,2),article_no varchar(300),section_name varchar(300),sub_section_name varchar(300),
	para1_name varchar(300),para2_name varchar(300),para3_name varchar(300),para4_name varchar(300),
	para5_name varchar(300),para6_name varchar(300),article_code CHAR(9),section_code  CHAR(7),
	sub_section_code  CHAR(7),para1_code CHAR(9),para2_code CHAR(9),para3_code CHAR(9),para4_code CHAR(9),
	para5_code CHAR(9),para6_code CHAR(9))

	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-2'
    CREATE TABLE #BuyerOrderInvQty (order_row_id VARCHAR(40),inv_qty NUMERIC(10,2))

	SET @cStep='125.15'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	IF @cXntype='WSL' AND @nUpdatemode IN (1,2)
		SELECT @nEntrymode=entry_mode FROM wsl_inm01106_upload (NOLOCK) WHERE sp_id=@cKeyFieldVal 		
	ELSE
	IF @cXntype='WSL' AND @nUpdatemode NOT IN (1,2)
		SELECT @nEntrymode=entry_mode FROM inm01106 (NOLOCK) WHERE inv_id=@cKeyFieldVal 		
	ELSE
	IF @cXntype='WPS' AND @nUpdatemode IN (1,2)
		SELECT @nEntrymode=entry_mode FROM wps_wps_mst_upload (NOLOCK) WHERE sp_id=@cKeyFieldVal 
	ELSE
	IF @cXntype='WPS' AND @nUpdatemode NOT IN (1,2)
		SELECT @nEntrymode=entry_mode FROM wps_mst (NOLOCK) WHERE ps_id=@cKeyFieldVal 		
	
	IF @cXnType='WPS' AND @nEntrymode=2 --- Have to do this in  special case of Pack slip because application is
		SET @nEntrymode=1				--- giving entrymode=2 for box entry pack slip and 1 in case opf box entry thru Invoice
		
		
	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-3:'+@cKeyFieldVal
	IF @nEntrymode in(3,4)
	BEGIN		
		SET @cStep='125.20'
EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
		EXEC SP3S_UPDATE_WOD_INV_QTY 
		@CKEYFIELDVAL=@cKeyFieldVal,
		@NREVERTFLAG=@nRevertFlag,
		@cXnType=@cXnType,
		@NUPDATEMODE=@NUPDATEMODE,
		@NBOXNO=@NBOXNO,
		@CPRODUCTCODE=@CPRODUCTCODE,
		@CERRORMSG=@CERRORMSG OUTPUT 

		IF @nRevertFlag=1 OR ISNULL(@CERRORMSG,'')<>''
			GOTO END_PROC
	END	

	set @cStep='125.22'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	IF NOT EXISTS (SELECT TOP 1 order_id FROM buyer_order_mst (NOLOCK) WHERE memo_type=2 AND cancelled=0)
		RETURN

	IF NOT EXISTS (SELECT TOP 1 inv_id FROM wsl_inm01106_upload (NOLOCK) WHERE sp_id=@cKeyFieldVal AND entry_mode IN (1,3)) AND @cXntype='WSL'
		RETURN
	
	
	SELECT @cInvoiceMstTable=(CASE WHEN @cXnType='WSL' THEN 'inm01106' ELSE 'wps_mst' END),
		   @cInvoiceDetTable=(CASE WHEN @cXnType='WSL' THEN 'ind01106' ELSE 'wps_det' END),
		   @cInvKeyField=(CASE WHEN @cXnType='WSL' THEN 'inv_id' ELSE 'ps_id' END),
		   @cUploadTable=(CASE WHEN @cXnType='WSL' THEN 'wsl_ind01106_upload' ELSE 'wps_wps_det_upload' END)

	print 'enter SP3S_VALIDATE_INV_PICKLIST_QTY : step-4:'+@cKeyFieldVal

	SELECT @cConfigCols = coalesce(@cConfigCols+',','')+'a.'+COLUMN_NAME from CONFIG_BUYERORDER (NOLOCK) 
	WHERE isnull(open_key,0)=1

	SET @cStep='125.25'
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	SELECT @cJoinstr=' b.article_no=c.article_no '+
	    (CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ' AND b.section_name=c.section_name ' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ' AND b.sub_section_name=c.sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ' AND b.para1_name=c.para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ' AND b.para2_name=c.para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ' AND b.para3_name=c.para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ' AND b.para4_name=c.para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ' AND b.para5_name=c.para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ' AND b.para6_name=c.para6_name ' ELSE '' END)

	SET @cColList='article_no'
	SET @cStep='125.30'	
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	SELECT @cColList=@cColList+
		(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',section_name' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',sub_section_name ' ELSE '' END)+
		(CASE WHEN charindex('ARTICLE_NAME',@cConfigCols)>0 THEN  ',article_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',para1_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',para2_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',para3_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',para4_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',para5_name ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',para6_name ' ELSE '' END)
	
	SET @cColListBo='c.'+REPLACE(@cColList,',',',c.')

	SET @cStep='125.35'	
	EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
	SELECT @cColListCodes='sku.article_code'+
		(CASE WHEN charindex('SECTION_NAME',@cConfigCols)>0 THEN  ',section_code' ELSE '' END)+
		(CASE WHEN charindex('SUB_SECTION_NAME',@cConfigCols)>0 THEN  ',sectiond.sub_section_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA1_NAME',@cConfigCols)>0 THEN  ',sku.para1_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA2_NAME',@cConfigCols)>0 THEN  ',sku.para2_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA3_NAME',@cConfigCols)>0 THEN  ',sku.para3_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA4_NAME',@cConfigCols)>0 THEN  ',sku.para4_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA5_NAME',@cConfigCols)>0 THEN  ',sku.para5_code ' ELSE '' END)+
		(CASE WHEN charindex('PARA6_NAME',@cConfigCols)>0 THEN  ',sku.para6_code ' ELSE '' END)	
	
	 IF @nEntrymode IN (1,3)
	 BEGIN
		SET @cStep='125.40'
		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
		SET @cCmd=N'INSERT INTO #BUYERORDER (stock_qty,order_qty,pending_pl_qty,inv_qty,'+@cColList+','+
					REPLACE(REPLACE(@cColListCodes,'sku.',''),'sectiond.','')+')
					SELECT 0 as stock_qty, 0 as order_qty,0 pending_pl_qty,SUM(quantity) inv_qty,'+
					REPLACE(REPLACE(@cColList,'article_no','b.article_no'),'sub_section_name','b.sub_section_name')+','+
					@cColListCodes+'
					FROM '+@cUploadTable+' a (NOLOCK)
					JOIN sku_names b (NOLOCK) ON b.product_code=a.product_code
					JOIN sku (NOLOCK) ON sku.product_code=a.product_code
					JOIN article (NOLOCK) ON article.article_code=sku.article_code
					JOIN sectiond (NOLOCK) ON article.sub_section_code=sectiond.sub_section_code
					WHERE a.sp_id='''+@cKeyFieldval+'''
					GROUP BY '+REPLACE(REPLACE(@cColList,'article_no','b.article_no'),'sub_section_name','b.sub_section_name')+','+
					@cColListCodes
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF @nEntrymode=1
	BEGIN
	
		SET @cInvId=''
		IF @nUpdatemode=2
		BEGIN
			IF @cXnType='WSL'
				SELECT @cInvId=inv_id FROM WSL_IND01106_UPLOAD (NOLOCK) WHERE sp_id=@cKeyFieldval
			ELSE
				SELECT @cInvId=ps_id FROM WPS_WPS_DET_UPLOAD (NOLOCK) WHERE sp_id=@cKeyFieldval
		END
		SET @cStep='125.42'	
		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
		SET @cCmd=N'UPDATE a SET pending_pl_qty=b.pending_pl_qty,order_qty=b.order_qty FROM 
					#BUYERORDER a JOIN 
					(SELECT '+@cColListBo+',SUM(b.quantity) order_qty,SUM(isnull(b.pl_qty,0)-isnull(b.inv_qty,0)) pending_pl_qty
					 FROM buyer_order_det b (NOLOCK)
					 JOIN buyer_order_mst a (NOLOCK) ON a.order_id=b.order_id 
					 JOIN #BUYERORDER c ON '+REPLACE(Replace(@cJoinstr,'_name','_code'),'_no','_code')+'
					 WHERE memo_type=2 and isnull(a.Short_close,0)=0
					 GROUP BY '+@cColListBo+') b ON '+REPLACE(@cJoinstr,'c.','a.')

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		IF NOT EXISTS (SELECT TOP 1 * FROM #BUYERORDER WHERE ISNULL(order_qty,0)>0)
			RETURN

		SET @cStep='125.45'	
		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
		SET @cCmd=N'UPDATE a SET stock_qty=b.stock_qty FROM 
					#BUYERORDER a JOIN 
					(SELECT '+REPLACE(@cColListBo,'c.','d.')+',SUM(e.quantity_in_stock) stock_qty 
					 FROM pmt01106 e (NOLOCK) 
					 JOIN sku_names d (NOLOCK) ON d.product_code=e.product_code
					 WHERE '+REPLACE(REPLACE(@cColListBo,',','+'),'c.','d.')+ '
					 IN (SELECT DISTINCT '+REPLACE(@cColListBo,',','+')+' FROM 
					 #BUYERORDER c 
					 JOIN BUYER_ORDER_DET b (NOLOCK) ON '+REPLACE(Replace(@cJoinstr,'_name','_code'),'_no','_code')+'
					 JOIN buyer_order_mst a (NOLOCK) ON a.order_id=b.order_id 
					 WHERE memo_type=2 AND a.cancelled=0 GROUP BY '+@cColListBo+'
					 )
					 AND e.dept_id='''+@cCurLocId+''' AND e.bin_id<>''999'' AND quantity_in_stock>0
					 GROUP BY '+REPLACE(@cColListBo,'c.','d.')+') b ON '+REPLACE(@cJoinstr,'c.','a.')

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd



		--if @@spid=96
		--	select * from #BUYERORDER

		IF EXISTS (SELECT TOP 1 * FROM #BUYERORDER WHERE isnull(inv_qty,0)>(isnull(stock_qty,0)-isnull(pending_pl_qty,0)) AND isnull(pending_pl_qty,0)>0)
		BEGIN
			SET @cStep='125.47'
			EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
			SET @cErrormsg='Invoice quantity cannot be more that Pick List pending qty..'
			SET @cCmd=N'SELECT '+@cColList+',stock_qty,order_qty,pending_pl_qty [Allocate Stock],inv_qty,
						(inv_qty-(isnull(stock_qty,0)-isnull(pending_pl_qty,0))) variance,
						'''+@cErrormsg+''' errmsg,'''' memo_id FROM 
						#BUYERORDER WHERE isnull(inv_qty,0)>(isnull(stock_qty,0)-isnull(pending_pl_qty,0)) 
						AND isnull(pending_pl_qty,0)>0'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
			SET @bOrderValidationFailed=1
		END
	END
	ELSE
	IF @nEntrymode=3
	BEGIN
		SET @cStep='125.50'		
		EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
		SET @cCmd=N'UPDATE a SET inv_qty=a.inv_qty+b.inv_qty FROM 
					#BUYERORDER a JOIN 
					(SELECT '+@cColListBo+',SUM(quantity) inv_qty FROM '+@cInvoiceDetTable+' b (NOLOCK)
					 JOIN '+@cInvoiceMstTable+' a (NOLOCK) ON a.'+@cInvKeyField+'=b.'+@cInvKeyField+'
					 JOIN sku_names d (NOLOCK) ON d.product_code=b.product_code
					 JOIN #BUYERORDER c ON '+REPLACE(@cJoinstr,'b.','d.')+'
					 WHERE a.'+@cInvKeyField+'<>'''+@cInvId+''' AND a.cancelled=0 
					 GROUP BY '+@cColListBo+') b ON '+REPLACE(@cJoinstr,'c.','a.')

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		IF EXISTS (SELECT TOP 1 a.row_id FROM BUYER_ORDER_DET a (NOLOCK) 
					JOIN #BuyerOrderInvqty b ON a.row_id=b.order_row_id
					JOIN buyer_order_mst c (NOLOCK) ON a.order_id=c.order_id
					WHERE a.inv_qty>a.pl_qty	AND c.memo_type=2)
		BEGIN
			SET @cStep='125.55'
			EXEC SP_CHKXNSAVELOG @cXnType,@cStep,1,@nSpId,'',1
			SET @cErrormsg='Invoice quantity cannot be more than Pick List qty'
			SET @cCmd=N'SELECT '+@cColList+',b.INV_QTY,b.pl_qty as pick_list_qty,'''+@cErrormsg+''' errmsg,'''' memo_id,
					(b.inv_qty-isnull(b.pl_qty,0)) variance
					FROM  BUYER_ORDER_DET b (NOLOCK) 
					JOIN #BuyerOrderInvqty a ON b.row_id=a.order_row_id
					JOIN buyer_order_mst d (NOLOCK) ON b.order_id=d.order_id
					JOIN #BUYERORDER  c (NOLOCK) ON '+REPLACE(Replace(@cJoinstr,'_name','_code'),'_no','_code')+'
					WHERE b.inv_qty>b.pl_qty	AND d.memo_type=2'

			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd

			SET @bOrderValidationFailed=1
		END
	END	 

	GOTO END_PROC
END TRY

BEGIN CATCH
	
	SET @cErrormsg='Error in Procedure SP3S_VALIDATE_INV_PICKLIST_QTY at Step#'+@cStep+' '+error_message()
	print 'enter catch of SP3S_VALIDATE_INV_PICKLIST_QTY'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

END