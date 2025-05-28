CREATE PROCEDURE SAVETRAN_DELETE_MISSINGROWS
@nSpId VARCHAR(40),
@cMemoIdCol VARCHAR(200),
@cMemoId VARCHAR(40),
@cMainTable VARCHAR(200),
@cTemptable VARCHAR(200),
@cFilterCondition VARCHAR(500)='',
@cErrormsg VARCHAR(MAX) OUTPUT
AS
BEGIN
	DECLARE @cMissingRowId VARCHAR(40),@cCmd NVARCHAR(MAX),@cStep VARCHAR(10),@cWhere VARCHAR(500)
BEGIN TRY

	SET @cStep=10
	seLECT @cMissingRowId='',@cWhere=''

	IF @cMainTable='paymode_xn_det'
		SET @cWhere= ' AND amount<>0'

	SET @cCmd=N'SELECT TOP 1 @cMissingRowId=a.row_id FROM '+@cMainTable+' A (NOLOCK) 
	LEFT JOIN 
	(SELECT row_id FROM '+@cTemptable+' B (NOLOCK) WHERE sp_id='''+@nSpId+''''+@cWhere+') b
		ON A.row_ID =B.row_ID WHERE A.'+@cMemoIdCol+'='''+@cMemoId+''''+@cFilterCondition+' AND b.row_id IS NULL'
	
	EXEC SP_EXECUTESQL @cCmd,N'@cMissingRowId VARCHAR(40) OUTPUT',@cMissingRowId OUTPUT

	IF ISNULL(@cMissingRowId,'')<>''
	BEGIN		
		SET @cStep = 20
		EXEC SP_CHKXNSAVELOG 'SLS',@cStep,0,@NSPID,1	

		SET @cCmd=N'DELETE a FROM '+@cMainTable+' A WITH (ROWLOCK) 
		LEFT JOIN 
		(SELECT row_id FROM '+@cTemptable+' B (NOLOCK) WHERE sp_id='''+@nSpId+''''+@cWhere+') b
		ON A.row_ID =B.row_ID WHERE A.'+@cMemoIdCol+' ='''+@cMemoId+''''+@cFilterCondition+'
		AND b.row_id IS NULL'

		EXEC SP_EXECUTESQL @cCmd
	END 

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SAVETRAN_DELETE_MISSINGROWS at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
