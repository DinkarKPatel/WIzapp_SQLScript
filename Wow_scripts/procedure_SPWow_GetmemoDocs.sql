CREATE procedure SPWow_GetmemoDocs
@cXnType VARCHAR(100),
@cMemoId VARCHAR(50)
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX),@cImgTable VARCHAR(200)

	SET @cImgTable=db_name()+'_image.dbo.image_info_doc'
	SET @cCmd=N'SELECT img_id imageId,doc_image,fileName,substring(fileName,charindex(''.'',fileName)+1,len(fileName)) filetype,
				CONVERT(BIT,0) deleted
				FROM '+@cImgTable+ ' WHERE xn_type='''+@cXnType+''' AND memo_id='''+@cMemoId+''''

	PRINT @cCmd
	EXEC SP_EXECUTESQL @cCmd
END
