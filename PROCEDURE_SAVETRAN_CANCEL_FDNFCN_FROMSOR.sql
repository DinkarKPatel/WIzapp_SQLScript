CREATE PROCEDURE SAVETRAN_CANCEL_FDNFCN_FROMSOR
@cEossSorMemoId VARCHAR(40)
AS
BEGIN
	DECLARE @cRmId VARCHAR(50),@cCnId VARCHAR(40),@cPostedMemoId VARCHAR(50),@cErrormsg VARCHAR(MAX),@cStep VARCHAR(2)
	
BEGIN TRY
	Set @cStep='10'
	SELECT TOP 1 @cRmId=refFdnMemoId from SOR_FDNFCN_LINK (NOLOCK) WHERE sorMemoId=@cEossSorMemoId
	SELECT TOP 1 @cCnId=refFcnMemoId from SOR_FDNFCN_LINK (NOLOCK) WHERE sorMemoId=@cEossSorMemoId

	IF @cRmId IS NOT NULL
	BEGIN
		Set @cStep='20'
		SELECT TOP 1 @cPostedMemoId=memo_id FROM POSTACT_VOUCHER_LINK a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id WHERE a.MEMO_ID=@cRmId AND a.XN_TYPE='PRT'

		IF @cPostedMemoId IS NOT NULL
		BEGIN
			SET @cErrormsg='Reference Debit note posted into account books...Cannot cancel'
			GOTO END_PROC
		END
	END

	IF @cCnId IS NOT NULL
	BEGIN	
		Set @cStep='30'
		SET @cPostedMemoId=NULL

		SELECT TOP 1 @cPostedMemoId=memo_id FROM POSTACT_VOUCHER_LINK a (NOLOCK) 
		JOIN vm01106 b (NOLOCK) ON a.vm_id=b.vm_id WHERE a.MEMO_ID=@cCnId AND a.XN_TYPE='WSR'

		IF @cPostedMemoId IS NOT NULL
		BEGIN
			SET @cErrormsg='Reference Credit note posted into account books...Cannot cancel'
			GOTO END_PROC
		END
	END

	BEGIN TRAN
	Set @cStep='40'
	UPDATE rmm01106 SET cancelled=1 WHERE rm_id=@cRmId
	UPDATE cnm01106 SET cancelled=1 WHERE cn_id=@cCnId

	Set @cStep='50'
	DELETE FROM SOR_FDNFCN_LINK with (rowlock) where sorMemoId=@cEossSorMemoId

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SAVETRAN_CANCEL_FDNFCN_FROMSOR at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:
	IF ISNULL(@cErrormsg,'')<>''
		ROLLBACK
	ELSE
		COMMIT


	SELECT ISNULL(@cErrormsg,'') errmsg
END