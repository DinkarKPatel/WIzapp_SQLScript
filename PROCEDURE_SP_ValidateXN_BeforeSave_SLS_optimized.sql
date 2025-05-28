CREATE  PROCEDURE SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED
(
	@NSPID			VARCHAR(40),
	@NUPDATEMODE	INT,
	@DCURRENTDATE	DATETIME,
	@CMEMOPREFIX	VARCHAR(10),
	@BDEBUGMODE		BIT=0,
	@CRETVAL		NVARCHAR(MAX) OUTPUT,
	@BNEGSTOCKFOUND BIT OUTPUT,
	@bExchangeToleranceCrossed BIT OUTPUT,
	@CLOCID	VARCHAR(5)=''
)
--WITH ENCRYPTION
AS
BEGIN

BEGIN TRY
		
	DECLARE @cUserCode CHAR(7),@NSTEP VARCHAR(10),@CCURLOCID varchar(5),@nExchangeTolerance NUMERIC(6,2),
	@cExchangeTolerance varchar(10)

	SELECT @CUSERCODE=USER_CODE	FROM SLS_CMM01106_UPLOAD 
	(NOLOCK) WHERE SP_ID=@NSPID

	SET @bExchangeToleranceCrossed=0
	
	IF @NUPDATEMODE IN (1,2)
	BEGIN
		SET @NSTEP='487.6.2'
		EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	

		EXEC SP3S_RESTRICT_BILLSAVING_WITHOUTRACK @NSPID,@CUSERCODE,@CRETVAL OUTPUT  --- To be done at Application Level
		
		IF ISNULL(@CRETVAL,'')<>''
			GOTO ATLAST

		SET @NSTEP='487.6.5'
		EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	
		IF EXISTS (SELECT TOP 1 a.product_code FROM sls_cmd01106_upload a (NOLOCK) JOIN sku b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
				   JOIN article c (NOLOCK) ON c.article_code=b.article_code
				   JOIN sls_cmm01106_upload d (NOLOCK) ON d.SP_ID=a.SP_ID
				   WHERE d.sp_id=@NSPID AND PERISHABLE=1 AND b.EXPIRY_DT<d.CM_DT AND ISNULL(b.EXPIRY_DT,'')<>'')
		BEGIN
			SET @NSTEP='487.6.8'
			EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE			
			
			SELECT a.product_code,'Item code is expired on  :'+convert(Varchar,b.EXPIRY_DT,105) as errmsg,0 quantity_in_stock
				FROM sls_cmd01106_upload a (NOLOCK) JOIN sku b (NOLOCK) ON a.PRODUCT_CODE=b.product_code
				JOIN article c (NOLOCK) ON c.article_code=b.article_code
				JOIN sls_cmm01106_upload d (NOLOCK) ON d.SP_ID=a.SP_ID
				WHERE d.sp_id=@NSPID AND PERISHABLE=1 AND b.EXPIRY_DT<d.CM_DT AND ISNULL(b.EXPIRY_DT,'')<>''
		END

	END
	
	SET @NSTEP='487.8'
	EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	
	
	IF ISNULL(@CLOCID,'')=''
		SELECT @CCURLOCID	=DEPT_ID FROM NEW_APP_LOGIN_INFO (nolock) WHERE SPID=@@SPID 
	ELSE
		SELECT @CCURLOCID=@CLOCID


     IF ISNULL(@CCURLOCID,'')=''
	 BEGIN
		SET @CRETVAL =' LOCATION ID CAN NOT BE BLANK  '  
		GOTO ATLAST    
	 END
	  
     SELECT TOP 1 @cExchangeTolerance = ISNULL(value,'') FROM config (NOLOCK)	 WHERE config_option='exchange_tolerance_discount_diff_pct'

	 IF isnull(@cExchangeTolerance,'')<>''
	 BEGIN
		
		SET @NSTEP='487.8.2'
		EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	
	
		SET @nExchangeTolerance=@cExchangeTolerance

	    DECLARE @nSlsValue NUMERIC(14,2),@nSlrValue NUMERIC(14,2),@nSlsDisc NUMERIC(10,2),@nSlrDisc NUMERIC(10,2),
		@nSlsDp NUMERIC(6,2),@nSlrDp NUMERIC(6,2),@bExchangeTolerancebypassed BIT,@nDiff NUMERIC(6,2)

		SELECT TOP 1 @bExchangeTolerancebypassed=ISNULL(exchange_tolerance_discount_check_bypassed,0)
		FROM SLS_cmm01106_UPLOAD (NOLOCK) WHERE sp_id=@nSpId

		IF @bExchangeTolerancebypassed=0
		BEGIN

			SET @NSTEP='487.8.4'
			EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	

			SELECT @nSlrValue=ABS(SUM(mrp*quantity)) FROM sls_cmd01106_upload (NOLOCK) WHERE sp_id=@nSpId
			AND quantity<0
			IF ISNULL(@nSlrValue,0)<>0
			BEGIN
				SELECT @nSlsValue=SUM(net+cmm_discount_amount+discount_amount) FROM sls_cmd01106_upload (NOLOCK) WHERE sp_id=@nSpId
				AND quantity>0

				IF ISNULL(@nSlsValue,0)<>0
				BEGIN
					SET @NSTEP='487.8.6'
					EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	

					SELECT @nSlrDisc=SUM(discount_amount+cmm_discount_amount) FROM sls_cmd01106_upload (NOLOCK) WHERE sp_id=@nSpId
					AND quantity<0

					SELECT @nSlsDisc=SUM(discount_amount+cmm_discount_amount) FROM sls_cmd01106_upload (NOLOCK) WHERE sp_id=@nSpId
					AND quantity>0
					
					SET @NSTEP='487.8.8'
					EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	


					SELECT @nSlsDp=(@nSlsDisc/@nSlsValue)*100,@nSlrDp=ABS(@nSlrDisc/@nSlrValue)*100

					SET @nDiff=@nSlsDp-@nSlrDp

					IF (@nSlsDp-@nSlrDp)>@nExchangeTolerance
					BEGIN
						SET @CRETVAL='Exchange Discount difference Tolerance% '+ltrim(rtrim(str(@nDiff,6,2)))+' cannot be more than :'+ltrim(rtrim(str(@nExchangeTolerance,6,2)))
						SET @bExchangeToleranceCrossed=1
						GOTO ATLAST
					END
				END
			END
		END
	 END
    
	SET @NSTEP='487.9.2'
	EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	


	SET @CRETVAL=''

ATLAST:

	IF LTRIM(RTRIM(ISNULL(@CRETVAL,'')))<>'' AND @BNEGSTOCKFOUND=0
		SET @CRETVAL=ISNULL(@CRETVAL,'') +'(SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED)'
			
	SET @NSTEP='487.9.4'
	EXEC SP_CHKXNSAVELOG 'SLS_VALID_TMP',@NSTEP,0,@NSPID,@BDEBUGMODE	

END TRY


BEGIN CATCH

	SET @CRETVAL=N'ERROR FOUND IN '+ISNULL(ERROR_PROCEDURE(),'SP_VALIDATEXN_BEFORESAVE_SLS_optimized ')+
	'STEP :'+LTRIM(RTRIM(STR(@NSTEP)))  +' MSG :'+ISNULL(ERROR_MESSAGE(),'NULL MSG')  
	  
END CATCH

END
----  END OF PROCEDURE SP_VALIDATEXN_BEFORESAVE_SLS_OPTIMIZED
