CREATE PROCEDURE SP3S_UPDATE_LEDGERBALANCES
@nUpdateMode NUMERIC(1,0),
@cTableName VARCHAR(200)='',
@cVmId VARCHAR(50)=''
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@nMultiple NUMERIC(1,0)

	SET @nMultiple=(CASE WHEN @nUpdateMode=1 THEN 1 ELSE -1 END)

	IF @cTableName=''
	BEGIN
		 SELECT cost_center_dept_id,a.ac_code,debit_amount,credit_amount INTO #tmpBal
		 FROM vd01106 a (NOLOCK)
		 WHERE vm_id=@cVmId
		 
		 SET @cTableName='#tmpBal'
	END
	
	--select 'check tmpbal',* from #tmpBal

	--select 'before cancel',* from loc_ledger_balance where ac_code='HO00001488'
	SET @cCmd=N'UPDATE a SET balance=a.balance+b.balance FROM loc_ledger_balance a WITH (ROWLOCK)
	JOIN (SELECT cost_center_dept_id as dept_id,ac_code,SUM(debit_amount-credit_amount)*'+str(@nMultiple)+' as balance
		  FROM '+@cTableName+' 
		  GROUP BY cost_center_dept_id ,ac_code) b ON a.AC_CODE=b.ac_code AND a.dept_id=b.dept_id'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
	--select 'after cancel',* from loc_ledger_balance where ac_code='HO00001488'

	IF @nUpdateMode=1
	BEGIN
		SET @cCmd=N'INSERT loc_ledger_balance	( ac_code, balance, dept_id )  
		SELECT 	a.ac_code, a.balance, a.dept_id FROM
		(SELECT cost_center_dept_id as dept_id,ac_code,SUM(debit_amount-credit_amount) as balance
		  FROM '+@cTableName+' 
		  GROUP BY cost_center_dept_id,ac_code) a 
		LEFT OUTER JOIN  loc_ledger_balance B (nolock) on a.AC_CODE=b.ac_code AND a.dept_id=b.dept_id
		WHERE b.dept_id IS NULL'

		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

	END
END