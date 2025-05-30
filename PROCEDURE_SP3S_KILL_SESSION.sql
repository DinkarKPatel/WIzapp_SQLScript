CREATE PROCEDURE SP3S_KILL_SESSION
(
	@nSPID	INT
)
AS
BEGIN
	
	DECLARE @cTableName VARCHAR(100),@cCMD NVARCHAR(MAX),@cErrMsg	VARCHAR(MAX) 
	SET @cTableName='TEMPDB..##'+CAST(DB_NAME() AS VARCHAR(100))+'_TMP_LOGIN_'+CAST(@nSPID AS VARCHAR(100))
	BEGIN TRY
		IF EXISTS (SELECT spid FROM sys.sysprocesses(NOLOCK) WHERE DBID=DB_ID() AND spid=@nSPID)
		BEGIN
	
			SET @cCMD=N'KILL '+CAST(@nSPID AS VARCHAR(100))
				
			EXEC SP_EXECUTESQL @cCMD
		END
	END TRY
	BEGIN CATCH
		SET @cErrMsg=ERROR_MESSAGE()
	END CATCH
	DELETE FROM  NEW_APP_LOGIN_INFO WHERE SPID=@nSPID

	SET @cCMD=N'IF OBJECT_ID('''+@cTableName+''',''U'') IS NOT NULL
		DROP TABLE '+@cTableName
		
	EXEC SP_EXECUTESQL @cCMD	
		
	
	
	SELECT ISNULL(@cErrMsg,'') AS ErrMsg
	
END