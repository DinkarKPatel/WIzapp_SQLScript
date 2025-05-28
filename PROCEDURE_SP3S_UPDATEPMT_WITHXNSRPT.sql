
create PROCEDURE SP3S_UPDATEPMT_WITHXNSRPT
@cDbName VARCHAR(100)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN


BEGIN TRY
	IF @cDbName=''
		SET @cDbName=db_name()+'.dbo.'
	
	SET @cErrormsg='this procedure has to be discarded '
	goto END_PROC
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(6)
	BEGIN TRANSACTION	
    
	SET @cStep='10'
    

	print 'view stock'
    
	
   --for cantable online order for reduce stock in without order id
   
   SELECT a.product_code ,a.DEPT_ID ,a.BIN_ID,a.rep_id  ,a.quantity_in_stock as quantity_in_stock,
          a.STOCK_RECO_QUANTITY_IN_STOCK ,a.PhysicalScanQty ,bo_order_id
         into #tmpStockBackup
   FROM PMT01106 A (NOLOCK) 
   where( isnull(a.bo_order_id ,'')<>'' or isnull(a.rep_id,'')<>'' or BIN_ID='999')
   
    truncate table pmt01106
    
    insert into PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK ,
                 PhysicalScanQty,bo_order_id  )  
	 SELECT 	 A. BIN_ID,A. DEPT_ID,'' DEPT_ID_NOT_STUFFED,GETDATE() last_update,A. product_code,
				A.quantity_in_stock ,a.rep_id,a.STOCK_RECO_QUANTITY_IN_STOCK ,a.PhysicalScanQty ,a.bo_order_id
	from #tmpStockBackup A
	
    
    
	
	CREATE TABLE  #PMTXNSUPD1(dept_id VARCHAR(4), product_code varchar(50),bin_id varchar(50),
	ORDER_ID varchar(50),Pick_list_id varchar(50), CBSQty numeric(10,3))
	

	SET @cStep='20'
    SET @cCmd=N'select a.dept_id, product_code,a.bin_id , sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
	''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
	then 1 else -1 end * xn_qty) CBSQty
	from '+@cDbName+'VW_XNSREPS a (nolock) 
	where  xn_type not in (''TRI'', ''TRO'',''sac'',''sau'',''saum'',''sacm'') 
	AND BIN_ID <>''999''
	group by a.dept_id, product_code,a.bin_id 
	having sum(case when xn_type in (''PFI'', ''WSR'', ''APR'', ''CHI'', ''WPR'', ''OPS'', ''DCI'', ''SCF'', ''PUR'', ''UNC'', ''SLR'',
	''JWR'',''DNPR'',''TTM'',''API'',''PRD'', ''PFG'', ''BCG'',''MRP'',''PSB'',''JWR'',''MIR'',''GRNPSIN'',''MAQ'',''OLOAQ'',''CNPI'') 
	then 1 else -1 end * xn_qty)<>0'

	PRINT @cCmd

	INSERT INTO #PMTXNSUPD1 (dept_id,product_code,bin_id,cbsqty)
	EXEC SP_EXECUTESQL @cCmd


	SET @cStep='25'
	SET @cCmd=N'UPDATE A SET purchase_ageing_days = (CASE WHEN isnull(purchase_receipt_dt,'''')='''' then 1 when 
					ABS(DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+''') END),
					shelf_ageing_days=(CASE WHEN isnull(sx.receipt_Dt,'''')='''' then 1 when  ABS(DATEDIFF(dd,sx.receipt_Dt,'''+
					convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,GETDATE(),110)+''')  END)
	FROM '+@cDbName+'PMT01106 A (nolock)
	JOIN #PMTXNSUPD1 C ON A.DEPT_ID=C.DEPT_ID AND A.BIN_ID =C.BIN_ID AND A.PRODUCT_CODE =C.PRODUCT_CODE
	LEFT JOIN  '+@cDbName+'sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
	JOIN '+@cDbName+'sku_names sn (nolock) on sn.product_code=a.product_code
	WHERE ISNULL(C.CBSQTY,0)<>0 AND A.BIN_ID<>''999'''
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cStep='32'
	SET @cCmd=N'UPDATE A SET QUANTITY_IN_STOCK = ISNULL(C.CBSQTY,0),last_update=getdate()  FROM '+@cDbName+'PMT01106 A with (rowlock)
	LEFT JOIN #PMTXNSUPD1 C ON A.DEPT_ID=C.DEPT_ID AND A.BIN_ID =C.BIN_ID AND A.PRODUCT_CODE =C.PRODUCT_CODE 
	WHERE A.QUANTITY_IN_STOCK <>ISNULL(C.CBSQTY,0) AND A.BIN_ID<>''999'' 
	and isnull(a.BO_ORDER_ID,'''')='''' 
	and isnull(a.rep_id,'''')='''' '
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	
	SET @cStep='40'
	 SET @cCmd=N'INSERT '+@cDbName+'PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK  )  
	 SELECT 	 A. BIN_ID,A. DEPT_ID,'''' DEPT_ID_NOT_STUFFED,GETDATE() last_update,A. product_code,
				A.CBSQty quantity_in_stock,'''' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK 				
	 FROM #PMTXNSUPD1 A
	 join '+@cDbName+'location l (nolock) on a.dept_id =l.dept_id 
	 LEFT JOIN '+@cDbName+'pmt01106 B (nolock) ON A.PRODUCT_CODE =B.product_code AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID=B.BIN_ID   AND ISNULL(B.BO_ORDER_ID,'''')=ISNULL(A.ORDER_ID,'''')
	 AND ISNULL(B.Pick_list_id,'''')=ISNULL(A.Pick_list_id,'''')
	 WHERE B.product_code IS NULL'

	 PRINT @cCmd
	 EXEC SP_EXECUTESQL @cCmd
	    
	 --chnages for cantable online order allocation
	 UPDATE A SET QUANTITY_IN_STOCK =A.QUANTITY_IN_STOCK -B.QUANTITY_IN_STOCK
	 FROM  PMT01106 A (NOLOCK)
	 JOIN #tmpStockBackup B ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
	 WHERE   ISNULL(A.BO_ORDER_ID ,'')='' and isnull(a.rep_id,'') =''
	 and ISNULL(b.BO_ORDER_ID ,'')<>''
   
 
	 

	END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'Error in Procedure SP3S_UPDATEPMT_WITHXNSRPT at Step#'+@cStep+ ' ' + ERROR_MESSAGE()
		GOTO END_PROC
	END CATCH
	
END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL(@CERRORMSG,'')='' 
		BEGIN
			COMMIT TRANSACTION
		END	
		ELSE
			ROLLBACK
	END

END
