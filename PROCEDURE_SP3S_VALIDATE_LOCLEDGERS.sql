CREATE PROCEDURE SP3S_VALIDATE_LOCLEDGERS   
(  
  @NSPID INT        
          
)        
        
AS        
BEGIN  
  
  
  
  DECLARE @CCMD NVARCHAR(MAX),@CERRMSG AS VARCHAR(MAX),@NSTEP INT ,@NCOUNT BIT  
    
   IF OBJECT_ID('TEMPDB..##T','U') IS NOT NULL  
   DROP TABLE ##T  
               
        SET @NSTEP = 10                      
        IF ISNULL(@NSPID,'') = ''                      
   BEGIN                      
    SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SPID REQUIRED .....CANNOT PROCEED'                      
    GOTO END_PROC                          
   END  
     
   SET @NSTEP = 20                      
     SET @CCMD=N'IF EXISTS (SELECT TOP  1 ''U'' FROM  TEMP_LOCLEDGEREXCEL_IMPORT_'+LTRIM(RTRIM(STR(@NSPID)))+'   
                              WHERE XN_TYPE NOT IN (''PUR'',''PRT'',''WSL'',''WSR''))  
                 SET @NCOUNT=1'   
        PRINT @CCMD  
  EXEC SP_EXECUTESQL @CCMD,N'@NCOUNT BIT OUTPUT',@NCOUNT OUTPUT  
  
  IF @NCOUNT=1   
    BEGIN                    
    SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' XN TYPE NOT EXISTS .....CANNOT PROCEED'                      
    GOTO END_PROC                          
    END     
  
  SET @NSTEP = 30                 
  SET @CCMD=N'IF EXISTS (SELECT TOP  1 ''U'' FROM  TEMP_LOCLEDGEREXCEL_IMPORT_'+LTRIM(RTRIM(STR(@NSPID)))+' A   
  LEFT JOIN LM01106 B ON A.LEDGER=B.AC_NAME WHERE B.AC_NAME IS NULL)  
  SET @NCOUNT=1'   
        PRINT @CCMD  
  EXEC SP_EXECUTESQL @CCMD,N'@NCOUNT BIT OUTPUT',@NCOUNT OUTPUT  
  
  IF @NCOUNT=1   
  BEGIN  
   SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SUPPLIER NAME DOES NOT EXISTS .....CANNOT PROCEED'                      
   GOTO END_PROC                          
  END  
    
  SET @NSTEP = 40                 
  SET @CCMD=N'IF EXISTS (SELECT TOP  1 ''U''   
             FROM  TEMP_LOCLEDGEREXCEL_IMPORT_'+LTRIM(RTRIM(STR(@NSPID)))+' A   
              LEFT JOIN LOCATION B ON A.SOURCE_LOCATION=B.DEPT_ID  
     LEFT JOIN LOCATION C ON A.TARGET_LOCATION=C.DEPT_ID  
     WHERE B.DEPT_ID IS NULL OR C.DEPT_ID IS NULL)  
  SET @NCOUNT=1'   
        PRINT @CCMD  
  EXEC SP_EXECUTESQL @CCMD,N'@NCOUNT BIT OUTPUT',@NCOUNT OUTPUT  
  
  IF @NCOUNT=1   
  BEGIN  
   SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' SOURCE / TARGET LOCATION DOES NOT EXISTS .....CANNOT PROCEED'                      
   GOTO END_PROC                          
  END  
    
  SET @NSTEP = 40                 
  SET @CCMD=N'IF NOT EXISTS (SELECT TOP  1 ''U''   
              FROM  TEMP_LOCLEDGEREXCEL_IMPORT_'+LTRIM(RTRIM(STR(@NSPID)))+' A   
              JOIN LOCATION B ON A.SOURCE_LOCATION=B.DEPT_ID  
     JOIN LOCATION C ON A.TARGET_LOCATION=C.DEPT_ID  
     WHERE (ISNULL(B.loc_typE,0)=2 AND ISNULL(B.Account_posting_at_ho,0)=1)  
     OR  (ISNULL(C.loc_typE,0)=2 AND ISNULL(C.Account_posting_at_ho,0)=1)  
     )  
  SET @NCOUNT=1'   
        PRINT @CCMD  
  EXEC SP_EXECUTESQL @CCMD,N'@NCOUNT BIT OUTPUT',@NCOUNT OUTPUT  
  
  IF @NCOUNT=1   
  BEGIN  
   SET @CERRMSG = 'STEP- ' + LTRIM(STR(@NSTEP)) + ' EITHER SOURCE / TARGET LOCATION SHOULD BE FRANCHIES OR ACCOUNT POSTING SHOULD BE ENANBLED AT HO   .....CANNOT PROCEED'                      
   GOTO END_PROC                          
  END   
    
    
  SET @CCMD=N'SELECT XN_TYPE,SOURCE_LOCATION AS SOURCE_DEPT_ID,TARGET_LOCATION AS TARGET_DEPT_ID,B.AC_CODE,A.LEDGER INTO ##T  
     FROM TEMP_LOCLEDGEREXCEL_IMPORT_'+LTRIM(RTRIM(STR(@NSPID)))+' A  
     JOIN LM01106 B ON A.LEDGER=B.AC_NAME'  
     PRINT @CCMD  
     EXEC SP_EXECUTESQL @CCMD  
       
       
       
       
    
    
    
    
    
  
END_PROC:         
  
      IF ISNULL(@CERRMSG,'')<>''        
      SELECT ISNULL(@CERRMSG,'') AS ERRMSG   
      ELSE  
      SELECT * FROM ##T  
        
        
        
               
          
END        
        
--********************* END OF SAVETRAN_LOCLEDGERS**********************   
  

