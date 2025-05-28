CREATE PROCEDURE SP3S_UPDATE_PMTSTOCK_PUR
@nUpdatemode numeric(1,0)=0,
@bREvertFlag BIT,
@nSpId VARCHAR(40)='',
@BNEGSTOCKFOUND BIT OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT,@bAllowNegStock BIT

	SET @bAllowNegStock=0
	

	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)
	if @bREvertFlag=1 AND @nUpdatemode=2
		set @bAllowNegStock=1

-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1

	INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK,bo_order_id )  
    SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,
	'' rep_id, 0 STOCK_RECO_QUANTITY_IN_STOCK,(CASE WHEN ISNULL(a.bo_order_id,'')='' then null else a.bo_order_id END)
	FROM  #BARCODE_NETQTY  (NOLOCK)  a
	left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
	WHERE NEW_ENTRY=@BNEWENTRY and b.product_code is null and a. product_code<>''
	group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID,a.bo_order_id
	
    
  IF EXISTS (SELECT TOP 1 A.MEMO_ID FROM STMH01106 A WITH (NOLOCK) 
             JOIN PMT01106 B WITH (NOLOCK) ON A.REP_ID=B.REP_ID
			 JOIN #BARCODE_NETQTY C ON C.product_code=B.product_code AND C.DEPT_ID=B.DEPT_ID AND C.BIN_ID=B.BIN_ID and isnull(C.bo_order_id,'')=isnull(b.bo_order_id,'')
			)
  BEGIN
		SELECT DISTINCT 'PUR' AS XN_TYPE,
				C.PRODUCT_CODE,0 AS QUANTITY_IN_STOCK,'FOLLOWING BAR CODES ARE PART OF STOCK RECONCILIATION' AS ERRMSG
			
		FROM STMH01106 A WITH (NOLOCK) 
        JOIN PMT01106 B WITH (NOLOCK) ON A.REP_ID=B.REP_ID
	    JOIN #BARCODE_NETQTY C ON C.product_code=B.product_code AND C.DEPT_ID=B.DEPT_ID AND C.BIN_ID=B.BIN_ID and isnull(C.bo_order_id,'')=isnull(b.bo_order_id,'')
			 			  
		SET @BNEGSTOCKFOUND=1			 
		RETURN					
  END	  
  

		
	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1

	--UPDATING STOCK IN PMT01106
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK+XN_QTY
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
	WHERE new_entry=@bNewEntry and  b. product_code<>''

	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1			

	IF @BALLOWNEGSTOCK=0 and @nUpdatemode<>1
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
					WHERE A.quantity_in_stock<0 )
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'PUR',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID and isnull(a.bo_order_id,'')=isnull(b.bo_order_id,'')
			WHERE  A.quantity_in_stock<0 and new_entry=0	
			
			SET @BNEGSTOCKFOUND=1
		END
	END
   		



END