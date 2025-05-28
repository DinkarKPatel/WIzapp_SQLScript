CREATE PROCEDURE SP3S_GET_CREDIT_LIMIT
(
	@cAcCode	VARCHAR(20),
	@cLOCID		VARCHAR(10)='',
	@cMemoId	VARCHAR(50)=''
)
AS
BEGIN
	SELECT ac_code,SUM(balance) balance
	FROM 
	(
	SELECT ac_code,SUM(net_amount) balance FROM inm01106 a (NOLOCK) 
	LEFT OUTER JOIN 
	(SELECT memo_id FROM POSTACT_VOUCHER_LINK a (NOLOCK)
	 JOIN  inm01106 b (NOLOCK) ON a.memo_id=b.inv_id
	 JOIN vm01106 c (NOLOCK) ON c.vm_id=a.vm_id
	 WHERE ac_code=@cAcCode AND xn_type='WSL' AND b.CANCELLED=0 AND c.cancelled=0
	 and Inv_id<>@cMemoId
	 ) b ON a.inv_id=b.memo_id
	 WHERE ac_code=@cAcCode AND cancelled=0 AND b.memo_id IS NULL
	 and Inv_id<>@cMemoId
	 GROUP BY ac_code
	
	UNION ALL
	SELECT ac_code,SUM(total_amount) balance FROM rmm01106 a (NOLOCK) 
	LEFT OUTER JOIN 
	(SELECT memo_id FROM POSTACT_VOUCHER_LINK a (NOLOCK)
	 JOIN  rmm01106 b (NOLOCK) ON a.memo_id=b.rm_id
	 JOIN vm01106 c (NOLOCK) ON c.vm_id=a.vm_id
	 WHERE ac_code=@cAcCode AND xn_type='PRT' AND b.CANCELLED=0 AND c.cancelled=0
	 ) b ON a.rm_id=b.memo_id
	 WHERE ac_code=@cAcCode AND cancelled=0 AND b.memo_id IS NULL
	 GROUP BY ac_code

	UNION ALL
	SELECT ac_code,SUM(total_amount)*-1 balance FROM cnm01106 a (NOLOCK) 
	LEFT OUTER JOIN 
	(SELECT memo_id FROM POSTACT_VOUCHER_LINK a (NOLOCK)
	 JOIN  cnm01106 b (NOLOCK) ON a.memo_id=b.cn_id
	 JOIN vm01106 c (NOLOCK) ON c.vm_id=a.vm_id
	 WHERE ac_code=@cAcCode AND xn_type='WSR' AND b.CANCELLED=0 AND c.cancelled=0
	 ) b ON a.rm_id=b.memo_id
	 WHERE ac_code=@cAcCode AND cancelled=0 AND b.memo_id IS NULL
	 GROUP BY ac_code

    UNION ALL
	SELECT AC_CODE,SUM(BALANCE) AS BALANCE 
	FROM LOC_LEDGER_BALANCE A (NOLOCK)
	WHERE AC_CODE =@cAcCode
	GROUP BY AC_CODE
	) a GROUP BY ac_code
END
--EXEC SP3S_GET_CREDIT_LIMIT ''