CREATE PROCEDURE SP_GETBCDISC_FROM_HO
(	
	 @CPRODUCTCODEPARA VARCHAR(50)
	 
)	
--WITH ENCRYPTION
AS
BEGIN
	DECLARE @CERRMSG VARCHAR(MAX),@NDISCPCT NUMERIC(7,3)
	
	---- CHECK FOR THE PENDING MEMO TO BE SENT TO MIRRORING SERVER
	DECLARE @TSLSDETAILS TABLE (DISCOUNT_PERCENTAGE NUMERIC(7,3),TAX_METHOD INT)
	
	INSERT 	@TSLSDETAILS
	EXEC SP_WL_PICKLASTDISCOUNT	@CPRODUCTCODEPARA,'',1	
	
	---- IF BARCODE NOT FOUND , JUST END THE PROCESS
	IF NOT EXISTS (SELECT TOP 1 * FROM @TSLSDETAILS)
		SET @CERRMSG='BAR CODE :'+@CPRODUCTCODEPARA+' SALE DETAILS NOT FOUND AT HEAD OFFICE'
	ELSE	
		SELECT @NDISCPCT=DISCOUNT_PERCENTAGE FROM @TSLSDETAILS 
		
	SELECT ISNULL(@CERRMSG,'') AS ERRMSG,ISNULL(@NDISCPCT,0) AS DISCOUNT_PERCENTAGE	
END
