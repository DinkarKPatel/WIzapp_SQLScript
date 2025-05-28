DECLARE @cCmd NVARCHAR(MAX),@cDfConstName VARCHAR(500)

if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE TABLE_NAME='cmm01106'
		   and COLUMN_NAME='wizclip_bill_uploaded_on')
BEGIN
	if exists (select name from sys.indexes where name='ind_cmm01106_wizclip_billupload_on')
	begin
		set @cCmd=N'DROP INDEX cmm01106.ind_cmm01106_wizclip_billupload_on'
		exec sp_executesql @cCmd
	end

	select TOP 1 @cDfConstName=cc.name from sys.default_constraints cc (nolock)
			  LEFT JOIN sys.columns sc WITH (NOLOCK) ON sc.column_id = cc.parent_column_id
               AND sc.object_id = cc.parent_object_id
			   where object_name(parent_object_id)='cmm01106' and sc.name='WIZCLIP_BILL_UPLOADED_ON'
	
	IF ISNULL(@cDfConstName,'')<>''
	BEGIN
		SET @cCmd=N'ALTER TABLE cmm01106 drop constraint '+@cDfConstName
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cCmd=N'ALTER TABLE cmm01106 drop column  wizclip_bill_uploaded_on'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE TABLE_NAME='sls_cmm01106_upload'
		   and COLUMN_NAME='wizclip_bill_uploaded_on')
BEGIN
	SET @cCmd=N'ALTER TABLE sls_cmm01106_upload drop column  wizclip_bill_uploaded_on'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
end

if exists (select top 1 column_name from INFORMATION_SCHEMA.columns (NOLOCK) WHERE TABLE_NAME='sls_cmm01106_upload'
		   and COLUMN_NAME='wizclip_bill_uploaded_on')
BEGIN
	
	SET @cCmd=N'ALTER TABLE sls_cmm01106_upload drop column  wizclip_bill_uploaded_on'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END

UPDATE cmm01106 WITH (ROWLOCK) SET wizclip_bill_synch_last_update=last_update
where isnull(wizclip_bill_synch_last_update,'')<>last_update

if object_id('wizclip_bill_upload','u') is not null
BEGIN
	SET @cCmd=N'DROP TABLE wizclip_bill_upload'
	EXEC SP_EXECUTESQL @cCmd
END



