CREATE PROCEDURE SP3SWOW_GETSCHEMA
(
	@cModuleID VARCHAR(10)
)
AS
BEGIN
	IF @cModuleID ='M090'
		SELECT DISTINCT devColumnName,dataType,columnWidth,decimalWidth from WOW_LOCATION_COLUMN
		ELSE
		BEGIN
			SELECT DISTINCT devColumnName,dataType,columnWidth ,decimalWidth
			from WOW_MAP_COLUMNS A
			JOIN WOW_MODULE_TABLES B ON B.tableName=A.tablename
			WHERE B.module_id=@cModuleID
		END
	
END
--EXEC SP3SWOW_GETSCHEMA @cModuleID='M037'