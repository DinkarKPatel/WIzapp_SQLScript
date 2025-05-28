CREATE PROCEDURE SPWOWDB_GETIMGDATA
AS
BEGIN
	DECLARE @cCmd NVARCHAR(MAX)
	SET @cCmd=N'select  a.img_id, CAST('''' AS XML).value(''xs:base64Binary(sql:column("prod_image"))'', ''VARCHAR(MAX)'') AS Base64String
	FROM '+DB_NAME()+'_image..image_info a (NOLOCK) join #tmpImgData b on a.img_id=b.img_id'

	EXEC SP_EXECUTESQL @cCmd
END
