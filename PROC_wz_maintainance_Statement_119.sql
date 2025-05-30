

--**** UPDATING DEPT_ID COLUMN IN GROUP PURCHASE FROM PARENT INVOICE TABLES
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPPUR_DEPTID' AND VALUE=1)
BEGIN
	PRINT 'UPDATING DEPT_ID COLUMN IN GROUP PURCHASE  FROM PARENT INVOICE TABLE'

	UPDATE PIM01106 SET DEPT_ID=B.PARTY_DEPT_ID FROM INM01106 B
	WHERE B.INV_ID=PIM01106.INV_ID AND B.INV_MODE=2 AND ISNULL(PIM01106.DEPT_ID,'')<>B.PARTY_DEPT_ID
	AND B.CANCELLED=0
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPPURCN_SOURCEMEMOID_1')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_GROUPPUR_DEPTID',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_GROUPPUR_DEPTID'
	
END		
