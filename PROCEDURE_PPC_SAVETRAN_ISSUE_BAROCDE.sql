CREATE PROCEDURE PPC_SAVETRAN_ISSUE_BAROCDE
(
	@NUPDATEMODE		NUMERIC(1,0),
	@NSPID				INT,
	@CFINYEAR			VARCHAR(10),
	@CXNMEMOID			VARCHAR(40)='',
	@CLOCID				VARCHAR(2)=''	
)
AS
BEGIN
EXEC PPC_SAVETRAN_ISSUE_BARCODE @NUPDATEMODE,@NSPID,@CFINYEAR,@CXNMEMOID,@CLOCID
END						
------------- END OF PROCEDURE PPC_SAVETRAN_BARCODE_PRINT		-----------------------------------------
