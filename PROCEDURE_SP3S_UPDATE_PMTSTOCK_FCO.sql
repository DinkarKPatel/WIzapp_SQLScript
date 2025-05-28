create PROCEDURE SP3S_UPDATE_PMTSTOCK_FCO
@nSpId VARCHAR(40)='',
@nUpdatemode NUMERIC(1,0),
@BALLOWNEGSTOCK BIT,
@cMemoId VARCHAR(40)='',
@nDelBoxNo INT=0,
@cDelBarCode VARCHAR(50)='',
@BNEGSTOCKFOUND BIT OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT,
@BOX_NO    VARCHAR(5)=''
AS
BEGIN
	DECLARE @cStep VARCHAR(20),@cDonotChkStockSisLoc VARCHAR(2),@nLoop INT,@nLoopCnt INT,@cCmd NVARCHAR(MAX),@cBinIdCol VARCHAR(100),@nFactor INT
	
	set @CERRORMSG=''

	set @cStep='5'

	

BEGIN TRY
	IF EXISTS (SELECT TOP 1 product_code FROM SAVETRAN_BARCODE_NETQTY (NOLOCK) WHERE sp_id=@nSpId)
		DELETE FROM SAVETRAN_BARCODE_NETQTY WITH (ROWLOCK) WHERE sp_id=@nSpId
    
	
	set @cStep='10'
	IF @nUpdatemode IN (1,2) 
		INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, bin_transfer, DEPT_ID, new_entry, PRODUCT_CODE, source_bin_id, sp_id, xn_bo_order_id, XN_QTY )  
		SELECT a.item_TARGET_BIN_ID BIN_ID,0 bin_transfer,B.LOCATION_CODE DEPT_ID,1 new_entry, PRODUCT_CODE, source_bin_id,@nSpId sp_id,
		null xn_bo_order_id,a.QUANTITY XN_QTY 
		FROM FCO_FLOOR_ST_DET_UPLOAD a (NOLOCK)
		JOIN FCO_FLOOR_ST_MST_UPLOAD b (NOLOCK) ON a.SP_ID=b.sp_id
		WHERE a.sp_id=@nSpId
    
	IF @nUpdatemode IN (6)
		INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, bin_transfer, DEPT_ID, new_entry, PRODUCT_CODE, source_bin_id, sp_id, xn_bo_order_id, XN_QTY )  
		SELECT a.item_TARGET_BIN_ID BIN_ID,0 bin_transfer,B.location_Code  DEPT_ID,0 new_entry, PRODUCT_CODE, ITEM_TARGET_BIN_ID ,@nSpId sp_id,
		null xn_bo_order_id,a.QUANTITY XN_QTY 
		FROM FLOOR_ST_DET a (NOLOCK)
		JOIN FLOOR_ST_MST b (NOLOCK) ON a.MEMO_ID=b.memo_id
		WHERE a.MEMO_ID=@cMemoId 
		
	
	set @cStep='15'
	IF (@nUpdatemode IN (3) or (@nUpdatemode=2 and @BOX_NO='0'))
		INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, bin_transfer, DEPT_ID, new_entry, PRODUCT_CODE, source_bin_id, sp_id, xn_bo_order_id, XN_QTY )  
		SELECT a.item_TARGET_BIN_ID BIN_ID,0 bin_transfer,B.LOCATION_CODE DEPT_ID,0 new_entry, PRODUCT_CODE, source_bin_id,@nSpId sp_id,
		null xn_bo_order_id,-a.QUANTITY XN_QTY 
		FROM FLOOR_ST_DET a (NOLOCK)
		JOIN FLOOR_ST_MST b (NOLOCK) ON a.MEMO_ID=b.memo_id
		WHERE a.MEMO_ID=@cMemoId
	ELSE
	IF @nUpdatemode IN (4,5)
		INSERT SAVETRAN_BARCODE_NETQTY	( BIN_ID, bin_transfer, DEPT_ID, new_entry, PRODUCT_CODE, source_bin_id, sp_id, xn_bo_order_id, XN_QTY )  
		SELECT a.item_TARGET_BIN_ID BIN_ID,0 bin_transfer,b.location_Code  DEPT_ID,0 new_entry, PRODUCT_CODE, source_bin_id,@nSpId sp_id,
		null xn_bo_order_id,-a.QUANTITY XN_QTY 
		FROM FLOOR_ST_DET a (NOLOCK)
		JOIN FLOOR_ST_MST b (NOLOCK) ON a.MEMO_ID=b.memo_id
		WHERE a.MEMO_ID=@cMemoId AND ((@nUpdatemode=4 AND box_no=@nDelBoxNo) OR (@nUpdatemode=5 AND product_code=@cDelBarCode))

	set @cStep='20'		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'FCO',@cStep,0,@nSpId,'',1
		

	IF @nUpdatemode IN (1,2)
		 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
		SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0STOCK_RECO_QUANTITY_IN_STOCK 
		FROM  SAVETRAN_BARCODE_NETQTY  (NOLOCK)  a
		left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id 
		WHERE SP_ID=@NSPID AND NEW_ENTRY=1 and b.product_code is null
		group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID
	ELSE
		INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
		SELECT 	a.source_bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0STOCK_RECO_QUANTITY_IN_STOCK 
		FROM  SAVETRAN_BARCODE_NETQTY  (NOLOCK)  a
		left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.source_bin_id =b.bin_id 
		WHERE SP_ID=@NSPID AND  b.product_code is null
		group by a.PRODUCT_CODE,a.DEPT_ID,a.source_BIN_ID


	
	set @cStep='30'
	EXEC SP_CHKXNSAVELOG 'FCO',@cStep,0,@nSpId,'',1			

	--UPDATING STOCK IN PMT01106
	SELECT @nLoop=1, @nLoopCnt=2

	IF @NUPDATEMODE =6 --Git receive through Bin Transfer
	  SET @NLOOPCNT=1
	ELSE  IF EXISTS (SELECT TOP 1 'U' FROM FLOOR_ST_MST WHERE isnull(RECEIPT_DT,'')='' and MEMO_ID=@cMemoId) -- only revert Source bin Stock
	   SET @NLOOP=2
	
	

	WHILE @nLoop<=@nLoopCnt
	BEGIN

		SELECT @cBinIdCol=(CASE WHEN @nLoop=1 THEN  'bin_id' ELSE 'source_bin_id' END),
		@nFactor=(CASE WHEN @nLoop=1 THEN -1 ELSE 1 END)
		
	
		if @BALLOWNEGSTOCK=0 and @nFactor=1
		begin
		     
			 PRINT ' CHANGE MESSAGE BEFORE UPDATING PMT '

			 SET @cCmd=N' if exists (select top 1 ''U'' FROM PMT01106 A WITH (ROWLOCK)
				JOIN 
				(
				SELECT product_code,dept_id,'+@cBinIdCol+' bin_id,ISNULL(xn_bo_order_id,'''') bo_order_id, SUM(xn_qty) as xn_qty 
				from  SAVETRAN_BARCODE_NETQTY  (nolock)  
				WHERE SP_ID='''+@nSpId+''' 
				GROUP BY product_code,dept_id,'+@cBinIdCol+',ISNULL(xn_bo_order_id,'''') 
				) b ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
				AND ISNULL(a.bo_order_id,'''')=b.bo_order_id
				JOIN SKU_NAMES C (NOLOCK) ON A.PRODUCT_CODE=C.PRODUCT_CODE 
				where isnull(c.stock_na,0)=0 and  (QUANTITY_IN_STOCK-XN_QTY*'+str(@nFactor)+')<0)
				begin

				    SELECT A.PRODUCT_CODE,(QUANTITY_IN_STOCK-XN_QTY*'+str(@nFactor)+') QUANTITY_IN_STOCK,''Bin STOCK is GOING NEGATIVE'' AS ERRMSG
					FROM PMT01106 A WITH (ROWLOCK)
				    JOIN 
					(
					SELECT product_code,dept_id,'+@cBinIdCol+' bin_id,ISNULL(xn_bo_order_id,'''') bo_order_id, SUM(xn_qty) as xn_qty 
					from  SAVETRAN_BARCODE_NETQTY  (nolock)  
					WHERE SP_ID='''+@nSpId+''' 
					GROUP BY product_code,dept_id,'+@cBinIdCol+',ISNULL(xn_bo_order_id,'''') 
				   )  b ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
					AND ISNULL(a.bo_order_id,'''')=b.bo_order_id
					JOIN SKU_NAMES C (NOLOCK) ON A.PRODUCT_CODE=C.PRODUCT_CODE 
					where isnull(c.stock_na,0)=0 and  (QUANTITY_IN_STOCK-XN_QTY*'+str(@nFactor)+')<0

				  SET @BNEGSTOCKFOUND=1

				end '

			   PRINT @cCmd
		       EXEC SP_EXECUTESQL @cCmd,N'@bNegStockFound BIT OUTPUT',@BNEGSTOCKFOUND OUTPUT

				IF @BNEGSTOCKFOUND=1
				BEGIN
					SET @cErrormsg='Stock going negative'
					GOTO END_PROC
				END

		end

		set @cStep='35'
		EXEC SP_CHKXNSAVELOG 'FCO',@cStep,0,@nSpId,'',1			

		SET @cCmd=N'UPDATE A
		SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY*'+str(@nFactor)+'
		FROM PMT01106 A WITH (ROWLOCK)
		JOIN 
		(SELECT product_code,dept_id,'+@cBinIdCol+' bin_id,ISNULL(xn_bo_order_id,'''') bo_order_id, SUM(xn_qty) as xn_qty from  SAVETRAN_BARCODE_NETQTY  (nolock)  
			WHERE SP_ID='''+@nSpId+''' 
			GROUP BY product_code,dept_id,'+@cBinIdCol+',ISNULL(xn_bo_order_id,'''') ) b ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
			AND ISNULL(a.bo_order_id,'''')=b.bo_order_id'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		

		SET @nLoop=@nLoop+1
	END

	--trigger filrer in stock Going Negative (norspin)
	/*
	SELECT @nLoop=1, @nLoopCnt=2

	IF @NUPDATEMODE =6 --Git receive through Bin Transfer
	  SET @NLOOPCNT=1
	ELSE IF EXISTS (SELECT TOP 1 'U' FROM FLOOR_ST_MST WHERE isnull(RECEIPT_DT,'')='' and MEMO_ID=@cMemoId) -- only revert Source bin Stock
	   SET @NLOOP=2
	
	
	WHILE @nLoop<=@nLoopCnt  
	BEGIN

		set @cStep='40'
		EXEC SP_CHKXNSAVELOG 'FCO',@cStep,0,@nSpId,'',1		
		
			SELECT @cBinIdCol=(CASE WHEN @nLoop=1 THEN  'bin_id' ELSE 'source_bin_id' END)

	--	SET @cBinIdCol=(CASE WHEN @nUpdatemode=1 OR (@nUpdatemode=2 AND @nLoop=1) THEN  'bin_id' ELSE 'source_bin_id' END)

	--at the time of rec git donot show stock going negative discuss with sanjiv sir for nagarmal (20230510)
	if @NUPDATEMODE<>6 and @cBinIdCol='source_bin_id' and @BALLOWNEGSTOCK=0
	begin
		SET @cCmd=N'IF EXISTS(SELECT TOP 1 a.product_Code FROM PMT01106 A (NOLOCK) JOIN SAVETRAN_BARCODE_NETQTY B (nolock) 
					ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.'+@cBinIdCol+' 
					AND ISNULL(a.bo_order_id,'''')=ISNULL(b.xn_bo_order_id,'''')
					join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
					join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
					join location loc (nolock) on loc.dept_id =a.DEPT_ID 
					WHERE sp_id='''+@nSpId+''' AND A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0
					)
		BEGIN	
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,''Bin STOCK is GOING NEGATIVE'' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN SAVETRAN_BARCODE_NETQTY B (NOLOCK) ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.'+@cBinIdCol+' AND ISNULL(a.bo_order_id,'''')=ISNULL(b.xn_bo_order_id,'''')
			join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
			join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
			join location loc (nolock) on loc.dept_id =a.DEPT_ID 
			WHERE sp_id='''+@nSpId+''' AND A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0

					  
			SET @BNEGSTOCKFOUND=1
						
		END'
					
		set @cStep='50'
		EXEC SP_CHKXNSAVELOG 'FCO',@cStep,0,@nSpId,'',1			
				
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@bNegStockFound BIT OUTPUT',@BNEGSTOCKFOUND OUTPUT
    end

		
		IF @BNEGSTOCKFOUND=1
		BEGIN
			SET @cErrormsg='Stock going negative'
			GOTO END_PROC
		END
		
		SET @nLoop=@nLoop+1
	END
	*/
	GOTO END_PROC
END TRY

BEGIN CATCH	
	SET @cErrormsg='Error in SP3S_UPDATE_PMTSTOCK_FCO at Step#'+@cStep +' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END