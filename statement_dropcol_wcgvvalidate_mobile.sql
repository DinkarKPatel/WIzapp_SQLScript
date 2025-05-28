IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME='wc_gv_validate'
			and COLUMN_NAME='mobile')
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'alter table wc_gv_validate drop column mobile'
	EXEC SP_EXECUTESQL @cCmd
END


