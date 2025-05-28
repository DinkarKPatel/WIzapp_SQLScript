CREATE PROCEDURE SP3S_GETCBSSTK_FOR_PLBS
(
	@dXnDt DATETIME,
	@nSpId varchar(40),
	@bCalledFromProfitCalc BIT=0,
	@bCalledfromPl BIT=0,
	@bCalledfromBs BIT=0,
	@nPlBsViewMode INT=1, -- 1.As per IT act 2.For Internal use
	@nRetOpsCbsMode INT=2,
	@bCalledFromFS BIT=0,
	@nCbp NUMERIC(20,2) OUTPUT,
	@cErrormsg VARCHAR(MAX) OUTPUT
)
--WITH ENCRYPTION
AS
BEGIN
	SET NOCOUNT ON 
BEGIN TRY
	--if @@spid=853
	--	select @dXnDt dxndtplbs
	--if @@spid=448
	--	select @bCalledFromProfitCalc CalledFromProfitCalc
	DECLARE @cStep VARCHAR(20),@DMINXNDT DATETIME,@DMAXXNDT DATETIME,@DLASTXNDT DATETIME,@NCBSSTKVAL NUMERIC(10,2),
			@CCMD NVARCHAR(MAX),@CFINYEAR VARCHAR(10),@DFROMDT DATETIME,@CRFDBNAME VARCHAR(500),
			@cbsQtyCol VARCHAR(100),@tPmtTable varchar(200),@tGitTable varchar(200),@tWip VARCHAR(200),@tPendingApp VARCHAR(200),@tPendingJw VARCHAR(200),@tPendingGit VARCHAR(200),
			@tPendingWPS VARCHAR(200),@tPendingRPS VARCHAR(200),@tPendingDnPS VARCHAR(200),@tPendingCnPS VARCHAR(200),
			@cPmtDbName VARCHAR(200),@cLocId VARCHAR(4),@cLocFilter VARCHAR(100),
			@nCBSPHYSICAL NUMERIC(20,3),@nCBSAPPROVAL  NUMERIC(20,2),@nCBSPACKSLIPS  NUMERIC(20,2),
			@nCBSJWI NUMERIC(20,2),@nCBSCHGIT  NUMERIC(20,2),@nCBSCHGITWsl  NUMERIC(20,2),@nCBSCHGITPrt  NUMERIC(20,2),
			@nCBSPURGIT  NUMERIC(20,2),@cLocPpStr VARCHAR(50),@cPPBaseCondition VARCHAR(400),
		    @nCBSWIP NUMERIC(20,2),@nCbsWps NUMERIC(20,2),@nCbsRps NUMERIC(20,2),@nCbsDnps NUMERIC(20,2),
			@nCbsCnps NUMERIC(20,2),@cHoLocId VARCHAR(5),@bFlag BIT,@bFinYearDate BIT,
			@nDepCnVal NUMERIC(10,2),@cDepCnFinyear VARCHAR(10),@cProfitFinYear VARCHAR(10),@nCbsQty numeric(20,2)
	
	set @cProfitFinYear=''
	---Special case of Saree sansar personal account data where no stock is maintained
	IF NOT EXISTS (SELECT TOP 1 mrr_id from pim01106)
	BEGIN
		set @nCbp=0
		GOTO END_PROC
	END	

	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='location_id'

	SET @cStep='52.10'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
	CREATE TABLE #LocList (dept_id VARCHAR(4),pan_no varchar(50))

	IF @bCalledFromProfitCalc=0
	BEGIN
		IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
		BEGIN    
			  INSERT #LocList  (dept_id,pan_no)  
			  SELECT a.DEPT_ID,b.PAN_NO FROM ACT_FILTER_LOC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id
			  WHERE SP_ID = @nSpId    
		END     
		ELSE    
			  INSERT #LocList  (dept_id,pan_no)      
			  SELECT DEPT_ID,pan_no FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)
	END
	ELSE
		INSERT INTO #LocList(dept_id,pan_no)
		select a.dept_id,b.PAN_NO from #locListC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id
	
	
	SET @cFinyear='01'+dbo.fn_getfinyear(@dXnDt)


	SET @cStep='52.12'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
	
	SET @cStep='52.125'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1

	SET @cPmtDbName=DB_NAME()+'_PMT.DBO.'

	CREATE TABLE #tmpPendingDocsValues (dept_id VARCHAR(4),xn_type VARCHAR(10),ppvalue NUMERIC(14,2))

	EXEC SP3S_FETCH_PENDINGDOCS 
	@dToDt=@dXnDt,
	@cErrormsg=@cErrormsg OUTPUT



	--if @@spid=201
	--	select 'check @dXndt',@dXndt dxndt,@nRetOpsCbsMode nRetOpsCbsMode

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	DECLARE @dFromDtLastMonthEndDt DATETIME,@dToMonthEndDt DATETIME

	SET @dFromDtLastMonthEndDt=DATEADD(DAY, -DAY(@dXnDt+1), CAST(@dXnDt+1 AS DATE))
	SET @dToMonthEndDt=DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @dXnDt) + 1, 0))

	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtops from pmt01106 where 1=2	select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtcbs from pmt01106 where 1=2

	DECLARE @cCompanyPanNo varchar(100),@bUpdateCbsOnly BIT,@bUpdateOpsOnly BIT
	SELECT @bUpdateCbsOnly=0,@bUpdateOpsOnly=0

	
	if @nRetOpsCbsMode=1
		SET @bUpdateOpsOnly=1

	if @nRetOpsCbsMode=2
		SET @bUpdateCbsOnly=1

	if (@bCalledfromPl=1 OR @bCalledfromBs=1 OR @bCalledFromFS=1)
	begin
		if @bCalledFromFS=1
			select top 1 @cCompanyPanNo=pan_no from #locListFS a JOIN location b (NOLOCK) ON a.dept_id=b.dept_id
		ELSE
			select top 1 @cCompanyPanNo=pan_no from #locListC a JOIN location b (NOLOCK) ON a.dept_id=b.dept_id
	end

	DECLARE @cFilterPara varchar(500)

	set @cFilterPara='sourcelocation.pan_no='''+@cCompanyPanNo+''''

	--- Need to populate ops and cbs tables of temp pmt for getting stock evaluation
	if (@nRetOpsCbsMode=1 and @dXnDt<>@dFromDtLastMonthEndDt) OR
	(@nRetOpsCbsMode=2 and (@dXnDt<>CONVERT(DATE,GETDATE()) AND @dXnDt<>@dToMonthEndDt AND @dXnDt<CONVERT(DATE,GETDATE())))
	BEGIN
		DECLARE @bCalledFromPlbs BIT
		SET @bCalledFromPlbs=0

		IF @bCalledfromBs=1 OR @bCalledfromPl=1
			SET @bCalledFromPlbs=1

		exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY 
		@dFromDt=@dXndt,
		@dToDt=@dXnDt,
		@cFilterPara=@cFilterPara,
		@bUpdateCbsOnly=@bUpdateCbsOnly,
		@bUpdateOpsOnly=@bUpdateOpsOnly,
		@bCalledFromPlbs=@bCalledFromPlbs,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END

	IF @nRetOpsCbsMode=1
	BEGIN
		IF @dXnDt<>@dFromDtLastMonthEndDt
			SELECT @tPmtTable='#pmtops'
		ELSE
			SELECT @tPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dXnDt,112)
	END
	ELSE
	IF @nRetOpsCbsMode=2
	BEGIN
		IF (@dXnDt<>CONVERT(DATE,GETDATE()) AND @dXnDt<>@dToMonthEndDt AND @dXnDt<CONVERT(DATE,GETDATE()))
			SELECT @tPmtTable='#pmtcbs'
		ELSE 
		BEGIN
			IF @dXnDt>=CONVERT(DATE,GETDATE()) -- Put this condition to handle the closing stock for Financial summary which gives month end date as parameter to this Procedure (Sanjay:18-07-2024)
				SET @tPmtTable='pmt01106'
			ELSE
				SET @tPmtTable=db_name()+'_pmt.dbo.pmtlocs_'+CONVERT(VARCHAR,@dXnDt,112)
		END
	END
	

	SET @cStep='52.15'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
	
	SELECT  @cbsQtyCol = (CASE WHEN @dXnDt>=CONVERT(DATE,GETDATE()) THEN 'quantity_in_stock' ELSE 'cbs_qty' END)



	SET @cStep='52.20'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
	print 'Start Calculating Closing stock value for Date:'+convert(varchar,@dXnDt,105)

	SELECT mrr_id INTO #tmpPurGit FROM pim01106 a (NOLOCK) where 1=2
	
	declare @nLoopcnt numeric(5,0)
	--if @dXndt='2021-03-31'
	--	  select 'Start Calculating Closing stock value for Date:',@dXndt xn_dt, a.* from #locListC a LEFT JOIN #year_wise_cbs b ON a.dept_id=b.dept_id
	--		WHERE b.dept_id IS NULL

	SET @nLoopcnt=1
	SET @bFlag=1
	WHILE @bFlag=1
	BEGIN
		SET @cStep='52.22'
		SET @cLocFilter=''
		IF @bCalledFromProfitCalc=1 AND @bCalledfromBs=0
		BEGIN
			
			EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
			SET @cLocId=''
			SELECT TOP 1 @cLocId=a.dept_id from #locListC a LEFT JOIN #year_wise_cbs b ON a.dept_id=b.dept_id
			WHERE b.dept_id IS NULL

			--if @dXndt='2021-03-31'
			--begin
			--	select 'Check loclistc',* from #LocListC
			--	select 'check year wise cbs',@dXndt, * from #year_wise_cbs
			--end

			IF ISNULL(@cLocId,'')<>''
				SET @cLocFilter=' AND b.dept_id='''+@cLocId+''''
			ELSE
				break
		END
		
		SET @cStep='52.25'
		IF (@bCalledfromPl=1 or @bCalledfromBs=1) AND @nPlBsViewMode=2 -- Show Closing Stock at Transfer Price (Without gst) If [For Internal Use] option is selected
												   -- in Profit Loss account & Balance sheet	
		BEGIN
			SET @cLocppStr='ISNULL(sx.xfer_price_without_gst,0)'
			SET @cPPBaseCondition=@cLocppStr+'=0 AND (sn.purloc_pan_no=b.pan_no OR b.dept_id='''+@cHoLocId+''')'
		END
		ELSE
		BEGIN
			SET @cLocPpStr='ISNULL(sx.loc_pp,0)'
			SET @cPPBaseCondition='sn.purloc_pan_no=b.pan_no OR b.dept_id='''+@cHoLocId+''' OR '+@cLocppStr+'=0'
		END

		print 'Calculating Closing stock value for Date:'+convert(varchar,@dXnDt,105)+': LocId'+@cLocId
		SET @cStep='52.30'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		SET @cCmd=N'SELECT @nCbsQty=sum('+@cbsQtyCol+'),@nCbsPhysical=SUM('+@cbsQtyCol+'*(CASE WHEN '+@cPPBaseCondition+
				' THEN sn.pp ELSE '+@cLocppStr+' END)) FROM '+@tPmtTable+' a
					JOIN #LocList b ON a.dept_id=b.dept_id
					JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
					LEFT JOIN sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
					WHERE sku_item_type=1 AND isnull(sku_er_flag,0) IN  (0,1) AND a.bin_id<>''999''
					AND ISNULL(sn.stock_na,0)=0 '+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsQty NUMERIC(20,3) OUTPUT,@nCbsPhysical NUMERIC(20,3) OUTPUT',@nCbsQty OUTPUT,@nCbsPhysical OUTPUT	

		--if @@spid=91
		--begin
		--	SET @cCmd=N'select '''+@tPmtTable+''' pmttable' --, * from '+@tPmtTable

		--	 --SELECT a.product_code,'+@cbsQtyCol+',sn.pp,'+@cLocppStr+','''+@tPmtTable+' FROM '+@tPmtTable+' a
		--		--		JOIN #LocList b ON a.dept_id=b.dept_id
		--		--		JOIN sku_names sn (NOLOCK) ON sn.product_code=a.product_code
		--		--		JOIN sku (NOLOCK) ON sku.product_code=sn.product_code
		--		--		LEFT JOIN sku_xfp sx (NOLOCK) ON sx.product_code=a.product_code AND sx.dept_id=a.dept_id
		--		--		WHERE sku_item_type=1 AND isnull(sku.er_flag,0) IN  (0,1) AND a.bin_id<>''999''
		--		--		AND ISNULL(sn.stock_na,0)=0 '+@cLocFilter 
		--	PRINT @cCmd
		--	EXEC SP_EXECUTESQL @cCmd
		--end
		SET @cStep='52.55'
		SET @cCmd=N'SELECT @nCbsApproval=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''APP'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsApproval NUMERIC(20,2) OUTPUT',@nCbsApproval OUTPUT	

		SET @cCmd=N'SELECT @nCbsWps=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''wps'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsWps NUMERIC(20,2) OUTPUT',@nCbsWps OUTPUT	

		SET @cCmd=N'SELECT @nCbsRps=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''rps'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsRps NUMERIC(20,2) OUTPUT',@nCbsRps OUTPUT	

		SET @cCmd=N'SELECT @nCbsDnps=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''DNPS'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsDnps NUMERIC(20,2) OUTPUT',@nCbsDnps OUTPUT	

		SET @cCmd=N'SELECT @nCbsCnps=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''cnps'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsCnps NUMERIC(20,2) OUTPUT',@nCbsCnps OUTPUT	

		SET @cCmd=N'SELECT @nCbsJwi=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''JWI'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCbsJwi NUMERIC(20,2) OUTPUT',@nCbsJwi OUTPUT	

		SET @cCmd=N'SELECT @nCBSCHGIT=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''GIT'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCBSCHGIT NUMERIC(20,2) OUTPUT',@nCBSCHGIT OUTPUT	
		
		SET @cCmd=N'SELECT @nCBSPurGit=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''PURGIT'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCBSPurGit NUMERIC(20,2) OUTPUT',@nCBSPurGit OUTPUT	

		SET @cCmd=N'SELECT @nCBSWip=SUM(ppvalue) FROM #tmpPendingDocsValues b WHERE xn_type=''WIP'''+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nCBSWip NUMERIC(20,2) OUTPUT',@nCBSWip OUTPUT	
		
		DECLARE @dFinyearToDt DATETIME

		SELECT @dFinyearToDt = DBO.FN_GETFINYEARDATE(@cFinyear,2)

		SET @cStep='52.60'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		IF @dFinyearToDt=@dXnDt
			SET @cDepCnFinyear=@CFINYEAR
		ELSE
			SET @cDepCnFinyear='01'+dbo.fn_getfinyear(DATEADD(YY,-1,@dFinyearToDt))

		SET @cCmd=N'SELECT @nDepCnVal=SUM('+@cbsQtyCol+'*(depcn_value+isnull(prev_depcn_value,0))) FROM '+@tPmtTable+' a
					JOIN #LocList b ON a.dept_id=b.dept_id
					JOIN year_wise_cbsstk_depcn_det c (NOLOCK) on c.dept_id=a.dept_id AND c.product_code=a.product_code
					WHERE c.fin_year=(SELECT TOP 1 d.fin_year FROM year_wise_cbsstk_depcn_det d
									  WHERE d.product_code=a.product_code AND d.dept_id=a.dept_id
									  AND d.fin_year<='''+@cDepCnFinyear+''' ORDER BY d.fin_year DESC) '+@cLocFilter 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@nDepCnVal NUMERIC(20,2) OUTPUT',@nDepCnVal OUTPUT	
	


		SET @cStep='52.70'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		SELECT @nCbp=isnull(@nCBSPHYSICAL,0)-ISNULL(@nDepCnVal,0)+ISNULL(@nCBSAPPROVAL,0)+ISNULL(@nCBSWPS,0)+ISNULL(@nCBSRPS,0)+
					 ISNULL(@nCBSDnPS,0)+ISNULL(@nCBSCNPS,0)+
					 ISNULL(@nCBSJWI,0)+ISNULL(@nCBSCHGIT,0)+ISNULL(@nCBSPURGIT,0)+ISNULL(@nCBSWIP,0)		

		--if @@spid=51 and @bCalledfromBs=1
		--begin
		--	select @bCalledFromProfitCalc CalledFromProfitCalc, @bCalledfromBs CalledfromBs, @cLocFilter loc_filter, @bCalledFromProfitCalc CalledFromProfitCalc,@nCbp Cbp_calculated, isnull(@nCBSPHYSICAL,0) nCBSPHYSICAL,ISNULL(@nDepCnVal,0) nDepCnVal,
		--	ISNULL(@nCBSAPPROVAL,0) nCBSAPPROVAL,
		--	ISNULL(@nCBSWPS,0) nCBSWPS,ISNULL(@nCBSRPS,0) nCBSRPS,
		--			 ISNULL(@nCBSDnPS,0) nCBSDnPS,ISNULL(@nCBSCNPS,0) nCBSCNPS,
		--			 ISNULL(@nCBSJWI,0) nCBSJWI ,ISNULL(@nCBSCHGIT,0) nCBSCHGIT,ISNULL(@nCBSPURGIT,0) nCBSPURGIT,ISNULL(@nCBSWIP,0) nCBSWIP,
		--			 count(*) loccnt from #LocList
			
		--end

		

		--if @@spid=597
		--	select @nCbp nCbp
		IF @bCalledFromProfitCalc=0 or @bCalledfromBs=1
		BEGIN
		SET @cStep='52.75'
			IF @bCalledfromBs=1 AND @bCalledFromProfitCalc=1
				INSERT #year_wise_cbs (dept_id,cbp)
				SELECT 'All' dept_id,@nCbp cbp


			BREAK
		END
		ELSE
		begin
			SET @cStep='52.77'
			INSERT #year_wise_cbs (dept_id,cbp)
			SELECT @cLocId,@nCbp
		end
		set @nLoopcnt=@nLoopcnt+1
	END

	SET @cStep='52.775'
	--if @dXndt='2021-03-31'
	--	  select 'Completed Calculating Closing stock value for Date:',@dXndt xn_dt,@nLoopcnt loopcnt, a.* from #locListC a LEFT JOIN #year_wise_cbs b ON a.dept_id=b.dept_id
	--		WHERE b.dept_id IS NULL
	
	--SET @cStep='52.77'
	--if @bCalledFromProfitCalc=1 and @nRetOpsCbsMode=2
	--select * into year_wise_cbs_plbs from #year_wise_cbs

	IF @bCalledfromPl=1 OR @bCalledFrombs=1
	BEGIN
		SET @cStep='52.80'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		DELETE FROM plbs_stock_summary with (rowlock) where xn_dt=@dXnDt
		
		--if @@spid=553
		--SELECT 	@dXnDt xn_dt,@nCbsQty cbsqty, @nRetOpsCbsMode nRetOpsCbsMode, @nCbp  cbp,@nDepCnVal depcn_val, @nCBSAPPROVAL CBS_APPROVAL,@nCBSCHGIT CBS_CHGIT,@nCBSDnPS CBS_dnps,@nCBSCnPS cbs_cnps,
		--@nCBSJWI CBS_JWI,@nCBSPHYSICAL cbs_physical,@nCBSPURGIT CBS_PURGIT, 
		--@nCBSRPS CBS_rps,@nCBSWIP cbs_wip, @nCBSWPS CBS_wps
		

		--if @@spid=939
		--	select @dXnDt dxndt
		INSERT plbs_stock_summary	( cbp, depcn_val, CBS_APPROVAL, CBS_CHGIT, CBS_dnps,cbs_cnps, CBS_JWI, cbs_physical, 
		CBS_PURGIT, CBS_rps, cbs_wip, CBS_wps, xn_dt )  
		SELECT 	@nCbp  cbp,@nDepCnVal depcn_val, @nCBSAPPROVAL CBS_APPROVAL,@nCBSCHGIT CBS_CHGIT,@nCBSDnPS CBS_dnps,@nCBSCnPS cbs_cnps,
		@nCBSJWI CBS_JWI,@nCBSPHYSICAL cbs_physical,@nCBSPURGIT CBS_PURGIT, 
		@nCBSRPS CBS_rps,@nCBSWIP cbs_wip, @nCBSWPS CBS_wps,@dXnDt xn_dt
	END	

	GOTO END_PROC
END TRY

BEGIN CATCH
	
	SET @cErrormsg='Error in Procedure SP3S_GETCBSSTK_FOR_PLBS at Step#'+@cStep+' '+error_message()
	print 'enter catch of SP3S_GETCBSSTK_FOR_PLBS :'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:

END
--END OF PROCEDURE - SP_GETCBSSTK_FOR_PLBS