	

IF NOT EXISTS(SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_HBD_PCQTY' AND VALUE='1')
BEGIN
	PRINT 'UPDATE PRODUCT CODE & QUANTITY COLUMN IN HOLD BACK TABLE '
	UPDATE A SET PRODUCT_CODE=B.PRODUCT_CODE,QUANTITY=B.QUANTITY FROM  HOLD_BACK_DELIVER_DET  A
	JOIN CMD01106 B ON A.REF_CMD_ROW_ID=B.ROW_ID 
	JOIN HOLD_BACK_DELIVER_MST  C ON C.MEMO_ID=A.MEMO_ID
	WHERE MODE<>2
	
	IF NOT EXISTS(SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_HBD_PCQTY')
	   INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
	   VALUES ('UPDATE_HBD_PCQTY','1','',GETDATE())	
	ELSE	
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_HBD_PCQTY'	
	
END
