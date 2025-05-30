

IF NOT EXISTS(SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_IND_WPS_ROWID'
			  AND VALUE='1')
BEGIN
	PRINT 'UPDATE REFERENCE REFERENCE WPS_DET ROW ID IN INVOICE DETAIL TABLE'
	DELETE FROM CONFIG WHERE CONFIG_OPTION='UPDATE_IND_WPS_ROWID'
	
	UPDATE IND01106 SET REF_WPS_DET_ROWID=B.ROW_ID FROM WPS_DET B WHERE B.PRODUCT_CODE=IND01106.PRODUCT_CODE
	AND B.PS_ID=IND01106.PS_ID
	
    INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
	VALUES ('UPDATE_IND_WPS_ROWID','1','',GETDATE())	
END
