DECLARE @cCmd NVARCHAR(MAX)
if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='temp_row_id' and TABLE_NAME='sls_cmd01106_upload')
BEGIN
	SET @cCmd=N'alter table sls_cmd01106_upload alter column temp_row_id varchar(50)'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='LAST_SLS_DISCOUNT_PERCENTAGE' and TABLE_NAME='sls_cmd01106_upload')
BEGIN
	SET @cCmd=N'alter table sls_cmd01106_upload alter column LAST_SLS_DISCOUNT_PERCENTAGE numeric(6,2)'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='sp_id' and TABLE_NAME='sls_custdym_upload')
BEGIN
	SET @cCmd=N'alter table sls_custdym_upload alter column sp_id varchar(40)'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select * from INFORMATION_SCHEMA.COLUMNS where COLUMN_NAME='sp_id' and TABLE_NAME='sls_dailogfile_upload')
BEGIN
	SET @cCmd=N'alter table sls_dailogfile_upload alter column sp_id varchar(40)'
	EXEC SP_EXECUTESQL @cCmd
END

