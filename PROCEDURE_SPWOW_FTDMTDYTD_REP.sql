CREATE PROCEDURE SPWOW_FTDMTDYTD_REP
@dReportingDate DATETIME,
@dLastYearDate DATETIME,
@nMode INT=0 --- (1.FTD 2.MTD 3.YTD)
AS
BEGIN
    Declare  @cTablewow varchar(200),@cTableWowPrevYear VARCHAR(200),@cCMD NVARCHAR(MAX),@cFinYear VARCHAR(10),
	@dFinYearFromDt DATETIME,@dMonthFromdt DATETIME,@cPrefix VARCHAR(10)
	
	CREATE TABLE #temp_wow (dept_alias VARCHAR(100),user_code CHAR(7),paymode_code CHAR(7),paymode_grp_code CHAR(7),
	mode INT,ftd_value_cy numeric(12,2),mtd_value_cy numeric(20,2),
	ytd_value_cy numeric(20,2),ftd_value_ly numeric(12,2),mtd_value_ly numeric(20,2),ytd_value_ly numeric(20,2),
	ftd_soldqty_cy numeric(12,2),mtd_soldqty_cy numeric(20,2),
	ytd_soldqty_cy numeric(20,2),ftd_soldqty_ly numeric(12,2),mtd_soldqty_ly numeric(20,2),ytd_soldqty_ly numeric(20,2),
	ftd_billCnt_cy numeric(12,2),mtd_billCnt_cy numeric(20,2),
	ytd_billCnt_cy numeric(20,2),ftd_billCnt_ly numeric(12,2),mtd_billCnt_ly numeric(20,2),ytd_billCnt_ly numeric(20,2))

	SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dReportingDate)

	SET @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)

	IF @nMode IN (0,3)
	BEGIN
		INSERT INTO #temp_wow (dept_alias,user_code,ytd_value_cy,ytd_soldqty_cy,ytd_billCnt_cy,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) ytd_value_cy,SUM(total_quantity) ytd_soldqty_cy,
		COUNT(cm_id) ytd_billCnt_cy,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt BETWEEN @dFinyearFromdt AND @dReportingDate AND cancelled=0
		GROUP BY B.DEPT_ALIAS,user_code

		INSERT INTO #temp_wow (dept_alias,paymode_code,paymode_grp_code,user_code,ytd_value_cy,mode)
		SELECT  B.DEPT_ALIAS,c.paymode_code,paymode_grp_code,user_code,SUM(amount) ytd_value_cy,2 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt BETWEEN @dFinyearFromdt AND @dReportingDate AND cancelled=0 AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END

	IF @nMode IN (0,2)
	BEGIN
		SET @dMonthFromdt=DATEADD(mm, DATEDIFF(m,0,@dReportingDate),0)

		INSERT INTO #temp_wow (dept_alias,user_code,mtd_value_cy,mtd_soldqty_cy,mtd_billCnt_cy,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) mtd_value_cy,SUM(total_quantity) mtd_soldqty_cy,
		COUNT(cm_id) mtd_billCnt_cy,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt BETWEEN @dMonthFromdt AND @dReportingDate AND cancelled=0
		GROUP BY B.DEPT_ALIAS,user_code

		INSERT INTO #temp_wow (dept_alias,user_code,paymode_code,paymode_grp_code,mtd_value_cy,mode)
		SELECT  B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code,SUM(amount) mtd_value_cy,2 
		FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt BETWEEN @dMonthFromdt AND @dReportingDate AND cancelled=0 AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END

	IF @nMode IN (0,1)
	BEGIN

		INSERT INTO #temp_wow (dept_alias,user_code,ftd_value_cy,ftd_soldqty_cy,ftd_billCnt_cy,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) ftd_value_cy,SUM(total_quantity) ftd_soldqty_cy,
		COUNT(cm_id) ftd_billCnt_cy,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt=@dReportingDate
		GROUP BY B.DEPT_ALIAS,user_code

		INSERT INTO #temp_wow (dept_alias,user_code,paymode_code,paymode_grp_code,ftd_value_cy,mode)
		SELECT  B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code,SUM(amount) ftd_value_cy,2 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt=@dReportingDate AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END

	SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dLastYearDate)
	SET @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)

	IF @nMode IN (0,3)
	BEGIN
		INSERT INTO #temp_wow (dept_alias,user_code,ytd_value_ly,ytd_soldqty_ly,ytd_billCnt_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) ytd_value_ly,SUM(total_quantity) ytd_soldqty_ly,
		COUNT(cm_id) ytd_billCnt_ly,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt BETWEEN @dFinyearFromdt AND @dLastYearDate AND cancelled=0
		GROUP BY B.DEPT_ALIAS,user_code

		--select @dFinyearFromdt,@dLastYearDate
		
		INSERT INTO #temp_wow (dept_alias,user_code,paymode_code,paymode_grp_code,ytd_value_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code,SUM(amount) ytd_value_ly,2 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt BETWEEN @dFinyearFromdt AND @dLastYearDate AND cancelled=0 AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END
	
	IF @nMode IN (0,2)
	BEGIN
		SET @dMonthFromdt=DATEADD(mm, DATEDIFF(m,0,@dLastYearDate),0)

		INSERT INTO #temp_wow (dept_alias,user_code,mtd_value_ly,mtd_soldqty_ly,mtd_billCnt_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) mtd_value_ly,SUM(total_quantity) mtd_soldqty_ly,
		COUNT(cm_id) mtd_billCnt_ly,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt BETWEEN @dMonthFromdt AND @dLastYearDate AND cancelled=0
		GROUP BY B.DEPT_ALIAS,user_code

		--select @dMonthFromdt,@dLastYearDate

		INSERT INTO #temp_wow (dept_alias,user_code,paymode_code,paymode_grp_code,mtd_value_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code,SUM(amount) mtd_value_ly,2 
		FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt BETWEEN @dMonthFromdt AND @dLastYearDate AND cancelled=0  AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END
	
	IF @nMode IN (0,1)
	BEGIN

		INSERT INTO #temp_wow (dept_alias,user_code,ftd_value_ly,ftd_soldqty_ly,ftd_billCnt_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,SUM(net_amount) ftd_value_ly,SUM(total_quantity) ftd_soldqty_ly,
		COUNT(cm_id) ftd_billCnt_ly,1 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		WHERE cm_dt=@dLastYearDate
		GROUP BY B.DEPT_ALIAS,user_code

		INSERT INTO #temp_wow (dept_alias,user_code,paymode_code,paymode_grp_code,ftd_value_ly,mode)
		SELECT  B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code,SUM(amount) ftd_value_ly,2 FROM cmm01106  A (NOLOCK)
		JOIN LOCATION  B (NOLOCK) ON A.location_code/*LEFT(a.cm_id,2)*//*Rohit 05-11-2024*/= B.DEPT_ID
		JOIN paymode_xn_det c (NOLOCK) ON c.memo_id=a.cm_id
		JOIN paymode_mst d (NOLOCK) ON d.paymode_code=c.paymode_code
		WHERE cm_dt=@dLastYearDate AND c.xn_type='SLS'
		GROUP BY B.DEPT_ALIAS,user_code,c.paymode_code,paymode_grp_code
	END
	
	SET @cPrefix=(CASE WHEN @nMode=1 THEN 'FTD' WHEN @nMode=2 THEN 'MTD' ELSE 'YTD' END)

	--- It will be Blank as per WizTickit#1222-00061 after discussion between Anil and Sir (Date :21-12-2022)
	DECLARE @cOutputPrefix VARCHAR(100)
	SET @cOutputPrefix=''

	SET @cCmd=N'SELECT *  FROM 
	(SELECT DEPT_ALIAS As [Alias],Username,SUM(ISNULL('+@cPrefix+'_value_cy,0)) AS ['+@cOutputPrefix+'Value Current year] ,'+
	'SUM(ISNULL('+@cPrefix+'_value_ly,0)) as ['+@cOutputPrefix+'Value Last year],SUM(ISNULL('+@cPrefix+'_soldqty_cy,0)) AS ['+@cOutputPrefix+'Qty Current year] ,'+
	'SUM(ISNULL('+@cPrefix+'_soldqty_ly,0)) as ['+@cOutputPrefix+'Qty Last year],SUM(ISNULL('+@cPrefix+'_billCnt_cy,0)) AS ['+@cOutputPrefix+'BillCnt Current year] ,'+
	'SUM(ISNULL('+@cPrefix+'_billCnt_ly,0)) as ['+@cOutputPrefix+'BillCnt Last year] FROM  #temp_wow a
	JOIN users b (NOLOCK) ON b.user_code=a.user_code
	WHERE mode=1 GROUP BY DEPT_ALIAS,username) a
	ORDER BY 1,2'

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cCmd=N'SELECT *  FROM 
	(SELECT  DEPT_ALIAS As [Alias],userName,paymode_grp_name payModeGrpName,paymode_name payModeName,SUM(ISNULL('+@cPrefix+'_value_cy,0)) AS ['+@cOutputPrefix+'Value Current year] ,'+
	'SUM(ISNULL('+@cPrefix+'_value_ly,0)) as ['+@cOutputPrefix+'Value Last year] FROM #temp_wow a
	JOIN users b (NOLOCK) ON b.user_code=a.user_code
	JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
	JOIN paymode_grp_mst d (NOLOCK) ON d.paymode_grp_code=c.paymode_grp_code
	WHERE mode=2
	GROUP BY DEPT_ALIAS,username,paymode_grp_name,paymode_name) a
	ORDER BY 1,2,3,4'
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END


