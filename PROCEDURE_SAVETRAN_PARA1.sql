CREATE PROCEDURE [DBO].[SAVETRAN_PARA1] 
(
	@PARA1_CODE				VARCHAR(9) = '',
	@PARA1_NAME				VARCHAR(300)='',
	@ALIAS					VARCHAR(50) = '',
	@INACTIVE				BIT = 0,     
	@PARA1_SET				VARCHAR(40) = '',   
	@REMARKS				VARCHAR(500) = '',
	@ERRMSG_OUT				VARCHAR(MAX) OUT,
	@BDELETE BIT=0
)
AS
BEGIN
	DECLARE @CSTEP INT
	DECLARE @TEMP_PARA1_CODE VARCHAR(9) = '',@ERRMSG VARCHAR(MAX)
	BEGIN TRY
	BEGIN TRANSACTION
	SET @ERRMSG_OUT = ''
	SET @ERRMSG=''
	SET @CSTEP=''
	
	IF @BDELETE=1
	BEGIN
	   IF @PARA1_CODE='0000000'
	   BEGIN
		   SET @ERRMSG='DEFAULT PARA1 CAN NOT BE DELETED'
		   GOTO END_PROC
	   END
	   
	   DELETE FROM PARA1 WHERE PARA1_CODE =@PARA1_CODE
	   GOTO END_PROC
	END	
	
		IF (RTRIM(LTRIM(@PARA1_CODE)) = '')
		BEGIN
			IF EXISTS(SELECT [PARA1_NAME] FROM [PARA1] WHERE [PARA1_NAME] = @PARA1_NAME)
			BEGIN
				SET @CSTEP=5
				SET @ERRMSG_OUT = 'PARA1 NAME: '+@PARA1_NAME + ' ALREADY EXIST.'
				PRINT @ERRMSG_OUT
				SET @ERRMSG=@ERRMSG_OUT
			END
			ELSE
			BEGIN
				SET @CSTEP=10
				EXEC DBO.GETNEXTKEY 'PARA1', 'PARA1_CODE', 7, '00', 1, '', 2, @TEMP_PARA1_CODE OUTPUT 
				
				PRINT 'PARA1 CODE: ' + @TEMP_PARA1_CODE
				
				SET @CSTEP=15
				INSERT PARA1 (PARA1_CODE, PARA1_NAME, LAST_UPDATE, ALIAS, INACTIVE, PARA1_ORDER, PARA1_SET, REMARKS, BL_PARA1_NAME, LAST_MODIFIED_ON)
				VALUES (@TEMP_PARA1_CODE, @PARA1_NAME, GETDATE(), @ALIAS, @INACTIVE, 	0, @PARA1_SET, @REMARKS, '', GETDATE())
				
				SET @ERRMSG_OUT = 'PARA1: '+ @PARA1_NAME +' CREATED SUCCESSFULLY.'
				PRINT @ERRMSG_OUT
			END
		END
		ELSE
		BEGIN
			SET @TEMP_PARA1_CODE = @PARA1_CODE
			IF NOT EXISTS(SELECT [PARA1_CODE] FROM [PARA1] WHERE [PARA1_CODE] = @PARA1_CODE)
			BEGIN
				IF EXISTS(SELECT [PARA1_NAME] FROM [PARA1] WHERE [PARA1_NAME] = @PARA1_NAME)
				BEGIN
					SET @CSTEP=20
					SET @ERRMSG_OUT = 'PARA1 NAME: '+@PARA1_NAME + ' ALREADY EXIST.'
					PRINT @ERRMSG_OUT
					SET @ERRMSG=@ERRMSG_OUT
				END
				ELSE
				BEGIN
					SET @CSTEP=25
					EXEC DBO.GETNEXTKEY 'PARA1', 'PARA1_CODE', 7, '00', 1, '', 2, @TEMP_PARA1_CODE OUTPUT 
					
					PRINT 'PARA1 CODE: ' + @TEMP_PARA1_CODE
					
					SET @CSTEP=30
					INSERT PARA1 (PARA1_CODE, PARA1_NAME, LAST_UPDATE, ALIAS, INACTIVE, PARA1_ORDER, PARA1_SET, REMARKS, BL_PARA1_NAME, LAST_MODIFIED_ON)
					VALUES (@TEMP_PARA1_CODE, @PARA1_NAME, GETDATE(), @ALIAS, @INACTIVE, 	0, @PARA1_SET, @REMARKS, '', GETDATE())
					
					SET @ERRMSG_OUT = 'PARA1: '+ @PARA1_NAME +' CREATED SUCCESSFULLY.'
					PRINT @ERRMSG_OUT
				END
			END
			ELSE
			BEGIN
				SET @CSTEP=35
				PRINT 'PARA1 CODE: ' + @TEMP_PARA1_CODE
			
			IF EXISTS(SELECT [PARA1_NAME] FROM [PARA1] WHERE [PARA1_NAME] = @PARA1_NAME AND PARA1_CODE <> @TEMP_PARA1_CODE)
			BEGIN
					SET @CSTEP=20
					SET @ERRMSG_OUT = 'PARA1 NAME: '+@PARA1_NAME + ' ALREADY EXIST.'
					PRINT @ERRMSG_OUT
					SET @ERRMSG=@ERRMSG_OUT
			END
			ELSE
			BEGIN	
				UPDATE [PARA1]
				SET	[PARA1_NAME] = @PARA1_NAME, 
						LAST_UPDATE = GETDATE(), 
						ALIAS = @ALIAS, 
						INACTIVE = @INACTIVE, 
						REMARKS = @REMARKS, 
						PARA1_SET = @PARA1_SET,
						LAST_MODIFIED_ON = GETDATE()
				WHERE PARA1_CODE = @TEMP_PARA1_CODE
				
				SET @ERRMSG_OUT = 'PARA1: '+ @PARA1_NAME +' UPDTED SUCCESSFULLY.'
				PRINT @ERRMSG_OUT
		    END
		END
		END
	END TRY  
	BEGIN CATCH 
	
		SET @ERRMSG_OUT='ERROR: [P]: SAVETRAN_PARA1, [STEP]: '+CAST(@CSTEP AS VARCHAR(5))+', [MESSAGE]: ' + ERROR_MESSAGE()
		PRINT @ERRMSG_OUT
		SET @ERRMSG=@ERRMSG_OUT
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
