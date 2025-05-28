CREATE PROCEDURE VALIDATEXN_JWI_BEFORE_CANCELLED
(
 @CMEMO_ID VARCHAR(50),
 @CERRORMSG VARCHAR(1000) OUTPUT
)
AS
BEGIN
 BEGIN TRY
      
      DECLARE @NSTEP INT
      SET @NSTEP=00
      
      
   IF EXISTS(   SELECT TOP 1 'U' FROM JOBWORK_ISSUE_MST  (nolock)
      WHERE ISSUE_ID=@CMEMO_ID AND CANCELLED =1)
    BEGIN
        SET @CERRORMSG='Memo has been Alredy cancelled can not cancelled it'
        RETURN
    END
    SET @NSTEP=10
    
        
   IF EXISTS(   SELECT TOP 1 'U' FROM BOM_ISSUE_MST   (nolock)
      WHERE JOBWORK_ISSUE_ID =@CMEMO_ID AND CANCELLED =0)
    BEGIN
        SET @CERRORMSG='Material has been assign for this job work can not cancelled it'
        RETURN
    END
    
    IF EXISTS (SELECT TOP 1 'U' FROM JOBWORK_ISSUE_MST A (NOLOCK)
    JOIN JOBWORK_ISSUE_DET B (NOLOCK) ON A.issue_id =B.issue_id 
    JOIN jobwork_receipt_det C (NOLOCK) ON B.ROW_ID =C.REF_ROW_ID
    JOIN jobwork_receipt_mst D (NOLOCK) ON C.receipt_id =D.receipt_id 
    WHERE A.issue_id =@CMEMO_ID AND D.cancelled =0)
    BEGIN
        SET @CERRORMSG='This job work has been Received can not cancelled it'
        RETURN
    END
     

 END TRY

BEGIN CATCH
	SET @CERRORMSG=N'ERROR FOUND IN '+ISNULL(ERROR_PROCEDURE(),'VALIDATEXN_BEFORE_CANCELLD ')+
	  'STEP :'+LTRIM(RTRIM(STR(@NSTEP)))  +' MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')  
	  
END CATCH   
    


END