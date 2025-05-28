CREATE PROCEDURE SP3S_UPDATERFNET_SLS 
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cRowId VARCHAR(40),@NSUMRFNET NUMERIC(10,2),@nSubTotal NUMERIC(10,2),@cStep VARCHAR(10),
	@nSumRfnetWithAtd NUMERIC(10,2),@nNetAmt NUMERIC(10,2)

BEGIN TRY
	
	SET @cStep='10'
	SELECT TOP 1 @CROWID = ROW_ID FROM #tSlsDetTable
			
	UPDATE #tSlsDetTable SET RFNET = NET-CMM_DISCOUNT_AMOUNT+(CASE WHEN TAX_METHOD=2 THEN TAX_AMOUNT+
	ISNULL(IGST_AMOUNT,0)+ISNULL(CGST_AMOUNT,0)+ISNULL(SGST_AMOUNT,0)+ISNULL(gst_CESS_AMOUNT,0) ELSE 0 END)
	

	IF EXISTS (SELECT TOP 1 net_amount FROM #tSlsMstTable WHERE atd_charges<>0)
		UPDATE a SET rfnet_with_other_charges=rfnet+((b.atd_charges/b.subtotal)*a.net) FROM #tSlsDetTable a
		JOIN #tslsMstTable  b ON 1=1
	ELSE
		UPDATE #tSlsDetTable SET rfnet_with_other_charges=rfnet

	SET @cStep='20'
	SELECT @NSUBTOTAL=net_amount-atd_charges,@nNetAmt=net_amount FROM #tslsMstTable

	SELECT @NSUMRFNET = SUM(RFNET),@nSumRfnetWithAtd=SUM(rfnet_with_other_charges) FROM #tSlsDetTable
				
	IF @NSUMRFNET <> @NSUBTOTAL
		UPDATE #tSlsDetTable SET RFNET = RFNET + ( @NSUBTOTAL - @NSUMRFNET ) 
		WHERE  ROW_ID = @CROWID

	IF @nSumRfnetWithAtd <> @nNetAmt
		UPDATE #tSlsDetTable SET rfnet_with_other_charges = rfnet_with_other_charges + ( @nNetAmt - @nSumRfnetWithAtd ) 
		WHERE  ROW_ID = @CROWID

	SET @cStep='30'
	UPDATE #tSlsDetTable SET REALIZE_SALE = (CASE WHEN (REALIZE_SALE=0 OR  MRP = OLD_MRP) THEN  ISNULL(RFNET,0) ELSE REALIZE_SALE END)
	

	SET @cStep='40'
	UPDATE #tSlsDetTable SET OLD_MRP = (CASE WHEN OLD_MRP=0 THEN MRP ELSE OLD_MRP END)

	GOTO END_PROC
END TRY

BEGIN CATCH	
	SET @cErrormsg='Error in Procedure SP3S_UPDATERFNET_SLS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
END
