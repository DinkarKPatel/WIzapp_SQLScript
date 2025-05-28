CREATE PROCEDURE SPWOW_UPDATE_PMTSTOCK_WPS
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(20),@cCmd nvarchar(max),@BNEGSTOCKFOUND bit
	
	set @CERRORMSG=''
	set @cStep='5'

	

BEGIN TRY

	   	INSERT PMT01106	( BIN_ID, DEPT_ID, last_update, product_code, quantity_in_stock )  
		SELECT 	A.BIN_ID  BIN_ID,A.DEPT_ID  DEPT_ID,GETDATE() LAST_UPDATE,A. PRODUCT_CODE,0 QUANTITY_IN_STOCK 
		FROM  #TMPPMTSTOCK_WPS   A
		LEFT JOIN PMT01106 B (NOLOCK) ON A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
		WHERE B.PRODUCT_CODE  IS NULL
		GROUP BY A.PRODUCT_CODE,A.DEPT_ID,A.BIN_ID

		UPDATE A   SET QUANTITY_IN_STOCK=A.QUANTITY_IN_STOCK+B.XN_QTY
		FROM PMT01106 A (NOLOCK)
		JOIN
		(
			SELECT A.BIN_ID  BIN_ID,A.DEPT_ID  DEPT_ID,A. PRODUCT_CODE,SUM(XN_QTY) XN_QTY 
			FROM #TMPPMTSTOCK_WPS A
			GROUP BY A.BIN_ID  ,A.DEPT_ID  ,A. PRODUCT_CODE
		) B ON  A.PRODUCT_CODE =B.PRODUCT_CODE AND A.DEPT_ID =B.DEPT_ID AND A.BIN_ID =B.BIN_ID 
	  
	  set @cStep='10'
		SET @cCmd=N'IF EXISTS(SELECT TOP 1 a.product_Code FROM PMT01106 A (NOLOCK) JOIN #TMPPMTSTOCK_WPS B 
					ON A.product_code=B.product_code	AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.bin_id 
					join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
					join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
					join location loc (nolock) on loc.dept_id =a.DEPT_ID 
					WHERE  A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0
					)
		BEGIN	
					  
			SELECT A.PRODUCT_CODE,A.QUANTITY_IN_STOCK,''Bin STOCK is GOING NEGATIVE'' AS ERRMSG
			FROM PMT01106 A WITH (NOLOCK)
			JOIN #TMPPMTSTOCK_WPS  B  ON A.product_code=B.product_code 
			AND A.DEPT_ID=B.DEPT_ID AND A.BIN_ID=B.bin_id 
			join sku (nolock) on b.PRODUCT_CODE =sku.product_code 
			join ARTICLE art (nolock) on art.ARTICLE_CODE =SKU.article_code
			join location loc (nolock) on loc.dept_id =a.DEPT_ID 
			WHERE  A.quantity_in_stock<0 AND ISNULL(ART.STOCK_NA,0)=0

					  
			SET @BNEGSTOCKFOUND=1
						
		END'
					
		set @cStep='50'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@bNegStockFound BIT OUTPUT',@BNEGSTOCKFOUND OUTPUT


		
		IF @BNEGSTOCKFOUND=1
		BEGIN
			SET @cErrormsg='Stock going negative'
			GOTO END_PROC
		END
		
	
	GOTO END_PROC
END TRY

BEGIN CATCH	
	SET @cErrormsg='Error in SPWOW_UPDATE_PMTSTOCK_WPS at Step#'+@cStep +' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END

