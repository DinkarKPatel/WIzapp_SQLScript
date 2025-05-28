CREATE PROCEDURE SPWOW_FWMY_REP
@nViewMode INT, --- (1.FTD 2.WTD 3.MTD 4.YTD)
@dReportingDate DATETIME,
@cLoginUserId CHAR(7)='0000000',
@cUserCode CHAR(7)='',
@cLocId VARCHAR(4)='',
@cKpiName VARCHAR(20)='',
@cDrillDownColName varchar(50)='',
@cDrillDownColHeader varchar(50)='',
@cDrillDownFilter varchar(1000)=''
AS
BEGIN
    Declare  @cTablewow varchar(200),@cTableWowPrevYear VARCHAR(200),@cCMD NVARCHAR(MAX),@cFinYear VARCHAR(10),
	@dFinYearFromDt DATETIME,@dMonthFromdt DATETIME,@cPrefix VARCHAR(10),@dFromDt DATETIME,@cMonth VARCHAR(10),@nLoop INT,
	@nDays INT,@cCmdPeriodWiseSale NVARCHAR(MAX),@dXnDt DATETIME,@cStep VARCHAR(5),@cDateFilter VARCHAR(200),@cFilter VARCHAR(MAX),
	@cCmdPaymodeWiseSale NVARCHAR(MAX),@cErrormsg VARCHAR(1000),@cDrillDownColExpr VARCHAR(200),@cDrillDownGrpExpr VARCHAR(250),
	@cJoinTaggedLocs VARCHAR(200) 

BEGIN TRY	
	SET @cStep='5'

	set datefirst 1
	CREATE TABLE #tmpDbData (paraName varchar(500),netRealizedValCy numeric(16,0),netRealizedValLy numeric(16,0),salesQtyCy numeric(16,0),salesQtyLy numeric(16,0),
	noOfBillsCy numeric(16,0),noOfBillsLy numeric(16,0),noOfPosCy numeric(16,0),noOfPosLy numeric(16,0),
	totalSqftAreaCy numeric(16,0),totalSqftAreaLy numeric(16,0),salesPerPosCy numeric(16,0),salesPerPosLy numeric(16,0),
	salesPerPosPerDayCy numeric(16,0),salesPerPosPerDayLy numeric(16,0),slsValPerSqFtCy numeric(16,0),slsValPerSqFtLy numeric(16,0),
	slsValPerSqFtPerDayCy numeric(16,0),slsValPerSqFtPerDayLy numeric(16,0),absCy numeric(16,1),absLy numeric(16,1),
	atsCy numeric(16,0),atsLy numeric(16,0),aspCy numeric(16,0),aspLy numeric(16,0))

	SET @cStep='7'
	CREATE TABLE #tmpTaggedLocs (dept_id VARCHAR(4),dept_alias varchar(50),dept_name VARCHAR(400),city varchar(400),state varchar(400))

	IF @cLoginUserId='0000000'
		INSERT INTO #tmpTaggedLocs (dept_id,dept_alias,dept_name,city,state)
		SELECT dept_id,dept_alias,dept_name,city,state FROM location a (NOLOCK) JOIN area (NOLOCK) ON area.area_code=a.area_code
		JOIN city (NOLOCK) ON city.CITY_CODE=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code
	ELSE
		INSERT INTO #tmpTaggedLocs (dept_id,dept_alias,dept_name,city,state)
		SELECT a.dept_id,dept_alias,dept_name,city,state FROM locrepuser A(NOLOCK)
		join LOCATION B ON b.dept_id=a.dept_id
		JOIN area (NOLOCK) ON area.area_code=b.area_code
		JOIN city (NOLOCK) ON city.CITY_CODE=area.city_code JOIN state (NOLOCK) ON state.state_code=city.state_code
		WHERE user_code=@cLoginUserId
	
	CREATE TABLE #tmpLocs (dept_id varchar(4),yearMode INT)
	
	CREATE TABLE #tmpPeriod (weekNoStr varchar(20),LastYearDates varchar(30),CurrentYearDates varchar(30))

	CREATE TABLE #tmpPaymodeWiseSale (payModeName varchar(100),amountCy NUMERIC(14,0),amountLy NUMERIC(14,0))

	SET @cStep='10'
    
	SELECT @cCmdPeriodWiseSale='',@cCmdPaymodeWiseSale=''
	SET @dXnDt=@dReportingDate
	declare @WeekNum int,@YearNum varchar(10),@weekDay INT,@weekDayName VARCHAR(15),@dFromDtLy DATETIME,
	@dFromDtCy DATETIME

	SET @cJoinTaggedLocs= ' JOIN #tmpTaggedLocs location on location.dept_id=b.location_code'
	if @cDrillDownColName LIKE '%locattr%'
		SET @cJoinTaggedLocs= @cJoinTaggedLocs+' JOIN loc_names (NOLOCK) ON loc_names.dept_id=b.location_code'
		
	SELECT @WeekNum= datepart(ww,@dXndt),@weekDay=datepart(weekday,@dXnDt),@weekDayName=datename(weekday,@dXndt),
	@YearNum=datepart(yy,@dXnDt),@dFromDt=@dReportingDate

	
	SET @nLoop=1
	WHILE @nLoop<=2
	BEGIN
		SET @cStep='30'
			
		IF @nLoop=2
			SELECT @dFromDtLy = @dFromDt, @YearNum= datepart(yy,dateadd(yy,-1,@dXndt)),@dXnDt=DATEADD(YY,-1,@dXnDt)
		
		IF @nViewMode IN (2)
			select @dXnDt=dbo.fnWOw_GetWeekSerial(@YearNum,@WeekNum,@weekDay)


		IF @nViewMode=4
		BEGIN
			SET @cFinYear='01'+dbo.FN_GETFINYEAR(@dXnDt)

			SET @cStep='32'
			SELECT @dFinYearFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)
		END

		SET @dFromDt=(CASE WHEN @nViewMode=1 THEN @dXnDt WHEN @nViewMode=2 THEN dbo.fnWOw_GetWeekSerial(@YearNum,@WeekNum,1)
						   WHEN @nViewMode=3 THEN CONVERT(DATE,ltrim(rtrim(str(YEAR(@dXnDt))))+'-'+ltrim(rtrim(str(month(@dXnDt))))+'-01')
						   ELSE @dFinYearFromDt END) 	

		

		IF @nLoop=2 
		BEGIN
			IF @nViewMode=1
			BEGIN
				INSERT INTO #tmpPeriod (weekNoStr,LastYearDates,CurrentYearDates)
				SELECT ltrim(rtrim(str(@WeekNum)))+' '+@weekDayName,format(@dXnDt,'dd-MMM-yyyy'),format(@dReportingDate,'dd-MMM-yyyy') 
			END
			ELSE
			BEGIN
				INSERT INTO #tmpPeriod (weekNoStr,LastYearDates,CurrentYearDates)
				SELECT ltrim(rtrim(str(@WeekNum)))+' '+@weekDayName,format(@dFromDt,'dd-MMM-yyyy')+' to '+format(@dXnDt,'dd-MMM-yyyy'),
				format(@dFromDtLy,'dd-MMM-yyyy')+' to '+format(@dReportingDate,'dd-MMM-yyyy')
			END
		END		 

		--select @dFromDt,@nLoop,@dXnDt

		SELECT @cDateFilter=N'b.cm_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+ CONVERT(VARCHAR,@dXnDt,110)+''''

		SET @cFilter=@cDateFilter+(CASE WHEN @cUserCode<>'' THEN ' AND user_code='''+@cUserCode+'''' ELSE '' END)+
		(CASE WHEN @cLocId<>'' THEN ' AND b.location_code='''+@cLocId+'''' ELSE '' END)
		
		SELECT @cDrillDownColExpr=''''' paraName,',@cDrillDownGrpExpr=''

		IF @cKpiName<>''
		BEGIN
		    IF @cDrillDownColName=''
				SELECT @cDrillDownColName='dept_alias',@cDrillDownColHeader='Loc Alias'
		    
			IF @cDrillDownFilter<>'' AND @nLoop=1
				SET @cDrillDownFilter=' AND '+@cDrillDownFilter
			
			SELECT @cDrillDownColExpr=@cDrillDownColName+' paraname,',@cDrillDownGrpExpr=' GROUP BY '+@cDrillDownColName
		END
	

		SET @cStep='40'
		IF (@cKpiName='' OR  @cDrillDownColName IN ('dept_name','dept_alias','dept_id')) AND @cDrillDownFilter=''
			SET @cCmdPeriodWiseSale=@cCmdPeriodWiseSale+(CASE WHEN @nLoop=1 THEN '' ELSE ' UNION ALL ' END)+
				N'SELECT '+@cDrillDownColExpr+(CASE WHEN @nLoop=1 THEN 'sum(net_amount) netRealizedValCy,count(cm_id) noOfBillsCy,
				sum(TOTAL_QUANTITY) salesQtyCy,0 netRealizedValLy,0 salesQtyLy,0 noOfBillsLy'
				ELSE '0 netRealizedValCy,0 noOfBillsCy,0 salesQtyCy,sum(net_amount) netRealizedValLy,sum(TOTAL_QUANTITY) salesQtyLy,count(cm_id) noOfBillsLy'
				END)+' FROM cmm01106  b  (NOLOCK) '+@cJoinTaggedLocs+' WHERE '+@cFilter+' AND cancelled=0'+@cDrillDownFilter+' '+@cDrillDownGrpExpr
		ELSE
			SET @cCmdPeriodWiseSale=@cCmdPeriodWiseSale+(CASE WHEN @nLoop=1 THEN '' ELSE ' UNION ALL ' END)+
				N'SELECT '+@cDrillDownColExpr+(CASE WHEN @nLoop=1 THEN 'sum(rfnet) netRealizedValCy,count(distinct b.cm_id) noOfBillsCy,
				sum(quantity) salesQtyCy,0 netRealizedValLy,0 salesQtyLy,0 noOfBillsLy'
				ELSE '0 netRealizedValCy,0 noOfBillsCy,0 salesQtyCy,sum(rfnet) netRealizedValLy,sum(quantity) salesQtyLy,count(distinct b.cm_id) noOfBillsLy'
				END)+' FROM cmd01106  a (NOLOCK) JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id '+@cJoinTaggedLocs+
				' JOIN sku_names (NOLOCK) ON sku_names.product_code=a.product_code WHERE '+@cFilter+' AND cancelled=0'+@cDrillDownFilter+' '+@cDrillDownGrpExpr
		SET @cStep='50'
		SET @cCmd=N'SELECT distinct LEFT(cm_id,2),'+STR(@nLoop)+' yearMode FROM cmm01106 b (NOLOCK) WHERE '+@cFilter
		INSERT #tmpLocs(dept_id,yearMode)
		EXEC SP_EXECUTESQL @cCmd

		IF @cKpiName=''
		BEGIN
			SET @cCmdPaymodeWiseSale=@cCmdPaymodeWiseSale+(CASE WHEN @nLoop=1 THEN '' ELSE ' UNION ALL ' END)+
				N'SELECT  paymode_grp_Name paymodeName,'+(CASE WHEN @nLoop=1 THEN 'sum(amount) amountCy,0 amountLy'
				ELSE '0 amountCy,sum(amount) amountLy'
				END)+' FROM cmm01106  b (NOLOCK) ' +@cJoinTaggedLocs+' JOIN paymode_xn_det a (NOLOCK) ON b.cm_id=a.memo_id
				JOIN paymode_mst c (NOLOCK) ON c.paymode_code=a.paymode_code
				JOIN paymode_grp_mst d (NOLOCK) ON d.paymode_grp_code=c.paymode_grp_code WHERE '+@cFilter+' AND cancelled=0
				GROUP BY paymode_grp_Name'
		END
		
		SET @nLoop=@nLoop+1
	END

	print @cCmdPeriodWiseSale
	SET @cStep='63'
	SET @cCmdPeriodWiseSale=N'SELECT  paraName,sum(netRealizedValCy),sum(salesQtyCy),sum(noOfBillsCy),
		   sum(netRealizedValLy),sum(salesQtyLy),sum(noOfBillsLy)
			FROM ('+@cCmdPeriodWiseSale+') a GROUP BY paraName'
	PRINT @cCmdPeriodWiseSale
	INSERT INTO #tmpDbData (paraName,netRealizedValCy,salesQtyCy,noOfBillsCy,netRealizedValLy,salesQtyLy,noOfBillsLy)
	EXEC SP_EXECUTESQL @cCmdPeriodWiseSale
	
	IF @cKpiName=''
	BEGIN
		SET @cStep='65'
		SET @cCmdPaymodeWiseSale=N'SELECT paymodeName,sum(amountCy),sum(amountLy)
				FROM ('+@cCmdPaymodeWiseSale+') a GROUP BY paymodeName'
	
		PRINT @cCmdPaymodeWiseSale
		INSERT INTO #tmpPaymodeWiseSale (payModeName,amountCy,amountLy)
		EXEC SP_EXECUTESQL @cCmdPaymodeWiseSale
	END
	
	IF @cKpiName IN ('','noOfPos','totalSqftArea') OR @cKpiName LIKE '%perpos%' or @cKpiName LIKE '%PerSqFt%'
	BEGIN
		SET @cStep='70'

		IF @cKpiName=''
			UPDATE a SET noOfPosCy=b.noOfPosCy,totalSqftAreaCy=b.totalSqftAreaCy,
			noOfPosLy=b.noOfPosLy,totalSqftAreaLy=b.totalSqftAreaLy
			FROM #tmpDbData a
			JOIN (SELECT sum(case when yearMode=1 then 1 else 0 end) noOfPosCy,sum(case when yearMode=2 then 1 else 0 end) noOfPosLy,
				 sum(case when yearMode=1 then isnull(b.area_covered,0) else 0 end) totalSqftAreaCy,
				 sum(case when yearMode=2 then isnull(b.area_covered,0) else 0 end) totalSqftAreaLy 
			  from #tmpLocs a JOIN location b ON a.dept_id=b.dept_id) b ON 1=1
		ELSE
		BEGIN
			
			--if @@spid=443
			--select 'check #tmpLocs',* from #tmpLocs

			UPDATE a SET noOfPosCy=b.noOfPosCy,totalSqftAreaCy=b.totalSqftAreaCy,
			noOfPosLy=b.noOfPosLy,totalSqftAreaLy=b.totalSqftAreaLy
			FROM #tmpDbData a
			JOIN (SELECT b.dept_alias,sum(case when yearMode=1 then 1 else 0 end) noOfPosCy,sum(case when yearMode=2 then 1 else 0 end) noOfPosLy,
				 sum(case when yearMode=1 then isnull(b.area_covered,0) else 0 end) totalSqftAreaCy,
				 sum(case when yearMode=2 then isnull(b.area_covered,0) else 0 end) totalSqftAreaLy 
			  from #tmpLocs a JOIN location b ON a.dept_id=b.dept_id GROUP BY b.dept_alias) b ON a.paraName=b.dept_alias
		END

	END

	SET @cStep='75'
	IF @nViewMode=1
		SET @nDays=1
	ELSE
	IF @nViewMode=2
		SET @nDays=DateDiff(dd,@dFromDt,@dXnDt)+1
	ELSE
	IF @nViewMode=3
		SET @nDays=Datepart(dd,@dXnDt)
	ELSE
	IF @nViewMode=4
	BEGIN
		SET @dFinYearFromDt=dbo.Fn_getfinYeardate('01'+dbo.fn_getfinyear(@dXnDt),1)
		SET @nDays=Datediff(dd,@dFinYearFromDt,@dXnDt)+1
	END
	--if @@spid=133
	--select @nLoop,@nDays,@dFromdt,@dXndt

	SET @cStep='80'
	SET @cCmd=(CASE WHEN @cKpiName IN ('','abs') THEN 'absCy=(CASE WHEN noOfBillsCy<>0 THEN (convert(numeric(16,1),salesQtyCy)/convert(numeric(16,1),noOfBillsCy)) else 0 end),
	absLy=(CASE WHEN noOfBillsLy<>0 THEN (convert(numeric(16,1),salesQtyLy)/convert(numeric(16,1),noOfBillsLy)) else 0 end)' ELSE '' END)

	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','ats') THEN (CASE WHEN @cCmd<>'' then ',' ELSE '' END)+'atsCy=(CASE WHEN noOfBillsCy<>0 THEN (convert(numeric(16,0),netRealizedValCy)/convert(numeric(16,0),noOfBillsCy)) else 0 end),
	atsLy=(CASE WHEN noOfBillsLy<>0 THEN (convert(numeric(16,0),netRealizedValLy)/convert(numeric(16,0),noOfBillsLy)) else 0 end)' ELSE '' END)

	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','asp') THEN (CASE WHEN @cCmd<>'' then ',' ELSE '' END)+
	'aspCy=(CASE WHEN salesQtyCy<>0 THEN (convert(numeric(16,0),netRealizedValCy)/convert(numeric(16,0),salesQtyCy)) else 0 end),
	aspLy=(CASE WHEN salesQtyLy<>0 THEN (convert(numeric(16,0),netRealizedValLy)/convert(numeric(16,0),salesQtyLy)) else 0 end)' ELSE '' END)
	
	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','salesPerPos') THEN (CASE WHEN @cCmd<>'' then ',' ELSE '' END)+
	'salesPerPosCy=netRealizedValCy/(CASE WHEN noOfPosCy=0 or '''+@cKpiName+'''<>'''' THEN 1 ELSE noOfPosCy END),
	salesPerPosLy=netRealizedValLy/(CASE WHEN noOfPosLy=0 or '''+@cKpiName+'''<>'''' THEN 1 ELSE noOfPosLy END)' ELSE '' END)

	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','salesPerPosPerDay') THEN (CASE WHEN @cCmd<>'' then ',' ELSE '' END)+
	'salesPerPosPerDayCy=netRealizedValCy/(CASE WHEN noOfPosCy=0 or '''+@cKpiName+'''<>'''' THEN 1 ELSE noOfPosCy END)/'+str(@nDays)+',
	salesPerPosPerDayLy=netRealizedValLy/(CASE WHEN noOfPosLy=0 or '''+@cKpiName+'''<>'''' THEN 1 ELSE noOfPosLy END)/'+str(@nDays) ELSE '' END)

	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','slsValPerSqFt') THEN 
	(CASE WHEN @cCmd<>'' then ',' ELSE '' END)+'slsValPerSqFtCy=netRealizedValCy/(CASE WHEN totalSqftAreaCy=0  THEN 1 ELSE totalSqftAreaCy END),
	slsValPerSqFtLy=netRealizedValLy/(CASE WHEN totalSqftAreaLy=0 THEN 1 ELSE totalSqftAreaLy END)' ELSE '' END)
	
	SET @cCmd=@cCmd+(CASE WHEN @cKpiName IN ('','slsValPerSqFtPerDay') THEN (CASE WHEN @cCmd<>'' then ',' ELSE '' END)+'slsValPerSqFtPerDayCy=netRealizedValCy/(CASE WHEN totalSqftAreaCy=0 THEN 1 ELSE totalSqftAreaCy END)/'+str(@nDays)+',
	slsValPerSqFtPerDayLy=netRealizedValLy/(CASE WHEN totalSqftAreaLy=0 THEN 1 ELSE totalSqftAreaLy END)/'+str(@nDays) ELSE '' END)
	
	IF @cCmd<>''
	BEGIN
		SET @cStep='90'
		SET @cCmd=N'UPDATE #tmpDbData set '+@cCmd

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END



	SET @cStep='95'

	SELECT * FROM #tmpPeriod


	--if @@spid=443
	--	select @ndays Days

	--select @cDrillDownColHeader finalcolheader
	IF @cKpiName=''
	BEGIN
		CREATE TABLE #tKpiNames (kpiName varchar(20),kpiDesc VARCHAR(100))
		INSERT INTO #tKpiNames (kpiName,kpiDesc)
		SELECT 'netRealizedVal','Net Realized Value' UNION ALL
		SELECT 'salesQty','Quantity' UNION ALL
		SELECT 'noOfBills','Bills' UNION ALL
		SELECT 'noOfPos','No. of Pos' UNION ALL
		SELECT 'totalSqftArea','Total Sq Ft Area' UNION ALL
		SELECT 'salesPerPos','Sales Per Pos' UNION ALL
		SELECT 'salesPerPosPerDay','Sales Per Pos Per Day' UNION ALL
		SELECT 'slsValPerSqFt','Sales Per Sq Ft' UNION ALL
		SELECT 'slsValPerSqFtPerDay','Sales Per Sq Ft Per Day' UNION ALL
		SELECT 'abs','Average Basket Size' UNION ALL
		SELECT 'ats','Average Ticket Size' UNION ALL
		SELECT 'asp','Average Selling Price' 

		SET @cCmd=N'SELECT a.kpiName,b.kpiDesc, cyFigure,lyFigure FROM 
		(SELECT ''netRealizedVal'' kpiName,netRealizedValCy cyFigure,netRealizedValLy lyFigure FROM #tmpDbData
		UNION ALL SELECT ''salesQty'' kpiName,salesQtyCy,salesQtyLy FROM #tmpDbData
		UNION ALL SELECT ''noOfBills'' kpiName ,noOfBillsCy,noOfBillsLy FROM #tmpDbData
		UNION ALL SELECT ''noOfPos'' kpiName ,noOfPosCy,noOfPosLy FROM #tmpDbData
		UNION ALL SELECT ''totalSqftArea'' kpiName ,totalSqftAreaCy,totalSqftAreaLy FROM #tmpDbData 
		UNION ALL SELECT ''salesPerPos'' kpiName ,salesPerPosCy,salesPerPosLy FROM #tmpDbData 
		UNION ALL SELECT ''salesPerPosPerDay'' kpiName ,salesPerPosPerDayCy ,salesPerPosPerDayLy FROM #tmpDbData 
		UNION ALL SELECT ''slsValPerSqFt'' kpiName ,slsValPerSqFtCy ,slsValPerSqFtLy FROM #tmpDbData 
		UNION ALL SELECT ''slsValPerSqFtPerDay'' kpiName ,slsValPerSqFtPerDayCy ,slsValPerSqFtPerDayLy FROM #tmpDbData 
		UNION ALL SELECT ''abs'' kpiName ,	absCy ,absLy FROM #tmpDbData 
		UNION ALL SELECT ''ats'' kpiName ,atsCy ,atsLy FROM #tmpDbData 
		UNION ALL SELECT ''asp'' kpiName ,aspCy ,aspLy FROM #tmpDbData ) a
		JOIN #tKpiNames b ON a.kpiName=b.kpiName'
	END
	ELSE
	BEGIN
		DECLARE @nTotCyValue NUMERIC(20,0),@nTotLyValue NUMERIC(20,0)

		SET @cCmd=N'SELECT @nTotCyValue=sum('+@cKpiName+'cy),@nTotLyValue=sum('+@cKpiName+'Ly)  FROM #tmpDbData'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nTotCyValue NUMERIC(20,2) OUTPUT,@nTotLyValue NUMERIC(20,2) output',@nTotCyValue OUTPUT,@nTotLyValue OUTPUT

		--if @@spid=443
		--	select @cDrillDownColHeader,@cKpiName,@nTotCyValue,@nTotLyValue,* from #tmpDbData

		SET @cCmd=N'SELECT paraName ['+@cDrillDownColHeader+'],'+@cKpiName+'Cy cyValue,(CASE WHEN '+str(@nTotCyValue)+'<>0 THEN CONVERT(NUMERIC(7,2),('+@cKpiName+'Cy/'+LTRIM(RTRIM(STR(@nTotCyValue)))+')*100) 
		ELSE 0 END) cyCntr,'+@cKpiName+'Ly lyValue,'+
		'(CASE WHEN '+str(@nTotLyValue)+'<>0 then CONVERT(NUMERIC(7,2),('+@cKpiName+'Ly/'+LTRIM(RTRIM(STR(@nTotLyValue)))+')*100) else 0 end) lyCntr FROM #tmpDbData ORDER BY paraName'
	END	
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	IF @cKpiName=''
		SELECT * FROM #tmpPaymodeWiseSale

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg= 'Error in Procedure SPWOW_FWMY_REP at Step#'+@cStep+' '+ERROR_MESSAGE();
	GOTO END_PROC
END CATCH

END_PROC:
	IF ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg errmsg

END