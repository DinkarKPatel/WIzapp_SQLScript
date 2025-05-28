create PROCEDURE SP3S_VALIDATE_DATAMERGED_SINGLECHANNEL
@cMasterTable VARCHAR(200),
@cDetTable VARCHAR(200),
@cMemoIdCol VARCHAR(200),
@cMemoId VARCHAR(40),
@cUploadTable VARCHAR(200),
@nSpId VARCHAR(40),
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	DECLARE @nTotMstQty NUMERIC(10,2),@nTotDetQty NUMERIC(10,2),@nTotUploadMstQty NUMERIC(10,2),@bcancelled bit

	SET @cErrormsg='' 

	
	SET @CCMD=N'SELECT @bcancelled=cancelled FROM '+@cUploadTable+' where sp_id ='''+@nSpId  +''' '
	PRINT @CCMD		
	EXEC SP_EXECUTESQL @CCMD,N'@bcancelled VARCHAR(25) OUTPUT',@bcancelled OUTPUT

	if isnull(@bcancelled,0)=1
	return



	SET @cCmd=N'SELECT @nTotMstQty=total_quantity FROM '+@cMasterTable+' WHERE '+@cMemoIdCol+'='''+@cMemoId+''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd,N'@nTotMstQty NUMERIC(10,2) OUTPUT',@nTotMstQty OUTPUT

	SET @cCmd=N'SELECT @nTotUploadMstQty=total_quantity FROM '+@cUploadTable+' WHERE sp_id='''+@nSpId+''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd,N'@nTotUploadMstQty NUMERIC(10,2) OUTPUT',@nTotUploadMstQty OUTPUT

	SET @cCmd=N'SELECT @nTotDetQty=SUM(quantity) FROM '+@cDetTable+' WHERE '+ @cMemoIdCol+'='''+@cMemoId+''''
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd,N'@nTotDetQty NUMERIC(10,2) OUTPUT',@nTotDetQty OUTPUT
	

	IF ISNULL(@nTotMstQty,0)<>ISNULL(@nTotDetQty,0) OR ISNULL(@nTotUploadMstQty,0)<>ISNULL(@nTotDetQty,0)
		SET @cErrormsg='Mismatch in Total quantity of Memo merged...'+str(ISNULL(@nTotMstQty,0))+'-'+str(ISNULL(@nTotDetQty,0))+'-'+
		str(ISNULL(@nTotUploadMstQty,0))
		
END

