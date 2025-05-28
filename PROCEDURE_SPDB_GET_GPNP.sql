CREATE PROCEDURE SPDB_GET_GPNP
@dRepDt DATETIME,
@cFinyear VARCHAR(5)
AS
BEGIN
	declare @cCmd NVARCHAR(MAX),@cPmtTableName VARCHAR(200),@dFinyearFromDt datetime

	CREATE TABLE #tmpPlHeads (head_Code char(10),bs_head_code CHAR(10),srno NUMERIC(1,0))  
	
	SET @dFinyearFromDt=CONVERT(DATE,DBO.FN_GETFINYEARDATE(@CFINYEAR,1),110)	
	
	CREATE TABLE #tProfitDet (dept_id varCHAR(5),obs NUMERIC(20,2),Cbs NUMERIC(20,2),sales NUMERIC(20,2),
	 purchase NUMERIC(20,2),DirectExpense NUMERIC(20,2),InDirectExpense NUMERIC(20,2),income NUMERIC(20,2))

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

	DECLARE @nSales NUMERIC(20,2),@nPurchase NUMERIC(20,2),@nDirectExpense NUMERIC(20,2),
	@nInDirectExpense NUMERIC(20,2),@nInCome NUMERIC(20,2),@nCbs NUMERIC(20,2),@nObs NUMERIC(20,2)

	SET @dFinyearFromDt=CONVERT(DATE,DBO.FN_GETFINYEARDATE(@CFINYEAR,1),110)

	SET @cPmtTableName=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dRepDt,112)

	SET @cCmd=N'SELECT dept_id,sum(cbs_qty*pp) as cbs,0 as obs from '+@cPmtTableName+' a
	join sku_names sn (nolock) on sn.product_Code=a.product_code
	WHERE ISNULL(sku_item_type,0) IN (0,1)
	GROUP BY dept_id'
	PRINT @cCmd

	INSERT #tProfitDet(dept_id,cbs,obs)
	EXEC SP_EXECUTESQL @cCmd

	SET @cPmtTableName=db_name()+'_pmt.dbo.pmtlocs_'+convert(varchar,@dFinYearFromDt-1,112)

	SET @cCmd=N'select dept_id,0 as cbs,sum(cbs_qty*pp) as obs  from '+@cPmtTableName+' a
	join sku_names sn (nolock) on sn.product_Code=a.product_code
	WHERE ISNULL(sku_item_type,0) IN (0,1) GROUP BY dept_id'
	PRINT @cCmd
	INSERT #tProfitDet(dept_id,cbs,obs)
	EXEC SP_EXECUTESQL @cCmd
	
	INSERT #tProfitDet(dept_id,sales)
	select cost_center_dept_id,abs(sum(debit_amount-credit_amount))
			from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
			join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
			join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
			join #tmpPlHeads thd on thd.head_Code=lm.HEAD_CODE
			where vm.fin_year=@cFinYear AND  cancelled=0 and VOUCHER_DT<=@dRepDt AND
			vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
			AND thd.bs_head_code IN ('0000000030')
	GROUP BY cost_center_dept_id

	INSERT #tProfitDet(dept_id,purchase)
	select cost_center_dept_id,abs(sum(debit_amount-credit_amount))
			from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
			join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
			join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
			join #tmpPlHeads thd on thd.head_Code=lm.HEAD_CODE
			where vm.fin_year=@cFinYear AND  cancelled=0 and VOUCHER_DT<=@dRepDt AND
			vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
			AND thd.bs_head_code IN ('0000000029')
	GROUP BY cost_center_dept_id

	INSERT #tProfitDet(dept_id,DirectExpense)
	select cost_center_dept_id,abs(sum(debit_amount-credit_amount))
			from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
			join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
			join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
			join #tmpPlHeads thd on thd.head_Code=lm.HEAD_CODE
			where vm.fin_year=@cFinYear AND  cancelled=0 and VOUCHER_DT<=@dRepDt AND
			vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
			AND thd.bs_head_code IN ('0000000026')
	GROUP BY cost_center_dept_id

	INSERT #tProfitDet(dept_id,InDirectExpense)
	select cost_center_dept_id,abs(sum(debit_amount-credit_amount))
			from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
			join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
			join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
			join #tmpPlHeads thd on thd.head_Code=lm.HEAD_CODE
			where vm.fin_year=@cFinYear AND  cancelled=0 and VOUCHER_DT<=@dRepDt AND
			vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
			AND thd.bs_head_code IN ('0000000027')
	GROUP BY cost_center_dept_id

	INSERT #tProfitDet(dept_id,Income)
	select dept_id, abs(sum(debit_amount-credit_amount))
		from vd01106 vd (NOLOCK) join vm01106 vm (NOLOCK) on vd.VM_ID = vm.VM_ID    
		join lm01106 lm (NOLOCK) on lm.AC_CODE = vd.AC_CODE    
		join vchtype vch (NOLOCK) on vch.VOUCHER_CODE = vm.VOUCHER_CODE    
		join #tmpPlHeads thd on thd.head_Code=lm.HEAD_CODE
		where vm.fin_year=@cFinYear AND  cancelled=0 and VOUCHER_DT<=@dRepDt AND
		vch.VOUCHER_CODE not in (select VOUCHER_CODE from vchtype where VOUCHER_TYPE like '%memo%')    
		AND thd.bs_head_code IN ('0000000028')
	GROUP BY dept_id
	
	--if @@spid=805
	-- select 'gp calc',	sum(isnull(obs,0)) obs,sum(isnull(cbs,0)) cbs,sum(isnull(sales,0)) sales,
	-- sum(isnull(purchase,0)) purchase,sum(isnull(DirectExpense,0)) DirectExpense,sum(isnull(InDirectExpense,0)) InDirectExpense,
	-- sum(isnull(income,0)) income
	-- FROM #tProfitDet

	---- Basic formula for calculating GP
		--declare @nGp numeric(20,2)
		--select @nGp= (@nCbs-@nObs+@nSales-@nPurchase-@nDirectExpense)

	INSERT #tProfit (dept_id,gross_profit,net_profit,sales)
	select dept_id,(cbs-obs+sales-purchase-directexpense) as gross_profit,
	((cbs-obs+sales-purchase-directexpense)-IndirectExpense+Income) as net_profit,sales
	FROM
	(SELECT dept_id,sum(isnull(obs,0)) obs,sum(isnull(cbs,0)) cbs,sum(isnull(sales,0)) sales,
	 sum(isnull(purchase,0)) purchase,sum(isnull(DirectExpense,0)) DirectExpense,sum(isnull(InDirectExpense,0)) InDirectExpense,
	 sum(isnull(income,0)) income
	 FROM #tProfitDet
	 GROUP BY dept_id) a

		--select * from #tprofit
END