
SET NOCOUNT ON
DECLARE @DB VARCHAR(100),@CCMD NVARCHAR(MAX),@ERR_MSG VARCHAR(100)
SET @ERR_MSG=''
SET @DB=DB_NAME()+'_IMAGE'
BEGIN TRY

	SET @CCMD=N'  UPDATE A SET a.filename=b.FileName
                  FROM '+@DB+'..IMAGE_INFO_DOC (NOLOCK) a
                  JOIN DailogFile b ON b.memono=a.MEMO_ID and a.XN_TYPE=b.ModuleName and a.IMG_ID=b.ROWID
					WHERE ISNULL(a.fileName,'''')='''' '

	PRINT @CCMD
	EXEC(@CCMD)

	SET @CCMD=N'UPDATE A SET a.filename=a.IMG_ID+''.pdf''
                  FROM '+@DB+'..IMAGE_INFO_DOC (NOLOCK) a
                   LEFT OUTER JOIN DailogFile b ON b.memono=a.MEMO_ID and a.XN_TYPE=b.ModuleName and a.IMG_ID=b.ROWID
				   WHERE b.ROWID IS NULL and ISNULL(a.filename,'''')='''' '
	PRINT @CCMD
	EXEC( @CCMD)
END TRY
BEGIN CATCH
	SELECT @ERR_MSG=ERROR_MESSAGE()
END CATCH

SET NOCOUNT OFF


