CREATE PROCEDURE SPWOW_VENDORDB_ANALYSIS
@cVendorAcCodesStr VARCHAR(1000),
@nSaleChartdays INT=30,
@cErrormsg varchar(1000) OUTPUT
AS
BEGIN
    Declare  @cCMD NVARCHAR(MAX),@cFinYear VARCHAR(10),
	@dFinYearFromDt DATETIME,@dMonthFromdt DATETIME,@cPrefix VARCHAR(10),@dFromDt DATETIME,@cMonth VARCHAR(10),@nLoop INT,
	@nDays INT,@cCmdPeriodWiseSale NVARCHAR(MAX),@dXnDt DATETIME,@cStep VARCHAR(5),@cDateFilter VARCHAR(200),@cFilter VARCHAR(MAX),
	@cCmdPaymodeWiseSale NVARCHAR(MAX),@cDrillDownColExpr VARCHAR(200),@cDrillDownGrpExpr VARCHAR(250),
	@nViewModeLoop INT,@cParaName VARCHAR(200),@cGroupByParaName VARCHAR(200)

BEGIN TRY	
	SET @cStep='5'
	SET @cErrormsg=''

	set datefirst 1
	CREATE TABLE #tmpDbData (paraName VARCHAR(200),periodMode int,yearMode int,netSaleVal numeric(16,0),salesQty numeric(16,0),
	sellthru numeric(4,0),vendorShareVal numeric(4,0),vendorShareQty numeric(4,0))

	CREATE TABLE #tVendors (vendor_ac_code CHAR(10))


	declare @dReportingDate datetime

	set @dReportingDate=convert(date,getdate())

	SET @cStep='10'
    
	SELECT @cCmdPeriodWiseSale='',@cCmdPaymodeWiseSale=''
	
	CREATE TABLE #ageWiseSales (yearMode NUMERIC(1,0),slabName VARCHAR(100),salesQty numeric(10,0))

	declare @WeekNum int,@YearNum varchar(10),@weekDay INT,@weekDayName VARCHAR(15),@dFromDtLy DATETIME,
	@dFromDtCy DATETIME
	SET @dXnDt=@dReportingDate
	SELECT @WeekNum= datepart(ww,@dXndt),@weekDay=datepart(weekday,@dXnDt),@weekDayName=datename(weekday,@dXndt),
	@YearNum=datepart(yy,@dXnDt),@dFromDt=@dReportingDate

	SELECT @cParaName=''''' para_name,',@cGroupByParaName=''
	

	--if @@spid=81
	--	select '#tmpageslabs',* from #tmpageslabs

	set @cStep='15'

	SET @cCmd=N'SELECT ac_code FROM lm01106 WHERE ac_code in ('+@cVendorAcCodesStr+')'
	INSERT INTO #tVendors (vendor_ac_code)
	EXEC SP_EXECUTESQL @cCmd

	SET @nViewModeLoop=2
	WHILE @nViewModeLoop<=4
	BEGIN
		SET @dXnDt=@dReportingDate
		SET @nLoop=1
		WHILE @nLoop<=2
		BEGIN

			SET @cStep='20'
			
			IF @nLoop=2
				SELECT @dFromDtLy = @dFromDt, @YearNum= datepart(yy,dateadd(yy,-1,@dXnDt)),@dXnDt=DATEADD(YY,-1,@dXnDt)
		
			IF @nViewModeLoop=2
				select @dXnDt=dbo.fnWOw_GetWeekSerial(@YearNum,@WeekNum,@weekDay)


			IF @nViewModeLoop=4
			BEGIN
				SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dXnDt)

				SET @cStep='25'
				SELECT @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)
			END

			SET @dFromDt=(CASE WHEN @nViewModeLoop=1 THEN @dXnDt WHEN @nViewModeLoop=2 THEN dbo.fnWOw_GetWeekSerial(@YearNum,@WeekNum,1)
							   WHEN @nViewModeLoop=3 THEN CONVERT(DATE,ltrim(rtrim(str(YEAR(@dXnDt))))+'-'+ltrim(rtrim(str(month(@dXnDt))))+'-01')
							   ELSE @dFinYearFromDt END) 	

		

			--select @dFromDt,@nLoop,@dXnDt

			SELECT @cDateFilter=N'b.cm_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+ CONVERT(VARCHAR,@dXnDt,110)+''''

			SET @cFilter=@cDateFilter
			
			if @nViewModeLoop=4
				SELECT @cParaName='sub_section_name,',@cGroupByParaName=' GROUP BY sub_section_name'

			SET @cStep='30'
			SET @cCmd=N'SELECT '+@cParaName+str(@nViewmodeLoop)+' periodMode,'+str(@nLoop)+' yearMode,sum(quantity*pp) netSaleVal,sum(quantity) salesQty
			  FROM cmd01106  a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
			  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
			  JOIN #tVendors v on v.vendor_ac_code=sku_names.ac_code WHERE '+@cFilter+' AND cancelled=0'+@cGroupByParaName
			
			PRINT @cCmd
			INSERT INTO #tmpDbData(paraName,periodMode,yearMode,netSaleVal,salesQty)
			EXEC SP_EXECUTESQL @cCmd

			SET @cStep='33'
			SET @cCmd=N'SELECT '+@cParaName+str(@nViewmodeLoop)+' periodMode,'+str(@nLoop)+' yearMode,sum(quantity*pp) netSaleVal,sum(quantity) salesQty
			  FROM ind01106  a (NOLOCK) JOIN inm01106 b (NOLOCK) ON a.inv_id=b.inv_id
			  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code
			  JOIN #tVendors v on v.vendor_ac_code=sku_names.ac_code WHERE '+replace(@cFilter,'cm_dt','inv_dt')+' AND inv_mode=1 AND cancelled=0'+@cGroupByParaName
			
			PRINT @cCmd
			INSERT INTO #tmpDbData(paraName,periodMode,yearMode,netSaleVal,salesQty)
			EXEC SP_EXECUTESQL @cCmd

			if @nViewModeLoop=4
			begin
				SET @cStep='35'
				SET @cCmd=N'SELECT s.category slabName,5 periodMode,'+str(@nLoop)+' yearMode,sum(quantity*pp) netSaleVal,sum(quantity) salesQty
				  FROM cmd01106  a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code 
				  LEFT JOIN #tmpAgeSlabs s ON ISNULL(a.selling_days,0) between S.fromRange AND s.toRange 
				  JOIN (SELECT  paraName from #tmpDbData where periodMode=4 AND yearmode='+str(@nLoop)+') c on c.paraname=sku_names.sub_section_name
				  WHERE '+@cDateFilter+' AND cancelled=0 GROUP BY s.category'
				  INSERT INTO #tmpDbData(paraName,periodMode,yearMode,netSaleVal,salesQty)
				  EXEC SP_EXECUTESQL @cCmd

				  SET @cStep='35.7'
				  SET @cCmd=N'SELECT s.category slabName,5 periodMode,'+str(@nLoop)+' yearMode,sum(quantity*pp) netSaleVal,sum(quantity) salesQty
				  FROM ind01106  a (NOLOCK) JOIN inm01106 b (NOLOCK) ON a.inv_id=b.inv_id
				  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code 
				  LEFT JOIN #tmpAgeSlabs s ON ISNULL(a.wsl_selling_days,0) between S.fromRange AND s.toRange 
				  JOIN (SELECT  paraName from #tmpDbData where periodMode=4 AND yearmode='+str(@nLoop)+') c on c.paraname=sku_names.sub_section_name
				  WHERE '+replace(@cDateFilter,'cm_dt','inv_dt')+' AND inv_mode=1  AND cancelled=0 GROUP BY s.category'
				  INSERT INTO #tmpDbData(paraName,periodMode,yearMode,netSaleVal,salesQty)
				  EXEC SP_EXECUTESQL @cCmd

				  SET @cStep='36.2'
				  SET @cCmd=N'SELECT s.category slabName,'+str(@nLoop)+' yearMode,sum(quantity) salesQty
				  FROM cmd01106  a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code 
				  JOIN #tVendors v on v.vendor_ac_code=sku_names.ac_code
				  JOIN #tmpAgeSlabs s ON a.selling_days BETWEEN s.fromRange AND s.toRange
				  WHERE cm_dt between '''+convert(varchar,@dFinYearFromDt,110)+''' and '''+convert(varchar,@dXnDt,110)+'''
				  AND  cancelled=0 GROUP BY s.category'

				  INSERT INTO #ageWiseSales (slabName,yearMode,salesQty)
				  EXEC SP_EXECUTESQL @cCmd

				  SET @cStep='37.5'
				  SET @cCmd=N'SELECT s.category slabName,'+str(@nLoop)+' yearMode,sum(quantity) salesQty
				  FROM ind01106  a (NOLOCK) JOIN inm01106 b (NOLOCK) ON a.inv_id=b.inv_id
				  JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code 
				  JOIN #tVendors v on v.vendor_ac_code=sku_names.ac_code
				  JOIN #tmpAgeSlabs s ON isnull(a.wsl_selling_days,0) BETWEEN s.fromRange AND s.toRange
				  WHERE inv_dt between '''+convert(varchar,@dFinYearFromDt,110)+''' and '''+convert(varchar,@dXnDt,110)+'''
				  AND inv_mode=1 AND cancelled=0 GROUP BY s.category'

				  INSERT INTO #ageWiseSales (slabName,yearMode,salesQty)
				  EXEC SP_EXECUTESQL @cCmd
			end

			SET @nLoop=@nLoop+1
			
		END

		
		SET @nViewModeLoop=@nViewModeLoop+1
	END

	DELETE FROM #tmpDbData WHERE netSaleVal is null and salesQty is null

	SET @cStep='40'
	DECLARE @nStockQtyCy numeric(10,0),@nStockQtyLy NUMERIC(10,0),@cPmtTableNameLy VARCHAR(200),@dToDtLy DATETIME,@dToMonthEndDtLy DATETIME,
	@dToDtLyLastMonthEndDt DATETIME

	SELECT @nStockQtyCy=sum(quantity_in_stock) FROM pmt01106 a (NOLOCK) JOIN sku_names b (NOLOCK) ON a.product_code=b.product_Code
	JOIN #tVendors v on v.vendor_ac_code=b.ac_code
	WHERE ISNULL(b.stock_na,0)=0 AND ISNULL(b.sku_item_type,0) IN (0,1)

	set  @dToDtLy=dateadd(yy,-1,@dReportingDate)
	SET @dToDtLyLastMonthEndDt=DATEADD(DAY, -DAY(@dToDtLy), CAST(@dToDtLy AS DATE))

	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty,convert(numeric(10,0),0) purchase_ageing_days,convert(numeric(10,0),0) shelf_ageing_days into #pmtops from pmt01106 (NOLOCK) where 1=2
	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty,convert(numeric(10,0),0) purchase_ageing_days,convert(numeric(10,0),0) shelf_ageing_days into #pmtcbs from pmt01106 (NOLOCK) where 1=2

	CREATE TABLE #ageWiseStock (slabType NUMERIC(1,0),yearMode NUMERIC(1,0),slabName VARCHAR(100),cbs_qty numeric(10,0))
	

	SET @cCmd=N'SELECT 1,1,s.category slabName,sum(quantity_in_stock) cbs_qty FROM pmt01106 a (NOLOCK) 
	JOIN #tmpAgeSlabs s ON a.purchase_ageing_days BETWEEN s.fromRange AND s.toRange
	JOIN sku_names sn (NOLOCK) ON sn.product_Code=a.product_code
	WHERE quantity_in_stock<>0 and sn.ac_code IN ('+@cVendorAcCodesStr+') AND ISNULL(sn.stock_na,0)=0 AND ISNULL(sn.sku_item_type,0) IN (0,1)
	GROUP BY s.category'
	INSERT INTO #ageWiseStock (slabType,yearMode,slabName,cbs_qty)
	EXEC SP_EXECUTESQL @cCmd
	

	DECLARE @cVendorFilter varchar(2000)
	SET @cVendorFilter=' sku_names.ac_code in ('+@cVendorAcCodesStr+')'

	print 'Check Vendor stock forlast year'
	SET @dToMonthEndDtLy=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dToDtLy) + 1, 0))
	--select @dToDtLy,@dToMonthEndDtLy
	IF @dToDtLy<>@dToMonthEndDtLy
	BEGIN
	
		SET @cStep='60'
		set @dFromDtLy=@dToDtLyLastMonthEndDt+1
		
	
		exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY
		@dFromDt=@dFromDtLy,
		@dToDt=@dToDtLy,
		@bUpdateCbsOnly=1,
		@cFilterPara=@cVendorFilter,
		@cErrormsg=@cErrormsg OUTPUT


		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
		
		IF EXISTS (SELECT TOP 1 * FROM #pmtcbs)
			SELECT @nStockQtyLy=SUM(cbs_qty) FROM #pmtcbs
		--if @@spid=81
		--	select @nStockQtyLy nStockQtyLy
		PRINT 'Update ageing days for Closing stock'
		UPDATE A SET purchase_ageing_days = (CASE WHEN isnull(purchase_receipt_dt,'')='' then 1 when 
						ABS(DATEDIFF(dd,purchase_receipt_dt,@dToDtLy))>99999 
						THEN 99999 ELSE ABS(DATEDIFF(dd,purchase_receipt_dt,@dToDtLy)) END)
		FROM #pmtcbs A (nolock)
		JOIN sku_names sn (nolock) on sn.product_code=a.product_code
		WHERE  ISNULL(purchase_ageing_days,0)<=0 
		
		--if @@spid=81
		--	select 'ageing days not foun', a.* from #pmtcbs a left join #tmpAgeSlabs s ON a.purchase_ageing_days BETWEEN s.fromRange AND s.toRange
		--	where s.fromRange is null

		
		INSERT INTO #ageWiseStock (slabType,yearMode,slabName,cbs_qty)
		SELECT 1,2,s.category slabName,sum(cbs_qty) cbs_qty FROM #pmtcbs a (NOLOCK) 
		JOIN #tmpAgeSlabs s ON a.purchase_ageing_days BETWEEN s.fromRange AND s.toRange
		JOIN sku_names (nolock) on sku_names.product_Code=a.product_code
		where isnull(sku_names.sku_er_flag,0) in (0,1) and isnull(sku_names.sku_item_type,0) in (0,1)
		GROUP BY s.category
		
		
	END
	ELSE
	BEGIN
		SET @cPmtTableNameLy=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dToDtLy,112)
		set @cCmd=N'SELECT @nStockQtyLy=SUM(cbs_qty) FROM '+@cPmtTableNameLy+' a '+
		'JOIN sku_names (nolock) on sku_names.product_Code=a.product_code
		where isnull(sku_names.sku_er_flag,0) in (0,1) and isnull(sku_names.sku_item_type,0) in (0,1)'

		EXEC SP_EXECUTESQL @cCmd,N'@nStockQtyLy NUMERIC(10,0) OUTPUT',@nStockQtyLy OUTPUT

		SET @cCmd=N'SELECT 1,2,s.category slabName,sum(cbs_qty) cbs_qty FROM '+@cPmtTableNameLy+' a (NOLOCK) 
		JOIN #tmpAgeSlabs s ON a.purchase_ageing_days BETWEEN s.fromRange AND s.toRange
		JOIN sku_names (nolock) on sku_names.product_Code=a.product_code
		where isnull(sku_names.sku_er_flag,0) in (0,1) and isnull(sku_names.sku_item_type,0) in (0,1)
		GROUP BY s.category'

		INSERT INTO #ageWiseStock (slabType,yearMode,slabName,cbs_qty)
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='70'

	--select @nStockQtyCy,@nStockQtyly

	INSERT INTO #tmpDbData(periodMode,yearMode,netSaleVal,salesQty)
	SELECT 4 periodMode,yearmode,sum(netSaleVal) netSaleVal,sum(salesQty) from 
	#tmpDbData WHERE periodMode=4 group by yearmode

	delete from #tmpDbData where periodMode=4 and isnull(paraName,'')<>''


	--if @@spid=67
	--	select 'check #tmpdbdata',@nStockQtyCy,* from #tmpdbdata

	UPDATE #tmpDbData SET sellthru=ceiling(salesQty*100/(salesQty+(CASE WHEN yearmode=1 THEN @nStockQtyCy ELSE  @nStockQtyLy END)))
	where periodMode=4 
	
	UPDATE a SET vendorShareVal=ceiling((a.netSaleVal/b.netSaleVal)*100),vendorShareQty=ceiling((a.salesQty/b.salesQty)*100)
	from #tmpDbData a JOIN
	(SELECT yearmode,SUM(netSaleVal) netSaleVal,sum(salesQty) salesQty from  #tmpDbData where periodMode=5 group by yearmode) b 
	ON a.yearMode=b.yearMode where a.periodMode=4 
		
	--delete from #tmpDbData where periodMode=5

	SELECT  * FROM #tmpDbData where periodMode<>5
	
	SELECT sum(case when xntype='PURCHASEINVOICE'  then Qty else 0 end) dispatched,
	sum(case when xntype='PurchaseOrder' then Qty else - Qty end) pending from PurchaseOrderProcessingNew a (NOLOCK)
	JOIN pod01106 b (NOLOCK) ON b.row_id=a.RefRowId
	JOIN pom01106 c (NOLOCK) ON c.po_id=b.po_id
	JOIN #tVendors v on v.vendor_ac_code=c.ac_code
	
	select count(rm_id) dnissued,sum(case when isnull(cr_received,0)=1 then 1 else 0 end) cnreceived
	from rmm01106 a (nolock) JOIN #tVendors v on v.vendor_ac_code=a.ac_code
	WHERE mode=1 AND cancelled=0
	
	SELECT slabName,'Sales' ageingType,sum(case when yearMode=1 THEN salesQty else 0 end) cyQty,sum(case when yearMode=2 THEN salesQty else 0 end) lyQty
	FROM #ageWiseSales group by slabName
	UNION ALL
	SELECT slabName,(case when slabtype=1 then 'Purchase' else 'Shelf' end) ageingType,
	sum(case when yearMode=1 THEN cbs_qty else 0 end) cyQty,sum(case when yearMode=2 THEN cbs_qty else 0 end) lyQty
	FROM #ageWiseStock group by slabName,(case when slabtype=1 then 'Purchase' else 'Shelf' end)


	SELECT category slabName FROM #tmpAgeSlabs order by srno

	EXEC SPWOW_VENDORDB_SALECHART
	@cVendorAcCodesStr=@cVendorAcCodesStr,
	@nSaleChartdays=@nSaleChartdays,
	@bCalledFromVendorDb=1

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg= 'Error in Procedure SPWOW_VENDORDB_ANALYSIS at Step#'+@cStep+' '+ERROR_MESSAGE();
	GOTO END_PROC
END CATCH

END_PROC:

END