CREATE PROCEDURE SP3S_PROCESS_BILL_BY_BILL_ENTRIES
@nSpId VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cStep VARCHAR(5)
	
BEGIN TRY
	SET @cStep='10'
	
	SET @cErrormsg=''
	---- Removed this code after discussion with Rohit/Ved as he told that Application will handle this (Date:08-06-2021)
	--IF EXISTS (SELECT TOP 1 sp_id from vch_vd01106_upload a (NOLOCK)
	--		   JOIN lmp01106 b (NOLOCK) ON a.ac_code=b.ac_code
	--		   WHERE sp_id=@nSpId AND ISNULL(ref_vd_id,'')<>'' AND ISNULL(bill_by_bill,0)=1)
	--BEGIN
	--	SET @cStep='15'
	--	IF EXISTS (SELECT TOP 1 a.ref_no FROM vch_bill_by_bill_ref_upload A with (rowlock)
	--			   JOIN vch_vd01106_upload B (NOLOCK) ON A.VD_ID=B.VD_ID and a.sp_id=b.sp_id
	--			   WHERE a.sp_id=@nSpId AND ISNULL(b.ref_vd_id,'')<>'')
	--		DELETE A FROM vch_bill_by_bill_ref_upload A with (rowlock)
	--		JOIN vch_vd01106_upload B (NOLOCK) ON A.VD_ID=B.VD_ID and a.sp_id=b.sp_id
	--		JOIN lmp01106 c (NOLOCK) ON c.ac_code=b.ac_code
	--		WHERE a.sp_id=@nSpId AND ISNULL(ref_vd_id,'')<>'' AND ISNULL(bill_by_bill,0)=1
				  

	--	SET @cStep='20'
	--	INSERT INTO vch_bill_by_bill_ref_upload
	--					(sp_id,VD_ID,REF_NO,AMOUNT,LAST_UPDATE,X_TYPE,CR_DAYS,due_dt)
	--	SELECT @nSpId sp_id,A.VD_ID,d.REF_NO, (a.CREDIT_AMOUNT+a.DEBIT_AMOUNT) amount,GETDATE() AS LAST_UPDATE
	--			,(CASE WHEN A.CREDIT_AMOUNT>0 THEN 'CR' ELSE 'DR' END) AS X_TYPE
	--			,0 AS CR_DAYS,'' AS due_dt
	--	FROM vch_vd01106_upload A (NOLOCK)
	--	JOIN vch_vm01106_upload B (NOLOCK) ON A.VM_ID=B.VM_ID and a.sp_id=b.sp_id
	--	JOIN vch_vd01106_upload c (NOLOCK) ON c.vd_id=a.ref_vd_id AND c.sp_id=a.sp_id
	--	JOIN vch_bill_by_bill_ref_upload d (NOLOCK) ON d.vd_id=c.vd_id AND d.sp_id=c.sp_id
	--	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=a.ac_code
	--	WHERE a.sp_id=@nSpId AND ISNULL(a.ref_vd_id,'')<>'' AND ISNULL(bill_by_bill,0)=1
		
	--	SET @cStep='22'
	--	UPDATE e  WITH (ROWLOCK) 
	--	SET amount=a.credit_amount+a.debit_amount,x_type=(CASE WHEN A.CREDIT_AMOUNT>0 THEN 'CR' ELSE 'DR' END)
	--	FROM vch_bill_by_bill_ref_upload e
	--	JOIN vch_vd01106_upload A (NOLOCK) ON e.vd_id=a.vd_id and a.sp_id=e.sp_id
	--	JOIN vch_vm01106_upload B (NOLOCK) ON A.VM_ID=B.VM_ID and a.sp_id=b.sp_id
	--	JOIN vch_vd01106_upload c (NOLOCK) ON a.vd_id=c.ref_vd_id AND c.sp_id=a.sp_id
	--	JOIN lmp01106 lmp (NOLOCK) ON lmp.ac_code=a.ac_code
	--	WHERE a.sp_id=@nSpId  AND ISNULL(bill_by_bill,0)=1
	--END

	SET @cStep='25'
	IF EXISTS (SELECT TOP 1 sp_id from vch_bill_by_bill_ref_upload (NOLOCK) WHERE sp_id=@nSpId)
	BEGIN
				
		SET @cStep='30'
		DELETE A FROM vch_bill_by_bill_ref_upload A WITH (ROWLOCK)
		LEFT OUTER JOIN vch_vd01106_upload B (NOLOCK) ON A.VD_ID=B.VD_ID AND a.sp_id=b.sp_id
		LEFT OUTER JOIN LMP01106 C ON C.AC_CODE=B.AC_CODE
		WHERE a.sp_id=@nSpid AND ( AMOUNT=0 OR ISNULL(C.BILL_BY_BILL,0)=0	OR B.VD_ID IS NULL)
				
	END				
			
	SET @cStep='35'
	/*IF CREDIT DAYS IN BILL_BY_BILL_REF TABLE IS 0,UPDATE THE VALUE FROM LEDGER MASTER*/
	UPDATE A WITH (ROWLOCK)
				SET CR_DAYS = (CASE WHEN ISNULL(A.CR_DAYS,0)=0 THEN ISNULL(C.CREDIT_DAYS,0) ELSE A.CR_DAYS END),
				due_dt=ISNULL(due_dt,'')
				FROM vch_bill_by_bill_ref_upload A
				JOIN vch_vd01106_upload B (NOLOCK) ON A.VD_ID=B.VD_ID AND a.sp_id=b.sp_id
				JOIN LMP01106 C (NOLOCK) ON B.AC_CODE=C.AC_CODE
	WHERE a.sp_id=@nSpId

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_PROCESS_BILL_BY_BILL_ENTRIES at Step#'+@cStep+' '+error_message()
	GOTO END_PROC
END CATCH

END_PROC:

END