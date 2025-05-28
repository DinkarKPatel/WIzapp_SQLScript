if exists (select top 1 name from sysobjects (nolock) where name='TRG_UPLOAD_CUSTDYM' and xtype='TR')
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'DROP TRIGGER TRG_UPLOAD_CUSTDYM'
	EXEC SP_EXECUTESQL @cCmd
END	