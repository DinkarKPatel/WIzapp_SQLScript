CREATE PROCEDURE DBSALE_KPI_SALE_PERFORMANCE
@MODE CHAR(1)='M',
@USER_CODE VARCHAR(7)='',
@LOC VARCHAR(MAX)='',
@DT VARCHAR(10)
AS
BEGIN
   DECLARE @dFROMDt DATETIME,@dToDt DATETIME,@cFromDt varchar(10),@cToDt varchar(10),@cCmd NVARCHAR(MAX),@cPeriod VARCHAR(20)
   SET @dToDt=DATEADD(DD,1-DAY(@DT),@DT)
   SET @dFROMDt=DATEADD(MM,-11,@dToDt)
 
   CREATE TABLE #tmpKpISale (Period VARCHAR(20),REVENUE NUMERIC(20,2),PROFIT NUMERIC(20,2),PROFIT_MARGIN NUMERIC(6,2))
    
   WHILE @dFROMDt<=@dToDt
   BEGIN
		IF @mode<>'M'
   			SELECT @cFromDt = CONVERT(VARCHAR,DATEADD(qq, DATEDIFF(qq, 0, @dFROMDt), 0),112),
				   @cToDt = CONVERT(VARCHAR,DATEADD (dd, -1, DATEADD(qq, DATEDIFF(qq, 0, @dFROMDt) +1, 0)),112),
				   @cPeriod=(CASE DATEPART(QUARTER, @dFROMDt) WHEN 1 THEN'Q4'WHEN 2 THEN'Q1'WHEN 3 THEN'Q2'WHEN 4 THEN'Q3'END)
		ELSE	
			SELECT @cFromDt =  CONVERT(VARCHAR,@dFROMDt-DAY(@dFROMDt)+1,112),
				   @cToDt=CONVERT(VARCHAR,dbo.UF_EOMONTH(@dFROMDt),112),
				   @cPeriod=DATENAME(mm,@dFROMDt)+LTRIM(RTRIM(str(YEAR(@dFromDt))))

		SET @cCmd=N'SELECT  '''+@cPeriod+''', SUM(case when kpi_name=''SALE'' then value else 0 end) as revenue ,
		sum(case when kpi_name=''PROFIT'' THEN value else 0 end) as profit
		FROM  dbsale_2 (NOLOCK) WHERE db_dt between '''+@cFROMDt+''' AND '''+@cToDt+'''
		and kpi_name in (''SALE'',''PROFIT'')
		AND ('''+@LOC+'''='''' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE('''+@LOC+''')))'

		PRINT @cCmd
		INSERT INTO #tmpKpISale (period,revenue,profit)
		EXEC SP_EXECUTESQL @cCmd

		SET @dFromdt=DATEADD(DD,1,CONVERT(DATE,@cToDt))
	END

	UPDATE #tmpKpISale SET profit_margin=ROUND(CONVERT(FLOAT,ISNULL(PROFIT,0))/CASE ISNULL(REVENUE,0) WHEN 0 THEN 1 
										  ELSE CONVERT(FLOAT,REVENUE) END*100.0,2)  
	
	SELECT * FROM #tmpKpISale
END