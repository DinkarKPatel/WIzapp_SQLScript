create PROCEDURE sp3s_getledger_ageing
@cAcCode CHAR(10),
@nMode NUMERIC(1,0)=1,
@dToDt DATETIME
as
begin
	DECLARE @cCreditorHeads VARCHAR(MAX),@cDebtorHeads VARCHAR(MAX),@bFlag BIT,@cHeadCode CHAR(10),
			@bDebtor BIT,@cRowId VARCHAR(50),@cAdjRowId VARCHAR(50),@nBillAmt NUMERIC(14,4),@dVchDt DATETIME, 
			@nAdjAmt NUMERIC(14,4),@nDeductAmt NUMERIC(14,4),@nRowNo NUMERIC(1,0),@cCmd NVARCHAR(MAX),
			@nAgeDays NUMERIC(5,0),@nAgeDaysPrev NUMERIC(5,0),@cAmtCol VARCHAR(50),@nMaxRowNo NUMERIC(5,0) 

	SELECT @cHeadCode=head_code FROM lm01106 (NOLOCK) WHERE ac_code=@cAccode

	SELECT @cCreditorHeads=dbo.fn_act_travtree('0000000021'),
		   @cDebtorHeads=dbo.fn_act_travtree('0000000018')
	
	
	IF CHARINDEX(@cHeadCode,@cCreditorHeads)=0 AND CHARINDEX(@cHeadCode,@cDebtorHeads)=0  	   	
		RETURN
	
	SET @bDebtor = (CASE when CHARINDEX(@cHeadCode,@cCreditorHeads)=0 then 1 ELSE 0 END)

	SELECT voucher_dt,credit_amount,debit_amount,vd_id,convert(numeric(5,0),0) as ageing_days
	into #tmpLedger FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	WHERE 1=2

	IF @nMode=1
		GOTO lblOnAccount
	ELSE
		GOTO lblBillbyBill
	
	
lblOnAccount:
	INSERT #tmpLedger (voucher_dt,credit_amount,debit_amount,vd_id,ageing_days)
	SELECT voucher_dt,sum(credit_amount) as credit_amount,sum(debit_amount) as debit_amount, convert(varchar,voucher_dt,112)  vd_id,
	convert(numeric(5,0),0) as ageing_days
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	WHERE voucher_dt<=@dToDt AND ac_code=@cAcCode AND cancelled=0
	group by voucher_dt

	SET @bFlag=0
	while @bFlag=0
	BEGIN
		SELECT @cRowId='',@cAdjRowId='',@nAdjAmt=0,@nDeductAmt=0,@nBillAmt=0

		IF @bDebtor=1
			SELECT TOP 1 @cRowId=vd_id,@nBillAmt=debit_amount,@dVchDt=VOUCHER_DT FROM #tmpLedger WHERE debit_amount<>0 ORDER BY voucher_dt
		ELSE
			SELECT TOP 1 @cRowId=vd_id,@nBillAmt=credit_amount,@dVchDt=VOUCHER_DT FROM #tmpLedger WHERE credit_amount<>0 ORDER BY voucher_dt
		
		IF	ISNULL(@cRowId,'')=''
			BREAK	
		
		IF @bDebtor=0
			SELECT TOP 1 @cAdjRowId=vd_id,@nAdjAmt=debit_amount FROM #tmpLedger WHERE debit_amount<>0 ORDER BY voucher_dt
		ELSE
			SELECT TOP 1 @cAdjRowId=vd_id,@nAdjAmt=credit_amount FROM #tmpLedger WHERE credit_amount<>0 ORDER BY voucher_dt
		
		IF	ISNULL(@cAdjRowId,'')=''
			BREAK		
		
		SET @nDeductAmt = (CASE WHEN @nBillAmt<@nAdjAmt THEN @nBillAmt ELSE @nAdjAmt END)

		IF @bDebtor=1
		BEGIN
			UPDATE #tmpLedger SET debit_amount=debit_amount-@nDeductAmt WHERE vd_id=@cRowId
			UPDATE #tmpLedger SET credit_amount=credit_amount-@nDeductAmt WHERE vd_id=@cAdjRowId
		END
		ELSE
		BEGIN
			UPDATE #tmpLedger SET credit_amount=credit_amount-@nDeductAmt WHERE vd_id=@cRowId
			UPDATE #tmpLedger SET debit_amount=debit_amount-@nDeductAmt WHERE vd_id=@cAdjRowId
		END
		
		PRINT 'Processing Data for  Row Id :'+@cRowId+' Voucher date:'+convert(varchar,@dVchDt,113)+' amount :'+str(@nBillAmt,10,2)+' Adj rowid:'+@cAdjRowid+' deduct amt:'+str(@nDeductamt,10,2)+' adj amt:'+str(@nAdjamt,10,2)
	END

	GOTO lblFinal

lblBillbyBill:
	EXEC SP3S_BILL_BY_BILL @NMODE=6,@CAC_CODE=@cAcCode,@DT_TODATE=@DTODT,@CLOCID='',@BSHOWMRRNO= 0,
	@NDUEBILLMODE=1,@cSpId=@@spid
	
	SET @cAmtCol=(CASE WHEN @bDebtor=1 THEN 'SUM(debit_amount-credit_amount) as debit_amount,0 as credit_amount'
				  ELSE '0 as debit_amount,SUM(credit_amount-debit_amount) as credit_amount' END)

	
	SET @cCmd=N'SELECT A.DUE_DATE,'+@cAmtCol+','''' as vd_id, 0 as AgeingDays 
				FROM ##TMPPENDINGBILLS A GROUP BY A.DUE_DATE '
	
	INSERT #tmpLedger (voucher_dt,debit_amount,credit_amount,vd_id,ageing_days)
	EXEC SP_EXECUTESQL @cCmd

	
lblFinal:
	
	UPDATE #tmpLedger set ageing_days=datediff(dd,voucher_dt,getdate())

	SELECT  AGEING_DAY,row_number() over (order by ageing_day) as rno  
	INTO #TMPAGEING FROM AGEINGDAYS_DRCR

	IF NOT EXISTS(SELECT TOP 1 'U' FROM #TMPAGEING)
	BEGIN
		INSERT INTO #TMPAGEING(AGEING_DAY,rno)
		SELECT 30 ,1
	END

	SELECT @nMaxRowNo=max(rno) from #TMPAGEING

	SET @cAmtCol=(CASE WHEN @bDebtor=1 THEN 'debit_amount' ELSE 'credit_amount' END)

	declare @nLoopCnt int=0
	SET @nRowNo=1
	if object_id('tempdb..#LEDGER_AGEING_CURSOR','u') is not null
	   drop table #LEDGER_AGEING_CURSOR

	SELECT sr=cast(1 as int), CAST('Total_Dues' AS VARCHAR(MAX)) AS TOTAL_DUE,CAST('' AS VARCHAR(MAX)) AS COL1,CAST('' AS VARCHAR(MAX)) AS COL2,
		CAST('' AS VARCHAR(MAX)) AS COL3, CAST('' AS VARCHAR(MAX)) AS COL4, CAST('' AS VARCHAR(MAX)) AS COL5,CAST('' AS VARCHAR(MAX)) AS COL6
		,CAST('' AS VARCHAR(MAX)) AS COL7
		INTO #LEDGER_AGEING_CURSOR 

	
	declare @cstr varchar(100),@dtsql nvarchar(max)
	
	SET @cCmd=''
	WHILE (@nRowNo<=(@nmaxRowNo+1))
	BEGIN
		set @nLoopCnt=@nLoopCnt+1
		
		SELECT TOP 1 @nAgeDays=ageing_day FROM #TMPAGEING where rno=@nRowNo
		set @cstr=''
		print 'process rowno.:'+str(@nRowno)
		IF @nRowNo=1
		begin
		    set @cstr='[Dues less than '+ltrim(rtrim(str(@nAgedays)))+' Days]'
			SET @cCmd=N'CAST(SUM(CASE WHEN ageing_days<'+str(@nAgeDays)+' THEN b.'+@cAmtCol+' ELSE 0 END) AS VARCHAR(1000)) as COL'+ltrim(rtrim(str(@nRowno)))-- [Dues less than '+ltrim(rtrim(str(@nAgedays)))+' Days]

		end
		ELSE
		BEGIN
			IF @nRowNo>@nMaxRowNo
			begin
			    set @cstr='[Dues more than '+ltrim(rtrim(str(@nAgedays)))+' Days]'
				SET @cCmd=@cCmd+N',SUM(CASE WHEN ageing_days>'+ltrim(rtrim(str(@nAgeDays)))+' THEN b.'+@cAmtCol+' ELSE 0 END) as COL'+ltrim(rtrim(str(@nRowno)))--[Dues more than '+ltrim(rtrim(str(@nAgedays)))+' Days]'

			end
			ELSE
			begin
			     SET @CSTR='[FROM '+LTRIM(RTRIM(STR(@NAGEDAYSPREV)))+' TO '+LTRIM(RTRIM(STR(@NAGEDAYS)))+' DAYS]'
				SET @cCmd=@cCmd+N',SUM(CASE WHEN ageing_days between '+ltrim(rtrim(str(@nAgeDaysPrev)))+' AND '+ltrim(rtrim(str(@nAgeDays)))+
							 ' THEN b.'+@cAmtCol+' ELSE 0 END) as COL'+ltrim(rtrim(str(@nRowno)))--[From '+ltrim(rtrim(str(@nAgedaysPrev)))+' To '+ltrim(rtrim(str(@nAgedays)))+' Days]'

			end
		END

		set @dtsql=' update #LEDGER_AGEING_CURSOR set col'+ltrim(rtrim(str(@nRowNo)))+'='''+@CSTR+''' where sr=1'
		print @dtsql
		exec sp_executesql @dtsql
		
		SET @nAgeDaysPrev=@nAgeDays+1
		SET @nRowNo=@nRowNo+1
	END

	 WHILE (@nRowNo<=7)
	 BEGIN
	     SET @cCmd=@cCmd+(CASE WHEN @cCmd<>'' then ',' else '' end)+''''' AS COL'+ltrim(rtrim(str(@nRowno)))
	     SET @nRowNo=@nRowNo+1
	 END




	--select @nLoopCnt as loop_cnt,@nMaxrowno as maxrowno, * from #tmpLedger

	--select @cCmd
	SET @cCmd=N'SELECT sr=2, SUM('+@cAmtCol+') as total_due,'+@cCmd+' FROM #tmpLedger b WHERE '+@cAmtCol+'<>0'
	PRINT @cCmd
	insert into #LEDGER_AGEING_CURSOR
	EXEC SP_EXECUTESQL @cCmd

	
	
	select TOTAL_DUE,COL1 ,COL2 ,COL3,COL4,COL5 ,COL6,COL7 from  #LEDGER_AGEING_CURSOR
	order by sr 
	
	IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='LEDGER_AGEING_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
  		DROP TABLE LEDGER_AGEING_CURSOR

	IF  OBJECT_ID('LEDGER_AGEING_CURSOR','U') IS NULL	
	BEGIN
		SELECT CAST('' AS VARCHAR(MAX)) AS TOTAL_DUE,CAST('' AS VARCHAR(MAX)) AS COL1,CAST('' AS VARCHAR(MAX)) AS COL2,
		CAST('' AS VARCHAR(MAX)) AS COL3, CAST('' AS VARCHAR(MAX)) AS COL4, CAST('' AS VARCHAR(MAX)) AS COL5,CAST('' AS VARCHAR(MAX)) AS COL6
		,CAST('' AS VARCHAR(MAX)) AS COL7
		INTO LEDGER_AGEING_CURSOR 
		WHERE 1=2
	END
	
end