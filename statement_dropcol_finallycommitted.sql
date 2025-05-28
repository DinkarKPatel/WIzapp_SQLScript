select a.table_name into #tmpDropCol FROM information_schema.columns a (NOLOCK)
join information_schema.tables b  (NOLOCK) on a.table_name=b.table_name WHERE column_name='finally_committed'
and table_type='base table'
DECLARE @cCmd NVARCHAR(MAX),@cTableName VARCHAR(200)

WHILE EXISTS (SELECT TOP 1 table_name FROM  #tmpDropCol)
BEGIN
	SELECT TOP 1 @cTableName=table_name FROM #tmpDropCol

	SET @cCmd=N'ALTER TABLE '+@cTableName+' DROP COLUMN finally_committed'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	DELETE FROM #tmpDropCol WHERE table_name=@cTableName
END



