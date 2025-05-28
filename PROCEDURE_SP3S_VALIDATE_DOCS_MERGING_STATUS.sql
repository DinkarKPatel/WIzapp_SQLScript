CREATE PROCEDURE SP3S_VALIDATE_DOCS_MERGING_STATUS
@cXnType VARCHAR(50),
@cXnId VARCHAR(50)
AS
BEGIN
	DECLARE @cSearchMemoId VARCHAR(50),@bNotFound BIT,@cStep VARCHAR(4),@cErrormsg VARCHAR(MAX)

BEGIN TRY
	SET @cStep='10'
	SELECT @bNotFound=1,@cErrormsg=''

	IF @cXnType='DOCWSL'
	BEGIN
		SET @cStep='20'
		SELECT TOP 1 @cSearchMemoId = inv_id FROM docwsl_inm01106_upload (NOLOCK)
		WHERE inv_id=@cXnId 

		SET @cStep='30'
		IF ISNULL(@cSearchMemoId,'')=''
			SELECT TOP 1 @cSearchMemoId = inv_id FROM pim01106 (NOLOCK)
			WHERE inv_id=@cXnId AND CANCELLED=0 AND INV_NO=BILL_NO

			--AS DISCUSS WITH SANJIV SIR 19-08-2021 eRP CHALLAN MODIFY THROUGH MERGING
	END
	ELSE
	BEGIN
		SET @cStep='40'
		SELECT TOP 1 @cSearchMemoId = rm_id FROM docprt_rmm01106_upload (NOLOCK)
		WHERE rm_id=@cXnId

		SET @cStep='50'
		IF ISNULL(@cSearchMemoId,'')=''
			SELECT TOP 1 @cSearchMemoId = rm_id FROM cnm01106 (NOLOCK)
			WHERE rm_id=@cXnId
	END

	SET @cStep='60'
	IF ISNULL(@cSearchMemoId,'')<>''
		SET @bNotFound=0

END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_VALIDATE_DOCS_MERGING_STATUS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC	
END CATCH

END_PROC:
	SELECT ISNULL(@bNotFound,0) not_found,@cErrormsg err_msg
END

