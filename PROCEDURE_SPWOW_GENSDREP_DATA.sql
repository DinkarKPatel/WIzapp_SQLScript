CREATE PROCEDURE SPWOW_GENSDREP_DATA
@cRepId varchar(10),
@dFromdt datetime,
@dToDt datetime,
@bEstimateModeEnabled BIT=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cMstColNames VARCHAR(2000),@cCalcColNames VARCHAR(3500),@cInsMstCols VARCHAR(MAX),
	@cInsCalcCols VARCHAR(MAX),@cPmtObs VARCHAR(100),@cPmtCbs VARCHAR(100),@cGitTable VARCHAR(200),@cLayoutMstCols VARCHAR(2000),
	@cErrormsg VARCHAR(MAX),@cStep VARCHAR(5),@cRepTableName VARCHAR(50),@nDays INT,@cCalcColNamesAgg VARCHAR(4000),
	@cAgeColNames VARCHAR(1000),@cDerivedCols VARCHAR(1000),@cColName VARCHAR(100),@cLayoutMstColName VARCHAR(100),
	@cInsMstColName VARCHAR(100),@cRollupTOtalCol VARCHAR(100),@c2ndMstCol varchar(100),@cNrvColumn VARCHAR(500),
	@cTaxableValCol VARCHAR(500),@cFilter VARCHAR(MAX),@cSlsLayoutCols VARCHAR(500),@cSlsInsCols VARCHAR(500),
	@bPurAgeingColFOund BIT,@bShelfAgeingColFOund BIT,@bSlsAgeingColFOund BIT,@cAgeColNamesAgg VARCHAR(500),
	@cFInalCalcColNamesAgg VARCHAR(1000),@cRestDerivedCols VARCHAR(1000),@cGroupingCols VARCHAR(1000),@cFinalLayoutMstCols VARCHAR(1000)

BEGIN TRY
	SET @cStep='10'

	SELECT * INTO #wow_sdrep_xn_mst from wow_sdrep_xn_mst WHERE repId=@cRepId
	SELECT b.devColName, b.colMode, b.orgcolName ,Convert(varchar(200),'') colexpr,convert(bit,0) derived_col,convert(varchar(20),'') datatype,
	a.* INTO #wow_sdrep_xn_det from wow_sdrep_xn_det a (NOLOCK)
	JOIN wow_sdrep_cols b (NOLOCK) ON a.columnId=b.columnId
	WHERE repId=@cRepId


	update #wow_sdrep_xn_det set datatype=(case when colmode=1 then 'String' else 'Numeric' end)

	;with cteRepDet 
	as
	(select *,ROW_NUMBER() over (order by colmode,colOrder) rno from  #wow_sdrep_xn_det)

	update cteRepDet set colOrder=rno

	SET @cStep='12'
	SELECT @cMstColNames=COALESCE(@cMstColNames+',','')+'CONVERT(VARCHAR(2000),'''')'+
	' as '+devColName FROM  #wow_sdrep_xn_det a
	WHERE colmode=1

	SELECT @cLayoutMstCols=COALESCE(@cLayoutMstCols+',','')+'['+a.devColName+']',
	@cInsMstCols=COALESCE(@cInsMstCols+',','')+a.orgcolName
	FROM #wow_sdrep_xn_det a (NOLOCK)
	WHERE colmode=1
   	
	SET @cAgeColNames=''
	IF EXISTS (SELECT TOP 1 colheader from #wow_sdrep_xn_det where orgcolName in ('whageing','shelfageing','slsageing'))
	BEGIN
		
		IF EXISTS (SELECT TOP 1 colheader from #wow_sdrep_xn_det where orgcolName='slsageing')
			SELECT @bSlsAgeingColFOund	=1,@cAgeColNames=',sls_ageing_1,sls_ageing_2,sls_ageing_3,sls_ageing_4'

		IF EXISTS (SELECT TOP 1 colheader from #wow_sdrep_xn_det where orgcolName='whageing')
		BEGIN
			SET @bPurAgeingColFOund	=1
			SET @cAgeColNames=@cAgeColNames+',wh_ageing_1,wh_ageing_2,wh_ageing_3,wh_ageing_4'
			INSERT INTO #wow_sdrep_xn_det (repid,columnId,orgcolName,datatype,colMode,Rowid,devColName)
			SELECT @cRepId,'','Purchase_ageing_days','Numeric',1,'',''
		END

		IF EXISTS (SELECT TOP 1 colheader from #wow_sdrep_xn_det where orgcolName='shelfageing')
		BEGIN
			SET @bShelfAgeingColFOund	=1
			SET @cAgeColNames=@cAgeColNames+',shelf_ageing_1,shelf_ageing_2,shelf_ageing_3,shelf_ageing_4'
			INSERT INTO #wow_sdrep_xn_det (repid,columnId,orgcolName,datatype,colMode,Rowid,devColName)
			SELECT @cRepId,'','shelf_ageing_days','Numeric',1,'',''
		END

		SET @cMstColNames=@cMstColNames+(CASE WHEN @bPurAgeingColFOund=1 THEN ',CONVERT(NUMERIC(10,2),0) AS purchase_ageing_days'  ELSE '' END)+
		(CASE WHEN @bShelfAgeingColFOund=1 THEN ',CONVERT(NUMERIC(10,2),0) AS shelf_ageing_days' ELSE '' END)
	END

	SELECT TOP 1 @cFilter=filterCriteria FROM #wow_sdrep_xn_mst 

	SET @cFilter=isnull(@cFilter,'')+(CASE WHEN ISNULL(@cFilter,'')<>'' THEN ' AND ' ELSE '' END)+'ISNULL(sku_item_type,1) IN (0,1)'

	SET @cStep='15'
	SELECT @cNrvColumn=(CASE WHEN @bEstimateModeEnabled=0 THEN 'rfnet' ELSE 
	'(CASE WHEN ISNULL(old_net,0)<>0 THEN old_net-old_cmm_discount_amount+(CASE WHEN tax_method=2 THEN
	  OLD_igst_amount+OLD_cgst_amount+OLD_sgst_amount ELSE 0 END) ELSE net-cmm_discount_amount END)' END),
	@cTaxableValCol=(CASE WHEN @bEstimateModeEnabled=0 THEN 'xn_value_without_gst' ELSE 
	'(CASE WHEN ISNULL(old_xn_value_without_gst,0)<>0 THEN old_xn_value_without_gst ELSE xn_value_without_gst END)' END)

	--SELECT @cInsMstCols,@cLayoutMstCols
	SET @cStep='20'
	UPDATE #wow_sdrep_xn_det SET colExpr=(CASE WHEN orgcolName='sale_ageing_days' THEN
	'AVG(ISNULL(selling_days,0))' WHEN orgColName='QtySold' THEN 'SUM(quantity)'
	WHEN orgColName='SaleTaxable' THEN 'SUM('+@cTaxableValCol+')'
	WHEN orgColName='NRV' THEN 'SUM('+@cNrvColumn+')'
	WHEN orgColName='COGS' THEN 'SUM(sku_names.pp*quantity)' 
	WHEN orgColName='profit' THEN 'SUM(xn_value_without_gst-(sku_names.pp*quantity))'
	END)

	UPDATE #wow_sdrep_xn_det SET derived_col=1 WHERE orgcolName IN ('ASPD','APPD','[Sell thru%]','[Profit % (From MRP)]','[Days of Stock]')
	 
	SET @cStep='40'
	SELECT @cInsCalcCols=COALESCE(@cInsCalcCols+',','')+colHeader FROM #wow_sdrep_xn_det where colMode=2

	SELECT @cCalcColNames=COALESCE(@cCalcColNames+',','')+'CONVERT(NUMERIC(20,2),0)'+
	' as '+devColName FROM #wow_sdrep_xn_det where colMode=2


	--select 'check #wow_sdrep_xn_det',* from #wow_sdrep_xn_det

	SET @cRepTableName='##tSDReport_'+replace(left(convert(varchar(38),newid()),10),'-','_')

	set @cRestDerivedCols=''
	IF EXISTS (SELECT TOP 1 * FROM #wow_sdrep_xn_det WHERE ISNULL(derived_col,0)=1)
	BEGIN
		SELECT @cRestDerivedCols=COALESCE(@cRestDerivedCols+',','')+'CONVERT(NUMERIC(10,2),0) AS '+colHeader FROM
		wow_sdrep_cols a (NOLOCK) LEFT JOIN #wow_sdrep_xn_det b ON a.columnId=b.columnId
		WHERE a.displayColName in ('ASPD','APPD','[Sell thru%]','[Profit % (From MRP)]','[Days of Stock]')
		and b.columnId IS NULL

		IF @cRestDerivedCols<>''
			SET @cRestDerivedCols=@cRestDerivedCols+','

	END

	SET @cStep='50'
	SET @cCmd=N'SELECT '+@cMstColNames+','+@cCalcColNames+@cRestDerivedCols+' INTO '+@cRepTableName+' from pmt01106 WHERE 1=2'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF EXISTS (SELECT TOP 1 orgColname FROM #wow_sdrep_xn_det WHERE orgcolName='OpeningStock')
	BEGIN
		SET @cStep='60'
		PRINT 'Populating Opening Stock data'
		SET @cPmtObs=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dFromDt-1,112)

		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',OpeningStock)
					SELECT '+@cInsMstCols+',SUM(cbs_qty) FROM '+@cPmtObs+' a (NOLOCK)
					JOIN location (NOLOCK) ON location.dept_id=a.dept_id
					JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code WHERE '+@cFilter+' GROUP BY '+@cInsMstCols
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
	

	IF EXISTS (SELECT TOP 1 orgColname FROM #wow_sdrep_xn_det WHERE orgcolName IN ('ClosingStock','purchase_ageing_days','shelf_ageing_days'))
	BEGIN
		SET @cStep='70'
		PRINT 'Populating Closing Stock data'
		SET @cPmtCbs=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dToDt,112)

		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',ClosingStock)
					SELECT '+@cInsMstCols+',SUM(cbs_qty) FROM '+@cPmtCbs+' a (NOLOCK)
					JOIN location (NOLOCK) ON location.dept_id=a.dept_id
					JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code WHERE '+@cFilter+
					' GROUP BY '+@cInsMstCols
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	IF EXISTS (SELECT TOP 1 orgColname FROM #wow_sdrep_xn_det WHERE orgcolName IN ('InwardsQty'))
	BEGIN
		SET @cStep='80'
		PRINT 'Populating Purchase data'
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',InwardsQty)
					SELECT '+@cInsMstCols+',SUM(quantity) FROM pid01106  (NOLOCK)
					JOIN pim01106 (NOLOCK) ON pim01106.mrr_id=pid01106.mrr_id 
					JOIN location (NOLOCK) ON location.dept_id=PIM01106.dept_id 
					LEFT JOIN pim01106 pim_conv (NOLOCK) ON pim_conv.mrr_id=pim01106.ref_converted_mrntobill_mrrid 
					JOIN lmp01106 supplier_lmp01106 on supplier_lmp01106.ac_code=pim01106.ac_code 
					join SKU_NAMES (NOLOCK) ON sku_names.product_code=pid01106.product_code '+
					' WHERE pim01106.receipt_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+'''
					AND pim01106.inv_mode=1 AND pim01106.cancelled=0 AND pid01106.product_code<>''0000000000''
				
					AND pim_conv.mrr_id IS NULL '+@cFilter+'  GROUP BY '+@cInsMstCols
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='90'
		PRINT 'Populating CHI-1 data'
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',InwardsQty)
		SELECT '+@cInsMstCols+',SUM(quantity) FROM ind01106  (NOLOCK)
		JOIN  PIM01106 PIM01106 (NOLOCK) ON PIM01106.inv_id=ind01106.inv_id
		JOIN location (NOLOCK) ON location.dept_id=pim01106.dept_id
		join SKU_NAMES (NOLOCK) ON sku_names.product_code=ind01106.product_code '+
		' WHERE pim01106.receipt_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+'''
		 AND pim01106.inv_mode=2 AND pim01106.cancelled=0 '+@cFilter+' GROUP BY '+@cInsMstCols
    
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	
		SET @cStep='100'
		PRINT 'Populating CHI-2 data'
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',InwardsQty)
		SELECT '+@cInsMstCols+',SUM(quantity) FROM cnd01106  (NOLOCK)
		JOIN CNM01106 (NOLOCK) ON CNM01106.CN_ID=CND01106.CN_ID 
		JOIN location (NOLOCK) ON location.dept_id=cnm01106.location_code/*LEFT(cnm01106.cn_id,2)*//*Rohit 05-11-2024*/
		join SKU_NAMES (NOLOCK) ON sku_names.product_code=cnd01106.product_code
		WHERE cnm01106.receipt_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+''' 
		AND cnm01106.mode=2 AND cnm01106.cancelled=0 '+@cFilter+' GROUP BY '+@cInsMstCols

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END

	IF EXISTS (SELECT TOP 1 orgColname FROM #wow_sdrep_xn_det WHERE orgcolName IN ('OutwardsQty'))
	BEGIN
		SET @cStep='110'
		PRINT 'Populating PRT+CHO data'
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',[PRT+CHO])
					SELECT '+@cInsMstCols+',SUM(quantity) FROM rmd01106  (NOLOCK)
					JOIN rmm01106 (NOLOCK) ON rmm01106.rm_id=rmd01106.rm_id
					JOIN location (NOLOCK) ON location.dept_id=rmm01106.location_code/*LEFT(rmm01106.rm_id,2)*//*Rohit 05-11-2024*/
					join SKU_NAMES (NOLOCK) ON sku_names.product_code=rmd01106.product_code '+

					' WHERE rmm01106.rm_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+'''
					AND cancelled=0 '+@cFilter+' GROUP BY '+@cInsMstCols

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='120'
		PRINT 'Populating WSLCHO data'
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',[PRT+CHO])
					SELECT '+@cInsMstCols+',SUM(quantity) FROM ind01106  (NOLOCK)
					JOIN inm01106 (NOLOCK) ON inm01106.inv_id=ind01106.inv_id
					JOIN location (NOLOCK) ON location.dept_id=inm01106.location_code/*LEFT(inm01106.inv_id,2)*//*Rohit 05-11-2024*/
					join SKU_NAMES (NOLOCK) ON sku_names.product_code=ind01106.product_code '+
					' WHERE inm01106.inv_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+'''
					AND inv_mode=2 AND cancelled=0 '+@cFilter+' GROUP BY '+@cInsMstCols

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END

	IF EXISTS (SELECT TOP 1 orgColname FROM #wow_sdrep_xn_det WHERE orgcolName IN ('GitQty'))
	BEGIN
		SET @cStep='130'
		PRINT 'Populating GIT data'
		SET @cGitTable=db_name()+'_pmt.dbo.gitlocs_'+convert(varchar,@dToDt,112)
		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+',GitQty)
		SELECT '+@cInsMstCols+',SUM(git_qty) FROM '+@cGitTable+' a
		JOIN location (NOLOCK) ON location.dept_id=a.dept_id
		join SKU_NAMES (NOLOCK) ON sku_names.product_code=a.product_code '+@cFilter+' GROUP BY '+@cInsMstCols

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='134'
	SELECT @cSlsLayoutCols=COALESCE(@cSlsLayoutCols+',','')+devColName,
	@cSlsInsCols=COALESCE(@cSlsInsCols+',','')+colExpr
	FROM #wow_sdrep_xn_det WHERE orgcolName IN('sale_ageing_days','QtySold','NRV','SaleTaxable','COGS','profit')

	IF ISNULL(@cSlsLayoutCols,'')<>''
	BEGIN
		SET @cStep='140'
		PRINT 'Populating Sales data'


		SET @cCmd=N'INSERT INTO '+@cRepTableName+' ('+@cLayoutMstCols+','+@cSlsLayoutCols+')
		SELECT '+@cInsMstCols+','+@cSlsInsCols+
		' FROM cmd01106 (NOLOCK) JOIN cmm01106 (NOLOCK) ON cmm01106.cm_id=cmd01106.cm_id
		JOIN location (NOLOCK) ON location.dept_id=cmm01106.location_code/*LEFT(cmm01106.cm_id,2)*//*Rohit 05-11-2024*/
		join SKU_NAMES (NOLOCK) ON sku_names.product_code=cmd01106.product_code '+
		' WHERE cmm01106.cm_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+''' AND '+@cFilter+
		' GROUP BY '+@cInsMstCols
	
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @nDays=DATEDIFF(dd,@dFromdt,@dtoDt)+1
	SET @cStep='150'
	
	SELECT @cCalcColNamesAgg=COALESCE(@cCalcColNamesAgg+',','')+'SUM(ISNULL('+orgcolName+',0)) AS '+orgcolName
	FROM #wow_sdrep_xn_det WHERE colmode=2



	 SET @cAgeColNamesAgg=(CASE WHEN @bPurAgeingColFOund=1 THEN
	 ',SUM(CASE WHEN ISNULL(Purchase_ageing_days,0) BETWEEN 0 AND 30 
	 THEN closingStock else 0 end) wh_ageing_1,SUM(CASE WHEN ISNULL(Purchase_ageing_days,0) BETWEEN 31 AND 60 
	 THEN closingStock else 0 end) wh_ageing_2,SUM(CASE WHEN ISNULL(Purchase_ageing_days,0) BETWEEN 61 AND 90 
	 THEN closingStock else 0 end) wh_ageing_3,SUM(CASE WHEN ISNULL(Purchase_ageing_days,0)>90
	 THEN closingStock else 0 end) wh_ageing_4' ELSE '' END)+(CASE WHEN @bShelfAgeingColFOund=1 THEN
	 ',SUM(CASE WHEN ISNULL(shelf_ageing_days,0) BETWEEN 0 AND 30 
	 THEN closingStock else 0 end) shelf_ageing_1,SUM(CASE WHEN ISNULL(shelf_ageing_days,0) BETWEEN 31 AND 60 
	 THEN closingStock else 0 end) shelf_ageing_2,SUM(CASE WHEN ISNULL(shelf_ageing_days,0) BETWEEN 61 AND 90 
	 THEN closingStock else 0 end) shelf_ageing_3,SUM(CASE WHEN ISNULL(shelf_ageing_days,0)>90
	 THEN closingStock else 0 end) shelf_ageing_4' ELSE '' END)+(CASE WHEN @bSlsAgeingColFOund=1 THEN
	 ',SUM(CASE WHEN ISNULL(sale_ageing_days,0) BETWEEN 0 AND 30 
	 THEN ISNULL([qty sold],0) else 0 end) sale_ageing_1,SUM(CASE WHEN ISNULL(sale_ageing_days,0) BETWEEN 31 AND 60 
	 THEN [qty sold] else 0 end) sale_ageing_2,SUM(CASE WHEN ISNULL(sale_ageing_days,0) BETWEEN 61 AND 90 
	 THEN [qty sold] else 0 end) sale_ageing_3,SUM(CASE WHEN ISNULL(sale_ageing_days,0)>90
	 THEN [qty sold] else 0 end) sale_ageing_4' ELSE '' END) 

	SET @cStep='152'
	--select 'chk age columns', * FROM #wow_sdrep_xn_det WHERE age_column=1
	--SELECT @cAgeColNames
	SET @cCalcColNames=null

	SELECT @cCalcColNames=COALESCE(@cCalcColNames+',','')+devColName
	FROM #wow_sdrep_xn_det WHERE colmode=2


	SET @cStep='155'
	seLECT @cCalcColNamesAgg=null,@cLayoutMstCols=null
	SELECT @cCalcColNamesAgg=COALESCE(@cCalcColNamesAgg+',','')+'SUM(ISNULL('+devColName+',0)) AS ['+devColName+']'
	FROM #wow_sdrep_xn_det WHERE colmode=2

	SELECT @cLayoutMstCols=COALESCE(@cLayoutMstCols+',','')+devColname
	FROM #wow_sdrep_xn_det WHERE colmode=1 and colHeader is not null
	
	SELECT @cGroupingCols=COALESCE(@cGroupingCols+',','')+devColname
	FROM #wow_sdrep_xn_det WHERE colmode=1 and colHeader is not null

	--select 'check FROM #wow_sdrep_xn_det',* FROM #wow_sdrep_xn_det

	SELECT TOP 1 @cRollupTOtalCol='ROLLUP(['+devColName+'])' FROM #wow_sdrep_xn_det WHERE colorder=1 
	SELECT TOP 1 @c2ndMstCol=devColName FROM #wow_sdrep_xn_det WHERE colorder=2 and colmode=1
	IF @c2ndMstCol IS NULL
		SELECT TOP 1 @c2ndMstCol=devColName,@cRollupTOtalCol='()' FROM #wow_sdrep_xn_det WHERE colorder=1 

	--select 'check ageingcols', @cAgeColNamesAgg,@cLayoutMstCols,@cCalcColNames,@cAgeColNames,@cCalcColNamesAgg

	--select @cLayoutMstCols,@cCalcColNamesAgg,@cRepTableName,@c2ndMstCol,@cRepTableName,@cRollupTOtalCol
	SET @cStep='158'
	SET @cCmd=N'SELECT (CASE WHEN ['+@c2ndMstCol+'] IS NULL THEN 1 ELSE 0 END) AS total_mode,
						IDENTITY(INT,1,1) org_rowno, * INTO '+@cRepTableName+'_final FROM  
	(
						select *
						FROM
						(SELECT '+@cLayoutMstCols+@cAgeColNamesAgg+','+@cCalcColNamesAgg+
						' FROM '+@cRepTableName+' GROUP BY GROUPING SETS(('+@cGroupingCols+'),'+@cRollupTOtalCol+')
						) a 
						) b '

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cRepTableName=@cRepTableName+'_final'

	IF EXISTS (SELECT TOP 1 * FROM #wow_sdrep_xn_det WHERE ISNULL(derived_col,0)=1)
	BEGIN
		SET @cStep='160'
		SET @cCmd=N'UPDATE '+@cRepTableName+' SET ASPD=CONVERT(NUMERIC(10,2),[NRV]/'+str(@nDays)+'),'+
					'APPD=CONVERT(NUMERIC(10,2),profit/'+str(@nDays)+'),
					[Sell thru%]=(CASE WHEN ISNULL(([qtysold]+[ClosingStock]),0)<>0 THEN CONVERT(NUMERIC(10,2),([qtySold]/([qtySold]+[closingStock]))*100.00)
					ELSE 0 END),
					[Profit % (From MRP)]=(CASE WHEN ISNULL([Sale Taxable],0)<>0 THEN CONVERT(NUMERIC(10,2),(profit/[Sale Taxable])*100)
					ELSE 0 END),
					[Days of Stock]=CONVERT(NUMERIC(10,0),[closingStock]/([qtySold]/'+str(@nDays)+'))
					WHERE [qtySold]<>0'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cCmd=N'UPDATE '+@cRepTableName+' SET [Days of Stock]=-1 WHERE [qtySold]=0'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='162'

	SET @cCalcColNames=null

	SELECT @cFInalCalcColNamesAgg=COALESCE(@cFInalCalcColNamesAgg+',','')+devcolName+' as ['+colHeader+']' FROM #wow_sdrep_xn_det
	WHERE colmode=2  and orgcolName not like '%ageing%'

	SELECT @cFinalLayoutMstCols=COALESCE(@cFinalLayoutMstCols+',','')+devColname+' as ['+colHeader+']'
	FROM #wow_sdrep_xn_det WHERE colmode=1 and colHeader is not null and orgcolName not like '%ageing%'

	SET @cStep='165'

	--select @cFinalLayoutMstCols,@cFInalCalcColNamesAgg,@cAgeColNames

	SET @cCmd=N'SELECT total_mode,'+@cFinalLayoutMstCols+@cAgeColNames+','+@cFInalCalcColNamesAgg+
	            ' FROM '+@cRepTableName+'	ORDER BY org_rowno'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	GOTO END_PROC

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_GENSDREP_DATA at Step#'+@cStep+' '+error_message()
	GOTO END_PROC 
END CATCH

END_PROC:

IF ISNULL(@cErrormsg,'')<>''
	SELECT @cErrormsg errmsg
END
