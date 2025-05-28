CREATE PROCEDURE SP3S_BUILDGIT_CURDATE
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cTableName VARCHAR(200),@cErrormsg varchar(max),@cStep VARCHAR(10),@dXnDt DATETIME,
			@cDtSuffix VARCHAR(20)

BEGIN TRY
	SET @cErrormsg=''

	SET @cStep='10'
	CREATE TABLE #tmpGitProcess (memo_id VARCHAR(50),quantity NUMERIC(10,2),memo_dt datetime,tat_days numeric(5,0))
	
	SET @dXnDt=convert(date,getdate())

	SET @cTableName=DB_NAME()+'_PMT.DBO.GITLOCS_'+CONVERT(VARCHAR,@dXnDt,112)

	SET @cDtSuffix=convert(varchar,@dXnDt,112)

	EXEC SP3S_CREATE_LOCWISEGITXNS_STRU @cDtSuffix

	BEGIN TRAN

	SET @cStep='20'
	EXEC SP3S_GET_PENDING_GITLOCS 
	@bBuildCurDate=1,
	@dXnDt=@dXnDt

	SET @cStep='30'
	SET @cCmd=N'DELETE a FROM '+@cTableName+' a JOIN pim01106 b ON SUBSTRING(a.memo_id,4,len(a.memo_id))=b.inv_id
				WHERE left(memo_id,3)=''WSL'' AND b.receipt_dt<>'''' AND b.cancelled=0'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	SET @cStep='40'
	SET @cCmd=N'DELETE a FROM '+@cTableName+' a JOIN cnm01106 b ON SUBSTRING(a.memo_id,4,len(a.memo_id))=b.rm_id
				WHERE left(memo_id,3)=''PRT'' AND b.receipt_dt<>'''' AND b.cancelled=0'
	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_BUILDGIT_CURDATE at Step#'+@cStep+' '+error_message() 
	GOTO END_PROC
END CATCH

END_PROC:
	IF @@TRANCOUNT>0
	BEGIN
		IF @cErrormsg=''
			COMMIT
		ELSE
			ROLLBACK
	END

	select isnull(@cErrormsg,'') errmsg
END
