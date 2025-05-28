CREATE PROCEDURE SAVETRAN_POST_SORPAYMENTS
@nSpId VARCHAR(40),
@cloginDeptId VARCHAR(4),
@bStart BIT=0,
@cuserCode char(7)='0000000'
AS
BEGIN
BEGIN TRY
	DECLARE @cCmd NVARCHAR(MAX),@cStep VARCHAR(4), @CTEMPMASTERTABLE VARCHAR(200),@CTEMPDETAILTABLE VARCHAR(200),
			@cErrormsg VARCHAR(MAX),@cFinYear VARCHAR(5),@CTEMPDETAILTABLE2 VARCHAR(200),@nVendorAmt NUMERIC(10,2)
	

	SET @cStep='2'
	SET @CERRORMSG=''

	IF NOT EXISTS (SELECT TOP 1 * FROM SOR_PAYMENT_UPLOAD (NOLOCK) WHERE sp_id=@nSpId)
	BEGIN
		SET @cErrormsg='No data found for Posting .... '
		GOTO END_PROC
	END

	SET @cStep='4'
	declare @cBankAcCode CHAR(10),@cPartyAcCode char(10),@nPendingAmt NUMERIC(14,2),@nAdvadj NUMERIC(14,2)

	SELECT @cBankAcCode=bank_ac_code,@cPartyAcCode=(CASE WHEN AgnstSupplier=1 THEN b.ac_code else c.dept_ac_code END),
	@nVendorAmt=ISNULL(a.vendor_amount,b.VENDOR_AMOUNT),@nAdvadj=ISNULL(a.advance_adjusted,0),
	@nPendingAmt=ISNULL(a.payment_advice_amount,0)
	FROM SOR_PAYMENT_UPLOAD A (NOLOCK)
	JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	LEFT OUTER JOIN location c (NOLOCK) ON c.dept_id=b.party_dept_id
	WHERE sp_id=@nSpId
	
	IF @cBankAcCode IS NULL
	BEGIN
		SET @cErrormsg='No data found for Posting .... '
		GOTO END_PROC
	END
	
	
	IF @nVendorAmt=0 AND @nPendingAmt<>@nAdvadj
	BEGIN
		SET @cErrormsg='Paid amount cannot be zero .... '
		GOTO END_PROC		
	END		

	IF @nVendorAmt=0
		GOTO lblUpdate

	SET @cStep='7'
	IF ISNULL(@cBankAcCode,'') IN ('','0000000000')
	BEGIN
		SET @cErrormsg='Bank A/c cannot be left blank .... '
		GOTO END_PROC		
	END

	IF ISNULL(@cPartyAcCode,'') IN ('','0000000000')
	BEGIN
		SET @cErrormsg='Party A/c cannot be left blank .... '
		GOTO END_PROC		
	END		

	SET @cStep='10'
	CREATE TABLE #tSorPay (errmsg varchar(max))

lblUpdate:	

	BEGIN TRAN

	update a set payment_bank_ac_code=payment_bank_ac_code,chq_no=b.chq_no,
	payment_mode=b.payment_mode,payment_date=b.payment_date,remarks=b.remarks,
	advance_adjusted=b.advance_adjusted,VENDOR_AMOUNT=(CASE WHEN isnull(b.vendor_amount,0)<>0 
	THEN b.vendor_amount ELSE a.VENDOR_AMOUNT END)
	from eosssorm a JOIN SOR_PAYMENT_UPLOAD b ON a.memo_id=b.memo_id
	WHERE sp_id=@nSpId


	IF @nVendorAmt=0
		GOTO END_PROC

	SET @cStep='30'	
	EXEC SP_DELETEUPLOADTABLES
	@CXN_TYPE='vch',
	@NSPID=@nSpId

	SELECT @cFinYear='01'+dbo.fn_getfinyear(payment_date) FROM SOR_PAYMENT_UPLOAD a (NOLOCK) WHERE sp_id=@nSpId

	SET @cStep='40'
	INSERT INTO vch_vm01106_upload (sp_id,voucher_code,user_code,cancelled,fin_year,bill_id,dept_id,
	last_update,bill_no,bill_dt,bill_type,drtotal,crtotal,voucher_no,voucher_dt,vm_id,
	audited_user_code,audited_dt)
	SELECT @nSpId sp_id,'0000000002' voucher_code,@cuserCode user_code,0 cancelled,@cFinYear fin_year,
	a.memo_id bill_id,@cLoginDeptId dept_id,getdate() last_update,a.ref_no bill_no,
	a.payment_date bill_dt,'SOR' bill_type, a.vendor_amount drtotal,a.vendor_amount crtotal,
	'LATER' voucher_no,a.payment_date as voucher_dt,'later' as vm_id,'' audited_user_code,
	'' as audited_dt
	FROM SOR_PAYMENT_UPLOAD a (NOLOCK)
	JOIN eosssorm b on a.memo_id=b.memo_id 
	WHERE sp_id=@nSpId



	SET @cStep='50'
	INSERT INTO vch_postact_voucher_link_upload  (sp_id,vm_id,memo_id,xn_type,last_update)
	SELECT @nSpId sp_id,'LATER' vm_id,a.memo_id,'EOSSSOR' XN_TYPE,b.last_update
	FROM SOR_PAYMENT_UPLOAD a (NOLOCK) JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	WHERE sp_id=@nSpId

	
	SET @cStep='60'
	INSERT INTO  vch_vd01106_upload (sp_id,vm_id,vd_id,ac_code,credit_amount,debit_amount,narration,x_type,
	vs_ac_code,cost_center_dept_id,last_update)
	SELECT @nSpId sp_id,'LATER' vm_id,'later1' vd_id,(CASE WHEN AgnstSupplier=1 THEN b.ac_code else c.dept_ac_code END) as ac_code,
	0 credit_amount,a.vendor_amount debit_amount,isnull(a.remarks,'') narration,'Dr' x_type,
	'0000000000' vs_ac_code,@cloginDeptId cost_center_dept_id,getdate() last_update from 
	SOR_PAYMENT_UPLOAD a (NOLOCK) JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	LEFT OUTER JOIN location c (NOLOCK) ON c.dept_id=b.party_dept_id
	WHERE sp_id=@nSpId

	SET @cStep='65'
	INSERT INTO  vch_vd01106_upload (sp_id,vm_id,vd_id,ac_code,credit_amount,debit_amount,narration,x_type,
				vs_ac_code,cost_center_dept_id,last_update)
	SELECT @nSpId sp_id,'LATER' vm_id,'later2' vd_id,a.bank_ac_code as ac_code,
	a.vendor_amount credit_amount,0 debit_amount,isnull(a.remarks,'') narration,'Cr' x_type,
	'0000000000' vs_ac_code,@cloginDeptId cost_center_dept_id,getdate() last_update 
	FROM SOR_PAYMENT_UPLOAD a (NOLOCK) JOIN eosssorm b (NOLOCK) ON a.memo_id=b.memo_id
	WHERE sp_id=@nSpId

	SET @cStep='70'
	

	EXEC SAVETRAN_VOUCHERENTRY
	 @NUPDATEMODE=1,
	 @NSPID=@nSpId,
	 @CFINYEAR=@cFinYear,
	 @BCALLEDFROMSorPayments=1,
	 @CEDEPT_ID=@cloginDeptId

	SELECT TOP 1 @cErrormsg=errmsg FROM #tSorPay

	SET @cStep='75'
	EXEC SP_DELETEUPLOADTABLES	'VCH',@nSpId

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SAVETRAN_POST_SORPAYMENTS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

	IF @@TRANCOUNT > 0
	BEGIN
		IF ISNULL(@CERRORMSG,'') = ''
			commit
		ELSE		
			ROLLBACK
	END

	DELETE FROM SOR_PAYMENT_UPLOAD WITH (ROWLOCK) WHERE sp_id=@nSpId
	
	SELECT @cErrormsg as errmsg
END