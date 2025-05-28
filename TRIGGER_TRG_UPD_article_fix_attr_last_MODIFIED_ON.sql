CREATE TRIGGER [DBO].[TRG_UPD_article_fix_attr_last_MODIFIED_ON] ON [DBO].[article_fix_attr]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE,INSERT
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT b.article_code,'article_fix_attr' FROM INSERTED b
	LEFT JOIN DELETED A ON b.article_code=a.article_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.article_code=df.master_code AND df.master_tablename='article_fix_attr'	
	where (ISNULL(b.attr1_key_code,'')<>isnull(a.attr1_key_code,'') OR
	ISNULL(b.attr2_key_code,'')<>isnull(a.attr2_key_code,'') OR
	ISNULL(b.attr3_key_code,'')<>isnull(a.attr3_key_code,'') OR
	ISNULL(b.attr4_key_code,'')<>isnull(a.attr4_key_code,'') OR
	ISNULL(b.attr5_key_code,'')<>isnull(a.attr5_key_code,'') OR
	ISNULL(b.attr6_key_code,'')<>isnull(a.attr6_key_code,'') OR
	ISNULL(b.attr7_key_code,'')<>isnull(a.attr7_key_code,'') OR
	ISNULL(b.attr8_key_code,'')<>isnull(a.attr8_key_code,'') OR
	ISNULL(b.attr9_key_code,'')<>isnull(a.attr9_key_code,'') OR
	ISNULL(b.attr10_key_code,'')<>isnull(a.attr10_key_code,'') OR
	ISNULL(b.attr11_key_code,'')<>isnull(a.attr11_key_code,'') OR
	ISNULL(b.attr12_key_code,'')<>isnull(a.attr12_key_code,'') OR
	ISNULL(b.attr13_key_code,'')<>isnull(a.attr13_key_code,'') OR
	ISNULL(b.attr14_key_code,'')<>isnull(a.attr14_key_code,'') OR
	ISNULL(b.attr15_key_code,'')<>isnull(a.attr15_key_code,'') OR
	ISNULL(b.attr16_key_code,'')<>isnull(a.attr16_key_code,'') OR
	ISNULL(b.attr17_key_code,'')<>isnull(a.attr17_key_code,'') OR
	ISNULL(b.attr18_key_code,'')<>isnull(a.attr18_key_code,'') OR
	ISNULL(b.attr19_key_code,'')<>isnull(a.attr19_key_code,'') OR
	ISNULL(b.attr20_key_code,'')<>isnull(a.attr20_key_code,'') OR
	ISNULL(b.attr21_key_code,'')<>isnull(a.attr21_key_code,'') OR
	ISNULL(b.attr22_key_code,'')<>isnull(a.attr22_key_code,'') OR
	ISNULL(b.attr23_key_code,'')<>isnull(a.attr23_key_code,'') OR
	ISNULL(b.attr24_key_code,'')<>isnull(a.attr24_key_code,'') OR
	ISNULL(b.attr25_key_code,'')<>isnull(a.attr25_key_code,'')) and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN

	UPDATE article_fix_attr SET LAST_MODIFIED_ON=GETDATE() 
	FROM article_fix_attr JOIN  INSERTED I on I.article_code=article_fix_attr.ARTICLE_CODE
	LEFT JOIN DELETED B on article_fix_attr.article_code=B.article_code
	WHERE b.article_code IS NULL OR b.attr1_key_code<>article_fix_attr.attr1_key_code OR
	b.attr2_key_code<>article_fix_attr.attr2_key_code OR
	b.attr3_key_code<>article_fix_attr.attr3_key_code OR
	b.attr4_key_code<>article_fix_attr.attr4_key_code OR
	b.attr5_key_code<>article_fix_attr.attr5_key_code OR
	b.attr6_key_code<>article_fix_attr.attr6_key_code OR
	b.attr7_key_code<>article_fix_attr.attr7_key_code OR
	b.attr8_key_code<>article_fix_attr.attr8_key_code OR
	b.attr9_key_code<>article_fix_attr.attr9_key_code OR
	b.attr10_key_code<>article_fix_attr.attr10_key_code OR
	b.attr11_key_code<>article_fix_attr.attr11_key_code OR
	b.attr12_key_code<>article_fix_attr.attr12_key_code OR
	b.attr13_key_code<>article_fix_attr.attr13_key_code OR
	b.attr14_key_code<>article_fix_attr.attr14_key_code OR
	b.attr15_key_code<>article_fix_attr.attr15_key_code OR
	b.attr16_key_code<>article_fix_attr.attr16_key_code OR
	b.attr17_key_code<>article_fix_attr.attr17_key_code OR
	b.attr18_key_code<>article_fix_attr.attr18_key_code OR
	b.attr19_key_code<>article_fix_attr.attr19_key_code OR
	b.attr20_key_code<>article_fix_attr.attr20_key_code OR
	b.attr21_key_code<>article_fix_attr.attr21_key_code OR
	b.attr22_key_code<>article_fix_attr.attr22_key_code OR
	b.attr23_key_code<>article_fix_attr.attr23_key_code OR
	b.attr24_key_code<>article_fix_attr.attr24_key_code OR
	b.attr25_key_code<>article_fix_attr.attr25_key_code 
END
