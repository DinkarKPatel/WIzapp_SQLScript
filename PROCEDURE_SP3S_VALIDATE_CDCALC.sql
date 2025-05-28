CREATE PROCEDURE SP3S_VALIDATE_CDCALC
@cMrrId VARCHAR(50),
@cErrormsg VARCHAR(MAX) output
AS
BEGIN
	DECLARE @cPcwithCd VARCHAR(50),@cPcwithoutCd VARCHAR(50)

	SET @cErrormsg=''

	SELECT TOP 1 @cPcwithCd=product_code FROM pid01106 (NOLOCK) WHERE mrr_id=@cMrrId AND ISNULL(cashdiscountamount,0)<>0
	
	IF ISNULL(@cPcwithCd,'')=''
		RETURN

	SELECT TOP 1 @cPcwithoutCd=product_code FROM pid01106 (NOLOCK) WHERE mrr_id=@cMrrId AND ISNULL(cashdiscountamount,0)=0	
	AND purchase_price<>0 
	
	IF ISNULL(@cPcwithoutCd,'')<>''
		SET @cErrormsg='Mixing of Barcodes with Zero & Non Zero CD found....Cannot Save'
END