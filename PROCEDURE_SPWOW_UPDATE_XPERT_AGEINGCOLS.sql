CREATE PROCEDURE SPWOW_UPDATE_XPERT_AGEINGCOLS
@cRepTempTable varchar(100),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(5),@CAgeingCol varchar(100),@nPrevAgeDays NUMERIC(5,0),@CPrevAgeingCol varchar(100),
	@bAgeXtab BIT,@nAgeDays NUMERIC(5,0),@cRepCol VARCHAR(100),@bFlag BIT,@cRepAgeingColUpd VARCHAR(200),@cRepColUpdExpr VARCHAR(200)


BEGIN TRY

	SET @cStep='20'
	SELECT @CAgeingCol='',@nPrevAgeDays=0,@CPrevAgeingCol='',@bAgeXtab=1

	--if @@spid=60
	--	select 'check initial #tmpAgeCols',* from  #tmpAgeCols

	WHILE @bAgeXtab=1
	BEGIN
		SET @cStep='30'
		SELECT TOP 1 @CAgeingCol=ageing_col,@nAgeDays=ageing_days FROM #tmpAgeCols 
		where rep_col='' ORDER BY ageing_col,ageing_days
		
		print 'Get ageing days for ageing col:'+@cAgeingCol+',agedays:'+str(@nAgeDays)

		IF @CPrevAgeingCol<>@CAgeingCol AND @CPrevAgeingCol<>''
		BEGIN
			SET @cStep='60'
			
			INSERT INTO #tmpAgeCols (ageing_col,rep_col,ageing_days,rep_ageing_col)
			SELECT @CPrevAgeingCol ageing_col,'>'+ltrim(rtrim(str(@nprevAgeDays))) as rep_col,
			@nPrevAgeDays+1  as ageing_days,'ageing_'+(CASE WHEN @CPrevAgeingCol='purchase ageing days' THEN '1' 
			WHEN @CPrevAgeingCol='Sale ageing days' THEN '2' ELSE '3' END) rep_ageing_col

			SELECT @nPrevAgeDays=0,@CPrevAgeingCol=''
		END

		SET @cRepCol=(CASE WHEN @nPrevAgeDays=0 THEN '<=' ELSE LTRIM(RTRIM(STR(@nPrevAgeDays+1)))+'-' END)+LTRIM(RTRIM(STR(@nAgeDays)))

		SET @cStep='70'
		print 'Update ageing col:'+@CAgeingCol+' with '+@cRepCol

		UPDATE #tmpAgeCols SET rep_col=@cRepCol,rep_ageing_col='ageing_'+
		(CASE WHEN ageing_col='purchase ageing days' THEN '1' WHEN ageing_col='Sale ageing days' THEN '2' ELSE '3' END)
		WHERE ageing_col=@CAgeingCol AND ageing_days=@nAgeDays

		SELECT @CPrevAgeingCol=@CAgeingCol,@nPrevAgeDays=@nAgeDays

		IF NOT EXISTS (SELECT TOP 1 ageing_col from #tmpAgeCols where rep_col='')
		begin
			SET @cStep='72'
			INSERT INTO #tmpAgeCols (ageing_col,rep_col,ageing_days,rep_ageing_col)
			SELECT @CPrevAgeingCol ageing_col,'>'+ltrim(rtrim(str(@nprevAgeDays))) as rep_col,
			@nPrevAgeDays+1  as ageing_days,'ageing_'+(CASE WHEN @CPrevAgeingCol='purchase ageing days' THEN '1' 
			WHEN @CPrevAgeingCol='Sale ageing days' THEN '2' ELSE '3' END) rep_ageing_col
			
			BREAK
		end
	END

	--if @@spid=60
	--BEGIN
	--	set @cCmd=N'SELECT ''check stock status'', * FROM '+@cRepTempTable+' where [ARTICLE NO.]=''BZ 1900'''
	--	exec sp_executesql @cCmd

	--	select 'check new #tmpAgeCols',* from  #tmpAgeCols
	--END
	SET @bFlag=1

	WHILE @bFlag=1
	BEGIN
		SET @cStep='74'
		SET @cRepAgeingColUpd=''
		SELECT TOP 1 @cRepAgeingColUpd=rep_ageing_col,@cRepColUpdExpr=rep_col,@cAgeingCol=ageing_col,
		@nAgeDays=ageing_days FROM 
		#tmpAgeCols WHERE ISNULL(processed,0)=0 ORDER BY ageing_col,ageing_days


		IF ISNULL(@cRepAgeingColUpd,'')=''
			BREAK

		--IF @@SPID=350
		--	SELECT 'CHECK Ageing col replace expression', @cRepTempTable,@cRepColUpdExpr,@cRepAgeingColUpd,@cRepColUpdExpr,@cAgeingCol

		SET @cStep='76.5'
		SET @cCmd=N'UPDATE '+@cRepTempTable+' SET '+@cRepAgeingColUpd+'='''+@cRepColUpdExpr+
					''' WHERE ISNULL(['+@cAgeingCol+'],0)'+(CASE WHEN CHARINDEX('-',@cRepColUpdExpr)=0 THEN @cRepColUpdExpr
					ELSE ' BETWEEN '+REPLACE(@cRepColUpdExpr,'-',' AND ') END)
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='78'
		UPDATE #tmpAgeCols SET processed=1 WHERE rep_ageing_col=@cRepAgeingColUpd AND ageing_days=@nAgeDays
	END


	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_UPDATE_XPERT_AGEINGCOLS at Step:'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
