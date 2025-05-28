CREATE PROCEDURE SPWOW_GENXPERT_REPDATA_stock
@cRepTempTable VARCHAR(400),
@dFromDt DATETIME,
@dToDt DATETIME,
@cHoLocId VARCHAR(5)='',
@cOpsPmtTableName VARCHAR(100)='#pmtops',
@cCbsPmtTableName VARCHAR(100)='#pmtcbs'
AS
BEGIN
	DECLARE @cXnType VARCHAR(10),@cCmd NVARCHAR(MAX),@cBaseExpr VARCHAR(MAX),@cInsCols VARCHAR(MAX),
	@cBaseExprOutput VARCHAR(MAX),@nLoop INT,@cColumnId VARCHAR(10),@cPmtTable VARCHAR(100),@cPmtAlias VARCHAR(100),
	@cLayoutCols VARCHAR(MAX),@bCalculateTotalsForXtab BIT,@cOrderColumnId VARCHAR(10),@cObpColId VARCHAR(10),@cStep VARCHAR(5),
	@cCbpColId VARCHAR(10),@cDepcnJoinStr VARCHAR(400),	@cErrormsg VARCHAR(MAX),@bGetPmtFromAPp BIT,@cHavingClause VARCHAR(200),
	@dFromDtLastMonthEndDt DATETIME,@dToMonthEndDt DATETIME,@cReferDailyPmt BIT,@bShowEstimateItems BIT
	
	--select 'check #wow_xpert_rep_det for stock column',* from #wow_xpert_rep_det

BEGIN TRY

	SET @cStep='10'
	SELECT TOP 1 @bCalculateTotalsForXtab=ISNULL(calculate_totals_for_xtab,0) FROM #tmpPeriodBase 
	WHERE ISNULL(processed,0)=0 OR ISNULL(calculate_totals_for_xtab,0)=1
   

    SELECT TOP 1 @cReferDailyPmt=value FROM config (NOLOCK) WHERE config_option='PMT_BUILD_DATEWISE'

	SET @cReferDailyPmt=ISNULL(@cReferDailyPmt,'')


  	SET @dFromDtLastMonthEndDt=DATEADD(DAY, -DAY(@dFromDt), CAST(@dFromDt AS DATE))
	SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dToDt) + 1, 0))

	SET @cOrderColumnId=''
	IF @bCalculateTotalsForXtab=1
	BEGIN
		SET @cStep='20'
		SELECT TOP 1 @cOrderColumnId = b.order_by_column_id FROM #wow_xpert_rep_det a
		JOIN WOW_xpert_report_cols_expressions b ON a.column_id=b.column_id
		WHERE a.dimension=1

		SET @cOrderColumnId=ISNULL(@cOrderColumnId,'')
	END

	--if @@spid=52
	--	select 'check ageslabs',* from #tmpageslabs

	SET @cStep='50'
	create table #tmpStkDepcn (product_code varchar(50),depcn_value numeric(10,2),mode NUMERIC(1,0))

	CREATE TABLE #tmpStkRepMode (pmtstk_mode INT)

	INSERT INTO #tmpStkRepMode
	select 1


	SELECT TOP 1 @bShowEstimateItems=ISNULL(ShowEstimateItems,0)  FROM #wow_xpert_rep_mst

	IF LEFT(DB_NAME(),4)<>'PUMA' AND @cReferDailyPmt<>'1'
		SELECT TOP 1 @bGetPmtFromApp=getpmtfromApp FROM #wow_xpert_rep_mst
	ELSE
		SET @bGetPmtFromApp=0

	SET @nLoop=1
	WHILE @nLoop<=2
	BEGIN
		SELECT @cLayoutCols=NULL,@cInsCols=NULL,@cObpColId=NULL,@cCbpColId=null

		SET @cStep='60'
		SET @cColumnId=''	
		IF @nLoop=1
		BEGIN
			SET @cStep='65'
			SELECT TOP 1 @cColumnId=a.column_id,@cPmtTable=(CASE WHEN @bGetPmtFromApp=1 AND @dFromDt-1<>@dFromDtLastMonthEndDt THEN  @cOpsPmtTableName 
			ELSE DB_NAME()+'_PMT.DBO.PMTLOCS_'+CONVERT(VARCHAR,@dFromDt-1,112) END)
			FROM #wow_xpert_rep_det a
			JOIN wow_xpert_report_cols_expressions b ON a.column_id=b.column_id
			WHERE a.col_expr like '%pmt_obs.%'

			SELECT TOP 1 @cObpColId=a.column_id
			FROM #wow_xpert_rep_det a
			JOIN wow_xpert_report_cols_expressions b ON a.column_id=b.column_id
			WHERE a.col_expr like '%pmt_obs.%' AND a.col_expr like '%sku_names.pp%' and a.col_expr like '%cbs_qty%'

			UPDATE #tmpStkRepMode SET pmtstk_mode=1

		END
		ELSE
		BEGIN
			SET @cStep='70'
			
			 --@dToDt=CONVERT(DATE,GETDATE()) THEN 'pmt01106' 
			SELECT TOP 1 @cColumnId=column_id,@cPmtTable=(CASE WHEN @dToDt=CONVERT(DATE,GETDATE()) THEN 'pmt01106' WHEN @bGetPmtFromAPp=1
			AND @dToDt<>@dToMonthEndDt THEN @cCbsPmtTableName ELSE
			DB_NAME()+'_PMT.DBO.PMTLOCS_'+CONVERT(VARCHAR,@dToDt,112) END)
			FROM #wow_xpert_rep_det WHERE col_expr like '%PMT_CBS.%'

			SELECT TOP 1 @cCbpColId=a.column_id
			FROM #wow_xpert_rep_det a
			JOIN wow_xpert_report_cols_expressions b ON a.column_id=b.column_id
			WHERE a.col_expr like '%PMT_CBS.%' AND a.col_expr like '%sku_names.pp%' and a.col_expr like '%cbs_qty%'

			UPDATE #tmpStkRepMode SET pmtstk_mode=2

	    END
		

		IF ISNULL(@cColumnId,'')=''
			GOTO lblNext
		
		SET @cStep='80'
		SET @cPmtAlias=(CASE WHEN @nLoop=1 THEN 'pmt_obs' ELSE 'pmt_cbs' END)

		delete from   #tmpStkDepcn 

		SET @cDepcnJoinStr=''

		IF @cObpColId IS NOT NULL
		BEGIN
			SET @cStep='90'
			PRINT 'Enter Obpcolid'
			EXEC  SPWOW_PREPARE_STKDEPCN_DATA
			@dXndt=@dFromDt,
			@cPmtTable=@cPmtTable,
			@nMode=1

			SET @cDepcnJoinStr='LEFT JOIN #tmpStkDepcn depcn1 ON depcn1.product_code='+@cPmtAlias+'.product_code AND depcn1.mode=1'

		END
		ELSE
		IF @cCbpColId IS NOT NULL
		BEGIN
			SET @cStep='100'
			PRINT 'Enter Cbpcolid'
			EXEC  SPWOW_PREPARE_STKDEPCN_DATA
			@dXndt=@dToDt,
			@cPmtTable=@cPmtTable,
			@nMode=2

			SET @cDepcnJoinStr='LEFT JOIN #tmpStkDepcn depcn2 ON depcn2.product_code='+@cPmtAlias+'.product_code AND depcn2.mode=2'

		END

		DECLARE @cAgeingSlabJoinStr VARCHAR(1500),@cAgeColExpr VARCHAR(200)
		SET @cAgeingSlabJoinStr=''

		IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det WHERE column_id='ageing_1')
		BEGIN
			SELECT TOP 1 @cAgeColExpr=REPLACE(col_expr,'[todate]',''''+convert(varchar,@dToDt,112)+'''') FROM wow_xpert_report_cols_expressions (NOLOCK) WHERE column_id='C1164'
			SET @cAgeColExpr=REPLACE(@cAgeColExpr,'avg(','(')

			SET @cAgeingSlabJoinStr=' LEFT JOIN #tmpAgeSlabs purAgeSlabs ON '+@cAgeColExpr+' BETWEEN purAgeSlabs.fromDays and purAgeSlabs.toDays'
		END


		
		IF EXISTS (SELECT TOP 1 * FROM #wow_xpert_rep_det WHERE column_id='ageing_3')
		BEGIN
			SELECT TOP 1 @cAgeColExpr=REPLACE(col_expr,'[todate]',''''+convert(varchar,@dToDt,112)+'''') FROM wow_xpert_report_cols_expressions(NOLOCK) WHERE column_id='C1165'
			SET @cAgeColExpr=REPLACE(@cAgeColExpr,'avg(','(')
			SET @cAgeingSlabJoinStr=@cAgeingSlabJoinStr+' LEFT JOIN #tmpAgeSlabs shelfAgeSlabs ON '+@cAgeColExpr+' BETWEEN shelfAgeSlabs.fromDays and shelfAgeSlabs.toDays'
		END

		SET @cHavingClause=' HAVING SUM('+(CASE WHEN @cPmtAlias='pmt_cbs' AND CONVERT(DATE,GETDATE())=@dToDt THEN 'quantity_in_stock' ELSE 'cbs_qty' END)+')<>0'

		SET @cStep='110'
		SELECT @cBaseExpr='[LAYOUT_COLS] from '+@cPmtTable+' '+@cPmtAlias+' (NOLOCK)    
		LEFT JOIN location SourceLocation (NOLOCK) ON SourceLocation.dept_id='+@cPmtAlias+'.dept_id
		LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code

		JOIN state  TargetLocation_state on TargetLocation_state.state_code=SourceLocation_city.state_code
		JOIN location TargetLocation (NOLOCK) ON TargetLocation.dept_id=SourceLocation.dept_id
		JOIN city  Targetlocation_city on Targetlocation_city.city_code=SourceLocation_area.city_code
		
		LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.dept_id='+@cPmtAlias+'.dept_id AND sku_xfp.product_code='+@cPmtAlias+'.product_code
		LEFT JOIN sku_current_xfp (NOLOCK) ON sku_current_xfp.dept_id='+@cPmtAlias+'.dept_id AND sku_current_xfp.product_code='+@cPmtAlias+'.product_code
		left outer join loc_names groupSuppler on groupSuppler.dept_id= sku_xfp.challan_source_location_code

		join SKU_NAMES (NOLOCK) ON sku_names.product_code='+@cPmtAlias+'.product_code
		LEFT JOIN BARCODEWISE_EOSS_SCHEMES_INFO eosssch (NOLOCK) ON eosssch.location_id='+@cPmtAlias+'.dept_id AND eosssch.product_code='+@cPmtAlias+'.product_code
		LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=sku_names.ac_code
		Left outer JOIN Hd01106 supplier_Hdd on supplier_Hdd.head_code = supplier_lm01106.Head_code
		LEFT JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
		LEFT JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
		LEFT JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
		LEFT JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
		LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
		LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
		LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
		LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code		 
		LEFT OUTER JOIN  #skumrpcat   skumrpcat ON 1=1   AND SKU_NAMES.MRP BETWEEN skumrpcat.FROMN  AND skumrpcat.TON 

		LEFT JOIN XN_ITEM_TYPE_DESC_mst (NOLOCK) on XN_ITEM_TYPE_DESC_mst.XN_ITEM_TYPE=SKU_NAMES.sku_ITEM_TYPE
		JOIN bin SourceBin on SourceBin.bin_id='+@cPmtAlias+'.bin_id
    	Left outer Join bin MajorSourceBin on MajorSourceBin.BIN_ID=SourceBin.major_bin_id
		JOIN LOC_NAMES (NOLOCK) on LOC_NAMES.dept_id='+@cPmtAlias+'.dept_id '+' '+ISNULL(@cDepcnJoinStr,'')+@cAgeingSlabJoinStr+
  		' WHERE sku_names.stock_na=0 AND '+(CASE WHEN @bShowEstimateItems=1 THEN ' ' ELSE 'Sku_Names.Sku_Er_Flag IN (0 , 1 ) AND ' END)+ 
		' [WHERE]   group by [GROUPBY]'+@cHavingClause


		--(CASE WHEN col_expr like '%cbs_qty%' AND @dToDt=CONVERT(DATE,GETDATE()) 
		--AND @nLoop=20 THEN REPLACE(col_expr,'cbs_qty','quantity_in_stock') ELSE col_expr  END)

		SET @cStep='120'
		SELECT 	@cLayoutCols=COALESCE(@cLayoutCols+',','')+(CASE WHEN col_expr like '%cbs_qty%' AND @dToDt=CONVERT(DATE,GETDATE()) 
		AND @nLoop=2 THEN REPLACE(col_expr,'cbs_qty','quantity_in_stock') ELSE col_expr  END),
		@cInsCols=COALESCE(@cInsCols+',','')+'['+col_header+']' 
		FROM 
		(SELECT DISTINCT (CASE WHEN @bCalculateTotalsForXtab=1 AND (c.dimension=1 or a.column_id=@cOrderColumnId) THEN '''ZZZTotal'''
		ELSE c.col_expr END) col_expr,c.col_header FROM  wow_xpert_report_cols_expressions a
		JOIN wow_xpert_report_cols_xntypewise b ON a.column_id=b.column_id
		JOIN #wow_xpert_rep_det c (NOLOCK) ON a.column_id=c.column_id
		LEFT JOIN wow_xpert_report_cols_xntypewise d (NOLOCK) ON d.ref_column_id=c.column_id
		WHERE b.xn_type='STOCK' AND d.column_id IS NULL
		AND (a.col_mode=1 OR a.col_expr LIKE '%'+@cPmtAlias+'.%' or a.column_id IN ('C1164','C1165','C1476')) and a.column_id<>'ageing_2'
		) a

		--if @@spid=372
			--select @cLayoutCols stockLayoutCols
		

		SET @cStep='130'
		EXEC SPWOW_GETXPERT_INSCOLS
		@cXntype='STOCK',
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@cHoLocId=@cHoLocId,
		@cBaseExprInput=@cBaseExpr,
		@cLayoutColsPara=@cLayoutCols,
		@cInsColsPara=@cInsCols,
		@cInsCols=@cInsCols OUTPUT,
		@cBaseExprOutput=@cBaseExprOutput OUTPUT

		
		SET @cStep='140'
		SET @cCmd=N'INSERT INTO '+@cRepTempTable+' ('+@cInsCols+')
					SELECT '+@cBaseExprOutput

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	lblNext:
		SET @nLoop=@nLoop+1
		
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_GENXPERT_REPDATA_STOCK at Step#'+@cStep+' '+error_message()

	print 'Enter catch of SPWOW_GENXPERT_REPDATA_STOCK'
	INSERT INTO #tSubProcError (errmsg)
	SELECT @cErrormsg

	GOTO END_PROC
END CATCH

END_PROC:

IF NOT EXISTS (SELECT TOP 1 * FROM #tSubProcError) AND ISNULL(@cErrormsg,'')<>''
	INSERT INTO #tSubProcError (errmsg)
	SELECT @cErrormsg

END