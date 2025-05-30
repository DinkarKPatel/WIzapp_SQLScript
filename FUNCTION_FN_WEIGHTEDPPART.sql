CREATE FUNCTION FN_WEIGHTEDPPART
 ( @CARTICLENO VARCHAR(50), 
   @DUPTODATE DATETIME,  
   @NMODE NUMERIC(1)=1 )  
RETURNS NUMERIC(12,4)  
--WITH ENCRYPTION
AS  
BEGIN  
	DECLARE @NPURPRICE NUMERIC(10,2)

	SELECT @NPURPRICE = AVG( DBO.FN_WEIGHTEDPP( A.PRODUCT_CODE, @DUPTODATE, @NMODE ))
		FROM SKU A
		JOIN ARTICLE B ON A.ARTICLE_CODE = B.ARTICLE_CODE
		WHERE B.ARTICLE_NO = @CARTICLENO

	IF @NPURPRICE IS NULL
		SET @NPURPRICE = 0

	RETURN @NPURPRICE
END
