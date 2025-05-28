IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME='pim01106'
			and COLUMN_NAME='terms_code')
BEGIN
	
	DECLARE @cDefConstName VARCHAR(200),@cCmd NVARCHAR(MAX)

	select @cDefConstName=O.NAME  FROM SYSOBJECTS O 
		INNER JOIN SYSCOLUMNS C
		ON O.ID = C.CDEFAULT
		INNER JOIN SYSOBJECTS T
		ON C.ID = T.ID
		WHERE O.XTYPE = 'D'
		AND C.NAME = 'terms_code'
		AND T.NAME = 'pim01106'

	SET @cCmd=N'Alter table pim01106 drop constraint '+@cDefConstName
	EXEC SP_EXECUTESQL @cCmd
	alter table pim01106 drop column terms_code 
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME='pur_pim01106_upload'
			and COLUMN_NAME='terms_code')
BEGIN
	alter table pur_pim01106_upload drop column terms_code 
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME='rmd01106'
			and COLUMN_NAME='terms_code')
BEGIN
	alter table rmd01106  drop column terms_code 
END

IF EXISTS (SELECT column_name FROM INFORMATION_SCHEMA.COLUMNS (NOLOCK) WHERE TABLE_NAME='prt_rmd01106_upload'
			and COLUMN_NAME='terms_code')
BEGIN
	alter table prt_rmd01106_upload  drop column terms_code 
END


