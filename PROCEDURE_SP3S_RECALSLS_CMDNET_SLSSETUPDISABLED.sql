CREATE PROCEDURE SP3S_RECALSLS_CMDNET_SLSSETUPDISABLED
@nSpId VARCHAR(40),
@CCUSTCODE CHAR(12),
@dXnDt DATETIME,
@bDonotPickCardDisc bit,
@BMRPEXCHANGEBILL BIT,
@cLocationId VARCHAR(5),
@CERRORMSG VARCHAR(MAX) OUTPUT

AS
BEGIN
	---- We need to call this procedure from Savetran If User presses Ctrl+s or Sales setup not in effect
	DECLARE @nStep VARCHAR(10),@BPICKCARDDISCFORSOLDITEMS BIT ,@CPickRoundITEMLEVELFromLoc VARCHAR(2) ,@CROUNDITEMLEVEL VARCHAR(2)
	IF @bDonotPickCardDisc=0 
	BEGIN
		SET @nSTEP='118.5'
		EXEC SP_CHKXNSAVELOG 'SLS_TMP',@nStep,0,@NSPID,1
		
		SET @BPICKCARDDISCFORSOLDITEMS=0

		IF @BMRPEXCHANGEBILL=0
			SET @BPICKCARDDISCFORSOLDITEMS=1

		EXEC SP_GETCARD_DISCOUNT_PERCETAGE
		@CCUSTOMERCODE=@CCUSTCODE,
		@DREFMEMODT=@DXNDT,
		@CPARACODE='',
		@BCALLEDFROMSALESETUPPROC=1,
		@BPICKCARDDISCFORSOLDITEMS=@BPICKCARDDISCFORSOLDITEMS,
		@BCALLEDFROMCASHMEMO=1,
		@bSalesSetupInEffect=0,
		@NSPID=@NSPID,
		@CERRORMSG=@CERRORMSG OUTPUT
			
		IF ISNULL(@CERRORMSG,'')<>''
			GOTO END_PROC
	END

	UPDATE sls_cmd01106_upload WITH (ROWLOCK) SET discount_amount=ISNULL(BASIC_DISCOUNT_AMOUNT,0)+ISNULL(CARD_DISCOUNT_AMOUNT,0)
	WHERE sp_id=@nSpId

	SELECT TOP 1 @CPickRoundITEMLEVELFromLoc = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='Pick_SLS_ROUND_OFF_fromloc'
	
	if isnull(@CPickRoundITEMLEVELFromLoc,'')<>'1'
		SELECT TOP 1 @CROUNDITEMLEVEL = VALUE  FROM CONFIG WHERE  CONFIG_OPTION='SLS_ROUND_ITEM_NET'
	ELSE
		SELECT TOP 1 @CROUNDITEMLEVEL = sls_round_item_level  FROM location (NOLOCK) WHERE dept_id=@cLocationId

	SET @CROUNDITEMLEVEL=ISNULL(@CROUNDITEMLEVEL,'')
	
	--- No need to store item_round_off column value in case of Manual Bill saving (Date : 22-03-2023 WizTickit#0323-00120)
	--- (Discussed with pankaj & Sir as per issue coming at Da milano Dubai location, We need not to store item round off
	---  as per decision in the meeting by Sir)
	UPDATE sls_cmd01106_upload WITH (ROWLOCK) SET ITEM_ROUND_OFF=0	
	WHERE sp_id=@nSpId

	IF @CROUNDITEMLEVEL='1'
		UPDATE sls_cmd01106_upload WITH (ROWLOCK) SET basic_discount_amount=round(basic_discount_amount,0),
		discount_amount=round(basic_discount_amount,0)+card_discount_amount
		WHERE sp_id=@nSpId AND ISNULL(manual_discount,0)=0 AND ISNULL(manual_dp,0)=0
		
	
	UPDATE sls_cmd01106_upload WITH (ROWLOCK) SET NET=((MRP*QUANTITY)-DISCOUNT_AMOUNT)
	WHERE sp_id=@nSpId

END_PROC:

END