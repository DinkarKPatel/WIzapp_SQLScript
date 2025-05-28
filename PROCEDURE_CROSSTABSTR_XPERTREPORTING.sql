CREATE PROCEDURE CROSSTABSTR_XPERTREPORTINg
(
	@cRepId VARCHAR(40),
	@cRepType VARCHAR(20)='',
	@cTempDb VARCHAR(200),
	@CTABLENAME VARCHAR(50), 
	@bCalledFromXpert BIT=0,
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
	DECLARE @CCELLCOLUMN VARCHAR(1500),@cStep VARCHAR(15), @nCrosstabType NUMERIC(1,0),
			@CAgeingCol VARCHAR(100),@nXtabCnt NUMERIC(10,0),@nXtabTot NUMERIC(2,0),
			@cDimColVal VARCHAR(50),
			@cCrossPara  VARCHAR(50),@cCrossParaName  VARCHAR(50),@nColOrder NUMERIC(10,0),
			@cColHeader   VARCHAR(200),
			@CCROSSPARAORDER VARCHAR(50),@bSizeXtab BIT,@bMonthXtab BIT,
			@cColtype VARCHAR(40),@CPrevAgeingCol VARCHAR(100),
			@CCOL VARCHAR(40), @cXpertRepCode VARCHAR(5),
			@CCOL2 VARCHAR(40), 
			@CCOL3 VARCHAR(40),@cAgeCol VARCHAR(100),@bDateXtab BIT,
			@CCOL4 VARCHAR(40),@nCntKeyCol NUMERIC(2,0), @nCnt NUMERIC(2,0),
			@CCMD NVARCHAR(4000), @bAgeXtab bit,@bGstXtab BIT,
			@NCOLCOUNTER NUMERIC(3), @cRepCol VARCHAR(100),
			@CCOLALIAS VARCHAR(200),@nAgeDays NUMERIC(7,0),@nPrevAgeDays NUMERIC(7,0),
			@CRETCOLSTR2 NVARCHAR(MAX)=N''
	
BEGIN TRY
	SET @cErrormsg=''
	SET @cStep='10'

	SET @CRETCOLSTR = N''
	SET @NCOLCOUNTER = 1
	
    SELECT distinct col_expr as dim_col,convert(bit,0) datetypecol
	into #tmpDimCols  
	FROM REP_DET  WHERE 1=2
	
	SET @cStep='20'
	IF @bCalledFromXpert=1
		INSERT INTO #tmpDimCols (dim_col,datetypecol)
		SELECT DISTINCT '['+b.col_header+']',ISNULL(datecol,0)  datetypecol FROM transaction_analysis_MASTER_COLS a
		JOIN #rep_det b ON a.col_name=b.key_col
		WHERE DIMENSION=1 AND  rep_type=@cRepType
		UNION 
		SELECT col_expr,0 datetypecol FROM #rep_det WHERE col_expr IN ('AGEING_1','AGEING_2','AGEING_3')
	ELSE
		INSERT INTO #tmpDimCols (dim_col,datetypecol)
		SELECT col_expr,0 datetypecol FROM rep_det where rep_id=@cRepId AND Dimension=1
	
	SELECT @bAgeXtab=1,@cXpertRepCode=''

	SET @cStep='23'
	IF @bCalledFromXpert=1
		SELECT @cXpertRepCode=xpert_rep_code FROM #rep_mst

	--IF @@spid=954
	--	SELECT 'check dimcols', * FROM #tmpDimCols
	--BEGIN
	--	select 'check tmpagecols',@bCalledFromXpert CalledFromXpert,* from #tmpAgeCols
	
	--	select * from #rep_det where dimension=1

	--END
	SET @cStep='40'
	IF NOT EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE dim_col like '%ageing%')
	BEGIN
		DELETE FROM #tmpAgeCols
		SET @bAgeXtab=0
	END

	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE dim_col like '%transaction_month_name%')
		SET @bMonthXtab=1
	
	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE dim_col like '%para2%')
		SET @bSizeXtab=1

	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE dim_col like '%gst%')
		SET @bGstXtab=1
	
	IF EXISTS (SELECT TOP 1 * FROM #tmpDimCols WHERE datetypecol=1)
		SET @bDateXtab=1
	
	--if @@spid=482
	--	select 'check #tmpAgeCols',* from #tmpAgeCols


	--if @@spid=98
	--	select 'check Final #tmpAgeCols',* from #tmpAgeCols order by ageing_col
	
	declare @nTotLoopCnt numeric(10,0)
	set @nTotLoopCnt=0
	SET @cStep='90'
	SELECT key_col,CONVERT(NUMERIC(10,0),0) col_order INTO #tmpKeyCol FROM rep_det (NOLOCK) WHERE 1=2

	--if @@spid=129
	--	select 'check dimcols',* from #tmpDimCols

	CREATE TABLE #tmpLoopXtab (dim_colval varchar(500),col_order numeric(12,2),age_col VARCHAR(100))


	WHILE EXISTS (SELECT TOP 1 * FROM #tmpDimCols)
	BEGIN
	   SELECT TOP 1 @cCrossPara=dim_col FROM #tmpDimCols	
		   
	   SET @cStep='100'
	   SET @cColtype=(CASE WHEN	LEFT(@cCrossPara,6)='AGEING' THEN 
	   (CASE WHEN	@cCrossPara='AGEING_2' THEN 'Sales' ELSE 'Stock' END) ELSE '' END)
	   
	   DELETE FROM #tmpKeyCol
	   DELETE FROM #tmpLoopXtab
	  
	  --SELECT DISTINCT ISNULL(A.' + @CCROSSPARA + ','''') AS COL1,'+
				
   	   SET @cStep='105'
   	   SET @CCMD = N'
				SELECT DISTINCT ISNULL(A.' + @CCROSSPARA + ','''') AS COL1,'+
				(CASE WHEN @bAgeXtab=1 THEN 'isnull(b.ageing_days,0) AS COL_ORDER ,isnull(b.ageing_col,'''') age_col' 
					  WHEN @bSizeXtab=1 THEN 'isnull(b.para2_order,0) AS COL_ORDER,'''' age_col' 
					  WHEN @bMonthXtab=1 THEN 'isnull(xn_month_id,0) AS COL_ORDER,'''' age_col' 
					  WHEN @bDateXtab=1 THEN 'convert(varchar(10),'+@cCrossPara+',112) AS COL_ORDER,'''' age_col' 
					  WHEN @bGstXtab=1 THEN 'CONVERT(NUMERIC(6,2),isnull(a.[Gst%],'''')) AS COL_ORDER,'''' age_col' 
					  ELSE '0 as col_order,'''' age_col' END)+'
				FROM '+@cTempDb+'[' + @CTABLENAME + '] A '+(CASE WHEN @bAgeXtab=1 THEN '
				LEFT JOIN #tmpAgeCols b ON a.'+@CCROSSPARA+'=b.rep_col	AND b.rep_ageing_col='''+@cCrossPara+''''
				WHEN @bSizeXtab=1 THEN  'LEFT JOIN para2 b ON b.para2_name=a.'+@cCrossPara ELSE '' END)+'
				WHERE ISNULL(A.' + @CCROSSPARA + ','''')<>'''' 
				'+(CASE WHEN @bAgeXtab=1 OR @bSizeXtab=1 OR @bGstXtab=1 OR @bMonthXtab=1 OR @bDateXtab=1 THEN ' ORDER BY  2'	ELSE '' END)
	
		print @CCMD

		INSERT INTO #tmpLoopXtab (dim_colval,col_order ,age_col)
		EXEC SP_EXECUTESQL @CCMD

		SET @cStep='110'
		;WITH ctedup
		as
		(select *,ROW_NUMBER() OVER (PARTITION BY dim_colval,age_col ORDER BY DIM_COLVAL) RNO FROM #tmpLoopXtab
		)

		DELETE FROM ctedup WHERE rno>1
		
				
		WHILE EXISTS (SELECT TOP 1 * FROM #tmpLoopXtab)
		BEGIN
			SET @cStep='120'

			---Change done for Size ctab error coming in Buyer order analysis (Date:14-09-2021)
			--SELECT (CASE WHEN @bCalledFromXpert=1 THEN '['+col_header+']' ELSE key_col END),col_order

			SELECT TOP 1 @cDimColVal=dim_colval ,@nColOrder=col_order,@cAgeCol=age_col
			FROM #tmpLoopXtab ORDER BY col_order

			SET @cStep='125'

			INSERT INTO #tmpKeyCol (key_col,col_order)
			SELECT (CASE WHEN @bCalledFromXpert=1 THEN  '['+a.col_header+']' ELSE key_col END),a.col_order
			FROM #rep_det a
			LEFT JOIN transaction_analysis_calculative_COLS b (NOLOCK) ON a.key_col=b.col_name AND b.rep_type=@cRepType
			 WHERE (a.col_type=@cColtype OR @cColtype='')
			AND a.Mesurement_col=1
			ORDER BY a.col_order

			SET @cStep='128'

			SELECT @nXtabTot=count(*) FROM #tmpKeyCol

			SET @nXtabCnt=0

			--IF @@spid=954
			--	SELECT 'check #tmpKeyCol',@bDateXtab,@cDimColVal,@nColOrder,@cAgeCol,* from #tmpKeyCol

			WHILE EXISTS (SELECT TOP 1 * FROM #tmpKeyCol)
			BEGIN
				set @nTotLoopCnt=	@nTotLoopCnt+1
				SET @cStep='130.22'
				SELECT TOP 1 @CCELLCOLUMN=key_col FROM #tmpKeyCol ORDER BY col_order
				SET @cStep='130.25' 
                SET @nXtabCnt=@nXtabCnt+1

				SET @cStep='130.28'
				SET @CCOLALIAS =  (CASE WHEN @bDateXtab=1 THEN CONVERT(VARCHAR,CONVERT(DATE,@cDimColval),105) ELSE  @cDimColVal END)+(CASE WHEN @bMonthXtab=1 THEN LEFT(LTRIM(RTRIM(STR(@nColOrder))),4) ELSE '' END)+
				(CASE WHEN @cAgeCol<>'' THEN '_'+@cAgeCol ELSE '' END)
				
				SET @cStep='130.4'
				SET @CRETCOLSTR = @CRETCOLSTR + (CASE WHEN @CRETCOLSTR<>'' THEN N', ' ELSE '' END )+N'
									SUM( CASE WHEN ' + @CCROSSPARA + ' = ''' + @cDimColVal + ''' THEN ' +
									@CCELLCOLUMN + ' ELSE 0 END ) AS ' + 
									(CASE WHEN @nXtabTot>1 THEN '['+@CCOLALIAS+'_'+
									REPLACE(REPLACE(@CCELLCOLUMN,'[',''),']','')+'_'+ltrim(rtrim(STR(@nXtabCnt))) 
									ELSE '['+ @CCOLALIAS  END)+']'
				
				


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
		SELECT (CASE WHEN @bCalledFromXpert=1 THEN  '['+a.col_header+']' ELSE key_col END),col_order
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b (NOLOCK) ON a.key_col=b.col_name AND b.rep_type=@cRepType
		WHERE (col_type=@cColtype OR @cColtype='')
		AND Mesurement_col=1


		SET @cStep='132.5'
		SELECT @nCntKeyCol=count(*) from #tmpKeyCol

		SET @nXtabCnt=1
		WHILE EXISTS (SELECT TOP 1 * FROM #tmpKeyCol)
		BEGIN
			SET @cStep='135'
			SELECT TOP 1 @CCELLCOLUMN=key_col FROM #tmpKeyCol ORDER BY col_order

			SET @cStep='140'
			SET @CCOLALIAS = 'Total'+(CASE WHEN @bAgeXtab=1 THEN '_'+@cAgeCol ELSE '' END)+
			(CASE WHEN @nCntKeyCol>1 THEN '_'+REPLACE(REPLACE(@CCELLCOLUMN,'[',''),']','')+'_'+ltrim(rtrim(str(@nXtabCnt))) ELSE '' END)

			SET @CRETCOLSTR = @CRETCOLSTR + (CASE WHEN @CRETCOLSTR<>'' THEN N', ' ELSE '' END )+N'
								SUM(' + @CCELLCOLUMN + ') AS ' + '['+ @CCOLALIAS + ']'
			
			SET @nXtabCnt=@nXtabCnt+1
			DELETE FROM #tmpKeyCol WHERE key_col=@CCELLCOLUMN
		END

		--if @@spid=436
		--	select  @nXtabCnt totloopcnt,@cRetColstr

		
		DELETE FROM #tmpDimCols WHERE dim_col=@cCrossPara
	END

	GOTO END_PROC
END TRY

BEGIN CATCH

	SET @cErrormsg='Error in Procedure CROSSTABSTR_XPERTREPORTINg at Step#'+@cStep+' '+ERROR_MESSAGE()
	print 'Error in crosstab proc:'+ @cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

	SET NOCOUNT OFF

END