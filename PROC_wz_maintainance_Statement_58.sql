
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_FINYEAR_HOLD_BACK_DELIVER_MST' AND VALUE='1')
BEGIN
	UPDATE HOLD_BACK_DELIVER_MST
	SET FIN_YEAR = '01'+DBO.FN_GETFINYEAR(MEMO_DT)
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_FINYEAR_HOLD_BACK_DELIVER_MST')
       INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
	   VALUES ('UPDATE_FINYEAR_HOLD_BACK_DELIVER_MST','1','',GETDATE())	
	ELSE	
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_FINYEAR_HOLD_BACK_DELIVER_MST'
END
