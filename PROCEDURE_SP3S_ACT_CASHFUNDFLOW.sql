CREATE PROCEDURE SP3S_ACT_CASHFUNDFLOW--(LocId 3 digit change by Sanjay:04-11-2024)
@dFromDt DATETIME='',  
@dToDt DATETIME='',
@cAcCodePara CHAR(10)='',
@nMode NUMERIC(1,0)=1,
@nMonthNo NUMERIC(2,0)=0,
@nSpId VARCHAR(50)='',
@nViewType NUMERIC(1,0)=1
AS  
BEGIN  
 --DECLARE @dFromDt DATETIME='2019-03-01'  ,@dToDt DATETIME  ='2019-09-26'
BEGIN TRY  
     
	 DECLARE @cStep VARCHAR(4),@cErrormsg varchar(max),@dOpnDt DATETIME,@CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS VARCHAR(4),
			@CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS VARCHAR(4),@cViewLedgerForCancelledVouchers VARCHAR(20),
			@cDebtorHEads VARCHAR(MAX),@cDebtorHEads1 VARCHAR(MAX),@cCmd NVARCHAR(MAX),@cLmCol VARCHAR(100)

	 SELECT TOP 1 @CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS=VALUE FROM  CONFIG WHERE CONFIG_OPTION='DONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS'
	 SELECT TOP 1 @CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS=VALUE FROM  CONFIG WHERE CONFIG_OPTION='CONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS'  

	 SELECT TOP 1 @cViewLedgerForCancelledVouchers=value FROM config WHERE config_option='LEDGER_OPENING_CUTOFF_DATE'
	
	SET @CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS=ISNULL(@CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS,0)
	SELECT @CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS=ISNULL(@CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS,0)
	 SET @cViewLedgerForCancelledVouchers=ISNULL(@cViewLedgerForCancelledVouchers,'')
	 
	 
		 SELECT @cDebtorHEads=dbo.FN_ACT_TRAVTREE('0000000013')	
		 SELECT @cDebtorHEads1=dbo.FN_ACT_TRAVTREE('0000000014')	
	 
	 declare @CDONOTPICKOBHEADS VARCHAR(2000),@cFinyear VARCHAR(10)  
	 
	 IF OBJECT_ID('#locListC','u') IS NOT NULL
		DROP TABLE #locListC

	 CREATE TABLE #locListC (dept_id VARCHAR(4))

	 SET @cStep='2'  

	 IF @nMode=0
		SET @cAcCodePara=''

	IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')
		INSERT #locListC
		SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId
	ELSE
		INSERT #locListC
		SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)

	 IF OBJECT_ID('tempdb..#temp','u') is not null  
		drop table #temp  

	 IF OBJECT_ID('tempdb..#tempDNObHd','u') is not null  
	    drop table #tempDNObHd

	 IF OBJECT_ID('tempdb..#tempLm','u') is not null  
	    drop table #tempLm 
		
	 SET @cStep='5'  
	 SELECT DISTINCT ac_code AS rep_ac_code 
	 INTO #tempLm 
	 FROM lm01106 (NOLOCK) 
	 WHERE CHARINDEX(head_code,@cDebtorHEads)>0 OR CHARINDEX(head_code,@cDebtorHEads1)>0

	 IF OBJECT_ID('tempdb..#tmpOb','u') IS NOT NULL  
		DROP TABLE #tmpOb  
			   
	 SET @cStep='7'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
    
	 SELECT @CDONOTPICKOBHEADS=''--DBO.FN_ACT_TRAVTREE('0000000010')  
     
	 SELECT head_code INTO #tempDNObHd FROM hd01106 WHERE 1=2-- CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0

	 SET @cStep='10'  
	 
	 SET @cFinyear='01'+DBO.FN_GETFINYEAR(@dFromDt)	

	 SET @cLmCol=(CASE WHEN @nViewType=1 THEN 'major_ac_code' ELSE 'ac_code' END)

	 CREATE TABLE #tmpOb (voucherdate DATETIME,accode CHAR(10),debitamount NUMERIC(20,2),creditamount NUMERIC(20,2))
	 
	 IF NOT (@nMode=3 AND @nMonthNo<>4)
	 BEGIN
		 		 
		 SET @cCmd=N'select '''+CONVERT(VARCHAR,@dFromDt,110)+''' as voucherdate,
		 ''0000000000'' as accode,  
		 case when sum(debit_amount-credit_amount)>=0 then sum(DEBIT_AMOUNT - CREDIT_AMOUNT) else 0 end as DebitAmount,  
		 case when sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount  
		 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
		 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
		 JOIN #tempLm lr ON '+(CASE WHEN @nViewType=1 THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code
		 JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
		 LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=vm.vm_id
		 LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=vm.vm_id								 
		 LEFT OUTER JOIN #tempDNObHd DNHD on dnhd.head_code=lm.head_code
		 where vm.cancelled=0 AND vm.VOUCHER_DT < '''+CONVERT(VARCHAR,@dFromDt,110)+''' 
		 AND dnhd.head_code IS NULL'
		 --AND (vm.VOUCHER_CODE NOT IN (''MEMO000001'',''MEMO000002'') OR '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1'')
		 --AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
			-- ('''+@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS+'''=''1'' AND '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1''))					
		 --AND ((VOUCHER_DT>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)'
			-- OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1 
			--	 AND VOUCHER_DT<='''+@cViewLedgerForCancelledVouchers+'''))'
		 --group by lm.'+@cLmCol
		 
		 PRINT @cCmd
		 INSERT #tmpOb (voucherdate,accode,DebitAmount,CreditAmount)
		 EXEC SP_EXECUTESQL @cCmd
		 
	END	
	--SELECT * FROM #tmpOb
 IF @nMode=1
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
	 create table #temp (cost_center_dept_id VARCHAR(4),vm_id VARCHAR(50), AcCode varchar(20),head_code CHAR(10), VoucherDate datetime, OrderDate datetime, VoucherType varchar(10),   
	 Narration varchar(4000), DebitAmount numeric(20, 2), CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),
	 UnqId int identity PRIMARY KEY,vd_id VARCHAR(50))   
	 --ALTER TABLE #temp ADD CONSTRAINT PK PRIMARY KEY(UnqId)
	CREATE TABLE #TempVSAC (VM_ID VARCHAR(50),DISPLAY_VS_AC_NAME VARCHAR(MAX))
	 
	 insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount)  
	 select '0000000000' AcCode,'0000000000'head_code, @dFromDt VoucherDate, @dFromDt-1 OrderDate, '' VoucherType, 'Opening Balance' as Narration,   
	 0 as DebitAmount,0  as CreditAmount 
	 --FROM lm01106 a
	 --JOIN #tempLm lr ON a.AC_CODE=lr.rep_ac_code..
	 --SELECT HEAD_CODE FROM HD01106 WHERE head_NAME=''
     
	 SET @cStep='15'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
     
	SET @cCmd=N'Select cost_center_dept_id,vd.vm_id, lm.'+@cLmCol+' AcCode,head_code, vm.voucher_dt VoucherDate, vm.voucher_dt OrderDate, vch.VOUCHER_TYPE_ALIAS VoucherType, 
	  vd.Narration, debit_amount, credit_amount  ,vd.vd_id
	  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
	  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
	  join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE  
	  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
	  JOIN #tempLm lr ON '+(CASE WHEN @nViewType=1 THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code
	  LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=vm.vm_id
	  LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=vm.vm_id							  
	  where vm.cancelled=0 AND vm.VOUCHER_DT between '''+CONVERT(VARCHAR,@dFromDt,110)+''' and '''+CONVERT(VARCHAR,@dToDt,110)+'''  
	  --AND (vm.VOUCHER_CODE NOT IN (''MEMO000001'',''MEMO000002'') OR '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1'')
	  --AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
	  -- 	   ('''+@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS+'''=''1'' AND '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1''))					

	  --AND ((VOUCHER_DT>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)
			-- OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1 
			--	 AND VOUCHER_DT<='''+@cViewLedgerForCancelledVouchers+'''))	   	   
	  ORDER BY cost_center_dept_id,vm.voucher_dt'  

	  PRINT @cCmd

	  insert #temp (cost_center_dept_id,vm_id ,AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vd_id)  
	  EXEC SP_EXECUTESQL @cCmd 

	 
	 SET @cStep='17'  
	 SET @cCmd=N'select ''0000000000'' AcCode,''0000000000'' head_code, '''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate, 
	  '''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate, ''ZZ1'' VoucherType, 
	 ''Sub Total'' as Narration,   
	  sum(DEBIT_AMOUNT) DebitAmount,  
	  sum(CREDIT_AMOUNT) as CreditAmount  
	  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
	  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
	  JOIN #tempLm lr ON '+(CASE WHEN @nViewType=1 THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code
	  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
	  LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=vm.vm_id
	  LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=vm.vm_id						
	  where vm.cancelled=0 AND vm.VOUCHER_DT BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+CONVERT(VARCHAR,@dToDt,110)+'''
 	 -- AND (vm.VOUCHER_CODE NOT IN (''MEMO000001'',''MEMO000002'') OR  '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1'')
	  --AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
	  -- 	   ('''+@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS+'''=''1'' AND '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1''))					
	  --AND ((VOUCHER_DT>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)
			-- OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1 
			--	 AND VOUCHER_DT<='''+@cViewLedgerForCancelledVouchers+'''))	   	   
	  --group by head_code'  
     
	 --print @cCmd

	 PRINT @cCmd
	 insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount)  
	 EXEC SP_EXECUTESQL @cCmd

	 --SELECT *
	 --FROM #temp a 
	 --WHERE  Narration='Opening Balance'


	 SET @cStep='19'  
	 UPDATE a SET debitamount=b.debitamount,creditamount=b.creditamount --,RunningTotal=b.DebitAmount-b.CreditAmount	 
	 FROM #temp a 
	 JOIN #tmpOb b ON a.accode=b.accode   
	 WHERE  Narration='Opening Balance'  
  
     SET @cStep='21'  
	 
	 SET @cCmd=N'select ''0000000000'' AcCode,''0000000000''head_code, '''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate,'''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate, ''ZZ2'' VoucherType, ''Closing Balance'' as Narration,   
	  case when sum(debit_amount-credit_amount)<0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end  as DebitAmount,  
	  case when  sum(debit_amount-credit_amount)>=0 then abs(sum(DEBIT_AMOUNT - CREDIT_AMOUNT)) else 0 end as CreditAmount  
	  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
	  join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
	  JOIN #tempLm lr ON '+(CASE WHEN @nViewType=1 THEN 'lm.AC_CODE' ELSE 'lm.major_ac_code' END)+'=lr.rep_ac_code
	  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
	  LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=vm.vm_id
	  LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=vm.vm_id							  
	  where vm.cancelled=0 AND vm.VOUCHER_DT BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+CONVERT(VARCHAR,@dToDt,110)+'''
 	 -- AND (vm.VOUCHER_CODE NOT IN (''MEMO000001'',''MEMO000002'') OR '+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'<>''1'')
	  --AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
	  --	   ('''+@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS+'''=''1'' AND '''+@cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS+'''<>''1''))					
	  --AND ((VOUCHER_DT>'''+@cViewLedgerForCancelledVouchers+''' AND vm.cancelled=0)
			-- OR ('''+@cViewLedgerForCancelledVouchers+'''<>'''' AND ISNULL(consider_for_ledger_view,0)=1 
			--	 AND VOUCHER_DT<='''+@cViewLedgerForCancelledVouchers+'''))
	  	   
	  --group by head_code'  
	  
	  insert #temp (AcCode,head_code, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount)  
	  EXEC SP_EXECUTESQL @cCmd

	 SET @cStep='24'  

	 --SELECT *
	 --FROM #temp a 
	 --WHERE  Narration='Opening Balance'

	 insert #temp (AcCode,head_code, VoucherDate,OrderDate, VoucherType, Narration, DebitAmount, CreditAmount)
	 SELECT a.AcCode,a.head_code,@dToDt as VoucherDate,a.OrderDate,a.VoucherType,'Closing Balance' AS Narration,
	 a.DebitAmount,a.CreditAmount
	 FROM #temp a LEFT OUTER JOIN 
	 (SELECT accode FROM #temp WHERE narration='Closing Balance') b ON a.accode=b.accode 
	 WHERE a.narration='Opening Balance' AND  b.accode IS NULL
	 

	 --SELECT *
	 --FROM #temp a 
	 --WHERE  Narration='Opening Balance'

	 SET @cStep='27'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)   
	 CREATE INDEX ind_accode ON #temp (ACCODE)  
   
	 SET @cStep='30'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
   
  
	 SET @cStep='35'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
	
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
	 IF OBJECT_ID('tempdb..#temp1','u') is not null  
	  drop table #temp1  
  
	 IF OBJECT_ID('tempdb..#tmpsum','u') is not null  
	  drop table #tmpsum  
     
	 SELECT a.* into #temp1 FROM #temp a
	 JOIN 
	 (SELECT distinct accode FROM #temp (NOLOCK) WHERE (debitamount+creditamount)<>0 
	 ) b on a.accode=b.accode 
	 

	CREATE CLUSTERED INDEX IX_1  ON #temp1 (voucherdate,UnqId)

	 DECLARe @NSUMVALUE NUMERIC(20,2),@cAcCode CHAR(10) ,@cVMID VARCHAR(50)
   
	 SELECT DISTINCT accode INTO #tmpSUm FROM #temp1  
	 SELECT DISTINCT VM_ID INTO #tmpVS FROM #temp1  
	SET @cStep='41'  
   --SELECT TOP 100 PERCENT a.* ,b.ac_name
			--FROM #temp1 a
			--JOIN lm01106 b on b.AC_CODE=a.AcCode
			----WHERE AcCode=@cAcCode 
			--ORDER BY voucherdate,UnqId
	 --WHILE EXISTS (SELECT TOP 1 * from #tmpsum)  
	 --BEGIN   
	 -- SELECT TOP 1 @cAcCode=accode FROM #tmpsum  
    
	 -- SET @NSUMVALUE=0  
    
	 -- UPDATE #temp1 SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),  
	 -- @NSUMVALUE=ISNULL(@NSUMVALUE,0)+DebitAmount-CreditAmount  
	 -- WHERE AcCode=@cAcCode  --AND narration
    
	 -- DELETE FROM #tmpsum WHERE AcCode=@cAcCode  
	 --END  
	 --SELECT * FROM #temp1
 
  
	 --WHILE EXISTS (SELECT TOP 1 * from #tmpsum)  
	 --BEGIN   
		--SELECT TOP 1 @cAcCode=accode FROM #tmpsum  

		SET @NSUMVALUE=0 
  
		;WITH A
		AS
		(
			SELECT TOP 100 PERCENT * 
			FROM #temp1
			--WHERE AcCode=@cAcCode 
			ORDER BY voucherdate--,UnqId
		) 
   		UPDATE A SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),  
		@NSUMVALUE=ISNULL(@NSUMVALUE,0)+ISNULL(DebitAmount,0)-ISNULL(CreditAmount  ,0)
	  --WHERE AcCode=@cAcCode  --AND narration

	  --UPDATE #temp1 SET RunningTotal=ISNULL(RunningTotal,0)+ISNULL(@NSUMVALUE,0),  
	  --@NSUMVALUE=ISNULL(@NSUMVALUE,0)+DebitAmount-CreditAmount  
	  --WHERE AcCode=@cAcCode  --AND narration
    
	
		UPDATE a SET DebitAmount=b.DebitAmount,a.CreditAmount=b.CreditAmount 
		FROM #temp1  a
		JOIN
		(
			SELECT SUM(DEBITAMOUNT) AS DEBITAMOUNT ,SUM(CREDITAMOUNT) AS CREDITAMOUNT 
			from #temp1 
			WHERE VoucherType NOT IN ('ZZ1','ZZ2') --AND AcCode=@cAcCode
			--GROUP BY AcCode
		)b ON 1=1--b.AcCode=a.AcCode
		WHERE 'ZZ1' =a.VoucherType --AND a.AcCode=@cAcCode

		UPDATE a SET DebitAmount=ABS(case when b.amount<0 then b.amount else 0 end) ,  
		CreditAmount  =ABS(case when b.amount>0 then b.amount else 0 end) 
		FROM #temp1  a
		JOIN
		(
			SELECT DEBITAMOUNT-CREDITAMOUNT AS AMOUNT 
			from #temp1 
			WHERE VoucherType IN ('ZZ1') --AND AcCode=@cAcCode
		)b ON 1=1--b.AcCode=a.AcCode
		WHERE 'ZZ2' =a.VoucherType --AND a.AcCode=@cAcCode

	 -- DELETE FROM #tmpsum WHERE AcCode=@cAcCode  
	 --END 
 /*
 Changes Required By Dinker for VS AC_CODE
 */
	WHILE EXISTS (SELECT TOP 1 * from #tmpVS WHERE vm_id is not null)  
	 BEGIN   
		SELECT TOP 1 @cVMID=VM_ID FROM #tmpVS  WHERE vm_id is not null
		DECLARE @CALL_VS_VALUE VARCHAR(MAX)
		SET @CALL_VS_VALUE=''
  
		select @CALL_VS_VALUE= @CALL_VS_VALUE+(CASE WHEN @CALL_VS_VALUE='' THEN '' ELSE CHAR(13)+CHAR(10) END)+ ac_name+' ['+CAST(CONVERT(NUMERIC(14,2),a.DEBIT_AMOUNT+a.CREDIT_AMOUNT) AS varchar(50)) +']'
		from vd01106 a  
		JOIN LM01106 b (NOLOCK) ON a.Ac_Code=b.AC_CODE  
		JOIN #temp1 C ON C.vm_id=a.VM_ID
		WHERE a.VM_ID=@cVMID AND c.VD_ID<>a.VD_ID AND a.X_TYPE=(CASE WHEN c.DebitAmount<>0 THEN 'CR' ELSE 'DR' END)
			
		INSERT INTO #TempVSAC(VM_ID,DISPLAY_VS_AC_NAME)
		SELECT @cVMID,LTRIM(RTRIM(@CALL_VS_VALUE))

		

	  DELETE FROM #tmpVS WHERE vm_id=@cVMID  
	 END 
	 SET @cStep='42'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
	 IF OBJECT_ID('tempdb..#temp2','u') is not null  
	  drop table #temp2  
   
   
  
	 SET @cStep='45'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
   
	 select cost_center_dept_id,vm_id,ac_name,b.head_code as major_head_code,b.head_code,head_name,head_name AS bs_head_name, AcCode,
	 VoucherDate, OrderDate, Vouchertype, Narration, DebitAmount, CreditAmount, UnqId,  
	 case when runningtotal >= 0 then convert(varchar, RunningTotal)+' Dr' else convert(varchar, abs(RunningTotal))+' Cr' end runningTotal  
	 ,ac_name AS DISPLAY_ac_name,head_name AS DISPLAY_head_name,head_name AS DISPLAY_bs_head_name,
	 CONVERT(VARCHAR(20) ,VoucherDate,105) AS   DISPLAY_VoucherDate,CONVERT(BIT,0) AS group_ledger,case when ISNULL(DebitAmount,0) > 0 then 'Dr' when ISNULL(CreditAmount,0) > 0 THEN 'Cr' else '' end XN_TYPE  
	 into #temp2  
	 from #temp1 a  
	 JOIN LM01106 b (NOLOCK) ON a.AcCode=b.AC_CODE  
	 JOIN HD01106 c (NOLOCK) ON c.head_code=b.head_code  
	 --order by VoucherDate--,UnqId  
   

	


	 SET @cStep='47'  
	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113) 

	 update #temp2 set DISPLAY_bs_head_name='',DISPLAY_head_name=''--,DISPLAY_ac_name=''
	 where narration <>'Opening Balance'--like '%Sub Total%' or Narration like '%Closing balance%'  
	  update #temp2 set VoucherType='',runningTotal='',DISPLAY_VoucherDate=''
	 where narration like '%Sub Total%' or Narration like '%Closing balance%'

	UPDATE #temp2 SET major_head_code=DBO.fn_act_majorhead(head_code)  
	UPDATE #temp2 SET DebitAmount=NULL WHERE DebitAmount=0 
	UPDATE #temp2 SET CreditAmount=NULL WHERE CreditAmount=0 

	IF @cAcCodePara<>''
	BEGIN
		IF EXISTS (SELECT TOP 1 AcCode FROM #temp2 a WHERE AcCode<>@cAcCodePara)
			UPDATE #temp2 SET group_ledger=1 
		ELSE
			UPDATE #temp2 SET group_ledger=0
	END
   
	 SET @cStep='49'  

	 PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)  
	 select cost_center_dept_id,a.vm_id,unqid,b.HEAD_NAME as  bs_head_name,a.head_name,c.ac_name,AcCode, VoucherDate, 
	 VoucherType, Narration, DebitAmount, CreditAmount, runningTotal,
	 DISPLAY_bs_head_name,DISPLAY_head_name,DISPLAY_ac_name,display_VoucherDate,d.ac_name as major_ac_name,group_ledger,XN_TYPE
	 ,	 G.DISPLAY_VS_AC_NAME
	 from #temp2 a  
	 JOIN HD01106 b ON a.major_head_code=b.HEAD_CODE  
	 JOIN lm01106 c (NOLOCK) ON c.ac_code=a.accode
	 JOIN lm01106 d (NOLOCK) ON d.ac_code=c.major_ac_code
	 LEFT OUTER JOIN #TempVSAC G ON G.vm_id=a.vm_id
	 order by VoucherDate,unqid  

	 goto end_proc  

lblMonthly:
	 
	 SET @cStep='52'
	 IF OBJECT_ID('tempdb..#tempMonthly','u') is not null  
		 drop table #tempMonthly  
	 
	IF OBJECT_ID('tempdb..#tempMonthList','u') is not null  
		 drop table #tempMonthList  
	
	CREATE TABLE #tempMonthList (year_no numeric(4,0),month_no numeric(2,0),from_dt datetime,to_dt datetime)

	INSERT #tempMonthList (year_no,month_no,from_dt,to_dt)
	select year_no,month_no,from_dt,to_dt from dbo.FN_ACT_MONTHLIST(@dFromDt ,@dToDt)


	 create table #tempMonthly (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2), 
	 CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2))   

	 create table #tempMonthlyFinal (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2), 
	 CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),unq_id INT IDENTITY)   
	 
	 --insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)
	 --select AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,DebitAmount, CreditAmount FROM #tmpOb
	 

	 SET @cStep='50'
	 
	 insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)
	 SELECT @cAcCodePara AS AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount

	 SET @cStep='55'
	 insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)
	 SELECT @cAcCodePara AS AcCode,	 DateName(mm,DATEADD(mm,Number,0)) as month_name,number+1 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount
	 FROM master..spt_values where number between 0 and 11 and type='p'

	 SET @cStep='56'
	 UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount 
	 FROM #tempMonthly a
	 JOIN 
	 (
		 select 'Opening Balance' as month_name,0 as MONTH_NO,
		 CASE WHEN sum(DEBIT_AMOUNT-credit_amount)<0 THEN sum(DEBIT_AMOUNT-credit_amount) ELSE 0 END as CreditAmount,  
		 CASE WHEN sum(DEBIT_AMOUNT-credit_amount)>=0 THEN sum(DEBIT_AMOUNT-credit_amount) ELSE 0 END as DebitAmount  
		 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
		 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
		 JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code
		 JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
		 where vm.voucher_dt < @dFromDt AND cancelled=0  
		 --and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')  
		 --group by lm.AC_CODE
	 ) b ON a.month_no=b.month_no


	 SET @cStep='58'
	 UPDATE a SET YEAR_NO=B.YEAR_NO,DebitAmount=b.debitamount,CreditAmount=b.creditamount FROM #tempMonthly a
	 JOIN (
	 select MONTH(VOUCHER_DT) as month_no,YEAR(VOUCHER_dT) as year_no,
	 sum(credit_amount)  as CreditAmount,  
	 sum(debit_amount) as DebitAmount  
	 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
	 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
	 JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code
	 JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
	 where vm.voucher_dt between @dFromDt AND @dToDt AND cancelled=0  
	 --and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')  
	 group by MONTH(VOUCHER_DT),YEAR(VOUCHER_dT)
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

	 goto end_proc

lblDaily:
	
	DECLARE @cMonth VARCHAR(10)

	SET @cStep='68'
	IF OBJECT_ID('tempdb..#tempDaily','u') is not null  
		 drop table #tempDaily  

	create table #tempDaily (AcCode varchar(20),voucher_dt datetime, DebitAmount numeric(20, 2), 
	CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2))   

	create table #tempDailyFinal (AcCode varchar(20),display_voucherdate varchar(70),voucher_dt datetime, DebitAmount numeric(20, 2), 
	CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),unq_id INT IDENTITY)   
	 
	SET @cStep='70'
	 
	 	
	insert #tempDaily (AcCode,voucher_dt,DebitAmount, CreditAmount)
	SELECT @cAcCodePara Accode,DATEADD(DD,number,@dFromdt-1) as XN_DT,0 as DebitAmount,0 as CreditAmount
	FROM master..spt_values where number between 0 and 365 and type='p'
	AND DATEADD(DD,number,@dFromdt-1)<=@dToDt

	SET @cStep='90'
	IF NOT EXISTS (SELECT ac_code FROM lm01106 (NOLOCK) WHERE ac_code=@cAcCodePara AND CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0)
		UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount 
		FROM #tempDaily a
		 JOIN (
		 select @dFromDt-1 as voucher_dt,sum(credit_amount)  as CreditAmount,sum(debit_amount)  as DebitAmount  
		 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
		 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
		 JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code
		 JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
		 where vm.voucher_dt<@dFromDt AND cancelled=0  
		 --and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')  
		 --group by lm.AC_CODE--,VOUCHER_DT
		 ) b ON a.voucher_dt=b.voucher_dt

	
	SET @cStep='90'
	UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount 
	FROM #tempDaily a
	 JOIN (
	 select VOUCHER_DT as voucher_dt,sum(credit_amount)  as CreditAmount,sum(debit_amount)  as DebitAmount  
	 from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID  
	 join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE  
	 JOIN #tempLm lr ON lm.AC_CODE=lr.rep_ac_code
	 JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id
	 where vm.voucher_dt between @dFromDt AND @dToDt AND cancelled=0  
	 --and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')  
	 group by VOUCHER_DT
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
     
	 update #tempDailyFinal SET DebitAmount=NULL WHERE ISNULL(DebitAmount,0)=0
	 update #tempDailyFinal SET CreditAmount=NULL WHERE ISNULL(CreditAmount,0)=0

	 SET @cStep='110'
	 SELECT AcCode,voucher_dt,display_voucherdate,DebitAmount, CreditAmount,LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+
	 (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal FROM #tempDailyFinal ORDER BY unq_id

	 goto end_proc

END TRY   
  
BEGIN CATCH  
	SET @cErrormsg='Error in Procedure SP3S_MULTILEDGER at Step#'+@cStep+':'+ERROR_MESSAGE()  
	goto end_proc  
END CATCH  
  
end_proc:  
	IF ISNULL(@cErrormsg,'')<>''  
		select ISNULL(@cErrormsg,'') as Narration  
END  
---End Multi Ledger-----------------------------------  