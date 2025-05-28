CREATE PROCEDURE SP3S_GET_TCS_VCH_AUTOENTRIES
@nReceiptAmt NUMERIC(10,2),
@cAcCode CHAR(10),
@dVchDt DATETIME,
@cLocId VARCHAR(5)
AS
BEGIN
	
BEGIN TRY
	
	DECLARE @cTcsAcCode CHAR(10),@cStep VARCHAR(4),@cErrormsg VARCHAR(500),@nTcsAmount NUMERIC(10,2),
			@bTcsApplicable BIT,@NPARTY_AMOUNT_FORTCS NUMERIC(14,2),@cfinyear VARCHAR(5),@cSourceGstNo VARCHAR(20),
			@cTargetGstNo VARCHAR(20)

	SET @cStep='10'
	SET @bTcsApplicable=0

	CREATE TABLE #TMSTTABLE (inv_mode NUMERIC(1,0),AC_CODE CHAR(10),INV_DT DATETIME,TCS_baseAmount numeric(14,2),
	TCS_PERCENtAgE NUMERIC (6,2),TCS_AMOUNT NUMERIC(10,2),PARTY_DEPT_ID VARCHAR(5))

	DECLARE @tPartyTcsBase TABLE (party_amount_for_tcs NUMERIC(14,2))

	SET @cStep='15'
	SET @cfinyear='01'+dbo.FN_GETFINYEAR(@dVchDt)
	SELECT @cSourceGstNo=loc_gst_no FROM location (NOLOCK) WHERE dept_id=@cLocId
	SELECT @cTargetGstNo=ac_gst_no FROM lmp01106 (NOLOCK) WHERE ac_code=@cAcCode

	SET @cStep='20'
	INSERT INTO @tPartyTcsBase (party_amount_for_tcs)
	EXEC SP3S_Get_Tcs_baseAmount
	 @CsourceGstNo=@cSourceGstNo,
	 @CtargetGstNo=@cTargetGstNo,
	 @cfinyear=@cfinyear,
	 @DINVDT=@dVchDt,
	 @cAc_code=@cAcCode,
	 @bCalledFromVchEntry=1	
	
	SELECT @NPARTY_AMOUNT_FORTCS=party_amount_for_tcs FROM @tPartyTcsBase

	SET @NPARTY_AMOUNT_FORTCS=ISNULL(@NPARTY_AMOUNT_FORTCS,0)

	SET @cStep='25'
	INSERT INTO #TMSTTABLE (inv_mode,ac_code,inv_dt)
	SELECT 1 inv_mode,@cAcCode ac_code,@dVchDt inv_dt

	SET @cStep='30'
	EXEC SP3S_TCSCAL 
	@CXNTYPE='VCH',
	@CLOCID=@CLOCID,
	@NTAXABLEVALUE=@nReceiptAmt,
	@NPARTY_AMOUNT_FORTCS=@NPARTY_AMOUNT_FORTCS,
	@CERRORMSG=@CERRORMSG OUTPUT

	IF ISNULL(@cErrormsg,'')<>''
		GOTO END_PROC
	
	SELECT @nTcsAmount=tcs_amount FROM  #TMSTTABLE

	IF ISNULL(@nTcsAmount,0)<>0
	BEGIN
		SET @cStep='35'
		SELECT TOP 1 @cTcsAcCode=tcs_receivable_ac_code FROM TCS_MST (NOLOCK) 
		WHERE wef<=@dVchDt ORDER BY wef DESC

		IF ISNULL(@cTcsAcCode,'') IN ('','0000000000')
		BEGIN
			SET @cStep='40'
			SET @cErrormsg='Tcs Receivable account not defined in TCS Setup...Please check'
			GOTO END_PROC
		END
		
		IF NOT EXISTS (SELECT TOP 1 ac_code FROM lm01106 (NOLOCK) WHERE ac_code=@cTcsAcCode)
		BEGIN
			SET @cStep='45'
			SET @cErrormsg='Invalid Tcs Receivable account defined in TCS Setup...Please check'
			GOTO END_PROC
		END

		SET @cStep='50'

		SELECT @cAcCode AC_CODE,@nTcsAmount as debit_amount,0 as credit_amount,
		AC_NAME,BILL_BY_BILL,HEAD_CODE,ISNULL(CREDIT_DAYS,0) AS CR_DAYS, 
		0 AS DISCOUNT_PERCENTAGE,PRINT_NAME,TDS_CODE,PAN_NO, 
		AC_NAME AS REPL_AC_NAME ,ISNULL(B.ON_HOLD,0) AS ON_HOLD FROM lm01106 a (NOLOCK)
		LEFT JOIN lmp01106 b (NOLOCK) ON a.ac_code=b.ac_code
		WHERE a.ac_code=@cAcCode
		UNION ALL
		SELECT @cTcsAcCode ac_code,0 as debit_amount,@nTcsAmount as credit_amount,
		AC_NAME,ISNULL(BILL_BY_BILL,0),HEAD_CODE,ISNULL(CREDIT_DAYS,0) AS CR_DAYS, 
		0 AS DISCOUNT_PERCENTAGE,ISNULL(PRINT_NAME,''),ISNULL(TDS_CODE,''),ISNULL(PAN_NO,''), 
		AC_NAME AS REPL_AC_NAME ,ISNULL(B.ON_HOLD,0) AS ON_HOLD FROM lm01106 a (NOLOCK)
		LEFT JOIN lmp01106 b (NOLOCK) ON a.ac_code=b.ac_code
		WHERE a.ac_code=@cTcsAcCode
		
		SET @bTcsApplicable=1
	END	
	
	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_GET_TCS_VCH_AUTOENTRIES at Step#'+@cStep+' '+error_message()
	SET @bTcsApplicable=0
	GOTO END_PROC
END CATCH

END_PROC:
	
	SELECT ISNULL(@cErrormsg,'') as errmsg,@bTcsApplicable tcs_applicable 
	
END