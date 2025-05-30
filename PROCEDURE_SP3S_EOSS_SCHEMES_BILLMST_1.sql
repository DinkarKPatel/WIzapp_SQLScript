CREATE PROCEDURE SP3S_EOSS_SCHEMES_BILLMST_1
@CSCHEMEDETROWID VARCHAR(50),
@nSpId VARCHAR(50),
@CERRORMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @NBILLAMOUNT NUMERIC(10,2),@NDISCOUNTFIGURE NUMERIC(6,2),@BAPPLYSCHEMEONNONEOSSITEMS BIT,
			@NDISCMETHOD INT,@BAPPLYCARDDISCOUNT BIT,@CSTEP VARCHAR(5)
	
BEGIN TRY
	
	SET @CSTEP='10'
	
	PRINT 'ENTER SP3S_EOSS_SCHEMES_BILLMST_1'
	SET @CERRORMSG = ''
	SELECT @NBILLAMOUNT=subtotal FROM  SLS_CMM01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId
	
	SET @CSTEP='20'

	SELECT TOP 1 @NDISCOUNTFIGURE=DISCOUNT_FIGURE,@NDISCMETHOD=DISC_METHOD,
	@BAPPLYSCHEMEONNONEOSSITEMS=APPLY_BILLLEVELSCHEME_ON_NONEOSS_ITEMS,
	@BAPPLYCARDDISCOUNT=APPLY_CARD_DISCOUNT_IF_BILLLEVELSCHEME_APPLICABLE
	FROM SCHEME_SETUP_SCHB001_1 A  JOIN SCHEME_SETUP_DET B ON A.SCHEME_SETUP_DET_ROW_ID=B.ROW_ID
	WHERE SCHEME_SETUP_DET_ROW_ID=@CSCHEMEDETROWID AND @NBILLAMOUNT BETWEEN FROM_AMOUNT AND TO_AMOUNT
	

	--if @@spid=127
	--	select @NBILLAMOUNT
	--SELECT 'CHECK BUY MORE PAY LESS SCHEME',* FROM #TMPCMD
	
	--SELECT 'CHECK BUY MORE PAY LESS SCHEME',@CSCHEMEDETROWID,@NBILLAMOUNT,@NDISCOUNTFIGURE
			    
	IF ISNULL(@NDISCOUNTFIGURE,0)<>0
	BEGIN
		SET @CSTEP='30'
		IF @NDISCMETHOD=1
			UPDATE #TMPSlsDiscTaxOpt SET BILL_LEVEL_DISCOUNT_PERCENTAGE=@NDISCOUNTFIGURE,
			BILL_LEVEL_DISCOUNT_AMOUNT=@NBILLAMOUNT*@NDISCOUNTFIGURE/100
		ELSE
		BEGIN
			SET @CSTEP='40'
			UPDATE #TMPSlsDiscTaxOpt SET BILL_LEVEL_DISCOUNT_AMOUNT=(CASE WHEN @NDISCOUNTFIGURE<@NBILLAMOUNT THEN 
			@NDISCOUNTFIGURE ELSE @NBILLAMOUNT END)
			
			UPDATE #TMPSlsDiscTaxOpt SET BILL_LEVEL_DISCOUNT_PERCENTAGE=ROUND((BILL_LEVEL_DISCOUNT_AMOUNT/@NBILLAMOUNT)*100,3)
		END	

		UPDATE SLS_CMD01106_UPLOAD  SET Slsdet_ROW_ID=(CASE WHEN ISNULL(Slsdet_ROW_ID,'')='' THEN @CSCHEMEDETROWID ELSE 
						   Slsdet_ROW_ID END)
		WHERE sp_id=@nSpId
		
		PRINT 'BILL LEVEL DISCOUNT FINALLY APPLIED'
		SET @CSTEP='50'
		IF ISNULL(@BAPPLYCARDDISCOUNT,0)=0 AND EXISTS (SELECT TOP 1 PRODUCT_CODE FROM SLS_CMD01106_UPLOAD 
			WHERE sp_id=@nSpId AND ISNULL(CARD_DISCOUNT_PERCENTAGE,0)<>0)
			UPDATE SLS_CMD01106_UPLOAD SET CARD_DISCOUNT_PERCENTAGE=0 WHERE 
			sp_id=@nSpId AND ISNULL(CARD_DISCOUNT_PERCENTAGE,0)<>0
		
	END	

	--if @@spid=139
	--SELECT 'check bill scheme applied',BILL_LEVEL_DISCOUNT_PERCENTAGE,BILL_LEVEL_DISCOUNT_AMOUNT from #tmpcmd
END TRY

BEGIN CATCH
	SET @CERRORMSG = 'PROCEDURE SP3S_EOSS_SCHEMES_BILLMST_1 : STEP- ' + @CSTEP + ' SQL ERROR: #' + LTRIM(STR(ERROR_NUMBER())) + ' ' + ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
END
