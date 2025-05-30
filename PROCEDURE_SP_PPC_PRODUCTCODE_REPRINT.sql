CREATE PROCEDURE SP_PPC_PRODUCTCODE_REPRINT
(
 @FMCPRODUCT_CODE VARCHAR(50),
 @TOCPRODUCT_CODE VARCHAR(50),
 @CMEMO_ID VARCHAR(50)
)
AS
BEGIN
    DECLARE @NISNUMERIC INT,@NFMSR NUMERIC(10,0),@NTOSR NUMERIC(10,0)
    
    SET @NISNUMERIC=0
    SET @NFMSR=SUBSTRING(@FMCPRODUCT_CODE,3,LEN(@FMCPRODUCT_CODE))
    SET @NTOSR=SUBSTRING(@TOCPRODUCT_CODE,3,LEN(@TOCPRODUCT_CODE))
    
    IF ISNUMERIC(@NFMSR)=1 AND ISNUMERIC(@NTOSR)=1
    SET @NISNUMERIC=1

IF @NISNUMERIC=1
     SELECT * FROM 
     VW_SPPPC_FG_BAROCDE_PRINT
     WHERE MEMO_ID =@CMEMO_ID
     AND CAST( SUBSTRING(PRODUCT_CODE ,3,LEN(PRODUCT_CODE)) AS NUMERIC (10,0))
     BETWEEN @NFMSR AND @NTOSR
ELSE
 SELECT * FROM 
     VW_SPPPC_FG_BAROCDE_PRINT
     WHERE MEMO_ID =@CMEMO_ID
     AND PRODUCT_CODE BETWEEN  @FMCPRODUCT_CODE AND @TOCPRODUCT_CODE

END
