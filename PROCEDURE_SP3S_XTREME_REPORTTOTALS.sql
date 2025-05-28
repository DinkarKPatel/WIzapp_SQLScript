CREATE PROCEDURE SP3S_XTREME_REPORTTOTALS
@cRepId VARCHAR(40),
@cRepType VARCHAR(20)='',
@cTempDb VARCHAR(200)='',
@cTempTable VARCHAR(200),
@cPaymodeCols VARCHAR(2000)='',
@bCalledFromXpert BIT=0,
@cAddnlFilter VARCHAR(MAX)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cMasterCol VARCHAR(2000),@cGrpMasterCol VARCHAR(2000),@cCalculativeColsVal VARCHAR(MAX),
	@bLoop BIT,@cColOrder VARCHAR(2000),@nMasterColCnt NUMERIC(1,0),@cOuterCalculativeCols VARCHAR(MAX),@bGrpColChecked BIT,
	@cOrgMasterCol VARCHAR(2000),@cGrpMasterColVal VARCHAR(MAX),@cGrpMasterColTotal VARCHAR(MAX),@cGrpTotalColsFirst VARCHAR(100),
	@cMainGrpMasterCol VARCHAR(MAX),@cRepeatCols VARCHAR(max),@bCalculativeCol BIT,@cXpertRepCode VARCHAR(10),
	@cDimCol VARCHAR(200),@cMeasureCol VARCHAR(200),@cGrpTotalCols VARCHAR(MAX),@cFinalOutputCols VARCHAR(MAX),
	@cOutputCol VARCHAR(300),@cGstCol VARCHAR(100),@cGrpMasterColValOrd VARCHAR(MAX),@bGrpTotalCol BIT,
	@CRETCOLSTR NVARCHAR(MAX),@cXntype VARCHAR(100),@nGrpCols NUMERIC(2,0),@cStep VARCHAR(5),@cRetGroupingSets VARCHAR(MAX),
	@cRetPivotExpr VARCHAR(MAX),@cRetUnPivotExpr VARCHAR(MAX),@nCrosstabType NUMERIC(1,0),@cRetCalculativeCols VARCHAR(MAX),
	@cPivotGrpMasterColsVal VARCHAR(MAX),@cPivotCalculativeCols VARCHAR(MAX),@bDimensionCol bit,@cRollUpTotalCols VARCHAR(MAX)

BEGIN TRY

	SET @cStep='10'
	SET @cErrormsg=''			
	SET @cStep='20'
	SET @cXntype=''

	IF @bCalledFromXpert=1
		SELECT TOP 1 @cXntype=xn_type FROM #REP_DET_XNTYPES
	ELSE
		SELECT * INTO #rep_det FROM rep_det (NOLOCK) WHERE rep_id=@cRepId

	
	SELECT @nCrosstabType=CrossTab_Type,@cXpertRepCode=xpert_rep_code from  #rep_mst 
	IF ISNULL(@nCrosstabType,0)=0 AND @bCalledFromXpert=1 AND @cRepType='SMRY'
	BEGIN
		SELECT TOP 1 @cGstCol=key_col FROM #rep_det WHERE key_col='gst_pct'
		IF ISNULL(@cGstCol,'')<>''
		BEGIN
			UPDATE #rep_det SET Dimension=1 WHERE key_col IN ('gst_pct')
			UPDATE #rep_det SET Mesurement_col=1 WHERE key_col IN ('taxable_value','gst_cess_amount','igst_amount','lgst_amount')
			SET @nCrosstabType=1

		END
	END

	SELECT @nGrpCols=count(*) FROM #rep_det a 	WHERE REP_ID=@cRepId
	AND Calculative_col=0 AND  Dimension=0 
	

	SELECT a.col_expr,COALESCE(b.col_header,c.col_header) col_header_exp,a.col_header,a.col_order,
		(CASE WHEN Calculative_col=1 AND COALESCE(b.col_header,a.col_header) NOT LIKE '%Total Discount %%' THEN 1
			   ELSE 0 END) calculative_col	,GRP_TOTAL,a.dimension dimcol
	INTO #tmpGrpCols 	FROM #rep_det a
	LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type=@cXnType and b.rep_type=@cRepType
	LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type=@cXnType and c.rep_type=@cRepType
	WHERE 1=2

	IF @cXpertRepCode='R1'
	BEGIN
		INSERT INTO #tmpGrpCols (col_expr,col_header_exp,col_header,col_Order,calculative_col,grp_total,dimcol)
		SELECT DISTINCT a.col_expr,COALESCE(a.col_header,b.col_header,c.col_header) col_header_exp,a.col_header,a.col_order,
		(CASE WHEN Calculative_col=1 AND COALESCE(b.col_header,a.col_header) NOT LIKE '%Total Discount %%' THEN 1
			   ELSE 0 END) calculative_col	,GRP_TOTAL,a.dimension
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.rep_type=@cRepType
		WHERE  (Calculative_col=0 OR COALESCE(b.col_header,c.col_header) LIKE '%Total Discount %%'
				OR NOT(Mesurement_col=1 AND @nCrosstabType=1) OR @nCrosstabType=2)
		AND  (Dimension=0 OR @nCrosstabType=2)  AND (b.col_name IS NOT NULL OR c.col_name IS NOT NULL)
		AND a.col_mst IS NOT NULL

		INSERT INTO #tmpGrpCols (col_expr,col_header_exp,col_header,col_Order,calculative_col,grp_total,dimcol)
		SELECT DISTINCT  a.col_expr,COALESCE(a.col_header,b.col_header,c.col_header,
		(CASE WHEN @cXpertRepCode='R1' THEN a.col_header WHEN a.calculative_col=1 THEN a.key_col ELSE a.col_expr END)) col_header_exp,a.col_header,a.col_order,
		(CASE WHEN a.Calculative_col=1 AND COALESCE(b.col_header,a.col_header) NOT LIKE '%Total Discount %%' THEN 1
			   ELSE 0 END) as calculative_col,A.grp_total,a.dimension
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type='COMMON' and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type='COMMON' and c.rep_type=@cRepType
		LEFT JOIN #tmpGrpCols d ON d.col_header=a.col_header
		WHERE  (a.Calculative_col=0 OR COALESCE(b.col_header,c.col_header) LIKE '%Total Discount %%'
				OR NOT(Mesurement_col=1 AND @nCrosstabType=1) OR @nCrosstabType=2) AND ISNULL(b.col_expr,'') NOT IN ('Payment_Groups','Payment_Modes')
		AND  (Dimension=0 OR @nCrosstabType=2)   AND (b.col_name IS NOT NULL OR c.col_name IS NOT NULL OR a.col_expr<>'xn_type')
		AND d.col_header IS NULL
		AND a.col_mst IS NOT NULL
	END
	ELSE
	BEGIN

		INSERT INTO #tmpGrpCols (col_expr,col_header_exp,col_header,col_Order,calculative_col,grp_total,dimcol)
		SELECT a.col_expr,COALESCE(a.col_header,b.col_header,c.col_header,d.col_header,(CASE WHEN a.calculative_col=1 THEN a.key_col ELSE a.col_expr END)) 
		col_header_exp,a.col_header,a.col_order,
		(CASE WHEN Calculative_col=1 AND COALESCE(b.col_header,a.col_header) NOT LIKE '%Total Discount %%' THEN 1
			   ELSE 0 END) calculative_col	,GRP_TOTAL,a.dimension
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type=@cXnType and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type=@cXnType and c.rep_type=@cRepType
		LEFT JOIN transaction_analysis_calculative_COLS d on d.col_name=a.key_col and d.xn_type=@cXnType+'(OH)' and d.rep_type=@cRepType
		WHERE  (Calculative_col=0 OR COALESCE(b.col_header,c.col_header) LIKE '%Total Discount %%'
				OR NOT(Mesurement_col=1 AND @nCrosstabType=1) OR @nCrosstabType=2) AND ISNULL(b.col_expr,'') NOT IN ('Payment_Groups','Payment_Modes')
		AND  (Dimension=0 OR @nCrosstabType=2)   AND (b.col_name IS NOT NULL OR c.col_name IS NOT NULL OR d.col_name IS NOT NULL)
	

		INSERT INTO #tmpGrpCols (col_expr,col_header_exp,col_header,col_Order,calculative_col,grp_total,dimcol)
		SELECT a.col_expr,COALESCE(a.col_header,b.col_header,c.col_header,
		(CASE WHEN a.calculative_col=1 THEN a.key_col ELSE a.col_expr END)) col_header_exp,a.col_header,a.col_order,
		(CASE WHEN a.Calculative_col=1 AND COALESCE(b.col_header,a.col_header) NOT LIKE '%Total Discount %%' THEN 1
			   ELSE 0 END) as calculative_col,A.grp_total,a.dimension
		FROM #rep_det a
		LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type='COMMON' and b.rep_type=@cRepType
		LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type='COMMON' and c.rep_type=@cRepType
		LEFT JOIN #tmpGrpCols d ON d.col_header=a.col_header
		WHERE  (a.Calculative_col=0 OR COALESCE(b.col_header,c.col_header) LIKE '%Total Discount %%'
				OR NOT(Mesurement_col=1 AND @nCrosstabType=1) OR @nCrosstabType=2) AND ISNULL(b.col_expr,'') NOT IN ('Payment_Groups','Payment_Modes')
		AND  (a.Dimension=0 OR @nCrosstabType=2)   AND (b.col_name IS NOT NULL OR c.col_name IS NOT NULL OR a.col_expr<>'xn_type')
		AND d.col_header IS NULL
	END


	IF @bCalledFromXpert=1 AND @cXpertRepCode NOT IN ('R5','R1')
		SET @cGrpTotalCols='[Transaction Type]'
	ELSE
	IF @cXpertRepCode='R1'
		SELECT TOP 1 @cGrpTotalColsFirst='['+col_header_exp+']' FROM #tmpGrpCols a
		ORDER BY col_order

	DECLARE @cColExpr VARCHAR(400),@cColHeaderExp VARCHAR(400),@cColHeader VARCHAR(400)

	UPDATE #tmpGrpCols SET col_order=-1 WHERE col_expr='xn_type'


	--if @@spid=321
	--	select 'check tmpgrpcols',@cRepType reptype, * from #tmpGrpCols

	SET @cStep='60'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpGrpCols)
	BEGIN
		SELECT top 1 @cColExpr=col_expr,@cColHeaderExp=col_header_exp,@cColHeader=col_header,
		@bCalculativeCol=calculative_col,@bGrpTotalCol=ISNULL(grp_total,0),@bDimensionCol=ISNULL(dimcol,0)
		FROM  #tmpGrpCols ORDER BY calculative_col,col_order
		
		IF @bDimensionCol=0
		BEGIN
			IF @bCalculativeCol=0
			BEGIN
				--(CASE WHEN right(@cColExpr,4)='date' OR @cColExpr='GST%' OR RIGHT(@cColHeader,4)='Date' THEN 'CONVERT(VARCHAR,' ELSE '' END)+'['+@cColHeaderExp+']'+
				--(CASE WHEN right(@cColExpr,4)='date' OR RIGHT(@cColHeader,4)='Date' THEN ',105)' WHEN @cColExpr='GST%' THEN ')' ELSE '' END)

				SELECT @cOutputCol=
				(CASE WHEN @cColExpr='GST%' THEN 'CONVERT(VARCHAR,' ELSE '' END)+'['+@cColHeaderExp+']'+
				(CASE WHEN @cColExpr='GST%' THEN ')' ELSE '' END)
			
				SELECT @cGrpMasterCol=COALESCE(@cGrpMasterCol+',','')+@cOutputCol,
						@cOutputCol= @cOutputCol+' as ['+@cColHeader+']' 
			END	
			ELSE
				SET @cOutputCol='SUM('+(CASE WHEN @cXpertRepCode='R1' THEN 'ISNULL(' ELSE '' END)+
				'['+@cColHeaderExp+']'+(CASE WHEN @cXpertRepCode='R1' THEN ',0)' ELSE '' END)+') AS ['+@cColHeader+']' 

		--(Old expression before change for column para3_name used in rollup command against Stock analysis Report)
		--@cGrpTotalCols=(CASE WHEN @bGrpTotalCol=1 THEN COALESCE(@cGrpTotalCols+',','')+
		--				   '['+@cColHeaderExp+']' ELSE @cGrpTotalCols END),		

			SET  @cRollUpTotalCols= (CASE WHEN @bGrpTotalCol=1 THEN COALESCE(@cRollUpTotalCols+',','')+
						   '['+@cColHeaderExp+']' ELSE @cRollUpTotalCols END)
			

			IF ISNULL(@nCrosstabType,0)<>2
			BEGIN

				SELECT @cFinalOutputCols=COALESCE(@cFinalOutputCols+',','') +@cOutputCol,
					   @cGrpMasterColValOrd=COALESCE(@cGrpMasterColValOrd+',','') +
					   (CASE WHEN right(@cColExpr,4)='date' THEN 'CONVERT(DATETIME,['+@cColHeader+'],103)'
							 ELSE '['+@cColHeader+']' END)
				IF @bCalculativeCol=0
					SET @cGrpMasterColVal=COALESCE(@cGrpMasterColVal+',','') +'['+@cColHeaderExp+']'
			END
			ELSE	
			IF @bCalculativeCol=0
		   		   SELECT @cGrpMasterColVal=COALESCE(@cGrpMasterColVal+',','') +@cOutputCol,
					@cGrpMasterColValOrd=COALESCE(@cGrpMasterColValOrd+',','') +
					   (CASE WHEN right(@cColExpr,4)='date' THEN 'CONVERT(DATETIME,['+@cColHeader+'],103)'
							 ELSE '['+@cColHeader+']' END)
				
			ELSE
			begin
				print 'Output col for :'+@cColHeader+' is :'+isnull(@cOutputCol,'null output')
				SElect @cCalculativeColsVal=COALESCE(@cCalculativeColsVal+',','') +@cOutputCol,
				@cPivotCalculativeCols=COALESCE(@cPivotCalculativeCols+',','') +'SUM(['+@cColHeaderExp+
				']) AS ['+@cColHeaderExp+']'
			end
		END		
		
		IF @bCalculativeCol=0
			SET @cPivotGrpMasterColsVal=COALESCE(@cPivotGrpMasterColsVal+',','') +'['+@cColHeaderExp+']'

		DELETE FROM  #tmpGrpCols WHERE col_header=@cColHeader
	END

	IF @cPaymodeCols<>''
	BEGIN
		IF ISNULL(@nCrosstabType,0)=2
			SET @cGrpMasterColVal=@cGrpMasterColVal+','+@cPaymodeCols
		ELSE
			SET @cFinalOutputCols=@cFinalOutputCols+','+@cPaymodeCols
	END

	SET @bGrpColChecked=0
lblRecheck:
	SET @cStep='70'
	SELECT TOP 1 @cMainGrpMasterCol='['+a.col_header+'] IS NULL' 
	FROM #rep_det a
	LEFT JOIN transaction_analysis_calculative_COLS b on b.col_name=a.key_col and b.xn_type IN (@cXnType,'COMMON') and b.rep_type=@cRepType
	LEFT JOIN transaction_analysis_master_COLS c on c.col_name=a.key_col and c.xn_type IN (@cXnType,'COMMON') and c.rep_type=@cRepType
	WHERE REP_ID=@cRepId AND Calculative_col=0 AND  Dimension=0  AND grp_total=0 AND 
	COALESCE(b.col_header,c.col_header,a.col_header) not like '%TRANSACTION TYPE%'

	IF @cMainGrpMasterCol IS NULL AND @bGrpColChecked=0
	BEGIN
		UPDATE #rep_det SET grp_total=0 WHERE grp_total=1
		SELECT @bGrpColChecked=1,@bGrpTotalCol=0

		GOTO lblRecheck
	END	

	IF EXISTS (SELECT TOP 1 * FROM #rep_det WHERE key_col IN  ('OH_NAME'))	
		SET @cMainGrpMasterCol=@cMainGrpMasterCol+' AND [oh name] IS NULL'

	SET @cStep='90'
	

	SELECT TOP 1 @cDimCol=col_expr from #rep_det (nolock)  WHERE REP_ID=@cRepId and Dimension=1
	SELECT TOP 1 @cMeasureCol=col_expr from #rep_det (nolock)  WHERE REP_ID=@cRepId and Mesurement_col =1

	--if @@spid=68	
	--	select @cMainGrpMasterCol,@cGrpMasterColVal,@cCalculativeColsVal,@cGrpMasterCol,@cFinalOutputCols finaloutput

	SELECT @cRetPivotExpr='',@cRetUnPivotExpr=''

	IF ISNULL(@cMeasureCol,'')<>'' AND ISNULL(@cDimCol,'')<>'' AND @nCrosstabType>=1
	BEGIN
--		SELECT 'ENTER CROSS TAB REPORTING ',@nCrosstabType

		IF @nCrosstabType=1
		BEGIN
			PRINT 'Start processing Cross tab across'
			SET @cStep='100'
			EXEC CROSSTABSTR_XPERTREPORTING
			@cTempDb=@cTempDb,
			@CTABLENAME=@CTEMPTABLE,
			@cRepid=@cRepid,
			@cRepType=@cRepType,
			@bCalledFromXpert=@bCalledFromXpert,
			@CRETCOLSTR=@CRETCOLSTR OUTPUT,
			@cErrormsg=@cErrormsg OUTPUT

			--if @@spid=436
			--	select 'final output cross tab gst string', @CRETCOLSTR,@cCalculativeColsVal

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC

			SELECT @cCalculativeColsVal=COALESCE(@cCalculativeColsVal+',','') +@CRETCOLSTR,
			@cFinalOutputCols=@cFinalOutputCols+','+@CRETCOLSTR
		END
		ELSE
		BEGIN
			SET @cStep='105'
			EXEC SP3S_GETXPERTREP_CROSSTAB_PIVOTCOLS
			@cTempDb=@cTempDb,
			@CTABLENAME=@CTEMPTABLE,
			@cRepType=@cRepType,
			@cXpertRepCode=@cXpertRepCode,
			@cRetPivotExpr=@cRetPivotExpr OUTPUT,
			@cRetUnPivotExpr=@cRetUnPivotExpr OUTPUT,
			@cRetCalculativeCols=@cRetCalculativeCols OUTPUT,
			@cRetGroupingSets= @cRetGroupingSets OUTPUT,
			@cErrormsg = @cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
			
			SET @cOuterCalculativeCols=ISNULL(@cRetCalculativeCols,'')

		END
		--SET @cTempTable='##tmppivot_'+ltrim(rtrim(str(@@spid)))
	END



	DECLARE  @cInputTable VARCHAR(200)

	SET @cStep='110'
	SET @cInputTable=@cTempDb+'xpertrepdata_'+LTRIM(RTRIM(STR(@@SPID)))

	IF OBJECT_ID(@cInputTable,'U') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE  '+@cInputTable
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cRollUpTotalCols=ISNULL(@cRollUpTotalCols,'')

	IF  @cRollUpTotalCols='' AND @cXpertRepCode<>'R1'
		SET @cRollUpTotalCols='[Transaction Type]'
	
	IF @cRollUpTotalCols<>''
	  SET @cRollUpTotalCols=',ROLLUP('+@cRollUpTotalCols+')'
	ELSE
	  SET @cRollUpTotalCols=',()' ----- We have to add this in FInal Select statement to enforce return Grand totals If no Break is selected for any master columns

	--if @@spid=129
	--	select @nCrosstabType CrosstabType




	SET @cStep='115'
	IF ISNULL(@nCrosstabType,0)<>2
	BEGIN
		
		--if @@spid=321
		--	select 'check @cGrpMasterColVal',@cGrpMasterColVal,@cFinalOutputCols,@cMainGrpMasterCol,@cRollUpTotalCols,@cAddnlFilter

		IF CHARINDEX('Image',@cFinalOutputCols)>0 
			SELECT @cFinalOutputCols=@cFinalOutputCols+',img_id',@cGrpMasterColVal=@cGrpMasterColVal+',img_id'

			--ROW_NUMBER() OVER (ORDER BY (CASE WHEN '+@cMainGrpMasterCol+' THEN 1 ELSE 0 END),'+@cGrpMasterColValOrd+') org_rowno,--
		SET @cCmd=N'SELECT (CASE WHEN '+@cMainGrpMasterCol+' THEN 1 ELSE 0 END) AS total_mode,
					IDENTITY(INT,1,1) org_rowno, * INTO '+
					@cInputTable+' FROM '+
					' (
					select *
					FROM
					(SELECT '+@cFinalOutputCols+'
					FROM '+@cTempDb+'['+@cTempTable+'] '+
					' GROUP BY '+@cGrpMasterColVal+'
					) a 
					) b '+(CASE WHEN @cAddnlFilter<>'' THEN ' WHERE '+@cAddnlFilter ELSE '' END)
					
					--' GROUP BY GROUPING SETS(('+@cGrpMasterColVal+')'+@cRollUpTotalCols+')
	END
	ELSE
	BEGIN
		
		IF ISNULL(@cOuterCalculativeCols,'')<>''
			SET @cOuterCalculativeCols=','+@cOuterCalculativeCols

		--ROW_NUMBER() OVER (ORDER BY '+@cGrpMasterColValOrd+') org_rowno,		
		SET @cGrpMasterColVal=@cGrpMasterColVal+(CASE WHEN CHARINDEX('Image',@cGrpMasterColVal)>0 
		THEN ',CONVERT(VARCHAR(100),'''') AS Image_id' ELSE '' END)
		SET @cCmd=N'SELECT (CASE WHEN '+@cMainGrpMasterCol+' THEN 1 ELSE 0 END) AS total_mode,
			IDENTITY(INT,1,1) org_rowno,*  INTO '+
					@cInputTable+' FROM '+
					'( SELECT '+@cGrpMasterColVal+',xtab_col_name'+@cOuterCalculativeCols+' FROM
					(
					SELECT * FROM
					(
					SELECT * FROM 
					(SELECT '+@cPivotGrpMasterColsVal+','+@cPivotCalculativeCols+'
					FROM '+@cTempDb+'['+@cTempTable+'] '+
					' GROUP BY '+@cPivotGrpMasterColsVal+') a '+@cRetUnPivotExpr+@cRetPivotExpr+'
					) d
					GROUP BY GROUPING SETS(('+@cRetGroupingSets+',xtab_col_name)'+@cRollUpTotalCols+')
					) e '+
					(CASE WHEN @cAddnlFilter<>'' THEN ' WHERE '+@cAddnlFilter ELSE '' END)
					

		--if @@spid=81
		--	SELECT  'check all output of Xtab Report cols',len(@cCmd), @cOuterCalculativeCols cOuterCalculativeCols,
		--	@cCalculativeColsVal cCalculativeColsVal,@cPivotGrpMasterColsVal cPivotGrpMasterColsVal,
		--	@cGrpMasterColVal cGrpMasterColVal,@cMainGrpMasterCol,@cGrpTotalCols cGrpTotalCols,@cRetUnPivotExpr cRetUnPivotExpr,
			--@cRetPivotExpr cRetPivotExpr,@cCmd
	END


	PRINT isnull(@cCmd,'null final report')
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='117'
	EXEC SP3S_XPERT_UPDATE_DERIVEDCOLS
	@cRepType=@cRepType,
	@cInputTable=@cInputTable,
	@cErrormsg=@cErrormsg OUTPUT

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	SET @cStep='118.5'

	IF EXISTS (SELECT TOP 1 * FROM #rep_mst WHERE ISNULL(show_data_pos_salenotfound,0)=1)
	BEGIN
		EXEC SP3S_XPERT_INSERT_MISSINGLOCSDATA
		@cRepType=@cRepType,
		@cInputTable=@cInputTable,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END

	SET @cStep='120'
	DECLARE @bRepeatCols BIT,@bXnHistory BIT
	SELECT TOP 1 @bRepeatCols=col_repeat,@bXnHistory=ISNULL(b.xn_history,0) FROM #rep_det A
	JOIN #rep_mst b ON a.rep_id=b.rep_id WHERE col_repeat=1

	IF ISNULL(@bRepeatCols,0)=0 
	BEGIN
		---Have to do this delete extra columns inserted for handling Ageing Columns (Purchase ageing,Shelf ageing)
		IF @cXpertRepCode='R1'
			DELETE FROM #rep_det WHERE col_mst IS NULL

		SET @cStep='122'
		EXEC SP3S_XPERT_PROCESS_REPEATCOLS
		@cRepType=@cRepType,
		@cInputTable=@cInputTable,
		@cErrormsg=@cErrormsg OUTPUT
	END
	ELSE
	BEGIN	
		SET @cStep='124'
		SET @cCmd=N'SELECT * FROM '+@cInputTable
		PRINT @cCmd 
		EXEC SP_EXECUTESQL @cCmd
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_XTREME_REPORTTOTALS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	print 'last step of SP3S_XTREME_REPORTTOTALS :'+@cStep
END