CREATE TRIGGER [DBO].[TRG_UPD_SECTION_LAST_MODIFIED_ON] ON [DBO].[SECTIONM]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.section_code,'sectionm' FROM DELETED a
	JOIN INSERTED b ON b.SECTION_CODE=a.SECTION_CODE
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.section_code=df.master_code AND df.master_tablename='sectionm'	
	where (a.section_name<>b.section_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')
		OR ISNULL(a.item_type,0)<>ISNULL(b.item_type,0))
	AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN

	UPDATE SECTIONM SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.SECTION_CODE=SECTIONM.SECTION_CODE
	AND (SECTIONM.section_name<>b.section_name OR SECTIONM.alias<>b.alias OR SECTIONM.inactive<>b.inactive OR SECTIONM.bl_section_name<>b.bl_section_name OR SECTIONM.ITEM_TYPE<>b.ITEM_TYPE)


END
