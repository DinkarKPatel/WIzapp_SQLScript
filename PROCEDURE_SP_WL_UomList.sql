CREATE PROCEDURE SP_WL_UOMLIST
--WITH ENCRYPTION
AS

	SELECT UOM_CODE, UOM_NAME, UOM_TYPE 
	FROM UOM
	ORDER BY UOM_NAME
--************************** END OF PROCEDURE SP_WL_UOMLIST
