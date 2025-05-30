IF NOT EXISTS(SELECT TOP 1 'U' FROM CONFIG WHERE CONFIG_OPTION='UPDATE_PSM_DISCOUNTED_ITEMS_APPLICABLE' AND VALUE=1)
BEGIN
	PRINT 'UPDATING DISCOUNTED_ITEMS_APPLICABLE MARK IN PROMOTIONAL_SCHEMES_MST TABLE'
	
	UPDATE PROMOTIONAL_SCHEMES_MST SET DISCOUNTED_ITEMS_APPLICABLE=1 WHERE PROMOTIONAL_SCHEME_ID IN 
	('SCH0007','SCH0004','SCH0005','SCH0009','SCH0006')

	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_PSM_DISCOUNTED_ITEMS_APPLICABLE')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_PSM_DISCOUNTED_ITEMS_APPLICABLE',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_PSM_DISCOUNTED_ITEMS_APPLICABLE'
END							
