IF EXISTS (SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='xtreme_reports_exp_COLS' AND COLUMN_NAME='row_id')
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'ALTER TABLE xtreme_reports_exp_COLS DROP COLUMN row_id'
	EXEC SP_EXECUTESQL @cCmd
END

