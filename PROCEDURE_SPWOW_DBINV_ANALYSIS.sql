CREATE PROCEDURE SPWOW_DBINV_ANALYSIS
@dFromDt DATETIME,
@dToDt DATETIME,
@dCompareFromDt DATETIME='',
@dCompareToDt DATETIME='',
@cMasterColsHeader varchar(max),
@cMasterColsExpr varchar(max),
@cGroupColsExpr  varchar(max),
@cAgeingSettingName VARCHAR(100)='ageing setting 1',
@cSupplierAcCodes VARCHAR(500)='',
@cPriceCategoryGrpCode VARCHAR(100)='',
@bRetPPCategories bit=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cDbTableName VARCHAR(200),@cPmtTableName VARCHAR(200),@cCbsColName VARCHAR(30),@dToMonthEndDt DATETIME,@cWc VARCHAR(200),
	@cWcCompare VARCHAR(200),@cWcLocWise VARCHAR(200),	@cWcCompareLocWise VARCHAR(200),@cPmtTableNameCompare VARCHAR(200),@cCbsColNameCompare VARCHAR(200),
	@nMaxSrno int,@nSrno INT,@nPrevDays INT,@cErrormsg VARCHAR(MAX),@cPriceCatgJoin varchar(200)


	select ageingdays,row_number() over (order by ageingdays) srno into #tmpAgeDays from wowdb_ageingdays (NOLOCK) 
	WHERE groupName=@cAgeingSettingName

	select @nMaxSrno=max(srno) from #tmpAgeDays

	CREATE TABLE #tmpAgeSlabs (fromDays INT,toDays INT,slabName VARCHAR(100),srno int)

	INSERT INTO #tmpAgeSlabs (fromDays,toDays,slabName,srno)
	SELECT 0,ageingDays ,'<='+LTRIM(RTRIM(str(ageingDays))),srno-1 from #tmpAgeDays WHERE SRNO=1
	union all
	SELECT ageingdays+1,999999999,'>'+LTRIM(RTRIM(str(ageingDays))),srno+1 from #tmpAgeDays WHERE SRNO=@nMaxSrno


	SELECT @nPrevDays=ageingdays from #tmpAgeDays where srno=1
	set @nSrno=2
	while @nSrno<=@nMaxSrno
	BEGIN

		INSERT INTO #tmpAgeSlabs (fromDays,toDays,slabName,srno)
		select @nPrevDays+1,ageingDays,ltrim(rtrim(str(@nPrevDays+1)))+'-'+ltrim(rtrim(str(ageingDays))),srno from #tmpAgeDays 
		where srno=@nSrno

		select @nPrevDays=ageingDays from #tmpAgeDays where srno=@nSrno
		
		set @nSrno=@nSrno+1
	END
	
	--drop table tmpAgeSlabs
	
	
	--select 'check #tmpAgeDays',* from #tmpAgeDays
	DECLARE @cSupplierFilter varchar(500)
	SET @cSupplierFilter=(CASE WHEN @cSupplierAcCodes<>'' THEN ' sku_names.ac_code in ('+@cSupplierAcCodes+')' ELSE '' END)
	SET @cWc=' AND ISNULL(Sku_Names.Sku_Er_Flag,0) IN (0 , 1 )   AND  ISNULL(SKU_NAMES.sku_item_type,1) IN (0,1) '+
	(CASE WHEN @cSupplierFilter<>'' then ' and '+@cSupplierFilter else '' end)

	SET @cWcLocWise=@cWc

	--SELECT @cMasterColsHeader=cMasterColsHeader,@cMasterColsExpr=cMasterColsExpr,@cGroupColsExpr=cGroupColsExpr FROM #tempHeaders
	
	SET @cPriceCatgJoin=''

	if @bRetPPCategories=1
		SET @cPriceCatgJoin= N' JOIN #tmpPriceCatg p ON sku_names.pp between p.fromPp AND p.toPp '


	SET @cCmd=N'SELECT '+@cMasterColsExpr+',avg(selling_days) avgSaleAgeing,s.slabName slsAgeingSLab,s.srno ageingOrder_sale,SUM(quantity) saleQty,
	 SUM(rfnet) nrv,SUM(xn_value_without_gst) slsTaxable,'+
  	 N'convert(numeric(20,2),SUM(quantity*pp)) cogs,sum(WeightedQtyBillCount) billCount'+
	 N' FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.cm_id JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	 N' JOIN location  (NOLOCK) ON location.dept_id=B.location_code/*LEFT(b.cm_id,2)*//*Rohit 05-11-2024*/ JOIN area (NOLOCK) ON area.area_code=location.area_code '+
	 N' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
	 N' JOIN #tmpAgeSlabs s ON ISNULL(a.selling_days,0) between S.fromdays AND s.todays '+@cPriceCatgJoin+
	 N' WHERE cm_dt between '''+CONVERT(VARCHAR,@dFromDt,112)+''''+
	 N' AND '''+CONVERT(VARCHAR,@dToDt,112)+''' AND cancelled=0 '+@cWc+' GROUP BY '+@cGroupColsExpr+',s.slabName,s.srno'

	

	--select @cCmd
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'SELECT '+@cMasterColsExpr+',avg(wsl_selling_days) avgSaleAgeing,s.slabName slsAgeingSLab,s.srno ageingOrder_sale,SUM(quantity) saleQty,SUM(rfnet) nrv,'+
  	 N' SUM(xn_value_without_gst) slsTaxable,convert(numeric(20,2),SUM(quantity*pp)) cogs,sum(wsl_WeightedQtyBillCount) billCount'+
	 N' FROM ind01106 a (NOLOCK) JOIN inm01106 b (NOLOCK) ON b.inv_id=a.inv_id JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	 N' JOIN location  (NOLOCK) ON location.dept_id=B.location_code/*LEFT(b.inv_id,2)*//*Rohit 05-11-2024*/ JOIN area (NOLOCK) ON area.area_code=location.area_code '+
	 N' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
	 N' JOIN #tmpAgeSlabs s ON ISNULL(a.wsl_selling_days,1) between S.fromdays AND s.todays '+@cPriceCatgJoin+
	 N' WHERE inv_dt between '''+CONVERT(VARCHAR,@dFromDt,112)+''' AND '''+CONVERT(VARCHAR,@dToDt,112)+''' AND inv_mode=1 '+
	 N' AND cancelled=0 '+@cWc+' GROUP BY '+@cGroupColsExpr+',s.slabName,s.srno'

	
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cCMd=N'SELECT '+@cMasterColsExpr+', s.slabname slsAgeingSLab,s.srno ageingOrder_sale, avg(selling_days)  avgSaleAgeing_compare,convert(numeric(10,0),0) avgSaleAgeing_variance,convert(numeric(10,0),0) avgSaleAgeing_variancepct,'+
	 N'SUM(quantity) saleQty_compare,convert(numeric(20,2),0) saleQty_variance,convert(numeric(20,2),0) saleQty_variancepct,'+
	 N'SUM(xn_value_without_gst) slsTaxable_compare,SUM(rfnet) nrv_compare,convert(numeric(20,2),0) nrv_variance,convert(numeric(20,2),0) nrv_variancepct,convert(numeric(20,2),SUM(quantity*pp)) cogs_compare,'+
	 N'convert(numeric(20,2),0) cogs_variance,convert(numeric(20,2),0) cogs_variancepct,sum(WeightedQtyBillCount) billCount_compare,'+
	 N'convert(numeric(20,2),0) billCount_variance,convert(numeric(20,2),0) billCount_variancepct FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.cm_id JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	 N' JOIN location  (NOLOCK) ON location.dept_id=B.location_code/*LEFT(b.cm_id,2)*//*Rohit 05-11-2024*/ JOIN area (NOLOCK) ON area.area_code=location.area_code '+
	 N' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
	  N' JOIN #tmpAgeSlabs s ON ISNULL(a.selling_days,0) between S.fromdays AND s.todays '+@cPriceCatgJoin+
	 N' WHERE '+(CASE WHEN @dCompareFromDt='' THEN '1=2' ELSE 'cm_dt between '''+CONVERT(VARCHAR,@dCompareFromDt,112)+''''+
	 N' AND '''+CONVERT(VARCHAR,@dCompareToDt,112)+''' AND cancelled=0 '+@cWc END)+' GROUP BY '+@cGroupColsExpr+',s.slabname,s.srno'
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cCMd=N'SELECT '+@cMasterColsExpr+', s.slabname slsAgeingSLab,s.srno ageingOrder_sale, avg(wsl_selling_days)  avgSaleAgeing_compare,'+
	 N'convert(numeric(10,0),0) avgSaleAgeing_variance,convert(numeric(10,0),0) avgSaleAgeing_variancepct,'+
	 N'SUM(quantity) saleQty_compare,convert(numeric(20,2),0) saleQty_variance,convert(numeric(20,2),0) saleQty_variancepct,'+
	 N' SUM(xn_value_without_gst) slsTaxable_compare,SUM(rfnet) nrv_compare,convert(numeric(20,2),0) nrv_variance,convert(numeric(20,2),0) nrv_variancepct,convert(numeric(20,2),SUM(quantity*pp)) cogs_compare,'+
	 N'convert(numeric(20,2),0) cogs_variance,convert(numeric(20,2),0) cogs_variancepct,sum(wsl_WeightedQtyBillCount) billCount_compare,'+
	 N'convert(numeric(20,2),0) billCount_variance,convert(numeric(20,2),0) billCount_variancepct FROM ind01106 a (NOLOCK) '+
	 N' JOIN inm01106 b (NOLOCK) ON b.inv_id=a.inv_id JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	 N' JOIN location  (NOLOCK) ON location.dept_id=B.location_code/*LEFT(b.inv_id,2)*//*Rohit 05-11-2024*/ JOIN area (NOLOCK) ON area.area_code=location.area_code '+
	 N' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
	  N' JOIN #tmpAgeSlabs s ON ISNULL(a.wsl_selling_days,0) between S.fromdays AND s.todays '+@cPriceCatgJoin+
	 N' WHERE '+(CASE WHEN @dCompareFromDt='' THEN '1=2' ELSE 'inv_dt between '''+CONVERT(VARCHAR,@dCompareFromDt,112)+''''+
	 N' AND '''+CONVERT(VARCHAR,@dCompareToDt,112)+''' AND inv_mode=1 AND cancelled=0 '+@cWc END)+' GROUP BY '+@cGroupColsExpr+',s.slabname,s.srno'
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	

	SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dToDt) + 1, 0))

	IF @dToDt=CONVERT(DATE,GETDATE())
		SELECT @cPmtTableName='pmt01106',@cCbsColName='quantity_in_stock'
	ELSE
		SELECT @cPmtTableName=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dToMonthEndDt,112),@cCbsColName='cbs_qty'

	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty,convert(numeric(10,0),0) purchase_ageing_days,convert(numeric(10,0),0) shelf_ageing_days into #pmtops from pmt01106 (NOLOCK) where 1=2
	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty,convert(numeric(10,0),0) purchase_ageing_days,convert(numeric(10,0),0) shelf_ageing_days into #pmtcbs from pmt01106 (NOLOCK) where 1=2

	IF @dToDt<>CONVERT(DATE,GETDATE()) AND @dToDt<>@dToMonthEndDt
	BEGIN
		
		print 'Enter getting stock from xns-1'
		exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY 
		@dFromDt=@dFromDt,
		@dToDt=@dToDt,
		@bUpdateCbsOnly=1,
		@cFilterPara=@cSupplierFilter,
		@cErrormsg=@cErrormsg OUTPUT


		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		SELECT @cPmtTableName='#pmtcbs',@cCbsColName='cbs_qty'
	END

	SET @cWc=@cWc+' and isnull(stock_na,0)=0 '
	SET @cWcCompare=@cWc

	--- Have to run this statement for updating the stock generated today where ageing days are not updated from Purchase
	--- or also those barcodes which have purchase_ageing_days null
	PRINT 'Update ageing days for Closing stock'
	SET @cCmd=N'UPDATE A SET purchase_ageing_days = (CASE WHEN isnull(purchase_receipt_dt,'''')='''' then 1 when 
					ABS(DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+''') END),
					shelf_ageing_days=(CASE WHEN isnull(sx.receipt_Dt,'''')='''' then 1 when  ABS(DATEDIFF(dd,sx.receipt_Dt,'''+
					convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,GETDATE(),110)+''')  END)
		FROM '+@cPmtTableName+' A (nolock)
		LEFT JOIN  sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
		JOIN sku_names (nolock) on sku_names.product_code=a.product_code
		WHERE ISNULL(a.'+@cCbsColName+',0)<>0'+@cWc+' AND A.BIN_ID<>''999'' AND (ISNULL(purchase_ageing_days,0)=0 OR ISNULL(shelf_ageing_days,0)=0)'
	print @CcMD
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'SELECT '+@cMasterColsExpr+',s1.slabname shelfAgeingSLab,s1.srno ageingOrder_shelf,s2.slabname purchaseAgeingSLab,s2.srno ageingOrder_stock,'+  
	  N'AVG(purchase_ageing_days) avgStockAgeing,AVG(shelf_ageing_days) avgShelfAgeing,SUM('+@cCbsColName+') stockQty,'+
	  N'CONVERT(NUMERIC(20,2),SUM('+@cCbsColName+'*pp)) stockPP FROM '+@cPmtTableName+' a (NOLOCK) '+
	N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	N' LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.product_code=a.product_code AND sku_xfp.dept_id=a.dept_id'+
	 N' JOIN location  (NOLOCK) ON location.dept_id=a.dept_id JOIN area (NOLOCK) ON area.area_code=location.area_code '+
	 N' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
	 N' JOIN #tmpAgeSlabs s1 ON a.shelf_ageing_days between S1.fromdays AND s1.todays '+
	 N' JOIN #tmpAgeSlabs s2 ON a.purchase_ageing_days between S2.fromdays AND s2.todays '+@cPriceCatgJoin+
	 N' WHERE 1=1'+@cWc+' GROUP BY '+@cGroupColsExpr+',s1.slabname,s2.slabname,s1.srno,s2.srno having SUM('+@cCbsColName+')<>0'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	IF @dCompareFromDt<>''
	BEGIN
		SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dCompareToDt) + 1, 0))

		IF @dToMonthEndDt=@dCompareToDt
		BEGIN
			SELECT @cPmtTableNameCompare=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dToMonthEndDt,112),@cCbsColNameCompare='cbs_qty'
		END
		ELSE
		BEGIN
			print 'Enter getting stock from xns-2r'
			exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY
			@dFromDt=@dCompareFromDt,
			@dToDt=@dCompareToDt,
			@bUpdateCbsOnly=1,
			@cFilterPara=@cSupplierFilter,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC

			SELECT @cPmtTableNameCompare='#pmtcbs',@cCbsColNameCompare='cbs_qty'
		END

		PRINT 'Update ageing days for Closing stock of Compare period'
		SET @cCmd=N'UPDATE A SET purchase_ageing_days = (CASE WHEN isnull(purchase_receipt_dt,'''')='''' then 1 when 
					ABS(DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,purchase_receipt_dt,'''+convert(varchar,GETDATE(),110)+''') END),
					shelf_ageing_days=(CASE WHEN isnull(sx.receipt_Dt,'''')='''' then 1 when  ABS(DATEDIFF(dd,sx.receipt_Dt,'''+
					convert(varchar,GETDATE(),110)+'''))>99999 
					THEN 99999 ELSE DATEDIFF(dd,sx.receipt_Dt,'''+convert(varchar,GETDATE(),110)+''')  END)
		FROM '+@cPmtTableNameCompare+' A (nolock)
		LEFT JOIN  sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
		JOIN sku_names (nolock) on sku_names.product_code=a.product_code
		WHERE ISNULL(a.cbs_qty,0)<>0 '+@cWcCompare+' AND A.BIN_ID<>''999'' AND (ISNULL(purchase_ageing_days,0)=0 OR ISNULL(shelf_ageing_days,0)=0)'
		print @CcMD
		EXEC SP_EXECUTESQL @cCmd

	END
	ELSE
	BEGIN
		SELECT @cPmtTableNameCompare='pmt01106',@cCbsColNameCompare='quantity_in_stock',@cWcCompare=' AND 1=2'
	END

	


	SET @cCmd=N'SELECT '+@cMasterColsExpr+',s1.slabname shelfAgeingSLab,s1.srno ageingOrder_shelf,s2.slabname purchaseAgeingSLab,s2.srno ageingOrder_stock,
	  AVG(Datediff(dd,sku_names.purchase_receipt_Dt,'''+CONVERT(VARCHAR,@dCompareToDt,112)+''')) avgStockAgeing_compare,convert(numeric(10,0),0) avgStockAgeing_variance,convert(numeric(10,0),0) avgStockAgeing_variancepct,
	  AVG(Datediff(dd,sku_xfp.first_receipt_Dt,'''+CONVERT(VARCHAR,@dCompareToDt,112)+''')) avgShelfAgeing_compare,convert(numeric(10,0),0) avgShelfAgeing_variance,convert(numeric(10,0),0) avgShelfAgeing_variancepct,
	  SUM('+@cCbsColNameCompare+') stockQty_compare,convert(numeric(20,2),0) stockQty_variance,convert(numeric(20,2),0) stockQty_variancepct,SUM('+@cCbsColNameCompare+'*pp) stockPP_compare,
	  convert(numeric(20,2),0) stockPP_variance,convert(numeric(20,2),0) stockPP_variancepct FROM '+@cPmtTableNameCompare+' a  (NOLOCK) '+
	' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code '+
	' LEFT JOIN sku_xfp (NOLOCK) ON sku_xfp.product_code=a.product_code AND sku_xfp.dept_id=a.dept_id'+
	' JOIN location  (NOLOCK) ON location.dept_id=a.dept_id JOIN area (NOLOCK) ON area.area_code=location.area_code '+
  	 ' JOIN #tmpAgeSlabs s1 ON a.shelf_ageing_days between S1.fromdays AND s1.todays '+
	 ' JOIN #tmpAgeSlabs s2 ON a.purchase_ageing_days between S2.fromdays AND s2.todays '+@cPriceCatgJoin+
	 ' JOIN city (NOLOCK) ON city.city_code=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code'+
     ' WHERE  1=1'+@cWcCompare+' GROUP BY '+@cGroupColsExpr+',s1.slabname,s2.slabname,s1.srno,s2.srno having SUM('+@cCbsColNameCompare+')<>0'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

    SELECT dept_id,(case when isnull(area_covered,0)=0 THEN 1 ELSE area_covered END) area_covered
	FROM location 

	SELECT * FROM #tmpAgeSlabs order by fromdays
END_PROC:

END