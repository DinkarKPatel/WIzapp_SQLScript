IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns	
		   WHERE table_name='lmp01106' AND column_name='ac_gst_dt')
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'ALTER TABLE lmp01106 DROP COLUMN ac_gst_dt'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END