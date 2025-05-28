create PROCEDURE SP3S_UPDATE_PMTSTOCK_WSR
@cMemoId VARCHAR(40),
@bREvertFlag BIT,
@NENTRYMODE NUMERIC(1,0),
@BIS_BIN_TRANSFER BIT,
@nCnType NUMERIC(1,0),
@bAllowNegStock bit=0,
@nSpId VARCHAR(40)='',
@cErrormsg varchar(2000) output,
@BNEGSTOCKFOUND BIT OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT

BEGIN TRY
	
	set @cStep='10'
	set @CERRORMSG=''
	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)

	
-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1

	IF @NENTRYMODE=2 OR @nCntype=2
		RETURN

	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1

	INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
    SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0 STOCK_RECO_QUANTITY_IN_STOCK 
	FROM  #BARCODE_NETQTY  (NOLOCK)  a
	left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id and isnull(b.bo_order_id,'')=''
	WHERE bin_transfer=0 AND NEW_ENTRY=@BNEWENTRY and b.product_code is null
	group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID


	
	--UPDATE A
	--SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK+XN_QTY
	--FROM PMT01106 A WITH (ROWLOCK)
	--JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
	--WHERE bin_transfer=0 /*Rohit 22-12-2022 AND new_entry=@bNewEntry */ and isnull(a.bo_order_id,'')=''

	 UPDATE A  
	 SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK+XN_QTY  
	 FROM PMT01106 A WITH (ROWLOCK)  
	 JOIN 
	 ( 
	  select product_code ,DEPT_ID,BIN_ID,
		   sum(xn_qty) as xn_qty
	  from #BARCODE_NETQTY 
	  where bin_transfer=0
	  and new_entry=@bNewEntry
	  group by product_code ,DEPT_ID,BIN_ID
	 )B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID  
	 WHERE  /*Rohit 22-12-2022 AND new_entry=@bNewEntry */  isnull(a.bo_order_id,'')=''  	 --major Problem come in case of edit credit note  
	 
     



	

	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1			

	IF @bAllowNegStock=0 AND @bREvertFlag=0
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
					WHERE bin_transfer=0 AND A.quantity_in_stock<0 and isnull(a.bo_order_id,'')='')
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE'+(case when @bREvertFlag=1 then '1' else '0' end) AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
			WHERE bin_transfer=0 AND A.quantity_in_stock<0 and isnull(a.bo_order_id,'')=''
			
			set @cErrormsg='Stock Going negative'
			SET @BNEGSTOCKFOUND=1

			goto end_proc
		END
	END

	IF @BIS_BIN_TRANSFER=1
	BEGIN
		SET @cStep = 188
		EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1
		
	--INVOICE MARKED AS BIN_TRANSFER
			
		INSERT PMT01106(last_update,rep_id,product_code,quantity_in_stock,DEPT_ID,BIN_ID) 
		SELECT GETDATE(),'' AS REP_ID,A.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,A.DEPT_ID,A.BIN_ID
		FROM #BARCODE_NETQTY A
		LEFT JOIN PMT01106 B WITH (NOLOCK) ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
		WHERE bin_transfer=1 AND B.product_code IS NULL AND new_entry=@bNewEntry

		SET @cStep = 190
		EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1
			
		--UPDATING STOCK IN PMT01106
		UPDATE A
		SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY
		FROM PMT01106 A WITH (ROWLOCK)
		JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
		WHERE bin_transfer=1 AND new_entry=@bNewEntry

		/*CHECKING IF TARGET BIN STOCK IS NOT GOING NEGATIVE, IF GOING NEGATIVE, SAVING OF 
			MEMO SHOULD NOT BE ALLOWED.*/

			SET @cStep = 192
			EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1
		IF @bAllowNegStock=0 AND @bREvertFlag=0
		BEGIN
			IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code
					    AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
						WHERE bin_transfer=1 AND A.quantity_in_stock<0)
			BEGIN	
					SET @cStep = 194
					EXEC SP_CHKXNSAVELOG 'WSR',@cStep,0,@nSpId,'',1

					SELECT b.xn_qty, A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK GOING NEGATIVE FOR TARGET BIN.' AS ERRMSG
					FROM PMT01106 A WITH (NOLOCK)
					JOIN #BARCODE_NETQTY B ON A.PRODUCT_CODE=B.PRODUCT_CODE 
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
					WHERE  bin_transfer=1 AND A.QUANTITY_IN_STOCK<0
					
					set @cErrormsg='Stock Going negative'
					SET @BNEGSTOCKFOUND=1

					goto end_proc
			END
		END
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_UPDATE_PMTSTOCK_WSR at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
END
