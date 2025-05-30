IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_FLOOR_ST_DET_ITEM_TARGET_BIN_ID' AND VALUE=1)
BEGIN
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_FLOOR_ST_DET_ITEM_TARGET_BIN_ID')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_FLOOR_ST_DET_ITEM_TARGET_BIN_ID',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE=1 WHERE CONFIG_OPTION='UPDATE_FLOOR_ST_DET_ITEM_TARGET_BIN_ID'
	
	   UPDATE A  SET ITEM_TARGET_BIN_ID=B.TARGET_BIN_ID
	           FROM FLOOR_ST_DET A JOIN FLOOR_ST_MST B ON A.MEMO_ID=B.MEMO_ID
	           WHERE ISNULL(A.ITEM_TARGET_BIN_ID,'')=''
END		



