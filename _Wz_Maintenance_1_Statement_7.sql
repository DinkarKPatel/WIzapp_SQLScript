

IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE  CONFIG_OPTION='UPDATE_CMD01106_BASIC_DP' AND VALUE=1)
BEGIN
	
	PRINT 'UPDATING BASIC DISCOUNT PERCENT COLUMN IN CMD01106'	
	UPDATE CMD01106 SET BASIC_DISCOUNT_PERCENTAGE=DISCOUNT_PERCENTAGE,BASIC_DISCOUNT_AMOUNT=DISCOUNT_AMOUNT
	WHERE DISCOUNT_PERCENTAGE<>0 AND BASIC_DISCOUNT_PERCENTAGE IS NULL
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE  CONFIG_OPTION='UPDATE_CMD01106_BASIC_DP')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_CMD01106_BASIC_DP',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_CMD01106_BASIC_DP'
		
END		
