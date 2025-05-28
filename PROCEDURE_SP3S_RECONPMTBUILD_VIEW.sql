CREATE PROCEDURE SP3S_RECONPMTBUILD_VIEW
@cDbNamePara VARCHAR(200)=''
AS
BEGIN

	DECLARE @dFromDt DATETIME,@dToDt DATETIME,@cPmtTable VARCHAR(200),@cCmd NVARCHAR(MAX),@cDbName VARCHAR(200),@bFirst BIT,
			@cErrormsg varchar(max),@cStep VARCHAR(5),@cDbNamePrefix VARCHAR(100)

	SET @dToDt=CONVERT(DATE,GETDATE()-1)
	SET @dFromDt = DATEADD(yy,-1,@dToDt)


BEGIN TRY

	SET @cStep='10'
	IF @cDbNamePara=''
		SET @cDbName=db_name()
	ELSE
		SET @cDbName=@cDbNamePara

	set @cDbNamePrefix=@cDbName+'.dbo.'

	SET @cPmtTable=@cDbName+'_PMT.DBO.pmtlocs_'+CONVERT(VARCHAR,@dFromDt-1,112)

	CREATE TABLE #tmpPmtObs (dept_id VARCHAR(5),obs NUMERIC(20,3))

	CREATE TABLE #tmpPmtCbs (dept_id VARCHAR(5),cbs NUMERIC(20,3))

	SET @cStep='20'
	SET @cCmd=N'SELECT dept_id,sum(cbs_qty) FROM '+@cPmtTable+' GROUP BY dept_id'

	PRINT @cCmd
	INSERT INTO #tmpPmtObs (dept_id,obs)
	EXEC SP_EXECUTESQL @cCmd


	SET @cStep='30'
	CREATE TABLE #tmpXn (dept_id CHAR(2),xn_type VARCHAR(50),xn_dt datetime,xnqty NUMERIC(20,3))

	
	SET @cCmd=N'select dept_id,xn_type,xn_dt,sum(xn_qty) xnqty from '+@cDbNamePrefix+'vw_xnsreps where xn_dt between '''+CONVERT(varchar,@dFromDt,112)+
	''' and '''+convert(varchar,@dToDt,112)+'''	group by dept_id,xn_type,xn_dt'

	PRINT @cCmd
	INSERT INTO #tmpXn (dept_id,xn_type,xn_dt,xnqty)
	exec sp_executesql @cCmd

	SET @cStep='40'
	SELECT dept_id,xn_dt,sum(case when xn_type in ('PFI', 'WSR', 'APR', 'CHI', 'WPR', 'OPS', 'DCI', 'SCF', 'PUR', 'UNC', 'SLR',
	'JWR','DNPR','TTM','API','PRD', 'PFG', 'BCG','MRP','PSB','JWR','MIR','GRNPSIN','MAQ','OLOAQ','CNPI') 
	then 1 else -1 end * xnqty) CBSQty INTO #tmpCbsXns FROM #tmpXn
	WHERE xn_type NOT IN ('TRI', 'TRO','sac','sau','saum','sacm') 
	GROUP BY dept_id,xn_dt 

	
	SET @cStep='50'
	;WITH cteXns
	as
	(SELECT *,ROW_NUMBER() OVER (PARTITION BY dept_id order by xn_dt) rno from  #tmpCbsXns)

	select * into #tmpcbsXnsFinal from cteXns

	SET @cStep='45'
	UPDATE a SET cbsqty=b.obs+a.cbsqty FROM #tmpcbsXnsFinal a 
	JOIN #tmpPmtObs b ON a.dept_id=b.dept_id 
	WHERE a.rno=1


	CREATE TABLE #tmpDiff (dept_id CHAR(2), xn_dt DATETIME,cbs_xns NUMERIC(20,3),cbs_PMT NUMERIC(20,3))

	--select 'row wise data',* from #tmpcbsXnsFinal

	SET @bFirst = 1
	WHILE @dFromDt<=@dToDt
	BEGIN
		SET @cStep='60'
		TRUNCATE TABLE #tmpPmtCbs
		print 'COmparing pmt for Date :'+convert(varchar,@dFromdt,113)

		IF @bFirst=0
			UPDATE a SET cbsqty=b.cbsqty+a.cbsqty FROM #tmpcbsXnsFinal a 
			JOIN #tmpcbsXnsFinal b ON a.dept_id=b.dept_id 
			WHERE a.xn_dt=@dFromDt AND b.rno=a.rno-1
		
		SET @cStep='70'
		SET @cPmtTable=@cDbName+'_pmt..pmtlocs_'+CONVERT(VARCHAR,@dFromDt,112)

		SET @cCmd=N'SELECT dept_id,SUM(cbs_qty) cbs FROM '+@cPmtTable+' GROUP BY dept_id'
		
		INSERT INTO #tmpPmtCbs (dept_id,cbs)
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='75'
		INSERT INTO #tmpDiff (dept_id,xn_dt,cbs_xns,cbs_PMT)
		SELECT ISNULL(a.dept_id,b.dept_id) dept_id,@dFromDt xn_dt,a.cbsqty,b.cbs
		FROM #tmpcbsXnsFinal a FULL OUTER JOIN #tmpPmtCbs b ON a.dept_id=b.dept_id
		WHERE a.xn_dt=@dFromDt AND isnull(a.cbsQty,0)<>isnull(b.cbs,0)

		SET @dFromDt=@dFromDt+1
		SET @bFirst=0
	END

	SET @cStep='80'
	SET @cCmd=N'UPDATE a set report_blocked=(CASE WHEN b.dept_id IS NOT NULL THEN  1 ELSE 0 END)
	from '+@cDbNamePrefix+'location a left JOIN #tmpDiff b ON a.dept_id=b.dept_id'

	print @CcmD
	EXEC SP_EXECUTESQL @cCmd

	--SELECT * FROM #tmpDiff

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_RECONPMTBUILD_VIEW at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	SELECT ISNULL(@cErrormsg,'') errmsg
END