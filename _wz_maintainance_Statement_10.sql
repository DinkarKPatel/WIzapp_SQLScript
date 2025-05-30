

--**** UPDATING DEPT ID COLUMN IN GROUP CREDIT NOTES SO THAT STOCK GETS PROPERLY UPDATED
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPCRNOTE_DEPTID' AND VALUE=1)
BEGIN
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPCRNOTE_DEPTID')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_GROUPCRNOTE_DEPTID',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_GROUPCRNOTE_DEPTID'

	UPDATE CNM01106 SET PARTY_DEPT_ID=LEFT(B.CN_ID,2) FROM WSR_IMPORT_LOG B WHERE B.CN_ID=CNM01106.CN_ID
			
	UPDATE CND01106 SET DEPT_ID=LEFT(B.CN_ID,2) FROM WSR_IMPORT_LOG B WHERE B.CN_ID=CND01106.CN_ID
END		
