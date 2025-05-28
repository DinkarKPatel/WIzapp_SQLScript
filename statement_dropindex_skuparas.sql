declare @cIndexName varchar(1000),@cCmd NVARCHAR(MAX)
SELECT
distinct  a.name AS Index_Name
INTO #tmpSkuIndex
 FROM
 sys.indexes AS a
INNER JOIN
 sys.index_columns AS b
       ON a.object_id = b.object_id AND a.index_id = b.index_id
WHERE
 COL_NAME(b.object_id,b.column_id) in ('article_code','para1_code','para2_code','para3_code','para4_code',
 'para5_code','para5_code','ac_code') and
 a.object_id = OBJECT_ID('sku');


 WHILE EXISTS (SELECT TOP 1 * FROM #tmpSkuIndex)
 BEGIN
	SELECT TOP 1 @cIndexName=index_name from #tmpSkuIndex

	SET @cCmd=N'DROP INDEX SKU.'+@cIndexName
	EXEC SP_EXECUTESQL @cCmd

	DELETE FROM #tmpSkuIndex WHERE index_name=@cIndexName
 END

