


--**** UPDATING NEWLY INSERTED INVOICE QTY COLUMN IN PID01106 WITH QUANTITY COLUMN
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_CMM01106_COPIESPTD' AND VALUE=1)
BEGIN
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_CMM01106_COPIESPTD')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_CMM01106_COPIESPTD',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_CMM01106_COPIESPTD'
	
	UPDATE CMM01106 SET COPIES_PTD=1 WHERE COPIES_PTD=0

END		
