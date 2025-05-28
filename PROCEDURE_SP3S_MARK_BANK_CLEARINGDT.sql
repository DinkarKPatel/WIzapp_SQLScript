CREATE PROCEDURE SP3S_MARK_BANK_CLEARINGDT
@nSpId VARCHAR(40)
AS
BEGIN
	DECLARE @cStep VARCHAR(4),@cCmd NVARCHAR(MAX)

	SET @CSTEP = 10
	DECLARE @nOnlineEntry INT=0,@cBankHeads VARCHAR(4000),@cCashHeads VARCHAR(4000)

	SET @cBankHeads=DBO.FN_ACT_TRAVTREE('0000000013') 
	SET @cCashHeads=DBO.FN_ACT_TRAVTREE('0000000014') 

	
	SELECT head_code INTO #tmpBankHeads FROM  hd01106 
	WHERE CHARINDEX(HEAD_CODE,@cBankHeads)> 0

	SELECT head_code INTO #tmpCashHeads FROM  hd01106 
	WHERE CHARINDEX(HEAD_CODE,@cCashHeads)> 0
	

	UPDATE VD WITH (ROWLOCK) SET VD.RECON_DT=VM.VOUCHER_DT
	FROM vch_vd01106_upload VD
	JOIN LM01106   A (NOLOCK)  ON VD.ac_code=A.ac_code
	JOIN vch_vm01106_upload vm (NOLOCK) ON  vd.sp_id=vm.sp_id
	JOIN #tmpBankHeads b ON b.head_code=a.head_code
	LEFT JOIN vch_vd01106_upload d (NOLOCK) ON d.vd_id=vd.vd_id AND d.sp_id=vd.sp_id
	WHERE vd.sp_id=@nSpid AND (d.vd_id IS NULL OR d.CHQ_PAY_MODE=2) AND vd.credit_amount<>0

	UPDATE VD_1 WITH (ROWLOCK) SET VD_1.RECON_DT=VM.VOUCHER_DT
	FROM vch_vd01106_upload VD_1
	JOIN LM01106  lm_1 (NOLOCK)  ON VD_1.ac_code=lm_1.ac_code
	JOIN vch_vm01106_upload vm (NOLOCK) ON vm.sp_id=vd_1.sp_id
	JOIN vch_vd01106_upload VD_2 (NOLOCK) ON vm.sp_id=vd_2.sp_id
	JOIN LM01106  lm_2 (NOLOCK)  ON VD_2.ac_code=lm_2.ac_code
	JOIN #tmpBankHeads b ON b.head_code=lm_1.head_code
	LEFT JOIN #tmpCashHeads c ON c.head_code=lm_2.head_code
	LEFT JOIN #tmpBankHeads d ON c.head_code=lm_2.head_code
	WHERE  vd_1.sp_id=@nSpid AND (vd_1.debit_amount<>0 AND c.head_code IS NOT NULL AND vd_2.credit_amount<>0) OR
	(vd_1.debit_amount<>0 AND d.head_code IS NOT NULL AND vd_2.credit_amount<>0)

END
