CREATE PROCEDURE SPWOW_DBPUR_ANALYSIS
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cAgeingSettingName VARCHAR(100)='ageing setting 1',
@cSupplierCode CHAR(10)='',
@cMrrId VARCHAR(50)='',
@bRetStockDetails BIT=0,
@cErrormsg varchar(200) output
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cDbTableName VARCHAR(200),@cPmtTableName VARCHAR(200),@cCbsColName VARCHAR(30),@dToMonthEndDt DATETIME,@cWc VARCHAR(200),
	@cWcCompare VARCHAR(200),@cWcLocWise VARCHAR(200),	@cWcCompareLocWise VARCHAR(200),@cPmtTableNameCompare VARCHAR(200),@cCbsColNameCompare VARCHAR(200),
	@nMaxSrno int,@nSrno INT,@nPrevDays INT,@cPriceCatgJoin varchar(200),@cStep varchar(5),@cInventoryColumns VARCHAR(500),@cInventoryGrpColumns VARCHAR(400)


BEGIN TRY
	SET @cStep='10'
	select ageingdays,row_number() over (order by ageingdays) srno into #tmpAgeDays from wowdb_ageingdays (NOLOCK) 
	WHERE groupName=@cAgeingSettingName

	select @nMaxSrno=max(srno) from #tmpAgeDays

	CREATE TABLE #tmpAgeSlabs (fromDays INT,toDays INT,slabName VARCHAR(100),srno int)

	SET @cStep='20'
	INSERT INTO #tmpAgeSlabs (fromDays,toDays,slabName,srno)
	SELECT 0,ageingDays ,'<='+LTRIM(RTRIM(str(ageingDays))),srno-1 from #tmpAgeDays WHERE SRNO=1
	union all
	SELECT ageingdays+1,999999999,'>'+LTRIM(RTRIM(str(ageingDays))),srno+1 from #tmpAgeDays WHERE SRNO=@nMaxSrno
	
	SET @cStep='30'
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
	
	DECLARE @cMasterColsExpr VARCHAR(1000),@cGroupColsExpr varchar(1000)

	if @cMrrId<>''
		SELECT @dFromDt=receipt_dt,@dToDt=receipt_dt FROM pim01106 (NOLOCK) WHERE mrr_id=@cMrrId

	select ac_code,mrr_no,receipt_dt,mrr_id into #tmpPim from  pim01106 (NOLOCK) WHERE 1=2
	SET @cStep='40'
	SET @cCmd=N'select ac_code,mrr_id,mrr_no,receipt_dt  from  pim01106 (NOLOCK) WHERE '+
	(CASE WHEN @cSupplierCode<>'' THEN 'ac_code='''+@cSupplierCode+'''' WHEN @cMrrId<>''
	 THEN 'mrr_id='''+@cMrrId+'''' ELSE ' 1=1 ' END)+(CASE WHEN @cMrrId='' THEN ' AND receipt_dt between '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+
	 CONVERT(VARCHAR,@dToDt,110)+'''' else '' END)
	 
    PRINT @cCmd
	INSERT INTO #tmpPim (ac_code,mrr_id,mrr_no,receipt_dt)
	EXEC SP_EXECUTESQL @cCmd
	
	SELECT product_code,a.mrr_id INTO #tmpPid FROM pid01106 a (NOLOCK) JOIN #tmpPim b ON b.mrr_id=a.mrr_id

	IF EXISTS (SELECT TOP 1 product_code FROM #tmppid GROUP BY product_code HAVING COUNT(*)>1)
	BEGIN
		WITH cteDUp
		as
		(
			select *,row_number() over (partition by product_code order by mrr_id) srno
			FROM #tmpPid 
		)

		DELETE FROM cteDup WHERE srno>1
	END

	SELECT @cInventoryColumns='',@cInventoryGrpColumns=''
	IF @bRetStockDetails=1
		SELECT @cInventoryColumns=',barcode_img_id img_id,article_no articleNo,para1_name para1Name,para2_name para2Name,para3_name para3Name',
		@cInventoryGrpColumns=',barcode_img_id,article_no,para1_name,para2_name,para3_name'


	SELECT @cMasterColsExpr='t.mrr_id mrrId,mrr_no mrnNo,t.receipt_dt receiptDate,lm_supp.ac_name Supplier,oem_ac_name oemSupplier'+@cInventoryColumns,
		   @cGroupColsExpr='t.mrr_id,mrr_no,t.receipt_dt,lm_supp.ac_name,oem_ac_name'+@cInventoryGrpColumns

	SET @cCmd=N'SELECT '+@cMasterColsExpr+',sum(quantity) slsQty,s.slabName slsAgeingSLab,s.srno ageingOrder_sale,SUM(rfnet) nrv,'+
  	 N'convert(numeric(20,2),SUM(quantity*pp)) cogs,sum(a.discount_amount+isnull(a.cmm_discount_amount,0)) slsDiscount,sum(a.mrp*quantity) slsMrpVal '+
	 N' FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.cm_id '+
	 N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' JOIN #tmpAgeSlabs s ON ISNULL(a.selling_days,0) between S.fromdays AND s.todays '+
	 N' WHERE cancelled=0  AND quantity>0 GROUP BY '+@cGroupColsExpr+',s.slabName,s.srno'
	 	

	--select @cCmd
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='50'
	SET @cCmd=N'SELECT '+@cMasterColsExpr+',sum(quantity) slsQty,s.slabName slsAgeingSLab,s.srno ageingOrder_sale,SUM(rfnet) nrv,'+
  	 N'convert(numeric(20,2),SUM(quantity*pp)) cogs,sum(a.discount_amount+isnull(a.inmdiscountamount,0)) slsDiscount,sum(a.rate*quantity) slsMrpVal '+
	 N' FROM ind01106 a (NOLOCK) JOIN inm01106 b (NOLOCK) ON b.inv_id=a.inv_id '+
	 N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code  JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' JOIN #tmpAgeSlabs s ON ISNULL(a.wsl_selling_days,1) between S.fromdays AND s.todays '+
	 N' WHERE inv_mode=1 AND cancelled=0 GROUP BY '+@cGroupColsExpr+',s.slabName,s.srno'

	
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cStep='60'
	SET @cCmd=N'SELECT '+@cMasterColsExpr+',sum(quantity) slrQty FROM cmd01106 a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON b.cm_id=a.cm_id '+
	 N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code  JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' WHERE cancelled=0  AND quantity<0 GROUP BY '+@cGroupColsExpr
	 	

	--select @cCmd
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	SET @cStep='65'
	SET @cCmd=N'SELECT '+@cMasterColsExpr+',sum(quantity) slrQty FROM cnd01106 a (NOLOCK) JOIN cnm01106 b (NOLOCK) ON b.cn_id=a.cn_id '+
	 N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' WHERE cancelled=0 AND b.mode=1 GROUP BY '+@cGroupColsExpr
	 	

	--select @cCmd
    PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	CREATE TABLE #tmpXnsCbs (dept_id VARCHAR(4),product_code VARCHAR(50),bin_id VARCHAR(10),xn_qty NUMERIC(20,3),xn_type VARCHAR(20))

	DECLARE @cFilter VARCHAR(500)

	SET @cStep='70'
	
	DECLARE @dStockToDate DATETIME

	SET @dStockToDate=CONVERT(DATE,GETDATE())
	EXEC SPWOW_GETXNSDATA_OBSCBSCALC 
	@dFromDt='1901-01-01',
	@dToDt=@dStockToDate,
    @cFilterJoinstr=' JOIN #tmpPid tp ON tp.product_code=sku_names.product_code ',
    @cErrormsg=@cErrormsg OUTPUT
	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	

    SET @cStep='75'
	SET @cCmd=N'SELECT '+@cMasterColsExpr+',(CASE WHEN a.xn_type=''PUR'' THEN 3 when a.xn_type=''PRT'' THEN 4 ELSE xntypeMode END) xntypeMode,'+
	 N'sum(xn_qty) xnQty FROM #tmpXnsCbs a (NOLOCK) '+
	 N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code  JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' JOIN wow_XPERT_XNTYPeS_alias xnt (NOLOCK) ON xnt.xn_type_alias=a.xn_type '+
	 N' WHERE a.xn_type NOT IN (''SLS'',''SLR'',''WSL'',''WSR'') GROUP BY '+@cGroupColsExpr+',(CASE WHEN a.xn_type=''PUR'' THEN 3 when a.xn_type=''PRT'' THEN 4 ELSE xntypeMode END)'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='80'
	SET @cCmd=N'SELECT '+@cMasterColsExpr+',s.slabname stockAgeingSLab
	  ,s.srno ageingOrder_stock,SUM(quantity_in_stock) stockQty FROM pmt01106 a (NOLOCK) '+
     N' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code  JOIN #tmppid p ON p.product_code=sku_names.product_code '+
	 N' JOIN #tmpPim t ON t.mrr_id=p.mrr_id JOIN LM01106 lm_supp (NOLOCK) ON lm_supp.ac_code=sku_names.ac_code '+
	 N' JOIN #tmpAgeSlabs s ON datediff(dd,sku_names.purchase_receipt_dt,getdate()) between s.fromdays AND s.todays '+
	 N' GROUP BY '+@cGroupColsExpr+',s.slabname,s.srno having SUM(quantity_in_stock)<>0'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	
	 SELECT * FROM #tmpAgeSlabs order by fromdays

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_DBPUR_ANALYSIS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END