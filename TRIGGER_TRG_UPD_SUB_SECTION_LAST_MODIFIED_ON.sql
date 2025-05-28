CREATE TRIGGER [DBO].[TRG_UPD_SUB_SECTION_LAST_MODIFIED_ON] ON [DBO].[SECTIOND]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
begin

	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.sub_section_code,'sectiond' FROM DELETED a
	JOIN INSERTED b ON b.SUB_SECTION_CODE=a.SUB_SECTION_CODE
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.sub_section_code=df.master_code AND df.master_tablename='sectiond'	
	where (b.sub_section_name<>a.sub_section_name OR ISNULL(b.alias,'')<>ISNULL(a.alias,'') OR a.section_code<>b.section_code)
	AND df.master_code IS NULL

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
		
	UPDATE SECTIOND SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.SUB_SECTION_CODE=SECTIOND.SUB_SECTION_CODE
	AND (SECTIOND.sub_section_name<>b.sub_section_name OR SECTIOND.alias<>b.alias OR SECTIOND.inactive<>b.inactive OR SECTIOND.section_code<>b.section_code OR SECTIOND.bl_sub_section_name<>b.bl_sub_section_name)


end
