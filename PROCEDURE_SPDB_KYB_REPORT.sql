CREATE PROCEDURE SPDB_KYB_REPORT
@dRepDt DATETIME,
@cUserCode CHAR(7)='0000000',
@nSrnoPara NUMERIC(3,0)=0
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@NDAYSCNT NUMERIC(5,0),@dFinyearFromDt datetime,@cFinYear VARCHAR(5),
	@cKpiStr VARCHAR(1000),@dlyRepDt DATETIME,@cKpiNamePara VARCHAR(100),@cRoleId CHAR(7)

	SELECT @cRoleId=a.role_id FROM users a (NOLOCK)	WHERE user_code=@cUserCode

	DECLARE @tOrder TABLE (kpi_name VARCHAR(200),srno NUMERIC(2,0))

	INSERT INTO @tOrder (kpi_name,srno) 
	SELECT 'Sale',1
	UNION
	SELECT 'Profit Amount',2
	UNION
	SELECT 'GMROI',3
	UNION
	SELECT 'Active Sq. ft. Area',4
	UNION 
	SELECT 'Sale(PSFPD)',5
	UNION
	SELECT 'Profit(PSFPD)',6
	UNION
	SELECT 'ASD',7
	UNION
	SELECT 'TPY',8
	UNION
	SELECT 'Days of Stock',9
	UNION
	SELECT 'ATS ',10
	UNION
	SELECT 'ABS',11
	UNION
	SELECT 'ASP',12
	UNION
	SELECT 'Discount/Sale Ratio',13
	UNION
	SELECT 'Wizclip Discount/Sale Ratio',14
	UNION
	SELECT 'Wizclip Sale Contribution',15
	UNION
	SELECT 'New/Old Stock Ratio',16
	UNION
	SELECT 'Ageing(Purchase)',17
	UNION
	SELECT 'Expense/Sale Ratio',18
	UNION
	SELECT 'Funds in Bank',19
	UNION
	SELECT 'Cash in Hand',20
	UNION
	SELECT 'Accounts Payable',21
	UNION
	SELECT 'Accounts Receivable',22
	UNION
	SELECT 'GP%',23
	UNION
	SELECT 'NP%',24
	
	DELETE  a FROM @tOrder a LEFT OUTER JOIN 
	(SELECT form_name from user_role_det (NOLOCK) WHERE role_id=@cRoleId AND form_name LIKE '%kyb%'
	 AND value='1') b
	ON 'KYB_'+LTRIM(RTRIM(STR(a.srno)))=b.FORM_NAME
	WHERE b.FORM_NAME IS NULL

	SET @cKpiNamePara=''

	IF @nSrnoPara<>0
		SELECT @cKpiNamePara=kpi_name from @tOrder WHERE srno=@nSrnoPara

	SET @CFINYEAR='01'+dbo.FN_GETFINYEAR(@dREpDt)

	SET @dFinyearFromDt=CONVERT(DATE,DBO.FN_GETFINYEARDATE(@CFINYEAR,1),110)	
	SELECT @NDAYSCNT=DATEDIFF(DD,@dFinyearFromDt,@dRepDt)+1

	SELECT CONVERT(VARCHAR(3),'') DEPT_ID,a.Kpi_NAME,a.ytd_value cy_value,a.ytd_value as ly_value,
	CONVERT(NUMERIC(10,2),0) AS variance,CONVERT(NUMERIC(1,0),0) AS DEVIATION INTO #tmpKyb
	FROM pos_dynamic_dbdata a (NOLOCK) WHERE 1=2
	
	SET @dlyRepDt=DATEADD(YY,-1,@dRepDt)

	IF @cKpiNamePara=''	
	BEGIN
		INSERT  #tmpKyb (dept_id,kpi_name,cy_value,ly_value,variance,deviation)
		SELECT 'All' dept_id,a.Kpi_NAME,a.cy_value,isnull(b.ly_value,0) as ly_value,
		CONVERT(NUMERIC(10,2),0) AS variance,CONVERT(NUMERIC(1,0),0) AS DEVIATION  FROM
		(SELECT kpi_name,SUM(ytd_value) as cy_value 
		 FROM pos_dynamic_dbdata a (nolock)
		 LEFT JOIN locusers b (NOLOCK) ON a.para_name=b.dept_id  AND user_code=@cUserCode
		 where db_dt=@dRepDt AND setup_id='KYB0001' AND kpi_name NOT IN ('TPY','GMROI','DAYS OF STOCK')
		 AND (kpi_name NOT IN ('ASD','Ageing(Purchase)') OR a.para_name='ALL' )
		  GROUP BY KPI_NAME) a
		left outer join 
		(SELECT kpi_name,SUM(ytd_value) as ly_value  FROM pos_dynamic_dbdata a (nolock)
		 LEFT JOIN locusers b (NOLOCK) ON a.para_name=b.dept_id  AND user_code=@cUserCode 
		 where db_dt=DATEADD(YY,-1,@dRepDt) 
		 AND setup_id='KYB0001' AND kpi_name NOT IN ('TPY','GMROI','DAYS OF STOCK')
		 AND (kpi_name NOT IN ('ASD','Ageing(Purchase)') OR a.para_name='ALL' )
		  GROUP BY kpi_name
		 ) b on a.kpi_name=b.kpi_name
	END

	ELSE
	BEGIN
		SELECT @cKpiStr=(CASE WHEN @cKpiNamePara='Discount/Sale Ratio' THEN '''Total Discount'',''SALE'''
		WHEN @cKpiNamePara='Wizclip Discount/Sale Ratio' THEN '''Wizclip Discount'',''SALE'''
		WHEN @cKpiNamePara='New/Old Stock Ratio' THEN '''New Stock'',''Old Stock'''
		WHEN @cKpiNamePara='Expense/Sale Ratio' THEN '''Expense'',''Sale'''
		WHEN @cKpiNamePara='Wizclip Sale Contribution' THEN '''Wizclip Sale'',''Sale'''
		WHEN @cKpiNamePara='ASP' THEN '''Sale Qty'',''Sale'''
		WHEN @cKpiNamePara='ADS(NRV)' THEN '''Sale'''
		WHEN @cKpiNamePara='SALE(PSFPD)' THEN '''Sale'',''Active Sq. ft. Area'''
		WHEN @cKpiNamePara='Profit(PSFPD)' THEN '''PROFIT AMOUNT'',''Active Sq. ft. Area'''
		WHEN @cKpiNamePara='Days of Stock' THEN '''PROFIT AMOUNT'',''Active Sq. ft. Area'''
		WHEN @cKpiNamePara='Days of Stock' THEN '''CLOSING STOCK'',''SALE QTY'''
		WHEN @cKpiNamePara='GP%' THEN '''GP'',''ACCOUNT SALES'''
		WHEN @cKpiNamePara='NP%' THEN '''NP'',''ACCOUNT SALES'''
		WHEN @cKpiNamePara='GMROI' THEN '''ADI'',''SALE'',''Cost of Goods Sold'''
		WHEN @cKpiNamePara='TPY' THEN '''ADI'',''Cost of Goods Sold'''
		ELSE ''''+@cKpiNamePara+'''' END)
		
		
		 			
		SET @cCmd=N'SELECT a.dept_id,a.Kpi_NAME,a.cy_value,isnull(b.ly_value,0) as ly_value,
		CONVERT(NUMERIC(10,2),0) AS variance,CONVERT(NUMERIC(1,0),0) AS DEVIATION  FROM
		(SELECT b.dept_id,kpi_name,SUM(ytd_value) as cy_value 
		 FROM pos_dynamic_dbdata a (nolock)
		 JOIN locusers b (NOLOCK) ON a.para_name=b.dept_id
		 where setup_id=''KYB0001'' AND db_dt='''+convert(varchar,@dRepDt,110)+''' AND 
		 kpi_name IN ('+@cKpiStr+') AND user_code='''+@cUserCode+'''
		 GROUP BY b.dept_id,KPI_NAME) a
		left outer join 

		(SELECT b.dept_id,kpi_name,SUM(ytd_value) as ly_value  FROM pos_dynamic_dbdata a (nolock)
		 JOIN locusers b (NOLOCK) ON a.para_name=b.dept_id
		 where setup_id=''KYB0001'' AND db_dt='''+convert(varchar,@dlyRepDt,110)+''' 
		 AND  kpi_name IN ('+@cKpiStr+') AND user_code='''+@cUserCode +'''
		 GROUP BY b.dept_id,kpi_name
		 ) b on a.dept_id=b.dept_id AND a.kpi_name=b.kpi_name
		 '
		
		print 'get kpi wise data'
		 PRINT @cCmd

		 INSERT  #tmpKyb (dept_id,kpi_name,cy_value,ly_value,variance,deviation)
		 EXEC SP_EXECUTESQL @cCmd

	 END

	--WHERE a.kpi_name in ('SALE' ,'Profit Amount','GMROI','Active Sq. ft. Area','Sale(PSFPD)','Profit(PSFPD)',
	--'ASD','Ageing(Purchase)','TPY','Total Discount','Wizclip Discount','Wizclip Sale',
	--'Days of Stock','New Stock','Expense','Account Sales','Funds in Bank','Cash in Hand','Sale Qty',
	--'Accounts Payable','Accounts Receivable','GP','NP')

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id,'Discount/Sale Ratio' as kpi_name,(CASE WHEN b.cy_value=0 THEN 0 ELSE
	ROUND((a.cy_value/b.cy_value)*100,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value)*100,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='Total Discount' AND b.kpi_name='SALE'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'Wizclip Discount/Sale Ratio' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/b.cy_value)*100,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value)*100,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='Wizclip Discount' AND b.kpi_name='SALE'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'New/Old Stock Ratio' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND(a.cy_value/b.cy_value,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value),2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='New Stock' AND b.kpi_name='Old Stock'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'Expense/Sale Ratio' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/b.cy_value),2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value),2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='Expense' AND b.kpi_name='Sale'
	
	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'Wizclip Sale Contribution' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/b.cy_value)*100,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value)*100,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='Wizclip Sale' AND b.kpi_name='Sale'
	

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'ASP' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/b.cy_value),2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_value),2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE  a.kpi_name='Sale' AND b.kpi_name='Sale Qty'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'ADS(NRV)' as kpi_name,ROUND((a.cy_value/@NDAYSCNT),2) cy_value,
	ROUND((a.ly_value/@NDAYSCNT),2) ly_value
	FROM  #tmpKyb  a
	WHERE  a.kpi_name='Sale'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'SALE(PSFPD)' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/@NDAYSCNT)/b.cy_Value,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/@NDAYSCNT)/b.ly_Value,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='SALE' AND b.kpi_name='Active Sq. ft. Area'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'Profit(PSFPD)' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/@NDAYSCNT)/b.cy_Value,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/@NDAYSCNT)/b.ly_Value,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='PROFIT AMOUNT' AND b.kpi_name='Active Sq. ft. Area'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'Days of Stock' as kpi_name,(CASE WHEN b.cy_value<>0 THEN 
	ROUND(a.cy_value/(b.cy_value/@NDAYSCNT),0) ELSE 0 END) cy_value,
	(CASE WHEN b.ly_value<>0 THEN ROUND(a.ly_value/(b.ly_value/@NDAYSCNT),0) ELSE 0 END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='CLOSING STOCK' AND b.kpi_name='SALE QTY'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'GP%' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/ABS(b.cy_Value))*100,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_Value)*100,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='GP' AND b.kpi_name='ACCOUNT SALES'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'NP%' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ROUND((a.cy_value/ABS(b.cy_Value))*100,2) END) cy_value,
	(CASE WHEN b.ly_value=0 THEN 0 ELSE ROUND((a.ly_value/b.ly_Value)*100,2) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='NP' AND b.kpi_name='ACCOUNT SALES'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'GMROI' as kpi_name,
	(CASE WHEN c.cy_value=0 THEN 0 ELSE ((a.cy_value-b.cy_value)*365.0/(c.cy_value*@NDAYSCNT))*100 END) cy_value,
	(CASE WHEN c.ly_value=0 THEN 0 ELSE ((a.ly_value-b.ly_value)*365.0/(c.ly_value*@NDAYSCNT))*100 END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	JOIN #tmpKyb  c ON a.dept_id=b.dept_id
	WHERE a.kpi_name='SALE' AND b.kpi_name='Cost of Goods Sold' AND c.kpi_name='ADI'

	INSERT INTO #tmpKyb (dept_id,kpi_name,cy_value,ly_value)
	SELECT a.dept_id, 'TPY' as kpi_name,
	(CASE WHEN b.cy_value=0 THEN 0 ELSE ((a.cy_value*365.0)/(b.cy_value*@NDAYSCNT)) END) cy_value,
	(CASE WHEN b.Ly_value=0 THEN 0 ELSE ((a.ly_value*365.0)/(b.ly_value*@NDAYSCNT)) END) ly_value
	FROM  #tmpKyb  a
	JOIN #tmpKyb  b ON a.dept_id=b.dept_id
	WHERE a.kpi_name='Cost of Goods Sold' AND b.kpi_name='ADI'


	UPDATE #tmpKyb SET  VARIANCE=(CASE WHEN isnull(ly_value,0)<>0 THEN CONVERT(NUMERIC(10,0),
	((isnull(cy_value,0)-ly_value)/ABS(isnull(ly_value,0)))*100) ELSE 100 END)  
		
	--UPDATE a SET discount_sale_ratio=(total_discount/nrv)*100,
	--wizclip_discount_sale_ratio=(wizclip_discount/nrv)*100,
	--asp=nrv/sold_qty,
	--ads_nrv=nrv/@NDAYSCNT,
	--ads_nrv_psf = (CASE WHEN isnull(area_covered,0)<>0 THEN  (nrv/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
	--nrv_psfpd = (CASE WHEN isnull(area_covered,0)<>0 THEN  (nrv/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
	--profit_psfpd = (CASE WHEN isnull(area_covered,0)<>0 THEN  (profit_amt/@NDAYSCNT)/isnull(area_covered,0) else 0 end),
	--Wizclip_Sale_Contribution=(CASE WHEN nrv<>0 THEN (Wizclip_Sale/nrv)*100 ELSE 0 END),
	--expense_sale_ratio=ABS(a.expense/b.sales)*100,
	--gp_pct=(cbs-obs+sales-purchase-directexpense)/Sales)*100 as gross_profit,
	--np_pct=(cbs-obs+sales-purchase-directexpense)-IndirectExpense+Income)/Sales)*100 as net_profit,
	--days_of_stock=(CASE WHEN sold_qty<>0 THEN ROUND(cbs_stk/(Sale Qty/@NDAYSCNT),0) else 0 end),
	--VARIANCE=(CASE WHEN isnull(b.ly_value,0)<>0 THEN CONVERT(NUMERIC(10,0),((isnull(a.cy_value,0)-b.ly_value)/ABS(isnull(b.ly_value,0)))*100)
	--ELSE 100 END)  
	--FROM #pos_dynamic_dbdata a
	--JOIN location b (NOLOCK) ON a.para_name=b.dept_id+'-'+b.dept_name

	UPDATE #tmpKyb SET deviation=
	(CASE WHEN kpi_name IN ('ASD','Discount/Sale Ratio','Wizclip Discount/Sale Ratio','Expense/Sale Ratio',
	'Accounts Payable','Accounts Receivable','Days of Stock','Ageing(Purchase)') THEN 
	(CASE WHEN ly_value>cy_value THEN 1 ELSE 2 END)
	WHEN ly_value<cy_value  THEN 1 ELSE 2 END)

	update a set kpi_name=b.kpi_name from #tmpkyb a 
	JOIN @tOrder b ON a.kpi_name=b.kpi_name

	IF @cKpiNamePara=''
		select a.*,b.srno from #tmpkyb a 
		JOIN @tOrder b ON a.kpi_name=b.kpi_name
		ORDER BY srno
	ELSE
		select a.dept_id+'-'+dept_alias dept_name,a.*,convert(numeric(6,2),(a.cy_value/c.all_cy_value)*100) as cy_contr,
		convert(numeric(6,2),(a.ly_value/c.all_ly_value)*100) as ly_contr from #tmpkyb a 
		JOIN @tOrder b ON a.kpi_name=b.kpi_name
		JOIN (SELECT sum(cy_value) as all_cy_value,sum(ly_value) as all_ly_value
			  FROM #tmpkyb) c ON 1=1
		JOIN location d (NOLOCK) ON d.dept_id=a.dept_id
		WHERE a.kpi_name=@cKpiNamePara
		ORDER BY srno
END