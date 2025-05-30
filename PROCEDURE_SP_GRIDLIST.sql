CREATE PROCEDURE SP_GRIDLIST

(
	@CMODULE VARCHAR(100),
	@CUSERCODE VARCHAR(10)
)
--WITH ENCRYPTION
AS

BEGIN
----- PROCEDURE TO STORE GRID SETTINGS OF EACH USER

SELECT A.USERROLE_ID,COL_DISPLAY_NAME ,COL_DATA_SOURCE ,ACCESS 
FROM  USERROLE_COL_DET A (NOLOCK)
JOIN
(
SELECT TOP 1 A.USERROLE_ID 
FROM  USERROLE_MST A(NOLOCK) 
JOIN USERROLE_USERS B (NOLOCK) ON A.USERROLE_ID = B.USERROLE_ID 
WHERE A.MODULE_NAME = @CMODULE AND B.USER_CODE= @CUSERCODE AND A.CANCELLED=0
ORDER BY A.LAST_UPDATE DESC
) B ON A.USERROLE_ID = B.USERROLE_ID 
WHERE  A.ACCESS =1


END
