CREATE PROCEDURE SPWOW_XTREME_REPORTTOTALS
@cTempDb VARCHAR(200),
@cRepTempTable VARCHAR(200),
@bBulkExport bit=0,
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cMasterCol VARCHAR(2000),@cOrderByMasterCols VARCHAR(2000), @cGrpMasterCol VARCHAR(2000),@cFinalGrpMasterCol VARCHAR(2000),@cCalculativeColsVal VARCHAR(MAX),
	@bLoop BIT,@cColOrder VARCHAR(2000),@nMasterColCnt NUMERIC(1,0),@cOuterCalculativeCols VARCHAR(MAX),@bGrpColChecked BIT,@cOrderbyColumnId VARCHAR(20),
	@cOrgMasterCol VARCHAR(2000),@cGrpMasterColVal VARCHAR(MAX),@cGrpMasterColTotal VARCHAR(MAX),@cRetOutputCols NVARCHAR(MAX),
	@cMainGrpMasterCol VARCHAR(MAX),@cRepeatCols VARCHAR(max),@bCalculativeCol BIT,@cXpertRepCode VARCHAR(10),@bOrderColumn BIT,@bOrderbyColumnIdFound BIT,
	@cDimCol VARCHAR(200),@cMeasureCol VARCHAR(200),@cFinalOutputCols VARCHAR(MAX),@cBaseOutputCols VARCHAR(MAX),@cColHeaderExp VARCHAR(200),
	@cOutputCol VARCHAR(300),@cOutputColForDerived VARCHAR(300),@cGstCol VARCHAR(100),@cGrpMasterColValOrd VARCHAR(MAX),@bGrpTotalCol BIT,@cXtabColsList NVARCHAR(MAX),
	@CRETCOLSTR NVARCHAR(MAX),@cXntype VARCHAR(100),@nGrpCols NUMERIC(5,0),@cStep VARCHAR(5),@cRetGroupingSets VARCHAR(MAX),@cOrderColHeader VARCHAR(100),
	@cRetPivotExpr VARCHAR(MAX),@cRetUnPivotExpr VARCHAR(MAX),@nCrosstabType NUMERIC(1,0),@cRetCalculativeCols VARCHAR(MAX),
	@cPivotGrpMasterColsVal VARCHAR(MAX),@bDimensionCol bit,@cRollUpTotalCols VARCHAR(MAX),@bSHowImage BIT,@nCOuntMstCols INT,@cPeriodTotalsExpr VARCHAR(MAX),
	@cRetOuterCalculativeCols VARCHAR(MAX),@cRetInnerCalculativeCols VARCHAR(MAX),@bMeasureCol BIT,@nColWidth INT,@cOrderByColumns VARCHAR(1000),
	@cGrpExpr VARCHAR(MAX),@cHavingClause VARCHAR(max),@cHavingClauseWoAddnl VARCHAR(MAX),@cHavingClauseAddnl VARCHAR(MAX),@cTotalModeExpr VARCHAR(MAX),
	@cAddnlFilterCriteria VARCHAR(1000),@nGrpColsCount INT,@nGrpColsTotal NUMERIC(2,0),@cRetCol VARCHAR(200),@cFilterTotalRowsExpr VARCHAR(1000),
	@cRetOutputColsNames VARCHAR(MAX),@nShowRetailsalePaymentsViewMode INT,@cPaymentTableName VARCHAR(200),@bPaymentbasedSaleReport BIT

BEGIN TRY

	SET @cStep='10'
	SET @cErrormsg=''			
	
	SET @cXntype=''
		

	SELECT @nShowRetailsalePaymentsViewMode=isnull(showRetailsalePaymentsViewMode,0),@cXpertRepCode=xpert_rep_code
	FROM #wow_xpert_rep_mst

	SET @bPaymentbasedSaleReport=0
	IF @nShowRetailsalePaymentsViewMode>0 AND @cXpertRepCode='R2'
		SET @bPaymentbasedSaleReport=1

	SELECT @nCrosstabType=CrossTab_Type,@cXpertRepCode=xpert_rep_code
	from  #wow_xpert_rep_mst 
	
	SELECT @nGrpCols=count(*) FROM #wow_xpert_rep_det a 	WHERE Calculative_col=0 AND  Dimension=0 
	
	IF @nGrpCols=1
	   UPDATE #wow_xpert_rep_Det set grp_total=0

	SELECT a.col_expr,a.col_header,a.col_order,0  calculative_col	,GRP_TOTAL,a.dimension dimcol,a.measurement_col,col_width,
	a.column_id,a.column_id order_by_column_id,a.order_column,convert(varchar(20),'') col_data_type
	INTO #tmpGrpCols 	FROM #wow_xpert_rep_det a
	WHERE 1=2

	SELECT TOP 1  @cXntype=XN_TYPE FROM #wow_xpert_rep_det
		
	IF @cXpertRepCode='R1'
		EXEC SPWOW_XPERT_VERIFY_STOCKNACOL_STKANALYSIS @cRepTempTable
		

	DECLARE @bComparisonPeriodFound BIT

	SET @bComparisonPeriodFound=0
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_mst WHERE ISNULL(compare_period_from_dt,'')<>'')
		SET @bComparisonPeriodFound=1


	SET @cStep='12'
	INSERT INTO #tmpGrpCols (column_id,order_column, col_expr,col_header,col_Order,calculative_col,grp_total,dimcol,measurement_col,col_width,
	order_by_column_id,col_data_type)
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



	SET @cStep='60'
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpGrpCols)
	BEGIN
		SELECT top 1 @cColExpr=col_expr,@cColHeaderExp=col_header,@cColHeader=col_header,@cColDatatype=col_data_type,
		@bCalculativeCol=calculative_col,@bGrpTotalCol=ISNULL(grp_total,0),@bDimensionCol=ISNULL(dimcol,0),
		@bMeasureCol=ISNULL(measurement_col,0),@nColWidth=ISNULL(col_width,0),@bOrderColumn=ISNULL(order_column,0),
		@cOrderbyColumnId=ISNULL(ORDER_BY_COLUMN_ID,'')
		FROM  #tmpGrpCols ORDER BY calculative_col,col_order
		
		IF @bCalculativeCol=0
		BEGIN
			DECLARE @cVersion VARCHAR(500)
			SELECT @cVersion=@@version
			
			SET @nGrpColsCount=@nGrpColsCount+1

			SELECT @cOutputCol=
			(CASE WHEN @cColDatatype='Date' THEN 
			(CASE WHEN @cVersion NOT LIKE '%2008%' THEN 'FORMAT(' ELSE 'CONVERT(VARCHAR,' END) ELSE '' END)+'['+@cColHeaderExp+']'+
			(CASE WHEN @cColDatatype='Date' THEN 
			(CASE WHEN @cVersion NOT LIKE '%2008%' THEN ',''dd-MMM-yyy''' ELSE ',106' END) ELSE '' END)+
			(CASE WHEN @cColDatatype='Date' THEN ')' ELSE '' END)
				
			IF @bDerivedColFound=1 OR @cAddnlFilterCriteria<>''
				SET @cOutputColForDerived = '['+@cColHeaderExp+']'
			
			SET @cOrderColHeader=''
			IF @cOrderbyColumnId<>''
			BEGIN

				SELECT @cOrderColHeader=col_header FROM #wow_xpert_rep_det WHERE column_id=@cOrderbyColumnId
				SET @cOrderColHeader='['+@cOrderColHeader+'],'
			END

			IF @bDimensionCol=0  AND @bOrderColumn=0
			BEGIN
			    -- Multiple Total lines coming due to this if there is more than one size order under given group of columns. (08-01-25)
				SELECT @cFinalGrpMasterCol=COALESCE(@cFinalGrpMasterCol+',','')+@cOrderColHeader+'['+@cColHeaderExp+']',
				--SELECT @cFinalGrpMasterCol=COALESCE(@cFinalGrpMasterCol+',','')+'['+@cColHeaderExp+']',
				@cPeriodTotalsExpr=COALESCE(@cPeriodTotalsExpr+',','')+'NULL ['+@cColHeader+']'
			END

		
			
			SELECT @cGrpMasterCol=COALESCE(@cGrpMasterCol+',','')+'['+@cColHeaderExp+']',
					@cOutputCol= @cOutputCol+' as ['+@cColHeader+']' ,
					@cOutputColForDerived =@cOutputColForDerived+' as ['+@cColHeader+']'
					
		END	
		ELSE
		BEGIN
			if left(@cColExpr,4)='AVG(' -- Need to avoid further aggregation of Avg related columns as it needs to be done only in first query after which
										-- it will be used as grouping column only
				SELECT @cOutputCol='ISNULL(['+@cColHeaderExp+'],0) AS ['+@cColHeader+']',@cGrpMasterCol=COALESCE(@cGrpMasterCol+',','')+'['+@cColHeaderExp+']',
				@cFinalGrpMasterCol=COALESCE(@cFinalGrpMasterCol+',','')+'['+@cColHeaderExp+']'
			ELSE IF @bComparisonPeriodFound=0 OR @bDerivedColFound=1
				SET @cOutputCol='SUM(ISNULL(['+@cColHeaderExp+'],0)) AS ['+@cColHeader+']' 
			ELSE
				SET @cOutputCol='SUM(CASE WHEN ISNULL([PERIOD BASE],'''') IN (''PERIOD1'','''') THEN ISNULL(['+@cColHeaderExp+'],0) ELSE 0 END) AS ['+@cColHeader+']' 

			SET @cOutputColForDerived = @cOutputCol

			IF  NOT (@bMeasureCol=1 AND @nCrosstabType=1)
				SET @cPeriodTotalsExpr=COALESCE(@cPeriodTotalsExpr+',','')+@cOutputCol

			SET @cHavingClause = @cHavingClause+(CASE WHEN @cHavingClause<>'' THEN ' AND ' ELSE '' END)+
			'SUM(ISNULL(['+@cColHeaderExp+'],0))=0'
		END
		
		IF @bDimensionCol=0
		BEGIN
			
			IF  NOT (@bMeasureCol=1 AND @nCrosstabType=1) AND @bOrderColumn=0
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
					SET @cRetCol= 'ISNULL(CONVERT(VARCHAR(100),['+@cColHeader+'])+(case when total_mode=1 then '' Total'' else  '''' end),'+
					(CASE WHEN  @cXpertRepCode='R1' AND @bFirstMasterCol=1 THEN '(case when total_mode=1 then ''Grand total''  else null end)' 
					else 'null' end)+')' 
				ELSE
				IF @cColDataType='Date'
					SET @cRetCol= 'ISNULL(CONVERT(VARCHAR,['+@cColHeader+'],105)+(case when total_mode=1 then '' Total'' else  '''' end),'+
					(CASE WHEN  @cXpertRepCode='R1' AND @bFirstMasterCol=1 THEN '(case when total_mode=1 then ''Grand total''  else null end)' 
					else 'null' end)+')' 
				ELSE
					SET @cRetCol= 'ISNULL(['+@cColHeader+']+(case when total_mode=1 then '' Total'' else  '''' end),'+
					(CASE WHEN  @cXpertRepCode='R1' AND @bFirstMasterCol=1 THEN '(case when total_mode=1 then ''Grand total''  else null end)' 
					else 'null' end)+')' 


			END

			SET @bFirstMasterCol=0
			--SET @cRetCol='['+@cColHeader+']' 

			IF NOT ((@bMeasureCol=1 AND @nCrosstabType=1) OR (@bCalculativeCol=1 AND @nCrosstabType=2) OR @nColWidth=0)
			BEGIN
				SET @cRetOutputCols=COALESCE(@cRetOutputCols+',','') + @cRetCol+' AS ['+@cColHeader+']'
				IF @bBulkExport=1
					SELECT  @cRetOutputColsNames=COALESCE(@cRetOutputColsNames+',','')+(CASE WHEN @cColDataType<>'string' 
					 THEN 'CONVERT(VARCHAR,' ELSE '' END)+@cRetCol+(CASE WHEN @cColDataType='Date' THEN ',105)' WHEN @cColDataType<>'string'  then ')' else '' end)+'  AS ['+@cColHeader+']'

			END
			IF @bCalculativeCol=0 
				SET @cGrpMasterColVal=COALESCE(@cGrpMasterColVal+',','') +'['+@cColHeaderExp+']'

		
		END

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

	IF ISNULL(@cMeasureCol,'')<>'' AND ISNULL(@cDimCol,'')<>'' AND @nCrosstabType>=1
	BEGIN
		IF @nCrosstabType=1
		BEGIN
			PRINT 'Start processing Cross tab'
			SET @cStep='100'
			EXEC SPWOW_CROSSTABSTR_XPERTREPORTINg
			@cXpertRepCode=@cXpertRepCode,
			@cRepTempTable=@cRepTempTable,
			@CRETCOLSTR=@CRETCOLSTR OUTPUT,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
			--if @@spid=74
			--	SELECT 'check @CRETCOLSTR from xtab',@CRETCOLSTR

			SELECT @cCalculativeColsVal=COALESCE(@cCalculativeColsVal+',','') +@CRETCOLSTR,
			@cFinalOutputCols=@cFinalOutputCols+','+@CRETCOLSTR,
			@cPeriodTotalsExpr=@cPeriodTotalsExpr+','+@CRETCOLSTR


			if @bBulkExport=1
			BEGIN
				SELECT @cXtabColsList=xtab_cols_list FROM #wow_xpert_rep_mst 
				SET @cRetOutputColsNames=@cRetOutputColsNames+','+@cXtabColsList
			END
		END
		ELSE
		BEGIN
			SET @cStep='105'
			EXEC SPWOW_GETXPERTREP_CROSSTAB_PIVOTCOLS
			@cRepTempTable=@cRepTempTable,
			@cRetPivotExpr=@cRetPivotExpr OUTPUT,
			@cRetUnPivotExpr=@cRetUnPivotExpr OUTPUT,
			@cRetOuterCalculativeCols=@cRetOuterCalculativeCols OUTPUT,
			@cRetInnerCalculativeCols=@cRetInnerCalculativeCols OUTPUT,
			@cRetGroupingSets= @cRetGroupingSets OUTPUT,
			@cErrormsg = @cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
			

		END

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

	---Anil

	IF  @cXpertRepCode not in ('R1','R6')
		SET @cRollUpTotalCols='[Transaction Type],'+@cRollUpTotalCols
	
	IF @bPaymentbasedSaleReport=1
		SET @cRollUpTotalCols='cm_id,'+@cRollUpTotalCols

	SET @bComparisonPeriodFound=0
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_mst WHERE ISNULL(compare_period_from_dt,'')<>'')
	BEGIN
		SELECT @cFinalOutputCols=@cFinalOutputCols,
			  @cBaseOutputCols=@cBaseOutputCols+',[Period Base]',
			   @cGrpMasterColVal=@cGrpMasterColVal+',[Period Base]',
			   @cGrpMasterCol=@cGrpMasterCol+',[Period Base]'
			   
	--@cFinalGrpMasterCol=@cFinalGrpMasterCol+',[Period Base]'

		--DECLARE @lastCommaIndex INT 
		--SET @lastCommaIndex= LEN(@cRollUpTotalCols) - CHARINDEX(',', REVERSE(@cRollUpTotalCols)) + 1;

		--SET  @cRollUpTotalCols=STUFF(@cRollUpTotalCols, @lastCommaIndex, 1, ',' + '[Period Base],')

		SET @bComparisonPeriodFound=1
	END
	--select 'check @cRetOutputCols before',@cRetOutputCols
	IF @cXpertRepCode NOT IN ('R1','R6')
	BEGIN
		SELECT @cFinalOutputCols='[Transaction type],'+@cFinalOutputCols,
			  @cBaseOutputCols='[Transaction type],'+@cBaseOutputCols,
				@cRetOutputCols='ISNULL([Transaction type],'''')+(case when total_mode=1 then '' Total'' else  '''' end) [Transaction type],'+@cRetOutputCols,
			   @cGrpMasterColVal='[Transaction type],'+@cGrpMasterColVal,
			   @cGrpMasterCol='[Transaction type],'+@cGrpMasterCol,
			   @cFinalGrpMasterCol='[Transaction type],'+@cFinalGrpMasterCol

		IF @bBulkExport=1
			SELECT	@cRetOutputColsNames='[Transaction type],'+@cRetOutputColsNames

	END

	--select 'check @cRetOutputCols after',@cRetOutputCols

    SET @cRollUpTotalCols=' ROLLUP('+@cRollUpTotalCols+')'
	
	

	
	--if @@spid=178
	--	select @nCrosstabType CrosstabType


	SELECT @bSHowImage=isnull(show_image,0) from #wow_xpert_rep_mst
	IF @bSHowImage=1
		SELECT @cFinalOutputCols='max(ISNULL(img_id,'''')) img_id,'+@cFinalOutputCols,
				@cBaseOutputCols='max(ISNULL(img_id,'''')) img_id,'+@cBaseOutputCols,
				@cPeriodTotalsExpr='null img_id,'+@cPeriodTotalsExpr,
				@cRetInnerCalculativeCols='max(ISNULL(img_id,'''')) img_id,'+@cRetInnerCalculativeCols,
				@cFinalGrpMasterCol='max(ISNULL(img_id,'''')) img_id,'+@cFinalGrpMasterCol
	
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

	

	SET @cStep='115'
	IF ISNULL(@nCrosstabType,0)<>2 OR ((@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0)
	BEGIN
		
		--- Need to take random image of an Item e.g. If Base for Image defining is Article+Color and User takes
		--- only Article no. in the Report , the report gives multiple records against one article because of 
		--- having multiple images for different colors..That's applying max on this column gives a random image
		--- This is done after discussion of Kamalpreet/Pankaj with Sir as per Ticket #03-1063 for client JDS Design (Date:20-03-2023)
				
		IF (@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0
			SELECT @cGenOutputCols=@cBaseOutputCols+(CASE WHEN @cDimCol<>'' AND @cDimCol like 'ageing%' AND @nCrosstabType<>2 THEN ','+@cDimCol ELSE '' END),
			@cRowNoCol='',@bFinalStatement=0
		ELSE
			SELECT @cGenOutputCols=@cFinalOutputCols,@cRowNoCol='IDENTITY(INT,1,1) org_rowno,',@bFinalStatement=1

		IF  (NOT ((@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') AND @bDerivedColCalculated=0) 
			OR (@bDerivedColFound=0 AND @cAddnlFilterCriteria='')) 
			SELECT @cGrpExpr=@cRollUpTotalCols,@cTotalModeExpr=
			'(CASE WHEN GROUPING_ID('+replace(@cFinalGrpMasterCol,'max(ISNULL(img_id,'''')) img_id,','')+')>0 THEN 1 ELSE 0 END)',@cHavingClause=@cHavingClauseWoAddnl
		ELSE
			SELECT @cGrpExpr=@cGrpMasterCol+(CASE WHEN @cDimCol<>''  AND @cDimCol like 'ageing%' AND (@bDerivedColFound=1 OR @cAddnlFilterCriteria<>'') 
			THEN ','+@cDimCol+' ' ELSE '' END)+(CASE WHEN @bPaymentbasedSaleReport=1 THEN ',CM_ID' ELSE '' END) ,@cTotalModeExpr='0',@cHavingClause=@cHavingClauseWoAddnl
		
		IF @nShowRetailsalePaymentsViewMode>0 AND @cXpertRepCode='R2'
			select @cGenOutputCols=@cGenOutputCols+',cm_id'	

		SET @cCmd=N'SELECT '+@cRowNoCol+'* INTO '+@cInputTable+' FROM '+
					' (
					select *
					FROM
					(SELECT '+@cGenOutputCols+','+@cTotalModeExpr+' AS total_mode
					FROM '+@cRepTempTable+' GROUP BY '+@cGrpExpr +
					' ) a 
					) b
					'
	END
	ELSE
	BEGIN
		

		--IF @@spid=58
		--	SELECT 'check final output after PivotUnpivot', @cGrpMasterColVal,@cRetInnerCalculativeCols,@cRetOuterCalculativeCols,@cPivotGrpMasterColsVal

		SET @cHavingClause=@cHavingClauseWoAddnl
		SELECT @cGrpExpr=@cRetGroupingSets+',xtab_col_name',@cTotalModeExpr='0',@cGenOutputCols=@cFinalOutputCols

		SET @cCmd=N'SELECT 	IDENTITY(INT,1,1) org_rowno,'+	@cTotalModeExpr+' AS total_mode,*  INTO '+
					@cInputTable+' FROM '+
					'( SELECT '+@cFinalGrpMasterCol+',SUBSTRING(xtab_col_name,3,len(xtab_col_name)) details,'+@cRetOuterCalculativeCols+' FROM
					(
					SELECT * FROM
					(
					SELECT * FROM 
					(SELECT '+@cPivotGrpMasterColsVal+','+@cRetInnerCalculativeCols+
					' FROM '+@cRepTempTable+
					' GROUP BY '+@cPivotGrpMasterColsVal+') a '+@cRetUnPivotExpr+@cRetPivotExpr+'
					) d
					GROUP BY '+@cGrpExpr+
					' ) e '
					

	END

	--if @@spid=91
	--	select @cCmd

	PRINT isnull(@cCmd,'null final report')
	EXEC SP_EXECUTESQL @cCmd

	
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

	--- Removed this code for making repeat columns as Null as it is creating issue in ordering of columns and Total showing 
	--- (Done as per discussion with Sir on 16-11-2023 whike doing rnd for showing totals with group by Rollup)
	----select 'check @bRepeatCols',@bRepeatCols RepeatCols
	--IF ISNULL(@bRepeatCols,0)=0 
	--BEGIN

	--	SET @cStep='122'
	--	EXEC SPWOW_XPERT_PROCESS_REPEATCOLS
	--	@cXpertREpCode=@cXpertRepCode,
	--	@cInputTable=@cInputTable,
	--	@cErrormsg=@cErrormsg OUTPUT
	--END

	SET @cFilterTotalRowsExpr=ISNULL(@cFilterTotalRowsExpr,'')

	IF @cFilterTotalRowsExpr<>''
		SET @cFilterTotalRowsExpr=' where total_mode=0 OR ('+@cFilterTotalRowsExpr+') '
	
	
	IF @bBulkExport=0
	BEGIN
		SET @cStep='124.5'
		SET @cCmd=N'SELECT '+(CASE WHEN @bSHowImage=1 THEN 'IMG_ID,' else '' END)+'total_mode,org_rowno,'+@cRetOutputCols+
		' FROM '+@cInputTable+@cFilterTotalRowsExpr+'  ORDER BY org_rowno'


		IF @nShowRetailsalePaymentsViewMode>0 AND @cXpertRepCode='R2'
		BEGIN
			SET @cPaymentTableName='tempdb.dbo.##xpertrepdata_payments_'+LTRIM(RTRIM(STR(@@SPID)))
			SET @cCmd=N'SELECT '+(CASE WHEN @bSHowImage=1 THEN 'IMG_ID,' else '' END)+'total_mode,org_rowno,'+@cRetOutputCols+
			',[paymodesData] FROM '+@cInputTable+' a LEFT JOIN '+@cPaymentTableName+' b ON a.cm_id=b.cm_id '+
			@cFilterTotalRowsExpr+'	ORDER BY org_rowno'
			
			EXEC SPWOW_GENXPERT_RETAILSALE_PAYMENTSUMMARY
			@nViewPaymodeType=@nShowRetailsalePaymentsViewMode,
			@cRepTempTable=@cInputTable,
			@cPaymentTableName=@cPaymentTableName,
			@cRunCmd=@cCmd
		END
		ELSE
		BEGIN
			PRINT @cCmd 
			EXEC SP_EXECUTESQL @cCmd
		END

		--SET @cStep='125'
		--SET @cCmd=N'DROP TABLE '+@cInputTable
		--PRINT @cCmd
		--EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	BEGIN
		SET @cStep='126.5'
		SET @cCmd=N'SELECT org_rowno,'+@cRetOutputColsNames+' FROM '+@cInputTable+@cFilterTotalRowsExpr+'  ORDER BY org_rowno'

		SELECT @cCmd bcpCmd,@cInputTable tempTableName

		SET @cCmd=N' SELECT '+@cRetOutputCols+' FROM '+@cInputTable+' WHERE 1=2'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='128'
	SET @cCmd=N'DROP TABLE '+@cRepTemptable
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_XTREME_REPORTTOTALS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	print 'last step of SPWOW_XTREME_REPORTTOTALS :'+@cStep
END
