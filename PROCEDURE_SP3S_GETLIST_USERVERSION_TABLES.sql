CREATE PROCEDURE SP3S_GETLIST_USERVERSION_TABLES
@cUserCodePara CHAR(7)
AS
BEGIN
	SELECT *,UPPER(table_name+'_'+module_name+'_'+@cUserCodePara) AS [TEMP_TABLE_NAME] FROM  modules_tables (NOLOCK)  
END