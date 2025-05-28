CREATE PROCEDURE SPWOW_VENDORDB_SALECHART
@cVendorAcCodesStr VARCHAR(1000),
@nSaleChartdays INT=30,
@bCalledFromVendorDb BIT=0
AS
BEGIN
	DECLARE @nLoop INT,@dSaleChartFromDt DATETIME,@dXnDt DATETIME,@cCmd NVARCHAR(MAX)
	CREATE TABLE #tmpDateWiseSales (xn_dt datetime,salesQty NUMERIC(10,0),yearmode INT)

	IF @bCalledFromVendorDb=0
	begin
		
		CREATE TABLE #tVendors (vendor_ac_code CHAR(10))

		SET @cCmd=N'SELECT ac_code FROM lm01106 WHERE ac_code in ('+@cVendorAcCodesStr+')'
		INSERT INTO #tVendors (vendor_ac_code)
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @dXnDt=CONVERT(DATE,GETDATE())

	SET @nLoop=1
	WHILE @nLoop<=2
	BEGIN
		set @dSaleChartFromDt= dateadd(dd,-@nSaleChartDays,@dXnDt)
		
		INSERT INTO #tmpDateWiseSales (xn_dt,yearmode,salesQty)
		SELECT cm_dt,@nLoop yearMode,sum(quantity) salesQty
		FROM cmd01106  a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
		JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code 
		JOIN #tVendors v on v.vendor_ac_code=sku_names.ac_code
		WHERE cm_dt between @dSaleChartFromDt and @dXnDt
		AND  cancelled=0 GROUP BY cm_dt HAVING SUM(quantity)<>0

		SET @nLoop=@nLoop+1
		SET @dXnDt=DATEADD(yy,-1,@dXndt)
	END
		
	update #tmpDateWiseSales set xn_dt=dateadd(yy,1,xn_dt) where yearmode=2 
	
	select xn_dt,sum(case when yearMode=1 THEN salesQty else 0 end) cyValue,
	sum(case when yearMode=2 THEN salesQty else 0 end) lyValue
	from #tmpDateWiseSales group BY xn_dt
	order by xn_dt

	
END