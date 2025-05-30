

IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='DELETE_DUP_SPLITCOMBINE' AND VALUE=1)
BEGIN
	PRINT 'DELETING DUPLICATE RECORDS IN SPLITCOMBINE'

	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='DELETE_DUP_SPLITCOMBINE')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('DELETE_DUP_SPLITCOMBINE','1','',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='DELETE_DUP_SPLITCOMBINE'
	
	DELETE A FROM SCC01106 A WHERE TS<>(SELECT TOP 1 TS FROM SCC01106 WHERE ROW_ID=A.ROW_ID) 
	DELETE A FROM SCF01106 A WHERE TS<>(SELECT TOP 1 TS FROM SCF01106 WHERE ROW_ID=A.ROW_ID) 
END		
