CREATE PROCEDURE SPWOW_XTREME_REPORTTOTALS_RAWDATA
@cTempDb VARCHAR(200),
@cRepTempTable VARCHAR(200),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cMasterCol VARCHAR(2000),@cGrpMasterCol VARCHAR(2000),@cFinalGrpMasterCol VARCHAR(2000),@cCalculativeColsVal VARCHAR(MAX),
	@bLoop BIT,@cColOrder VARCHAR(2000),@nMasterColCnt NUMERIC(1,0),@cOuterCalculativeCols VARCHAR(MAX),@bGrpColChecked BIT,@cOrderbyColumnId VARCHAR(20),
	@cOrgMasterCol VARCHAR(2000),@cGrpMasterColVal VARCHAR(MAX),@cGrpMasterColTotal VARCHAR(MAX),@cRetOutputCols NVARCHAR(MAX),
	@cMainGrpMasterCol VARCHAR(MAX),@cRepeatCols VARCHAR(max),@bCalculativeCol BIT,@cXpertRepCode VARCHAR(10),@bOrderColumn BIT,@bOrderbyColumnIdFound BIT,
	@cDimCol VARCHAR(200),@cMeasureCol VARCHAR(200),@cFinalOutputCols VARCHAR(MAX),@cBaseOutputCols VARCHAR(MAX),@cColHeaderExp VARCHAR(200),
	@cOutputCol VARCHAR(300),@cOutputColForDerived VARCHAR(300),@cGstCol VARCHAR(100),@cGrpMasterColValOrd VARCHAR(MAX),@bGrpTotalCol BIT,@cXtabColsList NVARCHAR(MAX),
	@CRETCOLSTR NVARCHAR(MAX),@cXntype VARCHAR(100),@nGrpCols NUMERIC(5,0),@cStep VARCHAR(5),@cRetGroupingSets VARCHAR(MAX),
	@cRetPivotExpr VARCHAR(MAX),@cRetUnPivotExpr VARCHAR(MAX),@nCrosstabType NUMERIC(1,0),@cRetCalculativeCols VARCHAR(MAX),
	@cPivotGrpMasterColsVal VARCHAR(MAX),@bDimensionCol bit,@cRollUpTotalCols VARCHAR(MAX),@bSHowImage BIT,@nCOuntMstCols INT,@cPeriodTotalsExpr VARCHAR(MAX),
	@cRetOuterCalculativeCols VARCHAR(MAX),@cRetInnerCalculativeCols VARCHAR(MAX),@bMeasureCol BIT,@nColWidth INT,@cOrderByColumns VARCHAR(1000),
	@cGrpExpr VARCHAR(MAX),@cHavingClause VARCHAR(max),@cHavingClauseWoAddnl VARCHAR(MAX),@cHavingClauseAddnl VARCHAR(MAX),@cTotalModeExpr VARCHAR(MAX),
	@cAddnlFilterCriteria VARCHAR(1000),@nGrpColsCount INT,@nGrpColsTotal NUMERIC(2,0),@cRetCol VARCHAR(200),@cFilterTotalRowsExpr VARCHAR(1000),
	@cOrderByMasterCols VARCHAR(2000),@cVersion VARCHAR(500)
			

BEGIN TRY

	SET @cStep='10'
	SET @cErrormsg=''			
	SELECT @cVersion=@@version
	SET @cXntype=''
		

	SELECT @nCrosstabType=CrossTab_Type,@cXpertRepCode=xpert_rep_code
	from  #wow_xpert_rep_mst 
	
	IF @cXpertRepCode<>'R6'
		SET @nCrosstabType=0

	SELECT @nGrpCols=count(*) FROM #wow_xpert_rep_det a 	WHERE Calculative_col=0 AND  Dimension=0 
	
	IF @nGrpCols=1
	   UPDATE #wow_xpert_rep_Det set grp_total=0

	SELECT a.col_expr,a.col_header,a.col_order,0  calculative_col,GRP_TOTAL,a.dimension dimcol,a.measurement_col,col_width,
	a.column_id,a.column_id order_by_column_id,a.order_column,convert(varchar(20),'') col_data_type
	INTO #tmpGrpCols 	FROM #wow_xpert_rep_det a
	WHERE 1=2

	SELECT TOP 1  @cXntype=XN_TYPE FROM #wow_xpert_rep_det

	
	IF @cXpertRepCode='R1'
		EXEC SPWOW_XPERT_VERIFY_STOCKNACOL_STKANALYSIS @cRepTempTable
		


	SET @cStep='12'
	INSERT INTO #tmpGrpCols (column_id,order_column, col_expr,col_header,col_Order,calculative_col,grp_total,dimcol,measurement_col,col_width,order_by_column_id,col_data_type)
	SELECT DISTINCT a.column_id,a.order_column, a.col_expr,a.col_header,a.col_order,
	a.calculative_col,GRP_TOTAL,a.dimension,a.measurement_col,a.col_width,ISNULL(b.order_by_column_id,''),b.col_data_type
	FROM #wow_xpert_rep_det a
	JOIN wow_xpert_report_cols_expressions b ON a.column_id=b.column_id
	JOIN wow_xpert_report_cols_xntypewise c ON a.column_id=c.column_id AND c.xn_type=a.xn_type

	SET @cStep='15'
	UPDATE a SET col_order=b.col_order-1 FROM #tmpGrpCols a 
	JOIN #tmpGrpCols b ON a.column_id=b.order_by_column_id

	DECLARE @cColExpr VARCHAR(400),@cColHeader VARCHAR(400),@cColDatatype VARCHAR(20)

	UPDATE #tmpGrpCols SET col_order=-1 WHERE col_expr='xn_type'

	--if @@spid=854
	--	select 'check tmpGrpCols',* from #tmpGrpCols
	
	SET @cHavingClause=''

	SELECT @nCOuntMstCols=count(distinct col_header) from #tmpGrpCols WHERE order_column=0


	DECLARE @bDerivedColFound BIT,@bDerivedColCalculated BIT

	SET @bDerivedColCalculated=0
	--- No need to make use of Having clause in Final statement If no derived column is present in the Report layout
	set @cStep='20'
	IF EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
			   JOIN wow_xpert_report_cols_xntypewise b ON a.xn_type=b.xn_type AND a.column_id=b.column_id
			   JOIN wow_xpert_report_cols_xntypewise c ON c.ref_column_id=b.column_id)
		OR EXISTS (SELECT TOP 1 a.column_id FROM #wow_xpert_rep_det a 
				JOIN wow_xpert_derivedcols_link b ON b.ref_column_id=a.column_id AND b.xn_type=a.xn_type)
		SELECT @bDerivedColFound=1
	ELSE
		SELECT @bDerivedColFound=0

	SELECT @cAddnlFilterCriteria=addnlFiltercriteria FROM #wow_xpert_rep_mst 
	
	SET @cAddnlFilterCriteria=ISNULL(@cAddnlFilterCriteria,'')
	--if @@spid=154
	--	SELECT 'check #tmpGrpCols',* FROM #tmpGrpCols

	

	SELECT @nGrpColsTotal=count(col_expr) from #tmpGrpCols where isnull(grp_total,0)=1

	SET @nGrpColsCount=0
	
	DECLARE @bFirstMasterCol BIT

	SET @bFirstMasterCol=1


	declare @cColumnId VARCHAR(10)
	SET @cStep='60'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpGrpCols)
	BEGIN
		SELECT top 1 @cColExpr=col_expr,@cColHeaderExp=col_header,@cColHeader=col_header,@cColDatatype=col_data_type,
		@bCalculativeCol=calculative_col,@bGrpTotalCol=ISNULL(grp_total,0),@bDimensionCol=ISNULL(dimcol,0),
		@bMeasureCol=ISNULL(measurement_col,0),@nColWidth=ISNULL(col_width,0),@bOrderColumn=ISNULL(order_column,0),
		@cOrderbyColumnId=ISNULL(ORDER_BY_COLUMN_ID,''),@cColumnId=column_id
		FROM  #tmpGrpCols ORDER BY calculative_col,col_order
		
		IF @bCalculativeCol=0
		BEGIN
			
			SET @nGrpColsCount=@nGrpColsCount+1

			SELECT @cOutputCol='['+@cColHeaderExp+']'
				
			IF @bDerivedColFound=1 OR @cAddnlFilterCriteria<>''
				SET @cOutputColForDerived = '['+@cColHeaderExp+']'

			SELECT @cFinalGrpMasterCol=COALESCE(@cFinalGrpMasterCol+',','')+'['+@cColHeaderExp+']'

			IF @cOrderbyColumnId='' AND (@bDimensionCol=0 OR @cXpertRepCode<>'R6' OR @cColumnId IN ('C0217','C0224','C1077','C1335','C1345'))
				SET @cOrderByMasterCols=COALESCE(@cOrderByMasterCols+',','')+'['+@cColHeaderExp+']'	

			SELECT @cGrpMasterCol=COALESCE(@cGrpMasterCol+',','')+'['+@cColHeaderExp+']',
					@cOutputCol= @cOutputCol+' as ['+@cColHeader+']' ,
					@cOutputColForDerived =@cOutputColForDerived+' as ['+@cColHeader+']'
					
		END	
		ELSE
		BEGIN
			if left(@cColExpr,4)='AVG('
				SELECT @cOutputCol='ISNULL(['+@cColHeaderExp+'],0) AS ['+@cColHeader+']',@cGrpMasterCol=COALESCE(@cGrpMasterCol+',','')+'['+@cColHeaderExp+']',
				@cFinalGrpMasterCol=COALESCE(@cFinalGrpMasterCol+',','')+'['+@cColHeaderExp+']'
			else
				SET @cOutputCol='SUM(ISNULL(['+@cColHeaderExp+'],0)) AS ['+@cColHeader+']' 

			SET @cOutputColForDerived = @cOutputCol

			SET @cHavingClause = @cHavingClause+(CASE WHEN @cHavingClause<>'' THEN ' AND ' ELSE '' END)+
			'SUM(ISNULL(['+@cColHeaderExp+'],0))=0'
		END
		
			
			IF @bDimensionCol=0 OR  @cXpertRepCode<>'R6' OR @cColumnId IN ('C0217','C0224','C1077','C1335','C1345')
				SELECT @cFinalOutputCols=COALESCE(@cFinalOutputCols+',','') +@cOutputCol
											
			--- Changed the below code because of Numeric columns also coming as String and resulting in left alignment
			--- as per reported by Anil (Date :28-02-2023) I removed the null handling as Windows application grid handles to show null as blank
			--IF NOT ((@bMeasureCol=1 AND @nCrosstabType=1) OR (@bCalculativeCol=1 AND @nCrosstabType=2) OR @nColWidth=0)
			--	SET @cRetOutputCols=COALESCE(@cRetOutputCols+',','') +'ISNULL(CONVERT(VARCHAR,['+@cColHeader+']),'''') as ['+@cColHeader+']'

			SET @cRetCol= '['+@cColHeader+']'

			
			IF @bCalculativeCol=0 
			BEGIN
				IF @bGrpTotalCol=0 AND @bOrderColumn=0
					SET @cFilterTotalRowsExpr = COALESCE(@cFilterTotalRowsExpr+' AND ','')+@cRetCol+ ' IS NULL'

				IF @cColDataType='NUMERIC'
					SET @cRetCol= 'ISNULL(CONVERT(VARCHAR(100),['+@cColHeader+']),'''')' 
				ELSE
				IF @cColDataType='Date'
					SET @cRetCol=(CASE WHEN @cVersion NOT LIKE '%2008%' THEN 'FORMAT(' ELSE 'CONVERT(VARCHAR,' END) +'['+@cColHeaderExp+']'+
								(CASE WHEN @cVersion NOT LIKE '%2008%' THEN ',''dd-MMM-yyy''' ELSE ',106' END) +')'
				ELSE
					SET @cRetCol= 'ISNULL(['+@cColHeader+'],'''')'


			END

			SET @bFirstMasterCol=0
			--SET @cRetCol='['+@cColHeader+']' 

			IF NOT ((@bMeasureCol=1 AND @nCrosstabType=1) OR (@bCalculativeCol=1 AND @nCrosstabType=2) OR @nColWidth=0
			   OR (@cXpertRepCode='R6' AND @cColumnId NOT IN ('C0217','C0224','C1077','C1335','C1345') 
			    AND (@bMeasureCol=1 or @bDimensionCol=1))) OR @cXpertRepCode<>'R6'
				SET @cRetOutputCols=COALESCE(@cRetOutputCols+',','') + @cRetCol+' AS ['+@cColHeader+']'

			IF @bCalculativeCol=0 
				SET @cGrpMasterColVal=COALESCE(@cGrpMasterColVal+',','') +'['+@cColHeaderExp+']'

		
		IF @bCalculativeCol=0
			SET @cPivotGrpMasterColsVal=COALESCE(@cPivotGrpMasterColsVal+',','') +'['+@cColHeaderExp+']'

		SELECT @cBaseOutputCols=COALESCE(@cBaseOutputCols+',','') +@cOutputColForDerived


		DELETE FROM  #tmpGrpCols WHERE col_header=@cColHeader
	END

	

	SELECT @cHavingClauseWoAddnl='HAVING NOT('+@cHavingClause+')'



	--if @@spid=412
	--	select @cHavingClause cHavingClause

	IF ISNULL(@cAddnlFilterCriteria,'')<>''
		SET @cHavingClauseAddnl = @cHavingClauseWoAddnl+(CASE WHEN  @cHavingClause='' THEN ' HAVING ' ELSE ' AND '  END)+'('+@cAddnlFilterCriteria+')'
	ELSE
		SET @cHavingClauseAddnl = @cHavingClauseWoAddnl

	SET @bGrpColChecked=0

lblRecheck:
	SET @cStep='70'
	SELECT TOP 1 @cMainGrpMasterCol='['+a.col_header+'] IS NULL' 
	FROM #wow_xpert_rep_det a WHERE Calculative_col=0 AND  Dimension=0  AND grp_total=0 AND a.column_id<>'xn_type'

	IF @cMainGrpMasterCol IS NULL AND @bGrpColChecked=0
	BEGIN
		UPDATE #wow_xpert_rep_det SET grp_total=0 WHERE grp_total=1
		SELECT @bGrpColChecked=1,@bGrpTotalCol=0

		GOTO lblRecheck
	END	

	SET @cStep='90'
	
		
	SELECT @cDimCol=COALESCE(@cDimCol+',','')+col_expr from #wow_xpert_rep_det (nolock)  WHERE  Dimension=1
	SELECT TOP 1 @cMeasureCol=col_expr from #wow_xpert_rep_det (nolock)  WHERE measurement_col =1

	SELECT @cRetPivotExpr='',@cRetUnPivotExpr=''


	--if @@spid=293
	--begin
	--	set @cCmd=N'SELECT ''check b4 final report'',  * FROM '+@cRepTempTable
	--	exec sp_executesql @cCmd
	--end

	--if @@spid=134
	--	select 'before applying crosstable columns',@cXpertRepCode XpertRepCode, @cMeasureCol cMeasureCol,@cDimCol cDimCol,@nCrosstabType CrosstabType,@cFinalOutputCols FinalOutputCols
	--	from #wow_xpert_rep_mst

	IF ISNULL(@cMeasureCol,'')<>'' AND ISNULL(@cDimCol,'')<>'' AND @cXpertRepCode='R6' AND @nCrosstabType>=1 --Process Non Eoss columns for Cross tab
	BEGIN
		
		PRINT 'Start processing Cross tab for Eoss and Sales Reporting only'
		SET @cStep='100'
		EXEC SPWOW_CROSSTABSTR_XPERTREPORTINg
		@cXpertRepCode=@cXpertRepCode,
		@cRepTempTable=@cRepTempTable,
		@CRETCOLSTR=@CRETCOLSTR OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
			
		SELECT @cCalculativeColsVal=COALESCE(@cCalculativeColsVal+',','') +@CRETCOLSTR,
		@cFinalOutputCols=@cFinalOutputCols+','+@CRETCOLSTR,
		@cPeriodTotalsExpr=@cPeriodTotalsExpr+','+@CRETCOLSTR
				

		SET @cStep='107'
		SELECT @cXtabColsList=xtab_cols_list FROM #wow_xpert_rep_mst 

		SET @cRetOutputCols=@cRetOutputCols+','+@cXtabColsList
	END

	
	
	DECLARE  @cInputTable VARCHAR(200)

	SET @cStep='110'
	SET @cInputTable= 'tempdb.dbo.##xpertrepdata_'+LTRIM(RTRIM(STR(@@SPID)))

	IF OBJECT_ID(@cInputTable,'U') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE  '+@cInputTable
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cRollUpTotalCols=ISNULL(@cFinalGrpMasterCol,'')

	IF  @cXpertRepCode NOT IN ('R1','R6')
		SET @cRollUpTotalCols='[Transaction Type],'+@cRollUpTotalCols
	
	DECLARE @bComparisonPeriodFound BIT

	SET @bComparisonPeriodFound=0
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_mst WHERE ISNULL(compare_period_from_dt,'')<>'')
	BEGIN
		SELECT @cFinalOutputCols=@cFinalOutputCols+',[Period Base]',
			   @cRollUpTotalCols=@cRollUpTotalCols+',[Period Base]',
			   @cBaseOutputCols=@cBaseOutputCols+',[Period Base]',
			   @cGrpMasterColVal=@cGrpMasterColVal+',[Period Base]',
			   @cGrpMasterCol=@cGrpMasterCol+',[Period Base]',
			   @cRetOutputCols=@cRetOutputCols+',[Period base]'
			   
	--@cFinalGrpMasterCol=@cFinalGrpMasterCol+',[Period Base]'

		--DECLARE @lastCommaIndex INT 
		--SET @lastCommaIndex= LEN(@cRollUpTotalCols) - CHARINDEX(',', REVERSE(@cRollUpTotalCols)) + 1;

		--SET  @cRollUpTotalCols=STUFF(@cRollUpTotalCols, @lastCommaIndex, 1, ',' + '[Period Base],')

		SET @bComparisonPeriodFound=1
	END
	--select 'check @cRetOutputCols before',@cRetOutputCols
	IF @cXpertRepCode NOT IN('R1','R6')
		SELECT @cFinalOutputCols='[Transaction type],'+@cFinalOutputCols,
			  @cBaseOutputCols='[Transaction type],'+@cBaseOutputCols,
				@cRetOutputCols='ISNULL([Transaction type],'''') [Transaction type],'+@cRetOutputCols,
			   @cGrpMasterColVal='[Transaction type],'+@cGrpMasterColVal,
			   @cGrpMasterCol='[Transaction type],'+@cGrpMasterCol,
			   @cFinalGrpMasterCol='[Transaction type],'+@cFinalGrpMasterCol

	

	--select 'check @cRetOutputCols after',@cRetOutputCols

    --SET @cRollUpTotalCols=' ROLLUP('+@cRollUpTotalCols+')'
	
	SET @cGrpExpr=@cRollUpTotalCols
	

	
	--if @@spid=178
	--	select @nCrosstabType CrosstabType


	SELECT @bSHowImage=isnull(show_image,0) from #wow_xpert_rep_mst
	IF @bSHowImage=1
		SELECT @cFinalOutputCols='max(img_id) img_id,'+@cFinalOutputCols,
				@cBaseOutputCols='max(img_id) img_id,'+@cBaseOutputCols,
				@cRetInnerCalculativeCols='max(img_id) img_id,'+@cRetInnerCalculativeCols,
				@cFinalGrpMasterCol='max(img_id) img_id,'+@cFinalGrpMasterCol
	
	DECLARE @cGenOutputCols VARCHAR(MAX),@cRowNoCol VARCHAR(2000),@bFinalStatement BIT

lblGenOutput:
	
	SET @bFinalStatement=0
	IF (@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=1
	BEGIN
		SET @cRepTempTable=@cInputTable

		SET @cInputTable= 'tempdb.dbo.##xpertrepdata_'+LTRIM(RTRIM(STR(@@SPID)))+'_derived'

		IF OBJECT_ID(@cInputTable,'U') IS NOT NULL
		BEGIN
			SET @cCmd=N'DROP TABLE  '+@cInputTable
			EXEC SP_EXECUTESQL @cCmd
		END

	END

	--if @@spid=350
	--	select @bDerivedColFound,@cAddnlFilterCriteria,@cFinalOutputCols,@cBaseOutputCols,@cDimCol
	--	--,* from #wow_xpert_rep_det (nolock)  WHERE  Dimension=1	

	--if @@spid=52 and @nCrosstabType=2
	--	select 'check derived col status', @bDerivedColCalculated bDerivedColCalculated,@bDerivedColFound bDerivedColFound,@cAddnlFilterCriteria cAddnlFilterCriteria

	SET @cStep='115'
		--if @@spid=92
		--	select 'check cFinalOutputCols',@cDimCol dimcolname, @nCOuntMstCols nCOuntMstCols,@cFinalOutputCols,@cHavingClause

		--- Need to take random image of an Item e.g. If Base for Image defining is Article+Color and User takes
		--- only Article no. in the Report , the report gives multiple records against one article because of 
		--- having multiple images for different colors..That's applying max on this column gives a random image
		--- This is done after discussion of Kamalpreet/Pankaj with Sir as per Ticket #03-1063 for client JDS Design (Date:20-03-2023)
		
		
		IF (@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0
			SELECT @cGenOutputCols=@cBaseOutputCols+(CASE WHEN @cDimCol<>'' AND @cDimCol like 'ageing%' AND @nCrosstabType<>2 THEN ','+@cDimCol ELSE '' END),@cRowNoCol='',@bFinalStatement=0
		ELSE
			SELECT @cGenOutputCols=@cFinalOutputCols,@cRowNoCol='ROW_NUMBER() OVER (ORDER BY '+@cOrderByMasterCols+')  org_rowno,',@bFinalStatement=1

		IF  (NOT ((@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0) 
			OR (@bDerivedColFound=0 AND @cAddnlFilterCriteria=''))  and @cXpertRepCode<>'R6' 
			SELECT @cTotalModeExpr=
			'(CASE WHEN GROUPING_ID('+replace(@cFinalGrpMasterCol,'max(img_id) img_id,','')+')>0 THEN 1 ELSE 0 END)',@cHavingClause=@cHavingClauseWoAddnl
		ELSE
			SELECT @cGrpExpr=@cGrpMasterCol+(CASE WHEN @cDimCol<>''  AND @cDimCol like 'ageing%' AND (@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') 
			THEN ','+@cDimCol+' ' ELSE '' END),@cTotalModeExpr='0',@cHavingClause=@cHavingClauseWoAddnl
		
		if @cXpertRepCode='R6' and exists (select top 1 a.column_id from wow_xpert_report_cols_xntypewise a
			JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id where a.xn_type='eoss' and a.proc_name like '%stock%')
		BEGIN	
			SELECT @cGenOutputCols=@cGenOutputCols+','+replace(col_expr,'sku_names.',''),@cGrpExpr=@cGrpExpr+','+replace(col_expr,'sku_names.','')
			from wow_xpert_report_cols_expressions (NOLOCK)
			WHERE ISNULL(invmasterpara,0)=1
		END
		
			--if @@spid=148 AND @bDerivedColCalculated=1
			--	select @cPeriodTotalsExpr cPeriodTotalsExpr
		SET @cCmd=N'SELECT '+@cRowNoCol+'* INTO '+@cInputTable+' FROM '+
					' (
					select *
					FROM
					(SELECT '+@cGenOutputCols+' FROM '+@cRepTempTable+' GROUP BY '+@cGrpExpr +
					' ) a 
					) b
					'


		--if @@spid=116
		--	select @cCmd cmd, @cGrpExpr,@nCOuntMstCols,@cGenOutputCols,@cFinalOutputCols cFinalOutputCols,@nCrosstabType CrosstabType,@cDimCol cDimCol,@cFinalGrpMasterCol FinalGrpMasterCol,
		--	@cTotalModeExpr		TotalModeExpr,@bDerivedColCalculated,@cRollUpTotalCols,@cHavingClauseAddnl,@cHavingClauseWoAddnl,@cHavingClause
		
		print @cCmd
		EXEC SP_EXECUTESQL @cCmd
	
	--if @@spid=91
	--	select @cCmd

	PRINT isnull(@cCmd,'null final report')
	

	
	--if @@spid=802
	--	select @bDerivedColFound bDerivedColFound

	IF (@bDerivedColFound=1  OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0
	BEGIN
		IF @bDerivedColFound=1
		BEGIN
			SET @cStep='112.5'
			EXEC SPWOW_XPERT_PROCESS_DERIVED_COLS
			@nMode=2,
			@cRepTempTable=@cInputTable,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
		END

		IF @cAddnlFilterCriteria<>''
		BEGIN
			SET @cCmd=N'DELETE FROM '+@cInputTable+' WHERE NOT('+@cAddnlFilterCriteria+')'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END
	
		SET @bDerivedColCalculated=1
		GOTO lblGenOutput
	END


	SET @cStep='118.5'

	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_mst WHERE ISNULL(show_data_pos_salenotfound,0)=1)
	BEGIN
		EXEC SPWOW_XPERT_INSERT_MISSINGLOCSDATA
		@cInputTable=@cInputTable,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END

	SET @cStep='120'
	DECLARE @bRepeatCols BIT,@bXnHistory BIT
	SELECT TOP 1 @bRepeatCols=col_repeat,@bXnHistory=ISNULL(b.xn_history,0) FROM #wow_xpert_rep_det A
	JOIN #wow_xpert_rep_mst b ON a.rep_id=b.rep_id WHERE col_repeat=1

	if @cXpertRepCode='R6' and exists (select top 1 a.column_id from wow_xpert_report_cols_xntypewise a
		JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id where a.xn_type='eoss' and a.proc_name like '%stock%')
	BEGIN	
		SELECT @cRetOutputCols=@cRetOutputCols+','+replace(col_expr,'sku_names.','')
		from wow_xpert_report_cols_expressions (NOLOCK)	WHERE ISNULL(invmasterpara,0)=1
	END

	DECLARE @cSaleAgecolHeader varchar(200),@cSaleAgeJoin VARCHAR(400),@cShelfAgecolHeader varchar(200),@cShelfAgeJoin VARCHAR(400), @cPurAgeColHeader VARCHAR(200),@cPurAgeJoin VARCHAR(400)
	SELECT @cShelfAgeJoin='',@cPurAgeJoin='',@cSaleAgeJoin=''
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det where column_id in ('ageing_1','ageing_3'))
	BEGIN
		
		SELECT TOP 1 @cShelfAgecolHeader=col_header FROM #wow_xpert_rep_det where column_id='ageing_3' AND dimension=1
		SET @cShelfAgecolHeader=ISNULL(@cShelfAgecolHeader,'')
		IF @cShelfAgecolHeader<>''
			SELECT @cRetOutputCols=@cRetOutputCols+',ISNULL(shelfAgeslabs.srno,-1) shelfAgeingOrder',
			@cShelfAgeJoin=' LEFT JOIN #tmpAgeSlabs shelfAgeslabs ON shelfageslabs.slabname=a.['+@cShelfAgecolHeader+']'

		SELECT TOP 1 @cPurAgeColHeader=col_header FROM #wow_xpert_rep_det where column_id='ageing_1' AND dimension=1
		SET @cPurAgeColHeader=ISNULL(@cPurAgeColHeader,'')
		IF @cPurAgeColHeader<>''
			SELECT @cRetOutputCols=@cRetOutputCols+',ISNULL(purAgeslabs.srno,-1) purAgeingOrder',
			@cShelfAgeJoin=' LEFT JOIN #tmpAgeSlabs purAgeslabs ON purAgeslabs.slabname=a.['+@cPurAgeColHeader+']'

		SELECT TOP 1 @cSaleAgeColHeader=col_header FROM #wow_xpert_rep_det where column_id='ageing_2' AND dimension=1
		SET @cSaleAgeColHeader=ISNULL(@cSaleAgeColHeader,'')
		IF @cSaleAgeColHeader<>''
			SELECT @cRetOutputCols=@cRetOutputCols+',ISNULL(saleAgeslabs.srno,-1) purAgeingOrder',
			@cSaleAgeJoin=' LEFT JOIN #tmpAgeSlabs saleAgeslabs ON saleAgeslabs.slabname=a.['+@cSaleAgeColHeader+']'
	END

	SET @cStep='124'
	SET @cCmd=N'SELECT '+(CASE WHEN @bSHowImage=1 THEN 'IMG_ID,' else '' END)+'org_rowno,'+@cRetOutputCols+
	' FROM '+@cInputTable+' a '+@cPurAgeJoin+@cShelfAgeJoin+@cSaleAgeJoin+'  ORDER BY org_rowno'
	PRINT @cCmd 
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='126'
	SET @cCmd=N'DROP TABLE '+@cInputTable
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='128'
	SET @cCmd=N'DROP TABLE '+@cRepTemptable
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd


	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_XTREME_REPORTTOTALS_RAWDATA at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	print 'last step of SPWOW_XTREME_REPORTTOTALS_RAWDATA :'+@cStep
END