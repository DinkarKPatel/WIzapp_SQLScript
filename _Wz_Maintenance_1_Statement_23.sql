



----MAINTAINANCE FOR LOCAL_GST_XN_AC_CODE
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_LOCAL_GST_XN_AC_CODE' AND VALUE=1)
BEGIN
	PRINT 'UPDATING NEW COLUMN LOCAL_GST_XN_AC_CODE'

	DECLARE @CCMD NVARCHAR(MAX)
	SET @CCMD=N'UPDATE GST_POSTING_CONFIG SET LOCAL_GST_XN_AC_CODE=SGST_XN_AC_CODE'
	EXEC SP_EXECUTESQL @CCMD
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_LOCAL_GST_XN_AC_CODE')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_LOCAL_GST_XN_AC_CODE',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_LOCAL_GST_XN_AC_CODE'
END
