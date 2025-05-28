CREATE PROCEDURE DBSALE_KPI_SALE_LAST_YEAR_COMPARISION
@MODE VARCHAR(1)='M',
@USER_CODE VARCHAR(7)='',
@LOC VARCHAR(MAX)='',
@DT VARCHAR(10)
AS    
BEGIN    
   SET NOCOUNT ON

   DECLARE @dFROMDt DATETIME,@dToDt DATETIME,@cFromDt varchar(10),@cToDt varchar(10),@cFromDtLy varchar(10),@cToDtLy varchar(10),
   @cCmd NVARCHAR(MAX),@cPeriod VARCHAR(20),@dFromDtly DATETIME

   SET @dToDt=DATEADD(DD,1-DAY(@DT),@DT)
   SET @dFROMDt=DATEADD(MM,-11,@dToDt)
 
   CREATE TABLE #tmpKpISale (MONTH_YR VARCHAR(20),CY NUMERIC(20,2),LY NUMERIC(20,2))
    
   WHILE @dFROMDt<=@dToDt
   BEGIN
		SET @dFromDtly=DATEADD(YY,-1,@dFromdt)

		IF @mode<>'M'
   			SELECT @cFromDt = CONVERT(VARCHAR,DATEADD(qq, DATEDIFF(qq, 0, @dFROMDt), 0),112),
				   @cToDt = CONVERT(VARCHAR,DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @dFROMDt) +1, 0)),112),
				   @cFromDtLy = CONVERT(VARCHAR,DATEADD(qq, DATEDIFF(qq, 0, @dFROMDtLy), 0),112),
				   @cToDtLy = CONVERT(VARCHAR,DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @dFROMDtLy) +1, 0)),112),
				   @cPeriod=(CASE DATEPART(QUARTER, @dFROMDt) WHEN 1 THEN'Q4'WHEN 2 THEN'Q1'WHEN 3 THEN'Q2'WHEN 4 THEN'Q3'END)
		ELSE	
			SELECT @cFromDt =  CONVERT(VARCHAR,@dFROMDt-DAY(@dFROMDt)+1,112),
				   @cToDt=CONVERT(VARCHAR,dbo.uf_eomonth(@dFROMDt),112),
				   @cFromDtLy =  CONVERT(VARCHAR,@dFROMDtLy-DAY(@dFROMDtLy)+1,112),
				   @cToDtLy=CONVERT(VARCHAR,dbo.uf_eomonth(@dFROMDtLy),112),
				   @cPeriod=DATENAME(mm,@dFROMDt)+LTRIM(RTRIM(str(YEAR(@dFromDt))))

		SET @cCmd=N'SELECT  '''+@cPeriod+''', SUM(value) as CY 
		FROM  dbsale_2 (NOLOCK) WHERE kpi_name=''SALE'' AND db_dt between '''+@cFROMDt+''' AND '''+@cToDt+'''
		AND ('''+@LOC+'''='''' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE('''+@LOC+''')))'

		PRINT @cCmd
		INSERT INTO #tmpKpISale (MONTH_YR,cy)
		EXEC SP_EXECUTESQL @cCmd

		SET @cCmd=N'SELECT  '''+@cPeriod+''', SUM(value) as LY 
		FROM  dbsale_2 (NOLOCK) WHERE kpi_name=''SALE'' AND db_dt between '''+@cFROMDtLy+''' AND '''+@cToDtLy+'''
		AND ('''+@LOC+'''='''' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE('''+@LOC+''')))'

		PRINT @cCmd
		INSERT INTO #tmpKpISale (MONTH_YR,ly)
		EXEC SP_EXECUTESQL @cCmd

		
		SET @dFromdt=DATEADD(DD,1,CONVERT(DATE,@cToDt))
	END

	SELECT MONTH_YR,SUM(cy) CY,sum(ly) LY FROM #tmpKpISale
	GROUP BY month_yr
END