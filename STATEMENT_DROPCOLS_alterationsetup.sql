DECLARE @cCmd NVARCHAR(MAX)

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='DISCOUNT_PER' AND table_name='alterationsetup_import_upload')
BEGIN
	SET @cCmd=N'alter table alterationsetup_import_upload drop column DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END
IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='FRESH_DISCOUNT_PER' AND table_name='alterationsetup_import_upload')
BEGIN
	SET @cCmd=N'alter table alterationsetup_import_upload drop column FRESH_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='LOWER_DISCOUNT_PER' AND table_name='alterationsetup_import_upload')
BEGIN
	SET @cCmd=N'alter table alterationsetup_import_upload drop column LOWER_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='HIGHER_DISCOUNT_PER' AND table_name='alterationsetup_import_upload')
BEGIN
	SET @cCmd=N'alter table alterationsetup_import_upload drop column HIGHER_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='DISCOUNT_PER' AND table_name='alterationsetup')
BEGIN
	SET @cCmd=N'alter table alterationsetup drop column DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END
IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='FRESH_DISCOUNT_PER' AND table_name='alterationsetup')
BEGIN
	SET @cCmd=N'alter table alterationsetup drop column FRESH_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='LOWER_DISCOUNT_PER' AND table_name='alterationsetup')
BEGIN
	SET @cCmd=N'alter table alterationsetup drop column LOWER_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.columns WHERE COLUMN_NAME='HIGHER_DISCOUNT_PER' AND table_name='alterationsetup')
BEGIN
	SET @cCmd=N'alter table alterationsetup drop column HIGHER_DISCOUNT_PER'
	EXEC SP_EXECUTESQL @cCmd
END