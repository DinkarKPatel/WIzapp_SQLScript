CREATE PROCEDURE SPDB_PERFORMANCE_ANALYSIS
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cSetupIdPara VARCHAR(10)='',
@cErrormsg VARCHAR(MAX) OUTPUT
WITH ENCRYPTION
AS
BEGIN
	DECLARE @dCutoffDate DATETIME,@cDashBoardDbName VARCHAR(300),
	@CFILEPATH VARCHAR(500),@CCMD NVARCHAR(MAX),@CCMD1 NVARCHAR(MAX),@cDbTableNameXnDt VARCHAR(200),@bLoop BIT,@cSetupId VARCHAR(10),
	@cParaName VARCHAR(max),@cFilter VARCHAR(MAX),@cPmtTableName VARCHAR(500),@dLyXnDt DATETIME,
	@cFinyear VARCHAR(5),@cPrevFinyear VARCHAR(5),@cMonth VARCHAR(3),
	@cPrevPmtTableName VARCHAR(200),
	@bDonotPopData BIT,@dFinyearFromDt DATETIME,@NDAYSCNT NUMERIC(5,2),@NdAYScNTSTD NUMERIC(5,2),@cStep varchar(5),@cSetupName VARCHAR(300),
	@dFirstDateCurMonth DATETIME,@NdAYScNTMTD NUMERIC(5,2),@cHavingFilter VARCHAR(500),@cOrgHavingFilter VARCHAR(500),@dSeasondEndDt DATETIME,
	@cWC VARCHAR(1000),@cPrevWC VARCHAR(1000),@nInnerLoop NUMERIC(1,0),@bSeasonApplicable BIT,@dMonthFromDt DATETIME,@cGrpParaname VARCHAR(200),
	@dAdiFromDt DATETIME,@nCntLoop NUMERIC(1,0),@bFirstAdi BIT,@cAdiInsCols VARCHAR(1000),@cAdiInsColsVal VARCHAR(1000),
	@cAdiUpdCols VARCHAR(1000),@cAdiColsVal VARCHAR(100),@dMinXndt DATETIME,@dFirstPurDt DATETIME,@dFirstSaleDt DATETIME,@cText VARCHAR(500),
	@nEndLoopCnt NUMERIC(1,0) ,@cDtFilter VARCHAR(500),@dStartBuildDt DATETIME
	
BEGIN TRY		
	SET @cStep='10'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	SET @cErrormsg=''	
	SET @dStartBuildDt=@dFromDt
	IF NOT EXISTS (SELECT TOP 1 * FROM pos_dynamic_dashboard_setup (NOLOCK) WHERE dashboard_mode=3)
	BEGIN
		GOTO END_PROC
	END

	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	IF @dToDt=''
		SET @dToDt=CONVERT(DATE,GETDATE()-1)	

	
	IF OBJECT_ID('tempdb..#tmpDbSetup','U') IS NOT NULL
		DROP TABLE #tmpDbSetup

	SELECT setup_id,para_name,filter_criteria,setup_name,additional_filter_criteria INTO #tmpDbSetup 
	FROM pos_dynamic_dashboard_setup WHERE 1=2
	
	SET @cStep='15'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	SET @bLoop=0
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
		
	DECLARE @dSeasonStartDt DATETIME,@nDisplayMode NUMERIC(1,0),@CStdStr VARCHAR(MAX),@cPrevStdStr VARCHAR(MAX),
	@CMtdStr VARCHAR(MAX),@cPrevMtdStr VARCHAR(MAX),@cYtdStr VARCHAR(MAX),@cPrevYtdStr VARCHAR(MAX)


	IF OBJECT_ID('tempdb..#pos_dynamic_dbdata','u') IS NOT NULL
		DROP TABLE #pos_dynamic_dbdata

	CREATE TABLE #pos_dynamic_dbdata (para_name varchar(1000),sold_qty NUMERIC(20,2),nrv numeric(20,2),profit numeric(20,2),
									  net_sold_qty NUMERIC(20,2),asd numeric(20,0),cbs_qty NUMERIC(20,2),
	sell_thru numeric(10,2))
								
	SET @cStep='18'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	SELECT TOP 1 @cParaName=para_name,@cFilter=filter_criteria,@cSetupname=setup_name,
	@cOrgHavingFilter=ISNULL(additional_filter_criteria,'')
	FROM pos_dynamic_dashboard_setup (NOLOCK) WHERE setup_id=@cSetupIdPara
			
	IF @cFilter=''
		SET @cFilter='1=1'
	
	SET @cGrpParaname=@cParaName

	IF @cParaName='dept_name'
		SELECT @cParaName='location.dept_id+''-''+dept_name',@cGrpParaname='location.dept_id,dept_name'
	ELSE
	IF @cParaName='dept_id'
		SELECT @cParaName='location.dept_id',@cGrpParaname='location.dept_id'
	ELSE
	IF @cParaName='POSDB_PRICECATEGORY'
		SELECT @cParaName='category_name',@cGrpParaname='CATEGORY_NAME',@cFilter=' sn.mrp BETWEEN mrp_from AND mrp_to'
		
	SET @cFilter=REPLACE(@cFilter,'dept_id','location.dept_id')
						
	
	
	SELECT @cWC=' b.CM_DT BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+'''	AND  '''+CONVERT(VARCHAR,@dToDt,110)+''''					

	SET @cStep='55'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	
	SET @cPmtTableName=DB_NAME()+'_PMT.dbo.pmtlocs_'+CONVERT(VARCHAR,@DtOdT,112)
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	SET @CCMD=N'SELECT '+@cParaName+' as para_name,
				SUM(a.quantity) AS sold_qty,sum(quantity*selling_days) AS asd
				FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				JOIN location (NOLOCK) On location.dept_id=LEFT(b.cm_id,2)				
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code			
				WHERE  '+@cWC+' AND b.cancelled=0 and quantity>0
				AND '+@cFilter+' GROUP BY '+@cGrpParaname+' HAVING SUM(a.quantity)>0'
		
	PRINT @cCmd

	INSERT #pos_dynamic_dbdata (para_name,sold_qty,asd)
	EXEC SP_EXECUTESQL @cCmd	

	SET @cStep='58'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	SET @cStep='60'
	SET @CCMD=N'SELECT '+@cParaName+' as para_name,
				SUM(a.quantity) AS net_sold_qty,sum(rfnet) as nrv,sum(rfnet-(a.quantity*(ISNULL(a.net_payable,sn.pp)-isnull(fdn.pp,0)))) as profit
				FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				JOIN location (NOLOCK) On location.dept_id=LEFT(b.cm_id,2)				
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code			
				LEFT OUTER JOIN 
				(SELECT product_code,SUM(purchase_price) as pp FROM 
					rmd01106 a (NOLOCK) 
					JOIN rmm01106 b (NOLOCK) ON a.rm_id=b.rm_id 
					WHERE cancelled=0 AND dn_type=2		
					GROUP BY product_code												
				) fdn ON fdn.product_code=a.product_code
				WHERE  '+@cWC+' AND b.cancelled=0
				AND '+@cFilter+' GROUP BY '+@cGrpParaname+' HAVING SUM(a.quantity)<>0'
		
	PRINT @cCmd

	INSERT #pos_dynamic_dbdata (para_name,net_sold_qty,nrv,profit)
	EXEC SP_EXECUTESQL @cCmd	
	SET @cStep='62'					
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)

	UPDATE a SET 
	asd = (CASE WHEN sold_qty<>0 THEN asd/sold_qty ELSE 0 END)
	FROM #pos_dynamic_dbdata a
	where isnull(sold_qty,0)<>0

	SET @cStep='65'					
	SET @cCmd=N'UPDATE a SET 
	sell_thru=(CASE WHEN (b.net_sold_qty+isnull(c.cbs_qty,0))<>0 THEN (b.net_sold_qty/(b.net_sold_qty+isnull(c.cbs_qty,0)))*100.0 ELSE 0 END),
	cbs_qty=isnull(c.cbs_qty,0),nrv=b.nrv,profit=b.profit
	FROM #pos_dynamic_dbdata a
	JOIN #pos_dynamic_dbdata b ON a.para_name=b.para_name
	LEFT OUTER JOIN (SELECT '+@cParaName+' as para_name,sum(pmt.cbs_qty) as cbs_qty from 
		  '+@cPmtTableName+' PMT (nolock)
		  JOIN sku_names sn(NOLOCK) ON sn.product_code=pmt.product_code
		  WHERE '+@cFilter+'
		  GROUP BY '+@cParaName+') c  on c.para_name=a.para_name
	WHERE isnull(a.net_sold_qty,0)=0 and isnull(b.net_sold_qty,0)<>0'
	
	PRINT	@cCmd
	EXEC SP_EXECUTESQL @cCmd	

	SET @cStep='70'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	SELECT para_name,nrv,profit,asd,sell_thru,cbs_qty,ntile(5) over (order by nrv) as nrv_rank,ntile(5) over (order by profit) as profit_rank,
	ntile(5) over (order by asd desc) as asd_rank,ntile(5) over (order by sell_thru) as sell_thru_rank
	INTO #Final_data FROM #pos_dynamic_dbdata
	where sold_qty<>0

	SELECT para_name,nrv,profit,asd,sell_thru,cbs_qty,nrv_rank,asd_rank,sell_thru_rank,profit_rank,convert(numeric(2,0),(nrv_rank+asd_rank+sell_thru_rank+profit_rank)) abcd_score,
	ntile(4) over (order by nrv_rank+asd_rank+sell_thru_rank+profit_rank desc) as abcd_rank,convert(varchar(50),'') as abcd_category
	INTO #Final_data_abcd FROM #Final_data

	SET @cStep='75'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	UPDATE #Final_data_abcd set abcd_category=(CASE WHEN abcd_rank=4 THEN 'BRONZE' WHEN abcd_rank=1 THEN 'DIAMOND'
	WHEN abcd_rank=2 THEN 'GOLD'  ELSE 'SILVER' END) from #Final_data_abcd a


	UPDATE a set a.abcd_category='BRONZE' FROM #Final_data_abcd a 
	JOIN (select min(abcd_score) as abcd_score from #Final_data_abcd where abcd_category='BRONZE')
	b ON a.abcd_score=b.abcd_score
	where a.abcd_category<>'BRONZE'

	set @CsTEP='80'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)

	UPDATE a set a.abcd_category='DIAMOND' FROM #Final_data_abcd a 
	JOIN (select min(abcd_score) as abcd_score from #Final_data_abcd where abcd_category='DIAMOND')
	b ON a.abcd_score=b.abcd_score
	where a.abcd_category<>'DIAMOND'

	UPDATE a set a.abcd_category='GOLD' FROM #Final_data_abcd a 
	JOIN (select min(abcd_score) as abcd_score from #Final_data_abcd where abcd_category='GOLD')
	b ON a.abcd_score=b.abcd_score
	where a.abcd_category<>'GOLD'

	SET @cStep='85'

	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	UPDATE a set a.abcd_category='SILVER' FROM #Final_data_abcd a 
	JOIN (select min(abcd_score) as abcd_score from #Final_data_abcd where abcd_category='SILVER')
	b ON a.abcd_score=b.abcd_score
	where a.abcd_category<>'SILVER'

	SET @cStep='90'
	print 'Executing SPDB_PERFORMANCE_ANALYSIS for SetupId:'+@cSetupIdPara+' step#'+@cStep+' '+convert(varchar,getdate(),113)
	INSERT #tPRfcRepData (setup_id ,para_name,nrv,profit,asd,sell_thru,cbs_qty , abcd_score ,
	nrv_rank,profit_rank ,asd_rank ,sell_thru_rank,abcd_percentage,abcd_category)
	SELECT @cSetupIdPara as	setup_id ,para_name,nrv,profit,asd,sell_thru,cbs_qty , abcd_score ,
	nrv_rank,profit_rank ,asd_rank ,sell_thru_rank,convert(numeric(6,2),(abcd_score/20)*100) as abcd_percentage,abcd_category
	from #Final_data_abcd
	
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPDB_abcd_ANALYSIS at step#'+@cStep+' '+ERROR_MESSAGE()
END CATCH

END_PROC:
END