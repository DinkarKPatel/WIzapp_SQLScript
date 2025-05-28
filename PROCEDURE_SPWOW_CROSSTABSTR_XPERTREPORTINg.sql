CREATE PROCEDURE SPWOW_CROSSTABSTR_XPERTREPORTINg
(
	@cXpertRepCode VARCHAR(10),
	@cRepTempTable VARCHAR(200),
	@CRETCOLSTR NVARCHAR(MAX) OUTPUT,
	@cErrormsg VARCHAR(MAX) OUTPUT
	--SECOND PIVOT COL
)
----WITH ENCRYPTION
AS
BEGIN
    SET NOCOUNT ON
	--******** PARAMETERS
	-- @CTABLENAME :		SOURCE TABLE IN WHICH THE DATA LIES IN TABULAR FORMAT
	-- @CCROSSPARA :		NAME OF COLUMN ON WHICH YOU WANT TO GENERATE CROSS TAB
	-- @CCROSSPARAORDER :	NAME OF COLUMN FOR THE ORDER OF CROSSTAB PARA
	--						IF LEFT BLANK, IT WILL ORDERED ON COLUMN SPECIFIED IN CROSSTABPARA
	-- @CCELLCOLUMN1 :		COLUMN1 OF VALUE TO BE DISPLAYED AS CELLVALUE
	-- @CCELLCOLUMN2 :		COLUMN2 OF VALUE TO BE DISPLAYED AS CELLVALUE (OPTIONAL)
	-- @CCELLCOLUMN3 :		COLUMN2 OF VALUE TO BE DISPLAYED AS CELLVALUE (OPTIONAL)
	-- @CRETCOLSTR :		OUTPUT VARCHAR TYPE VARIABLE FOR RETURN OF THE STRING


	-- ACTUAL PROCESSING STARTS HERE...
	--******** START OF BATCH
	DECLARE @CCELLCOLUMN VARCHAR(1500),@cStep VARCHAR(15), @nCrosstabType NUMERIC(1,0),@cDimColName VARCHAR(200),
			@CAgeingCol VARCHAR(100),@nXtabCnt NUMERIC(10,0),@nXtabTot NUMERIC(2,0),
			@cDimColVal VARCHAR(50),@cOrderbyColumn VARCHAR(200),
			@cCrossPara  VARCHAR(50),@cCrossParaName  VARCHAR(50),@cColOrder VARCHAR(100),
			@cColHeader   VARCHAR(200),@CCROSSPARAORDER VARCHAR(50),@bMonthXtab BIT,
			@cColtype VARCHAR(40),@CPrevAgeingCol VARCHAR(100),
			@CCOL VARCHAR(40), 	@CCOL2 VARCHAR(40), @bPeriodComparisonReport BIT,
			@CCOL3 VARCHAR(40),@cAgeCol VARCHAR(100),@bDateXtab BIT,
			@CCOL4 VARCHAR(40),@nCntKeyCol NUMERIC(2,0), @nCnt NUMERIC(2,0),
			@CCMD NVARCHAR(4000), @bAgeXtab bit,@bGstXtab BIT,@bBulkExport bit,
			@NCOLCOUNTER NUMERIC(3), @cRepCol VARCHAR(100),@nAgeDimColsCnt NUMERIC(1,0),
			@CCOLALIAS VARCHAR(200),@nAgeDays NUMERIC(7,0),@nPrevAgeDays NUMERIC(7,0),
			@CRETCOLSTR2 NVARCHAR(MAX)=N'',@cXtabColsList NVARCHAR(MAX)=N''
	
BEGIN TRY
	SET @cErrormsg=''
	SET @cStep='10'

	SET @CRETCOLSTR = N''
	SET @NCOLCOUNTER = 1
	
    SELECT distinct col_expr as dim_col,convert(bit,0) datetypecol,col_header,order_by_column_id,col_header order_by_column
	into #tmpDimCols  
	FROM #wow_xpert_rep_det  WHERE 1=2
	
	SET @cStep='15'
	PRINT 'Inserting DImension columns information-1'
	INSERT INTO #tmpDimCols (dim_col,datetypecol,col_header,order_by_column_id,order_by_column)
	SELECT DISTINCT '['+a.col_expr+']',(CASE WHEN col_data_type='Date' THEN 1 ELSE 0 END) datetypecol,c.col_header,
	(CASE WHEN ISNULL(c.order_by_column_id,'')='' THEN c.column_id ELSE c.order_by_column_id END) order_by_column_id,''
	FROM wow_xpert_report_cols_expressions a
	JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
	JOIN #wow_xpert_rep_det c ON c.column_id=b.column_id AND c.xn_type=b.xn_type
	WHERE DIMENSION=1 
	UNION 
	SELECT DISTINCT '['+a.col_expr+']',0 datetypecol,a.col_header,
	a.column_id order_by_column_id,''
	FROM #wow_xpert_rep_det a WHERE column_id in ('period')
	

	PRINT 'Inserting DImension columns information-2'
	UPDATE a SET order_by_column=b.col_header FROM #tmpDimCols a
	JOIN #wow_xpert_rep_det b ON b.column_id=a.order_by_column_id

	SELECT @bAgeXtab=1


	SET @bPeriodComparisonReport=0
	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols where dim_col='[period base]')
		SET @bPeriodComparisonReport=1


	PRINT 'Inserting DImension columns information-3'
	SET @cStep='20'
	IF NOT EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE order_by_column_id like '%ageing%')
		SET @bAgeXtab=0

	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE datetypecol=1)
		SET @bDateXtab=1
	
	declare @nTotLoopCnt numeric(10,0)
	set @nTotLoopCnt=0
	SET @cStep='90'
	SELECT key_col,CONVERT(NUMERIC(10,0),0) col_order INTO #tmpKeyCol FROM rep_det (NOLOCK) WHERE 1=2

	CREATE TABLE #tmpLoopXtab (dimColName VARCHAR(100), dim_colval varchar(500),col_order VARCHAR(100),age_col VARCHAR(100))

	SELECT @nAgeDimColsCnt=count(*) FROM #tmpDimCols


	--if @@spid=75
	--begin
	--	--select 'dimcols'
	--		select 'check dimcols',* from #tmpDimCols
	--		--select 'check #wow_xpert_rep_det for ageing',* from #wow_xpert_rep_det
	--end@bBulkExport


	SELECT TOP 1 @bBulkExport=BulkExport FROM  #wow_xpert_rep_mst

	WHILE EXISTS (SELECT TOP 1 * FROM #tmpDimCols)
	BEGIN
	   SELECT TOP 1 @cDimCOlName=dim_col, @cCrossPara=col_header,@cOrderbyColumn='['+order_by_column+']' FROM #tmpDimCols	
		   
	   SET @cStep='100'
	   DELETE FROM #tmpKeyCol
	   DELETE FROM #tmpLoopXtab
				
   	   SET @cStep='105'
   	   SET @CCMD = N'
				SELECT DISTINCT '''+replace(@cDimColName,'''','')+''' dimcolName, ISNULL(A.[' + @CCROSSPARA + '],'''') AS COL1,'+
				(CASE WHEN @bAgeXtab=1 THEN 'isnull(b.colOrder,0) AS COL_ORDER ,isnull(b.rep_ageing_col,'''') age_col'
					  WHEN @bDateXtab=1 THEN 'convert(varchar(10),a.[' +@cCrossPara+'],112) AS COL_ORDER,'''' age_col' 
					  ELSE @cOrderbyColumn+' as col_order,'''' age_col' END)+'
				FROM ' + @cRepTempTable + ' A '+(CASE WHEN @bAgeXtab=1 THEN '
				LEFT JOIN #tmpAgeCols b ON a.['+@CCROSSPARA+']=b.rep_col	AND b.rep_ageing_col='''+@cCrossPara+''''
				ELSE '' END)+'
				WHERE ISNULL(A.[' + @CCROSSPARA + '],'''')<>'''' ORDER BY 2'
	
		print @CCMD

		INSERT INTO #tmpLoopXtab (dimcolName,dim_colval,col_order ,age_col)
		EXEC SP_EXECUTESQL @CCMD


		

		SET @cStep='110'
		;WITH ctedup
		as
		(select *,ROW_NUMBER() OVER (PARTITION BY dim_colval,age_col ORDER BY col_order) RNO FROM #tmpLoopXtab
		)

		DELETE FROM ctedup WHERE rno>1
		
		--if @@spid=178
		--	select 'check #tmpLoopXtab',* from #tmpLoopXtab
				
		SELECT TOP 1 @cDimColName=dimcolName FROM #tmpLoopXtab

		WHILE EXISTS (SELECT TOP 1 * FROM #tmpLoopXtab)
		BEGIN
			SET @cStep='120'

			
			IF @cDimColName='[Sku_Names.Para2_Name]' OR @cDimColName like '%ageing%'
				SELECT TOP 1 @cDimColVal=dim_colval ,@cColOrder=col_order,@cAgeCol=age_col
				FROM #tmpLoopXtab ORDER BY  CONVERT(numeric(5,0),col_order) 
			ELSE
				SELECT TOP 1 @cDimColVal=dim_colval ,@cColOrder=col_order,@cAgeCol=age_col
				FROM #tmpLoopXtab ORDER BY col_order
				
			SET @cStep='125'

			INSERT INTO #tmpKeyCol (key_col,col_order)
			SELECT  '['+a.col_header+']',a.col_order
			FROM #wow_xpert_rep_det a
			WHERE a.Measurement_col=1
			ORDER BY a.col_order

			SET @cStep='128'

			SELECT @nXtabTot=count(*) FROM #tmpKeyCol

			SET @nXtabCnt=0

			--IF @@spid=339
			--	SELECT 'check all #tmpKeyCol',@bDateXtab,@cDimColVal,col_order,@cAgeCol,* from #tmpKeyCol

			WHILE EXISTS (SELECT TOP 1 * FROM #tmpKeyCol)
			BEGIN
				set @nTotLoopCnt=	@nTotLoopCnt+1
				SET @cStep='130.22'
				SELECT TOP 1 @CCELLCOLUMN=key_col FROM #tmpKeyCol ORDER BY col_order
                SET @nXtabCnt=@nXtabCnt+1

				SET @cStep='130.28'
				SET @CCOLALIAS =  (CASE WHEN @bDateXtab=1 THEN CONVERT(VARCHAR,CONVERT(DATE,@cDimColval),105) ELSE  @cDimColVal END)+
				(CASE WHEN @bMonthXtab=1 THEN LEFT(LTRIM(RTRIM(@cColOrder)),4) ELSE '' END)+
				(CASE WHEN @cAgeCol<>'' AND @nAgeDimColsCnt>1 THEN '_'+@cAgeCol ELSE '' END)
				
				if @cXpertRepCode='R6' --- Need to do this as Anil demanded this suffix for identifying the cross tab columns at Application level
									   --- for Eoss schemes identification (Sanjay:14-11-2024)
					SET @cColAlias=@cColAlias+'_xtab'

				SET @CCOLALIAS=(CASE WHEN @nXtabTot>1 AND @bPeriodComparisonReport=0 THEN '['+@CCOLALIAS+'_'+REPLACE(REPLACE(@CCELLCOLUMN,'[',''),']','')+'_'+
								ltrim(rtrim(STR(@nXtabCnt))) WHEN @bPeriodComparisonReport=1 THEN '['+@CCOLALIAS+ REPLACE(REPLACE(@CCELLCOLUMN,'[',' '),']','') 
								ELSE '['+ @CCOLALIAS  END)+']'
				
					SET @cXtabColsList=@cXtabColsList+(CASE WHEN @cXtabColsList<>'' THEN ',' ELSE '' END)+
					(CASE WHEN @bBulkExport=1 THEN 'CONVERT(VARCHAR,' ELSE '' END)+@CCOLALIAS+
					(CASE WHEN @bBulkExport=1 THEN ') '+@CCOLALIAS ELSE '' END)

				SET @cStep='130.4'
				SET @CRETCOLSTR = @CRETCOLSTR + (CASE WHEN @CRETCOLSTR<>'' THEN N', ' ELSE '' END )+N'
									SUM( CASE WHEN [' + @CCROSSPARA + '] = ''' + @cDimColVal + ''' THEN ' +
									@CCELLCOLUMN + ' ELSE 0 END ) AS ' +@cCOlAlias
									
									
				
				


				SET @cStep='130.6'
				DELETE FROM #tmpKeyCol WHERE key_col=@CCELLCOLUMN
				

			END
			SET @cStep='130.8'
			DELETE FROM #tmpLoopXtab WHERE dim_colval=@cDimColVal AND age_col=@cAgeCol
			
		END
		

		--if @@spid=436
		--	select  @nTotLoopCnt totloopcnt,@cRetColstr

		SET @cStep='131.2'
		INSERT INTO #tmpKeyCol (key_col,col_order)
		SELECT  '['+a.col_header+']',a.col_order
		FROM #wow_xpert_rep_det a
		WHERE a.Measurement_col=1
		ORDER BY a.col_order

		SET @cStep='132.5'
		SELECT @nCntKeyCol=count(*) from #tmpKeyCol


		--if @@spid=100
		--	select 'check #tmpKeyCol for crosstab',* from #tmpKeyCol


		SET @nXtabCnt=1
		WHILE EXISTS (SELECT TOP 1 * FROM #tmpKeyCol)
		BEGIN
			SET @cStep='135'
			SELECT TOP 1 @CCELLCOLUMN=key_col FROM #tmpKeyCol ORDER BY col_order

			SET @cStep='140'
			SET @CCOLALIAS = (CASE WHEN @bPeriodComparisonReport=1 THEN '[Variance '+REPLACE(REPLACE(@CCELLCOLUMN,'[',''),']','') ELSE 
			'[Total'+(CASE WHEN @bAgeXtab=1 AND @nAgeDimColsCnt>1 THEN '_'+@cAgeCol ELSE '' END) END)+
			(CASE WHEN @nCntKeyCol>1 AND @bPeriodComparisonReport=0 THEN '_'+REPLACE(REPLACE(@CCELLCOLUMN,'[',''),']','')+'_'+ltrim(rtrim(str(@nXtabCnt))) ELSE '' END)+']'

			print 'Enter cxtabcolslist assignment'
			SET @cXtabColsList=@cXtabColsList+(CASE WHEN @cXtabColsList<>'' THEN ',' ELSE '' END)+
			(CASE WHEN @bBulkExport=1 THEN 'CONVERT(VARCHAR,' ELSE '' END)+@CCOLALIAS+
			(CASE WHEN @bBulkExport=1 THEN ') '+@CCOLALIAS ELSE '' END)

			SET @CRETCOLSTR = @CRETCOLSTR + (CASE WHEN @CRETCOLSTR<>'' THEN N', ' ELSE '' END )+
							(CASE WHEN @bPeriodComparisonReport=0 THEN  N'SUM(' + @CCELLCOLUMN + ') AS ' +  @CCOLALIAS  
							ELSE 
							N'ltrim(rtrim(str(SUM(CASE WHEN [PERIOD BASE]=''PERIOD1'' THEN ISNULL('+@CCELLCOLUMN+',0) ELSE ISNULL('+@CCELLCOLUMN+'*-1,0) END))))'+
							'+'' ('''+
							'+ltrim(rtrim(str((SUM(CASE WHEN [PERIOD BASE]=''PERIOD1'' THEN ISNULL('+@CCELLCOLUMN+',0) ELSE ISNULL('+@CCELLCOLUMN+'*-1,0) END)/
							(CASE WHEN SUM(CASE WHEN [PERIOD BASE]=''PERIOD2'' THEN ISNULL('+@CCELLCOLUMN+',0) ELSE 0 END)=0 THEN 1 ELSE 
									   SUM(CASE WHEN [PERIOD BASE]=''PERIOD2'' THEN ISNULL('+@CCELLCOLUMN+',0)  END) END))*100)))+''%)'' as '+@CCOLALIAS END)
							
			
			SET @nXtabCnt=@nXtabCnt+1
			DELETE FROM #tmpKeyCol WHERE key_col=@CCELLCOLUMN
		END

		--if @@spid=436
		--	select  @nXtabCnt totloopcnt,@cRetColstr

		--select 'check delete @cCrossPara',@cCrossPara CrossPara,* from #tmpDimCols
	lblNextDim:
		DELETE FROM #tmpDimCols WHERE col_header=@cCrossPara
	END

	UPDATE #wow_xpert_rep_mst SET xtab_cols_list=@cXtabColsList

	GOTO END_PROC
END TRY

BEGIN CATCH

	SET @cErrormsg='Error in Procedure SPWOW_CROSSTABSTR_XPERTREPORTINg at Step#'+@cStep+' '+ERROR_MESSAGE()
	print 'Error in crosstab proc:'+ @cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

	SET NOCOUNT OFF

END