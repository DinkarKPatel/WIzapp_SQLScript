



--**** UPDATING INV_ID COLUMN IN GROUP PURCHASE / RM_ID IN GROUP CREDIT NOTE FROM IMP LOG TABLES
IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPPURCN_SOURCEMEMOID_1' AND VALUE=1)
BEGIN
	PRINT 'UPDATING INV_ID COLUMN IN GROUP PURCHASE / RM_ID IN GROUP CREDIT NOTE FROM IMP LOG TABLES'

	UPDATE PIM01106 SET INV_ID=B.INV_ID FROM PUR_IMPORT_LOG B WHERE B.MRR_ID=PIM01106.MRR_ID
	AND INV_MODE=2  AND ISNULL(PIM01106.INV_ID,'')=''
	
	UPDATE PIM01106 SET INV_ID=LEFT(INV_NO,2)+FIN_YEAR+INV_NO WHERE INV_MODE=2 AND ISNULL(INV_ID,'')=''
					
	UPDATE CNM01106 SET RM_ID=B.RM_ID FROM WSR_IMPORT_LOG B WHERE B.CN_ID=CNM01106.CN_ID
	AND MODE=2 AND ISNULL(CNM01106.RM_ID,'')='' 
	
	UPDATE CNM01106 SET RM_ID=LEFT(MANUAL_INV_NO,2)+FIN_YEAR+MANUAL_INV_NO WHERE MODE=2 AND ISNULL(RM_ID,'')=''
	
	IF NOT EXISTS (SELECT CONFIG_OPTION FROM CONFIG WHERE CONFIG_OPTION='UPDATE_GROUPPURCN_SOURCEMEMOID_1')
		INSERT CONFIG (CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
			   VALUES ('UPDATE_GROUPPURCN_SOURCEMEMOID_1',1,'',GETDATE())	
	ELSE
		UPDATE CONFIG SET VALUE='1' WHERE CONFIG_OPTION='UPDATE_GROUPPURCN_SOURCEMEMOID_1'
	
END		
