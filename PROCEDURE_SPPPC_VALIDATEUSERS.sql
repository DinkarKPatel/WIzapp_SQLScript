CREATE PROCEDURE SPPPC_VALIDATEUSERS            
(            
 @USERNAME    VARCHAR(30)='',            
 @PASSWORD    NVARCHAR(20)='',   
 @LOGINDATE    NVARCHAR(20)='',            
 @ERRMSG_OUT    VARCHAR(MAX) OUT            
)            
AS            
BEGIN            
 DECLARE @CSTEP INT            
             
 BEGIN TRY            
  SET @ERRMSG_OUT = ''     
      
  DECLARE @CDEPT_ID VARCHAR(5)    
      
  SELECT TOP 1 @CDEPT_ID=VALUE FROM CONFIG WHERE CONFIG_OPTION='LOCATION_ID'           
              
  SET @CSTEP = 10            
  IF EXISTS(SELECT 1 FROM [USERS] WHERE [USERNAME] = @USERNAME)            
  BEGIN            
   IF EXISTS(SELECT 1 FROM [USERS] WHERE [INACTIVE] = 0 AND [USERNAME] = @USERNAME AND [PASSWD] = @PASSWORD)            
   BEGIN            
             
    SELECT @@SPID AS [SPID], [USER_CODE], [USERNAME], [USER_ALIAS], [ROLE_ID],@CDEPT_ID AS DEPT_ID,    
           '01'+ DBO.FN_GETFINYEAR(@LOGINDATE) AS FIN_YEAR            
    FROM [USERS]            
    WHERE [INACTIVE] = 0 AND [USERNAME] = @USERNAME AND [PASSWD] = @PASSWORD            
                
    SET @ERRMSG_OUT = 'USER LOGIN SUCCESSFUL.'            
    PRINT @ERRMSG_OUT            
   END            
   ELSE            
   BEGIN            
    SET @ERRMSG_OUT = 'USER NAME AND PASSWORD NOT MATCHED.'            
    PRINT @ERRMSG_OUT            
   END             
  END            
  ELSE            
  BEGIN            
   SET @ERRMSG_OUT = 'USER NAME NOT FOUND.'            
   PRINT @ERRMSG_OUT            
  END            
   
   
   EXEC SP_PPC_INSERT_USER_ROLE_DET         
              
 END TRY              
 BEGIN CATCH              
  SET @ERRMSG_OUT='ERROR: [P]: SPPPC_VALIDATEUSERS, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()            
  PRINT @ERRMSG_OUT            
              
  GOTO END_PROC              
 END CATCH               
            
END_PROC:              
 IF  ISNULL(@ERRMSG_OUT,'')=''             
  SET @ERRMSG_OUT = ''            
END
