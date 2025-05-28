CREATE PROCEDURE SPDB_RFCC_ANALYSIS
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
	@cFinyear VARCHAR(5),@cPrevFinyear VARCHAR(5),@cMonth VARCHAR(3),@cPrevPmtTableName VARCHAR(200),
	@bDonotPopData BIT,@dFinyearFromDt DATETIME,@NDAYSCNT NUMERIC(5,2),@NdAYScNTSTD NUMERIC(5,2),@cStep varchar(5),@cSetupName VARCHAR(300),
	@dFirstDateCurMonth DATETIME,@NdAYScNTMTD NUMERIC(5,2),@cHavingFilter VARCHAR(500),@cOrgHavingFilter VARCHAR(500),@dSeasondEndDt DATETIME,
	@cWC VARCHAR(1000),@cPrevWC VARCHAR(1000),@nInnerLoop NUMERIC(1,0),@bSeasonApplicable BIT,@dMonthFromDt DATETIME,@cGrpParaname VARCHAR(200),
	@dAdiFromDt DATETIME,@nCntLoop NUMERIC(1,0),@bFirstAdi BIT,@cAdiInsCols VARCHAR(1000),@cAdiInsColsVal VARCHAR(1000),
	@cAdiUpdCols VARCHAR(1000),@cAdiColsVal VARCHAR(100),@dMinXndt DATETIME,@dFirstPurDt DATETIME,@dFirstSaleDt DATETIME,@cText VARCHAR(500),
	@nEndLoopCnt NUMERIC(1,0) ,@cDtFilter VARCHAR(500),@dStartBuildDt DATETIME,@cRfCcTableName VARCHAR(200),
	@cRfCcTableName1 VARCHAR(200),@cRfCcTableName2 VARCHAR(200),@cRepTable VARCHAR(100),
	@cParaNameStru VARCHAR(1000),@cParaNameCols VARCHAR(1000),@cJoinstr1 varchar(2000),@cJoinstr2 varchar(2000),@cParaDesc VARCHAR(200)
	
BEGIN TRY		
	SET @cStep='10'
	SET @cErrormsg=''	
	SET @dStartBuildDt=@dFromDt
	IF NOT EXISTS (SELECT TOP 1 * FROM pos_dynamic_dashboard_setup (NOLOCK) WHERE dashboard_mode=2)
	BEGIN
		GOTO END_PROC
	END

	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	IF @dToDt=''
		SET @dToDt=CONVERT(DATE,GETDATE()-1)	

	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	IF OBJECT_ID('tempdb..#tmpDbSetup','U') IS NOT NULL
		DROP TABLE #tmpDbSetup

	SELECT setup_id,para_name,filter_criteria,setup_name,additional_filter_criteria INTO #tmpDbSetup 
	FROM pos_dynamic_dashboard_setup WHERE 1=2
	
	SET @cStep='15'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	SET @bLoop=0

	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	
	DECLARE @tDbParas TABLE (master_col varchar(200),master_col_expr varchar(200))
		
	DECLARE @dSeasonStartDt DATETIME,@nDisplayMode NUMERIC(1,0),@CStdStr VARCHAR(MAX),@cPrevStdStr VARCHAR(MAX),
	@CMtdStr VARCHAR(MAX),@cPrevMtdStr VARCHAR(MAX),@cYtdStr VARCHAR(MAX),@cPrevYtdStr VARCHAR(MAX),
	@cParaNameFilter VARCHAR(1000),@cGrpParaNameFilter VARCHAR(1000)
	
								
	SET @cStep='18'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	SELECT TOP 1 @cFilter=filter_criteria,@cSetupname=setup_name,
	@cOrgHavingFilter=ISNULL(additional_filter_criteria,'')
	FROM pos_dynamic_dashboard_setup (NOLOCK) WHERE setup_id=@cSetupIdPara
	
	SELECT * INTO #pos_dynamic_dashboard_paras FROM pos_dynamic_dashboard_paras (NOLOCK)		
	WHERE setup_id=@cSetupIdPara

	IF @cFilter=''
		SET @cFilter='1=1'
	
	SELECT @cGrpParanameFilter='',@cParaNameFilter='',@cParaNameStru='',@cParaNameCols='',@cJoinStr1='',@cJoinStr2=''

	INSERT @tDbParas (master_col,master_col_expr)
	EXEC DBKPI_FILTER 3

	WHILE EXISTS (SELECT TOP 1 * FROM #pos_dynamic_dashboard_paras)
	BEGIN
		SET @cStep='22'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		SET @cParaDesc=''

		SELECT TOP 1 @cParaName=para_name,@cParaDesc=ISNULL(b.master_col,'')
		FROM #pos_dynamic_dashboard_paras a 
		LEFT OUTER JOIN @tDbParas b ON a.para_name=b.master_col_expr 
		ORDER BY col_order

		SET @cParaDesc='['+(CASE WHEN @cParaDesc='' THEN @cParaName ELSE @cParaDesc END)+']'
		SElect @cParaNameStru=@cParaNameStru+(CASE WHEN @cParaNameStru<>'' THEN ',' ELSE '' END)+@cParaDesc+' VARCHAR(1000)',
			   @cParaNameCols=@cParaNameCols+(CASE WHEN @cParaNameCols<>'' THEN ',' ELSE '' END)+@cParaDesc,
			   @cJoinStr1=@cJoinStr1+(CASE WHEN @cJoinStr1<>'' THEN ' AND ' ELSE '' END)+'a.'+@cParaDesc+'=b.'+@cParaDesc,
			   @cJoinStr2=@cJoinStr2+(CASE WHEN @cJoinStr2<>'' THEN ' AND ' ELSE '' END)+'a.'+@cParaDesc+'=c.'+@cParaName
		
		SET @cGrpParaname=@cParaName
		IF @cParaName='dept_name'
			SELECT @cParaName='location.dept_id+''-''+dept_name',@cGrpParaname='location.dept_id,dept_name'
		ELSE
		IF @cParaName='dept_id'
			SET @cParaName='location.dept_id'
		ELSE
		IF @cParaName='POSDB_PRICECATEGORY'
			SELECT @cParaName='category_name',@cGrpParaname='CATEGORY_NAME',@cFilter=@cFilter+' AND sn.mrp BETWEEN mrp_from AND mrp_to'
		
		SET @cStep='25'
		EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

		SELECT @cParaNameFilter=@cParaNameFilter+(CASE WHEN @cParaNameFilter<>'' THEN ',' ELSE '' END)+@cParaName,
			   @cGrpParaNameFilter=@cGrpParaNameFilter+(CASE WHEN @cGrpParaNameFilter<>'' THEN ',' ELSE '' END)+@cGrpParaName
		
		DELETE FROM #pos_dynamic_dashboard_paras WHERE para_name=@cParaName
	END

	SELECT @cRfCcTableName='rfcc_report_'+ltrim(rtrim(str(@@spid))),
		   @cRfCcTableName1='rfcc_report1_'+ltrim(rtrim(str(@@spid))),
		   @cRfCcTableName2='rfcc_report2_'+ltrim(rtrim(str(@@spid)))	

	IF OBJECT_ID(@cRfCcTableName,'u') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE '+@cRfCcTableName
		EXEC SP_EXECUTESQL @cCmd
	END

	IF OBJECT_ID(@cRfCcTableName1,'u') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE '+@cRfCcTableName1
		EXEC SP_EXECUTESQL @cCmd
	END

	IF OBJECT_ID(@cRfCcTableName2,'u') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE '+@cRfCcTableName2
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='32'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1

	SET @cCmd=N'CREATE TABLE '+@cRfCcTableName+'('+@cParaNameStru+',sold_qty NUMERIC(20,2),net_sold_qty NUMERIC(20,2),asd numeric(20,0),cbs_qty NUMERIC(20,2),
	sell_thru numeric(10,2))'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
			
	SET @cFilter=REPLACE(@cFilter,'dept_id','location.dept_id')
						
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	
	SELECT @cWC=' CM_DT BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+'''	AND  '''+CONVERT(VARCHAR,@dToDt,110)+''''					

	SET @cStep='55'
	EXEC SP_CHKXNSAVELOG 'posdb',@cSTEP,0,0,1
	
	SET @cPmtTableName=DB_NAME()+'_PMT.dbo.pmtlocs_'+CONVERT(VARCHAR,@DtOdT,112)
	print 'Start step:'+ @cStep+' '+convert(varchar,getdate(),113)
	SET @CCMD=N'INSERT '+@cRfCcTableName+'('+@cParaNameCols+',sold_qty,asd)
				SELECT '+@cParaNameFilter+',
				SUM(a.quantity) AS sold_qty,sum(quantity*selling_days) AS asd
				FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				JOIN location (NOLOCK) On location.dept_id=LEFT(b.cm_id,2)				
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code			
				WHERE  '+@cWC+' AND b.cancelled=0 and quantity>0
				AND '+@cFilter+' GROUP BY '+@cGrpParanameFilter+' HAVING SUM(a.quantity)>0'
		
	PRINT @cCmd

	EXEC SP_EXECUTESQL @cCmd	

	SET @CCMD=N'INSERT '+@cRfCcTableName+'('+@cParaNameCols+',net_sold_qty)
				SELECT '+@cParaNameFilter+',
				SUM(a.quantity) AS net_sold_qty
				FROM cmd01106 a (NOLOCK) 
				JOIN cmm01106 b (NOLOCK) ON a.cm_id=b.cm_id
				JOIN location (NOLOCK) On location.dept_id=LEFT(b.cm_id,2)				
				JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code			
				WHERE  '+@cWC+' AND b.cancelled=0
				AND '+@cFilter+' GROUP BY '+@cGrpParanameFilter+' HAVING SUM(a.quantity)<>0'
		
	PRINT @cCmd

	EXEC SP_EXECUTESQL @cCmd	
	SET @cStep='62'					

	SET @cCmd=N' UPDATE a SET 
	asd = (CASE WHEN sold_qty<>0 THEN asd/sold_qty ELSE 0 END)
	FROM '+@cRfCcTableName+' a where isnull(sold_qty,0)<>0'
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='65'					
	SET @cCmd=N'UPDATE a SET 
	sell_thru=(CASE WHEN (b.net_sold_qty+isnull(c.cbs_qty,0))<>0 THEN (b.net_sold_qty/(b.net_sold_qty+isnull(c.cbs_qty,0)))*100.0 ELSE 0 END),
	cbs_qty=isnull(c.cbs_qty,0)
	FROM '+@cRfCcTableName+' a
	JOIN '+@cRfCcTableName+' b ON '+@cJoinStr1+'
	LEFT OUTER JOIN (SELECT '+@cParaNameFilter+',sum(pmt.cbs_qty) as cbs_qty from 
		  '+@cPmtTableName+' PMT (nolock)
		  JOIN sku_names sn(NOLOCK) ON sn.product_code=pmt.product_code
		  WHERE '+@cFilter+'
		  GROUP BY '+@cGrpParaNameFilter+') c  on '+@cJoinstr2+'
	WHERE isnull(a.net_sold_qty,0)=0 and isnull(b.net_sold_qty,0)<>0'
	
	PRINT	@cCmd
	EXEC SP_EXECUTESQL @cCmd	

	SET @cStep='70'
	SET @cCmd=N'SELECT '+@cParaNameCols+',sold_qty,asd,sell_thru,cbs_qty,ntile(5) over (order by sold_qty) as sold_qty_rank,ntile(5) over (order by asd desc) as asd_rank,
	ntile(5) over (order by sell_thru) as sell_thru_rank
	INTO '+@cRfCcTableName1+' FROM '+@cRfCcTableName+'
	where sold_qty<>0'
	EXEC SP_EXECUTESQL @cCmd	

	SET @cStep='75'
	SET @cCmd=N'SELECT '+@cParaNameCols+',sold_qty,asd,sell_thru,cbs_qty,sold_qty_rank,asd_rank,sell_thru_rank,convert(numeric(2,0),(sold_qty_rank+asd_rank+sell_thru_rank)) rfcc_score,
	ntile(4) over (order by sold_qty_rank+asd_rank+sell_thru_rank desc) as rfcc_rank,convert(varchar(50),'''') as rfcc_category
	INTO '+@cRfCcTableName2+' FROM  '+@cRfCcTableName1
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='80'
	SET @cCmd=N'UPDATE '+@cRfCcTableName2+' set rfcc_category=(CASE WHEN rfcc_rank=1 THEN ''ROCKET'' 
	WHEN rfcc_rank=2 THEN ''F1'' WHEN rfcc_rank=3 THEN ''CART''  ELSE ''COFFIN'' END) 
	from '+@cRfCcTableName2+' a'
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='85'
	SET @cCmd=N'UPDATE a set a.rfcc_category=''ROCKET'' FROM '+@cRfCcTableName2+' a 
	JOIN (select min(rfcc_score) as rfcc_score from '+@cRfCcTableName2+' a where rfcc_category=''ROCKET'')
	b ON a.rfcc_score=b.rfcc_score
	where a.rfcc_category<>''ROCKET'''
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='90'
	SET @cCmd=N'UPDATE a set a.rfcc_category=''F1'' FROM  '+@cRfCcTableName2+' a 
	JOIN (select min(rfcc_score) as rfcc_score from  '+@cRfCcTableName2+' where rfcc_category=''F1'')
	b ON a.rfcc_score=b.rfcc_score
	where a.rfcc_category<>''F1'''
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='95'
	SET @cCmd=N'UPDATE a set a.rfcc_category=''CART'' FROM '+@cRfCcTableName2+' a 
	JOIN (select min(rfcc_score) as rfcc_score from '+@cRfCcTableName2+'  where rfcc_category=''CART'')
	b ON a.rfcc_score=b.rfcc_score
	where a.rfcc_category<>''CART'''
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='100'
	SET @cCmd=N'UPDATE a set a.rfcc_category=''COFFIN'' FROM '+@cRfCcTableName2+' a 
	JOIN (select min(rfcc_score) as rfcc_score from  '+@cRfCcTableName2+'  where rfcc_category=''COFFIN'')
	b ON a.rfcc_score=b.rfcc_score
	where a.rfcc_category<>''COFFIN'''

	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='105'
	SET @cRepTable='tRfCcRepData_'+@cSetupIdPara+'_'+ltrim(rtrim(str(@@spid)))

	IF OBJECT_ID(@cRepTable,'U') IS NOT NULL
	BEGIN
		SET @cCmd=N'DROP TABLE '+@cRepTable
		EXEC SP_EXECUTESQL @cCmd
	END

	SET @cStep='110'
	SET @cCmd=N'CREATE TABLE '+@cRepTable+'(setup_id char(7),'+@cParaNameStru+',sold_qty NUMERIC(20,2),asd NUMERIC(20,0),sell_thru NUMERIC(10,2),
							cbs_qty NUMERIC(20,2), rfcc_score numeric(4,0),sold_qty_rank numeric(4,0),
							asd_rank numeric(4,0),sell_thru_rank numeric(4,0),rfcc_percentage numeric(6,2),
							rfcc_category varchar(200),row_no INT IDENTITY)'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='115'
	SET @cCmd=N'INSERT INTO '+@cRepTable+' (setup_id,'+@cParaNameCols+',sold_qty,asd,sell_thru,cbs_qty, rfcc_score,
	sold_qty_rank,asd_rank,sell_thru_rank,rfcc_percentage,rfcc_category)
	SELECT  '''+@cSetupIdPara+''' as setup_id,'+@cParaNameCols+',sold_qty,asd,sell_thru,cbs_qty, rfcc_score,
	sold_qty_rank,asd_rank,sell_thru_rank,convert(numeric(6,2),(rfcc_score/15)*100) as rfcc_percentage,
	rfcc_category from '+@cRfCcTableName2+'
	ORDER BY rfcc_score desc,sold_qty desc,asd,sell_thru desc'
	EXEC SP_EXECUTESQL @cCmd

	SET @NDAYSCNT=DATEDIFF(DD,@dfromdt,@dToDt)+1

	SET @cStep='125'
	print 'step-125'+@cRepTable
	SET @cCmd=N'SELECT *,convert(numeric(10,0),round((CASE WHEN sold_qty<>0 then CONVERT(NUMERIC(10,2),'+str(@NDAYSCNT)+')/sold_qty else 0 end)*CBS_QTY,0))
				 AS DAYS_OF_STOCK
				FROM '+@cRepTable+' ORDER BY setup_id,rfcc_score desc,sold_qty desc,asd,sell_thru desc'
	print @cCmd
	EXEC SP_EXECUTESQL @cCmd

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SPDB_RFCC_ANALYSIS at step#'+@cStep+' '+ERROR_MESSAGE()
END CATCH

END_PROC:
print 'last step:'+@cStep

END