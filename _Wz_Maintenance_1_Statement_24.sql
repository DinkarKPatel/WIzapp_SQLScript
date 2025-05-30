




----MAINTAINANCE FOR CHQBOOK_D
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='INSERT_VD_CHQBOOK' AND VALUE=1)
BEGIN
	PRINT 'INSERTING ENTRY INTO NEW TABLE INSERT_VD_CHQBOOK'
	
	DECLARE @CCMD NVARCHAR(MAX)
	SET @CCMD=N'INSERT VD_CHQBOOK (VD_ID,CHQBOOK_ROW_ID)
	SELECT VD_ID,ROW_ID FROM CHQBOOK_D WHERE CANCELLED=0 AND ISNULL(VD_ID,'''')<>'''''
	EXEC SP_EXECUTESQL @CCMD
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='INSERT_VD_CHQBOOK')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('INSERT_VD_CHQBOOK',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='INSERT_VD_CHQBOOK'
END
