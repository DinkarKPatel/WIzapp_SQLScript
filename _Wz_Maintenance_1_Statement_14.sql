


--UPDATE PO_FOR_DEPT_ID INTO POM01106 TABLE 
IF NOT EXISTS (SELECT TOP 1  VALUE FROM DBO.CONFIG WITH(NOLOCK) WHERE CONFIG_OPTION='UPDATE_PO_FOR_DEPT_ID')
BEGIN
    --UPDATE PO_FOR_DEPT_ID INTO TABLE
    /*Rohit 30-10-2024
	UPDATE DBO.POM01106 SET PO_FOR_DEPT_ID = LEFT(PO_ID,2) 
    WHERE ISNULL(PO_FOR_DEPT_ID,'') =''
   */ 
   UPDATE DBO.POM01106 SET PO_FOR_DEPT_ID = LOCATION_CODE
    WHERE ISNULL(PO_FOR_DEPT_ID,'') =''
    --INSERT INTO CONFIG OPTION
    INSERT INTO DBO.CONFIG(CONFIG_OPTION,VALUE,ROW_ID,LAST_UPDATE)
    SELECT 'UPDATE_PO_FOR_DEPT_ID',1,NEWID(),GETDATE()
 END
   
