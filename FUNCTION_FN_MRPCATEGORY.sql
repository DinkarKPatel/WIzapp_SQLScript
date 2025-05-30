CREATE FUNCTION FN_MRPCATEGORY ( @NMRP NUMERIC(14,3),@CGROUPCODE CHAR(5),@CTYPE INT )  
RETURNS VARCHAR(20)  
--WITH ENCRYPTION
AS  
BEGIN  
 DECLARE @CMRPCATG VARCHAR(20)  
  
 SELECT  @CMRPCATG = ISNULL(( SELECT TOP 1 CATEGORY_NAME FROM CATGRPDET A JOIN CATGRPMST B  
         ON A.GROUP_CODE=B.GROUP_CODE WHERE A.GROUP_CODE=@CGROUPCODE AND GROUP_TYPE=@CTYPE  
      AND @NMRP BETWEEN FROMN AND TON  ),'')  
   
  
 RETURN @CMRPCATG  
END
