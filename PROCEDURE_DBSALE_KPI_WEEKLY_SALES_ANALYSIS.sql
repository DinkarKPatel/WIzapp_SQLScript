CREATE PROCEDURE DBSALE_KPI_WEEKLY_SALES_ANALYSIS (@USER_CODE VARCHAR(7)='',@YEAR INT=0,@LOC VARCHAR(MAX)='',@DT datetime)
AS    
BEGIN    
  DECLARE @dCurYearFromDt DATETIME,@dCurYearTotDt 	DATETIME,@dLastYearFromDt DATETIME,@dLastYearToDt	DATETIME,@dDtPara datetime,
  @dWeekStartDt DATETIME,@dWeekEndDt DATETIME,@nWeekno NUMERIC(2,0),@dWeekStartDtLy DATETIME,@dWeekEndDtLy DATETIME
  
  set @dDtPara=@dt
  SELECT @dCurYearFromDt=DATEADD(DD,-365,@dt),@dCurYearTotDt=@dt,@dLastYearFromDt=DATEADD(DD,-730,@dt),@dLastYearToDt=DATEADD(DD,-366,@dt)
  
  CREATE TABLE #tmpWeeklyRep (week_no numeric(2,0),WEEK_START_DT DATETIME,week_end_dt DATETIME,WEEK_START_DT_ly DATETIME,week_end_dt_ly DATETIME,
  cy_revenue numeric(20,2),ly_revenue numeric(20,2),cy_profit numeric(20,2),ly_profit numeric(20,2),cy_profit_PCT numeric(20,2),ly_profit_PCT numeric(20,2))
  
  SET NOCOUNT ON
  SElect @nWeekno=52
  WHILE @DT>=@dLastYearToDt
  BEGIN
	SElect @dWeekEndDt=@dT,@dWeekStartDt=DATEADD(dd,-6,@DT),@dWeekEndDtLy=DATEADD(DD,-366,@dt),@dWeekStartDtLy=DATEADD(dd,-372,@DT)
	
	
	--select @dWeekStartDt,@dWeekStartDtLy
	
	INSERT #tmpWeeklyRep (week_no ,WEEK_START_DT ,week_end_dt,WEEK_START_DT_ly ,week_end_dt_ly,cy_revenue,ly_revenue ,cy_profit,ly_profit)
	SELECT @nWeekno as week_no,@dWeekStartDt as week_start_dt,@dWeekEndDt as week_end_Dt,@dWeekStartDtLy as week_start_dt_ly,@dWeekEndDtLy as week_end_Dt_ly,
	SUM(cy_revenue) as cv_revenue,SUM(ly_revenue) as ly_revenue,SUM(cy_profit) as cy_profit,SUM(ly_profit) as ly_profit
	FROM
	(
	SELECT SUM(case when kpi_name='SALE' then value else 0 end) as cy_revenue ,0 as Ly_revenue,
	sum(case when kpi_name='PROFIT' THEN value else 0 end) as cy_profit,0 as  ly_profit
	FROM  dbsale_2 (NOLOCK) WHERE db_dt between @dWeekStartDt and @dWeekEndDt
	UNION all
	SELECT 0 as cy_revenue,SUM(case when kpi_name='SALE' then value else 0 end) as ly_revenue,
	0 as  cy_profit,sum(case when kpi_name='PROFIT' THEN value else 0 end) as ly_profit
	FROM  dbsale_2 (NOLOCK) WHERE db_dt between @dWeekStartDtLy and @dWeekEndDtLy	
	) a
	
	SET @DT=@dWeekStartDt-1
	--select @dt
  END
  
  UPDATE #tmpWeeklyRep  SET cy_profit_PCT=(CASE WHEN cy_revenue>0 THEN  round((cy_profit/cy_revenue)*100,2) ELSE 0 end),
  ly_profit_PCT=(CASE WHEN ly_revenue>0 THEN  round((ly_profit/ly_revenue)*100,2) else 0 end)
  
  
  SELECT convert(varchar,week_start_dt,105) as PERIOD
  ,convert(varchar,week_end_dt,105) [Week Range Curr],cy_revenue as REVENUE_CY,cy_profit as PROFIT_CY,
  cy_profit_PCT as PROFIT_MARGIN_CY
  ,convert(varchar,week_end_dt_LY,105) [Week Range Prev],Ly_revenue as REVENUE_LY,ly_profit as PROFIT_LY,
  ly_profit_PCT as PROFIT_MARGIN_LY
  FROM #tmpWeeklyRep
  --convert(varchar,week_start_dt_ly,105)+'-'+ 

  --SELECT C.PD_TYPE PERIOD
  --,C.PERIOD [Week Range Curr],ISNULL(C.REVENUE,'0.00') REVENUE_CY,ISNULL(C.PROFIT,'0.00') PROFIT_CY,ISNULL(C.PROFIT_MARGIN,'0.00') PROFIT_MARGIN_CY
  --,L.PERIOD [Week Range Prev],ISNULL(L.REVENUE,'0.00') REVENUE_LY,ISNULL(L.PROFIT,'0.00') PROFIT_LY,ISNULL(L.PROFIT_MARGIN,'0.00') PROFIT_MARGIN_LY

  --FROM (SELECT * FROM DBSALE_2 (NOLOCK) WHERE (@LOC='' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE(@LOC)))
  --AND  db_dt BETWEEN @dCurYearFromDt AND @dCurYearTotDt)C
  --JOIN (SELECT * FROM DBSALE_2 (NOLOCK) WHERE (@LOC='' OR DEPT_ID IN (SELECT CODE FROM DBO.FN_SPLIT_VALUE(@LOC)))
  --AND  db_dt BETWEEN @dLastYearFromDt AND @dLastYearTotDt)L ON C.PD_TYPE=L.PD_TYPE
  
  SET NOCOUNT OFF
END--PROCEDURE DBSALE_KPI_WEEKLY_SALES_ANALYSIS