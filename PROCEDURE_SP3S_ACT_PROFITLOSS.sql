CREATE PROCEDURE SP3S_ACT_PROFITLOSS--(LocId 3 digit change by Sanjay:04-11-2024)
@cFinYear VARCHAR(5)='',
@nSpId VARCHAR(50)='',
@dFromDtPara DATETIME='',
@dToDtPara DATETIME='',
@nViewMode NUMERIC(1,0)=1, -- 1.As per IT act 2.For Internal use
@cCompanyPanNo VARCHAR(50)=''
AS    
BEGIN    
 --DECLARE @dFromDt DATETIME='2019-03-01'  ,@dToDt DATETIME  ='2019-09-26'  
BEGIN TRY    
	
	IF @nSpId=''
		SET @nSpId=LTRIM(RTRIM(STR(@@spid)))

	DECLARE @cStep VARCHAR(10),@cErrormsg varchar(max),@cCmd NVARCHAR(MAX),@dFinYearFromDt DATETIME,
	@dFinYeartoDt DATETIME,@nGrossProfitLossAmt NUMERIC(20,2),@nNetProfitLossAmt NUMERIC(20,2),
	@CDONOTPICKOBHEADS VARCHAR(1000),@nTotalSales NUMERIC(20,2),@cDtSuffix VARCHAR(20),@dCbsXnDt DATETIME

	SELECT @CDONOTPICKOBHEADS = DBO.FN_ACT_TRAVTREE('0000000010')
	
	IF @dFromDtPara<>''
		SET @cFinYear='01'+dbo.fn_getfinyear(@dFromDtPara)
    ELSE
		SELECT  @dFromDtPara=dbo.FN_GETFINYEARDATE(@cFinYear,1),@dToDtPara=dbo.FN_GETFINYEARDATE(@cFinYear,2)


		
	SET @cStep='10'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

	CREATE TABLE #locListc (dept_id VARCHAR(4))

	IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')
		INSERT #locListc
		SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId
	ELSE
		INSERT #locListc
		SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)

	--if @@spid=51
	--	select 'check loccnt in p&l',@nSpId,count(*) from #locListc

	CREATE TABLE #tmpHeads (head_Code char(10),pl_child_head_code char(10),pl_head_code CHAR(10),pl_head_name varchar(200),
	srno NUMERIC(5,2),processed BIT,donotpickob BIT)  
	

	SET @cCmd=N'
	SELECT head_code,'''','''','''',3,0,0 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000026')+')  
	UNION   
	SELECT head_code,'''','''','''',8,0,0 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000027')+')  
	UNION   
	SELECT head_code,'''','''','''',9,0,0 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000028')+')  
	UNION   		
	SELECT head_code,'''','''','''',2,0,0 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000029')+')
	UNION   
	SELECT head_code,'''','''','''',4,0,0 FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000030')+')
	'  

	INSERT #tmpHeads  
	EXEC SP_EXECUTESQL @cCmd  

	SET @cStep='20'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	UPDATE #tmpHeads SET pl_child_head_code=dbo.FN_GET_PLHEADCODE(head_code)  
	
	SET @cStep='25'    
	print 'Update major head names'
	UPDATE a SET pl_head_code=b.head_code,pl_head_name=b.head_name FROM #tmpHeads a  
	JOIN hd01106 b ON a.pl_child_head_code=b.head_code  
	WHERE b.head_code IN ('0000000026','0000000027','0000000028','0000000029','0000000030')

	UPDATE #tmpHeads SET donotpickob=0
	UPDATE #tmpHeads SET donotpickob=1 WHERE CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0
	
		
	SET @cStep='30'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	UPDATE #tmpHeads SET pl_head_code=pl_child_head_code 
	WHERE pl_head_code=''
	

	--select 'check #tmpHeads',* from #tmpHeads
	
	PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)    
	create table #temp (head_code CHAR(10),pl_head_code CHAR(10),pl_head_name varchar(200),head_name varchar(500),Ac_name varchar(500),
	DebitAmount numeric(30, 2),CreditAmount numeric(30,2),pl_head_name_BAK VARCHAR(200),HEAD_NAME_BAK VARCHAR(200),row_no int identity,srno NUMERIC(2,0),mode NUMERIC(1,0),total_level NUMERIC(1,0))     

	SET @cStep='33'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	SELECT @dFinYearFromDt=DBO.FN_GETFINYEARDATE(@cFinYear,1),@dFinYeartoDt=DBO.FN_GETFINYEARDATE(@cFinYear,2)

	DECLARE @dPlDt datetime,@nCbp NUMERIC(20,2),@bEntryFound BIT

	SELECT @bEntryFound=0

	SET @dPlDt=@dFromDtPara-1
		
	EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
	@dXnDt=@dPlDt,
	@nCbp=@nCbp OUTPUT,
	@bEntryFound=@bEntryFound OUTPUT
	
	IF @bEntryFound=0
	BEGIN
		SET @cStep='37'    
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

		--if @@spid=553
		--	select 'Start of calculating plbs for ops'

		SET @dCbsXnDt=@dPlDt

		EXEC SP3S_GETCBSSTK_FOR_PLBS
		@dXnDt=@dCbsXnDt,
		@nSpId=@nSpId,
		@bCalledfromPl=1,
		@nPlBsViewMode=@nViewMode,
		@nRetOpsCbsMode=2,
		@nCbp=@nCbp OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT

		--if @@spid=553
		--	select 'End of calculating plbs for ops'

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END

	--if @@spid=98 
	--	select @bEntryFound opsentryfound,@dPlDt,@nCbp,* from #loclistC

  	 SELECT @cDtSuffix='('+CONVERT(VARCHAR,@dPlDt+1,105)+')'
    

	SET @cStep='40'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	INSERT #temp (pl_head_name,head_code,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
	SELECT 'Stock in Hand' as pl_head_name,'' head_code,'Stock in Hand' as head_name,'Opening Stock'+@cDtSuffix as ac_name,
	@nCbp as debitamount,0 as creditamount,1 as srno,1 as mode
	
	SET @cStep='50'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	insert #temp (pl_head_code,pl_head_name,head_code,head_name,Ac_name,DebitAmount, CreditAmount,mode)    
	select plhd.head_code as pl_head_code,plhd.head_name as pl_head_name,hd.head_code,hd.head_name,lm_major.Ac_name, 
	sum(debit_amount-credit_amount) as DebitAmount, 0 as CreditAmount,1 as mode
	from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
	join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
	join lm01106 lm_major (NOLOCK) on lm_major.AC_CODE = lm.major_ac_code
	join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
	JOIN #tmpHeads thd ON thd.head_Code=lm.head_code  
	JOIN hd01106 plhd on plhd.head_code=thd.pl_head_code  
	JOIN hd01106 hd on hd.head_code=lm.head_code  
	JOIN #locListc l ON l.dept_id=vd.cost_center_dept_id
	where ((vm.fin_year<=@cFinYear AND donotpickob=0) 
			OR (vm.fin_year=@cFinYear AND donotpickob=1))  AND  cancelled=0     
	and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
	AND voucher_Dt between @dFromDtPara AND @dToDtPara
	AND pl_head_code IN ('0000000026','0000000029','0000000030')
	GROUP BY plhd.head_code,plhd.head_name,hd.head_code,hd.head_name,lm_major.Ac_name  

	--select 'check level-1',* from #temp

	SET @cStep='52'    
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

	SET @bEntryFound=0

	EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
	@dXnDt=@dToDtPara,
	@nCbp=@nCbp OUTPUT,
	@bEntryFound=@bEntryFound OUTPUT

	IF @bEntryFound=0
	BEGIN
		SET @cStep='55'    

		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

		--if @@spid=553
		--	select 'Start of calculating plbs for cbs'
		
		set @dCbsXnDt=@dToDtPara
		EXEC SP3S_GETCBSSTK_FOR_PLBS
		@dXnDt=@dCbsXnDt,
		@nSpId=@nSpId,
		@bCalledfromPl=1,
		@nPlBsViewMode=@nViewMode,
		@nRetOpsCbsMode=2,
		@nCbp=@nCbp OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT
	
	--if @@spid=553
	--		select 'End of calculating plbs for cbs'
		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END			

	--if @@spid=51
	--	select 'P&L CBs',@dToDtPara,@nCbp
	SET @cStep='60'
	SELECT 'WSL'+a.inv_id memo_id,a.party_dept_id dept_id into #tmpPendingDocsMemos
	FROM inm01106 a (NOLOCK)  where 1=2

	CREATE TABLE #tmpPendingDocsValues (dept_id VARCHAR(4),xn_type VARCHAR(10),ppvalue NUMERIC(14,2))
		
	--- Need to do this becasue below common procedure called from many places is looking for this table
	CREATE TABLE #locList (dept_id VARCHAR(4),pan_no varchar(100))

	INSERT INTO #LocList(dept_id,pan_no)
	select a.dept_id,b.PAN_NO from #locListC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id

	EXEC spact_Getlocwise_gitValue @dToDtPara,1

	set @cStep='62'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

	if exists (select top 1 ppvalue FROM #tmpPendingDocsValues WHERE xn_type='PURGIT' AND ISNULL(ppvalue,0)<>0)
		INSERT #temp (pl_head_name,head_Code,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PURCHASE' as pl_head_name,'' head_Code, 'Party Purchase(GIT)' as head_name,'' as ac_name,sum(ppvalue) as debitamount,
		0 as creditamount,2 as srno,1 as mode FROM #tmpPendingDocsValues WHERE xn_type='PURGIT'

	if exists (select top 1 ppvalue FROM #tmpPendingDocsValues WHERE xn_type='GIT' AND ISNULL(ppvalue,0)<>0)
		INSERT #temp (pl_head_name,head_Code,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PURCHASE' as pl_head_name,'' head_Code, 'Group Purchase(GIT)' as head_name,'' as ac_name,sum(ppvalue) as debitamount,
		0 as creditamount,2 as srno,1 as mode FROM #tmpPendingDocsValues WHERE xn_type='GIT' AND ISNULL(ppvalue,0)<>0


	
	SELECT @cDtSuffix='('+CONVERT(VARCHAR,@dToDtPara,105)+')'

	INSERT #temp (pl_head_name,head_Code,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
	SELECT 'Stock in Hand' as pl_head_name,'' head_Code, 'Stock in Hand' as head_name,'Closing Stock'+@cDtSuffix as ac_name,0 as debitamount,
	@nCbp as creditamount,5 as srno,1 as mode
	
	SET @cStep='70'    
	SELECT @nGrossProfitLossAmt=SUM(debitamount-creditamount) FROM #temp
	
	IF @nGrossProfitLossAmt>0
		INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Gross Loss c/o' AS 
		ac_name,0 as debitamount,@nGrossProfitLossAmt as creditamount,6 as srno,1 as mode
		UNION ALL
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Gross Loss b/f' as
		ac_name,@nGrossProfitLossAmt as debitamount,0 as creditamount,7 as srno,2 as mode
	ELSE
		INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Gross Profit c/o' AS 
		ac_name,@nGrossProfitLossAmt*-1 as debitamount,0 as creditamount,6 as srno,1 as mode
		UNION ALL
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Gross Profit b/f' as
		ac_name,0 as debitamount,@nGrossProfitLossAmt*-1 as creditamount,7 as srno,2 as mode		

	SET @cStep='80'    
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	insert #temp (pl_head_code,pl_head_name,head_Code,head_name,Ac_name,DebitAmount, CreditAmount,mode)    
	select plhd.head_code,plhd.head_name as pl_head_name,hd.head_code,hd.head_name,lm_major.Ac_name, 
	sum(debit_amount-credit_amount) as DebitAmount,  
	0 as CreditAmount,2 as mode  
	from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
	join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
	join lm01106 lm_major (NOLOCK) on lm_major.AC_CODE = lm.major_ac_code
	join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
	JOIN #tmpHeads thd ON thd.head_Code=lm.head_code  
	JOIN hd01106 plhd on plhd.head_code=thd.pl_head_code  
	JOIN hd01106 hd on hd.head_code=lm.head_code  
	JOIN #locListc l ON l.dept_id=vd.cost_center_dept_id
	where ((vm.fin_year<=@cFinYear AND donotpickob=0 ) OR (vm.fin_year=@cFinYear AND donotpickob=1)) AND  cancelled=0     
	and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
	AND voucher_Dt between @dFromDtPara AND @dToDtPara
	AND pl_head_code IN ('0000000027','0000000028')
	GROUP BY plhd.head_code,plhd.head_name,hd.HEAD_CODE,hd.head_name,lm_major.Ac_name  
	

	--select * into tmpexpense from #temp 
	--select 'check level-2',* from #temp where pl_head_code='0000000027'

	SET @cStep='90'    
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	UPDATE #temp SET creditamount=abs(debitamount) where debitamount<0
	UPDATE #temp SET debitamount=0 where debitamount<0

	SELECT @nNetProfitLossAmt=SUM(debitamount-creditamount) FROM #temp
	WHERE pl_head_code IN ('0000000027','0000000028')
	
	SET @cStep='102'    
	SELECT @nNetProfitLossAmt=@nGrossProfitLossAmt+ISNULL(@nNetProfitLossAmt,0)
	
	IF @nNetProfitLossAmt<0
		INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Net Profit' AS 
		ac_name,ABS(@nNetProfitLossAmt) as debitamount,0 as creditamount,10 as srno,2 as mode
	ELSE
		INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
		SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,'Net Loss' AS 
		ac_name,0 as debitamount,@nNetProfitLossAmt as creditamount,10 as srno,2 as mode
	
	SET @cStep='106'   
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	UPDATE a set srno=b.srno FROM #temp a
	JOIN (SELECT distinct pl_head_name,srno FROM #tmpheads) b ON a.pl_head_name=b.pl_head_name
	
	UPDATE #temp SET total_level=0
			
	SET @cStep='107'    		
	insert #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,total_level)    
	select pl_head_name,'' head_name,'Total : ' as Ac_name, SUM(DEBITAMOUNT) AS DEBITAMOUNT,SUM(CREDITAMOUNT) AS CREDITAMOUNT,mode,1 as total_level
	FROM   #temp WHERE srno in (2,3,4,8,9)
	GROUP BY pl_head_name,mode  


	insert #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,srno,total_level)    
	select 'Trading Total : ' pl_head_name,'' head_name,'Trading Total : ' as Ac_name, SUM(DEBITAMOUNT) AS DEBITAMOUNT,
	SUM(CREDITAMOUNT) AS CREDITAMOUNT,1 mode,6.5 srno,1 as total_level
	FROM   #temp WHERE srno<=6 AND total_level=0

	insert #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,srno,total_level)    
	select 'P&L Total : ' pl_head_name,'' head_name,'P&L Total : ' as Ac_name, SUM(DEBITAMOUNT) AS DEBITAMOUNT,SUM(CREDITAMOUNT) AS CREDITAMOUNT,
	2 mode,99 srno,1 as total_level 
	FROM   #temp WHERE srno>=7 AND total_level=0
	
	--insert #temp (mode,head_name,Ac_name,DebitAmount, CreditAmount,srno,total_level)  
	--select mode,'ZZZZZZZZZZ' as head_name,'Grand Total : ' as Ac_name, 
	--SUM(DEBITAMOUNT) AS DEBITAMOUNT,  SUM(CREDITAMOUNT) AS CREDITAMOUNT,max(srno)+10 as srno,2 as total_level
	--FROM  #temp 
	--WHERE srno<>10 AND Ac_name NOT IN ('Total :')
	--GROUP BY mode

	SET @cStep='108.5'    		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	DECLARE @nGpPct NUMERIC(20,2),@nNpPct NUMERIC(20,2)

	SELECT @nTotalSales=ABS(debitamount-creditamount) FROM #temp WHERE pl_head_name='SALES' and total_level=1
	IF ISNULL(@nTotalSales,0)<>0
	BEGIN
		--if @@spid=83
		--	select @nGrossProfitLossAmt gross_profit,@nTotalSales total_sales_for_profit_calc
		SELECT @nGpPct=CONVERT(NUMERIC(20,2),@nGrossProfitLossAmt*100/@nTotalSales),
			   @nNpPct=CONVERT(NUMERIC(20,2),@nNetProfitLossAmt*100/@nTotalSales)
	END

	SET @cStep='108.8'    		
	INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
	SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,
	(CASE WHEN  @nGrossProfitLossAmt<0 THEN 'Gross Profit(%)' ELSE 'Gross Loss(%)' END) AS ac_name,
	(CASE WHEN  @nGrossProfitLossAmt<0 THEN ABS(@nGpPct) ELSE 0 END) as debitamount,
	(CASE WHEN  @nGrossProfitLossAmt>0 THEN @nGpPct ELSE 0 END) as creditamount,7 as srno,1 as mode

	SET @cStep='109.2'    		
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	INSERT #temp (pl_head_name,head_name,Ac_name,DebitAmount, CreditAmount,srno,mode)   
	SELECT 'PROFIT  &  LOSS A/C' as pl_head_name,'PROFIT  &  LOSS A/C' as head_name,
	(CASE WHEN  @nNetProfitLossAmt<0 THEN 'Net Profit(%)' ELSE 'Net Loss(%)' END) AS ac_name,
	(CASE WHEN  @nNetProfitLossAmt<0 THEN ABS(@nNpPct) ELSE 0 END) as debitamount,
	(CASE WHEN  @nNetProfitLossAmt>0 THEN @nNpPct ELSE 0 END) as creditamount,11 as srno,2 as mode

	SET @cStep='112'   
	UPDATE a set srno=b.srno FROM #temp a
	JOIN (SELECT distinct pl_head_name,srno FROM #tmpheads) b ON a.pl_head_name=b.pl_head_name
		
	SET @cStep='120'    
	IF OBJECT_ID('tempdb..#temp_output','u') is not null    
		drop table #temp_output

	select ROW_NUMBER() OVER(PARTITION BY pl_head_name ,head_Code,head_name ORDER BY total_level,pl_head_name ,head_name,ac_name) AS rNO,srno,
	pl_head_name AS pl_head_name,head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,mode,pl_head_name AS DISPLAY_plhead_name,head_name AS DISPLAY_head_name,
	Ac_name AS DISPLAY_Ac_name,row_no,total_level
	INTO #temp_output
	from #temp ORDER BY row_no  
	
	SET @cStep='130'    
	
	UPDATE #temp_output SET DISPLAY_head_name=''--,DISPLAY_Ac_name=CASE WHEN MODE>1 THEN '' ELSE DISPLAY_Ac_name END 
	WHERE rno >1 and pl_head_name not in ('stock in hand','PROFIT  &  LOSS A/C')

	
	UPDATE #temp_output SET DebitAmount= NULL WHERE DebitAmount=0

	UPDATE #temp_output SET CreditAmount= NULL WHERE CreditAmount=0
	
	SET @cStep='140'    
	--UPDATE #temp_output SET pl_head_name='CURRENT LIABILITIES', head_name='SUNDRY CREDITORS'  WHERE mode =1 AND pl_head_name='CURRENT ASSETS' AND  CreditAmount<>0 
	--UPDATE #temp_output SET  pl_head_name='CURRENT ASSETS',head_name='SUNDRY DEBTORS'  WHERE mode =1 AND pl_head_name='CURRENT LIABILITIES' AND  DebitAmount<>0 
	
	--SELECT distinct pl_head_name,srno FROM #tmpheads
	
	SELECT pl_head_name, head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,DISPLAY_head_name,DISPLAY_Ac_name,mode,srno,row_no,total_level
	from #temp_output   
	ORDER BY mode,srno,pl_head_name,total_level,head_name,Ac_name
	
	SET @cStep='200'
		EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='PROFITLOSS_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
	  	DROP TABLE PROFITLOSS_CURSOR

	IF  OBJECT_ID('PROFITLOSS_CURSOR','U') IS NULL	
	BEGIN
		SELECT head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,DISPLAY_head_name,DISPLAY_Ac_name,mode
		INTO PROFITLOSS_CURSOR     
		FROM #temp_output    
		WHERE 1=2
	END


END TRY     

BEGIN CATCH    
	SET @cErrormsg='Error in Procedure SP3S_ACT_PROFITLOSS at Step#'+@cStep+':'+ERROR_MESSAGE()    
	goto end_proc    
END CATCH    

end_proc:    
	IF ISNULL(@cErrormsg,'')<>''    
		select ISNULL(@cErrormsg,'') as DISPLAY_head_name    
END    
---End SP3S_ACT_PROFITLOSS----------------------------------- 