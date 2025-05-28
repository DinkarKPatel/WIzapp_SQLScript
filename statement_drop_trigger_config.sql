select name into #trgconfig from sys.triggers where object_name(parent_id)='config'

DECLARE @cCmd NVARCHAR(MAX),@cTrgName VARCHAR(500)
while exists (select top 1 * from #trgconfig)
begin
	SELECT top 1 @cTrgName=name from #trgconfig

	SET @cCmd=N'DROP TRIGGER '+@cTrgName
	EXEC SP_EXECUTESQL @cCmd

	delete from #trgconfig where name=@cTrgName
end