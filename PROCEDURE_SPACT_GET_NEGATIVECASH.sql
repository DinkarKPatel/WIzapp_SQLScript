CREATE PROCEDURE SPACT_GET_NEGATIVECASH
@nQueryId NUMERIC(1,0)
AS
BEGIN
	IF @nQueryId=1
		SELECT MIN(voucher_dt) cash_neg_dt FROM act_negativeCash
	ELSE
	IF @nQueryId=2
		SELECT cost_center_dept_id AS [Location],CONVERT(VARCHAR(20),voucher_dt,105) AS [Date],cash_amount AS [Amount]
		FROM act_negativeCash ORDER BY cost_center_dept_id,voucher_dt
END
