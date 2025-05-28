CREATE PROCEDURE SPWOW_BUILD_FTDMTDYTD_SALES
@dFromDtPara DATETIME,
@dToDtPara DATETIME,
@bCalledfromReporting BIT=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cFromDt VARCHAR(20),@cToDt VARCHAR(20),@nOuterLoop INT,@nInnerLoop INT,@bFirstDate BIT,@cWhere VARCHAR(50),
	@dFromDt DATETIME,@dToDt DATETIME,@dFirstDOM DATETIME,@dFirstDOY DATETIME,@dFilterDate DATETIME,@cTable VARCHAR(100),@cPrevtable VARCHAR(100),
	@cSaleColumn VARCHAR(100),@dFinYearFromDt DATETIME,@cFinYear VARCHAR(5),@cStep VARCHAR(4),@cErrormsg VARCHAR(MAX)

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''

	CREATE TABLE #temp_wow_ftdmtdytd_sales (xn_dt DATETIME,mode int,dept_id VARCHAR(5)/*CHAR(2)*//*Rohit 05-11-2024*/,ftd_value NUMERIC(20,2),mtd_value NUMERIC(20,2),
	ytd_value NUMERIC(20,2),fin_year VARCHAR(5))
	
	SELECT @dFromDt=@dFromDtPara
	SET @bFirstDate=1	
	
	SET @cStep='20'
	SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dFromDtPara)

	SET @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)

	INSERT INTO #temp_wow_ftdmtdytd_sales (xn_dt,mode,dept_id,ftd_value)
	SELECT cm_dt,1 mode,location_code/*LEFT(cm_id,2)*//*Rohit 05-11-2024*/ dept_id,SUM(net_amount) ftd_value
	FROM cmm01106 (NOLOCK) WHERE cm_dt BETWEEN @dFinYearFromDt AND @dToDtPara
	GROUP BY cm_dt,location_code/*left(cm_id,2)*//*Rohit 05-11-2024*/

	SET @cStep='30'
	UPDATE #temp_wow_ftdmtdytd_sales SET fin_year=dbo.FN_GETFINYEARDATE('01'+dbo.FN_GETFINYEAR(xn_dt),1)

	UPDATE a SET mtd_value=(SELECT sum(ftd_value) from #temp_wow_ftdmtdytd_sales b
	where month(b.xn_dt)=month(a.xn_dt) AND year(a.xn_dt)=year(b.xn_dt) AND b.dept_id=a.dept_id AND b.xn_dt<=a.xn_dt) from #temp_wow_ftdmtdytd_sales a

	SET @cStep='40'
	UPDATE a SET ytd_value=(SELECT sum(ftd_value) from #temp_wow_ftdmtdytd_sales b
	where b.fin_year=a.fin_year and b.dept_id=a.dept_id AND  b.xn_dt<=a.xn_dt) from #temp_wow_ftdmtdytd_sales a


	IF @bCalledfromReporting=1
	BEGIN
		INSERT INTO #tmpFTDMTDYTDBuild (dept_id, ftd_value, mtd_value,ytd_value)
		SELECT dept_id, ftd_value, mtd_value,ytd_value FROM  #temp_wow_ftdmtdytd_sales 
		WHERE xn_dt=@dToDtPara

		RETURN	
	END

	SELECT @dFromDt=@dFromDtPara
	SET @bFirstDate=1	
	
	
	SET @cStep='50'
	WHILE @dFromDt<=@dToDtPara
	BEGIN
		SET @cStep='60'
		PRINT 'Building data for Date :'+convert(varchar,@dFromDt,105)

		SET @cTable = db_name()+'_pmt.dbo.wow_ftdmtdytd_sales_'+CONVERT(VARCHAR,@dFromDt,112)

		IF OBJECT_ID(@cTable,'U') IS NULL
			SET @cCmd=N'create table '+@cTable+' (dept_id varchar(5),ftd_value numeric(14,2),mtd_value numeric(20,2),'+
					    'ytd_value numeric(20,2))'
		ELSE
			SET @cCmd=N'TRUNCATE TABLE '+@cTable
		
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='70'
		SET @cCmd=N'INSERT INTO '+@cTable+' (dept_id,ftd_value, mtd_value,ytd_value)
					SELECT dept_id, ftd_value, mtd_value,ytd_value FROM  #temp_wow_ftdmtdytd_sales
					WHERE xn_dt='''+CONVERT(VARCHAR,@dFromDt,110)+''''
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @dFromDt=@dFromDt+1
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPWOW_BUILD_FTDMTDYTD_SALES at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:
SELECT @cErrormsg errmsg
END
