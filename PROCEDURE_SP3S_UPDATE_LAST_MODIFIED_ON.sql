CREATE PROCEDURE SP3S_UPDATE_LAST_MODIFIED_ON
@CtARGETtALE VARCHAR(100),
@cSourceTable VARCHAR(100),
@cKeyField VARCHAR(100)
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)

	set @cCmd=N'UPDATE a sET last_modified_on=b.last_modified_on FROM '+@CtARGETtALE+
	' a JOIN '+@cSourceTable+' b ON a.'+@cKeyField+'=b.'+@cKeyField
	
	EXEC SP_EXECUTESQL @cCmd
END