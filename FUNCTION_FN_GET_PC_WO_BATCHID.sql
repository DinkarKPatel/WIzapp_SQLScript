CREATE FUNCTION DBO.FN_GET_PC_WO_BATCHID(@PRODUCT_CODE VARCHAR(50))
RETURNS VARCHAR(50)
AS
BEGIN
	  RETURN  @PRODUCT_CODE 
	---Discarded due to slow speed found at Cloud Server (25-03-2019)	  
--      DECLARE @CPRODUCT_CODE VARCHAR(50)
      
--      IF CHARINDEX('@',@PRODUCT_CODE)>0
--      BEGIN
--		   IF LEN(@PRODUCT_CODE)>0
--		   BEGIN
--		   SELECT @CPRODUCT_CODE=SUBSTRING(@PRODUCT_CODE,1,CHARINDEX('@',@PRODUCT_CODE)-1)
--		   END
--      END
--      ELSE
--        SET @CPRODUCT_CODE=@PRODUCT_CODE
       
      
       
--RETURN  @CPRODUCT_CODE    
      
END
