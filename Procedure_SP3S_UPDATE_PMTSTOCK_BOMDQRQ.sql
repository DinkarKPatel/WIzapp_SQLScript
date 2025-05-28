create PROCEDURE SP3S_UPDATE_PMTSTOCK_BOMDQRQ
@nUpdatemode numeric(1,0)=0,
@CERRORMSG varchar(1000) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5),@bNewEntry BIT,@bAllowNegStock BIT

	SET @bAllowNegStock=0

	BEGIN TRY
-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE

	INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK,bo_order_id  )  
    SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0 STOCK_RECO_QUANTITY_IN_STOCK ,
	       a.BO_ORDER_ID
	FROM  #BARCODE_NETQTY  (NOLOCK)  a
	left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id AND ISNULL(A.bo_order_id ,'')=ISNULL(B.bo_order_id ,'')
	WHERE  b.product_code is null and a. product_code<>''
	group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID,a.BO_ORDER_ID
	


		
	SET @cStep = 182
	
	--UPDATING STOCK IN PMT01106
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK+ISNULL(XN_QTY,0)
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID AND ISNULL(A.bo_order_id ,'')=ISNULL(B.bo_order_id ,'')
	WHERE   b. product_code<>''

	
	IF @BALLOWNEGSTOCK=0 
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code
					AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID AND ISNULL(A.bo_order_id ,'')=ISNULL(B.bo_order_id ,'')
					WHERE A.quantity_in_stock<0 )
		BEGIN	
			SET @cStep = 186
			
			set @CERRORMSG='Stock Going Negative'
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #BARCODE_NETQTY B ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID  AND ISNULL(A.bo_order_id ,'')=ISNULL(B.bo_order_id ,'')
			WHERE  A.quantity_in_stock<0 	
		
		END
	END
   		
END TRY
	BEGIN CATCH
		SET @CERRORMSG = 'STEP- ' + LTRIM(RTRIM((@cStep))) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
END CATCH
	


END