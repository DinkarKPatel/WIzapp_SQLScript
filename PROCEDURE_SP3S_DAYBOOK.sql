CREATE PROCEDURE SP3S_DAYBOOK--(LocId 3 digit change by Sanjay:05-11-2024)
@nMode NUMERIC(1,0), --- 1.Day Book 2. Journal Book 3.Cash Book 4. Cash cum Journal Book,5. Bank Book
@dFromDt DATETIME,
@dToDt DATETIME,
@nSpId VARCHAR(50)='' 
as
BEGIN
	  declare @cCashHeads VARCHAR(2000),@cFinyear VARCHAR(5),@dFinyearFromDt DATETIME,@cBankHeads VARCHAR(MAX),
			  @cStep VARCHAR(4),@cErrormsg VARCHAR(MAX)

BEGIN TRY
	  SET @cErrormsg	=''

	  SET @cStep='10'
	  SELECT @cCashHeads= DBO.FN_ACT_TRAVTREE('0000000014'),@cBankHeads= DBO.FN_ACT_TRAVTREE('0000000013')       

	  
	  SELECT head_code INTO #tempCashHd FROM hd01106 WHERE CHARINDEX(head_code,@cCashHeads)>0    
	  SELECT head_code INTO #tempBankHd FROM hd01106 WHERE CHARINDEX(head_code,@cBankHeads)>0    

	  CREATE TABLE #locListC (dept_id VARCHAR(4))    
	  
	  SET @cStep='20'
	  
	  CREATE TABLE #tVchTypes (voucher_code char(10))

	 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
		  INSERT #locListC    
		  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
	 ELSE    
		  INSERT #locListC    
		  SELECT DEPT_ID FROM LOCATION WHERE DEPT_ID=MAJOR_DEPT_ID AND (loc_type=1 OR ISNULL(Account_posting_at_ho,0)=1)    
	  
	  SET @cStep='30'
	  IF @nMode IN (3,5)
	  BEGIN

		  SELECT DISTINCT a.ac_code AS rep_ac_code INTO #tempLm 
		  FROM lm01106 a (NOLOCK) WHERE 1=2   
		  
		  SET @cStep='40'
		  IF @nMode=3
			  INSERT #tempLm  	
			  SELECT DISTINCT a.ac_code AS rep_ac_code
			  FROM lm01106 a (NOLOCK)     
			  JOIN #tempCashHd b ON b.HEAD_CODE=a.HEAD_CODE  
		  ELSE
			  INSERT #tempLm  	
			  SELECT DISTINCT a.ac_code AS rep_ac_code
			  FROM lm01106 a (NOLOCK)     
			  JOIN #tempBankHd b ON b.HEAD_CODE=a.HEAD_CODE  		  		
		  
		  

		  SET @cStep='50'
		  SELECT sum(debit_amount-credit_amount) as opening_balance
		  into #tmpOb from vd01106 a (NOLOCK)
		  JOIN vm01106 b (NOLOCK) on b.vm_id=a.vm_id 
		  join #templm c ON c.rep_ac_code=a.ac_code
		  join lm01106 lm (nolock) on lm.ac_code=a.ac_code
		  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id  
		  where  voucher_dt<@dFromDt  AND cancelled=0

		  delete from #tmpob where opening_balance is null
	  END	

	  SET @cStep='60'
	  SELECT DISTINCT a.vm_id 
	  INTO #tmpcjVm 
	  FROM vd01106 a (NOLOCK) 
		  JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
		  JOIN lm01106 d (NOLOCK) ON d.ac_code=a.ac_code
		  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id 
		  LEFT JOIN #tempCashHd e ON e.HEAD_CODE=d.HEAD_CODE
		  LEFT JOIN #tempBankHd f ON f.HEAD_CODE=d.HEAD_CODE
		  WHERE (voucher_dt BETWEEN @dFromdt AND @dToDt )
		  AND cancelled=0
		  AND  (@nMode=1 OR  
				(@nMode=2 AND b.voucher_code='0000000001')  OR
			   (@nMode=3 AND e.HEAD_CODE IS NOT NULL) OR
			   (@nMode=5 AND f.HEAD_CODE IS NOT NULL ) OR
			   (@nMode=4 AND (b.voucher_code='0000000001' OR e.HEAD_CODE IS NOT NULL)))
		
		--select * from #locListC
		--SELECT * FROM #tmpcjVm
		SET @cStep='70'
		  SELECT b.vm_id,convert(varchar,voucher_dt,105) voucher_dt,voucher_no,voucher_type,voucher_type as bk_voucher_type,
		  a.ac_code dr_ac_code,ac_name as dr_ac_name,debit_amount,a.narration as dr_narration,
		  convert(CHAR(10),'') cr_ac_code,convert(varchar(500),'') as cr_ac_name,convert(numeric(14,2),0) credit_amount,
		  convert(varchar(500),'')  as cr_narration,convert(varchar(40),newid()) as row_id,convert(varchar(40),'') ref_row_id,
		  convert(numeric(5,0),0) dr_count,convert(numeric(5,0),0) cr_count,convert(numeric(10,0),0) rowno,convert(numeric(10,0),0) vd_rowno,
		  2 as entry_mode,head_code,voucher_dt as bk_voucher_dt,voucher_no bk_voucher_no
		  INTO #tmpDaybook from vd01106 a (NOLOCK) 
		  JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
		  JOIN vchtype c (NOLOCK) ON c.voucher_code=b.voucher_code
		  JOIN lm01106 d (NOLOCK) ON d.ac_code=a.ac_code
		  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id
		  JOIN #tmpcjVm e ON e.vm_id=a.vm_id
		  WHERE debit_amount<>0 AND ISNULL(a.autoentry,0)=0

		  UNION ALL
		  SELECT b.vm_id,convert(varchar,voucher_dt,105) voucher_dt,voucher_no,voucher_type,voucher_type as bk_voucher_type,
		  '' AS dr_ac_code,convert(varchar(500),'') as dr_ac_name,convert(numeric(14,2),0) debit_amount,
		  convert(varchar(500),'')  as dr_narration,a.ac_code as cr_ac_code, ac_name as cr_ac_name,credit_amount,
		  a.narration as cr_narration,convert(varchar(40),newid()) as row_id,convert(varchar(40),'') ref_row_id,
		  convert(numeric(2,0),0) dr_count,convert(numeric(2,0),0) cr_count,convert(numeric(10,0),0) rowno,convert(numeric(10,0),0) vd_rowno,
		  2 as entry_mode,head_code,voucher_dt as bk_voucher_dt,voucher_no bk_voucher_no
		  from vd01106 a (NOLOCK) 
		  JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
		  JOIN vchtype c (NOLOCK) ON c.voucher_code=b.voucher_code
		  JOIN lm01106 d (NOLOCK) ON d.ac_code=a.ac_code
		  JOIN #locListC l ON l.dept_id=a.cost_center_dept_id
		  JOIN #tmpcjVm e ON e.vm_id=a.vm_id
		  WHERE credit_amount<>0 AND ISNULL(a.autoentry,0)=0

		  SET @cStep='80'
		  UPDATE a SET dr_count=b.dr_count,cr_count=b.cr_count FROM #tmpDaybook a
		  JOIN (SELECT VM_ID,SUM(CASE WHEN debit_amount<>0 THEN 1 ELSE 0 END) dr_count,
				SUM(CASE WHEN credit_amount<>0 THEN 1 ELSE 0 END) cr_count FROM #tmpDaybook
				GROUP BY vm_id) b ON a.vm_id=b.vm_id
		  
		  SET @cStep='90'
		 -- select * INTO #tmpDaybookDup from #tmpDaybook

		  ;WITH cteDb
		  as
		  (SELECT *,ROW_NUMBER() OVER (partition by voucher_dt,voucher_no order by debit_amount) rno
				    FROM #tmpDaybook
		   WHERE cr_count>=dr_count)


--		  select * from ctedb

  		  UPDATE a SET dr_ac_code=b.dr_ac_code, dr_ac_name=b.dr_ac_name,debit_amount=b.debit_amount,dr_narration=b.dr_narration,
		  ref_row_id=b.row_id FROM cteDb a JOIN cteDb b ON a.vm_id=b.vm_id
		  WHERE a.dr_ac_name='' AND b.dr_ac_name<>'' AND b.rno=a.rno+a.cr_count


		  SET @cStep='100'
		 -- SELECT 'check after updating',* FROM #tmpDaybook where vm_id='01AA3E6F04-E89F-46CC-90C4-1270B4CC318E'

		  ;WITH cteDb
		  as
		  (SELECT *,ROW_NUMBER() OVER (partition by voucher_dt,voucher_no order by credit_amount) rno FROM #tmpDaybook
		   WHERE dr_count>cr_count)
		  
		  --select * from ctedb

		  UPDATE a SET cr_ac_code=b.cr_ac_code,cr_ac_name=b.cr_ac_name,credit_amount=b.credit_amount,cr_narration=b.cr_narration,
		  ref_row_id=b.row_id FROM cteDb a JOIN cteDb b ON a.vm_id=b.vm_id
		  LEFT OUTER JOIN ctedb c ON c.ref_row_id=b.row_id
		  WHERE a.cr_ac_name='' AND b.cr_ac_name<>'' AND b.rno=a.rno+a.dr_count AND b.ref_row_id=''
		  AND c.row_id IS NULL  and b.DEBIT_AMOUNT=0

		  SET @cStep='110'
		  --select 'check before deletion',* from  #tmpDaybook where vm_id='005752E4F0-B950-49EC-B4A8-7459427012EF'

		  DELETE a FROM #tmpDaybook a JOIN #tmpDaybook b ON a.row_id=b.ref_row_id AND a.vm_id=b.vm_id

		  UPDATE #tmpDaybook SET bk_voucher_no=voucher_no

		  SET @cStep='120'
		  ;WITH cteDb
		   as
		   (SELECT row_id,DENSE_RANK() OVER (order by bk_voucher_dt,voucher_no) rno,
					     ROW_NUMBER() OVER (partition by vm_id order by vm_id,ref_row_id desc) vd_rno
					FROM #tmpDaybook)
			  
		  UPDATE a SET rowno=b.rno,vd_rowno=b.vd_rno FROM #tmpDaybook a JOIN ctedb b ON a.row_id=b.row_id  	

		  SET @cStep='130'
		  UPDATE a SET voucher_no='',voucher_type='',voucher_dt='' FROM #tmpDaybook a
		  WHERE vd_rowno<>(select top 1 vd_rowno FROM #tmpDaybook b WHERE b.vm_id=a.vm_id order by b.vd_rowno)
		  
		  IF @nMode NOT IN (3,5)
			 GOTO LBLLAST

		  
		  SET @cStep='140'	
		  IF EXISTS (SELECT TOP 1 * FROM #tmpOb)
			  INSERT INTO #tmpDayBook (dr_ac_code,cr_ac_code,head_code,voucher_type,bk_voucher_type,vm_id,voucher_no,
			  bk_voucher_no,voucher_dt,bk_voucher_dt,debit_amount,credit_amount,entry_mode,rowno)
			  SELECT '0000000001' dr_ac_code,'0000000001' cr_ac_code,'0000000014' head_code,
			  'Opening Balance' voucher_type,'Opening Balance' bk_voucher_type,'Opening' vm_id,'Opening' voucher_no,'Opening' bk_voucher_no,convert(varchar,@dFromDt,105) voucher_dt,
			  @dFromDt bk_voucher_dt,(CASE WHEN opening_balance>0 THEN opening_balance ELSE 0 END) DEBIT_AMOUNT,
			  (CASE WHEN opening_balance<0 THEN abs(opening_balance) ELSE 0 END) CREDIT_AMOUNT,1 entry_mode,1 rowno
			  FROM #tmpOb
		  ELSE
			  INSERT INTO #tmpDayBook (dr_ac_code,cr_ac_code,head_code,voucher_type,bk_voucher_type,vm_id,voucher_no,
			  bk_voucher_no,voucher_dt,bk_voucher_dt,debit_amount,credit_amount,entry_mode,rowno)
			  SELECT '0000000001' dr_ac_code,'0000000001' cr_ac_code, '0000000014' head_code,
			  'Opening Balance' voucher_type,'Opening Balance' bk_voucher_type,'Opening' vm_id,'Opening' voucher_no,'Opening' bk_voucher_no,
			  convert(varchar,@dFromDt,105) voucher_dt,@dFromDt voucher_dt,0 DEBIT_AMOUNT,0 CREDIT_AMOUNT,
			  1 entry_mode,1 rowno
		  
		  SET @cStep='150'	
		  INSERT INTO #tmpDayBook (dr_ac_code,cr_ac_code,head_code,vm_id,voucher_no,bk_voucher_no,
		  voucher_type,bk_voucher_type,
		  voucher_dt,bk_voucher_dt,debit_amount,credit_amount, entry_mode,rowno)
		  SELECT distinct '0000000001' dr_ac_code,'0000000001' cr_ac_code, '0000000014' head_code,
		  'Closing' vm_id,'' voucher_no,'Closing' bk_voucher_no,'Closing Balance' voucher_type,'Closing Balance' bk_voucher_type,'' voucher_dt,
		  bk_voucher_dt,0 DEBIT_AMOUNT,0 CREDIT_AMOUNT,3 entry_mode ,1 rowno
		  FROM #tmpDayBook WHERE vm_id<>'Opening'
		    
		  SET @cStep='160'
		  PRINT 'Update closing balances'
		  IF @nMode=3
			  UPDATE a SET debit_amount=(select sum((CASE WHEN hd_dr.head_code IS NOT NULL
			  THEN ISNULL(debit_amount,0) ELSE 0 END)-(CASE WHEN hd_cr.head_code IS NOT NULL 
			  THEN  isnull(credit_amount,0) ELSE 0 END)) 
			  from #tmpDayBook b
			  LEFT JOIN lm01106 lm_dr (NOLOCK) ON lm_dr.ac_code=b.dr_ac_code
			  LEFT JOIN #tempCashHd hd_dr ON hd_dr.HEAD_CODE=lm_dr.HEAD_CODE
			  LEFT JOIN lm01106 lm_cr (NOLOCK) ON lm_cr.ac_code=b.cr_ac_code
			  LEFT JOIN #tempCashHd hd_cr ON hd_cr.HEAD_CODE=lm_cr.HEAD_CODE
			  where b.bk_voucher_dt<=a.bk_voucher_dt)
			  FROM #tmpDayBook a  WHERE entry_mode=3
		  ELSE
			  UPDATE a SET debit_amount=(select sum((CASE WHEN hd_dr.head_code IS NOT NULL
			  THEN ISNULL(debit_amount,0) ELSE 0 END)-(CASE WHEN hd_cr.head_code IS NOT NULL 
			  THEN  isnull(credit_amount,0) ELSE 0 END)) 
			  from #tmpDayBook b
			  LEFT JOIN lm01106 lm_dr (NOLOCK) ON lm_dr.ac_code=b.dr_ac_code
			  LEFT JOIN #tempBankHd hd_dr ON hd_dr.HEAD_CODE=lm_dr.HEAD_CODE
			  LEFT JOIN lm01106 lm_cr (NOLOCK) ON lm_cr.ac_code=b.cr_ac_code
			  LEFT JOIN #tempBankHd hd_cr ON hd_cr.HEAD_CODE=lm_cr.HEAD_CODE
			  where b.bk_voucher_dt<=a.bk_voucher_dt)
			  FROM #tmpDayBook a  WHERE entry_mode=3

		  SET @cStep='170'
		  UPDATE #tmpDayBook SET debit_amount=0,credit_amount=abs(debit_amount) where entry_mode IN (1,3)
		  AND debit_amount<0
		  		  
LBLLAST:
	
	SET @cStep='180'
	UPDATE #tmpDayBook SET debit_amount=null where debit_amount=0
	UPDATE #tmpDayBook SET credit_amount=null where credit_amount=0

	SET @cStep='190'
	SELECT * FROM #tmpDaybook --where vm_id='005752E4F0-B950-49EC-B4A8-7459427012EF'
	ORDER BY bk_voucher_dt,entry_mode,bk_voucher_type,bk_voucher_no,vm_id,vd_rowno
	
	SET @cStep='200'
	IF (EXISTS(SELECT DATEDIFF(d,create_date,getdate()-2),* FROM SYS.TABLES WHERE NAME ='DAYBOOK_CURSOR' AND DATEDIFF(d,create_date,getdate())<>0))
	  	DROP TABLE DAYBOOK_CURSOR

	IF  OBJECT_ID('DAYBOOK_CURSOR','U') IS NULL	
	BEGIN
	  SELECT * INTO DAYBOOK_CURSOR  FROM #tmpDaybook  WHERE 1=2
	END

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_DAYBOOK at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:		  		  
	IF ISNULL(@cErrormsg,'')<>''
		SELECT @cErrormsg AS errmsg
END	
