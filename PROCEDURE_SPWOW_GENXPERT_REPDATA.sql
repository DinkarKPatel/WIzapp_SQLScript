CREATE PROCEDURE SPWOW_GENXPERT_REPDATA
@nMode NUMERIC(1,0)=1, --1.View Report , 2. Export Data , 3. Bulk Export to CSV by using bcp at application level
@cRepId CHAR(10),
@dFromDt DATETIME,
@dToDt DATETIME,
@bGetPmtOnTheFly BIT=0,
@bShowEstimateItems BIT=0
AS
BEGIN
	DECLARE @cTempDb VARCHAR(200),@cRepTableName VARCHAR(200),@cRepTempTable VARCHAR(300),@cColNames VARCHAR(max),@cStep VARCHAR(5),
			@cXnType varchar(200),@cHoLocId VARCHAR(5),@cCmd NVARCHAR(MAX),@cErrormsg VARCHAR(MAX),@cXpertRepCode VARCHAR(5),
			@cXntypeProc VARCHAR(100),@bAgeColsFound BIT,@cAgeColnames VARCHAR(MAX),@nPeriodLoop NUMERIC(1,0),@nLoop NUMERIC(1,0),
			@cPeriodBase VARCHAR(10),@nInnerLoop NUMERIC(1,0),@nCrosstabType NUMERIC(1,0),@cXnTypeProcess VARCHAR(20),
			@bShowImage BIT,@bFetchingData BIT,@cErrProcName VARCHAR(200),@nMeasureColsCount INT,@nShowRetailsalePaymentsViewMode INT
	
BEGIN TRY
	SET @cStep='5'
	SET @bFetchingData=0

	DECLARE @bBulkExport BIT
	SET @bBulkExport=(CASE WHEN @nMode=3 THEN 1 ELSE 0 END)

	--- Now this part os making rep_mst temp table is shifted to APplication as per discussion with  Sir to discard the updation of filter criteria
	--- updation in xpert_rep_mst table on every report viewing. Instead it will be now updated in Temp table (Date:21-02-2025)

	--select *,@bBulkExport BulkExport,CONVERT(NVARCHAR(MAX),'') xtab_cols_list,@bGetPmtOnTheFly getPmtFromApp,@bShowEstimateItems showEstimateItems 
	--into #wow_xpert_rep_mst from wow_xpert_rep_mst where rep_id=@cRepid

	SELECT TOP 1 @cXpertRepCode=xpert_rep_code,@nCrosstabType=ISNULL(CrossTab_Type,0) FROM #wow_xpert_rep_mst
	
	DECLARE @bOlapReportingEnabled BIT
	SELECT TOP 1 @bOlapReportingEnabled=activated FROM olapconfig (NOLOCK) WHERE xpert_rep_code=@cXpertRepCode
	SET @bOlapReportingEnabled=ISNULL(@bOlapReportingEnabled,0)
	IF @bOlapReportingEnabled=1 -- Stock analysis reporting shifted to Olap server via Wow only
		RETURN

	SELECT a.*,convert(varchar(500),'') col_expr,CONVERT(BIT,0) calculative_col,b.order_by_column_id,CONVERT(BIT,0) order_column,
	CONVERT(VARCHAR(200),'') unpivot_xtab_col_header,CONVERT(BIT,0) derivedcolref
	INTO #wow_xpert_rep_det from wow_xpert_rep_det a (NOLOCK)
	JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
	WHERE rep_id=@cRepid
	order by col_order

	CREATE TABLE #tmpAgeSlabs (mode INT,fromDays INT,toDays INT,slabName VARCHAR(100),srno int)
	
	DECLARE @dComaprePeriodFrom DATETIME,@dComaprePeriodTo DATETIME,@nMainLoopCnt NUMERIC(1,0),@nMainLoop NUMERIC(1,0),
	@dMainFromDt DATETIME,@dMainToDt DATETIME
	SET @cStep='5.2'
	SELECT TOP 1 @dComaprePeriodFrom=compare_period_from_dt,@dComaprePeriodTo=compare_period_to_dt,
	@nShowRetailsalePaymentsViewMode=isnull(showRetailsalePaymentsViewMode,0) FROM #wow_xpert_rep_mst

	IF ISNULL(@dComaprePeriodFrom,'')<>''
	BEGIN
		SET @cStep='5.6'
		
		UPDATE #wow_xpert_rep_mst SET crosstab_type=1
		UPDATE #wow_xpert_rep_det SET dimension=0

		INSERT #wow_xpert_rep_det	(rep_id,row_id,col_order, Calculative_col, col_expr, col_header, Dimension, column_id, 
		Measurement_col,xn_type,col_width ) 
		SELECT @cRepId rep_id, newid() row_id,0 col_order, 0 Calculative_col,'period base' col_expr,'Period Base' col_header,
		1 Dimension,'period' column_id, 0 Measurement_col,'' xn_type,0 col_width

	END

	SELECT @nMeasureColsCount=count(*) FROM #wow_xpert_rep_det where Measurement_col=1

	SET @cStep='6.2'
	IF exists (select top 1 rep_id FROM #wow_xpert_rep_mst where ISNULL(CrossTab_Type,0)>=1)
		AND (NOT EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det where dimension=1)
		OR NOT EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det where Measurement_col=1))
		UPDATE #wow_xpert_rep_mst SET crosstab_type=0
	
	
	if exists(select top 1 * FROM #wow_xpert_rep_det where column_id in ('ageing_1','ageing_2','ageing_3') and xn_type='Stock')
		AND EXISTS (SELECT TOP 1 rep_id FROM #wow_xpert_rep_det WHERE Measurement_col=1)
		UPDATE #wow_xpert_rep_mst SET crosstab_type=1 where crosstab_type=0

	SET @cStep='7.4'
	
	UPDATE a SET dimension=0,measurement_col=0 FROM  #wow_xpert_rep_det a
	JOIN #wow_xpert_rep_mst b ON a.rep_id=b.rep_id
	WHERE ISNULL(b.crosstab_type,0)=0



	CREATE TABLE #tSubProcError (errmsg varchar(max))

	SET @cStep='10'
	UPDATE a set col_expr=b.col_expr,calculative_col=(CASE WHEN b.col_mode=2 and b.col_data_type<>'String' THEN 1 ELSE 0 END),
	order_column=(CASE WHEN c.column_id IS NOT NULL THEN 1 ELSE 0 END),order_by_column_id=b.order_by_column_id
	from #wow_xpert_rep_det a
	JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON b.column_id=a.column_id
	LEFT JOIN wow_xpert_report_cols_expressions c (NOLOCK) ON c.order_by_column_id=a.column_id

	--if @@spid=86
	--select 'check #wow_xpert_rep_det',* from #wow_xpert_rep_det

	

	UPDATE #wow_xpert_rep_det SET col_expr=REPLACE(col_expr,'[todate]',''''+convert(varchar,@dToDt,112)+'''') WHERE column_id in ('C1164','C1165')



	CREATE TABLE #loopXntypes (xn_type VARCHAR(20),proc_name VARCHAR(200),measureColsCount NUMERIC(2,0))


	SET @cStep='12'

	--if @@spid=84
	--select 'check xpert_rep_det before adding ageing cols',* from #wow_xpert_rep_det

	EXEC SPWOW_XPERT_PROCESS_DERIVED_COLS 
	@nMode=1,
	@cErrormsg=@cErrormsg OUTPUT

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	--if @@spid=110
	--select 'check xpert_rep_det after derived cols',b.proc_name, a.* FROM #wow_xpert_rep_det a
	--JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
	--JOIN wow_xpert_report_cols_expressions c ON a.column_id=c.column_id
	--JOIN wow_xpert_report_colheaders d ON d.major_column_id=b.major_column_id
	--WHERE col_mode=2 AND ISNULL(b.proc_name,'')<>'' 


	--if @@spid=145
	--	select 'check wow_xpert_rep_det', * FROM #wow_xpert_rep_det a

	
	--IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det WHERE ISNULL(row_id,'')='')
	--BEGIN
		UPDATE c SET derivedcolref=1 FROM #wow_xpert_rep_det a JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND b.xn_type=a.xn_type
		JOIN #wow_xpert_rep_det c on c.column_id=b.ref_column_id 
		--where isnull(a.row_id,'')='' 
	--END

	SET @cStep='12.5'
	INSERT INTO #loopXntypes (xn_type,proc_name,measureColsCount)
	SELECT a.xn_type,b.proc_name,sum(case when ISNULL(a.Measurement_col,0)=1 THEN 1  ELSE 0 END) FROM #wow_xpert_rep_det a
	JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id AND a.xn_type=b.xn_type
	JOIN wow_xpert_report_cols_expressions c ON a.column_id=c.column_id
	JOIN wow_xpert_report_colheaders d ON d.major_column_id=b.major_column_id
	--LEFT JOIN #wow_xpert_rep_det ref ON ref.column_id=b.ref_column_id AND b.xn_type=ref.xn_type 
	WHERE col_mode=2 AND isnull(a.derivedcolref,0)=0 and  ISNULL(b.proc_name,'')<>''  --and (ref.column_id is not null or isnull(b.ref_column_id,'')='')
	GROUP BY a.xn_type,b.proc_name

	if isnull(@dComaprePeriodFrom,'')<>''
		UPDATE l SET measureColsCount=1 FROM #wow_xpert_rep_det a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.ref_column_id AND a.xn_type=b.xn_type
		join #loopXntypes l ON l.xn_type=b.xn_type AND l.proc_name=b.proc_name
		WHERE ISNULL(l.measureColsCount,0)=0 and a.Measurement_col=1

	--if @@spid=145
	--	select 'check @cXntypeProc-2',* from #loopXntypes

	SET @cStep='17'
	SET @cErrormsg=''

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='ho_location_id'
	SET @cTempdb=db_name()+'_image.dbo.'

	SET @cStep='20'
	SET @cRepTableName='##rep_det_'+replace(left(convert(varchar(38),newid()),10),'-','_')
		
	
	IF @cXpertRepCode<>'R1'
		SELECT TOP 1  @cXnType=xn_type FROM #loopXntypes
	ELSE
		SET @cXntype='STOCK'
	
	SET @cStep='30'
	SELECT @cColNames=COALESCE(@cColNames+',','')+(CASE WHEN col_data_type='Date' THEN 'CONVERT(DATE,'''')' 
	WHEN col_data_type='Numeric' THEN 'CONVERT(NUMERIC(20,3),0)' ELSE  'CONVERT(VARCHAR(2000),'''')' END)+
	' as ['+col_header+']'
	FROM 
	(SELECT DISTINCT c.col_header,col_data_type FROM  wow_xpert_report_cols_expressions a
	JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
	) a
	

	if @cXpertRepCode='r6' and exists (select top 1 a.column_id from wow_xpert_report_cols_xntypewise a
	JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id where a.xn_type='eoss' and a.proc_name like '%stock%')
	begin
		SELECT @cColNames=COALESCE(@cColNames+',','')+(CASE WHEN col_data_type='Date' THEN 'CONVERT(DATE,'''')' 
	WHEN col_data_type='Numeric' THEN 'CONVERT(NUMERIC(20,3),0)' ELSE  'CONVERT(VARCHAR(2000),'''')' END)+
	' as ['+col_header+']'
		FROM 
		(SELECT DISTINCT a.col_expr,col_data_type,replace(a.col_expr,'sku_names.','') col_header FROM  wow_xpert_report_cols_expressions a
		 where a.invmasterPara=1 
		) a
	end

	DECLARE @cAgeingGroupName VARCHAR(200)
	SELECT TOP 1 @cAgeingGroupName=ageingGroupName FROM #wow_xpert_rep_mst
	SET @bAgeColsFound=0
	
	SET @cStep='40.5'
	EXEC SPWOW_PREPARE_AGEINGSLABS
	@cAgeingSettingName=@cAgeingGroupName

	

	IF EXISTS (SELECT TOP 1 rep_id FROM  #wow_xpert_rep_det WHERE column_id in ('ageing_1','ageing_2','ageing_3'))
	AND EXISTS (SELECT TOP 1 rep_id FROM #wow_xpert_rep_det WHERE Measurement_col=1)
	BEGIN
		SET @bAgeColsFound=1

		SET @cStep='40'
		UPDATE #wow_xpert_rep_mst set CrossTab_Type=1 where crosstab_type=0

		UPDATE #wow_xpert_rep_det SET col_expr=REPLACE(col_expr,'[todate]',''''+convert(varchar,@dToDt,112)+'''') WHERE column_id in ('C1164','C1165')

		SET @cStep='41.2'
		SELECT DISTINCT (CASE WHEN a.mode=1 THEN 'Purchase ageing Category' WHEN mode=2 THEN 'Sale ageing Category' ELSE 'Shelf ageing Category' END) as rep_ageing_col,
		A.slabName rep_col,a.srno colOrder
		INTO #tmpAgeCols FROM #tmpAgeSlabs a
		JOIN #wow_xpert_rep_det b ON  b.column_id=(CASE WHEN a.mode=1 THEN 'ageing_1' WHEN a.mode=2 THEN 'ageing_2' ELSE 'ageing_3' END)

	END

	IF @cXpertRepCode NOT IN ('R1','R6')
	BEGIN
		SET @cStep='42'
		SET @cColNames=@cColNames+',CONVERT(VARCHAR(100),'''') AS [Transaction type]'
	END

	SET @cStep='45'
	SELECT TOP 1 @bShowImage=ISNULL(show_image,0) FROM #wow_xpert_rep_mst

	IF @bShowImage=1
		SET @cColNames=@cColNames+',Convert(varchar(200),'''') IMG_ID'
	

	IF ISNULL(@dComaprePeriodFrom,'')<>''
		SET @cColNames=@cColNames+',Convert(varchar(50),'''') [Period Base]'
	

	SET @cStep='50'
	SET @cRepTempTable=@cTempdb+@cRepTableName

	IF @cXpertRepCode='R2' AND @nShowRetailsalePaymentsViewMode>0
		SET @cColNames='convert(varchar(50),'''') cm_id,'+@cColNames
	
	
	set @cCmd=N'SELECT '+@cColNames+' INTO '+@cRepTempTable+' WHERE 1=2'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	CREATE TABLE #tmpPeriodBase (base VARCHAR(10),processed BIT,calculate_totals_for_xtab BIT,process_compare_period BIT,comparison_period_found BIT)
	
	SET @cStep='55'
	EXEC SPWOW_GET_XPERT_PERIODBASE

	SELECT @nPeriodLoop=COUNT(*) FROM #tmpPeriodBase

	SET @cStep='57'
	SET @nMainLoop=(CASE WHEN ISNULL(@dComaprePeriodFrom,'')='' THEN 1 ELSE 2 END)
	
	IF ISNULL(@dComaprePeriodFrom,'')<>''
		UPDATE #tmpPeriodBase SET comparison_period_found=1

	--if @@spid=80
	--	select 'check #loopXntypes',* from  #loopXntypes

	select @dMainFromDt=@dFromDt,@dMainToDt=@dToDt

	DECLARE @bCbsColsFound BIT,@bCompareStockProcessed BIT
	IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det WHERE col_expr like '%pmt_cbs%')
		SET @bCbsColsFound=1

	
	SET @bCompareStockProcessed=0

	DECLARE @cOpsPmtTableName VARCHAR(100),@cCbsPmtTableName VARCHAR(100)

	SELECT @cOpsPmtTableName='#pmtops',@cCbsPmtTableName='#pmtcbs'

	--if @@spid=80
	--	select 'check #tmpPeriodBase',* from #tmpPeriodBase

	DECLARE @cReferDailyPmt VARCHAR(2),@bGetPmtFromApp BIT
	SELECT TOP 1 @cReferDailyPmt=value FROM config (NOLOCK) WHERE config_option='PMT_BUILD_DATEWISE'

	SET @cReferDailyPmt=ISNULL(@cReferDailyPmt,'')
	SET @bGetPmtFromApp=1

	
	DECLARE @bMeasureColsFound BIT
	WHILE EXISTS (SELECT TOP 1 xn_type FROM #loopXntypes)
	BEGIN
		SELECT TOP 1 @cXntypeProc=proc_name,@cXnTypeProcess=xn_type,@bMeasureColsFound=(case when measureColsCount>0 THEN 1 ELSE 0 END) FROM #loopXntypes
		
		UPDATE #tmpPeriodBase SET processed=null,calculate_totals_for_xtab=null,process_compare_period=null

		SELECT @dFromdt=@dMainFromDt,@dToDt=@dMainToDt
		SET @nMainLoopCnt=1
		WHILE @nMainLoopCnt<=@nMainLoop
		BEGIN
			IF @nMainLoopCnt=2
			BEGIN
				SELECT @dFromdt=@dComaprePeriodFrom,@dToDt=@dComaprePeriodTo

				UPDATE #tmpPeriodBase SET process_compare_period=1

				
				--if @@spid=110
				--	select 'check period base-2', @bMeasureColsFound,@cXntypeProc

				IF  @bMeasureColsFound=0
					BREAK

				IF @cXpertRepCode='R1' AND @bCbsColsFound=1 AND @cXntypeProc='SPWOW_GENXPERT_REPDATA_STOCK' AND @bCompareStockProcessed=0
				BEGIN
					
					IF @cReferDailyPmt=''
					BEGIN
						SELECT @cOpsPmtTableName='#pmtops_compare',@cCbsPmtTableName='#pmtcbs_compare'
					
						select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtops_compare from pmt01106 where 1=2
						select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtcbs_compare from pmt01106 where 1=2


						exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY 
						@dFromDt=@dFromDt,
						@dToDt=@dToDt,
						@bUpdateCbsOnly=1,
						@bComparisonStock=1,
						@cErrormsg=@cErrormsg OUTPUT
					END

					SET @bCompareStockProcessed=1
				END
			END

			SET @nLoop=1
			
			WHILE @nLoop<=@nPeriodLoop
			BEGIN
				SET @nInnerLoop=1
				WHILE @nInnerLoop<=2
				BEGIN
					SET @cStep='59'
					SELECT TOP 1 @cPeriodBase=base FROM #tmpPeriodBase WHERE processed IS NULL


					UPDATE #tmpPeriodBase SET processed=0 WHERE base=@cPeriodBase
					SET @cStep='61'
					SET @bFetchingData=1
					
					SET @cCmd=N'EXEC '+@cXntypeProc+
					' @cRepTempTable='''+@cRepTempTable+''',
						@dFromDt='''+CONVERT(VARCHAR,@dFromDt,110)+''',
						@dToDt='''+CONVERT(VARCHAR,@dToDt,110)+''',
						@cHoLocId='''+@cHoLocId+''''

					IF @cXpertRepCode='R1' AND @nMainLoopCnt=2
					BEGIN 
						IF RIGHT(@cXnTypeProcess,3) IN ('CHO','CHI') OR RIGHT(@cXntypeProc,7) IN('GRP_PUR','GRP_WSR')
							SET @cCmd=@cCmd+',@bCalledfromStkAnalysis=1'

						IF  @cXntypeProc='SPWOW_GENXPERT_REPDATA_STOCK' 
							SET @cCmd=@cCmd+',@cOpsPmtTableName='''+@cOpsPmtTableName+''',@cCbsPmtTableName='''+@cCbsPmtTableName+''''
					END
				    
					print 'Xn type being processed:'+@cXntypeProcess
					PRINT @cCmd
					EXEC SP_EXECUTESQL @cCmd

					IF EXISTS (SELECT TOP 1 errmsg FROM #tSubProcError)
					BEGIN
						SELECT TOP 1 @cErrormsg=errmsg FROM #tSubProcError
						GOTO END_PROC
					END

					SET @bFetchingData=0
					SET @cStep='63'
					UPDATE #tmpPeriodBase SET processed=1,calculate_totals_for_xtab=(CASE WHEN @nCrosstabType=2 THEN 1 ELSE 0 END)
					WHERE base=@cPeriodBase

					SET @nInnerLoop=@nInnerLoop+1

					IF @nCrosstabType<=1
						BREAK
				END

				SET @nLoop=@nLoop+1
			END
			SET @nMainLoopCnt=@nMainLoopCnt+1
		END

		DELETE FROM #loopXntypes  where proc_name=@cXntypeProc
	END


	SET @cStep='70'
	DECLARE @cXrErrormsg VARCHAR(MAX)
	
	IF @nMode IN (1,3)
	BEGIN
	
		EXEC SPWOW_XTREME_REPORTTOTALS
		@cTempDb=@cTempDb,
		@bBulkExport=@bBulkExport,
		@cRepTempTable=@cRepTempTable,
		@cErrormsg=@cXrErrormsg OUTPUT
	END
	ELSE
	BEGIN
		EXEC SPWOW_XTREME_REPORTTOTALS_RAWDATA
		@cTempDb=@cTempDb,
		@cRepTempTable=@cRepTempTable,
		@cErrormsg=@cXrErrormsg OUTPUT
	END

	IF ISNULL(@cXrErrormsg,'')<>''
		GOTO END_PROC
END TRY

BEGIN CATCH
	IF @bFetchingData=1
		SET @cErrProcName=@cXntypeProc
	ELSE
		SET @cErrProcName='SPWOW_GENXPERT_REPDATA  at Step#'+@cStep

	SET @cErrormsg='Error in Procoedure :'+@cErrProcName+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:


IF ISNULL(@cXrErrormsg,'')<>''					 
	SET @cErrormsg=@cXrErrormsg

IF @cErrormsg<>''
	SELECT @cErrormsg errmsg

END