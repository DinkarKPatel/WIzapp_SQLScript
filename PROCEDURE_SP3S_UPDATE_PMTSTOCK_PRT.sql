create PROCEDURE SP3S_UPDATE_PMTSTOCK_PRT
@cMemoId VARCHAR(40),
@bREvertFlag BIT,
@NENTRYMODE NUMERIC(1,0),
@nDnType NUMERIC(1,0),
@BALLOWNEGSTOCK BIT,
@nSpId VARCHAR(40)='',
@BNEGSTOCKFOUND BIT OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT

	set @CERRORMSG=''

	set @cStep='10'
	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)

	IF @NENTRYMODE=2 OR @nDnType=2
		RETURN

BEGIN TRY
-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'PRT',@cStep,0,@nSpId,'',1
		
	 /*NO NEED TO UPDATE STOCK FOR ENTRY MODE 2 AS IT IS THRU PACKSLIP*/
	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'PRT',@cStep,0,@nSpId,'',1

	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
	 SELECT distinct 	  a.BIN_ID, a.DEPT_ID,'' as  DEPT_ID_NOT_STUFFED, getdate() as last_update,a.product_code  product_code,0 quantity_in_stock,'' rep_id,0 STOCK_RECO_QUANTITY_IN_STOCK 
	 FROM #BARCODE_NETQTY a
	 left join pmt01106 b on a.product_code=b.product_code and a.dept_id=b.DEPT_ID and a.bin_id=b.bin_id and  isnull(b.bo_order_id,'')=''
	 WHERE new_entry=@bNewEntry and  b.product_code is null


	--UPDATING STOCK IN PMT01106
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
	WHERE new_entry=@bNewEntry and  isnull(a.bo_order_id,'')=''



	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'PRT',@cStep,0,@nSpId,'',1			

	IF @BALLOWNEGSTOCK=0
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) 
		  JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
		  join sku_names sn (nolock) on sn.product_Code =a.product_code 
					WHERE  A.QUANTITY_IN_STOCK<0 AND ISNULL(SN.STOCK_NA,0)=0 and  isnull(a.bo_order_id,'')='' )
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'PRT',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code  AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
			join sku_names sn (nolock) on sn.product_Code =a.product_code 
			WHERE  A.quantity_in_stock<0  AND ISNULL(SN.STOCK_NA,0)=0 and  isnull(a.bo_order_id,'')=''
					  
			SET @BNEGSTOCKFOUND=1
			SET @cErrormsg='Stock going negative'
		END
	END

	GOTO END_PROC
END TRY

BEGIN CATCH	
	SET @cErrormsg='Error in SP3S_UPDATE_PMTSTOCK_PRT at Step#'+@cStep +' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END
