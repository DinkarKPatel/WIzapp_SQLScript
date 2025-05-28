CREATE TRIGGER [DBO].[TRG_UPD_PARA4_LAST_MODIFIED_ON] ON [DBO].[PARA4]  --- Do not verwrite in May2022 Release Folder	
FOR UPDATE
AS
BEGIN
	INSERT INTO opt_sku_diff (master_code,master_tablename)
	SELECT a.para4_code,'para4' FROM DELETED a
	JOIN INSERTED b ON b.para4_code=a.para4_code
	LEFT JOIN  opt_sku_diff df (NOLOCK) ON a.para4_code=df.master_code AND df.master_tablename='para4'	
	where (a.para4_name<>b.para4_name OR ISNULL(a.alias,'')<>ISNULL(b.alias,'')) and df.master_code is null

	IF (SELECT TRIGGER_NESTLEVEL())> 1  OR dbo.FN_CHECKHOLOC()=0
		RETURN
	
	UPDATE PARA4 SET LAST_MODIFIED_ON=GETDATE()
	FROM DELETED B WHERE B.PARA4_CODE=PARA4.PARA4_CODE
	AND (para4.para4_name<>b.para4_name OR para4.alias<>b.alias OR para4.inactive<>b.inactive 
		OR  para4.bl_para4_name<>b.bl_para4_name)
END
