

-- GET ALL DEFINED REGION MASTER
CREATE PROCEDURE SP_WL_PARA4LIST
--WITH ENCRYPTION
AS

	SELECT PARA4_CODE, PARA4_NAME,INACTIVE
	FROM PARA4
	WHERE INACTIVE = 0
	ORDER BY PARA4_NAME
