CREATE PROCEDURE SAVETRAN_PATCH_MRP_SETUP    
(    
  @NSPID INT   
    
)    
    
AS    
BEGIN    
    DECLARE @CCMD NVARCHAR(MAX),@CERRMSG AS VARCHAR(MAX),@NSTEP INT    
           
        SET @NSTEP = 10                  
     IF ISNULL(@NSPID,'') = ''                  
     BEGIN                  
    SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SPID REQUIRED .....CANNOT PROCEED'                  
    GOTO END_PROC                      
     END    
         
        
               
          SET @NSTEP = 20 
             
    DELETE FROM PATCH_MRP_SETUP    
    SET @CCMD=N'INSERT INTO PATCH_MRP_SETUP (OLD_MRP,NEW_MRP)    
       SELECT OLD_MRP,NEW_MRP FROM TEMP_PATCH_MRP_SETUP_'+LTRIM(RTRIM(STR(@NSPID)))    
                          
    PRINT @CCMD    
    EXEC SP_EXECUTESQL @CCMD     
              
           
END_PROC:                  
                  
     SELECT @CERRMSG AS ERRMSG                 
     SET @CERRMSG = 'PROCEDURE SAVETRAN_PATCH_MRP_SETUP  : STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()                       
END
