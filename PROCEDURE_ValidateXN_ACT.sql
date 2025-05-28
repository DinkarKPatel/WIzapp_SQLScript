create PROCEDURE VALIDATEXN_act ---- Do not overwrite in Release
(
		@CXNID VARCHAR(40),
		@NUPDATEMODE INT,					
		@CCMD VARCHAR(1000) OUTPUT
		--*** PARAMETERS :
		--*** @CXNID - TRANSACTION ID ( MEMO ID OF MASTER TABLE )
)
with  RECOMPILE 
AS
BEGIN
	BEGIN TRY
		DECLARE @NDRTOTAL NUMERIC(18,4), @NCRTOTAL NUMERIC(18,4),@cVchCode CHAR(10),@cAcCode CHAR(10),
				@nTotalCD NUMERIC(18,4),@cDiscAcCode CHAR(10),@nBBTotal NUMERIC(10,2),@nVdTotal NUMERIC(10,2),
				@cBBRefno VARCHAR(100),@nStoredAmt NUMERIC(10,2),@nCalcAmt NUMERIC(10,2),@cStep VARCHAR(10)
		
		set @cStep='10'
		DECLARE @CVMTABLE TABLE ( VM_ID VARCHAR(40),voucher_code char(10), VOUCHER_DT DATETIME, DRTOTAL NUMERIC(14,4), CRTOTAL NUMERIC(14,4) )


		
		DECLARE @CVDTABLE TABLE ( VD_ID VARCHAR(40), VM_ID VARCHAR(40), AC_CODE VARCHAR(10),
								  CREDIT_AMOUNT NUMERIC(18,4),credit_amount_forex NUMERIC(18,4), DEBIT_AMOUNT NUMERIC(18,4),debit_amount_forex NUMERIC(18,4),
								  ref_vd_id VARCHAR(40),forex_rate NUMERIC(10,2),billByBill BIT)
		
				
		DECLARE @cBbRefTable TABLE (vd_id VARCHAR(40),ref_no varchar(100),cd_amount NUMERIC(20,4),X_TYPE varchar(5),
									cd_posted BIT,cd_base_amount NUMERIC(20,4),amount NUMERIC(20,4),amount_forex NUMERIC(10,2),cd_percentage NUMERIC(6,2),
									org_bill_no VARCHAR(100),org_bill_amount NUMERIC(20,4),manual_cd BIT,ignore_cd_base_amount NUMERIC(20,4))
		
		set @cStep='20'
		INSERT @CVMTABLE (VM_ID, VOUCHER_DT,voucher_code, DRTOTAL, CRTOTAL)
		SELECT VM_ID, VOUCHER_DT,voucher_code, DRTOTAL, CRTOTAL FROM VM01106 (NOLOCK) WHERE VM_ID = @CXNID

		INSERT @CVDTABLE (VD_ID, VM_ID, AC_CODE, CREDIT_AMOUNT, DEBIT_AMOUNT,credit_amount_forex, debit_amount_forex,forex_rate,ref_vd_id,billByBill)
		SELECT VD_ID, VM_ID, a.AC_CODE, CREDIT_AMOUNT, DEBIT_AMOUNT,ISNULL(credit_amount_forex,0) credit_amount_forex,
		ISNULL(debit_amount_forex,0) debit_amount_forex ,forex_rate, ref_vd_id,c.BILL_BY_BILL
		FROM VD01106 a (NOLOCK)
		JOIN lmp01106 c (NOLOCK) ON c.AC_CODE=c.AC_CODE 
		WHERE VM_ID = @CXNID

		
		set @cStep='30'
		INSERT INTO @cBbRefTable (vd_id,ref_no,cd_amount,X_TYPE,cd_posted,cd_base_amount,amount,cd_percentage,
		org_bill_no,org_bill_amount,manual_cd,ignore_cd_base_amount)
		SELECT a.vd_id,ref_no,cd_amount,a.X_TYPE,cd_posted,ISNULL(a.cd_base_amount,0),amount,a.cd_percentage,
		a.org_bill_no,a.org_bill_amount,a.manual_cd,ISNULL(a.ignore_cd_base_amount,0) ignore_cd_base_amount
		FROM  bill_by_bill_ref a (NOLOCK)
		JOIN vd01106 b (NOLOCK) ON a.vd_id=b.vd_id
		JOIN lmp01106 c (NOLOCK) ON c.AC_CODE=b.AC_CODE
		WHERE b.vm_id=@CXNID and c.BILL_BY_BILL=1

		set @cStep='35'
		SELECT @cVchCode=voucher_code FROM  @CVMTABLE

		SELECT @NDRTOTAL = SUM(DEBIT_AMOUNT), @NCRTOTAL = SUM(CREDIT_AMOUNT) FROM @CVDTABLE

		IF ( ABS(@NDRTOTAL-@NCRTOTAL)>.01 )
			SET @CCMD = 'DEBIT AND CREDIT TOTALS DO NOT MATCH ....'
		
		IF @CCMD='' AND EXISTS (SELECT TOP 1 vd_id FROM @CVDTABLE WHERE credit_amount_forex+debit_amount_forex>0)
		BEGIN
			set @cStep='35.8'
			DECLARE @nStoredConvVdAmt NUMERIC(10,2),@nCalcConvVdAmt NUMERIC(10,2),@cForexAcName VARCHAR(400)

			IF EXISTS (SELECT TOP 1 vd_id FROM @CVDTABLE WHERE (ROUND((debit_amount_forex+credit_amount_forex)*FOREX_RATE,2)-
			(debit_amount+credit_amount))>.01)
			BEGIN
				set @cStep='36.2'
				SELECT TOP 1 @cForexAcName=AC_NAME, @nStoredConvVdAmt=(debit_amount+credit_amount),
				@nCalcConvVdAmt=ROUND((debit_amount_forex+credit_amount_forex)*FOREX_RATE,2)
				FROM @CVDTABLE a JOIN lm01106 b (NOLOCK) ON a.AC_CODE=b.AC_CODE WHERE (ROUND((debit_amount_forex+credit_amount_forex)*FOREX_RATE,2)-
				(debit_amount+credit_amount))>.01

				SET @CCMD = 'Mismatch in Conversion from Forex to INR amount for Ledger :'+@cForexAcName+' Stored : '+LTRIM(RTRIM(STR(@nStoredConvVdAmt,10,2)))+
				' Calculated :'+LTRIM(RTRIM(STR(@nCalcConvVdAmt,10,2)))

				GOTO END_PROC
			END

			set @cStep='36.5'
			IF EXISTS (SELECT TOP 1 a.vd_id FROM @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
						WHERE ABS(ROUND(amount_forex*FOREX_RATE,2)-amount)>.01)
			BEGIN
				set @cStep='36.8'
				SELECT TOP 1 @cBbREfno=a.ref_no, @cForexAcName=AC_NAME, @nStoredConvVdAmt=amount,
				@nCalcConvVdAmt=ROUND(amount_forex*FOREX_RATE,2)
				FROM @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
				JOIN lm01106 c (NOLOCK) ON c.AC_CODE=b.AC_CODE
				WHERE ABS(ROUND(amount_forex*FOREX_RATE,2)-amount)>.01

				SET @CCMD = 'Mismatch in Conversion from Forex to INR Bill by bill amount for Ledger :'+@cForexAcName+' Bill no.:'+@cBbREfno+
				' Stored : '+LTRIM(RTRIM(STR(@nStoredConvVdAmt,10,2)))+' Calculated :'+LTRIM(RTRIM(STR(@nCalcConvVdAmt,10,2)))

				GOTO END_PROC
			END

			set @cStep='37.2'
			SELECT @NDRTOTAL = SUM(debit_amount_forex), @NCRTOTAL = SUM(credit_amount_forex) FROM @CVDTABLE

			IF ( ABS(@NDRTOTAL-@NCRTOTAL)>.01 )
				SET @CCMD = 'FOREX DEBIT AND CREDIT TOTALS DO NOT MATCH ....'
		END

		set @cStep='40'
		IF @CCMD = '' AND NOT EXISTS ( SELECT VM_ID FROM @CVDTABLE )
			SET @CCMD = 'INVALID VOUCHER DETAIL SPECIFICATION....'

		IF @CCMD = '' AND EXISTS ( SELECT VM_ID FROM @CVDTABLE WHERE DEBIT_AMOUNT <= 0 AND CREDIT_AMOUNT <= 0 )
			SET @CCMD = 'INVALID AMOUNT SPECIFICATION AT VD LEVEL ....'

		IF @CCMD = '' AND EXISTS ( SELECT VM_ID FROM @CVDTABLE WHERE AC_CODE = '' OR AC_CODE = '0000000000' )
			SET @CCMD = 'INVALID LEDGER ACCOUNT SPECIFICATION AT VD LEVEL ....'
		
		IF @CCMD <> ''
			GOTO END_PROC
		
		set @cStep='50'
		IF EXISTS (SELECT TOP 1 a.vd_id FROM  vdt01106 a (NOLOCK) JOIN @CVDTABLE B on a.vd_id=b.VD_ID
				   LEFT JOIN  POSTACT_VOUCHER_LINK c (NOLOCK) ON c.vm_id=b.vm_id
				   WHERE c.vm_id IS NULL)
	    BEGIN
			set @cStep='60'
			DECLARE @cTdsBillNo VARCHAR(50),@dTdsBillDt DATETIME,@nTdsApplicableAmt NUMERIC(10,2),@nTdsBillAmt NUMERIC(10,2)

			SELECT TOP 1 @nTdsApplicableAmt=ISNULL(tds_applicable_amount,0),@nTdsBillAmt=ISNULL(tds_bill_amount,0)
			FROM  vdt01106 a (NOLOCK) JOIN @CVDTABLE B on a.vd_id=b.VD_ID
			
			set @cStep='70'
			IF @nTdsApplicableAmt=0
				SET @CCMD = 'Tds Applicable amount cannot be left blank ....'
			ELSE
			IF @nTdsBillAmt=0
				SET @CCMD = 'Tds Bill amount cannot be left blank ....'
		END

		IF @CCMD <> ''
			GOTO END_PROC
		
		IF @cVchCode='0000000002'
		BEGIN
			set @cStep='80'
			IF EXISTS (SELECT TOP 1 vd_id FROM @cBbRefTable WHERE cd_amount<>0)
			BEGIN

				SELECT TOP 1 @cAcCode=ac_code FROM @cVdTable a JOIN @cBbRefTable b ON a.VD_ID=b.vd_id
				AND DEBIT_AMOUNT<>0

				SELECT TOP 1 @cDiscAcCode=ac_code FROM @cVdTable a LEFT JOIN @cBbRefTable b ON a.VD_ID=b.vd_id
				WHERE ac_code<>@cAcCode AND ISNULL(ref_vd_id,'')<>'' AND b.vd_id IS NULL

				set @cStep='90'
				SELECT @nTotalCD=SUM(CASE WHEN x_type='Dr' THEN cd_amount ELSE -cd_amount END)
				FROM @cBbRefTable WHERE ISNULL(cd_posted,0)=0

				IF @nTotalCD<>0
				BEGIN
					set @cStep='100'
					IF  (NOT EXISTS (SELECT TOP 1 vd_id FROM  @CVDTABLE WHERE ISNULL(ref_vd_id,'')<>'' AND ac_code=@cDiscAcCode
									 AND ((CREDIT_AMOUNT<>0 AND @nTotalCD>0) OR (DEBIT_AMOUNT<>0 AND @nTotalCD<0)))
					  OR NOT EXISTS (SELECT TOP 1 vd_id FROM  @CVDTABLE WHERE ISNULL(ref_vd_id,'')<>''  AND ac_code=@cAcCode
									 AND ((CREDIT_AMOUNT<>0 AND @nTotalCD<0) OR (DEBIT_AMOUNT<>0 AND @nTotalCD>0))))
					BEGIN
						SET @CCMD = 'Reference entry of Cash discount/Party Account missing against CD deduction ....'
						GOTO END_PROC
					END
					
					set @cStep='110'
					---Older validation changed today (Date:16-09-2021)	
					--- due to cd entry not gone for debit notes due to Zero org_bill_amount gone
					--IF EXISTS (SELECT TOP 1 a.vd_id FROM  @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
					--		   JOIN @cBbRefTable c ON c.vd_id=b.ref_vd_id AND c.ref_no=a.ref_no
					--		   WHERE ABS(a.amount-round(((a.amount+c.amount)/c.org_bill_amount)*c.Cd_base_amount*c.Cd_percentage/100,0))>1 
					--		   AND ISNULL(a.manual_cd,0)=0)

					IF EXISTS (SELECT TOP 1 a.vd_id FROM   @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
					left join 
					(SELECT ref_no,ref_vd_id,amount FROM @cBbRefTable a 
					 JOIN @cVdTable c on c.vd_id=a.vd_id
					 WHERE ISNULL(c.ref_vd_id,'')<>'') d ON d.ref_vd_id=b.vd_id AND d.ref_no=a.ref_no
					WHERE (ABS(d.amount-round(((d.amount+a.amount+ISNULL(a.ignore_cd_base_amount,0))/a.org_bill_amount)*a.Cd_base_amount*a.Cd_percentage/100,0))>1 
							OR (d.ref_vd_id IS NULL AND ISNULL(a.Cd_percentage,0)<>0 AND a.cd_posted=0))
					AND ISNULL(b.ref_vd_id,'')=''  AND ISNULL(a.manual_cd,0)=0)
					BEGIN
						set @cStep='120'
						SELECT TOP 1 @cBBRefno=(CASE WHEN ISNULL(a.org_bill_no,'')<>'' THEN a.org_bill_no
						WHEN ISNULL(d.org_bill_no,'')<>'' THEN d.org_bill_no ELSE a.ref_no END),
						@nStoredAmt=d.amount,@nCalcAmt=round(((d.amount+a.amount+ISNULL(a.ignore_cd_base_amount,0))/a.org_bill_amount)*a.Cd_base_amount*a.Cd_percentage/100,0)
						--round(((a.amount+c.amount)/c.org_bill_amount)*c.Cd_base_amount*c.Cd_percentage/100,0)
						FROM   @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
						left join 
						(SELECT ref_no,ref_vd_id,amount,a.org_bill_no FROM @cBbRefTable a 
						 JOIN @cVdTable c on c.vd_id=a.vd_id
						 WHERE ISNULL(c.ref_vd_id,'')<>'') d ON d.ref_vd_id=b.vd_id AND d.ref_no=a.ref_no
						WHERE (ABS(d.amount-round(((d.amount+a.amount)/a.org_bill_amount)*a.Cd_base_amount*a.Cd_percentage/100,0))>1 
								OR (d.ref_vd_id IS NULL AND ISNULL(a.Cd_percentage,0)<>0 AND a.cd_posted=0))
						AND ISNULL(b.ref_vd_id,'')=''  AND ISNULL(a.manual_cd,0)=0

						set @cStep='130'
						SET  @cCmd='Mismatch in Reference entry of Cash discount for Bill no.:'+@cBBRefno+
								   ' Stored:'+LTRIM(RTRIM(STR(ISNULL(@nStoredAmt,0),10,2)))+' Calculated:'+LTRIM(RTRIM(STR(isnull(@nCalcAmt,0),10,2))) 
						GOTO END_PROC
					END
					

					---- This Validation is not possible If user pays the partial amount
					---- So I am discarding it for now till next discussion with Sir (Date:03-09-2021)
					--IF EXISTS (SELECT TOP 1 a.vd_id FROM  @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
					--		   JOIN @cBbRefTable c ON c.vd_id=b.ref_vd_id AND c.ref_no=a.ref_no
					--		   WHERE ABS(c.org_bill_amount-a.amount-c.amount)>1)
					--BEGIN
					--	SELECT TOP 1 @cBBRefno=(CASE WHEN ISNULL(c.org_bill_no,'')<>'' THEN c.org_bill_no
					--	WHEN ISNULL(a.org_bill_no,'')<>'' THEN a.org_bill_no ELSE a.ref_no END),
					--	@nStoredAmt=c.amount,@nCalcAmt=(c.org_bill_amount-a.amount)
					--	FROM  @cBbRefTable a JOIN @CVDTABLE b ON a.vd_id=b.VD_ID
					--	JOIN @cBbRefTable c ON c.vd_id=b.ref_vd_id AND c.ref_no=a.ref_no
					--	WHERE ABS(c.org_bill_amount-a.amount-c.amount)>1

					--	SET  @cCmd='Mismatch in Reference entry of Party Account against CD for Bill no.:'+@cBBRefno+
					--			   ' Stored:'+LTRIM(RTRIM(STR(@nStoredAmt,10,2)))+' Calculated:'+LTRIM(RTRIM(STR(@nCalcAmt,10,2))) 
					--	GOTO END_PROC
					--END
				END
			END
		END

		goto end_proc
	END TRY

	BEGIN CATCH
		SET @cCmd='Error in Procedure VALIDATEXN_ACT at Step#'+@cStep+' '+error_message()
		goto end_proc
	END CATCH
END_PROC:
END
--***************************************** END OF PROCEDURE VALIDATEXN_ACT
