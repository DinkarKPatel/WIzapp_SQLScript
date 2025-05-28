CREATE PROCEDURE SP3S_ACT_BALANCESHEET--(LocId 3 digit change by Sanjay:04-11-2024)
@cFinYear VARCHAR(5)='',
@nSpId VARCHAR(50)='',
@dFromDtPara DATETIME='',
@dToDtPara DATETIME='',
@nMode NUMERIC(1,0)=1,		---1.Summary 2.Detailed
@nViewMode NUMERIC(1,0)=1,
@cCompanyPanNo VARCHAR(50)=''
AS    
BEGIN    
 --DECLARE @dFromDt DATETIME='2019-03-01'  ,@dToDt DATETIME  ='2019-09-26'  
BEGIN TRY    

	DECLARE @cStep VARCHAR(4),@cErrormsg varchar(max),@cCmd NVARCHAR(MAX) ,@cDtSuffix VARCHAR(20),@cViewBSForCancelledVouchers VARCHAR(20)

	SET @cStep='10'    
	SELECT TOP 1 @cViewBSForCancelledVouchers=value FROM config WHERE config_option='LEDGER_OPENING_CUTOFF_DATE'    

	CREATE TABLE  #tProfit  (errmsg varchar(1000),calc_profit NUMERIC(20,2),profit_carried_fwd NUMERIC(20,2),plxferred NUMERIC(20,2),
	final_profit NUMERIC(20,2))

	CREATE TABLE #locListC (dept_id varCHAR(5))

	IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')
		INSERT #locListc
		SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId
	ELSE
		INSERT #locListc
		SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)
	
	--if @@spid=51
	--	select 'check loccnt in bs',@nSpId,count(*) from #locListc
	
	DECLARE @CDONOTPICKOBHEADS VARCHAR(MAX),@cProfitFinYear VARCHAR(10)

    SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    

	SET @cProfitFinYear='01'+dbo.fn_getfinyear(@dTodtPara)

	--select 'check ob heads',* from hd01106 where charindex(head_code,@CDONOTPICKOBHEADS)>0

	IF OBJECT_ID('tempdb..#tmpHeads','u') is not null    
		drop table #tmpHeads    

	CREATE TABLE #tmpHeads (head_Code char(10),bs_child_head_code char(10),bs_head_code CHAR(10),
	bshead_name varchar(1000),srno numeric(1,0),donotpickob BIT,debtor_head BIT)  
	

	
	SET @cStep='15'    
	SET @cCmd=N'
	SELECT head_code,'''','''','''',1 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000001')+')  
	UNION
	SELECT head_code,'''','''','''',1 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000002')+')  
	UNION   
	SELECT head_code,'''','''','''',2 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000007')+')  
	UNION   
	SELECT head_code,'''','''','''',3 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000004')+')  
	UNION   
	SELECT head_code,'''','''','''',4 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000003')+')
	UNION   
	SELECT head_code,'''','''','''',4 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00034')+')
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000005')+')  	
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000008')+') 
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000011')+')  	
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000006')+')  	
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00032')+')  	
	UNION   
	SELECT head_code,'''','''','''',5 as srno FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('00DEF00033')+')  	
	'
	
	

	INSERT #tmpHeads (head_code,bs_child_head_code, bs_head_code,bshead_name,srno)
	EXEC SP_EXECUTESQL @cCmd  

	SET @cStep='20'    
	UPDATE #tmpHeads SET bs_child_head_code=dbo.FN_GET_BSHEADCODE(head_code)  

	UPDATE a SET bs_head_code=b.major_head_code,bshead_name=c.head_name FROM #tmpHeads a  
	JOIN hd01106 b ON a.bs_child_head_code=b.head_code
	JOIN hd01106 c ON b.major_head_code=c.head_code

	SET @cStep='22'    
	UPDATE #tmpHeads SET donotpickob=0
	UPDATE #tmpHeads SET donotpickob=1 WHERE CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0

	SET @cStep='25'    

	UPDATE #tmpHeads SET debtor_head=1
	WHERE CHARINDEX(head_code,DBO.FN_ACT_TRAVTREE('0000000018'))>0


	SET @cStep='32.5'    
	PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)    
	create table #temp (bshead_name varchar(200),head_name varchar(500),Ac_name varchar(500),DebitAmount numeric(20, 2),   
	CreditAmount numeric(20,2),mode INT,BSHEAD_NAME_BAK VARCHAR(200),HEAD_NAME_BAK VARCHAR(200),entry_order numeric(2,0))     

	--select 'check @LOCLISTC',* from @LOCLISTC

	SET @cCmD=N'select bshd.head_name as bshead_name,hd.head_name,'+
	(case when @nMode=2 THEN 'lm_major.Ac_name' ELSE '''''' END)+' ac_name, 
	case when sum(debit_amount-credit_amount)>0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end  as DebitAmount,  
	case when  sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount  
	,1 as mode 	
	from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
	join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
	join lm01106 lm_major (NOLOCK) on lm_major.AC_CODE = lm.major_ac_code
	join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
	JOIN #tmpHeads thd ON thd.head_Code=lm.head_code  
	JOIN hd01106 bshd on bshd.head_code=thd.bs_head_code  
	JOIN hd01106 hd on hd.head_code=thd.bs_child_head_code  
	JOIN #LOCLISTC l ON l.dept_id=vd.cost_center_dept_id
	where vm.fin_year='''+@cProfitFinYear+''' 
	and vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like ''%memo%'')    
	AND voucher_dt<='''+CONVERT(VARCHAR,@dToDtPara,110)+''' and thd.head_code <>''0000000017'' 
	AND donotpickob=1
	AND  ((CANCELLED=0 AND ISNULL(debtor_head,0)=0)
    OR (VOUCHER_DT>'''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+''' AND ISNULL(debtor_head,0)=1 AND cancelled=0)
    OR ('''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
     AND VOUCHER_DT<='''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+''' AND ISNULL(debtor_head,0)=1))  

	GROUP BY  bshd.head_name,hd.head_name'+(case when @nMode=2 THEN ',lm_major.Ac_name' ELSE '' END)+'
	HAVING sum(DEBIT_AMOUNT - CREDIT_AMOUNT)<>0
	
	UNION ALL
	select bshd.head_name as bshead_name,hd.head_name,'+
	(case when @nMode=2 THEN 'lm_major.Ac_name' ELSE '''''' END)+' ac_name, 
	case when sum(debit_amount-credit_amount)>0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end  as DebitAmount,  
	case when  sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount  
	,1 as mode 	
	from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
	join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
	join lm01106 lm_major (NOLOCK) on lm_major.AC_CODE = lm.major_ac_code
	join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
	JOIN #tmpHeads thd ON thd.head_Code=lm.head_code  
	JOIN hd01106 bshd on bshd.head_code=thd.bs_head_code  
	JOIN hd01106 hd on hd.head_code=thd.bs_child_head_code  
	JOIN #LOCLISTC l ON l.dept_id=vd.cost_center_dept_id
	where voucher_dt<='''+CONVERT(VARCHAR,@dToDtPara,110)+''' AND vch.VOUCHER_CODE not in 
	(select VOUCHER_CODE from vchtype where VOUCHER_TYPE like ''%memo%'')    
	and thd.head_code <>''0000000017'' AND donotpickob=0
	AND  ((CANCELLED=0 AND ISNULL(debtor_head,0)=0)
    OR (VOUCHER_DT>'''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+''' AND ISNULL(debtor_head,0)=1 AND cancelled=0)
    OR ('''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
     AND VOUCHER_DT<='''+CONVERT(VARCHAR,@cViewBSForCancelledVouchers,110)+''' AND ISNULL(debtor_head,0)=1))  
	GROUP BY  bshd.head_name,hd.head_name'+(case when @nMode=2 THEN ',lm_major.Ac_name' ELSE '' END)+'
	HAVING sum(DEBIT_AMOUNT - CREDIT_AMOUNT)<>0
	'

	print @cCmd
	insert #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)    
	EXEC SP_EXECUTESQL @cCmd

	--select 'checkk #tmpheads',* from #tmpHeads 

	SET @cStep='34'    
	--select 'check #temp',c.donotpickob, a.* from #temp a join hd01106 b on a.head_name=b.head_name
	--join #tmpheads c on c.bs_child_head_code=b.head_code

	DECLARE @bEntryFound BIT,@nCbP NUMERIC(20,2)

	SET @bEntryFound=0
	EXEC SP3S_GETMANUAL_ACCOUNTS_CBS
	@dXnDt=@dToDtPara,
	@nCbp=@nCbp OUTPUT,
	@bEntryFound=@bEntryFound OUTPUT
	   	
	IF @bEntryFound=0 
	BEGIN
		SET @cStep='37'    
		EXEC SP3S_GETCBSSTK_FOR_PLBS
		@dXnDt=@dToDtPara,
		@nSpId=@nSpId,
		@bCalledfromBs=1,
		@nRetOpsCbsMode=2,
		@nCbp=@nCbp OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT
	
		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
	END		

	SET @cStep='38'
	SELECT @cDtSuffix='('+CONVERT(VARCHAR,@dToDtPara,105)+')'

	--if @@spid='51'
	--	select 'Balance sheet cbs',@dToDtPara,@nCbp
	--- Need to do this becasue below common procedure called from many places is looking for this table
	CREATE TABLE #locList (dept_id varchar(4),pan_no varchar(100))

	INSERT INTO #LocList(dept_id,pan_no)
	select a.dept_id,b.PAN_NO from #locListC a JOIN location b (NOLOCK) ON b.dept_id=a.dept_id


	set @cStep='39.5'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

	SELECT 'WSL'+a.inv_id memo_id,a.party_dept_id dept_id into #tmpPendingDocsMemos
	FROM inm01106 a (NOLOCK)  where 1=2

	CREATE TABLE #tmpPendingDocsValues (dept_id VARCHAR(4),xn_type VARCHAR(10),ppvalue NUMERIC(14,2))

	set @cStep='40.5'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1

	EXEC spact_Getlocwise_gitValue @dToDtPara,1

	set @cStep='42'
	EXEC SP_CHKXNSAVELOG 'profit',@cStep,0,@NSPID,@cFinYear,1
	
	
	if exists (select top 1 ppvalue FROM #tmpPendingDocsValues WHERE xn_type='PURGIT' AND ISNULL(ppvalue,0)<>0)
		INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)   
		SELECT 'BRANCH/DIVISIONS' as bshead_name,'Party Purchase(GIT)' as head_name,'' as ac_name,0 as debitamount,
		sum(ppvalue) as creditamount,1 as mode FROM #tmpPendingDocsValues WHERE xn_type='PURGIT'

	if exists (select top 1 ppvalue FROM #tmpPendingDocsValues WHERE xn_type='GIT' AND ISNULL(ppvalue,0)<>0)
		INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)
		SELECT 'BRANCH/DIVISIONS' as bshead_name, 'Group Purchase(GIT)' as head_name,'' as ac_name,0 as debitamount,
		sum(ppvalue) as creditamount,1 as mode FROM #tmpPendingDocsValues WHERE xn_type='GIT' AND ISNULL(ppvalue,0)<>0

	SET @cStep='45'    	
	INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)   
	SELECT 'Current Assets' as bshead_name,'Stock in Hand'+(CASE WHEN @nMode=1 THEN @cDtSuffix ELSE '' END) as head_name,
	(CASE WHEN @nMode=2 THEN 'Closing Stock'+@cDtSuffix ELSE '' END) as ac_name,
	@nCbp as debitamount,
	0 as creditamount,1 as mode
	
	IF @nMode IN (1,2)
	BEGIN
		
		SET @cStep='55'	
		insert #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)  
		select 'BS Totals' bshead_name,'ZZZZZZZZZZ' as head_name,'BS Totals : ' as Ac_name, 
		SUM(DEBITAMOUNT) AS DEBITAMOUNT,  SUM(CREDITAMOUNT) AS CREDITAMOUNT   ,2 as mode 
		FROM   #temp 
		WHERE mode=1
	END

	declare @nCalcProfit numeric(20,2),@nProfitCf NUMERIC(20,2),@nPlXferred NUMERIC(20,2),@nFinalProfit NUMERIC(20,2)	
	
	IF (DATEPART(DD,@dTodtPara)=31 AND DATEPART(MM,@dToDtPara)=3)
	BEGIN  
		SET @cStep='42' 
		SELECT @nFinalProfit=SUM(NetProfitLossAmt) ,@nProfitCf=sum(profit_carried_fwd) ,
		@nPlXferred=SUM(PlXferred) ,@nCalcProfit=SUM(NetProfitLossAmt-isnull(profit_carried_fwd,0)-isnull(PlXferred,0))
		FROM Trial_profitloss_locwise A (NOLOCK)       
		JOIN #LOCLISTC LOCLIST ON A.DEPT_ID = LOCLIST.DEPT_ID      
		WHERE A.fin_year = @cProfitFinYear

	END
	ELSE
	BEGIN
		SET @cStep='43' 
		EXEC SP3S_GETPROFITAMOUNT_TRIALBALANCE
		@bCalledFromBs=1,
		@cCompanyPanNo=@cCompanyPanNo,
		@nCbp=@nCbp,
		@dToDtPara=@dToDtPara

		SELECT TOP 1 @cErrormsg=isnull(errmsg,'')
		FROM #tProfit

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC
		
		SET @cStep='44' 
		SELECT @nFinalProfit=SUM(final_profit) ,@nProfitCf=sum(profit_carried_fwd) ,
		@nPlXferred=SUM(PlXferred) ,@nCalcProfit=SUM(calc_profit)
		FROM #tProfit


	END
	
	SET @cStep='45' 
	SELECT 	@nFinalProfit=ISNULL(@nFinalProfit,0),@nProfitCf=ISNULL(@nProfitCf,0),
			@nPlXferred=isnull(@nPlXferred,0),@nCalcProfit=isnull(@nCalcProfit,0)

	DECLARE @cPlheadName VARCHAR(200),@nProfitEntryMode INT
	SELECT TOP 1 @cPlheadName=head_name FROM hd01106 (NOLOCK) WHERE head_code='0000000009'
	SET @nProfitEntryMode=2 --(CASE WHEN @nMode=1 THEN 2 ELSE 1 END)

	SET @cStep='47' 	
	INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,entry_order)   
	 SELECT @cPlheadName as bshead_name,'P&L Brought Forward' as head_name,
	 (CASE WHEN @nMode=2 THEN @cPlheadName ELSE '' END)  as ac_name,    
	 (case when @nProfitCf>0 THEN ABS(@nProfitCf) else 0 end) CLOSING_DEBIT,
	 (case when @nProfitCf<0 THEN ABS(@nProfitCf) else 0 end) CLOSING_CREDIT,@nProfitEntryMode mode,1 entry_order

	INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,entry_order)   
	 SELECT @cPlheadName as bshead_name,'Calculated P&L' as head_name,
	 (CASE WHEN @nMode=2 THEN @cPlheadName ELSE '' END)  as ac_name,    
	 (case when @nCalcProfit>0 THEN ABS(@nCalcProfit) else 0 end) CLOSING_DEBIT,
	 (case when @nCalcProfit<0 THEN ABS(@nCalcProfit) else 0 end) CLOSING_CREDIT,@nProfitEntryMode mode,2 entry_order
	

	INSERT #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode,entry_order)   
	 SELECT @cPlheadName as bshead_name,'P&L Transferred' as head_name,
	 (CASE WHEN @nMode=2 THEN @cPlheadName ELSE '' END)  as ac_name,    
	 (case when @nPlXferred>0 THEN ABS(@nPlXferred) else 0 end) CLOSING_DEBIT,
	 (case when @nPlXferred<0 THEN ABS(@nPlXferred) else 0 end) CLOSING_CREDIT,@nProfitEntryMode mode,3 entry_order
	 
	IF @nMode=2	---- Do not insert Heads Total If View is Head Wise only
	BEGIN
		SET @cStep='50'
		insert #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)    
		select bshead_name,head_name,'Total : ' as Ac_name, SUM(DEBITAMOUNT) AS DEBITAMOUNT,SUM(CREDITAMOUNT) AS CREDITAMOUNT,2 as mode 
		FROM   #temp WHERE bshead_name NOT IN ('BS Totals',@cPlheadName)
		GROUP BY bshead_name,head_name  


		insert #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)  
		select bshead_name,'ZZZZZZZZZZ' as head_name,'Grand Total : ' as Ac_name, 
		SUM(DEBITAMOUNT) AS DEBITAMOUNT,  SUM(CREDITAMOUNT) AS CREDITAMOUNT   ,3 as mode 
		FROM   #temp 
		WHERE mode=2 AND bshead_name NOT IN ('BS Totals',@cPlheadName)
		GROUP BY bshead_name  
	END

	insert #temp (bshead_name,head_name,Ac_name,DebitAmount, CreditAmount,mode)  
	select 'BS Grand Totals' bshead_name,'ZZZZZZZZZZ' as head_name,'BS Grand Total : ' as Ac_name, 
	SUM(DEBITAMOUNT) AS DEBITAMOUNT,  SUM(CREDITAMOUNT) AS CREDITAMOUNT ,3 as mode 
	FROM   #temp 
	WHERE mode=2 and ac_name<>'Total : '

	--IF @@spid=1326
	--select 'check grand total',*	FROM   #temp 
	--WHERE mode=2 and ltrim(rtrim(ac_name))<>'Total:'


	SET @cStep='60'
	select ROW_NUMBER() OVER(PARTITION BY bshead_name,head_name 
	ORDER BY bshead_name ,head_name,mode,ac_name) AS SRNO,
	bshead_name AS bs_head_name,head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,mode,entry_order
	,bshead_name AS DISPLAY_bs_head_name,head_name AS DISPLAY_head_name,Ac_name AS DISPLAY_Ac_name
	INTO #temp_output
	from #temp   
	
	SET @cStep='65'
	--SELECT * FROM #temp_output
	UPDATE #temp_output SET DISPLAY_bs_head_name='',DISPLAY_head_name=''--,DISPLAY_Ac_name=CASE WHEN MODE>1 THEN '' ELSE DISPLAY_Ac_name END 
	WHERE srno >1 AND entry_order IS NULL

	UPDATE #temp_output SET DISPLAY_bs_head_name='',DISPLAY_head_name=''--,DISPLAY_Ac_name='' 
	WHERE mode >1 AND entry_order IS NULL

	UPDATE #temp_output SET DebitAmount= NULL WHERE DebitAmount=0

	UPDATE #temp_output SET CreditAmount= NULL WHERE CreditAmount=0
	
	SET @cStep='70'

	select *  from 
	(select b.srno,bs_head_name,head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,mode,DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_Ac_name
	from #temp_output  a
	JOIN (select distinct bshead_name,srno from #tmpheads
		  union all
		  select @cPlheadName bshead_name,7 srno) B ON B.bshead_name=A.bs_head_name
	UNION ALL
	select (CASE WHEN  bs_head_name not in('Grand Totals','BS Grand Totals') THEN 6.5 ELSE  9999 END) srno,
	bs_head_name,head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,mode,DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_Ac_name
	from #temp_output  a
	where bs_head_name in ('BS Totals','Grand Totals','BS Grand Totals')
	) a
	ORDER BY srno,bs_head_name,head_name,mode ,ac_name  


	SET @cStep='200'
	IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='BALANCESHEET_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
	  	DROP TABLE BALANCESHEET_CURSOR

	IF  OBJECT_ID('BALANCESHEET_CURSOR','U') IS NULL	
	BEGIN

		select CAST(0 AS NUMERIC(5)) srno,bs_head_name,head_name,Ac_name,DEBITAMOUNT,CREDITAMOUNT ,mode,DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_Ac_name
		INTO BALANCESHEET_CURSOR
		from #temp_output WHERE 1=2
	END

	END TRY     

	BEGIN CATCH    
		SET @cErrormsg='Error in Procedure SP3S_ACT_BALANCESHEET at Step#'+@cStep+':'+ERROR_MESSAGE()    
		goto end_proc    
	END CATCH    

end_proc:    
	IF ISNULL(@cErrormsg,'')<>''    
		select ISNULL(@cErrormsg,'') as DISPLAY_bs_head_name    
END