CREATE PROCEDURE SP3S_BUILDADICOLS_NEW
@dFromDt DATETIME='',
@dToDt DATETIME='',
@cSetupIdPara VARCHAR(10)=''
WITH ENCRYPTION
AS
BEGIN

	declare @tpmtdiff table (dept_id char(2))

	declare @cPmtTable varchar(200),@cCmd NVARCHAR(MAX),@bFlag  bit,@cFInYear VARCHAR(5),@cGrpExpr VARCHAR(400),
	@cSetupId VARCHAR(10),@cParaName VARCHAR(300),@cFilter VARCHAR(MAX),@cGrpParaname VARCHAR(500)

	IF OBJECT_ID('tempdb..#tmpDbSetupAdi','U') IS NOT NULL
		DROP TABLE #tmpDbSetupAdi

	SELECT setup_id,para_name,filter_criteria,setup_name,additional_filter_criteria INTO #tmpDbSetupAdi FROM pos_dynamic_dashboard_setup WHERE 1=2
	
	set @bFlag=0
	IF @dFromDt<>'' OR @dToDt<>'' or @cSetupId='KYB0001'
		SET @bFlag=1
		
	IF @dToDt=''
		SET @dToDt=convert(date,getdate()-1)
	
	IF @dFromDt=''	
		set @dFromDt=@dToDt

	
	while @bFlag=0
	BEGIN
		delete from @tpmtdiff

		set @cPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dFromDt,112)

		set @cCmd=N'SELECT TOP 1 a.DEPT_ID FROM (SELECT DEPT_ID,SUM(CBS_QTY) AS CBS FROM '+@cPmtTable+' (NOLOCK)
											   GROUP BY DEPT_ID) A
					LEFT OUTER JOIN posdb_pmtstk_log b ON a.dept_id=b.dept_id AND b.xn_dt='''+convert(varchar,@dFromDt,112)+'''
					where a.cbs<>isnull(b.cbs_qty,0)'
		
		print @cCmd
		insert @tpmtdiff
		exec sp_executesql @cCmd

		
		if not exists (select top 1 * from @tpmtdiff)
			break
		
		set @dFromDt=@dFromDt-1
	END
	
	if @dFromDt=@dToDt AND @bFlag=0
		return


lblBuildAdi:
	
--	select @dFromDt as dFromDtadi,@dtoDt as dtoDtadi
	
	while @dFromDt<=@dToDt
	begin
		
		set @cFInYear='01'+dbo.fn_getfinyear(@dFromDt)
		
		INSERT #tmpDbSetupAdi	(  setup_id,filter_criteria, para_name,setup_name ) 
		SELECT 	  setup_id,filter_criteria, para_name,setup_name FROM pos_dynamic_dashboard_setup
		WHERE setup_id=@cSetupIdPara OR (@cSetupIdPara='' and dashboard_mode in (0,1))
		
		DELETE a FROM ADICumCbp a JOIN #tmpDbSetupAdi b ON a.setup_id=b.setup_id 
		WHERE a.xn_dt=@dFromDt
		
		SET @cPmtTable=DB_NAME()+'_PMT.DBO.pmtlocs_'+CONVERT(VARCHAR,@dFromDt,112)
		
		WHILE EXISTS (SELECT TOP 1 * FROM #tmpDbSetupAdi)
		BEGIN				
					
			SELECT TOP 1 @cSetupId=setup_id,@cParaName=para_name,@cFilter=filter_criteria FROM #tmpDbSetupAdi
			
			PRINT 'Processing ADI for Date:'+convert(varchar,@dFromDt,113)+' AND setup:'+@cSetupId

			SET @cGrpParaname=@cParaName

			IF @cParaName='dept_name'
				SELECT @cParaName='location.dept_id+''-''+dept_name',@cGrpParaname='location.dept_id,dept_name'
			ELSE
			IF @cParaName='dept_id'
				SELECT @cParaName='location.dept_id',@cGrpParaName='location.dept_id'
			ELSE
			IF @cParaName='POSDB_PRICECATEGORY'
				SELECT @cParaName='category_name',@cGrpParaname='CATEGORY_NAME',@cFilter=' sn.mrp BETWEEN mrp_from AND mrp_to'
				
		
			IF @cFilter=''
				SET @cFilter='1=1'
			
			SET @cFilter=REPLACE(@cFilter,'dept_id','location.dept_id')
			SELECT @cGrpExpr=' GROUP BY '+@cGrpParaname

			SET @CCMD=N' SELECT '''+@cSetupId+''' as setup_id,'''+CONVERT(varchar,@dFromDt,110)+''' as xn_dt,'''+@cFInYear+''' as fin_year,'+
						 @cParaName+' as para_name,SUM(cbs_qty*sn.pp) as cbs_qty
						 FROM '+@cPmtTable+' a (NOLOCK)
						 JOIN sku_names sn (NOLOCK) ON a.product_code=sn.product_code
						 JOIN location (NOLOCK) On location.dept_id=a.dept_id
						 WHERE '+@cFilter+@cGrpExpr
						 
			PRINT @cCmd
			
		
			INSERT ADICumCbp (setup_id,xn_dt,fin_year,para_name ,cbp)
			EXEC SP_EXECUTESQL @cCmd

			DELETE FROM #tmpDbSetupAdi WHERE setup_id=@cSetupId
		END
			
		set @dFromDt=@dFromDt+1
	END
END