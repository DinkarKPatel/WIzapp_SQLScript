CREATE PROCEDURE SP3S_ACT_FINANCIAL_SMRY--(LocId 3 digit change by Sanjay:04-11-2024)
@cFinYear VARCHAR(10),
@cLocId VARCHAR(4)='',
@cCompanyPanNo VARCHAR(50)='',
@nSpId VARCHAR(50)=''
AS
BEGIN
	DECLARE @tHeads TABLE (head_code CHAR(10),major_head_code CHAR(10),major_head_name VARCHAR(200))

	DECLARE @cCmd NVARCHAR(MAX),@nMonth INT,@dFromDt DATETIME,@dToDt DATETIME,@dXnDt DATETIME,@cPmtOpsTable VARCHAR(100),@cMonthStr VARCHAR(200),
	@cErrormsg VARCHAR(MAX),@cPmtCbsTable VARCHAR(100),@nObp NUMERIC(20,2),@nCbp NUMERIC(20,2),@cHoLocId VARCHAR(4),@nStep VARCHAR(10),
	@cMonthCols VARCHAR(500),@cMajorHeadname VARCHAR(200),@cCurFinYear VARCHAR(10),@nProcessmonth int

BEGIN TRY
	SET @nStep='10'
	SET @cErrormsg=''
	SELECT TOP 1 @cHoLocId=value FROM config (NOLOCK) WHERE config_option='location_id'
	SELECT @dFromDt=dbo.FN_GETFINYEARDATE(@cFinYear,1),@dToDt=dbo.FN_GETFINYEARDATE(@cFinYear,2)

	set @cCurFinYear='01'+dbo.fn_getfinyear(getdate())


	--select @cCurFinYear,@dFromdt,@dToDt
	--0000000010,0000000013,0000000014,0000000029,0000000026,0000000027,0000000003,0000000004,0000000002,0000000007

	SET @cCmd=N'
		SELECT head_code,''0000000014'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000014')+')  
		UNION

		SELECT head_code,''0000000013'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000013')+')  
		UNION   
		SELECT head_code,''0000000030'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000030')+')  
		UNION   
		SELECT head_code,''0000000026'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000026')+')  
		UNION   
		SELECT head_code,''0000000029'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000029')+')
		UNION   
		SELECT head_code,''0000000027'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000027')+')
		UNION   
		SELECT head_code,''0000000003'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000003')+')
		UNION   
		SELECT head_code,''0000000004'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000004')+')
		UNION   
		SELECT head_code,''0000000002'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000002')+')
		UNION   
		SELECT head_code,''0000000007'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000007')+')
		UNION   
		SELECT head_code,''0000000018'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000018')+')
		UNION   
		SELECT head_code,''0000000021'' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree('0000000021')+')'
		
		
	
	INSERT @tHeads (head_code,major_head_code)
	EXEC SP_EXECUTESQL @cCmd  
	

	update a set major_head_name=b.head_name from @tHeads a
	join hd01106 b on a.major_head_code=b.HEAD_CODE

	SET @nStep='20'
	DECLARE @cFsHeadCode VARCHAR(10),@cChildHeadCode CHAR(10)

	SELECT child_head_code,b.fs_head_code,b.FS_HEAD_NAME major_head_name INTO #tmpFsMiscHeads FROM fs_heads_config_det a
	JOIN fs_heads_config_mst b on a.fs_head_code=b.fs_head_code
	
	WHILE EXISTS (SELECT TOP 1 * FROM #tmpFsMiscHeads)
	BEGIN
		SELECT TOP 1 @cFsHeadCode=fs_head_code,@cChildHeadCode=child_head_code,@cMajorHeadname=major_head_name FROM #tmpFsMiscHeads

		SET @nStep='30'
		SET @cCmd=N'SELECT head_code,'''+@cFsHeadCode+''','''+@cMajorHeadname+''' FROM hd01106 WHERE head_code IN ('+dbo.fn_act_travtree(@cChildHeadCode)+')'

		INSERT @tHeads (head_code,major_head_code,major_head_name)
		EXEC SP_EXECUTESQL @cCmd  

		DELETE FROM #tmpFsMiscHeads WHERE child_head_code=@cChildHeadCode
	END

	SELECT dept_id INTO #locListFS FROM location a (NOLOCK) WHERE 1=2

	 IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId AND dept_id<>'')    
		  INSERT #locListFS    
		  SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @nSpId    
	 ELSE    
		  INSERT #locListFS    
		  SELECT DEPT_ID FROM LOCATION WHERE LOC_TYPE=1 AND PAN_NO=@cCompanyPanNo

	DELETE FROM act_filter_loc where sp_id=ltrim(rtrim(str(@@spid)))

	insert into act_filter_loc (sp_id,dept_id)
	select @@spid,dept_id from #locListFS

	--select 'fs001', * from @theads where major_head_code='fs001'

	SET @nStep='40'
	CREATE TABLE #tReportBaseData (xn_month VARCHAR(20),major_head_code CHAR(10),head_code CHAR(10),head_name VARCHAR(200),
	major_head_name VARCHAR(200),amount NUMERIC(14,2),mode NUMERIC(1,0),month_no INT )
	
	CREATE TABLE  #tReport (xn_month VARCHAR(20),head_name VARCHAR(200),amount NUMERIC(20,2),srno NUMERIC(2,0),cashflowMode INT
	,balanceentry BIT,month_no INT,obscbs_Amount NUMERIC(14,2))


	SET @nStep='50'
	SELECT DISTINCT a.vm_id INTO #tmpDirectIncomes FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN POSTACT_VOUCHER_LINK v (NOLOCK) ON v.vm_id=b.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	LEFT JOIN inm01106 inm (NOLOCK) ON inm.inv_id=v.MEMO_ID
	LEFT JOIN location sloc (NOLOCK) ON sloc.dept_id=inm.location_Code
	LEFT JOIN location Tloc (NOLOCK) ON Tloc.dept_id=INM.party_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND B.cancelled=0
	AND (bill_type IN ('SLS') OR (bill_type='WSLCHO' AND (sloc.dept_id=@cHoLocId OR sloc.pur_loc=1)))

	SELECT DISTINCT a.vm_id INTO #tmpSDCredit FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	LEFT JOIN #tmpDirectIncomes di oN di.vm_id=a.vm_id
	WHERE voucher_dt BETWEEN @DfROMdT and @dToDt AND cancelled=0
	AND th.major_head_code='0000000018' AND cancelled=0 AND di.vm_id IS NULL
	
	SELECT DISTINCT a.vm_id INTO #tmpCapInv FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @DfROMdT and @dToDt AND cancelled=0
	AND th.major_head_code IN ('0000000016','0000000002') AND a.CREDIT_AMOUNT<>0

	SELECT DISTINCT a.vm_id INTO #tmpOthInf FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	LEFT JOIN #tmpDirectIncomes di oN di.vm_id=a.vm_id
	LEFT JOIN #tmpSDCredit sd oN sd.vm_id=a.vm_id
	LEFT JOIN #tmpCapInv ca on ca.vm_id=a.vm_id
	WHERE voucher_dt BETWEEN @DfROMdT and @dToDt AND cancelled=0
	AND th.major_head_code IN ('0000000013','0000000014') AND cancelled=0 AND di.vm_id IS NULL and sd.vm_id IS NULL AND ca.vm_id IS NULL
	AND a.debit_amount<>0


	SELECT DISTINCT a.vm_id INTO #tmpExpPaid FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @DfROMdT and @dToDt AND cancelled=0
	AND th.major_head_code IN ('0000000027','FS002')

	
	

	SET @nStep='60'
	SELECT DISTINCT a.vm_id INTO #tmpIndirectIncome FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt <=@dToDt AND cancelled=0
	AND th.major_head_code IN ('FS001') AND cancelled=0
	AND a.debit_AMOUNT<>0

	SET @nStep='70'
	SELECT DISTINCT a.vm_id INTO #tmpTVCPayments FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt between @dFromdt and @dToDt AND cancelled=0
	AND th.major_head_code IN ('FS004','FS005') AND cancelled=0
	AND a.debit_AMOUNT<>0

	SET @nStep='80'
	SELECT DISTINCT a.vm_id INTO #tmpCapitalExpPayments FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	LEFT JOIN (select head_code from  @tHeads where major_head_code IN ('FS003','FS004','FS005')) thOtherCreditors on thOtherCreditors.head_code=th.head_code
	WHERE voucher_dt between @dFromDt AND @dToDt AND cancelled=0
	AND th.major_head_code IN ('0000000021','0000000005','0000000016','0000000002')  AND cancelled=0 AND thOtherCreditors.head_code IS NULL
	AND a.debit_AMOUNT<>0

	SET @nStep='90'
	INSERT INTO #tReportBaseData (xn_month,major_head_code,head_code,head_name,major_head_name,amount,mode,month_no)
	SELECT 'OPS' xn_month,e.major_head_code, d.head_code,f.head_name,f.head_name major_head_name,
	SUM(debit_amount-credit_amount) ,1 mode,4 month_no
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN hd01106 f (NOLOCK) ON f.HEAD_CODE=e.major_head_code
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt<@dFromDt AND cancelled=0 
	AND e.major_head_code IN ('0000000013','0000000014','0000000018','0000000021')
	GROUP BY d.head_code,e.major_head_code,d.head_name,f.HEAD_NAME

	SET @nStep='95'
	INSERT INTO #tReportBaseData (xn_month,major_head_code,head_code,head_name,major_head_name,amount,mode,month_no)
	SELECT Datename(month,voucher_Dt) xn_month,e.major_head_code, d.head_code,f.head_name,f.head_name major_head_name,
	SUM(debit_amount-credit_amount) ,1 mode,month(voucher_dt) month_no
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN hd01106 f (NOLOCK) ON f.HEAD_CODE=e.major_head_code
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0 
	AND e.major_head_code IN ('0000000013','0000000014','0000000018','0000000021')
	GROUP BY Datename(month,voucher_Dt),d.head_code,d.head_name,f.HEAD_NAME,e.major_head_code,month(voucher_dt)



	SET @nStep='100'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,major_head_name,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,e.major_head_code major_head_code,e.major_head_name,
	SUM(debit_amount-credit_amount) amount ,2 mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0 
	AND e.major_head_code NOT IN ('0000000013','0000000014','0000000018','0000000021')
	GROUP BY Datename(month,voucher_Dt),d.head_code,d.head_name,e.major_HEAD_NAME,e.major_HEAD_CODE



	SET @nStep='110'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,
	'CR_DEBTOR' major_head_code,SUM(debit_amount-credit_amount),2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpSDCredit f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	
	GROUP BY Datename(month,voucher_Dt) ,	d.head_code,d.head_name


	
	SET @nStep='120'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'DIR_INCM' major_head_code,SUM(debit_amount-credit_amount) ,
	2 mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpDirectIncomes f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	--select 'check #tmpDirectIncomes',sum(amount) from #tReportBaseData


	--SELECT'Check other inflow', Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,voucher_dt,voucher_no,
	--ac_name,'OTH_INF' major_head_code,SUM(debit_amount-credit_amount) other_amount	
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpOthInf f ON f.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code NOT IN ('0000000013','0000000014')
	--GROUP BY Datename(month,voucher_Dt) ,
	--d.head_code,d.head_name,voucher_dt,voucher_no,ac_name
	--ORDER BY voucher_dt,voucher_no

	SET @nStep='130'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'OTH_INF' major_head_code,SUM(debit_amount-credit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpOthInf f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	select a.vm_id into #tmpExpPaidVch FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpExpPaid f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code  IN ('0000000013','0000000014')
	and credit_amount<>0
	GROUP BY a.vm_id

	--SELECT 'Check Cash Fix Cost ',Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,
	--voucher_dt,voucher_no,ac_name,SUM(debit_amount) other_amount 
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpExpPaidVch f ON f.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000027','FS002')
	--and debit_amount<>0
	--GROUP BY Datename(month,voucher_Dt) ,
	--d.head_code,d.head_name,voucher_dt,voucher_no,ac_name
	--order by voucher_dt,voucher_no

	SET @nStep='140'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'CP_EXP' major_head_code,SUM(debit_AMOUNT) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpExpPaidVch f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  and e.major_head_code IN ('0000000027','FS002')
	AND a.debit_AMOUNT<>0
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name


	SELECT DISTINCT a.vm_id INTO #tmpTVCPaymentsVch FROM vd01106 a (NOLOCK) 
	JOIN vm01106 b (NOLOCK) ON b.vm_id=a.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN @tHeads th ON th.head_code=c.HEAD_CODE
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	JOIN #tmpTVCPayments e on a.vm_id=e.vm_id
	WHERE voucher_dt between @dFromdt and @dToDt AND cancelled=0
	AND  th.major_head_code IN ('0000000013','0000000014') AND cancelled=0
	AND a.credit_AMOUNT<>0


	--SELECT 'check tvc payments',Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,voucher_dt,voucher_no,SUM(debit_amount) ,
	--2  mode
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpTVCPaymentsVch f ON f.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN  ('FS004','FS005')
	--AND a.DEBIT_AMOUNT<>0
	--GROUP BY Datename(month,voucher_Dt) ,voucher_dt,voucher_no,
	--d.head_code,d.head_name
	--order by 2,3

	SET @nStep='150'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'CP_TVC' major_head_code,SUM(debit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpTVCPaymentsVch f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN  ('FS004','FS005')
	AND a.DEBIT_AMOUNT<>0
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	SET @nStep='160'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'CP_FCOST' major_head_code,SUM(credit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpTVCPayments f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	AND a.CREDIT_AMOUNT<>0
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	SELECT a.vm_id,sum(credit_amount) credit_amount into #tmpCapExpVch
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpCapitalExpPayments f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	AND a.CREDIT_AMOUNT<>0
	GROUP BY a.vm_id
	
	--SELECT 'Check Capital Expenditure',Datename(month,voucher_Dt), d.head_code,d.head_name,voucher_dt,voucher_no,ac_name,
	--SUM(a.debit_amount-a.credit_amount) other_amount,f.credit_amount paid_amount
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpCapExpVch f ON f.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--LEFT JOIN (select head_code from  @tHeads where major_head_code IN ('FS003','FS004','FS005')) thOtherCreditors on thOtherCreditors.head_code=e.head_code
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code  IN  ('0000000021','0000000005','0000000016','0000000002')
	--AND thOtherCreditors.head_code IS NULL
	--GROUP BY Datename(month,voucher_Dt) ,	d.head_code,d.head_name,voucher_dt,voucher_no,ac_name,f.credit_amount
	--order by voucher_dt,voucher_no
	
	SET @nStep='170'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt), d.head_code,d.head_name,'CP_CAPEXP' major_head_code,SUM(debit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpCapExpVch f ON f.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	LEFT JOIN (select head_code from  @tHeads where major_head_code IN ('FS003','FS004','FS005')) thOtherCreditors on thOtherCreditors.head_code=e.head_code
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code  IN  ('0000000021','0000000005','0000000016','0000000002')
	AND thOtherCreditors.head_code IS NULL	AND a.debit_AMOUNT<>0
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	

	SELECT a.vm_id,SUM(credit_amount) paid_amount into #tmpCapinvVch
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpCapInv t on t.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code  IN ('0000000013','0000000014')
	and a.DEBIT_AMOUNT<>0
	GROUP BY a.vm_id

	--SELECT 'check capital investment',Datename(month,voucher_Dt) xn_month,voucher_dt,voucher_no,
	--d.head_code,d.head_name,ac_name,SUM(debit_amount) other_amount,paid_amount
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpCapinvVch t on t.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code  IN ('0000000016','0000000002')
	--GROUP BY Datename(month,voucher_Dt),d.head_code,d.head_name,voucher_dt,voucher_no,ac_name,paid_amount
	--order by voucher_dt,voucher_no
	
	SET @nStep='180'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'CAP_INV' major_head_code,SUM(credit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpCapinvVch t on t.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000016','0000000002')
	GROUP BY Datename(month,voucher_Dt),d.head_code,d.head_name

	SELECT a.vm_id,sum(a.credit_amount) amount INTO #tmpothVch	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	LEFT JOIN #tmpCapExpVch f ON f.vm_id=a.vm_id
	LEFT JOIN #tmpTVCPaymentsVch g ON g.vm_id=a.vm_id
	LEFT JOIN #tmpExpPaidVch h ON h.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code IN ('0000000013','0000000014')
	AND a.CREDIT_AMOUNT<>0 AND f.vm_id IS NULL AND g.vm_id IS NULL AND h.vm_id IS NULL 
	GROUP BY a.vm_id


	--SELECT 'Check other Outflow', Datename(month,voucher_Dt) xn_month,voucher_Dt,voucher_no,
	--d.head_code,d.head_name,ac_name,SUM(debit_amount) other_amount
	--FROM vd01106 a (NOLOCK)
	--JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	--JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	--JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	--JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	--JOIN #tmpothVch h ON h.vm_id=a.vm_id
	--JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	--WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code NOT IN ('0000000013','0000000014')
	--and a.DEBIT_AMOUNT<>0
	--GROUP BY Datename(month,voucher_Dt) ,	d.head_code,d.head_name,voucher_Dt,voucher_no,ac_name
	--ORDER BY voucher_Dt,voucher_no


	
	SET @nStep='190'
	INSERT INTO #tReportBaseData (xn_month,head_code,head_name,major_head_code,amount,mode)
	SELECT Datename(month,voucher_Dt) xn_month, d.head_code,d.head_name,'OTH_OUTF' major_head_code,SUM(debit_amount) ,
	2  mode
	FROM vd01106 a (NOLOCK)
	JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN hd01106 d (NOLOCK) ON d.HEAD_CODE=c.HEAD_CODE
	JOIN @tHeads e ON e.head_code=c.HEAD_CODE
	JOIN #tmpothVch h ON h.vm_id=a.vm_id
	JOIN #locListFS loc ON loc.dept_id=a.cost_center_dept_id
	WHERE voucher_dt BETWEEN @dFromDt AND @dToDt AND cancelled=0  AND e.major_head_code NOT IN ('0000000013','0000000014')
	AND a.debit_amount<>0 
	GROUP BY Datename(month,voucher_Dt) ,
	d.head_code,d.head_name

	
	SET @nMonth=4

	SET @nStep='195'    
	SET @dXnDt=LTRIM(RTRIM(STR(YEAR(@dFromDt))))+'-03-31'

	print 'Insert closing stock for :'+convert(varchar,@dXndt,110)
	EXEC SP3S_GETCBSSTK_FOR_PLBS
	@dXnDt=@dXnDt,
	@nSpId=@@spid,
	@bCalledfromPl=1,
	@nRetOpsCbsMode=1,
	@bCalledFromFS=1,
	@nCbp=@nObp OUTPUT,
	@cErrormsg=@cErrormsg OUTPUT

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC

	WHILE @nMonth<=15
	BEGIN
		SET @nStep='200'

		set @nProcessmonth=(case when @nmonth=13 then 1 when @nmonth=14 then 2 when @nmonth=15 then 3  else @nMonth end)
		
			
		SET @dXnDt=(CASE WHEN @nProcessmonth<=3 THEN LTRIM(RTRIM(STR(YEAR(@dToDt))))+'-'+LTRIM(RTRIM(STR(@nProcessmonth)))+'-01'
						 ELSE LTRIM(RTRIM(STR(YEAR(@dFromDt))))+'-'+LTRIM(RTRIM(STR(@nProcessmonth)))+'-01' END)	

		SET @dXnDt=DATEADD(mm,1,@dXndt)-1
				
		-----Opening and closing Stock month wise
		INSERT INTO #tReportBaseData (xn_month,major_head_code,head_name,major_head_name,amount,mode)
		SELECT Datename(month,@dXndt) xn_month,'OBS' major_head_code,'Opening Stock' head_name,
		'Stock' major_head_name,@nObp,3 mode

		SET @nStep='220'
		

		print 'Insert closing stock for :'+convert(varchar,@dXndt,110)
		EXEC SP3S_GETCBSSTK_FOR_PLBS
		@dXnDt=@dXnDt,
		@nSpId=@@spid,
		@bCalledfromPl=1,
		@nRetOpsCbsMode=2,
		@bCalledFromFs=1,
		@nCbp=@nCbp OUTPUT,
		@cErrormsg=@cErrormsg OUTPUT

		IF ISNULL(@cErrormsg,'')<>''
			GOTO END_PROC

		--if @dXndt='2022-04-30'
		--	select @nCBp april_closing,* from #locListFS

		INSERT INTO #tReportBaseData (xn_month,major_head_code,head_name,major_head_name,amount,mode)
		SELECT Datename(month,@dXnDt) xn_month,'CBS' major_head_code,'Closing Stock' head_name,
		'Stock' major_head_name,@nCbp,3 mode


		SET @nMonth=@nMonth+1

		SET @nObp=@nCbp

		IF month(@dXndt)=month(getdate()) and @cFInyear=@cCurFInyear
			BREAK
	END
	
	SET @nStep='230'
	---Revenue	
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Revenue' major_head_name,ABS(SUM(amount)) amount,1 srno FROM #tReportBaseData WHERE major_head_code='0000000030'
	AND mode=2
	GROUP BY xn_month
	

	
	---TVC
	--if @@spid=314
	--	select 'check tvc', * from #tReportBaseData WHERE (major_head_code IN ('0000000026','0000000029') AND mode=2)
	--or major_head_code in ('OBS','CBS')

	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'TVC' major_head_name,SUM(CASE WHEN major_head_code='CBS' THEN -amount ELSE amount END) amount,2 srno 
	FROM #tReportBaseData WHERE (major_head_code IN ('0000000026','0000000029') AND mode=2)
	or major_head_code in ('OBS','CBS')
	GROUP BY xn_month

	SET @nStep='240'
	--Gross Profit
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Gross Profit' major_head_name,SUM(CASE WHEN head_name='Revenue' THEN amount ELSE -amount END) amount,3 srno
	FROM #tReport where head_name IN ('Revenue','TVC')
	GROUP BY xn_month

	SET @nStep='245'
	--Gross Profit%
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT a.xn_month,'Gross Profit %' major_head_name,(CASE WHEN b.amount=0 THEN 0 ELSE CONVERT(NUMERIC(10,2),(a.amount/b.amount)*100) END) AMOUNT,4 srno
	FROM #tReport a JOIN #tReport b ON a.xn_month=b.xn_month where a.head_name='Gross Profit' AND b.head_name='Revenue'

	SET @nStep='250'
	--Indirect Income
	

	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Indirect Income' major_head_name,SUM(amount) amount,5 srno
	FROM #tReportBaseData WHERE major_head_code='FS001' AND mode=2
	GROUP BY xn_month

	--Fixed Cost (Indirect Expense)
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Fixed Cost' major_head_name,ABS(SUM(amount)) amount,6 srno
	FROM #tReportBaseData WHERE major_head_code IN ('0000000027') AND mode=2
	GROUP BY xn_month

	SET @nStep='260'
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Net Profit Margin' major_head_name,SUM(CASE WHEN head_name IN ('Gross Profit','Indirect Income') 
	THEN amount ELSE -amount END) amount,7 srno
	FROM #tReport where head_name IN ('Gross Profit','Indirect Income','Fixed Cost')
	GROUP BY xn_month
	
	SET @nStep='265'
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT a.xn_month,'Net Profit Margin %' major_head_name,(Case when b.amount=0 then 0 else CONVERT(NUMERIC(10,2),(a.amount/b.amount)*100) end) AMOUNT,8 srno
	FROM #tReport a JOIN #tReport b ON a.xn_month=b.xn_month where a.head_name='Net Profit Margin' AND b.head_name='Revenue'
	
	SET @nStep='270'
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT a.xn_month,'Break Even Point' major_head_name,(case when b.amount=0 then 0 else CONVERT(NUMERIC(10,2),
	(a.amount/b.amount)*100) end) AMOUNT,9 srno
	FROM #tReport a JOIN #tReport b ON a.xn_month=b.xn_month where a.head_name='Fixed Cost' AND b.head_name='Gross Profit %'

	--select 'check payable',* from #tReportBaseData where major_head_code='0000000021'
	--order by xn_month

	--SET @nStep='275'
	--INSERT INTO #tReport (xn_month,head_name,amount,srno)
	--SELECT xn_month,'Account Payable' major_head_name,SUM(amount) AMOUNT,10 srno
	--FROM #tReportBaseData where major_head_code='0000000021' AND mode=2
	--GROUP BY xn_month

	--SET @nStep='280'
	--INSERT INTO #tReport (xn_month,head_name,amount,srno)
	--SELECT xn_month,'Account Receivable' major_head_name,SUM(amount) AMOUNT,11 srno
	--FROM #tReportBaseData where major_head_code='0000000018' AND mode=2
	--GROUP BY xn_month

	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Inventory' major_head_name,SUM(amount) AMOUNT,12 srno
	FROM #tReportBaseData where major_head_code='cbs'
	GROUP BY xn_month


	---- Start of Actual Cash InFlow
	--Debt REceivable

	
	SET @nStep='300'
	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Debt Receivable' major_head_name,SUM(amount),14,1 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('CR_DEBTOR','DIR_INCM')
	GROUP BY xn_month
	
	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Capital Investments' major_head_name,SUM(amount),15,1 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('CAP_INV')
	GROUP BY xn_month

	SET @nStep='310'
	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Other Inflows' major_head_name,SUM(amount),16,1 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('OTH_INF')
	GROUP BY xn_month

	---- End of  of Actual Cash InFlow

	SET @nStep='320'
	---- Start of Actual Cash OutFlow
	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Cash Fixed Cost' major_head_name,SUM(amount),17,2 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('CP_EXP')
	GROUP BY xn_month

	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Cash TVC' major_head_name,SUM(amount),18,2 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('CP_TVC')
	GROUP BY xn_month

	SET @nStep='330'
	IF EXISTS (SELECT TOP 1 head_name FROM #tReportBaseData WHERE major_head_code IN ('CP_capexp')) 
		INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
		SELECT xn_month,'Capital Expenditure' major_head_name,SUM(amount),19,2 cashflowMode
		FROM #tReportBaseData WHERE major_head_code IN ('CP_capexp')
		GROUP BY xn_month
	ELSE
		INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
		SELECT top 1 xn_month,'Capital Expenditure' major_head_name,0,19,2 cashflowMode
		FROM #tReportBaseData WHERE 1=1

	INSERT INTO #tReport (xn_month,head_name,amount,srno,cashflowMode)
	SELECT xn_month,'Other Outflow' major_head_name,SUM(amount),20,2 cashflowMode
	FROM #tReportBaseData WHERE major_head_code IN ('OTH_OUTF')
	GROUP BY xn_month
	---- End of Actual Cash OutFlow

	SET @nStep='340'
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Net Cash Flow' major_head_name,SUM(CASE WHEN cashflowMode=1 THEN amount ELSE -amount END) amount,21
	FROM #tReport WHERE ISNULL(cashflowMode,0) IN (1,2)
	GROUP BY xn_month

	UPDATE #tReportBaseData set month_no=month_no+12 where month_no<4
	

	INSERT INTO #tReport (xn_month,head_name,obscbs_Amount,srno,balanceentry,month_no,amount)
	SELECT (CASE WHEN a.xn_month='OPS' THEN 'APRIL' ELSE a.xn_month END) xn_month,a.head_name,
	SUM(a.amount) amount,0 srno,1 balanceentry,(case when A.XN_MONTH='ops' then 3 else a.month_no END),0 amount
	FROM #tReportBaseData a 
	WHERE a.major_head_code IN ('0000000014','0000000013') AND a.mode=1
	GROUP BY (CASE WHEN a.xn_month='OPS' THEN 'APRIL' ELSE a.xn_month END),
	(case when A.XN_MONTH='ops' then 3 else a.month_no END),a.month_no,a.head_name

	UPDATE a SET amount=(SELECT sum(obscbs_Amount) FROM #tReport b WHERE b.balanceentry=1 AND a.head_name=b.head_name 
	AND (b.month_no<a.month_no)) 
	FROM #tReport a WHERE balanceentry=1

	--if @@spid=324	
	--select 'check receivable',* from #tReportBaseData where major_head_code='0000000018'
	--order by xn_month

	INSERT INTO #tReport (xn_month,head_name,obscbs_Amount,srno,balanceentry,month_no,amount)
	SELECT (CASE WHEN a.xn_month='OPS' THEN 'APRIL' ELSE a.xn_month END) xn_month,
	(CASE WHEN a.major_head_code='0000000021' then 'Account Payable' WHEN a.major_head_code='0000000018' then 'Account Receivable' 
	else  a.head_name end) head_name,
	SUM(a.amount) amount,(CASE WHEN a.major_head_code='0000000021' then 10 when a.major_head_code='0000000018' then 11
	else  22 end) srno,1 balanceentry,a.month_no,0 amount
	FROM #tReportBaseData a 
	WHERE a.major_head_code IN ('0000000014','0000000013','0000000018','0000000021') AND a.mode=1
	GROUP BY (CASE WHEN a.xn_month='OPS' THEN 'APRIL' ELSE a.xn_month END),a.month_no,a.head_name,
	(CASE WHEN a.major_head_code='0000000021' then 10 when a.major_head_code='0000000018' then 11
	else  22 end),(CASE WHEN a.major_head_code='0000000021' then 'Account Payable' WHEN a.major_head_code='0000000018' then 'Account Receivable' 
	else  a.head_name end)

	UPDATE a SET amount=(SELECT sum(obscbs_Amount) FROM #tReport b WHERE b.balanceentry=1 AND b.srno=a.srno
	AND a.head_name=b.head_name	AND b.month_no<=a.month_no) 
	FROM #tReport a WHERE balanceentry=1  AND a.srno in (22,10,11)
	

	SET @nStep='290'
	INSERT INTO #tReport (xn_month,head_name,amount,srno)
	SELECT xn_month,'Working Capital' major_head_name,SUM(CASE WHEN head_name IN ('Account Receivable','Inventory') 
	THEN amount ELSE -abs(amount) END) amount,13 srno
	FROM #tReport where head_name IN ('Account Payable','Account Receivable','Inventory')
	GROUP BY xn_month
	
	--select * from #tReportBaseData where major_head_code IN ('0000000014','0000000013')
	--select * from #tReport where balanceentry=1 order by month_no,srno

	select @cMonthStr = '[APR],[MAY],[JUN],[JUL],[AUG],[SEP],[OCT],[NOV],[DEC],[JAN],[FEB],[MAR]',
	@cMonthCols = 'SUM(ISNULL([APR],0)) APR,SUM(ISNULL([MAY],0)) MAY,SUM(ISNULL([JUN],0)) JUN,'+
	' SUM(ISNULL([JUL],0)) JUL,SUM(ISNULL([AUG],0)) AUG,SUM(ISNULL([SEP],0)) SEP,SUM(ISNULL([OCT],0)) OCT,SUM(ISNULL([NOV],0)) NOV,'+
	' SUM(ISNULL([DEC],0)) DEC,SUM(ISNULL([JAN],0)) JAN,SUM(ISNULL([FEB],0)) FEB,SUM(ISNULL([MAR],0)) MAR'

	
	SET @cCmd=N'SELECT head_name,srno,'+@cMonthCols+'  FROM 
	 ( SELECT head_name,SRNO,'+@cMonthStr+' FROM 
	 (select  LEFT(XN_MONTH,3) XN_MONTH_NEW,ABS(amount) amount,head_name,srno from #tReport ) a
	 PIVOT 
	 (sum(amount) for XN_MONTH_NEW IN ('+@cMonthStr+')) pvt
	 
	 ) a GROUP BY head_name,srno
	 order by srno
	 '
	
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd


	GOTO END_PROC

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_ACT_FINANCIAL_SMRY at Step#'+@nStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

IF ISNULL(@cErrormsg,'')<>''
	SELECT @cErrormsg errmsg
END

