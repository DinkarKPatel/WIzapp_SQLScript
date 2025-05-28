  
CREATE PROCEDURE SAVETRAN_LOCLEDGERS       
(        
  @NSPID INT        
          
)        
        
AS        
BEGIN  
  
BEGIN TRY  
  
  DECLARE @CCMD NVARCHAR(MAX),@CERRMSG AS VARCHAR(MAX),@NSTEP INT ,@NCOUNT BIT       
               
        SET @NSTEP = 10                      
        IF ISNULL(@NSPID,'') = ''                      
   BEGIN                      
    SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SPID REQUIRED .....CANNOT PROCEED'                      
    GOTO END_PROC                          
   END  
     
    
        
  SET @NSTEP = 50                      
  DELETE FROM FRANCHISE_LOC_LEDGER_SETUP    
  SET @CCMD=N'INSERT INTO FRANCHISE_LOC_LEDGER_SETUP (XN_TYPE,SOURCE_DEPT_ID,TARGET_DEPT_ID,AC_CODE)        
     SELECT XN_TYPE,SOURCE_DEPT_ID,TARGET_DEPT_ID,AC_CODE  
     FROM TEMP_FRANCHISE_LOC_LEDGER_SETUP_'+LTRIM(RTRIM(STR(@NSPID)))+''        
                               
  PRINT @CCMD        
  EXEC SP_EXECUTESQL @CCMD         
                  
END TRY  
BEGIN CATCH  
          SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()    
          GOTO END_PROC  
END CATCH        
     
               
END_PROC:   
  
      IF ISNULL(@CERRMSG,'')='' 
      begin
      select ISNULL(@CERRMSG,'') as errmsg 
      SELECT * FROM FRANCHISE_LOC_LEDGER_SETUP                        
      end
           
      IF ISNULL(@CERRMSG,'')<>''        
      SELECT ISNULL(@CERRMSG,'') AS ERRMSG   
        
               
          
END        
        
--********************* END OF SAVETRAN_LOCLEDGERS**********************   

