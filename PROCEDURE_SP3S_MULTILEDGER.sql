CREATE PROCEDURE SP3S_MULTILEDGER--(LocId 3 digit change by Sanjay:26-11-2024 left changes by concerned developer)
(
	@dFromDt DATETIME='',      
	@dToDt DATETIME='',    
	@cAcCodePara CHAR(10)='',    
	@nMode NUMERIC(1,0)=1,    
	@nMonthNo NUMERIC(2,0)=0,    
	@nSpId VARCHAR(50)='',    
	@nViewType NUMERIC(1,0)=1,
	@bRetAgeingDetails BIT=0 ,   
	@bCalInterrest BIT=0 ,   
	@bInterestPercent NUMERIC(5,2)=0,
	@nSorViewType INT=1 ,--- 1. Full Ledger 2.Commission Ledger
	@cCompanyPanNo VARCHAR(20)='',
	@bAllVsAc BIT=1,
	@nPeriodType INT=1
)
AS      
BEGIN      
 --DECLARE @dFromDt DATETIME='2019-03-01'  ,@dToDt DATETIME  ='2019-09-26'    
BEGIN TRY      
--         select @nMode
  DECLARE @cStep VARCHAR(4),@cErrormsg varchar(max),@dOpnDt DATETIME,    
   @cViewLedgerForCancelledVouchers VARCHAR(20),@cMultiHdTable VARCHAR(200),    
   @cDebtorHEads VARCHAR(MAX),@cDebtorHEads1 VARCHAR(MAX),@cCmd NVARCHAR(MAX),@cLmCol VARCHAR(100),
   @cFinyear VARCHAR(5),@dFinyearFromDt DATETIME    

   if @cCompanyPanNo<>''
   begin
        
		insert into ACT_FILTER_LOC(dept_id,sp_id)
		select a.dept_id,@nSpId sp_id from location a (nolock)
		join loc_accounting_company b on a.PAN_NO=b.pan_no
		where a.pan_no=@cCompanyPanNo

   end
    
  SELECT TOP 1 @cViewLedgerForCancelledVouchers=value FROM config WHERE config_option='LEDGER_OPENING_CUTOFF_DATE'    
     
  SET @cViewLedgerForCancelledVouchers=ISNULL(@cViewLedgerForCancelledVouchers,'')    
      
  IF @cViewLedgerForCancelledVouchers<>''    
  BEGIN    
	   SELECT @cDebtorHEads=dbo.FN_ACT_TRAVTREE('0000000018')     
       
	   IF NOT EXISTS (SELECT ac_code FROM LM01106 (NOLOCK) WHERE AC_CODE=@cAcCodePara AND CHARINDEX(HEAD_CODE,@cDebtorHEads)>0)    
	   SET @cViewLedgerForCancelledVouchers=''    
  END       
      
  declare @CDONOTPICKOBHEADS VARCHAR(2000)
      
  CREATE TABLE #locListC (dept_id VARCHAR(4))    
    
  SET @cStep='2'      
    
  --IF @nMode=0    
  --SET @cAcCodePara=''    
    
 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
 ELSE    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)    

	--SELECT * FROM #locListC
  
  SET @cStep='2.5'

  SELECT head_code INTO #tmpHd FROM hd01106 (NOLOCK) WHERE 1=2

  IF @nMode=0 
  BEGIN
		SET @cStep='2.8'
		IF @cAcCodePara<>''
			INSERT INTO #tmpHd
			select @cAcCodePara
		ELSE
		BEGIN
			SET @cStep='4'
			SET @cMultiHdTable='tempDB..#temp_multi_ledger_'+LTRIM(RTRIM(@nSpId))

			SET @cCmd=N'SELECT DISTINCT a.head_code FROM hd01106 a (NOLOCK) '+(CASE WHEN OBJECT_ID(@cMultiHdTable,'u') IS NOT NULL
			THEN 'JOIN '+@cMultiHdTable+' b ON a.head_code=b.ac_code '
			ELSE '' END)

			INSERT INTO #tmpHd
			EXEC SP_EXECUTESQL @cCmd
		
		END
  END

  CREATE TABLE #vmDates (vm_id VARCHAR(50),voucher_dt DATETIME)
  
	
  SET @cStep='5'      
  SELECT DISTINCT a.ac_code AS rep_ac_code INTO #tempLm 
  FROM lm01106 a (NOLOCK)     
  LEFT OUTER JOIN lm_broker_details b (NOLOCK) ON b.ac_code=a.ac_code
  LEFT JOIN #tmpHd hd ON hd.head_code=a.head_code
  WHERE (@nMode IN (1,2,3) AND (a.ac_code=@cAcCodePara OR major_ac_code=@cAcCodePara)) 
	OR  (@nMode=0  AND hd.head_CODE IS NOT NULL)
    OR  (@nMode=4  AND broker_ac_code=@cAcCodePara)


  IF @nPeriodType=1
	  INSERT INTO #vmDates (vm_id,voucher_dt)
	  SELECT distinct a.vm_id,a.voucher_dt from vm01106 a (NOLOCK) JOIN vd01106 b (NOLOCK) ON a.vm_id=b.vm_id
	  JOIN #tempLm lm ON lm.rep_ac_code=b.AC_CODE
  ELSE
	  INSERT INTO #vmDates (vm_id,voucher_dt)
	  SELECT distinct a.vm_id,(CASE WHEN ISNULL(a.posted_vendor_bill_dt,'')<>'' THEN a.posted_vendor_bill_dt ELSE a.voucher_dt end) from vm01106 a (NOLOCK) JOIN vd01106 b (NOLOCK) ON a.vm_id=b.vm_id
	  JOIN #tempLm lm ON lm.rep_ac_code=b.AC_CODE

  SET @cFinyear='01'+dbo.fn_getfinyear(@dTodt)
  SELECT @dFinyearFromDt = DBO.FN_GETFINYEARDATE(@cFinyear,1)
  
  SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
  SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
  SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    
	
  SET @cStep='5.2'      	
  SELECT head_code INTO #tempDNObHd FROM hd01106 WHERE CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0    
  
 -- if @@spid=981
 -- begin
	--select * from #tempDNObHd order by head_code
	--SELECT head_code,* from #templm a join lm01106 b on a.rep_ac_code=b.ac_code
 -- end
 
  IF EXISTS (SELECT TOP 1 * from #templm a join lm01106 b on a.rep_ac_code=b.ac_code
			 JOIN #tempDNObHd DNHD on dnhd.head_code=b.head_code  
		     ) AND @dFinyearFromDt>@dFromDt
  BEGIN
	 SET @cErrormsg = 'Revenue accounts cannnot be Viewed across Financial year Dates'
	 GOTO END_PROC
  END     

  IF @cAcCodePara<>''
  BEGIN
		SET @cStep='5.4'      
		DECLARE @cChildAcCode CHAR(10)
		SELECT TOP 1 @cChildAcCode=ac_code FROM lm01106 (NOLOCK) WHERE major_ac_code=@cAcCodePara AND ac_code<>@cAcCodePara

		IF ISNULL(@cChildAcCode,'')=''
			SET @nViewType=3

  END

  SET @cStep='5.6'
  SELECT vd_id INTO #tmpSorEntries from vd01106 (NOLOCK) WHERE 1=2

  IF @nSorViewType=2 
  BEGIN
	 SET @cStep='5.64'
	 INSERT INTO #tmpSorEntries (vd_id)
	 SELECT distinct a.vd_id FROM bill_by_bill_ref a (NOLOCK) 
	 JOIN vd01106 b (NOLOCK) ON a.vd_id=b.vd_id
	 join #templm c ON c.rep_ac_code=b.ac_code
	 WHERE ISNULL(a.on_account,0)=0
  END

  SET @cStep='5.84'
  SELECT (CASE WHEN @nViewType=1 THEN lm.major_ac_code ELSE  lm.ac_code END) AC_CODE,sum(debit_amount-credit_amount) as balance,
  sum(debit_amount_forex-credit_amount_forex) as balance_forex,
  (CASE WHEN b.voucher_code in ('0000000009','MEMO000001','MEMO000002') THEN 'MemoZZ2' else 'ZZ2'  end) vouchercode into #tmpcb from vd01106 a (NOLOCK)
  JOIN vm01106 b (NOLOCK) on b.vm_id=a.vm_id 
  join #templm c ON c.rep_ac_code=a.ac_code
  join lm01106 lm (nolock) on lm.ac_code=a.ac_code
  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id  
  JOIN #vmDates vmdt ON vmdt.vm_id=b.vm_id
  left outer join #tempDNObHd d on d.head_code=lm.head_code
  left join #tmpSorEntries SOR on SOR.VD_ID=a.vd_id
  where  vmdt.voucher_dt<=@dToDt AND (d.head_code is null or vmdt.voucher_dt>=@dFinyearFromDt) AND
  ((vmdt.voucher_dt>@cViewLedgerForCancelledVouchers AND cancelled=0)    
    OR (@cViewLedgerForCancelledVouchers<>'' AND ISNULL(consider_for_ledger_view,0)=1     
     AND vmdt.voucher_dt<=@cViewLedgerForCancelledVouchers))  
	 AND (@nSorViewType<>2 OR sor.VD_ID IS NOT NULL)
  group by (CASE WHEN @nViewType=1 THEN lm.major_ac_code ELSE  lm.ac_code END),(CASE WHEN b.voucher_code in ('0000000009','MEMO000001',
  'MEMO000002') THEN 'MemoZZ2' else 'ZZ2'  end)
	      
  SET @cStep='7'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      

  
  
  SET @cStep='10'      
      
  SET @cLmCol=(CASE WHEN @nViewType=1 THEN 'major_ac_code' ELSE 'ac_code' END)    
    
  CREATE TABLE #tmpOb (voucherdate DATETIME,accode CHAR(10),
  debitamount NUMERIC(20,2),creditamount NUMERIC(20,2),debitamount_forex NUMERIC(20,2),creditamount_forex NUMERIC(20,2),
  vouchercode VARCHAR(20))    
      
  IF NOT (@nMode=3 AND @nMonthNo<>4)    
  BEGIN    
	   SET @cCmd=N'select '''+CONVERT(VARCHAR,@dFromDt,110)+''' as voucherdate,    
	   lm.'+@cLmCol+' as accode,      
	   case when sum(debit_amount-credit_amount)>=0 then sum(DEBIT_AMOUNT - CREDIT_AMOUNT) else 0 end as DebitAmount,
	   case when sum(debit_amount_forex-credit_amount_forex)>=0 then sum(debit_amount_forex - credit_amount_forex) else 0 end as DebitAmount_forex,
	   case when sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount,
	   case when sum(debit_amount_forex-credit_amount_forex)<0 then abs(sum(debit_amount_forex-credit_amount_forex)) else 0 end as CreditAmount_forex,
		(CASE WHEN voucher_code in (''0000000009'',''MEMO000001'',
	  ''MEMO000002'') THEN ''MemoZZ1'' else ''ZZ1'' end) as vouchercode
	   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
	   join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
	   JOIN #tempLm lr ON '+(CASE WHEN @nViewType IN (1,3) THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code    
	   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
	   JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
	   LEFT OUTER JOIN #tempDNObHd DNHD on dnhd.head_code=lm.head_code    
	     left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
	   where vmdt.voucher_dt < '''+CONVERT(VARCHAR,@dFromDt,110)+'''     
	   AND (dnhd.head_code IS NULL OR vmdt.voucher_dt>='''+convert(varchar,@dFinyearFromDt,110)+''')    
	   AND ((vmdt.voucher_dt>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)    
		OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
		 AND vmdt.voucher_dt<='''+@cViewLedgerForCancelledVouchers+'''))    
	   AND ('+ltrim(rtrim(str(@nSorViewType)))+'<>2 OR sor.VD_ID IS NOT NULL)          
	   group by lm.'+@cLmCol+',(CASE WHEN voucher_code in (''0000000009'',''MEMO000001'',
	  ''MEMO000002'') THEN ''MemoZZ1'' else ''ZZ1'' end)'    
       
	   PRINT @cCmd    
	   INSERT #tmpOb (voucherdate,accode,DebitAmount,DebitAmount_forex,CreditAmount,CreditAmount_forex,vouchercode)    
	   EXEC SP_EXECUTESQL @cCmd    
       
 END     
    
 IF @nMode IN (0,1,4)    
	 GOTO lblDetailed    
 ELSE    
 IF @nMode=2    
	GOTO lblMonthly    
 ELSE    
 IF @nMode=3    
	GOTO lblDaily    
    
lblDetailed:    
    
  SET @cStep='12'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
  create table #temp (cost_center_dept_id varchar(4),vm_id VARCHAR(50), 
  AcCode varchar(20),head_code CHAR(10), 
  voucher_no varchar(400),ref_no varchar(500), VoucherDate datetime, 
  OrderDate datetime, VoucherType varchar(150),       
  Narration varchar(max), DebitAmount numeric(20, 2), CreditAmount numeric(20, 2),DebitAmount_forex numeric(20, 2),
  CreditAmount_forex numeric(20, 2),RunningTotal NUMERIC(20,2),RunningTotal_forex NUMERIC(20,2),UnqId int identity PRIMARY KEY,vd_id VARCHAR(150),
  vouchercode varchar(150),vs_ac_name varchar(max),vs_ac_name_forex varchar(max),x_type varchar(5))       
  --ALTER TABLE #temp ADD CONSTRAINT PK PRIMARY KEY(UnqId)    
 
      

  SET @cCmd=N'select a.'+@cLmCol+' AcCode, '''' head_code,'''+convert(varchar,@dFromDt,110)+'''
  VoucherDate, '''+convert(varchar,@dFromDt-1,110)+''' OrderDate, '''' VoucherType,
  ''Opening Balance'' as Narration, 0 as DebitAmount,0  as CreditAmount,0 as DebitAmount_forex,0  as CreditAmount_forex,''ZZ1'' AS vouchercode FROM  #tempLm lr    
  JOIN lm01106 a ON a.'+@cLmCol+'=lr.rep_ac_code
  GROUP BY a.'+@cLmCol

  print @cCmd
  insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex,vouchercode)      
  exec sp_executesql @cCmd 
  
  
  SET @cStep='12.6'      
  set @cCmd=N'select  A.'+@cLmCol+' AcCode,'''' head_code, '''+convert(varchar,@dFromDt,110)+''' VoucherDate,
  '''+convert(varchar,@dFromDt-1,110)+''' OrderDate, '''' VoucherType, 
  ''Opening Balance'' as Narration,       
	0 as DebitAmount,0  as CreditAmount,''MEMOZZ1'' as vouchercode FROM lm01106 a    
	JOIN #tempLm lr ON a.'+@cLmCol+'=lr.rep_ac_code
  GROUP BY a.'+@cLmCol

  print @cCmd

  insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vouchercode)      
  exec sp_executesql @cCmd  
  		         
  SET @cStep='15.6'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
         
  SET @cCmd=N'Select cost_center_dept_id,vd.vm_id, lm.'+@cLmCol+' AcCode,head_code, vm.voucher_no, vm.ref_no, vmdt.voucher_dt VoucherDate, 
   vmdt.voucher_dt OrderDate, vch.VOUCHER_TYPE_ALIAS VoucherType, vd.Narration, debit_amount, credit_amount  ,debit_amount_forex, credit_amount_forex  ,
   vd.vd_id, (CASE WHEN vch.voucher_code in (''0000000009'',''MEMO000001'', ''MEMO000002'') THEN ''MemoZZ1'' else ''ZZ1'' end) as vouchercode,
   x_type  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
   join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
   JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
   JOIN #tempLm lr ON '+(CASE WHEN @nViewType in  (1,3) THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code    
   where vmdt.voucher_dt between '''+CONVERT(VARCHAR,@dFromDt,110)+''' and '''+CONVERT(VARCHAR,@dToDt,110)+'''      
    
   AND ((vmdt.voucher_dt>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)    
    OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
     AND vmdt.voucher_dt<='''+@cViewLedgerForCancelledVouchers+'''))            
   AND ('+ltrim(rtrim(str(@nSorViewType)))+'<>2 OR sor.VD_ID IS NOT NULL)          
   ORDER BY cost_center_dept_id,vmdt.voucher_dt,voucher_no'      
    
   PRINT @cCmd    
    
   insert #temp (cost_center_dept_id,vm_id ,AcCode,head_code, Voucher_no,ref_no,VoucherDate, OrderDate, VoucherType, Narration,
   DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex,vd_id,vouchercode,x_type)      
   EXEC SP_EXECUTESQL @cCmd     
      
  SET @cStep='17'      
  SET @cCmd=N'select lm.'+@cLmCol+' AcCode,head_code, '''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate,     
   '''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate,''ZZ1'' as vouchertype     ,
  ''Sub Total'' as Narration,       
   sum(DEBIT_AMOUNT) DebitAmount,      
   sum(debit_amount_forex) DebitAmount_forex,      
   sum(CREDIT_AMOUNT) as CreditAmount,sum(credit_amount_forex) as CreditAmount_forex, (CASE WHEN vm.voucher_code in (''0000000009'',''MEMO000001'',
  ''MEMO000002'') THEN ''MemoZZ1'' else ''ZZ1'' end) as vouchercode      
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
   join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
   JOIN #tempLm lr ON '+(CASE WHEN @nViewType in (1,3) THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code    
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
   left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
   JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
   where vmdt.voucher_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+CONVERT(VARCHAR,@dToDt,110)+'''    
   AND ((vmdt.voucher_dt>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)    
    OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
     AND vmdt.voucher_dt<='''+@cViewLedgerForCancelledVouchers+'''))            
   AND ('+ltrim(rtrim(str(@nSorViewType)))+'<>2 OR sor.VD_ID IS NOT NULL)
   group by lm.'+@cLmCol+',head_code,(CASE WHEN vm.voucher_code in (''0000000009'',''MEMO000001'',
  ''MEMO000002'') THEN ''MemoZZ1'' else ''ZZ1'' end)'      
         
  --print @cCmd    
--    EXEC SP_EXECUTESQL @cCmd    

  PRINT @cCmd    
  insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount,DebitAmount_forex, CreditAmount, CreditAmount_forex,VoucherCode)      
  EXEC SP_EXECUTESQL @cCmd    
      
  SET @cStep='19'      
  UPDATE a SET debitamount=b.debitamount,creditamount=b.creditamount,
  head_code=c.head_code --,RunningTotal=b.DebitAmount-b.CreditAmount      
  FROM #temp a     
  JOIN #tmpOb b ON a.accode=b.accode and a.vouchercode=b.vouchercode       
  JOIN lm01106 c ON c.ac_code=a.accode
  WHERE  Narration='Opening Balance' AND a.vm_id IS NULL     
      
  SET @cStep='21'      
      
  SET @cCmd=N'select lm.'+@cLmCol+' AcCode,'''' head_code, '''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate,'''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate, 
   ''ZZ2'' as VoucherType, ''Closing Balance'' as Narration,       
   case when sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end  as DebitAmount,      
   case when sum(debit_amount_forex-credit_amount_forex)<0 then abs(sum(debit_amount_forex - credit_amount_forex)) else 0 end  as DebitAmount_foroex,      
   case when  sum(debit_amount-credit_amount)>=0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount,
   case when  sum(debit_amount_forex-credit_amount_forex)>=0 then abs(sum(debit_amount_forex - credit_amount_forex)) else 0 end as CreditAmount_foroex,
   (CASE WHEN vm.voucher_code in (''0000000009'',''MEMO000001'',
  ''MEMO000002'') THEN ''MemoZZ2'' else ''ZZ2''  end) as VoucherCode
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
   join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
   JOIN #tempLm lr ON lm.ac_code=lr.rep_ac_code    
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   left outer join #tempDNObHd d on d.head_code=lm.head_code
   left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
   JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
   where  vmdt.voucher_dt<='''+CONVERT(VARCHAR,@dToDt,110)+''' AND 
   (d.head_code is null or vmdt.voucher_dt>='''+CONVERT(VARCHAR,@dFinyearFromDt,110)+''') 
    AND ((vmdt.voucher_dt>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)    
    OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1     
     AND vmdt.voucher_dt<='''+@cViewLedgerForCancelledVouchers+'''))    
    AND ('+ltrim(rtrim(str(@nSorViewType)))+'<>2 OR sor.VD_ID IS NOT NULL)                 
   group by lm.'+@cLmCol+',(CASE WHEN vm.voucher_code in (''0000000009'',''MEMO000001'',
  ''MEMO000002'') THEN ''MemoZZ2'' else ''ZZ2''  end)'      
   
   print @cCmd    
   insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount,DebitAmount_forex, CreditAmount,CreditAmount_forex,vouchercode)      
   EXEC SP_EXECUTESQL @cCmd    
    
  SET @cStep='24'      
    
  insert #temp (AcCode,head_code, VoucherDate,OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex,vouchercode)    
  SELECT a.AcCode,a.head_code,@dToDt as VoucherDate,a.OrderDate,a.VoucherType,'Closing Balance' AS Narration,    
  a.creditamount as DebitAmount,a.debitamount as CreditAmount,DebitAmount_forex, CreditAmount_forex ,replace(a.vouchercode,'zz1','zz2')   
  FROM #temp a LEFT OUTER JOIN     
  (SELECT accode,vouchercode FROM #temp WHERE narration='Closing Balance' ) b ON a.accode=b.accode  
  and  replace(a.vouchercode,'zz1','zz2')= b.vouchercode  
  WHERE a.narration='Closing Balance' AND  b.accode IS NULL    
  
  SET @cStep='24.5' 
  update a set head_code=b.head_code from #temp a 
  JOIN  lm01106 b ON a.AcCode=b.ac_code
  WHERE narration='Closing Balance'
      
  SET @cStep='27'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)       
  CREATE INDEX ind_accode ON #temp (ACCODE)      
       
  SET @cStep='30'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
       
      
  SET @cStep='35'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
  
  --select 'check tempDNObHd   ',* from #tempDNObHd
  --select @CDONOTPICKOBHEADS,@cFinYear,'check loclist',* from #locListC    
  --select 'check tmplm',* from #tempLm    
  --select 'check ob',* from #tmpOb
  
  --delete a from #temp a LEFT OUTER JOIN #temp b ON a.AcCode=b.AcCode AND B.Narration='Closing Balance'      
  --LEFT OUTER JOIN #tmpOb c ON c.accode=a.AcCode    
  --WHERE b.AcCode IS NULL  AND (c.accode IS NULL OR (c.CreditAmount+c.DebitAmount)=0)    
      
  SET @cStep='37'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
    
 --ALTER TABLE #temp ADD RunningTotal NUMERIC(14,2)    
     
      
  SET @cStep='40'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)         
  
         
  SELECT a.* into #temp1 FROM #temp a    
  JOIN     
  (SELECT distinct accode FROM #temp (NOLOCK) WHERE (debitamount+creditamount)<>0     
  ) b on a.accode=b.accode     
      
    
 CREATE  CLUSTERED INDEX IX_1  ON #temp1 (accode,voucherdate,UnqId)    
    
  DECLARe @NSUMVALUE NUMERIC(20,2),@cAcCode CHAR(10) ,@cVMID VARCHAR(50)    
       
  SELECT DISTINCT accode,vouchercode INTO #tmpSUm FROM #temp1      
  
 SET @cStep='41'      
  
  DECLARE @cVchcode varchar(100)
  	      
  WHILE EXISTS (SELECT TOP 1 * from #tmpsum)      
  BEGIN       
	  SELECT TOP 1 @cAcCode=accode,@cVchCode=vouchercode FROM #tmpsum      
	  
	  SET @cStep='41.2'      	    
	  SET @NSUMVALUE=0     
      
	  ;WITH A    
	  AS    
	  (    
	   SELECT TOP 100 PERCENT *     
	   FROM #temp1    
	   WHERE AcCode=@cAcCode and vouchercode=@cVchCode    
	   ORDER BY accode,voucherdate,UnqId    
	  )    
	  
		 UPDATE A SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),      
		 @NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DebitAmount,0)-ISNULL(CreditAmount  ,0)    
		 WHERE AcCode=@cAcCode and vouchercode=@cVchCode  --AND narration    
	
	 SET @NSUMVALUE=0
	  ;WITH A    
	  AS    
	  (    
	   SELECT TOP 100 PERCENT *     
	   FROM #temp1    
	   WHERE AcCode=@cAcCode and vouchercode=@cVchCode    
	   ORDER BY accode,voucherdate,UnqId    
	  )    

		 UPDATE A SET RunningTotal_forex=ISNULL(RunningTotal_forex,0)+ISNULL(@NSUMVALUE,0),      
		 @NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DebitAmount_forex,0)-ISNULL(CreditAmount_forex  ,0)    
		 WHERE AcCode=@cAcCode and vouchercode=@cVchCode  --AND narration    
  
	  --UPDATE a SET DebitAmount=a.DebitAmount+b.DebitAmount,a.CreditAmount=a.CreditAmount+b.CreditAmount     
	  --FROM #temp1  a
	  --JOIN #tmpOb B on a.AcCode=b.accode
	  --WHERE a.VoucherType='ZZ1' AND a.AcCode=@cAcCode and a.vouchercode=@cVchcode  
	  
	  SET @cStep='41.4'            
	  UPDATE a SET DebitAmount=b.DebitAmount,a.CreditAmount=b.CreditAmount,
	  DebitAmount_forex=b.DebitAmount_forex,a.CreditAmount_forex=b.CreditAmount_forex
	  FROM #temp1  a    
	  JOIN    
	  (    
	   SELECT AcCode,vouchercode,SUM(DEBITAMOUNT) AS DEBITAMOUNT ,SUM(CREDITAMOUNT) AS CREDITAMOUNT
	   ,SUM(DEBITAMOUNT_forex) AS DEBITAMOUNT_forex ,SUM(CREDITAMOUNT_forex) AS CREDITAMOUNT_forex
	   from #temp1     
	   WHERE VoucherType NOT IN ('ZZ1','ZZ2') AND AcCode=@cAcCode and vouchercode=@cVchcode    
	   GROUP BY AcCode,vouchercode
	  )b ON b.AcCode=a.AcCode  and a.vouchercode=b.vouchercode   
	  WHERE a.VoucherType='ZZ1' AND a.AcCode=@cAcCode and a.vouchercode=@cVchcode   
      
	  SET @cStep='41.6'      
	 print 'Update rows of closing :'+@cvchcode
	  UPDATE a SET DebitAmount=ABS(case when b.amount<0 then b.amount else 0 end) ,      
	  CreditAmount  =ABS(case when b.amount>0 then b.amount else 0 end),
	  DebitAmount_forex=ABS(case when b.amount_forex<0 then b.amount_forex else 0 end) ,      
	  CreditAmount_forex  =ABS(case when b.amount_forex>0 then b.amount_forex else 0 end)	  
	  FROM #temp1  a    
	  JOIN    
	  (    
	   SELECT AcCode,vouchercode,isnull(DEBITAMOUNT,0)-isnull(cREDITAMOUNT,0) AS AMOUNT     
	   ,isnull(DEBITAMOUNT_forex,0)-isnull(cREDITAMOUNT_forex,0) AS AMOUNT_forex
	   from #temp1     
	   WHERE VoucherType IN ('ZZ1') AND AcCode=@cAcCode and vouchercode=@cVchcode   
	  )b ON b.AcCode=a.AcCode 
	  WHERE a.VoucherType='ZZ2' AND a.AcCode=@cAcCode AND a.vouchercode=replace(@cvchCode,'zz1','zz2')
    
	 print 'finished Update rows of closing :'+@cvchcode

	   DELETE FROM #tmpsum WHERE AcCode=@cAcCode and vouchercode=@cVchCode     
  END
  
  SET @cStep='41.8'      
  print 'delete unwanted opening balance entries'
  DELETE A from #temp1 a  
  left outer join 
  (select accode from #temp1 where vouchercode='memozz1' and (isnull(DebitAmount,0)<>0 or isnull(creditamount,0)<>0)
    group by accode) b on a.AcCode=b.AcCode
  where a.vouchercode='memozz1' and b.accode is null and (isnull(a.debitamount,0)+isnull(a.creditamount,0))=0
  
  SET @cStep='42.2'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
     
       
       
      
  SET @cStep='42.5'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
       
  select cost_center_dept_id,vm_id,ac_name,b.head_code as major_head_code,b.head_code,head_name,head_name AS bs_head_name, AcCode,    
  VoucherDate, OrderDate, Vouchertype, Narration, DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex, UnqId,      
  case when runningtotal >= 0 then convert(varchar, RunningTotal)+' Dr' else convert(varchar, abs(RunningTotal))+' Cr' end runningTotal
  ,case when ISNULL(runningtotal_forex,0) >= 0 then convert(varchar, RunningTotal_forex)+' Dr' else convert(varchar, abs(RunningTotal_forex))+' Cr' end runningTotal_forex
  ,ac_name AS DISPLAY_ac_name,head_name AS DISPLAY_head_name,head_name AS DISPLAY_bs_head_name,    
  CONVERT(VARCHAR(20) ,VoucherDate,106) AS   DISPLAY_VoucherDate,CONVERT(BIT,0) AS group_ledger,
  case when ISNULL(DebitAmount,0) > 0 then 'Dr' when ISNULL(CreditAmount,0) > 0 THEN 'Cr' else '' end XN_TYPE,
  vouchercode,accode as ac_code,vs_ac_name,vs_ac_name_forex,voucher_no,ref_no       
  into #temp2      
  from #temp1 a      
  JOIN LM01106 b (NOLOCK) ON a.AcCode=b.AC_CODE      
  JOIN HD01106 c (NOLOCK) ON c.head_code=b.head_code      
  order by UnqId      
  

  
  --FOR vs_ac_name ---
     

	DECLARE @VM_ID VARCHAR(1000), @VSACNAMES VARCHAR(MAX),@VSACNAMESForex VARCHAR(MAX);

    DECLARE @t TABLE(UnqId VARCHAR(50), AC_NAME VARCHAR(500), VSACNAMES VARCHAR(MAX),AC_NAME_forex VARCHAR(500), VSACNAMES_forex VARCHAR(MAX),
	                 Amount numeric(14,2));
 
  SET @cStep='42.8'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     

	 INSERT @t(UnqId, AC_NAME,AC_NAME_forex,Amount)
	 SELECT   A.UnqId,AC_NAME=  lm.AC_NAME+' ['+CAST(CONVERT(NUMERIC(14,2),sum(ISNULL(B.DEBIT_AMOUNT,0)+ISNULL(B.CREDIT_AMOUNT,0))) AS VARCHAR(50)) +B.X_TYPE+']',
	 AC_NAME_forex=  lm.AC_NAME+' ['+CAST(CONVERT(NUMERIC(14,2),sum(ISNULL(B.DEBIT_AMOUNT_forex,0)+ISNULL(B.CREDIT_AMOUNT_forex,0))) AS VARCHAR(50)) +B.X_TYPE+']',
	 Amount=CONVERT(NUMERIC(14,2),sum(ISNULL(B.DEBIT_AMOUNT,0)+ISNULL(B.CREDIT_AMOUNT,0)))
	 FROM #temp1 A
	 JOIN VD01106 B (nolock) ON A.VM_ID=B.VM_ID 
	 JOIN LM01106 LM (NOLOCK) ON B.AC_CODE=LM.AC_CODE  
	 WHERE a.vd_id <>b.vd_id 
	 group by  A.UnqId,lm.AC_NAME,B.X_TYPE
	



    if @bAllVsAc=1
	begin

	UPDATE @t SET @VSACNAMES = VSACNAMES = COALESCE(
		  CASE COALESCE(@VM_ID, N'') 
		  WHEN UnqId THEN  @VSACNAMES+CHAR(13)+CHAR(10) + N''+ AC_NAME --+CHAR(13)+CHAR(10)
		  ELSE AC_NAME  END , N'') , 
		  @VSACNAMESForex = VSACNAMES_Forex = COALESCE(
		  CASE COALESCE(@VM_ID, N'') 
		  WHEN UnqId THEN  @VSACNAMESForex+CHAR(13)+CHAR(10) + N''+ AC_NAME_Forex --+CHAR(13)+CHAR(10)
		  ELSE AC_NAME  END , N'') , 
		@VM_ID = UnqId;
    


	  SET @cStep='47'      
	  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     

	 UPDATE A SET VS_AC_NAME=B.VSACNAMES ,VS_AC_NAME_forex=B.VSACNAMES_forex 
	 FROM #TEMP2 A
	 JOIN
	 (
		SELECT UnqId, VSACNAMES = VSACNAMES, VSACNAMES_forex = VSACNAMES_forex,
		SR =ROW_NUMBER() OVER (PARTITION BY UNQID ORDER BY LEN(VSACNAMES)  DESC)
		FROM @t
	
		) B ON A.UnqId=B.UnqId and b.SR=1
end
Else
begin

     UPDATE A SET VS_AC_NAME=B.VSACNAMES ,VS_AC_NAME_forex=B.VSACNAMES_forex 
	 FROM #TEMP2 A
	 JOIN
	 (
		SELECT UnqId, VSACNAMES = AC_NAME, VSACNAMES_forex = AC_NAME_forex,
		SR =ROW_NUMBER() OVER (PARTITION BY UNQID ORDER BY Amount  DESC)
		FROM @t
	
		) B ON A.UnqId=B.UnqId and b.SR=1

end
  
  --END VS ACNAME       

  SET @cStep='47.2'          
  IF @nMode=4
  BEGIN
		DECLARE @cBrokerName VARCHAR(500)
		SELECT TOP 1 @cBrokerName=ac_name FROM lm01106 (NOLOCK) WHERE ac_code=@cAcCodePara
		UPDATE #temp2 SET head_name=@cBrokerName,display_head_name=@cBrokerName
  END
    
  SET @cStep='48'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     
    
  update #temp2 set DISPLAY_bs_head_name='',DISPLAY_head_name='',DISPLAY_ac_name=''    
  where not (narration ='Opening Balance'  AND vm_id IS NULL) --like '%Sub Total%' or Narration like '%Closing balance%'      
   update #temp2 set VoucherType='',runningTotal='',runningTotal_forex='',DISPLAY_VoucherDate=''    
  where narration like '%Sub Total%' or Narration like '%Closing balance%'    
    
 UPDATE #temp2 SET major_head_code=DBO.fn_act_majorhead(head_code)      
 UPDATE #temp2 SET DebitAmount=NULL,DebitAmount_Forex=NULL WHERE DebitAmount=0     
 UPDATE #temp2 SET CreditAmount=NULL,CreditAmount_Forex=NULL WHERE CreditAmount=0    
 
 UPDATE #temp2 SET major_head_code=DBO.fn_act_majorhead(head_code)      
    
 IF @cAcCodePara<>''    
 BEGIN    
	  IF EXISTS (SELECT TOP 1 AcCode FROM #temp2 a WHERE AcCode<>@cAcCodePara)    
		   UPDATE #temp2 SET group_ledger=1     
	  ELSE    
		   UPDATE #temp2 SET group_ledger=0    
 END    
 
 UPDATE #temp2 set accode=accode+'(memo)',ac_name=ac_name+'(MEMO)' WHERE left(vouchercode,4)='memo'
       
  SET @cStep='49'      
  
  IF @nMode<>0
  BEGIN
	print 'av'
	  IF EXISTS (SELECT TOP 1 a.* FROM #tmpcb a JOIN 
				 (select ac_code,vouchercode,sum(isnull(creditamount,0)-isnull(debitamount,0)) as balance
				 from #temp2 where narration='closing balance'  group by ac_code,vouchercode) b  ON
				 a.ac_code=b.ac_code and a.vouchercode=b.vouchercode
				 where abs(a.balance-b.balance)>10
				) 
	  begin
			
			DECLARE @nStored numeric(20,2),@nCalculated numeric(20,2),@cmismatchAc varchar(400)
			SELECT TOP 1 @nStored=a.balance,@nCalculated=b.balance,@cmismatchAc=ac_name
					FROM #tmpcb a 
			     JOIN (select ac_code,vouchercode,sum(isnull(creditamount,0)-isnull(debitamount,0)) as balance
				 from #temp2 where narration='closing balance'  group by ac_code,vouchercode) b  ON a.ac_code=b.ac_code
				 and a.vouchercode=b.vouchercode
				 join lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
				 where round(a.balance,2)<>round(b.balance,2)
			set @cErrormsg='Mismatch in Closing balance of Ledger :'+@cmismatchAc+' Calculated:'+ltrim(rtrim(str(@nCalculated,20,2)))+'
							Stored:'+ltrim(rtrim(str(@nStored,20,2)))+'...Please contact SoftInfo'
			goto end_proc
	  end
  END
  
  

  SET @cStep='49.5'          
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113) 
    --select @nMode
	IF @nMode>0
	BEGIN
	  select @nMode AS A,cost_center_dept_id,a.vm_id,unqid,b.HEAD_NAME as  bs_head_name,a.head_name,a.ac_name,AcCode,
	  voucherDate,VoucherType, Narration, DebitAmount, CreditAmount, runningTotal,
	  DebitAmount_forex, CreditAmount_forex, runningTotal_forex,
	  DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_ac_name,display_VoucherDate,d.ac_name as major_ac_name,group_ledger ,XN_TYPE,    
	  VS_AC_NAME as DISPLAY_VS_AC_NAME,vouchercode,voucher_no,ref_no ,
	  LTRIM(RTRIM(B0.ADDRESS0+' '+b0.ADDRESS1+' '+b0.ADDRESS2+' '+b1.area_name+' '+b2.city+' '+B3.state )) AS ADDRESS,B0.Ac_gst_no AS GST_NO
	   from #temp2 a      
	  JOIN HD01106 b ON a.major_head_code=b.HEAD_CODE      
	  JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	  JOIN lm01106 d (NOLOCK) ON d.ac_code=c.major_ac_code       
		LEFT OUTER JOIN lmp01106 b0 ON b0.ac_code=c.ac_code
		LEFT OUTER JOIN area b1 ON b1.area_code=b0.area_CODE
		LEFT OUTER JOIN city b2 ON b2.CITY_CODE=b1.city_code
		LEFT OUTER JOIN State b3 ON b3.state_code=b2.state_code
	  order by bs_head_name,head_name,ac_name,voucherdate,unqid  
	END
	ELSE
	BEGIN
	  SELECT @nMode AS A,cost_center_dept_id,a.vm_id,unqid,b.HEAD_NAME as  bs_head_name,a.head_name,a.ac_name,AcCode,
	  voucherDate,VoucherType, Narration, DebitAmount, CreditAmount, runningTotal,runningTotal_forex,    
	  DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_ac_name,display_VoucherDate,d.ac_name as major_ac_name,group_ledger ,XN_TYPE,    
	  VS_AC_NAME as DISPLAY_VS_AC_NAME,vouchercode,voucher_no,ref_no ,
	  LTRIM(RTRIM(B0.ADDRESS0+' '+b0.ADDRESS1+' '+b0.ADDRESS2+' '+b1.area_name+' '+b2.city+' '+B3.state )) AS ADDRESS,B0.Ac_gst_no AS GST_NO
	  from #temp2 a      
	  JOIN HD01106 b ON a.major_head_code=b.HEAD_CODE      
	  JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	  JOIN lm01106 d (NOLOCK) ON d.ac_code=c.major_ac_code       
		LEFT OUTER JOIN lmp01106 b0 ON b0.ac_code=c.ac_code
		LEFT OUTER JOIN area b1 ON b1.area_code=b0.area_CODE
		LEFT OUTER JOIN city b2 ON b2.CITY_CODE=b1.city_code
		LEFT OUTER JOIN State b3 ON b3.state_code=b2.state_code
		UNION ALL 
		select @nMode,'' cost_center_dept_id,'' vm_id,99999999 unqid,'ZZZZZZZZ' bs_head_name,'ZZZZZZZZ' head_name,'ZZZZZZZZ' ac_name,'' AcCode,
	  '' voucherDate,'' VoucherType,'Grand Total' Narration,SUM( DebitAmount) AS DebitAmount, SUM(CreditAmount)CreditAmount,'' runningTotal,'' runningTotal_forex,    
	  '' DISPLAY_bs_head_name,'' DISPLAY_head_name,'' DISPLAY_ac_name,'' display_VoucherDate,'' major_ac_name,0 group_ledger ,'' XN_TYPE,    
	  '' DISPLAY_VS_AC_NAME,'' vouchercode,'' voucher_no,'' ref_no , '' AS ADDRESS,'' AS GST_NO
	  from #temp2 
	  WHERE Narration NOT IN ('SUB TOTAL','CLOSING BALANCE')  
	  order by bs_head_name,head_name,ac_name,voucherdate,unqid  

	END 

    IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='LEDGER_DETAIL_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
  		DROP TABLE LEDGER_DETAIL_CURSOR

	IF  OBJECT_ID('LEDGER_DETAIL_CURSOR','U') IS NULL	
	BEGIN
		  select cost_center_dept_id,a.vm_id,unqid,b.HEAD_NAME as  bs_head_name,a.head_name,c.ac_name,AcCode,VoucherDate,       
		  VoucherType, Narration, DebitAmount, CreditAmount, runningTotal,runningTotal_forex,      
		  DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_ac_name,display_VoucherDate,d.ac_name as major_ac_name,group_ledger ,XN_TYPE,      
		  VS_AC_NAME as DISPLAY_VS_AC_NAME    ,'' voucher_no ,'' ref_no  ,
			LTRIM(RTRIM(B0.ADDRESS0+' '+b0.ADDRESS1+' '+b0.ADDRESS2+' '+b1.area_name+' '+b2.city+' '+B3.state )) AS ADDRESS,B0.Ac_gst_no AS GST_NO
		  INTO LEDGER_DETAIL_CURSOR  
		  from #temp2 a        
		  JOIN HD01106 b ON a.major_head_code=b.HEAD_CODE        
		  JOIN lm01106 c (NOLOCK) ON c.ac_code=a.accode      
		  JOIN lm01106 d (NOLOCK) ON d.ac_code=c.major_ac_code 
		  LEFT OUTER JOIN lmp01106 b0 ON b0.ac_code=c.ac_code
		LEFT OUTER JOIN area b1 ON b1.area_code=b0.area_CODE
		LEFT OUTER JOIN city b2 ON b2.CITY_CODE=b1.city_code
		LEFT OUTER JOIN State b3 ON b3.state_code=b2.state_code     
   	    WHERE 1=2
	END

  

  goto end_proc      
    
lblMonthly:    
      
  SET @cStep='52'    
     
   CREATE TABLE #tempMonthList (year_no numeric(4,0),month_no numeric(2,0),from_dt datetime,to_dt datetime)    
    
   INSERT #tempMonthList (year_no,month_no,from_dt,to_dt)    
   select year_no,month_no,from_dt,to_dt from dbo.FN_ACT_MONTHLIST(@dFromDt ,@dToDt)    
    
    
  create table #tempMonthly (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2),     
  CreditAmount numeric(20, 2),RurnningTotal NUMERIC(20,2),DebitAmount_forex numeric(20, 2),     
  CreditAmount_forex numeric(20, 2),RurnningTotal_forex NUMERIC(20,2))       
    
  create table #tempMonthlyFinal (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2),     
  CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),DebitAmount_forex numeric(20, 2),     
  CreditAmount_forex numeric(20, 2),RunningTotal_forex NUMERIC(20,2),unq_id INT IDENTITY)       
      
  insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex)    
  select AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex FROM #tmpOb    
      
    
  SET @cStep='50'    
      
  --insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)    
  --SELECT @cAcCodePara AS AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount    
    
  SET @cStep='55'    
  insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount,DebitAmount_forex, CreditAmount_forex)    
  SELECT @cAcCodePara AS AcCode,    
  DateName(mm,DATEADD(mm,Number,0)) as month_name,number+1 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount,0 as DebitAmount_forex,0 as CreditAmount_forex    
  FROM master..spt_values where number between 0 and 11 and type='p'    
    
    
  SET @cStep='58'    
  UPDATE a SET YEAR_NO=B.YEAR_NO,DebitAmount=b.debitamount,CreditAmount=b.creditamount FROM #tempMonthly a    
  JOIN (    
  select MONTH(vmdt.voucher_dt) as month_no,YEAR(vmdt.voucher_dt) as year_no,    
  sum(credit_amount)  as CreditAmount,      
  sum(debit_amount) as DebitAmount,
  sum(credit_amount_forex)  as CreditAmount_forex,      
  sum(debit_amount_forex) as DebitAmount_forex        
  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
  JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code    
  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
  left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
  JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
  where vmdt.voucher_dt between @dFromDt AND @dToDt AND cancelled=0      
  and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')      
  AND (@nSorViewType<>2 OR sor.VD_ID IS NOT NULL)          
  group by lm.AC_CODE,MONTH(vmdt.voucher_dt),YEAR(vmdt.voucher_dt)    
  ) b ON a.month_no=b.month_no    
    
      
  SET @cStep='60'    
  UPDATE #tempMonthly SET YEAR_NO=(CASE WHEN month_no in (1,2,3) THEN YEAR(@dToDt) ELSE YEAR(@dFromDt) END)    
    
   INSERT #tempMonthlyFinal (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)    
   SELECT AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount FROM #tempMonthly    
   ORDER BY year_no,month_no    
    
  SET @NSUMVALUE=0     
    
  ;WITH A    
  AS    
  (    
   SELECT TOP 100 PERCENT *     
   FROM #tempMonthlyFinal    
   ORDER BY unq_id    
  )     
     UPDATE A SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),      
  @NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DebitAmount,0)-ISNULL(CreditAmount  ,0)    
       
    
   SET @cStep='60'    
      insert #tempMonthlyFinal (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount,RunningTotal)      
   select @cAcCodePara AcCode,'Sub Total' month_name,13 month_no,year(@dToDt) year_no,    
   SUM(DebitAmount)  as  DebitAmount  ,    
   SUM(CreditAmount)  as CreditAmount,      
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempMonthlyFinal     
    
    
   SET @cStep='62'    
      insert #tempMonthlyFinal (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount,RunningTotal)      
   select @cAcCodePara AcCode,'Closing Balance' month_name,13 month_no,year(@dToDt) year_no,    
   --SUM(DebitAmount)  as  DebitAmount  ,    
   --SUM(CreditAmount)  as CreditAmount,      
   case when sum(debitamount-creditamount)<0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end  as DebitAmount,      
   case when  sum(debitamount-creditamount)>=0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end as CreditAmount ,     
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempMonthlyFinal     
   WHERE 'Sub Total' <>month_name    
      
            
         
  SET @cStep='65'    
  update #tempMonthlyFinal SET DebitAmount=NULL WHERE ISNULL(DebitAmount,0)=0    
  update #tempMonthlyFinal SET CreditAmount=NULL WHERE ISNULL(CreditAmount,0)=0    
  
    
  SELECT @cAcCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,    
  LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal,'' as from_Dt,'' as to_dt,unq_id     
  FROM #tempMonthlyFinal a    
  WHERE month_name IN ('Opening Balance','Closing Balance','Sub Total')    
  UNION ALL    
  SELECT @cAcCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,    
  LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal,b.from_Dt,b.to_dt,unq_id FROM #tempMonthlyFinal a    
  JOIN #tempMonthList b ON a.year_no=b.year_no AND a.month_no=b.month_no    
  ORDER BY unq_id    
    

	IF EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='LEDGER_MONTHLY_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE LEDGER_MONTHLY_CURSOR

	IF  OBJECT_ID('LEDGER_MONTHLY_CURSOR','U') IS NULL	
	BEGIN
		SELECT @cAcCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,      
		LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+      
		(CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal,'' as from_Dt,'' as to_dt,unq_id       
		INTO LEDGER_MONTHLY_CURSOR
		FROM #tempMonthlyFinal a      
		WHERE 1=2
	END
    goto end_proc    
    
lblDaily:    
     
 DECLARE @cMonth VARCHAR(10)    
    
 SET @cStep='68'       
    
 create table #tempDaily (AcCode varchar(20),voucher_dt datetime, DebitAmount numeric(20, 2),     
 CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2))       
    
 create table #tempDailyFinal (AcCode varchar(20),display_voucherdate varchar(70),voucher_dt datetime, DebitAmount numeric(20, 2),     
 CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),unq_id INT IDENTITY,INTEREST NUMERIC(20,2))       
      
 SET @cStep='70'    
      
       
 insert #tempDaily (AcCode,voucher_dt,DebitAmount, CreditAmount)    
 SELECT @cAcCodePara Accode,DATEADD(DD,number,@dFromdt-1) as XN_DT,0 as DebitAmount,0 as CreditAmount    
 FROM master..spt_values where number between 0 and 367 and type='p'    
 AND DATEADD(DD,number,@dFromdt)<=@dToDt+1    
    
 SET @cStep='90'    
 IF NOT EXISTS (SELECT ac_code FROM lm01106 (NOLOCK) WHERE ac_code=@cAcCodePara AND CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0)    
  UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount     
  FROM #tempDaily a    
   JOIN (    
   select @dFromDt-1 as voucher_dt,sum(credit_amount)  as CreditAmount,sum(debit_amount)  as DebitAmount ,
   sum(credit_amount_forex)  as CreditAmount_forex,sum(debit_amount_forex)  as DebitAmount_forex      
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
   join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
   JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code    
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
   JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
   where vmdt.voucher_dt<@dFromDt AND cancelled=0      
   and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')      
   AND (@nSorViewType<>2 OR sor.VD_ID IS NOT NULL)          
   group by lm.AC_CODE--,VOUCHER_DT    
   ) b ON a.voucher_dt=b.voucher_dt    
    
     
 SET @cStep='90'    
 UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount 
 FROM #tempDaily a    
  JOIN (    
  select vmdt.voucher_dt as voucher_dt,sum(credit_amount)  as CreditAmount,sum(debit_amount)  as DebitAmount 
  ,sum(credit_amount_forex)  as CreditAmount_forex,sum(debit_amount_forex)  as DebitAmount_forex 
  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE      
  JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code    
  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
  left join #tmpSorEntries SOR on SOR.VD_ID=vd.vd_id
  JOIN #vmDates vmdt ON vmdt.vm_id=vm.vm_id
  where vmdt.voucher_dt between @dFromDt AND @dToDt AND cancelled=0      
  and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')      
  AND (@nSorViewType<>2 OR sor.VD_ID IS NOT NULL)          
  group by lm.AC_CODE,vmdt.voucher_dt    
  ) b ON a.voucher_dt=b.voucher_dt    
    
      
  SET @cStep='95'    
  INSERT #tempDailyFinal (AcCode,display_voucherdate,voucher_dt,DebitAmount, CreditAmount)    
  SELECT AcCode,'Opening Balance' as display_voucherdate,'' as voucher_Dt,    
   case when (debitamount-creditamount)>=0 then abs((DEBITAMOUNT - CREDITAMOUNT)) else 0 end  as DebitAmount,      
   case when  (debitamount-creditamount)<0 then abs((DEBITAMOUNT - CREDITAMOUNT)) else 0 end as CreditAmount           
  FROM #tempDaily    
  WHERE voucher_dt=@dFromDt-1    
    
  INSERT #tempDailyFinal (AcCode,display_voucherdate,voucher_dt,DebitAmount, CreditAmount)    
  SELECT AcCode,convert(varchar,voucher_dt,105),voucher_Dt,DebitAmount, CreditAmount FROM #tempDaily    
  WHERE voucher_dt>=@dFromDt    
  ORDER BY voucher_dt    
    
      
      
  SET @cStep='98'    
  SET @NSUMVALUE=0     
    
  ;WITH A    
  AS    
  (    
   SELECT TOP 100 PERCENT *     
   FROM #tempDailyFinal    
   ORDER BY unq_id    
  )     
     UPDATE A SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),      
  @NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DebitAmount,0)-ISNULL(CreditAmount  ,0)    
      
  SET @cStep='100'    
      insert #tempDailyFinal (AcCode,display_voucherdate,DebitAmount, CreditAmount,RunningTotal)      
   select @cAcCodePara AcCode,'Sub Total' voucher_dt,    
   sum(DEBITAMOUNT)  as DebitAmount,      
   sum(CREDITAMOUNT) as CreditAmount  ,         
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempDailyFinal    
    
   SET @cStep='102'    
   insert #tempDailyFinal (AcCode,display_voucherdate,DebitAmount, CreditAmount,RunningTotal)      
   select @cAcCodePara AcCode,'Closing Balance' display_voucherdate,    
   case when sum(debitamount-creditamount)<0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end  as DebitAmount,      
   case when  sum(debitamount-creditamount)>=0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end as CreditAmount  ,         
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempDailyFinal     
    WHERE 'Sub Total' <>display_voucherdate    
	DECLARE @CHEADCODE VARCHAR(4000),@CHEADCODE1 VARCHAR(4000),@CHEADCODE2 VARCHAR(4000),@CHEADCODE3 VARCHAR(4000) 
	DECLARE @bOnlyBank INT
	SET @CHEADCODE=DBO.FN_ACT_TRAVTREE('0000000013') 
	SET @CHEADCODE1=DBO.FN_ACT_TRAVTREE('0000000007') 
	SET @CHEADCODE2=DBO.FN_ACT_TRAVTREE('0000000031') 


	SELECT @bOnlyBank =COUNT(*)
	 FROM LM01106  A (NOLOCK) 
	WHERE (CHARINDEX(HEAD_CODE,@CHEADCODE)>0  
	OR CHARINDEX( HEAD_CODE, @CHEADCODE1)>0 )  AND NOT CHARINDEX( HEAD_CODE, @CHEADCODE2)>0 
	AND A.AC_CODE = @cAcCodePara



	IF @bCalInterrest =1 AND @bOnlyBank>0
	BEGIN
		update #tempDailyFinal SET INTEREST=CAST((CASE WHEN runningtotal<>0 AND display_voucherdate LIKE '[0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]' THEN (ROUND((runningtotal * @bInterestPercent)/ 36500,2))  ELSE NULL END) AS NUMERIC(14,2))    

		update A SET A.INTEREST=ABS(B.INTEREST)
		FROM #tempDailyFinal A
		JOIN
		(
			SELECT SUM(INTEREST) AS INTEREST FROM #tempDailyFinal
		)B ON 1=1
		WHERE A.display_voucherdate IN ('Sub Total','Closing Balance')
   END
         
  update #tempDailyFinal SET DebitAmount=NULL WHERE ISNULL(DebitAmount,0)=0    
  update #tempDailyFinal SET CreditAmount=NULL WHERE ISNULL(CreditAmount,0)=0    
    
  SET @cStep='110'    
  SELECT AcCode,voucher_dt,display_voucherdate,DebitAmount, CreditAmount,LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal, INTEREST
  FROM #tempDailyFinal 
  ORDER BY unq_id    
    
	IF EXISTS(SELECT 'U' FROM SYS.TABLES WHERE NAME ='LEDGER_DAILY_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE LEDGER_DAILY_CURSOR

	IF  OBJECT_ID('LEDGER_DAILY_CURSOR','U') IS NULL	
	BEGIN
		SELECT AcCode,voucher_dt,display_voucherdate,DebitAmount, CreditAmount,LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+      
		(CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal ,INTEREST
		INTO LEDGER_DAILY_CURSOR
		FROM #tempDailyFinal 
		WHERE 1=2
   END
  goto end_proc    
    
END TRY       
      
BEGIN CATCH      
 SET @cErrormsg='Error in Procedure SP3S_MULTILEDGER at Step#'+@cStep+':'+ERROR_MESSAGE()      
 goto end_proc      
END CATCH      
      
end_proc:      
 IF ISNULL(@cErrormsg,'')<>''      
  select ISNULL(@cErrormsg,'') as errmsg      
END      
---End Multi Ledger----------------------------------- 