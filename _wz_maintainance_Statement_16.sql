

--**** UPDATING NEWLY INSERTED INVOICE QTY COLUMN IN PID01106 WITH QUANTITY COLUMN
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_ENABLE_GRSERVICE' AND VALUE=1)
BEGIN
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_ENABLE_GRSERVICE')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_ENABLE_GRSERVICE',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_ENABLE_GRSERVICE'
		
	DELETE FROM CONFIG WHERE  CONFIG_OPTION='ENABLE_GRSERVICE'
	
	INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('ENABLE_GRSERVICE',1,'',GETDATE())

END		
