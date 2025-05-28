CREATE PROCEDURE SPWOW_UPDATE_LOCFIXATTRCOLS_tempdata
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cKeyColCodeValue VARCHAR(10),@cKeyColNameValue VARCHAR(500),@NLOOP INT,
	@cKeyColCode VARCHAR(50),@cKeyColName VARCHAR(50),@cAttrTableName VARCHAR(100), @CKeyField VARCHAR(50),@cLocId VARCHAR(5),@NSTEP INT,@cMemonoVal VARCHaR(10)

	SET @cErrormsg=''

BEGIN TRY

	SET @nStep=10


	SELECT column_name as openkey_colname INTO #tmpOpenkey FROM config_locattr
	WHERE open_key=1

	IF NOT EXISTS (SELECT TOP 1 * from #tmpOpenkey)
		GOTO END_PROC

	SELECT TOP  1 @cLocId =VALUE FROM config (NOLOCK) WHERE config_option='location_id'

	SET @nStep=20
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpOpenkey)
	BEGIN
		SELECT TOP 1 @cKeyColName=openkey_colname FROM #tmpOpenkey

		SET @cKeyCOlCode=REPLACE(@cKeyColName,'_name','_code')
		

		--IF @@spid=71
		--	select @cKeyCOlCode,@cKeyColName

		SET @nStep=30
		SET @cCmd=N'SELECT TOP 1 @cKeyColCodeValue='+@cKeyColCode+',@cKeyColNameValue='+@cKeyCOlName+' FROM #tblLocFixAttr'
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@cKeyColCodeValue VARCHAR(10) OUTPUT,@cKeyColNameValue VARCHAR(500) OUTPUT',
		@cKeyColCodeValue OUTPUT,@cKeyColNameValue OUTPUT


		SET @nStep=40
		IF ISNULL(@cKeyColNameValue,'')<>'' AND ISNULL(@cKeyColCodeValue,'')=''
		BEGIN
			SET @nStep=45
			SELECT @cAttrTableName='LOC'+REPLACE(@cKeyColCode,'_key_code','')+'_mst'

			SET @nLoop=0
			WHILE @nLoop=0
			BEGIN
				SET @nStep=50
				EXEC GETNEXTKEY @cAttrTableName, @cKeyColCode, 7, @cLocId, 1,'',0, @CMEMONOVAL OUTPUT   
				
				SET @NSTEP = 60
				
				PRINT @CMEMONOVAL
				SET @cCmd=N'IF EXISTS ( SELECT '+@cKeyColCode+' FROM '+@cAttrTableName+' (nolock) WHERE '+@cKeyColCode+'='''+@CMEMONOVAL+''')
					SET @nLoop=0
				ELSE
					SET @NLOOP=1'
			    
				PRINT @cCmd
				EXEC SP_EXECUTESQL @cCMd,N'@nLoop int output',@nLoop Output

			END
			
			SET @cKeyColCodeValue=@cMemonoval

			SET @NSTEP = 65
			SET @cCmd=N'INSERT '+ @cAttrTableName+'	('+@cKeyColCode+','+ @cKeyColName+' )  
			SELECT '''+@cKeyColCodeValue+''','''+@cKeyColNameValue+''''
			PRINT @cCmd

			EXEC SP_EXECUTESQL @cCmd

			SET @nStep=70
			SET @cCmd=N'UPDATE #tblLocFixAttr SET '+@cKeyColCode+'='''+@CMEMONOVAL+''''
			PRINT @cCmd

			EXEC SP_EXECUTESQL @cCmd

		END

		
		--if @@spid=71
		--	select 'delete key',@cKeyColName,* from #tmpOpenkey
		DELETE FROM #tmpOpenkey where openkey_colname=@cKeyColName
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_UPDATE_LOCFIXATTRCOLS_tempdata at Step#'+ltrim(rtrim(str(@nStep)))+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

END
