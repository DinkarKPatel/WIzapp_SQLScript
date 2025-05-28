CREATE PROCEDURE SP3S_SYNCH_LEDGERBALANCES
AS
BEGIN
	
	DECLARE @CDONOTPICKOBHEADS VARCHAR(MAX),@cFinYear VARCHAR(5)

	SET @cFinYear='01'+dbo.fn_getfinyear(getdate())

	SELECT @CDONOTPICKOBHEADS=DBO.FN_ACT_TRAVTREE('0000000010')      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS+DBO.FN_ACT_TRAVTREE( '0000000017' )      
	SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')    

	SELECT cost_center_dept_id as dept_id,a.ac_code,SUM(debit_amount-credit_amount) as balance INTO #tmpBal
	 FROM vd01106 a (NOLOCK)
	 JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id
	 JOIN lm01106 c (NOLOCK) ON c.ac_code=a.ac_code
	 WHERE (fin_year=@cFinYear OR charindex(head_code,@CDONOTPICKOBHEADS)=0) AND cancelled=0
	 GROUP BY cost_center_dept_id,a.ac_code

	UPDATE loc_ledger_balance SET balance=b.balance FROM loc_ledger_balance a WITH (ROWLOCK)
	JOIN #tmpBal b ON a.ac_code=b.AC_CODE AND a.dept_id=b.dept_id

    INSERT loc_ledger_balance	( ac_code, balance, dept_id )  
	SELECT 	a.ac_code, a.balance, a.dept_id FROM #tmpBal a 
	LEFT OUTER JOIN  loc_ledger_balance B (nolock) on a.AC_CODE=b.ac_code AND a.dept_id=b.dept_id
	WHERE b.dept_id IS NULL

END