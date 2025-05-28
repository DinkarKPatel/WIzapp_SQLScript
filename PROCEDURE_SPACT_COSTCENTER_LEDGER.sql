CREATE PROCEDURE SPACT_COSTCENTER_LEDGER
(
	@dFromDt DATETIME='',      
	@dToDt DATETIME='',    
	@cCostCenterCodePara CHAR(10)='',    
	@nMode NUMERIC(1,0)=1,    
	@nMonthNo NUMERIC(2,0)=0,    
	@nSpId VARCHAR(50)='',    
	@cCompanyPanNo VARCHAR(20)=''
)
AS      
BEGIN      
 --DECLARE @dFromDt DATETIME='2019-03-01'  ,@dToDt DATETIME  ='2019-09-26'    
BEGIN TRY      
   DECLARE @cStep VARCHAR(4),@cErrormsg varchar(max),@dOpnDt DATETIME,@cCmd NVARCHAR(MAX),@cLmCol VARCHAR(100),
   @cFinyear VARCHAR(5),@dFinyearFromDt DATETIME,@CDONOTPICKOBHEADS VARCHAR(MAX)    

   if @cCompanyPanNo<>''
   begin
        
		DELETE FROM ACT_FILTER_LOC with (rowlock) WHERE sp_id=@nSpId

		insert into ACT_FILTER_LOC(dept_id,sp_id)
		select a.dept_id,@nSpId sp_id from location a (nolock)
		join loc_accounting_company b on a.PAN_NO=b.pan_no
		where a.pan_no=@cCompanyPanNo

   end
    
        
  CREATE TABLE #locListC (dept_id VARCHAR(4))    
    
  SET @cStep='2'      
    
  --IF @nMode=0    
  --SET @cCostCenterCodePara=''    
    
 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
 ELSE    
	  INSERT #locListC    
	  SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)    

	--SELECT * FROM #locListC
  
  SET @cStep='2.5'
  
  SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
  SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
  SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    
	
  SET @cStep='5.2'      	
  SELECT head_code INTO #tempDNObHd FROM hd01106 WHERE CHARINDEX(head_code,@CDONOTPICKOBHEADS)>0    
  

  SET @cStep='5'      
  SELECT DISTINCT a.COST_CENTER_CODE ac_code  INTO #tempLm 
  FROM COST_CENTER_MST a (NOLOCK)     
  WHERE a.COST_CENTER_CODE=@cCostCenterCodePara 

  SET @cFinyear='01'+dbo.fn_getfinyear(@dTodt)
  SELECT @dFinyearFromDt = DBO.FN_GETFINYEARDATE(@cFinyear,1)
  
	
  SET @cStep='5.2'      	
    

  SET @cStep='5.84'
  SELECT lm.ac_code ,sum((case when debit_amount>0 THEN 1 else -1 END)*CCREFAMOUNT) as balance,'ZZ2' vouchercode into #tmpcb from vd01106 a (NOLOCK)
  JOIN vm01106 b (NOLOCK) on b.vm_id=a.vm_id 
  JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=a.VD_ID
  join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id  
  JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=a.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
  where  b.voucher_dt<=@dToDt  AND cancelled=0 
   AND (d.head_code is null or b.voucher_dt>=@dFinyearFromDt)
  group by lm.ac_code
	      
  SET @cStep='7'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
    
  
  SET @cStep='10'      
      
     
  CREATE TABLE #tmpOb (voucherdate DATETIME,accode CHAR(10),
  debitamount NUMERIC(20,2),creditamount NUMERIC(20,2),vouchercode VARCHAR(20))    
      
  IF NOT (@nMode=3 AND @nMonthNo<>4)    
  BEGIN    
	   SET @cCmd=N'select '''+CONVERT(VARCHAR,@dFromDt,110)+''' as voucherdate,    
	   lm.ac_code as accode,sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT) as DebitAmount,
	   sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT) as CreditAmount,''ZZ1'' as vouchercode
	   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
	   JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
       join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
	   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
	   JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
       left outer join #tempDNObHd d on d.head_code=lmvd.head_code
	   where vm.voucher_dt < '''+CONVERT(VARCHAR,@dFromDt,110)+'''     
	   AND vm.cancelled=0  AND (d.head_code is null or vm.voucher_dt>='''+CONVERT(VARCHAR,@dFinyearFromDt,110)+''')       
	   group by lm.ac_code'    
       
	   PRINT @cCmd    
	   INSERT #tmpOb (voucherdate,accode,DebitAmount,CreditAmount,vouchercode)    
	   EXEC SP_EXECUTESQL @cCmd    
       
 END     
    
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
  create table #temp (cost_center_dept_id VARCHAR(4),vm_id VARCHAR(50), 
  AcCode varchar(20), voucher_no varchar(400),ref_no varchar(500), VoucherDate datetime, 
  OrderDate datetime, VoucherType varchar(150),       
  Narration varchar(max), DebitAmount numeric(20, 2), CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),UnqId int identity PRIMARY KEY,vd_id VARCHAR(150),
  vouchercode varchar(150),vs_ac_name varchar(max),x_type varchar(5))       
  --ALTER TABLE #temp ADD CONSTRAINT PK PRIMARY KEY(UnqId)    
 
      
  set @cLmCol='ac_code'
  SET @cCmd=N'select a.'+@cLmCol+' AcCode, '''+convert(varchar,@dFromDt,110)+'''
  VoucherDate, '''+convert(varchar,@dFromDt-1,110)+''' OrderDate, '''' VoucherType,
  ''Opening Balance'' as Narration, 0 as DebitAmount,0  as CreditAmount,''ZZ1'' AS vouchercode FROM  #tempLm a    
  GROUP BY a.'+@cLmCol

  print @cCmd
  insert #temp (AcCode, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vouchercode)      
  exec sp_executesql @cCmd 
  
  
  SET @cStep='12.6'      
  set @cCmd=N'select  A.'+@cLmCol+' AcCode, '''+convert(varchar,@dFromDt,110)+''' VoucherDate,
  '''+convert(varchar,@dFromDt-1,110)+''' OrderDate, '''' VoucherType, 
  ''Opening Balance'' as Narration,       
	0 as DebitAmount,0  as CreditAmount,''MEMOZZ1'' as vouchercode FROM #tempLm a    
  GROUP BY a.'+@cLmCol

  print @cCmd

  insert #temp (AcCode, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vouchercode)      
  exec sp_executesql @cCmd  
  		         
  SET @cStep='15.6'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
         
  SET @cCmd=N'Select cost_center_dept_id,vd.vm_id, lm.'+@cLmCol+' AcCode, vm.voucher_no, vm.ref_no, vm.voucher_dt VoucherDate, 
   vm.voucher_dt OrderDate, vch.VOUCHER_TYPE_ALIAS VoucherType, CCREFREMARKS Narration,sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT) debit_amount,
   sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT) credit_amount  ,
   vd.vd_id, ''ZZ1'' as vouchercode,
   x_type  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
	JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
	join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
   where vm.voucher_dt between '''+CONVERT(VARCHAR,@dFromDt,110)+''' and '''+CONVERT(VARCHAR,@dToDt,110)+'''      
   AND vm.cancelled=0 AND (d.head_code is null or vm.voucher_dt>='''+CONVERT(VARCHAR,@dFinyearFromDt,110)+''')   
   GROUP BY cost_center_dept_id,vd.vm_id, lm.'+@cLmCol+' , vm.voucher_no, vm.ref_no, vm.voucher_dt , 
   vm.voucher_dt , vch.VOUCHER_TYPE_ALIAS , CCREFREMARKS,vd.vd_id,x_type
   ORDER BY cost_center_dept_id,vm.voucher_dt,voucher_no'      
       
   PRINT @cCmd    
    
   insert #temp (cost_center_dept_id,vm_id ,AcCode, Voucher_no,ref_no,VoucherDate, OrderDate, VoucherType, Narration,
   DebitAmount, CreditAmount,vd_id,vouchercode,x_type)      
   EXEC SP_EXECUTESQL @cCmd     
      
  SET @cStep='17'      
  SET @cCmd=N'select lm.'+@cLmCol+' AcCode,'''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate,     
   '''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate,''ZZ1'' as vouchertype     ,
  ''Sub Total'' as Narration,       
   sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT) DebitAmount,      
   sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT) as CreditAmount, ''ZZ1'' as vouchercode      
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
 	JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
    join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
   JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id   
   JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
   where vm.voucher_dt BETWEEN '''+CONVERT(VARCHAR,@dFromDt,110)+''' AND '''+CONVERT(VARCHAR,@dToDt,110)+'''    
   AND (d.head_code is null or vm.voucher_dt>='''+CONVERT(VARCHAR,@dFinyearFromDt,110)+''')
   AND vm.cancelled=0
   group by lm.'+@cLmCol    
         
  --print @cCmd    
--    EXEC SP_EXECUTESQL @cCmd    

  PRINT @cCmd    
  insert #temp (AcCode, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount, VoucherCode)      
  EXEC SP_EXECUTESQL @cCmd    
      
  SET @cStep='19'      
  UPDATE a SET debitamount=b.debitamount,creditamount=b.creditamount
  FROM #temp a     
  JOIN #tmpOb b ON a.accode=b.accode and a.vouchercode=b.vouchercode       
  WHERE  Narration='Opening Balance' AND a.vm_id IS NULL     
      
  SET @cStep='21'      
      
  SET @cCmd=N'select lm.'+@cLmCol+' AcCode, '''+CONVERT(VARCHAR,@dToDt,110)+''' AS VoucherDate,'''+CONVERT(VARCHAR,@dToDt,110)+''' OrderDate, 
   ''ZZ2'' as VoucherType, ''Closing Balance'' as Narration,       
   sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT)  as DebitAmount,      
   sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT) as CreditAmount,
    ''ZZ2'' as VoucherCode
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
  	JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
    join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
	JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id    
   JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
   left outer join #tempDNObHd d on d.head_code=lmvd.head_code
   join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE      
 
   where  vm.voucher_dt<='''+CONVERT(VARCHAR,@dToDt,110)+'''  AND vm.cancelled=0
   AND (d.head_code is null or vm.voucher_dt>='''+CONVERT(VARCHAR,@dFinyearFromDt,110)+''') group by lm.'+@cLmCol    
   
   print @cCmd    
   insert #temp (AcCode, VoucherDate, OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vouchercode)      
   EXEC SP_EXECUTESQL @cCmd    
    
  SET @cStep='24'      
    
  insert #temp (AcCode, VoucherDate,OrderDate, VoucherType, Narration, DebitAmount, CreditAmount,vouchercode)    
  SELECT a.AcCode,@dToDt as VoucherDate,a.OrderDate,a.VoucherType,'Closing Balance' AS Narration,    
  a.creditamount as DebitAmount,a.debitamount as CreditAmount,replace(a.vouchercode,'zz1','zz2')   
  FROM #temp a LEFT OUTER JOIN     
  (SELECT accode,vouchercode FROM #temp WHERE narration='Closing Balance' ) b ON a.accode=b.accode  
  and  replace(a.vouchercode,'zz1','zz2')= b.vouchercode  
  WHERE a.narration='Closing Balance' AND  b.accode IS NULL    
  
  SET @cStep='27'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)       
  CREATE INDEX ind_accode ON #temp (ACCODE)      
       
  SET @cStep='30'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
       
      
  SET @cStep='35'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)      
  
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
	
	  

	  SET @cStep='41.4'            
	  UPDATE a SET DebitAmount=b.DebitAmount,a.CreditAmount=b.CreditAmount
	  FROM #temp1  a    
	  JOIN    
	  (    
	   SELECT AcCode,vouchercode,SUM(DEBITAMOUNT) AS DEBITAMOUNT ,SUM(CREDITAMOUNT) AS CREDITAMOUNT
	   from #temp1     
	   WHERE VoucherType NOT IN ('ZZ1','ZZ2') AND AcCode=@cAcCode and vouchercode=@cVchcode    
	   GROUP BY AcCode,vouchercode
	  )b ON b.AcCode=a.AcCode  and a.vouchercode=b.vouchercode   
	  WHERE a.VoucherType='ZZ1' AND a.AcCode=@cAcCode and a.vouchercode=@cVchcode   
      
	  SET @cStep='41.6'      
	 print 'Update rows of closing :'+@cvchcode
	  UPDATE a SET DebitAmount=ABS(case when b.amount<0 then b.amount else 0 end) ,      
	  CreditAmount  =ABS(case when b.amount>0 then b.amount else 0 end)
	  FROM #temp1  a    
	  JOIN    
	  (    
	   SELECT AcCode,vouchercode,isnull(DEBITAMOUNT,0)-isnull(cREDITAMOUNT,0) AS AMOUNT     
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
       
  select cost_center_dept_id,vm_id,COST_CENTER_NAME ac_name, AcCode,    
  VoucherDate, OrderDate, Vouchertype, Narration, DebitAmount, CreditAmount, UnqId,      
  case when runningtotal >= 0 then convert(varchar, RunningTotal)+' Dr' else convert(varchar, abs(RunningTotal))+' Cr' end runningTotal
  ,COST_CENTER_NAME AS DISPLAY_ac_name,
  CONVERT(VARCHAR(20) ,VoucherDate,106) AS   DISPLAY_VoucherDate,CONVERT(BIT,0) AS group_ledger,
  case when ISNULL(DebitAmount,0) > 0 then 'Dr' when ISNULL(CreditAmount,0) > 0 THEN 'Cr' else '' end XN_TYPE,
  vouchercode,accode as ac_code,vs_ac_name,voucher_no,ref_no       
  into #temp2      
  from #temp1 a      
  JOIN COST_CENTER_MST b (NOLOCK) ON a.AcCode=b.COST_CENTER_CODE      
  order by UnqId      
  

  
  --FOR vs_ac_name ---
     

	DECLARE @VM_ID VARCHAR(1000), @VSACNAMES VARCHAR(MAX)

    DECLARE @t TABLE(UnqId VARCHAR(50), AC_NAME VARCHAR(500), VSACNAMES VARCHAR(MAX), Amount numeric(14,2));
 
  SET @cStep='42.8'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     

	
  
  --END VS ACNAME       

  SET @cStep='48'      
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113)     
    
  UPDATE #temp2 SET DebitAmount=NULL WHERE DebitAmount=0     
  UPDATE #temp2 SET CreditAmount=NULL WHERE CreditAmount=0    
  
  SET @cStep='49'      
  
IF EXISTS (SELECT TOP 1 a.* FROM #tmpcb a JOIN 
			(select ac_code,vouchercode,sum(isnull(creditamount,0)-isnull(debitamount,0)) as balance
			from #temp2 where narration='closing balance'  group by ac_code,vouchercode) b  ON
			a.ac_code=b.ac_code and a.vouchercode=b.vouchercode
			where abs(a.balance-b.balance)>10
		) 
begin
			
	DECLARE @nStored numeric(20,2),@nCalculated numeric(20,2),@cmismatchAc varchar(400)
	SELECT TOP 1 @nStored=a.balance,@nCalculated=b.balance,@cmismatchAc=c.COST_CENTER_NAME

			FROM #tmpcb a 
			JOIN (select ac_code,vouchercode,sum(isnull(creditamount,0)-isnull(debitamount,0)) as balance
			from #temp2 where narration='closing balance'  group by ac_code,vouchercode) b  ON a.ac_code=b.ac_code
			and a.vouchercode=b.vouchercode
			join COST_CENTER_MST c (NOLOCK) ON c.COST_CENTER_CODE=a.ac_code
			where round(a.balance,2)<>round(b.balance,2)
	set @cErrormsg='Mismatch in Closing balance of Ledger :'+@cmismatchAc+' Calculated:'+ltrim(rtrim(str(@nCalculated,20,2)))+'
					Stored:'+ltrim(rtrim(str(@nStored,20,2)))+'...Please contact SoftInfo'
	goto end_proc
end
  
  
  

  SET @cStep='49.5'          
  PRINT 'Step#'+@cStep+':'+convert(varchar,getdate(),113) 
    --select @nMode
	
	select @nMode AS A,cost_center_dept_id,a.vm_id,unqid,a.ac_name,AcCode,
	voucherDate,VoucherType, Narration, DebitAmount, CreditAmount, runningTotal,
	DISPLAY_ac_name,display_VoucherDate,group_ledger ,XN_TYPE,    
	VS_AC_NAME as DISPLAY_VS_AC_NAME,vouchercode,voucher_no,ref_no 
	from #temp2 a  
	order by ac_name,voucherdate,unqid  
 

  goto end_proc      
    
lblMonthly:    
      
  SET @cStep='52'    
     
   CREATE TABLE #tempMonthList (year_no numeric(4,0),month_no numeric(2,0),from_dt datetime,to_dt datetime)    
    
   INSERT #tempMonthList (year_no,month_no,from_dt,to_dt)    
   select year_no,month_no,from_dt,to_dt from dbo.FN_ACT_MONTHLIST(@dFromDt ,@dToDt)    
    
    
  create table #tempMonthly (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2),     
  CreditAmount numeric(20, 2),RurnningTotal NUMERIC(20,2))       
    
  create table #tempMonthlyFinal (AcCode varchar(20),month_name VARCHAR(30),month_no NUMERIC(2,0),year_no numeric(4,0),DebitAmount numeric(20, 2),     
  CreditAmount numeric(20, 2),RunningTotal NUMERIC(20,2),unq_id INT IDENTITY)       
      
  insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)    
  select AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,DebitAmount, CreditAmount FROM #tmpOb    
      
    
  SET @cStep='50'    
      
  --insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)    
  --SELECT @cCostCenterCodePara AS AcCode,'Opening Balance' as month_name,0 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount    
    
  SET @cStep='55'    
  insert #tempMonthly (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount)    
  SELECT @cCostCenterCodePara AS AcCode,    
  DateName(mm,DATEADD(mm,Number,0)) as month_name,number+1 as MONTH_NO,0 as YEAR_NO,0 as DebitAmount,0 as CreditAmount
  FROM master..spt_values where number between 0 and 11 and type='p'    
    
    
  SET @cStep='58'    
  UPDATE a SET YEAR_NO=B.YEAR_NO,DebitAmount=b.debitamount,CreditAmount=b.creditamount FROM #tempMonthly a    
  JOIN (    
  select MONTH(vm.voucher_dt) as month_no,YEAR(vm.voucher_dt) as year_no,    
  sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT)  as CreditAmount,      
  sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT) as DebitAmount
  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
  JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
  join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
    JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
  JOIN #locListC l ON l.dept_id=vd.cost_center_dept_id  
 
  where vm.voucher_dt between @dFromDt AND @dToDt AND cancelled=0      
  AND (d.head_code is null or vm.voucher_dt>=@dFinyearFromDt)
  and VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')      
  group by MONTH(vm.voucher_dt),YEAR(vm.voucher_dt)    
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
   select @cCostCenterCodePara AcCode,'Sub Total' month_name,13 month_no,year(@dToDt) year_no,    
   SUM(DebitAmount)  as  DebitAmount  ,    
   SUM(CreditAmount)  as CreditAmount,      
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempMonthlyFinal     
    
    
   SET @cStep='62'    
      insert #tempMonthlyFinal (AcCode,month_name,MONTH_NO,YEAR_NO,DebitAmount, CreditAmount,RunningTotal)      
   select @cCostCenterCodePara AcCode,'Closing Balance' month_name,13 month_no,year(@dToDt) year_no,    
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
  
    
  SELECT @cCostCenterCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,    
  LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal,'' as from_Dt,'' as to_dt,unq_id     
  FROM #tempMonthlyFinal a    
  WHERE month_name IN ('Opening Balance','Closing Balance','Sub Total')    
  UNION ALL    
  SELECT @cCostCenterCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,    
  LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal,b.from_Dt,b.to_dt,unq_id FROM #tempMonthlyFinal a    
  JOIN #tempMonthList b ON a.year_no=b.year_no AND a.month_no=b.month_no    
  ORDER BY unq_id    
    

	IF EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='LEDGER_MONTHLY_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0)
  		DROP TABLE LEDGER_MONTHLY_CURSOR

	IF  OBJECT_ID('LEDGER_MONTHLY_CURSOR','U') IS NULL	
	BEGIN
		SELECT @cCostCenterCodePara as AcCode,a.month_name,a.MONTH_NO,a.YEAR_NO,a.DebitAmount as debitamount,a.CreditAmount as creditamount,      
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
 SELECT @cCostCenterCodePara Accode,DATEADD(DD,number,@dFromdt-1) as XN_DT,0 as DebitAmount,0 as CreditAmount    
 FROM master..spt_values where number between 0 and 367 and type='p'    
 AND DATEADD(DD,number,@dFromdt)<=@dToDt+1    
    
 SET @cStep='90'    
  UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount     
  FROM #tempDaily a    
   JOIN (    
   select @dFromDt-1 as voucher_dt,sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT)  as CreditAmount,
   sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT)  as DebitAmount 
     
   from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
   	JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
	join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
       JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
 
   where vm.voucher_dt<@dFromDt AND cancelled=0  
   AND (d.head_code is null or vm.voucher_dt>=@dFinyearFromDt)
   ) b ON a.voucher_dt=b.voucher_dt    
    
     
 SET @cStep='90'    
 UPDATE a SET DebitAmount=b.debitamount,CreditAmount=b.creditamount 
 FROM #tempDaily a    
  JOIN (    
  select vm.voucher_dt as voucher_dt,sum((case when debit_amount>0 then 0 else 1 end)*cc.CCREFAMOUNT)  as CreditAmount,
  sum((case when debit_amount>0 then 1 else 0 end)*cc.CCREFAMOUNT)  as DebitAmount 
  from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID      
  JOIN COSTCENTERREF cc (NOLOCK) ON cc.CCREFVDID=vd.VD_ID
  join #templm lm ON lm.ac_code=cc.CCREFCOSTCENTERCODE
    JOIN lm01106 lmvd (NOLOCK) ON lmvd.AC_CODE=vd.AC_CODE
  left outer join #tempDNObHd d on d.head_code=lmvd.head_code
 
   where vm.voucher_dt between @dFromDt AND @dToDt AND cancelled=0      
   AND (d.head_code is null or vm.voucher_dt>=@dFinyearFromDt)
  group by vm.voucher_dt    
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
   select @cCostCenterCodePara AcCode,'Sub Total' voucher_dt,    
   sum(DEBITAMOUNT)  as DebitAmount,      
   sum(CREDITAMOUNT) as CreditAmount  ,         
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempDailyFinal    
    
   SET @cStep='102'    
   insert #tempDailyFinal (AcCode,display_voucherdate,DebitAmount, CreditAmount,RunningTotal)      
   select @cCostCenterCodePara AcCode,'Closing Balance' display_voucherdate,    
   case when sum(debitamount-creditamount)<0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end  as DebitAmount,      
   case when  sum(debitamount-creditamount)>=0 then abs(sum(DEBITAMOUNT - CREDITAMOUNT)) else 0 end as CreditAmount  ,         
   SUM(DebitAmount-CreditAmount) as runningtotal    
   from #tempDailyFinal     
    WHERE 'Sub Total' <>display_voucherdate    
	

         
  update #tempDailyFinal SET DebitAmount=NULL WHERE ISNULL(DebitAmount,0)=0    
  update #tempDailyFinal SET CreditAmount=NULL WHERE ISNULL(CreditAmount,0)=0    
    
  SET @cStep='110'    
  SELECT AcCode,voucher_dt,display_voucherdate,DebitAmount, CreditAmount,LTRIM(RTRIM(STR(ABS(runningtotal),14,2)))+' '+    
  (CASE WHEN RunningTotal>0 THEN 'Dr' ELSE 'Cr' END) as runningtotal, INTEREST
  FROM #tempDailyFinal 
  ORDER BY unq_id    
    
  goto end_proc    
    
END TRY       
      
BEGIN CATCH      
 SET @cErrormsg='Error in Procedure SPACT_COSTCENTER_LEDGER at Step#'+@cStep+':'+ERROR_MESSAGE()      
 goto end_proc      
END CATCH      
      
end_proc:      
 IF ISNULL(@cErrormsg,'')<>''      
  select ISNULL(@cErrormsg,'') as errmsg      
END      
---End Multi Ledger----------------------------------- 