CREATE PROCEDURE SAVETRAN_HD01106  
(  
 @HEAD_CODE    VARCHAR(10) = '',    
 @HEAD_NAME    VARCHAR(300) = '',  
 @ALIAS     VARCHAR(10) = '',  
 @MAJOR_HEAD_CODE  VARCHAR(10) = '',  
 @PHYSICAL    BIT = 0,  
 @INACTIVE    BIT = 0 ,  
 @ERRMSG_OUT    VARCHAR(MAX) OUT  
)  
AS  
BEGIN  
 DECLARE @CSTEP INT  
 DECLARE @TEMP_HEAD_CODE VARCHAR(7) = ''  
   
 BEGIN TRY  
  SET @ERRMSG_OUT = ''  
    
  IF (RTRIM(LTRIM(@HEAD_CODE)) = '')  
  BEGIN  
   IF EXISTS(SELECT [HEAD_NAME] FROM [HD01106] WHERE [HEAD_NAME] = @HEAD_NAME)  
   BEGIN  
    SET @CSTEP=5  
    SET @ERRMSG_OUT = 'HEAD NAME: '+@HEAD_NAME + ' ALREADY EXIST.'  
    PRINT @ERRMSG_OUT  
   END  
   ELSE  
   BEGIN  
    SET @CSTEP=10  
    EXEC DBO.GETNEXTKEY 'HD01106', 'HEAD_CODE', 7, '00', 1, '', 2, @TEMP_HEAD_CODE OUTPUT   
      
    PRINT 'HEAD CODE: ' + @TEMP_HEAD_CODE  
      
    SET @CSTEP=15  
    INSERT HD01106 (HEAD_CODE, HEAD_NAME, MAJOR_HEAD_CODE, PHYSICAL, ALIAS, PRINT_HEAD, LAST_UPDATE, CREDITOR_DEBTOR_CODE, COMPANY_CODE, UPLOADED_TO_ACTIVSTREAM, INACTIVE)  
    VALUES (@TEMP_HEAD_CODE, @HEAD_NAME, @MAJOR_HEAD_CODE, @PHYSICAL, @ALIAS, 0, GETDATE(), '', '00', 0, @INACTIVE)  
      
    SET @ERRMSG_OUT = 'HEAD CREATION: '+ @HEAD_NAME +' CREATED SUCCESSFULLY.'  
    PRINT @ERRMSG_OUT  
   END  
  END  
  ELSE  
  BEGIN  
   SET @TEMP_HEAD_CODE = @HEAD_CODE  
   IF NOT EXISTS(SELECT HEAD_CODE FROM [HD01106] WHERE HEAD_CODE = @HEAD_CODE)  
   BEGIN  
    IF EXISTS(SELECT [HEAD_NAME] FROM [HD01106] WHERE [HEAD_NAME] = @HEAD_NAME)  
    BEGIN  
     SET @CSTEP=5  
     SET @ERRMSG_OUT = 'HEAD NAME: '+@HEAD_NAME + ' ALREADY EXIST.'  
     PRINT @ERRMSG_OUT  
    END  
    ELSE  
    BEGIN  
     SET @CSTEP=10  
     EXEC DBO.GETNEXTKEY 'HD01106', 'HEAD_CODE', 7, '00', 1, '', 2, @TEMP_HEAD_CODE OUTPUT   
       
     PRINT 'HEAD CODE: ' + @TEMP_HEAD_CODE  
       
     SET @CSTEP=15  
     INSERT HD01106 (HEAD_CODE, HEAD_NAME, MAJOR_HEAD_CODE, PHYSICAL, ALIAS, PRINT_HEAD, LAST_UPDATE, CREDITOR_DEBTOR_CODE, COMPANY_CODE, UPLOADED_TO_ACTIVSTREAM, INACTIVE)  
     VALUES (@TEMP_HEAD_CODE, @HEAD_NAME, @MAJOR_HEAD_CODE, @PHYSICAL, @ALIAS, 0, GETDATE(), '', '00', 0, @INACTIVE)  
       
     SET @ERRMSG_OUT = 'HEAD CREATION: '+ @HEAD_NAME +' CREATED SUCCESSFULLY.'  
     PRINT @ERRMSG_OUT  
    END  
   END  
   ELSE  
   BEGIN  
    SET @CSTEP=30  
    PRINT 'HEAD CODE: ' + @TEMP_HEAD_CODE  
     
    UPDATE [HD01106]  
    SET HEAD_NAME = @HEAD_NAME,   
     MAJOR_HEAD_CODE = @MAJOR_HEAD_CODE,   
     PHYSICAL = @PHYSICAL,   
     ALIAS = @ALIAS,   
     PRINT_HEAD = 0,   
     LAST_UPDATE = GETDATE(),   
     CREDITOR_DEBTOR_CODE = '',   
     COMPANY_CODE = '00',   
     UPLOADED_TO_ACTIVSTREAM = 0,   
     INACTIVE = @INACTIVE  
    WHERE HEAD_CODE = @TEMP_HEAD_CODE  
      
    SET @ERRMSG_OUT = 'HEAD CREATION: '+ @HEAD_NAME +' UPDATED SUCCESSFULLY.'  
    PRINT @ERRMSG_OUT  
   END  
  END  
 END TRY    
 BEGIN CATCH    
  SET @ERRMSG_OUT='ERROR: [P]: SAVETRAN_HD01106, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()  
  PRINT @ERRMSG_OUT  
    
  GOTO END_PROC    
 END CATCH     
  
END_PROC:    
 IF  ISNULL(@ERRMSG_OUT,'')=''   
  SET @ERRMSG_OUT = ''  
   
END
