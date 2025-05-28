CREATE PROCEDURE SAVETRAN_BOXHASH    
(    
  @NSPID INT,    
  @CMRR_ID CHAR(40)    
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
     IF ISNULL(@CMRR_ID,'') = ''                  
     BEGIN                  
    SET @CERRMSG = 'STEP- ' + LTRIM(STR(@CMRR_ID)) + ' MAJOR_DEPT_ID REQUIRED .....CANNOT PROCEED'                  
    GOTO END_PROC                      
     END    
               
          SET @NSTEP = 20    
    DELETE FROM PUR_BOX WHERE MRR_ID=@CMRR_ID    
    SET @CCMD=N'INSERT INTO PUR_BOX (MRR_ID,BOX)    
       SELECT MRR_ID,BOX FROM TEMP_PUR_BOX_'+LTRIM(RTRIM(STR(@NSPID)))    
                          
    PRINT @CCMD    
    EXEC SP_EXECUTESQL @CCMD     
              
           
END_PROC:                  
                  
     SELECT @CERRMSG AS ERRMSG                 
     SET @CERRMSG = 'PROCEDURE SAVETRAN_BOXHASH: STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()                  
             
      
END    
    
--********************* END OF SAVETRAN_BOXHASH********************** 