

PRINT 'UPDATING SUBTOTAL/DISCOUNT COLUMN IN CASH MEMO MASTER TABLE'

IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE  CONFIG_OPTION='UPDATE_CMM_SUBTOTAL_DISCOUNT' AND VALUE=1)
BEGIN
	
	EXEC SP_CMM_CAL_SUBTOTAL	

	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_CMM_SUBTOTAL_DISCOUNT')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_CMM_SUBTOTAL_DISCOUNT','1','',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_CMM_SUBTOTAL_DISCOUNT'

	
END
