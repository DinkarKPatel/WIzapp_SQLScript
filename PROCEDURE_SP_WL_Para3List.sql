

-- GET ALL PARA3 VALUE AND PARA3 ORDER
CREATE PROCEDURE SP_WL_PARA3LIST
--WITH ENCRYPTION
AS

	SELECT A.PARA3_CODE, A.PARA3_NAME,INACTIVE
	FROM PARA3 A 
	WHERE A.INACTIVE = 0
	ORDER BY A.PARA3_NAME
--************************* END OF PROCEDURE SP_WL_PARA3LIST
