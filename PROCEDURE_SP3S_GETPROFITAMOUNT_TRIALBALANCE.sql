CREATE PROCEDURE SP3S_GETPROFITAMOUNT_TRIALBALANCE
@bCalledFromBs BIT=0,
@nCbp NUMERIC(20,2)=0,
@dToDtPara DATETIME='',
@cCompanyPanNo VARCHAR(50)='',
@bResetOldEntries BIT=0
AS
BEGIN
	DECLARE @nOpnStkinHand NUMERIC(20,2),@nCbsStkinHand NUMERIC(20,2),@nGrossProfitLossAmt numeric(20,2),
			@nExpenses NUMERIC(20,2),@dFromDt DATETIME,@dToDt DATETIME,@cPlHeads VARCHAR(2000),
			@nPlXferred NUMERIC(20,2),@cCmd NVARCHAR(MAX),@nDirectExpense NUMERIC(20,2),@cMinFinYear VARCHAR(10),
			@dEndVoucherDt DATETIME,@dStartVoucherDt DATETIME,@cPrevFinYear varchar(5),@nObp NUMERIC(20,2),@bCalledFromProfitCalc BIT,
			@CDONOTPICKOBHEADS VARCHAR(MAX),@cFinYear VARCHAR(5),@cPurGitFinyear VARCHAR(5),@cErrormsg VARCHAR(1000),@cStep VARCHAR(10),
			@NSPID VARCHAR(20),@dFinyearToDt DATETIME,@tGitTable VARCHAR(200),@cPmtDbName VARCHAR(200),@cDtSuffix varchar(20)
						

BEGIN TRY
	
--	select @bCalledFromBs,@nCbp,@dToDtPara
	set @nSpid=ltrim(rtrim(str(@@spid)))
	SET @cStep='10'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1


	IF @bCalledFromBs=1 
		SET @bCalledFromProfitCalc=0
	ELSE
		SET @bCalledFromProfitCalc=1

	SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    


	CREATE TABLE #tmpPlHeads (head_Code char(10),bs_head_code CHAR(10),srno NUMERIC(1,0))  
	
	
	if @bCalledFromBs=0
	BEGIN
		select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtops from pmt01106 (NOLOCK) where 1=2		select product_code,bin_id,dept_id,quantity_in_stock cbs_qty into #pmtcbs from pmt01106 (NOLOCK) where 1=2	END

	SELECT * INTO #Trial_profitloss_locwise	 FROM Trial_profitloss_locwise (NOLOCK) WHERE 1=2

	SET @cStep='20'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1

	SET @cCmd=N'
	SELECT head_code,''0000000026'',3 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000026')+')  
	UNION   
	SELECT head_code,''0000000027'',8 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000027')+')  
	UNION   
	SELECT head_code,''0000000028'',9 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000028')+')  
	UNION   		
	SELECT head_code,''0000000029'',2 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000029')+')
	UNION   
	SELECT head_code,''0000000030'',4 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000030')+')
	'  
	print @cCmd
	INSERT #tmpPlHeads  
	EXEC SP_EXECUTESQL @cCmd  

	
	SELECT cost_center_dept_id ,min(VOUCHER_dT) start_dt,max(voucher_dt) end_dt
	INTO #tmpCutoffDates
	from vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	WHERE cancelled=0 AND VOUCHER_DT>='2000-04-01'
	and b.location_code <>'ob'
	GROUP BY cost_center_dept_id

	IF @bCalledFromBs=0
	BEGIN	
		
		SET @cStep='30'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1
		
		
		SET @cStep='32.2'
		UPDATE a SET start_dt=c.cut_off_dt FROM #tmpCutoffDates a
		JOIN location b (NOLOCK) ON a.cost_center_dept_id=b.dept_id
		JOIN loc_accounting_company c (NOLOCK) ON c.pan_no=b.PAN_NO
		WHERE ISNULL(c.cut_off_dt,'')<>''

		IF @bResetOldEntries=1
			TRUNCATE TABLE Trial_profitloss_locwise
	
	END
	ELSE
	BEGIN
		SET @cStep='40'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1

		SELECT @cFinYear='01'+dbo.fn_getfinyear(@dToDtPara)  

		SELECT @dStartVoucherDt=DBO.FN_GETFINYEARDATE(@cFinYear,1)

		UPDATE #tmpCutoffDates SET start_dt=@dStartVoucherDt,end_dt=@dToDtPara

		SELECT @dEndVoucherDt=@dToDtPara
	END

	--if @@spid=597
	--	select 'check #tmpCutoffDates',@dStartVoucherDt,@dEndVoucherDt,* from #tmpCutoffDates 
		
	CREATE TABLE #year_wise_cbs (cbp NUMERIC(38,2), dept_id varchar(5))

	DECLARE @cProfitFinYear VARCHAR(5),@dPrevToDt DATETIME,@dXnDt DATETIME,@bEntryFound BIT


	if @bCalledfrombs=0
		CREATE TABLE #locListC (dept_id varCHAR(5))

	SET @cStep='45'	
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1

	SET @cPrevFinYear=''
	
	IF @bCalledFromBs=0
	BEGIN
		SELECT @dStartVoucherDt=min(start_dt) FROM #tmpCutoffDates
		SET @cMinFinYear='01'+dbo.FN_GETFINYEAR(@dStartVoucherDt)
	
		SELECT @cFinYear='01'+dbo.fn_getfinyear(convert(date,getdate()))  

		SELECT @dStartVoucherDt=DBO.FN_GETFINYEARDATE(@cMinFinYear,1),
		@dEndVoucherDt=DBO.FN_GETFINYEARDATE(@cFinYear,2)
	END

	
	--if @@spid=535
	--	select 'check #tmpCutoffDates',@dStartVoucherDt dStartVoucherDt,@dEndVoucherDt dEndVoucherDt,c.CUT_OFF_DT,a.* from #tmpCutoffDates a
	--	JOIN location b on a.cost_center_dept_id=b.dept_id
	--	join loc_accounting_company c on c.pan_no=b.PAN_NO

	SELECT mrr_id,a.dept_id INTO #tmpPurGit  FROM pim01106 a (NOLOCK) where 1=2
	
	SELECT mrr_id memo_id,dept_id INTO #tmpPendingGit FROM pim01106 (NOLOCK) WHERE 1=2

	create table #tmpGitValue (dept_id varchar(5),ppvalue numeric(20,2))


	IF @bCalledFromBs=1
		INSERT #Trial_profitloss_locwise (fin_year,dept_id,NetProfitLossAmt)
		SELECT @cProfitFinYear as fin_year,'All' dept_id,0 


	CREATE TABLE #tmpPendingDocsValues (dept_id VARCHAR(4),xn_type VARCHAR(10),ppvalue NUMERIC(14,2))
	
	SELECT 'WSL'+a.inv_id memo_id,a.party_dept_id dept_id into #tmpPendingDocsMemos
	FROM inm01106 a (NOLOCK)  where 1=2

	--- Need to do this becasue below common procedure called from many places is looking for this table
	CREATE TABLE #locList (dept_id char(2),pan_no varchar(100))

	INSERT INTO #LocList(dept_id,pan_no)
	select a.dept_id,b.PAN_NO from #locListC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id


	update #tmpCutoffDates set start_dt=dbo.FN_GETFINYEARDATE('01'+dbo.FN_GETFINYEAR(start_dt),1)
	--select @dStartVoucherDt,@dEndVoucherDt
	WHILE @dStartVoucherDt<=@dEndVoucherDt
	BEGIN	
		SET @cProfitFinYear='01'+dbo.FN_GETFINYEAR(@dStartVoucherDt)

		print 'calculating profit for fin year :'+@cProfitFinYear		
		SET @dPrevToDt=''

		IF @cPrevFinYear<>''
			SET @dPrevToDt=DBO.FN_GETFINYEARDATE(@cPrevFinYear,2)
		
		IF @bCalledFromBs=0
		BEGIN
			SET @dToDt=DBO.FN_GETFINYEARDATE(@cProfitFinYear,2)

			--- Need to populate ops and cbs tables of temp pmt for getting stock evaluation
			exec SPWOW_GENXPERT_PMTSTK_ONTHEFLY 
			@dFromDt=@dStartVoucherDt,
			@dToDt=@dToDt,
			@cErrormsg=@cErrormsg OUTPUT

			IF ISNULL(@cErrormsg,'')<>''
				GOTO END_PROC
			
		END
		ELSE
		BEGIN
			SET @dToDt=@dToDtPara
			SET @cPrevFinYear='01'+dbo.FN_GETFINYEAR(@dStartVoucherDt-1)
		END
			SET @cStep='50'
				EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1

		
		if @bCalledfromBs=0
		BEGIN
			DELETE FROM #locListC

			INSERT #locListC (dept_id)
			select a.dept_id FROM location a (NOLOCK) 
			JOIN loc_accounting_company b (NOLOCK) ON a.pan_no=b.pan_no
			JOIN #tmpCutoffDates c (NOLOCK) ON c.cost_center_dept_id=a.dept_id
			WHERE c.start_dt<=@dStartVoucherDt and (B.PAN_NO=@cCompanyPanNo or @cCompanyPanNo='')
		END
		ELSE
			INSERT #locListC (dept_id) VALUES ('All')

		--IF @@SPID=448
		--BEGIN
		--	SELECT @cCompanyPanNo cCompanyPanNo,* FROM #tmpCutoffDates 
		--	SELECT 'CHECK LOCLIST',* FROM #locListC
		--END

		IF NOT EXISTS (SELECT TOP 1 dept_id FROM #locListC)
			GOTO lblNextYear

		
		INSERT #Trial_profitloss_locwise (fin_year,dept_id,NetProfitLossAmt)
		SELECT @cProfitFinYear as fin_year,dept_id,0 FROM #locListC

		DELETE FROM #year_wise_cbs

		SET @bEntryFound=0

		SET @dXnDt=@dStartVoucherDt-1 

		EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
		@dXnDt=@dXnDt,
		@bRetLocWise=1,
		@nCbp=@nCbp OUTPUT,
		@bEntryFound=@bEntryFound OUTPUT
		
		--Commented this Code because of recent issue found at Rainbow Apparels against Ticket#10-0572
		--They had mentioned CLosing stock manuallt only against HO instead of mentioning Location wise
		--Due to this , their Trial Balance was showing unbalanced due to wrong Pending PRofit component 
		--being carried forward..In the Evening meeting on 11-10-2021 ,Sir told that We shall consider manual stock for all Locations if it 
		-- is marked manual for a given Financial Year (Date:12-10-2021)
		--IF exists (select top 1 a.dept_id from #locListC a left join #year_wise_cbs b on a.dept_id=b.dept_id
		--		   where b.dept_id is null)
		IF @bEntryFound=0
		BEGIN
			SET @cStep='52'
			EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
			
			EXEC SP3S_GETCBSSTK_FOR_PLBS
			@dXnDt=@dXnDt,
			@nSpId=@@spid,
			@bCalledFromProfitCalc=1,
			@bCalledFromBs=@bCalledFromBs,
			@nRetOpsCbsMode=1,
			@nCbp=@nCbp OUTPUT,
			@cErrormsg=@cErrormsg OUTPUT

			if isnull(@cErrormsg,'')<>''
				goto end_proc
		END

		SET @cStep='55'
			EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,'',1
		UPDATE a SET OpnStkinHand=isnull(B.OpnStkinHand,0) FROM #Trial_profitloss_locwise A
		left outer JOIN
		(SELECT a.dept_id,SUM(cbp) as OpnStkinHand	FROM #year_wise_cbs a (NOLOCK) 
		JOIN #locListC b  ON a.dept_id=b.dept_id
		 group by a.dept_id) b on a.dept_id=b.dept_id
		 WHERE fin_year=@cProfitFinYear
				
		SET @cStep='60'		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		
		UPDATE a SET purchases=b.purchases,sales=b.sales
		FROM #Trial_profitloss_locwise a JOIN 
		(select cost_center_dept_id as dept_id,sum(case when thd.bs_head_code='0000000029' THEN
	     debit_amount-credit_amount else 0 end) as Purchases,
		 sum(case when thd.bs_head_code='0000000030' THEN
	     credit_amount-debit_amount else 0 end) as Sales
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		JOIN #tmpPlHeads thd ON thd.head_Code=lm.head_code  
		JOIN #locListC b  ON vd.cost_center_dept_id=b.dept_id
		where vm.fin_year=@cProfitFinYear AND  cancelled=0     
		AND voucher_dt<=@dToDt
		and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
		AND thd.bs_head_code IN ('0000000029','0000000030')
		GROUP BY cost_center_dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear
		

	

		SET @cStep='62'		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
			   
		exec SP3S_GETFINYEAR_LASTPMTXNDT @dToDt,@cDtSuffix output

		SET @cPmtDbName=DB_NAME()+'_PMT.DBO.'

		SET @cStep='62.24'		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1

		--select 'check b4 updating git', * from #Trial_profitloss_locwise where fin_year=@cProfitFinYear and dept_id='01'
		
		DELETE FROM #tmpPendingDocsValues
		DELETE FROM #tmpPendingDocsMemos

		EXEC spact_Getlocwise_gitValue  @DtOdT,1 

		--IF @@SPID=939
		--	SELECT 'CHECK tmpPendingDocsValues',* FROM #tmpPendingDocsValues

		SET @cCmd=N'UPDATE a SET 	purchases=isnull(a.purchases,0)+b.gitpp from #Trial_profitloss_locwise a JOIN 
					(SELECT a.dept_id,SUM(ppvalue) gitpp FROM #tmpPendingDocsValues a
					 WHERE xn_type=''GIT'' GROUP BY a.dept_id) b ON a.dept_id=b.dept_id'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
		--select 'check after updating Challan git', * from #Trial_profitloss_locwise where fin_year=@cProfitFinYear and dept_id='01'


		SET @cStep='64'		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1

		SET @cPurGitFinyear='01'+dbo.fn_getfinyear(@dToDt)
	
		SELECT @dFinyearToDt = DBO.FN_GETFINYEARDATE(@cPurGitFinyear,2)


		SET @cStep='64.25'		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		SET @cCmd=N'UPDATE a SET 	purchases=a.purchases+b.purgitpp from #Trial_profitloss_locwise a JOIN 
					(SELECT dept_id, SUM(ppvalue) purgitpp FROM #tmpPendingDocsValues 
					 WHERE xn_type=''PURGIT'' GROUP BY dept_id) b ON a.dept_id=b.dept_id ' 
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	
		--select 'check after updating Purchase git', * from #Trial_profitloss_locwise where fin_year=@cProfitFinYear and dept_id='01'

		SET @cStep='65'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		UPDATE a SET 	DirectExpenses=b.DirectExpenses
		FROM #Trial_profitloss_locwise a JOIN 
		(
		SELECT cost_center_dept_id as dept_id, sum(debit_amount-credit_amount) as DirectExpenses
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		JOIN #tmpPlHeads thd ON thd.head_Code=lm.head_code  
		JOIN #locListC b  ON vd.cost_center_dept_id=b.dept_id
		where vm.fin_year=@cProfitFinYear AND  cancelled=0     
		AND voucher_dt<=@dToDt
		and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
		AND thd.bs_head_code IN ('0000000026')
		GROUP BY cost_center_dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear

		SET @cStep='70'
EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		DELETE FROM #year_wise_cbs

		SET @dXnDt=@dToDt

		SET @bEntryFound=0


		EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
		@dXnDt=@dXnDt,
		@bRetLocWise=1,
		@nCbp=@nCbp OUTPUT,
		@bEntryFound=@bEntryFound OUTPUT
	   	
		
		--if @cProfitfinyear='01121'
		--begin
		--	select 'check stock b4 loc wise',@bEntryFound EntryFound,@dXndt xn_dt,* from  #year_wise_cbs
		--end

		--Commented this Code because of recent issue found at Rainbow Apparels against Ticket#10-0572
		--They had mentioned CLosing stock manuallt only against HO instead of mentioning Location wise
		--Due to this , their Trial Balance was showing unbalanced due to wrong Pending PRofit component 
		--being carried forward..In the Evening meeting on 11-10-2021 ,Sir told that We shall consider manual stock for all Locations if it 
		-- is marked manual for a given Financial Year (Date:12-10-2021)
		--IF exists (select top 1 a.dept_id from #locListC a left join #year_wise_cbs b on a.dept_id=b.dept_id
		--			where b.dept_id is null) 
		IF @bEntryFound=0
		BEGIN
			SET @cStep='70.5'
EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1	
			--if @cProfitfinyear='01121'	
			--	select 'check getcbssstk'

			EXEC SP3S_GETCBSSTK_FOR_PLBS
			@dXnDt=@dXnDt,
			@nSpId=@@spid,
			@bCalledFromProfitCalc=1,
			@bCalledFromBs=@bCalledFromBs,
			@nRetOpsCbsMode=2,
			@nCbp=@nCbp OUTPUT,
			@cErrormsg=@cErrormsg OUTPUT

			if isnull(@cErrormsg,'')<>''
				goto end_proc
		END


		--if @cProfitfinyear='01124'
		--begin

		--	select 'check stock after loc wise',* from  #year_wise_cbs
		--end

		SET @cStep='71.8'
EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		UPDATE a SET 	CbsStkinHand=isnull(b.CbsStkinHand,0)
		FROM #Trial_profitloss_locwise a JOIN 
		(
		SELECT a.dept_id,SUM(cbp) as CbsStkinHand	FROM #year_wise_cbs a (NOLOCK) 
		JOIN #locListC b  ON a.dept_id=b.dept_id
		GROUP BY a.dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear

		SET @cStep='75'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		UPDATE a SET 	IndirectExpenses=b.IndirectExpenses
		FROM #Trial_profitloss_locwise a JOIN 
		(
		SELECT cost_center_dept_id as dept_id,sum(debit_amount-credit_amount) as IndirectExpenses 
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		JOIN #tmpPlHeads thd ON thd.head_Code=lm.head_code  
		JOIN #locListC b  ON vd.cost_center_dept_id=b.dept_id
		where vm.fin_year=@cProfitFinYear AND  cancelled=0     
		AND voucher_dt<=@dToDt
		and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
		AND thd.bs_head_code IN ('0000000027')
		GROUP BY cost_center_dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear

		SET @cStep='80'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		UPDATE a SET 	InCome=b.InCome
		FROM #Trial_profitloss_locwise a JOIN 
		(
		SELECT cost_center_dept_id as dept_id,sum(credit_amount-debit_amount) as InCome 
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		JOIN #tmpPlHeads thd ON thd.head_Code=lm.head_code  
		JOIN #locListC b  ON vd.cost_center_dept_id=b.dept_id
		where vm.fin_year=@cProfitFinYear AND  cancelled=0     
		AND voucher_dt<=@dToDt
		and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
		AND thd.bs_head_code IN ('0000000028')
		GROUP BY cost_center_dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear
		
		SET @cStep='85'				
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
	SELECT @cPlHeads = DBO.FN_ACT_TRAVTREE('0000000009')
		
			SET @cStep='90'
EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		UPDATE a SET 	PlXferred=b.PlXferred
		FROM #Trial_profitloss_locwise a JOIN 
		(
		SELECT cost_center_dept_id as dept_id,sum(debit_amount-credit_amount) as PlXferred  
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		JOIN #locListC b  ON vd.cost_center_dept_id=b.dept_id
		where vm.fin_year=@cProfitFinYear AND  cancelled=0  AND CHARINDEX(lm.head_code,@cPlHeads)>0   
		and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')  
		AND voucher_dt<=@dToDt
		GROUP BY cost_center_dept_id
		) b ON a.dept_id=b.dept_id 
		WHERE fin_year=@cProfitFinYear

	SET @cStep='95'	                    		
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
		print 'Calculate profit for FIn year:'+@cProfitFinYear
		UPDATE a SET profit_carried_fwd=ISNULL(b.NetProfitLossAmt,0),
		NetProfitLossAmt=ISNULL(b.NetProfitLossAmt,0)+
							(ISNULL(OpnStkinHand,0)-ISNULL(CbsStkinHand,0)+ISNULL(purchases,0)-isnull(sales,0) +
							ISNULL(DirectExpenses,0)+ISNULL(IndirectExpenses,0)-ISNULL(Income,0)+
							ISNULL(PlXferred,0))
		FROM #Trial_profitloss_locwise a LEFT OUTER JOIN 
		(SELECT dept_id,NetProfitLossAmt FROM Trial_profitloss_locwise WHERE fin_year= @cPrevFinYear) b ON a.dept_id=b.dept_id							
		WHERE fin_year=@cProfitFinYear


		--if @@spid=51
		--begin
			
		--	select 'check profit loss calc',* FROM #Trial_profitloss_locwise
		--	--kcselect 'year wise cbs',* from #year_wise_cbs
		--end

		If @bCalledFromBs=0
		BEGIN
			 SET @cStep='100'
			 EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
			 DELETE a FROM Trial_profitloss_locwise a JOIN  #Trial_profitloss_locwise b ON a.fin_year=b.fin_year AND a.dept_id=b.dept_id

			 --if @cProfitfinyear='01121'
				--select 'check final profit',* from #Trial_profitloss_locwise

			 SET @cStep='105'	
			 EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cProfitFinYear,1
			 INSERT Trial_profitloss_locwise	( cbsstkinhand, dept_id, directexpenses, fin_year, income, Indirectexpenses, NetProfitLossAmt, OpnStkinHand, plxferred, profit_carried_fwd, purchases, revenuexns, sales )  
			 SELECT a.cbsstkinhand, a.dept_id, a.directexpenses, a.fin_year, a.income, a.Indirectexpenses, 
			 a.NetProfitLossAmt, a.OpnStkinHand, a.plxferred, a.profit_carried_fwd, a.purchases, a.revenuexns, 
			 a.sales  FROM #Trial_profitloss_locwise a 

			 DELETE FROM #Trial_profitloss_locwise
		END
		
lblNextYear:
		SET @cPrevFinYear=@cProfitFinYear
		SET @dStartVoucherDt=DATEADD(YY,1,@dStartVoucherDt)
	END	
	
	update vch_last_saved set voucher_dt=@dStartVoucherDt

	GOTO END_PROC
END TRY

BEGIN CATCH
	print 'catch of SP3S_GETPROFITAMOUNT_TRIALBALANCE:'
	SET @cErrormsg='Error in Procedure SP3S_GETPROFITAMOUNT_TRIALBALANCE at Step#'+@cStep+' '+ERROR_MESSAGE()
	print 'catch of SP3S_GETPROFITAMOUNT_TRIALBALANCE:'+@cErrormsg
	GOTO END_PROC
END CATCH

END_PROC:
	
	--if @bCalledFromBs=1 and @@spid=448
	--begin
	--	select 'check pl details',* from  #Trial_profitloss_locwise
	--	select 'check #loclistc',* from  #loclistC
	--end
	print 'Came to the end of SP3S_GETPROFITAMOUNT_TRIALBALANCE'
	IF @bCalledFromBs=1
		INSERT #tProfit (errmsg,calc_profit,profit_carried_fwd,PlXferred,final_profit)
		SELECT ISNULL(@cErrormsg,'') errmsg,SUM(NetProfitLossAmt-isnull(profit_carried_fwd,0)-isnull(PlXferred,0)) calc_profit,
		sum(profit_carried_fwd) profit_carried_fwd,SUM(PlXferred) PlXferred,
		SUM(NetProfitLossAmt) final_profit FROM #Trial_profitloss_locwise a JOIN #locListC b ON a.dept_id=b.dept_id

	
	IF NOT EXISTS (SELECT log_dt from logprofit_build (NOLOCK) WHERE log_dt=CONVERT(DATE,GETDATE()))
		INSERT INTO logprofit_build (log_dt)
		SELECT convert(date,getdate())
	
	UPDATE logprofit_build set errmsg=isnull(@cErrormsg,''),last_update=getdate() WHERE LOG_DT=convert(date,getdate())


	--select @cErrormsg errmsg
		 --SELECT 	sum(cbsstkinhand) cbsstk, sum(directexpenses) dexp,sum(income) income,
		 --sum(Indirectexpenses) indexp, sum(NetProfitLossAmt) NetProfitLossAmt, 
		 --sum(OpnStkinHand) OpnStkinHand , sum(plxferred)  plxferred,sum(profit_carried_fwd) profit_carried_fwd,
		 --sum(purchases) purchases,sum(revenuexns) revenuexns,sum(sales) sales  
		 --FROM #Trial_profitloss_locwise

END	