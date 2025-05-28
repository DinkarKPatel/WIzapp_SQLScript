CREATE PROCEDURE SP3S_UPDATE_PMTSTOCK_SLS
@nSpId VARCHAR(40),
@nUpdatemode NUMERIC(1,0),
@bREvertFlag BIT,
@BALLOWNEGSTOCK BIT,
@BNEGSTOCKFOUND BIT OUTPUT,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(20),@bNewEntry BIT,@cDonotChkStockSisLoc VARCHAR(2)
	
	set @CERRORMSG=''

	set @cStep='5'

	SELECT TOP 1 @cDonotChkStockSisLoc=value FROM  config (NOLOCK) WHERE config_option='donot_checkstock_sisloc'

	SET @cDonotChkStockSisLoc=ISNULL(@cDonotChkStockSisLoc,'')

	set @cStep='10'
	SET @bNewEntry=(CASE WHEN @bRevertFlag=1 THEN 0 ELSE 1 END)

	
      IF EXISTS (SELECT TOP 1 'U'  FROM SLS_CMM01106_UPLOAD (NOLOCK) WHERE SP_ID=@nSpId AND MANUAL_BILL=1)
	  SET @BALLOWNEGSTOCK=1
BEGIN TRY
-- UPDATING STOCK OF PMT W.R.T. CURRENT MEMO
	SET @cStep = 178		-- UPDATING PMT TABLE
	EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1
		
	 /*NO NEED TO UPDATE STOCK FOR ENTRY MODE 2 AS IT IS THRU PACKSLIP*/
	SET @cStep = 182
	EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1

	 INSERT PMT01106	( BIN_ID, DEPT_ID, DEPT_ID_NOT_STUFFED, last_update, product_code, quantity_in_stock, rep_id, STOCK_RECO_QUANTITY_IN_STOCK )  
    SELECT 	a.bin_id  BIN_ID,a.dept_id  DEPT_ID,'' DEPT_ID_NOT_STUFFED,getdate() last_update,a. product_code,0 quantity_in_stock,'' rep_id, 0STOCK_RECO_QUANTITY_IN_STOCK 
	FROM  SAVETRAN_BARCODE_NETQTY  (NOLOCK)  a
	left join PMT01106 b (nolock) on a.product_code =b.product_code and a.dept_id =b.dept_id and a.bin_id =b.bin_id 
	WHERE SP_ID=@NSPID AND NEW_ENTRY=@BNEWENTRY and b.product_code is null
	group by a.PRODUCT_CODE,a.DEPT_ID,a.BIN_ID
	

	SET @cStep = 182.4
	EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1
	--UPDATING STOCK IN PMT01106
	UPDATE A
	SET QUANTITY_IN_STOCK=QUANTITY_IN_STOCK-XN_QTY
	FROM PMT01106 A WITH (ROWLOCK)
	JOIN 
	(SELECT product_code,dept_id,bin_id,ISNULL(xn_bo_order_id,'') bo_order_id, SUM(xn_qty) as xn_qty from  SAVETRAN_BARCODE_NETQTY  (nolock)  
	 WHERE SP_ID=@nSpId AND new_entry=@bNewEntry
	 GROUP BY product_code,dept_id,bin_id,ISNULL(xn_bo_order_id,'') ) b ON A.product_code=B.product_code AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID
	 AND ISNULL(a.bo_order_id,'')=b.bo_order_id
	

	SET @cStep = 184
	EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1			

	--if @@spid=94
	--	select @BALLOWNEGSTOCK ALLOWNEGSTOCK,@nUpdatemode updatemode,@bREvertFlag REvertFlag,@cDonotChkStockSisLoc DonotChkStockSisLoc,
	--	b.* FROM  SAVETRAN_BARCODE_NETQTY B (nolock) 
	--	WHERE sp_id=@nSpId
				  --ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
				  --AND ISNULL(a.bo_order_id,'')=ISNULL(b.xn_bo_order_id,'')
				  --join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
				  --join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
				  --join location loc (nolock) on loc.dept_id =a.DEPT_ID 
				  --WHERE sp_id=@nSpId

	IF @BALLOWNEGSTOCK=0 AND NOT (@nUpdatemode=2 AND @bREvertFlag=1) AND @nUpdatemode<>3
	BEGIN
		IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN SAVETRAN_BARCODE_NETQTY B (nolock) 
				  ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
				  AND ISNULL(a.bo_order_id,'')=ISNULL(b.xn_bo_order_id,'')
				  join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
				  join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
				  join location loc (nolock) on loc.dept_id =a.DEPT_ID 
				  WHERE sp_id=@nSpId and (isnull(loc.sis_loc,0)=0 OR @cDonotChkStockSisLoc<>'1') AND A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0
				  )
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN SAVETRAN_BARCODE_NETQTY B (NOLOCK) ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID AND ISNULL(a.bo_order_id,'')=ISNULL(b.xn_bo_order_id,'')
			join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
		    join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
			join location loc (nolock) on loc.dept_id =a.DEPT_ID 
			WHERE sp_id=@nSpId and (isnull(loc.sis_loc,0)=0 OR @cDonotChkStockSisLoc<>'1') AND A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0

					  
			SET @BNEGSTOCKFOUND=1
			SET @cErrormsg='Stock going negative'
		END
	END


	IF @nUpdatemode=3 AND @BALLOWNEGSTOCK=0
	BEGIN

	     IF EXISTS(SELECT TOP 1 'U' FROM PMT01106 A (NOLOCK) JOIN
		        (
				   select product_code,DEPT_ID,BIN_ID,ISNULL(b.xn_bo_order_id,'') bo_order_id ,sum(XN_QTY)  as XN_QTY
				     from SAVETRAN_BARCODE_NETQTY B (nolock) 
				     WHERE sp_id=@nSpId 
				     group by product_code,DEPT_ID,BIN_ID,ISNULL(b.xn_bo_order_id,'')
					 having sum(XN_QTY)>0
				  ) b ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID 
				  AND ISNULL(a.bo_order_id,'')=b.bo_order_id
				  join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
				  join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
				  join location loc (nolock) on loc.dept_id =a.DEPT_ID 
				  where  A.quantity_in_stock<0 and (isnull(loc.sis_loc,0)=0 OR @cDonotChkStockSisLoc<>'1') AND ISNULL(ART.STOCK_NA,0)=0)
		BEGIN	
			SET @cStep = 186
			EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@nSpId,'',1			
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,'STOCK is GOING NEGATIVE' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			join (
				   select product_code,DEPT_ID,BIN_ID,ISNULL(b.xn_bo_order_id,'') bo_order_id ,sum(XN_QTY)  as XN_QTY
				     from SAVETRAN_BARCODE_NETQTY B (nolock) 
				     WHERE sp_id=@nSpId 
				     group by product_code,DEPT_ID,BIN_ID,ISNULL(b.xn_bo_order_id,'') 
					 having sum(XN_QTY)>0
			) b ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.BIN_ID AND ISNULL(a.bo_order_id,'')=b.bo_order_id
			join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
		    join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
			join location loc (nolock) on loc.dept_id =a.DEPT_ID 
			WHERE   A.quantity_in_stock<0 and (isnull(loc.sis_loc,0)=0 OR @cDonotChkStockSisLoc<>'1') AND ISNULL(ART.STOCK_NA,0)=0
					  
			SET @BNEGSTOCKFOUND=1
			SET @cErrormsg='Stock going negative'
		END

	END

	GOTO END_PROC
END TRY

BEGIN CATCH	
	SET @cErrormsg='Error in SP3S_UPDATE_PMTSTOCK_SLS at Step#'+@cStep +' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END
