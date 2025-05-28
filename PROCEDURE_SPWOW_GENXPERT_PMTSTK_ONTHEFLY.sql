CREATE PROCEDURE SPWOW_GENXPERT_PMTSTK_ONTHEFLY
@dFromDt DATETIME,
@dToDt DATETIME,
@cRepId VARCHAR(15)='',
@bUpdateCbsOnly BIT=0,
@bComparisonStock BIT=0,
@cFilterPara VARCHAR(200)='',
@bUpdateOpsXnsOnly BIT=0,
@bUpdateOpsOnly BIT=0,
@bCalledfromPlBs BIT=0,
@cErrormsg varchar(max) output
AS
BEGIN
	
	DECLARE @CcMD nvarchar(max),@cPmtTableName VARCHAR(500),@dFromDtLastMonthEndDt DATETIME,@dToDtLastMonthEndDt DATETIME,@dToMonthEndDt DATETIME,@bOpsColFound BIT,@bCbsColFound BIT,
	@dFromDtPara DATETIME,@dToDtPara DATETIME,@cFromDtPara VARCHAR(20),@cToDtPara  VARCHAR(20),@cFilter VARCHAR(MAX),
	@cStep VARCHAR(10),@cXnFilter VARCHAR(MAX),@cOpsPmtTableName VARCHAR(100),@cCbsPmtTableName VARCHAR(100)
	
	SET @cErrormsg=''

BEGIN TRY
	
	--if @@spid=853
	--	select @dFromDt dfromdt
	SET @cStep='10'

	IF @bComparisonStock=0
	BEGIN
		truncate table #pmtops
		truncate table #pmtcbs
	END

	SELECT @cOpsPmtTableName=(CASE WHEN @bComparisonStock=0 THEN '#pmtops' ELSE '#pmtops_compare' END),
	@cCbsPmtTableName=(CASE WHEN @bComparisonStock=0 THEN '#pmtcbs' ELSE '#pmtcbs_compare' END)

	DECLARE @bOlapReportingEnabled BIT
	SELECT TOP 1 @bOlapReportingEnabled=activated FROM olapconfig (NOLOCK) WHERE xpert_rep_code='R1'
	SET @bOlapReportingEnabled=ISNULL(@bOlapReportingEnabled,0)
	IF @bOlapReportingEnabled=1 -- Stock analysis reporting shifted to Olap server via Wow only
		RETURN

	IF @cRepId<>''
	BEGIN
		SELECT TOP 1 @cFilter=FILTER_CRITERIA FROM #wow_xpert_rep_mst (NOLOCK) WHERE rep_id=@cRepId

		IF ISNULL(@cFilter,'')=''
			SET @cFilter='isnull(sourcelocation.report_blocked,0) = 0'

		SET @cFilter=REPLACE(@cFilter,'ITEM_CODE_WO_BATCH','LEFT(sku_names.product_code,ISNULL(NULLIF(CHARINDEX (''@'',sku_names.product_code)-1,-1),LEN(sku_names.product_code )))')
		SET @cFilter=REPLACE(@cFilter,'POM01106.PO_DT BETWEEN','''2099-01-01''  NOT BETWEEN')		
	END
	ELSE
	IF @cFilterPara<>''
	BEGIN
		SET @cFilter=@cFilterPara
	END
	ELSE
	BEGIN
		SET @cFilter='1=1'
	END

	SET @dFromDtLastMonthEndDt=DATEADD(DAY, -DAY(@dFromDt), CAST(@dFromDt AS DATE))
	SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dToDt) + 1, 0))

	SET @cStep='20'
	

	--if @@spid=853
	--	select @dFromDtLastMonthEndDt dFromDtLastMonthEndDt
	SET @cPmtTableName=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dFromDtLastMonthEndDt,112)
	
	SET @cXnFilter=REPLACE(@cFilter,'sourcebin.BIN_ID  NOT IN (''999'')','1=1')

	SELECT @bOpsColFound=0,@bCbsColFound=0

	IF EXISTS (SELECT TOP 1 rep_id FROM wow_xpert_rep_det a (NOLOCK) JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON a.column_id=b.column_id
				where rep_id=@cRepId AND col_expr like '%pmt_cbs%')
		SET @bCbsColFound=1

	IF EXISTS (SELECT TOP 1 rep_id FROM wow_xpert_rep_det a (NOLOCK) JOIN wow_xpert_report_cols_expressions b (NOLOCK) ON a.column_id=b.column_id
				where rep_id=@cRepId AND col_expr like '%pmt_obs%')
		SET @bOpsColFound=1
	

	IF @bUpdateCbsOnly=1
		SET @bCbsColFound=1
	
	IF @bUpdateOpsXnsOnly=1 OR @bUpdateOpsOnly=1
		SELECT @bOpsColFound=1,@bCbsColFound=0

	SET @dToDtLastMonthEndDt=DATEADD(DAY, -DAY(@dToDt), CAST(@dToDt AS DATE))
	IF (@bOpsColFound=0 AND @bCbsColFound=1 AND @dToDt<>CONVERT(DATE,GETDATE()) AND @dToMonthEndDt<>@dToDt) OR @bCalledfromPlBs=1
		SET @bOpsColFound=1
	
	SET @cFilter='WHERE '+@cFilter
	

	IF @bOpsColFound=1 AND (@dFromDt-1)<>@dFromDtLastMonthEndDt AND @bUpdateOpsXnsOnly=0
	BEGIN
		SET @cCmd=N' INSERT INTO '+@cOpsPmtTableName+'(product_code,bin_id,dept_id,cbs_qty)
					 select a.product_code,a.bin_id,a.dept_id,sum(cbs_qty) cbs_qty From '+@cPmtTableName+' a (NOLOCK) '+
				  ' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
				  ' JOIN location sourceLocation (NOLOCK) ON sourceLocation.dept_id=a.dept_id
				    LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		            LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		            LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
				    JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
					LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
					Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
					Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
					Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
					Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
					LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
					LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
					LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
					LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
					LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
					JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id '+@cFilter+' GROUP BY a.product_code,a.bin_id,a.dept_id'
		PRINT @cCmd
	
		
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='30'
	
	CREATE TABLE #tmpXnsCbs (dept_id VARCHAR(4),product_code VARCHAR(50),bin_id VARCHAR(10),xn_qty NUMERIC(20,3),xn_type VARCHAR(20))

	
	IF @dFromDtLastMonthEndDt+1<>@dFromDt AND @bOpsColFound=1 AND @bCalledfromPlBs=0
	BEGIN
		
		PRINT 'Build Opening Stock'
		SET @cStep='40'
		

		SELECT @dFromDtPara=@dFromDtLastMonthEndDt+1,@dToDtPara=@dFromDt-1

		SELECT @cFromDtPara=CONVERT(VARCHAR,@dFromDtPara,112),@cToDtPara=CONVERT(VARCHAR,@dToDtPara,112)
		
		--if @@spid=553
		--begin
		--	select 'ops qty', sum(cbs_qty) cbsqty,sum(cbs_qty*pp) cbp from #pmtops a
		--	join sku_names b (nolock) on a.product_code=b.product_Code
		--	where BIN_ID <>'999' and sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1) 
		--			AND ISNULL(b.stock_na,0)=0

		--	select 'dates for building ops xns',@bUpdateOpsXnsOnly UpdateOpsXnsOnly,@bUpdateOpsOnly UpdateOpsOnly,
		--	@bUpdateCbsOnly UpdateCbsOnly, @cFromDtPara,@cToDtPara
		--end

		EXEC SPWOW_GETXNSDATA_OBSCBSCALC 
		@dFromDt=@cFromDtPara,
		@dToDt=@cToDtPara,
		@cFilter=@cXnFilter,
		@cErrormsg=@cErrormsg OUTPUT
		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		
		--if @@spid=553
		--	select 'check xntype wise xnqty', xn_type,sum(xn_qty) xnqty,sum(xn_qty*pp) xnvalue from #tmpXnsCbs a 
		--	join sku_names b (nolock) on a.product_code=b.product_Code
		--	where BIN_ID <>'999' and sku_item_type=1 AND isnull(b.sku_er_flag,0) IN  (0,1) 
		--			AND ISNULL(b.stock_na,0)=0 group by xn_type

		SET @cStep='50'
		SET @cCmd=N'update a SET cbs_qty=a.cbs_qty+b.xn_qty from '+@cOpsPmtTablename+' a 
		JOIN  (SELECT product_code,dept_id,bin_id,sum(xn_qty) xn_qty from #tmpXnsCbs WHERE bin_id<>''999'' GROUP BY product_code,dept_id,bin_id having sum(xn_qty)<>0 ) b 
		ON a.product_code=b.PRODUCT_CODE AND a.dept_id=b.DEPT_ID AND a.bin_id=b.BIN_ID'

		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='60'
		SET @cCmd=N'INSERT INTO '+@cOpsPmtTablename+' (product_code,dept_id,bin_id,cbs_qty)
		SELECT a.product_code,a.dept_id,a.bin_id,sum(a.xn_qty) xn_qty FROM #tmpXnsCbs a
		LEFT JOIN '+@cOpsPmtTablename+' b ON a.DEPT_ID=b.dept_id AND a.PRODUCT_CODE=b.product_code AND a.BIN_ID=b.bin_id
		WHERE b.product_code IS NULL AND  a.bin_id<>''999''
		GROUP BY a.product_code,a.dept_id,a.bin_id'

		EXEC SP_EXECUTESQL @cCmd
	END



	IF @dToDt<>CONVERT(DATE,GETDATE())  AND (@bCbsColFound=1 OR @bCalledfromPlBs=1) AND @dToDt<>@dToMonthEndDt
	BEGIN
		PRINT 'Build Closing Stock'
		SET @cStep='70'
	

		SET @cStep='80'
		IF @dToDtLastMonthEndDt=@dFromDtLastMonthEndDt AND @dFromDtLastMonthEndDt+1<>@dFromDt
		BEGIN
			SET @cCmd=N'INSERT INTO '+@cCbsPmtTableName+' (product_code,bin_id,dept_id,cbs_qty)
			select product_code,bin_id,dept_id,cbs_qty from '+@cOpsPmtTablename+'  WHERE bin_id<>''999'''
			EXEC SP_EXECUTESQL @cCmd
		END
		ELSE
		BEGIN
			SET @cStep='90'
			SET @cPmtTableName=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dToDtLastMonthEndDt,112)
			
			SET @cCmd=N'INSERT INTO '+@cCbsPmtTableName+' (product_code,bin_id,dept_id,cbs_qty)
			  select a.product_code,a.bin_id,a.dept_id,sum(cbs_qty) cbs_qty From '+@cPmtTableName+' a (NOLOCK) '+
			' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
			' JOIN  location sourceLocation (NOLOCK) ON sourceLocation.dept_id=a.dept_id
			  LEFT JOIN area  SourceLocation_area on SourceLocation.area_code=SourceLocation_area.area_code
		      LEFT JOIN city  SourceLocation_city on SourceLocation_city.city_code=SourceLocation_area.city_code
		      LEFT JOIN state  SourceLocation_state on SourceLocation_state.state_code=SourceLocation_city.state_code
			  JOIN loc_names (NOLOCK) ON loc_names.dept_id=sourceLocation.dept_id
			  LEFT JOIN lm01106 supplier_lm01106 on supplier_lm01106.ac_code=SKU_NAMES.ac_code
			  Left Outer  JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=sku_names.ac_code
			  Left Outer JOIN area  supplier_area on supplier_lmp01106.area_code=supplier_area.area_code
			  Left Outer  JOIN city  supplier_city on supplier_city.city_code=supplier_area.city_code
			  Left Outer  JOIN state  supplier_state on supplier_state.state_code=supplier_city.state_code
			  LEFT JOIN lm01106 oem_supplier_lm01106 on oem_supplier_lm01106.ac_code=sku_names.oem_ac_code
		      LEFT JOIN lmp01106 oem_supplier_lmp01106 on oem_supplier_lmp01106.ac_code=sku_names.oem_ac_code
			 LEFT JOIN area  oem_supplier_area on oem_supplier_lmp01106.area_code=oem_supplier_area.area_code
			 LEFT JOIN city  oem_supplier_city on oem_supplier_city.city_code=oem_supplier_area.city_code
			 LEFT JOIN state  oem_supplier_state on oem_supplier_state.state_code=oem_supplier_city.state_code
			  JOIN bin sourceBin (NOLOCK) ON sourceBin.bin_id=a.bin_id '+@cFilter+
			' GROUP BY a.product_code,a.bin_id,a.dept_id'
				
			SET @dFromDt=@dToDtLastMonthEndDt+1
			
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END

		
		TRUNCATE TABLE #tmpXnsCbs

		--select 'dates for building cbs xns', @dFromDt,@dToDt
		
		SET @cStep='95'
		
		SELECT @cFromDtPara=CONVERT(VARCHAR,@dFromDt,112),@cToDtPara=CONVERT(VARCHAR,@dToDt,112)
	    
		if @bCalledfromPlBs=1
			set @cFromDtPara=CONVERT(VARCHAR,@dFromDtLastMonthEndDt+1,112)
		
		EXEC SPWOW_GETXNSDATA_OBSCBSCALC 
		@dFromDt=@cFromDtPara,
		@dToDt=@cToDtPara,
		@cFilter=@cXnFilter,
		@cErrormsg=@cErrormsg OUTPUT
		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		--if @@spid=553
		--begin
		--	select 'ops qty', sum(cbs_qty) cbsqty,sum(cbs_qty*pp) cbp,@cCbsPmtTableName CbsPmtTableName from #pmtops a
		--	join sku_names b (nolock) on a.product_code=b.product_Code
		--	where BIN_ID <>'999' and sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1) 
		--			AND ISNULL(b.stock_na,0)=0

		--	select 'check xntype wise xnqty', xn_type,sum(xn_qty) xnqty,sum(xn_qty*pp) xnvalue from #tmpXnsCbs a 
		--	join sku_names b (nolock) on a.product_code=b.product_Code
		--	where BIN_ID <>'999' and sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1) 
		--			AND ISNULL(b.stock_na,0)=0  group by xn_type

		--	select 'dates for building cbs xns',@bUpdateOpsXnsOnly UpdateOpsXnsOnly,@bUpdateOpsOnly UpdateOpsOnly,
		--	@bUpdateCbsOnly UpdateCbsOnly, @cFromDtPara,@cToDtPara
		
		--end


		SET @cStep='100'
		SET @cCmd=N'update a SET cbs_qty=a.cbs_qty+b.xn_qty from '+@cCbsPmtTableName+' a JOIN 
		(SELECT product_code,dept_id,bin_id,sum(xn_qty) xn_qty from #tmpXnsCbs WHERE bin_id<>''999'' GROUP BY product_code,dept_id,bin_id  having sum(xn_qty)<>0 )  b 
		ON a.product_code=b.PRODUCT_CODE AND a.dept_id=b.DEPT_ID AND a.bin_id=b.BIN_ID'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='105'
		SET @cCmd=N'INSERT INTO '+@cCbsPmtTableName+' (product_code,dept_id,bin_id,cbs_qty)
		SELECT a.product_code,a.dept_id,a.bin_id,sum(a.xn_qty) xn_qty FROM #tmpXnsCbs a
		LEFT JOIN '+@cCbsPmtTableName+' b ON a.DEPT_ID=b.dept_id AND a.PRODUCT_CODE=b.product_code AND a.BIN_ID=b.bin_id
		WHERE b.product_code IS NULL AND a.bin_id<>''999''
		GROUP BY a.product_code,a.dept_id,a.bin_id'

		print @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END

	GOTO END_PROC
END TRY
BEGIN CATCH

	SET @cErrormsg='Error in Procedure SPWOW_GENXPERT_PMTSTK_ONTHEFLY at Step#'+@cStep+' '+ERROR_MESSAGE()
	print 'Enter catch of SPWOW_GENXPERT_PMTSTK_ONTHEFLY'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:
	

END