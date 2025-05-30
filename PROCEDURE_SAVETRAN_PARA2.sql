CREATE PROCEDURE [DBO].[SAVETRAN_PARA2]       
(      
 @PARA2_CODE    VARCHAR(9) = '',      
 @PARA2_NAME    VARCHAR(300)='',      
 @ALIAS       VARCHAR(50) = '',      
 @INACTIVE      BIT = 0,           
 @PARA2_SET     VARCHAR(40) = '',         
 @REMARKS      VARCHAR(500) = '',   
 @PARA2_ORDER      VARCHAR(500) = '',      
 @ERRMSG_OUT    VARCHAR(MAX) OUT,
 @BDELETE BIT=0      
)      
AS      
BEGIN      
 DECLARE @CSTEP VARCHAR(10)  ,@ERRMSG VARCHAR(1000)    
 DECLARE @TEMP_PARA2_CODE VARCHAR(9) = ''      
       
 BEGIN TRY  
 BEGIN TRANSACTION    
 SET @ERRMSG_OUT = ''  
 SET @ERRMSG=''    
 SET @CSTEP=''
 
 IF @BDELETE=1
  BEGIN
	 IF @PARA2_CODE='0000000'
	   BEGIN
		   SET @ERRMSG='DEFAULT PARA2 CAN NOT BE DELETED'
		   GOTO END_PROC
	   END
	   DELETE FROM PARA2 WHERE PARA2_CODE =@PARA2_CODE
	   GOTO END_PROC
 END
 	
        
  IF (RTRIM(LTRIM(@PARA2_CODE)) = '')      
  BEGIN      
   IF EXISTS(SELECT [PARA2_NAME] FROM [PARA2] WHERE [PARA2_NAME] = @PARA2_NAME )      
   BEGIN      
		SET @CSTEP=5      
		SET @ERRMSG_OUT = 'PARA2 NAME: '+@PARA2_NAME + ' ALREADY EXIST.'      
		PRINT @ERRMSG_OUT   
		SET @ERRMSG=@ERRMSG_OUT  
   END      
   ELSE      
   BEGIN      
		SET @CSTEP=10      
		EXEC DBO.GETNEXTKEY 'PARA2', 'PARA2_CODE', 7, '00', 1, '', 2, @TEMP_PARA2_CODE OUTPUT       
	          
		PRINT 'PARA2 CODE: ' + @TEMP_PARA2_CODE      
	          
		SET @CSTEP=15      
		INSERT PARA2 (PARA2_CODE, PARA2_NAME, LAST_UPDATE,ALIAS,INACTIVE,PARA2_ORDER,PARA2_SET,REMARKS,BL_PARA2_NAME,LAST_MODIFIED_ON)      
		VALUES (@TEMP_PARA2_CODE, @PARA2_NAME, GETDATE(), @ALIAS, @INACTIVE,@PARA2_ORDER, @PARA2_SET, @REMARKS, '', GETDATE())      
	          
		SET @ERRMSG_OUT = 'PARA2: '+ @PARA2_NAME +' CREATED SUCCESSFULLY.'      
		PRINT @ERRMSG_OUT      
   END      
  END      
  ELSE      
  BEGIN      
   SET @TEMP_PARA2_CODE = @PARA2_CODE      
   IF NOT EXISTS(SELECT [PARA2_CODE] FROM [PARA2] WHERE [PARA2_CODE] = @PARA2_CODE)      
   BEGIN      
    IF EXISTS(SELECT [PARA2_NAME] FROM [PARA2] WHERE [PARA2_NAME] = @PARA2_NAME)      
    BEGIN      
     SET @CSTEP=20      
     SET @ERRMSG_OUT = 'PARA2 NAME: '+@PARA2_NAME + ' ALREADY EXIST.'      
     PRINT @ERRMSG_OUT      
     SET @ERRMSG=@ERRMSG_OUT
    END      
    ELSE      
    BEGIN      
     SET @CSTEP=25      
     EXEC DBO.GETNEXTKEY 'PARA2', 'PARA2_CODE', 7, '00', 1, '', 2, @TEMP_PARA2_CODE OUTPUT       
           
     PRINT 'PARA2 CODE: ' + @TEMP_PARA2_CODE      
           
     SET @CSTEP=30      
     INSERT PARA2 (PARA2_CODE, PARA2_NAME, LAST_UPDATE, ALIAS, INACTIVE, PARA2_ORDER, PARA2_SET, REMARKS, BL_PARA2_NAME, LAST_MODIFIED_ON)      
     VALUES (@TEMP_PARA2_CODE, @PARA2_NAME, GETDATE(), @ALIAS, @INACTIVE,@PARA2_ORDER, @PARA2_SET, @REMARKS, '', GETDATE())      
           
     SET @ERRMSG_OUT = 'PARA2: '+ @PARA2_NAME +' CREATED SUCCESSFULLY.'      
     PRINT @ERRMSG_OUT      
    END      
   END      
   ELSE      
   BEGIN      
    SET @CSTEP=35      
    PRINT 'PARA2 CODE: ' + @TEMP_PARA2_CODE      
    
    IF EXISTS(SELECT [PARA2_NAME] FROM [PARA2] WHERE [PARA2_NAME] = @PARA2_NAME AND PARA2_CODE <> @TEMP_PARA2_CODE)
	BEGIN
		SET @CSTEP=20
		SET @ERRMSG_OUT = 'PARA2 NAME: '+@PARA2_NAME + ' ALREADY EXIST.'
		PRINT @ERRMSG_OUT
		SET @ERRMSG=@ERRMSG_OUT
	END
	ELSE
	BEGIN		     
    UPDATE [PARA2]      
    SET [PARA2_NAME] = @PARA2_NAME,       
      LAST_UPDATE = GETDATE(),       
      ALIAS = @ALIAS,       
      INACTIVE = @INACTIVE,       
      REMARKS = @REMARKS,       
      PARA2_SET = @PARA2_SET,  
      PARA2_ORDER=@PARA2_ORDER ,     
      LAST_MODIFIED_ON = GETDATE()      
      WHERE PARA2_CODE = @TEMP_PARA2_CODE      
          
    SET @ERRMSG_OUT = 'PARA2: '+ @PARA2_NAME +' UPDTED SUCCESSFULLY.'      
    PRINT @ERRMSG_OUT
   END      
  END      
  END      
  END TRY  
  BEGIN CATCH  
	--SET @ERRMSG_OUT='ERROR: [P]: SAVETRAN_PARA2, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()
	PRINT @ERRMSG_OUT
	GOTO END_PROC  
  END CATCH   
  END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF ISNULL( @ERRMSG,'')='' 
			COMMIT TRANSACTION
		ELSE
			ROLLBACK
	END

	SELECT @ERRMSG AS ERRMSG
       
END
