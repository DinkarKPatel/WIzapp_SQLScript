DECLARE @cCmd NVARCHAR(MAX)
select 'alter table '+table_name+' drop column '+column_name as cmd into #tmpDropCmd from INFORMATION_SCHEMA.COLUMNS
where table_name not like '%attr1_mst%' and column_name in ('attr1_alias','attr1_inactive')


WHILE EXISTS (SELECT TOP 1 cmd from #tmpDropCmd)
BEGIN
	SELECT @cCmd=cmd from #tmpDropCmd

	EXEC SP_EXECUTESQL @cCmd

	DELETE FROM #tmpDropCmd WHERE cmd=@cCmd
END

