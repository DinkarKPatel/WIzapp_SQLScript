CREATE FUNCTION FN_CheckNamesLM 
(  
@cAcCode varchar(10),  
@cAcName varchar(100)   
) 
RETURNS bit 
AS 
BEGIN  

	DECLARE @lRetVal bit  

	SET @lRetVal = 1   
	IF EXISTS ( SELECT AC_CODE  FROM LM01106 (NOLOCK) WHERE AC_NAME= @CACNAME  AND AC_CODE   <> @CACCODE      AND LEFT(AC_CODE,2) = LEFT(@CACCODE,2) )   
	 SET @lRetVal = 0  
       
 RETURN  @lRetVal
END 

