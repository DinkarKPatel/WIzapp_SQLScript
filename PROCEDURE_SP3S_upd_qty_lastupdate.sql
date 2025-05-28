CREATE PROCEDURE SP3S_upd_qty_lastupdate
@nUpdateMode NUMERIC(1,0),
@cXnType VARCHAR(200),
@cMasterTable VARCHAR(200),
@nSpId VARCHAR(50)='',
@cMemoId VARCHAR(50)='',
@cMemoIdCol VARCHAR(100)='',
@cXnDtCol VARCHAR(100)='',
@bCalledfromMerging BIT=0,
@cUploadTableNamePara VARCHAR(200)='',
@cErrormsg NVARCHAR(MAX) OUTPUT

AS
BEGIN

	DECLARE @cCmd NVARCHAR(MAX),@cUploadTableName VARCHAR(200),@cWhereClause VARCHAR(300),@cStep VARCHAR(4),
			@bOldCancelled bit

BEGIN TRY
	SET @cStep='10'
	SET @cErrormsg=''
	
	IF @cUploadTableNamePara=''
		SET @cUploadTableNamePara=@cXnType+'_'+@cMasterTable+'_upload'

	SET @cUploadTableName=(CASE WHEN @nUpdatemode IN (1,2) THEN @cUploadTableNamePara
						   ELSE @cMasterTable END)
	
	SET @cStep='13'
	SET @cWhereClause=(CASE WHEN  @nUpdatemode IN (1,2) THEN 'sp_id='''+@nSpId+'''' 
							ELSE @cMemoIdCol+'='''+@cMemoId+'''' END)

	IF @bCalledfromMerging=1
	BEGIN
		IF @nUpdatemode<>1
		BEGIN
			SET @cStep='15'
			SET @cCmd=N'UPDATE a SET quantity_last_update=b.quantity_last_update FROM '+@cUploadTableName+' a '+
						' JOIN '+@cMasterTable+' b ON a.'+@cMemoIdCol+'=b.'+@cMemoIdCol+
						' WHERE a.'+@cWhereClause+' AND a.total_quantity<>b.TOTAL_QUANTITY'
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd
		END

		IF @nUpdateMode=3
		BEGIN
			SET @cStep='15.3'
			SET @cCmd=N'SELECT @bOldCancelled=cancelled FROM '+@cMasterTable+' WHERE '+@cWhereClause
			PRINT @cCmd
			EXEC SP_EXECUTESQL @cCmd,N'@bOldCancelled BIT OUTPUT',@bOldCancelled OUTPUT

			IF @bOldCancelled=1
				GOTO END_PROC
		END

	END

	IF @nUpdateMode IN (1,3)
	BEGIN
		SET @cStep='30'
		SET @cCmd=N'UPDATE '+@cUploadTableName+' SET quantity_last_update=GETDATE() WHERE '+@cWhereClause
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd
	END
	ELSE
	BEGIN
		SET @cStep='40'
		SET @cCmd=N'UPDATE a set a.quantity_last_update=getdate() FROM '+@cUploadTableName+' a '+
		' JOIN '+@cMasterTable+' b ON a.'+@cMemoIdCol+'=b.'+@cMemoIdCol+
		' WHERE a.'+@cWhereClause+' AND (a.total_quantity<>b.TOTAL_QUANTITY or a.'+@cXnDtCol+'<>b.'+@cXnDtCol+')'
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd

		SET @cStep='50'
		DECLARE @dMemoDtChanged DATETIME
		SET @cCmd=N'SELECT TOP 1 @dMemoDtChanged=b.'+ @cXnDtCol+' FROM '+@cUploadTableName+' a '+
					' JOIN '+@cMasterTable+' b ON a.'+@cMemoIdCol+'=b.'+@cMemoIdCol+
					' WHERE a.'+@cWhereClause+' AND a.'+@cXnDtCol+'>b.'+@cXnDtCol
		
		PRINT @cCmd
		EXEC SP_EXECUTESQL @cCmd,N'@dMemoDtChanged DATETIME OUTPUT',@dMemoDtChanged OUTPUT

		IF ISNULL(@dMemoDtChanged,'')<>''
		BEGIN
			SET @cStep='60'
			EXEC SP3S_INS_PMTMINDT @dMemoDtChanged,@cXnType
		END
	END

	GOTO END_PROC
END TRY

BEGIN CATCH
	SET @cErrormsg='Error in Procedure SP3S_upd_qty_lastupdate at Step#'+@cStep+' '+ERROR_MESSAGE()
	GOTO END_PROC
END CATCH

END_PROC:

END
