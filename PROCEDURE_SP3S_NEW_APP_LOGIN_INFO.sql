CREATE PROCEDURE SP3S_NEW_APP_LOGIN_INFO
(
	@SPID INT,
	@USER INT,
	@STATICIP VARCHAR(100),
	@WINDOWUSERNAME VARCHAR(100),
	@COMPUTERNAME VARCHAR(100),
	@LOGINUSER VARCHAR(100),
	@PROCESSID NUMERIC(10),
	@cLocID			VARCHAR(5)='',
	@cBINID			VARCHAR(10)='',
	@cUCode		VARCHAR(10)=''
	,@cByPassLoc Varchar(5)='0'
)
AS
BEGIN
      DECLARE @CERRMSG NVARCHAR(MAX),@NSTEP INT,@CCMD NVARCHAR(MAX),
	  @COUNT INT,@SPIDCOUNT  INT
        
			  
      DECLARE @OUTPUT TABLE ( ERRMSG VARCHAR(2000))
      
      DECLARE @cTempTableName VARCHAR(100)
	  DECLARE @cHoId VARCHAR(10), @bServerLoc BIT
         
       -- SET @cTempTableName='##'+DB_NAME()+'_TMP_LOGIN_' + LTRIM(RTRIM(CAST(@SPID AS NVARCHAR))) + '_' + LTRIM(RTRIM(@cUCode))
	    SET @cTempTableName='##'+DB_NAME()+'_TMP_LOGIN_' + LTRIM(RTRIM(CAST(@SPID AS NVARCHAR))) + '_' + LTRIM(RTRIM(@cUCode)) + '_LOC' + LTRIM(RTRIM(@cLocID))

BEGIN TRY

 
        --SELECT @cByPassLoc =value From config (NOLOCK) where config_option = 'BYPASS_LOCREGUSERS'
		
		IF ISNULL(@cByPassLoc,'')='1'
		BEGIN
			SELECT @bServerLoc=server_loc FROM LOCATION WHERE dept_id=@cLocID
			SET @bServerLoc=ISNULL(@bServerLoc,0)
			SET @cTempTableName='##'+DB_NAME()+'_TMP_LOGIN_' + LTRIM(RTRIM(CAST(@SPID AS NVARCHAR))) + '_' + LTRIM(RTRIM(@cUCode))
			Select  @cHoId = value From config where config_option = 'HO_LOCATION_ID'
			Select  @USER=  reg_users from location  where dept_id=(CASE WHEN @bServerLoc=1 THEN @cHoId ELSE @cLocID END)
		END

		
			   
		SET @CCMD=N'IF OBJECT_ID(''TEMPDB..'+@cTempTableName+''',''U'') IS NOT NULL
					     	DROP TABLE '+ @cTempTableName
		PRINT @cCMD
		EXEC SP_EXECUTESQL @cCMD
		
		DELETE FROM NEW_APP_LOGIN_INFO WHERE SPID=@SPID

        SET @NSTEP=10
        SELECT @COUNT =COUNT(*) FROM NEW_APP_LOGIN_INFO 
       -- SELECT @SPIDCOUNT=COUNT(*) FROM NEW_APP_LOGIN_INFO WHERE SPID=@SPID
                     
        SET @SPIDCOUNT=0

		IF ISNULL(@cByPassLoc,'')='1'
		BEGIN
					 SELECT @SPIDCOUNT=COUNT(*) FROM TEMPDB.SYS.OBJECTS (nolock) WHERE NAME LIKE '##'+DB_NAME()+'_TMP_LOGIN%'
        END
		ELSE
		BEGIN
		           SELECT @SPIDCOUNT=COUNT(*) FROM TEMPDB.SYS.OBJECTS (nolock) WHERE NAME LIKE '##'+DB_NAME()+'_TMP_LOGIN%LOC'+ LTRIM(RTRIM(@cLocID))
        END

        SET @NSTEP=20
        IF @USER <= ISNULL(@SPIDCOUNT,0)
          BEGIN
            
            SET @CERRMSG='NO OF USER LIMIT EXHAUSTED; PLEASE CONTACT TO SYSTEM ADMINISTRATOR'
            GOTO END_PROC
          
          END
         ELSE
          BEGIN
          SET @NSTEP=30
                 SET @CCMD=N' SELECT '''+ @WINDOWUSERNAME+''' AS WINDOW_USER_NAME,
							'''+@COMPUTERNAME+''' AS COMPUTER_NAME,
							'''+@LOGINUSER+ ''' AS LOGIN_NAME,GETDATE() AS LAST_UPDATE ,'''+LTRIM(RTRIM(CAST(@SPID AS NVARCHAR)))+''' AS SP_ID 
								,'''+@cLocID+ ''' AS LOCATION_ID,'''+@cBINID+ ''' AS BIN_ID
							INTO '+ @cTempTableName 
                 PRINT @CCMD
                 EXEC SP_EXECUTESQL @CCMD
                 
                 INSERT INTO NEW_APP_LOGIN_INFO(SPID,STATIC_IP,WINDOW_USER_NAME,COMPUTER_NAME,LOGIN_NAME,LAST_UPDATE,PROCESS_ID,dept_id,BIN_ID)
				 VALUES(@SPID,@STATICIP,@WINDOWUSERNAME,@COMPUTERNAME,@LOGINUSER,GETDATE(),@PROCESSID,@cLocID,@cBINID)


           
          END 
                   
                   
   END TRY
   BEGIN CATCH
   SET @CERRMSG = 'SP3S_NEW_APP_LOGIN_INFO STEP- ' + LTRIM(STR(@NSTEP)) + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
   GOTO END_PROC
   END CATCH
   END_PROC:
       INSERT INTO @OUTPUT(ERRMSG)VALUES(ISNULL(@CERRMSG,''))
       SELECT * FROM @OUTPUT
END      
---------------------------------------- END OF SP3S_NEW_APP_LOGIN_INFO



