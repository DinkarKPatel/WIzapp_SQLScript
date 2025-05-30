CREATE FUNCTION FN_ACT_OPENING_NEW ( @CACCODE VARCHAR(20), @CDEPTID VARCHAR(5), @DOPENINGDT DATETIME, @CFINYEAR VARCHAR(10), @CCOMPANYCODE VARCHAR(2) )
RETURNS NUMERIC(14,2)
AS 
BEGIN
	DECLARE @NOPENING NUMERIC(14,2), 
			@CSTOCKINHANDTREE VARCHAR(2000),
			@CDONOTPICKOBHEADS VARCHAR(2000),
			@CHEADCODE VARCHAR(10),
			@CMINFINYEAR VARCHAR(10),@CPICKPROFILTLOSSHEADS VARCHAR(2),@CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS VARCHAR(2),
			@CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS VARCHAR(2)			

	SELECT TOP 1 @CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS=VALUE FROM  CONFIG WHERE CONFIG_OPTION='DONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS'
	SELECT TOP 1 @CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS=VALUE FROM  CONFIG WHERE CONFIG_OPTION='CONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS'

	SELECT @CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS=ISNULL(@CDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS,''),
		   @CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS=ISNULL(@CCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS,'')
		   	
	SET @NOPENING = 0

	-- TEMP TABLE TO STORED THE LIST OF LOCATIONS CURRENTLY SELECTED
	-- JOIN THIS TABLE IN EACH QUERY TO GET THE RESULT FOR SINGLE, MULTIPLE OR ALL LOCATIONS
	DECLARE @LOCLISTC TABLE ( DEPT_ID CHAR(5) )
	
	IF @CDEPTID <> ''
		INSERT @LOCLISTC VALUES ( @CDEPTID )
	ELSE
	BEGIN
		IF EXISTS ( SELECT TOP 1 DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @@SPID AND dept_id<>'' )
			INSERT @LOCLISTC
			SELECT DEPT_ID FROM ACT_FILTER_LOC WHERE SP_ID = @@SPID
		ELSE
			INSERT @LOCLISTC
			SELECT DEPT_ID FROM LOCATION WHERE LOC_TYPE=1 AND DEPT_ID=MAJOR_DEPT_ID
	END

	--*** SPECIAL CONSIDERATION FOR "STOCK IN HAND" HEADS
	--*** IN CASE OF "STOCK IN HAND" HEADS, RETURN OB ONLY FROM LOCOB TABLE
	--*** AND DO NOT PROCESS THROUGH VM AND VD
	SELECT @CDONOTPICKOBHEADS = DBO.FN_ACT_TRAVTREE('0000000010')

	SELECT TOP 1 @CPICKPROFILTLOSSHEADS=VALUE FROM CONFIG WHERE CONFIG_OPTION='PICK_PROFITLOSS_HEADS'
	IF ISNULL(@CPICKPROFILTLOSSHEADS,'')<>'1'
		SELECT @CDONOTPICKOBHEADS = @CDONOTPICKOBHEADS + ', '+DBO.FN_ACT_TRAVTREE('0000000009')

	SELECT @CSTOCKINHANDTREE = DBO.FN_ACT_TRAVTREE( '0000000017' )
	SELECT @CHEADCODE = HEAD_CODE FROM LM01106 WHERE AC_CODE = @CACCODE

	IF ( CHARINDEX( @CHEADCODE, @CDONOTPICKOBHEADS ) > 0 )
	BEGIN
		SET @NOPENING = 0
		-- ADDING FROM TRANSACTIONS
			SELECT @NOPENING = ISNULL(@NOPENING,0) + ISNULL( SUM(A.DEBIT_AMOUNT) - SUM(A.CREDIT_AMOUNT), 0 )
			FROM VD01106 A
			JOIN VM01106 B ON B.VM_ID = A.VM_ID
			JOIN @LOCLISTC LOCLIST ON A.COST_CENTER_DEPT_ID = LOCLIST.DEPT_ID
			JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE
			JOIN VCHTYPE D ON D.VOUCHER_CODE=B.VOUCHER_CODE
			LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=b.vm_id
			LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=b.vm_id			
			WHERE (A.AC_CODE = @CACCODE OR LM.MAJOR_AC_CODE=@CACCODE)
			AND B.CANCELLED = 0 AND ISNULL(B.OP_ENTRY,0)=0 AND ISNULL(B.MEMO,0)=0 AND A.COMPANY_CODE = @CCOMPANYCODE 
			AND B.FIN_YEAR = @CFINYEAR
			AND B.VOUCHER_DT < @DOPENINGDT
			AND (d.VOUCHER_CODE NOT IN ('MEMO000001','MEMO000002') OR @cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS<>'1')
			AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
				 (@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS='1' AND @cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS<>'1'))					
				 			
		GOTO END_PROC
	END

NEXT_PROC:

	IF @DOPENINGDT <> '' -- AND ( CHARINDEX( @CHEADCODE, @CSTOCKINHANDTREE ) = 0 )
	BEGIN
		-- ADDING FROM TRANSACTIONS
			SELECT @NOPENING = ISNULL(@NOPENING,0) + ISNULL( SUM(A.DEBIT_AMOUNT) - SUM(A.CREDIT_AMOUNT), 0 )
			FROM VD01106 A
			JOIN VM01106 B ON B.VM_ID = A.VM_ID
			JOIN @LOCLISTC LOCLIST ON A.COST_CENTER_DEPT_ID = LOCLIST.DEPT_ID
			JOIN LM01106 LM (NOLOCK) ON LM.AC_CODE=A.AC_CODE
			JOIN VCHTYPE D ON D.VOUCHER_CODE=B.VOUCHER_CODE
			LEFT OUTER JOIN acc_memo_reversal amr1 (NOLOCK) ON amr1.memo_vm_id=b.vm_id
			LEFT OUTER JOIN acc_memo_reversal amr2 (NOLOCK) ON amr2.reversal_vm_id=b.vm_id						
			WHERE (A.AC_CODE = @CACCODE OR LM.MAJOR_AC_CODE=@CACCODE)
			AND B.CANCELLED = 0 AND ISNULL(B.MEMO,0)=0 AND ( ISNULL(B.OP_ENTRY,0)=0 OR @CFINYEAR > B.FIN_YEAR )
			AND A.COMPANY_CODE = @CCOMPANYCODE 
			-- AND B.FIN_YEAR = @CFINYEAR
			AND B.VOUCHER_DT < @DOPENINGDT
			AND (d.VOUCHER_CODE NOT IN ('MEMO000001','MEMO000002') OR @cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS<>'1')
			AND ((amr1.memo_vm_id IS NULL AND amr2.memo_vm_id IS NULL) OR 
				 (@cCONSIDER_MEMO_REVERSAL_VOUCHERS_ACCBOOKS='1' AND @cDONOT_CONSIDER_MEMO_VOUCHERS_ACCBOOKS<>'1'))					
	END

END_PROC:
	RETURN ISNULL(@NOPENING,0)
END
