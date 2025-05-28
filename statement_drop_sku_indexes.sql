DECLARE @cCmd NVARCHAR(MAX)
if exists (select top 1 name from sys.indexes where name='ind_sku_lastmodified')
begin
	SET @cCmd=N'drop index sku.ind_sku_lastmodified'
	EXEC SP_EXECUTESQL @cCmd
end
if exists (select top 1 name from sys.indexes where name='ind_sku_uploaded')
begin
	SET @cCmd=N'drop index sku.ind_sku_uploaded'
	EXEC SP_EXECUTESQL @cCmd
END
if exists (select top 1 name from sys.indexes where name='IX_SKU_ACCODE_INCL')
begin
	SET @cCmd=N'drop index sku.IX_SKU_ACCODE_INCL'
	EXEC SP_EXECUTESQL @cCmd
END
if exists (select top 1 name from sys.indexes where name='IX_SKU_ARTICLE_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_ARTICLE_CODE'
	EXEC SP_EXECUTESQL @cCmd
END
if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA1_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA1_CODE'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA2_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA2_CODE'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA3_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA3_CODE'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA4_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA4_CODE'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA5_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA5_CODE'
	EXEC SP_EXECUTESQL @cCmd
END

if exists (select top 1 name from sys.indexes where name='IX_SKU_PARA6_CODE')
begin
	SET @cCmd=N'drop index sku.IX_SKU_PARA6_CODE'
	EXEC SP_EXECUTESQL @cCmd
END