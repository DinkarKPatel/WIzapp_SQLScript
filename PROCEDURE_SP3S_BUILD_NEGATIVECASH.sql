CREATE PROCEDURE SP3S_BUILD_NEGATIVECASH
AS
BEGIN
	declare @dServerDt datetime,@dFirstVoucherDt DATETIME,@cFinYear VARCHAR(5),@dFinYearFromDt DATETIME

	SET @dServerDt = convert(date,getdate())

	SET @cFinYear='01'+dbo.FN_GETFINYEAR(DATEADD(YY,-1,@dServerDt))
	SET @dFirstVoucherDt=dbo.FN_GETFINYEARDATE(@cFinYear,1)

	DECLARE @cCashHeads VARCHAR(500)
	select @cCashHeads=dbo.fn_act_travtree('0000000014')

	SELECT head_code INTO #tmpCashHeads FROM hd01106 where charindex(head_code,@cCashHeads)>0


	SELECT @dFirstVoucherDt as opn_dt,cost_center_dept_id,sum(debit_amount-credit_amount) as xn_amount
	INTO #tmpObCash  from vd01106 a (NOLOCK)JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN #tmpCashHeads d ON  d.HEAD_CODE=c.HEAD_CODE
	WHERE voucher_dt<@dFirstVoucherDt AND cancelled=0
	GROUP BY cost_center_dept_id

	SELECT voucher_dt,cost_center_dept_id,sum(debit_amount-credit_amount) as xn_amount,CONVERT(NUMERIC(14,2),0) AS BALANCE
	INTO #tmpBalance  from vd01106 a (NOLOCK)JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	JOIN #tmpCashHeads d ON  d.HEAD_CODE=c.HEAD_CODE
	WHERE voucher_dt>=@dFirstVoucherDt AND cancelled=0
	GROUP BY cost_center_dept_id,voucher_dt

	UPDATE a SET xn_amount=a.xn_amount+b.xn_amount FROM #tmpBalance a
	JOIN #tmpObCash b ON a.cost_center_dept_id=b.cost_center_dept_id

	INSERT #tmpBalance (VOUCHER_DT,cost_center_dept_id,xn_amount,BALANCE)
	SELECT a.opn_dt VOUCHER_DT,a.cost_center_dept_id,a.xn_amount,0 BALANCE FROM #tmpObCash a
	LEFT OUTER JOIN #tmpBalance b ON a.cost_center_dept_id=b.cost_center_dept_id 
	and b.VOUCHER_DT=a.opn_dt WHERE b.VOUCHER_DT IS NULL

	update a set balance=a.balance+(select sum(b.xn_amount) from #tmpbalance b 
	where b.cost_center_dept_id=a.cost_center_dept_id and b.VOUCHER_DT<=a.VOUCHER_DT)
	from #tmpBalance a

	TRUNCATE TABLE act_negativeCash

	--select * from #tmpBalance
	;with cte_negCash
	as
	(
	select cost_center_dept_id, voucher_dt,balance as cash_amount,row_number() over
	(partition by cost_center_dept_id order by voucher_dt) as rno from 
	#tmpBalance where balance<0
	)

	INSERT act_negativeCash	( cash_amount, cost_center_dept_id, voucher_dt )  
	SELECT cash_amount, cost_center_dept_id, voucher_dt FROM cte_negCash
	WHERE rno=1

END
