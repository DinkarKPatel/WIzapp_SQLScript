CREATE PROCEDURE SP3S_RECALTOTALS_SLSUPLOAD
@NSPID VARCHAR(40),
@DXNDT DATETIME,
@CERRORMSG VARCHAR(MAX) OUTPUT
AS
BEGIN
	
	DECLARE @NSTEP INT,@NCMMDISCAMT NUMERIC(10,2)
		
BEGIN TRY
	
	SET @NSTEP=329
	UPDATE SLS_CMM01106_UPLOAD SET SUBTOTAL=B.SUBTOTAL,SUBTOTAL_R=B.SUBTOTAL_R FROM 
	(SELECT SUM(CASE WHEN QUANTITY>0 THEN NET ELSE 0 END) AS SUBTOTAL,SUM(CASE WHEN QUANTITY<0 THEN 
	NET ELSE 0 END) AS SUBTOTAL_R FROM SLS_CMD01106_UPLOAD WHERE SP_ID=@NSPID) B
	WHERE  SP_ID=@NSPID
	
	SET @NSTEP=331

	UPDATE A  SET DISCOUNT_AMOUNT=ISNULL(B.DISCOUNT_AMOUNT,0),
	DISCOUNT_PERCENTAGE=(ISNULL(B.DISCOUNT_AMOUNT,0)/(SUBTOTAL+SUBTOTAL_R))*100
	FROM SLS_CMM01106_UPLOAD A JOIN 
	(SELECT SUM(ISNULL(A.DISCOUNT_AMOUNT,0)) AS DISCOUNT_AMOUNT FROM 
	(SELECT SUM(COUPON_DISC_AMOUNT) AS DISCOUNT_AMOUNT FROM SLS_COUPON_REDEMPTION_INFO_UPLOAD A 
	 WHERE SP_ID=@NSPID AND COUPON_DISC_AMOUNT<>0  AND ISNULL(GV_DISCOUNT,0)<>1
	 UNION
	 SELECT SUM(GV_AMOUNT) AS DISCOUNT_AMOUNT FROM SLS_GV_MST_REDEMPTION_UPLOAD A
	 WHERE SP_ID=@NSPID AND GV_AMOUNT<>0) A
	 ) B ON  1=1 WHERE A.SP_ID=@NSPID
	AND ISNULL(B.DISCOUNT_AMOUNT,0)<>0
	
	SELECT @NCMMDISCAMT=DISCOUNT_AMOUNT FROM SLS_CMM01106_UPLOAD WHERE SP_ID=@NSPID
	SET @NSTEP=333
	EXEC SP_RECAL_CMMDISC_CMD @NSPID,'',@NCMMDISCAMT
	
	
	SET @NSTEP = 335
	EXEC SP3S_PROCESS_SLS_GSTCALC
	@NSPID=@NSPID,
	@DXNDT=@DXNDT,
	@BDEBUGMODE=0,
	@CERRORMSG=@CERRORMSG OUTPUT					
	
	--SET @NSTEP=331
	PRINT 'CALL REPROCESS GST FOR SLS-3'
	EXEC SP3S_REPROCESS_GST_CALCULATION '','SLS',@NSPID,@CERRORMSG OUTPUT 
	IF ISNULL(@CERRORMSG,'')<>''
		 GOTO END_PROC
	
END TRY
	
BEGIN CATCH
	SET @CERRORMSG='ERROR IN PROCEDURE SP3S_RECALTOTALS_SLSUPLOAD AT STEP#:'+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	
END
